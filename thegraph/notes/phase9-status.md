# Phase 9 — Real RM, Migration Forks, Slash Probes

**Status:** Complete — no Immunefi-submit-ready finding  
**Date:** 2026-08-22

## Work Completed

| Track | Artifact | Result |
|-------|----------|--------|
| Real RewardsManager integration | `testing/test/integration/IndexingRewardsCollection.t.sol` | PASS — no double collection on over-alloc resize |
| H-R1 deferred POI + close | `testing/test/integration/IndexingRewardsDeferredClose.t.sol` | **PASS** — deny → defer → close → no double mint |
| OZ H-02 delegation slash skip | `horizon/.../delegationSlashingSkipped.t.sol` | **PASS** — pool untouched when slash > provision (live: slashing disabled) |
| Phase 9 fork probes | `test/poc/Phase9MigrationFork.t.sol` | PASS — live `delegationSlashingEnabled=0`, maxThaw=28d |
| RAM / issuance deep pass | Subagent + 622 issuance tests | No unprivileged drain |
| Full testing stack | 24 integration tests | All pass |

## Key Results

### H-R1 (Allocation close vs deferred POI) — CLOSED

Using **production RewardsManager bytecode**, the sequence deny → collect (0 payout) → `stopService` → re-collect does **not** double-mint or leak rewards. Safe by design.

### Delegation slashing disabled (OZ H-02 / M-05) — CONFIRMED, likely OOS

Live Arbitrum: `isDelegationSlashingEnabled() = false`. When slash exceeds indexer provision, `DelegationSlashingSkipped` fires and delegation pool is unchanged. PoC passes; this is a **known partial OZ audit item**, not a fresh finding.

### L-07 (Phase 8 carryover)

Still confirmed; OZ partial; not submittable under standard Immunefi rules.

## Fork Test Totals

```bash
forge test --match-path "test/poc/*.t.sol" -vv
# 28 pass, 2 skip (includes Phase 8 + Phase 9)
```

## Phase 10 Candidates

1. **L1GraphTokenGateway** — `l2MintAllowancePerBlock` / `totalMintedFromL2` accounting edge cases
2. **BillingConnector** — `addToL2` / permit fallback / L2 message replay
3. **Archive fork** at Horizon upgrade block (legacySlash transition) — need deployment block from Arbiscan
4. **DisputeManager collusion** — fisherman + indexer minimal slash + delegator exit (L-18)
5. **Stateful fuzz** — SubgraphService collect ordering with real RM harness
