# VIAL v2 source, schema, compatibility, import, and migration

Date: 2026-09-04
Owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.1`
Status: v2 source/migration/empty-base public tooling and the complete common foundation implemented through `.19.1.7`

## Outcome and authority

VIAL language version 2 is an additive envelope for target-independent
verification-intent families. It retains every version-1 declaration and
fixture meaning, adds one ordered `intents` package section, and admits only
family/revision grammars registered by the compiler. Normal and terse source
remain projections of one typed meaning. No source may carry an unknown clause
as inert data, and no backend-shaped text or raw SystemVerilog, UVM, VHDL, host
callback, hierarchy handle, or simulator command enters the language.

This contract freezes the source/version boundary before implementation.
Decision `0034` is its design authority. The v1 contract remains the complete
authority for language version 1. Later family leaves own the closed grammar
and semantics below each registered family block; `.19.1.3` owns the common
typed envelope through execution and results; `.19.1.4` owns the selected
taxonomy registry and fail-closed negotiation; `.19.1.5` owns common backend
adapter admission; `.19.1.7` owns public migration/tooling exposure.

## Immutable version-1 boundary

The implementation must route on the root language version before applying a
version-specific normalizer or builder. For a v1 root, all accepted bytes,
normal/terse formatting, semantic records and digests, profile and capability
IDs, import behavior, diagnostics and messages, limits, public v1 request and
result records, bridge/planning/backend behavior, artifacts, and support
classifications remain byte-for-byte or deeply equal to the pre-v2 behavior.

In particular, v1 keeps six mandatory package sections and does not accept an
`intents` or adapter clause. A v1-root catalog keeps the pre-v2 diagnostic
order: an imported normal non-v1 root reaches the existing bounded-version
`VIAL_LIMIT_ERROR`, while an imported terse non-v1 root keeps the existing
`VIAL_SOURCE_STYLE_ERROR`. The later explicit parse error was unreachable
because bounded integer validation ran first. A v2 implementation may share
private helpers only when focused regression proves this observable boundary;
neither formatting nor capability discovery silently upgrades v1 source.

## Roots and closed package envelope

The normal root and its exact section order are:

```text
SOURCE_V2      := (vial (version 2) PACKAGE_V2)
PACKAGE_V2     := (package NAME IMPORTS TYPES TRANSACTIONS MODELS
                   SCOREBOARDS INTENTS FIXTURES)
IMPORTS        := (imports IMPORT_V2*)
IMPORT_V2      := (import NAME STRING)
                | (import NAME STRING (adapter ADAPTER_ID))
