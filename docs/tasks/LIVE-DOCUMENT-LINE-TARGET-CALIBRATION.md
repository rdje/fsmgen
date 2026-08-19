# LIVE-DOCUMENT-LINE-TARGET-CALIBRATION: Re-derive line health targets that fail edits under trivial byte pressure

## Metadata

- Tree ID: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION`
- Status: `active`
- Roadmap lane: `infra/continuity`
- Created: `2026-08-19`
- Last updated: `2026-08-19`
- Owner: repo-local workflow

## Goal

Decide whether several live surfaces' `lines_each` health targets are
calibrated to their real information role, given that four of them now fail an
ordinary editorial write at the 80% warning milestone while their `bytes_each`
pressure is trivial. Either re-derive the affected targets from the retained
surface, or record that the tight line budget is the intended discipline.

## Non-Goals

- Weakening the warning/rollover milestone mechanism, the ratchet, the ceiling
  authority requirement, or any decision pairing.
- Raising an enforcement ceiling to avoid an honest containment signal.
- Touching surfaces whose line and byte pressure genuinely agree.

## Origin

Two ordinary writes in `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION` tripped
this. `.4` added two lines to the `MEMORY.md` resume pointer and failed the
doctrine driver with `surface active_resume is at 81.7% and must declare
warning_debt`, at 41.4% byte pressure. `.2` and `.5` both had to rewrite a
`TOOLBOX.md` row in place rather than add a line, because `diagnostics` sits at
79.8% with one line of headroom and 41.7% byte pressure.

Measured on the tree at commit `fddf36d9f`, comparing each measured surface's
largest member against its own health targets:

| Surface | Binding document | Lines | Line % | Byte % | Lines to 80% |
| --- | --- | --- | --- | --- | --- |
| `diagnostics` | `TOOLBOX.md` | 319/400 | 79.8% | 41.7% | 1 |
| `active_resume` | `MEMORY.md` | 46/60 | 76.7% | 41.4% | 2 |
| `rationale` | `docs/decisions/0055-*.md` | 404/512 | 78.9% | 7.9% | 5 |
| `live_document_review` | review doc | 76/100 | 76.0% | 78.1% | 4 |

`live_document_review` is excluded from the concern: its line and byte pressure
agree, so its signal is honest. The other three are the finding.

`rationale` is the clearest case. Its binding member,
`docs/decisions/0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md`,
is at 78.9% of the per-file line target while using 7.9% of the per-file byte
budget, because a `lines_each` of 512 paired with a `bytes_each` of 262,144
implies ~512-byte lines against decision records that average 51. Decision
records are the layer-C store the write path is required to use, so the next
long decision fails the gate for a reason unrelated to its size.

Note that `diagnostics` and `active_resume` are single-file surfaces, so their
two percentages describe the same document. `rationale` is a collection, where
each dimension is the maximum across members and two dimensions may come from
different files; the row above therefore reports the single worst-off member,
which is the file that actually cannot be extended.

## Risk If Unowned

The documented workaround is to rewrite a line in place instead of adding one.
Applied repeatedly under a hard gate, that pressures every edit toward denser,
longer, less readable prose in exactly the documents an agent must read on
resume — a containment rule degrading the surface it protects. That is a
quality risk, not merely an inconvenience.

## Acceptance Criteria

- Each affected `lines_each` target is either re-derived from the retained
  surface with its rationale recorded, or explicitly retained as intended
  discipline with the reason stated.
- Any target change is a health-target change, not a ceiling increase, or it
  carries the full authority record if a ceiling genuinely moves.
- No milestone, ratchet, verifier, authority requirement, or decision pairing
  is weakened.
- `scripts/check_doctrines.sh` passes.
- `scripts/check_task_tree_integrity.pl` passes while this tree is active.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION`
  Status: `active`
  Goal: `Decide and record whether the affected line health targets are calibrated to their surfaces' information role.`
  Children: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.1, LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.2, LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.3, LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.4, LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.5, LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.6`

- ID: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.1`
  Status: `done`
  Goal: `Measure the line/byte target pairs and identify which surfaces are genuinely miscalibrated.`
  Acceptance: `Read-only. For each candidate surface, compare the declared lines_each and bytes_each against the retained surface's actual bytes per line, and identify the exact binding member. Correct any misattributed measurement before proposing a change.`
  Verification: `Read-only measurement of six surfaces. Three are genuinely miscalibrated, each declaring an implied bytes-per-line far above what the retained surface uses: diagnostics implies 81 against TOOLBOX.md's actual 42, active_resume implies 136 against MEMORY.md's 73, and rationale implies 512 against decision records' 51. live_document_review implies 51 against an actual 52 and is correctly calibrated, which is why its line and byte pressure agree; it is excluded. engineering_rationale implies 131 against DEVELOPMENT_NOTES.md's 61 but sits at 13.4%, so it has no live pressure and needs no change now. This leaf also corrected the activation finding: the rationale surface is docs/decisions/*.md, not DEVELOPMENT_NOTES.md, and on a collection surface each dimension is the maximum across members, so the reported line and byte peaks may come from different files. The binding member is docs/decisions/0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md at 404/512 lines and 20,775/262,144 bytes.`
  Commit: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.1: measure the miscalibrated line targets`

- ID: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.2`
  Status: `done`
  Goal: `Re-derive the three miscalibrated lines_each values from the retained surface's measured bytes per line.`
  Acceptance: `Apply the doctrine's own Derive pressure limits from the retained surface method: a surface's lines_each and bytes_each must imply a bytes-per-line consistent with what that surface actually writes. Re-derive lines_each for diagnostics, active_resume, and rationale so the two dimensions reach their milestones together instead of the line dimension failing first at trivial byte pressure. active_resume must stay consistent with MEMORY_ARCHITECTURE.md and MEMORY_POINTER_LINE_CAP, so prefer widening its bytes_each or its milestone over breaking the documented one-screen cap. Where health_targets equals enforcement_ceilings, a raise is a reviewed ceiling increase and needs its paired decision record and ceiling_increase_authority row. Change no milestone mechanism, ratchet, verifier, or authority requirement. Pass scripts/check_doctrines.sh.`
  Verification: `Each pair is now one derivation. diagnostics keeps its reviewed 32,768-byte reading budget and takes lines_each 400 -> 768, the line count 32 KiB of 43-byte lines actually is; it moves from 79.8% to 46.5%. active_resume takes lines_each 60 -> 75 so the 80% warning lands exactly on the 60-line MEMORY_POINTER_LINE_CAP that scripts/check_memory_architecture.sh still enforces unconditionally, ending an undeclared 48-line cap; it moves from 78.3% to 62.7%. Its bytes_each stays 8,192 as a stated non-binding safety net. rationale takes lines_each 512 -> 640 so the 404-line retained record keeps room for the superseded-by edit the memory architecture requires, and bytes_each 262,144 -> 65,536 derived from its two member classes; it moves from 78.9% to 63.1%. Five enforcement-ceiling increases carry appended authority rows paired to new decision 0065; the single decrease needed none. scripts/check_live_document_ceiling_authority.pl reports 5 increases and all invariants holding, and scripts/check_doctrines.sh passes.`
  Commit: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.2: re-derive three miscalibrated target pairs`

- ID: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.3`
  Status: `pending`
  Goal: `Sweep every remaining governed surface for the same target-pair defect and re-derive or explicitly retain each one.`
  Acceptance: `.2 fixed only the three surfaces under live pressure. Apply decision 0065's rule to every other surface in doctrine/live_document_size/surfaces.jsonl: divide bytes_each by lines_each, compare the implied bytes-per-line against the retained surface's measured value, and either re-derive the pair or record why the divergence is intended. enforced_rules (implies 109 against a measured 56, at 74.7%) and engineering_rationale (implies 131 against 61, at 13.4%) are the known instances; the sweep must be complete rather than limited to those two. Any increase needs its own paired decision record and authority row; lowering stays free. Change no milestone mechanism, ratchet, verifier, or authority requirement. Pass scripts/check_doctrines.sh. The same sweep must also report each surface's remaining headroom against its owned transition allowance, because that is the other way containment obstructs an ordinary write: focused_documents currently has 1 line and 287 bytes left against an allowance owned by GITHUB-PUSH-OUTCOME-ASSURANCE.6.1, and knowledge_cards sits at 79.98% of line_bytes_each, so one long line in a new card trips warning debt. Decision 0064 makes raising transition.max_growth a declared measurement rather than a ceiling increase, so the remediation is documented; the finding is that the audit is not. If the sweep ratchets active_resume down after decisions 0067 and 0068 shrank MEMORY.md to 14 lines, do it as a routine measurement: MEMORY.md sizing is closed and must not be resurfaced to the director as a question.`
  Verification: `pending`
  Commit: `pending`

