#!/usr/bin/env bash
# Cold-start TTID, median of N runs (M8 budget: < 2000 ms, docs/ROADMAP.md).
#
# Usage: tool/perf/coldstart.sh [adb-device-id]
#   RUNS=7 tool/perf/coldstart.sh          # override run count
#
# Measure a RELEASE build (flutter build apk --release, installed) — debug
# and profile numbers do not represent what users feel.
set -euo pipefail

PKG=ir.miras
ACTIVITY="$PKG/.MainActivity"
RUNS="${RUNS:-5}"
DEVICE="${1:-}"
ADB=(adb)
[ -n "$DEVICE" ] && ADB=(adb -s "$DEVICE")

times=()
for i in $(seq "$RUNS"); do
  "${ADB[@]}" shell am force-stop "$PKG"
  sleep 2 # let the system settle so every run is genuinely cold
  total=$("${ADB[@]}" shell am start -S -W -n "$ACTIVITY" |
    awk -F': *' '/TotalTime/ {print $2}' | tr -d '\r')
  echo "run $i: ${total} ms"
  times+=("$total")
done

median=$(printf '%s\n' "${times[@]}" | sort -n | awk '{a[NR]=$1} END {print a[int((NR+1)/2)]}')
echo "----"
echo "median TTID over $RUNS cold starts: ${median} ms (budget: <2000 ms)"
echo "phase attribution: run in --profile and open DevTools timeline —"
echo "bootstrap spans are tagged miras.bootstrap.*"
