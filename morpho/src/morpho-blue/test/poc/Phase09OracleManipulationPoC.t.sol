// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../BaseTest.sol";

/// @dev Phase 9 — oracle price manipulation within single tx (static oracle)
contract Phase09OracleManipulationPoC is BaseTest {
    using MorphoLib for IMorpho;
    using MathLib for uint256;

    function test_oracleSpikeInTx_cannotBorrowBeyondLltv() public {
        _supply(1000e18);
        collateralToken.setBalance(BORROWER, 100e18);
        vm.startPrank(BORROWER);
        morpho.supplyCollateral(marketParams, 100e18, BORROWER, hex"");
        oracle.setPrice(ORACLE_PRICE_SCALE * 2);
        uint256 maxBorrow = uint256(100e18).mulDivDown(ORACLE_PRICE_SCALE * 2, ORACLE_PRICE_SCALE).wMulDown(marketParams.lltv);
        morpho.borrow(marketParams, maxBorrow - 1, 0, BORROWER, BORROWER);
        oracle.setPrice(ORACLE_PRICE_SCALE);
        vm.expectRevert(bytes(ErrorsLib.INSUFFICIENT_COLLATERAL));
        morpho.withdrawCollateral(marketParams, 1, BORROWER, BORROWER);
        vm.stopPrank();
    }
}
