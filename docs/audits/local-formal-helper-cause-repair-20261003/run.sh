#!/bin/bash
set -u
B=docs/audits/local-formal-helper-cause-repair-20261003
run() {
    name=$1
    expected=$2
    shift 2
    "$@" > "$B/$name.txt" 2>&1
    actual=$?
    echo "$actual" > "$B/$name.status"
    echo "$name: status $actual (expected $expected)"
    test "$actual" -eq "$expected"
}
run current 0 env FSMGEN_LOCAL_FORMAL_ORIGIN_CAPTURE="$B/products" FSMGEN_LOCAL_FORMAL_CAUSE_CAPTURE="$B/current-causes.json" prove -Iperl -It/lib t/2052-isf-local-formal-origin-authority.t t/2055-isf-local-formal-helper-diagnostic-causes.t || exit 1
run prior-helper-red 1 env FSMGEN_LOCAL_FORMAL_CAUSE_PRIOR_HELPER=1 FSMGEN_LOCAL_FORMAL_CAUSE_CAPTURE="$B/prior-causes.json" prove -v -Iperl -It/lib t/2055-isf-local-formal-helper-diagnostic-causes.t || exit 1
run full-stack-red 1 env FSMGEN_FORMAL_DIAGNOSTIC_FULL_STACK=1 FSMGEN_LOCAL_FORMAL_ORIGIN_CAPTURE="$B/full-stack-products" prove -Iperl -It/lib t/2052-isf-local-formal-origin-authority.t || exit 1
run source-bypass-red 1 env FSMGEN_LOCAL_FORMAL_ORIGIN_CLASS=FSM::Test::LocalFormalOriginAuthority::Bypass FSMGEN_LOCAL_FORMAL_ORIGIN_CAPTURE="$B/bypass-products" prove -Iperl -It/lib t/2052-isf-local-formal-origin-authority.t || exit 1
