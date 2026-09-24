# VIAL source inspection contract

Date: 2026-09-24
Owner: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3`
Status: selected; implementation and public advertisement pending

## Purpose and compatibility

An external agent needs typed source meaning, including lifecycle conditions
and deadlines, declaration bodies and scenario actions. The existing public
`semantic_report` is deliberately a summary. Its family counts and declaration
names cannot answer those questions. The exact public/native/MCP observation
is retained in
`docs/audits/mcp-feature-coverage-20260924/vial-summary-boundary.json`.

Decision `0105` selects a separate source-inspection schema. Existing v1/v2
check, format, plan, tooling capability records, semantic summaries and meaning
digests retain their current shapes and values. Neither the private SemanticIR
object nor its `as_hashref` record becomes a public API. Compiler changes must
adapt to the inspection contract, not silently redefine it.

The separate native bug correction `.31.3.2.5` preserves selected model-instance
identity and corrects affected meaning digests in both language versions.
Inspection must retain that identity alongside the shared state declaration;
the existing projection bug is not a compatibility promise.

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
and member arrays retain authored order; required capabilities remain sorted.
Bridge references are explicitly unresolved assertions, not HIAL facts.

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
| Faults | Transaction field target, typed substitution and duration/domain |
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
