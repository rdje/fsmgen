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
    `R8-STRICT-SUPPORT-TIER-CUTS.2`,
    `R8-STRICT-SUPPORT-TIER-CUTS.3`

- ID: `R8-STRICT-SUPPORT-TIER-CUTS.1`
  Status: `done`
  Goal: `Select the R8 strict-mode task tree and establish the audit frontier.`
  Acceptance: `The active tree, roadmap status, live docs, README index, and task-tree table name this tree, and the next leaf is limited to an audit/design boundary before behavior changes.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `R8-STRICT-SUPPORT-TIER-CUTS.1: select strict support-tier work`

- ID: `R8-STRICT-SUPPORT-TIER-CUTS.2`
  Status: `done`
  Goal: `Audit current strict-mode enforcement and choose one bounded compatibility cut.`
  Acceptance: `The audit identifies shipped strict-mode rejection families, accepted canonical replacements, corpus classification impact, docs coverage, and one bounded next implementation leaf or a documented close-out decision. No behavior changes are made in this audit leaf.`
  Verification: `passed: focused strict/composition/corpus tests, mdBook build, and diff check`
  Commit: `R8-STRICT-SUPPORT-TIER-CUTS.2: audit strict support-tier frontier`

- ID: `R8-STRICT-SUPPORT-TIER-CUTS.3`
  Status: `pending`
  Goal: `Reject legacy composition slash-link wiring tokens in strict mode.`
  Acceptance: `Default mode continues to accept '?wiring' legacy '/source/target/' tokens as compatibility input, strict mode rejects that token family with a targeted diagnostic that points to canonical '(source target)' or '(connect source target)' list forms, corpus accounting records paired default-compatible and strict-rejected entries, and mdBook/regression corpus docs describe the strict-mode boundary.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R8-STRICT-SUPPORT-TIER-CUTS.3` | `pending` | Composition slash-link wiring tokens are documented compatibility input with canonical list-form replacements, making them a bounded strict-mode cut. |

## Decisions

- `2026-05-24`: Select R8 strict support-tier widening as the next active PNT
  lane after closing the aggregate-operator tree. The roadmap still lists R8
  as in progress, and its remaining work is to widen strict-mode enforcement
  beyond the current root-family, section-level, and assignment-surface cuts.
  The first executable frontier is an audit so the next rejection can be
  chosen from evidence rather than guesswork.
- `2026-05-24`: The audit selected legacy composition `?wiring`
  `/source/target/` slash-link tokens as the next bounded strict-mode cut.
  The canonical replacement is already shipped and documented:
  `(source target)` or `(connect source target)`. Default mode compatibility
  must remain intact, and strict mode should reject only the slash-token
  family in composition wiring.

## Audit Result

Strict mode currently rejects these compatibility families through
`FSM::Pipeline::SourceFrontend`:

- Legacy direct `+fsm` roots.
- Legacy `?module:` direct-root aliases.
- Empty legacy `(+size)` sections.
- Legacy or misleading reset spellings such as `(asreset rstn)` and
  `(sreset rstn)`.
- Compact top-level init/default directives such as `(:= signal=value)`.
- Legacy infix assignment forms such as `(OUT = SRC)`.
- Legacy `<=+` assignment aliases for `<=-`.
- Legacy child source roots under generated `?fsmc` and `?dtc` children.

Regression corpus accounting records paired compatibility and strict-rejected
entries for the shipped strict-mode cuts, and every strict-rejection entry has
compiled diagnostic and migration-hint patterns. Positive supported-smoke
entries marked `strict_supported` must also pass through strict pipeline and
strict CLI execution.

The next safe cut is composition `?wiring` slash-link tokens. The composition
book already presents `(source target)` as the canonical directed-link form,
`(connect source target)` as the verbose equivalent, and `/source/target/` as
older compatibility input. Existing parser diagnostics already reject malformed
or wrapped slash-link usage. The selected implementation leaf should add only
the strict-mode rejection for the well-formed legacy slash-link token family,
with default mode preserving compatibility.

## Open Questions

- None for `.2`. The next active frontier is `.3`.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R8-STRICT-SUPPORT-TIER-CUTS.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |
| `2026-05-24` | `R8-STRICT-SUPPORT-TIER-CUTS.2` | `prove -Iperl t/239-strict-mode-legacy-fsm-root-boundary.t t/240-strict-mode-standalone-dt-alias-boundary.t t/245-strict-mode-fsm-child-root-boundary.t t/251-strict-mode-empty-size-boundary.t t/254-strict-mode-asreset-boundary.t t/257-strict-mode-compact-init-boundary.t t/295-strict-mode-infix-assignment-boundary.t t/410-strict-mode-legacy-lteplus-boundary.t t/14-composition-parser.t t/126-composition-parser-token-diagnostics.t t/248-regression-corpus-accounting.t t/249-regression-corpus-classified-behavior.t t/296-regression-corpus-supported-behavior.t`; `mdbook build docs/book`; `git diff --check` | `passed: focused strict/composition/corpus tests Files=13, Tests=3281` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R8-STRICT-SUPPORT-TIER-CUTS.1` | `R8-STRICT-SUPPORT-TIER-CUTS.1: select strict support-tier work` | `selection slice` |
| `R8-STRICT-SUPPORT-TIER-CUTS.2` | `R8-STRICT-SUPPORT-TIER-CUTS.2: audit strict support-tier frontier` | `audit/design slice` |
| `R8-STRICT-SUPPORT-TIER-CUTS.3` | `pending` | `implementation slice` |

## Changelog

- `2026-05-24`: Created active R8 strict support-tier task tree and selected
  the audit/design frontier.
- `2026-05-24`: Audited the shipped strict-mode cuts and selected composition
  `?wiring` slash-link token rejection as the next bounded implementation
  leaf.
