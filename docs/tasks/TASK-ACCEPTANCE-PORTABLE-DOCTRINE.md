# TASK-ACCEPTANCE-PORTABLE-DOCTRINE: Portable Evidence-Backed Task Acceptance

## Metadata

- Tree ID: `TASK-ACCEPTANCE-PORTABLE-DOCTRINE`
- Status: `active`
- Roadmap lane: `infra/continuity / doctrine enforcement`
- Created: `2026-07-30`
- Last updated: `2026-07-30`
- Owner: repo-local workflow

## Goal

Add the high-value `TASK-ACCEPTANCE` discipline to FSMGen without copying a
PGEN-specific evidence vocabulary: define a project-neutral checker contract,
a data-only project-declared evidence-signature registry, and an FSMGen-native
deployment that mechanically requires code-changing task leaves to carry
box-scoped root-cause, addressed, and no-regression evidence.

## Origin And Evidence Boundary

The existing `DOCTRINE-ENFORCEMENT-ADOPTION.1` deliberately translated only
the portable registry/driver/hook/CI structure. Its non-goals rejected copying
PGEN-specific Rust, grammar, and certificate tools, but no later task-tree
captured the neutral task-acceptance design that boundary required.

A repository-wide and all-history search on `2026-07-30` found no FSMGen
`TASK-ACCEPTANCE`, evidence-signature, signature-family, or project-declared
token owner. A narrowly scoped read-only inspection of the same-volume sibling
PGEN doctrine confirmed the missing concept: staged code changes require a
task-leaf checklist whose root-cause and no-regression boxes carry
project-native evidence signatures. No external file was modified or copied.

## Non-Goals

- Do not copy PGEN's parser, Rust, certificate, profiler, codegen, or
  ops/build-flow token regexes into FSMGen.
- Do not make a checked box count as proof by itself; declared evidence must be
  box-scoped, and existing deterministic gates remain the executable oracle.
- Do not require code-change acceptance evidence for documentation-only slices.
- Do not infer human intent or claim that evidence-shape checking makes local
  hooks unbypassable; CI remains the backstop.
- Do not weaken any existing doctrine, task-tree, Memory, Knowledge Map,
  locality, README, mdBook, or commit-workflow gate.
- Do not change parser, lowering, scheduler, HDL, PPIF, CLI, or runtime
  behavior.

## Acceptance Criteria

- A durable contract specifies the checklist semantics, staged-change scope,
  task-leaf discovery, box boundaries, project-declared signature schema,
  validation/fail-closed behavior, and honest enforcement limits.
- The signature registry is data-only, root-relative, reviewable, and rejects
  malformed rows or regexes. It distinguishes at least root-cause and
  no-regression evidence and groups project-native tokens by named family.
- The checker requires a staged code-changing slice to stage an owning
  `docs/tasks/*.md` leaf with checked ROOT CAUSE (WHY + WHERE), ADDRESSED, and
  NO REGRESSION boxes; the root-cause and no-regression boxes must each contain
  a matching declared signature in their own body.
- The checker exits successfully without demanding the checklist when no
  configured code-change path is staged.
- Focused probes cover no-code, missing task leaf, missing/unchecked boxes,
  cross-file evidence leakage, incidental prose outside a box, malformed
  registry data, unknown/empty families, project-native positive evidence,
  and no-regression evidence.
- `TASK-ACCEPTANCE` is registered in the existing doctrine driver, therefore
  runs through the existing pre-commit hook and hosted CI path.
- `TOOLBOX.md` supplies the reusable checklist template and FSMGen evidence
  families; doctrine docs explain how another project declares its own token
  registry instead of inheriting FSMGen's vocabulary.
- Bootstrap docs, commit workflow, mdBook, task tree, bounded Memory, decision
  records, `CHANGES.md`, and Knowledge Map stay aligned.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `TASK-ACCEPTANCE-PORTABLE-DOCTRINE`
  Status: `active`
  Goal: `Ship a neutral project-declared evidence gate plus an FSMGen-native TASK-ACCEPTANCE deployment.`
  Children: `TASK-ACCEPTANCE-PORTABLE-DOCTRINE.1`, `TASK-ACCEPTANCE-PORTABLE-DOCTRINE.2`, `TASK-ACCEPTANCE-PORTABLE-DOCTRINE.3`

- ID: `TASK-ACCEPTANCE-PORTABLE-DOCTRINE.1`
  Status: `active`
  Goal: `Audit the source discipline and select the neutral registry/checker contract.`
  Acceptance: `Record an evidence-backed decision for data-only project-declared signature families, staged-change and task-leaf matching, box-scoped checklist semantics, fail-closed validation, probe obligations, and honest limits without changing enforcement code.`
  Verification: `pending`
  Commit: `pending`

- ID: `TASK-ACCEPTANCE-PORTABLE-DOCTRINE.2`
  Status: `proposed`
  Goal: `Implement the neutral checker, FSMGen registry, and focused RED/GREEN/control probes.`
  Acceptance: `The data-driven checker and registry satisfy the selected contract, probes cover the failure and success matrix, existing doctrines remain green, and no product behavior changes.`
  Verification: `pending activation`
  Commit: `pending activation`

- ID: `TASK-ACCEPTANCE-PORTABLE-DOCTRINE.3`
  Status: `proposed`
  Goal: `Register TASK-ACCEPTANCE and synchronize the reusable/public workflow contract.`
  Acceptance: `The doctrine driver, hook/CI inheritance, TOOLBOX checklist, bootstrap/commit docs, mdBook, decision/fact/Knowledge Map surfaces, task tree, Memory, and changelog agree; focused and broader doctrine gates pass.`
  Verification: `pending activation`
  Commit: `pending activation`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `TASK-ACCEPTANCE-PORTABLE-DOCTRINE.1` | `active` | The neutral data contract must be selected before any checker or FSMGen token registry is written. |
| 2 | `TASK-ACCEPTANCE-PORTABLE-DOCTRINE.2` | `proposed` | Implement only after `.1` freezes the portable contract. |
| 3 | `TASK-ACCEPTANCE-PORTABLE-DOCTRINE.3` | `proposed` | Integrate only after probes prove the checker and registry. |

## Decisions

- `2026-07-30`: Treat the missing neutral `TASK-ACCEPTANCE` layer as its own
  top-priority doctrine tree, not as part of the unrelated four-document
  lifecycle review.
- `2026-07-30`: Preserve the valuable checklist/evidence shape while replacing
  PGEN-named tool regexes with a project-declared, data-only registry.
- `2026-07-30`: Keep the source-project inspection read-only and same-volume;
  derive a neutral design rather than copying external project data.

## Open Questions

- Which data-only schema gives reviewers precise literal/regex control without
  turning the registry into executable shell configuration? Owned by `.1`.
- Which FSMGen-native tool-output tokens are narrow enough to prove evidence
  shape without matching ordinary prose? Owned by `.1` and corpus-calibrated
  in `.2`.
- Should configured change scope use path prefixes, extended regexes, or both?
  Owned by `.1`; it does not block the selector commit.

## Blockers

- None.
