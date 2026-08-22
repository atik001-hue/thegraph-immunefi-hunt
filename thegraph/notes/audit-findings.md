# OpenZeppelin Horizon Audit — Hunt Tracker

Source: `src/contracts/packages/horizon/audits/2025-05-OZ-The Graph Horizon Audit.pdf`  
Status baseline: **26 resolved, 2 partially resolved** (per audit summary)

Use this to avoid duplicate reports and prioritize **partial fixes** + **post-audit code**.

## High — verify fix on deployed bytecode

| ID | Title | Hunt status | Notes |
|----|-------|-------------|-------|
| H-01 | Legacy Slash Breaks Accounting | TODO | Check legacy allocation migration + slash paths in `HorizonStaking` |
| H-02 | Delegations Unlikely Slashed When Delegation Slashing Disabled | TODO | `DisputeManager` + delegation pool during slash |

## Medium — priority targets

| ID | Title | Hunt status | Notes |
|----|-------|-------------|-------|
| M-01 | Service Providers Can Thaw Instantly to Escape Slashing | **ACTIVE** | `_thaw` / `_deprovision` timing vs dispute window |
| M-02 | Potential DoS During Slashing | TODO | Gas limits in `_fulfillThawRequests`, batch slash |
| M-03 | Provision Validity Can Be Temporarily Griefed | TODO | Parameter staging in provisions |
| M-04 | SP Left Without Payments if SubgraphService Paused | TODO | Pause + collect paths |
| M-05 | DisputeManager Excessively Slashes When Delegation Slashing Disabled | TODO | Slash amount math |

## Low — upgrade candidates (may be Medium under Primacy of Impact)

| ID | Title | Hunt status | Why interesting |
|----|-------|-------------|-----------------|
| L-03 | Incomplete Slashings → Share Inflation | **ACTIVE** | Direct fund/accounting impact |
| L-07 | Provision Slashing Does Not Update Tokens Locked on Query Fee Collect | **POC CONFIRMED** | `horizon/test/unit/data-service/extensions/DataServiceFeesSlash.t.sol` — slash leaves `feesProvisionTracker` unchanged; likely OOS (OZ partial) |
| L-11 | takeRewards/getRewards Wrong for Closed Allocations | REVIEW | `_closeAllocation` reclaims via `CLOSE_ALLOCATION`; check pending edge cases |
| **NEW** | **closeStaleAllocation reward inflation** | **NOT SUBMIT** | Re-verified: same total mint as `stopService`; see `phase13-status.md` |
| L-12 | Step-Wise Delegation Share Fee Frontrunning | TODO | Economic attack |
| L-17 | Thawing End Timestamp Reset on Re-thaw | **ACTIVE** | Extends thaw lock / slash evasion |
| L-18 | Verifier + SP Collusion Instant Withdrawal via Slashing | **ACTIVE** | Collusion path |

## Missed Issues report (June 2025)

Source: `The Graph Horizon Missed Issues Initial Report.pdf`  
Team-reported issues #1–#3 fixed in PR #1183. Re-check **similar patterns** in newer PRs (issuance allocator, eligibility oracle).

## Issuance package (2026 audits)

Recent Trust Security reviews in `packages/issuance/audits/`:

- `2026-06-05_Graph_PR1342_v06.pdf` — 4 High, 4 Medium (3 fixed, 1 partial)
- Eligibility oracle + issuance allocator are **new surface** — high priority after RewardsManager week

## Out of scope (do not report)

- Vesting double-spend (fixed Mar 2026, GHSA-qx35-rc5x-x39r)
- Any issue explicitly marked fixed in audit with verified patch on deployed impl

## Current sprint focus

1. **RewardsManager** accounting: `onSubgraphAllocationUpdate`, reclaim routing, closed allocations
2. **HorizonStaking** thaw/slash race (M-01, L-17, L-18)
3. **AllocationHandler** `presentPOI` deferred vs close interaction (known limitation comment in `_closeAllocation`)
