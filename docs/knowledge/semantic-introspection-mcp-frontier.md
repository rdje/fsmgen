---
id: semantic-introspection-mcp-frontier
title: Deep semantic introspection is an active first-class FSMGen feature
answers:
  - "does FSMGen have an MCP task tree?"
  - "does VIAL semantic inspection expose lifecycle conditions and action bodies?"
  - "what owns semantic introspection for AI automation?"
  - "should FSMGen be MCP-first?"
  - "what can FSMGen apply from an RTL simulator MCP design?"
  - "what is the first MCP-related FSMGen task?"
  - "is deep semantic introspection a first-class FSMGen feature?"
  - "what is the next semantic introspection leaf?"
  - "which MCP resources are selected for FSMGen introspection?"
  - "which MCP tools are selected for FSMGen introspection?"
  - "where is FSMGen semantic introspection advertised?"
  - "is the FSMGen MCP adapter implemented?"
  - "how do I configure the FSMGen MCP adapter?"
  - "which read-only MCP workflow examples are documented?"
  - "where are FSMGen MCP schema snapshots?"
  - "which MCP client modes are compatible with FSMGen?"
  - "does FSMGen MCP stdio use Content-Length framing?"
  - "is FSMGen MCP stdio newline delimited?"
  - "does FSMGen consume MCP client roots?"
  - "what is the FSMGen MCP workspace-root authority?"
  - "does FSMGen advertise MCP prompts?"
  - "are FSMGen MCP prompt templates implemented?"
  - "does FSMGen support MCP resource subscriptions?"
  - "does FSMGen emit MCP resources/list_changed notifications?"
  - "does FSMGen support MCP completion/complete?"
  - "does FSMGen advertise MCP completions?"
  - "does FSMGen advertise MCP logging?"
  - "does FSMGen support MCP logging/setLevel?"
  - "does FSMGen support MCP pagination?"
  - "does FSMGen emit MCP nextCursor?"
  - "how does FSMGen handle MCP cursor params?"
  - "does FSMGen support MCP sampling/createMessage?"
  - "does FSMGen support MCP elicitation/create?"
  - "does FSMGen initiate MCP model calls or user-input requests?"
  - "does FSMGen support MCP Streamable HTTP?"
  - "does FSMGen MCP run as a service?"
  - "which MCP transports does FSMGen ship?"
  - "does FSMGen MCP return structuredContent?"
  - "does FSMGen MCP advertise tool outputSchema?"
  - "are FSMGen MCP tool results still available as text JSON?"
  - "which FSMGen MCP tool annotations are shipped?"
  - "does FSMGen MCP advertise readOnlyHint?"
  - "does FSMGen MCP advertise openWorldHint?"
  - "does FSMGen MCP advertise destructiveHint or idempotentHint?"
  - "does FSMGen MCP annotate resources or resource templates?"
  - "does FSMGen MCP annotate tool result content?"
  - "does FSMGen MCP return resource_link tool content?"
  - "does FSMGen MCP emit progress notifications?"
  - "how does FSMGen MCP handle progressToken?"
  - "does FSMGen MCP handle notifications/cancelled?"
  - "does FSMGen MCP support JSON-RPC batch requests?"
  - "how does FSMGen MCP handle non-object JSON-RPC envelopes?"
  - "which MCP protocol version does FSMGen initialize return?"
  - "does FSMGen MCP echo unsupported protocol versions?"
  - "can client capabilities widen FSMGen MCP server capabilities?"
  - "does FSMGen MCP return JSON-RPC error.data?"
  - "does MCP preserve failed source check and semantic diagnostics?"
  - "how are embedded absolute paths removed from MCP errors?"
  - "does MCP discover axi apb ahb protocol aliases?"
  - "where is the public source query applicability map?"
  - "are FSMGen MCP error messages sanitized?"
  - "what serverInfo title does FSMGen MCP expose?"
  - "what do FSMGen MCP initialize instructions advertise?"
  - "is the immediate FSMGen MCP protocol-hardening pass exhausted?"
  - "what is the next semantic-introspection frontier after MCP protocol hardening?"
  - "what source discovery boundary is selected for FSMGen MCP?"
  - "does FSMGen MCP expose catalog-backed source discovery?"
  - "which FSMGen MCP tool discovers source identities?"
  - "does FSMGen MCP source discovery scan the workspace?"
  - "is the immediate FSMGen MCP semantic-introspection pass complete?"
  - "what did SEMANTIC-INTROSPECTION-MCP-FRONTIER.30 select?"
  - "what is the active priority after FSMGen MCP source discovery?"
