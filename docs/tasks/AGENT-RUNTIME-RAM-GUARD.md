# AGENT-RUNTIME-RAM-GUARD: Agent Process RAM Safety

## Metadata

- Tree ID: `AGENT-RUNTIME-RAM-GUARD`
- Status: `done`
- Roadmap lane: `infra/continuity`
- Created: `2026-06-21`
- Last updated: `2026-06-21`
- Owner: repo-local workflow

## Goal

Prevent agent-launched heavyweight local commands, especially broad
Perl/`prove`/`fsmgen` corpus runs, from pushing host RAM into the 90% danger
zone.

## Non-Goals

- Do not optimize the underlying Perl generator memory profile in this slice.
- Do not change supported corpus semantics, production code generation, or CI
  expectations.
- Do not make broad corpus runs mandatory when focused direct probes already
  cover a slice and the guard trips.

## Acceptance Criteria

- A reusable local wrapper exists for agent-launched heavyweight commands.
- The wrapper monitors host memory and descendant RSS, terminates the command
  tree before host RAM reaches 90%, and defaults below the danger zone.
- The workflow documents that future broad Perl/`prove`/`fsmgen` commands must
  use the wrapper or an equivalent active monitor.
- Focused validation proves the wrapper accepts a small command and kills a
  bounded high-RSS command.
- Task-tree, Memory, README, and commit workflow guidance are synced and the
  slice is committed per `COMMIT.md`.

## Task Tree

- ID: `AGENT-RUNTIME-RAM-GUARD`
  Status: `done`
  Goal: `Prevent agent-launched heavyweight local commands from exhausting host RAM.`
  Children: `AGENT-RUNTIME-RAM-GUARD.1`

- ID: `AGENT-RUNTIME-RAM-GUARD.1`
  Status: `done`
  Goal: `Add and document a RAM guard wrapper for heavyweight agent-launched local commands.`
  Acceptance: `Provide a wrapper with default host RAM cutoff below 90%, per-descendant RSS monitoring, process-tree termination, clear diagnostics, README/MEMORY/commit-workflow guidance, focused positive and kill-path validation, and standard continuity gates.`
  Verification: `Added scripts/run_with_ram_guard.sh with fail-closed process/RSS/host-memory inspection, default host cutoff 88%, default descendant RSS cutoff 4096 MiB, process-tree termination, and code 137 guard trips. README, COMMIT.md, MEMORY.md, task-tree index, and Knowledge Map fact card document the policy. Validation proved bash syntax, help text, fail-closed no-process-inspection behavior, normal guarded pass, direct Perl RSS kill, descendant Perl RSS kill, and host-percent kill.`
  Commit: `AGENT-RUNTIME-RAM-GUARD.1: add RAM guard for heavy local runs`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `complete` | `done` | RAM guard wrapper and workflow policy shipped. |

## Decisions

- `2026-06-21`: Default guard policy is host RAM cutoff below the user's 90%
  danger-zone threshold plus per-descendant RSS monitoring. A guard trip is a
  valid verification caveat for broad optional gates; it is not permission to
  keep running unbounded.
- `2026-06-21`: The wrapper fails closed when process-tree/RSS inspection or
  host-memory inspection is unavailable. In this sandbox that means future
  heavyweight guarded runs need process-inspection approval; otherwise the
  command must not run.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-21` | `AGENT-RUNTIME-RAM-GUARD.1` | `bash -n scripts/run_with_ram_guard.sh`; `scripts/run_with_ram_guard.sh --help`; guarded `sleep` pass; unapproved process-inspection fail-closed probe; guarded direct Perl RSS kill; guarded descendant Perl RSS kill; guarded host-percent kill; Knowledge Map generation/check; mdBook build; docs path audit; memory architecture; diff hygiene | `passed`; guard refuses to run without process inspection, reports current host memory under approval, exits 0 for a bounded pass, and exits 137 for RSS/host cutoff trips. |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `AGENT-RUNTIME-RAM-GUARD.1` | `AGENT-RUNTIME-RAM-GUARD.1: add RAM guard for heavy local runs` | Added guarded wrapper and documented future heavy-run policy. |

## Changelog

- `2026-06-21`: Created task tree after the `.202` broad
  supported-corpus verification attempt spawned a high-RSS Perl child.
- `2026-06-21`: Completed `.1`, adding a fail-closed RAM guard wrapper for
  heavyweight agent-launched local commands and documenting the 88% host /
  4096 MiB descendant RSS default policy.
