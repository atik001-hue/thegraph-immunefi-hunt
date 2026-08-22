// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../BaseTest.sol";

/// @dev Phase 8 — supply/withdraw rounding favor protocol (no supplier drain)
contract Phase08ShareRoundingPoC is BaseTest {
    using MorphoLib for IMorpho;

    function test_manyTinyDeposits_cannotInflateWithdraw() public {
        _supply(1000e18);
        address attacker = makeAddr("attacker");
        loanToken.setBalance(attacker, 1000e18);
        vm.startPrank(attacker);
        loanToken.approve(address(morpho), type(uint256).max);
        for (uint256 i; i < 50; ++i) {
            morpho.supply(marketParams, 1, 0, attacker, hex"");
        }
        uint256 shares = morpho.supplyShares(id, attacker);
        (uint256 assetsOut,) = morpho.withdraw(marketParams, 0, shares, attacker, attacker);
        vm.stopPrank();

        assertLe(assetsOut, 50, "cannot withdraw more than deposited");
        assertGe(morpho.totalSupplyAssets(id), morpho.totalBorrowAssets(id), "solvency");
    }
}
