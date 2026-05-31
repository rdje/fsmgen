# ISF-NESTED-CROSS-DOMAIN-ACTIVATION: Cross-Domain `(do)` Inside `when` / `switch` / `repeat` Bodies

## Metadata

- Tree ID: `ISF-NESTED-CROSS-DOMAIN-ACTIVATION`
- Status: `active`
- Roadmap lane: `R14` (ISF Multi-Clock And CDC Semantics — richer crossing primitives)
- Created: `2026-05-31`
- Last updated: `2026-05-31`
- Owner: repo-local workflow

## Goal

Extend cross-domain blocking `(do child)` through a declared
`(crossings (activation child (from SRC)(to DST)))` from the shipped **top-level**
case to **nested** control-flow contexts — a `(do child)` inside a `when` body, a
`switch` branch, or a `repeat` body — reusing the dual-CDC activation routing.

This is a direct follow-up to `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING` (which
shipped the top-level case end-to-end: parse → validate → dual-CDC lowering → HDL
→ book example → schedule report).

## Ground truth (investigated `2026-05-31`)

- The activation-crossing infrastructure exists and is correct for a top-level
  `(do child)`: `_validate_transaction_clause_domain_refs` accepts a covered
  cross-domain `(do)` (`_activation_crossing_covers`), `_domain_actor_for_scheduled_artifact`
  injects `external_activations`, and `_wire_external_activations`
  (LoweringIR.pm) promotes the handshake to per-domain module ports with the
  await-ready + one-cycle pulse on both the caller and callee, routed through two
  CDC children in `_emit_multi_domain_top`.
- Two restrictions currently scope it to the top level:
  1. The validator relaxation is gated on `($label // '') eq 'transaction body'`
     (LoweringIR.pm, the do/spawn branch of `_validate_transaction_clause_domain_refs`).
  2. The partition's "crossing owns a real activation" check
     (`_build_domain_partition`) only counts a covering `(do child)` whose
     `$ref->{label} eq 'transaction body'`.
- Net effect today: a nested cross-domain `(do worker)` (e.g. inside a `(when
  cond ...)`) fails closed — but with a **misleading** diagnostic: `ISF
  activation crossing for child 'worker' (domain 'core' -> 'bus') is declared but
  no transaction in domain 'core' performs a top-level '(do worker)'`. The
  crossing IS used; it is just used in a nested context, which is not yet
  supported. The message reads as "unused" rather than "nested-use deferred".

## Design

- `.1` select (this doc).
- `.2` (safe, bounded) — **precise deferred diagnostic**: when an activation
  crossing has no covering *top-level* `(do child)` but the source domain DOES
  perform a *nested* `(do child)`, fail closed with an accurate message
  (`... performs a nested '(do worker)' inside a when/switch/repeat body, but
  cross-domain activation is currently supported only for a top-level '(do)';
  nested cross-domain activation remains deferred`), distinct from the
  genuinely-unused case. Mirrors the project's targeted-rejection-diagnostic
  pattern. Lock with a `t/138x` diagnostic test; both the unused and the
  nested-deferred messages asserted.
