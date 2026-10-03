#!/bin/bash
set -u
B=docs/audits/formal-source-context-cause-repair-20261003
run() {
 name=$1
 expected=$2
 shift 2
 "$@" > "$B/$name.txt" 2>&1
 actual=$?
 echo "$actual" > "$B/$name.status"
 echo "$name: $actual (expected $expected)"
 test "$actual" -eq "$expected"
}
run bind 0 python3 "$B/bind.py" || exit 1
run current 0 env FSMGEN_SOURCE_CONTEXT_CAUSE_CAPTURE="$B/current-causes.json" prove -Iperl -It/lib t/1936-isf-formal-source-context.t t/2056-isf-formal-source-context-diagnostic-causes.t || exit 1
run ordinary 0 perl "$B/ordinary.pl" || exit 1
run prior-consumer-red 13 perl "$B/prior_probe.pl" || exit 1
run binding-bypass-red 1 perl "$B/bypass.pl" || exit 1
