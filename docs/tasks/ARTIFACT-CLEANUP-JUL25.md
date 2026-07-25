# ARTIFACT-CLEANUP-JUL25: Scheduled Generated-Artifact Cleanup Sweep

## Metadata

- Tree ID: `ARTIFACT-CLEANUP-JUL25`
- Status: `active`
- Roadmap lane: `artifact cleanup / disk hygiene`
- Created: `2026-07-25`
- Last updated: `2026-07-25`
- Owner: repo-local workflow

## Goal

Own the periodic (roughly every 12-24 hours) generated-artifact cleanup sweep
so that regenerable and dead local artifacts are deleted only under explicit
task-tree ownership, with a recorded safety classification for every candidate.

The sweep must reclaim disk from regenerable output while proving that no
tracked source, no deliberately imported reference material, and no live
editing session is touched.

## Non-Goals

- Does not delete tracked files of any kind.
- Does not delete `.claude/`, `.github/`, `.githooks/`, or any harness/CI wiring.
- Does not delete deliberately imported local reference mirrors owned by
  another task tree (`.cache/local-references/`, owned by
  `ACCELLERA-STANDARDS-LOCAL-REFERENCE-IMPORT`).
- Does not delete legacy untracked source-like files in `perl/` whose provenance
  is hand-authored rather than generated.
- Does not change `.gitignore`, generator output placement, or the CLI artifact
  contract (that placement contract is owned by
  `GENERATED-HDL-ARTIFACT-PLACEMENT`).
- Does not touch a swap file whose recorded pid belongs to a live process.

## Acceptance Criteria

- Every deletion candidate is classified as `delete` or `keep` with a stated
  reason before any file is removed.
- Only regenerable or provably dead artifacts are deleted.
- No tracked file changes: `git status --short` shows only this task tree and
  the layer-A pointer after the sweep.
- The doctrine driver passes after the sweep.
- The slice is committed through `COMMIT.md` with the leaf id in the subject.

## Task Tree

- ID: `ARTIFACT-CLEANUP-JUL25`
  Status: `active`
  Goal: `Own the 2026-07-25 generated-artifact cleanup sweep with a recorded per-candidate safety classification.`
  Children: `ARTIFACT-CLEANUP-JUL25.1`

- ID: `ARTIFACT-CLEANUP-JUL25.1`
  Status: `done`
  Goal: `Classify every local artifact candidate, delete only the provably safe ones, and prove the tracked tree is unchanged.`
  Acceptance: `Each candidate carries a delete/keep verdict with a reason; deletions reclaim disk; git status shows no tracked-source change; scripts/check_doctrines.sh passes.`
  Verification: `Deleted 8.3 MiB .artifacts/sv (27 regenerable .sv), root .DS_Store (8196 B), 5 stale foreign-repo vim swap files, and 1 unreferenced ppif .zip stray (4.9 MiB combined with the swaps). Kept the live root .swp (pid 54331 alive), .cache/local-references/ (26 MiB, other tree's imported mirrors), and perl/*.sv legacy untracked sources. scripts/check_doctrines.sh: all PASS. git status --short shows no tracked deletion.`
  Commit: `ARTIFACT-CLEANUP-JUL25.1: sweep regenerable and dead local artifacts`

## Candidate Classification

| Candidate | Size | Verdict | Reason |
| --- | --- | --- | --- |
| `.artifacts/sv/` (27 `.sv`) | 8.3 MiB | `delete` | Implicit generated HDL output under the git-ignored placement contract (`GENERATED-HDL-ARTIFACT-PLACEMENT.1`); fully regenerable by rerunning `./bin/fsmgen` on the owning source. |
| `.DS_Store` (root) | 8196 B | `delete` | macOS Finder metadata; git-ignored; carries no project information. |
| `specs/.ebnf.spec.swp` | — | `delete` | Stale vim swap; recorded pid `44027` has no live process; its recorded target is `pgen/fx/specs/ebnf.spec` in a different repository on a different host, so it is not recovery data for anything in this tree. |
| `perl/.lte_dif_pmaster.sv.swp` | — | `delete` | Stale vim swap (pid `11749`, no live process); target is `airefactored/fx/perl/lte_dif_pmaster.sv` in a different repository/host. |
| `perl/.lte_dif_pmaster.log.swp` | — | `delete` | Stale vim swap (pid `11749`, no live process); target log file does not exist in this repo. |
| `perl/.mipicsi2_laned_clog.sv.swp` | — | `delete` | Stale vim swap (pid `2557`, no live process); target is in a different repository/host. |
| `perl/.mipicsi2_laned_clog.log.swp` | — | `delete` | Stale vim swap (pid `2557`, no live process); target log file does not exist in this repo. |
| `ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_response_demux.ppif.zip` | 1413 B | `delete` | Unreferenced stray archive; git-ignored; the tracked `.ppif` counterpart exists and is the support-accounted sample. No doc, test, or module references the `.zip`. |
| `.swp` (repo root) | 12288 B | `keep` | **Live** vim swap: recorded pid `54331` is a running MacVim process. Deleting it would break an active editing session. |
| `.cache/local-references/` | 26 MiB | `keep` | Deliberately imported UVM 1.2 and SystemVerilog LRM Markdown mirrors owned by `ACCELLERA-STANDARDS-LOCAL-REFERENCE-IMPORT.1`; git-ignored by design but not regenerable from anything in this repo. |
| `perl/lte_dif_pmaster.sv`, `perl/mipicsi2_laned_clog.sv` | — | `keep` | Legacy untracked hand-authored HDL in the legacy `perl/` tree, not FSMGen generator output; provenance is not regenerable, so deletion is not provably safe. |
| `git_message_brief.txt` | 0 B | `keep` | Ephemeral commit-message input required by `COMMIT.md`; already truncated to zero bytes. |

## Decisions

- `2026-07-25`: Scope the sweep to git-ignored files only. Any candidate whose
  provenance is hand-authored, imported, or in active use is kept, even when it
  is large. "Regenerable or provably dead" is the deletion bar, not "ignored".
- `2026-07-25`: Check the recorded pid of every vim swap file against the live
  process table before deleting it. A swap file owned by a live process is
  never a cleanup candidate.
- `2026-07-25`: Keep `.cache/local-references/` (26 MiB, the largest single
  reclaim opportunity) because it is imported reference material owned by
  another task tree, not generator output. Disk savings do not justify
  destroying material this repository cannot rebuild.

## Open Questions

- None. Future sweeps should reuse this classification table and re-verify the
  `keep` rows rather than re-deriving them.

## Blockers

- None.
