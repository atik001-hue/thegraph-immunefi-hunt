// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./CometHuntBase.sol";

/// @dev Phase 4 — base transfer cannot bypass collateral check on sender
contract Phase04TransferDebtPoC is CometHuntBase {
    address internal receiver = makeAddr("receiver");

    function test_transferBase_debtStaysCollateralized() public {
        _openBorrowPosition(2e18, 1500e6);
        _approve(borrower);

        vm.prank(borrower);
        comet.transfer(receiver, 100e6);

        assertGt(comet.borrowBalanceOf(borrower), 0);
        assertFalse(comet.isLiquidatable(borrower));

        wethFeed.setRoundData(1, 500e8, block.timestamp, block.timestamp, 1);
        assertTrue(comet.isLiquidatable(borrower));
    }

    function test_transferBase_revertsIfWouldUndercollateralize() public {
        _openBorrowPosition(1e18, 2500e6);
        _approve(borrower);
        vm.prank(borrower);
        vm.expectRevert();
        comet.transfer(receiver, 500e6);
    }
}
