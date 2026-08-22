# Compound III (Comet) — Immunefi Hunt

**Program:** https://immunefi.com/bug-bounty/compound/  
**Repo:** `src/comet` (compound-finance/comet)

## In-scope surface

| Area | Contract / fn | Notes |
|------|---------------|-------|
| Absorption | `absorb`, `absorbInternal` | Underwater accounts → protocol sheet |
| Collateral | `supplyCollateral`, `withdrawCollateral` | Multi-asset |
| Base | `supply`, `withdraw`, `transfer` | Interest-bearing base |
| Liquidation | `isLiquidatable`, liquidation factors | Per-asset |
| Governance pause | `isAbsorbPaused`, `isWithdrawPaused` | |

## Mainnet (Ethereum USDC)

- Comet USDC: check `deployments/mainnet/usdc/` in repo for address
- Fork tests require `MAINNET_RPC_URL`

## Phase 1 hypotheses

1. **Absorb rounding** — `deltaBalance` / `repayAndSupplyAmount` socializes debt incorrectly
2. **Collateral withdraw** after price drop — health check bypass
3. **Transfer** of comet balance (receipt token) with debt
4. **Reserve drain** via repeated small absorbs
5. **Price feed** manipulation within block (Chainlink)

## Commands

```bash
cd compound/src/comet && forge test
cd compound && forge test --match-path "test/poc/*" -vv
```

## Status

Phase 1 bootstrapped — clone + Comet.t.sol smoke test PASS. Hunt active.
