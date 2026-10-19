#!/usr/bin/env bash
# Fails the job if any step recorded by step.sh failed.
set -u
failed=0
for f in "${CI_LOG_DIR:-ci-logs}"/*.status; do
  [ -e "$f" ] || continue
  read -r code _ < "$f"
  if [ "$code" != 0 ]; then echo "FAILED: $(basename "$f" .status)"; failed=1; fi
done
exit $failed
