# Feature Backlog

This chapter is the canonical book-facing backlog for user-visible features
that are discussed elsewhere as future work, deferred, not fully shipped, or
not yet a fully frozen public contract.

When another chapter mentions a limitation of that kind, the item must also be
listed here. Local chapters may keep short contextual notes, but this chapter
is the consolidated review list.

## Language Ergonomics

### Inference-First Scalar Authoring

Status: partially shipped; broader resource kinds and arbiters remain backlog.

Goal: make scalar declarations optional across the whole language whenever a
safe type and width can be recovered from authored usage.

Current boundary: FSMGen already infers widths from explicit `+size`, scalar
type aliases, positive integer scalar symbols, slices, selectors, guards, and
other bounded evidence. It does not yet promise "never declare scalar types
unless you want to" across every source position.

### Dynamic Divisor Safety Proofs

Status: partially shipped.

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

### Broader Generated-Child Top Instantiation

Status: partially shipped; generalized surfaces remain backlog.

Goal: instantiate generated child FSM/DT artifacts from higher-level ISF or
composition flows without manual wiring gaps.

Current boundary: generated-child parameterization exists for bounded
composition paths, and ISF spawned-child fixtures now emit a generated
`<actor>_top.fsm` that wires the scheduled parent, scheduled children,
start/done handoffs, named-drive handoffs, and per-instance spawn parameter
overrides through the existing composition pipeline. Broader generated-child
top surfaces beyond the covered ISF spawn pattern remain backlog.

### Spawn Parameter Binding

Status: partially shipped; broader parameter/value surfaces remain backlog.

Goal: bind parameters through spawned child instances in ISF-generated
multi-file scheduled designs.

Current boundary: spawn emits child files, a parent scheduled `.fsm`, and a
generated composition top for covered spawned-child fixtures. The ISF lowerer
now accepts one optional nested `(params (NAME value) ...)` block on
`(spawn child as instance ...)`, accepts spawned child transaction parameters
from a transaction-local `params` clause, emits child defaults as scheduled
child `+params`, validates duplicates/unknown overrides/value shapes, rejects
parameter declarations on non-spawned transactions, preserves per-instance
override lists in the parent lowerer IR, and applies those overrides through
the generated top. The first value domain is scalar/exact-width literals plus
compatible aggregate/list literals; symbolic constants wait for an explicit
ISF symbol surface.

### Spawn Inside Repeat Bodies

Status: backlog.

Goal: allow `(spawn child as name)` inside `(repeat count body...)` without
implying dynamic hardware creation.

Required contract: the lexical spawn name denotes one static child instance in
the generated top. The repeat loop may activate that instance multiple times,
but it must not elaborate one instance per iteration. The scheduler needs a
busy/re-entry rule before this can ship: either prove or insert sequencing so
each later iteration observes the child's fresh done pulse before starting it
again, or reject the loop with a targeted diagnostic.

Dynamic repeat counts are compatible with this model because `count` is a
runtime counter load value, not an elaboration count. They do make loop latency
data-dependent, and the repeat contract still needs an explicit zero-count
policy for the fully general case.

## Intent Scheduling Format

### IAL2 Protocol And Platform Intent Exploration

Status: backlog.

Goal: decide whether an intent layer above current ISF has enough independent
semantic value to exist.

Current boundary: FSMGen names `.fsm` as Intent Abstraction Layer 0 (`IAL0`)
and current `.isf` as Intent Abstraction Layer 1 (`IAL1`). A future `IAL2`
would need to justify itself with semantics above individual transactions, not
only syntax convenience. The first worthwhile areas to investigate are
reusable protocol-level intent objects, such as APB/AXI transaction templates,
and platform/resource mapping decisions that choose among legal ISF schedules
or resource allocations. Aliases, macros, wrappers, and sugar without a
distinct runtime model should stay inside IAL1 or remain out of the language.

### Enforced Resource Arbitration

Status: backlog.

Goal: lower `(resources ...)` metadata into scheduler-enforced mutual
exclusion and arbiter behavior.

Current boundary: resource metadata is structurally validated, including
supported arbiter names, resource kinds, duplicate resource rejection, and
resource-user validation for `rule_slot`. The scheduler now enforces the first
resource kind: `rule_slot`, a one-cycle mutual-exclusion slot where each bound
rule requests when its guard is true, the priority graph chooses a unique
active winner, and the generated grant gates the whole rule DT DTE without
adding a cycle.
The resource-kind catalog is owned in code by
`FSM::Support::ISFResourceCatalog` and exposed through the machine-readable
ISF public contract, so downstream consumers can distinguish shipped resource
behavior from parser-recognized backlog names without scraping prose.

