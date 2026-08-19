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
  Children: `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.1, KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.2, KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.3, KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.4`

- ID: `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.1`
  Status: `done`
  Goal: `Audit the exact binding rules, owning authority, and selectable growth routes without changing enforcement.`
  Acceptance: `Read-only. Identify which of the files/lines/bytes rules binds, who owns each, and what a legitimate growth change looks like; correct or confirm the activation premise with reproduced evidence.`
  Verification: `Read-only audit of doctrine/live_document_size/surfaces.jsonl, doctrine/live_document_size/ceiling_increase_authorities.jsonl, scripts/check_live_document_ceiling_authority.pl, LIVE_DOCUMENT_SIZE_CONTAINMENT.md, and 12 revisions of the surfaces registry. Two independent routes exist and are already exercised. Line/byte growth inside the enforcement ceiling is declared by raising transition.max_growth to the new measured actual; git shows knowledge_cards lines_total moving 358 -> 375 -> 392 -> 429 -> 425 across ordinary slices, so the value tracks measurement and is not a frozen allowance. A new card file is a genuine ceiling increase and requires exactly one new ceiling_increase_authority row whose decision names a docs/decisions Markdown path added in the same change, which the guard enforces with git --diff-filter=A; decisions 0052, 0059, 0061, and 0063 each carried one for files 1105->1109. Both routes were reproduced on the clean tree: appending two lines to a card and raising max_growth lines_total 425->428 and bytes_total 30031->30064 returns exit 0 with zero ceiling increases, and the probe was reverted exactly. The activation premise of a blocked write path and a doctrine contradiction is therefore withdrawn; the residual finding is discoverability, not enforcement. Remaining ceiling headroom is 29 lines and 65,381 bytes, with 0 files.`
  Commit: `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.1: correct the fact-card growth premise`

- ID: `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.2`
  Status: `done`
  Goal: `Make both growth routes discoverable in one step from the documents an agent reads.`
  Acceptance: `Add the two routes to TOOLBOX.md's chooser and the matching live-document section so a saturated knowledge_cards surface routes to its procedure without reading JSONL registries or git history. State the enforcement-ceiling headroom accessor rather than a copied number, per the derive-on-read contract. Change no ceiling, authority requirement, or decision pairing. Pass scripts/check_doctrines.sh.`
  Verification: `LIVE_DOCUMENT_SIZE_CONTAINMENT.md now carries an FSMGen-local Growing a surface that is at its declared allowance procedure covering the lines/bytes measurement route, the file route with its required paired decision record and ceiling_increase_authority row, and the parked-surface case. Its root_documents surface absorbs 39 lines against roughly 26,700 lines of headroom. TOOLBOX.md routes to it from both real entry points, the live-document row for a rejection and the Knowledge Map row for a card write, by rewriting existing rows in place: the file stays at exactly 319 lines because the diagnostics surface sits at 79.8% and one added line would trip its 80% warning milestone. That parked-surface hazard is now itself documented. scripts/check_live_document_size.sh and the full doctrine driver pass, with zero ceiling increases and no registry, ceiling, authority, or decision-pairing change.`
  Commit: `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.2: route the surface growth procedure`

- ID: `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.3`
  Status: `done`
  Goal: `Close the retrieval gap that produced the wrong conclusion by writing the missing fact card.`
  Acceptance: `AGENTS.md requires a fact card whenever investigation establishes a genuinely absent durable fact. Prove the absence with the Knowledge Map query and a card-corpus search, then ship the card through the exact route it documents: a newly added decision record selecting the registry and guard as authoritative for surface growth, one ceiling_increase_authority row for knowledge_cards files, and matching enforcement_ceilings/transition.max_growth updates. The card must answer the questions an agent actually asks when a live-document surface rejects a write. Pass scripts/check_doctrines.sh.`
  Verification: `Absence proved first: four Knowledge Map queries returned nothing and no card mentioned ceiling_increase_authorities or max_growth. Decision 0064 then selects the surface's own reviewed health targets as its collection ceilings, raising files 1109->1536, lines_total 42165->65536, and bytes_total 3246227->4194304 through three matching ceiling_increase_authority rows, while every per-file bound stays unchanged so cards remain small. git log -S'"files":1109' shows the pinned ceiling arrived with f206feaef and the 1536 health target with 3b71cb0b1, confirming the ceilings were an adoption-census artifact rather than a reviewed contract. Card live-document-surface-growth-procedure now answers 19 phrasings; the matcher is a case-insensitive fixed-substring search, so short high-signal phrasings and literal error strings were added and re-tested: fact card ceiling, add a knowledge map card, ceiling increase authority, max_growth, declare warning_debt, and does adding a fact card need a decision record all resolve to it. Knowledge Map reports 1,110 facts/5,789 questions/5,955 occurrences/121 shards and the full doctrine driver passes with three authorized increases. Ordinary card addition now needs no decision record.`
  Commit: `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.3: make fact cards cheap to add and retrievable`

