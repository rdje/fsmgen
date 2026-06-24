# AXI IAL2 Manager Mixed Dynamic Static Recapture Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.387`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.387` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.388`, public contract selection for mixed
dynamic/static write `BID` same-cycle release-and-recapture.

The audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, or runtime behavior.

## Evidence Read

The audit read or used:

- `.386` post multiple dynamic read `RLAST` recapture selector.
- `.385` multiple all-dynamic read burst-last recapture behavior.
- `.381` multiple all-dynamic read single-beat recapture behavior.
- `.378` multiple all-dynamic write recapture behavior.
- `.372`, `.368`, and `.365` single-active recapture behavior/selection
  records.
- `.363` dynamic/mixed same-cycle readiness audit.
- Mixed dynamic/static write, read single-beat, and read burst-last
  response-demux behavior and contract records.
- Current mixed dynamic/static dynamic selected-ID state, static concrete-ID
  busy state, capture guards, release-only rule emission, dynamic
  release-recapture rule emission, assertion specs, report projection, and
  focused t/1436/t1437/t1438 expectation surfaces.
- README, ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map.

The audit also ran guarded baseline schedule probes:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif
```

The live reports still show no release-recapture metadata:

```text
write mode=bounded_mixed_dynamic_static_write_bid_demux_contract
write transaction_completion_source=generated_mixed_dynamic_static_demux
write generated_assertions=axi0_w0_dynamic_request_not_busy, axi0_w1_static_request_not_busy, axi0_write_mixed_dynamic_static_request_onehot0, axi0_w0_dynamic_request_not_static_id, axi0_w0_dynamic_active_not_static_id, axi0_write_mixed_dynamic_static_response_active_match, axi0_w0_w1_write_mixed_dynamic_static_response_unique_match, axi0_w0_dynamic_completion_active, axi0_w1_static_completion_active
write dynamic_release_recapture=none
write static_release_recapture=none

read mode=bounded_mixed_dynamic_static_read_rid_demux_contract
read response_scope=single_beat
read generated_assertions=axi0_r0_dynamic_request_not_busy, axi0_r1_static_request_not_busy, axi0_read_mixed_dynamic_static_request_onehot0, axi0_r0_dynamic_request_not_static_id, axi0_r0_dynamic_active_not_static_id, axi0_read_mixed_dynamic_static_response_active_match, axi0_r0_r1_read_mixed_dynamic_static_response_unique_match, axi0_r0_dynamic_completion_active, axi0_r1_static_completion_active
read dynamic_release_recapture=none
read static_release_recapture=none

read_rlast mode=bounded_mixed_dynamic_static_read_rid_rlast_demux_contract
read_rlast response_scope=burst_last
read_rlast transaction_completion_source=generated_mixed_dynamic_static_read_demux_last_beat
read_rlast dynamic_release_recapture=none
read_rlast static_release_recapture=none
```

## Findings

Mixed dynamic/static response-demux is ready for a public contract selector,
not direct behavior.

The current mixed write and read plans already build a dynamic state with
selected-ID plus busy storage and a static state with concrete-ID busy storage.
Both classes get capture and release rules, request acceptance expressions,
completion-active assertions, and response active/unique-match assertions.
Dynamic capture already blocks selected static concrete IDs, and static capture
already blocks simultaneous dynamic and sibling static requests.

The current release-recapture machinery is dynamic-only. It recognizes
single-active and multiple all-dynamic policies and emits dynamic
release-recapture rules that keep selected ID and busy high on the same-cycle
request plus completion. Static states only have release-only behavior today,
and mixed dynamic/static assertions still require request implies `!busy` for
both dynamic and static transactions.

That means the mixed public contract must define both sides explicitly before
implementation:

- dynamic mixed recapture keeps selected-ID update semantics and static
  concrete-ID exclusion;
- static mixed recapture has no selected-ID update, only busy recapture for a
  concrete-ID slot;
- release-only rules must exclude same-transaction same-cycle requests for any
  recapture-enabled dynamic or static state;
- request assertions must say idle-or-releasing for the enabled class, not
  merely not-busy; and
- mixed onehot0 request, dynamic request/static-ID exclusion, active
  dynamic/static-ID exclusion, raw response active-match, raw response
  unique-match, and completion-active assertions must remain intact.

## Why Mixed Write First

The smallest useful next owner is mixed dynamic/static write `BID` recapture.
It exercises both lifecycle classes in one support-accounted sample:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif
```

Write avoids the extra read preservation stack. Mixed read single-beat adds
`RID`-side read-data interactions, and mixed read burst-last additionally must
preserve final-completion-only `RLAST` behavior, raw non-final beats, scalar
last-beat read-data, raw `ARLEN`, runtime beat-count/`RLAST` validation, and
multi-beat output-bank consumers. Starting with write lets the next selector
pin the common mixed dynamic/static recapture vocabulary and rule semantics
before those read-specific constraints are layered on top.

The audit therefore does not select mixed read single-beat, mixed read
burst-last, static-busy-only recapture, validation retry, helper/report cleanup,
or a narrower prerequisite as the next exact owner.

## Selected .388 Scope

`.388` should select the public contract for mixed dynamic/static write `BID`
same-cycle release-and-recapture on:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif
```

It should decide:

- public syntax and support-accounting identity preservation;
- whether the report mode remains
  `bounded_mixed_dynamic_static_write_bid_demux_contract`;
- dynamic recapture policy/source/report field spelling;
- static recapture policy/source/report field spelling;
- whether recapture fields live under `dynamic_capture`, under
  `static_transaction_state`, or a new mixed lifecycle report block;
- release-only guard changes for dynamic and static states;
- dynamic release-recapture guard requirements, including static concrete-ID
  reservation;
- static release-recapture guard requirements for the concrete busy slot;
- dynamic and static idle-or-releasing assertion names;
- preservation of mixed request onehot0, dynamic request/static-ID exclusion,
  active dynamic/static-ID exclusion, response active-match, response
  unique-match, and completion-active assertions;
- validation gates and host-memory caveats;
- rollback boundary; and
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map updates.

`.388` should not change behavior.

## Deferred Boundaries

This audit does not implement mixed recapture. Mixed read single-beat
recapture, mixed read burst-last recapture, multiple mixed dynamic/static
transaction recapture, static-busy-only recapture outside the selected mixed
write sample, request arbitration beyond onehot0, dynamic same-ID queues,
scoreboards, queued/blocking policy, profile aliases, direct backend behavior,
backend-language variants, VHDL, and full AXI manager behavior remain later
exact owners.

## Validation

Audit validation is the guarded baseline schedule probes above plus continuity
gates:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No focused generator, parser, support-accounting, strict check, semantic JSON,
or HDL probes are required because this audit changes no behavior.

## Rollback

Rollback is the `.387` audit commit. Reverting it restores `.387` as the
active readiness-audit frontier and removes `.388` as the selected public
contract-selection owner.
