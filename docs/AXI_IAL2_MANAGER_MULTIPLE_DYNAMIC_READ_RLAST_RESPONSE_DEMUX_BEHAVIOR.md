# AXI IAL2 Manager Multiple Dynamic Read RLAST Response-Demux Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.255`

Date: 2026-06-23

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.255` ships generated bounded multiple
dynamic read burst-last/`RLAST` response-demux for the public sample:

```text
ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif
```

The generated contract mode is:

```text
bounded_multi_dynamic_read_rid_rlast_demux_contract
```

The supported shape has two or more read transactions, every read transaction
uses `(id dynamic)`, the read ID family provides a positive-width request ID
source and response ID signal, and `response-demux.read` selects
`response-scope burst-last`, a one-bit `last-signal`, and
`transaction-completion generated`.

## Generated State

Each dynamic read transaction owns generated selected-ID and busy state:

```text
axi0_r0_dynamic_id_q
axi0_r0_dynamic_busy_q
axi0_r1_dynamic_id_q
axi0_r1_dynamic_busy_q
```

The capture rule records `ARID` on an admitted transaction request only when
the transaction is not busy, no sibling dynamic read request is admitted in the
same cycle, and no active sibling already owns the requested ID.

The generated capture report uses:

```yaml
dynamic_capture:
  request_id_source: axi0_arid
  capture_event_source: admitted_dynamic_read_request
  ownership: multi_active_unique_dynamic_read_ids
  simultaneous_request_policy: onehot0_dynamic_read_request
  same_id_conflict_policy: active_dynamic_ids_must_be_unique
```

## Response Matching

The generated response-demux rules complete only on a matched final beat:

```text
axi0_read_complete && axi0_r0_dynamic_busy_q &&
  (axi0_rid == axi0_r0_dynamic_id_q) && axi0_rlast

axi0_read_complete && axi0_r1_dynamic_busy_q &&
  (axi0_rid == axi0_r1_dynamic_id_q) && axi0_rlast
```

The completion pulses release the owning transaction busy bit through the
generated release rules.

Raw response active-match and unique-match assertions intentionally do not
include `RLAST`. They match each accepted read response beat by `RID` against
active captured dynamic IDs so non-last beats are legal and still checked for a
valid, unique active transaction owner.

## Report Surface

Schedule/check/semantic report JSON now includes:

```yaml
response_demux:
  mode: bounded_multi_dynamic_read_rid_rlast_demux_contract
  generated_behavior: true
  read:
    mode: bounded_multi_dynamic_read_rid_rlast_demux_contract
    response_event_role: raw_accepted_read_response_beat
    response_scope: burst_last
    last_signal: axi0_rlast
    transaction_completion_source: generated_dynamic_demux_last_beat
    transaction_completion_semantics: matched_dynamic_id_and_last_signal
    beat_valid_output: none
    burst_length_source: rlast_only
    burst_length_validation: not_generated
```

The generated assertion names for the public two-transaction sample are:

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

The support-accounting entry is:

```text
intent.ppif_axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last
```

with coverage:

```text
ial2_ppif_manager_capacity_status_dynamic_read_response_demux_multi_burst_last_pipeline_cli
```

## Preserved Boundaries

The slice does not add read-data routing over multiple dynamic read demux.
`read_data.read` still requires exactly one generated dynamic read transaction.

The following remain future exact owners:

- read-data over multiple dynamic read demux;
- burst-length/runtime validation over multiple dynamic read demux;
- multi-beat output banks over multiple dynamic read demux;
- mixed dynamic/static response-demux;
- same-cycle request widening beyond onehot0;
- same-cycle release-and-recapture;
- dynamic same-ID queues and scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

## Validation

Focused validation for `.255` covered:

```bash
env -u PERL5LIB perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
env -u PERL5LIB perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
env -u PERL5LIB perl -Iperl -c t/1436-ial2-ppif-parser-cli.t
env -u PERL5LIB perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t
env -u PERL5LIB perl -Iperl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
env -u PERL5LIB perl -Iperl -c t/248-regression-corpus-accounting.t
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --output /tmp/fsmgen_dynamic_read_response_demux_multi_burst_last.sv ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_dynamic_read_response_demux_multi_burst_last_verify.sv ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif
prove -Iperl t/248-regression-corpus-accounting.t
```

The guarded broad `t/1438` and `t/1437` runs were attempted under
`scripts/run_with_ram_guard.sh -- prove ...`, but the host-memory guard stopped
them at the 88% cutoff before test assertions ran. Direct schedule/check/
semantic/HDL probes, the adapter IAL1 probe, the read-data fail-closed probe,
syntax checks, and support-accounting regression covered the new public sample
and preserved boundary.

## Rollback

Rollback is the `.255` commit. Reverting it restores the previous fail-closed
multiple dynamic read burst-last/`RLAST` response-demux boundary while leaving
the `.254` contract-selection record intact.
