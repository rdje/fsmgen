# AXI IAL2 Manager Post Three-Static Mixed Dynamic/Static Read-Data Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.331`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.332`, readiness audit for
generated report-only raw-`ARLEN` burst-length capture over generated
one-dynamic plus three-concrete-static mixed dynamic/static read burst-last
response-demux and scalar last-beat read-data.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The selector read or used:

- `.330` three-static mixed dynamic/static scalar read-data behavior:
  `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md`
- `.329` three-static mixed dynamic/static read-data contract selection.
- `.328` three-static mixed dynamic/static read-data readiness audit.
- `.326` three-static mixed dynamic/static read burst-last `RID && RLAST`
  response-demux behavior.
- `.322` three-static mixed dynamic/static read single-beat `RID`
  response-demux behavior.
- `.307` two-static mixed dynamic/static scalar read-data behavior.
- `.310`, `.312`, and `.314` two-static mixed dynamic/static raw-`ARLEN`,
  runtime-validation, and multi-beat output-bank behavior.
- Current response-demux/read-data/burst/runtime/multi-beat residue in
  README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map state.

## Why Burst-Length Readiness Is Next

`.330` now supplies scalar read-data capture over both generated
one-dynamic plus three-concrete-static mixed read completion sources:

- single-beat `RID` completions from `.322`; and
- burst-last `RID && RLAST` completions from `.326`.

The remaining read-data-adjacent three-static residue is ordered:

1. report-only raw-`ARLEN` burst-length capture over the three-static
   burst-last scalar read-data shape;
2. runtime beat-count/`RLAST` validation over that raw-`ARLEN` metadata; and
3. multi-beat output banks over the runtime-validation boundary.

The third item depends on the first two. The one-dynamic plus one-static and
one-dynamic plus two-static mixed dynamic/static precedents both settled
request-time raw-`ARLEN` capture before runtime counters or multi-beat
payload banks. The one-dynamic plus three-static mixed read-data family should
follow that order unless the readiness audit finds a smaller prerequisite.

The selected `.332` audit is intentionally narrower than behavior. It should
decide whether the next owner can directly admit the bounded report-only
three-static raw-`ARLEN` shape, needs a public contract-selection leaf first,
needs helper/report cleanup first, or should defer behind another
prerequisite.

## Audit Scope For .332

`.332` must read or reverify:

- `.331` post three-static mixed dynamic/static read-data selector;
- `.330` three-static mixed dynamic/static scalar read-data behavior and its
  two public samples;
- `.329` contract selection and `.328` readiness audit;
- `.326` three-static mixed dynamic/static read burst-last response-demux
  behavior;
- `.322` three-static mixed dynamic/static read single-beat response-demux
  behavior;
- `.310`, `.312`, and `.314` two-static mixed dynamic/static burst-length,
  runtime-validation, and multi-beat precedents;
- `.307` two-static mixed dynamic/static scalar read-data behavior;
- current burst-length coverage gates for generated read-data families;
- request-time raw-`ARLEN` storage/rule/report helpers;
- runtime beat-count/`RLAST` validation helpers, only to preserve that as a
  later owner unless selected separately;
- multi-beat output-bank helpers, only to preserve that as a later owner;
- support-accounting and focused validation costs, including host-memory
  caveats; and
- README, ROADMAP_V2, mdBook, Memory, and Knowledge Map state.

The audit should answer:

- whether report-only raw-`ARLEN` capture over generated one-dynamic plus
  three-concrete-static mixed dynamic/static last-beat read-data can be
  implemented directly;
- whether the public source shape should extend
  `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data.ppif`
  with existing `burst-length` syntax, or needs a separate contract-selection
  owner first;
- whether all covered read transactions `r0`, `r1`, `r2`, and `r3` must carry
  per-transaction burst-length metadata before any behavior widens;
- how one family-level `ARLEN` signal maps to request-time raw-`ARLEN`
  capture for the dynamic transaction and all three concrete static
  transactions;
- whether the `.330` last-beat completion-validity string remains the scalar
  data/status capture guard while burst length captures on request;
- report vocabulary for generated three-static mixed burst-length inputs,
  storage, rules, validation mode, residue movement, and diagnostics;
- fail-closed diagnostics for single-beat burst-length, runtime validation,
  partial transaction coverage, extra transaction coverage,
  two-dynamic-plus-static shapes, broader mixed cardinalities, same-cycle
  widening, release-and-recapture, queues, scoreboards, direct backend
  behavior, backend-language variants, and VHDL;
- sample/support-accounting names for any later implementation owner;
- validation gates, including focused dynamic/mixed suite coverage and direct
  schedule/check/semantic/HDL probes or guarded lightweight fallbacks; and
- rollback and explicit residue.

## Non-Goals

`.331` does not implement burst-length capture, runtime beat-count
validation, multi-beat output banks, broader mixed cardinalities,
same-cycle widening, release-and-recapture, dynamic same-ID queues,
scoreboards, direct backend behavior, backend-language variants, or VHDL.

`.332` is also an audit owner unless it explicitly selects a later
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
HDL probes are required because `.331` changes no behavior.

## Rollback

Rollback is the `.331` selector commit. Reverting it restores `.331` as the
active post three-static mixed dynamic/static read-data selector and removes
the `.332` readiness-audit owner.
