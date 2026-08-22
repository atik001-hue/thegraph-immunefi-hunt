# BUG-BOUNTRY

Bug bounty research workspace (Immunefi + Cantina).

## Repositories

| Project | Status | Program |
|---------|--------|---------|
| [thegraph/](thegraph/) | Closed (13 phases) — no submit-ready | [Immunefi](https://immunefi.com/bug-bounty/thegraph/) |
| [morpho/](morpho/) | Closed (~23 phases) — no submit-ready | [Immunefi](https://immunefi.com/bug-bounty/morpho/) |
| [compound/](compound/) | Closed (8 phases) — no submit-ready | Compound III / Comet |
| [euler/](euler/) | **Active** — Phase 1–2 done | [Cantina $7.5M](https://cantina.xyz/bounties/4d285eee-602e-440a-845e-25e155cec26a) |

## Euler (current)

```bash
cd euler && forge test --match-path test/poc/ -vv
cd src/euler-vault-kit && forge test --match-contract Phase02 -vv
```

Scope: `euler/notes/scope.md` · Plan: `euler/notes/plan.md`

## Rules

- Local forks only for live contract testing
- PoC required; measure attacker profit (SCONE-style)
- Never commit `.env` or API keys
