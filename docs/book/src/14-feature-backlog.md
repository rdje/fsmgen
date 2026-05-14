# Feature Backlog

This chapter is the canonical book-facing backlog for user-visible features
that are discussed elsewhere as future work, deferred, not fully shipped, or
not yet a fully frozen public contract.

When another chapter mentions a limitation of that kind, the item must also be
listed here. Local chapters may keep short contextual notes, but this chapter
is the consolidated review list.

## Language Ergonomics

### Inference-First Scalar Authoring

Status: backlog.

Goal: make scalar declarations optional across the whole language whenever a
safe type and width can be recovered from authored usage.

Current boundary: FSMGen already infers widths from explicit `+size`, scalar
type aliases, positive integer scalar symbols, slices, selectors, guards, and
other bounded evidence. It does not yet promise "never declare scalar types
unless you want to" across every source position.

### Dynamic Divisor Safety Proofs

Status: backlog.

Goal: reject or prove safe runtime division/modulo expressions whose divisors
could be zero.

Current boundary: constant-expression domains reject divide/modulo-by-zero
before HDL emission. Runtime RHS expressions with dynamic divisors are emitted
as expressions; FSMGen does not yet prove every dynamic divisor nonzero.

## Aggregate Types And Data

### Automatic Aggregate Growth From Usage

Status: backlog.

Goal: infer aggregate record/list shapes from member/index usage when no
explicit aggregate type anchor is present.

Current boundary: aggregate aliases, aggregate constants, declared aggregate
types, direct-root aggregate member/list expressions, and partial aggregate
LHS writes are supported on the current SystemVerilog path. Broad automatic
aggregate type growth from arbitrary usage is not fully shipped.

### Backend-Owned Struct/Record Default Lowering

Status: backlog.

Goal: make backend-owned structured `struct`/record emission the default
lowering where it is portable and synthesizable.

Current boundary: generated-module and composition-top packed typedef emission
exists for aggregate aliases on the current SystemVerilog path. Structured
record lowering is not the default for all aggregate data.

### Richer Aggregate Operators

Status: backlog.

Goal: widen aggregate operators beyond the shipped matching-shape leafwise
numeric and bitwise families.

Current boundary: matching list/record aggregate shapes support leafwise
`+`, `-`, `*`, `/`, `%`, `&`, `|`, `^` plus word aliases before HDL lowering.
Additional aggregate operators remain deferred until each operator has a
defined type/shape/result contract and validation path.

### VHDL Aggregate Lowering

Status: backlog, behind active VHDL backend work.

Goal: lower aggregate types and values into portable VHDL record/array forms
for the subset that can be validated as synthesizable.

Current boundary: VHDL is recognized as a target family, but the full backend
is not implemented. Aggregate lowering beyond scalar/width-safe surfaces is
therefore not shipped.

### Public Type And Export Surfaces

Status: backlog.

Goal: expose richer type/export information to embedders without leaking
unstable internal objects.

Current boundary: bounded semantic and manifest surfaces exist, but richer
public type/export APIs remain under the broader public embedding/API lane.

## Composition

### VHDL Generic-Map Lowering

Status: backlog, behind active VHDL backend work.

Goal: lower validated composition parameter/generic overrides into VHDL
generic maps.

Current boundary: the Verilog-family backend lowers validated parameters and
aggregate overrides to SystemVerilog `#(...)` instance parameters. VHDL
generic-map lowering is not shipped.

### Full Generated-Child Top Instantiation

Status: backlog.

Goal: instantiate generated child FSM/DT artifacts from higher-level ISF or
composition flows without manual wiring gaps.

Current boundary: generated-child parameterization exists for bounded
composition paths. ISF child/spawn lowering writes scheduled child `.fsm`
artifacts and start/done handoff signals, but full composition-top
instantiation from ISF remains deferred.

### Spawn Parameter Binding

Status: backlog.

Goal: bind parameters through spawned child instances in ISF-generated
multi-file scheduled designs.

Current boundary: spawn emits child files and parent start/done wiring; spawn
parameter binding is deferred.

## Intent Scheduling Format

### Enforced Resource Arbitration

Status: backlog.

Goal: lower `(resources ...)` metadata into scheduler-enforced mutual
exclusion and arbiter behavior.

Current boundary: resource metadata is structurally validated, including
supported arbiter names and duplicate resource rejection. The scheduler does
not yet enforce resources.

### Priority Resolution

Status: partially shipped; broader cases remain backlog.

Goal: enforce actor-level and rule-local priorities when multiple rules or
transactions conflict.

