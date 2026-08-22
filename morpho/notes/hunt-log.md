# Morpho Hunt Log

## 2026-08-22 — Phase 1 kickoff

- Selected **Morpho Blue** after The Graph hunt (13 phases, no submit-ready finding)
- Cloned `morpho-org/morpho-blue` under `src/morpho-blue`
- Upstream `LiquidateIntegrationTest`: **10/10 PASS**
- Fork probes `MorphoBlueFork.t.sol`: **2/2 PASS** (mainnet Morpho `0xBBBB…`)

---

## 2026-08-22 — Phases 2–20 (continuous hunt)

**Verdict: no submit-ready finding.** Full matrix in `phases-2-20-summary.md`.

### PoCs added (`src/morpho-blue/test/poc/`)

| File | Phase | Outcome |
|------|-------|---------|
| `Phase02LiquidationRoundingPoC.t.sol` | 2 | Zero-seize: no liquidator profit |
| `Phase03ReentrancyPoC.t.sol` | 3 | Reentry ok; no drain |
| `Phase04FlashLoanPoC.t.sol` | 4 | Cross-market borrow blocked |
| `Phase05BadDebtShareInflationPoC.t.sol` | 5 | Bad debt capped |
| `Phase06FeeAccrualPoC.t.sol` | 6 | Fee ≤ interest |
| `Phase07AuthorizationPoC.t.sol` | 7 | Sig replay blocked |
| `Phase08ShareRoundingPoC.t.sol` | 8 | No withdraw inflation |
| `Phase09OracleManipulationPoC.t.sol` | 9 | Same-tx oracle spike blocked |
| `Phase10RepayRoundingPoC.t.sol` | 10 | Full repay clears debt |
| `Phase12IrmZeroPoC.t.sol` | 12 | No phantom interest |
| `Phase13UnauthorizedPoC.t.sol` | 13 | Auth enforced |
| `Phase14LiquidateCallbackPoC.t.sol` | 14 | Unpaid liq reverts |

### Fork / upstream

- `morpho/test/poc/Phase11MainnetForkPoC.t.sol` — **PASS**
- Upstream morpho-blue: **145/145 PASS**
- Invariants (Dynamic + Static): **6/6 PASS**
- AdaptiveCurve IRM clone: **40/40 PASS**
- MetaMorpho v1.1 clone: **196/196 PASS**

### Next if continuing

- MetaMorpho `reallocate` / curator race fuzzing on fork
- Morpho Bundler3 batch interactions
- Pivot to next Immunefi program if no edge found
