// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { HorizonStakingSharedTest } from "../../shared/horizon-staking/HorizonStakingShared.t.sol";
import { DataServiceImpFees } from "../implementations/DataServiceImpFees.sol";
import { IHorizonStakingTypes } from "@graphprotocol/interfaces/contracts/horizon/internal/IHorizonStakingTypes.sol";

/// @dev PoC for OZ L-07: slashing does not reduce feesProvisionTracker / stake claims.
/// Demonstrates accounting desync between provision slash and fee-collateral tracker.
contract DataServiceFeesSlashTest is HorizonStakingSharedTest {
    uint256 public constant PROVISION_TOKENS = 10_000 ether;
    DataServiceImpFees dataService;

    function setUp() public override {
        super.setUp();
        dataService = new DataServiceImpFees(address(controller));
    }

    function test_L07_SlashLeavesFeesProvisionTrackerUnchanged()
        external
        useIndexer
        useProvisionDataService(address(dataService), PROVISION_TOKENS, MAX_PPM, 0)
    {
        uint256 feeAmount = 10 ether;
        dataService.lockStake(users.indexer, feeAmount);

        uint256 trackerAfterLock = dataService.feesProvisionTracker(users.indexer);
        uint256 expectedLock = feeAmount * dataService.STAKE_TO_FEES_RATIO();
        assertEq(trackerAfterLock, expectedLock, "lock stake for fee backing");

        IHorizonStakingTypes.Provision memory provBefore = staking.getProvision(users.indexer, address(dataService));
        uint256 slashAmount = provBefore.tokens / 2;

        resetPrank(address(dataService));
        staking.slash(users.indexer, slashAmount, 0, address(dataService));

        uint256 trackerAfterSlash = dataService.feesProvisionTracker(users.indexer);
        IHorizonStakingTypes.Provision memory provAfter = staking.getProvision(users.indexer, address(dataService));

        assertEq(trackerAfterSlash, trackerAfterLock, "L-07: feesProvisionTracker unchanged after slash");
        assertLt(provAfter.tokens, provBefore.tokens, "provision reduced by slash");

        // After dispute window, claim release clears tracker without restoring slashed tokens.
        vm.warp(block.timestamp + dataService.LOCK_DURATION() + 1);
        resetPrank(users.indexer);
        dataService.releaseStake(0);

        assertEq(dataService.feesProvisionTracker(users.indexer), 0, "tracker released after expiry");
        assertLt(
            staking.getTokensAvailable(users.indexer, address(dataService), 0),
            provBefore.tokens,
            "available capacity reflects slash, not original backing"
        );

        // Indexer can lock again up to post-slash capacity — prior fee backing was burned on slash.
        uint256 postSlashAvailable = staking.getTokensAvailable(users.indexer, address(dataService), 0);
        uint256 newFeeAmount = postSlashAvailable / dataService.STAKE_TO_FEES_RATIO();
        if (newFeeAmount > 0) {
            dataService.lockStake(users.indexer, newFeeAmount);
            assertGt(dataService.feesProvisionTracker(users.indexer), 0, "can re-lock after slash + claim release");
        }
    }
}
