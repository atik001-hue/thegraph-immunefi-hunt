// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {EVaultTestBase} from "../EVaultTestBase.t.sol";
import {IEVault} from "../../../../src/EVault/IEVault.sol";
import {IEVC} from "ethereum-vault-connector/interfaces/IEthereumVaultConnector.sol";

/// @dev Phase 2 — free seize when collateralValue rounds to 0 (Liquidation.sol:155-163)
/// Hunt: is this a profitable exploit or documented dust edge?
contract Phase02ZeroCollateralLiquidationPoC is EVaultTestBase {
    address depositor;
    address borrower;
    address liquidator;

    function setUp() public override {
        super.setUp();

        depositor = makeAddr("depositor");
        borrower = makeAddr("borrower");
        liquidator = makeAddr("liquidator");

        oracle.setPrice(address(assetTST), unitOfAccount, 1e18);
        oracle.setPrice(address(eTST2), unitOfAccount, 1e18);
        eTST.setLTV(address(eTST2), 0.9e4, 0.9e4, 0);

        startHoax(depositor);
        assetTST.mint(depositor, type(uint256).max);
        assetTST.approve(address(eTST), type(uint256).max);
        eTST.deposit(100e18, depositor);
        vm.stopPrank();
    }

    function test_zeroCollateralValue_allowsFreeSeize_noProtocolDrain() public {
        startHoax(borrower);
        assetTST2.mint(borrower, 10e18);
        assetTST2.approve(address(eTST2), type(uint256).max);
        eTST2.deposit(10e18, borrower);
        evc.enableCollateral(borrower, address(eTST2));
        evc.enableController(borrower, address(eTST));
        eTST.borrow(5e18, borrower);
        vm.stopPrank();

        // Crash collateral mid-price to 0 → collateralValue == 0 branch
        oracle.setPrice(address(eTST2), unitOfAccount, 0);

        uint256 depositorSharesBefore = eTST.balanceOf(depositor);
        uint256 liquidatorColBefore = eTST2.balanceOf(liquidator);

        startHoax(liquidator);
        evc.enableCollateral(liquidator, address(eTST2));
        evc.enableController(liquidator, address(eTST));
        (uint256 maxRepay, uint256 yieldAmt) = eTST.checkLiquidation(liquidator, borrower, address(eTST2));
        assertEq(maxRepay, 0, "zero repay for worthless collateral");
        assertEq(yieldAmt, 10e18, "full collateral seizable");

        eTST.liquidate(borrower, address(eTST2), 0, 0);
        vm.stopPrank();

        assertEq(eTST2.balanceOf(liquidator), liquidatorColBefore + 10e18, "liquidator received coll");
        assertEq(eTST.balanceOf(depositor), depositorSharesBefore, "depositor share count unchanged");
        // Shares priced at 0 by oracle — not a profitable USD exploit in this setup
        assertEq(oracle.getQuote(eTST2.balanceOf(liquidator), address(eTST2), unitOfAccount), 0);
    }

    function test_deferredViolator_blocksLiquidation() public {
        startHoax(borrower);
        assetTST2.mint(borrower, 10e18);
        assetTST2.approve(address(eTST2), type(uint256).max);
        eTST2.deposit(10e18, borrower);
        evc.enableCollateral(borrower, address(eTST2));
        evc.enableController(borrower, address(eTST));
        eTST.borrow(5e18, borrower);

        oracle.setPrice(address(eTST2), unitOfAccount, 0.1e18);

        assetTST2.mint(borrower, 1);
        IEVC.BatchItem[] memory setup = new IEVC.BatchItem[](2);
        setup[0] = IEVC.BatchItem({
            targetContract: address(eTST2),
            onBehalfOfAccount: borrower,
            value: 0,
            data: abi.encodeWithSignature("deposit(uint256,address)", 1, borrower)
        });
        setup[1] = IEVC.BatchItem({
            targetContract: address(eTST),
            onBehalfOfAccount: liquidator,
            value: 0,
            data: abi.encodeWithSignature("liquidate(address,address,uint256,uint256)", borrower, address(eTST2), type(uint256).max, 0)
        });

        vm.expectRevert();
        evc.batch(setup);
        vm.stopPrank();
    }
}
