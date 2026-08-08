---
id: ram-guard-macos-host-metric-over-reports
title: RAM guard host-memory metric over-reports on macOS (counts reclaimable cache as used)
answers:
  - "why does run_with_ram_guard.sh trip at 88% on a healthy macOS host?"
  - "why does the RAM guard kill fsmgen/prove before it runs?"
  - "is the RAM guard's host memory near-100% real memory pressure on macOS?"
  - "why can't t/248 run under the RAM guard on macOS?"
  - "what does the RAM guard count as available memory?"
  - "how should an agent measure macOS RAM usage accurately?"
  - "what is the difference between Stats RAM usage and macOS memory pressure?"
date: 2026-08-08
status: current
tags: [infra, ram-guard, macos, memory, continuity]
evidence: scripts/run_with_ram_guard.sh; t/1595-agent-runtime-ram-guard-macos-metric.t; docs/tasks/AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT.md; MEMORY.md; https://github.com/exelban/stats/blob/master/Modules/RAM/readers.swift; https://support.apple.com/en-lamr/guide/activity-monitor/actmntr1004/mac
reverify: "FSMGEN_TOTAL_BYTES=$(sysctl -n hw.memsize); vm_stat | awk -v t=$FSMGEN_TOTAL_BYTES '/page size of/{ps=$8}/^Pages active:/{gsub(/[^0-9]/,\"\",$3);a=$3}/^Pages inactive:/{gsub(/[^0-9]/,\"\",$3);i=$3}/^Pages speculative:/{gsub(/[^0-9]/,\"\",$3);s=$3}/^Pages wired down:/{gsub(/[^0-9]/,\"\",$4);w=$4}/^Pages purgeable:/{gsub(/[^0-9]/,\"\",$3);p=$3}/^File-backed pages:/{gsub(/[^0-9]/,\"\",$3);e=$3}/^Pages occupied by compressor:/{gsub(/[^0-9]/,\"\",$5);c=$5}END{printf \"stats_used=%.1f%%\\n\",(a+i+s+w+c-p-e)*ps*100/t}'; sysctl -n kern.memorystatus_vm_pressure_level; memory_pressure -Q"
---

Before 2026-08-08, `scripts/run_with_ram_guard.sh` computed host usage as
`used = total - (Pages free + Pages speculative)`. On macOS, `Pages free` is
kept near-zero by design because idle RAM is used as file cache in the
`inactive` (and `purgeable`) buckets, which are reclaimed on demand and are not
real pressure. Because the formula excludes `inactive`/`purgeable`, it reports
~90%+ "used" on a healthy host and trips the default `88%` cutoff, killing any
guarded command (exit 137) before it runs.

The earlier `free + speculative + inactive + purgeable` estimate was also only
an approximation and must not be reported as canonical usage. Stats 3.0.9
computes used RAM from Mach VM counters as:

```text
used = active + inactive + speculative + wired + compressed
       - purgeable - external
used_pct = used / physical_memory * 100
```

For `vm_stat`, `Pages occupied by compressor` supplies `compressed` and
`File-backed pages` supplies the compatible external/file-backed count. A
2026-07-29 sample calculated 49.9% while the director's rapidly changing Stats
display was about 47%; later samples moved to 54.4% and 59.2%. The matching
source is Stats' `Modules/RAM/readers.swift`.

Capacity and safety are separate readings. Report the Stats-compatible
percentage for capacity, and report
`kern.memorystatus_vm_pressure_level` independently as normal (`1`), warning
(`2`), or critical (`4`). Apple's Activity Monitor documentation describes
memory pressure as a combined efficiency signal influenced by free memory,
swap rate, wired memory, and cached files; `memory_pressure -Q`'s free
percentage is therefore not the inverse of Stats usage. Treat swap *movement*
over a sampling interval as useful supporting evidence, not accumulated swap
occupancy as immediate pressure.

Since 2026-08-08 the guard uses that Stats-compatible capacity formula on
Darwin, retains the `88%` host and `4096 MiB` descendant cutoffs, and fails
closed when any required counter is missing or invalid. `memory_pressure` is
not a capacity fallback because it lacks the file-backed counter. Fixture
tests prove 55% pass, 96% trip, and malformed-input rejection; a real-host
sample matched the independent formula at 31.8-31.9%. A complete `t/296` retry
then passed the corrected host check but correctly tripped when one descendant
reached 4560.5 MiB, exposing a separate worker-memory issue rather than another
host-metric false positive.
