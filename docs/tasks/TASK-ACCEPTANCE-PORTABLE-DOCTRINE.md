# TASK-ACCEPTANCE-PORTABLE-DOCTRINE: Portable Evidence-Backed Task Acceptance

## Metadata

- Tree ID: `TASK-ACCEPTANCE-PORTABLE-DOCTRINE`
- Status: `done`
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
  Status: `done`
  Goal: `Ship a neutral project-declared evidence gate plus an FSMGen-native TASK-ACCEPTANCE deployment.`
  Children: `TASK-ACCEPTANCE-PORTABLE-DOCTRINE.1`, `TASK-ACCEPTANCE-PORTABLE-DOCTRINE.2`, `TASK-ACCEPTANCE-PORTABLE-DOCTRINE.3`

- ID: `TASK-ACCEPTANCE-PORTABLE-DOCTRINE.1`
  Status: `done`
  Goal: `Audit the source discipline and select the neutral registry/checker contract.`
  Acceptance: `Record an evidence-backed decision for data-only project-declared signature families, staged-change and task-leaf matching, box-scoped checklist semantics, fail-closed validation, probe obligations, and honest limits without changing enforcement code.`
  Verification: `TASK_ACCEPTANCE.md and decision 0026 select two data-only TSV declarations (staged implementation-path EREs plus scoped evidence signatures), Git-index-only matching, fresh changed box headers, one-file checklist ownership, box-scoped root-cause/no-regression evidence, fail-closed validation, repository-local probes, calibration rules, adoption steps, and honest enforcement limits. Repository/all-history absence and read-only source-discipline evidence are recorded without importing external tokens. Knowledge Map generation/check, docs relative paths, memory architecture, full doctrines, mdBook, and diff hygiene pass; no enforcement or product behavior changes.`
  Commit: `TASK-ACCEPTANCE-PORTABLE-DOCTRINE.1: select declarative evidence contract`

- ID: `TASK-ACCEPTANCE-PORTABLE-DOCTRINE.2`
  Status: `done`
  Goal: `Implement the neutral checker, FSMGen registry, and focused RED/GREEN/control probes.`
  Acceptance: `The data-driven checker and registry satisfy the selected contract, probes cover the failure and success matrix, existing doctrines remain green, and no product behavior changes.`
  Verification: `Implemented executable scripts/check_task_acceptance.sh plus data-only FSMGen change-path and evidence-signature TSV registries. The checker validates staged registry snapshots, reads staged paths/task contents/fresh line positions from the Git index, requires all three fresh boxes in one task file, enforces box-scoped declared root/no-regression signatures, uses repository-local self-cleaning scratch, and reports explicit success/failure. t/1545 supplies 9 top-level isolated-Git RED/GREEN/control groups: docs-only exemption, literal/ERE positive, missing owner, unchecked box, cross-file leakage, out-of-box leakage, stale boxes, invalid/unknown/empty registry cases, and unstaged-worktree isolation. bash -n and Perl syntax pass; focused t/1545 passes Files=1 Tests=9; combined locality+checker proof passes Files=2 Tests=29; locality doctrine and existing six-doctrine driver pass. The checker run against the actual staged .2 index passes with root=git_history and no-regression=prove_summary, proving its own fresh task evidence and declarations. shellcheck is unavailable on this host, so no shellcheck claim is made. No product behavior changed.`
  Commit: `TASK-ACCEPTANCE-PORTABLE-DOCTRINE.2: implement declarative acceptance checker`

