// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {CometScope} from "../../src/audit/CometScope.sol";

interface ICometLive {
    function getReserves() external view returns (int256);
    function totalSupply() external view returns (uint256);
    function totalBorrow() external view returns (uint256);
    function isAbsorbPaused() external view returns (bool);
}

/// @dev Phase 6 — mainnet USDC Comet fork sanity
contract Phase06MainnetForkPoC is Test {
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

    function test_mainnet_usdcComet_solvency() public {
        if (!_fork()) vm.skip(true, "MAINNET_RPC_URL missing");
        ICometLive c = ICometLive(CometScope.USDC_COMET_MAINNET);
        assertGt(c.totalSupply(), 0);
        assertGe(c.totalSupply(), c.totalBorrow());
    }
}
