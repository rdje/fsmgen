# AXI Intent-Capture Case Study

This note preserves the detailed lessons extracted from an external AXI
workspace outside this repository. The original local filesystem location is
intentionally not recorded here.

It is the current best concrete reference for the future `H4` intent-capture
lane:
- `PDF` / spec / protocol / bounded RTL-block document to `.fsm`
- via normalized `Markdown`
- with explicit staged validation and explicit residue reporting

Use this note when future work starts on:
- protocol/TRM/spec-to-`.fsm` intent capture,
- reusable protocol-role libraries,
- capture reports,
- verification-plan generation from captured intent,
- or the broader “executable PDF” direction.

## External source inventory

Primary source workspace:
- external AXI protocol workspace, not tracked in this repository

Key extracted method files:
- `PROTOCOL_EXTRACTION_METHOD.md`
- `PROTOCOL_PDF_TO_FSM_REFERENCE.md`
- `PROTOCOL_EXTRACTION_PROMPT.md`
- `PROTOCOL_EXTRACTION_WORKSHEET.md`

AXI-specific applied artifacts:
- `AXI_PROTOCOL_DOSSIER.md`
- `AXI_ACTOR_CATALOG.md`
- `AXI_FSM_DECOMPOSITION.md`
- `AXI_CORE_EXTRACTION_WORKSHEET.md`
- `fsm/transport_valid_ready_channel.fsm`

Normalized source material:
- `IHI0022L_amba_axi_protocol_spec.pdf`
- `md/IHI0022L_amba_axi_protocol_spec.md`
- `md/IHI0022L_amba_axi_protocol_spec/IHI0022L_amba_axi_protocol_spec_meta.json`

## What The AXI Workspace Already Proves

This AXI workspace is not just a prompt and a few ideas. It is already a
first-generation prototype of a serious intent-capture workflow.

It proves that a useful protocol/spec capture lane should:
- start from converted, searchable `Markdown` rather than raw `PDF`,
- preserve document identity, conversion commands, and section anchors,
- work actor-first rather than protocol-as-a-monolith,
- define phases before final FSM states,
- define persistent-state needs from protocol language rather than inventing
  states too early,
- separate source facts from derived rules, local design decisions, and
  explicit abstractions,
- and emit validation-ready `.fsm` artifacts only after dossier/catalog/sheet
  work exists.

It also proves that:
- reusable transport micro-actors are a real asset class,
- interconnect/order/realignment behavior must be modeled as its own actor,
- and explicit abstraction logging is not optional if first-pass capture is to
  remain honest.

## Durable Method Extracted

The strongest reusable method from the AXI workspace is:

1. convert the source `PDF` into normalized `Markdown`
2. verify document identity and conversion quality
3. build a section map with exact source anchors
4. build a protocol dossier
5. build an actor catalog
6. build an actor sheet per actor
7. capture interfaces
8. capture phases before states
9. capture persistent state needs
10. capture invariants, contracts, gates, and assertion candidates
11. capture abstractions and boundedness explicitly
12. define `.fsm` decomposition
13. emit `.fsm`
14. validate and back-annotate against the source

The required classification boundary is especially important:
- source facts
- derived machine rules
- local design decisions
- explicit abstractions

This distinction should remain mandatory in future FSMGen intent-capture work.
It is the difference between honest recovery and fake precision.

## AXI-Specific Modeling Choices Worth Reusing

### Actor-first decomposition

The AXI workspace correctly avoids one giant AXI state machine.

Its confirmed actor set is:
- reusable transport micro-actor:
  - `valid_ready_channel_tx_rx`
- reusable transport micro-actor:
  - `credited_channel_tx_rx`
- core path actors:
  - `manager_write_path`
  - `manager_read_path`
  - `subordinate_write_path`
  - `subordinate_read_path`
- interconnect actor:
  - `interconnect_order_route_realign`
- deferred extension actors:
  - atomic
  - cache/coherency-related feature layers
  - DVM/snoop family

This is a strong steering signal for future protocol capture:
- separate transport from transaction semantics,
- separate read from write,
- separate endpoint behavior from interconnect behavior,
- and separate baseline behavior from optional feature layers.

### Phases before states

