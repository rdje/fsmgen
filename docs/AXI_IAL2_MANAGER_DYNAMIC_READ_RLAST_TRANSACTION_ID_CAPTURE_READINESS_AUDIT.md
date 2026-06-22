# AXI IAL2 Manager Dynamic Read RLAST Transaction-ID Capture Readiness Audit

Status: readiness audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.229` on
2026-06-22.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.229`

## Conclusion

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.230`, public contract selection for
bounded dynamic read burst-last/`RLAST` transaction-ID capture and response
matching.

Do not implement generated dynamic read burst-last behavior directly in `.229`.
The generated single-beat dynamic read path proves admitted `ARID` capture,
single-active selected-ID/busy state, `RID` matching, generated completion,
busy release, runtime assertions, and report projection. The non-dynamic
burst-last path proves `response-demux.read` can own `response-scope
burst-last`, one-bit `last_signal`, raw accepted read response beats, and
matched `RID && RLAST` completion.

The missing piece is the public dynamic contract that joins those two shipped
surfaces. That contract must be selected before parser, generator, PPIF sample,
support-accounting, validation, generated artifact, test, or HDL behavior
changes.

## Evidence Read

The audit read:

- `.228` post-dynamic-read-ID selector.
- `.227` dynamic read single-beat behavior, `.226` contract selection, and
  `.225` readiness audit.
- `.223` dynamic write behavior and `.219` dynamic transaction-ID metadata
  behavior.
- Non-dynamic read burst-last/`RLAST` contract, metadata, behavior, read-data,
  burst-length, runtime-validation, and multi-beat output-bank records.
- Support-accounted dynamic read/write samples and the support-accounted
  non-dynamic burst-last response-demux sample.
- Current `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus` dynamic
  transaction selection, read response-demux normalization, response-demux
  match/assertion helpers, read-data helpers, support detail, and report
  projection.
- Focused live probes for:
  - `ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif`
    schedule JSON and strict check JSON.
  - `ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`
    schedule JSON and strict check JSON.
- README, `ROADMAP_V2.md`, mdBook backlog, task tree, Memory, and Knowledge
  Map fact cards.

## Current Substrate

The dynamic read single-beat path currently reports:

```text
mode: bounded_dynamic_read_rid_demux_contract
response_event_role: raw_accepted_read_response
response_scope: single_beat
transaction_completion_semantics: matched_dynamic_id_single_beat
dynamic_capture.ownership: single_active_dynamic_read
```

It captures the read request-ID source at the admitted request point, stores it
in generated selected-ID state, keeps a single-active busy bit, matches raw
read responses with `RID == captured_id`, pulses the generated transaction
completion, releases busy from that pulse, and emits read-specific dynamic
assertions.

The non-dynamic burst-last path currently reports:

```text
response_event_role: raw_accepted_read_response_beat
response_scope: burst_last
last_signal: axi0_rlast
transaction_completion_semantics: matched_rid_and_last_signal
burst_length_source: rlast_only
burst_length_validation: not_generated
```

The shared render helper already allows a response-demux state match to include
`last_signal` when that field is present. The assertion helper can build
dynamic-family assertions for dynamic response-demux states. That means no
lower IAL1/IAL0/SystemVerilog storage, rule, pulse, or assertion prerequisite
is evident for the narrow one-dynamic-read burst-last shape after contract
selection.

## Why Contract Selection Comes First

Dynamic read burst-last is not a pure mechanical flip from `single_beat` to
`burst_last`. The next owner must select:

- whether the public syntax reuses `response-demux.read` with
  `response-scope burst-last` and `last-signal`, or introduces a dynamic-only
  spelling;
- whether `response-event` remains the raw accepted read response beat and the
  generated transaction completion is exactly matched captured dynamic ID plus
  asserted `last_signal`;
- whether matched non-last beats only prove activity and keep busy asserted,
  without generating completion or release;
- whether the report should extend `bounded_dynamic_read_rid_demux_contract`
  or introduce a distinct dynamic burst-last mode such as
  `bounded_dynamic_read_rid_rlast_demux_contract`;
- how dynamic assertions should describe raw response beats while inactive or
  mismatched, generated completion while inactive, and non-last beats that
  must not complete;
- how the existing single-beat dynamic read residue narrows while read-data
  routing, burst-length capture, beat-count/runtime validation, and multi-beat
  output banks remain future work.

Current code intentionally fails closed when a dynamic read response-demux uses
`response-scope burst-last`. That fail-closed boundary is correct until `.230`
settles the public contract.

## Expected Boundary For `.230`

`.230` should select the exact public contract for one bounded dynamic read
burst-last response-demux shape. The likely shape reuses existing syntax:

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
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))
```

The selector must choose the final syntax and report vocabulary, and must
define:

- one transaction-local dynamic read ID in the selected read family;
- no new `auto-id-lifecycle` or dynamic-ID lifecycle clause for the first
  shape;
- admitted read request-ID capture from the family request-ID source;
- single-active selected-ID/busy ownership across all accepted response beats
  until a matched last beat completes;
- raw response event, `RID`, and `RLAST` completion semantics;
- generated completion and busy release timing;
- last-signal input ownership and width validation;
- diagnostics for unsupported combinations;
- generated `.isf`, `.fsm`, and SystemVerilog artifact boundaries for the
  later implementation owner;
- report keys, generated artifact lists, residue, docs, Knowledge Map, and
  rollback.

## Explicit Residue

The `.230` selector must keep these out of scope unless it explicitly creates
later owners:

- dynamic read-data routing over captured dynamic IDs;
- burst-length `ARLEN` capture and beat-count state over dynamic IDs;
- runtime missing/extra/early `RLAST` validation over dynamic IDs;
- multi-beat output banks and packed burst-vector outputs over dynamic IDs;
- multiple dynamic read transactions;
- mixed dynamic/static read response-demux;
- same-cycle release and recapture;
- dynamic same-ID ordering, per-ID queues, scoreboards, and generalized
  arbitration;
- direct backend behavior, HDL shapes outside the selected SystemVerilog path,
  and VHDL.

## Validation

Closeout validation for this audit is documentation and continuity focused:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
scripts/check_doctrines.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

The audit also used read-only focused probes:

```bash
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif
```

Any later behavior owner must add focused generator/PPIF tests,
support-accounting updates, schedule/check/semantic JSON probes, generated
artifact checks, default SystemVerilog reachability, and HDL evidence for the
selected public sample.

## Rollback

Rollback for `.229` is limited to this audit record, task-tree frontier
movement, README, `ROADMAP_V2.md`, mdBook, Memory, and Knowledge Map updates.
No parser, generator, public sample, support-accounting catalog, generated
artifact, test, validation, or HDL behavior is part of this slice.
