// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./CometHuntBase.sol";
import "../../../contracts/CometExtInterface.sol";

/// @dev Phase 3 — collateral withdraw blocked when underwater
contract Phase03WithdrawCollateralPoC is CometHuntBase {
    function test_withdrawCollateral_revertsWhenUnderwater() public {
        _openBorrowPosition(1e18, 2000e6);
        wethFeed.setRoundData(1, 1000e8, block.timestamp, block.timestamp, 1);
        assertTrue(comet.isLiquidatable(borrower));

        vm.prank(borrower);
        vm.expectRevert();
        comet.withdraw(address(weth), 1e15);
    }

    function test_withdrawCollateral_okWhenHealthy() public {
        _openBorrowPosition(2e18, 1000e6);
        vm.prank(borrower);
        comet.withdraw(address(weth), 1e17);
        assertGt(CometExtInterface(address(comet)).collateralBalanceOf(borrower, address(weth)), 0);
    }
}
