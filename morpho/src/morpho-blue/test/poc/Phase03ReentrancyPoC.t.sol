// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../BaseTest.sol";

contract ReentrantAttacker is IMorphoSupplyCallback, IMorphoRepayCallback {
    IMorpho public morpho;
    MarketParams public marketParams;
    ERC20Mock public loanToken;
    uint256 public reentered;

    function configure(IMorpho _morpho, MarketParams memory _mp, ERC20Mock _loan) external {
        morpho = _morpho;
        marketParams = _mp;
        loanToken = _loan;
    }

    function onMorphoSupply(uint256, bytes calldata) external {
        require(msg.sender == address(morpho));
        reentered++;
        morpho.withdraw(marketParams, 1, 0, address(this), address(this));
    }

    function onMorphoRepay(uint256 amount, bytes calldata) external {
        require(msg.sender == address(morpho));
        loanToken.approve(address(morpho), amount);
        reentered++;
        morpho.borrow(marketParams, 1, 0, address(this), address(this));
    }
}

/// @dev Phase 3 — callback reentrancy: allowed mid-tx but must not drain protocol (Certora reentrancySafe)
contract Phase03ReentrancyPoC is BaseTest {
    using MorphoLib for IMorpho;

    ReentrantAttacker internal attacker;

    function setUp() public override {
        super.setUp();
        attacker = new ReentrantAttacker();
        loanToken.setBalance(address(attacker), 1000e18);
        collateralToken.setBalance(address(attacker), 1000e18);
        vm.startPrank(address(attacker));
        loanToken.approve(address(morpho), type(uint256).max);
        collateralToken.approve(address(morpho), type(uint256).max);
        vm.stopPrank();
        attacker.configure(morpho, marketParams, loanToken);
    }

    function test_supplyCallback_reenterWithdraw_noProtocolDrain() public {
        _supply(1000e18);
        loanToken.setBalance(address(attacker), 100e18);
        uint256 morphoBefore = loanToken.balanceOf(address(morpho));

        vm.prank(address(attacker));
        morpho.supply(marketParams, 100e18, 0, address(attacker), hex"01");

        assertEq(attacker.reentered(), 1, "reentered withdraw");
        assertGe(loanToken.balanceOf(address(morpho)), morphoBefore, "morpho solvency preserved");
    }

    function test_repayCallback_reenterBorrow_noExtraDebt() public {
        _supply(1000e18);
        vm.startPrank(address(attacker));
        morpho.supply(marketParams, 500e18, 0, address(attacker), hex"");
        morpho.supplyCollateral(marketParams, 500e18, address(attacker), hex"");
        morpho.borrow(marketParams, 200e18, 0, address(attacker), address(attacker));
        uint256 debtBefore = morpho.borrowShares(id, address(attacker));
        morpho.repay(marketParams, 1e18, 0, address(attacker), hex"01");
        vm.stopPrank();

        assertEq(attacker.reentered(), 1, "reentered borrow");
        assertLe(morpho.borrowShares(id, address(attacker)), debtBefore, "no net debt inflation");
    }
}
