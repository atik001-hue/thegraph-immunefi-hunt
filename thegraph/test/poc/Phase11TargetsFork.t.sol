// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {GraphScope} from "../../src/audit/GraphScope.sol";

interface IControllerProbe {
    function paused() external view returns (bool);
    function governor() external view returns (address);
}

interface IGraphPaymentsProbe {
    function PROTOCOL_PAYMENT_CUT() external view returns (uint256);
}

interface IL2GraphTokenProbe {
    function gateway() external view returns (address);
    function l1Address() external view returns (address);
}

interface ISubgraphNFTProbe {
    function minter() external view returns (address);
}

/// @title Phase 11 — GraphPayments, Controller, L2GraphToken, SubgraphNFT live wiring
contract Phase11TargetsForkTest is Test {
    address internal constant CONTROLLER = 0x0a8491544221dd212964fbb96487467291b2C97e;
    address internal constant L2_GRAPH_TOKEN = 0x9623063377AD1B27544C965cCd7342f7EA7e88C7;
    address internal constant SUBGRAPH_NFT = 0x3FbD54f0cc17b7aE649008dEEA12ed7D2622B23f;

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

    function test_fork_arbitrum_controller_notPaused() public {
        if (!_selectFork("ARBITRUM_RPC_URL")) vm.skip(true, "ARBITRUM_RPC_URL missing");

        IControllerProbe controller = IControllerProbe(CONTROLLER);
        assertFalse(controller.paused(), "protocol should not be globally paused");
        assertTrue(controller.governor() != address(0), "controller governor unset");
    }

    function test_fork_arbitrum_graphPayments_hasCodeAndCut() public {
        if (!_selectFork("ARBITRUM_RPC_URL")) vm.skip(true, "ARBITRUM_RPC_URL missing");

        assertGt(GraphScope.GRAPH_PAYMENTS.code.length, 0, "GraphPayments has no code");
        IGraphPaymentsProbe payments = IGraphPaymentsProbe(GraphScope.GRAPH_PAYMENTS);
        assertGt(payments.PROTOCOL_PAYMENT_CUT(), 0, "protocol cut unset");
    }

    function test_fork_arbitrum_l2GraphToken_bridgeWiring() public {
        if (!_selectFork("ARBITRUM_RPC_URL")) vm.skip(true, "ARBITRUM_RPC_URL missing");

        IL2GraphTokenProbe l2Token = IL2GraphTokenProbe(L2_GRAPH_TOKEN);
        assertEq(l2Token.gateway(), GraphScope.L2_GRAPH_TOKEN_GATEWAY, "L2 token gateway mismatch");
        assertEq(l2Token.l1Address(), GraphScope.GRAPH_TOKEN, "L2 token L1 counterpart mismatch");
    }

    function test_fork_arbitrum_subgraphNFT_minterSet() public {
        if (!_selectFork("ARBITRUM_RPC_URL")) vm.skip(true, "ARBITRUM_RPC_URL missing");

        ISubgraphNFTProbe nft = ISubgraphNFTProbe(SUBGRAPH_NFT);
        assertTrue(nft.minter() != address(0), "SubgraphNFT minter unset");
    }
}
