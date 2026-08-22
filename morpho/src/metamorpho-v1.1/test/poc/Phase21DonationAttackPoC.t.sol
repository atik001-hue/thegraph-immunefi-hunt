// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../helpers/IntegrationTest.sol";

/// @dev Phase 21 — donation on behalf benefits existing shareholders, not attacker theft
contract Phase21DonationAttackPoC is IntegrationTest {
    function setUp() public override {
        super.setUp();
        _setCap(allMarkets[0], CAP);
        _sortSupplyQueueIdleLast();
    }

    function test_donationOnBehalf_benefitsExistingDepositors() public {
        uint256 deposit = 1000e18;
        uint256 donation = 200e18;

        loanToken.setBalance(SUPPLIER, deposit);
        vm.prank(SUPPLIER);
        vault.deposit(deposit, SUPPLIER);

        uint256 shares = vault.balanceOf(SUPPLIER);
        uint256 assetsBefore = vault.convertToAssets(shares);
        uint256 totalBefore = vault.totalAssets();

        loanToken.setBalance(SUPPLIER, donation);
        vm.prank(SUPPLIER);
        morpho.supply(allMarkets[0], donation, 0, address(vault), hex"");

        assertEq(vault.totalAssets(), totalBefore + donation);
        assertGt(vault.convertToAssets(shares), assetsBefore, "donation increases holder claim");
        assertEq(vault.balanceOf(SUPPLIER), shares, "shares unchanged");
    }
}
