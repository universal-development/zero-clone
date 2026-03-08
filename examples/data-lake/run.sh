#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$BASE_DIR/../.." && pwd)"
LAKE="$BASE_DIR/lake"

# Generate list.txt with absolute paths (simulating multiple remotes)
cat >"$BASE_DIR/.zero-clone/list.txt" <<EOF
$BASE_DIR/source-a/dataset1 dataset1
$BASE_DIR/source-b/dataset2 dataset2
EOF

echo "Running zero-clone in data lake mode (--dest $LAKE)"
bash "$ROOT_DIR/bin/zero-clone" --yes --dest "$LAKE" "$BASE_DIR"

echo ""
echo "Lake contents:"
find "$LAKE" -type f | sort
