# ISF-COMPATIBILITY: Legacy Handshake And Removed Assign Surface

## Metadata

- Tree ID: `ISF-COMPATIBILITY`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-14`
- Last updated: `2026-05-14`
- Owner: repo-local workflow

## Goal

Decide and document the fate of legacy or removed ISF surfaces, especially
deprecated `(handshake ...)` metadata and the removed transaction `(assign ...)`
keyword, so compatibility behavior remains intentional rather than accidental.

## Non-Goals

- Do not make legacy forms semantic by default.
- Do not widen rule expression assignments here; that belongs to
  `ISF-RULE-ACTIONS`.
- Do not remove compatibility forms without migration diagnostics and docs.

## Acceptance Criteria

- Current parsing, validation, ignored behavior, and fail-closed diagnostics
  for legacy/removed forms are inventoried.
- Each compatibility surface has an explicit decision: keep ignored, make
  semantic, remove, or keep fail-closed with migration guidance.
- Diagnostics and docs match the decision for each surface.
- Tests cover accepted compatibility behavior, rejected behavior, migration
  hints, and CLI/in-process parity.
- ISF spec, public contract, mdBook, roadmap, and live docs agree.

## Task Tree

- ID: `ISF-COMPATIBILITY`
  Status: `done`
  Goal: `Resolve legacy handshake and removed assign compatibility policy.`
  Children: `ISF-COMPATIBILITY.1`, `ISF-COMPATIBILITY.2`,
  `ISF-COMPATIBILITY.3`, `ISF-COMPATIBILITY.4`, `ISF-COMPATIBILITY.5`

- ID: `ISF-COMPATIBILITY.1`
  Status: `done`
  Goal: `Inventory current legacy handshake and removed assign behavior.`
  Acceptance: `The task file lists parser behavior, validation behavior,
  diagnostics, ignored metadata, fail-closed cases, tests, and docs.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `prove -l t/1178-isf-handshake-compatibility-boundary.t t/1180-isf-unsupported-transaction-clause-boundary.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-COMPATIBILITY.1: inventory legacy surfaces`

- ID: `ISF-COMPATIBILITY.2`
  Status: `done`
  Goal: `Decide legacy handshake policy.`
  Acceptance: `The tree records whether the handshake metadata remains ignored,
  gains semantics, becomes rejected, or gets a migration path, with rationale.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-COMPATIBILITY.2: decide handshake policy`

- ID: `ISF-COMPATIBILITY.3`
  Status: `done`
  Goal: `Decide removed transaction assign policy.`
  Acceptance: `The tree records whether transaction assign stays rejected, gains a
  replacement, or maps to another construct, with migration diagnostics.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-COMPATIBILITY.3: decide removed assign policy`

- ID: `ISF-COMPATIBILITY.4`
  Status: `done`
  Goal: `Implement selected compatibility diagnostics or semantics.`
  Acceptance: `The selected policy is enforced consistently across parser,
  scheduler, CLI, and in-process facades.`
  Verification: syntax checks for changed Perl modules and focused tests; `prove -l t/1178-isf-handshake-compatibility-boundary.t t/1180-isf-unsupported-transaction-clause-boundary.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-COMPATIBILITY.4: enforce compatibility diagnostics`

- ID: `ISF-COMPATIBILITY.5`
  Status: `done`
  Goal: `Add tests and synchronize docs/contracts.`
  Acceptance: `Focused tests and docs cover compatibility policy, rejected
  cases, migration hints, and public contract wording.`
  Verification: syntax checks for changed tests and contract module; `prove -l t/1178-isf-handshake-compatibility-boundary.t t/1180-isf-unsupported-transaction-clause-boundary.t t/1183-ci-regression-tier-selection.t t/1229-isf-compatibility-cli-parity.t t/1112-isf-public-interface-contract.t t/1144-isf-public-tested-by-metadata-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-COMPATIBILITY.5: close compatibility surface`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | All known compatibility leaves are complete. Future compatibility work should open a new leaf or feature tree. |

## ISF-COMPATIBILITY.1 Inventory

