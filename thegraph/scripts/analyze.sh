#!/usr/bin/env bash
# Static analysis helpers for The Graph hunt
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONTRACTS="$ROOT/src/contracts/packages"
export PATH="${HOME}/.foundry/bin:${PATH}"

# Load nvm for Graph monorepo (Node 24)
export NVM_DIR="${HOME}/.nvm"
# shellcheck disable=SC1090
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && nvm use 24 >/dev/null 2>&1 || true

# Load RPC URLs
if [ -f "$ROOT/.env" ]; then set -a; source "$ROOT/.env"; set +a; fi

echo "== The Graph Bug Hunt — Analysis =="
echo "Root: $ROOT"
echo

echo ">> Fork tests (thegraph/)"
(cd "$ROOT" && forge test --match-path test/poc/ -vv 2>&1 | tail -12)
echo

if command -v slither >/dev/null 2>&1 && [ -d "$CONTRACTS/horizon/node_modules" ]; then
  echo ">> Slither: horizon (summary)"
  (cd "$CONTRACTS/horizon" && slither . --filter-paths "test|mock" --exclude-dependencies 2>/dev/null | head -30) || echo "Slither run failed"
else
  echo ">> Slither: skipped (install horizon deps first)"
fi
echo

if [ -f "$CONTRACTS/contracts/artifacts/contracts/rewards/RewardsManager.sol/RewardsManager.json" ]; then
  echo ">> Real RewardsManager integration test"
  (cd "$CONTRACTS/testing" && forge test --match-contract IndexingRewardsCollectionTest -vv 2>&1 | tail -8)
else
  echo ">> Build contracts first: cd $CONTRACTS/contracts && pnpm compile"
fi
echo

echo ">> Scope addresses: $(grep -c '^| \`0x' "$ROOT/notes/scope.md" || echo 0)"
