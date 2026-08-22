# Phase 12 — NOT SUBMIT-READY (re-verified Phase 13)

**Status:** PoC confirmed behavior, but **do not submit** — matches `stopService` economics  
**Date:** 2026-08-22  
**Severity (proposed):** ~~High / Critical~~ → Informational / intended cleanup

## Summary

Permissionless `SubgraphService.closeStaleAllocation()` resizes a stale allocation to **zero tokens** (without closing it). During `_resizeAllocation`, the contract calls `RewardsManager.onSubgraphAllocationUpdate()` **before** reducing `getSubgraphAllocatedTokens()` for the subgraph deployment.

That distributes undistributed subgraph rewards using an **inflated denominator** (still includes the stale allocation’s tokens). The stale allocation’s pending rewards are then **STALE-reclaimed**, but the elevated global `accRewardsPerAllocatedToken` **remains**. A surviving allocation on the same subgraph collects **~2×** indexing rewards (exact 2× when two equal-sized allocations).

## In-scope contracts

| Contract | Arbitrum address |
|----------|------------------|
| SubgraphService | `0xb2Bb92d0DE618878E438b55D5846cfecD9301105` |
| RewardsManager | `0x971B9d3d0Ae3ECa029CAB5eA1fB0F72c85e6a525` |

## Root cause

```544:572:src/contracts/packages/subgraph-service/contracts/libraries/AllocationHandler.sol
        uint256 accRewardsPerAllocatedToken = graphRewardsManager.onSubgraphAllocationUpdate(
            allocation.subgraphDeploymentId
        );
        ...
        if (allocation.isStale(_maxPOIStaleness)) {
            graphRewardsManager.reclaimRewards(RewardsCondition.STALE_POI, _allocationId);
            _allocations.clearPendingRewards(_allocationId);
        }
        ...
        _subgraphAllocatedTokens[allocation.subgraphDeploymentId] -= (oldTokens - _tokens);
```

`onSubgraphAllocationUpdate` reads allocated token totals from SubgraphService **before** the resize subtracts `oldTokens`.

## Attack (single rogue indexer)

1. Indexer opens **two equal allocations** on the same subgraph deployment (A and B).
2. Present POIs only on B; let A go stale (> `maxPOIStaleness`).
3. Call `closeStaleAllocation(A)` (permissionless — can be the indexer themselves).
4. Collect indexing rewards on B → **~2×** mint vs honest single-allocation baseline.

Third parties can also trigger step 3 on a victim’s stale allocation to **gift** inflation to a colluding survivor on the same subgraph.

## PoC (PASS)

```bash
cd /Volumes/ORICO/BUG-BOUNTRY/thegraph/src/contracts/packages/testing
forge test --match-contract IndexingRewardsCloseStaleOverMintPoC -vv
```

**Observed logs:**

```
honestSurvivorMint: 5000000000000000000000
afterCloseStaleMint: 10000000000000000000000
```

Files:

- `src/contracts/packages/testing/test/integration/IndexingRewardsCloseStaleOverMintPoC.t.sol`
- `src/contracts/packages/testing/test/integration/IndexingRewardsCloseStaleTwoIndexer.t.sol` (regression comparator)

Uses **real RewardsManager** bytecode via `RealRewardsHarness` (requires `@graphprotocol/contracts` artifact).

## Impact

- Unauthorized inflation of GRT indexing rewards (protocol mint cap bypass per subgraph epoch).
- Scales with ratio of total allocated tokens on subgraph to survivor tokens (2 equal allocs → 2×; more stale allocs closed → higher multiplier).
- No privileged roles required.

## Suggested fix

In `_resizeAllocation`, update `_subgraphAllocatedTokens` **before** calling `onSubgraphAllocationUpdate` when **decreasing** allocation size (including resize-to-zero via `closeStaleAllocation`).

## Immunefi checklist

- [x] In-scope deployed contracts
- [x] Foundry PoC with real RewardsManager
- [x] Unprivileged attack path
- [x] Fund mint / inflation impact
- [ ] Fork-only mainnet demo (optional; local integration PoC suffices per program)
- [ ] KYC at submission

## Not duplicate of

- H-R1 deferred POI + `stopService` — closed, different path
- OZ L-07 / delegation slashing — unrelated
- Known `_closeAllocation` pending comment — different function (`closeStaleAllocation` → resize)