### Deprecated `(handshake ...)`

Current parser behavior:

- `FSM::Adapter::ISF::Parser` initializes `handshakes => {}` in the actor
  shell as a compatibility placeholder.
- Actor-level `(handshake ...)` clauses call `_parse_handshake(...)` and then
  discard the parsed result. No handshake metadata is stored in the returned
  actor shell.
- The parser accepts only actor-body placement. A transaction-level or
  rule-level handshake form is not a shipped construct.
- The accepted parser shape today is a scalar handshake name plus one or more
  scalar `(valid signal)` or `(ready signal)` properties. Duplicate property
  keys inside the same clause fail before actor-shell return. Unsupported
  property names, nested property signals, and nested names fail before
  actor-shell return.
- The implementation does not currently prove that both `valid` and `ready`
  are present, and duplicate handshake names are not diagnosed because
  handshakes are not retained. Those are policy gaps for
  `ISF-COMPATIBILITY.2`.

Current lowering behavior:

- `FSM::Scheduler::ISF::LoweringIR` does not consume
  `actor->{handshakes}`. Since the parser leaves that hash empty, the old
  handshake metadata has no scheduled `.fsm`, schedule JSON, generated HDL, or
  strict-mode semantics.
- Entry states still get the scheduler-created `can_accept` assignment. That
  is independent of any old `(handshake ...)` clause and is the current
  activation model together with direct `(on port ...)`.

Current diagnostics and tests:

- [t/1178-isf-handshake-compatibility-boundary.t](../../t/1178-isf-handshake-compatibility-boundary.t)
  proves a well-formed deprecated handshake clause is validated, discarded,
  and still lowers in-process.
- The same test proves malformed handshake names, missing properties,
  unsupported properties, duplicate properties, and nested property signals
  fail before actor-shell return with bounded scalar diagnostics.
- There is no dedicated CLI or strict-mode parity test for handshake
  compatibility today. That should be decided with the final handshake policy,
  not inferred from the current in-process boundary alone.

Current docs and contract:

- [docs/ISF_SPEC.md](../ISF_SPEC.md) says deprecated handshake metadata is
  structurally validated and ignored, and that direct `(on port ...)` plus
  scheduler-created `can_accept` is the current model.
- The mdBook feature backlog lists old handshake semantics as backlog or a
  removal candidate.
- `embedding.isf_public_interface` includes
  `t/1178-isf-handshake-compatibility-boundary.t` in `tested_by`, but the
  bounded actor-shell public contract does not freeze a populated handshake
  metadata shape.

### Removed transaction `(assign ...)`

Current parser behavior:

- `FSM::Adapter::ISF::Parser` stores transaction clauses as raw clause arrays
  after validating only transaction name and the currently special
  phase/stage boundaries. It does not reject `(assign ...)` at parse time.
- This means `(assign ...)` can appear in parser output as private scheduler
  input, but it is not a public supported transaction clause.

Current lowering behavior:

- `FSM::Scheduler::ISF::LoweringIR` owns transaction clause support through
  `%SUPPORTED_TRANSACTION_CLAUSES`.
- `assign` is not in the allowed set for top-level transaction bodies, `when`
  bodies, `switch` branches, or `repeat` bodies.
- Lowering therefore fails closed with
  `Transaction '<name>': unsupported '(assign ...)' clause in <context>`.
- The same unsupported-clause path also rejects future unknown transaction
  keywords, while more specific stage/contract diagnostics still take
  precedence where those clauses are recognized but malformed.

Current diagnostics and tests:

- [t/1180-isf-unsupported-transaction-clause-boundary.t](../../t/1180-isf-unsupported-transaction-clause-boundary.t)
  proves top-level removed `(assign ...)` fails closed during lowering.
- The same test proves nested `(assign ...)` in a `when` body fails with
  context-specific diagnostics, and that unrelated future unknown keywords
  use the same unsupported-clause mechanism.
- No migration-specific diagnostic exists yet. The current diagnostic says the
  clause is unsupported; it does not recommend `(update ...)`, rule
  assignment, a drive, or another replacement.

Current docs and contract:

