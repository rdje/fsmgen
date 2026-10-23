# Knowledge Map (KM) bundle

A self-contained, **project-agnostic**, git-tracked bundle provides a **question-keyed,
machine-derived index** of established repository facts for humans and AI agents,
avoiding re-derivation from code or runtime.

An **additive extension** to `MEMORY_ARCHITECTURE.md` and task-trees: **no replacement
or conversion** of existing docs. See `FAQ.md`.

## Adopt it in another project (copy the bundle)

```bash
cp -r knowledge-map /path/to/other-repo/        # copy the whole self-contained bundle
cd /path/to/other-repo
bash knowledge-map/install.sh                    # create fact dir, gen first map, print wiring
git config core.hooksPath .githooks             # if not already set
# then apply the hook + CI snippets the installer prints
```

The main per-project knobs (env, or a repo-root `.knowledge_map.conf`) are
`KM_SCAN_DIRS`, `KM_OUTPUT`, `KM_SHARD_DIR`, `KM_QUERY_CACHE_DIR`, and
`KM_TITLE`. Defaults keep canonical and generated data repository-relative;
disposable query data lives under `.artifacts/`.

## What's in the bundle

| Path | What it is |
|---|---|
| `KNOWLEDGE_MAP_ARCHITECTURE.md` | the standard: the model, the fact format, what to index / what NEVER to convert, enforcement, the read path |
| `FAQ.md` | plain-language explainer (no conversion, the ceiling, costs, sizing) |
| `scripts/gen_knowledge_map.sh` | derives the deterministic map from fact front-matter |
| `scripts/query_knowledge_map.sh` | searches unique question rows with cached/direct parity |
| `scripts/knowledge_map.pl` | shared dependency-free parser, projection, query, and bounds core |
| `scripts/check_knowledge_map.sh` | validates bounded cards/root/shards, freshness, coverage, and query parity |
| `scripts/knowledge_map.conf` | bundle-default config (`:=`, so env / repo override win) |
| `templates/FACT_TEMPLATE.md` | copy this to author a fact |
| `hooks/pre-commit.snippet` | lines to add to `.githooks/pre-commit` |
| `ci/knowledge-map-gate.yml` | the CI backstop |
| `install.sh` | idempotent adoption helper |

Fact files live in the first configured scan directory (default `docs/knowledge/`).
Copy `knowledge-map/templates/FACT_TEMPLATE.md` there and rename it `<id>.md`.

## The model in one breath

A **fact** is one `.md` with a non-empty `answers:` list in its YAML front-matter (the
questions an agent would search for) plus `id`/`title`/`date` and `evidence`/`reverify`. The
generator derives a bounded root and deterministic topic shards. The pre-commit hook
regenerates and stages the complete projection automatically; CI checks freshness.
A card is a **signpost** to the canonical home (book/code/decision record), without
copying its contents. Facts are added **lazily**, one at a time, whenever you establish a durable fact or catch
yourself re-deriving one. **No migration project.**

## How a future agent uses it

1. Run `knowledge-map/scripts/query_knowledge_map.sh 'question words'`.
2. Follow the returned card path. 3. Trust the dated fact or run its `reverify`
command. 4. Only investigate if the fact genuinely is not there — then write a
card so it never has to be investigated again.

> Read `KNOWLEDGE_MAP_ARCHITECTURE.md` and `FAQ.md` before authoring facts.
