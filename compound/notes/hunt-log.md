# Compound Hunt Log

## 2026-08-22 — Phase 1 (auto-pivot from Morpho)

**Prior:** Morpho Blue phases 2–20 + MetaMorpho phases 21–23 — no submit-ready finding.

### MetaMorpho phases 21–23 (closed)

| Phase | Hypothesis | Result |
|-------|------------|--------|
| 21 | Donation on behalf steals deposits | **CLOSED** — benefits existing shareholders |
| 22 | lostAssets dust amplification | **CLOSED** — stays dust-scale |
| 23 | Skim theft by caller | **CLOSED** — tokens go to `skimRecipient` only |

---

## 2026-08-22 — SCONE methodology applied

Ref: [Anthropic smart contract research](https://www.anthropic.com/research/smart-contracts) — fork + **profit measurement**, TVL-first targets, bug classes (missing `view`, access control gaps, rounding direction).

See `scone-methodology.md`.

### Compound local PoCs (`compound/src/comet/forge/test/poc/`)

| Phase | Hypothesis | Result |
|-------|------------|--------|
| 2 | `absorb` reserve socialization / absorber profit | **CLOSED** — 2/2 PASS, absorber balance unchanged |
| 3 | Collateral withdraw when underwater | **CLOSED** — 2/2 PASS |
| 4 | Base transfer debt escape | **CLOSED** — 2/2 PASS |
| 5 | Oracle drop + buyCollateral quote | **CLOSED** — 3/3 PASS (buy gated when reserves healthy) |
| 7 | SCONE profit probes (attacker delta) | **CLOSED** — 3/3 PASS |

### Mainnet fork (`compound/test/poc/`)

| Phase | Probe | Result |
|-------|-------|--------|
| 6 | USDC Comet solvency | **PASS** |
| 8 | Attacker USDC balance + reserves | **PASS** (2/2) |

### Known Comet surfaces (upstream tested)

- `buyCollateral` reentrancy — documented in `CometWithExtendedAssetList.sol`; `EvilToken.sol` BUY_COLLATERAL attack path
- `nonReentrant` on user ops — blocks callback reentry

### Next (SCONE-aligned)

1. Mainnet fork at **pinned block** + whale-funded attack sequences on USDC/WETH Comets
2. Cross-market pattern scan (same bug class on all Comet deployments)
3. Bulker / OnChainLiquidator composition edges
4. DefiHackLabs-style historical pattern grep on Comet diffs

**Verdict so far:** no submit-ready finding on Compound Phase 2–8.
