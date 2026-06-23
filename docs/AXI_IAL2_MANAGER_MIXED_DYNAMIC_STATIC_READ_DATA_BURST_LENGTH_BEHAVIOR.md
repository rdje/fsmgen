# AXI IAL2 Manager Mixed Dynamic/Static Read-Data Burst-Length Behavior

Date: 2026-06-23
Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.287`

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.287` ships generated report-only
raw-`ARLEN` burst-length capture over generated mixed dynamic/static read
burst-last response-demux and scalar last-beat read-data.

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length.ppif
```

## Source Shape

The sample extends the `.284` mixed dynamic/static last-beat read-data sample.
It still uses exactly one dynamic read transaction and one concrete static
read transaction:

```text
(transactions
  (read r0 ... (id dynamic))
  (read r1 ... (id (value 3))))
```

The `read-data.read` clause adds the existing shipped `burst-length` syntax:

```text
(burst-length
  (source arlen)
  (signal axi0_arlen (width 8))
  (encoding axlen-plus-one)
  (capture request)
  (max-beats 16)
  (validation report-only))
```

The response-demux remains generated mixed dynamic/static read burst-last
`RID && RLAST` demux. The scalar payload/status output bindings stay
transaction-local:

```text
(transaction r0
  (data-output axi0_r0_last_rdata)
  (status-output axi0_r0_last_rresp))
(transaction r1
  (data-output axi0_r1_last_rdata)
  (status-output axi0_r1_last_rresp))
```

## Generated Behavior

The generator now accepts mixed dynamic/static read-data with burst-length
metadata only when:

- `response-demux.read` is generated mixed dynamic/static read burst-last
  demux;
- `read-data.read` uses `capture-scope last-beat`;
- the burst-length metadata uses `validation report-only`;
- the demux covers exactly one dynamic read transaction and one concrete
  static read transaction; and
- `read-data.read.transactions` covers the ordered dynamic-plus-static
  transaction set exactly once.

For the public sample the generated IAL1 adds:

```text
(input axi0_arlen (width 8))
(var axi0_r0_arlen_q (width 8))
(var axi0_r1_arlen_q (width 8))
(rule axi0_r0_burst_length_capture axi0_r0_request
  (axi0_r0_arlen_q axi0_arlen))
(rule axi0_r1_burst_length_capture axi0_r1_request
  (axi0_r1_arlen_q axi0_arlen))
```

Scalar `RDATA`/`RRESP` capture remains guarded only by each transaction's
generated mixed `RID && RLAST` completion pulse:

```text
(rule axi0_r0_read_data_capture axi0_r0_complete
  (axi0_r0_last_rdata axi0_rdata)
  (axi0_r0_last_rresp axi0_rresp))
(rule axi0_r1_read_data_capture axi0_r1_complete
  (axi0_r1_last_rdata axi0_rdata)
  (axi0_r1_last_rresp axi0_rresp))
```

No expected-beat storage, read-beat counter storage, beat-count rules, or
runtime assertions are generated in this report-only slice.

## Report Contract

The read-data report remains a bounded last-beat scalar read-data contract:

```text
read_data.mode = bounded_last_beat_read_data_contract
read_data.read.completion_validity =
  generated_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse
read_data.read.burst_length_source = arlen_signal
read_data.read.burst_length_validation = report_only
```

For the public sample the generated burst-length artifact lists are:

```text
generated_burst_length_inputs  = [axi0_arlen]
generated_burst_length_storage = [axi0_r0_arlen_q, axi0_r1_arlen_q]
generated_burst_length_rules   = [axi0_r0_burst_length_capture,
                                  axi0_r1_burst_length_capture]
```

## Diagnostics And Residue

This behavior is deliberately bounded. The generator still rejects:

- mixed dynamic/static single-beat read-data with `burst-length`;
- mixed dynamic/static last-beat read-data with `validation runtime-assertion`;
- mixed dynamic/static multi-beat read-data;
- transaction sets that are not exactly one dynamic read plus one concrete
  static read;
- missing, duplicate, partial, or extra read-data transaction bindings; and
- generated completion signal counts that do not match the covered
  transaction list.

Runtime beat-count/`RLAST` validation over the mixed raw-`ARLEN` shape,
multi-beat output banks, multiple mixed dynamic/static transactions,
same-cycle widening, release-and-recapture, dynamic same-ID queues,
scoreboards, direct backend behavior, backend-language variants, and VHDL
remain future exact owners.

## Validation

Validation for `.287` included focused syntax checks, direct schedule/check/
semantic/verify-HDL probes for the public sample, support-accounting
validation, the focused mixed/dynamic test, mdBook build, Knowledge Map
generation/check, memory architecture checks, whitespace checks, and the full
doctrine gate.
