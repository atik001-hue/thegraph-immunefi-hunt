// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import { IGraphPayments } from "@graphprotocol/interfaces/contracts/horizon/IGraphPayments.sol";
import { IAllocation } from "@graphprotocol/interfaces/contracts/subgraph-service/internal/IAllocation.sol";
import { Allocation } from "subgraph-service/libraries/Allocation.sol";

import { RealRewardsHarness } from "../harness/RealRewardsHarness.t.sol";

/// @title L-11 probe — stale POI reclaim then close allocation (double-mint / reward leak)
contract IndexingRewardsStaleCloseTest is RealRewardsHarness {
    using Allocation for IAllocation.State;

    bytes32 internal constant SUBGRAPH = keccak256("stale-close-subgraph");

    function test_StalePOIReclaimThenClose_NoDoubleMint() public {
        if (!realRmAvailable) {
            vm.skip(true, "RewardsManager artifact missing");
            return;
        }

        IndexerSetup memory ix = _setupIndexer("stale-close-indexer", SUBGRAPH, MINIMUM_PROVISION_TOKENS * 10);

        vm.roll(block.number + 200);

        skip(MAX_POI_STALENESS + 1);

        bytes memory collectData = abi.encode(ix.allocationId, bytes32("POI"), _poiMetadata());

        uint256 supplyBefore = token.totalSupply();
        vm.prank(ix.addr);
        uint256 staleCollected = subgraphService.collect(
            ix.addr,
            IGraphPayments.PaymentTypes.IndexingRewards,
            collectData
        );
        assertEq(staleCollected, 0, "stale POI reclaims rather than paying indexer");

        uint256 mintedAfterStale = token.totalSupply() - supplyBefore;

        vm.prank(ix.addr);
        subgraphService.stopService(ix.addr, abi.encode(ix.allocationId));

        IAllocation.State memory afterClose = subgraphService.getAllocation(ix.allocationId);
        assertFalse(afterClose.isOpen(), "allocation closed");

        uint256 mintedThroughClose = token.totalSupply() - supplyBefore - mintedAfterStale;

        vm.prank(ix.addr);
        vm.expectRevert();
        subgraphService.collect(ix.addr, IGraphPayments.PaymentTypes.IndexingRewards, collectData);

        assertLe(mintedThroughClose, 1 ether, "unexpected large mint on close after stale reclaim");
    }

    function _poiMetadata() internal view returns (bytes memory) {
        // forge-lint: disable-next-line(unsafe-typecast)
        return abi.encode(block.number, bytes32("PUBLIC_POI"), uint8(0), uint8(0), uint256(0));
    }
}
