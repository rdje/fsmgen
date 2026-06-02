# TRACE-SEVERITY-NEVER-GATED: warnings/errors/fatals must never be gated by trace level

## Metadata

- Tree ID: `TRACE-SEVERITY-NEVER-GATED`
- Status: `in-progress`
- Roadmap lane: infra / observability
- Created: `2026-06-02`
- Last updated: `2026-06-02`
- Owner: repo-local workflow
- Decision: `docs/decisions/0010-severity-never-gated-by-trace-level.md`

## Goal

No warning/error/fatal message is masked by the trace/verbosity level anywhere in
the codebase (a masked error is a silent failure). Trace levels gate informational
output only; severity-bearing messages are always displayed.

## Design

Add an ungated severity channel to `FSM::Debug` — `fsm_warn`/`fsm_error`/`fsm_fatal`
that always emit to `STDERR` (prefixed `[WARNING]`/`[ERROR]`/`[FATAL]`), independent
of `$DEBUG_LEVEL` (and mirror to the trace file when set). They are observability
emitters — they do NOT `die` (existing `confess`/`die` keep handling termination).
Reroute every severity-bearing `fsm_debug(..., N)` / `fsm_trace_*` call onto them.

## Slice plan

- `.1` select + design — decision `0010` + this tree + the ungated emitters in
  `FSM::Debug` + a focused test that they emit at verbosity 0. **(this slice)**
- `.2` reroute the severity-bearing gated trace calls (initial sweep found 36 across
  18 files) onto `fsm_warn`/`fsm_error`/`fsm_fatal`; full suite green (handle any
  newly-surfaced `STDERR` lines per `0010`).
- `.3` sweep the remaining masking patterns: `warn`/`print STDERR` gated inside
  `if ($debug_level …)` blocks, and any severity routed through other gated channels.
- `.4` guard: a focused test asserting no `fsm_debug`/`fsm_trace_*` call in active
  source carries severity wording (keeps the invariant from regressing).

## Non-Goals

- Changing the informational verbosity scale or the gated `fsm_debug` semantics for
  genuinely informational lines.
- Reclassifying or rewording trace messages beyond moving severity-bearing ones to
  the ungated channel.

## Acceptance Criteria

- `fsm_warn`/`fsm_error`/`fsm_fatal` emit at verbosity 0 (proven by a focused test).
- No severity-bearing message remains on a level-gated path in active source.
- Full suite green; any test that newly observes a surfaced severity line is updated
  to tolerate/assert it (or the underlying condition fixed).

## Blockers

- None.

## Changelog

- `2026-06-02`: created; initial sweep — 36 severity-bearing gated trace calls across
  18 files (excluding `*.orig`/`*.txt` cruft); `FSM::Debug` has no ungated severity
  emitter yet.
