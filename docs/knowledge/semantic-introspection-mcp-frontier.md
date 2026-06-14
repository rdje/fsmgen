---
id: semantic-introspection-mcp-frontier
title: Semantic introspection and MCP work is proposed behind a contract selector
answers:
  - "does FSMGen have an MCP task tree?"
  - "what owns semantic introspection for AI automation?"
  - "should FSMGen be MCP-first?"
  - "what can FSMGen apply from an RTL simulator MCP design?"
  - "what is the first MCP-related FSMGen task?"
date: 2026-06-14
status: current
tags: [mcp, ai, llm, semantic-json, embedding, public-api, task-tree]
evidence: docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; docs/TASK_TREE.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'SEMANTIC-INTROSPECTION-MCP-FRONTIER|Semantic Introspection And MCP|MCP adapter|semantic-introspection' docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md docs/TASK_TREE.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

FSMGen has a proposed owner for future AI/LLM automation:
`SEMANTIC-INTROSPECTION-MCP-FRONTIER`.

The selected direction is stable semantic API first, MCP adapter second.
FSMGen should not expose raw private Perl AST, scheduler, or lowering objects
as public automation APIs. The first future executable leaf is a no-code
selector that must inventory the existing capability manifest, check JSON,
normalized semantic JSON, schedule JSON, support accounting, stable
diagnostics, embedding contracts, mdBook examples, roadmap, task tree, Memory,
and Knowledge Map before any implementation.

The RTL-simulator MCP analogy maps to FSMGen as follows: compile/elaborate/run
maps to check/lower/semantic JSON/schedule JSON/generate HDL; hierarchy and
waveform queries map to structured semantic/lowering/provenance/diagnostic
queries; coverage closure maps to support-accounting and example-discovery
workflows; assertion assistance maps to proposing verification-intent source
that FSMGen then checks and lowers.
