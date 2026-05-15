# ISF-DYNAMIC-WAIT: Non-Literal Transaction Wait Counts

## Metadata

- Tree ID: `ISF-DYNAMIC-WAIT`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-15`
- Last updated: `2026-05-15`
- Owner: repo-local workflow

## Goal

Extend ISF transaction-local `(wait ...)` beyond integer literals without
changing the exact timing meaning of the shipped wait construct.

## Non-Goals

- Do not accept runtime dynamic wait counts as public syntax until the lowerer
  preserves exact zero-count behavior in every shipped wait context.
- Do not treat dynamic waits as `(await ...)`; waits have no external ready
  condition and do not consume watchdogs.
- Do not let a generated counter silently change pending-sample timing.
- Do not expose raw lowerer state objects as the public report contract.

## Acceptance Criteria

- Non-literal wait-count classes are specified before implementation:
  statically resolved symbolic counts, runtime scalar counts, and rejected
  expression/count shapes.
- The mdBook, ISF spec, roadmap, task tree, and live docs distinguish shipped
  literal waits from the planned non-literal surfaces.
- Symbolic count implementation, when selected, resolves to the same fixed
  wait-state chain or transparent no-op as integer literals.
- Dynamic scalar implementation, when selected, samples the runtime count at
  wait entry, preserves exact `count == 0` fallthrough behavior, has explicit
  counter width/reset/report semantics, and fails closed where those guarantees
  are not possible.
- Each completed leaf is validated and committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DYNAMIC-WAIT`
  Status: `active`
  Goal: `Ship non-literal transaction wait counts without changing wait timing.`
  Children: `ISF-DYNAMIC-WAIT.1`, `ISF-DYNAMIC-WAIT.2`,
  `ISF-DYNAMIC-WAIT.3`

- ID: `ISF-DYNAMIC-WAIT.1`
  Status: `done`
  Goal: `Specify symbolic and dynamic wait-count contracts.`
  Acceptance: The task tree, mdBook, ISF spec, roadmap, and live docs record
  the count classes, timing, zero-count, pending-sample, counter, reset,
  diagnostics, and report obligations for future non-literal waits.
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-DYNAMIC-WAIT.1: specify non-literal waits`

- ID: `ISF-DYNAMIC-WAIT.2`
  Status: `pending`
  Goal: `Implement statically resolved symbolic wait counts.`
  Acceptance: `(wait NAME)` accepts only names that resolve before lowering to
  non-negative integer constants, lowers exactly like the existing literal
  count surface, preserves transparent zero-count behavior, rejects unknown or
  non-integer symbols with targeted diagnostics, updates reports/docs/tests,
  and reaches SystemVerilog generation.
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-DYNAMIC-WAIT.3`
  Status: `pending`
  Goal: `Implement runtime scalar dynamic wait counts.`
  Acceptance: Runtime scalar counts with known unsigned width lower through an
  explicit wait counter or equivalent bypass-capable schedule, preserve
  `count == 0` as no active wait cycle, snapshot the count at wait entry for
  positive counts, report bounded dynamic-wait metadata, reject unsupported
  contexts, and reach SystemVerilog generation.
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DYNAMIC-WAIT.2` | `pending` | Static symbolic counts can reuse the literal wait lowering contract and are the lowest-risk non-literal surface. |

## Decisions

- `2026-05-15`: Keep the meaning of `(wait count)` independent of count
  spelling. If the effective count is `K`, the transaction must wait exactly
  `K` active cycles; `K == 0` remains transparent fallthrough with no generated
  wait cycle.
- `2026-05-15`: Statically resolved symbolic counts are compile-time counts,
  not runtime payloads. Once resolved, they inherit the existing literal
  lowering, report shape, and zero-count behavior.
- `2026-05-15`: Runtime dynamic counts are sampled at the wait-entry boundary
  for the current wait occurrence. Later changes to the source signal do not
  change that occurrence's remaining wait.
- `2026-05-15`: Dynamic wait counters must use known widths. Unknown-width
  sources, signed negative values, list-expression counts, and unsupported
  count expressions fail closed until their type and timing contracts are
  specified.
- `2026-05-15`: Dynamic wait report metadata must not overload the existing
  exact `cycles` integer. Static waits keep `cycles` as an integer. Dynamic
  waits need explicit count-kind/count-source/counter metadata when they ship.

## Open Questions

- Which existing symbol scopes are the first legal source for
  `ISF-DYNAMIC-WAIT.2`: actor parameters only, package constants, or both?
  This does not block the current completed specification leaf; it must be
  answered before implementation.
- Should runtime dynamic waits initially allow only scalar names, or also
  allow known-width expressions such as `(+ base extra)`? This does not block
  symbolic count work.

## Blockers

- None for the current frontier.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-15` | `ISF-DYNAMIC-WAIT.1` | `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DYNAMIC-WAIT.1` | `ISF-DYNAMIC-WAIT.1: specify non-literal waits` | Specifies the non-literal wait-count contract before parser/lowerer changes. |

## Changelog

- `2026-05-15`: Created and activated the dynamic/symbolic wait task tree.
  Completed the specification leaf and made static symbolic counts the next
  PNT frontier.
