// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import { IGraphPayments } from "@graphprotocol/interfaces/contracts/horizon/IGraphPayments.sol";
import { IAllocation } from "@graphprotocol/interfaces/contracts/subgraph-service/internal/IAllocation.sol";
import { IRewardsManager } from "@graphprotocol/interfaces/contracts/contracts/rewards/IRewardsManager.sol";
import { Allocation } from "subgraph-service/libraries/Allocation.sol";

import { RealRewardsHarness } from "../harness/RealRewardsHarness.t.sol";
import { DenyOracle, IRealRewardsManagerAdmin } from "./IndexingRewardsDeferredClose.t.sol";

/// @title deny → defer → undeny → collect (real RewardsManager)
contract IndexingRewardsDenyUndenyCollect is RealRewardsHarness {
    using Allocation for IAllocation.State;

    DenyOracle internal oracle;

    function setUp() public override {
        super.setUp();
        if (!realRmAvailable) return;
        oracle = new DenyOracle(realRewardsManager);
        vm.prank(governor);
        IRealRewardsManagerAdmin(address(realRewardsManager)).setSubgraphAvailabilityOracle(address(oracle));
    }

    function test_DenyDeferUndenyCollect_NoExcessVsControl() public {
        if (!realRmAvailable) {
            vm.skip(true, "RewardsManager artifact missing");
            return;
        }

        uint256 controlMint = _runLifecycle(false);
        uint256 attackMint = _runLifecycle(true);

        emit log_named_uint("neverDeniedControl", controlMint);
        emit log_named_uint("denyUndenyPath", attackMint);

        assertGt(controlMint, 0, "control mints rewards");
        assertLe(attackMint, controlMint + 1 wei, "deny/undeny must not mint more than control");
    }

    function _runLifecycle(bool useDeny) internal returns (uint256 totalMint) {
        bytes32 subgraph = keccak256(abi.encodePacked("deny-", useDeny));
        IndexerSetup memory ix = _setupIndexer(useDeny ? "deny-ix" : "ctrl-ix", subgraph, MINIMUM_PROVISION_TOKENS * 10);
        bytes memory collectData = abi.encode(ix.allocationId, bytes32("POI"), _poiMetadata());
        uint256 supply0 = token.totalSupply();

        vm.roll(block.number + 200);

        if (useDeny) {
            oracle.setDenied(subgraph, true);
            vm.prank(ix.addr);
            subgraphService.collect(ix.addr, IGraphPayments.PaymentTypes.IndexingRewards, collectData);
            assertEq(subgraphService.getAllocation(ix.allocationId).accRewardsPending, 0);
            oracle.setDenied(subgraph, false);
            vm.roll(block.number + 200);
        } else {
            vm.roll(block.number + 200);
        }

        vm.prank(ix.addr);
        subgraphService.collect(ix.addr, IGraphPayments.PaymentTypes.IndexingRewards, collectData);

        skip(7 days);
        vm.roll(block.number + 50);
        vm.prank(ix.addr);
        subgraphService.collect(ix.addr, IGraphPayments.PaymentTypes.IndexingRewards, collectData);

        totalMint = token.totalSupply() - supply0;
    }

    function _poiMetadata() internal view returns (bytes memory) {
        // forge-lint: disable-next-line(unsafe-typecast)
        return abi.encode(block.number, bytes32("PUBLIC_POI"), uint8(0), uint8(0), uint256(0));
    }
}
