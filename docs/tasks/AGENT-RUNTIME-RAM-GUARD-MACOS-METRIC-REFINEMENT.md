# AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT: RAM guard host-memory metric over-reports on macOS

## Metadata

- Tree ID: `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT`
- Status: `active`
- Roadmap lane: `infra/continuity`
- Created: `2026-07-12`
- Last updated: `2026-08-08`
- Owner: repo-local workflow

## Goal

Make `scripts/run_with_ram_guard.sh`'s macOS host-capacity metric use the same
Mach VM counter model as the maintained Stats reference, so the guard stops
runaway commands without treating reclaimable file-backed pages as occupied
capacity.

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

- The macOS branch of `host_memory_pct()` computes Stats-compatible occupied
  capacity from `active + inactive + speculative + wired + compressed -
  purgeable - file_backed`, rather than treating `memory_pressure -Q` as an
  inverse capacity reading.
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
  Status: `active`
  Goal: `Correct the macOS host-memory pressure metric in the RAM guard.`
  Children: `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT.1, AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT.2`

- ID: `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT.1`
  Status: `done`
  Goal: `Select the corrected macOS availability formula and its validation approach before changing the guard.`
  Acceptance: `Choose the canonical capacity formula, exact vm_stat/sysctl fields, trip-behavior test plan for healthy and pressured hosts, and MEMORY.md/COMMIT.md sync contract, with director authority for the safety change.`
  Verification: `passed: selected the Stats 3.0.9 Mach-counter formula already captured by the canonical fact card; retained the 88% host and 4096-MiB descendant thresholds; specified fixture-driven healthy/trip/malformed-input tests; director delegated the signoff choice on 2026-08-08.`
  Commit: `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT.1: select macOS capacity metric`

- ID: `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT.2`
  Status: `active`
  Goal: `Implement and qualify the selected Stats-compatible macOS capacity metric.`
  Acceptance: `The guard parses every required vm_stat field, fails closed on incomplete or invalid samples, preserves Linux and descendant-RSS behavior, passes fixture-driven healthy and forced-pressure execution tests, reports a healthy real-host sample below the unchanged cutoff, and synchronizes COMMIT.md, MEMORY.md, and the canonical fact card.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT.2` | `active` | Implement the approved capacity contract before rerunning the blocked guarded parent test. |

## Decisions

- `2026-07-12`: Filed as `proposed` (not PNT-eligible). The guard is a safety
  mechanism; correcting its trip metric could change when it protects against a
  real OOM, so it needs the director's explicit go-ahead before implementation.
- `2026-08-08`: The director delegated the safety-metric decision to the agent
  under a SOTA/signoff-quality mandate. Selected the Stats 3.0.9 counter model:
  `active + inactive + speculative + wired + compressed - purgeable -
  file_backed`, divided by physical memory. This is preferable to the earlier
  additive-availability approximation because the reference model explicitly
  accounts for compressed and external/file-backed pages without treating
  `memory_pressure -Q` as inverse capacity.
- `2026-08-08`: Keep the established `88%` host-capacity and `4096 MiB`
  descendant-RSS cutoffs. This slice corrects the measured quantity; changing
  thresholds at the same time would confound the safety qualification.
- `2026-08-08`: Validate through deterministic fake macOS command fixtures:
  a healthy sample must let the child exit normally, a high-occupancy sample
  must terminate it with the guard's 137 result, and missing/invalid required
  counters must fail closed. Then run one real-host sample and the previously
  blocked complete `t/296-regression-corpus-supported-behavior.t` parent.

## Open Questions

- None for the implementation frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-07-12` | `finding` | `sysctl hw.memsize`; `vm_stat`; `memory_pressure`; guard-formula recomputation | `confirmed`: guard reports 90.5% used vs ~54.6% real / 75% free |
| `2026-08-08` | `.1` | canonical Knowledge Map fact; Stats 3.0.9 formula; director delegation; task-tree/doctrine baseline | `passed`: implementation contract selected with thresholds unchanged |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `finding` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.771` closeout | Finding surfaced and this proposed owner filed. |
| `.1` | `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT.1: select macOS capacity metric` | Activated the tree and fixed the implementation/qualification contract. |

## Changelog

- `2026-07-12`: Created proposed task tree from the RAM-guard macOS-metric
  finding root-caused during `IAL2-FEATURE-COMPLETENESS-FRONTIER.771`.
- `2026-08-08`: Activated under delegated director authority; completed metric
  selection `.1` and opened implementation/qualification leaf `.2`.
