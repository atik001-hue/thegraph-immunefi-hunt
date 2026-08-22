# Compound Hunt Log

## 2026-08-22 — Phase 1 (auto-pivot from Morpho)

**Prior:** Morpho Blue phases 2–20 + MetaMorpho phases 21–23 — no submit-ready finding.

### MetaMorpho phases 21–23 (closed)

| Phase | Hypothesis | Result |
|-------|------------|--------|
| 21 | Donation on behalf steals deposits | **CLOSED** — benefits existing shareholders |
| 22 | lostAssets dust amplification | **CLOSED** — stays dust-scale |
| 23 | Skim theft by caller | **CLOSED** — tokens go to `skimRecipient` only |

### Compound Phase 1

- Cloned `compound-finance/comet` → `compound/src/comet`
- Upstream `Comet.t.sol` smoke: **PASS**
- Fork PoC `CompoundForkPoC.t.sol`: USDC Comet `0xc3d688…` on mainnet
- Scope: `notes/scope.md`

### Next hypotheses (Compound Phase 2+)

1. `absorb` / `absorbInternal` rounding and reserve socialization
2. Collateral withdraw health bypass
3. Base transfer with negative principal
4. Liquidation factor edge cases per asset
5. Price feed staleness / scaling errors
