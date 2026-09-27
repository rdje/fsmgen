# SEMANTIC-INTROSPECTION-MCP-FRONTIER: Semantic Introspection And MCP Frontier

## Metadata

- Tree ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER`
- Status: `active`
- Roadmap lane: `Embedding And Public APIs / AI integration`
- Created: `2026-06-14`
- Last updated: `2026-09-27`
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
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.4, SEMANTIC-INTROSPECTION-MCP-FRONTIER.5, SEMANTIC-INTROSPECTION-MCP-FRONTIER.6, SEMANTIC-INTROSPECTION-MCP-FRONTIER.7, SEMANTIC-INTROSPECTION-MCP-FRONTIER.8, SEMANTIC-INTROSPECTION-MCP-FRONTIER.9, SEMANTIC-INTROSPECTION-MCP-FRONTIER.10, SEMANTIC-INTROSPECTION-MCP-FRONTIER.11, SEMANTIC-INTROSPECTION-MCP-FRONTIER.12, SEMANTIC-INTROSPECTION-MCP-FRONTIER.13, SEMANTIC-INTROSPECTION-MCP-FRONTIER.14, SEMANTIC-INTROSPECTION-MCP-FRONTIER.15, SEMANTIC-INTROSPECTION-MCP-FRONTIER.16, SEMANTIC-INTROSPECTION-MCP-FRONTIER.17, SEMANTIC-INTROSPECTION-MCP-FRONTIER.18, SEMANTIC-INTROSPECTION-MCP-FRONTIER.19, SEMANTIC-INTROSPECTION-MCP-FRONTIER.20, SEMANTIC-INTROSPECTION-MCP-FRONTIER.21, SEMANTIC-INTROSPECTION-MCP-FRONTIER.22, SEMANTIC-INTROSPECTION-MCP-FRONTIER.23, SEMANTIC-INTROSPECTION-MCP-FRONTIER.24, SEMANTIC-INTROSPECTION-MCP-FRONTIER.25, SEMANTIC-INTROSPECTION-MCP-FRONTIER.26, SEMANTIC-INTROSPECTION-MCP-FRONTIER.27, SEMANTIC-INTROSPECTION-MCP-FRONTIER.28, SEMANTIC-INTROSPECTION-MCP-FRONTIER.29, SEMANTIC-INTROSPECTION-MCP-FRONTIER.30, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32, SEMANTIC-INTROSPECTION-MCP-FRONTIER.33, SEMANTIC-INTROSPECTION-MCP-FRONTIER.34, SEMANTIC-INTROSPECTION-MCP-FRONTIER.35, SEMANTIC-INTROSPECTION-MCP-FRONTIER.36, SEMANTIC-INTROSPECTION-MCP-FRONTIER.37, SEMANTIC-INTROSPECTION-MCP-FRONTIER.38, SEMANTIC-INTROSPECTION-MCP-FRONTIER.39, SEMANTIC-INTROSPECTION-MCP-FRONTIER.40, SEMANTIC-INTROSPECTION-MCP-FRONTIER.41, SEMANTIC-INTROSPECTION-MCP-FRONTIER.42, SEMANTIC-INTROSPECTION-MCP-FRONTIER.43, SEMANTIC-INTROSPECTION-MCP-FRONTIER.44, SEMANTIC-INTROSPECTION-MCP-FRONTIER.45, SEMANTIC-INTROSPECTION-MCP-FRONTIER.46, SEMANTIC-INTROSPECTION-MCP-FRONTIER.47, SEMANTIC-INTROSPECTION-MCP-FRONTIER.48, SEMANTIC-INTROSPECTION-MCP-FRONTIER.49, SEMANTIC-INTROSPECTION-MCP-FRONTIER.50, SEMANTIC-INTROSPECTION-MCP-FRONTIER.51, SEMANTIC-INTROSPECTION-MCP-FRONTIER.52`

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
  Status: `pending`
  Goal: `Repair local rule-trigger payload retention at the admitted activation boundary.`
  Acceptance: `After .1 and scoped identities .49.2.2, reproduce the tracked request-gated delayed-zero case and retain both generated-live controls. Preserve early entry visibility and later snapshots with no extra observable activation cycle. Qualify changed sources, repeated requests, reset, busy requests, conditional authored entry and granted multiple rule sources; never remove all source guards to choose an implicit winner. Preserve authored rule-target entry semantics. Close only from generated production runtime and exact native/API/MCP evidence.`
  Verification: `pending`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3`
  Status: `pending`
  Goal: `Establish shared-write admission for independently active direct controllers.`
  Acceptance: `After .1/.2 and .49.2.2, derive physical target ownership from scoped identities and typed effects. Inventory data, completion, binding, named-drive and generated-handoff contributors. Preserve proved fan-in, rule priority and resource grants; refuse unproved overlapping controller writes with actionable diagnostics before runtime promotion. Do not treat shared encoded-state exclusion or parsed transaction priority as a proof. Qualify disjoint targets, equal/pulse compatibility boundaries, guarded conflicts and existing priority behavior; split implementation if needed.`
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
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.38.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.38.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.38.1`
  Status: `pending`
  Goal: `Implement required SPECFORGE storage-register-access R1-R3 for width-based scalar var and variable entries.`
  Acceptance: `Accept exactly the existing lowercase field-access token set on scalar storage words, with or without fields; preserve independent word/field facts without inheritance or consistency constraints. Reject duplicate, malformed, unknown and bank/typed access forms with storage/token diagnostics. Project optional access beside width/fields wherever scalar storage is reported, including applicable domain views and API/MCP schedule projections. Retain original caller controls from the .37 audit; prove unchanged scheduled FSM and date-normalized generated HDL/reset behavior, unchanged baseline/whole-word-field reports, token/alias coverage and default/strict/native/API/newline negative controls. Update book/spec/public contract and support coverage before commit.`
  Verification: `Current parser _parse_storage rejects access; existing _is_actor_storage_field_access defines the accepted vocabulary and field metadata reaches schedule inferred_storage only. Native/API/newline intake preserves both accepted controls and all refusals. Schedule semantic metadata must not be confused with runtime access enforcement. Schedule after the existing watchdog/reachability and .32.2/.32.4 repair lanes, before the generic-width-dependent configuration extensions; no dependency on generic widths.`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.38.2`
  Status: `pending`
  Goal: `Select and implement the optional R4 storage-bank access metadata extension after scalar access is qualified.`
  Acceptance: `Read scalarization/domain/report contracts after .38.1 and choose an unambiguous bank-level access projection without inventing per-field facts or access-policy RTL. Implement the same checked token set only if bank identity and element ownership survive every affected report; otherwise split the required report prerequisite into owned leaves. Prove unchanged generated FSM/HDL, unknown/duplicate/malformed refusal, native/API/newline parity and no implicit reset or access enforcement. Keep scalar metadata and unrelated bank boundaries unchanged; update book/spec and commit separately.`
  Verification: `Caller labels R4 optional; it is retained as scheduled work after .38.1 rather than silently dropped. Until its qualified implementation, access on bank remains refused.`
  Commit: `pending`

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
  Status: `active`
  Goal: `Lower direct transaction ports to collision-safe private identities.`
  Acceptance: `After .49.2.1, controller contract .32.1.3.3.1.2.2 and shadow ownership .32.1.3.3.1.3.1, implement scope-aware operand and binding resolution before .32.1.3.3.1.3.2. Preserve actor owner metadata, local aliases and resets, caller versus callee names, source provenance and public reports. Qualify direct input/output and rule payloads independently, including same names in different transactions and user names resembling generated prefixes. No global textual substitution or actor-role overwrite is permitted.`
  Verification: `pending`
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
  Status: `pending`
  Goal: `Integrate scoped formal lowering and preserve public source identities.`
  Acceptance: `After .1/.2/.5/.6, connect declaration maps, width/type/reset/role propagation, caller-local binding validation, local call endpoints and rule payload destinations. Allocate against actual actor/generated/private declarations, preserve generated child public ports and authored binding report names, and reject any unresolved physical collision. Qualify actor/local, sibling/caller/callee, input/output and generated-prefix cases through strict artifacts and complete native/API/MCP reports; keep runtime limits explicit until .49.2.3. Update book/spec/facts and commit before payload repair .32.1.3.3.1.3.2.`
  Verification: `pending`
  Commit: `pending`

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
  Status: `pending`
  Goal: `Repair stale runtime-wait lowering examples in the book.`
  Acceptance: `After .5 and before .3, census the runtime-wait examples in 13h against generated current carriers and the canonical count-predicate facts. Replace stale low-bit positive-entry guards with actual nonzero predicates; check pending/consecutive waits, joins, branches, repeat/switch/loop and exit/continue predecessors for related drift. Preserve explanatory intent while making generated examples accurate. Retain reproducible source/fragment evidence, run book-example checks/build and commit.`
  Verification: `13h still shows main_wait_1 counter load/entry guards as (& start cycles), while the committed production fix uses (& start (!= cycles 0)). At start=1/cycles=2 the old expression is false and the current one true. Similar stale guards occur in consecutive and expression wait examples. Canonical isf-dynamic-wait-count-predicates and T1909 own the runtime proof; this leaf owns the missed book synchronization.`
  Commit: `pending`

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
  Status: `pending`
  Goal: `Contain decision identity and index cardinality before file-count rollover.`
  Acceptance: `Activate before an added record would enter the rationale file-count rollover band. Audit stable external and generated provenance identities, select bounded identity/index partitions with exact retrieval, preserve all policy authority and record links, qualify negative navigation controls and commit without widening the file ceiling. This future warning-pressure task does not block controller contract adoption after .51.2.`
  Verification: `Root aliases deliberately preserve file cardinality. The .51.2 line/byte rollover leaves explicit warning_debt rather than claiming every pressure dimension is normal.`
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
  Status: `pending`
  Goal: `Preserve quoted division operators in public diagnostic sanitization.`
  Acceptance: `Immediately after .49.2.2.5 and before the wait-book repair .6, reproduce native/API diagnostic divergence for an unsupported carrier expression whose supported-operator hint contains quoted /. Repair contextual sanitization without exposing real absolute/quoted/URI/Windows paths. Qualify direct native/API/newline errors, bare/quoted HDL operators, genuine path redaction and repository-local paths; update book/facts and commit.`
  Verification: `T1929 before.log reproduces native diagnostics containing the quoted division token while API diagnostics replace it with [absolute-path-redacted]. _sanitize_public_string treats the quoted standalone slash as an absolute path, despite its comment promising HDL division preservation. The error is observable through check and semantic queries on the retained wait_not source at baseline 07f475f815630317383388f4da17a05cb8cb944d. Use a direct unsupported carrier-expression source after .5 moves the wait error earlier; do not classify the disappearance from that wait probe as a sanitizer fix.`
  Commit: `pending`

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

## Current Frontier

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.9` is complete: declared output
interfaces survive ordinary/domain lowering without invented drive values.
`.35` is complete: explicitly reset outputs without data writers reset and
hold; native/API/MCP drive families match the qualified hardware behavior.
Port-option validation and startup cleanup are complete.
Completed `.39.1` provides direct internal roles and reset/hold behavior.
Completed `.39.2.1` preserves ordinary/domain ISF storage and qualifies the
retained CSR baseline. Completed `.39.2.2.1` retains generated-child storage evidence and decision
0107. Completed `.39.2.2.2.1` routes live scalar/bank reads for ordinary and
single-domain children and refuses unqualified aggregate/domain reads and writes.
Completed `.40` repairs single-member type normalization; `.41` aligns residual
reset wording. Completed `.39.2.2.2.2.1` scopes aggregate typedefs by module.
Completed `.42` shares verified repeated-source module definitions; `.43`
retains child completion across joins and activations. Completed `.44` fixes
even runtime wait counts. Completed `.45` qualifies typed VHDL comparisons
and scalar wait timing. Completed `.39.2.2.2.2.2` qualifies
aggregate live reads. Completed `.39.2.2.2.3.1` realizes domain transaction
children and prevents held-start reexecution. Completed `.46` preserves named
child completion and excludes delayed events from inferred datapath sharing.
Completed `.47` restores library parent interfaces and qualifies default-domain
FIFO ownership/readbacks. Completed `.48` qualifies selected-domain library
system bindings and empty-domain artifacts. Completed `.39.2.2.2.3.2` qualifies
domain live storage reads and generated-do inherited-input wiring. Completed
`.39.2.2.3.1` qualifies sole full-width scalar writer handoffs in ordinary/single-domain actors.
Completed `.39.2.2.3.2` qualifies independent-domain scalar writer handoffs.
Completed `.39.2.2.4.1` splits broader writer contracts and repairs stale actor-storage
documentation. Completed `.39.2.2.4.2` qualifies whole-aggregate writers and repairs
declared-root domain validation. Completed `.49.1` isolates generated-child ports
and retains trigger payloads after start pulses. Completed `.49.2.1` audits direct
port scope and its controller prerequisite. Completed `.32.1.3.3.1.1` repairs
terminal synchronization. `.32.1.3.3.1.2.1` retains direct-controller failures and
passing public-carrier references. Next `.51` rolls over the saturated rationale
collection, then `.32.1.3.3.1.2.2` adopts the contract and `.1.3` implements it.
Then `.49.2.2/.3` repair direct identities and qualify local calls, `.49.3`
qualifies explicit locals and `.50` investigates the retained MCP response gap.
Partial writers and remaining writer leaves follow under `.39.2.2.4.3` onward,
then watchdog rearming `.32.1.3.3.3` and broad behavior/API/MCP signoff `.32.1.3.3.2`.
Naming, explicit routes and declared inputs are qualified; `.32.1.3.4` is done.
Bundle provenance and executable interconnect lowering follow under `.32.2`
and `.32.4`. Required scalar access metadata and optional banks are owned by
`.38.1` and `.38.2` after completed packet intake `.37`. Then implement actor
checks, knownness and phase metadata before
the generic-width foundation, derived widths, legal sets and optional ports
in dependency order; exact leaves are under `.33` and `.32.3`.
Full-source API coverage and historical native qualification remain open.
Preserve spent compiler/startup evidence; source checks do not promote runtime
support. The remaining feature extensions are not implemented by the port-option repair.

## Decisions

- `2026-09-24`: The director requires deep semantic API and MCP coverage for
  current and future features wherever applicable, maximizing useful external
  AI/LLM access. Activate `.31` after the prior native-release slice is committed
  and clean. Audit and repair this coverage before the next stream slice; retain
  the completed read-only profile and separate proposed write-horizon boundary.

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

## Acceptance Checklist — `.31.1` coverage audit

- [x] **ROOT CAUSE (WHY + WHERE)** — Native `--emit-semantic-json` results and
  `--debug=3` trace capture identify duplicate `lhs_enable:penable_0_en`
  contexts and replacement in `FactorizationSupport::_build_context_to_ast_map`.
  The tracked audit projection preserves those trace lines and the actual
  native/MCP discovery, VIAL and negative-diagnostic disagreements.
- [x] **ADDRESSED (verified)** — This audit owns each demonstrated defect in
  exact repair leaves, selects compiler identity first, and corrects current
  coverage claims in the book and fact card. No implementation repair or full
  coverage is claimed by the audit; the old profile chronology remains
  recoverable at the exact predecessor named in the fact card.
- [x] **NO REGRESSION** — `knowledge-map: OK`; task-tree integrity passes;
  `mdbook build docs/book -d .artifacts/mcp-feature-audit-book` succeeds and the
  rendered embedding chapter contains the coverage limits. Staged doctrines
  remain required before this commit.

## Acceptance Checklist — `.31.2.1` generated enable identity

- [x] **ROOT CAUSE (WHY + WHERE)** — The audit `--emit-semantic-json` and
  `--debug=3` trace proves duplicate generated names replace original driver
  conditions in the factorization context map. AssignmentSupport's old
  per-LHS tracking missed case/punctuation, DT-local and cross-family
  collisions. T1866 fails against the exact predecessor on original driver
  identity, namespace uniqueness and occupied-name preservation.
- [x] **ADDRESSED (verified)** — One build-local registry reserves authored
  module signals, effective system ports, parameters and top-level enables, then
  allocates both assignment-enable
  families in sorted original-identity order with occupied-suffix probing.
  Rebuilds are stable. The [repair receipt](../audits/mcp-feature-coverage-20260924/enable-identity-repair.json)
  retains the baseline and isolated incomplete-repair failure oracles, positive
  control, source/test hashes and actual CLI/MCP report hashes. Native and MCP
  reports for the unchanged APB source agree across recorded process seeds
  after only the documented resolved-source-path normalization.
  Independent generated-HDL simulation passes separate upper/lower writes,
  reset, both writes and holding; the original compiler instead changes both
  outputs on an upper-only write. Tracked FSM/testbench fixtures preserve this
  oracle. No APB sample edit is included; `.31.2.5` owns its separate defect.
- [x] **NO REGRESSION** — `All tests successful. Files=27, Tests=573` in the
  selected enable/factorization/structural IR/MCP band. The final band includes
  T1866/T1405/T205 and system-port/parameter controls; syntax and mdBook HTML pass.
  Full CI remains gated by its separate startup/parent qualification owner.
  Staged doctrine and normal hook checks remain required before commit.

Claim legs: re-derivation uses actual compiler/API reports and the selected
suite; falsification uses the exact baseline, isolated omitted/reversed
allocation controls and an independent HDL simulator; durability uses the
tracked repair receipt, test/fixture files and this work-unit commit. Scope is
assignment-enable identity and the recorded source queries, not universal
identifier safety or complete feature coverage. The first control harness
incorrectly let prove's include path select the current module; that result
was rejected and retained locally. The final harness explicitly preloads the
selected module and its canonical INC entry before the test. An unused-width
fixture was corrected to reference actual reserved signals; the standalone
simulation fixture was corrected to canonical strict syntax before comparison.

Final namespace inspection found an additional concrete reserved-name gap:
`--strict --output` for an authored `(clock out_1_en)` declares that clock
input and also emits `assign out_1_en = idle_out_1_en`. Module `signals`
does not contain every system port or parameter. The completed `.31.2.1`
repair also reserves effective system clock/reset ports and module parameters.
T1866 now covers this source boundary, and isolated missing-system/parameter
controls fail. The final selected band and CLI/MCP comparison were repeated
after that correction; the receipt supersedes intermediate qualification.

## Acceptance Checklist — `.31.2.5` APB completion and interface

- [x] **ROOT CAUSE (WHY + WHERE)** — `--emit-semantic-json` exposes unused
  helper start/value inputs beyond the authored interface; native scheduled
  `-done_phase` writes lowercase `psel`/`penable` rather than public outputs.
  Drive bodies are assignments, not nested calls. T1867 fails on the original
  source's completion writes, generated interface and driver provenance.
- [x] **ADDRESSED (verified)** — `done_phase` directly clears `PSEL`/`PENABLE`
  and unused helper definitions are removed without changing transaction state
  order or response-sampling timing. The schedule now truthfully exposes setup
  and completion as compatible PENABLE-zero sources; updated report oracles
  preserve both. T1867 and actual native/MCP semantic equality verify the
  corrected ports and original driver provenance. Assertion-enabled Verilator
  checks waits, separate write/read requests, data/error capture, bus clearing
  and completion pulse/idle behavior. The exact original source fails the
  same completion oracle with only its obsolete extra controls tied low.
- [x] **NO REGRESSION** — `All tests successful. Files=17, Tests=7156` in the
  selected ISF public-interface/CLI, schedule, corpus-accounting and independent
  compiler identity band. The drive-body chapter and embedding limits build
  and pass rendered HTML checks. Full CI remains separately gated; staged
  doctrines and normal commit hooks remain required before this commit.

Re-derivation and durability: the [tracked repair receipt](../audits/mcp-feature-coverage-20260924/apb-completion-repair.json)
retains source/test identities, actual native/MCP queries, strict support,
original/repaired behavior outputs and test summaries; the testbench is tracked.
Falsification: the exact original source fails the transfer oracle and the
source/IR test. The initial broader run found old DT/helper-storage and fan-in
expectations; they were corrected against the changed source, including an
explicit new PENABLE fan-in assertion, then the full selected band passed.

The noisy Icarus run is excluded, even though it printed the testbench PASS.
A standalone [public HDL probe](../audits/mcp-feature-coverage-20260924/onehot-probe.sv)
reproduces the installed tool's concatenation/packed-vector `$onehot0`
disagreement without FSMGen. `.31.2.6` owns qualification/disposition; no
upstream implementation was inspected or changed. Missing leg: this bounded
simulation is not full protocol certification, and latest-feature MCP coverage
remains open under the remaining `.31` leaves.

## Simulator Qualification Boundary — `.31.2.6`

Preserve the basic truth-table control, output-context probe and independent
checker under `docs/audits/mcp-feature-coverage-20260924/`. Qualify the
output-context probe through installed simulators' public command interfaces,
including intentionally wrong oracle controls. Preserve bounded output/version/command evidence, document the exact
Icarus SystemVerilog limitation and the verified Verilator path, and keep
native Verilog coverage distinct. A focused repository search found executable
Icarus usage in T1542 only, where `-g2005` compiles native Verilog and an
explicit oracle forbids `$onehot0`/SystemVerilog assertions. Other current
source hits are tool-name exclusion or CI package-availability checks.
Do not replay historical compiler fixture producers or change dependency
implementations/pins; public standalone builds are fresh repository-local work.
This leaf qualifies the integration boundary, not an upstream source repair.

The first basic truth-table and small assertion probes pass under Icarus, so
those results cannot qualify the failing context. The original display-context
probe repeatedly reports concat=0 versus packed/literal=1 for input 01.
In the full APB assertion context, an instrumented failure reports both
PENABLE-zero selector inputs as 0 with pairwise conflict=0. Keeping only that
assertion passes; selected paired contexts fail. Pairwise replacement also
exposes delta-cycle observations, so do not conflate isolated truth-table
success, tool expression-context behavior and stable-cycle HDL qualification.
Keep generic compiler conflict checks unchanged. Retain a finite output-context
probe and an independent expected-value checker, plus the passing basic probe
as a bounded control. Qualify the identical output-context probe under
Verilator, document exact observed scope, and preserve upstream-owned evidence.

## Acceptance Checklist — `.31.2.6` simulator qualification

- [x] **ROOT CAUSE (WHY + WHERE)** — The rejected APB run prints
  `ERROR: .artifacts/mcp-feature-coverage/apb-fixed.sv:720` despite its final
  PASS. Public standalone HDL reproduces context-specific concat/vector
  disagreement in Icarus; the basic control passes. Instrumented APB inputs
  are both zero at one rejected selector, and paired assertions alter the
  outcome. This locates a tool-context qualification defect without claiming
  universal intrinsic failure or inspecting upstream implementation.
- [x] **ADDRESSED (verified)** — The tracked output-context probe and
  `check_onehot_probe.py` require the explicit finite Boolean truth table.
  Actual Verilator output passes; actual Icarus output fails. Wrong truth,
  missing/duplicate rows, malformed input and simulator-error controls all
  fail. The book documents the exact supported evidence and native Verilog
  distinction. Compiler-owned changes: none; assertions remain intact.
- [x] **NO REGRESSION** — `knowledge-map: OK`; mdBook build and rendered
  runtime-qualification examples pass. The preceding APB assertion-enabled
  Verilator result remains valid, as recorded in its committed receipt.
  Staged doctrines and normal commit hooks are required before this commit.

Re-derivation uses actual simulator outputs and an independent expected-value
checker; falsification uses actual failing Icarus output and corrupted checker
inputs; durability is the [qualification receipt](../audits/mcp-feature-coverage-20260924/onehot-qualification.json),
tracked probes/checker and this commit. The basic control's captured original
path predates its move into the audit directory; receipt metadata names both.
Missing leg: no upstream source repair or general simulator, four-state or
scheduling certification is claimed. The APB original-source failure remains
separately preserved in the `.31.2.5` receipt. Resume adapter diagnostics.

## Failure Diagnostics Implementation Boundary — `.31.2.2`

The native check and normalized-semantic producers each already emit a typed,
versioned failure object with JSON `success: false`, original diagnostics and
support metadata, then exit unsuccessfully. Schedule failures lack a selected
structured failure contract. Decode captured stdout first, accepting nonzero
execution only for the matching public failure identity/shape; never accept an
arbitrary JSON scalar, unrelated object, success report or wrong-query report
as an expected refusal. Preserve the existing injected decoded-report runner.
Tool results retain text and structured report content and signal source
failure with `isError: true`; resource reads retain the same report envelope.
Transport errors remain code/message-only. Sanitize embedded root/path tokens
in report strings and errors, omit raw command/stderr/decoder excerpts from
execution failures, and bound public error messages. Check actual native/MCP
check and semantic failures, unsupported/non-JSON/success-on-failure controls,
workspace rejection before execution, preserved ordinary semantics/relative
paths and embedded external paths. T1868 owns this public boundary regression.

## Acceptance Checklist — `.31.2.2` source failure diagnostics

- [x] **ROOT CAUSE (WHY + WHERE)** — Actual strict `--check --json` and
  `--emit-semantic-json` refusals emit typed diagnostic reports with exit 1.
  The adapter discarded stdout before decoding on unsuccessful execution;
  its whole-string path sanitizer missed quoted paths inside diagnostic prose.
  T1868 rejects the exact predecessor on report delivery, tool failure flags,
  embedded paths and error boundaries, as captured in the repair receipt.
- [x] **ADDRESSED (verified)** — Matching check/normalized-semantic v1 failure
  identities survive failed execution and retain native diagnostic/support
  truth. Tool results use `isError: true` with identical text/structured
  content; resources return the same source envelope. Wrong-query, unrelated,
  malformed and success-on-failed-exit controls remain adapter errors.
  Public errors omit raw execution/decoder excerpts and bound messages;
  report/error paths become relative or redacted. Actual one-shot CLI check
  and semantic failure reports equal independent native projections after
  only known-root normalization. Safety-policy metadata and book examples
  advertise the same boundary; output envelope schemas remain compatible.
- [x] **NO REGRESSION** — `All tests successful. Files=15, Tests=43` in the
  selected actual-source, contract roundtrip, MCP protocol/CLI/schema/stdio,
  root-authority and output band. Complete successful check/semantic reports
  retain their contents. Syntax, Knowledge Map and mdBook/HTML checks pass;
  staged doctrines and normal commit hooks remain required before commit.

Claim legs: re-derivation uses actual native and MCP CLI/API calls and the
selected suite; falsification uses the exact predecessor and isolated omitted
failure decoding, report recognition, tool error flag, embedded-path and
public-error controls; durability is T1868 plus the [repair receipt](../audits/mcp-feature-coverage-20260924/mcp-failure-repair.json)
and this work-unit commit. No arbitrary native-tool JSON, schedule failure
schema, all-feature coverage or execution/mutation capability is claimed.
The official supported protocol's [tool error contract](https://modelcontextprotocol.io/specification/2025-06-18/server/tools#error-handling)
was checked before selecting the source-failure result flag.

The first complete successful-report comparison caught an overbroad sanitizer
redacting an HDL `//` comment. Narrowing path-token matching preserves that
report and slash expressions/URIs. The first broader command also named a
nonexistent test path; the final explicit band corrects it. The first mutation
harness set FindBin from its `-e` launcher, so its positive control failed
before qualification; that result was rejected. The final harness explicitly
sets the test directory, preloads the selected adapter and fixes its canonical
INC entry; its positive control passes and every incomplete repair fails.

## Protocol Alias Discovery Boundary — `.31.2.3`

Expose a fresh public `source_query_kinds` map through the semantic-introspection
contract and manifest section, with one exported native accessor. The adapter
must consume that map for catalog recognition and query applicability instead
of its separate fsm/isf/ppif suffix regex. Alias families share the current
PPIF check/semantic/schedule contract; source support/classification remains
catalog-derived, so query availability is not a promise of source success.
VIAL remains explicitly outside this leaf's implemented routing and is owned
by `.31.2.4`. T1869 will compare map membership with native shipped suffixes
minus that explicit VIAL boundary, compare every alias catalog entry with
filtered discovery, verify public defensive rebuilding and exclusion/filter
controls, and exercise actual native/MCP check, semantic and schedule queries
for each shipped alias. Update schedule/tool descriptions and user examples;
keep traversal, hidden/absolute paths and unsupported suffixes excluded.

## Acceptance Checklist — `.31.2.3` protocol-alias discovery

- [x] **ROOT CAUSE (WHY + WHERE)** — Native `--emit-semantic-json` and
  actual MCP queries already accept the shipped protocol aliases, but the
  adapter's separate suffix regex silently excludes their catalog entries.
  T1869's baseline fails applicability, full alias discovery and filtered
  public-alias discovery while its real native/MCP query-parity subtest passes.
- [x] **ADDRESSED (verified)** — The exported native
  `semantic_introspection_source_query_kinds()` owns the fresh applicability
  map in both contract and manifest section; adapter catalog recognition and
  advertised query kinds consume it. Every captured alias catalog record
  retains source/support identity and order through actual MCP CLI discovery.
  T1869 compares the complete representative alias check/semantic/schedule
  reports with native output after only known-root normalization. The public
  schema snapshot gains exactly the additive applicability key, and the book
  documents accessor/discovery/preview examples and support nonclaims.
- [x] **NO REGRESSION** — `All tests successful. Files=11, Tests=40` across
  the alias and source-failure regressions plus native semantic contracts,
  roundtrip/rebuild, MCP API/CLI/protocol/support/schema and structured output.
  Hidden, absolute, escaping and unknown-suffix catalog paths remain excluded;
  limits, source/support filters and defensive rebuilding pass. Knowledge Map,
  mdBook build/HTML and staged doctrine checks are required before commit.

Re-derivation: current native catalog plus actual MCP CLI discovery and actual
native/MCP representative source queries. Falsification: the unchanged adapter
fails discovery/applicability while query parity already passes; independent
native suffix/catalog comparisons reject omission, and path/filter/mutation
controls preserve the boundary. Durability: T1869, the [captured discovery receipt](../audits/mcp-feature-coverage-20260924/mcp-alias-repair.json),
public contract and this commit. Captured counts are not permanent feature
limits. Missing leg: VIAL exposure remains `.31.2.4`, and complete per-feature
coverage remains `.31.3`. The first broader suite correctly detected the new
public manifest key absent from the old bounded snapshot; its exact additive
fixture update was reviewed before the final successful band.

## VIAL Source Loading Finding — `.31.2.4.1`

While selecting latest-feature MCP exposure, inspection found that the native
VIAL filesystem CLI reads complete files and accumulates imports before its
public in-memory producer enforces semantic limits. The source reader uses
`local $/; my $text = <$fh>`, and import traversal has no pre-read byte/count
budget. This is owned repair work, not an assertion of an observed host OOM.
Before granting external-agent source access, establish bounded filesystem
loading and a clean report-returning facade reusable by CLI/MCP. Preserve the
existing public v1/v2 result/diagnostic identities and root-relative imported
source catalog. Do not duplicate private parser semantics or expose plan/run
by reusing an unconstrained CLI argument surface. This finding was surfaced
to the director; implementation can proceed within the authorized coverage
and defect-repair scope.

### Selected Filesystem Source API — `.31.2.4.1`

Add exported `FSM::VIAL::Tool::check_vial_source_file({ workspace_root,
source_id, language_version?, source_style? })`. Required root/source are
scalar; optional version defaults to 1 and accepts only 1/2, style defaults to
`auto` and accepts auto/normal/terse. Return the existing complete versioned
public tool result for action check, including structured invocation/host/limit
failures; never print or publish artifacts. Keep the portable text API intact.
The public wrapper delegates filesystem adaptation to ToolCLI, whose check
command then shares this path. Other CLI VIAL actions reuse the bounded source
reader/catalog loader without widening their action authority.

Use public source/combined/import limits at filesystem admission. Bound each
VIAL file read before parsing and reject over-limit growth; count root bytes
once and distinct loaded imports separately, leaving the parser's edge-count,
cycle and semantic checks authoritative. Rooted relative path, non-symlink and
same-volume checks remain mandatory. Source-loader limit failures use the
existing VIAL_LIMIT_ERROR family through the selected public result version;
missing/invalid imports must still reach their original parser diagnostic
unless admission itself fails. No new HIAL or JSON file-size promise is made
by this VIAL-only source-loading repair. T1870 owns valid native/API parity,
v1/v2/imported/invalid sources, exact/excess source/catalog bounds, invocation
and path rejection, and no-output/no-artifact evidence.

