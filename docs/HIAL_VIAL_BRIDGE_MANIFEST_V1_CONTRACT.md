# HIALVIALBridgeManifest Version-1 Contract

Date: 2026-07-31
Owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.4`
Status: implemented privately in-process by completed `.5`; decision `0060` selects a later qualification-only direct-IAL1 scale profile without changing the AHB carrier contract

## Outcome

`HIALVIALBridgeManifest` version 1 is the bounded, versioned, JSON-safe handoff
from canonical HIAL review routes to later VIAL binding. It publishes only
sanitized HIAL facts: source/review identity, units, configuration, logical
types, public endpoints, time domains, transactions/events, protocol facts,
IAL1 observations, declared verification probes, target-name bindings,
capabilities, retained residue, and field-level provenance.

The bridge is not raw IAL0/IAL1/IAL2 AST, SourceHIR, IntentHIR, scheduled IR,
lowered RTL IR, generated HDL, or `VIALExecutionIR`. It does not bind the
shipped VIAL source, schedule a scenario, emit a testbench, compile or simulate
a target, or make parity, UVM, VHDL-methodology, mixed-language, or scale
claims.

The first implementation profile is `core_single_unit_v1`. It covers one
direct IAL0 source, one direct single-clock IAL1 source, and the checked AHB
subordinate IAL2 source through generated IAL1 and IAL0 review artifacts. The
schema is multi-record and composition-ready, but `.5` rejects multiple units,
multiple domains, aggregate types, native hierarchy, and unselected protocol
profiles until later owners qualify them.

### Selected scale-profile boundary

Decision `0060` records that the fixed AHB annotation cannot honestly exercise
the manifest's broader transaction/event/probe/residue safety caps. It selects
one closed `qualification_only` direct-IAL1 annotation profile for later
`.17.2.3.2` implementation. That profile must traverse ordinary `.isf` parse,
scheduler-report, `.fsm` lowering, and bridge-builder authorities; it cannot
accept caller-created actors, reports, or manifests. It advertises only
`hial_vial.bridge_qualification.architecture_scale_v1` and cannot become an
accepted protocol, backend/runtime path, support classification, performance
budget, or capacity claim. The exact AHB route and IAL2 review constraint are
unchanged.

## Canonical Review Routes

The producer accepts exactly one already validated HIAL route:

| Authored layer | Required review chain | Version-1 first fixture |
| --- | --- | --- |
| IAL0 | authored `.fsm` | `fsm/ahb_lite_subordinate.fsm` |
| IAL1 | authored `.isf` -> generated `.fsm` | `isf/verification_observation_metadata.isf` |
| IAL2 | authored `.ppif` -> generated `.isf` plus its parsed schedule report -> generated `.fsm` | `ppif/ahb_lite_subordinate.ppif` |

Every route records every source and generated review artifact by content
identity. A generated artifact that has not been materialized has
`repository_path: null` and a non-empty `artifact_name`; a path is never
invented. Any materialized path is repository-relative. Absolute paths,
current-directory inference, home-relative paths, temporary paths, and network
identity are forbidden in the manifest.

IAL2 protocol facts may reach the bridge only after the IAL2 generator writes
them into the generated IAL1 source as the selected
`(verification-bridge ...)` annotation and the IAL1 parser validates and
reports that annotation. The bridge builder consumes the parsed IAL1 actor and
schedule-report projection. It never consumes a PPIF AST or PPIF report as a
shortcut. Original IAL2 provenance remains attached through the annotation's
source identity. This preserves:

```text
authored IAL2
  -> generated, reviewable IAL1 + verification-bridge annotation
  -> parsed/validated IAL1 schedule report
  -> generated IAL0 review artifact
  -> HIALVIALBridgeManifest
