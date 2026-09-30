# SEMANTIC-INTROSPECTION-MCP-FRONTIER: Semantic Introspection And MCP Frontier

## Metadata

- Tree ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER`
- Status: `active`
- Roadmap lane: `Embedding And Public APIs / AI integration`
- Created: `2026-06-14`
- Last updated: `2026-09-30`
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
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.4, SEMANTIC-INTROSPECTION-MCP-FRONTIER.5, SEMANTIC-INTROSPECTION-MCP-FRONTIER.6, SEMANTIC-INTROSPECTION-MCP-FRONTIER.7, SEMANTIC-INTROSPECTION-MCP-FRONTIER.8, SEMANTIC-INTROSPECTION-MCP-FRONTIER.9, SEMANTIC-INTROSPECTION-MCP-FRONTIER.10, SEMANTIC-INTROSPECTION-MCP-FRONTIER.11, SEMANTIC-INTROSPECTION-MCP-FRONTIER.12, SEMANTIC-INTROSPECTION-MCP-FRONTIER.13, SEMANTIC-INTROSPECTION-MCP-FRONTIER.14, SEMANTIC-INTROSPECTION-MCP-FRONTIER.15, SEMANTIC-INTROSPECTION-MCP-FRONTIER.16, SEMANTIC-INTROSPECTION-MCP-FRONTIER.17, SEMANTIC-INTROSPECTION-MCP-FRONTIER.18, SEMANTIC-INTROSPECTION-MCP-FRONTIER.19, SEMANTIC-INTROSPECTION-MCP-FRONTIER.20, SEMANTIC-INTROSPECTION-MCP-FRONTIER.21, SEMANTIC-INTROSPECTION-MCP-FRONTIER.22, SEMANTIC-INTROSPECTION-MCP-FRONTIER.23, SEMANTIC-INTROSPECTION-MCP-FRONTIER.24, SEMANTIC-INTROSPECTION-MCP-FRONTIER.25, SEMANTIC-INTROSPECTION-MCP-FRONTIER.26, SEMANTIC-INTROSPECTION-MCP-FRONTIER.27, SEMANTIC-INTROSPECTION-MCP-FRONTIER.28, SEMANTIC-INTROSPECTION-MCP-FRONTIER.29, SEMANTIC-INTROSPECTION-MCP-FRONTIER.30, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32, SEMANTIC-INTROSPECTION-MCP-FRONTIER.33, SEMANTIC-INTROSPECTION-MCP-FRONTIER.34, SEMANTIC-INTROSPECTION-MCP-FRONTIER.35, SEMANTIC-INTROSPECTION-MCP-FRONTIER.36, SEMANTIC-INTROSPECTION-MCP-FRONTIER.37, SEMANTIC-INTROSPECTION-MCP-FRONTIER.38, SEMANTIC-INTROSPECTION-MCP-FRONTIER.39, SEMANTIC-INTROSPECTION-MCP-FRONTIER.40, SEMANTIC-INTROSPECTION-MCP-FRONTIER.41, SEMANTIC-INTROSPECTION-MCP-FRONTIER.42, SEMANTIC-INTROSPECTION-MCP-FRONTIER.43, SEMANTIC-INTROSPECTION-MCP-FRONTIER.44, SEMANTIC-INTROSPECTION-MCP-FRONTIER.45, SEMANTIC-INTROSPECTION-MCP-FRONTIER.46, SEMANTIC-INTROSPECTION-MCP-FRONTIER.47, SEMANTIC-INTROSPECTION-MCP-FRONTIER.48, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49, SEMANTIC-INTROSPECTION-MCP-FRONTIER.50, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51, SEMANTIC-INTROSPECTION-MCP-FRONTIER.52, SEMANTIC-INTROSPECTION-MCP-FRONTIER.53, SEMANTIC-INTROSPECTION-MCP-FRONTIER.54, SEMANTIC-INTROSPECTION-MCP-FRONTIER.55, SEMANTIC-INTROSPECTION-MCP-FRONTIER.56, SEMANTIC-INTROSPECTION-MCP-FRONTIER.57, SEMANTIC-INTROSPECTION-MCP-FRONTIER.58, SEMANTIC-INTROSPECTION-MCP-FRONTIER.59, SEMANTIC-INTROSPECTION-MCP-FRONTIER.60`

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
  Status: `active`
  Goal: `Rollover the saturated decision-record collection while preserving exact history and active contracts.`
  Acceptance: `Immediately after .32.1.3.3.1.2.1, audit the rationale collection and its declared lifecycle under LIVE_DOCUMENT_SIZE_CONTAINMENT.md. Select the smallest semantic rollover that restores bounded current decision capacity without losing active policy, stable decision identities, exact historical text, relative links or Knowledge Map answers. Follow the atomic classification/reconstruction/index/retrieval protocol; split safe leaves before writes, prove source identity and semantic closure separately, add enforcement and negative controls where needed, synchronize reader guidance and commit. Do not merely increase rollover allowance or reclassify overflow to evade containment. Then resume controller contract .32.1.3.3.1.2.2.`
  Verification: `The staged gate for predecessor .32.1.3.3.1.1 reports rationale at 9663 lines and rollover_debt. Registry baseline 7996 plus growth 1667 exactly reaches that current use; the collection ceiling remains 10000. Local policy forbids ordinary allowance growth on rollover debt. This is a decision-record capacity prerequisite, not a request to weaken containment.`
  Commit: `pending`

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
  Status: `active`
  Goal: `Contain decision identity and index cardinality before file-count rollover.`
  Acceptance: `Activate before an added record would enter the rationale file-count rollover band. Audit stable external and generated provenance identities, select bounded identity/index partitions with exact retrieval, preserve all policy authority and record links, qualify negative navigation controls and commit without widening the file ceiling. This future warning-pressure task does not block controller contract adoption after .51.2.`
  Verification: `Root aliases deliberately preserve file cardinality. The .51.2 line/byte rollover leaves explicit warning_debt. Admission .60.4.3.2.3.5.2 observes a new staged record crossing the file-count rollover band: 116/128, 90.6%, rejected by the unchanged gate. Consolidating its redundant draft into canonical 0113 completes that dirty slice; .51.3 is the immediate clean-state prerequisite before more record growth, then frontend matrix .60.4.3.2.3.6 resumes.`
  Commit: `pending child qualification`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.1`
  Status: `done`
  Goal: `Audit exact decision identity, index and consumer cardinality before selecting rollover.`
  Acceptance: `At a fixed clean predecessor, census every decision identity, sealed original/forwarding page, current canonical body, index entry, front-matter identity and incoming tracked link/body/provenance consumer. Reconcile membership and per-file dimensions/digests with independent Git enumeration and published reader results. Separate external path compatibility from mutable fact storage and generated navigation; select a bounded semantic partition/identity contract with exact retrieval and retained policy/Knowledge Map answers. Record alternatives and limitations honestly, commit the audit before moving records, and do not increase ceilings or infer external consumer absence from repository search.`
  Verification: `Fixed source 25c01f0127144922ade78951b91439e1d9221c08 has exact IDs 0001-0114 and INDEX: 115 root files, 50 sealed forwarders and 64 canonical bodies; the next root record enters the unchanged 128-file target's rollover band. Tracked bounded producer/census reconcile per-ID index destinations and per-file dimensions/digests with an independent direct-directory Git enumeration and literal full ID set. Every pinned public sealed-reader result equals its independent Git source. Final replay is byte-for-byte equal despite current owned doc changes; explicit no-submodule recursion and same-volume captured-reader fixtures close ambient-input drift. Scoped basename/fragment consumers and separate generic code candidates identify stable provenance, four literal fragment destinations, T1809's direct body read, 0062/0091 self-searches and flat-only ceiling-authority validation. Canonical 0108 selects a finite pre-transition compatibility cohort plus current continuity/language-API/verification partitions, with exact authority/status/question/source/navigation preservation and no ceiling increase. Full atomic integration and fresh-record capacity remain .2-.3. Guarded T1999/T1923/T1554 reports All tests successful, Files=3, Tests=22; equal-count duplicate/substitution/misroute and missing/escape controls refuse. Syntax and book build pass. Source-bound census/search exclusions, current/generic reader differences and external/dynamic limits are explicit; no migration, external consumer signoff or native execution is claimed.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2`
  Status: `active`
  Goal: `Apply the selected bounded decision identity/index rollover atomically.`
  Acceptance: `After .1, split implementation prerequisites if needed, then preserve every pre-transition path/identity and exact original retrieval while placing mutable canonical records and navigation in bounded semantic partitions. Freeze any finite compatibility projection by exact source/membership proofs; never create unbounded alias growth. Update readers, metadata consumers, indexes and declared surfaces together, preserve stable question/answer and policy authority, and qualify corrupt/missing/duplicate/misrouted navigation controls. Restore legitimate current capacity without raising predecessor ceilings or merely relabeling overflow.`
  Verification: `Audit/contract selection is committed at 8acfa9c087f971706fd35a3755d208792d27076f. Split pure catalog/path/identity controls, actual reader/authority integration, and atomic storage/navigation rollout before changing source locations. Every first admitted canonical path must use complete identity and retrieval gates.`
  Commit: `pending child qualification`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.3`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.1`
  Status: `done`
  Goal: `Prepare closed decision catalog/path/identity controls before live integration.`
  Acceptance: `Define and independently qualify the bounded canonical location and catalog contract selected in 0108: finite pre-transition root identities, current continuity/language-API/verification parts, exact ID-to-source/type/status/question metadata, immutable original retrieval and compatibility headings. Reject escaping/symlinked/unknown-topic paths, duplicate or substituted IDs, malformed dimensions/digests, unresolved sources and borrowed identities. Preserve caller values and existing published sealed-reader/flat authority behavior; no source moves or live canonical authority admission yet. Keep one canonical identity authority across eventual Python reader and Perl gate consumers, then commit before wiring.`
  Verification: `The pure shared Python preparation module defines closed current parts, per-ID source paths/types/metadata/headings and independently supplied immutable originals. Literal future-store fixtures establish exact products, detached success/failure callers and fresh IDs without compatibility growth; borrowed sealed/body/fact IDs, supported-topic misroutes, duplicate/reordered/missing cohorts, copied metadata, invalid dimensions/digests, unresolved files and symlinked parent components refuse. Selected snapshot bytes use the same identity contract. Initial transition metadata is exact; subsequent owned status changes retain original text. Every actual current canonical body parses within the grammar. Guarded T2000/T1999/T1923/T1560/T1554 reports All tests successful, Files=5, Tests=32. Existing public reader and flat authority code/storage are unchanged. Canonical 0108 documents the closed schemas, bounded helper and caller source-authentication duty; .2 integrates actual reader/authority gates before .3 moves sources. Syntax and book checks accompany this commit.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2`
  Status: `active`
  Goal: `Integrate catalog-aware public reading and fresh authority paths before source rollout.`
  Acceptance: `After .1, connect qualified identity/path/retrieval gates to the published reader, complete index/heading verification and ceiling-authority addition boundary using independent supplied future-store fixtures. Preserve existing read/check/unknown-ID behavior where no delivered catalog exists, legacy flat authority identities and generated provenance strings. Qualify accepted current/original products and precise malformed/duplicate/stale/misrouted/missing-source failures; no partial output or unowned canonical admission. Keep real source paths unchanged until .3, then commit.`
  Verification: `Pure shared catalog/path/identity controls are qualified under .1. Integrate published reading, navigation and fresh authority validation using complete supplied future-store fixtures before moving real sources.`
  Commit: `pending child qualification`

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
  Status: `active`
  Goal: `Integrate exact catalog-aware canonical addition into ceiling-authority validation.`
  Acceptance: `After .1-.2, use the same authenticated store/identity contract for new canonical decision authority in actual staged/worktree/committed modes. Preserve legacy flat authorities and their exported paths; only exact resolved newly added canonical catalog IDs may authorize a same-change ceiling increase. Reject unknown parts, borrowed/substituted IDs, malformed/missing/stale source/catalog/index products, snapshot/worktree disagreement and reused/orphan authority. Continuously preserve prior selected-catalog ID/path/type/fact identities and question keys for every catalog change, including post-transition births; never permit deletion or recycling merely because an ID is absent from the fixed original census. Use complete independent Git fixtures, keep ceilings unchanged, qualify relevant gates and commit before real source rollout .3.`
  Verification: `Pending shared authenticated store/public-reader integration. Owned P2 prototype continuity gap: a supplied store admits fresh 0115; deleting its current row/body and both navigation rows restores a self-consistent snapshot which standalone current validation accepts. Root cause: the immutable source census necessarily covers only the transition cohort, so later births need prior-to-current catalog identity comparison. Resolve unconditionally at the actual selected Git boundary before live rollout, not merely when a ceiling increase occurs; qualify deletion/reuse/lost-new-fact controls.`
  Commit: `pending child qualification`

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
  Status: `active`
  Goal: `Qualify complete canonical authority and identity continuity across all selected modes.`
  Acceptance: `After .2, exercise actual public and Perl boundaries with independent complete staged/worktree/committed Git fixtures, including successful fresh authority and ordinary catalog growth/update with no increase. Plant equal-count deletion/reuse/path/type/fact/question substitutions, source/index/original corruption, stale descriptors/indexes/pages, symlink/conflict/missing data, mixed snapshots and reused/orphan authority. Prove legacy controls and default production pin isolation, run focused relevant gates/book/doctrines, commit and hand off cleanly to atomic real rollover .51.3.2.3.`
  Verification: `Shared accessor/continuity, actual public selection/adoption products and actual unconditional Perl integration are qualified under siblings .1-.2. Expand independent hostile store/authority controls across every selected mode, include bounded IPC and malformed request/caller controls, then hand off to the atomic rollover.`
  Commit: `pending`
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2.3.3.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2.3.3.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2.3.3.1`
  Status: `done`
  Goal: `Qualify post-transition identity and fact/question continuity independently in every selected gate mode.`
  Acceptance: `Publish an independently literal post-transition fact-bearing birth, then plant self-consistent deletion/equal-count recycling, path/type changes, fact deletion/replacement, question deletion/equal-count substitution and earlier-gap birth in separate worktree/staged/committed fixtures. Prove each current snapshot passes standalone authentication/navigation yet the actual Perl prior-current gate refuses it, with no ceiling increase to trigger the check. Prove additive owned content/status/summary/question updates pass all modes. Retain complete source/index/original/control baselines, same-volume fixture cleanup and legacy controls; synchronize book/evidence and commit before other hostile product/authority/IPC qualification.`
  Verification: `Each independently literal fixture publishes post-transition 0115 with a fact ID and question keys before mutation. Every current deletion/equal-count birth replacement/path/type/fact deletion or replacement/question deletion or equal-count replacement/earlier-gap birth has consistently updated bytes, metadata and complete root/part navigation. Actual standalone selected authentication passes each, then the actual Perl prior comparison refuses every case in worktree/staged/committed modes without a ceiling increase. Owned content/status/summary changes and additive questions pass every mode. Complete source/index/original/control baselines remain exact; each same-volume fixture is cleaned. Initial guarded T2006 passes Files=1, Tests=2; final T2006/T2005/T2004/T2003/T1560 passes All tests successful, Files=5, Tests=16. Book, syntax and bounded gates accompany the workflow; next child .2 completes malformed product/authority/caller/IPC qualification before atomic rollover.`
  Commit: `this commit`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.2.3.3.2`
  Status: `active`
  Goal: `Qualify malformed stores, authority/caller isolation and bounded IPC refusal before atomic rollout.`
  Acceptance: `After .1, plant complete malformed source/index/original/descriptor/navigation/alias and unsafe file controls across selected modes; exercise fresh/borrowed/reused/orphan/misrouted authority, production/default pin isolation and malformed public fingerprint/request inputs. Exercise actual bounded stdout/diagnostic draining, malformed products and signal failure using project-owned controlled dispatch fixtures. Repair and own any reproduced boundary defect, preserve all historical reader/flat authority behavior, run focused complete gates/book/doctrines and commit a clean frontier for atomic rollout .51.3.2.3.`
  Verification: `Independent self-consistent post-transition identity/fact/question controls and additive owned updates are qualified in all modes under child .1. Complete remaining malformed product/authority/caller/IPC controls, repair reproduced defects and commit before real atomic rollover.`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.2.3`
  Status: `pending`
  Goal: `Roll over canonical decision storage and navigation atomically through integrated gates.`
  Acceptance: `After .2, take a fresh exact pre-transition census, preserve complete original bodies separately from relocated current rendering, freeze finite compatibility paths/headings and place current bodies/indexes in the selected semantic partitions. Update self-searches and direct body readers, declarations, source links and Knowledge Map routes together. Prove exact source identity, unchanged authority/question/metadata keys, relative destination closure, complete reader products and no loss residue; restore current capacity without widening ceilings. Run focused relevant gates and book, commit, then hand off broad fresh-record/consumer continuity to .51.3.3.`
  Verification: `pending reader/authority integration`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3`
  Status: `pending`
  Goal: `Qualify complete decision continuity and new-record capacity before resuming frontend work.`
  Acceptance: `After .2, independently reconstruct every transition source and public identity, resolve complete tracked navigation/provenance/body consumers, compare exact Knowledge Map question/answer closure, and exercise successful fresh record growth plus planted known-bad alias/index/retrieval controls. Run relevant reader, containment, claim, memory and doctrine gates; synchronize user retrieval guidance and handoff pointer, commit, then resume .60.4.3.2.3.6 with a clean tree. Report finite external-consumer limits instead of asserting unseen integrations passed.`
  Verification: `pending atomic rollover`
  Commit: `pending`

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
  Status: `active`
  Goal: `Deliver packed record inputs, scalar field reads and whole input-to-storage copies.`
  Acceptance: `After .3.1, split further as needed before implementation. Admit local/imported resolved record roots, existing nested scalar paths and same resolved record-type copies. Qualify all existing scalar-expression contexts and declared input-write refusals, type/path mismatches, whole-record scalar-context refusal, unused ports, domain ownership and generated-child routing. Compare public IAL0 replay, independent packed-value HDL observations and complete native/API/newline products under HIAL admission; preserve scalar/storage-only sources and publish supported examples.`
  Verification: `Declaration metadata is qualified. Split before input source changes into ingress/qualification design, closed type/role preparation, parser admission with mandatory value gates, generated/domain carrier qualification and native/public completion. No record source form is newly admitted by this decomposition.`
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
  Status: `active`
  Goal: `Admit record inputs with qualified scalar reads and same-type copies.`
  Acceptance: `After .2, admit only local/imported resolved record input roots and wire all applicable transaction, rule, named-drive, enum-disambiguation and domain validators; qualify scalar leaf entry/body sampling width/type and existing capture timing while whole-record inferred samples refuse. Copies from an input to actor storage must use qualified recursive type identity from first admission; input writes and whole-record scalar contexts refuse. Root lists, outputs and transaction-local aggregate ports retain precise boundaries. Qualify nested paths, symbolic alias equivalence, lexical shadows, invalid members/types/roles and complete emitted IAL0 replay; synchronize accepted public reports and book.`
  Verification: `Pure type/path/role gates are qualified. Split before source mutation into contextual/lexical ingress review, scoped AST/enum gate preparation, scalar-leaf sampling carriers, domain-root protection, first source admission and frontend/public replay qualification. All mandatory value/role/type/domain/sampling gates must precede admission; record source ports remain refused during preparation.`
  Commit: `pending child qualification`


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
  Status: `pending`
  Goal: `Qualify frontend delivery and public replay before carrier/runtime completion.`
  Acceptance: `After .5, independently verify accepted local/imported/nested/shadow sources, all contextual failures, exact metadata/type/layout identities and complete native/API/actual newline check/semantic/schedule/discovery products. Strict-replay every emitted IAL0 carrier; preserve pre-change scalar/storage controls and exact source provenance. Close frontend work only with synchronized references while generated/domain behavior and independent native completion remain separately owned by .2.4-.2.5.`
  Verification: `Authored admission .5.2 is qualified; next independently complete the imported/nested/nearest-shadow public frontend matrix before generated/domain/native completion.`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4`
  Status: `pending`
  Goal: `Qualify generated and named-domain record-input carriers.`
  Acceptance: `After .3, independently exercise live record reads and valid input-to-storage transfers through existing generated-child/domain ownership, including nested/imported aliases, reused instances and unused declarations. Preserve explicit top interfaces, typed private connections, reset/storage ownership and unchanged old sources; refuse unowned crossing and unqualified input targets. Split actual prerequisite fixes before mutation and retain backend-profile boundaries.`
  Verification: `pending source admission`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5`
  Status: `pending`
  Goal: `Qualify packed input behavior and complete public delivery.`
  Acceptance: `After source/carrier qualification, consume current HIAL admission before genuine supervised native runtime. Independently observe packed layout, scalar signed/state properties, live versus explicitly sampled reads, whole-copy edge, holds, repeated requests and reset/domain behavior. Compare complete native/API/actual newline source/schedule/semantic/discovery products, supported corpus and baseline carriers/HDL. Keep unsupported profiles precise and synchronize all selected requirements/book/records; close input delivery only with recoverable behavior evidence.`
  Verification: `pending qualified carriers and HIAL admission`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3`
  Status: `pending`
  Goal: `Deliver record outputs and whole copies with physical writer admission.`
  Acceptance: `After qualified input delivery, map whole output writers to scoped physical packed roots. Preserve input/output roles, actor ownership, source-order semantics and existing exclusion/compatibility proofs. Refuse unresolved overlap, type mismatches and unqualified generated writers. Split any prerequisite repair before changing source; independently qualify hold, timing, repeated requests, reset and domain behavior and all public surfaces.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.4`
  Status: `pending`
  Goal: `Deliver scalar output fields with qualified packed-range overlap.`
  Acceptance: `After whole outputs and demonstrated physical target/writer prerequisites, admit scalar leaf writes in existing supported contexts. Independently distinguish disjoint members, same-value compatible overlap, whole/member overlap and conflicting writers; do not infer arbitration. Preserve unaddressed fields and original write edges under the applicable assignment contract. Qualify nested paths, domains, generated ownership, diagnostics, public replay/runtime and report/corpus/book alignment.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.5`
  Status: `pending`
  Goal: `Qualify affected backend profiles and unchanged source controls.`
  Acceptance: `After required implementation slices, qualify direct SystemVerilog/Verilog and supported VHDL profiles separately, imports, explicit interfaces, compositions and report metadata. Unsupported combinations must fail contextually. Preserve supplied baseline and scalar/storage/generated handoff controls, complete native/API/newline parity, capability/corpus/spec/book alignment and recoverable artifacts; do not close .60.4.4 from lint or parser acceptance alone.`
  Verification: `pending`
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

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.62`
  Status: `done`
  Goal: `Reject malformed reset clauses instead of silently selecting a different reset policy.`
  Acceptance: `P1 reset-policy correctness follow-up immediately after the current provenance implementation commit and before consumer closure. Reproduce unknown timing/polarity tokens and extra operands through strict public queries; Parser::_parse_reset currently loops recognized tokens and ignores all other values. Own exact accepted/rejected grammar, preserved valid shorthand and domain behavior, precise diagnostics, native/API/newline failure equality and book/spec alignment. Split if the compatibility census reveals an intended accepted alias; do not speculate that parse success proves authored reset intent.`
  Verification: `Parser closes reset arity and options while retaining explicit sync, suffix inference, modifier order and undefined Lispish tails. A late public probe exposed authored () collapsed to undef by own normalization; reset payload normalization now preserves empty lists for rejection, without changing other contexts. Final T1979 Files=1, Tests=3 PASS; normalizer/storage/output/timing/provenance regressions Files=10, Tests=43 PASS, including complete unchanged valid-source carriers and HDL. Ordinary/strict native check and semantic failures, API/newline equality and schedule refusal qualify the fix; no simulator executed. Historical singleton-tail handling at 8dc7bb3d6f262be760bbe11ca1ec968bf6bdd792 is preserved. Lossless red/intermediate/final logs, public AST cause capture and exact identities: docs/audits/isf-reset-grammar-20260930/. Book/spec/downstream and canonical fact align; .60.3.4 is next.`
  Commit: `this commit`

## Reset question scope disposition

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.61`
  Status: `superseded`
  Goal: `Disposition the inferred implementation-configurable reset follow-on.`
  Acceptance: `Respect the supplied packet's question classification and the director's explicit clarification. Answer whether an instantiation-selected reset form exists without converting that question into a new reset feature request.`
  Verification: `The director clarified that sf-isf-unstated-reset is a question. The packet already declared that kind; the additional configurable-reset implementation plan was an over-expansion and is withdrawn. Current forms and the report ambiguity are answered under .60.3; no configurable-reset implementation is on this packet's delivery path. A separately requested future capability would need its own contract. Duration units, named timers and aggregate ports remain feature requests; storage access remains independently owned.`
  Commit: `this commit`

## Current Frontier

Formal identity integration and its family qualification are complete under
`.49.2.2`; the live node records above carry exact status and evidence.
Local rule snapshots are qualified under `.32.1.3.3.1.3.2`. Stale named-drive
verification facts are repaired under `.57`. After the qualified strict
reset-token repair `.62`, `.60.3.4` closes the SPECFORGE reset question. The
duration and named-timer baselines `.60.1.1` and `.60.2.1` are qualified.
Aggregate intake `.60.4.1` is also qualified. Required scalar storage access `.38.1` is qualified. Domain storage details `.38.3` are also qualified. Decision 0113 selects bounded record-port delivery. Actual scoped contextual/enum/root preparation `.60.4.3.2.3.2` is qualified. Scalar-leaf sample facts `.60.4.3.2.3.3.1` are qualified. Contextual explicit sampling, private module carriers and actual helper/writer ownership are qualified under `.60.4.3.2.3.3.2`. Complete replay and existing capture-state preservation are qualified under `.60.4.3.2.3.3.3`. Record/formal domain roots and existing drive ingress repairs are qualified under `.60.4.3.2.3.4.2`. Unused named-drive domain carrier leakage is repaired under `.60.4.3.2.3.4.3`. Prepared parser/module gates are integrated under `.60.4.3.2.3.5.1`. Bounded authored record inputs are admitted under `.60.4.3.2.3.5.2`. The exact decision identity/cardinality audit `.51.3.1` is qualified. Next `.51.3.2` applies bounded rollover and reader/authority prerequisites before further record growth, then `.60.4.3.2.3.6` qualifies the full frontend/public matrix; duration and timer contracts remain owned, and
optional banks `.38.2` follow the required SPECFORGE features. The resource activation validator is qualified; target-local priority
`.32.1.3.3.1.3.3.2.2.3.2.2.2.2.3.2.3` remains a writer prerequisite,
with complete observed priority repair qualification,
after literal-guard repair and independently retained runtime qualification, after
exact named-drive invocation sources, following
source identities, declaration and implicit whole-root qualification, following
the physical target resolver and retained admission baseline. Conservative admission precedes independent controllers and local-call
timing under the following sibling leaves. `.49.2.3` qualifies direct-call runtime;
`.49.3` owns explicit-local physical scope. These remain prerequisites to execution promotion. Decision 0109 narrows the
former blanket dependency on passive metadata: scalar access `.38.1` proves
unchanged hardware; domain detail `.38.3` is qualified and optional banks `.38.2` remain owned.

Remaining partial/bank/competing writer work is under `.39.2.2.4.3` onward;
watchdog rearming is `.32.1.3.3.3` and broad behavior/API/MCP signoff is
`.32.1.3.3.2`. `.50` retains the MCP response gap. Bundle provenance and
executable interconnect are `.32.2` and `.32.4`; later actor checks, knownness,
phase and generic-width/optional-port work follows the dependencies recorded in
`.33` and `.32.3`. Full-source API coverage and historical native qualification
remain open. Preserve spent compiler/startup evidence; current runtime passes
do not close the separately tracked containment occurrence.

## Version-Retrievable Historical Views

- Acceptance history manifest: `docs/tasks/history/SEMANTIC-INTROSPECTION-MCP-FRONTIER/acceptance-history.jsonl`

The live node list above remains authoritative for ownership and status.
Historical decisions, verification/commit logs and acceptance evidence through
`03d65d6428eb4e34f294c6b71ea7bed185c39895` are retrieved and authenticated by the manifest.
This includes the controller, storage, formal scope, wait and extract audits.
The complete predecessor is retained as well as the exact historical suffix;
these products overlap. No historical source bytes are discarded.

To recover the original file from the repository root:

```bash
git show 03d65d6428eb4e34f294c6b71ea7bed185c39895:docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
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

## Acceptance — historical task rollover `.54`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` for the generated pin-shadow
  qualification heading identifies predecessor 03d65d64's latest acceptance
  append. The exact source census in the manifest reaches the warning band;
  optional decision/verification/checklist history is the scaling term, while
  all authoritative node records precede the selected Decisions heading.
  The existing acceptance-history contract supports this exact suffix without
  changing the checker, discarding evidence or increasing ceilings.
- [x] **ADDRESSED (verified)** — audit.log independently uses `git cat-file`
  and verifies complete-source identity, exact suffix/reconstruction, unchanged
  node identities and every other node record. The live graph/frontier remains
  available; active formal/controller and native-containment limits stay visible.
  The tracked manifest and required-history retention contract preserve both
  overlapping historical products. No discarded historical residue is claimed.
  A tracked anchor census finds no consumers of removed section anchors.
- [x] **NO REGRESSION** — negative-controls.log reports `All tests successful`
  for T1549, including altered source/suffix digests, string-encoded dimensions
  and displaced live pointers. book.log builds the retrieval guidance. The
  actual manifest passes task-tree integrity in integrity.log; paths.log passes
  T1414. The staged doctrine gate also verifies claim owners, query routes,
  documentation and unchanged ceilings.

