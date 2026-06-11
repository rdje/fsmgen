# ISF-SCHEDULING-BACKLOG-FRONTIER

Status: active

Roadmap lane: R14 / ISF scheduling, activation, CDC, ATL, actor-network, and generated-child surfaces

Created: 2026-06-10

Current frontier: `ISF-SCHEDULING-BACKLOG-FRONTIER.6.2`

## Goal

Own the seven deferred ISF scheduling/control-flow areas called out from the
user-facing book backlog and drive them one exact, recoverable implementation
leaf at a time.

This tree exists because the book backlog text is intentionally broad. It is
not direct permission to edit code. Each branch below must select a specific
leaf with an explicit contract, acceptance criteria, tests, and book/spec sync
before any source, test, generated-artifact, or config change starts.

## Source Backlog

This tree owns these book-deferred areas:

- direct `(on ...)` activation parameter overrides; currently `(on ...)` is an
  entry guard, not a generated activation site
- deeper or more general nested repeat-body `do` / `spawn` combinations
- broader outstanding-child lifetime rules beyond the current "must drain
  before repeat re-entry" model
- repeated/nested ATL triggers and waits
- fan-in/fan-out event joins
- broader actor-network scheduling and group scheduling
- generated-child top surfaces beyond the covered spawn, generated `do`, and
  rule-trigger cases

Primary book anchors at creation time:

- `docs/book/src/14-feature-backlog.md`, around the deferred activation and
  scheduling backlog entries
- `docs/book/src/13d-control-flow.md`, around the shipped child-activation
  surfaces and deferred boundaries

## Non-Goals

- Do not implement all seven surfaces in one slice.
- Do not broaden runtime semantics without a focused leaf and explicit tests.
- Do not invent hidden dynamic behavior for a surface whose source syntax has
  no generated activation site; record or improve the fail-closed contract
  instead.
- Do not edit frozen legacy prose logs (`CHANGES.md`,
  `DEVELOPMENT_NOTES.md`, `ROADMAP_STATUS.md`,
  `LIVE_ACHIEVEMENT_STATUS.md`).

## Acceptance

- Every user-requested bullet has a named task-tree branch.
- The first implementation branch is selected and made recoverable from the
  task tree plus `MEMORY.md`.
- For each implementation leaf:
  - current shipped behavior is reproduced or audited first;
  - source/test/book/spec changes are kept inside the selected leaf;
  - mdBook and public contract wording match the resulting behavior;
  - focused checks plus broader gates appropriate to the blast radius pass;
  - commit subject starts with the work-unit id.

## Task Tree

### ISF-SCHEDULING-BACKLOG-FRONTIER.1 — Create Frontier And Select First Leaf

Status: done

Goal: Convert the seven deferred scheduling/control-flow bullets into an
active, owned R14 task tree and select the first exact branch.

Acceptance:

- Task-tree index links this file as active.
- Each deferred bullet has a child branch below.
- First executable leaf is selected without source/test edits.

Evidence:

- Selected `ISF-SCHEDULING-BACKLOG-FRONTIER.2.1` because it is the first
  source-order backlog item and has the largest semantic ambiguity: direct
  `(on ...)` currently names an entry guard, while parameter overrides require
  a generated activation site. The first implementation slice must either
  implement a narrow explicit activation contract or preserve the boundary with
  tests, diagnostics, and book wording.

### ISF-SCHEDULING-BACKLOG-FRONTIER.2 — Direct `(on ...)` Activation Parameter Overrides

Status: done

Goal: Resolve the deferred question of parameter overrides on direct
`(on ...)` entries, where the current surface is an entry guard rather than a
generated child activation.

#### ISF-SCHEDULING-BACKLOG-FRONTIER.2.1 — Direct-On Override Contract Slice

Status: done

Goal: Audit the parser/lowerer/runtime contract for override-like direct
`(on ...)` forms and make one signoff-level change: either ship the smallest
explicitly testable generated activation surface if the architecture supports
it, or tighten the fail-closed diagnostic and book/spec wording if the current
surface cannot carry call-site values.

Acceptance:

