# AXI IAL2 Manager Multiple Dynamic Read RLAST Response-Demux Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.254`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.255`, direct generated behavior for
bounded multiple dynamic read burst-last/`RLAST` response-demux.

The selected public contract composes the shipped `.251` multiple dynamic
read single-beat capture/ID-uniqueness contract with the shipped `.231`
single-active dynamic read burst-last final-completion contract. It changes no
parser, generator, PPIF sample, support-accounting catalog, validation
behavior, generated artifact, test, schedule/check or semantic JSON, or HDL
behavior.

## Public Source Shape

The `.255` implementation should add one support-accounted public PPIF sample:

```text
ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif
```

The source shape reuses existing explicit `response-demux.read` syntax:

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
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))
```

The read ID family remains the shared dynamic request/response ID source:

```lisp
(id-families
  (read (width 4) (request-id axi0_arid) (response-id axi0_rid)))
```

## Public Boundary

The first implementation is intentionally response-demux-only:

- the read ID family must be present and positive-width;
- the read ID family must declare exactly the request ID source and response
  ID signal that dynamic read transactions use, for example `ARID` and `RID`;
- two or more read transactions are present;
- every read transaction in the selected read family uses `(id dynamic)`;
- `response-demux.read.response-scope` is `burst-last`;
- `response-demux.read.last-signal` is present, one bit wide, and generated as
  an input;
- `response-demux.read.transaction-completion` is `generated`;
- each generated transaction completion signal is distinct from the raw read
  response event; and
- `read-data`, `burst-length`, runtime beat-count/`RLAST` validation, and
  multi-beat output banks are absent in the first public sample.

Mixed dynamic/static read response-demux, read auto-ID lifecycle,
`same-id-ordering.read`, dynamic same-ID queues, scoreboards, same-cycle
dynamic request widening beyond onehot0, same-cycle release-and-recapture,
read-data over multiple dynamic read demux, burst-length/runtime validation
over multiple dynamic read demux, multi-beat output banks over multiple
dynamic read demux, direct backend behavior, backend-language variants, and
VHDL remain future exact owners.

## Capture And Lifetime

Each dynamic read transaction owns generated selected-ID and busy state:

```text
<transaction>_dynamic_id_q
<transaction>_dynamic_busy_q
```

The capture point is the admitted read request. A capture is valid only when:

- that transaction's admitted read request is present;
- that transaction is not already busy;
- no sibling dynamic read request is admitted in the same cycle; and
- no busy sibling dynamic read has the same captured ID as the current
  request ID source.

The busy bit remains asserted across matched non-last read beats. It releases
only from that transaction's generated final-beat completion pulse. A request
for the same transaction in the same cycle as its own generated completion
remains invalid in this contract because capture observes the pre-release busy
state. Release-and-recapture is a later owner.

## Response Matching

The public contract deliberately separates raw beat matching from final-beat
completion.

A raw read beat matches an active dynamic transaction when:

```text
response_event && dynamic_busy_q && (RID == dynamic_id_q)
```

That raw match is used by generated active-match and unique-match assertions.
It intentionally does not include `RLAST`, so matched non-last beats are legal
and mismatched non-last beats are diagnosed.

A generated transaction completion pulses only on the final matching beat:

```text
response_event && dynamic_busy_q && (RID == dynamic_id_q) && RLAST
```

The completion pulse releases that transaction's busy state. Non-last matched
beats do not complete or release the transaction.

The raw response active-match assertion must say that every raw read response
beat matches at least one active captured dynamic read ID. The raw response
unique-match assertion must say that every raw read response beat matches at
most one active captured dynamic read ID. Active-ID uniqueness and request
no-active-same-ID assertions keep the selected no-same-ID contract explicit;
they are not a same-ID ordering or queue contract.

This contract does not validate beat counts or enforce AXI burst length. It
only uses `RLAST` to choose the generated completion/release beat.

## Report Vocabulary

The `.255` implementation should report a new mode:

```yaml
response_demux:
  mode: bounded_multi_dynamic_read_rid_rlast_demux_contract
  generated_behavior: true
  read:
    mode: bounded_multi_dynamic_read_rid_rlast_demux_contract
    generated_behavior: true
    response_event: axi0_read_complete
    response_event_role: raw_accepted_read_response_beat
    response_scope: burst_last
    response_id_signal: axi0_rid
    response_id_direction: generated_input
    last_signal: axi0_rlast
    last_signal_direction: generated_input
    last_signal_width: 1
    transaction_completion_source: generated_dynamic_demux_last_beat
    transaction_completion_semantics: matched_dynamic_id_and_last_signal
    beat_valid_output: none
    burst_length_source: rlast_only
    burst_length_validation: not_generated
    dynamic_transactions: [r0, r1]
    dynamic_capture:
      request_id_source: axi0_arid
      capture_event_source: admitted_dynamic_read_request
      ownership: multi_active_unique_dynamic_read_ids
      simultaneous_request_policy: onehot0_dynamic_read_request
      same_id_conflict_policy: active_dynamic_ids_must_be_unique
      transactions:
        - transaction: r0
          selected_id_signal: axi0_r0_dynamic_id_q
          busy_signal: axi0_r0_dynamic_busy_q
          capture_rule: axi0_r0_dynamic_id_capture
          release_rule: axi0_r0_dynamic_id_release
        - transaction: r1
          selected_id_signal: axi0_r1_dynamic_id_q
          busy_signal: axi0_r1_dynamic_busy_q
          capture_rule: axi0_r1_dynamic_id_capture
          release_rule: axi0_r1_dynamic_id_release
    generated_rules:
      - axi0_r0_response_demux
      - axi0_r1_response_demux
    generated_completion_signals:
      - axi0_r0_complete
      - axi0_r1_complete