The worksheets define phases and phase exit/hold/stall conditions before
freezing state names.

That is the right order.

Future intent-capture automation should preserve this:
- phase extraction first,
- persistent-state inference second,
- emitted FSM states only after those are stable.

### Explicit abstraction logging

The AXI worksheets explicitly record first-pass fidelity limits such as:
- `payload_generic`
- `local_aw_first_policy_possible`
- `no_chunking_first_pass`
- `aw_before_w_first_pass`
- `no_interleave_first_pass`
- `no_early_response_first_pass`
- `bounded_scoreboard_first_pass`

This is one of the best parts of the whole method.

Future FSMGen capture work should never silently collapse legal behavior.
It should instead:
- record the abstraction,
- describe the protocol feature being narrowed,
- state the fidelity impact,
- and keep a removal path for later refinement.

### Assertion-ledger discipline

The AXI worksheets do not jump directly from prose to `.fsm`.
They also build:
- safety assertions,
- stability assertions,
- causality assertions,
- ordering assertions,
- bounds assertions,
- and liveness-with-assumptions assertions.

That means verification intent is being recovered alongside implementation
intent.

This should remain a core part of the future lane.

## What The First Emitted AXI `.fsm` Tells Us

`fsm/transport_valid_ready_channel.fsm`
is exactly the right kind of first emitted asset:
- small,
- reusable,
- explicit about scope,
- explicit about abstraction,
- and already executable through FSMGen strict mode.

It shows a healthy first-emission principle for intent capture:
- do not start with the hardest top actor,
- start with the smallest reusable actor that locks one invariant family
  correctly.

For future protocol capture, this suggests:
- transport actors first,
- path actors second,
- interconnect/ordering actors after that,
- optional feature layers last.

## Strongest Reusable Lessons For FSMGen

The AXI workspace suggests the following durable steering:

- Intent capture should be actor-first.
- Normalized `Markdown` should be the minimum textual entrypoint.
- A protocol/spec dossier is not optional.
- Interfaces should be defined before final states.
- Phases should be defined before final states.
- Persistent state should be justified from protocol rules.
- Invariants/contracts/gates/assertions should be recovered before `.fsm`
  emission.
- Abstraction and boundedness logs should be first-class outputs.
- The capture flow should emit both implementation artifacts and residue
  reports.
- Reusable transport and protocol micro-actors should feed the future library
  lane.

## What Still Looks First-Generation

The AXI workspace is strong, but it is still early.

Important current limitations:
- only one actual `.fsm` has been emitted so far,
- the local-side actor interfaces are sensible but still partly invented ad
  hoc,
- the worksheets are rich but still prose-heavy,
- and the process is methodical but not yet systematized into a machine-checked
  capture IR.

That points to likely future refinement work:
- define a normalized spec/capture IR,
- define a structured artifact schema for dossier/catalog/sheet/assertion data,
- standardize local actor-side interface conventions,
- and build stage gates that can verify artifact completeness before emission.

## Long-Term Target: Executable PDF

The long-term target saved from this brainstorming pass is stronger than “PDF
to `.fsm`”.

The real target is an almost fully staged automated flow that treats a bounded
protocol or RTL-block `PDF` as an executable intent source.

Desired end-state:
- feed a protocol/specification/RTL-block `PDF` or its normalized `Markdown`
  into the flow,
- recover the full executable intent into a coherent set of `.fsm` files,
- emit an integration/testbench-ready top or harness,
- emit a set of tests or executable scenarios,
- emit a verification plan,
- emit a functional-coverage plan,
- and emit a capture report that says what is solid, inferred, abstracted, or
  unresolved.

That is the right long-term picture for this lane.

The phrase “executable PDF” should be read as:
- not magical inversion,
- not blind text-to-code,
- but a staged evidence-driven capture flow whose outputs are executable,
  reviewable, and verification-oriented.

## Preferred Automated Stage Flow

Future FSMGen intent-capture work should aim for a staged automated flow with
explicit stage contracts and validation gates.

### Stage 0: Source normalization
- input:
  - `PDF` or equivalent source document
- output:
  - normalized `Markdown`
  - preserved metadata
  - preserved figures/tables/assets where useful
