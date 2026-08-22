# SCONE-Style Hunt Methodology

Based on [Anthropic's smart contract research](https://www.anthropic.com/research/smart-contracts) (SCONE-bench).

## Core principles

1. **Fork at pinned block** — reproducible state; use `vm.createSelectFork(rpc, blockNumber)`.
2. **Success = profit** — measure executor native/base token balance delta, not just "revert/no revert".
3. **Target TVL** — prioritize contracts with high assets under management (exploit $ ∝ TVL, not code complexity).
4. **Maximize extraction** — if a pattern hits multiple markets/pools/tokens, drain all instances (article: Opus 4.5 vs GPT-5 on FPC).
5. **Iterative Foundry loop** — forge test → adjust → re-run until profit ≥ threshold or hypothesis closed.

## High-yield bug classes (from article + DefiHackLabs patterns)

| Class | Example | Hunt action |
|-------|---------|-------------|
| Missing `view` | Public "calculator" mutates state | Grep `external`/`public` without `view` that only "reads" |
| Access control gap | Empty beneficiary → anyone claims fees | Optional params default to `address(0)` without revert |
| Rounding direction | Balancer $120M (Nov 2025) | Fuzz liquidate/absorb/transfer with 1-wei edges |
| Callback reentrancy | Pre-transfer hook skews balance | Malicious ERC777/ERC1363 on supply/buy |
| Cross-contract reuse | Same bug in many pools | Same pattern across Comet markets (USDC/WETH/wstETH) |

## Our harness

```bash
# Local Comet harness (fast iteration)
cd compound/src/comet && forge test --match-path "forge/test/poc/*" -vv

# Mainnet fork profit probes
cd compound && forge test --match-path "test/poc/*" -vv
```

## Profit threshold

Immunefi / SCONE: quantify **funds at risk** in USD. We use:

- Local: attacker base token balance increase > 0 with supplier/protocol solvency check
- Fork: attacker USDC/WETH balance delta after attack sequence

## Current status

Phases 2–5 local PoCs: absorb, withdraw, transfer, oracle — **7/8 pass** (buyCollateral gated by `NotForSale` when reserves healthy — expected).