## Acceptance Checklist — `.31.2.4.1` filesystem VIAL checks

- [x] **ROOT CAUSE (WHY + WHERE)** — The bounded tracked
  `docs/audits/mcp-feature-coverage-20260924/probe_vial_loading.pl` observed
  `_read_repo_source` delivering source-limit-plus-one bytes before native
  validation returned `VIAL_LIMIT_ERROR`. Initial T1870 reported
  `#   at t/1870-vial-filesystem-source-query.t line 85.` for returned over-limit
  text, and rejected unbounded imported-file/combined admission. The source
  slurp and import queue, not parser limits, owned the defect. No OOM was observed.
- [x] **ADDRESSED (verified)** — The same probe now returns no source text
  and a loader limit diagnostic. The public `check_vial_source_file` facade
  and CLI check share bounded loading, closed version/style arguments and
  complete public results. T1870 verifies exact/excess file and stream bounds,
  v1/v2 CLI parity, imported portable-result parity, source hashes/independent
  file sizes, structured refusals and unchanged inputs. Empty files now reach
  the portable parser diagnostic. A separate introspection contract preserves
  the frozen v1 capability bytes; the first attempted metadata extension was
  rejected by T1806 and removed. Initial test assumptions about nonexistent
  byte-length/kind fields were rejected and corrected to file sizes/hashes and
  the actual diagnostic phase.
- [x] **NO REGRESSION** — The RAM-guarded selected band ran T1870, T1555,
  T1556, T1801, T1806, T1438, T1439, T1440 and T1445: `All tests successful`,
  `Files=9, Tests=40`, `Result: PASS`. Final expanded T1870 independently passes
  `Files=1, Tests=6` with invocation-shape and v2-limit controls. The book's
  filesystem API example executes successfully and mdBook builds. Rendered
  HTML is checked; browser visual qualification remains explicitly unavailable.

Evidence legs and exact input identities are retained in
`docs/audits/mcp-feature-coverage-20260924/vial-filesystem-repair.json`.
The tracked probe re-derives admission, initial baseline failures and final
independent boundary controls falsify the unbounded/stat-only alternatives,
and T1870 plus T1806 watch the public behavior and frozen capability boundary.
MCP routing/version discovery remains `.31.2.4.2`; complete current-feature
coverage remains `.31.3`. HIAL/JSON input-size limits are not claimed here.

## Selected MCP VIAL Projection — `.31.2.4.2`

Route `.vial` check/semantic calls through the qualified public filesystem
facade and keep the complete native tool result under the existing MCP
`report` envelope. Both query kinds perform native action check; neither
plans or runs. Optional tool `language_version` accepts only 1/2, defaults
to 1 for VIAL, and is rejected for hardware queries. Keep scheduling
inapplicable to VIAL. Validate source-query arguments before invoking a
producer; preserve the existing source_path/source_id aliases.

Preserve existing unversioned resources and add explicit VIAL resources:
`fsmgen://vial/{language_version}/capabilities`,
`fsmgen://vial/{language_version}/source/{source_id}/check`, and
`fsmgen://vial/{language_version}/source/{source_id}/semantic`. Publish their
query domains and schemas through the native introspection contract. Expose
complete public capability records through capability-query sections
`vial_tooling_v1`/`vial_tooling_v2` using their public accessors, without
modifying either record. Discovery advertises VIAL check/semantic support;
version is caller-selected, never guessed from a filename.

Keep original relative VIAL path components when delegating to the filesystem
API: the hardware resolver canonicalizes symlinks and must not erase the
VIAL facade's non-symlink boundary. Absolute in-root aliases may be converted
lexically to relative paths; the public API still owns source/import admission.
Reject versioned resources naming non-VIAL sources. Retain full public
structured source failures with MCP isError, distinct from invalid request
errors. T1871 will qualify actual v1/v2/lifecycle/imported/invalid results,
versioned resources, capability parity, discovery, schema and path controls
and absence of hardware runner invocation or artifact publication.

## Acceptance Checklist — `.31.2.4.2` VIAL MCP projection

- [x] **ROOT CAUSE (WHY + WHERE)** — Initial T1871 rejected all source,
  capability/discovery and selector subtests. Its captured output reports
  `#   at t/1871-semantic-introspection-mcp-vial.t line 61.` for absent versioned
  capability access; source calls reach the hardware runner rather than the
  existing VIAL producer. The adapter source dispatcher, capability sections,
  URI mappings and public applicability map omit the VIAL contracts.
- [x] **ADDRESSED (verified)** — The same test now compares complete actual
  native v1/v2/lifecycle results with tools and versioned resources. Imported
  API results, original semantic paths, structured source failures and isError
  survive unchanged; both versioned capability accessors and catalog discovery
  are exposed. Original path components preserve the filesystem API's symlink
  boundary. Invalid versions, hardware selectors, VIAL scheduling and action
  expansion fail before a producer. Additional controls cover encoded URIs,
  default-v1 refusal of a v2 filename, symlink directories/imports, workspace
  escape, source size admission and no publication.
- [x] **NO REGRESSION** — RAM-guarded T1871, T1870, T1869, T1868, T1438,
  T1439, T1440, T1441, T1443, T1444, T1445, T1447, T1455 and T1806 report
  `All tests successful`, `Files=14, Tests=55`, `Result: PASS`. The final
  expanded T1871 and minimal schema snapshot also pass: `Files=2, Tests=6`.
  New book commands execute through the actual CLI; the guide builds and its
  rendered HTML anchor/examples exist. Browser visual access remains unavailable.

`docs/audits/mcp-feature-coverage-20260924/vial-mcp-repair.json` binds the
actual native CLI/newline-stdio comparisons and book commands to their inputs.
T1871 re-derives full report and capability equality; baseline failures and
negative inputs falsify missing routing, version guessing and authority
widening. Tracked fixtures/tests, book examples and the reviewed schema
additions retain the contract; T1869 now guards every shipped suffix and
T1806 retains byte-exact v1 capability evidence. The first broader invocation
used a nonexistent T1868 filename and was rejected; only the corrected band
counts. Full current-feature qualification and future signoff remain `.31.3`.

## Current-Feature Coverage Selection — `.31.3.1`

The native corpus has broad family labels that are too coarse to establish
feature completeness. The immutable
`docs/audits/mcp-feature-coverage-20260924/feature-coverage-selection.json`
therefore retains every selected source, catalog identity and coverage bucket,
plus its public applicable query kinds and explicit VIAL version. The capture
boundary is the recorded base revision and catalog digest, not a current-state
shadow or a count of independent product features.

Select all supported-smoke source contracts, deduplicate execution by source
while retaining each contract ID, and use native strict check/semantic plus
schedule where advertised. VIAL check/semantic use the documented explicit
source/version map. All current supported hardware entries are strict-backed
and require no additional source search roots. Unknown future suffixes or
unmapped VIAL sources must fail the guard rather than disappear. Source
selection may narrow ordinary focused checks only when the returned scope is
explicit; final qualification uses the complete derived population.

The selected scope is catalog-wide transport parity plus independent named
feature observations. It is not a claim that identical producers prove all
source semantics correct. Native feature tests remain their semantic oracles.
The existing ISF storage and passive-observation records explicitly place their
metadata on schedule JSON, not the normalized lowered machine; respecting
that adjudication avoids a false new defect and a false coverage claim.
Keep backend/runtime/private workflow capabilities discoverable without
promoting them to MCP execution tools or replaying spent native producers.

The tracked `docs/audits/mcp-feature-coverage-20260924/feature_pilot.py` ran
actual native and newline-stdio MCP semantic queries for width expressions,
concatenation, computed selectors, standalone-DT composition, ISF storage,
ISF observations and the complex AXI multi-group queue-head burst-length
runtime-assertion fixture. Applicable ISF/AXI schedule queries also matched.
Full reports agree after independent repository-prefix normalization; the
ISF schedule reports additionally preserve the fixture-authored field and
observation identities. All selected queries passed; no new concrete defect
was established by this pilot. The recorded cohort is not yet exhaustively
qualified: `.31.3.2` owns the durable guard and `.31.3.3` its complete run.

## Acceptance Checklist — `.31.3.1` coverage selection

- [x] **ROOT CAUSE (WHY + WHERE)** — Native `--emit-semantic-json` describes
  lowered `.isf` hardware; the canonical storage/observation fact cards and
  actual `--emit-schedule-json` queries locate source-only field/observation
  metadata. Suffix presence and broad corpus family labels cannot establish
  latest-feature detail coverage. The corpus and public applicability census
  select exact sources and query surfaces rather than repeating that blind spot.
- [x] **ADDRESSED (verified)** — The tracked census selects the complete
  supported source/query cohort and explicit VIAL versions. Actual pilot
  reports match across native/MCP, and independent authored storage-field
  and observation names are present on their canonical schedule surface.
  Selection, exclusions, source identities and pending qualification are durable.
- [x] **NO REGRESSION** — The tracked pilot parses with Python `compile`
  without writing bytecode; every selected executed query reports PASS.
  The RAM-guarded native contract and MCP snapshot checks report
  `All tests successful`, `Files=2, Tests=6`, `Result: PASS`. The mdBook
  builds and rendered report-selection guidance is present. No compiler or
  adapter behavior is changed by this selection slice.

## Additive VIAL inspection selection — `.31.3.2.3.1`

Independent feature assertions for the coverage guard exposed a depth gap, not
an MCP transport defect. `probe_vial_summary.py` compares actual native check
and newline MCP reports, asserts the exact family summary keys, and separately
reads authored lifecycle deadlines, service target, seed and reset values.
Its tracked `vial-summary-boundary.json` records the successful comparison and
missing detail. The existing v1 contract deliberately excludes bodies; v2
inherits that base boundary and adds only family identity/revision/count.
T1808 independently confirms the typed compiler retains conditions and nodes.

Decision `0105` and `docs/VIAL_SOURCE_INSPECTION_CONTRACT.md` select explicit
public typed records behind independent portable/filesystem APIs, native CLI
and MCP. Existing summaries and frozen capability records remain unchanged.
`.31.3.2.3.2` owns implementation, then `.3.3` owns MCP; the guard and exhaustive
qualification remain open. The book now states the actual summary limitation
and labels the new route selected/unshipped. This is not feature closure.

The knowledge card replaces historical routing prose with the current boundary;
no fact-card allowance increases. The task, focused-contract and decision
surfaces admit only their measured task-owned growth within existing ceilings;
their debt states remain unchanged. The book aggregate change records only the
corrected public scope. Browser visual inspection remains unavailable; the
mdBook build and rendered HTML boundary statements pass.

## Acceptance Checklist — `.31.3.2.3.1` inspection selection

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'selected bounded summary fields' --format='%h %s' -- docs/VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md`
  returns `08f59167b HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.2: select spanned VIAL semantic contract`.
  `SemanticReport::_package_summary`, `_named_summaries` and `_fixture_summary`
  implement that deliberate omission. The actual public probe returns
  `VIAL summary boundary and complete native/MCP equality: PASS`; its direct
  source assertions falsify the assumption that equality implies detail.
- [x] **ADDRESSED (verified)** — The owned selection adds a distinct typed
  inspection schema/API plan and concrete implementation/MCP children without
  widening frozen reports. `mdbook build docs/book -d .artifacts/vial-inspection-selection-book`
  succeeds; rendered HTML assertions return
  `Rendered HTML VIAL depth and selected/unshipped statements: PASS`.
  Re-derivation is the actual CLI/MCP probe; falsification is independent
  authored values plus exact summary-key exclusion; durability is the tracked
  probe/result, decision, contract and existing T1808 semantic oracle.
- [x] **NO REGRESSION** — RAM-guarded
  `prove -Iperl t/1806-vial-v2-public-foundation.t t/1808-vial-v2-lifecycle-compiler-phases.t t/1871-semantic-introspection-mcp-vial.t`
  reports `All tests successful. Files=3, Tests=15` and `Result: PASS`.
  The immutable tooling and compiler/MCP routes remain unchanged. Full feature
  qualification remains `.31.3.3`; no runtime or capacity conclusion follows.

The new root contract is explicitly classified and added to the independent
T1569 index fixture. Its first run caught that missing fixture member and an
unrelated pre-existing activation-content mismatch. The latter originates in
`0fc987bff`: the legitimate downstream book inclusion changed a link, while
T1569 still compares evolving parts to adoption bytes. `.31.3.2.4` owns the
immediate test repair; selection does not claim T1569 passes. Production index
regeneration/check succeeds. No current-reference or activation checker is
relaxed in this selection.

## Acceptance Checklist — `.31.3.2.4` current versus activation reference checks

- [x] **ROOT CAUSE (WHY + WHERE)** — The pre-repair T1569 run reports
  `#   at t/1569-focused-document-containment.t line 36.` and
  `activation content mismatch at docs/isf-spec/13-downstream-diagnostics-conformance.md:759`.
  Current source/checker bytes equal their HEAD versions; the HEAD test
  requests `--verify-activation-content` on evolving references. `git log -S`
  and `0fc987bff` identify the legitimate earlier book-link change. This is a
  stale test policy, not a corrupt activation source or defective book edit.
- [x] **ADDRESSED (verified)** — T1569 now uses ordinary current-reference
  checks for the live tree and link fixture. A separate repository-local
  fixture reads exact manifest-declared Git objects, independently verifies
  their hashes, and runs the existing activation materializer and equality
  verifier. A controlled body edit passes structural checks but fails exact
  historical equality at its precise path. Independent live-file hashes prove
  the fixture does not alter current references. Original gap, digest, missing
  link, stale index and unclassified-member controls remain. Production
  checker, manifest and current ISF prose are unchanged.
- [x] **NO REGRESSION** — RAM-guarded
  `prove -Iperl t/1560-live-document-ceiling-authority.t t/1561-live-document-reference-authority.t t/1569-focused-document-containment.t`
  returns `All tests successful. Files=3, Tests=19` and `Result: PASS`.
  `mdbook build docs/book -d .artifacts/reference-activation-book` and
  independent rendered current/historical guidance assertions pass.
  Re-derive: declared Git hashes and materialized equality; falsify: the same
  controlled edit under current versus historical checks plus preserved
  negative controls; durability: T1569, the unchanged manifest/checker and
  exact prior commit. Browser visual access remains unavailable. This repairs
  verification and does not change product semantics or qualify full CI.

## Model-instance meaning repair — `.31.3.2.5`

Projection review found that `(model MODEL_INSTANCE STATE)` resolved the chosen
instance, then retained only the shared model declaration's state identity.
Thus reads of `accepts.count` and `completions.count` produced equal public
meaning digests even though their authored instance bindings select different
transaction events. This is native semantic information loss, not a hash
algorithm collision or MCP truncation. The existing summary API cannot repair
it after the compiler has discarded the identity.

`SemanticBuilder::_expr` now carries `model_instance_id` beside the unchanged
state `semantic_id`. The shared builder applies the correction to both language
versions. Existing normalization carries the field into typed ExecutionIR;
source/compatibility projections now distinguish the selected scope. This is
an explicit bug correction for affected digests, not a v2-only reinterpretation
or a widening of summary/result/capability shapes. The book tells consumers to
refresh affected cached identities. No runtime profile is promoted.

`probe_vial_model_identity.pl` and `vial-model-identity-repair.json` retain a
controlled comparison against the exact compiler Git object at `eb2b8f2a1`.
Both runs use identical generated source bytes and source IDs; the probe checks
which compiler module was loaded. Different authored instances collide before
and differ after, while complete unmodified base reports stay equal. Source
hashes remain equal across the controlled before/after comparison. The earlier
inline probe used the maintained fixture's source ID, so its digest differs
from the durable probe's fixed `model_reference.vial`; neither is a global
content-only identity claim.

The initial T1872 assumed public plans retained model expressions. That
expectation was rejected: `ExecutionReport` deliberately summarizes operations.
The corrected baseline checks the actual typed ExecutionIR carrier and keeps
public planning success separate. No missing public plan detail is disguised
as a repaired source compiler defect. Deep source inspection remains owned by
`.31.3.2.3`, and source-only inspection needs no planner or backend.

## Acceptance Checklist — `.31.3.2.5` model-reference meaning identity

- [x] **ROOT CAUSE (WHY + WHERE)** — The corrected pre-fix T1872 reports
  `#   at t/1872-vial-model-reference-identity.t line 94.` with `got: undef`
  for the selected instance and equal digests for distinct model reads.
  `SemanticBuilder::_expr` resolves the instance but emitted only the state
  declaration ID. The tracked controlled probe verifies the exact old compiler
  module and reproduces equal public digests in both language versions.
- [x] **ADDRESSED (verified)** — T1872 passes after adding only the selected
  `model_instance_id` to the typed reference. Independent authored IDs and
  accepted/completed event bindings establish the intended difference; normal
  and terse forms and v1-to-v2 migration preserve each meaning. Native typed
  execution retains scope; portable/filesystem/native ToolCLI/MCP reports agree
  completely, source files stay unchanged, and unknown model/state names fail
  with the existing diagnostic. Controlled before/after probes confirm unequal
  affected meanings and identical complete base reports. Re-derivation: exact
  compiler/input comparison; falsification: selected-instance and same-meaning
  controls; durability: T1872, tracked probe/result and baseline Git object.
- [x] **NO REGRESSION** — RAM-guarded
  `prove -Iperl t/1550-vial-semantic-ir.t t/1555-vial-public-source-tooling.t t/1556-vial-public-planning-artifacts.t t/1801-vial-v2-source-projections.t t/1806-vial-v2-public-foundation.t t/1808-vial-v2-lifecycle-compiler-phases.t t/1870-vial-filesystem-source-query.t t/1871-semantic-introspection-mcp-vial.t t/1872-vial-model-reference-identity.t`
  reports `All tests successful. Files=9, Tests=59` and `Result: PASS`.
  `mdbook build docs/book -d .artifacts/model-identity-book` succeeds, and
  rendered cache-refresh/runtime-scope statements pass. Frozen fixture/API
  metadata, loading and lifecycle routes pass. Visual browser inspection,
  broader runtime and full CI qualification are not claimed.

## Acceptance Checklist — `.31.3.2.6.1` fault target identity

- [x] **ROOT CAUSE (WHY + WHERE)** — Corrected pre-fix T1873 reports
  `#   at t/1873-vial-fault-target-identity.t line 100.` with `got: undef`
  for the selected binding and equal digests for distinct aliases.
  `SemanticBuilder::_build_faults` resolved a binding but retained only its
  shared declaration ID. The tracked public probe reproduces that information
  loss with the exact baseline compiler Git object in both language versions.
- [x] **ADDRESSED (verified)** — The source compiler now adds
  `transaction_binding_id` only when multiple fixture bindings share the
  declaration. Unique bindings retain their prior record/identity. T1873
  independently checks authored scope, normal/terse and migration stability,
  imported declaration identity, malformed binding/field diagnostics and
  complete portable/filesystem/native/MCP reports without artifacts or source
  mutation. Controlled before/after reports prove affected meanings differ
  while complete unmodified base reports and summary shapes stay identical.
  The source contract documents explicit-versus-inferred scope; the selected
  inspection contract requires exact resolved scope in every public detail.
- [x] **NO REGRESSION** — RAM-guarded
  `prove -Iperl t/1550-vial-semantic-ir.t t/1555-vial-public-source-tooling.t t/1556-vial-public-planning-artifacts.t t/1633-vial-architecture-scale-checking-faults.t t/1714-vial-execution-fault-cardinality-preflight.t t/1801-vial-v2-source-projections.t t/1871-semantic-introspection-mcp-vial.t t/1872-vial-model-reference-identity.t t/1873-vial-fault-target-identity.t`
  reports `All tests successful. Files=9, Tests=61` and `Result: PASS`.
  Canonical source/evaluation/rerun/plan identities and exact/excess fault
  guards pass. `mdbook build docs/book -d .artifacts/fault-identity-book`
  and rendered identity/runtime-boundary assertions pass; browser visual
  access remains unavailable. No backend runtime or full CI claim is made.

Re-derivation is the identical-input public compiler comparison; falsification
is distinct authored bindings plus same-meaning/unaffected controls; durability
is T1873, the tracked probe/result, contracts/book and baseline Git object.
The initial import fixture used a local enum member against the imported enum
and correctly failed type validation. Correcting it to `lib.htrans_t.nonseq`
produced the accepted failing baseline; both logs are hashed in the audit.
Downstream execution admission and emitters remain owned by `.31.3.2.6.2`,
so the source repair does not prematurely close the fault parent.

## Downstream applicability investigation — `.31.3.2.6.2`

The source repair does not create a second AHB bridge transaction. Actual
public planning accepts the canonical target in both language versions and
rejects either distinct-alias source at the unresolved bridge reference,
without a partial plan or artifacts. The fault normalization seam retains
explicit binding/declaration identity, but that isolated carrier check is not
an admitted multi-binding execution claim. Canonical SV emission preserves
both unfaulted and substituted drives without launching a backend.

The public correlation probe also identifies misleading contract wording:
`declaration_order` is valid bridge metadata for plain IAL1, but binding it
returns `VIAL_BIND_EVENT_ERROR` requiring `single_active`. `git log -S` locates
the wording in selection `eaf3f95dc`; implementation `44dbecd1a` already has the
same refusal. This leaf owns clarifying the source/bridge/execution boundary
and its regression, without inventing a newly supported execution profile.
The initial plain fixture lacked the grammar-required endpoint; the corrected
fixture is source-valid and reaches the actual correlation diagnostic.

## Acceptance Checklist — `.31.3.2.6.2` downstream fault scope

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S declaration_order --format='%h %s' -- docs/VIAL_EXECUTION_IR_V1_CONTRACT.md`
  locates selection `eaf3f95dc`; `git show 44dbecd1a:perl/FSM/VIAL/ExecutionBuilder.pm`
  proves the original binder already requires `single_active`. T1874's actual
  public plan returns `VIAL_BIND_EVENT_ERROR` for the source-valid plain IAL1
  fixture. Actual distinct AHB aliases instead return the precise unresolved
  transaction `VIAL_BIND_REFERENCE_ERROR`, before any partial plan/artifacts.
- [x] **ADDRESSED (verified)** — The contract and book now separate valid
  source/bridge metadata from execution admission. T1874 verifies independent
  authored binding/declaration IDs and substitution values, actual canonical
  v1/v2 ExecutionIR, preserved explicit scope at the isolated normalization
  seam, duplicate-reference refusal, empty failure sinks and canonical SV
  drive emission. The seam test makes no complete multi-binding plan claim.
  VHDL/UVM admission and OSVVM delegation retain their existing bounded
  contracts; the separate caller-sealed balanced renderer is not replayed or
  promoted. No admitted public ambiguous-target runtime defect is established.
- [x] **NO REGRESSION** — RAM-guarded
  `prove -Iperl t/1552-vial-execution-ir.t t/1557-vial-portable-sv-backend-emission.t t/1593-vial-vhdl-portable-semantics.t t/1874-vial-fault-target-applicability.t`
  returns `All tests successful. Files=4, Tests=28` and `Result: PASS`.
  `mdbook build docs/book -d .artifacts/fault-applicability-book` and rendered
  boundary statements pass. Re-derivation: actual public plans and original
  implementation history; falsification: exact missing/duplicate/correlation
  controls plus canonical success; durability: T1874, tracked applicability
  record, contracts/book/fact and historical Git objects. Browser visual
  access, external runtime and full CI are not qualified by this slice.

## Acceptance Checklist — `.31.3.2.3.2.1` closed base source detail

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'selected bounded summary fields' --format='%h %s' -- docs/VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md`
  returns `08f59167b`. The tracked `.31.3.2.3.1` public CLI/MCP probe and
  `SemanticReport::_named_summaries` / `_fixture_summary` establish deliberate
  omission of declaration/action/expression bodies. Decision 0105 requires
  additive typed detail, not widening those frozen summaries.
- [x] **ADDRESSED (verified)** — `SourceInspection` uses enumerated closed
  record constructors and explicit kind/operator dispatch. Source spans become
  public locations; Boolean flags have explicit JSON type; decimal/bit/mask
  values remain strings; every fault resolves its exact binding. Unknown or
  missing fields/kinds, malformed coordinates and unresolvable scope fail.
  T1875 independently checks authored enum encodings, nested record/list types,
  signed model state, updates, event bindings, scoreboard keys, coverage range
  and cross references, random seed/decision IDs, every base action kind,
  expression operators, four-state masks and exact source-byte selection.
  Both versions, terse equivalence, imports, unchanged inputs and fresh repeat
  calls pass. Planner and backend runner modules remain unloaded. Families
  remain explicitly refused until .2; public API/CLI/MCP remain unshipped.
- [x] **NO REGRESSION** — RAM-guarded
  `prove -Iperl t/1550-vial-semantic-ir.t t/1555-vial-public-source-tooling.t t/1801-vial-v2-source-projections.t t/1806-vial-v2-public-foundation.t t/1808-vial-v2-lifecycle-compiler-phases.t t/1873-vial-fault-target-identity.t t/1875-vial-source-inspection-base.t`
  reports `All tests successful. Files=7, Tests=51` and `Result: PASS` after
  the authored-order correction. This supersedes the earlier passing band;
  forward-reference, malformed-coordinate and no-planner/runner controls are
  included in the final run. `mdbook build docs/book -d .artifacts/inspection-base-book`
  and rendered internal/unshipped statements pass; browser visual access
  remains unavailable. No execution, random evaluation or runtime claim.

Re-derivation uses actual parsed rich source and complete typed output;
falsification uses independently authored IDs/values/source substrings and
mutated-record refusal; durability is T1875, closed record definitions,
tracked evidence and the module. The first test attempt had an unescaped
slash in a test-source replacement; that syntax failure was fixed before
semantic qualification and is retained by log hash, not used as defect proof.
The Knowledge Map card is compacted without increasing its allowance. Task
and book metadata records only this owned implementation and truthful scope.

Final base-projection review adds a forward-declaration control: native type
construction inserts `later` before an earlier authored `first` alias that
references it. The inspection contract independently requires authored order,
so its constructor orders declarations by their source coordinates. Native
summary/digest repair is separately owned by `.31.3.2.7` and is the immediate
next slice after this foundation commit, before lifecycle implementation.

The final ordering regression first fails with `later` preceding `first` and
passes after projection declarations are ordered by their source coordinates.
The native compiler remains unchanged in this slice, with `.31.3.2.7` owning
its separate compatibility repair. The explicit new record definitions exceed
the prior focused-document line allowance; this leaf admits their measured
unique contract growth within the existing enforcement ceiling, with no debt
state or ceiling waiver. The initial doctrine failure is resolved by that
bounded ownership update before commit.

## Acceptance Checklist — `.31.3.2.7` native declaration order

- [x] **ROOT CAUSE (WHY + WHERE)** — The pre-repair T1876 reports
  `#   Failed test 'native declarations follow independently authored order'`
  and `#   at t/1876-vial-declaration-order.t line 99.` with `later` instead
  of `first`. Recursive `_build_type_declaration` appends completed dependencies
  before earlier authored aliases; native array positions consequently disagree
  with their original semantic paths. Public summaries inherit that order.
- [x] **ADDRESSED (verified)** — After successful construction, the builder
  restores each declaration collection from its original ordered stubs. It
  preserves dependency resolution, diagnostics, exact IDs and built records.
  T1876 verifies native/summary order and paths for local and imported types in
  both versions, transitive resolved identities, formatting and migration,
  complete portable/filesystem/native CLI/MCP report equality, unchanged source
  bytes and no publication. Unknown and cyclic aliases still fail with the
  existing diagnostic families and no partial summary. SourceInspection keeps
  its independent source-coordinate ordering.
- [x] **NO REGRESSION** — RAM-guarded
  `prove -Iperl t/1550-vial-semantic-ir.t t/1555-vial-public-source-tooling.t t/1556-vial-public-planning-artifacts.t t/1801-vial-v2-source-projections.t t/1806-vial-v2-public-foundation.t t/1808-vial-v2-lifecycle-compiler-phases.t t/1875-vial-source-inspection-base.t t/1876-vial-declaration-order.t`
  reports `All tests successful. Files=8, Tests=56` and `Result: PASS`.
  `mdbook build docs/book -d .artifacts/declaration-order-book` and rendered
  order/cache guidance pass; the disposable book output is removed. Browser
  visual access remains unavailable. No spent backend producer is replayed.

The controlled public probe loads the exact pre-repair compiler from `a84d4456`
with loaded-module path/hash verification. Identical base sources retain
identical complete check-report hashes; forward-alias sources change order and
semantic digests in both versions, plus the v2 public compatibility digest.
Affected caches must refresh; source/summary shapes and canonical base behavior
remain unchanged. This repairs a violated authored-order contract, not a hash
collision. Re-derivation: tracked probe and native/API reports. Falsification:
independent authored order/path/reference controls, bad dependencies and base
report equality. Durability: T1876, exact Git baseline, tracked
`vial-declaration-order-repair.json`, contracts/book/fact. Log hashes and final
summaries are retained there. Full CI/runtime remain outside this slice.
Task/book containment metadata records only this owned repair; existing
knowledge-card allowance is unchanged. No separate rationale ledger entry is
needed because the implementation invariant belongs to the source contract.

## Acceptance Checklist — `.31.3.2.3.2.2.1` typed lifecycle detail

- [x] **ROOT CAUSE (WHY + WHERE)** — Pre-implementation T1877 reports
  `VIAL source inspection projection at /packages/0: intent family detail is not implemented`
  and `#   at t/1877-vial-source-inspection-lifecycle.t line 111.` The base
  projector deliberately refuses every nonempty family; existing public
  summaries contain counts rather than the selected lifecycle meaning.
- [x] **ADDRESSED (verified)** — Explicit constructors now emit the independent
  intent-node schema, closed common envelope and family-specific payloads.
  Native common collection validation checks bounded identities/provenance;
  bounded condition validation precedes explicit public condition construction.
  No arbitrary private hash becomes output. T1877 independently verifies the
  complete readiness record, every node's authored identity/location/rank,
  intrinsic/additional relations, service conditions, deadlines, failure defaults
  and explicit policies. Normal/terse/import meaning, no-service and
  no-dependency cases separately, fresh deterministic output and unchanged
  compiler input pass. Unknown/missing family/payload/detail/condition fields,
  revision/kind, invalid milestone/bounds/scope and excess condition depth/width
  fail closed. No planner or runner loads. The old lifecycle refusal assertion
  is replaced by the substantive lifecycle and unknown-revision controls.
- [x] **NO REGRESSION** — RAM-guarded
  `prove -Iperl t/1550-vial-semantic-ir.t t/1555-vial-public-source-tooling.t t/1801-vial-v2-source-projections.t t/1806-vial-v2-public-foundation.t t/1808-vial-v2-lifecycle-compiler-phases.t t/1875-vial-source-inspection-base.t t/1876-vial-declaration-order.t t/1877-vial-source-inspection-lifecycle.t`
  reports `All tests successful. Files=8, Tests=56` and `Result: PASS`.
  `mdbook build docs/book -d .artifacts/inspection-lifecycle-book` and rendered
  detail/unshipped/prerequisite assertions pass; disposable book output is
  removed. Browser visual access and full CI/runtime remain unqualified.

Re-derivation: actual parsed source/catalogs and typed constructor. Falsification:
independent complete-record/coordinate oracles, changed source policies, hostile
records and no-planner/runner controls. Durability: T1877, explicit contract,
constructor and `vial-inspection-lifecycle-qualification.json` with raw-run hashes.
The initial green attempt had incorrect test expectations for inclusive end
columns and single-operand all wrappers; these were corrected from the source
contract. The separate native rejection of legal start_requires was then
reproduced without inspection and root-caused: an unparenthesized Perl map
consumes the optional condition as another dependency ID. Removing both optional
dependency/service collections exposes another native invalid empty-all
construction. Both failures are durably captured with public diagnostics and
underlying first-party exceptions. `.2.2.2` and `.2.2.3` own immediate repairs;
this internal projection slice does not claim those sources are admitted or the
public facade shipped. The lifecycle parent stays active until they are fixed.
Task/book metadata admits only this owned detail and truthful scope; knowledge
card compaction keeps its existing allowance. Record definitions belong to the
inspection contract, so no separate rationale ledger entry is needed.

