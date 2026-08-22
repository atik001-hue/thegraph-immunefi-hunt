# Euler V2 — Bug Bounty Scope

**Program:** [Cantina Euler-Bounty](https://cantina.xyz/bounties/4d285eee-602e-440a-845e-25e155cec26a)  
**Max reward:** up to **$7.5M USDC** (+ rEUL + USUAL)  
**Docs:** https://docs.euler.finance/security/bug-bounty/

> Note: Euler moved from Immunefi to **Cantina**. Same SCONE-style hunt applies (fork + profit PoC).

## Core components in scope

| Component | Repo | Role |
|-----------|------|------|
| **EVC** | `ethereum-vault-connector` | Account layer, batching, collateral enable, liquidations coordination |
| **EVK** | `euler-vault-kit` | ERC-4626 credit vaults (lend/borrow) |
| **EPO** | `euler-price-oracle` | Modular oracles + EulerRouter |
| EulerEarn / EulerSwap / Fee Flow / Reward Streams | separate repos | Also in program when relied on by known vaults |

## Vault scope rule (critical)

Only vaults returned as **known** by production API:

```bash
curl 'https://app.euler.finance/api/public/is-known?chainId=1'
curl 'https://app.euler.finance/api/public/is-known?chainId=1&addresses=0x...'
```

## Mainnet anchors

| Contract | Address |
|----------|---------|
| EVC | `0x0C9a3dd6b8F28529d72d7f9cE918D493519EE383` |

## Hunt rules (SCONE)

1. Fork at pinned block; measure **attacker profit** in base/native token.
2. Prefer high-TVL **known** vaults.
3. PoC required; check audits in `audits/` before submit.
4. OOS: known audit items, governance/oracle-config risk alone, non-standard token isolation issues per program rules.

## Phase 1 hypotheses

1. EVC batch reentrancy / deferred liquidity checks
2. EVK liquidation + socialized loss rounding
3. Cross-vault collateral enable race in same batch
4. Oracle router ERC4626 convertToAssets inflation
5. Controller / hook bypass on known vaults
