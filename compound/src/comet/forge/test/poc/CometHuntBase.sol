// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../../../contracts/test/CometHarnessExtendedAssetList.sol";
import "../../../contracts/CometConfiguration.sol";
import "../../../contracts/CometExtAssetList.sol";
import "../../../contracts/AssetListFactory.sol";
import "../../../contracts/test/FaucetToken.sol";
import "../../../contracts/test/SimplePriceFeed.sol";

/// @dev Shared Comet harness deployment for hunt PoCs
abstract contract CometHuntBase is Test {
    uint256 internal constant FACTOR = 1e18;
    uint256 internal constant PRICE_SCALE = 1e8;

    CometHarnessExtendedAssetList internal comet;
    FaucetToken internal usdc;
    FaucetToken internal weth;
    SimplePriceFeed internal usdcFeed;
    SimplePriceFeed internal wethFeed;

    address internal governor = makeAddr("governor");
    address internal pauseGuardian = makeAddr("pauseGuardian");
    address internal supplier = makeAddr("supplier");
    address internal borrower = makeAddr("borrower");
    address internal absorber = makeAddr("absorber");

    function setUp() public virtual {
        usdc = new FaucetToken(0, "USD Coin", 6, "USDC");
        weth = new FaucetToken(0, "Wrapped Ether", 18, "WETH");
        usdcFeed = new SimplePriceFeed(1e8, 8);
        wethFeed = new SimplePriceFeed(3000e8, 8);

        AssetListFactory assetListFactory = new AssetListFactory();
        CometExtAssetList ext = new CometExtAssetList(
            CometConfiguration.ExtConfiguration({name32: _b32("Compound USDC"), symbol32: _b32("cUSDCv3")}),
            address(assetListFactory)
        );

        CometConfiguration.AssetConfig[] memory assetConfigs = new CometConfiguration.AssetConfig[](1);
        assetConfigs[0] = CometConfiguration.AssetConfig({
            asset: address(weth),
            priceFeed: address(wethFeed),
            decimals: 18,
            borrowCollateralFactor: 8.5e17,
            liquidateCollateralFactor: 9e17,
            liquidationFactor: 95e16,
            supplyCap: type(uint128).max
        });

        CometConfiguration.Configuration memory config = CometConfiguration.Configuration({
            governor: governor,
            pauseGuardian: pauseGuardian,
            baseToken: address(usdc),
            baseTokenPriceFeed: address(usdcFeed),
            extensionDelegate: address(ext),
            supplyKink: 8e17,
            supplyPerYearInterestRateSlopeLow: 3e16,
            supplyPerYearInterestRateSlopeHigh: 4e17,
            supplyPerYearInterestRateBase: 0,
            borrowKink: 8e17,
            borrowPerYearInterestRateSlopeLow: 3e16,
            borrowPerYearInterestRateSlopeHigh: 2e17,
            borrowPerYearInterestRateBase: 1e16,
            storeFrontPriceFactor: 5e17,
            trackingIndexScale: 1e15,
            baseTrackingSupplySpeed: 0,
            baseTrackingBorrowSpeed: 0,
            baseMinForRewards: 1_000_000e6,
            baseBorrowMin: 1e6,
            targetReserves: 5_000_000e6,
            assetConfigs: assetConfigs
        });

        comet = new CometHarnessExtendedAssetList(config);
        comet.initializeStorage();

        usdc.allocateTo(supplier, 10_000_000e6);
        usdc.allocateTo(borrower, 1_000_000e6);
        weth.allocateTo(borrower, 1000e18);
    }

    function _b32(string memory s) internal pure returns (bytes32) {
        return bytes32(bytes(s));
    }

    function _approve(address user) internal {
        vm.startPrank(user);
        usdc.approve(address(comet), type(uint256).max);
        weth.approve(address(comet), type(uint256).max);
        vm.stopPrank();
    }

    function _seedMarket() internal {
        _approve(supplier);
        vm.prank(supplier);
        comet.supply(address(usdc), 1_000_000e6);
    }

    function _openBorrowPosition(uint256 collateral, uint256 borrow) internal {
        _seedMarket();
        _approve(borrower);
        vm.startPrank(borrower);
        comet.supply(address(weth), collateral);
        comet.withdraw(address(usdc), borrow);
        vm.stopPrank();
    }
}
