# Phase 13 — Hunt Status

**Date:** 2026-08-22  
**Result:** No new Immunefi-submit-ready finding

## Phase 12 re-verdict

`closeStaleAllocation` **NOT submitted** — deep validation showed:
- Final collect 2× vs leaving stale sibling, but **same total mint as `stopService`**
- Attack total mint **≤** solo single-allocation baseline
- Effect = removing stale tokens from reward denominator (intended cleanup)

## Phase 13 probes

| Probe | PoC | Result |
|-------|-----|--------|
| deny → defer → undeny → collect | `IndexingRewardsDenyUndenyCollect.t.sol` | **PASS** — same total mint as control (45k GRT) |
| over-alloc auto-downsize + sibling | `IndexingRewardsOverAllocSibling.t.sol` | Extra mint is **A's legitimate collect** (11k); B final mint identical (10k) |
| over-alloc vs stopService breakdown | `IndexingRewardsOverAllocBreakdown.t.sol` | Total 52k vs 41k — all delta from paying A on collect, not B inflation |
| `allocate()` before token increment | `IndexingRewardsAllocateInflationPoC.t.sol` | **Inconclusive** — 12.5% first-collect bump only with extra `roll(50)`; matched blocks → no delta |
| allocate total mint vs solo | `IndexingRewardsAllocateInflationCompare.t.sol` | Bug path +7.5k vs solo but honest 2-alloc path earns more (85k); not clean inflation |

## Still closed / OOS from prior phases

- L-07 feesProvisionTracker slash desync — confirmed, no unprivileged profit
- OZ H-02 / M-05 / L-18 — delegation slash / collusion — arbitrator-only
- H-R1 deferred POI + close — no double mint
- Bridge, billing, GraphPayments, issuance RAM — no drain paths
- TRST-CL-3 over-alloc single-alloc — fixed

## Highest-value next targets

1. ~~**L-07 stateful profit attempt**~~ — **CLOSED** — see `notes/l07-fullstack-result.md`
2. **Indexing-fee dispute accept** with real `RecurringCollector` (only create tests exist) — low priority
3. **Archive fork** at Horizon upgrade block for legacy slash transition — low priority

**Recommendation:** Shift to another Immunefi program; The Graph hunt exhausted for submit-ready bugs.

## Run new tests

```bash
cd src/contracts/packages/testing
forge test --match-contract "IndexingRewardsDenyUndeny|IndexingRewardsOverAlloc|IndexingRewardsAllocate" -vv
```
