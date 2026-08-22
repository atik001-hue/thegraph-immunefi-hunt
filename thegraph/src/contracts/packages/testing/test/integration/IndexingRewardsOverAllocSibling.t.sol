// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import { IGraphPayments } from "@graphprotocol/interfaces/contracts/horizon/IGraphPayments.sol";
import { IAllocation } from "@graphprotocol/interfaces/contracts/subgraph-service/internal/IAllocation.sol";
import { Allocation } from "subgraph-service/libraries/Allocation.sol";

import { RealRewardsHarness } from "../harness/RealRewardsHarness.t.sol";

/// @title Over-allocation auto-downsize with sibling allocation on same subgraph
contract IndexingRewardsOverAllocSibling is RealRewardsHarness {
    using Allocation for IAllocation.State;

    function test_OverAllocDownsize_SiblingNotInflatedBeyondStopService() public {
        if (!realRmAvailable) {
            vm.skip(true, "RewardsManager artifact missing");
            return;
        }

        uint256 provision = MINIMUM_PROVISION_TOKENS * 10;

        uint256 stopServiceTotal = _scenario(provision, 0);
        uint256 overAllocTotal = _scenario(provision, 1);

        emit log_named_uint("stopServiceBaseline", stopServiceTotal);
        emit log_named_uint("overAllocDownsizePath", overAllocTotal);

        assertGt(stopServiceTotal, 0);
        assertLe(overAllocTotal, stopServiceTotal + 1 wei, "over-alloc downsize must not exceed stopService baseline");
    }

    /// @dev mode 0: thaw+stopService on A; mode 1: thaw+collect on A (auto downsize)
    function _scenario(uint256 provision, uint256 mode) internal returns (uint256 totalMint) {
        bytes32 subgraph = keccak256(abi.encodePacked("oas-", mode));
        uint256 supply0 = token.totalSupply();

        IndexerSetup memory a = _setupIndexer(string.concat("oa-a-", vm.toString(mode)), subgraph, provision);
        IndexerSetup memory b = _setupIndexer(string.concat("oa-b-", vm.toString(mode)), subgraph, provision);

        vm.roll(block.number + 200);
        _collect(b, bytes32("POI-0"));
        skip(7 days);
        vm.roll(block.number + 20);
        _collect(b, bytes32("POI-1"));

        vm.prank(a.addr);
        staking.thaw(a.addr, address(subgraphService), provision / 2);

        if (mode == 0) {
            vm.prank(a.addr);
            subgraphService.stopService(a.addr, abi.encode(a.allocationId));
        } else {
            _collect(a, bytes32("POI-downsize"));
            assertEq(subgraphService.getAllocation(a.allocationId).tokens, 0, "A downsized to zero");
        }

        vm.roll(block.number + 100);
        _collect(b, bytes32("POI-final"));

        totalMint = token.totalSupply() - supply0;
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
