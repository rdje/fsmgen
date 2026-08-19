# KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION: Keep the fact-card growth path correct and discoverable

## Metadata

- Tree ID: `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION`
- Status: `active`
- Roadmap lane: `infra/continuity`
- Created: `2026-08-19`
- Last updated: `2026-08-19`
- Owner: repo-local workflow

## Goal

Keep the `knowledge_cards` growth path correct and discoverable from the
documents an agent actually reads, so a saturated allowance is handled by its
established governance route instead of being mistaken for a blocked write
path.

## Non-Goals

- Loosening the `knowledge_cards` enforcement ceiling, its authority
  requirement, or the decision-record pairing.
- Deleting or thinning recorded facts to fit a numeric budget.
- Changing any other surface's ceilings, ratchets, or containment state.

## Origin And Correction

`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.4.2` extended one fact card
and was rejected by `scripts/check_live_document_size.sh`. That slice fitted
its addition by compacting superseded chronology, and this tree was then
activated on the premise that the surface had become structurally unwritable
and that `AGENTS.md` and `LIVE-DOCUMENT-SIZE` therefore contradicted each other.

**That premise was wrong, and `.1` disproves it.** The measurements were
accurate; the conclusion drawn from them was not. Both growth routes exist,
are already exercised by prior slices, and were simply not found during the
first audit. The compaction was a legitimate tightening, but it was never the
only option, and no doctrine conflict exists.

## Acceptance Criteria

- The exact growth routes are established from tracked registries, the checker,
  and revision history rather than assumed.
- The routes are reachable from the documents an agent reads on resume, in one
  step, without reading JSONL registries or git history.
- No ceiling, authority requirement, or decision pairing is weakened.
- `scripts/check_doctrines.sh` passes.
- `scripts/check_task_tree_integrity.pl` passes while this tree is active.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION`
  Status: `active`
  Goal: `Keep the fact-card growth path correct and discoverable at a saturated allowance.`
  Children: `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.1, KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.2`

- ID: `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.1`
  Status: `done`
  Goal: `Audit the exact binding rules, owning authority, and selectable growth routes without changing enforcement.`
  Acceptance: `Read-only. Identify which of the files/lines/bytes rules binds, who owns each, and what a legitimate growth change looks like; correct or confirm the activation premise with reproduced evidence.`
  Verification: `Read-only audit of doctrine/live_document_size/surfaces.jsonl, doctrine/live_document_size/ceiling_increase_authorities.jsonl, scripts/check_live_document_ceiling_authority.pl, LIVE_DOCUMENT_SIZE_CONTAINMENT.md, and 12 revisions of the surfaces registry. Two independent routes exist and are already exercised. Line/byte growth inside the enforcement ceiling is declared by raising transition.max_growth to the new measured actual; git shows knowledge_cards lines_total moving 358 -> 375 -> 392 -> 429 -> 425 across ordinary slices, so the value tracks measurement and is not a frozen allowance. A new card file is a genuine ceiling increase and requires exactly one new ceiling_increase_authority row whose decision names a docs/decisions Markdown path added in the same change, which the guard enforces with git --diff-filter=A; decisions 0052, 0059, 0061, and 0063 each carried one for files 1105->1109. Both routes were reproduced on the clean tree: appending two lines to a card and raising max_growth lines_total 425->428 and bytes_total 30031->30064 returns exit 0 with zero ceiling increases, and the probe was reverted exactly. The activation premise of a blocked write path and a doctrine contradiction is therefore withdrawn; the residual finding is discoverability, not enforcement. Remaining ceiling headroom is 29 lines and 65,381 bytes, with 0 files.`
  Commit: `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.1: correct the fact-card growth premise`

- ID: `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.2`
  Status: `pending`
  Goal: `Make both growth routes discoverable in one step from the documents an agent reads.`
  Acceptance: `Add the two routes to TOOLBOX.md's chooser and the matching live-document section so a saturated knowledge_cards surface routes to its procedure without reading JSONL registries or git history. State the enforcement-ceiling headroom accessor rather than a copied number, per the derive-on-read contract. Change no ceiling, authority requirement, or decision pairing. Pass scripts/check_doctrines.sh.`
  Verification: `pending`
  Commit: `pending`

## Decisions

- `2026-08-19`: Withdraw the activation premise. The surface is saturated
  against its declared transition allowance, which is real, but saturation is
  handled by a declared measurement update, not by a blocked write path. No
  doctrine contradiction exists.
- `2026-08-19`: Keep the decision-record pairing for new card files. Admitting
  a new durable fact card only alongside a new durable decision record is a
  deliberate anti-sprawl control and is not a defect to repair.
- `2026-08-19`: Treat the residual issue as discoverability. The procedure was
  recoverable only from JSONL registries and revision history, which is what
  produced the incorrect first conclusion.

## Open Questions

- None. `.1` answered the activation question and the answer is recorded above.

## Blockers

- None.

## Changelog

- `2026-08-19`: Created after the exhaustion was reproduced during
  `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.4.2`.
- `2026-08-19`: Re-scoped from headroom restoration to procedure correctness
  and discoverability after `.1` disproved the activation premise.
