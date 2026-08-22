# L-07 Full-Stack Profit Attempt — CLOSED

**Date:** 2026-08-22  
**Result:** No unprivileged profit path — **do not submit**

## Hypothesis

After indexing-fee collect locks `feesProvisionTracker`, a slash during the dispute window leaves the tracker unchanged (OZ L-07). Attacker or indexer might:
- Collect fees twice backed by the same slashed stake, or
- Extract net GRT beyond intended dispute economics.

## PoC

`src/contracts/packages/testing/test/integration/L07FullStackProfit.t.sol`

```bash
cd src/contracts/packages/testing
forge test --match-contract L07FullStackProfitTest -vv
```

## Flow tested

1. Real stack: RAM → RecurringCollector → SubgraphService indexing-fee collect (locks stake)
2. Fisherman creates indexing-fee dispute; arbitrator slashes 1000 GRT
3. **Confirmed:** `feesProvisionTracker` unchanged after slash (L-07)
4. Second collect before `releaseStake` — fails or returns 0 (no double fee extract)
5. After dispute period + `releaseStake` — tracker cleared; third collect succeeds normally
6. **Indexer net ≈ fee total minus protocol cut** (4455 vs 4500 GRT) — no unexplained mint

## Verdict

- L-07 is real **accounting desync** (tracker vs provision after slash)
- **No Immunefi-submit-ready exploit:** grief/capacity blocking only, not protocol drain
- **OOS:** listed in OpenZeppelin Horizon audit (partial fix)

## Recommendation

**Shift to another project** for bounty hunting. The Graph in-scope surface (Phases 1–13) is heavily audited with 622+ issuance tests and extensive integration coverage.
