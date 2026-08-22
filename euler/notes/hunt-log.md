# Euler Hunt Log

## 2026-08-22 — Phase 1 kickoff (pivot from Compound)

**Prior:** The Graph (13) + Morpho (23) + Compound (8) — no submit-ready finding.

### Why Euler

- Live Cantina bounty up to **$7.5M**
- Modular surface (EVC + EVK + EPO) distinct from Morpho/Compound
- Foundry-native repos with Certora/audits to cross-check

### Setup

- Cloned `euler-vault-kit`, `ethereum-vault-connector`, `euler-price-oracle` under `src/`
- Scope: `notes/scope.md`, plan: `notes/plan.md`
- Known mainnet vaults: query `is-known?chainId=1`

### Results

| Check | Result |
|-------|--------|
| EVC upstream | **179/179 PASS** |
| EVK unit | **469/469 PASS** (2 skip) |
| Fork EVC + known vault | **2/2 PASS** |
| Phase 2 zero-collateral free seize | **PASS** — documented design (`test_basicLiquidation_worthless_collateral`); oracle=0 → not USD-profitable |
| Phase 2 deferred violator blocks liq | **PASS** — `E_ViolatorLiquidityDeferred` path |

### Status

Phase 1 **DONE**. Phase 2 **CLOSED** (known/documented). Continuing phases 3+ on socialization / batch / oracle wedge.
