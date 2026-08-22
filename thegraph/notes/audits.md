# The Graph — Audit Summary

Source: audit PDFs in cloned `src/contracts` repo.
**Any unfixed issue mentioned in these reports is OUT OF SCOPE.**

Use this file as a reading queue — start with the newest audits first.

## `contracts/packages/horizon/audits`

- `2024-06-OZ-horizon.pdf`
- `2024-11-Trust-horizon.pdf`
- `2025-03-OZ-pre audit assessment.pdf`
- `2025-05-OZ-The Graph Horizon Audit.pdf`
- `2025-06-Indexing-Payments.pdf`
- `The Graph Horizon Missed Issues Initial Report.pdf`

## `contracts/packages/issuance/audits`

- `2025-11-17_Graph_PR1242_1243_v02.pdf`
- `2025-12-13_Graph_EligibilityOracle_v02.pdf`
- `2025-12-28_Graph_IssuanceAllocator_v03.pdf`
- `2026-02-15_Graph_PR1279_v02.pdf`
- `2026-05-09_Graph_PR1334_v05.pdf`
- `2026-06-05_Graph_PR1342_v06.pdf`

## `contracts/packages/token-distribution/audits`

- `2020-11-graph-token-distribution.pdf`

## Priority reading order (for hunting)

1. **Horizon (2025–2026)** — current L2 staking/rewards architecture
2. **Issuance (2025–2026)** — new token issuance / eligibility oracle
3. **Legacy contracts audits (OpenZeppelin/Trust/ConsenSys)** — staking, rewards, bridge, curation
4. **Token distribution** — vesting (recent Immunefi medium: GHSA-qx35-rc5x-x39r, Mar 2026)

## Known recent fix (do NOT report)

- **Vesting double-spend** (Medium, Mar 2026): revocable vesting allowed withdrawn tokens to be reused in protocol. Fixed in token-distribution v3.0.0.
  - Advisory: https://github.com/graphprotocol/contracts/security/advisories/GHSA-qx35-rc5x-x39r

## Hunt focus after reading audits

- Reward accounting across epoch boundaries
- Bridge escrow / L1↔L2 token gateway mismatches
- Proxy upgrade + initializer replay
- Curation bonding curve edge cases
- DisputeManager slashing logic
- Billing connector fee/refund paths
