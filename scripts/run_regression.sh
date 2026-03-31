#!/usr/bin/env bash
#
# run_regression.sh - Run tests from a regression list file.
# Usage: ./scripts/run_regression.sh regressions/<list>.list
#

set -e

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <regression_list_file>" >&2
    echo "Example: $0 regressions/fetch_stage.list" >&2
    exit 1
fi

REGRESSION_LIST="$1"

if [[ ! -f "$REGRESSION_LIST" ]]; then
    echo "Error: Regression list file not found: $REGRESSION_LIST" >&2
    exit 1
fi
# Resolve to absolute path so it remains valid after we cd to repo root
REGRESSION_LIST="$(cd "$(dirname "$REGRESSION_LIST")" && pwd)/$(basename "$REGRESSION_LIST")"

# Run from repository root (parent of scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

# Timestamped results directory: YYYYMMDD_HHMMSS
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
RESULTS_DIR="results/${TIMESTAMP}"
mkdir -p "$RESULTS_DIR"

# Collect test names (skip empty lines and lines starting with #)
TESTS=()
while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"   # strip trailing comment
    line="${line#"${line%%[![:space:]]*}"}"   # trim leading whitespace
    line="${line%"${line##*[![:space:]]}"}"  # trim trailing whitespace
    if [[ -n "$line" ]]; then
        TESTS+=("$line")
    fi
done < "$REGRESSION_LIST"

if [[ ${#TESTS[@]} -eq 0 ]]; then
    echo "No tests found in $REGRESSION_LIST"
    exit 0
fi

PASS_COUNT=0
FAIL_COUNT=0
SUMMARY_LINES=()

# Derive the stage for a test by finding which tests/<stage>/ directory contains it.
# Handles multi-word stages like decode_slice (progressively tries longer prefixes).
derive_stage() {
    local test_name="$1"
    local IFS='_'
    local parts=($test_name)
    local candidate=""
    for part in "${parts[@]}"; do
        if [[ -z "$candidate" ]]; then
            candidate="$part"
        else
            candidate="${candidate}_${part}"
        fi
        if [[ -f "tests/${candidate}/${test_name}.sv" ]]; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

# Ensure all tests in this list target the same stage and use that stage
# for the one-time compile/elab snapshot.
FIRST_TEST="${TESTS[0]}"
STAGE_PREFIX="$(derive_stage "$FIRST_TEST")" || {
    echo "Error: Cannot determine stage for test '$FIRST_TEST' (no matching tests/<stage>/ directory)." >&2
    exit 1
}

for test_name in "${TESTS[@]}"; do
    test_stage="$(derive_stage "$test_name")" || {
        echo "Error: Cannot determine stage for test '$test_name'." >&2
        exit 1
    }
    if [[ "$test_stage" != "$STAGE_PREFIX" ]]; then
        echo "Error: Mixed stage tests in one regression list are not supported." >&2
        echo "  Found '$test_name' (stage '$test_stage') but expected stage '$STAGE_PREFIX'." >&2
        exit 1
    fi
done

# Build shared simulation snapshot once for this stage, then run tests via +TEST.
build_log="${RESULTS_DIR}/build.log"
echo "Compiling/elaborating shared snapshot for stage '${STAGE_PREFIX}'..."
make compile STAGE="${STAGE_PREFIX}" TEST="${FIRST_TEST}" > "$build_log" 2>&1
make elab STAGE="${STAGE_PREFIX}" TEST="${FIRST_TEST}" >> "$build_log" 2>&1

for test_name in "${TESTS[@]}"; do
    test_dir="${RESULTS_DIR}/${test_name}"
    mkdir -p "$test_dir"
    sim_log="${test_dir}/sim.log"

    echo -n "Running ${test_name}... "
    make run STAGE="${STAGE_PREFIX}" TEST="$test_name" > "$sim_log" 2>&1 || true

    # Move waveform if present (ignore errors if missing)
    if [[ -f waveform.vcd ]]; then
        mv waveform.vcd "${test_dir}/waveform.vcd"
    fi

    # Pass if sim.log contains "TEST PASSED"
    if grep -q "TEST PASSED" "$sim_log" 2>/dev/null; then
        echo "PASS"
        ((PASS_COUNT++)) || true
        SUMMARY_LINES+=("${test_name} PASS")
    else
        echo "FAIL"
        ((FAIL_COUNT++)) || true
        SUMMARY_LINES+=("${test_name} FAIL")
    fi
done

# Regression summary
echo ""
echo "REGRESSION SUMMARY"
echo "------------------"
for line in "${SUMMARY_LINES[@]}"; do
    echo "$line"
done
echo ""
echo "PASS: ${PASS_COUNT}"
echo "FAIL: ${FAIL_COUNT}"

# Save summary to results directory
SUMMARY_FILE="${RESULTS_DIR}/summary.txt"
{
    echo "REGRESSION SUMMARY"
    echo "------------------"
    for line in "${SUMMARY_LINES[@]}"; do
        echo "$line"
    done
    echo ""
    echo "PASS: ${PASS_COUNT}"
    echo "FAIL: ${FAIL_COUNT}"
} > "$SUMMARY_FILE"

echo ""
echo "Results saved to: ${RESULTS_DIR}"

# Exit with failure if any test failed
[[ $FAIL_COUNT -eq 0 ]]
