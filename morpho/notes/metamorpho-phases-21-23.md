# Morpho — MetaMorpho Phases 21–23

**Verdict:** No submit-ready finding. Pivot to Compound.

| Phase | PoC | Result |
|-------|-----|--------|
| 21 | `Phase21DonationAttackPoC` | Donation on behalf **increases** existing holder `convertToAssets` |
| 22 | `Phase22LostAssetsAmplifyPoC` | 20-cycle deposit/withdraw: `lostAssets` ≤ 100 wei, no profit |
| 23 | `Phase23SkimPoC` | `skim()` sends to `skimRecipient`, not caller |

Upstream MetaMorpho suite: **196/196 PASS**. Certora `LostAssetsLink.spec` + `Reentrancy.spec` align with results.

Run: `cd morpho/src/metamorpho-v1.1 && forge test --match-path test/poc/* -vv`
