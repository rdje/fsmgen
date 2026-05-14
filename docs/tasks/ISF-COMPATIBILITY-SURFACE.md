# ISF-COMPATIBILITY: Legacy Handshake And Removed Assign Surface

## Metadata

- Tree ID: `ISF-COMPATIBILITY`
- Status: `active`
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
  Status: `active`
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
  Status: `pending`
  Goal: `Decide legacy handshake policy.`
  Acceptance: `The tree records whether the handshake metadata remains ignored,
  gains semantics, becomes rejected, or gets a migration path, with rationale.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-COMPATIBILITY.3`
  Status: `pending`
  Goal: `Decide removed transaction assign policy.`
  Acceptance: `The tree records whether transaction assign stays rejected, gains a
  replacement, or maps to another construct, with migration diagnostics.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-COMPATIBILITY.4`
  Status: `pending`
  Goal: `Implement selected compatibility diagnostics or semantics.`
  Acceptance: `The selected policy is enforced consistently across parser,
  scheduler, CLI, and in-process facades.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-COMPATIBILITY.5`
  Status: `pending`
  Goal: `Add tests and synchronize docs/contracts.`
  Acceptance: `Focused tests and docs cover compatibility policy, rejected
  cases, migration hints, and public contract wording.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-COMPATIBILITY.2` | `pending` | The inventory shows handshake metadata is validated then ignored; the next slice should decide whether that remains intentional. |

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

## Decisions

- `2026-05-14`: Legacy handshake and removed transaction `assign` are tracked
  together because both are compatibility surfaces whose policy should be
  explicit before further ISF feature widening.
- `2026-05-14`: The inventory leaf does not decide policy. It records that
  handshake is currently validated-ignored compatibility input and `assign`
  is currently a fail-closed scheduler rejection, with both decisions left for
  the next policy leaves.

## Open Questions

- Is keeping `(handshake ...)` as validated ignored metadata still useful, or
  should it become a strict rejection with migration guidance?
- Should transaction `(assign ...)` remain removed permanently, or should a
  new explicit construct replace its original intent?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-COMPATIBILITY` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-COMPATIBILITY.1` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `prove -l t/1178-isf-handshake-compatibility-boundary.t t/1180-isf-unsupported-transaction-clause-boundary.t`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-COMPATIBILITY` | `R14: map ISF objectives to task trees` | Initial tree creation belongs to the ISF objective task-tree coverage slice. |
| `ISF-COMPATIBILITY.1` | `ISF-COMPATIBILITY.1: inventory legacy surfaces` | Inventory of deprecated handshake validation/ignored behavior and removed assign fail-closed lowering. |

## Changelog

- `2026-05-14`: Created the active ISF compatibility-surface task tree.
- `2026-05-14`: Added the current legacy handshake and removed assign
  behavior inventory.
