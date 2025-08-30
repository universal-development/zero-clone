#!/usr/bin/env bash
set -euo pipefail

pass_count=0
fail_count=0

_ts() { date +%H:%M:%S; }

ok() {
  printf "[%s] ok - %s\n" "$(_ts)" "$*"
  pass_count=$((pass_count+1))
}

fail() {
  printf "[%s] not ok - %s\n" "$(_ts)" "$*" >&2
  fail_count=$((fail_count+1))
}

assert_eq() {
  local a="$1" b="$2" msg="${3:-}"
  if [[ "$a" == "$b" ]]; then ok "${msg:-assert_eq}"; else fail "${msg:-assert_eq} (got='$a' expected='$b')"; fi
}

assert_contains() {
  local haystack="$1" needle="$2" msg="${3:-}"
  if grep -q -- "$needle" <<<"$haystack"; then ok "${msg:-assert_contains}"; else fail "${msg:-assert_contains} (missing '$needle')"; fi
}

summary() {
  printf "\nPassed: %d, Failed: %d\n" "$pass_count" "$fail_count"
  [[ "$fail_count" -eq 0 ]]
}

