# AXI Dynamic Identity Backlog

Dynamic same-ID issue-order readiness audit:
[AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_READINESS_AUDIT.md)
selects `.217`, public dynamic/user transaction-ID contract selection before
generalized per-ID issue-order queues. The audit found no cleanup or
lower-layer prerequisite: bounded concrete queue-head behavior is generated
over static concrete ID values and transaction inventory, while PPIF
transaction IDs currently accept only `auto` or concrete `(value N)`.
Dynamic transaction-ID contract selection:
[AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_CONTRACT_SELECTION.md)
selects transaction-local `(id dynamic)` and `.218`, metadata-first dynamic
transaction-ID parser/report readiness. The selected dynamic ID source is the
family request-ID signal declared in `id-families` at the transaction's
admitted request point; dynamic capture, response matching, same-ID policy,
queues, scoreboards, support accounting, generated artifacts, validation,
tests, and HDL remain deferred.
Dynamic transaction-ID metadata readiness audit:
[AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_READINESS_AUDIT.md)
selects `.219`, direct metadata-first `(id dynamic)` parser/report
implementation. The implementation boundary is metadata-only: accept exactly
transaction-local `(id dynamic)`, require a positive-width `id-families`
request/response signal contract, report user-supplied selected-not-generated
dynamic metadata, add a support-accounted metadata-only PPIF sample, and fail
closed for behavior clauses that would require dynamic capture, response
matching, queues, scoreboards, read-data routing, or HDL behavior.
Dynamic transaction-ID metadata behavior:
[AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_BEHAVIOR.md)
ships `.219`. Public `.ppif` now accepts `(id dynamic)` for read and write
transactions when the matching positive-width ID family declares request and
response ID signals. Schedule reports emit `policy: dynamic`, `family`,
`family_width`, `request_id_source`, `response_id_signal`, `ownership:
user_supplied`, and `implementation_status: selected_not_generated`. The
support-accounted sample is
`ppif/axi_manager_capacity_status_dynamic_transaction_id.ppif`. Dynamic ID
capture, response matching, same-ID ordering, read-data routing, queues,
scoreboards, direct backend behavior, HDL behavior, and VHDL remain backlog
under the explicit `dynamic_transaction_id_behavior` residue.

Post dynamic transaction-ID metadata selector:
[AXI_IAL2_MANAGER_POST_DYNAMIC_TRANSACTION_ID_METADATA_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_DYNAMIC_TRANSACTION_ID_METADATA_NEXT_SLICE_SELECTION.md)
selects `.221`, readiness audit for generated dynamic transaction-ID capture
and response matching. The next audit must decide capture timing at the
admitted request point, outstanding-state lifetime, response-match and
completion semantics, first bounded read or write shape, generated artifact
boundaries, diagnostics, validation, rollback, and residue before any parser,
generator, PPIF sample, support-accounting, test, generated HDL, or runtime
behavior changes.

Dynamic transaction-ID capture/matching readiness audit:
[AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_CAPTURE_MATCHING_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_CAPTURE_MATCHING_READINESS_AUDIT.md)
selects `.222`, public contract selection for bounded dynamic write
transaction-ID capture and `BID` response matching. The audit found the lower
substrate can likely carry selected-ID storage, busy state, response-ID
equality, completion pulses, and active/unique assertions, but the public
contract must first define admitted-request capture timing, single-active
dynamic ownership, stored-ID lifetime, matched-response completion/release
semantics, diagnostics/assertions, report vocabulary, validation, rollback,
and residue.

Dynamic write transaction-ID capture contract selection:
[AXI_IAL2_MANAGER_DYNAMIC_WRITE_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_DYNAMIC_WRITE_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION.md)
selects `.223`, direct generated bounded dynamic write transaction-ID capture
and `BID` response matching. The public contract reuses existing
`response-demux.write` with one transaction-local dynamic write ID, captures
the write request-ID source at the admitted request point, enforces
single-active selected-ID/busy ownership, matches `BID` against the captured
ID, generates the transaction completion pulse, and keeps dynamic read
matching, multiple dynamic write transactions, mixed dynamic/static write
demux, same-cycle recapture, same-ID ordering, read-data routing, queues,
scoreboards, direct backend behavior, and VHDL deferred at selection time.
Later dynamic leaves now ship selected single-active dynamic read matching,
selected dynamic read-data shapes, the single-active dynamic write same-cycle
release-and-recapture extension, the single-active dynamic read single-beat
same-cycle release-and-recapture extension, the all-dynamic multiple-write
response-demux shape, and the all-dynamic multiple-read single-beat
response-demux-only shape described below; mixed dynamic/static demux,
multiple dynamic read burst-last/read-data widening, same-cycle
widening/recapture, dynamic same-ID queues, scoreboards, direct backend
behavior, and VHDL remain deferred.

Dynamic write transaction-ID capture behavior:
[AXI_IAL2_MANAGER_DYNAMIC_WRITE_TRANSACTION_ID_CAPTURE_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_WRITE_TRANSACTION_ID_CAPTURE_BEHAVIOR.md)
ships `.223`. Explicit `response-demux.write` with exactly one
transaction-local dynamic write ID now generates `AWID` capture at the
admitted write request, generated selected-ID and busy state, a `BID` match
against the captured ID, the transaction completion pulse, busy release from
that pulse, runtime assertions, `bounded_dynamic_write_bid_demux_contract`
schedule-report keys, and the support-accounted sample
`ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif`.
Metadata-only dynamic IDs remain unchanged when no behavior clause consumes
them. This single-active write sample remains supported and `.365` extends it
with same-cycle release-and-recapture. Later dynamic leaves now ship selected
single-active dynamic read matching, selected dynamic read-data shapes, the
single-active dynamic read single-beat same-cycle release-and-recapture
extension, the single-active dynamic read burst-last same-cycle
release-and-recapture extension, the all-dynamic multiple-write response-demux
shape, and the all-dynamic multiple-read single-beat response-demux-only shape
described below; mixed dynamic/static demux, multiple dynamic read
burst-last/read-data widening, same-cycle recapture outside the selected
single-active dynamic write, read single-beat, and read burst-last boundaries,
dynamic same-ID queues, scoreboards, direct backend behavior, HDL shapes
outside the selected SystemVerilog path, and VHDL remain deferred.

Post dynamic write ID selector:
[AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_ID_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_ID_NEXT_SLICE_SELECTION.md)
selects `.225`, readiness audit for generated dynamic read transaction-ID
capture and `RID` response matching. The selector records that read response
scope, `RLAST`, read-data consumption, burst/runtime validation,
interleaving, assertions, and report vocabulary require an audit before any
parser, generator, PPIF sample, support-accounting, validation,
generated-artifact, test, or HDL behavior changes.

Dynamic read transaction-ID capture/matching readiness audit:
[AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_MATCHING_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_MATCHING_READINESS_AUDIT.md)
selects `.226`, public contract selection for bounded single-beat dynamic
read transaction-ID capture and `RID` response matching. The audit found the
existing response-demux substrate can likely carry selected-ID storage, busy
state, `RID` equality, completion pulses, release, and assertions, but the
public read contract must first settle admitted-request capture timing,
single-active ownership, single-beat completion/release semantics, diagnostics,
report keys, validation, rollback, and residue. Dynamic read burst-last,
`RLAST`, read-data routing, burst-length/runtime validation, interleaving,
multiple dynamic reads, mixed dynamic/static read demux, same-cycle recapture,
same-ID ordering, queues, scoreboards, direct backend behavior, and VHDL
remain deferred.

Dynamic read transaction-ID capture contract selection:
[AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION.md)
selects `.227`, direct generated behavior for bounded single-beat dynamic
read transaction-ID capture and `RID` response matching. The public contract
reuses existing `response-demux.read` with one transaction-local dynamic read
ID, `response-scope single-beat`, no `last_signal`, admitted read request-ID
capture, single-active selected-ID/busy ownership, raw accepted read response
plus `RID == captured_id` completion, generated busy release, read-specific
dynamic assertions, and `bounded_dynamic_read_rid_demux_contract` report
vocabulary. The burst-last/`RLAST` sibling now ships under `.231`; dynamic
read-data routing, burst-length/runtime validation, and the bounded multiple
dynamic read single-beat response-demux-only sibling now ship under later
leaves. Multiple dynamic read burst-last/read-data widening, mixed
dynamic/static read demux, same-cycle recapture, same-ID ordering, queues,
scoreboards, direct backend behavior, and VHDL remain deferred.

Dynamic read transaction-ID capture behavior:
[AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_BEHAVIOR.md)
ships `.227`, generated bounded single-beat dynamic read transaction-ID capture
and `RID` response matching. The support-accounted public sample is
`ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif`. It uses one
`(id dynamic)` read transaction plus explicit `response-demux.read` with
`response-scope single-beat` and generated transaction completion. FSMGen
captures admitted `ARID` into generated selected-ID storage, tracks a
single-active dynamic read busy bit, matches raw accepted read responses with
`RID == captured_id`, pulses `axi0_r0_complete`, releases busy from that pulse,
and reports `bounded_dynamic_read_rid_demux_contract` with
`capture_event_source: admitted_dynamic_read_request` and
`transaction_completion_semantics: matched_dynamic_id_single_beat`.

Post dynamic read ID selector:
[AXI_IAL2_MANAGER_POST_DYNAMIC_READ_ID_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_DYNAMIC_READ_ID_NEXT_SLICE_SELECTION.md)
selects `.229`, readiness audit for dynamic read burst-last/`RLAST`
transaction-ID capture and response matching. The selector keeps behavior
unchanged and records that the next audit must settle last-beat response scope,
`RLAST` signal ownership, selected-ID/busy lifetime, generated
completion/release semantics, assertions, report vocabulary, read-data and
burst/runtime interactions, validation, rollback, and explicit residue before
any parser, generator, PPIF sample, support-accounting catalog, generated
artifact, test, validation, or HDL behavior changes.

Dynamic read RLAST readiness audit:
[AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_READINESS_AUDIT.md)
selects `.230`, public contract selection for bounded dynamic read
burst-last/`RLAST` transaction-ID capture and response matching. The audit
keeps behavior unchanged: existing dynamic read support remains single-beat,
existing non-dynamic burst-last support remains generated, and dynamic
burst-last behavior waits for the public contract to settle last-signal
ownership, selected-ID/busy lifetime across non-last beats, raw response
`RID`/`RLAST` completion semantics, dynamic assertions, report vocabulary,
generated artifact boundaries, and read-data/burst/runtime residue.

Dynamic read RLAST contract selection:
[AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION.md)
selects `.231`, direct generated behavior for bounded dynamic read
burst-last/`RLAST` transaction-ID capture and response matching. The selected
public shape reuses existing `response-demux.read` with one transaction-local
dynamic read ID, `response-scope burst-last`, one-bit `last-signal`, admitted
`ARID` capture, single-active selected-ID/busy state across non-last beats, and
completion only on raw accepted read response beat plus `RID == captured_id`
plus asserted `RLAST`. Read-data routing, burst-length/runtime validation,
multi-beat outputs, multiple/mixed dynamic demux, same-ID ordering, queues,
scoreboards, direct backend behavior, and VHDL remain future exact-owner work.

Dynamic read RLAST behavior:
[AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_BEHAVIOR.md)
ships `.231`, generated bounded dynamic read burst-last/`RLAST`
transaction-ID capture and response matching. The support-accounted public
sample is
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_burst_last.ppif`.
It uses one `(id dynamic)` read transaction plus explicit
`response-demux.read` with `response-scope burst-last`, one-bit
`last-signal`, and generated transaction completion. FSMGen captures admitted
`ARID`, tracks generated selected-ID/busy state across non-last beats, pulses
`axi0_r0_complete` only on raw read response plus `RID == captured_id &&
RLAST`, releases busy from that completion, and reports
`bounded_dynamic_read_rid_rlast_demux_contract` with
`transaction_completion_semantics: matched_dynamic_id_and_last_signal`.

Post dynamic read RLAST selector:
[AXI_IAL2_MANAGER_POST_DYNAMIC_READ_RLAST_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_DYNAMIC_READ_RLAST_NEXT_SLICE_SELECTION.md)
selects `.233`, readiness audit for dynamic read-data routing over generated
single-active dynamic read response-demux. The selector keeps behavior
unchanged and records that the next audit must inspect single-beat versus
last-beat read-data scope, generated completion consumption, selected-ID/busy
interactions, data/status capture, report keys, diagnostics, public sample and
support-accounting boundaries, validation gates, rollback, docs, Knowledge Map,
and explicit residue. Dynamic read-data, burst-length/runtime validation,
multi-beat outputs, multiple/mixed dynamic demux, same-cycle recapture,
same-ID ordering, queues, scoreboards, direct backend behavior, and VHDL remain
deferred until exact owners select them.

Dynamic read-data readiness audit:
[AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_READINESS_AUDIT.md)
selects `.234`, direct bounded implementation of scalar dynamic read-data
capture over generated single-active dynamic read response-demux. The selected
behavior reuses existing `read-data.read` syntax, requires exactly one dynamic
read transaction covered by generated dynamic `response-demux.read`, and covers
only scalar `RDATA`/`RRESP` capture for `capture-scope single-beat` and
`capture-scope last-beat`. The generated dynamic completion pulse is the
capture guard. Dynamic `burst_length`, beat-count/runtime validation,
multi-beat output banks, multiple/mixed dynamic demux, same-cycle recapture,
dynamic same-ID ordering, queues, scoreboards, direct backend behavior, and
VHDL remain deferred.

Dynamic read-data behavior:
[AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md)
ships `.234`, bounded scalar dynamic read-data capture over generated
single-active dynamic read response-demux. The public samples are
`ppif/axi_manager_capacity_status_dynamic_read_data.ppif` and
`ppif/axi_manager_capacity_status_dynamic_read_data_last_beat.ppif`. Both use
existing `read-data.read` syntax with `completion-source response-demux`, bind
exactly one dynamic read transaction, expose generated `RDATA`/`RRESP` inputs,
and generate scalar data/status outputs captured under the generated dynamic
completion pulse. The single-beat sample reports
`generated_dynamic_read_response_demux_completion_pulse`; the last-beat sample
reports
`generated_dynamic_read_response_demux_last_beat_completion_pulse`.
Dynamic burst-length capture, runtime validation, multi-beat output banks,
multiple/mixed dynamic demux, same-cycle recapture, dynamic same-ID ordering,
queues, scoreboards, direct backend behavior, and VHDL remain deferred.
Selector
[AXI_IAL2_MANAGER_POST_DYNAMIC_READ_DATA_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_DYNAMIC_READ_DATA_NEXT_SLICE_SELECTION.md)
chooses `.236`, AXI manager focused-suite cost cleanup, before widening those
dynamic behavior boundaries. The prerequisite is the validation surface: the
shipped dynamic transaction-ID family should have bounded focused targets
rather than relying on oversized `t/1436` and `t/1437` monoliths for routine
closeout.
Cleanup
[AXI_IAL2_MANAGER_DYNAMIC_FOCUSED_SUITE_CLEANUP](../../AXI_IAL2_MANAGER_DYNAMIC_FOCUSED_SUITE_CLEANUP.md)
adds `t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t` for that
bounded proof and selects `.237`, dynamic burst-length readiness audit, as the
next owner. The readiness audit
[AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_READINESS_AUDIT.md)
selects `.238`, direct bounded report-only dynamic raw-`ARLEN` burst-length
capture over generated dynamic last-beat read-data.
Behavior
[AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_BEHAVIOR.md)
ships that selected shape. A dynamic last-beat read-data contract can now add:

```lisp
(burst-length
  (source arlen)
  (signal axi0_arlen (width 8))
  (encoding axlen-plus-one)
  (capture request)
  (max-beats 16)
  (validation report-only))
```

when paired with one `(id dynamic)` read transaction and generated
`response-demux.read` `burst-last` completion. FSMGen generates `axi0_arlen`,
transaction-local raw-`ARLEN` storage, request-guarded capture, and report
fields for generated burst-length inputs/storage/rules. Dynamic multi-beat
output banks, multiple or mixed dynamic demux, same-cycle recapture, dynamic
same-ID ordering, queues, scoreboards, direct backend behavior, and VHDL
remain deferred. The readiness audit
[AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_READINESS_AUDIT.md)
selects `.240`, direct bounded generated dynamic beat-count/`RLAST` runtime
validation over that same generated dynamic last-beat boundary. The selected
implementation needs no new public contract selector because existing
`read-data.read` `burst-length` syntax already accepts `validation
runtime-assertion`, and the runtime helper/report/residue substrate is already
transaction-list driven. Dynamic multi-beat output banks, multiple or mixed
dynamic demux, same-cycle recapture, dynamic same-ID ordering, queues,
scoreboards, direct backend behavior, backend-language variants, and VHDL
remain deferred.
Behavior
[AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_BEHAVIOR.md)
ships that selected runtime shape. The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_dynamic_read_data_burst_length_runtime_assertion.ppif
```

It uses the same dynamic last-beat read-data contract as the report-only
sample, with:

```lisp
(validation runtime-assertion)
```

FSMGen generates expected-beat storage from `ARLEN + 1`, read-beat counter
storage, request-time initialization, raw matched-`RID` beat-count increments,
and four beat-count/`RLAST` assertions while leaving scalar `RDATA`/`RRESP`
capture guarded by the generated dynamic `RID && RLAST` completion pulse.
The `.238` report-only sample stays supported and keeps
`generated_beat_count_validation` residue.

