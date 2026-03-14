#!/usr/bin/env bash

set -e

LIST_FILE="regressions/fetch_stage.list"
SUITE="fetch_stage"

if [ ! -f "$LIST_FILE" ]; then
  echo "Regression list not found: $LIST_FILE"
  exit 1
fi

while IFS= read -r test || [ -n "$test" ]; do
  # Skip empty lines and comments
  if [ -z "$test" ] || [[ "$test" =~ ^# ]]; then
    continue
  fi

  echo "Running test: $test"

  # Clean previous build artifacts
  make clean >/dev/null 2>&1 || true

  LOG_DIR="results/${SUITE}/${test}"
  mkdir -p "$LOG_DIR"
  LOG_FILE="${LOG_DIR}/sim.log"

  if make TEST="$test" >"$LOG_FILE" 2>&1; then
    echo "Test $test: PASS"
  else
    echo "Test $test: FAIL (see $LOG_FILE)"
  fi

done < "$LIST_FILE"

