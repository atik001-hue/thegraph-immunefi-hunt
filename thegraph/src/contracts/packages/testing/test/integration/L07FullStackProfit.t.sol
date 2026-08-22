// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import { IHorizonStakingTypes } from "@graphprotocol/interfaces/contracts/horizon/internal/IHorizonStakingTypes.sol";
import { IndexingAgreement } from "subgraph-service/libraries/IndexingAgreement.sol";
import { IRecurringCollector } from "@graphprotocol/interfaces/contracts/horizon/IRecurringCollector.sol";

import { FullStackHarness } from "../harness/FullStackHarness.t.sol";

/// @title L-07 full-stack profit attempt — feesProvisionTracker unchanged after slash
contract L07FullStackProfitTest is FullStackHarness {
    bytes32 internal constant SUBGRAPH = keccak256("l07-profit-subgraph");
    address internal fisherman = makeAddr("fisherman");

    function test_L07_NoExtraProfitAfterSlashAndSecondCollect() public {
        IndexerSetup memory ix = _setupIndexer("l07-indexer", SUBGRAPH, MINIMUM_PROVISION_TOKENS * 10);

        IndexingAgreement.IndexingAgreementTermsV1 memory terms =
            IndexingAgreement.IndexingAgreementTermsV1({ tokensPerSecond: 1 ether, tokensPerEntityPerSecond: 0 });

        bytes16 agreementId = _offerAndAccept(ix, _buildRCA(ix, 0, 10 ether, 3600, terms));

        skip(600);
        vm.roll(block.number + EPOCH_LENGTH);

        _addProvisionTokens(ix, 600 ether * STAKE_TO_FEES_RATIO * 2);

        uint256 bal0 = token.balanceOf(ix.addr);
        uint256 prov0 = staking.getProvision(ix.addr, address(subgraphService)).tokens;

        uint256 fees1 = _collectIndexingFees(ix, agreementId, 100, keccak256("poi-1"), block.number - 1);
        uint256 locked1 = subgraphService.feesProvisionTracker(ix.addr);

        _slashViaDispute(agreementId, 1000 ether);

        assertEq(subgraphService.feesProvisionTracker(ix.addr), locked1, "L-07 tracker unchanged");
        assertLt(staking.getProvision(ix.addr, address(subgraphService)).tokens, prov0, "provision slashed");

        skip(300);
        vm.roll(block.number + 10);
        _addProvisionTokens(ix, 600 ether * STAKE_TO_FEES_RATIO);

        uint256 fees2 = _tryCollect(ix, agreementId);

        skip(DISPUTE_PERIOD + 1);
        vm.prank(ix.addr);
        subgraphService.releaseStake(0);
        assertEq(subgraphService.feesProvisionTracker(ix.addr), 0);

        skip(600);
        vm.roll(block.number + 10);
        _addProvisionTokens(ix, 600 ether * STAKE_TO_FEES_RATIO * 2);
        uint256 fees3 = _collectIndexingFees(ix, agreementId, 100, keccak256("poi-3"), block.number - 1);

        uint256 feeTotal = fees1 + fees2 + fees3;
        uint256 indexerNet = token.balanceOf(ix.addr) - bal0;

        emit log_named_uint("feeTotal", feeTotal);
        emit log_named_uint("indexerNet", indexerNet);

        assertLe(indexerNet, feeTotal + 1 ether, "no unexplained mint to indexer");
    }

    function _slashViaDispute(bytes16 agreementId, uint256 slashAmount) internal {
        _mintTokens(fisherman, DISPUTE_DEPOSIT);
        vm.startPrank(fisherman);
        token.approve(address(disputeManager), DISPUTE_DEPOSIT);
        bytes32 disputeId = disputeManager.createIndexingFeeDisputeV1(
            agreementId,
            keccak256("dispute-poi"),
            50,
            block.number
        );
        vm.stopPrank();
        vm.prank(arbitrator);
        disputeManager.acceptDispute(disputeId, slashAmount);
    }

    function _tryCollect(IndexerSetup memory ix, bytes16 agreementId) internal returns (uint256 fees) {
        try this._externalCollect(ix, agreementId) returns (uint256 c) {
            return c;
        } catch {
            return 0;
        }
    }

    function _externalCollect(IndexerSetup memory ix, bytes16 agreementId) external returns (uint256) {
        return _collectIndexingFees(ix, agreementId, 100, keccak256("poi-2"), block.number - 1);
    }
}
