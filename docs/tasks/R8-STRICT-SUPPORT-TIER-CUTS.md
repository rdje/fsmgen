# R8-STRICT-SUPPORT-TIER-CUTS: Strict Support-Tier Cuts

## Metadata

- Tree ID: `R8-STRICT-SUPPORT-TIER-CUTS`
- Status: `active`
- Roadmap lane: `R8`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Continue widening strict-mode enforcement so `--strict` increasingly accepts
only the fully supported `.fsm` language contract while default mode can still
carry intentional compatibility residue.

## Non-Goals

- Do not remove compatibility behavior from default mode unless a later leaf
  explicitly selects that migration.
- Do not add broad strict-mode rejection sweeps without one named construct
  family, fixture impact audit, diagnostic contract, and documentation update.
- Do not change ISF strict-mode behavior under this tree unless an R8 leaf
  explicitly names an `.isf`-generated `.fsm` support-tier boundary and syncs
  the ISF public documents.
- Do not change generated HDL semantics for sources that are already accepted
  by the fully supported strict-mode contract.

## Acceptance Criteria

- The current strict-mode support-tier boundary is audited across direct
  `.fsm`, standalone `.dt`, composition child sources, regression corpus
  classification, diagnostics, mdBook guidance, and live docs.
- Each behavior-bearing leaf names one exact compatibility construct family
  and one accepted canonical replacement before code changes begin.
- Strict-mode success and failure coverage is updated in the same slice as any
  behavior change.
- The mdBook strict-mode chapter, regression corpus docs, roadmap status, and
  live docs stay synchronized with the shipped boundary and remaining
  compatibility residue.
- Broader validation runs when a leaf touches shared strict-mode frontend
  scanning, regression corpus support accounting, CLI diagnostics, or
  pipeline source handling.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R8-STRICT-SUPPORT-TIER-CUTS`
  Status: `active`
  Goal: `Widen strict mode through exact, reviewable support-tier cuts.`
  Children: `R8-STRICT-SUPPORT-TIER-CUTS.1`,
    `R8-STRICT-SUPPORT-TIER-CUTS.2`

- ID: `R8-STRICT-SUPPORT-TIER-CUTS.1`
  Status: `done`
  Goal: `Select the R8 strict-mode task tree and establish the audit frontier.`
  Acceptance: `The active tree, roadmap status, live docs, README index, and task-tree table name this tree, and the next leaf is limited to an audit/design boundary before behavior changes.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `R8-STRICT-SUPPORT-TIER-CUTS.1: select strict support-tier work`

- ID: `R8-STRICT-SUPPORT-TIER-CUTS.2`
  Status: `pending`
  Goal: `Audit current strict-mode enforcement and choose one bounded compatibility cut.`
  Acceptance: `The audit identifies shipped strict-mode rejection families, accepted canonical replacements, corpus classification impact, docs coverage, and one bounded next implementation leaf or a documented close-out decision. No behavior changes are made in this audit leaf.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R8-STRICT-SUPPORT-TIER-CUTS.2` | `pending` | R8 still has strict-mode widening left, and the next support-tier cut needs an explicit audit before behavior changes. |

## Decisions

- `2026-05-24`: Select R8 strict support-tier widening as the next active PNT
  lane after closing the aggregate-operator tree. The roadmap still lists R8
  as in progress, and its remaining work is to widen strict-mode enforcement
  beyond the current root-family, section-level, and assignment-surface cuts.
  The first executable frontier is an audit so the next rejection can be
  chosen from evidence rather than guesswork.

## Open Questions

- None for `.1`. The next active frontier is `.2`.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R8-STRICT-SUPPORT-TIER-CUTS.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R8-STRICT-SUPPORT-TIER-CUTS.1` | `R8-STRICT-SUPPORT-TIER-CUTS.1: select strict support-tier work` | `selection slice` |
| `R8-STRICT-SUPPORT-TIER-CUTS.2` | `pending` | `audit/design slice` |

## Changelog

- `2026-05-24`: Created active R8 strict support-tier task tree and selected
  the audit/design frontier.