## Acceptance Checklist — `.31.3.2.3.2.2.2` service start requirements

- [x] **ROOT CAUSE (WHY + WHERE)** — Pre-repair T1878 reports
  `#   Failed test 'legal (configured) checks with no_dependencies=0'`
  and `#   at t/1878-vial-lifecycle-start-requirements.t line 83.` Public source
  validation returns `VIAL_SEMANTIC_ERROR`. The prior tracked native diagnosis
  exposes an object-valued dependency reference: Perl's unparenthesized map in
  `LifecycleControl::_build_program` consumes the optional authored condition
  as another dependency ID instead of appending it to the conjunction.
- [x] **ADDRESSED (verified)** — Parentheses bound only the dependency-map
  input. T1878 independently asserts configured, reset and nested additional
  conditions with and without dependencies, exact scalar prerequisite IDs,
  complete typed inspection, imported domain scope, normal/terse meaning and
  complete portable/filesystem/native CLI/MCP report equality. The actual
  public target-neutral plan retains the added reset condition unchanged.
  Unknown domains/conditions, cyclic readiness, authored empty all and excess
  operand count still fail specifically without partial reports or artifacts.
- [x] **NO REGRESSION** — RAM-guarded
  `prove -Iperl t/1555-vial-public-source-tooling.t t/1801-vial-v2-source-projections.t t/1806-vial-v2-public-foundation.t t/1808-vial-v2-lifecycle-compiler-phases.t t/1877-vial-source-inspection-lifecycle.t t/1878-vial-lifecycle-start-requirements.t`
  reports `All tests successful. Files=6, Tests=31` and `Result: PASS`.
  `mdbook build docs/book -d .artifacts/lifecycle-start-book` and rendered
  service-start/remaining-prerequisite assertions pass; disposable output is
  removed. Browser visual access, backend execution and full CI remain outside
  this slice. No spent producer is replayed.

Re-derivation uses the tracked public probe against the exact `bd18ad17` compiler
blob and the repair, with loaded-module path/hash verification. Falsification
uses identical source IDs/bytes: complete canonical check/plan reports and
plan/meaning identities remain equal, while the authored reset-start source
moves from refusal to success. T1878 supplies independent semantic and invalid
input controls. Durability is the exact Git baseline, tracked
`vial-lifecycle-start-repair.json`, test, probe, contracts/book/fact. The empty
readiness failure remains immediately owned by `.2.2.3`; the lifecycle parent
stays active and public inspection is unadvertised. Task/book metadata admits
only this owned repair; knowledge-card allowance is unchanged. The source
contract owns the construction invariant, so no rationale-ledger duplication.

## Acceptance Checklist — `.31.3.2.3.2.2.3` empty readiness

- [x] **ROOT CAUSE (WHY + WHERE)** — Pre-repair T1879 reports
  `#   Failed test 'legal empty dependency/service collections check'`
  and `#   at t/1879-vial-lifecycle-empty-readiness.t line 75.` Public source
  validation returns `VIAL_SEMANTIC_ERROR`; the earlier tracked direct native
  diagnosis is `lifecycle condition /condition all node requires at least one operand`.
  `_build_program` constructs an empty all for readiness when both permitted
  optional collections and the authored requirement are absent, despite the
  configured lifecycle-entry precondition already being mandatory.
- [x] **ADDRESSED (verified)** — Only otherwise-empty readiness receives
  `all(configured)`. T1879 independently asserts its complete native, inspection
  and public-plan condition; empty relation lists; exact fixture/domain scope;
  no invented service/dependency; and semantic equality with explicit configured
  readiness. Normal/terse/imports and complete portable/filesystem/native CLI/MCP
  reports agree. Existing nonempty reset readiness is untouched. Authored empty
  all, unknown scope, cycles and excess operands remain specifically rejected
  with no partial semantic report or artifact. The general condition validator
  is unchanged.
- [x] **NO REGRESSION** — RAM-guarded
  `prove -Iperl t/1555-vial-public-source-tooling.t t/1801-vial-v2-source-projections.t t/1806-vial-v2-public-foundation.t t/1808-vial-v2-lifecycle-compiler-phases.t t/1877-vial-source-inspection-lifecycle.t t/1878-vial-lifecycle-start-requirements.t t/1879-vial-lifecycle-empty-readiness.t`
  reports `All tests successful. Files=7, Tests=34` and `Result: PASS`.
  `mdbook build docs/book -d .artifacts/lifecycle-empty-book` and rendered
  semantics/unshipped-interface assertions pass; disposable output is removed.
  Browser visual access, external runtime and full CI remain unqualified; no
  spent producer is replayed.

Re-derivation: tracked public check/virtual-plan probe with the exact `9700c273`
compiler blob, module path/hash verification and identical source IDs/bytes.
Falsification: canonical and explicit-reset/configured complete check/plan
reports remain identical; only formerly failing empty readiness gains admission,
with the same semantic digest as explicit configured readiness. T1879 adds
independent condition, absence and invalid-source controls. Durability: exact
Git baseline, tracked `vial-lifecycle-empty-readiness-repair.json`, probe/test,
contracts/book/fact. The lifecycle projection parent is complete; portable and
filesystem public facades are next, with CLI/MCP detail still unadvertised.
Task, book and source-spec aggregate metadata records this owned repair; the
knowledge-card allowance remains unchanged. The source spec owns the default
normalization rationale, with no duplicate rationale-ledger entry.

## Acceptance Checklist — `.31.3.2.3.2.3` public inspection APIs

- [x] **ROOT CAUSE (WHY + WHERE)** — Pre-implementation T1880 reports
  `#   Failed test 'portable source inspection API exists'` and
  `#   at t/1880-vial-public-source-inspection.t line 19.` The filesystem
  counterpart also fails at line 20. The qualified internal projector has no
  public facade; native check intentionally returns only a semantic summary.
- [x] **ADDRESSED (verified)** — Exported portable/file inspection functions
  construct the independent closed result, preserve the entire native check
  and ordered diagnostics, and expose complete typed base/lifecycle detail.
  T1880 compares complete reports, versions/styles/imports and repaired lifecycle
  forms; checks closed arguments, limits and unsafe paths; mutates files and
  caller values after check to prove captured-byte reuse; verifies fresh values
  and absence of stdout/stderr/filesystem mutation; traps planning/publication;
  and injects a projection exception to prove sanitized outer failure with an
  intact successful native check. Existing check construction is unchanged;
  detail reparses captured values without reopening sources.
- [x] **NO REGRESSION** — RAM-guarded
  `prove -Iperl t/1555-vial-public-source-tooling.t t/1801-vial-v2-source-projections.t t/1806-vial-v2-public-foundation.t t/1870-vial-filesystem-source-query.t t/1875-vial-source-inspection-base.t t/1877-vial-source-inspection-lifecycle.t t/1878-vial-lifecycle-start-requirements.t t/1879-vial-lifecycle-empty-readiness.t t/1880-vial-public-source-inspection.t`
  reports `All tests successful. Files=9, Tests=49` and `Result: PASS`.
  `mdbook build docs/book -d .artifacts/inspection-api-book`, rendered scope/error
  assertions and the actual documented exported API example pass. Disposable
  rendered output is removed. T1870 retains exact/excess import/stream limits.
  Browser visual access, runtime and full CI remain outside this qualification;
  no spent producer is replayed.

Re-derivation uses actual exported APIs and the runnable book example;
falsification uses baseline absence, exact native comparisons, authored values,
closed/invalid admission, mutation/no-effect controls and injected projection
failure. Durability is T1880, the exact Git baseline and tracked
`vial-inspection-api-qualification.json`, public contract, book and fact card.
CLI/discovery and MCP remain separate pending leaves; summary queries and
frozen tooling capabilities are unchanged. Task/book metadata admits only this
owned interface; the existing knowledge card is compacted within its allowance.
The inspection contract owns the API/error rationale without a duplicate ledger.

## Acceptance Checklist — `.31.3.2.3.2.4` native inspection and discovery

- [x] **ROOT CAUSE (WHY + WHERE)** — Pre-implementation T1881 reports
  `#   Failed test 'independent inspection capability API exists'` and
  `#   at t/1881-vial-inspection-cli-discovery.t line 21.` The actual native
  inspect command also fails at line 23. Public detail APIs exist, but native
  CLI dispatch and independent machine-readable discovery do not expose them.
- [x] **ADDRESSED (verified)** — The JSON-only native inspect branch delegates
  to the public bounded filesystem API and rejects all unrelated options before
  loading. Separate exported capability discovery and the manifest surface map
  describe the public schemas, source groups, admitted family, limits and no
  execution/publication effects. T1881 verifies full actual CLI/API equality,
  authored reset/deadline values, normal/terse/imports, diagnostics and exit
  codes, closed option refusal, no writes, fresh discovery and frozen v1/v2
  capability hashes captured from the preceding committed APIs. Initial test
  fixtures used a prohibited leading-dot source path; fixtures now use an
  explicitly repository-local non-hidden temporary directory with cleanup.
  Production path admission is unchanged.
- [x] **NO REGRESSION** — RAM-guarded
  `prove -Iperl t/1438-semantic-introspection-contract.t t/1439-semantic-introspection-section-runtime-contract-audit.t t/1440-semantic-introspection-manifest-contract-roundtrip-audit.t t/1445-semantic-introspection-mcp-schema-snapshots.t t/1555-vial-public-source-tooling.t t/1806-vial-v2-public-foundation.t t/1870-vial-filesystem-source-query.t t/1871-semantic-introspection-mcp-vial.t t/1880-vial-public-source-inspection.t t/1881-vial-inspection-cli-discovery.t`
  reports `All tests successful. Files=10, Tests=44` and `Result: PASS`.
  `mdbook build docs/book -d .artifacts/inspection-cli-book`, rendered contract
  assertions and the actual documented native lifecycle command pass. Exact
  disposable rendered output is removed. No backend/spent producer or full CI
  is run; browser visual qualification remains unavailable.

Re-derivation: actual native subprocesses and public file/discovery APIs.
Falsification: absent-command baseline, authored semantic values, complete API
comparisons, frozen capability hashes, malformed/effect options, source/import
and injected projection failures. Durability: T1881, exact baseline revision,
tracked `vial-inspection-cli-qualification.json`, contract, book and fact card.
The API/CLI parent is complete; MCP detail is the next leaf, with its tool and
resource still unadvertised. README and root help gain only compact discovery
wording. Task/book metadata records the owned interface; the existing fact card
stays within its allowance. The public contract owns CLI/discovery rationale.

## Acceptance Checklist — `.31.3.2.3.3` MCP deep inspection

- [x] **ROOT CAUSE (WHY + WHERE)** — Pre-implementation T1882 reports
  `#   Failed test 'dedicated VIAL inspection tool is discoverable'` and
  `#   at t/1882-semantic-introspection-mcp-vial-inspection.t line 25.` The
  callable-route assertion also fails at line 27. Qualified public/native
  inspection exists, but MCP exposes only the older VIAL summary result.
- [x] **ADDRESSED (verified)** — The dedicated closed inspection tool,
  versioned resource and capability section delegate to the clean public API.
  T1882 asserts complete native/API/tool/resource and text/structured equality,
  authored action bodies, lifecycle deadline/service/failure policy, additional
  start conditions and exact empty-readiness normalization. Versions, imports,
  normal/terse, native source/path/limit refusal, outer projection failure with
  successful inner check, invalid protocol arguments, no source writes and no
  hardware runner are qualified. Actual one-shot and newline stdio preserve the
  entire result. The discovery test caught a missing separate name inventory;
  domain/family/tool/resource inventories and applicability now agree. Snapshot
  coverage includes the actual lifecycle inspection envelope and tool shape.
- [x] **NO REGRESSION** — RAM-guarded
  `prove -Iperl t/1438-semantic-introspection-contract.t t/1439-semantic-introspection-section-runtime-contract-audit.t t/1440-semantic-introspection-manifest-contract-roundtrip-audit.t t/1441-semantic-introspection-mcp-adapter.t t/1442-fsmgen-mcp-jsonrpc-cli.t t/1443-semantic-introspection-mcp-protocol-hardening.t t/1444-semantic-introspection-mcp-support-queries.t t/1445-semantic-introspection-mcp-schema-snapshots.t t/1455-semantic-introspection-mcp-structured-tool-output.t t/1456-semantic-introspection-mcp-tool-annotations-boundary.t t/1462-semantic-introspection-mcp-serverinfo-instructions-boundary.t t/1871-semantic-introspection-mcp-vial.t t/1880-vial-public-source-inspection.t t/1881-vial-inspection-cli-discovery.t t/1882-semantic-introspection-mcp-vial-inspection.t`
  reports `All tests successful. Files=15, Tests=56` and `Result: PASS`.
  The final expanded T1882 separately passes with actual newline transport.
  `mdbook build docs/book -d .artifacts/inspection-mcp-book`, rendered guidance
  and all documented capability/tool/resource commands pass; their inspection
  report exactly equals the native book example. Disposable rendered output is
  removed. No backend, spent producer or full CI is run; browser access is still
  unavailable.

Re-derivation uses actual native/one-shot/newline MCP producers and the public
API. Falsification uses authored semantic oracles, complete report equality,
closed-argument and root-authority controls, failed admission and injected
projection faults; summaries and frozen capability hashes remain guarded.
Durability is T1882, the exact baseline, snapshot, tracked
`vial-inspection-mcp-qualification.json`, book/contract and knowledge cards.
The deep-inspection parent is complete. Guard implementation explicitly remains
owned by `.31.3.2.1`, avoiding a dependency cycle with the facade repair; the
public applicability map now includes inspection. Full corpus qualification and
future-feature signoff remain active subsequent leaves, not inferred from this
focused band. Task/book metadata admits this interface; fact cards are compacted
within existing allowances. The public contract owns protocol rationale.

## Acceptance Checklist — `.31.3.2.1.1` source-query cohort selection

- [x] **ROOT CAUSE (WHY + WHERE)** — Pre-implementation T1883 reports
  `#   Failed test 'source-query cohort selector exists'` and
  `#   at t/1883-semantic-source-query-cohort.t line 13.` The earlier selection
  capture is historical evidence; no reusable live-catalog selector protects
  complete feature/source/query accounting after public inspection was added.
- [x] **ADDRESSED (verified)** — The test-side selector derives supported rows
  from canonical catalog/applicability records, preserves every ID with its
  exact family/coverage/capability/phase/nonclaim allocation and source metadata,
  deduplicates physical source work and registers VIAL versions explicitly.
  T1883 independently accounts for the native supported set, confirms each
  public VIAL source checks with its mapped version, proves deterministic fresh
  focus and disjoint complete hosted source partition compatibility, and rejects
  unknown/missing queries, source kinds/suffixes, versions, stale registrations,
  duplicate IDs, conflicting metadata, unsafe paths and malformed/empty focus.
  Expected-failure and legacy entries never become supported evidence.
- [x] **NO REGRESSION** — RAM-guarded
  `prove -Iperl t/1883-semantic-source-query-cohort.t t/248-regression-corpus-accounting.t t/1438-semantic-introspection-contract.t t/1439-semantic-introspection-section-runtime-contract-audit.t t/1440-semantic-introspection-manifest-contract-roundtrip-audit.t`
  reports `All tests successful. Files=5, Tests=7136` and `Result: PASS`.
  `mdbook build docs/book -d .artifacts/query-cohort-book`, rendered scope
  assertions and the actual list-only developer command pass; disposable output
  is removed. No backend, spent producer or full CI is run; browser visual audit
  remains unavailable.

Re-derivation is the default live selector with exact catalog/applicability/helper
hashes. Falsification independently groups canonical supported identities and
retains exact ID-to-bucket allocation, checks actual VIAL admission, partitions
and hostile records. Durability is T1883, the helper, exact baseline and tracked
`source-query-cohort-qualification.json`, book and knowledge card. The recorded
cohort counts describe selection, not completed query execution or independent
feature counts. Root public VIAL examples are accounted; separate runtime
qualification fixtures remain outside the supported-source cohort. Actual
native/API/MCP execution is next under `.31.3.2.1.2`, followed by semantic controls
and explicitly owned CI/exhaustive work. Task/book metadata records only this
owned selector; the existing knowledge card is compacted without a wider budget.

## Acceptance Checklist — `.31.3.2.1.2` actual query runner

- [x] **ROOT CAUSE (WHY + WHERE)** — The absent-runner baseline reports
  `#   Failed test 'actual source-query runner exists'` and
  `#   at t/1884-semantic-source-query-runner.t line 9.` Selection alone cannot
  prove execution or complete adapter parity. The expanded alias regression
  also reports `#   at t/1869-semantic-introspection-mcp-protocol-aliases.t line 27.`:
  its old expectation omitted the now-shipped VIAL inspection query.
- [x] **ADDRESSED (verified)** — T1884 invokes actual native commands, the
  public adapter without a stub, explicit VIAL file APIs and newline stdio.
  Complete reports, text/structured results, response identity, diagnostics,
  source/module/catalog/schema and adapter provenance agree. Typed JSON hashes
  independently match across every recorded query; source and repository-bound
  public producer hashes remain unchanged. Normalization preserves non-root
  paths, semantic paths, scalar types and all fields; simultaneous large stdout
  and stderr retain exact bytes and refusal status. Focus/list-only controls
  preserve source partitions and reject malformed selection. Initial test-only
  assumptions about universal schedule schemas and hash-valued `scheduled_fsm`
  were corrected against the actual public IAL2 report and T1255's scalar
  contract. T1869 now includes inspection; no product report is rewritten.
- [x] **NO REGRESSION** — RAM-guarded
  `prove -Iperl t/1884-semantic-source-query-runner.t t/1883-semantic-source-query-cohort.t t/1869-semantic-introspection-mcp-protocol-aliases.t t/1868-semantic-introspection-mcp-source-failures.t t/1871-semantic-introspection-mcp-vial.t t/1882-semantic-introspection-mcp-vial-inspection.t`
  reports `All tests successful. Files=6, Tests=54` and `Result: PASS`.
  Actual filtered/list-only book commands, complete disjoint query partitions,
  invalid selection refusal, `mdbook build docs/book -d .artifacts/query-runner-book`
  and rendered scope assertions pass. Disposable rendered output is removed.
  Browser visual audit, runtime and full CI remain outside this qualification;
  no spent producer is replayed.

Re-derivation uses actual public producers with exact source/producer binding.
Falsification uses the absent-runner/stale-alias baselines, complete typed report
comparisons, independent source/module/catalog/provenance checks, normalization,
pipe capture and selection controls. Durability is T1884, the reusable runner,
T1869, exact baseline and tracked `source-query-runner-qualification.json`, book
and knowledge card. Its selected query count describes only the recorded focused
execution, not exhaustive or independent feature completeness. Independent
semantic/negative controls are next, with CI integration and full execution still
owned separately. The active index now points to the current frontier. Task/book
metadata records this owned guard; fact-card allowance is unchanged. The book
owns developer invocation rationale without a duplicate engineering ledger.

## Acceptance Checklist — `.31.3.2.1.3` independent semantic controls

- [x] **ROOT CAUSE (WHY + WHERE)** — The missing-oracle baseline reports
  `#   Failed test 'independent source-query semantic oracle exists'` and
  `#   at t/1885-semantic-source-query-oracles.t line 9.` Complete transport
  parity cannot reveal a common loss of native semantic detail. The selected
  runner therefore needs expectations derived from authored fixtures and public
  contracts, independently of the compared producer results.
- [x] **ADDRESSED (verified)** — Pure report/envelope oracles now guard
  authored storage field ranges/reset/enums/access, passive observation signal
  order/width/role/timing, hardware source/module/producer identity, and VIAL
  reset actions, model expressions/instances, exact fault bindings, lifecycle
  prerequisites, bounds and cleanup. T1885 deliberately keeps corrupted
  transport reports identical while proving that missing/wrong detail, scalar
  types, schema, provenance and unregistered families/revisions fail at the
  named independent check. Oracles do not mutate evidence. Actual strict
  hardware and malformed VIAL inputs retain complete native/public-API/newline
  reports, exact refusal diagnostics and MCP isError; false success and missing
  diagnostics are rejected. Negative inputs remain outside supported selection.
  T1884 runs these same oracles for each selected supported source/query.
- [x] **NO REGRESSION** — RAM-guarded
  `prove -Iperl t/1885-semantic-source-query-oracles.t t/1884-semantic-source-query-runner.t t/1453-isf-storage-field-metadata.t t/1260-isf-verification-observation-metadata.t t/1868-semantic-introspection-mcp-source-failures.t t/1882-semantic-introspection-mcp-vial-inspection.t`
  reports `All tests successful. Files=6, Tests=52` and `Result: PASS`.
  Final T1885 also passes after adding an explicit VIAL file-API refusal
  comparison. `mdbook build docs/book -d .artifacts/query-oracle-book` and
  rendered witness/corruption/refusal/limit assertions pass; exact disposable
  output is removed. No backend, spent producer or full CI is run; browser
  visual qualification remains unavailable.

Re-derivation uses actual public producers and separately authored semantic
expectations. Falsification uses identical corrupted reports plus explicit
negative-source admission and missing/schema/provenance/type/future-family
controls. Durability is T1884/T1885, the pure oracle, exact source/guard hashes
and baseline in `source-query-oracle-qualification.json`, book and knowledge
card. The named independent witnesses do not prove every meaning in every
report. The guard parent is complete; CI partition/future-feature signoff and
exhaustive execution remain separate next leaves. Task/book metadata admits
only this owned guard; the fact card is compacted within its existing allowance.
The book owns the verification boundary without duplicate ledger narration.

## Acceptance Checklist — `.31.3.2.2` CI and future-feature signoff

- [x] **ROOT CAUSE (WHY + WHERE)** — T1183's missing-registration baseline
  reports `#   at t/1183-ci-regression-tier-selection.t line 379.` for
  `full mode explicitly selects the complete source-query cohort` and line 447
  for the rejected hosted T1884 dry run. Full mode otherwise inherited the
  runner's intentionally focused default, and T1884 still belonged to ordinary
  file shards; neither path guaranteed complete feature-query execution.
- [x] **ADDRESSED (verified)** — CI now owns T1884 as a separate supported
  corpus audit and excludes it from all ordinary file shards. Full/local and
  hosted T1884 explicitly select all sources, then apply only their declared
  shard coordinates. T1183 proves complete disjoint workload and tracked-file
  ownership, exact full/cohort dispatch, workflow matrix/aggregate closure and
  pre-dispatch refusal of ambient source filters, list-only mode and shard
  coordinates. An isolated executable fixture proves actual child environment
  and argv with inherited all-source mode disabled; it executes no product
  producer. T1885 remains bounded ordinary regression. Task rules/template and
  book require a corpus case, public API/MCP applicability and meaningful
  independent semantics for future public features, or an explicit owned
  boundary. Current sharding facts now include the existing VIAL gate family.
- [x] **NO REGRESSION** — RAM-guarded
  `prove -Iperl t/1183-ci-regression-tier-selection.t` reports
  `All tests successful. Files=1, Tests=18` and `Result: PASS`;
  `prove -Iperl t/1883-semantic-source-query-cohort.t t/1414-docs-relative-paths-audit.t`
  reports `All tests successful. Files=2, Tests=8` and `Result: PASS`.
  `bash -n bin/ci-regression`, the actual documented hosted dry run,
  `mdbook build docs/book -d .artifacts/query-ci-book` and rendered partition/
  signoff assertions pass. Disposable rendered output is removed. Full CI,
  actual hosted execution and spent runtime producers remain unexecuted;
  browser visual access remains unavailable.

Re-derivation reads actual workflow/CI declarations and obtains live workload
lists. Falsification is the missing-registration baseline, exact disjoint/full
inventory checks, actual isolated dispatch and rejected ambient narrowing.
Durability is the exact baseline, tracked workflow/CI/tests and hashes in
`source-query-ci-qualification.json`, book, task/template and knowledge cards.
Recorded job counts describe configured topology, never completed hosted runs.
The former corpus-count claim is rebound to its changed source-line identity
with renewed workflow derivation and partition/dispatch falsification evidence;
the claim inventory and disposition join pass without opening an evidence gap.
The guard/repair parent is complete; exhaustive source-query execution is next
under `.31.3.3`. Task/book metadata records this owned integration; knowledge
cards stay within their existing allowance. The workflow overview is compacted
within its ancillary allowance after the gate caught duplicated wording growth.
The book and task acceptance rules
own signoff rationale without duplicate engineering-ledger narration.

## Acceptance Checklist — `.31.3.3.1` MCP wire encoding resource repair

- [x] **ROOT CAUSE (WHY + WHERE)** — The original full T1884 partition exits
  137 under the unchanged RAM guard without a completed receipt. Native
  `--emit-semantic-json ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif`
  succeeds; replaying that exact captured public report reaches text formatting
  and then trips the guard inside outer compact response encoding. Independent
  public JSON::PP controls produce identical ASCII output bytes while isolating
  excessive memory in ASCII-only encoding of a large string. Final baseline
  T1886 reports `#   at t/1886-semantic-introspection-mcp-json-encoding.t line 63.`
  for the guarded exit failure in both actual CLI modes. The initial full-run
  query was not logged; this separately identified semantic report is a proved
  reproducer, not a guessed complete reconstruction of the interrupted run.
- [x] **ADDRESSED (verified)** — Newline and one-shot MCP wire encoding use
  UTF-8 JSON bytes, with corresponding UTF-8 request decoding. Public API text
  remains unchanged; complete reports, provenance, text/structured equality,
  ordering and scalar types survive. The cohort runner decodes wire bytes
  accordingly. T1886's actual CLI tests use a synthetic native producer with
  many ordinary strings forming a large response, preserve literal and escaped
  Unicode identities, reject invalid UTF-8, and pass the same tighter resource
  guard that rejects the baseline. No report is truncated, query omitted,
  source replaced or resource limit raised. The captured real report passes
  both complete native/MCP and text/structured comparisons after root-prefix
  normalization; the actual AHB source passes every applicable query.
- [x] **NO REGRESSION** — RAM-guarded
  `prove -Iperl t/1886-semantic-introspection-mcp-json-encoding.t t/1442-fsmgen-mcp-jsonrpc-cli.t t/1445-semantic-introspection-mcp-schema-snapshots.t t/1446-semantic-introspection-mcp-stdio-framing.t t/1455-semantic-introspection-mcp-structured-tool-output.t t/1868-semantic-introspection-mcp-source-failures.t t/1885-semantic-source-query-oracles.t`
  reports `All tests successful. Files=7, Tests=22` and `Result: PASS`.
  Final T1886 adds escaped/invalid UTF-8 controls and passes. Actual T1884 for
  the implicated source reports `Files=1, Tests=6` and `Result: PASS`; its receipt
  retains all applicable queries. Exact Unicode book commands, mdBook build
  and rendered encoding/qualification boundaries pass; disposable book output
  is removed. Full CI, hosted execution, browser visual qualification and the
  interrupted complete cohort remain unqualified; no spent producer is run.

Re-derivation is the actual native report, stage-isolated encoding, public
encoder comparison and actual native/API/newline rerun. Falsification is the
original guard failure, both bounded baseline transport failures, identical
control output hashes, complete typed comparisons and Unicode/refusal controls.
Durability is T1886, the exact baseline/source/producer hashes and measurements
in `source-query-memory-repair.json`, task, book and current fact card. Measured
memory describes this host and these inputs, not a universal memory bound.
Initial stage RSS samples accidentally addressed the forked ps process because
Perl's magical PID scalar was passed directly to list-open; a public ps probe
proved the discrepancy. Those samples are discarded, and a copied parent PID
fixes the verified stage probe. RAM-guard readings and external time maxima are
independent. An initial test syntax error and a guarded-stdin fixture mistake
are retained as diagnostic history, not counted as product failure evidence.
The native report is complete and large; ordinary report storage remains real.
Task/book metadata owns this repair; knowledge prose is compacted within its
existing allowance. Exhaustive qualification restarts under `.31.3.3.2` after
this commit. The book owns the wire contract without duplicate ledger prose.

## Acceptance Checklist — `.31.3.3.2.1` structural identity repair

- [x] **ROOT CAUSE (WHY + WHERE)** — Native
  `--emit-semantic-json ppif/apb_requester_transfer_sideband_data16_status_back_to_back.apb`
  differs only in `generation_result_snapshot.summary.hdl_code_length` across
  controlled hash seeds. Actual emitted HDL assigns `concatenation_expr` from
  different operands. `ASTFactorization::extract_ast_structure` represented
  unrecognized kinds by class alone, while candidate names followed hash order.
  Concatenations therefore merged regardless of operands. Existing literal
  signatures also omitted width/radix and signal signatures omitted slices.
  The isolated baseline fails T1887's identity and substitution assertions;
  Icarus reports `FATAL: ... A distinct from B` from independently authored
  expected values. The original APB driver has only a declaration and an
  assignment, with no consumer: that reproducer proves incorrect identity and
  report nondeterminism, not an observed APB output failure.
- [x] **ADDRESSED (verified)** — Supported structural signatures retain
  ordered concatenation operands, literal representation, signal slices and
  aggregate paths. Unknown kinds and containing expressions remain inline;
  no renderer string or object address substitutes for semantic identity.
  Candidate allocation is sorted. T1887 preserves distinct drivers, genuine
  sharing, operand order/multiplicity, nested operands, widths/radices/slices,
  aggregate paths and conservative handling of other expression kinds. Seed
  and insertion-order controls pass, and independent generated-expression HDL
  behavior now matches differing input values. Original APB semantic reports
  are byte-identical across the tested seeds; HDL differs only in its timestamp.
  T1884 retains complete fields/types and uses canonical UTF-8 response hashes
  plus structural comparisons to avoid enormous embedded-text failure dumps.
- [x] **NO REGRESSION** — RAM-guarded factorization/defensive-copy regression
  reports `All tests successful. Files=15, Tests=30` and `Result: PASS`.
  The final T1887/T1866/T1867/T1883/T1885 band reports
  `All tests successful. Files=5, Tests=25` and `Result: PASS`.
  Actual T1884 for every failed source recovered from both retained partitions
  reports `All tests successful. Files=1, Tests=18` and `Result: PASS`.
  Its receipt contains every applicable check/semantic/schedule query and
  matching native/API/newline hashes; an independent join checks the exact
  source union, uniqueness, source bytes and producer identities. Perl syntax,
  mdBook build, rendered identity/metadata guidance and Knowledge Map generation
  pass. Disposable rendered output is removed. Browser visual qualification,
  complete cohort, full CI and hosted execution remain unqualified; historical
  spent producers remain untouched.

Re-derivation uses seed-controlled native reports and exact emitted HDL, then
recovers failed source identities independently from retained partition TAP.
Falsification uses the isolated baseline factorizer with the same behavioral
oracle, distinct input values, identity variations, complete report comparisons
and exact receipt/source/producer joins. Durability is the tracked regression,
implementation, book, current fact card and `source-query-identity-repair.json`.
The simulation supplies an explicit two-bit context around factorizer-generated
drivers and substitutions; it is not an APB protocol simulation. Early reduced
source probes were refused for infix assignment or an unsupported guard shape;
they are diagnostic attempts, not additional product defect claims.

The director supplied three SPECFORGE tickets during this repair. `.32` owns
their current-checkout reproduction and resolution without a dirty-tree pivot;
the original reports remain caller-authorized read-only inputs. The missing
old-export `specs/` concern is preserved under `.32.2`, including exact-revision
resources and a known-good preflight before differential claims. After this
commit, `.32.1` is next; complete cohort qualification follows those repairs.
Task/book containment metadata records this slice. The fact card's duplicated
reverify command is compacted within its existing allowance. Book and task
records own the rationale without duplicate engineering-ledger prose.

The staged doctrine gate caught a missing root child link and a pending status
on the newly introduced `.32` container. Both are corrected; its implementation
leaves remain pending until the clean handoff. No code verification changed.


## Acceptance Checklist — `.32.1.1` declared rule reads