Current shareable resource registry:

| Kind | Status | Meaning |
| --- | --- | --- |
| `rule_slot` | shipped for `priority` arbitration | One-cycle mutual exclusion for rule users under the `priority` arbiter. |
| `output_bundle` | backlog | One-cycle ownership of a group of actor outputs or LHS targets. |
| `interface_bundle` | backlog | Ownership of a protocol-facing interface or bus bundle. |
| `named_drive` | backlog | Ownership of a reusable actor `(drive ...)` body or drive-call path. |
| `transaction_start` | backlog | Arbitration for start/request fan-in into one transaction. |
| `child_instance` | backlog | Re-entry control for a spawned child instance. |
| `storage_port` | backlog | Arbitration for shared state, register, memory, or storage-port access. |

Remaining backlog: non-`rule_slot` resource kinds, `round_robin`, transaction
lifetime ownership, named-drive users, output-target users, multi-capacity
resources, and dynamic resource names remain backlog until their reset,
hold/release, fairness, and diagnostic contracts are explicit.

### Priority Resolution

Status: partially shipped; broader cases remain backlog.

Goal: enforce actor-level and rule-local priorities when multiple rules or
transactions conflict.

Current boundary: priority declarations are structurally validated and targets
must resolve to declared rules or transactions. Same-target rule/rule data
conflicts can now be resolved by rule-local or actor-level rule priority, with
the lower-priority assignment guarded off by the higher-priority rule
condition. Actor-level rule-over-transaction priority can now resolve the
covered same-target data case by guarding the transaction-state assignment
with the inverse active rule condition. Priority cycles, incomparable rule
conflicts, unordered rule/transaction conflicts, and mixed timing conflicts
fail closed.
Rule/drive overlap is still tracked because compile-time proof is not doable.
Generated SystemVerilog now includes verification-only selector assertions
derived from backend assignment analysis: same-value source selectors and
whole-mux value selectors are checked with `$onehot0` under
`` `ifndef SYNTHESIS``. Transaction-over-rule priority, drive/rule arbitration
policy, and broader resource arbitration remain backlog items.

### Expression-Valued Rule Assignments

Status: shipped for ordinary flopped rule assignments.

Goal: allow rule actions to assign expression values, not only scalar
`(port value)` pairs.

Current boundary: rule actions accept `(port expr)`, `(trigger transaction)`,
and `(priority over other_rule)`. Rule guards, trigger targets, and priority
targets remain scalar-only today. `(port expr)` lowers as a flopped `<-` rule
assignment under the rule DT DTE, where `expr` may be a scalar token or one
list expression from the transaction `update`/`.fsm` RHS expression domain.
`(trigger transaction)` lowers through a generated one-cycle source and
transaction start fan-in. `(priority over other_rule)` feeds the covered
priority/resource arbitration paths. Same-expression rule writes report as
compatible fan-in, incompatible expressions fail closed through the same
rule-write conflict diagnostic, and priority-resolved expression conflicts
project through `priority_resolutions`. Expression guards and alternate rule
assignment operators are separate future features.

### Transaction Stage Lowering

Status: partially shipped.

Goal: lower transaction `(stage ...)` clauses into valid/ready pipeline-stage
logic.

Shipped subset: a top-level transaction stage of the form
`(stage name (input ready_signal) (output valid_signal))`. It lowers to one
state that drives `valid_signal = 1` while active and advances only when
`ready_signal` is true. Actor-level stage metadata remains parser-carried only;
it does not reach `LoweringIR`, schedule JSON, scheduled `.fsm`, generated
composition tops, or HDL.

Remaining backlog: nested stages, stage-local latency, compute/action bodies,
multiple ready/valid endpoints, registered-valid variants, skid-buffer
behavior, and richer stage report families for future stage kinds.

### Temporal Contract Lowering

Status: backlog.

Goal: lower transaction `(contract ...)` temporal assertions into generated
checks or equivalent scheduled artifacts.

Shipped subset: a top-level transaction contract of the form
`(contract name (eventually signal (within cycles)))`. Reaching the clause
emits one arm state; the generated scheduled `.fsm` monitor tracks
pending/age/fail storage, clears on actor reset, and sets a sticky fail bit if
the signal is not seen within the window or if the same contract is armed
again while pending.

Remaining backlog: optional verification-only SystemVerilog assertion text
from the sticky fail bit, global `always` implication forms, min/max windows,
dynamic bounds, same-cycle checks, nested contracts, expression operands, and
multiple outstanding obligations.

### Legacy Handshake Semantics

Status: deprecated compatibility input with tightened validation.

Goal: keep old `(handshake ...)` source intentional without giving it new
runtime semantics.

Current boundary: deprecated handshake metadata is structurally validated and
ignored. The parser accepts a scalar handshake name plus scalar `valid`/`ready`
property entries and leaves the actor-shell handshake placeholder empty. Direct
`(on port ...)` activation plus generated `can_accept` is the current model.
Policy: keep well-formed legacy handshakes accepted and ignored for
compatibility, and do not lower them into scheduled `.fsm`, schedule JSON, or
HDL. Accepted legacy forms now require one `valid` and one `ready` property
with no duplicate handshake names. Use `(on ...)` for activation and
transaction `(stage name (input ready_signal) (output valid_signal))` for
ready/valid barriers.

### Removed Assign Keyword

Status: removed compatibility item; targeted diagnostic pending.

Goal: keep the removed `(assign ...)` transaction keyword out of the language
and guide authors to explicit timing constructs.

Current boundary: authored uses fail closed as unsupported transaction clauses.
The parser may carry the raw clause as private scheduler input, but the
scheduler rejects it in top-level transaction bodies and nested contexts such
as `when`, `switch`, or `repeat` bodies. The diagnostic is migration-specific:
do not auto-map the old keyword. Use `(update var expr)` for transaction-local
flopped updates, `(drive ...)` for protocol/output drives, rule `(port expr)`
actions for rule-driven assignments, and `(complete port)` for transaction
completion. A future transaction-local combinational assignment feature would
need a new explicit construct with its own timing semantics.

### Full Width Inference For Data Operations

Status: backlog.

Goal: infer widths for data operations in more cases without requiring
explicit width options, and keep accepted lowering free of width placeholders.

Current boundary: `shift_right` accepts `(width N)` and `extract` accepts
`(widths N...)` as explicit assertions. `extract` now fails closed instead of
emitting placeholder slice bounds when field positions cannot be proven or
field totals conflict with known source width. `shift_right` now fails closed
when width evidence is missing or conflicts with an explicit option.
`assemble` now rejects known target-width mismatches, while unknown part
widths remain accepted only as non-evidence concat operands.
Schedule reports now expose positive integer `width` metadata for inferred
scheduler counters and register storage with known ISF width evidence.

### Richer Schedule-Report Storage Classes

Status: partially shipped; additional classes remain backlog.

Goal: classify inferred storage more precisely in schedule reports.

Current boundary: schedule reports expose bounded storage metadata with
optional positive integer widths when width evidence is known.
`inferred_storage[].kind` remains the coarse storage category (`counter` or
`register`). The first optional `inferred_storage[].role` slice is shipped for
storage families with stable lowering evidence: `watchdog_counter`,
`latency_counter`, `repeat_counter`, `drive_request`, `drive_payload`,
`sample_alias`, `extract_field`, `data_register`, and `completion_pulse`.

Remaining direction: keep `role` additive and omit it when evidence is
ambiguous. Additional roles, including temporal-contract monitor storage,
child `do`/`spawn` handoff storage, rule-trigger source storage, and
resource-grant/debug storage, remain backlog until each family has its own
compatibility rules, public contract metadata, and regression coverage.

### Fully Frozen Schedule JSON Schema

Status: backlog.

Goal: freeze the whole schedule JSON schema as a public contract.

Current boundary: schedule JSON is public only through bounded key families
advertised by `embedding.isf_public_interface`. The whole JSON tree is not yet
promised as permanently frozen. The conflict/fan-in projection boundary is now
defined. Nonfatal conflict issues project into `compile_issues`, and accepted
fan-in groups project into `compatible_fanin_groups`, both with bounded
summary shapes. Successful priority/resource decisions project into
`priority_resolutions` and `resource_arbitration` as bounded static lowering
summaries. Shipped transaction stages and bounded eventual contracts project
into `transaction_stages` and `temporal_contracts` with bounded public
summary shapes.

Freeze-readiness plan: the current contractual surface is the metadata
advertised by `embedding.isf_public_interface`, including top-level keys,
nested key/value families, scalar policies, ordering policies, nullability
rules, storage kind/role/width metadata, and CLI/in-process report parity.
New optional keys or value-family members may be added only when the same slice
updates contract metadata, focused tests, and user-facing docs.

Blockers before flipping `schedule_report_full_schema_stable` are: decide
whether the report needs its own schema/version field, close or explicitly
defer remaining storage-role families, define generated-name stability policy,
decide whether assignment provenance and multi-file child summaries stay
private or gain bounded public summaries, document additive/deprecation rules,
and keep a golden fixture matrix for every advertised branch.

### ISF Realistic Fixture Matrix

Status: current coverage boundary with future promotion candidates.

Goal: keep realistic protocol fixtures aligned with shipped ISF behavior,
strict-mode expectations, schedule JSON assertions, scheduled `.fsm` review
artifacts, and generated HDL reachability.

Current boundary: APB remains the quick/smoke ISF baseline for parse, scheduled
`.fsm` header, and public-contract checks. Broader realistic fixture coverage
belongs in the `isf` regression tier. The active matrix in
[ISF-FIXTURE-COVERAGE](../../tasks/ISF-FIXTURE-COVERAGE.md) now covers
`isf/spi_master.isf` as a bounded SPI-like mode-0 serial-transfer fixture
through file-backed schedule JSON, scheduled `.fsm`, plain HDL, and strict HDL
checks. It is not a complete SPI protocol compliance suite. Future fixture
promotions should add stable structural assertions rather than full HDL or full
schedule JSON snapshots. The SPI-like fixture intentionally stays out of the
quick/smoke tier for now; `quick` remains APB-centered for fast turnaround.

Fixture authoring policy: realistic fixtures should use documented ISF
constructs. If a fixture needs an awkward workaround to express a normal
hardware intent, treat that as an ISF expressiveness gap and track the missing
construct instead of hiding the workaround inside the test.

ISF expressiveness policy: Lisp-like syntax makes argument-level composition
and variadic constructs natural, but arity is part of the public contract.
Constructs with fixed hardware roles should keep exact arity. Constructs whose
meaning is naturally list-like or associative may accept an arbitrary number of
arguments when that keeps the source clear and the lowering remains
deterministic. Each new variadic surface needs targeted malformed-arity
diagnostics, focused or fixture coverage, and book/spec updates in the same
slice.

### ISF Reusable Libraries

Status: active feature tree under
[ISF-LIBRARIES](../../tasks/ISF-LIBRARIES.md).

Goal: let users import tested reusable ISF descriptions instead of rewriting
common actors and transaction patterns in every design. The user-facing term is
**library**. The implementation may reuse package/import infrastructure, but
ISF libraries are broader than scalar constants or type packages: they should
be able to contain reusable ISF actors, transactions, drives, and associated
constraints when those surfaces are specified.

Current boundary: the first reusable ISF library import, same-name
generated-top, actor-owned fixed-storage, expression-valued rule-guard, and
disjoint-rule write slices have shipped. Actor roots may
import library roots, use an exported actor, validate use-site parameters and
explicit bindings, emit a specialized child scheduled `.fsm` artifact, wire
the library actor through a generated top, reach SystemVerilog generation for
the covered generated-top path, project bounded `library_uses`
schedule-report metadata, declare fixed actor-owned registers/banks, author
rule fire predicates as expressions, accept same-target rule writes when
direct contradictory guard literals prove disjointness, and record real FIFO
requirements. No FIFO fixture is shipped yet. Clock/reset name remapping
remains fail-closed.

Shipped source model for actor exports:

```lisp
(library fifo_lib
  (exports
    (actor fifo))

  (actor fifo
    ... reusable actor body ...))