- `.3`+ (the substantial work) — **support** nested cross-domain `(do)`. Scope
  finding from the `.3` design (investigated `2026-05-31`), see Decisions:

  - `do`/`spawn` are supported clause keywords ONLY in the `transaction`
    (top-level) and `repeat` contexts (`%SUPPORTED_TRANSACTION_CLAUSES`). A plain
    `(do)` directly in a `when`/`switch`/`while`/`until` body is unsupported **even
    same-domain** (rejected at `_validate_supported_transaction_clauses`). So
    "nested `(do)`" means "inside a `repeat` body" (a top-level repeat, or a repeat
    nested in a when/switch/while/until). Plain when/switch/while/until-body
    cross-domain `(do)` is therefore N/A for this tree (it would require a
    same-domain when/switch-body `(do)` feature first — a separate lane); `.2`
    already defers it accurately.
  - So `.3`+ = **cross-domain REPEAT-BODY `(do worker)`** (the local/sibling model
    the activation crossing covers), routed through the crossing's two CDC children
    per loop iteration. A blocking repeat-body `(do)` blocks each iteration until
    `done`, so it is single-outstanding per iteration → the shipped await-`ready` +
    one-cycle-`<start>` + dual-CDC handshake applies per iteration, and the DEST
    worker returns to idle between iterations (callee terminal → idle), ready for
    the next `<start>` pulse.
  - Caller restructure feasibility: `_wire_external_activations` (caller) finds the
    await-state asserting `<start>` and inserts `await <start>_ready` → one-cycle
    `<start>` before it, redirecting predecessors. Inside a `repeat` region the
    do-state's predecessor is the loop entry and the `repeat_check` loops back to
    the do-state; the existing "redirect all transitions targeting the do-state
    (except from the request state) to the ready-await" rule would ALSO redirect
    the `repeat_check` loop-back to the ready-await — exactly right (each iteration
    re-runs the full handshake). So the restructure likely applies in the repeat
    region with little/no change — to be verified empirically in the first
    implementation sub-slice.
  - Gate-lifting: the validator relaxation (currently `$label eq 'transaction
    body'`) and the partition deferral (`_activation_do_use_context` nested →
    confess) must be lifted for the `repeat` body context specifically, while
    keeping plain when/switch/while/until-body `(do)` deferred.
  - Sub-slices (mirroring the same-domain repeat-body frontier), each with a golden
    `.fsm` + HDL evidence: `.3` top-level repeat-body; `.4` when→repeat;
    `.5` switch→repeat; `.6` while/until→repeat; `.7` deeper-nested
    (`when⁺→repeat`, `switch→when⁺→repeat`). Consolidate if the restructure
    generalizes across contexts.

## Non-Goals

- Cross-domain `(spawn)` (non-blocking) — a separate tree (different drain
  semantics).
- Data-payload crossings.
- Auto-generation of a crossing without an explicit declaration.

## Acceptance Criteria

- `.2`: a nested cross-domain `(do)` covered by a declared crossing fails closed
  with an accurate "nested cross-domain activation remains deferred" diagnostic,
  distinct from the declared-but-unused message; locked by a focused test;
  top-level cross-domain activation and all existing behavior unchanged.
- `.3`+: nested cross-domain `(do)` lowers end-to-end through the dual-CDC routing
  for the supported contexts, with goldens + HDL evidence; unsupported deeper
  nestings still fail closed with accurate diagnostics.
- Each leaf committed via `COMMIT.md`.

## Task Tree

- ID: `ISF-NESTED-CROSS-DOMAIN-ACTIVATION`
  Status: `active`
  Goal: `Cross-domain blocking (do child) inside when/switch/repeat bodies via the activation crossing.`
  Children: `.1` (select), `.2` (precise nested-deferred diagnostic), `.3`+ (nested support per context)

