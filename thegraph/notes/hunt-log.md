# Hunt Log

Chronological research notes. **No confirmed bugs yet.**

## 2026-08-22 — Phase 2 kickoff

### RewardsManager (L1 + L2)

**Architecture**
- Global issuance tracked via `accRewardsPerSignal`; per-subgraph via `accRewardsForSubgraph` and `accRewardsPerAllocatedToken`.
- `SubgraphService` is sole `rewardsIssuer` for allocations (`takeRewards` / `reclaimRewards` caller check).
- Non-claimable subgraphs (denied, below min signal, no allocations) → immediate reclaim via `_reclaimRewards`.

**Interesting code paths**
1. `_updateSubgraphRewards` — handles pre-upgrade snapshot mismatch (comment lines 537–542). Worth fuzzing edge values.
2. `_deniedRewards` — subgraph denial checked **before** eligibility; can reclaim without eligibility check if deny address set.
3. `setReclaimAddress` — **retroactive** reclaim routing (governor only, not exploitable by external attacker unless gov compromised).
4. `getRewards` returns non-zero for closed allocations? `getAllocationData` sets `isActive = allo.isOpen()` → `_calcAllocationRewards` returns 0 if closed. OZ L-11 may be view-only inconsistency on deprecated paths.

**AllocationHandler close path**
- `_closeAllocation` calls `reclaimRewards(CLOSE_ALLOCATION)` before close.
- Comment: pending reward capture incomplete when `presentPOI` clears pending without consuming rewards.
- **Hypothesis A:** close + deferred POI (SUBGRAPH_DENIED) → reward stuck or double-claimed? Needs fork PoC with real allocation.

**presentPOI deferred path**
- `ALLOCATION_TOO_YOUNG` or `SUBGRAPH_DENIED` → returns 0, calls `onSubgraphAllocationUpdate`, **no snapshot**.
- Intended: preserve rewards until condition clears.

### HorizonStaking

**Thaw mechanism**
- Shares-based thaw pool; reset when pool emptied by slash.
- OZ M-01: instant thaw to escape slashing — verify `thawingPeriod` enforced in `_fulfillThawRequests`.
- OZ L-17: re-thaw resets end timestamp — read `_createThawRequest`.

### Tooling

- Foundry fork: **Arbitrum public RPC works** (verified live reads).
- Live Arbitrum RewardsManager:
  - controller: `0x0a8491544221dd212964fbb96487467291b2C97e`
  - subgraphService: `0xb2Bb92d0DE618878E438b55D5846cfecD9301105`
  - `getAccRewardsPerSignal()` > 0 on live deployment
  - `getAllocatedIssuancePerBlock()` reverts on live call (investigate — may need issuance allocator context)
- Mainnet fork: needs Alchemy/Infura in `.env` (public endpoints fail).
- Slither: needs `pnpm install` in horizon package.

### Next actions (Phase 4) — completed 2026-08-22

- [x] Manual review: Slither PaymentsEscrow reentrancy + balance check → **false positive**
- [x] Audit BillingConnector on mainnet fork → wiring OK, no exploit path
- [x] Bridge escrow L1/L2 differential analysis → allowance healthy, escrow funded
- [x] RecurringCollector getMaxNextClaim envelope tests → 22/22 pass
- [x] Run Graph integration tests (double-mint path cleared)
- [x] Run subgraph-service indexing tests (16/16 pass)
- [x] New fork probes: `BillingConnectorFork.t.sol`, `BridgeEscrowFork.t.sol` (10 pass total)

**Phase 4 result: no submit-ready finding.** See `notes/phase4-status.md`.

### Phase 5 candidates — completed 2026-08-22

- [x] DisputeManager — 109 unit tests + fork wiring; no unprivileged exploit
- [x] AllocationExchange — authority-signed vouchers only; no external drain
- [x] GraphTallyCollector — 34 unit tests + EIP-712 fork check; signer attack blocked
- [x] presentPOI × resize × collect — 16 indexing tests pass; H-A1/A2/A3 closed

**Phase 5 result: no submit-ready finding.** Alchemy RPC configured. See `notes/phase5-status.md`.

