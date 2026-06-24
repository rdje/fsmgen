# AXI IAL2 Manager Mixed Dynamic Static Read RLAST Recapture Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.394`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.394` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.395`, public contract selection for mixed
dynamic/static read burst-last `RID && RLAST` same-cycle
release-and-recapture.

The audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, or runtime behavior.

## Evidence Read

The audit read or used:

- `.393` post mixed read recapture selector.
- `.392` mixed dynamic/static read single-beat recapture behavior.
- `.391` mixed read recapture contract selection.
- `.390` post mixed write recapture selector.
- `.389` mixed dynamic/static write `BID` recapture behavior.
- `.387` mixed dynamic/static recapture readiness audit.
- `.280` mixed dynamic/static read burst-last response-demux behavior.
- Mixed scalar last-beat read-data, raw-`ARLEN`, runtime-validation, and
  multi-beat output-bank behavior docs over generated mixed read burst-last
  response-demux.
- Multiple mixed dynamic/static read/write behavior docs and focused t/1438
  expectation surfaces.
- Current response-demux read normalization, mixed read recapture marking,
  dynamic/static release-recapture rule emission, static busy lifecycle,
  assertion-generation helpers, support accounting, README, ROADMAP_V2,
  mdBook, Memory, task tree, and Knowledge Map.

## Baseline Probe

The audit ran a guarded schedule probe for the selected public sample:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif
```

The guard passed with host memory at 83.0% against the 88% cutoff. The live
report shows:

```text
mode=bounded_mixed_dynamic_static_read_rid_rlast_demux_contract
response_scope=burst_last
last_signal=axi0_rlast
transaction_completion_source=generated_mixed_dynamic_static_read_demux_last_beat
transaction_completion_semantics=matched_dynamic_or_static_concrete_id_and_last_signal
generated_assertions=axi0_r0_dynamic_request_not_busy, axi0_r1_static_request_not_busy, axi0_read_mixed_dynamic_static_request_onehot0, axi0_r0_dynamic_request_not_static_id, axi0_r0_dynamic_active_not_static_id, axi0_read_mixed_dynamic_static_response_active_match, axi0_r0_r1_read_mixed_dynamic_static_response_unique_match, axi0_r0_dynamic_completion_active, axi0_r1_static_completion_active
dynamic_release_recapture=none
static_capture=none
```

## Findings

Mixed dynamic/static read burst-last recapture is ready for public contract
selection. No lower cleanup prerequisite is required before contract work.

The shipped burst-last demux already has the right public shape: one dynamic
read, one concrete static read, `response-scope burst-last`, one one-bit
`last-signal`, raw accepted read-beat assertions, generated final-beat
completion pulses, dynamic selected-ID ownership, static concrete busy
ownership, static-ID reservation, and onehot0 mixed read request policy.

The current recapture machinery already supports the lifecycle classes that
`.395` needs to specify:

- dynamic selected-ID release-and-recapture for read transactions;
- static concrete busy release-and-recapture for mixed dynamic/static
  transactions;
- release-only guards that exclude same-transaction same-cycle requests once
  recapture is enabled;
- idle-or-releasing request assertions for dynamic and static states; and
- report projection through `dynamic_capture` plus `static_capture`.

The remaining missing piece is contract precision for the burst-last source.
Single-beat mixed read recapture currently marks the one-dynamic plus
one-static single-beat branch and reports
`generated_mixed_dynamic_static_read_demux_completion`. The burst-last branch
returns before mixed recapture is marked and must preserve
`generated_mixed_dynamic_static_read_demux_last_beat` as the demux source.
The contract therefore must decide the exact last-beat recapture report source
and field placement before implementation changes behavior.

Raw beat preservation is the main safety condition. The existing burst-last
contract keeps raw active-match and unique-match assertions on accepted `RID`
beats while generated completions additionally require `RLAST`. A future
implementation may only release or recapture from the generated final-beat
completion pulses; it must not release on non-final `RID` beats.

The scalar last-beat read-data, raw-`ARLEN`, runtime beat-count/`RLAST`, and
multi-beat output-bank consumers are preservation clients. They already
consume generated last-beat completion for scalar capture/release boundaries
and raw matched beats for beat-count or lane capture. Contract selection must
name them explicitly as unchanged consumers before implementation.

## Why Contract Selection Next

Direct implementation would be too abrupt because `.395` still needs to pin:

- public syntax and support-accounting identity preservation;
- mode, response scope, last-signal, and completion-source preservation;
- dynamic release-recapture policy/source/report fields under
  `response_demux.read.dynamic_capture`;
- static busy release-recapture policy/source/report fields under
  `response_demux.read.static_capture`;
- release-only exclusion semantics for same-transaction same-cycle requests;
- dynamic/static release-recapture guard requirements;
- idle-or-releasing assertion names;
- raw non-final `RID` beat preservation; and
- validation gates for the selected implementation leaf.

After that contract is selected, direct implementation should be the expected
next owner unless the selector discovers a narrower prerequisite.

## Selected .395 Scope

`.395` should select the public contract for mixed dynamic/static read
burst-last `RID && RLAST` same-cycle release-and-recapture on:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif
```

It should preserve:

- public PPIF syntax and support-accounting identity;
- `bounded_mixed_dynamic_static_read_rid_rlast_demux_contract`;
- `response_scope: burst_last`;
- `last_signal: axi0_rlast`;
- `transaction_completion_source:
  generated_mixed_dynamic_static_read_demux_last_beat`;
- `transaction_completion_semantics:
  matched_dynamic_or_static_concrete_id_and_last_signal`;
- dynamic selected-ID and static concrete busy ownership;
- static concrete-ID reservation;
- onehot0 mixed read request policy;
- raw response active-match and unique-match assertions;
- completion-active assertions; and
- read-data, raw-`ARLEN`, runtime-validation, and multi-beat output-bank
  consumers.

It should decide the exact dynamic and static same-cycle
release-and-recapture report fields, release-only rules, release-recapture
guards, assertion names, validation gates, rollback, docs, Knowledge Map
impact, and deferred boundaries. `.395` should not change behavior.

## Deferred Boundaries

This audit does not implement behavior. Multiple mixed dynamic/static
transaction recapture, static-busy-only recapture outside the selected mixed
read/write samples, request arbitration beyond onehot0, dynamic same-ID
queues, scoreboards, queued/blocking policy, profile aliases, direct backend
behavior, backend-language variants, VHDL, and full AXI manager behavior
remain later exact owners.

## Validation

Audit validation is the guarded baseline schedule probe above plus continuity
gates:

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

Rollback is the `.394` audit commit. Reverting it restores `.394` as the
active readiness-audit frontier and removes `.395` as the selected public
contract-selection owner.
