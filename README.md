# BUG-BOUNTRY

Immunefi bug bounty research workspace.

## Repositories

| Project | Status | Immunefi |
|---------|--------|----------|
| [thegraph/](thegraph/) | Hunt complete (13 phases) — no submit-ready finding | [The Graph](https://immunefi.com/bug-bounty/thegraph/) |
| morpho/ | **Next target** — setup in progress | [Morpho](https://immunefi.com/bug-bounty/morpho/) |

## The Graph hunt summary

- **13 phases** across RewardsManager, SubgraphService, HorizonStaking, DisputeManager, bridge, billing, issuance
- **Closest lead:** `closeStaleAllocation` reward inflation — ruled out (same economics as `stopService`)
- **L-07:** `feesProvisionTracker` slash desync — confirmed, no profit path, likely OOS
- Full write-up: `thegraph/notes/phase13-status.md`

## Quick start (The Graph)

```bash
cd thegraph
cp .env.example .env   # add RPC URLs — never commit .env
cd src/contracts && pnpm install   # first time only
forge test --match-path test/poc/ -vv
```

## Rules

- Local forks only for live contract testing
- PoC required for submissions
- Never commit `.env` or API keys
