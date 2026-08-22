# PoC Guide

## Run fork tests

```bash
cd thegraph
cp .env.example .env   # add your RPC URLs
forge test --match-path test/poc/ -vvv
```

## Writing a valid Immunefi PoC

1. Fork the chain where the vulnerable contract lives (mainnet `1` or Arbitrum `42161`).
2. Use **in-scope deployed addresses** from `notes/scope.md`.
3. Demonstrate impact without touching live networks.
4. Put the full PoC in the report body (no external-only links).

## Template location

- `test/poc/RewardsManagerFork.t.sol` — start here; duplicate for other targets.
- Immunefi templates: https://immunefi.com/blog/security-guides/immunefi-poc-templates/

## Report checklist

- [ ] Severity matches Immunefi impact table
- [ ] Affected asset is in scope
- [ ] Not a known/audited issue (`notes/audits.md`)
- [ ] Runnable Foundry test attached
- [ ] Clear fund-at-risk calculation for Critical/High
