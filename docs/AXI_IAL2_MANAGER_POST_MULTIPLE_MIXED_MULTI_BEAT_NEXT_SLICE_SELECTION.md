# AXI IAL2 Manager Post Multiple Mixed Multi-Beat Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.315`

Date: 2026-06-23

## Inputs Read

This selector follows the generated multiple mixed dynamic/static read-data
chain through `.314`:

- `.314` multiple mixed dynamic/static multi-beat output-bank behavior;
- `.313` multiple mixed multi-beat readiness audit;
- `.312` multiple mixed runtime beat-count/`RLAST` validation;
- `.307` multiple mixed scalar read-data behavior;
- `.303` and `.299` multiple mixed read response-demux behavior;
- `.291` one-dynamic plus one-static mixed multi-beat behavior;
- `.268` multiple all-dynamic multi-beat behavior;
- current response-demux, read-data, burst-length/runtime, and multi-beat
  residue in README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge
  Map.

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.316`, a readiness audit for
broader mixed dynamic/static transaction cardinality after generated multiple
mixed read-data reached multi-beat output banks.

The current supported mixed dynamic/static family now covers exactly:

- one dynamic plus one concrete static transaction for write demux, read
  demux, scalar read-data, burst-length/runtime validation, and multi-beat
  output banks; and
- one dynamic plus two concrete static transactions for write demux, read
  demux, scalar read-data, burst-length/runtime validation, and multi-beat
  output banks.

That is a complete bounded ladder for the selected one-dynamic mixed shape,
but it is not yet a general mixed-cardinality contract. The next nearest
roadmap-aligned question is whether FSMGen should widen from "one dynamic
plus one or two static" to shapes such as two dynamic plus one static, one
dynamic plus three static, or bounded dynamic-plus-static sets with explicit
caps.

## Why This Comes Before Other Residue

Same-cycle request widening, release-and-recapture, dynamic same-ID queues,
scoreboards, direct backend behavior, backend-language variants, and VHDL are
still important, but they are broader cross-cutting topics. Broader
mixed-cardinality readiness is local to the already active response-demux and
read-data machinery, and it can decide whether existing transaction-list
helpers are genuinely ready or whether a public contract-selection slice is
needed first.

The audit must not assume direct implementation. It must decide whether the
next owner should be:

- a direct bounded implementation for one clearly selected broader shape;
- a public contract-selection leaf that names the first broader mixed source
  shape and report vocabulary;
- a helper/report cleanup prerequisite; or
- deferral in favor of same-cycle, queue, scoreboard, backend, or VHDL work.

## Candidate Public Shapes

The audit should evaluate these source/report candidates without committing to
one before reading the code:

- two dynamic read transactions plus one concrete static read transaction;
- one dynamic read transaction plus three concrete static read transactions;
- a capped "at least one dynamic and at least one static" mixed set where all
  concrete static IDs are pairwise distinct and all dynamic transactions use
  generated captured IDs; and
- whether write demux must widen first, or whether read response-demux,
  scalar read-data, burst-length/runtime validation, and multi-beat behavior
  can widen independently.

Possible future sample stems include:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat.ppif
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_multi_static_burst_last_read_data_multi_beat.ppif
```

Those are audit candidates only. `.315` adds no public sample and changes no
parser, generator, support-accounting, validation, schedule/check/semantic
JSON, generated artifact, test, or HDL behavior.

## Validation Plan For `.316`

The readiness audit should read the current mixed response-demux/read-data
coverage helpers, dynamic/static transaction classification, generated rule
and report builders, focused t/1438 assertions, support-accounting costs, and
host-memory caveats. It should also compare the existing all-dynamic
multi-transaction path with the one-dynamic plus two-static mixed path before
choosing direct implementation or contract selection.

Expected `.316` closeout gates are documentation-only gates: Knowledge Map
generation/check, mdBook build, memory architecture check, diff hygiene, and
doctrine checks. No behavior should change in `.316`.

## Explicit Residue

Until `.316` decides otherwise, broader mixed dynamic/static cardinalities
remain fail-closed. Same-cycle request widening, release-and-recapture,
dynamic same-ID queues, scoreboards, direct backend behavior,
backend-language variants, VHDL, profile aliases, queued/blocking policy, and
full-manager behavior remain separate exact owners.

## Rollback

Rollback is documentation-only: remove this selector note, remove its
Knowledge Map fact card, restore `.315` to pending, and restore Memory,
README, ROADMAP_V2, mdBook, and task-tree frontier pointers to the
post-`.314` state.
