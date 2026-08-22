// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import { IGraphPayments } from "@graphprotocol/interfaces/contracts/horizon/IGraphPayments.sol";

import { RealRewardsHarness } from "../harness/RealRewardsHarness.t.sol";

/// @title Validate allocate()-before-tokens inflation for Immunefi
contract IndexingRewardsAllocateInflationVerify is RealRewardsHarness {
    function test_Verify_SingleVsTwinTotalMint() public {
        if (!realRmAvailable) {
            vm.skip(true, "RewardsManager artifact missing");
            return;
        }

        uint256 provision = MINIMUM_PROVISION_TOKENS * 10;
        uint256 singleTotal = _totalMintSingle(provision);
        uint256 twinTotal = _totalMintTwinSameIndexer(provision);

        emit log_named_uint("singleTotal", singleTotal);
        emit log_named_uint("twinTotal", twinTotal);

        assertGt(singleTotal, 0);
        // Key question: does opening a 2nd allocation inflate TOTAL protocol mint vs solo?
        assertLe(twinTotal, singleTotal + 1 wei, "twin allocations must not exceed solo total mint");
    }

    function test_Verify_FirstCollectInflationAmount() public {
        if (!realRmAvailable) {
            vm.skip(true, "RewardsManager artifact missing");
            return;
        }

        uint256 provision = MINIMUM_PROVISION_TOKENS * 10;
        uint256 solo = _firstCollectOnly(provision, false);
        uint256 twin = _firstCollectOnly(provision, true);

        emit log_named_uint("soloFirstCollect", solo);
        emit log_named_uint("twinFirstCollect", twin);

        assertGt(solo, 0);
        assertGt(twin, solo, "allocate ordering inflates first collect when 2nd alloc opened");
    }

    function _totalMintSingle(uint256 provision) internal returns (uint256 total) {
        bytes32 subgraph = keccak256("verify-single");
        IndexerSetup memory ix = _setupIndexer("vs-single", subgraph, provision);
        uint256 s0 = token.totalSupply();
        vm.roll(block.number + 200);
        _collect(ix);
        skip(7 days);
        vm.roll(block.number + 50);
        _collect(ix);
        return token.totalSupply() - s0;
    }

    function _totalMintTwinSameIndexer(uint256 provision) internal returns (uint256 total) {
        bytes32 subgraph = keccak256("verify-twin");
        address rogue = makeAddr("verify-rogue");
        uint256 s0 = token.totalSupply();

        IndexerSetup memory a = _openSecondAlloc(rogue, subgraph, provision, "a");
        vm.roll(block.number + 200);
        _openSecondAlloc(rogue, subgraph, provision, "b");
        vm.roll(block.number + 50);
        _collect(a);
        skip(7 days);
        vm.roll(block.number + 50);
        _collect(a);

        return token.totalSupply() - s0;
    }

    function _firstCollectOnly(uint256 provision, bool openTwin) internal returns (uint256 mint) {
        bytes32 subgraph = keccak256(abi.encodePacked("fc-", openTwin));
        address rogue = makeAddr("fc-rogue");
        IndexerSetup memory a = _openSecondAlloc(rogue, subgraph, provision, "x");
        vm.roll(block.number + 200);
        if (openTwin) {
            _openSecondAlloc(rogue, subgraph, provision, "y");
            vm.roll(block.number + 50);
        }
        uint256 before = token.totalSupply();
        _collect(a);
        return token.totalSupply() - before;
    }

    function _openSecondAlloc(
        address indexer,
        bytes32 subgraph,
        uint256 provision,
        string memory label
    ) internal returns (IndexerSetup memory ix) {
        (string memory url,) = subgraphService.indexers(indexer);
        if (bytes(url).length == 0) {
            _mintTokens(indexer, provision * 3);
            vm.startPrank(indexer);
            token.approve(address(staking), provision * 3);
            staking.stakeTo(indexer, provision * 3);
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

        (ix.allocationId, ix.allocationKey) = makeAddrAndKey(string.concat("vi-", label));
        ix.addr = indexer;
        ix.subgraphDeploymentId = subgraph;
        ix.provisionTokens = provision;

        bytes32 digest = subgraphService.encodeAllocationProof(indexer, ix.allocationId);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ix.allocationKey, digest);
        bytes memory data = abi.encode(subgraph, provision, ix.allocationId, abi.encodePacked(r, s, v));
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
