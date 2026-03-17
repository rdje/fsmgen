# Composition Scope

This document defines the concrete `R6` scope for composition-oriented work in the active `bin/fsmgen` architecture.

## Status
- The active toolchain now ships the first `C1` composition lane:
  - one `?top:name`,
  - one child instance, currently `?fsmc`, `?dtc`, or `?rtl`,
  - generated children realized either from the same file or from a searchable external `.fsm` source,
  - external RTL children realized from the shipped `.rtlif` interface contract,
  - either one explicit `?ports` block or an omitted/empty `?ports` shape that triggers bounded single-child top-interface inference,
  - deterministic passthrough top wiring,
  - generated child HDL plus generated top HDL through `bin/fsmgen`.
- The active toolchain now also ships the first `C2` composition lane:
  - two or more generated children (`?fsmc` / `?dtc`),
  - explicit `?toplink` wiring using top-port names and `instance.port` child endpoints,
  - deterministic instance ordering,
  - deterministic internal-net creation for child-to-child wiring,
  - bounded undeclared top-input inference for same-name child inputs that are not already consumed by explicit child-to-child links,
  - duplicate-driver rejection before emission.
- The active toolchain now also ships the first `C3` composition lane:
  - at least one external `?rtl` child,
  - plus any number of generated children (`?fsmc` / `?dtc`) beside those external RTL children,
  - explicit `?toplink` wiring using top-port names and `instance.port` child endpoints,
  - external RTL interface metadata loaded from embedded or sidecar `.rtlif` artifacts,
  - bounded undeclared top-input inference for same-name child inputs that are not already consumed by explicit child-to-child links,
  - deterministic internal-net creation and mixed-child instantiation without regenerating external RTL internals.
- The active toolchain now also ships the first `C4` composition lane:
  - top ports can be declared as `=name` inside `?ports` to request explicit same-name connect-by-name,
  - declared connect-by-name now covers one or more generated children, one or more external `?rtl` children, or any mixture of those generated and external RTL children,
  - declared connect-by-name can also coexist with explicit `?toplink` child-to-child wiring in those same bounded lanes,
  - declared top outputs still require exactly one matching child output,
  - declared top inputs may now fan out to all matching child inputs with the same name and width,
  - the planner still stays deterministic: exact-one-match for top outputs, fanout across fully compatible child inputs for top inputs,
  - ambiguous or missing matches fail explicitly instead of falling back to hidden inference.
- The active toolchain now also ships the first `C6` boundary:
  - out-of-scope legacy composition constructs fail explicitly and point to the scoped composition docs instead of falling through to generic parser behavior.
- `?top:name` inputs are now classified explicitly at the active pipeline boundary, parsed into typed composition IR, and then routed either into the shipped `C1`/`C2`/`C3`/`C4` runtime lanes or a deliberate scope-boundary diagnostic.
- This document remains the normative scope and acceptance boundary for the broader `R6` composition plan.

## Current active boundary
- `bin/fsmgen` currently compiles a single FSM or standalone-DT source into HDL.
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) parses a source file with `Lispish::multi(...)`, classifies the top-level source kind, and routes `?top:name` inputs through a typed composition parser plus the shipped `C1`/`C2`/`C3`/`C4` realization lanes or an explicit scope-boundary diagnostic.
- [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) currently accepts active single-module roots shaped like `?fsm:name`, `?dt:name`, or `+fsm`.

