# CLAIM-VERIFICATION-ADOPTION: Adopt Three-Leg Claim Verification

## Metadata

- Tree ID: `CLAIM-VERIFICATION-ADOPTION`
- Status: `active`
- Roadmap lane: `infra/evidence governance`
- Created: `2026-08-20`
- Last updated: `2026-08-20`
- Owner: repo-local workflow

## Goal

Adopt a project-owned claim-verification standard so every actionable
quantitative claim names dimensionally distinct re-derivation, falsification,
and durability evidence, and so missing evidence is visible instead of being
hidden behind repeated checks of the same kind.

## Non-Goals

- Do not claim that a structural tag or doctrine gate can prove human intent,
  semantic truth, or the independence of an oracle by itself.
- Do not convert dates, versions, task IDs, schema identifiers, HDL literals,
  example values, or transient command output into permanent claim records
  merely because they contain digits.
- Do not change FSMGen language, lowering, HDL, verification, or support
  behavior while adopting this evidence policy.
- Do not treat the originating PGEN copy as an automatically synchronized
  upstream after FSMGen adopts its own authoritative copy.

## Acceptance Criteria

- FSMGen owns an authoritative repository-root `CLAIM_VERIFICATION.md` with a
  fenced local adoption note and explicit discovery from the tool-neutral
  bootstrap and stable documentation routes.
- Actionable quantitative claims use a bounded record that names the claim,
  re-derivation, a separating falsification oracle or an explicit missing leg,
  and durable producer/watcher evidence or an explicit missing leg.
- A registered doctrine check validates the mechanically decidable record
  shape and its declared tracked paths, runs through the commit hook and CI
  doctrine driver, and has positive plus deliberately failing controls.
- Existing high-traffic current surfaces and repository-derived constants are
  inventoried; each actionable claim is migrated, derived/gated, or assigned a
  task-owned debt disposition without pretending the inventory proves truth.
- Focused validation and `scripts/check_doctrines.sh` pass for every slice;
  full CI remains reserved for the next push or a separately selected major
  boundary.
- The task index and bounded resume pointer remain synchronized, and each
  completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `CLAIM-VERIFICATION-ADOPTION`
  Status: `active`
  Goal: `Adopt and enforce dimensionally independent claim evidence.`
  Children: `CLAIM-VERIFICATION-ADOPTION.1, CLAIM-VERIFICATION-ADOPTION.2, CLAIM-VERIFICATION-ADOPTION.3, CLAIM-VERIFICATION-ADOPTION.4, CLAIM-VERIFICATION-ADOPTION.5, CLAIM-VERIFICATION-ADOPTION.6`

- ID: `CLAIM-VERIFICATION-ADOPTION.1`
  Status: `done`
  Goal: `Select FSMGen's local authority, scope, three-leg record, enforcement boundary, and migration sequence.`
  Acceptance: `Decision 0074 records the project-owned contract, the distinction between actionable claims and incidental numerals, the honest limit of structural enforcement, and the separately owned implementation leaves.`
  Verification: `PASS — scripts/check_task_tree_integrity.pl; scripts/check_docs_relative_paths.sh; git diff --check`
  Commit: `CLAIM-VERIFICATION-ADOPTION.1: select three-leg claim evidence`

- ID: `CLAIM-VERIFICATION-ADOPTION.2`
  Status: `pending`
  Goal: `Install the project-owned standard and wire stable discovery surfaces.`
  Acceptance: `The root standard has a fenced FSMGen adoption note; AGENTS, README, doctrine architecture, commit guidance, and the book reference map point to the canonical copy without duplicating its body; containment owns every new live path.`
  Verification: `focused link/bootstrap/containment checks plus doctrine gate`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.3`
  Status: `pending`
  Goal: `Implement the bounded claim-record checker and register it as a doctrine.`
  Acceptance: `A data-only bounded registry and deterministic checker validate claim IDs, source paths, exact record markers, all three named legs or explicit gaps, tracked producers/watchers, and path locality; positive fixtures pass and mutations that remove or alias a leg demonstrably fail RED.`
  Verification: `focused claim-verification fixtures plus doctrine gate`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.4`
  Status: `pending`
  Goal: `Inventory existing actionable quantitative claims and derived constants on mandatory/current surfaces.`
  Acceptance: `The sweep is producer-derived, partitions actionable claims from incidental numerals with reviewable reasons, identifies untracked producers and unwatched constants, and creates exact migration owners for every open leg without calling the inventory a truth proof.`
  Verification: `independent census parity, deliberate classifier RED control, tracked inventory identity, and doctrine gate`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.5`
  Status: `pending`
  Goal: `Migrate or gate the inventoried claims in bounded, surface-owned slices.`
  Acceptance: `Each claim is re-derived, falsified by a separating oracle where available, and made durable, or it names its missing leg and a task-owned repair; repository-derived constants are derived or input-identity gated rather than hand-carried.`
  Verification: `per-claim commands, observed RED controls, watcher/input mutation controls, and doctrine gate`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.6`
  Status: `pending`
  Goal: `Close adoption with a complete current-surface audit and recoverable handoff.`
  Acceptance: `The authoritative policy, discovery, registry, checker, migrated claims, explicit debt, task evidence, book, and resume pointer agree; no adoption artifact is off-volume, untracked, or reachable only from conversation.`
  Verification: `focused adoption suite, full doctrine gate, clean tracked/untracked census, and task integrity`
  Commit: `pending`

## Decisions

- `2026-08-20`: Decision `0074` selects re-derive, falsify, and durability as
  three distinct publication legs. Structural enforcement checks declared
  records and evidence plumbing; it never represents formatting as proof of a
  claim's semantic truth.
- `2026-08-20`: The external PGEN document is an adoption source, not a live
  dependency. FSMGen's repository-root copy becomes authoritative once leaf
  `.2` lands.
- `2026-08-20`: Adoption precedes the recorded HIAL backend-emission frontier
  because the director explicitly requested this missing policy and the
  repository was clean, making the pivot handoff-safe.

## Open Questions

- None blocking. The inventory leaf may split by governed surface after its
  producer-derived census establishes honest slice boundaries.

## Blockers

- None.

## Acceptance Checklist (enforced for implementation changes)

- [ ] **ROOT CAUSE (WHY + WHERE)** — `pending for the first implementation-bearing leaf .3`
- [ ] **ADDRESSED (verified)** — `pending for the first implementation-bearing leaf .3`
- [ ] **NO REGRESSION** — `pending for the first implementation-bearing leaf .3`

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-08-20` | `.1` | `scripts/check_task_tree_integrity.pl`; `scripts/check_docs_relative_paths.sh`; `git diff --check` | `PASS — 4 active trees / 954 nodes; 1 docs-relative-path file / 2 tests; clean diff whitespace` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `CLAIM-VERIFICATION-ADOPTION.1: select three-leg claim evidence` | `Decision and executable adoption sequence only; no policy or product behavior change.` |
