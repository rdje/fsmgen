# AXI IAL2 Manager Post Mixed Dynamic Static Write Recapture Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.390`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.390` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.391`, public contract selection for mixed
dynamic/static read single-beat `RID` same-cycle release-and-recapture.

The selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, or runtime behavior.

## Evidence Read

The selector read or used:

- `.389` mixed dynamic/static write `BID` recapture behavior.
- `.388` mixed write recapture contract selection.
- `.387` mixed dynamic/static recapture readiness audit.
- `.386` post multiple dynamic read `RLAST` recapture selector.
- `.276` mixed dynamic/static read single-beat response-demux behavior.
- `.280` mixed dynamic/static read burst-last response-demux behavior.
- `.299` and `.303` multiple mixed dynamic/static read single-beat and
  burst-last behavior.
- Mixed read-data, raw-`ARLEN`, runtime-validation, and multi-beat
  preservation records over generated mixed read response-demux.
- Current focused t/1436/t1437/t1438 expectation surfaces, support accounting,
  README, ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map.

The selector also ran guarded baseline schedule probes for the one-dynamic plus
one-static mixed read public samples:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif
```

Both passed below the 88% host-memory cutoff. The post-`.389` reports still
show no read-side release-recapture metadata:

```text
single mode=bounded_mixed_dynamic_static_read_rid_demux_contract
single response_scope=single_beat
single transaction_completion_source=generated_mixed_dynamic_static_read_demux
single generated_assertions=axi0_r0_dynamic_request_not_busy, axi0_r1_static_request_not_busy, axi0_read_mixed_dynamic_static_request_onehot0, axi0_r0_dynamic_request_not_static_id, axi0_r0_dynamic_active_not_static_id, axi0_read_mixed_dynamic_static_response_active_match, axi0_r0_r1_read_mixed_dynamic_static_response_unique_match, axi0_r0_dynamic_completion_active, axi0_r1_static_completion_active
single dynamic_release_recapture=none
single static_capture=none

burst_last mode=bounded_mixed_dynamic_static_read_rid_rlast_demux_contract
burst_last response_scope=burst_last
burst_last transaction_completion_source=generated_mixed_dynamic_static_read_demux_last_beat
burst_last last_signal=axi0_rlast
burst_last generated_assertions=axi0_r0_dynamic_request_not_busy, axi0_r1_static_request_not_busy, axi0_read_mixed_dynamic_static_request_onehot0, axi0_r0_dynamic_request_not_static_id, axi0_r0_dynamic_active_not_static_id, axi0_read_mixed_dynamic_static_response_active_match, axi0_r0_r1_read_mixed_dynamic_static_response_unique_match, axi0_r0_dynamic_completion_active, axi0_r1_static_completion_active
burst_last dynamic_release_recapture=none
burst_last static_capture=none
```

## Rationale

Mixed write recapture now pins the shared dynamic/static lifecycle vocabulary:
dynamic selected-ID release-and-recapture, static concrete busy
release-and-recapture, dynamic/static release-only exclusion, report placement
under `dynamic_capture` and `static_capture`, and idle-or-releasing request
assertions.

The next smallest useful read owner is mixed dynamic/static read single-beat
`RID` recapture. It reuses the same one-dynamic plus one-static public shape as
the shipped `.276` mixed read response-demux sample, but it avoids the extra
burst-last preservation stack. That keeps the next contract focused on:

- preserving `bounded_mixed_dynamic_static_read_rid_demux_contract`;
- preserving `response_scope: single_beat`;
- preserving `generated_mixed_dynamic_static_read_demux` as the completion
  source;
- adapting `.389` dynamic/static recapture report vocabulary to
  `response_demux.read`;
- selecting dynamic/static release-only and release-recapture guards for
  `RID`;
- replacing the selected dynamic/static request-not-busy assertions with
  idle-or-releasing assertions; and
- preserving onehot0 mixed read request, static-ID reservation, response
  active/unique-match, and completion-active assertions.

Mixed read burst-last recapture should wait until single-beat recapture is
selected because it must additionally preserve final-completion-only
`RID && RLAST` release, raw non-final read beat assertions, scalar last-beat
read-data consumers, raw `ARLEN`, runtime beat-count/`RLAST` validation, and
multi-beat output-bank consumers. Multiple mixed dynamic/static recapture and
static-busy-only recapture outside the selected mixed samples are broader than
the next safe slice. The `.389` guarded focused t/1438 host-memory cutoff is
recorded but is not itself a behavior-selection blocker; future behavior slices
can rely on guarded direct probes if broad focused tests are stopped by the RAM
guard.

## Selected .391 Scope

`.391` should select the public contract for mixed dynamic/static read
single-beat `RID` same-cycle release-and-recapture on:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif
```

It should decide:

- public syntax and support-accounting identity preservation;
- whether the report mode remains
  `bounded_mixed_dynamic_static_read_rid_demux_contract`;
- response-scope preservation as `single_beat`;
- dynamic recapture policy/source/report field spelling under
  `response_demux.read.dynamic_capture`;
- static recapture policy/source/report field spelling and public report
  placement under `response_demux.read.static_capture`;
- dynamic and static release-only exclusion semantics for same-transaction
  same-cycle requests;
- dynamic release-recapture guard requirements, including static concrete-ID
  reservation;
- static release-recapture guard requirements for concrete busy slots;
- dynamic and static idle-or-releasing assertion names;
- preservation of mixed request onehot0, dynamic request/static-ID exclusion,
  active dynamic/static-ID exclusion, raw response active-match, raw response
  unique-match, and completion-active assertions;
- validation gates and host-memory caveats;
- rollback boundary; and
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map updates.

`.391` should not change behavior.

## Deferred Boundaries

This selector does not implement behavior. Mixed read burst-last recapture,
multiple mixed dynamic/static transaction recapture, static-busy-only
recapture outside the selected public samples, request arbitration beyond
onehot0, dynamic same-ID queues, scoreboards, queued/blocking policy, profile
aliases, direct backend behavior, backend-language variants, VHDL, and full
AXI manager behavior remain later exact owners.

## Validation

Closeout for `.390` is documentation and continuity only:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No focused generator, parser, support-accounting, strict check, semantic JSON,
or HDL probes are required because this selector changes no behavior.

## Rollback

Rollback is the `.390` selector commit. Reverting it restores `.390` as the
active post-mixed-write selector and removes `.391` as the selected public
contract-selection owner.