TYPES          := the unchanged v1 types section
TRANSACTIONS   := the unchanged v1 transactions section
MODELS         := the unchanged v1 models section
SCOREBOARDS    := the unchanged v1 scoreboards section
INTENTS        := (intents FAMILY_BLOCK*)
FAMILY_BLOCK   := (family FAMILY_ID (revision REVISION) FAMILY_NODE*)
FIXTURES       := the unchanged v1 fixtures section
```

`NAME`, `STRING`, `ADAPTER_ID`, and positive integer `REVISION` retain the v1
lexical rules and spans. The seven package sections are mandatory and ordered;
empty sections are explicit. At least one fixture remains mandatory. Each
`FAMILY_ID` appears at most once in a package, and one family ID has one
revision throughout a connected source catalog.

`FAMILY_NODE` is not an open extension hash or generic syntax tree. It is a
closed discriminated source form owned by the exact registered
`(FAMILY_ID, REVISION)` grammar. Before that registration ships, a non-empty
block fails. Unknown family IDs, revisions, node heads, fields, defaults, and
backend-shaped escape clauses fail before SemanticIR construction.

The terse root is `(vial 2 PACKAGE_V2_TERSE)`. It removes the version wrapper,
empty section wrappers, and the existing v1 fixture/scenario/step wrappers.
Non-empty imports and declarations retain authored order. A family block
remains `(family FAMILY_ID (revision REVISION) FAMILY_NODE*)`; only the outer
`intents` wrapper is removed. Family and revision are therefore never inferred
by position, file name, backend profile, or ambient registry state.

Both styles normalize to the normal grammar before the one v2 builder runs.
Their public style identities are `normal_v2` and `terse_v2`. Canonical
formatting preserves the input language version by default and must reparse to
the same `fsmgen.vial_semantic_projection.v2` digest. A caller must invoke the
separate migration operation to change a language version.

## Source-phase schema identities

The following identities are exact. A consumer never guesses a schema from a
file name, `schema_version` alone, or a v1 object shape.

| Record or capability | Version-2 identity | Implementation owner |
| --- | --- | --- |
| private semantic record | `fsmgen.vial_semantic_ir.v2` / `schema_version: 2` | implemented by `.19.1.2-.19.1.3` |
| sanitized semantic report | `fsmgen.vial_semantic_report.v2` | implemented by `.19.1.2` |
| format/reparse meaning | `fsmgen.vial_semantic_projection.v2` | `.19.1.2` |
| cross-version base meaning | `fsmgen.vial_compatibility_projection.v1` | `.19.1.2` |
| source diagnostic | `fsmgen.vial_diagnostic.v2` | `.19.1.2` |
| migration result | `fsmgen.vial_source_migration.v1` | `.19.1.7` |
| source capability | `vial.source.v2` | `.19.1.2` IR requirement; `.19.1.7` public discovery |
| semantic capability | `vial.semantic_ir.v2` | `.19.1.2` IR requirement; `.19.1.7` public discovery |
| base profile | `vial.profile.core_directed_single_clock_v2` | `.19.1.2-.19.1.3` |

The implemented private downstream base carriers are
`fsmgen.vial_execution_ir.v2` and `fsmgen.vial_plan.v2`.
The selected later result identities are
`fsmgen.verification_result_manifest.v2`,
`fsmgen.vial_parity_projection.v2`, `fsmgen.vial_parity_report.v2`, and
`fsmgen.vial_source_map.v2`. Public v2 tooling uses
`fsmgen.vial_tool_request.v2` and `fsmgen.vial_tool_result.v2`. Their exact
fields and implementation are owned by `.19.1.3` and `.19.1.7`;
naming them here prevents a v1 schema from being silently widened. The unchanged HIAL
facts continue to use `fsmgen.hial_vial_bridge_manifest.v1`; a new bridge
version requires a real HIAL fact-shape change, not merely a v2 VIAL source.

## Implemented source and common phase boundary

Leaf `.19.1.2` implements the source-semantic foundation without advancing a
backend or public-tool schema. `FSM::VIAL::Parser` dispatches the connected
catalog by its root version. A separate version-2 builder validates the exact
seven-section envelope, rejects every non-empty family block whose registered
source stage is not implemented, and reuses the unchanged v1 semantic builder
for the inherited base grammar. It then constructs a new immutable v2 record
with typed `intent_families` and the authored `intents` span. The collection is
empty for the base fixture; `lifecycle_control@1` expands through its separately
closed compiler contract.

Normal-v2 and terse-v2 formatting preserve language version and reparse to one
`fsmgen.vial_semantic_projection.v2` digest. Empty-intents v2 and v1 also
produce one `fsmgen.vial_compatibility_projection.v1` digest. Same-version v2
catalog imports preserve root-then-depth-first authored order; v2-to-v1 imports,
reserved adapters, unknown versions, unknown families, backend-shaped forms,
and family bounds fail with closed v2 diagnostics. A v1-root catalog continues
through the legacy normalizer and retains its prior import diagnostics.

The existing public `fsmgen.vial_tool_request.v1` rejects v2 rather than
mislabeling it or loading a v2 CLI catalog. The additive v2 request exposes
check, format, migration, and empty-base planning through distinct records.
The plan builder carries the empty-intents base or implemented lifecycle nodes
through the unchanged v1 HIAL bridge into distinct v2 ExecutionIR and plan
envelopes. Other expressive families, v2 backend execution, complete result
manifests, and parity remain owned by later leaves. The focused
executable authorities are `t/1801-vial-v2-source-projections.t` and
`t/1802-vial-v2-semantic-family-envelope.t`; lifecycle compiler authority is
`t/1808-vial-v2-lifecycle-compiler-phases.t`.

The separate executable usability gate checks the seven maintained public VIAL
fixtures, both canonical v2 projections, a deterministic source diagnostic,
both semantic versions, and the v2 family carrier against one finite
target/methodology vocabulary. This is not a ban on verification concepts such
as coverage, properties, transactions, or constrained choices. It rejects
backend language, profile, syntax, package, and methodology-plumbing names
from the author and semantic layers so those layers remain usable without
SystemVerilog, UVM, VHDL, Verilator, GHDL, or OSVVM knowledge. The full quality
contract and backend checks are specified in
[the semantic-family foundation](semantic-family-envelope-and-registry.md#executable-author-and-generated-artifact-quality).

The private v2 semantic record starts with exactly:

```text
schema: "fsmgen.vial_semantic_ir.v2"
schema_version: 2
language: "vial"
language_version: 2
profile: "core_directed_single_clock_v2" | a registered expressive v2 profile
root_source, sources, packages, required_capabilities, provenance
```

A package retains every v1 field and adds `intent_families` between
`scoreboards` and `fixtures`. Each entry initially has exactly `semantic_id`,
`family_id`, `revision`, `semantic_path`, `source_span`, and `nodes`. `nodes`
is a closed union selected by the family registry, never raw parser forms.
The common family envelope is complete before any expressive node is accepted;
it cannot mutate v1.

The base v2 required capabilities are sorted and include
`vial.source.v2`, `vial.semantic_ir.v2`, and
`vial.profile.core_directed_single_clock_v2`. A registered family additionally
reserves `vial.family.<family_id>.v<revision>`; implemented lifecycle source
also requires `vial.semantic_family_envelope.v2` and
`vial.family.lifecycle_control.deadline.v1`. Later stage and backend
capabilities remain distinct and are added only by their implementation owner.
Presence of a registry identity or source syntax never implies planning,
emission, compile, run, result, parity, methodology, scale, or support.

### Semantic-family envelope and registry

The immutable common family records, phase traceability rules, bounds,
selected family registry, exact fail-closed negotiation, and common backend
adapter admission contract live in
[their dedicated semantic part](semantic-family-envelope-and-registry.md).

### Private base and lifecycle execution

The private `FSM::VIAL::ExecutionBuilderV2` accepts exactly
`core_directed_single_clock_execution_v2` and a v2 SemanticIR whose family
collections are empty or contain implemented lifecycle nodes. It projects the
inherited base meaning through the unchanged v1 binder, then creates a new immutable
`fsmgen.vial_execution_ir.v2`; it never relabels the v1 object. The carrier
adds `semantic_families`, records the authored v2 semantic identity, replaces
the versioned source/semantic/profile/execution/plan capability IDs, adds
`vial.semantic_family_envelope.v2`, and derives a new plan identity. Lifecycle
records additionally carry typed fixture/domain bindings, operation IDs,
family/deadline capabilities, and cumulative source maps. The plan is
`fsmgen.vial_plan.v2`; the HIAL facts remain
`fsmgen.hial_vial_bridge_manifest.v1` because their meaning did not change.

V1 ExecutionIR and plan key sets, content hashes, and plan identity remain
exact. The v1 portable backend rejects the v2 ExecutionIR during capability
negotiation before returning artifacts. The v1 result producer rejects it
with `VIAL_RESULT_VERSION_UNSUPPORTED` before producing a manifest, preventing
a future v2 result from being mislabeled as v1. The result-family schema above
is an implemented common validator and traceability contract, not yet the
complete `fsmgen.verification_result_manifest.v2` producer.

No other nonempty family can reach these carriers until its vertical activity
marks the necessary registry stages implemented and supplies its closed grammar
and semantics. The common adapter preflight maps each family to all four
current routes but keeps every mapping unavailable. Public v2 source,
migration, empty-base plan, and lifecycle plan tooling now ship; backend
mappings remain unavailable.

## Import and adapter compatibility

The root plus every reachable source is one connected catalog. Without an
adapter, all sources must use the root language version. V2 import discovery
reads only caller-supplied repository-relative source identities and bytes,
retains root-then-depth-first-authored order, and performs no filesystem,
environment, cache, registry, or network lookup.

A plain v2-to-v1 or v1-to-v2 edge fails closed. The new v2 diagnostic is
`VIAL_IMPORT_VERSION_MISMATCH`; its primary location is the importing path and
its note identifies the imported root version. The v1 entry route remains
unchanged and therefore keeps its existing diagnostic behavior.

The adapter import form is reserved but initially has no registered adapter.
Any use therefore fails with `VIAL_COMPATIBILITY_ADAPTER_UNAVAILABLE`. A later
adapter is admissible only as a closed compiler-owned record containing exact
adapter ID, input and output language/schema versions, accepted source
profile, output profile, semantic and provenance mapping, limits, deterministic
content identity, and implementation capability. Adapters are explicit per
import edge, compose only through a separately selected acyclic chain, and
may not infer target syntax, weaken types/effects, erase diagnostics, or access
ambient state. An adapter on an already same-version edge, a direction/profile
mismatch, duplicate ID, cycle, missing capability, or non-exact output fails
with `VIAL_COMPATIBILITY_ADAPTER_INVALID` before declaration resolution.

No adapter is required for the selected v1-to-v2 migration because migration
converts the complete reachable catalog atomically. No implicit adapter and no
mixed-version catalog are supported by this slice.

## Deterministic non-deprecating migration

Migration is opt-in and non-mutating. V1 remains a supported source version;
the normal `check`, `format`, `plan`, and `run` routes preserve v1. The selected
migration accepts one valid v1 root plus its complete valid v1 source catalog
and returns canonical v2 source bytes without overwriting input files or
publishing artifacts.

The conversion is exact:

1. traverse root then imports depth-first in authored order, with each source
   identity visited once;
2. parse every source through the unchanged v1 route; any error returns no
   migrated catalog;
3. for normal source, change `(version 1)` to `(version 2)` and insert empty
   `(intents)` between `scoreboards` and `fixtures`;
4. for terse source, change root integer `1` to `2`; the absent empty
   `intents` wrapper remains absent;
5. render each source canonically in its input style unless the caller selects
   `normal_v2` or `terse_v2` for the whole catalog;
6. parse the complete output through v2 and compare one
   `fsmgen.vial_compatibility_projection.v1` digest before returning success.

The compatibility projection is defined only for a valid v1 catalog or a v2
catalog with no intent-family blocks. It removes schema/language-version,
profile-version, content-hash, byte-span, source-style, and empty-v2-container
differences, while retaining package/declaration/fixture meaning, authored
order, stable semantic IDs, types, values, actions, logical-time facts, bridge
references, limits, and required base semantics. It fails rather than project
a non-empty family block. Equal compatibility digests prove base semantic
equivalence, not source-byte, diagnostic-byte, plan, backend, result, parity,
performance, or support equivalence.

`fsmgen.vial_source_migration.v1` contains exactly `schema`,
`schema_version`, `source_language_version`, `target_language_version`,
`input_style`, `output_style`, ordered `sources`,
`compatibility_projection_sha256`, and `diagnostics`. Each source record has
`source_name`, `input_sha256`, `output_sha256`, `formatted_source`, and an
ordered semantic-path source map from input to output locations. Success has
versions 1 and 2, empty diagnostics, and every reachable source. Failure has
no source records or digest. Comments are not semantic and canonical migration
does not promise comment retention; original bytes remain untouched.

Reverse v2-to-v1 migration is not selected. A v2 catalog with any v2-only fact
must fail `VIAL_MIGRATION_ERROR`; it is never approximated, dropped, or emitted
as target-language text.

## Public version-2 tooling

Public v2 tooling is now an explicit additive surface. Omitting the selector
keeps the complete v1 behavior; no command or API request infers v2 from source
bytes. The CLI selector and commands are:

```bash
./bin/fsmgen vial capabilities --language-version 2 --json
./bin/fsmgen vial check --language-version 2 --json SOURCE.vial
./bin/fsmgen vial format --language-version 2 --style normal SOURCE.vial
./bin/fsmgen vial migrate --language-version 2 --json SOURCE_V1.vial
./bin/fsmgen vial plan --language-version 2 --dut HIAL_SOURCE SOURCE_V2.vial
```

The embedding capability entrypoint is
`FSM::VIAL::Tool::vial_tool_capabilities_v2()`. Both versions use
`FSM::VIAL::Tool::execute_vial_tool_request($request, $environment)`, dispatch
on the exact request schema, and never expose parser forms or private IR
objects. `vial_tool_capabilities()` and a CLI command without
`--language-version` remain exactly v1.

The v2 request has exactly `schema`, `schema_version`, `action`, `vial_source`,
`hial_source`, and `options`. Its schema is `fsmgen.vial_tool_request.v2` and
`schema_version` is 2. The options record retains exactly the v1 field family:
`source_style`, `output_style`, `fixture_id`, `scenario_ids`,
`execution_profile`, `backend_profile`, `replay_manifest`,
`native_extension_catalogs`, `artifact_policy`, and `quiet`. Inapplicable
fields are null or empty arrays rather than omitted.

The v2 result schema is `fsmgen.vial_tool_result.v2`. It contains exactly:

```text
schema, schema_version, action, success, status
source_identities, source_style, semantic_report, formatted_source
bridge_manifest, plan, tool_manifest, verification_output_manifest
result_manifest, artifacts, capability_evidence, support_accounting
diagnostics, implementation, source_migration
```

`source_migration` is non-null only for the migration action. V2 diagnostics
retain the exact `fsmgen.vial_diagnostic.v2` shape: `schema`, `schema_version`,
`severity`, `code`, `phase`, `message`, `semantic_path`, singular nullable
`source_location`, and `notes`. The v1 result and its plural-location public
diagnostic shape do not change.

The public action states are exact:

| Action | Accepted source | Writes | Current v2 state |
| --- | --- | --- | --- |
| `capabilities` | none | none | supported smoke |
| `check` | v2 | none | supported smoke |
| `format` | v2 | stdout only | supported smoke |
| `migrate` | complete valid v1 catalog | none | supported smoke |
| `plan` | empty-family v2 plus HIAL | virtual API or atomic repository tree | supported smoke |
| `run` | none accepted for execution | none | unavailable; rejects before parse, plan, backend, workspace, or artifact allocation |

The plan result carries `fsmgen.vial_plan.v2` and
`fsmgen.vial_tool_manifest.v2`. Its canonical source is v2; the unchanged HIAL
facts retain `fsmgen.hial_vial_bridge_manifest.v1`. The tool-manifest field set
is unchanged from v1 while the schema, source style, execution profile, plan
record, capability evidence, and support accounting are distinctly v2. The CLI
publishes its complete graph atomically below a repository-relative same-volume
root; API virtual mode returns the same complete ordered graph in the caller's
initially empty artifact sink.

Migration accepts null `output_style` for per-file style preservation or
`normal`/`terse` to select one style for the whole catalog. Its result reports
root `input_style` as `normal_v1` or `terse_v1`; `output_style` is
`preserve_v2`, `normal_v2`, or `terse_v2`. Each ordered source record contains
exactly `source_name`, `input_sha256`, `output_sha256`, `formatted_source`, and
`source_map`. Each source-map entry contains exactly `semantic_path`,
`input_location`, and `output_location`; locations retain repository-relative
source identity plus byte and line/column bounds. All pre-existing semantic
paths must map and remain in range. The inserted empty `intent_families` path
has no false v1 origin and is therefore not invented in the cross-version map.

The v2 capability contract derives its source and empty-plan capabilities from
the semantic-family registry's parser and planner profiles. It publishes no
`vial.family.*`, v2 backend, compile, runtime, complete-result, or parity
capability. `run` returns `VIAL_VERSION_UNSUPPORTED` with unavailable action
evidence and an empty sink/artifact graph. Source and migration plus empty-base
planning have separate `supported_smoke` records; these do not promote any
expressive family or backend.

## Bounds

V2 preserves every v1 lexical, source-file, combined-catalog, import, token,
nesting, declaration, fixture, action, fiber, type, scoreboard, coverage, and
cycle limit for the unchanged grammar. It additionally enforces before
SemanticIR allocation:

| Resource | Limit |
| --- | ---: |
| family blocks per package | 256 |
| family nodes per block | 4,096 |
| family nodes across one connected catalog | 65,536 |
| registered family revisions in one catalog | 256 |
| compatibility adapters per import edge | 1 |

Family-specific leaves may select tighter independent limits but may not raise
these catalog ceilings by implication. Exceeding a base or family limit yields
`VIAL_LIMIT_ERROR`; it is a safety boundary, not a scale/support claim.

## Diagnostics and atomic failure

A v2 source diagnostic contains exactly:

```text
schema: "fsmgen.vial_diagnostic.v2"
schema_version: 2
severity: "error"
code, phase, message, semantic_path, source_location, notes
```

The v1 field meanings, source locations, note records, deterministic ordering,
cascade suppression, sanitization, and one-line thrown form remain unchanged.
V2 adds `VIAL_VERSION_UNSUPPORTED`, `VIAL_IMPORT_VERSION_MISMATCH`,
`VIAL_COMPATIBILITY_ADAPTER_UNAVAILABLE`,
`VIAL_COMPATIBILITY_ADAPTER_INVALID`, `VIAL_MIGRATION_ERROR`,
`VIAL_FAMILY_UNSUPPORTED`, `VIAL_FAMILY_REVISION_MISMATCH`,
`VIAL_BIND_REFERENCE_ERROR`, `VIAL_LIFECYCLE_DEADLINE_EXPIRED`,
`VIAL_LIFECYCLE_SERVICE_ERROR`, `VIAL_LIFECYCLE_DRAIN_INCOMPLETE`, and
`VIAL_LIFECYCLE_CLEANUP_TIMEOUT`. Version/style
and import/adapter errors stop before semantic construction; independent family
errors order by source, package, family-block, and node position. No failure
returns partial SemanticIR, migrated source catalog, plan, or artifact graph.

## Validation, nonclaims, and rollback

Implementation must prove unchanged v1 positive/negative bytes and projections;
normal-v2/terse-v2 equivalence; empty-intents v1 migration equivalence;
same-version import order; mixed/unknown version, adapter, family/revision,
shape, limit, and hostile backend-escape rejection; immutable defensive
records; deterministic diagnostics; no partial output; repository-relative
identities; public capability truth; and exact cleanup. Family syntax and
planning cannot ship until its vertical compiler owner passes; backend and
support claims require their own later qualification owners.

Implemented leaves `.19.1.2-.19.1.7` provide v2 source, semantic,
common-family contract, empty-base execution/plan, registry, backend-adapter
preflight, quality, public source/migration/plan tooling, and rejection
behavior. Lifecycle child `.19.2.2` adds the first closed family from source
through target-neutral planning and normalized-result validation.
V1 source, meaning, public capability bytes, successful plan/backend output,
support, and HIAL behavior remain unchanged. No other expressive family,
complete v2 verification result, family backend emission/runtime, parity,
provider, reverse
migration, mixed-version catalog, raw native block,
arbitrary SV/UVM/VHDL feature, mixed-language route, full-language claim,
scale claim, or support promotion ships. VIAL remains simpler intent above
qualified target mechanisms, not a renamed target API.

Selection rollback removes this v2 maintained reference, book, Knowledge Map,
task, and index links. Implementation rollback removes only private v2 routes
and v2 capability identities, restores this status to selected, and proves v1
bytes/behavior still equal. Neither rollback alters the v1 contract or any
HIAL source/lowering/backend path.
