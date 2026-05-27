# ISF-CROSS-DOMAIN-REPEAT-BODY-DO-DIAGNOSTIC-PRECISION: Targeted Cross-Domain Repeat-Body Do Diagnostic

## Metadata

- Tree ID: `ISF-CROSS-DOMAIN-REPEAT-BODY-DO-DIAGNOSTIC-PRECISION`
- Status: `pending`
- Roadmap lane: `R14`
- Created: `2026-05-27`
- Last updated: `2026-05-27`
- Owner: repo-local workflow

## Goal

Improve diagnostic precision when a repeat-body generated `do` clause
attaches a `(domain NAME)` annotation that names a domain different from
the calling transaction's domain. Currently the validator emits the same
"requires static '(params ...)' overrides" diagnostic that fires for
malformed same-domain attempts, which misleads authors who intended
cross-domain activation. Cross-domain repeat-body `do` remains backlog
overall (the broader implementation needs explicit crossing primitives,
CDC sync wrappers, generated-top CDC instantiation, and report
extensions); this slice ships only the targeted diagnostic so authors get
a clear "cross-domain repeat-body do remains deferred" message instead of
a misleading params-required hint.

## Non-Goals

- Do not implement cross-domain repeat-body `do` lowering. The broader
  feature remains a separate future leaf of the same tree.
- Do not introduce new crossing-primitive syntax for `do`.
- Do not change validator behavior for same-domain `(domain)` annotations
  or for activations without `(domain)`.
- Do not change the existing `clock-domain violation` rejection path that
  fires when a cross-domain do is attempted without the `(domain)`
  annotation.

## Acceptance Criteria

- When a repeat-body, when-body nested repeat, or switch-branch nested
  repeat generated `do` carries a `(domain X)` annotation where `X` is
  different from the calling transaction's domain, the validator emits a
  targeted diagnostic naming "cross-domain repeat-body do remains
  deferred" instead of the misleading "requires static '(params ...)'
  overrides" message.
- The existing "requires static '(params ...)' overrides" diagnostic
  still fires for same-domain attempts that omit `(params)`.
- A new focused regression `t/1372-isf-cross-domain-repeat-body-do-diagnostic.t`
  covers the three nested-repeat contexts (top-level repeat-body,
  when-body nested repeat, switch-branch nested repeat) with the targeted
  diagnostic, plus negative-control cases that keep the same-domain and
  no-annotation rejections unchanged.
- Doc surfaces in `docs/ISF_SPEC.md`,
  `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`, and
  `docs/book/src/14-feature-backlog.md` note the new diagnostic. The
  `ISF_SPEC.md` focused-tests list registers `t/1372`.
- mdBook builds clean; `git diff --check` clean; focused tests pass;
  `./bin/ci-regression isf --no-book` passes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-CROSS-DOMAIN-REPEAT-BODY-DO-DIAGNOSTIC-PRECISION`
  Status: `done`
  Goal: `Sharpen the cross-domain repeat-body do diagnostic without changing accepted behavior.`
  Children:
    `ISF-CROSS-DOMAIN-REPEAT-BODY-DO-DIAGNOSTIC-PRECISION.1`,
    `ISF-CROSS-DOMAIN-REPEAT-BODY-DO-DIAGNOSTIC-PRECISION.2`

- ID: `ISF-CROSS-DOMAIN-REPEAT-BODY-DO-DIAGNOSTIC-PRECISION.1`
  Status: `done`
  Goal: `Select the targeted diagnostic slice; record scope, boundaries, regression target, and doc-sync targets.`
  Acceptance: `Task tree exists and is committed before any validator change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `pending`

- ID: `ISF-CROSS-DOMAIN-REPEAT-BODY-DO-DIAGNOSTIC-PRECISION.2`
  Status: `done`
  Goal: `Ship the targeted diagnostic at the three validator sites plus regression t/1372 plus doc updates.`
  Acceptance: `Cross-domain (domain ...) annotations get the targeted diagnostic; same-domain rejections unchanged; t/1372 passes; ISF CI passes.`
  Verification: `prove -Iperl t/1372 t/1215 t/1250 t/1305; ./bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | Both leaves shipped; `.2` landed the targeted diagnostic at all three nested-repeat sites, regression `t/1372`, doc-surface updates, and t/1247 expectation refresh. |

## Decisions

- `2026-05-27`: Picked from the Spawn Inside Repeat Bodies deferred list.
  Probed current behavior: `(do worker (domain aux))` with `worker` in
  `aux` and calling transaction in `core` currently emits "repeat-body
  generated do domain metadata requires static '(params ...)' overrides"
  because the validator treats every `(domain ...)` annotation as a
  same-domain feature attempt. This slice fixes the diagnostic; the
  broader cross-domain `do` implementation remains a separate future
  leaf of this tree.

## Open Questions

- None blocking this leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-27` | `ISF-CROSS-DOMAIN-REPEAT-BODY-DO-DIAGNOSTIC-PRECISION.1` | `mdbook build docs/book`; `git diff --check` | `PASS`; selection-only commit |
| `2026-05-27` | `ISF-CROSS-DOMAIN-REPEAT-BODY-DO-DIAGNOSTIC-PRECISION.2` | `prove -Iperl t/1247 t/1372 t/1250`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `PASS`; focused 3-file `Files=3, Tests=17`; mdBook clean; ISF CI passed; t/1247 expectations refreshed for new targeted diagnostic |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-CROSS-DOMAIN-REPEAT-BODY-DO-DIAGNOSTIC-PRECISION.1` | `13a8a8da ISF-CROSS-DOMAIN-REPEAT-BODY-DO-DIAGNOSTIC-PRECISION.1: select cross-domain repeat-body do diagnostic precision` | Selection commit. |
| `ISF-CROSS-DOMAIN-REPEAT-BODY-DO-DIAGNOSTIC-PRECISION.2` | `ISF-CROSS-DOMAIN-REPEAT-BODY-DO-DIAGNOSTIC-PRECISION.2: ship cross-domain repeat-body do diagnostic precision` | `pending commit hash` |

## Changelog

- `2026-05-27`: Created active R14 task tree for the targeted cross-domain
  repeat-body do diagnostic precision slice. Cross-domain repeat-body do
  itself remains deferred; this slice ships the user-visible diagnostic
  improvement and registers the broader implementation as a future leaf.
- `2026-05-27`: Shipped `.2`. Validator at
  `perl/FSM/Scheduler/ISF/LoweringIR.pm` now emits the targeted
  diagnostic `Transaction '<tn>': <context> generated do target '<target>'
  is in a different clock domain than the calling transaction;
  cross-domain repeat-body do remains deferred` for all three
  nested-repeat sites (top-level repeat-body, when-body nested,
  switch-branch nested) when the `(domain ...)` annotation accompanies a
  cross-domain target. New helper
  `_repeat_body_do_is_cross_domain_attempt` reuses
  `_actor_has_clock_domains` and `_domain_for_entry` to compute
  cross-domain status. New regression `t/1372` covers the three
  nested-repeat sites plus the same-domain still-rejected case and the
  no-annotation falls-through case. `t/1247` expectations refreshed for
  the new targeted diagnostic. Doc surfaces synchronized in `ISF_SPEC.md`
  (focused-tests list), `ISF_DOWNSTREAM_INTEGRATION_SPEC.md` (deferred
  list), and `docs/book/src/14-feature-backlog.md` (cross-domain
  repeat-body do paragraph).
