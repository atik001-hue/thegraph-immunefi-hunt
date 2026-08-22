// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {MorphoScope} from "../../src/audit/MorphoScope.sol";

interface IMorphoProbe {
    function owner() external view returns (address);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

/// @title Phase 1 — Morpho Blue mainnet fork sanity
contract MorphoBlueForkTest is Test {
    function _fork(string memory envKey) internal returns (bool) {
        try vm.envString(envKey) returns (string memory rpc) {
            if (bytes(rpc).length == 0) return false;
            try vm.createSelectFork(rpc) {
                return true;
            } catch {
                return false;
            }
        } catch {
            return false;
        }
    }

    function test_fork_mainnet_morphoBlue_hasCode() public {
        if (!_fork("MAINNET_RPC_URL")) vm.skip(true, "MAINNET_RPC_URL missing");
        assertGt(MorphoScope.MORPHO_BLUE_MAINNET.code.length, 0);
    }

    function test_fork_mainnet_morphoBlue_ownerSet() public {
        if (!_fork("MAINNET_RPC_URL")) vm.skip(true, "MAINNET_RPC_URL missing");
        address owner = IMorphoProbe(MorphoScope.MORPHO_BLUE_MAINNET).owner();
        assertTrue(owner != address(0));
    }
}
