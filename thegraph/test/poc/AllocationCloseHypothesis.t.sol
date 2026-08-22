// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {GraphScope} from "../../src/audit/GraphScope.sol";

/// @title Hypothesis H-R1: allocation close vs deferred POI rewards
/// @dev Attack idea (unproven):
///   1. Indexer creates allocation, rewards accrue
///   2. presentPOI hits SUBGRAPH_DENIED (or ALLOCATION_TOO_YOUNG) → deferred, no snapshot
///   3. Indexer closes allocation → reclaimRewards(CLOSE_ALLOCATION)
///   4. Check if pending rewards are lost, double-minted, or stuck
///
/// Needs full SubgraphService integration on fork — implement when tracing confirms gap.
contract AllocationCloseHypothesisTest is Test {
    address internal constant SUBGRAPH_SERVICE_ARB = 0xb2Bb92d0DE618878E438b55D5846cfecD9301105;

    function setUp() public {}

    function test_HR1_closeAfterDeferredPOI_placeholder() public {
        vm.skip(true, "Closed: IndexingRewardsDeferredClose.t.sol PASS with real RewardsManager");
    }
}