- Reproduce current behavior for at least one override-like direct `(on ...)`
  example.
- If implementation is viable, add the smallest supported syntax/lowering path
  and a runnable example proving typed override value propagation.
- If implementation is not viable without a new source surface, add or tighten
  the targeted diagnostic and document why direct `(on ...)` remains an entry
  guard rather than a call site.
- Update `docs/book/` and any public spec text impacted by the result.
- Run focused ISF tests and the memory-architecture gate before commit.

Evidence:

- Current behavior already rejects direct `(on ... (params ...))` before
  scheduled `.fsm` emission with the targeted entry-guard/generated-activation
  diagnostic.
- Added regression coverage for the labeled-entry shape
  `(on start as accepting (params ...))`; it hits the same diagnostic because
  `as NAME` names the entry state for checks only.
- Synced `docs/book/src/13b-transactions.md`,
  `docs/book/src/13h-lowering-reference.md`,
  `docs/book/src/14-feature-backlog.md`, and `docs/ISF_SPEC.md`.

### ISF-SCHEDULING-BACKLOG-FRONTIER.3 — Deeper Nested Repeat-Body `do` / `spawn`

Status: done

Goal: Extend or close the remaining deeper/general nested repeat-body child
activation combinations beyond the currently covered local, generated, loop,
and branch forms.

Acceptance:

- Select exact syntax/context pair before implementation, such as a specific
  repeat-contained branch/loop/control body.
- Prove no regression to current repeat drain/re-entry guarantees.
- Sync the 13d control-flow examples and backlog matrix.

#### ISF-SCHEDULING-BACKLOG-FRONTIER.3.1 — Loop-Then-When Repeat Local `do`

Status: done

Goal: Implement or close the first loop-plus-branch repeat-body activation
shape: a plain local `(do child)` inside a `(repeat ...)` reached through one
`while` body and one nested `when` body, e.g.
`(while c1 (when c2 (repeat n (do worker))))`.

Acceptance:

- Reproduce the current `loop-contained repeat-body do remains deferred`
  rejection from `t/1379-isf-loop-contained-repeat-body-local-do.t`.
- If the lowering path is viable, accept the `while -> when -> repeat -> local
  do` shape and prove the schedule order: loop pre-test, branch guard,
  repeat init/check, local child start, fresh child done wait, repeat re-entry,
  then loop re-test.
- Keep generated `do`, `spawn`, cross-domain, extra loop nesting, `until`, and
  switch-containing variants fail-closed unless this leaf explicitly proves a
  smaller same-contract generalization.
- Sync `docs/book/src/13d-control-flow.md`, the feature backlog, and public
  audits/spec text impacted by the result.

Evidence:

- `while -> when -> repeat -> plain local do` now lowers and gates the local
  child start/done handshake through the existing repeat schedule.
- Generated `do` in the same loop-plus-branch shape stays fail-closed with a
  targeted loop-plus-branch diagnostic; `until -> when`, spawned, CDC, nested
  switch, and extra-loop variants remain outside this leaf.
- `docs/book/src/13d-control-flow.md`,
  `docs/book/src/13k-isf-feature-support-matrix.md`,
  `docs/book/src/14-feature-backlog.md`, `docs/ISF_SPEC.md`, and
  `docs/knowledge/isf-while-when-repeat-local-do.md` are synced.

### ISF-SCHEDULING-BACKLOG-FRONTIER.4 — Outstanding-Child Lifetime Rules

Status: done

Goal: Define and implement exact outstanding-child lifetime semantics beyond
the current repeat re-entry drain rule.

Acceptance:

- Select one exact lifetime rule first: e.g. cancellation, generation-tagged
  completion, parent-exit drain, or explicit detach.
- Prove behavior under local and generated child activation where applicable.
- Document the resulting hardware scheduling contract.

#### ISF-SCHEDULING-BACKLOG-FRONTIER.4.1 — Outstanding-Child Lifetime First Slice

Status: done

Goal: Select and implement the first exact lifetime rule beyond the current
mandatory repeat re-entry drain model, or close the first candidate with a
targeted diagnostic if the hardware contract is not yet safe.

