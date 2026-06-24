# AXI IAL2 Manager Broader Mixed Dynamic Static Recapture Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.398`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.398` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.399`, public contract selection for
one-dynamic plus two-static mixed dynamic/static write `BID` same-cycle
release-and-recapture.

The selected public sample is unchanged:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif
```

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, or runtime behavior.

## Evidence Read

The audit read or used:

- `.397` post mixed read `RLAST` recapture selector.
- `.396` mixed dynamic/static read burst-last `RID && RLAST` recapture
  behavior.
- `.395` mixed read burst-last recapture contract selection.
- `.394` mixed read burst-last recapture readiness audit.
- `.393` post mixed read recapture selector.
- `.392` mixed dynamic/static read single-beat `RID` recapture behavior.
- `.389` mixed dynamic/static write `BID` recapture behavior.
- `.387` mixed dynamic/static recapture readiness audit.
- Multiple mixed dynamic/static write, read single-beat, and read burst-last
  response-demux behavior records.
- One-dynamic plus three-static and two-dynamic-plus-one-static mixed
  dynamic/static write/read/read-`RLAST` behavior records.
- Mixed read-data, raw-`ARLEN`, runtime-validation, and multi-beat
  preservation records for one-static, two-static, three-static, and
  two-dynamic-plus-one-static mixed read families.
- Current response-demux write/read normalization, mixed dynamic/static state
  builders, static busy lifecycle helpers, dynamic/static release-only and
  release-recapture rule helpers, assertion/report helpers, focused
  t/1436/t1437/t1438 expectation surfaces, support accounting, README,
  ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map.

## Guarded Baseline Probes

The audit ran guarded schedule probes under the repository RAM guard. All
completed without raising the default 88% host-memory cutoff:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static3.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

The selected two-static write baseline reports:

```text
mode=bounded_multi_mixed_dynamic_static_write_bid_demux_contract
transaction_completion_source=generated_multi_mixed_dynamic_static_demux
dynamic_transactions=w0
static_transactions=w1,w2
dynamic_capture keys include transactions and static_id_exclusions
static_capture=absent
generated_assertions include request-not-busy for w0, w1, and w2
```

The adjacent three-static write baseline has the same mode/source, one dynamic
transaction, static transactions `w1,w2,w3`, no `static_capture`, and
request-not-busy assertions for all four transactions. The adjacent
two-dynamic-plus-one-static write baseline has the same mode/source, dynamic
transactions `w0,w1`, static transaction `w2`, no `static_capture`, and adds
`same_id_conflict_policy: active_dynamic_ids_must_be_unique` plus dynamic
request no-active-same-ID and dynamic active-ID uniqueness assertions.

## Findings

Broader mixed dynamic/static recapture is ready for public contract selection,
not direct implementation. The existing generator substrate already loops over
mixed dynamic/static state lists for capture rules, release rules, static
release-recapture rules once policy metadata is present, onehot0 request
assertions, dynamic/static ID exclusion assertions, active-match assertions,
pairwise unique-match assertions, and completion-active assertions.

The missing contract surface is report and guard precision for list-shaped
mixed dynamic/static captures. The one-dynamic plus one-static family reports
a singular `dynamic_capture` object and singular `static_capture` object. The
broader multi-static write family already reports `dynamic_capture.transactions`
and `static_id_reservations`, but it has no public `static_capture` list and
no per-transaction release-recapture metadata yet.

The smallest safe next owner is the one-dynamic plus two-static write `BID`
sample:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif
```

It is smaller than the three-static write sample because it introduces only
one sibling static busy slot beyond the already shipped one-static recapture
contract. It is smaller than the two-dynamic-plus-one-static write sample
because it does not add dynamic-vs-dynamic no-active-same-ID recapture
requirements, active dynamic-ID uniqueness preservation, or multiple dynamic
recapture report entries. It is smaller than read-side shapes because it
avoids scalar read-data, raw-`ARLEN`, runtime-validation, multi-beat output
bank, and raw non-final `RID` preservation constraints.

## Selected .399 Scope

`.399` should select the public contract for one-dynamic plus two-static
mixed dynamic/static write `BID` same-cycle release-and-recapture on:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif
```

It should preserve:

- public PPIF syntax and support-accounting identity;
- mode `bounded_multi_mixed_dynamic_static_write_bid_demux_contract`;
- `transaction_completion_source: generated_multi_mixed_dynamic_static_demux`;
- `transaction_completion_semantics: matched_dynamic_or_static_concrete_id`;
- `dynamic_transactions: [w0]`;
- `static_transactions: [w1, w2]`;
- `mixed_transactions.dynamic: [w0]`;
- `mixed_transactions.static: [w1, w2]`;
- `static_id_reservations` for `4'd3` and `4'd5`;
- dynamic capture exclusions against both static concrete IDs;
- onehot0 mixed write request policy;
- dynamic request/static-ID exclusion assertions;
- active dynamic/static-ID exclusion assertions;
- response active-match assertion;
- pairwise response unique-match assertions across dynamic/static/static
  matches; and
- completion-active assertions for all three transactions.

It should decide:

- whether the dynamic recapture fields live on
  `response_demux.write.dynamic_capture.transactions[0]` or another
  list-shaped field;
- how static concrete busy recapture is reported, with a bias toward
  `response_demux.write.static_capture` as a list of entries ordered by
  `static_transactions`;
- per-transaction rule/source/report spelling:
  `axi0_w0_dynamic_id_release_recapture`,
  `axi0_w1_static_busy_release_recapture`, and
  `axi0_w2_static_busy_release_recapture`;
- whether policy strings remain `mixed_dynamic_static_dynamic_write` and
  `mixed_dynamic_static_static_write`, with the multi-static distinction
  carried by the existing multi-mixed mode and list fields;
- release-only guard updates so dynamic/static release rules exclude their
  own same-transaction same-cycle requests;
- dynamic release-recapture guards requiring no admitted static sibling
  request and `AWID` not equal to either reserved static ID;
- static release-recapture guards requiring no admitted dynamic request and no
  admitted sibling static request;
- assertion renames from request-not-busy to idle-or-releasing for `w0`,
  `w1`, and `w2`;
- focused validation gates and RAM-guard constraints;
- rollback, docs, Knowledge Map impact; and
- deferred read-side, three-static, two-dynamic, backend, and VHDL
  boundaries.

`.399` should not change behavior.

## Deferred Boundaries

Direct implementation of the `.399` contract, three-static mixed write
recapture, two-dynamic-plus-one-static mixed write recapture, mixed read
single-beat multi-static recapture, mixed read burst-last multi-static
recapture, read-data/raw-`ARLEN`/runtime/multi-beat preservation behavior,
static-busy-only recapture outside selected public mixed samples, request
arbitration beyond onehot0, dynamic same-ID queues, scoreboards,
queued/blocking policy, profile aliases, direct backend behavior,
backend-language variants, VHDL, and full AXI manager behavior remain later
exact owners.

## Validation

Audit validation is the guarded baseline schedule probes above plus
continuity gates:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
mdbook build docs/book
scripts/check_doctrines.sh
```

No parser, support-accounting, strict check, semantic JSON, HDL, or focused
test rerun is required because this audit changes no behavior.

## Rollback

Rollback is the `.398` audit commit. Reverting it restores `.398` as the
active broader mixed recapture readiness-audit frontier and removes `.399` as
the selected public contract-selection owner.
