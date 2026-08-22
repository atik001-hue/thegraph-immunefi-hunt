// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../BaseTest.sol";

/// @dev Phase 13 — unauthorized withdraw/borrow blocked
contract Phase13UnauthorizedPoC is BaseTest {
    using MorphoLib for IMorpho;

    function test_unauthorizedWithdraw_reverts() public {
        _supply(100e18);
        vm.prank(LIQUIDATOR);
        vm.expectRevert(bytes(ErrorsLib.UNAUTHORIZED));
        morpho.withdraw(marketParams, 1e18, 0, address(this), LIQUIDATOR);
    }

    function test_unauthorizedBorrow_reverts() public {
        _supply(100e18);
        collateralToken.setBalance(BORROWER, 10e18);
        vm.startPrank(BORROWER);
        morpho.supplyCollateral(marketParams, 10e18, BORROWER, hex"");
        vm.stopPrank();
        vm.prank(LIQUIDATOR);
        vm.expectRevert(bytes(ErrorsLib.UNAUTHORIZED));
        morpho.borrow(marketParams, 1e18, 0, BORROWER, LIQUIDATOR);
    }
}