Handoff:

- 2026-06-10: user redirected full-time implementation focus to
  `ISF-COMPOSITIONAL-CONTROL-FLOW-ARCHITECTURE`. This leaf remains pending and
  will be addressed through that tree's typed outstanding-child lifetime
  effects instead of another one-off syntax combination gate.

Acceptance:

- Audit current outstanding generated-child diagnostics around undrained spawn
  and multi-pending `await_any` without a later drain.
- Select one precise behavior before source edits, such as explicit detach,
  parent-exit drain, generation-tagged completion, or a sharper fail-closed
  diagnostic for a named shape.
- Prove no regression to repeat re-entry freshness, generated-child done-set
  handling, and already shipped same-body drain paths.
- Sync the book/spec/backlog wording for the chosen rule.

Selection:

- Candidate behavior: multi-pending repeat-body `(await_any done)` without a
  later same-body `(await_all done)` remains fail-closed. The first lifetime
  slice will not add detach, parent-exit drain, or generation-tagged
  completion semantics because the current generated-child handoff model has
  no per-activation generation tag, cancellation handshake, or detached-child
  ownership surface.
- Implementation target: sharpen the public diagnostics for the named missing
  lifetime proof so authors see that `await_any` is observation-only and that
  the same body must still drain the exact outstanding set with `await_all`.
  Plain undrained spawns keep their existing same-body drain diagnostic.

Result:

- Kept multi-pending repeat-body `(await_any done)` without a later same-body
  `(await_all done)` fail-closed; no detach, parent-exit drain, cancellation,
  or generation-tagged completion semantics were introduced.
- Public diagnostics now distinguish plain undrained spawn from observation-only
  `await_any` missing-drain failures. Top-level repeat, loop-contained repeat,
  and deeper-nested repeat each name the missing later same-body `await_all`
  proof for multi-pending `await_any`.
- Focused coverage locks the new loop-contained, top-level, and deeper-nested
  diagnostic strings while preserving already shipped same-body drain paths and
  repeat/loop backedge freshness proofs.
- The mdBook, feature backlog, live ISF spec, downstream handoff, public
  interface contract, Knowledge Map fact card, task index, and `MEMORY.md` are
  synced to the sharper fail-closed contract.

#### ISF-SCHEDULING-BACKLOG-FRONTIER.4.2 — Next Outstanding-Child Lifetime Candidate Selection

Status: done

Goal: Select the next precise outstanding-child lifetime candidate after the
multi-pending `await_any` diagnostic slice.

Acceptance:

- Audit explicit detach, parent-exit drain, cancellation, and
  generation-tagged completion against the current generated-child handoff
  model.
- Select one behavior or fail-closed diagnostic target before source edits.
- If a behavior is accepted, prove restart-before-drain safety, repeat/loop
  backedge freshness, generated-child done-set ownership, and public docs/spec
  alignment.
- If no behavior is safe in this slice, record the exact missing hardware
  contract and close the candidate with a targeted diagnostic/doc update.

Result:

- Audited the next lifetime candidates against the current generated-child
  handoff model. Authored `(detach ...)` and `(cancel ...)` clauses already
  fail closed as unsupported transaction clauses; duplicate generated spawn
  instance names already fail before lowering, so those are not the next
  highest-value diagnostic target.
- Selected parent-exit drain after a repeat-body spawn as the next exact
  candidate: a source shape such as `(repeat loops (spawn worker as w0))
  (await_all done)` still cannot be accepted safely because the generated-child
  done set is scoped inside the repeat body and there is no cross-region
  ownership proof that prevents repeat re-entry before drain.
- The next implementation leaf is `.4.3`, which will keep that parent-exit
  drain candidate fail-closed and make the diagnostic explicitly say that
  repeat-body spawned children must be drained in the same repeat body before
  the repeat check can loop.

#### ISF-SCHEDULING-BACKLOG-FRONTIER.4.3 — Repeat Parent-Exit Drain Diagnostic

Status: done

