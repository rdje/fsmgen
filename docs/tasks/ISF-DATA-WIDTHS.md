# ISF-DATA-WIDTHS: Data Operation Width Inference

## Metadata

- Tree ID: `ISF-DATA-WIDTHS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-14`
- Last updated: `2026-05-14`
- Owner: repo-local workflow

## Goal

Improve ISF data-operation width inference so `extract`, `shift_right`,
`shift_left`, `assemble`, and related scheduled expressions avoid placeholder
width/slice behavior whenever safe width evidence can be derived from
interface declarations, samples, storage metadata, explicit options, or
neighboring operations.

## Non-Goals

- Do not implement broad aggregate type inference for the whole `.fsm`
  language; that belongs to language/type backlog work.
- Do not guess widths when evidence is ambiguous.
- Do not silently change generated bit ordering for already-shipped explicit
  width forms.

## Acceptance Criteria

- Current data-operation width sources and fallback behavior are inventoried.
- A width-evidence priority model is documented for ISF data operations.
- Safe inference cases lower to exact scheduled `.fsm` slices/shifts/concats.
- Ambiguous or underconstrained cases fail explicitly or remain documented as
  deferred with clear rationale.
- Schedule-report storage metadata reflects inferred widths more accurately.
- Focused tests and docs cover inferred, explicit, ambiguous, and malformed
  cases.

## Task Tree

- ID: `ISF-DATA-WIDTHS`
  Status: `active`
  Goal: `Ship safer and broader ISF data-operation width inference.`
  Children: `ISF-DATA-WIDTHS.1`, `ISF-DATA-WIDTHS.2`,
  `ISF-DATA-WIDTHS.3`, `ISF-DATA-WIDTHS.4`, `ISF-DATA-WIDTHS.5`

- ID: `ISF-DATA-WIDTHS.1`
  Status: `done`
  Goal: `Inventory current width inference and placeholder fallback behavior.`
  Acceptance: `The task file lists current width sources, explicit width
  options, unknown-width fallbacks, generated `.fsm` shapes, and report
  storage effects.`
  Verification: `prove -l t/1099-isf-repeat-data-ops.t t/1101-isf-extract-slices.t t/1111-isf-sample-before-data-ops.t t/1173-isf-shift-right-explicit-width.t t/1174-isf-extract-explicit-widths.t t/1199-isf-shift-clause-boundary.t t/1200-isf-assemble-clause-boundary.t t/1201-isf-extract-clause-boundary.t`;
  `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-DATA-WIDTHS.1: inventory data width behavior`

- ID: `ISF-DATA-WIDTHS.2`
  Status: `done`
  Goal: `Specify width-evidence precedence and failure policy.`
  Acceptance: `The tree records which evidence sources win, which cases infer,
  which cases fail, and which cases remain deferred.`
  Verification: `prove -l t/1099-isf-repeat-data-ops.t t/1101-isf-extract-slices.t t/1111-isf-sample-before-data-ops.t t/1173-isf-shift-right-explicit-width.t t/1174-isf-extract-explicit-widths.t t/1199-isf-shift-clause-boundary.t t/1200-isf-assemble-clause-boundary.t t/1201-isf-extract-clause-boundary.t`;
  `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-DATA-WIDTHS.2: specify width evidence policy`

- ID: `ISF-DATA-WIDTHS.3`
  Status: `pending`
  Goal: `Implement inference for the first data-operation family.`
  Acceptance: `The selected operation family lowers exact widths without
  placeholders for documented safe cases and rejects ambiguous cases.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-DATA-WIDTHS.4`
  Status: `pending`
  Goal: `Extend inference across remaining covered data operations.`
  Acceptance: `The agreed extract, shift_right, shift_left, and assemble
  cases share the documented width-evidence model.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-DATA-WIDTHS.5`
  Status: `pending`
  Goal: `Add reports, tests, and synchronized docs.`
  Acceptance: `Schedule-report storage, focused regressions, ISF spec, public
  contract, mdBook, and live docs describe the shipped width behavior.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DATA-WIDTHS.3` | `pending` | `extract` is the first implementation family because it currently emits placeholder slice bounds and already has partial width validation. |

## ISF-DATA-WIDTHS.1 Inventory

Current implementation points:

- Width-map owner: `perl/FSM/Scheduler/ISF/LoweringIR.pm`.
- Data-operation builders: `_ir_shift_left`, `_ir_shift_right`,
  `_ir_assemble`, and `_ir_extract`.
- Parser/lowering boundary coverage:
  [t/1199-isf-shift-clause-boundary.t](../../t/1199-isf-shift-clause-boundary.t),
  [t/1200-isf-assemble-clause-boundary.t](../../t/1200-isf-assemble-clause-boundary.t),
  and [t/1201-isf-extract-clause-boundary.t](../../t/1201-isf-extract-clause-boundary.t).
