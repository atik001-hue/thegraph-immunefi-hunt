// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {GraphScope} from "../../src/audit/GraphScope.sol";

interface IDisputeManagerProbe {
    function arbitrator() external view returns (address);
    function controller() external view returns (address);
}

interface IGraphTallyCollectorProbe {
    function eip712Domain()
        external
        view
        returns (bytes1 fields, string memory name, string memory version, uint256 chainId, address verifyingContract, bytes32 salt, uint256[] memory extensions);
}

interface IManagedProbe {
    function controller() external view returns (address);
}

/// @title Phase 5 in-scope targets — live fork wiring checks
contract Phase5TargetsForkTest is Test {
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

    function test_fork_arbitrum_disputeManager_wiring() public {
        if (!_selectFork("ARBITRUM_RPC_URL")) vm.skip(true, "ARBITRUM_RPC_URL missing or fork failed");

        IDisputeManagerProbe dm = IDisputeManagerProbe(GraphScope.DISPUTE_MANAGER_L2);

        address arbitrator = dm.arbitrator();
        address controller = dm.controller();

        emit log_named_address("arbitrator", arbitrator);
        emit log_named_address("controller", controller);

        assertGt(GraphScope.DISPUTE_MANAGER_L2.code.length, 0);
        assertTrue(arbitrator != address(0), "arbitrator is zero");
        assertEq(controller, IManagedProbe(GraphScope.REWARDS_MANAGER_L2).controller(), "controller mismatch");
    }

    function test_fork_mainnet_disputeManager_hasCode() public {
        if (!_selectFork("MAINNET_RPC_URL")) vm.skip(true, "MAINNET_RPC_URL missing or fork failed");
        assertGt(GraphScope.DISPUTE_MANAGER_L1.code.length, 0, "L1 DisputeManager has no code");
    }

    function test_fork_arbitrum_allocationExchange_hasCode() public {
        if (!_selectFork("ARBITRUM_RPC_URL")) vm.skip(true, "ARBITRUM_RPC_URL missing or fork failed");
        assertGt(GraphScope.ALLOCATION_EXCHANGE.code.length, 0, "AllocationExchange has no code");
    }

    function test_fork_arbitrum_graphTallyCollector_wiring() public {
        if (!_selectFork("ARBITRUM_RPC_URL")) vm.skip(true, "ARBITRUM_RPC_URL missing or fork failed");

        IGraphTallyCollectorProbe tally = IGraphTallyCollectorProbe(GraphScope.GRAPH_TALLY_COLLECTOR);

        (
            ,
            string memory name,
            ,
            uint256 chainId,
            address verifyingContract,
            ,
        ) = tally.eip712Domain();

        emit log_string(name);
        emit log_named_uint("chainId", chainId);
        emit log_named_address("verifyingContract", verifyingContract);

        assertGt(GraphScope.GRAPH_TALLY_COLLECTOR.code.length, 0);
        assertEq(verifyingContract, GraphScope.GRAPH_TALLY_COLLECTOR);
        assertEq(chainId, block.chainid);
        assertEq(keccak256(bytes(name)), keccak256("GraphTallyCollector"));
    }
}