Goal: Keep repeat-body spawned children fail-closed when an author attempts to
drain them after the repeat exits, and replace the generic same-body drain
message with a targeted parent-exit drain diagnostic for that shape.

Acceptance:

- Detect a repeat-body generated `spawn` that has no same-body sync while a
  following transaction-body `await_all` or multi-pending `await_any` appears
  to drain after the repeat exits.
- Preserve the existing accepted same-body `await_all`, single-pending
  `await_any`, and multi-pending `await_any` plus later same-body `await_all`
  paths.
- Preserve the existing plain undrained-spawn diagnostic when no later
  parent-body sync exists.
- Sync mdBook/spec/downstream/public-contract wording for the sharper
  fail-closed parent-exit drain contract.

Result:

- Kept repeat-body parent-exit drain fail-closed. A parent-body `await_all` or
  `await_any` after a top-level repeat exits is now diagnosed as an invalid
  drain for repeat-body spawned children, rather than looking like the same
  plain undrained-spawn case.
- The diagnostic states that repeat-body spawned children must be drained by a
  same-body `await_all` before the repeat check can loop; the authored
  parent-body sync form is included in the message.
- Focused coverage locks parent-body `await_all`/`await_any` after an
  undrained repeat-body spawn and parent-body `await_all` after a
  multi-pending repeat-body `await_any` observation.
- The mdBook, feature backlog, support matrix, live ISF spec, downstream
  handoff, public interface contract, Knowledge Map fact card, task index, and
  `MEMORY.md` are synced. This closes the current outstanding-child lifetime
  branch; detach/cancel, parent-exit drain, and generation-tagged completion
  remain fail-closed until a future exact owner adds the missing hardware
  contracts.

### ISF-SCHEDULING-BACKLOG-FRONTIER.5 — Repeated/Nested ATL Triggers And Waits

Status: done

Goal: Extend ATL trigger/wait lowering for repeated and nested transaction
flows without breaking existing single-trigger behavior.

Acceptance:

- Select one exact repeated or nested ATL pattern before implementation.
- Prove trigger pulse ordering and wait completion with focused tests.
- Sync ATL and control-flow book examples.

#### ISF-SCHEDULING-BACKLOG-FRONTIER.5.1 — Repeated/Nested ATL First Slice Selection

Status: done

Goal: Select the first exact repeated or nested ATL trigger/wait pattern for
implementation or targeted fail-closed closure.

Acceptance:

- Audit current ATL trigger/wait diagnostics and fixtures for repeated and
  nested transaction flows.
- Select one precise source pattern before source edits.
- If the pattern is accepted, prove trigger pulse ordering, wait completion,
  schedule report stability, and book/spec sync.
- If the pattern remains unsafe, record the exact missing ordering/lifetime
  contract and close it with a targeted diagnostic/doc update.

Result:

- Audited the shipped ATL trigger/wait surface in the parser, lowering IR,
  fixtures, public contract, live spec, and mdBook. Top-level nested
  waits/triggers already fail closed with targeted diagnostics. Trigger-batch
  multi-event waits already lower only when one contiguous temporary trigger
  batch is followed by contiguous source-ordered waits to distinct triggered
  actor instances and no ATL data movement is in the segment.
- Selected the repeated actor-event wait after a temporary trigger batch as
  the first exact `.5` implementation candidate. A source shape such as a
  trigger batch followed by `(await writer.done)` and `(await writer.ready)`
  for the same triggered actor remains unsafe to accept because the current
  ATL handoff model has no event re-arm, per-event generation tag, or
  repeated-wait lifetime contract proving that the second wait observes a new
  child event rather than the same external handoff level.
- The next implementation leaf is `.5.2`, which will keep repeated
  trigger-batch actor-event waits fail-closed and replace the broad
  multi-event wait fallback with a targeted diagnostic and synced docs/tests.

#### ISF-SCHEDULING-BACKLOG-FRONTIER.5.2 — Repeated Trigger-Batch Event-Wait Diagnostic

Status: done

Goal: Keep repeated actor-event waits after a temporary trigger batch
fail-closed, but diagnose them as a missing event re-arm/lifetime contract
rather than only the broad multi-event wait subset failure.