Current boundary: priority declarations are structurally validated and targets
must resolve to declared rules or transactions. Same-target rule/rule data
conflicts can now be resolved by rule-local or actor-level rule priority, with
the lower-priority assignment guarded off by the higher-priority rule
condition. Priority cycles and incomparable rule conflicts fail closed.
Rule/drive overlap is still tracked because compile-time proof is not doable
Generated SystemVerilog now includes verification-only selector assertions
derived from backend assignment analysis: same-value source selectors and
whole-mux value selectors are checked with `$onehot0` under
`` `ifndef SYNTHESIS``. Transaction priority, drive/rule arbitration policy,
and broader resource arbitration remain backlog items.

### Expression-Valued Rule Assignments

Status: backlog.

Goal: allow rule actions to assign expression values, not only scalar
`(port value)` pairs.

Current boundary: rule actions accept `(port value)`, `(trigger transaction)`,
and `(priority over other_rule)`. Expression-valued rule assignments are
deferred.

### Transaction Stage Lowering

Status: backlog.

Goal: lower transaction `(stage ...)` clauses into valid/ready pipeline-stage
logic.

Current boundary: transaction stage clauses are parsed and fail closed during
lowering with a targeted diagnostic.

### Temporal Contract Lowering

Status: backlog.

Goal: lower transaction `(contract ...)` temporal assertions into generated
checks or equivalent scheduled artifacts.

Current boundary: authored transaction contract clauses fail closed during
lowering instead of being silently dropped.

### Legacy Handshake Semantics

Status: backlog or removal candidate.

Goal: decide whether old `(handshake ...)` metadata should gain real lowering
semantics or remain validated ignored compatibility input only.

Current boundary: deprecated handshake metadata is structurally validated and
ignored. Direct `(on port ...)` activation plus generated `can_accept` is the
current model.

### Removed Assign Keyword

Status: removal/deferred compatibility item.

Goal: decide whether the removed `(assign ...)` transaction keyword should
stay unsupported or be replaced by a different explicit construct.

Current boundary: authored uses fail closed as unsupported transaction clauses.

### Full Width Inference For Data Operations

Status: backlog.

Goal: infer widths for `extract` and `shift_right` in more cases without
requiring explicit width options.

Current boundary: `shift_right` accepts `(width N)` and `extract` accepts
`(widths N...)` as explicit anchors. Unknown-width cases still use placeholder
width/slice expressions.

### Richer Schedule-Report Storage Classes

Status: backlog.

Goal: classify inferred storage more precisely in schedule reports.

Current boundary: schedule reports expose bounded storage metadata, but rich
storage-class optimization is not shipped.

### Fully Frozen Schedule JSON Schema

Status: backlog.

Goal: freeze the whole schedule JSON schema as a public contract.

Current boundary: schedule JSON is public only through bounded key families
advertised by `embedding.isf_public_interface`. The whole JSON tree is not yet
promised as permanently frozen.

## Backends And Validation

### Full VHDL Backend

Status: backlog.

Goal: implement VHDL as a full HDL backend.

Current boundary: the CLI recognizes VHDL target spelling, but explicit VHDL
generation is not implemented.

### GHDL Validation

Status: backlog, behind active VHDL backend work.

Goal: add GHDL validation once there is an active VHDL backend.

Current boundary: validation focuses on SystemVerilog using Verilator and
Yosys.

### Warning-Clean External Validation For Every Historical Sample

Status: backlog.

Goal: make every intended sample under `fsm/` externally warning-clean under
the supported Verilog-family validation tools.

Current boundary: the regression gate uses a focused SystemVerilog smoke set.
It does not claim every historical sample in `fsm/` is externally
warning-clean.

### ABC Mapping Hardening

Status: backlog.

Goal: decide whether and how to add ABC-backed Yosys optimization/mapping
validation without timeout-sensitive noise.

Current boundary: the Yosys lane intentionally uses `synth -noabc`.

### Structured Non-Flattened Generation

Status: backlog.

Goal: support a structured/non-flattened generation path where useful without
weakening the debug-first flattened contract.

Current boundary: flattened decision-tree generation is the shipped default
path.

## Embedding And Public APIs

### Fully Frozen Programmatic Embedding API

Status: backlog under `R13`.

Goal: graduate useful in-process seams into a fully frozen public embedding
API.

Current boundary: programmatic embedding exists and many bounded contracts are
advertised, but the whole API is not promised as permanently stable.

### Full Normalized Semantic Export

Status: backlog under `R13`.

Goal: provide a full normalized semantic export format for downstream tools.

Current boundary: the capability manifest and normalized semantic JSON expose
bounded, audited public surfaces. The manifest is not yet a full normalized
semantic export.
