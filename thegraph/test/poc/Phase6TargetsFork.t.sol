// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {GraphScope} from "../../src/audit/GraphScope.sol";

interface IHorizonStakingProbe {
    function getMaxThawingPeriod() external view returns (uint64);
    function isDelegationSlashingEnabled() external view returns (bool);
}

interface IEpochManagerProbe {
    function currentEpoch() external view returns (uint256);
    function epochLength() external view returns (uint256);
    function isCurrentEpochRun() external view returns (bool);
}

interface IRewardsManagerL1Probe {
    function controller() external view returns (address);
    function getAccRewardsPerSignal() external view returns (uint256);
    function getAllocatedIssuancePerBlock() external view returns (uint256);
    function getRawIssuancePerBlock() external view returns (uint256);
    function issuancePerBlock() external view returns (uint256);
}

/// @title Phase 6 — HorizonStaking, EpochManager, L1 RewardsManager fork checks
contract Phase6TargetsForkTest is Test {
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

    function test_fork_arbitrum_horizonStaking_maxThawingPeriod() public {
        if (!_selectFork("ARBITRUM_RPC_URL")) vm.skip(true, "ARBITRUM_RPC_URL missing or fork failed");

        IHorizonStakingProbe staking = IHorizonStakingProbe(GraphScope.HORIZON_STAKING);

        uint64 maxThaw = staking.getMaxThawingPeriod();
        bool delegationSlash = staking.isDelegationSlashingEnabled();

        emit log_named_uint("maxThawingPeriodSeconds", maxThaw);
        emit log_named_uint("delegationSlashingEnabled", delegationSlash ? 1 : 0);

        assertGt(GraphScope.HORIZON_STAKING.code.length, 0);
        assertGt(maxThaw, 0, "maxThawingPeriod must be configured");
        assertLe(maxThaw, 90 days, "maxThawingPeriod unexpectedly high (OZ M-01 check)");
    }

    function test_fork_arbitrum_epochManager_liveState() public {
        if (!_selectFork("ARBITRUM_RPC_URL")) vm.skip(true, "ARBITRUM_RPC_URL missing or fork failed");

        IEpochManagerProbe epochs = IEpochManagerProbe(GraphScope.EPOCH_MANAGER);

        uint256 epoch = epochs.currentEpoch();
        uint256 length = epochs.epochLength();
        bool run = epochs.isCurrentEpochRun();

        emit log_named_uint("currentEpoch", epoch);
        emit log_named_uint("epochLengthBlocks", length);
        emit log_named_uint("isCurrentEpochRun", run ? 1 : 0);

        assertGt(GraphScope.EPOCH_MANAGER.code.length, 0);
        assertGt(epoch, 0);
        assertGt(length, 0);
    }

    function test_fork_mainnet_rewardsManagerL1_issuanceState() public {
        if (!_selectFork("MAINNET_RPC_URL")) vm.skip(true, "MAINNET_RPC_URL missing or fork failed");

        IRewardsManagerL1Probe rm = IRewardsManagerL1Probe(GraphScope.REWARDS_MANAGER_L1);

        address controller = rm.controller();
        uint256 accSignal = rm.getAccRewardsPerSignal();

        emit log_named_address("controller", controller);
        emit log_named_uint("accRewardsPerSignal", accSignal);

        assertGt(GraphScope.REWARDS_MANAGER_L1.code.length, 0);
        assertTrue(controller != address(0));
        assertGt(accSignal, 0);

        // L1 may use IssuanceAllocator — probe without reverting the whole test
        try rm.getAllocatedIssuancePerBlock() returns (uint256 allocated) {
            emit log_named_uint("allocatedIssuancePerBlock", allocated);
            assertGt(allocated, 0);
        } catch {
            emit log("getAllocatedIssuancePerBlock reverted - may need allocator context");
        }

        try rm.getRawIssuancePerBlock() returns (uint256 raw) {
            emit log_named_uint("rawIssuancePerBlock", raw);
        } catch {}
    }
}

interface IManagedProbe {
    function controller() external view returns (address);
}
