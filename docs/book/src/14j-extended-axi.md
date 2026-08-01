# Extended AXI Backlog

Post multiple dynamic multi-beat selector:
[AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_MULTI_BEAT_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_MULTI_BEAT_NEXT_SLICE_SELECTION.md)
selects `.270`, readiness audit for mixed dynamic/static response-demux after
generated bounded multiple dynamic multi-beat output banks. The selector
changes no behavior. The audit is next because the all-dynamic multiple
dynamic path now covers write response-demux, read single-beat response-demux,
read burst-last/`RLAST` response-demux, scalar read-data, report-only
raw-`ARLEN` capture, runtime beat-count/`RLAST` validation, and multi-beat
output banks, while mixed static and dynamic response ownership still needs a
settled fail-closed/public contract boundary before same-cycle widening,
release-and-recapture, queues, scoreboards, direct backend,
backend-language variants, or VHDL.

Mixed dynamic/static response-demux readiness audit:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_RESPONSE_DEMUX_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_RESPONSE_DEMUX_READINESS_AUDIT.md)
selects `.271`, public contract selection for bounded mixed dynamic/static
write `BID` response-demux. Current dynamic response-demux intentionally
fails closed unless every selected family transaction is dynamic. The audit
chooses write `BID` as the first mixed family because it can settle static
concrete-ID versus active dynamic captured-ID ownership without read `RLAST`,
burst-length/runtime, read-data, or multi-beat output-bank coupling. No
behavior changed in the audit.

Mixed dynamic/static write response-demux contract:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md)
selects `.272`, direct generated behavior for bounded mixed dynamic/static
write `BID` response-demux. The contract reuses existing
`response-demux.write` syntax with generated completion, exactly one dynamic
write transaction, exactly one concrete static write transaction, and static
concrete IDs reserved away from dynamic capture so one raw `BID` cannot match
both owners. Read-side mixed demux, multiple mixed transactions, same-cycle
widening, release-and-recapture, queues, scoreboards, direct backend,
backend-language variants, and VHDL remain later owners.

Mixed dynamic/static write response-demux behavior:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md)
ships that `.272` behavior. The support-accounted public sample
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif`
generates dynamic selected-ID/busy state for `w0`, static busy state for `w1`,
captures `AWID` for the dynamic transaction only when it is not the static
concrete ID, matches generated completions from raw `BID` responses, and
reports `bounded_mixed_dynamic_static_write_bid_demux_contract`.

```text
(response-demux
  (write
    (response-event axi0_write_complete)
    (transaction-completion generated)))
```

The generated assertion set proves dynamic/static request onehot0, dynamic
request/static-ID exclusion, active dynamic ID/static-ID exclusion, raw
response active match, raw response unique match, and dynamic/static
completion-active release. Read-side mixed demux, multiple mixed transactions,
same-cycle widening, release-and-recapture, queues, scoreboards, direct
backend, backend-language variants, and VHDL remain later owners.

Post mixed dynamic/static write demux selector:
[AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION.md)
selects mixed dynamic/static read response-demux readiness after `.272` shipped
bounded mixed dynamic/static write `BID` response-demux. The read side still
fails closed when a selected read family mixes dynamic and static/concrete
transaction IDs; `.274` selected single-beat `RID` public contract selection as
the first safe read owner before burst-last `RID && RLAST`, scalar read-data,
burst/runtime, multi-beat output banks, report cleanup, or another
prerequisite.

Mixed dynamic/static read demux readiness audit:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md)
selects public contract selection for bounded mixed dynamic/static read
single-beat `RID` response-demux. The first read shape is intentionally
single-beat because it avoids `RLAST`, raw non-final beat accounting, read-data
capture, raw `ARLEN`, runtime beat-count validation, and multi-beat output
banks while still fixing dynamic/static `RID` ownership.

Mixed dynamic/static read demux contract selection:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md)
selects direct generated behavior for bounded one-dynamic plus one-concrete
static read single-beat `RID` response-demux. The support-accounted sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif`,
with report mode `bounded_mixed_dynamic_static_read_rid_demux_contract`,
static-ID reservation away from dynamic `ARID` capture, onehot0 mixed read
requests, static busy-state ownership, and burst/read-data/runtime/multi-beat
residue left to later owners.

Mixed dynamic/static read demux behavior:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md)
ships `.276`, generated bounded mixed dynamic/static read single-beat `RID`
response-demux. The public sample uses existing `response-demux.read` syntax
with `response-scope single-beat`, one dynamic read transaction `r0`, and one
concrete static read transaction `r1` at ID `3`. FSMGen emits
`axi0_r0_dynamic_id_q`, `axi0_r0_dynamic_busy_q`, and
`axi0_r1_static_busy_q`; dynamic capture rejects static literal `4'd3`, static
capture tracks only busy state, raw `RID` responses match either the active
dynamic ID or the active static concrete ID, and generated completions release
the matching busy state. The generated assertion set proves mixed read request
onehot0, dynamic/static ID reservation, raw response active match, raw response
unique match, and dynamic/static completion-active release. Burst-last,
read-data, burst/runtime, multi-beat output banks, multiple mixed
transactions, same-cycle widening, release-and-recapture, queues, scoreboards,
direct backend, backend-language variants, and VHDL remain later owners.

Post mixed dynamic/static read demux selector:
[AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION.md)
selects mixed dynamic/static read burst-last `RID && RLAST` readiness after
`.276` shipped bounded mixed dynamic/static read single-beat `RID`
response-demux. The audit comes before read-data, burst/runtime validation,
multi-beat output banks, multiple mixed transactions, same-cycle widening,
release-and-recapture, queues, scoreboards, direct backend,
backend-language variants, or VHDL because those later surfaces depend on a
settled final-beat completion or matched-beat ownership boundary.

Mixed dynamic/static read RLAST readiness audit:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md)
selects public contract selection for bounded mixed dynamic/static read
burst-last `RID && RLAST` response-demux. The audit found the mixed read state
and all-dynamic burst-last helpers close, but direct implementation still needs
an explicit public contract for static final-beat completion, raw `RID` beat
ownership assertions, report vocabulary, diagnostics, sample/support-accounting
names, and residue before generated behavior changes.

Mixed dynamic/static read RLAST contract selection:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md)
selects direct generated behavior for bounded mixed dynamic/static read
burst-last `RID && RLAST` response-demux. The selected support-accounted sample
is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif`.
The contract keeps raw `RID` beat ownership assertions separate from final
`RID && RLAST` dynamic/static completions and keeps read-data,
burst-length/runtime validation, multi-beat output banks, multiple mixed
transactions, same-cycle widening, release-and-recapture, queues, scoreboards,
direct backend, backend-language variants, and VHDL as later owners.

Mixed dynamic/static read RLAST behavior:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md)
ships `.280`, generated bounded mixed dynamic/static read burst-last
`RID && RLAST` response-demux. The public sample uses existing
`response-demux.read` syntax with `response-scope burst-last`, one-bit
`axi0_rlast`, one dynamic read transaction `r0`, and one concrete static read
transaction `r1` at ID `3`. FSMGen emits dynamic selected-ID/busy state and
static busy state, reserves static literal `4'd3` away from dynamic capture,
keeps raw `RID` beat active/unique assertions unqualified by `RLAST`, and
pulses generated completions only for final matched `RID && RLAST` beats.
Read-data, burst-length/runtime validation, multi-beat output banks, multiple
mixed transactions, same-cycle widening, release-and-recapture, queues,
scoreboards, direct backend, backend-language variants, and VHDL remain later
owners.

Post mixed dynamic/static read RLAST demux selector:
[AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_RLAST_DEMUX_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_RLAST_DEMUX_NEXT_SLICE_SELECTION.md)
selects `.282`, readiness audit for read-data over generated mixed
dynamic/static read response-demux. With `.276` and `.280`, the mixed read
family now has generated single-beat `RID` and burst-last `RID && RLAST`
completion pulses; scalar read-data coverage over those generated completions
is the next dependency before mixed burst-length/runtime validation,
multi-beat output banks, multiple mixed transactions, same-cycle widening,
release-and-recapture, queues, scoreboards, direct backend,
backend-language variants, or VHDL.

Mixed dynamic/static read-data readiness audit:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT.md)
selects `.283`, public contract selection for bounded scalar read-data over
generated mixed dynamic/static read response-demux. The audit found the lower
scalar capture substrate close, but the read-data transaction coverage helper
has no branch for `generated_mixed_dynamic_static_read_demux` or
`generated_mixed_dynamic_static_read_demux_last_beat`; the contract must choose
the public single-beat and last-beat source shapes, exact mixed transaction
coverage, sample names, completion-validity/report vocabulary, diagnostics,
validation gates, and explicit residue before behavior changes.

Mixed dynamic/static read-data contract selection:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION.md)
selects `.284`, direct generated behavior for bounded scalar read-data over
generated mixed dynamic/static read response-demux. The selected implementation
adds two public samples:
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data.ppif`
for scalar single-beat `RDATA`/`RRESP` capture, and
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data.ppif`
for scalar last-beat capture. Read-data coverage must consume the generated
mixed demux completion pulses for the ordered dynamic-plus-static transaction
set, report mixed-specific completion-validity strings, and keep
burst-length/runtime validation, multi-beat output banks, multiple mixed
transactions, same-cycle widening, queues, scoreboards, direct backend,
backend-language variants, and VHDL as later owners.

Mixed dynamic/static read-data behavior:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md)
ships `.284`, generated bounded scalar read-data capture over generated mixed
dynamic/static read response-demux. The support-accounted public samples are
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data.ppif`
for scalar single-beat `RDATA`/`RRESP` capture, and
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data.ppif`
for scalar last-beat capture. The generated capture covers exactly one
dynamic read transaction followed by one concrete static read transaction,
guards each scalar data/status update only with that transaction's generated
mixed demux completion pulse, and reports
`generated_mixed_dynamic_static_read_response_demux_completion_pulse` or
`generated_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`.
Burst-length/runtime validation, multi-beat output banks, multiple mixed
transactions, same-cycle widening, release-and-recapture, dynamic same-ID
queues, scoreboards, direct backend behavior, backend-language variants, and
VHDL remain later owners.

Post mixed dynamic/static read-data selector:
[AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION.md)
selects `.286`, readiness audit for generated report-only raw-`ARLEN`
burst-length capture over generated mixed dynamic/static read burst-last
response-demux and scalar last-beat read-data. The selector keeps runtime
beat-count/`RLAST` validation, multi-beat output banks, multiple mixed
transactions, same-cycle widening, release-and-recapture, dynamic same-ID
queues, scoreboards, direct backend behavior, backend-language variants, and
VHDL as later exact owners unless the audit selects a narrower prerequisite.

Mixed dynamic/static read-data burst-length readiness audit:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md)
selects `.287`, direct bounded implementation of report-only raw-`ARLEN`
burst-length capture over generated mixed dynamic/static read burst-last
response-demux and scalar last-beat read-data. The audit found the existing
public `burst-length` syntax and generic raw-`ARLEN` input/storage/rule/report
helpers sufficient; `.287` only needs to widen the mixed last-beat/report-only
coverage gate and publish the sample/support/test/docs surface. Runtime
beat-count/`RLAST` validation and multi-beat output banks remain later owners.

