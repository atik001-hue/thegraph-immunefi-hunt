# Morpho — Immunefi Scope

**Program:** https://immunefi.com/bug-bounty/morpho/  
**Docs:** https://docs.morpho.org/morpho/concepts/security/bug-bounty/

## Core deployments (Morpho Blue)

| Chain | Morpho Blue | AdaptiveCurveIRM |
|-------|-------------|------------------|
| Ethereum | `0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb` | `0x870aC11D48B15DB9a138Cf899d20F13F79Ba00BC` |
| Base | `0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb` | `0x46415998764C29aB2a25CbeA6254146D50D22687` |
| Arbitrum | `0x6c247b1F6182318877311737BaC0844bAa518F5e` | `0x66F30587FB8D4206918deb78ecA7d5eBbafD06DA` |

**Note:** Arbitrum uses a non-CREATE2 deploy address.

## Max rewards (smart contracts)

| Asset class | Critical max |
|-------------|--------------|
| Morpho Blue + IRM | $2,500,000 |
| MetaMorpho / Vault V2 | $1,500,000 |

## Rules

- PoC required; quantify funds at risk
- Check audits before submit (OOS if listed unfixed)
- Fork-only for live contract testing