- Width behavior coverage:
  [t/1099-isf-repeat-data-ops.t](../../t/1099-isf-repeat-data-ops.t),
  [t/1101-isf-extract-slices.t](../../t/1101-isf-extract-slices.t),
  [t/1111-isf-sample-before-data-ops.t](../../t/1111-isf-sample-before-data-ops.t),
  [t/1173-isf-shift-right-explicit-width.t](../../t/1173-isf-shift-right-explicit-width.t),
  and [t/1174-isf-extract-explicit-widths.t](../../t/1174-isf-extract-explicit-widths.t).

Width evidence currently collected before transaction lowering:

- `_build_signal_width_map($actor, $tx)` builds one transaction-local width
  map before any state IR is emitted. This map is type/shape evidence, not
  cycle-value evidence.
- Actor interface input/output declarations seed the map. Omitted interface
  widths normalize to `1` before lowering.
- `(sample source as alias)` adds `alias` width only when `source` already has
  known width evidence. Sample collection recurses through top-level and
  nested transaction bodies.
- `shift_right` explicit `(width N)` adds the shifted register width only when
  that register does not already have width evidence. The lowering builder
  still uses the explicit width option directly for that `shift_right`
  expression when it is present.
- `extract` explicit `(widths N...)` adds destination-field widths only when a
  field does not already have width evidence. The lowering builder separately
  rejects explicit widths that conflict with known field widths.
- `assemble` adds the target width as the sum of all part widths when every
  part has known width evidence. Today this assignment overwrites any existing
  target width evidence and does not diagnose disagreement with a declared
  target width.
- The collectors walk the whole transaction clause tree before lowering, so
  width evidence is not source-order-sensitive inside a transaction. A later
  `assemble` can provide width evidence used by an earlier `extract` of the
  same name. This is acceptable for width/type facts but must be called out
  before using the same mechanism for anything cycle-sensitive.

Current generated `.fsm` shapes:

- `shift_left` lowers to `(<- (reg (| (<< reg 1) bit)))`. It has no explicit
  width option and does not need a width to choose an insertion position.
- `shift_right` lowers to
  `(<- (reg (| (>> reg 1) (<< bit insert))))`. `insert` is:
  explicit `width - 1` when `(width N)` is present, otherwise known
  `width(reg) - 1`, otherwise the placeholder expression `(- WIDTH 1)`.
- `assemble` lowers to `(<- (target (concat part...)))`. The scheduled
  expression carries no explicit width in the `.fsm` text; any width evidence
  is only in the scheduler's private map for neighboring operations.
- `extract` lowers to one sequential extraction state using `<=` assignments.
  If the source word width is known, slicing starts at `width(word) - 1`.
  If the source word width is unknown but every field width is known, slicing
  starts at `sum(field_widths) - 1`. Otherwise each unknown field and every
  later field whose position can no longer be proven keeps placeholder slice
  bounds like `(slice packet header HIGH header LOW)`.

Current fallback and underconstrained behavior:

- Unknown-width `shift_right` remains accepted and emits the `WIDTH`
  placeholder expression.
- Unknown-width `extract` remains accepted and emits placeholder `HIGH`/`LOW`
  slice bounds for unproven field positions.
- `extract` validates malformed `(widths ...)` options, count mismatches, and
  conflicts between explicit field widths and already-known field widths.
- `extract` does not currently validate that the sum of field widths equals a
  known source word width. If the sum is smaller, lower bits of the word can be
  ignored; if the sum is larger, later computed lows can become negative.
- `shift_right` does not currently reject an explicit `(width N)` that
  disagrees with an already-known register width, because the explicit option
  is used locally by the lowering expression.
- `assemble` does not currently reject a concat part-total width that
  disagrees with an already-known or declared target width.

Current schedule-report storage effects:

- Data-operation targets appear in `inferred_storage` when their emitted
  assignment is sequential (`<-`, `<=`, or `<1`).
- Ordinary data-operation targets are reported as `kind = register` without a
  `width` field today. Width evidence collected for `shift_right`, `assemble`,
  and `extract` is not promoted into public storage-width metadata unless the
  target also belongs to a generated scheduler counter family.
- Generated repeat/watchdog/counter families still report widths through the
  existing counter-width path; this tree should avoid conflating that shipped
  counter reporting with future data-register width reporting.

## ISF-DATA-WIDTHS.2 Width Policy

Width facts:

- A width fact is a positive integer associated with one signal-like ISF name
  inside one actor/transaction lowering scope.
- Width facts are type/shape facts. They never imply that a runtime value is
  available before the state in which it is assigned.
- A width fact may be used across source order inside one transaction because
  widths are static facts, but the same rule must not be copied to
  cycle-sensitive values.

Precedence and conflict policy:

