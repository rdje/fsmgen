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
  Children: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.1, LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.2, LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.3`

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
  Acceptance: `.2 fixed only the three surfaces under live pressure. Apply decision 0065's rule to every other surface in doctrine/live_document_size/surfaces.jsonl: divide bytes_each by lines_each, compare the implied bytes-per-line against the retained surface's measured value, and either re-derive the pair or record why the divergence is intended. enforced_rules (implies 109 against a measured 56, at 74.7%) and engineering_rationale (implies 131 against 61, at 13.4%) are the known instances; the sweep must be complete rather than limited to those two. Any increase needs its own paired decision record and authority row; lowering stays free. Change no milestone mechanism, ratchet, verifier, or authority requirement. Pass scripts/check_doctrines.sh.`
  Verification: `pending`
  Commit: `pending`

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
