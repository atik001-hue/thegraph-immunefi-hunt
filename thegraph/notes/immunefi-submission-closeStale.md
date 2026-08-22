# Immunefi Report Draft — closeStaleAllocation Indexing Reward Inflation

Copy into Immunefi submission after KYC.

---

## Title

Permissionless `closeStaleAllocation` inflates survivor indexing rewards via premature `onSubgraphAllocationUpdate`

## Severity

High / Critical — unauthorized GRT mint (indexing rewards inflation)

## Asset

- SubgraphService: `0xb2Bb92d0DE618878E438b55D5846cfecD9301105` (Arbitrum One)
- RewardsManager: `0x971B9d3d0Ae3ECa029CAB5eA1fB0F72c85e6a525` (Arbitrum One)

## Description

`SubgraphService.closeStaleAllocation()` is permissionless. It calls `_resizeAllocation(allocationId, 0, delegationRatio)` to zero a stale allocation’s tokens without fully closing it.

In `AllocationHandler._resizeAllocation`, the contract invokes `RewardsManager.onSubgraphAllocationUpdate()` **before** decrementing `_subgraphAllocatedTokens` for the subgraph deployment. The rewards manager distributes undistributed subgraph rewards using the **pre-resize** allocated token total (still counting the stale allocation). The stale allocation’s pending rewards are then reclaimed via `STALE_POI`, but the elevated global `accRewardsPerAllocatedToken` persists. Remaining allocations on the same subgraph collect indexing rewards at an inflated rate.

With two equal allocations, survivor mint is **exactly 2×** the honest baseline (PoC: 5000 GRT vs 10000 GRT).

## Proof of Concept

Repository path: `thegraph/src/contracts/packages/testing/test/integration/IndexingRewardsCloseStaleOverMintPoC.t.sol`

```bash
cd src/contracts/packages/testing
forge test --match-contract IndexingRewardsCloseStaleOverMintPoC -vv
```

Requires `@graphprotocol/contracts` RewardsManager artifact (standard monorepo install).

Expected output:

```
honestSurvivorMint: 5000000000000000000000
afterCloseStaleMint: 10000000000000000000000
```

## Steps to Reproduce

1. Indexer allocates equal tokens to allocations A and B on the same subgraph deployment.
2. Present POIs on B only; wait until A is stale.
3. Anyone calls `closeStaleAllocation(A)`.
4. Indexer collects rewards on B — receives ~2× vs control with one allocation.

## Impact

Unauthorized inflation of GRT indexing rewards. Attack scales with the ratio of total subgraph allocated tokens to survivor tokens. No privileged access required; indexer can self-trigger on their own stale allocation.

## Recommended Fix

When decreasing allocation size in `_resizeAllocation`, update `_subgraphAllocatedTokens` **before** `onSubgraphAllocationUpdate`.

## References

- Root cause: `subgraph-service/contracts/libraries/AllocationHandler.sol` (`_resizeAllocation`)
- Full write-up: `notes/phase12-finding.md`