```

Direct IAL0 produces structural unit/endpoint/domain/configuration/type facts
only. Direct IAL1 additionally produces declared transactions and
`(observe ...)` records. Protocol roles, protocol events, probes, and protocol
residue exist only when validated IAL1 source carries an explicit
`verification-bridge` annotation. Absence is represented by empty arrays, not
inference from signal spelling.

## Generated IAL1 Verification-Bridge Annotation

IAL1 gains one actor-level metadata form. It is report/bridge intent and does
not create scheduled states, `.fsm` behavior, or HDL by itself:

```lisp
(verification-bridge
  (domain ahb_bus)
  (protocol ahb_lite_subordinate
    (profile ahb)
    (revision ARM-AMBA-AHB-IHI0033-C-2021-09)
    (role subordinate)
    (facts
      (fact supported_transfer 2'b10)
      (fact okay_response 1'b0)
      (fact error_response 1'b1)
      (fact error_completion two-cycle)))
  (transaction ahb_write
    (fields
      (field address HADDR drive address_phase)
      (field transfer HTRANS drive address_phase)
      (field write HWRITE drive address_phase)
      (field size HSIZE drive address_phase)
      (field data HWDATA drive data_phase)
      (field wait_cycles wait_cycles drive configuration))
    (events
      (event requested scenario_start drive)
      (event accepted predicate sample
        (& HSEL HREADY (== HTRANS 2'b10)))
      (event captured rising sample ahb_phase_pending_q)
      (event held predicate sample (== HREADYOUT 0))
      (event completed predicate sample HREADYOUT)
      (event error predicate sample (== HRESP 1'b1))))
  (probe reg_data_q read_only)
  (residue ahb_subordinate_profile_alias_deferred)
  (residue ahb_interconnect_generation_deferred)
  (residue ahb_subordinate_optional_signal_residue)
  (residue ahb_burst_seq_support_deferred)
  (residue ahb_verification_output_deferred))
```

Version 1 permits zero or one annotation per actor and exactly one `domain`.
Names are scalar identifiers. Protocol facts are unique scalar-key/scalar-
value pairs. Transaction fields must reference actor interface or
configuration inputs and have unique names. Event names and residue IDs are
unique. Event expressions use the already parsed, typed IAL1 expression
language and may reference only the transaction's endpoints, the declared
probe, clock/reset, and actor storage needed by the event. `scenario_start`
has no expression; `predicate` has exactly one Boolean expression; `rising`
has exactly one one-bit signal. Phase is one of `drive`, `sample`, `react`, or
`check`.

A probe must reference actor storage, declare `read_only`, and never become a
public DUT port merely because it is exported to verification. The bridge
records it as `verification_probe` plus an adapter-required capability. No raw
target hierarchy is stored. Direct authored IAL1 may use this form, but the
first `.5` protocol annotation is generated only for the checked AHB IAL2
fixture.

The generated AHB annotation is itself the reviewable protocol authority. The
PPIF generator must render it deterministically from the same normalized AHB
contract that renders the rest of the generated IAL1, then reparse it through
the ordinary IAL1 parser. The PPIF and generated IAL0 outputs otherwise remain
byte-for-byte unchanged except for the additive metadata block in generated
IAL1 and its additive schedule-report projection.

## Required Manifest Shape

Every successful manifest has exactly these top-level keys:

```json
{
  "schema": "fsmgen.hial_vial_bridge_manifest.v1",
  "schema_version": 1,
  "profile": "core_single_unit_v1",
  "manifest_id": "bridge/<64 lowercase hex digits>",
  "producer": {},
  "entry_source_id": "source/authored",
  "sources": [],
  "review_route": {},
  "review_artifacts": [],
  "units": [],
  "configurations": [],
  "types": [],
  "endpoints": [],
  "domains": [],
  "transactions": [],
  "events": [],
  "protocols": [],
  "observations": [],
  "probes": [],
  "backend_bindings": [],
  "required_capabilities": [],
  "unsupported_residue": [],
  "source_map": [],
  "diagnostics": []
}
```

No key is conditionally absent. Success has `diagnostics: []`. Failure returns
the diagnostic envelope defined below and no partial manifest.

### Identity and producer

`producer` has exactly:

```json
{
  "name": "FSMGen",
  "contract_source": "FSM::HIAL::VIALBridge::Manifest",
  "reference_implementation": "perl"
}
```

The reference implementation name is diagnostic provenance, not a language-
specific semantic contract. `manifest_id` is SHA-256 over these UTF-8 bytes:

```text
fsmgen.hial_vial_bridge_manifest.v1\0
<authored-layer>\0
<repository-relative authored identity>\0
<authored content SHA-256 lowercase hex>\0
<root unit semantic id>
```

and is rendered as `bridge/<hex>`. No generated target text, absolute path,
timestamp, process ID, random value, tool installation, or output directory
participates.

Semantic IDs are stable, source-meaningful strings:

```text
unit/<name>
configuration/<name>
type/<name>
endpoint/<name>
domain/<name>
transaction/<name>
event/<transaction-name>/<event-name>
protocol/<name>
observation/<name>
probe/<name>
binding/<target-language>/<semantic-id>
residue/<id>
```

The first profile contains one unit, so the concise endpoint/domain/probe IDs
selected by the checked `.vial` source are unambiguous. Multi-unit widening
must select a collision and migration rule before reusing this profile.

### Sources, route, and review artifacts

Each `sources[]` record has exactly:

```text
source_id, layer, kind, role, repository_path, artifact_name,
content_sha256, byte_length, line_count
```

`layer` is `IAL0`, `IAL1`, or `IAL2`; `role` is `authored` or
`generated_review`. `content_sha256` is 64 lowercase hex digits over the exact
source bytes. `repository_path` is a repository-relative POSIX path or null;
`artifact_name` is always non-empty.

`review_route` has exactly:

```text
authored_layer, direct_ial2_to_verification, stages
```

`direct_ial2_to_verification` is always false. Each ordered `stages[]` entry
has `layer`, `source_id`, and `review_artifact_ids`. Direct IAL0 has one stage;
direct IAL1 has IAL1 then IAL0; IAL2 has IAL2 then IAL1 then IAL0.

Each `review_artifacts[]` record has:

```text
artifact_id, layer, format, artifact_name, repository_path,
source_id, content_sha256, generated, entry
```

`generated` and `entry` are JSON booleans. The authored `.fsm` is both source
and review artifact. Generated virtual artifacts retain null paths.

### Units and configuration

Each `units[]` record has:

```text
unit_id, name, parent_unit_id, instance_name, source_layer,
configuration_ids, endpoint_ids, domain_ids, transaction_ids,
protocol_ids, observation_ids, probe_ids, backend_binding_ids
```

`parent_unit_id` and `instance_name` are null for the root. The first profile
rejects non-null values and more than one unit, but the record does not need a
schema migration when composition is later qualified.

Each `configurations[]` record has:

```text
configuration_id, unit_id, name, type_id, value, origin,
backend_binding_ids
```

`origin` is `parameter`, `generic`, or `verification_control`. `value` is the
normalized value record described below. Missing unresolved values are an
error, not null.

### Logical types and values

Each `types[]` record has exactly:

```text
type_id, name, kind, state_domain, signed, width,
enum_members, fields, element_type_id, length
```

`kind` is `logic`, `enum`, `record`, or `list`. `state_domain` is `two_state`
or `four_state` for logic/enum and null for aggregate containers. `signed` and
`width` are Boolean/integer for scalar kinds and null for aggregates.
`enum_members[]` contains `{name, value}`; `fields[]` contains
`{name, type_id}`. `element_type_id`/`length` are non-null only for lists.
Unused arrays are empty and unused scalars are null.

HIAL scalar ports and storage map to four-state `logic` records so X/Z remains
observable in both SystemVerilog and VHDL simulation; the bridge does not
claim that synthesis hardware stores unknown states. Signedness and positive
width must match the validated HIAL source exactly. The first profile supports
only logic records; enum/record/list shapes are schema-selected but fail
closed until a later profile implements their existing HIAL contracts.

Bridge types are authoritative **hardware carrier** types; they do not replace
or duplicate VIAL semantic types. Decision `0037` assigns the later binder a
closed directional proof between the independently owned types. Consequently,
the bridge remains four-state for a hardware port even when a VIAL Boolean or
unsigned value can be injected into it with all bits known and no Z. The
bridge does not claim the inverse conversion, VIAL arithmetic meaning, or enum
identity that HIAL did not declare.

A normalized `value` has exactly:

```json
{
  "type_id": "type/logic_u32",
  "width": 32,
  "value_hex": "00000000",
  "known_hex": "ffffffff",
  "z_hex": "00000000"
}
```

Hex strings are lowercase, zero-padded to `ceil(width/4)`, and masked above
width. `known_hex & z_hex` is zero. Two-state values require all known bits and
zero Z bits.

### Endpoints and time domains

Each `endpoints[]` record has:

```text
endpoint_id, unit_id, name, direction, type_id, role, access,
domain_id, backend_binding_ids
```

`direction` is `input`, `output`, or `inout`. `access` is `public_port`; probes
are not duplicated as endpoints. `role` is `clock`, `reset`, `data`, or an
explicit validated protocol role such as `ready_out`. `domain_id` is non-null
for synchronous data and clock/reset ports. Direct IAL0/IAL1 without a bridge
annotation uses role `data` and domain `domain/default`; signal-name heuristics
never invent protocol roles.

Each `domains[]` record has:

```text
domain_id, unit_id, name, clock_endpoint_id, active_edge,
reset_endpoint_id, reset_kind, reset_polarity
```

`active_edge` is `rising` or `falling`; v1 selects `rising`. `reset_kind` is
`async` or `sync`; polarity is `active_low` or `active_high`. A source without
an explicit reset is rejected by the first profile.

### Transactions and events

Each `transactions[]` record has:

```text
transaction_id, unit_id, name, type_id, protocol_id,
ordering, correlation, fields, event_ids
```

`ordering` is `in_order` in the first profile. `correlation` is
`single_active` for the first AHB transaction and `declaration_order` for a
plain IAL1 transaction. Because this profile admits scalar transaction fields
but no aggregate transaction record type, transaction `type_id` is null;
field `type_id` values are the authoritative v1 type links. A later aggregate-
type profile must assign a non-null transaction record type. Each `fields[]`
record has:

```text
name, type_id, endpoint_id, direction, phase_role
```

where direction is `drive` or `sample`, and phase role is `address_phase`,
`data_phase`, `configuration`, or `unspecified`.

Here authoritative means the exact HIAL carrier at the seam, not that a VIAL
field must discard its own semantic type. The later binder must prove one of
decision `0037`'s closed relations for this direction; a bridge manifest does
not contain, forge, or pre-approve that proof.

Each `events[]` record has:

```text
event_id, transaction_id, name, kind, phase, expression,
required_endpoint_ids, required_probe_ids
```

`kind` is `scenario_start`, `predicate`, or `rising`. `expression` is null for
`scenario_start` and otherwise a bridge-owned sanitized canonical expression
record with exactly `kind`, `operator`, `operands`, `value`,
`reference_kind`, and `semantic_id`. Calls recursively hold operand records;
literals hold only `value`; references identify an endpoint or probe by stable
semantic ID, while validated actor storage is named with null `semantic_id`
because storage is not otherwise a public bridge family in this profile. This
record is selected here because the current public IAL1 schedule report does
not expose a canonical expression AST. No rendered SV/VHDL text is stored.
Reference arrays are sorted unique IDs.

The checked AHB route must publish exactly transaction
`transaction/ahb_write` with fields `address`, `transfer`, `write`, `size`,
`data`, and `wait_cycles`, and events `requested`, `accepted`, `captured`,
`held`, `completed`, and `error`. This matches the checked VIAL source without
teaching VIAL AHB signal or UVM vocabulary. Field names and carrier widths/
signedness match; `transfer`, `write`, and `wait_cycles` deliberately retain
richer VIAL enum/two-state semantics and bind through the directional proofs
selected by decision `0037`.

### Protocols, observations, and probes

Each `protocols[]` record has:

```text
protocol_id, unit_id, name, profile, revision, role,
transaction_ids, facts
```

`facts[]` is a key-sorted array of `{name, value}` copied from the validated
IAL1 annotation. The checked AHB profile uses id
`protocol/ahb_lite_subordinate`, profile `ahb`, subordinate role, its source
revision anchor, and the exact selected transfer/response/error-completion
facts. Unknown facts are rejected by a profile-specific validator; the bridge
does not become an untyped property bag.

Each `observations[]` record has:

```text
observation_id, unit_id, name, role, domain_id, endpoint_ids
```

It projects existing IAL1 `(observe ...)` metadata. Version 1 accepts only
`passive_monitor`. The direct IAL1 fixture publishes
`observation/link_rx` over `endpoint/valid`, `endpoint/ready`, and
`endpoint/data` in authored order.

Each `probes[]` record has:

```text
probe_id, unit_id, name, type_id, access, domain_id,
adapter_requirement, backend_binding_ids
```

`access` is `verification_probe`; `adapter_requirement` is
`equivalent_adapter_required`. The checked AHB annotation publishes
`probe/reg_data_q`. No backend hierarchy path is exposed. A later execution or
backend profile must supply the named equivalent-adapter capability or reject
the fixture before output.

### Backend bindings and capabilities

Each `backend_bindings[]` record has:

```text
binding_id, semantic_id, target_language, target_kind, target_name,
status, required_capabilities
```

`target_language` is `systemverilog` or `vhdl`; `target_kind` is `module`,
`entity`, `port`, `generic`, or `probe_adapter`. Unit and public-port names are
copied from validated HIAL backend naming contracts. `status` is `declared`
for names and `adapter_required` for a probe. The record makes no compile,
simulation, methodology, or parity claim.

`required_capabilities[]` is a sorted unique array. `.5` may advertise only:

```text
hial_vial.bridge_manifest.v1
hial_vial.bridge_profile.core_single_unit_v1
hial_vial.bridge_source.ial0
hial_vial.bridge_source.ial1
hial_vial.bridge_source.ial2_via_generated_ial1
hial_vial.bridge_observation.passive_monitor
hial_vial.bridge_protocol.ahb_subordinate_v1
hial_vial.bridge_probe.equivalent_adapter_required
```

Only capabilities exercised by a manifest are present. The last three are
conditional on observation, AHB, and probe records. Backend execution
capabilities remain absent.

### Unsupported residue and source maps

Each `unsupported_residue[]` record has:

```text
residue_id, source_id, detail, owner, required_capability
```

`residue_id` is `residue/<annotation-id>`. `owner` is a task-tree ID or null;
`required_capability` is a future capability string or null. The five checked
AHB residue IDs must survive the generated IAL1 annotation and manifest in
source order. A missing residue record is not interpreted as support.

Each `source_map[]` record has:

```text
fact_path, semantic_id, field_path, provenance
```

`fact_path` is an RFC 6901 JSON Pointer from the manifest root. `field_path`
is an RFC 6901 pointer relative to the semantic record. `provenance[]` is a
non-empty ordered array whose records have exactly:

```text
source_id, review_artifact_id, precision, semantic_path,
start_byte, end_byte, start_line, start_column, end_line, end_column,
derivation
```

`precision` is `span`, `semantic_path`, or `generated`. Span fields are all
integers only for `span` and otherwise null. `semantic_path` is always a
non-empty stable path. `derivation` is `authored`, `generated_annotation`,
`inferred_system_contract`, or `derived_identity`.

Every scalar or array field under the semantic families from `units` through
`unsupported_residue` has exactly one source-map entry. Identity-derived
fields map to their complete inputs. Generated IAL2 facts include both the
authored IAL2 source and generated IAL1 annotation provenance. The first
implementation must not fabricate byte spans because current IAL0/IAL1
parsers do not preserve them uniformly; `semantic_path` is the honest minimum.

## Determinism, Immutability, and Projection

All semantic arrays except route stages and authored observation endpoint
order are sorted by semantic ID. Route stages remain IAL2 -> IAL1 -> IAL0,
observation endpoints preserve authored order, protocol facts sort by name,
capabilities sort lexically, and source maps sort by `fact_path`.

`FSM::HIAL::VIALBridge::Builder` alone constructs the private immutable
manifest object. Accessors, `as_hashref`, and the sanitized report return deep
defensive copies. Inputs are cloned before validation. No returned branch may
share mutable storage with caller input, another return value, or the internal
object.

The selected `.5` private entrypoints are:

```perl
FSM::HIAL::VIALBridge::Builder->build_ial0({ ...validated route... })
FSM::HIAL::VIALBridge::Builder->build_ial1({ ...validated route... })
FSM::HIAL::VIALBridge::Builder->build_ial2_via_ial1({ ...validated route... })
FSM::HIAL::VIALBridge::Report->build($manifest)
```

Each method accepts exactly one hash. The route supplies exact source bytes,
repository-relative identity, validated frontend/scheduler results, generated
review bytes, requested target-name mappings, and a closed source catalog.
Unknown keys, undefined required values, live parser/IR objects in the public
projection, or mismatched content identities fail closed.

The report is a full defensive JSON-safe projection with the exact manifest
shape; it does not expose a second summary schema. The manifest is the bounded
public data contract, while the private entrypoint is not a supported
embedding API until `.8` selects public tooling. `.5` writes no file.
`<out>/hial-vial-bridge.json`, CLI flags, output directories, and artifact-
manifest discovery remain owned by `.8`.

## Diagnostics

Failure returns:

```text
ok: false
manifest: null
report: null
diagnostics:
  - code, category, message, source, path, span, related
```

Selected codes are:

```text
HIAL_VIAL_BRIDGE_INVOCATION_ERROR
HIAL_VIAL_BRIDGE_ROUTE_ERROR
HIAL_VIAL_BRIDGE_ANNOTATION_ERROR
HIAL_VIAL_BRIDGE_DUPLICATE_ID
HIAL_VIAL_BRIDGE_UNRESOLVED_REFERENCE
HIAL_VIAL_BRIDGE_TYPE_ERROR
HIAL_VIAL_BRIDGE_ACCESS_ERROR
HIAL_VIAL_BRIDGE_CAPABILITY_ERROR
HIAL_VIAL_BRIDGE_LIMIT_ERROR
HIAL_VIAL_BRIDGE_INTERNAL_ERROR
```

Diagnostics are sorted by route stage, source order, semantic path, and code.
Independent annotation records may report together; dependent cascades are
suppressed. Messages and related records contain only repository-relative or
virtual artifact identities, never Perl stack text or machine-local paths.

## Bounded Limits

The schema is broader than the first profile. `.5` enforces these safety caps
before manifest construction:

| Resource | Limit |
| --- | ---: |
| sources / review artifacts | 3 / 3 |
| units / domains | 1 / 1 |
| configurations / logical types | 4,096 / 4,096 |
| endpoints | 4,096 |
| transactions / events | 256 / 2,048 |
| protocols / observations / probes | 16 / 256 / 256 |
| backend bindings | 16,384 |
| unsupported residue | 4,096 |
| source-map records | 65,536 |
| serialized manifest | 16,777,216 bytes |

Exceeding a cap yields `HIAL_VIAL_BRIDGE_LIMIT_ERROR`. These are defensive
version-1 limits, not `.17` performance or whole-product scale claims.

## First Implementation Oracles

Focused `t/1551-hial-vial-bridge-manifest.t` must prove:

- direct IAL0 yields one unit, all public/system endpoints, one default domain,
  normalized logic types, target-name bindings, empty protocol/observation/
  probe arrays, one-stage review route, and no target/runtime claim;
- direct IAL1 yields the actor interface, transaction `main`, its on/complete
  event meaning, `observation/link_rx`, the two-stage review route, and no
  protocol inference from names;
- AHB IAL2 generates and reparses the exact IAL1 annotation, then yields
  `unit/ahb_lite_subordinate`, `domain/ahb_bus`, exact public endpoints,
  `transaction/ahb_write`, six events, `protocol/ahb_lite_subordinate`,
  `probe/reg_data_q`, five retained residues, and a three-stage route;
- every emitted VIAL reference in
  `vial/ahb_subordinate_base_output_arbitration.vial` resolves by exact ID and
  type, while actual VIAL-to-bridge binding remains deferred to `.7`;
- generated IAL1 carries the additive annotation while generated IAL0 and
  SystemVerilog/VHDL HIAL behavior remain byte/semantically preserved;
- source bytes, route inputs, manifest accessors, reports, capability/support
  records, and nested arrays/hashes are defensive and deterministic;
- malformed/missing/duplicate annotation data, unresolved endpoints/storage,
  wrong widths/directions/phases/access, illegal raw hierarchy, direct PPIF
  consumption, content mismatch, unsafe path, unknown profile/fact/residue,
  unsupported composition/multi-domain/aggregate type, and every limit fail
  with stable sanitized diagnostics; and
- no bridge file, execution plan, target verification artifact, compile,
  simulation, result, parity, UVM, VHDL-methodology, mixed-language, or scale
  support is claimed.

Adjacent tests must cover the IAL1 public schedule-report key family, AHB PPIF
generated-review invariants, capability/language-surface/support accounting,
defensive copies, normalized semantic non-regression, and both current HIAL
backend outputs where locally supported.

## Implementation Ownership and Non-Claims

Completed `.5` implements exactly:

```text
perl/FSM/HIAL/VIALBridge/Builder.pm
perl/FSM/HIAL/VIALBridge/Manifest.pm
perl/FSM/HIAL/VIALBridge/Report.pm
the IAL1 verification-bridge parser/report contract
the AHB generated-IAL1 annotation
t/1551-hial-vial-bridge-manifest.t
bounded capability/support/language-surface discovery
```

It does not change `.vial` syntax or `VIALSemanticIR`, bind VIAL, create
`VIALExecutionIR`, publish a CLI/API, write `hial-vial-bridge.json`, generate a
verification testbench, select an execution scheduler, expose raw hierarchy,
or claim backend runtime/parity. Those boundaries remain with `.6`-.16 and
public tooling `.8`. Completed `.6` now selects decision `0036` and the exact
target-neutral execution contract in
`docs/VIAL_EXECUTION_IR_V1_CONTRACT.md`; proposed `.7` alone owns private
binding/ExecutionIR implementation after separate clean activation. The bridge
schema and implementation remain unchanged, and no execution behavior ships
in selection.

## Validation and Rollback

This contract selection must pass task-tree integrity, task/roadmap/audit/
book/fact consistency, documentation audits, every mdBook chapter and the
repository-local HTML build, Knowledge Map generation/check, bounded Memory,
diff, staged docs-only acceptance, all doctrines, and exact output cleanup.

Rollback removes this contract, decision `0035`, its fact/book/roadmap/task
continuity, returns `.4` to active, and removes the `.5` selection. No parser,
annotation, bridge object/report, generated review artifact, manifest,
capability/support entry, HDL, VIAL binding, test runtime, or product behavior
changes in selection.
