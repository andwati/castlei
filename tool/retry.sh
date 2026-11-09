#!/usr/bin/env bash
# Runs a command up to N times with a growing pause, for steps that download
# things from GitHub or Maven during the build (those occasionally return 504).
#   tool/retry.sh <attempts> <base-delay-seconds> <command> [args...]
set -u
attempts=$1; delay=$2; shift 2
for i in $(seq 1 "$attempts"); do
  "$@" && exit 0
  status=$?
  echo "::warning::attempt $i/$attempts failed (exit $status): $*"
  [ "$i" -lt "$attempts" ] && sleep $((delay * i))
done
exit 1
