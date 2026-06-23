# AXI IAL2 Manager Multiple Mixed Dynamic/Static Response-Demux Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.293`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.294`, public contract selection
for bounded multiple mixed dynamic/static write `BID` response-demux.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or used:

- `.292` post mixed dynamic/static multi-beat selector:
  `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_MULTI_BEAT_NEXT_SLICE_SELECTION.md`
- `.291` mixed dynamic/static multi-beat behavior:
  `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md`
- `.290` mixed dynamic/static multi-beat readiness audit.
- `.289` mixed dynamic/static runtime beat-count/`RLAST` behavior.
- `.287` mixed dynamic/static report-only raw-`ARLEN` behavior.
- `.284` mixed dynamic/static scalar read-data behavior.
- `.280` and `.276` mixed dynamic/static read response-demux behavior.
- `.272` mixed dynamic/static write response-demux behavior.
- `.268` multiple dynamic multi-beat behavior and the preceding multiple
  dynamic write/read/read-data/burst-length/runtime ladder.
- `.207` mixed auto-ID plus concrete queue-head multi-beat behavior and
  `.202` mixed auto-ID plus concrete queue-head runtime-validation behavior.
- Current mixed dynamic/static write/read plan builders, selected-ID and
  busy-state helpers, static concrete-ID reservation reports, generated
  completion signal maps, onehot0 request policies, assertion spec helpers,
  support/residue/report wording, support accounting, focused validation
  surfaces, README, `ROADMAP_V2.md`, mdBook, task tree, Memory, and Knowledge
  Map.

## Current Boundary

The one-dynamic plus one-concrete-static mixed dynamic/static path now covers
the local ladder through generated multi-beat output banks:

- write `BID` response-demux;
- read single-beat `RID` response-demux;
- read burst-last `RID && RLAST` response-demux;
- scalar read-data;
- report-only raw-`ARLEN` capture;
- runtime beat-count/`RLAST` validation; and
- multi-beat output banks.

The implementation is deliberately hard-bounded at exactly one dynamic
transaction and exactly one concrete static transaction. The mixed write and
read plan builders both confess on any wider selected family before report or
lowering behavior can run.

A temporary `/tmp` read-demux candidate with one dynamic read transaction and
two concrete static read transactions failed closed under a RAM-guarded
strict check with:

```text
AXI manager capacity/status IAL2 contract response_demux.read mixed dynamic/static ID matching supports exactly one dynamic read transaction and one concrete static read transaction in this slice
```

The current read-data coverage branch also requires exactly one dynamic read
transaction and one concrete static read transaction before it will route
scalar, burst-length/runtime, or multi-beat read-data over generated mixed
dynamic/static read response-demux.

## Readiness Findings

The lower substrate is ready for a contract-selection slice, but not for a
direct behavior implementation.

The assertion generator for mixed dynamic/static response-demux is already
list-shaped. It iterates over all dynamic and static state records for
request-not-busy assertions, onehot0 request policy, dynamic-vs-static ID
exclusion assertions, active response match assertions, pairwise raw-response
unique-match assertions, and completion-active release assertions. That
suggests the later implementation is localized around plan construction,
report vocabulary, diagnostics, public samples, and tests.

The plan builders are not yet list-shaped for mixed dynamic/static families.
They build a single dynamic state, a single static state, a singular
`static_id_reservation` object, singular mixed transaction report fields, and
dynamic capture guards that exclude exactly one static concrete ID. A
multiple mixed behavior needs a public contract for:

- whether the first bounded shape is one dynamic plus multiple static
  transactions, multiple dynamic plus one static transaction, or another
  minimal mixed family;
- how static concrete-ID reservation lists are represented;
- how every dynamic capture excludes every selected static concrete ID;
- whether static concrete IDs must be pairwise unique in the selected family;
- whether the current onehot0 request policy remains the first safe policy
  across all selected dynamic and static transactions; and
- how generated completion signals and report fields are named for multiple
  mixed dynamic/static transactions.

## Selected First Family

The first widened multiple mixed dynamic/static owner should be write `BID`
response-demux, not read response-demux or read-data behavior.

Write `BID` response-demux is the smallest surface that exercises the
cardinality-widened ownership problem. It needs no `RLAST`, raw
matched-read-beat accounting, burst-length metadata, runtime beat-count
validation, scalar read-data capture, or multi-beat output-bank rules. It can
settle static-ID reservation lists, dynamic capture exclusion, onehot0
request policy, raw `BID` ownership, generated completion signals, report
vocabulary, diagnostics, and support-accounting shape before the read and
read-data ladder reuse that contract.

Read single-beat, read burst-last/`RLAST`, scalar read-data,
burst-length/runtime validation, multi-beat output banks, same-cycle request
widening, release-and-recapture, dynamic same-ID queues, scoreboards, direct
backend behavior, backend-language variants, and VHDL remain later exact
owners.

## Selected .294 Boundary

`.294` should select only the public contract for bounded multiple mixed
dynamic/static write `BID` response-demux. It should decide and record:

- the first bounded transaction cardinality, with a bias toward one dynamic
  write transaction plus two concrete static write transactions unless the
  contract selection finds a smaller prerequisite;
- the public PPIF sample stem and support-accounting identity;
- whether existing `response-demux.write` syntax is reused unchanged;
- report mode names and whether `mixed_transactions` and
  `static_id_reservation` become list-shaped fields or gain sibling list
  fields while preserving the existing one-plus-one report contract;
- dynamic capture exclusion against all selected static concrete IDs;
- static concrete-ID uniqueness diagnostics;
- onehot0 same-cycle request policy across all selected mixed write
  transactions;
- raw `BID` active-match and pairwise unique-match assertion names;
- generated completion signal ordering and transaction state report ordering;
- focused diagnostics for unsupported auto-ID, same-ID ordering, read-family,
  partial transaction coverage, duplicate static IDs, missing dynamic or
  static transactions, same-cycle widening, release-and-recapture, queues,
  scoreboards, direct backend, backend-language variants, and VHDL;
- validation gates, rollback, docs, mdBook, and Knowledge Map impact; and
- explicit residue for read-side multiple mixed demux, read-data,
  burst-length/runtime validation, multi-beat output banks, same-cycle
  widening, release-and-recapture, dynamic same-ID queues, scoreboards,
  direct backend behavior, backend-language variants, and VHDL.

`.294` should not implement parser, generator, sample, support-accounting,
test, JSON, generated artifact, or HDL behavior. It should only select the
future public contract so a later implementation owner can change behavior
with one unambiguous ownership model.

## Explicit Non-Goals

`.293` changes no behavior.

`.294` should not implement multiple mixed dynamic/static response-demux. It
should not widen read response-demux, `RLAST`, read-data, burst-length/runtime
validation, multi-beat output banks, same-cycle request policy,
release-and-recapture, dynamic same-ID queues, scoreboards, direct backend
behavior, backend-language variants, or VHDL.

## Validation

Audit validation covers live docs, mdBook, Memory, Knowledge Map, diff
hygiene, and doctrine gates. The temporary RAM-guarded candidate confirmed
the current fail-closed diagnostic for one dynamic plus two concrete static
read transactions. No behavior changed.

## Rollback

Rollback is the `.293` audit commit. Reverting it restores `.293` as the
active multiple mixed dynamic/static readiness-audit owner and removes the
`.294` contract-selection handoff.