- [docs/ISF_SPEC.md](../ISF_SPEC.md) lists removed `(assign ...)` as
  explicitly deferred and says authored uses fail closed as unsupported
  transaction clauses.
- The mdBook feature backlog keeps removed assign as a removal/deferred
  compatibility item.
- The public tested-by metadata includes the unsupported transaction clause
  regression, but the public contract does not advertise a replacement
  construct for the old keyword.

## ISF-COMPATIBILITY.2 Legacy Handshake Policy

Decision: keep actor-level `(handshake ...)` as deprecated compatibility input
for now, but keep it explicitly non-semantic.

Selected policy:

- Do not add old handshake lowering semantics. Direct `(on port ...)`
  activation plus scheduler-generated `can_accept` remains the current
  transaction activation model.
- Do not copy old handshake metadata into `LoweringIR`, schedule JSON,
  generated `.fsm`, generated composition tops, or HDL.
- Keep accepted default behavior for well-formed legacy source so existing
  compatibility inputs continue to parse and lower.
- Tighten the accepted shape during the implementation leaf: a retained
  compatibility handshake clause should require exactly one scalar `valid`
  property and exactly one scalar `ready` property, and duplicate handshake
  names should fail before actor-shell return.
- Leave the actor-shell `handshakes` value as an empty compatibility
  placeholder. A populated public handshake metadata shape is not part of the
  current public contract.
- Keep current ISF strict-mode behavior aligned with default source acceptance
  until an explicit ISF source-strictness policy exists. A future strict-source
  mode may choose to reject deprecated handshakes, but this tree will not make
  that broader strictness change.

Rationale:

- Reintroducing old handshake semantics would duplicate newer, clearer ISF
  constructs without a fresh runtime contract. A ready/valid barrier already
  has an explicit shipped subset through transaction `(stage name (input
  ready_signal) (output valid_signal))`.
- Silently accepting incomplete or duplicate ignored metadata is not useful
  compatibility. If the source is deprecated but still accepted, the accepted
  shape should be exact and diagnosable.
- Keeping the metadata ignored avoids adding new schedule-report and HDL
  surface area for a compatibility feature whose forward replacement is already
  clearer.

Migration guidance:

- Use `(on port ...)` for transaction activation.
- Use generated `can_accept` as the scheduler-created acceptance signal
  rather than authoring a legacy handshake-ready binding.
- Use transaction `(stage name (input ready_signal) (output valid_signal))`
  when the intended behavior is a ready/valid barrier.
- Use rules, drives, or explicit transaction clauses for protocol-valid output
  behavior instead of expecting `(handshake ...)` to drive signals.

Implementation work left for `ISF-COMPATIBILITY.4`:

- Require both `valid` and `ready` properties in `_parse_handshake`.
- Reject duplicate handshake names before actor-shell return while still
  leaving `actor->{handshakes}` empty.
- Add migration guidance to malformed-handshake diagnostics where it helps
  without making error strings noisy.
- Add CLI/strict parity coverage in the final test/docs leaf if the current
  CLI behavior remains accepted.

## ISF-COMPATIBILITY.3 Removed Transaction Assign Policy

Decision: keep transaction `(assign ...)` removed and rejected.

Selected policy:

- Do not reintroduce `(assign ...)` as a transaction clause.
- Do not silently map `(assign ...)` to `(update ...)`, `(drive ...)`, rule
  assignment, or `(complete ...)`. The old keyword does not encode enough
  timing intent to choose one safely.
- Keep parser behavior as-is for now: the parser may carry raw transaction
  clauses as private scheduler input, and the scheduler owns the fail-closed
  unsupported-clause boundary.
- Replace the generic unsupported-clause diagnostic for `assign` with a
  migration-specific diagnostic during the implementation leaf.
- Keep nested-context rejection. `(assign ...)` should be rejected in top-level
  transaction bodies and inside `when`, `switch`, or `repeat` bodies.

Rationale:

- ISF now has more explicit constructs for the common meanings an old
  `assign` might have had. `(update var expr)` names a transaction-local
  flopped state update. `(drive name ...)` names output/protocol drive
  behavior. Rule actions name rule-driven assignments. `(complete port)` names
  terminal completion behavior.
