# 0065 — A surface's line and byte targets are one derivation, not two round numbers

- Date: 2026-08-19
- Type: infra/continuity governance
- Status: selected by `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.2`
- Refines: [0041](0041-live-documents-use-bounded-views-over-durable-stores.md), [0064](0064-live-document-growth-is-declared-measurement-with-paired-decisions.md)
- Implementation owner: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.2`
- Ceiling authority: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.2-DIAGNOSTICS-LINES-EACH`
- Surface: `diagnostics`
- Dimension: `lines_each`
- Change: `400 -> 768`
- Ceiling authority: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.2-DIAGNOSTICS-LINES-TOTAL`
- Surface: `diagnostics`
- Dimension: `lines_total`
- Change: `400 -> 768`
- Ceiling authority: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.2-ACTIVE-RESUME-LINES-EACH`
- Surface: `active_resume`
- Dimension: `lines_each`
- Change: `60 -> 75`
- Ceiling authority: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.2-ACTIVE-RESUME-LINES-TOTAL`
- Surface: `active_resume`
- Dimension: `lines_total`
- Change: `60 -> 75`
- Ceiling authority: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.2-RATIONALE-LINES-EACH`
- Surface: `rationale`
- Dimension: `lines_each`
- Change: `512 -> 640`

## Context

`LIVE_DOCUMENT_SIZE_CONTAINMENT.md` requires health targets to be derived from
the retained surface. FSMGen's first census did not do that for every surface.
`git log -S'"lines_each":400' --oneline -- doctrine/live_document_size/surfaces.jsonl`
identifies `18e2dcbc6`, where each surface received one `budgets` object holding
a round line count beside an unrelated power-of-two byte count. `9bd081935`
later split that object into `health_targets` and `enforcement_ceilings`
without re-deriving either dimension. Neither commit checked the pair against
the bytes per line the surface actually writes.

Three surfaces inherited a pair that no content can satisfy in both dimensions
at once. Measured on the tree at `f269aab12`:

| Surface | Binding member | Implied B/line | Measured B/line | Line % | Byte % |
| --- | --- | --- | --- | --- | --- |
| `diagnostics` | `TOOLBOX.md` | 82 | 43 | 79.8% | 41.7% |
| `active_resume` | `MEMORY.md` | 137 | 74 | 78.3% | 42.6% |
| `rationale` | `0055-*.md` (lines) | 512 | 51 | 78.9% | 8.7% |

The line dimension therefore reaches the 80% warning milestone while the byte
dimension still reports the surface as nearly empty. That is not a tight
budget; it is a milestone firing on a dimension the content cannot exhaust.
The cost was real and repeated: `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.4`
could not add two lines to `MEMORY.md`, and `.2` and `.5` each had to rewrite a
`TOOLBOX.md` row in place rather than add one. The documented workaround —
rewrite a line instead of adding one — pressures every edit toward denser, less
readable prose in exactly the documents an agent must read on resume.

## Decision

1. **A surface's dimensions are one derivation.** Choose the dimension that
   expresses the surface's information role, then derive the others from the
   retained surface's measured bytes per line. A derived limit must never reach
   its milestone before the reviewed one. Two independently chosen round
   numbers are not a derivation.
2. **A warning milestone must be reachable only by real growth.** The doctrine
   already requires the warning to leave room for the largest normal update
   plus the rollover transaction. One line of headroom, as `diagnostics` had,
   fails that requirement regardless of how the number was obtained.
3. `diagnostics`: the reviewed dimension is **bytes**. `TOOLBOX.md` is loaded
   on every diagnosis, so its reading cost is the budget, and 32,768 bytes is
   the reviewed statement of that cost. `lines_each` becomes `768` — the line
   count that 32 KiB of 43-byte lines actually is. No new reading cost is
   granted; the line dimension stops being a second, tighter, accidental cap on
   the same budget.
4. `active_resume`: the reviewed dimension is **lines**, and it is owned
   elsewhere. `MEMORY_ARCHITECTURE.md` §6 and `MEMORY_POINTER_LINE_CAP` fix the
   resume pointer at 60 lines, enforced unconditionally by
   `scripts/check_memory_architecture.sh`. Containment must not restate that cap
   more tightly: an 80% milestone on a 60-line target is an undeclared 48-line
   cap. `lines_each` becomes `75`, placing the containment warning exactly on
   the documented 60-line cap. The documented cap is unchanged and still
   binding; only the duplicate that silently tightened it is removed.
5. `active_resume` keeps `bytes_each` at `8,192`. Its byte dimension is a
   deliberately non-binding safety net, because the line dimension is
   externally owned and the resume pointer must never be the thing that blocks
   recording where work stands. This is a stated exemption from rule 1, not an
   oversight.
6. `rationale`: the reviewed dimension is **lines**. `lines_each` becomes `640`
   so the largest retained record (404 lines) keeps room for a normal update —
   including the `superseded by` edit the memory architecture requires — before
   warning. `bytes_each` falls `262,144 -> 65,536`: a quarter-megabyte prose
   record is not a decision record, and 64 KiB is derived from the two retained
   member classes rather than from one of them.
7. `rationale` has two member classes and that is now explicit. Prose records
   average 51 bytes per line and bind on lines. `docs/decisions/INDEX.md` is a
   dense table at 285 bytes per line, is the surface's largest member at 22,810
   bytes, and grows about 490 bytes per added record; at the surface's own
   128-file target it reaches roughly 54 KiB. The 64 KiB per-file byte budget is
   derived from that projection, so the index binds on bytes while records bind
   on lines. A single pair cannot be calibrated to both classes at once.
8. No milestone percentage, ratchet, verifier, authority requirement, decision
   pairing, or debt baseline changes. Every increase here carries its own
   appended `ceiling_increase_authority` row.

## Consequences

- The three surfaces return to honest, reachable pressure: `diagnostics` 46.5%,
  `active_resume` 62.7%, `rationale` 63.1%, each peaking on a dimension its
  content can actually exhaust.
- Ordinary editorial writes to `TOOLBOX.md`, `MEMORY.md`, and the decision store
  stop being rejected at trivial byte pressure, so the containment rule no
  longer degrades the surfaces it protects.
- `MEMORY.md` remains capped at 60 lines. Anyone reading only
  `surfaces.jsonl` would now infer 75; the authority is
  `MEMORY_ARCHITECTURE.md` plus `scripts/check_memory_architecture.sh`, and this
  record is where that split is written down.
- The same pair defect exists on other surfaces that are not yet under
  pressure — `enforced_rules` implies 109 bytes per line against a measured 56,
  and `engineering_rationale` implies 131 against 61.
  `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.3` owns that sweep; this record does
  not license changing a target without one.
- Lowering a target or ceiling remains free and unreviewed. Only the five
  increases above required authority, and each is paired to this record.

## Containment

One bounded rationale record under the existing decision collection limits, and
the operating procedure it implies is added to the local adoption note in
`LIVE_DOCUMENT_SIZE_CONTAINMENT.md` so a future write finds it without reading
this record.
