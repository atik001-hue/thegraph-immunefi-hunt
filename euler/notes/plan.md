# Euler Phase Plan (SCONE-style)

**Bounty:** Cantina up to $7.5M  
**Repos:** EVK + EVC + EPO (known vaults only)

| Phase | Hypothesis | Entry |
|-------|------------|-------|
| 1 | Setup + fork sanity | **DONE** — EVC 179 tests, EVK 469 unit, fork 2/2 |
| 2 | Zero-collateral free seize + deferred violator | `Liquidation.sol` / Phase02 PoC |
| 3 | Debt socialization early trigger | `Liquidation.sol` executeLiquidation |
| 4 | Nested batch deferred check restore | `EthereumVaultConnector.sol` |
| 5 | Bid/ask vs mid liquidation wedge | `LiquidityUtils.sol` |
| 6 | Share rounding / skim donation | `Vault.sol` skim, ConversionHelpers |
| 7 | Cap snapshot mid-batch | `RiskManager.sol` |
| 8 | Hook / balanceTracker reentrancy | `Base.sol` callHook |
| 9 | controlCollateral arbitrary calldata | EVC `controlCollateral` |
| 10 | Oracle router ERC4626 inflation | `euler-price-oracle` |
| 11–15 | Mainnet fork known vaults profit probes | `is-known` vaults |
| 16–20 | EulerEarn / EulerSwap if EVK closed | clone + hunt |

Success bar: **attacker asset balance increases** on fork/local with quantified USD risk.
