# AXI IAL2 manager multiple dynamic read-data behavior

Date: 2026-06-23
Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.259`

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.259` ships generated bounded scalar
read-data capture over generated multiple dynamic read response-demux.

The supported public samples are:

```text
ppif/axi_manager_capacity_status_dynamic_read_data_multi.ppif
ppif/axi_manager_capacity_status_dynamic_read_data_multi_last_beat.ppif
```

The single-beat sample composes the `.251` generated multiple dynamic read
single-beat `RID` demux with scalar `capture-scope single-beat` read-data.
The last-beat sample composes the `.255` generated multiple dynamic read
burst-last `RID && RLAST` demux with scalar `capture-scope last-beat`
read-data.

## Source Shape

Both samples use two all-dynamic read transactions under the existing
`response-demux.read` syntax:

```text
(transactions
  (read r0 ... (id dynamic))
  (read r1 ... (id dynamic)))
```

The single-beat sample adds scalar read-data bindings for every generated
dynamic read demux transaction:

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

The last-beat sample uses the same exact transaction coverage with
`capture-scope last-beat`, `status-policy last-beat`, and last-beat output
names.

## Generated Behavior

The generator now accepts scalar read-data over generated dynamic read demux
when:

- `response-demux.read` is generated dynamic read demux;
- the demux transaction completion source is `generated_dynamic_demux` for
  scalar single-beat capture or `generated_dynamic_demux_last_beat` for scalar
  last-beat capture;
- no dynamic `burst_length` metadata is present;
- `read-data.read.transactions` covers every generated dynamic read demux
  transaction exactly once.

For each covered transaction the generated IAL1 includes:

- the shared `RDATA`/`RRESP` generated inputs;
- scalar data/status outputs;
- one read-data capture rule guarded by that transaction's generated dynamic
  completion pulse.

For the public two-transaction single-beat sample, the generated capture rules
are:

```text
axi0_r0_read_data_capture
axi0_r1_read_data_capture
```

For the last-beat sample, the same rule names capture into
`axi0_r0_last_rdata`/`axi0_r0_last_rresp` and
`axi0_r1_last_rdata`/`axi0_r1_last_rresp`.

## Report Contract

The single-beat report keeps:

```text
read_data.mode = bounded_single_beat_read_data_contract
read_data.read.completion_validity =
  generated_dynamic_read_response_demux_completion_pulse
```

The last-beat report keeps:

```text
read_data.mode = bounded_last_beat_read_data_contract
read_data.read.completion_validity =
  generated_dynamic_read_response_demux_last_beat_completion_pulse
```

Both reports list all covered dynamic read transactions in source order and map
each transaction to its generated demux completion pulse. `generated_inputs`,
`generated_outputs`, and `generated_rules` are the aggregate scalar read-data
artifacts across the covered transaction set.

The response-demux report remains the response-demux owner:

- `bounded_multi_dynamic_read_rid_demux_contract` for the single-beat sample;
- `bounded_multi_dynamic_read_rid_rlast_demux_contract` for the last-beat
  sample.

## Diagnostics And Residue

The existing read-data transaction coverage validation now applies to the
multiple dynamic transaction set:

- missing read-data bindings for generated dynamic read demux transactions are
  rejected;
- duplicate read-data transaction bindings are rejected;
- read-data bindings for transactions outside the generated dynamic demux set
  are rejected;
- completion-count mismatches between generated dynamic demux completions and
  covered transactions are rejected.

Dynamic burst-length/runtime validation and dynamic multi-beat output-bank
coverage remain limited to the selected single-active dynamic read-data
owners. Multiple dynamic read demux with `burst_length`, runtime beat-count
validation, or multi-beat output banks remains explicit future work.

The selected behavior also does not widen mixed dynamic/static demux,
same-cycle request behavior beyond onehot0, release-and-recapture, dynamic
same-ID queues, scoreboards, direct backend behavior, backend-language
variants, or VHDL.

## Validation

Validation for `.259` included:

```text
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -c perl/FSM/Support/RegressionCorpus.pm
perl -c t/1436-ial2-ppif-parser-cli.t
perl -c t/1437-axi-ial2-manager-capacity-status-generator.t
perl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
perl -c t/248-regression-corpus-accounting.t
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_data_multi.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_dynamic_read_data_multi.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_dynamic_read_data_multi.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_data_multi_last_beat.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_dynamic_read_data_multi_last_beat.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_dynamic_read_data_multi_last_beat.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_dynamic_read_data_multi.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_dynamic_read_data_multi_last_beat.ppif
prove -Iperl t/248-regression-corpus-accounting.t
scripts/run_with_ram_guard.sh --host-max-pct 93 --process-max-rss-mb 4096 -- prove -Iperl t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
```

The broader guarded `t/1437-axi-ial2-manager-capacity-status-generator.t`
attempt was stopped by the RAM guard when host memory reached the configured
93% cutoff before TAP output completed.
