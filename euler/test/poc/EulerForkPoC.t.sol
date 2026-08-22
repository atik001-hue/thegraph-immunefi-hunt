// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {EulerScope} from "../../src/audit/EulerScope.sol";

interface IEVCProbe {
    function getRawExecutionContext() external view returns (uint256);
    function areChecksDeferred() external view returns (bool);
}

interface IERC20Code {
    function totalSupply() external view returns (uint256);
}

/// @dev Phase 1 — Euler mainnet fork sanity (EVC + known vault)
contract EulerForkPoC is Test {
    function _fork() internal returns (bool) {
        try vm.envString("MAINNET_RPC_URL") returns (string memory rpc) {
            if (bytes(rpc).length == 0) return false;
            try vm.createSelectFork(rpc) {
                return true;
            } catch {
                return false;
            }
        } catch {
            return false;
        }
    }

    function test_fork_mainnet_evc_deployed() public {
        if (!_fork()) vm.skip(true, "MAINNET_RPC_URL missing");
        assertGt(EulerScope.EVC_MAINNET.code.length, 0);
        // Smoke: view call does not revert
        IEVCProbe(EulerScope.EVC_MAINNET).areChecksDeferred();
    }

    function test_fork_mainnet_sampleKnownVault_hasCode() public {
        if (!_fork()) vm.skip(true, "MAINNET_RPC_URL missing");
        assertGt(EulerScope.SAMPLE_KNOWN_VAULT.code.length, 0);
    }
}
