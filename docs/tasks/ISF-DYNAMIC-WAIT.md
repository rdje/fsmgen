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
  Status: `done`
  Goal: `Implement statically resolved symbolic wait counts.`
  Acceptance: `(wait NAME)` accepts only names that resolve before lowering to
  non-negative integer constants, lowers exactly like the existing literal
  count surface, preserves transparent zero-count behavior, rejects unknown or
  non-integer symbols with targeted diagnostics, updates reports/docs/tests,
  and reaches SystemVerilog generation.
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1244-isf-wait-clause-lowering.t`; `prove -Iperl t/1244-isf-wait-clause-lowering.t t/1116-isf-public-schedule-report-key-family-audit.t t/1131-isf-public-top-level-discovery-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-DYNAMIC-WAIT.2: ship symbolic waits`

- ID: `ISF-DYNAMIC-WAIT.3`
  Status: `active`
  Goal: `Implement runtime scalar dynamic wait counts.`
  Children: `ISF-DYNAMIC-WAIT.3.1`, `ISF-DYNAMIC-WAIT.3.2`,
  `ISF-DYNAMIC-WAIT.3.3`

- ID: `ISF-DYNAMIC-WAIT.3.1`
  Status: `done`
  Goal: `Specify the first executable runtime dynamic wait boundary.`
  Acceptance: The task tree, roadmap, mdBook backlog, ISF spec, and live docs
  state why runtime dynamic waits require predecessor-transition bypass, what
  the first implementation may accept, and which contexts must continue
  failing closed.
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-DYNAMIC-WAIT.3.1: split runtime waits`

- ID: `ISF-DYNAMIC-WAIT.3.2`
  Status: `done`
  Goal: `Implement first bounded runtime scalar wait lowering.`
  Acceptance: Runtime scalar counts with known unsigned width lower through an
  explicit counter plus predecessor-transition bypass for supported top-level
  contexts, preserve `count == 0` as no active wait cycle, snapshot the count
  on the predecessor edge for positive counts, report bounded dynamic-wait
  metadata, reject unsupported contexts, and reach SystemVerilog generation.
  Verification: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1244-isf-wait-clause-lowering.t`; `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1131-isf-public-top-level-discovery-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-DYNAMIC-WAIT.3.2: ship runtime scalar waits`

- ID: `ISF-DYNAMIC-WAIT.3.3`
  Status: `active`
  Goal: `Expand runtime dynamic wait contexts after the first lowering works.`
  Children: `ISF-DYNAMIC-WAIT.3.3.1`, `ISF-DYNAMIC-WAIT.3.3.2`,
  `ISF-DYNAMIC-WAIT.3.3.3`, `ISF-DYNAMIC-WAIT.3.3.4`,
  `ISF-DYNAMIC-WAIT.3.3.5`, `ISF-DYNAMIC-WAIT.3.3.6`

- ID: `ISF-DYNAMIC-WAIT.3.3.1`
  Status: `done`
  Goal: `Split the post-first-runtime expansion into executable leaves.`
  Acceptance: The task tree, roadmap, mdBook backlog, and live docs name the
  remaining runtime dynamic wait expansion families and identify the next
  implementation frontier.
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-DYNAMIC-WAIT.3.3.1: split dynamic wait expansion`

- ID: `ISF-DYNAMIC-WAIT.3.3.2`
  Status: `done`
  Goal: `Support consecutive top-level runtime scalar waits.`
  Acceptance: A dynamic wait may be followed immediately by another dynamic
  wait; the first wait's final sampled-counter edge must split into the second
  wait's zero-bypass and positive sampled-counter paths without rereading the
  first wait count or adding an active cycle.
  Verification: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `prove -Iperl t/1244-isf-wait-clause-lowering.t`; `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1131-isf-public-top-level-discovery-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-DYNAMIC-WAIT.3.3.2: support consecutive runtime waits`

- ID: `ISF-DYNAMIC-WAIT.3.3.3`
  Status: `done`
  Goal: `Support additional top-level predecessor kinds.`
  Acceptance: Runtime waits after `await`, `stage`, `repeat_check`,
  `sync_all`, and `sync_any` either lower through exact combined predecessor
  conditions and counter loads or remain fail-closed with targeted diagnostics
  and book coverage for each predecessor kind.
  Verification: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `prove -Iperl t/1244-isf-wait-clause-lowering.t`; `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1131-isf-public-top-level-discovery-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-DYNAMIC-WAIT.3.3.3: support dynamic wait predecessors`

