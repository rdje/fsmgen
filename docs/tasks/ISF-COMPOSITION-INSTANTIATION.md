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
  evolution beyond the advertised generated-composition summary belongs to
  `ISF-SCHEDULE-REPORTS`.

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
  `ISF-COMPOSITION.6`, `ISF-COMPOSITION.7`

- ID: `ISF-COMPOSITION.1`
  Status: `done`
  Goal: `Inventory current child/spawn lowering and composition integration gaps.`
  Acceptance: `The task file lists current emitted files, start/done wiring,
  known composition entrypoints, unsupported spawn parameter cases, and exact
  gaps before policy or implementation work starts.`
  Verification: `source/test inspection; focused ISF and composition tests; git diff --check`
  Commit: `ISF-COMPOSITION.1: inventory current handoff gaps`

- ID: `ISF-COMPOSITION.2`
  Status: `done`
  Goal: `Specify public ISF child/spawn composition semantics.`
  Acceptance: `The tree records the accepted syntax, generated artifact
  ownership, parent/child identity rules, parameter binding rules, and rejected
  cases.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-COMPOSITION.2: specify public semantics`

- ID: `ISF-COMPOSITION.3`
  Status: `done`
  Goal: `Implement spawn parameter binding in the ISF IR/lowering path.`
  Acceptance: `Valid spawn parameter bindings preserve through lowering, and
  malformed or unsupported bindings fail before misleading scheduled artifacts
  are emitted.`
  Verification: `perl -c LoweringIR; perl -Iperl -c Emitter::FSM; focused
  spawn/composition/metadata tests; ci-regression isf --no-book; mdbook build;
  git diff --check`
  Commit: `ISF-COMPOSITION.3: implement spawn parameter binding`

- ID: `ISF-COMPOSITION.4`
  Status: `done`
  Goal: `Implement generated top/composition handoff for ISF parent/child artifacts.`
  Acceptance: `The covered ISF multi-file output can be consumed by the
  existing generation pipeline to produce a wired parent/child top for the
  agreed fixture set.`
  Verification: `syntax checks; focused public/fixture tests; generated top
  CLI-to-HDL probe; ci-regression isf --no-book; mdbook build; git diff --check`
  Commit: `ISF-COMPOSITION.4: implement generated top handoff`

- ID: `ISF-COMPOSITION.5`
  Status: `active`
  Goal: `Add diagnostics and bounded schedule-report metadata.`
  Children: `ISF-COMPOSITION.5.1`, `ISF-COMPOSITION.5.2`,
  `ISF-COMPOSITION.5.3`, `ISF-COMPOSITION.5.4`

- ID: `ISF-COMPOSITION.5.1`
  Status: `done`
  Goal: `Define the bounded composition schedule-report and diagnostic projection schema.`
  Acceptance: `The task tree, ISF spec, public contract, and book state the
  public report fields for generated top, parent, child files, spawned
  instances, handoff links, parameter bindings, and the targeted diagnostics
  expected from composition/spawn lowering.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-COMPOSITION.5.1: define report schema`

- ID: `ISF-COMPOSITION.5.2`
  Status: `done`
  Goal: `Implement bounded generated-composition schedule-report metadata.`
  Acceptance: `Successful multi-file spawn reports expose bounded parent,
  generated top, child, instance, handoff, and parameter-binding metadata
  without leaking raw LoweringIR internals.`
  Verification: `syntax checks; focused public report/contract/composition tests; mdbook build docs/book; git diff --check`
  Commit: `ISF-COMPOSITION.5.2: project composition report metadata`