Re-derivation is the exact Git object and independently computed manifest
identities; falsification is the existing hostile source/suffix/pointer tests;
durability is the tracked manifest, required Git history, live graph and unchanged
integrity checker. `.artifacts/semantic-task-rollover/audit.json` separates source,
suffix, semantic closure, live working set and residue; those products overlap.
The collection still has another large task file, so this local rollover does not
claim collection-wide health. Current contracts remain in the book/cards/ADRs;
DEVELOPMENT_NOTES needs no duplicate rationale. Source-context work resumes next.

## Acceptance — explicit-local admission `.49.2.2.3.1.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — T1935 before.log reproduces successful
  native `--check --json` and semantic admission of `(defualt 3)` in a local.
  `_parse_local_decl` skipped non-list/unknown options, ignored trailing option
  operands and overwrote repeated values. The detached clause resolver had a
  stricter shape contract, so connecting it could mask this source defect.
  The first test fixture's dotted invalid name was already rejected earlier by
  enum-context validation; the final invalid-name control uses a hyphen.
- [x] **ADDRESSED (verified)** — qualified-final.log passes T1935. Exact known
  option pairs and defined values are required before assignment. Duplicate
  default/init share one initialization slot; width/reset also reject repeats.
  Valid reordered options retain separate hardware reset and entry values.
  Carrier replay, source isolation, old collision/value checks, zero-only target
  pruning and live-target validation pass. Complete check/semantic reports and
  successful schedule reports agree across native/API/newline queries; failed
  schedules retain the existing message-only adapter error contract.
- [x] **NO REGRESSION** — qualified-final.log reports `All tests successful`.
  Related local, reset, for/procedure expansion, formal-width and mdBook fixture
  checks are retained in related-final.log; book-final.log builds the updated
  chapters. The staged doctrine and commit-hook gates qualify the final index.

Evidence is under `.artifacts/local-declaration-admission/`. before.log retains
permissive behavior; qualified.log caught the parser's undefined missing-option
value, now rejected explicitly. regression.log contains an incorrectly named
T1926 path after passing the earlier tests, so it is not a suite pass.
final-regression.log passes the related tests but exposes the new test's wrong
schedule-error expectations; T1929 and the adapter's existing failure contract
establish the corrected expectations, qualified in qualified-final.log.
Re-derivation is native source admission and emitted declarations; falsification
is typo/arity/duplicate/value/collision plus pruned/live controls; durability is
T1935 and the synchronized spec/book/card. No runtime or independent explicit-
local physical ownership claim is added. Rationale belongs here and in the
scope card; DEVELOPMENT_NOTES needs no duplicate entry. Next is `.1.2.2`.

## Acceptance — formal source contexts `.49.2.2.3.1.2.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — native `--emit-schedule-json` for the
  direct-param-shadow probe reports a static scalar wait sourced from count;
  probe.log emits its fixed wait chain and a runtime count register read.
  FormalClauseResolver previously sent scalar count positions and runtime RHS
  through one static-symbol set. The retained probe shows that an empty set
  renames both roles, while adding count preserves both: neither is correct.
  Source validation and zero pruning precede rewriting, but no caller previously
  supplied their complete contexts. Inferred samples cannot stand in for locals.
- [x] **ADDRESSED (verified)** — T1936 qualifies prepare_formal_source over
  parsed records, sharing production module admission and invoking existing
  per-transaction validation without parent merging. It supplies only explicit
  locals, exact resolved actor/enum/package expression names, generated-child
  parameters, separate standalone count symbols and structural zero-repeat
  paths. The walker preserves validated dead subtrees and resolves live count
  and expression roles separately. Missing maps, stale/non-repeat paths,
  malformed source, live bad bindings and source mutation controls pass.
  Detached transformed carriers strict-replay; scalar wait timing and dynamic
  count provenance remain separate. Physical allocation is still caller-owned.
- [x] **NO REGRESSION** — regression.log reports `All tests successful` for
  T1936/T1928, T1933 caller bindings/public queries, T1935 local admission,
  T1929 wait/public queries, T1348/T1350 parameter cases and T1376 book fixtures.
  qualified-final.log passes the explicit timing/generated-carrier oracles;
  final-context.log passes T1255 schedule goldens but its new generated fixture
  initially omitted a required output binding, corrected in qualified-final.log.
  book.log builds the updated source-semantics guidance.
  The staged doctrine gate and commit hook verify the final index.

Evidence is under `.artifacts/formal-source-context/`. context.log retains the
first test fixture's bare literal width refusal; the final fixture uses the
existing exact-width wait operand contract, without widening production grammar.
Re-derivation is native schedule/carrier evidence and canonical Package::Symbols
paths; falsification is distinct count/runtime roles, static-name exclusions,
malformed and pruned/live controls plus context/source isolation; durability is
T1936, the extended resolver tests, book/spec/card and this task record.
The returned source copy remains authored source. This helper does not provide
complete generated physical reservations, finalize parent wiring, validate the
backend or switch production emission. .3.2 must derive actual names before .3.3
uses the prepared contexts; controller/runtime obligations remain separate.
DEVELOPMENT_NOTES needs no duplicate rationale.

## Acceptance — transaction reservation products `.49.2.2.3.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — native `--emit-schedule-json` for probe.isf
  confirms the named isf_port_main drive. probe.log separately compares the
  source-only plan candidate isf_port_main_payload with the actual drive_payload
  counter and emitted declaration. _build_transaction already produces that
  assignment target, but prepare_formal_source discarded its returned products.
  Source-token reservation alone therefore misses a real generated collision.
- [x] **ADDRESSED (verified)** — T1937 qualifies retained transaction_products
  and FormalReservationInventory: conservative key/scalar tokens, formatted
  expressions, deterministic escaped JSON-pointer provenance, unsupported/cyclic
  refusal and shared acyclic inputs. Actual wait/repeat/monitor counters, sample
  targets, local/generated call records and resets are retained without parent
  merging. Exact/case-only drive collisions cause a distinct formal allocation;
  detached rewritten carriers pass strict checking. Products and source stay
  independent; a conflicting production parent merge still fails as before.
- [x] **NO REGRESSION** — regression.log passes T1937/T1936/T1928/T1925,
  T1413 monitor/anchor and T1189 drive cases before a mistyped book test path
  stops the harness; it is not a suite pass. book-fixtures.log then reports
  `All tests successful` for the correctly named T1376 audit. book.log builds
  the updated chapter. Final staged doctrine and commit-hook gates apply.

Evidence is under `.artifacts/formal-reservations/`. test.log retains the first
fixture's documented pending-sample/dynamic-wait-to-repeat refusal; the fixture
now flushes the sample through a supported assignment before waiting. It also
exposed a test helper name colliding with Test::More's plan export, renamed.
test-qualified.log catches a wrong test expectation for local call field
transaction; the actual contract is child, now asserted. Neither fixture repair
widens production admission. Re-derivation uses actual producer data and full
IR/carrier declarations; falsification covers source-only omission, case-folded
collision, malformed/cyclic products, source isolation and still-refused parent
merges; durability is T1937, the scope card, book and task record. This is a
partial producer boundary, not complete physical reservation or production
renaming. Later rule/shared-drive/child/storage/completion/library/ATL/domain
coverage and stable helper identity inputs remain owned by .3.2.2. No duplicate
DEVELOPMENT_NOTES entry is needed.

## Acceptance — parent activation products `.49.2.2.3.2.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — native `--emit-schedule-json` for
  rule-probe.isf reports isf_port_main_payload as rule_trigger_payload_source
  and as the binding payload_source. T1938 proves that name is absent from
  transaction_products and remains the planner candidate when only those
  products are reserved. _build_rules produces the omitted name after transaction
  lowering; generated activation registration and shared-drive lowering add
  further physical ports and payloads after the same boundary.
- [x] **ADDRESSED (verified)** — prepare_formal_source now retains separate
  parent_activation_products by invoking the canonical registration, rule and
  shared-drive producers. Source activation records are cloned before destructive
  registration. T1938 compares actual production ports, counters, roles, DT
  assignments, instance metadata and rule bank accesses; local rule collisions,
  case-folded names, declaration permutations, generated spawn/do/parameterized
  trigger drive handoffs, snapshot isolation and unknown-bank refusal pass.
  A conflicting actor/formal width can still yield partial product names while
  production continues to reject its physical parent merge.
- [x] **NO REGRESSION** — regression.log reports `All tests successful` for
  T1938/T1937/T1936, T1248 generated rule triggers, T1241 port bindings, T1236
  bank lowering, T1255 schedule goldens and T1376 book fixtures. book.log builds
  the updated scope guidance; staged doctrine and commit-hook gates apply.

Evidence is under `.artifacts/formal-parent-products/`. test.log retains an
incorrect test assumption that ordinary spawn records carry activation_kind;
production intentionally defaults an absent field to spawn. The test now applies
that same default while comparing full registered metadata to production.
No production record was changed to satisfy the test. Re-derivation is native
schedule provenance and actual production IR comparison; falsification includes
transaction-only omission, exact/case-folded collision, declaration permutation,
source snapshots, invalid bank input and still-refused parent merging; durability
is T1938, the card, book and this record. The new product bundle is not an IR:
there is no transaction-map merge, finalization, ownership connection or emission.
Local/external activation state wiring, priority/resource processing, child
storage/completion/library/ATL and domain closure still require .3.2.2.2; source
helper identity inputs must stay stable after endpoint rewriting. The complete
reservation gate remains .3.2.2.3 and production integration remains .3.3.
Rationale is owned here and in the scope card; no duplicate DEVELOPMENT_NOTES
entry is warranted.

## Owned defect — terminal static wait `.55`

Run immediately after `.49.2.2.3.2.2.2.1`, before further reservation work.
The following raw source lowers to an empty worker_wait_0 state. Native strict
`--check --json` of worker.fsm rejects that state; the diagnostic's `undef` is
its normalized rendering of the absent body, not text emitted into the carrier.

```lisp
(actor generated_helper (clock clk) (reset rst_n)
  (interface (input fire) (input din (width 4)) (output done))
  (transaction main (on fire) (complete done))
  (transaction worker (params (N 2)) (ports (input data (width 4))) (wait 1))
  (rule launch fire (trigger worker (params (N 3)) (bind (input data din)))))
```

_link_states supplies no transition for a static wait without a successor;
_emit_states then emits its empty body. The raw-source path never receives the
new private formal identity annotation, so this is an existing terminal-state
boundary. The helper-identity positive fixture uses explicit complete; .55 owns
the original source, terminal hold semantics, broader empty-state census and
verified repair. Do not classify the malformed carrier as supported behavior.

## Acceptance — stable rule helper identity `.49.2.2.3.2.2.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — native `--emit-schedule-json` retained
  under formal-parent-products reports isf_port_main_payload as the rule payload
  source. probe.log compares source and detached rewritten IR: rewriting the
  bound formal produces isf_port_main_isf_port_main_payload_formal instead,
  absent from the original reservations. _build_rules and binding metadata
  previously derived helper names from the rewritten endpoint spelling.
- [x] **ADDRESSED (verified)** — after-qualified.log preserves the original
  helper while the physical formal remains isf_port_main_payload_formal.
  T1939 qualifies private typed source/physical declaration provenance, checked
  shape/owner/name agreement and duplicate source refusal, stable helpers under
  alternative physical allocations, correct physical fan-in destinations,
  generated public ports/instances/assignments, source isolation, schedule
  provenance and strict replay. The annotation stays outside the public schedule
  schema; already projected declarations cannot be silently rewritten again.
- [x] **NO REGRESSION** — qualified-final.log reports `All tests successful`
  for T1939. test.log separately passes T1938/T1937/T1936/T1928 but is not a
  suite pass: the initial T1939 fixture attempted deferred activation-specialized
  wait counts. qualified.log passes T1243/T1248/T1255 but T1939 exposed the
  raw terminal-wait defect now owned by .55; it is not a suite pass either.
  The final generated positive fixture uses explicit completion. book-fixtures.log
  qualifies T1376; book.log builds the synchronized chapter. Staged doctrine
  and commit-hook gates apply to the final index.

Evidence is under `.artifacts/formal-helper-identity/`. after.log retains a
Perl grep/list-operator precedence error in the initial projection guard, fixed
with explicit parentheses and qualified in after-qualified.log and T1939.
Re-derivation uses actual before/after IR plus schedule helper provenance;
falsification uses source-only name drift, alternate physical allocations,
malformed/stale/duplicate records, generated-interface equality and source
snapshots; durability is T1939, the scope card, book and this task record.
No automatic production rewriting, complete namespace proof or runtime scope
promotion is claimed. The separate raw terminal-wait defect and exact source
are owned by .55 above, scheduled immediately next; its repair is not waived by
using a supported continuation in this slice's identity fixture. Rationale
belongs here and in the scope card; DEVELOPMENT_NOTES needs no duplicate entry.

## Acceptance — empty terminal-state carriers `.55`

- [x] **ROOT CAUSE (WHY + WHERE)** — raw generated-child worker.fsm fails
  native `--check --json` with Unsupported top-level form and a normalized
  worker_wait_0 undef diagnostic. The emitted carrier actually has an empty
  state body, not an undef token. The before.json census reproduces the same
  failure for direct/generated terminal static wait, point and phase states.
  LoweringIR has no successor there; Emitter::FSM::_emit_states emitted that
  empty body although the carrier grammar requires a body.
- [x] **ADDRESSED (verified)** — _emit_states now emits an explicit self-loop
  only when both emitted assignments and transitions are empty. It preserves
  the source graph, state identity and normal nonempty bodies. after.json passes
  the retained census with identical source IR. T1940 qualifies actual carriers,
  empty-body mutation refusals, explicit successors/completion, warning-free
  lowering and complete native/API/newline check/semantic/schedule parity.
  The Darwin-qualified Verilator run passes independent direct/generated
  terminal hold, repeated-request and reset-reactivation oracles through public
  interfaces, including generated child storage handoffs.
- [x] **NO REGRESSION** — test.log and regression.log report
  `All tests successful`. The latter covers T1244 waits, T1922 synchronization,
  T1413 anchors, T1255 schedule goldens and T1939 helper identity; its legacy
  runtime guards are not a new runtime qualification. T1940 was run separately
  with FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 and an available provider;
  runtime-guard.log independently records those exact branch prerequisites.
  book-fixtures.log passes T1376 with the new complete example; book.log builds
  synchronized book/spec guidance. Staged doctrine and commit hooks apply.

Evidence is under `.artifacts/terminal-state-carriers/`; the original raw
source/carrier/refusal remains under formal-helper-identity/terminal-wait-baseline.
The census reuses case directories for repaired outputs; before.json retains
original failure statuses and graphs, while T1940 independently restores empty
bodies and proves native refusal. Re-derivation is actual source/IR/carrier
comparison; falsification is the malformed-body control, continued-state checks
and repeated-request/reset HDL oracle; durability is T1940, the terminal-state
card, book/spec and this task. No new storage, completion, return-to-entry edge
or automatic direct-controller repair is claimed. Zero-wait region erasure and
dynamic-wait successor policy are unchanged. Resume .49.2.2.3.2.2.2.2 before
remaining producer closure and the complete reservation gate. Rationale belongs
here and in the fact card; DEVELOPMENT_NOTES needs no duplicate entry.

## Acceptance — pre-allocation monitor admission `.49.2.2.3.2.2.2.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — probe.log derives main_assert_1_age
  from an actual monitor product. Both raw preparation and raw production fail
  with the recorded diagnostic ` at perl/FSM/Scheduler/ISF/LoweringIR.pm line 9297`:
  the generated monitor signal collides with an existing signal. Explicit
  detached projection instead preserves separate declared formal and generated
  monitor widths. _ir_monitor_check was enforcing an unresolved physical alias
  before preparation could supply the names needed for allocation.
- [x] **ADDRESSED (verified)** — prepare_formal_source alone supplies the
  narrow pre-allocation context. Only an unprojected direct formal still marked
  transaction_port, absent from fixed actor names, can defer a monitor collision.
  deferred_formal_collisions retains the typed source identity, detached formal
  declaration and actual helper role/width/state. T1941 qualifies monitor roles
  with input/output formals, strict raw production refusal, actual projected
  widths and strict carriers, no remaining deferral after projection, actor
  storage/interface/constant/clock/reset, local/generated/projected refusals,
  malformed source checks and independent snapshots. after.log confirms the
  original source preparation succeeds while raw production still fails.
- [x] **NO REGRESSION** — test.log and regression.log report
  `All tests successful`. The latter covers T1941/T1939/T1938/T1937/T1936,
  T1935 local source checks, T1413 monitors/anchors and T1255 schedule goldens.
  book-fixtures.log passes T1376 and book.log builds the updated boundary.
  Staged doctrine and commit-hook gates qualify the final index.

Evidence is under `.artifacts/formal-preallocation-admission/`. Re-derivation
uses actual monitor products and physical lowering; falsification uses strict
raw/fixed/local/generated/projected failures, malformed source, separate widths
and snapshot controls; durability is T1941, the dedicated admission card,
book and this task. This context is never stored on the source actor or lowerer,
and executable build_module callers never pass it. Returned source products may
still overlap under raw names and are inventory inputs, not executable IR or a
complete collision census. Full module/backend validation of the projected
actor remains mandatory. There is no automatic production rewrite or runtime
scope promotion; .3.2.2.2.3 and .3.2.2.3 retain remaining producer and completeness
obligations. No duplicate DEVELOPMENT_NOTES rationale is needed.

## Acceptance — activation wiring products `.49.2.2.3.2.2.2.3.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — native `--emit-schedule-json` on
  t/data/logical-controller-shadow/crossing.isf identifies the worker activation,
  both domain artifacts and start/done crossings. The independent before.json
  probe runs those real domain projections and finds ready/request/entry state
  and ready-port names missing from transaction/activation products. The locus
  is the later _wire_do_children and _wire_external_activations producer stage.
- [x] **ADDRESSED (verified)** — parent_wiring_products invokes those same
  routines on cloned retained direct states and activation ports. Handshake
  additions have a separate counter map; unresolved source widths/roles are
  never merged into an executable IR. after.json has no missing names in the
  same domain-state/port probe. T1942 compares production state/port/counter
  products, qualifies source-order membership, raw-product isolation, actual
  projected domains, exact/case-folded late ready-port candidate collisions,
  stable physical helper/state names and strict carriers. Generated/pruned
  bodies are excluded; raw width conflicts, bad roles and fixed ready-port
  width conflicts retain canonical refusals.
- [x] **NO REGRESSION** — test.log and regression.log report
  `All tests successful`; the cohort includes T1942, T1941 admission, T1938
  parent products, T1939 source identities, T1387 external wiring, T1924 logical
  controller shadow, T1255 schedule goldens and T1376 book fixtures. book.log
  builds the synchronized guidance. Staged doctrine and commit hooks apply.

Evidence is under `.artifacts/formal-wiring-products/`. Re-derivation uses the
native schedule and independently realized before/after domains; falsification
uses the old-inventory collision, case variants, permutations, detached mutation,
source conflicts and malformed producer inputs; durability is T1942, the wiring
card, book and this task. Returned states stop after activation wiring: point
resolution, defaults, priority/resource processing and child ownership can still
alter later products. Library/ATL and final domain/outer composition are not
covered. Preparation remains source-only; executable admission and controller
runtime semantics are unchanged. The .2 continuation owns those remaining
producer phases before the complete .3.2.2.3 gate. Rationale belongs here and in
the fact card; DEVELOPMENT_NOTES needs no duplicate entry.

## Acceptance — parent point/default products `.49.2.2.3.2.2.2.3.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — native `--emit-schedule-json` on the
  retained source exposes interface_output_default assignments from late parent
  processing. The independent before.json probe derives the actual point_active
  target isf_port_main_point_1_active from production states and proves it is
  absent from previous preparation products, while the old plan selects that
  exact name for main.point_1_active. _resolve_at_references creates the signal
  only after transaction lowering and activation wiring.
- [x] **ADDRESSED (verified)** — parent_point_products reuses the canonical
  parent point-binding map, _resolve_at_references and the entry-default producer
  on detached states/assertions. Actual generated counters remain separate from
  unresolved declaration maps. after.json reserves the actual helper and selects
  a distinct formal. T1943 compares actual states, resolved checks, defaults and
  widths; qualifies point/on-as anchors, exact/case-folded collisions, stable
  helper identities through projection, declaration order, cross-transaction
  scope, actor default ownership under a raw formal shadow, strict carriers and
  snapshot mutation controls. Generated/pruned assertions stay outside parent
  scope; unknown/duplicate direct anchors retain canonical refusals.
- [x] **NO REGRESSION** — test.log and regression.log report
  `All tests successful`; the latter covers T1943, T1942 wiring, T1941 admission,
  T1936 contexts, T1413/T1416 anchors, T1476 output defaults/reset and T1255
  schedule goldens. book-fixtures.log passes T1376; book.log builds synchronized
  guidance. Staged doctrine and commit hooks apply to the final index.

Evidence is under `.artifacts/formal-point-products/`. Re-derivation uses the
native schedule and independently collected actual before/after helper products;
falsification uses old-plan aliases, case variants, separate widths, source
permutation, mutation controls, shadowed defaults and invalid anchor references;
durability is T1943, the point-products card, book and this task. These remain
source preparation products, not a merged or finalized executable IR. Child
point scopes, arbitration, ownership connections and library/ATL/domain closure
retain their later producer obligations. No automatic production rewrite or
controller runtime change is claimed. Rationale belongs here and in the fact
card; DEVELOPMENT_NOTES needs no duplicate entry.

## Acceptance — resource pointer declarations `.49.2.2.3.2.2.2.3.2.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — native `--emit-schedule-json` exposes
  isf_rr_shared_bus_turn with resource_round_robin_pointer role and width 2.
  before.json independently extracts that actual production declaration and
  proves its absence from transaction/activation/wiring/point products. The
  declaration is created later by _apply_round_robin_rule_user_resource_grants;
  raw formal aliases meet its strict physical collision guard before renaming.
- [x] **ADDRESSED (verified)** — _round_robin_pointer_declaration now owns
  the actual name, width and role consumed by both executable arbitration and
  resource_signal_products. Preparation collects potential declarations only
  for selected round-robin kinds with users, sorted by source resource name;
  malformed generated names fail through the shared canonical check. It does
  not fabricate grants or perform resource user/member/physical admission.
  after.json finds the actual declaration. T1944 compares supported resource
  kinds with real counters, roles and grant update targets, checks independent
  width boundaries and source-order/snapshot isolation, preserves identity
  through formal projection and strict carriers, and keeps raw formal/fixed
  symbol/user-overlap/unknown-user/name/unsupported-kind refusals executable.
- [x] **NO REGRESSION** — test.log and regression.log report
  `All tests successful`; the latter includes T1944, T1943 points, T1939 helper
  identity, T1218 resource arbitration, T1210/T1219 priorities, T1316 resource
  fixtures and T1255 schedule goldens. Exact native schedule-before.json and
  schedule-after.json compare equal. book-fixtures.log passes T1376; book.log
  builds synchronized guidance. Staged doctrine and commit hooks apply.

Evidence is under `.artifacts/formal-resource-products/`. Re-derivation uses the
native schedule and independently extracted actual declarations; falsification
uses missing old inventory, independent capacity boundaries, real grant targets,
raw versus projected aliases, invalid resource controls and detached mutations;
durability is T1944, the resource-products card, book and this task. Unused,
priority and unsupported-kind resources add no potential pointer declaration.
Collection is not admission: an unknown or overlapping user or fixed-symbol
collision can still have a potential declaration and must fail actual lowering.
The executable validation order and report remain intact. Grant/priority product
coverage, child ownership and library/ATL/domain composition remain .2 before
the complete reservation gate. No automatic production rewriting or controller
runtime support is claimed; DEVELOPMENT_NOTES needs no duplicate rationale.

## Acceptance — generated child products `.49.2.2.3.2.2.2.3.2.2.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — native `--emit-schedule-json` records
  the worker module and real actor storage read/write handoffs. before.json
  independently extracts actual child counters/ports/states/DT names and finds
  activation history, storage-write ports, synthesized entry and point-active
  signal names absent from earlier products. Those names are produced by the
  independent _build_child_ir stage before any parent declaration merge.
- [x] **ADDRESSED (verified)** — _build_generated_transaction_children
  now shares that exact production loop with source preparation, which calls it
  on a separate actor clone and retains detached generated_child_products by
  module. after.json has no missing names in the same child declaration probe.
  T1945 compares complete actual child IR before/after direct formal projection,
  spawn/generated-do/trigger placement, exact/case-folded public-port/helper
  collisions, storage read/write and named completion metadata, child point
  resolution, source/product isolation, reused definitions, real domain scopes
  and strict carriers. Raw parent conflicts, child unknown-anchor/bank-write
  refusals and zero-pruned bodies retain their canonical boundaries.
- [x] **NO REGRESSION** — qualified.log and the completed regression.log
  report `All tests successful`. The cohort covers T1945 products, T1936 source
  contexts, T1938 parent products, T1934 generated pin shadows, T1904 storage
  reads, T1917 scalar writes and T1255 schedule goldens. The run did not opt into
  new Darwin runtime qualification. Exact native schedule.json/schedule-after.json
  comparison is byte-identical. book-fixtures.log passes T1376 and book.log builds
  synchronized guidance. Implementation doctrine/commit.log passed before the
  longer regression finished; this qualification commit consumes that result.

Evidence is under `.artifacts/formal-child-products/`. Initial test.log contains
an incorrect negative-control expectation for set-bit. The set-bit-probe.json
reproduction and Parser::_desugar_bit_op establish the actual whole-word
(set cell (| cell 1)) normalization and canonical full-width write handoff.
T1945 now keeps this as a positive control and uses the existing unsupported
bank-write boundary as its negative control; qualified.log passes. This is a
test-assumption correction, not a production partial-writer repair.
Re-derivation uses native schedule provenance and independent actual-child
before/after products; falsification uses old inventory omissions, portable
helper collisions, complete child equality, reused/domain scope, raw conflicts,
invalid child source and mutation controls; durability is T1945, the child
products card, book and this task. Child construction retains its real semantic
finalization, but complete parent connection, grant/priority and library/ATL/domain
namespace closure remain .2. Source preparation is not an executable parent,
and no new controller/storage runtime qualification is claimed. Existing runtime
and historical containment obligations remain separate. DEVELOPMENT_NOTES needs
no duplicate rationale.

Qualification follow-up: b5990b98a committed the verified implementation while
its broader confirmation ran, with an explicit active resume pointer. The
completed regression.log is now consumed and no owned process remains in flight.
The command was scripts/run_with_ram_guard.sh prove -Iperl with
`t/1945-isf-formal-child-products.t`, `t/1936-isf-formal-source-context.t`,
`t/1938-isf-formal-parent-products.t`, `t/1934-isf-generated-pin-shadow.t`,
`t/1904-isf-generated-child-storage-reads.t`, `t/1917-isf-generated-child-scalar-writes.t`
and `t/1255-isf-schedule-report-golden-matrix.t` in that order. No new Darwin HDL
runtime qualification is inferred. The separate historical containment
occurrence remains open under its existing owner.

## Acceptance — child qualification closure `.49.2.2.3.2.2.2.3.2.2.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` on the focused regression
  pointer in MEMORY.md identifies b5990b98a as the intentional pending-result
  commit. The owned cohort now reports All tests successful, and the native
  `--emit-schedule-json` before/after files compare byte-identically. Keeping
  the active pending pointer would misstate the consumed qualification state.
  The initial closure doctrine run also requires fresh acceptance for changed
  inventory and size-registry declarations under change_paths.tsv.
- [x] **ADDRESSED (verified)** — the task records the completed cohort,
  source/report evidence and unchanged runtime boundary; MEMORY.md advances to
  the remaining reservation leaf with no background work. The book and fact
  card describe the qualified reused/domain child scope. This fresh closure
  checklist covers the co-staged generated inventory and measured book/task
  declarations; no production source or test implementation changes here.
- [x] **NO REGRESSION** — regression.log reports `All tests successful` for
  the complete focused cohort. book-qualification.log rebuilds the final prose;
  runnable examples were unchanged after the passing book-fixtures.log audit.
  doctrine-qualification.log retains the initial freshness failure; the renewed
  staged doctrine run and commit hook verify the corrected closure index.

## Acceptance — parent completion products `.49.2.2.3.2.2.2.3.2.2.2.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — native `--emit-schedule-json` and
  before.json show real generated-child joins and completion views, while the
  preexisting preparation inventory omits their seen/ready declarations.
  ChildCompletion::retain_child_completions allocates them after parent point
  and resource processing; they cannot be reconstructed from transaction-only
  lowering products without rerunning their real producer.
- [x] **ADDRESSED (verified)** — the real producer now returns its allocation
  input_names and typed instance/start/done/seen/ready records. Executable parents
  retain that private metadata. Preparation runs it over detached point states,
  registered activations and declaration membership, retaining only fresh
  generated widths/roles/resets/DTs and rewritten states. after.json has no
  missing completion helper. T1946 compares actual allocation namespaces,
  ownership and join products on raw and projected sources, including dynamic
  wait guards, fixed/formal helper collisions, static/storage/point/resource
  inputs, declaration order, mutation isolation, raw width conflicts, absent
  or pruned joins and strict parent carriers.
- [x] **NO REGRESSION** — qualified.log and regression.log report
  `All tests successful` for T1946 and the preallocation, wiring, point,
  resource, completion-memory and native schedule cohort. The unchanged
  schedule-before.json/schedule-after.json files compare byte-identically.
  book-fixtures.log passes the runnable example audit; book.log builds the
  synchronized guidance. Staged doctrine and commit hook run before closure.

