# 0010 — Severity (≥ warning) is never gated by a trace/verbosity level

- Date: 2026-06-02
- Type: convention (correctness / observability)
- Status: accepted

## Context

`FSM::Debug` provides a verbosity-graded trace API (`fsm_debug`,
`fsm_trace_enter/exit/decision/topic`) gated by `return unless $DEBUG_ENABLED &&
$level <= $DEBUG_LEVEL`. The verbosity scale (`none`/`low`/`medium`/`high`/`debug`
= 0–4) is purely **informational**.

Across the codebase, many messages that convey **warning/error/fatal** content
were emitted *through* that gated path (e.g. `fsm_debug("WARNING: could not
extract signal name, using fallback", 3)`). At the default verbosity (0) those
messages are **silent**. A masked error is a silent failure (user, 2026-06-02:
"warnings, errors, fatals are never masked out in the entire codebase ... When/If
a debug message says fail, error, …, the user shall be notified right away, it
will decide what to do with it").

## Decision

1. **Trace verbosity levels govern informational output only.** A message that
   conveys warning / error / fatal severity (or describes a failure: "fail",
   "error", "cannot", "invalid", "missing", "corrupt", "unsupported", "abort",
   "reject", "deprecated", …) must be **displayed regardless of the trace level**.
2. **No classification debate.** We do not argue "genuine warning vs. incidental
   debug note." If a message carries severity wording, it is surfaced
   unconditionally; the human reader decides what to do with it.
3. **Mechanism — an ungated severity channel in `FSM::Debug`:** `fsm_warn`,
   `fsm_error`, `fsm_fatal` always emit (to `STDERR`, prefixed `[WARNING]` /
   `[ERROR]` / `[FATAL]`), independent of `$DEBUG_LEVEL`/`$DEBUG_ENABLED`. They are
   *observability* emitters — they do not change control flow (they do not `die`);
   existing `confess`/`die` continue to handle termination where a fatal must stop
   execution. Severity lines are also mirrored to the trace output file when one is
   set, so the trace log stays complete.
4. **Existing severity-bearing `fsm_debug(..., N)` / `fsm_trace_*` calls are
   rerouted** onto `fsm_warn`/`fsm_error`/`fsm_fatal`. Genuinely informational
   trace lines (no severity wording) stay on the gated path.

## Consequences

- Surfacing previously-masked warnings may make a real, latent issue visible during
  a run/test. That is the point — the warning was always true; it was just hidden.
  Tests that asserted on clean `STDERR` are updated to tolerate (or assert) the
  now-visible severity line, or the underlying condition is fixed.
- New code: never route warning/error/fatal content through `fsm_debug`/`fsm_trace_*`
  — use `fsm_warn`/`fsm_error`/`fsm_fatal` (or `confess`/`die` for hard failures).
- Tracked in `docs/tasks/TRACE-SEVERITY-NEVER-GATED.md`.