- [x] **ROOT CAUSE (WHY + WHERE)** — At `45c0e579c`, native strict
  `--check --json` and `--emit-semantic-json` accept the supplied one-bit
  undeclared `VALID` source. Semantic signal analysis and structural ports
  expose `VALID` as an input; generated SV has `input wire VALID`. Schedule
  preview accepts both invalid variants; the mixed-width source instead fails
  late with an inferred RHS width mismatch. Parser rule validation checks
  structural and special enum/aggregate domains but does not resolve ordinary
  reads against actor symbols. The same implicit-inference dependency hides
  shared-state declarations in AXI endpoint and composition generators.
- [x] **ADDRESSED (verified)** — The ISF parser collects missing reads in
  guards, nested RHS expressions, selections and bank index/value operands
  before returning the actor shell. Diagnostics deterministically identify
  actor, operands and reading rules; declared symbols, enum/aggregate leaves
  and transaction-local inference retain their separate contracts. The new
  catalog fixture publishes `FSMGEN_LANGUAGE_ISF_UNDECLARED_RULE_OPERAND`.
  T1888 rejects the original cases through native/API/newline MCP, keeps the
  authored source, verifies the declared-input control and prevents invalid
  HDL emission. AXI generators explicitly declare shared actor state rather
  than weakening admission. Existing independent transfer/payload/stall/reset
  oracles pass before and after; full SV matches except its date headers.
- [x] **NO REGRESSION** — T1888 reports `All tests successful. Files=1,
  Tests=7` and `Result: PASS`. Focused rule/enum/aggregate checks report
  `Files=11, Tests=35`; catalog/diagnostic/cohort checks report
  `Files=4, Tests=8264`; multi-clock/provenance/fan-in/MCP checks report
  `Files=5, Tests=145`, all successful. Endpoint T1884 reports
  `Files=1, Tests=21` with complete native/API/newline query equality.
  Composition T1884 reports `Files=1, Tests=18`. The final ordinary public
  adapter census consumes every selected source successfully; the independent
  catalog/receipt join confirms unique complete coverage and unchanged source
  hashes. Endpoint and composition queries cover each affected producer through
  check/semantic/schedule, preserving complete typed reports across transports.
  Perl/Python syntax, the exact complete book example, rendered contract checks
  and mdBook build pass. Browser visual review remains unavailable.

Re-derivation uses caller-file hashes, native reports and actual emitted ports.
Falsification includes before/after refusal, declared/literal/enum/aggregate
controls, transaction-private scope, absent generated handoff declarations,
constructor collisions, full typed transport equality, independent protocol
oracles and exact emitted-HDL comparisons. Durability is T1888, the catalog
fixture, implementation, book/facts and
`docs/audits/specforge-rule-admission-20260924/`.

The broad strict-generation attempt was deliberately cancelled after its
completed prefix; its interrupted children and unvisited sources are not
passes. Actor admission is verified through ordinary public adapters. Replaying
all generated ISF is a different contract: the discovered AHB interconnect
review artifact bypasses executable ISF and is owned for repair by `.32.4`.
The book names that limitation. Initial test exit-status/diagnostic wording
assumptions and a driver print warning were corrected without changing product
exit conventions. Icarus rejects even a minimal forward wire declaration;
its unsuccessful attempt is not HDL qualification. Endpoint Verilator oracles
use assertions; composition behavior oracles deliberately drive invalid
inputs and retain their published `--no-assert` profile. An initial incorrect
assert-enabled composition run stopped on its expected misalignment assertion
and is not counted as a product failure. Full CI, hosted execution and browser
visual review remain outside this signoff; spent native producers are intact.


The first staged doctrine pass accepts fresh task evidence but finds the new
nested audit README outside existing document surfaces. The exact replay
procedure is now registered as `isf_rule_admission_replay`, bounded separately
without widening existing collection ceilings or hiding the Markdown file.

## Acceptance Checklist — `.32.1.2` authored diagnostic provenance

- [x] **ROOT CAUSE (WHY + WHERE)** — Native `--strict --check --json` on
  the independently declared width-8 VALID / width-1 B source fails correctly
  but names an ephemeral lowered FSM. `bin/fsmgen` saves the authored source
  yet its generation catch uses the lowered path; CheckDiagnostics extracts
  the embedded Source file label before its fallback argument. The operand
  validator itself prefixes its module/method names. Baseline and repaired
  reports are retained in `width-diagnostics.json` in the rule-admission audit.
- [x] **ADDRESSED (verified)** — The CLI registers origins only for FSM files
  it writes, projects exact quoted identities in failure context, and uses the
  authored source for failure reports. Inline source references and generated
  domain parent context agree; real external child and expected lookup paths
  stay physical. Directly rechecked retained artifacts name themselves.
  Removing the prefix at the operand validator also cleans library exceptions.
  T1889 proves actual width reasons, compatibility-mode domain children,
  retained files, PPIF public-hook failures, complete native/API/newline MCP
  equality and valid-source controls. No line/column mapping or universal
  stable width-error classification is claimed.
- [x] **NO REGRESSION** — RAM-guarded T1889 reports `All tests successful.`
  and `Files=1, Tests=5`. The operand/width, real child/RTL/lookup context,
  D-input cleanup, MCP source-failure and undeclared-rule band reports
  `All tests successful. Files=8, Tests=33`. The mdBook build and rendered
  contract assertions pass; the disposable rendered output is removed.

Re-derivation uses the exact declared-source control and native check/semantic
reports. Falsification covers real child paths, direct retained artifacts,
width-aligned success and full transport equality. Durability is T1889,
`docs/audits/specforge-rule-admission-20260924/width-diagnostics.json`, the book,
ISF reference and semantic-introspection fact card. Initial test assumptions
were corrected: human `--check` requires JSON, the historical concat fixture
uses compatibility assignment syntax, and generated_child_source is a kind
field rather than a combined kind/name. These are not product changes.

The multi-domain control separately exposes emitted slash-form top wiring,
which strict admission rejects before child validation. This is traced to
`FSM::Scheduler::ISF::_link`, explicitly owned by `.32.1.3` and next for repair.
The diagnostic slice does not call that strict path qualified. Full CI/push
and browser visual review remain gated; spent native producers are untouched.

## Acceptance Checklist — `.32.1.3.1` canonical multi-clock wiring

- [x] **ROOT CAUSE (WHY + WHERE)** — At `c6b8bc783`, native strict
  `--check --json` rejects each checked-in event/dual-event/no-reset source
  on generated slash links. `Scheduler::ISF::_emit_multi_domain_wiring` routes
  every domain and CDC connection through `_link`, whose return value is the
  legacy slash token. Existing lowering tests matched that legacy spelling.
  Exact original native reports and post-repair results are retained in
  `docs/audits/specforge-rule-admission-20260924/multiclock-strict-wiring.json`.
- [x] **ADDRESSED (verified)** — `_link` emits canonical endpoint pairs without
  altering connection selection. Tests now assert those routes and T1890
  independently strict-checks every generated artifact for event, dual-event,
  no-reset and activation controls. Strict and compatibility HDL match except
  date headers; complete native/API/newline check, semantic and schedule
  reports agree. T1889 now reaches actual strict domain-child width failures
  using explicit async active-low resets and preserves authored provenance.
  Original dual-event/no-reset sources pass strict check; the single-event
  source now reaches its separately owned reset-carrier error.
- [x] **NO REGRESSION** — The RAM-guarded T1247/T1387/T1889/T1890/T411 band
  reports `All tests successful. Files=5, Tests=39` and `Result: PASS`.
  The original fixture compatibility HDL is byte-identical before/after after
  removing only emitted date headers. T411 still rejects authored legacy
  slash syntax; strict admission is not relaxed. The final mdBook build and
  rendered canonical-wiring/reset/naming-limit checks pass; output is removed.

Re-derivation is the native before/after report set and exact generated HDL.
Falsification combines independent strict artifact admission, real child
errors, unchanged complete hardware text, authored legacy rejection and full
transport equality. Durability is the tracked audit JSON, T1890, extended
T1889, existing route tests, book/spec and fact card. This is syntax and query
qualification, not a reset/event behavioral claim. Full CI/push and browser
visual review remain gated.

Runtime review exposed a genuine baseline reset-polarity contradiction, owned
by `.32.1.3.2`. Activation qualification additionally exposed reserved logical
domain-name reuse and a public `ready` input's explicit-route collision, both
owned for separately scoped repairs under `.32.1.3.4` before `.32.1.3.3`
behavioral closure. Initial harness assumptions about every reset-declared
fixture being faulty were corrected: the dual-event fixture already uses
supported async active-low/sync active-high forms. The syntax control uses
explicit supported resets, portable domain `peripheral` and input `work_ready`;
no discovered gap is marked fixed by those choices. Failed development TAPs
remain under `.artifacts/isf-multiclock-strict/`; successful evidence is
`focused-complete.tap`, whose complete summary is in the tracked audit.

The first staged gate found the bounded audit README over its normal pressure
threshold. Its replay paragraphs are reflowed within the existing ceiling;
no budget or lifecycle state is widened, and no technical content is removed.


## Acceptance Checklist — `.32.1.3.2.1` explicit FSM reset polarity

- [x] **ROOT CAUSE (WHY + WHERE)** — At `7761cc503`, native strict
  `--check --json` refuses `(sreset reset_n active_low)` as misleading
  `(sreset unknown)`. The public Lispish AST carries name/polarity together;
  FSMGenFull's system parser and SourceFrontend assumed a single name.
  CoreAST recomputed the active level from the keyword instead of retaining
  the parser's resolved level. Existing hardware consumers already use the
  normalized kind/level. The retained before report and repaired
  `--emit-semantic-json` projection identify the boundary precisely.
- [x] **ADDRESSED (verified)** — Canonical sreset/areset accept one optional
  literal polarity; explicit level overrides naming while omitted forms retain
  defaults and strict checks. The effective contract preserves the resolved
  level with unchanged semantic field families. Capabilities expose all forms;
  invalid polarity has a stable catalogued diagnostic. T1891 covers the full
  timing/level matrix, malformed/duplicate/legacy controls, capabilities and
  complete native/API/actual newline MCP success and failure equality.
  T1892 independently observes nonzero reset values, clocked updates and pulses
  wholly between edges in SystemVerilog, Verilog and VHDL, with no tool skips.
- [x] **NO REGRESSION** — RAM-guarded T1891/T1892 report
  `All tests successful. Files=2, Tests=11` and `Result: PASS`. The existing
  reset-name/alias/backend, normalized-contract/copy/roundtrip, language-surface,
  corpus and diagnostic-registry band reports `Files=18, Tests=8324`, all
  successful. The complete book example strict-checks, mdBook builds and
  rendered contract assertions pass. Browser visual review remains unavailable.

Re-derivation uses the exact source, public raw AST and native before/after
reports. Falsification uses opposite-name explicit forms, old-default and
no-reset controls, invalid declarations, complete transport equality and
independent between-edge HDL observations. Durability is T1891/T1892,
`docs/audits/specforge-rule-admission-20260924/reset-polarity-carrier.json`,
decision 0106, the book and the explicit-system-reset-polarity fact card.
The first development parser assumed a flat AST entry; public AST capture
corrected that assumption before qualification. No dependency implementation
was inspected. ISF emission is deliberately unchanged until `.32.1.3.2.2`;
full CI/push and spent native producers remain outside this qualification.

The ordinary new fact card uses decision 0064's explicit collection-measurement
procedure despite unrelated per-card rollover debt; decision 0070 supplies one
bounded measurement step. The new rationale file remains inside the existing
collection file ceiling and byte/line allowances. No enforcement ceiling,
per-file bound or historical baseline changes. Task/book aggregate authority
records only this slice's measured documentation changes.

The first staged doctrine pass identifies the reset table's binary active
levels as new claim-review candidates. Each is now explicitly reviewed as an
exact syntax value, backed by the semantic and independent HDL tests; no
measured claim or missing evidence is hidden by that classification.


### `.32.1.3.2.2` verification-output locality recovery — verified

The mdBook publisher returned success but the expected repository-local HTML
was absent. Read-only inspection locates both this slice's book and the prior
carrier slice's book under `../../.artifacts/`, outside the repository.
The helper incorrectly assumed a relative mdBook destination was relative to
`docs/book`; mdBook resolves it against the invocation working directory.
The prior slice's second rendered check read the valid earlier local build,
not the second build's output. The initial local build did verify the same
carrier prose, but the second command's output-locality claim is incorrect.

This current verification repair owns both exact generated directories. Keep
all implementation work in place; copy each exact book into a fresh owned
repository-local recovery directory, verify its complete file/byte/hash
manifest and same-volume identity, then delete only the proven old directory
and census the exact residues. Correct current build commands to derive an
absolute destination at runtime while recording repository-relative output
identity; build into a fresh destination and verify that output. Preserve the
initial failures, correction and manifests in tracked evidence. Do not rerun
spent native producers or remove unrelated `.artifacts` contents. The replay
probe launched before the publisher artifact existed failed at file-open and
performed no HDL compilation; it is not qualification.


## Acceptance Checklist — `.32.1.3.2.2` faithful ISF reset emission

- [x] **ROOT CAUSE (WHY + WHERE)** — At `07f7e8333`, native strict
  `--check --json` rejects the original flat active-low event fixture, while
  ordinary async active-high can pass check and still emit active-low HDL.
  `Scheduler::ISF::Emitter::FSM::_emit_system` chooses only the keyword and
  ignores the parsed polarity. ISF `_n`/`_b` inference also differs from the
  direct FSM strict final-n convention. Retained original HDL fails the
  independent reset-value and event-delivery oracles; successful admission
  alone would conceal the behavior defect.
- [x] **ADDRESSED (verified)** — The emitter retains the resolved policy,
  adding an explicit modifier when defaults or strict naming would lose it.
  Already strict-supported carriers keep their spelling. T1893 proves parser,
  independently checked scheduled carrier and full native/API/newline policy
  equality, including flat/default/opposite-name controls. T1892 applies the
  same independent nonzero-reset/between-edge oracle to direct FSM and ISF in
  SV, Verilog and VHDL. T1894 proves domain/CDC agreement and real events around
  source-only, destination-only and joint resets in both Verilog-family
  targets. T1890 now uses the original fixture and additional reset policies.
  The exact preserved baseline and repaired HDL fail/pass identical oracles;
  the tracked replay reproduces those outcomes from hash-bound retained data.
- [x] **NO REGRESSION** — The RAM-guarded ordinary feature tests report
  `All tests successful. Files=2, Tests=11`; domain behavior reports
  `Files=1, Tests=4`, without skipped providers. The header/reset metadata,
  timing/defaults, domain/activation, output-reset, provenance and full-query
  band reports `All tests successful. Files=9, Tests=58`. Unaffected ordinary
  sync-high/async-low, original dual-event and reset-free HDL remain identical
  after excluding only date headers. A fresh absolute-destination mdBook build
  and rendered contract checks pass; the bounded destination probe confirms
  both CLI path modes and cleans its local fixture. Browser visual review is
  unavailable; full CI/push remains gated.

Re-derivation uses exact original/variant sources, native reports and emitted
hardware. Falsification is the observed before/after reversal in independent
reset and event oracles, flat/name-policy controls, no-reset and unchanged-HDL
controls, and complete transport comparisons. Durability is T1890/T1892–T1894,
the tracked HDL testbenches, `isf-reset-polarity.json` and its replay driver,
updated book/spec/facts and this task. No report-field expansion, reset-tree
glue, generated-top VHDL or broad activation-runtime promotion is implied.

The publication helper's relative-output mistake is root-caused and repaired,
not counted as successful local verification. Both exact misplaced books were
copied, completely hash-verified and consumed before their old roots were
removed; `book-output-recovery.json` retains each manifest and absence census.
The earlier carrier receipt preserves its original command and explicitly
records the corrected attribution. `verify-book-output-locality.py` now
reproduces the path semantics safely inside an owned temporary workspace.
All compiler workspaces in this slice were fresh; spent native producers are
untouched. Development receipts remain separate from the successful final
publication and replay evidence.


### `.32.1.3.4.1` confirmed generated-artifact identity loss

At `f16130a4f`, the public scheduler returns the two domain keys ending in
`__domain_CORE.fsm` and `__domain_core.fsm`. The real CLI `--outdir` writes
only the former path on this case-insensitive volume, and its contents begin
with the latter module's header. The top file is separate. This is observed
artifact replacement, not a failure inferred from a filename resemblance.
`before/materialization.json` and `before/case-pair-public-lower.json` retain
the exact result under `.artifacts/isf-domain-names/`; the controlled filename
probe is removed after confirming the filesystem behavior.

The current generated-name repair owns this immediately alongside the
keyword/child collision: allocate domain module/file names in the partition
and child instance names in the generated top, preserve logical name keys,
route every endpoint through the chosen instance map, and qualify actual
materialized artifacts plus complete public report identity. Both allocation
steps reuse the established portable identifier/case-fold collision policy;
ordinary non-collision output remains unchanged. No submodule is involved.

### `.32.1.3.4.1` qualification failures requiring root cause

The first T1895 run found two failures beyond successful naming admission:
unused public inputs in the suffix-cascade fixture are linked by the top but
absent from the emitted domain ports, and the event-after-activation oracle
misses its first expected event. Preserve the exact initial TAP and generated
reproducers under `.artifacts/isf-domain-names/diagnosis/`; current ownership
includes diagnosis before any closure or fixture adjustment. Establish whether
these are test assumptions or independent compiler defects, create precise
repair ownership for a confirmed independent defect, and never count the
failed behavior as qualification. Existing T1247/T1387 expectations also need
portable `bus_instance` labels; T1387's synthetic private partition must be
replaced with a real public parse/lower input. No production fallback to
reconstructing unallocated names is warranted.

The non-colliding controls reproduce both independent qualification failures.
The callee's emitted FSM returns to its own idle through the done handshake;
the independent event-consumer states have no incoming path from that
component. Unused interface inputs have `+size` entries but no explicit
`+interface` carrier, so top links target ports omitted by signal inference.
Owned repairs are `.32.1.3.4.3` and `.32.1.3.3.1`. The corrected naming fixture
uses consumed suffix-reserving inputs and a separate worker domain; all names
still collide as intended. One intermediate fixture incorrectly used a list
expression in `(on ...)`; its public rejection is a test-authoring error,
corrected to ordinary scalar awaits and preflighted before the final rerun.

## Acceptance Checklist — `.32.1.3.4.1` generated domain identities

- [x] **ROOT CAUSE (WHY + WHERE)** — Real `--strict --check --json` probes
  reject logical `bus`/`BUS`/`interconnect` child labels and domain/event name
  collisions. `_emit_domain_instance` copied logical names while wiring
  reconstructed them independently. Public lower returns case-only domain
  filenames, but the real CLI overwrites one on this case-insensitive volume;
  retained filename/header evidence proves replacement. The audit binds the
  baseline revision, source hashes and exact native/lowering/materialization
  results. This is file loss, not only a theoretical case-fold collision.
- [x] **ADDRESSED (verified)** — `LoweringIR` allocates domain and crossing
  physical identities once using the existing shared keyword/case-fold policy.
  Generated declarations, files, routes and reports consume that partition;
  logical names and public pins remain authored. T1895 passes actual export
  and strict checks for every artifact, complete native/API/newline reports,
  existing-field logical/physical joins, and independent event/reset oracles
  in both Verilog-family targets with no skipped runtime qualification. The
  case-only files both retain their correct distinct contents. No private
  naming map is added to the public schema. Fresh mdBook output passes
  rendered-content checks; browser visual qualification remains unavailable.
- [x] **NO REGRESSION** — `All tests successful` for T1895, `Files=1, Tests=13`,
  and corrected T1247/T1387, `Files=2, Tests=26`. The other selected reset,
  module-header, identifier-policy and T1890 API/MCP checks passed in the
  retained initial regression. Original event, dual-event and no-reset HDL are
  unchanged apart from Date headers. Both changed modules report `syntax OK`;
  task-tree integrity passes. The initial naming fixtures exposed independent
  unused-input and unreachable-consumer defects; non-colliding controls prove
  both, and exact repair leaves `.32.1.3.4.3` and `.32.1.3.3.1` own them.
  Tests, failed controls, source/HDL evidence and the honest isolation boundary
  survive in the audit; none is recategorized as a naming success.

Claim legs: re-derivation is actual public lowering/export and full report
comparison; falsification is the baseline replacement/refusals, unchanged HDL
controls and independent pin-driven behavior, plus retained negative controls;
durability is the tracked audit, tests, knowledge card, book and this task.
Full CI/push and broader multi-clock/runtime qualification remain gated.

### `.32.1.3.4.2` scoped start

Start from clean committed `c5b3caa37`; the commit brief is empty. Query-first
reading found no canonical explicit-input precedence fact. The owning path is
`SameNameLinkBuilder::build_top_input_links`: unlike its top-output peer, it
checks every same-name child candidate before excluding a top input already
owned by an explicit route. `LinkedPlanBuilder::build_plan` subsequently
resolves every explicit endpoint and validates roles, widths, declared types
and duplicate drivers; these checks must remain intact. Preserve implicit
fanout and mixed-family refusals when no top input route exists. Do not broaden
this repair to child-only routing or undeclared/implicit port inference.
Baseline artifacts and bounded checks belong under
`.artifacts/isf-explicit-input-routes/` before implementation.

### `.32.1.3.4.2` independent leading-await watchdog defect

The original source/query cases now pass, but the independent HDL oracle
rejects premature completion on both `ready` and unmodified `work_ready`.
Baseline HDL visibly initializes `worker_wd` in `worker_await_0`, whose timeout
transition simultaneously tests its reset zero. Synthetic `worker_idle_ext`
was added later with no initialization. Exact repair `.32.1.3.3.3` owns this
before broad signoff; preserve the failed TAP and baseline HDL. The routing
qualification must isolate this independent scheduling defect explicitly,
without calling the original leading-await behavior correct.

The ordinary-entry control passes the same independent activation-ready oracle
(`ISF_ACTIVATION_READY_PASS`). Its generated `worker_idle_0` initializes the
watchdog before `worker_await_1`. A leading sample was inspected and rejected
as an isolation control because it folds into the await, leaving the same
initialization hazard. The final routing regression uses the explicit entry;
the original source and non-colliding control retain their recorded failure.

## Acceptance Checklist — `.32.1.3.4.2` explicit input-route precedence

- [x] **ROOT CAUSE (WHY + WHERE)** — `--strict --check --json` rejects an
  original ISF `ready` input and direct C3 composition despite explicit routes;
  the `work_ready` control passes. `SameNameLinkBuilder::build_top_input_links`
  checks an unrelated mixed-direction family before consulting explicit top
  ownership. The corresponding top-output path already skips early. Baseline
  native check/semantic/schedule records bind `c5b3caa37` and exact sources.
- [x] **ADDRESSED (verified)** — The existing explicit whole-top-input
  exclusion now precedes same-name checks. Every original source query passes,
  while `LinkedPlanBuilder` still validates actual roles, widths, declared
  types and duplicate drivers. T1896 compares entire native/API/newline reports
  for successes and malformed-link refusals, independently admits generated
  domain artifacts, and passes a public-pin activation oracle in SystemVerilog
  and Verilog with no skipped runtime checks. Runtime uses ordinary entries;
  the original first-await form remains explicitly unqualified and owned by
  `.32.1.3.3.3`. Fresh book rendering and the complete strict example pass;
  browser visual qualification remains unavailable.
- [x] **NO REGRESSION** — `All tests successful`: builder controls
  `Files=2, Tests=15`; T1896 `Files=1, Tests=8`; existing implicit-port, explicit
  diagnostic, declared-by-name and T1890 controls `Files=5, Tests=22`. Unowned
  same-name families retain their refusals; child-only routes do not claim a
  top input. Original `work_ready` HDL is unchanged except Date headers. The
  changed module reports `syntax OK`. Independent baseline runtime failure
  reports premature completion with no worker observation; emitted watchdog
  initialization/timeout ordering explains it. The failed and passing control
  sources, HDL, commands, logs and producer identities are retained in the
  audit, so no unrelated defect is hidden by fixture isolation.

Claim legs: re-derivation uses real native queries/artifacts and complete API/
newline comparisons; falsification uses malformed links, unowned-family
controls, unchanged HDL, the independent activation oracle and retained
watchdog failure; durability uses the tracked audit/tests/book/facts and exact
repair leaves. No source-expression ownership widening, full CI/push, or broad
activation-runtime signoff is claimed.

### `.32.1.3.4.3` scoped start and shared-path reproduction

Clean baseline `354844fe1019d2db1e413dd54f8c4a5ae9eb398b`; no outstanding jobs.
Knowledge Map queries for ISF unused/explicit interface inputs returned no
canonical repair fact. Read the public interface/spec, generated ATL role
carrier, domain partition/emitter and FSM parser/analyzer before editing.
The RAM-guarded `.artifacts/isf-unused-domain-inputs/capture.py before` reproduces
missing `spare_flag`/`spare_bus` domain endpoints: strict check and semantic
queries fail while schedule succeeds. An ordinary `single_unused` actor passes
strict check, but its nine-bit `spare_bus` is absent from generated HDL and
semantic input analysis. Both paths retain only `+size`, which does not assert
port ownership. This same-locus scope extension is owned here, before repair:
carry declared actor input roles through parent IR, including partitioned
actors, without making inferred internal signals or unrelated child ports public.
Exact sources, reports, emitted artifacts and HDL are retained in the probe;
ordinary strict success is not interface-preservation evidence.

The first repaired T1897 run passed the independent SV/Verilog event oracles
but failed its multi-domain semantic/count expectations: the test omitted the
established generated-top clock/reset inputs. The public report contract in
`docs/isf-spec/22-public-interface-reports-evolution.md` explicitly includes
those pins. Corrected the test expectation without changing production reports;
retain the initial failed TAP alongside the final rerun. The previous session's
post-repair capture was not executed because automatic approval review hit a
usage limit. The director resumed; the same guarded approval path succeeded,
and all before/after capture jobs have now been consumed.

## Acceptance Checklist — `.32.1.3.4.3` declared input preservation

- [x] **ROOT CAUSE (WHY + WHERE)** — Baseline native `--strict --check --json`
  and `--emit-semantic-json` reject unused domain endpoints, while an ordinary
  actor passes but loses its declared vector input in HDL. Schedule still
  counts that input. `LoweringIR::_build_parent_ir` supplies only widths to
  `+size`; the FSM analyzer requires a read or an explicit role to retain the
  input. The existing parser/emitter `+interface` carrier owns that role.
  Exact baseline source, reports, exported artifacts and HDL bind `354844fe1`.
- [x] **ADDRESSED (verified)** — Parent IR retains declared input roles;
  ordinary and partitioned actors emit `+interface` alongside `+size`.
  T1897 passes `Files=1, Tests=6`, with strict real materialization, independent
  artifact admission, authored scalar/vector/symbolic widths and domain
  ownership, complete native/API/newline MCP reports and generated-child
  isolation. SystemVerilog and Verilog public-pin oracles pass without skips
  while unused pins toggle across event transfers and reset controls. The
  used-input control HDL is identical except Date headers. Fresh book render
  and the exact documented source pass; browser visual audit is unavailable.
- [x] **NO REGRESSION** — `All tests successful` for corrected T1330
  `Files=1, Tests=66` and T1215 `Files=1, Tests=100`. The initial selected
  ten-file run passed the other eight files, including public interface,
  domain partition, parameter/constant widths, output defaults/reset, rule
  admission, canonical wiring and activation-route API/HDL checks. T1330's
  exact role lists now include its already-declared start inputs. T1215's
  legacy slash-route expectations fail identically with the committed
  LoweringIR module preloaded from an isolated repository-local overlay;
  corrected canonical `(core.resp resp)` expectations pass. This is a
  changed-module control with unchanged other production components, not a
  complete old-revision export. No unrelated production repair was needed.

The immutable `declared-input-preservation.json` audit retains complete
before/after reports, source/artifact/HDL text, initial/final TAP and producer
identities, including both independently diagnosed stale-test corrections.
The first publisher attempt only misparsed aligned prove-summary whitespace;
it wrote no evidence or book, and the corrected publisher completed normally.
Re-derivation uses actual public queries and materialized artifacts;
falsification uses the missing-role baseline, unchanged used-input HDL,
child-boundary exclusion and independent changing-pin event oracle; durability
uses this owner, tracked tests, audit, synchronized book/spec and fact card.
All verification jobs are consumed. Complete the staged doctrine and normal
commit hooks before starting the watchdog leaf. Full CI/push and historical
startup/native qualification remain gated and are not claimed by this slice.

## Acceptance Checklist — `.33.1` SPECFORGE intake and response

- [x] **ROOT CAUSE (WHY + WHERE)** — Exact caller copies run through native
  `--strict --check --json` and generation at `a7bf398ac`. Unknown port clauses
  succeed with HDL identical to the baseline except Date. `_parse_interface`
  skips malformed shapes and has no final unknown-option refusal. Separate
  `--emit-semantic-json`, schedule and exported FSM controls locate lost
  undriven outputs at missing output roles; literal widths reproduce it and
  a real assignment preserves the output. Actual HDL instantiation proves the
  default-resolved width survives an external parameter override incorrectly.
- [x] **ADDRESSED (verified)** — The existing tracked SPECFORGE response now
  answers the question, states each feature's intended scope and current
  limits, distinguishes optional extensions, and gives execution order.
  `.33.2` through `.33.9` own every requested family and discovered defect;
  `.32.3` remains the distinct derived-width owner. Each implementation requires
  public contracts/reports, API/MCP parity, book examples and appropriate
  independent behavior evidence. This is intake completion, not a claim that
  compiler defects or requested features are already implemented.
- [x] **NO REGRESSION** — Final retained-input replay captures 28 sources with
  zero changed strict-check outcomes. The replay driver rejects absolute,
  escaping, root and existing destinations before output creation. T1414:
  `All tests successful`, `Files=1, Tests=2`. Fresh mdBook build and rendered
  gap/interface markers pass; no interactive visual audit is claimed.

The audit retains complete input identities, reports, HDL and independent
width/output controls. Re-derivation is native capture and local replay;
falsification uses clause-free HDL, literal/driven output controls and actual
HDL width instantiation; durability is the tracked audit, replay driver,
response, task owners, book/spec and canonical fact card. Caller-wide corpus
counts remain unverified. The first book marker probe expected packet/signal
names absent from the authored prose; its build succeeded but the probe failed.
Corrected exact authored markers pass in a fresh build; no product change was
made to satisfy the mistaken probe. All probe jobs are consumed. Complete the
staged doctrine and normal commit hooks before beginning `.33.2`.

The first staged doctrine pass rejected the focused-document collection's
stale growth allowance after the response expanded. The declared allowance
was refreshed from measured usage plus its existing ratchet step, within the
unchanged ceiling and existing live owner. No limit or doctrine was bypassed.

## Scoped implementation — `.33.2`

Activate the shared `_parse_interface` validation repair at clean `5be6a3c08`.
Reject scalar, empty and non-scalar-headed options and unknown option names;
retain recognized-option diagnostics and output metadata semantics. T1898
will exercise public parsing, native default/strict check and semantic/schedule
queries, adapter API and actual newline MCP, plus independent valid fixtures.
Census tracked first-party ISF/PPIF producers through focused corpus admission.
Synchronize interface spec/downstream contract, book, response and fact card;
existing diagnostic envelopes remain authoritative. No new optional syntax.
Startup comparison finds the authorized PGEN claim template byte-identical to
the retained reviewed template; local doctrine remains authoritative. The
local README policy and containment adoption guide are already adopted.
The missing cleanup record requires separately owned maintenance after this
leaf; retained compiler/native-proxy evidence must survive it.

The RED run at the original parser rejects the new test's expectations for
all newly refused shapes. The first repaired run exposed a test-contract
mismatch: schedule API failures intentionally have no selected structured
failure schema (`source_query_failure_policy.schedule`). Native schedule
stderr names the option; API/MCP preserve their bounded message-only refusal.
T1898 now checks that exact boundary and full native/API check/semantic
failure-report parity. No stderr exposure or new schedule schema is added.
The initial sandbox guard refused process inspection before running tests;
the approved guarded invocation supplied it without weakening RAM cutoffs.

## Acceptance Checklist — `.33.2` closed interface options

- [x] **ROOT CAUSE (WHY + WHERE)** — Native `--strict --check --json`,
  semantic and schedule controls reproduced silent acceptance at the two
  `_parse_interface` skip branches and absent unknown-option refusal. T1898
  was run RED before the parser edit; unsupported and malformed shapes
  escaped as actors and successful native/API/MCP queries.