```

Generated assertion names should follow the existing local naming convention
and make these roles visible:

```text
axi0_r0_dynamic_request_not_busy
axi0_r1_dynamic_request_not_busy
axi0_read_dynamic_request_onehot0
axi0_r0_dynamic_request_no_active_same_id
axi0_r1_dynamic_request_no_active_same_id
axi0_r0_r1_read_dynamic_active_id_unique
axi0_read_dynamic_response_active_match
axi0_r0_r1_read_dynamic_response_unique_match
axi0_r0_dynamic_completion_active
axi0_r1_dynamic_completion_active
```

The generated response-demux residue should stay:

```yaml
residue:
  - same_id_ordering
  - read_data_interleaving
  - bursts
```

The broader `dynamic_transaction_id_behavior` unsupported-residue detail should
move only multiple dynamic read burst-last/`RLAST` response-demux out of the
future-work list. Read-data and runtime/multi-beat widening over multiple
dynamic read demux must remain explicit residue.

## Diagnostics And Fail-Closed Boundaries

The `.255` implementation should remove only the current fail-closed
diagnostic that rejects multiple dynamic read transactions when
`response_scope` is `burst-last`.

These diagnostics and boundaries remain:

- all selected read transactions must be dynamic;
- dynamic read demux cannot combine with read `auto-id-lifecycle`;
- dynamic read demux cannot combine with `same-id-ordering.read`;
- `response-demux.read.response-scope burst-last` requires `last-signal`;
- `last-signal-width` must be `1`;
- `last-signal` is rejected for `response-scope single-beat`;
- read-data dynamic coverage continues to require exactly one generated
  dynamic read transaction and exactly one generated dynamic completion signal;
- burst-length/runtime validation over multiple dynamic read demux remains
  unowned; and
- multi-beat output banks over multiple dynamic read demux remain unowned.

## Validation Expectations

The `.255` implementation should include focused validation for:

- PPIF parser/adapter and CLI schedule JSON for the new sample;
- strict check JSON and semantic JSON support-accounting coverage;
- generated IAL1/IAL0/SystemVerilog shape;
- generated capture, response-demux, and release rules;
- generated raw-beat active-match/unique-match assertions;
- generated final `RID && RLAST` completion and release guards;
- generated report mode and dynamic-capture vocabulary;
- preservation of `.227`, `.231`, `.247`, `.251`, and dynamic
  read-data/runtime/multi-beat samples; and
- fail-closed read-data over multiple dynamic read demux.

Useful closeout gates for `.255`:

```bash
env -u PERL5LIB perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
env -u PERL5LIB perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
env -u PERL5LIB perl -Iperl -c t/1436-ial2-ppif-parser-cli.t
env -u PERL5LIB perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t
env -u PERL5LIB perl -Iperl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --output /tmp/fsmgen_dynamic_read_response_demux_multi_burst_last.sv ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_dynamic_read_response_demux_multi_burst_last_verify.sv ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif
scripts/run_with_ram_guard.sh -- prove -Iperl t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
scripts/run_with_ram_guard.sh -- prove -Iperl t/248-regression-corpus-accounting.t
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

Broader `t/1436` or `t/1437` guarded runs are useful when host memory permits,
but direct parser/CLI, generator, support-accounting, schedule/check/semantic,
HDL, docs, Knowledge Map, memory, and doctrine probes are the required
coverage if the broad suites hit the existing host-memory guard.

## Rollback

Rollback is the `.254` selector commit. Reverting it restores `.254` as the
active contract-selection owner and removes the `.255` direct implementation
selection.