Acceptance:

- Detect a temporary trigger batch followed by multiple top-level event waits
  that target the same triggered actor instance.
- Preserve the accepted source-ordered multi-event wait chain to distinct
  triggered actor instances.
- Preserve existing nested wait/trigger diagnostics and non-batch multi-wait
  fail-closed behavior.
- Sync the parser tests, mdBook, live specs/contracts, and Knowledge Map with
  the sharper repeated-wait boundary.

Result:

- Kept repeated actor-event waits after a temporary trigger batch fail-closed.
  The parser now detects the contiguous trigger-batch plus repeated wait
  instance shape before the broad multi-event wait fallback.
- The diagnostic names the repeated wait itself and states that repeated
  actor-event waits require an event re-arm or per-event generation/lifetime
  contract. The accepted distinct-triggered-actor multi-wait chain,
  non-batch multi-wait fallback, and nested wait/trigger diagnostics are
  preserved.
- Focused fixture coverage proves the accepted trigger-batch multi-event wait
  form still lowers, while the repeated-wait fixture now expects the targeted
  event re-arm/lifetime diagnostic.
- The mdBook, live ISF spec, downstream handoff, public interface contract,
  Knowledge Map fact card, task index, and `MEMORY.md` are synced.

### ISF-SCHEDULING-BACKLOG-FRONTIER.6 — Fan-In/Fan-Out Event Joins

Status: active

Goal: Add or close exact fan-in/fan-out event join semantics across the ISF
event/trigger surfaces.

Acceptance:

- Select a precise join surface first, such as all-of/any-of completion over
  named events or child completions.
- Prove deterministic lowering and failure behavior for malformed joins.
- Document example use cases and limits.

#### ISF-SCHEDULING-BACKLOG-FRONTIER.6.1 — Event Join First Slice Selection

Status: done

Goal: Select the first exact fan-in/fan-out event-join source shape for
implementation or targeted fail-closed closure.

Acceptance:

- Audit current local sync, child completion sync, ATL event wait, and
  trigger-batch diagnostics for all-of/any-of event joins.
- Select one precise source pattern before implementation.
- If the pattern is accepted, prove deterministic lowering, malformed-shape
  failure behavior, report/doc stability, and mdBook examples.
- If the pattern remains unsafe, record the missing ordering/lifetime/storage
  contract and close it with a targeted diagnostic/doc update.

Result:

- Audited current join-adjacent surfaces. Generated-child completion joins
  already ship through `(await_all done)` over the current outstanding child
  done set, and `(await_any done)` is accepted only for the documented
  single-pending drain or multi-pending observation followed by same-body
  `(await_all done)` drain.
- ATL trigger-batch multi-event waits are not event joins: they lower as
  explicit source-ordered sequential wait states to distinct triggered actors.
  Hidden same-cycle all-of/any-of actor-event joins remain deferred.
- Selected the first exact event-join closure: source that tries to spell an
  ATL event join with sync clauses such as `(await_all reader.done
  writer.done)` or `(await_any reader.done writer.done)` remains unsafe to
  accept because there is no event latch/storage, same-cycle join operator,
  or per-event lifetime contract. The current path falls through to generic
  enum/sync diagnostics, so `.6.2` will keep it fail-closed with a targeted
  ATL event-join diagnostic.

#### ISF-SCHEDULING-BACKLOG-FRONTIER.6.2 — ATL Sync-Clause Event-Join Diagnostic

Status: pending

Goal: Keep `await_all`/`await_any` clauses that try to join qualified ATL
actor events fail-closed, while replacing generic enum/sync messages with a
targeted missing event-join contract diagnostic.

Acceptance:

- Detect transaction-body `await_all` or `await_any` clauses that carry one or
  more qualified static actor event operands such as `reader.done`.
- Preserve accepted generated-child completion sync through `(await_all done)`
  and the existing single-pending/multi-pending `(await_any done)` contracts.
- Preserve accepted sequential ATL multi-event waits after a temporary trigger
  batch; do not collapse them into a hidden same-cycle join.