- [x] **ADDRESSED (verified)** — T1898 now reports `All tests successful`.
  Public parsing and native default/strict queries refuse unknown names,
  scalars, empty lists and nested heads. Check/semantic API reports match
  native reports in full after path normalization; actual newline MCP agrees
  with the adapter API. Schedule retains its explicit message-only failure
  contract. Independent expected metadata and valid native/API/MCP controls
  preserve supported output width/reset/default values.
- [x] **NO REGRESSION** — Existing T1476, T1333, T1338, T1353, T1247, T1112
  and T1115 pass for reset/default, symbolic widths, domains and public
  contracts. Parser and contract modules report `syntax OK`. T1414 reports
  `All tests successful`. Fresh mdBook HTML includes the closed-option and
  schedule-failure guidance; no interactive visual audit is claimed.

Re-derivation uses actual public parser/native queries. Falsification is the
pre-repair RED run and independent accepted/rejected option controls. Durability
is the tracked regressions, public contract, spec, book and fact card; scratch
logs are supplementary. No runtime behavior change or new report schema is
claimed. T1899 completes successfully over the catalog-selected supported
ISF/IAL2/profile source population; T1257 and T1259 retain scalar/aggregate
type controls. The first docs-test invocation used an incorrect filename and
ran no tests; the verified T1414 filename then passed. All jobs are consumed.

## Acceptance Checklist — `.34` startup artifact cleanup

- [x] **ROOT CAUSE (WHY + WHERE)** — Startup found the required
  `docs/ARTIFACT_CLEANUP.md` absent; `git log -S 'Latest artifact cleanup'
  over that exact path returns no creation record. Completed `.33.2` renders
  and scratch logs are regenerable from committed tests and source.
- [x] **ADDRESSED (verified)** — Removed only `.artifacts/mdbook-port-options`
  and the session's exact `port-options-` log set (commit, doc-gate, doc-tests,
  doctrines-final, doctrines, final, green, producers, red, types), after
  checking untracked identity, same volume and absence of symlinks. The exact
  deletion list is absent afterward. The bounded cleanup record contains the
  latest UTC timestamp and removal summary. No Rust log/bin deletion was needed.
- [x] **NO REGRESSION** — T1414: `All tests successful`. The retained native
  receipt result directory still exists; cleanup touched no other artifacts.
  Generated focused-document discovery includes the new record. Product
  behavior and mdBook content are unchanged by this maintenance slice.

## Scoped implementation — `.33.9` output preservation

Resume from clean `495e394d1`. The retained intake and input-preservation fact
locate missing output roles in parent `explicit_interface_ports`; the existing
emitter and FSM parser already carry both input/output directions. Extend
authored role preservation without adding assignments or propagating unrelated
parent ports to transaction children. T1900 will retain the positive-width
caller source, literal/driven controls, ordinary/named-domain/multi-domain
outputs, real materialized FSM/HDL inventories and full native/API/newline MCP
parity. Compare declared-spare and absent-spare controls to ensure no invented
drive or changed existing assignments. Run supported backend boundaries and
independent HDL admission where available, plus the existing input/route band.
Synchronize spec/downstream contract, book, response, knowledge and public
interface guidance; keep generic widths and optional presence separately owned.

The pre-repair T1900 RED run loses caller/literal/named/domain outputs and
parent-only child-boundary roles; the driven control passes. The fixed T1900
passes, including independent Verilator named-port and wrong-width controls.
GHDL is absent from PATH, so its optional analysis subtest explicitly skips:
VHDL emission/width/no-assignment checks pass, but external VHDL qualification
is not claimed. `.35` owns the next backend behavior qualification.
The broader band exposed stale T1330 exact interface expectations: resolved
children now also declare their authored `done` output. Update those exact
expected role lists to include `done`; do not weaken them to partial matches.

GHDL follow-up: the Knowledge Map identifies an existing qualified local
provider outside PATH. T1900 now accepts the existing `FSMGEN_RESET_GHDL`
selector, and the provider-backed rerun passes external VHDL analysis without
installing or inspecting dependency implementation. Its earlier skip is not
counted as evidence. T1330 passes with exact output-role expectations. One
broader invocation then stopped at an incorrect book-test filename; the
verified T1376 path and T1112 were run separately and both pass.

## Acceptance Checklist — `.33.9` declared output roles

- [x] **ROOT CAUSE (WHY + WHERE)** — Retained caller and literal controls
  pass native `--strict --check --json` while `--emit-semantic-json` and HDL
  omit AWMECID. Pre-repair T1900 fails for every undriven role path but passes
  the driven control. Parent LoweringIR carries only inputs in
  `explicit_interface_ports`; `+size` alone does not preserve output roles.
- [x] **ADDRESSED (verified)** — T1900: `All tests successful`. Both authored
  directions now reach the existing `+interface` emitter. Caller, literal,
  scalar, named-domain, multi-domain and unrelated-child controls retain exact
  semantic outputs and widths. Materialized FSMs match public lowering; full
  native/API/newline MCP check/semantic/schedule reports agree. No spare-port
  value assignment is emitted. Verilator named-port and wrong-width controls
  plus repository-local GHDL declaration analysis pass.
- [x] **NO REGRESSION** — T1897, T1896 and T1476 pass for input preservation,
  top-route precedence and authored driven reset/default behavior. T1330
  passes after its exact expected child roles add their declared done output.
  T1376 and T1112 report `All tests successful`; the new book example lowers
  and the public contract remains valid. LoweringIR reports `syntax OK`.
  Fresh mdBook build and exact rendered output/reset-only markers pass.

Re-derivation is native lowering/report/HDL generation. Falsification uses the
original RED run, driven controls, exact semantic inventories and external
wrong-width admission. Durability is the retained caller input, T1900/T1330,
public contract, book/spec and canonical output fact. The distinct reset-only
value gap is diagnosed and immediately owned by `.35`; interface presence
does not qualify it. T1899 completes with `All tests successful` for the
catalog-selected supported ISF/IAL2/profile producer population. All jobs
are consumed; no broader runtime claim is inferred from producer admission.

## Acceptance Checklist — `.35` reset-only output behavior

- [x] **ROOT CAUSE (WHY + WHERE)** — The retained reset-only caller passes
  `--strict --check --json` and preserves `+size` reset metadata but emits no
  reset assignment. Pre-fix T1901 fails each direct-FSM/ISF HDL target's driver
  assertions. `AssignmentSupport::build_unified_assignment_analysis` only
  considers captured data-write LHS families. `LoweredRTLIRBuilder` likewise
  drops a family without data-driver blocks or RHS values.
- [x] **ADDRESSED (verified)** — Outputs with an authored reset, no captured
  data writer and an effective hardware reset now use the shared registered
  output plan with feedback default and empty data/RHS/enable lists. The
  existing emitter owns reset kind/polarity and hold logic. T1901 verifies
  exact semantic drive families and complete native/API/newline MCP parity.
  Independent Verilator and GHDL oracles exercise reset-only scalar and vector
  outputs, zero/nonzero resets, synchronous/asynchronous timing, active levels,
  between-edge pulses and post-reset hold. Plain undriven outputs acquire no
  assignment. T1901 reports `All tests successful`; the explicit clock-only
  Verilog no-initialization and VHDL refusal/no-artifact controls pass.
- [x] **NO REGRESSION** — Existing T1892, T1476 and T1900 pass with independent
  runtimes for authored driven resets, idle defaults and retained undriven
  interfaces. T1376 and T1112 pass, including lowering the new book example.
  T156, T170, T1033 and T1392 report `All tests successful`, preserving forward
  IR helpers, public contract serialization and existing register resets.
  Changed implementation modules report `syntax OK`; fresh mdBook HTML
  contains the reset-only example and clock-only boundary. Full CI/push remain
  gated by the existing historical startup/parent qualification owners.

Re-derivation: actual CLI artifacts, semantic drive-family content, API/MCP
parity and selected existing regressions. Falsification: the pre-fix missing
sequential-driver failures, unreset undriven/clock-only controls and independent
simulator assertions distinguishing asynchronous pulses from synchronous
clocked reset. Durability: T1901, shared plan/report changes, public guidance,
book/spec, updated output fact and this task-scoped commit.

The first added clock-only VHDL success expectation was invalid for the
current reset-bearing process subset. Its failure is retained in
`.artifacts/reset-only-final.log`: VHDL rejects the generated state-register
assignment in `_split_if_else_assignments`. `.36` owns clock-only VHDL
completion after the established SV IAL prerequisite. T1901 now explicitly
requires this bounded refusal and absence of an emitted VHDL artifact rather
than claiming clock-only VHDL behavior. Reset-bearing VHDL simulation already
passes. No compiler policy or unsupported-input gate was relaxed.


## Acceptance Checklist — `.37` storage-register-access intake

- [x] **ROOT CAUSE (WHY + WHERE)** — Native `--strict --check --json` and
  `--emit-schedule-json` reject storage-word `access` in `_parse_storage`,
  while field access is accepted by `_parse_actor_storage_fields_option` and
  projected in `inferred_storage[].fields`. The packet requests an additive
  metadata location, not enforcement or changed hardware. Existing scalar
  contract and original caller controls confirm this is a missing feature.
- [x] **ADDRESSED (verified)** — The local audit retains exact request/source
  bytes and hashes, current native reports and complete matching API/newline
  responses. Required scalar R1-R3 are owned by `.38.1`, optional bank R4 by
  `.38.2`, with independent word/field facts and unchanged hardware contracts.
  The existing replay driver gains an explicit storage-access selector and
  reproduces retained inputs without reading the external checkout. Fresh
  replay matches all intake outcomes; existing-directory, path-escape and
  unknown-option refusals preserve the old result. Original mode is unchanged.
- [x] **NO REGRESSION** — `All tests successful` for T1453, T1112 and T1376:
  current field metadata, public interface contract and book examples remain
  valid. Replay Python parses (`syntax OK`); fresh mdBook HTML contains the
  requested-word-access boundary. Task integrity, staged doctrine and hooks
  remain required before commit. No parser or generated-HDL behavior changed.

Claim legs are distinct: re-derivation uses actual current native commands;
falsification uses the accepted baseline/whole-word-field and unknown-token
controls plus API/newline parity and replay refusal controls; durability uses
the tracked packet, replay driver, task scopes and response/book/fact routing.
Missing leg: SPECFORGE corpus quantities and its historical revision results
remain caller-supplied and were not independently reproduced. They authorize
no signoff or capacity claim. The foreign script was read only because its
output paths would mutate the source bundle; local equivalents were used.
The current intake fact also supersedes its stale reset-only gap sentence
with the committed .35 behavior proof, retaining the original diagnosis.


Intake extension: the accepted baseline is not hardware signoff. Its public
schedule labels `status` actor storage, but semantic/HDL classify it as an
input. The retained materialized FSM contains `(status 8 (reset 0))` only in
`+size`; no internal ownership survives into ordinary read/no-write inference.
`SignalAnalyzer::_classify_signal_role` consequently chooses INPUT, and there
is no status reset assignment. The audit retains exact FSM/HDL bytes, hashes
and semantic input entry. Immediate `.39` owns repair before watchdog and
metadata work; `.38` must compare corrected hardware, not preserve this bug.


## Acceptance Checklist — `.39.1` explicit internal roles

- [x] **ROOT CAUSE (WHY + WHERE)** — The retained caller baseline and direct
  `--strict --check --json` probes show no explicit internal ownership carrier:
  the old parser refuses `(internal Q)`, and usage inference exports read-only
  storage. T1902 fails before implementation. Merely retaining CoreAST signals
  also exposed IntentHIR's non-output-as-input assumption; the exact native
  semantic inventory test caught it. A clockless DT reset control separately
  reproduced sequential logic on undeclared `clk`/`rst_n`: AssignmentSupport
  tested the default reset name without checking `declare_ports`.
- [x] **ADDRESSED (verified)** — T1902 reports `All tests successful` with
  qualified Verilator and local GHDL. Explicit internal roles survive parsing,
  classification, typed declarations and semantic/structural port exclusion.
  Independent simulations check synchronous/asynchronous active-high/low
  reset, readback, ordinary writes and hold. Native/API/newline complete
  reports agree; malformed/conflicting roles and system/output-marker
  collisions fail in default and strict modes. Clock-only and clockless
  controls invent no reset or data driver. The operand gate distinguishes
  explicitly authored internals from compiler helpers, retaining declaration
  proof for both. No public report schema was widened.
- [x] **NO REGRESSION** — T1901, T1897, T1900, T172, T279 and T338 each
  report `ok` for existing resets, interface preservation, typed declarations
  and semantic contracts. The focused run's old T1902 clockless failure is
  superseded by the final T1902/T269 `All tests successful` run after the
  operand-gate fix. T521/T1889 also report `All tests successful`, preserving
  expression and authored diagnostic contracts. T269 retains undeclared and
  unassigned generated-helper rejection. T1376 and T1112 pass;
  the new direct book example separately passes strict native check, and the
  rendered mdBook contains the role section and example. Browser visual
  qualification remains blocked under its existing owner.

Re-derivation: real direct CLI emission and complete semantic/API/MCP reports.
Falsification: original parser refusal, exact port sets, independent HDL
reset/write/hold oracles, role contradictions and missing-hardware-reset
controls. Durability: T1902, shared parser/planners/report filter/operand gate,
book example, updated canonical role fact and this owning task-scoped commit.
The first compound assignment fixture was corrected to separate canonical
assignments. The report oracle now checks data ports separately from system
ports, matching the existing public schema; structural ports check both.
The initial clockless control exposed the generated-helper-only assumption
in the operand gate. The explicit-source exception does not bypass its
undeclared-operand check or relax generated-helper producer requirements.


## Acceptance Checklist — `.39.2.1` ordinary/domain storage ownership

- [x] **ROOT CAUSE (WHY + WHERE)** — A fresh `--strict --emit-semantic-json`
  replay of the exact retained SPECFORGE baseline at 4447ca7a0 reports input
  `status` alongside `start` and `wdata`. Parent LoweringIR preserves storage
  widths/reset metadata but emits explicit roles only for public ports;
  read-only usage inference therefore overrides the actor-storage identity.
  The direct internal carrier exists after `.39.1`, but the ISF producer does
  not use it. Domain partitions share that parent construction path.
- [x] **ADDRESSED (verified)** — Final T1903 reports `All tests successful`.
  Parent/domain LoweringIR carries explicit internal names independently of
  public port metadata, and the FSM emitter serializes those roles. Exact
  retained baseline/whole-word-field sources, nonzero and unreset variants,
  unused typed scalars, bank elements and named/multiple domains all qualify.
  Direct FSM replay and complete native/API/newline reports agree. Independent
  Verilator and GHDL simulate ordinary CSR reset/write/readback/hold; both
  Verilog targets also simulate the generated domain composition top and
  domain-local readback. Generated-child role production is unchanged.
- [x] **NO REGRESSION** — `All tests successful` for T1232, T1236, T1247,
  T1259, T1260, T1261, T1262, T1398, T1453 and T1112: existing scalar/bank,
  domain, typed aggregate, reset, field metadata and public contracts hold.
  T1376 and T248 also report `All tests successful`, checking the new book
  example and support-accounted public corpus. Fresh mdBook HTML contains the
  storage-readback example and precise reset boundary; browser visual audit
  remains under its existing blocked owner. Full CI/push remain gated.

Re-derivation: exact retained caller inputs through real native CLI, direct
materialized FSM replay, API and newline MCP. Falsification: exact external
interfaces and independent CSR reset/write/read/hold oracles, nonzero and
unreset controls, unused typed signals, bank elements and domain isolation.
Durability: T1903, parent/domain role production, book/spec/response and updated
canonical intake fact, followed by this task-scoped commit.

The first T1903 run passed ordinary cases and independent Verilator/GHDL CSR
behavior, but made invalid assumptions about composed report placement. The
actual multi-domain contract is retained: the composition top includes system
ports, owns no internal storage or flattened inferred_storage detail, and
clock_domains[].storage lists each domain's owned names. The corrected oracle
checks those locations and semantic child data interfaces without adding a
report schema. Detailed field metadata is compared on ordinary actor reports.
Generated transaction-child adoption remains separately owned by `.39.2.2`;
its copied declarations are not newly marked internal in this slice.


## Evidence and selection — `.39.2.2.1`

`docs/audits/generated-child-storage-ownership-20260926.json` retains the exact
accepted reader/writer sources, strict-check reports, emitted FSM/HDL, direct
worker semantic report, independent testbenches/runners and simulator output
from a929fe719. Both strict checks succeed and both Verilator compilations
succeed. Both behavioral assertions fail: the reader observes external 73
instead of parent-written 53, and the parent observes reset 19 instead of
child-written 37. These are deliberately failing reproduction oracles, not
passing regression or maturity claims. Source/artifact SHA-256 records and
JSON structure are checked before commit.

Root cause is separate state/no handoff in LoweringIR::_build_child_ir and
CompositionTop. Read-only inference creates the worker input; PlanBuilder and
TopPortInferenceBuilder::augment_undeclared_top_inputs legitimately extend the
generic composition top, so ISF's missing ownership route leaks externally.
Fresh per-module SignalManagers disprove the initially considered attribute-
leak explanation. Initial malformed/unbound reader probes were corrected to
canonical explicit transaction output bindings before capturing admitted cases.

Decision 0107 selects the faithful single actor/domain owner, live reads,
original-edge writes, no hidden completion latency, no copied unrelated state,
and explicit writer arbitration. `.39.2.2.2` owns live reads and interim writer
refusal; `.3` owns sole-writer full-width scalars; `.4` owns wider updates and
competing writer prerequisites. The book now states the actual known boundary.
This slice closes diagnosis/contract selection only; implementation remains open.

Claim legs: re-derivation is public strict check/semantic/artifact capture;
falsification is the independent runtime value distinction; durability is the
tracked receipt, decision, current guidance and scheduled repair children.
No caller corpus coverage or cross-domain writer support is inferred.

Containment prerequisite: the rationale collection rejected this append at its
owned rollover allowance. No allowance or ceiling was raised. Duplicated
summary narration in decisions 0055/0056 was replaced with pointers to the
unchanged full contracts in the same files. The preservation receipt is
`docs/audits/decision-summary-compaction-20260926.json`; source revision and
before/after hashes bind the review, while exact suffix comparisons prove
all detailed contract and execution-status bytes remain intact. Index 0107's
summary was shortened without changing membership. This is duplicate removal,
not archive or deletion of recorded contract facts; rollover debt remains owned.

- [x] **ROOT CAUSE (WHY + WHERE)** — Native `--strict --check --json`
  succeeds for both retained child cases; independent Verilator execution
  fails the expected-value assertions. LoweringIR copies storage without a
  shared ownership route; generic composition infers the dangling read input.
- [x] **ADDRESSED (verified)** — Diagnosis is bound to exact sources, HDL,
  reports and failing runtime oracles in the tracked audit. Decision 0107 and
  the ordered repair leaves select and own the fix; no behavior repair is
  claimed here. JSON/hash checks and exact contract-suffix comparisons pass.
- [x] **NO REGRESSION** — `knowledge-map: OK` from the registered gate;
  mdBook build and rendered known-boundary markers pass. Source implementation
  is unchanged. Both detailed decision contracts and execution-status blocks
  compare byte-for-byte after duplicated summary removal.

## Qualification — `.39.2.2.2.1`

The bounded read slice uses `ChildStorageOwnership` to walk emitted operands,
keep actor storage/register/reset ownership in the parent, and construct one
collision-safe combinational read handoff per used signal with per-instance
links. Unrelated declarations disappear from child storage. Authored transaction
ports remain explicit; copied actor inputs are retained only when read. The
parent's assignment provenance is rebuilt only when a new handoff exists.

Qualification split the parent `.39.2.2.2` after discovering two independently
owned composition defects: duplicate aggregate typedefs and omitted domain
child artifacts. This slice refuses those unqualified read combinations and
shared child writers. `.40` repairs single-member type normalization next;
`.39.2.2.2.2/.3` then qualify aggregate and multi-domain composition before
`.39.2.2.3/.4` qualify original-edge writes and arbitration. No unsupported
combination is counted as a runtime pass.

T1904 covers post-spawn parent updates and repeated activations in independent
Verilator simulations for scalar, signed scalar type and bank reads. Separately
generated owner/child VHDL is wired by an independent GHDL testbench; this does
not promote the wider generated-composition VHDL scope. Other controls cover
expression/guard-only reads, dynamic banks, a named single domain, generated
name collisions, local state, explicit payload bindings, multiple readers,
unused declarations, literals, exact public ports and materialized FSM replay.
Native check/semantic/schedule and API/newline routes are compared completely.
Rejected check/semantic cases preserve public failure reports; schedule keeps
its existing generic non-report error envelope, with no fabricated result.

The typed-reset falsifier also identified an undefined literal-width warning
and an accepted overflowing reset after named-type resolution. The parser now
checks integer bit length after every storage width resolves. T1904 uses zero,
maximum-fitting and overflowing values across literal/type/parameter/constant
widths; the numeric book sentence has a three-leg derived-gate disposition in
the canonical general-book claim group. Reset prose now consistently says
hardware reset, including the CSR example comments, rather than power-up.

Earlier test failures were acted on: the input filter needed emitted guard
operands; the public multi-form parser must be assigned in scalar context before
normalization. Direct scanner probes distinguish dynamic index reads, numeric
literal suffixes and state_active identities. T1241/T1248 payload fixtures now
use local sinks instead of depending on the old private actor-storage copies.
The original admission-only expectation for a sliced set was corrected to its
existing earlier scalar-target diagnostic. Scope/refusal controls are explicit.

- [x] **ROOT CAUSE (WHY + WHERE)** — Retained native `--strict --check --json`
  and independent runtime evidence prove the original exported read/private
  write defect; new controls isolate copied declarations, inferred interfaces,
  expression-context loss, and reset validation before width resolution.
- [x] **ADDRESSED (verified)** — T1904/T1241/T1248 report `All tests successful`
  with qualified Verilator and GHDL enabled. Exact public interfaces, complete
  report parity, live/repeated reads and reset-fit boundary controls pass.
- [x] **NO REGRESSION** — Broader T1232/T1236/T1247/T1255/T1900/T1397/T1391/
  T1376/T1112/T1262 reports `All tests successful`; mdBook builds and rendered
  scope markers match. Knowledge Map, inventory and disposition checks pass.
  The mandatory staged doctrine gate and commit hook remain required.


## Qualification — `.40`

Public Lispish calls confirm distinct layouts: raw record bodies wrap their
member sequence, while the ISF adapter returns a flat sequence. The shared
canonicalizer and dependency walker unconditionally expand a sole array body,
splitting a normalized member or structured list item. This is a caller-layout
contract mismatch, not a defect in the submodule parser. Explicit layout must
flow from the ISF package-resolution call to both shared consumers; preserve
raw direct/package/composition parsing, including aliases named like type
constructors, without shape guesses. The first public negative parity test exposed Carp stack frames and process-specific
addresses in the package type-cycle diagnostic. Own the contextual type-cycle
and malformed-spec failure paths in this slice: end expected input errors with
a newline and omit internal stack traces, then prove complete negative parity.
Regression controls own single, nested,
forward-reference, multi-member and malformed/cyclic types here.

- [x] **ROOT CAUSE (WHY + WHERE)** — Native `--strict --check --json` rejected
  the retained single-record actor with malformed +types. Public Lispish and
  adapter outputs isolate wrapper-versus-member expansion in both shared
  consumers; negative report comparisons identify process-specific Carp frames.
- [x] **ADDRESSED (verified)** — T1905 reports `All tests successful`: exact
  independently specified type shapes match ISF parsing, direct generation and
  scheduled replay; complete native/API/newline positive and negative reports
  agree. Imported raw packages coexist with normalized local types.
- [x] **NO REGRESSION** — T279/T280/T281/T285/T1257/T1259/T1260/T1261/
  T1262/T1376 report `All tests successful`, including the new complete book
  example. mdBook builds and rendered example markers match.


The initial broader command referenced nonexistent test filenames; corrected
paths were enumerated before the signoff rerun. The mdBook destination was
interpreted relative to invocation, creating output outside the repository on
the same volume. The exact generated output was copied into the repository,
all file hashes compared, and the misplaced output plus its empty task directory
removed. No external output remains; the qualified HTML lives under
`.artifacts/aggregate-layout/book`. No visual-browser claim is made.

Claim legs: exact parser/type/replay comparisons re-derive aggregate identity;
malformed/cyclic and constructor-named alias controls falsify over-flattening
or shape guessing; T1905 and the new Knowledge Map card preserve the evidence.
The already owned aggregate composition refusal remains in place. No wider
backend or shared-child aggregate runtime qualification is claimed here.


## Qualification — `.41`

A maintained-ISF census finds reset/power-up conflation in the feature matrix
and local-variable chapter. The actor-interface chapter already distinguishes
hardware reset from pre-reset initialization. This slice aligns the remaining
prose/comments with that qualified contract, preserving the same examples and
all actual reset/default behavior. The canonical output/internal-role fact and
T1901/T1902 own behavior evidence; a wording-only fix does not claim new HDL
support. Validation: the terminology census retains only explicit statements
distinguishing reset from power-up. Executable fenced examples compare exactly
after comment removal. mdBook builds in a fresh, root-derived local destination;
rendered matrix/local-variable text matches the corrected reset contract.
Claim inventory/dispositions and staged doctrine gates remain commit requirements.

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'its power-up state'` traces
  the local-variable wording to `4d425d36c`; `git log -S 'register powers up'`
  traces matrix wording to `92b1155c5` and `14ad74179`. Those reset-value docs
  describe reset-block assignments but incorrectly equate them with power-up;
  the qualified actor-interface contract explicitly excludes that guarantee.
- [x] **ADDRESSED (verified)** — The maintained ISF census now finds power-up
  only in explicit distinctions from reset. Fresh rendered chapter/matrix
  markers agree, and executable fenced examples are unchanged after comments.
- [x] **NO REGRESSION** — The current registered gate reports `knowledge-map: OK`
  and `readme-entrypoint: all README entry-point invariants hold`; claim census
  and dispositions pass. No compiler, example semantics or reset logic changed.

## Qualification — `.39.2.2.2.2.1`

The public canonical C2 reproducer strict-admits distinct reader modules and
an aggregate top, but the retained pre-repair HDL fails Verilator with duplicate
`frame_t__fsmgen_t` declarations. Both scaffold and structural emitters put
port types at compilation-unit scope; their alias-only allocators previously
knew only the local module. The fix passes actual module identity into the
shared typedef state and prefixes names with an unambiguous length-delimited
module identifier. Existing local alias sanitization/collision handling remains.
Internal and port declarations share state; Orchestrator resets it per emission.

T1906 independently compares packed output values for distinct equal/different/
nested record/list types, verifies unique global typedef identifiers, reuses a
pipeline, probes namespace/alias delimiter collisions, and rejects same-width
incompatible semantic types. Existing emitter tests retain exact alias suffix,
shape, field, port and carrier assertions while accepting the private module
prefix. No text deduplication or semantic type erasure is used.

The initial source used legacy links/assignments and then a single generated
child; strict mode and the documented C2 minimum rejected those probes. The
canonical multi-child source is the reproducer used for HDL diagnosis. Reusing
one child source then exposed duplicated module bodies; `.42` owns the verified
assembly cause and is immediate after this commit, before aggregate read
qualification. Distinct modules isolate the current typedef repair. The ISF
aggregate read refusal stays in place until `.39.2.2.2.2.2` qualifies routing.

- [x] **ROOT CAUSE (WHY + WHERE)** — Native `--strict --check --json` admits
  the canonical source; retained pre-repair Verilator output reports duplicate
  frame_t__fsmgen_t declarations from distinct modules. Both port emitters
  publish local-allocator names at compilation-unit scope.
- [x] **ADDRESSED (verified)** — T1906 passes with qualified Verilator runtime:
  composed equal/different/nested type channels retain independently driven
  packed values, global names stay distinct, and incompatible types still fail.
- [x] **NO REGRESSION** — T280/T282/T281/T1905 report `All tests successful`;
  T114/T167/T198/T288/T1321 and the new runtime test pass. The only initial
  failures were incorrectly escaped namespace regex updates in T280/T282;
  their corrected assertions preserve alias/shape checks. Fresh mdBook output
  contains the scoped example and semantic-compatibility explanation.


## Qualification — `.42`

The realized-instance plan retains each instance's complete generated HDL;
GenerationOrchestrator concatenates all payloads, even when module identity is
shared. Collect definitions at that realized-artifact boundary: preserve every
instance/provenance/binding, emit the first definition per module, and require
later definitions to agree. Ignore only the known generated scaffold header's
informational Date line for comparison; retain the emitted first payload
unchanged. No global text deduplication or arbitrary comment normalization is
allowed. Conflicting same-name definitions and collisions with the generated
top fail explicitly. VHDL name comparison remains case-insensitive.

- [x] **ROOT CAUSE (WHY + WHERE)** — Native `--strict --check --json` admits
  repeated sources; retained Verilator output reports MODDUP and duplicate
  typedefs after each realized instance contributed the same full module to
  GenerationOrchestrator child_segments.
- [x] **ADDRESSED (verified)** — T1907 proves one emitted definition, both
  instance records, independent scalar/aggregate/parameter runtime, preserved
  worker-local values and complete check/semantic/schedule API/newline parity.
  Definition/top-name conflicts fail contextually. The unchanged completion
  expectations remain explicit `.43` TODOs; they are not runtime passes.
- [x] **NO REGRESSION** — T1907/T189/T292/T1906 report `All tests successful`
  with only the explicitly owned `.43` completion TODOs. T114/T281 also report
  `All tests successful`; mdBook builds and rendered reuse/limitation markers
  match the qualified scope.


The `.43` trace establishes a separate lowering defect: independent child
results are correct, but their completion pulses occur on different edges and
the parent sync predicate is their raw conjunction. T1907 retains the exact
normal/repeated-completion expectations under an explicit `.43` TODO, with a
separate passing timed observation of independent worker-local results. No
completion qualification is claimed by `.42`. `.43` is the immediate next leaf
and must remove the TODO only after the original runtime oracle passes.


## Qualification — `.43`

Keep generated child done outputs as pulses. Parent/domain join lowering owns
completion-seen state for the generated instances actually consumed by sync_all
or sync_any. Clear a seen bit on its instance's next start, capture done when
not starting, and expose live-done OR seen to join predicates. Preserve raw
handoff metadata, make the generated storage/view internal and collision-safe,
and rewrite already-materialized dynamic-wait predecessor guards as well as
ordinary sync predicates. A live last completion must allow the existing exit
edge without adding a latch cycle. The original T1907 completion assertions
must pass with their TODO removed; qualify staggered/early/simultaneous pulses,
rearm/reset, any-then-all observation, dynamic waits and ordinary binding/API
contracts before closing this leaf.

- [x] **ROOT CAUSE (WHY + WHERE)** — Native `--strict --check --json`
  admits T1907 while the retained independent trace shows staggered done pulses
  and a parent stuck in the raw-AND join. Ordinary multi-pending await_any also
  cleared the pending set before its later drain, unlike repeat lowering.
- [x] **ADDRESSED (verified)** — T1907's original completion/repeated-activation
  oracles pass without TODOs. T1908 independently drives early, staggered and
  simultaneous completion, checks reactivation/reset, any-then-all, private
  collision-safe storage, raw metadata and unchanged live completion latency.
  Zero/odd dynamic-wait joins pass; `.44` owns the proven even-count defect.
- [x] **NO REGRESSION** — T1908/T1907 plus sync, dynamic-wait, loop/repeat,
  binding/trigger and book-example regressions report `All tests successful`
  in `.artifacts/completion-memory/focused.log`. A fresh mdBook build renders
  completion retention and the scoped dynamic-wait limitation accurately.

The `.43` independent parent test also proves that ordinary transaction and
branch/loop lowerers cleared their pending set after multi-child await_any,
so a later await_all had no operands and advanced prematurely. The repeat
lowerer already retains that set. Apply the same observe-versus-drain rule
through all sync collection paths under this leaf and preserve raw metadata.
A positive even dynamic-wait count additionally timed out after a completed
join. Investigate its generated counter-load predicate before making a claim
about nonzero-count coverage; this finding remains owned by `.43` until its
root cause and appropriately bounded repair are established.