## Current shipped runtime subset
The currently shipped composition behavior is intentionally bounded:
- exactly one top-level `?top:name`,
- zero or one `?ports` block,
- one or more child instances, currently `?fsmc`, `?dtc`, and `?rtl`,
- every generated child must reference exactly one active child source, either embedded in the same file or resolved from an external `.fsm` file,
- `C1` single-child passthrough works without `?toplink` for one `?fsmc`, `?dtc`, or `?rtl` child,
- `C1` may infer the whole top interface directly from that lone child when `?ports` is omitted or empty,
- `C2` multi-generated-child composition uses explicit `?toplink`,
- `C2` and `C3` may now also infer undeclared top inputs when one or more child inputs share the same name, width, and type metadata and those inputs are not already targeted by explicit child-to-child links,
- `C3` explicit-link composition currently supports any explicit-link top with at least one external `?rtl` child, including pure multi-`?rtl`, one-generated-plus-`?rtl`, and multi-generated-plus-`?rtl` mixtures,
- `C4` declared connect-by-name currently supports top ports marked as `=name` inside `?ports` for one or more generated children, one or more external `?rtl` children, or any mixture of those generated and external RTL children,
- each `=name` top output must resolve to exactly one same-named child output with the same width,
- each `=name` top input may resolve to one or more same-named child inputs with the same width,
- mixed-direction or width-mismatched same-name candidates still fail explicitly,
- each `?rtl` child currently loads its interface from an embedded `(?rtlif:module_name ...)` companion root in the same composition source when present, otherwise from a sidecar `<module>.rtlif` metadata file searched first beside the composition source, then through explicit search roots such as repeated `--path DIR`, and then through the existing `FSMLIB` roots,
- the shipped `.rtlif` mini-contract is one flat `(?rtlif:module_name ...)` root with declaration-ordered port tokens such as `clk`, `data_in<8`, `txd>`, `core_clk:clock`, and `rst_async_n:reset`,
- explicit `.rtlif` type annotations are currently limited to `data`, `clock`, and `reset`,
- typed `.rtlif` `clock` / `reset` tokens let custom-named RTL system ports auto-wire through composition without reviving broader hidden inference,
- the current `C3` slice uses the RTL module name as the instance name,
- top ports must match the realized child interface exactly by name, width, and direction in `C1`,
- when `C1` infers ports, that inferred top interface is exactly the realized child interface by name, width, and direction,
- when `C2` / `C3` infer undeclared top inputs, only input-only same-name groups with exact width/type agreement are eligible,
- child inputs already consumed by explicit child-to-child links are not inferred back out as top inputs,
- explicit `?toplink` endpoints must match by role and exact width in `C2`, `C3`, and `C4`,
- explicit and declared connect-by-name mismatches now fail before emission and identify the conflicting endpoints and widths,
- realized child interface currently means:
  - effective system inputs from the active FSM generator contract:
    - explicit conventional `+system` currently yields `clk` / `rstn`,
    - absent `+system` currently yields implicit `clk` / `rst_n`,
    - purely combinational standalone-DT children do not acquire fake system ports just because they are instantiated in composition,
  - plus explicit user-facing child ports as exposed by the active generation pipeline for `?fsmc` and `?dtc`,
  - plus explicit ports declared in the loaded `<module>.rtlif` metadata for `?rtl`,
- explicit-link endpoint syntax is currently:
  - top-port name, for example `result_data`,
  - or child endpoint `instance.port`, for example `producer.output_data`,
- composition output is currently limited to SystemVerilog / Verilog targets.

## Goal of `R6`
Add a composition layer to the active architecture so `fsmgen` can build a top module from multiple child blocks without reviving the legacy eval/plugin model.

The first composition lane is intentionally narrow:
- preserve the current single-FSM compile path unchanged,
- add one explicit composition source path,
- keep composition typed and deterministic,
- reuse the existing child-FSM compile pipeline where possible.

## In-scope model for the first composition lane
### 1. Source kind
The active tool currently supports three top-level source families:
- FSM source: existing `?fsm:name` / `+fsm` path.
- Standalone-DT source: `?dt:name` for reusable DT-root modules.
- Composition source: one top-level `?top:name` form routed to a dedicated composition parser.

### 2. Child block kinds
The language surface for the first composition lane recognizes exactly three child block kinds:
- `?fsmc`
  - Child instance compiled from an FSM source through the active FSM pipeline.
- `?dtc`
  - Child instance compiled from a standalone-DT source through the active generation pipeline.
- `?rtl`
  - Child instance bound to an external RTL module with an explicitly declared interface.

Current shipped runtime subset:
- `?fsmc` and `?dtc` are realized in the shipped `C1`, `C2`, and `C3` slices,
- `?rtl` is now realized in the shipped single-child `C1`, explicit-link `C3`, and declared-by-name `C4` slices,
- the current explicit-link `C3` slice expects either one embedded `(?rtlif:module_name ...)` companion root or one `<module>.rtlif` sidecar metadata file per external RTL module and does not parse/regenerate SV/VHDL module internals at composition time.

