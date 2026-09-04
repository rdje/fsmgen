# VIAL v2 source, schema, compatibility, import, and migration

Date: 2026-09-04
Owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.1`
Status: selected contract; base parser/projections implemented by `.19.1.2`

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
typed envelope through execution and results; `.19.1.4` owns the registry and
capability implementation; `.19.1.7` owns public migration/tooling exposure.

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
| private semantic record | `fsmgen.vial_semantic_ir.v2` / `schema_version: 2` | `.19.1.2-.19.1.3` |
| sanitized semantic report | `fsmgen.vial_semantic_report.v2` | `.19.1.2-.19.1.3` |
| format/reparse meaning | `fsmgen.vial_semantic_projection.v2` | `.19.1.2` |
| cross-version base meaning | `fsmgen.vial_compatibility_projection.v1` | `.19.1.2` |
| source diagnostic | `fsmgen.vial_diagnostic.v2` | `.19.1.2` |
| migration result | `fsmgen.vial_source_migration.v1` | `.19.1.7` |
| source capability | `vial.source.v2` | `.19.1.2` IR requirement; `.19.1.7` public discovery |
| semantic capability | `vial.semantic_ir.v2` | `.19.1.2` IR requirement; `.19.1.7` public discovery |
| base profile | `vial.profile.core_directed_single_clock_v2` | `.19.1.2-.19.1.3` |

The downstream identities selected for typed v2 data are
`fsmgen.vial_execution_ir.v2`, `fsmgen.vial_plan.v2`,
`fsmgen.verification_result_manifest.v2`,
`fsmgen.vial_parity_projection.v2`, `fsmgen.vial_parity_report.v2`, and
`fsmgen.vial_source_map.v2`. Public v2 tooling uses
`fsmgen.vial_tool_request.v2` and `fsmgen.vial_tool_result.v2`. Their exact
fields and implementation remain owned by `.19.1.3` and `.19.1.7`; naming them
here prevents a v1 schema from being silently widened. The unchanged HIAL
facts continue to use `fsmgen.hial_vial_bridge_manifest.v1`; a new bridge
version requires a real HIAL fact-shape change, not merely a v2 VIAL source.

## Implemented base-source boundary

Leaf `.19.1.2` implements the source-semantic foundation without advancing a
backend or public-tool schema. `FSM::VIAL::Parser` dispatches the connected
catalog by its root version. A separate version-2 builder validates the exact
seven-section envelope, rejects every non-empty family block because the
registry is still empty, and reuses the unchanged v1 semantic builder only for
the inherited base grammar. It then constructs a new immutable v2 record with
an empty typed `intent_families` collection and the authored `intents` span.

Normal-v2 and terse-v2 formatting preserve language version and reparse to one
`fsmgen.vial_semantic_projection.v2` digest. Empty-intents v2 and v1 also
produce one `fsmgen.vial_compatibility_projection.v1` digest. Same-version v2
catalog imports preserve root-then-depth-first authored order; v2-to-v1 imports,
reserved adapters, unknown versions, unknown families, backend-shaped forms,
and family bounds fail with closed v2 diagnostics. A v1-root catalog continues
through the legacy normalizer and retains its prior import diagnostics.

The existing public `fsmgen.vial_tool_request.v1` and version-1 plan builder
reject v2 rather than mislabeling it or passing it downstream. Public v2 tool
requests, CLI catalog loading, migration, expressive families, bridges, plans,
backends, runtime, results, parity, and support remain owned by later leaves.
The focused executable authority is `t/1801-vial-v2-source-projections.t`.

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
`.19.1.3` may add the already-owned common family envelope only by completing
the v2 schema before any expressive node is accepted; it cannot mutate v1.

The base v2 required capabilities are sorted and include
`vial.source.v2`, `vial.semantic_ir.v2`, and
`vial.profile.core_directed_single_clock_v2`. A registered family additionally
requires `vial.family.<family_id>.r<revision>.semantic`; later stage/backend
capabilities are distinct. Presence of source syntax never implies planning,
emission, compile, run, result, parity, methodology, scale, or support.

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
`VIAL_FAMILY_UNSUPPORTED`, and `VIAL_FAMILY_REVISION_MISMATCH`. Version/style
and import/adapter errors stop before semantic construction; independent family
errors order by source, package, family-block, and node position. No failure
returns partial SemanticIR, migrated source catalog, plan, or artifact graph.

## Validation, nonclaims, and rollback

Implementation must prove unchanged v1 positive/negative bytes and projections;
normal-v2/terse-v2 equivalence; empty-intents v1 migration equivalence;
same-version import order; mixed/unknown version, adapter, family/revision,
shape, limit, and hostile backend-escape rejection; immutable defensive
records; deterministic diagnostics; no partial output; repository-relative
identities; public capability truth; and exact cleanup. Family syntax cannot
ship until its own vertical source-to-qualified-result owner passes.

This selection changes no parser, source acceptance, semantic object, public
tool action, capability/support record, bridge, execution plan, artifact,
backend, compile, runtime, result, parity, provider, or HIAL behavior. It does
not implement any expressive family, adapter, reverse migration, mixed-version
catalog, raw native block, arbitrary SV/UVM/VHDL feature, mixed-language route,
full-language claim, scale claim, or support promotion. VIAL remains simpler
intent above qualified target mechanisms, not a renamed target API.

Selection rollback removes this v2 maintained reference and its registry,
book, Knowledge Map, task, and index links. Later implementation rollback must
remove only v2 routes and advertised v2 capabilities, restore this status to
selected, and prove v1 bytes/behavior still equal. Neither rollback alters the
v1 contract or any HIAL source/lowering/backend path.