Post dynamic runtime-validation selector:
[AXI_IAL2_MANAGER_POST_DYNAMIC_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_DYNAMIC_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md)
selects `.242`, readiness audit for generated dynamic multi-beat output-bank
behavior over the selected single-active dynamic read runtime-validation
boundary. The selector changes no behavior; multiple/mixed dynamic demux,
same-cycle recapture, dynamic same-ID ordering, queues, scoreboards, direct
backend behavior, backend-language variants, and VHDL remain deferred.
The readiness audit
[AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_READINESS_AUDIT.md)
selects `.243`, direct bounded implementation. The remaining work is local to
dynamic multi-beat coverage admission plus dynamic report-residue recognition;
the existing public syntax and output-bank lowerers are already adjacent.
Dynamic multi-beat behavior:
[AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_BEHAVIOR.md)
now ships that selected shape. The public sample
`ppif/axi_manager_capacity_status_dynamic_read_data_multi_beat.ppif`
generates per-beat `RDATA`/`RRESP` output lanes, a valid mask, a length
output, a worst-observed scalar `RRESP` aggregate, raw matched-`RID`
per-beat capture, and the `.240` expected-beat/`RLAST` runtime assertions.
Multiple/mixed dynamic demux, same-cycle recapture, dynamic same-ID ordering,
queues, scoreboards, direct backend behavior, backend-language variants, and
VHDL remain deferred.
Post dynamic multi-beat selector:
[AXI_IAL2_MANAGER_POST_DYNAMIC_MULTI_BEAT_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_DYNAMIC_MULTI_BEAT_NEXT_SLICE_SELECTION.md)
selects `.245`, readiness audit for multiple/mixed dynamic response-demux
behavior. The selected dynamic multi-beat sample now has empty `read_data`
residue and keeps only `same_id_ordering` in `response_demux.residue`; the
next prerequisite is the dynamic response ownership model for multiple
dynamic transactions, mixed dynamic/static demux, and same-cycle recapture.
Multiple dynamic response-demux readiness:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_RESPONSE_DEMUX_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_RESPONSE_DEMUX_READINESS_AUDIT.md)
selects `.246`, public contract selection for bounded multiple dynamic write
response-demux behavior. The audit found list-shaped lower helpers after
normalization, but the public contract must first define dynamic same-ID
ambiguity handling before one raw response can safely map across multiple
active dynamic transactions.
Multiple dynamic write response-demux contract:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md)
selects `.247`, direct generated behavior for bounded multiple dynamic write
response-demux. The selected first behavior requires every write transaction
in the covered family to be dynamic, keeps same-cycle dynamic write requests
onehot0, requires active captured dynamic IDs to be pairwise unique, and
prevents ambiguous `BID` responses through active-match, unique-match, and
same-ID conflict assertions rather than queues or scoreboards.
Multiple dynamic write response-demux behavior:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md)
ships that `.247` behavior. The support-accounted public sample
`ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif`
generates per-transaction selected-ID/busy state, admitted `AWID` capture,
matched `BID` completion pulses, busy release rules, request onehot0
assertions, active-ID uniqueness assertions, request no-active-same-ID
assertions, response active-match assertions, and response unique-match
assertions. `.378` extends the same public sample with per-transaction
same-cycle release-and-recapture while preserving
`bounded_multi_dynamic_write_bid_demux_contract`. Multiple dynamic read
single-beat response-demux now ships under `.251`; multiple dynamic read
burst-last/`RLAST`, read-data, burst-length, runtime validation, and
multi-beat output-bank widening now ship in selected bounded forms. Multiple
dynamic read recapture, mixed dynamic/static recapture, same-cycle request
widening beyond onehot0, dynamic same-ID queues, scoreboards, direct backend
behavior, backend-language variants, and VHDL remain deferred.
Post multiple dynamic write response-demux selector:
[AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md)
selects `.249`, readiness audit for multiple dynamic read response-demux. The
read side needs an audit before behavior changes because it combines
`single_beat` and `burst_last` response scopes, optional `RLAST`, raw
matched-read-beat counting, scalar read-data, burst-length/runtime
validation, and multi-beat output-bank coupling.
Multiple dynamic read response-demux readiness:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md)
selects `.250`, public contract selection for bounded multiple dynamic read
response-demux. The audit found list-shaped dynamic storage, capture/release,
response-rule, and assertion helpers after normalization, but the read helper
and dynamic read-data coverage still admit exactly one generated dynamic read
transaction, so public read scope and read-data interaction must be selected
before implementation.
Multiple dynamic read response-demux contract:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md)
selects `.251`, direct generated behavior for bounded multiple dynamic read
single-beat response-demux. The first contract is response-demux-only, requires
all read transactions in the selected family to be dynamic, keeps same-cycle
dynamic read requests onehot0, requires active captured dynamic read IDs to be
pairwise unique, and defers burst-last/`RLAST`, read-data, burst-length,
runtime validation, and multi-beat output banks over multiple dynamic reads.
Multiple dynamic read response-demux behavior:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_BEHAVIOR.md)
ships `.251`, generated bounded multiple dynamic read single-beat
response-demux. The support-accounted sample
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif`
uses explicit `response-demux.read` with `response-scope single-beat`, two
all-dynamic read transactions, shared `ARID`/`RID` family signals,
per-transaction selected-ID/busy state, admitted `ARID` capture, generated
matched-`RID` completion pulses, busy release rules, request onehot0,
request no-active-same-ID, active-ID uniqueness, active-match, unique-match,
and completion-active assertions. Multiple dynamic read burst-last/`RLAST`,
read-data, burst-length/runtime validation, multi-beat output banks, mixed
dynamic/static demux, same-cycle widening, same-cycle release-and-recapture,
dynamic same-ID queues, scoreboards, direct backend behavior, backend-language
variants, and VHDL remain later exact owners.
Post multiple dynamic read response-demux selector:
[AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md)
selects `.253`, readiness audit for multiple dynamic read burst-last/`RLAST`
response-demux after `.251` shipped the bounded multiple dynamic read
single-beat boundary. The audit must decide whether all-dynamic multiple-read
burst-last can be implemented directly, needs contract selection, or needs
helper/report cleanup first. It must settle raw matched-`RID` beat assertions,
selected-ID/busy lifetime across non-last beats, one-bit `last-signal`
ownership, final `RID && RLAST` completion, generated release, validation,
rollback, and explicit residue before any multiple dynamic read read-data,
burst-length/runtime, or multi-beat output-bank widening.

Multiple dynamic read RLAST response-demux readiness audit:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md)
selects `.254`, public contract selection for bounded multiple dynamic read
burst-last/`RLAST` response-demux. The audit found the state-list
capture/release/rule/assertion substrate is close after `.251`, but the
public contract must first pin the all-dynamic family shape, burst-last
`last-signal` ownership, selected-ID/busy lifetime across non-last beats, raw
`RID` beat matching versus final `RID && RLAST` completion, generated
assertion roles, report vocabulary, sample/support-accounting expectations,
validation, rollback, and explicit read-data/runtime/multi-beat residue. No
parser, generator, PPIF sample, support-accounting catalog, validation
behavior, generated artifact, test, schedule/check/semantic JSON, or HDL
behavior changes in the audit slice.

Multiple dynamic read RLAST response-demux contract selection:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md)
selects `.255`, direct generated behavior for bounded multiple dynamic read
burst-last/`RLAST` response-demux. The selected contract uses two or more
all-dynamic read transactions, `response-demux.read response-scope
burst-last`, a one-bit `last-signal`, admitted `ARID` capture, onehot0
same-cycle dynamic read requests, pairwise unique active dynamic IDs, raw
`RID` beat active/unique assertions without `RLAST`, final `RID && RLAST`
completion/release guards, and
`bounded_multi_dynamic_read_rid_rlast_demux_contract` report vocabulary.
Read-data, burst-length/runtime validation, multi-beat output banks, mixed
dynamic/static demux, same-cycle widening, release-and-recapture, dynamic
same-ID queues, scoreboards, direct backend behavior, backend-language
variants, and VHDL remain later exact owners.

Multiple dynamic read RLAST response-demux behavior:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md)
ships generated bounded multiple dynamic read burst-last/`RLAST`
response-demux for
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif`.
The report mode is
`bounded_multi_dynamic_read_rid_rlast_demux_contract`. The generated logic
captures admitted `ARID` into per-transaction selected-ID/busy state, enforces
onehot0 same-cycle dynamic read requests and pairwise unique active dynamic
IDs, completes each transaction only on final `RID && RLAST`, and keeps raw
`RID` beat active/unique assertions unqualified by `RLAST` so non-last beats
remain checked but do not complete the transaction. Read-data,
burst-length/runtime validation, and multi-beat output banks over multiple
dynamic read demux remain explicit future owners.

Post multiple dynamic read RLAST response-demux selector:
[AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md)
selects `.257`, readiness audit for read-data over generated multiple dynamic
read response-demux. The selector records that `.251` and `.255` now provide
generated multiple dynamic read completion pulses for single-beat and
burst-last scopes, but `read_data.read` dynamic coverage still requires
exactly one dynamic read transaction. That read-data coverage audit is the
next dependency before burst-length/runtime validation or multi-beat
output-bank widening over multiple dynamic read demux.

Multiple dynamic read-data readiness audit:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_READINESS_AUDIT.md)
selects `.258`, public contract selection for bounded scalar read-data over
generated multiple dynamic read response-demux. The audit found the helper
substrate is close: dynamic response-demux reports expose ordered transactions
and generated completion pulses, and read-data normalization already validates
transaction bindings against a coverage list. The contract selector must still
pin scalar single-beat and last-beat source shapes, sample names,
transaction-to-completion mapping, report vocabulary, diagnostics, validation,
and residue before behavior changes.

Multiple dynamic read-data contract selection:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_CONTRACT_SELECTION.md)
selects `.259`, direct generated behavior for bounded scalar read-data over
generated multiple dynamic read response-demux. The selected public samples
are `ppif/axi_manager_capacity_status_dynamic_read_data_multi.ppif` and
`ppif/axi_manager_capacity_status_dynamic_read_data_multi_last_beat.ppif`.
The contract requires read-data bindings to exactly cover all generated
dynamic read demux transactions, reuses the scalar single-beat and last-beat
read-data report modes, and keeps burst-length/runtime validation plus
multi-beat output banks over multiple dynamic read demux as later owners.

Multiple dynamic read-data behavior:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_BEHAVIOR.md)
ships `.259`. FSMGen now generates scalar single-beat and scalar last-beat
`RDATA`/`RRESP` capture over generated all-dynamic multiple read
response-demux. The shipped public samples are
`ppif/axi_manager_capacity_status_dynamic_read_data_multi.ppif` and
`ppif/axi_manager_capacity_status_dynamic_read_data_multi_last_beat.ppif`.
Each read-data transaction binding must cover one generated dynamic read
demux transaction, every generated dynamic read demux transaction must be
covered exactly once, and each scalar capture rule is guarded by that
transaction's generated completion pulse. Report-only raw-`ARLEN`
burst-length capture over the multiple dynamic last-beat shape now ships under
`.263`; runtime validation, multi-beat output banks, mixed dynamic/static
demux, same-cycle widening, dynamic same-ID queues, scoreboards, direct
backend behavior, backend-language variants, and VHDL remain later exact
owners.

Post multiple dynamic read-data selector:
[AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_DATA_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_DATA_NEXT_SLICE_SELECTION.md)
selects `.261`, readiness audit for burst-length/runtime validation over
generated multiple dynamic read response-demux. The selector keeps behavior
unchanged and chooses an audit because multi-beat output-bank widening depends
on per-transaction raw-`ARLEN` capture, expected-beat state, read-beat
counters, and assertion semantics across multiple active dynamic reads.

Multiple dynamic read burst-length/runtime readiness audit:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_READINESS_AUDIT.md)
selects `.262`, public contract selection for bounded burst-length and
runtime beat-count/`RLAST` validation over generated multiple dynamic read
response-demux. The lower burst-length, beat-count, assertion, matched-beat,
and report helpers were already transaction-list shaped after coverage
admission, but the dynamic coverage gate still failed closed for
multi-transaction burst-length/runtime metadata at audit time. The next slice had to settle
sample names, report-only versus runtime split, transaction coverage,
per-transaction `ARLEN` ownership, report vocabulary, diagnostics, validation,
and residue before implementation. No parser, generator, sample,
support-accounting, test, JSON, or HDL behavior changed in the audit.

Multiple dynamic read burst-length/runtime contract selection:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_CONTRACT_SELECTION.md)
selects a split implementation. `.263` ships report-only raw-`ARLEN`
burst-length capture over generated multiple dynamic read burst-last
response-demux and scalar last-beat read-data, using
`ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length.ppif`
as the public sample. `.264` ships the runtime beat-count/`RLAST` assertion
sibling through
`ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length_runtime_assertion.ppif`.
Both shapes require complete coverage of the all-dynamic read transaction set;
generated multiple dynamic multi-beat output banks ship in `.268`.
Mixed dynamic/static demux, same-cycle widening, dynamic queues/scoreboards,
direct backend behavior, backend-language variants, and VHDL remain later
owners.

Multiple dynamic read burst-length behavior:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_BEHAVIOR.md)
ships `.263`. FSMGen now emits a shared generated `axi0_arlen` input,
per-transaction raw-`ARLEN` storage, and request-guarded burst-length capture
rules for every generated all-dynamic read transaction in the scalar last-beat
read-data shape. The schedule report records
`burst_length_validation: report_only`,
`generated_burst_length_inputs`, per-transaction
`generated_burst_length_storage`, per-transaction
`generated_burst_length_rules`, and keeps
`generated_beat_count_validation` as residue. Runtime beat-count/`RLAST`
validation over multiple dynamic read demux ships in `.264`.

Multiple dynamic read burst-length runtime behavior:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_BEHAVIOR.md)
ships `.264`. FSMGen now emits per-transaction expected-beat storage,
read-beat counter storage, request-time initialization, matched-read-beat
counter increments, and four runtime assertions per generated all-dynamic read
transaction in the scalar last-beat shape. The schedule report records
`burst_length_validation: runtime_assertion`,
`beat_count_validation_generated_behavior: true`,
`expected_beat_count_encoding: arlen_plus_one`,
`beat_count_match_source: response_demux_matched_read_beat`, per-transaction
generated beat-count storage/rules/assertions, and removes
`generated_beat_count_validation` from residue.
Post multiple dynamic runtime-validation selector:
[AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md)
selects `.266`, readiness audit for generated multiple dynamic multi-beat
output-bank behavior over the generated multiple dynamic read
runtime-validation boundary. The selector changes no behavior. The audit is
next because the live dynamic multi-beat admission boundary is still
single-active, while scalar burst-length/runtime over multiple dynamic reads
is now generated; it must settle the multi-transaction output-bank source
shape, diagnostics, report vocabulary, validation, and residue before
multiple dynamic multi-beat behavior widens.

Multiple dynamic multi-beat readiness audit:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_READINESS_AUDIT.md)
selects `.267`, public contract selection for bounded generated multiple
dynamic multi-beat output-bank behavior. The audit found no separate IAL1,
IAL0, or SystemVerilog prerequisite before contract selection: the lower
output-bank helpers are already transaction-list shaped after coverage
admission, while dynamic multi-beat admission and report-residue recognition
are still single-active. Mixed dynamic/static, queue, scoreboard, direct
backend, backend-language variant, and VHDL behavior remain later exact
owners.

Multiple dynamic multi-beat contract selection:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_CONTRACT_SELECTION.md)
selects `.268`, direct implementation of the bounded all-dynamic
multi-transaction multi-beat output-bank contract. The selected public sample
is
`ppif/axi_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat.ppif`;
the name deliberately distinguishes multiple dynamic transactions from the
existing single-active dynamic multi-beat sample. The contract requires
generated dynamic read burst-last response-demux, `capture-scope multi-beat`,
runtime-assertion `ARLEN` burst-length metadata, complete exactly-once
output-bank bindings for every generated dynamic read transaction,
request-time output-bank initialization, raw matched-beat lane capture, and
worst-observed per-transaction scalar `RRESP` aggregation.

Multiple dynamic multi-beat behavior:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_BEHAVIOR.md)
ships `.268`. FSMGen now emits per-transaction output-bank initialization,
per-beat `RDATA`/`RRESP` lanes, valid masks, length outputs, scalar
worst-observed `RRESP` aggregates, request-captured `ARLEN`, expected-beat
state, read-beat counters, raw matched-beat lane capture, and four runtime
assertions per generated all-dynamic read transaction. The schedule report
records `read_data.mode: bounded_multi_beat_read_data_contract`,
`completion_validity:
generated_dynamic_read_response_demux_last_beat_completion_pulse`,
`status_aggregation_generated_behavior: true`,
`multi_beat_reassembly_generated_behavior: true`, and empty read-data
residue for the supported sample. Response-demux residue still keeps
`same_id_ordering`; mixed dynamic/static, same-cycle widening,
release-and-recapture, queues, scoreboards, direct backend, backend-language
variant, and VHDL behavior remain later owners.

Post multiple dynamic read recapture selector:
[AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RECAPTURE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md)
selects `.383`, readiness audit for multiple all-dynamic read burst-last
`RID && RLAST` same-cycle release-and-recapture. The selector changes no
behavior. The audit comes before public contract or implementation because
the burst-last path must preserve final completion, non-final raw read beats,
scalar last-beat read-data, raw-`ARLEN`, runtime beat-count/`RLAST`, and
multi-beat output-bank consumers.

Multiple dynamic read RLAST recapture readiness audit:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md)
selects `.384`, public contract selection for multiple all-dynamic read
burst-last `RID && RLAST` same-cycle release-and-recapture. The audit changes
no behavior. It found the implementation substrate close, but selected
contract ownership first for the last-beat release-recapture source, request
assertions, release guards, raw non-final beat preservation, scalar last-beat
read-data, raw-`ARLEN`, runtime beat-count/`RLAST`, multi-beat output-bank
preservation, validation, and rollback semantics.

Multiple dynamic read RLAST recapture contract:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md)
selects `.385`, direct implementation of multiple all-dynamic read burst-last
`RID && RLAST` same-cycle release-and-recapture. The selector changes no
behavior. The implementation must preserve
`bounded_multi_dynamic_read_rid_rlast_demux_contract`, use
`same_cycle_release_recapture_policy: multi_active_unique_dynamic_read` with
`release_recapture_source: generated_dynamic_demux_last_beat_completion`,
replace selected request-not-busy assertions with idle-or-releasing
assertions, and preserve raw non-final beats plus scalar last-beat read-data,
raw-`ARLEN`, runtime, and multi-beat consumers.

Multiple dynamic read RLAST recapture behavior:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_BEHAVIOR.md)
ships `.385`, same-cycle release-and-recapture for the existing multiple
all-dynamic read burst-last `RID && RLAST` response-demux sample. FSMGen emits
`axi0_r0_dynamic_id_release_recapture` and
`axi0_r1_dynamic_id_release_recapture`, reports
`same_cycle_release_recapture_policy: multi_active_unique_dynamic_read` with
`release_recapture_source: generated_dynamic_demux_last_beat_completion` under
`response_demux.read.dynamic_capture.transactions[]`, replaces the selected
request-not-busy assertions with idle-or-releasing assertions, keeps raw
non-final beats as raw matched beats only, and preserves scalar last-beat
read-data, raw-`ARLEN`, runtime beat-count/`RLAST`, and multi-beat output-bank
consumers.

Post multiple dynamic read RLAST recapture selector:
[AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md)
selects `.387`, readiness audit for mixed dynamic/static same-cycle
release-and-recapture. The selector changes no behavior. The audit comes next
because all selected all-dynamic recapture siblings are now covered, while the
mixed boundary must still pin static busy recapture semantics,
dynamic/static concrete-ID reservation, onehot0 sibling policy, assertion
changes, read `RID && RLAST` and raw non-final beat preservation, and layered
read-data/raw-`ARLEN`/runtime/multi-beat implications before behavior changes.

Mixed dynamic/static recapture readiness audit:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_RECAPTURE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_RECAPTURE_READINESS_AUDIT.md)
selects `.388`, public contract selection for mixed dynamic/static write
`BID` same-cycle release-and-recapture. The audit changes no behavior.
Guarded baseline schedule probes for the one-dynamic/one-static mixed write,
read single-beat, and read burst-last public samples passed and confirmed the
current reports still use request-not-busy assertions with no
release-recapture metadata. Mixed write is the next owner because it exercises
both dynamic selected-ID recapture and static concrete busy recapture without
the read `RID`/`RLAST`, read-data, raw-`ARLEN`, runtime validation, and
multi-beat output-bank preservation stack.

