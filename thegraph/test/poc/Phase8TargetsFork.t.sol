// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {GraphScope} from "../../src/audit/GraphScope.sol";

interface IL2GNSProbe {
    function MAX_ROUNDING_ERROR() external view returns (uint256);
    function controller() external view returns (address);
}

interface IAllocationExchangeProbe {
    function authority(address account) external view returns (bool);
}

/// @title Phase 8 — L2GNS, StakingExtension, AllocationExchange fork probes
contract Phase8TargetsForkTest is Test {
    address internal constant L2GNS = 0xec9A7fb6CbC2E41926127929c2dcE6e9c5D33Bec;
    address internal constant STAKING_EXTENSION = 0x3bE385576d7C282070Ad91BF94366de9f9ba3571;
    address internal constant ALLOCATION_EXCHANGE = 0x993F00C98D1678371a7b261Ed0E0D4b6F42d9aEE;

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

    function test_fork_arbitrum_l2gns_roundingParams() public {
        if (!_selectFork("ARBITRUM_RPC_URL")) vm.skip(true, "ARBITRUM_RPC_URL missing or fork failed");

        IL2GNSProbe gns = IL2GNSProbe(L2GNS);
        uint256 maxRounding = gns.MAX_ROUNDING_ERROR();
        address ctrl = gns.controller();

        emit log_named_uint("MAX_ROUNDING_ERROR_ppm", maxRounding);
        emit log_named_address("controller", ctrl);

        assertGt(L2GNS.code.length, 0);
        assertEq(maxRounding, 1000, "expected 1000 PPM rounding tolerance");
        assertTrue(ctrl != address(0));
    }

    function test_fork_arbitrum_stakingExtension_hasCode() public {
        if (!_selectFork("ARBITRUM_RPC_URL")) vm.skip(true, "ARBITRUM_RPC_URL missing or fork failed");

        // StakingExtension is delegatecalled from L2Staking; storage lives on the proxy, not this impl.
        assertGt(STAKING_EXTENSION.code.length, 0);
        emit log_named_uint("stakingExtensionBytecodeBytes", STAKING_EXTENSION.code.length);
    }

    function test_fork_arbitrum_allocationExchange_hasCode() public {
        if (!_selectFork("ARBITRUM_RPC_URL")) vm.skip(true, "ARBITRUM_RPC_URL missing or fork failed");

        assertGt(ALLOCATION_EXCHANGE.code.length, 0);

        // Spot-check authority mapping is readable (governance-controlled EOA set)
        IAllocationExchangeProbe ex = IAllocationExchangeProbe(ALLOCATION_EXCHANGE);
        bool govAuth = ex.authority(GraphScope.GOVERNOR);
        emit log_named_uint("governorIsAuthority", govAuth ? 1 : 0);
    }
}