- ID: `TASK-ACCEPTANCE-PORTABLE-DOCTRINE.3`
  Status: `done`
  Goal: `Register TASK-ACCEPTANCE and synchronize the reusable/public workflow contract.`
  Acceptance: `The doctrine driver, hook/CI inheritance, TOOLBOX checklist, bootstrap/commit docs, mdBook, decision/fact/Knowledge Map surfaces, task tree, Memory, and changelog agree; focused and broader doctrine gates pass.`
  Verification: `Registered TASK-ACCEPTANCE as the seventh doctrine; the existing hook and hosted workflow inherit it through the shared driver. Bootstrap enforcement now requires TASK_ACCEPTANCE.md plus AGENTS/COMMIT/doctrine/toolbox pointers and the registry row. TOOLBOX carries the checklist and FSMGen family chooser; the task template, AGENTS, COMMIT workflow, README, mdBook reference map, decision 0026, fact/Knowledge Map, task tree, Memory, and changelog are synchronized. Bash syntax, Perl syntax, t/1527+t/1545 Files=2 Tests=29, seven-doctrine driver, README guard at 246 lines / 9952 bytes, Knowledge Map at 1067 facts / 5493 keys, docs paths, mdBook build, and diff hygiene pass. The final driver run against the actual staged .3 index passes TASK-ACCEPTANCE with root=git_history and no-regression=prove_summary. Generated book output was removed; no product behavior changed.`
  Commit: `TASK-ACCEPTANCE-PORTABLE-DOCTRINE.3: enforce portable task acceptance`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `TASK-ACCEPTANCE-PORTABLE-DOCTRINE.1` | `done` | Decision 0026 and TASK_ACCEPTANCE.md freeze the neutral contract. |
| 2 | `TASK-ACCEPTANCE-PORTABLE-DOCTRINE.2` | `done` | The checker, FSMGen registries, and 9-group isolated-Git probe suite satisfy decision 0026. |
| 3 | `TASK-ACCEPTANCE-PORTABLE-DOCTRINE.3` | `done` | The seventh doctrine, bootstrap/commit/toolbox/template contract, README/mdBook, and durable decision/fact surfaces are synchronized. |

## Decisions

- `2026-07-30`: Treat the missing neutral `TASK-ACCEPTANCE` layer as its own
  top-priority doctrine tree, not as part of the unrelated four-document
  lifecycle review.
- `2026-07-30`: Preserve the valuable checklist/evidence shape while replacing
  PGEN-named tool regexes with a project-declared, data-only registry.
- `2026-07-30`: Keep the source-project inspection read-only and same-volume;
  derive a neutral design rather than copying external project data.
- `2026-07-30`: Use two TSV registries: path EREs and scoped evidence
  signatures with literal/ERE plus explicit case modes. Never source config as
  shell.
- `2026-07-30`: Require all hard-gated box headers to be fresh in the staged
  diff and read checklist content from the index, closing stale-checklist and
  unstaged-worktree ambiguity.

## Open Questions

- Which FSMGen-native tool-output tokens are narrow enough to prove evidence
  shape without matching ordinary prose? Corpus-calibrated in `.2`.

## Blockers

- None.

## Acceptance Checklist — `TASK-ACCEPTANCE-PORTABLE-DOCTRINE.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'TASK-ACCEPTANCE' -- .` and repository-wide searches found no FSMGen gate/owner; the June adoption tree's explicit PGEN-tool non-goal explains the omission locus, while decision `0026` identifies the missing declarative layer.
- [x] **ADDRESSED (verified)** — `prove -Iperl -v t/1545-task-acceptance-doctrine.t` exercises the selected checker contract through 9 isolated-Git RED/GREEN/control groups and reports every expected verdict.
- [x] **NO REGRESSION** — `prove -Iperl t/1527-project-data-locality.t t/1545-task-acceptance-doctrine.t` reports `All tests successful` and `Files=2, Tests=29`; the project-locality doctrine and the existing six-doctrine driver also pass.

## Acceptance Checklist — `TASK-ACCEPTANCE-PORTABLE-DOCTRINE.3`

- [x] **ROOT CAUSE (WHY + WHERE)** — pre-integration `scripts/check_doctrines.sh --list` exposed only six rows; `git log -S'TASK-ACCEPTANCE' -- .` locates the contract/checker commits but no registration before this leaf, pinning the remaining gap to driver and public-workflow integration.
- [x] **ADDRESSED (verified)** — `scripts/check_doctrines.sh --list` now reports `TASK-ACCEPTANCE` as row seven, while `scripts/check_doctrine_bootstrap.sh` confirms the standard, four required pointers, registry row, hook, and hosted-workflow inheritance.
- [x] **NO REGRESSION** — `scripts/check_doctrines.sh` reports `[doctrine] all doctrine checks passed`; `prove -Iperl t/1527-project-data-locality.t t/1545-task-acceptance-doctrine.t` reports `All tests successful` and `Files=2, Tests=29`; README, Knowledge Map, docs paths, mdBook, and diff gates pass.
