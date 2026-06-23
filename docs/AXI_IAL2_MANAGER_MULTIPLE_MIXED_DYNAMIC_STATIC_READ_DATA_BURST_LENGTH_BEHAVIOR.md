# AXI IAL2 Manager Multiple Mixed Dynamic/Static Read-Data Burst-Length Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.310`

Date: 2026-06-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.310` ships generated report-only
raw-`ARLEN` burst-length capture over generated multiple mixed dynamic/static
read burst-last response-demux and scalar last-beat read-data.

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length.ppif
```

## Public Shape

The sample extends the `.307` multiple mixed dynamic/static last-beat
read-data shape. It still covers exactly one dynamic read transaction followed
by exactly two pairwise-distinct concrete static read transactions:

```text
(transactions
  (read r0 ... (id dynamic))
  (read r1 ... (id (value 3)))
  (read r2 ... (id (value 5))))
```

The `response-demux.read` clause remains generated burst-last
`RID && RLAST` response demux, and the `read-data.read` clause uses scalar
last-beat capture with the existing `burst-length` syntax:

```text
(burst-length
  (source arlen)
  (signal axi0_arlen (width 8))
  (encoding axlen-plus-one)
  (capture request)
  (max-beats 16)
  (validation report-only))
```

## Generated Behavior

The generator now accepts this multiple mixed dynamic/static burst-length
boundary only when:

- `response-demux.read` is generated multiple mixed dynamic/static read
  burst-last response-demux;
- `read-data.read` uses `capture-scope last-beat`;
- `burst-length` uses `validation report-only`;
- the demux covers exactly one dynamic read transaction and exactly two
  concrete static read transactions; and
- `read-data.read.transactions` covers the ordered dynamic-then-static
  transaction set exactly once.

For the public sample the generated IAL1 adds:

- generated input `axi0_arlen`;
- raw request-time ARLEN storage `axi0_r0_arlen_q`, `axi0_r1_arlen_q`, and
  `axi0_r2_arlen_q`;
- request-guarded capture rules `axi0_r0_burst_length_capture`,
  `axi0_r1_burst_length_capture`, and `axi0_r2_burst_length_capture`; and
- scalar last-beat `RDATA`/`RRESP` capture rules that remain guarded only by
  `axi0_r0_complete`, `axi0_r1_complete`, and `axi0_r2_complete`.

Report data marks `burst_length_validation: report_only`, lists
`generated_burst_length_inputs`, `generated_burst_length_storage`, and
`generated_burst_length_rules`, and uses
`generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`
as the completion-validity string.

## Boundaries

The report-only shape does not emit runtime beat-count storage, expected-beat
storage, ARLEN bound assertions, or RLAST timing assertions. Runtime
beat-count/`RLAST` validation over this multiple mixed raw-`ARLEN` boundary,
multi-beat output banks, broader mixed dynamic/static cardinalities,
same-cycle widening, release-and-recapture, dynamic same-ID queues,
scoreboards, direct backend behavior, backend-language variants, and VHDL
remain separate exact owners.

## Validation

The implementation is covered by the support-accounted public sample, focused
dynamic transaction-ID test coverage, support-accounting coverage, syntax
checks, schedule/report/HDL probes, mdBook, Knowledge Map, memory, diff, and
doctrine gates recorded in the owning task-tree leaf.
