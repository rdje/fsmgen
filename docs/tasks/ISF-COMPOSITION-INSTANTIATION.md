# ISF-COMPOSITION: Generated Child Instantiation And Spawn Binding

## Metadata

- Tree ID: `ISF-COMPOSITION`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-14`
- Last updated: `2026-05-14`
- Owner: repo-local workflow

## Goal

Ship ISF-generated child/spawn composition as a reviewable, documented,
regression-backed flow: parent and child scheduled `.fsm` artifacts should be
usable through an explicit generated top, and spawned child parameters should
bind through validated public semantics instead of remaining deferred.

## Non-Goals

- Do not redesign the general `?top` composition language.
- Do not widen generated-child parameter semantics beyond what ISF spawn needs
  unless the existing composition contract already supports it.
- Do not make schedule JSON a fully frozen schema in this tree; report-shape
  stabilization belongs to `ISF-SCHEDULE-REPORTS`.

## Acceptance Criteria

- Current `(do transaction)` and `(spawn transaction as instance)` lowering
  behavior is inventoried against the existing composition pipeline.
- ISF has a documented authoring contract for generated child top
  instantiation and spawn parameter binding.
- Parent/child scheduled `.fsm` artifacts can be consumed by a generated
  composition/top flow without manual wiring gaps for the covered fixture set.
- Spawn parameter binding validates names, values, widths/shapes, and
  unsupported cases with targeted diagnostics.
- Schedule reports expose enough bounded metadata for downstream consumers to
  discover generated parent/child relationships without traversing raw
  scheduler internals.
- Focused tests and at least one realistic multi-file fixture cover the flow.
- ISF spec, public interface contract, mdBook, roadmap, and live docs agree.

## Task Tree

- ID: `ISF-COMPOSITION`
  Status: `active`
  Goal: `Ship generated child instantiation and spawn parameter binding for ISF.`
  Children: `ISF-COMPOSITION.1`, `ISF-COMPOSITION.2`,
  `ISF-COMPOSITION.3`, `ISF-COMPOSITION.4`, `ISF-COMPOSITION.5`,
  `ISF-COMPOSITION.6`

- ID: `ISF-COMPOSITION.1`
  Status: `done`
  Goal: `Inventory current child/spawn lowering and composition integration gaps.`
  Acceptance: `The task file lists current emitted files, start/done wiring,
  known composition entrypoints, unsupported spawn parameter cases, and exact
  gaps before policy or implementation work starts.`
  Verification: `source/test inspection; focused ISF and composition tests; git diff --check`
  Commit: `ISF-COMPOSITION.1: inventory current handoff gaps`

- ID: `ISF-COMPOSITION.2`
  Status: `pending`
  Goal: `Specify public ISF child/spawn composition semantics.`
  Acceptance: `The tree records the accepted syntax, generated artifact
  ownership, parent/child identity rules, parameter binding rules, and rejected
  cases.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-COMPOSITION.3`
  Status: `pending`
  Goal: `Implement spawn parameter binding in the ISF IR/lowering path.`
  Acceptance: `Valid spawn parameter bindings preserve through lowering, and
  malformed or unsupported bindings fail before misleading scheduled artifacts
  are emitted.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-COMPOSITION.4`
  Status: `pending`
  Goal: `Implement generated top/composition handoff for ISF parent/child artifacts.`
  Acceptance: `The covered ISF multi-file output can be consumed by the
  existing generation pipeline to produce a wired parent/child top for the
  agreed fixture set.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-COMPOSITION.5`
  Status: `pending`
  Goal: `Add diagnostics and bounded schedule-report metadata.`
  Acceptance: `Composition/spawn failures are targeted, and accepted parent,
  child, instance, and binding metadata appears in bounded report fields.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-COMPOSITION.6`
  Status: `pending`
  Goal: `Add focused regressions, realistic fixture coverage, and docs.`
  Acceptance: `Tests cover valid binding, invalid binding, generated top
  handoff, schedule-report metadata, CLI behavior, and synchronized docs.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-COMPOSITION.2` | `pending` | The current lowering and composition handoff gaps are now inventoried; the next slice can specify the public child/spawn composition semantics before implementation. |

## ISF-COMPOSITION.1 Inventory

`ISF-COMPOSITION.1` inspected the current scheduler, emitters, CLI handoff,
composition parser/realizer, focused tests, and the `isf/spawn_parent.isf`
fixture before setting new policy.

### Current ISF Lowering Behavior

- `FSM::Scheduler::ISF::LoweringIR::build_module(...)` validates `do` and
  `spawn` transaction references, collects spawned transaction targets, emits
  one child IR per unique spawned transaction name, and builds the parent IR
  from the non-spawned transactions.
- Blocking `(do child)` remains a same-actor parent/child rewrite inside the
  parent scheduled `.fsm`. The parent state asserts `child_start` with `=`,
  waits on `child_done`, `_wire_do_children(...)` rewires the child idle guard
  to `child_start`, and the child terminal state gets a `<1 child_done` pulse.
- `(spawn child as instance)` currently lowers to one parent sequential state
  per spawn. Each state asserts `instance_start` with `=`, and the associated
  `instance_done` signal is collected for the next `(await_all done)` or
  `(await_any done)` state.
- `await_all` now emits a single transition guard using the conjunction of all
  collected done ports, for example
  `(-> parent_main_done_5 <(& w0_done w1_done w2_done))`. `await_any` emits one
  guard per collected done port.
- Spawned child IRs are emitted as separate scheduled `.fsm` modules. The child
  module gets the actor interface plus `start`, `done`, and `last_error` ports
  if those names are missing.
- The child entry state is forced to guard on `start`. In the inspected
  `spawn_parent.isf` output, however, the generated `child_worker_done_1`
  terminal state still transitions to `child_worker_drive_0`, because the
  terminal link was created before the injected entry state. That is an exact
  handoff gap to settle before claiming reusable spawned-child instances.

### Current Emitted Files

- In-process lowering returns only the public lower-result keys, including a
  `files` map. For `isf/spawn_parent.isf`, the map contains exactly
  `child_worker.fsm` and `spawn_parent.fsm`.
- `./bin/fsmgen --strict --outdir DIR isf/spawn_parent.isf` writes both
  scheduled `.fsm` files, then passes only `spawn_parent.fsm` to the normal HDL
  pipeline. It does not generate or compile an ISF-specific composition top.
- The generated parent `.fsm` declares `w0_start`, `w1_start`, and `w2_start`
  in `+size` and drives them internally. The generated parent SystemVerilog
  therefore treats the starts as internal signals, not top ports. The
  corresponding `w0_done`, `w1_done`, and `w2_done` signals are parent inputs
  because the parent reads them but does not drive them.
- That split means an external top cannot currently wire parent start outputs
  to child `start` inputs through the ordinary composition pipeline: the
  parent start signals are not exposed as child/top ports.

### Current Schedule Report Scope

- `FSM::Scheduler::ISF::Emitter::JSON` reports the parent IR only.
- The current multi-file report for `spawn_parent.isf` advertises source
  `spawn_parent.isf`, scheduled file `spawn_parent.fsm`, one parent
  transaction (`parent_main`), and parent-local DT/storage summaries.
- It does not report generated child files, spawned instances, parent/child
  start-done relationships, or spawn binding metadata.

### Existing Composition Entrypoints

- The general composition source parser accepts `?top:name` with `?ports`,
  `?fsmc`, `?dtc`, `?rtl`, `?toplink`, `+constants`, `+enums`, `+types`, and
  `+import` sections.
- Existing generated-child composition already supports embedded or external
  `?fsm` and `?dt` child sources through `?fsmc` and `?dtc`.
- Existing generated-child parameter override blocks use
  `(?fsmc:inst child_src (params (NAME value) ...))` or the corresponding
  `?dtc` form. The parser validates override shape and duplicate names, the
  resolver handles top constants/deferred symbols, and the generated-child
  realizer validates override names and aggregate shapes against the child's
  direct `+params` declarations.
- Existing composition HDL emission can produce a generated top with SV
  `#(...)` parameter overrides for generated children, but it expects a
  composition source. The ISF scheduler does not currently synthesize that
  source or an equivalent structured handoff.

