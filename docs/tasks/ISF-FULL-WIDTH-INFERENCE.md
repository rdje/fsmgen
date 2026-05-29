# ISF-FULL-WIDTH-INFERENCE: Broader Data-Operation Width Inference

## Metadata

- Tree ID: `ISF-FULL-WIDTH-INFERENCE`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-29`
- Last updated: `2026-05-30`
- Owner: repo-local workflow

## Status note

Activated `2026-05-30` to run the `.1` probe leaf. The probe (see Decisions /
Probe outcome below) found **no decidable multi-unknown sub-case** beyond the
shipped single-missing inference, so per this tree's own `.1` definition the
honest terminal is to **record the fail-closed boundary and close** — which
this slice does (with an executable lock, `t/1385`).

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

## Probe outcome (`2026-05-30`)

Read the assemble/extract width-inference logic (`LoweringIR.pm` ~L4100-4140
assemble, ~L4220-4248 extract) and probed the live binary:

- Single missing part/field width with a known target IS inferred
  (`@unknown_indices == 1` → `target_width - known_total`, L4124/L4233);
  this is the shipped single-missing inference (owned by
  `ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE` /
  `ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE`).
- `@unknown_indices >= 2` returns with unknowns (L4134/L4244) → fail-closed
  downstream. **Genuinely two-or-more-unknown is underdetermined and correctly
  fail-closed.**
- The hypothesized decidable sub-case ("two unknown parts where one is
  independently width-evidenced") **does not exist as a distinct case**: an
  independently-evidenced part has a defined `$widths->{$part}`, so it is not
  in `@unknown_indices` at all — it reduces to the shipped single-missing
  inference.
- Interface signals always carry a width (scalar default 1), so a partial
  `(widths …)` is rejected by the count-must-match-part/field-count rule, and a
  parts-sum ≠ known-target mismatch fails closed with a clear diagnostic.

**Conclusion:** no decidable multi-unknown sub-case beyond what is shipped. The
current fail-closed behavior is the correct terminal state. This slice records
that boundary executably (`t/1385`) and closes the tree.

## Task Tree

- ID: `ISF-FULL-WIDTH-INFERENCE`
  Status: `done`
  Goal: `Probe for a decidable multi-unknown width sub-case; else record the fail-closed terminal and close.`
  Children: `ISF-FULL-WIDTH-INFERENCE.1`

- ID: `ISF-FULL-WIDTH-INFERENCE.1`
  Status: `done`
  Goal: `Probe; record the fail-closed terminal; lock the boundary with t/1385; close.`
  Acceptance: `No decidable sub-case found; boundary locked; tree closed.`
  Verification: `prove -Iperl t/1385 t/1344 t/1101 t/1250; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-30` | `ISF-FULL-WIDTH-INFERENCE.1` | `prove -Iperl t/1385 t/1344 t/1101 t/1250`; `mdbook build docs/book`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-FULL-WIDTH-INFERENCE.1` | `ISF-FULL-WIDTH-INFERENCE.1: record full-width-inference fail-closed terminal` | `ship commit (this slice)` |

## Changelog

- `2026-05-29`: Created as a Proposed tree (backlog ownership).
- `2026-05-30`: Activated; ran the `.1` probe. No decidable multi-unknown
  sub-case found (the multi-unknown case is underdetermined and correctly
  fail-closed; the only decidable case, single-missing, is already shipped).
  Recorded the fail-closed terminal, locked the boundary with `t/1385`, and
  closed the tree.

## Blockers

- None. Activation is gated on identifying a decidable sub-case.
