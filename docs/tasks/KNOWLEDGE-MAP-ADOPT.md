# KNOWLEDGE-MAP-ADOPT: adopt the Knowledge Map retrieval layer

## Metadata

- Tree ID: `KNOWLEDGE-MAP-ADOPT`
- Status: `done`
- Roadmap lane: `infra` (durable-memory / retrieval)
- Created: `2026-06-04`
- Last updated: `2026-06-04`
- Owner: repo-local workflow

## Goal

Adopt the **Knowledge Map (KM)** bundle — a portable, harness-agnostic retrieval
layer that sits on top of the Durable Memory Architecture (`MEMORY_ARCHITECTURE.md`)
+ task-trees — so a future session **never has to do archaeology** (re-derive a
durable fact from code or runtime) to rediscover something already logged once.

The KM is **additive**: it converts nothing, replaces nothing. Each existing layer
keeps its job (mdBook teaches, task-trees track the frontier, decision records hold
ADR facts, git remembers history); the KM adds one cross-cut **question → fact**
index, derived deterministically from small front-mattered fact cards.

## Ground truth (investigated `2026-06-04`)

- Source bundle: the sibling `pgen` repo's `knowledge-map/` bundle (10 files:
  architecture doc, FAQ, README, `install.sh`, two POSIX-sh+awk scripts, conf,
  fact template, pre-commit snippet, CI gate).
- A **fact** = one `.md` whose YAML front-matter has a non-empty `answers:` list
  (the marker). Required: `id`, `title`, `answers`, `date`, and ≥1 of
  `evidence`/`reverify`. The map is a **derived** artifact (sorted, no timestamps)
  so regenerate-and-diff is a valid sync gate.
- This repo already has the prerequisites: `MEMORY_ARCHITECTURE.md`, `docs/tasks/`
  + `docs/TASK_TREE.md`, `docs/decisions/`, `core.hooksPath=.githooks`, a
  `.githooks/pre-commit` (currently a single `exec` of
  `scripts/check_memory_architecture.sh`), and `.github/workflows/`.
- Default config: `KM_SCAN_DIRS="docs/knowledge docs/decisions"`,
  `KM_OUTPUT="KNOWLEDGE_MAP.md"`. Sensible for this repo as-is — `docs/decisions/`
  records carry no `answers:` today, so they are not (yet) false-positive facts.

## Design

- **Copy** the `knowledge-map/` bundle into the repo root (self-contained, tracked).
- **Scan dirs**: keep the default `docs/knowledge docs/decisions`. New fact cards
  live in `docs/knowledge/`; high-traffic decision records may *optionally* be
  folded in later by adding `answers:` front-matter in place (not in this tree).
- **Enforcement (mirror MEMORY_ARCHITECTURE §9):** the existing `.githooks/pre-commit`
  is a single `exec` — restructure it to run the memory-arch check **and then** the
  KM gate (regenerate the map, `git add` it, run `check_knowledge_map.sh`). Add a
  standalone `.github/workflows/knowledge-map-gate.yml` CI backstop.
- **Read path:** wire the bootstrap entrypoint (`MEMORY.md` / `AGENTS.md` /
  `MEMORY_ARCHITECTURE.md`) to point at `KNOWLEDGE_MAP.md` so a fresh session opens
  it, finds the question, follows one pointer — no excavation.
- **Seed lazily, not a sweep:** write a handful of cards for facts established or
  re-derived in recent sessions (each card permanently retires one future
  archaeology). No migration project.

## Slice plan

- `.1` select (this doc) — scope, ground truth, design, slice plan. Task tree
  committed before any code change.
- `.2` adopt — copy the bundle, create `docs/knowledge/`, wire the pre-commit gate
  + CI workflow, add the bootstrap read-path pointer, generate the first map, and
  seed the first fact cards. Gate green; commit.

## Task Tree

- ID: `KNOWLEDGE-MAP-ADOPT`
  Status: `done`
  Goal: `Adopt the Knowledge Map retrieval layer (additive to MEMORY_ARCHITECTURE + task-trees).`
  Children: `.1` (select), `.2` (adopt + wire + seed), `.3` (close optional-active residue)

- ID: `KNOWLEDGE-MAP-ADOPT.1`
  Status: `done`
  Goal: `Select; record ground truth (bundle, fact format, repo prerequisites) + design + slice plan.`
  Acceptance: `Task tree committed before any code change; TASK_TREE.md index row added.`
  Verification: `scripts/check_memory_architecture.sh; git diff --check`
  Commit: `ship commit (this slice)`