### Unsupported Spawn Parameter Cases

- ISF spawn syntax is currently exact: `(spawn transaction as instance)`.
  Nested `(params ...)`, named binding blocks, literal actuals, and top-symbol
  references are not parsed as part of spawn.
- Spawn instance-name uniqueness is not enforced by the ISF spawn path before
  scheduled `.fsm` emission. The general composition pipeline has duplicate
  child-instance diagnostics, but those diagnostics do not apply until ISF
  produces an actual composition handoff.
- Width/shape validation for spawned child parameters is absent at the ISF
  level because no spawn parameter surface exists yet.

### Exact Gaps Before Implementation

- Decide whether ISF should emit a concrete `?top` composition source, return
  structured composition metadata that an existing entrypoint consumes, or do
  both with one artifact being canonical.
- Define parent/child port ownership for `instance_start` and `instance_done`
  so the generated top can wire starts and dones without reaching into parent
  internals.
- Fix or explicitly define spawned child re-entry after completion; the current
  injected-entry case can loop from terminal back to the child body instead of
  waiting for the next `start`.
- Specify spawn instance identity, uniqueness, and deterministic generated
  module/source names.
- Specify the first supported spawn parameter binding syntax and value domain,
  then reuse the existing composition parameter override validator where it
  matches the ISF contract.
