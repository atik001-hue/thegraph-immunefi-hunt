// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import { IGraphPayments } from "@graphprotocol/interfaces/contracts/horizon/IGraphPayments.sol";

import { RealRewardsHarness } from "../harness/RealRewardsHarness.t.sol";

/// @title Compare allocate-inflation vs adding tokens via honest second collect on both allocs
contract IndexingRewardsAllocateInflationCompare is RealRewardsHarness {
    uint256 internal constant PROVISION = MINIMUM_PROVISION_TOKENS * 10;

    function test_Compare_TotalMintMatchedCollects() public {
        if (!realRmAvailable) {
            vm.skip(true, "RewardsManager artifact missing");
            return;
        }

        uint256 soloTotal = _run(true, false);
        uint256 twinBugTotal = _run(false, true);
        uint256 twinHonestTotal = _run(false, false);

        emit log_named_uint("soloOneAllocTwoCollects", soloTotal);
        emit log_named_uint("twinOpenSecondBeforeFirstCollect", twinBugTotal);
        emit log_named_uint("twinBothCollectNormally", twinHonestTotal);

        assertApproxEqRel(twinHonestTotal, soloTotal, 0.20e18, "two alloc honest ~ solo total");
        assertGt(twinBugTotal, soloTotal, "bug path total mint exceeds solo");
    }

    /// @dev soloMode: one allocation only. bugMode: open 2nd alloc before first collect on A.
    function _run(bool soloMode, bool bugMode) internal returns (uint256 total) {
        bytes32 subgraph = keccak256(abi.encodePacked("cmp-", soloMode, bugMode));
        address ix = makeAddr(string.concat("ix-", vm.toString(subgraph)));
        uint256 s0 = token.totalSupply();

        IndexerSetup memory a = _alloc(ix, subgraph, "a");
        vm.roll(block.number + 200);

        if (!soloMode) {
            if (bugMode) {
                _alloc(ix, subgraph, "b");
            }
            _collect(a);
            skip(7 days);
            vm.roll(block.number + 50);
            if (!bugMode) {
                IndexerSetup memory b = _alloc(ix, subgraph, "b");
                vm.roll(block.number + 200);
                _collect(b);
            }
            _collect(a);
        } else {
            _collect(a);
            skip(7 days);
            vm.roll(block.number + 50);
            _collect(a);
        }

        return token.totalSupply() - s0;
    }

    function _alloc(address indexer, bytes32 subgraph, string memory label) internal returns (IndexerSetup memory ix) {
        (string memory url,) = subgraphService.indexers(indexer);
        if (bytes(url).length == 0) {
            _mintTokens(indexer, PROVISION * 3);
            vm.startPrank(indexer);
            token.approve(address(staking), PROVISION * 3);
            staking.stakeTo(indexer, PROVISION * 3);
            staking.provision(indexer, address(subgraphService), PROVISION, FISHERMAN_REWARD_PERCENTAGE, DISPUTE_PERIOD);
            subgraphService.register(indexer, abi.encode("url", "geoHash", address(0)));
            subgraphService.setPaymentsDestination(indexer);
            vm.stopPrank();
        } else {
            _mintTokens(indexer, PROVISION);
            vm.startPrank(indexer);
            token.approve(address(staking), PROVISION);
            staking.stakeTo(indexer, PROVISION);
            staking.addToProvision(indexer, address(subgraphService), PROVISION);
            vm.stopPrank();
        }

        (ix.allocationId, ix.allocationKey) = makeAddrAndKey(string.concat("c-", label, vm.toString(subgraph)));
        ix.addr = indexer;
        ix.subgraphDeploymentId = subgraph;
        ix.provisionTokens = PROVISION;

        bytes32 digest = subgraphService.encodeAllocationProof(indexer, ix.allocationId);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ix.allocationKey, digest);
        bytes memory data = abi.encode(subgraph, PROVISION, ix.allocationId, abi.encodePacked(r, s, v));
        vm.prank(indexer);
        subgraphService.startService(indexer, data);
    }

    function _collect(IndexerSetup memory ix) internal {
        bytes memory data = abi.encode(ix.allocationId, bytes32("POI"), _poiMetadata());
        vm.prank(ix.addr);
        subgraphService.collect(ix.addr, IGraphPayments.PaymentTypes.IndexingRewards, data);
    }

    function _poiMetadata() internal view returns (bytes memory) {
        // forge-lint: disable-next-line(unsafe-typecast)
        return abi.encode(block.number, bytes32("PUBLIC_POI"), uint8(0), uint8(0), uint256(0));
    }
}