Mixed dynamic/static read-data burst-length behavior:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR.md)
ships `.287`, generated report-only raw-`ARLEN` burst-length capture over the
generated mixed dynamic/static read burst-last response-demux and scalar
last-beat read-data shape. The support-accounted public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length.ppif`.
It uses the existing `burst-length` syntax with `source arlen`, width-8
`axi0_arlen`, `axlen-plus-one`, request capture, and `validation report-only`;
the generated artifacts add `axi0_arlen`, per-transaction raw-`ARLEN` storage
and request-guarded capture rules, while scalar `RDATA`/`RRESP` capture remains
guarded by the generated mixed `RID && RLAST` completion pulses. Runtime
beat-count/`RLAST` validation, multi-beat output banks, multiple mixed
transactions, direct backend behavior, backend-language variants, and VHDL
remain later exact owners.

Mixed dynamic/static read-data runtime-validation readiness audit:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md)
selects `.289`, direct bounded implementation of runtime beat-count/`RLAST`
validation over the same generated mixed dynamic/static read burst-last
response-demux and scalar last-beat read-data shape as `.287`. The selected
runtime sibling sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length_runtime_assertion.ppif`.
The audit found no lower-layer prerequisite and no separate public contract
selection need: once the mixed coverage gate admits `validation
runtime-assertion`, the existing runtime machinery can generate expected-beat
storage, read-beat counters, request-time initialization, raw matched-read-beat
increments, four assertions per transaction, and report/residue updates.
Mixed multi-beat output banks, multiple mixed transactions, direct backend
behavior, backend-language variants, and VHDL remain later exact owners.

Mixed dynamic/static read-data runtime-validation behavior:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md)
ships `.289`, generated runtime beat-count/`RLAST` validation over generated
mixed dynamic/static read burst-last response-demux and scalar last-beat
read-data. The support-accounted public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length_runtime_assertion.ppif`.
FSMGen emits `axi0_arlen`, raw `ARLEN` storage, expected-beat storage,
read-beat counters, request-time `ARLEN + 1` initialization, raw matched-beat
increments for the dynamic captured `RID` and static concrete `RID`, and four
runtime assertions per covered transaction. Scalar `RDATA`/`RRESP` capture
remains guarded only by generated mixed `RID && RLAST` completion pulses. The
report keeps `bounded_last_beat_read_data_contract`,
`runtime_assertion`, `response_demux_matched_read_beat`, generated beat-count
artifact lists, and removes `generated_beat_count_validation` from read-data
residue. Mixed multi-beat output banks, multiple mixed transactions, direct
backend behavior, backend-language variants, and VHDL remain later exact
owners.

Mixed dynamic/static read-data multi-beat readiness audit:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md)
selects `.291`, direct bounded implementation of generated mixed
dynamic/static multi-beat output-bank behavior over the `.289` runtime
boundary. The audit found no lower-layer prerequisite: `.289` already provides
the generated mixed `RID && RLAST` response-demux, raw `ARLEN` capture,
expected-beat storage, counters, raw matched-beat expressions, and runtime
assertions, while existing multi-beat helpers are transaction-list driven once
coverage admits `capture-scope multi-beat`. The selected future sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_multi_beat.ppif`.
It should use `status-policy per-beat`, `status-aggregation worst-observed`,
`interleaving multi-beat-by-rid`, runtime-assertion `burst-length` metadata,
and complete dynamic-plus-static output-bank bindings. Multiple mixed
transactions, same-cycle widening, direct backend behavior,
backend-language variants, and VHDL remain later exact owners.

Mixed dynamic/static read-data multi-beat behavior:
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR](../../AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md)
ships `.291`, generated mixed dynamic/static multi-beat output-bank behavior
over generated mixed dynamic/static read burst-last response-demux and runtime
beat-count/`RLAST` validation. The support-accounted public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_multi_beat.ppif`.
The sample uses exactly one dynamic read transaction and one concrete static
read transaction, `capture-scope multi-beat`, `status-policy per-beat`,
`status-aggregation worst-observed`, `interleaving multi-beat-by-rid`, and
runtime-assertion `burst-length` metadata. FSMGen emits per-transaction
data/status output banks, valid masks, length outputs, scalar worst-observed
`RRESP` aggregate outputs, request-time output-bank clearing, raw
matched-read-beat lane capture for the dynamic captured `RID` and static
concrete `RID`, raw `ARLEN`/expected-beat/read-beat-count state, and four
runtime assertions per covered transaction. Reports use
`bounded_multi_beat_read_data_contract`, mixed last-beat completion validity,
`response_demux_matched_read_beat`, empty read-data residue, and
`response_demux.residue = [same_id_ordering]`. `.291` selects `.292`, the
next mixed dynamic/static frontier selector after generated mixed multi-beat
output banks.

Post mixed dynamic/static multi-beat selector:
[AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_MULTI_BEAT_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_MULTI_BEAT_NEXT_SLICE_SELECTION.md)
selects `.293`, readiness audit for multiple mixed dynamic/static transaction
cardinality after the one-dynamic plus one-concrete-static mixed path reached
multi-beat output banks. The audit must decide the first bounded
cardinality-widening owner, static concrete-ID reservation-list rules,
dynamic capture exclusion for all selected static IDs, generated ownership
assertions, report vocabulary, diagnostics, public sample/support-accounting
names, focused validation, rollback, and explicit residue. Same-cycle
widening, release-and-recapture, dynamic same-ID queues, scoreboards, direct
backend behavior, backend-language variants, and VHDL remain later exact
owners.

Multiple mixed dynamic/static response-demux readiness:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_RESPONSE_DEMUX_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_RESPONSE_DEMUX_READINESS_AUDIT.md)
selects `.294`, public contract selection for bounded multiple mixed
dynamic/static write `BID` response-demux. The audit found that current mixed
write/read plan builders and read-data coverage predicates are still singular
for exactly one dynamic and one concrete static transaction, while mixed
assertion generation already iterates over dynamic/static state lists. Write
`BID` response-demux is the first widened owner because it settles static-ID
reservation lists, dynamic capture exclusion, onehot0 request policy,
raw-response ownership, generated completion ordering, report vocabulary, and
diagnostics before read `RID`/`RLAST` or read-data behavior widens.

Multiple mixed dynamic/static write response-demux contract:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md)
selects `.295`, direct generated behavior for bounded multiple mixed
dynamic/static write `BID` response-demux. The first public behavior should
reuse existing `response-demux.write` syntax with exactly one dynamic write
transaction and exactly two concrete static write transactions. Reports should
use `bounded_multi_mixed_dynamic_static_write_bid_demux_contract`, generated
completion source `generated_multi_mixed_dynamic_static_demux`, list-shaped
mixed transaction and static-ID reservation fields, dynamic capture
exclusions for every selected static ID, onehot0 request policy across all
selected write transactions, and pairwise raw-response unique-match
assertions. The one-dynamic plus one-static `.272` report contract remains
unchanged.

Multiple mixed dynamic/static write response-demux behavior:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md)
ships `.295`. The public sample
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif`
uses existing `response-demux.write` syntax with one dynamic write
transaction and two concrete static write transactions. FSMGen now emits
dynamic selected-ID/busy state, per-static busy state, dynamic capture
exclusions for static IDs `4'd3` and `4'd5`, generated completion pulses
for `w0`, `w1`, and `w2`, pairwise raw `BID` response unique-match
assertions, and list-shaped mixed transaction/static-ID reservation report
fields while preserving the `.272` one-dynamic plus one-static report
contract.

Post multiple mixed dynamic/static write selector:
[AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION.md)
selects `.297`, readiness audit for multiple mixed dynamic/static read
response-demux after `.295` shipped the widened write `BID` contract. The
selector changes no behavior; it records that read-side mixed dynamic/static
response-demux remains singular while single-beat `RID` and burst-last
`RID && RLAST` scopes need an owned parity audit before contract selection or
implementation.

Multiple mixed dynamic/static read readiness:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md)
selects `.298`, public contract selection for bounded multiple mixed
dynamic/static read single-beat `RID` response-demux. The audit changes no
behavior; it records that the read plan builder remains singular, the mixed
assertion helper is already list-shaped, and single-beat `RID` is the
smallest read-side widened ownership surface before burst-last `RID &&
RLAST`, read-data, burst-length/runtime validation, or multi-beat output
banks.

Multiple mixed dynamic/static read contract:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md)
selects `.299`, direct generated behavior for bounded multiple mixed
dynamic/static read single-beat `RID` response-demux. The selected contract
uses existing `response-demux.read` syntax with `response-scope single-beat`,
one dynamic read transaction, two concrete static read transactions, candidate
mode `bounded_multi_mixed_dynamic_static_read_rid_demux_contract`, completion
source `generated_multi_mixed_dynamic_static_read_demux`, list-shaped
`mixed_transactions`/`static_id_reservations`, dynamic capture exclusions for
all selected static IDs, and preserved `.276` one-dynamic plus one-static
report shape.

Multiple mixed dynamic/static read response-demux behavior:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md)
ships `.299`. The public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif`
uses existing `response-demux.read` syntax with `response-scope single-beat`,
one dynamic read transaction, and two concrete static read transactions.
FSMGen now emits dynamic selected-ID/busy state, per-static busy state,
dynamic capture exclusions for static IDs `4'd3` and `4'd5`, generated
single-beat `RID` completion pulses for `r0`, `r1`, and `r2`, pairwise raw
`RID` response unique-match assertions, and list-shaped mixed
transaction/static-ID reservation report fields while preserving the `.276`
one-dynamic plus one-static report contract.

Post multiple mixed dynamic/static read selector:
[AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION.md)
selects `.301`, readiness audit for multiple mixed dynamic/static read
burst-last `RID && RLAST` response-demux after `.299` shipped widened
single-beat `RID` behavior. The selector changes no behavior; it records that
read-data, burst-length/runtime validation, and multi-beat output-bank
widening over the multi-static mixed read shape should wait until final-beat
completion semantics are audited.

Multiple mixed dynamic/static read RLAST readiness:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md)
selects `.302`, public contract selection for bounded multiple mixed
dynamic/static read burst-last `RID && RLAST` response-demux. The audit
changes no behavior; a guarded temporary candidate confirmed the current
strict-check diagnostic for one dynamic plus two concrete static reads under
`response-scope burst-last`.

Multiple mixed dynamic/static read RLAST contract:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md)
selects `.303`, direct generated behavior for bounded multiple mixed
dynamic/static read burst-last `RID && RLAST` response-demux. The selected
contract changes no behavior in `.302`; it reuses existing
`response-demux.read` syntax with one dynamic read transaction, two concrete
static read transactions, `response-scope burst-last`, one-bit `last-signal`,
mode `bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
completion source `generated_multi_mixed_dynamic_static_read_demux_last_beat`,
list-shaped `mixed_transactions`/`static_id_reservations`, dynamic capture
exclusions for all selected static IDs, raw `RID` ownership assertions, and
final `RID && RLAST` completion pulses for `r0`, `r1`, and `r2`.