The dynamic-wait root cause is now reproduced in generated HDL: the load and
entry enables use a bitwise conjunction of scalar completion-ready values
with the multi-bit count itself. Count 4 has a clear low bit, so neither entry
nor zero bypass fires. This pre-existing predicate defect is owned by `.44`,
immediately after `.43`. The completion-memory slice qualifies zero and odd
counts only; it does not claim general dynamic-wait correctness. Retained
pre-repair source, scheduled FSM, HDL, test and runtime failure live under
`.artifacts/completion-memory/`; tracked `.44` acceptance recreates the case.

Final compatibility qualification: T1904 independently passes the retained
scalar/bank storage readers in SystemVerilog and VHDL. Existing composition,
port-binding, lifetime and storage-report tests pass. T1215/T1315 initially
failed only their exact old raw-done join/DT inventory expectations; updated
expectations retain every source/binding/provenance assertion and explicitly
include the private child_completion blocks. Their rerun reports
`All tests successful` in `compatibility-updated.log`; T1908 region coverage
and T1255 schedule golden checks also pass in `regions.log`. No original
completion assertion remains TODO. Full CI is reserved for the push gate.


## Qualification — `.44`

The preserved completion_dynamic source lowers wait cycles after sync_all to
completion_ready AND cycles in both counter-load and entry predicates.
A scalar true AND even multi-bit count is zero under the DSL's bitwise
operator. `_link_dynamic_wait_entry_edge` owns every dynamic wait predecessor
and recursively carries zero paths through consecutive waits. Convert only
the count's predicate use to explicit nonzero; preserve the sampled RHS and
count-source report metadata. Qualify the complete bounded runtime count range,
entry/await/sync/consecutive paths, expression counts and sampling before
closing the leaf. Existing exact scheduled-FSM expectations must express the
new boolean predicate without weakening transition or count assertions.

- [x] **ROOT CAUSE (WHY + WHERE)** — Native `--strict --check --json`
  accepts T1909 count_entry, but pre-repair HDL ANDs the multi-bit count with
  a scalar predecessor condition; the retained count-4 join stalls. The count
  load/entry guard is constructed in `_link_dynamic_wait_entry_edge`.
- [x] **ADDRESSED (verified)** — Explicit nonzero predicates preserve the
  sampled RHS and reports. T1909 independently verifies the declared scalar
  range, consecutive pairs, expressions, awaits/branches and post-entry input
  changes in SystemVerilog. Complete native/API/newline reports agree. T1908
  now passes the original even-count join case. VHDL analysis remains an
  explicit `.45` TODO with its unchanged runtime oracle, not a timing pass.
- [x] **NO REGRESSION** — Focused T1244/T1308/T1331/T1359/T1369 and book
  examples report `All tests successful` in `lowering.log`. Exact positive
  guards now expect boolean nonzero while zero/sample/state/report assertions
  remain intact. T1908 and T1255 pass in the qualified log; `.45` separately
  owns its VHDL analysis failure.

The additional independent GHDL check exposed a separate backend type error:
T1909's scalar-count entry actor emits a vector wait counter compared against
scalar `'1'` for both greater-than and equality. GHDL cannot analyze these
operators. `.45` owns the immediate repair after `.44`; the original analysis
and bounded runtime assertions remain in T1909, with only the known analysis
failure explicitly marked TODO until fixed. `.44` earns SystemVerilog timing
and public report parity, not VHDL runtime qualification. This is separate
from the boolean nonzero count-entry repair, whose predicate itself analyzes.


## Qualification — `.45`

The direct VHDL backend renders the scheduler's unsigned vector counter
against a scalar one-bit literal. Its concurrent-assignment wrapper recognizes
only `==` as boolean; greater-than therefore also attempts to drive std_logic
with a boolean. `_sv_condition_to_vhdl` similarly detects boolean comparison
results through `=` alone. Repair comparison-result handling for supported
comparison operators and contextualize known one-bit binary constants against
unsigned vector operands in either operand order. Preserve literal width and
signedness outside that proven conversion; do not narrow counters or invent
scheduler cycles. Qualify GHDL timing and direct comparison truth tables,
including equality/inequality, relational directions and scalar controls.

- [x] **ROOT CAUSE (WHY + WHERE)** — T1909 native `--strict --check --json`
  accepts the runtime-wait actor, while GHDL rejects vector counter comparisons
  against scalar literals. Direct backend result wrapping covered concurrent
  equality only. T1910 additionally proves DATA=2 incorrectly fails comparison
  with the wider literal 16 under unequal-length vector ordering.
- [x] **ADDRESSED (verified)** — T1909's original GHDL count/snapshot oracle
  now passes without TODO. T1910 passes independent integer truth tables for
  all selected comparison operators, both operand orders, narrow/wide/equal
  literals, scalar controls and wider result destinations. Shared expression
  emission preserves typed logic results; unsigned operands extend to their
  common width without truncating the literal.
- [x] **NO REGRESSION** — T1910/T1909/T1420/T1543 report `All tests successful`
  in `.artifacts/vhdl-wait-comparisons/focused.log`; the added wider-result
  control also passes in `typed-results.log`. T1543's original reduction
  expectations remain intact after correcting the first implementation's
  redundant coercion. Native/API/newline reports still agree in T1909.

T1910's direct comparison controls additionally expose procedural assignment
results passed through as VHDL booleans into std_logic outputs. The same
comparison-result conversion must cover procedural RHS emission, with typed
zero/one results for the destination. The first test source incorrectly grouped
multiple assignments inside one `=` action and was rejected before backend
qualification; the corrected source uses one canonical action per assignment.
T1543 caught redundant boolean coercion of existing reduction conditions;
restore their converted-equality recognition before closing this slice.

After result typing, T1910 GHDL runs and exposes a numeric mismatch:
`DATA < 8'h10` is false at DATA=2 because unequal-length std_logic_vector
comparison is lexicographic without unsigned extension. This is the same
comparison operand-normalization boundary, now proved at runtime. Extend the
smaller operand to the maximum unsigned operand width, in both orders, and
preserve exact literal validity before padding. Include narrow, wide,
equal-width, reversed and scalar controls in this leaf's truth-table gate.

The final book adds explicit operand/result-width examples. The general-book
claim-disposition gate required fresh reviewed entries for those source-line
identities. `.45` owns the updates under the registry's mandated general-book
owner: re-derive from the backend's typed width normalization, falsify with
T1910's independently executed integer truth table and observed pre-fix
DATA=2/16 failure, and retain the tracked test plus source-identity disposition
watcher. No numeric example was removed or exempted to evade the gate.

Claim-registry serialization initially escaped existing non-ASCII strings in a
form different from the checker canonicalization. During that correction,
existing records published-46a796038b0326b4f51a4995 and
published-572ce6362e69a3a37290e40e revealed a misencoded multiplication symbol
in their historical competing-hypothesis formula. This slice owns that small
registry-text correction: use the unambiguous ASCII N*body+2 spelling, retain
the meaning/evidence/owners, and serialize the registry canonically.


## Qualification — `.39.2.2.2.2.2`

The module typedef, definition reuse, completion-lifetime and runtime-wait
repairs are committed. Qualify aggregate actor storage over the existing live
read handoff, preserving its type on parent outputs and child inputs while
keeping authored ISF ports scalar. Exercise one-member/multi-member records,
lists, nested types and scalar leaves, simultaneous different storage types,
reused child instances, post-spawn parent updates and repeated activations.
The owner alone retains reset/state. Remove only the aggregate read refusal;
keep the separately owned multi-domain realization and direct writer refusals.
Use independent runtime, scheduled replay and complete native/API/newline
reports, then update composition spec, downstream response, book and facts.

- [x] **ROOT CAUSE (WHY + WHERE)** — Retained native `--strict --check --json`
  in `.artifacts/aggregate-child-reads/before-check.json` rejects the record
  source at ChildStorageOwnership's explicit aggregate qualification refusal.
  The typed read selection/connection path already preserves aliases and owner
  state after the committed prerequisite repairs.
- [x] **ADDRESSED (verified)** — Removing only that refusal makes T1904's record
  case and T1911's packed/leaf runtime controls pass. T1911 checks independent
  Verilator observations after owner updates and repeated activation, reused
  worker instances, simultaneous different aliases, exact interfaces/reset
  ownership, strict scheduled replay and complete native/API/newline reports.
- [x] **NO REGRESSION** — T1904 reports `All tests successful` in
  `.artifacts/aggregate-child-reads/storage-baseline.log`; T1911/T1905/T1906,
  T280/T1260/T1262 report `All tests successful` in `focused.log` in that
  directory. The updated book example lowers in T1376; mdBook builds and the
  spec partition gate passes. Existing writer/domain refusals remain tested.

The first nested-leaf fixture tried implicit widening into its packed-root
width. The strict operand contract correctly rejected it. Aligning the output
with the leaf width preserves that contract and passes the original independent
packed-layout expectation. No widening rule was changed.

This slice also owns a discovered stale composition-spec sentence: it still
specified joins over raw done pulses after `.43` qualified retained completion.
The spec now matches the implemented live-or-retained predicate and start-clear
priority. Runtime coverage remains T1908; no scheduler behavior changed here.
Book/type/spec/intake/fact updates distinguish internal generated aggregate
handoffs from still-unsupported authored aggregate ports and banks. Live-doc
budget deltas belong to this leaf and preserve their existing hard ceilings.


## Qualification — `.39.2.2.2.3.1`

Split domain child realization from storage-read admission so both have bounded
runtime qualification. The lowerer constructs child IR but the multi-domain
artifact loop drops it; the top has no matching child instances or wiring.
T1247's artifact inventory codifies this omission rather than a runtime result.
Reuse the ordinary generated-child wiring contract at the flat outer top,
with allocated module/file/instance identities and each owning domain's clock
and reset. Preserve CDC endpoint sources when children inherit domain inputs.
The same artifact loop also omits library children; inspect its supported
public domain-use contract and include or explicitly schedule that defect,
without claiming unseen library behavior qualified.

- [x] **ROOT CAUSE (WHY + WHERE)** — Retained native `--strict --check --json`
  accepts `before.isf` in `.artifacts/domain-child-realization/`, but its emitted
  top and artifact map omit worker. The domain loop emits parent IR only.
  T1912 additionally measures an extra generated-do payload pulse: held start
  re-enters the child after terminal, before delayed done reaches the caller.
  Domain signal lookup also wrongly chooses an actor signal before a local port.
- [x] **ADDRESSED (verified)** — T1912's final `runtime-identities.log` passes
  independent dual-domain spawn/do execution, exact output-pulse counts, reset
  isolation, repeat activation, CDC-ready routing, module/pin collisions,
  reset absence, strict scheduled replay and complete native/API/newline
  check/semantic/schedule parity. Physical semantic sources join to emitted
  artifacts. Private start history fixes reexecution without an extra state.
  The child-await oracle remains TODO under its existing watchdog owner;
  `.46/.47` retain named-completion/library refusals, not runtime passes.
- [x] **NO REGRESSION** — `focused-final.log` reports `All tests successful`
  for T1216/T1217/T1241/T1242/T1247/T1315/T1424/T1426/T1427/T1387.
  `completion-runtime.log` reports `All tests successful` for T1907/T1908.
  T1904 and T1911 individually report `ok` in `activation-runtime.log`, including
  the qualified scalar/bank VHDL controls. T1376 passes and mdBook builds;
  spec partition validation passes. All logs are under
  `.artifacts/domain-child-realization/`.

The scalar/aggregate invocation accidentally named a nonexistent T1907 filename
after its valid T1904/T1911 entries. Those entries completed successfully;
the harness then exited with a source-discovery error, so that invocation is
not described as an overall green gate. The correctly discovered T1907/T1908
invocation separately passed. No test assertion was waived for that typo.
The final local-port runtime control uses a fully bound auxiliary data port
shadowing core's data input; an earlier local-done specimen also needed an
explicit activation binding and was not used as the positive qualification.
Live-document budget deltas and generated knowledge/inventory updates belong
to this leaf without raising hard ceilings.

The first T1912 runtime fixture used activation overrides of wait-count parameters;
that separately deferred surface correctly refused before composition. The
fixture now uses supported non-wait parameter overrides. It then exposed named
child completion: the auxiliary worker's aux_done output is unconnected and its
canonical done handshake has no authored pulse. `.46` owns that independent
ordinary/domain repair immediately after this realization slice. Retain the
original named-completion source and exact refusal in T1912; qualify realization
with explicit transaction-local canonical done ports in the meantime.

The explicit local done control exposed a smaller blocking validator defect:
`_validate_domain_signal_access` chooses an actor signal before a same-name
transaction-local port. The aux worker's local done output therefore gets
misclassified as a write to core's actor done output. This leaf owns local-port
precedence in that lookup, matching the existing child-port/storage shadowing
contract. Preserve true unowned-crossing refusals in T1247 and the effect-domain
regressions; T1912 is the positive same-name local-port runtime falsifier.

The broader library regression T1238 exposed a pre-existing retained-parent-port
mismatch: the ordinary library top skips its parent data_in connection even
though explicit interface preservation now declares that port. `.47` owns the
ordinary/domain repair immediately after `.46` and before domain storage reads.
The library child artifact is no longer omitted by domain emission, but this
slice does not claim library-composition admission/runtime. Keep T1238 unchanged
and retain the exact multi-domain FIFO refusal in T1912.

T1912's first runtime expected a generated-do output binding to remain asserted
until the later parent completion pulse. The published contract instead emits
that binding as combinational data gated by child done. Its independent oracle
now samples the payload on the receiving clock during that valid pulse, then
checks parent completion separately; no RTL rule changes.

The CDC-await child reproduces the already-owned `.32.1.3.3.3` watchdog entry
failure: its generated entry goes directly into the await, where an uninitialized
watchdog can take the timeout path before the event arrives. T1912 retains the
original runtime oracle as explicit TODO under that owner. Flat CDC-boundary
routing is separately qualified by a fixed-wait child reading the source CDC
ready endpoint, followed by the parent's event crossing. This slice earns no
child-await watchdog timing signoff.

T1912's measured repeated-do oracle observes an extra auxiliary payload pulse.
The generated do parent holds start high until done; the child returns to its
start-guarded idle before its delayed done pulse reaches the parent, so it
accepts the same held start again. This leaf owns that blocking activation
lifetime fix: accept an assertion of start only once, rearm when start is low,
and reset the private start history with the child's own reset. Preserve the
existing state sequence, accepted start edge and done timing. T1912's original
exact payload count stays unchanged; ordinary pulse-start suites must pass.


## Qualification — `.46`

Preserve each authored named completion pulse in the child and add its canonical
activation done pulse at the same terminal state. For noncanonical actor output
completion names, route per-instance pulses into the parent/domain and expose
their union without another clocked stage. If the parent also completes that
output, keep its original delayed pulse in private local state and combine the
already-delayed pulses combinationally. This preserves their original edges;
it does not turn a completion into a delayed commit of arbitrary storage.
Transaction-local completion ports retain explicit binding semantics. Preserve
canonical done behavior and reject mixed non-completion writers instead of
inventing priority. Qualify separate and shared named outputs, reused instances,
parent/child completion, repeated activation, widths/types/reset timing,
ordinary/domain artifacts and complete native/API/MCP reports.

- [x] **ROOT CAUSE (WHY + WHERE)** — `bin/fsmgen --strict --check --json`
  against the retained before.isf reports unconnected w0.worker_done. Child
  ports always include canonical done but complete emits only its authored
  target; CompositionTop lacks named actor-completion wiring. The initial
  T1913 runtime then reports shared-datapath multi-value conflict: notice.
  `--emit-semantic-json` shows pulse outputs summarized only as flops;
  same-name candidate inference mistakes independent events for shared state.
  Evidence: before-check.json, before-check.log, first-runtime.log and
  semantic.json in `.artifacts/named-child-completion/`.
- [x] **ADDRESSED (verified)** — complete-runtime.log reports `All tests successful`
  for final T1913, including suffix collision and local shadow controls. Named
  child pulses and canonical done share the terminal edge; private parent
  views preserve delayed edges and merge coincident/adjacent events. T1912
  passes in domain-runtime.log and qualified-final.log, retaining the original
  named-domain source and exact pulse/payload oracle. Its unrelated watchdog
  TODO remains explicit. Full native/API/newline reports and strict scheduled
  replay pass. pulse_delay_cycles is numeric for pulses and null otherwise;
  shared candidate inference excludes those event families. All evidence is
  under `.artifacts/named-child-completion/`.
- [x] **NO REGRESSION** — shared-regression.log reports `All tests successful`
  for T139–T153/T178/T183/T340, preserving ordinary shared-register,
  combinational and assertion behavior. qualified-final.log reports
  `All tests successful` for T1913/T1912/T311/T354 after the corrected domain
  oracle and nullable schema. T1907/T1908 each report ok in final-runtime.log;
  that earlier combined invocation is not an overall pass because it retained
  the subsequently repaired oracle/schema failures. Book example audit and
  reference partition checks pass in book-complete.log; finalized mdBook builds
  in book-handoff.log. Logs are under `.artifacts/named-child-completion/`.

T1913's unchanged spawn timing oracle reproduces a blocking composition assertion:
`shared-datapath multi-value conflict: notice` at the first child terminal edge.
The generated top groups the child notice pulse and parent notice forwarding
view by bare local name, despite their distinct physical nets. `.46` owns this
blocking repair before named-completion signoff. Inspect candidate construction
and physical connection ownership; retain real shared-target conflict checks
and independently test coincident same-name child outputs. Evidence:
`.artifacts/named-child-completion/first-runtime.log` and its emitted spawn RTL.

The shared-datapath root cause is pulse-type erasure in LoweredRTLIRBuilder's
output-drive summary. It reports the hardware mux as flop without its delayed
event semantics, so same-name inference can impose exclusivity or holding
register behavior on independent completions. This leaf adds nullable public
pulse_delay_cycles through the existing runtime assignment helper and excludes
any candidate family containing delayed pulses. The original holding-register
and combinational contract is retained; the shared-datapath regression set
passes unchanged. T1913 adds coincident completions as an independent falsifier.
The original typed test attempt used a vector completion target; delayed-pulse
hardware explicitly requires one bit. Qualification uses a named bit alias,
matching that existing contract, rather than broadening vector pulse semantics.

The first positive named-domain oracle omitted the authored `(set result data)`
state after `(wait 3)`. Scheduled aux child evidence shows wait states, then the
set state, terminal state and delayed pulse. Relative to parent start at cycle
zero, the child pulse/payload is cycle seven and parent pulse is cycle ten.
T1912 corrects only those oracle constants; no implementation timing changes.
The first combined run remains retained as a failed invocation; the corrected
T1912 rerun must pass before this leaf closes.

The bounded output-drive key contract is a presence contract, as T311/T354
independently enforce. pulse_delay_cycles is therefore always present: an
integer for delayed pulses, JSON null for ordinary drives. This preserves exact
key-set checks without inventing a delay for non-pulse signals. The first
combined regression correctly rejected the initial optional-field shape.

Re-derivation: native scheduled replay and full check/semantic/schedule reports
expose the authored pulse, canonical handshake, private completion view and
nullable delay field. Falsification: T1913 independently predicts exact cycles,
coincident/adjacent events, repeats, mixed-writer refusal and exact public pins;
T1912 predicts domain-local pulses and payloads with the other clock stopped.
Durability: the regression sources, contract helper, book, fact cards and this
owning leaf retain those oracles; generated inventory and staged doctrines are
required before commit. Existing watchdog TODO remains explicitly unqualified.
The early book command used a nonexistent guessed test filename; it failed
before running tests. The discovered T1376 test and final book build pass in
book-complete.log; book.log is retained as the failed command, not green evidence.

Final collision probing found another `.46` blocker: a public input named
w0_worker_done receives both its authored top input and child worker_done via
CompositionTop's legacy suffix-based output lookup. The strict check rejects
that duplicate driver in handoff-collision.json. Automatic named completion
routing must suppress that legacy lookup; explicit transaction-local bindings
remain on their separate declared-port path. Extend T1913 with the public suffix collision and a nonlocal explicit
output-binding control; preserve transaction-local binding behavior.

The first nonlocal output-binding control was invalid: activation bindings
require declared transaction ports. Declaring the same name makes it a local
port, which shadows the actor output and deliberately bypasses automatic actor
completion routing. T1913 now tests that valid shadowing contract: mirrored
receives the local pulse and the untouched actor notice stays low. The emitter
therefore skips legacy lookup for automatic actor completions unconditionally;
explicit transaction-local bindings retain their existing separate path.


## Qualification — `.47`

Restore retained parent inputs in ordinary and domain library compositions.
Keep library outputs owned by their child; parent readback must be an explicit
input view, not a phantom parent writer or a leaked public port. Reject genuine
competing writers. Qualify unchanged FIFO regression, push/pop/reset runtime,
parent input/readback use, exact interfaces, scheduled replay and native/API/MCP
parity before domain storage-read work.

- [x] **ROOT CAUSE (WHY + WHERE)** — `bin/fsmgen --strict --check --json`
  reports unconnected fifo_library_use.data_in in before-check.json; unchanged
  T1238 fails in before-test.log. CompositionTop skipped retained parent inputs
  solely because the library also consumed them. Emitted before/fifo_library_use.fsm
  also declares child-owned full/empty/data_out as parent outputs, creating
  phantom ownership. LibraryPortOwnership now separates the actor-facing
  interface from explicit parent-component readback inputs. Evidence lives in
  `.artifacts/library-parent-interfaces/`.
- [x] **ADDRESSED (verified)** — final-runtime.log reports `All tests successful`
  for T1914/T1912. The independent queue scoreboard verifies FIFO data/flags,
  wrap stimulus, reset/idle and parent sampling, including typed readback and
  a stopped sibling clock. Exact public directions/counts, strict scheduled
  replay and complete native/API/newline check/semantic/schedule reports pass.
  Competing writers and parent reset/default declarations fail precisely.
  T1914 retains the nondefault-domain refusal for immediate follow-up `.48`;
  T1912's unrelated watchdog TODO remains owned by `.32.1.3.3.3`.
- [x] **NO REGRESSION** — focused.log reports `All tests successful` for
  T1230/T1231/T1237/T1238/T1239/T1247/T1281/T1321/T1352/T1476. The original
  FIFO schedule counts remain unchanged. catalog-final.log reports
  `All tests successful` for T1239/T297 after machine-readable catalog sync.
  T1376 and reference partition validation pass in book.log; mdBook builds.
  Logs are under `.artifacts/library-parent-interfaces/`.

T1238 and T1231 pass after the initial wiring repair. T1321 then caught an
actor-report regression: changing parent IR ports to inputs changed the public
schedule counts. Keep actor-facing ports unchanged and express readback only
in explicit_interface_ports, the emitted importing FSM contract. The generated
top and schedule continue to expose the authored directions, while the parent
component sees child-owned outputs as inputs. Preserve T1321's original counts.

T1914's first observed/typed/domain scoreboard run omitted the idle clock between
reset release and the first operation. The FIFO sets empty on that clock and
the parent samples it on the next. The corrected reset task explicitly advances
and verifies that first idle edge, then seeds the independent flag model; it
still requires all outputs low while reset is asserted. No RTL timing changes.

The nondefault-domain probe reproduces a separate parser defect before lowering:
clock binding references unknown parent signal clk despite that clock belonging
to the selected FIFO domain. `.48` owns this immediate next repair; `.47`
qualifies default-domain library realization with independently clocked sibling
logic and retains the nondefault source/refusal without claiming it works.

Re-derivation uses retained strict diagnostics, scheduled parent interfaces and
source-backed schedule/semantic reports. Falsification uses an independent
queue/flag model and cycle-offset parent samples, plus rejected competing owners
and exact top-level interfaces. Durability is carried by T1914, unchanged older
regressions, catalog/public contract, spec/book, fact card, this task and the
staged doctrine gate. No visual mdBook audit or nondefault binding runtime is
claimed. Live-document budget/inventory refresh belongs to this leaf without
raising hard ceilings.

## Qualification — `.48`

The exact retained nondefault source now passes library binding, then strict
check rejects the empty default-domain module with FSMGEN_STRICT_EMPTY_SIZE_SECTION:
the compiler emits a legacy empty (+size) section. Reproduce with
`bin/fsmgen --strict --check --json .artifacts/library-parent-interfaces/nondefault/source.isf`;
see `.artifacts/library-domain-bindings/retained-check.json`. The new book example
also has an idle domain. This is generated-source behavior, not an authored
legacy section. `.48` owns the blocking repair and regression before signoff.

The empty size section came from Emitter::FSM::_emit_size unconditionally
opening/closing a block with no declared ports, storage or counters. It now
omits only an empty size block; authored legacy empty sections retain their
strict rejection. T1914 includes the original empty-default-domain FIFO shape
through scheduled replay, complete reports and independent queue simulation.
retained-check-final.json accepts the exact retained source with no diagnostics.

The first new T1914 attempt placed :default outside its generated domain form;
corrected the fixture constructor before the green fifo-runtime.log run. The
first T1915 run passed its HDL policy cases but omitted parse_source's required
source label in the final parser checks; reset-final.log uses the public API
correctly. An initial focused command guessed a nonexistent T1247 filename;
focused-final.log uses the discovered clock-domain-partition test and completes.
The first book wrapper fed Python over stdin, which the background RAM wrapper
did not consume; its empty log is not validation. book-final.log runs a saved
repository-local script, checks the new example, passes the book-example and
partition audits, and builds the book. No visual audit is claimed.

- [x] **ROOT CAUSE (WHY + WHERE)** — `bin/fsmgen --strict --check --json`
  originally rejects the retained nondefault FIFO clock because
  Parser::_validate_use_bindings uses only the default compatibility timing.
  The selected use domain is available before annotation materialization and
  now supplies explicit binding validation and same-name inference. After that
  repair, retained-check.json exposes the generated idle-domain empty +size;
  Emitter::FSM now omits that empty block. Evidence is under
  `.artifacts/library-domain-bindings/` and the original `.47` reproducer.
- [x] **ADDRESSED (verified)** — final-runtime.log reports `All tests successful`
  for T1914/T1915 with qualified Verilator enabled. Independent FIFO/reset
  observations, selected-domain inference/remapping, stopped-clock/reset
  isolation, exact interfaces and complete native/API/newline reports pass.
  Wrong-domain bindings and incompatible inferred reset policies are refused.
  retained-check-final.json accepts the original source; strict scheduled
  replay covers the original empty-domain shape in T1914.
- [x] **NO REGRESSION** — reset-final.log reports `All tests successful` for
  T1915/T1230/T1231. focused-final.log reports `All tests successful` for
  T1237/T1238/T1239/T1247/T1321/T1281/T1352/T297. empty-size-regression.log
  reports `All tests successful` for T251/T50/T1890, preserving authored
  legacy refusal and multiclock wiring. book-final.log checks the new example,
  passes T1376 and reference partitions, and builds the book; book-handoff.log
  builds the final prose. Logs are under `.artifacts/library-domain-bindings/`.

Re-derivation uses the exact retained source, structured strict checks and
emitted system/size declarations. Falsification uses the independent FIFO queue
model, reset edge/polarity observations, stopped-clock isolation, wrong-domain
bindings and incompatible inferred reset policies. Durability is carried by
T1914/T1915, the existing library/domain/strict-boundary regressions, the public
catalog/spec/book, Knowledge Map and staged gates. Explicit reset remapping
preserves the reusable actor's policy; it does not override kind or polarity.

## Qualification — `.39.2.2.2.3.2`

Remove the explicit multi-domain storage-read qualification refusal only after
the now-realized domain compositions preserve the existing owner-to-child
handoff. No alternate state, reset copy or CDC path is introduced. The retained
T1904 domain source becomes a positive interface/replay/report control. T1916
exercises independent domains, explicit scalar resets, signed aliases, nested
aggregate whole/leaf reads and dynamic scalarized bank reads, with writes after
activation, repeated activations, both reset-isolation directions and a stopped
owner clock. Direct child writers and sibling-domain reads remain refused.

The first new source reused spawn identity reader across domains; actor-wide
instance validation correctly rejected it. Use distinct reader/aux_reader names.
before-valid.json then reproduces the actual qualification refusal through
`bin/fsmgen --strict --check --json`. The first T1916 runtime passed all hardware
observations but expected the phrase cross-domain instead of the existing
clock-domain violation diagnostic; use the exact owned signal/domain message.
final-runtime.log qualifies full and scalar-leaf aggregate reads. The final
spawn/generated-do matrix is recorded in qualified-runtime.log; the earlier
spawn-do-runtime.log exposes the local-call issue diagnosed below.

A scoped Knowledge Map check found stale intake/output-preservation facts still
calling aggregate/domain reads pending. This slice updates those facts and the
aggregate/domain cards to the qualified boundary; writer ownership remains open.
An exploratory read used a guessed ISF partition/book filename; use the discovered
03-composition-rules.md and 13b-transactions.md paths. No missing-path output is
counted as source inspection or validation.

- [x] **ROOT CAUSE (WHY + WHERE)** — `bin/fsmgen --strict --check --json`
  in before-valid.json reports the exact generated child actor-storage
  multi-domain qualification refusal. LoweringIR::build_module's admission
  guard predates realized domain children. _multi_domain_realizations rebuilds
  each domain IR through the existing ChildStorageOwnership handoffs; the
  parent owns registers/resets and the child receives typed live inputs.
- [x] **ADDRESSED (verified)** — qualified-runtime.log reports `All tests successful`
  for T1916 with qualified Verilator enabled. Spawn and parameterized generated-do
  cases pass independent live-update, scalar/typed/aggregate/bank observations,
  repeated reset/activation and domain isolation. An inverted explicit index
  binding proves precedence over inherited input wiring. Exact public interfaces,
  strict scheduled replay and full native/API/newline reports pass. Storage
  remains owned once; direct writers and sibling reads remain rejected.
- [x] **NO REGRESSION** — read-regression.log reports `All tests successful` for
  T1904/T1911 with qualified Verilator and the local GHDL provider. The original
  T1904 domain source is now a positive case; existing writer refusals remain.
  domain-regression.log reports `All tests successful` for T1912, retaining its
  unrelated watchdog TODO rather than claiming that runtime. book-final.log
  passes T1376, reference partitions and mdBook build. Logs are under
  `.artifacts/domain-storage-reads/`; visual book audit remains blocked.

Re-derivation uses emitted scheduled domain/child modules and full source-backed
check, semantic and schedule reports. Falsification uses independent HDL values
for post-activation updates, initial and repeated reset, whole/leaf aggregate
packing, bank index changes, stopped-clock isolation and exact public pins;
wrong-domain reads and direct writers remain negative controls. Durability is
carried by T1904/T1911/T1916, the book examples, scoped facts and staged gates.
No multi-domain VHDL or generated-child writer claim is made.

The exploratory plain-do source is retained under
`.artifacts/domain-storage-reads/plain-do/source.isf`. Unlike the selected
parameterized generated-do path, it stays local. The source passed strict
replay and report/interface parity but timed out without parent completion in
spawn-do-runtime.log. The missing generated-child IR is expected for local do;
the lost completion still requires ownership, not dismissal as a fixture issue.
`.32.1.3.3.1` owns its local-call control-flow investigation before metadata
signoff, alongside existing independent-transaction reachability. Diagnose the
materialized call/return states now and retain the source for that repair; this
storage-read lane must not claim plain local-do runtime qualification.

Materialized plain-do core FSM starts in worker_wait_0 and loops worker_done_11
back to worker_wait_0; parent_idle_0/parent_do_1 are unreachable in that single
state machine. This is the already-owned independent local-transaction entry
problem, now with a retained call-site reproduction under `.32.1.3.3.1`.

The parameterized generated-do probe exposes a smaller blocking wiring defect:
generated-do-runtime.log reports unconnected core__parent_worker_do_0.index.
CompositionTop wires inherited actor inputs only for spawn, even though the
generated do child retains the read index input. `.39.2.2.2.3.2` owns the immediate
repair: wire remaining same-name inputs for generated do while explicit child
input bindings take precedence. Qualify an inverted explicit index binding as
a falsifier, preserve spawn's existing binding-source contract, and retain all
storage reads as owner handoffs.

