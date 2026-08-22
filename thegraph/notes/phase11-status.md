# Phase 10–11 — Bridge, Collusion, Reward Edge Cases

**Status:** Complete — no Immunefi-submit-ready finding  
**Date:** 2026-08-22

## Phase 10 (completed)

| Track | Artifact | Result |
|-------|----------|--------|
| L1 gateway mint allowance | `test/poc/Phase10GatewayMintFork.t.sol` | PASS — headroom healthy |
| BillingConnector wiring | `test/poc/BillingConnectorFork.t.sol` | PASS (prior) |

## Phase 11 (completed)

| Track | Artifact | Result |
|-------|----------|--------|
| L-18 dispute collusion | `subgraph-service/.../indexing/collusion.t.sol` | **PASS** — slash beyond provision, pool untouched, delegator exits full (OZ H-02/M-05, likely OOS) |
| L-11 stale POI + close | `testing/.../IndexingRewardsStaleClose.t.sol` | **PASS** — no double mint with real RewardsManager |
| GraphPayments / L2GRT / NFT forks | `test/poc/Phase11TargetsFork.t.sol` | PASS — live wiring sane |

## Fork totals

```bash
forge test --match-path "test/poc/*.t.sol" -vv
# 32 pass, 2 skip
```

## Phase 12 candidates

1. Archive fork at Horizon upgrade deployment block (legacy slash transition)
2. Eligibility oracle + `revertOnIneligible` vs deferred collect paths
3. IssuanceAllocator on-chain address verification + self-mint drift vs L1 gateway allowance
4. Stateful fuzz: query-fee collect → slash → fee tracker desync (L-07 live exploit attempt)
5. Indexing-fee dispute accept path (integration, not mocked collector)
