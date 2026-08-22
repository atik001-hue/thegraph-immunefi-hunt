// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {GraphScope} from "../../src/audit/GraphScope.sol";

interface IHorizonArchiveProbe {
    function isDelegationSlashingEnabled() external view returns (bool);
    function getMaxThawingPeriod() external view returns (uint64);
}

/// @title Phase 12 — archive fork at Horizon Arbitrum One deployment window
/// @dev Block from horizon-arbitrumOne ignition journal (ExponentialRebates deploy, ~Horizon rollout)
contract Phase12ArchiveForkTest is Test {
    uint256 internal constant HORIZON_ROLLOUT_BLOCK = 399_496_019;

    function _selectForkAtBlock(string memory envKey, uint256 blockNumber) internal returns (bool) {
        string memory rpc;
        try vm.envString(envKey) returns (string memory envRpc) {
            rpc = envRpc;
        } catch {
            return false;
        }
        if (bytes(rpc).length == 0) return false;
        try vm.createSelectFork(rpc, blockNumber) {
            if (block.number != blockNumber) return false;
            return true;
        } catch {
            return false;
        }
    }

    function test_fork_arbitrum_archive_horizonRollout_delegationSlashing() public {
        if (!_selectForkAtBlock("ARBITRUM_RPC_URL", HORIZON_ROLLOUT_BLOCK)) {
            vm.skip(true, "ARBITRUM_RPC_URL missing or archive block unavailable");
        }

        IHorizonArchiveProbe h = IHorizonArchiveProbe(GraphScope.HORIZON_STAKING);
        emit log_named_uint("rolloutBlock", block.number);
        emit log_named_uint("delegationSlashingEnabled", h.isDelegationSlashingEnabled() ? 1 : 0);
        emit log_named_uint("maxThawingPeriod", h.getMaxThawingPeriod());

        assertGt(GraphScope.HORIZON_STAKING.code.length, 0, "HorizonStaking has code at rollout block");
    }

    function test_fork_arbitrum_current_vs_rollout_maxThaw() public {
        if (!_selectForkAtBlock("ARBITRUM_RPC_URL", HORIZON_ROLLOUT_BLOCK)) {
            vm.skip(true, "archive block unavailable");
        }
        uint64 thawAtRollout = IHorizonArchiveProbe(GraphScope.HORIZON_STAKING).getMaxThawingPeriod();

        try vm.createSelectFork(vm.envString("ARBITRUM_RPC_URL")) {} catch {
            vm.skip(true, "current fork failed");
        }
        uint64 thawNow = IHorizonArchiveProbe(GraphScope.HORIZON_STAKING).getMaxThawingPeriod();

        emit log_named_uint("thawAtRollout", thawAtRollout);
        emit log_named_uint("thawNow", thawNow);
        assertGt(thawNow, 0);
    }
}
