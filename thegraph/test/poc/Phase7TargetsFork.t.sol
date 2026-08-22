// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {GraphScope} from "../../src/audit/GraphScope.sol";

interface IL2CurationProbe {
    function minimumCurationDeposit() external view returns (uint256);
    function curationTaxPercentage() external view returns (uint32);
    function subgraphService() external view returns (address);
}

interface IServiceRegistryProbe {
    function isRegistered(address indexer) external view returns (bool);
}

interface ICurationL1Probe {
    function minimumCurationDeposit() external view returns (uint256);
    function defaultReserveRatio() external view returns (uint32);
}

/// @title Phase 7 — ServiceRegistry, Curation, legacy AllocationExchange fork checks
contract Phase7TargetsForkTest is Test {
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

    function test_fork_arbitrum_l2Curation_wiring() public {
        if (!_selectFork("ARBITRUM_RPC_URL")) vm.skip(true, "ARBITRUM_RPC_URL missing or fork failed");

        IL2CurationProbe curation = IL2CurationProbe(GraphScope.L2_CURATION);

        uint256 minDeposit = curation.minimumCurationDeposit();
        uint32 tax = curation.curationTaxPercentage();
        address subgraphService = curation.subgraphService();

        emit log_named_uint("minimumCurationDeposit", minDeposit);
        emit log_named_uint("curationTaxPercentagePPM", tax);
        emit log_named_address("subgraphService", subgraphService);

        assertGt(GraphScope.L2_CURATION.code.length, 0);
        assertGt(minDeposit, 0);
        assertLe(tax, 1_000_000);
        assertEq(subgraphService, GraphScope.SUBGRAPH_SERVICE);
    }

    function test_fork_arbitrum_serviceRegistry_hasCode() public {
        if (!_selectFork("ARBITRUM_RPC_URL")) vm.skip(true, "ARBITRUM_RPC_URL missing or fork failed");
        assertGt(GraphScope.SERVICE_REGISTRY.code.length, 0);

        IServiceRegistryProbe registry = IServiceRegistryProbe(GraphScope.SERVICE_REGISTRY);
        bool registered = registry.isRegistered(address(0x1));
        emit log_named_uint("randomIsRegistered", registered ? 1 : 0);
    }

    function test_fork_mainnet_curationL1_params() public {
        if (!_selectFork("MAINNET_RPC_URL")) vm.skip(true, "MAINNET_RPC_URL missing or fork failed");

        ICurationL1Probe curation = ICurationL1Probe(GraphScope.CURATION_L1);

        uint256 minDeposit = curation.minimumCurationDeposit();
        uint32 reserveRatio = curation.defaultReserveRatio();

        emit log_named_uint("minimumCurationDeposit", minDeposit);
        emit log_named_uint("defaultReserveRatioPPM", reserveRatio);

        assertGt(GraphScope.CURATION_L1.code.length, 0);
        assertGt(minDeposit, 0);
        assertGt(reserveRatio, 0);
        assertLe(reserveRatio, 1_000_000);
    }

    function test_fork_arbitrum_allocationExchange_hasCode() public {
        if (!_selectFork("ARBITRUM_RPC_URL")) vm.skip(true, "ARBITRUM_RPC_URL missing or fork failed");
        assertGt(GraphScope.ALLOCATION_EXCHANGE.code.length, 0);
    }
}