- ID: `ISF-DYNAMIC-WAIT.3.3.4`
  Status: `done`
  Goal: `Support inline dynamic waits in branch and loop bodies.`
  Children: `ISF-DYNAMIC-WAIT.3.3.4.1`,
  `ISF-DYNAMIC-WAIT.3.3.4.2`, `ISF-DYNAMIC-WAIT.3.3.4.3`,
  `ISF-DYNAMIC-WAIT.3.3.4.4`, `ISF-DYNAMIC-WAIT.3.3.4.5`
  Acceptance: Dynamic waits inside shipped `when`, `switch`, `repeat`,
  `while`, and `until` bodies either preserve branch/loop exit semantics with
  exact zero-bypass behavior or remain fail-closed with targeted diagnostics
  and book coverage for each inline context.
  Verification: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `prove -Iperl t/1244-isf-wait-clause-lowering.t`; `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1131-isf-public-top-level-discovery-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-DYNAMIC-WAIT.3.3.4.5: support loop-body dynamic waits`

- ID: `ISF-DYNAMIC-WAIT.3.3.4.1`
  Status: `done`
  Goal: `Split inline dynamic wait expansion and lock the fail-closed matrix.`
  Acceptance: Tests and docs explicitly cover the current fail-closed behavior
  for dynamic waits in `when`, `switch`, `repeat`, `while`, and `until`
  bodies, including context-specific diagnostics, and the task tree identifies
  the next implementation leaves.
  Verification: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `prove -Iperl t/1244-isf-wait-clause-lowering.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-DYNAMIC-WAIT.3.3.4.1: split inline dynamic waits`

- ID: `ISF-DYNAMIC-WAIT.3.3.4.2`
  Status: `done`
  Goal: `Support dynamic waits in when bodies.`
  Acceptance: A runtime wait in a `when` body either lowers through the true
  branch's zero/positive split while preserving the false-branch skip, or
  remains fail-closed with narrower documented constraints.
  Verification: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `prove -Iperl t/1244-isf-wait-clause-lowering.t`; `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1131-isf-public-top-level-discovery-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-DYNAMIC-WAIT.3.3.4.2: support when-body dynamic waits`

- ID: `ISF-DYNAMIC-WAIT.3.3.4.3`
  Status: `done`
  Goal: `Support dynamic waits in repeat bodies.`
  Acceptance: A runtime wait in a `repeat` body either lowers with exact
  sampled-counter timing and repeat-check loop/exit preservation, or remains
  fail-closed with narrower documented constraints.
  Verification: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `prove -Iperl t/1244-isf-wait-clause-lowering.t`; `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1131-isf-public-top-level-discovery-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-DYNAMIC-WAIT.3.3.4.3: support repeat-body dynamic waits`

- ID: `ISF-DYNAMIC-WAIT.3.3.4.4`
  Status: `done`
  Goal: `Support dynamic waits in switch branches.`
  Acceptance: A runtime wait in a `switch` branch either lowers by splitting
  only that case's branch-entry or predecessor edge while preserving other
  case/default exits, or remains fail-closed with narrower documented
  constraints.
  Verification: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `prove -Iperl t/1244-isf-wait-clause-lowering.t`; `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1131-isf-public-top-level-discovery-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-DYNAMIC-WAIT.3.3.4.4: support switch-branch dynamic waits`

- ID: `ISF-DYNAMIC-WAIT.3.3.4.5`
  Status: `done`
  Goal: `Support dynamic waits in while/until bodies.`
  Acceptance: Runtime waits in loop bodies either lower while preserving
  loop-entry, loop-back, and loop-exit semantics, or remain fail-closed with
  narrower documented constraints.
  Verification: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `prove -Iperl t/1244-isf-wait-clause-lowering.t`; `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1131-isf-public-top-level-discovery-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-DYNAMIC-WAIT.3.3.4.5: support loop-body dynamic waits`