Evidence: `.artifacts/formal-completion-products/`. Initial test.log records
an exact-spelling assertion failure. case-probe.json proves the uppercase raw
formal moves to a private name, freeing the lowercase completion helper base;
the supplied inventory contains its uppercase portable alias. The canonical
HDLInstanceIdentifierPolicy::_reserved_name_exists compares case-insensitively.
T1946 now checks that actual contract and preserves explicit instance ownership
across the real helper allocation change. This is a corrected test assumption,
not a general proof of reservation closure or a production allocator defect.
Re-derivation uses actual executable producer metadata and native reports;
falsification uses missing-name, portable collision, raw-width, no-join and
mutation controls; durability is T1946, the completion-products card, book and
this task. Source-only membership is never emitted as fabricated storage widths.
Public reports and completion behavior remain unchanged; no new HDL runtime
qualification or complete namespace/production formal rewriting is claimed.
Parent storage/named-completion connections, grants/priority and library/ATL/domain
composition remain owned by .2. DEVELOPMENT_NOTES needs no duplicate rationale.

## Acceptance — reusable child products `.49.2.2.3.2.2.2.3.2.2.2.2.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — native `--emit-schedule-json` of the
  resolved ATL fixture exposes the real child module and composition. before.json
  independently inventories executable library and ATL child declarations and
  finds FIFO DT/state helpers and ATL process states absent from earlier source
  preparation products. build_module constructs these modules before its parent
  merge, but preparation previously collected only generated transaction children.
- [x] **ADDRESSED (verified)** — _build_module_child_products now shares the
  exact production construction order, conflict checks, library metadata, ATL
  selection and child-interface marking. Preparation calls it on a separate actor
  clone and retains distinct detached generated/reusable views. after.json has
  no missing declarations in the same probe. T1947 compares complete actual
  reusable children and composition records before/after formal projection for
  FIFO, resolved ATL trigger/event, vector ingress/egress, actor-to-actor data
  and trigger batches. Mixed generated/library modules, bound parameters,
  storage/bank products, strict carriers, source/mutation isolation and raw
  parent width conflicts pass. Canonical missing-module/shell, cross-kind module
  conflict, unsupported ATL group and unresolved-external controls are retained.
- [x] **NO REGRESSION** — qualified.log reports `All tests successful` for
  T1947 and T1945. The native ATL schedule before/after files compare byte-identically.
  book-fixtures.log passes the runnable example audit and book.log builds the
  synchronized guidance. Completed regression.log reports All tests successful
  for T1947, T1936, T1946, T1231, T1330 and T1255; no new runtime opt-in is
  inferred. Staged doctrine and commit hook run for this implementation.

Evidence: `.artifacts/formal-reusable-products/`. Initial test.log records a
control-fixture error: the added raw direct payload formal aliases the authored
ATL ingress payload pin, and executable parent lowering correctly rejects it.
The control now uses local_delay; dedicated raw conflict cases keep the strict
boundary. This is not a production regression. qualified.log passes both new
reusable and existing generated child product tests. Native ATL schedule
atl-before.json/atl-after.json compare byte-identically.
Re-derivation uses native schedules and complete actual child/metadata equality;
falsification uses old inventory omissions, raw parent conflict, invalid module
and composition inputs, mutation and strict replay; durability is T1947, the
reusable-products card, book and this task. Parent connection/grant and outer
domain completeness remain .2; no new runtime qualification is claimed.
A separately owned documentation defect in stale ATL support summaries is .3,
scheduled immediately after this slice commits. DEVELOPMENT_NOTES needs no
duplicate rationale.

## Acceptance — ATL book status `.49.2.2.3.2.2.2.3.2.2.2.2.2.3`

- [x] **ROOT CAUSE (WHY + WHERE)** — native `--emit-schedule-json` for
  atl_resolved_child_pipeline, atl_two_child_trigger_batch_pipeline and
  atl_two_child_vector_data_pipeline reports library_actor_export instances,
  their actual generated tops and vector_actor_handoff routing. The composition
  chapter's older introduction nevertheless called resolution future/backlog
  and multi-child/data-route tops unavailable. The orchestration backlog also
  said resolved children do not emit generated tops, contradicting its later
  shipped-subset descriptions and the feature-support matrix.
- [x] **ADDRESSED (verified)** — both summaries now describe shipped
  library-qualified resolution and explicitly point to the bounded trigger/event,
  same-child pin-route and two-child composition subsets. Obsolete blanket
  denials are removed. Sibling-root resolution, unqualified external intent,
  executable groups, actor-event aggregation, CDC, route mux/storage and broader
  routing remain bounded by their existing contracts. No compiler or example
  source behavior changes. Native evidence.json is derived from the fresh
  complete schedule reports under .artifacts/atl-book-status/.
- [x] **NO REGRESSION** — tests.log reports `All tests successful` for
  T1332 ATL documentation status and T1376 runnable book examples. The final
  prose build is book-final.log. The unchanged implementation was already
  qualified by the completed T1330 cohort in .artifacts/formal-reusable-products/
  regression.log; no new runtime qualification is inferred. The staged doctrine
  gate and commit hook validate the co-staged claim/size registry updates.

Re-derivation uses native schedule metadata, the feature matrix and detailed
composition contracts; falsification compares the stale blanket denials with
actual resolved/top/route outputs and preserves the canonical group/event-join
negative boundaries; durability is the corrected mdBook and this task record.
No new low-impact prose test mirrors the implementation. No DEVELOPMENT_NOTES
entry is needed for correcting stale support prose. Resume remaining parent
connection/grant/outer domain reservations under .2 after this commit.

## Acceptance — arbitration namespace `.49.2.2.3.2.2.2.3.2.2.2.2.2.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — native `--emit-schedule-json` on the
  resource probe shows real round-robin grants, a target-local priority record
  and the pointer declaration. _apply_rule_user_resource_arbitration is the
  declaration-producing phase; the following priority routines rewrite guards,
  and _finalize_ir derives provenance/fan-in/conflicts. Parent connections run
  after those stages, so their reservation input requires qualification of this
  boundary rather than assuming finalization adds or removes names.
- [x] **ADDRESSED (verified)** — T1948 observes the real production calls,
  delegates each wrapper to its original CV and compares exact declaration sets
  before/after. Resource additions equal the retained pointer products; priority
  and finalization add/remove no declarations. Actual stage order, nonempty grant
  and priority records, supported resource kinds/arbiters, direct and unique
  named-drive priorities in both directions, state_active guards, source/physical
  inventories and strict carriers pass. The test never executes a fabricated
  parent assembled from conflicting raw products. Actual unknown-user/pointer
  collisions and finalization writer-conflict refusals remain authoritative.
- [x] **NO REGRESSION** — qualified.log and regression.log report
  `All tests successful` for T1948, T1944, T1218 and T1220. book-fixtures.log
  passes the runnable examples; book.log builds synchronized scope guidance.
  No production implementation changes or new runtime qualification are claimed.
  Staged doctrine and commit hook check the test/docs/inventory slice.

Evidence: `.artifacts/formal-arbitration-namespace/`. Initial test.log assumed
whole-rule resource grants eliminate target-local priority records. The native
resource-schedule.json proves both are retained for conflicting data writes;
canonical _rule_data_assignment_refs carries authored condition terms into
_condition_terms_prove_disjoint, so resource guards do not erase this priority
record. Compatible transaction-trigger pulses remain a distinct path. Corrected
expectations pass in qualified.log without changing production semantics.
Re-derivation uses real stage observations and native grant/priority/storage
reports; falsification uses exact namespace deltas, source/physical inventories,
nonvacuous priority/grant checks, malformed resource and finalization refusals;
durability is T1948, the namespace card, book and this task. This closes the
current arbitration/finalization declaration boundary, not complete parent
connections, outer domain realization or automatic production formal renaming.
Those remain .2. No duplicate DEVELOPMENT_NOTES rationale is needed.

## Acceptance — parent write products `.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — native `--emit-schedule-json` and
  before.json expose the generated child's real parent data/enable handoffs,
  absent from earlier preparation products. connect_child_storage_writes creates
  these declarations after parent finalization and writer admission; child-local
  write ports alone do not describe the parent instance namespace.
- [x] **ADDRESSED (verified)** — plan_child_storage_write_handoffs now
  shares the unchanged allocation/product loop with executable connection, which
  still checks competing generated and parent writers first. Source preparation
  retains potential ports, widths/types, DTs and typed actor/instance/storage
  links against declaration membership extended by actual completion products.
  after.json has no missing parent write port. T1949 compares the complete actual
  production plan and installed products before/after formal projection across
  scalar/alias/record/list and distinct-target writes, portable fixed/formal
  collisions, raw role overlap, detached snapshots and strict carriers. Potential
  plans never bypass executable competing-writer checks or invent readonly-child
  write handoffs. T1946 preserves completion namespace inputs through extraction
  of the common declaration-membership helper.
- [x] **NO REGRESSION** — qualified.log reports `All tests successful` for
  T1949 and T1946. Native schedule-before.json/schedule-after.json compare
  byte-identically. The completed regression.log reports All tests successful
  for T1949, T1946, T1945, T1917 and T1255. No new runtime opt-in is inferred.
  Book fixture/build and staged doctrine/commit gates passed for implementation;
  this qualification closure consumes the broader cohort.

Evidence: `.artifacts/formal-parent-write-products/`. Initial test.log has one
incorrect diagnostic spelling in the raw formal/storage control. The tool
reports storage role for 'cell' conflicts across transactions while merging
'main' at the existing _merge_storage_roles admission. The exact expectation
now matches that canonical diagnostic; no production diagnostic changed.
Re-derivation uses actual planner observations and installed parent ports/DTs,
plus native schedule metadata; falsification uses old inventory omissions,
portable allocation changes, typed ownership, raw role/writer conflicts,
readonly children and snapshot mutation; durability is T1949, the write-products
card, book and this task. Plans are not executable parent IR or writer admission.
Read/named-completion/readback and outer domain coverage remain .2. This adds
no new runtime qualification or production formal rewrite. No duplicate
DEVELOPMENT_NOTES rationale is needed.

## Acceptance — parent write qualification closure `.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` on MEMORY.md's
  parent/child/completion/scalar-writer/schedule regression pointer identifies
  461d851a9 as the intentional implementation commit with confirmation pending.
  The completed regression.log now reports All tests successful, so retaining
  the pending pointer would misstate qualification and strand the next frontier.
- [x] **ADDRESSED (verified)** — consume the complete T1949/T1946/T1945/
  T1917/T1255 result, close this leaf and advance MEMORY.md to remaining
  read/named-completion/readback/domain products with no background work.
  The book and fact card record completed writer report qualification. The
  implementation and test sources are unchanged from 461d851a9.
- [x] **NO REGRESSION** — .artifacts/formal-parent-write-products/regression.log
  reports `All tests successful` for the entire named cohort. Native schedule
  before/after remains byte-identical; prior book-fixtures.log passed unchanged
  runnable examples, and book-qualification.log rebuilds the final prose.
  Fresh staged doctrine and commit hook apply to the measured documentation and
  generated claim inventory. No new Darwin HDL runtime qualification is claimed.

## Acceptance — read handoff block collision `.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.1.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — `--strict --check --json` accepts
  block-collision.isf although connect_child_storage_reads omits state and DT
  names from its reservations. The emitted collision.sv gives the authored
  guarded rule and generated live view the same DT enable, assigned true.
  legal-runtime-before.json independently compiles the isolated value_reg
  variant and reports READ_HANDOFF_LOST_RULE_GUARD fire=0 flag=1 at runtime.
  The original cell-named source stops at compilation; it supplies no runtime
  evidence and is separately owned by .1.3.
- [x] **ADDRESSED (verified)** — reuse _reserved_names before read allocation,
  preserving existing blocks and allocating a distinct generated read port/DT.
  collision-test.log passes T1950, including independent HDL guard/read/reset
  observations without runtime skips. Exact/case-folded state and DT controls
  preserve authored blocks, child contracts, shared links, widths and aliases;
  ordinary allocation stays stable. Native strict check and schedule routes
  continue to return structured successful results.
- [x] **NO REGRESSION** — collision-test.log reports `All tests successful`.
  Broader T1904/T1911/T1949/T1255 confirmation is explicitly pending in
  collision-regression.log; it is not included in this focused pass claim.
  The synchronized book and retained storage fact card describe the repaired
  collision boundary. Staged doctrines and normal hook remain mandatory.

Evidence: `.artifacts/formal-parent-read-products/`. Re-derivation traces the
actual emitted duplicate headers/enable and observes the public source;
falsification uses independent compiled HDL with a legal storage name, portable
block collisions, ordinary names and shared readers; durability is T1950,
the aggregate-read card, book and this task. The original compiler refusal and
isolated runtime failure are both preserved. No generic duplicate-DT semantics,
public identifier contract, storage cycle or formal production rewrite changes.
The separately scheduled keyword defect is not closed by this allocator fix.
No duplicate DEVELOPMENT_NOTES rationale is needed.

## Acceptance — read collision qualification closure `.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.1.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` on MEMORY.md's read
  collision regression pointer identifies 54b51ef10 as the implementation
  committed with explicit confirmation pending. The complete retained
  collision-regression.log now reports All tests successful; the pending
  pointer must advance rather than strand finished qualification.
- [x] **ADDRESSED (verified)** — consume the complete T1904/T1911/T1949/
  T1255 result, close the block-collision repair and point to read planning.
  Independent HDL guard/read/reset evidence remains in collision-test.log;
  scalar/aggregate runtime opt-in was enabled for the broader cohort.
  No source or regression test changed after its successful run.
- [x] **NO REGRESSION** — collision-regression.log reports `All tests successful`
  across the entire named cohort. T1376 book examples passed; the final book
  qualification rebuild includes this closure. Fresh staged doctrines and the
  normal hook apply to updated durable records and claim classification.

All jobs consumed. Re-derivation is the complete retained cohort result;
falsification includes authored block collisions and independent pin-driven
HDL behavior; durability is T1950 and the committed task/card/book records.
The keyword compiler defect .1.3 remains scheduled after .1.2 and is not
classified as resolved by these passing controls.

The first closure doctrine run correctly rejected reuse of the implementation
aggregate-change authority ID. The closure uses a fresh qualification authority
and recomputed HEAD-relative measurements; no size ceiling is raised.

## Acceptance — parent storage-read plans `.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.1.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — actual `--emit-schedule-json` succeeds
  for legal-collision.isf, while read-product-probe.pl's planner-before.json
  reports isf_storage_read_value_reg_storage_read missing from prepared
  products. connect_child_storage_reads previously allocated this real output
  only after write connections; prepare_formal_source could not reserve it.
- [x] **ADDRESSED (verified)** — share plan_child_storage_read_handoffs with
  executable connection and preparation after completion/write declarations.
  planner-after.json has no missing read handoff. T1951 compares complete
  actual allocation inputs and installed ports/types/DTs/links against detached
  source and projected products. Typed actor/storage identities, shared
  readers, scalar/alias/record/list/selected-bank and read/write cases retain
  strict carriers. Portable formal/fixed/rule collisions preserve reservations;
  raw storage-role conflicts still fail executable admission. Caller inputs,
  source and child/write snapshots remain detached; absent reads stay absent.
- [x] **NO REGRESSION** — planner-qualified.log reports `All tests successful`
  for T1951. planner-schedule-before.json and planner-schedule-after.json are
  byte-identical. The complete T1951/T1950/T1949/T1946/T1255 cohort in
  planner-regression.log reports All tests successful, including non-skipped
  independent guard/read/reset execution. T1376 book fixtures and
  the synchronized book build pass; staged doctrine and hook gates remain.

Evidence: `.artifacts/formal-parent-read-products/`. Re-derivation observes the
actual production planner and installed parent interface plus public schedule;
falsification uses the missing before-name, actual portable reallocations,
raw ownership refusals, empty reads and snapshot mutations; durability is
T1951, the formal-read-products card, book and this task. The first planner-test
control assigned a non-pulse rule to the transaction's pulse done output;
strict checking correctly returned FSMGEN_LANGUAGE_MIXED_PULSE_ASSIGNMENT_FAMILY.
The rule control now uses an independent flag output. No production diagnostic
or assignment contract changed. No new production formal rewriting, writer
admission or extra storage cycle is claimed. Named-completion/readback/domain
coverage remains later; .1.3 owns the separate keyword compiler defect.
No duplicate DEVELOPMENT_NOTES rationale is needed.

### Storage identifier producer follow-up under `.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.1.3`

The book audit reproduces the same keyword defect in dataop_demo's packed
variable at docs/book/src/13e-data-manipulation.md. The literal tracked-producer
census also finds record in T1920's domain-access control; a qw(var var ...)
list in T1232 is a lexical false positive, not an ISF source declaration.
Own and repair the book example and domain control in this leaf, preserving
assembly and cross-domain access behavior. Update T248's exact expected-failure
count for the newly added named corpus fixture, retaining exact accounting.
Census scope is tracked literal var/variable forms in t, isf, perl and book
sources; it is not a proof about arbitrary interpolated/generated source.

## Acceptance — actor storage keywords `.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.1.3`

- [x] **ROOT CAUSE (WHY + WHERE)** — the original `--strict --check --json`
  succeeds for block-collision.isf, but runtime-before.json records independent
  Verilator compile failure: syntax error, unexpected cell. _parse_storage
  checked identifier shape without consulting the existing keyword registry;
  scalar variables emit their authored names as owner registers/child inputs.
  T1376 also exposes packed in the book after the new guard; the tracked literal
  census identifies the record domain control and excludes a qw-list false hit.
- [x] **ADDRESSED (verified)** — _parse_storage rejects var/variable target
  keywords with actor/name/target/rename guidance. Decision 0110 distinguishes
  emitted variable names from logical bank names. original-after.json rejects
  the exact original source with FSMGEN_LANGUAGE_ISF_STORAGE_IDENTIFIER.
  T1952 proves alias/case rules, unchanged legal spelling and bank identity,
  complete native/API/newline check/semantic failures and unchanged schedule
  refusal behavior. Independent Verilog/SystemVerilog lint accepts legal
  controls; the corrected dataop_demo example also compiles independently.
  Formal and domain test controls retain their mechanisms under legal names.
- [x] **NO REGRESSION** — qualified-final.log, regression.log and
  producer-qualified.log report `All tests successful`. The complete selected
  cohorts cover T1952, T1944/T1945/T1948/T1949/T1951, T1232/T1398/T1453,
  T1920, T248/T298/T315/T1041 and T1376. The final book builds. VHDL emission
  succeeds; independent GHDL analysis is explicitly skipped because GHDL is
  unavailable on PATH, so this slice claims no new VHDL compilation result.
  Fresh staged doctrines and normal hook remain mandatory.

Evidence: `.artifacts/storage-keyword/` plus original retained evidence in
`.artifacts/formal-parent-read-products/`. Re-derivation uses strict-before,
actual compiler failure and exact source rejection after repair; falsification
uses independent legal-control lint, keyword/case/bank controls and complete
public failures; durability is T1952 and its named corpus fixture, migrated
controls, decision 0110, fact card, book and this task. No global identifier
completeness, escaped-name support or storage access-metadata feature is claimed.

Initial test.log assumed a structured schedule failure contrary to the existing
T1898/adapter contract; it now checks the documented message-only refusal.
qualified.log used the binary-build helper for lint, which correctly refused
that invocation. qualified-lint.log exposed a missing explicit supervisor cwd;
qualified-final.log uses bounded generic lint supervision with the derived
repository root. No supervisor or containment guard was changed. The first
book/corpus gate identified packed and the new exact rejection count; the
corrected producer-qualified.log passes both. These harness corrections do not
resolve the separately owned historical process-group containment occurrence.
DEVELOPMENT_NOTES needs no duplicate of decision 0110.

Renaming packed to packed_value changes the content-derived identities of the
book's existing assembly-width claims. claim-id-map.json records the exact old
and new candidate IDs; disposition witness/producer/oracle legs are unchanged
because widths and low-to-high assembly order are unchanged. The refreshed
inventory agrees with its independent census after exact ID remapping and
sorted registry preservation. assembly-claims.log reports All tests successful
for T1099/T1200/T1344, retaining the original width/order evidence.

## Acceptance — named-completion plans `.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — `--emit-schedule-json` succeeds for
  named_products, while before-full.json records actual child input, local
  pulse and output-view DT names absent from prepared product reservations.
  ChildCompletionOutputs allocated these only in executable connection after
  storage handoffs; source preparation retained child contracts without the
  resulting parent namespace.
- [x] **ADDRESSED (verified)** — share plan_child_completion_outputs with
  source preparation after retained read/write declarations. The pure plan
  retains exact inputs, local contracts, widths/types/roles/resets, explicit
  pulse state, per-instance links and typed output/source/view identities.
  Executable connection retains mixed-writer checks before planning, then
  installs products and rewrites the original local delayed assignments.
  after.json has no missing baseline name. T1953 compares entire production
  plans and installed effects before/after projection across shared/child-only,
  typed, literal reset, multiple-instance and local/canonical controls.
  Portable formal/fixed/rule collisions retain coverage, all snapshots remain
  detached and potential planning does not admit mixed writers.
- [x] **NO REGRESSION** — qualified.log reports `All tests successful` for
  T1953; schedule-before.json and schedule-after.json compare byte-identically.
  T1376 book fixtures and synchronized build pass. The broader
  T1953/T1913/T1951/T1946/T1255 confirmation is explicitly pending in
  regression.log, with independent named-completion runtime opted in.
  Fresh staged doctrine and normal commit hook remain mandatory.

Evidence: `.artifacts/formal-named-completion-products/`. Re-derivation
observes actual production planner inputs, installed parent declarations and
rewritten local assignment objects, plus native reports; falsification uses
missing baseline declarations, actual portable allocation changes, mixed-writer
refusal, local/canonical exclusions and snapshot mutation; durability is T1953,
the formal named-completion card, book and this task. The initial test.log
combined typed output and reset metadata, which canonical parsing explicitly
defers. The corrected controls separately qualify typed output and literal-width
reset contracts; no source admission was widened. before.json recorded only
role-bearing declarations; before-full.json additionally includes view DTs.
No parent is fabricated from raw formal width maps, and no production formal
rewriting, new pulse stage or shared-writer policy is claimed. Library readback
and outer domains remain subsequent owners. No duplicate DEVELOPMENT_NOTES
rationale is needed.

## Acceptance — named-completion qualification closure `.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` on MEMORY.md's
  T1953/T1913/T1951/T1946/T1255 confirmation pointer identifies 73d4047be as
  the implementation commit with broader qualification pending. The complete
  retained regression.log now reports All tests successful; leaving the
  pointer pending would strand the next eligible library-readback leaf.
- [x] **ADDRESSED (verified)** — consume the complete reader/completion/
  schedule cohort, including independent T1913 named-completion execution and
  its full native/API/newline reports, close the leaf and advance the resume
  action with no background work. Source and tests are unchanged from the
  successful implementation/regression run.
- [x] **NO REGRESSION** — regression.log reports `All tests successful` for
  T1953/T1913/T1951/T1946/T1255. The native schedule remains byte-identical;
  T1376 already passed the unchanged runnable examples. A fresh book rebuild,
  staged doctrine gate and normal commit hook cover the qualification prose.

Evidence: `.artifacts/formal-named-completion-products/`. Re-derivation consumes
the complete retained cohort; falsification includes exact independent pulse
cycles, reset/repeated activation and actual mixed-writer refusals; durability
is T1953/T1913, the formal completion card, book and committed task history.
This is bounded completion qualification, not whole-domain namespace closure.

## Acceptance — library readback namespace `.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — `--emit-schedule-json` on the public
  fifo_library_use fixture succeeds and retains authored library output
  bindings. The remaining reservation question is whether executable
  LibraryPortOwnership or its following finalization adds declarations.
  T1954 observes those actual LoweringIR calls, delegating each call once;
  full parent snapshots expose direction/role adaptation without allocation.
- [x] **ADDRESSED (verified)** — T1954 compares the complete before/after IR
  against only the admitted explicit-interface direction and storage-role
  changes. Actual declarations remain covered by prepared source/products
  before and after formal projection. Typed, observed, direct-formal,
  generated-completion and absent-library controls preserve public contracts
  and strict emitted carriers. Rejected writers, reset/default ownership,
  duplicate drivers and generated completions introduce no name, propagate
  the original exception and prevent re-finalization. No production change
  or additional synthetic reservation product is necessary.
- [x] **NO REGRESSION** — test.log reports `All tests successful` for T1954;
  the synchronized mdBook build passes. Independent library/domain execution
  and reusable-product confirmation are pending in regression.log; the
  canonical schedule matrix and runnable examples report All tests successful
  in report-book.log. Consume the remaining runtime job before closing this leaf. Fresh staged
  doctrine and the normal commit hook remain mandatory.

Evidence: `.artifacts/formal-library-readback/`. Re-derivation observes real
lowering snapshots, stage order and native schedule bindings; falsification
uses ownership refusals, mixed generated completion, absent-library control
and formal projection; durability is T1954, the library ownership card,
composition book and this task. Outer-domain realization remains separately
owned; this does not claim whole-namespace closure or production rewriting.
The initial cohort command names a nonexistent T1255 suffix; its selected
library tests remain running, and the canonical T1255 filename discovered
from the repository passed separately with T1376. Consume every actual
result; the invalid selector is not a product regression. No duplicate
DEVELOPMENT_NOTES rationale is warranted.

## Acceptance — library readback qualification closure `.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` identifies 8ca4fe501 as
  the commit retaining the pending library/domain/reusable confirmation.
  regression.log now reports ok for each real selected test (T1954, T1914,
  T1915 and T1947), then exits nonzero because the final T1255 selector was
  mistyped. report-book.log supplies the successful canonical T1255 result.
- [x] **ADDRESSED (verified)** — consume all job results, explicitly separate
  the failed aggregate invocation from its completed successful tests, and
  close the readback leaf using those exact results plus the separately
  passing schedule/book cohort. No job remains and no source changed after
  these qualifications. Advance the durable pointer to outer domains.
- [x] **NO REGRESSION** — report-book.log reports `All tests successful` for
  canonical T1255/T1376; test.log reports the same for T1954. regression.log
  records ok for T1914/T1915 with independent runtime opted in and for T1947.
  The previous book build covers unchanged prose; staged doctrines and the
  normal hook qualify this evidence-only closure.

Evidence: `.artifacts/formal-library-readback/`. Re-derivation consumes the
actual test outputs; falsification retains FIFO queue/readback/reset/domain
observations, ownership refusals and complete native/API/newline comparisons;
durability is T1954/T1914/T1915/T1947/T1255, the canonical card and task history.
The aggregate selector failure is an invocation mistake, not a passing exit
or a product defect. No successful test is rerun solely to replace that log.

The first closure doctrine gate correctly rejected a refreshed shipped-book
aggregate authority with no book aggregate change. The evidence-only closure
now retains the existing authority; no ceiling or verifier was relaxed.
The follow-up gate caught task-evidence allowance drift after that note was
added. Refreshing the existing owned transition allowance after the final
task edit corrects it; enforcement ceilings remain unchanged.

## Acceptance — domain capability prose `.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.3.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` traces the storage-read
  refusal paragraph in 13a-actor-interface.md to 01718f524, the initial
  domain-child artifact realization. Later qualification under .39.2.2.2.3.2,
  .46, .47 and .48 changed supported behavior without updating this summary.
  The current domain/storage/completion/library fact cards and their task
  evidence contradict that paragraph's storage refusal and deferred ownership.
- [x] **ADDRESSED (verified)** — replace the obsolete limits with live
  same-domain scalar/signed/packed aggregate/selected-bank reads, owner-held
  registers/resets, named completion forwarding and domain-selected library
  readback. Keep sibling-domain refusal and independently pending watchdog,
  local-call and VHDL boundaries explicit. Link to maintained composition
  detail instead of duplicating its examples or acceptance history.
- [x] **NO REGRESSION** — book-fixtures.log reports `All tests successful`
  for T1376; book.log records a successful synchronized mdBook build.
  Existing canonical cards retain their dated independent runtime/report
  qualifications; this prose-only slice changes no implementation or fixture
  and does not claim a new runtime run. Staged doctrine and normal hook apply.

Evidence: `.artifacts/domain-capability-docs/`. Re-derivation joins exact Git
history and canonical qualified behavior; falsification compares the prior
refusal claim with the supported T1916/T1913/T1914/T1915 contracts and preserves
unqualified limits; durability is the corrected book and this defect-owning
leaf. The finding was surfaced before repair. DEVELOPMENT_NOTES needs no
additional copy of these established contracts.

## Acceptance — actual domain source products `.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.3.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — `--emit-schedule-json` succeeds for
  activation.isf, but activation-before.json identifies actual caller
  parent_do_1_ready, parent_do_1_req and worker_start_ready plus callee
  worker_idle_ext, worker_done_ready and worker_done_req absent from
  monolithic preparation. The scheduler alone constructed filtered domain
  actors and injected external_activations before local lowering. Ordinary
  event/no-reset controls have no missing baseline declaration.
- [x] **ADDRESSED (verified)** — extract the unchanged canonical domain
  source constructor and its helpers into DomainSource, retaining imported
  scheduler helper identities for existing consumers. Formal preparation
  invokes the same constructor and retains domain_source_products with typed
  actor/domain identity, detached partition metadata and complete independent
  local preparation. Clearing clock_domains terminates recursion; no parent
  merge or fabricated executable IR is used. activation-after.json has no
  missing names. T1955 compares actual source construction and local products,
  checks emitted declaration coverage and strict composition, projects portable
  formal/helper aliases, verifies ownership and snapshot isolation, forbids
  build_module during preparation and preserves unused-crossing refusal.