- ID: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.4`
  Status: `done`
  Goal: `Separate MEMORY.md's two size criteria and set each from its own authority, on director direction.`
  Acceptance: `The director set 32,768 bytes as the maximum size allowed for MEMORY.md, with single-call readability as the criterion. Establish that byte maximum, and resolve the interaction it exposes: at ~75 bytes per line a 60-line file is ~4,500 bytes, so the byte ceiling was unreachable and raising it alone changes nothing. Do not derive the line cap from the byte maximum; ~440 lines is the blob MEMORY_ARCHITECTURE.md exists to prevent. Raise the line cap only as far as the layer-routing control justifies, keep the containment warning aligned to it, record the split in a paired decision record with authority rows, and restate both bounds where an author meets them. Pass scripts/check_doctrines.sh.`
  Verification: `MEMORY.md's dimensions now answer different questions and neither is derived from the other. bytes_each/bytes_total 8,192 -> 32,768 is the director's single-call ingestion maximum and is deliberately non-binding: 120 lines of this file is about 9,000 bytes. MEMORY_POINTER_LINE_CAP 60 -> 120 in scripts/check_memory_architecture.sh is the real cap and remains the layer-routing control; lines_each/lines_total 75 -> 150 keeps the 80% containment warning exactly on it, preserving the alignment .2 established. MEMORY.md moves to 33.3% lines and 11.6% bytes, a 37.9% surface peak now carried by line_bytes_each, from 62.7% after .2 and 78.3% before it. Four enforcement-ceiling increases carry appended authority rows paired to new decision 0066, which supersedes point 5 of 0065 only. The neutral MEMORY_ARCHITECTURE.md keeps its ~50-line default and its MEMORY_POINTER_LINE_CAP knob, now with an explicit warning against deriving that knob from a reader-capability bound.`
  Commit: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.4: separate the resume pointer's two size criteria`

