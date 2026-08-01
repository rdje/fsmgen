# Engineering rationale ledger index

`DEVELOPMENT_NOTES.md` is the bounded current view. Add entries only for
durable, non-obvious engineering rationale that has no better canonical home.
Task evidence, decisions, fact cards, user documentation, source comments, and
work-unit Git history remain preferred when they answer the question directly.

## Ordered ranges

| Sequence | Range | Ordinals | Entries | Storage | Retrieval |
| --- | --- | ---: | ---: | --- | --- |
| 1 | `engineering-rationale-0001` | 1–2843 | 2843 | exact version-backed archive descriptor | `git show d3c22e003d6e732a51dc69e6a999cdbd41963e84:DEVELOPMENT_NOTES.md`; the range is the entry body after the two-line legacy preamble |
| 2 | `engineering-rationale-current` | 2844–2847 | 4 | bounded current view | [DEVELOPMENT_NOTES.md](DEVELOPMENT_NOTES.md) |

The complete pre-cutover source is fixed by descriptor
`engineering-rationale-source-2026-08-01`. The ordered entry body is checked
independently by descriptor `engineering-rationale-range-0001`; both use the
`fsmgen_required_history` retention contract. The executed verifier proves the
source body is the exact reconstruction prefix and that the current range is a
real post-cutover append.

## Append and rotation contract

1. Append a whole `## ` rationale entry to `DEVELOPMENT_NOTES.md` only when the
   conditional rationale rule is satisfied.
2. Update the current range endpoint, dimensions, entry digests, and aggregate
   ledger identity in `doctrine/live_document_size/ledger_manifests.jsonl`.
3. Run `scripts/check_engineering_rationale_ledger.pl` and the doctrine gate.
4. Before the current view reaches its 2,000-line or 256-KiB health target,
   close it only at an entry boundary, store the range through a proved seal or
   archive descriptor, append the next ordered range row here, and start a new
   bounded current range.

Historical range identity never depends on dates sorting monotonically. The
authoritative order is the preserved file order and contiguous ordinal
sequence.