date: 2026-09-24
status: current
tags: [mcp, ai, llm, semantic-json, embedding, public-api, task-tree]
evidence: >-
  docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/SEMANTIC_INTROSPECTION_MCP_FIRST_CLASS_SELECTION.md; docs/TASK_TREE.md; ROADMAP_V2.md; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; perl/FSM/Support/SemanticIntrospectionContract.pm; perl/FSM/Support/SemanticIntrospectionSection.pm; perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm; bin/fsmgen-mcp; https://modelcontextprotocol.io/specification/2025-06-18/basic/lifecycle; https://modelcontextprotocol.io/specification/2025-06-18/basic/transports; https://modelcontextprotocol.io/specification/2025-06-18/client/roots; https://modelcontextprotocol.io/specification/2025-06-18/client/sampling;
  https://modelcontextprotocol.io/specification/2025-06-18/client/elicitation; https://modelcontextprotocol.io/specification/2025-06-18/server/prompts; https://modelcontextprotocol.io/specification/2025-06-18/server/resources; https://modelcontextprotocol.io/specification/2025-06-18/server/tools; https://modelcontextprotocol.io/specification/2025-06-18/schema; https://modelcontextprotocol.io/specification/2025-06-18/server/utilities/completion; https://modelcontextprotocol.io/specification/2025-06-18/server/utilities/logging; https://modelcontextprotocol.io/specification/2025-06-18/server/utilities/pagination
reverify: >-
  mkdir -p .artifacts/reverify && env -u PERL5LIB ./bin/fsmgen --capability-manifest >.artifacts/reverify/fsmgen_semantic_introspection_manifest.json && perl -MJSON::PP=decode_json -0777 -ne 'my $m=decode_json($_); die "missing semantic_introspection\n" unless $m->{semantic_introspection}; die "adapter not enabled\n" unless $m->{semantic_introspection}{mcp_adapter_implemented}; die "write tools unexpectedly enabled\n" if $m->{semantic_introspection}{write_generation_tools_enabled}; die "missing adapter owner\n" unless ($m->{semantic_introspection}{contract_surface_map}{mcp_adapter}{contract_source}||"") eq "FSM::Support::SemanticIntrospectionMCPAdapter"; my %tools=map { $_=>1 } @{$m->{semantic_introspection}{mcp_tool_names}}; die "missing source discovery tool\n" unless $tools{fsmgen_discover_sources}; my
  %resources=map { $_=>1 } @{$m->{semantic_introspection}{mcp_resource_uri_templates}}; die "missing source discovery resource\n" unless $resources{"fsmgen://sources"}; print "semantic_introspection manifest adapter ok\n";' .artifacts/reverify/fsmgen_semantic_introspection_manifest.json && perl bin/fsmgen-mcp --request-json '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' >.artifacts/reverify/fsmgen_mcp_tools.json && perl -MJSON::PP=decode_json -0777 -ne 'my $r=decode_json($_); my %t=map { $_->{name}=>1 } @{$r->{result}{tools}}; die "missing semantic tool\n" unless $t{fsmgen_semantic_introspect}; die "missing source discovery tool\n" unless $t{fsmgen_discover_sources}; die "unexpected cursor\n" if exists $r->{result}{nextCursor}; print "fsmgen-mcp tools ok\n";' .artifacts/reverify/fsmgen_mcp_tools.json &&
  perl bin/fsmgen-mcp --request-json '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"fsmgen_discover_sources","arguments":{"query":"axi_aw","file_kind":"ppif","limit":2}}}' >.artifacts/reverify/fsmgen_mcp_sources.json && perl -MJSON::PP=decode_json -0777 -ne 'my $r=decode_json($_); my $p=$r->{result}{structuredContent}; die "bad source discovery kind\n" unless ($p->{query_kind}||"") eq "source_discovery"; die "source discovery traversed workspace\n" if $p->{path_policy}{recursive_workspace_traversal}; die "source discovery returned no sources\n" unless @{$p->{sources}||[]}; print "fsmgen-mcp source discovery ok\n";' .artifacts/reverify/fsmgen_mcp_sources.json && prove -Iperl t/1444-semantic-introspection-mcp-support-queries.t t/1445-semantic-introspection-mcp-schema-snapshots.t
  t/1446-semantic-introspection-mcp-stdio-framing.t t/1447-semantic-introspection-mcp-roots-boundary.t t/1448-semantic-introspection-mcp-prompts-boundary.t t/1449-semantic-introspection-mcp-resource-change-boundary.t t/1450-semantic-introspection-mcp-completion-boundary.t t/1451-semantic-introspection-mcp-logging-boundary.t t/1452-semantic-introspection-mcp-pagination-boundary.t t/1453-semantic-introspection-mcp-sampling-elicitation-boundary.t t/1454-semantic-introspection-mcp-transport-boundary.t t/1455-semantic-introspection-mcp-structured-tool-output.t t/1456-semantic-introspection-mcp-tool-annotations-boundary.t t/1457-semantic-introspection-mcp-content-resource-annotations-boundary.t t/1458-semantic-introspection-mcp-progress-cancellation-boundary.t
  t/1459-semantic-introspection-mcp-jsonrpc-batch-envelope-boundary.t t/1460-semantic-introspection-mcp-initialize-negotiation-boundary.t t/1461-semantic-introspection-mcp-error-data-sanitization-boundary.t t/1462-semantic-introspection-mcp-serverinfo-instructions-boundary.t t/1882-semantic-introspection-mcp-vial-inspection.t t/1883-semantic-source-query-cohort.t
