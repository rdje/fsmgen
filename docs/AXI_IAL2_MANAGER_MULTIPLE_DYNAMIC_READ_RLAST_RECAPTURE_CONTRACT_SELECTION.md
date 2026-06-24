# AXI IAL2 Manager Multiple Dynamic Read RLAST Recapture Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.384`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.384` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.385`, direct implementation of multiple
all-dynamic read burst-last `RID && RLAST` same-cycle release-and-recapture.

The contract selection changes no parser, generator, PPIF sample,
support-accounting catalog, validation behavior, generated artifact, test,
schedule/check or semantic JSON, HDL, or runtime behavior.

## Public Contract

The implementation must preserve the existing public sample, source syntax,
support-accounting identity, generated response-demux rule names, generated
completion names, and report mode:

```text
ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif
bounded_multi_dynamic_read_rid_rlast_demux_contract
```

Same-cycle dynamic read requests remain onehot0. The contract does not widen
request arbitration, add queues, or add scoreboards.

The behavior is per transaction. If transaction `rN` has an admitted read
request in the same cycle as that same transaction's generated matched
`RID && RLAST` completion while its dynamic slot is busy, the generated update
must capture the new `ARID` into that transaction's selected-ID state and keep
that transaction busy for the next cycle. The response match still uses the
pre-update selected ID and busy state.

Non-final read beats remain raw matched beats only. They must not release the
dynamic slot, must not pulse the generated transaction completion, and must
not trigger release-and-recapture.

## Generated Update Contract

For each dynamic read transaction, the implementation should add the existing
release-recapture rule name pattern:

```text
axi0_r0_dynamic_id_release_recapture
axi0_r1_dynamic_id_release_recapture
```

The release-recapture guard must require:

- that transaction's admitted read request;
- that transaction's generated final `RID && RLAST` completion pulse;
- that transaction's busy bit;
- no sibling admitted dynamic read request; and
- no active sibling selected-ID equal to the new `ARID`.

The release-only rule for each dynamic read transaction must exclude that
transaction's own same-cycle request:

```text
axi0_rN_complete && axi0_rN_dynamic_busy_q && !axi0_rN_request
```

Under that completion guard, `!axi0_rN_request` excludes the same
transaction's admitted same-cycle request because completion contributes to
the admission fan-in. Sibling request conflicts remain diagnosed by the
existing onehot0 and active-ID assertions.

## Report Contract

Each entry in `response_demux.read.dynamic_capture.transactions[]` should
gain:

```yaml
release_recapture_rule: axi0_rN_dynamic_id_release_recapture
same_cycle_release_recapture_policy: multi_active_unique_dynamic_read
release_recapture_source: generated_dynamic_demux_last_beat_completion
release_recapture_transaction: rN
```

Top-level `response_demux.read` fields remain burst-last scoped:

```yaml
mode: bounded_multi_dynamic_read_rid_rlast_demux_contract
response_event_role: raw_accepted_read_response_beat
response_scope: burst_last
transaction_completion_source: generated_dynamic_demux_last_beat
transaction_completion_semantics: matched_dynamic_id_and_last_signal
```

## Assertion Contract

The implementation should replace per-transaction request-not-busy assertions
with request idle-or-releasing assertions:

```text
axi0_r0_dynamic_request_idle_or_releasing
axi0_r1_dynamic_request_idle_or_releasing
```

The remaining multiple dynamic burst-last assertions stay present:

- `axi0_read_dynamic_request_onehot0`;
- per-transaction request no-active-same-ID assertions;
- pairwise active dynamic-ID uniqueness assertions;
- raw response active-match assertion;
- pairwise response unique-match assertion; and
- per-transaction completion-active assertions.

The raw response active/unique-match assertions remain unqualified by `RLAST`,
so non-final beats are legal while mismatched `RID` beats are still diagnosed.
Completion-active assertions remain final-completion scoped.

## Preservation Consumers

The implementation must preserve layered consumers over generated multiple
dynamic read burst-last response-demux:

- scalar last-beat read-data still captures `RDATA`/`RRESP` on the generated
  last-beat completion pulse for the pre-update selected ID;
- report-only raw-`ARLEN` still captures request metadata at the admitted
  request;
- runtime beat-count/`RLAST` validation still counts raw matched beats and
  checks the final `RLAST` boundary; and
- multi-beat output banks still capture every raw matched beat while final
  `RID && RLAST` completion owns transaction release.

## Selected .385 Scope

`.385` should implement only this contract for:

```text
ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif
```

It should update focused t/1436/t1437/t1438 expectations, generated report
docs, README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map. It
should run syntax checks, direct adapter/report preservation probes, guarded
focused dynamic validation, guarded schedule JSON for the affected sample,
and continuity gates. Broader strict check, semantic JSON, HDL, or full
focused suites should run only where the RAM guard permits.

## Deferred Boundaries

Mixed dynamic/static recapture, static busy recapture, request arbitration
beyond onehot0, dynamic same-ID queues, scoreboards, queued/blocking policy,
profile aliases, direct backend behavior, backend-language variants, VHDL, and
full AXI manager behavior remain later exact owners.

## Rollback

Rollback for the future implementation is the `.385` implementation commit.
Reverting that commit should remove only the multiple dynamic burst-last
release-recapture rules, report fields, and assertion renames selected here,
restoring the `.255` burst-last behavior and preserving `.381` single-beat
recapture.

Rollback for this selector is the `.384` commit. Reverting it restores `.384`
as the active public-contract-selection frontier.
