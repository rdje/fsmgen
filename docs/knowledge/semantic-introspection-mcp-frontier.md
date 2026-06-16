---
id: semantic-introspection-mcp-frontier
title: Deep semantic introspection is an active first-class FSMGen feature
answers:
  - "does FSMGen have an MCP task tree?"
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
date: 2026-06-16
status: current
tags: [mcp, ai, llm, semantic-json, embedding, public-api, task-tree]
evidence: docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; docs/SEMANTIC_INTROSPECTION_MCP_FIRST_CLASS_SELECTION.md; docs/TASK_TREE.md; ROADMAP_V2.md; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; perl/FSM/Support/SemanticIntrospectionContract.pm; perl/FSM/Support/SemanticIntrospectionSection.pm; perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm; bin/fsmgen-mcp; https://modelcontextprotocol.io/specification/2025-06-18/basic/transports; https://modelcontextprotocol.io/specification/2025-06-18/client/roots; https://modelcontextprotocol.io/specification/2025-06-18/client/sampling; https://modelcontextprotocol.io/specification/2025-06-18/client/elicitation; https://modelcontextprotocol.io/specification/2025-06-18/server/prompts; https://modelcontextprotocol.io/specification/2025-06-18/server/resources; https://modelcontextprotocol.io/specification/2025-06-18/server/tools; https://modelcontextprotocol.io/specification/2025-06-18/schema; https://modelcontextprotocol.io/specification/2025-06-18/server/utilities/completion; https://modelcontextprotocol.io/specification/2025-06-18/server/utilities/logging; https://modelcontextprotocol.io/specification/2025-06-18/server/utilities/pagination
reverify: env -u PERL5LIB ./bin/fsmgen --capability-manifest >/tmp/fsmgen_semantic_introspection_manifest.json && perl -MJSON::PP=decode_json -0777 -ne 'my $m=decode_json($_); die "missing semantic_introspection\n" unless $m->{semantic_introspection}; die "adapter not enabled\n" unless $m->{semantic_introspection}{mcp_adapter_implemented}; die "write tools unexpectedly enabled\n" if $m->{semantic_introspection}{write_generation_tools_enabled}; die "missing adapter owner\n" unless ($m->{semantic_introspection}{contract_surface_map}{mcp_adapter}{contract_source}||"") eq "FSM::Support::SemanticIntrospectionMCPAdapter"; print "semantic_introspection manifest adapter ok\n";' /tmp/fsmgen_semantic_introspection_manifest.json && perl bin/fsmgen-mcp --request-json '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' >/tmp/fsmgen_mcp_tools.json && perl -MJSON::PP=decode_json -0777 -ne 'my $r=decode_json($_); my %t=map { $_->{name}=>1 } @{$r->{result}{tools}}; die "missing semantic tool\n" unless $t{fsmgen_semantic_introspect}; die "unexpected cursor\n" if exists $r->{result}{nextCursor}; print "fsmgen-mcp tools ok\n";' /tmp/fsmgen_mcp_tools.json && prove -Iperl t/1445-semantic-introspection-mcp-schema-snapshots.t t/1446-semantic-introspection-mcp-stdio-framing.t t/1447-semantic-introspection-mcp-roots-boundary.t t/1448-semantic-introspection-mcp-prompts-boundary.t t/1449-semantic-introspection-mcp-resource-change-boundary.t t/1450-semantic-introspection-mcp-completion-boundary.t t/1451-semantic-introspection-mcp-logging-boundary.t t/1452-semantic-introspection-mcp-pagination-boundary.t t/1453-semantic-introspection-mcp-sampling-elicitation-boundary.t t/1454-semantic-introspection-mcp-transport-boundary.t t/1455-semantic-introspection-mcp-structured-tool-output.t t/1456-semantic-introspection-mcp-tool-annotations-boundary.t t/1457-semantic-introspection-mcp-content-resource-annotations-boundary.t t/1458-semantic-introspection-mcp-progress-cancellation-boundary.t t/1459-semantic-introspection-mcp-jsonrpc-batch-envelope-boundary.t
---

FSMGen has an active owner for first-class semantic introspection and future
MCP exposure:
`SEMANTIC-INTROSPECTION-MCP-FRONTIER`.

The selected direction is stable semantic-introspection API first and MCP as a
required adapter over that API. `.3` shipped the first manifest-advertised
contract: `./bin/fsmgen --capability-manifest` now exposes a top-level
`semantic_introspection` section owned by
`FSM::Support::SemanticIntrospectionContract` and built by
`FSM::Support::SemanticIntrospectionSection`.

That section advertises query domains, query families, schema/version fields,
contract sources, provenance/support-accounting expectations, read-only
defaults, workspace restrictions, safety policy, and MCP resource/tool
mappings over the existing capability manifest, check JSON, normalized
semantic JSON, schedule JSON, support accounting, diagnostics,
documentation/example, embedding, and backend-validation surfaces.

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.4` shipped the first read-only local
JSON-RPC stdio adapter over the contract: `bin/fsmgen-mcp`, backed by
`FSM::Support::SemanticIntrospectionMCPAdapter`.

The shipped first MCP resource families are `fsmgen://capabilities`,
`fsmgen://contracts`, `fsmgen://diagnostics`,
`fsmgen://support-accounting`, `fsmgen://examples`,
`fsmgen://source/{source_id}/check`,
`fsmgen://source/{source_id}/semantic`, and
`fsmgen://source/{source_id}/schedule`.

