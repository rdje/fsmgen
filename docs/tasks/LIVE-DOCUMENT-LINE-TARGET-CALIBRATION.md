# LIVE-DOCUMENT-LINE-TARGET-CALIBRATION: Re-derive line health targets that fail edits under trivial byte pressure

## Metadata

- Tree ID: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION`
- Status: `proposed`
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

| Surface | Document | Lines | Line % | Byte % | Lines to 80% |
| --- | --- | --- | --- | --- | --- |
| `diagnostics` | `TOOLBOX.md` | 319/400 | 79.8% | 41.7% | 1 |
| `active_resume` | `MEMORY.md` | 46/60 | 76.7% | 41.4% | 2 |
| `live_document_review` | review doc | 76/100 | 76.0% | 78.1% | 4 |
| `rationale` | `DEVELOPMENT_NOTES.md` | 404/512 | 78.9% | 8.7% | 5 |

`live_document_review` is excluded from the concern: its line and byte pressure
agree, so its signal is honest. The other three are the finding.

`rationale` is the clearest case. `DEVELOPMENT_NOTES.md` is at 78.9% of its
line target while using 8.7% of its byte budget, because a `lines_each` of 512
paired with a `bytes_each` of 262,144 implies ~512-byte lines against a
document whose lines average roughly 56 bytes. `COMMIT.md` routes durable
engineering rationale there, so the next slice that legitimately produces
rationale will fail the gate for a reason unrelated to the document's size.

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
  Children: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.1`

- ID: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.1`
  Status: `pending`
  Goal: `Audit how each affected lines_each target was originally derived, without changing enforcement.`
  Acceptance: `Read-only. For diagnostics, active_resume, and rationale, recover from git and the containment doctrine how lines_each and bytes_each were each derived, and whether the pair was ever intended to be consistent. Report whether the line target encodes a real information-role limit or an unreviewed default, and only then propose per-surface leaves.`
  Verification: `pending`
  Commit: `pending`

## Decisions

- `2026-08-19`: Proposed, not activated. Changing a health target is a reviewed
  act, and the honest first step is an audit of how these targets were derived
  rather than an immediate re-derivation. Recorded by the guarantor after the
  hazard was hit twice in one session.

## Open Questions

- Is the tight `lines_each` budget on a chooser or resume pointer deliberate
  reading-cost control, in which case the correct answer is to keep it and
  accept in-place rewriting? `.1` must answer this before any target moves.

## Blockers

- None.

## Changelog

- `2026-08-19`: Created after `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.4`
  and `.5` were each forced to work around a line milestone at trivial byte
  pressure.