- Add bounded schedule-report metadata for parent/child files, spawned
  instances, and bindings after the public semantics are set.

## Decisions

- `2026-05-14`: This tree owns the ISF-specific generated-child top and spawn
  parameter objective. General composition language changes remain outside this
  tree unless they are required by the ISF handoff.
- `2026-05-14`: `ISF-COMPOSITION.1` confirms that current ISF multi-file
  lowering emits parent/child scheduled `.fsm` artifacts but no generated top,
  and that the parent start signals are internal rather than wireable
  composition ports.

## Open Questions

- Should ISF generate a composition source explicitly, or should the scheduler
  return enough structured metadata for an existing composition entrypoint to
  construct the top? This remains the primary `ISF-COMPOSITION.2` decision.
- Which parameter value domains are valid for spawned ISF children in the
  first shipped slice? `ISF-COMPOSITION.1` confirms no spawn parameter syntax
  exists today.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-COMPOSITION` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.1` | Source/test inspection of `LoweringIR`, `Scheduler`, FSM/JSON emitters, `bin/fsmgen`, composition parser/realizer, and focused ISF/composition tests | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.1` | `./bin/fsmgen --strict --outdir /tmp/isf-composition-inventory.6QUiW9 isf/spawn_parent.isf` | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.1` | `./bin/fsmgen --strict --emit-schedule-json isf/spawn_parent.isf` | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.1` | `prove -l t/1117-isf-public-lower-result-files-audit.t t/1122-isf-public-cli-outdir-lowering-audit.t t/1128-isf-public-multifile-schedule-report-audit.t t/1110-isf-do-child-entry-rewire.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1204-isf-child-composition-clause-boundary.t` | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.1` | `prove -l t/184-composition-generated-child-realizer.t t/292-composition-generated-child-parameter-overrides.t t/93-composition-multi-generated-plus-rtl-children.t` | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.1` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-COMPOSITION` | `R14: map ISF objectives to task trees` | Initial tree creation belongs to the ISF objective task-tree coverage slice. |
| `ISF-COMPOSITION.1` | `ISF-COMPOSITION.1: inventory current handoff gaps` | Records current ISF child/spawn lowering, existing composition entrypoints, unsupported spawn parameters, and exact gaps. |

## Changelog

- `2026-05-14`: Created the active ISF composition/spawn task tree.
- `2026-05-14`: Completed `ISF-COMPOSITION.1`; current frontier moves to
  `ISF-COMPOSITION.2` for public child/spawn composition semantics.
