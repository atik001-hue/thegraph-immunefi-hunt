// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {GraphScope} from "../../src/audit/GraphScope.sol";

interface IERC20Probe {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface IL1GraphTokenGatewayProbe {
    function escrow() external view returns (address);
    function totalMintedFromL2() external view returns (uint256);
    function l2MintAllowancePerBlock() external view returns (uint256);
    function accumulatedL2MintAllowanceSnapshot() external view returns (uint256);
    function lastL2MintAllowanceUpdateBlock() external view returns (uint256);
    function l2Counterpart() external view returns (address);
}

/// @title Bridge escrow + L1 gateway allowance sanity on live mainnet fork
contract BridgeEscrowForkTest is Test {
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

    function test_fork_mainnet_bridgeEscrow_hasBalanceAndAllowance() public {
        if (!_selectFork("MAINNET_RPC_URL")) vm.skip(true, "MAINNET_RPC_URL missing or fork failed");

        IL1GraphTokenGatewayProbe gateway = IL1GraphTokenGatewayProbe(GraphScope.L1_GRAPH_TOKEN_GATEWAY);
        IERC20Probe grt = IERC20Probe(GraphScope.GRAPH_TOKEN);

        address escrow = gateway.escrow();
        assertEq(escrow, GraphScope.BRIDGE_ESCROW, "gateway escrow mismatch");

        uint256 escrowBalance = grt.balanceOf(escrow);
        uint256 allowance = grt.allowance(escrow, GraphScope.L1_GRAPH_TOKEN_GATEWAY);

        emit log_named_uint("escrowBalanceGRT", escrowBalance);
        emit log_named_uint("gatewayAllowance", allowance);

        assertGt(escrowBalance, 0, "bridge escrow should hold GRT");
        assertGe(allowance, escrowBalance, "gateway allowance should cover escrow balance");
    }

    function test_fork_mainnet_l1Gateway_l2MintAllowanceHealthy() public {
        if (!_selectFork("MAINNET_RPC_URL")) vm.skip(true, "MAINNET_RPC_URL missing or fork failed");

        IL1GraphTokenGatewayProbe gateway = IL1GraphTokenGatewayProbe(GraphScope.L1_GRAPH_TOKEN_GATEWAY);

        uint256 totalMinted = gateway.totalMintedFromL2();
        uint256 perBlock = gateway.l2MintAllowancePerBlock();
        uint256 snapshot = gateway.accumulatedL2MintAllowanceSnapshot();
        uint256 updateBlock = gateway.lastL2MintAllowanceUpdateBlock();
        address l2Counterpart = gateway.l2Counterpart();

        emit log_named_uint("totalMintedFromL2", totalMinted);
        emit log_named_uint("l2MintAllowancePerBlock", perBlock);
        emit log_named_uint("accumulatedSnapshot", snapshot);
        emit log_named_uint("lastUpdateBlock", updateBlock);
        emit log_named_address("l2Counterpart", l2Counterpart);

        assertEq(l2Counterpart, GraphScope.L2_GRAPH_TOKEN_GATEWAY, "L2 counterpart mismatch");
        assertGt(perBlock, 0, "L2 mint allowance per block should be configured");
        assertGe(snapshot, totalMinted, "accumulated allowance should cover minted-from-L2 total");
    }
}
