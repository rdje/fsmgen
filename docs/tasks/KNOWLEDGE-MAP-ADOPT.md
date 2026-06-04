# KNOWLEDGE-MAP-ADOPT: adopt the Knowledge Map retrieval layer

## Metadata

- Tree ID: `KNOWLEDGE-MAP-ADOPT`
- Status: `active`
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

- Source bundle: `/Users/richarddje/Documents/github/pgen/knowledge-map/` (10 files:
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
  Status: `active`
  Goal: `Adopt the Knowledge Map retrieval layer (additive to MEMORY_ARCHITECTURE + task-trees).`
  Children: `.1` (select), `.2` (adopt + wire + seed)

- ID: `KNOWLEDGE-MAP-ADOPT.1`
  Status: `done`
  Goal: `Select; record ground truth (bundle, fact format, repo prerequisites) + design + slice plan.`
  Acceptance: `Task tree committed before any code change; TASK_TREE.md index row added.`
  Verification: `scripts/check_memory_architecture.sh; git diff --check`
  Commit: `ship commit (this slice)`

- ID: `KNOWLEDGE-MAP-ADOPT.2`
  Status: `pending`
  Goal: `Copy the knowledge-map/ bundle; create docs/knowledge/; wire .githooks/pre-commit (memory-arch THEN KM gate) + .github/workflows/knowledge-map-gate.yml; add the bootstrap read-path pointer; generate KNOWLEDGE_MAP.md; seed the first fact cards.`
  Acceptance: `knowledge-map/ tracked; bash knowledge-map/scripts/check_knowledge_map.sh PASS (facts valid, ids unique, map in sync); pre-commit runs both gates; MEMORY.md/AGENTS.md point at KNOWLEDGE_MAP.md; >=3 seed cards under docs/knowledge/ with valid front-matter; full suite green.`
  Verification: `bash knowledge-map/scripts/check_knowledge_map.sh; scripts/check_memory_architecture.sh; prove -j4 -Iperl t/; git diff --check`
  Commit: `ship commit (this slice)`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Selection/design (this doc); task tree committed before code. |
| 2 | `.2` | `pending` | Copy bundle + wire enforcement (hook/CI) + bootstrap pointer + generate map + seed cards. |

## Decisions

- `2026-06-04`: adopt the KM as a self-contained tracked bundle (`knowledge-map/`)
  rather than vendoring its scripts ad hoc — keeps it copyable/updatable as one unit
  and self-documenting (it ships its own architecture doc + FAQ).
- `2026-06-04`: keep the default `KM_SCAN_DIRS` (`docs/knowledge docs/decisions`) and
  `KM_OUTPUT` (`KNOWLEDGE_MAP.md`); no per-repo `.knowledge_map.conf` needed.
- `2026-06-04`: restructure the existing single-`exec` pre-commit into a two-gate
  hook (memory-arch then KM) rather than a second hook file — one local gate, in
  order.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-04` | `.1` | `scripts/check_memory_architecture.sh`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `KNOWLEDGE-MAP-ADOPT.1: select — adopt the Knowledge Map retrieval layer (task tree)` | `ship commit (this slice)` |

## Changelog

- `2026-06-04`: Created. Selected adoption of the Knowledge Map retrieval bundle
  (from `pgen/knowledge-map/`) as an additive extension to the Durable Memory
  Architecture. Recorded ground truth (bundle contents, fact format, repo
  prerequisites — hooks path, decisions/tasks dirs, single-exec pre-commit) and the
  two-slice plan (`.1` select, `.2` adopt + wire + seed).
