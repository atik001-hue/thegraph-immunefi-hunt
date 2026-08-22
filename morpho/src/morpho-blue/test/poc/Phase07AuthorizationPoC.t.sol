// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../BaseTest.sol";
import {SigUtils} from "../helpers/SigUtils.sol";

/// @dev Phase 7 — EIP-712 authorization replay / nonce / deadline
contract Phase07AuthorizationPoC is BaseTest {
    uint256 internal authorizerKey = 0xA11CE;

    function _sign(Authorization memory auth) internal view returns (Signature memory sig) {
        bytes32 digest = SigUtils.getTypedDataHash(morpho.DOMAIN_SEPARATOR(), auth);
        (sig.v, sig.r, sig.s) = vm.sign(authorizerKey, digest);
    }

    function test_replaySameSig_revertsInvalidNonce() public {
        address authorizer = vm.addr(authorizerKey);
        Authorization memory auth = Authorization({
            authorizer: authorizer,
            authorized: LIQUIDATOR,
            isAuthorized: true,
            nonce: 0,
            deadline: type(uint256).max
        });
        Signature memory sig = _sign(auth);

        morpho.setAuthorizationWithSig(auth, sig);
        vm.expectRevert(bytes(ErrorsLib.INVALID_NONCE));
        morpho.setAuthorizationWithSig(auth, sig);
    }

    function test_expiredDeadline_reverts() public {
        address authorizer = vm.addr(authorizerKey);
        Authorization memory auth = Authorization({
            authorizer: authorizer,
            authorized: LIQUIDATOR,
            isAuthorized: true,
            nonce: 0,
            deadline: block.timestamp
        });
        Signature memory sig = _sign(auth);

        vm.warp(block.timestamp + 1);
        vm.expectRevert(bytes(ErrorsLib.SIGNATURE_EXPIRED));
        morpho.setAuthorizationWithSig(auth, sig);
    }

    function test_wrongAuthorizerSig_reverts() public {
        Authorization memory auth = Authorization({
            authorizer: BORROWER,
            authorized: LIQUIDATOR,
            isAuthorized: true,
            nonce: 0,
            deadline: type(uint256).max
        });
        Signature memory sig = _sign(auth);

        vm.expectRevert(bytes(ErrorsLib.INVALID_SIGNATURE));
        morpho.setAuthorizationWithSig(auth, sig);
    }
}
