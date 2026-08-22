# Morpho Hunt — Phases 2–20 Summary

**Date:** 2026-08-22  
**Target:** Morpho Blue + peripheral (IRM, MetaMorpho)  
**Verdict:** No submit-ready finding after 19 phases.

## Test matrix

| Phase | Hypothesis | PoC / probe | Result |
|-------|------------|-------------|--------|
| 2 | Liquidation zero-seize profit | `Phase02LiquidationRoundingPoC.t.sol` | **CLOSED** — liquidator pays 1 wei, gets 0 collateral; no drain |
| 3 | Callback reentrancy drain | `Phase03ReentrancyPoC.t.sol` | **CLOSED** — reentry possible mid-tx; morpho solvency preserved (Certora `reentrancySafe`) |
| 4 | Flash loan cross-market borrow | `Phase04FlashLoanPoC.t.sol` | **CLOSED** — reverts without collateral |
| 5 | Borrow-share inflation / bad debt | `Phase05BadDebtShareInflationPoC.t.sol` | **CLOSED** — bad debt capped (`testBadDebtOverTotalBorrowAssets` upstream) |
| 6 | Fee accrual over-mint | `Phase06FeeAccrualPoC.t.sol` | **CLOSED** — fee ≤ interest |
| 7 | EIP-712 auth replay | `Phase07AuthorizationPoC.t.sol` | **CLOSED** — nonce + deadline enforced |
| 8 | Supply rounding inflation | `Phase08ShareRoundingPoC.t.sol` | **CLOSED** — 50×1 wei deposits withdraw ≤50 |
| 9 | Oracle spike in same tx | `Phase09OracleManipulationPoC.t.sol` | **CLOSED** — withdraw blocked after price reset |
| 10 | Full repay by shares dust | `Phase10RepayRoundingPoC.t.sol` | **CLOSED** — debt clears to 0 |
| 11 | Mainnet fork sanity | `Phase11MainnetForkPoC.t.sol` + `MorphoBlueFork.t.sol` | **PASS** — Morpho + IRM deployed, owner set |
| 12 | Zero IRM phantom interest | `Phase12IrmZeroPoC.t.sol` | **CLOSED** — no accrual without IRM |
| 13 | Unauthorized borrow/withdraw | `Phase13UnauthorizedPoC.t.sol` | **CLOSED** — `UNAUTHORIZED` |
| 14 | Liquidate without loan payment | `Phase14LiquidateCallbackPoC.t.sol` | **CLOSED** — reverts (no approval) |
| 15 | Foundry invariants | `DynamicInvariantTest` + `StaticInvariantTest` | **PASS** — 6 invariant suites, 0 failures |
| 16 | Upstream integration suite | `forge test` morpho-blue | **PASS** — 145/145 |
| 17 | AdaptiveCurve IRM | `morpho-blue-irm` clone | **PASS** — 40/40 (utilization edges) |
| 18 | MetaMorpho v1.1 vault | `metamorpho-v1.1` clone | See phase18 note |
| 19 | Certora / audit surface | `certora/specs/*.spec` | Known issues documented; no new bypass |
| 20 | Final triage | All PoCs + upstream | **No bounty-grade exploit** |

## Closest items (not submit-ready)

1. **Zero-seize liquidation** (`liquidate(..., 0, 1)`) — upstream `testSeizedAssetsRoundUp`. Liquidator **loses** 1 wei; borrower debt reduced trivially. Not profitable attack.

2. **Mid-callback reentrancy** — supply callback can reenter `withdraw` before `transferFrom`, but caller must still fund supply; no protocol drain observed.

3. **Borrow 0 assets / N shares** — documented in IMorpho; bad debt socialization uses `min(totalBorrowAssets, …)` cap.

## Commands

```bash
# Morpho Blue PoCs (phases 2–14)
cd morpho/src/morpho-blue && forge test --match-path "test/poc/*" -vv

# Fork probes (phase 11)
cd morpho && forge test --match-path "test/poc/*" -vv

# Full upstream + invariants
cd morpho/src/morpho-blue && forge test
cd morpho/src/morpho-blue && forge test --match-contract "DynamicInvariantTest|StaticInvariantTest"
```

## Next target

If continuing bounty hunt: deepen **MetaMorpho reallocate races** (phase 18+) or pivot to another Immunefi program.
