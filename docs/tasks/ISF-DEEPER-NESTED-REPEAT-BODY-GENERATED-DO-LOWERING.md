# ISF-DEEPER-NESTED-REPEAT-BODY-GENERATED-DO-LOWERING: Enable Deeper-Nested Repeat-Body Generated `(do)` Lowering

## Metadata

- Tree ID: `ISF-DEEPER-NESTED-REPEAT-BODY-GENERATED-DO-LOWERING`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-29`
- Last updated: `2026-05-29`
- Owner: repo-local workflow

## Goal

Allow a same-domain **generated** `(do child ...)` (static `(params ...)`, with
`(bind ...)`/`(domain NAME)` when params are present, or a generated-child
target) inside a `(repeat N ...)` reached through deeper branch nesting
(`when⁺ → repeat`, `switch → when⁺ → repeat`) to lower and instantiate its
child in the `_top` composition. Fourth scheduler-frontier slice.

## Ground truth (probed)

1. Currently a deeper-nested generated do fails first at the generated-child
   **collector** (`_child_action_refs_from_transaction_clauses`): its `when`/
   `switch` branches find only a **direct** `repeat` child, so a `repeat` nested
   two branch levels deep (`when → when → repeat`) is never discovered, the
   child's `(params)` is rejected, and the do is misclassified.
2. The lowering recursions `_expand_when` (~L8095) and `_expand_switch` (~L8138)
   call the inner `_expand_when` **without** the four trailing `_ir_repeat`
   params (`$spawn_refs`, `$constant_values`, `$generated_children`,
   `$repeat_do_ordinal_ref`), so even once discovered the generated child would
   not be instantiated (no `$spawn_refs` push).
3. The validator (after [[ISF-DEEPER-NESTED-REPEAT-BODY-LOCAL-DO-LOWERING]])
   defers a deeper-nested generated do with `deeper-nested repeat-body
   generated do remains deferred`.
4. Reachable deeper-nested shapes are `when⁺ → repeat` and `switch → when⁺ →
   repeat` (the validator blocks nested `switch`), matching the recursions.

## Scope (this tree)

- Discover generated children in repeats reached through nested `when`/`switch`
  (collector recursion).
- Thread the four `_ir_repeat` params through the nested `_expand_when`/
  `_expand_switch` recursions so the generated child is built + instantiated.
- Validator: admit a same-domain generated do at deeper branch nesting; keep
  cross-domain generated do (`cross-domain repeat-body do remains deferred`),
  spawn (`deeper-nested repeat-body spawn remains deferred`), and bindings/
  domain-without-params deferred.

## Non-Goals

- No deeper-nested spawn (separate slice).
- No cross-domain generated do (separate slice).

## Acceptance Criteria

- `when⁺ → repeat (do worker (params ...))` and `switch → when⁺ → repeat (...)`
  lower, instantiate the child in `_top`, and emit HDL (`--check-json` + SV).
- Deeper-nested cross-domain generated do, spawn, and params-less bindings/
  domain still fail closed.
- New `t/1382-isf-deeper-nested-repeat-body-generated-do.t` golden + updated
  `t/1375`/`t/1374`/`t/1215` where they asserted the now-lifted generated-do
  deferral.
- Book/spec docs synced; `prove` slice audit set + broad regression pass;
  mdBook clean; `git diff --check` clean.
- Each leaf committed via `COMMIT.md`.

## Task Tree

- ID: `ISF-DEEPER-NESTED-REPEAT-BODY-GENERATED-DO-LOWERING`
  Status: `active`
  Goal: `Lower same-domain deeper-nested repeat-body generated (do); keep cross-domain/spawn deferred.`
  Children:
    `ISF-DEEPER-NESTED-REPEAT-BODY-GENERATED-DO-LOWERING.1`,
    `ISF-DEEPER-NESTED-REPEAT-BODY-GENERATED-DO-LOWERING.2`

- ID: `ISF-DEEPER-NESTED-REPEAT-BODY-GENERATED-DO-LOWERING.1`
  Status: `pending`
  Goal: `Select the slice; record probed ground truth and the 3-part plan.`
  Acceptance: `Task tree committed before any code/test/doc change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `pending`

- ID: `ISF-DEEPER-NESTED-REPEAT-BODY-GENERATED-DO-LOWERING.2`
  Status: `pending`
  Goal: `Collector recursion + thread params through nested branch recursions + validator relaxation; add t/1382; sync docs; validate.`
  Acceptance: `Accept-path lowers + instantiates child + emits HDL; deferred cases still fail closed; audits green.`
  Verification: `prove -Iperl t/1382 t/1381 t/1380 t/1379 t/1375 t/1374 t/1215 t/1304 t/1307 t/1305 t/1376 t/1332 t/1250; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DEEPER-NESTED-REPEAT-BODY-GENERATED-DO-LOWERING.1` | `pending` | Selection commit before any code/test/doc change. |
| 2 | `ISF-DEEPER-NESTED-REPEAT-BODY-GENERATED-DO-LOWERING.2` | `pending` | Ship collector + threading + validator + golden + doc sync. |

## Decisions

- `2026-05-29`: Three-part change (collector recursion, lowering threading,
  validator) mirroring the loop-contained generated-do slice but for branch
  nesting. Same-domain only; cross-domain and spawn stay deferred.

## Open Questions

- None blocking.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-29` | `ISF-DEEPER-NESTED-REPEAT-BODY-GENERATED-DO-LOWERING.1` | `mdbook build docs/book`; `git diff --check` | `pending` |
| `2026-05-29` | `ISF-DEEPER-NESTED-REPEAT-BODY-GENERATED-DO-LOWERING.2` | `prove -Iperl t/1382 ... ; mdbook build docs/book; git diff --check` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DEEPER-NESTED-REPEAT-BODY-GENERATED-DO-LOWERING.1` | `ISF-DEEPER-NESTED-REPEAT-BODY-GENERATED-DO-LOWERING.1: select deeper-nested repeat-body generated-do lowering` | `pending commit hash` |
| `ISF-DEEPER-NESTED-REPEAT-BODY-GENERATED-DO-LOWERING.2` | `ISF-DEEPER-NESTED-REPEAT-BODY-GENERATED-DO-LOWERING.2: ship deeper-nested repeat-body generated-do lowering` | `pending commit hash` |

## Changelog

- `2026-05-29`: Created. Fourth scheduler-frontier slice. Same-domain generated
  `(do)` at deeper branch nesting; collector recursion + lowering threading +
  validator relaxation; cross-domain and spawn stay deferred.