- [x] **NO REGRESSION** — qualified-final.log reports `All tests successful`
  for T1955; schedule-before.json and schedule-after.json compare byte-identically.
  regression.log reports All tests successful for the complete
  T1955/T1247/T1387/T1924/T1942/T1945/T1912 cohort with independent domain
  runtime and public-report confirmation enabled. Every job result is consumed.
  T1376 book fixtures and synchronized book build pass. Fresh staged doctrine
  and normal hook qualify the implementation commit before final closure.

Evidence: `.artifacts/formal-domain-products/`. Re-derivation observes actual
production domain sources and declarations plus native reports; falsification
uses the missing activation baseline, event controls, case-only domains,
portable helper/formal aliases, forbidden parent merge, empty/no-domain controls,
source/sibling mutation isolation and unused-crossing refusal; durability is
T1955, the domain-source card, book and this task. The initial test used a
nonexistent source path for library resolution; it now uses the real public
FIFO fixture path. A subsequent case-only test-label directory collision was
fixed with unique ordinal artifact directories on the case-insensitive volume.
These harness corrections did not alter library resolution or source admission.
Outer composition identities remain child .2, integration child .3, and the
previously observed stale activation-test header child .4. No production formal
rewriting or new controller/runtime semantics are claimed. No additional
DEVELOPMENT_NOTES rationale is needed beyond the canonical fact and task.

## Acceptance — outer domain scope `.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.3.2.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` identifies 01718f524 as
  the introduction of _multi_domain_realizations. Its allocator records
  separate module/file and flat-instance identities; the remaining question
  is whether that outer stage or emission adds unreserved local declarations.
  T1956 observes real public lowering, allocated metadata and complete domain
  IR through actual file/top emission rather than constructing a surrogate.
- [x] **ADDRESSED (verified)** — exact emitted FSM children, CDC children
  and interfaces, wiring labels and files match actual realization metadata.
  Every actual local declaration is covered by its independent prepared domain
  inventory; complete domain/child IR remains unchanged by file materialization
  and top emission. Formal projection preserves every outer identity and public
  port declaration. Reused generated children, library/empty siblings,
  event/activation/no-reset, keyword/case domains and actual public-pin/module
  collisions pass. This proves a separate-scope boundary; no extra local
  reservation producer or production naming change is necessary.
- [x] **NO REGRESSION** — qualified-final.log reports `All tests successful`
  for T1956. T1376 book examples and synchronized book build pass. The complete
  T1956/T1955/T1895/T1947/T1255 naming/reusable/report cohort is in flight in
  regression.log with independent naming runtime opted in. Consume its complete
  result before closing the leaf; staged doctrines and normal hook apply.

Evidence: `.artifacts/formal-domain-outer/`. Re-derivation observes actual
outer allocations, emitted declaration scopes and unchanged complete local IR;
falsification uses genuine pin/module conflicts, portable domain variants,
formal projection and the canonical multi-domain ATL event refusal; durability
is T1956, the generated-domain identity card, book and this task. The initial
pair comparator accidentally captured the lexical actor variable instead of
Perl's sort variable; moving it to a separate helper fixed the harness. The ATL
positive exploration reached the existing parser single-clock refusal; the
final test locks that boundary instead of widening support or claiming ATL
runtime qualification. Complete domain reservation integration remains child
.3. DEVELOPMENT_NOTES needs no duplicate of the scoped naming contract.

## Acceptance — outer scope qualification closure `.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.3.2.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` identifies fc19fb1f5 as
  the commit retaining the pending naming/runtime/reusable/report cohort.
  regression.log now reports All tests successful for every selected file;
  retaining the pending pointer would strand the next domain integration leaf.
- [x] **ADDRESSED (verified)** — consume the full T1956/T1955/T1895/T1947/
  T1255 result, close outer-scope qualification and advance the durable resume
  action. T1895 includes independently observed CDC/reset behavior and complete
  native/API/newline identity reports. No background result remains, and no
  implementation or test changed after those runs.
- [x] **NO REGRESSION** — regression.log reports `All tests successful` for
  the complete selected cohort with qualified runtime enabled. T1376 and the
  existing synchronized build cover the unchanged book. Fresh staged doctrine
  and normal hook cover this evidence-only closure.

Evidence: `.artifacts/formal-domain-outer/`. Re-derivation consumes actual
cohort outputs; falsification includes real namespace collisions, case-safe
materialization, public-only HDL oracles and explicit ATL refusal; durability
is T1956/T1895 and the canonical naming card/task. This does not close domain
integration or the separately owned watchdog/local-call/containment issues.

### Discovered blocking defect — composed-domain activation handoff

Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.3.2.3.
Reproduction: T1957 activation_composed in
`.artifacts/formal-domain-integration/qualified-combined.log` lowers successfully,
then strict-checking its exported top rejects unconnected core.remote_done.
Impact: composing a generated child and an external domain activation drops an
explicit CDC handoff and prevents hardware admission. Priority: immediate,
blocking this integration leaf. Resolved: the isf_handoff filter discarded explicit
outer sources/targets routes already removed from outer-only wiring. Preserve
direction-matching mapped handoffs; strict public admission and independent
SystemVerilog/Verilog execution now pass (acceptance below).


## Acceptance — combined domain integration and activation handoff repair `.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.3.2.3`

- [x] **ROOT CAUSE (WHY + WHERE)** — native `--check --json` reports
  success false and unconnected core.remote_done for composed-activation.isf.
  handoff-before.json observes actual external activation ports marked
  isf_handoff and their explicit direction-specific sources/targets maps.
  CompositionTop skipped those ports after the outer emitter transferred their
  CDC routes to the maps. The minimal public reproduction needs no formal
  projection; this is a shipped composition routing defect exposed by T1957.
- [x] **ADDRESSED (verified)** — retain explicitly mapped input/output
  handoffs at the component boundary while leaving unmapped child handoffs
  internal. composed-after.json reports success true. T1958 checks exact CDC
  routes, strict exported replay, private public interfaces and complete native,
  API and newline check/semantic/schedule equality for composed caller,
  composed caller/callee and library-composed caller. Independent SystemVerilog
  and Verilog public-pin oracles verify stopped destination clock, reset,
  repeated activation and no replay for the generated-child cases. T1957 joins
  actual domain products, physical projection, width/shadow/resource/priority
  ownership, generated reads/writes, shared completion and collision controls.
- [x] **NO REGRESSION** — runtime.log and qualified-fixed.log report
  `All tests successful` for T1958 and T1957. regression.log reports the same
  for T1957/T1955/T1956/T1948/T1949/T1953/T1954/T1387/T1255. Book fixtures
  T1376 and synchronized mdBook build pass. All results are consumed; staged
  doctrines and the normal hook cover this slice before commit.

Evidence: `.artifacts/formal-domain-integration/`. Re-derivation observes actual
prepared and executable products, boundary maps and strict public reports;
falsification uses the failing pre-fix source, stopped-clock independent HDL
oracles, declaration permutations, exact/case-folded conflicts and retained
competing-writer refusal; durability is T1957/T1958, the composed-handoff and
domain-source fact cards, runnable book example and this defect-owning leaf.
Harness corrections parenthesized a Perl grep before the assertion label and
removed an unbound formal from the control-only activation fixture. Neither
changed production admission. The global fail-closed reservation contract and
automatic production formal rewrite remain subsequent leaves. Existing
watchdog/local-call/containment issues remain separately owned. Engineering
rationale is owned by the canonical card; no duplicate ledger entry is needed.


## Acceptance — activation test commentary and producer closure `.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.3.2.4`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` identifies 13cbceeb6,
  which replaced T1386's blanket lowering refusal with the unused-crossing
  diagnostic but left the file header claiming all routing was deferred.
  The actual supported handshake is exercised by T1387 and documented in 13a.
- [x] **ADDRESSED (verified)** — the header now distinguishes parsing,
  unused-crossing refusal and supported start/done CDC lowering. The book
  clarifies that declaration alone creates no activation. No assertion or
  admission code changed. Close only producer ancestors whose declared children
  are all done; leave the separate global completeness integration leaf open.
- [x] **NO REGRESSION** — tests.log reports `All tests successful` for
  T1386/T1387. This comment-only test change preserves every executable test
  statement; the book adds explanatory prose only. Staged doctrines and the
  normal hook verify task-tree closure and documentation consistency.

Evidence: `.artifacts/activation-header/tests.log`; exact ancestor closure list
in `.artifacts/activation-header/closed-parents.txt`. Re-derivation joins the
introducing Git diff and current tests; falsification retains malformed and
unused refusal controls beside supported handshake lowering; durability is the
corrected test header, book and task frontier. No fresh runtime, full-CI or
complete-production-reservation claim is made. Existing child evidence remains
in place; parent closure does not widen any individual qualification boundary.


## Acceptance — checked prepared reservation inputs `.49.2.2.3.2.2.3.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` identifies f3a6fc691
  as the generic FormalReservationInventory collector introduction. It accepts
  any explicit product hash, while domain integration chose products by suffix.
  An omitted category therefore had no input-contract failure. Actual
  prepare_formal_source shapes are captured in shape.log; final producer
  qualification establishes the categories to require without a parent merge.
- [x] **ADDRESSED (verified)** — PreparedFormalReservations checks the
  complete preparation category schema, live transaction/context and generated
  child membership, reusable product shape, source partition membership and
  domain identity before returning the conservative inventory and explicit
  independent module scopes. It preserves the existing generic partial API.
  T1959 rejects removed/malformed categories, unknown producers, missing child
  IR and erased/misidentified domains, including erasure from both product maps.
  Real FIFO, generated children, static-zero and single-domain controls pass.
  T1957 now uses the checked collector in actual projected domain integration.
- [x] **NO REGRESSION** — regression.log reports `All tests successful`
  for T1959/T1957/T1937/T1955/T1956. T1376 book examples and synchronized
  mdBook build pass; all results are consumed. Staged doctrines and the normal
  hook qualify the source, test and documentation slice before commit.

Evidence: `.artifacts/formal-reservation-contract/`. Re-derivation reads actual
preparation products and preserves the previously qualified identifier/provenance
union; falsification deletes real categories and scope members, corrupts owner
identities, introduces cycles and tests reordered/detached results; durability
is T1959, the migrated T1957 consumer, canonical fact card and book. The input
schema does not authenticate arbitrary edited product contents or prove final
executable declarations. That independent check remains child .2, before
production integration. No extra DEVELOPMENT_NOTES rationale is needed.


## Acceptance — final module reservation coverage `.49.2.2.3.2.2.3.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — actual public-lowering modules
  strict-check with `--check --json`, but the checked input schema alone also
  accepts a structurally valid preparation with every occurrence of an actual
  dynamic-wait helper removed. T1960 preserves the canonical private plan under
  that mutation, exposing the missing final declaration comparison independently
  of the input contract. Actual declarations must be checked in their own scopes.
- [x] **ADDRESSED (verified)** — FormalReservationCoverage verifies the
  canonical allocation plan, exact physical parent/domain module set and child
  identities; it checks actual explicit and implicit declarations against each
  prepared scope plus that scope's live private formals. Direct formals retain
  counter/width-map widths, transaction_port roles and fixed-name separation.
  The omitted real helper now fails with unreserved declarations. Late registers,
  implicit assignment targets, stale plans, wrong/missing modules, nested children,
  changed widths/roles, block aliases and parent-formal leakage into a child also
  fail. Actual generated, FIFO, ATL, storage, rule and monitor cases strict-replay;
  T1957 verifies combined domain declarations. Inputs remain unchanged.
- [x] **NO REGRESSION** — regression.log reports `All tests successful`
  for T1960/T1957/T1959/T1941/T1939/T1947/T1255. final-focused.log reports the
  same for final T1960 including the added child-scope mutation and T1376 book
  examples. The synchronized book build passes. Every result is consumed;
  staged doctrines and normal hook qualify this slice before commit.

Evidence: `.artifacts/formal-reservation-coverage/`. Re-derivation observes actual
public-lowering modules and emitted carriers; falsification mutates real producer
names, allocation and executable scope/declaration ownership independently of
collection; durability is T1960/T1957, the coverage fact card and book. This
closes the detached ISF-to-FSM reservation gate and its exhausted parent tasks,
not automatic production renaming, arbitrary IR semantic correctness, independent
controllers, local-call runtime or the historical containment issue. Production
integration and complete source-facing report preservation remain .49.2.2.3.3.
The exact exhausted-parent list is retained in closed-parents.txt. Canonical
fact/task records own the rationale without a duplicate DEVELOPMENT_NOTES entry.


## Acceptance — authored binding report preparation `.49.2.2.3.3.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` identifies 1211bd617
  as the canonical transaction binding metadata producer introduction.
  T1961 observes that applying the qualified physical resolver changes the
  caller actor_signal and callee port in the current report, whereas the public
  contract requires authored binding provenance and formatted source expressions.
  The producer is independent of parent declaration merging; retain its original
  source records before the production rewrite switch.
- [x] **ADDRESSED (verified)** — prepare_formal_source retains a detached
  transaction_binding_report_products array from that existing producer, also
  in each actual domain preparation. The checked inventory explicitly requires
  and classifies the new category. Complete records equal ordinary public
  binding reports and actual local domain metadata, including local/generated/
  rule sites, widths, scalar/output/expression endpoints, authored timing and
  handoff/helper names. Raw storage/formal shadows retain records without a
  parent merge while executable raw collisions still fail. The old partial
  producer comment is corrected to reference the separate final coverage guard.
- [x] **NO REGRESSION** — test.log and regression.log report
  `All tests successful`; the complete cohort is T1961/T1959/T1960/T1957/
  T1243/T1241/T1255. T1961 compares whole native/API/newline schedule reports.
  T1376 book examples and synchronized mdBook build pass. All jobs are consumed;
  staged doctrines and normal hook qualify this slice before commit.

Evidence: `.artifacts/formal-source-binding-reports/`. Re-derivation invokes the
same canonical producer used by ordinary reports; falsification contrasts actual
physical endpoint reports with the unchanged source snapshot, exercises raw
width/role refusal, local-domain ownership and snapshot mutation; durability is
T1961, the checked preparation schema, canonical fact card and book. This private
product does not add public report keys, switch production naming or qualify
independent execution. Child .2 must use original source records for authored
report provenance while keeping executable operands physical. The canonical
fact/task records own the rationale without a duplicate ledger entry.


## Acceptance — production formal integration `.49.2.2.3.3.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — Native `--check --json` in the retained
  pre-integration scope tests refused actor/formal width or role collisions.
  Scheduler lower/report sent raw formal names directly into the parent merger.
  The qualified detached allocator/resolver and final scope guard were not on
  that path; source binding reports read the same executable endpoints.
- [x] **ADDRESSED (verified)** — FormalLowering connects complete preparation,
  canonical allocation and scoped rewriting before actual module construction.
  Final declaration coverage runs before emission for parent and domain scopes.
  Report-only copies restore original binding records and source operands;
  actual executable wait/loop fields remain physical. T1962 observes separate
  actor-pin/storage and private formal widths, source immutability, generated
  storage readback, automatic domain projection and strict carrier replay.
  Independent public-pin SV/Verilog oracles emit PRODUCTION_FORMAL_SCOPE_PASS
  through dynamic waits, reset and repeated activation. An injected unreserved
  helper fails before any FSM emission. T1961 distinguishes physical domain
  binding endpoints from the restored original report records.
- [x] **NO REGRESSION** — runtime.log and migrated.log report
  `All tests successful`; the migrated cohort covers T1925/T1927/T1928/T1933/
  T1936/T1955/T1956/T1241/T1962. The initial broader cohort's other cases passed,
  including T1926/T1929/T1934/T1935/T1937..T1939/T1941..T1949/T1951/T1953/
  T1954/T1957/T1959/T1960/T1961/T1243/T1244/T1255. Its failures were obsolete
  raw-name/refusal expectations, now replaced with positive separated-storage
  checks while preserving admission controls. T1376 and the mdBook build pass.
  Staged doctrines and the normal hook are required before commit.

Evidence: `.artifacts/formal-production-integration/`. Re-derivation observes
actual production declarations and complete native/API/newline reports;
falsification retains actor shadows, differing domain widths, source immutability,
late declaration injection and independent public-pin runtime; durability is
T1962, migrated regression assertions, canonical facts, book/spec and final scope
guard. The report projection is deliberately detached because executable loop
and wait wiring consumes source-labelled fields. Explicit already-projected
private callers retain compatibility without a second rewrite. No controller,
plain local-call runtime, explicit-local ownership or historical containment
repair is claimed. These remain owned; .49.2.2.3.4 is the next family gate.

The first staged gate rejected lowercase/underscore authority-ID suffixes for
the changed book/spec aggregates. This slice corrects them to valid uppercase
hyphenated IDs; the aggregate evidence and ceilings are unchanged.


## Owned finding — private formal port leakage under `.49.2.2.3.4`

T1368's direct transaction parameter fixture reads an unassigned formal `addr`.
After physical allocation, HDL exposes `input wire [7:0] isf_port_main_addr`.
The parent IR carries transaction_port width/role but explicit_internal_signals
contains only actor storage; +size cannot prevent usage-based input inference.
Impact: private direct formals leak into public interfaces despite unique names.
Reproduce with the retained initial/migrated family cohort and T1368. Priority:
blocking scope signoff, owned and fixed within this current leaf before payload
work. Add direct formals to parent/domain explicit internal declarations and
require that classification in final coverage. Preserve generated-child ports,
unused/read-only formal widths/types and uninitialized-value semantics; verify
exact semantic/HDL ports and a missing-internal-classification negative control.
Evidence directory: `.artifacts/formal-family-qualification/`.


## Acceptance — production scope families `.49.2.2.3.4`

- [x] **ROOT CAUSE (WHY + WHERE)** — T1368's emitted HDL exposes unassigned
  `isf_port_main_addr` as an input. The native `--emit-semantic-json` port
  inventory is the independent public boundary oracle. LoweringIR parent
  construction put only actor storage in explicit_internal_signals: formal
  width/role alone in +size left read-only formals subject to input inference.
  This disproved complete physical ownership and blocked scope signoff.
- [x] **ADDRESSED (verified)** — Parent/domain lowering includes direct formal
  storage in explicit internal roles, while generated children keep their own
  public interface builder. Final reservation coverage requires the internal
  classification. T1963 proves exact semantic public ports, SV/Verilog/VHDL
  private declarations, read-only and unused widths, and a missing-classification
  negative control. It also checks detached report/IR mutation isolation,
  loop/exit/continue and bank source operands, stage/monitor actor ownership,
  typed sibling permutations and real helper-name collisions. No initial value
  or driver is invented. Earlier width/selector tests now name private signals.
- [x] **NO REGRESSION** — internal-fix.log, runtime.log and regression.log report
  `All tests successful`. T1960/T1957 retain final reservation/domain coverage;
  T1962/T1510 independently execute private payload/reset/readback and loop
  truthiness. The broad focused cohort covers declarations, parameter/constant/
  package widths, binding conflicts, loops/early exits/continues, stages, banks,
  nested generated/local activations, report keys/order, internal ownership,
  source binding views and T1376 book examples. The mdBook build passes. VHDL
  declarations are checked; this slice makes no VHDL simulation claim.

Evidence: `.artifacts/formal-family-qualification/`. Re-derivation observes
source reports, actual IR and native public ports; falsification includes the
retained input leak, omission of explicit internal classification, typed/case
collisions, report ownership mutation and independent runtime; durability is
T1963, migrated family assertions and the strengthened final scope guard. The
initial family failures separate obsolete physical-name expectations from the
real interface leak. The new monitor probe was corrected to preserve the empty
legacy temporal-contract table: monitor assertions are DT/assertion products,
not the removed contract syntax. The source frontier narrative is synchronized
with the completed scope prerequisites. All remaining execution defects retain
their owners; next is local rule-trigger payload retention .32.1.3.3.1.3.2.

## Acceptance — scoped local-payload baseline `.32.1.3.3.1.3.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` identifies
  0ee9dca5634d69c3d85e660dd7bbc20507abfbfb introducing the local payload fan-in.
  _rule_trigger_payload_fanin_assignments still emits a request-guarded `=`
  assignment. Current strict production HDL completes the retained local target
  but returns zero after waits. Fresh `--emit-schedule-json` also exposes child
  completion storage roles/kind absent from the advertised public enumerations.
- [x] **ADDRESSED (verified)** — The bounded scoped-baseline audit authenticates
  unchanged canonical source/testbench hashes and exact local-failure/generated-
  live-control observations at b7b18c76095e2c08a629f823d964a2fd28afad93. The tracked
  reproduction command runs successfully and reproduces those classifications;
  its local simulation failures are expected evidence, not a repair pass.
  Acceptance must preserve entry-cycle visibility, actual capture eligibility,
  busy isolation and source/grant guards; helper preparation and domain coverage
  are explicit obligations. New enumeration defect .56 is scheduled before
  snapshot integration. Implementation and runtime signoff are children .2/.3.
- [x] **NO REGRESSION** — regression.log reports `All tests successful` for
  T1171/T1243/T1255/T1376. The mdBook build passes. No production source or
  counterfactual HDL is changed. The staged doctrine gate and normal hook must
  pass before commit.

Evidence: `.artifacts/local-rule-payload/` and the tracked scoped-baseline audit
and reproduction entrypoint. Re-derivation compiles current strict production;
falsification contrasts stable/changed local snapshot failures with both passing
generated-live controls and verifies canonical input hashes; durability is the
bounded audit, tracked replay, canonical fact and owned dependency leaves. This
slice closes only baseline recovery and implementation prerequisites. It does
not close the payload defect, controller/local-call failures or historical
native process-containment occurrence.


## Acceptance — generated report enumerations `.56`

- [x] **ROOT CAUSE (WHY + WHERE)** — Native `--emit-schedule-json` on the
  generated-role fixture emits child_completion_seen/view/output_handoff and
  local_completion_pulse storage roles plus child_completion/output and
  actor_storage_read/write_handoff DT kinds. Their actual producers are
  ChildCompletion, ChildCompletionOutputs and ChildStorageOwnership. The
  canonical public-interface enum omitted them; earlier membership fixtures
  did not exercise these producer families together.
- [x] **ADDRESSED (verified)** — The canonical advertised enum includes each
  actual missing value. T1964 requires all observed values to be advertised and
  all repaired values to occur, and detects every deliberate descriptor omission
  against the actual report. T1158 extends its all-advertised-DT-kind coverage.
  Strict source checking and complete native/API/newline schedule agreement pass.
  Before/after production schedule reports are identical. No lowering behavior
  or public key set changes. The stale direct-formal lookup in T1148 now uses its
  private name while preserving kind/role/width assertions. The spec also agrees
  with the book on the empty legacy temporal-contract array.
- [x] **NO REGRESSION** — fixed.log reports `All tests successful` for
  T1964/T1140/T1148/T1158/T1255/T1376. The mdBook build passes. All result jobs
  are consumed; staged doctrines and the normal hook qualify this commit.

Evidence: `.artifacts/schedule-enumeration/`. Re-derivation joins production
reports to source producers; falsification removes each advertised value while
retaining its observed producer output; durability is the fixture, enum and
metadata coverage tests, fact card, book/spec and task. This closes the owned
report-contract gap before snapshot additions. It does not qualify local payload
retention, controller execution or the remaining SPECFORGE storage-access feature.

## Acceptance — local snapshot integration `.32.1.3.3.1.3.2.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — The scoped baseline and native
  `--emit-schedule-json` local payload report isolate the pulse-guarded formal
  assignments from retained per-rule sources. `_rule_trigger_payload_fanin_assignments`
  formerly lost the value outside that request pulse. A source register alone
  cannot preserve the target's accepted invocation when a later busy request
  updates it. The target's actual first owned state and authored guard define
  the capture boundary; gating the entry view by a payload-dependent guard
  would create a combinational cycle.
- [x] **ADDRESSED (verified)** — A shared producer plans initial-state request
  views and accepted-payload capture for detached preparation and actual
  parent/domain lowering. It reserves source formal spellings across projection,
  retains width/type/internal binding ownership, preserves per-source guards
  and leaves generated paths unchanged. T1965 proves typed collision stability,
  domain isolation, mandatory preparation and unreserved-declaration controls,
  complete native/API/newline reports and strict carrier replay. Independent
  SV/Verilog public-pin oracles pass entry samples and delayed reads with a
  payload-qualified leading when. The retained original reproduction now reads
  seven for stable/changed local inputs; generated live reads remain seven and
  thirteen. No emitted HDL is edited. Initial negative-control design was
  corrected: erasing a producer record alone retains downstream reservations;
  a truly unreserved emitted declaration is the relevant final-coverage control.
- [x] **NO REGRESSION** — focused.log, compatibility-fixed.log and
  book-examples.log report `All tests successful` for T1965/T1171/T1243/T1255/
  T1959/T1963, T1241/T1242/T1248/T1176/T1219 and T1376 respectively. T1241's
  obsolete pulse-only expectation now checks all accepted/held paths. The
  mdBook build passes and all verification jobs are consumed. Staged doctrines
  and the normal hook qualify this commit; broader runtime is the next leaf.

Evidence: `.artifacts/local-rule-snapshot/` and the original canonical audit
source/testbench. Re-derivation follows actual prepared and emitted products;
falsification uses missing-category/unreserved-declaration controls plus an
independent public-pin changed-input oracle; durability is T1965 and its fixture,
the canonical retention card, book/spec and this owner. This closes integration,
not broad repeated/reset/granted-source qualification or independent controllers.

## Acceptance — local snapshot runtime `.32.1.3.3.1.3.2.3`

- [x] **ROOT CAUSE (WHY + WHERE)** — Native `--strict --check --json` and
  `--emit-schedule-json` succeed for priority/round-robin payload fixtures, but
  admission/report agreement alone cannot prove accepted-invocation retention.
  T1966 drives public pins through waits and a later on to exercise that
  distinction. The first oracle exposed a testbench timing error: the next
  entry sample may update with the previous delayed done pulse; waiting on its
  still-high level also reused that previous completion. The terminal carrier's
  delayed pulse and return-to-entry contract explain both observations.
- [x] **ADDRESSED (verified)** — T1966 now samples entry values at admission
  and checks completed results against a fresh counted done event. Both emitted
  Verilog families pass changed/repeated sources, false admission and zero
  payload rejection, busy requests at a later on, reset abort/fresh re-entry,
  held level requests and priority/round-robin grants. Ungranted overlap trips
  the actual payload selector assertion instead of choosing a winner. An
  unguarded target still completes without any request. Canonical generated-live
  source/testbench hashes match and stable/changed live results remain correct.
  Exact public ports, complete native/API/newline check/semantic/schedule
  responses and exported carrier replay pass. No production change was needed.
- [x] **NO REGRESSION** — runtime-qualified.log and focused.log report
  `All tests successful` for T1966 and T1218/T1242/T1944/T1376. The mdBook build
  passes. All jobs are consumed. Task acceptance and the normal hook qualify
  the commit. The stale active-index pointer to formal integration is replaced
  by the live shared-write frontier; decision/card status distinguishes the
  completed payload repair from still-unqualified controller/local-call work.

Evidence: `.artifacts/local-rule-snapshot-runtime/`. Re-derivation checks
production carriers/reports and fresh public-pin invocation observations;
falsification includes ungranted overlap, rejected requests, changed busy inputs
and reset abort; durability is T1966, the source/testbench fixtures, retention
card, updated decision consequence and mdBook. The owned parent .2 closes;
shared-write admission .3 is next. No independent-controller, VHDL runtime,
local-call or requested storage/register-access metadata completion is claimed.

## Acceptance — direct writer baseline `.32.1.3.3.1.3.3.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — `--strict --check --json` admits
  direct scalar/output overlaps and `--emit-schedule-json` reports no compile
  issue or transaction-priority resolution. Actual final IR writers show the
  shared physical targets. `_build_conflict_issues` compares equal target strings
  and handles rule/rule errors and rule/drive warnings; the separate priority
  pass handles rule/transaction pairs. Relevant introduction history is
  f657a6c89c9ce1771cc8f02f1d90bd958739203d and
  49711b6dbee775600d924da3f92819136c52c567. Existing state provenance/priority
  recovers owners from spellings despite explicit state.transaction membership.
- [x] **ADDRESSED (verified)** — The source-hashed baseline retains current
  checks, schedule findings, actual physical writers and explicit state owners.
  It distinguishes private formals, disjoint/equal scalars, scalar bank entries,
  aggregate whole/member/disjoint leaves, full-register masked updates, named
  drive payload helpers and completion fan-in. Existing rule rejection messages
  are preserved as unclassified diagnostics, not promoted to stable codes.
  The manifest authenticates source/producer/reproducer/result files at the
  recorded revision; replay regenerates result.json exactly. Children .2/.3
  own a complete detached writer inventory and conservative admission before
  independent-controller execution. No new arbitration or safety is claimed.
- [x] **NO REGRESSION** — focused.log reports `All tests successful` for
  T1209/T1219/T1261/T1403. The mdBook build passes; the tracked reproducer
  completes with exact retained output and all jobs are consumed. Staged
  doctrines and normal hooks qualify the evidence commit. Production code,
  source admission and emitted execution are unchanged by this baseline slice.

Evidence: `docs/audits/direct-writer-admission-20260927/` and
`.artifacts/direct-writer-admission/`. Re-derivation joins native check/schedule
outcomes to actual lowered writers and relevant history; falsification uses
separate/private/same-value/pulse controls and current rejecting rule pairs;
durability is the authenticated baseline/reproducer, canonical writer-boundary
card, task decomposition and mdBook. The known direct-controller runtime audit
remains authoritative and is not re-run as an admission proof.

