# ISF-REPEAT-BODY-CHILD-ACTIVATION: Repeat-Body Child Activation Widening

## Metadata

- Tree ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-17`
- Last updated: `2026-05-17`
- Owner: repo-local workflow

## Goal

Track and ship the remaining repeat-body child activation surfaces after the
closed plain-spawn and static-parameter repeat-spawn subsets.

## Non-Goals

- Reopening already-shipped plain repeat-body spawn behavior.
- Reopening already-shipped repeat-body spawn static `(params ...)` behavior.
- Changing top-level spawn, top-level `do`, top-level `await_all`, or
  top-level `await_any` behavior outside repeat bodies unless a leaf explicitly
  selects that dependency.
- Bundling multiple repeat-body activation semantics into one implementation
  leaf without a bounded contract and focused validation.

## Acceptance Criteria

- Each future repeat-body child activation widening is selected as a bounded
  leaf before implementation.
- The source contract, generated-top wiring, re-entry semantics,
  fail-closed diagnostics, schedule/report visibility, and mdBook behavior are
  documented before or with implementation.
- Unsupported repeat-body child activation forms remain fail-closed until
  their own leaf ships.
- The ISF spec, downstream handoff, public contract, mdBook, roadmap, live
  docs, and focused tests stay synchronized for any shipped behavior.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION`
  Status: `active`
  Goal: `Ship remaining repeat-body child activation subsets safely.`
  Children: `ISF-REPEAT-BODY-CHILD-ACTIVATION.1`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.2`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.3`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.4`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.5`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.6`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.7`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.8`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.9`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.10`, `ISF-REPEAT-BODY-CHILD-ACTIVATION.11`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.1`
  Status: `done`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog identify the selected leaf, source shape, exclusions, and validation plan.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.1: select repeat spawn bindings`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.2`
  Status: `done`
  Goal: `Ship repeat-body spawn port bindings if selected.`
  Acceptance: `Top-level repeat bodies accept '(spawn child as inst [(params ...)] (bind ...))' only when the same repeat body reaches '(await_all done)' before the repeat check can loop; input and output bindings reuse the shipped static generated-child handoff model, generated-top wiring, diagnostics, docs, and tests while domain overrides, await_any, repeat-body do, nested activation, and sample-after-spawn remain deferred.`
  Verification: `syntax checks; focused repeat/spawn/port-binding/doc tests; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.2: implement repeat spawn bindings`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.3`
  Status: `done`
  Goal: `Ship repeat-body spawn domain overrides if selected.`
  Acceptance: `Repeat-body spawn '(domain NAME)' is accepted only as declared same-domain ownership metadata on the existing top-level repeat plus same-body await_all static-instance subset; omitted domain annotations inherit the owning transaction domain, cross-domain activation and undeclared domains fail closed, and docs/tests/report metadata prove that no CDC behavior is implied.`
  Verification: `syntax checks; focused repeat/spawn/domain/doc tests; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.3: implement repeat spawn domains`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.4`
  Status: `done`
  Goal: `Ship repeat-body await_any semantics if selected.`
  Acceptance: `Repeat-body '(await_any done)' is accepted only when exactly one repeat-body spawn is pending, making its re-entry semantics equivalent to waiting for that one static child instance before the repeat check can loop; zero-pending and multi-pending await_any fail closed, and broader outstanding-child lifetime semantics remain deferred.`
  Verification: `syntax checks; focused repeat/spawn/await-any/doc tests; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.4: implement repeat await_any`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.5`
  Status: `done`
  Goal: `Ship repeat-body blocking do activation if selected.`
  Acceptance: `Top-level repeat bodies accept local '(do child)' only when the child transaction remains local to the scheduled parent; the do state waits for the child's fresh done pulse before the repeat check can loop, local start/done wiring is installed for repeat-body do targets, and generated/parameterized/bound/domain-qualified repeat-body do, nested repeat-body do, cross-domain activation, and sample-before/after-do timing remain fail-closed with docs/tests.`
  Verification: `syntax checks; focused repeat/do/doc tests; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.5: implement repeat local do`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.6`
  Status: `done`
  Goal: `Ship repeat-body sample-after-spawn timing if selected.`
  Acceptance: `Top-level repeat bodies accept samples after repeat-body spawn only when the same body still reaches await_all or single-pending await_any before the repeat check can loop; pending samples materialize in an explicit sample state before the sync state, spawn-after-sample and sample-before/after-do remain fail-closed, and docs/tests show the exact timing.`
  Verification: `syntax checks; focused repeat/spawn/sample/doc tests; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.6: implement repeat spawn samples`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.7`
  Status: `done`
  Goal: `Select the next repeat-body generated blocking-do subset.`
  Acceptance: `Task tree, roadmap, and book backlog select repeat-body generated blocking '(do child (params ...))' as the next bounded implementation; the selected contract is top-level repeat-body only, static parameter overrides only, no repeat-body bind or domain subclauses, no cross-domain activation, no nested branch/loop placement, and no multi-pending await_any widening.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.7: select repeat generated do`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.8`
  Status: `done`
  Goal: `Ship repeat-body generated blocking do with static parameter overrides if selected.`
  Acceptance: `Top-level repeat bodies accept '(do child (params ...))' when the generated child instance is static and the do state waits for that instance's fresh done pulse before the repeat check can loop; the generated top emits one generated do instance and parameter binding for the lexical do site; repeat-body '(bind ...)', '(domain NAME)', generated-child targets not owned by this selected do site, sample-before/after-do timing, nested placement, cross-domain activation, and multi-pending await_any remain fail-closed.`
  Verification: `syntax checks; focused repeat/do/generated-composition/doc tests; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.8: implement repeat generated do params`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.9`
  Status: `done`
  Goal: `Select the next repeat-body generated do binding subset.`
  Acceptance: `Task tree, roadmap, and book backlog select top-level repeat-body generated blocking '(do child (params ...) (bind ...))' as the next bounded implementation; the selected contract reuses the static generated do instance from the parameter subset, adds generated-top input/output binding handoffs once for that lexical do site, and keeps repeat-body domain metadata, nested placement, cross-domain activation, multi-pending await_any, plain generated-child local do targets, and sample-before/after-do timing deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.9: select repeat generated do bindings`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.10`
  Status: `done`
  Goal: `Ship repeat-body generated blocking do with static parameter overrides and port bindings if selected.`
  Acceptance: `Top-level repeat bodies accept '(do child (params ...) (bind ...))' when the generated do instance is static, binding handoff ports are emitted once in the generated top for the lexical do site, input/output binding provenance is visible in reports, and the do state still waits for the generated instance's fresh done handoff before the repeat check can loop; repeat-body '(domain NAME)', nested placement, cross-domain activation, multi-pending await_any, plain generated-child local do targets, and sample-before/after-do timing remain fail-closed.`
  Verification: `syntax checks; focused repeat/do/binding/generated-composition/doc tests; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-REPEAT-BODY-CHILD-ACTIVATION.10: implement repeat generated do bindings`

