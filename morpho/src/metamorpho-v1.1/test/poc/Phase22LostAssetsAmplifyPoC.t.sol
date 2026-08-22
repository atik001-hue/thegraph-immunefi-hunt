// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../helpers/IntegrationTest.sol";

/// @dev Phase 22 — lostAssets 1-wei dust cannot be amplified to theft
contract Phase22LostAssetsAmplifyPoC is IntegrationTest {
    function setUp() public override {
        super.setUp();
        _setCap(allMarkets[0], CAP);
        _sortSupplyQueueIdleLast();
    }

    function test_lostAssetsDust_noWithdrawProfit() public {
        loanToken.setBalance(SUPPLIER, 10 ether);
        vm.prank(SUPPLIER);
        vault.deposit(10 ether, SUPPLIER);

        uint256 before = loanToken.balanceOf(SUPPLIER);
        loanToken.setBalance(SUPPLIER, 100);
        for (uint256 i; i < 20; ++i) {
            vm.startPrank(SUPPLIER);
            vault.deposit(1, SUPPLIER);
            vault.deposit(0, SUPPLIER);
            if (vault.maxWithdraw(SUPPLIER) > 0) {
                vault.withdraw(1, SUPPLIER, SUPPLIER);
            }
            vm.stopPrank();
        }
        uint256 afterBal = loanToken.balanceOf(SUPPLIER);
        assertLe(afterBal, before + 120, "no material profit from dust loop");
        assertLe(vault.lostAssets(), 100, "lostAssets stays dust-scale");
    }
}