- ID: `ISF-COMPOSITION.5.3`
  Status: `pending`
  Goal: `Add targeted diagnostics for generated-composition lowering failures.`
  Acceptance: `Composition/spawn failures that can occur after syntax-level
  validation fail with source-local, actionable diagnostics instead of generic
  Perl or composition-pipeline fallout.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-COMPOSITION.5.4`
  Status: `pending`
  Goal: `Close schedule-report/diagnostic documentation and regression coverage.`
  Acceptance: `Focused tests, ISF spec, public interface contract, mdBook,
  roadmap, live docs, and task tree agree on shipped generated-composition
  report and diagnostic behavior.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-COMPOSITION.6`
  Status: `pending`
  Goal: `Add focused regressions, realistic fixture coverage, and docs.`
  Acceptance: `Tests cover valid binding, invalid binding, generated top
  handoff, schedule-report metadata, CLI behavior, and synchronized docs.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-COMPOSITION.7`
  Status: `done`
  Goal: `Document static spawn lifetime and repeat activation semantics.`
  Acceptance: `The book and live ISF docs state that spawn elaborates static
  HDL instances, runtime control only activates them, future spawn-in-repeat
  reuses the lexical instance instead of creating dynamic hardware, and dynamic
  repeat counts are runtime counter loads with zero-count and busy semantics
  still needing explicit shipped policy.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-COMPOSITION.7: document spawn repeat lifetime`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-COMPOSITION.5.3` | `pending` | The successful generated-composition report projection is now implemented; the next step is targeted failure diagnostics. |

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

## ISF-COMPOSITION.2 Public Semantics

`ISF-COMPOSITION.2` establishes the accepted user-facing contract for the
implementation leaves. It is a target contract: until the implementation leaves
land, the current shipped behavior remains the inventory described above.

### Accepted Authoring Syntax

The existing unparameterized spawn form stays valid:

```lisp
(spawn child_worker as w0)
```

Parameterized spawned children use one optional nested `params` block after
the instance name:

```lisp
(transaction child_worker
  (params
    (WIDTH 8)
    (LANES (8'h00 8'h00)))
  ...)

(transaction parent_main
  (on trigger)
  (spawn child_worker as w0
    (params
      (WIDTH 16)
      (LANES (8'hA5 8'h3C))))
  (await_all done)
  (complete done))