- ID: `ISF-REPEAT-BODY-CHILD-ACTIVATION.11`
  Status: `pending`
  Goal: `Select the next repeat-body child activation subset.`
  Acceptance: `Task tree, roadmap, and book backlog select the next bounded implementation after repeat-body generated do bindings; remaining candidates include repeat-body do domain metadata, plain local do targeting already generated children, nested placement, cross-domain activation, multi-pending await_any, sample-before/after-do timing, and spawn-after-sample ordering.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.1` | `done` | Selected repeat-body spawn port bindings as the next bounded implementation subset. |
| 2 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.2` | `done` | Shipped repeat-body spawn port-binding handoffs on the top-level repeat plus same-body `await_all` path. |
| 3 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.3` | `done` | Shipped repeat-body spawn same-domain ownership annotations without implying CDC behavior. |
| 4 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.4` | `done` | Shipped repeat-body await_any for the exactly-one-pending-spawn subset. |
| 5 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.5` | `done` | Shipped repeat-body local blocking `do` with local child start/done re-entry proof. |
| 6 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.6` | `done` | Shipped repeat-body sample-after-spawn timing before same-body sync. |
| 7 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.7` | `done` | Selected repeat-body generated blocking `do` with static parameter overrides as the next bounded subset. |
| 8 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.8` | `done` | Shipped repeat-body generated blocking `do` with static parameter overrides. |
| 9 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.9` | `done` | Selected repeat-body generated blocking `do` with static parameter overrides and port bindings. |
| 10 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.10` | `done` | Shipped repeat-body generated blocking `do` with static parameter overrides and port bindings. |
| 11 | `ISF-REPEAT-BODY-CHILD-ACTIVATION.11` | `pending` | Selects the next remaining repeat-body activation subset. |

## Decisions

- `2026-05-17`: This proposed tree owns the remaining repeat-body child
  activation backlog that is not covered by the closed
  `ISF-SPAWN-IN-REPEAT` and `ISF-REPEAT-SPAWN-PARAMS` trees.
- `2026-05-17`: No remaining repeat-body activation surface is PNT-ready for
  implementation until leaf `.1` selects the exact next subset.
- `2026-05-17`: The repository workflow now makes task-tree ownership a
  precondition before any future code, test, source, generated-artifact, or
  config change.
- `2026-05-17`: Leaf `.1` selects repeat-body spawn port bindings as the next
  implementation subset. The selected source shape is top-level
  `(repeat count (spawn child as inst [(params ...)] (bind ...)) ... (await_all done))`.
  The binding model remains static: the lexical spawn name denotes one
  generated child instance, binding payload ports are generated once in the
  composition top, and repeat iterations reuse that instance.
- `2026-05-17`: Repeat-body spawn `(domain ...)`, `await_any`, repeat-body
  `do`, nested branch/loop activation, and sample-after-spawn timing remain
  deferred after the binding selection.
- `2026-05-17`: Leaf `.2` shipped repeat-body spawn `(bind ...)` for top-level
  repeat bodies that reach same-body `(await_all done)` before the repeat check.
  Validation now covers generated parent handoff metadata, generated-top
  wiring, schedule-report `transaction_port_bindings[]` provenance, and
  fail-closed validation for missing/invalid repeat-body bindings.
- `2026-05-17`: Leaf `.3` is bounded to same-domain repeat-body spawn
  `(domain NAME)` annotations on the existing static-instance plus same-body
  `await_all` subset. The annotation selects declared ownership metadata only;
  it does not ship cross-domain activation, CDC handoff, or relaxed binding
  rules.
- `2026-05-17`: Leaf `.3` shipped repeat-body spawn `(domain NAME)` on the
  existing top-level repeat plus same-body `await_all` subset. Declared
  same-domain annotations are preserved in generated-child metadata and
  `clock_domains[].child_instances[]`; undeclared domains and cross-domain
  activation remain fail-closed.
- `2026-05-17`: Leaf `.4` is bounded to the single-pending-spawn
  repeat-body `await_any` subset. Multi-pending `await_any` would leave
  outstanding static children across the repeat back-edge, so it remains
  fail-closed until a broader lifetime contract ships.
- `2026-05-17`: Leaf `.4` shipped repeat-body `(await_any done)` when exactly
  one repeat-body spawn is pending. Zero-pending and multi-pending repeat-body
  `await_any` remain fail-closed with targeted diagnostics.
- `2026-05-17`: Leaf `.5` is bounded to local blocking `(do child)` in a
  top-level repeat body. The child must remain in the parent scheduled module,
  the repeat body must wait on the child's fresh done pulse before the repeat
  check back-edge, and generated/parameterized/bound/domain-qualified
  repeat-body `do`, nested repeat-body `do`, cross-domain activation, and
  sample-before/after-do timing remain deferred.
- `2026-05-17`: Leaf `.5` shipped repeat-body local `(do child)` for the
  top-level repeat subset. Repeat-body local `do` uses parent-module
  start/done wiring and reaches the repeat check only after the child done
  pulse; generated/parameterized/bound/domain-qualified repeat-body `do`,
  generated-child targets, nested repeat-body `do`, cross-domain activation,
  and sample-before/after-do timing remain fail-closed.
- `2026-05-17`: Leaf `.6` is bounded to repeat-body sample-after-spawn timing.
  The selected source shape is top-level repeat-body spawn, then one or more
  samples, then same-body `await_all` or single-pending `await_any`; samples
  must materialize before the sync state so the timing is explicit, while
  spawn-after-sample and sample-before/after-do remain deferred.
- `2026-05-17`: Leaf `.6` shipped repeat-body sample-after-spawn timing for
  the top-level repeat subset. Pending samples after spawn now drain through
  an explicit sample state before same-body `await_all` or single-pending
  `await_any`; spawn-after-sample, sample-before/after-do, multi-pending
  `await_any`, nested activation, and cross-domain activation remain
  fail-closed.
- `2026-05-17`: Leaf `.7` selects repeat-body generated blocking `do` with
  static parameter overrides as the next implementation subset. The selected
  source shape is top-level repeat-body `(do child (params ...))`; it should
  reuse one generated child instance and wait for that instance's fresh done
  pulse before the repeat check. Repeat-body `(bind ...)`, `(domain NAME)`,
  nested placement, cross-domain activation, multi-pending `await_any`, and
  sample-before/after-do timing remain out of scope.
- `2026-05-17`: Leaf `.8` shipped repeat-body generated blocking
  `(do child (params ...))` for top-level repeat bodies. The generated do site
  owns one `{parent}_{child}_repeat_do_{ordinal}` instance, static parameter
  overrides are applied once in the generated top, and the repeat check is
  reachable only after the generated instance's fresh done handoff. Repeat-body
  do bindings, domain metadata, plain local do targeting an already generated
  child, nested placement, cross-domain activation, multi-pending `await_any`,
  and sample-before/after-do timing remained fail-closed at that leaf.
- `2026-05-17`: Leaf `.9` selects repeat-body generated blocking
  `(do child (params ...) (bind ...))` as the next implementation subset. The
  selected contract reuses the `.8` static generated do instance, adds
  generated-top input/output binding handoffs once for the lexical repeat-body
  do site, and keeps repeat-body `(domain NAME)`, nested placement,
  cross-domain activation, multi-pending `await_any`, plain generated-child
  local do targets, and sample-before/after-do timing out of scope.
- `2026-05-17`: Leaf `.10` shipped repeat-body generated blocking
  `(do child (params ...) (bind ...))` for top-level repeat bodies. The
  generated do site owns one `{parent}_{child}_repeat_do_{ordinal}` instance,
  static parameter overrides and input/output binding handoff ports are wired
  once in the generated top, schedule JSON reports the do-site binding
  provenance, and the repeat check is reachable only after the generated
  instance's fresh done handoff. Repeat-body `(domain NAME)`, plain local do
  targeting an already generated child, nested placement, cross-domain
  activation, multi-pending `await_any`, and sample-before/after-do timing
  remain fail-closed.

## Open Questions

- Which deferred repeat-body activation subset should follow: repeat-body do
  domain metadata, plain local do targeting already generated children, nested
  branch/loop activation, cross-domain activation, multi-pending `await_any`,
  or the remaining sample-ordering forms.

## Blockers

- None for tracking. Implementation leaves must resolve their own timing,
  generated-top, domain, and report contracts before shipping.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after task-tree gate policy sync` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.1` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.2` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused repeat/spawn/doc checks, adjacent port-binding/report checks, book build, full ISF gate, and diff check passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.3` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t t/1247-isf-clock-domain-partition.t`; `prove -l t/1204-isf-child-composition-clause-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused repeat/spawn/domain/doc checks, adjacent activation/binding/report checks, book build, full ISF gate, and diff check passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.4` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1203-isf-await-sync-clause-boundary.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused repeat/spawn/await-any/doc checks, book build, full ISF gate, and diff check passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.5` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused repeat/do/doc checks (Files=7, Tests=291), book build, full ISF gate (Files=227, Tests=1089), and diff check passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.6` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused repeat/spawn/sample/doc checks (Files=7, Tests=297), book build, full ISF gate (Files=227, Tests=1095), and diff check passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.7` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting repeat-body generated blocking do with static parameters` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.8` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused repeat/do/generated-composition/doc checks (Files=8, Tests=294), book build, full ISF gate (Files=227, Tests=1090), and diff check passed` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.9` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed after selecting repeat-body generated blocking do bindings` |
