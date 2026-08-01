# 0048 — Achievement history is task trees, the mdBook, and Git

- Date: 2026-08-01
- Type: architecture/convention/feedback
- Status: accepted
- Supersedes: clause 6 of [0046](0046-project-documents-use-two-bounded-ledgers-and-canonical-live-views.md)
- Evidence owner: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.11`

## Context

The independent present-value audit measures the former achievement-status
journal at 16,618 lines / 955,308 bytes / SHA-256
`46c3c8ad2a0b7375a02b0a111bcc65410f78e0dd1df97709aeabe5f97b735d18`.
It was edited in 1,339 commits from `2026-05-10` through `2026-06-01`, then
remained byte-identical through 1,784 later commits at the audit revision.

No product, compiler, runtime, build, test, or executable consumer reads the
content. Its only distinct benefit is direct browsing of a hand-written,
partial 23-day digest. It no longer answers its claimed live recovery question:
the journal mixes selection and completion records with obsolete active-tree
and frontier snapshots.

The director independently selected retirement after reviewing this evidence.
The outcome does not depend on the separately retired changelog and says
nothing about the still-frozen roadmap-status record.

## Decision

1. Retire `LIVE_ACHIEVEMENT_STATUS.md` without a replacement status journal.
2. Route current completion evidence to the owning task node and work-unit Git
   commit, shipped behavior to the mdBook, active recovery to bounded Memory
   and the task index, rationale to decisions, and durable facts to Knowledge
   Cards.
3. Preserve the exact former object at revision
   `b4d07fee5ffd6621503007958dcac3af8d44b345` under the
   `fsmgen_required_history` retention contract. The archive descriptor and
   executable verifier must prove the line, byte, longest-line, and SHA-256
   identity and reject a recreated live path or unresolved current consumer.
4. Remove only current workflow, README navigation, book, and live-surface
   consumers. Historical tasks, decisions, audits, and sealed evidence remain
   truthful and directly addressable.
5. Assess `ROADMAP_STATUS.md` independently before changing its lifecycle.

## Consequences

- The project has no second manually curated completion-history projection.
- Exact historical prose remains recoverable with:

  ```sh
  git show b4d07fee5ffd6621503007958dcac3af8d44b345:LIVE_ACHIEVEMENT_STATUS.md
  ```

- A missing or rewritten required object, identity mismatch, recreated live
  path, or planted active/executable consumer fails the doctrine gate.
- The deletion lowers root-document pressure without claiming that raw
  repository history must remain fixed in size; bounded live retrieval and
  exact cold retention remain separate products.