Multiple mixed dynamic/static read RLAST behavior:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md)
ships `.303`. The public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif`
uses existing `response-demux.read` syntax with `response-scope burst-last`,
one one-bit `last-signal`, one dynamic read transaction, and two concrete
static read transactions. FSMGen now emits dynamic selected-ID/busy state,
per-static busy state, dynamic capture exclusions for static IDs `4'd3` and
`4'd5`, generated final-beat `RID && RLAST` completion pulses for `r0`,
`r1`, and `r2`, same-cycle final-beat release-and-recapture for those three
transactions, pairwise raw `RID` response unique-match assertions, and
list-shaped mixed transaction/static-ID reservation report fields while
preserving the `.276`, `.280`, and `.299` public report contracts.

Post multiple mixed dynamic/static read RLAST selector:
[AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_DEMUX_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_DEMUX_NEXT_SLICE_SELECTION.md)
selects `.305`, readiness audit for bounded scalar read-data over generated
multiple mixed dynamic/static read response-demux. The selector changes no
behavior in `.304`. It chooses the audit because `.299` now supplies
generated multiple mixed single-beat `RID` completions and `.303` now
supplies generated multiple mixed burst-last `RID && RLAST` completions for
one dynamic read plus two concrete static reads. The audit must settle sample
stems, completion-validity vocabulary, dynamic-then-static transaction
coverage, diagnostics, validation strategy, rollback, and explicit residue
before raw `ARLEN`, runtime validation, multi-beat output banks, broader
cardinalities, same-cycle widening, queues/scoreboards, backend variants, or
VHDL widen.

Multiple mixed dynamic/static read-data readiness audit:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT.md)
selects `.306`, public contract selection for bounded scalar read-data over
generated multiple mixed dynamic/static read response-demux. The audit changes
no behavior in `.305`. It finds that scalar read-data normalization and
capture rule generation are already transaction-count agnostic after coverage
is admitted, while the current mixed dynamic/static read-data coverage branch
only admits the one-dynamic plus one-static completion sources. The next
contract slice must settle public sample names, completion-validity
vocabulary, dynamic-then-static transaction coverage, diagnostics, validation
strategy, residue movement, and rollback before implementation changes.

Multiple mixed dynamic/static read-data contract:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION.md)
selects `.307`, direct generated behavior for bounded scalar read-data over
generated multiple mixed dynamic/static read response-demux. The selector
changes no behavior in `.306`. The selected public samples are
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_read_data.ppif`
and
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data.ppif`.
The contract uses dynamic-then-static transaction coverage `r0, r1, r2`,
keeps scalar single-beat and last-beat read-data modes, uses generated
multiple mixed completion-validity strings, and keeps raw `ARLEN`, runtime
validation, multi-beat output banks, broader cardinalities, same-cycle
widening, queues/scoreboards, backend variants, and VHDL deferred.

Multiple mixed dynamic/static read-data behavior:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md)
ships `.307`. The public samples
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_read_data.ppif`
and
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data.ppif`
compose the `.299` single-beat `RID` demux and `.303` burst-last
`RID && RLAST` demux with scalar read-data for the ordered transaction set
`r0, r1, r2`. FSMGen now emits shared generated `axi0_rdata`/`axi0_rresp`
inputs, scalar data/status outputs for the dynamic transaction and both
static transactions, and one capture rule per transaction guarded only by the
generated multiple mixed demux completion pulse. Reports use
`generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse`
for single-beat capture and
`generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`
for last-beat capture while raw `ARLEN`, runtime validation, multi-beat output
banks, broader cardinalities, same-cycle widening, queues/scoreboards,
backend variants, and VHDL remain deferred.

Post multiple mixed dynamic/static read-data selector:
[AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION.md)
selects `.309`, readiness audit for generated report-only raw-`ARLEN`
burst-length capture over generated multiple mixed dynamic/static read
burst-last response-demux and scalar last-beat read-data. The selector changes
no behavior in `.308`. It chooses the audit because `.307` now supplies scalar
last-beat read-data over the `.303` multiple mixed `RID && RLAST` completion
pulses, while runtime validation and multi-beat output banks depend on first
settling request-time raw-`ARLEN` capture for the dynamic transaction and both
concrete static transactions.

Multiple mixed dynamic/static burst-length readiness:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md)
selects `.310`, direct bounded implementation of report-only raw-`ARLEN`
burst-length capture over generated multiple mixed dynamic/static read
burst-last response-demux and scalar last-beat read-data. The audit changes no
behavior in `.309`. It finds that the generic burst-length normalization,
per-transaction storage/rule generation, and report artifact lists are already
transaction-list driven once the multiple mixed coverage branch admits
last-beat `validation report-only` burst metadata. The selected public sample
is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length.ppif`;
runtime validation, multi-beat output banks, broader cardinalities,
same-cycle widening, queues/scoreboards, backend variants, and VHDL remain
deferred.

Multiple mixed dynamic/static burst-length behavior:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR.md)
ships `.310`. The public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length.ppif`
adds generated report-only raw-`ARLEN` capture to the `.307` multiple mixed
last-beat read-data shape. FSMGen emits generated `axi0_arlen`, raw
request-time storage `axi0_r0_arlen_q`, `axi0_r1_arlen_q`, and
`axi0_r2_arlen_q`, one request-guarded burst-length capture rule per
transaction, and report artifact lists for the generated ARLEN input,
storage, and rules. Scalar last-beat `RDATA`/`RRESP` capture remains guarded
only by generated multiple mixed `RID && RLAST` completions. `.310` selects
`.311`, readiness audit for generated runtime beat-count/`RLAST` validation
over this same multiple mixed raw-`ARLEN` boundary; runtime validation,
multi-beat output banks, broader cardinalities, same-cycle widening,
queues/scoreboards, backend variants, and VHDL remain deferred.

Multiple mixed dynamic/static runtime-validation readiness audit:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md)
selects `.312`, direct bounded implementation of runtime beat-count/`RLAST`
validation over generated multiple mixed dynamic/static raw-`ARLEN`
last-beat read-data. The audit changes no behavior in `.311`. It finds that
the existing runtime-validation machinery is transaction-list driven across
`r0`, `r1`, and `r2` once the multiple mixed last-beat coverage branch admits
`validation runtime-assertion`. The selected public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length_runtime_assertion.ppif`;
multi-beat output banks, broader cardinalities, same-cycle widening,
queues/scoreboards, backend variants, and VHDL remain deferred.

Multiple mixed dynamic/static runtime-validation behavior:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md)
ships `.312`. The public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length_runtime_assertion.ppif`
adds generated runtime beat-count/`RLAST` validation to the `.310` multiple
mixed raw-`ARLEN` last-beat read-data shape. FSMGen emits expected-beat
storage, read-beat counters, request-time beat-count initialization, raw
matched-read-beat increment rules, and four runtime assertions for each of
`r0`, `r1`, and `r2`. Scalar last-beat `RDATA`/`RRESP` capture remains
guarded only by generated multiple mixed `RID && RLAST` completions.
Multi-beat output banks, broader cardinalities, same-cycle widening,
queues/scoreboards, backend variants, and VHDL remain deferred. `.312`
selects `.313`, readiness audit for generated multiple mixed dynamic/static
multi-beat output banks over this runtime-validation boundary.

Multiple mixed dynamic/static multi-beat readiness audit:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md)
selects `.314`, direct bounded implementation of generated multiple mixed
dynamic/static multi-beat output banks over the `.312` runtime-validation
boundary. The audit changes no behavior in `.313`. It finds that `.312`
already supplies the exact one-dynamic plus two-static generated burst-last
runtime source shape, while `.291` and `.268` already ship the public
multi-beat syntax and report vocabulary. The selected public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_multi_beat.ppif`.
The implementation owner should add only bounded coverage admission, support
publication, focused tests, and multiple mixed multi-beat residue recognition.

Multiple mixed dynamic/static multi-beat behavior:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md)
ships `.314`. The public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_multi_beat.ppif`
emits generated per-beat output banks for `r0`, `r1`, and `r2`: 48 `RDATA`
lanes, 48 `RRESP` lanes, three valid masks, three length outputs, and three
scalar worst-observed `RRESP` aggregates. Reports use
`bounded_multi_beat_read_data_contract`, multi-mixed last-beat completion
validity, runtime-assertion `ARLEN` burst-length metadata, empty read-data
residue, and response-demux residue limited to `same_id_ordering`. `.314`
selects `.315`, the next exact-owner selector after multiple mixed
dynamic/static read-data reached multi-beat output banks.

Post multiple mixed multi-beat selector:
[AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_MULTI_BEAT_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_MULTI_BEAT_NEXT_SLICE_SELECTION.md)
selects `.316`, readiness audit for broader mixed dynamic/static transaction
cardinality after the one-dynamic plus one- or two-static mixed read-data
chain reached multi-beat output banks. The selector changes no behavior and
does not choose a public sample yet; the audit must decide whether the next
owner should directly widen a bounded broader shape, first select a public
source/report contract, land helper/report cleanup, or defer in favor of
same-cycle, queue, scoreboard, backend, or VHDL work.

Broader mixed dynamic/static cardinality readiness audit:
[AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_CARDINALITY_READINESS_AUDIT](../../AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_CARDINALITY_READINESS_AUDIT.md)
selects `.317`, public contract selection for the first broader mixed
dynamic/static transaction-cardinality shape. The audit changes no behavior.
It finds that mixed demux admission, mixed demux construction, read
burst-last normalization, read-data coverage, and multi-beat residue
predicates still encode the exact one-dynamic plus one- or two-static
boundary, so the next owner must choose the first public broader shape and
report/diagnostic/support-accounting contract before implementation.

Broader mixed dynamic/static cardinality contract selection:
[AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_CARDINALITY_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_CARDINALITY_CONTRACT_SELECTION.md)
selects `.318`, direct generated behavior for bounded one-dynamic plus
three-concrete-static write `BID` response-demux. The selector changes no
behavior. It reuses the existing
`bounded_multi_mixed_dynamic_static_write_bid_demux_contract` report mode and
chooses public sample stem
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static3.ppif`.
`.318` now ships that sample and generated write behavior. The generated
contract accepts exactly one dynamic write transaction plus one, two, or three
pairwise-distinct concrete static write transactions, records the static
reservations/exclusions as list-shaped report fields, and emits completion,
response-demux, active-match, pairwise unique-match, and completion-active
assertions for the covered write transactions.
Read-side, read-data, two-dynamic-plus-static, general capped mixed sets,
same-cycle, queue/scoreboard, backend, and VHDL work remain deferred.

Post three-static mixed dynamic/static write demux selector:
[AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION.md)
selects `.320`, readiness audit for bounded one-dynamic plus
three-concrete-static mixed dynamic/static read response-demux. The selector
changes no behavior. It starts the audit at the read single-beat `RID`
boundary and keeps burst-last, read-data, two-dynamic-plus-static, capped
mixed sets, same-cycle, queue/scoreboard, backend, and VHDL work as explicit
future owners.

Three-static mixed dynamic/static read response-demux readiness audit:
[AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT](../../AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md)
selects `.321`, public contract selection for bounded one-dynamic plus
three-concrete-static mixed dynamic/static read single-beat `RID`
response-demux. The audit changes no behavior. It finds the report/assertion
surface is list-shaped enough for contract selection, while read admission,
burst-last normalization, and read-data coverage still enforce one dynamic
plus one or two static reads.

Three-static mixed dynamic/static read response-demux contract selection:
[AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md)
selects `.322`, direct generated behavior for bounded one-dynamic plus
three-concrete-static mixed dynamic/static read single-beat `RID`
response-demux. The selector changes no behavior. It reuses existing
`response-demux.read` syntax, public sample stem
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif`,
and report mode `bounded_multi_mixed_dynamic_static_read_rid_demux_contract`.