| `2026-05-17` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.10` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -l t/1215-isf-spawn-parameter-binding.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1203-isf-await-sync-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `syntax, focused repeat/do/binding/generated-composition/doc checks (Files=11, Tests=305), book build, full ISF gate (Files=227, Tests=1089), and diff check passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION` | `ISF-REPEAT-BODY-CHILD-ACTIVATION: track repeat activation backlog` | `e942bfc6; proposed tracking tree created` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.1` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.1: select repeat spawn bindings` | `47715e55; selected repeat-body spawn binding subset` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.2` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.2: implement repeat spawn bindings` | `0bc68c85; repeat-body spawn binding handoffs shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.3` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.3: implement repeat spawn domains` | `027c3d1b; repeat-body spawn same-domain metadata shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.4` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.4: implement repeat await_any` | `2d349f08; single-pending repeat-body await_any shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.5` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.5: implement repeat local do` | `repeat-body local blocking do shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.6` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.6: implement repeat spawn samples` | `repeat-body sample-after-spawn timing shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.7` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.7: select repeat generated do` | `selected repeat-body generated blocking do with static parameters` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.8` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.8: implement repeat generated do params` | `repeat-body generated blocking do static parameters shipped` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.9` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.9: select repeat generated do bindings` | `selected repeat-body generated blocking do bindings` |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION.10` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.10: implement repeat generated do bindings` | `repeat-body generated blocking do binding handoffs shipped` |

