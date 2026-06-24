# AXI IAL2 Manager Multiple Dynamic Read RLAST Response-Demux Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.255`

Date: 2026-06-23

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.255` shipped generated bounded multiple
dynamic read burst-last/`RLAST` response-demux for the public sample, and
`IAL2-FEATURE-COMPLETENESS-FRONTIER.385` adds same-cycle
release-and-recapture for the same generated state:

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
generated release rules when there is no same-cycle request for that same
transaction.

If transaction `rN` has an admitted same-cycle read request while its matched
final `RID && RLAST` completion fires, FSMGen emits
`axi0_rN_dynamic_id_release_recapture`. The rule captures the new `ARID`,
keeps the busy bit asserted, and uses the pre-update selected ID for the
completion match. The guard also requires no sibling admitted dynamic read
request and no active sibling selected ID equal to the new `ARID`.

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
axi0_r0_dynamic_request_idle_or_releasing
axi0_r1_dynamic_request_idle_or_releasing
axi0_read_dynamic_request_onehot0
axi0_r0_dynamic_request_no_active_same_id
axi0_r1_dynamic_request_no_active_same_id
axi0_r0_r1_read_dynamic_active_id_unique
axi0_read_dynamic_response_active_match
axi0_r0_r1_read_dynamic_response_unique_match
axi0_r0_dynamic_completion_active
axi0_r1_dynamic_completion_active
```

Each entry under `dynamic_capture.transactions[]` reports the recapture
ownership:

```yaml
- transaction: r0
  release_recapture_rule: axi0_r0_dynamic_id_release_recapture
  same_cycle_release_recapture_policy: multi_active_unique_dynamic_read
  release_recapture_source: generated_dynamic_demux_last_beat_completion
  release_recapture_transaction: r0
- transaction: r1
  release_recapture_rule: axi0_r1_dynamic_id_release_recapture
  same_cycle_release_recapture_policy: multi_active_unique_dynamic_read
  release_recapture_source: generated_dynamic_demux_last_beat_completion
  release_recapture_transaction: r1
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

Layered consumers over the same generated multiple dynamic read burst-last
response-demux remain preserved:

- scalar last-beat read-data captures `RDATA/RRESP` on each generated
  last-beat completion pulse;
- report-only raw-`ARLEN` captures request metadata at admission time;
- runtime beat-count/`RLAST` validation still counts raw matched beats and
  checks the final boundary; and
- multi-beat output banks still capture every raw matched beat while final
  `RID && RLAST` completion owns transaction release.

Mixed dynamic/static recapture, static busy recapture, request arbitration
beyond onehot0, queues, scoreboards, direct backend behavior, backend-language
variants, VHDL, and full AXI manager behavior remain future exact owners.

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
