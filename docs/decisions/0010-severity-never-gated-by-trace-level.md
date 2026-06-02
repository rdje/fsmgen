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
   reports an *actual* warning / error / fatal condition — a real problem the reader
   should see — must be **displayed regardless of the trace level**.
2. **Informational notes stay gated — even when worded with severity words.** Many
   routine internal steps describe themselves with words like "failed" / "no … generated"
   (a multi-candidate recovery search whose individual misses are *expected*; a
   "no factoring needed" state). Those are *notes*, not problems: they stay on the
   gated trace path and are reworded to read as the notes they are. Only messages
   reporting an actual problem are ungated. **Heuristic:** a message that fires
   repeatedly during normal, successful operation is a note (gate it); a message that
   fires only on a genuine error / edge path is a warning/error (ungate it).
   (Refinement, user 2026-06-02: "Notes should be gatable via trace level" — after a
   literal "surface every severity word" pass revealed two notes flooding ~3755×/run.)
3. **Mechanism — an ungated severity channel in `FSM::Debug`:** `fsm_warn`,
   `fsm_error`, `fsm_fatal` always emit (to `STDERR`, prefixed `[WARNING]` /
   `[ERROR]` / `[FATAL]`), independent of `$DEBUG_LEVEL`/`$DEBUG_ENABLED`. They are
   *observability* emitters — they do not change control flow (they do not `die`);
   existing `confess`/`die` continue to handle termination where a fatal must stop
   execution. Severity lines are also mirrored to the trace output file when one is
   set, so the trace log stays complete.
4. **Existing severity-bearing `fsm_debug(..., N)` / `fsm_trace_*` calls were
   triaged:** genuine warnings/errors rerouted onto `fsm_warn`/`fsm_error`/`fsm_fatal`;
   routine notes kept gated and reworded to drop the alarming wording. Informational
   trace lines (no severity content) stay on the gated path unchanged.

## Consequences

- Surfacing previously-masked warnings can make a real, latent issue visible during a
  run/test. That is the point — the warning was always true; it was just hidden. In
  practice the triage gated the routine notes (so the suite's `STDERR` stays clean) and
  left ~28 genuine warnings ungated; across the full suite only 5 genuine warnings/errors
  fire (1× each, on real edge paths — a fixpoint pass-cap, a dependency-cycle fallback, an
  unsupported-source rejection, …) and none break a test. A `STDERR`-cleanliness test that
  newly observes a genuine severity line is updated to tolerate/assert it (the line is
  legitimate), not silenced.
- New code: never route warning/error/fatal content through `fsm_debug`/`fsm_trace_*`
  — use `fsm_warn`/`fsm_error`/`fsm_fatal` (or `confess`/`die` for hard failures).
- Tracked in `docs/tasks/TRACE-SEVERITY-NEVER-GATED.md`.
