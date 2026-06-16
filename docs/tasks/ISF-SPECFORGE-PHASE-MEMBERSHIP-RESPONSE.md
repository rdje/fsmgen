# ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE: SPECFORGE Transaction Phase-Membership Response

## Metadata

- Tree ID: `ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE`
- Status: `done`
- Roadmap lane: `Downstream ISF handoff / verification-generation alignment`
- Created: `2026-06-16`
- Last updated: `2026-06-16`
- Owner: repo-local workflow

## Goal

Answer SPECFORGE's `2026-06-16` question about lowering grounded
transaction phase membership without fabricating drive values or step order,
and record FSMGen's `.isf` versus future `.val` stance in the established
tracked response channel.

## Non-Goals

- Do not change the parser, scheduler, lowerer, generated `.fsm`, HDL,
  schedule JSON, public contract code, or support accounting in this tree.
- Do not edit the SPECFORGE repository. FSMGen responds only in
  `docs/SPECFORGE_FEEDBACK_RESPONSE.md`.
- Do not implement transaction phase-group metadata, value-less drives,
  unordered bodies, `.val`, SV/UVM, VHDL verification output, or any public
  CLI artifact in this response slice.
- Do not use `.val` as a replacement for `.isf` in SPECFORGE's synthesizable
  `IntentIR -> .isf -> FSMGen` path.

## Acceptance Criteria

- `docs/SPECFORGE_FEEDBACK_RESPONSE.md` adds a dated response to the
  SPECFORGE request and answers:
  value-less output participation, unordered/partial-order body semantics,
  phase-group metadata, and ordering-as-constraint versus ordering-as-body.
- The response states that no immediate FSMGen code change is required to
  answer the question, while future checked ISF phase-group metadata would
  require a separate task-tree-owned implementation slice.
- The response keeps named `drive` calls value-bearing and transaction bodies
  source-ordered; SPECFORGE should not fabricate values or total order.
- The response identifies checked transaction phase-group metadata as the
  appropriate future ISF feature for grounded membership/phase/role facts.
- The response clarifies that `.isf` remains the synthesizable source of truth;
  a future `.val` Verification Abstraction Layer, if selected, is only a
  verification-output/interchange artifact derived from `.isf` or schedule
  reports, not a SPECFORGE replacement target.
- Task-tree index, README, Memory, and Knowledge Map are synchronized if the
  response creates durable project state.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE`
  Status: `done`
  Goal: `Record FSMGen's answer to SPECFORGE's transaction phase-membership/value/order request.`
  Children: `ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE.1, ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE.2`

- ID: `ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE.1`
  Status: `done`
  Goal: `Create the task-tree owner and select the response boundary.`
  Acceptance: `The SPECFORGE request is read, the response is scoped as documentation/contract guidance with no runtime code change, and the response edit is owned before touching the response file.`
  Verification: `passed: git diff --check; scripts/check_memory_architecture.sh; positive owner scan`
  Commit: `ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE.1: select phase response`

- ID: `ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE.2`
  Status: `done`
  Goal: `Edit and commit the tracked FSMGen response.`
  Acceptance: `The response document records the dated answer, durable follow-on task-tree/Knowledge Map state is synchronized, doc-only validation passes, and the tree closes.`
  Verification: `passed: mdbook build docs/book; prove -Iperl t/1414-docs-relative-paths-audit.t; bash knowledge-map/scripts/check_knowledge_map.sh; scripts/check_memory_architecture.sh; git diff --check; positive response scan`
  Commit: `ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE.2: answer phase membership`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE.1` | `done` | The SPECFORGE request has been read and scoped as a no-runtime-change response. |
| 2 | `ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE.2` | `done` | Added the dated tracked response and closed the response loop without runtime code changes. |

## Decisions

- `2026-06-16`: Treat the SPECFORGE request as a documentation/contract
  response, not an immediate code change. The live code already behaves as
  SPECFORGE observed: transaction bodies are ordered and `drive` remains
  value-bearing.
- `2026-06-16`: Preserve `.isf` as SPECFORGE's synthesizable target. A future
  `.val` idea can be considered only as a verification-specific layer or
  artifact after `.isf`/schedule-report facts are selected.
- `2026-06-16`: Answer `.2`: do not treat bare `drive` as participation,
  do not encode unordered phase facts as transaction-body order, and route any
  future grounded phase membership handoff to checked transaction phase-group
  metadata in `.isf`, not to `.val`.

## Open Questions

- The exact future ISF syntax/report shape for transaction phase-group
  metadata remains unselected and must be owned by a future implementation
  tree before code changes.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-16` | `ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE.1` | `Read external SPECFORGE feedback request and current FSMGen response; git diff --check; scripts/check_memory_architecture.sh; positive owner scan` | `passed` |
| `2026-06-16` | `ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE.2` | `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check`; positive response scan | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE.1` | `ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE.1: select phase response` | `selection owner before response edit` |
| `ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE.2` | `ISF-SPECFORGE-PHASE-MEMBERSHIP-RESPONSE.2: answer phase membership` | `tracked response edited and tree closed` |

## Changelog

- `2026-06-16`: Created the task tree in response to SPECFORGE's
  transaction phase-membership/value/order request.
- `2026-06-16`: Added the tracked response. FSMGen's guidance is that
  SPECFORGE should keep ungrounded values/order as metadata/residuals for now;
  future checked transaction phase-group metadata belongs in `.isf`; `.val`
  is not a replacement for SPECFORGE's synthesizable ISF target.
