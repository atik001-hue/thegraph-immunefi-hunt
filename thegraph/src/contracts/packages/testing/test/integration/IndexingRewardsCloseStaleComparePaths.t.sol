// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import { IGraphPayments } from "@graphprotocol/interfaces/contracts/horizon/IGraphPayments.sol";
import { IAllocation } from "@graphprotocol/interfaces/contracts/subgraph-service/internal/IAllocation.sol";
import { Allocation } from "subgraph-service/libraries/Allocation.sol";

import { RealRewardsHarness } from "../harness/RealRewardsHarness.t.sol";

/// @title Compare closeStale vs stopService vs leaving stale sibling
contract IndexingRewardsCloseStaleComparePaths is RealRewardsHarness {
    using Allocation for IAllocation.State;

    function test_ComparePaths_TotalMint() public {
        if (!realRmAvailable) {
            vm.skip(true, "RewardsManager artifact missing");
            return;
        }

        uint256 noClose = _scenario(0);
        uint256 closeStale = _scenario(1);
        uint256 stopService = _scenario(2);
        uint256 single = _scenario(3);

        emit log_named_uint("noCloseStale", noClose);
        emit log_named_uint("closeStalePath", closeStale);
        emit log_named_uint("stopServicePath", stopService);
        emit log_named_uint("singleAlloc", single);

        assertGt(closeStale, noClose, "closeStale mints more than leaving stale sibling");
        assertApproxEqRel(closeStale, single, 0.10e18, "closeStale total within 10% of single baseline");
    }

    /// @dev mode: 0=no action, 1=closeStale, 2=stopService on stale, 3=single indexer
    function _scenario(uint256 mode) internal returns (uint256 totalMint) {
        bytes32 subgraph = keccak256(abi.encodePacked("cmp-", mode));
        uint256 provision = MINIMUM_PROVISION_TOKENS * 10;
        uint256 supply0 = token.totalSupply();

        if (mode == 3) {
            IndexerSetup memory ix = _setupIndexer(string.concat("solo-", vm.toString(mode)), subgraph, provision);
            _cycle(ix);
            vm.roll(block.number + 100);
            _collect(ix, bytes32("POI-final"));
            return token.totalSupply() - supply0;
        }

        IndexerSetup memory stale = _setupIndexer(string.concat("st-", vm.toString(mode)), subgraph, provision);
        IndexerSetup memory live = _setupIndexer(string.concat("lv-", vm.toString(mode)), subgraph, provision);
        _cycle(live);

        if (mode == 1) {
            subgraphService.closeStaleAllocation(stale.allocationId);
        } else if (mode == 2) {
            vm.prank(stale.addr);
            subgraphService.stopService(stale.addr, abi.encode(stale.allocationId));
        }

        vm.roll(block.number + 100);
        _collect(live, bytes32("POI-final"));
        return token.totalSupply() - supply0;
    }

    function _cycle(IndexerSetup memory ix) internal {
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