### 3. Interface model
Composition will use explicit typed interface data, not implicit global hashes.

The first lane must represent:
- top ports,
- child instances,
- child port directions,
- interconnect nets,
- top-to-child bindings,
- child-to-child bindings.

### 4. Wiring model
The first lane supports:
- explicit top-port exposure,
- explicit child-port wiring,
- declared top-port connect-by-name through `=name` declarations in `?ports`,
- deterministic connect-by-name only when the names are unambiguous and declared,
- explicit failure on:
  - unknown ports,
  - duplicate drivers,
  - ambiguous connect-by-name,
  - width mismatch where no legal adaptation exists.

### 5. Output model
The first lane produces:
- one generated top module in the selected HDL target,
- generated child modules for `?fsmc` and `?dtc` children,
- references to external RTL children without attempting to regenerate their internals.

### 6. CLI behavior
`bin/fsmgen` remains the single entrypoint.

The composition path must:
- detect a `?top:name` root before the FSM-only parser runs,
- route to a composition pipeline,
- keep current single-FSM CLI behavior unchanged for existing inputs.

## Explicit non-goals for the first composition lane
The following are out of scope for the first implementation slice:
- legacy eval/plugin phases (`.plg`, `cclausearch`, `declarch`, `beginarch`, `endarch`, etc.),
- macro systems and dynamic code injection,
- implicit architecture rewriting across child boundaries,
- automatic datapath/control repartitioning at composition level,
- mixed-language top generation,
- hierarchical timing semantics beyond explicit port/net wiring,
- broad “do what I mean” auto-wiring beyond deterministic declared connect-by-name.

## Working interpretation of legacy terms
- `?fsmc`
  - Composition-layer child FSM declaration and interface exposure/wiring support.
  - It is not itself an enable-synthesis feature.
- `?rtl`
  - External RTL module binding with declared interface metadata loaded separately for composition-time validation and wiring.
- `?ports`
  - Explicit top-level interface declaration for the generated composition.
- `?toplink`
  - Explicit connectivity specification between top ports, interconnect nets, and child ports.

These names come from the historical composition flow, but the implementation must be typed and modernized rather than copied structurally from the legacy engine.

## Active architecture mapping
The first composition lane should be added above the current FSM-only parser boundary.

### Planned pipeline split
1. Source classification
   - inspect the Lispish root and choose FSM path or composition path.
2. Composition parsing
   - build a typed composition IR from `?top:*`, `?fsmc`, `?dtc`, `?rtl`, `?ports`, and `?toplink`.
3. Child realization
   - compile `?fsmc` children through the existing FSM pipeline whether the child source is embedded or loaded from an external `.fsm` file,
   - load/validate declared interfaces for `?rtl` children from embedded or sidecar `.rtlif` metadata.
4. Top planning
   - resolve ports, nets, instance wiring, and deterministic ordering.
5. Top emission
   - emit the generated top module in the selected HDL target.

### Planned typed IR concepts
The first lane should introduce typed composition objects instead of free-form hashes.
The initial parser/IR slice now covers the root/container side and also includes typed per-port/per-link objects used by the shipped `C1` planning path.

Planned typed objects:
- `CompositionSpec`
- `CompositionTop`
- `CompositionInstance`
- `CompositionPort`
- `CompositionNet`
- `CompositionLink`

Exact package names may change, but the architecture must stay typed at this boundary.

Historical note:
- [docs/COMPOSITION_LEGACY_MAPPING.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_LEGACY_MAPPING.md) captures how the obsolete `fx/bin/fsmgen` composition lane maps onto this modern scope without reviving its plugin/eval machinery.

## Acceptance matrix for the first composition lane
These are the executable scenarios that must exist before `R6` can be closed.

### C1. Single-child passthrough top
Status:
- Implemented in the current active toolchain for one child (`?fsmc`, `?dtc`, or `?rtl`) with either explicit same-name top exposure or bounded omitted/empty-`?ports` top-interface inference.

- Input:
  - one `?top:name` with one child (`?fsmc`, `?dtc`, or `?rtl`) and either explicit top-port exposure or an omitted/empty `?ports` shape.