```

The first shipped parameter-binding surface is deliberately spawn-only. Blocking
`(do child)` remains unparameterized until a separate need is proven.

### Generated Artifact Ownership

- ISF lowering owns scheduled parent and child `.fsm` emission.
- For a multi-file spawn actor, the canonical composition handoff is an
  explicit generated top over the scheduled parent module and spawned child
  modules. The implementation may materialize that handoff as a concrete
  `?top` source or as equivalent structured metadata consumed by the existing
  composition pipeline, but one handoff must be canonical for reports and
  tests.
- The scheduled parent module keeps the actor name for compatibility. The
  generated top must use a distinct deterministic name, initially
  `<actor_name>_top`, to avoid colliding with the scheduled parent module.
- The top re-exports the actor's public interface. Per-instance start/done
  handoff signals are child-to-child links inside the generated top, not public
  top ports unless the actor explicitly declares such ports later through a
  separate feature.

### Spawn Lifetime And Repeated Activation

- A spawned child instance is static HDL. It is elaborated into the generated
  top and exists for the lifetime of that top.
- Executing a spawn state at runtime only activates the instance through its
  start path. Completion returns that same instance to start-gated idle; it
  does not destroy the instance.
- Reaching the same lexical spawn again must reuse the same instance.
- Future `(spawn ...)` support inside `(repeat ...)` must therefore mean
  repeated activation of one lexical instance, not dynamic creation of one
  instance per iteration.
- A spawn-in-repeat implementation needs an explicit busy rule: prove or insert
  sequencing so a later iteration waits for the child's fresh done pulse, or
  reject the path before scheduled artifacts are emitted.
- A dynamic repeat count is not a structural instance count. It is a runtime
  counter load. Dynamic counts are compatible with static HDL topology when the
  count width is known, but they make latency data-dependent and require an
  explicit zero-count policy before the repeat surface is fully general.

### Parent/Child Identity And Wiring

- Spawn target names resolve to declared same-actor transactions. Forward
  references stay valid; missing targets still fail before scheduled artifacts
  are emitted.
- Spawn instance names are actor-local instance identities. Duplicate spawn
  instance names are rejected before scheduled artifacts are emitted.
- One scheduled child module is emitted per unique spawned transaction target.
  Multiple spawned instances of the same transaction instantiate the same child
  module with distinct instance names.
- The scheduled parent exposes each `instance_start` as an output port and each
  `instance_done` as an input port in the parent child-interface used by the
  generated top.
- Each spawned child exposes `start` as an input and `done` as an output. The
  generated top wires `parent.instance_start` to `instance.start` and
  `instance.done` to `parent.instance_done`.
- After a spawned child completes, it returns to its `start`-guarded idle state.
  It must not re-enter the child body until the next start pulse.

### Parameter Binding Rules

- Spawned child transaction parameter declarations use a transaction-local
  `params` clause. Parameter names must be HDL-identifier-compatible, scalar,
  non-empty, and unique within the child transaction.
- Spawn parameter overrides use at most one nested `params` block. Override
  names must be HDL-identifier-compatible, scalar, non-empty, and unique within
  the spawn.
- An override name must match a parameter declared by the spawned child
  transaction. Unknown overrides fail closed.
- Missing overrides use the child transaction's default parameter value.
- The first shipped value domain reuses the existing composition generated-child
  parameter value rules where they apply: scalar numeric/exact-width literals
  remain width-flexible, and aggregate/list defaults require compatible
  aggregate/list override shape. Symbolic top constants are not accepted until
  ISF has an explicit constant/symbol surface.
- Parameter overrides are instance-local. Two instances of the same child
  transaction may bind different parameter values.
- The scheduled child `.fsm` carries direct `+params` declarations derived from
  the child transaction parameters. The generated top carries the instance
  overrides through the existing generated-child composition parameter override
  path.

### Rejected Cases

The following cases are public fail-closed behavior for the implementation
leaves:

- malformed `spawn` forms, including missing `as`, missing instance name, nested
  child names, nested instance names, or extra unsupported blocks;
- duplicate spawn instance names in one actor;
- unknown spawn targets;
- multiple `params` blocks on one spawn or one child transaction;
- malformed parameter declarations or overrides;
- duplicate parameter declarations or duplicate overrides;
- override names not declared by the spawned child transaction;
- aggregate/scalar shape mismatches;
- symbolic parameter values that cannot be resolved by the first shipped ISF
  value domain;
- parameter declarations on non-spawned transactions; and
- parameter blocks on `(do child)`.

## ISF-COMPOSITION.3 Spawn Parameter Binding

`ISF-COMPOSITION.3` implements the spawn parameter surface in the ISF
IR/lowering path while deliberately stopping short of generated-top
instantiation.

### Shipped Behavior

- Transaction-local `(params (NAME value) ...)` clauses are accepted on spawned
  child transactions and validated before scheduled `.fsm` artifacts are
  emitted. Parameter declarations on non-spawned transactions fail closed.
- Spawn clauses may carry one nested `(params (NAME value) ...)` override
  block after the instance name.
- Spawn instance names are actor-local and must be unique.
- Child parameter names and spawn override names must be scalar
  HDL-identifier-compatible names and unique in their local declaration block.
- Spawn override names must match parameters declared by the target child
  transaction.
- The first value domain accepts scalar decimal literals, exact-width numeric
  literals, and non-empty aggregate/list literals with compatible shape.
  Symbolic constants still fail closed until ISF has its own constant/symbol
  surface.
- Spawned child scheduled `.fsm` files now emit child transaction defaults in a
  direct `+params` block.
- The parent lowerer IR preserves each spawned instance's override list in a
  `spawn_instances` collection for the later generated-top handoff.
- `(do child)` remains unparameterized; parameter blocks on `do` still fail
  closed.

### Remaining Boundary

The generated top that wires parent start outputs, parent done inputs, child
`start`/`done` ports, and per-instance parameter overrides remains
`ISF-COMPOSITION.4`. Until that leaf lands, the per-instance override values
are validated and preserved in lowerer metadata but are not yet applied to HDL
child instances.

## ISF-COMPOSITION.4 Generated Top Handoff

`ISF-COMPOSITION.4` implements the concrete generated-top composition handoff
over scheduled parent and child `.fsm` artifacts for the covered spawned-child
fixtures.

### Shipped Behavior

- Spawn actors now lower to a deterministic generated `<actor>_top.fsm`
  composition source in addition to the scheduled parent `<actor>.fsm` and one
  scheduled child `.fsm` per unique spawned transaction target.
- The CLI selects the generated top as the HDL entrypoint whenever it is
  present. `--outdir` materializes the same lower-result file map, including
  the top, and the normal `.fsm` composition pipeline compiles that top to HDL.
- The scheduled parent exposes every `instance_start` signal as an output port
  and every `instance_done` signal as an input port. The generated top wires
  `parent.instance_start` to `instance.start` and `instance.done` to
  `parent.instance_done`.
- Spawned children now return to their start-gated entry state after a
  terminal state. They do not re-enter the child body until the next `start`
  pulse.
- Named drive calls inside spawned children no longer directly expose the
  actor output they conceptually drive. Instead, the child exposes
  `<drive>_start` plus one `<drive>_<param>` output per drive parameter.
- The parent exposes matching per-instance handoff inputs such as
  `w0_rdata_start` and `w0_rdata_val`. The generated top wires child handoff
  outputs to those parent handoff inputs.
- The parent drive DT aggregates local drive calls and spawned-child handoff
  sources through the actor drive body. For example, a child `rdata` drive
  becomes parent assignments guarded by `w0_rdata_start`, `w1_rdata_start`,
  and so on, each selecting the corresponding per-instance payload.
- The scheduled `.fsm` emitter now marks declared output ports with `>` across
  all assignment families, so parent start outputs, child drive handoff
  outputs, and ordinary public output updates remain visible to the composition
  pipeline.
- Spawn parameter overrides are applied through generated `?fsmc` parameter
  override blocks such as `(?fsmc:w0 child_worker (params ...))`, reusing the
  existing generated-child composition parameter validator and SystemVerilog
  instance-parameter emission.
- Child public actor outputs are exposed only when the spawned child assigns
  them directly as actor outputs. Drive-call-owned actor outputs stay behind
  the per-instance drive handoff boundary.

### Remaining Boundary

Schedule reports now keep ordinary transaction, storage, and DT summaries
parent-scoped, while the `generated_composition` field exposes bounded
generated top, child, instance, handoff, and parameter-binding metadata for
spawned-child actors. Targeted failure diagnostics remain the next
`ISF-COMPOSITION.5` leaf family.

`spawn` inside `repeat` remains unimplemented. The accepted design direction is
static instance lifetime plus repeated runtime activation of the same lexical
instance. The future implementation must define busy/re-entry diagnostics or
sequencing and the zero-count repeat policy before claiming full support.

## ISF-COMPOSITION.5.1 Report And Diagnostic Schema

`ISF-COMPOSITION.5.1` defines the target public projection before implementation
widens successful schedule JSON.

### Generated Composition Report Field

The accepted top-level field is `generated_composition`.

- Reports with no generated composition top use JSON null.
- Spawned-child generated-top reports use an object with `kind`, `top_module`,
  `top_fsm`, `parent`, `children`, and `instances`.
- `kind` is currently `spawn_generated_top`.
- `parent` exposes `module` and `scheduled_fsm`.
- Each child entry exposes `transaction`, `module`, `scheduled_fsm`, and
  `parameters`. Parameter entries expose `name` and stringified `default`.
- Each instance entry exposes `instance`, `child`, `start`, `done`,
  `parameter_bindings`, and `drive_handoffs`.
- `start` exposes `parent_port` and `child_port`.
- `done` exposes `child_port` and `parent_port`.
- `parameter_bindings` entries expose `name`, `source`, and stringified
  `value`; `source` is `default` or `override`.
- `drive_handoffs` entries expose `drive`, `request`, and `payloads`.
- A drive `request` exposes `child_port` and `parent_port`.
- Drive payload entries expose `parameter`, `child_port`, `parent_port`, and
  `width`.

The projection is a bounded review/discovery summary. It must not expose raw
LoweringIR records, raw composition parser objects, raw `?toplink` arrays,
assignment provenance, activation context, or private port-inference internals.

## ISF-COMPOSITION.5.2 Generated Composition Report Projection

`ISF-COMPOSITION.5.2` implements the successful-report projection defined by
`ISF-COMPOSITION.5.1`.

### Shipped Behavior

- Every schedule report now includes the top-level `generated_composition`
  key.
- Actors without spawned-child generated tops report JSON null for that key.
- Spawned-child actors report `kind => spawn_generated_top`, deterministic
  generated top module/file names, and the scheduled parent module/file.
- Child summaries expose spawned child transaction/module names, scheduled
  child `.fsm` basenames, and stringified parameter defaults.
- Instance summaries expose authored instance names, child names, start/done
  handoff links, default-or-override parameter bindings, and named-drive
  request/payload handoff links.
- The report object is built from bounded lowerer metadata. It does not expose
  raw LoweringIR records, raw composition parser objects, raw `?toplink`
  syntax, activation context, assignment provenance, or private port-inference
  internals.

The ISF public-interface contract advertises the generated-composition key
families and the `spawn_generated_top` kind value, and the capability manifest
publishes the same metadata through `embedding.isf_public_interface`.

The contract remains live. Exact tests in this leaf prove the current
advertised surface matches the implementation and documentation; they do not
freeze the ISF API or the full schedule-report schema.

### Diagnostic Projection Boundary

Generated composition diagnostics should fail before misleading scheduled
artifacts or generated tops are emitted. A targeted diagnostic in this family
should name the relevant transaction, spawn instance, child transaction,
parameter, generated top, or handoff link.

Already-covered diagnostic families include malformed spawn syntax, unknown
child targets, duplicate instance names, parent actor naming conflicts,
malformed or duplicate parameter declarations/overrides, unknown override
names, aggregate/scalar shape mismatches, parameter declarations on
non-spawned transactions, and parameterized `(do child)`. The next diagnostics
leaf audits and adds targeted diagnostics for post-syntax generated-top and
handoff failures that can still fall through to generic composition-pipeline
errors.

## Decisions

- `2026-05-14`: This tree owns the ISF-specific generated-child top and spawn
  parameter objective. General composition language changes remain outside this
  tree unless they are required by the ISF handoff.
- `2026-05-14`: `ISF-COMPOSITION.1` confirms that current ISF multi-file
  lowering emits parent/child scheduled `.fsm` artifacts but no generated top,
  and that the parent start signals are internal rather than wireable
  composition ports.
- `2026-05-14`: `ISF-COMPOSITION.2` selects an explicit generated-top handoff
  over scheduled parent/child modules, with `<actor_name>_top` as the initial
  top name, parent start outputs, parent done inputs, reusable start-gated
  spawned children, and spawn-only parameter overrides using one nested
  `(params ...)` block.
- `2026-05-14`: `ISF-COMPOSITION.3` ships the spawn parameter parser/lowering
  surface but keeps generated-top application as a separate leaf. The child
  scheduled `.fsm` carries default `+params`, and parent lowerer metadata keeps
  instance-local override lists for `ISF-COMPOSITION.4`.
- `2026-05-14`: `ISF-COMPOSITION.4` selects a concrete generated `?top`
  source as the canonical handoff artifact. The `.fsm` text boundary remains
  the integration point: ISF emits scheduled parent/child sources plus the top,
  and the existing composition pipeline owns HDL realization.
- `2026-05-14`: `spawn` is static HDL composition plus runtime activation.
  Future spawn-in-repeat support must reuse one lexical child instance per
  spawn name and must settle busy/re-entry and zero-count repeat policy before
  becoming a shipped authoring surface.
- `2026-05-14`: `ISF-COMPOSITION.5` is split into executable leaves before
  implementation because it widens successful schedule JSON and diagnostic
  behavior. Schema definition comes first, then report projection, targeted
  diagnostics, and synchronized regression/docs closure.
- `2026-05-14`: `ISF-COMPOSITION.5.1` defines the bounded
  `generated_composition` report shape and diagnostic projection boundary
  before emitter or contract code is widened.
- `2026-05-14`: `ISF-COMPOSITION.5.2` ships the successful-report projection
  for generated composition while keeping the ISF contract live rather than
  frozen. The field is public discovery metadata for current generated tops,
  not a broad promise that raw scheduler internals or every current report key
  are permanent.

## Open Questions

- Future symbolic constant support for ISF spawn parameters waits for an
  explicit ISF constant/symbol surface.
- Targeted post-syntax diagnostics for generated top and handoff failures
  remain in `ISF-COMPOSITION.5.3`.

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
| `2026-05-14` | `ISF-COMPOSITION.2` | `mdbook build docs/book` | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.2` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.3` | `perl -c perl/FSM/Scheduler/ISF/LoweringIR.pm` | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.3` | `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm` | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.3` | `prove -l t/1215-isf-spawn-parameter-binding.t` | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.3` | `prove -l t/1204-isf-child-composition-clause-boundary.t t/1144-isf-public-tested-by-metadata-audit.t` | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.3` | `prove -l t/1117-isf-public-lower-result-files-audit.t t/1122-isf-public-cli-outdir-lowering-audit.t t/1128-isf-public-multifile-schedule-report-audit.t t/1184-isf-child-transaction-target-boundary.t` | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.3` | `prove -l t/184-composition-generated-child-realizer.t t/292-composition-generated-child-parameter-overrides.t` | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.3` | `./bin/ci-regression isf --no-book` | `passed; 123 files, 417 tests` |
| `2026-05-14` | `ISF-COMPOSITION.3` | `mdbook build docs/book` | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.3` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.4` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm; perl -Iperl -c perl/FSM/Scheduler/ISF.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm; perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; perl -Iperl -c bin/fsmgen; perl -Iperl -c t/1216-isf-generated-composition-top.t` | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.4` | `prove -l t/1117-isf-public-lower-result-files-audit.t t/1122-isf-public-cli-outdir-lowering-audit.t t/1128-isf-public-multifile-schedule-report-audit.t t/1139-isf-public-lower-result-metadata-audit.t t/1142-isf-public-guidance-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1153-isf-public-cli-success-metadata-audit.t t/1156-isf-public-lower-result-file-shape-audit.t t/1215-isf-spawn-parameter-binding.t t/1216-isf-generated-composition-top.t` | `passed; 10 files, 20 tests` |
| `2026-05-14` | `ISF-COMPOSITION.4` | `prove -l t/1096-isf-schedule-json-report.t t/1097-isf-start-signal-binding.t t/1099-isf-repeat-data-ops.t t/1100-isf-sample-piggyback.t t/1101-isf-extract-slices.t t/1105-isf-size-deduplication.t t/1106-isf-schedule-json-counter-storage.t t/1111-isf-sample-before-data-ops.t t/1119-isf-deterministic-dt-block-order.t t/1121-isf-public-cli-schedule-report-audit.t t/1168-isf-rule-guard-factoring.t t/1169-isf-rule-shorthand-guard.t t/1177-isf-do-child-done-pulse.t t/1184-isf-child-transaction-target-boundary.t t/1194-isf-drive-body-boundary.t t/1196-isf-complete-clause-boundary.t t/1198-isf-update-clause-boundary.t t/1199-isf-shift-clause-boundary.t t/1200-isf-assemble-clause-boundary.t t/1201-isf-extract-clause-boundary.t t/1204-isf-child-composition-clause-boundary.t t/1207-isf-assignment-provenance-inventory.t t/1210-isf-priority-conflict-resolution.t` | `passed; 23 files, 157 tests` |
| `2026-05-14` | `ISF-COMPOSITION.4` | `./bin/fsmgen --quiet --outdir /tmp/isf-spawn-parent-cli.* --output /tmp/isf-spawn-parent-cli.*/spawn_parent.sv isf/spawn_parent.isf` | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.4` | `./bin/ci-regression isf --no-book` | `passed; 124 files, 419 tests` |
| `2026-05-14` | `ISF-COMPOSITION.4` | `mdbook build docs/book` | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.4` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.7` | `mdbook build docs/book` | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.7` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.5` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.5.1` | `mdbook build docs/book` | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.5.1` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.5.2` | `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; perl -Iperl -c t/1217-isf-generated-composition-schedule-report.t` | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.5.2` | `prove -l t/1096-isf-schedule-json-report.t t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1121-isf-public-cli-schedule-report-audit.t t/1128-isf-public-multifile-schedule-report-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1142-isf-public-guidance-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1154-isf-public-facade-return-metadata-audit.t t/1215-isf-spawn-parameter-binding.t t/1216-isf-generated-composition-top.t t/1217-isf-generated-composition-schedule-report.t` | `passed; 12 files, 22 tests` |
| `2026-05-14` | `ISF-COMPOSITION.5.2` | `./bin/ci-regression isf --no-book` | `passed; 125 files, 421 tests` |
| `2026-05-14` | `ISF-COMPOSITION.5.2` | `mdbook build docs/book` | `passed` |
| `2026-05-14` | `ISF-COMPOSITION.5.2` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-COMPOSITION` | `R14: map ISF objectives to task trees` | Initial tree creation belongs to the ISF objective task-tree coverage slice. |
| `ISF-COMPOSITION.1` | `ISF-COMPOSITION.1: inventory current handoff gaps` | Records current ISF child/spawn lowering, existing composition entrypoints, unsupported spawn parameters, and exact gaps. |
| `ISF-COMPOSITION.2` | `ISF-COMPOSITION.2: specify public semantics` | Defines the accepted generated-top handoff, parent/child identity and wiring, spawn parameter syntax, value domain, and rejected cases. |
| `ISF-COMPOSITION.3` | `ISF-COMPOSITION.3: implement spawn parameter binding` | Validates spawn parameter declarations/overrides, emits child `+params`, and preserves per-instance override metadata for generated-top handoff. |
| `ISF-COMPOSITION.4` | `ISF-COMPOSITION.4: implement generated top handoff` | Emits the generated top, wires start/done and named-drive handoffs, applies spawn parameter overrides, and compiles spawn fixtures through the composition pipeline. |
| `ISF-COMPOSITION.7` | `ISF-COMPOSITION.7: document spawn repeat lifetime` | Records static HDL spawn lifetime, future repeat activation semantics, dynamic repeat-count implications, and unshipped busy/zero-count boundaries. |
| `ISF-COMPOSITION.5` | `ISF-COMPOSITION.5: split report diagnostic work` | Splits broad report/diagnostic work into schema, projection, diagnostics, and closure leaves. |
| `ISF-COMPOSITION.5.1` | `ISF-COMPOSITION.5.1: define report schema` | Defines the bounded generated-composition schedule-report field and diagnostic projection boundary. |
| `ISF-COMPOSITION.5.2` | `ISF-COMPOSITION.5.2: project composition report metadata` | Emits bounded generated-composition schedule-report metadata and advertises its key families through the live ISF public contract. |

## Changelog

- `2026-05-14`: Created the active ISF composition/spawn task tree.
- `2026-05-14`: Completed `ISF-COMPOSITION.1`; current frontier moves to
  `ISF-COMPOSITION.2` for public child/spawn composition semantics.
- `2026-05-14`: Completed `ISF-COMPOSITION.2`; current frontier moves to
  `ISF-COMPOSITION.3` for spawn parameter binding implementation.
- `2026-05-14`: Completed `ISF-COMPOSITION.3`; current frontier moves to
  `ISF-COMPOSITION.4` for generated-top composition handoff.
- `2026-05-14`: Completed `ISF-COMPOSITION.4`; current frontier moves to
  `ISF-COMPOSITION.5` for generated-top diagnostics and bounded
  schedule-report metadata.
- `2026-05-14`: Completed `ISF-COMPOSITION.7` as a documentation-only
  clarification; current frontier remains `ISF-COMPOSITION.5`.
- `2026-05-14`: Split `ISF-COMPOSITION.5` into executable leaves; current
  frontier moves to `ISF-COMPOSITION.5.1`.
- `2026-05-14`: Completed `ISF-COMPOSITION.5.1`; current frontier moves to
  `ISF-COMPOSITION.5.2`.
- `2026-05-14`: Completed `ISF-COMPOSITION.5.2`; current frontier moves to
  `ISF-COMPOSITION.5.3`.
