# AXI IAL2 Manager Post Mixed Dynamic/Static Read RLAST Demux Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.281`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.282`, readiness audit for
read-data over generated mixed dynamic/static read response-demux.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The selector read or used:

- `.280` mixed dynamic/static read burst-last `RID && RLAST` response-demux
  behavior:
  `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md`
- `.279` mixed dynamic/static read burst-last contract selection.
- `.278` mixed dynamic/static read burst-last readiness audit.
- `.277` post mixed dynamic/static read single-beat selector.
- `.276` mixed dynamic/static read single-beat `RID` response-demux behavior.
- `.272` mixed dynamic/static write `BID` response-demux behavior.
- `.259` multiple dynamic scalar read-data behavior and its `.256`/`.257`/`.258`
  selector/audit/contract chain.
- `.234` single-active dynamic scalar read-data behavior and `.233` readiness
  audit.
- Current `_read_data_response_demux_transaction_coverage`,
  read-data/burst-length/runtime/multi-beat emission helpers, response-demux
  report/residue wording, focused validation caveats, README, ROADMAP_V2,
  mdBook, Memory, and Knowledge Map.

## Why Read-Data Coverage Is Next

`.276` and `.280` now cover both scalar mixed dynamic/static read
response-demux completion boundaries:

- single-beat `RID` completion source
  `generated_mixed_dynamic_static_read_demux`; and
- burst-last `RID && RLAST` completion source
  `generated_mixed_dynamic_static_read_demux_last_beat`.

That removes the response-demux-only blocker for scalar read-data capture over
the mixed dynamic/static read family. The next dependency order is now:

1. read-data must learn whether and how to consume generated completion pulses
   from the one-dynamic plus one-concrete-static mixed read demux;
2. report-only raw-`ARLEN` burst-length capture over that last-beat mixed read
   shape depends on read-data transaction coverage;
3. runtime beat-count/`RLAST` validation depends on read-data coverage plus
   request-time burst-length capture; and
4. multi-beat output-bank behavior depends on the runtime-validation shape.

The current read-data response-demux transaction coverage helper has branches
for generated auto-ID, concrete queue-head, mixed auto-ID plus queue-head, and
all-dynamic response-demux families. It has no branch for
`generated_mixed_dynamic_static_read_demux` or
`generated_mixed_dynamic_static_read_demux_last_beat`, so a mixed read-data
source still fails before scalar capture can be normalized.

The mixed response-demux reports now expose the data the read-data owner needs:
ordered `dynamic_transactions`, `static_transactions`, `mixed_transactions`,
and `generated_completion_signals`. The next audit should decide whether the
implementation can reuse the existing scalar capture path directly or needs a
public contract-selection slice first.

## Selected .282 Boundary

`.282` should audit read-data over generated mixed dynamic/static read
response-demux. It should decide whether the next exact owner is:

- direct bounded scalar read-data behavior over mixed dynamic/static read
  demux;
- public contract selection before behavior;
- helper cleanup around mixed transaction/completion mapping,
  completion-validity wording, diagnostics, or report residue;
- focused-suite/support-accounting cleanup; or
- a narrower prerequisite.

The audit should cover:

- the `.276` single-beat mixed dynamic/static read response-demux shape;
- the `.280` burst-last `RID && RLAST` mixed dynamic/static read
  response-demux shape;
- `read-data.read capture-scope single-beat` and `last-beat` scalar capture;
- whether the first read-data widening should cover both single-beat and
  last-beat mixed read demux or split them;
- mapping the dynamic transaction and static transaction to their generated
  completion signals;
- data/status output binding requirements for both covered read transactions;
- completion validity strings for generated mixed dynamic/static single-beat
  and burst-last read demux;
- report `read_data.read.transactions`, generated inputs/outputs/rules, and
  response-demux residue cleanup;
- diagnostics for missing, duplicate, partial, or extra transaction bindings;
- fail-closed boundaries for burst-length, runtime beat-count/`RLAST`
  validation, multi-beat output banks, multiple mixed transactions,
  same-cycle widening, release-and-recapture, dynamic same-ID queues,
  scoreboards, direct backend behavior, backend-language variants, and VHDL;
- focused parser/generator/dynamic/support-accounting validation
  expectations;
- docs, mdBook, README, ROADMAP_V2, Memory, Knowledge Map impact; and
- rollback.

## Non-Goals

`.281` does not implement read-data behavior. It does not change parser,
generator, PPIF samples, support-accounting catalog, validation behavior,
generated artifacts, tests, schedule/check/semantic JSON, or HDL behavior.

These remain later exact owners unless `.282` explicitly selects otherwise:

- generated read-data over mixed dynamic/static read demux;
- burst-length/runtime validation over mixed dynamic/static read demux;
- multi-beat output banks over mixed dynamic/static read demux;
- multiple mixed dynamic/static read or write transactions;
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

Rollback is the `.281` selector commit. Reverting it restores `.281` as the
active post-implementation selector and removes the `.282` readiness-audit
selection record.
