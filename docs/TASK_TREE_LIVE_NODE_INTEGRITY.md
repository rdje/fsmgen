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
links, and validates only each authoritative `## Task Tree` section. It checks:

- one indexed active root, first in the node list;
- unique IDs with valid root-descendant ancestry and present parents;
- exactly one `Goal` and one canonical status per node;
- exact, unique direct-child references for containers;
- container status `active` or `done`, with only terminal children under a
  done container;
- exactly one `Acceptance`, `Verification`, and `Commit` field per leaf.

The checker is project-neutral and read-only. `--root PATH` exists only so the
focused regression can use same-volume repository-local fixtures through
`FSM::ProjectDataLocality`. `t/1549-task-tree-integrity-doctrine.t` proves the
live tree and valid fixture pass, while missing/extra/malformed child
references, duplicate IDs, unknown statuses, missing ancestry or leaf commit
fields, nonterminal children under done containers, and malformed active roots
fail with deterministic diagnostics.

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
