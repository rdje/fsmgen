# NEXSIM-SEMANTIC-API-MCP-CONSUMER-REQUIREMENTS: Agent Consumer Contract

## Metadata

- Tree ID: `NEXSIM-SEMANTIC-API-MCP-CONSUMER-REQUIREMENTS`
- Status: `deferred`
- Roadmap lane: `Verification infrastructure / external simulator operability`
- Created: `2026-08-02`
- Last updated: `2026-08-02`
- Owner: repo-local workflow

## Goal

Publish and maintain a precise, implementation-neutral statement of everything
an expert engineering agent should be able to discover, inspect, control, and
verify through NEXSIM's semantic API and MCP layer. The contract must be useful
to NEXSIM as an external consumer specification without disclosing or imposing
FSMGEN-private intent-language or reference-simulator architecture.

## Non-Goals

- Do not claim that NEXSIM, PGEN, or any MCP adapter currently implements the
  requested capabilities.
- Do not define NEXSIM internals, storage, scheduler implementation, parser
  architecture, or programming language.
- Do not expose or require FSMGEN-private xIAL, IASIM, IR, lowering, or backend
  structures in the public NEXSIM contract.
- Do not make MCP the semantic authority; the native typed API remains primary
  and MCP is one bounded transport/operability projection.
- Do not implement a simulator client, provider adapter, runtime integration,
  or qualification claim in this documentation task.

## Acceptance Criteria

- A canonical, Git-tracked document defines requirement language, scope,
  principles, capability discovery, identity/provenance, compile/elaboration,
  static and runtime semantic introspection, scheduler causality, execution
  control, UVM, assertions, coverage, traces, replay, mutation, orchestration,
  security, performance, MCP projection, error behavior, conformance, and
  evolution requirements.
- Requirements distinguish mandatory foundations from recommended and optional
  capabilities, and distinguish inspection from authorized state-changing
  control.
- Examples use generic HDL/UVM concepts and stable opaque identities; they do
  not require knowledge of FSMGEN-private intent architecture.
- The document explicitly separates requested future behavior from observed
  NEXSIM capability and includes a durable amendment process.
- The mdBook renders the canonical document through one source of truth, with
  ordinary prose split into readable paragraphs rather than stitched blobs.
- Task index, bounded Memory, Knowledge Map, and live-document containment stay
  synchronized; focused documentation and doctrine gates pass.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `NEXSIM-SEMANTIC-API-MCP-CONSUMER-REQUIREMENTS`
  Status: `deferred`
  Goal: `Maintain the versioned external-consumer requirements for NEXSIM's semantic API and MCP operability surface.`
  Children: `NEXSIM-SEMANTIC-API-MCP-CONSUMER-REQUIREMENTS.1, NEXSIM-SEMANTIC-API-MCP-CONSUMER-REQUIREMENTS.2`

- ID: `NEXSIM-SEMANTIC-API-MCP-CONSUMER-REQUIREMENTS.1`
  Status: `done`
  Goal: `Publish the complete version-1 agent-consumer requirements baseline.`
  Acceptance: `The canonical document and its mdBook rendering cover the full bounded API/MCP feature set, priorities, examples, security/performance constraints, conformance gates, non-claims, and amendment protocol without exposing FSMGEN-private internals.`
  Verification: `The 2,251-line/99,361-byte baseline contains 365 unique requirement IDs in 45 numbered sections and 51 recommended MCP operation mappings. It contains no xIAL/IASIM vocabulary; native API authority, bounded MCP projection, requested/accepted/implemented/verified separation, typed values, snapshots, causality, control, mutation, replay, UVM, assertions, coverage, timing/power/mixed-language, safe overlays/experiments, security, scale, conformance, priorities, and amendment rules are explicit. The focused regression passes Files=9/Tests=94 after synchronizing the exact 1,021-member index fixture. Knowledge Map passes at 1,105 facts/5,681 questions/5,847 occurrences/118 shards. All 50 mdBook chapters test; the repository-local HTML build contains 86 files/17,564 KiB, and the included chapter contains 463 balanced paragraph elements with a longest 451-character paragraph. The exact build is removed; the rejected wrong destination and correct destination are both absent. Live-document containment passes all 22 surfaces with two exact file-ceiling authorities and one maintained-reference change.`
  Commit: `this commit (NEXSIM-SEMANTIC-API-MCP-CONSUMER-REQUIREMENTS.1: publish agent-consumer contract)`

- ID: `NEXSIM-SEMANTIC-API-MCP-CONSUMER-REQUIREMENTS.2`
  Status: `deferred`
  Goal: `Amend the consumer contract as NEXSIM schemas, prototypes, capability evidence, and director feedback become concrete.`
  Acceptance: `Each amendment identifies its trigger, preserves version history and compatibility meaning, updates conformance priorities/examples, and never converts requested capability into an observed support claim without evidence.`
  Verification: `pending the version-1 baseline and future concrete input`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Version 1.0 is canonical, book-rendered, indexed, contained, and verified without making a NEXSIM support claim. |
