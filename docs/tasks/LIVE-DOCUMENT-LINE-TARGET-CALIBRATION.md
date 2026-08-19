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
  Children: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.1, LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.2`

- ID: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.1`
  Status: `done`
  Goal: `Measure the line/byte target pairs and identify which surfaces are genuinely miscalibrated.`
  Acceptance: `Read-only. For each candidate surface, compare the declared lines_each and bytes_each against the retained surface's actual bytes per line, and identify the exact binding member. Correct any misattributed measurement before proposing a change.`
  Verification: `Read-only measurement of six surfaces. Three are genuinely miscalibrated, each declaring an implied bytes-per-line far above what the retained surface uses: diagnostics implies 81 against TOOLBOX.md's actual 42, active_resume implies 136 against MEMORY.md's 73, and rationale implies 512 against decision records' 51. live_document_review implies 51 against an actual 52 and is correctly calibrated, which is why its line and byte pressure agree; it is excluded. engineering_rationale implies 131 against DEVELOPMENT_NOTES.md's 61 but sits at 13.4%, so it has no live pressure and needs no change now. This leaf also corrected the activation finding: the rationale surface is docs/decisions/*.md, not DEVELOPMENT_NOTES.md, and on a collection surface each dimension is the maximum across members, so the reported line and byte peaks may come from different files. The binding member is docs/decisions/0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md at 404/512 lines and 20,775/262,144 bytes.`
  Commit: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.1: measure the miscalibrated line targets`

- ID: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.2`
  Status: `pending`
  Goal: `Re-derive the three miscalibrated lines_each values from the retained surface's measured bytes per line.`
  Acceptance: `Apply the doctrine's own Derive pressure limits from the retained surface method: a surface's lines_each and bytes_each must imply a bytes-per-line consistent with what that surface actually writes. Re-derive lines_each for diagnostics, active_resume, and rationale so the two dimensions reach their milestones together instead of the line dimension failing first at trivial byte pressure. active_resume must stay consistent with MEMORY_ARCHITECTURE.md and MEMORY_POINTER_LINE_CAP, so prefer widening its bytes_each or its milestone over breaking the documented one-screen cap. Where health_targets equals enforcement_ceilings, a raise is a reviewed ceiling increase and needs its paired decision record and ceiling_increase_authority row. Change no milestone mechanism, ratchet, verifier, or authority requirement. Pass scripts/check_doctrines.sh.`
  Verification: `pending`
  Commit: `pending`

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
