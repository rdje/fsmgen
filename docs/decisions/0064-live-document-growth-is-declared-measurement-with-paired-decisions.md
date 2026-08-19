# 0064 — Fact cards are a cheap-to-add retrieval surface, not a ceiling-rationed one

- Date: 2026-08-19
- Type: infra/continuity governance
- Status: selected by `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.3`
- Refines: [0041](0041-live-document-size-containment-architecture.md)
- Implementation owner: `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.3`
- Ceiling authority: `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.3-KNOWLEDGE-CARD-FILES`
- Surface: `knowledge_cards`
- Dimension: `files`
- Change: `1109 -> 1536`
- Ceiling authority: `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.3-KNOWLEDGE-CARD-LINES`
- Surface: `knowledge_cards`
- Dimension: `lines_total`
- Change: `42165 -> 65536`
- Ceiling authority: `KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.3-KNOWLEDGE-CARD-BYTES`
- Surface: `knowledge_cards`
- Dimension: `bytes_total`
- Change: `3246227 -> 4194304`

## Context

`AGENTS.md` requires a fact card whenever investigation establishes a durable
fact that was genuinely absent. The value of that rule is retrieval: a card is
cheap to write and turns a future excavation into one bounded query. The rule
only works if adding a card is close to free.

It had stopped being free. `knowledge_cards` carried enforcement ceilings pinned
to the measured actual at adoption — `files 1109`, `lines_total 42165`,
`bytes_total 3246227` — while its own reviewed health targets were `1536`,
`65536`, and `4194304`. Ceilings sat 28% to 38% below the sizes the surface
itself declares healthy. Every new card was therefore a ceiling increase
requiring a decision record, and the file dimension had reached exactly zero
headroom.

The cost was not theoretical. A slice extending one card was rejected, could
not find the procedure in the Knowledge Map or `TOOLBOX.md`, read the
containment prose alone, and concluded the write path was structurally blocked
and that two enforced doctrines contradicted each other. That conclusion was
false, and it was reached because the retrieval surface that should have
answered the question had itself been rationed into silence.

Two mechanisms are separate and must stay separate. Ceiling increases are
genuinely reviewed events. Declaring a new measured `transition.max_growth`
inside an unchanged ceiling is not, and repository practice has always treated
it that way: `knowledge_cards` `max_growth.lines_total` has moved 358, 375,
392, 429, 425 across ordinary slices.

## Decision

1. Raise the `knowledge_cards` collection ceilings to the surface's own
   reviewed health targets: `files 1109 -> 1536`,
   `lines_total 42165 -> 65536`, `bytes_total 3246227 -> 4194304`. The health
   targets are the existing reviewed statement of what this surface may hold;
   the pinned ceilings were an adoption-census artifact, not a contract.
2. Leave every per-file bound unchanged — `bytes_each 32768`,
   `lines_each 512`, `line_bytes_each 1024`. Cards must stay small, single-fact
   signposts. Cheap to add is the goal; cheap to *read* is the constraint that
   makes it worth anything.
3. Adding an ordinary fact card is consequently a normal write, not a governed
   event. Do not require a decision record, an authority row, or a ceiling
   change for one.
4. Keep the authority requirement for ceiling increases themselves. It is the
   control that makes a ceiling mean something; this record is one such
   reviewed increase, not a repeal of the rule.
5. Never delete or thin a recorded fact to fit a numeric budget. Compaction may
   remove duplicated or superseded narration only.
6. For whether growth is permitted, the authority is
   `doctrine/live_document_size/surfaces.jsonl`,
   `doctrine/live_document_size/ceiling_increase_authorities.jsonl`, and the two
   executable guards. `LIVE_DOCUMENT_SIZE_CONTAINMENT.md` carries rationale and
   the local operating procedure; its prose does not by itself prohibit a change
   the guards accept.

## Consequences

- Fact cards regain their intended economics: 427 files, 23,400 lines, and
  1,013,458 bytes of headroom, so an agent writes the card instead of skipping
  it or arguing with a budget.
- One prose/check divergence is explicitly resolved in favour of the check.
  Other divergences in that document remain unresolved and belong to
  `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION`; this record does not license
  ignoring containment prose generally.
- The surface stays in `rollover_debt` after this change for an unrelated
  reason: one 32,746-byte card sits 22 bytes under the per-file target. That
  card must be split before the surface can return to `normal`, and until then
  `transition.max_growth` still tracks measured line and byte totals.
- No milestone, ratchet, verifier, per-file bound, or product behavior changes.

## Containment

One bounded rationale record under the existing decision collection limits. Its
paired card is the retrieval surface; this record is the rationale home.
