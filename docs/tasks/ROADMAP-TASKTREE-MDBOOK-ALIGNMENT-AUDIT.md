# ROADMAP-TASKTREE-MDBOOK-ALIGNMENT-AUDIT: Doctrine Compliance + Roadmap ↔ Task-Tree ↔ Codebase ↔ mdBook Alignment

## Metadata

- Tree ID: `ROADMAP-TASKTREE-MDBOOK-ALIGNMENT-AUDIT`
- Status: `done`
- Roadmap lane: `R0` (live roadmap/governance infrastructure)
- Created: `2026-05-31`
- Last updated: `2026-05-31`
- Owner: repo-local workflow

## Goal

Per the task-tree doctrine (no code change without task-tree ownership; the whole
roadmap's activities/phases must be task-tree owned; past code changes must be
audited and annotated; roadmap, codebase, and mdBook must stay aligned with no
drift), perform a thorough, accurate, meticulous audit of the *current* state and
record the outcome. This audit is itself task-tree owned (the doctrine applied to
the audit).

## Audit findings (`2026-05-31`)

### 1. Mandatory task-tree gate — IMPLEMENTED + ENFORCED

- `docs/TASK_TREE.md` § "Mandatory Task-Tree Gate For Code Changes": "No code,
  test, source, generated-artifact, or config change may begin without task-tree
  ownership already in place." § "ISF Task-Tree Rule": all `R14` work is
  task-tree-managed by default.
- `COMMIT.md` § "Non-negotiable invariant": "No code, test, source,
  generated-artifact, or config change may start unless the activity already has
  task-tree ownership". The commit workflow requires the owning `docs/tasks/*.md`
  file to be updated and the leaf ID to appear in the commit subject/first line.
- Evidence the gate is honored in practice: the most recent feature
  (`ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING`, `.1`–`.7`) and its follow-up
  (`ISF-NESTED-CROSS-DOMAIN-ACTIVATION`) were each owned by a `docs/tasks/*.md`
  tree before any code change, with per-leaf commits carrying the leaf ID.

### 2. Whole-roadmap task-tree ownership — COMPLETE

- `401` task-tree files under `docs/tasks/`. Lane statuses (from
  `ROADMAP_STATUS.md`) and their ownership:
  - `R0`–`R7` `done`: foundational architecture/runtime lanes, owned by trees such
    as `EXPR-*`, `IR-*`, `GLOBAL-AST-MANAGER-BOUNDARY`, `FSMGEN-IR-AUDIT`,
    `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE`, `MODULE-INFO-PROJECTION-GUARD`.
  - `R8`–`R10` `mostly done`: owned by `R8-*` / `R9-*` / `R10-*` exit/frontier/
    provenance **audit** trees (these are the past-change audit trees).
  - `R11`: owned by six `R11-*-FRONTIER-AUDIT` trees + `R11-RTLIF-INTERFACE-SOURCE-DIRECTION`.
  - `R12` `in progress`: owned by ~50 `R12-*-CORPUS-WIDENING` trees.
  - `R13` `in progress`: shipped public-embedding surfaces owned by
    `ISF-PUBLIC-CONTRACT`, `ISF-DOWNSTREAM-INTEGRATION-SPEC`, and the public
    interface-contract trees; remaining embedding/API work gated by
    `docs/TASK_TREE.md` § "Book-Facing Feature Backlog Owner Coverage"
    (`Embedding And Public APIs` → `future task tree required`).
  - `R14` `in progress` (active): every ongoing/unresolved objective family is
    mapped to an owning tree in `docs/TASK_TREE.md` § "R14 ISF Objective
    Coverage"; the active frontier is `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.2`.
- The book-facing backlog categories all carry a tracking stance with explicit
  `future task tree required` gates for not-yet-owned future behavior, so backlog
  text is never an implementation permission slip.

### 3. Past code changes — AUDITED

- Pre/early-system lanes were retro-audited via dedicated audit trees:
  `R8-LANGUAGE-CONTRACT-EXIT-AUDIT`, `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT`,
  `R9-STRICT-MODE-FRONTIER-AUDIT`, `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT` /
  `...-FRONTIER-AUDIT`, the six `R11-*-FRONTIER-AUDIT` trees, the `R12-*-CORPUS-WIDENING`
  trees, `R14-ASPECT-COVERAGE-AUDIT`, and `FSMGEN-IR-AUDIT`.

