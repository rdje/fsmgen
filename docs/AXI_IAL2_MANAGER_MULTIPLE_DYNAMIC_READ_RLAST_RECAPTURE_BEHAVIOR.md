# AXI IAL2 Manager Multiple Dynamic Read RLAST Recapture Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.385`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.385` ships same-cycle
release-and-recapture for the existing support-accounted multiple
all-dynamic read burst-last response-demux sample:

```text
ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif
```

The public source syntax, support-accounting identity, generated response-demux
rule names, generated last-beat completion names, and
`bounded_multi_dynamic_read_rid_rlast_demux_contract` report mode are
unchanged.

## Generated Rules

For each dynamic read transaction, FSMGen emits a release-recapture rule:

```text
axi0_r0_dynamic_id_release_recapture
axi0_r1_dynamic_id_release_recapture
```

For transaction `rN`, the release-recapture guard requires:

- the same transaction has an admitted read request in the cycle;
- the same transaction has its generated matched final `RID && RLAST`
  completion in the cycle;
- the same transaction is busy before the update;
- no sibling dynamic read has an admitted request in the cycle; and
- no active sibling dynamic read already holds the new `ARID`.

The rule writes the new `ARID` into the transaction selected-ID state and keeps
the busy bit asserted. The response-demux match still uses the pre-update
selected ID and busy bit, so the completing response and newly admitted request
remain ordered inside the generated update cycle.

The release-only rule remains per transaction and clears busy only when the
transaction completes without that same transaction's same-cycle request:

```text
axi0_rN_complete && axi0_rN_dynamic_busy_q && !axi0_rN_request
```

Matched non-final read beats remain raw matched beats only. They do not pulse
the generated transaction completion, release a dynamic slot, or trigger
release-and-recapture.

## Report Contract

Each entry in `response_demux.read.dynamic_capture.transactions[]` now reports:

```yaml
release_recapture_rule: axi0_rN_dynamic_id_release_recapture
same_cycle_release_recapture_policy: multi_active_unique_dynamic_read
release_recapture_source: generated_dynamic_demux_last_beat_completion
release_recapture_transaction: rN
```

The per-transaction request assertions are now:

```text
axi0_r0_dynamic_request_idle_or_releasing
axi0_r1_dynamic_request_idle_or_releasing
```

The slice preserves:

- `bounded_multi_dynamic_read_rid_rlast_demux_contract`;
- generated last-beat `RID && RLAST` response-demux completion pulses;
- `axi0_read_dynamic_request_onehot0`;
- per-transaction request no-active-same-ID assertions;
- pairwise active dynamic ID uniqueness;
- raw response active-match and response unique-match assertions;
- per-transaction final completion-active assertions; and
- support-accounting coverage for the existing PPIF sample.

## Preservation Consumers

The selected behavior changes the shared multiple dynamic burst-last
response-demux state lifetime but preserves the layered consumers over it:

- scalar last-beat read-data still captures `RDATA/RRESP` under generated
  last-beat completion pulses;
- report-only raw-`ARLEN` still captures request metadata under admitted
  requests;
- runtime beat-count/`RLAST` validation still counts raw matched read beats
  and checks the final boundary; and
- multi-beat output banks still capture every raw matched beat while final
  `RID && RLAST` completion owns transaction release.

## Residue

This slice does not widen request arbitration beyond onehot0 and does not add
queues or scoreboards. Mixed dynamic/static recapture, static busy recapture,
backend-language variants, VHDL, and full AXI manager behavior remain future
exact-owner work.

## Validation

Focused validation covered syntax checks for the generator and focused tests,
a guarded schedule JSON probe for the public PPIF, a guarded focused `t/1438`
dynamic case, direct adapter and generator report probes, and continuity gates.

The host-memory guard stopped broad `t/1436`, broad `t/1437`, and a later
strict-check retry while host memory was above the configured cutoff. The
direct probes above cover the selected public behavior without bypassing the
RAM guard.

## Rollback

Rollback is the `.385` implementation commit. Reverting it removes only the
multiple dynamic read burst-last release-recapture rules, report fields, and
idle-or-releasing assertion names selected by `.384`, restoring the previous
multiple dynamic burst-last response-demux behavior while preserving earlier
single-active and single-beat recapture slices.