| 2 | `.2` | `deferred` | Director-deferred until concrete schemas, prototypes, capability evidence, or new feedback justify reactivation. |

## Decisions

- `2026-08-09`: The director deferred this tree and the evidence-driven `.2`
  amendment lane. The version-1 baseline remains canonical and current, but
  no NEXSIM-dependent work is PNT-eligible until explicit reactivation.

- `2026-08-02`: Use a standalone external-consumer contract rather than burying
  requirements inside an FSMGEN qualification leaf. This lets NEXSIM consume
  the request without learning or coupling to FSMGEN-private architecture.
- `2026-08-02`: Treat the native semantic API as authoritative and MCP as a
  typed, bounded projection. This preserves non-MCP clients and prevents a
  transport protocol from defining simulator meaning.
- `2026-08-02`: Keep the tree active after the version-1 baseline; `.2` is the
  explicit amendment owner, not permission to rewrite history silently.
- `2026-08-02`: Decision `0052` makes the native typed semantic API
  authoritative, MCP its faithful bounded projection, and the standalone
  specification independent of both NEXSIM internals and client-private
  architecture.

## Open Questions

- Exact NEXSIM release, API schema, MCP protocol profile, and implemented
  capability subset remain future evidence questions; none blocks publication
  of the consumer-side requirements baseline.

## Blockers

- None for completed `.1`. Deferred `.2` requires explicit reactivation plus
  concrete schemas, prototypes, capability evidence, or director feedback.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-08-02` | `.1` | 365-ID canonical contract; Files=9/Tests=94; 50-chapter mdBook test; 86-file/17,564-KiB build; 463 balanced HTML paragraphs; Knowledge Map; task/live-doc/ceiling/reference gates; exact cleanup | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `this commit` | Publish the implementation-neutral agent-consumer requirements baseline; `.2` remains proposed for evidence-driven amendments. |

## Acceptance Checklist (enforced) — director deferral

- [x] **ROOT CAUSE (WHY + WHERE)** — Completed `.1` already publishes the
  version-1 external-consumer baseline. `.2` cannot make an evidence-driven
  amendment because no concrete NEXSIM schema, prototype, implemented
  capability report, or new feedback exists, and the director explicitly
  deferred NEXSIM-dependent work on 2026-08-09.
- [x] **ADDRESSED (verified)** — The root and `.2` are `deferred`, the active
  index no longer presents this tree as PNT-eligible, the canonical baseline
  remains unchanged, and the task, book, fact, HIAL provider leaf, and bounded
  Memory all require explicit reactivation plus concrete evidence.
- [x] **NO REGRESSION** — Task integrity, Knowledge Map generation/check, all
  52 mdBook chapter tests, `git diff --check`, and final staged doctrines pass.
  No requirement ID, schema, example, requested capability, implementation
  claim, runtime integration, or product behavior changes.

## Acceptance Checklist (enforced) — `.1` baseline

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'live_maintainer_reference'
  --oneline --
  scripts/focused_document_index.pl` identifies containment commit `ea1b76dd5`,
  whose exact classification list could not recognize the new standalone
  consumer contract. The first focused run consequently reported
  `focused-document-index: expected classified path is absent:
  docs/NEXSIM_API_MCP_AGENT_CONSUMER_REQUIREMENTS.md`; after classification it
  also exposed the adjacent exact census/fixture at 1,020 rather than 1,021.
  More fundamentally, prior project prose described only a future deep
  semantic API/MCP direction and did not give NEXSIM a complete implementation-
  neutral consumer specification.
- [x] **ADDRESSED (verified)** — The canonical 2,251-line contract now carries
  365 unique requirement IDs, 45 numbered sections, 51 suggested MCP operation
  mappings, explicit non-claims, four delivery priorities, four conformance
  levels, examples, and an amendment protocol. Decision `0052`, roadmap,
  mdBook include/SUMMARY, fact card/Knowledge Map, generated focused index,
  exact surface authorities, task/index, and bounded Memory route one durable
  truth. `t/1569` now seeds the newly classified document and expects the exact
  1,021-member projection.
- [x] **NO REGRESSION** — The RAM-guarded focused suite reports `All tests
  successful` at `Files=9, Tests=94`. All 50 mdBook chapters test; its
  repository-local build has 86 files/17,564 KiB and the rendered NEXSIM
  chapter has 463 opening/closing paragraph tags with longest paragraph 451
  characters. `knowledge-map: OK` reports 1,105 facts/5,681 questions/5,847
  occurrences/118 shards; all 22 live-document surfaces, two new exact ceiling
  authorities, one maintained-reference aggregate change, relative paths, task
  integrity, source syntax, diff hygiene, final staged doctrines, and exact
  artifact cleanup are required to remain green through commit.
