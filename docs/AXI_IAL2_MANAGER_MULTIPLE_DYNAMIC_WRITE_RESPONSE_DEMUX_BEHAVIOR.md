# AXI IAL2 Manager Multiple Dynamic Write Response-Demux Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.247`

Date: 2026-06-22

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.247` ships generated bounded multiple
dynamic write response-demux behavior for the AXI manager capacity/status IAL2
object.

The support-accounted public sample is
`ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif`.
It extends the earlier single-active dynamic write sample by allowing two or
more write transactions in the selected write family when every write
transaction uses `(id dynamic)`.

## Public Shape

The shipped public source shape remains explicit:

```lisp
(transactions
  (write w0
    (tag wr0)
    (request axi0_w0_request)
    (completion axi0_w0_complete)
    (id dynamic))
  (write w1
    (tag wr1)
    (request axi0_w1_request)
    (completion axi0_w1_complete)
    (id dynamic)))

(response-demux
  (write
    (response-event axi0_write_complete)
    (transaction-completion generated)))
```

The write ID family supplies the shared request ID source and response ID
signal:

```lisp
(id-families
  (write (width 4) (request-id-signal axi0_awid) (response-id-signal axi0_bid))
  (read  (width 4) (request-id-signal axi0_arid) (response-id-signal axi0_rid)))
```

The behavior is bounded by these rules:

- every write transaction in the selected family must use `(id dynamic)`;
- the raw write response event must be the explicit `response-demux.write`
  `response-event`;
- transaction completions are generated dynamic demux pulse outputs;
- same-cycle dynamic write requests are onehot0 for this first multiple-write
  boundary; and
- active captured dynamic write IDs must be pairwise unique.

Mixed dynamic/static write demux, dynamic read demux with multiple dynamic
transactions, same-cycle request widening beyond onehot0, same-cycle
release-and-recapture, dynamic same-ID queues, and scoreboards remain future
exact-owner work.

## Generated Behavior

For the public two-write sample, FSMGen emits generated state per dynamic write
transaction:

```text
axi0_w0_dynamic_id_q
axi0_w0_dynamic_busy_q
axi0_w1_dynamic_id_q
axi0_w1_dynamic_busy_q
```

Each transaction captures `axi0_awid` at its admitted write request when the
transaction is not already busy, no sibling admitted dynamic write request is
present in the same cycle, and no active sibling holds the same dynamic ID.

Each generated response-demux rule matches the raw accepted write response:

```text
axi0_write_complete && dynamic_busy_q && axi0_bid == dynamic_id_q
```

The matched rule pulses that transaction's generated completion output, and the
generated release rule clears the transaction busy bit from that completion
pulse. The single-active `.223` dynamic write sample keeps its existing
`bounded_dynamic_write_bid_demux_contract` report mode.

## Report Contract

Schedule JSON reports the multiple dynamic write contract with:

```yaml
response_demux:
  mode: bounded_multi_dynamic_write_bid_demux_contract
  generated_behavior: true
  write:
    mode: bounded_multi_dynamic_write_bid_demux_contract
    response_event: axi0_write_complete
    response_event_role: raw_accepted_write_response
    response_id_signal: axi0_bid
    response_id_direction: generated_input
    transaction_completion_source: generated_dynamic_demux
    transaction_completion_semantics: matched_dynamic_id
    dynamic_transactions: [w0, w1]
    dynamic_capture:
      request_id_source: axi0_awid
      capture_event_source: admitted_dynamic_write_request
      ownership: multi_active_unique_dynamic_write_ids
      simultaneous_request_policy: onehot0_dynamic_write_request
      same_id_conflict_policy: active_dynamic_ids_must_be_unique
      transactions:
        - transaction: w0
          selected_id_signal: axi0_w0_dynamic_id_q
          busy_signal: axi0_w0_dynamic_busy_q
          capture_rule: axi0_w0_dynamic_id_capture
          release_rule: axi0_w0_dynamic_id_release
        - transaction: w1
          selected_id_signal: axi0_w1_dynamic_id_q
          busy_signal: axi0_w1_dynamic_busy_q
          capture_rule: axi0_w1_dynamic_id_capture
          release_rule: axi0_w1_dynamic_id_release
```

The write report also lists generated completion signals, response-demux rules,
and the generated assertion names. The shipped multiple-state assertion roles
are:

- per-transaction request-not-busy;
- family request onehot0;
- per-transaction request no-active-same-ID;
- pairwise active dynamic ID uniqueness;
- raw response active match;
- pairwise response unique match; and
- per-transaction completion-active release.

## Public Sample And Checks

The public sample is support-accounted:

```text
ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif
```

Useful focused checks:

```bash
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --output /tmp/fsmgen_dynamic_write_response_demux_multi.sv ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_dynamic_write_response_demux_multi_verify.sv ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif
```

The behavior is covered by the bounded focused dynamic test
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t` and by
support-accounting test `t/248-regression-corpus-accounting.t`.

## Residue

The implementation moves only the all-dynamic write-family multiple-transaction
shape out of dynamic residue. These remain fail-closed or unshipped:

- multiple dynamic read response-demux;
- mixed dynamic/static write or read response-demux;
- same-cycle dynamic write request widening beyond onehot0;
- same-cycle release-and-recapture;
- dynamic same-ID ordering;
- dynamic same-ID queues and scoreboards;
- direct backend behavior outside the selected generated SystemVerilog path;
- backend-language variants; and
- VHDL.

## Validation

Closeout validation covered syntax checks for touched Perl modules/tests,
direct schedule JSON, strict check JSON, semantic JSON, generated
SystemVerilog, and `--verify-hdl` probes for the new public sample, guarded
focused dynamic validation through
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`, and guarded
support-accounting validation through
`t/248-regression-corpus-accounting.t`.

Full guarded `t/1436-ial2-ppif-parser-cli.t` and
`t/1437-axi-ial2-manager-capacity-status-generator.t` were attempted during
implementation and stopped by the host-memory guard at the configured 88%
cutoff without TAP diagnostics. Direct parser/CLI, schedule/check/semantic,
HDL, focused dynamic, and support-accounting probes covered the new public
sample after the expectation updates.

## Rollback

Rollback is the `.247` implementation commit. Reverting it removes the public
multiple dynamic write PPIF sample, support-accounting entry, generated
multiple dynamic write demux behavior, focused coverage, docs, and facts,
restoring `.247` as the active frontier.