```

Shipped use model for actor exports:

```lisp
(actor top
  (imports
    (library common.fifo as fifo_lib))

  (use fifo_lib.fifo as rx_fifo
    (params (WIDTH 32) (DEPTH 4))
    (bind
      (clock clk)
      (reset rst)
      (input push push_i)
      (input pop pop_i)
      (input data_in data_i)
      (output data_out data_o)
      (output full full_o)
      (output empty empty_o))))
```

Imports are actor-scoped in the first shipped model. Imported definitions stay
namespaced by default; `as alias` creates a local namespace alias, not
unqualified symbol pollution. The first shipped export target should be
reusable actors. Standalone transaction templates and standalone drive helpers
need their own binding rules before they become public library exports.

Shipped specialization and binding model:

```lisp
(actor fifo
  (params
    (WIDTH 8)
    (DEPTH 4))
  ...)

(actor top
  (imports
    (library common.fifo as fifo_lib))

  (use fifo_lib.fifo as rx_fifo
    (params
      (WIDTH 32)
      (DEPTH 4))
    (bind
      (clock clk)
      (reset rst)
      (input push push_i)
      (input pop pop_i)
      (input data_in data_i)
      (output data_out data_o)
      (output full full_o)
      (output empty empty_o))))
```

Actor-library parameters use unique HDL-identifier-compatible names and a
default value. Use-site overrides are instance-local and should reuse the
spawn-parameter value boundary first: scalar decimal literals, exact-width
numeric literals, and compatible aggregate/list literals. Missing overrides use
defaults; duplicate parameters, unknown overrides, unsupported symbolic values,
and unsupported non-static parameter use fail closed.

Binding is explicit. A reusable actor with a clock or reset must bind it at the
use site. Reset kind and polarity belong to the reusable actor for the first
ship; the use site should not silently change sync/async or active-high/low
semantics. Every exported actor interface port must be bound exactly once with
matching direction and matching specialized width. No implicit truncation,
extension, or slicing is performed by the binder.

Generated names are deterministic in the shipped resolver: the authored
instance name remains
the stable diagnostic/report identity, while the first specialized child module
and scheduled `.fsm` basename use `<importing_actor>__<instance>` and
`<importing_actor>__<instance>.fsm`. Successful reports expose a bounded
`library_uses` array with library/export/instance identity, parameter
source/value summaries, binding summaries, and generated artifact names without
exposing raw resolver or lowerer internals.

Resolver scope: `parse_file(...)` checks same-source library roots, then
external library files under the importing source directory, `FSMLIB` entries,
and the current directory. For a dotted namespace such as `common.fifo`, both
`common.fifo.isf` and `common/fifo.isf` are candidate file names. `parse_source`
can use same-source library roots but cannot resolve external files without a
real source path. Standalone transaction/drive exports, symbolic parameter
values, derived parameter expressions, and clock/reset name remapping are
still deferred.

FIFO modeling rule: a FIFO should be modeled primarily as an actor because it
owns persistent storage, pointers, occupancy, full/empty flags, reset behavior,
and interface timing across cycles. Enqueue, dequeue, flush, or status-probe
behaviors can be transactions or callable operations inside or against that
actor, but a transaction alone should not own the FIFO's persistent state.
Hardware components in ISF are persistent regions, not software processes that
die when their immediate work is done. Actors, transactions, DTs, and rules
may be inactive, but while the design is powered, clocked, and released from
reset, their logic remains present.

Shipped actor-owned storage model:

```lisp
(actor fifo
  (storage
    (register rd_ptr (width 2))
    (register wr_ptr (width 2))
    (register occupancy (width 3))
    (bank data (width 8) (depth 4)))
  ...)
