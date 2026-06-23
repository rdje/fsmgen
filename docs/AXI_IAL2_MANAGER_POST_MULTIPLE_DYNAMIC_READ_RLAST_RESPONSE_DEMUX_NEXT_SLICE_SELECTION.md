# AXI IAL2 Manager Post Multiple Dynamic Read RLAST Response-Demux Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.256`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.257`, readiness audit for read-data
over generated multiple dynamic read response-demux.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The selector read or used:

- `.255` multiple dynamic read burst-last/`RLAST` response-demux behavior:
  `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md`
- `.254` multiple dynamic read burst-last/`RLAST` contract selection.
- `.253` multiple dynamic read burst-last/`RLAST` readiness audit.
- `.251` multiple dynamic read single-beat response-demux behavior.
- `.250` multiple dynamic read response-demux contract selection.
- `.247` multiple dynamic write response-demux behavior.
- `.243` dynamic multi-beat output-bank behavior.
- `.240` dynamic runtime beat-count/`RLAST` validation behavior.
- `.238` dynamic report-only raw-`ARLEN` burst-length behavior.
- `.234` scalar dynamic read-data behavior.
- `.231` single-active dynamic read burst-last/`RLAST` behavior.
- `.227` single-active dynamic read single-beat behavior.
- Current `_read_data_response_demux_transaction_coverage`,
  read-data/burst-length/runtime/multi-beat emission helpers,
  response-demux report/residue wording, focused validation caveats, README,
  ROADMAP_V2, mdBook, Memory, and Knowledge Map.

## Why Read-Data Coverage Is Next

`.255` removed the response-demux-only blocker for multiple dynamic read
burst-last/`RLAST`. The remaining read-side stack now has a clear dependency
order:

1. read-data must first learn how to consume generated completion pulses from
   multiple dynamic read transactions;
2. report-only raw-`ARLEN` burst-length capture over multiple dynamic reads
   depends on that read-data transaction coverage;
3. runtime beat-count/`RLAST` validation depends on both the read-data
   transaction coverage and request-time burst-length capture; and
4. multi-beat output-bank behavior depends on the runtime-validation shape.

The current dynamic read-data coverage helper still accepts only one dynamic
read transaction:

```text
AXI manager capacity/status IAL2 contract read_data.read dynamic coverage requires exactly one dynamic read transaction
```

The helper already has the right single-active completion-validity vocabulary
for `generated_dynamic_demux` and `generated_dynamic_demux_last_beat`, and the
multiple-dynamic response-demux reports now expose matching ordered
`dynamic_transactions` and `generated_completion_signals`. That makes
read-data coverage readiness the right next audit. It should decide whether
the next implementation can simply widen the dynamic coverage helper and
existing scalar capture/report paths, or whether a public contract-selection
slice is needed first.

## Selected .257 Boundary

`.257` should audit read-data over generated multiple dynamic read
response-demux. It should decide whether the next exact owner is:

- direct bounded scalar read-data behavior over multiple dynamic read demux;
- public contract selection before behavior;
- lower helper cleanup around dynamic transaction/completion mapping,
  completion-validity wording, or report residue;
- focused-suite/support-accounting cleanup; or
- a narrower prerequisite.

The audit should cover:

- the `.251` single-beat multiple dynamic read response-demux shape;
- the `.255` burst-last/`RLAST` multiple dynamic read response-demux shape;
- `read-data.read capture-scope single-beat` and `last-beat` scalar capture;
- whether the first read-data widening should cover both single-beat and
  last-beat multiple dynamic read demux or split them;
- mapping each covered dynamic transaction to its generated completion signal;
- data/status output binding requirements for all covered dynamic read
  transactions;
- completion validity strings for generated multiple dynamic single-beat and
  burst-last read demux;
- report `read_data.read.transactions`, generated inputs/outputs/rules, and
  response-demux residue cleanup;
- diagnostics for missing, duplicate, or extra transaction bindings;
- fail-closed boundaries for burst-length, runtime beat-count/`RLAST`
  validation, multi-beat output banks, mixed dynamic/static demux,
  same-cycle widening, release-and-recapture, dynamic same-ID queues,
  scoreboards, direct backend behavior, backend-language variants, and VHDL;
- focused parser/generator/dynamic/support-accounting validation expectations;
- docs, mdBook, README, ROADMAP_V2, Memory, Knowledge Map impact; and
- rollback.

## Non-Goals

`.257` should not implement read-data behavior. It should not change parser,
generator, PPIF samples, support-accounting catalog, validation behavior,
generated artifacts, tests, schedule/check/semantic JSON, or HDL behavior
unless it explicitly selects a later implementation owner.

The selector intentionally leaves these as later exact owners until `.257`
finishes:

- generated read-data over multiple dynamic read demux;
- burst-length/runtime validation over multiple dynamic read demux;
- multi-beat output banks over multiple dynamic read demux;
- mixed dynamic/static demux;
- same-cycle request widening beyond onehot0;
- same-cycle release-and-recapture;
- dynamic same-ID ordering;
- dynamic same-ID queues and scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

## Validation Gates

For this selector, documentation and continuity gates are sufficient:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No focused generator, parser, support-accounting, schedule/check/semantic, or
HDL probes are required because this slice changes no behavior.

## Rollback

Rollback is the `.256` selector commit. Reverting it restores `.256` as the
active post-implementation selector and removes the `.257` readiness-audit
selection record.
