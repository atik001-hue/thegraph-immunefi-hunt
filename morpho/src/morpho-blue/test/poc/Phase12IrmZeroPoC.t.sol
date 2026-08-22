// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../BaseTest.sol";
import {MarketParamsLib} from "../../src/libraries/MarketParamsLib.sol";

/// @dev Phase 12 — IRM zero address (no interest) cannot inflate supply without borrow
contract Phase12IrmZeroPoC is BaseTest {
    using MorphoLib for IMorpho;
    using MarketParamsLib for MarketParams;

    MarketParams internal noIrmMarket;
    Id internal noIrmId;

    function setUp() public override {
        super.setUp();
        noIrmMarket = MarketParams({
            loanToken: address(loanToken),
            collateralToken: address(collateralToken),
            oracle: address(oracle),
            irm: address(0),
            lltv: 0.8e18
        });
        noIrmId = noIrmMarket.id();
        vm.prank(OWNER);
        morpho.createMarket(noIrmMarket);
    }

    function test_zeroIrm_noPhantomInterest() public {
        loanToken.setBalance(address(this), 100e18);
        morpho.supply(noIrmMarket, 100e18, 0, address(this), hex"");
        vm.warp(block.timestamp + 365 days);
        morpho.accrueInterest(noIrmMarket);
        assertEq(morpho.totalSupplyAssets(noIrmId), 100e18, "no interest without IRM");
        assertEq(morpho.totalBorrowAssets(noIrmId), 0);
    }
}