- ID: `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.4`
  Status: `pending`
  Goal: `Split the one oversized card that pins the surface in rollover_debt.`
  Acceptance: `docs/knowledge/hial-vial-verification-fixture-architecture.md is 32,746 bytes of a 32,768-byte per-file bound and 422 of 512 lines, so it holds the surface at 99.9% target pressure and will reject its own next edit. Partition it into bounded single-topic cards without losing an answer or an exact recorded fact, prove answer-set equality before and after, and return the surface to normal so transition.max_growth stops binding. Pass the Knowledge Map gate and scripts/check_doctrines.sh.`
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

## Acceptance Checklist (enforced) — `.3` cheap-to-add retrieval surface

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'"files":1109' --oneline --
  doctrine/live_document_size/surfaces.jsonl` returns only `f206feaef`, and
  `git log -S'"files":1536'` returns `3b71cb0b1`. The `knowledge_cards`
  enforcement ceilings were pinned to the measured actual by an adoption census
  while the surface's own reviewed health targets were 28% to 38% higher, so
  every new card became a ceiling increase and the file dimension reached zero
  headroom. `scripts/check_live_document_size.sh` reproduced it: copying one
  card returned `surface knowledge_cards files is 1110 (> inclusive enforcement
  ceiling 1109)`. Four Knowledge Map queries and a card-corpus search for
  `ceiling_increase_authorit` and `max_growth` returned nothing, so the
  procedure was recoverable only from JSONL registries and revision history.
- [x] **ADDRESSED (verified)** — decision `0064` and three matching authority
  rows raise the collection ceilings to the reviewed health targets while every
  per-file bound stays unchanged. Before: adding a card failed the checker.
  After: `docs/knowledge/live-document-surface-growth-procedure.md` is committed
  as an ordinary card, `knowledge-map: OK` reports 1,110 facts/5,789
  questions/5,955 occurrences/121 shards, and the six re-tested query phrasings
  `fact card ceiling`, `add a knowledge map card`, `ceiling increase authority`,
  `max_growth`, `declare warning_debt`, and `does adding a fact card need a
  decision record` each resolve to the new card. Collection headroom is now 426
  files, 23,349 lines, and 1,010,647 bytes.
- [x] **NO REGRESSION** — `[doctrine] all doctrine checks passed` with
  `live-doc-ceiling-authority: all ceiling-change invariants hold (3
  increase(s))`, `knowledge-map: OK`, task-tree integrity, relative paths, live
  containment, bounded Memory, and diff hygiene. No per-file bound, milestone,
  ratchet, verifier, other surface, or product behavior changed.

## Changelog

- `2026-08-19`: Created after the exhaustion was reproduced during
  `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.4.2`.
- `2026-08-19`: Re-scoped from headroom restoration to procedure correctness
  and discoverability after `.1` disproved the activation premise.
- `2026-08-19`: Closed after `.2` routed both procedures into the containment
  contract and the toolbox chooser.
- `2026-08-19`: Fact cards are a retrieval surface whose value depends on being
  written often, so ceilings pinned at the measured actual are a defect, not a
  control. Decision `0064` raises the collection ceilings to the surface's own
  reviewed health targets and keeps per-file bounds and the authority rule for
  ceiling increases intact. This was the guarantor's call, not a directed one.
- `2026-08-19`: Reopened with `.3`. Closing at `.2` was premature: the mandated
  Knowledge Map card for the newly established fact was never written, so the
  same absent-fact retrieval gap that produced the wrong conclusion was left in
  place. `TOOLBOX.md` routing alone does not satisfy the `AGENTS.md` write-back
  rule.