## Acceptance — physical write targets `.32.1.3.3.1.3.3.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — The retained native
  `--emit-schedule-json` admission baseline and actual final writer records
  distinguish frame from frame.mode even though their physical bits overlap;
  disjoint set-field syntax instead writes the same whole value_reg. Equal
  target strings cannot express the required physical relation. The existing
  Package::AggregatePathSupport owns declared aggregate path traversal and
  packed offsets, so this prerequisite reuses it rather than another walker.
- [x] **ADDRESSED (verified)** — PhysicalWriteTargets resolves a declared
  module/root/packed range and compares intersection only within that identity.
  T1967 resolves every actual assignment target in the admitted baseline,
  retains separate private formals/bank entries, recognizes whole/member overlap
  and disjoint leaves, and treats masked updates as whole-root writes. Independent
  nested record/list arithmetic, symmetric overlap and separate-module controls
  pass. Unknown declarations/paths, type-width mismatches, malformed ranges and
  inconsistent same-root widths are refused. Returned records are detached.
  The helper is not invoked by production lowering or writer admission yet.
- [x] **NO REGRESSION** — regression.log reports `All tests successful` for
  T1967/T284/T283/T1261, including the canonical package/composition path tests.
  The mdBook build passes and all verification jobs are consumed. Staged
  doctrine checks and the normal hook qualify this commit; full declaration/
  owner collection and shadow attachment remain the following children.

Evidence: `.artifacts/physical-write-targets/` and the authenticated direct
writer baseline. Re-derivation joins actual lowered assignments to resolved
source declarations; falsification uses independent packed-range arithmetic,
module isolation and malformed/omitted contracts; durability is the helper,
T1967, the canonical writer card, book and this task. No new accepted syntax,
controller behavior, public report or arbitration is introduced.

## Acceptance — explicit writer declarations `.32.1.3.3.1.3.3.2.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — The retained `--emit-schedule-json`
  writer baseline requires actual target declarations rather than raw target
  spelling. Emitter::FSM::_emit_size emits ports, declared storage, counters
  and assembly operands; LoweringIR::signal_widths additionally contains known
  expression/sample widths that are not emitted declarations. T1968 reproduces
  a known-width captured alias that has no +size entry, so blindly treating the
  width map as a declaration inventory would hide an unresolved obligation.
- [x] **ADDRESSED (verified)** — PhysicalWriteDeclarations returns detached
  module-local explicit declarations with resolved widths, emitted tokens,
  origins and aggregate layouts. It checks declared assignment paths through
  PhysicalWriteTargets and lists unresolved targets without inventing widths.
  T1968 independently parses actual emitted +size entries for the admitted
  baseline and generated post-wiring parent/child modules. Typed private formals,
  local registers, aggregate ranges and assembly widths agree; static operands
  stay excluded. Precedence, omission, malformed-contract and nested-mutation
  controls pass. No production consumer or admission change is introduced.
- [x] **NO REGRESSION** — regression.log reports `All tests successful` for
  T1968/T1967/T1344/T1963. The mdBook build passes. Staged doctrine checks and
  normal commit hooks qualify this slice. Implicit scalar resolution is owned
  by .3.2.2.2; source/generated ownership and complete shadow coverage remain
  the following children, with independent execution still separately pending.

Evidence: `.artifacts/physical-write-declarations/`. Re-derivation compares
actual emitter declarations with collected contracts; falsification removes
storage declarations despite retained width-map entries and mutates target/type
contracts; durability is T1968, the canonical writer card, book and this tree.
The helper is deliberately incomplete for implicit targets and does not claim
whole-inventory or writer-safety signoff. No new quantitative performance claim.

## Acceptance — implicit writer targets `.32.1.3.3.1.3.3.2.2.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — The native `--emit-semantic-json`
  probe exposes captured/copy roots in structural_rtl_ir.nets with widths
  inferred downstream despite their absence from emitted +size. The canonical
  FSMGenFull parser owns assignment width inference and later simple-signal
  reconciliation. Reimplementing that inference in scheduling would duplicate
  a separate stage; whole-root overlap instead requires identity and full
  coverage, independent of the final inferred width.
- [x] **ADDRESSED (verified)** — PhysicalWriteTargets::whole_root supplies
  conservative width-free coverage, and PhysicalWriteDeclarations::target_contracts
  pairs every actual assignment spelling with an explicit range or whole-root
  contract. T1969 proves complete native/carrier semantic equality under width
  and state-order variants, canonical inferred sample/copy widths, actual
  sibling root overlap, separate roots/modules and symmetric mixed whole/member
  overlap. Missing layouts cannot turn partial paths into implicit evidence;
  malformed coverage and returned-record mutation controls pass. Explicit
  declaration collection still exposes unknown widths rather than inventing them.
- [x] **NO REGRESSION** — regression.log reports `All tests successful` for
  T1969/T1968/T1967/T310, including canonical downstream inference regressions.
  The mdBook build passes. Staged doctrines and normal hooks qualify this slice.
  No production admission or execution path consumes these detached contracts;
  explicit producer ownership and complete shadow attachment remain owned next.

Evidence: `.artifacts/implicit-write-targets/`. Re-derivation compares native
and emitted-carrier semantic products and actual downstream net widths;
falsification changes inferred widths/order and removes layouts or corrupts
coverage; durability is T1969, the canonical writer card, book and this tree.
Whole-root coverage proves overlap only; it does not infer a width, partial
layout, ownership, mutual exclusion or arbitration grant.

## Acceptance — source writer identities `.32.1.3.3.1.3.3.2.2.3.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — The complete native
  `--emit-schedule-json` fixture exposes latency/monitor DTs through existing
  generated-name provenance; source identity is not an explicit DT contract.
  _build_transaction knows the creating transaction, _build_rules knows the
  authored rule, and _build_drive_dts knows the drive definition. States already
  retain explicit transaction membership. These producer sites supply identity
  without reverse-parsing names or changing legacy public provenance.
- [x] **ADDRESSED (verified)** — Producers attach private source_owner records;
  SourceWriterOwners resolves declared source/module/domain/container tuples.
  T1970 proves source-order and container-renaming independence, private-formal
  preparation, generated children and actual clock-domain modules. Missing,
  malformed and unknown owner controls refuse fabricated membership. Detached
  IR/source/result checks pass. Transaction-created auxiliary DTs remain DTs,
  and shared drives retain multiple callers. Exact carrier/schedule comparisons
  with private metadata removed pass, as do complete native/API/newline check,
  semantic and schedule reports plus exported-carrier strict replay.
- [x] **NO REGRESSION** — regression.log reports `All tests successful` for
  T1970/T1924/T1197/T1943. The mdBook build passes. Staged doctrines and normal
  hooks qualify the slice. Exact activation and per-assignment drive caller
  associations remain .3.2.2.3.2; generated helper ownership and complete shadow
  coverage remain later children. No executable writer admission is enabled.

Evidence: `.artifacts/source-writer-owners/`. Re-derivation joins actual source
producers and complete public reports; falsification removes/corrupts owners,
renames containers and permutes declarations; durability is T1970, the source
owner resolver, canonical writer card, book and this task. Source ownership is
not a grant or a state-exclusion claim. The initial test fixture's named-drive
syntax was corrected to the existing published positional-call grammar before
qualification; no language acceptance change was made.

## Acceptance — named-drive fact refresh `.57`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` traces token-free scalar
  named-drive VHDL to 2879f22af56e1835a9afe52476e2d8cee6147245. The named-drive
  behavior/selection cards and detailed behavior still described the earlier
  token leak as current, despite the separate completed backend card. The
  behavior card also raised the host RAM cutoff in its reverify command. The
  Knowledge Map query for drive priority returned that stale guidance.
- [x] **ADDRESSED (verified)** — Current named-drive guidance and the book
  now describe token-free generation with external VHDL compile/runtime still
  unclaimed. The selection record explicitly dates its original leak and links
  the completed repair. Consulted verification commands use the RAM guard
  defaults and distinguish qualified Darwin runtime opt-in from a skipped test.
  The bounded obsolete-current-claim search is empty. No product or backend
  behavior changes; all edits belong to this discovered documentation defect.
- [x] **NO REGRESSION** — verification.log reports `All tests successful` for
  T1542/T1543 with the qualified Darwin runtime enabled and default RAM limits.
  The positive/complemented generation and malformed reduction controls pass,
  alongside named-drive runtime qualification. The mdBook build passes; staged
  doctrines and normal hooks qualify this documentation repair.

Evidence: `.artifacts/named-drive-fact-refresh/`. Re-derivation uses exact repair
history and current focused tests; falsification retains malformed/unresolved
reduction controls and checks stale guidance is absent; durability is the
corrected cards, detailed behavior/dated selection, book and this task. Runtime
verification does not imply an installed or qualified external VHDL compiler;
command discovery found no ghdl/nvc/vcom during this slice. Resume the already
owned activation/caller prerequisite without changing its implementation scope.

## Acceptance — drive invocation sources `.32.1.3.3.1.3.3.2.2.3.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — The mixed local/spawn/do/trigger fixture's
  `--emit-schedule-json` report retains the broad legacy invoking_transactions
  provenance. _build_drive_dts previously copied that local caller group onto
  every body assignment, while only the DT-level generated_call_sources list
  retained generated invocation identities. A future precise writer inventory
  cannot pair assignments with sources by parsing helper prefixes or selecting
  an arbitrary local caller from those broad fields.
- [x] **ADDRESSED (verified)** — _build_drive_dts attaches private per-assignment
  drive_invocation records at its actual local/generated source branches.
  DriveInvocationSources verifies assignment-index association against the
  explicit drive owner and producer source records, then returns detached data.
  T1971 proves local groups, empty/multiple callers and exact generated spawn/do/
  trigger child/instance/source/request relationships. Renamed DTs and source
  permutations preserve identity; omitted and mutated associations fail closed.
  Existing target-local priority guards/suppressors and public provenance remain
  unchanged. Exact carrier/schedule comparisons, complete native/API/newline
  reports and strict generated-carrier replay pass.
- [x] **NO REGRESSION** — regression.log reports `All tests successful` for
  T1971/T1542/T1942/T1970 with the qualified supervised Darwin runtime enabled
  under default RAM limits. The mdBook build passes. Staged doctrines and
  normal hooks qualify the slice. Actual emitted guard/grant qualification is
  the next child; no source descriptor is treated as a mutual-exclusion proof.

Evidence: `.artifacts/drive-invocation-sources/`. Re-derivation joins actual
producer branches to per-assignment descriptors and full public reports;
falsification removes callers/sources or mutates ownership/request identities;
durability is T1971 and its mixed fixture, the resolver, canonical writer card,
book and this tree. This slice does not promote independent execution or alter
existing arbitration, including its conservative ambiguous-caller boundary.


## Acceptance — literal guard repair `.32.1.3.3.1.3.3.2.2.3.2.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — The retained rule_0 `--check --json`
  succeeds at bbb1ed7352255345722939a6e5a029dabd64055a although the false guard
  disappears from the emitted DT. LoweringIR retains port=0; emitter truthiness
  tests drop it from DT/assignment suffixes and entry transitions. T1972 RED
  independently observes disabled=5, captured=42, observed=9 through both HDL
  targets. A true entry instead emits a compact <1 group, parsed as a pulse
  assignment. Bare numeric groups also collide with strict infix recognition.
- [x] **ADDRESSED (verified)** — Explicit scalar-presence tests preserve zero;
  numeric predicates render as < (!= N 0) in headers, suffixes and groups.
  True port=1 elision and symbolic/relational behavior remain intact. T1972
  strict carrier replay, detached IR and complete native/API/newline reports
  pass. Verilog false/true entry and SystemVerilog false entry complete the
  independent reset/repeated-activation oracle. SystemVerilog true-entry runtime
  remains unqualified because the supervisor refuses pre-exec containment;
  this is a committed implementation repair, not completed leaf signoff.
- [x] **NO REGRESSION** — regression.log reports `All tests successful` for
  T1972/T1168/T1206/T1233/T1376 with runtime explicitly disabled after the
  containment failure. This establishes carrier/report, rule factoring,
  expression/when boundaries and book-example lowering only; T1972's runtime
  skip is not runtime evidence. The mdBook build passes. Staged doctrines and
  normal hooks qualify the commit, without closing the runtime blocker.

Evidence: `.artifacts/writer-guards/` retains initial RED, intermediate carrier
failures and green-predicate.log's exact containment failure. Re-derivation uses
actual source/IR/carrier and reports; falsification uses predecessor RED plus
true/symbolic/reset controls through generated HDL; durability is T1972, the
tracked fixture, canonical constant-guard card, book and this task. The sample
reset expectation was corrected from emitted register_in mux behavior: enabled
captured exposes data at entry during reset while its hidden register resets.
This was an oracle error, not a newly changed sample contract.

### Blocking verification result and scheduled ownership

The final runtime attempt returns test exit one. Its only failed runtime variant
is SystemVerilog entry=1, before exec, with empty stdout and this exact diagnostic:

```text
process-group containment failed: pid=43538 operation=setpgid result=undef errno=1 (Operation not permitted)
```

The failure originates in Support::ProcessSupervisor::_child_group_admission_error,
which exits 126 before cwd/stdio/exec when setpgid fails. It is not an HDL assertion
failure, and its errno does not identify the underlying native cause. The existing
P1 owner is `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.10`;
its precise-diagnostic child is complete but causal repair is still open. This
occurrence is linked there through this blocked consumer leaf. Resolve that
native containment cause without weakening admission, then finish the true-entry
SystemVerilog qualification before promoting guard collection or storage access.
No retry-as-repair, host change, cutoff change or alternate uncontained execution
was attempted. Unaffected checks were completed separately and cannot close this
blocker. The broader containment repair exceeds this guard-emitter slice.

## Acceptance — detached emitted writer predicates `.32.1.3.3.1.3.3.2.2.3.2.2.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'state_guard      => _clone_provenance_value'` identifies e32cbee6504362450be9f27f3ab060dc89bc8697 as the raw assignment-provenance introduction. Current emitter inspection and T1973 distinguish raw state context from effective assignment/DT conditions: entry bookkeeping lacks the sample guard and state decrement emission has no suffix. Raw ownership/context alone cannot prove effective activation.
- [x] **ADDRESSED (verified)** — The detached WriterActivation helper retains separately tagged container and assignment conditions plus raw guards/AST and transition context. T1973 checks actual carrier placement and strict native/carrier semantic equality, unguarded bookkeeping, literal false headers, comparison/monitor/decrement forms, rule grouping, malformed evidence, omission changes and deep detachment. Production lowering does not call the helper.
- [x] **NO REGRESSION** — Guarded `prove -Iperl -It/lib t/1973-isf-writer-activation-predicates.t t/1970-isf-source-writer-owners.t t/1971-isf-drive-invocation-sources.t` reports `All tests successful`, `Files=3, Tests=11`. No supervised HDL runtime or native-failure recurrence is requested. The selected public sync scope is private evidence plus book/fact/task; grant consistency and complete API/newline parity follow under the next children.

Re-derivation uses actual lowering and emitted carrier queries; falsification uses independent explicit carrier expectations, omitted guards, malformed/ambiguous/AST mismatch controls and unchanged entry bookkeeping; durability is the helper, T1973 and canonical docs/Git. The focused log is repository-local but ignored at `.artifacts/writer-activation-predicates/focused.log`; rerun the tracked tests for fresh counts. No complete physical writer inventory or independent execution is claimed.

## Acceptance — same-owner priority loss baseline `.32.1.3.3.1.3.3.2.2.3.2.2.2.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — Admitted public schedules and carriers retain only the last higher transaction state in the lower rule's inverse guard. `_suppress_priority_assignment` replaces the owner-key entry. `git log -S '_state_active_condition_expr($state->{name})'` identifies 7a3222a1a465e165d14569f1229f6887d6709f2f as transaction-winner exposure; owner-key generalization at 49711b6 predates support and is not mislabeled as exposure. Exact history hashes are sealed.
- [x] **ADDRESSED (verified)** — The bounded baseline retains actually admitted single/multiple/reversed-value sources, complete check/schedule/carrier/semantic outputs and the static earlier-state overlap witness. The saved verifier rejects lost writers, altered retained conditions/admission/owners and erased suppression metadata. P1 repair .2 precedes any metadata join; HIAL .3.2.10.11.1 owns the necessary fixed runtime observer qualification. This baseline does not claim a fix or executed HDL failure.
- [x] **NO REGRESSION** — Saved baseline verification passes; `knowledge-map: OK`, task-tree/claim checks, book build and staged doctrines qualify publication. Production source is unchanged. The book, ISF spec and downstream handoff expose the same known limitation instead of advertising complete multi-writer priority coverage.

Re-derivation uses actual admitted public queries and source/history inspection; falsification uses the single-state and reversed-value controls, independent carrier/selector joins and corrupted records; durability is complete tracked evidence, producer, verifier and Git identities. Runtime repair evidence remains explicitly missing and scheduled, with native failure-only observation required first.

## Acceptance — priority contributor union and first runtime blocker `.32.1.3.3.1.3.3.2.2.3.2.2.2.2.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — The red regression reports failure `#   at t/1974-isf-priority-contributor-union.t line 104`: LoweringIR::_suppress_priority_assignment overwrites earlier writer conditions under one owner key. Six multi-contributor cases lose their required emitted guard, while single/opposite/compatible controls and complete public-report parity pass.
- [x] **ADDRESSED (verified)** — Distinct per-owner conditions are retained and deterministically ORed before suppression. The focused matrix preserves target locality, unrelated progress, same-value admission, resource grants and exact native/API/newline/carrier products. The first genuine observed runtime compiles SystemVerilog then exposes the separate backend onehot0/compatible-fan-in contradiction. Complete failure and source/cleanup evidence is sealed, its exact cause is traced, and child .2 owns correction before child .3 completes runtime. No overall runtime signoff is claimed.
- [x] **NO REGRESSION** — Guarded T1974/T1210/T1218/T1219/T1971 reports `All tests successful`, `Files=5, Tests=29` with HDL skipped; the observed current T1974 separately passes its full static/report subtests before the retained runtime assertion failure. Saved hostile checks protect incomplete-stage, native-attribution, admission, bound and cleanup limits. Book/spec/downstream, map, claim census and staged doctrines qualify this implementation/evidence commit.

Re-derivation uses red/green actual lowering and full public products; falsification uses independent literal predicates, ordered public-pin runtime controls, the emitted-equation witness, exact workspace/command absence and corrupt saved records; durability uses tracked test versions, full logs/stages/reports, producer Git blobs and the saved verifier. Runtime completion and historical native causality remain missing and separately owned. No source schema keys or assertion policy change in this slice.


## Acceptance — compatible same-value selector contract `.32.1.3.3.1.3.3.2.2.3.2.2.2.2.2.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — Red T1211 reports `#   at t/1211-isf-runtime-selector-conflict-instrumentation.t line 47.` and line 57: LoweredRTLIRBuilder labels OR-coalesced same-RHS sources onehot0, and GeneratedModuleEmitter unconditionally enforces that label. The preceding actual T1974 execution fails on two admitted sources of out=9. Public --emit-semantic-json and the retained exact emitted equations establish compatible OR selection, while git log -S traces the assertion policy introduction to fd3317ef93c8ea5901c53fd507ce2f2cf9672b3d.
- [x] **ADDRESSED (verified)** — Decision 0111 retains the legacy descriptor and changes its kind to compatible_fanin. The renderer omits that incompatible exclusivity obligation, while explicit onehot0 and different-value checks remain. The complete public semantic product changes only the declared kinds; complete HDL changes only the exact invalid assertion and generated Date comment. The saved verifier checks those full comparisons and rejects old policy, weakened different-value checking, restored invalid assertion and lost OR contributors. Corrected actual runtime is intentionally a separately committed sibling, not claimed here.
- [x] **NO REGRESSION** — Guarded T1211/T340/T151/T154 reports `All tests successful`, `Files=4, Tests=9`; T1974/T311/T297 reports `All tests successful`, `Files=3, Tests=16`, with runtime explicitly skipped. Public key families, Verilog emission, standalone-DT and composition assertion contracts remain covered. Book/spec/downstream, canonical policy cards, decision, map and claim census accompany staged doctrine qualification.

Re-derivation uses changed production metadata/emission and complete public products;
falsification uses the red expectations, explicit-exclusive controls, independent
preserved different-value/OR equations and hostile saved comparisons; durability
uses exact logs, old/current artifacts and recoverable producer blobs in
`docs/audits/same-value-selector-repair-20260928/`. Corrected runtime and historical
native causality remain missing and separately owned. No source grammar, source
admission, scheduling, public keys, facade method or capability key changes.


## Acceptance — priority reset-oracle repair `.32.1.3.3.1.3.3.2.2.3.2.2.2.2.2.3.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — The observed SystemVerilog run reports `[311] %Fatal: tb.sv:20: Assertion failed in tb.check_reset.unnamedblk1: reset did not clear public outputs`. Public --emit-semantic-json reports sync/sreset/active-level-zero for the flat reset rst_n source, and the emitted state/output blocks are sensitive only to posedge clk. The bench introduced with a7fc9a98d1217d98f817c8d4c84448a8e1a762cc checked falling-edge+1 before a reset-active rising edge. The saved independent event-order model derives the exact failing time without further native execution.
- [x] **ADDRESSED (verified)** — The bench now holds reset across the next rising edge and checks after the following falling edge before deassertion. Independent parsed/carrier expectations pin the authored synchronous contract. The separately prepared negative fixture changes only the known missing-contributor guard in a cloned complete carrier; actual negative execution remains pending. The failed observation, full test versions, original stage limits/results, unchanged producer identities and independent workspace/command absence are sealed. No production or observer policy changed.
- [x] **NO REGRESSION** — Guarded T1974/T1211 reports `All tests successful`, `Files=2, Tests=7`, with runtime skipped. Complete native/API/newline/carrier products and selector-policy controls pass. The saved verifier rejects wrong failure attribution, disabled assertions, false cleanup, changed admitted inputs and invented stage completion. Book/spec/downstream, reset/native fact cards, task frontier, map and census accompany the staged doctrine gate.

Re-derivation joins the actual failure to the public reset contract and exact
bench event ordering; falsification uses the old-versus-corrected event model,
independent parsed/carrier expectations and hostile saved records; durability
uses `docs/audits/priority-reset-oracle-20260928/` with complete logs and source
identities. Corrected actual runtime and original native causality remain missing
and separately owned. This correction does not claim a production reset defect.


## Acceptance — complete observed priority qualification `.32.1.3.3.1.3.3.2.2.3.2.2.2.2.2.3.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — The committed red --emit-semantic-json/carrier baseline demonstrates the lost same-owner contributor, and preceding observed failures separately identify the incompatible same-value assertion and premature reset check. Their exact repairs and source identities are committed before this genuine qualification; no unexplained failure is retried.
- [x] **ADDRESSED (verified)** — The unchanged committed T1974 completes both positive HDL targets with ordered values, compatible overlap, target locality, unrelated progress, repeated requests and reset. A separately cloned carrier restoring only the lost contributor fails the enabled different-value assertion with its precise diagnostic. Complete original stage results, source identities and cleanup are retained in docs/audits/priority-runtime-qualified-20260928/. This closes the contributor repair and exposed assertion/reset prerequisites, not general writer admission or historical native causality.
- [x] **NO REGRESSION** — The guarded genuine observation reports `All tests successful`, `Files=1, Tests=4`, including complete native/API/newline/carrier parity and the executed negative control. Original compile/runtime bounds and assertion flags remain, all expected stages are present, and the saved hostile verifier rejects missing pass markers, wrong negative failures, weakened bounds/flags, source drift and false cleanup. Independent workspace/command absence complements retained supervisor cleanup; successful-child PID absence is not claimed.

Re-derivation uses the actual public-pin execution and complete public products;
falsification uses the restored missing-contributor fixture's real assertion
rejection plus independent cleanup and corrupted evidence controls; durability
uses the committed test, full original stage/log records, admitted/extra source
identities and saved verifier. No historical EPERM cause follows from silent
successful native calls. That missing causal leg remains owned by HIAL .3.2.10.11.5.


## Acceptance — detached resource-grant correspondence `.32.1.3.3.1.3.3.2.2.3.2.2.2.2.3.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — Actual --emit-schedule-json and LoweringIR resource_arbitration expose grants whose rule DTs retain resource_grants mirrors. Those lowered copies alone cannot establish completeness when both omit a resource/user. T1975's independent declared user matrix and simultaneous-copy deletion control establish why the actor declaration witness is required. SourceWriterOwners supplies the authored rule identity independently of the generated DT spelling.
- [x] **ADDRESSED (verified)** — The private WriterResourceGrants collector joins actual declarations, complete module rows and DT mirrors; validates policy/members/peer identity and duplicate/missing/malformed boundaries; and returns detached records. Independent expected records cover supported kinds and both arbiters, unbound declarations, multiple resources, declaration order and DT rename. It does not infer an exclusion proof or attach itself to production admission.
- [x] **NO REGRESSION** — Guarded T1975 reports `All tests successful`, `Files=1, Tests=3`; T1973/T1970/T1218 reports `All tests successful`, `Files=3, Tests=22`. Complete carrier identity, strict checks, native/carrier semantic parity and both arbiter schedule native/API/newline products pass. Book/spec/downstream, canonical fact, map and claim census accompany staged doctrine qualification; no HDL runtime was needed for this detached metadata slice.

Re-derivation uses actual parsed/lowered fixtures and independent literal expected
grant records; falsification removes or corrupts either/both lowered copies,
authored declarations and ownership while healthy/unbound controls still pass;
durability uses the permanent T1975 regression, tracked collector and canonical
fact/task records. Full grant-condition, priority-suppression and invocation
semantics remain the following owned children; these records alone prove no
mutual exclusion. No additional decision or rationale-ledger entry is needed.


## Acceptance — resource activation producer `.32.1.3.3.1.3.3.2.2.3.2.2.2.2.3.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — Red T1976 reports `#   at t/1976-isf-resource-activation-evidence.t line 104.`: the producer returns grant names but loses original requests as successive resources overwrite dte_guard. The complete baseline --emit-schedule-json and --emit-semantic-json products confirm the existing public behavior; missing private provenance is the selected implementation gap, not a new runtime defect.
- [x] **ADDRESSED (verified)** — LoweringIR retains detached requests and ordered actual transformations at both arbitration producers, including unchanged priority winners, original higher conditions, selected round-robin declaration/permission and exact update index. Independent literal expressions, mixed-resource order, absent/literal guards, selected-pointer substitution and nested mutations pass. Complete baseline/current compiler/public products agree after excluding only the added private evidence from internal IR.
- [x] **NO REGRESSION** — Guarded T1976 reports `All tests successful`, `Files=1, Tests=3`; guarded T1975/T1973/T1944/T1218 reports `All tests successful`, `Files=4, Tests=24`. Complete source/carrier, API/newline and malformed grant regressions pass. Book/spec/downstream and canonical knowledge are aligned; map, claim census, book build and staged doctrines complete publication qualification.

Re-derivation uses actual producer and complete baseline/current products;
falsification uses red missing evidence, independent expressions, pointer identity
substitution and destructive nested-copy controls; durability is the tracked
fixture/test and Git-owned producer, with dated comparison logs in
`.artifacts/resource-activation/`. The permanent tests rerun semantic/carrier
and private/public separation contracts. General grant proof, admission and
native runtime remain separately owned. Shared policy source recheck matches
the retained claim-template digest; local README/containment authorities remain
adopted. Startup reviewed the scoped roadmap, selected lowering/public spine and
relevant book/spec paths; the import map needs no change for this private field.

## Acceptance — scheduled artifact cleanup `.59`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S '2026-09-27T19:21:28+00:00' -- docs/ARTIFACT_CLEANUP.md` identifies 1dc5e48cefda6896dd3b89e52eebf1e1ddcb8f3d as the prior cleanup record. The current session date makes the required sweep due. Exact selected directories contain generated mdBook indexes/assets; the initial unhashed-asset check stopped before deletion and was corrected from actual index references.
- [x] **ADDRESSED (verified)** — The closed selected-path list was checked for same-volume, regular/untracked renderer contents before removal; every selected directory is absent afterward. Repository artifact and Rust release/deps/incremental log/bin candidates remain untouched. The bounded cleanup record and its generated inventory now agree; task/resume state returns to resource activation validation.
- [x] **NO REGRESSION** — The cleanup staged run reports `knowledge-map: OK`; locality, task integrity, claim inventory/dispositions and document pressure checks pass. Its initial acceptance gate correctly required fresh boxes because generated doctrine registries changed; this checklist supplies the missing current-slice evidence. Source/tests/book source and all failure evidence remain unchanged. The selected rendered outputs can be regenerated from committed book source.


## Acceptance — detached resource activation validation `.32.1.3.3.1.3.3.2.2.3.2.2.2.2.3.2.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — Complete public --emit-schedule-json grant annotations and the existing structural collector do not establish their guard semantics. T1977 deliberately removes a higher user from both module/DT grant copies: structural collection accepts the matching lists, while the new independent authored-priority reconstruction refuses them with `incomplete priority suppressors`. The private ordered producer evidence supplies original requests and transformations without proving those associations by itself.
- [x] **ADDRESSED (verified)** — WriterResourceActivation validates exact source/request/DT coverage, ordered step identity and chaining, final headers, original higher requests, priority reachability and circular permissions. Actual selected counter width/role and pointer update identity are checked without name reconstruction. Independent request-selection enumeration and hostile changed/missing/copied evidence controls pass; source permutations, local priority declarations, selected pointer names and nested detachment remain covered. The initial test oracle's reversed-user-order assumption was corrected against the fixture's explicit priority declarations; production arbitration was unchanged.
- [x] **NO REGRESSION** — Guarded T1977 reports `All tests successful`, `Files=1, Tests=4`; T1975/T1976/T1973/T1944/T1218 reports `All tests successful`, `Files=5, Tests=27`. All supported resource kinds join their independently expected catalogs, with complete public native/API/newline/carrier parity and unchanged emitted products. The helper has only test callers. Book/spec/downstream, Knowledge Map, task/claim checks and staged doctrines qualify publication.

