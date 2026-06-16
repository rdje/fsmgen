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
date: 2026-06-16
status: current
tags: [mcp, ai, llm, semantic-json, embedding, public-api, task-tree]
evidence: docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; docs/SEMANTIC_INTROSPECTION_MCP_FIRST_CLASS_SELECTION.md; docs/TASK_TREE.md; ROADMAP_V2.md; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; perl/FSM/Support/SemanticIntrospectionContract.pm; perl/FSM/Support/SemanticIntrospectionSection.pm; perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm; bin/fsmgen-mcp; https://modelcontextprotocol.io/specification/2025-06-18/basic/transports; https://modelcontextprotocol.io/specification/2025-06-18/client/roots; https://modelcontextprotocol.io/specification/2025-06-18/server/prompts; https://modelcontextprotocol.io/specification/2025-06-18/server/resources
reverify: env -u PERL5LIB ./bin/fsmgen --capability-manifest >/tmp/fsmgen_semantic_introspection_manifest.json && perl -MJSON::PP=decode_json -0777 -ne 'my $m=decode_json($_); die "missing semantic_introspection\n" unless $m->{semantic_introspection}; die "adapter not enabled\n" unless $m->{semantic_introspection}{mcp_adapter_implemented}; die "write tools unexpectedly enabled\n" if $m->{semantic_introspection}{write_generation_tools_enabled}; die "missing adapter owner\n" unless ($m->{semantic_introspection}{contract_surface_map}{mcp_adapter}{contract_source}||"") eq "FSM::Support::SemanticIntrospectionMCPAdapter"; print "semantic_introspection manifest adapter ok\n";' /tmp/fsmgen_semantic_introspection_manifest.json && perl bin/fsmgen-mcp --request-json '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' >/tmp/fsmgen_mcp_tools.json && perl -MJSON::PP=decode_json -0777 -ne 'my $r=decode_json($_); my %t=map { $_->{name}=>1 } @{$r->{result}{tools}}; die "missing semantic tool\n" unless $t{fsmgen_semantic_introspect}; print "fsmgen-mcp tools ok\n";' /tmp/fsmgen_mcp_tools.json && prove -Iperl t/1445-semantic-introspection-mcp-schema-snapshots.t t/1446-semantic-introspection-mcp-stdio-framing.t t/1447-semantic-introspection-mcp-roots-boundary.t t/1448-semantic-introspection-mcp-prompts-boundary.t t/1449-semantic-introspection-mcp-resource-change-boundary.t
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
consumption, prompts, sampling, completions, service mode, and write tools are
future-owned work.
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
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.13`, MCP completion API boundary.
