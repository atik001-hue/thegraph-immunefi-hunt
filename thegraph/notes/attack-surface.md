# Attack Surface Map

Working doc for Phase 2+. Update as we read each contract.

## Priority queue

| P | Contract | Chain | Address | Focus |
|---|----------|-------|---------|-------|
| P0 | RewardsManager | L1 | `0x9Ac758AB77733b4150A901ebd659cbF8cB93ED66` | Issuance accrual, reclaim, eligibility |
| P0 | RewardsManager | Arbitrum | `0x971B9d3d0Ae3ECa029CAB5eA1fB0F72c85e6a525` | Same + Horizon subgraph service issuer |
| P0 | SubgraphService | Arbitrum | see scope.md | Allocation lifecycle, POI collect, close |
| P1 | HorizonStaking | Arbitrum | `0x00669A4CF01450B64E8A2A20E9b1FCB71E61eF03` | Provisions, thaw, slash, delegation |
| P1 | DisputeManager | L1 + L2 | see scope.md | Slashing disputes |
| P2 | BridgeEscrow + gateways | L1 + L2 | see scope.md | Escrow, L1↔L2 GRT |
| P2 | BillingConnector | L1 | `0x8017B9AF3F199CC6b08A48DA3859410F20bbea72` | Billing, refunds |
| P3 | Curation / L2Curation | L1 + L2 | see scope.md | Signal, bonding curve |

Full address list: `notes/scope.md`

---

## RewardsManager

**Source:** `src/contracts/packages/contracts/contracts/rewards/RewardsManager.sol`

| Item | Detail |
|------|--------|
| Privileged roles | Governor, Controller, subgraph availability oracle |
| External deps | Curation, GraphToken (mint), SubgraphService, IssuanceAllocator, Eligibility oracle |
| Token flow | Inflation mint → indexer via SubgraphService OR reclaim addresses |

**Critical functions**

| Function | Caller | Impact |
|----------|--------|--------|
| `takeRewards` | SubgraphService only | Mints GRT to issuer for distribution |
| `reclaimRewards` | SubgraphService only | Mints to reclaim address or drops |
| `onSubgraphAllocationUpdate` | Anyone + hooks | Updates per-allocation reward index |
| `setReclaimAddress` | Governor | Retroactive reclaim destination |

**Hypotheses**

- [ ] **H-R1:** Close allocation after deferred POI — pending rewards lost or over-minted (`AllocationHandler._closeAllocation` known limitation)
- [ ] **H-R2:** `undistributedRewards` math when `accRewardsForSubgraph < accRewardsForSubgraphSnapshot` (migration edge)
- [ ] **H-R3:** Reclaim address zero → rewards dropped; grief if indexer expected payment
- [ ] **H-R4:** `getRewards` overestimate vs `takeRewards` (documented in NatSpec — intentional? exploitable?)

**Audits:** OpenZeppelin rewards upgrades, Horizon 2025, L-11 closed allocation views

---

## SubgraphService + AllocationHandler

**Source:** `packages/subgraph-service/contracts/`

| Item | Detail |
|------|--------|
| Entry points | `allocate`, `presentPOI` (via collect), `closeAllocation`, `resizeAllocation` |
| Rewards paths | CLAIMED → `takeRewards`; RECLAIMED → `reclaimRewards`; DEFERRED → no mint, no snapshot |

**Hypotheses**

- [ ] **H-A1:** Present POI with SUBGRAPH_DENIED then deny lifted — double snapshot?
- [ ] **H-A2:** Resize stale allocation reclaims pending — race with POI collect
- [ ] **H-A3:** Over-allocation auto-downsize to 0 after POI — reward accounting

---

## HorizonStaking

**Source:** `packages/horizon/contracts/staking/HorizonStaking.sol`

| Item | Detail |
|------|--------|
| Economic security | Provisions locked for verifiers; slashable |
| Thaw flow | thaw → wait thawingPeriod → deprovision/reprovision |

**Hypotheses (from OZ audit)**

- [ ] **H-S1 (M-01):** Thaw + deprovision faster than dispute — **CLOSED Phase 6** (maxThawingPeriod=28d live)
- [ ] **H-S2 (L-17):** Re-thaw resets `thawingUntil` — **CLOSED Phase 6** (no evasion path)
- [ ] **H-S3 (L-18):** Verifier collusion + slash to withdraw instantly — **CLOSED Phase 6** (arbitrator-only)
- [ ] **H-S4 (L-03):** Partial slash share inflation — reviewed in slash tests; rounding bounded

---

## Findings log

| Date | ID | Contract | Hypothesis | Status |
|------|-----|----------|------------|--------|
| — | — | — | — | — |

See also: `notes/audit-findings.md`, `notes/hunt-log.md`
