// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {CometScope} from "../../src/audit/CometScope.sol";

/// @dev Compound Phase 1 — mainnet Comet fork sanity
interface ICometProbe {
    function baseToken() external view returns (address);
    function numAssets() external view returns (uint8);
    function isAbsorbPaused() external view returns (bool);
}

contract CompoundForkPoC is Test {
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

    function test_fork_mainnet_usdcComet_live() public {
        if (!_fork()) vm.skip(true, "MAINNET_RPC_URL missing");
        assertGt(CometScope.USDC_COMET_MAINNET.code.length, 0);
        assertTrue(ICometProbe(CometScope.USDC_COMET_MAINNET).baseToken() != address(0));
        assertGt(ICometProbe(CometScope.USDC_COMET_MAINNET).numAssets(), 0);
    }
}
