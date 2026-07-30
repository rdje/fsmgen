# IAL2 Post Public-Sync Next-Owner Selection

## Selection

`IAL2-FEATURE-COMPLETENESS-FRONTIER.837` selects proposed
`MDBOOK-RUSTDOC-NON-RUST-FENCE-REPAIR.1` as the next exact owner.

The selected leaf must label exactly four already-identified plain-text
diagram fences as `text`, preserve their contents, and restore a clean
`mdbook test docs/book`. This selector does not activate or modify the
selected child before its own commit is clean.

## Current-HEAD Evidence

With an absolute repository-derived `TMPDIR`, `mdbook test docs/book` on clean
selector-activation commit `9cacba136` fails only at these four known blocks:

- the Pipeline diagram in `docs/book/src/13-intent-scheduling.md`;
- the transaction-to-state sketch in `docs/book/src/13b-transactions.md`;
- the Composition Architecture diagram in `docs/book/src/13f-composition.md`;
- the APB state summary in `docs/book/src/13h-lowering-reference.md`.

Every other chapter reaches rustdoc without a reported failure. The four
opening fences are still untyped, their matching closes are intact, and the
existing task/fact already bound the same exact repair. The probe's exact
repository-local scratch directory was removed after inspection.

## Candidate Comparison

| Candidate | Result | Evidence |
| --- | --- | --- |
| mdBook rustdoc fence repair | **selected** | Four one-line fence annotations restore the currently failing full-book doctest gate without changing rendered content or product behavior. |
| Four-document lifecycle review | remains proposed | Director direction schedules the policy discussion but keeps it inactive; `CHANGES.md` remains per-slice, `DEVELOPMENT_NOTES.md` conditional, and both legacy status files untouched meanwhile. |
| Protocol-composition identifier audit | remains proposed | Cross-protocol target-language identifier policy is broader than four reproduced documentation annotations. |
| HIAL/VIAL, HIR, host builder, scale, MCP-write, and protocol/backend horizons | remain proposed | Valuable architecture/product directions, but larger than the exact validation repair. |
| RAM guard, t1436, transaction layering, and AXI book-coherence items | ineligible | Their task trees retain explicit director gates. |

## Selected Contract And Rollback

The child may change only the four untyped opening fences listed above, from
triple backticks to triple backticks plus `text`. It must prove all intervening
diagram bytes unchanged, run `mdbook test docs/book` and `mdbook build
docs/book`, synchronize task/Memory/changelog/Knowledge Map state, and satisfy
all doctrine gates.

It must not reclassify another fence or change prose, examples, source/test
code, generated artifacts, parser/generator behavior, HDL/runtime behavior, or
the scheduled lifecycle review. Rollback restores the four untyped openings
and returns this selector to active; every other candidate remains
independently owned.

## Closeout Evidence

- The current-HEAD rustdoc probe reports only the four task-owned failures
  above; its exact repository-local output directory is removed.
- Feature-backlog status, live-book-path, and relative-path audits pass with
  `Files=3, Tests=40`.
- Knowledge Map generation/check passes at 1,070 facts / 5,507 question keys;
  mdBook HTML build and diff hygiene pass.
- `MEMORY.md` remains at its 60-line cap, `README.md` remains 246 lines,
  neither legacy status file changed, and no background job remains.

Clean selector commit `9e3308e5c` activates only the selected four-fence
repair through continuity changes. The fences, diagram contents, doctest
result, scheduled lifecycle review, and every product behavior remain
unchanged during activation.

The selected child now classifies exactly the four owned openings as `text`.
All diagram bytes are preserved, and the full 36-chapter mdBook doctest plus
HTML build pass. The repair tree is complete; the next action returns to the
clean parent IAL2 selector.
