# SEMANTIC-INTROSPECTION-MCP-FRONTIER: Semantic Introspection And MCP Frontier

## Metadata

- Tree ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER`
- Status: `done`
- Roadmap lane: `Embedding And Public APIs / AI integration`
- Created: `2026-06-14`
- Last updated: `2026-06-16`
- Owner: repo-local workflow

## Goal

Make deep semantic introspection a first-class FSMGen feature: every meaningful
FSMGen semantic domain must become queryable through a clean, bounded API and
MCP must expose that API without leaking private implementation structures.

## Applied Direction From The RTL Simulator MCP Discussion

FSMGen can apply the same core principle: do not make the compiler/lowering
engine "MCP-first"; make it "stable semantic API first, MCP-exposed second."
For FSMGen, the analogs are:

- Simulator `compile/elaborate/run` maps to FSMGen `check`, `lower`, `emit
  semantic JSON`, `emit schedule JSON`, and `generate HDL`.
- Simulator hierarchy/driver/waveform queries map to FSMGen source identity,
  capability discovery, normalized semantic summaries, lowering-stage review
  artifacts, generated-artifact inventories, provenance, diagnostics, and
  support-accounting queries.
- Simulator waveform slices do not apply directly; FSMGen should expose
  structured semantic slices rather than large raw internal dumps.
- Simulator coverage-closure workflows map to FSMGen support-coverage and
  example-discovery workflows: find runnable examples, identify unsupported
  constructs, explain diagnostics, and select the nearest supported spelling.
- Simulator assertion/monitor generation maps to FSMGen verification-intent
  assistance: propose `.isf`/`.fsm` assertion or property forms, then let
  FSMGen check/generate exact diagnostics and HDL.
- Simulator regression triage maps to FSMGen corpus/check/semantic triage:
  classify parse, support-accounting, lowering, backend, and external
  validation failures.
- Simulator service API maps to a future long-lived or in-process FSMGen
  semantic service only if repeated fine-grained queries justify it. The first
  safe adapter may still drive existing stable CLI JSON surfaces.

## Existing Surfaces To Reuse

- `./bin/fsmgen --capability-manifest`
- `./bin/fsmgen --check --json`
- `./bin/fsmgen --emit-semantic-json`
- `./bin/fsmgen --emit-schedule-json` for `.isf` / `.ppif` lowering review
- generated `.isf` / `.fsm` / HDL artifact reporting
- support accounting and stable diagnostic-code registry
- normalized semantic contracts under `perl/FSM/Support/NormalizedSemantic*`
- embedding-facing manifest contracts under `perl/FSM/Support/*Contract.pm`
- mdBook examples and checked-in corpus entries as user-facing examples

## Non-Goals

- Do not implement MCP, service APIs, new CLI commands, new generated
  artifacts, or behavior-bearing API changes without activating an exact leaf.
- Do not expose raw Perl AST objects, raw private scheduler/lowering objects,
  raw `LoweringIR`, or unstable whole-hash payloads as public API.
- Do not add arbitrary shell access, unrestricted file writes, network access,
  or unbounded workspace traversal through any future MCP adapter.
- Do not make MCP define the semantic contract for IAL0, IAL1, or IAL2; MCP
  exposes the bounded public semantic-introspection API.
- Do not continue broad IAL2 feature-completeness work ahead of this lane
  while an exact semantic-introspection leaf is the active priority.

## Acceptance Criteria

- The first active selector inventories current machine-readable surfaces and
  selects a bounded semantic-introspection contract boundary before any
  implementation.
- Future implementation exposes MCP through the selected semantic API instead
  of through raw private compiler objects or ad hoc command text.
- Any future implementation leaf names exact resources, tools, prompts,
  schemas, safety policy, tests, docs, and rollback plan before source changes.
- Public docs and mdBook explain only shipped behavior; unshipped MCP adapter
  work stays clearly labeled as future until implemented.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER`
  Status: `done`
  Goal: `Track first-class semantic introspection and MCP query API work.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.1`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.2`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.3`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.4`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.5`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.6`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.7`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.8`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.9`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.10`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.11`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.12`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.13`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.14`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.15`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.16`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.17`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.18`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.19`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.20`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.21`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.22`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.23`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.24`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.25`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.26`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.27`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.28`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.29`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.30`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.1`
  Status: `done`
  Goal: `Create the proposed semantic-introspection/MCP owner and capture the FSMGen-specific scope mapping.`
  Acceptance: `The task-tree index, roadmap, and mdBook backlog point at this proposed owner; this tree records the applied lessons from the RTL-simulator MCP discussion and keeps future implementation behind a separate selector leaf.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.1: capture MCP introspection owner`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.2`
  Status: `done`
  Goal: `Select the first semantic-introspection API/MCP contract boundary.`
  Acceptance: `A selector reads the existing capability manifest, check JSON, normalized semantic JSON, schedule JSON, support accounting, diagnostic registry, embedding contracts, mdBook examples, roadmap, task tree, Memory, and Knowledge Map; it selects the first safe resource/tool/prompt subset or records a smaller prerequisite before any behavior-bearing implementation.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.2: activate first-class introspection`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.3`
  Status: `done`
  Goal: `Implement the first-class semantic-introspection contract manifest.`
  Acceptance: `Add a bounded manifest-advertised semantic-introspection contract that names query domains, query families, version/schema fields, contract sources, provenance/support-accounting expectations, read-only defaults, workspace restrictions, and MCP resource/tool mappings over existing capability, check JSON, normalized semantic JSON, schedule JSON, support-accounting, diagnostics, documentation/example, embedding, and backend-validation surfaces; do not expose raw private AST/scheduler/lowering objects or implement write/generation MCP tools; update tests, docs, mdBook, task tree, Memory, Knowledge Map, README, and roadmap; run focused contract/manifest checks plus standard continuity gates.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.3: ship introspection contract manifest`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.4`
  Status: `done`
  Goal: `Implement the first read-only MCP adapter over the semantic-introspection contract.`
  Acceptance: `Expose the manifest-selected read-only resource/tool families through a bounded local MCP adapter over the semantic_introspection contract; require explicit workspace-root/source identity handling for source-bound queries; do not enable write/generation tools, network access, arbitrary shell access, mutation workflows, commit/push actions, or raw private AST/scheduler/lowering/HDLGenerator payloads; add focused adapter tests plus manifest/docs/mdBook/Memory/Knowledge Map/task-tree/README/roadmap synchronization; run appropriate focused checks and continuity gates.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.4: ship read-only MCP adapter`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.5`
  Status: `done`
  Goal: `Harden MCP adapter protocol/client compatibility and source-query envelopes.`
  Acceptance: `Audit the shipped read-only JSON-RPC stdio adapter against MCP client expectations; add protocol fixture coverage for initialize, notifications, resource listing, resource templates, resource reads, tool listing, tool calls, error envelopes, source URI escaping, path sanitization, and source-query provenance; do not enable write/generation tools, network access, arbitrary shell access, mutation workflows, commit/push actions, or raw private payloads; sync manifest/docs/mdBook/Memory/Knowledge Map/task-tree/README/roadmap and run focused plus continuity gates.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.5: harden MCP protocol envelopes`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.6`
  Status: `done`
  Goal: `Deepen read-only diagnostic, example, and support-accounting MCP query coverage.`
  Acceptance: `Extend the read-only adapter with richer bounded query envelopes for diagnostic explanations, example discovery, and support-accounting summaries without exposing raw private objects or enabling writes; preserve workspace-root/source identity policy; update focused tests, manifest/docs/mdBook/Memory/Knowledge Map/task-tree/README/roadmap; run focused plus continuity gates.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.6: deepen MCP support queries`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.7`
  Status: `done`
  Goal: `Document read-only MCP client configuration and workflow examples.`
  Acceptance: `Add user-facing read-only MCP client configuration/workflow examples for capabilities, support summaries, diagnostics, examples, check JSON, semantic JSON, and schedule previews; keep examples bounded and non-mutating; sync README/mdBook/task tree/Memory/Knowledge Map/roadmap and run docs plus continuity gates.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.7: document MCP client workflows`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.8`
  Status: `done`
  Goal: `Add MCP adapter schema snapshot fixtures and client compatibility matrix.`
  Acceptance: `Add bounded schema/fixture snapshots for read-only resource/tool envelopes and a client compatibility matrix without enabling writes; sync docs/KM/Memory/task/roadmap; run focused/docs gates.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.8: add MCP schema snapshots`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.9`
  Status: `done`
  Goal: `Audit and select the official MCP stdio framing compatibility boundary.`
  Acceptance: `Audit the shipped line-delimited JSON-RPC stdio profile against official MCP 2025-06-18 stdio framing/session expectations; add a bounded framing guard or record a smaller exact prerequisite before behavior-bearing changes; sync docs/KM/Memory/task/roadmap and run focused/docs gates; do not enable writes, prompts, sampling, network, shell, mutation workflows, commit, or push tools.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.9: lock MCP stdio framing`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.10`
  Status: `done`
  Goal: `Select the MCP roots and workspace-root negotiation boundary.`
  Acceptance: `Audit the official MCP roots client feature against FSMGen's explicit --workspace-root and source identity policy; select whether the adapter should consume roots/list_changed or remain CLI-configured for this phase; do not allow unbounded workspace traversal or implicit source access; sync docs/KM/Memory/task/roadmap and run focused/docs gates.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.10: select MCP roots boundary`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.11`
  Status: `done`
  Goal: `Select read-only MCP prompt and workflow template boundaries.`
  Acceptance: `Audit whether read-only prompt/workflow templates for diagnostics, support discovery, examples, and semantic inspection should be advertised now or deferred; if selected, name exact prompt templates, inputs, safety policy, tests, and docs before implementation; do not enable writes, sampling, elicitation, network, shell, mutation workflows, commit, or push tools.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.11: defer MCP prompt templates`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.12`
  Status: `done`
  Goal: `Select MCP resource subscription and list-change boundaries.`
  Acceptance: `Audit whether resource subscribe/unsubscribe, resources/listChanged, and notifications/resources/list_changed should be advertised for the read-only semantic-introspection profile; either select exact behavior with tests/docs or keep static resources with listChanged false; do not enable writes, network, shell, mutation workflows, commit, or push tools.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.12: keep MCP resources static`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.13`
  Status: `done`
  Goal: `Select MCP completion API boundaries for resource and tool arguments.`
  Acceptance: `Audit whether completion/complete should be advertised for source paths, diagnostics, examples, sections, or resource templates; either select exact completion behavior with tests/docs or keep completion unsupported; do not enable filesystem traversal beyond configured workspace-root, writes, network, shell, mutation workflows, commit, or push tools.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.13: defer MCP completions`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.14`
  Status: `done`
  Goal: `Select MCP logging API boundaries for adapter diagnostics.`
  Acceptance: `Audit whether logging/setLevel and notifications/message should be advertised for adapter diagnostics; either select exact bounded logging behavior with tests/docs or keep logging unsupported; do not expose raw stderr, machine-local paths, writes, network, shell, mutation workflows, commit, or push tools.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.14: defer MCP logging`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.15`
  Status: `done`
  Goal: `Select MCP pagination boundaries for resource/tool listings.`
  Acceptance: `Audit whether resources/list, resources/templates/list, tools/list, prompts/list, and other list endpoints should support cursor pagination; either select exact pagination behavior with tests/docs or keep bounded unpaginated listings; do not enable unbounded payloads, writes, network, shell, mutation workflows, commit, or push tools.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.15: bound MCP pagination`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.16`
  Status: `done`
  Goal: `Select MCP sampling and elicitation boundaries for read-only semantic workflows.`
  Acceptance: `Audit whether sampling/createMessage and elicitation/create should be used or advertised for semantic-introspection workflows; either select exact bounded behavior with tests/docs or keep server-initiated model/user requests unsupported; do not enable model calls, user data collection, writes, network, shell, mutation workflows, commit, or push tools.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.16: defer MCP sampling elicitation`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.17`
  Status: `done`
  Goal: `Select MCP Streamable HTTP and service-mode transport boundaries.`
  Acceptance: `Audit whether Streamable HTTP transport, HTTP session behavior, or long-lived service mode should be advertised for the read-only semantic-introspection adapter; either select exact bounded behavior with tests/docs or keep one-shot/newline-delimited stdio as the only shipped transport; do not enable ambient network serving, writes, shell, mutation workflows, commit, or push tools.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.17: keep MCP transport local stdio`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.18`
  Status: `done`
  Goal: `Select MCP structured tool output boundaries.`
  Acceptance: `Audit whether read-only tool results should add MCP outputSchema and structuredContent alongside the existing JSON text content; either select exact bounded schemas/tests/docs or keep text-only JSON payloads for compatibility; do not expose raw private objects, writes, network, shell, mutation workflows, commit, or push tools.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.18: add MCP structured tool content`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.19`
  Status: `done`
  Goal: `Select MCP per-tool outputSchema boundaries.`
  Acceptance: `Audit which read-only MCP tool payloads have stable enough bounded schemas to advertise outputSchema; either select exact schemas with snapshot tests/docs or keep outputSchema deferred; do not overconstrain volatile support counts, full compiler reports, raw private objects, writes, network, shell, mutation workflows, commit, or push tools.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.19: add MCP output schemas`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.20`
  Status: `done`
  Goal: `Select MCP tool annotation and safety metadata boundaries.`
  Acceptance: `Audit whether read-only MCP tool descriptors should advertise annotations such as read-only or destructive/idempotent/open-world hints; either select exact stable annotations with tests/docs or keep annotations absent; do not imply write/generation authority, network access, shell access, mutation workflows, commit, or push tools.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.20: annotate MCP tool safety`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.21`
  Status: `done`
  Goal: `Select MCP content and resource annotation boundaries.`
  Acceptance: `Audit whether MCP content blocks, resource descriptors, or resource templates should advertise audience, priority, last-modified, or resource-link annotations; either select exact stable annotations with tests/docs or keep them absent; do not leak machine-local paths, imply subscriptions/list-change behavior, expose network/shell/write authority, or freeze volatile generated report details.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.21: defer MCP content annotations`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.22`
  Status: `done`
  Goal: `Select MCP progress and cancellation boundaries.`
  Acceptance: `Audit whether the read-only adapter should honor request progress tokens, emit notifications/progress, or handle notifications/cancelled beyond existing notification silence; either select exact bounded behavior with tests/docs or keep progress/cancellation unsupported/no-op for the one-shot profile; do not imply async jobs, service mode, mutation, network, shell, commit, or push authority.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.22: defer MCP progress cancellation`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.23`
  Status: `done`
  Goal: `Select JSON-RPC batch and request-envelope boundaries.`
  Acceptance: `Audit whether newline-delimited stdio and --request-json should accept JSON-RPC batch arrays or only single request objects; either select exact batch behavior with tests/docs or keep batch unsupported with explicit errors; do not add async fan-out, mutation, write/generation tools, network, shell, commit, or push authority.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.23: reject MCP batch envelopes`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.24`
  Status: `done`
  Goal: `Select MCP initialize protocol-version and capability negotiation boundaries.`
  Acceptance: `Audit whether initialize should echo the client protocol version, pin the server-supported MCP protocol version, or reject unsupported versions; ensure server capability advertisement remains minimal and exact; either select behavior with tests/docs or record the smaller prerequisite; do not enable unowned prompts, logging, completions, roots, sampling, elicitation, resources subscriptions, service mode, writes, network, shell, commit, or push tools.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.24: lock MCP initialize negotiation`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.25`
  Status: `done`
  Goal: `Select MCP error-data and sanitization boundaries.`
  Acceptance: `Audit whether JSON-RPC error responses should include structured data objects for invalid params, method-not-found, unsupported envelopes, or adapter failures; either select exact sanitized data fields with tests/docs or keep message-only errors; do not leak machine-local paths, raw Perl stack frames, raw private objects, command internals, network, shell, write/generation, commit, or push authority.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.25: keep MCP errors message-only`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.26`
  Status: `done`
  Goal: `Select MCP serverInfo and instructions metadata boundaries.`
  Acceptance: `Audit whether initialize serverInfo should add display title or richer metadata and whether instructions text should be expanded or kept compact; either select exact stable fields/text with tests/docs or keep the current minimal profile; do not introduce marketing copy, stale capability claims, unowned optional protocol features, machine-local paths, writes, network, shell, commit, or push authority.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.26: title MCP server info`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.27`
  Status: `done`
  Goal: `Audit remaining MCP read-only profile work and decide exhaustion or next expansion.`
  Acceptance: `Review the completed MCP adapter frontier against the selected read-only semantic-introspection profile, official MCP feature families already deferred or shipped, mdBook/user-facing docs, and roadmap priorities; either mark this hardening run exhausted with a return frontier or select one exact next leaf; do not make behavior-bearing code changes in this audit unless a smaller owned leaf is created first.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.27: exhaust MCP protocol hardening`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.28`
  Status: `done`
  Goal: `Select read-only source and workspace discovery boundaries.`
  Acceptance: `Audit whether the MCP adapter should expose bounded read-only source/workspace discovery for available repo/workspace inputs, examples, and supported file families; either select exact resources/tools/schemas/tests/docs or defer discovery; do not allow arbitrary filesystem traversal, hidden dotfile leakage, machine-local absolute path leakage, writes, network, shell, mutation, commit, or push authority.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.28: select MCP source discovery`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.29`
  Status: `done`
  Goal: `Implement catalog-backed read-only source discovery.`
  Acceptance: `Expose bounded source discovery through MCP using existing manifest, support-accounting, and example/catalog surfaces; return repo/workspace-relative source identities with file kind, source kind/support metadata when available, query/limit controls, and no hidden files, arbitrary recursive traversal, machine-local absolute paths, writes, network, shell, mutation, commit, or push authority; update tests, docs, mdBook, Knowledge Map, Memory, and roadmap; run focused plus continuity gates.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.29: add MCP source discovery`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.30`
  Status: `done`
  Goal: `Select the next post-source-discovery semantic-introspection frontier.`
  Acceptance: `Review the shipped read-only semantic-introspection surface after catalog-backed source discovery against roadmap priorities, mdBook coverage, Knowledge Map facts, and remaining active task-tree work; either select one exact next semantic-introspection leaf or return the active lane to the broader roadmap frontier; do not make behavior-bearing code changes in this audit unless a smaller owned leaf is created first.`
  Verification: `passed`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.30: return to IAL2 frontier`

## Implementation Notes From `.4`

- `.4` ships a repo-local read-only JSON-RPC stdio adapter:
  `bin/fsmgen-mcp`, backed by
  `FSM::Support::SemanticIntrospectionMCPAdapter`.
- Static resources read manifest-backed capabilities, contracts,
  diagnostics, support accounting, and examples.
- Source-bound resources/tools drive fixed repo-local `bin/fsmgen` argv for
  strict check JSON, normalized semantic JSON, and schedule JSON.
- Source identity is resolved under an explicit workspace root before any
  FSMGen invocation. Workspace escape attempts fail before the runner is
  called.
- Source-bound payloads normalize workspace/repo absolute paths to relative
  source identities and redact other absolute paths.
- Write/generation tools, network access, arbitrary shell access, mutation
  workflows, commit/push actions, service mode, and raw private object payloads
  remain blocked.

## Resolved Contract Questions From `.5`

- Which MCP clients should be fixture-modeled first, and which protocol
  behaviors can stay in the local JSON-RPC stdio harness until a real client
  integration leaf?
- Should the adapter add more explicit source-query provenance wrappers around
  check JSON, normalized semantic JSON, and schedule JSON without changing those
  underlying public report contracts?
- Which error families should remain adapter-local JSON-RPC errors and which
  should map to stable FSMGen diagnostic codes or unsupported-residue payloads?
- Does source URI escaping need stricter percent-encoding validation before any
  future client integration is considered signoff-ready?

## Implementation Notes From `.5`

- Invalid JSON-RPC versions and missing methods now return `-32600`.
- Unknown JSON-RPC methods now return `-32601`.
- Parse errors remain `-32700` and adapter call errors remain `-32000`.
- Id-less notifications remain silent.
- Malformed percent-encoded source URI segments fail explicitly before source
  resolution.
- Source-bound query payloads now include `adapter_provenance` with transport,
  read-only, no-shell, source-identity, workspace-root, and sanitized command
  shape policy.

## Candidate Contract Questions For `.6`

- Which diagnostic explanation fields need a richer read-only envelope before
  client integrations can rely on them?
- Should example discovery group by support-accounting family, coverage bucket,
  or source kind first?
- What is the smallest support-accounting summary that helps AI clients select
  nearest supported spellings without dumping the entire catalog by default?

## Implementation Notes From `.6`

- Added `support_summary` / `fsmgen_support_summary` to the manifest-advertised
  query/tool families.
- `fsmgen_support_summary` returns bounded support-accounting aggregates,
  ID-family counts, and optional sanitized catalog samples.
- `fsmgen_find_examples` now includes support-summary context without dumping
  catalog samples by default.
- `fsmgen_explain_diagnostic` now links stable diagnostic metadata to matching
  support-accounting examples.

## Candidate Contract Questions For `.7`

- Which MCP client configuration shape should the mdBook document first without
  depending on a specific proprietary client?
- Which read-only workflows should be shown as copy-paste JSON-RPC examples
  versus prose recipes?
- How much output should examples include without turning docs into large
  generated JSON dumps?

## Implementation Notes From `.7`

- README quick start now documents the generic read-only local MCP command:
  `perl /path/to/fsmgen/bin/fsmgen-mcp --workspace-root /path/to/workspace`.
- The mdBook embedding chapter now includes copy-paste bounded JSON-RPC
  examples for tool discovery, capability queries, support summaries, example
  discovery, diagnostic explanation, strict check JSON, normalized semantic
  JSON, and schedule previews.
- Source-bound examples use workspace-relative `source_path` values and
  document that responses carry relative source identity and
  `adapter_provenance` instead of leaking the configured workspace root.

## Candidate Contract Questions For `.8`

- Which resource/tool envelopes need stable snapshot fixtures before real
  client integration can be considered signoff-ready?
- Which client families should the first compatibility matrix name without
  depending on proprietary local configuration?
- How should fixture drift be reviewed so the adapter can evolve while keeping
  first-class semantic introspection predictable?

## Implementation Notes From `.8`

- Added `t/fixtures/semantic_introspection_mcp/read_only_schema_snapshot.json`
  as a bounded projection of read-only MCP initialization, resources,
  resource templates, tools, and tool-envelope shapes.
- Added `t/1445-semantic-introspection-mcp-schema-snapshots.t` to compare the
  live adapter against the fixture while asserting that no write, generation,
  shell, network, commit, or push tool is advertised.
- The mdBook now has a client compatibility matrix that distinguishes the
  shipped one-shot/newline-delimited MCP stdio profile from unclaimed
  Streamable HTTP, client roots consumption, prompts, sampling, completions, and
  service-mode session features.

## Candidate Contract Questions For `.9`

- Is the current line-delimited JSON-RPC stdio transport already aligned with
  the official MCP 2025-06-18 stdio transport?
- Which MCP session-lifecycle messages are required for real clients before
  prompts, sampling, or write tools are even considered?
- How should the adapter preserve the current read-only/path-sanitized policy
  if an additional framing layer is introduced?

## Implementation Notes From `.9`

- The official MCP 2025-06-18 transport specification defines stdio messages
  as newline-delimited JSON-RPC messages with no embedded newlines.
- The existing `run_stdio` path already emits compact newline-delimited
  JSON-RPC responses for stdio and stays silent for id-less notifications.
- Added `t/1446-semantic-introspection-mcp-stdio-framing.t` to guard
  one-message-per-line output, notification silence, parse-error framing, and
  non-leaking parse-error messages.
- The mdBook compatibility matrix no longer defers mythical Content-Length
  stdio framing; it marks MCP stdio as shipped and keeps Streamable HTTP,
  prompts, sampling, completions, client roots consumption, service mode, and write
  tools outside the shipped profile.

## Candidate Contract Questions For `.10`

- Should the adapter consume MCP client `roots` to derive workspace roots, or
  keep explicit `--workspace-root` as the only source of authority for now?
- How should root changes interact with already-open source identities and
  path-sanitized report payloads?
- What is the smallest client-visible roots contract that preserves fail-closed
  source access and does not broaden filesystem traversal?

## Implementation Notes From `.10`

- MCP roots are a client feature for exposing `file://` workspace boundaries to
  servers, but the shipped FSMGen adapter does not consume `roots/list` yet.
- Explicit `--workspace-root` remains the only authority for source-bound
  queries in this phase.
- Added `t/1447-semantic-introspection-mcp-roots-boundary.t` to prove client
  roots capabilities do not replace the configured workspace root, `roots/list`
  is not a server-side method, and source escapes are rejected before runner
  invocation.
- The mdBook compatibility matrix now has a dedicated roots row instead of
  implying roots negotiation is silently supported.

## Candidate Contract Questions For `.11`

- Which read-only prompt templates would add value without becoming a second,
  text-first semantic API?
- Should diagnostic triage, example discovery, and source semantic inspection
  remain tool-only until prompt schemas can be snapshot-tested?
- How should prompt templates avoid implying mutation, repair, generation, or
  sampling authority?

## Implementation Notes From `.11`

- MCP prompts are user-facing server-provided templates, not the structured
  semantic API itself.
- Prompt templates remain unadvertised in the shipped profile; clients should
  use resources/tools for semantic queries.
- Added `t/1448-semantic-introspection-mcp-prompts-boundary.t` to guard that
  the server does not advertise `prompts`, prompt-shaped tools are absent, and
  `prompts/list` / `prompts/get` return method-not-found until a prompt
  contract is separately selected.

## Candidate Contract Questions For `.12`

- Should static semantic-introspection resources continue advertising
  `listChanged => false`, or is there a bounded list-change notification
  contract worth shipping?
- Should resource subscribe/unsubscribe remain unsupported until there is a
  long-lived service mode or mutable resource state?
- What fixture coverage is needed before a client can rely on resource-list
  stability across sessions?

## Implementation Notes From `.12`

- The shipped resource list remains static: `initialize` reports
  `resources.listChanged` false and does not advertise `resources.subscribe`.
- Added `t/1449-semantic-introspection-mcp-resource-change-boundary.t` to guard
  static resource capability shape, non-paginated bounded listings, and
  unsupported `resources/subscribe` / `resources/unsubscribe` methods.
- The mdBook compatibility matrix now names resource subscriptions and
  list-change notifications as unadvertised in the shipped profile.

## Candidate Contract Questions For `.13`

- Which arguments would benefit from completion first: source paths,
  diagnostic codes, manifest sections, example queries, or resource-template
  variables?
- How can completion remain workspace-root-bounded and avoid unbounded
  filesystem traversal?
- Should completion stay unsupported until the adapter has a reusable bounded
  candidate-provider contract?

## Implementation Notes From `.13`

- MCP completion is an optional utility for prompt and resource-URI argument
  suggestions.
- Completion remains unsupported in the shipped profile until source-path,
  diagnostic-code, manifest-section, and example-query candidate providers are
  bounded and snapshot-tested.
- Added `t/1450-semantic-introspection-mcp-completion-boundary.t` to guard that
  the server does not advertise `completions` and that `completion/complete`
  returns method-not-found.

## Candidate Contract Questions For `.14`

- Should adapter diagnostics use MCP logging, or should errors remain pure
  JSON-RPC error envelopes and tool payloads for now?
- How can logging avoid leaking raw stderr, absolute paths, or private
  implementation details?
- Is there a useful log level contract before the adapter has a long-lived
  service mode?

## Implementation Notes From `.14`

- MCP logging remains unsupported in the shipped profile.
- Adapter diagnostics stay in JSON-RPC error envelopes, stable diagnostic
  payloads, and sanitized source-query provenance instead of
  `notifications/message`.
- Added `t/1451-semantic-introspection-mcp-logging-boundary.t` to guard that
  `logging` is not advertised and `logging/setLevel` returns method-not-found.

## Candidate Contract Questions For `.15`

- Are current resource/tool/template listings small enough to remain
  unpaginated with no `nextCursor`?
- Should pagination stay unsupported until dynamic resources, prompts, or
  larger catalogs make it necessary?
- Which list endpoints need snapshot coverage before cursor semantics can ship?

## Implementation Notes From `.15`

- The shipped resource, resource-template, and tool lists remain complete,
  bounded, and unpaginated.
- `resources/list`, `resources/templates/list`, and `tools/list` do not emit
  `nextCursor`.
- Client-supplied cursor params are rejected as JSON-RPC invalid params because
  the adapter has issued no cursor in this profile.
- `prompts/list` remains unsupported rather than becoming a hidden paginated
  prompt surface.
- Added `t/1452-semantic-introspection-mcp-pagination-boundary.t` to guard
  the bounded unpaginated list contract and invalid-cursor behavior.

## Candidate Contract Questions For `.16`

- Should the read-only adapter ever initiate `sampling/createMessage`, or should
  all AI reasoning remain with the MCP host/client using FSMGen's structured
  resources and tools?
- Should `elicitation/create` stay unsupported until FSMGen has an explicit
  user-input workflow contract that forbids sensitive data requests?
- What guards are required before any server-initiated model or user-interaction
  request can coexist with the no-write/no-network/no-shell policy?

## Implementation Notes From `.16`

- MCP sampling and elicitation remain unsupported in the shipped profile.
- Client-advertised `sampling` or `elicitation` capabilities do not widen the
  server capabilities returned by `initialize`.
- `sampling/createMessage` and `elicitation/create` remain unsupported server
  methods; FSMGen does not initiate model calls or user-input requests through
  MCP.
- Added
  `t/1453-semantic-introspection-mcp-sampling-elicitation-boundary.t` to guard
  the boundary.

## Candidate Contract Questions For `.17`

- Should the adapter keep one-shot and newline-delimited stdio as the only
  shipped transports until a real long-lived client profile requires
  Streamable HTTP?
- What session, lifecycle, and shutdown semantics would an HTTP/service-mode
  adapter need before it can be signoff-ready?
- How should a future transport preserve the current no-write, no-shell,
  no-network-beyond-listener, and workspace-root source authority policy?

## Implementation Notes From `.17`

- Streamable HTTP, listener flags, port flags, and service mode remain
  unshipped.
- `bin/fsmgen-mcp` exposes only one-shot `--request-json` and
  newline-delimited JSON-RPC stdio transports.
- Source-query provenance continues to identify the adapter transport as
  `jsonrpc_stdio`.
- Added `t/1454-semantic-introspection-mcp-transport-boundary.t` to guard the
  CLI/help surface, HTTP/service flag rejection, and stdio provenance.

## Candidate Contract Questions For `.18`

- Should each read-only MCP tool advertise an `outputSchema` and return
  `structuredContent`, or should the current JSON text payload remain the only
  tool result for compatibility?
- Which tool payloads already have stable bounded schema projections that can
  be exposed without dumping private compiler structures?
- How should schema snapshot fixtures review output-shape drift without pinning
  volatile support-corpus counts or full generated reports?

## Implementation Notes From `.18`

- Read-only MCP tool calls now return `structuredContent` containing the same
  bounded public JSON object serialized in the existing text content block.
- Existing text JSON content remains for backward-compatible MCP clients.
- Per-tool `outputSchema` metadata remains deferred until exact schemas are
  selected and snapshot-tested.
- Added `t/1455-semantic-introspection-mcp-structured-tool-output.t` and
  updated the schema snapshot fixture to guard response keys and text/structured
  payload agreement.

## Candidate Contract Questions For `.19`

- Which read-only tool payloads should advertise `outputSchema` first:
  capability queries, support summaries, diagnostic explanations, example
  discovery, source check JSON, semantic JSON, or schedule previews?
- Should source-bound tools expose compact envelope schemas only, leaving full
  compiler reports intentionally schema-light?
- How can output schemas improve client integration without freezing volatile
  support-accounting counts or private implementation details?

## Implementation Notes From `.19`

- Read-only MCP tool descriptors now advertise compact `outputSchema` metadata.
- Output schemas cover stable public envelope fields and intentionally leave
  nested compiler reports, support catalogs, and manifest payloads as
  schema-light objects or arrays.
- Updated `t/1455-semantic-introspection-mcp-structured-tool-output.t` and the
  schema snapshot fixture to guard output schema presence and stable projected
  fields.

## Candidate Contract Questions For `.20`

- Should read-only tools advertise MCP annotations to help clients distinguish
  non-mutating queries from future write/generation tools?
- Which annotations are stable enough to expose without implying mutation,
  network, shell, repair, commit, or push authority?
- How should annotations be snapshot-tested so future tool additions cannot
  accidentally widen safety expectations?

## Implementation Notes From `.20`

- Current MCP tool descriptors now advertise a narrow safety annotation set:
  `readOnlyHint: true` and `openWorldHint: false`.
- `destructiveHint` and `idempotentHint` remain absent because the official MCP
  schema defines those hints for non-read-only tools, and FSMGen ships no
  write/generation MCP tools in this profile.
- Updated the read-only schema snapshot projection and added
  `t/1456-semantic-introspection-mcp-tool-annotations-boundary.t` to guard the
  annotation surface and ensure tool annotations do not widen result authority.

## Candidate Contract Questions For `.21`

- Should MCP content blocks or resources advertise audience/priority
  annotations, or should annotations stay tool-descriptor-only for now?
- Are any last-modified annotations stable enough without introducing
  filesystem timestamp drift into the public contract?
- Should tool results return resource links for existing static resources, or
  would that duplicate the resource API without adding review value?

## Implementation Notes From `.21`

- Common MCP `Annotations` remain absent from resource descriptors, resource
  templates, resource-read content blocks, and tool-result text blocks.
- Tool results do not return `resource_link` content yet; clients should use
  the explicit `resources/list`, `resources/templates/list`, and
  `resources/read` API.
- Added
  `t/1457-semantic-introspection-mcp-content-resource-annotations-boundary.t`
  to guard the absence of audience/priority/lastModified annotations and tool
  result resource links.

## Candidate Contract Questions For `.22`

- Should one-shot requests with `_meta.progressToken` produce progress
  notifications, or is that only meaningful for a future service profile?
- Should `notifications/cancelled` be accepted as a silent notification, logged
  nowhere, or treated as unsupported because there is no long-running job
  registry?
- How can progress/cancellation behavior be tested without adding async
  background work or broadening transport/session authority?

## Implementation Notes From `.22`

- Request `_meta.progressToken` values do not emit `notifications/progress` in
  the shipped one-shot/stdin profile.
- Id-less `notifications/cancelled` messages remain silent notifications, and
  id-bearing `notifications/cancelled` requests are method-not-found because no
  job/session registry is shipped.
- Added
  `t/1458-semantic-introspection-mcp-progress-cancellation-boundary.t` to
  guard progress-token no-op behavior and cancellation notification handling.

## Candidate Contract Questions For `.23`

- Should `--request-json` reject JSON-RPC batch arrays as invalid requests or
  expand them into multiple responses?
- Should newline-delimited stdio continue to require exactly one compact JSON
  request object per line?
- What error shape should be stable for non-object envelopes without implying
  batch or async fan-out support?

## Implementation Notes From `.23`

- `handle_jsonrpc_request` now rejects batch arrays and other non-object
  request envelopes with `-32600 Invalid Request` instead of throwing through
  the one-shot CLI or reporting a parse error from stdio.
- Newline-delimited stdio remains one compact JSON-RPC request object per line;
  batch fan-out is not implemented.
- Added
  `t/1459-semantic-introspection-mcp-jsonrpc-batch-envelope-boundary.t` to
  guard direct adapter and stdio behavior for unsupported envelopes.

## Candidate Contract Questions For `.24`

- Should `initialize` continue echoing the client-provided protocol version or
  report the server's supported MCP protocol version explicitly?
- Should unsupported protocol versions be rejected now, or does that require a
  broader compatibility matrix first?
- Are advertised capabilities still minimal after the frontier work, and do
  tests prove unowned optional capability families remain absent?

## Implementation Notes From `.24`

- `initialize` now reports the single supported MCP protocol version
  `2025-06-18` and does not echo unsupported client protocol strings.
- Client-advertised roots, sampling, elicitation, and experimental
  capabilities do not widen the server's minimal advertised `resources` and
  `tools` capability map.
- Updated the schema snapshot fixture and added
  `t/1460-semantic-introspection-mcp-initialize-negotiation-boundary.t`.

## Candidate Contract Questions For `.25`

- Should JSON-RPC errors gain structured `error.data` payloads for client
  routing, or are stable messages enough for the shipped profile?
- Which error families can carry sanitized, stable data without exposing
  machine-local paths, Perl implementation details, or command internals?
- How should tests prove that any error data remains bounded and redacted?

## Implementation Notes From `.25`

- JSON-RPC errors remain message-only for the shipped profile: stable `code`
  and sanitized `message`, with no `error.data`.
- Error messages are guarded against machine-local repo-root leakage and Perl
  file/line suffixes.
- Added
  `t/1461-semantic-introspection-mcp-error-data-sanitization-boundary.t`.

## Candidate Contract Questions For `.26`

- Should `serverInfo` include a stable display `title`, or is `name`/`version`
  enough for the shipped profile?
- Should `instructions` become a more detailed client-facing contract summary,
  or remain compact to avoid duplicating the mdBook and manifest?
- How should tests prevent instructions from advertising unshipped optional
  protocol capabilities?

## Implementation Notes From `.26`

- Initialize `serverInfo` now includes stable title metadata:
  `FSMGen Semantic Introspection`.
- Instructions remain compact and read-only; the boundary test rejects
  blocked authority wording and unshipped optional MCP feature claims.
- Updated the schema snapshot fixture and added
  `t/1462-semantic-introspection-mcp-serverinfo-instructions-boundary.t`.

## Candidate Contract Questions For `.27`

- Has the immediate read-only MCP protocol hardening pass reached a natural
  stopping point?
- Should the next semantic-introspection work return to deeper query coverage,
  read-only source discovery, or another roadmap lane?
- Are any remaining MCP optional features important enough to select now
  without broadening authority or duplicating existing surfaces?

## Implementation Notes From `.27`

- The immediate MCP protocol-hardening pass is exhausted for the current
  read-only profile.
- Remaining optional MCP feature families are either shipped, explicitly
  unsupported/deferred in this task tree, or require future exact owners.
- The next useful semantic-introspection frontier moves from protocol mechanics
  to read-only source/workspace discovery.

## Candidate Contract Questions For `.28`

- Should source/workspace discovery use a resource, a tool, or both?
- Which directories and file suffixes are safe to scan without arbitrary
  traversal or hidden-file leakage?
- How should source discovery reuse existing support-accounting/example
  catalogs without inventing a second source registry?

## Implementation Notes From `.28`

- Source discovery is selected as catalog-backed, not filesystem-wide.
- `.29` should reuse existing manifest, support-accounting, and example/catalog
  surfaces and return bounded repo/workspace-relative source identities.
- Arbitrary recursive traversal, hidden-file exposure, machine-local absolute
  paths, writes, network, shell, mutation, commit, and push authority remain
  non-goals.

## Candidate Contract Questions For `.29`

- Which existing catalog entries should be included first: support-accounting
  examples, mdBook-documented examples, or all known `.fsm`/`.isf`/`.ppif`
  sample inputs?
- Should the first discovery surface be a tool only, a static resource only,
  or both?
- What stable output schema keeps discovery useful without freezing volatile
  support-accounting internals?

## Implementation Notes From `.29`

- Source discovery is now advertised through both `fsmgen://sources` and
  `fsmgen_discover_sources`.
- Discovery is backed by `support_accounting.catalog_entries` from the
  capability manifest; it does not scan the repository or workspace.
- Returned source identities are repo/workspace-relative `source_id` /
  `source_path` values with file kind, source kind, available read-only query
  kinds, and bounded support metadata.
- Query controls are `query`, `limit`, `file_kind`, `source_kind`, and
  `classification`.
- Catalog entries with absolute paths, dot segments, hidden path segments, or
  unsupported file kinds are filtered before response construction.

## Candidate Contract Questions For `.30`

- Should the semantic-introspection lane continue with deeper source-bound
  query coverage now that catalog discovery is shipped?
- Should the next exact owner return to the broader `IAL2` frontier instead of
  adding more MCP surface now?
- Are there any remaining user-facing docs or examples needed before another
  behavior-bearing semantic-introspection leaf is selected?

## Implementation Notes From `.30`

- The immediate read-only semantic-introspection/MCP pass is exhausted after
  catalog-backed source discovery.
- No additional semantic-introspection behavior-bearing leaf is selected now:
  the shipped capability manifest, resources, tools, mdBook coverage, README,
  roadmap, and Knowledge Map already describe the current public surface.
- Active roadmap priority returns to
  `IAL2-FEATURE-COMPLETENESS-FRONTIER.136`, the existing selector after
  generated runtime-validation multi-group queue-head scalar last-beat
  read-data.
- Future MCP or semantic-introspection expansion still requires a new exact
  task-tree leaf before any code, test, source, generated-artifact, or config
  change.

## Candidate Future Phases

- Phase 1: contract inventory and first safe semantic-introspection boundary.
- Phase 2: stable machine API wrapper over existing JSON surfaces.
- Phase 3: read-only MCP adapter for capabilities, diagnostics, semantic
  summaries, lowering previews, and examples.
- Phase 4: controlled generation tools with explicit workspace/output policy.
- Phase 5: AI workflows for diagnostic triage, support discovery, example
  matching, migration advice, and bug-report/reproducer packaging.

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `_none_` | `done` | `.30` closed the immediate semantic-introspection/MCP pass after catalog-backed source discovery; active roadmap priority returns to `IAL2-FEATURE-COMPLETENESS-FRONTIER.136`. |

## Decisions

- `2026-06-15`: User clarified that deep semantic introspection is a
  first-class FSMGen feature and everything meaningful in FSMGen must become
  queryable through MCP via a clean API. Activate this tree and make MCP a
  required adapter over the stable semantic-introspection API, not an optional
  someday integration.
- `2026-06-15`: `.2` selected `.3`, first-class semantic-introspection
  contract manifest. The first implementation must advertise query domains and
  MCP resource/tool mappings through a bounded contract over existing shipped
  machine-readable surfaces before any read-write tools or service mode.
- `2026-06-15`: `.3` shipped `semantic_introspection` as a top-level
  capability-manifest section. It advertises query domains, query families,
  versioning/provenance/safety policy, contract-surface owners, selected MCP
  resources/tools, `mcp_adapter_implemented: false`, and
  `write_generation_tools_enabled: false`.
- `2026-06-15`: `.4` shipped `bin/fsmgen-mcp`, a read-only local JSON-RPC
  stdio adapter over the manifest-selected resources/tools. The manifest now
  reports `mcp_adapter_implemented: true`, keeps
  `write_generation_tools_enabled: false`, and advertises source-bound path
  sanitization.
- `2026-06-16`: `.5` hardened the adapter with JSON-RPC protocol error codes,
  id-less notification silence, malformed percent-encoding rejection, and
  source-query `adapter_provenance` envelopes without enabling write/generation
  tools.
- `2026-06-16`: `.6` added `fsmgen_support_summary`, bounded
  support-accounting aggregates, support-aware example discovery, and
  diagnostic explanations linked to support-accounting examples.
- `2026-06-16`: `.7` documented generic read-only MCP client configuration and
  bounded one-shot workflows for capabilities, support summaries, diagnostics,
  examples, check JSON, semantic JSON, and schedule previews.
- `2026-06-16`: `.8` added bounded read-only MCP schema snapshot fixtures and a
  client compatibility matrix that does not claim Streamable HTTP, client roots
  consumption, prompts, sampling, completions, service mode, or write tools.
- `2026-06-16`: `.9` audited the official MCP 2025-06-18 stdio transport,
  locked newline-delimited JSON-RPC framing with no embedded newlines, and kept
  Streamable HTTP, client roots consumption, prompts, sampling, completions,
  service mode, and write tools outside the shipped profile.
- `2026-06-16`: `.10` selected explicit `--workspace-root` as the only shipped
  source authority; MCP client roots are not consumed yet, and source escapes
  remain fail-closed before runner invocation.
- `2026-06-16`: `.11` kept MCP prompt templates unadvertised until a separate
  prompt contract can be selected and snapshot-tested.
- `2026-06-16`: `.12` kept MCP resources static with `listChanged` false and
  subscription methods unsupported until a resource-change contract is
  separately selected.
- `2026-06-16`: `.13` kept `completion/complete` unsupported until bounded
  source, diagnostic, section, and example candidate providers are selected.
- `2026-06-16`: `.14` kept MCP logging unsupported; adapter diagnostics remain
  JSON-RPC errors and structured, sanitized payloads.
- `2026-06-16`: `.15` kept list responses bounded and unpaginated: no
  `nextCursor` is emitted, and unissued cursor params are invalid.
- `2026-06-16`: `.16` kept sampling and elicitation unsupported; FSMGen does
  not initiate model calls or user-input requests through MCP.
- `2026-06-16`: `.17` kept transport local to one-shot `--request-json` and
  newline-delimited stdio; Streamable HTTP and service mode remain unshipped.
- `2026-06-16`: `.18` added MCP `structuredContent` to read-only tool results
  while preserving serialized JSON text content; per-tool `outputSchema`
  remains deferred.
- `2026-06-16`: `.19` added compact `outputSchema` metadata for stable public
  tool-result envelope fields while keeping nested reports and catalogs
  schema-light.
- `2026-06-16`: `.20` added MCP tool annotations for the read-only profile:
  every current tool advertises `readOnlyHint: true` and `openWorldHint:
  false`; destructive/idempotent hints remain absent because no write tools are
  shipped.
- `2026-06-16`: `.21` kept common MCP annotations absent from resources,
  resource templates, resource-read content, and tool-result text blocks; tool
  results do not return resource links.
- `2026-06-16`: `.22` kept progress/cancellation session behavior unshipped:
  progress tokens emit no progress notifications, and cancelled notifications
  are silent unless incorrectly sent as id-bearing requests.
- `2026-06-16`: `.23` rejected JSON-RPC batch arrays and non-object request
  envelopes with explicit `-32600 Invalid Request` errors; batch fan-out is not
  shipped.
- `2026-06-16`: `.24` locked initialize negotiation to the supported
  `2025-06-18` protocol version and kept client capabilities from widening the
  server's advertised capability map.
- `2026-06-16`: `.25` kept JSON-RPC errors message-only with sanitized
  messages and no `error.data`.
- `2026-06-16`: `.26` added stable `serverInfo.title` metadata while keeping
  instructions compact, read-only, and free of unshipped feature claims.
- `2026-06-16`: `.27` exhausted the immediate MCP protocol-hardening pass and
  selected read-only source/workspace discovery as the next semantic frontier.
- `2026-06-16`: `.28` selected catalog-backed source discovery over existing
  manifest/support/example surfaces and routed implementation to `.29`.
- `2026-06-16`: `.29` shipped catalog-backed source discovery as
  `fsmgen://sources` and `fsmgen_discover_sources`, backed by the manifest
  support catalog rather than filesystem traversal, and routed the next
  selection audit to `.30`.
- `2026-06-16`: `.30` closed the immediate semantic-introspection/MCP pass
  after catalog-backed source discovery and returned active roadmap priority
  to `IAL2-FEATURE-COMPLETENESS-FRONTIER.136`.
- `2026-06-14`: Create this as a proposed owner, not an active implementation
  lane. The first real work must be no-code contract selection over existing
  public surfaces.
- `2026-06-14`: Keep MCP as an adapter over stable semantic APIs. The public
  contract remains the bounded FSMGen semantic/check/capability/lowering
  surfaces, consistent with backend-language-neutral IAL contracts.

## Open Questions

- None for the immediate semantic-introspection/MCP pass. Future expansion
  needs a new exact leaf; active roadmap priority is
  `IAL2-FEATURE-COMPLETENESS-FRONTIER.136`.

## Blockers

- None for ownership. Read-write MCP tools, generation/write tools, service
  mode, network access, arbitrary shell access, and mutation workflows remain
  blocked until future exact leaves select them.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-14` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.1` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check` | `passed`; Knowledge Map now has `177` facts and `1030` question keys |
| `2026-06-15` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.2` | Existing owner tree, roadmap, mdBook, Knowledge Map card, embedding and semantic-export contracts, README CLI/API documentation; sampled `env -u PERL5LIB ./bin/fsmgen --capability-manifest`, `env -u PERL5LIB ./bin/fsmgen --strict --check --json ppif/axi_aw_valid_ready.ppif`, `env -u PERL5LIB ./bin/fsmgen --strict --emit-semantic-json ppif/axi_aw_valid_ready.ppif`, and `env -u PERL5LIB ./bin/fsmgen --strict --emit-schedule-json ppif/axi_aw_valid_ready.ppif`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; README numbering check; active/proposed semantic-introspection frontier scans | `passed`; selected `.3`, first-class semantic-introspection contract manifest |
| `2026-06-15` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.3` | Syntax checks for `SemanticIntrospectionContract`, `SemanticIntrospectionSection`, `CapabilityManifest`, `CapabilityManifestContract`, and new tests; `prove -Iperl t/1438-semantic-introspection-contract.t t/1439-semantic-introspection-section-runtime-contract-audit.t t/1440-semantic-introspection-manifest-contract-roundtrip-audit.t t/369-manifest-section-builder-audit.t t/370-capability-manifest-section-discovery-audit.t t/897-capability-manifest-contract-public-keys-json-roundtrip-audit.t t/898-capability-manifest-contract-top-level-source-map-json-roundtrip-audit.t t/899-capability-manifest-contract-section-presence-map-json-roundtrip-audit.t t/900-capability-manifest-contract-presence-family-map-json-roundtrip-audit.t`; `./bin/fsmgen --capability-manifest` probe; broader manifest/continuity gates | `passed`; shipped top-level `semantic_introspection` manifest section and selected `.4` read-only MCP adapter |
| `2026-06-15` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.4` | Syntax checks for `SemanticIntrospectionMCPAdapter`, `bin/fsmgen-mcp`, semantic-introspection contract/section modules, `CapabilityManifestContract`, and new adapter tests; `prove -Iperl t/1438-semantic-introspection-contract.t t/1439-semantic-introspection-section-runtime-contract-audit.t t/1440-semantic-introspection-manifest-contract-roundtrip-audit.t t/1441-semantic-introspection-mcp-adapter.t t/1442-fsmgen-mcp-jsonrpc-cli.t`; live `bin/fsmgen-mcp` tools/list and sanitized semantic-query probes; broader manifest, mdBook, Knowledge Map, memory-architecture, README-numbering, and diff gates | `passed`; shipped read-only MCP adapter and selected `.5` hardening frontier |
| `2026-06-16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.5` | Syntax checks for `SemanticIntrospectionMCPAdapter` and `t/1443`; `prove -Iperl t/1438-semantic-introspection-contract.t t/1439-semantic-introspection-section-runtime-contract-audit.t t/1440-semantic-introspection-manifest-contract-roundtrip-audit.t t/1441-semantic-introspection-mcp-adapter.t t/1442-fsmgen-mcp-jsonrpc-cli.t t/1443-semantic-introspection-mcp-protocol-hardening.t`; mdBook, Knowledge Map, memory-architecture, README-numbering, and diff gates | `passed`; hardened protocol/client envelopes and selected `.6` deeper read-only query coverage |
| `2026-06-16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.6` | Syntax checks for `SemanticIntrospectionMCPAdapter`, `SemanticIntrospectionContract`, and `t/1444`; `prove -Iperl t/1438-semantic-introspection-contract.t t/1439-semantic-introspection-section-runtime-contract-audit.t t/1440-semantic-introspection-manifest-contract-roundtrip-audit.t t/1441-semantic-introspection-mcp-adapter.t t/1442-fsmgen-mcp-jsonrpc-cli.t t/1443-semantic-introspection-mcp-protocol-hardening.t t/1444-semantic-introspection-mcp-support-queries.t`; broader manifest, mdBook, Knowledge Map, memory-architecture, README-numbering, and diff gates | `passed`; added support summary and support-aware diagnostic/example queries; selected `.7` docs/workflow frontier |
| `2026-06-16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.7` | MCP one-shot examples for `tools/list`, `fsmgen_capability_query`, `fsmgen_support_summary`, `fsmgen_find_examples`, `fsmgen_explain_diagnostic`, `fsmgen_check`, `fsmgen_semantic_introspect`, and `fsmgen_schedule_preview`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `mdbook build docs/book`; `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; README numbering check | `passed`; documented read-only MCP client workflows and selected `.8` schema snapshot/client compatibility frontier |
| `2026-06-16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.8` | Syntax check for `t/1445`; `prove -Iperl t/1438-semantic-introspection-contract.t t/1441-semantic-introspection-mcp-adapter.t t/1442-fsmgen-mcp-jsonrpc-cli.t t/1443-semantic-introspection-mcp-protocol-hardening.t t/1444-semantic-introspection-mcp-support-queries.t t/1445-semantic-introspection-mcp-schema-snapshots.t`; mdBook, docs path audit, Knowledge Map generation/check, memory-architecture, README-numbering, and diff gates | `passed`; added read-only MCP schema snapshot fixture and client compatibility matrix; selected `.9` official MCP stdio framing compatibility boundary |
| `2026-06-16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.9` | Syntax check for `t/1446`; `prove -Iperl t/1441-semantic-introspection-mcp-adapter.t t/1442-fsmgen-mcp-jsonrpc-cli.t t/1443-semantic-introspection-mcp-protocol-hardening.t t/1445-semantic-introspection-mcp-schema-snapshots.t t/1446-semantic-introspection-mcp-stdio-framing.t`; mdBook, docs path audit, Knowledge Map generation/check, memory-architecture, README-numbering, and diff gates | `passed`; locked official newline-delimited MCP stdio framing and selected `.10` roots/workspace-root negotiation |
| `2026-06-16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.10` | Syntax check for `t/1447`; `prove -Iperl t/1441-semantic-introspection-mcp-adapter.t t/1443-semantic-introspection-mcp-protocol-hardening.t t/1446-semantic-introspection-mcp-stdio-framing.t t/1447-semantic-introspection-mcp-roots-boundary.t`; mdBook, docs path audit, Knowledge Map generation/check, memory-architecture, README-numbering, and diff gates | `passed`; selected explicit workspace-root authority and selected `.11` read-only prompt/workflow template boundary |
| `2026-06-16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.11` | Syntax check for `t/1448`; `prove -Iperl t/1441-semantic-introspection-mcp-adapter.t t/1443-semantic-introspection-mcp-protocol-hardening.t t/1448-semantic-introspection-mcp-prompts-boundary.t`; mdBook, docs path audit, Knowledge Map generation/check, memory-architecture, README-numbering, and diff gates | `passed`; kept prompt templates unadvertised and selected `.12` resource subscription/list-change boundary |
| `2026-06-16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.12` | Syntax check for `t/1449`; `prove -Iperl t/1441-semantic-introspection-mcp-adapter.t t/1443-semantic-introspection-mcp-protocol-hardening.t t/1449-semantic-introspection-mcp-resource-change-boundary.t`; mdBook, docs path audit, Knowledge Map generation/check, memory-architecture, README-numbering, and diff gates | `passed`; kept resources static and selected `.13` completion API boundary |
| `2026-06-16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.13` | Syntax check for `t/1450`; `prove -Iperl t/1441-semantic-introspection-mcp-adapter.t t/1443-semantic-introspection-mcp-protocol-hardening.t t/1450-semantic-introspection-mcp-completion-boundary.t`; mdBook, docs path audit, Knowledge Map generation/check, memory-architecture, README-numbering, and diff gates | `passed`; kept completion unsupported and selected `.14` logging API boundary |
| `2026-06-16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.14` | Syntax check for `t/1451`; `prove -Iperl t/1441-semantic-introspection-mcp-adapter.t t/1443-semantic-introspection-mcp-protocol-hardening.t t/1451-semantic-introspection-mcp-logging-boundary.t`; mdBook, docs path audit, Knowledge Map generation/check, memory-architecture, README-numbering, and diff gates | `passed`; kept logging unsupported and selected `.15` pagination boundary |
| `2026-06-16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.15` | Syntax checks for `SemanticIntrospectionMCPAdapter` and `t/1452`; `prove -Iperl t/1441-semantic-introspection-mcp-adapter.t t/1443-semantic-introspection-mcp-protocol-hardening.t t/1445-semantic-introspection-mcp-schema-snapshots.t t/1449-semantic-introspection-mcp-resource-change-boundary.t t/1452-semantic-introspection-mcp-pagination-boundary.t`; mdBook, docs path audit, Knowledge Map generation/check, memory-architecture, README-numbering, and diff gates | `passed`; kept list responses bounded/unpaginated and selected `.16` sampling/elicitation boundary |
| `2026-06-16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.16` | Syntax check for `t/1453`; `prove -Iperl t/1441-semantic-introspection-mcp-adapter.t t/1443-semantic-introspection-mcp-protocol-hardening.t t/1453-semantic-introspection-mcp-sampling-elicitation-boundary.t`; mdBook, docs path audit, Knowledge Map generation/check, memory-architecture, README-numbering, and diff gates | `passed`; kept sampling/elicitation unsupported and selected `.17` Streamable HTTP/service-mode transport boundary |
| `2026-06-16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.17` | Syntax check for `t/1454`; `prove -Iperl t/1442-fsmgen-mcp-jsonrpc-cli.t t/1446-semantic-introspection-mcp-stdio-framing.t t/1454-semantic-introspection-mcp-transport-boundary.t`; mdBook, docs path audit, Knowledge Map generation/check, memory-architecture, README-numbering, and diff gates | `passed`; kept transport local to one-shot/stdin and selected `.18` structured tool output boundary |
| `2026-06-16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.18` | Syntax checks for `SemanticIntrospectionMCPAdapter`, `t/1445`, and `t/1455`; `prove -Iperl t/1445-semantic-introspection-mcp-schema-snapshots.t t/1455-semantic-introspection-mcp-structured-tool-output.t`; mdBook, docs path audit, Knowledge Map generation/check, memory-architecture, README-numbering, and diff gates | `passed`; shipped structuredContent and selected `.19` outputSchema boundary |
| `2026-06-16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.19` | Syntax checks for `SemanticIntrospectionMCPAdapter`, `t/1445`, and `t/1455`; `prove -Iperl t/1445-semantic-introspection-mcp-schema-snapshots.t t/1455-semantic-introspection-mcp-structured-tool-output.t`; mdBook, docs path audit, Knowledge Map generation/check, memory-architecture, README-numbering, and diff gates | `passed`; shipped compact outputSchema metadata and selected `.20` tool annotation/safety metadata boundary |
| `2026-06-16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.20` | Syntax checks for `SemanticIntrospectionMCPAdapter`, `t/1445`, and `t/1456`; `prove -Iperl t/1445-semantic-introspection-mcp-schema-snapshots.t t/1456-semantic-introspection-mcp-tool-annotations-boundary.t`; mdBook, docs path audit, Knowledge Map generation/check, memory-architecture, README-numbering, and diff gates | `passed`; shipped read-only closed-world tool annotations and selected `.21` content/resource annotation boundary |
| `2026-06-16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.21` | Syntax check for `t/1457`; `prove -Iperl t/1457-semantic-introspection-mcp-content-resource-annotations-boundary.t`; mdBook, docs path audit, Knowledge Map generation/check, memory-architecture, README-numbering, and diff gates | `passed`; kept content/resource annotations absent and selected `.22` progress/cancellation boundary |
| `2026-06-16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.22` | Syntax check for `t/1458`; `prove -Iperl t/1458-semantic-introspection-mcp-progress-cancellation-boundary.t`; mdBook, docs path audit, Knowledge Map generation/check, memory-architecture, README-numbering, and diff gates | `passed`; kept progress/cancellation unshipped and selected `.23` JSON-RPC batch/envelope boundary |
| `2026-06-16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.23` | Syntax checks for `SemanticIntrospectionMCPAdapter` and `t/1459`; `prove -Iperl t/1443-semantic-introspection-mcp-protocol-hardening.t t/1446-semantic-introspection-mcp-stdio-framing.t t/1459-semantic-introspection-mcp-jsonrpc-batch-envelope-boundary.t`; mdBook, docs path audit, Knowledge Map generation/check, memory-architecture, README-numbering, and diff gates | `passed`; rejected JSON-RPC batch/non-object envelopes and selected `.24` initialize protocol/capability boundary |
| `2026-06-16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.24` | Syntax checks for `SemanticIntrospectionMCPAdapter`, `t/1441`, and `t/1460`; `prove -Iperl t/1441-semantic-introspection-mcp-adapter.t t/1445-semantic-introspection-mcp-schema-snapshots.t t/1460-semantic-introspection-mcp-initialize-negotiation-boundary.t`; mdBook, docs path audit, Knowledge Map generation/check, memory-architecture, README-numbering, and diff gates | `passed`; locked initialize negotiation and selected `.25` error-data/sanitization boundary |
| `2026-06-16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.25` | Syntax check for `t/1461`; `prove -Iperl t/1461-semantic-introspection-mcp-error-data-sanitization-boundary.t`; mdBook, docs path audit, Knowledge Map generation/check, memory-architecture, README-numbering, and diff gates | `passed`; kept errors message-only/sanitized and selected `.26` serverInfo/instructions boundary |
| `2026-06-16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.26` | Syntax checks for `SemanticIntrospectionMCPAdapter` and `t/1462`; `prove -Iperl t/1441-semantic-introspection-mcp-adapter.t t/1445-semantic-introspection-mcp-schema-snapshots.t t/1460-semantic-introspection-mcp-initialize-negotiation-boundary.t t/1462-semantic-introspection-mcp-serverinfo-instructions-boundary.t`; mdBook, docs path audit, Knowledge Map generation/check, memory-architecture, README-numbering, and diff gates | `passed`; added stable server title metadata and selected `.27` remaining-profile exhaustion audit |
| `2026-06-16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.27` | mdBook, docs path audit, Knowledge Map generation/check, memory-architecture, README-numbering, and diff gates | `passed`; exhausted immediate MCP protocol hardening and selected `.28` read-only source/workspace discovery |
| `2026-06-16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.28` | mdBook, docs path audit, Knowledge Map generation/check, memory-architecture, README-numbering, and diff gates | `passed`; selected catalog-backed source discovery and routed implementation to `.29` |
| `2026-06-16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.29` | Syntax checks for `SemanticIntrospectionContract`, `SemanticIntrospectionMCPAdapter`, and focused MCP tests; `prove -Iperl t/1441-semantic-introspection-mcp-adapter.t t/1444-semantic-introspection-mcp-support-queries.t t/1445-semantic-introspection-mcp-schema-snapshots.t t/1455-semantic-introspection-mcp-structured-tool-output.t t/1456-semantic-introspection-mcp-tool-annotations-boundary.t`; one-shot `fsmgen_discover_sources` probe; mdBook, docs path audit, Knowledge Map generation/check, memory-architecture, README-numbering, and diff gates | `passed`; shipped catalog-backed source discovery and routed next selection to `.30` |
| `2026-06-16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.30` | Roadmap, mdBook, Knowledge Map, README, `docs/TASK_TREE.md`, and active IAL2 `.136` task-tree audit; mdBook, docs path audit, Knowledge Map generation/check, memory-architecture, README-numbering, and diff gates | `passed`; closed the immediate semantic-introspection/MCP pass and returned active priority to IAL2 `.136` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.1` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.1: capture MCP introspection owner` | Proposed owner capture only; no implementation active. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.2` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.2: activate first-class introspection` | Activated semantic introspection as a first-class feature and selected `.3`, the contract-manifest implementation owner. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.3` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.3: ship introspection contract manifest` | Shipped the top-level `semantic_introspection` capability-manifest contract and selected `.4`, the read-only MCP adapter frontier. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.4` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.4: ship read-only MCP adapter` | Shipped `bin/fsmgen-mcp`, a read-only local JSON-RPC stdio adapter over the manifest-selected resources/tools, with workspace-root source binding and path sanitization. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.5` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.5: harden MCP protocol envelopes` | Hardened JSON-RPC protocol error handling, notification behavior, source URI percent-encoding validation, and source-query provenance envelopes. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.6` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.6: deepen MCP support queries` | Added support-summary, support-aware examples, and diagnostic-to-support-accounting query envelopes. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.7` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.7: document MCP client workflows` | Documented generic read-only MCP client configuration and bounded one-shot workflows for the shipped resource/tool families. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.8` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.8: add MCP schema snapshots` | Added bounded read-only MCP schema snapshot fixture/test and a client compatibility matrix. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.9` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.9: lock MCP stdio framing` | Locked official newline-delimited MCP stdio framing with a focused guard and corrected the compatibility matrix. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.10` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.10: select MCP roots boundary` | Selected explicit workspace-root authority for the shipped profile and deferred client roots consumption. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.11` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.11: defer MCP prompt templates` | Kept prompt templates unadvertised until a prompt contract is separately selected and snapshot-tested. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.12` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.12: keep MCP resources static` | Kept resource subscription/list-change features unadvertised for the shipped static resource profile. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.13` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.13: defer MCP completions` | Kept completion unsupported until bounded candidate providers are selected. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.14` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.14: defer MCP logging` | Kept MCP logging unsupported until a bounded log-message contract is selected. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.15` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.15: bound MCP pagination` | Kept list responses bounded and unpaginated, with unissued cursor params rejected as invalid. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.16` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.16: defer MCP sampling elicitation` | Kept sampling and elicitation unsupported for the read-only profile. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.17` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.17: keep MCP transport local stdio` | Kept Streamable HTTP and service mode unshipped; CLI remains one-shot/stdin only. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.18` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.18: add MCP structured tool content` | Added structuredContent to read-only MCP tool results while keeping serialized JSON text content. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.19` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.19: add MCP output schemas` | Added compact per-tool outputSchema metadata for stable public envelope fields. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.20` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.20: annotate MCP tool safety` | Added read-only closed-world MCP tool annotations for the shipped profile. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.21` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.21: defer MCP content annotations` | Kept common content/resource annotations and tool-result resource links absent for the shipped profile. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.22` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.22: defer MCP progress cancellation` | Kept progress notifications and cancellation session behavior unshipped for the one-shot/stdin profile. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.23` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.23: reject MCP batch envelopes` | Rejected batch arrays and non-object JSON-RPC envelopes with explicit invalid-request errors. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.24` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.24: lock MCP initialize negotiation` | Locked initialize to the supported protocol version and minimal server capabilities. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.25` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.25: keep MCP errors message-only` | Kept JSON-RPC errors message-only and sanitized, with no error.data. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.26` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.26: title MCP server info` | Added stable serverInfo title metadata and guarded compact read-only instructions. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.27` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.27: exhaust MCP protocol hardening` | Exhausted the immediate read-only MCP protocol-hardening pass. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.28` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.28: select MCP source discovery` | Selected catalog-backed source discovery and routed implementation to `.29`. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.29` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.29: add MCP source discovery` | Shipped catalog-backed `fsmgen://sources` and `fsmgen_discover_sources` over manifest support catalog entries. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.30` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.30: return to IAL2 frontier` | Closed the immediate semantic-introspection/MCP pass and returned active priority to IAL2 `.136`. |

## Changelog

- `2026-06-14`: Created proposed owner after the user raised MCP-backed AI
  automation for FSMGen and provided a related RTL-simulator MCP analysis.
- `2026-06-14`: Completed `.1`; task-tree index, roadmap, mdBook backlog, and
  Knowledge Map now capture the proposed owner and leave implementation behind
  selector `.2`.
- `2026-06-15`: Completed `.2`; deep semantic introspection is now an active
  first-class feature lane, MCP is a required adapter over the stable semantic
  API, and `.3` owns the first implementation boundary.
- `2026-06-15`: Completed `.3`; `semantic_introspection` is now a shipped
  top-level capability-manifest section with bounded query domains/families,
  selected read-only MCP mappings, explicit safety policy, and no write/generation
  tools.
- `2026-06-15`: Completed `.4`; `bin/fsmgen-mcp` now ships the first read-only
  local JSON-RPC stdio adapter over the `semantic_introspection` contract,
  backed by direct adapter and CLI tests, workspace-root source binding, and
  machine-local absolute path sanitization. `.5` owns protocol/client
  compatibility and source-query envelope hardening.
- `2026-06-16`: Completed `.5`; the adapter now has protocol-level JSON-RPC
  error codes, id-less notification silence, malformed percent-encoding
  rejection, and non-leaking source-query `adapter_provenance`. `.6` owns
  deeper read-only diagnostic/example/support-accounting query coverage.
- `2026-06-16`: Completed `.6`; the adapter now exposes
  `fsmgen_support_summary`, embeds support-summary context in example
  discovery, and links diagnostics to support-accounting examples. `.7` owns
  read-only MCP client configuration and workflow examples.
- `2026-06-16`: Completed `.7`; README and the mdBook now document generic
  read-only MCP client configuration plus bounded workflows for capabilities,
  support summaries, diagnostics, examples, check JSON, semantic JSON, and
  schedule previews, then selected `.8` for schema snapshot fixtures and a
  client compatibility matrix.
- `2026-06-16`: Completed `.8`; the read-only MCP profile now has a bounded
  schema snapshot fixture/test and the mdBook documents the first client
  compatibility matrix, then selected `.9` for official MCP stdio framing
  compatibility.
- `2026-06-16`: Completed `.9`; official MCP stdio is newline-delimited
  JSON-RPC, the adapter's stdio path now has explicit framing coverage, and
  then selected `.10` for roots/workspace-root negotiation.
- `2026-06-16`: Completed `.10`; explicit `--workspace-root` remains the only
  shipped source authority, client roots remain unconsumed, and `.11` selected
  the read-only prompt/workflow template boundary.
- `2026-06-16`: Completed `.11`; prompt templates remain unadvertised in the
  shipped profile, and `.12` selected resource subscription/list-change policy.
- `2026-06-16`: Completed `.12`; resources remain static with list-change and
  subscription features unadvertised, and `.13` selected completion API policy.
- `2026-06-16`: Completed `.13`; completion remains unsupported until bounded
  candidate providers are selected, and `.14` selected logging API policy.
- `2026-06-16`: Completed `.14`; MCP logging remains unsupported, and `.15`
  owns pagination selection.
- `2026-06-16`: Completed `.15`; list responses remain bounded and
  unpaginated, client cursors are invalid until a paginated profile is
  selected, and `.16` selected sampling/elicitation policy.
- `2026-06-16`: Completed `.16`; sampling and elicitation remain unsupported,
  and `.17` selected the Streamable HTTP/service-mode transport boundary.
- `2026-06-16`: Completed `.17`; Streamable HTTP and service mode remain
  unshipped, transport stays one-shot/stdin only, and `.18` selected
  structured MCP tool output.
- `2026-06-16`: Completed `.18`; read-only tool results now include
  `structuredContent` matching their serialized JSON text, and `.19` selected
  per-tool `outputSchema` metadata.
- `2026-06-16`: Completed `.19`; compact `outputSchema` metadata now covers
  stable public tool-result envelope fields, and `.20` owns tool
  annotation/safety metadata selection.
- `2026-06-16`: Completed `.20`; current MCP tools now advertise read-only
  closed-world annotations, and `.21` owns content/resource annotation
  selection.
- `2026-06-16`: Completed `.21`; resources, resource templates, resource-read
  content, and tool-result text remain unannotated, tools return no resource
  links, and `.22` owns progress/cancellation selection.
- `2026-06-16`: Completed `.22`; progress tokens are ignored by the shipped
  one-shot/stdin profile, cancelled notifications stay silent, and `.23` owns
  JSON-RPC batch/envelope selection.
- `2026-06-16`: Completed `.23`; batch arrays and non-object JSON-RPC
  envelopes now fail with explicit invalid-request errors, and `.24` owns
  initialize protocol/capability negotiation.
- `2026-06-16`: Completed `.24`; initialize now reports the supported MCP
  protocol version and minimal server capabilities, and `.25` owns
  error-data/sanitization selection.
- `2026-06-16`: Completed `.25`; JSON-RPC errors remain message-only and
  sanitized, and `.26` owns serverInfo/instructions metadata selection.
- `2026-06-16`: Completed `.26`; initialize serverInfo now has stable title
  metadata, instructions remain compact/read-only, and `.27` owns the
  remaining MCP profile exhaustion audit.
- `2026-06-16`: Completed `.27`; immediate MCP protocol hardening is
  exhausted, and `.28` owns read-only source/workspace discovery selection.
- `2026-06-16`: Completed `.28`; selected catalog-backed read-only source
  discovery and routed implementation to `.29`.
- `2026-06-16`: Completed `.29`; `fsmgen://sources` and
  `fsmgen_discover_sources` now expose catalog-backed source identity
  discovery with relative paths, file/source kind metadata, support metadata,
  and query/filter controls while keeping traversal, hidden paths, absolute
  paths, writes, network, shell, mutation, commit, and push authority blocked.
  It routed the final selection audit to `.30`.
- `2026-06-16`: Completed `.30`; the immediate read-only
  semantic-introspection/MCP pass is exhausted after catalog-backed source
  discovery, no new semantic behavior leaf is selected, and active roadmap
  priority returns to `IAL2-FEATURE-COMPLETENESS-FRONTIER.136`.
