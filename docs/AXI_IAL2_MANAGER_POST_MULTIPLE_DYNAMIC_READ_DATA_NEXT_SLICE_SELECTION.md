# AXI IAL2 Manager Post Multiple Dynamic Read-Data Next-Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.260`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.261`, readiness audit for
generated burst-length and runtime beat-count/`RLAST` validation over
generated multiple dynamic read response-demux.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Why This Next

`.259` now ships scalar read-data capture over generated all-dynamic multiple
read response-demux for both single-beat and last-beat shapes. The remaining
read-data-adjacent dynamic residue is ordered:

1. burst-length metadata over multiple dynamic read demux;
2. runtime beat-count/`RLAST` validation over that burst-length metadata;
3. multi-beat output banks over the runtime-validation boundary.

The third item depends on the first two. The `.243` single-active dynamic
multi-beat behavior captures raw matched `RID` beats into output banks and
uses runtime beat-count/`RLAST` state to bound the bank. The multiple-dynamic
version therefore needs a readiness audit before implementation so it can
settle whether report-only raw-`ARLEN` capture and runtime validation can be
implemented directly across all generated dynamic transactions, whether they
need a public contract selector, or whether helper/report cleanup is required
first.

Mixed dynamic/static demux, same-cycle request widening, same-cycle
release-and-recapture, dynamic same-ID queues, scoreboards, direct backend
behavior, backend-language variants, and VHDL remain broader later owners.

## Audit Scope For .261

`.261` must read or reverify:

- `.259` multiple dynamic read-data behavior;
- `.258` multiple dynamic read-data contract selection;
- `.257` multiple dynamic read-data readiness audit;
- `.255` multiple dynamic read burst-last/`RLAST` response-demux behavior;
- `.251` multiple dynamic read single-beat response-demux behavior;
- `.243` single-active dynamic multi-beat output-bank behavior;
- `.240` single-active dynamic runtime validation behavior;
- `.238` single-active dynamic report-only raw-`ARLEN` burst-length behavior;
- current read-data burst-length, runtime-validation, matched-read-beat,
  output-bank, report, residue, support-accounting, and focused-validation
  helpers; and
- README, ROADMAP_V2, mdBook, Memory, and Knowledge Map state.

The audit should answer:

- whether the next behavior should split report-only raw-`ARLEN` capture and
  runtime validation into separate owners or select them together;
- whether all generated dynamic read demux transactions must carry
  per-transaction `burst-length` bindings before any behavior widens;
- how request-time raw `ARLEN` capture maps to each dynamic transaction's
  admitted request event;
- how expected-beat and read-beat counter state should be allocated per
  transaction for multiple active dynamic reads;
- whether raw matched-beat assertions from `.255` are sufficient for runtime
  validation or need new per-transaction checks;
- report vocabulary for multiple dynamic burst-length/runtime fields;
- diagnostics for missing, partial, extra, duplicate, or mismatched
  burst-length/runtime transaction coverage;
- sample names and support-accounting expectations for any later
  implementation owner;
- validation gates, including focused dynamic suite coverage and direct
  schedule/check/semantic/HDL probes; and
- rollback and explicit residue.

## Non-Goals

`.260` does not implement burst-length capture, runtime beat-count validation,
multi-beat output banks, mixed dynamic/static demux, same-cycle widening,
same-cycle release-and-recapture, dynamic same-ID queues, scoreboards, direct
backend behavior, backend-language variants, or VHDL.

`.261` is also an audit owner unless it explicitly selects a later
implementation or contract-selection leaf. It must not change parser,
generator, PPIF samples, support-accounting catalog, validation behavior,
generated artifacts, tests, schedule/check/semantic JSON, or HDL behavior
unless it first records that later owner.

## Validation

Selector validation is documentation and continuity only:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No focused generator, parser, support-accounting, schedule/check/semantic, or
HDL probes are required because `.260` changes no behavior.

## Rollback

Rollback is the `.260` selector commit. Reverting it restores `.260` as the
active post multiple dynamic read-data selector and removes the `.261`
readiness-audit owner.