Re-derivation uses the actual retained producers and new detached validator;
falsification uses direct winner selection, matching incomplete catalog copies,
permission/header corruption and actual storage/update controls; durability is
tracked T1977/T1975, fixture producers and the private module in Git. This is a
rule-header semantic correspondence result, not general assignment exclusion,
priority-contributor integration, independent-controller admission or native
runtime qualification. The director's newly blocking SPECFORGE requests are
owned under .60 and become the next delivery priority after this commit.

## Acceptance Checklist — SEM .60.3.1 reset packet baseline

- [x] **ROOT CAUSE (WHY + WHERE)** — Current `--emit-semantic-json` retains identical reset contracts for explicit and omitted legacy forms; `--emit-schedule-json` returns null for the clock-only form. Parser::_finalize_actor_timing_conventions applies legacy defaults only outside clock-domains, while generated explicit-system metadata describes the lowered carrier. Exact public products and actual HDL are retained in the reset audit.
- [x] **ADDRESSED (verified)** — Preserved the supplied packet and verified copied source identities. The audit captures complete native/API/newline reports and both Verilog targets; independent verify.py checks explicit versus omitted equality and clock-only initialization absence. Corrupt reset fields, default policy and an invented initial block fail its hostile controls. Baseline only; the missing downstream provenance contract is owned by .60.3.2.
- [x] **NO REGRESSION** — RAM-guarded audit `prove -v -Iperl -It/lib docs/audits/specforge-unstated-reset-20260930/capture.t`: `All tests successful. Files=1, Tests=3`; native/API/newline complete comparisons and actual HDL generation all succeed. Production source unchanged. The first run failed only unnormalized repository-path comparisons; corrected harness and both logs are retained.

Claim legs: re-derivation is actual independent public commands and HDL emission;
falsification is the offline verifier's corrupt-evidence controls; durability is
the tracked packet, products, command/test logs and hashes. These qualify the
supplied forms at the recorded revision, not arbitrary no-reset hardware runtime.

## Acceptance Checklist — SEM .60.3.2 reset provenance contract

- [x] **ROOT CAUSE (WHY + WHERE)** — The retained `--emit-semantic-json` and `--emit-schedule-json` baseline collapses explicit and defaulted reset. Parser timing finalization supplies legacy rst_n; the emitted FSM explicitly carries that policy, so its explicit-system metadata cannot prove ISF clause presence. The spec also retained a contradictory legacy-only domain sentence alongside its named-domain contract.
- [x] **ADDRESSED (verified)** — Decision 0112 defines origin metadata, unknown-provenance behavior, complete domain scope and unchanged hardware. .60.3.3.1 owns coherent public delivery; .61 owns missing deferred reset configuration after required packet unblocks. The stale spec sentence now scopes the single domain to legacy clock syntax. Book/spec clearly label the selected report extension unshipped.
- [x] **NO REGRESSION** — Offline retained-product verification passes and preceding `All tests successful. Files=1, Tests=3` public baseline remains immutable. No production or fixture behavior changed; the contract requires preservation and complete query/capability qualification before delivery.

## Acceptance Checklist — SEM .60.3.3.1 reset provenance delivery

- [x] **ROOT CAUSE (WHY + WHERE)** — Sealed `--emit-semantic-json` and `--emit-schedule-json` products could not distinguish omitted legacy reset from an explicit clause because Parser::_finalize_actor_timing_conventions normalized both before downstream reporting. T1978 red fails the independently expected source/schedule provenance while all pre-existing products remain valid.
- [x] **ADDRESSED (verified)** — Parser captures origin before defaulting; LoweringIR/domain selection retain detached evidence and the shared projection validates closed domain/origin shapes. Schedule and successful ISF source reports expose the same complete provenance, with matching capability declarations. T1978 confirms independent expected origins, domain order/scope, unknown evidence, malformed-evidence refusals, failure/direct-FSM/PPIF controls and exact native/API/newline equality. Complete legacy public fields and actual scheduled FSM/HDL match the baseline, allowing only the new field and HDL date banner.
- [x] **NO REGRESSION** — Final T1978: `All tests successful. Files=1, Tests=5`. Focused report/source/reset/domain tests pass except the initially stale T1144 expected tested_by list; correcting that explicit catalog addition and running T1144/T1255/T1305/T1227 yields `All tests successful. Files=4, Tests=288`. T1890/T1893 and all other neighboring checks pass in the retained regression log. No native simulator run was required for byte-preserved hardware; historical native cause remains open.

Claim legs: public-product re-derivation uses actual native/API/newline commands
and both HDL emitters; falsification uses the missing-metadata red run,
independent baseline byte comparisons and malformed-evidence controls; durability
is T1978, the immutable baseline plus candidate logs/producer identities in
`docs/audits/specforge-reset-provenance-20260930/`. The typo acceptance is a
separate actual defect, owned by .62 and scheduled before downstream closure.


## Acceptance Checklist — SEM .62 reset grammar repair

- [x] **ROOT CAUSE (WHY + WHERE)** — The sealed strict --emit-semantic-json witness accepts asnyc and reports sync: Parser::_parse_reset ignored unknown list values, repeated/conflicting options and extra outer operands. T1979 red reproduces the malformed acceptance. The relevant git log -S history at 8dc7bb3d records valid singleton-tail handling. A late public AST probe also proves the own normalizer collapsed authored () to undef; that identity loss caused empty options to evade the parser guard.
- [x] **ADDRESSED (verified)** — The parser now enforces reset arity, scalar options, known timing/polarity values and non-repeated selection. Reset-payload normalization retains authored empty lists separately from legitimate undefined tails; T1092 proves that distinction and unchanged non-reset normalization. T1979 passes independent expected actor/domain policies and malformed controls, ordinary/strict public diagnostic failures, complete native/API/newline equality and schedule refusal. Explicit sync, inferred polarity, option order and whitespace tails remain accepted. The first repaired run failed only incorrect missing-name diagnostic expectations; correction is disclosed in the sealed evidence.
- [x] **NO REGRESSION** — Guarded T1979 reports `All tests successful. Files=1, Tests=3`; Final T1092/T1398/T1476/T1331/T1165/T1192/T1150/T1159/T1893/T1978 report `All tests successful. Files=10, Tests=43`. Parser syntax, Knowledge Map, task/claim checks and book build pass. T1978 compares complete previous reports, scheduled carriers and generated HDL; no native runtime was required for preserved valid-source hardware. Staged doctrines qualify the committed publication.

Re-derivation uses actual parsing and public commands; falsification uses the
original successful typo report, the red grammar regression and independently
expected policy/error matrices; durability is T1979 and the lossless log/hash
archive in `docs/audits/isf-reset-grammar-20260930/`. Existing supported corpus
forms remain covered by neighboring tests; no new source-feature category or
public schema is introduced. Historical native EPERM remains separately open.


## Acceptance Checklist — SEM .60.3.4 reset question answer

- [x] **ROOT CAUSE (WHY + WHERE)** — The supplied question and retained --emit-semantic-json baseline conflated legacy default and explicit reset; qualified provenance now separates them. The clock-only baseline has no state initializer. Actual T1980 --emit-schedule-json and generated HDL confirm that storage reset metadata also does not create initialization without a hardware reset. T1398's powers-up wording described reset assignments and overstated what those assertions establish.
- [x] **ADDRESSED (verified)** — The tracked response answers every question and condition in expected-notes.md, names the exact provenance fields/commits and preserves the boundary between upstream source silence, an accepted implementation default, hardware without reset and unavailable deferred choice. T1980 independently checks actual state/storage declarations and assignments against an explicit-reset control; T1398 labels now say reset assignments. The initial next-helper-name oracle error is disclosed and corrected by following the actual clocked RHS; no production code changed.
- [x] **NO REGRESSION** — Guarded T1980/T1398 report `All tests successful. Files=2, Tests=5`. The immediately preceding final T1978-containing regression reports `All tests successful. Files=10, Tests=43` on the unchanged production revision, retaining complete supplied native/API/newline reports and baseline HDL equality. Book/spec/downstream, canonical facts, task state and bounded claim/document records are synchronized through publication and staged doctrine checks.

Re-derivation uses complete actual public reports and both HDL emitters;
falsification distinguishes an explicit-reset control from absent initialization
and locks current-value feedback plus ordinary writes; durability is T1980 and
full products/logs/source identities in the committed reset-answer audit.
No simulator startup value is claimed. This closes the question, not a new
configurable-reset feature or SPECFORGE's downstream adapter-policy decision.


## Acceptance Checklist — SEM .60.1.1 duration packet baseline

- [x] **ROOT CAUSE (WHY + WHERE)** — Supplied and current --emit-schedule-json reports show the cycle parameter lowering to a static chain without a counter. Parser::_parse_clock requires one name; LoweringIR::_wait_count_spec refuses time as an unsupported expression operator and _parse_await_wd requires a scalar bound. _ir_wait allocates one state per static cycle. This is the documented missing duration capability, not evidence that the requested feature already exists.
- [x] **ADDRESSED (verified)** — Preserved the director-authorized packet losslessly, verified every source identity, and captured complete bounded native/API/newline results and actual scheduled FSM. Current baseline fields equal the supplied schedule after removing only qualified reset provenance. The independent verifier refuses corrupted state counts, counter metadata, failure/provenance fields even when all report mirrors agree, and a changed actual carrier census. Initial exit/indentation audit assumptions were corrected and retained; production is unchanged.
- [x] **NO REGRESSION** — Guarded intake capture reports `All tests successful. Files=1, Tests=4`; offline identity/transport/carrier/hostile verification passes. The accepted control and exact public failure contracts are preserved. No large timeout rerun or native runtime was needed. Book, response and Knowledge Map state the current gap; task/claim/publication and staged doctrines qualify the record.

Re-derivation uses actual public commands and the emitted carrier; falsification
uses matching-copy report corruption and a separate carrier mutation; durability
uses the complete packet/products, hashes, capture test and offline verifier.
Supplied corpus counts and larger-scale timing remain externally supplied,
not independently measured here. This intake does not close feature delivery.


## Acceptance Checklist — SEM .60.2.1 named-timer packet baseline

- [x] **ROOT CAUSE (WHY + WHERE)** — Current --emit-schedule-json refuses the timers actor clause in Parser and distinct await limits in LoweringIR::_transaction_watchdog_limit. The accepted watchdog carrier loads limit minus one, then raises last_error on timeout. Ordinary concurrent expiry is a missing capability, not the current watchdog contract.
- [x] **ADDRESSED (verified)** — Preserved the complete authorized packet with verified identities and exact sources. Native/API/newline reports agree completely; baseline schedule fields match supplied evidence apart from reset provenance. Independent carrier checks retain actual load, error and idle behavior. The offline verifier rejects semantic corruption even when report mirrors agree, plus changed actual load/error assignments. Initial audit-oracle guesses are disclosed and corrected without production changes.
- [x] **NO REGRESSION** — Guarded capture reports `All tests successful. Files=1, Tests=3`; offline identity/transport/carrier and hostile controls pass. The accepted watchdog and current refusal contracts are preserved. No native runtime required. Book, canonical fact, response and task state distinguish required cycle timers, conditional durations and optional per-await limits; publication and staged doctrines qualify the record.

Re-derivation uses actual public commands and the emitted watchdog carrier;
falsification uses matching-copy report corruption and independent carrier
mutations; durability uses tracked packet/products, logs, hashes and verifier.
External corpus counts are not independently measured. Feature delivery remains
open and follows the remaining aggregate intake.


## Acceptance Checklist — SEM .60.4.1 aggregate-port packet baseline

- [x] **ROOT CAUSE (WHY + WHERE)** — Current --emit-schedule-json refuses both record-port forms in Parser::_resolve_typed_width_entry; _finalize_actor_type_references allows aggregates only on storage variables. The accepted scalar-input control retains typed actor storage and its scalar-leaf assignment. Generated internal typed handoffs do not remove this authored-port boundary.
- [x] **ADDRESSED (verified)** — Preserved the complete authorized packet and exact source identities. Native/API/newline reports agree completely; prior strict-check fields match after exact source relocation and reset provenance. Independent expected storage shape/order/width and actual carrier checks qualify the control. The offline verifier refuses count/storage/failure/provenance corruption even with matching report mirrors, reversed member order and altered carrier target. Required record ports and optional lists/variants remain separately owned.
- [x] **NO REGRESSION** — Guarded capture reports `All tests successful. Files=1, Tests=3`; offline identity/transport/type/carrier and hostile controls pass. Production remains unchanged; no native runtime or external corpus remeasurement. Book, canonical fact, response and task state describe the current boundary; publication and staged doctrines qualify the record.

Re-derivation uses actual public commands, parsed type evidence and the emitted
carrier; falsification uses independent expected shapes, matching-copy report
corruption and carrier mutation; durability uses tracked packet/products, logs,
hashes and verifier. This closes intake, not feature implementation.


## Acceptance Checklist — SEM .38.1 scalar storage access delivery

- [x] **ROOT CAUSE (WHY + WHERE)** — Retained --emit-schedule-json intake and T1981 red show Parser::_parse_storage rejecting the access option. Existing field vocabulary and LoweringIR::_declared_storage_for_ir provide the bounded metadata path; JSON::_storage_summary previously omitted word access. The initial domain test separately traced missing public details to multi_domain_report_hash and _clock_domain_entry_summary, owned by .38.3.
- [x] **ADDRESSED (verified)** — Width-based var/variable words accept the checked field vocabulary, preserving independent word and field facts with precise unknown/malformed/duplicate/carrier refusals. Detached declared storage projects optional access in schedule reports and discovery. T1981 checks exact supplied native/API/newline products, both spellings/tokens, omission/no-inheritance, domain source ownership and complete FSM/HDL equality to pre-change controls. No hardware policy consumes access. Decision 0109 scopes passive metadata independently of execution repairs. The support fixture, book/spec, stale ownership wording and downstream response match this bounded delivery and explicit domain-report limit.
- [x] **NO REGRESSION** — T1981 reports `All tests successful. Files=1, Tests=6`; focused storage/reset/public-contract/golden/book/provenance regression reports `All tests successful. Files=8, Tests=31`. Pre-change capture reports `All tests successful. Files=1, Tests=2`. Original red, domain-oracle correction and wrong-path regression invocation are retained alongside passing logs. Independent identity/product verification, publication checks and staged doctrines qualify durability. No native runtime required for identical hardware.

Re-derivation uses actual native/API/newline commands and both HDL emitters;
falsification uses the red feature test, independent token/field expectations,
malformed and unsupported-carrier controls, and exact old-product comparisons;
durability is T1981 plus retained sources/products/logs/hashes in the audit.
The multi-domain storage-detail gap is immediately next under `.38.3`; it is
not hidden by scalar delivery. Historical native and execution defects remain open.


## Acceptance Checklist — SEM .38.3 domain storage detail

- [x] **ROOT CAUSE (WHY + WHERE)** — T1981 and retained --emit-schedule-json show multi_domain_report_hash clearing the top storage array while _clock_domain_entry_summary forwarded only storage names/counts. T1982 red independently reproduces missing owned details and discovery. T1978 then exposed the separate named-single-domain report path, which has no domain-report map and must reuse its own module storage.
- [x] **ADDRESSED (verified)** — clock_domains[].inferred_storage reuses the normalized storage schema with detached nested values. Word and field facts, typed storage, scalarized bank elements and scheduler counters retain domain ownership; empty realized domains have empty arrays, while unavailable private detail remains null. Named single domains publish their known module storage without altering old count fields. Existing storage names, top ownership, old report fields, actual FSM and both HDL targets are preserved. Exact capability keys/scope, book/spec/downstream and canonical fact are synchronized.
- [x] **NO REGRESSION** — Final T1982/T1978/T1255 report `All tests successful. Files=3, Tests=11`. The preceding broader run had only the repaired T1978 failure; T1981/T1144/T1247/T1890/T1893 and the original T1982/T1255 all passed. The initial feature reported `All tests successful. Files=1, Tests=4`; baseline capture reported `All tests successful. Files=1, Tests=1`. Full logs preserve both the correction and exact qualification boundary. No native runtime needed for byte-preserved hardware; publication and staged doctrines qualify continuity.

Re-derivation uses actual public reports and HDL emission; falsification uses
the original absent-field failure, independently expected owned storage arrays,
empty/single-domain controls and nested-mutation isolation; durability uses
T1982 and the retained baseline/source/log/hash audit. The initially wrong
scope-descriptor test key is disclosed in the manifest; it is not a production
contract change. Required record-port delivery is next; optional banks stay owned.

## Acceptance — record-port contract selection `.60.4.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'accepts aggregate type aliases only on actor-owned storage variables' -- perl/FSM/Adapter/ISF/Parser.pm` identifies `9c6fda6961ca1c40e1de547e39c58cec10c2ed69`. `_finalize_actor_type_references` still passes no aggregate permission for interface ports, while typed storage and generated internal handoffs have their own qualification. The retained packet and baseline verifier preserve that boundary. The task-index row also incorrectly pointed to timer intake already completed in the live nodes; its current projection is corrected here.
- [x] **ADDRESSED (verified)** — Decision 0113 selects exact source/value/layout/public snapshot contracts and maps R1-R3 to separate metadata, input, whole-output, scalar-output and backend qualification owners. R4/R5 have explicit blocked optional owners. The book labels selection as future work; current record-port refusals remain. Shared policy source identity matches the reviewed local snapshot, the cleanup interval remains current, and no external repository was changed. No source implementation or native HDL runtime is claimed.
- [x] **NO REGRESSION** — `scripts/check_docs_relative_paths.sh` reports `All tests successful`. Guarded `prove -Iperl t/1259-isf-aggregate-storage-type-aliases.t t/1978-isf-reset-provenance.t` also reports `All tests successful`, retaining the aggregate refusal and unchanged reset controls. `scripts/check_task_tree_integrity.pl` passes the expanded live graph; the retained aggregate baseline verifier passes identities, complete reports, actual typed storage carrier and hostile controls. `mdbook build docs/book -d .artifacts/mdbook-record-port-contract` succeeds and the rendered chapter retains the future label and decision link. The initial staged doctrine run rejected an unnecessary new Knowledge Map topic row at the root-document allowance. The signpost now joins the existing aggregate topic through the owning decision record, retaining its complete metadata/body without growing the saturated card collection. Task/decision warning allowances are refreshed from measured actual plus their declared ratchet steps, inside unchanged ceilings. The staged doctrine gate owns document pressure, aggregate authority, inventory/dispositions and Knowledge Map freshness.

Evidence scope: the selection is durable in decision/task/book/card/Git. Baseline
identity and independently rejected corrupt controls establish retained evidence;
no new runtime, external corpus, capacity or timing measurement is published.

## Acceptance — detached interface producer `.60.4.3.1.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — The initial T1983 malformed controls accepted `inout`, signed `2` and an unknown state model. A minimal Perl reproduction shows a failed regex predicate disappearing in argument-list context, shifting the message into the truth slot. The strict guard subsequently reports `Invalid ISF interface port metadata: validation requires a predicate and message` at perl/FSM/Support/ISFInterfacePortMetadata.pm line 220 when a nonempty ordered-member array expands into arguments. Both faults belong to this previously unshipped producer draft.
- [x] **ADDRESSED (verified)** — `ISFInterfacePortMetadata` projects a closed detached declared-port value and validates its exact key/type/range families. Explicit scalar/boolean predicates and exact validation arity repair the demonstrated bypass and expansion. Independently authored nested/imported layouts, signed/state-model leaves, mutation controls, empty/null distinctions and hostile metadata pass T1983. The producer remains unwired; no parser admission, new public source/schedule field, hardware policy or native runtime is claimed.
- [x] **NO REGRESSION** — Guarded `prove -Iperl t/1983-isf-interface-port-metadata.t t/1259-isf-aggregate-storage-type-aliases.t` reports `All tests successful`. The original aggregate-storage controls preserve accepted types/carriers and authored-port refusal. `perl -Iperl -c perl/FSM/Support/ISFInterfacePortMetadata.pm` reports `syntax OK`. The book labels metadata as planned; its build and staged doctrine gate verify documentation, task ownership, aggregate authority and Knowledge Map consistency before commit.

Re-derive: rerun the focused producer/aggregate controls. Falsify: the malformed
and mutated metadata controls reject exact competing layouts and the retained
Perl reproduction demonstrates the original argument-context mechanism.
Durability: producer, tests, this owning leaf and decision 0113 retain the
contract and reproducible cause. Public integration remains explicitly owned.


## Acceptance — declared interface report integration `.60.4.3.1.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — The retained domain-storage baseline's `--emit-schedule-json` product has counts/inferred ports but no authored interface snapshot. Decision 0113 requires declared source roles including unused ports, unknown versus empty evidence and private-handoff exclusion. The qualified producer was unwired in parser/IR/source/report paths; projecting inferred scheduler ports would lose that source distinction. An independent advertised-key census also reports `missing: ['verification_bridge']` for both maintained report top-level lists, revealing existing schema drift.
- [x] **ADDRESSED (verified)** — Parser captures validated declarations before scheduler injection; ordinary IR and domain source selection propagate detached owned evidence; generated transaction children retain unknown authored metadata. Shared success source and schedule/domain projections expose the same closed schema and advertise every selected key/value family. T1984 independently expects order, alias identity, named ownership, actual crossing/private-child exclusions and unknown/empty/mutation/failure controls. The two stale schema lists now match the complete advertised key set. Book examples produce exactly their independently written arrays for check, semantic and schedule.
- [x] **NO REGRESSION** — Guarded producer integration/aggregate/source-copy/roundtrip/parser-facade/schedule tests report `All tests successful`. T1978/T1981/T1982/T1255 also individually pass with the same production source: complete native/API/newline reports preserve old fields after removing only the new declarations; actual carriers and SystemVerilog/Verilog HDL retain complete baseline identity except generated date. `perl -Iperl -c bin/fsmgen` reports `syntax OK`. mdBook build and staged doctrine gate verify synchronized documents, task ownership, maintained-reference authority and Knowledge Map consistency before commit. New complete transport/corpus qualification remains owned; no native HDL execution is represented.

Re-derive: rerun T1984 and the named historical/source/schema controls. Falsify:
independently authored declarations, unknown/empty and private-port exclusions,
mutation controls, exact old-product comparisons and advertised/documented key
sets distinguish source evidence from inference and parity from semantic truth.
Durability: producer wiring, permanent controls, this task, decision 0113 and
book/spec retain both the report contract and repaired schema drift.


## Acceptance — complete declaration metadata qualification `.60.4.3.1.3`

- [x] **ROOT CAUSE (WHY + WHERE)** — Earlier integration establishes the shared report field but complete parity alone cannot establish correct declarations. T1985 executes native `--check --json`, `--emit-semantic-json` and `--emit-schedule-json` products with independent authored port expectations. Corpus qualification reports `catalog contract for 'feature.isf_declared_interface_metadata' is unique` failing at t/248-regression-corpus-accounting.t line 1231: the draft reused a `(relpath, classification, coverage)` tuple. Exact counts also report got 385/375 versus expected 383/373. Independent exports at pre-slice `241fad6b5` show the old catalog was already 384/374; `git log -S` locates the prior storage-word-access addition at `3fa482924`.
- [x] **ADDRESSED (verified)** — A dedicated reviewed `isf/interface_port_metadata.isf` retains typed unused input and undriven output; its catalog entry is unique. Independent live exports yield 385 supported and 375 strict entries with no duplicate tuples; T248's exact expectations include both missing prior storage access and the new fixture. T1985 joins the complete live ISF cohort to literal declarations and qualifies complete native/API/newline reports and discovery, local/imported/empty/domain cases, unrelated omission/null, contextual source refusal and untouched bytes. Shared corruption of all transport copies still fails the independent typed expectations. T1883/T248 preserve classification, strict admission, source allocation and uniqueness contracts.
- [x] **NO REGRESSION** — Guarded T1985/T248/T1883 reports `All tests successful`. Focused T1884 additionally qualifies the new fixture through existing producer identity, envelope and semantic oracles. The previously passed T1983/T1984, T1978/T1981/T1982 and T1255 retain malformed metadata, parser/report isolation, actual private crossing/child exclusion, complete old report fields, actual scheduled carriers and SystemVerilog/Verilog HDL identity except date. mdBook build and staged doctrines verify user/spec/discovery alignment, source locality, task ownership and Knowledge Map consistency. Record source ports remain refused; no native HDL execution or full-CI/push signoff is represented.

Re-derive: rerun T1985/T248/T1883 and the focused T1884 fixture selection;
export current `regression_corpus_entries()` for catalog definitions. Falsify:
independent literal declarations and typed shared-corruption controls reject
parity-only loss; T248 rejects duplicate tuples/IDs and inconsistent strict
classification, while the fixed pre-slice public export distinguishes old
stale assertions from the one added distinct fixture. Durability: corpus,
fixture, controls, this owning task, decision 0113, book and Git retain the
complete preparation. Catalog totals are entries, not product-feature/runtime
coverage. Subsequent record-port admission remains explicitly owned.


## Acceptance — record-input ingress selection `.60.4.3.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — The public parser probe refuses `interface port packet references aggregate type frame` at perl/FSM/Adapter/ISF/Parser.pm line 2862. Storage-only aggregate maps and enum disambiguation cannot establish lexical input roles. Public payload compatibility controls accept signed/state-distinct resolved records of equal width, so that helper cannot establish the selected copy identity. Existing leaf validation has no update/sample branch and sample width collection does not resolve leaf facts. These are pre-admission dependencies, not evidence of shipped record support.
- [x] **ADDRESSED (verified)** — Decision 0113 records strict recursive resolved identity, optional state presence/value, preserved payload/storage compatibility, lexical masking and owned domains, supported scalar/copy contexts and explicit leaf sampling preparation. Reproducible controls establish alias identity, distinct signed/absent/four/two-state facts and unchanged record-input refusal. Closed gates, mandatory first-admission checks, carrier ownership and native/public completion have exact child owners; the book keeps all new source forms future-only.
- [x] **NO REGRESSION** — Guarded `prove -Iperl t/1983-isf-interface-port-metadata.t t/1259-isf-aggregate-storage-type-aliases.t` reports `All tests successful`. A first invocation named a nonexistent T1259 path; the corrected canonical path passes. The retained decision command reproduces controls without HDL. Book build and staged doctrines verify future-only prose, task ownership, fresh aggregate authority, measured warning allowances, generated Knowledge Map and claim inventory before commit. No implementation source or native-runtime admission changes.

Re-derive: run the pure command in decision 0113 and the named focused tests.
Falsify: alias-equivalent and signed/state-distinct controls distinguish strict
identity from width compatibility; the source refusal prevents a planning
receipt being mistaken for feature delivery. Durability: decision, task, book
and Git retain the selected contracts and executable controls. Native behavior
is explicitly owned by the later completion leaf.


## Acceptance — unwired record value gates `.60.4.3.2.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — T1986 diagnostic-line controls report Failed test at t/1986-isf-record-port-value-gates.t line 66: `packet.unknown` emits `unresolved` rather than `unknown_member`, with analogous index/syntax and shadow controls. The draft reads `reason`, but AggregatePathSupport returns `code`. Its original negative helper searches a Carp stack containing the expected regex passed to that helper, concealing the defect. A permanent independent wrong-message/expected-stack control reproduces that false match. Core range resolution also explicitly returns `scalar_root` for a direct scalar slice, so scalar locals masking records require a range-preserving traversal anchor.
- [x] **ADDRESSED (verified)** — The unwired closed scope/reference/copy helpers reuse validated declared shapes, core packed ranges and the existing strict composition type comparison. First-line-only negative oracles reject the demonstrated wrong diagnostic; code projection retains canonical failures. Scalar local/formal slices resolve through a one-member anchor without borrowing outer record facts. Known input roles reject writes before unresolved-type fallback. T1986 independently verifies alias/imported positives, equal-width identity negatives, nested ranges/properties, lexical masks, malformed/cyclic facts and unchanged storage-only contracts. No source/scheduler wiring or runtime admission is added.
- [x] **NO REGRESSION** — Guarded `prove -Iperl t/1986-isf-record-port-value-gates.t t/1983-isf-interface-port-metadata.t t/1259-isf-aggregate-storage-type-aliases.t t/284-package-aggregate-path-support.t t/283-composition-aggregate-path-support.t t/281-structural-declared-type-contracts.t t/1188-isf-interface-port-boundary.t` reports `All tests successful`. Source record input/output and list-port controls retain the existing refusal; aliases, package types and current core/interface contracts remain accepted. `perl -Iperl -c perl/FSM/Support/ISFRecordPortValues.pm` reports `syntax OK`. mdBook and staged doctrines verify future-only source claims, ownership, fresh maintained-reference authority and generated knowledge/inventory before commit. No native HDL observation or complete record-input public delivery is claimed.

Re-derive: rerun T1986 and the listed core/interface baselines. Falsify: distinct
recursive identities, literal packed ranges, known-bad stack-only diagnostics,
invalid declaration/role/path controls and unchanged source refusal distinguish
semantic preparation from parity and parser acceptance. Durability: helper,
permanent tests, decision 0113, this task and book retain the contracts and the
repaired draft oracle. Parser context/carrier/runtime completion remains owned.