Three-static mixed dynamic/static read response-demux behavior:
[AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR](../../AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md)
ships generated bounded one-dynamic plus three-concrete-static mixed
dynamic/static read single-beat `RID` response-demux through public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif`.
The generated report reuses
`bounded_multi_mixed_dynamic_static_read_rid_demux_contract` and exposes
`r0` dynamic plus `r1`, `r2`, and `r3` static list fields, static-ID
reservations/exclusions for `4'd3`, `4'd5`, and `4'd7`, four generated
response-demux rules/completions, request onehot, dynamic static-ID
exclusion, response active-match, pairwise unique-match, and
completion-active assertions. Burst-last and read-data over the three-static
read boundary remain future exact-owner work.

Post three-static mixed dynamic/static read demux selector:
[AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION.md)
selects `.324`, readiness audit for bounded one-dynamic plus
three-concrete-static mixed dynamic/static read burst-last `RID && RLAST`
response-demux after the three-static read single-beat demux shipped. The
selector changes no behavior and keeps read-data over the three-static
boundary behind final-beat completion semantics.

Three-static mixed dynamic/static read RLAST readiness audit:
[AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT](../../AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md)
selects `.325`, public contract selection for bounded one-dynamic plus
three-concrete-static mixed dynamic/static read burst-last `RID && RLAST`
response-demux. The audit changes no behavior; it confirms the current
three-static single-beat read demux and two-static burst-last demux are
list-shaped while three-static burst-last admission and read-data coverage
remain fail-closed.

Three-static mixed dynamic/static read RLAST contract selection:
[AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md)
selects `.326`, direct generated behavior for bounded one-dynamic plus
three-concrete-static mixed dynamic/static read burst-last `RID && RLAST`
response-demux. The selector changes no behavior; it reuses existing
`response-demux.read` burst-last syntax, the
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract` report
mode, and the future public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif`.

Three-static mixed dynamic/static read RLAST response-demux behavior:
[AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR](../../AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md)
ships generated one-dynamic plus three-concrete-static mixed dynamic/static
read burst-last `RID && RLAST` response-demux through
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif`.
The generated report reuses
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`, records
static ID reservations and dynamic-capture exclusions for `4'd3`, `4'd5`,
and `4'd7`, keeps raw `RID` active/unique assertions separate from final
`RID && RLAST` completion, and emits generated completions for `r0`, `r1`,
`r2`, and `r3`. Read-data, burst-length/runtime validation, and multi-beat
output banks over this three-static boundary remain future exact-owner work.

Post three-static mixed dynamic/static read RLAST demux selector:
[AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_DEMUX_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_DEMUX_NEXT_SLICE_SELECTION.md)
selects `.328`, readiness audit for bounded scalar read-data over generated
one-dynamic plus three-concrete-static mixed dynamic/static read
response-demux. The selector changes no behavior; it records that current
read-data coverage still admits the generated multi-mixed completion sources
only for exactly one dynamic plus two concrete static read transactions, so
three-static read-data needs an audit before any behavior-bearing owner.

Three-static mixed dynamic/static read-data readiness audit:
[AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT](../../AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT.md)
selects `.329`, public contract selection for bounded scalar read-data over
generated one-dynamic plus three-concrete-static mixed dynamic/static read
response-demux. The audit changes no behavior; it finds the scalar read-data
normalizer, capture-rule generator, and report artifacts are transaction-list
driven after coverage admission, while the current multi-mixed coverage
branch still stops at exactly two concrete static read transactions.

Three-static mixed dynamic/static read-data contract selection:
[AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION.md)
selects `.330`, direct generated behavior for bounded scalar read-data over
generated one-dynamic plus three-concrete-static mixed dynamic/static read
response-demux. The selected public sample stems are
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_read_data.ppif`
and
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data.ppif`;
three-static `burst_length`, runtime validation, and multi-beat output banks
remain fail-closed.

Three-static mixed dynamic/static read-data behavior:
[AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR](../../AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md)
ships generated scalar read-data capture over generated one-dynamic plus
three-concrete-static mixed dynamic/static read response-demux. The public
single-beat and last-beat samples generate scalar `RDATA`/`RRESP` capture
for `r0`, `r1`, `r2`, and `r3`; reports expose completion validity
`generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse`
or
`generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`.
Three-static raw `ARLEN`, runtime beat-count/`RLAST` validation, and
multi-beat output banks remain fail-closed.

Post three-static mixed dynamic/static read-data selector:
[AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION.md)
selects `.332`, readiness audit for report-only raw-`ARLEN` burst-length
capture over generated one-dynamic plus three-concrete-static mixed
dynamic/static read burst-last response-demux and scalar last-beat read-data.
The selector changes no behavior; it follows the read-data ladder by auditing
raw-`ARLEN` before runtime validation and multi-beat output banks over the
same three-static boundary.

Three-static mixed dynamic/static read-data burst-length readiness audit:
[AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_READINESS_AUDIT](../../AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md)
selects `.333`, direct bounded implementation of report-only raw-`ARLEN`
burst-length capture over generated one-dynamic plus three-concrete-static
mixed dynamic/static read burst-last response-demux and scalar last-beat
read-data. The audit changes no behavior; the public `burst-length` syntax
and transaction-list driven raw-`ARLEN` helpers are already ready once
coverage admits `r0`, `r1`, `r2`, and `r3`.

Three-static mixed dynamic/static read-data burst-length behavior:
[AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR](../../AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR.md)
ships generated report-only raw-`ARLEN` burst-length capture over generated
one-dynamic plus three-concrete-static mixed dynamic/static read burst-last
response-demux and scalar last-beat read-data. The public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_burst_length.ppif`
generates width-8 `axi0_arlen`, per-transaction raw-`ARLEN` storage and
request capture rules for `r0`, `r1`, `r2`, and `r3`, and keeps scalar
last-beat payload capture guarded by generated mixed `RID && RLAST`
completion pulses. Runtime beat-count/`RLAST` validation and multi-beat
output banks remain future exact owners.

Three-static mixed dynamic/static read-data runtime-validation readiness audit:
[AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT](../../AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md)
selects `.335`, direct bounded implementation of runtime beat-count/`RLAST`
validation over generated one-dynamic plus three-concrete-static mixed
dynamic/static raw-`ARLEN` last-beat read-data. The audit changes no
behavior; runtime validation syntax and generated expected-beat/beat-count
helpers are already transaction-list driven once coverage admits `r0`, `r1`,
`r2`, and `r3`. Three-static multi-beat output banks remain future
exact-owner work.

Three-static mixed dynamic/static read-data runtime-validation behavior:
[AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR](../../AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md)
ships generated runtime beat-count/`RLAST` validation over generated
one-dynamic plus three-concrete-static mixed dynamic/static raw-`ARLEN`
last-beat read-data. The public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_burst_length_runtime_assertion.ppif`
emits expected-beat and read-beat-count state for `r0`, `r1`, `r2`, and
`r3`, request-time initialization, matched-read-beat increments, and four
runtime assertions per covered transaction. Multi-beat output banks remain
future exact-owner work.

Three-static mixed dynamic/static read-data multi-beat readiness audit:
[AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_READINESS_AUDIT](../../AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md)
selects `.337`, direct bounded implementation of generated multi-beat output
banks over that same one-dynamic plus three-concrete-static runtime-validation
read-data boundary. The audit changes no behavior; public multi-beat syntax,
runtime-assertion `ARLEN` metadata, output-bank report vocabulary, and
transaction-list-driven helper paths are already present once coverage admits
the `r0`, `r1`, `r2`, and `r3` shape.

Three-static mixed dynamic/static read-data multi-beat behavior:
[AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR](../../AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md)
ships generated multi-beat output banks over generated one-dynamic plus
three-concrete-static mixed dynamic/static runtime-validation read-data. The
public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_multi_beat.ppif`
emits per-transaction output banks for `r0`, `r1`, `r2`, and `r3`,
including 64 generated `RDATA` lanes, 64 generated `RRESP` lanes, valid
masks, length outputs, scalar worst-observed `RRESP` aggregates, raw-`ARLEN`
storage, expected-beat storage, beat counters, lane capture, aggregate
update, and sixteen runtime beat-count/`RLAST` assertions. Reports mark
read-data residue empty and keep response-demux residue limited to
`same_id_ordering`.

Post three-static mixed dynamic/static multi-beat selector:
[AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_NEXT_SLICE_SELECTION.md)
selects `.339`, readiness audit for two-dynamic-plus-one-static mixed
dynamic/static write `BID` response-demux. The selector changes no behavior
and starts at write response-demux because it is the smallest
behavior-bearing boundary before read response-demux, read-data,
burst-length/runtime validation, or multi-beat output-bank widening can
depend on a combined multiple-dynamic-plus-static policy.

Two-dynamic/one-static mixed dynamic/static write response-demux readiness
audit:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_READINESS_AUDIT](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_READINESS_AUDIT.md)
selects `.340`, public contract selection for the two-dynamic-plus-one-static
mixed write `BID` response-demux boundary. The audit changes no behavior;
current mixed write admission and constructors still require exactly one
dynamic write transaction plus one, two, or three concrete static write
transactions, while the two-dynamic-plus-static shape needs an owned public
report/assertion contract that combines multi-dynamic active selected-ID
uniqueness with static concrete-ID reservations and dynamic-vs-static
exclusions.

Two-dynamic/one-static mixed dynamic/static write response-demux contract
selection:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md)
selects `.341`, direct generated behavior for bounded
two-dynamic-plus-one-static mixed dynamic/static write `BID` response-demux.
The selector changes no behavior. It chooses public sample stem
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif`,
support identity
`intent.ppif_axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic`,
focused behavior label `mixed_dynamic_static_write_demux_multi_dynamic`,
dynamic write transactions `w0`/`w1`, static write transaction `w2` with ID
`3`, the existing `bounded_multi_mixed_dynamic_static_write_bid_demux_contract`
report mode, `onehot0_mixed_write_request`, active dynamic selected-ID
uniqueness, static concrete-ID reservation/exclusion, and mixed response
active/unique assertion roles.

Two-dynamic/one-static mixed dynamic/static write response-demux behavior:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md)
ships `.341`, generated bounded two-dynamic-plus-one-static mixed
dynamic/static write `BID` response-demux. The support-accounted public sample
is
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif`.
The generated behavior captures dynamic `AWID` into selected-ID/busy state
for `w0` and `w1`, tracks static busy state for `w2` with concrete ID `3`,
requires onehot0 mixed write requests, prevents request-time capture of an
already-active sibling dynamic ID, keeps active dynamic selected IDs pairwise
unique, excludes static literal `4'd3` from dynamic request and active state,
and emits three generated completion pulses matched against raw `BID`.
Reports reuse `bounded_multi_mixed_dynamic_static_write_bid_demux_contract`
with list-shaped dynamic/static transaction fields and preserve the earlier
one-dynamic mixed write contracts.