```

`(register name (width N))` declares one fixed-width internal actor register.
`(bank name (width N) (depth N))` declares fixed-depth actor-owned storage and
currently scalarizes to `<name>_0` through `<name>_<depth-1>` in scheduled
`.fsm`. This is the first `DEPTH=4` FIFO storage path; parameter-derived
dimensions, indexed source access, generalized arbitrary-depth elaboration,
and memory-array backend emission remain future work.

The first FIFO fixture must be a real FIFO actor, not a depth-1 placeholder.
A depth-1 element may be useful as a register slice or holding element, but it
does not exercise FIFO depth, pointers, or occupancy semantics. The first
fixture uses `DEPTH=4`. It must explicitly model the four request cases: no
request, push without pop, pop without push, and push with pop. Push-only
updates storage and occupancy when not full; pop-only updates read state and
occupancy when not empty; simultaneous push+pop derives write-fire and
read-fire from the same pre-cycle state and updates both sides atomically;
idle preserves state. Depth 4 gives the initial implementation concrete
storage indices, 2-bit pointer wrap, occupancy values 0 through 4, and
full/empty flag checks before arbitrary-depth elaboration is generalized.
`wr_ptr` names the next entry written by an accepted push; `rd_ptr` names the
next entry read by an accepted pop. For the depth-4 fixture both pointers wrap
from entry 3 back to entry 0.
Transaction `(when condition body...)` is ordered control flow, so using a
chain of `when` branches to model FIFO ports would be misleading. Disjoint-rule
proof for same-target FIFO-style rule writes is shipped for direct
contradictory guard literals. The next FIFO slice must prove same-cycle
two-port update semantics on top of the declared storage primitives, then
author and prove the reusable FIFO library.

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
