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
| Structural | Re-derive an invariant from tracked files. | `MEMORY.md` line cap, `README.md` line/byte caps and chronology density, bootstrap pointers, relative-path docs audit. |
| Oracle | Re-run a deterministic tool. | Focused `prove` tests, `mdbook build docs/book`, `./bin/ci-regression`, HDL validation. |
| Evidence | Require a task-tree leaf to carry tool-backed diagnosis and verification evidence. | Future diagnosis-evidence checks can cite `TOOLBOX.md` commands and rerunnable gates. |

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
| `README-ENTRYPOINT` | `scripts/check_readme_entrypoint.sh` | `README.md` stays within its 300-line / 16,384-byte landing-page budget and no line enumerates two or more narrated work-unit leaves (`docs/decisions/0021` and `0024`; reusable standard: `README_POLICY.md`). |
| `PROJECT-DATA-LOCALITY` | `scripts/check_project_data_locality.sh` | Project-owned output, temporary, test, cache, log, dependency, and build paths stay repository-derived and same-volume (`docs/decisions/0022`). |

List the registry with:

```bash
scripts/check_doctrines.sh --list
```

Run the local doctrine gate with:

```bash
scripts/check_doctrines.sh
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
- Evidence checks can be faked unless they cite rerunnable oracles.
- A check proves repository state, not private intent.
- Heavy or environment-dependent checks belong in focused validation or CI, not
  in the fast pre-commit path unless their dependencies are always available.
