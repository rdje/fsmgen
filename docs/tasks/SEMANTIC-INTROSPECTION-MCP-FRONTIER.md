# SEMANTIC-INTROSPECTION-MCP-FRONTIER: Semantic Introspection And MCP Frontier

## Metadata

- Tree ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER`
- Status: `active`
- Roadmap lane: `Embedding And Public APIs / AI integration`
- Created: `2026-06-14`
- Last updated: `2026-09-24`
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
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.2, SEMANTIC-INTROSPECTION-MCP-FRONTIER.3, SEMANTIC-INTROSPECTION-MCP-FRONTIER.4, SEMANTIC-INTROSPECTION-MCP-FRONTIER.5, SEMANTIC-INTROSPECTION-MCP-FRONTIER.6, SEMANTIC-INTROSPECTION-MCP-FRONTIER.7, SEMANTIC-INTROSPECTION-MCP-FRONTIER.8, SEMANTIC-INTROSPECTION-MCP-FRONTIER.9, SEMANTIC-INTROSPECTION-MCP-FRONTIER.10, SEMANTIC-INTROSPECTION-MCP-FRONTIER.11, SEMANTIC-INTROSPECTION-MCP-FRONTIER.12, SEMANTIC-INTROSPECTION-MCP-FRONTIER.13, SEMANTIC-INTROSPECTION-MCP-FRONTIER.14, SEMANTIC-INTROSPECTION-MCP-FRONTIER.15, SEMANTIC-INTROSPECTION-MCP-FRONTIER.16, SEMANTIC-INTROSPECTION-MCP-FRONTIER.17, SEMANTIC-INTROSPECTION-MCP-FRONTIER.18, SEMANTIC-INTROSPECTION-MCP-FRONTIER.19, SEMANTIC-INTROSPECTION-MCP-FRONTIER.20, SEMANTIC-INTROSPECTION-MCP-FRONTIER.21, SEMANTIC-INTROSPECTION-MCP-FRONTIER.22, SEMANTIC-INTROSPECTION-MCP-FRONTIER.23, SEMANTIC-INTROSPECTION-MCP-FRONTIER.24, SEMANTIC-INTROSPECTION-MCP-FRONTIER.25, SEMANTIC-INTROSPECTION-MCP-FRONTIER.26, SEMANTIC-INTROSPECTION-MCP-FRONTIER.27, SEMANTIC-INTROSPECTION-MCP-FRONTIER.28, SEMANTIC-INTROSPECTION-MCP-FRONTIER.29, SEMANTIC-INTROSPECTION-MCP-FRONTIER.30, SEMANTIC-INTROSPECTION-MCP-FRONTIER.31, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32`

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
  Verification: `Caller bundle: ../specforge/docs/fsmgen-issues/sf-isf-undeclared-rule-operand/README.md; SPECFORGE owner FSMGEN-REQUESTS.2. Structural identity repair is committed as 45c0e579c23f3c693e7537de1693e5ef6a07cccd; clean tree, empty message file and derived ahead count verified before activation. Read supplied cases without changing SPECFORGE; preserve exact hashes when copying to task-owned local fixtures. Missing-operand reproduction and repair are complete under .32.1.1; the separate width-diagnostic repair remains active under .32.1.2.`
  Commit: `pending`

  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.1, SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.2`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.1`
  Status: `done`
  Goal: `Validate declared ISF rule read operands before actor-shell return and scheduling.`
  Acceptance: `Reject undeclared scalar and nested-expression reads in rule guards and value/index operands before IAL0 inference. Preserve declared ports/storage, actor constants/parameters, enum and aggregate leaves, and supported ATL trigger actions. Keep transaction-local inferred assignment behavior separate. Collect useful actor/rule/operand context deterministically and register the expected-failure fixture with stable FSMGEN_LANGUAGE_ISF_UNDECLARED_RULE_OPERAND metadata; qualify exact supplied cases, public API, native check/semantic/schedule, MCP and generated-port controls. Use focused rule/symbol regressions and supported-source admission checks; synchronize book/facts and commit.`
  Verification: `At 45c0e579c, all supplied cases are copied byte-for-byte into .artifacts/specforge-undeclared-rule/ with hashes. The one-bit undeclared source passes strict check and semantic emission with VALID exposed in signal_analysis and structural_rtl_ir input ports. Both invalid variants pass schedule preview. The mixed-width variant fails late as a width mismatch on B. The baseline parser checked form and special enum/aggregate domains without rejecting an ordinary unknown scalar token. The repair refuses both supplied invalid variants before lowering, preserves declared controls and has complete evidence in docs/audits/specforge-rule-admission-20260924/.`
  Commit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.1: reject undeclared ISF rule reads`

  Compatibility prerequisite: `The first complete public-adapter census exposes generated AXI endpoint/composition rule reads of undeclared shared state. Endpoint generators and composition coordinators now declare those captured payloads, launch/arm handoffs, active/completion flags and expected response IDs as actor storage at their intended widths. No name whitelist or promotion of transaction-private values is used. Scheduled FSM differences are explicit size declarations; endpoint and composition SV is otherwise byte-identical after removing only date headers. Both component baselines and repairs pass the existing independent protocol behavior oracles. The complete ordinary public-adapter census passes; every affected endpoint and composition passes native/API/newline MCP check, semantic and schedule comparison. See the acceptance evidence and retained receipts below.`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.2`
  Status: `active`
  Goal: `Preserve authored ISF source context in operand-contract failures without implementation diagnostics.`
  Acceptance: `Reproduce a declared but width-invalid ISF control independently of the missing-operand repair. Trace generated-to-authored source mapping and backend exception presentation, repair confirmed leaked implementation paths/names in public diagnostics, and qualify native/API/MCP error identity with targeted direct/ISF controls. Keep this boundary separate from successful actor admission.`
  Verification: `The supplied mixed-width baseline reports its temporary ial1-lowering FSM as source_file and exposes OperandContractValidationSupport.pm plus validate_pre_generation_operand_contract() in the message. Reproduce the remaining width-error path after .32.1.1 before editing it.`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.2`
  Status: `pending`
  Goal: `Prevent issue bundles from attributing an exported FSMGen copy to a foreign enclosing Git revision.`
  Acceptance: `Reproduce sf-tool-issue-bundle-foreign-git-head in an isolated repository-local fixture. Require demonstrable FSMGen repository identity or unknown consistently in bundle records; qualify a real checkout, non-Git export nested in a foreign repository, and relevant environment/worktree controls. Preserve public helper/capability contracts. Document complete exact-revision export setup and known-good preflight before downstream differential censuses; never repair an old export with current-revision resources.`
  Verification: `Caller bundle: ../specforge/docs/fsmgen-issues/sf-tool-issue-bundle-foreign-git-head/README.md; SPECFORGE owner FSMGEN-REQUESTS.3. Current reproduction pending; bundled default temporary-directory behavior must not be used.`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.3`
  Status: `pending`
  Goal: `Support bounded derived actor width parameters with symbolic dependency preservation.`
  Acceptance: `Audit existing public expression contracts, then decompose sf-isf-derived-width-parameter into bounded parameter resolution, symbolic lowering/emission, ceiling arithmetic and clog2, refusal diagnostics, and semantic/API/MCP qualification leaves. Verify default and overridden widths independently in emitted HDL; document derived-parameter override policy, integer division meaning and intentional optional inline-width boundary. Reject undeclared/later/cyclic/runtime operands, zero divisors and invalid widths. Preserve existing scalar/aggregate parameter behavior.`
  Verification: `Caller bundle: ../specforge/docs/fsmgen-issues/sf-isf-derived-width-parameter/README.md; SPECFORGE owner FSMGEN-REQUESTS.1. Current reproduction and contract reconciliation pending. Reported corpus counts remain externally supplied claims.`
  Commit: `pending`

- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.4`
  Status: `pending`
  Goal: `Repair emitted protocol ISF artifacts that bypass executable IAL1 lowering.`
  Acceptance: `Before derived-width feature work, audit generated ISF round-trip admission against published artifact contracts. Root-cause every refusal and decompose repairs by protocol and safe lowering boundary. Require generated ISF to be executable through the public ISF parser/scheduler where advertised, preserve protocol-specific behavior with independent HDL oracles, remove parallel handwritten IAL0 bypasses, and synchronize report/API/MCP/book claims. Do not introduce IAL2-only syntax into ISF or relabel executable artifacts as mere review prose to close the defect.`
  Verification: `The .32.1.1 compatibility probe obtains ahb_interconnect.isf from the public PPIF adapter for ppif/ahb_interconnect.ppif; ISF admission fails at unknown actor clause address-map. AhbInterconnect::_build_ahb_interconnect_artifacts separately calls _build_ahb_interconnect_isf and _build_ahb_interconnect_fsm; the first emits address-map/decode/behavior clauses unsupported by Parser::_build_actor, while normal source generation uses the separately built FSM. Existing knowledge calls these review artifacts, but docs/book/src/14i-ahb-and-integration.md claims lowering through ISF and IAL2-FEATURE-COMPLETENESS-FRONTIER forbids bypassing that chain. This is a pre-existing architecture/documentation gap, not evidence that the new operand validator rejects valid rules. Root-cause evidence is retained under docs/audits/specforge-rule-admission-20260924/; full artifact census and repair remain owned here.`
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

`SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.2` is active: repair authored-source
provenance in independently reproduced operand-width diagnostics. Admission
repair `.32.1.1` is done; bundle provenance, generated-interconnect lowering
and derived widths follow under `.32.2`, `.32.4` and `.32.3`.
Own any demonstrated gap before returning to HIAL
streaming. Preserve spent native compiler/startup evidence and the separate
read-only/write horizon; source checks do not promote runtime support.

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
