# SEMANTIC-INTROSPECTION-MCP-FRONTIER: Semantic Introspection And MCP Frontier

## Metadata

- Tree ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER`
- Status: `active`
- Roadmap lane: `Embedding And Public APIs / AI integration`
- Created: `2026-06-14`
- Last updated: `2026-10-01`
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
  Status: `active`
  Goal: `Track first-class semantic introspection and MCP query API work.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.4, SEMANTIC-INTROSPECTION-MCP-FRONTIER.5, SEMANTIC-INTROSPECTION-MCP-FRONTIER.6, SEMANTIC-INTROSPECTION-MCP-FRONTIER.7, SEMANTIC-INTROSPECTION-MCP-FRONTIER.8, SEMANTIC-INTROSPECTION-MCP-FRONTIER.9, SEMANTIC-INTROSPECTION-MCP-FRONTIER.10, SEMANTIC-INTROSPECTION-MCP-FRONTIER.11, SEMANTIC-INTROSPECTION-MCP-FRONTIER.12, SEMANTIC-INTROSPECTION-MCP-FRONTIER.13, SEMANTIC-INTROSPECTION-MCP-FRONTIER.14, SEMANTIC-INTROSPECTION-MCP-FRONTIER.15, SEMANTIC-INTROSPECTION-MCP-FRONTIER.16, SEMANTIC-INTROSPECTION-MCP-FRONTIER.17, SEMANTIC-INTROSPECTION-MCP-FRONTIER.18, SEMANTIC-INTROSPECTION-MCP-FRONTIER.19, SEMANTIC-INTROSPECTION-MCP-FRONTIER.20, SEMANTIC-INTROSPECTION-MCP-FRONTIER.21, SEMANTIC-INTROSPECTION-MCP-FRONTIER.22, SEMANTIC-INTROSPECTION-MCP-FRONTIER.23, SEMANTIC-INTROSPECTION-MCP-FRONTIER.24, SEMANTIC-INTROSPECTION-MCP-FRONTIER.25, SEMANTIC-INTROSPECTION-MCP-FRONTIER.26, SEMANTIC-INTROSPECTION-MCP-FRONTIER.27, SEMANTIC-INTROSPECTION-MCP-FRONTIER.28, SEMANTIC-INTROSPECTION-MCP-FRONTIER.29, SEMANTIC-INTROSPECTION-MCP-FRONTIER.30, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32, SEMANTIC-INTROSPECTION-MCP-FRONTIER.33, SEMANTIC-INTROSPECTION-MCP-FRONTIER.34, SEMANTIC-INTROSPECTION-MCP-FRONTIER.35, SEMANTIC-INTROSPECTION-MCP-FRONTIER.36, SEMANTIC-INTROSPECTION-MCP-FRONTIER.37, SEMANTIC-INTROSPECTION-MCP-FRONTIER.38, SEMANTIC-INTROSPECTION-MCP-FRONTIER.39, SEMANTIC-INTROSPECTION-MCP-FRONTIER.40, SEMANTIC-INTROSPECTION-MCP-FRONTIER.41, SEMANTIC-INTROSPECTION-MCP-FRONTIER.42, SEMANTIC-INTROSPECTION-MCP-FRONTIER.43, SEMANTIC-INTROSPECTION-MCP-FRONTIER.44, SEMANTIC-INTROSPECTION-MCP-FRONTIER.45, SEMANTIC-INTROSPECTION-MCP-FRONTIER.46, SEMANTIC-INTROSPECTION-MCP-FRONTIER.47, SEMANTIC-INTROSPECTION-MCP-FRONTIER.48, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49, SEMANTIC-INTROSPECTION-MCP-FRONTIER.50, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51, SEMANTIC-INTROSPECTION-MCP-FRONTIER.52, SEMANTIC-INTROSPECTION-MCP-FRONTIER.53, SEMANTIC-INTROSPECTION-MCP-FRONTIER.54, SEMANTIC-INTROSPECTION-MCP-FRONTIER.55, SEMANTIC-INTROSPECTION-MCP-FRONTIER.56, SEMANTIC-INTROSPECTION-MCP-FRONTIER.57, SEMANTIC-INTROSPECTION-MCP-FRONTIER.58, SEMANTIC-INTROSPECTION-MCP-FRONTIER.59, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60, SEMANTIC-INTROSPECTION-MCP-FRONTIER.61, SEMANTIC-INTROSPECTION-MCP-FRONTIER.62, SEMANTIC-INTROSPECTION-MCP-FRONTIER.63, SEMANTIC-INTROSPECTION-MCP-FRONTIER.64, SEMANTIC-INTROSPECTION-MCP-FRONTIER.65`

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

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31`
  Status: `active`
  Goal: `Keep latest product features queryable through the public semantic API and MCP.`
  Acceptance: `Audit current shipped feature families and repair missing public semantic or MCP exposure with bounded stable schemas, original diagnostic/support/provenance truth and direct/MCP parity. Provide usable external-agent queries and examples without claiming unsupported execution controls. Every actionable gap owns an implementation leaf; completion requires repairs and regression coverage, not only a findings list. Preserve the read-only default and separately proposed write horizon.`
  Verification: `Director activated latest-feature coverage on 2026-09-24 after clean 5a44ad496c852b168c31d4021cfdb158001a47c7. Complete coverage has not yet been established.`
  Commit: `pending`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.1`
  Status: `done`
  Goal: `Derive current feature-to-semantic-API/MCP coverage and select exact repairs.`
  Acceptance: `Use the Knowledge Map, current capability contracts, canonical book and recent feature owners to census applicable public source/semantic families. Trace native query producers and MCP resources/tools/discovery, reverify uncertain coverage with real bounded read-only requests, and compare structured results/diagnostics. Record supported, missing and intentionally inapplicable boundaries with evidence. Decompose every actionable gap into ordered repair leaves under .31.2 before ending this audit; do not call existing profile-only tests proof of latest feature coverage.`
  Verification: `The 2026-09-24 audit and tracked result projection below establish concrete native and adapter defects; child .31.2 owns their repairs. Full per-feature qualification remains .31.3, not claimed by this census.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.1: audit current semantic and MCP coverage`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2`
  Status: `done`
  Goal: `Implement current-feature semantic API and MCP coverage repairs.`
  Acceptance: `After .31.1, create exact child leaves naming affected public contracts, API producers, MCP mappings, actual feature fixtures, failure cases and book sections before source changes. Repair native semantic contracts first where needed and project them through MCP; preserve bounded JSON-safe results, diagnostics, workspace authority and read-only defaults. Commit each verified repair separately and leave no discovered defect merely parked.`
  Verification: `All audited repair children are complete: native enable identity, APB completion/interface, simulator qualification, structured MCP failures, protocol-alias discovery and bounded VIAL API/MCP exposure. Per-feature qualification remains .31.3 rather than being inferred from completed repairs.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.4.2: expose versioned VIAL inspection through MCP`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.4, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.5, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.6`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.1`
  Status: `done`
  Goal: `Resolve unexpected native/MCP ISF semantic differences at their original producer.`
  Acceptance: `Reproduce direct and MCP normalized semantics for isf/apb_requester.isf, distinguish path-derived metadata from seed/order or semantic differences, and root-cause every unexplained delta before accepting parity. Repair the owning public producer if defective; preserve authored meaning and source provenance. Use independent semantic comparisons and selected compiler regressions, then commit a precise native/API/MCP contract and evidence.`
  Verification: `--debug=3 trace proves clean_signal_name case-folds PENABLE and penable into the same generated family name. Per-LHS collision tracking cannot separate them; FactorizationSupport::_build_context_to_ast_map overwrites the duplicate lhs_enable:penable_0_en key in hash-dependent feed order. The trace shows the original done-phase AST replaced with the setup-phase AST; no legitimate equivalence or OR simplification is involved. Same source bytes produced either driver under independent native executions.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.1: preserve generated enable identity`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.2`
  Status: `done`
  Goal: `Preserve structured source-query failures and prevent MCP error path leakage.`
  Acceptance: `Decode valid public failure JSON independently of child exit status and expose original diagnostics without converting an expected compiler refusal into an opaque transport error. Keep invalid/non-JSON command failures distinct, bound and sanitize error messages including embedded absolute command paths, and preserve JSON-RPC codes/message-only error policy. Qualify actual catalogued invalid sources plus runner and workspace-escape controls; update public contracts, schemas, tests and book.`
  Verification: `Actual strict check of fsm/mipicsi2_txccore_ulp.fsm returns structured diagnostic JSON with exit 1; MCP discards it and embeds absolute repository/executable/source paths in error.message. _run_fsmgen_json previously tested process success before decoding stdout; handle_jsonrpc_request stripped only Perl location. T1868 now preserves actual native failure reports, rejects unrelated/non-JSON failures, sanitizes embedded paths and checks complete successful reports. See the acceptance evidence and repair receipt below.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.2: preserve structured MCP failure diagnostics`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.3`
  Status: `done`
  Goal: `Expose all supported protocol source aliases in MCP discovery and query metadata.`
  Acceptance: `Drive applicable source family/query mappings from an owned public contract, include catalogued .axi/.apb/.ahb aliases with accurate check/semantic/schedule support, and retain existing path/filter/limit/safety behavior. Compare discovery with current native support catalog and actual semantic queries; prevent a new supported family from being silently omitted. Sync native introspection metadata, MCP schemas and book.`
  Verification: `The baseline manifest contains .axi/.apb/.ahb catalog entries and actual native/MCP semantic calls succeed, while baseline discover_sources returns zero for each alias family. The old _source_file_kind accepted only fsm/isf/ppif. The native source_query_kinds contract now owns applicability; the adapter consumes it and T1869 qualifies full alias catalog discovery plus actual representative check/semantic/schedule parity.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.3: expose protocol aliases through MCP discovery`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.4`
  Status: `done`
  Goal: `Project current public VIAL semantic tooling through the native introspection contract and MCP.`
  Acceptance: `Select exact JSON-safe source query result/version contracts over the existing VIAL public API before implementation; expose applicable VIAL capabilities, source discovery, check and sanitized semantic reports with explicit v1/v2 selection and accurate query applicability. Preserve imported source catalogs, public diagnostics and workspace authority. Qualify actual v1/v2/invalid sources and direct/API/MCP parity; keep execution and mutation outside the existing read-only profile.`
  Verification: `Children .1 and .2 expose the bounded public filesystem API and versioned MCP reports/resources/capability discovery. T1870 and T1871 qualify source admission, complete native parity and no publication; frozen v1 metadata remains unchanged. Full feature-level census and future signoff guard remain .31.3.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.4.2: expose versioned VIAL inspection through MCP`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.4.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.4.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.4.1`
  Status: `done`
  Goal: `Expose a clean bounded filesystem VIAL source-check API before MCP routing.`
  Acceptance: `Select a closed caller-rooted source-file check interface returning the existing public VIAL tool result with explicit language version 1 or 2 and no printing, artifact generation or execution. Reuse the native public request/result producer and import semantics; keep paths relative, regular, non-symlink and on the caller-root volume. Root-cause and repair pre-validation unbounded filesystem reads/import accumulation in the existing CLI source-loading path, with bounded source/import/combined-size controls and independent boundary tests. Preserve valid CLI/API report identity and current diagnostics where applicable; qualify real v1/v2/imported/invalid inputs, workspace escape and no-write behavior. Update public contract, book, knowledge and evidence; do not replay historical native compiler producers.`
  Verification: `T1870 qualifies source admission, exact/excess bounds, v1/v2 native and imported portable API parity, structured diagnostics, closed invocation and no publication. The tracked vial-filesystem-repair.json receipt records the original limit-plus-one slurp and repaired pre-validation refusal. The nine-file selected band passes, including frozen v1 capability identity; the final expanded focused test also passes.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.4.1: expose bounded VIAL filesystem checks`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.4.2`
  Status: `done`
  Goal: `Project the qualified VIAL check and semantic report through MCP and discovery.`
  Acceptance: `Use the clean filesystem source API from .1 for VIAL check and semantic queries; preserve the complete existing public result and semantic_report instead of inventing hardware-report shape. Add explicit validated language-version selection, truthful provenance/applicability, source discovery, applicable versioned resource/tool schemas and public capability guidance. Preserve import authority and structured failure reports/tool flags, qualify actual v1/v2/invalid/imported sources against native/API results, and keep scheduling, planning, backend execution and mutation unadvertised. Update tests/snapshots/book/facts and commit before .31.3 coverage qualification.`
  Verification: `T1871 qualifies complete native/API/MCP reports for v1/v2/lifecycle/imported/invalid inputs, versioned capabilities/resources, source discovery, semantic paths, selector rejection and symlink/workspace authority. The selected fourteen-file band and final expanded focused tests pass; actual newline-stdio and book one-shot queries match native results. See the captured repair receipt and acceptance below.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.4.2: expose versioned VIAL inspection through MCP`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.5`
  Status: `done`
  Goal: `Repair the shipped APB requester completion-phase output targets.`
  Acceptance: `Use the public drive-body assignment contract to correct done_phase in isf/apb_requester.isf so completion clears PSEL/PENABLE, with a lowered-output and generated-behavior regression. Do not invent nested drive-call semantics. Keep the separate compiler collision fixture so repairing the example cannot hide that native defect; synchronize support evidence and book.`
  Verification: `Native lowering emits (<- (psel 0) <done_phase_start) and (<- (penable 0) <done_phase_start), while public outputs are uppercase PSEL/PENABLE. docs/isf-spec/02-interface-transactions.md defines body pairs as assignments, not nested drive calls. This source defect is independent of the generated-enable alias collision.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.5: clear APB completion outputs`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.6`
  Status: `done`
  Goal: `Resolve selector assertion errors exposed by APB behavior qualification.`
  Acceptance: `Root-cause actual generated selector assertion failures under the installed simulator, distinguishing real conflicting drivers, scheduling artifacts and tool behavior through bounded public HDL counterexamples. Preserve original failure logs, qualify a supported simulator and implement any compiler-owned repair with negative controls before accepting simulation success. If tool-owned, retain a minimal public-interface reproduction and an explicit integration boundary; do not mask errors or count a printed PASS as a clean simulation.`
  Verification: `During .31.2.5, Icarus behavior checks reach the final APB PASS but generated $onehot0 selector assertions repeatedly print ERROR, including apparently independent families. A standalone source with no FSMGen output reproduces concat=0 versus packed=1 for the same onehot value under installed Icarus 13.0; assertion-enabled Verilator 5.050 passes the APB behavior oracle. The tracked bounded probe/checker and receipt qualify Verilator and document the context-specific Icarus exclusion; no compiler change or universal simulator qualification is claimed.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.6: qualify selector assertion simulation`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3`
  Status: `active`
  Goal: `Qualify complete feature coverage and make API/MCP parity part of future feature signoff.`
  Acceptance: `After repair leaves pass, run representative actual native and MCP queries for every applicable current feature family with negative and schema/provenance controls. Keep advertised resources/tools/discovery and book examples aligned with real capability. Add a maintainable coverage guard or feature-acceptance contract so future language/verification features must verify semantic API and MCP support or explicitly justify an owned boundary. Keep mutation/service expansion in its separate proposed owner and resume bounded stream work after this activity is complete.`
  Verification: `Pending owned repairs.`
  Commit: `pending`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.1`
  Status: `done`
  Goal: `Define current feature-family coverage from canonical public contracts and select representative semantic queries.`
  Acceptance: `Census current public capability/support families and recent user-visible feature owners, distinguish source semantics from planning/runtime-only or internal workflow capabilities, and map each applicable family to exact native/API/MCP evidence or a concrete repair owner. Select truthful source/version/search-path expectations and independent feature observations before building the parity guard. Preserve original compiler/startup evidence and dependency black-box boundaries. Do not claim full feature coverage from suffix discovery or identical success flags.`
  Verification: `Canonical native corpus/capability census and ten actual native/MCP pilot queries are captured in feature-coverage-selection.json. Authored ISF field/observation identities are retained on schedule reports, and direct/composition/complex AXI semantic reports match completely after only repository-prefix normalization. The exhaustive source/query cohort and explicit VIAL versions are selected; ongoing guard and full qualification remain .2 and .3.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.1: select current-feature MCP qualification`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2`
  Status: `done`
  Goal: `Implement the selected current-feature parity guard and close coverage gaps.`
  Acceptance: `After .1 selects the population and observations, introduce a bounded maintainable guard that detects unaccounted public feature additions and tests actual native/MCP semantic parity with feature-specific assertions. Decompose every demonstrated gap into an exact repair leaf before code changes, commit repairs separately, and ensure new-feature acceptance requires API/MCP evidence or an explicit owned applicability boundary.`
  Verification: `Children qualify additive deep VIAL inspection and its semantic prerequisite repairs, live catalog/source/query accounting, actual native/API/newline parity with independent semantic/refusal controls, and closed CI partitions plus future-feature signoff. Existing summary contracts remain unchanged. Complete cohort execution remains .31.3.3 and is not inferred from focused qualification.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.2: integrate source-query coverage into CI`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.4, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.5, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.6, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.7`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.1`
  Status: `done`
  Goal: `Implement catalog-derived actual native/API/MCP source-query coverage and focused controls.`
  Acceptance: `Build a reusable test-side coverage selector over the native supported corpus and public query applicability map, retaining all contract IDs and deduplicating source work. Reject unknown query/source/version mappings and unaccounted VIAL fixtures. Execute actual public native and MCP producers, compare complete reports after only documented root normalization, and assert independent authored ISF and VIAL observations plus source/module provenance. Provide explicit focused selection and existing hosted corpus partition compatibility without calling a focused run exhaustive. Add fast malformed/new-family/missing-report controls, prove positive and known-bad outcomes, sync book/facts and commit before CI integration.`
  Verification: `Child commits qualify live catalog/query selection, actual native/API/newline report and provenance checks, authored feature witnesses, shared-corruption controls and representative full refusal reports. T1883-T1885 retain focused/list-only/source-partition boundaries. CI/signoff integration and full cohort execution remain .31.3.2.2 and .31.3.3; no focused run is called exhaustive.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.1.3: guard independent source-query semantics`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.1.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.1.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.1.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.1.1`
  Status: `done`
  Goal: `Derive a complete bounded source-query cohort from the supported public catalog.`
  Acceptance: `Implement reusable test-side selection retaining every supported catalog ID and coverage bucket while deduplicating source work. Join the public source-query applicability map, strict admission and source provenance; explicitly map VIAL language versions and reject unaccounted fixtures, unknown source/query kinds, conflicting duplicate metadata and malformed records. Provide deterministic focused selection and list-only data compatible with existing hosted partitioning, with independent complete-accounting and adversarial controls. Document precise selection boundaries and commit before executing the full query cohort.`
  Verification: `T1883 independently accounts for every supported catalog identity and its exact source/family/bucket allocation, proves explicit live VIAL version admission and source deduplication, deterministic defensive focus and complete/disjoint hosted partition compatibility. Unknown/missing mappings, malformed records, stale versions, conflicting metadata and unsafe paths fail. Focused catalog/manifest tests and runnable/rendered book pass; selection is not actual-query parity qualification.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.1.1: derive accounted source-query coverage cohorts`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.1.2`
  Status: `done`
  Goal: `Execute selected actual native/API/MCP source queries with complete report and provenance checks.`
  Acceptance: `Use the qualified selector and public native/API/MCP producers with explicit source/version/query mapping, documented root normalization only, complete report equality and no stub producer. Expose focused/list-only execution compatible with hosted source partitioning. Diagnose source/search-path/schema gaps through public interfaces and own any prerequisite repairs before widening coverage. Qualify representative direct, composition, ISF, protocol alias and VIAL sources without replaying spent runtime producers; exhaustive execution stays .31.3.3.`
  Verification: `T1884 executes actual native/public-adapter/newline queries plus explicit VIAL APIs, with complete report/text/structured equality, source/module/catalog/schema/provenance checks, exact root normalization and unchanged source/producer hashes. Focused execution and full producer-free list/partition controls pass. T1869's stale pre-inspection applicability expectation is corrected. Distinct ISF schedule and IAL2 protocol shapes are preserved. Independent semantics and exhaustive qualification remain subsequent leaves.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.1.2: execute actual source-query parity checks`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.1.3`
  Status: `done`
  Goal: `Guard independent feature semantics and representative failed source reports across adapters.`
  Acceptance: `Add authored ISF storage/observation, hardware source/module and VIAL base/lifecycle assertions to the selected query runner, with falsification that catches missing/wrong detail even when compared transports agree. Qualify representative structured failures, missing reports, unknown future families and schema/provenance mismatches. Retain exact focused evidence and update book/facts; leave complete corpus execution and CI/signoff integration to their explicit owners.`
  Verification: `T1885 qualifies independent ISF storage/observation, hardware identity and VIAL base/lifecycle witnesses against actual public producers. Identical in-memory transport corruption fails the independent oracles for lost/wrong detail, scalar types, schema/provenance and future families/revisions. Actual strict hardware and malformed VIAL refusals preserve native/API/newline reports, stable diagnostics and isError. T1884 consumes the same pure oracles for selected supported queries. Focused regression and rendered book pass; full coverage remains explicitly pending.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.1.3: guard independent source-query semantics`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.2`
  Status: `done`
  Goal: `Integrate feature-query coverage with existing regression partitioning and future-feature signoff.`
  Acceptance: `Use the repository-owned CI/regression contracts to register the new corpus coverage without repeating a full cohort in unrelated file shards. Verify exact disjoint complete partitioning, list-only/source-filter behavior and focused developer commands. Require new public source features to carry a supported corpus case and semantic/schedule API/MCP evidence or an explicit owned applicability boundary. Update maintained workflow/book guidance, run focused integration checks, and leave the full cohort run to .31.3.3 before activity closure.`
  Verification: `T1183 qualifies separate T1884 corpus ownership, exclusion from ordinary shards, complete disjoint query partitions, all-source full/hosted selection, actual argv/environment dispatch and pre-dispatch refusal of ambient narrowing. T1885 stays bounded ordinary regression. Workflow, rendered/runnable book, task/template signoff and current sharding facts agree; T1883 and relative-path checks pass. Configuration counts do not claim hosted or exhaustive runtime results.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.2: integrate source-query coverage into CI`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3`
  Status: `done`
  Goal: `Expose typed VIAL source details through a stable additive inspection API and MCP.`
  Acceptance: `Root-cause the summary-only native contract before changing it. Keep existing v1/v2 tooling results and capability records unchanged. Select a separately versioned JSON-safe read-only projection, implement bounded portable/filesystem inspection and CLI exposure, then adapt MCP and qualify independent authored lifecycle/base semantics. Do not export private SemanticIR or require DUT binding, planning, execution or publication to inspect source meaning.`
  Verification: `The additive typed source-inspection contract, complete base/lifecycle projector, native semantic prerequisites, portable/filesystem APIs, native CLI/independent discovery and dedicated MCP tool/resource are qualified through the child commits. Existing summaries and frozen capabilities remain exact. Catalog-derived full feature coverage and future-feature signoff remain .31.3.2.1-.2 and .31.3.3.`
  Commit: `Completed through .31.3.2.3.1-.3 child commits`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.1`
  Status: `done`
  Goal: `Select the additive VIAL deep-inspection contract from verified missing public details.`
  Acceptance: `Capture actual public summary output and independent authored lifecycle/base observations, verify intentional compatibility boundaries and record the precise additive API/result/CLI/MCP design. Decompose implementation into safe owned slices, update the book truthfully as selected rather than shipped, preserve frozen records, and commit selection before implementation.`
  Verification: `Actual public CLI/newline MCP reports agree completely while excluding lifecycle nodes and base action/declaration bodies. The tracked probe and source assertions establish an intentional summary boundary; decision 0105 and the source-inspection contract select additive typed APIs and MCP without changing frozen records.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.1: select additive VIAL deep inspection`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.2`
  Status: `done`
  Goal: `Implement the selected bounded public VIAL detail API and native inspection command.`
  Acceptance: `Decompose portable typed projection, filesystem adaptation and CLI into independently verifiable leaves before source changes. Use explicit public record constructors and closed field shapes, defensive fresh values, stable source identities and diagnostic behavior. Preserve base/lifecycle conditions, ordering, references and bounds with independent authored oracles; reject malformed invocation, unknown schema/family and incomplete projection. Reuse the existing bounded source loader without a second filesystem read, preserve old check/format/plan results and frozen capability hashes, and prove no artifacts or execution.`
  Verification: `Closed base and complete lifecycle projection, prerequisite native semantic repairs, portable/filesystem APIs and native CLI/independent discovery are qualified through the child leaves. Captured-byte reuse, exact native checks, authored semantics, fail-closed boundaries and frozen capability hashes are guarded; MCP detail is next.`
  Commit: `Completed through .31.3.2.3.2.1-.4 child commits`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.2.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.2.4`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.2.1`
  Status: `done`
  Goal: `Implement closed typed projection of base VIAL source meaning.`
  Acceptance: `Enumerate public base record fields and discriminants, then implement explicit constructors for source/package/declaration/type/value/expression/fixture/action details. Preserve selected model and resolved fault binding identities, provenance coordinates and unresolved bridge assertions. Reject missing/unknown fields, kinds and not-yet-implemented family detail; never dump an arbitrary private hash. Prove authored observations, full source-version/style/import fidelity, defensive determinism and malformed-record refusal while preserving frozen summaries. This internal foundation remains unadvertised until the public facade and lifecycle projection are complete.`
  Verification: `SourceInspection constructs closed typed base records for both source versions, resolves all public fault targets and preserves model scope. T1875 independently verifies rich authored declarations/actions/expressions, source coordinates, imports, styles, fresh deterministic values and malformed-record refusal. Lifecycle families deliberately fail until .2; no public facade is advertised.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.2.1: construct closed VIAL base inspection records`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.2.2`
  Status: `done`
  Goal: `Project complete typed lifecycle-control source semantics.`
  Acceptance: `Extend the base projector with the selected public intent-node envelope and explicit lifecycle payload/condition/detail shapes. Preserve authored and intrinsic dependencies, service state conditions, deadlines and failure cleanup. Validate registered family/revision, reject unknown and incomplete records, prove independent authored values and complete source locations, and keep the API unadvertised until the facade ships.`
  Verification: `Closed lifecycle projection is qualified by T1877, with service-start and empty-readiness prerequisites repaired and qualified by T1878/T1879. All children are complete; public API exposure is next.`
  Commit: `See committed children .1, .2 and .3.`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.2.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.2.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.2.2.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.2.2.1`
  Status: `done`
  Goal: `Construct closed typed lifecycle inspection detail with authored semantic oracles.`
  Acceptance: `Implement the parent projection contract over admitted SemanticIR, preserving complete conditions, scope, ordering, service/deadline/failure policy, fresh values and source coordinates. Qualify defaults, explicit admitted policies, imports/styles and hostile records. Track and explain the discovered native start_requires failure under .2, without claiming that source form is working. Commit this coherent internal projection before the compiler prerequisite; keep public API unadvertised.`
  Verification: `T1877 proves exact public lifecycle nodes, complete authored/default conditions and policies, independent coordinates, source styles/imports, optional service/dependency controls and hostile record refusal. The focused source/inspection band and rendered book pass. Native start_requires and empty-readiness failures are diagnosed and immediately owned by .2/.3; no public API is advertised.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.2.2.1: project typed lifecycle source detail`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.2.2.2`
  Status: `done`
  Goal: `Repair native lifecycle service start_requires construction and qualify complete inspection coverage.`
  Acceptance: `Reproduce public rejection of legal configured/reset start requirements, root-cause the unparenthesized map consuming the optional condition as another dependency ID, and repair construction without weakening validation. Preserve canonical source/plan identities, verify exact additional conditions and references through normal/terse/import/native/API/MCP and typed inspection, and qualify other optional clauses. Keep unknown/cyclic/excess inputs fail-closed. Record controlled baseline/current evidence, update contract/book/facts and qualify this prerequisite before .3 closes the remaining empty-readiness gap. No spent runtime producers.`
  Verification: `Parenthesizing only the dependency map preserves authored start conditions. T1878 passes configured/reset/nested conditions with and without dependencies, imported scope, style and native/API/MCP parity, exact typed inspection and actual target-neutral planning. Unknown/cyclic/excess inputs still fail. Controlled baseline/current reports preserve canonical check/plan identities; the focused band and rendered book pass.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.2.2.2: preserve authored service start requirements`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.2.2.3`
  Status: `done`
  Goal: `Admit configured readiness when a lifecycle has no dependencies or service.`
  Acceptance: `Reproduce the grammar-valid empty dependency/service case and repair only its vacuous readiness normalization, retaining the configured lifecycle-entry precondition and refusing authored empty all. Prove typed inspection, source styles, native/API/MCP and target-neutral planning; preserve canonical identities and all nonempty prerequisite order. Clarify the default in the spec/book and retain controlled evidence. Commit before closing lifecycle inspection or advertising its facade; no runtime producers.`
  Verification: `T1879 proves legal empty readiness normalizes to all(configured), with no invented relations/services and the same meaning as explicit configured readiness. Native/inspection/plan conditions, styles/imports and API/CLI/MCP parity pass; invalid authored empty/unknown/cyclic/excess conditions still fail. Controlled reports preserve canonical and existing nonempty identities. The focused band and rendered book pass.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.2.2.3: normalize empty lifecycle readiness`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.2.3`
  Status: `done`
  Goal: `Expose portable and bounded filesystem VIAL source inspection APIs.`
  Acceptance: `Implement the selected closed invocations and independent result envelope over captured source bytes and the qualified typed projector. Preserve complete native check results, diagnostics and null-on-failure detail. Reuse bounded filesystem loading without reopening after check, preserve version/style/import provenance, prove no planning/random/backend/provider/network/publication effects and fresh values, and document runnable API examples with exact admitted behavior.`
  Verification: `T1880 qualifies exported portable/filesystem APIs, complete native checks/diagnostics, current base/lifecycle detail, closed invocations, captured-byte reuse under file/caller mutation, fresh values and no execution/publication effects. The focused loader/source/inspection band, runnable book API example and rendered book pass; CLI/discovery and MCP follow.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.2.3: expose public VIAL source inspection APIs`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.2.4`
  Status: `done`
  Goal: `Add native VIAL inspection command and independent capability discovery.`
  Acceptance: `Implement inspect JSON CLI and separate machine-readable inspection contract without changing frozen tooling capabilities. Reject planning/runtime/publication options, prove complete CLI/API equality and actual version/style/import/error behavior, synchronize book and discovery guidance, and commit before MCP adaptation.`
  Verification: `T1881 proves actual native CLI/API equality for both languages, normal/terse/imported/current lifecycle forms and failures; exact authored action/deadline detail; closed JSON-only options and exit codes; independent manifest discovery; fresh capability values and unchanged frozen v1/v2 hashes. Focused manifest/API/CLI/MCP-summary band and rendered/runnable book pass.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.2.4: expose native VIAL inspection and discovery`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.3`
  Status: `done`
  Goal: `Expose qualified VIAL detail inspection to external agents through MCP.`
  Acceptance: `After .2, add discoverable explicitly versioned deep-inspection tool/resource contracts backed only by the clean public API. Preserve existing semantic summary queries and native/MCP parity, qualify actual v1/v2/imported/invalid/root-boundary sources and meaningful lifecycle/base detail assertions, update snapshots/book/facts and expose the query in the public applicability map consumed by the subsequent .31.3.2.1 catalog-guard implementation. Keep execution and mutation outside this read-only slice.`
  Verification: `T1882 qualifies native/API/MCP tool/resource equality, text/structured parity, explicit versions/styles/imports, authored actions and current lifecycle conditions/deadlines/policies, failed source/projection reports, protocol/authority refusal, no writes or hardware runner and actual one-shot/newline transports. All discovery inventories and schema snapshots agree; focused MCP regression and runnable/rendered book pass. Catalog guard integration remains .31.3.2.1.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.3: expose typed VIAL inspection through MCP`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.4`
  Status: `done`
  Goal: `Repair stale activation-equality assumptions in focused-document regression coverage.`
  Acceptance: `T1569 must check maintained references against current structural/link contracts, and prove historical activation equality in a separately reconstructed repository-local fixture. Preserve the activation verifier and negative controls; do not revert legitimate downstream-book edits or loosen production validation. Demonstrate the failure predates this selection, retain exact activation reconstruction and corruption detection, run the repaired focused test and doctrines, then resume VIAL typed inspection.`
  Verification: `T1569 now checks current structural/link contracts and independently reconstructs exact declared Git activation sources in an isolated repository-local fixture. Historical equality passes before a controlled edit and rejects that edit afterward; current structure still passes and all live source hashes remain unchanged. T1560/T1561/T1569 and rendered book guidance pass.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.4: separate live reference checks from activation equality`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.5`
  Status: `done`
  Goal: `Preserve the selected model instance in VIAL typed state references and meaning identity.`
  Acceptance: `Reproduce the actual public check digest collision between reads of distinct instances of one model declaration. Preserve both declaration-state and selected-instance identity in typed references, prove distinct meanings plus same-meaning style stability for v1/v2 and migration, and retain downstream propagation without backend execution. Treat changed digests for affected model reads as an explicit bug correction; do not change summary/result/capability shapes or unaffected frozen fixtures. Add authored independent identity assertions, missing-instance negative controls, public/native/MCP evidence, contract/book/fact updates and a separate commit before deep inspection resumes.`
  Verification: `The controlled old/current compiler probe reproduces then removes the v1/v2 digest collision with identical input bytes and source identities. Model references now retain model_instance_id plus the state semantic_id. T1872 independently verifies authored bindings, style/migration equivalence, execution propagation, complete native/filesystem/MCP parity and unknown-reference refusal. Unchanged base reports remain identical; the focused nine-file band passes.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.5: preserve VIAL model instance meaning identity`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.6`
  Status: `done`
  Goal: `Preserve the selected transaction binding in VIAL fault target meaning.`
  Acceptance: `Capture actual public source checks for distinct aliases of one transaction declaration and prove the current false digest equality. Select a compatibility-safe exact target representation before implementation, preserving unambiguous existing qualified fixtures where identity is derivable. Retain selected scope through semantic/compatibility and typed execution projections, qualify v1/v2 normal/terse/import/migration and API/MCP behavior, and require future source inspection to expose an exact resolved target. Verify runtime profile applicability without replaying spent producers or inferring runtime qualification from source checks. Own any real downstream gap before closure, update contracts/book/facts and commit separately.`
  Verification: `Source identity repair .1 and downstream applicability .2 are complete. Distinct aliases retain semantic scope; actual public AHB binding rejects unmatched transactions, duplicate references cannot bypass validation, and canonical source/plan/emission remain qualified. No multi-binding runtime capability is claimed.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.6.2: qualify VIAL fault target execution boundaries`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.6.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.6.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.6.1`
  Status: `done`
  Goal: `Disambiguate source fault targets without invalidating unambiguous legacy identity.`
  Acceptance: `Use the existing declaration transaction_id when exactly one fixture binding has that declaration; add transaction_binding_id when multiple bindings make the target otherwise ambiguous. The pair must resolve the authored binding exactly; new public inspection must always expose the resolved binding whether explicit or uniquely inferred. Qualify distinct aliases, same-meaning styles, versions/imports/migration, precise invalid-target rejection and complete native/API/MCP reports. Preserve exact canonical single-binding source/plan identities and cap fixtures. Retain raw source and declaration identities; do not widen the existing summary schema or infer runtime support. Record controlled before/after evidence and commit before downstream applicability qualification.`
  Verification: `The controlled old/current public probe proves distinct fault targets now have distinct v1/v2 meaning digests, with identical complete base reports and unchanged summary shapes. T1873 independently qualifies binding/declaration IDs, formats, imports, migration, malformed targets and native/API/MCP equality. The nine-file focused band preserves pinned canonical fault/plan identities. Downstream applicability remains .2.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.6.1: preserve exact VIAL fault target identity`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.6.2`
  Status: `done`
  Goal: `Qualify downstream fault-target applicability and repair any admitted ambiguous behavior.`
  Acceptance: `Trace the preserved target through binding and ExecutionIR into applicable public/backend contracts. Use exact admitted/rejected public-interface evidence; do not assume that source checking grants runtime support. Investigate emitter selection by field name and the bounded profile's actual admission. If a legal admitted case loses target scope, own and fix the exact route with negative controls before closure. Preserve unambiguous canonical identities and spent producer boundaries, and use documented dependency surfaces only. Close the fault parent only after target handling or explicit truthful unavailability is proved, then resume typed source inspection.`
  Verification: `T1874 proves genuine canonical v1/v2 execution binding, explicit fault normalization, unresolved-alias and duplicate-reference refusal, plain-IAL1 correlation refusal and canonical SV emission without runtime. The misleading declaration_order sentence is clarified against original implementation history. The four-file binding/emission band and rendered book pass.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.6.2: qualify VIAL fault target execution boundaries`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.7`
  Status: `done`
  Goal: `Restore authored declaration order after native VIAL dependency resolution.`
  Acceptance: `Reproduce forward aliases returning dependencies before earlier authored declarations in native SemanticIR and public summaries. Restore declared ordering without breaking recursive resolution or stable IDs, qualify both versions, imports, styles and API/MCP output, and explicitly assess affected semantic/compatibility digests while preserving unchanged canonical fixtures. Keep the inspection projector ordered independently by source provenance. Add durable positive/negative oracles and correct contract/book/facts; commit this repair immediately after the base projector before lifecycle implementation. Do not replay spent backend producers.`
  Verification: `T1876 proves authored order and path indices in both versions, local/imported references, style/migration identity, invalid dependency refusal and complete portable/filesystem/CLI/MCP equality. Controlled baseline/current probes preserve complete base reports while correcting affected order/digests. The focused source/planning/inspection band and rendered book pass.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.7: preserve authored VIAL declaration order`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.3`
  Status: `active`
  Goal: `Qualify the complete selected feature population and resume the roadmap from a clean durable handoff.`
  Acceptance: `After all owned repairs and the coverage guard pass, execute the selected actual feature queries, schema/provenance and negative controls. Update capability/book/fact guidance and feature signoff rules, state exact coverage and remaining intentional boundaries, and commit before resuming the existing bounded HIAL streaming frontier. Do not treat internal/native backend qualification as MCP execution authority or replay spent native compiler producers.`
  Verification: `CI integration is committed at c42b112b15a351680ef918ec15a241aee3228b4a and the tree was verified clean. Execute each declared T1884 corpus partition sequentially through the actual CI entrypoint, retaining per-query receipts and per-partition logs. Independently join their disjoint union to the live cohort, source/catalog identities and typed report hashes; rerun named semantic/refusal controls. Stop and root-cause any failure before advancing. Preserve spent runtime producers and full-CI/startup gates.`
  Commit: `pending`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.3.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.3.1`
  Status: `done`
  Goal: `Root-cause and repair excessive MCP memory use exposed by complete source-query qualification.`
  Acceptance: `Retain the original guarded failure and identify the exact source/query/transport before changing implementation. Distinguish native report size, adapter expansion and harness retention with bounded public queries and measured evidence. Repair the demonstrated cause with complete report/type/provenance parity and meaningful regression controls, preserving public contracts and the configured resource cutoff. Do not hide the case, narrow the qualified cohort, or replay spent runtime producers. Commit the repair before restarting exhaustive qualification.`
  Verification: `The interrupted full run earns no partition result. Its last sampled AHB semantic source independently reproduces the same resource failure specifically during outer response encoding. Public JSON encoder controls isolate ASCII-mode large-string amplification; UTF-8 wire encoding preserves complete values. T1886 qualifies both real CLI modes under a tighter guard, typed report equality, Unicode byte identities and invalid UTF-8 refusal. The actual implicated source passes all applicable native/API/newline queries under the original guard. Focused MCP regression, book commands/rendering and retained qualification evidence pass.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.3.1: prevent MCP wire encoding memory amplification`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.3.2`
  Status: `active`
  Goal: `Complete source-query qualification after the resource repair and resume the roadmap cleanly.`
  Acceptance: `Execute every selected source/query through the repaired native/API/MCP paths, retain per-query evidence and independently prove disjoint complete catalog allocation and report hashes. Run semantic/refusal controls, synchronize the book and facts, and commit before resuming bounded HIAL streaming. Keep full-CI/startup and spent-producer boundaries intact.`
  Verification: `Repair commit 4d0beeb638223943e189431f89bae8c070ceade2 is clean with an empty commit-message file. Restart every declared source partition with explicit all-source selection, direct verbose prove for expanded per-query TAP, and at most two read-only partitions under one unchanged RAM guard. Stop new dispatch on a failure, consume every running result, retain per-partition evidence and independently qualify the complete union. Fresh query-complete-* artifacts preserve the interrupted query-full-* attempt, which earns no complete-cohort result.`
  Commit: `pending`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.3.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.3.2.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.3.2.1`
  Status: `done`
  Goal: `Preserve distinct concatenation identities in generated HDL and consistent native/API/MCP semantic reports.`
  Acceptance: `Retain failed partition evidence and trace the original structural-identity/emission mechanism. Native seed-controlled reports and exact HDL prove the defect; repair its producer without dropping size metadata or normalizing away differences. Preserve ordered concatenation operands, literal representation and signal slices; leave unrecognized node kinds and containing expressions unfactored rather than merging class-only signatures. Allocate candidate names deterministically. Add reduced identity/substitution and seed-order regressions, plus an independent bounded generated-HDL behavioral oracle with differing inputs. A new isolated ordinary HDL simulation is allowed; historical native-proxy/compiler/runtime producers remain spent and untouched. Bound complete-response failure diagnostics without narrowing comparisons. Preserve contracts/resource limits, consume both partitions before changes, and commit before complete qualification.`
  Verification: `T1887 fails against the isolated baseline and passes after complete supported-node signatures, conservative unknown-node handling and deterministic naming. Independent HDL simulation catches incorrect substitution with differing inputs. Original APB native reports now match across controlled seeds; HDL matches except its timestamp. The original APB differing driver was unused, so that example does not establish an output malfunction. All failed sources independently recovered from both retained partitions pass every applicable native/API/MCP query. Focused compiler/oracle bands, syntax, book/rendered assertions and exact receipt/hash qualification pass. Capture: docs/audits/mcp-feature-coverage-20260924/source-query-identity-repair.json. Complete cohort remains open.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.3.2.1: preserve expression identity during factorization`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.3.2.2`
  Status: `pending`
  Goal: `Finish complete source-query qualification after the report consistency repair.`
  Acceptance: `Execute the complete accounted population after repair, retain all actual query receipts, independently check complete disjoint allocation and typed report hashes, synchronize book/facts and commit before HIAL resumption. Keep every discovered gap owned until fixed and preserve existing full-CI/startup and spent-producer gates.`
  Verification: `Resume after the director-supplied SPECFORGE reports under .32 are resolved. The interrupted and failing attempts remain distinct retained evidence, not completed coverage.`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32`
  Status: `active`
  Goal: `Resolve the SPECFORGE downstream reports while retaining deep semantic API/MCP coverage.`
  Acceptance: `Read the caller-authorized bundles under ../specforge/docs/fsmgen-issues/ without modifying SPECFORGE or inspecting its submodules. Reproduce against current FSMGen in repository-local fixtures; fix confirmed defects and implement the bounded derived-width capability in separately committed leaves. Each product change includes native/API/MCP semantics and book contracts. Begin only after the active compiler repair is committed and clean; return to complete cohort qualification afterward.`
  Verification: `All three README.md reports were read on 2026-09-24. Their historical measurements and reproduction claims are supplied evidence, not current-checkout verification. Do not run bundled scripts before checking their paths and locality defaults.`
  Commit: `pending`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.4, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1`
  Status: `active`
  Goal: `Reject undeclared ISF rule operands before implicit input creation or width inference.`
  Acceptance: `Reproduce sf-isf-undeclared-rule-operand from its supplied primary, mixed-width and declared controls. Diagnose rule operand resolution, retain legitimate actor symbols, reject invalid reads with actor/rule/name provenance, and verify strict checks, semantic API/MCP and generated interfaces. Investigate and repair the report's related internal-path/stack diagnostic exposure if confirmed. Refine into safe leaves before implementation.`
  Verification: `Caller bundle: ../specforge/docs/fsmgen-issues/sf-isf-undeclared-rule-operand/README.md; SPECFORGE owner FSMGEN-REQUESTS.2. Structural identity repair is committed as 45c0e579c23f3c693e7537de1693e5ef6a07cccd; clean tree, empty message file and derived ahead count verified before activation. Read supplied cases without changing SPECFORGE; preserve exact hashes when copying to task-owned local fixtures. Missing-operand reproduction and repair are complete under .32.1.1; the width-diagnostic repair is complete under .32.1.2; the reproduced strict multi-domain wiring repair is active under .32.1.3.`
  Commit: `pending`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.1`
  Status: `done`
  Goal: `Validate declared ISF rule read operands before actor-shell return and scheduling.`
  Acceptance: `Reject undeclared scalar and nested-expression reads in rule guards and value/index operands before IAL0 inference. Preserve declared ports/storage, actor constants/parameters, enum and aggregate leaves, and supported ATL trigger actions. Keep transaction-local inferred assignment behavior separate. Collect useful actor/rule/operand context deterministically and register the expected-failure fixture with stable FSMGEN_LANGUAGE_ISF_UNDECLARED_RULE_OPERAND metadata; qualify exact supplied cases, public API, native check/semantic/schedule, MCP and generated-port controls. Use focused rule/symbol regressions and supported-source admission checks; synchronize book/facts and commit.`
  Verification: `At 45c0e579c, all supplied cases are copied byte-for-byte into .artifacts/specforge-undeclared-rule/ with hashes. The one-bit undeclared source passes strict check and semantic emission with VALID exposed in signal_analysis and structural_rtl_ir input ports. Both invalid variants pass schedule preview. The mixed-width variant fails late as a width mismatch on B. The baseline parser checked form and special enum/aggregate domains without rejecting an ordinary unknown scalar token. The repair refuses both supplied invalid variants before lowering, preserves declared controls and has complete evidence in docs/audits/specforge-rule-admission-20260924/.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.1: reject undeclared ISF rule reads`

  Compatibility prerequisite: `The first complete public-adapter census exposes generated AXI endpoint/composition rule reads of undeclared shared state. Endpoint generators and composition coordinators now declare those captured payloads, launch/arm handoffs, active/completion flags and expected response IDs as actor storage at their intended widths. No name whitelist or promotion of transaction-private values is used. Scheduled FSM differences are explicit size declarations; endpoint and composition SV is otherwise byte-identical after removing only date headers. Both component baselines and repairs pass the existing independent protocol behavior oracles. The complete ordinary public-adapter census passes; every affected endpoint and composition passes native/API/newline MCP check, semantic and schedule comparison. See the acceptance evidence and retained receipts below.`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.2`
  Status: `done`
  Goal: `Preserve authored ISF source context in operand-contract failures without implementation diagnostics.`
  Acceptance: `Reproduce a declared but width-invalid ISF control independently of the missing-operand repair. Trace generated-to-authored source mapping and backend exception presentation, repair confirmed leaked implementation paths/names in public diagnostics, and qualify native/API/MCP error identity with targeted direct/ISF controls. Keep this boundary separate from successful actor admission.`
  Verification: `The independently declared VALID width-8 control still fails at B width-1 on be25e7205. Native check JSON names the temporary ial1-lowering FSM in source.resolved_path, diagnostic.source_file and the embedded Source file line. bin/fsmgen saves public_source_file but its generation catch uses fsm_file; CheckDiagnostics extracts the embedded label before its fallback argument. OperandContractValidationSupport adds its module/method prefix at the producer. Repair the shared ISF/PPIF handoff using exact generated-file origin registration, preserve unrelated authored child and expected-lookup artifact paths, and remove the backend prefix at origin. Exact registered source identities now project to the authored source in both report fields and embedded messages; the producer prefix is removed. T1889 and the focused regression band pass. Durable before/after capture and limits: docs/audits/specforge-rule-admission-20260924/width-diagnostics.json.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.2: preserve authored lowering failure context`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3`
  Status: `active`
  Goal: `Make generated multi-clock ISF top wiring strict-admissible and qualify native/API/MCP failures and success.`
  Acceptance: `Repair the emitted legacy slash-link syntax at the multi-domain generator, not by relaxing strict validation. Qualify complete generated artifact admission, real child width failures with authored provenance, valid event-crossing behavior, and native/API/newline MCP parity. Synchronize exact supported boundaries in the book and task evidence; commit before bundle work.`
  Verification: `T1889 development probe on .32.1.2 exposes strict rejection of /bus_start/source.bus_start/ in domain_width_control_top.fsm. perl/FSM/Scheduler/ISF.pm::_emit_multi_domain_wiring calls _link, which returns slash-delimited links at line 519. The generated wrapper fails before its intended child width error. Existing T1247 exercises partition structure rather than strict top admission. Initial failing TAP is .artifacts/specforge-width-diagnostics/focused.tap; no strict multi-domain qualification is claimed by .32.1.2.`
  Commit: `children below`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.4, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.1`
  Status: `done`
  Goal: `Emit canonical multi-clock top wiring and qualify strict admission without changing generated hardware.`
  Acceptance: `Replace slash-form links at their generator. Exercise event, dual-event, no-reset and activation top routes; compare compatibility HDL before/after and strict HDL after. Qualify actual native/API/newline queries and strict child-width diagnostics; preserve direct strict rejection of authored legacy syntax. Commit independently of reset polarity repair.`
  Verification: `At c6b8bc783 all three checked-in clock_domain_*_event_crossing fixtures fail strict check on generated slash links but emit compatibility HDL. Exact commands, failures and baseline artifacts are retained in .artifacts/isf-multiclock-strict/before/. T1890 qualifies independently strict-generated artifacts, same-source strict/compatibility HDL and complete native/API/newline check/semantic/schedule equality for event/dual-event/no-reset/activation controls with supported reset/name choices. Original fixture compatibility HDL is byte-identical after removing date headers. Strict original dual-event/no-reset checks pass; the single-event fixture progresses to its true reset-carrier refusal. Behavioral reset qualification is explicitly excluded here and owned by .32.1.3.2/.3 because baseline HDL reveals opposite domain/CDC reset polarity.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.1: emit canonical multi-clock wiring`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.2`
  Status: `done`
  Goal: `Preserve authored ISF reset polarity through ordinary and multi-clock FSM lowering.`
  Acceptance: `Trace the full public reset carrier contract and repair polarity loss without combinational reset-tree glue or changing authored intent. Cover sync/async and active-high/active-low choices, flat-name defaults, explicit declarations, no-reset, report metadata and generated domain/CDC agreement. Prove actual reset behavior with independent HDL oracles; qualify API/MCP and update source/book contracts.`
  Verification: `Before any wiring repair, clock_domain_event_crossing.isf emits domain always_ff blocks with if (bus_rst_n)/if (core_rst_n), but its CDC module uses if (!source_reset)/if (!dest_reset) on the same nets. Parser::_parse_reset correctly infers active_low from _n; Scheduler::ISF::Emitter::FSM::_emit_system ignores polarity for sync and also emits areset for both async polarities. The core public contract says sreset is synchronous active-high and areset asynchronous active-low. Baseline design.sv and generated top metadata under .artifacts/isf-multiclock-strict/before/ preserve the contradiction. This affects more than strict syntax; do not qualify these reset-declared designs behaviorally until repaired.`
  Commit: `children below`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.2.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.2.1`
  Status: `done`
  Goal: `Carry explicit reset polarity through the public FSM grammar, semantic contracts and hardware backends.`
  Acceptance: `Add an optional literal active_high/active_low modifier to canonical sreset/areset declarations; preserve omitted-modifier defaults and existing strict legacy/name checks. An explicit modifier owns polarity independently of naming; invalid tokens, non-scalars, duplicate/malformed declarations and asreset extensions fail closed. Preserve reset kind/level in effective and explicit public semantic contracts without changing their bounded field shapes; advertise the additive source option in language-surface capabilities. Qualify all sync/async and high/low combinations through direct API, native/MCP reports, independent emitted-HDL reset behavior, and focused existing reset/contract regressions. Update book and decision record, then commit before changing ISF emission.`
  Verification: `At 7761cc503, FSMGenFull::Parser::parse_system_section requires exactly two tokens and derives level from sreset/areset. CoreAST::FSMModule::effective_system_contract recomputes kind/level from the keyword even though the parser already records reset_kind/reset_active_level. Backend and ModulePlanningSupport consume those normalized fields. SourceFrontend::_strict_system_reset_contract_issue checks keyword/name conventions before parsing. The public normalized explicit-system contract already contains clock/reset/reset_keyword/reset_kind/reset_active_level; no new semantic result keys are needed. Decision 0106 owns the additive syntax and compatibility boundary. T1891 qualifies all combinations, legacy controls, malformed input, capabilities and complete native/API/newline equality; T1892 independently proves reset timing/level in SV, Verilog and VHDL with real providers. Exact reports, hashes and non-skipped TAP are in docs/audits/specforge-rule-admission-20260924/reset-polarity-carrier.json.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.2.1: preserve explicit reset polarity`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.2.2`
  Status: `done`
  Goal: `Lower authored ISF reset kind/polarity faithfully through the qualified public FSM carrier.`
  Acceptance: `Use the explicit modifier when keyword defaults or strict naming heuristics cannot represent the authored policy, preserving already strict-supported output spellings. ISF flat-name inference and direct FSM strict naming differ (including _b and bare n suffixes); never reinterpret authored polarity from the emitted identifier. Cover flat-name inference, explicit sync/async high/low declarations, no-reset, ordinary and multi-clock actors, generated domain/CDC agreement, independent reset/event behavior, and complete native/API/MCP reports. Requalify original event-crossing fixture, update misleading book mappings and facts, and commit before naming/explicit-route repairs.`
  Verification: `The public carrier is committed at 07f7e8333. Scheduler::ISF::Emitter::FSM::_emit_system emits sreset for every sync policy and areset for every async policy without retaining polarity. SourceFrontend strict name policy treats final n case-insensitively as low-active; ISF flat inference uses case-sensitive _n/_b. The original contradictory HDL is retained in the .32.1.3.1 audit. The repair preserves authored policy with explicit modifiers where necessary. Ordinary and domain/CDC simulations pass for every timing/level combination; the exact baseline HDL fails the same independent oracles. T1890/T1893 qualify complete native/API/newline equality, and the focused regression band passes. Tracked reports, HDL, oracles and replay: docs/audits/specforge-rule-admission-20260924/isf-reset-polarity.json. The mdBook output-path mistake is fully recovered with copied/hash-verified renders and exact old-root residue census; see book-output-recovery.json.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.2.2: preserve ISF reset policy through lowering`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3`
  Status: `active`
  Goal: `Complete multi-clock behavioral and semantic-query qualification after syntax and reset repairs.`
  Acceptance: `Run independent event/activation behavior and reset controls against repaired strict HDL, preserve exact native/API/newline reports and complete emitted-artifact admission, synchronize book/facts, then close .32.1.3 and return to .32.2.`
  Verification: `Requires committed .32.1.3.1, .32.1.3.2 and .32.1.3.4; strict admission alone is insufficient.`
  Commit: `children below`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1`
  Status: `active`
  Goal: `Repair independently triggered transaction and plain local-call reachability.`
  Acceptance: `Use the retained event-after-activation failure and non-colliding control to establish the scheduling contract, including plain multi-transaction and existing dual-event controls; repair lost independent transaction reachability or fail closed at the documented unsupported boundary with accurate capability/report evidence. Prefer completing intended supported behavior. Require independent event and activation oracles, repeated/reset controls, public artifact/API/MCP qualification and synchronized book before closure.`
  Verification: `The generated core FSM starts at worker_idle_ext and returns there through worker_done_ready/worker_done_req. core_consume_idle_0 and its completion state form a separate unreachable component; an event-after-do source strict-checks but its independent oracle reports expected 1 observed 0. The naming slice owns exact retained source/HDL/control evidence. No successful mixed-transaction runtime claim is made.`
  Additional reproduction: `The .39.2.2.2.3.2 plain-do control strict-admits but times out: core FSM starts at worker_wait_0 and cycles worker_done_11 back there, leaving parent_idle_0/parent_do_1 unreachable. Recreate from T1916 text by replacing spawn worker as reader with do worker and removing only the core parent await_all done; keep its remaining source and spawn HDL oracle. Retained source/materialized FSM/HDL are under .artifacts/domain-storage-reads/plain-do; spawn-do-runtime.log records the timeout. Repair here before metadata signoff; generated-do storage reads remain separately qualified.`
  Terminal-await reproduction: `During .39.2.2.4.2, domain-qualified.log exposes Use of uninitialized value target at Emitter/FSM.pm line 336. The retained .artifacts/whole-aggregate-writes/terminal-await.isf ends the parent immediately after await_all done; _emit_transitions reads a missing first transition target for terminal sync_all. Recreate from T1920's explicit aux_seen input child control by removing parent complete finished and its output. Own the terminal-await scheduling/emission repair here alongside reachability; current positive domain controls use an explicit completion.`
  Commit: `pending`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.1`
  Status: `done`
  Goal: `Emit terminal synchronization states without an undefined continuation.`
  Acceptance: `Reproduce the retained terminal await_all source and inspect await_any and empty pending sets. Establish fall-through versus explicit complete semantics from existing lowering; preserve terminal hold when no continuation exists instead of inventing a rearm edge. Fix the missing-target warning, qualify completion retention, strict replay, repeated/reset controls where a continuation exists and full public reports. Synchronize the book and commit before controller restructuring.`
  Verification: `The retained terminal-await source now strict-checks without warnings. T1922 qualifies both synchronization forms with empty/single/multiple pending sets, explicit hold, reset reactivation, exact interfaces/replay and complete native/API/MCP reports. T1908/T1912/T1920 and book/reference checks pass. Existing watchdog/controller defects remain open.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.1: preserve terminal synchronization holds`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.2`
  Status: `done`
  Goal: `Select an executable controller contract for independent transactions and blocking local calls.`
  Acceptance: `Reproduce the disconnected first/second and retained plain-do graphs with independent runtime oracles. Audit intended trigger/concurrency, shared storage, caller input capture, delayed completion, nested/repeated calls, reset and report provenance contracts. Select explicit per-transaction control or another semantics-preserving representation through public IAL0 carriers; do not silently serialize independent transactions, duplicate actor state or infer support from admission. Split implementation and qualification leaves before editing the scheduler and commit the contract/evidence.`
  Verification: `The direct-port audit two_ports scheduled source contains separate first/second state loops inside one ?fsm root. Existing plain-do and event-after-do runtime evidence separately proves unreachable callers/consumers; generated child activation already has independently qualified controllers.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.2.2: select independent controller and binding contracts`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.2.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.2.1`
  Status: `done`
  Goal: `Retain independent-controller and local-call runtime baselines and test a public IAL0 carrier.`
  Acceptance: `Use colliding-name-free sources in both declaration orders to distinguish unreachable independent controllers from local call defects. Test an explicitly authored controller-register/DT reference with simultaneous/separate/repeated requests and reset. Preserve complete source/oracle/output evidence in a tracked audit, identify conflict and binding dependencies, and commit the bounded audit without advertising a production repair or adopting an undocumented architecture.`
  Verification: `Both declaration orders strict-check and compile but fail independent-controller and local-call runtime oracles. Explicit IAL0 references pass simultaneous/isolated/repeated activation, idle hold and partial-work reset. Tracked audit source hashes and result classifications verify; book examples/build pass. Production behavior is unchanged and architecture adoption remains under .1.2.2 after .51.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.2.1: retain direct controller runtime evidence`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.2.2`
  Status: `done`
  Goal: `Adopt the controller contract with an explicit conflict and binding admission boundary.`
  Acceptance: `After .51 restores decision-record capacity, use .1.2.1 evidence and current source contracts to adopt a backend-neutral architecture preserving concurrent progress, actor storage ownership, call capture/completion timing and report provenance. Require an owned transaction-write conflict policy before independently enabling existing writers. Record the durable decision and split implementation/qualification under .1.3; do not silently serialize, duplicate storage or treat a hand-authored carrier as implemented lowering.`
  Verification: `Decision 0109 selects independent logical control, unchanged actor ownership, exact activation/timing classes and fail-closed shared-write admission. The retained binding audit confirms local delayed payload loss and generated live behavior; implementation is split under .1.3, with scoped identity dependency .49.2.2.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.2.2: select independent controller and binding contracts`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3`
  Status: `active`
  Goal: `Implement and qualify the selected direct transaction controller contract.`
  Acceptance: `After .1.2 selects the exact contract, split implementation into safe leaves and repair independent trigger and blocking local-call execution. Require simultaneous/separate triggers, declaration-order controls, nested/repeated calls, original binding edges, reset and source/API/MCP parity. Preserve fail-closed writer conflicts and publish any unsupported form precisely; unblock .49.2 only with executable evidence.`
  Verification: `pending`
  Commit: `pending`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.4, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.5, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.6`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.1`
  Status: `done`
  Goal: `Build a shadow logical-controller ownership model and inventory state consumers.`
  Acceptance: `After decision 0109, attach explicit transaction/domain ownership, entry and state membership without switching execution. Inventory predicates, point-active signals, priorities, loops/waits, terminal holds, resets, reports and emitted interfaces. Prove native/API/MCP and generated source parity, collision-safe identity planning, complete state membership and malformed-owner rejection. Commit the shadow slice before .49.2.2; split further if the inventory exceeds a safe code slice.`
  Verification: `T1924 qualifies explicit parent/child/domain membership and malformed-owner controls. The tracked logical-controller-shadow audit proves complete native/API/MCP and emitted IAL0 parity with the baseline; focused watchdog, point, domain, priority, binding and book-example gates pass. Phantom no-watchdog timeout references are removed without changing emitted behavior.`
  Commit: `this slice`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.2`
  Status: `done`
  Goal: `Repair local rule-trigger payload retention at the admitted activation boundary.`
  Acceptance: `After .1 and scoped identities .49.2.2, reproduce the tracked request-gated delayed-zero case and retain both generated-live controls. Preserve early entry visibility and later snapshots with no extra observable activation cycle. Qualify changed sources, repeated requests, reset, busy requests, conditional authored entry and granted multiple rule sources; never remove all source guards to choose an implicit winner. Preserve authored rule-target entry semantics. Close only from generated production runtime and exact native/API/MCP evidence.`
  Verification: `Children .1/.2/.3 retain the scoped failure baseline, integrate accepted-entry storage with complete reservations and qualify the invocation lifecycle independently through public pins. Stable/changed/early/conditional/repeated/reset/held/busy and priority/round-robin cases pass in SV/Verilog; ungranted overlap retains the selector assertion, generated live handoffs and unguarded targets preserve their semantics, and complete native/API/newline reports agree. This closes local rule payload retention only; shared-write admission, independent controllers and local calls remain separate.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.2.3`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.2.1`
  Status: `done`
  Goal: `Reverify the scoped production baseline and bind snapshot implementation dependencies.`
  Acceptance: `Run the retained request-gated delayed-read reproduction and both generated-live controls through current strict production HDL with independent runtime. Preserve source/testbench hashes and exact observations. Derive acceptance-edge/busy-request constraints from actual state and rule producers, retain decision 0109, and own any discovered public-report contract mismatch before snapshot integration.`
  Verification: `At b7b18c76095e2c08a629f823d964a2fd28afad93, stable and changed local inputs both observe zero with one completion instead of the required captured seven. Generated live controls observe seven and thirteen respectively, each with one completion. No source production change or HDL counterfactual is applied. Fresh schedule output also proves child completion storage-role and DT-kind enumeration omissions, owned by .56 before adding snapshot report roles. The bounded audit records the exact identities/results. Snapshot preparation/application and runtime qualification remain children .2/.3.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.2.2`
  Status: `done`
  Goal: `Integrate accepted local rule payload retention with complete source preparation.`
  Acceptance: `After .1 and enumeration repair .56, derive the initial target state and authored entry guard from actual owned states; preserve a request-visible entry view while capturing only at accepted entry. Retain held payload through busy work without queues or implicit source selection, preserve granted-source guards and generated live paths, and avoid a cycle when the entry guard reads a bound formal. Use stable source-derived collision-safe helper identities in both detached preparation and actual production, including domain scopes and final reservation coverage. Preserve public binding provenance and advertise any new emitted roles/kinds. Split safe children if needed before switching execution.`
  Verification: `T1965 qualifies actual raw/projected helper naming with a freed sibling-formal collision, signed width/type/internal ownership, complete source/domain reservations and negative missing-category/unreserved-declaration controls. Strict carriers and complete native/API/newline check/semantic/schedule reports agree. Independent SV/Verilog entry samples and delayed reads pass with a payload-dependent leading-when guard. The original stable/changed local reproduction now retains seven; generated-live controls remain seven/thirteen. Binding conflict, resource priority, generated-trigger, metadata, golden-report and book fixtures/build pass. Broader runtime admission is retained by .3.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.2.3`
  Status: `done`
  Goal: `Qualify local rule snapshots across acceptance timing, grants and repeated execution.`
  Acceptance: `Require independent public-pin SV/Verilog runtime for early entry samples, delayed stable/changed reads, repeated/reset/held and busy requests, conditional authored entry including payload-dependent guards, and granted multiple sources. Preserve generated-live controls, caller/source interfaces, complete native/API/newline reports and strict carrier replay. Keep controller reachability/local-call ownership limits separate; commit before writer admission.`
  Verification: `T1966 passes independent production SV/Verilog changed/repeated inputs, rejected entry including zero payload, busy requests at a later on, reset abort/re-entry, held level requests and priority/round-robin granted sources. Ungranted overlap is caught by the actual payload selector assertion. Unguarded targets still free-run and authenticated generated-live controls observe stable/changed inputs. Exact public interfaces, complete native/API/newline check/semantic/schedule reports and strict carrier replay pass. Resource/selector/preparation and book fixture/build regressions pass. Oracle correction separates next-entry samples from previous delayed completion and requires a fresh counted pulse; no production code changed in this qualification slice.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3`
  Status: `active`
  Goal: `Establish shared-write admission for independently active direct controllers.`
  Acceptance: `After .1/.2 and .49.2.2, derive physical target ownership from scoped identities and typed effects. Inventory data, completion, binding, named-drive and generated-handoff contributors. Preserve proved fan-in, rule priority and resource grants; refuse unproved overlapping controller writes with actionable diagnostics before runtime promotion. Do not treat shared encoded-state exclusion or parsed transaction priority as a proof. Qualify disjoint targets, equal/pulse compatibility boundaries, guarded conflicts and existing priority behavior; split implementation if needed.`
  Verification: `Select the bounded baseline first, then a detached physical writer inventory and conservative admission integration. Do not promote independent execution from the old encoded-state exclusivity assumption.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.3`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.1`
  Status: `done`
  Goal: `Retain current direct-writer admission and physical ownership baseline.`
  Acceptance: `Reproduce direct scalar/output/bank and named-drive writer overlaps through actual strict/check/schedule paths with disjoint/private, same-value and completion-pulse controls. Trace the current admission/provenance locus and relevant history without redoing the known controller runtime audit. Record exact actual physical targets/owners and bounded implementation obligations, including generated handoffs, source guards and domain isolation. No execution promotion or new arbitration is claimed.`
  Verification: `The retained source-hashed baseline at 18b23da3a confirms strict admission and empty compile issues for direct scalar/output, bank-entry, aggregate whole/member, masked and shared-drive overlaps. Parsed transaction priority creates no resolution; separate private formals, disjoint/same-value writes and completion fan-in remain controls. Rule/rule and unordered rule/transaction controls reject with exact current message tokens. Actual final writer records retain explicit state owners alongside legacy provenance. The tracked reproducer regenerates result.json exactly. T1209/T1219/T1261/T1403 and the mdBook build pass; no production behavior or independent execution is changed.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2`
  Status: `active`
  Goal: `Build a complete detached physical writer inventory from admitted production IR.`
  Acceptance: `After .1, inventory every state/DT assignment using explicit source ownership and actual physical target structure. Cover private formals, actor scalars/outputs, aggregate leaves/masked updates, scalarized banks, drives, binding copies, generated handoffs, completion fan-in and internal helpers. Preserve module/domain boundaries and actual grant/suppression predicates; never infer owners from prefixes or treat entry guards as body-wide exclusion. Prove completeness, deterministic detached products, malformed/omission controls and unchanged native/API/MCP/carriers before admission changes. Split producer families into safe children if needed.`
  Verification: `pending`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.3`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.1`
  Status: `done`
  Goal: `Normalize declared physical write targets without changing production admission.`
  Acceptance: `Resolve whole signals and admitted aggregate paths to module/root/packed-range identities using the existing AggregatePathSupport resolver and resolved declaration contracts. Keep private formals and scalarized bank entries distinct; treat masked updates as whole-target writes. Prove whole/member/disjoint/nested overlap, module isolation, width/type/unknown-path refusal and detached results against actual lowered baseline targets. No independent controller or admission change is enabled.`
  Verification: `T1967 resolves every assignment target from the admitted writer baseline using actual declarations, preserves private/module identity, and compares physical overlap for scalar/output/bank/masked/drive and aggregate targets. Independent nested record/list arithmetic, symmetric overlap, detached mutation and missing/type-width/path/range controls pass. T284/T283/T1261 and mdBook build pass. The helper remains detached; complete declaration/owner collection and shadow attachment are .2/.3, with executable admission separately owned.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2`
  Status: `active`
  Goal: `Collect complete writer declarations and explicit owner/activation records from actual producers.`
  Acceptance: `After .1, collect every parent/domain state and DT assignment after actual binding/handoff wiring, with resolved target contracts and source-owned state/DT identities. Attach missing ownership at the actual producer, not by name-prefix parsing. Classify drives with multiple callers, generated handoffs, completion views and helpers conservatively. Retain actual guards/grants and mutation/omission checks; preserve reports and emitted carriers. Split producer families if completeness exceeds a safe slice.`
  Verification: `pending`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.4`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.1`
  Status: `done`
  Goal: `Collect explicit physical declarations from the actual lowered module.`
  Acceptance: `Match the production emitter declaration sources and precedence for ports, storage, counters and assembly operands; preserve resolved aggregate layouts and detached module-local identities. Reject malformed contracts, record unknown assignment roots without inventing widths, and compare actual emitted size declarations. This child remains detached and does not change production admission.`
  Verification: `T1968 matches exact emitted size/token sets for the admitted writer baseline, typed private formals, aggregates, assembly and actual post-wiring generated modules. Known sample widths remain unresolved when not explicitly emitted; declaration omission cannot be masked by signal_widths. Detached mutation, malformed contracts, precedence and static exclusions pass. T1967/T1344/T1963 and mdBook build pass. Collection remains detached; implicit target contracts and producer ownership remain the following children.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.2`
  Status: `done`
  Goal: `Resolve the remaining implicit scalar writer contract.`
  Acceptance: `After .1, qualify actual emitted implicit targets through the public carrier and canonical downstream width inference. Establish a sound whole-root contract for every remaining scalar writer without guessed widths, width-map overclaims or report changes. Retain malformed/omission and carrier controls before complete inventory attachment.`
  Verification: `T1969 proves actual bare implicit targets have conservative whole-root overlap contracts without guessed widths; native and emitted-carrier semantic products agree across inferred-width and state-order variants. Same-root sibling writes and mixed whole/member coverage overlap; different roots/modules remain separate. Missing layouts and malformed whole-root contracts fail closed. T1968/T1967/T310 and mdBook build pass. Canonical downstream inference remains authoritative; the helper is detached and producer ownership remains .3/.4.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3`
  Status: `active`
  Goal: `Attach explicit state and transaction/rule/drive producer ownership.`
  Acceptance: `Use actual source-owned transaction and rule/drive records rather than state or helper prefixes. Preserve activation guards, caller identities and grant/suppression evidence. Split producer families further before changing code if needed; require unchanged reports and carriers.`
  Verification: `pending`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.1`
  Status: `done`
  Goal: `Attach and qualify source identities for transaction auxiliary, rule and named-drive DTs.`
  Acceptance: `Retain existing explicit state.transaction ownership and attach private source_owner records at the actual transaction/rule/drive producers. Resolve source ownership against declared source records and actual module/domain identity without prefix parsing. Do not treat transaction-created auxiliary DTs as state-exclusive. Qualify parent/generated/domain modules, source permutations, missing/malformed records, detached results and unchanged reports/carriers. Exact caller/activation associations remain the next child.`
  Verification: `T1970 qualifies private transaction/rule/drive DT source_owner records and existing state.transaction identities against actual declarations, parent/generated/domain modules, private-formal preparation and source permutations. Renamed containers cannot change source ownership; missing/malformed/unknown identities are refused. Exact emitted carriers and schedules ignore private metadata; complete native/API/newline check/semantic/schedule reports agree and exported carriers strict-check. T1924/T1197/T1943 and mdBook build pass. Source identity does not imply activation or mutual exclusion; exact caller/guard collection remains .2.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2`
  Status: `active`
  Goal: `Qualify source-writer activation and exact named-drive caller associations.`
  Acceptance: `After .1, collect actual state/container/assignment guards and existing grants without replacing them with source-owner assumptions. Attach per-assignment local/generated named-drive invocation associations at the actual producer so multi-caller and mixed generated/local sources remain conservative. Preserve resource and priority predicates, and prove missing/malformed/caller mutation controls and public carrier/report parity before completing this source-producer parent.`
  Verification: `pending`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.1`
  Status: `done`
  Goal: `Attach exact local/generated invocation source records to named-drive assignments.`
  Acceptance: `Build private per-assignment invocation descriptors at _build_drive_dts from the actual local caller group or generated source record. Preserve empty and multiple local caller sets, generated activation instance/owner/child relationships and request-signal identity without parsing name prefixes. Validate association against the DT producer records, prove malformed/omission/source mutation controls and detached records, and preserve complete reports, priority behavior and emitted carriers. Existing broad public invoking_transactions provenance remains unchanged; no ownership exclusion or grant is inferred.`
  Verification: `T1971 qualifies exact per-assignment local caller groups and generated spawn/do/trigger source descriptors from actual producers, including child/instance/owner/request identity, empty/multiple local sets, source permutations and renamed DTs. Omission/source/request mutation and detached-return controls pass. Unique-caller target-local priority guards and suppressors are unchanged. Exact carrier/schedule comparisons ignore private metadata, complete native/API/newline reports agree, and the complete generated carrier strict-checks. T1542 runtime, T1942 preparation and T1970 ownership regressions plus mdBook build pass. Emitted activation proof remains .2.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2`
  Status: `active`
  Goal: `Qualify actual emitted writer activation guards and grant/suppression evidence.`
  Acceptance: `After .1, collect actual assignment and DT enable guards plus resource and priority evidence in a detached contract. Keep state transition/entry guards separate from assignment execution and do not infer transaction-wide exclusion. Verify the effective emitter semantics for every supported assignment operator and guard shape, including unguarded controls, state decrements and rule assignment grouping; preserve typed/raw predicates and caller descriptors. Diagnose and own any discrepancy before shadow admission; prove omission/mutation controls and full report/carrier parity.`
  Verification: `pending`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.1`
  Status: `done`
  Goal: `Repair dropped literal-false guards before writer activation qualification.`
  Acceptance: `P1 discovered defect: a strictly admitted rule with (when 0) retains port=0 in LoweringIR but _format_guard_suffix treats it as Perl false and emits an unconditional write. Reproduce actual emitted/runtime behavior with false/true and symbolic controls; qualify related state-entry assignment/transition and expression guard fields. Replace truthiness with explicit presence checks without changing supported syntax or inventing entry-wide assignment guards. Preserve normal guards, reports and public carrier replay, sync book/spec and commit before activation inventory work.`
  Verification: `Emitter presence checks preserve zero and numeric predicates render as explicit boolean expressions to avoid delayed-pulse/infix ambiguity. T1972 carrier, detached-IR and complete native/API/newline reports pass. Supervised Verilog false/true entry and SystemVerilog false entry pass the public-pin oracle; the SystemVerilog true-entry run is rejected before exec by setpgid EPERM. The earlier reset oracle was corrected after emitted HDL proved the existing register-input sample bypass remains visible at entry during reset. Focused non-runtime regression and book build pass; the initial runtime qualification was incomplete, with no containment weakening. Exact failure and ownership follow below.`
  Follow-up: `HIAL .3.2.10.3.2 consumes the qualified native witness at 915b311c2e82e37453018e3399f6321a07460eba and executes unchanged T1972 once. Both HDL targets and entry cases pass with successful observed native calls and exact cleanup. Complete saved evidence is docs/audits/native-group-witness-20260927/original/manifest.json. This supplies guard runtime evidence but does not attribute or repair the historical EPERM; HIAL .3.2.10.10 independently reverifies the saved observation and current source equality, satisfying this guard repair acceptance. Historical containment remains P1-open under .3.2.10/.11; its next observation is scheduled before genuine roadmap runtime.`
  Commit: `7ee298c6958a61ff5600c22d1de164ff23b4f6ca; runtime evidence at 85e7e9a59f2b8e382d9567036202521ce288e4f5; source/evidence reconciliation under HIAL .3.2.10.10`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2`
  Status: `active`
  Goal: `Collect qualified effective writer guards and arbitration evidence.`
  Acceptance: `After .1, implement the detached activation contract from actual emitted semantics, including DT and assignment guards, state-transition context kept separately, operator exceptions and resource/priority evidence. Preserve exact invocation sources; reject unsupported or malformed evidence rather than inferring exclusion. Prove actual carrier correspondence, omission/mutation controls and full report parity before completing this guard parent.`
  Verification: `pending`
  Commit: `children below`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.1`
  Status: `done`
  Goal: `Collect detached effective predicates for explicit state and DT assignments.`
  Acceptance: `Mirror actual emitter placement without calling the emitter as the collector oracle. Retain tagged raw/typed guard forms, state-active or DT-header enable, assignment enable and separately labeled state-transition context. Preserve zero/one, scalar/expression/comparison forms, rule groups and all supported assignment operators; refuse malformed/ambiguous or unqualified forms rather than inferring exclusion. State decrement guards are not emitted: qualify the actual unguarded producer and refuse invented guarded forms without claiming a production defect. Compare actual lowered/emitted carriers and strict replay, independently mutate guards/enable placement, preserve detached inputs and outputs. No production attachment, admission, grant proof or supervised HDL runtime belongs here. Commit before grant/suppression integration.`
  Verification: `WriterActivation resolves explicit assignment indexes into detached state-active/DT-header and assignment predicates, keeping state-transition context separate. It preserves raw guards and tagged truthy/comparison/always forms, validates structured expression text/AST agreement and distinguishes rule groups from suffixes. Unsupported/malformed forms and invented guarded state or DT decrements fail closed. T1973 compares actual inline samples, unconditional entry bookkeeping, latency comparisons, monitor enables, repeat decrement and false rule headers with emitted carriers and full native/carrier semantic replay. Fragment controls cover scalar/numeric/expression/comparison predicates and assignment operators without claiming each synthetic combination has an authored producer. Omitted guards independently change records and actual emitted text; returned nested records remain detached. Initial fixture corrections use documented when rather than compound on and retain the internal captured alias without an output marker. Guarded T1973/T1970/T1971 pass All tests successful, Files=3, Tests=11. No production caller or runtime invocation is added. Public sync scope: private helper/test plus book/fact/task; source syntax, lowering, HDL, public diagnostics/reports/facade/manifest and downstream integration contract remain unchanged. Resource/priority consistency and complete producer/public parity remain .2/.3.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2`
  Status: `active`
  Goal: `Join actual resource, priority and invocation evidence to qualified writer predicates.`
  Acceptance: `After .1, retain complete actual resource grants and assignment-local suppressors with exact local/generated invocation associations. Validate producer consistency and reject omitted/malformed evidence; never infer mutual exclusion from metadata or source ownership alone. Qualify priority/round-robin and both priority directions, source permutations and unchanged carriers/reports. Own any discovered emitted discrepancy before attachment.`
  Verification: `pending`
  Commit: `children below`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.1`
  Status: `done`
  Goal: `Root-cause and retain suspected same-owner priority suppression loss.`
  Acceptance: `P1 candidate found during evidence collection: _suppress_priority_assignment overwrites suppressed_by indexed by higher owner, although one transaction may write the same target in multiple states. Build a minimal actually admitted transaction-over-rule source with distinct higher-state writes and lower conflicting rule; inspect public schedule, carrier and semantic selectors. Compare a single-state control and source/state ordering without inventing a producer. Retain exact source and current output, identify the historical introducing change and own any confirmed repair before further evidence collection. No HDL runtime belongs to this baseline; separately qualify HIAL .3.2.10.11 observation before genuine runtime repair verification. Commit the diagnosis and precise next repair scope.`
  Verification: `Confirmed P1: single-state, multi-state and reversed-value sources all strict-admit with empty compile issues. Multi-state public schedules list both main writers/resolutions, but the lower fallback output guard retains only main_set_2; main_set_1 is lost regardless of value ordering. The single-state control retains its only condition and the unrelated side output stays unmasked. Public carrier and semantic selector reports agree. Under force=1 in main_set_1, both different-valued writers are statically enabled; this is not an executed HDL observation. _suppress_priority_assignment overwrites the owner-key slot. History distinguishes the rule-key predecessor at 3e5e916a90cbe09dd7474dd0c051ab6caa753ba2, generalization at 49711b6dbee775600d924da3f92819136c52c567 while transaction winners were rejected, and actual transaction-winner exposure at 7a3222a1a465e165d14569f1229f6887d6709f2f. Complete sources/check/schedule/carrier/semantic records, current/history hashes and hostile saved verification are sealed under docs/audits/priority-contributors-20260927/. The introducing mechanism is proved; runtime remains unmeasured. HIAL .3.2.10.11.1 qualifies the fixed failure-only observer before .2 repair/runtime; .3 evidence integration remains blocked on that repair.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.2`
  Status: `done`
  Goal: `Repair confirmed priority contributor loss with independent emitted and runtime oracles.`
  Acceptance: `After .1 establishes the actual defect, preserve every relevant higher writer condition without broadening suppression to unrelated targets or transaction progress. Keep deterministic output, same-value compatibility, priority/resource composition and native/API/newline parity. Qualify multi-state same-owner, source ordering, opposite priority, unrelated-target, reset/repeated and both HDL-target controls. Use legal override_req in runtime fixtures; .58 separately owns the baseline input force keyword boundary. Before runtime consume separately committed HIAL .3.2.10.11 observer integration; never weaken native admission. Update book/spec/downstream contracts and close only after signoff evidence.`
  Verification: `All children qualify the contributor union and its exposed assertion/test prerequisites. Static red/green and full public products establish the repair; the final observed T1974 completes all positive SystemVerilog/Verilog cases, repeated requests and synchronous reset, while the deliberately broken mask is rejected by the real different-value assertion. No native rejection occurs; historical native causality remains separately P1-open. Complete current evidence is in docs/audits/priority-runtime-qualified-20260928/. Grant/suppression/invocation integration resumes at sibling .2.3.`
  Commit: `this commit closes qualified children`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.2.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.2.1`
  Status: `done`
  Goal: `Commit the qualified contributor-union implementation and first runtime blocker evidence.`
  Acceptance: `Retain the red static regression and exact repair; qualify all emitted predicates, existing priority/resource/invocation controls and complete native/API/newline/carrier products. Preserve the first observed HDL failure and source/observer identities, exact stage results and cleanup. Document the admitted same-value assertion blocker without claiming complete runtime or native-cause repair. Commit this independently verified implementation/evidence slice before changing the assertion policy.`
  Verification: `Red static control fails exactly the lost contributor cases; focused suite passes five files and 29 top-level tests with HDL skipped. First genuine observation compiles SystemVerilog, then runtime exits one at time 55: selector same-value conflict: out 9 in priority_compatible. Native events are empty and both completed stages retain successful process cleanup. The independent saved verifier retains exact red/green logs, test versions, production blob identities, first admission/results and reconstructed public check/semantic/RTL products. It rejects false runtime completion, native-failure attribution, changed bounds, lost admission and false cleanup. Native PID absence is not independently measured on the intentionally silent success path; exact workspace and selected-command residue are independently absent. Its initial expected-stage oracle assumed strings; the actual canonical admission uses integers, and the corrected reader passes without changing producer evidence. Diagnosis belongs to .2; remaining runtime qualification belongs to .3.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.2.2`
  Status: `done`
  Goal: `Resolve admitted same-value overlap rejected by the emitted SystemVerilog selector assertion.`
  Acceptance: `P1 prerequisite for this repair: reproduce through the existing compatible T1974 source; root-cause the accepted source versus emitted selector contract before further runtime. Inspect public compatibility rules, actual selector origins and relevant history. Preserve genuine different-value conflict checks and established compatible-write behavior. Qualify the smallest metadata/emission correction with independent allowed-overlap and forbidden-conflict controls, preserving the existing report key families. Commit this static contract repair before sibling .3 performs actual observed positive/negative runtime; never disable runtime assertions or weaken process admission. Retain complete source/evidence and synchronize book/spec/downstream before commit.`
  Verification: `Root cause traced without further execution: GeneratedModuleEmitter::selector_conflict_assertion_runtime_lines emits onehot0 for every multi-source same-value family from LoweredRTLIRBuilder. The admitted compatible source ORs fallback_out__9_en with main_set_1_out__9_en; both are enabled at main_set_1 with override_req=1. The independent emitted-equation witness confirms this allowed overlap, while the first runtime fails that assertion at time 55. git log -S traces assertion introduction to fd3317ef93c8ea5901c53fd507ce2f2cf9672b3d. T1211 checks emission text, not execution of the compatible case. Complete first evidence and public reconstruction are in docs/audits/priority-contributor-repair-20260928/. No second target or retry ran. Active from clean a7fc9a98d1217d98f817c8d4c84448a8e1a762cc. Select compatible_fanin metadata under the legacy same_value_assertion key for OR-coalesced sources; preserve different-value onehot0 and separate standalone/composition policies. Decision 0111 owns the interpretation. Red T1211 fails exactly the policy-kind and forbidden same-value assertion expectations. Corrected T1211 plus contract/standalone/composition controls pass Files=4, Tests=9; T1974 plus public report/manifest controls pass Files=3, Tests=16, with HDL runtime explicitly skipped. Fresh complete public semantic output differs only in same-value policy kinds; complete HDL differs only by removal of the invalid assertion and its generated Date comment. Both original dates are retained, and the verifier excludes exactly one anchored Date line per artifact. Explicit onehot0 metadata still emits its check. The sealed static audit and hostile comparisons are in docs/audits/same-value-selector-repair-20260928/. Corrected runtime remains sibling .3; no native or HDL execution claim follows from these static checks.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.2.3`
  Status: `done`
  Goal: `Complete observed two-target priority runtime qualification after the assertion contract repair.`
  Acceptance: `Consume committed .1/.2 and the qualified native observer. Complete every T1974 source/priority/resource/drive/order/compatible/reset/repeated/progress oracle for SystemVerilog and Verilog, retaining first attempts, full stage evidence, source identities and cleanup. Add an independent negative fixture by restoring the previously lost first-state mask on a cloned actual carrier: the retained different-value assertion must reject that overlap with its precise diagnostic. Keep runtime assertions enabled. A native rejection or unexpected HDL outcome requires diagnosis before further execution. Close the priority contributor parent only after all acceptance holds; a successful run cannot close historical native causality.`
  Verification: `The first corrected observation exposed only the testbench synchronous-reset timing mismatch; child .1 retains and statically corrects it. Child .2 completes the unchanged corrected test under fresh qualified observation: all positive target and deliberately broken-mask controls pass with original stage bounds and cleanup. Full parent runtime acceptance is now satisfied; historical native causality is not attributed.`
  Commit: `this commit closes qualified children`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.2.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.2.3.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.2.3.1`
  Status: `done`
  Goal: `Diagnose and correct the first post-repair reset-oracle failure before further runtime.`
  Acceptance: `Retain the complete first corrected observation, unchanged identities and cleanup. Reproduce the reset timing contract through public metadata/emission and inspect exact test event ordering. Distinguish test-oracle mismatch from production defect; fix only the proved cause with independent timing controls. Preserve every priority/value/progress oracle, runtime assertions and native admission. Commit static repair/evidence before .2 executes again. No runtime pass is claimed by this leaf.`
  Verification: `At time 311 check_reset fails after the bench asserts rst_n at a falling edge and waits one time unit. The initial check had waited through rising edges. Root cause proved by canonical explicit-system-reset-polarity and book13a: flat reset rst_n is synchronous active-low. The retained full public semantic system contract says sync/sreset/active-level-zero, and emitted state/output registers use only posedge clk. The mid-run bench checked at falling-edge+1 before any reset-active rising edge, unlike its initial reset. Fix only the bench to span the next rising edge; add independent parsed/carrier reset expectations. Production code and observer stay unchanged; no retry executed. The negative fixture restores exactly one missing contributor in a cloned actual carrier and preserves its positive source. Static T1974/T1211 passes All tests successful, Files=2, Tests=7, with native runtime skipped. The saved event-order model derives the failing check at 311 before any reset-active rising edge and the corrected check at 321 after one, independently of the runtime oracle. Full prior/preflight/observed/corrected test sources, complete logs, two stage records, additional backend identities and hostile saved verification are sealed under docs/audits/priority-reset-oracle-20260928/. The original temporary HDL/binary are removed by normal cleanup; the unchanged-backend public reconstruction is labeled as such. No full two-target or negative execution result is claimed. Public sync scope: fixture and qualification documentation only; source syntax, production lowering/reset behavior, reports, facade and capability metadata unchanged.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.2.3.2`
  Status: `done`
  Goal: `Finish observed two-target and negative runtime after reset-contract correction.`
  Acceptance: `Consume all committed failures and static repairs, then use a fresh admitted failure-only observation for actual T1974. Require full positive and deliberate different-value rejection oracles, source identity, original bounds and cleanup. Stop and diagnose any unexpected result before further execution. Historical native cause cannot close on a pass.`
  Verification: `Fresh priority_reset_corrected observation consumes committed fa4546704a8fc52ca6dbdefe1f1eb74e90ff0a67 with no test/production/observer changes. Guarded prove reports All tests successful, Files=1, Tests=4. All nine source cases retain complete native/API/newline/carrier parity; SystemVerilog and Verilog each complete ordered writer values, opposite priority, compatible overlap, named drive, the resource-gated case with peer_req low, unrelated output progress, repeated requests and synchronous reset. The isolated missing-contributor carrier compiles, then exits one with the exact selector multi-value conflict diagnostic; no assertion flag is disabled. All six predeclared stages retain original results/bounds and complete supervisor cleanup; input identities agree before/after, native events and capture/retention gaps are empty. Independent postcheck finds no workspace or matching command; successful-child PID identities are not independently recorded. The exact committed test, full logs/stages, additional backend/report hashes and hostile saved verifier are sealed in docs/audits/priority-runtime-qualified-20260928/. Original generated HDL/binaries follow normal test cleanup, explicitly stated rather than claimed retained. This closes the priority repair only; grant/invocation collection, general writer admission, historical native causality and broader startup/full CI remain separate. Public sync scope is qualification evidence/book/spec/downstream/fact/task; no source syntax, production code, report schema, facade or capability key changes.`
  Commit: `this commit closes qualified children`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.3`
  Status: `active`
  Goal: `Join qualified grant, suppression and invocation evidence after contributor repair.`
  Acceptance: `After .1/.2, complete the parent resource/priority/invocation association contract against actual producer records and effective predicates, preserving all contributors and rejecting omitted/malformed evidence. Split further if necessary; no metadata-only exclusion proof or production admission promotion.`
  Verification: `Scoped from clean 588028b01271a706ec78c0f66a4b5e1a00bd0b70 after complete priority repair. Qualify declaration/root/DT grant correspondence first, then predicate/suppression semantics and invocation integration. No production attachment or native runtime in the first child.`
  Commit: `pending`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.3.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.3.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.3.1`
  Status: `done`
  Goal: `Collect detached resource grants with complete declaration/root/DT correspondence.`
  Acceptance: `Add a private collector joining actual actor resource/user declarations, module resource_arbitration grants and explicitly owned rule DT resource_grants. Preserve resource kind, arbiter, user, higher/peer lists and members without treating those names as an exclusion proof. Reject missing/extra/duplicate/malformed grants, unknown users and inconsistent DT mirrors, including simultaneous root/DT omission caught by declarations. Support priority and round_robin plus unbound declarations, actual source identity after DT rename, and detached/nonmutating records. Qualify real emitted carriers and public report parity with independent expected records. This child does not rederive priority ordering, prove grant predicates, attach assignment annotations or change production admission; child .2 owns those remaining semantic joins. No supervised HDL runtime belongs here.`
  Verification: `WriterResourceGrants::collect receives the actual actor as its independent declaration witness, validates complete module grant rows and explicitly owned rule-DT mirrors, and returns detached grant/owner records. It preserves resource policy, member ordering and higher/peer lists; round-robin completeness follows the declared user order. Declared users catch simultaneous root/DT deletion. Unknown/duplicate/missing/malformed records, wrong policy/members, self/unknown suppressors and inconsistent mirrors reject. T1975 covers every currently supported resource kind with both arbiters, unbound backlog declarations, multiple resources, reordered authored rules, renamed DTs, deep detachment and exact unchanged carriers. Every fixture strict-checks and has complete native/carrier semantic equality; priority/round-robin rule-slot schedules additionally agree through native/API/newline. Guarded focused T1975 passes All tests successful, Files=1, Tests=3; related T1973/T1970/T1218 passes Files=3, Tests=22. Initial authoring errors used name instead of the parser actor_name field and omitted the mandatory arbiter on the unbound fixture; both were corrected from the actual parser contract before these passing runs. Only T1975 imports the new private helper. No priority ordering re-derivation, effective-grant proof, legacy assignment annotation completeness or production attachment is claimed. Public sync scope: private helper/test and book/spec/downstream/fact/task; source syntax, scheduler emission, public schema/facade/capability metadata remain unchanged. Child .2 owns semantic joins.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.3.2`
  Status: `active`
  Goal: `Join validated grants and priority suppressors to actual assignment predicates.`
  Acceptance: `After .1, qualify actual grant condition and target-local suppression semantics against producer records, authored requests and emitted guards. Preserve multiple resources, priority/round_robin distinctions, both priority directions and all higher contributors. Keep source annotations separate from effective container/assignment guards; qualify generated assignments added after arbitration without inventing complete legacy annotations. Reject omitted or inconsistent evidence before attachment; no metadata-only exclusion proof. Split further if needed before code changes.`
  Verification: `Scoped from clean 8513cef4254db4572ab8dd3c94f3953df358f0a9. Existing grants describe source users and peers, while effective guards are destructively combined in resource declaration order. Preserve actual pre-grant requests and each transformation before validating semantic joins; do not infer input conditions from final names or owner lists. Children separate producer evidence, resource validation, priority contributions and combined assignment coverage.`
  Commit: `pending`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.3.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.3.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.3.2.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.3.2.4`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.3.2.1`
  Status: `done`
  Goal: `Retain private resource activation evidence from the actual arbitration producer.`
  Acceptance: `Capture detached original rule request guards and one ordered before/after transformation record per actual resource grant, including unchanged highest-priority grants and round-robin permission/pointer identity. Use actual producer inputs and selected declarations; do not reconstruct identities from naming conventions. Preserve zero/unconditional/compound requests, multiple resources and both arbiters. Qualify deep detachment, exact emitted carriers and complete baseline/current public products. No public schema keys, grant policy, guard expression, source admission or native runtime change. Commit producer evidence before semantic validation.`
  Verification: `T1976 red baseline fails both missing-evidence subtests at unchanged 8513cef4254db4572ab8dd3c94f3953df358f0a9. Producer capture now preserves original raw guards/source owners/expressions and ordered priority or round-robin before/after steps, actual suppressor inputs and selected pointer/update identity. Guarded focused final: Files=1, Tests=3 PASS; T1975/T1973/T1944/T1218: Files=4, Tests=24 PASS. Complete baseline/current executable IR (excluding only the new private field), carriers, check/schedule/semantic JSON and API/newline products agree for all ResourceActivationFixture cases. Logs and snapshots: .artifacts/resource-activation/. No native HDL runtime or public contract change. Semantic validation follows .2.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.3.2.2`
  Status: `done`
  Goal: `Validate resource activation evidence against declarations and actual predicates.`
  Acceptance: `After .1, join the qualified grant catalog to original requests, complete ordered transformations and final DT header predicates. Require independent priority and round-robin selection controls, literal/compound requests and multiple-resource composition; reject missing/inconsistent intermediate or final evidence. Validate actual pointer identity/update association without inferring from prefixes. State explicitly any boundary that prevents exclusion proof and keep the helper detached from production admission.`
  Verification: `WriterResourceActivation joins complete authored-rule/request/DT coverage to ordered grant steps and actual final headers. It independently reconstructs priority reachability and circular permissions and validates selected pointer storage/update identity, including unbound rules and consistently renamed containers. T1977 focused final: Files=1, Tests=4 PASS; T1975/T1976/T1973/T1944/T1218: Files=5, Tests=27 PASS, including all resource kinds and complete native/API/newline/carrier parity. Initial T1977 oracle incorrectly used reversed resource user order for priority in mixed resources; exact declared high-over-middle-over-low ranking corrects that test-only error. Hostile controls reject matching incomplete grant copies, changed inputs/chains/headers and pointer/permission corruption. No production caller, public key, admission or native runtime change. Logs: .artifacts/resource-activation-validation/. Director-prioritized SPECFORGE intake .60.3.1 precedes further writer work.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.3.2.3`
  Status: `pending`
  Goal: `Retain and validate all target-local priority suppression contributors.`
  Acceptance: `After resource evidence qualification, join every actual higher contributor and original assignment predicate to target-local suppression. Preserve both priority directions, multiple same-owner states/drives, same-value compatibility and independent invocation identities; reject omissions and malformed associations with emitted and independent controls. Do not treat source owner names as controller-wide exclusion. Split further before edits if the producer and validator require independent slices.`
  Verification: `pending .1/.2`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.3.2.4`
  Status: `pending`
  Goal: `Qualify combined grants and suppressors across complete explicit assignments.`
  Acceptance: `After .1-.3, cover actual user and generated assignments, including records appended after arbitration, against effective container and assignment predicates. Keep legacy source annotations separate from actual guards, preserve exact detached products and full public parity, and own any discrepancy before invocation integration or whole-collector admission.`
  Verification: `pending .1-.3`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.3.3`
  Status: `pending`
  Goal: `Integrate exact invocation associations with qualified grant/suppression evidence.`
  Acceptance: `After .1/.2, retain actual local/generated invocation associations and require complete explicit assignment coverage with detached immutable output, source permutations, omitted/mutated associations and full native/API/newline/carrier parity. No shadow admission promotion before the separate whole-collector qualification leaf.`
  Verification: `pending .1/.2`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.3`
  Status: `pending`
  Goal: `Qualify the complete detached activation collection and public parity.`
  Acceptance: `After .1/.2, require complete explicit assignment coverage across actual parent/generated/domain producer families and operator/guard shapes, exact source ownership and invocation joins, stable detached products and omission/mutation controls. Compare complete native/API/newline reports and strict carrier replay. Keep emission-generated assignments and helper ownership under their explicit later owner; do not advertise a complete physical inventory until those gates pass. Any genuine HDL runtime first consumes HIAL .3.2.10.11 observation ownership.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.4`
  Status: `pending`
  Goal: `Collect generated handoff, completion and helper writer ownership.`
  Acceptance: `After source producer ownership, inventory every post-binding/generated-handoff assignment with explicit module/domain and source-instance relationships. Conservatively retain multi-caller and helper activation uncertainty; prove omitted and malformed ownership failures before shadow inventory attachment.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.3`
  Status: `pending`
  Goal: `Qualify and attach the complete detached physical writer inventory in shadow mode.`
  Acceptance: `After .2, require deterministic complete assignment coverage, valid explicit controller/module ownership and actual physical target ranges across source permutations and module/domain boundaries. Inventory all writer categories from the parent acceptance contract and prove missing/malformed record controls, complete native/API/MCP/carrier parity and focused regressions. Keep executable admission changes in .3 and independent-controller promotion in the next sibling.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.3`
  Status: `pending`
  Goal: `Require sound physical writer compatibility before independent-controller promotion.`
  Acceptance: `After .2, integrate conservative admission using physical overlap, same-controller state exclusion, qualified equal-value/pulse compatibility and actual disjoint predicates/grants. Refuse unproved cross-controller data overlap or ambiguous activation ownership with actionable public diagnostics. Preserve generated-child ownership boundaries and existing rule/resource behavior; parsed transaction priority alone is not a grant. Qualify source/declaration permutations, complete native/API/newline failures and success reports, strict carriers and relevant regression/book gates before enabling independent execution in .4.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.4`
  Status: `pending`
  Goal: `Emit independent controller execution through the public IAL0 carrier.`
  Acceptance: `After shadow ownership, scoped identities and admission .3, implement private controller registers and guarded DT bodies with translated logical state predicates. Preserve all admitted state kinds, assignment edges, source provenance, exact ports and qualified reset behavior. Turn the declaration-order baseline into production runtime passes for concurrent short/long work, separate/repeated triggers and reset. Qualify point/assertion and rule-priority consumers, public replay and reports; do not infer local-call signoff from this leaf.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.5`
  Status: `pending`
  Goal: `Repair local-call entry, one-shot activation and payload/completion timing.`
  Acceptance: `After .4, replace unreachable local-call wiring with independent owned caller/callee execution. Install called-body entry when absent, retain a single invocation per held request, capture caller-scoped snapshot inputs on acceptance and copy outputs only on fresh completion. Prove both declaration orders, authored/missing callee entry, repeated/nested acyclic calls, changed inputs, early samples, reset and terminal holds. Diagnose unproved recursive/multiple-caller or mixed activation ownership explicitly. Then run .49.2.3 scope qualification before broad closure.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.6`
  Status: `pending`
  Goal: `Qualify the complete controller repair and synchronize shipped contracts.`
  Acceptance: `After .4/.5 and .49.2.3, run the broader regression gate plus focused SystemVerilog/VHDL runtime, state/point/priority, local and generated activation, domain/reset and complete native/API/MCP parity. Require exact ownership and interfaces with no hidden public selector ports. Update the book/spec only from qualified production behavior, remove only repaired warnings and retain watchdog/other owned gaps. Commit before resuming broader storage writer and access metadata work.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.2`
  Status: `pending`
  Goal: `Complete broad multi-clock event/activation behavior and public-query qualification after the owned repairs.`
  Acceptance: `Execute the parent qualification scope with no missing repair dependency, retain independent behavior/reset controls and complete native/API/newline reports plus emitted-artifact admission, update book/facts and close the parent only from successful evidence.`
  Verification: `Requires .32.1.3.3.1, .32.1.3.3.3 and .32.1.3.4.3 as well as the existing wiring/reset/naming repairs; strict admission is not behavior qualification.`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.3`
  Status: `pending`
  Goal: `Initialize external activation callee watchdogs before evaluating a leading await.`
  Acceptance: `Reproduce premature completion with ready held low using the retained original ready/work_ready sources and pin-driven oracle. Repair watchdog initialization and rearming across synthetic callee entry without weakening timeouts. Cover leading-await, folded-sample and ordinary-entry controls, repeated activations, reset and actual timeout outcomes through generated artifacts, independent HDL behavior and native/API/MCP; update book/facts and commit before .32.1.3.3.2.`
  Verification: `T1896 reports expected 0 activations, done=1 observed=0 for both original ready and unchanged work_ready controls. _inj_watchdog initializes the first state; _wire_external_activations later inserts worker_idle_ext without moving initialization. The emitted worker_await_0 tests reset worker_wd=0 in the same cycle that assigns limit-1, transitions through worker_timeout and acknowledges completion without observed. Exact baseline work_ready HDL and failing TAP are retained by .32.1.3.4.2; do not claim that original actor behavior is qualified.`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.4`
  Status: `done`
  Goal: `Preserve logical domain and public signal identities through generated top naming and wiring.`
  Acceptance: `Reproduce a public actor with domain bus, trace admission versus generated instance naming, and repair that boundary while preserving logical domain/report identities. Audit collisions and keyword/case variants; qualify actual generated tops and API/MCP behavior. Update book/facts and commit before .32.1.3.3 behavioral closure.`
  Verification: `The .32.1.3.1 activation control parses and lowers domain bus, but strict and compatibility HDL both refuse generated ?fsmc:bus as reserved in VHDL. Parser::_parse_clock_domains admits scalar identifier-shaped names; Scheduler::ISF::_emit_domain_instance copies the logical name verbatim. Initial failing focused-final.tap under .artifacts/isf-multiclock-strict/ retains native/API failure evidence. The syntax-only control uses peripheral after this independent gap is owned; no bus-domain HDL support is claimed by .32.1.3.1.`
  Collision extension: `After using portable domain peripheral, top input ready still fails despite an emitted explicit (ready peripheral.ready) link: CDC ready outputs form a mixed-direction same-name family. SameNameLinkBuilder::build_top_input_links computes explicit_sources/targets but rejects the direction family before using those exclusions. focused-verified.tap retains the public refusal. Decompose .32.1.3.4 into independent domain-name and explicit-route collision repairs before implementation; do not weaken portable identifiers or silently rename authored public ports. Syntax qualification uses work_ready to isolate this separate composition defect.`
  Commit: `children below`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.4.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.4.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.4.3`


- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.4.1`
  Status: `done`
  Goal: `Allocate portable generated multi-domain child names while preserving logical ISF identities.`
  Acceptance: `Reproduce the bus-domain refusal at the current reset-qualified revision through public parse/lower and real strict CLI. Reuse the existing portable generated-instance policy, audit domain/event/activation/public-pin and case-folded collision namespaces, and keep authored domain names and public pins stable. Carry the allocation consistently through declarations and every route; expose enough stable public report/artifact identity to relate logical domains to generated hardware. Qualify strict artifacts, unchanged non-collision controls, independent behavior and complete native/API/MCP reports. Allocate case-safe scheduled module/file identities as well as child labels; public lowering and filesystem materialization must preserve every domain. Join logical domains to physical children through existing scheduled_fsm and composition-child identity fields without leaking a private naming map. Update book/spec/facts and commit before explicit-route repair.`
  Verification: `T1895 passes Files=1 Tests=13 with actual strict materialization, logical/physical report joins, complete native/API/newline MCP equality and non-skipped SystemVerilog/Verilog public-pin behavior. Original event, dual-event and no-reset HDL match the baseline except Date headers. The focused existing regression exposed expected stale bus-label/private-partition fixtures in T1247/T1387; corrected public-boundary tests pass Files=2 Tests=26, and the other selected tests passed unchanged. Exact before/after reports, overwritten baseline file content, fresh book render, producer hashes, commands, successful/failed receipts and owned independent defects are retained in docs/audits/specforge-rule-admission-20260924/generated-domain-names.json. Staged doctrines and normal hooks are required before commit.`
  Commit: `this commit; subject carries SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.4.1`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.4.2`
  Status: `done`
  Goal: `Honor explicit top-input routes before incompatible same-name inference.`
  Acceptance: `Reproduce the ready input collision after generated-name repair; make explicit-route ownership precede same-name family inference without weakening actual explicit-link direction/width/type/driver validation. Cover input/output name collisions, explicit source/target controls, ordinary inferred fanout and invalid explicit wiring; qualify the original activation topology and native/API/MCP success/failure identities. Preserve authored ports, synchronize book/facts and commit before broader .32.1.3.3 qualification.`
  Verification: `Current original ready/direct-composition strict checks and semantic queries fail before repair while work_ready passes; after moving explicit ownership ahead of same-name checks all original source queries pass. T175/T176 pass Files=2 Tests=15, preserving unrelated-family refusals and actual explicit-link width/type/direction/driver checks. T1896 passes Files=1 Tests=8 with full native/API/newline success/failure reports and non-skipped SystemVerilog/Verilog pin-driven activation controls using an ordinary entry. Existing composition/T1890 regression passes Files=5 Tests=22. Original work_ready HDL is unchanged except Date headers. The original leading-await runtime failure, folded-sample probe, explicit-entry passing control, exact reports, hashes and fresh book render are retained in docs/audits/specforge-rule-admission-20260924/explicit-input-routes.json; .32.1.3.3.3 owns the independent watchdog defect. Staged doctrines and normal hooks remain required before commit.`
  Commit: `this commit; subject carries SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.4.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.4.3`
  Status: `done`
  Goal: `Preserve authored unused actor interface inputs through generated artifacts.`
  Acceptance: `Reproduce missing unused input endpoints using collision-free domains and the shared ordinary actor lowering path; preserve authored input interface ownership in parent/domain modules without changing used-port behavior or exporting unrelated generated-child inputs. Qualify strict materialization, scalar/vector and symbolic-width declarations, semantic/API/MCP identities and unchanged controls, synchronize the book and commit before broader runtime closure.`
  Verification: `T1897 passes Files=1 Tests=6 with actual strict exports, ordinary/named-single/domain scalar/vector/symbolic input identity, complete native/API/newline MCP equality, unrelated-child exclusion and non-skipped SystemVerilog/Verilog event/reset behavior while unused pins toggle. Used-input HDL is unchanged except Date headers. The selected regression found stale T1330 interface-role lists and pre-existing T1215 slash-route expectations; baseline-overlay proof and corrected reruns pass Files=1 Tests=66 and Files=1 Tests=100, while the other eight selected files passed unchanged. Exact baseline/repaired reports, artifacts, commands, failed/passing TAP, producer hashes and fresh book render are retained in docs/audits/specforge-rule-admission-20260924/declared-input-preservation.json. Staged doctrine and normal hook gates remain required before commit.`
  Commit: `this commit; subject carries SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.4.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.2`
  Status: `pending`
  Goal: `Prevent issue bundles from attributing an exported FSMGen copy to a foreign enclosing Git revision.`
  Acceptance: `Reproduce sf-tool-issue-bundle-foreign-git-head in an isolated repository-local fixture. Require demonstrable FSMGen repository identity or unknown consistently in bundle records; qualify a real checkout, non-Git export nested in a foreign repository, and relevant environment/worktree controls. Preserve public helper/capability contracts. Document complete exact-revision export setup and known-good preflight before downstream differential censuses; never repair an old export with current-revision resources.`
  Verification: `Caller bundle: ../specforge/docs/fsmgen-issues/sf-tool-issue-bundle-foreign-git-head/README.md; SPECFORGE owner FSMGEN-REQUESTS.3. Current reproduction pending; bundled default temporary-directory behavior must not be used.`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.3`
  Status: `pending`
  Goal: `Support bounded derived actor width parameters with symbolic dependency preservation.`
  Acceptance: `Coordinate the generic-width foundation under .33.3, audit existing public expression contracts, then decompose sf-isf-derived-width-parameter into bounded parameter resolution, symbolic lowering/emission, ceiling arithmetic and clog2, refusal diagnostics, and semantic/API/MCP qualification leaves. Verify default and overridden widths independently in emitted HDL; document derived-parameter override policy, integer division meaning and intentional optional inline-width boundary. Reject undeclared/later/cyclic/runtime operands, zero divisors and invalid widths. Preserve existing scalar/aggregate parameter behavior.`
  Verification: `Caller bundle: ../specforge/docs/fsmgen-issues/sf-isf-derived-width-parameter/README.md; SPECFORGE owner FSMGEN-REQUESTS.1. Current reproduction and contract reconciliation pending. Reported corpus counts remain externally supplied claims.`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.4`
  Status: `pending`
  Goal: `Repair emitted protocol ISF artifacts that bypass executable IAL1 lowering.`
  Acceptance: `Before derived-width feature work, audit generated ISF round-trip admission against published artifact contracts. Root-cause every refusal and decompose repairs by protocol and safe lowering boundary. Require generated ISF to be executable through the public ISF parser/scheduler where advertised, preserve protocol-specific behavior with independent HDL oracles, remove parallel handwritten IAL0 bypasses, and synchronize report/API/MCP/book claims. Do not introduce IAL2-only syntax into ISF or relabel executable artifacts as mere review prose to close the defect.`
  Verification: `The .32.1.1 compatibility probe obtains ahb_interconnect.isf from the public PPIF adapter for ppif/ahb_interconnect.ppif; ISF admission fails at unknown actor clause address-map. AhbInterconnect::_build_ahb_interconnect_artifacts separately calls _build_ahb_interconnect_isf and _build_ahb_interconnect_fsm; the first emits address-map/decode/behavior clauses unsupported by Parser::_build_actor, while normal source generation uses the separately built FSM. Existing knowledge calls these review artifacts, but docs/book/src/14i-ahb-and-integration.md claims lowering through ISF and IAL2-FEATURE-COMPLETENESS-FRONTIER forbids bypassing that chain. This is a pre-existing architecture/documentation gap, not evidence that the new operand validator rejects valid rules. Root-cause evidence is retained under docs/audits/specforge-rule-admission-20260924/; full artifact census and repair remain owned here.`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33`
  Status: `active`
  Goal: `Deliver SPECFORGE configuration, verification and phase-metadata requests with complete public semantic API/MCP coverage.`
  Acceptance: `Read the director-supplied packets, reproduce current public behavior, answer the strict-port question, and own each required/optional request through bounded implementation leaves. Preserve existing runtime repair obligations and the derived-width dependency; no request is closed by intake or parser acceptance alone.`
  Verification: `Caller-authorized read-only inputs: ../specforge/docs/upstream/fsmgen/sf-isf-{actor-level-assertion,generic-port-widths,known-value-predicate,optional-signal,parameter-value-set,strict-unknown-port-clause,transaction-phase-groups}/README.md. All README texts and minimal sources read; fresh native reproduction and independent controls retained in docs/audits/specforge-feature-intake-20260926.json. Caller corpus quantities are not independently verified.`
  Commit: `children below`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.4, SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.5, SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.6, SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.7, SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.8, SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.9`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.1`
  Status: `done`
  Goal: `Reproduce and integrate the new SPECFORGE requests, answer the strict-port question, and establish ordered repair/feature leaves.`
  Acceptance: `Use complete current FSMGen resources and repository-local copied caller fixtures, never execute foreign bundle scripts or modify SPECFORGE. Retain exact source/request hashes and native strict reports, diagnose silent acceptance at its code locus, reconcile phase guidance and generic/derived widths, and assign every requirement a concrete owner with report/API/MCP and independent behavior evidence requirements. Update book, bounded resume pointer and durable response, then commit before implementation.`
  Verification: `passed; exact caller inputs, native strict checks/generation, literal/driven output controls and real HDL width-override oracle retained in docs/audits/specforge-feature-intake-20260926.json. Final replay captures all retained sources with unchanged check outcomes; negative destination controls reject before writes. Fresh mdBook render and T1414 docs-path checks pass. Six feature families and required/optional children owned; question answered in the existing tracked response. Caller-wide impact and future feature implementation are not qualified.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.1: answer SPECFORGE feature requests and strict-port question`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.2`
  Status: `done`
  Goal: `Reject unsupported or malformed actor interface-port options instead of silently discarding them.`
  Acceptance: `Answer sf-isf-strict-unknown-port-clause as a validation defect. Reproduce bogus-clause/present and malformed scalar/empty/nested option shapes through public parse, strict check, semantic and schedule queries. Reject unrecognized options at the shared parser boundary with named port/option diagnostics in default and strict modes; retain width/type/domain/reset/default behavior and targeted duplicate/arity/type errors. Census first-party producers and qualify unchanged valid controls. Do not accidentally implement optional presence while refusing its currently unsupported spelling. Every shipped slice synchronizes supported syntax, capability/diagnostic contracts, semantic and schedule API/MCP reports, book/examples and independent positive/negative checks before its commit.`
  Verification: `passed; T1898 native default/strict parser/check/semantic/schedule and real API/newline MCP controls, T1899 supported ISF/IAL2 producer census, existing width/type/domain/output metadata and public-contract band, T1414, syntax and fresh rendered mdBook. Schedule API failures retain the existing message-only boundary; no new schema or optional syntax.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.2: reject unknown and malformed actor port options`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.3`
  Status: `active`
  Goal: `Deliver generic parameter-dependent port widths and safe shape overrides; coordinate the earlier derived-width request.`
  Acceptance: `Complete the exact child slices; active denotes an owned container, not shipped capability or simultaneous implementation.`
  Verification: `pending; caller request and fresh baseline owned by .33.1`
  Commit: `children below`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.3.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.3.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.3.4`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.3.1`
  Status: `pending`
  Goal: `Define and preserve authored width dependencies separately from resolved default widths.`
  Acceptance: `For sf-isf-generic-port-widths R1/R4, audit existing IAL0 parameterized-size and IAL1 width contracts; preserve symbolic dependency and resolved width without guessing from equal numeric values. Cover actor, transaction and library parameter scopes, parameter/constant distinction, type references, resets, parameter aliases and public report schema evolution. Document the currently fixed-default HDL behavior immediately; a misleading unused parameter must not imply supported shape configurability. Every shipped slice synchronizes supported syntax, capability/diagnostic contracts, semantic and schedule API/MCP reports, book/examples and independent positive/negative checks before its commit.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.3.2`
  Status: `pending`
  Goal: `Emit generic port, register, expression and reset widths consistently.`
  Acceptance: `After .3.1, implement symbolic width propagation for supported HDL backends through the public IAL1-to-IAL0 path. Every dependent port, temporary/register, reset and width-sensitive constant follows the parameter; unrelated equal-width signals remain independent. Prove an actual HDL DATA_WIDTH override to 64 changes the port and matches separately generated default-64 behavior, while the fixed-width baseline remains unchanged. Unsupported backend shapes fail closed; no textual HDL post-processing. Every shipped slice synchronizes supported syntax, capability/diagnostic contracts, semantic and schedule API/MCP reports, book/examples and independent positive/negative checks before its commit.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.3.3`
  Status: `pending`
  Goal: `Re-specialize parameter-driven interfaces at library, activation and generated-top use sites.`
  Acceptance: `For R2, recompute per-instance widths from explicit/inherited overrides before binding validation, preserving instance independence and stable identities. Cover exact-width binding and stale default-width refusal, nested supported scopes, generated tops and existing transaction parameter behavior. Coordinate .32.3 derived dependencies and .33.4 legality constraints without bypassing those contracts. Every shipped slice synchronizes supported syntax, capability/diagnostic contracts, semantic and schedule API/MCP reports, book/examples and independent positive/negative checks before its commit.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.3.4`
  Status: `pending`
  Goal: `Qualify generic-width legality and the complete parameter-to-HDL contract.`
  Acceptance: `Reject nonpositive/noninteger width settings at source/use-site and exposed HDL elaboration boundaries where applicable. Exercise independent elaboration/runtime overrides, constant/reset sizing and direct/derived width controls; expose authored dependency, default and specialized shape to agents. Resolve R3 explicitly: ship real generic behavior or clearly bound any still-fixed surface without silently presenting a configurable width. Every shipped slice synchronizes supported syntax, capability/diagnostic contracts, semantic and schedule API/MCP reports, book/examples and independent positive/negative checks before its commit.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.4`
  Status: `active`
  Goal: `Carry legal parameter value sets and recommendations through defaults, overrides and reports.`
  Acceptance: `Complete the exact child slices; active denotes an owned container, not shipped capability or simultaneous implementation.`
  Verification: `pending; caller request and fresh baseline owned by .33.1`
  Commit: `children below`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.4.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.4.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.4.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.4.4`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.4.1`
  Status: `pending`
  Goal: `Parse and validate scalar parameter value sets and inclusive ranges.`
  Acceptance: `For sf-isf-parameter-value-set R1, define union semantics for values/range clauses and validate integer members, inclusive bounds, nonempty sets, scalar-only use and default membership. Preserve plain NAME/value and existing aggregate defaults. Reject illegal defaults, reversed ranges, malformed/duplicate clauses and runtime operands with parameter/value/set context. Every shipped slice synchronizes supported syntax, capability/diagnostic contracts, semantic and schedule API/MCP reports, book/examples and independent positive/negative checks before its commit.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.4.2`
  Status: `pending`
  Goal: `Enforce parameter sets at every supported override and expose the contract.`
  Acceptance: `For R2/R3, preserve declared constraints through library use, activation and generated-top overrides and check the effective value at each existing specialization boundary. Cover inherited/explicit valid and invalid overrides. Add bounded actor/instance parameter constraint fields and corresponding capability/schema, semantic/schedule and actual MCP parity tests. Every shipped slice synchronizes supported syntax, capability/diagnostic contracts, semantic and schedule API/MCP reports, book/examples and independent positive/negative checks before its commit.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.4.3`
  Status: `pending`
  Goal: `Add advisory recommended parameter values and ranges.`
  Acceptance: `For optional R4, preserve recommended values/ranges separately from legal sets. Defaults and overrides outside recommendations warn rather than fail, while illegal values still fail. Define warning identity/provenance and recommendation consistency, expose both sets to agents, and verify that advice cannot silently change a chosen value. Every shipped slice synchronizes supported syntax, capability/diagnostic contracts, semantic and schedule API/MCP reports, book/examples and independent positive/negative checks before its commit.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.4.4`
  Status: `pending`
  Goal: `Validate exposed HDL parameter instantiations against declared sets.`
  Acceptance: `For optional R5 and generic-width coordination, emit supported elaboration-time legality checks without changing legal synthesized behavior. Qualify legal/illegal external instantiations with an independent HDL oracle; document and fail closed at backend boundaries that cannot carry the chosen contract. Every shipped slice synchronizes supported syntax, capability/diagnostic contracts, semantic and schedule API/MCP reports, book/examples and independent positive/negative checks before its commit.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.5`
  Status: `active`
  Goal: `Represent optional input/output presence and absent-input values faithfully.`
  Acceptance: `Complete the exact child slices; active denotes an owned container, not shipped capability or simultaneous implementation.`
  Verification: `pending; caller request and fresh baseline owned by .33.1`
  Commit: `children below`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.5.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.5.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.5.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.5.1`
  Status: `pending`
  Goal: `Define optional-port width, presence and tie-off semantics before lowering.`
  Acceptance: `For sf-isf-optional-signal R1-R3, reconcile zero-width absence with logical value width and tie-off fit checks, nonzero presence parameters, absent output no-op writes, and reads of absent inputs. Require an explicit static contract for undeclared/non-scalar presence, negative/noninteger widths, nonliteral/too-wide tie-offs and output tie-offs. Resolve how logical width is known for zero-width inputs rather than inventing a fit rule; preserve positive-width behavior. Every shipped slice synchronizes supported syntax, capability/diagnostic contracts, semantic and schedule API/MCP reports, book/examples and independent positive/negative checks before its commit.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.5.2`
  Status: `pending`
  Goal: `Lower resolved optional ports and expose declared versus realized interfaces.`
  Acceptance: `After .5.1, remove absent formal ports, routes, drivers and width-dependent storage; replace allowed absent-input reads with the declared tie-off and reject a read without one. Qualify both presence values, zero/positive widths, domain ownership, reset and expression use with independent HDL behavior. Keep declaration/presence/resolved value/provenance discoverable through public reports without manufacturing a live input. Every shipped slice synchronizes supported syntax, capability/diagnostic contracts, semantic and schedule API/MCP reports, book/examples and independent positive/negative checks before its commit.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.5.3`
  Status: `pending`
  Goal: `Re-evaluate optional presence at supported instance-specialization boundaries.`
  Acceptance: `For optional R4, coordinate generic-width and parameter-set work so each library/activation override independently determines presence. Define supported HDL elaboration versus generated-specialization boundaries explicitly; require actual emitted interface inventories and binding/runtime controls for both absent and present configurations. No placeholder zero-width vectors or silently ignored presence clauses may stand in for absence. Every shipped slice synchronizes supported syntax, capability/diagnostic contracts, semantic and schedule API/MCP reports, book/examples and independent positive/negative checks before its commit.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.6`
  Status: `active`
  Goal: `Allow always-on actor-level assertion, assumption and coverage intent.`
  Acceptance: `Complete the exact child slices; active denotes an owned container, not shipped capability or simultaneous implementation.`
  Verification: `pending; caller request and fresh baseline owned by .33.1`
  Commit: `children below`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.6.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.6.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.6.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.6.1`
  Status: `pending`
  Goal: `Parse and lower actor-level assert/assume/cover without a hosting transaction.`
  Acceptance: `For sf-isf-actor-level-assertion R1/R2, reuse the existing verification property language on ordinary actors, including no transactions. Preserve clock/reset policy, verification-only guards and always-on semantics; do not invent a trigger/completion or silently gate by an unrelated transaction state. Qualify signal/operator/window errors and existing transaction-level property equivalence. Every shipped slice synchronizes supported syntax, capability/diagnostic contracts, semantic and schedule API/MCP reports, book/examples and independent positive/negative checks before its commit.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.6.2`
  Status: `pending`
  Goal: `Qualify actor-level verification reports, backend behavior and placement guidance.`
  Acceptance: `Expose checked actor invariants and source placement in bounded semantic/schedule contracts where meaningful, with full API/MCP parity and capability discovery. Prove emitted properties and independent supported simulation outcomes, reset suppression, malformed inputs and unchanged ordinary behavior. State transaction-level checks remain always-on; any future transaction-scoped meaning requires a distinct contract. Every shipped slice synchronizes supported syntax, capability/diagnostic contracts, semantic and schedule API/MCP reports, book/examples and independent positive/negative checks before its commit.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.6.3`
  Status: `pending`
  Goal: `Support explicit domain ownership for actor-level checks.`
  Acceptance: `For optional R3, choose a bounded domain annotation, resolve every referenced signal to that domain, preserve each clock/reset and refuse illegal cross-domain references or ambiguous ownership. Qualify actual domain artifacts and properties; do not treat multiple declared clocks as an implicit CDC verification rule. Every shipped slice synchronizes supported syntax, capability/diagnostic contracts, semantic and schedule API/MCP reports, book/examples and independent positive/negative checks before its commit.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.7`
  Status: `active`
  Goal: `Add verification-only known/unknown value predicates with real four-state evidence.`
  Acceptance: `Complete the exact child slices; active denotes an owned container, not shipped capability or simultaneous implementation.`
  Verification: `pending; caller request and fresh baseline owned by .33.1`
  Commit: `children below`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.7.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.7.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.7.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.7.1`
  Status: `pending`
  Goal: `Add a verification-only known signal predicate.`
  Acceptance: `For sf-isf-known-value-predicate R1, define known(SIG) as every bit being 0 or 1 and lower through the existing property path to the supported backend equivalent of !$isunknown. Validate declared scalar/vector signals and refuse rule guards/drive values or malformed arity. Preserve stable/changed/rose/fell/past behavior and synthesis exclusion. Every shipped slice synchronizes supported syntax, capability/diagnostic contracts, semantic and schedule API/MCP reports, book/examples and independent positive/negative checks before its commit.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.7.2`
  Status: `pending`
  Goal: `Add the direct unknown predicate and grouped known-value form.`
  Acceptance: `For optional R2/R3, define isunknown(SIG) and known(A B C) as the exact negative/conjunction contracts. Preserve diagnostics and expression precedence, require every member to resolve, and expose normalized public semantics without confusing knownness with numeric validity, protocol validity or stability. Every shipped slice synchronizes supported syntax, capability/diagnostic contracts, semantic and schedule API/MCP reports, book/examples and independent positive/negative checks before its commit.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.7.3`
  Status: `pending`
  Goal: `Qualify knownness using an independent four-state oracle.`
  Acceptance: `Prove 0/1 inputs pass and X/Z-containing vectors fail in the qualified property context, including guards and resets. A two-state simulator or emitted system-function string alone cannot prove this claim. Identify a supported oracle or an explicit unqualified boundary; synchronize capability, API/MCP and book evidence without promoting compile success to four-state behavior. Every shipped slice synchronizes supported syntax, capability/diagnostic contracts, semantic and schedule API/MCP reports, book/examples and independent positive/negative checks before its commit.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.8`
  Status: `active`
  Goal: `Carry checked transaction phase memberships without invented values or order.`
  Acceptance: `Complete the exact child slices; active denotes an owned container, not shipped capability or simultaneous implementation.`
  Verification: `pending; caller request and fresh baseline owned by .33.1`
  Commit: `children below`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.8.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.8.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.8.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.8.1`
  Status: `pending`
  Goal: `Define checked transaction phase-group metadata and validation.`
  Acceptance: `For sf-isf-transaction-phase-groups R1/R2, follow the existing June response: preserve authored transaction/phase names, member signals, actor-relative roles and optional provenance as metadata. Resolve members to actor ports and roles to directions; reject duplicate/malformed/empty phases and unknown signals. Membership creates no drive, sample, order, schedule edge or HDL behavior. Every shipped slice synchronizes supported syntax, capability/diagnostic contracts, semantic and schedule API/MCP reports, book/examples and independent positive/negative checks before its commit.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.8.2`
  Status: `pending`
  Goal: `Expose phase memberships through public contracts and prove behavior preservation.`
  Acceptance: `For R3, add bounded discoverable phase/member/role/provenance report fields to semantic/schedule APIs and MCP, including lossless round-trip/defensive-copy where applicable. Compare generated HDL for baseline and metadata-enriched behavior sources, and qualify every malformed-member refusal through native/API/newline queries. Update the canonical SPECFORGE response and book examples. Every shipped slice synchronizes supported syntax, capability/diagnostic contracts, semantic and schedule API/MCP reports, book/examples and independent positive/negative checks before its commit.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.8.3`
  Status: `pending`
  Goal: `Support metadata-only transactions without synthesizing transaction behavior.`
  Acceptance: `For optional R4, establish the declaration-only transaction contract, including whether names can be activation targets, report presence, reset/system requirements and interaction with ordinary transactions. Preserve phase facts without invented entry, completion or state machinery; unsupported behavioral use fails closed and actual artifacts demonstrate the absence of added behavior. Every shipped slice synchronizes supported syntax, capability/diagnostic contracts, semantic and schedule API/MCP reports, book/examples and independent positive/negative checks before its commit.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.9`
  Status: `done`
  Goal: `Repair loss of declared but undriven actor output interfaces and qualify optional-port presence controls.`
  Acceptance: `Reproduce the optional-signal packet's positive-width baseline missing AWMECID despite strict success, with literal-width and driven-output controls. Reconcile public declaration, schedule and realized interface contracts; preserve declared output identity through generated artifacts where supported without inventing a drive value, or fail closed at an explicitly unsupported emission boundary. Cover ordinary/domain and relevant generated-child paths, actual HDL port inventories and native/API/MCP parity. Update the book and the optional-signal qualification to require actual present/absent endpoints, not just strict status or byte comparisons between already-missing ports. Commit before optional-port implementation.`
  Verification: `passed; T1900 native/API/newline MCP output inventories, materialized FSM/Verilog-family/direct-VHDL declarations, no invented assignments, Verilator correct/wrong-width controls and repository-local GHDL analysis. T1897/T1896/T1476 preservation, exact updated T1330 child roles, T1376 book lowering, T1112 contract and T1899 supported-producer census pass. Fresh book render and syntax pass. Reset-only value semantics remain separately owned by immediate .35.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.9: preserve declared output interfaces`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.34`
  Status: `done`
  Goal: `Complete startup-required safe artifact cleanup and restore the bounded latest-cleanup record.`
  Acceptance: `Inventory repository-local disposable session output and Rust target release/deps/incremental log/bin candidates without following links or inspecting dependency implementation. Remove only known regenerated .33.2 scratch outputs after their evidence is committed; preserve spent compiler/native-proxy and all ambiguously retained evidence. Write only the latest dated cleanup record in docs/ARTIFACT_CLEANUP.md, verify deleted paths are absent, refresh generated discovery and doctrine data, and commit before output-interface work resumes.`
  Verification: `Known .33.2 scratch logs and mdBook render removed only after same-volume, non-symlink and untracked checks; exact deleted paths absent afterward. Root target paths and rust/target/release absent; rust/target/debug/deps and incremental contain no log/bin candidates. Retained native-proxy evidence remains present; all other evidence untouched. T1414 documentation audit passes; generated focused-document index refreshed.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.34: record safe artifact cleanup`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.35`
  Status: `done`
  Goal: `Honor explicitly authored hardware reset and hold behavior on outputs without ordinary data writers.`
  Acceptance: `After .33.9, reproduce reset-only actor and direct FSM outputs with literal widths and reset values; locate why retained +size reset metadata does not create HDL reset behavior without an ordinary writer. Select faithful reset/hold semantics from existing contracts, repair common/backend planning without inventing values for outputs without a reset, and qualify actual reset behavior plus native/API/MCP reports, both Verilog-family targets and supported VHDL. Preserve driven reset/default and plain undriven-output controls; update book, specs and knowledge and commit separately.`
  Verification: `T1901 passes exact native/API/newline MCP reports and independent Verilator/GHDL reset timing, polarity and hold behavior for both source layers and both Verilog targets plus reset-bearing VHDL. Plain undriven outputs have no writer; explicit clock-only Verilog has no invented reset; clock-only VHDL refusal is owned by .36. T1892/T1476/T1900/T1376/T1112 and T156/T170/T1033/T1392 pass. Detailed root cause, negative controls and claim legs are in the .35 acceptance checklist.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.35: honor reset-only output behavior`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.36`
  Status: `deferred`
  Goal: `Support clock-only direct VHDL sequential processes after the established SV-backed IAL completeness prerequisite.`
  Acceptance: `After R11-DIRECT-STRUCTURAL-VHDL-REROUTING.2 readiness permits VHDL expansion, select common/structural clock-only sequential lowering and qualify direct FSM and ISF generation plus independent GHDL behavior. Preserve the reset-bearing subset and do not synthesize a reset or initialization that the source does not request. Update native/API/MCP capability boundaries and book.`
  Verification: `Exact public reproduction in T1901: (?fsm:no_reset (+system (clock clk)) (+interface (output Q)) (+size (Q 5 (reset 19))) (idle (-> idle))). Both Verilog targets retain clock-only generation with no Q initialization. VHDL rejects the generated current_state <= next_state body in VHDL::_split_if_else_assignments because it requires an if/reset branch. This is outside docs/VHDL_SCOPE.md's reset-bearing process subset, not a regression caused by .35. T1901 owns the present fail-closed control. Priority: bounded VHDL completeness extension after SV IAL completion; do not pivot from the active runtime/semantic repair queue.`
  Commit: `deferred`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.37`
  Status: `done`
  Goal: `Intake the director-supplied SPECFORGE sf-isf-storage-register-access request and assign exact repair/feature ownership.`
  Acceptance: `Read the authorized external request bundle without mutation, preserve its request and exact source controls with provenance in repository-local tracked evidence, query canonical storage contracts, reproduce bounded current native/API/MCP results, and distinguish existing behavior from requested semantics. Own every confirmed defect and extension in dependency order, synchronize response/book/knowledge and resume pointers, run appropriate checks and commit before returning to the runtime repair queue.`
  Verification: `Exact packet and controls retained in docs/audits/specforge-storage-register-access-intake-20260926.json from clean 851c252a2. Default/strict/native/API/newline results agree: baseline and whole-word-field pass, both word-access forms and unknown token fail. Local retained-source replay matches intake; existing-directory/escape/unknown-option refusals preserve prior results. T1453/T1112/T1376 pass, book renders and .38 owns all required and optional feature scopes. No feature implementation or external mutation occurred.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.37: intake storage register access request`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.38`
  Status: `active`
  Goal: `Represent checked storage-word access independently of field access, without changing generated behavior.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.38.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.38.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.38.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.38.1`
  Status: `done`
  Goal: `Implement required SPECFORGE storage-register-access R1-R3 for width-based scalar var and variable entries.`
  Acceptance: `Accept exactly the existing lowercase field-access token set on scalar storage words, with or without fields; preserve independent word/field facts without inheritance or consistency constraints. Reject duplicate, malformed, unknown and bank/typed access forms with storage/token diagnostics. Project optional access beside width/fields wherever scalar storage is reported, including applicable domain views and API/MCP schedule projections. Retain original caller controls from the .37 audit; prove unchanged scheduled FSM and date-normalized generated HDL/reset behavior, unchanged baseline/whole-word-field reports, token/alias coverage and default/strict/native/API/newline negative controls. Update book/spec/public contract and support coverage before commit.`
  Verification: `Required scalar packet R1-R3 qualified: parser checks the existing field vocabulary on width-based var/variable words; LoweringIR preserves an independent scalar fact and JSON reports optional inferred_storage[].access. Complete supplied native/API/newline reports retain all prior fields except authored access; actual scheduled FSM and both HDL targets equal pre-change controls except HDL date. T1981 Files=1, Tests=6 PASS; T1453/T1398/T1144/T1148/T1112/T1255/T1376/T1978 Files=8, Tests=31 PASS. Baseline, red, initial/final feature and regression logs/source identities are retained in docs/audits/storage-word-access-20260930/. First candidate assumed nonexistent public domain detail; root cause is name-only projection, now owned immediately next by .38.3. Initial regression had a wrong T1398 filename, corrected and rerun. Decision 0109 narrows over-broad execution prerequisites for passive metadata; those runtime owners remain open. Stale child-storage spec disclaimers and power-on wording are corrected against qualified ownership contracts. Book/spec/capabilities/support fixture and canonical fact are synchronized. No new native runtime.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.38.2`
  Status: `pending`
  Goal: `Select and implement the optional R4 storage-bank access metadata extension after scalar access is qualified.`
  Acceptance: `Read scalarization/domain/report contracts after .38.1 and choose an unambiguous bank-level access projection without inventing per-field facts or access-policy RTL. Implement the same checked token set only if bank identity and element ownership survive every affected report; otherwise split the required report prerequisite into owned leaves. Prove unchanged generated FSM/HDL, unknown/duplicate/malformed refusal, native/API/newline parity and no implicit reset or access enforcement. Keep scalar metadata and unrelated bank boundaries unchanged; update book/spec and commit separately.`
  Verification: `Caller labels R4 optional; scalar .38.1 and domain projection .38.3 are qualified. This extension remains scheduled after the required duration/timer/record-port packet deliveries rather than silently dropped. Until its qualified implementation, access on bank remains refused.`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.38.3`
  Status: `done`
  Goal: `Publish owned storage metadata in multi-domain schedule reports.`
  Acceptance: `Immediately after .38.1, select and add a bounded per-domain storage-detail projection preserving existing storage-name lists and top-level empty ownership. Reproduce multi-domain field and word metadata absence, qualify independent owned-domain expectations and existing report compatibility, advertise exact keys/shapes across native/API/newline capabilities, update report golden controls/book/spec, and prove unchanged FSM/HDL. Do not conflate domain summaries with child-report publication or promote runtime controller behavior.`
  Verification: `JSON clock_domains entries now include detached inferred_storage using each realized domain report and the existing normalized storage schema. Single-domain named actors reuse their module storage details without changing old null count fields; multi-domain top inferred_storage stays empty. Existing storage-name lists and every prior report field/FSM/HDL remain unchanged. T1982 independently qualifies words/fields/types/bank elements/watchdogs, single/multiple/empty domains, nested detachment and native/API/newline discovery/products. Initial feature Files=1, Tests=4 PASS. Broad Files=8, Tests=43 failed only T1978 on the separate single-domain route; all other files passed. After its isolated correction, T1982/T1978/T1255 Files=3, Tests=11 PASS; unchanged multi-domain wiring/reset/partition and word-access controls retain their passed results. Full sources/baseline/reproduction/disposition/log/hash evidence is in docs/audits/domain-storage-report-20260930/. Book/spec/fact/response and capability/test catalog are aligned. No native simulator executed. Next required feature contract .60.4.2; optional bank access .38.2 stays owned after required SPECFORGE deliveries.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39`
  Status: `active`
  Goal: `Preserve actor-owned storage identity and reset behavior when the source reads a register without ordinary data writes.`
  Acceptance: `Immediately after .37, reproduce the retained baseline-good and whole-word-field sources: inferred_storage calls status actor_storage, but generated csr_access exposes input status and has no status reset assignment. Trace materialized FSM and inference, select a faithful ownership representation across scalar/domain/child boundaries, and split prerequisites if needed. Repair internal ownership without synthetic external ports or invented initialization for storage lacking reset; qualify explicit reset-and-hold behavior and driven storage controls with independent HDL simulation and native/API/newline reports. Preserve metadata-only field/access semantics, update book/spec/facts and commit before returning to watchdog and .38 metadata work.`
  Verification: `Discovered in the .37 retained-source replay from 851c252a2: baseline-good.sv declares input wire [7:0] status and reads it into status_out_next, with no status assignment. Both baseline and whole-word-field schedule reports declare status kind register, role actor_storage, width 8; authored var reset is 0. Ordinary LoweringIR carries declared storage separately while +interface records only authored input/output roles; width-only inference can classify a read-only storage reference as input. Captured csr_access.fsm retains status reset in +size with no internal role; SignalAnalyzer::_classify_signal_role selects INPUT for referenced-without-assignment signals. Priority: immediate after .37, ahead of watchdog and new metadata extensions.`
  Commit: `children below`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.1`
  Status: `done`
  Goal: `Add an explicit internal signal role to the existing IAL0 +interface carrier, preserving internal declarations and reset-only register behavior.`
  Acceptance: `Extend the closed +interface role vocabulary with (internal NAME), preserving widths/types/reset metadata in +size and rejecting malformed or contradictory role declarations. Explicit internal signals must never become ports, including read-only/unused and data-driven cases. Carry their CoreAST ownership through classification, internal declaration planning and shared reset/hold planning without inventing an initialization when no reset is authored or available. Qualify strict/default native/API/newline semantic inventory and independent Verilator/GHDL behavior in the supported reset-bearing subset; preserve existing input/output and inferred internal behavior. Document the public role carrier and commit before ISF producer adoption.`
  Verification: `Selected because ownership must survive the materialized FSM artifact; a private ISF-only pipeline hint would lose the repair on replay, and synthetic data assignments would misrepresent authored writers. Existing +interface already owns explicit signal-direction decisions; internal is an explicit exclusion from port inference. SignalAnalyzer currently keeps other internal signals outside FSMModule::signals, so new explicit internal signals also require declaration planning and port exclusion rather than only a classifier change.`
  Additional defect: `A clockless ?dt with +size reset metadata emits always_ff on undeclared clk/rst_n: AssignmentSupport checks reset name but ignores effective_system_contract.declare_ports. Reproduced in .artifacts/internal-role/clockless.sv through strict emission. This leaf owns the small shared-plan fix and clockless internal/output negative controls before commit; no system or initialization may be invented.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.1: preserve explicit internal signal roles`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2`
  Status: `active`
  Goal: `Carry declared ISF actor storage through the qualified internal-role substrate and close the retained caller defect.`
  Acceptance: `After .39.1, emit internal roles for declared scalar storage and scalarized bank elements in their owning ordinary/domain/child FSMs without exposing unrelated parent storage in children. Retain original baseline and whole-word-field controls, a nonzero reset, driven/no-reset/unused storage and domain/child cases. Prove exact authored external interfaces and actual reset/hold/readback behavior through both Verilog targets and supported VHDL; qualify native/API/newline inventories, support-producer controls and unchanged field metadata. Remove the known-gap documentation only after behavior proof and commit.`
  Verification: `Pending the direct internal-role substrate; .37 retains exact caller inputs and the incorrect public status input for falsification. Access-word metadata remains separately owned by .38.`
  Commit: `children below`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.1`
  Status: `done`
  Goal: `Preserve declared internal storage in ordinary actor and domain FSMs, closing the retained scalar CSR baseline defect.`
  Acceptance: `Carry explicit internal storage signals in parent/domain LoweringIR and emit their +interface roles without changing public port direction metadata. Include unused scalars, typed storage and scalarized bank elements; retain exact caller baseline/whole-word-field metadata controls. Qualify authored interfaces, reset/read/write/hold through both Verilog targets and supported VHDL, direct materialized-FSM replay, native/API/newline reports and existing storage/domain producers. No reset value or unavailable hardware reset invents no initialization. Keep generated-child adoption separately owned and document that boundary accurately; commit before it.`
  Verification: `Pre-change .37 audit records status exported as input and missing reset. .39.1 is committed as 4447ca7a0 with qualified direct internal roles. Ordinary parent IR and domain partitions share _build_parent_ir; generated children use _build_child_ir, currently carrying every actor storage declaration. Limit this producer adoption to parent/domain ownership and qualify child isolation before enabling it there.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.1: retain internal actor storage ownership`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2`
  Status: `active`
  Goal: `Select and repair generated-child storage ownership without duplicating or leaking unrelated actor state.`
  Acceptance: `After .39.2.1, reproduce storage reads/writes across generated transaction children and their parent through public lowering and HDL. Determine shared actor-state ownership from source contracts; distinguish child-owned state, parent-owned state and explicitly routed data. Split routing/arbitration prerequisites when required rather than copying every actor declaration into independent registers. Qualify unused parent storage exclusion, child read/write/reset behavior, exact interfaces and native/API/MCP composition reports with independent runtime evidence. Track any unsupported or ambiguous sharing contract explicitly, update book/spec/facts and commit before closing .39.`
  Verification: `Read-only inspection finds _build_child_ir copies _declared_storage_for_ir($actor) wholesale, whereas _build_child_ports handles public ports separately. Turning all those declarations into explicit internal registers without a usage/ownership analysis could duplicate actor state. No child behavior is changed by .39.2.1.`
  Findings: `Public strict check accepts child_storage_writer, but independent Verilator simulation reports parent observed=19 after the child writes 37. Generated HDL has separate status registers in parent and worker and no storage wiring; this is incorrect shared actor-state behavior, owned immediately here. A reader with canonical transaction output binding also passes composition despite no status wiring; compare direct worker semantic inventory to composed realization before selecting a repair. Exact probes and runtime output are under .artifacts/child-storage pending a tracked evidence receipt. Initial reader controls without explicit output binding and with shorthand bind syntax correctly failed their documented boundaries and are not signoff cases.`
  Commit: `children below`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.4`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.1`
  Status: `done`
  Goal: `Retain the generated-child storage defects and select a single-owner handoff contract before changing module boundaries; remove duplicated decision-summary narration as its bounded documentation prerequisite.`
  Acceptance: `Retain exact accepted reader/writer sources, strict reports, materialized FSM/HDL, independent runtime oracles and results. Explain why reads escape through generic top-input inference and writes use separate registers. Record actor/domain ownership and explicit live-read/write-handoff semantics, leaving transaction-local state and separately instantiated actors distinct. Schedule read, single-writer and wider writer lanes, update known-boundary book/facts, and commit the diagnosis before implementation.`
  Verification: `Writer simulation completes the transaction but parent readback remains reset value 19 instead of child-written 37. Reader simulation observes external input 73 instead of parent-written 53. Direct worker semantic inventory includes status input; emitted top exposes and binds it through TopPortInferenceBuilder::augment_undeclared_top_inputs. SourceFrontend creates fresh signal managers per module; no cross-root attribute leak is involved. Both accepted sources pass strict check, so check success is not behavior signoff.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.1: select shared child-storage ownership`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.2`
  Status: `done`
  Goal: `Route generated-child actor-storage reads from their owning parent/domain without external port leakage or copied state.`
  Findings: `T1904's parent-only wdata input exposes a child-interface mismatch: _build_child_ports declares it and CompositionTop wires w0.wdata, but implicit IAL0 inference drops the unused child input. Preserving all inherited inputs then exposed unconnected trigger and expression-binding inputs. The exact repair prunes unread inherited actor inputs from child IR and preserves authored transaction ports; wiring and emitted declarations must agree.`
  Additional defect: `The typed reset control emits an uninitialized-width warning in Parser::_parse_storage before named-type resolution. Guard the literal-width precheck with definedness here and verify resolved-width overflow still rejects; the required named-type path must not warn.`
  Reset falsifier: `Strict check unexpectedly accepted a named 8-bit type with reset 256. Root cause: the literal-width check runs before type/parameter resolution, and the later reset-fit check is conditional on fields. Own a resolved-storage reset-fit check here, with exact fit/overflow controls; typed or symbolic widths must not bypass reset validation.`
  Fixture migration: `T1241/T1248 payload-binding tests used actor-storage sinks written only inside generated children. The old tests silently relied on private copies, not shared-state runtime evidence. Preserve their payload checks using explicit transaction-local sinks and retain actor-writer refusal separately in T1904; original shared writes stay owned by .39.2.2.3/.4.`
  Acceptance: `Use the selected contract to classify lowered child storage reads and writes. Add explicit live read handoffs with collision-safe names, exact widths/types and per-instance top wiring; keep the actual register/reset in the parent/domain and exclude unrelated declarations from child hardware. Qualify scalar, typed, bank-element, guard/expression and repeated-activation reads, parent updates, multiple readers, domains, direct replay and complete native/API/MCP parity with independent runtime evidence. Until qualified writer lanes exist, refuse unsupported generated-child actor-storage writes explicitly rather than emit independent copies. Preserve explicit transaction port bindings and local child state. Update book/spec/facts and commit.`
  Verification: `Completed scalar/bank, aggregate and domain child-read leaves qualify live owner-held state, exact types/interfaces, reset ownership, repeated activation and complete native/API/MCP reports. T1904/T1911/T1916 pass; direct child writes remain explicitly owned by .39.2.2.3/.4.`
  Commit: `children below`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.2.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.2.1`
  Status: `done`
  Goal: `Qualify scalar, named scalar type and scalarized bank live reads in ordinary/single-domain generated children, with truthful unsupported boundaries.`
  Acceptance: `Route only actual reads to one owner; preserve explicit transaction ports and prune unread inherited actor inputs. Prove post-spawn updates and repeated reads independently in Verilator and separately wired GHDL, exact interfaces, direct replay and native/API/MCP parity. Refuse unqualified writers, aggregate read composition and multi-domain child read composition. Repair resolved reset overflow and preserve binding/local-state controls. Commit this bounded slice before wider composition repairs.`
  Verification: `T1904 positive reader cases and adversarial boundary controls; broader storage/domain/contract/book suite. Scope split because independent qualification exposed pre-existing aggregate typedef duplication and missing multi-domain child artifacts; those repairs have immediate owners below instead of extending this slice without bound.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.2.1: route shared scalar storage reads`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.2.2`
  Status: `done`
  Goal: `Repair aggregate type declaration identity across generated composition modules and qualify shared aggregate storage reads.`
  Acceptance: `After .40 fixes one-member normalization, reproduce the retained multi-member record through native HDL generation and Verilator. Select collision-safe declaration identity or an exact shared declaration contract without hiding conflicting same-name types. Prove same/different nested record/list types, parent/child/top ports, independent live-read runtime and API/MCP parity before removing the aggregate read refusal.`
  Verification: `T1904 record control generated valid-looking HDL but Verilator rejected three compilation-unit typedef declarations named byte_t__fsmgen_t, emitted before parent, child and top modules. Reproduce with (type byte_t (record (payload (bits 7)) (flag bit))) and actor storage read in worker. Root is compilation-unit declaration reuse across generated modules, not width or storage route; read-refusal prevents claiming the unqualified combination.`
  Commit: `children below`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.2.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.2.2.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.2.2.1`
  Status: `done`
  Goal: `Give emitted aggregate typedefs collision-safe module ownership without changing semantic type compatibility.`
  Acceptance: `Reproduce duplicate compilation-unit typedefs through public direct composition. Scope backend-owned identifiers by the actual module identity in both direct and structural emitters, preserve per-module type lookup and name collision handling, and prove same-name equal/different nested record/list types with independent HDL admission/runtime. Preserve type-mismatch refusals, direct generator reuse and portable-target boundaries. Update book/fact evidence and commit before removing the ISF aggregate-read refusal.`
  Verification: `ScaffoldEmitter and StructuralRTLIREmitter emit compilation-unit declarations, but TypeDeclarationSupport allocates alias-derived names only within each module's fresh typedef_state. Orchestrator resets this state per generation. A scoped identifier fixes the name collision without text deduplication or silently equating same-width different types.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.2.2.1: scope aggregate typedefs by module`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.2.2.2`
  Status: `done`
  Goal: `Qualify shared generated-child aggregate storage reads after backend declaration ownership is repaired.`
  Acceptance: `Remove only the aggregate read refusal after single/multiple/nested record/list reads, exact owner/child/top interfaces, post-spawn parent updates, repeated activations, independent runtime, direct replay and complete native/API/MCP reports pass. Keep multi-domain and writer boundaries separately owned; update book/spec/intake/facts and commit.`
  Verification: `T1911 qualifies single/multiple/nested record/list and scalar-leaf live reads, simultaneous aliases, reused instances, repeated activation, exact interfaces/reset ownership, scheduled replay and complete native/API/newline parity. T1904 record control is now a passing runtime case; focused type/leaf regressions and book audit pass.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.2.2.2: qualify aggregate child reads`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.2.3`
  Status: `done`
  Goal: `Materialize and wire generated transaction children inside multi-domain actors without exporting internal handshakes or storage handoffs.`
  Acceptance: `After .39.2.2.2.2, repair Scheduler::_emit_multi_domain_scheduled_artifacts and top wiring for generated child modules and per-domain activations, including children with no storage reads. Preserve module/instance collision policy and domain clocks/resets; qualify public interfaces, independent runtime and API/MCP reports before removing the multi-domain child-storage read refusal.`
  Verification: `Completed .3.1 realizes flat domain children and .3.2 qualifies live scalar/typed/aggregate/bank reads. T1912/T1916 pass independent clocks/reset/runtime and report checks. Generated-do inherited inputs are wired with explicit binding precedence. Local-call/independent transaction reachability and watchdog behavior remain separately owned.`
  Commit: `children below`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.2.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.2.3.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.2.3.1`
  Status: `done`
  Goal: `Emit and wire same-domain generated transaction children inside multi-domain actors.`
  Acceptance: `Reproduce accepted missing-child artifacts without storage. Emit children with collision-safe module/file and hardware-instance identities; share ordinary composition wiring semantics without nesting unsupported tops. Preserve parent interface routes, domain clocks/resets, CDC and generated do parameter bindings. Prove completion, distinct domain clocks/resets, repeated activations, exact ports, scheduled replay and native/API/MCP reports. Keep the storage-read refusal until the next qualification leaf. Sync docs/facts and commit.`
  Verification: `T1912 independently qualifies domain clocks/reset isolation, repeated spawn/do activations, exact do-output pulse counts, CDC-ready input routing, reused definitions, name collisions, reset absence, scheduled replay and native/API/newline identity parity. The original watchdog runtime remains explicit TODO under .32.1.3.3.3; named completion and library interfaces remain exact refusal controls under .46/.47. Ordinary composition/domain/effect regressions pass.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.2.3.1: realize domain transaction children`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.2.3.2`
  Status: `done`
  Goal: `Qualify shared storage reads through realized domain children.`
  Acceptance: `After .3.1 and prerequisite .46/.47/.48 repairs, qualify scalar/typed/aggregate/bank live reads with owner-only reset/state and independently clocked domains, repeated activation, exact interfaces and native/API/MCP parity. Remove only the multi-domain read refusal, keep unowned cross-domain access and direct writer refusals, synchronize documentation and commit.`
  Verification: `T1916 qualifies spawn and parameterized generated do, whole/nested-leaf aggregate and dynamic bank reads, owner-only reset, post-activation updates, repeated activation and independent clock/reset isolation. Explicit inverted index binding wins over inherited input. T1904/T1911/T1912 and book checks pass. Plain local-do reachability is retained and scheduled under .32.1.3.3.1.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.2.3.2: qualify domain child storage reads`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.46`
  Status: `done`
  Goal: `Honor named completion pulses in generated transaction children alongside their activation handshake.`
  Acceptance: `Immediately after .39.2.2.2.3.1 and before domain storage-read qualification, reproduce a generated worker completing an actor output other than done through ordinary and multi-domain compositions. Select explicit named-output and canonical child-done routing without double-driving parent outputs or losing the authored pulse. Preserve strict interfaces, repeated activation and independent runtime; retain the original failing dual-domain source, update contracts/book/facts and commit.`
  Verification: `T1913 qualifies exact named/canonical pulse edges, shared and coincident outputs, spawn/do/reuse, repeated activation, named bit aliases, local shadowing/bindings, private/public suffix collisions, mixed-writer refusal, scheduled replay and full native/API/newline parity. T1912 qualifies the retained domain source. Pulse metadata remains nullable under T311/T340/T354; ordinary shared-datapath regressions pass. The unrelated watchdog TODO remains owned by .32.1.3.3.3.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.46: preserve generated child named completion`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.47`
  Status: `done`
  Goal: `Restore correct parent interfaces around library-owned ports after explicit interface preservation.`
  Acceptance: `Immediately after .46 and before domain storage-read qualification, repair ordinary/default-domain library compositions without hiding authored public ports. Reproduce T1238 and the T1912 FIFO domain source. Connect retained parent inputs; assign library-driven output ownership and any parent readback explicitly, rejecting competing writers. Prove FIFO reset/push/pop, parent input/readback use, exact interfaces, native/API/MCP parity and library regressions; update docs/facts and commit.`
  Verification: `Unchanged T1238/T1231/T1321 pass. T1914 independently qualifies FIFO queue/flag/reset behavior, parent input and output readback, typed aliases, sibling-domain isolation, exact public pins, scheduled replay and full native/API/MCP parity. Parent writers, reset/default overrides, generated completions and duplicate library drivers are rejected. T1912 retains its original default-domain FIFO source as a passing check. Nondefault system binding remains explicitly owned by .48.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.47: restore library parent interfaces`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.48`
  Status: `done`
  Goal: `Validate library system bindings against their owning clock domain.`
  Acceptance: `Immediately after .47 and before domain storage-read qualification, repair explicit and inferred clock/reset binding for library uses in nondefault domains. Use the retained T1914 source, preserve same-domain reset kind/polarity and published remapping behavior, reject unowned system crossings, and qualify independent clocks/resets, FIFO runtime, exact interfaces and native/API/MCP reports. Synchronize the catalog, spec/book/facts and commit.`
  Verification: `T1914/T1915 qualify nondefault explicit/inferred/remapped FIFO bindings, independent clock/reset behavior, reset kind/polarity and absence, exact interfaces, strict scheduled replay and full native/API/MCP reports. The original retained empty-default-domain source now passes after omitting an empty generated size section. Wrong-domain system bindings and incompatible inference fail precisely. Library/catalog and strict-boundary regressions, executable book example and book build pass.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.48: bind libraries to selected domains`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.3`
  Status: `done`
  Goal: `Implement full-width scalar actor-storage writes from a sole generated-child writer with unchanged cycle timing.`
  Acceptance: `After read ownership, add per-instance write-data and write-enable handoffs feeding the owning parent/domain register on the original assignment edge. Child reads remain live; do not add payload-register latency or defer writes to child completion. Start with one statically owned full-width scalar writer and prove explicit/default resets, repeated activations, conditional writes and parent readback in independent simulation and API/MCP reports. Reject unqualified partial/aggregate/bank or competing writers with contextual diagnostics and explicit next ownership; update docs and commit.`
  Verification: `T1917/T1918 qualify sole scalar writer handoffs in ordinary and independent-domain actors, preserving original assignment edges, live reads, owner resets, exact interfaces and full reports. The retained parent readback now changes from 19 to 37. Broader writers remain owned by .39.2.2.4.`
  Commit: `children below`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.3.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.3.1`
  Status: `done`
  Goal: `Transfer sole full-width scalar generated-child writes to the ordinary or single-domain owner on the original assignment edge.`
  Acceptance: `Implement combinational child write-data/enable handoffs and owner-side register assignment for one statically owned child instance per scalar. Preserve live reads, exact scalar widths/types, reset values, guarded writes and original-edge visibility. Reject competing parent/child writers, unqualified partial/aggregate/bank writes and multi-domain writes until their owned lanes. Qualify the retained 19-to-37 defect, independent edge-by-edge parent observation, conditional/no-write paths, repeated/reset activations, exact public interfaces, scheduled replay and native/API/MCP reports. Update book/spec/facts and commit before domain qualification.`
  Verification: `T1917 qualifies original-edge sole scalar writes, late-changing payloads, conditional holds, shared child readback, signed aliases, reset/default reset, field metadata, generated do, separate scalar targets, collisions, repeated calls and the original 19-to-37 defect. Strict replay, exact interfaces and full native/API/MCP reports pass. Parent/child contention, bank/aggregate and multi-domain writer boundaries remain explicit. T1904/T1916, binding regressions and book checks pass.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.3.1: route sole scalar child writes`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.3.2`
  Status: `done`
  Goal: `Qualify sole scalar generated-child writer handoffs inside independent clock domains.`
  Acceptance: `After .3.1, remove only the temporary multi-domain writer boundary after independent clocks/reset isolation, original-edge owner reads, repeated activations, exact interfaces, scheduled replay and native/API/MCP reports pass. Preserve same-domain ownership and refusal of unowned crossings or competing writers; synchronize docs and commit before broader writer arbitration.`
  Verification: `T1918 qualifies independent-domain writes on original edges, late payloads, repeated live updates including zero, guarded holds, stopped clocks, reset isolation, signed aliases, generated do and default-domain changes. Exact interfaces, strict replay and complete native/API/MCP reports pass. T1917/T1916 and executable book checks pass.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.3.2: qualify domain scalar writers`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.4`
  Status: `active`
  Goal: `Complete the remaining generated-child storage writer surface under explicit partial-update and arbitration contracts.`
  Acceptance: `Audit partial/sliced/typed aggregate writes, dynamic bank stores, parent-versus-child writers and multiple generated instances after the single-writer lane. Split independently verifiable ownership/merge/arbitration prerequisites before implementation. Preserve source assignment ordering, original clock edges, reset ownership and declared domain boundaries; use existing roadmap resource-arbitration requirements instead of inventing silent priority. Keep unsupported combinations fail-closed and task-owned until implemented, prove adversarial concurrent behavior with independent runtime and full report parity, then close .39 only when the selected writer surface and documentation agree.`
  Verification: `Scheduled after .39.2.2.3; current public resource guidance explicitly defers generated-child storage arbitration. This is owned completion work, not a claim of current support.`
  Commit: `pending`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.4.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.4.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.4.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.4.4, SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.4.5`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.4.1`
  Status: `done`
  Goal: `Audit broader generated-child writer contracts, split safe implementation leaves and repair stale actor-storage documentation.`
  Acceptance: `Review decision 0107, parser/lowering contracts, published resource arbitration, relevant tests and book. Preserve the sole-owner boundary while ordering whole aggregates, partial updates, banks and explicit contention contracts. Record the source of stale read/write refusal wording, correct it against completed qualification and run book checks before committing.`
  Verification: `The actor-storage paragraph in docs/book/src/13a-actor-interface.md still says all child writes and aggregate/multi-domain reads are refused despite completed T1911/T1916/T1917/T1918 qualification; reproduce by reading its Actor-Owned Storage section. git log -S traces it to 5c0f802646c69108d15995f7e8cd7e29c32ebdf5. The introduction now matches qualified behavior and links the detailed composition contract. T1261/T1403/T1218/T1376, reference partitions and mdBook build pass in .artifacts/writer-contract-audit/checks.log.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.4.1: split broader writer contracts`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.4.2`
  Status: `done`
  Goal: `Qualify full-width packed aggregate writes from a sole generated-child instance.`
  Acceptance: `Extend only whole-record/list register handoffs, preserving exact aliases, widths, reset ownership and live reads without extra cycle latency. Cover nested/local/imported types, spawn/generated do, independent domains, repeated/guarded updates, source replay, exact interfaces and full native/API/MCP reports. Keep member/partial/bank and competing writes fail-closed until their leaves; sync docs and commit.`
  Verification: `T1917/T1919 qualify ordinary and independent-domain whole record/list writes with exact local/imported aliases, original edges, live read-modify-write values, repeated/guarded updates, owner reset, replay, interfaces and complete native/API/MCP reports. T1920/T1247 qualify the discovered aggregate-path and inferred-target domain ownership repair. T1916/T1904 and book checks pass. Explicit storage-port name collisions and the first unclassified MCP envelope remain owned by .49/.50.`
  Qualification defect: `T1919 aggregate crossing control fails in .artifacts/whole-aggregate-writes/final-runtime.log: aux_status.payload reaches composition as an unconnected child input instead of a domain violation. LoweringIR::_validate_domain_signal_access ignores non-identifier paths. Own the narrow root-ownership validation repair here before this slice can close; verify member/index reads and writes and preserve explicit transaction-port shadowing. The retained domain-before.log confirms public lowering accepts sibling-domain member reads, member writes and whole-register writes: inferred assignment targets take precedence over declared actor ownership. Repair that precedence while preserving explicit local ports.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.4.2: qualify whole aggregate child writes`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.4.3`
  Status: `pending`
  Goal: `Preserve partial and aggregate scalar-leaf updates through sole-writer child handoffs.`
  Acceptance: `Audit accepted slice/member/extract LHS shapes and their backend merge semantics first. Implement only source-supported updates using explicit target/mask information or owner-side partial assignments; never overwrite untouched bits with a zero-filled root. Preserve ordered writes and original edges with no competing owner, prove adjacent/overlapping fields and whole-plus-partial sequences independently, exact interfaces/replay/reports, and commit synced docs. Keep unsupported parser shapes explicit and task-owned.`
  Verification: `T1261 preserves scalar leaf LHS paths in scheduled assignments; T1403 set-field is already a whole-register masked read-modify-write and must not be conflated with physical partial writes.`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.4.4`
  Status: `pending`
  Goal: `Qualify generated-child scalarized bank stores under explicit element ownership.`
  Acceptance: `Audit static/dynamic index guards, out-of-range behavior, same-edge load/store semantics and resource membership before permitting writes. Preserve original scalarized element updates and owner resets with no memory backend or hidden port policy. Qualify sole-child stores, live reads, repeats, independent domains and exact reports; reject competing element owners pending .4.5 and commit synced docs.`
  Verification: `Published banks lower to concrete scalar entries; storage_port members name entries rather than bank roots and currently arbitrate rule users only.`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.4.5`
  Status: `pending`
  Goal: `Define and implement explicit generated-child storage contention contracts without silent priority.`
  Acceptance: `After sole-writer surfaces, select roadmap-aligned ownership/merge/arbitration semantics for parent-versus-child and multiple generated writers. Separate static exclusion, concurrent disjoint updates and true contention; define request retention, grant visibility and whether denied transactions stall before any implementation. Reuse published resource priorities only through a declared extension, split safe leaves, prove adversarial concurrency/runtime/report parity and keep all unqualified combinations rejected. Ask only if repository direction cannot resolve a required policy decision.`
  Verification: `Existing storage_port priority/round_robin gates whole rule DTs for a cycle; its rule-only users do not define generated-child denial or progress semantics. Decision 0107 forbids silent priority.`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49`
  Status: `active`
  Goal: `Resolve explicit transaction-port shadowing against declared actor storage roles.`
  Acceptance: `Immediately after .39.2.2.4.2, reproduce the retained direct and generated input/output shadow cases through the public parser/lowerer and establish the supported local-port contract. Repair role merging or introduce a precise owned boundary if independently scoped storage is required, preserving generated-child explicit bindings. Prove runtime/interface/report behavior for the selected fix, update docs and commit before partial writer work.`
  Verification: `T1920's first direct worker controls fail in .artifacts/whole-aggregate-writes/domain-controls.log with storage role for scalar conflicts across transactions while merging worker at LoweringIR::_merge_storage_roles. The actor owns scalar in aux; a core transaction declares an explicit scalar input or output and reads/writes it. The diagnostic is a role-merge conflict, not a domain failure. Generated-worker controls in domain-controls-final.log fail at the same merge boundary before child storage selection. Both direct and generated local scope defects is owned here and must not be hidden by broad shadowing claims.`
  Commit: `pending`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.1`
  Status: `done`
  Goal: `Keep explicit generated-child ports distinct from same-named actor storage.`
  Acceptance: `Repair early child width/type/role/reset merging so explicit transaction inputs/outputs shadow actor storage only inside that child. Preserve the actual owner register and reset, avoid actor reset/type leakage into local ports, and keep explicit binding payload/timing unchanged. Qualify different widths/types, input/output reset independence, ordinary/domain generated activations, exact interfaces, replay and full native/API/MCP reports. Migrate T1920 generated controls, retain direct role conflicts under .49.2, update docs and commit.`
  Verification: `T1921 qualifies independent local/actor widths, aliases, roles, resets and values for ordinary/domain input/output collisions, scalarized bank-entry names, spawn/generated do and generated rule triggers. The trigger controls exposed and now verify retained captured payloads beyond start pulses. T1920 generated collisions lower; T1241/T1243/T1248/T1431/T1918, full native/API/MCP reports, replay, exact interfaces and book checks pass.`
  Documentation correction: `The opening transaction chapter still says all rule triggers bind inputs only, while docs/isf-spec/02-interface-transactions.md documents generated/parameterized trigger output handoffs. Correct that stale blanket statement in this port-scope slice; keep local rule-trigger output bindings explicitly refused.`
  Trigger payload defect: `The new T1921 trigger cases complete but read zero after wait 2. Retained .artifacts/child-port-shadow/trigger-probe/trigger_input/source.isf, scheduled FSM, HDL and trigger-probe.log show a registered per-rule payload capture followed by a combinational child input guarded only by the trigger pulse. That guard returns the child input to zero before its authored read. Repair the small handoff defect in this leaf: drive the retained payload register continuously, preserve the existing capture/start/output timing, and qualify delayed reads after external input changes. This does not add request queuing or a new overlapping-trigger policy.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.1: isolate child port storage identities`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2`
  Status: `active`
  Goal: `Resolve same-named direct transaction ports and actor storage without conflating their state.`
  Acceptance: `After generated-child repair, audit direct/local-call and trigger binding contracts, then select collision-safe scoped identities or another explicit semantics-preserving lowering. Do not simply overwrite the actor role or let local assignments mutate the actor register. Preserve exact binding timing, source provenance, reset/type/width ownership and public interfaces. Split prerequisites if needed, prove independent runtime and full reports, sync docs and commit before .49.3 and .50.`
  Verification: `The first T1920 direct input/output controls fail in _build_parent_ir::_merge_storage_roles. Direct transactions share the owner module, so the generated-child map filtering fix alone cannot separate their storage identities.`
  Commit: `pending`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.1`
  Status: `done`
  Goal: `Audit direct-port identities and bind their repair to executable controller prerequisites.`
  Acceptance: `Reproduce direct input/output storage collisions through the public source routes; trace declaration, operand, call binding, rule payload and report identities. Retain the existing local-call reachability reproduction, split safe dependencies and document the current runtime boundary without claiming a code fix. Update the book, facts and resume frontier, run focused evidence checks and commit.`
  Verification: `Public check/schedule/semantic probes reproduce actor/local role and width collisions, caller-local binding precedence failure and shared formal identity across direct transactions. The repair scope and controller dependencies are recorded below. T1241/T1243/T1376 and the book build pass; no runtime or implementation repair is claimed.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.1: bound direct port scope prerequisites`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2`
  Status: `done`
  Goal: `Lower direct transaction ports to collision-safe private identities.`
  Acceptance: `After .49.2.1, controller contract .32.1.3.3.1.2.2 and shadow ownership .32.1.3.3.1.3.1, implement scope-aware operand and binding resolution before .32.1.3.3.1.3.2. Preserve actor owner metadata, local aliases and resets, caller versus callee names, source provenance and public reports. Qualify direct input/output and rule payloads independently, including same names in different transactions and user names resembling generated prefixes. No global textual substitution or actor-role overwrite is permitted.`
  Verification: `All declared children are verified. Direct formals now have collision-safe physical identities, lexical operands/bindings, private interface classification and preserved authored reports; parser/helper prerequisites and family qualification are committed with their evidence. This closes scope integration, not the separately owned local payload, shared-writer, controller or local-call execution obligations.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.4, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.5, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.6`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.1`
  Status: `done`
  Goal: `Define scoped formal identities and deterministic private-name planning.`
  Acceptance: `Build a detached typed identity plan for direct transaction formals with explicit actor/transaction separation and supplied complete reserved names. Preserve source declaration metadata, reject malformed/ambiguous ownership, and qualify declaration permutations, case-fold/prefix collisions, source/plan isolation and generated-child exclusion. Keep execution unchanged; document integration requirements and commit before operand rewriting.`
  Verification: `T1925 qualifies deterministic direct names, scoped lookup, generated-child exclusion, case/prefix collisions, declaration and lookup isolation, malformed ownership and the still-failing production boundary. Existing shadow, identifier policy and binding/report regressions pass. Parser prerequisite .4 is newly reproduced and scheduled next.`
  Commit: `this slice`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.2`
  Status: `done`
  Goal: `Resolve transaction operands and activation endpoints through their lexical scopes.`
  Acceptance: `After .1 and parser prerequisite .4, implement typed operand and binding rewrites over explicit signal positions. Distinguish caller actuals and callee formals, generated child public formals, actor rule/drives, source state/type/member/point names, messages and specialization parameters. Cover supported clause/expression families with mutation and preservation controls. Do not use global string substitution or silently guess unknown grammar; commit the qualified resolver before production integration.`
  Verification: `Detached expression/endpoints and normalized clause walker are qualified in children .1/.2. Production integration remains open; newly reproduced dynamic-wait grammar mismatch is owned by .49.2.2.5 before .3.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.2.2`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.2.1`
  Status: `done`
  Goal: `Resolve typed runtime expressions and explicit caller/callee endpoints.`
  Acceptance: `Provide a detached resolver consuming the formal identity plan and explicit lexical locals/static-symbol context. Rewrite only runtime signal roots; preserve literals, static symbols, aggregate members, state/point names and generated-child ports. Distinguish binding directions and caller actuals from callee formal identities. Qualify malformed grammar, owner/type/path controls, source isolation and every supported operator family without production integration.`
  Verification: `T1927 passes typed caller/callee and actor scope, generated public endpoints, local/static precedence, every carrier operator family, aggregate/scalar suffixes, state/point identities, property context, malformed grammar and mutation isolation. Existing expression, binding/report, aggregate and controller regressions pass. Production remains detached.`
  Commit: `this slice`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.2.2`
  Status: `done`
  Goal: `Apply scoped resolution to normalized transaction and rule clause roles.`
  Acceptance: `After .1, walk explicit normalized clause families using typed expression/target/endpoint methods. Preserve declaration metadata, source labels, messages, parameter overrides and actor-owned drive bodies. Rewrite named-drive actuals, inline drive pairs, temporal signal roles and nested control bodies; reject unknown grammar. Qualify parsed-source corpus and mutation controls before .49.2.2.3 integration.`
  Verification: `T1928 passes explicit clause-role preservation, source/report input isolation, parsed helper expansion, source-local collision rejection and strict carrier replay across the controller cohort. Existing expressions, bindings, properties and wait regressions pass. No production route is switched.`
  Commit: `this slice`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3`
  Status: `done`
  Goal: `Integrate scoped formal lowering and preserve public source identities.`
  Acceptance: `After .1/.2/.5/.6 and extract carrier repair .53, connect declaration maps, width/type/reset/role propagation, caller-local binding validation, local call endpoints and rule payload destinations. Allocate against actual actor/generated/private declarations, preserve generated child public ports and authored binding report names, and reject any unresolved physical collision. Qualify actor/local, sibling/caller/callee, input/output and generated-prefix cases through strict artifacts and complete native/API/MCP reports; keep runtime limits explicit until .49.2.3. Update book/spec/facts and commit before payload repair .32.1.3.3.1.3.2.`
  Verification: `All children are verified: source admission/contexts, complete reservations and final scope guard, automatic physical integration with authored report views, and broad family qualification including private-interface classification. Evidence remains with the children. Local payload retention is next under .32.1.3.3.1.3.2; independent controllers and direct-call runtime remain open.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.4`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.1`
  Status: `done`
  Goal: `Prepare source validation and complete lexical contexts for formal integration.`
  Acceptance: `Map existing source checks, static-zero pruning and binding admission before rewriting. Derive transaction-local and resolved static-symbol contexts from canonical source semantics; repair the confirmed caller-formal binding lookup precedence without weakening actor input protection, width/type checks or timing admission. Qualify source validation, malformed/zero-pruned controls and caller/callee distinctions. Keep physical scope and runtime limits explicit; commit before allocation integration.`
  Verification: `Caller-formal source validation, generated pin shadowing and explicit local/static/count/pruning contexts are qualified in the children. Existing module admission is shared with source preparation; per-transaction checks run without conflicting parent merges. Physical reservations remain .3.2 before production rewriting .3.3.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.1.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.1.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.1.3`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.1.1`
  Status: `done`
  Goal: `Validate caller-formal binding actuals in their lexical scope.`
  Acceptance: `Repair explicit caller-formal lookup before actor declarations for scalar and expression input actuals and scalar output targets. Preserve actor-scope read/write restrictions, exact widths, callee directions and timing admission. Qualify parsed source validation with shadowing, malformed and static-zero controls plus production report/carrier regressions. Keep physical collisions and runtime limitations explicit; commit independently before broader context preparation.`
  Verification: `T1933 passes caller-formal precedence, source isolation, actor protections, width/direction/timing controls, zero pruning, direct actor-pin alias rejection, strict ordinary carriers and complete native/API/newline reports. Related binding/domain/conflict/resolver tests pass. Generated spawn pin-shadow refusal is reproduced and owned by immediate successor .3.1.3 before context preparation .3.1.2.`
  Commit: `this slice`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.1.2`
  Status: `done`
  Goal: `Prepare validated explicit-local and resolved-static contexts before formal rewriting.`
  Acceptance: `Map and preserve source checks and static-zero pruning without relying on conflicting parent merges. Derive complete explicit-local and resolved-static contexts from existing source semantics, excluding inferred sample destinations from explicit-local shielding. Qualify malformed, pruned, parameter/constant/enum and context-isolation controls; commit before physical reservations.`
  Verification: `T1935 repairs malformed explicit-local admission; T1936 derives explicit-only locals, exact actor/package static symbols, separate scalar count contexts and validated structural zero-repeat paths. Detached rewriting preserves direct parameter/formal role distinctions and source isolation. Complete physical reservations and production wiring remain the next leaves.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.1.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.1.2.2`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.1.2.1`
  Status: `done`
  Goal: `Reject malformed explicit-local declarations before scope rewriting.`
  Acceptance: `Qualify and repair source admission that silently ignores malformed local options or overwrites repeated options. Require a valid identifier and exact width/default/init/reset options, one width, one initialization and one reset; retain valid synonyms, reset/init independence, existing collision/value checks and static-zero pruning. Verify source reports and strict carriers; commit independently.`
  Verification: `T1935 rejects malformed/duplicate options and invalid names, preserves reordered valid defaults/resets, collisions and zero-pruned targets, strict-replays carriers and compares complete native/API/newline queries. Lowering now validates exact options before recording values. Book/spec/card document admission and the remaining explicit-local physical scope limit. Related local/reset/for/procedure/formal-width and book fixtures pass; complete contexts remain .1.2.2.`
  Commit: `this slice`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.1.2.2`
  Status: `done`
  Goal: `Prepare complete local/static contexts and source checks after local grammar repair.`
  Acceptance: `Finish the parent acceptance: derive only explicit locals, canonical parameter/constant/enum and package references; preserve source validation and static-zero pruning before any rewrite. Qualify malformed, pruned and context-isolation controls without relying on successful conflicting parent merges; commit before physical reservations.`
  Verification: `T1936 qualifies canonical local/static contexts, direct versus generated parameter scope, scalar count versus runtime operand rewriting, pruned versus live bindings, malformed source, source isolation and strict carriers. Public source/regression checks pass after factoring initial module admission. Count-role ambiguity is fixed in the detached walker; production renaming and complete physical reservations remain open.`
  Commit: `this slice`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.1.3`
  Status: `done`
  Goal: `Preserve generated transaction formals when they shadow actor interface pins.`
  Acceptance: `Run immediately after .3.1.1 and before .3.1.2. Repair the reproduced spawn duplicate driver from automatic same-name actor input wiring plus explicit child input binding. Audit child port construction where inherited actor inputs currently win name deduplication, including width/direction shadows and actor-output assignment classification. Preserve generated public formal names, explicit handoffs and inherited nonformal inputs. Qualify native/API/MCP reports, strict carriers and runtime data provenance; update book/spec/facts and commit.`
  Verification: `T1934 passes exact formal interfaces/type/reset ownership, strict carriers, complete native/API/newline reports and Verilator payload/reset/repeat oracles for actor/formal direction combinations across spawn, generated do and parameterized triggers. T1933 equal-width shadow now passes. Binding/domain/book checks pass. T1921 has one native pre-exec setpgid failure retained under the existing supervisor owner; its exact HDL differs from predecessor only by date comments and its retained oracle executes successfully. Next .54 task-history rollover, then .3.1.2 source contexts.`
  Commit: `this slice`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2`
  Status: `done`
  Goal: `Prove complete physical reservations and deterministic formal allocation in actual lowering contexts.`
  Acceptance: `After source-context preparation, derive real generated declarations and signal consumers without relying on guessed naming patterns or a successful conflicting old module merge. Cover counters, monitors, wait/sample helpers, named drives, bindings, child handoffs, domains and case-folded collisions. Qualify allocation determinism and fail-closed missing reservations; preserve generated public ports. Commit the qualified reservation integration before production renaming.`
  Verification: `All declared children are verified. Actual producer inventories, checked preparation inputs and a detached final-module coverage guard now qualify canonical allocation, separate scopes and missing-reservation failures. Evidence remains with those leaves. Production formal rewriting and public report preservation start at .49.2.2.3.3; controller/runtime qualification remains separate.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.1`
  Status: `done`
  Goal: `Retain and inventory actual per-transaction lowering products for reservations.`
  Acceptance: `Retain the existing per-transaction products from source preparation and collect conservative identifier reservations with structural provenance. Qualify actual counter/monitor/wait/sample/drive/call products without a parent merge, source isolation, malformed inputs and case-folded allocator controls. Prove the named-drive collision with source-only reservations and its avoidance using actual products. Keep module/rule/child/domain closure explicitly pending; commit this bounded producer boundary first.`
  Verification: `T1937 retains actual per-transaction products and qualifies deterministic structural identifier provenance, exact/case-folded named-drive collision avoidance, strict transformed carriers, counter/monitor/wait/sample/call coverage, snapshot isolation and malformed/cyclic controls. Production parent merging and later wiring remain unchanged; complete reservations are .3.2.2.`
  Commit: `this slice`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2`
  Status: `done`
  Goal: `Close module/wiring/domain reservation coverage before production allocation.`
  Acceptance: `Complete the parent contract using actual rule, shared-drive, child, storage/completion, library/ATL and domain producers. Preserve authored helper identity inputs when formal physical names change; prove final allocation and emitted declarations cannot introduce unreserved collisions. Do not equate a transaction-only inventory with complete coverage, bypass conflicting parent merges as executable output, or infer helper names from guessed patterns. Qualify deterministic/case-folded and missing-reservation controls, then commit before .3.3.`
  Verification: `All declared children are verified. Actual producer inventories, checked preparation inputs and a detached final-module coverage guard now qualify canonical allocation, separate scopes and missing-reservation failures. Evidence remains with those leaves. Production formal rewriting and public report preservation start at .49.2.2.3.3; controller/runtime qualification remains separate.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.3`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.1`
  Status: `done`
  Goal: `Retain actual parent activation, rule and shared-drive reservation products.`
  Acceptance: `Use existing generated activation registration, rule lowering and shared-drive producers over validated source and retained transaction records without requiring a conflicting parent merge. Qualify actual local/generated rule payloads, spawn/do/trigger handoffs, shared-drive sources, bank accesses, deterministic/case-folded reservations and snapshot isolation. Preserve production admission and make the still-missing child/domain/final namespace boundary explicit.`
  Verification: `T1938 qualifies actual local rule payload collisions, generated spawn/do/parameterized-trigger handoffs and shared-drive products, rule bank metadata, source isolation, declaration permutations and canonical malformed-bank refusal. Retained products match actual parent declarations/assignments/instances. T1936/T1937 and binding/bank/schedule-golden/book regressions pass. Later ownership/domain coverage and source helper stability remain .2; final completeness remains .3.`
  Commit: `this slice`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2`
  Status: `done`
  Goal: `Preserve helper source identities and close child/domain producer coverage.`
  Acceptance: `Retain authored helper identity inputs independently from physical formal endpoints; qualify rule payload naming and generated child storage/completion/library/ATL/domain producer names. Address pre-allocation validation collisions with generated helpers without weakening source admission. Use actual producer outputs, preserve generated public interfaces and avoid treating source-conflicting merged IR as executable output. Split further only for independently reviewable implementation boundaries.`
  Verification: `All declared child producer leaves are complete and verified in their evidence below. Actual transaction, rule, wiring, point, resource, child, ownership, readback and domain products are qualified; global fail-closed completeness remains the independently pending .49.2.2.3.2.2.3 integration gate.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.1`
  Status: `done`
  Goal: `Preserve authored rule payload helper identity through detached formal rewriting.`
  Acceptance: `Reproduce the change in rule payload helper names when a direct callee formal is rewritten. Retain a checked explicit source-to-physical identity projection so helper generation uses authored identities while data endpoints use physical identities. Qualify source snapshots, generated public ports, native schedule/carrier provenance, malformed/stale maps and naming collisions. Do not enable automatic production rewriting or claim complete physical reservations.`
  Verification: `T1939 qualifies typed source identity on detached physical declarations, stable rule payload helper names across physical allocations, physical fan-in endpoints, exact generated public interfaces/metadata, malformed/stale/duplicate projection refusal, source isolation, schedule provenance and strict carriers. The pre-repair unreserved helper change is retained in probe.log; after-qualified.log proves stable reserved helper identity. Next .55 repairs the separately reproduced raw terminal-wait empty-state carrier before .3.2.2.2.2 resumes.`
  Commit: `this slice`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.2`
  Status: `done`
  Goal: `Separate lexical source admission from generated-helper physical collision checks.`
  Acceptance: `Reproduce helper-looking formal names against monitor/counter preparation. Resolve the pre-allocation validation cycle without weakening actual executable admission, losing collision evidence or accepting a fabricated final IR. Preserve explicit-local/static and source grammar checks; qualify source-only versus post-allocation behavior and failure controls.`
  Verification: `T1941 qualifies source-only deferral for monitor collisions solely with unprojected direct input/output formals, retaining typed source/declaration and actual helper/role/width/state evidence. Raw production still rejects, while explicit projection passes with separate widths and strict carriers. Fixed actor/local/generated/projected identities remain strict; malformed source and snapshot controls pass. Surrounding source/local/monitor/schedule/book regressions pass. Remaining producer closure is .3.2.2.2.3.`
  Commit: `this slice`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3`
  Status: `done`
  Goal: `Close remaining actual module child and domain reservation producers.`
  Acceptance: `Cover local/external activation wiring, priority/resource processing, generated child storage/completion, library/ATL and domain realization using actual producer outputs and stable source/physical projections. Preserve raw conflict refusals in executable lowering and do not infer physical names from guessed patterns. Qualify representative real declarations and separate namespaces before the final completeness gate .3.2.2.3.`
  Verification: `All declared child producer leaves are complete and verified in their evidence below. Actual transaction, rule, wiring, point, resource, child, ownership, readback and domain products are qualified; global fail-closed completeness remains the independently pending .49.2.2.3.2.2.3 integration gate.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.1`
  Status: `done`
  Goal: `Retain actual local and external activation wiring products before allocation.`
  Acceptance: `Collect real local-call and external caller/callee states, counters and ports without merging conflicting transaction width/role maps. Compare with production wiring, prove detached inputs and stable names across formal projection, retain raw conflict refusal and canonical malformed-activation diagnostics. Qualify real projected domains without claiming complete domain composition or controller runtime support.`
  Verification: `T1942 compares actual local and projected domain wiring, previously absent external ready/request/entry names, exact/case-folded candidate collision avoidance, physical helper stability, strict carriers, source/product isolation, generated/pruned exclusions and raw/invalid-source refusals. The focused admission/identity/cross-domain/controller-shadow/schedule/book cohort passes. Later processing and final composition remain .2.`
  Commit: `this slice`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2`
  Status: `done`
  Goal: `Close priority resource child ownership library ATL and final domain producers.`
  Acceptance: `Retain actual later module priority/resource products, generated child storage/completion connections, library/ATL and domain realization identities with stable source/physical projections. Preserve strict executable admission; split independently reviewable producer boundaries as needed before complete gate .3.2.2.3.`
  Verification: `All declared child producer leaves are complete and verified in their evidence below. Actual transaction, rule, wiring, point, resource, child, ownership, readback and domain products are qualified; global fail-closed completeness remains the independently pending .49.2.2.3.2.2.3 integration gate.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.1`
  Status: `done`
  Goal: `Retain actual parent point-reference and entry-default products.`
  Acceptance: `Use canonical point bindings and producer functions to retain resolved assertions, point-active signals, wired states and entry defaults without conflicting formal merges. Qualify actual helper collisions, source identity stability, cross-transaction anchors, generated/pruned exclusions, malformed names, detached products and strict carriers; do not promote runtime or complete reservation support.`
  Verification: `T1943 compares actual point/default products, exact/case-folded late candidate collisions, named point and activation anchors, cross-transaction lookup, declaration order, output-shadow physical separation, source/product isolation, generated/pruned exclusions and canonical bad-anchor refusals. Strict projected carriers and focused point/default/admission/wiring/schedule regressions pass. Later arbitration and composition remain .2.`
  Commit: `this slice`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2`
  Status: `done`
  Goal: `Close arbitration child ownership and final composition reservation coverage.`
  Acceptance: `Qualify actual priority/resource products, child storage/completion connections, library/ATL and final domain realization identities with stable source/physical projections. Preserve executable admission and explicit separate namespaces; split producer boundaries when warranted before complete gate .3.2.2.3.`
  Verification: `All declared child producer leaves are complete and verified in their evidence below. Actual transaction, rule, wiring, point, resource, child, ownership, readback and domain products are qualified; global fail-closed completeness remains the independently pending .49.2.2.3.2.2.3 integration gate.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.1`
  Status: `done`
  Goal: `Retain actual resource pointer declaration products without premature physical admission.`
  Acceptance: `Share the canonical round-robin declaration producer between executable arbitration and detached preparation. Retain potential name/width/role products for selected resource kinds with users; prove real production equality, source-formal collision separation, source/permutation isolation and unchanged resource admission failures. Do not claim grants, priority resolution or complete reservations from a declaration inventory.`
  Verification: `T1944 compares shared declarations with actual supported-kind counters/roles and grant updates, independent width boundaries, source order and mutation controls, formal-shadow separation and strict carriers. Fixed/user/overlap/name/unsupported-kind refusals remain executable checks. Exact native schedule before/after is unchanged; resource/priority/identity/point/schedule regressions pass. Potential declaration inventory does not qualify grants or full reservations.`
  Commit: `this slice`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2`
  Status: `done`
  Goal: `Qualify remaining priority/grant child ownership and final composition coverage.`
  Acceptance: `Complete actual priority/grant product coverage and child storage/completion, library/ATL and final domain realization names with stable source/physical projections. Preserve strict executable admission, distinct scopes and the final fail-closed completeness gate .3.2.2.3; split remaining producer boundaries as needed.`
  Verification: `All declared child producer leaves are complete and verified in their evidence below. Actual transaction, rule, wiring, point, resource, child, ownership, readback and domain products are qualified; global fail-closed completeness remains the independently pending .49.2.2.3.2.2.3 integration gate.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.1`
  Status: `done`
  Goal: `Retain actual independently built generated transaction child products.`
  Acceptance: `Collect canonical generated child IR from cloned child source, including activation history, child storage read/write interfaces, named completion and child point resolution, without requiring a conflicting parent merge. Compare actual production children, helper collision allocations, source/physical identity stability, reused/domain ownership, strict carriers and source isolation. Preserve child validation and statically pruned exclusions; parent connection and final composition names remain later obligations.`
  Verification: `T1945 qualifies complete actual child products, physical/source identity stability, helper collisions, reused/domain scopes, strict carriers and source controls. The complete T1945/T1936/T1938/T1934/T1904/T1917/T1255 cohort passes; native schedule before/after is byte-identical. Book fixtures/build and implementation doctrines/hooks pass. Broader qualification is now consumed; .2 owns remaining parent connection, grant/priority and final composition coverage.`
  Commit: `b5990b98a implementation; this slice consumes qualification`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2`
  Status: `done`
  Goal: `Close grant/priority parent-child connection and library ATL domain reservation coverage.`
  Acceptance: `Qualify actual later grant/priority products, parent storage/completion connections and library/ATL/final domain realization names with stable source/physical projections. Retain strict executable admission, distinct scopes and complete gate .3.2.2.3; split remaining producer boundaries as needed.`
  Verification: `All declared child producer leaves are complete and verified in their evidence below. Actual transaction, rule, wiring, point, resource, child, ownership, readback and domain products are qualified; global fail-closed completeness remains the independently pending .49.2.2.3.2.2.3 integration gate.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.1`
  Status: `done`
  Goal: `Retain actual parent completion products with explicit instance ownership.`
  Acceptance: `Collect the real completion-retention producer outputs from detached source states, activation records and declaration-name inputs without merging conflicting raw widths/roles or finalizing a parent IR. Retain explicit instance-to-signal allocation records from production, qualify namespace inputs, real seen/ready helpers and rewritten joins, source/physical ownership, helper-looking formals, source isolation and strict carriers. Preserve public reports and existing completion behavior; parent storage/completion-output connections and full reservations remain later gates.`
  Verification: `T1946 qualifies actual allocation inputs/ownership, declarations, dynamic join guards, portable fixed/formal collisions, namespace controls, raw conflicts, isolation and strict carriers. Focused regression/book checks pass; native schedule before/after is byte-identical. Evidence: .artifacts/formal-completion-products/.`
  Commit: `this slice`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2`
  Status: `done`
  Goal: `Close remaining grant/priority parent storage and final composition reservations.`
  Acceptance: `Qualify actual grant/priority products, parent storage/named-completion connections, library/ATL and final domain realization names with source/physical provenance. Preserve strict executable admission and separate namespaces before complete gate .3.2.2.3; split remaining producer boundaries as needed.`
  Verification: `All declared child producer leaves are complete and verified in their evidence below. Actual transaction, rule, wiring, point, resource, child, ownership, readback and domain products are qualified; global fail-closed completeness remains the independently pending .49.2.2.3.2.2.3 integration gate.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.3`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.1`
  Status: `done`
  Goal: `Retain actual reusable library and resolved ATL child products.`
  Acceptance: `Share real independent child construction and composition selection with executable builds, preserving canonical module conflicts, origin and port metadata. Keep children detached from source and parent formal widths; qualify source/physical products, bound parameters, storage and ATL data interfaces, strict carriers and unchanged public schedules. Parent connections and outer domain names remain later gates.`
  Verification: `T1947/T1945 and the source/completion/library/ATL/schedule cohort pass; full real child and composition products agree before/after formal projection, strict carriers pass, native ATL schedule is byte-identical and book checks pass. Evidence: .artifacts/formal-reusable-products/.`
  Commit: `this slice`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.3`
  Status: `done`
  Goal: `Reconcile stale ATL resolution and composition book summaries.`
  Acceptance: `Remove contradictions between the composition and orchestration-backlog actor-type-resolution summaries and the shipped resolved-child/multi-child/data-route sections, grounded in actual supported fixtures and contracts. Preserve explicit unsupported composition/runtime boundaries. Run book fixture/build checks.`
  Verification: `Priority medium documentation defect fixed in composition and orchestration-backlog summaries: actual native resolved-child, trigger-batch and vector route reports confirm the shipped subsets. T1332/T1376 and mdBook build pass; existing group/join/CDC/routing limits remain. Evidence: .artifacts/atl-book-status/.`
  Commit: `this slice`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2`
  Status: `done`
  Goal: `Close remaining parent connection grant and outer domain reservations.`
  Acceptance: `Retain actual parent storage/named-completion/readback connections and grant/priority products with typed scoped identities; qualify outer domain realization before complete reservation integration. Split producer and admission boundaries safely without fabricating executable raw parent widths.`
  Verification: `All declared child producer leaves are complete and verified in their evidence below. Actual transaction, rule, wiring, point, resource, child, ownership, readback and domain products are qualified; global fail-closed completeness remains the independently pending .49.2.2.3.2.2.3 integration gate.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.1`
  Status: `done`
  Goal: `Qualify actual resource priority and finalization declaration namespaces.`
  Acceptance: `Observe real production stages independently and prove which declaration names they introduce or preserve. Compare round-robin additions with existing potential resource products; qualify rule/rule, rule/transaction, unique named-drive and resource variants, projected formals, state-active guards and strict carriers. Preserve canonical collision/conflict failures. Do not merge raw widths, execute fabricated parents, or infer runtime support from this namespace gate.`
  Verification: `T1948 observes actual production stage order and before/after declarations, exercises grants and priority metadata, verifies raw/projected inventories and strict carriers, and retains collision/user/conflict refusals. Resource/report regression and book checks pass. Evidence: .artifacts/formal-arbitration-namespace/.`
  Commit: `this slice`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2`
  Status: `done`
  Goal: `Retain parent ownership connections and outer domain declaration products.`
  Acceptance: `Collect real parent storage-write/read, named-completion/readback and outer domain realization names with typed ownership and stable source/physical correspondence before complete reservation integration. Keep raw conflicts distinct and executable validation strict; split bounded producer boundaries as needed.`
  Verification: `All declared child producer leaves are complete and verified in their evidence below. Actual transaction, rule, wiring, point, resource, child, ownership, readback and domain products are qualified; global fail-closed completeness remains the independently pending .49.2.2.3.2.2.3 integration gate.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.1`
  Status: `done`
  Goal: `Retain actual parent storage-write handoff declaration plans.`
  Acceptance: `Share canonical handoff allocation with executable connection after its unchanged writer admission. Source preparation retains detached potential ports, widths/types, DTs and typed instance/storage links using declaration membership rather than conflicting raw widths. Qualify actual source/physical products, helper collisions, separate scopes, raw conflicts, strict carriers and native report parity. Competing writers still fail in executable connection; read/named-completion/readback and outer domain products remain later gates.`
  Verification: `T1949/T1946 and book checks pass; actual plan and installed ports/DTs agree before/after projection, strict carriers pass and native schedule is byte-identical. Complete parent/child/completion/scalar-writer/schedule cohort passes; .artifacts/formal-parent-write-products/regression.log is consumed with no new runtime opt-in.`
  Commit: `461d851a9 implementation; this slice consumes qualification`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2`
  Status: `done`
  Goal: `Retain remaining parent read completion readback and outer domain products.`
  Acceptance: `Collect canonical storage-read and named-completion handoffs after write declarations, qualify library-readback namespace preservation and outer domain realization, then complete the reservation integration gate. Preserve source/physical ownership and strict validation.`
  Verification: `All declared child producer leaves are complete and verified in their evidence below. Actual transaction, rule, wiring, point, resource, child, ownership, readback and domain products are qualified; global fail-closed completeness remains the independently pending .49.2.2.3.2.2.3 integration gate.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.1`
  Status: `done`
  Goal: `Retain canonical parent storage-read handoff plans and qualify allocator scope.`
  Acceptance: `Share actual read-handoff allocation and products with source preparation after potential write products. Preserve one live owner view per storage target, exact widths/types and explicit consumer links. Qualify allocator inputs, authored block-name collisions, raw formal projection, existing write products, source isolation, strict carriers and native reports. Own and repair any demonstrated read allocator collision defect within this leaf; named completion/readback/domain stages remain later gates.`
  Verification: `Children close the real read/block collision, retain and qualify actual reader plans, and reject invalid actor-variable keyword names with compiled legal controls. Next named-completion/readback/domain products remain independently owned by .2.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.1.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.1.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.1.3`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.1.1`
  Status: `done`
  Goal: `Prevent parent read handoffs from colliding with authored DT or state names.`
  Acceptance: `Reserve existing block names before allocating read handoff ports/DTs, preserve their source owners and guards, and qualify the retained real collision with an independent HDL observation plus strict/native report checks. Keep normal read widths/types, shared live views and connection links unchanged; retain exact before-fix evidence.`
  Verification: `High-priority defect: a rule named isf_storage_read_cell guarded by fire collides with the generated actor-storage read DT. Public --strict --check --json succeeds, but emitted collision.sv drives isf_storage_read_cell_en unconditionally and flag ignores fire. Reproduce .artifacts/formal-parent-read-products/block-collision.isf; the emitted parent has duplicate DT headers. The initial runtime-before.json stops at the separately owned cell keyword compile error (.1.3). The isolated legal-collision.isf compiles and fails runtime with READ_HANDOFF_LOST_RULE_GUARD fire=0 flag=1. T1950 passes independent guard/read/reset execution after using the existing full _reserved_names scope; the complete scalar/aggregate/write-plan/schedule regression passes.`
  Commit: `54b51ef10; qualification closure in this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.1.3`
  Status: `done`
  Goal: `Resolve accepted storage names that cannot compile as emitted HDL identifiers.`
  Decision: `Use the existing shared keyword union for actor var/variable names, which become emitted signal names. Reject with actor/name/target/rename guidance before lowering. Banks retain logical names because emitted element names have numeric suffixes. Decision 0110 records this bounded source contract; four new formal-preparation tests migrate their legal controls from cell to value_reg. Keep explicit keyword rejection and independent compiler controls.`
  Acceptance: `Trace the public identifier policy for storage named cell, preserve the actual compiler refusal, and repair or explicitly diagnose unsupported backend names with focused native/report and independent compiler controls. Do not silently rename public contracts or weaken compiler checks.`
  Verification: `The exact original source now fails early with FSMGEN_LANGUAGE_ISF_STORAGE_IDENTIFIER; before strict success and Verilator compile failure remain retained. T1952 qualifies variable aliases, target case rules, keyword bank identity, full native/API/newline check/semantic failures and the existing schedule refusal contract. Independent Verilog/SystemVerilog lint passes legal controls; VHDL emission passes but GHDL is absent from PATH. The migrated formal/domain controls, existing storage reset/field tests, diagnostic accounting and book fixtures pass. The exact corrected dataop_demo book example independently passes Verilator lint.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.1.2`
  Status: `done`
  Goal: `Retain actual parent read handoff declaration plans after allocator repair.`
  Acceptance: `Share the corrected production read allocation/product boundary with source preparation after potential write products; retain live shared views, widths/types and typed storage/consumer links. Qualify source/physical plans, collisions, isolation and strict/report parity without altering writer admission.`
  Verification: `T1951 compares complete actual read allocation inputs and installed ports/types/DTs/storage identities/consumer links before and after formal projection. Scalar, typed aggregate, selected bank, shared readers, read/write ordering, portable formal/fixed/rule collisions, raw ownership refusal and detached snapshots pass. Before inventory omission is repaired; native schedule before/after is byte-identical. The complete T1951/T1950/T1949/T1946/T1255 cohort passes with independent guard/read/reset runtime enabled; book fixtures and build pass.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2`
  Status: `done`
  Goal: `Retain named-completion readback and outer domain reservation products.`
  Acceptance: `Collect actual named-completion declaration plans after storage connections, qualify library-readback declaration preservation and outer domain realization, then complete the reservation integration gate without weakening executable ownership or report contracts.`
  Verification: `All declared child producer leaves are complete and verified in their evidence below. Actual transaction, rule, wiring, point, resource, child, ownership, readback and domain products are qualified; global fail-closed completeness remains the independently pending .49.2.2.3.2.2.3 integration gate.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.3`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.1`
  Status: `done`
  Goal: `Retain actual named-completion handoff and local-pulse plans.`
  Acceptance: `Share canonical completion allocation after read/write handoffs with detached source preparation. Preserve per-instance ports, actor-output identity, local delayed pulses, OR views, widths/types/resets and source ownership. Keep mixed-writer admission executable and separate from potential plans. Qualify actual complete inputs/products, projection, collisions, source isolation, strict/report parity and independent named-completion runtime before commit.`
  Verification: `T1953 qualifies complete actual named-completion inputs/products and installed metadata/links/rewrites against source and projected plans. before-full.json shows missing child input/local pulse/view names; after.json has none. Native schedule remains byte-identical. Typed and literal reset cases remain separate supported contracts; multiple completers, canonical/local exclusions, portable collisions, snapshot isolation and mixed-writer refusal pass. The full selected regression including independent named-completion runtime and complete native/API/newline reports passes.`
  Commit: `73d4047be; qualification closure in this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.2`
  Status: `done`
  Goal: `Qualify library readback namespace preservation after completion connections.`
  Acceptance: `Observe real library readback ownership admission and emitted interface adaptation, prove declaration namespace preservation across legal and rejected cases, retain any actual missing products if found, and preserve strict/native/API/MCP behavior.`
  Verification: `T1954 observes real source/projected readback and finalization calls: complete effects are interface direction/storage role only, with no declaration additions/removals and no uncovered prepared names. Ordinary, typed, observed, direct-formal, mixed completion and no-library controls pass; writer/reset/default/duplicate/completion refusals preserve namespace and propagate original errors. T1914/T1915 independent library/domain execution and T1947 reusable-product checks each pass; the canonical T1255 schedule matrix and T1376 book examples pass separately. The aggregate invocation exits on a mistyped nonexistent final selector after all real selected tests pass; this harness error is recorded without claiming a successful aggregate exit.`
  Commit: `8ca4fe501; qualification closure in this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.3`
  Status: `done`
  Goal: `Qualify outer-domain declaration realization before complete reservation integration.`
  Acceptance: `Trace actual domain-specific parent/child/CDC/top realization against prepared products and source identities. Own any missing producer before declaring reservation coverage complete; preserve domain and public report contracts.`
  Verification: `All declared child producer leaves are complete and verified in their evidence below. Actual transaction, rule, wiring, point, resource, child, ownership, readback and domain products are qualified; global fail-closed completeness remains the independently pending .49.2.2.3.2.2.3 integration gate.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.3.2`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.3.1`
  Status: `done`
  Goal: `Repair stale domain chapter storage/completion/library capability limits.`
  Acceptance: `Trace the refusal paragraph to its introducing commit and current canonical qualification; replace obsolete limits with supported same-domain storage reads, named completions and library readback, preserving the independently pending watchdog/local-call/VHDL limits. Verify book examples and build.`
  Verification: `Reproduce by reading the paragraph after domain_child_read in docs/book/src/13a-actor-interface.md: it contradicts T1916 storage reads, T1913 named completion and T1914/T1915 library contracts. Impact: the user-facing book falsely denies shipped capabilities. Repaired with current ownership/readback/completion contracts and retained independent watchdog/local-call/VHDL limits. T1376 and book build pass.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.3.2`
  Status: `done`
  Goal: `Qualify actual domain source shells, local products and outer identities.`
  Acceptance: `Observe real domain-specific parent/child/CDC/top realization against prepared products, retain missing canonical producers before complete reservation integration, and preserve strict/native/API/MCP contracts without fabricated parent merges.`
  Verification: `All declared child producer leaves are complete and verified in their evidence below. Actual transaction, rule, wiring, point, resource, child, ownership, readback and domain products are qualified; global fail-closed completeness remains the independently pending .49.2.2.3.2.2.3 integration gate.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.3.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.3.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.3.2.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.3.2.4`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.3.2.1`
  Status: `done`
  Goal: `Retain actual detached per-domain source preparation products.`
  Acceptance: `Share the production domain source constructor with formal preparation, retaining per-domain contexts and declarations without executing a fabricated parent merge. Qualify actual source and namespace equality, activation/event crossings, domain ordinals, generated/library children, ownership, collisions, isolation and report stability.`
  Verification: `Reproduce with .artifacts/formal-domain-products/activation.isf and probe.pl: executable caller/callee declarations are absent from monolithic preparation despite successful --emit-schedule-json. Impact: future formal allocation could collide with external-activation helpers. The shared domain source constructor now supplies detached local preparation; activation-after.json has no missing names and native schedules compare byte-identically. T1955 and the full T1247/T1387/T1924/T1942/T1945/T1912 cohort pass, including independent domain runtime and public reports. Book fixtures/build and staged doctrine pass.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.3.2.2`
  Status: `done`
  Goal: `Retain or prove outer domain composition identity reservations.`
  Acceptance: `Cover actual module/file/flat-instance/wiring/CDC declaration namespaces from domain realization and top emission using canonical producers. Keep separate module scopes and logical/public identities explicit; no fabricated parent execution.`
  Verification: `T1956 observes exact outer FSM/CDC/interface/wiring/file identities from actual realization, unchanged complete local IR across materialization/top emission, local declaration coverage and stable public ports/outer identities after formal projection. Generated/reused/library/empty siblings, event/activation/no-reset, portable domain and actual pin/module collision controls pass. Multi-domain ATL event composition is canonically refused. No additional local producer is needed. The complete T1956/T1955/T1895/T1947/T1255 cohort passes, including independent naming/CDC runtime and complete native/API/newline reports. All jobs are consumed.`
  Commit: `fc19fb1f5; qualification closure in this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.3.2.3`
  Status: `done`
  Goal: `Qualify complete domain reservation integration.`
  Acceptance: `Join prepared domain products and outer composition identities against real lowering, formal projection, portable collisions and native/API/MCP reports, retaining independent domain runtime and existing refusal boundaries.`
  Verification: `T1957 qualifies combined domain resources, priorities, private/storage shadows, declaration permutations, case-folded conflicts, generated reads/writes and completion sharing against actual lowering. The discovered composed-domain CDC handoff loss is repaired by honoring explicit direction-matching boundary maps. T1958 strict/native/API/newline reports and independent SystemVerilog/Verilog stopped-clock/reset/repeated-activation oracles pass. Full focused regression, book examples and book build pass; all jobs consumed.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.3.2.4`
  Status: `done`
  Goal: `Correct stale activation parser-test support commentary.`
  Acceptance: `Align T1386 header with its actual unused-crossing refusal and T1387 supported used-crossing contract; run both focused tests without changing admission.`
  Verification: `git log -S identifies 13cbceeb6 as the integration change that updated the unused-crossing test while retaining the obsolete header. The corrected header distinguishes malformed, unused and supported used crossings. T1386/T1387 pass; no source admission or test assertion changed.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.3`
  Status: `done`
  Goal: `Qualify complete reservation integration before production renaming.`
  Acceptance: `Join actual producer inventories with a fail-closed completeness contract. Prove final allocation/emission cannot add unreserved collisions, including source declaration permutations, case-folded names, helper-looking formals, separate modules and domain realization. Preserve source/public identities and commit before .3.3.`
  Verification: `All declared children are verified. Actual producer inventories, checked preparation inputs and a detached final-module coverage guard now qualify canonical allocation, separate scopes and missing-reservation failures. Evidence remains with those leaves. Production formal rewriting and public report preservation start at .49.2.2.3.3; controller/runtime qualification remains separate.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.3.2`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.3.1`
  Status: `done`
  Goal: `Collect all prepared reservation products through a checked scope-aware contract.`
  Acceptance: `Replace ad hoc product-name filters for new consumers with one explicit prepared-input collector. Reject missing, unknown or malformed product categories and mismatched live transaction/domain/child membership. Preserve detached deterministic provenance and separate parent, generated/reusable child and domain scope identities. Qualify real source products without an executable conflicting parent merge. This input contract alone does not prove final emitted completeness.`
  Verification: `T1959 qualifies missing/malformed/unknown categories, live and child membership, source/domain identity, erased partition/domain controls, cycles, deterministic detached provenance, raw storage/formal shadows, FIFO and static-zero/single-domain cases. T1957 consumes the checked collector in real domain projection; T1937/T1955/T1956 and book fixtures/build pass. Final emitted completeness remains child .2; no automatic rewrite or runtime support is claimed.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.3.2`
  Status: `done`
  Goal: `Verify final executable declarations and allocation against complete prepared scopes.`
  Acceptance: `Join the checked input inventory with actual projected modules, final declaration ownership and outer scope boundaries. Fail closed on missing reservations or unexpected scopes, including injected omissions and helper/formal aliases. Qualify declaration permutations, case-folded conflicts, library/generated children and domains. Preserve source/public reports and strict refusal boundaries; only then close the global contract before production renaming.`
  Verification: `T1960 checks actual public-lowering modules and strict exported carriers, with omitted real helper, late explicit/implicit declarations, stale plans, scope-set/identity and formal width/role/block-alias mutations. Generated/FIFO/ATL/storage/rule/monitor cases and declaration/case permutations pass. T1957 checks combined actual domains. The complete focused regression, final child-scope falsification, book fixtures/build pass; all jobs consumed. This detached guard is qualified for production integration next; it does not claim controller/runtime repair.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.3`
  Status: `done`
  Goal: `Wire scoped declarations, operands and bindings while preserving source-facing reports.`
  Acceptance: `Use the qualified contexts/reservations and detached resolvers to connect physical formal identities through parent/domain/child lowering, widths/types/resets/roles, local calls and rule payload destinations. Preserve source binding names, logical state ownership and diagnostics; reject unresolved collisions. Qualify focused generated artifacts and complete native/API/MCP reports in the same implementation commit. Do not claim the separate controller/runtime repairs complete.`
  Verification: `Both children are verified: original binding report products and automatic production physical scope integration. Evidence remains with those leaves. Actual storage identities and authored report operands are now separate; broad scheduler-family qualification is .49.2.2.3.4 and controller/runtime repairs remain separately owned.`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.3.2`
  Commit: `children below`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.3.1`
  Status: `done`
  Goal: `Retain canonical authored binding report metadata before physical projection.`
  Acceptance: `Collect the actual source binding report producer during detached preparation, including caller expressions, callee names, widths, timing, generated/local/rule sites and domain ownership. Validate raw-shadow sources without executing a conflicting parent merge; preserve detached snapshots and compare with native public reports for admitted controls. Qualify the checked input contract extension. No production rewrite is enabled in this preparatory slice.`
  Verification: `T1961 compares complete original records with public reports and actual domain producers, preserves caller/callee names, expression text and timing across detached physical lowering, and qualifies raw storage shadows and snapshot isolation. Complete native/API/newline schedules agree. T1959/T1960/T1957/T1243/T1241/T1255 and book fixtures/build pass. The stale partial-producer comment now points to the separate final guard; automatic integration remains child .2.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.3.2`
  Status: `done`
  Goal: `Integrate physical formal projection and reservation coverage into production compilation.`
  Acceptance: `Use complete prepared contexts and inventories, canonical allocation, scoped transaction/rule rewriting and final actual-module coverage in lowering and reporting. Preserve authored binding metadata, logical controller ownership and diagnostics, keep generated interfaces unchanged, and qualify native/API/newline reports plus emitted declarations for parent/domain/child and collision cases. Do not close separate execution repairs.`
  Verification: `FormalLowering now prepares, allocates and rewrites direct formals at scheduler lower/report entry, checks actual parent/domain/child scopes before emission, and restores authored binding/wait/loop/temporal/bank metadata only in a detached report view. T1962 qualifies raw pin/storage shadows, generated reads, automatic domains, complete native/API/newline reports, strict exported carriers and late-declaration refusal. Independent SystemVerilog/Verilog public-pin oracles pass dynamic waits, reset and repeated activation. Existing scope/domain/binding tests are migrated from obsolete raw-name expectations; source validation and raw LoweringIR refusal controls remain. Book examples/build pass. Broad family qualification and independent execution remain separate.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.4`
  Status: `done`
  Goal: `Qualify scoped production integration across existing scheduler families.`
  Acceptance: `After production wiring, run declaration permutations and actor/local, sibling/caller/callee, direction/type and generated-prefix collision controls plus the warranted broad regression gate. Reconcile book/spec/canonical records with the final identity/report contract. Keep remaining local-payload, shared-writer, independent-controller and local-call runtime obligations in their owning leaves. Commit before the payload repair frontier.`
  Verification: `T1963 qualifies authored loop/exit/continue and bank report operands against unchanged physical IR, typed sibling declaration permutations, source helper collisions and strict carriers. Family qualification exposed and repaired unassigned direct-formal input leakage: parent/domain IR now emits explicit internal roles and final coverage requires them. Exact semantic ports and SV/Verilog/VHDL declarations exclude read-only/unused formals. Existing parameter/constant/package and selector tests use private names without weakening width or conflict checks. Focused family, internal-ownership, source-report, final-reservation/domain and book gates pass; independent T1962/T1510 runtime passes. No independent-controller/local-call or VHDL runtime claim.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.4`
  Status: `done`
  Goal: `Honor formal widths during parser bit-operation desugaring.`
  Acceptance: `Run immediately after .1 and before .2. Reproduce valid wider-formal rejection and invalid narrower-formal acceptance for clear-bit index 7 with actor/formal status widths reversed. Fix parser lexical width precedence and qualify set/clear/toggle, set-field, rotate and bit/field tests, port-only and actor-shadow cases, aliases/parameter widths and nested bodies without weakening range checks. Verify source expansion and emitted behavior where current controller/scope support permits it; keep production scope integration .3 explicit. Update book/facts and commit.`
  Verification: `T1926 qualifies literal formal precedence across all shared bit/field/rotate helpers, nested bodies, unresolved parameter/type boundaries and genuine default widths. Direct and generated production HDL passes repeated/reset controls with complete native/API/MCP reports and strict IAL0 replay. Existing helper, scope and book-example regressions pass. Type-placeholder zero-mask emission now fails closed; direct physical identity integration remains open.`
  Commit: `this slice`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.5`
  Status: `done`
  Goal: `Align dynamic-wait operator admission with the emitted carrier grammar.`
  Acceptance: `After the clause walker and before production scope integration .3, reproduce lowerer admission followed by strict carrier rejection for ~, &&, || and unary concat wait expressions. Use the actual carrier contract to reject unsupported shapes at the wait boundary, or qualify any intended translation without changing operator meaning. Cover working known-width arithmetic/boolean/concat forms and complete native/API/MCP diagnostics. Update book and canonical wait facts and commit.`
  Verification: `T1929 now rejects unsupported direct/nested wait shapes before carrier serialization, qualifies every retained operator through strict replay, preserves full check/semantic native/API/MCP reports and the documented schedule refusal boundary. Existing SystemVerilog/GHDL timing, wait lowering, scoped clause and source-failure regressions pass; book builds. .52 then .6 are next before .3.`
  Commit: `this slice`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.6`
  Status: `done`
  Goal: `Repair stale runtime-wait lowering examples in the book.`
  Acceptance: `After .5 and before .3, census the runtime-wait examples in 13h against generated current carriers and the canonical count-predicate facts. Replace stale low-bit positive-entry guards with actual nonzero predicates; check pending/consecutive waits, joins, branches, repeat/switch/loop and exit/continue predecessors for related drift. Preserve explanatory intent while making generated examples accurate. Retain reproducible source/fragment evidence, run book-example checks/build and commit.`
  Verification: `The retained runtime-wait-book audit maps every generated wait excerpt to complete sources and current primary-carrier states, with explicit prose-predecessor controls. Corrected nonzero predicates, completion-ready join signals, idle readiness and exact transition grouping/order. The book and audit mark the extract intermediate carrier as a tracked refusal under .53; other carrier replays pass. T1376/T1244 pass and mdBook builds. Next .53, then .49.2.2.3.`
  Commit: `this slice`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.3`
  Status: `pending`
  Goal: `Qualify local-call scope end to end after controller and identity repairs.`
  Acceptance: `After .49.2.2 and the local-call execution repair, exercise repeated/nested calls and caller/callee same-name ports with distinct actor storage. Prove payload capture and output completion timing, owner reset, exact interfaces, source replay and native/API/MCP parity; keep unqualified contention and recursive calls explicit. Commit synchronized docs before .49.3.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.3`
  Status: `pending`
  Goal: `Qualify explicit local declarations that share names with actor storage.`
  Acceptance: `After port scope repair, reproduce generated and direct local storage names against actor storage, including differing widths and reset/default values. Parser bit-operation lookup gives explicit locals precedence, but child storage ownership currently excludes only explicit ports. Resolve scope consistently without mutating the actor register, qualify runtime/reset/report behavior and synchronize docs before .50.`
  Verification: `Local declarations are separate transaction clauses, not entries in tx ports. _parse_local_decl checks interface and existing counter collisions but not actor storage. _build_signal_width_map and child actor-storage cleanup therefore require a dedicated local-name ownership audit; no current shadowing support is claimed from this code observation.`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.50`
  Status: `pending`
  Goal: `Diagnose the unclassified newline/API schedule mismatch retained during whole-aggregate qualification.`
  Acceptance: `After .49 and before partial writer implementation, replay T1904 multiple_readers with complete response diagnostics and a stable implementation snapshot. Inspect source-query failure and transport paths, determine whether concurrent implementation mutation explains the old error, and qualify any repair with deterministic controls. The original response payload was not printed and cannot be invented; keep that missing evidence explicit. Do not mark a product defect fixed solely from a passing retry.`
  Verification: `regression.log under .artifacts/whole-aggregate-writes records one missing result envelope for multiple_readers schedule while the implementation was being edited. All other cases and T1917 pass. multiple-readers-probe.log subsequently passes the isolated complete native/API/newline reports on stable files. T1904 now prints the actual response/stderr on mismatch. Root cause is not yet established; the missing first error payload prevents attribution.`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51`
  Status: `done`
  Goal: `Rollover the saturated decision-record collection while preserving exact history and active contracts.`
  Acceptance: `Immediately after .32.1.3.3.1.2.1, audit the rationale collection and its declared lifecycle under LIVE_DOCUMENT_SIZE_CONTAINMENT.md. Select the smallest semantic rollover that restores bounded current decision capacity without losing active policy, stable decision identities, exact historical text, relative links or Knowledge Map answers. Follow the atomic classification/reconstruction/index/retrieval protocol; split safe leaves before writes, prove source identity and semantic closure separately, add enforcement and negative controls where needed, synchronize reader guidance and commit. Do not merely increase rollover allowance or reclassify overflow to evade containment. Then resume controller contract .32.1.3.3.1.2.2.`
  Verification: `Whole-record sealing and canonical identity partitioning preserve fixed originals, finite root aliases and active current authority under predecessor ceilings. Atomic delivery, complete fixed-source consumer/question closure, production birth, malformed-product refusal and published floors are qualified by the children. Final source/doctrine qualification and scoped frontend handoff are .51.3.3.3.2; no external/runtime signoff is implied.`
  Commit: `completed through committed children; final closure in this commit`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.1`
  Status: `done`
  Goal: `Audit decision-record rollover boundaries and consumers without changing decision authority.`
  Acceptance: `Inventory exact source identities, current pressure, record status, front matter, links and executable consumers. Compare bounded storage choices against the existing append-once/supersede convention. Select a whole-record seal and stable retrieval route that preserves every decision, active policy, old link and Knowledge Map answer, with independently verified source/reconstruction/navigation products. Keep director-deferred agent-era document reassessment outside this narrow declared decision-store task; commit the audit before the atomic migration.`
  Verification: `Exact source/cohort/consumer census and contract selection retained in docs/audits/decision-record-rollover-census-20260927.json and the .51.1 audit below. No records moved; migration qualification belongs to .51.2.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.1: audit exact decision-record rollover`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.2`
  Status: `done`
  Goal: `Perform the selected atomic decision-record rollover and enforce exact retrieval.`
  Acceptance: `After .51.1, implement the bounded record reader/reconstruction checker, planted-negative tests, immutable archive/manifest, root pointers and doctrine registration in one atomic migration. Preserve record authority and exact original content separately from relocated link rendering; prove source/semantic/live/residue products, complete links and Knowledge Map closure. Record the rollover decision within the migrated capacity, derive budgets from the retained working set without an unrelated ceiling increase, update reader guidance and commit. Restore controller contract adoption only after the full gate passes.`
  Verification: `T1923 independent Git reconstruction and negative controls plus T1554 containment regression pass. Exact originals, view and reader declarations are atomic; Knowledge Map parity holds. See .51.2 evidence below for limits and separate live/residue products.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.2: seal decision originals with exact retrieval`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3`
  Status: `done`
  Goal: `Contain decision identity and index cardinality before file-count rollover.`
  Acceptance: `Activate before an added record would enter the rationale file-count rollover band. Audit stable external and generated provenance identities, select bounded identity/index partitions with exact retrieval, preserve all policy authority and record links, qualify negative navigation controls and commit without widening the file ceiling. This future warning-pressure task does not block controller contract adoption after .51.2.`
  Verification: `Exact source/index identities and complete canonical partitions are installed. Fixed consumer closure and complete-cohort birth/refusal/published-floor qualification preserve compatibility aliases, current authority and unchanged ceilings. Final .51.3.3.3.2 closes this capacity prerequisite before .60.4.3.2.3.6; dynamic/external consumers and runtime remain outside the proof.`
  Commit: `completed through committed children; final closure in this commit`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.1`
  Status: `done`
  Goal: `Audit exact decision identity, index and consumer cardinality before selecting rollover.`
  Acceptance: `At a fixed clean predecessor, census every decision identity, sealed original/forwarding page, current canonical body, index entry, front-matter identity and incoming tracked link/body/provenance consumer. Reconcile membership and per-file dimensions/digests with independent Git enumeration and published reader results. Separate external path compatibility from mutable fact storage and generated navigation; select a bounded semantic partition/identity contract with exact retrieval and retained policy/Knowledge Map answers. Record alternatives and limitations honestly, commit the audit before moving records, and do not increase ceilings or infer external consumer absence from repository search.`
  Verification: `Fixed source 25c01f0127144922ade78951b91439e1d9221c08 has exact IDs 0001-0114 and INDEX: 115 root files, 50 sealed forwarders and 64 canonical bodies; the next root record enters the unchanged 128-file target's rollover band. Tracked bounded producer/census reconcile per-ID index destinations and per-file dimensions/digests with an independent direct-directory Git enumeration and literal full ID set. Every pinned public sealed-reader result equals its independent Git source. Final replay is byte-for-byte equal despite current owned doc changes; explicit no-submodule recursion and same-volume captured-reader fixtures close ambient-input drift. Scoped basename/fragment consumers and separate generic code candidates identify stable provenance, four literal fragment destinations, T1809's direct body read, 0062/0091 self-searches and flat-only ceiling-authority validation. Canonical 0108 selects a finite pre-transition compatibility cohort plus current continuity/language-API/verification partitions, with exact authority/status/question/source/navigation preservation and no ceiling increase. Full atomic integration and fresh-record capacity remain .2-.3. Guarded T1999/T1923/T1554 reports All tests successful, Files=3, Tests=22; equal-count duplicate/substitution/misroute and missing/escape controls refuse. Syntax and book build pass. Source-bound census/search exclusions, current/generic reader differences and external/dynamic limits are explicit; no migration, external consumer signoff or native execution is claimed.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2`
  Status: `done`
  Goal: `Apply the selected bounded decision identity/index rollover atomically.`
  Acceptance: `After .1, split implementation prerequisites if needed, then preserve every pre-transition path/identity and exact original retrieval while placing mutable canonical records and navigation in bounded semantic partitions. Freeze any finite compatibility projection by exact source/membership proofs; never create unbounded alias growth. Update readers, metadata consumers, indexes and declared surfaces together, preserve stable question/answer and policy authority, and qualify corrupt/missing/duplicate/misrouted navigation controls. Restore legitimate current capacity without raising predecessor ceilings or merely relabeling overflow.`
  Verification: `Audit/contract selection is committed at 8acfa9c087f971706fd35a3755d208792d27076f. Split pure catalog/path/identity controls, actual reader/authority integration, and atomic storage/navigation rollout before changing source locations. Every first admitted canonical path must use complete identity and retrieval gates.`
  Commit: `completed through committed children; atomic delivery in this commit`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.1`
  Status: `done`
  Goal: `Prepare closed decision catalog/path/identity controls before live integration.`
  Acceptance: `Define and independently qualify the bounded canonical location and catalog contract selected in 0108: finite pre-transition root identities, current continuity/language-API/verification parts, exact ID-to-source/type/status/question metadata, immutable original retrieval and compatibility headings. Reject escaping/symlinked/unknown-topic paths, duplicate or substituted IDs, malformed dimensions/digests, unresolved sources and borrowed identities. Preserve caller values and existing published sealed-reader/flat authority behavior; no source moves or live canonical authority admission yet. Keep one canonical identity authority across eventual Python reader and Perl gate consumers, then commit before wiring.`
  Verification: `The pure shared Python preparation module defines closed current parts, per-ID source paths/types/metadata/headings and independently supplied immutable originals. Literal future-store fixtures establish exact products, detached success/failure callers and fresh IDs without compatibility growth; borrowed sealed/body/fact IDs, supported-topic misroutes, duplicate/reordered/missing cohorts, copied metadata, invalid dimensions/digests, unresolved files and symlinked parent components refuse. Selected snapshot bytes use the same identity contract. Initial transition metadata is exact; subsequent owned status changes retain original text. Every actual current canonical body parses within the grammar. Guarded T2000/T1999/T1923/T1560/T1554 reports All tests successful, Files=5, Tests=32. Existing public reader and flat authority code/storage are unchanged. Canonical 0108 documents the closed schemas, bounded helper and caller source-authentication duty; .2 integrates actual reader/authority gates before .3 moves sources. Syntax and book checks accompany this commit.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2`
  Status: `done`
  Goal: `Integrate catalog-aware public reading and fresh authority paths before source rollout.`
  Acceptance: `After .1, connect qualified identity/path/retrieval gates to the published reader, complete index/heading verification and ceiling-authority addition boundary using independent supplied future-store fixtures. Preserve existing read/check/unknown-ID behavior where no delivered catalog exists, legacy flat authority identities and generated provenance strings. Qualify accepted current/original products and precise malformed/duplicate/stale/misrouted/missing-source failures; no partial output or unowned canonical admission. Keep real source paths unchanged until .3, then commit.`
  Verification: `Authenticated loading/navigation, public selected reading, unconditional prior-current continuity, exact fresh authority and hostile mode qualification are complete under children .1-.3. Production sources remain unmoved; .51.3.2.3 owns fresh capture and atomic rollout.`
  Commit: `this commit`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2.1`
  Status: `done`
  Goal: `Qualify authenticated decision-store loading and complete compatibility/navigation controls.`
  Acceptance: `Before public integration, load fixed relative source/original/catalog products through the shared preparation checks with independently supplied authenticated source and original-index digests. Retain the exact pre-transition index, including its title/type/summary values, as recoverable immutable evidence. Derive finite root compatibility pages from fixed source paths/headings and semantic parts; preserve all actual heading destinations without inventing a competing slug grammar. Qualify complete root and part index identity/destination closure, selected-snapshot access, exact transition metadata/navigation and corrupt/missing/duplicate/misrouted/stale/symlinked controls. Keep later owned current status/navigation updates distinct from initial exact preservation. Do not move real records or admit live canonical authority yet; commit the loader/navigation controls first.`
  Verification: `Shared store loading authenticates independent source/index fingerprints before catalog preparation and retains exact original records/index, including navigation values. Independent literal aliases preserve the complete original heading sequence without another slug grammar; complete root/part tables reconcile every ID/type/destination and bounded fixed root membership. Fresh IDs populate the new parts without old root aliases. Corrupt/stale/missing/duplicate/misrouted/type/heading/anchor/symlink controls refuse. Selected bytes require a complete selected inventory and cannot borrow ambient worktree data. Exact initial metadata/navigation is distinct from later owned current updates. Every existing current body, sealed original and root-index row fits the shared grammar. Final guarded T2001/T2000/T1999/T1923/T1560/T1554 completes All tests successful, Files=6, Tests=34, after a recorded incomplete aggregate hit the unchanged 88% memory cutoff at 88.2%. Syntax, book and bounded doctrine checks accompany this commit. Published readers, live authority and real source locations are unchanged; .2 now integrates actual public products.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2.2`
  Status: `done`
  Goal: `Integrate authenticated catalog stores into the published decision reader.`
  Acceptance: `After .1, connect authenticated stores and complete compatibility/navigation checks to actual published check/read/current/original operations. Qualify supplied future-store products and request failures through the actual CLI or its public boundary, preserve old no-catalog sealed-only behavior and unknown-ID rejection, and never emit partial output. Fixed source authority must come from the integrating caller or delivered production pin, never matching caller-supplied metadata alone; document supplied-store and production boundaries. Also close the owned P2 legacy archive schema-kind defect: JSON true must not be accepted as integer schema version one, and invalid schema must emit no record bytes. Also allow owned first-time fact indexing where the original had no fact identity, while preserving every existing identity/question. Reproduced P2: adding a unique fact ID/questions to originally unindexed current 0100 exits 1 with loses-source-fact-identity despite no existing key being lost; repair this overstrict null-identity equality in the shared helper and qualify through actual current/original CLI products. Real canonical sources remain unmoved until .3.`
  Verification: `Actual published CLI accepts independently supplied source/index fingerprints and explicit roots, validates complete stores, and delivers ordered captured original/current/fresh products with no partial output. Unknown/unavailable/malformed/oversized requests, missing or altered products and wrong canonical bindings refuse. Resolve names transition_source_revision explicitly and returns a bounded exact canonical binding without granting authority. Production fingerprints remain unset; installed mode must additionally preserve all published sealed originals/view/consumers. No-catalog sealed behavior and a helper-free selected legacy capsule pass. Reproduced JSON true schema admission is repaired with strict integer kinds, including float/string/null/boolean/aggregate controls. Reproduced overstrict first-time indexing is repaired: new unique fact IDs are allowed where none existed, existing IDs/questions remain, and initial transition equality still refuses additive change. Guarded final broad cohort reports All tests successful, Files=7, Tests=36; final wire/capsule refinements report Files=2, Tests=4. Syntax, book and bounded gates accompany this commit. Real sources remain unmoved. The independently reproduced post-transition deletion gap is owned by .3 for unconditional prior-current identity continuity before live admission.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2.3`
  Status: `done`
  Goal: `Integrate exact catalog-aware canonical addition into ceiling-authority validation.`
  Acceptance: `After .1-.2, use the same authenticated store/identity contract for new canonical decision authority in actual staged/worktree/committed modes. Preserve legacy flat authorities and their exported paths; only exact resolved newly added canonical catalog IDs may authorize a same-change ceiling increase. Reject unknown parts, borrowed/substituted IDs, malformed/missing/stale source/catalog/index products, snapshot/worktree disagreement and reused/orphan authority. Continuously preserve prior selected-catalog ID/path/type/fact identities and question keys for every catalog change, including post-transition births; never permit deletion or recycling merely because an ID is absent from the fixed original census. Use complete independent Git fixtures, keep ceilings unchanged, qualify relevant gates and commit before real source rollout .3.`
  Verification: `Shared selected Git products, public predecessor binding and actual Perl integration retain complete prior identities/facts/questions. Children qualify fresh authority, ordinary no-increase evolution, all-mode identity substitutions and malformed product/caller/IPC refusal. No ceiling is widened. The owned P2 schema and P3 fingerprint-shape defects are repaired before production rollout.`
  Commit: `this commit`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2.3.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2.3.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2.3.1`
  Status: `done`
  Goal: `Qualify bounded selected-Git store access and prior-current catalog identity continuity.`
  Acceptance: `Before gate integration, provide one bounded regular-blob/path-inventory accessor for staged index and resolved immutable Git revisions, with no ambient fallback or submodule traversal. Refuse conflicting stages, symlink/gitlink/directory members, missing/unbounded blobs and unsafe selectors/paths; retain the selected inventory independently of later working changes. Compare complete authenticated prior/current store products: source cohort/authority/index/originals immutable, every prior current ID/path/type/fact identity/question retained, and fresh births never reuse transition or prior identities. Current owned content/status/summary additions remain possible and first fact indexing from null remains additive. Qualify actual repository-local Git fixtures and literal deletion/reuse/substitution/lost-fact controls; commit these shared prerequisites before public/Perl integration.`
  Verification: `Shared Git snapshots capture bounded path/mode/object IDs from index or resolved revision and read only those regular blobs. Actual Git fixtures prove captured bytes survive later index/HEAD/worktree changes and replacement refs; root binding, unsafe selectors/paths, missing/directory/symlink/gitlink/conflicting/oversized/output-bound controls refuse. Git traversal never enters submodules; lazy fetching and optional locks are disabled. Complete selected root inventory accompanies the bytes. Prior-current comparison preserves source revision/digests/cohort/originals/index/routes plus every earlier current ID/path/type/fact identity/question, including post-transition births; new IDs follow the prior high-water mark. The previously self-consistent 0115 deletion now refuses. Literal immutable-source/recycle/lost-fact/question/gap controls pass; owned updates and first indexing from null remain possible after independent authentication. Broad guarded cohort reports All tests successful, Files=8, Tests=38; final replacement/root accessor refinements pass Files=3, Tests=6. Syntax, book and bounded gates accompany this commit. These are shared prerequisites; actual unconditional selected-store/public/Perl enforcement remains .2, then .3 qualifies modes before real rollout.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2.3.2`
  Status: `done`
  Goal: `Wire selected-store continuity and fresh canonical authority into actual public and Perl gates.`
  Acceptance: `After .1, expose selected Git snapshot access through the actual published reader/resolve boundary, and integrate the same authenticated identity contract into staged/worktree/committed ceiling-authority validation. Run prior-current continuity on every catalog/store change, not only ceiling increases. Preserve old no-catalog/flat historical authority behavior; fixture trust anchors must be explicit and cannot override installed production authority at the real repository root. Only a genuinely fresh resolved canonical ID newly added with the exact increase may authorize it. Reject borrowed prior/transition IDs, snapshot/worktree mixing, malformed or stale products, unknown parts and reused/orphan authority. No source moves or ceiling increases in this integration; commit before broad mode qualification.`
  Verification: `Children qualify actual selected public products and atomic predecessor checks, then actual unconditional Perl continuity/fresh authority with exact control-file bindings. Final focused gate/reader/catalog/legacy/containment cohort passes Files=10, Tests=42; book and syntax pass. Broader hostile mode qualification remains sibling .3 before production source rollover.`
  Commit: `this commit`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2.3.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2.3.2.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2.3.2.1`
  Status: `done`
  Goal: `Expose actual selected-snapshot reader products and atomic prior-current continuity.`
  Acceptance: `Read/check/resolve selected index or resolved Git revisions using the qualified captured regular blobs and complete selected inventory; retain ordinary filesystem and no-catalog behavior. Add one bounded atomic public change check that authenticates current and prior stores, rejects catalog removal and identity loss, binds first adoption to the exact preceding source/index/originals and returns exact requested canonical bindings plus prior-relative freshness. Supplied fixture authority requires explicit other roots and cannot override the actual repository authority. Validate complete requests before output, preserve legacy reader capsules and qualify actual independent Git fixtures before committing; no production pins, source moves, ceiling changes or Perl enforcement yet.`
  Verification: `Actual read/check/resolve use captured index/resolved Git blob bytes and selected inventory, including legacy publication consumers. Atomic check-continuity authenticates both stores and retains every prior identity/key, returning complete selected canonical text and prior-relative freshness without partial output. First adoption matches the selected predecessor revision/root population/index/sealed and flat originals plus exact transition metadata/navigation. Catalog removal, malformed requests, mixed ambient products and JSON-output expansion refuse. Explicit supplied fingerprints cannot override the actual reader root with or without installed pins. First tests failed only incorrect expected refusal strings/order; corrected. A later aggregate passed eight files but failed to locate the mistyped final filename; incomplete aggregate is not qualification. Enumerated full focused cohort reports All tests successful, Files=9, Tests=40; actual repository HEAD-selected legacy check and book build pass. The first doctrine run caught an overlong task-index frontier row; its exact pointer was shortened without changing limits, and the complete rerun passed. Syntax, Knowledge Map/inventory and bounded staged doctrines/hooks accompany the commit. No production pin, source relocation, ceiling increase or Perl enforcement occurs; next child .2 integrates the gate.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2.3.2.2`
  Status: `done`
  Goal: `Enforce selected-store continuity and exact fresh canonical ceiling authority through the actual Perl gate.`
  Acceptance: `After .1, use the atomic authenticated public change check in staged/worktree/committed modes, selecting changes from store paths as well as registry/authority paths. Enforce prior-current continuity for ordinary catalog changes without increases. Bind registry/authority fingerprints to the same captured reader snapshot and consume resolved current text, unfenced authority markers, prior-relative freshness and predecessor file absence for exact nested canonical authority; preserve append-only historical flat authorities and no-catalog controls. Qualify primitive authority schema kinds, including a reproduced Boolean schema control, as part of the touched boundary. Refuse mixed controlled snapshots, borrowed IDs, malformed stores and orphan/reused authority. Qualify focused actual boundary fixtures and commit before sibling all-mode qualification .3.`
  Verification: `Actual Perl controlled selection covers store/source/reader changes as well as registry/authority files; ordinary catalog changes enforce complete authenticated prior-current identities even without increases. The actual atomic public product binds registry/authority bytes to the same captured inventory, and a real fixture dispatch that changes the index registry after the Perl read is refused. Canonical authority requires a fresh ID, predecessor-absent file and exact visible markers outside fences; borrowed transition IDs and fenced examples refuse. Captured current commits determine their exact parent. Supplied fixture pins require an explicit other root and cannot override actual authority. Bounded parallel stdout/stderr draining refuses process failure and oversize streams. P2 Boolean schema defect red T2005 returned success on legacy staged true; reference-valued schemas now refuse in surface/authority metadata and authority rows. Focused initial Files=3, Tests=12 PASS; final complete cohort All tests successful, Files=10, Tests=42 PASS; book and syntax pass. Policy/book/canonical evidence, registry, Knowledge Map/inventory and staged doctrines/hooks accompany this commit. The first doctrine run found one open claim candidate because SHA-256 bindings was tokenized as a binding count; the algorithm identifier receives an explicit reviewed-incidental disposition under its existing chapter review group. The root policy duplicate exceeded its fixed total-line allowance; conditional canonical-path wording and a direct pointer to the complete 0108 contract preserve the policy within existing root lines. No source moves, production pins or ceiling increases occur. Parent .2 integration and its shared prerequisites are complete; sibling .3 owns broader hostile mode qualification before .51.3.2.3 atomic source rollover.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2.3.3`
  Status: `done`
  Goal: `Qualify complete canonical authority and identity continuity across all selected modes.`
  Acceptance: `After .2, exercise actual public and Perl boundaries with independent complete staged/worktree/committed Git fixtures, including successful fresh authority and ordinary catalog growth/update with no increase. Plant equal-count deletion/reuse/path/type/fact/question substitutions, source/index/original corruption, stale descriptors/indexes/pages, symlink/conflict/missing data, mixed snapshots and reused/orphan authority. Prove legacy controls and default production pin isolation, run focused relevant gates/book/doctrines, commit and hand off cleanly to atomic real rollover .51.3.2.3.`
  Verification: `Children .1-.2 qualify self-consistent post-transition identity/key substitutions and malformed product/authority/caller/IPC controls through actual selected public and Perl gates. Owned additive evolution and historical controls remain accepted. Installed capsules preserve published sealed originals and refuse own-root pin overrides. Production rollover remains .51.3.2.3.`
  Commit: `this commit`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2.3.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2.3.3.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2.3.3.1`
  Status: `done`
  Goal: `Qualify post-transition identity and fact/question continuity independently in every selected gate mode.`
  Acceptance: `Publish an independently literal post-transition fact-bearing birth, then plant self-consistent deletion/equal-count recycling, path/type changes, fact deletion/replacement, question deletion/equal-count substitution and earlier-gap birth in separate worktree/staged/committed fixtures. Prove each current snapshot passes standalone authentication/navigation yet the actual Perl prior-current gate refuses it, with no ceiling increase to trigger the check. Prove additive owned content/status/summary/question updates pass all modes. Retain complete source/index/original/control baselines, same-volume fixture cleanup and legacy controls; synchronize book/evidence and commit before other hostile product/authority/IPC qualification.`
  Verification: `Each independently literal fixture publishes post-transition 0115 with a fact ID and question keys before mutation. Every current deletion/equal-count birth replacement/path/type/fact deletion or replacement/question deletion or equal-count replacement/earlier-gap birth has consistently updated bytes, metadata and complete root/part navigation. Actual standalone selected authentication passes each, then the actual Perl prior comparison refuses every case in worktree/staged/committed modes without a ceiling increase. Owned content/status/summary changes and additive questions pass every mode. Complete source/index/original/control baselines remain exact; each same-volume fixture is cleaned. Initial guarded T2006 passes Files=1, Tests=2; final T2006/T2005/T2004/T2003/T1560 passes All tests successful, Files=5, Tests=16. Book, syntax and bounded gates accompany the workflow; next child .2 completes malformed product/authority/caller/IPC qualification before atomic rollover.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2.3.3.2`
  Status: `done`
  Goal: `Qualify malformed stores, authority/caller isolation and bounded IPC refusal before atomic rollout.`
  Acceptance: `After .1, plant complete malformed source/index/original/descriptor/navigation/alias and unsafe file controls across selected modes; exercise fresh/borrowed/reused/orphan/misrouted authority, production/default pin isolation and malformed public fingerprint/request inputs. Exercise actual bounded stdout/diagnostic draining, malformed products and signal failure using project-owned controlled dispatch fixtures. Repair and own any reproduced boundary defect, preserve all historical reader/flat authority behavior, run focused complete gates/book/doctrines and commit a clean frontier for atomic rollout .51.3.2.3.`
  Verification: `Initial T2007 passes malformed product/authority/conflict/IPC controls but exposes P3 malformed supplied fingerprints accepted on the no-catalog path. Unconditional shape validation repairs it before product selection, preserves valid no-catalog results and emits no partial output. Final refined T2007/T2004/T2005 passes All tests successful, Files=3, Tests=6. Every selected mode refuses source/index/original/descriptor/schema/JSON/navigation/alias/missing/symlink/oversized controls; orphan/reused/prior-birth/misrouted authority and conflicting/gitlink entries refuse. Controlled dispatch refuses oversized dual streams, malformed products and signal termination after valid output. Installed default capsules retain published sealed-prefix authority and deny own-root pins. Final guarded T2007/T2006/T2005/T2004/T2003/T2002/T2001/T2000/T1923/T1999/T1560/T1554 reports All tests successful, Files=12, Tests=46. Book/syntax and bounded staged doctrines/hooks accompany the workflow. No source moves or ceiling increases occur; .51.3.2.3 is now active.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.3`
  Status: `done`
  Goal: `Roll over canonical decision storage and navigation atomically through integrated gates.`
  Acceptance: `After .2, take a fresh exact pre-transition census, preserve complete original bodies separately from relocated current rendering, freeze finite compatibility paths/headings and place current bodies/indexes in the selected semantic partitions. Update self-searches and direct body readers, declarations, source links and Knowledge Map routes together. Prove exact source identity, unchanged authority/question/metadata keys, relative destination closure, complete reader products and no loss residue; restore current capacity without widening ceilings. Run focused relevant gates and book, commit, then hand off broad fresh-record/consumer continuity to .51.3.3.`
  Verification: `Direct-collection census correction and exact predecessor capture are complete. Atomic real canonical relocation, immutable originals/index/pins, finite compatibility, complete navigation and public/Perl first adoption are qualified by .2; broader fresh-record/consumer closure is .51.3.3.`
  Commit: `this commit`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.3.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.3.1`
  Status: `done`
  Goal: `Correct overstated direct-collection measurements before production source capture.`
  Acceptance: `Own the P3 temporary census defect introduced in 2f6c144ff: Python fnmatch matches slash-separated descendants where the production Perl bsd_glob contract selects direct members. Recompute focused_documents and rationale allowances from exact checker-compatible paths, retain fixed baselines and ceilings, qualify containment/authority/claims and commit before atomic rollout. Task evidence patterns already explicitly include their segments; independently confirm that collection too.`
  Verification: `Independent pathlib direct-glob and Perl File::Glob membership sets agree for focused documents, task evidence and rationale. Overstated descendant counts are replaced with exact direct-surface dimensions plus the unchanged per-axis ratchet step, clamped by unchanged ceilings and baselines. Guarded check_live_document_size.sh passes all size-containment, maintained-reference and ceiling-change invariants with zero increases. This is a declaration correction; no behavior or root policy changes. Staged doctrines/claims and the guarded commit finish the repair before fresh source capture.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.3.2`
  Status: `done`
  Goal: `Capture and deliver the real decision-store rollover atomically.`
  Acceptance: `Bind immutable source/index/original products to clean predecessor 585070c07bbcfa1af1497ff9701924a0f9b81e01. Retain all published sealed originals and capture every later flat body exactly; relocate current rendering into closed continuity/language-api/verification partitions with unchanged metadata/question/authority keys. Preserve every root compatibility path and original heading destination. Install independently derived source/index pins, complete root/part navigation, same-volume reconstruction and updated canonical body consumers/Knowledge Map declarations in the same commit. Pin legacy fixture products to their own pre-transition source rather than new aliases. Separate finite compatibility pressure from current canonical capacity using unchanged predecessor ceilings, and qualify actual initial-adoption/current/original/gate/book/doctrine products before committing. Broader fresh-record and consumer closure remains .51.3.3.`
  Verification: `Clean predecessor and zero-byte brief verified; local ahead count is below push cadence. Direct-collection declarations are corrected under .1. The source capture must use this exact predecessor; historical identity-capacity audit remains pinned separately and is not a current census. Production capture/delivery is in flight. Initial T2008 incorrectly requested more than the existing bounded ID list; changed to independent bounded cohort requests. Actual T1809 also reports frozen v1 emitted-graph SHA 6a0966e3... versus 604f4713... while its normalized result remains exact. Exact introduction-code capsule reproduces 604f4713...; complete recursive product comparison isolates changed generated HIAL DUT text and its dependent byte/digest references. Same-value assertion removal traces to 69ae18454c52a51079da17edd7c31c423ef66bb5; existing width-aware scalar truthiness also reflects current internal-signal metadata. The VIAL source/plan/fixture/runtime/tool/commands and normalized result retain identity. Own the stale mixed-dependency oracle here: retain its exact historical graph SHA with one authenticated frozen DUT input and keep current-DUT emission separately exercised; never replace the old graph hash with an unexplained new value.`
  Commit: `this commit`

  Delivery: `Actual production check and exact-predecessor continuity pass. All fourteen non-route files in production-qualified-tests.log pass; its only remaining failure was T1553's old ten-surface pressure assertion. Updating that separately traced cohort expectation for canonical rationale and finite compatibility makes the guarded route-qualified.log pass Files=1, Tests=9. Complete focused coverage comprises fifteen named files and sixty-three top-level tests; no failed aggregate is claimed successful. Initial invocation paths and preparatory no-pin/oversized-request assumptions are corrected. Production containment, book, Python/Perl syntax, Knowledge Map and claim inventory pass. Staged doctrines/hooks complete this atomic workflow; no HDL runtime, full CI or push occurs.`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3`
  Status: `done`
  Goal: `Qualify complete decision continuity and new-record capacity before resuming frontend work.`
  Acceptance: `After .2, independently reconstruct every transition source and public identity, resolve complete tracked navigation/provenance/body consumers, compare exact Knowledge Map question/answer closure, and exercise successful fresh record growth plus planted known-bad alias/index/retrieval controls. Run relevant reader, containment, claim, memory and doctrine gates; synchronize user retrieval guidance and handoff pointer, commit, then resume .60.4.3.2.3.6 with a clean tree. Report finite external-consumer limits instead of asserting unseen integrations passed.`
  Verification: `Complete fixed-source consumer/navigation/question closure .1 and production growth/malformed/prior-floor .2 are qualified. Final combined source/doc/doctrine closure and frontend handoff are .3.2, after due cleanup .3.1. Immutable source/index products and all containment ceilings remain fixed; unseen external/runtime consumers are not claimed.`
  Commit: `completed through committed children; final closure in this commit`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3.1`
  Status: `done`
  Goal: `Independently qualify production identity, tracked navigation and Knowledge Map closure.`
  Acceptance: `Use committed df7f692c8b94b083d2d078d62854d37869fbca6d and its exact immutable predecessor as distinct authorities. Resolve all source compatibility heading destinations and current canonical records/indexes, independently compare complete Knowledge Map question/fact/path bindings after known physical relocation, and census every tracked full-basename consumer plus separate generic code readers without submodule recursion. Classify historical exports, current direct body readers, self-searches and fixture provenance explicitly; retain unresolved dynamic/external limits. Exercise planted lost/question/misroute controls against the independent verifier. Repair the stale prose frontier left by atomic delivery, while live nodes/Memory remain authoritative. Commit this finite consumer proof before fresh-record growth; no HDL execution or arbitrary unseen-consumer guarantee.`
  Verification: `Committed atomic store is clean, brief empty and ahead count below push cadence. Complete fixed-source question/fact/path equality, original heading and inline destination continuity, exported provenance and tracked candidate review are qualified by .2. Child .1 also repairs the stale prose frontier and canonical SPECFORGE status. Fresh-record growth is .51.3.3.2.`
  Commit: `this commit`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3.1.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3.1.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3.1.1`
  Status: `done`
  Goal: `Synchronize the downstream feedback and book matrix with admitted record inputs.`
  Acceptance: `The director asks whether the unstated-reset answer reached the canonical SPECFORGE response. Verify its existing committed complete answer, then fix the confirmed stale record-port refusal statements in the response and book matrix against qualified source admission 25c01f0127144922ade78951b91439e1d9221c08. Preserve dated intake evidence, distinguish admitted record-input source from outstanding frontend/generated/domain/native/consumer and output/list/variant delivery, and state duration/timer implementations remain open. Record the committed storage rollover and remaining qualification prerequisite truthfully. Do not change production capability, contact SPECFORGE, or modify another checkout. Qualify the relevant current source/book/doc gates and commit before the independent consumer census.`
  Verification: `The complete reset answer already exists at docs/SPECFORGE_FEEDBACK_RESPONSE.md under its dated unstated-reset heading; git log -S traces f6c44aa5a4517967632d25c2a190d2f1c2e22f59. The feedback baseline still says whole copy and input guard remain refused, and matrix rows/explicit non-claims retain blanket record-port refusal despite source admission. Git traces the baseline row to 5bad5f36b8d81cd2bfaf823c7b32b3d757d1ad08. Own this P2 user-facing status drift immediately; complete runtime/consumer feature signoff is still open.`
  Commit: `this commit`

  Delivery: `The pre-existing complete reset answer is linked and summarized near the canonical response top. Current record-input admission and remaining frontend/generated/domain/native/consumer/output/list/variant work are accurate, with durations/timers explicitly unimplemented. Dated refused intake evidence stays historical. Book requested/current rows, declaration/type/leaf rows, explicit non-claims and the matrix audit agree. Initial T1305 fails only its old blanket aggregate-port non-claim literal; corrected source-admitted row and separate output/list non-claims retain the genuine boundaries. Guarded T1980/T1998/T1305/T1303 reports All tests successful, Files=4, Tests=315. Book builds; map/inventory and staged doctrines/hooks complete the workflow. Production capabilities and code are unchanged.`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3.1.2`
  Status: `done`
  Goal: `Complete the independent committed-source consumer and question-binding proof.`
  Acceptance: `After .1, execute parent .51.3.3.1's exact immutable/current identity, complete tracked consumer/navigation and Knowledge Map binding closure with independent planted negative controls and explicit external/dynamic limits. Commit its finite proof before .51.3.3.2 fresh-record qualification.`
  Verification: `Canonical response/book status repair .1 is committed at 17e8c7645e56160528b2fb93ca72930c05d9a562; tree clean and brief empty. git log -S for T1809's canonical 0100 path traces atomic df7f692c8b94b083d2d078d62854d37869fbca6d. Executed a fixed-commit audit with independent complete question/fact/path equality, original-heading forwarding and resolved inline destination preservation; retain full-basename and generic code candidate censuses separately. Literal lost/substituted question/fact/path and missing/misrouted heading/destination controls qualify the independent verifier. Known current body reader and self-search routes are explicit assertions; immutable exports stay historical. No submodule recursion, dynamic/external enumeration or HDL runtime is inferred.`
  Commit: `this commit`


  Delivery: `Fixed df7 against exact source 585 preserves all original heading forwarders and inline destination meanings, complete question/fact/path bindings and unchanged exported provenance bytes. Full-basename and generic code censuses are independently scoped, with explicit interface classification. Guarded T2009/T2008/T1923/T1685/T1763 passes Files=5, Tests=95; literal loss/substitution/misroute and unreviewed-code controls pass. Book and canonical 0108 are synchronized; staged doctrines/hooks complete this workflow. Fresh growth remains .2; external/dynamic consumers and HDL runtime are unqualified.`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3.2`
  Status: `done`
  Goal: `Prove actual fresh-record capacity through installed production reader and authority gates.`
  Acceptance: `Copy authenticated committed production products into a complete same-volume project-owned fixture, preserve installed independent pins and publish its prior catalog before birth. Add a literal new canonical fact-bearing record, catalog and complete part/root routes without any compatibility birth or ceiling increase. Verify ordinary growth through actual public and Perl gates in worktree/index/committed modes and independently measure physical current/compatibility membership. Plant alias/index/retrieval and post-birth identity/question losses while retaining valid descriptors, proving both current authentication and prior continuity. Preserve real repository source/history and never publish fictitious decisions. Commit qualification before closure.`
  Verification: `Positive production growth .1, transparent guard repair .4, complete malformed products .2 and current-consistent published floors .3 are qualified. Independent source/index fingerprints and production ceilings remain fixed; no fresh production decision or external/native scope is claimed. Parent closure .51.3.3.3 is the next leaf.`
  Commit: `this commit`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3.2.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3.2.4`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3.2.1`
  Status: `done`
  Goal: `Qualify successful fresh growth from actual authenticated production products.`
  Acceptance: `Use fixed committed 5ef1133c59f6d1814ebe7d1bf95373bdd77cbbc8 as the independent complete store input. Copy all store/original/compatibility/current/index/helper and control products into a same-volume project-owned isolated fixture; retain installed independent production fingerprints and commit its prior catalog before birth. Add literal fixture-only 0115 with independently declared fact/questions, descriptor and complete root/part routes, never a root alias. Require actual public original/current/default retrieval and prior-aware Perl admission in worktree/index/committed modes, with literal original refusal for the uncaptured fresh ID. Independently compare physical current and fixed alias membership/dimensions using Python direct globs and Perl File::Glob, retaining unchanged actual production ceilings and declaring any fixture warning pressure honestly. Preserve immutable source/original/index products. Commit the positive proof before hostile controls .2 and post-birth continuity .3; do not publish a fictional ADR or claim full CI/native/external delivery.`
  Verification: `Parent consumer proof is committed, clean and brief empty. Initial T2010 fails at t/2010-decision-production-growth.t line 12 because the fixture omits README_POLICY.md: the published reader also verifies every sealed-census selected link destination and reverify consumer. Capture that complete declared set from the fixed source, rather than weakening installed check. Existing T2005/T2006 use smaller literal cohorts; this leaf must exercise all real installed source/record/navigation/control inputs and retain independent pins, without inspecting submodules or writing another existing project checkout.`
  Commit: `this commit`
  Delivery: `Complete fixed production products plus every declared sealed-census link destination and reverify consumer are copied exactly. Actual installed/default and supplied public products, uncaptured-original refusal, and prior-aware Perl admission pass worktree/index/committed modes. Python/Perl membership and byte/line censuses agree; current grows 67 to 68 members and 7985 to 8005 lines, while 114 alias bytes and 115 compatibility members stay fixed. Root discovery grows one row honestly. Fixture warning pressure is declared; every production ceiling and immutable original/control product is unchanged. Guarded T2010/T2006/T2007 passes Files=3, Tests=6 and the book builds. Source-input RAM guard defect .4 is prioritized next; complete production-cohort hostile/floor controls .2/.3 remain open.`


- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3.2.2`
  Status: `done`
  Goal: `Falsify actual production-cohort alias/index/retrieval corruption in every mode.`
  Acceptance: `After positive .1, plant independently selected missing/wrong compatibility headings, duplicate or misrouted root/part indexes and current retrieval/body corruption in the same complete fixed production-cohort fixtures. Observe actual public and prior-aware Perl refusal in worktree/index/committed modes without changing independent source/index pins or ceilings. Keep the positive published fixture and immutable products independently recoverable. Commit before post-birth floor controls.`
  Verification: `Positive production-cohort birth .1 is committed at ce4d0029028a3e25f517ea93632cf50f2712354a; guard repair .4 is committed clean at 331fd1955510196064406dfd4d2649b4b7108a3a with an empty brief. Reuse fixed 5ef production inputs with independently literal installed pins and unchanged ceilings. Publish an authenticated fixture-only birth and honest warning declaration before malformed controls; restore that exact positive fixture revision between independently selected cases. Require public check, read-current and prior-continuity plus actual prior-aware Perl refusal in worktree/index/committed selections; preserve immutable source/index/original/control bytes. No production ADR, native workload, other existing checkout or ceiling change is authorized by this qualification.`
  Commit: `this commit`
  Delivery: `Complete production fixture publishes authenticated literal birth and its honest warning before corruption. Eight independently selected heading/root/part/body cases refuse actual public check/current retrieval/prior-continuity and actual prior-aware Perl gates in all three selections: 24 complete case/mode cells. Equal-size body corruption proves digest binding beyond counts; missing regular body also refuses. Explicit Git views bind each selected mode to the same published positive predecessor. Each case restores that exact owned fixture revision; source/original/index/catalog/control products stay byte-equal. Guarded T2012 passes Files=1, Tests=2 with complete per-cell transcript. Positive growth and real installed retrieval form the broader gate. Prior-floor .3 remains open; no production decision, ceiling, native or external scope changes.`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3.2.3`
  Status: `done`
  Goal: `Qualify real production-cohort prior floors after a fresh fact-bearing birth.`
  Acceptance: `Publish the literal 0115 fact/questions before every independently planted identity deletion/replacement and fact/question loss or equal-count substitution. Update descriptors and complete navigation consistently so standalone current authentication passes first; actual prior-aware public/Perl gates must then refuse in all modes. Preserve owned additive content/questions as a positive control. Close fresh-growth parent only after positive, malformed-product and prior-floor scopes are complete; hand off .51.3.3.3 with exact finite limits and unchanged ceilings.`
  Verification: `Complete production-cohort malformed .2 is committed clean at 6e2e018349f7a399b81b78558c5f08cab5cc29f9 with an empty brief. Use the fixed complete 5ef production input with independently installed source/index pins. Publish literal 0115 with authored fact/questions in a separate project-owned fixture before each independently selected identity/path/type/fact/question mutation. Update descriptors and every navigation route consistently; standalone public authentication and exact selected current retrieval must pass first, before prior-aware public/Perl refusal in every mode. Fresh fixtures isolate mutations and avoid hidden untracked residue. Retain owned additive content/status/question evolution as a positive control, declare warning pressure honestly and preserve all ceilings and immutable source/control products. No real decision birth, native producer or existing foreign checkout changes.`
  Commit: `this commit`
  Delivery: `Separate complete fixed-production fixture publications precede eight independently authored identity/path/type/fact/question mutations. Updated descriptors, metadata and complete navigation pass actual standalone authentication and exact current retrieval; actual public prior continuity and prior-aware Perl then refuse every one of the 24 selected case/mode cells. Owned additive content/status/questions pass all three modes with no fresh identity. Warning pressure is declared; every production ceiling and immutable source/original/control product remains unchanged. Guarded T2013 passes Files=1, Tests=2, and independent literal T2006/T2007 passes Files=2, Tests=4. Growth parent .2 is closed; final rollover closure .51.3.3.3 remains before frontend work.`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3.2.4`
  Status: `done`
  Goal: `Repair RAM-guard stdin forwarding before further guarded qualification.`
  Acceptance: `After the positive-growth commit, reproduce and repair the guard's lost standard input without changing resource cutoffs, descendant supervision, exit/signal propagation or inherited descriptor contracts. Preserve stdin for piped/file input and script-on-stdin execution, with independent exact sentinel and no-input controls plus existing RAM-guard regression tests. Audit maintained guarded-stdin recipes and verification claims, owning any affected evidence rather than assuming earlier checks ran. Use Bash syntax compatible with the existing supported launcher. Update user/tool guidance, durable facts and this owner; commit before complete production-cohort hostile controls .2.`
  Verification: `Positive .1 is committed at ce4d0029028a3e25f517ea93632cf50f2712354a with clean tree and empty brief. P2 discovered during its capacity capture: guarded Python code supplied on stdin exits zero with no bytes. Exact public sentinel through the actual guard also disappears; scripts/run_with_ram_guard.sh line 278 launches "$@" asynchronously without explicit stdin forwarding. /bin/bash with explicit <&0 retains the sentinel. git log -S traces the bare asynchronous launch to 06c38fba703c53708875df14f501f1be3e94f891. Own and repair the transparent-launcher defect; use an exact committed old capsule as a falsifier. Maintained targeted guarded-stdin recipe search currently returns no matching direct uses; enumerate complete tracked guard references and multi-line blocks before closing that scope. The passing .1 matrix uses file/module commands and its successful file-based capacity capture is recorded.`
  Commit: `this commit`
  Delivery: `Explicit <&0 preserves pipe/file/binary/EOF/script input and inherited descriptor three on the existing Bash syntax. Exact ce4 old-source capsule remains an independent empty-success falsifier. T2011/T1595/T1811 passes Files=3, Tests=15 with unchanged cutoff/telemetry/signal/cleanup controls. The retained fixed-ce4 basename census has 920 matching rows across 407 tracked paths, including 54 reviewed code interfaces; joined Markdown/code recipes yield no explicit direct stdin candidates. Earlier observations at 25a4a196 and the native-feasibility task rejected empty captures and corrected to named scripts; T1886 likewise deliberately reopens its owned request file, and its stale comment is corrected. Dynamic/ephemeral historical invocations are not exhaustively recoverable. The finite audit, current facts, TOOLBOX and book retain the scope. Resume .2 malformed-product controls.`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3.3`
  Status: `done`
  Goal: `Close decision rollover qualification and hand off the SPECFORGE frontend matrix.`
  Acceptance: `After consumer and growth proofs, run appropriate combined reader/claim/memory/containment/doctrine qualification, reconcile complete identity/question/consumer and fixture evidence, update retrieval guidance and every frontier pointer, close exhausted parents, and commit a clean handoff before .60.4.3.2.3.6. State scoped external/runtime limits; retain native/full-CI gates and unchanged containment ceilings.`
  Verification: `Due fixed-render cleanup .1 and final current/original retrieval plus source/doc/doctrine reconciliation .2 close this prerequisite. Canonical 0108, book, SPECFORGE response and resume/task frontiers agree. Authored frontend/public matrix .60.4.3.2.3.6 is next; native causality/full-CI and external-consumer limits persist.`
  Commit: `completed through committed children; final closure in this commit`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3.3.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3.3.1`
  Status: `done`
  Goal: `Perform the due safe artifact cleanup before final rollover handoff.`
  Acceptance: `Last recorded cleanup is 2026-09-29T21:42:40.755094+00:00; fresh UTC clock after the clean floor commit is past the daily threshold. Census repository-owned obsolete rendered-book copies and project Rust release/deps/incremental log/bin locations without crossing existing Git boundaries. Delete only proven generated, inactive and regenerable render copies, with same-volume regular-file and no-symlink checks. Preserve all logs, native/receipt evidence, spent compiler workspaces and the current book output. Retain a bounded candidate/residue census, overwrite docs/ARTIFACT_CLEANUP.md with only the latest date/summary, synchronize maintenance guidance and pointers, run required doc gates and commit before final closure.`
  Verification: `Floor qualification is committed clean at 5daaeb7e8e3a0b089c4cd7f2552e6aeebbba3fe9, brief empty and all verification results consumed. No cleanup mutation precedes this owner. Inspect candidate provenance and physical membership before removal; absent Rust paths and retained log/bin candidates are recorded honestly, not treated as deletion evidence.`
  Commit: `this commit`
  Delivery: `Tracked fixed-target cleanup driver independently reconciles os.walk and rg membership, same-volume regular-node identities, generated-book markers and existing Git boundaries before removing obsolete named-drive fact/reset-wording render copies. Fresh residue checks and saved member allocation pass; current rendered book is retained and rebuilt. Exact top-level and configured rust/target release/deps/incremental log/bin census records absent roots and no matching candidates in present paths. All logs, native/receipt evidence and spent compiler workspaces remain untouched. Latest-only cleanup date is 2026-09-30T21:56:12.405484+00:00. Dated census does not imply reproduction of the old renders' unknown generating Git revision; deleted render bytes are intentionally not retained. Resume final closure .2 after commit.`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3.3.2`
  Status: `done`
  Goal: `Qualify and commit the final decision-store closure and frontend handoff.`
  Acceptance: `After the daily cleanup commit, fulfill parent .51.3.3.3's combined reader/claim/memory/containment/doctrine qualification and finite evidence reconciliation. Keep canonical 0108, book, feedback and frontier pointers aligned, close exhausted prerequisite parents and commit before starting .60.4.3.2.3.6. Preserve source pins, immutable history, all ceilings and native/external/full-CI limits.`
  Verification: `Installed public authentication, independent current physical/original Git retrieval for canonical 0108 and 0113, actual predecessor continuity and prior-aware Perl admission pass. Combined reader/consumer/archive tests, book and Knowledge Map qualify this final closure; staged doctrines and hooks must pass before commit. All pins, originals, ceilings and external/native/full-CI limits are retained.`
  Commit: `this commit`


- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.40`
  Status: `done`
  Goal: `Repair one-member aggregate type normalization exposed by the child-read qualification.`
  Acceptance: `Immediately after .39.2.2.2.1, reproduce (type byte_t (record (payload (bits 8)))) through the public ISF/direct-type routes. Distinguish a one-member definition from a wrapped member sequence in DeclarativeTypeSupport and DeclarativeTypeResolver without consulting submodule implementation. Prove single/multiple/nested members, aliases/dependencies and invalid shapes; update contracts/book/facts and commit before generated-child writer work.`
  Verification: `T1904's first record probe failed before storage lowering: normalized record body has one member array, but the generic single-array flattening treats that member's name/type as separate members; canonicalize_type_spec then rejects the scalar name. The resolver repeats the same flattening in dependency collection. This is a parser defect, not evidence that child record read routing is unsupported. The retained failing transcript is .artifacts/child-storage/final-focused.log; source shape and mechanism are preserved here.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.40: preserve single-member aggregate types`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.41`
  Status: `done`
  Goal: `Remove residual power-up claims from the ISF feature matrix's hardware reset descriptions.`
  Acceptance: `Immediately after .40, compare the scalar-storage and local-variable matrix rows with the qualified reset contract, replace powers-up wording with hardware-reset wording, census remaining maintained ISF descriptions, validate claims/book and commit before wider child composition.`
  Verification: `docs/book/src/13k-isf-feature-support-matrix.md scalar storage and local variables say powers up although their own evidence is an HDL reset block; .35 and .39 qualify reset behavior, not power-up initialization. This stale wording was exposed while selecting aggregate documentation.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.41: distinguish hardware reset from power-up`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.42`
  Status: `done`
  Goal: `Emit a realized generated module definition once when multiple instances reference the same source.`
  Acceptance: `Immediately after .39.2.2.2.2.1 and before aggregate child-read qualification, reproduce a canonical C2 top with two ?dtc instances of reader_src. Locate generated-artifact assembly, distinguish identical reusable module definitions from conflicting same-name realizations/parameter specialization, and repair at the semantic artifact boundary. Prove duplicate-source direct composition with independent HDL/runtime and preserve every ISF worker instance, binding and local value. The independently exposed staggered-completion join defect is owned by .43 immediately next; retain its exact failing runtime assertions explicitly rather than claim join completion. Preserve mismatched-module diagnostics, docs and public reports, then commit.`
  Verification: `The strict-admitted aggregate_top probe emits module reader_src twice for reader and copy_reader instances, plus its top. GenerationOrchestrator maps hdl_code from every realized instance into child_segments without grouping by module identity; GeneratedChildRealizer constructs a full emitted module per instance. This is separate from duplicate alias-derived typedefs: scoping typedefs cannot fix repeated module definitions. Reproducer retained in .artifacts/aggregate-typedefs/duplicate-module.fsm; the source is a canonical two-instance pass-through with shared reader_src and top fanout.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.42: share verified generated module definitions`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.43`
  Status: `done`
  Goal: `Diagnose and repair repeated-worker await_all runtime timeout found during module-definition qualification.`
  Acceptance: `Immediate blocker investigation within .42: trace the exact T1907 repeated_workers parent/worker state and completion signals; distinguish local-init, activation, completion, and join behavior. Fix a small direct cause in the current safe slice or schedule the isolated lowering repair immediately before aggregate-read qualification. Preserve independent worker local state and repeat activation oracles; do not hide the timeout by weakening await_all expectations.`
  Verification: `T1907 strict-admits two instances of worker, emits one worker definition after .42, and compiles independently, but its first or repeated await_all completion times out. The worker has local acc/default initialization, a payload assignment, a wait and a result assignment. Parent binds separate inputs/outputs and spawns sequentially. Exact source is repeated_workers in T1907; retained probe .artifacts/module-definitions/repeated-workers.isf. The trace proves first/second outputs 83/29 and non-overlapping done pulses while parent remains in its await_all state. FSM::_emit_transitions implements sync_all as a raw AND of done_ports; completion is emitted as a pulse. Add per-activation completion memory with exact reset/rearm and no added completion-edge latency.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.43: retain generated child completion across joins`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.44`
  Status: `done`
  Goal: `Use boolean nonzero predicates for dynamic-wait counts so even counts enter and complete correctly.`
  Acceptance: `Immediately after .43, repair dynamic-wait positive-count predicates that bitwise-AND a multi-bit count with scalar control. Reproduce a completed join followed by wait cycles with count 4: generated parent.sv uses completion_ready & cycles, making an even positive count false. Qualify zero, odd, even and maximum counts across predecessor forms with independent runtime; retain sampling/zero-bypass timing and focused regressions, sync the book, then commit.`
  Verification: `.artifacts/completion-memory/dynamic.isf; .artifacts/completion-memory/parent.fsm; .artifacts/completion-memory/parent.sv; .artifacts/completion-memory/runtime-first.log; T1908 count-4 reproducer retained before .43 scopes its positive-count proof to odd counts.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.44: test the entire runtime wait count for nonzero`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.45`
  Status: `done`
  Goal: `Emit type-correct VHDL dynamic-wait counter comparisons and qualify independent timing.`
  Acceptance: `Immediately after .44, reproduce T1909 count_entry with GHDL: vector counter comparisons against scalar literal '1' fail analysis. Diagnose the owning comparison/literal emitter contract, repair without narrowing count or changing timing, and make the original complete-range and sampling VHDL oracle pass without TODO. Preserve SystemVerilog, typed comparison controls and public report parity, update docs and commit.`
  Verification: `.artifacts/dynamic-wait-predicates/qualified.log records no function declarations for operator > and = for main_wait_1_cnt compared with scalar '1'. T1909 retains the exact analysis/runtime expectations; no VHDL timing qualification is claimed by .44. The shared AHB knowledge card independently records an older workaround for generic dynamic-wait comparison widths.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.45: preserve VHDL comparison types and unsigned widths`



- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.52`
  Status: `done`
  Goal: `Preserve quoted division operators in public diagnostic sanitization.`
  Acceptance: `Immediately after .49.2.2.5 and before the wait-book repair .6, reproduce native/API diagnostic divergence for an unsupported carrier expression whose supported-operator hint contains quoted /. Repair contextual sanitization without exposing real absolute/quoted/URI/Windows paths. Qualify direct native/API/newline errors, bare/quoted HDL operators, genuine path redaction and repository-local paths; update book/facts and commit.`
  Verification: `T1930 RED/GREEN proves unsupported/arity diagnostic parity through native/API/newline calls, unchanged successful division reports, and actual-path redaction including ordinary quoted roots. T1868/T1461/T1929 regressions pass; book builds. Next .49.2.2.6 repairs stale wait excerpts before scope integration .3.`
  Commit: `this slice`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.53`
  Status: `done`
  Goal: `Repair extract carrier/public-query incompatibility found by strict book replay.`
  Acceptance: `Immediately after the current wait-book synchronization and before scope integration .49.2.2.3, reproduce the extract carrier's unsupported slice operator through actual native check/semantic and API/MCP paths. Resolve the mismatch between emitted extract RHS and the active expression grammar while preserving exact bit ranges, widths, capture timing and pending-sample behavior. Close the extract-specific replay gap in the older lowering tests; qualify direct/assembled/inferred sources and malformed controls, synchronize book/spec/facts and commit.`
  Verification: `T1931 qualifies complete native/API/newline check/semantic/schedule parity and strict carriers for declared, assembled, explicit, inferred, single-field, scalar-bit, constant-operand and pending-sample extraction. T1932 passes independent SystemVerilog/GHDL values, capture, hold/reset and assembled round trips. Existing data-op width/parameter/negative, wait, clause and book regressions pass; every mapped wait-book carrier now strict-replays and mdBook builds. Next .49.2.2.3.`
  Commit: `this slice`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.54`
  Status: `done`
  Goal: `Rollover accumulated historical acceptance prose before the semantic task reaches its line milestone.`
  Acceptance: `Activate before this task would reach 7200 lines. Use the existing exact-version acceptance-history manifest protocol; preserve the live node graph, current frontier and active repair facts, authenticate complete-source and historical-suffix identities, audit links and canonical consumers, and independently prove semantic closure, live working set and residue. Do not widen ceilings or activate deferred document reassessment. Commit before further ordinary appends.`
  Verification: `The exact 03d65d64 predecessor and Decisions-to-end suffix are authenticated through the bounded acceptance-history manifest. Independent cat-file reconstruction preserves every node ID and every other complete node record; current scope/runtime/native limits remain live, no anchored consumers target removed headings, and no historical source residue is discarded. T1549 source/suffix/pointer/typed-number negative controls pass; the book builds. Full integrity and staged gates verify the declaration. Next .49.2.2.3.1.2 prepares source contexts.`
  Commit: `this slice`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.55`
  Status: `done`
  Goal: `Repair empty terminal-state carrier emission and qualify hold behavior.`
  Acceptance: `Run immediately after helper identity .49.2.2.3.2.2.2.1. Reproduce raw source for a generated child ending in wait 1, isolate LoweringIR linking versus FSM emission, and fix terminal static-wait behavior without inventing completion/rearm. Qualify direct/generated cases, explicit successor/complete controls, warning-free strict carriers, public queries and relevant runtime behavior. Audit related empty terminal state classes within a safe scope and own any additional defects. Commit before resuming reservation prerequisites.`
  Verification: `T1940 qualifies explicit carrier self-loops for otherwise empty terminal wait/point/phase states in direct/generated transactions, unchanged source IR, native empty-body negative controls, real continuations, complete native/API/newline parity and qualified Verilator hold/repeated-request/reset behavior. The before/after census confirms all retained raw failures are repaired with identical lowering graphs. Neighboring wait/synchronization/anchor/schedule/helper and book fixtures pass. Resume .49.2.2.3.2.2.2.2.`
  Commit: `this slice`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.56`
  Status: `done`
  Goal: `Close advertised schedule enumeration drift for generated storage and DT roles.`
  Acceptance: `Before storage-access report extensions and as a prerequisite to adding new snapshot report roles, compare emitted production schedule roles/kinds with the advertised bounded contract. Reproduce child_completion_seen/view omissions, audit the same producer families for other omissions, update the canonical public contract and exact fixtures without inventing unsupported values, and add actual-report membership controls. Preserve public key shape and native/API/newline agreement; update book/spec and commit.`
  Verification: `T1964 exercises real generated storage writes/reads, completion retention and named completion with a parent contribution. Every emitted role/kind is advertised and every repaired value is observed; each deliberate descriptor omission is detected. The fixture strict-checks and complete native/API/newline reports agree; the full production schedule is identical before/after. T1158 now covers the added DT producer families. T1148 uses the qualified private formal identity without weakening width/kind/role checks. T1140/T1148/T1158/T1255/T1376 and mdBook build pass. The spec's stale temporal-contract mapping is aligned with the already-correct book: current monitors leave that legacy array empty. Snapshot integration .32.1.3.3.1.3.2.2 resumes next.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.57`
  Status: `done`
  Goal: `Refresh stale named-drive priority verification and VHDL boundary facts encountered during writer activation work.`
  Acceptance: `P1 documentation repair before .32.1.3.3.1.3.3.2.2.3.2: reproduce the contradiction between current named-drive cards/docs and completed reduction lowering, trace exact repair history, replace the RAM-guard cutoff override with the current default guarded command, and distinguish token-free VHDL generation from still-unqualified external compiler/runtime evidence. Preserve dated contract-selection history with an explicit current follow-up. Reverify focused named-drive behavior under the qualified supervised runtime without weakening guards; sync mdBook and canonical records, commit, then resume activation/caller collection.`
  Verification: `git log -S traces token-free named-drive scalar lowering to 2879f22af56e1835a9afe52476e2d8cee6147245. T1542/T1543 pass under the default RAM guard with the already-qualified Darwin runtime opt-in, covering executable SystemVerilog/native Verilog and token-free VHDL generation. Current named-drive cards/detailed behavior and mdBook now distinguish repaired generation from still-unqualified external VHDL compile/runtime. The dated selection record preserves the original observation with an explicit current follow-up. Consulted reverify commands retain the default guard and clarify that runtime skips are not qualification. Focused obsolete-claim search is empty; book build passes. Resume .32.1.3.3.1.3.3.2.2.3.2.`
  Commit: `this commit`


- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.58`
  Status: `pending`
  Goal: `Resolve the authored actor-port keyword acceptance boundary.`
  Acceptance: `P2 candidate found in the priority baseline: input force strict-admits, while the shared shipped-target keyword registry reserves force and the public semantic assignment text retains that spelling. Reproduce from docs/audits/priority-contributors-20260927/multi_state.isf after the P1 contributor repair; independently compile emitted HDL using the qualified native observer before classifying actual backend behavior. Establish the published authoring contract and choose consistent early diagnostics or supported escaping if a gap is confirmed. Keep storage-variable policy 0110 and logical/generated identifier families distinct. Own implementation, complete native/API/newline diagnostics, target case/legal-name controls and book/spec/downstream sync; do not advertise unmeasured compiler rejection. Schedule after the P1 priority repair and before declaring full writer qualification complete.`
  Verification: `Unmeasured compiler outcome; this is not part of the static priority-overwrite proof. The existing T1219 also uses input force. Planned T1974 priority runtime must use a separately admitted legal override_req spelling so keyword acceptance cannot obscure that oracle.`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.59`
  Status: `done`
  Goal: `Perform the startup-due safe artifact cleanup before the next resource validator slice.`
  Acceptance: `Last cleanup is 2026-09-27T19:21:28+00:00 and the resumed session is 2026-09-29. Inventory repository-local generated artifacts and Rust release/debug dependency/incremental log/bin candidates. Delete only provably disposable completed book renders; preserve all failure/native evidence, logs, spent compiler/proxy directories and ambiguous build products. Overwrite the bounded cleanup record, verify exact selected path absence, synchronize task/resume state and commit separately.`
  Verification: `Only .artifacts/{priority-contributors,priority-contributor-repair,same-value-selector-repair,priority-final-observation,priority-runtime-qualified,writer-resource-grants,resource-activation}/book were removed after same-volume, non-symlink, untracked and actual mdBook index/hashed-asset checks. Initial unhashed book.js preflight assumption failed safely before deletion and was corrected from index.html. All selected paths are absent; all log/bin candidates are retained. Root target and rust/target/release are absent; rust debug deps/incremental contain no log/bin candidates. Census and cleanup procedure: .artifacts/artifact-cleanup-20260929/. Latest-cleanup record overwritten. No product behavior/book source changed; preceding committed book build remains valid. Next .32.1.3.3.1.3.3.2.2.3.2.2.2.2.3.2.2.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60`
  Status: `active`
  Goal: `Resolve the additional SPECFORGE duration, named-timer and aggregate-port feature requests and the unstated-reset question supplied on 2026-09-29.`
  Acceptance: `Own every requested capability and question, retain authorized packet inputs locally, independently reverify current compiler observations, distinguish supplied corpus/scale measurements from FSMGen evidence, and select bounded roadmap-aligned implementation and qualification leaves. Read sibling packet inputs only; do not change the SPECFORGE checkout, run its commands blindly, inspect submodule internals or treat illustrative syntax as selected. Director states SPECFORGE is blocked, so finish and commit only the active resource validator, then prioritize downstream intake and the smallest shippable unblocks. Resolve the reset question first, inventory other packets promptly, and retain broader compiler prerequisites only where a specific request needs them. No dirty pivot.`
  Verification: `Read all four packet README files from the director-authorized external directories. Reset packet preservation, reproduction, provenance delivery and complete question answer are qualified under .60.3, with P1 malformed-option repair .62 complete. Duration packet preservation and baseline reproduction are qualified under .60.1.1; named-timer packet preservation and baseline reproduction are qualified under .60.2.1; aggregate packet preservation and baseline reproduction are qualified under .60.4.1. Required duration/timer/record feature deliveries remain open. Required scalar storage access from the earlier packet is qualified under .38.1; domain details are qualified under .38.3. Next .60.4.2 selects record-port delivery; optional bank access stays owned after required packet features. The requests cite FSMGen 8513cef4254db4572ab8dd3c94f3953df358f0a9 plus a separate SPECFORGE pin; neither is a current-result claim. Corpus counts and timing observations are supplied external evidence, not independently verified here.`
  Commit: `pending`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.1`
  Status: `active`
  Goal: `Time-unit durations and clock frequency from sf-isf-duration-time-units.`
  Acceptance: `R1 duration literals for wait/watchdog/latency/temporal bounds; R2 literal/parameter clock frequency or period per actor/domain; R3 exact stated conversion with upward minimum/wait rounding and downward maximum rounding plus source/frequency/derived reports; R4 counter lowering independent of duration count; optional R5 legal duration ranges. Preserve existing cycle-count meanings. Own the reported static-wait scale limit without replaying the large timeout before bounded measurement design. Commit each implementation/qualification slice with book/spec/downstream/API/MCP applicability and independent evidence before any completion claim.`
  Verification: `.1 preserves and qualifies the complete packet/current baseline. Required and optional contract selection remains .2; no duration implementation is shipped. Preserve the existing cycle-parameter schedule and define frequency-parameter override/count-width recomputation explicitly before implementation.`
  Commit: `pending`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.1.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.1.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.1.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.1.4`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.1.1`
  Status: `done`
  Goal: `Preserve and qualify the supplied packet baseline.`
  Acceptance: `Read request.json, SIGNOFF.md, commands and all relevant sources/evidence for sf-isf-duration-time-units; copy needed inputs and immutable provenance into repository-relative storage after identity checks. Independently run small bounded current native/API/MCP controls, retain discrepancies and root-cause any actual defect. Do not rerun large scale probes or native runtime without their existing admission/measurement prerequisites.`
  Verification: `Full request/signoff/commands/source/expected material read; packet text/size/SHA identities and exact source copies retained in docs/audits/specforge-duration-intake-20260930/. Guarded capture Files=1, Tests=4 PASS with complete native/API/newline reports and expected schedule transport refusals. Actual carrier independently contains 236 states, including 234 wait states, with no wait counter; every prior supplied baseline schedule field matches after excluding only reset_provenance. Initial audit assumptions about schedule exit and carrier indentation were corrected without production changes; both logs retained. Offline verifier checks source/product identities and rejects matching-copy count/counter/provenance/failure corruption plus changed carrier census. No large scale probe, performance/corpus claim, implementation or native HDL run. The foreign Git-head issue remains owned by .32.2. Book, canonical fact and downstream response state the unshipped boundary. Next intake is .60.2.1; contract .60.1.2 follows sibling inventories.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.1.2`
  Status: `pending`
  Goal: `Select the precise contract and safe dependency order.`
  Acceptance: `Map all required and optional packet requirements to current roadmap, decisions, parser/lowerer/backends/reports/tests/book. Resolve time-unit durations and clock frequency semantics within director authority; explicitly own any missing decision, source ambiguity or external evidence gap. Decompose implementation before source changes; do not equate intake with delivery.`
  Verification: `pending preceding contract dependency`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.1.3`
  Status: `pending`
  Goal: `Implement the selected bounded contract.`
  Acceptance: `After baseline and contract selection, split into independently verifiable parser/IR/lowering/report/diagnostic and compatibility leaves before code changes. Preserve accepted source semantics, locality and source provenance. Use existing public dependency APIs and qualify every affected public facade and book example.`
  Verification: `pending preceding contract dependency`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.1.4`
  Status: `pending`
  Goal: `Qualify the complete consumer outcome.`
  Acceptance: `After implementation, independently exercise positive/negative cases, unchanged controls, target-qualified HDL where behavior changes, exact native/API/newline reports, source/capability/corpus/book alignment and all explicit requirement dispositions. Retain recoverable evidence and a repository-local downstream response; no external sending is authorized by this intake.`
  Verification: `pending preceding contract dependency`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.2`
  Status: `active`
  Goal: `Concurrent actor-owned named timers from sf-isf-named-timers.`
  Acceptance: `R1 named limits and duplicate/zero/unknown refusals; R2 start/restart/stop from rules and transactions; R3 ordinary expiry conditions; R4 concurrent timers independent of initiating transactions; R5 limit/width/control/use reports. Optional R6 per-await watchdog limits stays distinct. Preserve watchdog error semantics; timer command conflicts require qualified writer admission and explicit timing/reset/control precedence. Commit each implementation/qualification slice with book/spec/downstream/API/MCP applicability and independent evidence before any completion claim.`
  Verification: `.1 preserves and qualifies the complete packet/current watchdog baseline. Cycle limits are required, duration support is conditional, and per-await watchdog limits are optional. Contract .2 must define timing/control/reset precedence and actual concurrent expiry qualification; no named-timer implementation ships yet.`
  Commit: `pending`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.2.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.2.4`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.2.1`
  Status: `done`
  Goal: `Preserve and qualify the supplied packet baseline.`
  Acceptance: `Read request.json, SIGNOFF.md, commands and all relevant sources/evidence for sf-isf-named-timers; copy needed inputs and immutable provenance into repository-relative storage after identity checks. Independently run small bounded current native/API/MCP controls, retain discrepancies and root-cause any actual defect. Do not rerun large scale probes or native runtime without their existing admission/measurement prerequisites.`
  Verification: `Full request/signoff/commands/source/expected material read. Packet identities, exact sources, complete native/API/newline reports and actual baseline carrier retained in docs/audits/specforge-timer-intake-20260930/. Guarded capture Files=1, Tests=3 PASS; current schedule equals every supplied prior field after excluding reset_provenance. The actual watchdog loads limit minus one, sets last_error and returns to idle on timeout. Named declarations and distinct await limits remain refused. Offline verifier rejects matching-copy counter/count/failure/provenance corruption plus altered actual load/error assignments. Initial audit guesses about load folding and output markers were corrected without production changes; both logs retained. No native execution or external corpus measurement. Next .60.4.1, then selected feature contracts and implementation.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.2.2`
  Status: `pending`
  Goal: `Select the precise contract and safe dependency order.`
  Acceptance: `Map all required and optional packet requirements to current roadmap, decisions, parser/lowerer/backends/reports/tests/book. Resolve concurrent actor-owned named timers semantics within director authority; explicitly own any missing decision, source ambiguity or external evidence gap. Decompose implementation before source changes; do not equate intake with delivery.`
  Verification: `pending preceding contract dependency`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.2.3`
  Status: `pending`
  Goal: `Implement the selected bounded contract.`
  Acceptance: `After baseline and contract selection, split into independently verifiable parser/IR/lowering/report/diagnostic and compatibility leaves before code changes. Preserve accepted source semantics, locality and source provenance. Use existing public dependency APIs and qualify every affected public facade and book example.`
  Verification: `pending preceding contract dependency`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.2.4`
  Status: `pending`
  Goal: `Qualify the complete consumer outcome.`
  Acceptance: `After implementation, independently exercise positive/negative cases, unchanged controls, target-qualified HDL where behavior changes, exact native/API/newline reports, source/capability/corpus/book alignment and all explicit requirement dispositions. Retain recoverable evidence and a repository-local downstream response; no external sending is authorized by this intake.`
  Verification: `pending preceding contract dependency`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.3`
  Status: `done`
  Goal: `Source-honest unspecified-reset guidance from sf-isf-unstated-reset.`
  Acceptance: `Answer the distinction between omitted/defaulted reset, actual no-reset clock domains and implementation-selected reset. Reverify generated initial state/register behavior and all report surfaces for supplied variants; never infer initialization from successful checking. Explain single-domain support and supported target limits, distinguish unstated from absent hardware, and answer the missing configurable-reset form without treating this question as a feature request. Commit each implementation/qualification slice with book/spec/downstream/API/MCP applicability and independent evidence before any completion claim.`
  Verification: `Question answered, with the report ambiguity resolved by qualified provenance and malformed reset options repaired under .62. Complete downstream response and initial-state/storage limits are in docs/SPECFORGE_FEEDBACK_RESPONSE.md and docs/audits/specforge-reset-answer-20260930/. .1 owns the immutable packet baseline, .2 the contract, .3.3.1 the public delivery and .4 the consumer answer. The director-confirmed question scope excludes the withdrawn configurable-reset inference .61. SPECFORGE owns whether its adapter may accept compiler defaults; no current form defers policy to instantiation.`
  Commit: `this commit`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.3.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.3.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.3.4`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.3.1`
  Status: `done`
  Goal: `Preserve and qualify the supplied packet baseline.`
  Acceptance: `Read request.json, SIGNOFF.md, commands and all relevant sources/evidence for sf-isf-unstated-reset; copy needed inputs and immutable provenance into repository-relative storage after identity checks. Independently run small bounded current native/API/MCP controls, retain discrepancies and root-cause any actual defect. Do not rerun large scale probes or native runtime without their existing admission/measurement prerequisites.`
  Verification: `Read-only packet preserved losslessly in docs/audits/specforge-unstated-reset-20260930/packet.json; input identities and emitted products retained with revision/producer hashes. capture.t --strict --check --json / --emit-semantic-json / --emit-schedule-json: Files=1, Tests=3 PASS, complete native/API/newline parity after correcting test-only repository-path normalization. Existing omission and explicit baseline differ only by source paths; clock-only schedule/semantic reset is null and actual SV/Verilog has neither state initializer nor reset branch. verify.py independently checks contracts/HDL/identities and rejects corrupt reset/default/initialization controls. No native runtime executed or startup guarantee inferred. Legacy default mechanism: Parser::_finalize_actor_timing_conventions; clock-domain omission bypasses it. Source provenance/implementation-choice answer remains .60.3.2 onward.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.3.2`
  Status: `done`
  Goal: `Select the precise contract and safe dependency order.`
  Acceptance: `Map all required and optional packet requirements to current roadmap, decisions, parser/lowerer/backends/reports/tests/book. Resolve source-honest unspecified-reset guidance semantics within director authority; explicitly own any missing decision, source ambiguity or external evidence gap. Decompose implementation before source changes; do not equate intake with delivery.`
  Verification: `Decision 0112 selects reset_provenance per authored actor/domain before defaulting, shared success source metadata and complete native/API/newline/capability qualification. Explicit existing hardware contracts and carriers remain unchanged; unknown caller-created provenance is not guessed. Legacy omission is an unstated ISF clause with a selected implementation default, not a deferred reset contract or proof about an unseen original specification. Q1/Q3 and expected metadata distinction are delivered by .60.3.3; Q2 is qualified static reset-free absence with no guaranteed initialization; Q4 is answered as missing; the inferred implementation follow-on .61 is superseded by the director clarification that this packet is a question. No writer/controller/native-runtime prerequisite for metadata. Found and corrected stale spec statement claiming ISF supports only one domain: same section already documented named domains, and supplied single-domain source passes. Existing reset carrier decision 0106 remains authoritative.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.3.3`
  Status: `done`
  Goal: `Implement selected reset declaration provenance without hardware changes.`
  Acceptance: `Decision 0112 defines the bounded metadata contract. Child .1 owns coherent parser/IR/report/capability implementation and focused qualification before .60.3.4 consumer closure. No new source syntax or reset timing, initialization, backend or admission change.`
  Verification: `Child .1 qualifies the complete additive provenance contract and unchanged hardware. Consumer response .60.3.4 follows the separately discovered P1 reset-token repair .62.`
  Commit: `this commit`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.3.3.1`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.3.3.1`
  Status: `done`
  Goal: `Retain and expose reset clause provenance through every affected facade.`
  Acceptance: `Retain parser evidence before defaults; detached schedule reset_provenance and successful ISF source.reset_provenance entries have domain/origin and explicit/legacy_default/domain_absent values. Preserve unknown evidence as null/absence, named-domain order/selection and standalone FSM reports. Advertise exact capability key/value families; qualify supplied forms, default clock, mixed domains, permutations, caller-built actor, malformed source, detachment, full native/API/newline equality, baseline carrier/HDL equality and focused neighboring contracts. Update corpus, spec, book, shared source and ISF public contract together; split again only if the bounded implementation exposes a real dependency.`
  Verification: `T1978 red -> green; final Files=1, Tests=5 PASS. Parser retains clause provenance before defaults; detached projections preserve authored domain order and scope. Successful ISF native check/semantic plus schedule, API/newline and capability discovery agree completely. Direct FSM/PPIF and failure controls acquire no ISF provenance; unknown caller-created evidence remains null. All prior supplied reports except the new field, complete FSM and both Verilog targets except date remain identical to the sealed baseline. Hostile evidence is rejected. Neighboring report/reset/domain regressions pass after updating the expected advertised test catalog; golden/book/schema follow-up Files=4, Tests=288 PASS. Exact logs and producer hashes: docs/audits/specforge-reset-provenance-20260930/. No new source syntax, corpus category, HDL behavior or native runtime; current corpus cases participate in T1255/T1890/T1893. New reset-token P1 .62 is next before consumer closure.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.3.4`
  Status: `done`
  Goal: `Qualify the complete consumer outcome.`
  Acceptance: `After implementation, independently exercise positive/negative cases, unchanged controls, target-qualified HDL where behavior changes, exact native/API/newline reports, source/capability/corpus/book alignment and all explicit requirement dispositions. Retain recoverable evidence and a repository-local downstream response; no external sending is authorized by this intake.`
  Verification: `Complete repository-local response in docs/SPECFORGE_FEEDBACK_RESPONSE.md answers every supplied question and expected outcome: omission is source-unstated plus selected legacy hardware default; clock-only means actual no reset with no guaranteed initialization; standalone domains are supported; provenance is discoverable; instantiation-selected reset is absent and not inferred as a feature request. T1980 qualifies written/read-only storage and explicit-reset controls through native reports and actual SV/Verilog emission; T1398 misleading power-on wording corrected without assertion changes. Files=2, Tests=5 PASS. Initial helper-name test assumption corrected against actual emission, retaining the failed and successful logs. Exact products and hashes: docs/audits/specforge-reset-answer-20260930/. Prior T1978 complete supplied native/API/newline, baseline and capability qualification remains current because production is unchanged. No external message, SPECFORGE checkout write or new native runtime. Director-prioritized feature intake resumes at .60.1.1.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4`
  Status: `active`
  Goal: `Packed record interface ports and named fields from sf-isf-aggregate-interface-ports.`
  Acceptance: `R1 local/imported packed record input/output ports and precise unknown/unpacked refusals; R2 scalar-context input field reads, output field writes and whole same-type port/storage copies; R3 documented packed layout/width in carriers, HDL and reports. Optional R4 list ports and R5 variants remain explicitly separate. Preserve scalar/storage behavior and depend on qualified physical writer overlap before output-field admission. Commit each implementation/qualification slice with book/spec/downstream/API/MCP applicability and independent evidence before any completion claim.`
  Verification: `.1 preserves and qualifies the complete packet/current storage baseline. Required packed-record ports/fields/copies/reports remain unshipped; list ports and variants are optional. Decision 0113 separates input reads from output writer admission; .3.1 begins detached interface metadata before record source admission.`
  Commit: `pending`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.4, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.5, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.6`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.1`
  Status: `done`
  Goal: `Preserve and qualify the supplied packet baseline.`
  Acceptance: `Read request.json, SIGNOFF.md, commands and all relevant sources/evidence for sf-isf-aggregate-interface-ports; copy needed inputs and immutable provenance into repository-relative storage after identity checks. Independently run small bounded current native/API/MCP controls, retain discrepancies and root-cause any actual defect. Do not rerun large scale probes or native runtime without their existing admission/measurement prerequisites.`
  Verification: `Full request/signoff/commands/source/expected material read. Packet identities, exact sources, complete native/API/newline products and actual baseline carrier retained in docs/audits/specforge-aggregate-intake-20260930/. Guarded capture Files=1, Tests=3 PASS. Both record-port forms retain precise parser refusal; accepted typed storage retains width, kind, member order and scalar leaf assignment. Every supplied baseline check field matches after exact source path relocation and reset_provenance removal. Independent verifier rejects matching-copy count/storage/failure/provenance corruption, changed member order and changed carrier target. No production change, native runtime or external corpus measurement. Next inspect .38.1 and its recorded execution prerequisites against the metadata-only contract before selecting delivery; aggregate contract .60.4.2 remains owned.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.2`
  Status: `done`
  Goal: `Select the precise contract and safe dependency order.`
  Acceptance: `Map all required and optional packet requirements to current roadmap, decisions, parser/lowerer/backends/reports/tests/book. Resolve packed record interface ports and named fields semantics within director authority; explicitly own any missing decision, source ambiguity or external evidence gap. Decompose implementation before source changes; do not equate intake with delivery.`
  Verification: `Decision 0113 maps R1-R3 to shared packed types, live scalar reads, same resolved record-type copies and physical writer admission. Detached public interface metadata precedes input delivery, whole output copies and scalar output-field writes. Optional R4/R5 have separately blocked owners .60.4.5/.6. The supplied baseline/source contracts and exact core member-offset order were read; no record-port acceptance or runtime signoff is claimed. Shared claim template matches its reviewed snapshot; cleanup remains within its required interval. Focused doctrine, historical baseline and book verification are recorded below.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3`
  Status: `active`
  Goal: `Implement the selected bounded contract.`
  Acceptance: `After baseline and contract selection, split into independently verifiable parser/IR/lowering/report/diagnostic and compatibility leaves before code changes. Preserve accepted source semantics, locality and source provenance. Use existing public dependency APIs and qualify every affected public facade and book example.`
  Verification: `Decision 0113 selects five independently qualified delivery slices; declaration metadata .3.1 is qualified and .3.2 next owns record input delivery. Record source ports remain refused until their delivery leaves pass.`
  Commit: `pending child qualification`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.4, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.5`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.1`
  Status: `done`
  Goal: `Project detached declared interface metadata without changing accepted hardware.`
  Acceptance: `Implement one closed fresh JSON-safe snapshot from parsed ports, shared success source.interface_ports and schedule interface_ports, owned domain details and capability field families under decision 0113. Qualify scalar/local/imported/unused/undriven/domain interfaces, null caller-created metadata, copy isolation and complete native/API/newline products. Record-layout producer controls do not admit record source ports. Preserve complete pre-change scheduled FSM/HDL and existing check/semantic/schedule controls; synchronize book/spec and corpus applicability.`
  Verification: `Children .1-.3 qualify the closed producer, detached parser/IR/source/schedule/domain integration and complete typed native/API/newline products, supported corpus allocation, hostile controls and historical hardware/report preservation. Known/unknown declaration evidence and private boundaries are explicit. The book/spec/discovery/corpus are synchronized. This is metadata delivery; authored record inputs/outputs remain separately pending under .3.2-.3.5.`
  Commit: `this commit`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.1.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.1.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.1.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.1.1`
  Status: `done`
  Goal: `Implement the closed detached interface snapshot producer.`
  Acceptance: `Implement source-ordered declared port projection, scalar/local/imported type metadata, nested record leaf ranges through the shared aggregate resolver, known/unknown metadata handling and exact public schema description under decision 0113. Independently test signed/state-model/order/range properties, null/empty distinctions, mutation isolation and malformed/cyclic/contradictory metadata. No parser admission, report wiring or native runtime in this slice.`
  Verification: `T1983 independently verifies scalar/local/imported identities, ordered nested record/list leaf ranges, signed/state-model properties, known empty versus unknown, detached JSON-safe values and contextual malformed/cyclic/range/type refusals. Draft hostile controls exposed list-context predicate disappearance; an argument-count guard then exposed expanding nonempty array predicates. Explicit boolean/scalar results and exact guard arity repair both mechanisms. Guarded T1983 plus T1259 report All tests successful; authoring/parser/report/HDL paths remain unchanged and record ports retain their current refusal. Report integration is .3.1.2.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.1.2`
  Status: `done`
  Goal: `Integrate declared interface snapshots through parser, IR and reports.`
  Acceptance: `After qualified producer .1, capture validated parsed declarations without widening accepted source forms; preserve actor/domain/source ownership and generated private handoff boundaries. Wire shared success source and schedule/domain fields, including unknown caller-created metadata, advertise exact capability shapes and update book/spec. Prove unchanged scheduled carriers/HDL and existing failures before claiming report delivery.`
  Verification: `Parser captures declarations after validation, ordinary IR retains detached evidence and domain sources filter owned original ports before private injection. T1984 independently verifies local/imported scalar declarations, unused/undriven source order, known empty versus unknown, failure/unrelated omission, generated-child and actual event-crossing exclusions, source/IR/report isolation and exact shared discovery families. Guarded T1984/T1259/source-copy/roundtrip/facade/schedule set reports All tests successful. T1978, T1981, T1982 and T1255 passed with production code unchanged, preserving complete native/API/newline products, historical reports apart from the explicitly removed new metadata, actual scheduled files and HDL except date. The initial aggregate run failed only draft fixture assertions expecting do to generate a child and activation metadata to enter interface arrays; corrected controls use spawned children and actual event interface injection. New book example check/semantic/schedule arrays match the independently written JSON. The advertised-key census found verification_bridge missing from two maintained top-level lists; this leaf owns and fixes that stale schema and exact set rechecks pass. Record source ports remain refused; no native HDL runtime or downstream completion is claimed. Complete new transport/corpus coverage remains .3.1.3.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.1.3`
  Status: `done`
  Goal: `Qualify complete public metadata delivery and unchanged controls.`
  Acceptance: `After .2, independently compare complete native/API/actual newline check, semantic, schedule and discovery products for scalar/local/imported/unused/undriven/domain sources, malformed source and unrelated formats. Verify detached ownership, actual baseline carriers/HDL, all compatibility tests and existing supported corpus applicability. Preserve record-port refusal and close the metadata lane only with recoverable evidence and synchronized docs.`
  Verification: `T1985 compares complete typed native/API/actual newline check/semantic/schedule products for every live supported ISF source-query row against independently reviewed literal port lists, plus local/imported aliases, empty interfaces and empty named domains. Record/list/unknown-width source refusals and unrelated FSM/PPIF omission/null controls pass; discovery sections compare complete products and source bytes stay unchanged. Identical corrupt transport copies still fail independent typed width/role/order/field/private-data expectations. The new feature owns dedicated isf/interface_port_metadata.isf and a supported catalog entry. T248 exposed an invalid reused (relpath, classification, coverage) tuple and stale exact counts from storage-word-access commit 3fa482924; pre-slice 241fad6b5 exports 384 supported/374 strict entries while the final catalog exports 385/375 with no duplicate tuples. The dedicated fixture and independently recounted T248 expectations repair both issues. Guarded T1985/T248/T1883 reports All tests successful. Existing T1983/T1984 and retained historical native/API/newline reports, exact carriers and HDL controls establish the unchanged boundary. Focused T1884 qualifies the new public fixture and producer/envelope/semantic provenance; book and staged doctrines gate completion. No native HDL runtime, record source admission, full CI/push or downstream completion is claimed.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2`
  Status: `done`
  Goal: `Deliver packed record inputs, scalar field reads and whole input-to-storage copies.`
  Acceptance: `After .3.1, split further as needed before implementation. Admit local/imported resolved record roots, existing nested scalar paths and same resolved record-type copies. Qualify all existing scalar-expression contexts and declared input-write refusals, type/path mismatches, whole-record scalar-context refusal, unused ports, domain ownership and generated-child routing. Compare public IAL0 replay, independent packed-value HDL observations and complete native/API/newline products under HIAL admission; preserve scalar/storage-only sources and publish supported examples.`
  Verification: `Selected R1–R3 input portions are independently qualified through committed ingress, type/role/context/domain/sample/source, generated/public, backend/profile and genuine direct/generated execution children. Exact requirement/evidence join and current public checks are sealed under .5.5.3.2.3. Record outputs/field writers and full aggregate consumer delivery remain required; X/Z and historical-native limits stay explicit.`
  Commit: `pending child qualification`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.1`
  Status: `done`
  Goal: `Trace record-input ingress and select the safe qualification split.`
  Acceptance: `Read selected source/type/role contracts and relevant parsed value, enum, domain, lexical, IAL0 and child routes. Reproduce current source refusal without native runtime, retain independent resolved type/layout controls and map every required scalar-read/copy context to its owning validator and emitted carrier. Decide bounded role, type identity and shadowing behavior from existing public/core contracts; own genuine unresolved dependencies before any admission change. Publish precise children and synchronized future book guidance without widening source.`
  Verification: `Decision 0113 retains the source/type/role/enum/lexical/domain/carrier ingress map and reproducible pure controls. Alias-equivalent resolved records match; existing public payload compatibility accepts distinct signed/state facts, requiring a separate strict identity gate without changing literal/storage behavior. Source record inputs still refuse at Parser.pm line 2862. Transaction locals/formals and drive parameters must mask outer declaration roots. Scalar leaf entry/body samples need resolved width/type and existing timing; whole-record inferred samples remain deferred. Five bounded children own gate preparation, source admission, generated/domain carriers and native/public completion. Guarded T1983/T1259 reports All tests successful; no new authoring or native runtime is claimed.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.2`
  Status: `done`
  Goal: `Qualify closed resolved record-type and input-role value gates.`
  Acceptance: `After .1, implement or reuse one qualified recursive type-identity and readable/writable root contract, with independent same-width different-member/order/signed/state-model controls, alias-equivalent positives, scalar-leaf and input-write refusals. Preserve existing storage-only transfer contracts and lexical shadowing. Prepare gates without admitting new source until every required value context can fail closed.`
  Verification: `ISFRecordPortValues prepares closed detached declaration scopes, nearest-binding masking, core scalar type/ranges and strict whole-record-port copies through existing composition comparison after validated shape. T1986 independently distinguishes alias/imported identity from equal-width member/order/kind/nested/list/signed/state mismatches, exact nested ranges, unresolved/scalar/formal shadows, known input roles, malformed/cyclic facts and storage-only bypass. Review exposed scalar shadow slices requiring core traversal anchoring and a draft diagnostic oracle accepting regex text from Carp caller stacks. First-line-only oracles turned incorrect reason-key projections RED; code-key projection and a permanent known-bad stack control repair the cause. Guarded T1986 plus metadata/storage/core-path/structural-type/interface controls reports All tests successful. Parser and scheduler remain unwired; authored records/lists retain refusal, and native/public input delivery is pending.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3`
  Status: `done`
  Goal: `Admit record inputs with qualified scalar reads and same-type copies.`
  Acceptance: `After .2, admit only local/imported resolved record input roots and wire all applicable transaction, rule, named-drive, enum-disambiguation and domain validators; qualify scalar leaf entry/body sampling width/type and existing capture timing while whole-record inferred samples refuse. Copies from an input to actor storage must use qualified recursive type identity from first admission; input writes and whole-record scalar contexts refuse. Root lists, outputs and transaction-local aggregate ports retain precise boundaries. Qualify nested paths, symbolic alias equivalence, lexical shadows, invalid members/types/roles and complete emitted IAL0 replay; synchronize accepted public reports and book.`
  Verification: `Children .1-.6 qualify lexical/type/path/role/context/sample/domain prerequisites, first bounded record-input admission and complete authored frontend/public source/replay closure. Accepted local/imported/nested/shadow sources, contextual refusals, unchanged supplied sources and preserved scalar/storage products are qualified. Generated/domain carrier completion and backend/native/consumer delivery remain .2.4-.2.5.`
  Commit: `children completed through .6.3.1 in this commit`


  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.4, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.5, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.6`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.1`
  Status: `done`
  Goal: `Select bounded contextual integration and re-verify admission prerequisites.`
  Acceptance: `Trace finalized declarations, actual lexical bindings, AST scalar/copy contexts, enum maps, sampling width/type carriers and domain-root protection. Re-verify questionable prerequisite behavior through public interfaces without native execution, log and schedule every confirmed defect, and select exact integration children before code mutation. Keep source refusal and the book future boundary.`
  Verification: `Decision 0113 retains finalized declaration/lexical/AST/enum/sampling/domain integration boundaries and a reproducible public domain probe at pre-repair 02827d840. Foreign unsliced member and whole input controls refuse, while record-member/storage scalar slices and scalar input slices/bit indexes pass lowering. Domain lookup excludes colon ranges and non-storage roots. P1 repair .3.4.1 is next before contextual source work; .3.4.2 retains future record/formal/domain protection. Source record ports remain refused. Existing domain/storage baseline, task/book and staged doctrines qualify decomposition without native execution.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.2`
  Status: `done`
  Goal: `Prepare scoped record-value and enum-context gates without admission.`
  Acceptance: `Use actual finalized actor, transaction local/formal and drive-parameter declarations to build nearest-binding scopes. Reuse qualified value primitives for all selected transaction/rule/drive scalar/copy contexts, input roles and exact resolved identity. Prepare coherent aggregate/enum/rule operand root classification; retain legacy storage/scalar behavior and record source refusal until mandatory gates are wired. Qualify independent AST/source controls, unknown paths, enum/package names, lexical shadows and unchanged facades.`
  Verification: `Children .1-.3 qualify actual declaration scopes, selected contextual scalar/copy gates, repaired first-touch caller-data detachment and a common aggregate/enum/rule root projection. Complete current public products and historical carriers remain unchanged. Frontend wiring, sampling, domains and authored record input admission retain subsequent owners; all three preparation children are committed through their work-unit subjects.`
  Commit: `this commit`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.2.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.2.1`
  Status: `done`
  Goal: `Prepare detached scopes from actual parsed declarations.`
  Acceptance: `Consume finalized actor interface/storage declarations, transaction formals and explicit local AST declarations, and named-drive parameter names. Preserve declared input/output/storage roles, nearest local/formal masking, resolved signed/state facts and unknown local/drive type facts without placeholder inference. Do not invent declarations from assignment targets or admit invalid local collisions. Qualify parsed ordinary/imported/symbolic controls, independent scope/range witnesses, mutation isolation, unresolved/shadow cases and unchanged parser/lowering products. Keep contextual wiring, sampling and source admission pending.`
  Verification: `ISFRecordPortScopes projects actual finalized actor ports/var storage, transaction formals and explicit local AST clauses, and untyped drive parameters into detached qualified value scopes. T1987 independently expects width/type/role/range facts, imported equivalence, unresolved/scalar/local/formal shadows and mutation isolation; it rejects malformed facts and retains authored pin/storage, explicit-local pin-collision and symbolic-local refusals. No assignment-inferred declaration or type placeholder erases actor input ownership. Complete parsed and scheduled objects, including emitted file bytes, are unchanged. Guarded T1987/T1986/T1983/T1259/T1391 reports All tests successful, Files=5, Tests=33. Helpers remain unwired; contextual/enum, sampling, domain and source/runtime admission remain pending.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.2.2`
  Status: `done`
  Goal: `Prepare selected scalar and whole-copy AST context validation.`
  Acceptance: `After detached scopes, validate selected set/update RHS, condition/switch, rule assignment/guard, inline/named drive body and actual contexts with qualified value primitives. Distinguish same-type whole record assignments from scalar contexts and refuse declared input writes, operator-position paths and unsupported subaggregate uses. Preserve established scalar/storage-only behavior and delegate unrelated tokens to current validators. Qualify independently authored AST positives and precise first-line failures without source admission. P2 owned prerequisite: scope projection and underlying scope/reference/copy validation read borrowed resolved widths numerically, changing JSON scalar kinds on fresh copies of parsed actors; reproduce with a fresh copied pre-projection complete product, detach all caller-owned facts before validation and retain permanent first-touch controls. The independent scalar demonstration changes {width:"7"} to {width:7} after numeric reading alone. P2 draft namespace control: admitted mode.BUSY with scalar input mode must remain an enum token rather than an invalid scalar member; preserve actual namespace delegation while retaining nearest aggregate-shadow facts. No public facade is currently wired.`
  Verification: `ISFRecordPortContexts prepares actual scoped transaction/rule/drive scalar and copy contexts, exact input roles, strict resolved identity, operator/path refusals and namespace delegation without source wiring. T1988 independently qualifies selected ASTs, whole-record scalar/negation/comparison negatives, wrong-copy and input-target failures, nearest shadows and admitted enum/pin coexistence. Its complete copied-actor comparison exposed numeric validation mutating caller JSON kinds; first-touch T1987 and explicitly string-width T1986 controls go RED. Scope, reference, copy and declaration extraction now detach before numeric reads; all caller products stay unchanged. Direct fresh parser controls remain equal; copied facts were the distinct missing case. Decision 0114 retains diagnosis, independent mechanism and permanent producers. Guarded T1988/T1987/T1986/T1983/T1259/T1391 reports All tests successful, Files=6, Tests=42. Complete admitted parser/scheduled products and file bytes are unchanged. Namespace integration, sampling, domains, source admission and native behavior remain pending.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.2.3`
  Status: `done`
  Goal: `Align contextual aggregate, enum and rule namespace classification.`
  Acceptance: `After contextual gates, prepare one actual scoped declaration-root classifier for aggregate-path, enum and rule-operand validators, honoring nearest bindings and preserving enum/package constants. Wire only behavior-preserving preparation on currently admitted sources or retain an explicit unwired boundary until sample/domain prerequisites permit admission. Qualify complete native/API/newline products, historical carriers and scalar/storage/enum/local controls, synchronize book/spec/facts and close this preparation parent only when all children qualify.`
  Verification: `ISFRecordPortScopes supplies one detached actual actor/transaction/drive projection for value, aggregate traversal, enum exclusion, namespace and actor rule roots. Nearest scalar/unresolved/drive bindings suppress outer aggregate traversal and enum fallback; scalar pin/package coexistence retains namespace ownership. Contextual gates consume the common projection; frontend validators remain explicitly unwired until sample/domain prerequisites qualify. T1989 independently expects complete maps, actual imported type/enum/constant facts, named-domain clocks/resets, first-read JSON and separate output-map detachment. Guarded T1989/T1988/T1987/T1986/T1985/T1982/T1259/T1391 reports All tests successful, Files=8, Tests=52. Complete native/API/newline check, semantic and schedule products, current refusals, historical domain reports, actual IAL0 files and generated SystemVerilog/Verilog except date remain unchanged. mdBook builds. No authored record admission or native HDL execution is claimed; sampling .3.3 is next.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.3`
  Status: `done`
  Goal: `Prepare qualified scalar-leaf sampling facts and typed carriers.`
  Acceptance: `Resolve entry/body sample leaf width and signed/state facts in actual lexical scope, preserve existing capture timing and deterministic private carrier ownership, and refuse whole-record inferred aliases. Reuse core type declarations and avoid alias collisions, leaked reset/type metadata, placeholder widths or implicit samples. Qualify replay, local/imported/nested and shadow controls without enabling record source before prerequisites are complete.`
  Verification: `Children .1-.3 qualify detached explicit sample facts, contextual/private carrier ownership and complete existing capture-state preservation with strict typed IAL0 semantic replay. Complete state comparisons and independent entry/await/pre-data witnesses reject isolated entry-guard loss. Actual imported leaves, nearest scalar formals, whole/invalid/masked refusals and caller isolation pass. Generated/domain carriers remain qualified within their prior preparatory bounds; authored record sources still refuse. Domain preparation .3.4.2 precedes frontend admission; native runtime and complete delivery remain separately owned.`
  Commit: `this commit`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.3.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.3.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.3.1`
  Status: `done`
  Goal: `Prepare detached explicit scalar-leaf sample facts and alias bindings.`
  Acceptance: `Resolve exact entry/body sample sources in qualified actual lexical scope; retain scalar width, kind, signed/state facts and root-relative ranges. Reject whole-record/subaggregate inferred samples, input targets, invalid paths and record-derived alias collisions or inconsistent repeated bindings. Honor nearest scalar/unresolved formals and explicit locals, imported aliases and sample-alias shadows without inferring unknown types. Prepare deterministic private scalar type declaration products through the existing IAL0 declaration contract, without carrier/source wiring or capture-timing claims. P2 draft ownership: an earlier ordinary scalar sample must not erase an original authored storage declaration and permit later record-derived alias reuse; preserve the original collision set and retain an isolated known-bad rejection control. Qualify independent packed-layout, identity, shadow, negative and first-touch detachment controls.`
  Verification: `ISFRecordPortSamples prepares actual scoped explicit entry/body/control leaf references, alias bindings and record provenance. Core scalar facts and exact nested packed ranges are detached; whole aggregates, malformed paths, input targets, declaration collisions and inconsistent repeated aliases refuse. Unknown/formal/enum facts are delegated without width inference. A separate deterministic collision-safe scalar type AST/ref/width product has no reset/default leakage; the actual public type resolver independently reconstructs signed/state facts. T1990 independently expects a nine-bit layout, supplied input roles, actual imported types, nearest local/formal/unknown and alias shadows, consistent repeats, first-read complete copied JSON and sibling-output detachment. The initial local fixture removed its declaration via clause replacement; retaining the actual local AST repairs that fixture. An isolated draft predicate permits scalar-then-record sample reuse of authored storage held; the permanent rejection witness goes RED, then passes when the original declaration set remains authoritative. Guarded T1990/T1989/T1988/T1987/T1986/T1100/T1111/T1195/T1259/T1391 reports All tests successful, Files=10, Tests=61. Complete current parser/scheduled products and emitted bytes remain unchanged; native structured authored record-input check still refuses without output. Helpers are unwired; carrier integration .2 and replay/timing .3 are next, with no authored admission or native HDL execution claimed.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.3.2`
  Status: `done`
  Goal: `Integrate typed record-leaf sample aliases into existing private carriers.`
  Acceptance: `Consume .1 facts in contextual/sample validation and lowering width/type declarations while preserving established capture assignments and state order. Keep source admission refused; qualify supplied preparatory actor controls. Reuse core scalar type declarations, deterministic collision-safe private type names and actual transaction identities. Avoid inherited reset/default/type metadata and unsound cross-transaction alias sharing; preserve ordinary scalar/storage sampling and unchanged carrier products.`
  Verification: `Children .1-.3 qualify contextual explicit-sample bindings, actual private parent/generated-child/domain widths and scalar types, exact eleven-product transaction ABI, helper/cross-writer ownership and first-touch caller isolation. Production consumes supplied preparatory record-input facts while authored record sources still refuse. Known-bad context/carrier/ownership and borrowed-metadata controls go RED; current focused and complete public products pass. All children are committed through their owning subjects. Complete replay/capture timing remains .3.3.3 before domain and source admission.`
  Commit: `this commit`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.3.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.3.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.3.2.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.3.2.1`
  Status: `done`
  Goal: `Consume qualified explicit sample bindings in unwired contextual gates.`
  Acceptance: `For supplied record-input actors, validate selected entry/body/control scalar-leaf samples and use their detached alias facts in contextual reads/copies. Keep input targets, whole-record snapshots, invalid paths, private declaration collisions and inconsistent aliases closed. Delegate existing storage-only packed sampling and namespace/unknown facts to current owners; never borrow outer record layouts or placeholder widths. Refuse unresolved forward sample chains that would lose newly derived record scalar facts. P2 draft selector defect: actor_has_record_input reads a null declared entry through a hash accessor, autovivifying caller inputs from [null] to [{}] while returning false. A direct first-touch probe reproduces this; validate declaration/container shapes before any entry dereference, retain a RED first-touch control and verify complete caller isolation. Preserve all currently admitted source/parser/lowering products and source refusal, with no module/carrier or capture-state change.`
  Verification: `The unwired contextual gate consumes ordered explicit sample plans for supplied record-input actors and overlays detached scalar alias facts before selected reads/copies. Port-only collection preserves legacy packed-storage inference and namespace ownership; whole input snapshots, paths, input targets, original declaration collisions, inconsistent aliases and unresolved forward record-derived sample chains refuse. T1991 independently covers selected entry/body/control samples, scalar alias shape/width, actual role masks and complete caller isolation. Its controls go RED against the exact e0015db1314cfc0625609a358219c85a8d4cfa4b context module, whose _unsupported route refuses packet.count; current producer passes. A direct draft-selector probe and T1991 first-touch RED control expose unchecked null-entry hash access autovivifying caller inputs from [null] to [{}]. Interface/list/entry shapes now validate before dereference, including malformed suffixes after a valid record; complete caller JSON stays unchanged. A standalone Perl array/hash read independently reproduces the mechanism. Guarded T1991/T1990/T1989/T1988/T1987/T1986/T1100/T1111/T1195/T1259/T1391 reports All tests successful, Files=11, Tests=67. Complete ordinary parser/scheduled products and emitted bytes remain unchanged, and authored records still refuse. Module ABI/carriers and native behavior remain unchanged; width/type emission .2 is next.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.3.2.2`
  Status: `done`
  Goal: `Carry qualified record-leaf sample widths and scalar types through module emission.`
  Acceptance: `After contextual consumption, integrate explicit private sample widths and core type declarations into actual parent/child/domain module IR without changing the transaction product ABI or capture assignments/state order. Preserve original declared resets/defaults and ordinary scalar/storage sampling. Use deterministic reserved type names, actual lexical/physical identities and precise refusal for unsupported prepared contexts; record source remains refused. P2 qualification prerequisite: T1938 compares raw parent_activation_products assignments with finalized parent payload fan-in after the qualified snapshot transformation. It falsely fails the current broader gate and the exact 24d0 predecessor at its line 27 guard comparison. Own and repair that test now by comparing complete selected snapshot products for transformed DTs, retaining exact raw comparisons elsewhere and independent guard/capture witnesses; do not remove the production snapshot transform to satisfy the old test.`
  Verification: `RecordSamples consumes qualified port-only facts before data-width collectors and after actual transaction/module helpers. It preserves the eleven-product transaction ABI, sample_alias role, existing capture assignments/guards/state order, collision-safe core scalar types and explicit private declarations without inherited resets/defaults. T1992 independently expects signed four-state and two-state bit carriers, exact widths/roles, reserved-name suffixes, complete caller isolation and native strict IAL0 replay in actual parent, documented spawn child and owning-domain modules. Its isolated 24d0 predecessor makes type/width/privacy controls RED despite successful untyped parent parsing. Local do was an incorrect generated-child fixture; documented spawn emits worker.fsm. Broader checks exposed T1938 comparing raw activation DTs with finalized payload snapshots; the exact predecessor reproduces the same guard mismatch. Its comparator now selects complete snapshot products only for transformed DTs, with independent initial-state, accepted capture and held-value witnesses. Omitting only production snapshot installation in an isolated lowerer makes those controls RED; no snapshot production change was needed. Guarded T1992/T1991/T1990/T1989/T1988/T1987/T1986/T1985/T1982/T1100/T1111/T1195/T1259/T1391/T1945/T1936/T1938 reports All tests successful, Files=17, Tests=95. Complete current public products, historical domain FSM/HDL carriers and ordinary sampling/formal controls remain qualified. Syntax and mdBook build pass; scoped dependency architecture, decision, map, claim inventory and exact maintained-reference authority accompany this slice. Actual helper/cross-owner qualification .3 is next; authored record ports remain refused and no native HDL execution is claimed.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.3.2.3`
  Status: `done`
  Goal: `Qualify actual private sample ownership against generated helpers and other writers.`
  Acceptance: `Before source admission, prove record-derived private sample declarations cannot collide with real scheduler/drive/spawn/counter helpers or share an unsound alias across transaction/rule owners. Derive actual producer/module facts rather than guessed prefixes. Qualify collision negatives, deterministic private type reuse, no inherited metadata and strict actual IAL0 replay for prepared carriers. Preserve source refusal and ordinary products; broad replay/timing qualification remains .3.3.3. P2 owned prerequisite: T1993 fresh copied actors show metadata width strings become JSON numbers after refused actual drive/spawn carrier lowering. ISFInterfacePortMetadata validates borrowed capture/snapshot widths numerically before rebuilding output; prior post-validation baselines miss first-touch mutation. Reproduce direct capture/snapshot and invalid-input controls before repair, detach caller facts before validation, and qualify complete source/output isolation without changing normalized metadata products.`
  Verification: `T1993 derives actual drive request/payload, dynamic wait-counter and spawn handoff names/roles/declarations from ordinary production modules. Prepared record samples cannot collide with these helpers, share record/ordinary transaction owners or accept other transaction/rule writers. Same-owner repeats share one private type; unused samples remain internal, and identical alias spellings in separate parent/generated-child modules strictly replay independently. Isolated removal of transaction collision, multiple-record-owner and module ownership predicates makes those permanent negatives RED while distinct-module positives pass. No ownership production change was needed. T1993 first-touch copied actors expose metadata scalar-kind mutation on refused drive/spawn routes; direct snapshot turns caller width string into number, independently of helper logic. New T1983 valid/refused nested-layout controls go RED before repair. Interface metadata capture and snapshot now clone containers before numeric reads; normalized numeric outputs remain exact and complete caller JSON stays unchanged, including malformed suffixes and independent output edits. The existing standalone Perl numeric-read witness reproduces the mechanism. Guarded T1993/T1983/T1984/T1985/T1992/T1991/T1990/T1989/T1988/T1987/T1986/T1100/T1111/T1195/T1259/T1391/T1938/T1945 reports All tests successful, Files=18, Tests=103. Syntax and mdBook build pass; current complete native/API/newline reports, source refusal and ordinary sample/formal products remain qualified. Decision 0114, map, inventory and exact book authority accompany the slice. Carrier parent .2 closes; complete replay/timing .3.3.3 is next. No native HDL execution or authored record admission is claimed.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.3.3`
  Status: `done`
  Goal: `Qualify sample replay and existing capture timing before record source admission.`
  Acceptance: `After .2, independently strict-replay typed IAL0 carriers and compare complete actual entry/body/nested states, widths, signed/state facts, source identity and unchanged ordinary products. Cover local/imported/nested and nearest shadow controls, alias/type collisions, malformed/whole record failures and generated/domain preparatory routes within their existing bounds. No native HDL execution before the separately owned HIAL prerequisite. Close sampling only with synchronized book/decision/task evidence; actual authored source and runtime signoff remain later owners.`
  Verification: `T1994 compares complete actual states against admitted scalar-source states after only deliberate sample-source substitution, including retained control ASTs, capture assignments, guards and transitions. Entry, await/drive piggybacks, pre-data and when/while/until/repeat/switch controls preserve existing capture structure. Actual strict --emit-semantic-json replay retains exact independent signed four-state bits and two-state bit specs in symbol types and private structural nets, actual source identity and no alias pins. Real imported package, nearest renamed scalar formal, whole/invalid/masked refusals and complete caller JSON pass. An isolated LoweringIR copy deletes only packet-derived _ir_on capture guards; complete entry/imported states and literal entry guard go RED while semantic/type replay remains green, proving distinct oracles are needed. Guarded T1994/T1993/T1992/T1991/T1990/T1989/T1988/T1987/T1986/T1983/T1100/T1111/T1195/T1259/T1391 reports All tests successful, Files=15, Tests=87. Test syntax and mdBook build pass; synchronized decision, map, inventory, exact book authority and staged doctrines accompany qualification. Draft fixtures were corrected to admitted scalar sampling, actual entry assignment selection and retained control AST source substitution; no production defect or code change was required. No authored record admission, native HDL execution or complete backend/consumer delivery is claimed.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.4`
  Status: `done`
  Goal: `Qualify declared domain roots before record-input admission.`
  Acceptance: `Resolve selected member/item/scalar-slice paths to actual declared actor/formal roots for domain ownership. Reproduce and repair any existing prerequisite defects with public before/after controls and exact lexical masking; refuse unowned read/write crossings, preserve authored diagnostics, unrelated enum/package names and declared crossings. Qualify existing scalar/storage/domain facade/replay controls before new record source admission.`
  Verification: `Children .1-.3 qualify scalar/input slice ownership, record/formal nested roots and actual domain drive selection. Existing inline-first-assignment and used named-body read/write bypasses are repaired with exact public diagnostics. Independent domain sources now retain only validated used definitions, preserving generated calls while omitting unused request/payload helpers. Exact original scalar-only strict source, actual domain/top/generated replay and complete public products pass; formal, source-owner, historical schedule and crossing controls remain qualified. Authored record admission remains .3.5; no native HDL execution is claimed.`
  Commit: `this commit`


  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.4.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.4.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.4.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.4.1`
  Status: `done`
  Goal: `P1: repair existing foreign-domain scalar slice and input-index admission bypasses.`
  Acceptance: `At pre-repair 02827d840, public parse/lower rejects record_value.payload and foreign data but accepts record_value.payload[3:0], scalar[3:0], data[3:0] and data[0]. Reproduce those exact declared ownership failures, repair the domain root/path classifier with real lexical scope, and permanently reject them before carrier emission. Preserve same-domain slices, local/formal shadows, unrelated enum/package constants and declared crossings; use first-diagnostic-line negative oracles, complete native/API/newline products, IAL0 replay and current scalar/storage/domain baselines. This source-validation repair needs no native HDL replay or new record-port admission.`
  Verification: `T1920 first reports empty diagnostics for foreign member/storage scalar slices and input slice/bit-index reads, proving the admission bypass. Domain lookup now recognizes colon ranges and selects nearest declared roots for indexed references; dotted storage/enum/package classification is preserved. Exact first-line controls include nested list/member slices, reversed/single-bit ranges, same-domain values and generated formal shadows. The same public pre-repair probe now rejects every foreign case. Guarded T1920/T1247/T1259 and complete T1985/T1982/T1986 qualification report All tests successful: native/API/newline check/semantic diagnostics are independently exact, schedule failures retain no partial product and source bytes are unchanged; complete historical domain reports, actual IAL0 files and SystemVerilog/Verilog HDL except date remain identical. The book gap is replaced by qualified current behavior. No native HDL execution or record-source admission is claimed.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.4.2`
  Status: `done`
  Goal: `Prepare record/formal path-domain ownership before input admission.`
  Acceptance: `After the existing-path repair and scoped contextual gates, retain actual declared record/input/formal roots across nested member/list/scalar-slice paths. Preserve nearest lexical bindings, owned-domain selection, enum/package namespaces and explicit crossings. Qualify preparatory public lowering actors and unchanged admitted sources before first authored record-input admission, with actual authored-source confirmation in .3.5-.3.6 and carrier/runtime qualification under .2.4-.2.5.`
  Verification: `T1995 proves supplied foreign record input nested members, scalar/reversed/single-bit slices, list leaves, control/rule/drive reads and entry/body samples lose domain refusal at 8698b1a897752036b875c27336306582665dc4e3. Resolved record roots now join storage member ownership while scalar enum/package namespaces remain delegated and nearest formals keep local domains. Complete caller JSON, actual imported aliases, independently valid scalar contexts, same-domain copies/reads, domain snapshots and strict replay of every domain/top carrier pass. A forced scalar-pin record_root predicate falsely refuses valid mode.ON, proving the namespace witness. The remaining inline control exposes an existing P1 first-assignment omission; ordinary scalar-only probes also prove used named-drive bodies lack ownership validation. T1920 exact storage read/write controls go RED before repair. Inline validation now matches emitted assignment boundaries; used named bodies validate targets/expressions in activation-site domains with parameter masks. T1985 adds complete native/API/newline check/semantic diagnostic parity, schedule transport refusal, no successful metadata/partial schedules and unchanged bytes. Guarded T1995/T1920/T1247/T1982/T1985/T1989/T1992/T1994/T1936/T1945/T1387 reports All tests successful, Files=11, Tests=87. Syntax and mdBook pass; exact book/reference authorities, decision/map/inventory and staged doctrines accompany the slice. Positive draft width and metadata-shape mistakes were corrected from actual native diagnostics/contracts. A separate ordinary unused-drive top width conflict is P2-owned by .4.3 immediately next before record admission; it is not hidden as a fixture error. Source records still refuse; no native HDL execution or full record delivery is claimed.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.4.3`
  Status: `done`
  Goal: `P2: repair unused named-drive parameter leakage across independent domains.`
  Acceptance: `Immediately after .2 and before authored record input admission, reproduce and repair actual domain source/helper selection for named drives without inventing private top inputs. Ordinary admitted source with core/aux domains, seen width 8, unused drive publish(value) assigning seen, and main setting seen=data strictly fails: core.publish_value width 8 disagrees with aux.publish_value width 1, blocking top inference. Retain that exact source and original strict diagnostic, determine the responsible producer, preserve used drive calls/parameters and lexical masking, qualify complete domain/top carriers and unchanged public reports. Own any broader unused-drive helper/width cases discovered and avoid changing submodules or native runtime prerequisites.`
  Verification: `At pre-repair 68880895fc4635f04b631f705ad548a600bddb3f, complete T1996 is RED: every definition appears in both domains and unused helper widths break strict top replay. DomainSource inherits all bodies; _build_drive_dts creates helpers and _drive_param_width defaults to one without the foreign target. The private partition now retains its existing validated activation-site selection, and actual/formal domain sources clone only selected definitions. Literal independent body sets, absent unused/foreign helpers, nested and generated calls, caller isolation, closed malformed selection and strict every-carrier replay pass. Complete native/API/actual newline check/semantic/schedule products agree with unchanged bytes. Exact original scalar source now reports strict success. A drop-all-definitions mutant terminates on used publish not defined, independently proving retention. Final T1996 reports All tests successful, Files=1, Tests=4; formal/domain/source-owner/schedule/crossing cohort reports Files=8, Tests=59. Earlier formal/reservation/partition/historical-domain cohort passed Files=5, Tests=28. Syntax and book build pass; exact reference authorities, decision/map/inventory and staged gates accompany the repair. One aggregate attempt was RAM-guard terminated at 91.4% host use, exit 137, with no suite verdict; completed reruns use unchanged cutoff. Initial dynamic transport fixture was corrected to the established capture protocol. No native HDL execution or record source admission is claimed.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.5`
  Status: `done`
  Goal: `Admit the bounded record-input source surface with every mandatory gate.`
  Acceptance: `After .2-.4, admit local/imported packed record input aliases only with complete contextual scalar/copy/role/type/domain/sampling checks from the first accepted source. Preserve root-list/output/transaction aggregate refusals, explicit IAL0 typed interfaces and unused declarations; qualify invalid types/paths/operators/whole-record scalar contexts and same-type input-to-owned-storage copies. Keep unsupported carrier/backend contexts fail closed and synchronize actual authoring behavior in book/spec.`
  Verification: `Gate integration .1 and bounded authored admission .2 are qualified separately. Every admitted source consumes the complete contextual, role/type/copy/domain/sample gates; strict native source/carrier and complete public/corpus products pass. Frontend matrix .3.6 and generated/domain/native completion retain their owners.`
  Commit: `children qualified through this commit`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.5.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.5.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.5.1`
  Status: `done`
  Goal: `Integrate qualified record-input gates before authored admission.`
  Acceptance: `Connect the existing detached contextual/sample/role/type gates to the actual parser and shared module-source preparation boundaries. Use the canonical nearest declaration projection for record-bearing enum exclusions and rule operands; preserve the existing storage-only aggregate grammar and all nonrecord behavior. Qualify actual parser phase order using supplied finalized record facts, actual formal/executable module admission, precise failures, nearest masks and complete caller isolation. Keep authored aggregate-port refusal intact; source admission remains .2 and native/runtime/carrier completion keeps its prior owners.`
  Verification: `At 6f7b30bb4498f3ab13f294fae6a209342a4ef4c4, corrected full T1997 fails parser namespace and formal/executable admission controls. Record-input actors now consume the existing contextual gate at resolved parser phases and shared module source preparation. Canonical nearest projections supply record-bearing enum exclusions and actor rule declarations; existing storage-only path grammar and nonrecord projections remain. T1997 supplies finalized facts at the actual type-finalization boundary without replacing validators, proves independent layout metadata, scalar/formal/drive masks, input roles, copies and precise failures, and preserves complete caller JSON at formal/executable entry. An isolated omission of only the shared gate makes module admission subtest 3 RED while parser and source-refusal controls pass. Final preparation/domain/sample/storage cohort reports All tests successful, Files=13, Tests=77; complete native/API/actual newline, historical schedules and scalar sampling cohort reports Files=5, Tests=21. Producer/test syntax and final book build pass. An earlier book attempt was RAM-guard terminated at 89.7% host usage, exit 137; no success is inferred from it, and the completed build uses the unchanged cutoff. The initial test fixture used invalid unparenthesized drive formals and fatal metadata capture; both are corrected from exact parser/TAP diagnostics, without product changes. Exact book authority, bounded 0113 integration record, map/inventory and staged gates accompany the slice. Authored record ports still refuse; admission .5.2 is next, and native/runtime/full carrier/consumer completion remains separately owned.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.5.2`
  Status: `done`
  Goal: `Admit local/imported packed record inputs only through integrated gates.`
  Acceptance: `After .1, admit the selected actor record-input aliases with all mandatory contextual/domain/sample/role/copy/type checks. Permanently qualify actual authored local/imported/nested/unused inputs, scalar leaves, strict same-type input-to-owned-storage copies and typed IAL0 replay. Preserve output/list-root/transaction aggregate refusal and invalid declaration/path/operator/context/input-write failures. Keep unsupported integration/backend carriers precise and fail closed, then synchronize actual authoring book/spec before frontend/public qualification .3.6.`
  Verification: `At predecessor 0d01ca3fc8f880acf926ae59305843a1172bf1d3, actual local/imported inputs fail T1998 at resolved interface aggregate refusal. Record-kind-only actor input admission now passes authored nested/unused/copy/leaf/slice/sample/rule/drive/generated sources with independent exact metadata, complete caller isolation and strict source/every-carrier replay. First-cause type/path/role/context/copy/domain negatives and deferred output/list/transaction carriers remain closed. Generated scalar outputs require published explicit bindings; record and ordinary unbound controls refuse alike. Final focused preparation/sample/domain/storage/historical cohort reports All tests successful, Files=16, Tests=89. Complete native/API/actual newline/discovery T1985 reports Files=1, Tests=6; current corpus/source cohort reports Files=2, Tests=7201. Catalog omission control exits 2 on literal supported 385 versus 386 and strict 375 versus 376. Syntax and book build pass. Initial width and unbound-child fixtures were corrected to existing strict contracts, without product repairs. An 88.2% host RAM cutoff exits 137 without a verdict; final completed runs keep the unchanged cutoff. Two aggregate attempts used nonexistent test basenames and have no suite verdict; final paths were enumerated with rg. Shipped record_input source, book/spec/fixture list, bounded 0113 admission update, exact reference authority, map/inventory and staged gates accompany the slice. No native execution or complete backend/consumer signoff is claimed; .3.6 then .2.4-.2.5 remain owned.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.6`
  Status: `done`
  Goal: `Qualify frontend delivery and public replay before carrier/runtime completion.`
  Acceptance: `After .5, independently verify accepted local/imported/nested/shadow sources, all contextual failures, exact metadata/type/layout identities and complete native/API/actual newline check/semantic/schedule/discovery products. Strict-replay every emitted IAL0 carrier; preserve pre-change scalar/storage controls and exact source provenance. Close frontend work only with synchronized references while generated/domain behavior and independent native completion remain separately owned by .2.4-.2.5.`
  Verification: `Accepted nested/import/nearest-shadow public sources and imported local type dependencies are qualified under .1. Contextual public refusal matrix .2 and its scalar-parameter repair are qualified; prior-control/discovery closure .3 and JSON-copy purity child are qualified. Complete frontend closes; generated/domain/backend/native/consumer completion remains separately owned.`
  Commit: `children completed through .3.1 in this commit`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.6.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.6.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.6.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.6.1`
  Status: `done`
  Goal: `Qualify actual accepted record-input frontend sources and complete public products.`
  Acceptance: `Exercise independently authored local/imported/nested/forward-alias and nearest scalar formal/drive-shadow sources through actual parser/lowerer and native/API/newline check/semantic/schedule products. Require literal complete declaration/layout/type witnesses, exact source/import preservation, complete typed transport equality and strict replay of every emitted carrier. Keep generated/domain/native execution and consumer completion separate. Record any discovered actual defect before repairing it; update relevant book/feedback/frontiers and commit this accepted-source proof before the negative matrix.`
  Verification: `T2014 qualifies all authored accepted nested/local/imported/forward/shadow/unused sources through complete native/API/newline check/semantic/schedule products with literal full recursive types/layouts, exact source/package preservation and every-carrier strict replay. Child .1 repairs imported local alias resolution, stale scalar oracle and book wording; T2015 and existing public/scalar/storage/core/book controls qualify its compatibility. Negative matrix .6.2 is next; full frontend and generated/domain/native/consumer closure remain open.`
  Commit: `completed through child .1 in this commit`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.6.1.1`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.6.1.1`
  Status: `done`
  Goal: `Repair ISF local type aliases resolving before their imported dependencies.`
  Acceptance: `Reproduce an actual imported shared.frame declaration that succeeds directly but fails when referenced by an actor-local alias; trace the actor symbol finalization and compare the existing public core imported-alias contract. Seed local resolution from resolved imported type facts through existing package machinery, preserving local forward aliases, metadata and embedded package roots. Qualify scalar and nested aggregate aliases/imported members, unknown-import/type refusals, complete public accepted-source products and strict carriers plus focused old scalar/storage/core type gates. Maintain a supported corpus imported-alias case with independent public witnesses. Log and correct the test runner's catalog-only source-id mismatch and stale book storage-only wording; no public transport policy relaxation. Commit the qualified repair before the negative frontend matrix.`
  Verification: `Actual pre-repair T2014 fails only imported_local_alias after correcting the catalog-runner fixture mismatch. Resolving packages first and seeding qualified temporary type lookup repairs local aliases/nested imported members without leaking imported names into local tables. T2014/T2015 pass full accepted-source and focused dependency controls; maintained record_input corpus now exercises the imported alias. The complete clean d9 predecessor reproduces T1257 raw-formal regex failure with other scalar controls passing; corrected private-name oracle passes. Canonical facts/book/feedback retain scoped runtime/negative-matrix limits. See fresh acceptance below.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.6.2`
  Status: `done`
  Goal: `Qualify contextual record-input refusals across all public frontend routes.`
  Acceptance: `After .1, exercise the complete reviewed contextual/type/path/role/unsupported-carrier and nearest-shadow failure matrix through native/API/actual newline check/semantic and schedule refusal. Independently expect diagnostics, no partial successful declarations/schedule/HDL, exact source/import preservation and complete failure transport products. Fix and separately own discovered defects before closing this slice; synchronize references and commit.`
  Verification: `T2016 qualifies the complete authored contextual/type/path/role/shadow/unsupported-carrier failure matrix through native/API/actual newline check/semantic and schedule routes, with independently expected first causes, no partial successful products, complete typed transport equality and exact source/import preservation. Child .1 repairs scalar-parameter direct/indexed member admission. Final combined T2014/T2015/T2016 passes All tests successful, Files=3, Tests=42; frontend prior-control/discovery closure remains .3.`
  Commit: `completed through child .1 in this commit`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.6.2.1`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.6.2.1`
  Status: `done`
  Goal: `Repair masked scalar drive-parameter member validation before public product publication.`
  Acceptance: `Reproduce a drive parameter named packet masking an actor record input, called with declared one-bit input start, whose body reads packet.payload.data. The first scalar-width-five probe fails check/semantic for a width mismatch while schedule preview succeeds. The width-aligned start-bit probe incorrectly succeeds on all native/API/newline check/semantic/schedule routes. Trace scalar-only drive parameter facts and existing scope/context contracts; retain width/type uncertainty without borrowing outer record facts, preserve valid scalar arguments/slices and enum/package namespaces, and refuse invalid masked member access before successful scheduling. Qualify deterministic root controls and complete public refusal/accepted matrices plus focused scope/context/legacy regressions. Log any ordinary-source variants or dependency gaps before repairs, synchronize book/facts/feedback and commit the complete qualification.`
  Verification: `Corrected pre-product T2016 RED completes Files=1, Tests=27, failing only drive_parameter_member: aligned start-bit actual succeeds on all check/semantic/schedule routes, while the other cases refuse. The earlier five-bit actual fails check/semantic only for an unrelated width mismatch. The first draft also assumes nonnullable diagnostic codes, schedule exit one and contextual API schedule messages, contrary to the existing nullable-code, arbitrary nonzero exit and generic message-only contracts; correct those test expectations separately from the genuine schedule gap. The scope correctly masks the outer record with type_spec undef, but the context then delegates dotted parameter paths without using the scalar-only drive contract. The private scalar-only context marker now rejects direct/indexed/sliced member paths without type borrowing; final full public and focused scope/context/module controls pass. See fresh acceptance below.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.6.3`
  Status: `done`
  Goal: `Close frontend qualification with prior controls, discovery and exact handoff.`
  Acceptance: `After .1-.2, compare complete pre-admission scalar/storage public products and scheduled carriers with narrowly declared source/date/reset-origin differences. Qualify full native/API/newline discovery and current supported corpus applicability, reconcile exact positive/negative/strict-replay evidence, run focused combined gates and synchronize canonical record/book/feedback/frontiers. Close frontend only; generated/domain/backend/native and consumer completion remain .2.4-.2.5. Commit a clean handoff without claiming omitted external/runtime legs.`
  Verification: `Accepted and refused public matrices are qualified through .1-.2. T1981/T1982 own complete preserved scalar/storage products and actual carriers/HDL under declared access/domain/interface/date differences; T1985 owns current supported-source joins and public discovery. Reuse those finite controls and add T2017 for complete all-section native/API/newline discovery plus the unchanged supplied aggregate-intake sources: current whole-copy/field-guard admission with literal types/layouts, exact baseline check/semantic/schedule equality after only independently qualified declaration metadata, actual strict carrier replay and source/receipt preservation. Confirm full discovery applicability and preserve fixed historical evidence and later carrier/runtime owners. P3-owned doc defect: isf-aggregate-port-request-baseline.md describes captured storage-only admission in present tense despite source admission 25c01f0127144922ade78951b91439e1d9221c08; its offline verifier proves historical receipt only. Restate dated scope and route the live answer to qualified record-input products before closure. A stale guessed T1985 read basename failed; file enumeration resolves t/1985-isf-interface-port-public-qualification.t, with no source mutation or result inferred from the failed read.`
  Commit: `completed through child .1 in this commit`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.6.3.1`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.6.3.1`
  Status: `done`
  Goal: `Resolve numeric JSON kinds changing across public path sanitization and its test oracle.`
  Acceptance: `P1 qualification defect: T2017 exact historical baseline comparison fails check/semantic/schedule for string-versus-number kinds only, while transport parity passes after the current helper. Independently inspect untouched native JSON and actual API/newline products, trace primitive scalar flags through report admission/sanitization and test normalization, and identify every observed responsible boundary before mutation. Preserve numeric/string/boolean/null kinds and complete caller input while applying only authorized path substitutions/redactions. Add root first-touch controls and actual transport typed witnesses, retain original strict historical comparison and all path/diagnostic/VIAL contracts, repair qualified boundaries and rerun focused public/closure cohorts. Audit and own any historical typed-parity claims whose oracle erased distinctions; preserve dated receipts and correct current evidence limits. Do not classify or relax this foundational discrepancy without a verified root repair.`
  Verification: `Initial T2017 completes Files=1, Tests=5, failing baseline-good only. Independently parsed diagnostic products differ solely in JSON primitive kinds: check 5, semantic 155, schedule 8 differences; no key/value/layout changes. Production _sanitize_public_payload applies scalar path processing to every nonreference value; test normalize_repository_paths stringifies each scalar before returning it. Untouched native and actual API probes retain numeric kinds. Independent stage probes show raw and raw-clone retain integers; normalized/sanitized JSON remains numeric, but cloning either projection changes selected numbers into strings, even after encoding. The first fresh-literal root controls pass serialized equality and therefore do not falsify copy stability; expanded post-projection copy controls precede product mutation. Existing scalar/storage/discovery/corpus cohort passes Files=4, Tests=7211 but is not strict detached-copy qualification.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4`
  Status: `done`
  Goal: `Qualify generated and named-domain record-input carriers.`
  Acceptance: `After .3, independently exercise live record reads and valid input-to-storage transfers through existing generated-child/domain ownership, including nested/imported aliases, reused instances and unused declarations. Preserve explicit top interfaces, typed private connections, reset/storage ownership and unchanged old sources; refuse unowned crossing and unqualified input targets. Split actual prerequisite fixes before mutation and retain backend-profile boundaries.`
  Verification: `Full authored local/imported nested ordinary/domain sources retain reused readers, sole whole input-to-owned-storage spawn/do writers and unused declarations. Complete literal recursive types/layouts/roles/endpoints, exact explicit top/typed child carriers, reset/storage/domain ownership and every actual strict replay are qualified. Embedded package context, scalar selector identity and binding-formal identity prerequisites are repaired with exact predecessor falsification. Complete typed native/API/newline accepted/refused products, prior scalar/storage report/carrier/HDL controls, full discovery/current cohort/fixed catalog and source/package/caller/named producer purity reconcile through .1-.2. Final Files=3, Tests=7217 and Files=7, Tests=32 pass. Generated/domain source/carrier/public qualification closes; backend/native behavior and consumer completion remain .2.5.`
  Commit: `completed through .2.3.2 in this commit`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4.1`
  Status: `done`
  Goal: `Qualify actual generated record-input carriers and domain ownership.`
  Acceptance: `Use authored local and imported nested record inputs, reused generated readers, unused declarations and input-to-storage transfers through ordinary and named-domain lowering. Independently assert complete resolved types, explicit top interfaces, typed child connections, instance bindings, storage/reset ownership and complete caller purity; strictly replay every actual carrier. Retain scalar/storage controls and root all discrepancies before repair. No native HDL execution or backend completion is claimed.`
  Verification: `Completed through owned prerequisite child .1.1: actual authored local/imported ordinary/domain reused readers, unused inputs, sole generated spawn/do whole copies and maintained imported example retain exact literal types/layouts, complete child/top roles and endpoints, artifact membership, register/reset ownership and caller/source/package purity. Every actual carrier strictly replays. Complete generated/domain transport/refusal closure remains .2; static carrier/reset structure does not qualify HDL execution.`
  Commit: `completed through child .1.1 in this commit`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4.1.1`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4.1.1`
  Status: `done`
  Goal: `Retain embedded package context when realizing generated composition children.`
  Acceptance: `P1 authored carrier defect: local aliases to imported record inputs lower, and individual parent/child artifacts strictly replay, but the ordinary generated top refuses when its embedded modules import shared. Trace actual authored and isolated carrier checks to the responsible handoff before repair. Emitted top already contains package roots; GeneratedChildRealizer selects only the child AST and create_fsm_module can no longer collect sibling packages. Preserve the composition's detached package context for embedded FSM/DT children only, through the existing frontend and resolver. Keep external-source package locality, exact imported type spelling, caller purity, prior local/domain/scalar/storage products and independent hostile controls. No external repo or submodule access, profile widening or native runtime.`
  Verification: `Exact 9aaa27bbb7c072dab52b486b64f93309e55cfa99 realizer source with final T2020 fails embedded FSM/DT positives only; missing/undeclared import and external local-package controls pass. Corrected T2019/T2020 final carrier matrix reports All tests successful, Files=2, Tests=10. Detaching sibling packages into the existing embedded child frontend repairs ordinary imported top replay without changing emitted carrier bytes or external dependency lookup. Final prior-domain/storage controls Files=4, Tests=20, realizer/frontend/package controls Files=5, Tests=15 and maintained native/API/newline/corpus/book controls Files=3, Tests=7216 pass. Durable acceptance below distinguishes draft setup/oracle failures and exact catalog addition.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4.2`
  Status: `done`
  Goal: `Close generated/domain record-input public and refusal qualification.`
  Acceptance: `After .1, compare complete actual native/API/newline check/semantic/schedule products and source preservation for generated/domain sources. Preserve fixed older scalar/storage products and complete carrier controls; qualify foreign reads/copies, input targets and nearest scalar declarations with first-cause diagnostics. Reconcile all generated/domain ownership and carrier evidence, book and canonical feedback before backend/native/consumer .2.5; split prerequisite repairs before mutation.`
  Verification: `Accepted complete typed native/API/newline generated/domain products and literal recursive HIR/structural/clock/reset/physical ports are qualified under .1; contextual refusals/scalar shadows and selector/binding identity repairs under .2; exact typed prior scalar/storage, complete current declaration cohort/all-section discovery/fixed catalog under .3. Every actual carrier strictly replays, sources/imports/caller/public producer bytes remain, and later-C2 intent preview retains its precise boundary. Final gates Files=3, Tests=7217 and Files=7, Tests=32 pass. Source/carrier/public closure only; no new HDL execution or external consumer signoff.`
  Commit: `completed through .3 in this commit`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4.2.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4.2.1`
  Status: `done`
  Goal: `Qualify complete accepted generated/domain record-input public products.`
  Acceptance: `Extend the authored carrier witnesses with actual native/API/newline check/semantic/schedule queries, complete typed product equality, literal declarations/domain snapshots, exact physical top pins and recursive typed child HIR/structural ports. Preserve imports, sources, public producers and caller facts. Keep outer vector-port representation distinct from authored record metadata and typed module declarations; no new schema or runtime claim. Independently reject shared corrupted ownership/type/layout projections before public closure.`
  Verification: `Final T2019 reports All tests successful, Files=1, Tests=8 for all authored generated/domain and maintained sources over actual native/API/newline check/semantic/schedule products. Complete typed equality, literal declarations/ranges/domain snapshots, exact physical top pins and ordered instances, recursive child HIR/structural/private writer types, authored clock/reset contracts/provenance, source/package/public producer bytes and caller purity pass. Shared corrupted ownership/type/layout projections fail independent literals despite parity. Ordinary domain:null expectation is corrected against the unchanged closed schema. Prior T2018/T2017/T2020 controls Files=3, Tests=12, runnable T1376 Files=1, Tests=2, book build and KM pass. Contextual refusals .2 are next; final prior/discovery closure remains .3.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4.2.2`
  Status: `done`
  Goal: `Qualify generated/domain contextual record-input refusals and scalar shadows.`
  Acceptance: `Use actual authored generated/domain sources to refuse unowned nested/sliced reads, whole copies and input targets with independent contextual causes and complete native/API/newline failure products. Preserve nearest scalar formal/local/drive identities, explicit child bindings and unsupported writer/aggregate boundaries. Contextual refusals yield no declarations, schedule, semantic or HDL success; later C2 wiring refusals retain the documented pre-HDL intent preview. Exact source/import bytes remain. Own any prerequisite defect before mutation.`
  Verification: `Final guarded T2021/T2023 reports All tests successful, Files=2, Tests=14. Complete typed native/API/newline contextual failures and admitted direct/generated scalar shadows, exact carrier/semantic identities, source/package/public producer bytes and caller purity pass. Scalar-selector .1 and binding-identity .2 are repaired and independently falsified against exact committed predecessors. Later unbound C2 output retains only its documented complete intent preview; strict check/semantic refuse. Record binding actuals, input targets, aggregate formals and unsupported writers remain closed. Focused binding/scope/JSON-kind controls Files=6, Tests=267; accepted carriers/selectors Files=2, Tests=12; late malformed numeric/null purity Files=2, Tests=10; runnable book Files=1, Tests=2 and KM pass. Exact prior/discovery closure .3 is next.`
  Commit: `completed through child .2 in this commit`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4.2.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4.2.2.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4.2.3`
  Status: `done`
  Goal: `Close generated/domain record-input qualification with exact prior controls.`
  Acceptance: `After accepted/refused matrices, requalify complete fixed prior scalar/storage products and carrier/HDL controls under narrowly declared differences, complete discovery/current supported applicability and final combined focused gates. Reconcile every .2.4 acceptance requirement, exact caller/import/type/ownership evidence and canonical feedback/book/Knowledge Map pointers. Close generated/domain frontend/carriers only and resume backend/native/consumer .2.5 with HIAL admission before genuine HDL execution.`
  Verification: `Completed through children .1-.2: fixed scalar/storage prior JSON-kind relocation/comparisons are qualified, then the complete current declaration-cohort omission is repaired without dropping its guard. Final native/API/newline/discovery/supplied-source/current catalog T1985/T2017/T248 passes Files=3, Tests=7217; final typed storage/copy/package/selector/binding/book focused gate passes Files=7, Tests=32. Immutable report/carrier/HDL baselines, metadata/source/date permissions, caller/source/import/producer bytes and prior contextual/accepted receipts remain. Every .2.4 requirement reconciles in final acceptance; generated/domain source/carrier/public closure is complete, backend/native/consumer remains .2.5.`
  Commit: `completed through child .2 in this commit`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4.2.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4.2.3.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4.2.3.1`
  Status: `done`
  Goal: `Preserve JSON kinds in fixed prior storage-report qualification.`
  Acceptance: `P2 qualification defect: T1981 relocate stringifies nonreference expected scalars and older T1981/T1982 is_deeply public/baseline comparisons do not distinguish JSON numbers from strings. Root fresh decoded literal and full typed expected/native differences, preserve immutable receipts and exact prior permissions, then repair only oracle relocation and strengthen complete typed native/API/newline/declaration/baseline comparisons. Retain primitive/copy/caller witnesses and exact named producer/source/baseline bytes, complete unchanged FSM/HDL controls and scoped historical evidence limits. Complete-cohort discovery omission is separately owned .3.2; parent .3/.2.4 closures wait for that qualification.`
  Verification: `Pre-repair typed T1981/T1982 is RED, Files=2, Tests=11: only T1981 literal/copy and fixed expected report comparisons fail; domain typed controls pass. Exact committed predecessor helper still converts numbers to strings after authorized path-only relocation. Repaired separate-scalar inspection returns untouched values unless text changes. Final T1981/T1982/T2018 reports All tests successful, Files=3, Tests=17, preserving complete JSON kinds and named producer/immutable baseline/source bytes, full prior reports/carriers and both emitted HDL targets. Book audit Files=1, Tests=2, book build and KM pass. Untouched T1985/T2017/T248 cohort Files=3, Tests=7216 is FAIL solely for missing generated catalog declaration witness; .3.2 owns it and parent closure remains active.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4.2.3.2`
  Status: `done`
  Goal: `Keep public declaration witnesses complete for the generated record-input catalog source.`
  Acceptance: `P2 discovery qualification omission: the admitted maintained isf/record_input_children.isf catalog row joins the live ISF source-query cohort, but T1985's independent supported-source declaration table omits it. Current T1985 membership and complete literal metadata checks are RED. Preserve the complete-cohort guard; add independent literal authored packet/unused types, ordered packed ranges, domains, ports and widths for that actual maintained source, with full native/API/newline products/source/package preservation. Qualify the complete fixed catalog and prior controls, then reconcile and close generated/domain .2.4. Do not weaken or drop the row/guard or rewrite original catalog evidence. Finish the separate .3.1 typed storage-oracle repair and commit clean before this slice.`
  Verification: `Exact omitted live cohort membership and typed declarations are RED at T1985 line 52/219. git log -S identifies the maintained source/catalog addition in 24a58de05d1bf72dc1c0bd26c0d48a3906bb3bbc with no T1985 table update. Independent literal source/package-derived input/output order, packed ranges, signed/state/type properties and domains now join the complete table; the guard remains unchanged. Final T1985/T2017/T248 reports All tests successful, Files=3, Tests=7217 with all current source-query applicability, complete typed native/API/newline products/all-section discovery and fixed catalog. Final focused T1981/T1982/T2018/T2020/T2022/T2023/T1376 passes Files=7, Tests=32. Exact source/package/named producer bytes remain. Existing full authored T2019 and contextual T2021 receipts at unchanged production source remain qualified; parent source/carrier/public closure reconciles below, native/backend/consumer stays .2.5.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4.2.2.1`
  Status: `done`
  Goal: `Preserve scalar named-drive parameter identity through bit/slice lowering.`
  Acceptance: `P1 prerequisite: a width-qualified scalar drive parameter masks a foreign outer record during contextual/domain validation, but _substitute_named_drive_body_expr replaces only bare parameter names. An authored packet[3:0] remains the outer spelling instead of publish_packet[3:0]; actual strict native domain check refuses an unintended core.packet port. Root the selector handoff and relevant history, retain immutable predecessor falsification, then rewrite only admitted static scalar selectors on declared drive parameter roots. Preserve parameter width ownership, scalar member refusals, unrelated namespaces/declarations, nested expression/caller facts, generated/domain invocation and all full public error/success products. Close parent refusal qualification only after its matrix passes. No runtime or broader writer/profile admission.`
  Verification: `Final T2021/T2022 passes All tests successful, Files=2, Tests=11. Static scalar selectors and nested expressions retain declared private drive roots, source/caller/producer bytes and existing width ownership; ordinary/domain/generated sources strictly check and emit semantics. Exact aebe0037554eb9995c1d4fa67f4ec53f98364520 helper is RED only for the independent selector literals. Complete contextual native/API/newline refusals and admitted direct scalar controls pass; later C2 binding failures retain the documented pre-HDL schedule preview. Focused old drive/domain/public failures Files=4, Tests=38; scope/JSON kinds Files=3, Tests=21; accepted T2019 Files=1, Tests=8; actual lisp-fenced book audit Files=1, Tests=2 and final book build pass. Parent closure remains active for owned binding-name P1 .2.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4.2.2.2`
  Status: `done`
  Goal: `Keep generated binding formal identities out of actor record-read scanning.`
  Acceptance: `P1 qualification defect: an actual generated worker with scalar input packet width 3 and explicit caller binding (input packet scalar[2:0]) falsely refuses because ISFRecordPortContexts recursively treats the callee formal name as an actor record value. Reproduce the actual authored public refusal, trace the unsupported-context scan and declared binding grammar before mutation, then retain identity positions separately from actual value positions without admitting unqualified record actuals or aggregate formals. Qualify generated scalar shadows, exact private ports/bindings, actual strict carriers and complete native/API/newline products with hostile actual-record reads and caller purity. Finish .1's selector commit first; close parent .2 only after this repair and matrix qualification.`
  Verification: `Calibrated actual native --strict --check --json first reproduces identity-as-record-read refusal; corrected T2023 is RED only for identity positions while scalar-only activation controls and actual record-value refusals pass. Role-directed activation scanning preserves actual value/profile gates and existing complete grammar/width/timing/domain admission. Exact 85b6fdfb460d93b632be9bfa3da880da83b9d3c8 module capsule remains RED for formal/output/target/instance/static metadata identities with scalar/record-actual controls passing. Final T2021/T2023 Files=2, Tests=14 PASS; late numeric/null malformed purity plus T2018 Files=2, Tests=10 PASS. Literal generated private handoffs, public scalar child HIR/structural ports and all actual strict carriers/full native/API/newline products pass. Prior binding/scope/JSON controls Files=6, Tests=267, accepted T2019/T2022 Files=2, Tests=12, runnable book Files=1, Tests=2, book build and KM pass. Parent .2 closes; next exact prior/discovery .3.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5`
  Status: `done`
  Goal: `Qualify packed input behavior and complete public delivery.`
  Acceptance: `After source/carrier qualification, consume current HIAL admission before genuine supervised native runtime. Independently observe packed layout, scalar signed/state properties, live versus explicitly sampled reads, whole-copy edge, holds, repeated requests and reset/domain behavior. Compare complete native/API/actual newline source/schedule/semantic/discovery products, supported corpus and baseline carriers/HDL. Keep unsupported profiles precise and synchronize all selected requirements/book/records; close input delivery only with recoverable behavior evidence.`
  Verification: `Complete input delivery joins qualified frontend/generated/public contracts, genuine direct/generated binary observations, contextual unsupported profiles and independent selected requirement signoff. Original native evidence is immutable; current full SystemVerilog products match predecessors except dates. Final source/public checks and sealed join complete .5.5.3.2.3. No X/Z, reset-free guarantee or broader consumer closure.`
  Commit: `this commit`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.4, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.1`
  Status: `done`
  Goal: `Prepare a direct packed-input behavioral witness without executing HDL.`
  Acceptance: `Consume decision 0113, R13/R14, current frontend/generated evidence and HIAL .3.2.10.11.5. Own a fixed independently authored nested-record source and public-pin bench for packed ranges, live versus entry-sampled reads, whole-copy edge, hold, repeated requests and asynchronous reset. Check literal declaration/caller facts, scheduled carriers and both emitted Verilog families without HDL compilation/execution. Signed/state declarations retain independent structural witnesses; a binary-valued Verilator observation cannot claim X/Z behavior. Include hostile literal/bench controls and preserve production bytes. Native execution is explicitly pending .2-.3 and must not occur in this slice.`
  Verification: `T2024 and fixed source/bench preserve literal nested packed fields, actual native semantic declarations, guarded entry sample, authored whole copy, live read and both emitted typed Verilog-family products. Authored equal-width signed/state/member-order variants fail the unchanged literal witness; unsigned behavioral counterexample is prepared. Final guarded T2024/T1994/T2018 passes All tests successful, Files=3, Tests=13 with the native subtest explicitly skipped. Production/source/bench/supervision bytes remain. The independent single-transaction bench uses literal entry/copy/live words, prior held value, repeated requests, idle hold and reset/abort; execution remains unqualified. HIAL .11.5 is consumed and requires a new exact fixed observer. Repair stale narrative pointer .63 before .5.2 observer qualification.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.2`
  Status: `done`
  Goal: `Qualify a fixed failure-only observer for the direct packed-input test.`
  Acceptance: `After .1 commits, bind only its exact maintained target/fixture/producer identities through a new exclusive admission. Consume the committed native/failure-only witness and preserve original arguments, returns, errno, bounds, capture gaps and cleanup. Independently qualify silent success, controlled real rejection, diagnostic gaps, source drift, wrong targets and reused captures before genuine HDL use. Existing archived observer admission and receipts remain immutable. Link HIAL .3.2.10.11.5 ownership; no actual feature HDL execution in observer qualification.`
  Verification: `Corrected admission preparation is committed at 786aa4466133f8f2c47575f3c81fbd21a9ad2f89. Fresh exclusive finite controls and complete sealed independent verification close the exact fixed observer integration. Source identities, original helper/adapter limits/results, silent success, controlled real native rejection, explicit gaps and independent PID/group absence are qualified. Original warning-bearing integration remains unqualified and immutable. Genuine T2024 execution is separately .5.3; historical native cause remains open.`
  Commit: `this commit`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.2.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.2.1`
  Status: `done`
  Goal: `Repair fixed-admission diagnostics and caller purity before fresh qualification.`
  Acceptance: `P2 new integration defect: finite controls pass but saved verification rejects outer stderr because return sort (...) emits a Perl interpreted-as-function warning at RecordInputAdmission.pm line 18. Preserve complete initial source/admission/results/cleanup/manifest and exact failed verifier result. Prepare a corrected separate fixed observer using explicit path array plus sort @paths and add exact outer stderr checks to the finite qualifier. Independently prove the warning is the sole saved integration failure, syntax is clean, and admitted target/count/source bounds remain unchanged. Fresh JSON calibration also proves aliased scalar inspection mutates accepted numeric-string kinds; detach the closed root/count/digest values while preserving accepted values and owned CLI numeric serialization. Commit this bounded repair/preparation before fresh native controls; no feature HDL execution or archived-helper change.`
  Verification: `Initial sealed oct01 controls and failed saved verifier remain byte-exact and unqualified. Independent warning-only normalization passes all original saved checks and hostile controls without native rerun. Corrected syntax is clean, and pure preparation passes All tests successful, Files=1, Tests=25, including unchanged targets/bounds, complete caller JSON kinds on success/refusal and the preserved actual-before counterexample. Strict finite outer-stderr checks are prepared. Fresh native observer qualification remains child .2; no feature HDL execution.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.2.2`
  Status: `done`
  Goal: `Requalify the corrected fixed observer from fresh exclusive native controls.`
  Acceptance: `After .1 commits, use the corrected fixed recipe with new exclusive captures. Require both finite TAP and complete sealed independent verification, exact stderr including deliberate gaps, unchanged stage/argument/result/errno/bounds, fixed target/source/coverage and independent PID/group cleanup. Preserve first warning-bearing evidence. Close observer integration only after all saved hostile controls and doctrines pass and commit before genuine packed-input HDL execution.`
  Verification: `Fresh exclusive oct01fix finite controls pass All tests successful, Files=1, Tests=63. Complete sealed saved verification passes exact stderr, silent ordinary/stale success, intentional real session rejection and native context/errno, modeled query/capture/retention gaps, original stage arguments/results/bounds and independent captured PID/group absence. Hostile saved mutations reject. Exact sources and original unqualified warning-bearing evidence remain unchanged. No feature HDL execution; genuine direct observation remains .5.3 after bounded history rollover .64.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.3`
  Status: `done`
  Goal: `Observe and qualify genuine direct packed-input runtime behavior.`
  Acceptance: `After .1-.2 commit, execute the actual direct test under its freshly qualified failure-only observer. Independently observe both emitted Verilog families through public pins, complete unchanged stage results, exact source/producer identities and cleanup. Stop and own any native or HDL failure before further execution. Retain recoverable outcomes and hostile saved-record verification. Binary-valued execution does not establish four-state X/Z semantics or historical EPERM repair.`
  Verification: `Fresh exclusive record_input_direct_oct01 runs actual T2024 with the committed qualified fixed observer. Both emitted Verilog families pass the independent public-pin bench, three request laps, entry sample/live/whole-copy edges, held reset/prior values, idle holds and reset/abort. The actual same-width unsigned source compiles and reaches PACKED_SIGNED_MISMATCH with nonzero exit, preserving all original stage arguments/results/bounds. Full TAP reports All tests successful, Files=1, Tests=4, with no skipped runtime. Sealed independent verification authenticates all six receipts, exact admitted/extra producer Git blobs and before/after identities, empty native events/diagnostic gaps and saved hostile controls. Independent workspace/selected-command census is absent; successful-child native PID identities are deliberately uncaptured. Source/test/bench/observer/supervisor remain unchanged. Evidence is docs/audits/record-input-direct-observation-20261001/. Binary-valued execution leaves X/Z and historical EPERM causality unproved; generated/domain execution remains .5.4.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.4`
  Status: `done`
  Goal: `Qualify generated and named-domain packed-input execution.`
  Acceptance: `Select the smallest independently authored public-pin runtime witnesses for reused live readers and a sole generated whole-copy writer, including owning/reset-free sibling domains, repeated requests and reset. Split preparation, fixed observer admission and genuine observation before each runtime when necessary. Preserve explicit output binding, domain ownership and exact packed private data/enable edges; no arbitration or record-output admission.`
  Verification: `All children complete: fixed independent source/bench preparation, separately qualified exact observer, bounded typed-carrier and oracle repairs before full genuine positive/unsigned-negative execution, then .4 requirement/public/baseline reconciliation. Both fixed generated sources pass both Verilog families. Existing complete declaration/private ownership/clock-reset/refusal contracts remain; no record output or arbitration admission. Supported backend/input completion is .5.5; historical native causality and X/Z/reset-free initialization stay open.`
  Commit: `this commit`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.4.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.4.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.4.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.4.4`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.4.1`
  Status: `done`
  Goal: `Prepare fixed generated/domain input source and behavioral witnesses without HDL execution.`
  Acceptance: `Use independently authored nested packed declarations, parent-owned public phase outputs, literal entry/copy/live/prior/reset words, repeated requests, idle hold and reset/abort. Include named-domain spawned sole writer/reused readers with clock-only unused sibling and ordinary parameterized blocking sole writer/reused readers. Check exact roles, artifacts, data/enable edges, typed packed endpoints, domain/reset ownership, both emitted families and strict carrier replay, caller/source/producer purity and hostile structural/property witnesses. Prepare actual unsigned behavioral counterexample. No native HDL compilation/execution, reset-free initialization, X/Z or complete delivery claim.`
  Verification: `Fixed T2025 named-domain spawned and ordinary parameterized blocking copier sources preserve independent complete packed declarations, caller JSON kinds, exact private child roles, reused reader definitions, whole typed data/enable ownership and entire public/private wiring. Original authored sources emit both Verilog families; every unchanged-basename artifact strictly replays. Clock-only unused sibling gains no reset/state and live declarations stay in io. Disabled actual write-enable and authored same-width unsigned property fail independent structural witnesses; the unsigned actual source emits for later behavioral falsification. Fixed bench distinguishes entry/copy/live and all copied packed leaves, prior held values, repeated requests, holds and asynchronous reset/abort. First draft guard-scope and replay-basename oracle errors are diagnosed and corrected without product changes. Focused generated/package/direct/JSON checks pass Files=5, Tests=23; final readable witness/book passes Files=2, Tests=6. Authenticated static receipts are docs/audits/record-input-generated-preparation-20261001/. Runtime is explicitly skipped. Genuine HDL execution remains .2-.3, historical cause/XZ unproved.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.4.2`
  Status: `done`
  Goal: `Qualify a fixed observer for the exact generated record-input witness.`
  Acceptance: `After .1 commits, bind exactly T2025 and its fixed sources/bench/producer identities through a new exclusive admission and predeclared five compile/runtime pairs. Reuse immutable qualified failure-only/native/stage helpers; separately qualify finite silent/rejection/gap/admission/cleanup controls and sealed hostile verification before feature execution. Link HIAL .11.6; no T2024/T1974 admission reuse or original supervisor change.`
  Verification: `Fresh exclusive oct01gen finite controls pass All tests successful, Files=1, Tests=63; pure exact target/fixture/caller-kind checks pass Files=1, Tests=18. Complete sealed independent verification passes fixed generated_input schema/target/five-pair admission, complete producer membership/identities, original stage arguments/results/bounds/errno, exact outer stderr, silent ordinary/stale success, controlled real session rejection/context, explicit modeled gaps and independent captured child PID/group absence. Hostile saved source/scope/coverage/result/context/cleanup controls reject. Original helpers/direct observers and exact committed T2025/source/bench remain unchanged. Qualified evidence is docs/audits/generated-input-observer-20261001/. Genuine feature HDL is not executed; fresh observation remains .5.4.3 after this integration commit.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.4.3`
  Status: `done`
  Goal: `Observe genuine generated/domain record-input behavior.`
  Acceptance: `After .1-.2 commit, execute the exact fixed witness under fresh qualified failure-only admission. Observe both emitted families for named spawned and ordinary blocking copies plus reused readers, repeated requests, hold, owning reset/abort and clock-only sibling isolation. Retain full original stage results/bounds, source identities, explicit gaps, independent cleanup and hostile saved verification. Stop and own unexpected failure before another execution. No X/Z, reset-free initialization or historical native-cause claim.`
  Verification: `First compile and later partial failures remain immutable under child diagnoses. Typed variable carrier repair and completion-window oracle correction are committed; .3.3.3 now independently qualifies complete genuine generated/domain behavior. Generated execution reconciliation remains .5.4.4 and backend/input closure .5.5; no full request or historical native-cause closure is inferred.`
  Commit: `this commit`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.4.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.4.3.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.4.3.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.4.3.1`
  Status: `done`
  Goal: `Preserve and diagnose the first genuine generated-input compile failure.`
  Acceptance: `Retain full original TAP/stdout/stderr/admission/stage/result/summary/source identities/cleanup from spent generated_input_oct01. Independently authenticate only the actually reached stage and rejection with hostile saved controls. Trace authored mixed nested state-model types through actual public re-emission and the structural composition declaration path, distinguishing illegal typed net from property/layout changes. No further HDL execution before diagnosis and commit; retain any unqualified success verifier draft honestly.`
  Verification: `Full original spent generated_input_oct01 first-compile failure is sealed in docs/audits/record-input-generated-observation-20261001/. Independent saved verification authenticates the reached compile only, exact sources/Git producer blobs, nonzero HDL rejection, original argv/bounds/result/cleanup, empty native events/gaps and absent selected workspace/commands; hostile saved mutations reject. Actual unchanged strict public re-emission reproduces exact wire declaration and nested bit locations without compiling/executing HDL. StructuralRTLIREmitter::_render_net_line prefixes wire to typed aggregates; TypeDeclarationSupport preserves authored two_state leaves. Existing T167 explicitly expects this illegal mixed-state wire, exposing a structural-only oracle gap. Git pickaxe identifies 3ca803fc8946140c172aeb97da26d66dd8830aee as introduction. No product fix or genuine behavior is claimed; .2 owns the immediate P1 repair.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.4.3.2`
  Status: `done`
  Goal: `Repair typed composition carriers containing two-state members.`
  Acceptance: `P1 accepted source emits illegal wire-over-bit-containing packed typedef. Review actual StructuralRTLIR declaration/driver/type contracts, corresponding scalar and nested list/record cases, supported backends and book before source change. Preserve complete layout/signed/state intent and driver ownership; no silent four-state widening or arbitration. Add independent structural legality and old-emitter counterexamples, focused producer/integration tests and exact baseline controls. Commit the verified bounded fix before genuine HDL execution.`
  Verification: `The shared type renderer recursively identifies explicit two_state scalar leaves in nested records/lists. Structural emission preserves those exact typedefs on variable carriers instead of illegal typed wires; explicit scalar two_state wire metadata renders bit variables. Existing all-four-state typed wires, legacy scalar nets and explicit typed variable carriers remain. T2026 independently checks both family declaration classes and complete caller JSON, and its actual unchanged failing source full HDL differs from sealed predecessor solely by removal of the illegal carrier wire keyword and date. Exact old emitter preload makes both T2026 subtests RED. Focused T2026/T167 passes Files=2, Tests=25; structural/typed/shared/generated/carrier/JSON regression passes Files=8, Tests=49 with runtime explicitly disabled. Sealed independent saved verification rejects unrelated/weakened controls. Prepared T2025/source/bench and fixed observer/native helpers remain unchanged. The declaration fix is qualified structurally; actual compiler/runtime defect closure remains fresh .3.3 after this commit.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.4.3.3`
  Status: `done`
  Goal: `Qualify corrected genuine generated/domain behavior from fresh authority.`
  Acceptance: `After .1-.2 commit, recheck qualified fixed observer scope and complete changed producer membership/identities; split new observer preparation/qualification if its closed contract needs widening. Use a new exclusive capture, never replay generated_input_oct01. Execute all required pairs and retain independent full saved/hostile verification and cleanup. Diagnose any new unexpected result before another execution. No X/Z, reset-free initialization or historical native causality claim.`
  Verification: `Children diagnose and repair the illegal mixed-state typed wire and wrong late-hold oracle before fresh complete qualification. Fresh exclusive generated_input_window_oct01 consumes committed f606ce2fd01461039d279d13fa863478fe91d375 and the unchanged qualified observer. All five compile/runtime pairs execute: named-domain spawned and ordinary blocking positives pass both Verilog families; the actually compiled unsigned property reaches the expected signed mismatch after its bound-result window passes. Every positive covers all packed leaves, sampled/prior/live/signed/repeated/reset/hold/isolation predicates and all request laps. Overall Files=1, Tests=5 PASS, no skips. Full original arguments/results/bounds, exact before/after producer Git identities and cleanup are sealed in docs/audits/record-input-generated-observation-complete-20261001/. Independent saved hostile verification and workspace/command census pass; native events/drift/gaps empty. Successful-child PID identities, X/Z, reset-free initialization and historical EPERM causality remain unproved. All earlier spent evidence is preserved.`
  Commit: `this commit`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.4.3.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.4.3.3.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.4.3.3.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.4.3.3.1`
  Status: `done`
  Goal: `Preserve partial generated runtime passes and diagnose blocking whole-copy mismatch.`
  Acceptance: `Retain full actual generated_input_fixed_oct01 admission, all reached stage results/arguments/bounds, complete TAP, exact source/producer identities and cleanup. Independently authenticate the named-domain positives and ordinary blocking compile/runtime failure without treating the full target as PASS. Trace actual source/carrier/HDL binding, whole private handoff and owning state timing; determine product or oracle root cause. No further HDL execution before diagnosis is owned and committed; preserve native limits and old spent evidence.`
  Verification: `Complete partial receipts and hostile saved controls pass independent authentication. Actual public schedule reports copy_seen binding_timing done_guarded; actual carrier uses combinational = guarded by child done. Emitted always_comb defaults copy_seen to zero outside that pulse, which precedes parent phase 2 and later parent done. Published composition contract agrees. The old bench requires nonzero copied data at late parent done and idle, so even correct packed storage fails this scalar predicate. Individual failed blocking values were not captured; no claim they passed. This is P2 witness timing error, immediately owned by .2. No further HDL execution; historical EPERM remains unattributed.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.4.3.3.2`
  Status: `done`
  Goal: `Correct the blocking output-binding observation window.`
  Acceptance: `P2 witness requires late retention from a documented done-guarded combinational binding. Observe the independent literal copied result during the public copy phase; distinguish spawned forwarding from blocking pulse binding at later completion. Preserve all actual packed-storage and idle-hold predicates. Qualify temporal counterexamples without changing production retention semantics. Preserve selected input sampling/live/copy semantics, explicit output binding and physical owner/type/model contracts, with actual predecessor falsification and focused controls. Commit before another genuine execution; no arbitrary expectation weakening.`
  Verification: `The bench now observes the independently literal copied result during public phase 1 before phase 2, with negedge sampling preserving original live-input change timing. Explicit call-role literals retain spawned result expectations and require blocking combinational default zero at later parent done/idle. Every packed-storage, sampled/prior/live/signed/repeated/reset/isolation predicate is preserved. Pure temporal controls reject missing/late-only result, wrong retention and each packed leaf. Exact old bench makes corrected checks RED. Focused T2025/admission passes Files=2, Tests=23; structural/generated/caller regression passes Files=8, Tests=50, runtime explicitly disabled. Sealed independent verifier authenticates exact predecessor, complete other-predicate preservation and hostile receipts. Fixed observer paths/schema/target/coverage are unchanged; its sealed qualification and current dynamic-hash preparation pass. No production/source fixture/helper change; complete actual runtime remains fresh .3 after this commit.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.4.3.3.3`
  Status: `done`
  Goal: `Qualify complete corrected generated/domain behavior after blocking repair.`
  Acceptance: `After .1-.2 commits, recheck exact current witness and complete producer closure, qualify any changed observer contract before HDL use and choose a new exclusive capture. Execute complete positive and actual unsigned-negative coverage with unchanged independent public-pin predicates, full original records, hostile saved verification and cleanup. Stop and own any unexpected result before another execution. Preserve binary/XZ/reset-free/native limits and partial historical receipts.`
  Verification: `Fresh exclusive generated_input_window_oct01 consumes committed f606ce2fd01461039d279d13fa863478fe91d375 and the unchanged qualified observer. All five compile/runtime pairs execute: named-domain spawned and ordinary blocking positives pass both Verilog families; the actually compiled unsigned property reaches the expected signed mismatch after its bound-result window passes. Every positive covers all packed leaves, sampled/prior/live/signed/repeated/reset/hold/isolation predicates and all request laps. Overall Files=1, Tests=5 PASS, no skips. Full original arguments/results/bounds, exact before/after producer Git identities and cleanup are sealed in docs/audits/record-input-generated-observation-complete-20261001/. Independent saved hostile verification and workspace/command census pass; native events/drift/gaps empty. Successful-child PID identities, X/Z, reset-free initialization and historical EPERM causality remain unproved. All earlier spent evidence is preserved.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.4.4`
  Status: `done`
  Goal: `Reconcile and close generated/domain execution qualification.`
  Acceptance: `After actual .3 qualification, verify each selected generated/domain behavioral requirement, exact explicit binding and private packed data/enable ownership, prior direct/public/carrier controls and affected book/response/facts. Preserve unsupported profiles and explicit native/X/Z limits; backend/input completeness remains .5.5. Run focused meaningful checks and close parent only from recoverable evidence.`
  Verification: `The bounded requirement crosswalk reconciles complete literal layout/state declarations, live/reused readers, typed private sole-writer data/enable and owning reset, explicit spawn/blocking binding roles, domain/unused isolation, repeated/signed/reset/hold execution and complete public/refusal/prior baselines. Saved direct and complete generated verifiers pass without HDL replay. Fresh T2019/T2020/T2021/T1985/T1981/T1982 public/package/refusal/scalar/storage checks report All tests successful, Files=6, Tests=39; complete native/API/newline equality and independent literal/corrupt-product/refusal oracles pass. All tracked bin/perl/t/isf code/source remains baseline 153c79aca9b75354dd0753c448688a4f032f3956. Sealed exact-source/receipt and hostile verification: docs/audits/generated-input-execution-reconciliation-20261001/. Backend/input closure remains .5.5, outputs/aggregate consumer delivery separate; no X/Z/reset-free/native causal closure.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5`
  Status: `done`
  Goal: `Reconcile supported backend profiles and complete record-input delivery.`
  Acceptance: `After executed direct/generated witnesses, qualify supported VHDL subsets and precise unsupported profile refusals, full native/API/newline/discovery/corpus/baseline products and every selected input requirement. Keep four-state execution limits explicit. Synchronize book, capability/spec, canonical SPECFORGE response and facts; close only independently verified input delivery. Full aggregate consumer signoff stays .60.4.4 after output delivery.`
  Verification: `Profile qualification and current public/corpus reconciliation are complete. Independent .3.2.3 joins every selected input clause to exact source/type/layout/copy/domain/public and original native evidence. SystemVerilog is qualified; current Verilog/v and selected VHDL requests refuse precisely. Input parents close; output/field writer/full consumer and stated execution limits remain owned.`
  Commit: `this commit`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5.1`
  Status: `done`
  Goal: `Qualify record-input backend profile boundaries against supported controls.`
  Acceptance: `Read decision 0113 and supported VHDL scope, then characterize actual authored direct/generated/domain and supplied record-input generation through CLI and public pipeline. Require precise unsupported-profile refusal without successful or partial output, preserving existing destinations and supported scalar/packed-output VHDL controls. Retain independently expected declarations and Verilog-family support, producer/source purity and literal false-success/wrong-diagnostic controls. Own any newly exposed defect before further work. No native HDL execution, VHDL executable qualification, broader backend admission or historical-cause claim. Synchronize book, canonical response and fact evidence before committing.`
  Verification: `Actual CLI/public pipeline selected direct mixed-member, supplied typed-input and generated/domain composition refusals retain precise primary reasons, no partial success and existing/absent destination preservation. Independent scalar-input and inferred packed-output VHDL controls remain admitted. T2027 plus published direct/facade/composition band reports All tests successful, Files=4, Tests=453. False-success/signal/absent/stack-only diagnostic controls and independent saved product/destination/width mutations reject. Baseline sources/producers are exact; no production code or HDL runtime changes. Complete census, draft diagnostic-link RED, corrected test/recipe and PASS evidence sealed under docs/audits/record-input-backend-profiles-20261001/. Final public/corpus .2 and selected-input signoff .3 remain open.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5.2`
  Status: `done`
  Goal: `Reconcile complete record-input public discovery, corpus and prior controls.`
  Acceptance: `After profile qualification, join current native/API/actual newline check/semantic/schedule/discovery products and complete selected supported ISF cohort to independently authored declaration/type/layout and baseline carriers. Preserve supplied-source identity and capability/spec/book consistency, generated-private exclusion and contextual refusals. Reuse already qualified evidence where unchanged; investigate genuine drift. No implicit output/list/variant delivery or X/Z runtime claim.`
  Verification: `P2 stale book matrix public/runtime pending rows are repaired; git log -S traces the old qualification prose to aebe0037554eb9995c1d4fa67f4ec53f98364520. Only the requested-record and packed-record-input rows change; pending input signoff and output/optional/XZ boundaries remain. Fresh T2017/T248/T2018 reports All tests successful, Files=3, Tests=7214: complete supplied check/semantic/schedule and native/API/newline/all-section discovery, catalog and JSON-kind controls. Actual complete selected ISF cohort and literal check/semantic/schedule discovery descriptors reconcile; missing membership/applicability/schema/kind mutations reject. Draft saved dictionary equality aliases booleans and integers; canonical JSON equality and retained boolean/string hostile controls correct it before final qualification, with a literal counterexample preserved. Unchanged complete-cohort/generated/refusal/prior/runtime evidence authenticates without HDL replay. Production/tests/maintained sources remain baseline f69a464; sealed proof: docs/audits/record-input-public-reconciliation-20261001/. Independent input signoff .3 is next.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5.3`
  Status: `done`
  Goal: `Complete independently verified record-input delivery from selected requirements.`
  Acceptance: `After .1-.2 commits, reconcile every input portion of selected R1-R3 against exact source, type/layout, lexical/domain, copy ownership, backend profile, complete public and genuine direct/generated behavior evidence. Authenticate original receipts and independent counterexamples without spent native replay. Close only input parents whose requirements are satisfied; update canonical response/book/facts and resume record outputs .60.4.3.3. Keep four-state execution, output/full aggregate consumer, durations/timers and historical native/startup/full-CI gates explicit.`
  Verification: `Children reconcile stale VHDL scalar scope and record-input language-profile claims, implement precise unsupported Verilog/v refusal and independently sign off selected input delivery. Original sources/receipts authenticate without replay, current public controls pass and complete SystemVerilog RTL is unchanged except dates. Output/full consumer, X/Z and historical-native obligations remain separate.`
  Commit: `this commit`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5.3.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5.3.1`
  Status: `done`
  Goal: `Repair contradictory supported signed-scalar VHDL scope before input signoff.`
  Acceptance: `P2 maintained-profile drift: trace the old refusal and later bounded support through actual history, published book and current pipeline/facade controls. Replace the stale VHDL_SCOPE blanket refusal and overbroad vector-only signed deferral with supported signed scalar addition/subtraction/multiplication and precise division/modulo/mixed-sign limits; retain record-input refusal and decision 0023 analyzer/runtime boundaries. Qualify focused actual source generation and independent literal positive/refusal controls, preserve source/producers, synchronize book/fact/response and commit before final input signoff. No new backend implementation or native HDL execution.`
  Verification: `git log -S identifies old blanket refusal 0f31a983ffaafb606b41e1e42c965523279f37db and later bounded support b4033eb3f62856b8d60d3554475883e13490dfcd. The later scope diff updated support elsewhere while retaining that separate old bullet. Current T1420/T386 passes All tests successful, Files=2, Tests=160, including actual positive RHS/chain generation and precise signed division/modulo/mixed-sign refusals. Replace the obsolete scope bullet and its related vector-only signed deferral; independent exact-byte predecessor/current and hostile stale/operator/record-profile controls pass in docs/audits/vhdl-scalar-scope-reconciliation-20261001/. Book/fact/response agree; source/producers remain baseline b069b76. Initial staged doctrines reject a draft edit to the pinned direct-vhdl-scaffold card with bounded replacement drifted from the stable partition. Exact checker reconstruction proves the card is immutable navigation, not an ordinary current fact. Restore its HEAD bytes and route new evidence to vhdl-signed-scalar-scope-reconciliation; no history pin or gate is weakened. No analyzer found on PATH and no HDL/analyzer/runtime executes. Input signoff .2 remains next.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5.3.2`
  Status: `done`
  Goal: `Sign off every independently qualified selected record-input requirement.`
  Acceptance: `After parent prerequisites and child .1 commit, reconcile every input portion of selected R1-R3 against exact source/type/layout/context/domain/copy/profile/public and genuine direct/generated evidence. Authenticate complete original positive/negative receipts and counterexamples without spent HDL replay. Close only satisfied input parents and synchronize capability/spec/book/response/facts, preserving X/Z, output/full consumer, durations/timers and historical-native/startup/full-CI gates. Resume record outputs .60.4.3.3 from a clean committed frontier.`
  Verification: `Children preserve original SystemVerilog parser scope, qualify precise ISF Verilog/v refusal and complete the selected input requirement/evidence join. No full aggregate request closure, legacy aggregate Verilog standards qualification, X/Z or historical-native cause follows. Record outputs .60.4.3.3 are next.`
  Commit: `this commit`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5.3.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5.3.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5.3.2.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5.3.2.1`
  Status: `done`
  Goal: `Reconcile current record-input backend and authoring scope statements.`
  Acceptance: `P2 scope defect: generic qualified Verilog wording omits that the actual complete original positive and unsigned-negative receipts compile .sv DUTs with default SystemVerilog syntax. Authenticate exact immutable original argv/results, independently capture current direct/generated text without any HDL compiler or simulator, and compare retained packed typedefs/procedural forms with the published version-matched tool contract and exact converter history. Preserve genuine binary behavior and all prior archives; correct book/spec/feedback/facts to recommend SystemVerilog and identify pure Verilog-2005 as unqualified. Also repair the inherited book storage walkthrough that still refuses all aggregate interface ports after record-input admission, using exact history and current actual authored controls. Own a precise boundary repair in sibling .2; do not infer a pure-mode failure or silently retire a supported emitter option.`
  Verification: `git log -S roots the overbroad target recommendation at f69a464cfdcbe00128bb3923cbd6921a913887c4, procedural-only conversion at 5de2f44d8e68b1124a3736c30e8479a005188768 and stale walkthrough at aa2404ebe7822c53c048460abf7d10961924da12. Complete original direct/generated receipts authenticate Verilator 5.050, .sv DUTs and no IEEE 1364 selector; its published version-matched default is SystemVerilog. All six actual FSMGen-only direct/domain/blocking emissions retain packed typedefs; no HDL tool runs. Exact source/producers match baseline 40a51936. Scope/authoring statements now agree across book/spec/feedback/facts; preserved positive/unsigned-negative behavior remains valid. Missing-pair, language-selector, erased-type and false-zero JSON-kind controls reject. Sealed docs/audits/record-input-language-profile-20261001/ retains complete inputs/emissions/original identities and exact book replacements. Focused docs T1305/T1414/T1303 passes All tests successful, Files=3, Tests=310; book builds. Precise Verilog-profile qualification .2 precedes independent signoff .3.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5.3.2.2`
  Status: `done`
  Goal: `Qualify a precise record-input Verilog language boundary.`
  Acceptance: `After .1 commits, inspect the selected contract and actual direct/generated target handoffs. Retained packed SystemVerilog syntax must not be advertised as IEEE 1364 qualification. Select and implement the smallest correct profile behavior: valid standards-qualified lowering, or an explicit contextual refusal for an unsupported record-input profile. Preserve scalar and already qualified SystemVerilog/storage behavior, public destination atomicity and archived native evidence. Split native-profile admission and observations before any new HDL invocation; do not replay spent captures. Log broader existing aggregate/Verilog issues with independently established ownership before changing their scope.`
  Verification: `Decision 0113 selects precise unsupported-profile refusal. CLI and facade use validated declared metadata before lowering/publication; Verilog/v names actor/input/type and recommends SystemVerilog. Original T2028 RED is Files=1/Tests=8, missing refusals only. Draft status probe confirms 255/signal 0 from the existing lowering exception path; a separate handler now returns normal 1 and stable stack-free diagnostics. Final actual T2028 passes Files=1/Tests=10, including imported/unused declarations, existing/absent destinations, check/semantic JSON, target-neutral schedule and complete SystemVerilog predecessor RTL except date banners. Seven-file regression passes Files=7/Tests=7328 before final diagnostic-format change; latest focus verifies that change. Docs T1305/T1414/T1303 passes Files=3/Tests=310; book builds; syntax and both immutable native saved verifiers pass. Sealed docs/audits/record-input-verilog-boundary-20261001/ retains RED/draft/final receipts, code identities and hostile controls. Current T2024/T2025 membership is SystemVerilog-only; HIAL owns fresh future native admission. Stale import-map admission prose is reconciled. Legacy aggregate Verilog qualification gap is owned by .60.4.3.5.1. No new HDL invocation or spent replay; final selected-input signoff .3.2.3 remains next.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5.3.2.3`
  Status: `done`
  Goal: `Complete selected-input signoff after precise backend profiles qualify.`
  Acceptance: `After siblings commit, reconcile every selected R1-R3 input requirement with original complete frontend/generated/public/profile/native evidence and independent counterexamples. Close only satisfied input parents, preserve X/Z, output/full consumer, duration/timer and historical-native limits, and resume record outputs .60.4.3.3 from a clean committed frontier.`
  Verification: `Every selected R1–R3 input clause joins exact source/value/carrier/public/profile and genuine direct/generated evidence in docs/audits/record-input-signoff-20261001/. All selected immutable verifiers authenticate complete original receipts and counterexamples without HDL replay. git diff shows only the separately qualified shared profile integration changed production since original generated runtime; source/benches/lowering stay unchanged. Current T2014/T2016/T1998 passes All tests successful, Files=3/Tests=42. The first docs band rejects the old T1305 pending-status literal after promotion; its exact status update then passes T1305/T1414/T1303, Files=3/Tests=310. Book builds. Missing-clause, width-only identity and parser-scope substitutions reject. Input parents close; record outputs/field writers/full consumer, X/Z, reset-free guarantees, VHDL runtime, legacy .fsm standards qualification and historical native/startup/full-CI limits stay owned. Next output ingress leaf .60.4.3.3.1 is pending.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3`
  Status: `active`
  Goal: `Deliver record outputs and whole copies with physical writer admission.`
  Acceptance: `After qualified input delivery, map whole output writers to scoped physical packed roots. Preserve input/output roles, actor ownership, source-order semantics and existing exclusion/compatibility proofs. Refuse unresolved overlap, type mismatches and unqualified generated writers. Split any prerequisite repair before changing source; independently qualify hold, timing, repeated requests, reset and domain behavior and all public surfaces.`
  Verification: `pending`
  Commit: `pending`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.1`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.1`
  Status: `pending`
  Goal: `Trace record-output whole-copy writers and select closed admission slices.`
  Acceptance: `After committed input signoff, read selected output/type/role/domain and physical writer contracts. Trace actual parsed targets, scoped owner identities, post-binding/generated module assignments and backend/public paths through their public interfaces. Reproduce current record-output refusal and independent packed target/overlap controls without HDL execution. Select the smallest sound output admission and qualification split; preserve input/scalar/storage semantics and refuse unresolved/competing writers without invented arbitration. Own every genuine prerequisite before source changes and keep output authoring closed until gates qualify.`
  Verification: `pending after selected input closure`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.4`
  Status: `pending`
  Goal: `Deliver scalar output fields with qualified packed-range overlap.`
  Acceptance: `After whole outputs and demonstrated physical target/writer prerequisites, admit scalar leaf writes in existing supported contexts. Independently distinguish disjoint members, same-value compatible overlap, whole/member overlap and conflicting writers; do not infer arbitration. Preserve unaddressed fields and original write edges under the applicable assignment contract. Qualify nested paths, domains, generated ownership, diagnostics, public replay/runtime and report/corpus/book alignment.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.5`
  Status: `active`
  Goal: `Qualify affected backend profiles and unchanged source controls.`
  Acceptance: `After required implementation slices, qualify direct SystemVerilog/Verilog and supported VHDL profiles separately, imports, explicit interfaces, compositions and report metadata. Unsupported combinations must fail contextually. Preserve supplied baseline and scalar/storage/generated handoff controls, complete native/API/newline parity, capability/corpus/spec/book alignment and recoverable artifacts; do not close .60.4.4 from lint or parser acceptance alone.`
  Verification: `pending`
  Commit: `pending`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.5.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.5.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.5.1`
  Status: `pending`
  Goal: `Qualify remaining legacy Verilog aggregate profile boundaries before full consumer signoff.`
  Acceptance: `P2 validation/profile gap: procedural-only Verilog conversion and shared aggregate emitters retain packed SystemVerilog typedefs for legacy storage and lowered .fsm carriers. Existing compatibility text/behavior evidence does not establish IEEE 1364 syntax. Independently enumerate the affected authored public profiles and published contracts, preserve valid prior SystemVerilog and scalar controls, then deliver standards-qualified lowering or precise unsupported-profile refusal. Any new compiler/simulator probe needs separately committed HIAL admission and fresh fixed observation first. Do not classify a missing pure-mode observation as an actual native failure, replay spent captures or silently alter legacy supported semantics. Complete before affected backend/full aggregate consumer signoff.`
  Verification: `Scheduled from the exact procedural converter and complete two-emitter text evidence in docs/audits/record-input-language-profile-20261001/. Current .60.4.3.2.5.5.3.2.2 repairs only declared ISF record-input profile admission. Broader legacy storage/.fsm language qualification is explicitly unproved, with this repair owner; no new HDL execution or broad failure is claimed.`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.5.2`
  Status: `pending`
  Goal: `Complete affected backend and unchanged-source qualification after output delivery.`
  Acceptance: `After output/root/member delivery and sibling .1, qualify affected direct/generated/imported/explicit-interface/composition profiles separately, retain precise unsupported refusals and destination/public contracts, and verify supplied baseline plus scalar/storage/generated handoffs. Preserve capability/spec/book alignment and HIAL admission requirements. Reconcile every parent .5 requirement before closing it; complete consumer signoff remains .60.4.4.`
  Verification: `pending output-dependent complete backend-profile reconciliation`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.4`
  Status: `pending`
  Goal: `Qualify the complete consumer outcome.`
  Acceptance: `After implementation, independently exercise positive/negative cases, unchanged controls, target-qualified HDL where behavior changes, exact native/API/newline reports, source/capability/corpus/book alignment and all explicit requirement dispositions. Retain recoverable evidence and a repository-local downstream response; no external sending is authorized by this intake.`
  Verification: `pending preceding contract dependency`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.5`
  Status: `blocked`
  Goal: `Select optional list-root ports after required delivery.`
  Acceptance: `Map optional R4 to the completed required record-port contract and remaining roadmap; select a separately qualified bounded contract or explicit deferral before implementation. Preserve required record, scalar and storage behavior.`
  Verification: `Optional request remains unimplemented under decision 0113.`
  Commit: `pending`
  Blocked by: `Required R1-R3 and director-prioritized SPECFORGE duration/timer delivery; unblock after those required outcomes qualify.`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.6`
  Status: `blocked`
  Goal: `Select optional variant-record semantics after required delivery.`
  Acceptance: `Map optional R5 to the completed required record-port contract and remaining roadmap; select a separately qualified bounded contract or explicit deferral before implementation. Preserve required record, scalar and storage behavior.`
  Verification: `Optional request remains unimplemented under decision 0113.`
  Commit: `pending`
  Blocked by: `Required R1-R3 and director-prioritized SPECFORGE duration/timer delivery; unblock after those required outcomes qualify.`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.61`
  Status: `superseded`
  Goal: `Disposition the inferred implementation-configurable reset follow-on.`
  Acceptance: `Respect the supplied packet's question classification and the director's explicit clarification. Answer whether an instantiation-selected reset form exists without converting that question into a new reset feature request.`
  Verification: `The director clarified that sf-isf-unstated-reset is a question. The packet already declared that kind; the additional configurable-reset implementation plan was an over-expansion and is withdrawn. Current forms and the report ambiguity are answered under .60.3; no configurable-reset implementation is on this packet's delivery path. A separately requested future capability would need its own contract. Duration units, named timers and aggregate ports remain feature requests; storage access remains independently owned.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.62`
  Status: `done`
  Goal: `Reject malformed reset clauses instead of silently selecting a different reset policy.`
  Acceptance: `P1 reset-policy correctness follow-up immediately after the current provenance implementation commit and before consumer closure. Reproduce unknown timing/polarity tokens and extra operands through strict public queries; Parser::_parse_reset currently loops recognized tokens and ignores all other values. Own exact accepted/rejected grammar, preserved valid shorthand and domain behavior, precise diagnostics, native/API/newline failure equality and book/spec alignment. Split if the compatibility census reveals an intended accepted alias; do not speculate that parse success proves authored reset intent.`
  Verification: `Parser closes reset arity and options while retaining explicit sync, suffix inference, modifier order and undefined Lispish tails. A late public probe exposed authored () collapsed to undef by own normalization; reset payload normalization now preserves empty lists for rejection, without changing other contexts. Final T1979 Files=1, Tests=3 PASS; normalizer/storage/output/timing/provenance regressions Files=10, Tests=43 PASS, including complete unchanged valid-source carriers and HDL. Ordinary/strict native check and semantic failures, API/newline equality and schedule refusal qualify the fix; no simulator executed. Historical singleton-tail handling at 8dc7bb3d6f262be760bbe11ca1ec968bf6bdd792 is preserved. Lossless red/intermediate/final logs, public AST cause capture and exact identities: docs/audits/isf-reset-grammar-20260930/. Book/spec/downstream and canonical fact align; .60.3.4 is next.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.63`
  Status: `done`
  Goal: `Retire misleading historical resume prose without backfilling a duplicate frontier.`
  Acceptance: `P2 discovery ambiguity: the optional Current Frontier narrative appears current and names an obsolete next leaf. Decision 0019 and the canonical secondary-view fact explicitly make it historical; the authoritative nodes/index are correct. After .60.4.3.2.5.1 commits clean, retire only that unlabelled duplicate prose with exact committed retrieval and a historical stamp pointing to live sources. Do not backfill a second frontier. Preserve every node and active dependency, verify exact old narrative retrieval and unchanged node contracts, sync current pointers and commit before .2.5.2. No production change or new delivery claim.`
  Verification: `Exact 49ef15cba77bdb8572beb079a1a3e81bfa04a85e narrative names completed frontend refusals as next; the actual nodes and index are correct. Decision 0019 explicitly makes the secondary view historical, so no node-status defect or per-slice backfill requirement is inferred. Only that unlabelled prose is retired behind exact Git retrieval; .63 moves into the live node list. Independent exact predecessor/node-contract and historical-text verification passes; task-tree integrity reports all active task-tree invariants hold. Active index and Memory advance to the prepared direct target fixed-observer .60.4.3.2.5.2; book/canonical feedback already state its correct unexecuted scope.`
  Commit: `this commit`


- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.64`
  Status: `done`
  Goal: `Seal completed semantic acceptance history before genuine record-input runtime.`
  Acceptance: `Activate before the task would reach the unchanged 7200-line milestone, following completed .54's exact-version acceptance-history protocol. Retire only closed optional acceptance prose behind exact committed source/suffix identities and the existing bounded manifest. Preserve every live node, active contract, unresolved failure and current native/feature qualification limits. Independently verify node/text preservation, archive chain and consumers; run focused history/integrity checks and book before commit. No ceiling change or deferred doctrine reassessment.`
  Verification: `Legal boundary preparation is committed at b2669c3fafe36b40f8f1897f48a954dcbf94a9bb. Child .2 seals that exact complete source and closed suffix through the existing bounded manifest, preserves the old chain and every other node contract, and independently qualifies real hostile integrity controls. Only closed optional acceptance prose is retired; active native/feature limits and all original Git bytes remain. No checker, ceiling, product or native evidence changes. Resume .60.4.3.2.5.3.`
  Commit: `this commit`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.64.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.64.2`


- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.64.1`
  Status: `done`
  Goal: `Commit a legal boundary for the next closed acceptance-history suffix.`
  Acceptance: `The current live file has no Decisions heading; its first closed acceptance heading contains backticks, which the unchanged closed manifest contract forbids. Insert one unique Completed Acceptance History heading immediately before historical .54 acceptance, preserve all existing node contracts and history bytes apart from this owned boundary, and commit before exact-source rollover .2. No history is removed, no manifest or ceiling is changed, and no feature/runtime work starts.`
  Verification: `git log -S identifies former Decisions removal in 29ab49f217a82bacdd1ac83a8bcf2b687996f3ed. The unique legal Completed Acceptance History heading is inserted before closed .54 acceptance. Independent comparison preserves the entire historical body byte-for-byte except that insertion and every original node contract except owned parent .64 refinement. Actual integrity passes; no history, manifest, native evidence or ceiling changes. .2 consumes this committed source next.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.64.2`
  Status: `done`
  Goal: `Seal and retire closed acceptance history from the committed legal boundary.`
  Acceptance: `After .1 commits clean, use its exact Completed Acceptance History suffix and unchanged single-record bounded manifest. Independently authenticate full source/suffix hashes and dimensions, old manifest/source chain, all original live node contracts, anchors and native/feature scope limits. Keep complete predecessor retrieval and current pointer, qualify actual read-only integrity and hostile source/suffix/typed-dimension/pointer controls without other Git repository writes, and commit before .60.4.3.2.5.3. No ceiling or checker change.`
  Verification: `Exact committed b2669c3fafe36b40f8f1897f48a954dcbf94a9bb source and legal closed suffix are authenticated under unchanged single-record bounds. Python and independent Perl digests/dimensions agree; the prior manifest and exact older source chain remain retrievable. All original live node contracts except owned .64/.2 disposition remain byte-identical. Actual read-only checker accepts full rollover and rejects source/suffix digest, string-dimension, missing-boundary and displaced-pointer controls; independent changed-contract control rejects. Native/feature limits, original audits and active nodes remain live. Next .60.4.3.2.5.3 owns genuine observation.`
  Commit: `this commit`


- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.65`
  Status: `done`
  Goal: `Repair completed ownership records outside the authoritative task section.`
  Acceptance: `P2 continuity defect exposed by current observer qualification gate: the new .64 record is outside parsed Task Tree, and independent section extraction finds completed .61-.63 there as well. After the current qualified observer commit, trace their exact introduction and move only those existing records into the live Task Tree, adding exact root child references. Preserve every complete node contract, outcome, historical prose and source bytes except the owned registration repair. Correct the earlier global-regex preservation claim's registration limit, qualify actual checker extraction and hostile missing/changed/misplaced node controls, and commit before .64 or feature execution. Do not change the checker or historical-view doctrine.`
  Verification: `Exact git log -S introduction objects place .61-.63 after the first Task Tree boundary; .63 whole-file node preservation did not establish registration. All original node contracts are byte-preserved except the owned root references and .65 disposition, and all IDs now register inside the authoritative section. Public read-only checker and plain fixture controls pass: misplaced/missing/duplicate nodes and absent root references reject, including equal whole-file ID sets; independent contract mutation rejects. Product/native/history/checker bytes remain unchanged. Audit source/blob manifest and verifier preserve replay; .64 is next.`
  Commit: `this commit`


## Implementation Notes From `.4`

Downstream intake note (2026-09-24): the director reports SPECFORGE's old-copy
census failed because `specs/` was omitted, after an earlier missing
`pplugin.spec` warning. `git ls-tree 5a44ad496c852b168c31d4021cfdb158001a47c7
specs/pplugin.spec specs` confirms these are tracked exact-revision resources;
the current tree also tracks them. The reported differences are setup-invalid,
not established regressions. Their count is caller-supplied, not independently
re-derived. `.32.2` owns complete-export/preflight guidance; SPECFORGE's rerun
and all remaining ticket claims require fresh evidence.

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

## APB Source Repair Boundary — `.31.2.5`

Correct `done_phase` body assignments to public `PSEL` and `PENABLE` and
remove the unused parameterized `psel`/`penable` definitions. Actual current
semantic input ports include their undriven `psel_start`, `psel_val`,
`penable_start` and `penable_val` controls, beyond the declared APB interface.
Retain the same transaction states and response-sampling order; do not invent
nested drive calls or alter the language's drive lowering contract. Rename
the sample comment to describe its explicit output phases.

Own a focused source/lowering/structural-port regression in T1867, update the
existing deterministic DT summary expectation after unused definitions are
removed, and simulate generated HDL through wait, completion and repeat
transfers with both read-data and error results. Recheck actual native/MCP
semantic parity and support-accounted strict checks. The drive-block chapter
must show concurrent direct output assignments and clarify that body pairs
are not calls; also correct its stale expression-valued-body rejection claim
against the existing T1194 public contract. Compiler collision regressions
remain independent in T1866.

## Compiler Repair Boundary — `.31.2.1`

The selected change is module-wide deterministic allocation of assignment
DT-local and LHS-level enable names in `EnableGraph::AssignmentSupport`.
Keep existing readable candidates when available; separate colliding families
before factorization contexts, structural assignment records, mux consumers
and HDL emission are built. Reserve authored signal and top-level state/DT
enable names. Reset allocation on each analysis build, including rebuilds of
a prepared backend; do not change authored case or merge distinct signals.

`t/1866-generated-enable-name-identity.t` will exercise case-distinct LHSs
in the same and different DTs, distinct RHSs with colliding cleaned names,
DT/LHS cross-family collisions, authored/reserved suffix conflicts and rebuild
stability. Actual semantic CLI/MCP comparisons across process hash seeds
must preserve original driver provenance; generated HDL simulation provides
an independent behavioral check. Keep the APB source unchanged in this slice;
`.31.2.5` owns its independent correction. Selected enable/factorization,
structural IR and previous expression-alias tests provide the broader band.
Update the embedding book limitation and the canonical semantic fact only
when the native repair and its controls have passed.

## Latest-Feature Audit — `.31.1` (2026-09-24)

Capture revision: `5a44ad496c852b168c31d4021cfdb158001a47c7`.
The tracked [result projection](../audits/mcp-feature-coverage-20260924/evidence.json)
retains exact commands, input hashes, failure diagnostics, discovery results,
seed/path observations and decisive trace lines. Full raw reports remain in
`.artifacts/mcp-feature-coverage/`; their absence after cleanup does not turn the
projection into an exhaustive compiler report or a replay guarantee.

Re-derivation: the current manifest census was compared with actual native and
MCP queries for direct FSM, ISF, PPIF, protocol aliases, VIAL v1/v2 and an
expected negative source. Native capability metadata includes the later VIAL
public API, execution, bridge and backend contract sections; capability queries
select existing top-level sections dynamically. Source-bound coverage does
not follow automatically from that manifest visibility.

Falsification: native success with empty discovery contradicts alias coverage;
native VIAL JSON success with MCP hardware-route failure contradicts VIAL
parity; the native negative check preserves diagnostics that MCP discards.
Independent native runs with identical ISF bytes and varied hash seed/path
spelling selected different driver dependencies. The debug trace identifies
case-folded name collision and context replacement, separating this cause from
path metadata or legitimate Boolean simplification. Public drive-body syntax
and lowered completion assignments separately identify the APB source defect.

Durability: this task and the tracked projection commit the decisive evidence.
Missing leg: exhaustive feature-by-feature semantic qualification and repair
negative controls remain owned by `.31.2` and `.31.3`; no percentage or complete
coverage claim is earned here. Execution/service/mutation expansion is outside
the current read-only profile. The internal native proxy still lacks selected
routing/qualification, so it is not advertised as an MCP execution feature.

Repair order: compiler name identity (`.31.2.1`), APB source (`.31.2.5`),
structured failures (`.31.2.2`), alias discovery (`.31.2.3`), VIAL public
source tooling (`.31.2.4`), then complete qualification (`.31.3`). Actual
implementation leaves must refine their smallest safe test/contract boundary
before editing code. No discovered defect is closed by this audit alone.

## Reset grammar defect ownership

Canonical ownership is live node `.62` in the Task Tree above.

## Reset question scope disposition

Canonical ownership is live node `.61` in the Task Tree above.

## Current Frontier

Historical convenience view, retired under decision `0019`. Its former prose is
retrievable exactly from Git; it is not the live frontier and is not backfilled.
Read the eligible leaf nodes above, `docs/TASK_TREE.md`, and the bounded
`MEMORY.md` pointer for current work.

```sh
git show 49ef15cba77bdb8572beb079a1a3e81bfa04a85e:docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
```

## Version-Retrievable Historical Views

- Acceptance history manifest: `docs/tasks/history/SEMANTIC-INTROSPECTION-MCP-FRONTIER/acceptance-history.jsonl`

The live node list above remains authoritative for ownership and status.
Historical decisions, verification/commit logs and acceptance evidence through
`b2669c3fafe36b40f8f1897f48a954dcbf94a9bb` are retrieved and authenticated by the manifest.
The committed predecessor also retains the prior manifest and its exact older
source chain. Closed controller, storage, formal scope, input and observer
acceptance remains fully retrievable.
The complete predecessor is retained as well as the exact historical suffix;
these products overlap. No historical source bytes are discarded.

To recover the original file from the repository root:

```bash
git show b2669c3fafe36b40f8f1897f48a954dcbf94a9bb:docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
scripts/check_task_tree_integrity.pl
```

Current behavior and active contracts remain in the mdBook, decision 0109 and
the canonical cards `docs/knowledge/isf-direct-transaction-port-scope.md` and
`docs/knowledge/isf-generated-child-port-storage-shadowing.md`. Source binding
and generated pin shadows are qualified; production formal scope is recorded in
`docs/knowledge/isf-production-formal-scope.md`. Local
payload retention, writer analysis and independent execution remain open in
the live nodes. Source admission alone does not qualify their runtime.

The T1921 pre-exec setpgid EPERM remains an unresolved native occurrence under
`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.10`.
Its full recorded failure, date-only HDL comparison and successful separate
oracle execution survive in this exact history; no containment repair is claimed.
Preserve spent compiler/startup evidence and the resume pointer's audit capture.


Current record-input generated/domain source/carrier/public qualification and
the fixed failure-only observer integration are complete. Genuine direct HDL
behavior is qualified under .5.3; generated/domain execution, backend/input completion, record outputs
and full consumer signoff remain their own live leaves. The canonical response
is docs/SPECFORGE_FEEDBACK_RESPONSE.md. Binary-valued execution cannot establish
four-state X/Z behavior, and no historical native EPERM repair is claimed.


## Exact closed-history retirement `.64.2`

Legal boundary b2669c3fafe36b40f8f1897f48a954dcbf94a9bb is committed clean,
with both doctrine gates passed and brief empty. The unchanged bounded manifest
now authenticates its complete source and exact Completed Acceptance History
suffix. The previous single record remains in that committed predecessor;
its older source/suffix independently reconstructs, preserving the chain.
Complete source and suffix products overlap; no discarded bytes are claimed.
Python and independent Perl SHA/dimension census agree with every manifest
field, including JSON-number dimensions. Original live node contracts remain
byte-identical except owned .64/.2 dispositions. Active controller/formal,
feature/native limits and spent compiler/capture retention remain visible.

Actual read-only integrity passes. Plain same-volume fixtures resolve Git reads
to this project without creating a Git repository: correct rollover passes;
source/suffix digest corruption, string dimension, missing source boundary and
displaced live pointer reject. Independent changed-contract control rejects.
Tracked anchor census finds no consumers of removed acceptance headings. The
original product/test/checker, native observer and registration audit bytes
remain unchanged. Fixed direct runtime .60.4.3.2.5.3 is next; no feature HDL
execution, native retry, host-protection/privilege change, full CI or push.

- [x] **ROOT CAUSE (WHY + WHERE)** — git log -S locates the former Decisions rollover in 29ab49f217a82bacdd1ac83a8bcf2b687996f3ed; current accumulated closed acceptance is the scaling term approaching the unchanged milestone. Committed b2669c3fafe36b40f8f1897f48a954dcbf94a9bb supplies the legal unique boundary while every authoritative node and active native/feature limit precedes it. Exact source/suffix and old manifest retrieval establish the bounded retirement locus without changing the checker or policy.
- [x] **ADDRESSED (verified)** — The existing single-record manifest authenticates the complete predecessor and closed suffix with unchanged registry bounds and retention contract. Independent Python and Perl digest/dimension census agree. Every original node contract remains byte-identical except owned .64/.2 dispositions; prior manifest/source chain, active contracts and spent native evidence remain available. Actual correct-rollover fixture passes and corrupt source/suffix, string dimension, missing boundary, displaced pointer and changed-contract controls reject. Only closed optional prose is retired.
- [x] **NO REGRESSION** — Actual task-tree integrity reports all active task-tree invariants hold; independent full source/suffix/chain/node reconstruction and actual hostile checker controls pass. Product/test/checker and original/corrected observer/registration audit diffs are empty; removed-anchor consumer census is empty. Re-derivation uses exact Git objects plus distinct Python/Perl census and full original-node comparison; falsification uses real corrupted digest/dimension/boundary/pointer and changed-contract controls; tracked bounded manifest, authenticated audit, original retained Git objects, nodes/fact/book/pointer provide durability. The actual Knowledge Map check reports knowledge-map: OK and the book builds; staged doctrines remain required before normal hooks. No feature/native execution, other repository write, ceiling change, full CI or push.


## Genuine direct record-input observation `.60.4.3.2.5.3`

The clean committed qualified observer and .64/.65 continuity prerequisites
are consumed. Exact admission predeclares the three compile/runtime pairs.
Actual SystemVerilog and Verilog-family public-pin behavior passes every
literal bench vector and marker, including repeated requests and asynchronous
reset/abort; the intentionally unsigned same-width source reaches the expected
signed-property assertion. No unplanned native rejection occurs. Full stage
arguments/results, TAP/stdout/stderr, source/test/bench and admitted plus extra
producer Git identities are sealed in the observation archive. Generated HDL
and binaries follow normal temporary cleanup. Independent process/workspace
census finds no selected residue; successful-child PID identities were not
captured by the failure-only native hook. This is the precise artifact limit.

Re-derivation consumes actual complete stage receipts and exact Git blobs.
Falsification includes the actually compiled unsigned source and detached
hostile saved records for bounds, markers, cleanup, assertions, target, drift,
gaps, native events and negative result kinds. The immutable manifest/archive,
fixed source/bench/test, task nodes, fact/book/response and Git provide durability.
The first staged doctrine run rejects the new numeric book rows for missing
claim dispositions. Their independent literal-vector watcher also exposes an
unsigned display of the signed prior-held reset member: bits 10010 represent
-14 in this signed field. Correct signed table values, actual saved bench-word
and expected-literal derivation, and hostile wrong-value/missing-row controls
repair that P2 documentation defect within this owner; no HDL rerun is needed.
Explicit three-leg dispositions and the tracked watcher complete publication.
Four-state declarations have structural witnesses; binary Verilator values do
not establish X/Z behavior. Historical native causality remains P1-open, with
HIAL .11.6 scheduled before generated/domain runtime. No external repository,
submodule pin, original supervisor/observer, host protection or CI/push change.

- [x] **ROOT CAUSE (WHY + WHERE)** — Actual --emit-semantic-json and scheduled carrier checks bind the authored nested packed input and scalar leaf declarations to the independently literal test/bench. Source/carrier admission alone left direct runtime behavior unqualified. The fresh exact observer admission executes the real T2024 target; saved original results identify both positive targets and the deliberate unsigned PACKED_SIGNED_MISMATCH at tb.sv line 45.
- [x] **ADDRESSED (verified)** — Actual native HDL execution passes both emitted families, all literal entry/copy/live/reset/prior/hold vectors and complete request markers. The same-width unsigned authored property counterexample fails the unchanged public-pin predicate. Sealed independent verifier authenticates exact stage order/coverage, unchanged source/producer identities, original limits/arguments/results and cleanup and rejects corrupted saved evidence. Native events and diagnostic gaps are empty; historical EPERM remains unresolved.
- [x] **NO REGRESSION** — The genuine guarded T2024 observation reports All tests successful, Files=1, Tests=4 with runtime enabled and no skips; independent saved verification passes, exact production/test/bench/observer/supervision identities match before/after and every stage retains original cleanup. Focused T2024/T1994/T2018 and actual runnable-book T1376 pass All tests successful, Files=4, Tests=15 with this separate static T2024 runtime deliberately skipped. Actual task-tree integrity passes and Knowledge Map reports knowledge-map: OK; book build and staged doctrines complete before normal commit hooks. No broader profile or X/Z signoff is inferred.


## Generated/domain witness preparation `.60.4.3.2.5.4.1`

T2025 owns fixed independently authored sources for a named-domain spawned
whole copier and an ordinary parameterized blocking copier, each with reused
live readers. Parent phase outputs separate explicit entry sampling, generated
whole-copy and later live reads without inferring pipeline edges. The literal
bench observes every copied packed leaf, copier and reader scalar results,
signed comparisons, held reset/prior values, idle holds, repeated requests and
reset/abort. Changing the unused clock-only sibling input/clock is an isolation
control; it establishes no guarantee about reset-free initial state.

The first unqualified static run diagnoses two draft oracle errors. A
blocking-call completion guard was wrongly generalized to spawned bindings,
whose actual emitted assignments forward their child's registered output.
Prefixing individual artifact basenames also broke published same-directory
child lookup. Correct call-role literals and a complete unchanged-basename
artifact cohort repair those errors; a bound copier result explicitly contrasts
spawn and parameterized blocking call publication. No production defect or
source/profile widening follows. The retained first RED is projected only to
repository-relative paths in the preparation audit.

Actual source/caller JSON, exact roles, complete public/private wiring, strict
native every-carrier replay and both emitted families provide re-derivation.
Independently authored declarations, disabled actual private write enable and
an authored unsigned same-width property provide structural falsification.
Fixed source/test/bench, saved preparation records, fact/book/response, task
nodes and Git provide durability. Actual behavioral falsification and runtime
remain missing, owned by committed-observer .2 and genuine-observation .3.
Historical native causality, X/Z and full input/backend completion remain open.

- [x] **ROOT CAUSE (WHY + WHERE)** — Actual --check --json identifies failed child-source lookup after the first draft renamed emitted artifact basenames. Initial T2025 at line 91 also incorrectly expected the documented parameterized-do completion guard on spawned reader output forwarding. The actual complete carrier and blocking-call documentation establish those role/source-boundary loci. Existing source/structure qualification still lacks executed generated/domain behavior, so this slice prepares an independent fixed oracle before observer qualification.
- [x] **ADDRESSED (verified)** — T2025 checks independently literal packed declarations, complete caller JSON, exact artifacts/private roles/data/enable/wiring, owning and clock-only sibling facts, actual strict source/carrier products and both emitted families. Correct spawned versus blocking bindings and original artifact basenames pass. Disabled actual copy enable and actual equal-width unsigned declaration fail unchanged independent structural predicates. The fixed public-pin bench and actual unsigned HDL are prepared; runtime is explicitly skipped.
- [x] **NO REGRESSION** — Focused T2025/T2019/T2020/T2024/T2018 reports All tests successful, Files=5, Tests=23, retaining prior complete generated/public/package, direct sample and JSON-kind controls. Final readable T2025/runnable-book passes Files=2, Tests=6; book build and actual task integrity pass, Knowledge Map reports knowledge-map: OK, and the sealed saved preparation verifier rejects unrelated receipts. Staged doctrines complete before normal hooks. Production, previous direct/native archives, source syntax/schema/profiles and original supervision remain unchanged. This preparation does not qualify HDL behavior.


## Fixed generated-input observer qualification `.60.4.3.2.5.4.2`

The separately sealed generated_input observer admits exactly T2025, both
prepared source fixtures, the fixed public-pin bench and the complete declared
producer closure. Its distinct schema, mode and capture namespace predeclare
all positive and unsigned-negative compile/runtime pairs. Prior direct-input
and priority target authority cannot be reused. Detached admission inspection
preserves complete caller JSON kinds on both acceptance and refusal.

Fresh exclusive oct01gen finite controls pass with unchanged native helpers,
original stage bounds/arguments/results, exact outer stderr, silent success,
controlled real session rejection/context/errno and explicit modeled diagnostic
gaps. Independent captured child PID/group absence is checked after cleanup.
The sealed saved verifier authenticates the complete fixed feature identity
closure and rejects foreign targets, older coverage, omitted or additional
fixtures/producers and corrupted native/result/context/cleanup evidence.
No genuine feature HDL compiles or runs in this qualification. The actual
runtime observation belongs to .5.4.3 after this integration is committed.
The parent frontier retained a draft overgeneralization of completion guards;
reconcile it with the qualified literal call-role witnesses: spawned outputs
forward live child outputs, while parameterized blocking-do bindings are
completion-guarded. This bounded P2 task-prose defect is fixed within this leaf.

Owned P2 validation-artifact defect: this slice's mdbook invocation used
--dest-dir ../../.artifacts/mdbook-generated-input-observer-qualified. Actual
build output resolved from the repository root rather than the book directory,
placing this generated directory outside the repository. Read-only census
confirms no enclosing Git repository, no symlink, and the repository volume.
Fixed and verified within this leaf: copied the exact generated directory to
the repository-derived .artifacts destination, verified complete relative file
membership and bytes/hashes, successfully rebuilt at the correct local
destination, then deleted exactly the old owned output. Independent path
census confirms absence. The complete receipt is
docs/audits/generated-input-observer-book-placement-20261001.json. Future
invocation uses --dest-dir .artifacts/mdbook-generated-input-observer-qualified.


Actual complete finite receipts and exact identities provide re-derivation.
Controlled rejection, modeled gaps and hostile saved mutations provide distinct
falsification. Immutable archive/manifest, fixed source/bench, task nodes,
Knowledge Map, book/response and Git provide durability. Historical native EPERM
causality, X/Z and complete backend/input delivery remain separately owned.

- [x] **ROOT CAUSE (WHY + WHERE)** — git log -S '2024-isf-record-input-runtime.t' identifies the corrected direct observer's fixed-target introduction. Its RecordInputAdmission.pm target/coverage contract permits T2024 and three feature pairs; it cannot authorize prepared generated/domain T2025. Actual new pure/finite refusals identify old_target, wrong_count and omitted_fixture before any target execution. A separate exact target/fixture authority is required before genuine generated-input behavior can be observed.
- [x] **ADDRESSED (verified)** — Separate GeneratedInputAdmission, driver, finite controls and saved verifier bind the closed generated_input schema, exact T2025 target, complete producer/fixture identities and declared feature coverage. Fresh finite capture passes actual rejection/context and modeled diagnostic gaps; complete sealed verification authenticates original bounds/results/arguments and independent captured PID/group cleanup, with hostile corruptions rejected. Original helpers, direct observer and production/test/source/bench remain unchanged.
- [x] **NO REGRESSION** — Pure exact-target/fixture/caller-kind checks report All tests successful, Files=1, Tests=18. Fresh finite qualification reports All tests successful, Files=1, Tests=63; independent sealed saved verification passes. Actual Knowledge Map reports knowledge-map: OK; task integrity and corrected repository-local book build pass before staged doctrines and normal hooks. The owned misplaced-build defect is fixed and its verified copy/use/delete/residue record is tracked. No feature HDL execution, historical EPERM repair or broader profile signoff is inferred.


## First generated-input compile diagnosis `.60.4.3.2.5.4.3.1`

Fresh exclusive generated_input_oct01 executes the committed exact T2025
observer. Static original-source/carrier checks and the authored unsigned source
emission pass. The first named-domain SystemVerilog compile then rejects the
whole-copy composition link: wire is applied to a packed typedef containing
nested authored two-state bit members. No runtime or later pair executes.
This is a P1 accepted-source emitted-HDL defect, owned for immediate repair by
.5.4.3.2; actual generated behavior remains unqualified. No native process-group
rejection or diagnostic gap is captured, and historical EPERM remains open.

The complete failure is immutable in
`docs/audits/record-input-generated-observation-20261001/`. It retains exact
admission, original stage/summary/results/bounds/argv/cleanup, source and
producer Git identities before/after, complete TAP and independent selected
workspace/command absence. Only the exact active repository prefix in outer
stderr is projected away; the original stderr hash and complete stage record
remain. Successful native PID identities were deliberately uncaptured, so
individual PID absence is not independently measured. Normal cleanup removed
compiled temporary HDL/binaries. The unchanged source's strict public
re-emission is separately labeled diagnosis evidence rather than captured
original HDL bytes. The pre-result success-verifier draft is explicitly
unqualified and never passed or executed.

The re-emitted declaration and compiler member locations agree.
StructuralRTLIREmitter::_render_net_line unconditionally prefixes wire for its
typed-net branch; TypeDeclarationSupport faithfully renders nested two_state
leaves as bit. Existing T167 expects this mixed-state wire without a compiler
leg, explaining why structural/public qualification did not catch legality.
Actual retained rejection, complete identities and public re-emission provide
re-derivation. Hostile saved result/bounds/cleanup/identity/gap/coverage/target
mutations provide distinct falsification. Immutable archive, fixed source,
producer Git blobs, scheduled repair leaf, fact/book/response and Git provide
durability. Diagnose and commit before further HDL execution.

- [x] **ROOT CAUSE (WHY + WHERE)** — Actual %Error: domains_systemverilog.sv:1674:73 rejects comp_link_io__writer_isf_write_held_data because its typed wire contains the nested bit member at line 1636. Unchanged public strict source re-emission reproduces both locations. StructuralRTLIREmitter::_render_net_line applies wire to the preserved typedef, while TypeDeclarationSupport renders authored two_state members as bit. git log -S 'wire %s %s;' identifies introduction 3ca803fc8946140c172aeb97da26d66dd8830aee; T167's old structural oracle explicitly expects the illegal form.
- [x] **ADDRESSED (verified)** — This diagnosis slice seals the actual failed first compile, proves no runtime/later pair occurred, independently authenticates original source/producer identities and full rejection/bounds/arguments/cleanup, and reproduces its declaration through public emission without another HDL execution. Hostile saved failure/coverage/identity/native/gap/cleanup mutations reject. The product defect is scheduled immediately under .5.4.3.2 and remains unresolved; no feature success or historical native cause is inferred.
- [x] **NO REGRESSION** — The independent saved first-failure verifier passes complete archive/Git identity and hostile controls; unchanged strict public SystemVerilog re-emission succeeds. Original production, fixed test/source/bench, qualified observer/native helpers and earlier archives remain unchanged. Actual Knowledge Map reports knowledge-map: OK; task integrity and local book build complete before staged doctrines and normal hooks. The original genuine TAP is retained as FAIL, not relabeled a passing behavioral check.


## Typed composition declaration repair `.60.4.3.2.5.4.3.2`

Supported composition plans reserve each target's driver and create carriers
by one stable source-family key, adding only fanout targets. A variable-style
connection therefore preserves the supported connectivity contract. The shared
type renderer detects explicit two_state scalar leaves recursively across
ordered record members and list items. Structural emission uses the unchanged
aggregate typedef as a variable for those carriers; all-four-state aggregate
wire declarations and existing explicit variable declarations stay intact.
Explicit scalar two_state wire metadata similarly renders bit variables with
its existing width and signedness. This fixes the corresponding direct scalar
wire-bit declaration defect too. No layout, member model, ownership, clock or
pipeline edge changes; authored source, schema and supported lanes stay fixed.

T2026's independent literal declaration matrix retains nested record/list and
all-two-state/four-state controls, signed leaves and complete caller JSON.
Actual public strict emission of the unchanged failed source matches the sealed
full predecessor product except exactly the illegal carrier wire keyword and
generated date comments. The exact committed old emitter, preloaded from a
plain repository-local include tree, makes both matrix and full-product
subtests fail. It emits the actual illegal typed wires and wire bit scalar.
Focused and broader structural/typed/shared/generated/carrier/JSON controls
pass. Full saved old-emitter RED and positive receipts, source hashes/Git
identities and hostile receipt verification are sealed in
`docs/audits/typed-composition-carrier-repair-20261001/`.

Actual emitted complete products and literal declarations provide re-derivation.
The exact old-emitter counterfactual and hostile receipt substitution provide
independent falsification. Tracked code/tests, first genuine compiler failure,
immutable repair archive, fact/book/response/tasks and Git provide durability.
No additional HDL compiles or runs in this slice. Actual corrected compiler
and runtime qualification remains .3.3 after the fix commits, including fresh
complete current producer identities under the fixed observer's closed scope.
The P1 defect's executed closure, X/Z, reset-free initialization and historical
native causality remain open; prior spent evidence is untouched.

The first staged doctrine gate catches a final acceptance-text addition after
the pressure census: task_evidence total bytes exceed the recorded owned
transition allowance. Re-census final documents independently with Python and
Perl and refresh only the existing transition allowance, preserving every
inclusive ceiling and debt owner. No implementation test fails.


- [x] **ROOT CAUSE (WHY + WHERE)** — The retained actual %Error: domains_systemverilog.sv:1674:73 rejects a typed composition wire containing bit members at line 1636. StructuralRTLIREmitter::_render_net_line prefixes wire regardless of the preserved nested state model; its scalar branch similarly emits wire bit for explicit two_state metadata. Exact old-emitter T2026 RED shows the illegal aggregate and scalar declarations and fails the complete actual public source-product predicate. git log -S 'wire %s %s;' identifies 3ca803fc8946140c172aeb97da26d66dd8830aee as the typed-wire introduction. Supported LinkedPlanBuilder reserves unique target drivers and creates each carrier from one source-family key, so a typed variable preserves current single-source fanout.
- [x] **ADDRESSED (verified)** — Shared recursive explicit two_state-leaf detection selects unchanged typed variable carriers; explicit scalar two_state wire metadata selects bit variables. T2026's independent declaration matrix in both families preserves literal widths, signed/state models, all-four-state and legacy wire controls, existing variable carriers and complete caller JSON. Its actual failing source product changes only the illegal carrier declaration and date. Exact old emitter fails both subtests; corrected focused and regression cohorts pass. Actual native compiler/runtime closure is deliberately pending .3.3, not inferred from static repair.
- [x] **NO REGRESSION** — T2026/T167 reports All tests successful, Files=2, Tests=25. T2026/T167/T281/T278/T178/T2025/T2019/T2018 reports All tests successful, Files=8, Tests=49 with runtime explicitly disabled. Sealed saved repair and hostile receipt verification pass; first genuine failure, prepared target/source/bench and qualified observer/native/supervision bytes remain unchanged. Knowledge Map reports knowledge-map: OK; task integrity and local book build complete before staged doctrines and normal hooks. No broader backend or X/Z signoff is inferred.

## Acceptance — blocking partial observation diagnosis (2026-10-01)

Owner: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.4.3.3.1`. Sealed complete partial outcomes and diagnosis:
`docs/audits/record-input-generated-observation-corrected-20261001/`.
Re-derivation uses original complete stage receipts and unchanged public emitted
carrier/HDL, with the public schedule report. Independent hostile mutations and
the literal completion-value versus late-zero counterexample provide
falsification; the archive, source Git blobs, published binding contract,
tracked immediate repair and Git provide durability. The counterexample derives
logic behavior; it is not a recording of individual failed pin values.

- [x] **ROOT CAUSE (WHY + WHERE)** — Actual --emit-schedule-json of the unchanged blocking source reports copy_seen binding_timing done_guarded and main_copier_do_0_done. Actual carrier uses (= copy_seen child_result) under that pulse; emitted always_comb defaults the output to zero afterward. The child completes before parent phase 2 and later done. The bench at blocking_tb.sv line 48 wrongly requires copied nonzero data at that late parent done and during idle. The published composition contract agrees; P2 wrong witness timing, with other blocking values unqualified.
- [x] **ADDRESSED (verified)** — Saved verification authenticates all reached positive named-domain pairs, ordinary blocking compile and first runtime failure, exact committed producers, complete original bounds/results/arguments/cleanup and empty native events/gaps. The actual carrier/HDL and hostile saved mutations establish the bounded diagnosis. Immediate correction is scheduled under .2 before any further HDL run; complete generated runtime remains open.
- [x] **NO REGRESSION** — Independent saved verification passes without HDL replay and preserves all prior archives. Knowledge Map reports knowledge-map: OK; task integrity and local book build are checked before staged doctrine and normal commit hooks. No individual successful-child PID, remaining blocking values, unsigned runtime, X/Z or historical native causality proof is inferred.

## Acceptance — completion-window oracle correction (2026-10-01)

Owner: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.4.3.3.2`. Immutable correction, exact predecessor and
full positive/old-oracle receipts: `docs/audits/generated-binding-oracle-correction-20261001/`.
Re-derivation uses actual unchanged binding products and corrected fixed bench.
Independent temporal/packed literal counterexamples, exact old-bench RED and
hostile receipt/predicate mutations provide falsification. Sealed recipes,
source identities, task/book/response and Git provide durability. No HDL runs
in this slice; complete behavior is the fresh committed-authority next leaf.

- [x] **ROOT CAUSE (WHY + WHERE)** — Actual --emit-schedule-json and retained carrier/HDL under .1 establish copy_seen as done_guarded combinational output before phase 2. The old bench wrongly demands copied data at later parent done/idle; its genuine blocking run fails. Exact committed predecessor bench also fails the corrected independent window/role checks and lacks the required binding-role token. P2 oracle error, not a new production retention requirement.
- [x] **ADDRESSED (verified)** — T2025 declares each call role explicitly. The bench requires the copied value in phase 1, then distinguishes spawned forwarding from blocking default zero at parent completion/idle. Pure controls reject missing/late-only results, wrong retention and each packed leaf. Independent byte reconstruction protects all other original predicates and input timing; archived source fixtures and production/helper paths remain unchanged. Corrected current-hash preparation and unchanged saved observer qualification pass without scope widening.
- [x] **NO REGRESSION** — Focused T2025/fixed-admission checks report All tests successful, Files=2, Tests=23; structural/typed/shared/generated/carrier/caller-JSON cohort reports All tests successful, Files=8, Tests=50 with runtime explicitly disabled. Sealed exact predecessor/old-oracle and hostile verification pass. Knowledge Map, task integrity and local book build are checked before staged doctrines and normal hooks. Full generated runtime remains unqualified until fresh .3; no X/Z/reset-free/native claim is added.

## Acceptance — complete generated input runtime (2026-10-01)

Owner: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.4.3.3.3`. Re-derivation: complete original genuine
positive/negative stage receipts and fixed source/bench/producers. Falsification:
actually compiled same-width unsigned source reaches the unchanged signed
predicate, plus independent hostile saved scope/result/bounds/identity/cleanup
and published-vector mutations. Durability: sealed
`docs/audits/record-input-generated-observation-complete-20261001/`, fixed
qualified observer, committed source objects, task/book/response/facts and Git.
Native PID and X/Z/reset-free/historical-cause gaps remain explicit.

- [x] **ROOT CAUSE (WHY + WHERE)** — Actual --check --json strict carrier replay and retained public --emit-schedule-json provenance bind the fixed typed copier/readers, owning packed data/enable and done-guarded blocking result to the selected public-pin witness. Earlier real compile rejected the mixed-state typed wire; later real blocking execution rejected the wrong late-hold test. Their bounded committed repairs precede this fresh complete runtime. Source/carrier-only tests could not establish these executed behaviors.
- [x] **ADDRESSED (verified)** — Fresh generated_input_window_oct01 executes all admitted pairs on committed f606ce2. Named-domain and ordinary blocking sources pass both families with complete copy-window/packed-leaf/live/signed/entry/prior/repeated/reset/idle isolation checks. The actual unsigned source passes its bound-result window and reaches only the expected signed rejection. Complete original result/argument/bound/cleanup receipts and before/after Git identities authenticate; no skip, drift, native event or diagnostic gap.
- [x] **NO REGRESSION** — Genuine T2025 reports All tests successful, Files=1, Tests=5 with runtime unskipped and unchanged fixed sources/producers/helpers. Independent complete saved verification rejects hostile coverage, argument/bound/result/identity/cleanup/native-gap and signed-vector mutations. Knowledge Map, task integrity and local book build are checked before staged doctrines and normal hooks. Broader record-input/backend closure, full CI and historical native causality remain separately owned.

## Acceptance — generated execution reconciliation (2026-10-01)

Owner: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.4.4`. Requirement-to-evidence crosswalk and
complete public/saved receipts: `docs/audits/generated-input-execution-reconciliation-20261001/`.
Re-derivation uses actual current native/API/newline products and complete saved
positive/negative runtime. Independent literal layouts/roles, shared-corruption
and contextual-refusal oracles, actual unsigned rejection and hostile saved
receipt controls provide falsification. Exact baseline Git objects, sealed
receipts/prerequisites, tasks/book/response/facts and Git provide durability.

- [x] **ROOT CAUSE (WHY + WHERE)** — Actual --emit-semantic-json and --emit-schedule-json products in T2019 retain complete typed children, physical/public/private endpoints, owning clocks/reset and authored declaration snapshots. T2021 actual --check --json and semantic refusals preserve contextual/read-only/binding/shadow boundaries without partial success. Runtime alone could not close these public contracts or prior scalar/storage baselines; the crosswalk now joins their independent producer oracles to genuine execution.
- [x] **ADDRESSED (verified)** — Reconcile every selected generated/domain requirement against exact complete committed carrier/public and runtime evidence. Both fixed generated witnesses and the actual unsigned rejection are sealed; current public/package/refusal/scalar/domain-storage checks pass, and saved direct/generated hostile verification passes without HDL replay. Explicit variable carrier/type/private ownership and spawn/blocking binding semantics remain; no source, production, helper, arbitration or output-port change. Close .5.4 from recoverable evidence, preserving .5.5 backend/input closure.
- [x] **NO REGRESSION** — T2019/T2020/T2021/T1985/T1981/T1982 reports All tests successful, Files=6, Tests=39. Both complete saved runtime verifiers and independent crosswalk/hostile receipt verification pass. All tracked bin/perl/t/isf source matches baseline Git; Knowledge Map, task integrity and local book build are checked before staged doctrines and normal hooks. Full aggregate, X/Z/reset-free initialization, historical native cause and startup/full-CI/push qualification are not inferred.

## Acceptance — record-input backend profiles (2026-10-01)

Owner: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5.1`.
Re-derivation uses actual CLI and public pipeline generation plus literal
source/declaration identities. Independent false-success, signal, primary-only
reason and saved partial-product/destination/width substitutions provide
falsification. Complete sealed census/test/recipe/receipts and baseline Git
objects in `docs/audits/record-input-backend-profiles-20261001/`, task/book/spec,
canonical response and facts provide durability. No HDL executable qualification
or broader backend admission is inferred.

- [x] **ROOT CAUSE (WHY + WHERE)** — Actual public pipeline mixed-state record generation refuses unsupported packed struct member at perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm line 283; supplied typed record inputs refuse at that module line 232. Generated/domain tops retain the scoped composition target-support reason from PlanBuilder. The published scaffold admits scalar inputs and bounded inferred packed outputs, not these declared record profiles. Original complete census and error context are retained; primary-only controls prevent stack text from pretending to establish the reason.
- [x] **ADDRESSED (verified)** — T2027 qualifies every selected refusal through actual CLI and public pipeline, existing and absent destination controls and no partial successful product. Independent admitted scalar and packed-output entity/width/literal controls pass. The draft omitted .md from its expected final diagnostic link; the exact RED and correction remain preserved, with no production change. Saved independent verification rejects false success, stack-only reason, partial product, destination overwrite and width substitutions. Book/spec/scope/response and canonical fact state the qualified Verilog-family support and precise VHDL boundary.
- [x] **NO REGRESSION** — T2027/T1420/T386/T114 reports All tests successful, Files=4, Tests=453. Exact baseline selected source and producer Git objects and complete census products authenticate; no HDL compiler/simulator/analyzer executes. Knowledge Map, task integrity, book build and docs-path checks run before staged doctrines and normal hooks. Initial staged gate detects the missing fresh ISF-reference authority for the spec addition; independently measured baseline/delta and this owning authority are corrected with ceilings unchanged. The byte-exact immutable audit note uses notes.md.source alongside the sealed source copies rather than introducing an unclassified live document. The active-index row is shortened to current status/next action after its expanded historical prose triggers line-pressure classification; full evidence remains in canonical nodes and Git, with limits unchanged. Final public/corpus and selected-input signoff remain separate; X/Z, output/full consumer and historical native/startup/full-CI gates stay open.

## Acceptance — final record-input public reconciliation (2026-10-01)

Owner: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5.2`.
Re-derivation uses actual complete native/API/newline supplied/discovery products,
current cohort and literal schema descriptors, with exact unchanged prior
producer objects. Independent declaration/refusal/JSON-kind controls and saved
missing-row/applicability/schema/kind mutations provide falsification. Sealed
`docs/audits/record-input-public-reconciliation-20261001/`, prerequisite members,
exact Git objects, task/book/response/facts and Git provide durability. Final
selected-input signoff and full output/consumer delivery remain open.

- [x] **ROOT CAUSE (WHY + WHERE)** — git log -S traces the stale matrix pending-public/runtime sentence to aebe0037554eb9995c1d4fa67f4ec53f98364520. Book 13k's requested-record and packed-record-input rows did not advance with later committed complete generated/refusal/prior and direct/generated runtime qualification. Actual --check --json and --emit-semantic-json supplied/cohort products and discovery retain their already qualified metadata/schema; this is P2 documentation drift, with final input signoff and output delivery still open.
- [x] **ADDRESSED (verified)** — Only those matrix rows change; independent predecessor/current comparison preserves every other line and pending input/output/optional/XZ boundaries. Fresh complete supplied-source/all-section-discovery products, catalog and primitive-kind checks pass. Actual entire selected ISF cohort matches independent source/query identities; complete check/semantic/schedule descriptors match independent field/kind/order/state/null semantics. Unchanged complete-cohort/public/refusal/prior and saved behavior evidence authenticates; hostile missing membership/applicability/descriptor and numeric-kind substitutions reject. No production/test/source or HDL runtime change.
- [x] **NO REGRESSION** — T2017/T248/T2018 reports All tests successful, Files=3, Tests=7214; independent sealed reconciliation and hostile verification pass. All tracked bin/perl/t/isf paths match baseline f69a464cfdcbe00128bb3923cbd6921a913887c4. Initial staged gate catches resume-pointer line pressure; the pointer is shortened to its single next action with detailed scope retained here and limits unchanged. Knowledge Map, task integrity, docs paths/matrix and local book build run before staged doctrines and normal hooks. Full input signoff, X/Z, record outputs/full consumer and historical native/startup/full-CI remain separate.

## Acceptance — signed-scalar VHDL scope reconciliation (2026-10-01)

Owner: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5.3.1`.
Re-derivation uses actual fixed-source pipeline/facade controls and exact
scope/history objects. Independent literal positive/refusal tests and hostile
stale/operator/record-profile scope substitutions provide falsification.
Sealed `docs/audits/vhdl-scalar-scope-reconciliation-20261001/`, exact Git blobs,
canonical task/book/fact/response and Git provide durability. No production or
VHDL executable behavior is changed or newly qualified.

- [x] **ROOT CAUSE (WHY + WHERE)** — git log -S traces the blanket scalar-arithmetic refusal to 0f31a983ffaafb606b41e1e42c965523279f37db. Support ships in b4033eb3f62856b8d60d3554475883e13490dfcd; its exact diff updates other VHDL_SCOPE support bullets but leaves the old separate refusal. Current T1420 and T386 actual source generation qualifies one-bit signed +, -, * and RHS chains, retaining division/modulo and mixed-sign refusal. The contradictory maintained bullet is P2 documentation drift.
- [x] **ADDRESSED (verified)** — Replace that obsolete bullet and the related overbroad vector-only signed deferral with exact bounded xor/and support and precise remaining limits. Independent byte comparison protects every other scope line and the unsupported record-input boundary. Stale, operator-substituted and record-support mutations reject. Book, canonical fact and SPECFORGE response preserve the same supported profile and analyzer/runtime limits. Exact current backend/test/pipeline bytes match baseline b069b76; no implementation or HDL native execution changes.
- [x] **NO REGRESSION** — Focused pipeline/facade T1420/T386 reports All tests successful, Files=2, Tests=160. Independent saved history/source/receipt/scope and hostile verification pass. Initial staged doctrines catch the draft pinned-card mutation; restore the exact historical partition and add a separate dated reconciliation card. Knowledge Map, task integrity, docs-relative paths and local book build run before staged doctrines and normal hooks. Declared record VHDL and broad backend/executable parity remain unsupported; independent input signoff and output/full consumer qualification remain open.


## Acceptance — record-input language and authoring scope (2026-10-01)

Owner: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5.3.2.1`.
Original complete native arguments/results, exact converter/history objects and
current FSMGen-only text reproduce the scoped observation. Independently literal
syntax/argv and hostile missing-pair, selector, type-erasure and false-zero
JSON-kind controls falsify a broader claim. The version-matched published tool
contract, sealed `docs/audits/record-input-language-profile-20261001/`, baseline
producer objects, canonical docs/facts and Git provide durability. No new HDL
compiler or simulator is invoked; pure-mode failure is not claimed.

- [x] **ROOT CAUSE (WHY + WHERE)** — git log -S identifies the overbroad qualified-target recommendation at f69a464cfdcbe00128bb3923cbd6921a913887c4. Verilog.pm's procedural-only conversion predates the feature at 5de2f44d8e68b1124a3736c30e8479a005188768. Original T2024/T2025 argv use .sv DUTs and default SystemVerilog parsing; current packed typedef emission does not establish IEEE 1364 syntax. The inherited all-interface refusal in the storage walkthrough traces to aa2404ebe7822c53c048460abf7d10961924da12 and contradicts actual admitted record inputs. Both P2 prose defects are owned here.
- [x] **ADDRESSED (verified)** — Correct the supported-profile recommendation and walkthrough; book/spec/feedback/facts distinguish both genuine emitter observations under SystemVerilog parsing from unqualified Verilog-2005. All six actual direct/domain/blocking emissions retain independently expected packed signed/two-state syntax. Original full positive and unsigned-negative receipts authenticate without replay; exact book replacement comparison protects other bytes. Selector, missing-pair, type-erasure and false-zero JSON-kind mutations reject. Record-output/root-list/transaction boundaries remain closed. Sibling .2 owns precise target-profile admission or refusal before final signoff.
- [x] **NO REGRESSION** — T1305/T1414/T1303 reports All tests successful, Files=3, Tests=310; mdBook builds. Both original runtime verifiers and the new complete saved emission/argv/source/history/scope verifier pass. bin/perl/t/isf bytes remain baseline 40a51936. Initial staged claim dispositions rejects the new standard-name sentence as an unreviewed numeric candidate. IEEE 1364/Verilog-2005 are reviewed structural identifiers; the actual semantic qualification limit retains the sealed argv/emission evidence. Add that exact disposition in required candidate-ID order and regenerate the inventory after final measured-capacity edits without weakening completeness. Knowledge Map, task integrity, capacity/claim inventory and staged doctrines run before normal commit hooks. One final staged run is stopped by the unchanged RAM guard at host 88.0%, exit 137; named children 69305/69480 are absent in an independently escalated read-only ps census. The initial sandbox census refuses; escalation succeeds. Preserve the cutoff and rerun only after headroom returns. No unrelated process is changed. No HDL tool invocation, spent native replay, X/Z qualification or broader backend/signoff closure follows.

## Acceptance — precise record-input Verilog refusal (2026-10-01)

Owner: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5.3.2.2`.
Actual CLI/facade source-to-HDL queries re-derive the selected boundary; literal
actor/input/type expectations, unsupported-success/signal/secondary-message and
saved guard target/direction/validation mutations provide falsification. Complete
receipts, baseline Git objects, sealed producer snapshots, canonical documentation
and Git provide durability. No native HDL execution follows from this slice.

- [x] **ROOT CAUSE (WHY + WHERE)** — Original T2028 reports Failed 5/8 subtests: Verilog/v emits packed record inputs and replaces destinations instead of the selected unsupported-profile refusal. The converter changes procedural forms without qualifying record syntax; prior git log -S and sealed language-profile evidence locate this boundary. Draft actual status is 255/signal 0 because the existing CLI lowering error path dies after the profile exception. Actual --check --json probe also exposes implementation stack text. A distinct shared profile guard and dedicated normal-failure handler address these exact mechanisms; legacy .fsm/storage standards qualification stays under .60.4.3.5.1.
- [x] **ADDRESSED (verified)** — The shared validated declaration guard refuses Verilog/v only for ISF record inputs before lowering/publication. Final T2028 reports Files=1, Tests=10, Result: PASS; imported/unused/direct/generated/supplied inputs retain exact reasons, normal status 1, machine reports, facade refusal and destination atomicity. Target-neutral schedule metadata remains available. Complete SystemVerilog products equal the committed predecessor except date banners; scalar Verilog and SystemVerilog storage controls pass. Original RED/draft evidence is preserved; hostile target/direction/validation and actual false-success/signal/secondary-diagnostic controls reject. Existing native archives are immutable; changed future test membership requires fresh HIAL admission.
- [x] **NO REGRESSION** — Seven-file focused regression reports All tests successful, Files=7, Tests=7328, Result: PASS before the final diagnostic-format change; final T2028 verifies that exact latest change and full SystemVerilog equivalence. Docs T1305/T1414/T1303 reports All tests successful, Files=3, Tests=310; mdBook builds. New helper, facade and CLI report syntax OK. Both original saved runtime verifiers and the new sealed profile verifier pass without HDL execution. Task integrity, Knowledge Map, measured capacity, claim inventory and staged doctrines precede normal commit hooks. The first staged gate rejects an audit README outside registered live-document surfaces; preserve its scoped evidence prose as the normal sealed scope.txt member and reseal, without expanding a surface or weakening the gate. No X/Z, VHDL runtime, legacy aggregate profile or full consumer signoff is claimed.

## Acceptance — selected record-input delivery (2026-10-01)

Owner: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5.3.2.3`.
Current source/native/API/newline products and exact original receipt/Git identities
re-derive the selected requirements. Independent layout/type/context literals,
actual compiled unsigned counterexamples and hostile incomplete/width-only/parser
joins provide falsification. The complete sealed requirement join, canonical
book/feedback/fact and Git provide durability; original HDL is never replayed.

- [x] **ROOT CAUSE (WHY + WHERE)** — The selected contract splits input portions of R1–R3 from required outputs/field writes. Exact current --check --json, semantic and schedule controls join complete native/API/newline products, contextual refusals, packed metadata and preserved supplied sources to original native behavior. Production Git comparison since the generated observation names only the separately qualified CLI/facade/shared profile integration; lowering/source/bench bytes are unchanged. Book inherited pending statements and T1305's old pending-status literal still describe an earlier frontier. The first docs band fails exactly that status row after justified promotion.
- [x] **ADDRESSED (verified)** — The sealed requirements join covers all selected input aliases, scalar contexts/samples, exact-type owned copies, layout/carriers/public reports and supported execution/profiles. Current T2014/T2016/T1998 reports All tests successful, Files=3, Tests=42; every selected saved verifier passes without native replay. Missing clauses, width-only identity and parser-scope mutations reject. Promote the bounded input matrix row, reconcile stale current book/fact/feedback status and its exact T1305 expectation. Close satisfied input parents only; output writer ingress .60.4.3.3.1 becomes the next pending leaf.
- [x] **NO REGRESSION** — T1305/T1414/T1303 reports All tests successful, Files=3, Tests=310 after the exact single-row status update; mdBook builds. Current source/public checks and complete immutable prior verifiers pass; no behavioral oracle or original receipt changes. Only input closure is claimed: outputs/field writers/full aggregate consumer, X/Z, reset-free guarantees, VHDL runtime, legacy .fsm Verilog standards qualification and historical native/startup/full-CI gates remain owned. Knowledge Map, task integrity, measured capacity, claim inventory and staged doctrines precede normal commit hooks.
