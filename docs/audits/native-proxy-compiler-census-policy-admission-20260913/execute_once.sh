#!/bin/bash
# Invoke under the repository RAM guard. This is executable procedure source;
# do not invoke before the separate execution leaf and one-use permit exist.
set -uC
profile_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
cd "$profile_root" || exit 1
profile_output='.artifacts/logs/native-proxy-compiler-census-policy-20260913'
env -i PATH=/usr/bin:/bin LC_ALL=C LANG=C TMPDIR="$profile_root/.artifacts/tmp" \
    /usr/bin/perl docs/audits/native-proxy-compiler-census-policy-admission-20260913/compile_profile.pl --execute-admitted \
    > "$profile_output/runner.stdout" 2> "$profile_output/runner.stderr"
profile_exit=$?
printf '%s\n' "$profile_exit" > "$profile_output/runner.exit"
exit "$profile_exit"