- ID: `ISF-DYNAMIC-WAIT.3.3.5`
  Status: `active`
  Goal: `Preserve pending samples across runtime dynamic wait bypass paths.`
  Children: `ISF-DYNAMIC-WAIT.3.3.5.1`,
  `ISF-DYNAMIC-WAIT.3.3.5.2`, `ISF-DYNAMIC-WAIT.3.3.5.3`,
  `ISF-DYNAMIC-WAIT.3.3.5.4`
  Acceptance: Pending-sample preservation, branch/switch/repeat/loop contexts,
  and zero/positive runtime wait paths either share one exact sample
  materialization contract or remain explicitly fail-closed with diagnostics
  and book coverage.
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-DYNAMIC-WAIT.3.3.5.1`
  Status: `done`
  Goal: `Specify and split pending-sample dynamic wait preservation.`
  Acceptance: The task tree, mdBook backlog, and live docs explain why
  preserving runtime-wait pending samples needs path-specific materialization,
  name the no-hidden-cycle invariant for `count == 0`, and split the
  implementation into executable leaves.
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-DYNAMIC-WAIT.3.3.5.1: split pending-sample preservation`

- ID: `ISF-DYNAMIC-WAIT.3.3.5.2`
  Status: `done`
  Goal: `Preserve pending samples for top-level runtime waits.`
  Acceptance: A top-level runtime wait preceded by pending samples preserves
  static-wait timing on the positive-count path and zero-wait timing on the
  zero-count bypass path for sample-compatible successors without adding a
  hidden decision/sample cycle; other successors fail closed.
  Verification: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `prove -Iperl t/1244-isf-wait-clause-lowering.t`; `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1131-isf-public-top-level-discovery-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-DYNAMIC-WAIT.3.3.5.2: preserve top-level wait samples`

