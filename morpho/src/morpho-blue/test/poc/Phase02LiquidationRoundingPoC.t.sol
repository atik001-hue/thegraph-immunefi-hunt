// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../BaseTest.sol";

/// @dev Phase 2 — zero-seize liquidation (upstream testSeizedAssetsRoundUp). Hunt: profit for liquidator?
contract Phase02LiquidationRoundingPoC is BaseTest {
    using MorphoLib for IMorpho;

    function test_zeroSeize_liquidatorPaysWithoutCollateralGain() public {
        _setLltv(0.75e18);
        _supply(100e18);

        uint256 amountCollateral = 400;
        uint256 amountBorrowed = 300;
        collateralToken.setBalance(BORROWER, amountCollateral);

        vm.startPrank(BORROWER);
        morpho.supplyCollateral(marketParams, amountCollateral, BORROWER, hex"");
        morpho.borrow(marketParams, amountBorrowed, 0, BORROWER, BORROWER);
        vm.stopPrank();

        oracle.setPrice(ORACLE_PRICE_SCALE - 0.01e18);

        loanToken.setBalance(LIQUIDATOR, 1);
        vm.prank(LIQUIDATOR);
        (uint256 seizedAssets, uint256 repaidAssets) = morpho.liquidate(marketParams, BORROWER, 0, 1, hex"");

        assertEq(seizedAssets, 0, "zero seize confirmed");
        assertEq(repaidAssets, 1, "repaid 1 wei");
        assertEq(collateralToken.balanceOf(LIQUIDATOR), 0, "no collateral profit");
        assertEq(loanToken.balanceOf(LIQUIDATOR), 0, "liquidator spent 1 wei loan token");
    }

    function test_zeroSeize_singleShot_only() public {
        _setLltv(0.75e18);
        _supply(100e18);

        uint256 amountCollateral = 400;
        uint256 amountBorrowed = 300;
        collateralToken.setBalance(BORROWER, amountCollateral);

        vm.startPrank(BORROWER);
        morpho.supplyCollateral(marketParams, amountCollateral, BORROWER, hex"");
        morpho.borrow(marketParams, amountBorrowed, 0, BORROWER, BORROWER);
        vm.stopPrank();

        oracle.setPrice(ORACLE_PRICE_SCALE - 0.01e18);
        loanToken.setBalance(LIQUIDATOR, 1);

        vm.prank(LIQUIDATOR);
        morpho.liquidate(marketParams, BORROWER, 0, 1, hex"");

        vm.prank(LIQUIDATOR);
        vm.expectRevert();
        morpho.liquidate(marketParams, BORROWER, 0, 1, hex"");
    }
}
