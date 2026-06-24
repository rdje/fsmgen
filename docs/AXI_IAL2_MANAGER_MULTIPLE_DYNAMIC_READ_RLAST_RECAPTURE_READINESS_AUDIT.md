# AXI IAL2 Manager Multiple Dynamic Read RLAST Recapture Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.383`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.383` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.384`, public contract selection for
multiple all-dynamic read burst-last `RID && RLAST` same-cycle
release-and-recapture.

The audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, or runtime behavior.

## Evidence Read

The audit read or used:

- `.382` post multiple dynamic read recapture selector.
- `.381` multiple all-dynamic read single-beat recapture behavior.
- `.380` multiple all-dynamic read single-beat recapture contract.
- `.255` multiple all-dynamic read burst-last `RID && RLAST` response-demux.
- `.259` scalar single-beat and scalar last-beat multiple dynamic read-data.
- `.263` report-only raw-`ARLEN` capture over multiple dynamic last-beat
  read-data.
- `.264` runtime beat-count/`RLAST` validation over the same boundary.
- `.268` multiple dynamic multi-beat output-bank behavior.
- `.372` single-active dynamic read burst-last recapture behavior.
- `.378` multiple dynamic write recapture behavior.
- Current response-demux read normalization, recapture marking,
  release-only/release-recapture rule emission, report, assertion, and focused
  t/1436/t1437/t1438 expectation surfaces.
- README, ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map.

The audit also ran a guarded baseline schedule probe:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif
```

The live report still shows:

```text
mode=bounded_multi_dynamic_read_rid_rlast_demux_contract
response_scope=burst_last
transaction_completion_source=generated_dynamic_demux_last_beat
transaction_completion_semantics=matched_dynamic_id_and_last_signal
generated_assertions=axi0_r0_dynamic_request_not_busy, axi0_r1_dynamic_request_not_busy, ...
r0 release_recapture_rule=none
r1 release_recapture_rule=none
```

## Findings

The implementation substrate is close enough for contract selection but should
not be changed directly in this audit.

The shared dynamic read plan already builds per-transaction selected-ID/busy
state, capture and release rules, request acceptance expressions, sibling
request block expressions, active-same-ID block expressions, request
idle-or-releasing assertion names, and release-recapture rule names for both
single-beat and burst-last response scopes.

The single-beat branch now marks every all-dynamic multi-read state with:

```text
same_cycle_release_recapture_policy = multi_active_unique_dynamic_read
release_recapture_source = generated_dynamic_demux_completion
```

The burst-last branch already marks the single-active dynamic read case with:

```text
same_cycle_release_recapture_policy = single_active_dynamic_read
release_recapture_source = generated_dynamic_demux_last_beat_completion
```

It does not yet mark the multiple all-dynamic burst-last branch. Because of
that, the existing multiple dynamic burst-last sample still emits
request-not-busy assertions and no release-recapture report fields.

The future behavior appears local after contract selection: the implementation
would mark only the all-dynamic multi-read burst-last entry with
`multi_active_unique_dynamic_read` release-recapture metadata and the
last-beat completion source, then rely on the existing release-recapture rule
emitter to add sibling request and active-same-ID guards. The implementation
must remain scoped to `response_scope burst_last` and must not disturb
single-beat recapture, mixed dynamic/static response-demux, or static
transaction behavior.

## Why Contract Selection First

The next behavior has enough public surface to need a contract selector before
code changes:

- the release-recapture source must be pinned as
  `generated_dynamic_demux_last_beat_completion`, not the single-beat source;
- request assertions should become per-transaction idle-or-releasing only for
  the selected burst-last sample;
- release-only rules must exclude the same transaction's same-cycle request
  while preserving sibling-request behavior and onehot0 diagnostics;
- release-recapture guards must require own admitted request, own final
  completion, own busy state, no sibling admitted request, and no active
  sibling with the new `ARID`;
- raw response active/unique-match assertions must remain unqualified by
  `RLAST` so non-final beats stay legal and checked;
- final completion-active assertions must remain final-beat scoped;
- scalar last-beat read-data must still capture on the generated last-beat
  completion pulse for the pre-update selected ID;
- raw-`ARLEN`, runtime beat-count/`RLAST`, and multi-beat output-bank samples
  must keep request-time and raw matched-beat semantics; and
- validation needs targeted parser/generator/dynamic/report probes because
  broad tests can trip the documented host-memory guard.

## Selected .384 Scope

`.384` should select the public contract for multiple all-dynamic read
burst-last `RID && RLAST` same-cycle release-and-recapture on:

```text
ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif
```

It should decide the exact report fields under
`response_demux.read.dynamic_capture.transactions[]`, generated assertion
renames, release-only and release-recapture guard semantics, preservation
checks for scalar last-beat read-data, raw-`ARLEN`, runtime validation, and
multi-beat output banks, validation gates, rollback, docs, Knowledge Map, and
deferred boundaries. The contract selector should not change behavior.

## Deferred Boundaries

This audit does not implement burst-last recapture. Mixed dynamic/static
recapture, static busy recapture, request arbitration beyond onehot0, dynamic
same-ID queues, scoreboards, queued/blocking policy, profile aliases, direct
backend behavior, backend-language variants, VHDL, and full AXI manager
behavior remain later exact owners.

## Validation

Audit validation is the guarded baseline schedule probe above plus continuity
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

Rollback is the `.383` audit commit. Reverting it restores `.383` as the
active readiness-audit frontier and removes `.384` as the selected public
contract-selection owner.