## Changelog

- `2026-05-17`: Created proposed task tree so the remaining repeat-body child
  activation backlog has explicit task-tree ownership before future code work.
- `2026-05-17`: Strengthened the surrounding workflow docs so the task-tree
  preflight is mandatory for all future implementation work, not only this ISF
  backlog.
- `2026-05-17`: Activated the tree and selected repeat-body spawn
  `(bind ...)` as the next bounded implementation leaf.
- `2026-05-17`: Shipped repeat-body spawn `(bind ...)` on the existing
  top-level repeat plus same-body `await_all` subset.
- `2026-05-17`: Shipped repeat-body spawn `(domain NAME)` as declared
  same-domain ownership metadata on the same static-instance subset.
- `2026-05-17`: Shipped repeat-body `(await_any done)` for the exactly-one
  pending spawn subset while keeping broader outstanding-child semantics
  deferred.
- `2026-05-17`: Shipped repeat-body local `(do child)` for top-level repeat
  bodies while keeping generated/parameterized/bound/domain-qualified and
  sample-before/after-do forms deferred.
- `2026-05-17`: Shipped repeat-body sample-after-spawn timing before
  same-body `await_all` or single-pending `await_any`, while keeping
  spawn-after-sample ordering and broader outstanding-child forms deferred.
- `2026-05-17`: Selected repeat-body generated blocking `do` with static
  parameter overrides as the next bounded implementation subset.
- `2026-05-17`: Shipped repeat-body generated blocking `do` with static
  parameter overrides, while keeping generated-do binding handoffs, domain
  metadata, and broader outstanding-child forms deferred at that leaf.
- `2026-05-17`: Selected repeat-body generated blocking `do` bindings as the
  next bounded implementation subset.
- `2026-05-17`: Shipped repeat-body generated blocking `do` bindings for the
  top-level static-parameter subset, with generated-top handoff ports,
  report-visible do-site binding provenance, and done-gated repeat re-entry.
