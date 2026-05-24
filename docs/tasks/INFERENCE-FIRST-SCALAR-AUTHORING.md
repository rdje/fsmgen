# INFERENCE-FIRST-SCALAR-AUTHORING: Inference-First Scalar Authoring

## Metadata

- Tree ID: `INFERENCE-FIRST-SCALAR-AUTHORING`
- Status: `active`
- Roadmap lane: `language ergonomics`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Make scalar declarations optional in additional source positions where FSMGen
can recover a safe scalar type and width from already-authored usage, without
weakening existing fail-closed diagnostics for ambiguous or unsafe values.

## Non-Goals

- Do not claim a global "never declare scalar types" guarantee in one slice.
- Do not broaden aggregate inference, struct lowering, or VHDL behavior under
  this tree.
- Do not infer widths from ambiguous runtime values without a reviewable proof
  source.
- Do not change public behavior before a bounded implementation leaf records
  its syntax, acceptance criteria, documentation targets, and validation plan.

## Acceptance Criteria

- The current scalar-inference boundary is audited against the codebase,
  corpus, mdBook, and live docs.
- Each implementation leaf names one bounded source position or diagnostic
  family before code changes begin.
- Shipped behavior is documented in the mdBook and live docs in the same slice
  as the implementation.
- Focused validation covers the changed source position and any affected
  regression corpus accounting.
- Broader validation runs when a leaf touches shared scalar inference or HDL
  generation paths.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `INFERENCE-FIRST-SCALAR-AUTHORING`
  Status: `active`
  Goal: `Broaden safe scalar width/type inference one reviewable surface at a time.`
  Children: `INFERENCE-FIRST-SCALAR-AUTHORING.1`,
    `INFERENCE-FIRST-SCALAR-AUTHORING.2`

- ID: `INFERENCE-FIRST-SCALAR-AUTHORING.1`
  Status: `done`
  Goal: `Select the task tree and establish the first executable frontier.`
  Acceptance: `The active tree, roadmap status, live docs, and backlog owner stance name this tree, and the next leaf is limited to an audit/design boundary before behavior changes.`
  Verification: `passed: syntax check, live-book/spec index audits, mdBook build, and diff check`
  Commit: `INFERENCE-FIRST-SCALAR-AUTHORING.1: select scalar inference work`

- ID: `INFERENCE-FIRST-SCALAR-AUTHORING.2`
  Status: `pending`
  Goal: `Audit the shipped scalar-inference boundary and choose the smallest safe implementation surface.`
  Acceptance: `The audit identifies current inference sources, expected-failure or deferred scalar declaration positions, relevant tests/docs, and one bounded next implementation leaf with explicit non-goals.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `INFERENCE-FIRST-SCALAR-AUTHORING.2` | `pending` | The backlog item is broad; implementation needs a code-and-corpus audit before selecting one behavior-bearing scalar-inference surface. |

## Decisions

- `2026-05-24`: The first executable leaf is an audit/design slice, not an
  implementation slice. Scalar inference is shared language infrastructure, so
  the next code change must name one narrow source position and preserve
  fail-closed behavior for ambiguous cases.

## Open Questions

- Which undeclared-scalar source position is the smallest safe next shipped
  surface? This is owned by `INFERENCE-FIRST-SCALAR-AUTHORING.2` and blocks
  behavior-bearing work until answered.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `INFERENCE-FIRST-SCALAR-AUTHORING.1` | `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -Iperl t/1303-isf-public-live-book-paths-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: Files=3, Tests=351` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `INFERENCE-FIRST-SCALAR-AUTHORING.1` | `INFERENCE-FIRST-SCALAR-AUTHORING.1: select scalar inference work` | Selection leaf complete. |

## Changelog

- `2026-05-24`: Created active task tree and selected the audit/design
  frontier.