- ID: `ISF-DYNAMIC-WAIT.3.3.5.3`
  Status: `pending`
  Goal: `Preserve pending samples for branch runtime waits.`
  Acceptance: Runtime waits with pending samples inside `when` bodies and
  `switch` branches preserve false/default/other-case exits, positive-count
  sample timing, and zero-count bypass sample timing, or remain fail-closed
  with narrower documented constraints.
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-DYNAMIC-WAIT.3.3.5.4`
  Status: `pending`
  Goal: `Preserve pending samples for repeat and loop runtime waits.`
  Acceptance: Runtime waits with pending samples inside `repeat`, `while`, and
  `until` bodies preserve loop-back/exit behavior, positive-count sample
  timing, and zero-count bypass sample timing, or remain fail-closed with
  narrower documented constraints.
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-DYNAMIC-WAIT.3.3.6`
  Status: `pending`
  Goal: `Evaluate expression-valued runtime wait counts.`
  Acceptance: Expression-valued count expansion has a width/type/snapshot
  contract and either ships through a generated count temporary or stays
  fail-closed with diagnostics and book coverage.
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DYNAMIC-WAIT.3.3.5.3` | `pending` | Branch contexts are the next smallest pending-sample materialization problem after top-level runtime waits. |

## Decisions

- `2026-05-15`: Keep the meaning of `(wait count)` independent of count
  spelling. If the effective count is `K`, the transaction must wait exactly
  `K` active cycles; `K == 0` remains transparent fallthrough with no generated
  wait cycle.
- `2026-05-15`: Statically resolved symbolic counts are compile-time counts,
  not runtime payloads. Once resolved from actor-level `(constants ...)`, they
  inherit the existing literal lowering, report shape, and zero-count behavior.
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
- `2026-05-15`: Actor-level `(constants (NAME value) ...)` is the first legal
  symbolic wait source. Actor and transaction `params` are deliberately not
  wait-count sources because they are overrideable specialization values and
  cannot honestly choose the number of already-emitted wait states.
- `2026-05-15`: A runtime dynamic zero count cannot be implemented by inserting
  an ordinary generated decision state; that would consume an active
  transaction cycle. The first implementation must split the predecessor edge
  into `count == 0` bypass and `count != 0` wait-entry paths, or reject that
  context.
- `2026-05-15`: The first runtime implementation should accept scalar count
  names with known unsigned width only. Count expressions, parameter-backed
  counts, pending samples before the wait, and inline branch/loop contexts
  stay fail-closed until their bypass and snapshot semantics are implemented.
- `2026-05-15`: Runtime scalar wait counts are sampled on the predecessor edge,
  not inside the generated wait state. The same edge that enters the wait also
  loads the generated counter; the zero-count sibling edge bypasses the wait
  state entirely. This prevents source-signal changes between the predecessor
  cycle and wait state from changing the active wait occurrence.
- `2026-05-15`: The first shipped runtime wait state is a one-state sampled
  counter loop: the state decrements the generated counter, exits when the
  sampled value is `1`, and loops while the sampled value is greater than `1`.
- `2026-05-15`: Expand runtime dynamic waits from smaller predecessor-edge
  problems outward. Consecutive top-level dynamic waits come before inline
  branch/loop waits and pending-sample support because they reuse the existing
  top-level state shape while exercising a real dynamic predecessor split.
- `2026-05-15`: Consecutive top-level runtime waits require two split points:
  the zero-bypass edge of the preceding wait's predecessor and the final
  sampled-counter edge of an active preceding wait. Both paths must evaluate
  the following wait's zero/positive split without entering the following wait
  uninitialized and without rereading the preceding wait source.
- `2026-05-15`: Additional top-level dynamic-wait predecessors should be
  modeled as one base advance condition plus any unrelated alternatives that
  must survive. `await` preserves watchdog timeout, `repeat_check` preserves
  loop-back, `stage` preserves valid driving while splitting ready, `sync_all`
  uses the AND of collected done signals, and `sync_any` uses their OR.
- `2026-05-15`: Inline dynamic waits need their own implementation leaves.
  The current public behavior remains fail-closed for `when`, `switch`,
  `repeat`, `while`, and `until` bodies, with diagnostics that name the
  rejected body context. `when` is the next implementation leaf because it has
  one true branch and one false skip.
- `2026-05-15`: A dynamic wait in a `when` body lowers by treating the true
  branch condition as the dynamic wait predecessor condition. The false branch
  is preserved as an explicit negated-condition skip. Pending samples before a
  `when`-body dynamic wait remain fail-closed until the shared pending-sample
  preservation leaf.
- `2026-05-15`: A dynamic wait in a `repeat` body lowers as part of the linear
  repeat body state chain. The repeat initializer may also load the dynamic
  wait counter on the positive path, the zero path bypasses to the next body
  state, and the repeat-check loop-back/exit state remains unchanged.
- `2026-05-15`: A dynamic wait in a `switch` branch lowers by materializing the
  switch state only when a selected branch needs a runtime wait split. The
  selected case owns its positive-count counter load/entry and zero-count
  bypass, other explicit cases remain selectable, and implicit fallthrough is
  emitted as the complement of the OR of all explicit case predicates.
- `2026-05-15`: A dynamic wait in a `while` body lowers by materializing loop
  decision states only when a body-entry or back-edge targets the generated
  wait. The true path loads/enters or bypasses the wait, and the false path
  still exits the loop.
- `2026-05-15`: A dynamic wait in an `until` body lowers with a normal first
  body-entry split plus a materialized loop decision: the true path exits, and
  the false path reloads/enters or bypasses the first body wait for the next
  iteration.
- `2026-05-15`: Loop decision states can also split loop-exit edges that target
  a following runtime wait, preserving the opposite loop branch rather than
  treating loop decisions as unsupported dynamic-wait predecessors.
- `2026-05-15`: Pending samples before runtime waits need path-specific
  materialization. The positive-count path should preserve the static positive
  wait behavior by materializing samples in the first active wait state. The
  zero-count path should preserve `wait 0` behavior by materializing samples in
  the next state-producing clause without adding a hidden cycle.
- `2026-05-15`: The likely implementation needs specialized post-wait
  zero-bypass handling, such as cloning or otherwise specializing the immediate
  successor state for the zero path. Placing the sample unconditionally on a
  shared successor would double-sample after a positive wait, and inserting a
  separate sample-only state on the zero path would violate the no-hidden-cycle
  invariant.
- `2026-05-15`: Top-level runtime waits with pending samples use path-specific
  materialization. The positive path enters a sample-carrying wait state for
  the first active wait cycle, then counts greater than one move to a generated
  no-resample wait-loop state. The zero path targets a sample-preserving clone
  of the following state-producing clause when that successor can carry samples
  without changing timing, preserving `wait 0` timing without modifying the
  original positive-count successor. Other top-level successor shapes fail
  closed until their sample materialization rule is explicit.

## Open Questions

- None for the next frontier. Runtime expressions beyond scalar names are a
  later expansion under `ISF-DYNAMIC-WAIT.3.3`.

## Blockers

- None for the current frontier.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-15` | `ISF-DYNAMIC-WAIT.1` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-DYNAMIC-WAIT.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1244-isf-wait-clause-lowering.t`; `prove -Iperl t/1244-isf-wait-clause-lowering.t t/1116-isf-public-schedule-report-key-family-audit.t t/1131-isf-public-top-level-discovery-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-DYNAMIC-WAIT.3.1` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-DYNAMIC-WAIT.3.2` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1244-isf-wait-clause-lowering.t`; `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1131-isf-public-top-level-discovery-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-DYNAMIC-WAIT.3.3.1` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-DYNAMIC-WAIT.3.3.2` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `prove -Iperl t/1244-isf-wait-clause-lowering.t`; `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1131-isf-public-top-level-discovery-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-DYNAMIC-WAIT.3.3.3` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `prove -Iperl t/1244-isf-wait-clause-lowering.t`; `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1131-isf-public-top-level-discovery-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-DYNAMIC-WAIT.3.3.4.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `prove -Iperl t/1244-isf-wait-clause-lowering.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-DYNAMIC-WAIT.3.3.4.2` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `prove -Iperl t/1244-isf-wait-clause-lowering.t`; `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1131-isf-public-top-level-discovery-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-DYNAMIC-WAIT.3.3.4.3` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `prove -Iperl t/1244-isf-wait-clause-lowering.t`; `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1131-isf-public-top-level-discovery-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-DYNAMIC-WAIT.3.3.4.4` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `prove -Iperl t/1244-isf-wait-clause-lowering.t`; `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1131-isf-public-top-level-discovery-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-DYNAMIC-WAIT.3.3.4.5` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `prove -Iperl t/1244-isf-wait-clause-lowering.t`; `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1131-isf-public-top-level-discovery-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-DYNAMIC-WAIT.3.3.5.1` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-DYNAMIC-WAIT.3.3.5.2` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `prove -Iperl t/1244-isf-wait-clause-lowering.t`; `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1131-isf-public-top-level-discovery-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DYNAMIC-WAIT.1` | `ISF-DYNAMIC-WAIT.1: specify non-literal waits` | Specifies the non-literal wait-count contract before parser/lowerer changes. |
| `ISF-DYNAMIC-WAIT.2` | `ISF-DYNAMIC-WAIT.2: ship symbolic waits` | Ships actor constants as the static symbolic source for wait counts. |
| `ISF-DYNAMIC-WAIT.3.1` | `ISF-DYNAMIC-WAIT.3.1: split runtime waits` | Splits runtime dynamic waits into a bypass-capable first implementation and later context expansion. |
| `ISF-DYNAMIC-WAIT.3.2` | `ISF-DYNAMIC-WAIT.3.2: ship runtime scalar waits` | Ships the first top-level known-width runtime scalar wait lowering and report metadata. |
| `ISF-DYNAMIC-WAIT.3.3.1` | `ISF-DYNAMIC-WAIT.3.3.1: split dynamic wait expansion` | Splits context expansion into executable leaves. |
| `ISF-DYNAMIC-WAIT.3.3.2` | `ISF-DYNAMIC-WAIT.3.3.2: support consecutive runtime waits` | Supports back-to-back top-level runtime waits with recursive zero-bypass and sampled-counter final-edge splits. |
| `ISF-DYNAMIC-WAIT.3.3.3` | `ISF-DYNAMIC-WAIT.3.3.3: support dynamic wait predecessors` | Supports runtime waits after `await`, `stage`, `repeat_check`, `sync_all`, and `sync_any` predecessor states. |
| `ISF-DYNAMIC-WAIT.3.3.4.1` | `ISF-DYNAMIC-WAIT.3.3.4.1: split inline dynamic waits` | Covers the inline fail-closed diagnostic matrix and splits implementation leaves. |
| `ISF-DYNAMIC-WAIT.3.3.4.2` | `ISF-DYNAMIC-WAIT.3.3.4.2: support when-body dynamic waits` | Supports runtime waits in `when` bodies for the no-pending-sample subset. |
| `ISF-DYNAMIC-WAIT.3.3.4.3` | `ISF-DYNAMIC-WAIT.3.3.4.3: support repeat-body dynamic waits` | Supports runtime waits in `repeat` bodies for the no-pending-sample subset. |
| `ISF-DYNAMIC-WAIT.3.3.4.4` | `ISF-DYNAMIC-WAIT.3.3.4.4: support switch-branch dynamic waits` | Supports runtime waits in `switch` branches for the no-pending-sample subset. |
| `ISF-DYNAMIC-WAIT.3.3.4.5` | `ISF-DYNAMIC-WAIT.3.3.4.5: support loop-body dynamic waits` | Supports runtime waits in `while` and `until` bodies for the no-pending-sample subset. |
| `ISF-DYNAMIC-WAIT.3.3.5.1` | `ISF-DYNAMIC-WAIT.3.3.5.1: split pending-sample preservation` | Splits pending-sample preservation into executable leaves and records the path-specific materialization contract. |
| `ISF-DYNAMIC-WAIT.3.3.5.2` | `ISF-DYNAMIC-WAIT.3.3.5.2: preserve top-level wait samples` | Supports pending samples before top-level runtime waits with one-shot positive sampling and a zero-count sample-preserving clone for sample-compatible successors. |