- An automatic mapping would be ambiguous and could silently change timing.
  Hardware intent should state whether the target is a persistent update, a
  protocol/output drive, a rule-side action, or a completion pulse.
- Keeping the rejection in the scheduler preserves the current parser shell
  boundary while still failing before scheduled `.fsm` emission.

Migration guidance:

- Use `(update var expr)` for transaction-local flopped data/state updates.
- Use a named or inline `(drive ...)` for protocol/output driving behavior.
- Use rule `(port expr)` actions for rule-driven assignments.
- Use `(complete port)` when the old intent was transaction completion.
- If a future need appears for transaction-local combinational assignment, it
  should be introduced as an explicit new construct with documented timing
  semantics rather than reviving the ambiguous `assign` keyword.

Implementation work left for `ISF-COMPATIBILITY.4`:

- Add a targeted `assign` rejection in `_validate_supported_transaction_clauses`
  before the generic unsupported-clause path.
- Include concise migration wording in the diagnostic without making every
  unknown future keyword verbose.
- Preserve existing context labels such as `transaction body`, `when body`,
  `switch branch`, and `repeat body`.

## ISF-COMPATIBILITY.4 Implementation

Implemented behavior:

- `_parse_handshake` now requires the retained compatibility shape to have a
  scalar name plus exactly one scalar `(valid signal)` and one scalar
  `(ready signal)` property.
- Duplicate legacy handshake names now fail before actor-shell return, while
  the returned actor shell still leaves `handshakes => {}` as an empty
  compatibility placeholder.
- Missing `valid`/`ready` properties now produce migration guidance that points
  authors to `(on ...)` activation or transaction `(stage ...)` for
  ready/valid behavior.
- Removed transaction `(assign ...)` now has a targeted scheduler diagnostic
  before the generic unsupported-clause path. The message preserves the
  context label and points authors to `(update var expr)`, `(drive ...)`, rule
  `(port expr)` actions, or `(complete port)`.
- Unknown future transaction keywords still use the generic unsupported-clause
  diagnostic.

Regression coverage:

- [t/1178-isf-handshake-compatibility-boundary.t](../../t/1178-isf-handshake-compatibility-boundary.t)
  now covers missing `ready` and duplicate handshake name rejection in
  addition to the retained accepted/ignored compatibility path.
- [t/1180-isf-unsupported-transaction-clause-boundary.t](../../t/1180-isf-unsupported-transaction-clause-boundary.t)
  now covers the targeted removed-assign diagnostic in transaction, `when`,
  `switch`, and `repeat` contexts while preserving generic diagnostics for
  unrelated unsupported keywords.

## ISF-COMPATIBILITY.5 Closure

Closure state:

- Deprecated actor-level `(handshake ...)` remains accepted but ignored
  compatibility input when it has exactly one scalar `valid` and one scalar
  `ready` property.
- Duplicate handshake names fail before actor-shell return.
- The public actor shell still does not expose populated handshake metadata;
  `handshakes => {}` is a private compatibility placeholder, not a stable
  public surface.
- Removed transaction `(assign ...)` remains rejected in top-level
  transaction bodies and nested `when`, `switch`, and `repeat` contexts.
- The removed-assign diagnostic now carries migration guidance; unrelated
  unsupported transaction keywords still use the generic unsupported-clause
  diagnostic.
- CLI schedule-report and strict-HDL paths now have parity coverage for
  accepted ignored handshake compatibility input.
- CLI failure now has parity coverage for the removed-assign migration
  diagnostic.

Public contract and tier sync:

- [t/1229-isf-compatibility-cli-parity.t](../../t/1229-isf-compatibility-cli-parity.t)
  is part of the ISF regression tier.
- `embedding.isf_public_interface.tested_by` now advertises the new parity
  test through `FSM::Support::ISFPublicInterfaceContract`.
- [t/1183-ci-regression-tier-selection.t](../../t/1183-ci-regression-tier-selection.t)
  asserts the ISF tier includes the compatibility parity regression.
