# AXI IAL2 Manager Mixed Dynamic/Static Read-Data Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.283`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.284`, direct generated behavior for
bounded scalar read-data over generated mixed dynamic/static read
response-demux.

The selected contract composes the shipped `.276` mixed dynamic/static
single-beat `RID` response-demux and `.280` mixed dynamic/static burst-last
`RID && RLAST` response-demux with the existing scalar `read-data.read`
surface. The implementation should add coverage for the generated mixed
completion sources and then reuse the existing normalized read-data capture
rules. It must not add a second raw `RID` or `RID && RLAST` matcher in the
read-data path.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Public Source Shapes

The `.284` implementation should add two support-accounted public PPIF
samples:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data.ppif
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data.ppif
```

The single-beat sample should compose the `.276` public response-demux shape
with scalar single-beat read-data:

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
    (id (value 3))))

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

The last-beat sample should compose the `.280` public burst-last response-demux
shape with scalar last-beat read-data:

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

Both samples should keep the existing read/write ID-family declarations from
the response-demux-only samples. `r0` remains the dynamic read transaction and
`r1` remains the concrete static read transaction with static ID `3`.

## Public Boundary

`.284` should implement only scalar read-data over the already generated
mixed dynamic/static read response-demux families:

- exactly one read transaction uses `(id dynamic)`;
- exactly one read transaction uses a concrete static ID;
- `response-demux.read.transaction-completion` is `generated`;
- `response-demux.read.transaction_completion_source` is
  `generated_mixed_dynamic_static_read_demux` for scalar single-beat capture;
- `response-demux.read.transaction_completion_source` is
  `generated_mixed_dynamic_static_read_demux_last_beat` for scalar last-beat
  capture;
- `read-data.read.completion-source` is `response-demux`;
- `capture-scope single-beat` is accepted only with `response-scope
  single-beat`, no `last-signal`, no `status-policy`, and no `burst-length`;
- `capture-scope last-beat` is accepted only with `response-scope
  burst-last`, a one-bit `last-signal`, `status-policy last-beat`, and no
  `burst-length`;
- `read-data.read.transactions` must bind the generated mixed dynamic/static
  read demux transaction set exactly once; and
- `capture-scope multi-beat`, `burst-length`, runtime beat-count/`RLAST`
  validation, and multi-beat output banks remain fail-closed over mixed
  dynamic/static read demux.

The implementation should not widen same-cycle request admission,
release-and-recapture, dynamic same-ID queues, scoreboards, direct backend
behavior, backend-language variants, or VHDL.

## Transaction Coverage Contract

Read-data coverage should be derived from the response-demux report metadata
already emitted by `.276` and `.280`:

```text
dynamic_transactions: [r0]
static_transactions: [r1]
generated_completion_signals: [axi0_r0_complete, axi0_r1_complete]
```

The covered transaction list is the ordered dynamic transaction list followed
by the ordered static transaction list. In this bounded slice that is exactly
`r0, r1`.

The generated completion signal list must have the same length and order as
the covered transaction list. The coverage helper should build the
transaction-to-completion mapping from those two lists:

```text
r0 -> axi0_r0_complete
r1 -> axi0_r1_complete
```

Missing, duplicate, or extra `read-data.read.transaction` bindings remain
diagnosed by the existing normalization layer once the mixed coverage branch
admits the correct covered set.

## Completion And Capture Semantics

Read-data capture consumes generated completion pulses. It does not re-match
raw `RID`, does not inspect the static ID reservation directly, and does not
create a second ownership decision.

For the single-beat sample, each completion pulse is a matched raw single-beat
`RID` response for either the captured dynamic ID or the concrete static ID.
The read-data capture rules should be:

```text
axi0_r0_complete -> capture axi0_rdata/axi0_rresp into r0 outputs
axi0_r1_complete -> capture axi0_rdata/axi0_rresp into r1 outputs
```

For the last-beat sample, each completion pulse is a matched final
`RID && RLAST` response. Non-last raw matched beats remain owned by
response-demux assertions and must not update scalar last-beat read-data
outputs.

The generated IAL1 review artifact should declare shared generated inputs
`axi0_rdata` and `axi0_rresp`, per-transaction scalar data/status outputs,
and one scalar capture rule per covered transaction.

## Report Vocabulary

The single-beat report should keep the existing scalar read-data mode:

```yaml
read_data:
  mode: bounded_single_beat_read_data_contract
  generated_behavior: true
  read:
    capture_scope: single_beat
    completion_source: response_demux
    completion_validity: generated_mixed_dynamic_static_read_response_demux_completion_pulse
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
    completion_validity: generated_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse
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

