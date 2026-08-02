---
id: nexsim-semantic-api-mcp-agent-consumer-requirements
title: NEXSIM has a versioned implementation-neutral agent-consumer API and MCP requirements baseline
answers:
  - "what should the NEXSIM semantic API let an engineering agent do?"
  - "what should NEXSIM expose through MCP?"
  - "is MCP or the NEXSIM native API the semantic authority?"
  - "does the NEXSIM agent-consumer document claim current implementation support?"
  - "how should NEXSIM report partial and unsupported capabilities?"
  - "what stable identity and snapshot guarantees does a NEXSIM client need?"
  - "how should NEXSIM explain why a simulated value or event occurred?"
  - "what UVM state should NEXSIM expose structurally?"
  - "what assertion coverage trace and replay support should NEXSIM expose?"
  - "how should NEXSIM authorize runtime mutation through API or MCP?"
  - "how should NEXSIM bound large semantic queries and streams?"
  - "what MCP tools and resources are recommended for NEXSIM?"
  - "what are the NEXSIM API delivery priorities and conformance levels?"
  - "how is the NEXSIM API MCP consumer contract amended?"
  - "where is the canonical NEXSIM agent-consumer requirements document?"
date: 2026-08-02
status: current
tags: [nexsim, semantic-api, mcp, agent, simulation, introspection, causality, replay, uvm, conformance]
evidence: >-
  docs/NEXSIM_API_MCP_AGENT_CONSUMER_REQUIREMENTS.md;
  docs/tasks/NEXSIM-SEMANTIC-API-MCP-CONSUMER-REQUIREMENTS.md;
  docs/book/src/16e-nexsim-api-mcp-consumer-requirements.md;
  docs/book/src/SUMMARY.md
reverify: >-
  rg -n 'Status: `consumer requirements baseline|NXAPI-ARCH-001|NXAPI-CAUSE-001|NXAPI-UVM-001|NXMCP-INIT-001|Priority 0|Level D: Qualify|Requested, accepted, implemented, and verified' docs/NEXSIM_API_MCP_AGENT_CONSUMER_REQUIREMENTS.md &&
  rg -n 'NEXSIM Semantic API and MCP Agent-Consumer Requirements|16e-nexsim-api-mcp-consumer-requirements' docs/book/src/SUMMARY.md docs/book/src/16e-nexsim-api-mcp-consumer-requirements.md &&
  scripts/check_task_tree_integrity.pl
---

The canonical consumer requirements baseline is
`docs/NEXSIM_API_MCP_AGENT_CONSUMER_REQUIREMENTS.md`. It describes the complete
observable API/MCP surface an expert engineering agent would like NEXSIM to
provide without prescribing NEXSIM internals or requiring knowledge of a
client's private architecture.

The native typed semantic API is the authority. MCP is a faithful, bounded,
secure projection for agent operability. The contract covers configuration,
build, elaboration, semantic graphs, exact runtime values, scheduler state,
causality, controlled execution, authorized mutation, checkpoints/replay, UVM,
assertions, coverage, traces, orchestration, comparison, reduction, security,
performance, error behavior, conformance, and schema evolution.

The document is a request, not evidence that NEXSIM implements any capability.
Capability negotiation must keep requested, accepted, implemented, and verified
states distinct. The owning task-tree keeps an explicit amendment leaf open so
future NEXSIM schemas, prototypes, evidence, and director feedback can update
the contract without rewriting history silently.
