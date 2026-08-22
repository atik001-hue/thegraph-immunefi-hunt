// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IHorizonStakingMain } from "@graphprotocol/interfaces/contracts/horizon/internal/IHorizonStakingMain.sol";
import { HorizonStakingTest } from "../HorizonStaking.t.sol";

/// @dev OZ H-02 / M-05 probe: with delegation slashing disabled, slash beyond provision skips
/// delegation burn — delegators retain full pool backing (collusion / insolvency risk).
contract HorizonStakingDelegationSlashingSkippedTest is HorizonStakingTest {
    function test_DelegationSlashingDisabled_PoolUntouchedWhenSlashExceedsProvision() public useIndexer {
        vm.assume(!staking.isDelegationSlashingEnabled());

        uint256 provisionTokens = 1000 ether;
        uint256 delegationTokens = 9000 ether;

        _useProvision(subgraphDataServiceAddress, provisionTokens, MAX_PPM, 0);

        resetPrank(users.delegator);
        _delegate(users.indexer, subgraphDataServiceAddress, delegationTokens, 0);

        uint256 poolBefore = _getStorageDelegationPoolInternal(users.indexer, subgraphDataServiceAddress, false).tokens;
        uint256 slashAmount = provisionTokens + delegationTokens / 2;

        vm.expectEmit(address(staking));
        emit IHorizonStakingMain.DelegationSlashingSkipped(
            users.indexer,
            subgraphDataServiceAddress,
            slashAmount - provisionTokens
        );

        resetPrank(subgraphDataServiceAddress);
        staking.slash(users.indexer, slashAmount, 0, users.verifier);

        uint256 poolAfter = _getStorageDelegationPoolInternal(users.indexer, subgraphDataServiceAddress, false).tokens;
        assertEq(poolAfter, poolBefore, "delegation pool unchanged when slashing disabled");
    }
}
