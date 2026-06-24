# AXI IAL2 Manager Multiple Dynamic Read Recapture Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.380`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.380` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.381`, direct implementation of multiple
all-dynamic read single-beat `RID` same-cycle release-and-recapture for the
existing support-accounted sample:

```text
ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif
```

The contract selection changes no parser, generator, PPIF sample,
support-accounting catalog, validation behavior, generated artifact, test,
schedule/check or semantic JSON, HDL, or runtime behavior.

## Public Contract

The implementation must preserve the existing public source syntax,
support-accounting identity, generated completion names, generated
response-demux rule names, and report mode:

```text
bounded_multi_dynamic_read_rid_demux_contract
```

Same-cycle dynamic read requests remain onehot0. The first multiple-dynamic
read recapture behavior does not widen request arbitration, add queues, or add
scoreboards.

The selected behavior is per transaction. If a transaction's admitted read
request occurs in the same cycle as that same transaction's generated matched
single-beat `RID` completion while its dynamic slot is busy, the generated
update must capture the new `ARID` into that transaction's selected-ID state
and keep that transaction busy for the next cycle. The response match still
uses the pre-update selected ID and busy state.

Cross-transaction release plus capture, such as `r0` completing while `r1`
captures an idle slot, remains the existing capture/release behavior and does
not use a release-recapture report field.

## Generated Update Contract

For each dynamic read transaction, the future implementation should add a
release-recapture rule with the existing generated name pattern:

```text
axi0_r0_dynamic_id_release_recapture
axi0_r1_dynamic_id_release_recapture
```

The release-recapture guard must require:

- that transaction's admitted read request;
- that transaction's generated single-beat completion pulse;
- that transaction's busy bit;
- no sibling admitted dynamic read request, preserving onehot0 request
  behavior; and
- no active sibling selected-ID equal to the new request ID.

The release-only rule for each dynamic read transaction must exclude that
transaction's own same-cycle request. Sibling requests do not block release-only
behavior; the existing onehot0 and no-active-same-ID assertions continue to
diagnose illegal sibling/request conflicts.

Capture-only guards remain the existing idle-slot path and continue to require
not-busy, no sibling admitted request, and no active sibling with the requested
ID.

## Report Contract

The future implementation should add per-transaction fields under
`response_demux.read.dynamic_capture.transactions[]`:

```yaml
release_recapture_rule: axi0_r0_dynamic_id_release_recapture
same_cycle_release_recapture_policy: multi_active_unique_dynamic_read
release_recapture_source: generated_dynamic_demux_completion
release_recapture_transaction: r0
```

The second transaction uses the same field names with `r1` and
`axi0_r1_dynamic_id_release_recapture`. Top-level read report fields,
`dynamic_transactions`, `generated_rules`, generated completion signals,
ownership, simultaneous request policy, and same-ID conflict policy remain
unchanged.

## Assertion Contract

The implementation should replace each per-transaction request-not-busy
assertion with request idle-or-releasing semantics:

```text
axi0_r0_dynamic_request_idle_or_releasing
axi0_r1_dynamic_request_idle_or_releasing
```

The remaining multiple-dynamic read assertions stay present:

- `axi0_read_dynamic_request_onehot0`;
- per-transaction request no-active-same-ID assertions;
- pairwise active dynamic-ID uniqueness assertions;
- raw response active-match assertion;
- pairwise response unique-match assertion; and
- per-transaction completion-active assertions.

## Read-Data Preservation

The scalar single-beat multiple dynamic read-data sample remains a preservation
consumer:

```text
ppif/axi_manager_capacity_status_dynamic_read_data_multi.ppif
```

The implementation should not change the read-data public syntax, read-data
report mode, generated `RDATA`/`RRESP` inputs, scalar outputs, or capture rule
ownership. Read-data capture remains guarded by each transaction's generated
dynamic completion pulse. In a same-cycle release-and-recapture cycle, that
completion pulse belongs to the response matched against the pre-update
selected ID; the newly captured `ARID` is visible only for later response
matching.

## Deferred Boundaries

Multiple dynamic read burst-last `RID && RLAST` recapture, scalar last-beat
read-data recapture preservation, report-only raw-`ARLEN`, runtime
beat-count/`RLAST`, multi-beat output-bank recapture preservation, mixed
dynamic/static recapture, static busy recapture, dynamic same-ID queues,
scoreboards, queued/blocking policy, profile aliases, direct backend behavior,
backend-language variants, VHDL, and full AXI manager behavior remain later
exact owners.

## Validation

The selector used direct code/report/test inspection and one guarded baseline
probe:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif
```

The baseline report still contains `bounded_multi_dynamic_read_rid_demux_contract`,
`multi_active_unique_dynamic_read_ids`, `onehot0_dynamic_read_request`,
request-not-busy assertions, active-ID uniqueness, response unique-match
assertions, and no release-recapture fields yet.

Closeout for `.380` remains documentation/doctrine oriented:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```