Mixed dynamic/static write recapture contract:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md)
selects `.389`, direct implementation of mixed dynamic/static write `BID`
same-cycle release-and-recapture for the existing support-accounted public
sample. The selector changes no behavior. It preserves public syntax,
`bounded_mixed_dynamic_static_write_bid_demux_contract`, generated mixed
completion source, onehot0 mixed request policy, static-ID reservation,
response active/unique-match, and completion-active assertions while selecting
dynamic recapture report fields, a new `static_capture` report block,
dynamic/static release-only exclusion, dynamic/static release-recapture guards,
and dynamic/static idle-or-releasing request assertions.

Mixed dynamic/static write recapture behavior:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md)
ships `.389`, same-cycle release-and-recapture for the existing mixed
dynamic/static write `BID` sample. FSMGen emits
`axi0_w0_dynamic_id_release_recapture` and
`axi0_w1_static_busy_release_recapture`, keeps release-only rules disjoint from
same-transaction same-cycle requests, reports
`mixed_dynamic_static_dynamic_write` under
`response_demux.write.dynamic_capture` and
`mixed_dynamic_static_static_write` under
`response_demux.write.static_capture`, and replaces the selected
request-not-busy assertions with idle-or-releasing assertions.

Post mixed dynamic/static write recapture selector:
[AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md)
selects `.391`, public contract selection for mixed dynamic/static read
single-beat `RID` same-cycle release-and-recapture. The selector changes no
behavior. Guarded baseline schedule probes for the mixed read single-beat and
burst-last public samples passed below the 88% host-memory cutoff and
confirmed the post-`.389` read reports still use request-not-busy assertions
with no read-side release-recapture metadata or `static_capture` block.
Single-beat read is next so `.391` can adapt the `.389` dynamic/static
recapture vocabulary to `response_demux.read` while preserving
`bounded_mixed_dynamic_static_read_rid_demux_contract`,
`response_scope: single_beat`, and `generated_mixed_dynamic_static_read_demux`
before burst-last, read-data, raw-`ARLEN`, runtime-validation, and multi-beat
preservation layers are widened.

Mixed dynamic/static read recapture contract:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION.md)
selects `.392`, direct implementation of mixed dynamic/static read
single-beat `RID` same-cycle release-and-recapture for the existing
support-accounted public sample. The selector changes no behavior. It
preserves public syntax, `bounded_mixed_dynamic_static_read_rid_demux_contract`,
`response_scope: single_beat`, generated mixed read completion source,
static-ID reservation, onehot0 mixed request policy, response
active/unique-match, and completion-active assertions while selecting
`response_demux.read.dynamic_capture` recapture fields, a new
`response_demux.read.static_capture` report block, dynamic/static release-only
exclusion, dynamic/static release-recapture guards, and dynamic/static
idle-or-releasing request assertions.

Mixed dynamic/static read recapture behavior:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md)
ships `.392`, same-cycle release-and-recapture for the existing mixed
dynamic/static read single-beat `RID` sample. FSMGen emits
`axi0_r0_dynamic_id_release_recapture` for the dynamic selected-ID slot and
`axi0_r1_static_busy_release_recapture` for the concrete static busy slot,
keeps release-only rules disjoint from same-transaction same-cycle requests,
reports `mixed_dynamic_static_dynamic_read` under
`response_demux.read.dynamic_capture` and `mixed_dynamic_static_static_read`
under `response_demux.read.static_capture`, and replaces the selected
request-not-busy assertions with idle-or-releasing assertions. Public syntax,
support identity, `bounded_mixed_dynamic_static_read_rid_demux_contract`,
`response_scope: single_beat`, and the generated mixed read completion source
are preserved; the mixed read burst-last `RID && RLAST` sample remains
unchanged.

Post mixed dynamic/static read recapture selector:
[AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md)
selects `.394`, readiness audit for mixed dynamic/static read burst-last
`RID && RLAST` same-cycle release-and-recapture. The selector changes no
behavior. Burst-last is the nearest sibling after `.392`, but it needs audit
before contract selection because final-only release and recapture must
preserve raw non-final `RID` beats, raw active/unique-match assertions,
scalar last-beat read-data, raw `ARLEN`, runtime beat-count/`RLAST`
validation, and multi-beat output-bank consumers.

Mixed dynamic/static read RLAST recapture readiness audit:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md)
selects `.395`, public contract selection for mixed dynamic/static read
burst-last `RID && RLAST` same-cycle release-and-recapture. The audit changes
no behavior. A guarded baseline schedule probe confirmed the existing
`bounded_mixed_dynamic_static_read_rid_rlast_demux_contract`,
`response_scope: burst_last`, `last_signal: axi0_rlast`, last-beat completion
source, request-not-busy assertions, no recapture metadata, and no
`static_capture` block. Contract selection is next so last-beat report source,
dynamic/static recapture fields, idle-or-releasing assertions, raw non-final
`RID` preservation, and read-data/raw-`ARLEN`/runtime/multi-beat consumers are
pinned before implementation.

Mixed dynamic/static read RLAST recapture contract:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md)
selects `.396`, direct implementation of mixed dynamic/static read burst-last
`RID && RLAST` same-cycle release-and-recapture for the existing public
sample. The selector changes no behavior. The selected contract preserves the
burst-last mode/scope, `last_signal`, last-beat transaction completion source,
raw non-final `RID` assertions, and layered read-data/raw-`ARLEN`/runtime/
multi-beat consumers. It reuses `mixed_dynamic_static_dynamic_read` and
`mixed_dynamic_static_static_read` policy names, with
`generated_mixed_dynamic_static_read_demux_last_beat_completion` as the
release-recapture source.

Mixed dynamic/static read RLAST recapture behavior:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md)
ships `.396` under the existing public sample. FSMGen emits
`axi0_r0_dynamic_id_release_recapture` and
`axi0_r1_static_busy_release_recapture`, keeps release-only rules disjoint
from same-transaction same-cycle requests, drives both recapture paths from
generated final `RID && RLAST` completion pulses, reports the last-beat
release-recapture source under `response_demux.read.dynamic_capture` and
`response_demux.read.static_capture`, and replaces the selected
request-not-busy assertions with `axi0_r0_dynamic_request_idle_or_releasing`
and `axi0_r1_static_request_idle_or_releasing`. Public syntax, support
identity, the burst-last mode/scope/source, raw non-final `RID` assertions,
and scalar read-data/raw-`ARLEN`/runtime/multi-beat consumers are preserved.

Post mixed dynamic/static read RLAST recapture selector:
[AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md)
selects `.398`, readiness audit for broader mixed dynamic/static same-cycle
release-and-recapture. The selector changes no behavior. Broader mixed
recapture is the nearest next residue now that the one-dynamic plus one-static
mixed write/read/read-`RLAST` family has shipped; multi-static, three-static,
and two-dynamic-plus-one-static public samples add sibling static busy
recapture, static-ID exclusion lists, active dynamic-ID uniqueness, and read
burst-last raw non-final beat preservation that need audit ownership before
contract selection or implementation. The `.396` RAM-guard cutoff is recorded
but is not selected as the next owner.

Broader mixed dynamic/static recapture readiness audit:
[AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_RECAPTURE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_RECAPTURE_READINESS_AUDIT.md)
selects `.399`, public contract selection for one-dynamic plus two-static
mixed dynamic/static write `BID` same-cycle release-and-recapture. The audit
changes no behavior. Guarded baseline probes confirmed the two-static,
three-static, and two-dynamic-plus-one-static write samples still report no
`static_capture` recapture block; the two-static write sample is the smallest
broader owner because it adds sibling static busy recapture and multiple
static-ID exclusions without adding read `RLAST`/read-data preservation or
two-dynamic active-ID uniqueness.

Multiple mixed dynamic/static write recapture contract selection:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md)
selects `.400`, direct implementation of one-dynamic plus two-static mixed
dynamic/static write `BID` same-cycle release-and-recapture for the existing
multi-static public sample. The selector changes no behavior. The selected
contract keeps `bounded_multi_mixed_dynamic_static_write_bid_demux_contract`,
`generated_multi_mixed_dynamic_static_demux`, the `w0`/`w1`/`w2` transaction
lists, static-ID reservations for `4'd3` and `4'd5`, generated demux rules,
generated completions, and the existing onehot0/static-ID-exclusion/
active-match/unique-match/completion-active assertions. It adds
list-shaped recapture metadata under `dynamic_capture.transactions[]` and
`static_capture[]`, makes release-only rules exclude same-transaction
same-cycle requests, and replaces the `w0`, `w1`, and `w2` request-not-busy
assertions with idle-or-releasing assertions.

Multiple mixed dynamic/static write recapture behavior:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md)
ships one-dynamic plus two-static mixed dynamic/static write `BID`
same-cycle release-and-recapture for the existing multi-static public sample.
FSMGen emits dynamic `w0` selected-ID release-recapture and `w1`/`w2`
concrete static busy release-recapture, reports dynamic recapture under
`dynamic_capture.transactions[0]`, reports static recapture under list-shaped
`static_capture[]`, and replaces the selected request-not-busy assertions with
idle-or-releasing assertions. Public syntax, support identity, mode/source/
semantics, transaction lists, static-ID reservations, response-demux matches,
generated completions, onehot0/static-ID-exclusion/active-match/
pairwise-unique-match/completion-active assertions, one-static singular
recapture shape, and three-static no-recapture shape are preserved. `.401`
selects the next post two-static mixed write recapture activity.

Post multiple mixed dynamic/static write recapture selector:
[AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md)
selects `.402`, public contract selection for one-dynamic plus three-static
mixed dynamic/static write `BID` same-cycle release-and-recapture under the
existing three-static public sample. The selector changes no behavior.
Three-static write recapture is the smallest post-`.400` behavior direction
because it stays write-only and one-dynamic while adding only one more
concrete static sibling. Two-dynamic recapture remains deferred behind active
dynamic-ID uniqueness and no-active-same-ID checks; broader mixed read
recapture remains deferred behind `RID`/`RLAST`, read-data, raw-`ARLEN`,
runtime, and multi-beat preservation.

Three-static mixed dynamic/static write recapture contract selection:
[AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md)
selects `.403`, direct implementation of one-dynamic plus three-static mixed
dynamic/static write `BID` same-cycle release-and-recapture for the existing
three-static public sample. The selector changes no behavior. The selected
contract preserves public syntax, support identity, mode/source/semantics,
transaction lists, static-ID reservations for `4'd3`/`4'd5`/`4'd7`, generated
demux rules/completions, and onehot0/static-ID-exclusion/active-match/
pairwise-unique-match/completion-active assertions. It selects dynamic
recapture fields under `dynamic_capture.transactions[0]`, list-shaped
`static_capture[]` entries for `w1`/`w2`/`w3`, disjoint release-only and
release-recapture guards for all four transactions, and idle-or-releasing
assertion names for `w0`/`w1`/`w2`/`w3`.

Three-static mixed dynamic/static write recapture behavior:
[AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR](../../AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md)
ships one-dynamic plus three-static mixed dynamic/static write `BID`
same-cycle release-and-recapture for the existing three-static public sample.
FSMGen emits dynamic `w0` selected-ID release-recapture and concrete static
`w1`/`w2`/`w3` busy release-recapture, reports dynamic recapture under
`dynamic_capture.transactions[0]`, reports static recapture under list-shaped
`static_capture[]`, makes release-only rules disjoint from same-transaction
same-cycle requests, and replaces `w0`/`w1`/`w2`/`w3` request-not-busy
assertions with idle-or-releasing assertions. Public syntax, support identity,
mode/source/semantics, transaction lists, static-ID reservations, generated
demux/completion behavior, onehot0/static-ID-exclusion/active-match/
pairwise-unique-match/completion-active assertions, the one-static singular
recapture shape, the two-static recapture shape, and the
two-dynamic-plus-one-static no-recapture shape are preserved. `.404` selects
the next post three-static mixed write recapture activity.

Post three-static mixed dynamic/static write recapture selector:
[AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md)
selects `.405`, readiness audit for two-dynamic-plus-one-static mixed
dynamic/static write `BID` same-cycle release-and-recapture under the
existing `ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif`
sample. The selector changes no behavior. This is the nearest post-`.403`
residue because it stays write-only, but it needs an audit before contract
selection: the current mixed write recapture marker is capped at one dynamic
transaction, while the candidate composes two active dynamic selected-ID
owners, one concrete static owner, active dynamic-ID uniqueness,
no-active-same-ID checks, static-ID exclusions, list-shaped dynamic recapture
entries, and `static_capture`. Broader mixed read recapture remains deferred
behind raw non-final `RID`, `RLAST`, read-data, raw-`ARLEN`, runtime, and
multi-beat preservation.

Two-dynamic/one-static mixed dynamic/static write recapture readiness audit:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_READINESS_AUDIT.md)
selects `.406`, public contract selection for the same
two-dynamic-plus-one-static mixed dynamic/static write `BID` same-cycle
release-and-recapture boundary. The audit changes no behavior. It found no
smaller parser/source/support-accounting/report/assertion substrate
prerequisite: the existing state builder already computes sibling dynamic
request blocks, active sibling same-ID blocks, static request blocks,
static-ID exclusions, static dynamic-request blocks, idle-or-releasing names,
no-active-same-ID assertions, active dynamic-ID uniqueness, response
active-match, unique-match, and completion-active surfaces. Contract
selection remains required before implementation because the current mixed
write recapture marker is capped at one dynamic transaction and the dynamic
recapture helper currently chooses either multi-active dynamic guards or
mixed static guards. A guarded candidate schedule probe stopped before usable
output at host memory 89.5% against the default 88% cutoff; no cutoff was
raised. Broader mixed read recapture remains deferred behind raw non-final
`RID`, `RLAST`, read-data, raw-`ARLEN`, runtime, and multi-beat preservation.

Two-dynamic/one-static mixed dynamic/static write recapture contract:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md)
selects `.407`, direct implementation of two-dynamic-plus-one-static mixed
dynamic/static write `BID` same-cycle release-and-recapture for the existing
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif`
sample. The selector changes no behavior. The contract preserves public
syntax, support identity, the multi-mixed write mode/source/semantics,
transaction lists, static ID `4'd3`, generated demux/completion behavior, and
onehot0/no-active-same-ID/active dynamic-ID uniqueness/static-ID-exclusion/
active-match/unique-match/completion-active assertions. It selects dynamic
recapture fields for both `dynamic_capture.transactions[]` entries, new
dynamic policy `mixed_dynamic_static_multi_active_dynamic_write`,
`release_recapture_source: generated_multi_mixed_dynamic_static_demux_completion`,
list-shaped
`static_capture[]` for `w2`, combined dynamic guards across sibling dynamic
request, active sibling same-ID, static request, and static-ID exclusion
blocks, static recapture guarded against both dynamic requests, release-only
exclusion of same-transaction requests, and idle-or-releasing assertions for
`w0`/`w1`/`w2`. Broader mixed read recapture remains deferred behind raw
non-final `RID`, `RLAST`, read-data, raw-`ARLEN`, runtime, and multi-beat
preservation.

Two-dynamic/one-static mixed dynamic/static write recapture behavior:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md)
ships two-dynamic-plus-one-static mixed dynamic/static write `BID` same-cycle
release-and-recapture for the existing
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif`
sample. FSMGen emits `axi0_w0_dynamic_id_release_recapture`,
`axi0_w1_dynamic_id_release_recapture`, and
`axi0_w2_static_busy_release_recapture`, reports
`mixed_dynamic_static_multi_active_dynamic_write` for both dynamic capture
transaction entries, reports list-shaped `static_capture[]` for `w2`, keeps
release-only rules disjoint from same-transaction requests, composes dynamic
guards across sibling dynamic request, active sibling same-ID, static request,
and static-ID exclusion blocks, guards static recapture against both dynamic
requests, and replaces `w0`/`w1`/`w2` request-not-busy assertions with
idle-or-releasing assertions. Syntax checks passed. Guarded selected schedule
JSON and focused t/1438 probes stopped before usable output at host memory
94.5% and 92.5% against the default 88% cutoff; no cutoff was raised.

Post two-dynamic/one-static mixed dynamic/static write recapture selector:
[AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md)
selects `.409`, readiness audit for one-dynamic-plus-two-static mixed
dynamic/static read single-beat `RID` same-cycle release-and-recapture. The
selector changes no behavior. It chooses the read single-beat one-dynamic plus
two-static sample because broader mixed write recapture is now covered, while
read burst-last recapture adds raw non-final `RID`, final `RLAST`, read-data,
raw-`ARLEN`, runtime, and multi-beat preservation, and two-dynamic read
recapture adds active dynamic-ID uniqueness and no-active-same-ID guards. A
guarded candidate schedule probe stopped before usable output at host memory
92.0% against the default 88% cutoff; output was 0 bytes and no cutoff was
raised.

Multiple mixed dynamic/static read recapture readiness audit:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_READINESS_AUDIT.md)
selects `.410`, public contract selection for one-dynamic-plus-two-static
mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture.
The audit changes no behavior. A guarded baseline schedule probe for
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif`
completed at host memory 79.6% against the default 88% cutoff and produced a
44021-byte schedule report. The live report still has request-not-busy
assertions for `r0`/`r1`/`r2`, no `static_capture`, and no
release-recapture fields under `dynamic_capture.transactions[]`. The next
contract must pin list-shaped static read recapture, dynamic guard
composition across both static siblings, idle-or-releasing assertion names,
and scalar read-data preservation before behavior widens.

Multiple mixed dynamic/static read recapture contract selection:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION.md)
selects `.411`, direct implementation of one-dynamic-plus-two-static mixed
dynamic/static read single-beat `RID` same-cycle release-and-recapture. The
selector changes no behavior. A guarded baseline schedule probe completed at
host memory 83.5% against the default 88% cutoff and produced a 44021-byte
report. The contract selects dynamic recapture fields for
`dynamic_capture.transactions[0]`, list-shaped `static_capture[]` entries for
`r1`/`r2`, `generated_multi_mixed_dynamic_static_read_demux_completion`, and
idle-or-releasing assertions while preserving scalar single-beat read-data
consumers.

Multiple mixed dynamic/static read recapture behavior:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md)
ships one-dynamic-plus-two-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture for the existing public sample. FSMGen emits
`axi0_r0_dynamic_id_release_recapture`,
`axi0_r1_static_busy_release_recapture`, and
`axi0_r2_static_busy_release_recapture`; reports
`mixed_dynamic_static_dynamic_read` under
`dynamic_capture.transactions[0]`; reports list-shaped `static_capture[]` for
`r1`/`r2`; uses
`generated_multi_mixed_dynamic_static_read_demux_completion`; preserves the
singular mixed read recapture shape, the three-static no-recapture boundary,
and scalar single-beat read-data consumers; and advances `.412` to select the
next post-read-recapture activity.

