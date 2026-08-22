// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../BaseTest.sol";

/// @dev Phase 5 — borrow 0 assets / 1 share inflation + bad debt cap (upstream testBadDebtOverTotalBorrowAssets)
contract Phase05BadDebtShareInflationPoC is BaseTest {
    using MorphoLib for IMorpho;
    using MathLib for uint256;
    using SharesMathLib for uint256;

    function test_shareInflation_badDebtCappedByTotalBorrow() public {
        uint256 collateralAmount = 10 ether;
        uint256 loanAmount = 1 ether;
        _supply(loanAmount);

        collateralToken.setBalance(BORROWER, collateralAmount);
        vm.startPrank(BORROWER);
        morpho.supplyCollateral(marketParams, collateralAmount, BORROWER, hex"");
        morpho.borrow(marketParams, loanAmount, 0, BORROWER, BORROWER);
        morpho.borrow(marketParams, 0, 1, BORROWER, BORROWER);
        vm.stopPrank();

        uint256 totalBorrowBefore = morpho.totalBorrowAssets(id);
        oracle.setPrice(1e36 / 100);

        loanToken.setBalance(LIQUIDATOR, loanAmount);
        vm.prank(LIQUIDATOR);
        morpho.liquidate(marketParams, BORROWER, collateralAmount, 0, hex"");

        assertEq(morpho.totalBorrowAssets(id), 0, "bad debt cleared");
        assertLe(morpho.totalSupplyAssets(id), loanAmount, "supply not inflated beyond deposit");
        assertGe(totalBorrowBefore, loanAmount, "sanity");
    }

    function test_attackerCannotBorrowExcessiveShares() public {
        _supply(1000e18);
        collateralToken.setBalance(BORROWER, 1e18);
        vm.startPrank(BORROWER);
        morpho.supplyCollateral(marketParams, 1e18, BORROWER, hex"");
        (uint256 maxAssets,) = _maxBorrowAssets(BORROWER);
        vm.expectRevert(bytes(ErrorsLib.INSUFFICIENT_COLLATERAL));
        morpho.borrow(marketParams, maxAssets + 1 ether, 0, BORROWER, BORROWER);
        vm.stopPrank();
    }

    function _maxBorrowAssets(address borrower) internal view returns (uint256 assets, uint256 shares) {
        uint256 col = morpho.collateral(id, borrower);
        uint256 price = oracle.price();
        assets = col.mulDivDown(price, ORACLE_PRICE_SCALE).wMulDown(marketParams.lltv);
        shares = assets.toSharesUp(morpho.totalBorrowAssets(id), morpho.totalBorrowShares(id));
    }
}
