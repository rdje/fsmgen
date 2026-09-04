# VIAL Semantic-Family Envelope And Registry

Date: 2026-09-04
Owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.3-.19.1.5`
Status: common private phase envelope, fail-closed registry, and backend adapter preflight implemented

This semantic part defines the common facts every expressive family must carry
and the registry negotiation every compiler stage must pass. The surrounding
[version-2 source and compatibility contract](source-semantic-ir-v2.md) owns
the language boundary, import rules, projections, and migration policy.

## Immutable semantic-family envelope

`FSM::Support::VIALSemanticFamilyContract` is the machine authority for the
common facts every later family must supply. An `intent_families` entry has
exactly `semantic_id`, `family_id`, `revision`, `semantic_path`, `source_span`,
and one-or-more `nodes`. Family IDs and semantic IDs are unique in their
collection. Each node is an immutable
`fsmgen.vial_semantic_family.v2` record with exactly:

```text
schema, schema_version, stage
semantic_id, family_id, revision, node_id, node_kind
scope, lifetime, order
ports, effects, failure, result
semantic_path, source_span, payload
```

`scope` names one `catalog`, `package`, `fixture`, `scenario`, or `fiber`
owner. `lifetime` gives distinct start/end seams and a `forbidden`,
`cooperative`, or `required` cancellation policy. `order` carries a domain,
phase, nonnegative rank, and disjoint before/after identity lists. Ports carry
stable identity, name, input/output/inout direction, type identity,
one/optional/many cardinality, and a JSON Boolean required flag. Effects carry
stable identity, target, and visibility. Failure and result contracts state
their typed outcome before any backend choice. `payload` is family-typed plain
JSON data: lexer/parser nodes and raw source residue are rejected.

The containing family span must enclose every node span in the same
repository-relative source. The family registry owns each payload's exact
keys and tighter limits; the common validator does not accept a family merely
because its generic envelope is well formed. The source grammar can recognize
an empty family block so semantic diagnostics own that error, but a zero-node
family never enters SemanticIR.

## Phase records and traceability

The exact per-node stage schemas are:

| Phase | Schema | Additional common facts |
| --- | --- | --- |
| semantic | `fsmgen.vial_semantic_family.v2` | unbound meaning above |
| bridge binding | `fsmgen.vial_semantic_family_binding.v2` | typed port bindings and HIAL bridge fact paths |
| execution | `fsmgen.vial_execution_family.v2` | operation IDs and complete required capabilities |
| plan | `fsmgen.vial_plan_family.v2` | sanitized execution projection |
| result | `fsmgen.vial_result_family.v2` | status, typed outputs, observed effects, diagnostic IDs |

Binding, execution, and plan records have exactly `schema`, `schema_version`,
`stage`, `semantic`, `bindings`, `operation_ids`, `required_capabilities`, and
`source_map`. Result adds exactly `status`, `outputs`, `observed_effects`, and
`diagnostic_ids`. Required ports must be bound once to known semantic ports;
each binding cites at least one HIAL bridge fact and type-relation proof, and
the source map contains exactly the binding records' ordered bridge-fact union;
plan and result preserve execution operations and sorted capabilities; every
later phase preserves the exact semantic and binding meaning. An execution may
add requirements but cannot lose a binding requirement. A passing result must
provide its required typed output and account for every result-visible effect.

Each stage embeds `fsmgen.vial_source_map.v2` with a content-derived
`source-map/<sha256>` identity, semantic identity/path, bridge fact paths,
execution paths, plan paths, result paths, and authored locations. The
validator requires the first location to be the exact node span and paths to
accumulate in phase order. Forged identity, lost span, missing phase path,
mutation of earlier meaning, unknown key, blessed value, duplicate identity,
or unbounded collection fails before a downstream object is allocated.

The common per-node ceilings are 256 ports, effects, bindings, capabilities,
diagnostics, or source locations; 256 entries in each before/after relation;
and 4,096 operations, observed effects, source paths, or payload values. A
payload is also limited to depth 64 and 262,144 canonical JSON bytes. A family
has at most 4,096 nodes and at least one. The catalog ceilings in
[the source contract's bounds](source-semantic-ir-v2.md#bounds) remain
independent and may be tighter. These are safety limits, not capacity claims.

## Selected family registry and negotiation

`FSM::Support::VIALSemanticFamilyRegistry` is the single machine authority for
family and revision identities, dependency lists, reserved target-neutral
effect vocabularies, the common bound profile, stage maturity, and backend
profile mappings. Its closed `fsmgen.vial_semantic_family_registry.v1` record
has a content-derived `vial-family-registry/<sha256>` identity and registers
revision 1 of these roadmap-selected namespaces:

```text
lifecycle_control             notification_interception
timed_interface               stimulus_orchestration
producer_observer             implementation_selection
scoped_configuration          register_intent
constrained_decision          coverage_property
bounded_fault                 result_introspection
```

Registration reserves coordination identities; it is not implementation. Each
entry points to its `.19.2-.19.13` activity, uses the common v2 bound profile,
has an explicitly empty dependency list pending cross-family selection, records
its reserved effect kinds, and reports `selection: selected`. Every functional
maturity dimension—source, semantic, binding, execution, plan, emission,
compile, runtime, result, parity, and public—is `unavailable`. The current
backend mappings are `sv_portable_verilator`,
`sv_uvm_emit.accellera_2020_3_1`, `vhdl_portable_ghdl`, and
`vhdl_osvvm_qualified`; every family maturity is unavailable independently on
all four. Later vertical owners must update this same record; they may not
maintain a shadow registry or borrow another route's maturity.

The registry also owns six exact current profile records: the v2 parser, the
empty-family v2 execution planner, and the four v1 backend routes above. A
profile lists accepted source or ExecutionIR versions plus its own supported
family revisions, capabilities, and effects. Negotiation reads only the
selected profile. Support recorded for any other profile cannot satisfy a
requirement.

`fsmgen.vial_semantic_family_negotiation.v1` contains its registry identity,
stage, selected profile, acceptance flag, and ordered `required`, `satisfied`,
`unsupported`, and structured `issues` collections. Parser and planner
negotiate before SemanticIR/HIAL work; emitter negotiates before artifact
construction; runner negotiates before lifecycle workspace or process
creation. Rejection reports the complete unsupported schema, profile, family,
revision, dependency, capability, and effect set rather than stopping at the
first missing item. It returns no partial semantic object, review graph,
artifact, workspace, or runtime result.

The existing public v1 tooling capability list and portable-backend capability
set are registry projections. Observable bytes remain unchanged, removing a
duplicate authority without exposing v2. The executable authority is
`t/1803-vial-v2-family-registry.t`.

## Common backend adapter preflight

`FSM::Support::VIALSemanticFamilyBackendAdapter` is the common adapter
authority. Its closed
`fsmgen.vial_semantic_family_backend_adapter_registry.v1` record has a
content-derived `vial-backend-adapters/<sha256>` identity. Each adapter names
the exact private emitter, target language and mechanism, accepted ExecutionIR
schema/profile, output and source-map schemas, artifact model, and independent
emission/compile/runtime/result/parity/public maturity:

| Profile | Emission | Compile/runtime/result/parity | Public |
| --- | --- | --- | --- |
| `sv_portable_verilator` | qualified | qualified | qualified |
| `sv_uvm_emit.accellera_2020_3_1` | implemented review output | unavailable | unavailable |
| `vhdl_portable_ghdl` | qualified | qualified for the bounded selected fixture | unavailable |
| `vhdl_osvvm_qualified` | qualified | qualified for the bounded fixture/provider probe | unavailable |

These are base v1 route states, not family support. The family registry's four
per-family mappings remain independently unavailable. In particular, native
UVM cannot inherit portable-SystemVerilog runtime evidence, and private VHDL
qualification cannot become public API support.

`fsmgen.vial_semantic_family_backend_preflight.v1` accepts only the exact
immutable `FSM::VIAL::ExecutionIR` class. It checks that schema, profile,
version, and the v2 family carrier agree, then negotiates the complete family,
revision, capability, and effect set for the selected adapter. All four
emitters invoke it before target rendering; the OSVVM route invokes it before
portable-VHDL delegation or provider verification. A rejection has no
operation identity, source map, artifact graph, provider access, workspace, or
process. Successful v1 output records and bytes are unchanged because the
preflight is an admission boundary, not an output field.

Target mechanisms exist only in adapter records and generated artifacts; they
do not enter SemanticIR or ExecutionIR family meaning. All current emitters
retain deterministic in-memory artifact graphs for atomic publication and
their existing source-map schemas. The executable authority is
`t/1804-vial-v2-backend-adapter-seams.t`, together with the existing per-route
emission and qualification tests.