### 4. Roadmap ↔ codebase ↔ mdBook alignment — VERIFIED, ZERO DRIFT, CONTINUOUSLY ENFORCED

- Alignment is enforced by automated *test gates* that run in the regression
  suite, so drift is caught mechanically (not just by manual review):
  - `t/1376` book-example lowering audit — every `lisp`-tagged `(actor ...)` book
    example parses + lowers (39 complete fixtures lowered cleanly).
  - `t/1305` book feature-matrix audit; `t/1304` repeat-body, `t/1306` rule-guard,
    `t/1307` loop-body, `t/1332` ATL doc-status doc-truth audits.
  - `t/1256` feature-backlog status audit; `t/1303` public live-book paths;
    `t/371` documentation-path-existence; `t/1112` public-interface contract.
  - `t/1250` ISF spec focused-test index; `t/1116`/`t/1255` schedule-report
    key-family + golden matrix.
- All of the above pass on the current tree (13 files, `919` tests PASS,
  `2026-05-31`), and the full `./bin/ci-regression isf --no-book` passed at `292`
  files / `2084` tests on the current codebase (only doc-only commits since).

## Outcome

The doctrine is fully implemented and currently satisfied: the whole roadmap is
task-tree owned, the no-code-without-ownership gate is in force and honored, past
changes are audited, and roadmap/codebase/mdBook alignment is verified with zero
drift and continuously enforced by test gates. No code or doc-content repair was
required by this audit beyond recording the outcome.

## Acceptance Criteria

- The doctrine's four pillars (ownership gate, whole-roadmap coverage, past-change
  audit, tri-surface alignment) are each verified with concrete evidence and
  recorded; the audit is itself task-tree owned; the alignment gates pass.

## Task Tree

- ID: `ROADMAP-TASKTREE-MDBOOK-ALIGNMENT-AUDIT`
  Status: `done`
  Goal: `Audit + record doctrine compliance and tri-surface alignment.`
  Children: `.1` (audit + record outcome)

- ID: `ROADMAP-TASKTREE-MDBOOK-ALIGNMENT-AUDIT.1`
  Status: `done`
  Goal: `Verify the task-tree gate, whole-roadmap ownership, past-change audit, and roadmap/codebase/mdBook alignment; record findings.`
  Acceptance: `Findings recorded with evidence; alignment gates pass; no drift.`
  Verification: `prove -Iperl t/1256 t/1303 t/1304 t/1305 t/1306 t/1307 t/1332 t/1376 t/1112 t/371 t/1250 t/1116 t/1255 (13 files, 919) PASS; git diff --check`
  Commit: `ship commit (this slice)`

## Current Frontier

The audit is complete (`.1` done). This tree records a point-in-time compliance
verification; future drift is caught by the standing alignment test gates above.

## Decisions

- `2026-05-31`: recorded the audit as a `done` governance tree rather than
  proposing remediation work, because the audit found the doctrine fully
  implemented and the tri-surface alignment at zero drift; no code/content repair
  was warranted.

## Open Questions

- None. Future behavior-bearing work continues to pass the mandatory task-tree
  gate per existing policy.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-31` | `.1` | `prove -Iperl t/1256 t/1303 t/1304 t/1305 t/1306 t/1307 t/1332 t/1376 t/1112 t/371 t/1250 t/1116 t/1255` (13 files, 919 tests) PASS; coverage cross-check of `ROADMAP_STATUS.md` lanes R0–R14 vs `docs/TASK_TREE.md` ownership; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ROADMAP-TASKTREE-MDBOOK-ALIGNMENT-AUDIT.1: audit doctrine compliance + tri-surface alignment (zero drift)` | `ship commit (this slice)` |

## Changelog

- `2026-05-31`: Created and closed in one slice. Audited the task-tree doctrine's
  four pillars (ownership gate, whole-roadmap coverage, past-change audit,
  roadmap/codebase/mdBook alignment) and found full compliance with zero current
  drift, continuously enforced by the standing alignment test gates. Recorded the
  outcome; no code/content repair required.
