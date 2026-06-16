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
