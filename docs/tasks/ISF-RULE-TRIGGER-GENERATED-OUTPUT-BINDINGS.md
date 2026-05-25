# ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS: Generated Rule-Trigger Output Bindings

## Metadata

- Tree ID: `ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Allow rule-trigger output bindings for generated-child transaction trigger
instances when the scheduler has a unique per-trigger instance and completion
observation signal. A rule should be able to trigger a generated child, bind an
output port to a scalar actor signal, and have the copy occur only when that
generated trigger instance completes, without making the rule wait in-line for
the child.

## Non-Goals

- Do not add direct/local transaction rule-trigger output bindings in this
  tree. Local transaction triggers still share one target transaction instance
  and need a separate completion-identity contract before output copies can be
  unambiguous.
- Do not add an awaited-rule syntax, callback syntax, or a new transaction
  composition form.
- Do not add explicit snapshot-vs-live timing syntax for input bindings.
- Do not allow expression-valued output targets; generated rule-trigger output
  bindings target scalar actor signals only.
- Do not change parser shape for activation `(bind ...)` blocks.
- Do not bump the schedule-report schema version or expose raw `LoweringIR`
  assignment internals.

## Acceptance Criteria

- Generated-child rule triggers accept output bindings for declared output
  ports when the target actor signal exists, is writable, is same-domain, and
  width-matches the child output port.
- The output copy is guarded by the unique generated trigger instance
  completion observation, not by the rule predicate and not by the trigger
  pulse.
- Existing generated rule-trigger input payload binding behavior is preserved.
- Direct/local transaction rule-trigger output bindings continue to fail
  closed with a targeted diagnostic until a later task tree selects a safe
  completion-identity contract.
- Schedule reports and public contract metadata remain bounded and accurately
  describe generated rule-trigger output bindings without exposing private
  lowering structures.
- The ISF spec, downstream handoff, mdBook, roadmap, README index, task tree,
  and live docs are synchronized with the shipped behavior.
- Focused parser/lowering/report/public-contract tests prove accepted
  generated-child output bindings, rejected local/direct output bindings, and
  unchanged input-binding behavior.
- Broader ISF regression runs when warranted by the lowering/report blast
  radius.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS`
  Status: `done`
  Goal: `Ship generated-child rule-trigger output bindings through a
  per-trigger completion observation contract.`
  Children: `ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS.1`,
  `ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS.2`

- ID: `ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS.1`
  Status: `done`
  Goal: `Select the bounded generated-child rule-trigger output-binding
  contract.`
  Acceptance: `Task-tree ownership, acceptance criteria, implementation
  boundary, active frontier, roadmap status, README index, and live docs
  identify the generated-child rule-trigger output-binding slice before code
  changes.`
  Verification: `feature-backlog/live-book/book matrix audits; mdBook build; git diff --check`
  Commit: `ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS.1: select generated trigger output bindings`

- ID: `ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS.2`
  Status: `done`
  Goal: `Implement and document generated-child rule-trigger output
  bindings.`
  Acceptance: `Generated-child rule triggers lower output bindings through
  done-observed generated handoff copies; local/direct rule-trigger output
  bindings remain fail-closed; public docs, downstream handoff, reports, and
  tests are synchronized.`
  Verification: `syntax checks; focused public/report/spec/book tests; broad ISF regression; mdBook build; git diff --check`
  Commit: `ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS.2: lower generated trigger output bindings`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| `_None_` | `_None_` | `_None_` | Tree closed. |

## Decisions

- `2026-05-25`: Select generated-child rule triggers first because each rule
  trigger owns a unique generated instance and already has a distinct
  completion observation signal. That gives output copies an unambiguous
  source transaction instance without making the rule wait in-line.
- `2026-05-25`: Keep direct/local transaction rule-trigger output bindings
  deferred. A local transaction target has one shared transaction instance and
  one shared done pulse, so a future task must first select how to associate a
  completion with the rule trigger that requested it.
- `2026-05-25`: Preserve the existing activation binding syntax. The parser
  already recognizes `output` bind roles for rule triggers; this tree owns the
  bounded lowering and public contract change.
- `2026-05-25`: Implement generated rule-trigger output copies in the existing
  generated trigger handoff DT and guard each copy with the per-trigger
  `*_done_seen` observer. This keeps the rule non-blocking while giving the
  binding a concrete completion identity.
- `2026-05-25`: Report `done_signal` as the per-trigger done-observer signal
  for generated rule-trigger output entries. Local/direct rule-trigger input
  entries and generated rule-trigger input entries keep non-applicable
  completion fields as `null`.

## Open Questions

- None for the current frontier. Direct/local rule-trigger output bindings are
  deliberately out of scope for this tree, not a blocker.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `git diff --check` | `pass` |
| `2026-05-25` | `ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS.2` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1248-isf-rule-trigger-parameter-binding.t`; `perl -Iperl -c t/1242-isf-port-binding-conflict-semantics.t`; `perl -Iperl -c t/1241-isf-transaction-port-bindings.t`; `prove -Iperl t/1248-isf-rule-trigger-parameter-binding.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1140-isf-public-schedule-report-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1255-isf-schedule-report-golden-matrix.t t/1250-isf-spec-focused-test-index-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1256-feature-backlog-status-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS.1` | `ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS.1: select generated trigger output bindings` | `selection commit` |
| `ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS.2` | `ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS.2: lower generated trigger output bindings` | `completion commit` |

## Changelog

- `2026-05-25`: Created active task tree and selected the bounded
  generated-child rule-trigger output-binding contract. The next frontier is
  implementation and documentation synchronization.
- `2026-05-25`: Completed `ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS.2` and
  closed the tree.