The next exact owner after `.341` is `.342`, readiness audit for bounded
two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID`
response-demux.

Two-dynamic/one-static mixed dynamic/static read response-demux readiness
audit:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md)
selects `.343`, public contract selection for bounded
two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID`
response-demux. The audit changes no behavior. Mixed read admission and
construction still require exactly one dynamic read transaction plus one,
two, or three concrete static read transactions, while the two-dynamic-plus
static read shape needs an owned public contract for report mode, completion
source, transaction order, static-ID reservation, active dynamic selected-ID
uniqueness, static-ID exclusions, assertion names, diagnostics, validation,
residue, rollback, and next frontier before any generated behavior changes.

Two-dynamic/one-static mixed dynamic/static read response-demux contract
selection:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md)
selects `.344`, direct generated behavior for bounded
two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID`
response-demux. The selector changes no behavior. It chooses public sample
stem
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif`,
support identity
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic`,
focused behavior label `mixed_dynamic_static_read_demux_multi_dynamic`,
dynamic read transactions `r0`/`r1`, static read transaction `r2` with ID
`3`, report mode `bounded_multi_mixed_dynamic_static_read_rid_demux_contract`,
completion source `generated_multi_mixed_dynamic_static_read_demux`,
onehot0 mixed read requests, active dynamic selected-ID uniqueness,
static-ID reservation/exclusion, and raw `RID` response active/unique
assertion roles. The generated behavior remains unshipped until `.344`
lands.

Two-dynamic/one-static mixed dynamic/static read response-demux behavior:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md)
ships `.344`, generated bounded two-dynamic-plus-one-static mixed
dynamic/static read single-beat `RID` response-demux. The support-accounted
public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif`.
The generated behavior captures dynamic `ARID` into selected-ID/busy state
for `r0` and `r1`, tracks static busy state for `r2` with concrete ID `3`,
requires onehot0 mixed read requests, prevents request-time capture of an
already-active sibling dynamic ID, keeps active dynamic selected IDs pairwise
unique, excludes static literal `4'd3` from dynamic request and active state,
and emits three generated completion pulses matched against raw `RID`.
Reports reuse `bounded_multi_mixed_dynamic_static_read_rid_demux_contract`
with list-shaped dynamic/static transaction fields and preserve the earlier
one-dynamic mixed read single-beat contracts.

The next exact owner after `.344` is `.345`, readiness audit for bounded
two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID`/`RLAST`
response-demux.

Two-dynamic/one-static mixed dynamic/static read burst-last readiness audit:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md)
selects `.346`, public contract selection for bounded
two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID`/`RLAST`
response-demux. The audit changes no behavior. A scratch guarded strict-check
probe confirmed the current generated burst-last mixed dynamic/static read
boundary still fails closed for this shape. The next selector must settle the
sample stem, support identity, behavior label, last signal policy, report
mode `bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
completion source `generated_multi_mixed_dynamic_static_read_demux_last_beat`,
raw `RID` beat ownership assertions, final `RID && RLAST` completions,
diagnostics, validation, residue, rollback, and next frontier before any
generated behavior changes.

Two-dynamic/one-static mixed dynamic/static read burst-last contract
selection:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md)
selects `.347`, direct generated behavior for the bounded burst-last
`RID`/`RLAST` shape. The selected sample stem is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif`.
The contract uses dynamic reads `r0`/`r1`, static read `r2` with ID `3`,
one-bit last signal `axi0_rlast`, report mode
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
completion source `generated_multi_mixed_dynamic_static_read_demux_last_beat`,
raw `RID` beat ownership assertions independent of `RLAST`, final
`RID && RLAST` generated completions, and explicit read-data, raw `ARLEN`,
runtime-validation, and multi-beat residue. The selector changes no behavior.

Two-dynamic/one-static mixed dynamic/static read burst-last response-demux
behavior:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md)
ships `.347`, generated bounded two-dynamic-plus-one-static mixed
dynamic/static read burst-last `RID`/`RLAST` response-demux. The public sample
is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif`.
It captures dynamic `ARID` for `r0`/`r1`, tracks static busy state for `r2`,
preserves raw `RID` response ownership assertions independent of `RLAST`, and
emits generated completions only on final `RID && RLAST` matches. Read-data,
raw `ARLEN`, runtime-validation, and multi-beat behavior over this shape remain
explicit residue.

Two-dynamic/one-static mixed dynamic/static read burst-last read-data readiness:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_READINESS_AUDIT](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_READINESS_AUDIT.md)
selects `.349`, public contract selection for scalar last-beat read-data over
that generated `RID`/`RLAST` demux. The audit changes no behavior. A scratch
guarded strict-check probe reached the read-data coverage gate and failed
closed with the current one-dynamic plus two-static/three-static diagnostic.
The next selector must settle sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data.ppif`,
support identity, focused behavior label, scalar output names,
completion-validity vocabulary, validation, rollback, and raw `ARLEN`/runtime/
multi-beat residue before implementation.

Two-dynamic/one-static mixed dynamic/static read burst-last read-data contract:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_CONTRACT_SELECTION.md)
selects `.350`, direct generated behavior for scalar last-beat read-data over
that generated demux. The selector fixes sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data.ppif`,
support identity, coverage key, focused behavior label, generated
`axi0_rdata`/`axi0_rresp` inputs, `r0`/`r1`/`r2` scalar last-beat outputs, and
completion validity
`generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`.
Single-beat read-data over `.344`, raw `ARLEN`, runtime validation, and
multi-beat output banks remain future exact owners.

Two-dynamic/one-static mixed dynamic/static read burst-last read-data behavior:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_BEHAVIOR](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_BEHAVIOR.md)
ships `.350`, scalar last-beat read-data over that generated demux. The public
sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data.ppif`
keeps dynamic reads `r0`/`r1`, static read `r2`, final `RID && RLAST`
completion pulses, and static exclusion `4'd3`; it adds generated
`axi0_rdata`/`axi0_rresp` inputs and scalar last-beat `RDATA`/`RRESP` outputs
for all three transactions. Schedule JSON reports
`bounded_last_beat_read_data_contract`, completion validity
`generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`,
and generated capture rules for `r0`, `r1`, and `r2`. Report-only raw `ARLEN`,
runtime validation, multi-beat output banks, and the single-beat `.344`
read-data sibling remain future exact owners.

Post two-dynamic/one-static mixed dynamic/static read burst-last read-data
selector:
[AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_NEXT_SLICE_SELECTION.md)
selects `.352`, readiness audit for report-only raw-`ARLEN` burst-length
capture over the shipped `.350` scalar last-beat read-data boundary. The
selector changes no behavior. The audit must decide whether the `.350` public
sample should grow existing `burst-length` syntax directly, needs a public
contract selector first, needs helper/report cleanup first, or should defer
behind another prerequisite. Runtime validation, multi-beat output banks,
broader cardinalities, direct backend behavior, backend-language variants, and
VHDL remain separate owners.

Two-dynamic/one-static mixed dynamic/static read burst-last read-data
burst-length readiness:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_BURST_LENGTH_READINESS_AUDIT](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md)
selects `.353`, direct implementation of report-only raw-`ARLEN`
burst-length capture over the `.350` scalar last-beat read-data boundary. The
audit changes no behavior. The planned sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length.ppif`;
it should add generated `axi0_arlen`, per-transaction raw-`ARLEN` storage and
request-guarded capture rules for `r0`, `r1`, and `r2`, and report generated
burst-length inputs/storage/rules while runtime validation and multi-beat
output banks remain future owners.

Two-dynamic/one-static mixed dynamic/static read burst-last read-data
burst-length behavior:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_BURST_LENGTH_BEHAVIOR](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_BURST_LENGTH_BEHAVIOR.md)
ships `.353`, generated report-only raw-`ARLEN` burst-length capture over the
`.350` scalar last-beat read-data boundary. The public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length.ppif`
keeps dynamic reads `r0`/`r1`, static read `r2`, final `RID && RLAST`
completion pulses, and scalar last-beat `RDATA`/`RRESP` capture; it adds
generated `axi0_arlen`, raw-`ARLEN` storage for all three transactions, and
request-guarded burst-length capture rules. Runtime beat-count/`RLAST`
validation and multi-beat output banks remain future owners; `.353` advanced
to `.354`, the runtime-validation readiness audit.

Two-dynamic/one-static mixed dynamic/static read burst-last read-data
runtime-validation readiness:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md)
selects `.355`, direct implementation of runtime beat-count/`RLAST`
validation over the `.353` raw-`ARLEN` scalar last-beat read-data boundary. The
audit changes no behavior. The planned runtime sibling sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_runtime_assertion.ppif`;
it should add per-transaction expected-beat storage, read-beat counters,
request-time initialization, matched-read-beat increments, and four
beat-count/`RLAST` assertions for `r0`, `r1`, and `r2` while preserving
multi-beat output banks as a later owner.

Two-dynamic/one-static mixed dynamic/static read burst-last read-data
runtime-validation behavior:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md)
ships `.355`, generated runtime beat-count/`RLAST` validation over the
`.353` raw-`ARLEN` scalar last-beat read-data boundary. The public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_runtime_assertion.ppif`
keeps the `r0`/`r1` dynamic and `r2` static transaction bindings, raw `ARLEN`
capture, final `RID && RLAST` completion pulses, and scalar last-beat
`RDATA`/`RRESP` capture. It adds expected-beat storage, read-beat counters,
request-time initialization from `ARLEN + 1`, matched-read-beat increments,
and four beat-count/`RLAST` assertions per covered transaction. Multi-beat
output banks remain the next exact owner under `.356`.

Two-dynamic/one-static mixed dynamic/static read burst-last read-data
multi-beat readiness:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_MULTI_BEAT_READINESS_AUDIT](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md)
selects `.357`, direct implementation of generated multi-beat output banks
over the `.355` runtime-validation boundary. The audit changes no behavior.
The planned sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat.ppif`;
it should keep `r0`/`r1` dynamic and `r2` static matching, runtime
`ARLEN + 1` beat-count validation, and final `RID && RLAST` completion pulses,
then add per-beat output banks, valid masks, length outputs, and
worst-observed scalar `RRESP` aggregates for all three covered transactions.

Two-dynamic/one-static mixed dynamic/static read burst-last read-data
multi-beat behavior:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_MULTI_BEAT_BEHAVIOR](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_MULTI_BEAT_BEHAVIOR.md)
ships `.357`, generated multi-beat output banks over the `.355`
runtime-validation boundary. The public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat.ppif`
keeps the `r0`/`r1` dynamic and `r2` static transaction bindings, raw
`ARLEN` capture, runtime `ARLEN + 1` beat-count validation, and final
`RID && RLAST` completion pulses. It adds per-transaction `RDATA`/`RRESP`
lanes, valid masks, read-length outputs, and worst-observed scalar `RRESP`
aggregates for all three covered transactions. Read-data residue is empty for
this sample; response-demux residue keeps only same-ID ordering. Broader
cardinalities, same-cycle behavior, queues, direct backend behavior, backend
variants, VHDL, aliases, queued/blocking policy, and full-manager behavior
remain exact-owner work.

