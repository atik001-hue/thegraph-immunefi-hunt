// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../BaseTest.sol";
import {MarketParamsLib} from "../../src/libraries/MarketParamsLib.sol";

contract FlashManipulator is IMorphoFlashLoanCallback {
    IMorpho public morpho;
    MarketParams public marketB;
    ERC20Mock public loanToken;

    function configure(IMorpho _m, MarketParams memory _b, ERC20Mock _loan) external {
        morpho = _m;
        marketB = _b;
        loanToken = _loan;
    }

    function onMorphoFlashLoan(uint256 amount, bytes calldata) external {
        require(msg.sender == address(morpho));
        morpho.borrow(marketB, amount / 2, 0, address(this), address(this));
        loanToken.approve(address(morpho), amount);
    }
}

/// @dev Phase 4 — flash loan cannot borrow in second market without collateral
contract Phase04FlashLoanPoC is BaseTest {
    using MarketParamsLib for MarketParams;

    FlashManipulator internal manipulator;
    MarketParams internal marketB;

    function setUp() public override {
        super.setUp();
        manipulator = new FlashManipulator();
        marketB = MarketParams({
            loanToken: address(loanToken),
            collateralToken: address(collateralToken),
            oracle: address(oracle),
            irm: address(irm),
            lltv: 0.5e18
        });
        vm.prank(OWNER);
        morpho.enableLltv(0.5e18);
        morpho.createMarket(marketB);
        manipulator.configure(morpho, marketB, loanToken);
    }

    function test_flashLoan_crossMarketBorrow_reverts() public {
        _supply(1000e18);
        loanToken.setBalance(address(manipulator), 1000e18);
        vm.startPrank(address(manipulator));
        loanToken.approve(address(morpho), type(uint256).max);
        morpho.supply(marketParams, 500e18, 0, address(manipulator), hex"");
        vm.stopPrank();

        vm.expectRevert();
        morpho.flashLoan(address(loanToken), 100e18, hex"");
    }
}