- Sync parser/lowering tests, mdBook, live specs/contracts, and Knowledge Map
  with the fail-closed ATL event-join boundary.

### ISF-SCHEDULING-BACKLOG-FRONTIER.7 — Actor-Network And Group Scheduling

Status: pending

Goal: Broaden actor-network and group scheduling only through exact, testable
increments.

Acceptance:

- Select one scheduling primitive or grouping rule before implementation.
- Prove arbitration, ordering, or CDC behavior as applicable.
- Keep actor-network docs aligned with generated HDL behavior.

### ISF-SCHEDULING-BACKLOG-FRONTIER.8 — Generated-Child Top Surface Widening

Status: pending

Goal: Cover generated-child top surfaces beyond the currently documented spawn,
generated `do`, and rule-trigger cases.

Acceptance:

- Select one generated-child source surface before implementation.
- Prove naming, interface, and completion semantics.
- Document how the surface relates to existing generated child activation.

## Verification Log

- 2026-06-10 (`.1`): task-tree owner created; implementation not started yet.
  `scripts/check_memory_architecture.sh`, `git diff --check`, and
  `prove -Iperl t/1414-docs-relative-paths-audit.t` pass.
- 2026-06-10 (`.2.1`): direct `(on ...)` activation override boundary
  reverified and labeled-entry regression added. `prove -Iperl
  t/1195-isf-sample-clause-boundary.t
  t/1250-isf-spec-focused-test-index-audit.t
  t/1303-isf-public-live-book-paths-audit.t
  t/1305-isf-book-feature-matrix-audit.t
  t/1256-feature-backlog-status-audit.t`, `mdbook build docs/book`,
  `scripts/check_memory_architecture.sh`, and `git diff --check` pass.
- 2026-06-10 (`.3.1`): shipped `while -> when -> repeat -> plain local do`;
  generated/spawn/CDC/`until -> when` variants remain fail-closed.
  `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c
  t/1374-isf-loop-contained-repeat-body-activation-diagnostic.t`; `perl
  -Iperl -c t/1375-isf-deeper-nested-repeat-body-activation-diagnostic.t`;
  `perl -Iperl -c t/1379-isf-loop-contained-repeat-body-local-do.t`; and
  `prove -Iperl t/1374-isf-loop-contained-repeat-body-activation-diagnostic.t
  t/1375-isf-deeper-nested-repeat-body-activation-diagnostic.t
  t/1379-isf-loop-contained-repeat-body-local-do.t
  t/1380-isf-loop-contained-repeat-body-generated-do.t
  t/1381-isf-deeper-nested-repeat-body-local-do.t
  t/1382-isf-deeper-nested-repeat-body-generated-do.t
  t/1383-isf-loop-and-deeper-repeat-body-spawn.t
  t/1384-isf-loop-and-deeper-repeat-body-multi-pending-awaitany.t
  t/1305-isf-book-feature-matrix-audit.t
  t/1307-isf-loop-body-doc-truth-audit.t
  t/1256-feature-backlog-status-audit.t` pass. Broad gates also pass:
  `./bin/ci-regression isf --no-book` (Files=294, Tests=2133), `mdbook
  build docs/book`, `knowledge-map/scripts/check_knowledge_map.sh`,
  `scripts/check_memory_architecture.sh`, and `git diff --check`.
- 2026-06-11 (`.4.1`): selected the multi-pending repeat-body `await_any`
  missing-drain case as the first outstanding-child lifetime slice and kept it
  fail-closed because no detach, parent-exit drain, cancellation, or
  generation-tagged completion contract exists. The public validator now emits
  a specific diagnostic for multi-pending `await_any` without a later same-body
  `await_all` in top-level, loop-contained, and deeper-nested repeat contexts;
  plain undrained spawn keeps its previous drain diagnostic. `perl -Iperl -c
  perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c
  t/1384-isf-loop-and-deeper-repeat-body-multi-pending-awaitany.t`; `perl
  -Iperl -c t/1423-isf-control-flow-lifetime-checks.t`; `prove -Iperl
  t/1383-isf-loop-and-deeper-repeat-body-spawn.t
  t/1384-isf-loop-and-deeper-repeat-body-multi-pending-awaitany.t
  t/1423-isf-control-flow-lifetime-checks.t`; `prove -Iperl
  t/1419-isf-control-flow-effect-inventory.t
  t/1421-isf-control-flow-effect-checks.t
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`;
  `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t
  t/1305-isf-book-feature-matrix-audit.t
  t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl
  t/1376-isf-book-example-lowering-audit.t`; `mdbook build docs/book`;
  `knowledge-map/scripts/check_knowledge_map.sh`;
  `scripts/check_memory_architecture.sh`; and `git diff --check` pass.
