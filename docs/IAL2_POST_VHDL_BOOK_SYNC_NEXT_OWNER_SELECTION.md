# IAL2 Post VHDL-Book-Sync Next-Owner Selection

## Selection

`IAL2-FEATURE-COMPLETENESS-FRONTIER.834` selects proposed no-behavior
`TASK-TREE-FROZEN-LEGACY-DOC-WORKFLOW-SYNC.1` as the next exact owner.

The selected leaf must remove active workflow instructions that tell future
maintainers to write the four decision-`0007`-frozen legacy blobs. It must route
live state through task trees, decision records, bounded `MEMORY.md`, the
mdBook, and git while preserving decision `0019`'s node-list/frontier rule.
This selector changes no product behavior and does not modify the selected
child before the selector commit is clean.

## Reconciled Boundary

Clean documentation commit `0c9f402ca` aligns mdBook Chapters 00/10 with
Chapter 14's bounded direct plus exact C1/C2/C3/APB-C4 VHDL truth. Full parity,
GHDL or other external compiler qualification, broad composition, aggregate/
package emission, and unsupported shapes remain deferred or fail closed.

Decision `0007` freezes `CHANGES.md`, `DEVELOPMENT_NOTES.md`,
`ROADMAP_STATUS.md`, and `LIVE_ACHIEVEMENT_STATUS.md`; `COMMIT.md`, `AGENTS.md`,
and current practice obey that rule. Decision `0019` makes the task-tree node
list, `docs/TASK_TREE.md`, and git the live frontier/history sources.

## Exact Workflow Drift At Selection Time

The maintained workflow guidance contradicted those accepted decisions when
the selector was recorded:

- `docs/TASK_TREE.md` requires all five old continuity/history files to be
  updated and calls the four frozen blobs canonical live records.
- `docs/TASK_TREE_README.md` lists the frozen blobs as setup inputs, requires
  `ROADMAP_STATUS.md` updates, requires append-style history/rationale updates,
  and checks that the frozen roadmap blob links active trees.
- `docs/tasks/TEMPLATE.md` already reflects decision `0019`; the selected leaf
  must confirm it needs no frozen-blob wording repair rather than edit it
  gratuitously.

The contradiction can cause a future session to violate the repository's
memory doctrine even though current enforcement and practice are correct.

## Candidate Comparison

| Candidate | Selection result | Evidence |
| --- | --- | --- |
| Frozen-legacy task-tree workflow sync | **selected** | Active tracked instructions contradict decisions `0007`/`0019` and `COMMIT.md`. The exact stale paragraphs are known, the correction is no-behavior, and the risk affects every future work unit. |
| `bin/fsmgen` import-tree refresh | remains proposed | Its counts are stale, but it is an architecture snapshot rather than an instruction that can cause future workflow violations. |
| HIAL/VIAL verification-fixture architecture | remains proposed | Foundational and director-endorsed, but broader than removing a current continuity-doctrine contradiction first. |
| End-to-end big/really-big scalability | remains proposed | Required product direction; workload and capacity methodology remain broader than the exact workflow repair. |
| Public-sync test drift | remains proposed | Its three known failures are separately owned and do not supersede the cross-session continuity rule. |
| Other protocol/backend and simulator work | deferred | No evidence makes it a prerequisite for the exact workflow correction. |
| RAM-guard refinement, t1436, decision `0020` | retain explicit gates | None is PNT-eligible through this selector. |

## Selected Leaf Contract

The selected leaf must:

- update `docs/TASK_TREE.md` completion/system-integration prose to the current
  layer model without editing the frozen blobs;
- update `docs/TASK_TREE_README.md` setup steps, file roles, continuity routing,
  anti-patterns, and checklist to decisions `0007`/`0019` and `COMMIT.md`;
- audit `docs/tasks/TEMPLATE.md` and change it only if stale write guidance is
  actually present;
- preserve the live node-list/frontier rule, task-tree ownership, commit-per-
  leaf discipline, mdBook synchronization, and git audit trail;
- add exact positive/negative wording verification, run documentation,
  Knowledge Map, mdBook, diff, and doctrine gates; and
- make no code, test, product, or runtime behavior change.

## Validation, Resources, And Rollback

Validation uses exact scans for frozen-blob write/canonical wording and the
replacement layer model, book/status/path audits, Knowledge Map generation/
checking, repository-local mdBook rendering, diff hygiene, and all doctrine
gates. Heavy commands use the authorized host100/process4096 profile. Capacity
truth uses the canonical Stats-compatible formula with kernel pressure
reported separately.

Rollback removes this selector record/fact and restores `.834` to active. The
stale workflow prose and all product behavior remain unchanged. A clean
selector commit may activate only the selected documentation leaf through a
separate continuity commit.

Clean selector commit `dc055558c` activates only
`TASK-TREE-FROZEN-LEGACY-DOC-WORKFLOW-SYNC.1` through continuity changes. The
stale guidance, all four frozen blobs, and every product behavior remain
unchanged during activation.

The selected child is now complete. `docs/TASK_TREE.md`,
`docs/TASK_TREE_README.md`, and the reusable template consistently route live
state through the current memory layers. The template's decision-`0019`
historical-view comments were already correct; only its stale acceptance
phrase changed. All four frozen blobs remain untouched, and no product
behavior changes.

Clean workflow completion commit `771d2918c` activates parent selector `.835`
continuity-only. No next candidate is selected or modified during activation.

## Closeout Evidence

- Book/status/path truth passes 5 files/329 tests. Knowledge Map generation and
  checking passes at 1,063 facts/5,471 question keys.
- The mdBook renders exactly 72 files/16,539,014 bytes; its exact repository-
  local output is removed, and `.artifacts/tmp/tests` is empty.
- `MEMORY.md` is 49 lines, `README.md` is 2,351 lines, diff hygiene passes, and
  all six doctrine gates pass, including project-data locality.
- Final canonical Stats-compatible capacity is
  18,918,588,416/25,769,803,776 bytes = 17.619/24.000 GiB = 73.41%, with
  separate macOS kernel pressure level 1 and `memory_pressure` 75% free. Guard
  occupancy is excluded from capacity truth. No background job remains.
