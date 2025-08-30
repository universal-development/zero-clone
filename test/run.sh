#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/test/helpers.sh"

run_zero_clone() {
  bash "$ROOT_DIR/bin/zero-clone" "$@"
}

with_tmp_sample() {
  local tmp
  tmp="$(mktemp -d)"
  cp -a "$ROOT_DIR/examples/sample-project" "$tmp/"
  echo "$tmp/sample-project"
}

test_help() {
  local out
  if out=$(bash "$ROOT_DIR/bin/zero-clone" --help); then
    assert_contains "$out" "Usage: zero-clone" "help prints usage"
  else
    fail "help command failed"
  fi
}

test_no_bases_found() {
  local tmp
  tmp="$(mktemp -d)"
  set +e
  local out rc
  out=$(run_zero_clone "$tmp" 2>&1)
  rc=$?
  set -e
  assert_eq "$rc" 1 "no bases returns exit 1"
}

test_runs_with_os_rclone() {
  local base
  base=$(with_tmp_sample)
  # Prepare local source data and rewrite list to absolute local paths
  mkdir -p "$base/src/alpha" "$base/src/beta"
  echo "one" >"$base/src/alpha/file1.txt"
  echo "two" >"$base/src/beta/file2.txt"
  cat >"$base/.zero-clone/list.txt" <<EOF
$base/src/alpha a
$base/src/beta
EOF
  set +e
  local rc out
  out=$(run_zero_clone --yes "$base" 2>&1)
  rc=$?
  set -e
  assert_eq "$rc" 0 "zero-clone run exit 0"
  # Logs directory should exist and have at least two logs (two jobs in list.txt)
  local logs_dir="$base/.zero-clone/logs"
  local count=0
  if [[ -d "$logs_dir" ]]; then
    count=$(find "$logs_dir" -type f -name '*.log' | wc -l | awk '{print $1}')
  fi
  [[ "$count" -ge 2 ]] && ok "created per-job log files" || fail "expected >=2 log files, got $count"
  # Verify files synced to clone/
  [[ -f "$base/clone/a/file1.txt" ]] && ok "alpha synced" || fail "alpha not synced"
  [[ -f "$base/clone/beta/file2.txt" ]] && ok "beta synced" || fail "beta not synced"
}

main() {
  # Ensure mock is executable
  chmod +x "$ROOT_DIR/bin/zero-clone" || true

  test_help
  test_no_bases_found
  if command -v rclone >/dev/null 2>&1; then
    test_runs_with_os_rclone
  else
    ok "rclone not found; skipping OS rclone tests"
  fi

  if summary; then
    echo "All tests passed"
    exit 0
  else
    echo "Some tests failed" >&2
    exit 1
  fi
}

main "$@"
