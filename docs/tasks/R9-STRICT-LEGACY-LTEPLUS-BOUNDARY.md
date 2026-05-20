# R9-STRICT-LEGACY-LTEPLUS-BOUNDARY: Strict Legacy <=+ Boundary

## Metadata

- Tree ID: `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY`
- Status: `done`
- Roadmap lane: `R9`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Make strict mode reject the legacy `<=+` D-input dual-output assignment alias
while preserving default-mode compatibility and the preferred strict-supported
`<=-` spelling.

## Non-Goals

- Do not remove default-mode `<=+` compatibility.
- Do not change the preferred `<=-` assignment semantics.
- Do not change D-input self-dependency validation.
- Do not widen assignment operators, partial-LHS semantics, delayed-pulse
  semantics, or HDL lowering in this tree.
- Do not change ISF/ATL scheduling behavior.

## Acceptance Criteria

- The R9 strict-mode lane has task-tree ownership before source, test,
  fixture, or generated-artifact changes.
- The selected strict-mode cut is explicit: `<=+` is compatibility residue and
  strict users must author the preferred `<=-` spelling.
- Default mode continues to accept `<=+`.
- Strict mode rejects `<=+` through the shared frontend path with a targeted
  migration hint toward `<=-` and no HDL output.
- Strict mode still accepts canonical `<=-` pair forms, including the
  maintained partial-LHS fixture family.
- The maintained regression corpus separates strict-supported preferred
  partial-LHS fixtures from legacy `<=+` compatibility evidence.
- The mdBook, corpus documentation, roadmap, task tree, and live docs are
  synchronized with the behavior.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY`
  Status: `done`
  Goal: `Reject legacy '<=+' in strict mode while preserving default-mode
  compatibility.`
  Children: `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.1`,
  `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.2`

- ID: `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.1`
  Status: `done`
  Goal: `Select the legacy '<=+' strict-mode cut and scope fixture/doc
  reshaping.`
  Acceptance: `The task tree records '<=+' as the next high-signal R9
  compatibility cut after preferred '<=-' partial-LHS coverage, identifies the
  needed corpus fixture split, and selects '.2' as the bounded implementation
  leaf.`
  Verification: `static strict/corpus/book coverage audit`; `git diff --check`;
  `mdbook build docs/book`
  Commit: `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.1: select lteplus strict cut`

- ID: `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.2`
  Status: `done`
  Goal: `Implement the strict-mode '<=+' rejection and corpus/doc sync.`
  Acceptance: `Shared frontend strict mode rejects pair and infix '<=+'
  compatibility forms with an '<=-' migration hint, default mode still accepts
  '<=+', preferred '<=-' fixtures remain strict-supported, the legacy alias is
  cataloged as compatibility residue, and focused plus corpus checks pass.`
  Verification: `perl -Iperl -c perl/FSM/Pipeline/SourceFrontend.pm`;
  `perl -Iperl -c perl/FSM/Support/DiagnosticCodes.pm`;
  `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`;
  `perl -Iperl -c t/410-strict-mode-legacy-lteplus-boundary.t`;
  `perl -Iperl -c t/248-regression-corpus-accounting.t`;
  `prove -Iperl t/410-strict-mode-legacy-lteplus-boundary.t`;
  `prove -Iperl t/410-strict-mode-legacy-lteplus-boundary.t
  t/295-strict-mode-infix-assignment-boundary.t`;
  `prove -Iperl t/248-regression-corpus-accounting.t
  t/249-regression-corpus-classified-behavior.t
  t/261-regression-corpus-supported-language-features.t
  t/296-regression-corpus-supported-behavior.t`;
  `prove -Iperl t/297-capability-manifest.t
  t/298-diagnostic-code-registry.t t/299-check-json-diagnostics.t
  t/300-check-json-regression-corpus.t t/301-check-json-supported-corpus.t
  t/302-normalized-semantic-json.t
  t/303-normalized-semantic-json-supported-corpus.t
  t/304-normalized-semantic-json-regression-corpus.t`;
  `git diff --check`; `mdbook build docs/book`
  Commit: `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.2: reject legacy lteplus in strict mode`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.1` | `done` | Selected the next bounded strict-mode support-tier cut before code. |
| 2 | `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.2` | `done` | Implemented the selected strict-mode rejection, fixture split, and docs sync. |

This tree is closed. Legacy `<=+` is now default-mode compatibility residue,
while strict mode rejects it and points authors to preferred `<=-`.

## Decisions

- `2026-05-20`: Selected this R9 tree after the R8 preferred `<=-`
  partial-LHS coverage and delayed-pulse fail-closed boundary reached
  completion. The project now has direct evidence for the preferred `<=-`
  partial-LHS spelling, so `<=+` can move from strict-supported alias
  compatibility to default-mode-only compatibility residue.
- `2026-05-20`: The implementation leaf must preserve the default-mode
  compatibility path for `<=+`. The strict-mode change is a support-tier
  boundary, not a removal of the legacy source surface.
- `2026-05-20`: The maintained partial-LHS fixtures currently mix preferred
  `<=-` and legacy `<=+` coverage while being tagged `strict_supported`.
  `.2` must split or rewrite those fixtures so strict-supported entries prove
  preferred syntax, while a separate legacy asset proves default-mode
  compatibility and strict-mode rejection.
- `2026-05-20`: Completed `.2` by adding the shared strict-mode `<=+`
  scanner, stable diagnostic code, focused direct/CLI/child-source coverage,
  and a paired corpus fixture. The existing strict-supported partial-LHS
  corpus fixtures now use preferred `<=-` for D-input dual-output writes.

## Open Questions

- None for `.2`.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.1` | `static strict/corpus/book coverage audit`; `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-20` | `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.2` | `perl -Iperl -c perl/FSM/Pipeline/SourceFrontend.pm`; `perl -Iperl -c perl/FSM/Support/DiagnosticCodes.pm`; `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c t/410-strict-mode-legacy-lteplus-boundary.t`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `prove -Iperl t/410-strict-mode-legacy-lteplus-boundary.t`; `prove -Iperl t/249-regression-corpus-classified-behavior.t`; `prove -Iperl t/410-strict-mode-legacy-lteplus-boundary.t t/295-strict-mode-infix-assignment-boundary.t`; `prove -Iperl t/248-regression-corpus-accounting.t t/249-regression-corpus-classified-behavior.t t/261-regression-corpus-supported-language-features.t t/296-regression-corpus-supported-behavior.t`; `prove -Iperl t/297-capability-manifest.t t/298-diagnostic-code-registry.t t/299-check-json-diagnostics.t t/300-check-json-regression-corpus.t t/301-check-json-supported-corpus.t t/302-normalized-semantic-json.t t/303-normalized-semantic-json-supported-corpus.t t/304-normalized-semantic-json-regression-corpus.t`; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.1` | `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.1: select lteplus strict cut` | Selects `<=+` as the next R9 strict-mode support-tier cut. |
| `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.2` | `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.2: reject legacy lteplus in strict mode` | Rejects `<=+` in strict mode and splits corpus/docs. |

## Changelog

- `2026-05-20`: Created and activated the tree, completed `.1`, and selected
  `.2` for strict-mode `<=+` rejection and corpus/doc synchronization.
- `2026-05-20`: Completed `.2` and closed the tree.
