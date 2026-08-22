// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { PPMMath } from "@graphprotocol/horizon/contracts/libraries/PPMMath.sol";
import { DisputeManagerTest } from "../../DisputeManager.t.sol";

/// @dev OZ L-18 / H-02 probe: with delegation slashing disabled, arbitrator can accept a dispute
/// slashing beyond indexer provision while the delegation pool stays intact.
contract DisputeManagerIndexingCollusionTest is DisputeManagerTest {
    using PPMMath for uint256;

    uint256 internal constant PROVISION_TOKENS = 1_000 ether;
    uint256 internal constant DELEGATION_TOKENS = 19_000 ether;

    function test_Indexing_Collusion_SlashBeyondProvision_DelegatorsExitWholePool()
        public
        useIndexer
        useAllocation(PROVISION_TOKENS)
        useDelegation(DELEGATION_TOKENS)
    {
        assertFalse(staking.isDelegationSlashingEnabled(), "test requires disabled delegation slashing");

        uint256 stakeSnapshot = disputeManager.getStakeSnapshot(users.indexer);
        assertEq(stakeSnapshot, PROVISION_TOKENS + DELEGATION_TOKENS, "snapshot must include delegation");

        uint256 maxSlash = stakeSnapshot.mulPPM(MAX_SLASHING_PERCENTAGE);
        uint256 slashBeyondProvision = PROVISION_TOKENS + 100 ether;
        assertLe(slashBeyondProvision, maxSlash, "slash must stay within dispute cap");

        uint256 poolBefore = staking.getDelegationPool(users.indexer, address(subgraphService)).tokens;

        resetPrank(users.fisherman);
        bytes32 disputeId = _createIndexingDispute(allocationId, bytes32("POI1"), block.number);

        resetPrank(users.arbitrator);
        disputeManager.acceptDispute(disputeId, slashBeyondProvision);

        assertEq(
            staking.getDelegationPool(users.indexer, address(subgraphService)).tokens,
            poolBefore,
            "delegation pool untouched when slashing disabled"
        );

        uint256 delegatorShares = staking
            .getDelegation(users.indexer, address(subgraphService), users.delegator)
            .shares;

        uint256 delegatorBalanceBefore = token.balanceOf(users.delegator);

        resetPrank(users.delegator);
        _undelegate(users.indexer, address(subgraphService), delegatorShares);

        skip(staking.getMaxThawingPeriod() + 1);
        resetPrank(users.delegator);
        staking.withdrawDelegated(users.indexer, address(subgraphService), 0);

        assertEq(
            token.balanceOf(users.delegator) - delegatorBalanceBefore,
            DELEGATION_TOKENS,
            "delegator withdraws full delegation despite slash beyond provision"
        );
    }
}
