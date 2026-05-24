# R8-LANGUAGE-CONTRACT-EXIT-AUDIT: Language Contract Exit Audit

## Metadata

- Tree ID: `R8-LANGUAGE-CONTRACT-EXIT-AUDIT`
- Status: `done`
- Roadmap lane: `R8`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Audit the remaining `R8` language-contract exit criteria and decide whether
the lane can close, should hand remaining work to a later roadmap lane, or
still has one bounded parser-visible `.fsm` construct family to resolve.

## Non-Goals

- Do not change parser, strict-mode, HDL, corpus, manifest, or generated
  behavior before the audit selects an exact follow-up.
- Do not classify broad roadmap themes as complete without evidence from the
  language reference, regression corpus, strict-mode boundary, mdBook, and
  capability/public metadata.
- Do not start `R9`/`R10`/`R11` work under this tree except to record an
  explicit handoff recommendation.

## Acceptance Criteria

- The audit maps the current `R8` exit criteria to concrete evidence in docs,
  tests, regression corpus accounting, strict-mode behavior, and public
  metadata.
- The tree either selects one bounded follow-up leaf, closes `R8` language
  contract hardening honestly, or records a precise handoff/defer decision for
  remaining work.
- Any behavior-bearing follow-up leaf includes focused tests and mdBook/live
  documentation synchronization.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R8-LANGUAGE-CONTRACT-EXIT-AUDIT`
  Status: `done`
  Goal: `Resolve the R8 exit decision from evidence instead of assumption.`
  Children: `R8-LANGUAGE-CONTRACT-EXIT-AUDIT.1`,
    `R8-LANGUAGE-CONTRACT-EXIT-AUDIT.2`

- ID: `R8-LANGUAGE-CONTRACT-EXIT-AUDIT.1`
  Status: `done`
  Goal: `Activate the R8 language-contract exit audit task tree.`
  Acceptance: `The active tree, roadmap status, task-tree table, live docs, and README index name this tree, and the next leaf is limited to an audit/design boundary before any behavior change or roadmap handoff.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `R8-LANGUAGE-CONTRACT-EXIT-AUDIT.1: select R8 exit audit`

- ID: `R8-LANGUAGE-CONTRACT-EXIT-AUDIT.2`
  Status: `done`
  Goal: `Audit R8 exit criteria and select close-out, handoff, or one bounded follow-up.`
  Acceptance: `The audit identifies current evidence for every R8 exit criterion, names any still-unclear parser-visible construct family, and records whether the next safe step is implementation, documentation truth sync, roadmap handoff, or R8 close-out. No behavior changes are made in this audit leaf.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `R8-LANGUAGE-CONTRACT-EXIT-AUDIT.2: audit R8 exit criteria`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | The audit found no next behavior-bearing R8 leaf; active implementation focus can hand off to `R9` strict-mode widening. |

## Decisions

- `2026-05-24`: After closing
  `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT`, select a separate `R8` exit audit
  instead of assuming the lane is done. `ROADMAP_STATUS.md` still records
  `R8` as `in progress` with remaining gray-zone/support-claim work, so the
  next PNT activity is an audit-only frontier that can either close `R8`
  honestly, hand work to another lane, or select one more bounded construct
  family.
- `2026-05-24`: Completed `.2` and closed the tree without a behavior-bearing
  follow-up. Current evidence shows the known default-mode compatibility
  residue is named in the `language_surface` manifest and paired in the
  regression corpus: legacy `+fsm`, `?module`, empty `(+size)`, misleading
  reset spellings, compact `:=`, infix assignments, legacy `<=+`,
  generated-child legacy roots, and composition slash-link wiring. The mdBook
  documents the user-facing language surface and strict-mode split, while the
  feature-backlog chapter owns broader partially shipped or deferred feature
  families. The remaining `R8` work is not a concrete unclassified
  parser-visible construct; it is ongoing support-claim maintenance that
  should continue as feature slices land. Mark `R8` as `mostly done` and hand
  active implementation focus to `R9`.

## Open Questions

- None. The tree is closed.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R8-LANGUAGE-CONTRACT-EXIT-AUDIT.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |
| `2026-05-24` | `R8-LANGUAGE-CONTRACT-EXIT-AUDIT.2` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R8-LANGUAGE-CONTRACT-EXIT-AUDIT.1` | `R8-LANGUAGE-CONTRACT-EXIT-AUDIT.1: select R8 exit audit` | `selection slice` |
| `R8-LANGUAGE-CONTRACT-EXIT-AUDIT.2` | `R8-LANGUAGE-CONTRACT-EXIT-AUDIT.2: audit R8 exit criteria` | `audit/roadmap handoff slice` |

## Changelog

- `2026-05-24`: Created active `R8` language-contract exit audit tree and
  selected `.2` as the audit/design frontier.
- `2026-05-24`: Completed `.2`; closed the tree, marked `R8` mostly done in
  the roadmap, and handed active implementation focus to `R9`.
