// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {GraphScope} from "../../src/audit/GraphScope.sol";
import {IManaged} from "../../src/audit/interfaces/IManaged.sol";

interface IRewardsManagerProbe is IManaged {
    function getAllocatedIssuancePerBlock() external view returns (uint256);
    function subgraphService() external view returns (address);
    function getAccRewardsPerSignal() external view returns (uint256);
    function issuancePerBlock() external view returns (uint256);
}

/// @title RewardsManager fork sanity + PoC scaffold
/// @dev Set MAINNET_RPC_URL / ARBITRUM_RPC_URL in .env before running.
contract RewardsManagerForkTest is Test {
    IRewardsManagerProbe internal rewardsL1;
    IRewardsManagerProbe internal rewardsL2;

    function setUp() public {
        rewardsL1 = IRewardsManagerProbe(GraphScope.REWARDS_MANAGER_L1);
        rewardsL2 = IRewardsManagerProbe(GraphScope.REWARDS_MANAGER_L2);
    }

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

    function _selectForkAtBlock(string memory envKey, uint256 blockNumber) internal returns (bool) {
        string memory rpc;
        try vm.envString(envKey) returns (string memory envRpc) {
            rpc = envRpc;
        } catch {
            return false;
        }
        if (bytes(rpc).length == 0) return false;

        if (blockNumber == 0) {
            try vm.createSelectFork(rpc) {
                return true;
            } catch {
                return false;
            }
        }

        try vm.createSelectFork(rpc, blockNumber) {
            return true;
        } catch {
            return false;
        }
    }

    function test_fork_mainnet_rewardsManager_hasCode() public {
        if (!_selectFork("MAINNET_RPC_URL")) vm.skip(true, "MAINNET_RPC_URL missing or fork failed");
        assertGt(GraphScope.REWARDS_MANAGER_L1.code.length, 0, "L1 RewardsManager has no code");
    }

    function test_fork_mainnet_rewardsManager_controllerSet() public {
        if (!_selectFork("MAINNET_RPC_URL")) vm.skip(true, "MAINNET_RPC_URL missing or fork failed");
        address controller = rewardsL1.controller();
        assertTrue(controller != address(0), "controller is zero");
        assertGt(controller.code.length, 0, "controller has no code");
    }

    function test_fork_arbitrum_rewardsManager_hasCode() public {
        if (!_selectFork("ARBITRUM_RPC_URL")) vm.skip(true, "ARBITRUM_RPC_URL missing or fork failed");
        assertGt(GraphScope.REWARDS_MANAGER_L2.code.length, 0, "L2 RewardsManager has no code");
    }

    function test_fork_arbitrum_rewardsManager_controllerSet() public {
        if (!_selectFork("ARBITRUM_RPC_URL")) vm.skip(true, "ARBITRUM_RPC_URL missing or fork failed");
        address controller = rewardsL2.controller();
        assertTrue(controller != address(0), "controller is zero");
    }

    function test_fork_arbitrum_rewardsManager_liveState() public {
        if (!_selectFork("ARBITRUM_RPC_URL")) vm.skip(true, "ARBITRUM_RPC_URL missing or fork failed");

        address controller = rewardsL2.controller();
        address subgraphService = rewardsL2.subgraphService();
        uint256 accSignal = rewardsL2.getAccRewardsPerSignal();

        emit log_named_address("controller", controller);
        emit log_named_address("subgraphService", subgraphService);
        emit log_named_uint("accRewardsPerSignal", accSignal);

        assertTrue(controller != address(0));
        assertTrue(subgraphService != address(0));
        assertGt(accSignal, 0, "accRewardsPerSignal should be non-zero on live deployment");
    }

    /// @dev Template for a real finding — copy and fill in attack steps.
    function test_POC_placeholder() public {
        if (!_selectForkAtBlock("MAINNET_RPC_URL", GraphScope.MAINNET_FORK_BLOCK)) {
            vm.skip(true, "MAINNET_RPC_URL missing or fork failed");
        }

        // 1. Set up actors
        // address attacker = makeAddr("attacker");

        // 2. Record pre-state (balances, rewards, allocations)
        // uint256 before = ...

        // 3. Execute attack sequence
        // vm.startPrank(attacker);
        // ...
        // vm.stopPrank();

        // 4. Assert impact (fund loss, unauthorized mint, etc.)
        // assertGt(after, before, "attack did not increase attacker balance");

        vm.skip(true, "Replace with a real PoC when a bug is found");
    }
}
