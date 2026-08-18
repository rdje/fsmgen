# KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION: Restore writable headroom on the fact-card surface

## Metadata

- Tree ID: `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION`
- Status: `active`
- Roadmap lane: `infra/continuity`
- Created: `2026-08-19`
- Last updated: `2026-08-19`
- Owner: repo-local workflow

## Goal

Restore honest, non-zero write headroom on the `knowledge_cards` live-document
surface so the Knowledge Map write path mandated by `AGENTS.md` stays open,
without deleting an exact recorded fact and without silently raising a ceiling
that belongs to another authority.

## Non-Goals

- Deleting, thinning, or downgrading any exact recorded fact merely to fit a
  numeric budget.
- Changing any other surface's ceilings, ratchets, or containment state.
- Re-opening the decision-`0041` containment model itself.

## Origin

`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.4.2` extended one fact card
by 17 lines and was rejected by `scripts/check_live_document_size.sh`. That
slice fitted its addition by compacting superseded chronology, which closed the
remaining headroom entirely rather than creating it.

Measured on commit `9c2a79765` with
`scripts/check_live_document_size.sh`:

| Dimension | Actual | Transition allowance | Enforcement ceiling | Headroom |
| --- | ---: | ---: | ---: | ---: |
| files | 1,109 | 1,105 + 4 = 1,109 | 1,109 | `0` |
| lines_total | 42,136 | 41,711 + 425 = 42,136 | 42,165 | `0` |
| bytes_total | 3,180,846 | 3,151,130 + 30,031 = 3,181,161 | 3,246,227 | `315` |

Both zero-headroom results are mechanically reproduced, not inferred: copying
one existing card to a new path makes the checker report
`surface knowledge_cards files is 1110 (> inclusive enforcement ceiling 1109)`
and `total lines is 42137 (> baseline 41711 + growth 425)`, and exit `1`.

The consequence is a live contradiction between two enforced doctrines.
`AGENTS.md` requires writing a fact card whenever a durable fact is newly
established; `LIVE-DOCUMENT-SIZE` currently rejects both a new card and a
single new line in any existing card.

## Acceptance Criteria

- The exact binding rule, its owning authority, and every selectable repair
  route are identified from tracked registries rather than assumed.
- The selected repair restores non-zero headroom in all three dimensions.
- No exact recorded fact is removed; any compaction removes only duplicated or
  superseded narration, and says so with before/after measurements.
- Any ceiling, baseline, or ratchet change is made by, or explicitly delegated
  by, the authority that owns it, and passes the ceiling-authority guard.
- `scripts/check_doctrines.sh` passes, and a new card plus a new card line are
  both demonstrably acceptable afterwards.
- `scripts/check_task_tree_integrity.pl` passes while this tree is active.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION`
  Status: `active`
  Goal: `Restore non-zero, honest write headroom on the knowledge_cards surface.`
  Children: `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.1, KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.2`

- ID: `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.1`
  Status: `pending`
  Goal: `Audit the exact binding rule, owning authority, and selectable repair routes without changing enforcement.`
  Acceptance: `Read-only. Identify from doctrine/live_document_size/surfaces.jsonl and the live-document-size checker package which of the files/lines/bytes rules binds first, which authority owns the rollover_debt transition and its ratchet_step, whether the declared ratchet is intended to be applied per adoption slice, and how much durable compaction the existing card corpus can honestly yield. Record the selected route with exact measurements and name any decision record it requires. Change no registry value, card, or check.`
  Verification: `pending`
  Commit: `pending activation`

- ID: `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.2`
  Status: `pending`
  Goal: `Implement the selected repair and prove restored headroom.`
  Acceptance: `Apply only the route selected by .1. Prove with before/after checker output that files, lines_total, and bytes_total all regain non-zero headroom, that a newly added card and a newly added card line are both accepted, and that no exact recorded fact was removed. Pass the ceiling-authority guard, scripts/check_doctrines.sh, and the Knowledge Map gate.`
  Verification: `pending`
  Commit: `pending activation`

## Decisions

- `2026-08-19`: Treat this as a continuity blocker rather than a cosmetic
  budget question. Two enforced doctrines currently contradict each other, and
  the cheapest local fix — deleting recorded facts — is explicitly rejected.

## Open Questions

- Does the `rollover_debt` `ratchet_step` for `knowledge_cards`
  (`files 1`, `lines_total 50`, `bytes_total 4096`) exist to be applied once per
  adoption slice by `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION`, or only by the
  named transition owner `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.18.2`? `.1` must
  answer this from tracked sources; it decides whether `.2` ratchets or
  compacts. It blocks `.2`, not `.1`.

## Blockers

- None for `.1`.

## Changelog

- `2026-08-19`: Created task tree after the exhaustion was reproduced during
  `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.4.2`.