- 2026-06-11 (`.4.2`): audited explicit detach, cancellation, duplicate
  generated instance restart, parent-exit drain, and generation-tagged
  completion candidates. `(detach ...)` and `(cancel ...)` already fail as
  unsupported clauses, duplicate spawn instance names already fail before
  lowering, and generation-tagged completion still lacks a hardware contract.
  Selected `.4.3` to keep parent-exit drain after a repeat-body spawn
  fail-closed with a targeted diagnostic. `scripts/check_memory_architecture.sh`;
  `knowledge-map/scripts/check_knowledge_map.sh`; and `git diff --check` pass.
- 2026-06-11 (`.4.3`): kept parent-exit drain after repeat-body generated
  spawn fail-closed and added a targeted diagnostic for parent-body
  `await_all`/`await_any` after a repeat exits. The diagnostic tells authors to
  drain spawned children with same-body `await_all` before the repeat check can
  loop, and multi-pending `await_any` observations keep the same same-body
  drain requirement. `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`;
  `perl -Iperl -c
  t/1384-isf-loop-and-deeper-repeat-body-multi-pending-awaitany.t`; `perl
  -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -Iperl
  t/1383-isf-loop-and-deeper-repeat-body-spawn.t
  t/1384-isf-loop-and-deeper-repeat-body-multi-pending-awaitany.t`; `prove
  -Iperl t/1305-isf-book-feature-matrix-audit.t
  t/1307-isf-loop-body-doc-truth-audit.t
  t/1250-isf-spec-focused-test-index-audit.t`; `prove -Iperl
  t/1419-isf-control-flow-effect-inventory.t
  t/1421-isf-control-flow-effect-checks.t
  t/1423-isf-control-flow-lifetime-checks.t
  t/1432-isf-loop-pending-spawn-local-do-effect-widening.t
  t/1433-isf-until-pending-spawn-local-do-effect-widening.t
  t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t`;
  `prove -Iperl t/1376-isf-book-example-lowering-audit.t`; `mdbook build
  docs/book`; `knowledge-map/scripts/check_knowledge_map.sh`;
  `scripts/check_memory_architecture.sh`; and `git diff --check` pass.

## Commit Log

- `ISF-SCHEDULING-BACKLOG-FRONTIER.1`: `0cf6722c
  ISF-SCHEDULING-BACKLOG-FRONTIER.1: track scheduling backlog`
- `ISF-SCHEDULING-BACKLOG-FRONTIER.2.1`: `fedfde19
  ISF-SCHEDULING-BACKLOG-FRONTIER.2.1: close direct on override boundary`
- `ISF-SCHEDULING-BACKLOG-FRONTIER.3.1`: `9c87ecc4
  ISF-SCHEDULING-BACKLOG-FRONTIER.3.1: ship while-when repeat local do`
- `ISF-SCHEDULING-BACKLOG-FRONTIER.4.1`: this commit,
  `ISF-SCHEDULING-BACKLOG-FRONTIER.4.1: sharpen await_any lifetime diagnostics`.
- `ISF-SCHEDULING-BACKLOG-FRONTIER.4.2`: this commit,
  `ISF-SCHEDULING-BACKLOG-FRONTIER.4.2: select repeat parent-exit drain diagnostic`.
- `ISF-SCHEDULING-BACKLOG-FRONTIER.4.3`: this commit,
  `ISF-SCHEDULING-BACKLOG-FRONTIER.4.3: diagnose repeat parent-exit drains`.
