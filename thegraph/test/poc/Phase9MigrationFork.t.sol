// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {GraphScope} from "../../src/audit/GraphScope.sol";

interface IHorizonProbe {
    function isDelegationSlashingEnabled() external view returns (bool);
    function getMaxThawingPeriod() external view returns (uint64);
    function controller() external view returns (address);
}

interface ISubgraphServiceProbe {
    function stakeToFeesRatio() external view returns (uint256);
    function feesProvisionTracker(address indexer) external view returns (uint256);
    function maxPOIStaleness() external view returns (uint256);
}

interface IHorizonStakingProbe {
    function getProvision(address sp, address verifier) external view returns (Provision memory);
    function getTokensAvailable(address sp, address verifier, uint32 delegationRatio) external view returns (uint256);
}

struct Provision {
    uint256 tokens;
    uint256 tokensThawing;
    uint256 sharesThawing;
    uint32 maxVerifierCut;
    uint64 thawingPeriod;
    uint32 maxVerifierCutPending;
    uint64 thawingPeriodPending;
}

/// @title Phase 9 — live-state probes for migration / slash / fee collateral
contract Phase9MigrationForkTest is Test {
    address internal constant SAMPLE_INDEXER = 0x6E2A457424800d6080C7Ec0A5C5b2DAA364B5Eb9;

    function _selectFork(string memory envKey) internal returns (bool) {
        string memory rpc;
        try vm.envString(envKey) returns (string memory envRpc) {
            rpc = envRpc;
        } catch {
            return false;
        }
        if (bytes(rpc).length == 0) return false;
        try vm.createSelectFork(rpc) {
            return true;
        } catch {
            return false;
        }
    }

    function test_fork_arbitrum_horizon_delegationSlashing_live() public {
        if (!_selectFork("ARBITRUM_RPC_URL")) vm.skip(true, "ARBITRUM_RPC_URL missing");

        IHorizonProbe h = IHorizonProbe(GraphScope.HORIZON_STAKING);
        emit log_named_uint("delegationSlashingEnabled", h.isDelegationSlashingEnabled() ? 1 : 0);
        emit log_named_uint("maxThawingPeriod", h.getMaxThawingPeriod());
    }

    function test_fork_arbitrum_subgraphService_feeCollateral_sampleIndexer() public {
        if (!_selectFork("ARBITRUM_RPC_URL")) vm.skip(true, "ARBITRUM_RPC_URL missing");

        ISubgraphServiceProbe ss = ISubgraphServiceProbe(GraphScope.SUBGRAPH_SERVICE);
        IHorizonStakingProbe staking = IHorizonStakingProbe(GraphScope.HORIZON_STAKING);

        uint256 tracker = ss.feesProvisionTracker(SAMPLE_INDEXER);
        Provision memory prov = staking.getProvision(SAMPLE_INDEXER, GraphScope.SUBGRAPH_SERVICE);
        uint256 available = staking.getTokensAvailable(SAMPLE_INDEXER, GraphScope.SUBGRAPH_SERVICE, 0);

        emit log_named_address("sampleIndexer", SAMPLE_INDEXER);
        emit log_named_uint("feesProvisionTracker", tracker);
        emit log_named_uint("provisionTokens", prov.tokens);
        emit log_named_uint("tokensAvailable", available);
        emit log_named_uint("stakeToFeesRatio", ss.stakeToFeesRatio());

        // Informational: tracker > available may indicate L-07 style desync on live indexers
        if (tracker > available && tracker > 0) {
            emit log("WARN: feesProvisionTracker exceeds getTokensAvailable");
        }
    }
}
