// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import { IGraphPayments } from "@graphprotocol/interfaces/contracts/horizon/IGraphPayments.sol";
import { IAllocation } from "@graphprotocol/interfaces/contracts/subgraph-service/internal/IAllocation.sol";
import { Allocation } from "subgraph-service/libraries/Allocation.sol";

import { RealRewardsHarness } from "../harness/RealRewardsHarness.t.sol";

/// @title Permissionless closeStaleAllocation vs sibling indexer reward capture
contract IndexingRewardsCloseStaleTwoIndexerTest is RealRewardsHarness {
    using Allocation for IAllocation.State;

    address internal attacker = makeAddr("attacker");

    /// @dev A goes stale while B keeps presenting POIs. Compare B's mint when attacker
    ///      force-resizes A to zero vs control where A stays allocated but stale.
    function test_CloseStaleSibling_NoOverMintVsControl() public {
        if (!realRmAvailable) {
            vm.skip(true, "RewardsManager artifact missing");
            return;
        }

        uint256 attackMint = _measureSurvivorMint(true);
        uint256 controlMint = _measureSurvivorMint(false);

        emit log_named_uint("controlMint", controlMint);
        emit log_named_uint("attackMint", attackMint);

        assertGt(controlMint, 0, "control scenario should mint indexing rewards to survivor");
        // Documents confirmed inflation bug — test fails intentionally until fixed
        assertLe(attackMint, controlMint + 1 wei, "closeStale must not inflate survivor mint");
    }

    function _measureSurvivorMint(bool useCloseStale) internal returns (uint256 survivorMint) {
        bytes32 subgraph = keccak256(abi.encodePacked("two-ix-", useCloseStale));
        uint256 provision = MINIMUM_PROVISION_TOKENS * 10;

        IndexerSetup memory ixA = _setupIndexer(useCloseStale ? "ix-a-attack" : "ix-a-ctrl", subgraph, provision);
        IndexerSetup memory ixB = _setupIndexer(useCloseStale ? "ix-b-attack" : "ix-b-ctrl", subgraph, provision);

        vm.roll(block.number + 200);

        // B keeps presenting; A never presents POI
        _collectIndexing(ixB, bytes32("POI-0"));
        skip(7 days);
        vm.roll(block.number + 20);
        _collectIndexing(ixB, bytes32("POI-1"));
        skip(7 days);
        vm.roll(block.number + 20);
        _collectIndexing(ixB, bytes32("POI-2"));

        // 29 days since allocation creation; A never presented POI → stale. B last POI ~7 days ago → fresh.
        skip(15 days);

        assertTrue(subgraphService.getAllocation(ixA.allocationId).isStale(MAX_POI_STALENESS));
        assertFalse(subgraphService.getAllocation(ixB.allocationId).isStale(MAX_POI_STALENESS));

        if (useCloseStale) {
            vm.prank(attacker);
            subgraphService.closeStaleAllocation(ixA.allocationId);
            assertEq(subgraphService.getAllocation(ixA.allocationId).tokens, 0);
            assertEq(subgraphService.getSubgraphAllocatedTokens(subgraph), provision);
        }

        vm.roll(block.number + 100);

        uint256 before = token.totalSupply();
        _collectIndexing(ixB, bytes32("POI-final"));
        survivorMint = token.totalSupply() - before;
    }

    function _collectIndexing(IndexerSetup memory ix, bytes32 poi) internal {
        bytes memory data = abi.encode(ix.allocationId, poi, _poiMetadata());
        vm.prank(ix.addr);
        subgraphService.collect(ix.addr, IGraphPayments.PaymentTypes.IndexingRewards, data);
    }

    function test_CloseStaleThenStopService_NoDoubleMint() public {
        if (!realRmAvailable) {
            vm.skip(true, "RewardsManager artifact missing");
            return;
        }

        bytes32 subgraph = keccak256("solo-close-stale");
        IndexerSetup memory ix = _setupIndexer("solo", subgraph, MINIMUM_PROVISION_TOKENS * 10);

        vm.roll(block.number + 200);
        skip(MAX_POI_STALENESS + 1);

        uint256 supplyStart = token.totalSupply();

        vm.prank(attacker);
        subgraphService.closeStaleAllocation(ix.allocationId);

        vm.prank(ix.addr);
        subgraphService.stopService(ix.addr, abi.encode(ix.allocationId));

        bytes memory collectData = abi.encode(ix.allocationId, bytes32("POI"), _poiMetadata());
        vm.prank(ix.addr);
        vm.expectRevert();
        subgraphService.collect(ix.addr, IGraphPayments.PaymentTypes.IndexingRewards, collectData);

        assertLe(token.totalSupply() - supplyStart, 1 ether, "no large mint on closeStale+stop path");
    }

    function _poiMetadata() internal view returns (bytes memory) {
        // forge-lint: disable-next-line(unsafe-typecast)
        return abi.encode(block.number, bytes32("PUBLIC_POI"), uint8(0), uint8(0), uint256(0));
    }
}
