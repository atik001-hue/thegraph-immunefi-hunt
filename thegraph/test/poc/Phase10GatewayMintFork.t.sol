// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {GraphScope} from "../../src/audit/GraphScope.sol";

interface IL1GatewayMintProbe {
    function totalMintedFromL2() external view returns (uint256);
    function l2MintAllowancePerBlock() external view returns (uint256);
    function accumulatedL2MintAllowanceSnapshot() external view returns (uint256);
    function lastL2MintAllowanceUpdateBlock() external view returns (uint256);
    function accumulatedL2MintAllowanceAtBlock(uint256 blockNum) external view returns (uint256);
    function l2Counterpart() external view returns (address);
}

/// @title Phase 10 — L1 gateway L2-mint allowance headroom / drift checks
contract Phase10GatewayMintForkTest is Test {
    function _selectFork(string memory envKey) internal returns (bool) {
        string memory rpc;
        try vm.envString(envKey) returns (string memory envRpc) {
            rpc = envRpc;
        } catch {
            return false;
        }
        if (bytes(rpc).length == 0) return false;
        try vm.createSelectFork(rpc) {
            return true;
        } catch {
            return false;
        }
    }

    function test_fork_mainnet_l1Gateway_mintAllowanceHeadroom() public {
        if (!_selectFork("MAINNET_RPC_URL")) vm.skip(true, "MAINNET_RPC_URL missing");

        IL1GatewayMintProbe gw = IL1GatewayMintProbe(GraphScope.L1_GRAPH_TOKEN_GATEWAY);

        uint256 totalMinted = gw.totalMintedFromL2();
        uint256 allowedNow = gw.accumulatedL2MintAllowanceAtBlock(block.number);
        uint256 headroom = allowedNow > totalMinted ? allowedNow - totalMinted : 0;

        emit log_named_uint("totalMintedFromL2", totalMinted);
        emit log_named_uint("allowedAtCurrentBlock", allowedNow);
        emit log_named_uint("headroom", headroom);
        emit log_named_uint("l2MintAllowancePerBlock", gw.l2MintAllowancePerBlock());

        assertGe(allowedNow, totalMinted, "mint allowance must cover historical L2 mints");
        assertEq(gw.l2Counterpart(), GraphScope.L2_GRAPH_TOKEN_GATEWAY);
    }

    /// @dev If headroom is enormous vs per-block rate, governor may have lagged updating allowance after issuance change.
    function test_fork_mainnet_l1Gateway_allowanceConfigSane() public {
        if (!_selectFork("MAINNET_RPC_URL")) vm.skip(true, "MAINNET_RPC_URL missing");

        IL1GatewayMintProbe gw = IL1GatewayMintProbe(GraphScope.L1_GRAPH_TOKEN_GATEWAY);
        uint256 perBlock = gw.l2MintAllowancePerBlock();
        uint256 updateBlock = gw.lastL2MintAllowanceUpdateBlock();

        assertGt(perBlock, 0);
        assertLt(updateBlock, block.number, "allowance update block should be in past");
    }
}