Post multiple mixed dynamic/static read recapture selector:
[AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md)
selects `.413`, readiness audit for one-dynamic-plus-two-static mixed
dynamic/static read burst-last `RID && RLAST` same-cycle
release-and-recapture. The selector changes no behavior. A guarded baseline
schedule probe on the public burst-last sample started at host memory 85.2%
against the default 88% cutoff and produced a 44340-byte report. The live
burst-last report still has request-not-busy assertions for `r0`/`r1`/`r2`,
no `static_capture`, and no release-recapture fields under
`dynamic_capture.transactions[]`; `.413` must pin the final-beat
release-recapture source and preservation boundaries before implementation.

Multiple mixed dynamic/static read RLAST recapture readiness audit:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md)
selects `.414`, public contract selection for one-dynamic-plus-two-static
mixed dynamic/static read burst-last `RID && RLAST` same-cycle
release-and-recapture. The audit changes no behavior. A guarded baseline
schedule probe started at host memory 86.3% against the default 88% cutoff
and produced a 44340-byte report showing request-not-busy assertions, no
`static_capture`, and no release-recapture fields. No lower parser, PPIF
syntax, support-accounting, IAL1/HDL lowering, or report-schema prerequisite
was found.

Multiple mixed dynamic/static read RLAST recapture contract:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md)
selects `.415`, direct implementation of one-dynamic-plus-two-static mixed
dynamic/static read burst-last `RID && RLAST` same-cycle
release-and-recapture. The selector changes no behavior. The selected
contract keeps the existing public burst-last sample, mode
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
`axi0_rlast`, generated final-beat completion source, `r0`/`r1`/`r2`
transaction lists, static IDs `4'd3`/`4'd5`, raw `RID` assertions,
completion-active assertions, and scalar read-data/raw-`ARLEN`/runtime/
multi-beat consumers. It pins recapture fields under
`dynamic_capture.transactions[0]`, list-shaped `static_capture[]` entries
for `r1`/`r2`, release-recapture source
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`,
mixed read policy names, dynamic/static guard composition, release-only
same-transaction request exclusions, and idle-or-releasing assertion names
for the implementation owner.

Multiple mixed dynamic/static read RLAST recapture behavior:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md)
ships `.415`. The public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif`
now reports same-cycle final-beat release-and-recapture for `r0`, `r1`, and
`r2`: dynamic recapture under `dynamic_capture.transactions[0]`,
list-shaped static recapture under `static_capture[]`,
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`, and
idle-or-releasing assertions for all three selected read transactions. The
one-static RLAST recapture shape, three-static no-recapture shape,
two-dynamic-plus-one-static no-recapture shape, and scalar read-data/raw-
`ARLEN`/runtime/multi-beat consumers remain preserved.

Post multiple mixed dynamic/static read RLAST recapture selector:
[AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md)
selects `.417`, readiness audit for one-dynamic-plus-three-static mixed
dynamic/static read single-beat `RID` same-cycle release-and-recapture. The
selector changes no behavior. A guarded baseline schedule probe for
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif`
produced a 46985-byte report showing request-not-busy assertions for
`r0`/`r1`/`r2`/`r3`, no `static_capture`, and no release-recapture fields.
The audit must pin the three-static recapture report, guard, assertion,
validation, rollback, and deferred-boundary contract before implementation.

Three-static mixed dynamic/static read recapture readiness audit:
[AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_READINESS_AUDIT.md)
selects `.418`, public contract selection for one-dynamic-plus-three-static
mixed dynamic/static read single-beat `RID` same-cycle
release-and-recapture. The audit changes no behavior. It found no lower
parser, syntax, support-accounting, report-schema, or IAL1/HDL prerequisite:
the public sample and list-shaped report mode already ship, rule/assertion
helpers already compose over guard arrays, and the marker body already
projects list-shaped static capture entries after its current one-or-two-
static selection guard.

Three-static mixed dynamic/static read recapture contract selection:
[AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION.md)
selects `.419`, direct implementation of one-dynamic-plus-three-static mixed
dynamic/static read single-beat `RID` same-cycle release-and-recapture for
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif`.
The selector changes no behavior. The selected contract preserves the
existing public syntax and support identity, the existing
`bounded_multi_mixed_dynamic_static_read_rid_demux_contract` mode,
single-beat scope, generated multiple mixed read demux source, `r0`/`r1`/
`r2`/`r3` transaction lists, static-ID reservations, generated demux and
completion names, onehot0/static-ID/active-match/unique-match/completion-
active assertions, and adjacent read-data consumers. The implementation must
add dynamic recapture under `dynamic_capture.transactions[0]`, list-shaped
`static_capture[]` entries for `r1`/`r2`/`r3`,
`generated_multi_mixed_dynamic_static_read_demux_completion`, dynamic/static
guard composition, same-transaction request exclusions on release-only rules,
and idle-or-releasing request assertions for all four transactions.

Three-static mixed dynamic/static read recapture behavior:
[AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR](../../AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md)
ships one-dynamic-plus-three-static mixed dynamic/static read single-beat
`RID` same-cycle release-and-recapture for the existing three-static public
sample. Reports now include dynamic recapture for `r0`, list-shaped
`static_capture[]` entries for `r1`/`r2`/`r3`,
`generated_multi_mixed_dynamic_static_read_demux_completion`, composed
dynamic/static guards, same-transaction request exclusions on release-only
rules, and idle-or-releasing request assertions for all four transactions.
The three-static burst-last sample and two-dynamic-plus-one-static samples
remain un-widened.

Post three-static mixed dynamic/static read recapture selector:
[AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md)
selects `.421`, readiness audit for one-dynamic-plus-three-static mixed
dynamic/static read burst-last `RID && RLAST` same-cycle
release-and-recapture. The selector changes no behavior. A direct baseline
probe confirmed the three-static burst-last report still has no
`static_capture`, no dynamic recapture fields, and request-not-busy
assertions for all four transactions.

Three-static mixed dynamic/static read RLAST recapture readiness audit:
[AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md)
selects `.422`, public contract selection for one-dynamic-plus-three-static
mixed dynamic/static read burst-last `RID && RLAST` same-cycle
release-and-recapture. The audit changes no behavior. A direct
normalizer/report probe confirmed the current three-static burst-last
baseline has `burst_last` scope, one-bit `axi0_rlast`,
`generated_multi_mixed_dynamic_static_read_demux_last_beat`, no
`static_capture`, no dynamic recapture fields, and four request-not-busy
assertions. A direct marker probe confirmed the existing marker substrate can
project three `static_capture[]` entries with
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion` once a
later implementation selects the burst-last normalizer widening.

Three-static mixed dynamic/static read RLAST recapture contract selection:
[AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md)
selects `.423`, direct implementation of one-dynamic-plus-three-static mixed
dynamic/static read burst-last `RID && RLAST` same-cycle
release-and-recapture for the existing three-static public sample. The
selector changes no behavior. The selected contract preserves public syntax,
the existing `bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`
mode, final-beat `RID && RLAST` completion semantics, raw non-final `RID`
ownership evidence, adjacent read-data consumers, dynamic recapture for `r0`,
list-shaped `static_capture[]` entries for `r1`/`r2`/`r3`, final-beat
release-recapture source, dynamic/static guard composition, same-transaction
request exclusions, and idle-or-releasing assertion names.

Three-static mixed dynamic/static read RLAST recapture behavior:
[AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR](../../AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md)
ships one-dynamic-plus-three-static mixed dynamic/static read burst-last
`RID && RLAST` same-cycle release-and-recapture for the existing three-static
public sample. The public syntax is unchanged. The report now includes
dynamic recapture under `dynamic_capture.transactions[0]`, list-shaped
`static_capture[]` entries for `r1`/`r2`/`r3`, final-beat
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`, and
idle-or-releasing assertions for all four transactions. The generated rules
include `axi0_r3_static_busy_release_recapture`, release-only guards exclude
same-transaction requests, dynamic recapture excludes all three reserved
static IDs, and adjacent read-data/burst-length consumers keep their existing
completion or raw matched-beat contracts.

Post three-static mixed dynamic/static read RLAST recapture selector:
[AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md)
selects `.425`, readiness audit for two-dynamic-plus-one-static mixed
dynamic/static read single-beat `RID` same-cycle release-and-recapture. The
selector changes no behavior. Direct baseline probes confirmed the existing
two-dynamic-plus-one-static read single-beat and burst-last reports still have
no release-recapture fields, no `static_capture`, request-not-busy assertions
for `r0`/`r1`/`r2`, and zero idle-or-releasing assertions. The single-beat
shape is audited first because it covers multi-dynamic selected-ID recapture,
active same-ID blocking, static concrete busy recapture, onehot0 mixed request
policy, no-active-same-ID assertions, and active dynamic-ID uniqueness without
the extra `RLAST` final-beat boundary.

Two-dynamic/one-static mixed dynamic/static read recapture readiness:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_READINESS_AUDIT.md)
selects `.426`, public contract selection for two-dynamic-plus-one-static
mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture.
The audit changes no behavior. A guarded schedule probe stopped at 95.3% host
memory against the default 88% cutoff, so direct fallback probes were used.
Those probes confirmed the public single-beat sample still has no dynamic
release-recapture fields, no `static_capture`, no generated
release-recapture rules, and request-not-busy assertions for `r0`, `r1`, and
`r2`. The contract-selection leaf should pin the read-side
`mixed_dynamic_static_multi_active_dynamic_read` policy, list-shaped static
capture for `r2`, the generated mixed read completion source, and
idle-or-releasing assertions while preserving the burst-last no-recapture
sibling and read-data consumers.

Two-dynamic/one-static mixed dynamic/static read recapture contract:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION.md)
selects `.427`, direct implementation of the single-beat `RID`
same-cycle release-and-recapture contract. The selector changes no behavior.
The implementation owner should keep the existing public sample and report
mode, add release-recapture entries for `r0` and `r1` under
`dynamic_capture.transactions[]` with
`mixed_dynamic_static_multi_active_dynamic_read`, add list-shaped
`static_capture[]` for `r2`, use
`generated_multi_mixed_dynamic_static_read_demux_completion`, and replace only
the `r0`/`r1`/`r2` request-not-busy assertions with idle-or-releasing
assertions. The burst-last two-dynamic read sibling, one-/two-/three-static
read recapture shapes, the two-dynamic write recapture shape, and read-data
consumers stay preservation boundaries.

Two-dynamic/one-static mixed dynamic/static read recapture behavior:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md)
ships `.427`, two-dynamic-plus-one-static mixed dynamic/static read
single-beat `RID` same-cycle release-and-recapture for the existing public
sample. FSMGen emits `axi0_r0_dynamic_id_release_recapture`,
`axi0_r1_dynamic_id_release_recapture`, and
`axi0_r2_static_busy_release_recapture`; reports
`mixed_dynamic_static_multi_active_dynamic_read` under both dynamic
`dynamic_capture.transactions[]` entries; reports list-shaped
`static_capture[]` for `r2`; composes dynamic guards across sibling dynamic
requests, active sibling same-ID, static requests, and static-ID exclusion;
composes static guards across both dynamic requests; and replaces the
`r0`/`r1`/`r2` request-not-busy assertions with idle-or-releasing assertions.
The two-dynamic burst-last and read-data/raw-`ARLEN`/runtime/multi-beat
consumers remain no-recapture preservation boundaries. A guarded focused
`t/1438` selected filter stopped at the RAM cutoff before TAP output; direct
report and ISF/FSM/SystemVerilog fallback probes covered the selected
behavior. `.428` now selects the next post two-dynamic mixed read recapture
slice.

Post two-dynamic/one-static mixed dynamic/static read recapture selector:
[AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md)
selects `.429`, readiness audit for two-dynamic-plus-one-static mixed
dynamic/static read burst-last `RID && RLAST` same-cycle
release-and-recapture. The selector changes no behavior. Direct baseline
probes on the burst-last response-demux, burst-last read-data, and burst-last
raw-`ARLEN` samples confirmed they still use
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
`generated_multi_mixed_dynamic_static_read_demux_last_beat`,
request-not-busy assertions for `r0`/`r1`/`r2`, no `static_capture`, and no
release-recapture rules. The audit is next because this shape reuses the
`.427` dynamic/static guard problem but adds final-beat source, raw non-final
`RID`, `RLAST`, and read-data/raw-`ARLEN`/runtime/multi-beat preservation
questions before any behavior change.

Two-dynamic/one-static mixed dynamic/static read RLAST recapture readiness:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md)
selects `.430`, public contract selection for the same
two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID &&
RLAST` release-and-recapture boundary. The audit changes no behavior. It
found no lower parser, support-accounting, report-schema, IAL1, or HDL
prerequisite: `.427` already supplied the read-side multi-active mixed
recapture policy and guard storage, while the burst-last normalizer is the
remaining selector that leaves the two-dynamic/one-static RLAST branch
unmarked. `.430` must pin
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`,
dynamic/static report fields, guard composition, idle-or-releasing assertion
names, and read-data/raw-`ARLEN`/runtime/multi-beat preservation before
implementation.

Two-dynamic/one-static mixed dynamic/static read RLAST recapture contract:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md)
selects `.431`, direct implementation of the existing public burst-last
sample's `RID && RLAST` release-and-recapture contract. The selector changes
no behavior. The selected implementation keeps the existing support identity,
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
`axi0_rlast`, generated final-beat completion source, raw non-final `RID`
assertions, and adjacent read-data/raw-`ARLEN`/runtime/multi-beat consumers.
It adds release-recapture fields for `r0` and `r1` under
`dynamic_capture.transactions[]` with
`mixed_dynamic_static_multi_active_dynamic_read`, list-shaped
`static_capture[]` for `r2`, final-beat source
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`,
combined dynamic/static guards, same-transaction release-only exclusions, and
idle-or-releasing request assertions for `r0`, `r1`, and `r2`.

Two-dynamic/one-static mixed dynamic/static read RLAST recapture behavior:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md)
ships that existing public burst-last sample's `RID && RLAST`
release-and-recapture behavior. FSMGen emits dynamic recapture rules for
`r0`/`r1` and static recapture for `r2` from generated final-beat completion
pulses only, reports dynamic recapture under
`dynamic_capture.transactions[]`, reports list-shaped `static_capture[]` for
`r2`, and replaces the selected request-not-busy assertions with
idle-or-releasing assertions. Public syntax, support identity, mode/source/
semantics, raw non-final `RID` assertions, final-beat completion ownership,
`.427` single-beat recapture, one-/two-/three-static burst-last recapture,
and read-data/raw-`ARLEN`/runtime/multi-beat consumers remain preserved.
`.432` is the next post two-dynamic mixed read burst-last recapture selector.

Post two-dynamic/one-static mixed dynamic/static read RLAST recapture selector:
[AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md)
selects `.433`, readiness audit for dynamic same-ID issue-order policy,
queue, and scoreboard ownership after the bounded dynamic/mixed
response-demux, read-data, multi-beat, and same-cycle release-and-recapture
chain reached the two-dynamic-plus-one-static read burst-last boundary. The
selector changes no behavior. It records that dynamic transaction-ID
contract/report support and generated bounded dynamic/mixed response-demux
behavior now exist, while direct same-ID queue or scoreboard behavior still
needs public issue-order policy, request arbitration, overflow/ambiguity
assertions, and report/residue movement before implementation.

Dynamic same-ID policy readiness audit:
[AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_READINESS_AUDIT.md)
selects `.434`, public dynamic same-ID policy contract selection before
dynamic per-ID queues, scoreboards, parser/report implementation, or
generated behavior. The audit changes no behavior. It records that generated
bounded dynamic and mixed response-demux/read-data/multi-beat/recapture
substrate now exists, while dynamic same-ID reuse still lacks public
source/report vocabulary distinct from concrete `concrete-id-reuse`. Direct
queues or scoreboards remain deferred until the contract selects the dynamic
policy spelling, report fields, diagnostics, allowed first policy values, and
first later owner.

Dynamic same-ID policy contract:
[AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_CONTRACT_SELECTION.md)
selects additive family-local `(dynamic-id-reuse reject)` under
`(same-id-ordering ...)`, distinct from `concrete-id-reuse`, and selects
`.435`, metadata-first parser/report readiness audit before implementation.
The first dynamic same-ID policy value is only `reject`; dynamic
`issue-order-queue` and `scoreboard` values remain unsupported future owners.
The selected report vocabulary is
`same_id_ordering.dynamic_id_reuse_policy.<family>`, with accepted same-ID
reuse false and no generated queue or scoreboard behavior. The selector
changes no behavior.

Dynamic same-ID policy metadata readiness audit:
[AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_METADATA_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_METADATA_READINESS_AUDIT.md)
selects `.436`, direct metadata-first parser/report implementation for
`(dynamic-id-reuse reject)`. The audit changes no behavior. The first
implementation should add the public syntax, normalized report fields,
focused diagnostics, a metadata-only public sample, and support accounting,
while keeping generated dynamic response-demux plus dynamic same-ID policy
fail-closed until a later owner maps generated no-active-same-ID assertion
enforcement.

Dynamic same-ID policy metadata-first support:
[AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_METADATA_FIRST_SLICE](../../AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_METADATA_FIRST_SLICE.md)
ships parser/report support for `(dynamic-id-reuse reject)` under
`(same-id-ordering ...)`. Dynamic-only policy reports
`same_id_ordering.mode: dynamic_id_reuse_policy` and
`same_id_ordering.dynamic_id_reuse_policy.<family>` with `policy: reject`,
`implementation_status: selected_not_generated`, `enforcement:
not_generated`, `accepted_same_id_reuse: false`,
`request_conflict_policy: no_active_same_id`, and no generated queue or
scoreboard behavior. Concrete and dynamic policy clauses may coexist in one
family arm and report as `same_id_ordering.mode: id_reuse_policy`. The public
sample is
`ppif/axi_manager_capacity_status_dynamic_same_id_reject_policy.ppif`.
At this metadata-first boundary, generated dynamic same-ID enforcement and
response-demux mapping were still deferred; later `.438` and `.442` slices now
cover bounded generated response-demux assertion mappings. Dynamic queues,
scoreboards, HDL behavior, and VHDL behavior remain deferred.

Dynamic same-ID reject enforcement mapping readiness audit:
[AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_REJECT_ENFORCEMENT_MAPPING_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_REJECT_ENFORCEMENT_MAPPING_READINESS_AUDIT.md)
selects `.438`, a narrow generated-enforcement report mapping for selected
`dynamic-id-reuse reject` policy over already generated multi-active dynamic
and mixed dynamic/static response-demux shapes. The audit changes no behavior.
The first covered shapes are bounded multiple all-dynamic write/read response
demux and bounded two-dynamic-plus-one-static mixed write/read response demux
where generated reports already expose `active_dynamic_ids_must_be_unique`,
`*_dynamic_request_no_active_same_id`, and `*_dynamic_active_id_unique`
artifacts. Single-active dynamic demux, one-dynamic mixed demux, queues,
scoreboards, direct backend behavior, and VHDL remain deferred.

