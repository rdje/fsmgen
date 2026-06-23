# AXI IAL2 Manager Multiple Dynamic Read-Data Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.258`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.259`, direct generated behavior for
bounded scalar read-data over generated multiple dynamic read response-demux.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Public Source Shapes

The `.259` implementation should add two support-accounted public PPIF
samples:

```text
ppif/axi_manager_capacity_status_dynamic_read_data_multi.ppif
ppif/axi_manager_capacity_status_dynamic_read_data_multi_last_beat.ppif
```

The single-beat sample should compose the `.251` multiple dynamic read
single-beat response-demux shape with scalar read-data:

```lisp
(transactions
  (read r0
    (tag rd0)
    (request axi0_r0_request)
    (completion axi0_r0_complete)
    (id dynamic))
  (read r1
    (tag rd1)
    (request axi0_r1_request)
    (completion axi0_r1_complete)
    (id dynamic)))

(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))

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

The last-beat sample should compose the `.255` multiple dynamic read
burst-last/`RLAST` response-demux shape with scalar last-beat read-data:

```lisp
(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))

(read-data
  (read
    (capture-scope last-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (status-policy last-beat)
    (interleaving last-beat-by-rid)
    (transaction r0
      (data-output axi0_r0_last_rdata)
      (status-output axi0_r0_last_rresp))
    (transaction r1
      (data-output axi0_r1_last_rdata)
      (status-output axi0_r1_last_rresp))))
```

Both samples remain all-dynamic read-family shapes. Mixed dynamic/static read
demux remains future work.

## Public Boundary

The `.259` behavior should accept only scalar read-data over generated
multiple dynamic read response-demux:

- two or more read transactions are present;
- every read transaction in the selected read family uses `(id dynamic)`;
- `response-demux.read.transaction-completion` is `generated`;
- `response-demux.read` is either `response-scope single-beat` with no
  `last-signal`, or `response-scope burst-last` with a one-bit `last-signal`;
- `read-data.read.completion-source` is `response-demux`;
- `capture-scope single-beat` is accepted only with generated multiple
  dynamic single-beat response-demux and no `status-policy` or
  `burst-length`;
- `capture-scope last-beat` is accepted only with generated multiple dynamic
  burst-last response-demux, `status-policy last-beat`, and no
  `burst-length`;
- `read-data.read.transactions` must bind every generated dynamic read demux
  transaction exactly once;
- no extra transaction bindings are accepted; and
- `capture-scope multi-beat`, `burst-length`, runtime beat-count/`RLAST`
  validation, and status aggregation stay fail-closed over multiple dynamic
  read demux.

The first implementation should not widen same-cycle request admission,
release-and-recapture, dynamic same-ID queues, scoreboards, direct backend
behavior, backend-language variants, or VHDL.

## Completion And Capture Semantics

Read-data capture consumes generated completion pulses. It does not create a
second raw `RID` or `RID && RLAST` match path.

For the single-beat sample, each generated completion pulse is a matched raw
single-beat `RID` response for that captured dynamic ID. The read-data capture
rules are:

```text
axi0_r0_complete -> capture axi0_rdata/axi0_rresp into r0 outputs
axi0_r1_complete -> capture axi0_rdata/axi0_rresp into r1 outputs
```

For the last-beat sample, each generated completion pulse is a matched final
`RID && RLAST` response for that captured dynamic ID. Non-last raw matched
beats remain owned by response-demux assertions and do not update scalar
last-beat read-data outputs.

The transaction-to-completion mapping comes from
`response_demux.read.dynamic_transactions` and
`response_demux.read.generated_completion_signals`. The order of those two
lists must match, and their lengths must match the covered transaction set.

## Report Vocabulary

The single-beat report should keep the existing scalar mode:

```yaml
read_data:
  mode: bounded_single_beat_read_data_contract
  generated_behavior: true
  read:
    capture_scope: single_beat
    completion_source: response_demux
    completion_validity: generated_dynamic_read_response_demux_completion_pulse
    interleaving_policy: single_beat_by_rid
    transactions:
      - transaction: r0
        completion_signal: axi0_r0_complete
        data_output: axi0_r0_rdata
        status_output: axi0_r0_rresp
      - transaction: r1
        completion_signal: axi0_r1_complete
        data_output: axi0_r1_rdata
        status_output: axi0_r1_rresp
```

The last-beat report should keep the existing scalar last-beat mode:

```yaml
read_data:
  mode: bounded_last_beat_read_data_contract
  generated_behavior: true
  read:
    capture_scope: last_beat
    completion_source: response_demux
    completion_validity: generated_dynamic_read_response_demux_last_beat_completion_pulse
    status_policy: last_beat
    interleaving_policy: last_beat_by_rid
    burst_length_source: rlast_only
    burst_length_validation: not_generated
    transactions:
      - transaction: r0
        completion_signal: axi0_r0_complete
        data_output: axi0_r0_last_rdata
        status_output: axi0_r0_last_rresp
      - transaction: r1
        completion_signal: axi0_r1_complete
        data_output: axi0_r1_last_rdata
        status_output: axi0_r1_last_rresp
```

The generated read-data artifacts should list the shared generated inputs
`axi0_rdata` and `axi0_rresp`, per-transaction scalar data/status outputs,
and per-transaction scalar read-data capture rules.

The response-demux report mode remains
`bounded_multi_dynamic_read_rid_demux_contract` for single-beat and
`bounded_multi_dynamic_read_rid_rlast_demux_contract` for burst-last.
Scalar read-data does not claim multi-beat interleaving or burst-output
coverage, so response-demux residue may continue to include
`read_data_interleaving` and `bursts` until later multi-beat owners remove
them.

## Diagnostics And Fail-Closed Boundaries

The `.259` implementation should replace the current exact-one dynamic
transaction dynamic read-data diagnostic with bounded multiple-dynamic
diagnostics:

- reject generated dynamic read-data coverage when there are no dynamic read
  transactions;
- reject generated dynamic read-data coverage when generated completion signal
  count does not match dynamic transaction count;
- reject missing `read-data.read` bindings for any generated dynamic read
  demux transaction;
- reject extra `read-data.read` transaction bindings outside the generated
  dynamic read demux transaction set;
- preserve duplicate binding diagnostics; and
- keep `burst-length`, runtime beat-count/`RLAST` validation, and multi-beat
  output banks over multiple dynamic read demux fail-closed.

Existing single-active dynamic read-data samples must preserve their current
schedule/check/semantic reports.

## Validation Gates

The `.259` implementation should cover:

```bash
env -u PERL5LIB perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
env -u PERL5LIB perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
env -u PERL5LIB perl -Iperl -c t/1436-ial2-ppif-parser-cli.t
env -u PERL5LIB perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t
env -u PERL5LIB perl -Iperl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
env -u PERL5LIB perl -Iperl -c t/248-regression-corpus-accounting.t
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_data_multi.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_dynamic_read_data_multi.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_dynamic_read_data_multi.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_data_multi_last_beat.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_dynamic_read_data_multi_last_beat.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_dynamic_read_data_multi_last_beat.ppif
prove -Iperl t/248-regression-corpus-accounting.t
```

Broad focused suites such as `t/1438` and `t/1437` should use
`scripts/run_with_ram_guard.sh` on this host. If host memory stops a broad
run, direct sample probes plus focused support-accounting and syntax checks
must be recorded in the task-tree verification log.

Closeout must also run:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Explicit Residue

The `.259` implementation should move only scalar read-data over generated
multiple dynamic read demux out of residue. These remain later exact owners:

- burst-length/runtime validation over multiple dynamic read demux;
- multi-beat output banks over multiple dynamic read demux;
- mixed dynamic/static demux;
- same-cycle request widening beyond onehot0;
- same-cycle release-and-recapture;
- dynamic same-ID ordering;
- dynamic same-ID queues and scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

## Rollback

Rollback is the `.258` selector commit. Reverting it restores `.258` as the
active contract-selection frontier and removes the `.259` implementation
selection record.
