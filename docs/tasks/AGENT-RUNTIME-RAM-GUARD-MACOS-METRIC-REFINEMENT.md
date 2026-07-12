# AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT: RAM guard host-memory metric over-reports on macOS

## Metadata

- Tree ID: `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT`
- Status: `proposed`
- Roadmap lane: `infra/continuity`
- Created: `2026-07-12`
- Last updated: `2026-07-12`
- Owner: repo-local workflow

## Goal

Make `scripts/run_with_ram_guard.sh`'s host-memory pressure metric reflect
genuinely unavailable memory on macOS, so the guard stops runaway commands
without tripping on reclaimable file-cache memory that macOS keeps in the
`inactive`/`purgeable` buckets by design.

This tree is **proposed, not PNT-eligible**: the guard is a safety mechanism,
so any change to its trip metric needs the director's explicit judgment before
implementation (it must not silently weaken protection against real
out-of-memory conditions).

## Background / Finding

Root-caused on 2026-07-12 during `IAL2-FEATURE-COMPLETENESS-FRONTIER.771`.

`scripts/run_with_ram_guard.sh` computes host usage as:

```text
available = (Pages free + Pages speculative) * page_size
used%     = (total - available) / total * 100
```

On macOS, `Pages free` is kept near-zero by design: idle RAM is used as file
cache and parked in the `inactive` bucket (plus `purgeable`), which is
reclaimed on demand and is **not** real memory pressure. Because the formula
excludes `inactive` and `purgeable`, it reports ~90%+ "used" on a healthy host.

Measured snapshot (24.0 GiB host, `page size 16384`):

```text
free=2.2G  speculative=0.2G  inactive=9.1G  purgeable=0.2G
active=7.5G  wired=3.4G  file_backed=8.2G  compressor=2.8G

GUARD metric  (avail = free+speculative)                 -> used = 90.5%
approx real   (avail = free+speculative+inactive+purgeable) -> used = 54.6%
memory_pressure headline                                 -> 75% free
```

Consequences:

- The default `88%` cutoff trips essentially always on this macOS host, so any
  command wrapped by the guard is killed (exit 137) before it runs. Earlier
  reverify runs this session saw the guard report `99.4-99.5%` and terminate
  `./bin/fsmgen` before it produced output.
- COMMIT.md requires broad/heavyweight Perl/`prove`/`fsmgen` commands (notably
  `t/248-regression-corpus-accounting.t`, which loads the whole corpus) to run
  under the guard. With the current metric that gate is effectively unrunnable
  locally on macOS.
- Prior sessions recorded this as "pre-existing host memory 99.6% against the
  88% cutoff; do not bypass" (see `IAL2-FEATURE-COMPLETENESS-FRONTIER.764` /
  MEMORY.md). That is a misdiagnosis: it is not high real memory, it is a wrong
  metric. Lightweight single-file `fsmgen` commands have therefore been run
  directly (COMMIT.md scopes the guard to broad/heavy runs), but the heavy gate
  has no working guarded path.

## Non-Goals

- Do not remove or disable the RAM guard.
- Do not change the descendant-RSS cutoff (4096 MiB), which is unaffected.
- Do not raise the host cutoff percentage as a workaround (that trades a wrong
  metric for a looser wrong metric).
- Do not change any FSMGen product behavior; this is infra/continuity only.

## Acceptance Criteria

- The macOS branch of `host_memory_pct()` counts reclaimable memory
  (`inactive` + `purgeable`, and any equivalently-reclaimable buckets) as
  available, so a healthy idle host reports pressure comparable to
  `memory_pressure` (tens of percent, not ~90%+).
- A genuine high-pressure condition (little free + little reclaimable, high
  wired/active/compressor) still trips the cutoff.
- The Linux `/proc/meminfo` branch (already using `MemAvailable`) and the
  descendant-RSS cutoff are unchanged.
- A focused test or documented manual verification demonstrates both the
  healthy-host (no trip) and simulated-pressure (trip) cases.
- MEMORY.md's RAM-guard blocker note and COMMIT.md guidance are updated to the
  corrected metric once shipped.

## Task Tree

- ID: `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT`
  Status: `proposed`
  Goal: `Correct the macOS host-memory pressure metric in the RAM guard.`
  Children: `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT.1`

- ID: `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT.1`
  Status: `pending`
  Goal: `Select the corrected macOS availability formula and its validation approach before changing the guard.`
  Acceptance: `Chosen reclaimable-bucket set (inactive/purgeable/speculative/free), the vm_stat/sysctl fields used, the trip-behavior test plan for healthy and pressured hosts, and the MEMORY.md/COMMIT.md sync, with the director's approval that the safety trade-off is acceptable.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT.1` | `pending` | Needs director approval to change a safety mechanism; proposed until then. |

## Decisions

- `2026-07-12`: Filed as `proposed` (not PNT-eligible). The guard is a safety
  mechanism; correcting its trip metric could change when it protects against a
  real OOM, so it needs the director's explicit go-ahead before implementation.

## Open Questions

- Which reclaimable buckets should count as available on macOS? At minimum
  `inactive` + `purgeable` alongside `free` + `speculative`; whether to also
  discount part of the compressor pool needs judgment.
- Should the default host cutoff (88%) be revisited once the metric is
  corrected, or left as-is against the corrected denominator?

## Blockers

- Director approval to modify the safety guard (see Decisions).

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-07-12` | `finding` | `sysctl hw.memsize`; `vm_stat`; `memory_pressure`; guard-formula recomputation | `confirmed`: guard reports 90.5% used vs ~54.6% real / 75% free |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `finding` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.771` closeout | Finding surfaced and this proposed owner filed. |

## Changelog

- `2026-07-12`: Created proposed task tree from the RAM-guard macOS-metric
  finding root-caused during `IAL2-FEATURE-COMPLETENESS-FRONTIER.771`.
