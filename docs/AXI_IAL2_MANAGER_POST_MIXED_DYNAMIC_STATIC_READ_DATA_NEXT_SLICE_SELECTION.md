# AXI IAL2 Manager Post Mixed Dynamic/Static Read-Data Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.285`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.286`, readiness audit for
generated report-only raw-`ARLEN` burst-length capture over generated mixed
dynamic/static read burst-last response-demux and scalar last-beat read-data.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The selector read or used:

- `.284` mixed dynamic/static scalar read-data behavior:
  `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md`
- `.283` mixed dynamic/static read-data contract selection.
- `.282` mixed dynamic/static read-data readiness audit.
- `.280` mixed dynamic/static read burst-last `RID && RLAST` response-demux
  behavior.
- `.276` mixed dynamic/static read single-beat `RID` response-demux behavior.
- `.272` mixed dynamic/static write `BID` response-demux behavior.
- `.263` and `.264` multiple dynamic burst-length/runtime behavior and the
  `.260`/`.261`/`.262` selector/audit/contract precedent.
- `.238` and `.240` single-active dynamic burst-length/runtime behavior and
  the `.237` readiness-audit precedent.
- `.200` and `.202` mixed auto-ID plus queue-head burst-length/runtime
  behavior and the `.198`/`.199` selector/audit precedent.
- Current read-data response-demux coverage, burst-length normalization,
  request-time raw-`ARLEN` capture, runtime-validation, multi-beat output-bank,
  report, residue, support-accounting, and focused-validation helpers.
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map state.

## Why Burst-Length Readiness Is Next

`.284` now supplies the missing scalar read-data consumer over the mixed
dynamic/static read response-demux completions. The remaining
read-data-adjacent mixed dynamic/static residue is ordered:

1. report-only raw-`ARLEN` burst-length capture over the mixed burst-last
   scalar read-data shape;
2. runtime beat-count/`RLAST` validation over that burst-length metadata; and
3. multi-beat output banks over the runtime-validation boundary.

The third item depends on the first two. The existing single-active dynamic,
multiple-dynamic, queue-head, and mixed auto-ID plus queue-head precedents all
settle request-time raw-`ARLEN` capture before runtime counters or multi-beat
payload banks. The mixed dynamic/static read family should follow that order
unless the readiness audit finds a lower prerequisite.

The selected `.286` audit is intentionally narrower than behavior. It should
decide whether the next owner can directly admit the bounded report-only
mixed dynamic/static raw-`ARLEN` shape, needs a public contract-selection
leaf first, needs helper/report cleanup first, or should defer behind a
smaller prerequisite.

## Audit Scope For .286

`.286` must read or reverify:

- `.284` mixed dynamic/static read-data behavior and its two public samples;
- `.283` contract selection and `.282` readiness audit;
- `.280` mixed dynamic/static read burst-last response-demux behavior;
- `.276` mixed dynamic/static read single-beat response-demux behavior;
- `.272` mixed dynamic/static write response-demux behavior;
- single-active dynamic, multiple-dynamic, queue-head, and mixed auto-ID
  burst-length/runtime precedents;
- current burst-length coverage gates for generated read-data families;
- request-time raw-`ARLEN` storage/rule/report helpers;
- runtime beat-count/`RLAST` validation helpers, only to preserve that as a
  later owner unless selected separately;
- multi-beat output-bank helpers, only to preserve that as a later owner;
- support-accounting and focused validation costs; and
- README, ROADMAP_V2, mdBook, Memory, and Knowledge Map state.

The audit should answer:

- whether report-only raw-`ARLEN` capture over generated mixed dynamic/static
  last-beat read-data can be implemented directly;
- whether the public source shape should extend
  `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data.ppif`
  with existing `burst-length` syntax, or needs a separate contract-selection
  owner first;
- whether all covered mixed dynamic/static read transactions must carry
  per-transaction burst-length metadata before any behavior widens;
- how one family-level `ARLEN` signal maps to request-time raw-`ARLEN` capture
  for the dynamic transaction and the concrete static transaction;
- whether the existing generated mixed last-beat completion validity string
  remains the scalar data/status capture guard while burst length captures on
  request;
- report vocabulary for mixed dynamic/static burst-length generated inputs,
  storage, rules, validation mode, residue movement, and diagnostics;
- fail-closed diagnostics for single-beat burst-length, runtime validation,
  partial transaction coverage, extra transaction coverage, multiple mixed
  transactions, same-cycle widening, release-and-recapture, queues,
  scoreboards, direct backend behavior, backend-language variants, and VHDL;
- sample/support-accounting names for any later implementation owner;
- validation gates, including focused dynamic/mixed suite coverage and direct
  schedule/check/semantic/HDL probes; and
- rollback and explicit residue.

## Non-Goals

`.285` does not implement burst-length capture, runtime beat-count
validation, multi-beat output banks, multiple mixed transactions, same-cycle
widening, release-and-recapture, dynamic same-ID queues, scoreboards, direct
backend behavior, backend-language variants, or VHDL.

`.286` is also an audit owner unless it explicitly selects a later
implementation or contract-selection leaf. It must not change parser,
generator, PPIF samples, support-accounting catalog, validation behavior,
generated artifacts, tests, schedule/check/semantic JSON, or HDL behavior
unless it first records that later owner.

## Validation

Selector validation is documentation and continuity only:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No focused generator, parser, support-accounting, schedule/check/semantic, or
HDL probes are required because `.285` changes no behavior.

## Rollback

Rollback is the `.285` selector commit. Reverting it restores `.285` as the
active post mixed dynamic/static read-data selector and removes the `.286`
readiness-audit owner.