- The ISF spec, mdBook backlog, roadmap, and live docs describe the closed
  compatibility policy and remaining future-only question.

## Decisions

- `2026-05-14`: Legacy handshake and removed transaction `assign` are tracked
  together because both are compatibility surfaces whose policy should be
  explicit before further ISF feature widening.
- `2026-05-14`: The inventory leaf does not decide policy. It records that
  handshake is currently validated-ignored compatibility input and `assign`
  is currently a fail-closed scheduler rejection, with both decisions left for
  the next policy leaves.
- `2026-05-14`: Legacy `(handshake ...)` remains accepted but ignored
  compatibility input. It will not gain lowering semantics; implementation
  should tighten shape validation and diagnostics while leaving the public
  actor-shell handshake metadata unpopulated.
- `2026-05-14`: Removed transaction `(assign ...)` stays rejected. It will not
  be auto-mapped because its timing intent is ambiguous; diagnostics should
  direct authors to explicit constructs such as `(update ...)`, `(drive ...)`,
  rule actions, or `(complete ...)`.
- `2026-05-14`: Compatibility diagnostics are now policy-backed. Handshake
  compatibility accepts only the exact retained shape, duplicate names fail,
  and removed transaction `assign` reports a targeted migration diagnostic.

## Open Questions

- Whether a future transaction-local combinational construct is needed; that
  should be a new feature request with explicit timing semantics, not a
  compatibility revival of `(assign ...)`.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-COMPATIBILITY` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-COMPATIBILITY.1` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `prove -l t/1178-isf-handshake-compatibility-boundary.t t/1180-isf-unsupported-transaction-clause-boundary.t`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-COMPATIBILITY.2` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-COMPATIBILITY.3` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-COMPATIBILITY.4` | Syntax checks for changed Perl modules and focused tests; `prove -l t/1178-isf-handshake-compatibility-boundary.t t/1180-isf-unsupported-transaction-clause-boundary.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-COMPATIBILITY.5` | Syntax checks for changed tests and contract module; `prove -l t/1178-isf-handshake-compatibility-boundary.t t/1180-isf-unsupported-transaction-clause-boundary.t t/1183-ci-regression-tier-selection.t t/1229-isf-compatibility-cli-parity.t t/1112-isf-public-interface-contract.t t/1144-isf-public-tested-by-metadata-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-COMPATIBILITY` | `R14: map ISF objectives to task trees` | Initial tree creation belongs to the ISF objective task-tree coverage slice. |
| `ISF-COMPATIBILITY.1` | `ISF-COMPATIBILITY.1: inventory legacy surfaces` | Inventory of deprecated handshake validation/ignored behavior and removed assign fail-closed lowering. |
| `ISF-COMPATIBILITY.2` | `ISF-COMPATIBILITY.2: decide handshake policy` | Keep handshake as accepted ignored compatibility input, tighten validation, and point authors to `on`, `can_accept`, and transaction stages. |
| `ISF-COMPATIBILITY.3` | `ISF-COMPATIBILITY.3: decide removed assign policy` | Keep transaction `assign` rejected and point authors to explicit replacement constructs. |
| `ISF-COMPATIBILITY.4` | `ISF-COMPATIBILITY.4: enforce compatibility diagnostics` | Tightened handshake compatibility validation and targeted removed-assign migration diagnostics. |
| `ISF-COMPATIBILITY.5` | `ISF-COMPATIBILITY.5: close compatibility surface` | CLI/strict parity coverage, public contract provenance, docs, live status, and tree closure. |

## Changelog

- `2026-05-14`: Created the active ISF compatibility-surface task tree.
- `2026-05-14`: Added the current legacy handshake and removed assign
  behavior inventory.
- `2026-05-14`: Decided the legacy handshake policy.
- `2026-05-14`: Decided the removed transaction `assign` policy.
- `2026-05-14`: Implemented selected compatibility validation and diagnostics.
- `2026-05-14`: Added CLI/strict parity coverage, synchronized public
  contract provenance, and closed the compatibility tree.
