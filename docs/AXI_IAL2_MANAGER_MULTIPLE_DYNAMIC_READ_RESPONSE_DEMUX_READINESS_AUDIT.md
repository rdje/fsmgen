# AXI IAL2 Manager Multiple Dynamic Read Response-Demux Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.249`

Date: 2026-06-22

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.250`, public contract selection
for bounded multiple dynamic read response-demux behavior.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or used:

- `.248` post multiple dynamic write selector:
  `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md`
- `.247` multiple dynamic write response-demux behavior.
- `.246` multiple dynamic write response-demux contract selection.
- `.245` multiple/mixed dynamic response-demux readiness audit.
- `.243` dynamic multi-beat read-data output-bank behavior.
- `.240` dynamic runtime-validation behavior and `.238` report-only dynamic
  raw-`ARLEN` behavior.
- `.236` bounded dynamic focused-suite cleanup.
- `.234` scalar dynamic read-data behavior.
- `.231` dynamic read burst-last `RID && RLAST` response-demux behavior.
- `.227` dynamic read single-beat response-demux behavior.
- Current response-demux normalizers, dynamic state/capture/release helpers,
  response match helpers, assertion helpers, read-data coverage gate,
  report/residue wording, and focused dynamic tests.
- README, `ROADMAP_V2.md`, mdBook, task tree, Memory, and Knowledge Map.

## Code Findings

The current read normalizer is still the hard fail-closed boundary:

- `_response_demux_dynamic_read_transaction` requires exactly one dynamic read
  transaction.
- The same helper also requires no additional read transactions in the
  selected read family.
- Dynamic read matching still rejects same-family read `auto_id_lifecycle` and
  `same_id_ordering.read`.
- The dynamic read-data coverage gate requires exactly one dynamic read
  transaction and exactly one generated dynamic completion signal.

The lower response-demux substrate is closer to ready:

- Dynamic selected-ID/busy storage is emitted by iterating dynamic transaction
  states.
- Dynamic capture and release rules are already state-list driven.
- Response-demux rules iterate `_response_demux_transaction_states`, so more
  than one read dynamic state can be represented after normalization admits
  it.
- `_response_demux_guard_expr` already adds the read `last_signal` to
  `burst_last` completion guards.
- `_response_demux_match_expr` intentionally omits `last_signal`, which lets
  read assertions and read-data beat counting reason about raw matched `RID`
  beats independent of final `RLAST` completion.
- `_response_demux_dynamic_assertion_specs_for_family` is already
  family-generic and can express request onehot0, request no-active-same-ID,
  active-ID uniqueness, response active-match, response unique-match, and
  completion-active assertions for multiple dynamic states once read states
  are normalized with the needed assertion names.

## Why Contract Selection First

Multiple dynamic read response-demux is not just the write behavior with
`RID` substituted for `BID`. The public contract must first define:

- whether the first read behavior covers `single_beat`, `burst_last`, or both;
- whether all read transactions in the selected family must be dynamic, as the
  `.247` write contract requires for write;
- whether the first public sample is response-demux-only or also preserves
  selected scalar read-data behavior;
- how raw matched `RID` beats feed runtime beat-count/`RLAST` validation and
  multi-beat output-bank capture when multiple dynamic read transactions are
  active;
- whether response active-match and unique-match assertions are checked on
  every raw read beat, while completion pulses for `burst_last` still require
  `RLAST`;
- how same-cycle dynamic read requests are handled when their `ARID` values
  compare equal or differ; and
- how read-specific report vocabulary names the capture ownership,
  simultaneous request policy, same-ID conflict policy, response scope, last
  signal, raw beat match source, and explicit residue.

Selecting those public semantics in `.250` keeps the later implementation
bounded and reviewable. Direct behavior before that contract would risk
mixing response-demux-only behavior, read-data preservation, burst accounting,
and multi-beat output-bank semantics in one slice.

## Selected .250 Boundary

`.250` should select the exact public contract for the first multiple dynamic
read response-demux implementation owner. It should define, at minimum:

- the first read-family shape and whether it is all-dynamic;
- the selected response scope or scopes;
- whether read-data remains fail-closed for multiple dynamic read demux in the
  first implementation or is preserved for a named scalar subset;
- selected-ID/busy state, capture guard, release, response match, assertion,
  and report vocabulary;
- same-cycle request and active same-ID policy;
- public PPIF sample/support-accounting expectations for the later
  implementation;
- focused `t/1438` coverage expectations;
- explicit deferrals for mixed dynamic/static demux, same-cycle widening,
  release-and-recapture, dynamic same-ID queues, scoreboards, direct backend
  behavior, backend-language variants, and VHDL.

`.250` should not implement behavior. It should not change parser, generator,
PPIF samples, support accounting, validation behavior, generated artifacts,
tests, schedule/check/semantic JSON, or HDL behavior except to record the
selected later owner.

## Non-Goals

This audit does not implement multiple dynamic read response-demux, read-data
coverage widening, mixed dynamic/static demux, same-cycle request widening,
release-and-recapture, dynamic same-ID ordering, queues, scoreboards, direct
backend behavior, backend-language variants, or VHDL.

## Validation

Audit validation covered code review, live docs, mdBook, Memory, Knowledge
Map, and doctrine gates. No behavior changed.

## Rollback

Rollback is the `.249` audit commit. Reverting it restores `.249` as the
active readiness audit and removes the `.250` contract-selection owner.
