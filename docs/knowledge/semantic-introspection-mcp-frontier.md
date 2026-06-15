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
date: 2026-06-15
status: current
tags: [mcp, ai, llm, semantic-json, embedding, public-api, task-tree]
evidence: docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; docs/SEMANTIC_INTROSPECTION_MCP_FIRST_CLASS_SELECTION.md; docs/TASK_TREE.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'SEMANTIC-INTROSPECTION-MCP-FRONTIER|SEMANTIC_INTROSPECTION_MCP_FIRST_CLASS_SELECTION|Semantic Introspection And MCP|first-class semantic|semantic-introspection' docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md docs/SEMANTIC_INTROSPECTION_MCP_FIRST_CLASS_SELECTION.md docs/TASK_TREE.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

FSMGen has an active owner for first-class semantic introspection and future
MCP exposure:
`SEMANTIC-INTROSPECTION-MCP-FRONTIER`.

The selected direction is stable semantic-introspection API first and MCP as a
required adapter over that API. `.2` selected `.3`, the next implementation
leaf. `.3` must add a manifest-advertised semantic-introspection contract over
the existing capability manifest, check JSON, normalized semantic JSON,
schedule JSON, support accounting, diagnostics, documentation/example,
embedding, and backend-validation surfaces before any MCP adapter or write
tools.

The selected first MCP resource families are `fsmgen://capabilities`,
`fsmgen://contracts`, `fsmgen://diagnostics`,
`fsmgen://support-accounting`, `fsmgen://examples`,
`fsmgen://source/{source_id}/check`,
`fsmgen://source/{source_id}/semantic`, and
`fsmgen://source/{source_id}/schedule`.

The selected first MCP tool families are `fsmgen_capability_query`,
`fsmgen_check`, `fsmgen_semantic_introspect`, `fsmgen_schedule_preview`,
`fsmgen_find_examples`, and `fsmgen_explain_diagnostic`.

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