- ID: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.6`
  Status: `done`
  Goal: `Remove the COMMIT.md instruction that grew MEMORY.md, and reduce the file to a frontier pointer and nothing else.`
  Acceptance: `Director direction: MEMORY.md shall JUST be a pointer to the frontier and nothing else, and the part of COMMIT.md that causes it to grow for no objective reason must change. .5 removed the content and added a per-field control but left the instruction intact. Identify the exact workflow phrases that ask a slice to write non-pointer content, remove them, and reduce MEMORY.md to the active work unit, the single next action, and the in-flight/blocker flags. Preserve the active_resume_repository_head derive-on-read contract, which requires the HEAD derivation string to remain present and the commit itself to remain unstored. Change no limit. Pass scripts/check_doctrines.sh.`
  Verification: `Three COMMIT.md phrases were the driver, each executed by every slice: OVERWRITE its Current state block when recording completed work, which literally asks for completed work in layer A; current state + the single next action only, broad enough to admit the nine-line narration .5 found; and point at the new latest commit, which also contradicts the derive-on-read contract in doctrine/live_document_size/derived_state_contracts.jsonl. All three are replaced with the direct prohibition. MEMORY.md drops the current_state, push_state, and Durable context blocks, each verified duplicate of the owning task tree, COMMIT.md's own Push cadence section with decision 0062, and docs/decisions/INDEX.md respectively. The file is now 14 lines / 654 bytes, from 50 / 3,800 at session start and 30 / 1,690 after .5 - 12% of its line cap. The derive-on-read contract still passes: the git log -1 derivation string remains and no commit is stored. Decision 0068 records the rule and the lesson that a workflow step running every slice outweighs a written rule about restraint. No limit changed.`
  Commit: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.6: make MEMORY.md a frontier pointer only`

- ID: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.5`
  Status: `done`
  Goal: `Find and remove the reason MEMORY.md keeps filling, instead of moving its limits again.`
  Acceptance: `.2 and .4 both treated recurring MEMORY.md pressure as a limit problem. Measure the file's actual composition instead. For any content that belongs to another layer, verify it against its authority per the containment duplicate rule, inspect that authority for divergence the copy concealed, repair the authority first if wrong, then remove the copy and leave the reader's question answerable. Install a mechanical control that fails on the offending write rather than many slices later, and prove it fails closed. Change no limit in this slice. Pass scripts/check_doctrines.sh.`
  Verification: `The file was 46% misplaced content. A 23-line Durable context block summarised 14 cross-cutting decisions and 10 task leaves, and the current_state field spent 9 more lines restating decisions 0065 and 0066. All 14 decisions were verified present on disk with exactly one docs/decisions/INDEX.md row each, and all 10 leaves verified as real nodes in docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md, so nothing unique was lost. The audit also found one concealed drift: the copy attributed PNT autonomy to decision 0062 (push cadence) when the authority is 0003, which the removal restores. MEMORY.md is now 30 lines / 1,690 bytes, from 50 / 3,800, and 25% of its line cap. Decision 0067 records the incentive that produced the drift and adds MEMORY_POINTER_FIELD_LINE_CAP, capping each resume field at 5 lines in scripts/check_memory_architecture.sh. No limit changed in this slice.`
  Commit: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.5: remove the layer-A bloat vector`

## Acceptance Checklist (enforced) — `.5`

- [x] **ROOT CAUSE (WHY + WHERE)** — measuring `MEMORY.md` rather than its limits found 23 of 50 lines in a `## Durable context` block plus a 9-line `current_state` field, both holding layer-B and layer-C content. `git log -S'## Durable context' --oneline -- MEMORY.md` traces the block's introduction, and the duplicate check is exact: all 14 cited decisions resolve to a file on disk with exactly one `docs/decisions/INDEX.md` row, and all 10 cited leaves resolve to real `- ID:` nodes in `docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md`. The mechanism is an incentive plus a missing control: `COMMIT.md` step 3.3 makes every slice overwrite this file, one summary line is cheaper than opening the right store, and the only guard was a whole-file count that fired at 60 — many slices after the drift began, which is why `.2` and `.4` both answered it by moving limits.
- [x] **ADDRESSED (verified)** — `scripts/check_memory_architecture.sh` reports `MEMORY.md is 30 lines (<= cap 120)` and `MEMORY.md resume fields are each <= 5 lines`, against 50 lines and no field control before. The new `MEMORY_POINTER_FIELD_LINE_CAP` control is proved fail-closed, not merely present: running it at `MEMORY_POINTER_FIELD_LINE_CAP=2` emits `FAIL: MEMORY.md resume field(s) exceed 2 lines: next_action(3)` and exits `1`, while the shipped cap of 5 exits `0`. The concealed drift is repaired by removal — `0003` regains sole ownership of autonomous PNT from a copy that credited `0062`.
- [x] **NO REGRESSION** — staged `scripts/check_doctrines.sh` ends with `[doctrine] all doctrine checks passed`, and `prove -Iperl t/1553-readme-routed-destination-pressure.t t/1554-live-document-size-doctrine.t t/1560-live-document-ceiling-authority.t` reports `All tests successful` at `Files=3, Tests=35`; `knowledge-map: OK`, the task-tree graph, README landing contract, locality, derived-state, and complete Markdown coverage stay green. No limit, milestone, ratchet, verifier, authority requirement, decision pairing, or debt baseline changed in this slice.

