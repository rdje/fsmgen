# SEMANTIC-INTROSPECTION-MCP-WRITE-HORIZON: Beyond-Read-Only MCP Horizon

## Metadata

- Tree ID: `SEMANTIC-INTROSPECTION-MCP-WRITE-HORIZON`
- Status: `proposed`
- Roadmap lane: `Embedding And Public APIs / AI integration`
- Created: `2026-07-12`
- Last updated: `2026-07-12`
- Owner: repo-local workflow

## Goal

Track the horizon of extending the shipped semantic-introspection MCP surface
**beyond its deliberate read-only, closed-world boundary** — that is, whether and
how FSMGen should ever advertise write/generation MCP tools, server-initiated
model calls (`sampling/createMessage`), server-initiated user prompts
(`elicitation/create`), client `roots` consumption, or a long-lived/HTTP service
transport, without giving up the safety guarantees that make the current adapter
trustworthy.

This tree exists because `SEMANTIC-INTROSPECTION-MCP-FRONTIER` is `done` through
`.30` and shipped a first-class, **intentionally read-only** MCP surface:
`bin/fsmgen-mcp` (line-delimited JSON-RPC stdio, MCP protocol `2025-06-18`), the
`semantic_introspection` capability-manifest contract, `--emit-semantic-json`
across the semantic stack, catalog-backed source discovery, structured tool
results, and read-only closed-world tool annotations. Every leaf of that tree
explicitly refused writes, generation tools, sampling, elicitation, unbounded
roots, network/shell access, and commit/push authority. Crossing that boundary is
a genuinely new architecture question, not an increment of the read-only profile,
so it gets its own proposed owner rather than living only in session chat.

## Non-Goals

- Do not activate or implement anything in this capture; it is a proposed owner.
- Do not weaken or bypass the shipped read-only adapter's guarantees
  (no arbitrary shell, no unrestricted file writes, no ambient network, explicit
  `--workspace-root`/source identity) as a side effect of exploring the horizon.
- Do not add commit/push authority, arbitrary filesystem traversal, or ambient
  network serving to the MCP surface.
- Do not compile arbitrary agent instructions into hardware or IAL, or let an MCP
  client mutate the repo outside a bounded, reviewed, opt-in workflow.
- Do not treat "write-capable" as license to bypass the existing parser,
  validation, or `IAL2 -> IAL1 -> IAL0` / `IAL1 -> IAL0` lowering chains; any
  generation tool must route through the same checked pipeline as the CLI.
- Do not duplicate read-only-profile increments already owned by
  `SEMANTIC-INTROSPECTION-MCP-FRONTIER` (prompt templates, subscriptions,
  completions, logging, pagination, batch, Streamable-HTTP-for-read) — those are
  read-only refinements, not the beyond-read-only boundary this tree owns.

## Acceptance Criteria

- The beyond-read-only MCP horizon is durably captured as a proposed task-tree
  owner rather than living only in session chat.
- Future activation starts with a safety/design/selection leaf, not
  implementation.
- The first activation leaf decides which single capability (write/generation
  tool, sampling, elicitation, roots consumption, or long-lived transport) is the
  smallest safe first target, and defines its trust model, authorization/opt-in
  boundary, sandboxing, provenance, determinism, and rollback before any code
  changes.
- Any later implementation leaf keeps every generated artifact routed through the
  existing checked pipeline, preserves the read-only default, requires explicit
  opt-in for any mutating capability, and proves the read-only surface is
  unchanged.
- Each completed active leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `SEMANTIC-INTROSPECTION-MCP-WRITE-HORIZON`
  Status: `proposed`
  Goal: `Track whether and how the read-only semantic-introspection MCP surface should ever gain write/generation, sampling, elicitation, roots, or service-mode capabilities, safely.`
  Children: `SEMANTIC-INTROSPECTION-MCP-WRITE-HORIZON.1`

- ID: `SEMANTIC-INTROSPECTION-MCP-WRITE-HORIZON.1`
  Status: `proposed`
  Goal: `Select the first beyond-read-only MCP capability and its safety/trust boundary.`
  Acceptance: `Audit the shipped read-only adapter's safety model and the SEMANTIC-INTROSPECTION-MCP-FRONTIER deferrals (.11-.30). Choose the smallest safe first target among: (a) a bounded generation tool that emits checked .isf/.fsm/HDL through the existing CLI pipeline into an explicit, opt-in output location; (b) sampling/createMessage for a bounded semantic workflow; (c) elicitation/create for a bounded input; (d) client roots consumption in place of / alongside --workspace-root; or (e) a long-lived/HTTP service transport. Define its trust model, explicit opt-in/authorization boundary, sandboxing and path restrictions, provenance and determinism requirements, required tests/fixtures, docs/mdBook/Knowledge Map surface, rollback, and explicit non-goals. Record why the chosen target is the least-risk first step. No implementation begins in this leaf unless it is split into a later active implementation leaf.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

This tree is proposed and not PNT-eligible until the roadmap or user explicitly
activates it. The first activation must select the safety/design contract before
any adapter, manifest, tool, transport, or generated-artifact implementation
work.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `SEMANTIC-INTROSPECTION-MCP-WRITE-HORIZON.1` | `proposed` | Decide the smallest safe beyond-read-only capability and its trust boundary before any implementation. |

## Decisions

- `2026-07-12`: Capture the beyond-read-only MCP horizon (write/generation tools,
  sampling, elicitation, roots consumption, long-lived/HTTP transport) as a
  proposed owner. The shipped adapter is deliberately read-only and closed-world;
  crossing that boundary is a new safety/architecture question, not an increment
  of the read-only profile.
- `2026-07-12`: Any future mutating capability must default off, require explicit
  opt-in, route all generation through the existing checked
  `IAL2 -> IAL1 -> IAL0` / `IAL1 -> IAL0` pipeline, and never gain commit/push,
  arbitrary shell, ambient network, or unbounded filesystem authority.
- `2026-07-12`: The read-only surface remains the default and supported profile;
  this tree must never regress it.

## Open Questions

- Which capability is the safest first step: a bounded, opt-in generation tool
  (emit checked artifacts into an explicit output path) or a purely client-side
  feature like `roots` consumption that adds no mutation authority?
- Should sampling/elicitation ever be server-initiated from FSMGen, or is that a
  permanent non-goal for a build tool?
- What authorization/opt-in mechanism (CLI flag, manifest capability gate,
  per-tool annotation) is strong enough to make a mutating tool trustworthy?
- Does a long-lived/HTTP service mode belong here at all, or does it stay a
  read-only-profile transport decision under the original tree?

## Blockers

- Not blocked. It is intentionally proposed until selected by roadmap/user
  priority. Active priority remains the IAL2/IAL1 feature-completeness frontier.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-07-12` | `SEMANTIC-INTROSPECTION-MCP-WRITE-HORIZON.1` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `SEMANTIC-INTROSPECTION-MCP-WRITE-HORIZON.1` | `pending` | Proposed safety/design-selection leaf only; no implementation selected. |

## Changelog

- `2026-07-12`: Created proposed task tree to preserve the beyond-read-only MCP
  horizon for future selection, at the director's request, after confirming the
  shipped `SEMANTIC-INTROSPECTION-MCP-FRONTIER` surface is intentionally
  read-only and closed-world.
