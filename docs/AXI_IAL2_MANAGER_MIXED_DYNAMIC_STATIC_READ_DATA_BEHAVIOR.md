# AXI IAL2 manager mixed dynamic/static read-data behavior

Date: 2026-06-23
Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.284`

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.284` ships generated bounded scalar
read-data capture over generated mixed dynamic/static read response-demux.

The support-accounted public samples are:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data.ppif
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data.ppif
```

The single-beat sample composes the `.276` generated mixed dynamic/static
single-beat `RID` demux with scalar `capture-scope single-beat` read-data.
The last-beat sample composes the `.280` generated mixed dynamic/static
burst-last `RID && RLAST` demux with scalar `capture-scope last-beat`
read-data.

## Source Shape

Both samples use exactly one dynamic read transaction and one concrete static
read transaction:

```text
(transactions
  (read r0 ... (id dynamic))
  (read r1 ... (id (value 3))))
```

The single-beat sample adds scalar read-data bindings for the ordered
dynamic-plus-static transaction set:

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
      (status-output axi0_r1_rresp))))
```

The last-beat sample uses `capture-scope last-beat`,
`status-policy last-beat`, `interleaving last-beat-by-rid`, and the scalar
last-beat output names `axi0_r0_last_rdata`/`axi0_r0_last_rresp` and
`axi0_r1_last_rdata`/`axi0_r1_last_rresp`.

## Generated Behavior

The generator now accepts scalar read-data over generated mixed
dynamic/static read demux when:

- `response-demux.read` is generated mixed dynamic/static read demux;
- the demux transaction completion source is
  `generated_mixed_dynamic_static_read_demux` for scalar single-beat capture
  or `generated_mixed_dynamic_static_read_demux_last_beat` for scalar
  last-beat capture;
- no `burst_length` metadata is present;
- the demux covers exactly one dynamic read transaction and one concrete
  static read transaction;
- `read-data.read.transactions` covers the ordered dynamic transactions
  followed by the ordered static transactions exactly once.

For each covered transaction the generated IAL1 includes:

- the shared `RDATA`/`RRESP` generated inputs;
- scalar data/status outputs;
- one read-data capture rule guarded only by that transaction's generated
  mixed demux completion pulse.

The public single-beat sample emits:

```text
(rule axi0_r0_read_data_capture axi0_r0_complete
  (axi0_r0_rdata axi0_rdata)
  (axi0_r0_rresp axi0_rresp))
(rule axi0_r1_read_data_capture axi0_r1_complete
  (axi0_r1_rdata axi0_rdata)
  (axi0_r1_rresp axi0_rresp))
```

The last-beat sample emits the same capture-rule names, guarded by the same
generated completion pulses, but captures into the `*_last_rdata` and
`*_last_rresp` outputs.

## Report Contract

The single-beat read-data report keeps:

```text
read_data.mode = bounded_single_beat_read_data_contract
read_data.read.completion_validity =
  generated_mixed_dynamic_static_read_response_demux_completion_pulse
read_data.read.transactions = r0, r1
```

The last-beat read-data report keeps:

```text
read_data.mode = bounded_last_beat_read_data_contract
read_data.read.completion_validity =
  generated_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse
read_data.read.transactions = r0, r1
```

Both reports map `r0` to `axi0_r0_complete` and `r1` to
`axi0_r1_complete`, list `axi0_rdata`/`axi0_rresp` as generated inputs, and
list the two scalar capture rules as generated read-data rules.

The response-demux report remains the response-demux owner:

- `bounded_mixed_dynamic_static_read_rid_demux_contract` for the single-beat
  sample;
- `bounded_mixed_dynamic_static_read_rid_rlast_demux_contract` for the
  last-beat sample.

## Diagnostics And Residue

The mixed dynamic/static read-data coverage branch is deliberately bounded.
It rejects unsupported capture scope/source combinations, any `burst_length`
metadata in this slice, transaction sets that are not exactly one dynamic
plus one concrete static read transaction, and generated completion-signal
counts that do not match the covered transaction list.

The existing read-data binding validator still rejects missing, duplicate, or
uncovered transaction bindings after the branch selects the generated mixed
dynamic/static transaction set.

Burst-length/runtime validation, multi-beat output banks, multiple mixed
transactions, same-cycle widening, release-and-recapture, dynamic same-ID
queues, scoreboards, direct backend behavior, backend-language variants, and
VHDL remain future exact owners.

## Validation

Validation for `.284` included:

```text
env -u PERL5LIB perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
env -u PERL5LIB perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
env -u PERL5LIB perl -Iperl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
env -u PERL5LIB perl -Iperl -c t/248-regression-corpus-accounting.t
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data.ppif
env -u PERL5LIB ./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data.ppif
env -u PERL5LIB ./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data.ppif
env -u PERL5LIB ./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data.ppif
env -u PERL5LIB ./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data.ppif
env -u PERL5LIB ./bin/fsmgen --verify-hdl --output /tmp/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data.sv ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data.ppif
env -u PERL5LIB ./bin/fsmgen --verify-hdl --output /tmp/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data.sv ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data.ppif
prove -Iperl t/248-regression-corpus-accounting.t
scripts/run_with_ram_guard.sh --host-max-pct 93 --process-max-rss-mb 4096 -- prove -Iperl t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
```