Post two-dynamic/one-static mixed dynamic/static read-data multi-beat
selector:
[AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_NEXT_SLICE_SELECTION.md)
selects `.359`, readiness audit for scalar single-beat read-data over the
`.344` generated two-dynamic-plus-one-static mixed dynamic/static read
single-beat `RID` response-demux. The planned sample, if the audit selects
direct implementation, is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data.ppif`.
The selector changes no behavior and leaves broader cardinalities,
same-cycle behavior, queues, backend variants, VHDL, aliases,
queued/blocking policy, and full-manager behavior as separate owners.

Two-dynamic/one-static mixed dynamic/static read single-beat read-data
readiness:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT.md)
selects `.360`, public contract selection for scalar single-beat read-data
over the `.344` generated two-dynamic-plus-one-static mixed dynamic/static
read single-beat `RID` response-demux. The audit changes no behavior. The
candidate sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data.ppif`,
and the selected report vocabulary should keep
`bounded_single_beat_read_data_contract` with generated mixed read
single-beat completion validity.

Two-dynamic/one-static mixed dynamic/static read single-beat read-data
contract:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION.md)
selects `.361`, direct generated behavior for bounded scalar single-beat
read-data over the `.344` generated two-dynamic-plus-one-static mixed
dynamic/static read single-beat `RID` response-demux. The selector changes no
behavior. The selected public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data.ppif`,
with report mode `bounded_single_beat_read_data_contract`, completion validity
`generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse`,
ordered transactions `r0`, `r1`, and `r2`, generated inputs `axi0_rdata` and
`axi0_rresp`, scalar data/status outputs for each transaction, and read-data
residue `rlast_completion`, `bursts`, and
`multi_beat_read_data_reassembly`.

Two-dynamic/one-static mixed dynamic/static read single-beat read-data
behavior:
[AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR](../../AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md)
ships `.361`, scalar single-beat `RDATA`/`RRESP` capture over the `.344`
generated two-dynamic-plus-one-static mixed dynamic/static read single-beat
`RID` response-demux. The support-accounted public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data.ppif`.
It keeps dynamic transactions `r0` and `r1`, static transaction `r2`, response
scope `single_beat`, no `RLAST` or `burst_length` metadata, generated inputs
`axi0_rdata`/`axi0_rresp`, scalar outputs for all three transactions, and
capture rules guarded by the generated single-beat completion pulses. The
read-data report uses completion validity
`generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse`
and keeps residue `rlast_completion`, `bursts`, and
`multi_beat_read_data_reassembly`.

Post two-dynamic/one-static mixed dynamic/static read-data selector:
[AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION.md)
selects `.363`, readiness audit for same-cycle request/response and
release-and-recapture behavior across generated dynamic and mixed
dynamic/static response-demux/read-data shapes. The selector changes no
behavior. The selected audit must decide whether request plus generated
completion, dynamic selected-ID release-and-recapture, or static busy
release-and-recapture can be widened directly while preserving capacity
accounting, generated assertions, report vocabulary, and scheduler conflict
assumptions.

Dynamic/mixed same-cycle readiness audit:
[AXI_IAL2_MANAGER_DYNAMIC_MIXED_SAME_CYCLE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_MIXED_SAME_CYCLE_READINESS_AUDIT.md)
selects `.364`, public contract selection for the first single-active dynamic
write `BID` same-cycle release-and-recapture boundary. Capacity admission
already accounts for same-cycle completion fan-in, but response-demux capture
still requires `!busy` and release uses a separate generated completion rule.
The first contract owner is deliberately narrower than static recapture,
mixed sibling request widening, read `RID`/`RLAST`, read-data payload capture,
queues, scoreboards, backend variants, and VHDL.

Dynamic write same-cycle recapture contract:
[AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_CYCLE_RECAPTURE_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_CYCLE_RECAPTURE_CONTRACT_SELECTION.md)
selected `.365`, direct generated behavior for single-active dynamic write
`BID` same-cycle release-and-recapture.
[AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_CYCLE_RECAPTURE_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_CYCLE_RECAPTURE_BEHAVIOR.md)
now ships that behavior through the existing dynamic write response-demux public
sample. The generated update emits `axi0_w0_dynamic_id_release_recapture`,
keeps `bounded_dynamic_write_bid_demux_contract`, adds
`same_cycle_release_recapture_policy` report vocabulary, changes release-only
to exclude a same-cycle request, and replaces the request-not-busy assertion
with `axi0_w0_dynamic_request_idle_or_releasing`. That behavior advanced to
`.366`, the next same-cycle/release-recapture selector.

Post dynamic write recapture selector:
[AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md)
selects `.367`, public contract selection for first single-active dynamic read
same-cycle release-and-recapture. The selector changes no behavior. The
single-active dynamic read `RID` and `RID && RLAST` paths are the closest
symmetric siblings after the write recapture slice, but the contract selection
must settle scope and read-data completion-pulse preservation before any
generator update.

Dynamic read same-cycle recapture contract:
[AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_CYCLE_RECAPTURE_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_CYCLE_RECAPTURE_CONTRACT_SELECTION.md)
selects `.368`, direct generated behavior for single-active dynamic read
single-beat `RID` same-cycle release-and-recapture. The selector changes no
behavior. The selected contract reuses the existing dynamic read response-demux
sample/source syntax, keeps `bounded_dynamic_read_rid_demux_contract`, adds
read-side `same_cycle_release_recapture_policy` vocabulary, and leaves
burst-last `RID && RLAST`, scalar last-beat read-data, burst-length/runtime,
multi-beat, multiple dynamic, mixed dynamic/static, backend, and VHDL behavior
to later owners.

Dynamic read same-cycle recapture behavior:
[AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_CYCLE_RECAPTURE_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_CYCLE_RECAPTURE_BEHAVIOR.md)
ships `.368`, generated single-active dynamic read single-beat `RID`
same-cycle release-and-recapture under the existing public sample. The generated
updates now include `axi0_r0_dynamic_id_release_recapture`, release-only excludes
a same-cycle request, the report records
`same_cycle_release_recapture_policy: single_active_dynamic_read`, and the
single-active request assertion is now
`axi0_r0_dynamic_request_idle_or_releasing`. Scalar single-beat dynamic
read-data remains a completion-pulse payload consumer; burst-last, scalar
last-beat read-data, burst-length/runtime/multi-beat recapture, multiple
dynamic, mixed dynamic/static, backend, and VHDL behavior remain later owners.

Post dynamic read recapture selector:
[AXI_IAL2_MANAGER_POST_DYNAMIC_READ_RECAPTURE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_DYNAMIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md)
selects `.370`, readiness audit for single-active dynamic read burst-last
`RID && RLAST` same-cycle release-and-recapture. The selector changes no
behavior. It chooses audit before direct implementation because burst-last
recapture affects final-beat completion, matched non-last beats, raw
active-match assertions, scalar last-beat read-data, report-only raw-`ARLEN`,
runtime beat-count/`RLAST`, and multi-beat output-bank consumers.

Dynamic read RLAST recapture readiness audit:
[AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md)
selects `.371`, public contract selection for single-active dynamic read
burst-last `RID && RLAST` same-cycle release-and-recapture. The audit changes
no behavior and found no lower cleanup prerequisite, but contract selection
must settle final-completion-only recapture, matched non-last beat behavior,
raw active-match assertions, scalar last-beat read-data preservation,
raw-`ARLEN`/runtime/multi-beat consumer boundaries, report vocabulary, and
assertion semantics before generator behavior changes.

Dynamic read RLAST recapture contract:
[AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md)
selects `.372`, direct generated behavior for single-active dynamic read
burst-last `RID && RLAST` same-cycle release-and-recapture. The selector
changes no behavior. The contract preserves the existing burst-last response
demux source syntax and `bounded_dynamic_read_rid_rlast_demux_contract`, uses
`generated_dynamic_demux_last_beat_completion` as the release-recapture
source, replaces the single-active burst-last request-not-busy assertion with
idle-or-releasing semantics, preserves raw matched non-last beats, and treats
scalar last-beat read-data, raw-`ARLEN`, runtime, and multi-beat output banks as
payload/validation preservation consumers.

Dynamic read RLAST recapture behavior:
[AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_BEHAVIOR](../../AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_BEHAVIOR.md)
ships `.372`, generated single-active dynamic read burst-last `RID && RLAST`
same-cycle release-and-recapture under the existing public sample. The generated
updates now include `axi0_r0_dynamic_id_release_recapture`, release-only excludes
a same-cycle request, the report records
`release_recapture_source: generated_dynamic_demux_last_beat_completion`, and
the burst-last single-active request assertion is now
`axi0_r0_dynamic_request_idle_or_releasing`. Matched non-last beats remain raw
matched beats only; scalar last-beat read-data, raw-`ARLEN`, runtime, and
multi-beat payload/validation contracts remain preserved consumers.

Post dynamic read RLAST recapture selector:
[AXI_IAL2_MANAGER_POST_DYNAMIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_DYNAMIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md)
selects `.374`, readiness audit for multiple all-dynamic same-cycle
release-and-recapture. The selector changes no behavior. Multiple all-dynamic
response-demux is the nearest broader recapture residue because it still uses
dynamic selected-ID/busy ownership, but it adds sibling onehot0 request policy,
active dynamic selected-ID uniqueness, request no-active-same-ID checks,
unique-match assertions, and burst-last raw non-final-beat handling.
Mixed dynamic/static recapture, static busy recapture, queues, scoreboards,
backend variants, VHDL, and full-manager behavior remain later owners.

Multiple dynamic recapture readiness audit:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_RECAPTURE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_RECAPTURE_READINESS_AUDIT.md)
selects `.375`, generated support-detail prose alignment for the shipped
single-active dynamic read burst-last release-and-recapture behavior before any
multiple-dynamic recapture contract. Guarded probes confirmed the multiple
dynamic write/read/read-RLAST samples still report onehot0 request policy,
active dynamic selected-ID uniqueness, request no-active-same-ID checks,
response unique-match assertions, request-not-busy assertions, and no
release-recapture fields. The same probes exposed stale generated support prose
saying the single-active dynamic read burst-last `RID/RLAST` shape is supported
without release-and-recapture and listing same-cycle recapture as future outside
only dynamic write plus read single-beat.

Dynamic recapture support-detail alignment:
[AXI_IAL2_MANAGER_DYNAMIC_RECAPTURE_SUPPORT_DETAIL_ALIGNMENT](../../AXI_IAL2_MANAGER_DYNAMIC_RECAPTURE_SUPPORT_DETAIL_ALIGNMENT.md)
ships `.375`, generated support-detail prose alignment for the shipped
single-active dynamic read burst-last release-and-recapture behavior. The
generated dynamic transaction-ID support detail now describes single-active
dynamic read single-beat `RID` matching and burst-last `RID/RLAST` matching as
including same-cycle release-and-recapture, and same-cycle recapture remains
future only outside the selected single-active dynamic write `BID`, read
single-beat `RID`, and read burst-last `RID/RLAST` demux boundaries at `.375`.
Parser syntax, PPIF samples, response-demux semantics, generated state/rules,
assertions, HDL, and runtime behavior are unchanged. The frontier advances to
`.376`, selection of the first multiple all-dynamic recapture contract owner.

