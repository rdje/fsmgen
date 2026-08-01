# 0049 — Roadmap status is the roadmap, task trees, Memory, and Git

- Date: 2026-08-01
- Type: architecture/convention/feedback
- Status: accepted
- Supersedes: clause 5 of [0046](0046-project-documents-use-two-bounded-ledgers-and-canonical-live-views.md)
- Evidence owner: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.11`

## Context

The independent present-value audit measures the former roadmap-status board
at 15,039 lines / 1,638,574 bytes / longest line 5,716 / SHA-256
`0f8db932c57d883d97f1f92fec8a576795b5b367157d9846088501c52aeb22d8`.
It was edited in 2,760 commits from `2026-03-14` through `2026-06-01`, then
remained byte-identical through 1,786 later commits at the audit revision.

The file called itself the canonical live roadmap board while reporting no
active tree or frontier despite active task trees. No product, compiler,
runtime, or build consumer reads its content. One test scanned it only for the
absence of an obsolete ATL label, and one composition note inaccurately called
it an active source. Its sole distinct benefit is direct browsing of a partial
March-June 2026 chronology plus an R0-R14 snapshot.

The director independently selected retirement after reviewing that evidence.
The decision does not depend on the earlier changelog or achievement-journal
retirements.

## Decision

1. Retire `ROADMAP_STATUS.md` without a replacement status board.
2. Route high-level direction to `ROADMAP_V2.md`, active work and evidence to
   `docs/TASK_TREE.md` plus the owning task node, resume state to `MEMORY.md`,
   shipped behavior to the mdBook, and exact chronology to work-unit Git
   history.
3. Preserve the exact former object at revision
   `b4d07fee5ffd6621503007958dcac3af8d44b345` under the
   `fsmgen_required_history` retention contract. The archive descriptor and
   executable verifier must prove its line, byte, longest-line, and SHA-256
   identity and reject a recreated live path or unresolved current consumer.
4. Replace the stale test scan with assertions against maintained canonical ATL
   sources, correct the composition source route, and remove only current
   workflow, README, book, route, and surface consumers. Historical tasks,
   decisions, audits, and sealed evidence remain truthful and addressable.
5. Do not generate another combined status projection. A later bounded view
   requires a distinct reader question and its own task-tree/decision owner.

## Consequences

- Direction, execution state, recovery state, shipped behavior, and exact
  history each have one canonical authority rather than a synchronized prose
  duplicate.
- Exact historical prose remains recoverable with:

  ```sh
  git show b4d07fee5ffd6621503007958dcac3af8d44b345:ROADMAP_STATUS.md
  ```

- A missing or rewritten required object, identity mismatch, recreated live
  path, planted policy/executable consumer, or stale route fails the doctrine
  gate.
- The deletion lowers root-document pressure without deleting historical
  evidence or constraining legitimate growth of the maintained roadmap.