## Acceptance Checklist (enforced) — `.4`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'MEMORY_POINTER_LINE_CAP' --oneline -- scripts/check_memory_architecture.sh` identifies `70cd867e3`; source inspection shows the cap has always been a single line number carrying two unrelated jobs. `scripts/check_memory_architecture.sh:14` enforces it as the layer-routing control, while `doctrine/live_document_size/surfaces.jsonl` declared an 8,192-byte companion that no 60-line file can reach: `MEMORY.md` measured 3,515 bytes across 47 lines, so 60 lines is about 4,500 bytes and the byte dimension was structurally dead. Raising only the byte ceiling would therefore have been a measurable no-op, and deriving the line cap from it at that measured density yields ~440 lines — the unbounded layer-A blob `MEMORY_ARCHITECTURE.md` §1 and §12 name as the anti-pattern.
- [x] **ADDRESSED (verified)** — `scripts/check_memory_architecture.sh` now reports `MEMORY.md is 50 lines (<= cap 120)` where it previously reported `<= cap 60`, and `scripts/check_live_document_size.sh` moves `active_resume` from `target peak 62.7%` to `37.9%` with `bytes_each` 8,192 -> 32,768 and `lines_each` 75 -> 150. The 80% containment warning lands on 120 lines, exactly the enforced cap, so containment still signals at its owning doctrine's boundary and never restates it more tightly. `scripts/check_live_document_ceiling_authority.pl` reports `all ceiling-change invariants hold (4 increase(s))`, proving each raise is paired to newly added `docs/decisions/0066-memory-pointer-size-is-two-externally-owned-criteria.md`.
- [x] **NO REGRESSION** — staged `scripts/check_doctrines.sh` ends with `[doctrine] all doctrine checks passed`, and `prove -Iperl t/1553-readme-routed-destination-pressure.t t/1554-live-document-size-doctrine.t t/1560-live-document-ceiling-authority.t` reports `All tests successful` at `Files=3, Tests=35`; `knowledge-map: OK`, the task-tree graph, README landing contract, locality, derived-state, and complete Markdown coverage stay green, and no milestone percentage, ratchet, verifier, authority requirement, decision pairing, or debt baseline changed.

