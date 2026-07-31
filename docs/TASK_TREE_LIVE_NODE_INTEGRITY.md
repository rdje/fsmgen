# Task-Tree Live-Node Integrity

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.843` repairs the authoritative IAL2 node
list and registers `TASK-TREE-INTEGRITY` as FSMGEN's eighth doctrine check.
The slice changes continuity/enforcement only; no public language, compiler,
generated artifact, support-accounting, API/report, HDL/runtime, protocol, or
backend behavior changes.

## Repaired Live State

The pre-repair selector census had 842 numbered nodes but only 840 root child
references: `.633` and `.842` were absent. Separate activation added `.843` to
both places, leaving 843 numbered nodes and 842 references, still missing only
`.633`. The repair restores `.633`, adds proposed next selector `.844`, and
leaves 844 numbered nodes fully and uniquely enumerated.

Three additional authoritative-node repairs follow directly from the declared
structural contract:

- `.73` changes undocumented status `completed` to canonical `done`.
- `.705` changes stale live status `blocked` to `done`. Its dated blocker
  record remains historical; `.706` imported the approved official reference,
  `.707` extracted source facts, `.708` selected the seed contract, and `.709`
  shipped the seed.
- `.758` receives its missing canonical `Commit:` field, recovered from git as
  `IAL2-FEATURE-COMPLETENESS-FRONTIER.758: ship AHB aggregate SEQ PPIF`.

Optional in-file frontier, verification, commit, and changelog sections remain
historical under decision `0019`; this repair does not sweep or promote them.

## Mechanical Contract

`scripts/check_task_tree_integrity.pl` reads rows marked `active` in
`docs/TASK_TREE.md`, follows their repository-relative `docs/tasks/*.md`
links, and validates each authoritative live `## Task Tree` section. Decision
`0042` later extends that same graph with optional bounded exact-source segment
manifests and exact version-object compact terminals. It checks:

- one indexed active root, first in the node list;
- unique IDs with valid root-descendant ancestry and present parents;
- exactly one `Goal` and one canonical status per node;
- exact, unique direct-child references for containers;
- container status `active` or `done`, with only terminal children under a
  done container;
- exactly one `Acceptance`, `Verification`, and `Commit` field per leaf.
- finite JSONL manifest schema, repository-local same-volume non-symlink paths,
  content-addressed segment identity, exact source-revision node equality,
  disjoint complete terminal subtrees, and cross-file closure;
- compact-terminal exact revision retrieval, file digest, original goal,
  subtree cardinality, terminal status/closure, and closed leaf evidence.
- bounded completed-index manifest schema, exact index retrieval/digest/
  dimensions, unique terminal rows, revision-local task-file paths, and
  active/proposed-only live PNT tables.

The checker is project-neutral and read-only. Existing one-file trees remain
valid and no tree is migrated merely by enabling the optional forms. `--root
PATH` exists only so the
focused regression can use same-volume repository-local fixtures through
`FSM::ProjectDataLocality`. `t/1549-task-tree-integrity-doctrine.t` proves the
live tree and valid fixture pass, while missing/extra/malformed child
references, duplicate IDs, unknown statuses, missing ancestry or leaf commit
fields, nonterminal children under done containers, and malformed active roots
fail with deterministic diagnostics. Its expanded fixtures also prove sealed
segments and compact terminals pass only when manifest bounds, digest,
provenance, reconstruction, terminal state, and evidence are exact.
The `.7` fixtures additionally prove completed-index schema/bounds, digest,
exact task retrieval, and live-view status failures close deterministically.

The doctrine driver and bootstrap meta-check register the executable as
`TASK-TREE-INTEGRITY`. The ordinary focused command is:

```bash
scripts/check_task_tree_integrity.pl
```

## Scope Boundary And Rollback

The check enforces structure, not semantic blocker resolution. `.705` is
closed from its explicit canonical `.706`-`.709` resolution chain; future
blocker meaning still requires task-owned evidence before its live state is
changed.

Rollback unregisters `TASK-TREE-INTEGRITY`, removes the checker/test and this
record/fact, and reverts the `.633`, `.73`, `.705`, and `.758` live-node
repairs plus proposed `.844`. That rollback would intentionally restore known
authoritative-ledger drift and is therefore not recommended. Product behavior
is unchanged in either direction.

Clean implementation commit `c21765214` activates only `.844` through a
separate continuity transition. The integrity implementation remains complete;
candidate comparison and exact-one next-owner selection remain unperformed
during activation.

Completed `.844` selects proposed no-behavior HIAL/VIAL architecture audit
`.1`; the audit remains inactive until a separate clean commit. The integrity
contract and product behavior remain unchanged.

`LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.6` subsequently refines the checker
under decision `0042` so a long-running tree can bound its live file without
weakening the original node contract. That capability slice migrates no
existing tree. `.7` then seals the exact 844 terminal IAL2 children from
revision `44b5f159789ba1c31b487c6b047097bb27a9770d` into one content-addressed
segment while retaining the live root, and moves 540 unique terminal cross-tree
rows to a bounded exact-version JSONL archive. The checker now also proves that
archive's digest/dimensions, terminal IDs/statuses, revision-local task paths,
and active/proposed-only live PNT views. The live result remains three trees and
882 reconstructed nodes, now with one segment and one index archive.
