# Phase 3 Status — The Graph Immunefi Hunt

Last updated: 2026-08-22

## Done automatically (no action needed from you)

| Item | Status |
|------|--------|
| `.env` with working public RPCs | ✅ `ethereum.publicnode.com` + Arbitrum |
| Fork tests (mainnet + Arbitrum) | ✅ 5 pass, 1 placeholder skip |
| Scope + audit notes | ✅ `notes/scope.md`, `audit-findings.md`, `attack-surface.md`, `hunt-log.md` |
| Slither + pypdf installed | ✅ |
| Live Arbitrum state verified | ✅ RewardsManager wired to SubgraphService |

## Run commands

```bash
cd /Volumes/ORICO/BUG-BOUNTRY/thegraph
forge test --match-path test/poc/ -vv          # fork sanity
./scripts/analyze.sh                            # analysis wrapper
```

## Research conclusions (Phase 3)

### Known fixed — do NOT report

| Finding | Source | Why out of scope |
|---------|--------|------------------|
| TRST-CL-3 double mint on over-allocation resize | Trust audit Jun 2026 | Fixed: `_resizeAllocation` re-reads fresh storage |
| OZ M-01 instant thaw via uint64 overflow | Horizon audit 2025 | Fixed PR #1160: `_maxThawingPeriod` cap |
| OZ H/M findings in issuance PR #1342 | Trust audit | All High fixed; 1 Medium acknowledged (M-3 operator config) |
| Stale POI on same-tx collect | By design | Tests expect reclaim when stale before collect |

### Active hunt areas (Phase 4)

1. **Variants of TRST-CL-3** — other stale memory uses in `presentPOI` (e.g. `_distributeIndexingRewards` after deferred path)
2. **Horizon L-03 / L-07** — partial slash share inflation; slashing vs query fee collection
3. **Issuance RAM edge cases** — TRST-M-3 acknowledged mode degradation; operator error vs exploitable?
4. **BillingConnector** — not yet reviewed (`0x8017...ea72`)
5. **Bridge escrow** — L1↔L2 accounting

### Blocked without your help (optional upgrades)

| Need | Why | How |
|------|-----|-----|
| Alchemy/Infura API key | Faster, archive forks for historical blocks | Replace URLs in `.env` |
| Node.js ≥ 22 | Run Graph monorepo `pnpm test` locally | `nvm install 24` then build contracts package |

## Immunefi submission checklist (when we find something)

- [ ] In-scope contract on fork
- [ ] Foundry PoC in `test/poc/`
- [ ] Not in audit reports as fixed
- [ ] Impact = fund loss / unauthorized mint
- [ ] Report via Immunefi dashboard with inline PoC