## Changelog

- `2026-05-15`: Created and activated the dynamic/symbolic wait task tree.
  Completed the specification leaf and made static symbolic counts the next
  PNT frontier.
- `2026-05-15`: Completed implementation work for `ISF-DYNAMIC-WAIT.2`;
  actor-level constants now resolve static symbolic wait counts and the current
  frontier advances to runtime scalar dynamic waits.
- `2026-05-15`: Split runtime scalar dynamic wait work under
  `ISF-DYNAMIC-WAIT.3`; the first implementation must use predecessor-edge
  bypass for zero counts and keep unsupported contexts fail-closed.
- `2026-05-15`: Completed `ISF-DYNAMIC-WAIT.3.2`; top-level known-width
  runtime scalar waits now lower through predecessor-edge counter load/bypass
  and the current frontier advances to `ISF-DYNAMIC-WAIT.3.3`.
- `2026-05-15`: Split `ISF-DYNAMIC-WAIT.3.3` into executable expansion leaves;
  the next implementation frontier is consecutive top-level dynamic waits.
- `2026-05-15`: Completed `ISF-DYNAMIC-WAIT.3.3.2`; consecutive top-level
  runtime scalar waits now lower through recursive zero-bypass and active-wait
  final-edge splits. The current frontier advances to
  `ISF-DYNAMIC-WAIT.3.3.3`.
