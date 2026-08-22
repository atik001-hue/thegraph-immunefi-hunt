# Phase 4 Status — The Graph Immunefi Hunt

Last updated: 2026-08-22

## Summary

Phase 4 completed manual review of **PaymentsEscrow**, **BillingConnector**, **BridgeEscrow / L1GraphTokenGateway**, and **RecurringCollector envelope logic**. **No submit-ready vulnerabilities found.**

## Fork probe results (10 pass, 2 skip)

```bash
cd /Volumes/ORICO/BUG-BOUNTRY/thegraph
forge test --match-path "test/poc/*.t.sol" -vv
```

| Test file | Result |
|-----------|--------|
| `RewardsManagerFork.t.sol` | 5 pass, 1 placeholder skip |
| `BillingConnectorFork.t.sol` | 3 pass — L1↔L2 wiring + callhook allowlist verified |
| `BridgeEscrowFork.t.sol` | 2 pass — escrow balance + L2 mint allowance healthy |
| `AllocationCloseHypothesis.t.sol` | 1 skip — H-R1 ruled out in Phase 3 |

### Live mainnet observations (fork)

- **BridgeEscrow** holds ~2.85B GRT; gateway has max allowance
- **L1GraphTokenGateway** `totalMintedFromL2 = 0`; accumulated allowance >> minted
- **BillingConnector** wired to expected gateway, inbox, L2 billing; on callhook allowlist

## Lead-by-lead conclusions

### 1. PaymentsEscrow — Slither reentrancy (CLOSED)

**Slither flag:** external call to `GraphPayments.collect()` before post-call balance invariant check.

**Verdict: false positive / intentional defense-in-depth**

- `collect()` debits escrow accounting **before** the external call (lines 177–177 in `PaymentsEscrow.sol`)
- Post-call invariant `escrowBalanceBefore == tokens + escrowBalanceAfter` ensures `GraphPayments` pulled exactly `tokens`
- Unit test `testCollect_RevertWhen_InconsistentCollection` mocks a no-op collect and confirms revert
- 53 escrow unit tests pass (including all collect paths)
- Reentrancy into `collect()` cannot steal funds: second call hits insufficient balance or inconsistent-collection revert

### 2. BillingConnector (CLOSED)

**Reviewed paths:** `addToL2`, `addToL2WithPermit`, `removeOnL2`, `_permit` fallback, callhook `extraData`

**Verdict: no exploitable external path**

| Path | Analysis |
|------|----------|
| `addToL2(_to, …)` | `_to` encoded in callhook; L2 `onTokenTransfer` credits decoded user; `_from` must be BillingConnector |
| `addToL2WithPermit` | `_user == msg.sender`; permit fallback only when allowance already sufficient |
| `removeOnL2` | L2 `removeFromL1` debits `_from = msg.sender` (L1 caller); cannot drain others |
| Spoofed L1 sender on L2 | Blocked by `require(_from == l1BillingConnector)` |

Fork tests confirm reciprocal wiring between `0x8017…ea72`, `0x01cDC9…`, `0x1B07…477a`, `0x65E1…D302`.

### 3. BridgeEscrow + L1GraphTokenGateway (CLOSED)

**Reviewed:** `BridgeEscrow.approveAll`, `finalizeInboundTransfer`, `_mintFromL2`, L2 mint allowance accumulator

**Verdict: operational/governance risk only, not externally exploitable**

- Escrow is a passive GRT holder; only governor can approve/revoke spenders
- L2→L1 withdrawals use escrow first; overflow mints gated by `_l2MintAmountAllowed`
- Live state: zero minted-from-L2 total; allowance snapshot healthy

### 4. RecurringCollector / RAM envelope (CLOSED)

**TRST-CL-1 / TRST-M-3 variants**

- 22/22 `getMaxNextClaim` tests pass, including post-update collection envelope cases
- `test_GetMaxNextClaim_PendingScope_CoversPostUpdateCollection` confirms fix for stale-envelope overcharge
- TRST-M-3 (operator misconfiguration mode degradation) is **acknowledged**, not an unprivileged exploit

### 5. GraphPayments rounding (CLOSED)

- `mulPPMRoundUp` uses `a - mulPPM(a, MAX_PPM - b)` — mathematically bounded so sum of cuts ≤ `tokens`
- Worst case: payment reverts (grief), not over-withdrawal from escrow

## What you do NOT need to do

Everything in Phase 4 ran autonomously with public RPCs. No API keys, KYC, or manual steps required.

## Optional upgrades (Phase 5+)

| Item | Benefit |
|------|---------|
| Alchemy/Infura archive RPC in `.env` | Historical-block forks for time-dependent bugs |
| Immunefi account + KYC | Required only when submitting a finding |

## Suggested Phase 5 targets

1. **DisputeManager** — slashing + fisherman reward paths (`0x0Ab2…BD46` Arbitrum, `0x9730…FB0b` L1)
2. **AllocationExchange** — `0x993F…9aEE`
3. **GraphTallyCollector** — `0x8f69…1A9e`
4. **Differential fuzz** — `presentPOI` × allocation resize × collect ordering (beyond June 2026 audit coverage)

## Immunefi submission checklist (unchanged)

- [ ] In-scope contract on fork
- [ ] Foundry PoC in `test/poc/`
- [ ] Not in audit reports as fixed
- [ ] Impact = fund loss / unauthorized mint
- [ ] Report via Immunefi dashboard with inline PoC