The response-demux report remains the owner for ID capture, static-ID
reservation, raw beat ownership assertions, and final completion generation:

- `bounded_mixed_dynamic_static_read_rid_demux_contract` for the single-beat
  sample;
- `bounded_mixed_dynamic_static_read_rid_rlast_demux_contract` for the
  last-beat sample.

Scalar read-data should not claim burst-length/runtime validation or
multi-beat output-bank coverage. Response-demux residue may continue to list
`read_data_interleaving` and `bursts` until later mixed burst/runtime and
multi-beat owners remove those items.

## Sample And Support Accounting

The support-accounting entries should be:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data
```

The coverage labels should follow the local PPIF naming pattern:

```text
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data_pipeline_cli
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_pipeline_cli
```

The samples should be support-accounted for check JSON and semantic JSON.

## Diagnostics And Fail-Closed Boundaries

`.284` should keep fail-closed behavior outside the selected contract and
sharpen diagnostics for:

- mixed dynamic/static read-data coverage with any transaction count other
  than one dynamic read transaction plus one concrete static read transaction;
- generated mixed dynamic/static read-data coverage when generated completion
  signal count does not match the covered transaction count;
- `capture-scope single-beat` paired with burst-last mixed read demux;
- `capture-scope last-beat` paired with single-beat mixed read demux;
- missing `status-policy last-beat` on last-beat mixed read-data;
- `status-policy` on single-beat mixed read-data;
- missing `read-data.read` bindings for any generated mixed read demux
  transaction;
- extra `read-data.read` bindings outside the generated mixed read demux
  transaction set;
- duplicate `read-data.read` transaction bindings;
- `burst-length` metadata over mixed dynamic/static scalar read-data;
- `capture-scope multi-beat` over mixed dynamic/static read demux;
- read `auto-id-lifecycle` combined with the selected mixed dynamic/static
  read-data contract;
- `same-id-ordering.read` combined with the selected mixed dynamic/static
  read-data contract; and
- generated completion names colliding with raw response events or other
  generated declarations.

## Validation Gates

The `.284` implementation should run:

```bash
env -u PERL5LIB perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
env -u PERL5LIB perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
env -u PERL5LIB perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t
env -u PERL5LIB perl -Iperl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
env -u PERL5LIB perl -Iperl -c t/248-regression-corpus-accounting.t
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_mixed_dynamic_static_read_data.sv ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_mixed_dynamic_static_read_data_burst_last.sv ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data.ppif
prove -Iperl t/248-regression-corpus-accounting.t
```

Broad focused suites such as `t/1438` and `t/1437` should use
`scripts/run_with_ram_guard.sh` on this host. If host memory stops a broad
run, direct public-sample schedule/check/semantic/HDL probes plus focused
support-accounting and syntax checks must be recorded in the task-tree
verification log.

Closeout must also run:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Explicit Residue

The `.284` implementation should move only scalar read-data over generated
mixed dynamic/static read demux out of residue. These remain later exact
owners:

- burst-length/runtime validation over mixed dynamic/static read demux;
- multi-beat output banks over mixed dynamic/static read demux;
- multiple mixed dynamic/static read or write transactions;
- same-cycle request widening beyond onehot0;
- same-cycle release-and-recapture;
- dynamic same-ID ordering;
- dynamic same-ID queues and scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

## Rollback

Rollback is the `.283` selector commit. Reverting it restores `.283` as the
active contract-selection frontier and removes the `.284` implementation
selection record. Reverting the future `.284` implementation should remove
only the mixed dynamic/static scalar read-data behavior, its two public
samples, support-accounting entries, focused tests, docs, and fact card.