The shipped first MCP tool families are `fsmgen_capability_query`,
`fsmgen_check`, `fsmgen_semantic_introspect`, `fsmgen_schedule_preview`,
`fsmgen_find_examples`, `fsmgen_explain_diagnostic`, and
`fsmgen_support_summary`.

The manifest reports `mcp_adapter_implemented: true` and
`write_generation_tools_enabled: false`. Source-bound adapter responses
normalize workspace/repo absolute paths to relative source identities and
redact other absolute paths. `.5` hardens protocol/client behavior with
JSON-RPC error-code policy, notification handling, malformed percent-encoding
rejection, and non-leaking source-query `adapter_provenance`.
`.6` adds bounded support-accounting summaries, support-aware example
discovery, and diagnostic explanations linked to support-accounting examples.
`.7` documents generic read-only client configuration with `perl
/path/to/fsmgen/bin/fsmgen-mcp --workspace-root /path/to/workspace` and
bounded one-shot JSON-RPC workflows for capabilities, support summaries,
diagnostics, examples, strict check JSON, normalized semantic JSON, and
schedule previews.
`.8` adds `t/fixtures/semantic_introspection_mcp/read_only_schema_snapshot.json`
and `t/1445-semantic-introspection-mcp-schema-snapshots.t` for bounded
read-only adapter envelope snapshots. The mdBook compatibility matrix claims
the one-shot JSON-RPC CLI and official MCP 2025-06-18 newline-delimited
JSON-RPC stdio profile. `.9` adds
`t/1446-semantic-introspection-mcp-stdio-framing.t` and records that MCP stdio
does not require Content-Length framing; Streamable HTTP, client roots
consumption, prompts, sampling, elicitation, completions, service mode, and
write tools are future-owned work.
`.10` selects explicit `--workspace-root` as the only shipped source authority:
the adapter does not consume MCP client roots yet, does not expose `roots` as a
server capability, treats client `roots/list` as unsupported, and rejects
source escapes before invoking FSMGen.
`.11` keeps MCP prompt templates unadvertised. Clients should use the
structured resources/tools for semantic queries until a separate prompt
contract is selected and snapshot-tested.
`.12` keeps resources static: `resources.listChanged` is false, `subscribe` is
not advertised, and `resources/subscribe` / `resources/unsubscribe` are
unsupported until a resource-change contract is selected.
`.13` keeps completion unsupported: the server does not advertise
`completions`, and `completion/complete` returns method-not-found until bounded
candidate providers are selected.
`.14` keeps MCP logging unsupported: the server does not advertise `logging`,
and `logging/setLevel` returns method-not-found until a bounded log-message
contract is selected.
`.15` keeps MCP list pagination unenabled for the shipped static profile:
resource, resource-template, and tool list responses are bounded and emit no
`nextCursor`, and client-supplied cursor params are invalid because the adapter
has issued no cursor.
`.16` keeps sampling and elicitation unsupported: FSMGen does not initiate
`sampling/createMessage` model calls or `elicitation/create` user-input
requests through MCP.
`.17` keeps transport local: `bin/fsmgen-mcp` ships one-shot `--request-json`
and newline-delimited JSON-RPC stdio only. Streamable HTTP, listener flags,
port flags, and service mode remain unshipped.
`.18` adds MCP `structuredContent` to read-only tool results. The existing
serialized JSON text content remains present for compatibility. `.19` adds
compact per-tool `outputSchema` metadata for stable public result-envelope
fields while keeping volatile nested compiler reports, support catalogs, and
manifest payloads schema-light.
`.20` adds MCP `ToolAnnotations` for the read-only profile: every shipped tool
advertises `readOnlyHint: true` and `openWorldHint: false`. `destructiveHint`
and `idempotentHint` remain absent because they are meaningful for
non-read-only tools, and FSMGen ships no write/generation MCP tools.
`.21` keeps common MCP `Annotations` absent from resources, resource
templates, resource-read content blocks, and tool-result text blocks. Tool
results do not return `resource_link` content; stable audience, priority,
last-modified, and resource-link contracts remain future work.
`.22` keeps progress/cancellation session behavior unshipped. Request
`_meta.progressToken` values do not emit `notifications/progress`; id-less
`notifications/cancelled` messages remain silent notifications, and
id-bearing cancellation requests are unsupported.
`.23` keeps JSON-RPC batch arrays and non-object request envelopes unsupported
with explicit `-32600 Invalid Request` errors. The stdio profile remains one
compact JSON-RPC request object per line.
FSMGen should not expose raw private Perl AST, scheduler, lowering objects,
`HDLGenerator` compatibility hashes, or internal Perl references as public
automation APIs. Write generation tools, HDL writing, service mode, network
access, arbitrary filesystem traversal, mutation workflows, and commit/push
actions remain deferred until separately task-tree-owned.

The RTL-simulator MCP analogy maps to FSMGen as follows: compile/elaborate/run
maps to check/lower/semantic JSON/schedule JSON/generate HDL; hierarchy and
waveform queries map to structured semantic/lowering/provenance/diagnostic
queries; coverage closure maps to support-accounting and example-discovery
workflows; assertion assistance maps to proposing verification-intent source
that FSMGen then checks and lowers.

The next semantic-introspection leaf is
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.24`, initialize protocol/capability
boundary.
