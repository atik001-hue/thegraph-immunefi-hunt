# Morpho — Immunefi Hunt Plan

**Program:** [Immunefi Morpho](https://immunefi.com/bug-bounty/morpho/)  
**Also:** [Cantina $2.5M](https://cantina.xyz/bounties/35a5f0a1-2ffd-432c-8f3b-77d169add8c3)  
**Max critical:** $2,500,000 (Morpho Blue + IRM) | $1,500,000 (Vault V1/V2)

## Why Morpho (after The Graph)

| Factor | Morpho | The Graph (done) |
|--------|--------|------------------|
| Max bounty | **$2.5M** | $50k |
| Code style | Foundry-native, compact core | Huge monorepo, heavily hunted |
| Attack surface | Lending math, liquidations, callbacks, oracles | Rewards accounting (exhausted) |
| Audits | Multiple (Trail of Bits, etc.) — but active new vault versions | OZ + Trust, 13 phases clear |

## Phase plan

| Phase | Goal | Status |
|-------|------|--------|
| 1 Setup | Clone repos, scope.md, foundry.toml, fork RPC | 🔄 In progress |
| 2 Recon | Map markets, IRM, oracle, liquidation, flashLoan | Pending |
| 3 PoC | Top 3 hypotheses with fork tests | Pending |
| 4 Report | Submit if submit-ready | Pending |

## In-scope repos (clone under `src/`)

| Repo | Focus |
|------|--------|
| [morpho-org/morpho-blue](https://github.com/morpho-org/morpho-blue) | Core lending (`Morpho.sol`) |
| [morpho-org/morpho-blue-irm](https://github.com/morpho-org/morpho-blue-irm) | AdaptiveCurveIRM |
| [morpho-org/metamorpho-v1.1](https://github.com/morpho-org/metamorpho-v1.1) | MetaMorpho vaults |
| [morpho-org/bundler3](https://github.com/morpho-org/bundler3) | Bundler (lower priority) |

## Priority hypotheses (Phase 2)

1. **Liquidation rounding** — seize/share math, bad debt socialization (`Morpho.sol`)
2. **Flash loan callback reentrancy** — state during `flashLoan` callback
3. **IRM rate manipulation** — borrow rate edge at utilization boundaries
4. **Oracle price staleness / manipulation** — MorphoChainlinkOracleV2
5. **MetaMorpho reallocate race** — vault curator vs market liquidity

## Rules

- Fork-only testing on mainnet/Base/Arbitrum deployments
- PoC required; optimize for max funds at risk in report
- Check audit reports before submitting (OOS if listed unfixed)

## Commands

```bash
cd morpho
cp .env.example .env
forge test --match-path test/poc/ -vv
```
