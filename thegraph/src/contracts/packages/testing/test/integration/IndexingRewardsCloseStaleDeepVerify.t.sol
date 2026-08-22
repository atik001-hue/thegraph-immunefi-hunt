// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import { IGraphPayments } from "@graphprotocol/interfaces/contracts/horizon/IGraphPayments.sol";
import { IAllocation } from "@graphprotocol/interfaces/contracts/subgraph-service/internal/IAllocation.sol";
import { Allocation } from "subgraph-service/libraries/Allocation.sol";

import { RealRewardsHarness } from "../harness/RealRewardsHarness.t.sol";

/// @title Deep verification — total mint + ordering vs denominator effects
contract IndexingRewardsCloseStaleDeepVerify is RealRewardsHarness {
    using Allocation for IAllocation.State;

    function test_DeepVerify_TotalMintSingleVsTwoAllocControlVsAttack() public {
        if (!realRmAvailable) {
            vm.skip(true, "RewardsManager artifact missing");
            return;
        }

        uint256 provision = MINIMUM_PROVISION_TOKENS * 10;

        uint256 singleTotal = _runFullScenario(ScenarioKind.Single);
        uint256 controlTotal = _runFullScenario(ScenarioKind.TwoAllocNoClose);
        uint256 attackTotal = _runFullScenario(ScenarioKind.TwoAllocCloseStale);

        emit log_named_uint("singleTotalMint", singleTotal);
        emit log_named_uint("controlTotalMint", controlTotal);
        emit log_named_uint("attackTotalMint", attackTotal);

        // If attack == single, inflation is only vs diluted control, not vs fair solo baseline.
        assertApproxEqRel(attackTotal, singleTotal, 0.05e18, "attack total mint ~= single-alloc baseline");
        assertGt(attackTotal, controlTotal, "attack mints more than stale-diluted control");
    }

    function test_DeepVerify_FinalCollectOnlyMatchesPriorPoCs() public {
        if (!realRmAvailable) {
            vm.skip(true, "RewardsManager artifact missing");
            return;
        }

        (uint256 controlFinal, uint256 attackFinal) = _finalCollectOnly();

        emit log_named_uint("controlFinalCollect", controlFinal);
        emit log_named_uint("attackFinalCollect", attackFinal);

        assertEq(controlFinal, 5000 ether, "control final collect");
        assertEq(attackFinal, 10000 ether, "attack final collect");
        assertEq(attackFinal, controlFinal * 2, "exact 2x on final collect");
    }

    enum ScenarioKind {
        Single,
        TwoAllocNoClose,
        TwoAllocCloseStale
    }

    function _runFullScenario(ScenarioKind kind) internal returns (uint256 totalMint) {
        bytes32 subgraph = keccak256(abi.encodePacked("deep-", uint256(kind)));
        uint256 provision = MINIMUM_PROVISION_TOKENS * 10;
        uint256 supply0 = token.totalSupply();

        if (kind == ScenarioKind.Single) {
            IndexerSetup memory ix = _setupIndexer(string.concat("deep-single-", vm.toString(uint256(kind))), subgraph, provision);
            _poiCycle(ix);
            vm.roll(block.number + 100);
            _collect(ix, bytes32("POI-final"));
        } else {
            IndexerSetup memory stale = _setupIndexer(string.concat("deep-stale-", vm.toString(uint256(kind))), subgraph, provision);
            IndexerSetup memory live = _setupIndexer(string.concat("deep-live-", vm.toString(uint256(kind))), subgraph, provision);
            _poiCycle(live);
            assertTrue(subgraphService.getAllocation(stale.allocationId).isStale(MAX_POI_STALENESS));
            if (kind == ScenarioKind.TwoAllocCloseStale) {
                subgraphService.closeStaleAllocation(stale.allocationId);
            }
            vm.roll(block.number + 100);
            _collect(live, bytes32("POI-final"));
        }

        totalMint = token.totalSupply() - supply0;
    }

    function _finalCollectOnly() internal returns (uint256 controlFinal, uint256 attackFinal) {
        uint256 provision = MINIMUM_PROVISION_TOKENS * 10;

        bytes32 sgCtrl = keccak256("deep-final-ctrl");
        IndexerSetup memory sC = _setupIndexer("fc-stale-c", sgCtrl, provision);
        IndexerSetup memory lC = _setupIndexer("fc-live-c", sgCtrl, provision);
        _poiCycle(lC);
        assertTrue(subgraphService.getAllocation(sC.allocationId).isStale(MAX_POI_STALENESS));
        vm.roll(block.number + 100);
        uint256 b0 = token.totalSupply();
        _collect(lC, bytes32("POI-final"));
        controlFinal = token.totalSupply() - b0;

        bytes32 sgAtk = keccak256("deep-final-atk");
        IndexerSetup memory sA = _setupIndexer("fc-stale-a", sgAtk, provision);
        IndexerSetup memory lA = _setupIndexer("fc-live-a", sgAtk, provision);
        _poiCycle(lA);
        assertTrue(subgraphService.getAllocation(sA.allocationId).isStale(MAX_POI_STALENESS));
        subgraphService.closeStaleAllocation(sA.allocationId);
        vm.roll(block.number + 100);
        uint256 b1 = token.totalSupply();
        _collect(lA, bytes32("POI-final"));
        attackFinal = token.totalSupply() - b1;
    }

    function _poiCycle(IndexerSetup memory ix) internal {
        vm.roll(block.number + 200);
        _collect(ix, bytes32("POI-0"));
        skip(7 days);
        vm.roll(block.number + 20);
        _collect(ix, bytes32("POI-1"));
        skip(7 days);
        vm.roll(block.number + 20);
        _collect(ix, bytes32("POI-2"));
        skip(15 days);
    }

    function _collect(IndexerSetup memory ix, bytes32 poi) internal {
        bytes memory data = abi.encode(ix.allocationId, poi, _poiMetadata());
        vm.prank(ix.addr);
        subgraphService.collect(ix.addr, IGraphPayments.PaymentTypes.IndexingRewards, data);
    }

    function _poiMetadata() internal view returns (bytes memory) {
        // forge-lint: disable-next-line(unsafe-typecast)
        return abi.encode(block.number, bytes32("PUBLIC_POI"), uint8(0), uint8(0), uint256(0));
    }
}
