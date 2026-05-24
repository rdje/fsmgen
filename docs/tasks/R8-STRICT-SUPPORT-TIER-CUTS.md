# R8-STRICT-SUPPORT-TIER-CUTS: Strict Support-Tier Cuts

## Metadata

- Tree ID: `R8-STRICT-SUPPORT-TIER-CUTS`
- Status: `done`
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
  Status: `done`
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
  Status: `done`
  Goal: `Reject legacy composition slash-link wiring tokens in strict mode.`
  Acceptance: `Default mode continues to accept '?wiring' legacy '/source/target/' tokens as compatibility input, strict mode rejects that token family with a targeted diagnostic that points to canonical '(source target)' or '(connect source target)' list forms, corpus accounting records paired default-compatible and strict-rejected entries, and mdBook/regression corpus docs describe the strict-mode boundary.`
  Verification: `passed: focused strict/composition/corpus tests, diagnostic/check-json/semantic-json corpus gates, mdBook build, feature-backlog audit, and diff check`
  Commit: `R8-STRICT-SUPPORT-TIER-CUTS.3: reject slash wiring in strict mode`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `R8-STRICT-SUPPORT-TIER-CUTS.3` shipped the bounded composition slash-link strict-mode cut and closed this task tree. |

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
- `2026-05-24`: The implementation shipped that cut. Default mode still
  accepts well-formed `?wiring` `/source/target/` tokens as compatibility
  input. Strict mode now rejects the token family before HDL emission with
  `FSMGEN_STRICT_COMPOSITION_WIRING_SLASH_LINK` and a migration hint toward
  `(source target)` or `(connect source target)`. Positive strict-supported
  composition fixtures were migrated to canonical list wiring so strict mode
  remains a positive acceptance gate for the supported corpus.

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
- Legacy composition `?wiring` slash-link tokens such as
  `/source/target/`.

Regression corpus accounting records paired compatibility and strict-rejected
entries for the shipped strict-mode cuts, and every strict-rejection entry has
compiled diagnostic and migration-hint patterns. Positive supported-smoke
entries marked `strict_supported` must also pass through strict pipeline and
strict CLI execution.

The completed cut is composition `?wiring` slash-link tokens. The composition
book presents `(source target)` as the canonical directed-link form,
`(connect source target)` as the verbose equivalent, and `/source/target/` as
default-mode compatibility input. Existing parser diagnostics still reject
malformed or wrapped slash-link usage, while strict mode now rejects the
well-formed legacy slash-link token family with a stable strict-mode
diagnostic and migration hint.

## Open Questions

- None for `.3`. This task tree is closed; future strict-mode cuts should
  start with a fresh audit leaf or task tree.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R8-STRICT-SUPPORT-TIER-CUTS.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |
| `2026-05-24` | `R8-STRICT-SUPPORT-TIER-CUTS.2` | `prove -Iperl t/239-strict-mode-legacy-fsm-root-boundary.t t/240-strict-mode-standalone-dt-alias-boundary.t t/245-strict-mode-fsm-child-root-boundary.t t/251-strict-mode-empty-size-boundary.t t/254-strict-mode-asreset-boundary.t t/257-strict-mode-compact-init-boundary.t t/295-strict-mode-infix-assignment-boundary.t t/410-strict-mode-legacy-lteplus-boundary.t t/14-composition-parser.t t/126-composition-parser-token-diagnostics.t t/248-regression-corpus-accounting.t t/249-regression-corpus-classified-behavior.t t/296-regression-corpus-supported-behavior.t`; `mdbook build docs/book`; `git diff --check` | `passed: focused strict/composition/corpus tests Files=13, Tests=3281` |
| `2026-05-24` | `R8-STRICT-SUPPORT-TIER-CUTS.3` | `prove -Iperl t/411-strict-mode-composition-wiring-slash-boundary.t t/14-composition-parser.t t/126-composition-parser-token-diagnostics.t t/248-regression-corpus-accounting.t t/249-regression-corpus-classified-behavior.t t/296-regression-corpus-supported-behavior.t`; `prove -Iperl t/297-capability-manifest.t t/298-diagnostic-code-registry.t t/299-check-json-diagnostics.t t/300-check-json-regression-corpus.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t t/304-normalized-semantic-json-regression-corpus.t t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: focused strict/composition/corpus tests Files=6, Tests=3279; manifest/diagnostic/JSON/support gates Files=8, Tests=1131; feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R8-STRICT-SUPPORT-TIER-CUTS.1` | `R8-STRICT-SUPPORT-TIER-CUTS.1: select strict support-tier work` | `selection slice` |
| `R8-STRICT-SUPPORT-TIER-CUTS.2` | `R8-STRICT-SUPPORT-TIER-CUTS.2: audit strict support-tier frontier` | `audit/design slice` |
| `R8-STRICT-SUPPORT-TIER-CUTS.3` | `R8-STRICT-SUPPORT-TIER-CUTS.3: reject slash wiring in strict mode` | `implementation slice` |

## Changelog

- `2026-05-24`: Created active R8 strict support-tier task tree and selected
  the audit/design frontier.
- `2026-05-24`: Audited the shipped strict-mode cuts and selected composition
  `?wiring` slash-link token rejection as the next bounded implementation
  leaf.
- `2026-05-24`: Shipped the composition slash-link strict-mode cut, migrated
  strict-supported composition fixtures to canonical list wiring, and closed
  this task tree.
