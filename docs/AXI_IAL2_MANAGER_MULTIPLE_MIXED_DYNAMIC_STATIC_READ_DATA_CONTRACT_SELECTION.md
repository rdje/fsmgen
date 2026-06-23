# AXI IAL2 Manager Multiple Mixed Dynamic/Static Read-Data Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.306`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.307`, direct generated behavior for
bounded scalar read-data over generated multiple mixed dynamic/static read
response-demux.

The selected contract composes the shipped `.299` multiple mixed
dynamic/static single-beat `RID` response-demux and `.303` multiple mixed
dynamic/static burst-last `RID && RLAST` response-demux with the existing
scalar `read-data.read` surface. The implementation should add coverage for
the generated multiple mixed completion sources and then reuse the existing
normalized scalar read-data capture rules. It must not add a second raw `RID`
or `RID && RLAST` matcher in the read-data path.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Public Source Shapes

The `.307` implementation should add two support-accounted public PPIF
samples:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_read_data.ppif
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data.ppif
```

The single-beat sample should compose the `.299` public response-demux shape
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
    (id (value 3)))
  (read r2
    (tag rd2)
    (request axi0_r2_request)
    (completion axi0_r2_complete)
    (id (value 5))))

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
      (status-output axi0_r1_rresp))
    (transaction r2
      (data-output axi0_r2_rdata)
      (status-output axi0_r2_rresp))))
```

The last-beat sample should compose the `.303` public burst-last
response-demux shape with scalar last-beat read-data:

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
      (status-output axi0_r1_last_rresp))
    (transaction r2
      (data-output axi0_r2_last_rdata)
      (status-output axi0_r2_last_rresp))))
```

Both samples should keep the existing read/write ID-family declarations from
the response-demux-only samples. `r0` remains the dynamic read transaction;
`r1` and `r2` remain concrete static read transactions with static IDs `3`
and `5`.

## Public Boundary

`.307` should implement only scalar read-data over already generated multiple
mixed dynamic/static read response-demux:

- exactly one read transaction uses `(id dynamic)`;
- exactly two read transactions use pairwise-distinct concrete static IDs;
- `response-demux.read.transaction-completion` is `generated`;
- `response-demux.read.transaction_completion_source` is
  `generated_multi_mixed_dynamic_static_read_demux` for scalar single-beat
  capture;
- `response-demux.read.transaction_completion_source` is
  `generated_multi_mixed_dynamic_static_read_demux_last_beat` for scalar
  last-beat capture;
- `read-data.read.completion-source` is `response-demux`;
- `capture-scope single-beat` is accepted only with `response-scope
  single-beat`, no `last-signal`, no `status-policy`, and no `burst-length`;
- `capture-scope last-beat` is accepted only with `response-scope
  burst-last`, a one-bit `last-signal`, `status-policy last-beat`, and no
  `burst-length`;
- `read-data.read.transactions` must bind the generated multiple mixed
  dynamic/static read demux transaction set exactly once; and
- `capture-scope multi-beat`, `burst-length`, runtime beat-count/`RLAST`
  validation, and multi-beat output banks remain fail-closed over the multiple
  mixed dynamic/static read demux shape.

The implementation should not widen same-cycle request admission,
release-and-recapture, dynamic same-ID queues, scoreboards, direct backend
behavior, backend-language variants, or VHDL.

## Transaction Coverage Contract

Read-data coverage should be derived from the response-demux report metadata
already emitted by `.299` and `.303`:

```text
dynamic_transactions: [r0]
static_transactions: [r1, r2]
generated_completion_signals: [axi0_r0_complete, axi0_r1_complete, axi0_r2_complete]
```

The covered transaction list is the ordered dynamic transaction list followed
by the ordered static transaction list. In this bounded slice that is exactly
`r0, r1, r2`.

The generated completion signal list must have the same length and order as
the covered transaction list. The coverage helper should build the
transaction-to-completion mapping from those lists:

```text
r0 -> axi0_r0_complete
r1 -> axi0_r1_complete
r2 -> axi0_r2_complete
```

Missing, duplicate, or extra `read-data.read.transaction` bindings remain
diagnosed by the existing normalization layer once the multiple mixed coverage
branch admits the correct covered set.

## Completion And Capture Semantics

Read-data capture consumes generated completion pulses. It does not re-match
raw `RID`, does not inspect static ID reservations directly, and does not
create a second ownership decision.

For the single-beat sample, each completion pulse is a matched raw
single-beat `RID` response for either the captured dynamic ID or one selected
concrete static ID. The read-data capture rules should be:

```text
axi0_r0_complete -> capture axi0_rdata/axi0_rresp into r0 outputs
axi0_r1_complete -> capture axi0_rdata/axi0_rresp into r1 outputs
axi0_r2_complete -> capture axi0_rdata/axi0_rresp into r2 outputs
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
    completion_validity: generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse
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
      - transaction: r2
        completion_signal: axi0_r2_complete
        data_output: axi0_r2_rdata
        status_output: axi0_r2_rresp
