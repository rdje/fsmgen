# AXI IAL2 Manager Multiple Dynamic Write Recapture Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.377`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.377` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.378`, direct implementation of multiple
all-dynamic write `BID` same-cycle release-and-recapture for the existing
support-accounted sample:

```text
ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif
```

The contract selection changes no parser, generator, PPIF sample,
support-accounting catalog, validation behavior, generated artifact, test,
schedule/check or semantic JSON, HDL, or runtime behavior.

## Public Contract

The implementation must preserve the existing public source syntax,
support-accounting identity, and report mode:

```text
bounded_multi_dynamic_write_bid_demux_contract
```

Same-cycle dynamic write requests remain onehot0. The first multiple-dynamic
write recapture behavior does not widen request arbitration, queues, or
scoreboards.

The selected behavior is per transaction. If a transaction's admitted write
request occurs in the same cycle as that same transaction's generated matched
`BID` completion while its dynamic slot is busy, the generated update must
capture the new `AWID` into that transaction's selected-ID state and keep that
transaction busy for the next cycle. The response match still uses the
pre-update selected ID and busy state.

Cross-transaction release plus capture, such as `w0` completing while `w1`
captures an idle slot, remains the existing capture/release behavior and does
not use a release-recapture report field.

## Generated Update Contract

For each dynamic write transaction, the future implementation should add a
release-recapture rule with the existing generated name pattern:

```text
axi0_w0_dynamic_id_release_recapture
axi0_w1_dynamic_id_release_recapture
```

The release-recapture guard must require:

- that transaction's admitted write request;
- that transaction's generated completion pulse;
- that transaction's busy bit;
- no sibling admitted dynamic write request, preserving onehot0 request
  behavior; and
- no active sibling selected-ID equal to the new request ID.

The release-only rule for each dynamic write transaction must exclude that
transaction's own admitted same-cycle request. Sibling requests do not block
release-only behavior; the existing onehot0 and no-active-same-ID assertions
continue to diagnose illegal sibling/request conflicts.

Capture-only guards remain the existing idle-slot path and continue to require
not-busy, no sibling admitted request, and no active sibling with the requested
ID.

## Report Contract

The future implementation should add per-transaction fields under
`response_demux.write.dynamic_capture.transactions[]`:

```yaml
release_recapture_rule: axi0_w0_dynamic_id_release_recapture
same_cycle_release_recapture_policy: multi_active_unique_dynamic_write
release_recapture_source: generated_dynamic_demux_completion
release_recapture_transaction: w0
```

The second transaction uses the same field names with `w1` and
`axi0_w1_dynamic_id_release_recapture`. Top-level write report fields,
`dynamic_transactions`, `generated_rules`, generated completion signals,
ownership, simultaneous request policy, and same-ID conflict policy remain
unchanged.

## Assertion Contract

The implementation should replace each per-transaction request-not-busy
assertion with request idle-or-releasing semantics:

```text
axi0_w0_dynamic_request_idle_or_releasing
axi0_w1_dynamic_request_idle_or_releasing
```

The remaining multiple-dynamic write assertions stay present:

- `axi0_write_dynamic_request_onehot0`;
- per-transaction request no-active-same-ID assertions;
- pairwise active dynamic-ID uniqueness assertions;
- raw response active-match assertion;
- pairwise response unique-match assertion; and
- per-transaction completion-active assertions.

## Deferred Boundaries

Multiple dynamic read single-beat recapture, multiple dynamic read burst-last
recapture, read-data/burst-length/runtime/multi-beat recapture over multiple
dynamic reads, mixed dynamic/static recapture, static busy recapture, dynamic
same-ID queues, scoreboards, queued/blocking policy, profile aliases, direct
backend behavior, backend-language variants, VHDL, and full AXI manager
behavior remain later exact owners.

## Validation

The selector used direct code/report/test inspection and one guarded baseline
probe:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif
```

The baseline report still contains `bounded_multi_dynamic_write_bid_demux_contract`,
`multi_active_unique_dynamic_write_ids`, `onehot0_dynamic_write_request`,
request-not-busy assertions, active-ID uniqueness, and response unique-match
assertions, and it has no release-recapture fields yet.

Closeout for `.377` remains documentation/doctrine oriented:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

