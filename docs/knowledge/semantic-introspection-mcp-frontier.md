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
  - "why do ISF width diagnostics name the authored source?"
  - "what blocks strict multi-clock ISF qualification?"
  - "how are embedded absolute paths removed from MCP errors?"
  - "does MCP discover axi apb ahb protocol aliases?"
  - "where is the public source query applicability map?"
  - "are FSMGen MCP error messages sanitized?"
  - "does MCP preserve quoted division operators in diagnostics?"
  - "why did large MCP reports exceed the RAM guard?"
  - "why did concatenation factorization change APB HDL across hash seeds?"
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
date: 2026-09-27
status: current
tags: [mcp, ai, llm, semantic-json, embedding, public-api, task-tree]
evidence: >-
  docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/SEMANTIC_INTROSPECTION_MCP_FIRST_CLASS_SELECTION.md; docs/TASK_TREE.md; ROADMAP_V2.md; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; perl/FSM/Support/SemanticIntrospectionContract.pm; perl/FSM/Support/SemanticIntrospectionSection.pm; perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm; bin/fsmgen-mcp; https://modelcontextprotocol.io/specification/2025-06-18/basic/lifecycle; https://modelcontextprotocol.io/specification/2025-06-18/basic/transports; https://modelcontextprotocol.io/specification/2025-06-18/client/roots; https://modelcontextprotocol.io/specification/2025-06-18/client/sampling;
  https://modelcontextprotocol.io/specification/2025-06-18/client/elicitation; https://modelcontextprotocol.io/specification/2025-06-18/server/prompts; https://modelcontextprotocol.io/specification/2025-06-18/server/resources; https://modelcontextprotocol.io/specification/2025-06-18/server/tools; https://modelcontextprotocol.io/specification/2025-06-18/schema; https://modelcontextprotocol.io/specification/2025-06-18/server/utilities/completion; https://modelcontextprotocol.io/specification/2025-06-18/server/utilities/logging; https://modelcontextprotocol.io/specification/2025-06-18/server/utilities/pagination
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl t/144*-semantic-introspection-mcp-*.t t/145*-semantic-introspection-mcp-*.t t/146*-semantic-introspection-mcp-*.t t/1868-semantic-introspection-mcp-source-failures.t t/1869-semantic-introspection-mcp-protocol-aliases.t t/1882-semantic-introspection-mcp-vial-inspection.t t/1883-semantic-source-query-cohort.t t/1884-semantic-source-query-runner.t t/1885-semantic-source-query-oracles.t t/1886-semantic-introspection-mcp-json-encoding.t t/1887-ast-factorization-structural-identity.t t/1889-authored-source-operand-diagnostics.t t/1890-isf-multiclock-strict-wiring.t t/1930-mcp-quoted-division-diagnostics.t
---

Owner: `docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md`. Earlier history: `git show 5a44ad496c852b168c31d4021cfdb158001a47c7:docs/knowledge/semantic-introspection-mcp-frontier.md`.

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

One-shot JSON-RPC and newline stdio use UTF-8 JSON with
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
  `.52` preserves quoted `/` tokens in singular-operator and operator-list
  diagnostics while retaining redaction for ordinary filesystem roots and
  longer paths. T1930 compares full native/API/newline failure and successful
  division reports, plus contextual path and message-only error controls.
- `.31.2.1` repairs case-folded enable collisions with deterministic allocation
  preserving driver identity. Actual CLI/MCP reports agree after normalization;
  this does not qualify unrelated features.
- `.31.2.5` repairs APB completion clears and unused helpers while preserving
  ports. T1867/Verilator guard behavior and native/MCP reports agree.
  `.31.2.6` separately qualifies the Icarus concat/packed `$onehot0` discrepancy
  with its tracked public probe and exact tool-context limit.

Durable capture and limits:
`docs/audits/mcp-feature-coverage-20260924/evidence.json` and the `.31.1` task
record. Reverify checks selected queries, not all-feature coverage. `.31.3` owns
coverage qualification and ongoing feature-signoff integration after repairs.

VIAL summaries omit action bodies and lifecycle nodes by design. Decision
`0105` and `docs/VIAL_SOURCE_INSPECTION_CONTRACT.md` select additive typed
inspection. `fsmgen_vial_inspect`, versioned `/inspection` and
`vial_inspection` capabilities now use the clean public API (T1882).
T1883 accounts sources/queries. T1884 compares actual native/API/newline reports;
T1885 adds authored storage, observation and VIAL oracles, shared-corruption and
failed-source controls. ISF/IAL2 report shapes stay distinct. CI partitions T1884;
public features require API/MCP signoff. Exhaustive qualification remains owned.
The full run exposed ASCII wire-encoding memory amplification.
UTF-8 wire encoding removes that mechanism and preserves complete values;
T1886 guards both CLI modes, Unicode identity and report/type equality.

Current-feature query selection and its pilot are captured in
`docs/audits/mcp-feature-coverage-20260924/feature-coverage-selection.json`.
ISF storage fields and passive observations require schedule reports;
normalized hardware alone does not retain that source-only metadata.

Complete qualification also exposed class-only structural matching in
`perl/FSM/HDL/ASTFactorization.pm`. The repair retains concatenation operands,
literal class/value/width/radix, signal slices and aggregate paths, skips
unsupported kinds and containing expressions, and sorts candidate allocation.
T1887 proves distinct-driver substitution, seed/order stability and independent
HDL behavior. The original APB module's differing driver was unused: an APB
output failure is not established by that reproducer. Native size fields remain
intact. Exact evidence is in
`docs/audits/mcp-feature-coverage-20260924/source-query-identity-repair.json`.

ISF/PPIF CLI failures map registered lowered sources to authored paths; direct/external child paths remain physical. T1889 checks clean width reasons, retained/domain artifacts and native/API/MCP equality; no line/column map.

T1890 qualifies canonical multi-clock wiring and all reset policies through native/API/MCP. ISF emission preserves explicit polarity; direct/domain behavior and exact controls are in docs/knowledge/explicit-system-reset-polarity.md. Broader activation qualification remains owned by .32.1.3.3.
