#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$BASE_DIR/../.." && pwd)"

# Generate list.txt with absolute paths to precreated sources
cat >"$BASE_DIR/.zero-clone/list.txt" <<EOF
$BASE_DIR/source/alpha a
$BASE_DIR/source/beta
EOF

# Run zero-clone for this base
echo "Running zero-clone for base: $BASE_DIR"
bash "$ROOT_DIR/bin/zero-clone" --yes "$BASE_DIR"

echo "Done. See $BASE_DIR/clone and $BASE_DIR/.zero-clone/logs."
