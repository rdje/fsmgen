# IAL1 Verification Code Generation Source Readiness Audit

## Metadata

- Owner leaf: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.2`
- Date: `2026-06-16`
- Status: `complete`
- Outcome: select `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3`.

## Question

Can the shipped IAL1 verification surface directly support first-class
verification-code generation, or does FSMGen need an IAL1 verification-specific
source feature before choosing SV/UVM and VHDL-oriented output contracts?

## Evidence Read

- IAL1/ISF verification surface: `docs/ISF_SPEC.md`,
  `docs/book/src/13d-control-flow.md`,
  `docs/book/src/13h-lowering-reference.md`, and
  `docs/book/src/13k-isf-feature-support-matrix.md`.
- Existing verification task trees: `docs/tasks/ISF-ASSERT.md`,
  `docs/tasks/ISF-ASSERT-CONCURRENT.md`,
  `docs/tasks/ISF-COVER-ASSUME.md`,
  `docs/tasks/ISF-PROPERTY-IMPLICATION.md`,
  `docs/tasks/ISF-PROPERTY-SAMPLED-VALUE.md`,
  `docs/tasks/ISF-PROPERTY-WINDOW-RANGE.md`,
  `docs/tasks/ISF-TRIGGER-ANCHOR.md`,
  `docs/tasks/ISF-TEMPORAL-CONTRACT-ASSERTIONS.md`, and
  `docs/tasks/ISF-TEMPORAL-CONTRACT-STORAGE-REPORTS.md`.
- Lowering and carrier code: `perl/FSM/Scheduler/ISF/LoweringIR.pm`,
  `perl/FSM/Scheduler/ISF/Emitter/FSM.pm`,
  `perl/FSM/Adapter/FSMGenFull/Parser.pm`,
  `perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm`,
  `perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm`, and
  `perl/FSM/Backend/GeneratedModuleEmitter.pm`.
- Public contracts and report boundaries:
  `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`,
  `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`, support-accounting contracts, and
  normalized semantic report contract notes.
- Current VHDL boundary: `docs/tasks/R11-DIRECT-STRUCTURAL-VHDL-REROUTING.md`
  and `docs/knowledge/direct-vhdl-scaffold.md`.
- Accellera/UVM reference material: tracked UVM 1.2 PDFs under
  `docs/vendor/accellera/uvm/` plus the ignored local UVM 1.2 source mirror
  under `.cache/local-references/accellera/uvm/uvm-1.2`.
- Existing Knowledge Map cards:
  `docs/knowledge/isf-fsm-verification-boundary.md`,
  `docs/knowledge/isf-verification-book-map.md`, and
  `docs/knowledge/ial1-verification-code-generation-frontier.md`.

## Findings

The shipped IAL1 verification surface is strong enough for inline
SystemVerilog assertion/property projection. It supports
`assert`/`assume`/`cover`, overlapping implication, `next`, bounded `within`,
event and named anchors, sampled-value predicates, `past`, and the
synthesizable bounded-eventually monitor form
`(assert (monitor (within SIGNAL N)) ...)`.

That surface currently lowers through a thin `.fsm` `+assert` carrier:
`LoweringIR.pm` collects IAL1 checks, `Emitter/FSM.pm` emits `(+assert ...)`,
`FSMGenFull/Parser.pm` parses the carrier and property tree, signal analysis
keeps check-only references live, `GeneratedModuleInfoBuilder.pm` surfaces
`immediate_assertions`, and `GeneratedModuleEmitter.pm` emits
SystemVerilog-only verification blocks. Simulable checks go under
`` `ifndef SYNTHESIS``; delayed sequence checks go under `` `ifdef FORMAL``.
Verilog output stays assertion-free.

That is not the same contract as first-class verification-code generation.
The existing IAL1 source and reports do not yet define:

- passive observation roles for generated verification components;
- an observed interface/channel contract beyond ordinary actor IO;
- transaction/event object metadata suitable for UVM `uvm_sequence_item`
  classes or VHDL/testbench records;
- monitor publication channels such as UVM analysis ports;
- scoreboard compare hooks, expected/actual stream pairing, or ordering
  policy metadata;
- coverage-intent metadata beyond inline `cover property`;
- generated verification artifact identity, package names, component names,
  report paths, and support-accounting entries.

The UVM 1.2 references reinforce that split: monitors, agents, scoreboards,
analysis ports, subscribers, coverage models, and sequence items are component
and transaction-object structures, not just SVA text. A generator that only
knows today's IAL1 property carrier could emit assertion snippets, but it
would not have enough source truth to generate reviewable UVM monitors,
scoreboards, agents, coverage collectors, or reusable VIP with signoff-level
semantics.

The VHDL-oriented path is also not ready for direct output selection. Current
VHDL support is a scaffold with deferred validation/rerouting prerequisites;
a verification artifact would need its own VHDL/PSL-friendly property metadata
and validation gate before it can be claimed.

Direct IAL2-to-verification generation remains an explicit future audit. This
audit does not select a direct IAL2 route; IAL1 remains the source boundary for
the first verification-code generation prerequisites.

## Decision

Existing IAL1 verification primitives are sufficient for the current inline
SV assertion/property path, but insufficient as the sole source contract for
first-class SV/UVM or VHDL-oriented verification-code generation.

Select `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3` as the next leaf:
choose the first IAL1 verification-specific source/report feature family. The
selected feature family should be an observation/source contract before any
output generator is selected.

## Selected Next Slice

`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3` will select a bounded IAL1
verification observation contract. The selector must decide the exact source
spelling, report/schema surface, review artifact, diagnostics, support
accounting, mdBook examples, and validation gates for one first feature
family, expected to cover passive observation roles and source identity for
future monitors/checkers.

It must not implement UVM, VHDL, scoreboard, coverage, reusable VIP, or direct
IAL2 routing behavior. Those remain behind later contract-selection leaves.

## Deferred

- SV/UVM output contract selection remains under
  `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4`.
- VHDL-oriented verification output contract selection remains under
  `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.5`.
- Direct IAL2-to-verification routing remains under
  `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.6`.
- Public CLI/artifact/report/support-accounting behavior for emitted
  verification code remains under
  `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.7`.

