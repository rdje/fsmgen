# FSMGen First-Class Semantic Introspection And MCP Selection

Status: selected by `SEMANTIC-INTROSPECTION-MCP-FRONTIER.2` on 2026-06-15.

## Purpose

Deep semantic introspection is a first-class FSMGen feature. The end state is
that every meaningful FSMGen semantic domain is queryable through a clean,
bounded API and exposed through MCP without binding clients to private Perl
objects, raw ASTs, unstable whole hashes, or ad hoc command text.

The selected architecture is:

- stable semantic introspection API first;
- MCP as a required adapter over that API;
- read-only query resources before generation/write tools;
- explicit schemas, versioning, contract sources, source identity, diagnostics,
  support accounting, and provenance on every public query family.

## Evidence Read

The selector read the existing owner tree, roadmap, mdBook, Knowledge Map,
embedding contracts, semantic export contracts, README CLI/API documentation,
and sampled the existing machine-readable reports:

```bash
env -u PERL5LIB ./bin/fsmgen --capability-manifest
env -u PERL5LIB ./bin/fsmgen --strict --check --json ppif/axi_aw_valid_ready.ppif
env -u PERL5LIB ./bin/fsmgen --strict --emit-semantic-json ppif/axi_aw_valid_ready.ppif
env -u PERL5LIB ./bin/fsmgen --strict --emit-schedule-json ppif/axi_aw_valid_ready.ppif
```

The capability manifest already exposes bounded public sections for
`semantic_exports`, `diagnostics`, `embedding`, `support_accounting`,
`language_surface`, `documentation`, `backend_validation`, and `producer`, each
with contract ownership metadata.

The sampled public reports show the current queryable foundation:

- `--check --json`: top-level `check_schema_version`, `producer`, `command`,
  `source`, `success`, `diagnostics`, `diagnostic_summary`,
  `generated_output`, `result`, and `support_accounting`.
- `--emit-semantic-json`: top-level `normalized_semantic_schema_version`,
  `producer`, `command`, `source`, `success`, `diagnostics`,
  `diagnostic_summary`, `generated_output`, `generation_result_snapshot`,
  `semantic`, and `support_accounting`.
- `--emit-schedule-json`: top-level `schema`, `mode`, `source_object`,
  `target_channel`, `bindings`, `layering`, `generated_artifacts`,
  `generated_runtime_assertions`, `generated_scheduler_or_monitor_rules`,
  `enforced_static_rules`, `assumptions`, `transfer_fire_condition`, and
  `unsupported_residue`.

## Selected First Boundary

Select `SEMANTIC-INTROSPECTION-MCP-FRONTIER.3`, first-class semantic
introspection contract manifest.

That implementation leaf must introduce a stable, manifest-advertised
semantic-introspection contract before an MCP server or adapter is implemented.
The contract must define:

- query-domain names and descriptions for capability discovery, source
  identity, diagnostics, stable diagnostic codes, support accounting, normalized
  semantic JSON, schedule/lowering reports, generated-artifact inventories,
  documentation/examples, embedding contracts, and backend-validation status;
- public query family names, input parameters, output schema references,
  version fields, contract source names, and support-accounting/provenance
  expectations;
- an MCP resource/tool mapping that future adapter work must follow;
- read-only default behavior, explicit workspace-root restriction, no
  arbitrary shell access, no network access, and no implicit file writes;
- an explicit split between cached resource-style queries and tool-style
  per-source checks/introspection runs;
- the rule that raw private parser ASTs, scheduler objects, lowering objects,
  `HDLGenerator` compatibility hashes, and internal Perl references are never
  public semantic-introspection payloads.

The selected first MCP resource families are:

- `fsmgen://capabilities`
- `fsmgen://contracts`
- `fsmgen://diagnostics`
- `fsmgen://support-accounting`
- `fsmgen://examples`
- `fsmgen://source/{source_id}/check`
- `fsmgen://source/{source_id}/semantic`
- `fsmgen://source/{source_id}/schedule`

The selected first MCP tool families are:

