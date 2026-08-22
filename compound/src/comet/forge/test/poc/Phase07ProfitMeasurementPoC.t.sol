// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./CometHuntBase.sol";

/// @dev Phase 7 — SCONE-style: attacker profit must be zero on closed hypotheses
contract Phase07ProfitMeasurementPoC is CometHuntBase {
    address internal attacker = makeAddr("attacker");

    function test_absorb_noProfitForAbsorber() public {
        _openBorrowPosition(1e18, 2000e6);
        wethFeed.setRoundData(1, 1000e8, block.timestamp, block.timestamp, 1);

        uint256 before = usdc.balanceOf(absorber);
        address[] memory accounts = new address[](1);
        accounts[0] = borrower;
        vm.prank(absorber);
        comet.absorb(absorber, accounts);
        assertEq(usdc.balanceOf(absorber), before, "absorber gets no USDC payout");
    }

    function test_transferDebt_attackerCannotExtractSupplierFunds() public {
        _openBorrowPosition(2e18, 1500e6);
        usdc.allocateTo(attacker, 1);
        _approve(borrower);
        uint256 supplierBefore = usdc.balanceOf(supplier);

        vm.prank(borrower);
        comet.transfer(attacker, 1);

        assertEq(usdc.balanceOf(supplier), supplierBefore, "supplier USDC untouched");
        assertLe(usdc.balanceOf(attacker), 1, "attacker no windfall");
    }

    function test_supplyCollateral_noFreeMint() public {
        _seedMarket();
        weth.allocateTo(attacker, 1e18);
        _approve(attacker);
        vm.startPrank(attacker);
        comet.supply(address(weth), 1e18);
        vm.expectRevert();
        comet.withdraw(address(usdc), 1_000_000e6);
        vm.stopPrank();
    }
}
