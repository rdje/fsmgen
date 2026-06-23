# AXI IAL2 Manager Mixed Dynamic/Static Response-Demux Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.270`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.271`, public contract selection
for bounded mixed dynamic/static write `BID` response-demux.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or used:

- `.269` post multiple dynamic multi-beat selector:
  `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_MULTI_BEAT_NEXT_SLICE_SELECTION.md`
- `.268` multiple dynamic multi-beat behavior:
  `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_BEHAVIOR.md`
- `.267` multiple dynamic multi-beat contract selection.
- `.264` multiple dynamic runtime validation behavior.
- `.259` multiple dynamic scalar read-data behavior.
- `.255` multiple dynamic read burst-last/`RLAST` response-demux behavior.
- `.251` multiple dynamic read single-beat response-demux behavior.
- `.247` multiple dynamic write response-demux behavior.
- `.245` multiple/mixed dynamic response-demux readiness precedent.
- Current mixed dynamic/static fail-closed diagnostics in
  `t/1437-axi-ial2-manager-capacity-status-generator.t`.
- Current response-demux dynamic/static state helpers, response match
  expressions, report/residue wording, and dynamic transaction-ID support
  text in `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`.
- Focused validation caveats, support-accounting catalog, README,
  `ROADMAP_V2.md`, mdBook, task tree, Memory, and Knowledge Map.

## Current Boundary

The all-dynamic multiple dynamic path now covers:

- bounded multiple dynamic write `BID` response-demux;
- bounded multiple dynamic read single-beat `RID` response-demux;
- bounded multiple dynamic read burst-last `RID && RLAST` response-demux;
- scalar read-data over generated multiple dynamic read response-demux;
- report-only raw-`ARLEN` capture over that read-data shape;
- runtime beat-count/`RLAST` validation over that read-data shape; and
- multi-beat output banks over generated multiple dynamic read runtime
  validation.

Mixed dynamic/static response-demux is still intentionally fail-closed. The
dynamic write normalizer rejects a selected write family unless every write
transaction uses dynamic IDs. The dynamic read normalizer has the same
all-dynamic requirement for selected read transactions. Focused generator
coverage locks both diagnostics:

```text
response_demux.write dynamic ID matching requires every write transaction to use dynamic IDs
response_demux.read dynamic ID matching requires every read transaction to use dynamic IDs
```

The support-detail prose also states that dynamic transaction IDs fail closed
with mixed dynamic/static `response_demux` until those shapes are explicitly
owned.

## Readiness Findings

The lower substrate is close enough to justify a contract-selection slice, but
not direct implementation.

Dynamic response-demux state is already list-shaped for all-dynamic families:
per-transaction selected-ID/busy storage, capture/release rules, request
onehot0 policy, active dynamic-ID uniqueness, active-match, unique-match, and
completion-active assertions are generated for selected all-dynamic shapes.

Static and concrete response-demux behavior already has separate concrete-ID
and queue-head ownership paths. However, those paths are not merged with
dynamic selected-ID state today. If a mixed family were admitted without a
contract, one raw response could match a static concrete transaction and an
active dynamic transaction whose captured ID equals that concrete ID.

The current all-dynamic dynamic capture guard prevents same-cycle sibling
dynamic requests and active sibling dynamic same-ID collisions. It does not
define static concrete-ID collision policy, static-vs-dynamic same-cycle
request ordering, or whether a dynamic transaction may capture an ID equal to
any static selected transaction in the same family.

## Selected First Family

The first safe mixed dynamic/static owner should be write `BID`
response-demux, not read response-demux or read-data behavior.

Write `BID` response-demux is the smallest family because it does not need
`RLAST`, raw matched-read-beat accounting, burst-length capture, runtime
beat-count validation, or read-data output-bank rules. The contract can focus
on response ownership for one raw `BID` transfer, generated completion
pulses, static/dynamic ID collision policy, diagnostics, and report
vocabulary.

Read single-beat, read burst-last/`RLAST`, scalar read-data, burst-length,
runtime validation, multi-beat output banks, same-cycle widening,
release-and-recapture, dynamic same-ID queues, and scoreboards remain later
owners.

## Selected .271 Boundary

`.271` should select only the public contract for bounded mixed
dynamic/static write `BID` response-demux. It should decide and record:

- the exact public source shape and sample/support-accounting stem;
- whether the first shape requires at least one dynamic write transaction and
  at least one static concrete-ID write transaction in the selected write
  family;
- whether existing `response-demux.write` syntax is reused unchanged or needs
  a report-only contract note before behavior changes;
- how dynamic captured IDs are prevented from colliding with active/static
  concrete write IDs;
- same-cycle dynamic/static request policy;
- release timing and whether same-cycle release-and-recapture stays deferred;
- response ownership when a raw `BID` could otherwise match both static and
  dynamic state;
- generated assertion and report vocabulary, including a future mode name;
- focused diagnostics for unsupported auto-ID, same-ID ordering, read-family,
  burst/read-data, and partial transaction coverage cases;
- validation gates, rollback, docs, mdBook, and Knowledge Map impact; and
- explicit residue for read-side mixed demux, read-data, burst-length,
  runtime validation, multi-beat output banks, same-cycle widening,
  release-and-recapture, dynamic same-ID queues, scoreboards, direct backend,
  backend-language variants, and VHDL.

`.271` should not implement parser, generator, sample, support-accounting,
test, JSON, generated artifact, or HDL behavior. It should only select the
future public contract so the implementation owner can change behavior with a
single unambiguous ownership model.

## Explicit Non-Goals

`.270` changes no behavior.

`.271` should not implement mixed dynamic/static demux. It should not widen
read response-demux, `RLAST`, read-data, burst-length/runtime validation,
multi-beat output banks, same-cycle request policy, release-and-recapture,
dynamic same-ID queues, scoreboards, direct backend behavior,
backend-language variants, or VHDL.

## Validation

Audit validation covers live docs, mdBook, Memory, Knowledge Map, diff
hygiene, and doctrine gates. No behavior changed.

## Rollback

Rollback is the `.270` audit commit. Reverting it restores `.270` as the
active mixed dynamic/static readiness-audit owner and removes the `.271`
contract-selection handoff.
