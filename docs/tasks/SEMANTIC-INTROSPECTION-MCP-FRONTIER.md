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
    `SEMANTIC-INTROSPECTION-MCP-FRONTIER.4`

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
  Status: `pending`
  Goal: `Implement the first read-only MCP adapter over the semantic-introspection contract.`
  Acceptance: `Expose the manifest-selected read-only resource/tool families through a bounded local MCP adapter over the semantic_introspection contract; require explicit workspace-root/source identity handling for source-bound queries; do not enable write/generation tools, network access, arbitrary shell access, mutation workflows, commit/push actions, or raw private AST/scheduler/lowering/HDLGenerator payloads; add focused adapter tests plus manifest/docs/mdBook/Memory/Knowledge Map/task-tree/README/roadmap synchronization; run appropriate focused checks and continuity gates.`
  Verification: `pending`
  Commit: `pending`

## Candidate Contract Questions For `.4`

- Should the first adapter be a repo-local stdio MCP server over existing CLI
  JSON, a thin in-process Perl adapter, or a small wrapper that can support
  both without freezing service mode?
- How will `.4` bind `source_id` to explicit workspace-root-contained source
  paths without allowing arbitrary traversal or shell execution?
- Which selected `semantic_introspection.mcp_resources[]` can be implemented
  from cached manifest data, and which require per-source tool calls?
- How will the selected tools preserve check JSON, normalized semantic JSON,
  schedule JSON, diagnostics, support-accounting, and generated-output
  inventories without exposing raw private objects?
- What is the first adapter test harness: direct tool invocation, MCP protocol
  JSON fixtures, or both?
- How will adapter errors map back to stable FSMGen diagnostics or explicit
  unsupported-residue responses?
- How will the mdBook explain the shipped behavior without pretending future
  write/generation tools are already implemented?

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
| 1 | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.4` | `pending` | `.3` shipped the manifest-advertised semantic-introspection contract; the next exact frontier is the read-only MCP adapter over that contract. |

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
- `2026-06-14`: Create this as a proposed owner, not an active implementation
  lane. The first real work must be no-code contract selection over existing
  public surfaces.
- `2026-06-14`: Keep MCP as an adapter over stable semantic APIs. The public
  contract remains the bounded FSMGen semantic/check/capability/lowering
  surfaces, consistent with backend-language-neutral IAL contracts.

## Open Questions

- Whether the first adapter implementation should be CLI-driven, in-process
  Perl API, or a local long-lived service is intentionally left to future
  adapter leaf `.4`.

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
| `pending` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.4` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.1` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.1: capture MCP introspection owner` | Proposed owner capture only; no implementation active. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.2` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.2: activate first-class introspection` | Activated semantic introspection as a first-class feature and selected `.3`, the contract-manifest implementation owner. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.3` | `SEMANTIC-INTROSPECTION-MCP-FRONTIER.3: ship introspection contract manifest` | Shipped the top-level `semantic_introspection` capability-manifest contract and selected `.4`, the read-only MCP adapter frontier. |
| `SEMANTIC-INTROSPECTION-MCP-FRONTIER.4` | `pending` | `pending` |

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
  selected read-only MCP mappings, explicit safety policy, and no enabled MCP
  adapter or write/generation tools.
