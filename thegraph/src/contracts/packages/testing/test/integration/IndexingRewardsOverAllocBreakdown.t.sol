// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import { IGraphPayments } from "@graphprotocol/interfaces/contracts/horizon/IGraphPayments.sol";
import { IAllocation } from "@graphprotocol/interfaces/contracts/subgraph-service/internal/IAllocation.sol";
import { Allocation } from "subgraph-service/libraries/Allocation.sol";

import { RealRewardsHarness } from "../harness/RealRewardsHarness.t.sol";

/// @title Break down over-alloc downsize vs stopService mint components
contract IndexingRewardsOverAllocBreakdown is RealRewardsHarness {
    using Allocation for IAllocation.State;

    function test_Breakdown_OverAllocVsStopService() public {
        if (!realRmAvailable) {
            vm.skip(true, "RewardsManager artifact missing");
            return;
        }

        uint256 provision = MINIMUM_PROVISION_TOKENS * 10;

        (uint256 stopA, uint256 stopB, uint256 stopTotal) = _run(provision, false);
        (uint256 oaA, uint256 oaB, uint256 oaTotal) = _run(provision, true);

        emit log_named_uint("stopService_A_mint", stopA);
        emit log_named_uint("stopService_B_mint", stopB);
        emit log_named_uint("stopService_total", stopTotal);
        emit log_named_uint("overAlloc_A_mint", oaA);
        emit log_named_uint("overAlloc_B_mint", oaB);
        emit log_named_uint("overAlloc_total", oaTotal);

        assertGt(oaTotal, stopTotal, "over-alloc path mints more protocol GRT than stopService");
    }

    function _run(
        uint256 provision,
        bool useOverAllocCollect
    ) internal returns (uint256 mintA, uint256 mintB, uint256 total) {
        bytes32 subgraph = keccak256(abi.encodePacked("break-", useOverAllocCollect));
        uint256 supply0 = token.totalSupply();

        IndexerSetup memory a = _setupIndexer(string.concat("bk-a-", vm.toString(useOverAllocCollect)), subgraph, provision);
        IndexerSetup memory b = _setupIndexer(string.concat("bk-b-", vm.toString(useOverAllocCollect)), subgraph, provision);

        vm.roll(block.number + 200);
        _collect(b, bytes32("POI-0"));
        skip(7 days);
        vm.roll(block.number + 20);
        _collect(b, bytes32("POI-1"));

        vm.prank(a.addr);
        staking.thaw(a.addr, address(subgraphService), provision / 2);

        if (useOverAllocCollect) {
            uint256 s0 = token.totalSupply();
            _collect(a, bytes32("POI-down"));
            mintA = token.totalSupply() - s0;
        } else {
            uint256 s0 = token.totalSupply();
            vm.prank(a.addr);
            subgraphService.stopService(a.addr, abi.encode(a.allocationId));
            mintA = token.totalSupply() - s0;
        }

        vm.roll(block.number + 100);
        uint256 s1 = token.totalSupply();
        _collect(b, bytes32("POI-final"));
        mintB = token.totalSupply() - s1;
        total = token.totalSupply() - supply0;
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
