# Phase 8 — Unaudited In-Scope Targets

**Status:** Complete pass, no Immunefi-submit-ready finding  
**Date:** 2026-08-22

## Targets Reviewed

| Contract | Address | Result |
|----------|---------|--------|
| L2GNS | `0xec9A7fb6CbC2E41926127929c2dcE6e9c5D33Bec` | Rounding refund path is owner-only; no theft |
| StakingExtension | `0x3bE385576d7C282070Ad91BF94366de9f9ba3571` | Delegatecall impl; legacy L2 staking slash skips delegators (OZ H-02 area) |
| AllocationExchange | `0x993F00C98D1678371a7b261Ed0E0D4b6F42d9aEE` | Raw keccak vouchers; needs authority sig; no unprivileged drain |
| SubgraphNFT | `0x3FbD54f0cc17b7aE649008dEEA12ed7D2622B23f` | Minter-gated; no GRT flow |
| GraphTokenLockWallet | `0xbE5e630383b5BAEcF0Db7b15C50d410edD5A2255` | Fixed Mar 2026 (OOS) |
| HorizonStakingExtension legacySlash | build-info bytecode | Transition-period partial slash; DisputeManager legacy disputes by design |
| Legacy allocation ID reuse | SubgraphService + HorizonStaking | By design (`LegacyAllocationAlreadyExists`) |

## PoCs Added

| Test | Location | Result |
|------|----------|--------|
| L-07 slash vs feesProvisionTracker | `horizon/test/unit/data-service/extensions/DataServiceFeesSlash.t.sol` | **PASS** — confirms OZ L-07 accounting desync |
| Phase 8 fork probes | `test/poc/Phase8TargetsFork.t.sol` | **PASS** (3/3) |

## L-07 Finding (Not Submittable)

**Confirmed:** `HorizonStaking.slash()` reduces provision but `feesProvisionTracker` / stake claims unchanged until expiry release.

**Immunefi status:** Likely **out of scope** — OpenZeppelin Horizon audit L-07 listed as partial fix in `notes/audit-findings.md`. Program rules exclude unfixed listed audit issues unless Primacy of Impact applies with demonstrated fund loss.

**Impact assessment:** Accounting inconsistency during dispute window; post-expiry release re-enables fee collection capped by post-slash `getTokensAvailable`. No demonstrated double-spend or protocol drain in PoC.

## Next Pivot Options

1. Archive-block forks around Horizon migration (legacySlash transition window)
2. Stateful fuzz on SubgraphService + real RewardsManager (`packages/testing` RealRewardsHarness)
3. IssuanceAllocator / RecurringAgreementManager (may be outside Immunefi address list — verify deployment)
4. Monitor new unaudited deployments on Arbitrum Controller

## Fork Test Count

Run all PoCs: `forge test --match-path "test/poc/*.t.sol" -vv`  
**24 pass, 2 skip** (includes Phase 8)