```

The last-beat report should keep the existing scalar last-beat mode:

```yaml
read_data:
  mode: bounded_last_beat_read_data_contract
  generated_behavior: true
  read:
    capture_scope: last_beat
    completion_source: response_demux
    completion_validity: generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse
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
      - transaction: r2
        completion_signal: axi0_r2_complete
        data_output: axi0_r2_last_rdata
        status_output: axi0_r2_last_rresp
```

The response-demux report remains the owner for ID capture, static-ID
reservation, raw beat ownership assertions, and final completion generation:

- `bounded_multi_mixed_dynamic_static_read_rid_demux_contract` for the
  single-beat sample;
- `bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract` for the
  last-beat sample.

Scalar read-data should not claim burst-length/runtime validation or
multi-beat output-bank coverage. Response-demux residue may continue to list
`read_data_interleaving` and `bursts` until later mixed burst/runtime and
multi-beat owners remove those items.

## Sample And Support Accounting

The support-accounting entries should be:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_read_data
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data
```

The coverage labels should follow the local PPIF naming pattern:

```text
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_read_data_pipeline_cli
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_pipeline_cli
```

## Diagnostics And Fail-Closed Boundaries

The `.307` implementation should add bounded multiple mixed diagnostics while
preserving the existing one-static mixed behavior:

- reject generated multiple mixed read-data coverage when the demux does not
  expose exactly one dynamic read transaction and exactly two concrete static
  read transactions;
- reject generated multiple mixed read-data coverage when generated
  completion signal count does not match the dynamic-plus-static transaction
  count;
- reject missing `read-data.read` bindings for any generated multiple mixed
  read demux transaction;
- reject extra `read-data.read` transaction bindings outside the generated
  multiple mixed read demux transaction set;
- preserve duplicate binding diagnostics; and
- keep `burst-length`, runtime beat-count/`RLAST` validation, and multi-beat
  output banks over multiple mixed read demux fail-closed in this slice.

Existing `.284` one-static mixed read-data samples, `.259` multiple dynamic
read-data samples, `.299` response-demux-only sample, and `.303`
response-demux-only sample must preserve their current schedule/check/semantic
reports.

## Validation Gates

The `.307` implementation should cover:

```bash
env -u PERL5LIB perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
env -u PERL5LIB perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
env -u PERL5LIB perl -Iperl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
env -u PERL5LIB perl -Iperl -c t/248-regression-corpus-accounting.t
scripts/run_with_ram_guard.sh --host-max-pct 88 --process-max-rss-mb 4096 -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_read_data.ppif
scripts/run_with_ram_guard.sh --host-max-pct 88 --process-max-rss-mb 4096 -- env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_read_data.ppif
scripts/run_with_ram_guard.sh --host-max-pct 88 --process-max-rss-mb 4096 -- env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_read_data.ppif
scripts/run_with_ram_guard.sh --host-max-pct 88 --process-max-rss-mb 4096 -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data.ppif
scripts/run_with_ram_guard.sh --host-max-pct 88 --process-max-rss-mb 4096 -- env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data.ppif
scripts/run_with_ram_guard.sh --host-max-pct 88 --process-max-rss-mb 4096 -- env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data.ppif
scripts/run_with_ram_guard.sh --host-max-pct 88 --process-max-rss-mb 4096 -- prove -Iperl t/248-regression-corpus-accounting.t
```

If guarded direct probes trip host-memory cutoffs before assertion output, the
implementation should record that explicitly and use guarded lightweight
adapter/report probes to validate the normalized report and generated IAL1
rule surface. A documented 90% host cutoff retry is allowed only after the
standard 88% guard trips, matching the existing memory-safety policy.

Closeout must also run:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback is the `.306` selector commit. Reverting it restores `.306` as the
active contract-selection frontier and removes the `.307` implementation
owner.

## Explicit Residue

These remain future exact owners:

- generated scalar read-data implementation over multiple mixed read demux
  until `.307` ships it;
- raw `ARLEN` burst-length capture over multiple mixed read burst-last demux;
- runtime beat-count/`RLAST` validation over multiple mixed read burst-last
  demux;
- multi-beat output banks over multiple mixed read demux;
- two-dynamic plus one-static mixed dynamic/static cardinality;
- broader mixed write and read cardinalities;
- same-cycle request widening beyond onehot0;
- same-cycle release-and-recapture;
- dynamic same-ID queues and scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.
