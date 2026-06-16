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
date: 2026-06-15
status: current
tags: [mcp, ai, llm, semantic-json, embedding, public-api, task-tree]
evidence: docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; docs/SEMANTIC_INTROSPECTION_MCP_FIRST_CLASS_SELECTION.md; docs/TASK_TREE.md; ROADMAP_V2.md; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; perl/FSM/Support/SemanticIntrospectionContract.pm; perl/FSM/Support/SemanticIntrospectionSection.pm
reverify: env -u PERL5LIB ./bin/fsmgen --capability-manifest >/tmp/fsmgen_semantic_introspection_manifest.json && perl -MJSON::PP=decode_json -0777 -ne 'my $m=decode_json($_); die "missing semantic_introspection\n" unless $m->{semantic_introspection}; die "adapter unexpectedly enabled\n" if $m->{semantic_introspection}{mcp_adapter_implemented}; die "missing contract owner\n" unless ($m->{manifest_contract}{top_level_contract_source_map}{semantic_introspection}||"") eq "FSM::Support::SemanticIntrospectionContract"; print "semantic_introspection manifest ok\n";' /tmp/fsmgen_semantic_introspection_manifest.json
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

The next implementation leaf is `SEMANTIC-INTROSPECTION-MCP-FRONTIER.4`, the
first read-only MCP adapter over the shipped contract.

The selected first MCP resource families are `fsmgen://capabilities`,
`fsmgen://contracts`, `fsmgen://diagnostics`,
`fsmgen://support-accounting`, `fsmgen://examples`,
`fsmgen://source/{source_id}/check`,
`fsmgen://source/{source_id}/semantic`, and
`fsmgen://source/{source_id}/schedule`.

The selected first MCP tool families are `fsmgen_capability_query`,
`fsmgen_check`, `fsmgen_semantic_introspect`, `fsmgen_schedule_preview`,
`fsmgen_find_examples`, and `fsmgen_explain_diagnostic`.

The MCP adapter is not implemented yet: the manifest reports
`mcp_adapter_implemented: false` and `write_generation_tools_enabled: false`.
FSMGen should not expose raw private Perl AST, scheduler, lowering objects,
`HDLGenerator` compatibility hashes, or internal Perl references as public
automation APIs. Read/write generation tools, HDL writing, service mode,
network access, arbitrary filesystem traversal, mutation workflows, and
commit/push actions remain deferred until separately task-tree-owned.

The RTL-simulator MCP analogy maps to FSMGen as follows: compile/elaborate/run
maps to check/lower/semantic JSON/schedule JSON/generate HDL; hierarchy and
waveform queries map to structured semantic/lowering/provenance/diagnostic
queries; coverage closure maps to support-accounting and example-discovery
workflows; assertion assistance maps to proposing verification-intent source
that FSMGen then checks and lowers.