- Must prove:
  - top generation succeeds,
  - generated child HDL is emitted through the active pipeline when the child is generated,
  - external RTL children are instantiated but not regenerated when the child is `?rtl`,
  - top ports are emitted deterministically,
  - child ports are wired exactly as declared,
  - and omitted/empty `?ports` in `C1` infers a top interface that matches the realized child interface exactly.

### C2. Two generated children with explicit child-to-child wiring
Status:
- Implemented in the current active toolchain for generated children with explicit `?toplink`, plus bounded undeclared top-input inference for child-input groups that are still top-facing.

- Input:
  - one `?top:name` with two generated children (`?fsmc` / `?dtc`) and explicit links between them.
- Must prove:
  - deterministic net creation,
  - deterministic instance ordering,
  - explicit link wiring is emitted correctly,
  - undeclared shared top inputs can be inferred when they are not already consumed by explicit child-to-child links,
  - duplicate-driver errors are rejected.

### C3. Explicit-link external RTL composition
Status:
- Implemented in the current active toolchain for explicit-link tops with at least one external `?rtl` child and any number of generated children (`?fsmc` or `?dtc`) beside those RTL children, using the shipped `.rtlif` interface metadata and the same bounded undeclared top-input inference rule as `C2`.

- Input:
  - one or more `?rtl` children with explicit `?toplink` wiring,
  - optionally mixed with one or more generated children that participate in the same explicit-link plan.
- Must prove:
  - generated child is compiled,
  - RTL children are instantiated but not regenerated,
  - interface validation catches unknown ports, unsupported `.rtlif` type names, and direction mismatches,
  - deterministic carrier nets can feed more than one external RTL child from one resolved source,
  - multiple generated children can still participate in the same explicit-link plan as long as at least one `?rtl` child is present,
  - undeclared shared top inputs can still be inferred when they are not already consumed by explicit child-to-child links,
  - typed `.rtlif` `clock` / `reset` metadata can carry custom-named RTL system ports honestly.

### C4. Connect-by-name only when unambiguous
Status:
- Implemented in the current active toolchain for top ports declared as `=name` inside `?ports`, with direction-asymmetric same-name matching across the shipped single-child (`?fsmc`, `?dtc`, or `?rtl`), multi-generated-child, multi-`?rtl`, and mixed generated-child plus external RTL lanes.
- Implemented in the current active toolchain for top ports declared as `=name` inside `?ports`, with direction-asymmetric same-name matching:
  - top outputs still require exactly one compatible child output,
  - top inputs may fan out to one or more compatible child inputs.

- Input:
  - composition relying on declared connect-by-name.
- Must prove:
  - exact declared top outputs connect automatically when one unique child output matches,
  - exact declared top inputs can fan out automatically to one or more child inputs,
  - declared `=name` may coexist with explicit child-to-child `?toplink` wiring in the same bounded top,
  - ambiguous matches are rejected,
  - undeclared/unknown names are rejected.

### C5. Width mismatch diagnostics
Status:
- Implemented in the current active toolchain for both explicit `?toplink` links and declared `=name` connect-by-name ports.

- Input:
  - composition with incompatible linked widths.
- Must prove:
  - generation fails before emission,
  - the diagnostic identifies the two endpoints and the conflicting widths.

### C6. Legacy-composition features not in scope fail explicitly
Status:
- Implemented in the current active toolchain for legacy macro/plugin children and the currently out-of-scope legacy parser shapes that were still reachable from modern `?top:name` inputs.

- Input:
  - legacy macro/plugin-oriented composition constructs outside this scope.
- Must prove:
  - the active tool fails explicitly and points to unsupported composition scope,
  - it does not silently fall back to eval/plugin behavior.

## Test plan mapping
The first executable acceptance tests should be added as focused composition tests, separate from the FSM-only regression files.

Suggested initial names:
- `t/20-composition-single-fsm-top.t`
- `t/21-composition-two-fsm-linking.t`
- `t/22-composition-fsm-plus-rtl.t`
- `t/23-composition-errors.t`

## Exit boundary for `R6`
`R6` is not done when the scope is written down.

`R6` closes only when:
- the active composition source path exists in `bin/fsmgen`,
- the typed composition IR and top emitter exist,
- the acceptance matrix above is covered by executable tests,
- user/developer documentation reflects the shipped composition behavior.
