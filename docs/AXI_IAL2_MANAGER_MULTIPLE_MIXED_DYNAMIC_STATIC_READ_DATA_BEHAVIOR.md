# AXI IAL2 Manager Multiple Mixed Dynamic/Static Read-Data Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.307`

Date: 2026-06-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.307` ships generated bounded scalar
read-data capture over generated multiple mixed dynamic/static read
response-demux.

The support-accounted public samples are:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_read_data.ppif
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data.ppif
```

The single-beat sample composes the `.299` generated multiple mixed
single-beat `RID` response-demux with scalar `capture-scope single-beat`
read-data. The last-beat sample composes the `.303` generated multiple mixed
burst-last `RID && RLAST` response-demux with scalar `capture-scope
last-beat` read-data.

## Public Shape

Both samples use exactly one dynamic read transaction and exactly two
pairwise-distinct concrete static read transactions:

```text
(transactions
  (read r0 ... (id dynamic))
  (read r1 ... (id (value 3)))
  (read r2 ... (id (value 5))))
```

The single-beat sample adds scalar read-data bindings for the ordered
dynamic-then-static transaction set:

```text
(read-data
  (read
    (capture-scope single-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (interleaving single-beat-by-rid)
    (transaction r0
      (data-output axi0_r0_rdata)
      (status-output axi0_r0_rresp))
    (transaction r1
      (data-output axi0_r1_rdata)
      (status-output axi0_r1_rresp))
    (transaction r2
      (data-output axi0_r2_rdata)
      (status-output axi0_r2_rresp))))
```

The last-beat sample uses `capture-scope last-beat`, `status-policy
last-beat`, `interleaving last-beat-by-rid`, and the scalar last-beat output
names `axi0_r0_last_rdata`/`axi0_r0_last_rresp`,
`axi0_r1_last_rdata`/`axi0_r1_last_rresp`, and
`axi0_r2_last_rdata`/`axi0_r2_last_rresp`.

## Generated Behavior

The generator now accepts scalar read-data over generated multiple mixed
dynamic/static read demux when:

- `response-demux.read` is generated multiple mixed dynamic/static read demux;
- the demux transaction completion source is
  `generated_multi_mixed_dynamic_static_read_demux` for scalar single-beat
  capture or `generated_multi_mixed_dynamic_static_read_demux_last_beat` for
  scalar last-beat capture;
- no `burst_length` metadata is present;
- the demux covers exactly one dynamic read transaction and exactly two
  concrete static read transactions; and
- `read-data.read.transactions` covers the ordered dynamic transactions
  followed by the ordered static transactions exactly once.

For each covered transaction the generated IAL1 includes:

- the shared `RDATA`/`RRESP` generated inputs;
- scalar data/status outputs; and
- one read-data capture rule guarded only by that transaction's generated
  multiple mixed demux completion pulse.

The public single-beat sample emits:

```text
(rule axi0_r0_read_data_capture axi0_r0_complete
  (axi0_r0_rdata axi0_rdata)
  (axi0_r0_rresp axi0_rresp))
(rule axi0_r1_read_data_capture axi0_r1_complete
  (axi0_r1_rdata axi0_rdata)
  (axi0_r1_rresp axi0_rresp))
(rule axi0_r2_read_data_capture axi0_r2_complete
  (axi0_r2_rdata axi0_rdata)
  (axi0_r2_rresp axi0_rresp))
```

The last-beat sample emits the same capture-rule names, guarded by the same
generated completion pulses, but captures into the `*_last_rdata` and
`*_last_rresp` outputs. It does not generate `axi0_arlen`.

## Report Contract

The single-beat read-data report keeps:

```text
read_data.mode = bounded_single_beat_read_data_contract
read_data.read.completion_validity =
  generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse
read_data.read.transactions = r0, r1, r2
read_data.residue = rlast_completion, bursts, multi_beat_read_data_reassembly
```

The last-beat read-data report keeps:

```text
read_data.mode = bounded_last_beat_read_data_contract
read_data.read.completion_validity =
  generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse
read_data.read.transactions = r0, r1, r2
read_data.residue =
  multi_beat_read_data_reassembly, per_beat_outputs, rresp_aggregation,
  arlen_or_beat_count_validation
```

Both reports map `r0`, `r1`, and `r2` to `axi0_r0_complete`,
`axi0_r1_complete`, and `axi0_r2_complete`, list `axi0_rdata`/`axi0_rresp`
as generated inputs, and list the three scalar capture rules as generated
read-data rules.

The response-demux report remains the response-demux owner:

- `bounded_multi_mixed_dynamic_static_read_rid_demux_contract` for the
  single-beat sample; and
- `bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract` for the
  last-beat sample.

## Diagnostics And Residue

The multiple mixed dynamic/static read-data coverage branch is deliberately
bounded. It rejects unsupported capture scope/source combinations, any
`burst_length` metadata in this slice, transaction sets that are not exactly
one dynamic plus two concrete static read transactions, and generated
completion-signal counts that do not match the covered transaction list.

The existing read-data binding validator still rejects missing, duplicate, or
uncovered transaction bindings after the branch selects the generated
multiple mixed transaction set.

Raw `ARLEN` burst-length capture, runtime beat-count/`RLAST` validation,
multi-beat output banks, two-dynamic plus one-static mixed cardinality,
broader mixed cardinalities, same-cycle widening, release-and-recapture,
dynamic same-ID queues, scoreboards, direct backend behavior,
backend-language variants, and VHDL remain future exact owners.
As of `IAL2-FEATURE-COMPLETENESS-FRONTIER.411`, the underlying
one-dynamic-plus-two-static single-beat response-demux also supports
same-cycle release-and-recapture. This read-data owner remains preserved: the
single-beat read-data report still uses
`generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse`
for `r0`, `r1`, and `r2`, and no raw-`ARLEN`, runtime, multi-beat, or
burst-last read-data behavior changes in `.411`.

## Validation

Validation for `.307` included syntax checks for the touched generator,
support catalog, and focused tests. Guarded filtered `t/1438` attempts at the
standard 88% host cutoff and the documented 90% retry stopped before
assertion output because host memory was already above the cutoff. A guarded
direct strict-check CLI probe for the single-beat public sample also stopped
before execution at the 88% cutoff when host memory was 92.2%; no unsafe
higher-cutoff retry was run. No failed assertion was observed from those
guarded attempts.

Lightweight adapter/report/rule probes confirmed both public samples parse,
emit all three read-data capture rules and all three response-demux rules,
bind `r0`, `r1`, and `r2` to generated completion pulses, report the selected
completion-validity strings, and keep `axi0_arlen` absent. A direct normal
frontend HDL-lowering probe confirmed the second static transaction's
single-beat and last-beat capture enables and next-state assignments.

Closeout also runs the Knowledge Map, mdBook, memory, whitespace, and doctrine
gates.

## Rollback

Rollback is the `.307` implementation commit. Reverting it removes the public
multi-static mixed read-data PPIF samples, support-accounting entries,
generated multiple mixed read-data coverage, focused tests, docs, and facts,
restoring `.307` as the active implementation frontier.
