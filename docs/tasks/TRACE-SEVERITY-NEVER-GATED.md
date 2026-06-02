# TRACE-SEVERITY-NEVER-GATED: warnings/errors/fatals must never be gated by trace level

## Metadata

- Tree ID: `TRACE-SEVERITY-NEVER-GATED`
- Status: `done`
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
- `2026-06-02`: `.1` done — ungated `fsm_warn`/`fsm_error`/`fsm_fatal` (commit
  `765b03cd`); decision `0010`.
- `2026-06-02`: `.2` done — triaged + rerouted the 34 severity-bearing gated calls.
  - A first literal "surface every severity word" pass revealed that **2 messages fire
    ~3755×/run on normal paths** (a multi-candidate recovery "compatibility parse miss"
    ×2547; "no intermediate signals generated" when none are needed ×1208), flooding
    STDERR and breaking 130 tests — and burying the real warnings. User refined `0010`:
    notes are gatable even when worded with severity words; only genuine problems ungate.
  - **Triage:** 6 high/moderate-frequency routine notes (`GlobalFactorizationSupport`
    165/206, `IntermediateSignalRecoverySupport` 481, `ExpressionBuilder` 80,
    `FactorizationSupport` 294, `IntermediateSignalSupport` 220) kept **gated**
    (`fsm_debug`, reworded to drop the alarm wording: "parse miss / no factoring needed /
    bare condition treated as positive"). The remaining ~28 genuine warnings/errors stay
    **ungated** (`fsm_warn`/`fsm_error`). Heuristic: fires repeatedly during normal passing
    runs ⇒ note; fires only on a genuine edge/error path ⇒ warning.
  - Verified: full suite **PASS** (1414 files, 10227 tests); across the whole suite only 5
    genuine warnings/errors fire (1× each — `LoopStateSupport` pass-cap,
    `ConsolidatedIntermediateDependencySupport` cycle-fallback, `Parser` unsupported-source
    `[ERROR]`, `ExpressionBuilder` can't-truncate, `FactorizationPolicySupport` pre-scan) and
    none break a test.
  - Remaining: `.3` sweep other masking patterns (`warn`/`print STDERR` gated by level —
    initial sweep found none); `.4` optional guard test.
- `2026-06-02`: `.3` done — swept active source for `warn`/`carp`/`print STDERR` gated by a
  debug/verbosity check, and for any residual severity-tagged `fsm_debug`: none found. The
  codebase is clean of masked severity.
- `2026-06-02`: `.4` done — guard `t/1415-trace-severity-not-gated-audit.t` fails if any
  active perl source routes a `WARNING:`/`ERROR:`/`FATAL:`-tagged message through the gated
  `fsm_debug`/`fsm_trace_*` API (must use the ungated channel). **Tree complete.**
