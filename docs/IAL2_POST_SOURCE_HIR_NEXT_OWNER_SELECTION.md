# IAL2 Post-SourceHIR Next-Owner Selection

## Selection

`IAL2-FEATURE-COMPLETENESS-FRONTIER.842` selects proposed no-product-behavior
`IAL2-FEATURE-COMPLETENESS-FRONTIER.843` as the next exact owner.

The selected leaf repairs the authoritative IAL2 task ledger and adds bounded
mechanical protection for direct-child node integrity. This selector creates
the proposed leaf but does not activate or implement it before the selector
commit is clean.

## Root Cause

The task-tree contract makes the `## Task Tree` node list authoritative. A
complete read-only census finds `842` numbered IAL2 nodes but only `840` root
child references. Exactly `.633` and `.842` are absent from the root child
enumeration; no extra child is listed.

The same census finds `.705` as the only node with live status `blocked`.
That status was correct when commit `955dc55ec` recorded the missing local AHB
reference. It is no longer true: `.706` imported the approved official source
at commit `23b2f6de5`, `.707` extracted source-backed facts, `.708` selected the
direct-seed contract, and `.709` shipped the seed. The canonical blocker and
import records already call `.705` historical and resolved.

The drift persisted because later node additions did not update the root
enumeration and no repository check compares direct-child references with
actual node IDs or flags resolved live blockers. Historical prose was updated,
but the authoritative status was not.

## Candidate Comparison

| Candidate | Selection result | Evidence |
| --- | --- | --- |
| IAL2 live task-ledger reconciliation | **selected** | It is a bounded correctness repair to the authoritative work-state ledger, has an exact `842`/`840` census and resolved-blocker history, and must precede trustworthy PNT selection. |
| HIAL/VIAL verification architecture | remains proposed; strongest later product candidate | Its director-established product requirement and documentation-only `.1` audit remain valid, but its bridge/backend/simulator/scale scope is broader than repairing the live selector substrate it depends on. |
| Public host-language builder | remains proposed | Decision `0031` says private SourceHIR evidence does not establish a supported producer or public projection; HIR completion does not activate it implicitly. |
| End-to-end large-design scalability | remains proposed | Workload definitions, correctness oracles, measurements, budgets, and graceful-failure contracts are broader and independent. |
| Beyond-read-only MCP | remains proposed | It crosses a separate trust/authorization boundary and is not a prerequisite for task-ledger correctness. |
| Protocol/backend and simulator-profile work | remains separate | No smaller active owner or newly reproduced defect outranks the exact ledger drift; simulator-profile selection is already part of the proposed HIAL/VIAL audit. |
| `.705` source-reference work | resolved, not reactivated | `.706`-`.709` satisfy and consume the missing-reference prerequisite; only its stale live status needs reconciliation. |
| Decision `0020`, t1436, AXI-book, RAM-guard, lifecycle review | ineligible | Their explicit director/policy gates remain in force, and both frozen status files stay untouched. |

## Selected Leaf Contract

After separate clean activation, `.843` must:

- preserve `.705`'s historical blocked outcome while changing its live status
  to the terminal state required by the already-completed resolution chain;
- restore complete, unique direct-child enumeration, including `.633`, `.842`,
  and `.843`;
- add the smallest repository-native integrity check for duplicate node IDs,
  missing/extra direct-child references, status vocabulary, and active-tree
  root/leaf shape, integrated with existing doctrine and focused tests;
- preserve decision `0019`: optional frontier/log/changelog views remain
  historical and are not promoted back into live state;
- change no public language, parser, generator, source, support identity,
  accounting, artifact, API, HDL/runtime, protocol/backend, or product
  behavior.

## Validation And Rollback

Validation runs an exact node/reference census, the focused new integrity
regression, all affected doctrine probes, documentation audits, all mdBook
chapters and HTML build, Knowledge Map generation/check, memory architecture,
diff hygiene, staged task acceptance where implementation paths are touched,
and the full doctrine driver from repository-derived same-volume paths.

Rollback removes `.843` and this selector record/fact, restores `.842` to
active, and removes `.842`/`.843` from the newly extended child list. No
product behavior changes in either direction.

Selector closeout passes the feature-backlog, live-book-path, and relative-path
audits at `Files=3, Tests=40`; all 36 mdBook chapters test successfully; the
HTML book builds to 72 files / 16,659,112 bytes and is removed without residue;
Knowledge Map generation writes 1,083 facts / 5,584 question keys. Memory,
diff, generated-map, staged-index, and full-doctrine results are recorded in
the owning task node and commit workflow.

Clean selector commit `bd1ef6765` activates only `.843` through a separate
continuity transition. The exact ledger repair and mechanical protection stay
unimplemented until that activation commits cleanly.

## Implementation Closeout

After clean activation commit `38e928e7b`, `.843` restores complete root
enumeration through proposed `.844`, normalizes `.73` to `done`, closes the
historical/resolved `.705` live blocker, and restores `.758`'s canonical
commit field. `TASK-TREE-INTEGRITY` is now the eighth registered doctrine; its
read-only checker and focused `t/1549` matrix mechanically enforce active-tree
root, node, ancestry, direct-child, status, container, and leaf-field shape.
See `docs/TASK_TREE_LIVE_NODE_INTEGRITY.md` for the canonical implementation
contract and rollback.

The post-repair live census is 844 numbered nodes and 844 unique root child
references; the doctrine reports one active tree and 845 total nodes including
the root. Optional historical views remain untouched under decision `0019`.
Proposed `.844` owns the next exact roadmap selector; no candidate is activated
by this infrastructure repair, and no product behavior changes.