- gate:
  - document identity verified
  - conversion quality acceptable
  - main headings/sections/tables readable enough to continue

### Stage 1: Source anchoring and dossier
- input:
  - normalized `Markdown`
- output:
  - protocol/block dossier
  - section map
  - scope and deferred-scope statement
- gate:
  - all major extracted conclusions have source anchors
  - included vs deferred scope is explicit

### Stage 2: Actor discovery
- input:
  - dossier plus anchored source
- output:
  - actor catalog
  - role model
  - actor boundary rationale
- gate:
  - actor set stable enough for first-pass work
  - no giant-monolith fallback hidden in the background

### Stage 3: Interface and phase extraction
- input:
  - actor catalog
- output:
  - actor sheets with:
    - bus inputs/outputs
    - local inputs/outputs
    - phase model
    - persistent-state candidates
- gate:
  - interfaces are defined before state emission
  - phases are defined before state emission
  - persistent state is justified

### Stage 4: Contract / invariant / gate / assertion extraction
- input:
  - actor sheets
- output:
  - invariant set
  - contract set
  - gate/guard set
  - assertion ledger
- gate:
  - every actor has explicit safety/stability/causality coverage
  - liveness claims are marked with assumptions when needed
  - gate classes are explicit enough to drive state transitions honestly

### Stage 5: Abstraction and boundedness control
- input:
  - actor sheets plus extracted rules
- output:
  - abstraction log
  - boundedness log
  - fidelity-impact notes
- gate:
  - every intentional simplification is explicit
  - legal protocol behavior is not silently dropped
  - the first-pass model’s limits are reviewable

### Stage 6: Decomposition and hierarchy planning
- input:
  - stabilized actors and abstractions
- output:
  - `.fsm` decomposition plan
  - reusable micro-actor plan
  - non-leaf composition/module plan
- gate:
  - decomposition matches actor boundaries
  - reusable leaves are separated from higher-level composition
  - future hierarchy is enabled rather than flattened away

### Stage 7: `.fsm` emission
- input:
  - decomposition plan
- output:
  - emitted `.fsm` set
- gate:
  - emitted FSMs satisfy the captured invariants/contracts/gates
  - emitted artifacts preserve stated abstractions
  - strict-mode parse/generation succeeds

### Stage 8: Verification-asset emission
- input:
  - emitted `.fsm` set plus assertion ledger
- output:
  - `.fsm` composition or testbench harness
  - scenario list / test plan
  - executable tests where possible
  - functional-coverage plan
  - verification plan
- gate:
  - the emitted verification assets map back to the recovered contracts and
    assertions
  - coverage intent is not separated from capture intent

### Stage 9: Capture report and back-annotation
- input:
  - all prior stages
- output:
  - capture report
  - source-back-annotation
  - unresolved ambiguity list
- gate:
  - the flow distinguishes:
    - confident recovery
    - heuristic inference
    - explicit abstractions
    - unresolved ambiguity
    - unsupported residue

## Relationship To Future FSMGen Architecture

This intent-capture lane fits naturally with several already-saved directions:

- reusable `.fsm` library assets:
  - transport/protocol micro-actors can become reusable assets later
- semantic parameterization:
  - protocol roles and transport actors will eventually benefit from explicit
    semantic parameters
- non-leaf module/composition roots:
  - protocol capture will want reusable non-leaf composition artifacts above
    leaf DT/FSM actors
- intent recovery/import:
  - spec capture remains distinct from HDL import, but both can eventually
    share middle semantic IR layers

The lane should stay distinct from HDL import:
- HDL import starts from implementation evidence,
- spec/TRM intent capture starts from behavioral-contract evidence.

They should not be merged just because both end in `.fsm`.

## Current Recommended Positioning

Current positioning for this lane should remain:
- design/probe ready,
- documentation-rich,
- suitable for bounded experiments,
- but not yet the main implementation lane ahead of active forward-language,
  diagnostics, and backend-convergence work.

That said, this AXI case study materially raises confidence that the lane is
real and worth doing.

It is no longer just a vague aspiration.
It now has:
- a concrete method,
- a concrete worksheet shape,
- a concrete actor decomposition style,
- a concrete first emitted artifact,
- and a concrete long-term target.