---

Owner: `docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md`. Earlier history:

```sh
git show 5a44ad496c852b168c31d4021cfdb158001a47c7:docs/knowledge/semantic-introspection-mcp-frontier.md
```

Product contract and client examples:
`docs/book/src/11-extensions-and-embedding.md`; schemas are in
`t/fixtures/semantic_introspection_mcp/read_only_schema_snapshot.json`.
`SemanticIntrospectionContract` and `SemanticIntrospectionSection` own the
manifest section; `SemanticIntrospectionMCPAdapter` implements `bin/fsmgen-mcp`.
Stable semantic API first, MCP adapter second remains the required design.
No private Perl AST, scheduler, lowering, or generator hashes are public APIs.

Discover current query families, tool/resource names and applicability through
`./bin/fsmgen --capability-manifest` and `tools/list`. Catalog-backed source
discovery never scans the workspace. Results retain relative identity and
public API provenance.

The current profile uses one-shot JSON-RPC or newline-delimited stdio with
MCP protocol `2025-06-18` (no Content-Length framing). Unsupported requested
versions do not widen that profile. `--workspace-root` is the source authority;
client roots are not consumed. Tools return text JSON and `structuredContent`
with compact output schemas, `readOnlyHint: true`, and `openWorldHint: false`.
Resources are static; list responses have no cursor. Prompts, completions,
subscriptions, logging, sampling, elicitation, progress/cancellation sessions,
Streamable HTTP and service mode remain unshipped. Batch/non-object envelopes
are invalid. JSON-RPC errors have code/message and no error.data.
Write/generation, arbitrary shell/network/filesystem access, mutation and
commit/push tools remain separately owned future work.

The 2026-09-24 audit found limits that earlier profile tests did not expose:

- `.31.2.3` exposes `.axi`, `.apb` and `.ahb` through catalog discovery.
  The exported `semantic_introspection_source_query_kinds()` and manifest
  `source_query_kinds` map own applicability; aliases share PPIF's check,
  semantic and schedule queries. T1869 compares all alias catalog records,
  native suffix coverage and actual native/MCP reports; availability does not
  promote a catalogued expected failure into support.
- `.31.2.4` exposes VIAL check/semantic reports through the bounded public
  filesystem API. Select tool `language_version` explicitly for v2, or use
  `fsmgen://vial/{language_version}/source/{source_id}/check|semantic`.
  Versioned capabilities use `vial_tooling_v1`/`vial_tooling_v2` query sections
  or `fsmgen://vial/{language_version}/capabilities`. Unversioned VIAL defaults
  to v1; hardware selectors and VIAL scheduling fail closed. T1871 qualifies
  native v1/v2/lifecycle/imported/invalid parity, original semantic paths,
  symlink authority, discovery and no publication.
- `.31.2.2` preserves native check/semantic v1 failure JSON on nonzero exit
  after matching public producer, mode and diagnostic shape. Tools return
  `isError: true` with text/structured reports; resources carry the same
  envelope. Unrelated/non-JSON failures stay message-only adapter errors;
  raw command/stderr/decoder excerpts are omitted. Embedded path tokens are
  sanitized and public error messages are bounded. T1868 compares complete
  actual successful/failed native reports and exercises malformed-output,
  error-path, comment/URI preservation and workspace controls.
- The native case-folded enable collision is repaired under `.31.2.1`: shared,
  deterministic assignment-enable allocation keeps original driver identity.
  The recorded actual CLI/MCP reports agree after source-path normalization;
  this bounded check does not establish parity for all other features.
- The APB sample completion/output-interface defect is repaired under
  `.31.2.5`: direct uppercase clears and removal of unused helper definitions
  preserve the declared ports. T1867 and assertion-enabled Verilator transfer
  checks guard behavior; native/MCP semantic results agree. An independent
  Icarus concat/packed `$onehot0` discrepancy is qualified under `.31.2.6`;
  its tracked probe/checker document the exact tool-context limit.

Durable capture and limits:
`docs/audits/mcp-feature-coverage-20260924/evidence.json` and the `.31.1` task
record. Reverify checks selected queries, not all-feature coverage. `.31.3` owns
coverage qualification and ongoing feature-signoff integration after repairs.

VIAL summaries omit action bodies and lifecycle nodes by design. Decision
`0105` and `docs/VIAL_SOURCE_INSPECTION_CONTRACT.md` select additive typed
inspection. `fsmgen_vial_inspect`, versioned `/inspection` and
`vial_inspection` capabilities now use the clean public API (T1882).
Summary queries remain summaries. T1883 qualifies the catalog-derived
`FSM::Test::SourceQueryCoverage` selector: complete ID/bucket allocation, explicit
VIAL versions, strict admission, closed mappings and deterministic focus.
Actual-query execution and exhaustive coverage remain subsequent work.

Current-feature query selection and its pilot are captured in
`docs/audits/mcp-feature-coverage-20260924/feature-coverage-selection.json`.
ISF storage fields and passive observations require schedule reports;
normalized hardware alone does not retain that source-only metadata.