Dynamic same-ID reject enforcement mapping behavior:
[AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_REJECT_ENFORCEMENT_MAPPING_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_REJECT_ENFORCEMENT_MAPPING_BEHAVIOR.md)
ships that `.438` mapping. Same-family `response-demux.<family>` plus
`same-id-ordering.<family> (dynamic-id-reuse reject)` is now accepted for the
covered multi-active all-dynamic and two-dynamic-plus-one-static mixed
response-demux shapes whose generated reports already expose
`active_dynamic_ids_must_be_unique`,
`*_dynamic_request_no_active_same_id`, and
`*_dynamic_active_id_unique` artifacts. Covered dynamic policy reports use
`implementation_status: generated_no_active_same_id_reject`,
`enforcement: generated_no_active_same_id_assertions`,
`assertion_enforcement: runtime_assertion`, and
`response_demux_covered: true`, with exact covered dynamic transactions and
generated assertion names. The new public sample is
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_same_id_reject.ppif`;
its generated IAL1/IAL0/HDL artifacts match the base multiple dynamic read
response-demux sample. Single-active dynamic demux, one-dynamic mixed demux,
queues, scoreboards, direct backend behavior, backend-language variants, and
VHDL remain deferred.

Post dynamic same-ID reject mapping selector:
[AXI_IAL2_MANAGER_POST_DYNAMIC_SAME_ID_REJECT_MAPPING_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_DYNAMIC_SAME_ID_REJECT_MAPPING_NEXT_SLICE_SELECTION.md)
selects `.440`, readiness audit for single-active dynamic same-ID reject
mapping. Single-active dynamic response-demux already exposes generated
`*_dynamic_request_idle_or_releasing`, active-match, and completion-active
assertions for write `BID`, read single-beat `RID`, and read burst-last
`RID && RLAST`, but it does not expose the `.438` multi-active
`*_dynamic_request_no_active_same_id` plus
`*_dynamic_active_id_unique` assertion pair. The audit must decide whether a
single-active-specific generated reject report contract is honest or whether
the current fail-closed behavior remains. One-dynamic mixed mapping, dynamic
queues, scoreboards, direct backend behavior, backend-language variants, VHDL,
and new generated HDL remain deferred.

Single-active dynamic same-ID reject mapping readiness audit:
[AXI_IAL2_MANAGER_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_READINESS_AUDIT](../../AXI_IAL2_MANAGER_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_READINESS_AUDIT.md)
selects `.441`, public contract selection for single-active dynamic
same-ID reject mapping. Guarded compact probes confirmed the single-active
write `BID`, read single-beat `RID`, and read burst-last `RID && RLAST`
samples expose generated `*_dynamic_request_idle_or_releasing`, active-match,
and completion-active assertions while still carrying `same_id_ordering`
residue. Temporary guarded same-ID reject probes still fail closed at the
`.438` generated multi-active no-active-same-ID diagnostic. The existing
idle-or-releasing assertions are strong enough for a single-active generated
reject contract, but they are not the `.438` multi-active evidence model, so
`.441` must select exact report fields, residue movement, and diagnostics
before behavior changes. One-dynamic mixed mapping, dynamic queues,
scoreboards, direct backend behavior, backend-language variants, VHDL, and new
generated HDL remain deferred.

Single-active dynamic same-ID reject mapping contract:
[AXI_IAL2_MANAGER_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_CONTRACT_SELECTION.md)
selects `.442`, direct implementation of the single-active dynamic same-ID
reject mapping. The selected report contract uses `implementation_status:
generated_single_active_reject`, `enforcement:
generated_idle_or_releasing_assertions`, `single_active_covered: true`, and
`single_active_request_policy: idle_or_releasing`, while preserving
`accepted_same_id_reuse: false`, `request_conflict_policy: no_active_same_id`,
and generated queue/scoreboard false. It lists generated idle-or-releasing,
active-match, and completion-active assertion names and deliberately does not
reuse the `.438` multi-active `generated_no_active_same_id_assertions` or
`generated_active_id_uniqueness_assertions` fields. `.442` is bounded to
acceptance/report/residue mapping for single-active write `BID`, read
single-beat `RID`, and read burst-last `RID && RLAST`; one-dynamic mixed
mapping, dynamic queues, scoreboards, direct backend behavior,
backend-language variants, VHDL, and new generated HDL remain deferred.

Single-active dynamic same-ID reject mapping behavior:
[AXI_IAL2_MANAGER_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_BEHAVIOR](../../AXI_IAL2_MANAGER_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_BEHAVIOR.md)
ships the `.442` mapping. Same-family `response-demux.<family>` plus
`same-id-ordering.<family> (dynamic-id-reuse reject)` is accepted for
single-active dynamic write `BID`, read single-beat `RID`, and read burst-last
`RID && RLAST` shapes that already report generated idle-or-releasing,
active-match, and completion-active assertions. Covered policy reports use
`implementation_status: generated_single_active_reject`,
`enforcement: generated_idle_or_releasing_assertions`,
`assertion_enforcement: runtime_assertion`, `response_demux_covered: true`,
`single_active_covered: true`, and `single_active_request_policy:
idle_or_releasing`, with exact assertion names. The new public sample is
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_same_id_reject.ppif`;
its generated IAL1/IAL0/HDL behavior matches the base single-active dynamic
read response-demux sample. One-dynamic mixed response-demux, dynamic queues,
scoreboards, direct backend behavior, backend-language variants, VHDL, and new
generated HDL remain deferred.

Post single-active dynamic same-ID reject mapping selector:
[AXI_IAL2_MANAGER_POST_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_NEXT_SLICE_SELECTION.md)
selects `.444`, readiness audit for one-dynamic mixed dynamic/static dynamic
same-ID reject mapping. The selector changes no behavior. The remaining
one-dynamic mixed fail-closed boundary must be compared against generated
mixed response-demux evidence: static concrete ID reservation/exclusion,
dynamic request-not-static-ID and active-not-static-ID assertions, mixed
request onehot0, response active/unique-match, and completion-active
assertions. The audit must decide whether that evidence can support a generated
reject report contract distinct from `.438` multi-active no-active-same-ID
coverage and `.442` single-active idle-or-releasing coverage, or whether the
current fail-closed behavior should remain. Dynamic queues, scoreboards,
direct backend behavior, backend-language variants, VHDL, and new generated
HDL remain deferred.

One-dynamic mixed dynamic same-ID reject mapping readiness audit:
[AXI_IAL2_MANAGER_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_READINESS_AUDIT](../../AXI_IAL2_MANAGER_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_READINESS_AUDIT.md)
selects `.445`, public report contract selection for one-dynamic mixed
dynamic/static dynamic same-ID reject mapping. Guarded schedule probes
confirmed representative mixed write, read single-beat, read burst-last,
three-static write, and three-static read burst-last samples expose static-ID
reservation/exclusion, mixed request onehot0, response active/unique-match,
and completion-active assertion evidence. A guarded temporary read probe still
failed closed at the generated multi-active no-active-same-ID diagnostic. The
evidence is ready for contract selection, but direct implementation is
deferred because one-dynamic mixed mapping needs report fields and residue
rules distinct from both `.438` multi-active and `.442` single-active
coverage. Dynamic queues, scoreboards, direct backend behavior,
backend-language variants, VHDL, and new generated HDL remain deferred.

One-dynamic mixed dynamic same-ID reject mapping contract:
[AXI_IAL2_MANAGER_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_CONTRACT_SELECTION.md)
selects `.446`, direct implementation of the one-dynamic mixed dynamic/static
dynamic same-ID reject mapping. The selected report contract covers generated
mixed write `BID`, read single-beat `RID`, and read burst-last `RID && RLAST`
response-demux shapes with exactly one dynamic transaction plus one, two, or
three pairwise-distinct concrete static transactions. Covered reports use
`implementation_status: generated_mixed_static_id_exclusion_reject`,
`enforcement: generated_static_id_exclusion_assertions`,
`mixed_dynamic_static_covered: true`,
`mixed_dynamic_static_request_policy: onehot0_mixed_request`,
`static_id_conflict_policy: static_concrete_ids_reserved`, and
`static_id_exclusion_policy: dynamic_id_must_not_equal_static_concrete_id`,
while preserving `accepted_same_id_reuse: false`,
`request_conflict_policy: no_active_same_id`, and generated queue/scoreboard
false. `.446` is bounded to acceptance/report/residue mapping over existing
static-ID exclusion, mixed request onehot0, response active/unique-match, and
completion-active evidence; queues, scoreboards, direct backend behavior,
backend-language variants, VHDL, new generated HDL, and new generated rules,
storage, assertions, or runtime behavior remain deferred.

One-dynamic mixed dynamic same-ID reject mapping behavior:
[AXI_IAL2_MANAGER_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_BEHAVIOR](../../AXI_IAL2_MANAGER_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_BEHAVIOR.md)
ships the `.446` mapping. Same-family `response-demux.<family>` plus
`same-id-ordering.<family> (dynamic-id-reuse reject)` is accepted for
generated mixed write `BID`, read single-beat `RID`, and read burst-last
`RID && RLAST` shapes with exactly one dynamic transaction plus one, two, or
three pairwise-distinct concrete static transactions. Covered reports use
`implementation_status: generated_mixed_static_id_exclusion_reject`,
`enforcement: generated_static_id_exclusion_assertions`,
`mixed_dynamic_static_covered: true`, and
`static_id_exclusion_policy: dynamic_id_must_not_equal_static_concrete_id`,
with exact static-ID reservations and generated mixed assertion names. `.446`
adds no public PPIF sample or support-accounting entry; focused tests inject
the same-ID policy into existing mixed response-demux samples and prove
generated IAL1/IAL0 artifacts match the originals. Dynamic queues,
scoreboards, direct backend behavior, backend-language variants, VHDL, new
generated HDL, and new generated rule/storage/assertion/runtime behavior
remain deferred. `.446` selects `.447`, the next post-mapping selector.

Post one-dynamic mixed dynamic same-ID reject mapping selector:
[AXI_IAL2_MANAGER_POST_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_NEXT_SLICE_SELECTION.md)
selects `.448`, readiness audit for the public dynamic same-ID
`issue-order-queue` policy contract after all bounded `dynamic-id-reuse
reject` mappings shipped. The selector changes no behavior and accepts no new
source values. It puts issue-order queue contract readiness before scoreboard
because concrete same-ID queue-head behavior is the closest bounded
precedent, while dynamic scoreboard behavior has a different
completion-tracking promise. `.448` must decide whether
`dynamic-id-reuse issue-order-queue` becomes metadata-first
selected-not-generated policy, remains unsupported until generated queue
behavior is selected, or needs a narrower prerequisite.

Dynamic same-ID issue-order queue policy readiness:
[AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_POLICY_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_POLICY_READINESS_AUDIT.md)
selects `.449`, public dynamic same-ID `issue-order-queue` policy contract
selection. The audit changes no behavior and keeps
`dynamic-id-reuse issue-order-queue` and `dynamic-id-reuse scoreboard`
unsupported. It rejects direct generated dynamic queue behavior as too large
for one slice, direct parser/report implementation as premature without a
contract, and scoreboard as a separate policy with different
completion-tracking semantics. `.449` must decide source spelling,
metadata-first report fields, selected-not-generated boundary, residue,
diagnostics, support-accounting impact, validation gates, and non-goals before
any parser or generated behavior change.

Dynamic same-ID issue-order queue policy contract:
[AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_POLICY_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_POLICY_CONTRACT_SELECTION.md)
selects `.450`, metadata-first parser/report implementation for dynamic
same-ID `issue-order-queue` policy. The selected source spelling is
family-local `(dynamic-id-reuse issue-order-queue)` under `same-id-ordering`
read/write arms. `.450` must accept and report the selected metadata as
`implementation_status: selected_not_generated`, `enforcement:
not_generated`, `accepted_same_id_reuse: false`, `generated_queue_behavior:
false`, and residue `dynamic_per_id_issue_order_queues`, while keeping dynamic
`scoreboard` unsupported and avoiding generated dynamic queue, HDL, direct
backend, or accepted-reuse behavior.

Dynamic same-ID issue-order queue policy metadata-first behavior:
[AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_POLICY_METADATA_FIRST_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_POLICY_METADATA_FIRST_BEHAVIOR.md)
ships `.450`, metadata-first parser/report support for
`dynamic-id-reuse issue-order-queue`. The public support-accounted PPIF sample
is
`ppif/axi_manager_capacity_status_dynamic_same_id_issue_order_queue_policy.ppif`.
It lowers to the same generated IAL1/IAL0 artifacts as the base dynamic
transaction-ID metadata sample and reports `issue_order_queue` with
`implementation_status: selected_not_generated`, `accepted_same_id_reuse:
false`, `generated_queue_behavior: false`, `generated_scoreboard_behavior:
false`, and `dynamic_per_id_issue_order_queues` residue. Dynamic
`scoreboard`, generated dynamic queues, accepted dynamic same-ID reuse, HDL,
VHDL, direct backend behavior, and backend-language variants remain deferred.
`.450` selects `.451`, the next dynamic same-ID policy selector.

Post dynamic same-ID issue-order queue metadata selector:
[AXI_IAL2_MANAGER_POST_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_NEXT_SLICE_SELECTION.md)
selects `.452`, readiness audit for generated dynamic same-ID
`issue-order-queue` behavior. The selector changes no behavior. It chooses
queue readiness before scoreboard because `.450` made
`dynamic_per_id_issue_order_queues` explicit and user-visible, while dynamic
scoreboard remains a separate unsupported policy with different
completion-tracking semantics. `.452` must decide whether generated dynamic
queue behavior can move to contract selection, needs a narrower prerequisite,
or remains deferred.

Generated dynamic same-ID issue-order queue readiness:
[AXI_IAL2_MANAGER_GENERATED_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_GENERATED_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md)
selects `.453`, public contract selection for generated dynamic same-ID
`issue-order-queue` behavior. The audit changes no behavior. The dynamic
response-demux substrate is mature enough for a contract pass, but direct
generated queue behavior still needs the public family/scope, runtime-ID queue
key, entry state, admitted enqueue, dequeue, response matching, ordering
guarantees, overflow/ambiguity assertions, report fields, and residue movement
selected first.

Generated dynamic same-ID issue-order queue contract:
[AXI_IAL2_MANAGER_GENERATED_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_GENERATED_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md)
selects `.454`, runtime-ID queue-state representation selection for the first
generated dynamic same-ID `issue-order-queue` behavior. The selector changes
no behavior. It chooses the all-dynamic write `BID` path as the first
generated family, while direct behavior waits for an explicit representation
contract that replaces reject-only active-ID uniqueness proofs with
runtime-ID queue state, enqueue/dequeue semantics, response matching,
same-cycle policy, overflow/ambiguity assertions, report fields, and residue
movement.

Dynamic runtime-ID queue-state representation:
[AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_ID_QUEUE_STATE_REPRESENTATION_SELECTION](../../AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_ID_QUEUE_STATE_REPRESENTATION_SELECTION.md)
selects `.455`, implementation of the bounded two-transaction all-dynamic
write `BID` dynamic issue-order queue behavior. The selector changes no
behavior. It chooses `compact_runtime_id_issue_order_slots`: each queue slot
stores one-hot transaction identity plus a slot-local captured runtime ID, and
`BID` response demux selects the earliest valid slot whose captured ID matches
the response. Same-ID overlaps are ordered by slot age, different-ID slot1
responses may complete ahead of slot0, same-cycle selected dequeue plus one
enqueue is supported, and reject-only active-ID uniqueness assertions remain
exclusive to `dynamic-id-reuse reject`.

Dynamic write same-ID issue-order queue behavior:
[AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md)
ships `.455`, generated bounded behavior for exactly two all-dynamic write
transactions with explicit generated `response-demux.write` and
`same-id-ordering.write (dynamic-id-reuse issue-order-queue)`. The public
sample is
`ppif/axi_manager_capacity_status_dynamic_write_same_id_issue_order_queue.ppif`.
It generates `axi0_awid`/`axi0_bid` inputs, slot-local transaction bits,
slot-local captured `AWID` registers, generated `BID` completion rules for
`w0` and `w1`, and queue-specific assertions.

The generated write response-demux reports
`bounded_dynamic_write_bid_issue_order_queue_demux_contract`,
`generated_dynamic_issue_order_queue_demux`,
`earliest_matching_captured_runtime_id`,
`compact_runtime_id_issue_order_slots`, and
`dynamic_issue_order_earliest_matching_slot`. A `BID` response selects the
earliest valid slot whose captured ID matches. If both slots hold the same
captured ID, slot0 completes first; if slot0 has a different ID and slot1
matches, slot1 may complete ahead of slot0.

The same-ID ordering report now marks the covered write family as generated:
`implementation_status: generated_dynamic_write_bid_issue_order_queue`,
`accepted_same_id_reuse: true`, `generated_queue_behavior: true`,
`same_id_overlap_policy: allowed_by_issue_order_queue`,
`multi_match_policy: earliest_matching_slot`, and
`active_id_uniqueness_policy: not_required_for_issue_order_queue`. Dynamic
read queues, broader write cardinalities, mixed dynamic/static queues,
dynamic scoreboards, direct backend behavior, backend-language variants, and
VHDL remain future exact owners. `.456` is the next selector after this
behavior.

Post dynamic write same-ID issue-order queue selector:
[AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md)
selects `.457`, readiness audit for generated dynamic read same-ID
`issue-order-queue` behavior. The selector changes no behavior. It chooses
read queue readiness before broader write cardinality, mixed dynamic/static
queues, scoreboards, validation retry, direct backend, backend-language
variants, or VHDL because existing generated dynamic read behavior already has
single-beat `RID`, burst-last `RID && RLAST`, read-data, raw `ARLEN`/runtime
validation, multi-beat output-bank, and recapture consumers that a queue
implementation must preserve.

Dynamic read same-ID issue-order queue readiness audit:
[AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md)
selects `.458`, public contract selection for the first generated dynamic
read same-ID `issue-order-queue` behavior. The audit changes no behavior. It
chooses all-dynamic read single-beat `RID` before direct behavior or
burst-last `RID && RLAST` because the single-beat shape can reuse the
runtime-ID queue model without final-beat-only dequeue, raw non-final beats,
`RLAST`, read-data, raw `ARLEN`, runtime validation, multi-beat, or recapture
consumer coupling. Burst-last queues, read-data over queues, broader queue
cardinality, mixed dynamic/static queues, scoreboards, direct backend,
backend-language variants, and VHDL remain future exact owners.

Dynamic read single-beat same-ID issue-order queue contract:
[AXI_IAL2_MANAGER_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md)
selects `.459`, implementation of the bounded two-transaction all-dynamic
read single-beat `RID` dynamic same-ID `issue-order-queue` behavior. The
selector changes no behavior. The selected public shape requires exactly two
dynamic read transactions, `same-id-ordering.read (dynamic-id-reuse
issue-order-queue)`, explicit generated `response-demux.read` with
`response-scope single-beat`, `compact_runtime_id_issue_order_slots`,
slot-local captured `ARID`, earliest matching `RID` response demux,
same-cycle selected dequeue plus one enqueue, and queue-specific assertions.
The future public sample is
`ppif/axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue.ppif`.
Read burst-last, read-data over queues, raw `ARLEN`/runtime, multi-beat,
broader queue cardinality, mixed dynamic/static queues, scoreboards, direct
backend behavior, backend-language variants, and VHDL remain future exact
owners.

