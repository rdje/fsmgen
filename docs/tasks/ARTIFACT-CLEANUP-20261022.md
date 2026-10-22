# ARTIFACT-CLEANUP-20261022: Due Safe Artifact Census

## Metadata

- Tree ID: `ARTIFACT-CLEANUP-20261022`
- Status: `active`
- Roadmap lane: `infra/continuity / same-volume artifact maintenance`
- Created: `2026-10-22`
- Last updated: `2026-10-22`
- Owner: repo-local workflow

## Goal

Qualify elapsed-time admission from clean `e16cd0d0b`, then perform the safe
artifact sweep when due, preserving original native/compiler evidence.

## Non-Goals

- No foreign repository, submodule, shared cache or unqualified evidence deletion.
- No language/API behavior change, HDL execution or publication qualification.

## Acceptance Criteria

- Reuse the authenticated published collector/reviewer and genuine controls.
- Keep all project-owned outputs and persisted paths repository-relative.
- Census regular log/bin paths and root/Rust locations, excluding Git metadata,
  foreign repositories, symlinks and other volumes.
- Retain candidates without exact disposal authority; suffix/age is insufficient.
- Preserve complete dated membership, metadata, independent enumeration and controls.
- Overwrite only the latest cleanup date/summary; synchronize the saved-reader
  book route, task state and resume pointer, pass gates and commit before resuming.

## Task Tree

- ID: `ARTIFACT-CLEANUP-20261022`
  Status: `active`
  Goal: `Qualify actual due status, perform the safe census when due and preserve reduction continuity.`
  Children: `ARTIFACT-CLEANUP-20261022.1, ARTIFACT-CLEANUP-20261022.2`

- ID: `ARTIFACT-CLEANUP-20261022.1`
  Status: `done`
  Goal: `Correct calendar-date due classification and qualify actual elapsed-time admission.`
  Acceptance: `Authenticate the unchanged published collector against native source and compare actual UTC with the complete prior cleanup record. Preserve any first refusal and exact attempted source, distinguish original streams from a controlled replay and verify no sweep/output/deletion or cleanup record update occurs before 24 elapsed hours. Record the actual scheduled sweep under .2, synchronize book/pointer and pass focused/required gates before returning to the reduction frontier.`
  Verification: `The original overdue classification was wrong: published collect() refuses its elapsed-time prerequisite before any walk/output creation. Independent actual UTC 2026-10-22T06:19:52Z is before prior2026-10-21T06:50:19.603025Z plus24h. The installed source matches native e16cd0d0b and the exact attempted wrapper/source hash is retained in docs/audits/artifact-census-20261022/admission.json.gz. Controlled same-source native replay independently exits1 at the same prerequisite and emits no census output; the prior cleanup record stays byte-identical. Git history identifies the canonical record. The receipt explicitly does not reconstruct uncaptured original first raw streams. The unpublished failed wrapper is retained completely inside the receipt, then removed from the live executable surface; no successful saved-reader command is advertised. .2 owns the actual due sweep, with no candidate deletion authorized by age/suffix. Re-derivation uses actual UTC/prior source/native collector; falsification is genuine native refusal and complete prior-record/output preservation; durability is exact source/controlled streams/audit/task/book/Git. Focused admission replay, task/source/claim checks and staged/normal doctrine gates qualify this scheduling correction. No sweep, physical reclamation, source behavior or publication claim.`
  Commit: `ARTIFACT-CLEANUP-20261022.1: qualify elapsed-time census admission`

- ID: `ARTIFACT-CLEANUP-20261022.2`
  Status: `blocked`
  Goal: `Capture and qualify the same-volume artifact census after its elapsed-time prerequisite.`
  Acceptance: `After actual UTC exceeds 2026-10-22T06:50:19.603025Z, authenticate the unchanged published collector against the then-current committed native revision and create an exclusive current-source wrapper/output. Retain complete regular log/bin metadata, root/Rust locations, exclusions and independent rg membership; keep all candidates without exact disposal authority. Qualify saved replay and genuine missing-member/path/Boolean/removal controls, update latest-only record and book reader route, run gates and commit from a clean boundary before returning to reduction work. Recheck the canonical prior record before capture in case another sweep supersedes this schedule.`
  Verification: `No capture yet; .1 qualifies that the initial attempt occurred before the prior sweep plus24h.`
  Commit: `pending`
  Blocked by: `Actual UTC must exceed the canonical prior cleanup timestamp plus24h. Continue ISF-REDUCTION-DELIVERY.1.2.3.1.2.2.2.3.2.2 meanwhile; recheck due status at its next clean commit boundary.`

## Acceptance Checklist (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — git log -S "Latest artifact cleanup" locates the canonical prior record. Actual UTC and complete record show that the earlier overdue statement confused calendar date with elapsed time. Published collect() refuses at total_seconds() > 86400 before filesystem enumeration or output creation; exact source and a separately captured native refusal retain.
- [x] **ADDRESSED (verified)** — Corrected admission preserves the complete prior record and absent census output, retains the failed wrapper as immutable evidence, advertises no nonexistent successful reader and schedules actual collection under .2 after the canonical elapsed-time boundary. The original first raw-stream retention gap is explicit. Book guidance now states the elapsed-time rule.
- [x] **NO REGRESSION** — Controlled native refusal, independent UTC/prior-record/output checks and the tracked verify_admission.py reader with genuine due/status-kind/prior/source/diagnostic controls pass. knowledge-map: OK; task integrity and source/index checks pass. The book cadence numeral is a policy_input, not a measured result. First staged scripts/check_doctrines.sh rejects only that disposition's owner metadata: the registry requires its canonical general_book review owner. Complete failed log and before/after row retain in gate-refusal.json.gz; the correction preserves the actual cleanup task's ownership of this slice. Corrected claim/acceptance checks and normal full doctrine hooks gate the final staged state. No product source changes or HDL execution occur.

## Blockers

- `.2` waits for the elapsed-time boundary; reduction work continues meanwhile.
