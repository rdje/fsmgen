# ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE: Same-Value Activation Overrides For Contract Windows

## Metadata

- Tree ID: `ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Allow generated child activation-site parameter overrides that target a child
temporal contract-window parameter only when the override resolves to the same
positive integer cycle count as the child transaction parameter default.

This narrows the current fail-closed boundary without selecting full
per-activation temporal monitor specialization.

## Non-Goals

- Do not specialize generated child temporal monitors per activation site,
  generated top, child instance, or rule-trigger edge.
- Do not generate per-instance child `.fsm` variants.
- Do not add schedule-report keys, schema versions, or public report fields.
- Do not widen contract-window value sources beyond the already shipped
  positive literal, actor constant, actor scalar parameter, qualified package
  scalar constant, and same-transaction scalar parameter default sources.
- Do not accept mismatched activation-site overrides for contract-window
  parameters; they must continue to fail closed until true specialization is
  selected.
- Do not change unrelated activation overrides, unknown-name diagnostics,
  shape diagnostics, generated top emission, HDL projection, or temporal
  monitor semantics.

## Acceptance Criteria

- Same-value activation overrides on `spawn`, generated blocking `do`, and rule
  `trigger` are accepted when the targeted generated child parameter is used as
  that child transaction's bounded eventual contract window.
- The accepted same-value override may be a decimal or exact-width literal, or
  any already-supported static activation override source that resolves to the
  same positive integer as the child parameter default.
- Mismatched activation overrides for child contract-window parameters keep a
  targeted fail-closed diagnostic that explains full override-specialized
  contract-window lowering remains deferred.
- Existing unknown parameter and parameter-shape diagnostics keep their current
  precedence.
- Generated child `.fsm` monitors still lower from the child transaction
  definition's resolved default; generated top parameter override syntax remains
  unchanged.
- Focused regression coverage proves accepted same-value overrides and rejected
  mismatched overrides for `spawn`, generated `do`, and rule `trigger`.
- The ISF spec, downstream integration handoff, public contract, mdBook, task
  tree, README index, roadmap, and live docs are synchronized.
- Focused validation passes, the broader ISF gate runs when warranted, and each
  completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE`
  Status: `done`
  Goal: `Ship bounded same-value activation overrides for generated child contract-window parameters.`
  Children: `ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE.1`,
  `ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE.2`

- ID: `ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE.1`
  Status: `done`
  Goal: `Select the bounded same-value override slice and record the frontier before code changes.`
  Acceptance: `Task tree, roadmap, task index, README, and live docs name the active implementation frontier, exact behavior boundary, non-goals, documentation impact, and verification scope. No parser, scheduler, generated artifact, HDL, schedule-report, public API, or runtime behavior changes.`
  Verification: `passed: feature-backlog/live-book/book matrix audits with Files=3, Tests=364; mdbook build docs/book; git diff --check`
  Commit: `this commit`

- ID: `ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE.2`
  Status: `done`
  Goal: `Implement same-value activation override acceptance for generated child temporal contract-window parameters.`
  Acceptance: `Lowering accepts same-value contract-window parameter overrides for spawn, generated do, and rule trigger; mismatches still fail closed with a targeted diagnostic; unknown/shape diagnostics keep precedence; generated child monitors and reports remain default-resolved; public docs/book/contract/handoff are synchronized; focused and appropriate broader gates pass.`
  Verification: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1366-isf-contract-activation-override-windows.t`; `prove -Iperl t/1366-isf-contract-activation-override-windows.t`; focused contract/public/spec/book tests; `./bin/ci-regression isf --no-book`; final public/spec/book audits; `mdbook build docs/book`; `git diff --check`
  Commit: `pending this commit`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE.2` shipped same-value activation override acceptance for generated child contract-window parameters. |

## Decisions

- `2026-05-25`: Selected same-value activation override acceptance as the next
  temporal-contract slice because it removes a false negative in the current
  diagnostic boundary without requiring per-instance monitor specialization or
  new generated child module variants.
- `2026-05-25`: Mismatched override values remain fail-closed. The existing
  generated child monitor is emitted once from the child transaction
  definition's resolved default, so an override that changes the resolved cycle
  count would silently produce the wrong monitor unless a future task selects a
  true specialization strategy.

## Open Questions

- None. Full override-specialized temporal monitor lowering remains a future
  feature and does not block this bounded same-value slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: doc/book audits Files=3, Tests=364` |
| `2026-05-25` | `ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE.2` | syntax checks; focused contract/public/spec/book tests; `./bin/ci-regression isf --no-book`; final public/spec/book audits; `mdbook build docs/book`; `git diff --check` | `passed: focused Files=13, Tests=453; broad Files=272, Tests=1732; final audits Files=5, Tests=368` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE.1` | `this commit: ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE.1: select same-value contract-window overrides` | `selection leaf; no behavior change` |
| `ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE.2` | `pending this commit: ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE.2: accept same-value contract-window overrides` | `implementation slice; closes the tree` |

## Changelog

- `2026-05-25`: Created active task tree, completed the selection leaf in the
  working tree, and set `.2` as the implementation frontier.
- `2026-05-25`: Shipped same-value activation override acceptance for generated
  child temporal contract-window parameters and closed the task tree.