Dynamic read single-beat same-ID issue-order queue behavior:
[AXI_IAL2_MANAGER_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md)
ships `.459`, generated bounded two-transaction all-dynamic read single-beat
`RID` dynamic same-ID `issue-order-queue` behavior. The public support-
accounted sample is
`ppif/axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue.ppif`.
FSMGen now generates compact runtime-ID issue-order slots with slot-local
captured `ARID`, earliest matching `RID` response demux, same-cycle selected
dequeue plus one enqueue, generated `r0`/`r1` completion outputs,
queue-specific assertions, and report mode
`bounded_dynamic_read_rid_issue_order_queue_demux_contract`.
The same-ID ordering read policy reports
`generated_dynamic_read_rid_issue_order_queue`,
`first_generated_scope: read_rid_two_dynamic_transactions`,
`accepted_same_id_reuse: true`, and no same-ID ordering residue for the
covered read family. Read burst-last queues, read-data over dynamic queues,
raw `ARLEN`/runtime, multi-beat output banks, broader queue cardinality,
mixed dynamic/static queues, scoreboards, direct backend behavior,
backend-language variants, and VHDL remain future exact owners. `.459`
selects `.460`, a post dynamic read single-beat same-ID issue-order queue
selector.

Post dynamic read single-beat same-ID issue-order queue selector:
[AXI_IAL2_MANAGER_POST_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md)
selects `.461`, readiness audit for generated dynamic read burst-last
`RID && RLAST` same-ID `issue-order-queue` behavior. The selector changes no
behavior. Burst-last readiness is next because the shipped dynamic read queue
path covers only `response-scope single-beat`, while the burst-last sibling
must settle final-beat-only dequeue, raw non-final beat policy,
`RLAST`/`response-scope`/`last-signal` requirements, selected-match
assertions, downstream read-data/burst/runtime/multi-beat/recapture
preservation, report/residue/support/sample/validation, rollback, and
explicit residue before behavior changes. Read-data over queues, raw
`ARLEN`/runtime over queues, multi-beat output banks over queues, broader
queue cardinality, mixed dynamic/static queues, scoreboards, validation retry,
direct backend behavior, backend-language variants, and VHDL remain future
exact owners.

Dynamic read burst-last same-ID issue-order queue readiness:
[AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md)
selects `.462`, public contract selection for generated dynamic read
burst-last `RID && RLAST` same-ID `issue-order-queue` behavior. The readiness
audit changes no behavior. It found no lower parser, report-schema, IAL1,
IAL0, or SystemVerilog prerequisite because burst-last response-demux
metadata, one-bit `RLAST` input lowering, compact runtime-ID queue slots,
final dynamic `RID && RLAST` completions, raw non-final dynamic beat
assertions, and concrete burst-last queue-head non-last no-dequeue semantics
already exist. Direct behavior still needs public contract selection for
final-beat-only selected dequeue, raw non-final beat preservation, `RLAST`
requirements, selected completion and report vocabulary, queue assertions,
residue/support/sample/validation, and downstream read-data/burst/runtime/
multi-beat/recapture preservation.

Dynamic read burst-last same-ID issue-order queue contract:
[AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md)
selects `.463`, direct implementation of the first generated dynamic read
burst-last `RID && RLAST` same-ID `issue-order-queue` behavior. The contract
changes no behavior. It selects exactly two all-dynamic reads, explicit
`response-demux.read` with `response-scope burst-last` and one-bit
`last-signal`, compact runtime-ID issue-order slots, raw `RID` beat matching
without `RLAST`, selected final dequeue and generated completion only on the
earliest matching captured runtime ID plus `RLAST`, mode
`bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract`, completion
source `generated_dynamic_issue_order_queue_demux_last_beat`, implementation
status `generated_dynamic_read_rid_rlast_issue_order_queue`, and first scope
`read_rid_rlast_two_dynamic_transactions`. Read-data over generated dynamic
read queues, raw `ARLEN`, runtime validation, multi-beat output banks, queue
recapture widening, broader queue cardinality, mixed dynamic/static queues,
scoreboards, direct backend behavior, backend-language variants, and VHDL
remain future exact owners.

Dynamic read burst-last same-ID issue-order queue behavior:
[AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md)
ships `.463`, generated bounded two-transaction all-dynamic read burst-last
`RID && RLAST` dynamic same-ID `issue-order-queue` behavior. The public sample
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue.ppif`
uses exactly two dynamic reads, `same-id-ordering.read
(dynamic-id-reuse issue-order-queue)`, explicit generated
`response-demux.read`, `response-scope burst-last`, and one-bit
`last-signal axi0_rlast`. FSMGen generates compact runtime-ID queue slots with
slot-local `ARID`, raw earliest matching `RID` response ownership, final
completion/dequeue only on earliest matching captured runtime ID plus `RLAST`,
same-cycle selected final dequeue plus one enqueue, and queue assertions
including non-final no-dequeue. Reports use
`bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract`,
`generated_dynamic_issue_order_queue_demux_last_beat`,
`generated_dynamic_read_rid_rlast_issue_order_queue`, and
`first_generated_scope: read_rid_rlast_two_dynamic_transactions`. Read-data
over generated dynamic read queues, raw `ARLEN`, runtime validation,
multi-beat output banks, broader queue cardinality, mixed dynamic/static
queues, scoreboards, direct backend behavior, backend-language variants, and
VHDL remain future exact owners.

Post dynamic read burst-last same-ID issue-order queue selector:
[AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md)
selects `.465`, readiness audit for read-data routing over generated dynamic
read same-ID `issue-order-queue` response-demux pulses. The selector changes
no behavior. Read-data is next because generated dynamic read same-ID queues
now ship both single-beat `RID` and burst-last `RID && RLAST` completion
sources, while read-data over generated dynamic read queues remains explicitly
unowned. The audit must decide whether the first behavior owner is scalar
single-beat over generated dynamic read single-beat queues, scalar last-beat
over generated dynamic read burst-last queues, a paired bounded scalar
contract, a report/static cleanup prerequisite, a lower-layer prerequisite, or
deferral. Raw `ARLEN`, runtime validation, multi-beat output banks, queue
recapture widening, broader queue cardinality, mixed dynamic/static queues,
scoreboards, direct backend behavior, backend-language variants, and VHDL
remain future exact owners.

Dynamic read same-ID issue-order queue read-data readiness:
[AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_READINESS_AUDIT.md)
selects `.466`, public contract selection for paired bounded scalar read-data
routing over generated dynamic read same-ID `issue-order-queue` completions.
The readiness audit changes no behavior. It selects a paired contract because
generated dynamic read same-ID queues now ship both single-beat
`generated_dynamic_issue_order_queue_demux` and burst-last
`generated_dynamic_issue_order_queue_demux_last_beat` completion sources, and
the ordinary generated dynamic read-data path already supports the matching
scalar single-beat and scalar last-beat public syntax. `.466` must pin the
public source shape, sample identities, report keys, diagnostics, residue,
validation, rollback, and queue-specific read-data completion validity names
`generated_dynamic_read_issue_order_queue_response_demux_completion_pulse` and
`generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse`
before behavior changes. Raw `ARLEN`, runtime validation, multi-beat output
banks, queue recapture widening, broader queue cardinality, mixed
dynamic/static queues, scoreboards, direct backend behavior, backend-language
variants, and VHDL remain future exact owners.

Dynamic read same-ID issue-order queue read-data contract:
[AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_CONTRACT_SELECTION.md)
selects `.467`, direct implementation of paired bounded scalar read-data
routing over generated dynamic read same-ID `issue-order-queue` completions.
The contract-selection slice changes no behavior. It reuses existing
`read-data.read` syntax and selects two public samples:
`ppif/axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue_read_data.ppif`
and
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data.ppif`.
The implementation must cover exactly two all-dynamic read transactions with
complete scalar transaction bindings, keep the underlying queue response-demux
modes and sources, report
`generated_dynamic_read_issue_order_queue_response_demux_completion_pulse` for
single-beat capture and
`generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse`
for last-beat capture, and leave raw `ARLEN`, runtime validation, multi-beat
output banks, queue recapture widening, broader queue cardinality, mixed
dynamic/static queues, scoreboards, direct backend behavior, backend-language
variants, and VHDL as future exact owners.

Dynamic read same-ID issue-order queue read-data behavior:
[AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BEHAVIOR.md)
ships `.467`, paired scalar read-data routing over generated dynamic read
same-ID `issue-order-queue` completions. The public samples are
`ppif/axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue_read_data.ppif`
and
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data.ppif`.
The single-beat shape reports
`generated_dynamic_read_issue_order_queue_response_demux_completion_pulse`;
the last-beat shape reports
`generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse`.
Both shapes keep the response-demux queue-owned, bind exactly `r0` and `r1`,
generate scalar `RDATA`/`RRESP` capture, and leave the report-only raw
`ARLEN` scalar last-beat sibling to `.469`. Runtime validation, multi-beat
output banks, broader queues, mixed dynamic/static queues, scoreboards,
direct backend behavior, backend-language variants, and VHDL remain future
exact owners.

Dynamic read same-ID issue-order queue read-data raw-ARLEN readiness:
[AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md)
selected `.469`, direct bounded implementation of report-only raw-`ARLEN`
burst-length capture over generated dynamic read same-ID `issue-order-queue`
last-beat read-data. Existing `read-data.read` `burst-length` syntax is
sufficient, so no new public contract-selection leaf was required. The
selected support-accounted sample is
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length.ppif`.

Dynamic read same-ID issue-order queue read-data raw-ARLEN behavior:
[AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_BEHAVIOR.md)
ships the `.469` support-accounted sample. The generator admits only the
exact two-transaction all-dynamic burst-last queue shape with
`validation report-only`, keeps completion validity
`generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse`,
adds generated `axi0_arlen`, per-transaction raw-`ARLEN` storage
`axi0_r0_arlen_q`/`axi0_r1_arlen_q`, and request-capture rules
`axi0_r0_burst_length_capture`/`axi0_r1_burst_length_capture`. The `.467`
no-`burst-length` queue samples remain unchanged.

Dynamic read same-ID issue-order queue read-data runtime-validation readiness:
[AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md)
selects `.471`, direct bounded implementation of runtime beat-count/`RLAST`
validation over the generated dynamic read same-ID `issue-order-queue`
last-beat raw-`ARLEN` shape. Existing `read-data.read` `burst-length` syntax
already covers `(validation runtime-assertion)`, so no new public
contract-selection leaf is required. The selected future sample is
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif`.
`.470` changes no parser, generator, PPIF sample, support accounting,
validation behavior, generated artifact, test, JSON, HDL, runtime behavior,
direct backend behavior, backend-language variant, or VHDL behavior.
Multi-beat output banks, queue recapture widening, broader queues, mixed
dynamic/static queues, scoreboards, direct backend behavior,
backend-language variants, and VHDL remain future exact owners.

Dynamic read same-ID issue-order queue read-data runtime-validation behavior:
[AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md)
ships the `.471` support-accounted sample
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif`.
The generator admits only the exact two-transaction all-dynamic burst-last queue
shape with `validation runtime-assertion`, keeps completion validity
`generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse`,
and emits per-transaction expected-beat storage, read-beat counters,
request-time `ARLEN[4:0] + 5'd1` initialization, matched queue read-beat
increments, and four beat-count/`RLAST` assertions per transaction. The `.469`
report-only raw-`ARLEN` sample remains supported.

Dynamic read same-ID issue-order queue read-data multi-beat readiness:
[AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md)
selects `.473`, direct bounded implementation of multi-beat output banks over
the generated dynamic read same-ID `issue-order-queue` runtime-validation
read-data boundary. Existing `read-data.read` multi-beat syntax already covers
per-beat status, worst-observed aggregation, multi-beat-by-RID interleaving,
runtime-assertion `burst-length`, and complete per-transaction output-bank
bindings. The `.472` audit changes no behavior: a guarded temporary queue
multi-beat candidate failed closed only at the local dynamic issue-order queue
read-data coverage gate. Queue recapture widening, broader queue cardinality,
mixed dynamic/static queues, scoreboards, direct backend behavior,
backend-language variants, and VHDL remain future exact owners.

Dynamic read same-ID issue-order queue read-data multi-beat behavior:
[AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_BEHAVIOR.md)
ships the `.473` support-accounted sample
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_multi_beat.ppif`.
The generator admits only the exact two-transaction all-dynamic burst-last
queue shape with runtime-assertion `ARLEN` metadata and multi-beat
output-bank bindings. Schedule JSON reports
`bounded_multi_beat_read_data_contract`, completion validity
`generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse`,
matched-beat source `response_demux_matched_read_beat`, per-transaction valid
masks, length outputs, worst-observed scalar `RRESP` aggregates, and empty
read-data residue. For the default 16-beat sample the generated artifacts
include 32 `RDATA` lanes, 32 `RRESP` lanes, output-bank init rules, lane
capture rules, aggregate update rules, and the `.471` raw-`ARLEN`,
expected-beat/read-beat counter, and beat-count/`RLAST` assertion artifacts.
The `.467`, `.469`, and `.471` queue read-data samples remain supported.
Queue recapture widening is the next audit owner; broader queue cardinality,
mixed dynamic/static queues, scoreboards, direct backend behavior,
backend-language variants, and VHDL remain future exact owners.

Dynamic read same-ID issue-order queue recapture readiness:
[AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_RECAPTURE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_RECAPTURE_READINESS_AUDIT.md)
selects `.475`, public report/static contract selection for generated dynamic
same-ID `issue-order-queue` same-cycle selected-dequeue-plus-enqueue
recapture. The audit changes no behavior and found existing emitted
same-cycle dequeue-plus-enqueue queue rules, but `.475` narrows the public
contract before any positive report field is added.

Dynamic same-ID issue-order queue recapture report contract:
[AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_RECAPTURE_REPORT_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_RECAPTURE_REPORT_CONTRACT_SELECTION.md)
selects `.476`, readiness audit for identity-preserving same-transaction
queue recapture ID refresh. Current queue reports keep
`generated_update_rules` as literal emitted-rule lists under
`same_id_ordering.dynamic_id_reuse_policy.*.generated_queues[]`; classic
`same_cycle_release_recapture_policy` and `release_recapture_*` fields remain
exclusive to dynamic response-demux capture state until that audit settles the
identity-preserving case.

Dynamic same-ID issue-order queue identity recapture readiness:
[AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_READINESS_AUDIT.md)
selects `.477`, direct implementation of state-key-preserving dynamic queue
recapture ID refresh. The audit found the prior transition builder omitted
same-transaction selected-dequeue-plus-enqueue rules such as
`r0_dequeue_enqueue_r0` and `w0_dequeue_enqueue_w0`, even though the affected
slot ID must refresh from the current `ARID` or `AWID`.

Dynamic same-ID issue-order queue identity recapture behavior:
[AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_BEHAVIOR.md)
ships state-key-preserving same-transaction queue recapture ID refresh for the
generated two-transaction dynamic queue families. The emitted
`generated_update_rules` list now includes one-entry and tail-selected refresh
forms such as `r0_dequeue_enqueue_r0`, `r1_r0_dequeue_enqueue_r0`,
`w0_dequeue_enqueue_w0`, and `w1_w0_dequeue_enqueue_w0`; those rules refresh
the affected slot ID from current `ARID` or `AWID`.

Dynamic same-ID issue-order queue identity recapture report contract:
[AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_REPORT_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_REPORT_CONTRACT_SELECTION.md)
selects queue-owned public report fields for the shipped identity recapture
behavior. `.479` ships
`same_transaction_recapture_policy: refresh_captured_request_id`,
`same_transaction_recapture_rule_scope:
state_key_preserving_selected_dequeue_enqueue`, and
`same_transaction_recapture_id_source` under each generated dynamic queue
entry, with the ID source set to `axi0_awid` for write BID queues and
`axi0_arid` for read RID/RID-and-RLAST queues. `generated_update_rules`
remains the literal emitted-rule evidence, and `release_recapture_*` fields
remain exclusive to response-demux capture state.

Dynamic same-ID issue-order queue identity recapture report behavior:
[AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_REPORT_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_REPORT_BEHAVIOR.md)
documents the shipped queue-owned `same_transaction_*` report fields and the
negative contract that classic response-demux recapture fields do not appear
inside generated queue entries.

Post dynamic queue recapture report selector:
[AXI_IAL2_MANAGER_POST_DYNAMIC_QUEUE_RECAPTURE_REPORT_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_DYNAMIC_QUEUE_RECAPTURE_REPORT_NEXT_SLICE_SELECTION.md)
selects `.481`, readiness audit for one generated all-dynamic write BID
same-ID `issue-order-queue` widened from two transactions to a bounded
depth-3, three-transaction queue.
Other broader queue cardinality, mixed dynamic/static queues, scoreboards,
direct backend behavior, backend-language variants, and VHDL remain future
exact owners.

Dynamic write depth-3 same-ID issue-order queue readiness audit:
[AXI_IAL2_MANAGER_DYNAMIC_WRITE_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_WRITE_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md)
selects `.482`, direct bounded implementation for exactly three all-dynamic
write transactions, generated BID response-demux completion,
`write-max-pending` at least 3, and one depth-3 queue. The audit found the
current behavior blocker is local to the dynamic queue admission/storage gate:
it still requires depth 2 and exactly two transactions. Transition,
assignment, state-expression, selected-match, assertion, and report helpers
are already queue-depth and transaction-list driven. Read depth-3 queues,
read-data, mixed dynamic/static queues, scoreboards, arbitrary cardinality,
direct backend behavior, backend-language variants, and VHDL remain future
exact owners.

Dynamic write depth-3 same-ID issue-order queue behavior:
[AXI_IAL2_MANAGER_DYNAMIC_WRITE_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_WRITE_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md)
ships generated support through
`ppif/axi_manager_capacity_status_dynamic_write_depth3_same_id_issue_order_queue.ppif`.
The generated write queue covers `w0`, `w1`, and `w2`, allocates three compact
runtime-ID issue-order slots, captures `AWID` per slot, completes by earliest
matching `BID`, reports
`first_generated_scope: write_bid_three_dynamic_transactions`, and keeps the
queue-owned same-transaction captured-ID refresh fields. Ambiguous depth-3
cross-transaction selected-dequeue-plus-enqueue rules include the selected
dequeued transaction in the generated rule name; existing depth-2 and
same-transaction refresh names remain stable.

Post dynamic write depth-3 same-ID issue-order queue selector:
[AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md)
selects `.484`, readiness audit for generated all-dynamic read single-beat
`RID` same-ID `issue-order-queue` cardinality widening from two transactions
to one bounded depth-3, three-transaction queue. Read single-beat is the
smallest read-side depth-3 audit after the write proof because it adds
generated `RID` completion without `RLAST`, read-data, raw `ARLEN`, runtime
validation, output banks, mixed static-ID exclusion, or scoreboard semantics.
Backend-language variants and external converters such as `sv2v` remain
outside this IAL2 slice; FSMGen-owned generation/lowering remains the default
under the backend portability frontier.

Dynamic read depth-3 same-ID issue-order queue readiness audit:
[AXI_IAL2_MANAGER_DYNAMIC_READ_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_READ_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md)
selects `.485`, direct bounded implementation of one generated all-dynamic
read single-beat `RID` same-ID `issue-order-queue` with exactly three dynamic
read transactions, generated single-beat `RID` response-demux completion,
`read-max-pending` at least 3, and queue depth 3. The audit found the
remaining blocker is local to the dynamic read planner and shared builder
gate. A lightweight helper probe produced 99 transition rules, 19 assertions,
zero duplicate names, the disambiguated cross-transaction rule, the
tail-selected refresh rule, and the `r2` completion-selected-match assertion.
Read burst-last depth-3, read-data over depth-3 queues, mixed dynamic/static
queues, scoreboards, arbitrary cardinality, backend-language variants,
external converter dependencies, and VHDL remain deferred.

Dynamic read depth-3 same-ID issue-order queue behavior:
[AXI_IAL2_MANAGER_DYNAMIC_READ_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_READ_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md)
ships generated support through
`ppif/axi_manager_capacity_status_dynamic_read_depth3_same_id_issue_order_queue.ppif`.
The generated read queue covers `r0`, `r1`, and `r2`, allocates three compact
runtime-ID issue-order slots, captures `ARID` per slot, completes by earliest
matching single-beat `RID`, reports
`first_generated_scope: read_rid_three_dynamic_transactions`, and keeps the
queue-owned same-transaction captured-ID refresh fields. Ambiguous depth-3
cross-transaction selected-dequeue-plus-enqueue rules include the selected
dequeued transaction in the generated rule name; existing depth-2 read and
depth-3 write queue behavior remains stable. Read burst-last depth-3,
read-data over depth-3 queues, mixed dynamic/static queues, scoreboards,
arbitrary cardinality, direct backend behavior, backend-language variants,
external converter dependencies, and VHDL remain deferred.

Post dynamic read depth-3 same-ID issue-order queue selector:
[AXI_IAL2_MANAGER_POST_DYNAMIC_READ_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_DYNAMIC_READ_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md)
selects `.487`, readiness audit for generated all-dynamic read burst-last
`RID && RLAST` same-ID `issue-order-queue` cardinality widening from the
shipped two-transaction dynamic read burst-last queue to one bounded depth-3,
three-transaction queue. It is the smallest next audit because `.485` proves
the read depth-3 runtime-ID queue shape and `.463` proves RLAST-gated dynamic
read queue semantics. Read-data over depth-3 queues, mixed dynamic/static
queues, scoreboards, arbitrary cardinality, direct backend behavior,
backend-language variants, external converter dependencies such as `sv2v`,
and VHDL remain deferred; FSMGen-owned generation/lowering remains the
default.

Dynamic read burst-last depth-3 same-ID issue-order queue readiness audit:
[AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md)
selects `.488`, direct bounded implementation of one generated all-dynamic
read burst-last `RID && RLAST` same-ID `issue-order-queue` with exactly three
dynamic read transactions, one-bit `last_signal`, `read-max-pending` at least
3, and queue depth 3. The audit found only local planner, builder, and RLAST
scope-reporting gates. A direct helper probe produced 99 transition rules, 20
assertions, zero duplicate names, the non-final no-dequeue assertion, the
slot2 onehot assertion, the `r2` completion-selected-match assertion, the
tail-selected recapture rule, and the disambiguated cross-transaction enqueue
rule. Read-data over depth-3 queues, mixed dynamic/static queues, scoreboards,
arbitrary cardinality, backend-language variants, external converter
dependencies, and VHDL remain deferred.

Dynamic read burst-last depth-3 same-ID issue-order queue behavior:
[AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md)
ships `.488`, generated support through
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue.ppif`.
The generated read queue covers `r0`, `r1`, and `r2`, allocates three compact
runtime-ID issue-order slots, captures `ARID` per slot, and completes by
earliest matching captured `RID` plus one-bit `axi0_rlast`. Matching
non-final beats do not dequeue the queue. The report uses
`bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract`,
`generated_dynamic_issue_order_queue_demux_last_beat`,
`read_rid_rlast_three_dynamic_transactions`, queue depth 3, and queue-owned
same-transaction captured-ID refresh fields. Existing depth-2 RLAST queues,
depth-3 single-beat read queues, and depth-3 write queues remain stable.
Read-data over depth-3 queues, mixed dynamic/static queues, scoreboards,
arbitrary cardinality, direct backend behavior, backend-language variants,
external converter dependencies such as `sv2v`, and VHDL remain deferred;
FSMGen-owned generation/lowering remains the default.

