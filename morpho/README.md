# Morpho — Immunefi Hunt

Next bug bounty target after [The Graph hunt](../thegraph/).

## Setup

```bash
cd morpho
cp .env.example .env          # MAINNET_RPC_URL, BASE_RPC_URL
cd src/morpho-blue && forge install && cd ../..
```

Run upstream integration tests:

```bash
cd src/morpho-blue
forge test --match-contract LiquidateIntegrationTest -vv
```

Run our fork probes:

```bash
# from morpho/ with foundry.toml
forge test --match-path test/poc/ -vv
```

## Plan

See [notes/plan.md](notes/plan.md) — Phase 1 setup, Phase 2 liquidation/callback/flash-loan hypotheses.

## Program

- [Immunefi Morpho](https://immunefi.com/bug-bounty/morpho/) — up to **$2.5M** critical
- [Cantina bounty](https://cantina.xyz/bounties/35a5f0a1-2ffd-432c-8f3b-77d169add8c3)
