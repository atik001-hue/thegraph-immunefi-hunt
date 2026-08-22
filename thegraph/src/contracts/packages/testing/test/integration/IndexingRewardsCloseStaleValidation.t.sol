// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import { IGraphPayments } from "@graphprotocol/interfaces/contracts/horizon/IGraphPayments.sol";
import { IAllocation } from "@graphprotocol/interfaces/contracts/subgraph-service/internal/IAllocation.sol";
import { Allocation } from "subgraph-service/libraries/Allocation.sol";
import { IRewardsManager } from "@graphprotocol/interfaces/contracts/contracts/rewards/IRewardsManager.sol";

import { RealRewardsHarness } from "../harness/RealRewardsHarness.t.sol";

/// @title Extended validation — is closeStaleAllocation inflation real?
contract IndexingRewardsCloseStaleValidation is RealRewardsHarness {
    using Allocation for IAllocation.State;

    address internal stranger = makeAddr("stranger");

    modifier requireRealRm() {
        if (!realRmAvailable) {
            vm.skip(true, "RewardsManager artifact missing");
            return;
        }
        _;
    }

    /// @dev One allocation only: closeStale leaves no survivor → no inflation vector.
    function test_Validate_SoloAlloc_CloseStaleDoesNotMintSurplus() public requireRealRm {
        bytes32 subgraph = keccak256("solo-validate");
        IndexerSetup memory ix = _setupIndexer("solo-v", subgraph, MINIMUM_PROVISION_TOKENS * 10);

        vm.roll(block.number + 200);
        skip(MAX_POI_STALENESS + 1);

        uint256 supplyBefore = token.totalSupply();
        subgraphService.closeStaleAllocation(ix.allocationId);
        uint256 mintOnClose = token.totalSupply() - supplyBefore;

        assertEq(subgraphService.getAllocation(ix.allocationId).tokens, 0);
        assertLe(mintOnClose, 1 ether, "solo closeStale should not mint large rewards");
    }

    /// @dev Global reward index jumps when closeStale uses inflated denominator, then subgraph tokens drop.
    function test_Validate_GlobalIndexSpikesThenTokensDrop() public requireRealRm {
        bytes32 subgraph = keccak256("index-spike");
        uint256 provision = MINIMUM_PROVISION_TOKENS * 10;

        IndexerSetup memory stale = _setupExtraAllocation(makeAddr("ix-spike"), subgraph, provision, "stale");
        IndexerSetup memory survivor = _setupExtraAllocation(makeAddr("ix-spike"), subgraph, provision, "live");

        _advanceToStale(stale, survivor);

        (uint256 accBefore,) = realRewardsManager.getAccRewardsPerAllocatedToken(subgraph);
        uint256 subgraphTokensBefore = subgraphService.getSubgraphAllocatedTokens(subgraph);
        assertEq(subgraphTokensBefore, provision * 2);

        subgraphService.closeStaleAllocation(stale.allocationId);

        (uint256 accAfter,) = realRewardsManager.getAccRewardsPerAllocatedToken(subgraph);
        uint256 subgraphTokensAfter = subgraphService.getSubgraphAllocatedTokens(subgraph);

        emit log_named_uint("accBefore", accBefore);
        emit log_named_uint("accAfter", accAfter);
        emit log_named_uint("subgraphTokensBefore", subgraphTokensBefore);
        emit log_named_uint("subgraphTokensAfter", subgraphTokensAfter);

        assertEq(subgraphTokensAfter, provision, "stale alloc zeroed from subgraph total");
        assertGt(accAfter, accBefore, "global index inflated during closeStale resize");
    }

    /// @dev Permissionless third party triggers the same inflation for survivor indexer.
    function test_Validate_StrangerTriggersCloseStale() public requireRealRm {
        uint256 provision = MINIMUM_PROVISION_TOKENS * 10;

        uint256 control = _finalCollectMint(false, stranger);
        uint256 attack = _finalCollectMint(true, stranger);

        emit log_named_uint("controlMint", control);
        emit log_named_uint("strangerTriggeredMint", attack);

        assertGt(control, 0);
        assertGe(attack, (control * 19) / 10, "third-party closeStale still ~2x survivor mint");
    }

    /// @dev Compare against honest single-allocation indexer (fair baseline).
    function test_Validate_TwoAllocAttackVsSingleAllocBaseline() public requireRealRm {
        uint256 provision = MINIMUM_PROVISION_TOKENS * 10;

        uint256 singleBaseline = _singleAllocFinalMint(provision);
        uint256 attackMint = _finalCollectMint(true, makeAddr("attacker-3a"));
        uint256 controlTwoAlloc = _finalCollectMint(false, makeAddr("attacker-3b"));

        emit log_named_uint("singleAllocBaseline", singleBaseline);
        emit log_named_uint("twoAllocControl", controlTwoAlloc);
        emit log_named_uint("twoAllocAttack", attackMint);

        // Single alloc and two-alloc control (stale sibling still counted) should be in same ballpark.
        assertApproxEqRel(singleBaseline, controlTwoAlloc, 0.15e18, "single vs 2-alloc control");

        // Attack path mints ~2x the fair single-allocation baseline.
        assertGe(attackMint, (singleBaseline * 19) / 10, "attack ~2x single-alloc fair baseline");
    }

    /// @dev Three equal allocations: close two stale siblings → ~3x survivor mint vs control.
    function test_Validate_ThreeAllocs_CloseTwoStale() public requireRealRm {
        bytes32 subgraphCtrl = keccak256("triple-ctrl");
        bytes32 subgraphAtk = keccak256("triple-atk");
        uint256 provision = MINIMUM_PROVISION_TOKENS * 10;
        address rogue = makeAddr("rogue-triple");

        uint256 ctrlMint = _tripleScenario(subgraphCtrl, rogue, false);
        uint256 atkMint = _tripleScenario(subgraphAtk, rogue, true);

        emit log_named_uint("tripleControlMint", ctrlMint);
        emit log_named_uint("tripleAttackMint", atkMint);

        assertGt(ctrlMint, 0);
        assertGe(atkMint, (ctrlMint * 25) / 10, "closing 2 of 3 stale allocs inflates survivor >=2.5x");
    }

    /// @dev Indexer-owned resize to zero on stale alloc matches closeStale inflation (same internal path).
    function test_Validate_OwnerResizeToZeroSameAsCloseStale() public requireRealRm {
        uint256 provision = MINIMUM_PROVISION_TOKENS * 10;
        bytes32 subgraph = keccak256("owner-resize");
        address rogue = makeAddr("owner-resize-ix");

        IndexerSetup memory stale = _setupExtraAllocation(rogue, subgraph, provision, "s");
        IndexerSetup memory survivor = _setupExtraAllocation(rogue, subgraph, provision, "v");
        _advanceToStale(stale, survivor);

        uint256 before = token.totalSupply();
        vm.prank(rogue);
        subgraphService.resizeAllocation(rogue, stale.allocationId, 0);
        vm.roll(block.number + 100);
        _collect(survivor, bytes32("POI-final"));
        uint256 ownerResizeMint = token.totalSupply() - before;

        uint256 closeStaleMint = _finalCollectMint(true, makeAddr("cmp"));

        emit log_named_uint("ownerResizeMint", ownerResizeMint);
        emit log_named_uint("closeStaleMint", closeStaleMint);

        assertApproxEqRel(ownerResizeMint, closeStaleMint, 0.05e18, "owner resize-to-zero ~= closeStale");
    }

    function _tripleScenario(bytes32 subgraph, address rogue, bool closeTwo) internal returns (uint256 finalMint) {
        IndexerSetup memory a = _setupExtraAllocation(rogue, subgraph, MINIMUM_PROVISION_TOKENS * 10, "a");
        IndexerSetup memory b = _setupExtraAllocation(rogue, subgraph, MINIMUM_PROVISION_TOKENS * 10, "b");
        IndexerSetup memory c = _setupExtraAllocation(rogue, subgraph, MINIMUM_PROVISION_TOKENS * 10, "c");

        vm.roll(block.number + 200);
        _collect(c, bytes32("POI-0"));
        skip(7 days);
        vm.roll(block.number + 20);
        _collect(c, bytes32("POI-1"));
        skip(7 days);
        vm.roll(block.number + 20);
        _collect(c, bytes32("POI-2"));
        skip(15 days);

        assertTrue(subgraphService.getAllocation(a.allocationId).isStale(MAX_POI_STALENESS));
        assertTrue(subgraphService.getAllocation(b.allocationId).isStale(MAX_POI_STALENESS));

        if (closeTwo) {
            subgraphService.closeStaleAllocation(a.allocationId);
            subgraphService.closeStaleAllocation(b.allocationId);
            assertEq(subgraphService.getSubgraphAllocatedTokens(subgraph), MINIMUM_PROVISION_TOKENS * 10);
        }

        vm.roll(block.number + 100);
        uint256 before = token.totalSupply();
        _collect(c, bytes32("POI-final"));
        finalMint = token.totalSupply() - before;
    }

    function _singleAllocFinalMint(uint256 provision) internal returns (uint256 finalMint) {
        bytes32 subgraph = keccak256("single-baseline");
        IndexerSetup memory ix = _setupIndexer("single-base", subgraph, provision);

        vm.roll(block.number + 200);
        _collect(ix, bytes32("POI-0"));
        skip(7 days);
        vm.roll(block.number + 20);
        _collect(ix, bytes32("POI-1"));
        skip(7 days);
        vm.roll(block.number + 20);
        _collect(ix, bytes32("POI-2"));
        skip(15 days);
        vm.roll(block.number + 100);

        uint256 before = token.totalSupply();
        _collect(ix, bytes32("POI-final"));
        finalMint = token.totalSupply() - before;
    }

    function _finalCollectMint(bool closeStale, address caller) internal returns (uint256 finalMint) {
        bytes32 subgraph = keccak256(abi.encodePacked("validate-", closeStale, caller));
        uint256 provision = MINIMUM_PROVISION_TOKENS * 10;

        IndexerSetup memory stale = _setupIndexer(
            string.concat("stale-", vm.toString(uint256(uint160(caller)))),
            subgraph,
            provision
        );
        IndexerSetup memory survivor = _setupIndexer(
            string.concat("live-", vm.toString(uint256(uint160(caller)))),
            subgraph,
            provision
        );

        _advanceToStale(stale, survivor);

        if (closeStale) {
            vm.prank(caller);
            subgraphService.closeStaleAllocation(stale.allocationId);
        }

        vm.roll(block.number + 100);
        uint256 before = token.totalSupply();
        _collect(survivor, bytes32("POI-final"));
        finalMint = token.totalSupply() - before;
    }

    function _advanceToStale(IndexerSetup memory stale, IndexerSetup memory survivor) internal {
        vm.roll(block.number + 200);
        _collect(survivor, bytes32("POI-0"));
        skip(7 days);
        vm.roll(block.number + 20);
        _collect(survivor, bytes32("POI-1"));
        skip(7 days);
        vm.roll(block.number + 20);
        _collect(survivor, bytes32("POI-2"));
        skip(15 days);
        assertTrue(subgraphService.getAllocation(stale.allocationId).isStale(MAX_POI_STALENESS));
    }

    function _collect(IndexerSetup memory ix, bytes32 poi) internal {
        bytes memory data = abi.encode(ix.allocationId, poi, _poiMetadata());
        vm.prank(ix.addr);
        subgraphService.collect(ix.addr, IGraphPayments.PaymentTypes.IndexingRewards, data);
    }

    function _setupExtraAllocation(
        address indexer,
        bytes32 subgraph,
        uint256 provision,
        string memory label
    ) internal returns (IndexerSetup memory ix) {
        (string memory url,) = subgraphService.indexers(indexer);
        if (bytes(url).length == 0) {
            _mintTokens(indexer, provision * 2);
            vm.startPrank(indexer);
            token.approve(address(staking), provision * 2);
            staking.stakeTo(indexer, provision * 2);
            staking.provision(indexer, address(subgraphService), provision, FISHERMAN_REWARD_PERCENTAGE, DISPUTE_PERIOD);
            subgraphService.register(indexer, abi.encode("url", "geoHash", address(0)));
            subgraphService.setPaymentsDestination(indexer);
            vm.stopPrank();
        } else {
            _mintTokens(indexer, provision);
            vm.startPrank(indexer);
            token.approve(address(staking), provision);
            staking.stakeTo(indexer, provision);
            staking.addToProvision(indexer, address(subgraphService), provision);
            vm.stopPrank();
        }

        (ix.allocationId, ix.allocationKey) = makeAddrAndKey(string.concat(label, "-alloc"));
        ix.addr = indexer;
        ix.subgraphDeploymentId = subgraph;
        ix.provisionTokens = provision;

        bytes32 digest = subgraphService.encodeAllocationProof(indexer, ix.allocationId);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ix.allocationKey, digest);
        bytes memory allocationData = abi.encode(subgraph, provision, ix.allocationId, abi.encodePacked(r, s, v));
        vm.prank(indexer);
        subgraphService.startService(indexer, allocationData);
    }

    function _poiMetadata() internal view returns (bytes memory) {
        // forge-lint: disable-next-line(unsafe-typecast)
        return abi.encode(block.number, bytes32("PUBLIC_POI"), uint8(0), uint8(0), uint256(0));
    }
}