## Acceptance — contextual integration prerequisites `.60.4.3.2.3.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — Public parse/lower at 02827d840 emits `clock-domain violation` at perl/FSM/Scheduler/ISF/LoweringIR.pm line 3428 for foreign unsliced record_value.payload and whole data; scalar slices of record members/storage and scalar input slices/bit indexes instead lower successfully. LoweringIR::_validate_domain_signal_access recognizes single index paths but excludes colon ranges, then limits non-identifiers to actor_storage roots. Decision 0113 retains executable reproduction and the source-validation impact. No native behavior is inferred.
- [x] **ADDRESSED (verified)** — Integration now has exact owners for scoped contextual/enum gates, leaf sampling carriers, domain protection, first source admission and frontend/public replay. Confirmed domain bypasses are P1-owned and scheduled next under .3.4.1, with independent accepted/refused source controls and complete public/replay requirements; .3.4.2 retains record/formal namespace qualification. Source record ports still refuse, and the book exposes the current validation gap accurately. The repair is pending rather than falsely reported complete.
- [x] **NO REGRESSION** — Guarded existing T1920/T1259 checks report `All tests successful`; the retained public probe verifies the scoped baseline without native execution. Task-tree integrity, book build and staged doctrines verify the expanded graph, current/future product distinctions, fresh aggregate authority and generated knowledge/inventory before commit. This is ownership/decomposition; the pending domain defect is not erased by baseline success.

Re-derive: run the public command in decision 0113. Falsify: the same declared
foreign roots distinguish whole/member refusal from slice/index acceptance.
Durability: the exact pre-repair revision, executable source, owning P1 repair,
book limitation and Git retain the finding. First-line permanent oracles and
complete source/report/replay qualification belong to the repair slice.


## Acceptance — P1 domain slice/index repair `.60.4.3.2.3.4.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — Before production mutation, T1920 reports Failed test at t/1920-isf-storage-domain-path-ownership.t line 42: foreign record_value.payload[3:0] and scalar[3:0] return empty diagnostics; input slice/index controls fail likewise. The existing unsliced control throws at perl/FSM/Scheduler/ISF/LoweringIR.pm line 3428. The path matcher omits colon ranges and its non-identifier branch excludes actor inputs; local/formal root selection never runs for those forms. This is the P1 source-validation defect reproduced at 02827d840, not a new HDL behavior claim.
- [x] **ADDRESSED (verified)** — Colon ranges enter domain validation, and indexed scalar references select the nearest declared actor/formal/local root. Dotted paths preserve existing storage/enum/package classification. The exact same public probe now rejects every foreign case. T1920 independently requires the authored path/access/domains in the first diagnostic line, including nested/reversed/single-bit ranges and formal shadow positives. T1985 compares complete typed native/API/newline products with literal diagnostic messages, successful-metadata omission, schedule transport-error/no-partial-product and untouched-source controls. The book's known-gap note is replaced by the verified current rule.
- [x] **NO REGRESSION** — Guarded T1920/T1247/T1259 reports `All tests successful`; guarded T1920/T1985/T1982/T1986 also reports `All tests successful`. T1982 preserves complete historical domain reports, actual scheduled IAL0 files and SystemVerilog/Verilog HDL except date. Current scalar/storage/core type gates, same-domain paths, generated formal shadows, enum names and complete public discovery remain accepted. `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm` reports `syntax OK`. Book and staged doctrines verify current behavior, source locality, task ownership and generated knowledge/inventory before commit. The first staged doctrine gate reports rationale max lines 431 above baseline 421 plus growth 0; the warning-debt allowance is refreshed to measured actual plus its declared ratchet step, inside the unchanged 640-line ceiling. No native HDL execution or new record-port authoring is established.

Re-derive: rerun the decision's unchanged public probe and T1920/T1985.
Falsify: pre-mutation first-line oracles go RED; independently exact foreign
ownership messages and same-domain/formal controls distinguish domain enforcement
from broad refusal. T1982 compares complete old products and actual carriers/HDL.
Durability: repair, permanent source/report controls, owning task, decision 0113,
book and Git retain the cause and closure. Future record/domain member admission
remains under .3.4.2 after scoped contextual preparation.

## Acceptance — actual declaration scopes `.60.4.3.2.3.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — Existing value primitives require manual closed maps; actual parser declarations use resolved port/storage maps, explicit local AST clauses and untyped drive names. `_bit_op_width_map` establishes nearest local/formal lookup, and type finalization follows desugaring; a typed placeholder cannot establish width/type. The initial source fixture independently refused an assumed pin/storage collision: `Error: actor 'scopes' storage signal 'data' conflicts with interface input port 'data'` at perl/FSM/Adapter/ISF/Parser.pm line 9868. The corrected T1987 retains that source refusal and the current local collision/symbolic-width boundaries instead of treating scope projection as authoring admission.
- [x] **ADDRESSED (verified)** — `ISFRecordPortScopes` now derives detached actor/transaction/drive maps from actual declarations and delegates closed type/path/role validation to qualified value helpers. T1987 checks independent literal scope/range/signed/state witnesses, imported identity, unresolved placeholders and explicit shadows, known input roles, malformed width/name/role controls and mutation isolation. Its complete parser/scheduled-object comparison, including emitted file bytes, remains equal. Record inputs still refuse and the helpers remain unwired; sampling/contextual/domain delivery has separate owners.
- [x] **NO REGRESSION** — Guarded `prove -Iperl t/1987-isf-record-port-declaration-scopes.t t/1986-isf-record-port-value-gates.t t/1983-isf-interface-port-metadata.t t/1259-isf-aggregate-storage-type-aliases.t t/1391-isf-local-variables.t` reports `All tests successful`, `Files=5, Tests=33`. Producer and test syntax checks report syntax OK. The first doctrine gate rejects the expanded decision evidence-line width; refresh its measured warning allowance within unchanged ceilings, then rerun. mdBook, scoped decision signpost, task frontier, inventory and staged doctrine checks accompany this slice. No native HDL runtime or new transport/source field is claimed.

## Acceptance — contextual gates and first-touch repair `.60.4.3.2.3.2.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — T1988 first reports complete caller actor inequality, with the captured TAP diagnostic `#   at t/1988-isf-record-port-context-gates.t line 50.`: borrowed resolved widths become JSON numbers while numeric validation reads them. Fresh copied actor/transaction/drive controls in T1987 and independent explicitly string-width scope/reference/copy controls in T1986 go RED; direct fresh parser controls remain equal. The standalone JSON::PP numeric-read program in decision 0114 independently changes width string to number without assignment. `_binding` and value-gate validation read caller facts before cloning; the older mutation baseline followed an earlier projection. The draft also misclassifies admitted `mode.BUSY` under scalar input `mode`; the public parse/gate probe locates that path at the core `member_on_non_record` diagnostic.
- [x] **ADDRESSED (verified)** — All declaration and scope/reference/copy boundaries detach maps before numeric validation. The first-touch controls and complete T1988 products stay equal without oracle normalization. Context gates qualify selected transaction/rule/drive AST reads/copies and strict type/role failures, whole record scalar negation/comparison misuse, invalid members/indexes/operators, input writes and nearest shadows. Actual enum/package roots remain delegated while outer aggregate shadows prevent borrowed enum members. Unsupported sampling/count/trigger references refuse, and unknown tokens remain with existing validators. Source authoring and facades remain unwired; record admission and actual namespace/sample/domain integration retain owners.
- [x] **NO REGRESSION** — Guarded `prove -Iperl t/1988-isf-record-port-context-gates.t t/1987-isf-record-port-declaration-scopes.t t/1986-isf-record-port-value-gates.t t/1983-isf-interface-port-metadata.t t/1259-isf-aggregate-storage-type-aliases.t t/1391-isf-local-variables.t` reports `All tests successful`, `Files=6, Tests=42`. Existing parser/scheduled objects and emitted file bytes stay equal; malformed/cyclic type, metadata, alias/storage and local-declaration controls retain their contract. Syntax, mdBook, scoped decision, map/inventory and staged doctrines accompany this slice; no native HDL execution or new public/source admission is claimed.

## Acceptance — common declaration classifier `.60.4.3.2.3.2.3`

- [x] **ROOT CAUSE (WHY + WHERE)** — Current T1985 native/API/newline `--check --json`, `--emit-semantic-json` and `--emit-schedule-json` controls confirm scalar declarations and aggregate-port refusals; T1989 retains the first-line authored diagnostic interface port 'packet' references aggregate type. The private contextual namespace projection at 48da7b698 lacks shared aggregate and actor rule maps, so independently selecting roots risks borrowing an outer record through a scalar/unresolved formal or confusing enum/package tokens with scalar members. Actual declaration scopes and existing namespace producers identify the boundary; source integration must wait for sampling/domain prerequisites. This is owned preparation, not a new public admission defect.
- [x] **ADDRESSED (verified)** — The common scope projection supplies detached actual value, aggregate traversal, enum-exclusion, namespace and actor rule-declaration maps. The contextual gate consumes it. T1989 independently expects exact sets and imported/named-domain facts, and distinguishes member-validation ownership from enum ownership, scalar-pin coexistence from masked outer aggregates, input writes from reads, and transaction locals from actor rule operands. Fresh copied caller JSON and mutation of independent output maps preserve source and sibling facts. Frontend aggregate/enum/rule validators remain explicitly unwired until the separately owned mandatory gates qualify.
- [x] **NO REGRESSION** — Guarded `prove -Iperl t/1989-isf-record-port-root-classification.t t/1988-isf-record-port-context-gates.t t/1987-isf-record-port-declaration-scopes.t t/1986-isf-record-port-value-gates.t t/1985-isf-interface-port-public-qualification.t t/1982-isf-domain-storage-report.t t/1259-isf-aggregate-storage-type-aliases.t t/1391-isf-local-variables.t` reports `All tests successful`, `Files=8, Tests=52`. Complete public transport products, current source refusals, historical domain reports and emitted IAL0/HDL bytes except date stay unchanged. Syntax, mdBook build, scoped decision, generated map/inventory and staged doctrines accompany the slice. No native HDL execution or new authored record-port behavior is claimed.

## Acceptance — explicit scalar-leaf sample facts `.60.4.3.2.3.3.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — The native guarded `--strict --check --json` probe for an authored record input with explicit packet.data sampling reports success false, generated_output.emitted false and interface port 'packet' references aggregate type 'frame'. Record authoring remains refused while sampling prerequisites are prepared. Decision 0113 locates the current `_collect_sample_widths` exact-root lookup and missing resolved leaf properties; qualified scope/path primitives supply the actual facts without widening the parser. Initial T1990 TAP locates its nearest-local fixture failure with `#   at t/1990-isf-record-port-sample-facts.t line 73.`: the fixture replaced transaction clauses and removed the explicit local declaration, rather than exposing a scope defect. The corrected witness retains that local AST. The isolated earlier collision predicate allows prior scalar alias held to hide the original storage declaration; its known-bad run reports failed prior scalar sample cannot erase an authored storage collision at ./t/1990-isf-record-port-sample-facts.t line 41. Collision checks must retain the original declaration set rather than trust the rewritten sample scope.
- [x] **ADDRESSED (verified)** — A detached explicit sample plan uses qualified actual lexical roots for ordered entry/body/control samples, preserving scalar kind/width/signed/state facts, exact packed ranges and chained sample provenance. Unknown/formal/enum and alias shadows cannot borrow outer types. Whole aggregates, invalid paths, input targets, declaration collisions and inconsistent repeated record-derived scalar types refuse. A pure private type product emits existing core scalar AST declarations and exact type refs/widths, reserves names deterministically and adds no reset/default or capture state. T1990 independently reconstructs these scalar types through the actual public type resolver and preserves complete fresh copied caller products and independent sibling maps. Source/carrier wiring remains pending.
- [x] **NO REGRESSION** — Guarded `prove -Iperl t/1990-isf-record-port-sample-facts.t t/1989-isf-record-port-root-classification.t t/1988-isf-record-port-context-gates.t t/1987-isf-record-port-declaration-scopes.t t/1986-isf-record-port-value-gates.t t/1100-isf-sample-piggyback.t t/1111-isf-sample-before-data-ops.t t/1195-isf-sample-clause-boundary.t t/1259-isf-aggregate-storage-type-aliases.t t/1391-isf-local-variables.t` reports `All tests successful`, `Files=10, Tests=61`. Existing entry/drive/await/pre-data capture and malformed-clause boundaries stay green; complete parsed/scheduled products and actual emitted bytes stay unchanged. Syntax, mdBook, scoped decision, map/inventory and staged doctrines accompany the slice. No authored record-port, typed private carrier replay, new capture timing or native HDL execution is claimed.

## Acceptance — contextual explicit sampling `.60.4.3.2.3.3.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — T1991 run against an isolated exact context producer from e0015db1314cfc0625609a358219c85a8d4cfa4b reports failed selected explicit scalar sample context, with captured TAP `#   at ./t/1991-isf-record-port-sample-contexts.t line 37.` and first diagnostic Invalid ISF record context: transaction 'main' on body sample clause does not admit record port reference 'packet.count'. The prior `_clauses` fallback routes samples through `_unsupported` and has no resolved sampled-alias scope. This is the owned unwired consumer prerequisite; authored record source is still refused. Forward unresolved sample chains also need a precise refusal before scalar signed/state facts can be lost. The draft selector first-touch probe returns false while changing inputs [null] to [{}]; added T1991 caller-isolation controls go RED at t/1991-isf-record-port-sample-contexts.t line 60, and raw hash failures locate the unchecked read at ISFRecordPortSamples.pm line 19. A standalone Perl array/hash read independently autovivifies the same shape.
- [x] **ADDRESSED (verified)** — The contextual gate consumes the qualified ordered sample plan only for supplied resolved record-input actors and overlays detached scalar alias bindings. Selected entry/body/control samples then feed actual scalar reads/copies, preserving exact alias widths and input roles. The port-only selection delegates existing packed storage and namespaces without new aggregate layouts. Whole input snapshots, bad paths, original declaration collisions, input targets, inconsistent repeated types and unresolved forward record-derived sample aliases refuse. The selector now validates interface/list/entry shapes before dereference and checks the complete declaration inventory, preserving absent and malformed caller facts. T1991's predecessor and first-touch comparisons are RED and current controls pass, including nearest formal/local/unresolved masks and complete caller products. Parser, scheduler, module type/width ABI and capture-state emission remain untouched.
- [x] **NO REGRESSION** — Guarded `prove -Iperl t/1991-isf-record-port-sample-contexts.t t/1990-isf-record-port-sample-facts.t t/1989-isf-record-port-root-classification.t t/1988-isf-record-port-context-gates.t t/1987-isf-record-port-declaration-scopes.t t/1986-isf-record-port-value-gates.t t/1100-isf-sample-piggyback.t t/1111-isf-sample-before-data-ops.t t/1195-isf-sample-clause-boundary.t t/1259-isf-aggregate-storage-type-aliases.t t/1391-isf-local-variables.t` reports `All tests successful`, `Files=11, Tests=67`. Complete ordinary parsed/scheduled objects and actual emitted bytes stay equal; existing sampling timing, malformed clauses, storage/local and namespace/role contracts retain their owners. Syntax, mdBook, scoped decision, map/inventory and staged doctrines accompany the slice. No authored record-port admission, module carrier change or native HDL execution is claimed.

## Acceptance — private scalar sample module carriers `.60.4.3.2.3.3.2.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — Isolated exact 24d0abf84622ffaf6e665ae425e86f687968995c LoweringIR makes T1992 fail expected private scalar types, widths and roles, with captured TAP `#   at t/1992-isf-record-port-sample-carriers.t line 53.` and missing inferred_storage width at line 67. Legacy exact-root sample width lookup cannot carry resolved leaf signed/state facts. Its untyped parent still passes native `--check --json`, demonstrating why strict replay alone is insufficient. The broader gate also reproduces T1938's stale raw/finalized guard comparison against that predecessor at original line 27: raw guard.port differs after qualified payload snapshot integration. The tracked producer boundary locates the transform after raw parent_activation_products; independent request/entry/capture/held witnesses and isolated omitted-installation RED controls distinguish correct final products.
- [x] **ADDRESSED (verified)** — Qualified port-only widths enter the existing transaction map before data collectors. The separate module consumer reserves actual type names, checks declarations/ownership and metadata, adds ordinary typed scalar declarations and explicit internal aliases, and retains exact eleven-product ABI and capture lowering. Actual parent/spawn-child/domain IAL0 strictly replays with independently expected scalar properties and no public alias pins/reset leakage. T1938 now compares complete selected snapshot products for transformed DTs and exact raw assignments elsewhere; independent normalized-IR guards/capture/held values pass. Its first new witness spelling was corrected to symbolic state_active and flattened conjunctions, not by changing production. Both known-bad comparisons are RED and current controls pass. Authored records remain refused; comprehensive helper ownership and timing have later owners.
- [x] **NO REGRESSION** — Guarded `prove -Iperl t/1992-isf-record-port-sample-carriers.t t/1991-isf-record-port-sample-contexts.t t/1990-isf-record-port-sample-facts.t t/1989-isf-record-port-root-classification.t t/1988-isf-record-port-context-gates.t t/1987-isf-record-port-declaration-scopes.t t/1986-isf-record-port-value-gates.t t/1985-isf-interface-port-public-qualification.t t/1982-isf-domain-storage-report.t t/1100-isf-sample-piggyback.t t/1111-isf-sample-before-data-ops.t t/1195-isf-sample-clause-boundary.t t/1259-isf-aggregate-storage-type-aliases.t t/1391-isf-local-variables.t t/1945-isf-formal-child-products.t t/1936-isf-formal-source-context.t t/1938-isf-formal-parent-products.t` reports `All tests successful`, `Files=17, Tests=95` after the owned oracle repair. Complete public transport and historical domain carriers, ordinary sample timing and formal products pass. Producer/test syntax is OK and mdBook builds. Initial pressure gate identifies task/rationale growth; measured warning allowances are refreshed with their own ratchet steps within unchanged ceilings, with fresh exact book authority, generated map/inventory and staged doctrines before commit. No native HDL execution is claimed.

## Acceptance — actual sample ownership and metadata isolation `.60.4.3.2.3.3.2.3`

- [x] **ROOT CAUSE (WHY + WHERE)** — T1993 selects real storage_roles/counter/port products rather than guessed names. Isolated omission of RecordSamples transaction/multiple-owner/module ownership checks makes actual drive/spawn/counter and other-writer refusals fail, with TAP `#   at t/1993-isf-record-port-sample-ownership.t line 43.` Current ownership checks pass. Fresh copied actors separately fail caller JSON equality at line 45: interface_port_metadata width strings become numbers even on refused drive/spawn lowering. Direct snapshot of width string 3 independently reproduces this. Capture/snapshot numerically read borrowed widths/ranges before rebuilding output; T1983 new first-touch valid/refused controls are RED at line 95/111. The earlier standalone Perl numeric-read witness explains scalar-flag mutation; deep comparisons after validation miss its original JSON kind. The pre-repair producer is retained at 53c7f9a5361fa0af96dcc94af7150218b3c22b14.
- [x] **ADDRESSED (verified)** — Permanent actual helper/writer negatives and strict positive repeated/distinct-module owners qualify the existing ownership implementation. Both public interface metadata boundaries now detach validated containers before reading numeric members. T1983 independently expects unchanged numeric nested layouts, source JSON on first successful/refused validation, precise malformed-suffix diagnostics and detached output edits; T1993 caller-isolation failures now pass. No normalized metadata schema/product, capture assignment/state order or source admission changed. The carrier-integration parent closes; complete replay/timing retains its next owner.
- [x] **NO REGRESSION** — Guarded `prove -Iperl t/1993-isf-record-port-sample-ownership.t t/1983-isf-interface-port-metadata.t t/1984-isf-interface-port-report-integration.t t/1985-isf-interface-port-public-qualification.t t/1992-isf-record-port-sample-carriers.t t/1991-isf-record-port-sample-contexts.t t/1990-isf-record-port-sample-facts.t t/1989-isf-record-port-root-classification.t t/1988-isf-record-port-context-gates.t t/1987-isf-record-port-declaration-scopes.t t/1986-isf-record-port-value-gates.t t/1100-isf-sample-piggyback.t t/1111-isf-sample-before-data-ops.t t/1195-isf-sample-clause-boundary.t t/1259-isf-aggregate-storage-type-aliases.t t/1391-isf-local-variables.t t/1938-isf-formal-parent-products.t t/1945-isf-formal-child-products.t` reports `All tests successful`, `Files=18, Tests=103`. Complete native/API/newline public products, ordinary sampling/formal controls and current record refusal remain qualified. Producer/test syntax is OK and mdBook builds. Synchronized decision/map/inventory, measured warning allowances within unchanged ceilings, exact book authority and staged doctrines accompany the slice. No native HDL execution is claimed.


## Acceptance — complete sample replay and capture-state preservation `.60.4.3.2.3.3.3`

- [x] **ROOT CAUSE (WHY + WHERE)** — Isolated LoweringIR based on 401aea31d1159e4136c3903304373f6ea43b099f deletes only packet-derived capture guards in _ir_on. T1994 reports `#   at t/1994-isf-record-port-sample-replay.t line 76.` for complete entry/imported states and line 107 for the independent literal entry guard; expected guards are missing. Actual `--emit-semantic-json` replay and scalar-type witnesses still pass on that mutant, so replay/type success alone cannot establish the capture-state contract. This is calibration of the remaining preparation obligation, not a production regression. The initial reference incorrectly authored storage-leaf sampling, which the current parser refuses; admitted scalar samples with explicitly substituted operands provide the valid reference.
- [x] **ADDRESSED (verified)** — Permanent T1994 compares every complete state field after only deliberate sample-source substitution and independently requires start-qualified entry capture, existing unguarded await capture and pre-data ordering. Entry/await/drive and nested when/while/until/repeat/switch controls pass. Actual native typed IAL0 semantic replay independently checks exact leaf scalar specs in symbol types and private structural nets, actual source identity and private alias ownership. Real imported leaves, nearest distinct scalar formal and precise whole/invalid/masked refusals preserve complete caller JSON. The guard-loss control is RED and the unchanged production module is GREEN. Sampling preparation closes; domain/frontend admission and native/runtime delivery remain owned next.
- [x] **NO REGRESSION** — Guarded `prove -Iperl t/1994-isf-record-port-sample-replay.t t/1993-isf-record-port-sample-ownership.t t/1992-isf-record-port-sample-carriers.t t/1991-isf-record-port-sample-contexts.t t/1990-isf-record-port-sample-facts.t t/1989-isf-record-port-root-classification.t t/1988-isf-record-port-context-gates.t t/1987-isf-record-port-declaration-scopes.t t/1986-isf-record-port-value-gates.t t/1983-isf-interface-port-metadata.t t/1100-isf-sample-piggyback.t t/1111-isf-sample-before-data-ops.t t/1195-isf-sample-clause-boundary.t t/1259-isf-aggregate-storage-type-aliases.t t/1391-isf-local-variables.t` reports `All tests successful`, `Files=15, Tests=87`. `perl -Iperl -c t/1994-isf-record-port-sample-replay.t` reports syntax OK. Book, exact aggregate authority, generated knowledge/inventory and staged doctrine/hook gates accompany the slice. No native HDL execution is claimed.

Re-derivation is actual complete state/carrier/semantic replay; falsification is
the isolated guard-loss control plus independent scalar specs and precise
negative/shadow witnesses; durability is T1994, the tracked production boundary,
decision 0114's mutation recipe and this task record. Ignored logs under
`.artifacts/record-sample-replay-*` supplement those tracked sources. Native
runtime and full frontend/backend/consumer signoff remain explicitly missing
and owned by following record delivery leaves. Rationale is canonical in 0114;
DEVELOPMENT_NOTES needs no duplicate entry.


## Acceptance — record/formal domain roots and drive ingress `.60.4.3.2.3.4.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — T1995's pre-repair supplied aux-owned packet member/slice/list/sample/control/rule/drive paths lower from core with empty diagnostics: _validate_domain_signal_access recognizes dotted storage only. T1920 newly reports `#   at t/1920-isf-storage-domain-path-ownership.t line 57.` for inline and named storage read/write cases. _ir_drive emits its first array assignment at index one while domain validation starts at two; used named bodies receive no ownership validation. Ordinary scalar-only public probes independently accept core reads of aux data and writes of aux remote in both forms. Production predecessor is 8698b1a897752036b875c27336306582665dc4e3. Strict `--check --json` also confirms the separate unused parameterized-drive top width conflict on the exact ordinary source in decision 0114; that P2 repair is owned immediately next, not classified away.
- [x] **ADDRESSED (verified)** — Finalized record input roots retain nested path domains, nearest scalar formals keep their actual local/physical identities and scalar enum/package names remain delegated. Complete caller facts, exact first diagnostics, imported types, selected contexts, owned declaration snapshots and every positive actual domain/top IAL0 carrier qualify. Inline checks now cover the emitted first assignment; each used named body's read/write validation uses its real call domain and parameter masks. T1920 prior RED drive controls are GREEN; T1985 complete native/API/newline diagnostics preserve exact authored ownership and absent successful/partial products. The isolated all-scalar record_root mutation falsely refuses valid mode.ON and exits nonzero; current namespace controls pass. The unused-drive carrier defect remains scheduled under .4.3 before frontend admission.
- [x] **NO REGRESSION** — Guarded `prove -Iperl t/1995-isf-record-port-domain-roots.t t/1920-isf-storage-domain-path-ownership.t t/1247-isf-clock-domain-partition.t t/1982-isf-domain-storage-report.t t/1985-isf-interface-port-public-qualification.t t/1989-isf-record-port-root-classification.t t/1992-isf-record-port-sample-carriers.t t/1994-isf-record-port-sample-replay.t t/1936-isf-formal-source-context.t t/1945-isf-formal-child-products.t t/1387-isf-cross-domain-activation-handshake-lowering.t` reports `All tests successful`, `Files=11, Tests=87`. Historical complete public reports and actual scheduled/HDL bytes except date remain equal; current record refusal, sampling, formals and explicit crossings pass. Producer/new/updated test syntax is OK and mdBook builds. Exact aggregate book/reference authority, generated map/inventory, measured warning allowances within unchanged ceilings and staged doctrines/hooks accompany the slice. No native HDL execution or complete authored record delivery is claimed.

Re-derivation uses public before/after lowering and actual full carrier/report
products; falsification uses independently valid leaf contexts, exact authored
domain messages, nearest bindings and the observed bad scalar-root predicate;
durability is T1995/T1920/T1985, the immutable predecessor, decision 0114's
recipes and owning nodes. Ignored record-domain logs supplement tracked sources.
The separately confirmed P2 unused-drive source and impact have immediate
repair ownership; record admission and native/backend/consumer completion
remain subsequent gates. Canonical rationale is in 0114, without duplicate
DEVELOPMENT_NOTES narration.

The first map regeneration rejected decision 0113 at 567 lines above its
512-line fact-card bound. New domain/drive contextual facts are routed intact
to existing decision 0114, with a direct canonical pointer from 0113; existing
questions and facts are retained, and no topic/card or ceiling is added.

## Acceptance — independent domain drive selection `.60.4.3.2.3.4.3`

- [x] **ROOT CAUSE (WHY + WHERE)** — At 68880895fc4635f04b631f705ad548a600bddb3f, T1996 reports Failed test with `#   at t/1996-isf-domain-drive-selection.t line 57.`: literal empty domain definition sets instead contain aux_publish and publish. Native `--strict --check --json` on decision 0114's exact ordinary source reports success false: core publish_value width 8 conflicts with aux width 1. DomainSource copies every definition into each actor; _build_drive_dts emits its helpers and _drive_param_width infers widths from local outputs, defaulting to one without a target. Full transport parity alone agrees on that incorrect result.
- [x] **ADDRESSED (verified)** — The private partition retains sorted selected names from its already validated actual drive-use map. The shared actual/formal domain constructor clones only selected bodies, including generated-child calls, and refuses malformed, unknown or duplicate selection. T1996 independently qualifies exact definition sets, inactive-helper absence, nested/generated retention, detached bodies and unchanged caller facts. Every actual domain/top/generated IAL0 file strictly replays. Complete native/API/newline check, semantic and schedule products agree with successful tool results, clean tool stderr and unchanged exact source bytes. The original native strict source now reports success true. An isolated drop-all-definitions DomainSource control exits 255 on `Transaction 'main': drive 'publish' not defined` at LoweringIR.pm line 8838; active definitions are required.
- [x] **NO REGRESSION** — Guarded final `prove -Iperl t/1996-isf-domain-drive-selection.t` reports `All tests successful`, `Files=1, Tests=4`. Guarded `prove -Iperl t/1995-isf-record-port-domain-roots.t t/1920-isf-storage-domain-path-ownership.t t/1955-isf-formal-domain-source-products.t t/1957-isf-formal-domain-reservation-integration.t t/1945-isf-formal-child-products.t t/1970-isf-source-writer-owners.t t/1255-isf-schedule-report-golden-matrix.t t/1387-isf-cross-domain-activation-handshake-lowering.t` reports `All tests successful`, `Files=8, Tests=59`. Existing formal/domain products, reservations, writer ownership, complete historical schedules and explicit crossings pass. Both producers and T1996 report syntax OK; mdBook builds. Prior domain partition/storage report controls also passed. Exact book/reference authority, bounded canonical decision, map/inventory and staged doctrines/hooks accompany this slice.

Re-derivation uses actual public strict source and complete carrier/report replay;
falsification uses literal selected bodies, absent inactive helpers, the complete
pre-repair RED run and observed drop-all-definitions control; durability is
T1996, the tracked producers, immutable predecessor and decision 0114's recipes.
One aggregate run was RAM-guard terminated at 91.4% host usage, exit 137;
no pass is inferred from it. Final completed runs use the unchanged 88% cutoff.
The qualified-corpus row helper rejects dynamic source IDs by design; the draft
transport fixture now uses the established actual capture protocol. No product
path-policy change is made. Canonical rationale belongs to 0114; no duplicate
DEVELOPMENT_NOTES entry is needed. Source record admission remains next,
and native/backend/consumer qualification retains its existing owners.

