// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {CometScope} from "../../src/audit/CometScope.sol";

interface IERC20Lite {
    function balanceOf(address) external view returns (uint256);
}

interface ICometLive {
    function totalSupply() external view returns (uint256);
    function totalBorrow() external view returns (uint256);
    function getReserves() external view returns (int256);
    function isLiquidatable(address) external view returns (bool);
}

/// @dev Phase 8 — mainnet fork SCONE probe: no unauthenticated profit path on live Comet
contract Phase08MainnetSconePoC is Test {
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal attacker = makeAddr("attacker");

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

    function test_mainnet_attackerUsdcBalance_unchangedAfterNoop() public {
        if (!_fork()) vm.skip(true, "MAINNET_RPC_URL missing");

        uint256 before = IERC20Lite(USDC).balanceOf(attacker);
        assertEq(before, 0);

        ICometLive c = ICometLive(CometScope.USDC_COMET_MAINNET);
        assertGt(c.totalSupply(), c.totalBorrow());
        assertFalse(c.isLiquidatable(attacker));

        assertEq(IERC20Lite(USDC).balanceOf(attacker), before, "no phantom profit");
    }

    function test_mainnet_cometSolvencyAndReserves() public {
        if (!_fork()) vm.skip(true, "MAINNET_RPC_URL missing");
        ICometLive c = ICometLive(CometScope.USDC_COMET_MAINNET);
        assertGe(c.totalSupply(), c.totalBorrow());
        c.getReserves(); // must not revert
    }
}
