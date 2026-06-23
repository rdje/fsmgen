# AXI IAL2 Manager Post Mixed Dynamic/Static Multi-Beat Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.292`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.293`, readiness audit for
multiple mixed dynamic/static transaction cardinality after generated mixed
dynamic/static multi-beat read-data output banks.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The selector read or used:

- `.291` mixed dynamic/static multi-beat behavior:
  `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md`
- `.290` mixed dynamic/static multi-beat readiness audit.
- `.289` mixed dynamic/static runtime beat-count/`RLAST` behavior.
- `.287` mixed dynamic/static report-only raw-`ARLEN` behavior.
- `.284` mixed dynamic/static scalar read-data behavior.
- `.280` mixed dynamic/static read burst-last `RID && RLAST`
  response-demux behavior.
- `.276` mixed dynamic/static read single-beat `RID` response-demux behavior.
- `.272` mixed dynamic/static write `BID` response-demux behavior.
- `.268` multiple dynamic multi-beat behavior and the preceding multiple
  dynamic write/read/read-data/burst-length/runtime ladder.
- `.207` mixed auto-ID plus concrete queue-head multi-beat behavior and
  `.202` mixed auto-ID plus concrete queue-head runtime-validation behavior.
- Current support, residue, and report wording in
  `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`.
- README, `ROADMAP_V2.md`, mdBook, task tree, Memory, and Knowledge Map state.

## Rationale

The one-dynamic plus one-concrete-static mixed dynamic/static path is now
covered through the local SystemVerilog-backed ladder: write `BID`
response-demux, read single-beat `RID` response-demux, read burst-last
`RID && RLAST` response-demux, scalar read-data, report-only raw-`ARLEN`
capture, runtime beat-count/`RLAST` validation, and multi-beat output banks.

The next local feature-completeness gap is not direct backend behavior,
backend-language variants, or VHDL. Those lanes still depend on the
SystemVerilog-backed IAL path having a settled source/report contract for the
remaining dynamic ownership shapes.

The next local gap is also narrower than scoreboards or dynamic same-ID
queues. Those behaviors need a settled answer for how a family with more than
one dynamic and/or more than one concrete static transaction reserves static
IDs, excludes those IDs from dynamic capture, reports ownership, and proves
that one raw response cannot complete multiple transactions.

The existing multiple all-dynamic path proves that transaction-list-driven
generation can scale beyond one transaction. The mixed auto-ID plus concrete
queue-head path proves that heterogeneous ownership forms can share the
read-data, burst-length, runtime, and output-bank machinery when the response
ownership contract is explicit. The mixed dynamic/static path now proves the
one-dynamic plus one-static substrate. What remains is the bounded
cardinality-widening decision for mixed dynamic/static transactions.

That widening should be audited before implementation because it touches the
fail-closed coverage predicates that currently require exactly one dynamic and
exactly one concrete static transaction, the static-ID reservation set, the
dynamic capture exclusion policy, the generated completion signal lists, the
onehot0 same-cycle request policy across more than two selected
transactions, report vocabulary, support accounting, and focused validation
cost.

## Selected .293 Boundary

`.293` should audit only multiple mixed dynamic/static transaction
cardinality after the `.291` multi-beat boundary. It should decide:

- whether the next behavior owner should begin with write `BID`
  response-demux, read single-beat `RID` response-demux, read burst-last
  `RID && RLAST` response-demux, scalar read-data, burst-length/runtime,
  multi-beat output banks, or a smaller public contract/report cleanup
  prerequisite;
- what bounded transaction set should be first, such as one dynamic plus two
  concrete static transactions, two dynamic plus one concrete static
  transaction, or another minimal mixed family;
- how static concrete-ID reservation lists are represented and how dynamic
  capture excludes every selected static concrete ID;
- whether the current onehot0 same-cycle mixed request policy remains the
  first safe policy across more than two transactions;
- what generated assertions are needed for static-ID uniqueness, dynamic
  exclusion, active response match, unique raw-response ownership, and
  completion-active release;
- expected report mode names, residue movement, public sample names,
  support-accounting entries, focused tests, direct probe gates, rollback,
  docs, and Knowledge Map impact; and
- explicit residue for same-cycle request widening beyond onehot0,
  same-cycle release-and-recapture, dynamic same-ID queues, scoreboards,
  direct backend behavior, backend-language variants, and VHDL.

No parser, generator, PPIF sample, support-accounting catalog, validation
behavior, generated artifact, test, schedule/check/semantic JSON, or HDL
behavior should change in `.293` unless that audit first records a later
behavior owner.

## Explicit Non-Goals

`.292` changes no behavior.

`.293` should not implement multiple mixed dynamic/static transactions,
same-cycle request widening, release-and-recapture, dynamic same-ID queues,
scoreboards, direct backend behavior, backend-language variants, or VHDL. It
should only select the next owned boundary and record enough evidence for a
later safe contract-selection or implementation slice.

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
HDL probes are required because `.292` changes no behavior.

## Rollback

Rollback is the `.292` selector commit. Reverting it restores `.292` as the
active selector after `.291` and removes the `.293` readiness-audit owner.
