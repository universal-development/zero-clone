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

test_zero_clone_dir_env() {
  local base
  base=$(with_tmp_sample)
  mkdir -p "$base/src/alpha"
  echo "env-var-data" >"$base/src/alpha/file1.txt"
  cat >"$base/.zero-clone/list.txt" <<EOF
$base/src/alpha a
EOF
  set +e
  local rc out
  out=$(ZERO_CLONE_DIR=envdata run_zero_clone --yes "$base" 2>&1)
  rc=$?
  set -e
  assert_eq "$rc" 0 "ZERO_CLONE_DIR env exit 0"
  [[ -f "$base/envdata/a/file1.txt" ]] && ok "file synced via ZERO_CLONE_DIR env var" || fail "file not in ZERO_CLONE_DIR dir"
  [[ ! -d "$base/clone" ]] && ok "base/clone not created with ZERO_CLONE_DIR" || fail "base/clone should not exist with ZERO_CLONE_DIR"
}

test_init_sh() {
  local base
  base=$(with_tmp_sample)
  mkdir -p "$base/src/alpha"
  echo "init-sh-data" >"$base/src/alpha/file1.txt"
  cat >"$base/.zero-clone/list.txt" <<EOF
$base/src/alpha a
EOF
  local workdir
  workdir="$(mktemp -d)"
  cat >"$workdir/init.sh" <<'EOF'
export ZERO_CLONE_DIR=mydata
EOF
  set +e
  local rc out
  out=$(cd "$workdir" && bash "$ROOT_DIR/bin/zero-clone" --yes "$base" 2>&1)
  rc=$?
  set -e
  assert_eq "$rc" 0 "init.sh exit 0"
  [[ -f "$base/mydata/a/file1.txt" ]] && ok "file synced via init.sh ZERO_CLONE_DIR" || fail "file not in init.sh ZERO_CLONE_DIR dir"
  [[ ! -d "$base/clone" ]] && ok "base/clone not created with init.sh" || fail "base/clone should not exist with init.sh"
}

test_clone_dir_flag() {
  local base
  base=$(with_tmp_sample)
  mkdir -p "$base/src/alpha"
  echo "clone-dir-data" >"$base/src/alpha/file1.txt"
  cat >"$base/.zero-clone/list.txt" <<EOF
$base/src/alpha a
EOF
  set +e
  local rc out
  out=$(run_zero_clone --yes --clone-dir data "$base" 2>&1)
  rc=$?
  set -e
  assert_eq "$rc" 0 "clone-dir flag exit 0"
  [[ -f "$base/data/a/file1.txt" ]] && ok "file synced to custom clone dir" || fail "file not in custom clone dir"
  [[ ! -d "$base/clone" ]] && ok "base/clone not created with --clone-dir" || fail "base/clone should not exist with --clone-dir"
}

test_dest_flag() {
  local base
  base=$(with_tmp_sample)
  local lake
  lake="$(mktemp -d)"
  mkdir -p "$base/src/alpha"
  echo "lake-data" >"$base/src/alpha/file1.txt"
  cat >"$base/.zero-clone/list.txt" <<EOF
$base/src/alpha a
EOF
  set +e
  local rc out
  out=$(run_zero_clone --yes --dest "$lake" "$base" 2>&1)
  rc=$?
  set -e
  assert_eq "$rc" 0 "dest flag exit 0"
  [[ -f "$lake/a/file1.txt" ]] && ok "file synced to lake dir" || fail "file not in lake dir"
  [[ ! -d "$base/clone" ]] && ok "base/clone not created with --dest" || fail "base/clone should not exist with --dest"
}

test_multi_source_data_lake() {
  local base
  base=$(with_tmp_sample)
  local lake
  lake="$(mktemp -d)"
  mkdir -p "$base/src/alpha" "$base/src/beta"
  echo "from-alpha" >"$base/src/alpha/file1.txt"
  echo "from-beta" >"$base/src/beta/file2.txt"
  cat >"$base/.zero-clone/list.txt" <<EOF
$base/src/alpha data/alpha
$base/src/beta data/beta
EOF
  set +e
  local rc out
  out=$(run_zero_clone --yes --dest "$lake" "$base" 2>&1)
  rc=$?
  set -e
  assert_eq "$rc" 0 "multi-source lake exit 0"
  [[ -f "$lake/data/alpha/file1.txt" ]] && ok "alpha synced to lake" || fail "alpha not in lake"
  [[ -f "$lake/data/beta/file2.txt" ]] && ok "beta synced to lake" || fail "beta not in lake"
}

main() {
  # Ensure mock is executable
  chmod +x "$ROOT_DIR/bin/zero-clone" || true

  test_help
  test_no_bases_found
  if command -v rclone >/dev/null 2>&1; then
    test_runs_with_os_rclone
    test_zero_clone_dir_env
    test_init_sh
    test_clone_dir_flag
    test_dest_flag
    test_multi_source_data_lake
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