- `fsmgen_capability_query`
- `fsmgen_check`
- `fsmgen_semantic_introspect`
- `fsmgen_schedule_preview`
- `fsmgen_find_examples`
- `fsmgen_explain_diagnostic`
- `fsmgen_support_summary`

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.3` should not implement the MCP adapter
itself unless the contract surface and tests remain small enough for a safe
single slice. If not, it must activate the next exact leaf for the read-only
MCP adapter.

## Implementation Result

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.3` shipped the selected contract as a
top-level `semantic_introspection` capability-manifest section. The manifest
now advertises query domains, query families, versioning/provenance/safety
policy, contract-surface ownership, selected MCP resource URI templates, and
selected MCP tool names.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.4` shipped the first read-only local
JSON-RPC stdio adapter over that contract as `bin/fsmgen-mcp`, backed by
`FSM::Support::SemanticIntrospectionMCPAdapter`. The manifest now reports
`mcp_adapter_implemented: true` and still reports
`write_generation_tools_enabled: false`. Static resources expose capabilities,
contracts, diagnostics, support accounting, and examples; source-bound tools
and resources require a workspace-root-contained source identity.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.5` hardened the shipped adapter's
protocol/client boundary. The adapter now returns protocol-level JSON-RPC
errors for invalid requests and unknown methods, ignores id-less
notifications, rejects malformed percent-encoded source URI segments, and
adds a non-leaking `adapter_provenance` envelope to source-bound query
responses.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.6` deepened the shipped read-only query
coverage. The adapter now exposes `fsmgen_support_summary`, returns bounded
support-accounting aggregates, includes a support summary in example
discovery results, and links stable diagnostic explanations to matching
support-accounting examples.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.7` documented generic read-only MCP
client configuration and bounded one-shot JSON-RPC workflows. The user-facing
examples cover capabilities, support summaries, diagnostics, examples, strict
check JSON, normalized semantic JSON, and schedule previews without enabling
write/generation tools or exposing the configured workspace root.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.8` added a bounded schema snapshot
fixture for the read-only adapter's initialization, resource, template, tool,
and tool-envelope shapes, guarded by
`t/1445-semantic-introspection-mcp-schema-snapshots.t`. The mdBook now
documents the first client compatibility matrix.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.9` audited the official MCP 2025-06-18
transport boundary and locked the current stdio profile as newline-delimited
JSON-RPC with no embedded newlines. One-shot JSON-RPC and MCP stdio are
shipped, while Streamable HTTP, prompts, sampling, completions, roots
negotiation, service mode, and write/generation tools are not claimed yet.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.10` selected the workspace-root boundary
for the shipped profile. MCP client roots remain unconsumed; the adapter uses
the explicit `--workspace-root` chosen at launch, keeps source identities
relative to that root, and rejects source escapes before invoking FSMGen.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.11` selected the prompt boundary for the
shipped profile. Prompt templates are not advertised yet; clients should use
the structured resource/tool API for semantic queries until a separate prompt
contract is selected and snapshot-tested.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.12` selected the resource-change boundary
for the shipped profile. Resources remain static: `listChanged` is false,
`subscribe` is not advertised, and resource subscribe/unsubscribe methods stay
unsupported until a separate resource-change contract is selected.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.13` selected the completion boundary for
the shipped profile. `completion/complete` remains unsupported until source,
diagnostic, section, and example candidate providers can be bounded and
snapshot-tested.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.14` selected the logging boundary for the
shipped profile. MCP logging is not advertised yet; adapter diagnostics remain
JSON-RPC errors and structured, sanitized payloads until a logging contract is
selected.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.15` selected the pagination boundary for
the shipped profile. Resource, resource-template, and tool list responses are
bounded and unpaginated: they emit no `nextCursor`, and client-supplied cursor
params are invalid because the adapter has issued no cursor.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.16` selected the sampling/elicitation
boundary for the shipped profile. FSMGen does not initiate
`sampling/createMessage` or `elicitation/create`; hosts should use the
structured resources and tools for semantic workflows.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.17` selected the transport boundary for
the shipped profile. `bin/fsmgen-mcp` exposes one-shot `--request-json` and
newline-delimited JSON-RPC stdio only; Streamable HTTP, listener flags, and
service-mode sessions remain unshipped.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.18` selected the first structured tool
output boundary. Read-only tool calls return MCP `structuredContent` matching
the serialized JSON text block; per-tool `outputSchema` metadata was left for
`.19`.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.19` selected the first `outputSchema`
boundary. Read-only tool descriptors advertise compact schemas for stable
public envelope fields, while volatile nested compiler reports, support
catalogs, and manifest payloads remain schema-light objects or arrays.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.20` selected the first MCP tool
annotation boundary. All shipped read-only tool descriptors advertise
`readOnlyHint: true` and `openWorldHint: false`. The adapter deliberately does
not set `destructiveHint` or `idempotentHint` on these read-only tools because
those hints are meaningful for non-read-only tools; write/generation tools
remain unshipped.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.21` selected the common content/resource
annotation boundary. The shipped profile keeps `Annotations` absent from
resources, resource templates, resource-read content blocks, and tool-result
text blocks. Tool results do not return `resource_link` content yet. Stable
audience, priority, last-modified, and resource-link contracts remain future
work.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.22` selected the progress/cancellation
boundary for the shipped profile. Request `_meta.progressToken` values do not
emit `notifications/progress`; id-less `notifications/cancelled` messages stay
silent, and id-bearing cancellation requests are unsupported because no async
job/session registry is shipped.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.23` selected the JSON-RPC batch/envelope
boundary. The adapter accepts one request object at a time. Batch arrays and
other non-object envelopes return `-32600 Invalid Request`; newline-delimited
stdio remains one compact request object per line.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.24` selected the initialize
protocol/capability boundary. The server reports the supported MCP protocol
version `2025-06-18` and does not echo unsupported client protocol strings.
Client capabilities cannot widen the advertised server capability map beyond
the shipped `resources` and `tools` capabilities.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.25` selected the error-data boundary.
JSON-RPC errors expose a stable `code` and sanitized `message` only.
`error.data` remains absent until a separate bounded schema can be selected
without leaking machine-local paths, Perl internals, command details, or raw
private objects.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.26` selected the serverInfo/instructions
boundary. Initialize now includes stable `serverInfo.title` metadata, while
instructions stay compact and read-only and do not advertise blocked authority
or unshipped optional MCP features.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.27` exhausted the immediate MCP protocol
hardening pass for the shipped read-only profile. The remaining optional MCP
feature families are either shipped, explicitly unsupported/deferred above, or
require future exact owners. The next selected direction is deeper read-only
source/workspace discovery for semantic-introspection queries.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.28` selected the source-discovery
implementation boundary. Discovery must be catalog-backed over existing
manifest, support-accounting, and example surfaces. It must not recursively
scan arbitrary workspace paths, expose hidden files, return machine-local
absolute paths, or introduce write/network/shell authority.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.29` shipped that boundary. The adapter now
advertises `fsmgen://sources` and `fsmgen_discover_sources`; both are backed by
`support_accounting.catalog_entries` from the capability manifest rather than
filesystem traversal. Results return repo/workspace-relative `source_id` /
`source_path` values, file kind, source kind, available read-only query kinds,
and bounded support metadata. Query controls include `query`, `limit`,
`file_kind`, `source_kind`, and `classification`. Hidden paths, dot segments,
absolute paths, unsupported file kinds, workspace scans, writes, network,
shell, mutation, commit, and push authority remain outside the shipped profile.

## Deferred

The following remain outside `.2` and `.3` unless separately selected:

- write generation tools exposed through MCP;
- HDL output-writing tools;
- long-lived service mode;
- network access;
- arbitrary filesystem traversal outside the repository/workspace root;
- raw AST or raw private object exposure;
- full schema freeze for every existing manifest/report field;
- mutation workflows, automated repairs, and commit/push actions.

## Validation Plan

The first implementation leaf must at minimum run:

- focused syntax checks for new/changed support modules and tests;
- capability-manifest checks proving the new semantic-introspection contract is
  advertised;
- JSON round-trip/defensive-copy tests for any new contract builder;
- focused CLI samples for `--capability-manifest`, `--check --json`,
  `--emit-semantic-json`, and `--emit-schedule-json`;
- mdBook, docs path audit, Knowledge Map generation/check, memory
  architecture, README numbering, frontier scans, and diff hygiene gates.
