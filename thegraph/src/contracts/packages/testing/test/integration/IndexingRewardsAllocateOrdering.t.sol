// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import { IGraphPayments } from "@graphprotocol/interfaces/contracts/horizon/IGraphPayments.sol";
import { IAllocation } from "@graphprotocol/interfaces/contracts/subgraph-service/internal/IAllocation.sol";
import { Allocation } from "subgraph-service/libraries/Allocation.sol";

import { RealRewardsHarness } from "../harness/RealRewardsHarness.t.sol";

/// @title allocate() calls onSubgraphAllocationUpdate BEFORE incrementing subgraph tokens
contract IndexingRewardsAllocateOrdering is RealRewardsHarness {
    using Allocation for IAllocation.State;

    function test_SecondAllocationOpen_DoesNotInflateFirstAllocMint() public {
        if (!realRmAvailable) {
            vm.skip(true, "RewardsManager artifact missing");
            return;
        }

        uint256 provision = MINIMUM_PROVISION_TOKENS * 10;

        uint256 singleMint = _singleAllocCollect(provision);
        uint256 twinMint = _twoAllocSameIndexerCollect(provision);

        emit log_named_uint("singleAllocCollect", singleMint);
        emit log_named_uint("afterSecondAllocOpen", twinMint);

        assertGt(singleMint, 0);
        assertLe(twinMint, singleMint + 1 wei, "opening 2nd allocation must not inflate 1st collect");
    }

    function test_AttackerSecondAllocOnVictimSubgraph_DoesNotStealMint() public {
        if (!realRmAvailable) {
            vm.skip(true, "RewardsManager artifact missing");
            return;
        }

        uint256 provision = MINIMUM_PROVISION_TOKENS * 10;
        bytes32 subgraph = keccak256("victim-subgraph");

        IndexerSetup memory victim = _setupIndexer("victim-ix", subgraph, provision);

        vm.roll(block.number + 200);

        uint256 victimOnlyMint = _collectMint(victim);

        // Attacker opens competing allocation on same subgraph
        bytes32 subgraph2 = keccak256("victim-subgraph-2");
        IndexerSetup memory v2 = _setupIndexer("victim-ix-b", subgraph2, provision);
        IndexerSetup memory attacker = _setupIndexer("attacker-ix", subgraph2, provision);

        vm.roll(block.number + 200);
        uint256 victimAfterAttackMint = _collectMint(v2);

        emit log_named_uint("victimSoloMint", victimOnlyMint);
        emit log_named_uint("victimWithAttackerAlloc", victimAfterAttackMint);

        assertLe(victimAfterAttackMint, victimOnlyMint + 1 wei, "attacker alloc must not inflate victim mint");
    }

    function _singleAllocCollect(uint256 provision) internal returns (uint256 mint) {
        bytes32 subgraph = keccak256("single-alloc-order");
        IndexerSetup memory ix = _setupIndexer("solo-order", subgraph, provision);
        vm.roll(block.number + 200);
        return _collectMint(ix);
    }

    function _twoAllocSameIndexerCollect(uint256 provision) internal returns (uint256 mint) {
        bytes32 subgraph = keccak256("twin-alloc-order");
        address rogue = makeAddr("rogue-twin");

        IndexerSetup memory first = _setupExtra(rogue, subgraph, provision, "first");
        vm.roll(block.number + 200);
        _setupExtra(rogue, subgraph, provision, "second");
        vm.roll(block.number + 50);
        return _collectMint(first);
    }

    function _collectMint(IndexerSetup memory ix) internal returns (uint256 mint) {
        uint256 before = token.totalSupply();
        bytes memory data = abi.encode(ix.allocationId, bytes32("POI"), _poiMetadata());
        vm.prank(ix.addr);
        subgraphService.collect(ix.addr, IGraphPayments.PaymentTypes.IndexingRewards, data);
        return token.totalSupply() - before;
    }

    function _setupExtra(
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

        (ix.allocationId, ix.allocationKey) = makeAddrAndKey(string.concat("ao-", label));
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