| Priority | Evidence | Policy |
| --- | --- | --- |
| 1 | Actor interface declaration | Authoritative public width. Omitted widths normalize to `1`. |
| 2 | Operation-local explicit option | Author assertion for that operation, such as `shift_right (width N)` or `extract (widths N...)`. It may fill an unknown width, but it must match any existing fact for the same named signal. |
| 3 | Alias propagation | `(sample source as alias)` copies `source` width to `alias` when known. It must not override an existing different `alias` width. |
| 4 | Structural derivation | `assemble` part sums and `extract` field/source sums can derive missing widths only when all required operands are known. They must agree with already-known facts. |
| 5 | Generated scheduler storage | Repeat/watchdog/contract counters keep their existing generated-width path. This is not a reason to expose ordinary data-register widths until `ISF-DATA-WIDTHS.5`. |

Failure and fallback policy:

- Once an operation family is migrated by this tree, that family should not
  emit `WIDTH`, `HIGH`, or `LOW` placeholders for accepted source. A case that
  cannot derive exact positions must fail closed with a targeted diagnostic,
  unless the tree explicitly marks the subcase deferred.
- Conflict between two width facts for the same name must fail closed. The
  lowerer should name the signal, the conflicting values, and the evidence
  sources when practical.
- Explicit width options are not force-casts. They document author intent and
  fill gaps, but they do not silently override declarations or derived facts.
- Compatibility placeholder behavior may remain temporarily for operation
  families that have not yet been migrated by `ISF-DATA-WIDTHS.3` or
  `ISF-DATA-WIDTHS.4`, but that boundary must stay documented until removed.

Operation-specific policy:

- `extract` is the first implementation family for `ISF-DATA-WIDTHS.3`.
  Accepted exact cases are:
  known source word width plus all field widths known; unknown source word
  width plus all field widths known, using the field-width sum; explicit
  `(widths N...)` for every field with no conflicts; and field widths inherited
  from interface/sample/structural facts.
- `extract` must fail when a known source word width disagrees with the sum of
  field widths, when any field width remains unknown after the evidence pass,
  or when explicit field widths conflict with known facts.
- `shift_right` should later use the same explicit-width-as-assertion policy:
  explicit `(width N)` can fill an unknown register width, but must not
  disagree with known register width. Unknown register width without explicit
  width should fail after the family is migrated.
- `assemble` should derive target width only when all part widths are known.
  If target width is already known, the part sum must match it. Unknown part
  widths may remain deferred if the emitted concat can still be reviewed, but
  they cannot be used as evidence for neighboring operations.
- `shift_left` needs no insertion-position width today. It participates mainly
  by consuming and preserving the register width facts used by other
  operations.

Deferred policy details:

- Broad aggregate/record width inference remains outside this tree.
- Signedness, truncation, extension, and explicit cast semantics remain
  separate language-surface work.
- Public schedule-report width metadata for ordinary data registers is
  deferred to `ISF-DATA-WIDTHS.5` after implementation proves which width facts
  are stable enough to advertise.

## Decisions

- `2026-05-14`: This tree owns ISF-specific data-operation width inference,
  not broad language-wide type inference.
- `2026-05-14`: Width evidence precedence is declaration, explicit option,
  alias propagation, structural derivation, then generated scheduler storage.
  Explicit width options are assertions, not silent overrides.
- `2026-05-14`: `extract` is the first implementation family because it owns
  the most visible placeholder fallback (`HIGH`/`LOW`) and already has
  explicit width validation hooks.

## Open Questions

- None for the current frontier. `ISF-DATA-WIDTHS.3` should implement the
  `extract` policy above before widening to other operation families.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-DATA-WIDTHS` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-DATA-WIDTHS.1` | `prove -l t/1099-isf-repeat-data-ops.t t/1101-isf-extract-slices.t t/1111-isf-sample-before-data-ops.t t/1173-isf-shift-right-explicit-width.t t/1174-isf-extract-explicit-widths.t t/1199-isf-shift-clause-boundary.t t/1200-isf-assemble-clause-boundary.t t/1201-isf-extract-clause-boundary.t`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-DATA-WIDTHS.2` | `prove -l t/1099-isf-repeat-data-ops.t t/1101-isf-extract-slices.t t/1111-isf-sample-before-data-ops.t t/1173-isf-shift-right-explicit-width.t t/1174-isf-extract-explicit-widths.t t/1199-isf-shift-clause-boundary.t t/1200-isf-assemble-clause-boundary.t t/1201-isf-extract-clause-boundary.t`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DATA-WIDTHS` | `R14: map ISF objectives to task trees` | Initial tree creation belongs to the ISF objective task-tree coverage slice. |
| `ISF-DATA-WIDTHS.1` | `ISF-DATA-WIDTHS.1: inventory data width behavior` | Current width sources, fallbacks, and report effects. |
| `ISF-DATA-WIDTHS.2` | `ISF-DATA-WIDTHS.2: specify width evidence policy` | Width precedence and first implementation target. |

## Changelog

- `2026-05-14`: Created the active ISF data-width task tree.
- `2026-05-14`: Completed the current width-inference and placeholder
  fallback inventory; advanced the frontier to `ISF-DATA-WIDTHS.2`.
- `2026-05-14`: Specified width-evidence precedence and fail-closed policy;
  selected `extract` as the first implementation family and advanced the
  frontier to `ISF-DATA-WIDTHS.3`.