## Acceptance Checklist (enforced) — `.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'"lines_each":400' --oneline -- doctrine/live_document_size/surfaces.jsonl` identifies `18e2dcbc6`, where every surface received one `budgets` object holding a round line count beside an unrelated power-of-two byte count; `9bd081935` then copied that object into `health_targets` and `enforcement_ceilings` without re-deriving either dimension. Reading `git show 18e2dcbc6:doctrine/live_document_size/surfaces.jsonl` confirms the original pairs (`400`/`32768`, `60`/`8192`, `512`/`262144`) were never checked against the bytes per line their surfaces write, so `lines_each` became a second, tighter, undeclared cap on the same budget and the warning milestone fired on a dimension the content cannot exhaust.
- [x] **ADDRESSED (verified)** — `scripts/check_live_document_size.sh` moves `diagnostics` from `target peak 79.8%` to `46.5%` (`lines_each` 400 -> 768, bytes unchanged at 32,768), `active_resume` from `78.3%` to `62.7%` (`lines_each` 60 -> 75, bytes unchanged at 8,192), and `rationale` from `78.9%` to `63.1%` (`lines_each` 512 -> 640, `bytes_each` 262,144 -> 65,536). All three remain `normal` and each now peaks on a dimension its content can reach. `scripts/check_live_document_ceiling_authority.pl` reports `all ceiling-change invariants hold (5 increase(s))`, proving every raise is paired to newly added `docs/decisions/0065-live-document-line-and-byte-targets-are-derived-as-a-pair.md`. `scripts/check_memory_architecture.sh` still reports `MEMORY.md is 47 lines (<= cap 60)`, so the documented resume-pointer cap is unchanged and remains the binding authority.
- [x] **NO REGRESSION** — staged `scripts/check_doctrines.sh` ends with `[doctrine] all doctrine checks passed` over 22 surfaces and 3,001 declared document paths, and `prove -Iperl t/1553-readme-routed-destination-pressure.t t/1554-live-document-size-doctrine.t t/1560-live-document-ceiling-authority.t` reports `All tests successful` at `Files=3, Tests=35`; `knowledge-map: OK` covers 1,120 facts across 127 bounded shards, the task-tree graph, README landing contract, locality, derived-state, and complete Markdown coverage stay green, and no milestone percentage, ratchet, verifier, authority requirement, decision pairing, or debt baseline changed.

