# Phase 6 Status — The Graph Immunefi Hunt

Last updated: 2026-08-22

## Summary

Phase 6 reviewed **HorizonStaking thaw/slash races**, **EpochManager**, **L1 RewardsManager issuance**, and **indexing-fee disputes**. **No submit-ready vulnerabilities found.**

## Fork probe results (17 pass, 2 skip)

```bash
cd /Volumes/ORICO/BUG-BOUNTRY/thegraph
forge test --match-path "test/poc/*.t.sol" -vv
```

New file: `test/poc/Phase6TargetsFork.t.sol`

## Live deployment observations (Alchemy fork)

| Contract | Observation |
|----------|-------------|
| HorizonStaking | `maxThawingPeriod = 2,419,200s` (28 days); delegation slashing **disabled** |
| EpochManager | Active; epoch length > 0 |
| L1 RewardsManager | `accRewardsPerSignal > 0`; controller set |

## Lead-by-lead conclusions

### 1. HorizonStaking thaw/slash (OZ M-01, L-17, L-18) — CLOSED

| Finding | Verdict |
|---------|---------|
| **M-01** instant thaw escape | **Fixed** — `_maxThawingPeriod` enforced at provision + accept; live cap = 28 days |
| **L-17** re-thaw resets timer | Each thaw creates separate request; fulfillment stops at first non-expired; no slash evasion path for external attacker |
| **L-18** verifier + SP collusion | Requires arbitrator accepting dispute + slash; not unprivileged exploit |
| Thaw during slash | Slashing proportionally reduces `tokensThawing`; pool reset invalidates pending thaws (12 thaw + 10 slash tests pass) |
| Slash with delegation disabled | `DelegationSlashingSkipped` emitted; SP tokens slashed only — matches live config (delegation slashing off) |

**OZ M-05 / H-02** (excessive slash when delegation slashing disabled): arbitrator-controlled outcome; fisherman cannot extract beyond `min(maxVerifierCut, fishermanRewardCut)` × slash. Not an external attacker profit path.

### 2. EpochManager + L1 RewardsManager (CLOSED)

| Area | Verdict |
|------|---------|
| EpochManager `runEpoch` | Permissionless but only advances `lastRunEpoch`; no fund movement |
| Epoch length change | Governor-only; no external exploit |
| `_updateSubgraphRewards` migration edge (H-R2) | Code explicitly handles pre-upgrade snapshot mismatch; documented non-negative invariant |
| L1 `getAllocatedIssuancePerBlock` | May revert without allocator wiring on some selectors; L2 is primary issuance surface post-Horizon |

### 3. Indexing-fee disputes V1 (CLOSED)

7/7 unit tests pass on `createIndexingFeeDisputeV1`:

- Requires agreement collected + V1 version
- Stake snapshot must be non-zero
- Duplicate dispute IDs blocked
- Accept/reject paths use same `_slashIndexer` caps as query disputes

No accept-specific fuzz gap found beyond existing DisputeManager test suite (109 tests total).

### 4. Invariant fuzz (deferred)

Full cross-contract fuzz (SubgraphService × RewardsManager × HorizonStaking) not run in CI this phase — unit + integration coverage already exercises ordering. No new variant identified from manual trace.

## Test coverage added this phase

| Suite | Result |
|-------|--------|
| HorizonStaking slash | 10/10 |
| HorizonStaking thaw | 12/12 |
| Indexing-fee dispute create | 7/7 |
| Phase6 fork probes | 3/3 |

## Immunefi submission checklist (unchanged)

- [ ] In-scope contract on fork
- [ ] Foundry PoC in `test/poc/`
- [ ] Not in audit reports as fixed
- [ ] Impact = fund loss / unauthorized mint

## Suggested Phase 7 targets

1. **ServiceRegistry + AllocationExchange** legacy interaction on Arbitrum
2. **L2Curation / Curation** bonding curve edge cases
3. **Issuance allocator + eligibility oracle** (2026 Trust audit partial fixes)
4. **Echidna/Foundry invariant fuzz** on RewardsManager + AllocationHandler (automated)
