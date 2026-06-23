# AXI IAL2 Manager Post Three-Static Mixed Dynamic/Static Read RLAST Demux Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.327`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.328`, readiness audit for bounded
scalar read-data over generated one-dynamic plus three-concrete-static mixed
dynamic/static read response-demux.

The selected audit follows the now-shipped `.322` single-beat `RID`
response-demux and `.326` burst-last `RID && RLAST` response-demux for
exactly one dynamic read transaction plus three concrete static read
transactions.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The selector read or used:

- `.326` three-static mixed dynamic/static read burst-last `RID && RLAST`
  response-demux behavior.
- `.325` three-static mixed dynamic/static read burst-last public contract
  selection.
- `.324` three-static mixed dynamic/static read burst-last readiness audit.
- `.322` three-static mixed dynamic/static read single-beat `RID`
  response-demux behavior.
- `.303` two-static mixed dynamic/static read burst-last `RID && RLAST`
  response-demux behavior.
- `.307`, `.310`, `.312`, and `.314` two-static mixed dynamic/static
  read-data, burst-length, runtime-validation, and multi-beat output-bank
  behavior over the multiple mixed boundary.
- Current `_read_data_response_demux_transaction_coverage`,
  `_normalize_read_data_read`, read-data capture/report helpers,
  response-demux residue, support accounting, focused dynamic tests,
  README, `ROADMAP_V2.md`, mdBook, task tree, Memory, and Knowledge Map
  surfaces.

## Rationale

`.326` completed the final-beat completion prerequisite for the widened
three-static mixed dynamic/static read ownership shape. The repository now
has both generated completion sources that scalar read-data would need for
the same one-dynamic plus three-static transaction set:

```text
generated_multi_mixed_dynamic_static_read_demux
generated_multi_mixed_dynamic_static_read_demux_last_beat
```

The next roadmap-aligned step is not raw `ARLEN`, runtime validation, or
multi-beat output banks yet. Those later owners depend on a read-data
contract that decides how the three-static mixed transaction set maps
generated completion pulses to scalar `RDATA`/`RRESP` capture outputs.

The existing read-side order is stable across the one-static, two-static, and
multiple-dynamic ladders: response-demux, scalar read-data, raw `ARLEN`,
runtime validation, and then multi-beat output banks. `.327` keeps that order
for the three-static mixed boundary by selecting a readiness audit first.

The current read-data coverage predicate already has a multiple mixed
dynamic/static branch for `generated_multi_mixed_dynamic_static_read_demux`
and `generated_multi_mixed_dynamic_static_read_demux_last_beat`, but that
branch still requires exactly one dynamic read transaction and exactly two
concrete static read transactions. A readiness audit is therefore the
smallest signoff-level next slice before widening read-data behavior to the
three-static boundary.

## Selected .328 Boundary

`.328` should audit only bounded scalar read-data over generated
one-dynamic plus three-concrete-static mixed dynamic/static read
response-demux. It should:

- inspect `.326` and `.322` response-demux reports and generated completion
  signal lists;
- compare the two-static mixed read-data behavior in `.307` and the
  one-static mixed read-data behavior in `.284`;
- inspect `_read_data_response_demux_transaction_coverage`,
  `_normalize_read_data_read`, read-data capture rule generation, read-data
  report vocabulary, response-demux residue movement, support-accounting
  expectations, and focused dynamic tests;
- decide whether the next exact owner should be public contract selection,
  direct generated behavior, helper/report cleanup, or a narrower
  prerequisite;
- record candidate public sample stems, likely
  `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_read_data.ppif`
  and
  `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data.ppif`
  if the audit selects scalar behavior;
- record candidate completion-validity vocabulary, likely
  `generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse`
  and
  `generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`;
- record whether the covered transaction order remains dynamic transactions
  followed by static transactions, preserving `r0, r1, r2, r3` for the new
  bounded shape;
- record diagnostics for partial, extra, duplicate, or unsupported
  `read-data.read.transaction` bindings and unsupported three-static
  burst-length/runtime/multi-beat extensions;
- record focused validation gates, including guarded direct CLI probes,
  support-accounting checks if samples are added later, mdBook, Knowledge
  Map, memory, diff, and doctrine gates;
- record rollback and docs/Knowledge Map impact; and
- change no parser, generator, PPIF sample, support-accounting catalog,
  validation behavior, generated artifact, test, schedule/check or semantic
  JSON, or HDL behavior.

## Explicit Residue

These remain future exact owners unless `.328` deliberately selects one of
them as the next boundary:

- implementation of scalar read-data over three-static mixed read demux;
- raw `ARLEN` burst-length capture over three-static mixed read burst-last
  demux;
- runtime beat-count/`RLAST` validation over three-static mixed read
  burst-last demux;
- multi-beat output banks over three-static mixed read demux;
- two-dynamic plus one-static mixed dynamic/static cardinality;
- broader capped mixed write and read cardinalities;
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
HDL probes are required because `.327` changes no behavior.

## Rollback

Rollback is the `.327` selector commit. Reverting it restores `.327` as the
active selector after `.326` and removes the `.328` readiness-audit owner.