Multiple dynamic recapture owner selection:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_RECAPTURE_CONTRACT_OWNER_SELECTION](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_RECAPTURE_CONTRACT_OWNER_SELECTION.md)
selects `.377`, public contract selection for multiple all-dynamic write `BID`
same-cycle release-and-recapture. The selector changes no behavior. It starts
on the write side because that shape exercises multi-active dynamic
selected-ID/busy ownership, onehot0 request policy, active-ID uniqueness,
request no-active-same-ID checks, response active-match, response unique-match,
and completion-active assertions without read-side `RLAST`, raw non-final-beat,
read-data, raw-`ARLEN`, runtime, or multi-beat preservation coupling. Multiple
dynamic read single-beat recapture, read burst-last recapture, mixed
dynamic/static recapture, static busy recapture, queues, scoreboards, backend
variants, VHDL, and full-manager behavior remain later exact owners.

Multiple dynamic write recapture contract:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RECAPTURE_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md)
selects `.378`, direct implementation of multiple all-dynamic write `BID`
same-cycle release-and-recapture for the existing
`ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif`
sample. The contract preserves public syntax, support accounting,
`bounded_multi_dynamic_write_bid_demux_contract`, and onehot0 request policy;
adds per-transaction `release_recapture_rule`,
`same_cycle_release_recapture_policy: multi_active_unique_dynamic_write`,
`release_recapture_source: generated_dynamic_demux_completion`, and
`release_recapture_transaction` report fields; replaces per-transaction
request-not-busy assertions with idle-or-releasing assertions; and preserves
no-active-same-ID, active-ID uniqueness, response active/unique-match, and
completion-active assertions. The selector changes no behavior.

Multiple dynamic write recapture behavior:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RECAPTURE_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RECAPTURE_BEHAVIOR.md)
ships `.378`, same-cycle release-and-recapture for the existing multiple
all-dynamic write `BID` response-demux sample. FSMGen emits per-transaction
`axi0_w0_dynamic_id_release_recapture` and
`axi0_w1_dynamic_id_release_recapture`, keeps release-only updates disjoint
from same-cycle own requests, reports `same_cycle_release_recapture_policy:
multi_active_unique_dynamic_write`, replaces per-transaction request-not-busy
assertions with idle-or-releasing assertions, and preserves source syntax,
support identity, generated completion names,
`bounded_multi_dynamic_write_bid_demux_contract`, onehot0 request policy,
no-active-same-ID, active-ID uniqueness, response active/unique-match, and
completion-active assertions. The next frontier is `.379`, the next
multiple-dynamic recapture selector.

Post multiple dynamic write recapture selector:
[AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md)
selects `.380`, public contract selection for multiple all-dynamic read
single-beat `RID` same-cycle release-and-recapture. The selector changes no
behavior. It chooses single-beat read before burst-last because the single-beat
shape shares the multi-active selected-ID/busy lifecycle, onehot0 request
policy, active-ID uniqueness, request no-active-same-ID, response
active/unique-match, and completion-active assertion structure without `RLAST`
final-beat, raw non-final beat, last-beat read-data, raw-`ARLEN`, runtime, or
multi-beat output-bank coupling. The `.380` contract selection must preserve
the existing `bounded_multi_dynamic_read_rid_demux_contract`, support identity,
generated completion pulses, scalar single-beat read-data consumer, validation
gates, rollback, and deferred burst-last/read-data/runtime/multi-beat
boundaries before implementation.

Multiple dynamic read recapture contract:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RECAPTURE_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RECAPTURE_CONTRACT_SELECTION.md)
selects `.381`, direct implementation of multiple all-dynamic read single-beat
`RID` same-cycle release-and-recapture for the existing
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif`
sample. The selector changes no behavior. The selected implementation must
preserve public syntax, support identity,
`bounded_multi_dynamic_read_rid_demux_contract`, generated demux rules,
generated completions, onehot0 request policy, no-active-same-ID, active-ID
uniqueness, response active/unique-match, completion-active assertions, and
scalar single-beat read-data capture over generated completion pulses while
adding per-transaction `multi_active_unique_dynamic_read` release-recapture
report fields and idle-or-releasing request assertions. At that point,
multiple dynamic burst-last recapture still required a later exact owner;
`.385` now ships it.

Multiple dynamic read recapture behavior:
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RECAPTURE_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RECAPTURE_BEHAVIOR.md)
ships `.381`, same-cycle release-and-recapture for the existing multiple
all-dynamic read single-beat `RID` response-demux sample. FSMGen now emits
`axi0_r0_dynamic_id_release_recapture` and
`axi0_r1_dynamic_id_release_recapture`, reports
`same_cycle_release_recapture_policy: multi_active_unique_dynamic_read` under
`response_demux.read.dynamic_capture.transactions[]`, replaces the two
per-transaction request-not-busy assertions with idle-or-releasing assertions,
and preserves `bounded_multi_dynamic_read_rid_demux_contract`, onehot0 request
policy, no-active-same-ID, active-ID uniqueness, response active/unique-match,
completion-active assertions, generated completion names, support identity, and
scalar single-beat read-data capture over generated completions. Multiple
dynamic read burst-last recapture then advanced through `.382`-`.385`; mixed
dynamic/static recapture advanced through `.386`-`.388` to `.389` mixed write
implementation. Static busy-only recapture outside that selected mixed write
boundary, queues, scoreboards, backend variants, VHDL, and full-manager
behavior remain later owners.

Post queue-head burst-length selector:
[AXI_IAL2_MANAGER_POST_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md)
selects generated queue-head beat-count/RLAST runtime validation for the same
bounded queue-head last-beat read-data shape as `.119`; `.119` now ships that
selected behavior.

Post queue-head runtime-validation selector:
[AXI_IAL2_MANAGER_POST_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md)
selected generated multi-beat read-data output-bank behavior for the bounded
read burst-last concrete same-ID queue-head demux shape as `.121`; `.121` now
ships that selected behavior.

First implementation subset selection:
[AXI_IAL2_FIRST_IMPLEMENTATION_SUBSET_SELECTION](../../AXI_IAL2_FIRST_IMPLEMENTATION_SUBSET_SELECTION.md)
selects a source-anchored AXI Valid-Ready channel contract/monitor as the
first safe AXI-derived IAL2 implementation subset. It is intentionally not the
full AXI manager; it must first prove reviewable `IAL2 -> IAL1/.isf ->
IAL0/.fsm -> HDL` lowering, source-anchor reporting, and explicit residue.

Implementation readiness audit:
[AXI_IAL2_VALID_READY_READINESS_AUDIT](../../AXI_IAL2_VALID_READY_READINESS_AUDIT.md)
mapped the existing code/test/docs/report owners for the first implementation
subset. It selected the in-process IAL2/protocol-intent generator boundary
that emits reviewable `.isf`, then uses the existing `FSM::Adapter::ISF` and
`FSM::Scheduler::ISF` path to emit reviewable `.fsm`. The audit explicitly
deferred public `.pif`/`.ppi`/`.ppif`/`.axi` CLI suffix support and the full
AXI manager until later owners.

First in-process generator slice:
[AXI_IAL2_VALID_READY_GENERATOR_FIRST_SLICE](../../AXI_IAL2_VALID_READY_GENERATOR_FIRST_SLICE.md)
ships the first behavior-bearing IAL2 protocol-intent entrypoint. It is not a
file parser and not a CLI suffix. It is an in-process API:

```perl
use FSM::IAL2::ProtocolIntent::ValidReadyChannel;

my $result = FSM::IAL2::ProtocolIntent::ValidReadyChannel->new()->generate({
    name     => 'axi_aw',
    protocol => 'axi4',
    channel  => 'AW',
    role     => 'manager-to-subordinate',
    clock    => 'clk',
    reset    => { signal => 'rst_n', active_low => 1, async => 1 },
    valid    => 'awvalid',
    ready    => 'awready',
    payload  => [
        { name => 'awaddr', width => 32 },
        { name => 'awlen',  width => 8 },
    ],
    source => {
        object_id => 'axi-valid-ready-aw',
        anchors => [
            { document => 'IHI0022_L_2025-08', section => 'A3.2.1', page => 'A3-40' },
        ],
    },
});
```

The result exposes `generated_ial1.text` before `generated_ial0.files`. The
generated `.isf` parses through `FSM::Adapter::ISF`, lowers through
`FSM::Scheduler::ISF`, and emits assertion carriers for the first owned safety
subset: prior-cycle stalled `VALID` remains asserted, and each payload/control
signal remains stable after a prior-cycle stall. The IAL2 report includes
source anchors, generated artifact names, bindings, `VALID && READY` as the
transfer/fire condition, generated assertions, assumptions, enforced static
rules, and explicit residue for reset-during-reset behavior, READY
independence, and full AXI manager concurrency.

User-facing AXI manager brainstorm:
[AXI_MANAGER_USER_API_BRAINSTORM](../../AXI_MANAGER_USER_API_BRAINSTORM.md)
captures the intended IAL2 surface direction for a future AXI manager. Easy
mode is conventions over configuration, not a reduced subset: users submit
logical reads/writes and the manager owns AXI legality, outstanding windows,
IDs, ordering, interleaving where permitted, response matching, backpressure,
and clear full/acceptance/status feedback. Power mode exposes structured
overrides while preserving manager enforcement. Raw channel access should
normally be supervised by the same AXI rule engine, with any unsafe bypass
treated as verification-only and unable to claim guaranteed AXI correctness.

Public file-surface decision:
[decision 0016](../../decisions/0016-ppif-is-first-public-ial2-container.md)
selects `.ppif` as the first generic IAL2 file suffix and records the first
public Valid-Ready source shape. The first parser/CLI slice for `.ppif` is now
shipped by
[IAL2_PPIF_PARSER_CLI_FIRST_SLICE](../../IAL2_PPIF_PARSER_CLI_FIRST_SLICE.md).
Public `.pif` and `.ppi` remain unshipped generic-container spellings. `.axi`
is now shipped only for the bounded AXI AW Valid-Ready profile-alias sample,
while `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, `.i2s`, and full AXI
manager profile-alias behavior remain unshipped. Multi-channel `.ppif`
Valid-Ready bundle report/review-artifact behavior is now shipped in the
bounded slice below; aggregate semantic JSON is shipped as a bundle semantic
root; and the tracked AW/W bundle now generates an aggregate wrapper/top HDL
entry.

First selected `.ppif` shape, checked in as
`ppif/axi_aw_valid_ready.ppif`:

```text
(protocol-platform-intent axi_aw_valid_ready
  (profile axi4)
  (source
    (object axi-valid-ready-aw)
    (anchor (document IHI0022_L_2025-08) (section A3.2.1) (page A3-40)))
  (valid-ready-channel axi_aw
    (channel AW)
    (role manager-to-subordinate)
    (clock clk)
    (reset (rst_n active_low async))
    (valid awvalid)
    (ready awready)
    (payload
      (awaddr width 32)
      (awlen width 8))))
```

CLI examples for the shipped first public slice:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_aw_valid_ready.ppif
./bin/fsmgen --outdir generated ppif/axi_aw_valid_ready.ppif
./bin/fsmgen --strict --check --json ppif/axi_aw_valid_ready.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_aw_valid_ready.ppif
```

Protocol-neutral Valid-Ready sample, checked in as
`ppif/valid_ready_handshake.ppif`:

```text
(protocol-platform-intent valid_ready_handshake
  (profile valid-ready)
  (source
    (object fsmgen-valid-ready-profile)
    (anchor (document FSMGEN-IAL2-VALID-READY-PROFILE) (section monitor) (page contract)))
  (valid-ready-channel data_link
    (channel data_link)
    (role producer-to-consumer)
    (clock clk)
    (reset (rst_n active_low async))
    (valid valid)
    (ready ready)
    (payload
      (data width 8))))