## Decisions

- `2026-08-19`: Proposed, not activated. Changing a health target is a reviewed
  act, and the honest first step is an audit of how these targets were derived
  rather than an immediate re-derivation. Recorded by the guarantor after the
  hazard was hit twice in one session.
- `2026-08-19`: **Activated on the director's explicit authorization.** The
  standing direction is that containment rules exist to ease containment, not
  to create problems; where they obstruct, relax the involved rule, apply the
  proposal, and adjust incrementally until the right set is found for FSMGen.
  This authorizes `.2` to change the affected targets without a further ask.
- `2026-08-19`: `.6` selects decision `0068` on director correction. `.5` fixed the
  symptom and left the cause: `COMMIT.md` told every slice to overwrite the block
  "when recording completed work" and to point it at "the new latest commit". A
  workflow step that runs on every slice outweighs a written rule about restraint,
  so the step changed. `MEMORY.md` is now the frontier pointer and nothing else.
- `2026-08-19`: `.5` selects decision `0067` after the director asked why a
  pointer keeps growing at all. It should not, and it was not one: 46% of the
  file was decision and lane summaries, all verified duplicates. The honest
  answer is that no doctrine did this — successive slices did, because
  `COMMIT.md` guarantees every slice has this file open and one summary line is
  always cheaper than opening the right store. `.2` and `.4` both mistook the
  symptom for the cause and moved limits; this leaf moves none.
- `2026-08-19`: `.4` selects decision `0066` on director direction. `MEMORY.md`'s
  two dimensions answer different questions — lines ask "is this still a
  pointer?", bytes ask "can a resuming agent read it in one call?" — so neither
  is derived from the other. The byte maximum is 32,768 as directed; the line
  cap moved 60 -> 120 because the byte raise alone was a no-op, and stopped
  there because ~440 lines would be the blob the standard prevents.
- `2026-08-19`: `.2` selects decision `0065`. A surface's dimensions are one
  derivation: choose the dimension that expresses the surface's information
  role, then derive the others from the retained surface's measured bytes per
  line, and never let a derived limit reach its milestone first. `diagnostics`
  is bytes-reviewed (reading cost of a chooser loaded on every diagnosis);
  `active_resume` and `rationale` are lines-reviewed.
- `2026-08-19`: `.2` resolves the `active_resume` open question by widening the
  reading, not the cap. `MEMORY_ARCHITECTURE.md` §6 and `MEMORY_POINTER_LINE_CAP`
  own the 60-line cap and `scripts/check_memory_architecture.sh` enforces it
  unconditionally. Containment was restating that cap and then tightening it to
  an undeclared 48 lines through its own 80% milestone. A health target of 75
  puts the containment warning exactly on the documented cap, so the cap keeps
  one authority. Widening `bytes_each` — the alternative named in the leaf
  acceptance — would have worsened the mismatch, since the byte dimension was
  already the slack one at 42.6%.
