// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import { IGraphPayments } from "@graphprotocol/interfaces/contracts/horizon/IGraphPayments.sol";
import { IAllocation } from "@graphprotocol/interfaces/contracts/subgraph-service/internal/IAllocation.sol";
import { IRewardsManager } from "@graphprotocol/interfaces/contracts/contracts/rewards/IRewardsManager.sol";
import { Allocation } from "subgraph-service/libraries/Allocation.sol";

import { RealRewardsHarness } from "../harness/RealRewardsHarness.t.sol";

/// @dev Minimal oracle so governor can wire denylist on the real RewardsManager.
contract DenyOracle {
    IRewardsManager public immutable rewardsManager;

    constructor(IRewardsManager _rewardsManager) {
        rewardsManager = _rewardsManager;
    }

    function setDenied(bytes32 subgraphDeploymentId, bool deny) external {
        rewardsManager.setDenied(subgraphDeploymentId, deny);
    }
}

interface IRealRewardsManagerAdmin {
    function setSubgraphAvailabilityOracle(address oracle) external;
    function setSubgraphService(address subgraphService) external;
    function setIssuancePerBlock(uint256 issuancePerBlock) external;
}

/// @title H-R1 — deferred POI (SUBGRAPH_DENIED) then close allocation
/// @notice Tests whether rewards are double-minted, stolen, or incorrectly dropped when:
///   1. Indexer accrues indexing rewards
///   2. POI collection hits SUBGRAPH_DENIED (deferred, no snapshot)
///   3. Indexer closes the allocation
contract IndexingRewardsDeferredCloseTest is RealRewardsHarness {
    using Allocation for IAllocation.State;

    bytes32 internal constant SUBGRAPH = keccak256("hr1-deferred-close-subgraph");

    function test_HR1_DenyThenClose_NoDoubleMint() public {
        if (!realRmAvailable) {
            vm.skip(true, "RewardsManager artifact missing");
            return;
        }

        IndexerSetup memory ix = _setupIndexer("hr1-indexer", SUBGRAPH, MINIMUM_PROVISION_TOKENS * 10);

        // Wire deny oracle on real RewardsManager
        DenyOracle oracle = new DenyOracle(realRewardsManager);
        vm.startPrank(governor);
        IRealRewardsManagerAdmin(address(realRewardsManager)).setSubgraphAvailabilityOracle(address(oracle));
        vm.stopPrank();

        vm.roll(block.number + 200);

        // Deny subgraph — next POI collect will defer (SUBGRAPH_DENIED path)
        oracle.setDenied(ix.subgraphDeploymentId, true);

        bytes memory collectData = abi.encode(ix.allocationId, bytes32("POI"), _poiMetadata());

        uint256 supplyBefore = token.totalSupply();
        vm.prank(ix.addr);
        uint256 deferredCollected = subgraphService.collect(
            ix.addr,
            IGraphPayments.PaymentTypes.IndexingRewards,
            collectData
        );
        assertEq(deferredCollected, 0, "denied subgraph defers mint on collect");

        IAllocation.State memory afterDeferred = subgraphService.getAllocation(ix.allocationId);
        assertTrue(afterDeferred.isOpen(), "allocation stays open after deferred POI");

        // Close allocation while denied
        vm.prank(ix.addr);
        subgraphService.stopService(ix.addr, abi.encode(ix.allocationId));

        IAllocation.State memory afterClose = subgraphService.getAllocation(ix.allocationId);
        assertFalse(afterClose.isOpen(), "allocation closed");

        uint256 mintedThroughClose = token.totalSupply() - supplyBefore;

        // Attempt second collect on closed allocation — must revert
        vm.prank(ix.addr);
        vm.expectRevert();
        subgraphService.collect(ix.addr, IGraphPayments.PaymentTypes.IndexingRewards, collectData);

        // Lift denial and roll — closed allocation must not pay again
        oracle.setDenied(ix.subgraphDeploymentId, false);
        vm.roll(block.number + 200);

        uint256 supplyBeforeSecond = token.totalSupply();
        vm.prank(ix.addr);
        vm.expectRevert();
        subgraphService.collect(ix.addr, IGraphPayments.PaymentTypes.IndexingRewards, collectData);

        assertEq(token.totalSupply(), supplyBeforeSecond, "no mint after close on denied/deferred path");
        assertLe(mintedThroughClose, 1 ether, "unexpected large mint on close while denied");
    }

    function _poiMetadata() internal view returns (bytes memory) {
        // forge-lint: disable-next-line(unsafe-typecast)
        return abi.encode(block.number, bytes32("PUBLIC_POI"), uint8(0), uint8(0), uint256(0));
    }
}
