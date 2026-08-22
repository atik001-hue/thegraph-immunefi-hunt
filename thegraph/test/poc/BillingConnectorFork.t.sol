// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {GraphScope} from "../../src/audit/GraphScope.sol";

interface IBillingConnectorProbe {
    function l1TokenGateway() external view returns (address);
    function l2Billing() external view returns (address);
    function inbox() external view returns (address);
    function governor() external view returns (address);
}

interface IL1GraphTokenGatewayProbe {
    function callhookAllowlist(address) external view returns (bool);
    function escrow() external view returns (address);
}

interface IBillingProbe {
    function l1BillingConnector() external view returns (address);
    function l2TokenGateway() external view returns (address);
}

/// @title BillingConnector + L2 Billing wiring checks on live forks
contract BillingConnectorForkTest is Test {
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

    function test_fork_mainnet_billingConnector_wiring() public {
        if (!_selectFork("MAINNET_RPC_URL")) vm.skip(true, "MAINNET_RPC_URL missing or fork failed");

        IBillingConnectorProbe connector = IBillingConnectorProbe(GraphScope.BILLING_CONNECTOR);

        address gateway = connector.l1TokenGateway();
        address l2Billing = connector.l2Billing();
        address inbox = connector.inbox();
        address governor = connector.governor();

        emit log_named_address("l1TokenGateway", gateway);
        emit log_named_address("l2Billing", l2Billing);
        emit log_named_address("inbox", inbox);
        emit log_named_address("governor", governor);

        assertEq(gateway, GraphScope.L1_GRAPH_TOKEN_GATEWAY, "unexpected L1 gateway");
        assertEq(l2Billing, GraphScope.L2_BILLING, "unexpected L2 billing");
        assertEq(inbox, GraphScope.ARBITRUM_INBOX, "unexpected inbox");
        assertTrue(governor != address(0), "governor is zero");
        assertGt(GraphScope.BILLING_CONNECTOR.code.length, 0, "BillingConnector has no code");
    }

    function test_fork_mainnet_billingConnector_onCallhookAllowlist() public {
        if (!_selectFork("MAINNET_RPC_URL")) vm.skip(true, "MAINNET_RPC_URL missing or fork failed");

        IL1GraphTokenGatewayProbe gateway = IL1GraphTokenGatewayProbe(GraphScope.L1_GRAPH_TOKEN_GATEWAY);
        bool allowed = gateway.callhookAllowlist(GraphScope.BILLING_CONNECTOR);

        emit log_named_uint("callhookAllowlisted", allowed ? 1 : 0);
        assertTrue(allowed, "BillingConnector must be callhook-allowlisted on L1 gateway");
        assertEq(gateway.escrow(), GraphScope.BRIDGE_ESCROW, "gateway escrow mismatch");
    }

    function test_fork_arbitrum_billing_reciprocalWiring() public {
        if (!_selectFork("ARBITRUM_RPC_URL")) vm.skip(true, "ARBITRUM_RPC_URL missing or fork failed");

        IBillingProbe billing = IBillingProbe(GraphScope.L2_BILLING);

        address l1Connector = billing.l1BillingConnector();
        address l2Gateway = billing.l2TokenGateway();

        emit log_named_address("l1BillingConnector", l1Connector);
        emit log_named_address("l2TokenGateway", l2Gateway);

        assertEq(l1Connector, GraphScope.BILLING_CONNECTOR, "L2 billing L1 connector mismatch");
        assertEq(l2Gateway, GraphScope.L2_GRAPH_TOKEN_GATEWAY, "L2 billing gateway mismatch");
    }
}
