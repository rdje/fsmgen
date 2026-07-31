# Doctrine Enforcement Architecture

FSMGEN adopts the portable doctrine-enforcement model from the sibling PGEN
checkout as a repo-local, mechanical gate.

The rule is simple:

```text
doctrine = a written rule + a deterministic check that exits nonzero on breach
```

Written doctrine explains why the rule exists. The check decides whether the
repository currently satisfies it. A doctrine that is not checked is advisory,
not enforced.

## Relationship To The Existing Systems

Doctrine enforcement sits beside the three continuity systems already used by
FSMGEN:

| System | Owns |
| --- | --- |
| Task-trees | Per-work-unit ownership, frontier, acceptance, verification, and commit evidence. |
| Memory architecture | Durable four-layer resume and decision memory. |
| Knowledge Map | Question-to-fact retrieval over dated fact cards. |
| Doctrine enforcement | Registry-driven mechanical checks for rules that must not drift. |

The existing memory and Knowledge Map gates are now doctrine checks registered
under the general driver. This does not weaken their meaning; it gives them one
shared enforcement entrypoint.

`LIVE_DOCUMENT_SIZE_CONTAINMENT.md` is the selected project-neutral,
project-agnostic, and harness-neutral lifecycle doctrine for every live
documentation family. Decision `0041` and the local audit select bounded live
views over semantic partitions, generated projections, rolling ledgers, or
exact archive terminals according to information role. The data-only JSONL
registries under `doctrine/` hold all FSMGen paths, health targets, enforcement
ceilings, states, owners, routes, and descriptors. Every common registry
declares finite record-count, file-byte, and record-byte caps; closed scalar
domains and array cardinalities prevent the control plane from becoming the
next unbounded document.
`scripts/check_live_document_size.sh` adapts those declarations to the neutral
contract and checker package under `live-document-size/`; it inventories every
tracked Markdown path, executes all locally delegated verifiers through the
registry-driven adapter runner, and invokes the separate cross-revision
ceiling-authority guard on every doctrine run. Core verifiers execute inside
the neutral checker. External contracts are explicit fail-closed degradation,
never a green presence check.

The top-level `README.md` is both a governed bounded snapshot and the rendered
GitHub project landing page. Containment preserves its purpose, quick start,
architecture summary, and navigation in that first-class interface. It routes
only changing detail, exhaustive inventory, and chronology; it does not replace
the landing page with an empty pointer list.

## Check Contract

Each doctrine check must obey this contract:

1. Exit `0` only when the doctrine holds.
2. Exit nonzero on breach and print an actionable message to stderr.
3. Be deterministic for the same repository state.
4. Resolve paths from the repository root and use repo-relative paths in output.
5. Avoid mutation. A derived-artifact regeneration step is allowed only when it
   is explicit, idempotent, and paired with a sync check.
6. Be scope-aware when the doctrine governs only some kinds of changes.
7. Stay fast for pre-commit, or document that it belongs to CI/broader gates.

## Check Archetypes

FSMGEN uses the same three archetypes as the portable model:

| Archetype | Meaning | FSMGEN examples |
| --- | --- | --- |
| Structural | Re-derive an invariant from tracked files. | `MEMORY.md` line cap, `README.md` line/byte caps, chronology density, routed-destination budgets/frozen identities, bootstrap pointers, relative-path docs audit. |
| Oracle | Re-run a deterministic tool. | Focused `prove` tests, `mdbook build docs/book`, `./bin/ci-regression`, HDL validation. |
| Evidence | Require a task-tree leaf to carry tool-backed diagnosis and verification evidence. | `TASK-ACCEPTANCE` requires fresh box-scoped project-declared evidence for staged implementation changes. |

Prefer structural checks when they prove the rule directly. Use oracle checks
when behavior must be re-executed. Use evidence checks only for process rules
whose proof must live in a task-tree leaf.

## FSMGEN Doctrine Registry

The registry and driver live at:

```bash
scripts/check_doctrines.sh
```

Current registered checks:

