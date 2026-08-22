// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./CometHuntBase.sol";
import "../../../contracts/CometExtInterface.sol";

/// @dev Phase 2 — absorb socializes bad debt; absorber cannot drain reserves
contract Phase02AbsorbPoC is CometHuntBase {
    function test_absorb_underwaterAccount_reservesCoverDebt() public {
        uint256 collateral = 1e18;
        uint256 borrow = 2000e6;
        _openBorrowPosition(collateral, borrow);

        assertFalse(comet.isLiquidatable(borrower));
        wethFeed.setRoundData(1, 1000e8, block.timestamp, block.timestamp, 1);
        assertTrue(comet.isLiquidatable(borrower));

        int256 reservesBefore = comet.getReserves();
        uint256 supplierBefore = comet.balanceOf(supplier);

        address[] memory accounts = new address[](1);
        accounts[0] = borrower;
        comet.absorb(absorber, accounts);

        assertFalse(comet.isLiquidatable(borrower));
        assertEq(comet.borrowBalanceOf(borrower), 0);
        assertEq(CometExtInterface(address(comet)).collateralBalanceOf(borrower, address(weth)), 0);
        assertLe(comet.getReserves(), reservesBefore, "absorb consumes reserves");
        assertGe(comet.balanceOf(supplier), supplierBefore, "supplier not drained by absorb");
    }

    function test_absorb_revertsIfHealthy() public {
        _openBorrowPosition(2e18, 1000e6);
        address[] memory accounts = new address[](1);
        accounts[0] = borrower;
        vm.expectRevert();
        comet.absorb(absorber, accounts);
    }
}
