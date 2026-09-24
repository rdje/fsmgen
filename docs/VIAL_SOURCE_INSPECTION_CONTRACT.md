# VIAL source inspection contract

Date: 2026-09-24
Owner: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3`
Status: internal base projector implemented; lifecycle, public API and advertisement pending

## Purpose and compatibility

An external agent needs typed source meaning, including lifecycle conditions
and deadlines, declaration bodies and scenario actions. The existing public
`semantic_report` is deliberately a summary. Its family counts and declaration
names cannot answer those questions. The exact public/native/MCP observation
is retained in
`docs/audits/mcp-feature-coverage-20260924/vial-summary-boundary.json`.

Decision `0105` selects a separate source-inspection schema. Existing v1/v2
check, format, plan, tooling capability records, semantic summaries and meaning
digests are unchanged by the additive inspection API. Neither the private SemanticIR
object nor its `as_hashref` record becomes a public API. Compiler changes must
adapt to the inspection contract, not silently redefine it.

Separate native bug corrections preserve model-instance identity (`.31.3.2.5`),
exact fault binding (`.31.3.2.6.1`) and authored declaration order (`.31.3.2.7`).
They correct affected meaning digests in both language versions; cached values
for those sources require refreshing. Inspection retains the corrected scope
and order. Existing compiler bugs are not compatibility promises.

## Selected entrypoints

The following interfaces are selected, **not yet callable**:

```perl
FSM::VIAL::Tool::inspect_vial_source({
    source_id => 'vial/example.vial', text => $source_bytes,
    source_catalog => {}, language_version => 2, source_style => 'auto',
});
FSM::VIAL::Tool::inspect_vial_source_file({
    workspace_root => $caller_root, source_id => 'vial/example.vial',
    language_version => 2, source_style => 'auto',
});
```

Each accepts exactly one unblessed closed hash. The portable call requires
`source_id` and byte-string `text`; its optional `source_catalog` maps relative
source IDs to byte strings and defaults to empty. The filesystem call requires
`workspace_root` and `source_id` and accepts no catalog or text. Both default to
language version 1 and style `auto`; only versions 1/2 and styles
`auto|normal|terse` are admitted. The selector is explicit, never inferred from
the filename or silently migrated. Portable calls perform no filesystem,
environment, provider or network access. Filesystem calls share the qualified
bounded loader and its root, symlink, same-volume and import policy.

Inspection consumes the same captured source bytes as checking; it must not
reopen files after validation. It requires no DUT source, bridge binding,
random decision evaluation, plan, backend, simulator or artifact destination.
Calls return fresh JSON-safe values without stdout/stderr or publication.

The closed result is:

```text
schema: fsmgen.vial_source_inspection.v1
schema_version: 1
success: JSON boolean
check_result: complete existing selected-version public check result
inspection: null on failure, otherwise the source-semantics projection below
diagnostics: ordered public diagnostic records
```

Source/admission failures retain the existing check diagnostic and null detail;
the wrapper diagnostics equal those of the failed check. Successful inspection
has an empty diagnostic list. An internal projection-contract failure must
fail closed with a sanitized inspection diagnostic and null detail even if
checking succeeded; it cannot publish partial data or a false success.
Invocation errors also return this result shape with an unsuccessful native
check result. Existing source limits and diagnostic versioning remain in force.

## Source-semantics projection

The closed detail envelope is `fsmgen.vial_source_semantics.v1` with
`schema_version`, `language`, `language_version`, `profile`, `root_source`,
`sources`, `packages`, `required_capabilities`, and `unresolved_bridge_refs`.
The public schema version is independent of the inspected language version.
Root/import identities retain relative source names and content hashes. Package
declarations and action arrays retain authored order; required capabilities
remain sorted. Expanded lifecycle nodes retain their explicit semantic order.
Bridge references are explicitly unresolved assertions, not HIAL facts.

Fault detail must always expose the resolved `transaction_binding_id`. The
native source record supplies it explicitly for ambiguous declarations; for a
unique declaration binding the projection must resolve it from that fixture's
bindings. Missing or non-unique inferred scope is a projection error, never a
license to select the first binding. This requirement does not change legacy
summary shapes or qualify runtime behavior.

The implementation must use explicit constructors with closed, discriminated
record shapes for the following semantic groups:

| Group | Required public meaning |
| --- | --- |
| Packages/imports | Names, semantic identities and resolved import package references |
| Types | Scalar properties, enum members/values, aliases, record fields and bounded list element/count |
| Transactions | Ordered typed fields and event identities |
| Models | Inputs, typed state with initial values, event rules and assignments |
| Scoreboards | Transaction reference, ordering policy and capacity |
| DUT/instances | Opaque bridge references, domain/endpoint access and types, transaction/model/scoreboard bindings |
| Coverage | Sample domains, typed expressions, bin matchers, cross point references and bounds |
| Faults | Exact transaction binding and declaration, field target, typed substitution and duration/domain |
| Randomness | Authored seed, choice type/identity, distribution and constraints; no chosen runtime value |
| Scenarios | Timeout domain/bound, handles, ordered actions, nested fibers/repeats and their join semantics |
| Expressions/properties | Kind/operator, normalized literal or resolved reference, result type, ordered operands and temporal bounds |
| Intent families | Family identity/revision and every typed lifecycle node as described below |

Named entities retain `semantic_id` and authored `name`. Cross-references retain
resolved semantic IDs rather than re-resolving names on the client. Semantic
paths and source spans become explicit public `semantic_path` and
`source_location` values. Source locations use the existing closed relative
source/byte/line/column coordinates. No global private provenance table,
parser forms, mutable compiler links or target program is exported.

Public record definitions must enumerate fields and discriminants before the
corresponding implementation slice ships. Mapping an entire arbitrary private
hash recursively is insufficient: unrecognized kinds/fields must trigger
review, never disappear or leak through unnoticed. Fresh defensive values and
repeat-call determinism are required throughout.

### Base detail record definitions

These fields define the independent inspection representation. Every record is
closed; every listed field is required, including fields whose value can be
null. Declaration and action arrays preserve source order. Declaration order
is recovered from source coordinates independently of compiler dependency
construction order. `M` abbreviates `semantic_path` and
`source_location`; `N` adds `semantic_id` and `name` to `M`. The abbreviations
are documentation notation, not emitted keys. Locations contain `source_name`,
`start_byte`, `end_byte_exclusive`, `start_line`, `start_column`, `end_line`,
`end_column`. Source records contain `source_name`, `content_sha256`,
`byte_length`, `line_ending`. Bounds/widths/counts/coordinates are JSON integers;
flags are JSON booleans; identifiers, seed, decimal literal values and
hexadecimal literal bit/mask strings remain strings. Existing source contracts
own admissible numeric ranges and semantic relationships.

| Record | Fields beyond `M` or `N`, where stated |
| --- | --- |
| Package (`N`) | `source_name`, `imports[]`, `types[]`, `transactions[]`, `models[]`, `scoreboards[]`, `fixtures[]`, `intent_families[]` (empty for base v1) |
| Import (`M`) | `alias`, `source_name`, `package_id` |
| Type declaration (`N`) | `declaration_kind: alias\|enum`, `type` |
| Enum member (`N`) | `value` |
| Transaction (`N`) | `fields[]` (typed names), `events[]` (names) |
| Typed name (`N`) | `type` |
| Model (`N`) | `inputs[]` (typed names), `state[]`, `rules[]` |
| State (`N`) | `type`, `initial_value` |
| Rule (`M`) | `input_id`, `assignments[]` |
| Assignment (`M`) | `state_id`, `expression` |
| Scoreboard (`N`) | `transaction_id`, `policy: in_order\|keyed`, `key` (string or null), `capacity` |
| Fixture (`N`) | `dut`, `instances`, `coverage`, `faults[]`, `randomness`, `scenarios[]` |
| DUT (`N`) | `unit_bridge_ref`, `domains[]`, `endpoints[]`, `transaction_bindings[]` |
| Domain (`N`) | `bridge_ref` |
| Endpoint (`N`) | `bridge_ref`, `type`, `access: public_port\|verification_probe` |
| Transaction binding (`N`) | `bridge_ref`, `authored_transaction`, `transaction_id` |
| Instances | `model_instances[]`, `scoreboard_instances[]` |
| Model instance (`N`) | `model_id`, `bindings[]` |
| Model binding (`M`) | `input_id`, `value` (expression or event binding) |
| Event binding | `semantic_id`, `event_id` |
| Scoreboard instance (`N`) | `scoreboard_id`, `transaction_id`, `actual_id` |
| Coverage | `coverpoints[]`, `crosses[]` |
| Coverpoint (`N`) | `domain_id`, `expression`, `bins[]` |
| Bin (`N`) | `classification: normal\|illegal\|ignore`, `matcher` |
| Cross (`N`) | `point_ids[]`, `max_bins` |
| Fault (`N`) | `transaction_id`, `transaction_binding_id`, `field_name`, `substitute` (expression), `domain_id`, `duration_cycles` |
| Randomness | `seed`, `choices[]` |
| Choice (`N`) | `type`, `decision_id`, `distribution`, `constraints[]` (properties) |
| Distribution | `kind: uniform`, `low`, `high` (literal values) |
| Scenario (`N`) | `domain_id`, `timeout_cycles`, `actions[]`, `action_count`, `fiber_count` |
| Fiber (`N`) | `actions[]` |
| Transaction field value (`M`) | `field_id`, `value` (expression) |

A bin matcher is `{kind: value, value}` or `{kind: range, low, high}`, with
literal-value children. Type records have these exact alternatives:

| Type `kind` | Additional fields |
| --- | --- |
| `scalar` | `family: bool\|u\|s\|logic\|slogic`, `width`, `signed`, `four_state` |
| `reference` | `authored_name`, `semantic_id`, `resolved` (type) |
| `record` | `fields[]`, each exactly `name`, `type` |
| `list` | `length`, `element_type` |
| `enum` | `semantic_id`, `base_type`, `members[]` |
| `event` | none |

Literal values have `kind` and exactly: `bool_value` → `value` (Boolean);
`enum_value` → `enum_id`, `member_id`; `integer_value` → `width`, `signed`,
`value_decimal`; `logic_vector` → `width`, `signed`, `value_bits`, `known_mask`,
`z_mask`. Masks retain X/Z distinctions without evaluating them.

Expressions all contain `M`, `kind`, `result_type`. A `literal` adds `value`.
A `reference` adds `op` and `semantic_id`; admitted operators are `enum_member`,
`symbol`, `sample`, `event`, `event_count`, `model`, `choice`. Only `model` also
requires `model_instance_id`. An `operator` adds `op`, `operands[]`; admitted
operators are `field`, `not`, `and`, `or`, `xor`, `same`, `value_eq`, `known`,
`+`, `-`, `<`, `<=`, `>`, `>=`. Only `field` adds `field_name`; `+`/`-` add
`overflow_policy: error`. A `property` adds `op: =>|next|within`, `operands[]`;
only `within` adds `min_cycles` and `max_cycles`.

Actions contain `M` and `kind`, plus exactly the corresponding fields:

| Action `kind` | Additional fields |
| --- | --- |
| `reset` | `domain_id`, `cycles` |
| `drive` | `endpoint_id`, `value` |
| `start` | `handle_id`, `transaction_binding_id`, `fields[]` |
| `await` | `property` |
| `parallel` | `join: all\|any`, `fibers[]` |
| `repeat` | `count`, `actions[]` |
| `expect` | `semantic_id`, `name`, `property` |
| `scoreboard_expect` | `scoreboard_instance_id`, `fields[]` |
| `scoreboard_check` | `scoreboard_instance_id` |
| `inject` | `fault_id` |

Each unresolved bridge assertion contains `fixture_id`, `kind`, `alias`,
`bridge_ref`, `expected_type`, `access`. Assertions follow fixture order, then
unit/domain/endpoint/transaction order. Unit/domain expected type and access
are null; endpoints carry their public type and access; transactions carry
the declaration ID as expected type and null access. These are source assertions,
not facts established by a DUT or backend.

### Lifecycle detail

Every projected family contains `semantic_id`, `family_id`, `revision`,
`semantic_path`, `source_location` and ordered `nodes`. A node has schema
`fsmgen.vial_intent_node.v1`, `schema_version: 1`, and exactly the following
meaning fields:

```text
semantic_id, family_id, revision, node_id, node_kind
scope, lifetime, order, ports, effects, failure, result
semantic_path, source_location, payload
```

The common typed meanings follow the
[semantic-family contract](vial-spec/semantic-family-envelope-and-registry.md);
payloads follow the exact registered family/revision grammar. The compiler's
private stage/schema labels are not used as the public inspection identity.
For `lifecycle_control@1`, preserve scalar-or-null condition reference/domain
IDs, ordered operands, intrinsic dependency/service prerequisites, milestone
relations, service target/cancellation, deadline start/end/domain/cycle bound,
and failure disposition/cleanup bounds. A count is not a substitute for nodes.
Unknown family revisions must fail admission rather than producing generic
untyped payloads. Future implemented families need a public projector and
independent semantic oracle before inspection advertises their support.

## CLI and MCP selection

Native `fsmgen vial inspect --json --language-version 1|2 SOURCE.vial` will
return the independent inspection result. Source style selection matches the
API. It accepts no planning, runtime or publication options. Inspection
capability discovery is a new separate contract; frozen tooling capability
records remain unchanged.

MCP will expose `fsmgen_vial_inspect` with closed `source_id`, optional
`language_version` and optional `source_style` arguments, backed by the public
filesystem API. The explicit resource template is
`fsmgen://vial/{language_version}/source/{source_id}/inspection` and uses
automatic source style. A dedicated `vial_inspection` capability-query section
will describe the new schema and coverage. Text/structured reports and resource
reports must agree completely with the native API. Failed inspections set
tool `isError`; protocol/parameter errors retain ordinary JSON-RPC behavior.
Original semantic paths remain semantic identities. Existing `check` and
`semantic` routes remain summary queries with unchanged results.

## Qualification and ownership

`.31.3.2.3.2` owns typed projection, public portable/filesystem APIs and CLI;
`.31.3.2.3.3` owns MCP. Decompose these before implementation. Each leaf needs
authored-value assertions independent of the compared producers, exact schema
and reference/location checks, malformed/missing-field negative controls,
defensive-copy and no-side-effect controls, and frozen v1/v2 regressions.
The catalog-driven guard must include inspection when available and reject
new applicable features without an oracle. The earlier summary parity census
remains valid transport evidence, not proof of deep semantic coverage.
