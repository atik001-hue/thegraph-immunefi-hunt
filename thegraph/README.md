# The Graph — Immunefi Hunt

Foundry workspace for auditing [The Graph bug bounty](https://immunefi.com/bug-bounty/thegraph/information/) on Immunefi.

## Setup

Requires [Foundry](https://book.getfoundry.sh/getting-started/installation).

```bash
cp .env.example .env
# Edit .env with Alchemy/Infura RPC URLs

forge test --match-path test/poc/ -vvv
```

## Source repos (cloned under `src/`)

| Repo | Path |
|------|------|
| [graphprotocol/contracts](https://github.com/graphprotocol/contracts) | `src/contracts/` |
| [graphprotocol/token-distribution](https://github.com/graphprotocol/token-distribution) | `src/token-distribution/` |
| [edgeandnode/billing-contracts](https://github.com/edgeandnode/billing-contracts) | `src/billing/` |

Audit PDFs live inside `src/contracts/packages/*/audits/`.

## Notes

See `notes/` for scope, audit queue, attack surface tracker, and PoC guide.

## Current focus

**RewardsManager** (L1 + Arbitrum) — highest fund flow, recent Horizon upgrades, fork tests in `test/poc/RewardsManagerFork.t.sol`.