| Doctrine | Check | Proves |
| --- | --- | --- |
| `DOCTRINE-BOOTSTRAP` | `scripts/check_doctrine_bootstrap.sh` | Root doctrine/toolbox docs exist, bootstrap files point to them, and local hook/hosted CI call the doctrine driver. |
| `MEMORY-ARCH` | `scripts/check_memory_architecture.sh` | `MEMORY_ARCHITECTURE.md`, bounded `MEMORY.md`, bootstrap pointers, decision store, and task-tree index are present and compliant. |
| `KNOWLEDGE-MAP` | `knowledge-map/scripts/check_knowledge_map.sh` | Fact cards are valid and `KNOWLEDGE_MAP.md` is in sync with them. |
| `DOC-PATHS` | `scripts/check_docs_relative_paths.sh` | Live docs and the Knowledge Map do not leak machine-local absolute home paths. |
| `LIVE-DOCUMENT-SIZE` | `scripts/check_live_document_size.sh` | Bounded JSONL control data, strict schema/lifecycle/locator compatibility, project-relative same-volume targets, six fixed pressure axes including maximum content-line bytes, inclusive ceilings, maintained-reference classification/bounded reads/parts/exact aggregate-change authority, 80/90 target pressure, immutable transition baselines, owned debt/ratchets, separately authorized ceiling increases, typed source-derived routes, collection-index contracts, evidence-map paths, staged/resulting-tree agreement, bounded version-retention contracts, executed core/adapter freshness, retrieval, and opt-in currency verifiers, fail-closed external degradation, frozen identities, archive descriptors, and complete tracked-Markdown coverage. |
| `README-ENTRYPOINT` | `scripts/check_readme_entrypoint.sh` | On every commit/CI tree, the rendered GitHub landing page stays within its locally derived 275-line / 12,288-byte budget, retains its first-use contract, avoids narrated work-unit chronology, and keeps every route in `doctrine/readme_entrypoint/routed_destinations.jsonl` marker-linked to the common surface graph (`docs/decisions/0021`, `0024`, `0038`, `0040`, and `0041`; reusable standard: `README_POLICY.md`). |
| `PROJECT-DATA-LOCALITY` | `scripts/check_project_data_locality.sh` | Project-owned output, temporary, test, cache, log, dependency, and build paths stay repository-derived and same-volume (`docs/decisions/0022`). |
| `TASK-TREE-INTEGRITY` | `scripts/check_task_tree_integrity.pl` | Every active indexed tree has one live active root, unique valid nodes, exact direct-child enumeration, canonical statuses, valid ancestry/container state, and complete leaf evidence across the live list plus optional bounded exact-source sealed segments; compact terminals and completed-index manifests use named retention contracts, while migration manifests independently prove complete source, semantic nodes, working-set dimensions, and loss residue. |
| `TASK-ACCEPTANCE` | `scripts/check_task_acceptance.sh` | A staged implementation change has one staged owning task file with fresh checked ROOT CAUSE, ADDRESSED, and NO REGRESSION boxes plus box-scoped declared root/no-regression evidence (`TASK_ACCEPTANCE.md`, decision `0026`). |

List the registry with:

```bash
scripts/check_doctrines.sh --list
```

Run the local doctrine gate with:

```bash
scripts/check_doctrines.sh
```

## Task-Acceptance Evidence Gate

`TASK_ACCEPTANCE.md` is the project-neutral standard. The checker embeds no
FSMGen or source-project tool vocabulary. FSMGen declares its staged
implementation-path scope in `doctrine/task_acceptance/change_paths.tsv` and
its native evidence families in
`doctrine/task_acceptance/evidence_signatures.tsv`.

For matching staged work, the checker reads task content and changed-line
freshness from the Git index. All three required box headers must be newly
added or changed in the current slice, and one task file must satisfy the
entire checklist. Root-cause and no-regression signatures must occur inside
their corresponding box bodies. This prevents stale checklists, co-staged
cross-file evidence, incidental prose, and unstaged worktree text from
satisfying the gate.

Run the focused checker after staging intended files:

```bash
scripts/check_task_acceptance.sh
```

Documentation-only commits remain exempt when no configured implementation
path is staged, but both registries are still validated. The gate checks
evidence presence, freshness, and shape; the cited focused/broader commands
remain the behavioral oracle.

