#!/usr/bin/env bash
# Runs one CI step, keeping its output and exit code for the results report.
# Never fails by itself; tools/ci/finish.sh fails the job at the end so every
# step runs and gets reported.
#   tools/ci/step.sh <name> <command...>
set -u
name="$1"; shift
mkdir -p "${CI_LOG_DIR:-ci-logs}"
log="${CI_LOG_DIR:-ci-logs}/${name}.log"
start=$(date +%s)
echo "::group::${name}"
bash -o pipefail -c "$*" 2>&1 | tee "$log"
code=${PIPESTATUS[0]}
echo "::endgroup::"
echo "$code $(( $(date +%s) - start ))" > "${CI_LOG_DIR:-ci-logs}/${name}.status"
if [ "$code" != 0 ]; then echo "::error title=${name}::step failed with exit code ${code}"; fi
exit 0
