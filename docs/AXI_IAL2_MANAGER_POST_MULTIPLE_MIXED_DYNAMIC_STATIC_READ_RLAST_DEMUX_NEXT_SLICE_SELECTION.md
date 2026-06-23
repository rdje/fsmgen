# AXI IAL2 Manager Post Multiple Mixed Dynamic/Static Read RLAST Demux Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.304`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.305`, readiness audit for bounded
scalar read-data over generated multiple mixed dynamic/static read
response-demux.

The selected audit follows the now-shipped `.299` single-beat `RID`
response-demux and `.303` burst-last `RID && RLAST` response-demux for exactly
one dynamic read transaction plus two concrete static read transactions.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The selector read or used:

- `.303` multiple mixed dynamic/static read burst-last `RID && RLAST`
  response-demux behavior.
- `.302` multiple mixed dynamic/static read burst-last public contract
  selection.
- `.301` multiple mixed dynamic/static read burst-last readiness audit.
- `.299` multiple mixed dynamic/static read single-beat `RID` response-demux
  behavior.
- `.291` mixed dynamic/static multi-beat output-bank behavior over the
  one-dynamic plus one-static path.
- `.289` mixed dynamic/static runtime beat-count/`RLAST` validation behavior.
- `.287` mixed dynamic/static report-only raw-`ARLEN` capture behavior.
- `.284` mixed dynamic/static scalar read-data behavior over the one-dynamic
  plus one-static path.
- `.259` multiple dynamic scalar read-data behavior, including the precedent
  that scalar read-data consumes generated completion pulses without adding a
  second raw `RID` or `RID && RLAST` matcher.
- Current response-demux, read-data, burst-length, runtime-validation,
  multi-beat, support-accounting, focused validation cost, README,
  `ROADMAP_V2.md`, mdBook, task-tree, Memory, and Knowledge Map surfaces.

## Rationale

`.303` completed the final-beat completion prerequisite for the widened
multiple mixed dynamic/static read ownership shape. The repository now has
both response-demux completion sources that scalar read-data would need:

```text
generated_multi_mixed_dynamic_static_read_demux
generated_multi_mixed_dynamic_static_read_demux_last_beat
```

The next roadmap-aligned step is not raw `ARLEN`, runtime validation, or
multi-beat output banks yet. Those later owners depend on a read-data contract
that decides how the multi-static mixed transaction set maps generated
completion pulses to scalar `RDATA`/`RRESP` capture outputs. The existing
one-dynamic plus one-static path shipped in the same order:
response-demux, scalar read-data, raw `ARLEN`, runtime validation, and then
multi-beat output banks. The multiple dynamic path used the same scalar
read-data-before-burst/runtime ordering.

The `.305` audit should determine whether scalar read-data over multiple mixed
read demux is contract-ready, whether it needs a public contract selection
before implementation, whether any helper/report cleanup should come first,
and what validation strategy is realistic given the host-memory cutoffs seen
while closing `.303`.

## Selected .305 Boundary

`.305` should audit only bounded scalar read-data over generated multiple
mixed dynamic/static read response-demux. It should:

- inspect `.299` and `.303` response-demux reports and generated completion
  signal lists;
- compare the one-static mixed read-data behavior in `.284` and the multiple
  dynamic read-data behavior in `.259`;
- inspect `_read_data_response_demux_transaction_coverage`,
  `_normalize_read_data_read`, read-data capture rule generation, read-data
  report vocabulary, response-demux residue movement, support-accounting
  expectations, and focused dynamic tests;
- decide whether the next exact owner should be public contract selection,
  direct generated behavior, helper/report cleanup, or a narrower
  prerequisite;
- record candidate public sample stems, likely
  `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_read_data.ppif`
  and
  `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data.ppif`
  if the audit selects scalar behavior;
- record candidate completion-validity vocabulary, likely
  `generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse`
  and
  `generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`;
- record whether the covered transaction order is dynamic transactions
  followed by static transactions, preserving `r0, r1, r2` for the current
  bounded shape;
- record diagnostics for partial, extra, duplicate, or unsupported
  `read-data.read.transaction` bindings;
- record focused validation gates, including guarded direct CLI probes,
  lightweight report/adapter probes when direct probes trip host-memory
  guards, support-accounting checks if samples are added later, mdBook,
  Knowledge Map, memory, diff, and doctrine gates;
- record rollback and docs/Knowledge Map impact; and
- change no parser, generator, PPIF sample, support-accounting catalog,
  validation behavior, generated artifact, test, schedule/check or semantic
  JSON, or HDL behavior.

## Explicit Residue

These remain future exact owners unless `.305` deliberately selects one of
them as the next boundary:

- implementation of scalar read-data over multiple mixed read demux;
- raw `ARLEN` burst-length capture over multiple mixed read burst-last demux;
- runtime beat-count/`RLAST` validation over multiple mixed read burst-last
  demux;
- multi-beat output banks over multiple mixed read demux;
- two-dynamic plus one-static mixed dynamic/static cardinality;
- broader mixed write and read cardinalities;
- same-cycle request widening beyond onehot0;
- same-cycle release-and-recapture;
- dynamic same-ID queues and scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

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
HDL probes are required because `.304` changes no behavior.

## Rollback

Rollback is the `.304` selector commit. Reverting it restores `.304` as the
active selector after `.303` and removes the `.305` readiness-audit owner.