Post dynamic read burst-last depth-3 same-ID issue-order queue selector:
[AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md)
selects `.490`, readiness audit for scalar last-beat read-data over the
generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID
`issue-order-queue` behavior shipped in `.488`. The selector is next because
`.488` now provides the missing three-transaction queue-owned last-beat
completion source, the `.467`/`.469`/`.471`/`.473` chain proves
two-transaction dynamic issue-order queue read-data, and the concrete
depth-3 queue-head chain shows depth-3 read-data needs explicit audit
ownership before implementation. Mixed dynamic/static queues, scoreboards,
arbitrary cardinality, direct backend behavior, backend-language variants,
external converter dependencies such as `sv2v`, and VHDL remain deferred;
FSMGen-owned generation/lowering remains the default.

Dynamic read burst-last depth-3 same-ID issue-order queue read-data readiness:
[AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_READINESS_AUDIT.md)
selects `.491`, direct bounded implementation of scalar last-beat read-data
over the generated all-dynamic read burst-last `RID && RLAST` depth-3
same-ID `issue-order-queue`. A RAM-guarded temporary candidate with
`r0`/`r1`/`r2` failed closed at the local dynamic issue-order queue read-data
coverage gate, which still requires exactly two dynamic transactions and one
depth-2 queue. No parser or lower artifact prerequisite was exposed. The
direct owner, shipped in `.491`, adds the support-accounted
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data.ppif`
sample and widens only scalar last-beat read-data coverage/report
expectations for the exact three-transaction queue. Raw `ARLEN`, runtime
beat-count/`RLAST` validation, multi-beat output banks, mixed dynamic/static
queues, scoreboards, arbitrary cardinality, direct backend behavior,
backend-language variants, external converter dependencies such as `sv2v`,
and VHDL remain deferred; FSMGen-owned generation/lowering remains the
default.

Dynamic read burst-last depth-3 same-ID issue-order queue read-data behavior:
[AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BEHAVIOR.md)
ships `.491`, scalar last-beat read-data over the generated all-dynamic
read burst-last `RID && RLAST` depth-3 same-ID `issue-order-queue` through
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data.ppif`.
The generated capture covers `r0`, `r1`, and `r2`, binds each
`axi0_r*_read_data_capture` rule to the generated queue completion pulse,
and captures `axi0_rdata`/`axi0_rresp` into `axi0_r*_last_rdata`/
`axi0_r*_last_rresp`. The report keeps the `.488` queue contract,
`read_rid_rlast_three_dynamic_transactions`, and
`generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse`.
Raw `ARLEN`, runtime beat-count/`RLAST` validation, multi-beat output banks,
mixed dynamic/static queues, scoreboards, arbitrary cardinality, direct
backend behavior, backend-language variants, external converter dependencies
such as `sv2v`, and VHDL remain deferred; FSMGen-owned generation/lowering
remains the default.

Post dynamic read burst-last depth-3 same-ID issue-order queue read-data
selector:
[AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_NEXT_SLICE_SELECTION.md)
selects `.493`, readiness audit for report-only raw `ARLEN` burst-length
capture over the generated all-dynamic read burst-last `RID && RLAST`
depth-3 same-ID `issue-order-queue` scalar read-data shipped in `.491`.
This is the smallest adjacent owner because `.491` supplies the exact
three-transaction scalar last-beat queue read-data surface, while `.469`
already proves report-only raw `ARLEN` over the two-transaction dynamic
RLAST queue. Runtime validation, multi-beat output banks, mixed
dynamic/static queues, scoreboards, arbitrary cardinality,
verification-code generation, direct backend behavior, backend-language
variants, external converter dependencies such as `sv2v`, and VHDL remain
deferred; FSMGen-owned generation/lowering remains the default.

Dynamic read burst-last depth-3 same-ID issue-order queue read-data
raw-`ARLEN` readiness:
[AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md)
selects `.494`, direct bounded implementation of report-only raw `ARLEN`
burst-length capture over the generated all-dynamic read burst-last
`RID && RLAST` depth-3 same-ID `issue-order-queue` scalar read-data
shipped in `.491`. Code inspection found the only blocker is local to
dynamic issue-order queue read-data coverage: depth-2 queue raw-`ARLEN` and
depth-3 no-burst read-data are already supported, while the generated
burst-length storage/rule/report helpers already enumerate all covered
transactions. A RAM-guarded in-memory candidate inserted the existing public
burst-length clause into the `.491` source and failed closed at that local
coverage diagnostic. Runtime validation, multi-beat output banks, mixed
dynamic/static queues, scoreboards, arbitrary cardinality,
verification-code generation, direct backend behavior, backend-language
variants, external converter dependencies such as `sv2v`, and VHDL remain
deferred; FSMGen-owned generation/lowering remains the default.

Dynamic read burst-last depth-3 same-ID issue-order queue read-data
raw-`ARLEN` behavior:
[AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_BEHAVIOR.md)
ships the `.494` support-accounted sample
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_burst_length.ppif`.
The generated path keeps the queue-owned `RID && RLAST` completion pulse,
adds generated input `axi0_arlen`, stores request-time raw length in
`axi0_r0_arlen_q`, `axi0_r1_arlen_q`, and `axi0_r2_arlen_q`, and emits
`axi0_r*_burst_length_capture` rules for `r0`/`r1`/`r2`. The report keeps
completion validity
`generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse`
and records `burst_length_validation: report_only`,
`generated_burst_length_inputs: [axi0_arlen]`, and the three generated
storage/rule names. Runtime validation over this depth-3 queue, multi-beat
output banks over this depth-3 queue, mixed dynamic/static queues,
scoreboards, arbitrary cardinality, verification-code generation, direct
backend behavior, backend-language variants, external converter dependencies
such as `sv2v`, and VHDL remain deferred; FSMGen-owned generation/lowering
remains the default.

Post dynamic read burst-last depth-3 same-ID issue-order queue read-data
raw-`ARLEN` selector:
[AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_NEXT_SLICE_SELECTION.md)
selects `.496`, readiness audit for runtime beat-count/`RLAST` validation
over the generated all-dynamic read burst-last `RID && RLAST` depth-3
same-ID `issue-order-queue` scalar read-data raw-`ARLEN` behavior shipped in
`.494`. This is the smallest adjacent owner because `.494` supplies the
exact three-transaction report-only raw-`ARLEN` queue read-data surface,
while `.471` already proves runtime beat-count/`RLAST` validation over the
two-transaction dynamic RLAST queue. Multi-beat output banks, mixed
dynamic/static queues, scoreboards, arbitrary cardinality,
verification-code generation, direct backend behavior, backend-language
variants, external converter dependencies such as `sv2v`, and VHDL remain
deferred; FSMGen-owned generation/lowering remains the default.

Dynamic read burst-last depth-3 same-ID issue-order queue read-data runtime
validation readiness:
[AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md)
selects `.497`, direct bounded implementation of runtime
beat-count/`RLAST` validation over the generated all-dynamic read burst-last
`RID && RLAST` depth-3 same-ID `issue-order-queue` scalar read-data
raw-`ARLEN` behavior shipped in `.494`. The unmodified runtime candidate
failed closed at the local dynamic queue coverage diagnostic. A RAM-guarded
out-of-tree one-line predicate overlay proved the existing runtime helpers
enumerate `r0`/`r1`/`r2` expected-beat storage, read-beat counters, six
rules, and twelve beat-count/`RLAST` assertion names. Multi-beat output
banks, mixed dynamic/static queues, scoreboards, arbitrary cardinality,
verification-code generation, direct backend behavior, backend-language
variants, external converter dependencies such as `sv2v`, and VHDL remain
deferred; FSMGen-owned generation/lowering remains the default.

Dynamic read burst-last depth-3 same-ID issue-order queue read-data runtime
validation behavior:
[AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md)
ships `.497` through support-accounted sample
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif`.
The generated path keeps queue-owned `RID && RLAST` completion and scalar
last-beat read-data capture, adds per-transaction expected-beat storage and
read-beat counters for `r0`/`r1`/`r2`, emits six beat-count init/increment
rules, and emits twelve `ARLEN`/beat-count/`RLAST` runtime assertions. The
read-data report advertises `burst_length_validation: runtime_assertion`,
`beat_count_validation_generated_behavior: true`,
`generated_expected_beat_count_storage`,
`generated_beat_count_storage`, `generated_beat_count_rules`, and twelve
`generated_beat_count_assertions`. The `.494` report-only sample remains
supported and keeps runtime beat-count state absent. Multi-beat output banks
over this depth-3 queue, mixed dynamic/static queues, scoreboards, arbitrary
cardinality, verification-code generation, direct backend behavior,
backend-language variants, external converter dependencies such as `sv2v`,
and VHDL remain deferred; FSMGen-owned generation/lowering remains the
default.

Post dynamic read burst-last depth-3 same-ID issue-order queue read-data
runtime-validation selector:
[AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md)
selects `.499`, readiness audit for multi-beat output banks over the
generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID
`issue-order-queue` runtime-validation read-data behavior shipped in `.497`.
This is the smallest adjacent owner because `.497` supplies the exact
three-transaction runtime-validation queue read-data surface, while `.473`
already proves multi-beat output banks over the two-transaction dynamic RLAST
queue. Mixed dynamic/static queues, scoreboards, arbitrary cardinality,
verification-code generation, direct backend behavior, backend-language
variants, external converter dependencies such as `sv2v`, and VHDL remain
deferred; FSMGen-owned generation/lowering remains the default.

Dynamic read burst-last depth-3 same-ID issue-order queue read-data
multi-beat readiness:
[AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md)
selects `.500`, direct bounded implementation of multi-beat output banks over
generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID
`issue-order-queue` runtime-validation read-data. The audit found only the
local dynamic issue-order queue read-data coverage gate: the RAM-guarded
temporary depth-3 multi-beat candidate failed closed at the diagnostic that
still admits multi-beat only over two dynamic transactions. Downstream
multi-beat normalization, artifact, report, lane-capture, and
runtime-validation helpers are already transaction-list driven. Mixed
dynamic/static queues, scoreboards, arbitrary cardinality,
verification-code generation, direct backend behavior, backend-language
variants, external converter dependencies such as `sv2v`, and VHDL remain
deferred; FSMGen-owned generation/lowering remains the default.

Dynamic read burst-last depth-3 same-ID issue-order queue read-data
multi-beat behavior:
[AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_BEHAVIOR.md)
ships `.500` through support-accounted sample
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat.ppif`.
The generated path keeps queue-owned `RID && RLAST` completion,
raw-`ARLEN` capture, expected-beat storage, read-beat counters, six
beat-count rules, and twelve beat-count/`RLAST` runtime assertions, and adds
per-transaction multi-beat `RDATA`/`RRESP` output banks for `r0`/`r1`/`r2`,
valid masks, length outputs, scalar worst-observed `RRESP` aggregate
outputs, output-init rules, 48 lane-capture rules, and aggregate update
rules. The read-data report advertises
`bounded_multi_beat_read_data_contract`, `capture_scope: multi_beat`,
response-demux matched-read-beat capture, runtime-assertion burst-length
validation, three generated valid-mask outputs, three generated length
outputs, 48 data outputs, 48 status outputs, and 48 capture rules. Existing
two-transaction dynamic queue multi-beat behavior, the `.494` report-only
depth-3 raw-`ARLEN` sample, and the `.497` depth-3 scalar
runtime-validation sample remain supported. Mixed dynamic/static queues,
scoreboards, arbitrary cardinality, verification-code generation, direct
backend behavior, backend-language variants, external converter dependencies
such as `sv2v`, and VHDL remain deferred; FSMGen-owned generation/lowering
remains the default.

Post dynamic read burst-last depth-3 issue-order queue multi-beat selector:
[AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_NEXT_SLICE_SELECTION.md)
selects `.502`, readiness audit for generated mixed dynamic/static write
`BID` same-ID `issue-order-queue` behavior with exactly one dynamic write
transaction and one concrete static write transaction. It changes no
behavior. This is the smallest mixed queue owner after `.500` closed the
all-dynamic depth-3 queue/read-data ladder: write `BID` avoids read-only
`RLAST`, read-data, raw `ARLEN`, runtime beat-count validation, and
multi-beat output-bank complications. Optional external converter audits such
as `sv2v`, scoreboards, arbitrary cardinality, same-cycle widening,
verification-code generation, direct backend behavior, backend-language
variants, and VHDL remain deferred; FSMGen-owned generation/lowering remains
the default.

Mixed dynamic/static write same-ID issue-order queue readiness:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md)
selects `.503`, direct bounded implementation for exactly one dynamic write
transaction plus one concrete static write transaction. Parser support
already accepts `dynamic-id-reuse issue-order-queue`; a RAM-guarded temporary
mixed write candidate failed closed only at the local all-dynamic write queue
planner diagnostic requiring two or three all-dynamic write transactions. The
direct implementation is local to mixed queue planning, report projection,
queue rule/assertion coverage, sample/support accounting, and focused tests.
External converter dependencies such as `sv2v`, mixed read queues,
multi-static or two-dynamic-plus-static queues, scoreboards, arbitrary
cardinality, backend behavior, backend-language variants, verification-code
generation, and VHDL remain deferred.

Mixed dynamic/static write same-ID issue-order queue behavior:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md)
ships `.503` through support-accounted public sample
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue.ppif`.
The generated response-demux uses
`bounded_mixed_dynamic_static_write_bid_issue_order_queue_demux_contract`,
`generated_mixed_dynamic_static_issue_order_queue_demux`,
`earliest_matching_captured_or_static_runtime_id`, compact runtime-ID slots,
and `mixed_dynamic_static_issue_order_earliest_matching_slot`. Dynamic
enqueues store `axi0_awid`; static enqueues store the sized concrete literal
such as `4'd3`; static/dynamic runtime-ID overlap is allowed and ordered by
queue position. The same-ID ordering report uses
`generated_mixed_dynamic_static_write_bid_issue_order_queue`,
`generated_mixed_dynamic_static_issue_order_queue`,
`accepted_same_id_reuse: true`, `generated_scoreboard_behavior: false`,
`active_id_uniqueness_policy: not_required_for_issue_order_queue`, and
`static_id_conflict_policy: ordered_overlap_allowed`. Mixed read queues,
multi-static/two-dynamic mixed queues, scoreboards, arbitrary cardinality,
backend behavior, backend-language variants, verification-code generation,
external converter dependencies such as `sv2v`, and VHDL remain deferred;
FSMGen-owned generation/lowering remains the default.