- `2026-08-19`: `.2` records that `rationale` holds two member classes. Prose
  records average 51 bytes per line and bind on lines; `docs/decisions/INDEX.md`
  is a 285-byte-per-line table, is the surface's largest member by bytes, and
  grows about 490 bytes per added record toward roughly 54 KiB at the surface's
  own 128-file target. `bytes_each` 65,536 is derived from that projection. A
  single pair cannot be calibrated to both classes, which also corrects `.1`'s
  quoted byte figure: the surface's byte peak was the index, not `0055`.
- `2026-08-19`: `.1` reframes the defect. The problem is not that the line
  budgets are small; it is that each miscalibrated surface declares a
  `lines_each` and `bytes_each` pair implying a bytes-per-line its content never
  uses, so the line dimension always reaches the milestone first while the byte
  dimension reports the surface as nearly empty. A milestone that fires on a
  dimension the content cannot exhaust is measuring the wrong thing.

## Open Questions

- `active_resume` is the one case where the tight line budget is deliberate:
  `MEMORY_ARCHITECTURE.md` §6 and `MEMORY_POINTER_LINE_CAP` both fix the
  resume pointer at one screen. `.2` must widen the reading rather than the
  documented cap, or state plainly that the 80% milestone on a 60-line surface
  is an effective 47-line cap and should be re-stated as such.

## Blockers

- None.

## Changelog

- `2026-08-19`: Created after `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.4`
  and `.5` were each forced to work around a line milestone at trivial byte
  pressure.
- `2026-08-19`: Activated by the director, and `.1` completed. `.1` corrected a
  misattribution in the activation text: the `rationale` surface is
  `docs/decisions/*.md`, not `DEVELOPMENT_NOTES.md`, and its two reported peaks
  came from different member files. The finding survives the correction — the
  binding member is a real decision record at 78.9% lines and 7.9% bytes — but
  the original wording named the wrong document and wrongly implied that
  `COMMIT.md`'s engineering-rationale route was about to fail. That route is
  the `engineering_rationale` surface at 13.4%, which is not affected.
- `2026-08-19`: `.2` re-derived the three target pairs, appended five
  `ceiling_increase_authority` rows against new decision `0065`, added the
  local calibration procedure to `LIVE_DOCUMENT_SIZE_CONTAINMENT.md`, and
  published fact card `live-document-target-pair-calibration`. It also opened
  `.3`, because `enforced_rules` and `engineering_rationale` carry the same pair
  defect without live pressure and must not be left merely reported.
- `2026-08-19`: `.4` set the resume pointer's byte maximum to 32,768 on director
  direction, raised the enforced line cap 60 -> 120, aligned the containment
  target at 150, and recorded the split in decision `0066`. It also corrected
  the live statements in `MEMORY.md`, `COMMIT.md`, `MEMORY_ARCHITECTURE.md` §6,
  and the fact card, without rewriting `0065` or `0007`.
- `2026-08-19`: `.5` removed the layer-A bloat vector. `MEMORY.md` went from 50
  lines / 3,800 bytes to 30 / 1,690 with no limit change, and
  `MEMORY_POINTER_FIELD_LINE_CAP` now fails a resume field that starts
  narrating. Decision `0067` and fact card `memory-pointer-layer-a-content`
  record the rule and the incentive that defeated the previous one.
- `2026-08-19`: `.6` removed the `COMMIT.md` phrases that produced the drift and
  reduced `MEMORY.md` to 14 lines / 654 bytes — the active work unit, the single
  next action, the in-flight/blocker flags, and the required `HEAD` derivation.
  Decision `0068` records the rule and the lesson.