### Phase 6 candidates — completed 2026-08-22

- [x] HorizonStaking thaw/slash (OZ M-01, L-17, L-18) — maxThaw=28d live; 22 unit tests pass
- [x] EpochManager + L1 RewardsManager issuance — no external exploit path
- [x] Indexing-fee disputes V1 — 7/7 create tests pass
- [x] Phase6 fork probes — `Phase6TargetsFork.t.sol` (17 total fork tests pass)

**Phase 6 result: no submit-ready finding.** See `notes/phase6-status.md`.

### Phase 7 candidates — completed 2026-08-22

- [x] ServiceRegistry — auth-gated metadata only; no fund flow
- [x] AllocationExchange legacy — recap confirms authority-signed vouchers only
- [x] L2Curation / L1 Curation — bonding curve + collect auth OK; fork wired
- [x] Issuance package — 622/622 unit tests pass (allocator, eligibility, RAM)

**Phase 7 result: no submit-ready finding.** Phases 1–7 complete. See `notes/phase7-status.md`.

### Phase 8 — unaudited in-scope targets (2026-08-22)

- [x] L2GNS rounding refund path — owner-only; no cross-user theft
- [x] StakingExtension legacy slash — delegation pool not updated (OZ H-02); slasher-gated
- [x] AllocationExchange raw-hash vouchers — needs authority EOA sig
- [x] Legacy allocation ID blocking — by design
- [x] **L-07 PoC** — `DataServiceFeesSlash.t.sol` PASS: slash does not reduce `feesProvisionTracker`
- [x] Phase8 fork probes — `Phase8TargetsFork.t.sol` (26 total fork tests pass)

**Phase 8 result: no Immunefi-submit-ready finding.** L-07 confirmed but likely OOS (OZ audit partial). See `notes/phase8-status.md`.

**Next:** Phase 10 — L1GraphTokenGateway mint allowance, BillingConnector, dispute collusion (L-18). See `notes/phase9-status.md`.

### Phase 9–11 (2026-08-22)

- [x] H-R1 deferred POI + close — `IndexingRewardsDeferredClose.t.sol` PASS (real RewardsManager)
- [x] OZ H-02 delegation slash skip — live + unit PoC PASS (likely OOS)
- [x] Phase 10 gateway mint allowance — healthy headroom on mainnet fork
- [x] BillingConnector L1↔L2 wiring — PASS (prior Phase 4)
- [x] **L-18 collusion PoC** — `collusion.t.sol` PASS: slash beyond provision, delegation pool untouched, delegator exits full (requires compromised arbitrator; OZ partial)
- [x] **L-11 stale POI + close** — `IndexingRewardsStaleClose.t.sol` PASS: no double mint
- [x] Phase 11 forks — GraphPayments, L2GraphToken, Controller, SubgraphNFT wiring OK

**Phases 9–11 result: no Immunefi-submit-ready finding.** Fork total: **32 pass, 2 skip**. See `notes/phase11-status.md`.

**Next:** Phase 12 — archive fork at Horizon upgrade, eligibility oracle paths, L-07 live exploit attempt, indexing-fee dispute integration.

### Phase 12 — SUBMIT-READY (2026-08-22)

**`closeStaleAllocation` / `_resizeAllocation` indexing reward inflation (~2×)**

- PoC: `testing/test/integration/IndexingRewardsCloseStaleOverMintPoC.t.sol` — **PASS** (real RewardsManager)
- Honest survivor mint: 5000 GRT; after permissionless closeStale on sibling: **10000 GRT**
- Root cause: `onSubgraphAllocationUpdate` before `_subgraphAllocatedTokens` decrement in `AllocationHandler._resizeAllocation`
- See `notes/phase12-finding.md` for Immunefi submission draft

**Phase 12 re-verdict (same day): NOT submit-ready** — `stopService` yields identical total mint; attack ≤ solo baseline. See `notes/phase13-status.md`.

### Phase 13 (2026-08-22)

- deny/undeny collect, over-alloc sibling, allocate ordering — **no submit-ready finding**
- See `notes/phase13-status.md`