- ID: `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.1`
  Status: `done`
  Goal: `Select; record ground truth (top-level-only gates + misleading nested diagnostic) + design + slice plan.`
  Acceptance: `Task tree committed before any code change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `2c081347`

- ID: `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.2`
  Status: `done`
  Goal: `Precise nested-deferred diagnostic — distinguish a nested (do child) use from a genuinely-unused crossing.`
  Acceptance: `A nested cross-domain (do child) (inside when/switch/repeat/while/until) fails closed with "used by a nested (do child) (inside a <ctx>) ... nested cross-domain activation remains deferred", distinct from the declared-but-unused message; the top-level case still lowers; genuinely-unused still says "declared but ... no top-level (do)"; locked by t/1387.`
  Verification: `prove -Iperl t/1387 (9 subtests) t/1386 t/1247 t/1372 t/1374 t/1375 t/1250 t/1305 t/1382 t/1383 t/1110 (11 files, 451) PASS; full ./bin/ci-regression isf --no-book PASS; perl -c; git diff --check`
  Commit: `ship commit (this slice)`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Selection/design (`2c081347`). |
| 2 | `.2` | `done` | Precise nested-deferred diagnostic shipped (`_activation_do_use_context` recursive scan; `t/1387` covers when/switch/repeat + the genuinely-unused case). |
| 3 | `.3` | `pending` | Support **top-level repeat-body** cross-domain `(do worker)` (the first supported nested context): lift the validator + partition gate for the `repeat` context, verify the caller restructure applies in the repeat region, route the per-iteration handshake through the dual-CDC; golden `.fsm` + HDL. |
| 4 | `.4`–`.7` | `pending` | Remaining repeat contexts: `when→repeat`, `switch→repeat`, `while/until→repeat`, deeper-nested. (Plain when/switch/while/until-body `(do)` is N/A — unsupported even same-domain.) |

## Decisions

- `2026-05-31`: split into a safe diagnostic-precision slice (`.2`) before the
  substantial support work (`.3`+), because the current fail-closed message for a
  nested cross-domain `(do)` is misleading (reports "unused" when it is
  nested-use-deferred), and an accurate diagnostic is independently valuable and
  low-risk.
- `2026-05-31` (`.3` design): scoped `.3`+ to **cross-domain repeat-body `(do)`
  only**. `%SUPPORTED_TRANSACTION_CLAUSES` allows `do`/`spawn` only in the
  `transaction` and `repeat` contexts, so a plain `(do)` in a when/switch/while/
  until body is unsupported even same-domain (confirmed: rejected at
  `_validate_supported_transaction_clauses` with "unsupported '(do ...)' clause in
  when body"). Supporting cross-domain plain when/switch-body `(do)` would require
  building same-domain support for it first — out of this tree (a separate lane).
  The viable nested-do context is the `repeat` body, and there the per-iteration
  single-outstanding blocking handshake fits the shipped dual-CDC handshake.

## Open Questions

- `.3`+: whether the caller-side one-cycle/await-ready restructure can be applied
  uniformly to a nested do-state, or whether each nesting context (`when`,
  `switch`, `repeat`) needs context-specific handling (as same-domain repeat-body
  activation did).

## Blockers

- None for `.1`/`.2`. `.3`+ is the substantial support work.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-31` | `.1` | `mdbook build docs/book`; `git diff --check` | `PASS` |
| `2026-05-31` | `.2` | `prove -Iperl t/1387` (9 subtests) + clock-domain/crossing/diagnostic/spec-index/feature-matrix sweep (11 files, 451) PASS; full `./bin/ci-regression isf --no-book` PASS; `perl -c`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.1: select nested cross-domain activation` | `2c081347` |
| `.2` | `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.2: precise nested cross-domain (do) deferred diagnostic` | `ship commit (this slice)` |

## Changelog

- `2026-05-31`: Created as the direct follow-up to
  `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING` (top-level cross-domain activation
  shipped). Recorded the two top-level-only gates, the misleading nested
  diagnostic, and the slice plan (`.2` precise diagnostic, `.3`+ nested support).
- `2026-05-31`: `.2` shipped. Added `_activation_do_use_context` (a recursive
  clause scan in `LoweringIR.pm`) that classifies a `(do child)` as top-level vs
  nested (when/switch/repeat/while/until body); `_build_domain_partition` now
  fails a nested cross-domain `(do child)` with an accurate "used by a nested
  '(do child)' (inside a <ctx>) ... nested cross-domain activation remains
  deferred" message, distinct from the genuinely-unused "declared but ... no
  top-level (do)" message. The top-level case still lowers; `t/1387` gained a
  subtest covering when/switch/repeat + the not-misreported-as-unused assertion
  (now 9 subtests). The recursive scan replaced the prior reliance on
  `_live_child_action_refs_from_transaction_clauses`, which only surfaced
  repeat-body do-refs (so when/switch nested uses were previously misreported as
  unused).
- `2026-05-31`: `.3` nested-support DESIGN recorded. Investigated the supported
  nested-`(do)` surface and found `do`/`spawn` are allowed only in the
  `transaction` and `repeat` clause contexts (`%SUPPORTED_TRANSACTION_CLAUSES`);
  plain when/switch/while/until-body `(do)` is unsupported even same-domain. So
  `.3`+ is scoped to **cross-domain repeat-body `(do)`** (per-iteration handshake
  through the dual-CDC; the caller restructure is expected to apply in the repeat
  region with little change). Re-scoped `.3`+ into `.3` top-level repeat-body and
  `.4`–`.7` for the remaining repeat contexts. NOTE: the do/spawn clause-context
  limitation has no fundamental semantic rationale (blocking `await` IS allowed in
  those contexts) — it is an implementation-scoping deferral, tracked separately
  for mdBook documentation and a possible future "conditional `(do)`" language
  feature aligned with the rich-high-level-language goal.