## Acceptance — parser/module record gate integration `.60.4.3.2.3.5.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — At 6f7b30bb4498f3ab13f294fae6a209342a4ef4c4, the corrected full T1997 reports `#   at t/1997-isf-record-port-gate-integration.t line 70.` for valid supplied packet.data: actual parser enum phases report unknown enum member instead of selecting the declared record. Parser enum/rule maps select storage only. Independent formal/executable negatives lack contextual input-write, whole-scalar and exact-copy refusal because _prepare_module_source does not call the prepared gate. The full pre-integration run fails subtests 1-3; source aggregate refusal passes. This is an unfulfilled preparatory integration obligation, not new authored admission.
- [x] **ADDRESSED (verified)** — Resolved parser phases and shared formal/executable source preparation apply the qualified contextual role/type/copy/sample gate for record-input facts. Canonical nearest actor/transaction/drive projections supply record-bearing enum exclusions and actor rule declaration/aggregate roots. T1997 exercises actual later parser phases with only a finalized-fact fixture promotion, keeping every production validator. Literal layout, valid scalar/copy/sample contexts, nearest scalar/formal/parameter masks and real enum names pass. Invalid paths, input targets, wrong copies, whole scalar contexts, operator references and unsupported waits refuse on the first cause; unknown rule operands stay with their original validator. Both actual module entry points preserve complete caller JSON on accepted/refused actors. Removing only the shared gate in an isolated LoweringIR makes module subtest 3 fail while parser phases and source refusal pass. Authored record source remains refused.
- [x] **NO REGRESSION** — Guarded `prove -Iperl t/1997-isf-record-port-gate-integration.t t/1989-isf-record-port-root-classification.t t/1988-isf-record-port-context-gates.t t/1995-isf-record-port-domain-roots.t t/1994-isf-record-port-sample-replay.t t/1993-isf-record-port-sample-ownership.t t/1992-isf-record-port-sample-carriers.t t/1987-isf-record-port-declaration-scopes.t t/1986-isf-record-port-value-gates.t t/1983-isf-interface-port-metadata.t t/1259-isf-aggregate-storage-type-aliases.t t/1391-isf-local-variables.t t/1996-isf-domain-drive-selection.t` reports `All tests successful`, `Files=13, Tests=77`. Guarded complete public/historical/sample cohort `prove -Iperl t/1985-isf-interface-port-public-qualification.t t/1255-isf-schedule-report-golden-matrix.t t/1100-isf-sample-piggyback.t t/1111-isf-sample-before-data-ops.t t/1195-isf-sample-clause-boundary.t` reports `All tests successful`, `Files=5, Tests=21`. Complete native/API/actual newline products, historical schedule carriers, prior sampling, private sample ownership/types and domains pass. Producer/test syntax is OK and the final mdBook build passes after host headroom recovered. The earlier 89.7% host cutoff exits 137 without a build verdict; no cutoff is raised. Exact reference authority, map/inventory, measured warning allowances and staged doctrines/hooks accompany completion.

Re-derivation uses real parser phase order and both formal/executable source
entry points; falsification uses independent first-line role/type/path/context
failures and the observed isolated omission control. Durability is T1997,
tracked producers, the immutable predecessor and decision 0113's integration
recipe. The draft's positive parameter declaration was corrected to actual
parenthesized drive formals; nonfatal diagnostic capture lets all independent
negative subtests run before the producer changes. Ignored logs supplement
tracked controls. No authored admission, native HDL execution or complete
backend/consumer signoff is claimed; those remain subsequent owned gates.
Canonical rationale belongs to 0113; DEVELOPMENT_NOTES gains no duplicate.


## Acceptance — authored record-input admission `.60.4.3.2.3.5.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — At 0d01ca3fc8f880acf926ae59305843a1172bf1d3, guarded T1998 reports `#   at t/1998-isf-record-input-source-admission.t line 48.` and `actor 'records' interface port 'packet' references aggregate type 'frame'`: valid local/imported record sources cannot reach the already integrated contextual gates. Parser::_finalize_actor_type_references supplies no record permission to actor interfaces, and _resolve_typed_width_entry permits aggregate aliases only for storage. The pre-admission run fails positive source and selected first-cause diagnostic subtests 1-3 while remaining-carrier refusal passes. This is the selected admission obligation, distinct from fixture width or binding errors.
- [x] **ADDRESSED (verified)** — The resolved type boundary admits only actual record-kind actor inputs. Existing layout, nearest-declaration contexts, exact-copy roles/types, domain and scalar sample consumers remain authoritative. T1998 independently expects the complete ordered nested field layout and local/imported identities, checks unchanged complete caller JSON, actual schedule metadata, native original-source success and every emitted IAL0 carrier. Live leaves/slices, same-type owned-storage copies, explicit captures, rules, drives, generated scalar output binding and unused declarations pass. Invalid input targets/aliases, whole scalar/operator/trigger contexts, members/items, same-width wrong types and foreign domains name their first cause; record outputs, root-list and transaction aggregate ports still refuse. Complete T1985 native/API/actual newline check, semantic, schedule and discovery products include literal metadata for the maintained record_input fixture and preserve exact source bytes.
- [x] **NO REGRESSION** — Guarded `prove -Iperl t/1998-isf-record-input-source-admission.t t/1997-isf-record-port-gate-integration.t t/1983-isf-interface-port-metadata.t t/1984-isf-interface-port-report-integration.t t/1986-isf-record-port-value-gates.t t/1987-isf-record-port-declaration-scopes.t t/1989-isf-record-port-root-classification.t t/1990-isf-record-port-sample-facts.t t/1991-isf-record-port-sample-contexts.t t/1992-isf-record-port-sample-carriers.t t/1993-isf-record-port-sample-ownership.t t/1994-isf-record-port-sample-replay.t t/1995-isf-record-port-domain-roots.t t/1996-isf-domain-drive-selection.t t/1259-isf-aggregate-storage-type-aliases.t t/1255-isf-schedule-report-golden-matrix.t` reports `All tests successful`, `Files=16, Tests=89`. Complete guarded T1985 reports `All tests successful`, `Files=1, Tests=6`; guarded T1883/T248 reports `Files=2, Tests=7201`. Producer/test syntax and `mdbook build docs/book` pass. Corpus catalog omission fails the independent literal counters as expected. Exact maintained book/spec authority, unchanged ceilings, map/inventory and staged doctrines/hooks accompany this slice.

Re-derivation uses actual authored native source and every strict IAL0 carrier,
complete public products, and the maintained catalog/source-cohort derivation.
Falsification uses the pre-admission RED run, literal nested layout and exact
field properties, equal-width wrong-type/input-target/context controls, and
observed omission of only feature.isf_record_input from an isolated catalog:
T248 exits 2, reporting supported 385 versus 386 and strict 375 versus 376.
Durability is the tracked parser, maintained source, T1998/T1985/T1883/T248,
immutable predecessor and decision 0113. Ignored logs supplement those recipes.

The draft's five-bit-to-eight-bit assignment was corrected to width-aligned
outputs after actual strict checking refused widening. Unbound job.seen is
reproduced for both record and ordinary scalar sources; an explicit scalar
formal and published output binding correct the positive fixture. These are
existing closed contracts, not new product defects. One public aggregate was
RAM-guard terminated at 88.2% host usage, exit 137. Two aggregate invocations
used nonexistent T1883/T1993 basenames; individual green files in those runs
are not suite passes. Final path enumeration and completed commands above
supply the verdicts, using the unchanged 88% cutoff.

No native HDL execution occurred. Complete frontend matrix .3.6,
generated/domain behavior .2.4, and independent runtime/backend/supplied
consumer completion .2.5 remain owned; the runtime leg is explicitly missing
here and retains the HIAL failure-only prerequisite. Canonical rationale
belongs to 0113; DEVELOPMENT_NOTES gains no duplicate.


The first staged doctrine run identified one new general-book candidate: the
maintained example's exact flag/data bit indices. Its reviewed disposition
classifies those as syntax/example values under the claim policy, with actual
independent T1985 field-range/property witnesses and T1998 nested-order controls.
No numeric metric is excused and no checker is weakened; the final staged gate
must cover the new disposition.


The added draft 0115 made the staged rationale collection contain 116 files
against the unchanged 128-file target/ceiling, entering its 90% rollover band
(`surface rationale is at 90.6% and must declare rollover_debt`). Existing
`.51.3` already owns identity/index cardinality rollover and is next after this
clean commit, before further record growth; .3.6 keeps frontend qualification.
This slice consolidates the admission facts into canonical 0113 instead of
adding a redundant record. Its removed Retrieval signpost repeated the preceding
source/value, metadata, delivery-order and consequence contracts; no evidence
recipe or unique fact was removed. Plain-prose reflow checks unchanged word
sequences, preserving code/front matter/lists. The draft's actual admission,
fixture corrections, controls and explicit runtime gaps now live in 0113;
its three answer questions and T1998 evidence move there. Stable prior identity
and questions remain; the Knowledge Map must prove their continued routing.
No ceiling grows and no rollover-debt reclassification excuses this work.


## Acceptance — decision identity/cardinality audit `.51.3.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'Every original path remains' -1 --format='%H %s' -- docs/decisions/0108-decision-records-seal-originals-with-stable-retrieval.md` returns cca713eff2f241c920275ec423454183ac6ab083, the .51.2 body seal. Its root forwarding identities deliberately remain. The admission slice's staged gate reports `surface rationale is at 90.6% and must declare rollover_debt` when adding a record. At fixed clean source 25c01f0127144922ade78951b91439e1d9221c08, the producer and independent direct-directory Git population/literal ID set establish 114 decision paths plus INDEX, with 50 forwarders and 64 canonical bodies. This cardinality cannot shrink merely by sealing more bodies; retiring paths would violate known identity/provenance contracts and cannot prove unseen external safety.
- [x] **ADDRESSED (verified)** — The task-owned bounded audit captures complete per-ID destinations, blob dimensions/digests, fact identities, fixed original-reader comparisons, scoped full-basename/fragment consumer candidates and a separate generic code-path search. It invokes the captured published CLI and inputs in a same-volume temporary fixture, then compares every sealed original with its independent Git source. Final current instrument replay exactly matches the tracked fixed census, while current owned docs differ; ambient working reader inputs cannot substitute. T1999 observes equal-count duplicate IDs, substituted identities, wrong per-ID destinations, missing and escaping routes refuse. Review identifies the direct T1809 body/status read, 0062/0091 reverify bodies, recursive Knowledge Map and root-index bootstrap, stable exported path strings, published reader navigation, and the flat-only authority grammar. Canonical 0108 preserves its entire pre-audit body and adds the finite compatibility/current semantic partition contract; .51.3.2-.3 own actual migration, precise reader/authority prerequisites and fresh capacity. No decision moved and no ceiling widened.
- [x] **NO REGRESSION** — Guarded `prove -Iperl t/1999-decision-identity-capacity-audit.t t/1923-decision-record-archive.t t/1554-live-document-size-doctrine.t` reports `All tests successful`, `Files=3, Tests=22`. Exact original/public-reader, altered-original, duplicate/reordered/missing archive, stale view/alias/index/link and neutral containment controls pass. Both new Python modules parse with syntax OK; the Perl wrapper completes. The final pinned audit replay compares byte-for-byte equal with `cmp`, and `mdbook build docs/book` passes. Bounded canonical facts, unchanged-ceiling exact book authority, Knowledge Map/inventory and staged doctrines/hooks accompany this audit. Native HDL, external consumers and migration completion have no signoff here.

Re-derivation is the tracked fixed-revision producer and public original-reader
comparison. Falsification is the independent direct-directory Git member set,
literal 0001-0114 identity population, per-ID destinations, observed equal-count
bad routes and T1923's original-byte/corrupt-navigation controls. Durability is
the tracked instrument, fixed input revision, JSON census, tests, canonical 0108
and existing version-history retention. The 1050 basename candidate lines and
101 generic code candidates describe those scoped lexical populations, not a
defect or complete dynamic/external-reader count. Four literal fragment targets
must remain reachable; unknown external headings also require retained original
heading compatibility rather than an absence inference.

The producer's first replay reproduced the capture; final generic/fragment
instrument changes and explicit submodule opt-out were re-executed before
completion. All fixtures stay under .artifacts and temporary captured-reader
files are removed by their owning context. Original sealed history, spent
compiler/proxy evidence and other repositories remain untouched. Atomic storage
and reader/authority integration are deliberately subsequent leaves, and
DEVELOPMENT_NOTES gains no duplicate of the canonical contract selection.


## Acceptance — closed decision catalog preparation `.51.3.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'Every original path remains' -1 --format='%H %s' -- docs/decisions/0108-decision-records-seal-originals-with-stable-retrieval.md` returns cca713eff2f241c920275ec423454183ac6ab083, the original body seal that preserved flat path cardinality. The audit 8acfa9c087f971706fd35a3755d208792d27076f and canonical 0108 select finite compatibility plus current semantic parts; the published reader still accepts only sealed originals, and the authority checker retains its flat-only path grammar. Broadening that grammar or moving bodies before full source/identity gates would admit substituted or unresolved authority. This preparation leaf therefore precedes both integrations.
- [x] **ADDRESSED (verified)** — `scripts/decision_catalog.py` defines one closed location/source/catalog contract with independent original-byte closure, derived metadata/headings, exact transition metadata and detached caller products. T2000's independent literal supplied future stores exercise all three parts and accepted current/original products. The complete existing current bodies parse within the content/metadata grammar. Same-size original corruption, source/type/part/body substitutions, duplicate/reordered/missing IDs, borrowed sealed/fact identities, unsupported and escaping paths, malformed dimensions/digests, copied metadata, unresolved sources and file/parent symlinks refuse; failure leaves a caller boolean unchanged. Fresh IDs do not create old root aliases. A selected-snapshot byte accessor uses the same checks. Canonical 0108 and the book state source authentication and complete navigation/rendering are integrating duties, not claims established by this pure helper. No live paths, source storage, published reading or authority admission changed.
- [x] **NO REGRESSION** — Guarded `prove -Iperl t/2000-decision-catalog-preparation.t t/1999-decision-identity-capacity-audit.t t/1923-decision-record-archive.t t/1560-live-document-ceiling-authority.t t/1554-live-document-size-doctrine.t` reports `All tests successful`, `Files=5, Tests=32`. Original public byte retrieval, corrupt/stale archive/navigation controls, existing flat authority and neutral containment remain green. Python syntax is OK; all existing current source bodies are parsed by the new extractor. The book, bounded Knowledge Map/inventory and staged doctrines/hooks are required commit checks. Re-derivation is the source/current byte and metadata comparison; falsification is the literal independent fixtures and observed planted failures; durability is tracked helper/tests, canonical 0108, task ownership and Git. Initial metadata equality is distinct from later owned supersession; production source authentication, body meaning, index/compatibility rendering and live integration remain .2-.3, with no external or HDL execution signoff here.


## Acceptance — authenticated decision-store/navigation preparation `.51.3.2.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'The caller supplies an independently authenticated transition census' -1 --format='%H %s' -- scripts/decision_catalog.py` returns ea6b332fdfe4b7fe9d74b508bd0f144e57915059. Its pure preparation API correctly delegates source authentication and complete compatibility/navigation to integrating callers; it cannot establish historical authority from copied metadata. The root index also carries unique title/type/summary values, so preserving IDs alone would lose source value. Authenticated fixed-input loading, full original-index retention and complete navigation must precede public admission.
- [x] **ADDRESSED (verified)** — The shared store helper authenticates independently supplied source/index digests before preparation and retains complete original index text. Literal future-store products compare exact originals, current metadata, root/part routes and independent compatibility pages with the same complete heading sequence; no separate slug grammar is introduced. Fresh IDs navigate through all three parts without new root aliases. Known-bad source/index fingerprints, missing originals/current members, duplicate/substituted/escaping/malformed/fenced routes, type/part drift, stale page/headings, missing sealed anchors, extra root aliases and symlinks refuse. Selected snapshots require complete selected inventories, and broken ambient bytes cannot substitute. Shared fence handling rejects fake closing runs and unterminated blocks; every existing current body, published sealed original and root-index row fits the grammar. Later owned summary/status changes remain current while initial transition values must be exact. Real sources, published reader and authority gate remain unchanged until the subsequent owned children.
- [x] **NO REGRESSION** — Earlier guarded T2001/T2000/T1999/T1923/T1560/T1554 completed `All tests successful`, `Files=6, Tests=34`. After final shared fence refinements, another aggregate passes the first five files but stops at host memory 88.2% under the unchanged 88% cutoff, exit 137, before containment finishes; that aggregate is incomplete and is not a pass. The final unchanged-guard re-execution completes `All tests successful`, `Files=6, Tests=34`; complete output is .artifacts/decision-store-navigation-final-tests.log. The book build and staged doctrines/hooks accompany the required commit workflow. Python syntax and actual old source/index grammar checks pass. Re-derivation is authenticated exact source/current/index loading and per-ID route comparison; falsification is independent literal source/alias/index fixtures with observed corrupt/misrouted/stale/ambient controls; durability is tracked helpers/tests, canonical 0108 and this owner. Production fingerprint installation, actual reader/authority integration, real body/link closure, external signoff and storage rollout remain the subsequent children.


## Acceptance — published authenticated decision reader `.51.3.2.2.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S "require(archive['schema_version'] == 1" -1 --format='%H %s' -- scripts/decision_records.py` returns cca713eff2f241c920275ec423454183ac6ab083. Actual copied-archive CLI reproduction sets only schema_version to JSON true: exit 0 and exact original bytes are returned because Python equality treats True as integer one. Another actual supplied-store probe adds a unique first fact ID/questions to originally unindexed 0100: exit 1, current record loses source fact identity/questions; the helper incorrectly treats null absence as a protected identifier. Shared store loading/navigation is qualified, but actual public original/current/request boundaries and production provenance still need integration.
- [x] **ADDRESSED (verified)** — The actual CLI now supports explicit trusted supplied-store fingerprints, check/read/read-original/read-current and exact canonical resolve. Immutable transition originals and current owned updates are distinct, fresh uncaptured records have current products, and unavailable/unknown/malformed/oversized requests refuse before stdout. Complete store identity/compatibility/index validation precedes every supplied operation. Production pins remain unset; delivered production mode additionally compares every already-published sealed original and preserves its view/consumer checks. Resolve reports transition_source_revision, avoiding a copied-current-revision implication, and grants no addition authority. JSON non-integer schema kinds now refuse with no output. A first unique fact identity may be added where none existed; existing identities/questions stay protected and initial transition equality remains exact. Actual independent CLI controls observe accepted products and all relevant planted failures. A selected helper-free copied legacy capsule and ordinary legacy original/read byte comparison pass; bytecode writes are disabled. Real sources and ceiling authority remain unchanged. Reproduced post-transition deletion of 0115 is explicitly owned by immediate .3 before any live catalog is admitted.
- [x] **NO REGRESSION** — Final guarded T2002/T2001/T2000/T1923/T1999/T1560/T1554 reports `All tests successful`, `Files=7, Tests=36`. After the transition-field naming and capsule refinements, guarded T2002/T1923 reports `All tests successful`, `Files=2, Tests=4`. Every public legacy original still compares with its independent Git source, corrupt/stale navigation/schema and borrowed-original controls pass, and existing flat authority/containment remain green. Final Python syntax is OK, ordinary read-original/read 0001 compare byte-for-byte, and book/inventory/Knowledge Map/staged doctrines/hooks accompany the workflow. Re-derivation is actual public CLI byte products and independent source/source-index fingerprints; falsification is literal independent supplied stores, non-integer legacy schemas, borrowed originals, broken requests/data and helper-free captured execution; durability is tracked CLI/helpers/tests, canonical 0108 and this owner. Production fingerprint installation, continuous catalog birth/identity checks, fresh authority and real rollover remain the next owned leaves; no external/native execution signoff is claimed.


## Acceptance — selected-Git store access and continuity `.51.3.2.2.3.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S "require(required <=" -1 --format='%H %s' -- scripts/decision_catalog.py` returns ea6b332fdfe4b7fe9d74b508bd0f144e57915059. Its required set deliberately comes from the immutable transition source. Actual supplied-store reproduction admits fresh 0115, then deletes its row/body/root-part routes: standalone authenticated current validation accepts the restored consistent snapshot. Later births therefore need a prior-current identity floor. Reading a mutable index selector or ambient inventory would also let later state substitute for the selected gate snapshot. These shared prerequisites precede actual authority integration.
- [x] **ADDRESSED (verified)** — GitSnapshot captures a bounded regular mode/object inventory once and resolves revision selectors to exact commits; reads address captured blobs. Actual project-local Git fixtures compare accepted index/revision products, then stage/commit wrong ambient data while captured products remain exact. A real replacement ref changes ordinary Git blob reads but cannot change this accessor; root resolution matches the requested repository, and lazy fetch/optional locks are disabled. Unsafe selectors/paths, missing/directory/symlink/gitlink/conflicting-stage/oversized blobs and streamed-output bounds refuse. No submodule traversal or implementation read occurs. Prior-current comparison preserves the complete independent source/index fingerprints and original products plus all prior current ID/path/type/fact/question keys. The self-consistent post-transition deletion now refuses; equal-count deletion/recycle, changed original authority/products, lost new fact/questions and earlier-gap births refuse. Already-authenticated owned current updates and first fact indexing from null remain possible. The shared checks do not install production pins or authorize new paths; .2 owns unconditional actual integration before real rollout.
- [x] **NO REGRESSION** — Guarded T2003/T2002/T2001/T2000/T1923/T1999/T1560/T1554 reports `All tests successful`, `Files=8, Tests=38`. Final replacement/root refinements re-run T2003/T2002/T2001: `All tests successful`, `Files=3, Tests=6`. Exact old/public/current/original products, primitive schema repairs, navigation/fingerprint/caller controls and existing flat authority/containment remain green. Final Python syntax is OK; book, unchanged-ceiling aggregate authority, Knowledge Map/inventory and staged doctrines/hooks accompany the workflow. Re-derivation is actual selected Git blob/inventory loading plus authenticated prior-current comparison; falsification is independent literal source/index inputs and observed actual replacement/ambient/conflict/deletion/recycle/lost-key controls; durability is tracked helpers/tests, canonical 0108 and this leaf. Production/global enforcement, all selected modes and real source rollover remain .2-.3, not established by these pure prerequisites.

## Acceptance — published selected-reader continuity `.51.3.2.2.3.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'def load_store' -1 --format='%H %s' -- scripts/decision_records.py` returns fa79aba797840932027ba2dbdcb1ecb33ad6569a. Its actual public store caller uses filesystem bytes/inventory and exposes transition-relative identity only; there is no actual prior-store comparison or first-adoption predecessor binding. Independently qualified shared helpers do not enforce those public guarantees. Explicit fixture digests also previously reached the reader's real root without a boundary. The gate needs one atomic selected product rather than separate mutable reads.
- [x] **ADDRESSED (verified)** — Published read/check/resolve operations select captured index or resolved Git revisions, with the qualified regular-blob accessor and exact root inventory throughout; no selected consumer falls back to ambient bytes. Atomic check-continuity authenticates both snapshots, enforces full prior identity retention and returns requested canonical text/bindings with prior-relative freshness. Actual fresh 0115 reports fresh against its predecessor and false after publication. First adoption requires exact predecessor revision/root population/index/originals and transition metadata/routes. Actual current consistency alone accepts post-transition deletion, while the public prior comparison refuses it; removal, wrong predecessor, unknown/duplicate path requests and expanded oversized JSON return no output. Caller fingerprints require an explicit other root and refuse the actual root, including an independently installed-pin capsule. Production pins remain unset; actual Perl integration is separately owned by child .2.
- [x] **NO REGRESSION** — Guarded T2004/T2003/T2002/T2001/T2000/T1923/T1999/T1560/T1554 reports `All tests successful`, `Files=9, Tests=40`. Actual repository --snapshot HEAD check verifies exact originals/view/links/consumers; book builds and final syntax is OK. Existing filesystem requests, no-catalog capsules, original/current byte products, literal catalog/authentication/navigation controls and flat authority/containment remain green. Initial failures were incorrect diagnostic strings/order; the later mistyped-file aggregate was explicitly incomplete and replaced by the enumerated complete run. Re-derivation is actual public CLI against independent same-volume Git snapshots; falsification uses literal expected bodies/routes and planted ambient/prior/identity/removal/authority/request/output expansions; durability is tracked reader/tests, canonical 0108 and this leaf. Broader actual Perl and production rollover qualification remain separately owned. Bounded registry authority, Knowledge Map/inventory and staged doctrines/hooks accompany this workflow.

## Acceptance — actual canonical authority and continuity gate `.51.3.2.2.3.2.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'metadata has unsupported schema_version' -1 --format='%H %s' -- scripts/check_live_document_ceiling_authority.pl` returns 2e10cc605f1dec9259b18d9b9d568c35882105a6. The touched actual gate selects changes only from ceiling/authority registries, admits flat paths only and reads cited body bytes separately; ordinary catalog deletion therefore has no prior identity floor. Red actual-gate T2005 also returns success for JSON true in staged surface schema metadata: string comparison treated the Boolean reference as one. Shared public continuity alone cannot enforce the actual gate or bind its earlier registry reads.
- [x] **ADDRESSED (verified)** — Gate mode selection includes all controlled store/source/reader paths and untracked members. Every selected catalog pair authenticates complete products and prior-current continuity, including ordinary no-increase births. Canonical authority consumes exact public text, prior-relative freshness, predecessor file absence and unfenced exact marker lines. Real independent fixtures pass one fresh authority in working/staged/committed modes; prior/relocated IDs and fenced examples refuse. Optional selected file digests bind the gate's earlier control bytes to the captured inventory: an actual dispatch that changes the Git index registry during reader invocation refuses the mismatch. Selected current commits determine their own exact parent; byte-bounded simultaneous output/diagnostic draining consumes process outcomes. Other-root fixture fingerprints remain explicit; actual-root overrides refuse. Reference-valued schema versions now refuse in both registry headers and authority rows, closing the owned P2 Boolean defect. Historical flat/no-catalog contracts remain. No production catalog/pin, source movement or ceiling increase is installed.
- [x] **NO REGRESSION** — Guarded T2005/T2004/T1560 initially reports `All tests successful`, `Files=3, Tests=12`. Final guarded T2005/T2004/T2003/T2002/T2001/T2000/T1923/T1999/T1560/T1554 reports `All tests successful`, `Files=10, Tests=42`. Book builds; Perl and Python syntax and diff checks pass. Actual ordinary growth, post-birth deletion, removal, source corruption, staged/ambient disagreement, selected control substitution, marker examples and authority/schema override controls complete; old reader capsules, original/current products, catalog/navigation and flat authority/containment stay green. Re-derivation is the actual public/Perl boundary on complete same-volume Git fixtures; falsification is independent literal source/index/registry/body products plus hostile prior/current/dispatch controls; durability is tracked helpers/tests, canonical 0108, policy/book and this leaf. Broader full hostile-mode and production rollout qualification remain sibling .3 and .51.3.2.3. Bounded declarations, Knowledge Map/inventory and staged doctrines/hooks accompany the workflow.

## Acceptance — post-transition identities across selected modes `.51.3.2.2.3.3.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'sub catalog_change_product' -1 --format='%H %s' -- scripts/check_live_document_ceiling_authority.pl` returns c83948125cdd6c84baa3fb13fbca7a4edd180800. The actual integrated gate has initial mode/birth/deletion controls, while pure prior-product comparisons cover fact/question and path/type controls. Neither alone earns complete actual-mode proof for facts first born after the immutable transition source. An internally self-consistent current snapshot can lose those identities/keys while retaining correct digests and routes; qualification must distinguish current authentication from the prior floor before real rollout.
- [x] **ADDRESSED (verified)** — Independently literal fixtures publish a post-transition fact-bearing identity with its questions before each mutation. Complete source/index/original/control baselines remain independent, and every current byte/metadata/root/part product is kept consistent. Actual selected current authentication passes each deletion, equal-count birth replacement, path/type recycle, fact deletion/replacement, question deletion/equal-count substitution and earlier-gap birth. The actual prior-aware Perl gate refuses the intended identity/key violation in every worktree/staged/committed mode, even with no ceiling increase. Owned body/status/summary changes and additive questions retain earlier keys and pass every mode. Each same-volume fixture is cleaned; book and canonical evidence name the separate current/prior legs. Remaining malformed product/authority/caller/IPC qualification is owned by child .2.
- [x] **NO REGRESSION** — Guarded T2006 initially reports `All tests successful`, `Files=1, Tests=2`. Final T2006/T2005/T2004/T2003/T1560 reports `All tests successful`, `Files=5, Tests=16`; book builds and Python syntax/diff checks pass. Complete current products, ordinary owned evolution, public selections, actual authority/control-byte binding and legacy flat authority remain green; predecessor full catalog/reader/containment qualification is committed in c83948125cdd6c84baa3fb13fbca7a4edd180800. Re-derivation is actual standalone current authentication followed by the actual prior-aware Perl gate on independently published fixtures; falsification is literal post-transition fact/question products plus separate self-consistent hostile mode mutations; durability is tracked T2006/Python matrix, canonical 0108, book and this leaf. No production rollout or wider backend/runtime qualification is inferred. Bounded registry authority, Knowledge Map/inventory and staged doctrines/hooks accompany the workflow.
