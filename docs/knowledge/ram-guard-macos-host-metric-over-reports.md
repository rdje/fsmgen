---
id: ram-guard-macos-host-metric-over-reports
title: RAM guard host-memory metric over-reports on macOS (counts reclaimable cache as used)
answers:
  - "why does run_with_ram_guard.sh trip at 88% on a healthy macOS host?"
  - "why does the RAM guard kill fsmgen/prove before it runs?"
  - "is the RAM guard's host memory near-100% real memory pressure on macOS?"
  - "why can't t/248 run under the RAM guard on macOS?"
  - "what does the RAM guard count as available memory?"
date: 2026-07-12
status: current
tags: [infra, ram-guard, macos, memory, continuity]
evidence: scripts/run_with_ram_guard.sh; docs/tasks/AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT.md; docs/tasks/AGENT-RUNTIME-RAM-GUARD.md; MEMORY.md
reverify: "TOTAL=$(sysctl -n hw.memsize); vm_stat | awk -v t=$TOTAL '/page size of/{ps=$8}/^Pages free:/{gsub(/[^0-9]/,\"\",$3);f=$3}/^Pages speculative:/{gsub(/[^0-9]/,\"\",$3);s=$3}/^Pages inactive:/{gsub(/[^0-9]/,\"\",$3);i=$3}/^Pages purgeable:/{gsub(/[^0-9]/,\"\",$3);p=$3}END{printf \"guard_used=%.1f%% real_used=%.1f%%\\n\",(t-(f+s)*ps)*100/t,(t-(f+s+i+p)*ps)*100/t}'; memory_pressure | grep -i 'free percentage'"
---

`scripts/run_with_ram_guard.sh` computes host memory usage as
`used = total - (Pages free + Pages speculative)`. On macOS, `Pages free` is
kept near-zero by design because idle RAM is used as file cache in the
`inactive` (and `purgeable`) buckets, which are reclaimed on demand and are not
real pressure. Because the formula excludes `inactive`/`purgeable`, it reports
~90%+ "used" on a healthy host and trips the default `88%` cutoff, killing any
guarded command (exit 137) before it runs.

Measured 2026-07-12 on a 24 GiB host: guard metric `90.5%` used vs approx real
`54.6%` used (adding `inactive` + `purgeable` to available); `memory_pressure`
reported `75%` free. Earlier the same session the guard reported `99.4-99.5%`
and terminated `./bin/fsmgen`.

Practical rule until fixed: run lightweight single-file `fsmgen` commands
directly (COMMIT.md scopes the guard to broad/heavy runs); the heavy
`t/248-regression-corpus-accounting.t` gate has no working guarded path on
macOS. Do not misread the guard's ~90-99% as real memory pressure, and do not
"bypass the cutoff" as if the host were genuinely full. The correction is
tracked by `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT` (proposed; needs
director approval since it changes a safety guard). The descendant-RSS cutoff
(4096 MiB) is unaffected and correct.
