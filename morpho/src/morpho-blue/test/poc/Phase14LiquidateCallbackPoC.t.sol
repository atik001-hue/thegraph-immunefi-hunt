// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../BaseTest.sol";

/// @dev Phase 14 — liquidate callback cannot skip loan repayment
contract Phase14LiquidateCallbackPoC is BaseTest {
    using MorphoLib for IMorpho;

    function test_liquidateWithoutLoanPayment_reverts() public {
        _setLltv(0.75e18);
        _supply(100e18);
        uint256 col = 400;
        uint256 debt = 300;
        collateralToken.setBalance(BORROWER, col);
        vm.startPrank(BORROWER);
        morpho.supplyCollateral(marketParams, col, BORROWER, hex"");
        morpho.borrow(marketParams, debt, 0, BORROWER, BORROWER);
        vm.stopPrank();
        oracle.setPrice(ORACLE_PRICE_SCALE - 0.01e18);
        loanToken.setBalance(LIQUIDATOR, debt);
        vm.prank(LIQUIDATOR);
        vm.expectRevert();
        morpho.liquidate(marketParams, BORROWER, col, 0, hex"");
    }
}
