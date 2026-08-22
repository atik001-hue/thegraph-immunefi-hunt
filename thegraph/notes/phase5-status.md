# Phase 5 Status — The Graph Immunefi Hunt

Last updated: 2026-08-22

## Summary

Phase 5 reviewed **DisputeManager**, **AllocationExchange**, **GraphTallyCollector**, and **presentPOI × resize × collect** ordering. **No submit-ready vulnerabilities found.**

Alchemy RPC configured in `.env` (mainnet + Arbitrum). All fork probes pass.

## RPC upgrade

| Endpoint | Status |
|----------|--------|
| Mainnet (`eth-mainnet.g.alchemy.com`) | ✅ Working |
| Arbitrum (`arb-mainnet.g.alchemy.com`) | ✅ Working |
| Archive (historical blocks) | ✅ Tested block 15M on free tier |

**Premium not needed** for current hunting. Free Alchemy tier is sufficient for fork tests and archive forks. Upgrade only if you hit rate limits during heavy fuzzing.

## Test results

```bash
cd /Volumes/ORICO/BUG-BOUNTRY/thegraph
forge test --match-path "test/poc/*.t.sol" -vv
# 14 passed, 0 failed, 2 skipped
```

| Package tests | Result |
|---------------|--------|
| DisputeManager unit | 109/109 pass |
| GraphTallyCollector unit | 34/34 pass |
| SubgraphService indexing collect | 16/16 pass |
| SubgraphService allocation resize | pass (incl. stale + post-collect) |

## Lead-by-lead conclusions

### 1. DisputeManager (CLOSED)

**Reviewed:** create/accept/reject/draw/cancel, conflict disputes, `_slashIndexer`, stake snapshot, fisherman reward cap

| Path | Verdict |
|------|---------|
| Permissionless dispute creation | Requires `disputeDeposit` pull; stake snapshot must be non-zero |
| Fisherman reward inflation | Capped by `min(provision.maxVerifierCut, fishermanRewardCut)` × slash |
| Slash above cap | Reverts `DisputeManagerInvalidTokensSlash` (tested with delegation) |
| Reward cut change mid-dispute | Uses provision's `maxVerifierCut` at accept time (test confirms) |
| OZ M-05 / H-02 (delegation slashing disabled) | **Arbitrator-only** misconfiguration; not unprivileged fund theft. Slash math uses SP tokens first |

Live fork: arbitrator set, controller = `0x0a8491…` (matches RewardsManager).

### 2. AllocationExchange (CLOSED)

Legacy L1-style voucher redeemer on Arbitrum (`0x993F…`).

| Control | Analysis |
|---------|----------|
| `redeem` | ECDSA over `(allocationID, amount)`; authority must sign |
| Double-spend | Blocked by `allocationsRedeemed` mapping |
| Unauthorized redeem | Requires `authority[signer] == true` (governor-set EOA only) |
| Fund drain | Only governor `withdraw()`; no external exploit without compromised authority/governor |

### 3. GraphTallyCollector (CLOSED)

| Control | Analysis |
|---------|----------|
| RAV monotonicity | `tokensRAV > tokensAlreadyCollected` enforced |
| Signer attack | `testGraphTally_Collect_PreventSignerAttack` — payer must authorize signer |
| Syphon via fake data service | Blocked: `msg.sender == rav.dataService` + active provision check |
| Partial collect | Bounded by remaining RAV delta |

Live fork: EIP-712 domain `GraphTallyCollector` on chain 42161.

### 4. presentPOI × resize × collect (CLOSED)

| Hypothesis | Verdict |
|------------|---------|
| H-A1: deny → lift → double snapshot | No double mint; deferred path skips snapshot intentionally |
| H-A2: resize vs POI race | `_resizeAllocation` re-reads fresh accRewards; stale resize reclaims pending |
| H-A3: over-alloc auto-downsize double payout | `test_SubgraphService_Collect_Indexing_OverAllocated_NoDoubleCollectionPayout` passes |
| H-R1: close after deferred POI | By design — close reclaims via `CLOSE_ALLOCATION` |

## Immunefi submission checklist (unchanged)

- [ ] In-scope contract on fork
- [ ] Foundry PoC in `test/poc/`
- [ ] Not in audit reports as fixed
- [ ] Impact = fund loss / unauthorized mint

## Suggested Phase 6 targets

1. **HorizonStaking thaw/slash race** (OZ M-01, L-17, L-18) — verify deployed `_maxThawingPeriod`
2. **EpochManager + issuance edge cases** on L1 RewardsManager
3. **DisputeManager indexing fee disputes V1** — deeper fuzz with real agreements
4. **Invariants fuzz** across SubgraphService + RewardsManager on fork
