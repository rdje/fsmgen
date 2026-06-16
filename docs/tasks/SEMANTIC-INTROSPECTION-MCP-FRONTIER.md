# SEMANTIC-INTROSPECTION-MCP-FRONTIER: Semantic Introspection And MCP Frontier

## Metadata

- Tree ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER`
- Status: `active`
- Roadmap lane: `Embedding And Public APIs / AI integration`
- Created: `2026-06-14`
- Last updated: `2026-06-15`
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
  while the user has made semantic introspection the active priority.

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
  Children: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.1`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.2`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.3`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.4`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.5`,
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.6`

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
  Status: `pending`
  Goal: `Deepen read-only diagnostic, example, and support-accounting MCP query coverage.`
  Acceptance: `Extend the read-only adapter with richer bounded query envelopes for diagnostic explanations, example discovery, and support-accounting summaries without exposing raw private objects or enabling writes; preserve workspace-root/source identity policy; update focused tests, manifest/docs/mdBook/Memory/Knowledge Map/task-tree/README/roadmap; run focused plus continuity gates.`
  Commit: `pending`

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
| 1 | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.6` | `pending` | `.5` hardened protocol/client behavior; the next exact frontier is deeper read-only diagnostic/example/support-accounting query coverage. |

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
- `2026-06-14`: Create this as a proposed owner, not an active implementation
  lane. The first real work must be no-code contract selection over existing
  public surfaces.
- `2026-06-14`: Keep MCP as an adapter over stable semantic APIs. The public
  contract remains the bounded FSMGen semantic/check/capability/lowering
  surfaces, consistent with backend-language-neutral IAL contracts.

## Open Questions

- None for `.5`; `.6` owns deeper diagnostic/example/support-accounting query
  coverage.

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

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.1` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.1: capture MCP introspection owner` | Proposed owner capture only; no implementation active. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.2` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.2: activate first-class introspection` | Activated semantic introspection as a first-class feature and selected `.3`, the contract-manifest implementation owner. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.3` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.3: ship introspection contract manifest` | Shipped the top-level `semantic_introspection` capability-manifest contract and selected `.4`, the read-only MCP adapter frontier. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.4` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.4: ship read-only MCP adapter` | Shipped `bin/fsmgen-mcp`, a read-only local JSON-RPC stdio adapter over the manifest-selected resources/tools, with workspace-root source binding and path sanitization. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.5` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.5: harden MCP protocol envelopes` | Hardened JSON-RPC protocol error handling, notification behavior, source URI percent-encoding validation, and source-query provenance envelopes. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.6` | `pending` | `pending` |

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
