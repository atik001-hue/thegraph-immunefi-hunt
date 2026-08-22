// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../BaseTest.sol";

/// @dev Phase 6 — fee share mint rounding in _accrueInterest
contract Phase06FeeAccrualPoC is BaseTest {
    using MorphoLib for IMorpho;
    using SharesMathLib for uint256;

    function setUp() public override {
        super.setUp();
        vm.prank(OWNER);
        morpho.setFee(marketParams, 0.1e18); // 10%
    }

    function test_feeAccrual_doesNotOvermintFeeRecipient() public {
        _supply(1e18);
        collateralToken.setBalance(BORROWER, 10e18);
        vm.startPrank(BORROWER);
        morpho.supplyCollateral(marketParams, 10e18, BORROWER, hex"");
        morpho.borrow(marketParams, 0.5e18, 0, BORROWER, BORROWER);
        vm.stopPrank();

        vm.warp(block.timestamp + 365 days);
        morpho.accrueInterest(marketParams);

        uint256 feeShares = morpho.supplyShares(id, FEE_RECIPIENT);
        uint256 feeAssets = feeShares.toAssetsDown(morpho.totalSupplyAssets(id), morpho.totalSupplyShares(id));
        uint256 interest = morpho.totalSupplyAssets(id) - 1e18;

        assertLe(feeAssets, interest, "fee recipient cannot exceed accrued interest");
        assertLe(morpho.totalBorrowAssets(id), morpho.totalSupplyAssets(id), "solvency");
    }
}
