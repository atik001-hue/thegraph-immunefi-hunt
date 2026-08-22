# Phase 7 Status — The Graph Immunefi Hunt

Last updated: 2026-08-22

## Summary

Phase 7 reviewed **ServiceRegistry**, **AllocationExchange** (legacy recap), **L2Curation / L1 Curation**, and the full **issuance package** (allocator + eligibility oracle + agreement manager). **No submit-ready vulnerabilities found.**

## Fork probe results (21 pass total across all phases)

```bash
cd /Volumes/ORICO/BUG-BOUNTRY/thegraph
forge test --match-path "test/poc/*.t.sol" -vv
```

New file: `test/poc/Phase7TargetsFork.t.sol` (4 tests)

## Live deployment observations

| Contract | Observation |
|----------|-------------|
| L2Curation | `minimumCurationDeposit = 1 wei`; tax = 10,000 PPM (1%); `subgraphService` wired correctly |
| L1 Curation | `minimumCurationDeposit = 1 GRT`; `defaultReserveRatio = 500,000 PPM` (50%) |
| ServiceRegistry | Deployed; registration is auth-gated (indexer or operator) |
| AllocationExchange | On Arbitrum; legacy voucher redeemer (reviewed Phases 4–5) |

## Lead-by-lead conclusions

### 1. ServiceRegistry (CLOSED)

| Path | Verdict |
|------|---------|
| `register` / `registerFor` | `_isAuth(indexer)` — caller must be indexer or staking operator |
| `unregister` / `unregisterFor` | Same auth; no token flow |
| Impersonation | Cannot register URL for another indexer without operator rights |

No economic impact — metadata only.

### 2. AllocationExchange + ServiceRegistry interaction (CLOSED)

No direct coupling between contracts. AllocationExchange redeems governor-signed vouchers into legacy Staking; ServiceRegistry is discovery metadata only. No cross-contract drain path.

### 3. L2Curation / L1 Curation (CLOSED)

| Control | Verdict |
|---------|---------|
| `mint` / `burn` | Standard bonding curve math; slippage guards; `_updateRewards` before balance changes |
| `collect` | **SubgraphService only**; requires curated pool |
| `mintTaxFree` | **GNS only** |
| L2 flat curve | 100% reserve ratio — proportional signal; no undercollateralized mint path found |
| L1 curve | 50% reserve ratio — well-studied Bancor-style; hardhat tests exist |

Dust `minimumCurationDeposit` on L2 (1 wei) is governor-configured — grief cost borne by curator, not protocol drain.

### 4. Issuance allocator + eligibility oracle (CLOSED)

**622/622 unit tests pass** across `packages/issuance`:

| Component | Tests | Verdict |
|-----------|-------|---------|
| IssuanceAllocator | distribution, defensive checks, accounting | 100% allocation invariant documented + tested |
| RewardsEligibilityOracle | eligibility, access control | Fail-open on oracle timeout is **documented** governance/liveness tradeoff |
| RecurringAgreementManager | fuzz, escrow edge cases, lifecycle | TRST-M-3 mode degradation is operator-config; not unprivileged exploit |
| DirectAllocation | construction + distribution | Governor-controlled |

Eligibility oracle fail-open (`oracleUpdateTimeout`) and `eligibilityValidationEnabled = false` are **admin configuration**, not attacker paths. RewardsManager checks eligibility at claim time with optional `revertOnIneligible`.

## Immunefi submission checklist (unchanged)

- [ ] In-scope contract on fork
- [ ] Foundry PoC in `test/poc/`
- [ ] Not in audit reports as fixed
- [ ] Impact = fund loss / unauthorized mint

## Hunt status after Phase 7

**Phases 1–7 complete.** All 37 in-scope contract groups reviewed at least once. **Zero submit-ready findings.**

## Options if continuing

1. **Pivot program** — other Immunefi targets with less audit coverage
2. **Echidna invariant campaigns** — SubgraphService + RewardsManager stateful fuzz (multi-day)
3. **Historical block PoCs** — pin pre-upgrade blocks for migration edge cases (archive RPC)
4. **Monitor** — new Graph deployments / post-audit code changes
