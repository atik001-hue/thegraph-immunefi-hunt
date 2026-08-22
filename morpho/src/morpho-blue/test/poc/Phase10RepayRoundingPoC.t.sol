// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../BaseTest.sol";

/// @dev Phase 10 — repay 1 wei over totalBorrowAssets comment in Morpho.sol
contract Phase10RepayRoundingPoC is BaseTest {
    using MorphoLib for IMorpho;

    function test_fullRepayByShares_clearsDebt() public {
        _supply(100e18);
        collateralToken.setBalance(BORROWER, 50e18);
        vm.startPrank(BORROWER);
        morpho.supplyCollateral(marketParams, 50e18, BORROWER, hex"");
        morpho.borrow(marketParams, 30e18, 0, BORROWER, BORROWER);
        uint256 shares = morpho.borrowShares(id, BORROWER);
        loanToken.setBalance(BORROWER, 30e18);
        morpho.repay(marketParams, 0, shares, BORROWER, hex"");
        vm.stopPrank();

        assertEq(morpho.borrowShares(id, BORROWER), 0);
        assertEq(morpho.totalBorrowAssets(id), 0);
    }
}
