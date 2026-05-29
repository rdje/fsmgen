# ISF-FULL-WIDTH-INFERENCE: Broader Data-Operation Width Inference

## Metadata

- Tree ID: `ISF-FULL-WIDTH-INFERENCE`
- Status: `proposed`
- Roadmap lane: `R14`
- Created: `2026-05-29`
- Last updated: `2026-05-29`
- Owner: repo-local workflow

## Status note

This is a **Proposed** tree: it records accepted backlog direction and
establishes task-tree ownership for the "Full Width Inference For Data
Operations" ISF backlog aspect. It is **not PNT-eligible** until
explicitly activated.

## Goal

Infer data-operation widths in more cases without explicit width
options, keeping accepted lowering free of width placeholders, beyond
the shipped single-missing-field/part inference.

## Current shipped boundary (owned elsewhere)

- `ISF-DATA-WIDTHS`: base width inference for shift/extract/assemble.
- `ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE`: exactly one missing
  `extract` destination field width.
- `ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE`: exactly one missing
  `assemble` part width.
- `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS`,
  `ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS`: explicit width-evidence
  sources.

## Remaining backlog (this tree's scope)

- `extract` with two or more unknown destination field widths.
- `assemble` with two or more unknown part widths.
- Any additional decidable inference context discovered later.

## Decidability caveat

Two-or-more-unknown inference is generally underdetermined: with N
unknown widths and a single total-width equation, the solution is not
unique, so the honest result is to **remain fail-closed** unless a
specific decidable sub-case is identified (for example, all-but-one
unknown widths constrained by an independent evidence source). This
tree will be activated only when such a decidable sub-case is found;
otherwise the current fail-closed behavior is the correct terminal
state and this tree stays proposed.

## Proposed first leaf

- `ISF-FULL-WIDTH-INFERENCE.1`: probe the validator for any decidable
  multi-unknown sub-case (e.g. two unknown `assemble` parts where one
  is independently width-evidenced); if found, ship inference for it;
  if not, record the fail-closed boundary as the honest terminal state
  and close.

## Blockers

- None. Activation is gated on identifying a decidable sub-case.