Post mixed dynamic/static write same-ID issue-order queue selector:
[AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md)
selects `.505`, readiness audit for generated mixed dynamic/static read
single-beat `RID` same-ID `issue-order-queue` behavior. This is the smallest
adjacent FSMGen-owned queue continuation after `.503`: it reuses the
one-dynamic plus one-concrete-static queue model and the all-dynamic read
single-beat `RID` queue model while avoiding mixed read burst-last
`RID && RLAST`, read-data, raw `ARLEN`, runtime validation, multi-beat output
banks, broader mixed cardinality, scoreboards, direct backend behavior,
backend-language variants, verification-code generation, external converter
dependencies such as `sv2v`, and VHDL. No parser, generator, PPIF sample,
support-accounting catalog, generated artifact, report JSON, test,
HDL/runtime behavior, backend behavior, external converter dependency, or
VHDL behavior changed in `.504`.

Mixed dynamic/static read same-ID issue-order queue readiness audit:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md)
selects `.506`, direct bounded implementation of generated mixed
dynamic/static read single-beat `RID` same-ID `issue-order-queue` behavior for
exactly one dynamic read transaction and one concrete static read transaction.
Parser support already accepts read `dynamic-id-reuse issue-order-queue`; a
RAM-guarded temporary mixed read candidate fails closed only at the local
all-dynamic read queue planner diagnostic requiring exactly two all-dynamic
read transactions, or exactly three all-dynamic read transactions with
single-beat or burst-last scope. The direct implementation is local to mixed
read queue planning, read response-demux projection, mixed queue coverage
gating, report projection, queue rule/assertion coverage, sample/support
accounting, and focused tests. Mixed read burst-last queues, read-data, raw
`ARLEN`, runtime validation, multi-beat output banks, broader mixed
cardinality, scoreboards, backend behavior, backend-language variants,
external converter dependencies such as `sv2v`, verification-code generation,
and VHDL remain deferred.

Mixed dynamic/static read same-ID issue-order queue behavior:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md)
ships `.506` through support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_same_id_issue_order_queue.ppif`.
The top-level response-demux report remains the aggregate
`bounded_response_demux_contract`, while `response_demux.read.mode` reports
`bounded_mixed_dynamic_static_read_rid_issue_order_queue_demux_contract`.
The generated read demux uses
`generated_mixed_dynamic_static_issue_order_queue_demux`,
`earliest_matching_captured_or_static_runtime_id`, compact runtime-ID slots,
`captured_or_static_request_id`, and
`mixed_dynamic_static_issue_order_earliest_matching_slot`. Dynamic enqueues
store `axi0_arid`; static enqueues store the sized concrete literal such as
`4'd3`; static/dynamic runtime-ID overlap is allowed and ordered by queue
position. The same-ID ordering report uses
`generated_mixed_dynamic_static_read_rid_issue_order_queue`,
`generated_mixed_dynamic_static_issue_order_queue`,
`accepted_same_id_reuse: true`, `generated_scoreboard_behavior: false`,
`active_id_uniqueness_policy: not_required_for_issue_order_queue`, and
`static_id_conflict_policy: ordered_overlap_allowed`. Mixed read burst-last
queues, read-data over this queue, raw `ARLEN`, runtime validation,
multi-beat output banks, multi-static/two-dynamic mixed queues, scoreboards,
arbitrary cardinality, backend behavior, backend-language variants,
verification-code generation, external converter dependencies such as `sv2v`,
and VHDL remain deferred; FSMGen-owned generation/lowering remains the
default.

Post mixed dynamic/static read same-ID issue-order queue selector:
[AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md)
selects `.508`, readiness audit for generated mixed dynamic/static read
burst-last `RID && RLAST` same-ID `issue-order-queue` behavior. This selector
changes no behavior. The next audit is the smallest adjacent owner because
`.506` proves the queue-owned one-dynamic plus one-static mixed read `RID`
model, `.463` proves all-dynamic read burst-last queue completion/dequeue
semantics, and `.280` proves mixed read final `RID && RLAST` response-demux
matching. Read-data over mixed read queues, raw `ARLEN`, runtime validation,
multi-beat output banks, broader mixed cardinality, scoreboards, backend
behavior, backend-language variants, verification-code generation, external
converter dependencies such as `sv2v`, and VHDL remain deferred; FSMGen-owned
generation/lowering remains the default.

Mixed dynamic/static read burst-last same-ID issue-order queue readiness:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md)
selects `.509`, direct bounded implementation of generated mixed
dynamic/static read burst-last `RID && RLAST` same-ID `issue-order-queue`
behavior for exactly one dynamic read transaction and one concrete static
read transaction. A RAM-guarded temporary candidate derived from the `.506`
mixed read queue sample by switching to `response-scope burst-last` and adding
one-bit `axi0_rlast` fails closed at the local planner diagnostic that still
permits mixed dynamic/static read issue-order queues only for
`response_scope single-beat`. No parser, IAL1, IAL0, SystemVerilog,
backend-language, external converter, verification-output, or VHDL
prerequisite is required first. The direct implementation is local to mixed
read burst-last queue admission, last-beat response-demux report projection,
mixed queue behavior gating, report vocabulary, sample/support accounting,
and focused tests. Read-data over the mixed queue, raw `ARLEN`, runtime
validation, multi-beat output banks, broader mixed cardinality, scoreboards,
backend behavior, backend-language variants, verification-code generation,
external converter dependencies such as `sv2v`, and VHDL remain deferred.

Mixed dynamic/static read burst-last same-ID issue-order queue behavior:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md)
ships `.509`, generated mixed dynamic/static read burst-last `RID && RLAST`
same-ID `issue-order-queue` behavior for exactly one dynamic read transaction
and one concrete static read transaction. The public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue.ppif`
stores `axi0_arid` for the dynamic enqueue, stores `4'd3` for the static
enqueue, matches the earliest captured-or-static `RID`, and completes/dequeues
only when that selected match also carries `axi0_rlast`. Reports expose
`bounded_mixed_dynamic_static_read_rid_rlast_issue_order_queue_demux_contract`,
`generated_mixed_dynamic_static_issue_order_queue_demux_last_beat`, and
`read_rid_rlast_one_dynamic_one_static_transaction`. Read-data over this queue,
raw `ARLEN`, runtime validation, multi-beat output banks, broader mixed
cardinality, scoreboards, backend behavior, backend-language variants,
verification-code generation, external converter dependencies such as `sv2v`,
and VHDL remain deferred.

Post mixed dynamic/static read burst-last same-ID issue-order queue selector:
[AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md)
selects `.511`, public `.ppif` downstream-contract, capability-manifest, and
mdBook surface synchronization before any further mixed queue behavior. The
selector found the behavior-specific `.503`/`.506`/`.509` surfaces current,
but the downstream handoff, public interface contract, embedding chapter, and
`language_surface.file_surfaces` `.ppif` manifest boundary do not yet advertise
the generated mixed dynamic/static same-ID `issue-order-queue` chain for write
`BID`, read single-beat `RID`, and read burst-last `RID && RLAST`. `.511`
owns that public-surface repair without parser/generator/sample/support-accounting,
generated-artifact, schedule/check/semantic JSON, HDL/runtime,
backend, external-converter, verification-output, or VHDL behavior changes.
At that point, mixed read-data over these queues, raw `ARLEN`, runtime
validation, multi-beat output banks, broader mixed cardinality, scoreboards,
backend behavior, backend-language variants, verification-code generation,
external converter dependencies such as `sv2v`, and VHDL remained deferred.

Mixed dynamic/static issue-order queue public surface synchronization:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_PUBLIC_SURFACE_SYNC](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_PUBLIC_SURFACE_SYNC.md)
ships `.511`, public `.ppif` downstream-contract, capability-manifest, and
mdBook surface synchronization. The downstream integration spec, public
interface contract, embedding chapter, and `language_surface.file_surfaces`
`.ppif` manifest boundary now advertise generated one-dynamic plus
one-concrete-static mixed dynamic/static same-ID `issue-order-queue` behavior
for write `BID`, read single-beat `RID`, and read burst-last `RID && RLAST`.
The manifest test now locks that boundary. The later `.514` slice adds paired
scalar read-data over the generated mixed read single-beat and burst-last queue
completions; raw `ARLEN`, runtime validation, and multi-beat output banks over
generated mixed dynamic/static issue-order queues remain deferred, as do
broader mixed cardinality, scoreboards, backend behavior, backend-language
variants, verification-code generation, external converter dependencies such
as `sv2v`, and VHDL. `.512` is the next selector after this public-surface
sync.

Post mixed dynamic/static issue-order queue public surface sync selector:
[AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_PUBLIC_SURFACE_SYNC_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_PUBLIC_SURFACE_SYNC_NEXT_SLICE_SELECTION.md)
selects `.513`, readiness audit for scalar read-data routing over generated
mixed dynamic/static read same-ID `issue-order-queue` completion pulses. The
selector changes no behavior. Read-data is next because the mixed write
`BID`, read single-beat `RID`, and read burst-last `RID && RLAST` queue
families now generate one-dynamic plus one-concrete-static completion
sources, while scalar read-data over those generated mixed read queue
completions remains explicitly unowned. The audit must decide whether the next
owner is paired scalar single-beat plus scalar last-beat contract selection,
direct bounded implementation, a narrower read-data owner, a prerequisite
cleanup, or deferral. Raw `ARLEN`, runtime validation, multi-beat output
banks, broader mixed cardinality, scoreboards, backend behavior,
backend-language variants, verification-code generation, external converter
dependencies such as `sv2v`, and VHDL remain future exact owners.

Mixed dynamic/static issue-order queue read-data readiness audit:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_READINESS_AUDIT.md)
selects `.514`, direct bounded implementation of paired scalar read-data over
generated mixed dynamic/static read same-ID `issue-order-queue` completions.
Existing scalar `read-data.read` syntax and scalar report modes are sufficient;
the remaining blocker is local to read-data transaction coverage for
`generated_mixed_dynamic_static_issue_order_queue_demux` and
`generated_mixed_dynamic_static_issue_order_queue_demux_last_beat`. Temporary
single-beat and burst-last candidates reached the current coverage fallback,
so no parser, PPIF syntax, IAL1, IAL0, SystemVerilog, backend, external
converter, or VHDL prerequisite is exposed. Raw `ARLEN`, runtime validation,
multi-beat output banks, broader mixed cardinality, scoreboards, backend
behavior, backend-language variants, verification-code generation, external
converter dependencies such as `sv2v`, and VHDL remain future exact owners.

Mixed dynamic/static issue-order queue read-data behavior:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_BEHAVIOR](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_BEHAVIOR.md)
ships `.514`, paired scalar read-data routing over generated mixed
dynamic/static read same-ID `issue-order-queue` completions. The public samples
are
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_same_id_issue_order_queue_read_data.ppif`
and
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data.ppif`.
Each sample uses exactly one dynamic read transaction plus one concrete static
read transaction, one depth-2 generated mixed queue, existing scalar
`read-data.read` syntax, complete scalar `RDATA`/`RRESP` output bindings, no
`burst_length` metadata, and queue-specific completion-validity names for the
single-beat and last-beat queue demux pulses. Raw `ARLEN`, runtime validation,
multi-beat output banks, broader mixed cardinality, scoreboards, backend
behavior, backend-language variants, verification-code generation, external
converter dependencies such as `sv2v`, and VHDL remain future exact owners.
The next owned frontier is `.515`, raw-`ARLEN` burst-length readiness over the
mixed burst-last queue read-data path.

Mixed dynamic/static issue-order queue read-data burst-length readiness:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md)
selects `.516`, direct bounded implementation of report-only raw-`ARLEN`
burst-length capture over generated mixed dynamic/static read burst-last
same-ID `issue-order-queue` scalar read-data. Existing `burst-length` syntax,
dynamic queue raw-`ARLEN` behavior, and ordinary mixed response-demux
raw-`ARLEN` behavior are sufficient; the temporary candidate failed only at
the local mixed queue coverage branch that still requires no `burst_length`
metadata. Runtime validation, multi-beat output banks, broader mixed
cardinality, scoreboards, backend behavior, backend-language variants,
verification-code generation, external converter dependencies such as `sv2v`,
and VHDL remain future exact owners.

Mixed dynamic/static issue-order queue read-data burst-length behavior:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_BEHAVIOR](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_BEHAVIOR.md)
ships `.516`, report-only raw-`ARLEN` burst-length capture over generated mixed
dynamic/static read burst-last same-ID `issue-order-queue` scalar read-data.
The public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_burst_length.ppif`.
It remains bounded to exactly one dynamic read plus one concrete static read,
one depth-2 generated mixed queue, complete scalar last-beat `RDATA`/`RRESP`
bindings, existing report-only `burst-length` metadata, and completion validity
`generated_mixed_dynamic_static_read_issue_order_queue_response_demux_last_beat_completion_pulse`.
Runtime validation is now covered by `.517`/`.518`; multi-beat output banks,
broader mixed cardinality, scoreboards, backend behavior,
backend-language variants, verification-code generation, external converter
dependencies such as `sv2v`, and VHDL remain future exact owners.

Mixed dynamic/static issue-order queue read-data runtime-validation readiness:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md)
selects `.518`, direct bounded implementation of runtime beat-count/`RLAST`
validation over generated mixed dynamic/static read burst-last same-ID
`issue-order-queue` scalar last-beat read-data with raw-`ARLEN` capture.
Existing `burst-length` syntax, dynamic issue-order queue runtime behavior,
ordinary mixed response-demux runtime behavior, and shared runtime generation
and report helpers are sufficient; the remaining blocker is local to the
mixed queue read-data coverage branch admitting `report_only` but not
`runtime_assertion`. Multi-beat output banks, broader mixed cardinality,
scoreboards, backend behavior, backend-language variants, verification-code
generation, external converter dependencies such as `sv2v`, and VHDL remain
future exact owners.

Mixed dynamic/static issue-order queue read-data runtime-validation behavior:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md)
ships `.518`, runtime beat-count/`RLAST` validation over generated mixed
dynamic/static read burst-last same-ID `issue-order-queue` scalar last-beat
read-data with raw-`ARLEN` capture. The public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif`.
It remains bounded to exactly one dynamic read plus one concrete static read,
one depth-2 generated mixed queue, complete scalar last-beat `RDATA`/`RRESP`
bindings, runtime-assertion raw-`ARLEN` metadata, per-transaction
expected-beat/read-beat-count storage, eight beat-count/`RLAST` assertions, and
completion validity
`generated_mixed_dynamic_static_read_issue_order_queue_response_demux_last_beat_completion_pulse`.
Multi-beat output banks, broader mixed cardinality, scoreboards, backend
behavior, backend-language variants, verification-code generation, external
converter dependencies such as `sv2v`, and VHDL remain future exact owners. The
next owned frontier is `.519`, multi-beat output-bank readiness over this mixed
queue path.

Mixed dynamic/static issue-order queue read-data multi-beat readiness:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md)
selects `.520`, direct bounded implementation of multi-beat output banks over
the `.518` mixed queue runtime-validation read-data path. The audit found the
remaining blocker local to the mixed dynamic/static issue-order queue read-data
coverage branch: it has scalar single-beat and scalar last-beat boundaries, but
no `capture-scope multi-beat` boundary requiring runtime-assertion
`burst-length` metadata. Shared parser syntax, normalization, report metadata,
output-bank rule generation, status aggregation, beat-count/`RLAST` assertions,
response-state lookup, and test helper vocabulary are already present. The
selected `.520` public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_multi_beat.ppif`.
Broader mixed cardinality, scoreboards, backend behavior,
backend-language variants, verification-code generation, external converter
dependencies such as `sv2v`, and VHDL remain future exact owners.

Mixed dynamic/static issue-order queue read-data multi-beat behavior:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_BEHAVIOR](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_BEHAVIOR.md)
ships `.520`, generated multi-beat read-data output banks over generated mixed
dynamic/static read burst-last same-ID `issue-order-queue` runtime-validation
read-data. The public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_multi_beat.ppif`.
It remains bounded to exactly one dynamic read plus one concrete static read,
one depth-2 generated mixed queue, generated burst-last queue completion source
`generated_mixed_dynamic_static_issue_order_queue_demux_last_beat`,
`capture-scope multi-beat`, runtime-assertion raw-`ARLEN` burst-length
metadata, complete per-transaction data/status output banks, scalar
worst-observed `RRESP` aggregate outputs, valid-mask outputs, length outputs,
and completion validity
`generated_mixed_dynamic_static_read_issue_order_queue_response_demux_last_beat_completion_pulse`.
The read-data report residue is empty for this bounded queue-owned shape.
Broader mixed issue-order queue cardinality, scoreboards, backend behavior,
backend-language variants, verification-code generation, external converter
dependencies such as `sv2v`, and VHDL remain future exact owners.

Post mixed issue-order queue multi-beat selector:
[AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_NEXT_SLICE_SELECTION.md)
selects `.523`, readiness audit for one-dynamic plus two-concrete-static
mixed dynamic/static write `BID` same-ID `issue-order-queue` behavior. The
selector changes no behavior. It chooses write `BID` first because it widens
static siblings without adding read `RLAST`, read-data, raw-`ARLEN`, runtime,
multi-beat, scoreboard, backend, external-converter, or VHDL behavior.

Mixed dynamic/static write multi-static same-ID issue-order queue readiness:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_MULTI_STATIC_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_MULTI_STATIC_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md)
selects `.524`, direct bounded implementation for one dynamic write plus two
concrete static writes over generated write `BID` same-ID
`issue-order-queue` behavior. The current candidate fails closed at the local
mixed queue planner/materializer boundary, not at parser, lower IAL1/IAL0,
SystemVerilog, backend, external-converter, or VHDL prerequisites. The next
behavior slice remains bounded to write `BID`; broader read queues, read-data,
raw-`ARLEN`, runtime validation, multi-beat output banks, scoreboards,
arbitrary cardinality, backend behavior, verification-output generation, and
VHDL stay deferred.

Mixed dynamic/static write multi-static same-ID issue-order queue behavior:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_MULTI_STATIC_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_MULTI_STATIC_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md)
ships `.524` through support-accounted public sample
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue_multi_static.ppif`.
The generated write `BID` issue-order queue covers one dynamic write plus two
pairwise-distinct concrete static writes, uses compact runtime-ID queue slots
of depth three, enqueues `axi0_awid`, `4'd3`, and `4'd5`, reports
`write_bid_one_dynamic_two_static_transactions`, and preserves the `.503`
one-static mixed queue plus all-dynamic write depth-2/depth-3 queue behavior.
Broader read queue cardinality, read-data, raw `ARLEN`, runtime validation,
multi-beat output banks, scoreboards, arbitrary mixed cardinality,
group-local simultaneous enqueue widening, backend behavior,
verification-output generation, backend-language variants, external converter
dependencies such as `sv2v`, and VHDL stay deferred.
