# R8-LANGUAGE-CONTRACT-EXIT-AUDIT: Language Contract Exit Audit

## Metadata

- Tree ID: `R8-LANGUAGE-CONTRACT-EXIT-AUDIT`
- Status: `active`
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
  Status: `active`
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
  Status: `pending`
  Goal: `Audit R8 exit criteria and select close-out, handoff, or one bounded follow-up.`
  Acceptance: `The audit identifies current evidence for every R8 exit criterion, names any still-unclear parser-visible construct family, and records whether the next safe step is implementation, documentation truth sync, roadmap handoff, or R8 close-out. No behavior changes are made in this audit leaf.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R8-LANGUAGE-CONTRACT-EXIT-AUDIT.2` | `pending` | `R8` still lists remaining gray-zone families and support-claim coverage as exit criteria; the next safe step is evidence gathering before declaring closure or selecting more behavior. |

## Decisions

- `2026-05-24`: After closing
  `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT`, select a separate `R8` exit audit
  instead of assuming the lane is done. `ROADMAP_STATUS.md` still records
  `R8` as `in progress` with remaining gray-zone/support-claim work, so the
  next PNT activity is an audit-only frontier that can either close `R8`
  honestly, hand work to another lane, or select one more bounded construct
  family.

## Open Questions

- None. `.2` owns the evidence review and next-slice selection.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R8-LANGUAGE-CONTRACT-EXIT-AUDIT.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R8-LANGUAGE-CONTRACT-EXIT-AUDIT.1` | `R8-LANGUAGE-CONTRACT-EXIT-AUDIT.1: select R8 exit audit` | `selection slice` |

## Changelog

- `2026-05-24`: Created active `R8` language-contract exit audit tree and
  selected `.2` as the audit/design frontier.