- ID: `KNOWLEDGE-MAP-ADOPT.2`
  Status: `done`
  Goal: `Copy the knowledge-map/ bundle; create docs/knowledge/; wire .githooks/pre-commit (memory-arch THEN KM gate) + .github/workflows/knowledge-map-gate.yml; add the bootstrap read-path pointer; generate KNOWLEDGE_MAP.md; seed the first fact cards.`
  Acceptance: `knowledge-map/ tracked; bash knowledge-map/scripts/check_knowledge_map.sh PASS (facts valid, ids unique, map in sync); pre-commit runs both gates; MEMORY.md/AGENTS.md point at KNOWLEDGE_MAP.md; >=3 seed cards under docs/knowledge/ with valid front-matter; full suite green.`
  Verification: `bash knowledge-map/scripts/check_knowledge_map.sh; scripts/check_memory_architecture.sh; prove -j4 -Iperl t/; git diff --check`
  Commit: `ship commit (this slice)`
  Done: `bundle copied (10 files); docs/knowledge/ + 5 seed cards (isf-schedule-report-additive-keys, isf-lowering-pipeline, loop-early-exit-target-hook, isf-fsm-verification-boundary, full-test-suite-invocation); KNOWLEDGE_MAP.md generated (5 facts, 26 question keys); .githooks/pre-commit = two gates; knowledge-map-gate CI added; read-path pointer in AGENTS.md/MEMORY.md/MEMORY_ARCHITECTURE.md. check_knowledge_map.sh PASS; check_memory_architecture.sh PASS.`

- ID: `KNOWLEDGE-MAP-ADOPT.3`
  Status: `done`
  Goal: `Close the optional-active residue after the Knowledge Map adoption is complete.`
  Acceptance: `The task tree and index no longer present Knowledge Map adoption as active work; optional future folding of high-traffic decision records is left to a new task-tree-owned leaf if it is selected later. No behavior, gate, or mdBook source change is made.`
  Verification: `passed: memory architecture, knowledge-map, mdBook build, doc path audit, and diff checks`
  Commit: `KNOWLEDGE-MAP-ADOPT.3: close adoption tree`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | Knowledge Map adoption is complete; optional future decision-record folding requires a new task-tree-owned leaf if selected. |

## Decisions

- `2026-06-04`: adopt the KM as a self-contained tracked bundle (`knowledge-map/`)
  rather than vendoring its scripts ad hoc — keeps it copyable/updatable as one unit
  and self-documenting (it ships its own architecture doc + FAQ).
- `2026-06-04`: keep the default `KM_SCAN_DIRS` (`docs/knowledge docs/decisions`) and
  `KM_OUTPUT` (`KNOWLEDGE_MAP.md`); no per-repo `.knowledge_map.conf` needed.
- `2026-06-04`: restructure the existing single-`exec` pre-commit into a two-gate
  hook (memory-arch then KM) rather than a second hook file — one local gate, in
  order.
- `2026-06-05`: close the adoption tree rather than leaving it active only for
  optional future decision-record folding. Optional future folding remains
  backlog until a new exact leaf is selected.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-04` | `.1` | `scripts/check_memory_architecture.sh`; `git diff --check` | `PASS` |
| `2026-06-04` | `.2` | `bash knowledge-map/scripts/check_knowledge_map.sh` (5 facts, ids unique, map in sync); `scripts/check_memory_architecture.sh`; two-gate pre-commit dry-run; `git diff --check` | `PASS` |
| `2026-06-05` | `.3` | `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `KNOWLEDGE-MAP-ADOPT.1: select — adopt the Knowledge Map retrieval layer (task tree)` | `5ce4725e` |
| `.2` | `KNOWLEDGE-MAP-ADOPT.2: adopt the KM bundle + wire enforcement + seed first facts` | `ship commit (this slice)` |
| `.3` | `KNOWLEDGE-MAP-ADOPT.3: close adoption tree` | `status-normalization slice` |

## Changelog

- `2026-06-04`: Created. Selected adoption of the Knowledge Map retrieval bundle
  (from `pgen/knowledge-map/`) as an additive extension to the Durable Memory
  Architecture. Recorded ground truth (bundle contents, fact format, repo
  prerequisites — hooks path, decisions/tasks dirs, single-exec pre-commit) and the
  two-slice plan (`.1` select, `.2` adopt + wire + seed).
- `2026-06-04`: `.2` shipped — Knowledge Map adopted. Copied the `knowledge-map/`
  bundle (10 files: architecture doc, FAQ, README, `install.sh`, two POSIX-sh+awk
  scripts, conf, fact template, pre-commit snippet, CI gate). Created `docs/knowledge/`
  and generated `KNOWLEDGE_MAP.md` (5 facts, 26 question keys). **Enforcement**:
  restructured the single-`exec` `.githooks/pre-commit` into two ordered gates
  (memory-arch, then KM regenerate+stage+check), and added a standalone
  `.github/workflows/knowledge-map-gate.yml` CI backstop. **Read path**: AGENTS.md
  (resume step 6), MEMORY.md (Notes), and MEMORY_ARCHITECTURE.md (§5 READ path) now
  point a fresh session at `KNOWLEDGE_MAP.md` before any re-derivation. **Seeded** 5
  cards for facts established/re-derived in recent sessions:
  `isf-schedule-report-additive-keys`, `isf-lowering-pipeline`,
  `loop-early-exit-target-hook`, `isf-fsm-verification-boundary`,
  `full-test-suite-invocation` — each a signpost (pointer + `reverify`), no narrative
  duplicated. Lazy growth from here; no migration sweep. `check_knowledge_map.sh` PASS;
  `check_memory_architecture.sh` PASS.
- `2026-06-05`: `.3` closed the task tree. The adoption work is complete and no
  pending frontier leaf remains; optional high-traffic decision-record folding
  stays available only by selecting a new exact task-tree-owned leaf later.