- `2026-05-15`: Completed `ISF-DYNAMIC-WAIT.3.3.3`; runtime waits now lower
  after `await`, `stage`, `repeat_check`, `sync_all`, and `sync_any`
  predecessors. The current frontier advances to `ISF-DYNAMIC-WAIT.3.3.4`.
- `2026-05-15`: Completed `ISF-DYNAMIC-WAIT.3.3.4.1`; inline dynamic waits
  are split into context-specific implementation leaves and remain fail-closed
  with tests/book coverage for each shipped inline context. The current
  frontier advances to `ISF-DYNAMIC-WAIT.3.3.4.2`.
- `2026-05-15`: Completed `ISF-DYNAMIC-WAIT.3.3.4.2`; runtime waits in `when`
  bodies now lower through true-edge count load/bypass and false-edge skip
  preservation. The current frontier advances to `ISF-DYNAMIC-WAIT.3.3.4.3`.
- `2026-05-15`: Completed `ISF-DYNAMIC-WAIT.3.3.4.3`; runtime waits in
  `repeat` bodies now lower through body-local count load/bypass while
  preserving repeat-check loop/exit behavior. The current frontier advances to
  `ISF-DYNAMIC-WAIT.3.3.4.4`.
- `2026-05-15`: Completed `ISF-DYNAMIC-WAIT.3.3.4.4`; runtime waits in
  `switch` branches now lower through selected-case count load/bypass while
  preserving other case and implicit fallthrough behavior. The current
  frontier advances to `ISF-DYNAMIC-WAIT.3.3.4.5`.
- `2026-05-15`: Completed `ISF-DYNAMIC-WAIT.3.3.4.5`; runtime waits in
  `while` and `until` bodies now lower through loop-entry, loop-back, and
  loop-exit count load/bypass while preserving opposite loop branches. The
  current frontier advances to `ISF-DYNAMIC-WAIT.3.3.5`.
- `2026-05-15`: Completed `ISF-DYNAMIC-WAIT.3.3.5.1`; pending-sample
  preservation is split into executable leaves and the path-specific
  materialization contract is documented. The current frontier advances to
  `ISF-DYNAMIC-WAIT.3.3.5.2`.
- `2026-05-15`: Completed `ISF-DYNAMIC-WAIT.3.3.5.2`; top-level runtime waits
  now preserve pending samples with a sample-carrying first wait state, a
  no-resample wait-loop state for counts greater than one, and a zero-count
  sample-preserving clone of sample-compatible following states. Non-compatible
  top-level successors fail closed. The current frontier advances to
  `ISF-DYNAMIC-WAIT.3.3.5.3`.