## Qualification — `.39.2.2.3.1`

The public parsed storage descriptors distinguish a var's resolved bits type
from record/list aggregates and bank signals carrying indexes. Preparation
accepts only a full scalar target with a sequential <- assignment. Field metadata
alone remains behavior-neutral; full-register writes must not be rejected just
because fields are documented. Named scalar aliases keep their resolved type.

prepare_child_storage_writes emits combinational data/enable outputs in the
original state and guard. Existing read selection then removes actor-register
copies and keeps any actual live reads. connect_child_storage_writes validates
one generated instance per scalar and no parent writer, adds private owner
inputs, and feeds an always-active owner DT assignment gated by the enable.
CompositionTop explicitly links those ports and excludes them from legacy suffix
matching. Multi-domain writer admission remains explicitly gated for .3.2.

The original audit's exact writer source is retained in
`.artifacts/child-scalar-writes/retained.isf` and replayed by T1917 from the tracked
audit. The new edge source has two wait states, a conditional branch and the
write state: changing data immediately before the write edge falsifies added
payload-register latency. Parent sequential observation must change on the
following edge. Initial runtime passes scalar, named signed alias, default reset,
read-modify-write, one named domain and legacy public-input collision cases, plus
the exact retained 19-to-37 defect and rejected competing writers.

The expanded matrix adds metadata-only fields, generated do and distinct scalar
targets. expanded-runtime.log passed those first additions but exposed an invalid
testbench module-level assignment introduced by text substitution in the two-target
case. The final test builds declarations, observation statements and reset/update
statements separately before rendering the testbench; final-runtime.log owns the
complete result. No compiler failure is attributed to the implementation from
that malformed testbench.

- [x] **ROOT CAUSE (WHY + WHERE)** — The versioned
  docs/audits/generated-child-storage-ownership-20260926.json records the original
  accepted `--strict --check --json` source, separate parent/child status registers
  and independent parent observed=19 instead of 37. Decision 0107 requires one
  owner and original-edge transfer. The immediate predecessor explicitly refused
  all generated child writes. retained/worker.fsm and retained/child_storage_writer.fsm
  now show combinational child requests and the sole owner register assignment.
- [x] **ADDRESSED (verified)** — final-runtime.log reports `All tests successful`
  for T1917 with qualified Verilator enabled. The edge oracle, late payload,
  conditional hold, owner and child readback, signed alias, reset/default reset,
  repeated activation, metadata-only fields, generated do and distinct-target
  cases pass. Exact retained source now produces 37 in the owner observation.
  Direct scheduled replay, exact public pins and complete native/API/newline
  check/semantic/schedule reports pass. Unsupported writer families and competing
  owners are rejected with contextual diagnostics.
- [x] **NO REGRESSION** — read-regression.log reports `All tests successful` for
  T1904/T1916 with qualified Verilator and the local GHDL provider. Existing
  live reads and domain isolation survive; writer negatives now assert the
  specific ownership or qualification boundary. binding-regression.log reports
  `All tests successful` for T1241/T1248/T1403. book.log passes T1376,
  reference partitions and mdBook build. Logs are under
  `.artifacts/child-scalar-writes/`; no visual book audit is claimed.

Re-derivation uses parsed storage descriptors and emitted source/HDL, including
one owner reset and source-backed full semantic/schedule reports. Falsification
uses a late-changing payload and edge-specific parent observation, conditional
holds, live child readback, repeated/reset calls, signed payloads, separate scalar
targets, explicit writer conflicts and exact public pins. Durability is carried
by T1917, retained audit bytes, read/domain/binding regressions, book/spec/facts
and staged gates. No multi-domain writer, competing-writer arbitration, physical
partial/aggregate/bank write or generated VHDL composition claim is made.

The first staged gate exceeded the existing focused-doc total-line transition
allowance by one line. Remove redundant watchdog/metadata-queue narration in the
feedback response; preserve the scope and evidence. No hard ceiling or transition
allowance increase is needed for that surface. The final gate owns signoff.


## Qualification — `.39.2.2.3.2`

The same private data/enable handoff applies after domain partitioning. Remove
only LoweringIR's temporary multi-domain writer admission guard; same-domain
validation, sole-writer checks and parent reset ownership remain unchanged.

- [x] **ROOT CAUSE (WHY + WHERE)** — The retained before.json from
  `--strict --check --json` rejects aux_worker with "generated child actor-storage
  writes in a multi-domain actor require qualified domain writer handoffs".
  LoweringIR applies this qualification guard before connecting otherwise valid
  per-domain child requests. T1918 checks the resulting child IR has only its
  domain's scalar read/write interfaces and no copied register or reset.
- [x] **ADDRESSED (verified)** — initial-runtime.log reports `All tests successful`
  for T1918 with qualified Verilator enabled. Independent edge oracles check
  writes on edges 5 and 8, followed by sequential owner observation on edges
  6 and 9. Late payload changes, zero-valued first writes, repeated live updates,
  guarded holds, reset isolation and stopped clocks pass for spawn, generated do
  and signed aliases with the other domain selected as default. Strict replay,
  exact public pins and complete native/API/newline reports pass. Cross-domain
  reads, parent writers and duplicate child writer instances remain rejected.
- [x] **NO REGRESSION** — regression.log reports `All tests successful` for
  T1917/T1916. T1917 includes a writer in a multi-domain actor with an empty second
  domain; T1916's writer negative now asserts the real parent/child contention.
  book.log reports `All tests successful` for T1376 and passes exact reference
  partitions plus mdBook build. Evidence is under `.artifacts/domain-scalar-writes/`.
  The new nondefault-domain writer book example lowers cleanly. No visual audit
  or generated VHDL composition qualification is claimed.

Re-derivation uses domain-partitioned IR and emitted scheduled/HDL interfaces,
owner-only register/reset declarations and full source-backed reports.
Falsification uses independently stepped clocks, distinct async/sync reset
policies, changing payloads immediately before writes, edge-specific observation,
zero updates, repeated calls and forbidden ownership/crossing controls.
Durability is carried by T1918, migrated T1917/T1916, book/spec/facts and staged
gates. Competing writers and physical partial/aggregate/bank writes remain owned
by .39.2.2.4; this slice does not invent arbitration for them.


## Contract audit — `.39.2.2.4.1`

Read decision 0107, R13/R14 direction, ChildStorageOwnership, parser aggregate
path/resource validation, LoweringIR bank assignment/report generation and the
actor/type/data/composition/resource book contracts. Whole aggregate transfers
need typed whole-value handoffs; partial writes must retain untouched bits;
bank stores must retain index guards and concrete-element ownership; competing
writers need a declared progress contract before arbitration. These are separate
owned leaves, ordered .4.2 through .4.5. This audit changes no writer admission.

- [x] **ROOT CAUSE (WHY + WHERE)** — The actor-storage introduction still
  published the earlier all-writes and aggregate/domain-read refusals. git log -S
  attributes that paragraph to 5c0f802646c69108d15995f7e8cd7e29c32ebdf5; subsequent
  qualifications updated the composition chapter but missed this introduction.
- [x] **ADDRESSED (verified)** — The introduction now describes qualified
  reads/scalar writes and links the detailed current boundary. The contract
  frontier fact card makes resource-user and partial-write distinctions
  searchable. The task leaves preserve the implementation order and boundaries.
- [x] **NO REGRESSION** — .artifacts/writer-contract-audit/checks.log reports
  All tests successful for T1261/T1403/T1218/T1376, then passes reference
  partitions and mdBook build. The first staged gate requires these fresh
  acceptance boxes because the document budget registry is a governed config
  path. The gate also caught an unnecessary isf_reference authority refresh
  with no reference-text change; restore that unchanged HEAD record. The final
  staged gate owns signoff.
Re-derivation uses the named parser/lowering functions and published contracts;
falsification uses existing invalid-path/resource-user/field-shape test controls;
durability uses split task leaves, the fact card, corrected book and staged gates.
No new runtime support or visual book audit is claimed.


Whole-aggregate qualification follow-ups: regression.log first passes T1917 but
T1904 multiple_readers has a newline/API schedule response without result.
The original test did not print the actual error response. Add failure-only
response diagnostics and rerun from a stable source tree; do not infer a timeout
or dismiss the mismatch without reproducing its cause. T1920's direct worker
shadowing controls expose a separate role-merge conflict owned by .49; generated
worker controls also fail at the same role boundary. T1920 now asserts that
separately owned diagnostic for storage collisions and proves explicit-port
domain precedence using an actor-output name without a storage-role collision.


## Qualification — `.39.2.2.4.2`

Whole packed record/list assignments use the existing original-edge data/enable
handoff. ChildStorageOwnership now admits resolved bits/record/list var types
while retaining whole-target, sequential-op and sole-instance checks. Private
ports retain the declared alias and width; no alternate register or merge path
is added. T1917 gains ordinary record/list cases and migrates the old aggregate
negative to a scalar member write. T1919 exercises whole aggregate writes and
live scalar-leaf RHSs in independent domains, including imported/nested types.

initial-runtime.log passes the initial aggregate matrix. The strengthened final
matrix then exposes a real domain check gap: final-runtime.log fails only its
aggregate sibling-domain diagnostic expectation, reaching unconnected composition
wiring instead. domain-before.log reproduces public lowering admission for direct
member reads, member writes and whole-register writes in a sibling domain.
_validate_domain_signal_access skipped non-identifier paths, while inferred
assignment targets in _transaction_local_signal_domains overrode declared actor
ownership. The repair resolves parsed storage paths to their declared root and
removes actor names from inferred locals before applying explicit local ports.

T1920's first shadowing controls expose a separate role-merge defect for direct
and generated explicit ports that reuse storage names. .49 owns that repair;
the final controls distinguish domain precedence from the later role boundary.
A positive parent ending immediately in await_all also produces an undefined
transition-target warning; retain terminal-await.isf and schedule its repair
under .32.1.3.3.1. Positive controls now author an explicit completion and pass
without that warning. Neither issue is hidden as supported behavior in the book.

The first combined regression passes T1917 but T1904 records a missing MCP result
envelope while implementation files were changing. The initial test omitted the
error payload, so its cause cannot be established from that log. Failure-only
response diagnostics are now retained; multiple-readers-probe.log passes the
isolated case on stable code. .50 owns root-cause investigation rather than
claiming a product fix from a retry.

- [x] **ROOT CAUSE (WHY + WHERE)** — before.json from `--strict --check --json`
  rejects whole aggregate status writes at ChildStorageOwnership's scalar-type
  guard. The path diagnostic failure and domain-before.log locate the separate
  ownership-validation mechanisms described above in LoweringIR.
- [x] **ADDRESSED (verified)** — qualified-runtime.log reports All tests successful
  for T1919/T1916 with qualified Verilator. Packed record/list/nested/imported
  writes preserve original edges, live reads, resets, repeated calls and exact
  private types/public pins. Complete native/API/newline reports and strict
  scheduled replay pass. Aggregate-specific partial/cross-domain/competing
  controls reject precisely. The exact retained whole-writer before.isf now
  passes strict check in after.json.
- [x] **NO REGRESSION** — domain-final.log reports All tests successful for
  T1920/T1247, with contextual member/index/root domain failures, same-domain
  controls, inferred locals and explicit-port precedence. read-final.log reports
  All tests successful for the complete T1904 suite with qualified Verilator and
  the local GHDL provider; the previously failed report case passes on stable
  code. T1917 passes in regression.log, including ordinary record/list writes.
  book-final.log passes T1376, exact reference partitions and mdBook build.
  Evidence is under
  .artifacts/whole-aggregate-writes/; no visual book audit is claimed.

Re-derivation uses resolved storage types, typed owner/child handoff IR, emitted
scheduled/HDL artifacts and source-backed complete reports. Falsification uses
independent packed-value edge oracles, late payload changes, repeated live reads,
zero-valued updates, stopped clocks, reset isolation, imported aliases, rejected
partial/competing writers and explicit cross-domain controls. Durability uses
T1917/T1919/T1920, retained source probes, book/spec/facts, scheduled defect owners
and staged gates. No partial/bank/competing writer or VHDL composition claim is
made; the first missing MCP error payload remains an explicit evidence gap.


The first aggregate staged gate caught the active-index row's line length above
its existing focused-document transition allowance. Condense older qualification
narration into the current owner/read/write summary while preserving the next
repair sequence; no size allowance increase is needed. The final gate owns signoff.


## Qualification notes — `.49.1`

initial-controls.log passes the retained T1920 generated input/output collisions.
initial-runtime.log passes ordinary, typed, independent-domain and scalarized
bank-entry cases, but the first generated-do monitor incorrectly requires the
public output to hold after completion. The retained generated-do-probe source,
scheduled FSM and HDL show the actual (= child_seen ... <child_done) binding;
generated-do-probe.log observes payload 7 during its completion-qualified window
then zero at idle, as the published contract requires. Correct the monitor to
observe the nonzero test payload during the valid window, retain the independent
completion count and resets, and add generated rule-trigger snapshot controls.
No implementation repair is attributed to that monitor failure.


The implementation removes inherited actor metadata for explicit local port
names before child width/role/type/reset merging. Local type references and
transaction reset values are then applied; select_child_storage_reads skips
those local identities when discarding actor-storage copies. The actual actor
register retains its separate owner metadata. Explicit local declarations are
not transaction ports and remain separately owned under .49.3; direct shared-
module port naming remains under .49.2.

- [x] **ROOT CAUSE (WHY + WHERE)** — The retained domain-controls-final.log from
  .artifacts/whole-aggregate-writes/ reports the storage role conflict
  at perl/FSM/Scheduler/ISF/LoweringIR.pm line 5625 while merging the child. The
  mismatch precedes child storage selection. Same-named local widths and types
  also encounter inherited actor entries; child cleanup previously deleted
  local role/reset metadata under those actor names.
- [x] **ADDRESSED (verified)** — .artifacts/child-port-shadow/qualified-runtime.log
  reports All tests successful for T1921 with qualified Verilator. Local payloads
  and actor register values remain independent across exact widths/types, resets,
  repeated calls, independent domains and scalarized bank-entry names. Spawn,
  generated do and generated rule-trigger snapshot controls pass, with strict
  replay, exact public interfaces and full native/API/newline reports. T1920's
  retained generated controls now lower. The payload-handoff repair retains
  captured values after the start pulse without adding a register stage.
- [x] **NO REGRESSION** — .artifacts/child-port-shadow/regression-final.log
  reports All tests successful for T1920/T1241/T1243/T1248/T1431/T1918 with qualified
  Verilator. Existing domain writers, activation bindings, schedule reports and
  trigger effect validation survive. book-final.log passes
  T1376, exact reference partitions and mdBook build. No visual audit is claimed.

Re-derivation uses module metadata before merging, declared storage versus local
ports, explicit binding artifacts and complete source-backed reports.
Falsification uses narrower local widths and independent signed aliases, actor
reset values distinct from local defaults, repeated calls, owner updates,
independent domain resets and live/snapshot payload timing. Durability uses
T1921, migrated T1920, retained generated-do trace, existing binding/domain
regressions, book/spec/facts and staged gates. Direct-port and local-declaration
scope support remains explicitly outside this leaf's qualification.


final-runtime.log passes the corrected generated-do cases but the added trigger
snapshot cases fail: completion occurs while the payload result remains zero.
The retained trigger-probe directory shows a per-rule payload register capturing
under the authored rule guard, then a combinational child input guarded only by
the delayed trigger source. trigger-probe.log confirms zero throughout the later
child read/completion. Remove only the redundant handoff guard so the existing
captured register remains visible; retain request capture, start pulse and output
completion guards. T1248's scheduled-artifact assertions now require that retained
snapshot connection. T1921 changes the external payload after trigger activation
and reads after waits, with repeated/reset calls; this falsifies both a gated-zero
handoff and an accidental live external-input connection. No request queue or
new overlapping-trigger policy is introduced.

The first .49.1 staged doctrine gate found two new book width claims without
claim dispositions. Both describe the qualified local-port/actor example;
explicit derived-gate records now link distinct metadata, runtime falsification
and tracked watchers. No test result or implementation claim was changed.

## Direct-port scope audit — `.49.2.1`

Public --strict --check --json, --emit-schedule-json and --emit-semantic-json
probes are retained under .artifacts/direct-port-scope/. input.isf and output.isf
use actor status and worker status at the same width; both fail the parent
storage-role merge. narrow_input.isf instead fails the width merge. These
results reproduce the direct scope defect independently of clock domains.

caller_shadow.isf exposes a second scope-resolution defect: actor status has
width 8, caller parent explicitly declares status at width 4, and a spawn binds
worker payload at width 4 from caller status. All public routes reject with
binding width 4 does not match actor signal status width 8. The locus is
LoweringIR::_binding_signal_info: actor interface/storage lookup precedes
transaction-local lookup. This is owned by .49.2.2, with priority ahead of
local-call signoff and storage access metadata. Repair lexical lookup together
with identity lowering; do not independently overwrite the actor declaration.

The two_ports.isf control has separate first/second transaction output ports
named status. All public routes admit it. Inspect its scheduled source and
inferred storage before any behavior claim: admission alone does not qualify
independent port state or independently triggered controllers. The direct
runtime/control prerequisite remains .32.1.3.3.1.

The public two_ports schedule reports one status register for both formal
outputs. Materialized two_ports.fsm confirms both transactions assign the same
status and return to their separate entry states under one ?fsm root. This is
a lowering identity collision, not qualified concurrent behavior. .49.2.2 owns
private identities for distinct declarations as well as actor/local shadowing.

Scope repair must cover declaration maps, typed assignment/condition operands,
local call callee input/output endpoints, caller-side binding expressions,
rule-trigger payload destinations and source-facing binding reports. Preserve
formal names in _transaction_port_binding_entry and use an explicit lowered
identity when needed. Never rename state/transaction/type/member names or
message text with an undifferentiated recursive string replacement.

The .32.1.3.3.1 prerequisite now has separate terminal-sync, controller-contract
and executable-repair leaves. Terminal synchronization is a small independent
repair selected next. Controller selection then precedes scoped port lowering;
local-call timing and independent trigger behavior must be proved before the
port repair is declared runtime-qualified. This audit changes no implementation.

## Acceptance checklist — `.49.2.1` audit

- [x] **ROOT CAUSE (WHY + WHERE)** — Public --emit-schedule-json probes retained
  in .artifacts/direct-port-scope/probe-final.log reproduce direct role/width
  conflicts and caller-local lookup precedence. The accepted two_ports schedule
  and materialized FSM expose the shared raw formal identity and disconnected
  transaction graphs. LoweringIR::_build_parent_ir, _binding_signal_info,
  _ir_do, _build_rules and _transaction_port_binding_entry identify the relevant
  merge, lookup, binding and reporting boundaries; no runtime success is inferred.
- [x] **ADDRESSED (verified)** — The audit splits scoped identity and local-call
  qualification under .49.2, and terminal synchronization, controller contract
  and executable repair under .32.1.3.3.1. Each reproduced defect has a scheduled
  owner ahead of access metadata. Book and Knowledge Map state the current
  boundary; this leaf closes investigation scope, not implementation defects.
- [x] **NO REGRESSION** — .artifacts/direct-port-scope/check.log reports
  All tests successful for T1241/T1243/T1376, then a successful mdBook build.
  The binding/report tests retain their artifact contract; visual book QA and
  direct-controller runtime signoff remain unearned and explicitly pending.

Re-derivation uses separate public check/schedule/semantic probes and exact
lowered declarations/operands. Falsification varies local widths, removes clock
domains and separates declarations across transactions; the caller binding
control tests lexical lookup before IR merging. Durability uses this task,
the canonical scope card and the shipped book boundary. The retained runtime
failures belong to controller repair; a source-only passing control does not
close them.

## Terminal synchronization qualification — `.32.1.3.3.1.1`

.artifacts/terminal-sync/before.json and before.stderr reproduce the retained
terminal-await.isf through public strict check. The emitter warns about an
uninitialized target at Emitter/FSM.pm line 336; the generated core module then
fails transition-target validation. test-before.log independently fails the
new empty-pending regression on a missing target and malformed scheduled FSM.

LoweringIR::_link_states only assigned sync successors when a next state
existed. It now gives either synchronization form an explicit self-loop when
there is no successor. This preserves terminal hold and completion predicates;
it introduces neither a completion pulse nor an implicit rearm edge. Explicit
complete retains return-to-entry behavior. Simply omitting emission would leave
an empty state body, which the public IAL0 grammar rejects under T49.

runtime.log passes all HDL hold/reset observations but fails the new empty-set
interface assertions: standalone semantic reports separate system_contract
from data signal_analysis; composition tops include system pins in their input
inventory. empty-semantic.json independently verifies the exact standalone
explicit_system_contract. The corrected test checks both exact representations,
without changing production reporting. The first regression command passes
T1908, then aborts because of a mistyped activation test filename. The corrected
command names the existing T1912; no product failure is inferred from that typo.

## Acceptance checklist — `.32.1.3.3.1.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — before.stderr records an uninitialized
  target at perl/FSM/Scheduler/ISF/Emitter/FSM.pm line 336; before.json rejects
  the malformed transition target from the retained domain source. The empty
  pending-set regression also fails in test-before.log. _link_states omitted
  terminal synchronization continuations while the emitter required a target.
- [x] **ADDRESSED (verified)** — .artifacts/terminal-sync/runtime-final.log
  reports All tests successful for T1922 with qualified Verilator. Both sync
  forms retain an explicit self-loop for empty/single/multiple pending sets;
  independent completion pulses and later start requests cannot rearm them,
  while reset permits a fresh activation. Full native/API/newline reports and
  strict emitted-source replay pass. after.json plus empty after.stderr prove
  the original domain reproduction now succeeds without the warning.
- [x] **NO REGRESSION** — .artifacts/terminal-sync/regression-final.log reports
  All tests successful for T1908/T1912/T1920 with qualified Verilator. Continued
  joins retain completion-memory lifetime and timing, repeated/reset behavior
  and the existing domain activation controls. T1912's already-owned watchdog
  limitation is not closed. book.log passes T49/T1376, reference partitions and
  the mdBook build; no visual audit is claimed.

Re-derivation follows the missing successor in IR through the emitter and
public malformed-target report. Falsification distinguishes terminal hold from
implicit entry rearm, varies pending sets and pulse ordering, repeats requests
without reset and then resets. Existing continued joins separately prove the
repair did not add completion latency. Durability uses T1922, T1908 and the
retained source, with synchronized book/spec/fact and staged doctrines.
Independent controller reachability and direct-port scope remain open.

## Direct controller audit — `.32.1.3.3.1.2`

The public source and HDL probes under .artifacts/direct-controller-contract/
reproduce declaration-order dependence without formal-port collisions.
baseline_ab strict-checks and compiles, but its runtime observes first active
and second inactive. Reversing declarations in baseline_ba instead observes
second active and first inactive. The oracle requires the short transaction to
finish while the long transaction is still waiting. Both baseline runs fail.
reference_dt is an explicitly authored IAL0 reference with separate private
controller registers and guarded DT bodies over shared actor storage. It
strict-checks, compiles and passes simultaneous activation, short-versus-long
progress, isolated repeated requests and reset during partial work. This proves
the public carrier can express the intended independence; production ISF
lowering is unchanged. The first probe script also emitted a Perl print-spacing
warning; its serialization completed, and the script spelling is corrected
without attributing any product behavior to that warning.

The controller repair must separately qualify local callee entry insertion,
held-start one-shot acceptance, caller payload capture and completion copy,
nested/repeated calls and transaction-local identities. Existing rule-versus-
transaction priority is assignment-local, not a stall or queue policy. Current
_apply_rule_transaction_priority_resolution only selects rule/transaction
pairs; _build_conflict_issues does not provide general transaction/transaction
write conflict admission. Independently executing previously disconnected
controllers therefore requires an explicit shared-write boundary before code
can be promoted. This is a prerequisite owned by the controller implementation
split, not permission to choose silent priority or to duplicate actor storage.

The rationale collection is already declared rollover_debt. Its measured
current lines reach baseline plus transition allowance; the local containment
policy prohibits increasing that allowance for a rollover surface. A durable
controller architecture decision therefore needs the declared rationale
rollover before adoption. Keep the carrier evidence here and complete the
bounded audit separately; schedule rationale containment before the contract
leaf rather than hide the decision in implementation or relax its limits.

The local-call baseline repeats the defect without formal ports. Callee-first
starts its body repeatedly without the caller; caller-first remains blocked
with neither side executed. The explicit IAL0 reference adds independent
caller/callee selectors and held-start history. It passes exact call counts,
repeated calls, idle hold and reset during a partial call. This does not qualify
production local-call binding capture or nested calls; those remain separate
contract/implementation requirements.

Complete baseline/reference sources, shared runtime oracles, source hashes and
observed results are tracked in docs/audits/direct-controller-contract-20260927.json.
Runtime logs and compiled artifacts remain in the local probe directory. The
hand-authored reference is a feasibility oracle, not generated production
output. .1.2.1 owns this completed audit; .51 restores bounded decision capacity,
then .1.2.2 adopts the architecture and splits executable implementation.

The transaction chapter's opening every-clause-produces-a-state wording also
conflicted with declaration-only ports/params/locals. This audit replaces it
with the actual scheduled-state/data-path model and explicitly states that
declarations alone do not execute. The broader direct-controller warning is
now visible at both transaction and composition entry points.

## Acceptance checklist — `.32.1.3.3.1.2.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — The audit --check --json probes accept
  both declaration orders, and HDL generation/Verilator compilation succeed,
  but independent runtime oracles fail. Emitter::FSM::_emit_states concatenates
  the transaction loops built separately by LoweringIR::_link_states inside
  one encoded FSM root. The local-call case additionally lacks a gated callee
  entry when none is authored. Full source/oracle/output evidence is retained
  in docs/audits/direct-controller-contract-20260927.json.
- [x] **ADDRESSED (verified)** — Independent-controller and local-call baselines
  are now explicit expected failures in the tracked audit. Separate public IAL0
  references prove private control registers and guarded DT bodies can preserve
  concurrent progress and one-shot local-call acceptance over shared storage.
  .1.2.2 owns contract adoption, .1.3 owns split implementation, .49.2 retains
  scoped bindings and .51 owns the rationale rollover prerequisite. The book
  warns at both relevant chapter entry points; no product defect is closed by
  the reference or the audit alone.
- [x] **NO REGRESSION** — .artifacts/direct-controller-contract/check.log
  verifies all tracked source hashes, expected-failure classifications and
  reference observations; T1376 reports All tests successful and mdBook builds.
  No production code changed. Visual QA remains unqualified, and reference
  simulations do not substitute for later production controller runtime gates.

Re-derivation uses exact public source admission and emitted HDL. Falsification
reverses declarations, overlaps short and long work, repeats isolated requests
and resets partial execution; local-call probes distinguish free-running
callee-first from stalled caller-first behavior. Durability retains complete
sources/oracles, hashes and observed results in the tracked audit plus the
canonical fact and explicit implementation queue. Architecture adoption awaits
bounded rationale capacity; no hidden scheduling or contention policy is chosen.

## Decision-record rollover audit — `.51.1`

The fixed source revision and complete record identities live in
`docs/audits/decision-record-rollover-census-20260927.json`. Re-derivation
compares each current record byte-for-byte with `git show` at that revision,
checks hashes/lines/bytes, and compares sorted membership with `git ls-tree`.
The selected contiguous whole-record cohort is decisions `0001–0050`.
This is a storage boundary, not a claim that early decisions are obsolete:
all text, supersession markers and policy authority must survive unchanged.

The selected atomic migration stores original text in a bounded immutable JSON
segment and separately generates a browseable Markdown view with explicit
per-record anchors and relocated relative links. Every original root path
becomes a forwarding page preserving its title, identity and archive link.
The index still discovers every identity; a bounded reader returns an exact
original record by ID. Ordinary lookup does not require Git history or network
access. A manifest and registered file-backed archive descriptor pin source
revision, cohort identities and archive hashes; reconstruction checks compare
each original to this independently committed census and regenerate the entire
human view. Archive storage never supersedes a decision.

Rejected alternatives: deleting older records loses active contracts; relying
only on `git show` weakens ordinary local retrieval; simply moving Markdown
breaks its relative links; changing original bytes to relocate those links
loses exact reconstruction; raising the live rollover allowance evades the
required transition. The archive is a sealed record store, not a new unbounded
bootstrap read or a replacement narrative ledger.

Executable consumers use decision paths as provenance or existence identities.
The backend contract path stays unchanged. Knowledge Map evidence paths remain
valid, but body-search reverify commands must search the exact reader output
or the reconstructed view in the migration. The cohort has no front-matter
cards, so moving its bodies must not change the map's fact set. The census
retains complete matching consumer lines and source link targets. Its inline
Markdown anchor search found no incoming section links; this does not assert
that arbitrary external links or dynamically constructed consumers were scanned.

The migration must separately prove complete source identity, semantic/live
consumer closure, bounded current dimensions and absence of unretained source
residue. Root aliases retain file cardinality, so restoring line capacity alone
does not clear file-count warning pressure. Keep that dimension visible and
require another bounded index/identity transition before its rollover threshold;
do not raise its ceiling as part of this migration. The director-deferred
agent-era Markdown reassessment `.26` remains outside this narrow decision-store
transition. No authority has been retired or reclassified by this audit.

The first consumer scan was unnecessarily broad and lacked the RAM wrapper.
It was stopped by terminating its identified process before any output write.
The replacement uses targeted `rg` discovery, tracked membership and streamed
matching lines under the RAM guard; its result is the retained census. No
product failure or successful migration is inferred from the aborted scan.

- [x] **ROOT CAUSE (WHY + WHERE)** — The rationale registry's declared
  rollover debt and saturated allowance prevent an ordinary architecture
  append. `git log -S` on the rationale surface declaration identifies its
  registered containment history. Exact source membership and per-record identities are retained;
  the controller audit identifies the pending architecture decision.
- [x] **ADDRESSED (verified)** — Select exact immutable originals, generated
  relative-link views, stable root aliases and bounded per-record retrieval.
  `.51.2` owns atomic implementation and all preservation/negative controls.
- [x] **NO REGRESSION** — The audit check compares every record against the
  fixed Git source, validates cohort totals and retained consumer lines, and
  resolves each selected source link. No decision or implementation changes.
  The book build passed; knowledge.log reports `knowledge-map: OK`. Visual
  QA remains unqualified.

Falsification uses independent Git membership and exact per-record identities
rather than totals alone. Durability is the committed census and this selected
contract. Migration semantic closure and planted-negative enforcement remain
explicitly missing until `.51.2`; an audit pass is not a rollover pass.

## Exact decision storage migration — `.51.2`

Decision `0108` adopts the audited whole-record seal. Original text is retained
in the file-backed archive; every source digest is checked against the prior
committed census, whose identity is pinned independently by the reader.
The complete human view is derived from those exact originals, with relocated
relative links and explicit record anchors. Root forwarding pages are exact
bounded projections; the index still reaches every original identity. No
record's policy or supersession status was selected for retirement.

The live-document adapter executes the reader's default check as freshness
verification for the generated view. A separate archive descriptor pins the
original JSON bytes. The fixed view limits admit this one sealed cohort; the
freshness gate prohibits additions disguised as generated output. The live
rationale ceilings are unchanged, recovered line/byte growth allowance is
retired, and file-count warning debt remains explicit. `.51.3` owns the next
identity/index transition before that dimension reaches rollover.

The affected Knowledge Map commands combine exact reader output with their
remaining original sources before applying the original rg expression. Their
fact bodies and answers are unchanged. Existing backend provenance and
existence checks keep the same decision paths. A new retrieval fact documents
the local read path; no map answers are removed by the storage transition.

The source-identity product is the fixed census plus independent Git-byte
comparison for every reader result. Semantic closure is complete-record text
preservation plus unchanged authority, forwarding/index closure, relocated
link targets and migrated body searches. Live dimensions are measured from
the resulting root collection and bounded generated view. Loss residue is
empty because every selected source identity is present exactly once in the
archive and every original path is an exact forwarding projection; unselected
originals are unchanged. These products are separate from a generic gate pass.

