// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./CometHuntBase.sol";

/// @dev Phase 5 — oracle/price paths (SCONE: rounding + same-block health)
contract Phase05PriceFeedPoC is CometHuntBase {
    function test_oracleDrop_sameBlock_noWithdrawBypass() public {
        _openBorrowPosition(2e18, 1000e6);
        wethFeed.setRoundData(1, 500e8, block.timestamp, block.timestamp, 1);
        vm.prank(borrower);
        vm.expectRevert();
        comet.withdraw(address(weth), 1e17);
    }

    function test_quoteCollateral_monotonic_withBaseAmount() public {
        _openBorrowPosition(1e18, 2000e6);
        wethFeed.setRoundData(1, 1000e8, block.timestamp, block.timestamp, 1);
        address[] memory accounts = new address[](1);
        accounts[0] = borrower;
        comet.absorb(absorber, accounts);

        uint256 q1 = comet.quoteCollateral(address(weth), 1_000e6);
        uint256 q2 = comet.quoteCollateral(address(weth), 2_000e6);
        assertGt(q2, q1, "quote scales with base input");
        assertGt(q1, 0);
    }

    function test_buyCollateral_revertsWhenReservesHealthy() public {
        _seedMarket();
        int256 reserves = comet.getReserves();
        assertGt(reserves, 0, "sanity: positive reserves in test market");
        usdc.allocateTo(supplier, 1000e6);
        _approve(supplier);
        vm.startPrank(supplier);
        vm.expectRevert();
        comet.buyCollateral(address(weth), 1, 100e6, supplier);
        vm.stopPrank();
    }
}
