# Morpho Hunt Log

## 2026-08-22 — Phase 1 kickoff

- Selected **Morpho Blue** after The Graph hunt (13 phases, no submit-ready finding)
- Cloned `morpho-org/morpho-blue` under `src/morpho-blue`
- Upstream `LiquidateIntegrationTest`: **10/10 PASS**
- Fork probes `MorphoBlueFork.t.sol`: **2/2 PASS** (mainnet Morpho `0xBBBB…`)

### Top hypotheses (Phase 2)

1. Liquidation rounding — zero seize / debt repaid
2. Borrow-share inflation at low utilization (documented in IMorpho)
3. Callback reentrancy ordering (supply/repay/liquidate)
4. Flash loan cross-market manipulation
5. Bad debt socialization + LIF extraction

See `plan.md` and upstream audits in `src/morpho-blue/audits/`.
