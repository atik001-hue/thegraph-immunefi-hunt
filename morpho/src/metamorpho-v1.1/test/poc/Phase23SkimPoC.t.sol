// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../helpers/IntegrationTest.sol";

/// @dev Phase 23 — permissionless skim sends to skimRecipient only (not attacker)
contract Phase23SkimPoC is IntegrationTest {
    address internal attacker = makeAddr("attacker");

    function test_skim_goesToRecipient_notCaller() public {
        uint256 reward = 100e18;
        loanToken.setBalance(address(vault), reward);

        uint256 attackerBefore = loanToken.balanceOf(attacker);
        uint256 recipientBefore = loanToken.balanceOf(SKIM_RECIPIENT);

        vm.prank(attacker);
        vault.skim(address(loanToken));

        assertEq(loanToken.balanceOf(attacker), attackerBefore, "attacker gets nothing");
        assertEq(loanToken.balanceOf(SKIM_RECIPIENT), recipientBefore + reward, "skimRecipient gets tokens");
        assertEq(loanToken.balanceOf(address(vault)), 0);
    }
}
