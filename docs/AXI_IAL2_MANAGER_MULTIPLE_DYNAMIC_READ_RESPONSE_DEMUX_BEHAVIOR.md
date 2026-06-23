# AXI IAL2 Manager Multiple Dynamic Read Response-Demux Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.251`

Date: 2026-06-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.251` ships generated bounded multiple
dynamic read response-demux behavior for the AXI manager capacity/status IAL2
object.

The support-accounted public sample is
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif`.
It extends the earlier single-active dynamic read sample by allowing two or
more read transactions in the selected read family when every read transaction
uses `(id dynamic)` and the read response scope is `single-beat`.

## Public Shape

The shipped public source shape remains explicit:

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
```

The read ID family supplies the shared request ID source and response ID
signal:

```lisp
(id-families
  (write (width 4) (request-id-signal axi0_awid) (response-id-signal axi0_bid))
  (read  (width 4) (request-id-signal axi0_arid) (response-id-signal axi0_rid)))
```

The behavior is bounded by these rules:

- every read transaction in the selected family must use `(id dynamic)`;
- the read response scope must be `single-beat`;
- the raw read response event must be the explicit `response-demux.read`
  `response-event`;
- transaction completions are generated dynamic demux pulse outputs;
- same-cycle dynamic read requests are onehot0 for this first multiple-read
  boundary; and
- active captured dynamic read IDs must be pairwise unique.

Multiple dynamic read burst-last/`RLAST` demux, read-data over multiple dynamic
read demux, burst-length/runtime validation and multi-beat output banks over
multiple dynamic read demux, mixed dynamic/static read demux, same-cycle
request widening beyond onehot0, same-cycle release-and-recapture, dynamic
same-ID queues, and scoreboards remain future exact-owner work.

## Generated Behavior

For the public two-read sample, FSMGen emits generated state per dynamic read
transaction:

```text
axi0_r0_dynamic_id_q
axi0_r0_dynamic_busy_q
axi0_r1_dynamic_id_q
axi0_r1_dynamic_busy_q
```

Each transaction captures `axi0_arid` at its admitted read request when the
transaction is not already busy, no sibling admitted dynamic read request is
present in the same cycle, and no active sibling holds the same dynamic ID.

Each generated response-demux rule matches the raw accepted read response:

```text
axi0_read_complete && dynamic_busy_q && axi0_rid == dynamic_id_q
```

The matched rule pulses that transaction's generated completion output, and the
generated release rule clears the transaction busy bit from that completion
pulse. The single-active `.227` dynamic read sample keeps its existing
`bounded_dynamic_read_rid_demux_contract` report mode, and the `.231`
single-active burst-last/`RLAST` sample remains supported without widening to
multiple dynamic read transactions.

## Report Contract

Schedule JSON reports the multiple dynamic read contract with:

```yaml
response_demux:
  mode: bounded_multi_dynamic_read_rid_demux_contract
  generated_behavior: true
  read:
    mode: bounded_multi_dynamic_read_rid_demux_contract
    response_event: axi0_read_complete
    response_scope: single_beat
    response_event_role: raw_accepted_read_response
    response_id_signal: axi0_rid
    response_id_direction: generated_input
    transaction_completion_source: generated_dynamic_demux
    transaction_completion_semantics: matched_dynamic_id_single_beat
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
```

The read report also lists generated completion signals, response-demux rules,
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
ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif
```

Useful focused checks:

```bash
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --output /tmp/fsmgen_dynamic_read_response_demux_multi.sv ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_dynamic_read_response_demux_multi_verify.sv ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif
```

The behavior is covered by the bounded focused dynamic test
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`, generator-focused
coverage in `t/1437-axi-ial2-manager-capacity-status-generator.t`, parser/CLI
coverage in `t/1436-ial2-ppif-parser-cli.t`, and support-accounting test
`t/248-regression-corpus-accounting.t`.

## Residue

The implementation moves only the all-dynamic read-family, single-beat,
response-demux-only multiple-transaction shape out of dynamic residue. These
remain fail-closed or unshipped:

- multiple dynamic read burst-last/`RLAST` demux;
- read-data over multiple dynamic read demux;
- burst-length/runtime validation and multi-beat output banks over multiple
  dynamic read demux;
- mixed dynamic/static write or read response-demux;
- same-cycle dynamic read request widening beyond onehot0;
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
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`, guarded generator
validation through `t/1437-axi-ial2-manager-capacity-status-generator.t`, and
guarded support-accounting validation through
`t/248-regression-corpus-accounting.t`.

Full guarded `t/1436-ial2-ppif-parser-cli.t` was attempted during
implementation and stopped by the host-memory guard while checking an
unrelated depth-3 queue-head `--verify-hdl` case. Direct parser/CLI,
schedule/check/semantic, HDL, focused dynamic, generator, and
support-accounting probes covered the new public sample after the expectation
updates.

## Rollback

Rollback is the `.251` implementation commit. Reverting it removes the public
multiple dynamic read PPIF sample, support-accounting entry, generated multiple
dynamic read single-beat demux behavior, focused coverage, docs, and facts,
restoring `.251` as the active frontier.