## Task-Tree Integrity Gate

`scripts/check_task_tree_integrity.pl` reads active rows from
`docs/TASK_TREE.md` and checks each linked file's authoritative live
`## Task Tree` node list. Under decision `0042`, an optional finite JSONL
manifest may add content-addressed terminal subtree segments that match exact
source-revision nodes; a compact completed terminal must retrieve, digest-check,
and reconstruct its full terminal subtree from an exact version object. A
bounded completed-history JSONL manifest may similarly name an exact prior
cross-tree index: the checker verifies its digest, dimensions, unique terminal
row IDs, task-file links at that revision, and the active/proposed-only live
PNT views.
Optional historical frontier, verification, commit, and changelog views remain
outside live-state enforcement under decision `0019`.

The check fails on duplicate or malformed node IDs, unknown statuses, missing
parents, missing/extra/duplicate direct-child references across files,
non-active indexed roots, invalid container states, nonterminal children under
a done container, or leaves without required evidence. It also rejects
unbounded/malformed manifests, per-segment or aggregate node/line/byte pressure,
unsafe/symlinked/off-volume or digest-mismatched segments, overlapping/
incomplete/nonterminal sealed roots, source-revision drift, and compact-
terminal retrieval/digest/cardinality/closure/evidence failures. Completed-
index manifests also fail on malformed/unbounded data, unretrievable versions,
digest/count drift, duplicate terminal IDs, missing exact task paths, or
terminal rows retained in the live PNT tables. Its `--root
PATH` option exists for repository-local focused
fixtures; ordinary use needs no argument:

```bash
scripts/check_task_tree_integrity.pl
```

## Enforcement Layers

FSMGEN uses the same E1 to E4 layering as the portable model.

| Layer | FSMGEN artifact |
| --- | --- |
| E1 discovery | `README.md`, `AGENTS.md`, harness pointer files, this file, `TOOLBOX.md`. |
| E2 self-checks | `scripts/check_doctrines.sh` and each registered `check_*.sh`. |
| E3 local hook | `.githooks/pre-commit` regenerates the Knowledge Map, stages it, then runs the doctrine driver; `.githooks/commit-msg` enforces work-unit subjects. |
| E4 CI | `.github/workflows/regression.yml` runs the doctrine driver and commit-subject gate; `knowledge-map-gate.yml` keeps the Knowledge Map backstop; `./bin/ci-regression` runs regression plus mdBook. |

The local hook catches ordinary mistakes quickly. CI is the backstop because
`--no-verify` cannot bypass it on a branch or pull request.

## Adding A New Doctrine

1. Create a focused task-tree owner first.
2. Write a deterministic executable check under `scripts/` or the owning tool
   directory.
3. Add one row to the `DOCTRINES` registry in `scripts/check_doctrines.sh`.
4. Document the doctrine here and, when it affects users or workflow, in
   `TOOLBOX.md`, `README.md`, and the mdBook.
5. Run `scripts/check_doctrines.sh` and the relevant broader gate.
6. Commit the slice through `COMMIT.md` with the work-unit id in the subject.

Do not register a doctrine whose check is missing, nondeterministic, or merely
prose. The driver meta-check rejects missing or non-executable check scripts.

## Toolbox-First Diagnosis

FSMGEN issue work must use `TOOLBOX.md` before speculation. The toolbox lists
the exact commands for trace logs, schedule JSON, strict check JSON, semantic
JSON, support-accounting tests, HDL validation, mdBook, Knowledge Map,
doctrine gates, task-tree lookup, and git hygiene.

If the toolbox cannot expose the why and where for a recurring class of issue,
the next task-tree-owned step is to add or improve a tool, then register a
doctrine check only when a deterministic invariant is available.

## Honest Limits

- Local hooks can be bypassed; CI is the real merge backstop.
- Evidence signatures can be fabricated; focused tests and CI must re-run the
  named oracles cited in each task checklist.
- A check proves repository state, not private intent.
- Heavy or environment-dependent checks belong in focused validation or CI, not
  in the fast pre-commit path unless their dependencies are always available.