```

The same CLI modes work for the neutral sample:

```bash
./bin/fsmgen --emit-schedule-json ppif/valid_ready_handshake.ppif
./bin/fsmgen --outdir generated ppif/valid_ready_handshake.ppif
./bin/fsmgen --strict --check --json ppif/valid_ready_handshake.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/valid_ready_handshake.ppif
```

Protocol-neutral dual-channel Valid-Ready bundle, checked in as
`ppif/valid_ready_dual_channel_bundle.ppif`:

```text
(protocol-platform-intent valid_ready_dual_channel_bundle
  (profile valid-ready)
  (source
    (object fsmgen-valid-ready-dual-channel-bundle)
    (anchor (document FSMGEN-IAL2-VALID-READY-PROFILE) (section bundle) (page contract)))
  (valid-ready-channel data_downstream
    (source
      (object fsmgen-valid-ready-data-downstream)
      (anchor (document FSMGEN-IAL2-VALID-READY-PROFILE) (section monitor) (page producer-to-consumer)))
    (channel data_downstream)
    (role producer-to-consumer)
    (clock clk)
    (reset (rst_n active_low async))
    (valid data_valid)
    (ready data_ready)
    (payload
      (data width 8)))
  (valid-ready-channel status_upstream
    (channel status_upstream)
    (role consumer-to-producer)
    (clock clk)
    (reset (rst_n active_low async))
    (valid status_valid)
    (ready status_ready)
    (payload
      (status width 4))))
```

The same CLI modes work for the neutral bundle:

```bash
./bin/fsmgen --emit-schedule-json ppif/valid_ready_dual_channel_bundle.ppif
./bin/fsmgen --outdir generated --output valid_ready_dual_channel_bundle.sv ppif/valid_ready_dual_channel_bundle.ppif
./bin/fsmgen --strict --check --json ppif/valid_ready_dual_channel_bundle.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/valid_ready_dual_channel_bundle.ppif
```

The `.ppif` path always lowers through generated `.isf` before generated
`.fsm`. `--outdir` writes both review artifacts before the HDL path runs.
`--emit-schedule-json` emits the IAL2 source-anchor/residue report for the
source object, including the authored top-level PPIF intent name
`axi_aw_valid_ready`. `--emit-semantic-json` emits the bounded normalized
semantic report without writing HDL, while keeping `source.resolved_path` on
the public `.ppif` path and leaving the semantic payload rooted at the
generated `.fsm`. The capability manifest now advertises this file-layer stack
under `language_surface.file_surfaces`, including the `.ppif` sample path,
first-slice alias exclusions, and `supported_cli_modes[]` entries for
`--emit-schedule-json`, `--check --json` / `--check-json`, and
`--emit-semantic-json`. Later completed slices shipped public
`manager-capacity-status` `.ppif` syntax, optional static `(id-families ...)`
metadata, a selector for the next logical read/write
transaction-envelope/static-validation subset, and the readiness audit for its
additive static/report implementation boundary. The optional static
`(transactions ...)` implementation slice and the additive transaction event
dispatch/fan-in slice are now also shipped, and `.45` ships parser/report
metadata and static validation for the bounded public read-data payload/status
contract selected by `.44`. `.46` audits generated read-data capture behavior
readiness and selects `.47`, direct generated single-beat `RDATA`/`RRESP`
capture, with no new IAL1/IAL0/SystemVerilog prerequisite. `.47` ships that
generated capture behavior, `.48` selects AXI burst/`RLAST` completion
readiness, and `.49` selects public burst/`RLAST` completion contract
selection before parser/report metadata or generated behavior changes. The
`.50` selector chooses `response-scope burst-last` plus one-bit `last-signal`
as an additive read response-demux contract. `.51` ships parser/report
metadata and static validation for that contract with generated behavior
unchanged. `.52` selects direct generated burst-last/`RLAST` completion
behavior. `.53` ships that generated behavior. `.55` aligns the generated
report prose with shipped `RLAST` behavior. `.56` selects `.57`, public AXI
burst read-data contract selection, before parser/report metadata or generated
behavior changes. `.57` selects explicit last-beat read-data capture and
advances the frontier to `.58`, parser/report metadata and static validation.
`.58` ships that metadata with generated behavior deferred and advances the
frontier to `.59`, generated last-beat read-data capture readiness. `.59`
selects direct generated last-beat capture behavior and hands off to `.60`.
`.60` ships generated last-beat `RDATA`/`RRESP` capture behavior and hands off
to selector `.61`. `.61` selects public AXI burst read-data beat-count/depth
contract selection and hands off to `.62`. `.62` selects ARLEN-based
`burst-length` parser/report metadata and static validation and advances the
frontier to `.63`. `.63` ships that parser/report metadata and static
validation with a support-accounted sample while keeping generated artifacts
unchanged, then advances the frontier to `.64`. `.64` selects generated
ARLEN burst-length capture readiness and advances the frontier to `.65`.
`.65` audits that readiness, finds no new substrate prerequisite, and
advances the active frontier to `.66`. `.66` ships generated raw-ARLEN
capture behavior and advances the active frontier to `.67`, beat-count/RLAST
validation readiness. `.67` preserves `validation report-only` as
no-runtime-check behavior and selects `.68`, public runtime-validation
contract selection. `.68` selects `(validation runtime-assertion)` /
`runtime_assertion`, preserves report-only behavior, and advances the active
frontier to `.69`, the first generated beat-count/RLAST runtime-validation
implementation slice. `.69` ships that behavior and advances the active
frontier to `.70`, the next exact-owner selector.
Future behavior owners must keep the reviewable
`IAL2 -> IAL1 -> IAL0 -> SystemVerilog` path; read-data
interleaving/reassembly, bursts, per-ID queues, full-manager behavior, and
VHDL remain out of scope unless a later exact owner selects them.
Additional `.ppif` objects/clauses and profile aliases remain future
exact-owner work, and they must not jump ahead of the active selector unless
that selector records why.

Multi-channel `.ppif` bundle support:
[IAL2_PPIF_MULTI_VALID_READY_READINESS](../../IAL2_PPIF_MULTI_VALID_READY_READINESS.md)
records why accepting multiple `(valid-ready-channel ...)` objects required an
aggregate contract rather than a parser-only change. The bounded implementation
is documented in
[IAL2_PPIF_VALID_READY_BUNDLE_FIRST_SLICE](../../IAL2_PPIF_VALID_READY_BUNDLE_FIRST_SLICE.md).
It accepts multiple unique Valid-Ready channel objects, emits the
`fsmgen.ial2.protocol_intent.valid_ready_bundle.v1` report, writes per-channel
generated `.isf`/`.fsm` review artifacts plus an aggregate wrapper/top `.fsm`
with `--outdir`, supports aggregate normalized semantic JSON, generates
SystemVerilog through that wrapper/top, and keeps `IAL2 -> IAL1 -> IAL0`
intact.
The semantic JSON slice is documented in
[IAL2_PPIF_BUNDLE_SEMANTIC_JSON_FIRST_SLICE](../../IAL2_PPIF_BUNDLE_SEMANTIC_JSON_FIRST_SLICE.md).

Selected future bundle contract:
[IAL2_PPIF_VALID_READY_BUNDLE_CONTRACT_SELECTION](../../IAL2_PPIF_VALID_READY_BUNDLE_CONTRACT_SELECTION.md)
and decision
[0017-ppif-valid-ready-bundle-contract](../../decisions/0017-ppif-valid-ready-bundle-contract.md)
select an aggregate PPIF bundle report over per-channel generated `.isf` and
`.fsm` review artifacts. The shipped first bundle slice avoids a hidden
multi-actor `.isf` file and forbids "first channel wins" HDL selection.
Default HDL for the tracked multi-channel bundle now uses the aggregate
wrapper/top `.fsm` generated from the top-level PPIF intent name. Aggregate
semantic JSON is an aggregate PPIF bundle root, not one generated channel root.
The HDL entry contract and first implementation are documented in
[IAL2_PPIF_BUNDLE_HDL_ENTRY_SELECTION](../../IAL2_PPIF_BUNDLE_HDL_ENTRY_SELECTION.md):
bundle HDL must use an aggregate wrapper/top entry with reviewable generated
IAL1 and IAL0 artifacts, not "first channel wins" root selection. The shipped
implementation is recorded in
[IAL2_PPIF_BUNDLE_HDL_ENTRY_FIRST_SLICE](../../IAL2_PPIF_BUNDLE_HDL_ENTRY_FIRST_SLICE.md).

Runnable bundle commands:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_aw_w_valid_ready_bundle.ppif
./bin/fsmgen --outdir generated --output bundle.sv ppif/axi_aw_w_valid_ready_bundle.ppif
./bin/fsmgen --strict --check --json ppif/axi_aw_w_valid_ready_bundle.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_aw_w_valid_ready_bundle.ppif
./bin/fsmgen --outdir generated --output bundle.sv --verify-hdl ppif/axi_aw_w_valid_ready_bundle.ppif
```

The neutral bundle uses the same aggregate surfaces with neutral logical
channels and roles:

```bash
./bin/fsmgen --emit-schedule-json ppif/valid_ready_dual_channel_bundle.ppif
./bin/fsmgen --outdir generated --output valid_ready_dual_channel_bundle.sv ppif/valid_ready_dual_channel_bundle.ppif
./bin/fsmgen --strict --check --json ppif/valid_ready_dual_channel_bundle.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/valid_ready_dual_channel_bundle.ppif
```

The semantic export uses `semantic.module.source_root_kind = ppif_bundle` and
adds `semantic.protocol_intent_bundle`, including the bundle schema,
channel list, generated `.isf`/`.fsm` review artifact summaries, per-channel
schedule-report presence, and the selected aggregate wrapper/top HDL entry.
The wrapper/top HDL output contains the AW and W generated channel monitors and
the `axi_aw_w_valid_ready_bundle` wrapper module. The sampled-value assertions
keep `$past(...)` inside property text; sampled-value helper expressions are
not emitted as unclocked combinational assigns.

PDF extraction workflow:
[PDF_EXTRACTION_WORKFLOW](../../PDF_EXTRACTION_WORKFLOW.md)
documents the reusable source-anchored PDF extraction approach used for the
AXI evidence work. It covers task-tree ownership, metadata/hash checks, text
extraction, table handling, diagram/image rendering, visual QA,
troubleshooting, cleanup, validation, copyright hygiene, and the rule that
future flow improvements must update that document in the same task-owned
slice.

Protocol/platform surface decision:
[0014-protocol-platform-intent-surface-and-layered-lowering](../../decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md)
records the generic future IAL2 file-surface direction, the open
`.pif`/`.ppi`/`.ppif` extension candidates, and the required
`IAL2 -> IAL1 -> IAL0` lowering chain. Decision
[0016-ppif-is-first-public-ial2-container](../../decisions/0016-ppif-is-first-public-ial2-container.md)
selects `.ppif` as the first public generic IAL2 suffix.

Profile-extension refinement:
[0015-ial2-profile-extensions-are-vocabulary-aliases](../../decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md)
records that protocol-specific extensions may be accepted later as profile
aliases, not separate semantic layers.
