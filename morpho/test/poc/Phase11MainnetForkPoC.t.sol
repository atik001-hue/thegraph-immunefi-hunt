// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {MorphoScope} from "../../src/audit/MorphoScope.sol";

interface IMorphoProbe {
    function owner() external view returns (address);
}

/// @dev Phase 11 — mainnet fork sanity + IRM deployed
contract Phase11MainnetForkPoC is Test {
    function _fork() internal returns (bool) {
        try vm.envString("MAINNET_RPC_URL") returns (string memory rpc) {
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

    function test_mainnet_morphoBlue_and_irm() public {
        if (!_fork()) vm.skip(true, "MAINNET_RPC_URL missing");
        assertGt(MorphoScope.MORPHO_BLUE_MAINNET.code.length, 0);
        assertGt(MorphoScope.ADAPTIVE_CURVE_IRM_MAINNET.code.length, 0);
        assertTrue(IMorphoProbe(MorphoScope.MORPHO_BLUE_MAINNET).owner() != address(0));
    }
}