The initial Python suite passed. The first Perl wrapper then failed before
running tests because it called SourceQueryRunner::_capture with positional
arguments instead of its array-reference/input contract and expected a tuple
instead of the result hash. The wrapper was corrected after reading that
interface; prove-final.log records the completed successful wrapper and
containment regression. This was a new test integration error, not archive
corruption or a product compiler failure.

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` identifies the rationale
  collection's declared containment history (audit .51.1). Its fixed census
  locates the saturated growth allowance and body-search consumers; moving
  bodies without exact retrieval would break those consumers. T1923 plants
  these failures and requires the new checker to reject them.
- [x] **ADDRESSED (verified)** — Exact originals, bounded reader, deterministic
  human view, forwarding pages, archive descriptor and executed projection
  verifier implement decision `0108` atomically. The test compares every
  public read with independent Git source bytes; archive corruption, membership
  drift, stale views, broken routes and obsolete body searches fail closed.
- [x] **NO REGRESSION** — .artifacts/decision-rollover/prove-final.log reports
  All tests successful for T1923 and T1554. Before adding the retrieval card,
  knowledge.log reports knowledge-map: OK with the same fact/answer set and
  query parity as the preceding audit. Compiler behavior is unchanged.

Re-derivation uses fixed source identities and current filesystem dimensions.
Falsification uses per-record Git comparison and planted defects, including
same-size text replacement, duplicate/order changes and missing destinations.
Durability is the archive descriptor, pinned prior census, executable checker,
regression, decision and fact card. Browser visual QA remains unavailable;
textual navigation checks and a book build do not claim visual inspection.

Final `.51.2` qualification.log passes T1923/T1414 and the mdBook build.
All rewritten reverify commands pass `bash -n`; exact source scope and reader
bytes are covered separately. The tracked
`docs/audits/decision-record-rollover-result-20260927.json` retains resulting
live dimensions, unchanged unselected identities and empty loss residue.
The new retrieval card is the only added Knowledge Map fact; original fact
bodies and answers retain their existing content.

The initial full gate rejected an incomplete surface declaration: the generated
view's declared route to original storage lacked its route-registry row.
The row now names the view's existing archive-source marker as reader navigation.
Exact reconstruction and all other doctrine checks passed in that attempt;
the complete staged gate is rerun for the corrected atomic declaration.

The corrected declaration passes the complete staged doctrine gate. A final
staged whitespace check then found an extra blank line at the derived view's
end; the renderer now emits one terminal newline. renderer-final.log passes
T1923 after regeneration; exact archive originals are unchanged.

## Controller adoption binding probe — `.32.1.3.3.1.2.2` (in flight)

The published transaction binding contract calls activation-region `do` inputs
snapshots, while _activation_input_assignments emits continuous assignments and
generated child start-history guards only activation. Before adopting timing,
probe a generated do with a delayed input read and change the external source
after call admission. Existing generated-do port-scope qualification held that
source stable; generated-trigger delayed capture has separate evidence. This
is a source-observed contract risk, not yet a confirmed runtime failure.
The active adoption leaf owns diagnosis; any reproduced repair must receive
an explicit implementation child before controller signoff or access metadata.

The generated-do snapshot probe is rejected before emission as
`generated_live_handoff`, exactly as the timing validator specifies. This
narrows the hypothesis: generated calls do not promise snapshots. Preserve
that rejected probe; qualify its live positive control and local rule-trigger
snapshot retention separately. Local activation-region calls still need their
own capture qualification once their controller executes.

The generated-live positive control passes both stable and changed inputs.
The direct rule-trigger target without authored `on` strict-admits and compiles
but free-runs repeatedly and reads zero, even with a stable external payload.
This initially suggested an additional entry failure, but T1171 and the rule
contract establish authored request gating: no-entry free-running behavior is
not classified as a new defect. That source conflates payload and entry behavior.
An otherwise identical authored-entry control isolates those mechanisms before
selecting the repair. Complete probe sources and observations are retained
under .artifacts/direct-controller-adoption for tracked audit capture.

The request-specific `(on worker_start)` control accepts one rule request yet
reads zero after the delay, with either stable or changed external input.
The emitted mux assigns payload zero outside its per-rule trigger pulse;
_rule_trigger_payload_fanin_assignments supplies that combinational guard.
A diagnostic emitted-HDL control changes only the mux default to the retained
single-rule payload source. This is attribution evidence, not a general
multi-source capture policy or a production implementation. The forthcoming
local activation/capture leaf owns repair and busy/multiple-source qualification.

## Controller and binding contract adoption — `.32.1.3.3.1.2.2`

Decision `0109` adopts private per-transaction logical control through public
IAL0 registers and guarded DT bodies while retaining shared actor ownership.
State/owner identity must be explicit before physical emission; the existing
_state_active_condition_expr used by rule/transaction priority cannot continue
to rely on one global encoded state. Point references already lower into
state-owned point-active assignments and must retain that meaning.

The selected execution contract does not silently install rule target entry:
T1171 uses `(on work_start)`, and the rule contract defines request fan-in.
The ungated rule probe was therefore corrected from a suspected entry defect
to an authored free-running control. Blocking local do is different: its
published call contract owns the callee entry and requires a one-shot request
and fresh completion. Generated do inputs are explicitly live and reject
snapshot spelling. Only local activation-region calls and rule payloads carry
the snapshot obligation; no generated live path is converted by this decision.

The request-gated local rule probe isolates a real payload defect: source
admission and HDL compile succeed, completion occurs once, but a delayed read
returns zero. Its emitted input mux defaults to zero after the trigger pulse.
A diagnostic change to that single mux default restores the retained payload
for stable and changed external inputs. Both raw emitted artifacts are kept;
comparison removes exactly one generated Date header comment from each before
proving the sole executable edit. No production lowerer changed, and the
single-source diagnostic is not a multiple-source arbitration implementation.

Complete source/testbench hashes, observations, rejected generated-snapshot
request, corrected intermediate classifications and raw counterfactual HDL
are tracked in docs/audits/direct-controller-binding-timing-20260927.json.
The prior controller audit remains valid: Git confirms no scheduler/ISF adapter
production changes since its recorded revision. The carrier references still
do not qualify production controller behavior.

Implementation children now separate shadow ownership, local payload repair,
shared-write admission, independent execution, blocking calls and broad
qualification. Existing .49.2.2 scoped identities runs after the shadow model
and before payload/admission work; .49.2.3 runs after local-call execution.
The local payload defect has a concrete scheduled repair under .1.3.2.

The rules chapter also retained stale generated-handoff wording from before
.49.1: it implied that the input value remained gated by the start pulse.
That paragraph and T1248's assertion description now state retained generated
payload behavior; the assertion itself already checked the correct output.
The book separately exposes the uncorrected local payload defect and marks
independent controllers as selected but unimplemented.

- [x] **ROOT CAUSE (WHY + WHERE)** — Native --check --json and independent
  emitted-HDL probes separate correct generated-live timing from local delayed
  payload loss. _rule_trigger_payload_fanin_assignments applies a combinational
  trigger guard that returns the input to zero after the pulse. The tracked
  counterfactual changes that mux default only, apart from generated Date
  comments, and passes both independent input controls. Existing direct
  controller failures remain rooted in concatenated loops and local-call entry.
- [x] **ADDRESSED (verified)** — Decision 0109 selects logical owner/state
  mapping, exact activation classes and shared-write admission. Every execution
  obligation has a child owner; local payload repair is .1.3.2. Complete
  evidence is retained and the book distinguishes selected contracts from
  current defects. This contract commit closes no production runtime defect.
- [x] **NO REGRESSION** — .artifacts/direct-controller-adoption/check.log
  verifies both tracked audits, source hashes, classifications, counterfactual
  equality and unchanged production source. It reports All tests successful
  for T1171/T1219/T1241/T1248/T1413/T1376, followed by a successful book build.

Re-derivation retains complete public sources and emitted artifacts.
Falsification uses declaration permutations, independent source changes,
request-specific entry and the minimal emitted-HDL counterfactual. Durability
is the tracked audits, decision, canonical fact and explicit implementation
queue. Direct-call capture, busy/multiple-source policy and full production
controller qualification remain named implementation obligations, not inferred
from the authored references. Browser visual QA remains unqualified.

## Shadow controller inventory — `.32.1.3.3.1.3.1`

The first shadow membership test rejects parent_do_1's parent_timeout target
in t/data/logical-controller-shadow/binding_generated_live.isf. Inspection
locates _link_states: it appends a watchdog transition to every await, even
when no watchdog exists. The condition's signal is undefined and the target
state is absent. Emitter::FSM ignores that await transition, so this is an
IR integrity defect rather than a demonstrated runtime timeout. This leaf
owns immediate removal of the phantom reference, guarded by unchanged public
reports/generated source plus real-watchdog positive controls. The separate
external-callee watchdog initialization defect remains owned by .32.1.3.3.3.

The private model now records explicit owner tuples, per-owner first/entry
states, domain timing and typed state references. Parent, generated transaction
child and concrete domain fixtures pass complete membership checks. Synthetic
cross-domain handshake states carry transaction ownership. No physical selector
is allocated and neither emitter reads this shadow. The Knowledge Map card
isf-logical-controller-shadow inventories the remaining state consumers and
names the legacy priority/provenance lookups that later promotion must replace.

Capture sources are durable under t/data/logical-controller-shadow; complete
before/after transport reports and emitted files are retained in the local
workspace, with their exact digest audit and reproducible capture probe under
docs/audits/logical-controller-shadow-20260927. The complete captures are byte
identical. Source/producer fingerprints were stable within every query.
The initial capture used a dot-prefixed artifact source, which the runner's
source-id contract rejects; sources were moved to the durable fixture cohort.
The original lowering-only cross-domain fixture mixed completion and data on
one output and correctly failed --check --json. The parity fixture uses
separate outputs; no language admission rule was weakened.

The initial T1924 detected the phantom timeout reference, now repaired with
real-watchdog positive coverage. A second test compared JSON serialization
strings after Storable cloning and observed Perl scalar numeric/string flags,
not unequal decoded report fields. The test now compares complete decoded
reports, while the independent public before/after captures remain exact-byte
comparisons. T1924 also covers implicit default-domain realization, named-point
ownership, terminal hold and absent reset without inventing semantics.

- [x] **ROOT CAUSE (WHY + WHERE)** — The baseline --emit-schedule-json and
  source/API/MCP captures establish current public behavior. T1924's initial
  `Logical controller ownership` diagnostic identifies the dangling
  parent_timeout target at LogicalControllers.pm line 91; _link_states
  appended it even when its watchdog signal was undefined. State expansion
  already stamps transaction owners, but synthetic external activation states
  lacked them. The emitter ignored the phantom edge and used existing control.
- [x] **ADDRESSED (verified)** — The shadow checker now accounts for every
  state in the retained parent/child/domain fixtures and rejects missing,
  unknown or reference-valued owners, duplicate membership, missing targets
  and cross-owner edges. Synthetic ownership is explicit and no-watchdog
  awaits no longer have nonexistent timeout targets. The audit's exact complete
  before/after equality proves no public report or emitted IAL0 change.
- [x] **NO REGRESSION** — focused.log and qualification.log under
  .artifacts/logical-controller-model both report All tests successful for
  shadow ownership plus real-watchdog, points, external activation, nested
  effects, domain partition, priority, binding and book lowering checks.
  The mdBook builds successfully; browser visual QA remains unqualified.

Re-derivation uses the retained capture probe and ownership tests.
Falsification includes malformed owner/target mutations, prefix-like names,
implicit domains, absent resets and a real-watchdog control. Durability is
the tracked source cohort, exact file/report digests, consumer card and tests.
This closes shadow ownership only. Scoped formal identities .49.2.2 is next;
local payload, writer admission and production controller/runtime obligations
remain open. No additional DEVELOPMENT_NOTES entry is needed because decision
0109 and the canonical consumer card own the rationale.

The first staged doctrine gate passed task acceptance and claim checks but
found the added import-map row one line beyond focused_documents' owned
transition allowance. Apply its existing ratchet under this active tree,
without changing health targets or hard ceilings, then rerun the full gate.


## Formal identity planning — `.49.2.2.1`

The namespace repair spans declaration maps, explicit signal operands,
caller/callee binding endpoints, rule payloads and source-facing report names.
It is split into detached identity planning (.1), typed rewriting (.2) and
production integration (.3). Plans must accept complete additional physical
reservations from the eventual lowering integration; source declarations alone
cannot prove absence of collisions with generated counters, monitors or ports.
No isolated planner is claimed to fix the existing parent merge or runtime.

While checking the parser boundary, _bit_op_width_map was found to omit
transaction ports. A paired public-parser probe confirms that actor status
width 4 with formal status width 8 rejects clear-bit index 7, while actor
width 8 with formal width 4 accepts it and expands mask 127. This is a real
lexical range-validation defect before lowering, independently of the already
owned role/width merge. Its sources/results are retained in
`docs/audits/direct-formal-bit-width-scope-20260927.json`; .49.2.2.4 owns repair
immediately after this plan slice and before typed operand rewriting.

The detached FormalIdentityPlan preserves source declaration metadata under
actor/transaction/formal tuples and allocates distinct direct private names
against source identifiers plus mandatory caller-supplied physical reservations.
Generated child formals keep their own module interface names. Scoped lookup
returns detached data and does not borrow another transaction's declaration.
The planner is intentionally not imported by the production scheduler yet;
.2/.3 still own typed rewriting, complete reservation integration, declaration
maps and source-facing binding reports. No emitted controller/port changes are
claimed by this leaf, and the production merge rejection remains a test control.

T1925 covers source declaration permutations, same-name formals, actor shadowing,
case-folded and concatenated-prefix collisions, type/width/reset isolation,
empty scopes, detached nested metadata and malformed owner/context controls.
The first run only failed its integration-boundary assertion because the regex
expected "conflicting width" while the actual diagnostic says "signal width
for 'status' conflicts across transactions". The assertion now matches that
exact mechanism; no lowerer behavior was changed to satisfy it.

- [x] **ROOT CAUSE (WHY + WHERE)** — first.log records the existing merge
  rejection at perl/FSM/Scheduler/ISF/LoweringIR.pm line 5610: direct formal
  status is merged under actor status's physical identity. The paired parser
  probe additionally reports an out-of-range rejection at
  perl/FSM/Adapter/ISF/Parser.pm line 747 when the formal is wider; reversing
  widths incorrectly admits the same operation. These are distinct mechanisms.
- [x] **ADDRESSED (verified)** — T1925 proves a detached, deterministic owner
  plan with separate physical identities and preserved local declarations,
  while generated child interfaces keep their authored names. The scope repair
  now has explicit typed-rewrite/integration children and a scheduled parser
  prerequisite. The planner does not claim a production scope or parser fix.
- [x] **NO REGRESSION** — .artifacts/formal-identity-plan/focused.log reports
  All tests successful for T1925, T1924, T1546, T1241 and T1243. Existing logical
  membership, generated identifier policy and transaction binding/report
  behavior remain covered. The new module is not in the production import tree.

Re-derivation uses the planner tests and retained parser source cases.
Falsification changes declaration order, reservation case/prefixes, ownership
shape, lookup data and actor/formal width direction. Durability is the module,
test, canonical scope card and tracked parser audit, with .49.2.2.4 next.
The book now names the actual formal-width limitation instead of implying
that an actor-side width qualifies a shadowing transaction formal. Runtime
scope and controller qualification remains open; no new DEVELOPMENT_NOTES
entry is needed beyond the canonical scope record and decision 0109.


## Parser formal-width prerequisite — `.49.2.2.4`

Bit operations, set-field, rotate and bit/field tests all use
Parser::_bit_op_width_map. These passes run before interface/transaction port
width and type finalization. Preserve the declared-literal helper contract:
an unresolved formal must shadow an actor declaration even when it cannot yet
supply a literal width. A type placeholder must not count as a real width.
Probe typed actor interface placeholders as a same-helper control before
changing lookup precedence; any confirmed defect remains owned by this leaf.

The typed actor-interface control confirms a second defect in the same helper:
an output declared with an eight-bit type still carries the parser's temporary
width 1 during desugaring. clear-bit value 0 becomes `(set value (& value 0))`;
type finalization then emits an eight-bit output with that wrong zero mask.
The exact source/clauses are retained in .artifacts/formal-bit-width/type-probe.log.
This leaf owns an immediate fail-closed repair: type-derived width is unresolved
at this pass and must not use its placeholder as literal evidence. Preserve
existing symbolic-width boundaries instead of silently introducing early type
or parameter finalization. Qualify actor-interface and formal type controls,
literal defaults, and the ordinary storage/local/interface positive cases.

The shared width helper now checks transaction ports before actor interface
ports and storage, after the existing local declarations. An unresolved formal
retains its name with unknown width, preventing fallback to another scope.
Type-derived interface/formal widths remain unknown at this early pass instead
of using parser placeholders. Width-dependent helpers fail closed under the
existing literal-width contract; this does not introduce early type/parameter
finalization. The typed wrong-mask source and exact before/after evidence are
tracked in docs/audits/formal-bit-width-placeholder-20260927.json.

T1926 exercises set/clear/toggle, set-field, both rotations and bit/field test
variants with actor/formal widths reversed; it checks exact inverse masks,
port-only and genuinely defaulted widths, nested bodies and unresolved actor
parameter, transaction parameter and type cases. Its public production cases
cover a direct port-only body and a generated child shadowing actor storage.
Complete check/semantic/schedule reports agree over native/API/newline MCP,
every emitted IAL0 file strict-replays, and generated HDL compiles and executes
repeated activations plus reset-aborted/restarted work with actor state intact.
Direct same-name actor/formal physical merging is still owned by .49.2.2.3.

The first T1926 run completed those production controls successfully but failed
parser assertions: a retained params clause shifted an assumed array index,
and rotation uses a distinct "requires 0 < N < width" diagnostic. The tests
now select the actual set clause and match that range diagnostic. Production
code did not change to accommodate either test mistake. qualified.log is the
fresh verbose successful run and explicitly includes both compile/runtime
results without skips. regression.log separately qualifies the existing
bit/field/rotate suites and T1924/T1925; book-examples.log passes the updated
complete examples. The book and normative data-manipulation reference now
state exact precedence and literal/type boundaries with a runnable formal
example. The original typed baseline is source/IAL0 evidence, not a claimed
baseline HDL simulation.

- [x] **ROOT CAUSE (WHY + WHERE)** — The tracked reversed-width audit shows
  both wrong rejection and wrong acceptance because _bit_op_width_map omitted
  transaction ports. type-probe.log independently exposes a typed output's
  placeholder-derived zero mask before its resolved width is emitted. The
  corrected source reports the refusal at perl/FSM/Adapter/ISF/Parser.pm line 761,
  rather than generating that mask.
- [x] **ADDRESSED (verified)** — T1926 proves local formal precedence, exact
  masks and range checks, no outer-width borrowing for unresolved formals,
  and refusal of type-placeholder masks. Production direct and generated
  literal-formal executions pass repeated/reset controls; authored actor
  storage remains unchanged by the generated child's local formal operations.
- [x] **NO REGRESSION** — qualified.log, regression.log and book-examples.log
  under .artifacts/formal-bit-width report All tests successful. They cover
  exact public transport reports, strict artifact replay, production HDL
  compile/runtime, every existing shared-helper family, prior scope/shadow
  tests and runnable book examples. No full-CI or browser visual result is claimed.

Re-derivation is the paired source/AST audits and exact parsed mask checks.
Falsification reverses actor/formal widths, uses unresolved and default widths,
executes independent arithmetic outcomes, repeats activation and resets during
work. Durability is T1926, both tracked audits, the canonical helper fact and
synchronized book/spec. Typed scope rewriting .49.2.2.2 is next. The established
literal-width helper boundary owns the fail-closed policy; no separate new
DEVELOPMENT_NOTES rationale is needed.

The inventory refresh correctly detected a stale candidate identity for the
edited data-manipulation support-matrix row. Its existing derived-gate
classification and data/field evidence remain; migrate the identity and extend
its distinct legs with Parser.pm and T1926 scope/runtime controls. Regenerate
the inventory only after staging that bounded disposition update.


The first full doctrine run exposed claim-registry ordering/group ownership
requirements and a wrapped root-cause signature. The migrated matrix record
retains its fixed general_book group owner, with sorted path legs and candidate
order; the current parser task still owns the actual change. Keep the exact
Perl diagnostic locus together on one acceptance line. Rerun the complete gate
after these evidence-format corrections; no production/test behavior changed.


## Typed scoped operand resolver — `.49.2.2.2` (in flight)

Prerequisites .49.2.2.1 and .4 are committed. The resolver must consume the
normalized parsed transaction/rule forms, preserve source-owned labels,
transaction/callee names, type/member names, messages and specialization
parameters, and distinguish caller actuals from callee formal endpoints.
The eventual integration must retain original source binding metadata before
physical renaming; inferred physical storage may expose distinct private names.
Named drives remain actor-owned bodies, while inline drive assignments are
transaction operand positions. Point labels and state_active identities are
not signal operands. Unknown grammar needs a precise refusal rather than a
recursive string replacement. Aggregate/scalar suffix and static qualified
constant disambiguation need explicit qualification before production use.

FormalIdentityPlan currently proves allocation only against source identifiers
and the caller's supplied complete physical reservations. .3 must establish
that completeness for generated counters, monitors, state/DT labels, handoffs
and other declarations, including authored transaction names resembling
private prefixes. A detached plan cannot itself prove that integration fact.

## Detached expression/endpoints — `.49.2.2.2.1`

FormalOperandResolver consumes the identity plan plus explicit owner/local/static
scope sets. Only typed runtime reference roots are renamed; exact named static
values, aggregate member spelling, state/point identities and timing metadata
retain their roles. Operator policy is reused from the carrier. Source binding
entries and physical entries are returned separately, with a detached callee
identity. Generated child public names remain unchanged. The normalized clause
walker is a separate next commit, followed by production integration.

This helper is deliberately not a second semantic/type checker. It requires
complete caller-supplied static and local context, does not validate nonformal
reference existence or binding width/timing admission, and does not allocate
physical names. The integration leaf retains those obligations plus explicit
reservation completeness and authored report projection. No runtime repair or
new public API/MCP surface is claimed from the detached helper.

### Acceptance — detached expression/endpoints

- [x] **ROOT CAUSE (WHY + WHERE)** — The retained collision.pl probe still fails
  with `signal width for 'data' conflicts across transactions while merging 'main'`
  at perl/FSM/Scheduler/ISF/LoweringIR.pm line 5610. The formal planner cannot
  resolve runtime operands by itself; blind replacement would also rename
  callee/source identities. T1927 retains that production boundary and contrasts
  explicitly scoped caller/callee endpoints with actor, generated and static roles.
- [x] **ADDRESSED (verified)** — T1927 passes in first.log and regression.log:
  normalized runtime expressions rewrite matching caller roots, bindings use
  callee identities, generated interfaces remain public, nested source data and
  constructor contexts stay isolated, and unknown grammar fails precisely.
  Production integration remains owned by .49.2.2.3, not closed by this helper.
- [x] **NO REGRESSION** — regression.log reports `All tests successful` for
  T1927/T1925/T1924/T1241/T1243/T40/T58/T283/T1262. These cover existing carrier
  grammar, aggregate paths, controller shadow and public binding reports.
  The synchronized book retains the runtime/scope warning; book build and
  staged doctrine results are recorded before commit below.

Claim legs: re-derive the role transformations with T1927; falsify with its
same-spelling source roles, actor/generated scope, invalid paths/operators and
mutation controls; durability is the checked-in helper/test, canonical scope
card and task record. Existing API/MCP reports are covered by binding regressions;
there is no public query change requiring a new feature corpus entry.
DEVELOPMENT_NOTES is unchanged because these contracts belong in the canonical
card/task and existing decision 0109. Artifact cleanup is not due: its latest
record is 2026-09-26T19:14:38+00:00, checked at 2026-09-27T06:15:29Z.

Book verification: `mdbook build docs/book` succeeds under the RAM guard with
its destination derived from the repository root; book.log is retained beside
regression.log. Browser visual review remains the separately owned blocker.

## Normalized clause walker — `.49.2.2.2.2` (in flight)

The preceding detached operand slice committed after the staged doctrine gate
and commit hook both passed; its message records that result. The next walker
must retain existing source admission rules before physical rewriting: a renamed
formal cannot make a formerly rejected duplicate local declaration legal.
Stage ready/valid endpoints and monitor-within observations explicitly resolve
against actor interfaces in current lowering, and ATL trigger endpoints are
already generated actor wiring. These require actor identity preservation,
not transaction lexical substitution. Named drive actuals remain caller-owned.

The dynamic-wait grammar currently declares operators outside the carrier
operator table (including bitwise-not and logical conjunction/disjunction).
Before deciding walker support, reproduce their actual admission/emission path;
do not infer a working surface or silently narrow it from the declarations alone.

Grammar investigation result: dynamic-wait's local arity table accepts `~`,
`&&`, `||` and unary concat, but unchanged serialization reaches the carrier
and fails there. Strict check and HDL generation reject them; the known-width
addition control succeeds. This is a validator/diagnostic consistency defect,
not evidence of silently emitted working hardware. Priority prerequisite .5
owns repair after this walker and before .3 integration. The walker will use
carrier-supported expression roles and retain precise refusal for these forms.
The first positive probe used unsized 1 and correctly failed known-width
inference; the corrected control uses `(+ cycles cycles)`.

## Normalized clause resolution qualification — `.49.2.2.2.2`

FormalClauseResolver now rewrites detached transaction/rule records using the
committed operand helper. Runtime clause positions are explicit; nested bodies
retain source structure. Activation records include source/physical bindings
and structural paths. Named-drive arguments use caller scope while drive names
and actor definitions remain untouched. Bank names, stage endpoints, monitor
observations and ATL wiring retain actor identity. Phase annotations and static
parameter structures are copied without interpreting them as runtime code.
Property traversal preserves window/depth operands, state/point names and text.

The helper requires parsed, source-validated records and complete local/static
context, not a second language-admission pass. Integration must preserve
original legality, static-zero pruning and source reports before rewriting.
The local/formal collision control specifically prevents renaming from making
an already-invalid duplicate declaration legal. Placement and collision-safe
allocation still belong to .3; no public query or execution route imports this
helper yet. The dynamic-wait shape discrepancy is independently owned by .5.

### Acceptance — normalized clause resolver

- [x] **ROOT CAUSE (WHY + WHERE)** — T1928's parsed shadowing fixture still
  reaches the production merge failure `signal width for 'data' conflicts`;
  the same mechanism is retained in collision.log from the preceding slice
  at perl/FSM/Scheduler/ISF/LoweringIR.pm line 5610. Typed scalar expressions
  alone cannot distinguish source labels, callee formal endpoints, static
  parameters, actor-only endpoints and nested statement operands.
- [x] **ADDRESSED (verified)** — T1928 compares exact expected clause arrays
  under same-spelling role collisions, retains separate source bindings and
  rewrites parsed bit-helper expansion. Its transformed source-shadow fixture
  passes `--strict --check --json` carrier replay while actor width/reset and
  formal width remain separate. Every emitted FSM carrier from the tracked
  controller cohort also passes strict replay; source actors stay identical.
  cohort.log reports `All tests successful` after adding that cohort.
- [x] **NO REGRESSION** — regression.log reports `All tests successful` for
  T1928/T1927/T1925/T1241/T1243/T1412/T1417/T1418/T1244. Existing expression,
  activation/report, temporal-property and wait contracts remain green.
  The later cohort addition also passes. The commit workflow requires the
  final staged doctrine gate and repeats it through the commit hook.

The first negative run caught a new local-option check using a regex in list
context: failure removed the first argument, letting the diagnostic label act
as a true condition. Explicit scalar context fixes it. The exact `(local
scratch (type data))` mutation now fails in T1928; first.log and diagnostic.log
retain the failing evidence, regression.log/cohort.log the passing evidence.
No previously shipped implementation had that new-helper mistake.

Claim legs: role assertions and parsed strict replay re-derive the result;
malformed clauses, same-spelling static/actor/source roles, local/formal
collisions and mutation isolation falsify it; checked-in helpers, T1928, the
canonical scope card and the retained wait audit provide durability. Current
API/MCP applicability is existing binding/report regression, because production
is unchanged. DEVELOPMENT_NOTES is unchanged: existing decision 0109 and the
canonical scope card own the implementation contract.

Book verification: the repository-derived `.artifacts/formal-clauses/book`
build succeeds; book.log is retained. The separate browser visual-audit blocker
is unchanged. Staged doctrine and hook results belong to the commit evidence.

## Dynamic-wait grammar alignment — `.49.2.2.5` (in flight)

The clause-walker commit and its hook are complete. Fix the wait-local arity
policy to accept only the currently supported carrier intersection, without
reinterpreting bitwise-not as logical-not or logical conjunction as bitwise
conjunction. Retain source spelling and artifact/report parity for working
operators. Unsupported source already fails strict checks/generation; the
repair moves the failure to wait validation instead of emitting invalid carrier.

During this review, 13h's runtime-wait fragments were found stale after the
count-predicate repair. The first example still combines `start` and the raw
multi-bit `cycles` signal. The canonical wait fact and T1909 prove why even
positive values fail that expression and why current lowering tests nonzero.
The drift recurs across nested/consecutive/expression examples. .6 owns the
book census and repair immediately after .5; it cannot be closed by a passing
fragment-skipping book extractor or by changing the prose in 13b alone.

The pre-fix T1929 run fails its expected early-refusal tests: direct lowering
and schedule queries accept invalid carrier shapes, while strict check/semantic
queries reject downstream. It also detects a separate public diagnostic
sanitizer defect: the quoted division operator in the carrier hint becomes
`[absolute-path-redacted]` only in API/MCP output. .52 owns that small repair
immediately after this grammar slice. All working-operator controls pass in
before.log. No production source was edited while those queries ran.

The first post-fix T1929 run passes check/semantic failure-report parity but
reveals an incorrect test assumption for failed schedule queries: only check
and semantic have public failure-report schemas. `bin/fsmgen` schedule failure
uses stderr/nonzero exit, and the MCP adapter intentionally returns its bounded
message-only error (canonical semantic-introspection-mcp-frontier, .31.2.2,
T1868). Adjust the schedule negative oracle to that documented contract; do not
invent a schedule failure schema or classify this existing boundary as a defect.
Working schedule reports still require exact complete native/API/MCP parity.

### Acceptance — wait/carrier grammar alignment `.49.2.2.5`

- [x] **ROOT CAUSE (WHY + WHERE)** — The retained baseline grammar audit shows
  wait-local shape acceptance followed by `Unsupported expression operator '~'`
  at perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm line 975. The local table
  also admits logical conjunction/disjunction spellings and unary concat;
  serialization does not translate them. T1929 before.log proves direct lower
  and schedule admission, downstream check/semantic refusal, and passing
  supported-operator controls before the repair.
- [x] **ADDRESSED (verified)** — qualified.log reports `All tests successful`
  for T1929: unsupported direct/nested forms fail at wait validation, while
  retained operators still strict-replay and preserve authored count metadata.
  Complete check/semantic native/API/newline reports match. Failed schedule
  queries use the existing nonzero native/message-only adapter contract;
  working schedule reports retain complete parity. No new schema is invented.
- [x] **NO REGRESSION** — regression.log reports `All tests successful` for
  T1909/T1244/T1928/T1868. T1909 ran with the Darwin Verilator runtime flag and
  repository-derived GHDL provider; the provider was executable and Verilator
  available. Its SystemVerilog and GHDL timing/sampling checks pass, alongside
  the wait lowering, scoped clause replay and public failure-report controls.
  book.log records a successful root-derived mdBook build.

Claim legs: T1929's RED/GREEN wait rejection and unchanged supported controls
re-derive the grammar result; strict carrier replay, malformed nested forms,
complete protocol reports and T1909's independent runtime oracles falsify it;
T1929, the baseline audit, canonical wait card and synchronized book/spec retain
it. DEVELOPMENT_NOTES is unchanged because the wait card owns this boundary.
Full staged doctrine and commit-hook results are captured in commit evidence.
The sanitizer .52 and stale book-fragment .6 defects remain owned and scheduled;
this successful grammar repair does not close either one.

Workflow correction: the first staged gate rejected the missing root child-list
link for newly owned .52. Added that link; all implementation/claim checks in
that run passed. Rerun the complete staged gate before commit.
