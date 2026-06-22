# AXI IAL2 Manager Dynamic Read Transaction-ID Capture/Matching Readiness Audit

Status: readiness audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.225` on
2026-06-22.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.225`

## Conclusion

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.226`, public contract selection for
bounded single-beat dynamic read transaction-ID capture and `RID` response
matching.

Do not implement generated dynamic read response matching directly in `.225`.
The existing IAL1/IAL0/SystemVerilog substrate can carry the narrow
single-active read shape after a public contract is selected, but the read
surface still needs an explicit contract for response scope, generated
completion ownership, `RID` matching, report vocabulary, assertions, and
which read-data or burst behavior stays residue.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation, generated artifact, test, or HDL behavior.

## Evidence Read

The audit read:

- `.224` post-dynamic-write selector:
  `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_ID_NEXT_SLICE_SELECTION.md`.
- `.223` dynamic write behavior, `.222` dynamic write contract selection, and
  `.219` dynamic transaction-ID metadata behavior.
- Existing generated read response-demux single-beat and burst-last behavior
  docs, including `.37` through `.41` for single-beat `RID` demux and `.49`
  through `.53` for `RLAST` last-beat completion.
- Read-data capture, burst-length, runtime-validation, and multi-beat
  output-bank docs and live schedule reports for representative samples.
- Current PPIF dynamic metadata sample and generated dynamic write sample
  reports.
- `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus` dynamic ID rejection
  guard, dynamic write normalizer, response-demux read normalizer, dynamic
  storage/rule rendering helpers, response-demux assertion helpers,
  read-data coverage helpers, support-detail text, and report projection.
- README, `ROADMAP_V2.md`, mdBook backlog, task tree, Memory, and Knowledge
  Map fact cards.

Useful live probes:

```bash
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_transaction_id.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif
```

## Current Substrate

The generated response-demux renderer is already close to the needed dynamic
read shape. It can emit:

- width-bearing generated request/response ID inputs;
- generated selected-ID and busy storage;
- generated capture and release rules for dynamic transaction states;
- response-demux pulse rules guarded by response event, active busy state,
  response-ID equality, and optional `last_signal`;
- one-cycle generated completion outputs;
- response-demux assertions through the existing assertion carrier path.

The shipped read response-demux behavior already proves the read-side match
shape for generated auto-ID transactions:

```text
read_response_event && read_busy && RID == selected_read_id
```

The shipped dynamic write behavior proves the admitted-request capture shape
for a user-supplied request ID:

```text
admitted_request && !dynamic_busy
```

The first dynamic read implementation can combine those pieces for a bounded
single-beat shape after the public contract is explicit.

## Why Contract Selection Comes First

Dynamic read response matching is not a direct write mirror.

Write response matching has one response packet, `BID`, and one completion
event. Read response matching must state whether a raw read response beat is:

- a single-beat/non-burst transaction completion;
- a burst last-beat completion gated by `RLAST`;
- a beat-valid signal that later read-data or beat-count logic consumes.

The current public dynamic metadata boundary still reports read dynamic IDs as
`implementation_status: selected_not_generated`, and the generator still
fails closed when `response-demux.read` is combined with same-family dynamic
read IDs. That fail-closed state is honest and should remain until a dedicated
contract selector records the first supported read scope.

## Selected First Scope For `.226`

`.226` should select the public contract for the first bounded dynamic read
response-demux shape, using `response-scope single-beat` as the first scope.

The selected first shape should be analogous to the shipped generated
single-beat read `RID` demux, but with dynamic/user-supplied request-ID
capture:

```lisp
(transactions
  (read r0
    (tag rd0)
    (request axi0_r0_request)
    (completion axi0_r0_complete)
    (id dynamic)))

(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))
```

The single-beat choice is the narrowest honest read contract because:

- it avoids `RLAST` semantics in the first dynamic read slice;
- it does not require burst length, beat-count, missing/extra-beat, or
  last-beat validation policy;
- it avoids read-data payload capture and multi-beat output-bank ownership;
- it reuses an already-shipped public read response-demux scope and report
  vocabulary;
- it keeps dynamic read behavior symmetric with `.223` at the capture and
  response-ID match layer without claiming burst or payload behavior.

## Expected Contract Boundary For `.226`

`.226` should define:

- reuse of existing `response-demux.read` with one transaction-local dynamic
  read ID;
- no new dynamic-ID lifecycle clause;
- exactly one dynamic read transaction in the selected read family for the
  first generated behavior;
- positive-width read `id-families.read` metadata with request ID source such
  as `ARID` and response ID signal such as `RID`;
- admitted-request capture of the read request-ID source;
- single-active dynamic read ownership with generated selected-ID and busy
  storage;
- raw accepted read response event plus `RID == captured_id` as the
  single-beat completion condition;
- generated transaction completion pulse and busy release from that pulse;
- runtime assertions for request while busy, response while inactive or
  mismatched, and completion while inactive;
- report vocabulary parallel to `bounded_dynamic_write_bid_demux_contract`,
  with read-specific names such as
  `bounded_dynamic_read_rid_demux_contract`.

## Explicit Residue

The contract selected by `.226` must keep these out of scope unless it
explicitly creates later owners:

- dynamic read `response-scope burst-last`;
- `RLAST` input, last-beat completion, and early/late `RLAST` diagnostics;
- read-data capture over dynamic IDs;
- burst-length capture, beat-count state, runtime-validation assertions, and
  multi-beat output-bank behavior over dynamic IDs;
- multiple dynamic read transactions;
- mixed dynamic/static read response demux;
- same-cycle release and recapture;
- dynamic same-ID ordering, per-ID queues, scoreboards, and generalized
  arbitration;
- full manager behavior, direct backend behavior, HDL shapes outside the
  selected SystemVerilog path, and VHDL.

## Validation Gates

For `.225`, documentation and continuity gates are sufficient:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
scripts/check_doctrines.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

For `.226`, documentation and continuity gates are still sufficient if it is
selector-only. Any later behavior owner must add focused parser/generator
tests, support accounting, schedule/check/semantic JSON probes, generated
artifact checks, and HDL reachability for the selected public sample.

## Rollback Boundary

Rollback for `.225` is limited to this audit record, task-tree frontier
movement, Memory, README, roadmap, mdBook, and Knowledge Map/fact-card
updates. No parser, generator, public sample, support-accounting catalog,
generated artifact, test, validation, or HDL behavior is part of this slice.
