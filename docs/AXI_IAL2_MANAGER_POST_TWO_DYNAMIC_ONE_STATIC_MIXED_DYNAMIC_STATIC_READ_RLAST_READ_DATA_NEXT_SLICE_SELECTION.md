# AXI IAL2 Manager Post Two-Dynamic/One-Static Mixed Dynamic/Static Read RLAST Read-Data Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.351`

Date: 2026-06-24

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.352`, readiness audit for
generated report-only raw-`ARLEN` burst-length capture over generated
two-dynamic-plus-one-static mixed dynamic/static read burst-last response-demux
and scalar last-beat read-data.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The selector read or used:

- `.350` two-dynamic-plus-one-static mixed dynamic/static scalar read-data
  behavior:
  `docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_BEHAVIOR.md`
- `.349` two-dynamic-plus-one-static mixed dynamic/static read-data contract
  selection.
- `.348` two-dynamic-plus-one-static mixed dynamic/static read-data readiness
  audit.
- `.347` two-dynamic-plus-one-static mixed dynamic/static read burst-last
  `RID && RLAST` response-demux behavior.
- `.344` two-dynamic-plus-one-static mixed dynamic/static read single-beat
  `RID` response-demux behavior.
- `.310`, `.312`, and `.314` one-dynamic plus two-static mixed dynamic/static
  raw-`ARLEN`, runtime-validation, and multi-beat precedents.
- `.333`, `.335`, and `.337` one-dynamic plus three-static mixed
  dynamic/static raw-`ARLEN`, runtime-validation, and multi-beat precedents.
- `.263`, `.264`, and `.268` multiple all-dynamic raw-`ARLEN`,
  runtime-validation, and multi-beat precedents.
- Current response-demux/read-data/burst/runtime/multi-beat residue in
  README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map state.

## Why Burst-Length Readiness Is Next

`.350` now supplies scalar read-data capture over the generated
two-dynamic-plus-one-static mixed read burst-last `RID && RLAST` completion
source selected by `.347`.

The remaining read-data-adjacent two-dynamic-plus-one-static residue is
ordered:

1. report-only raw-`ARLEN` burst-length capture over the
   two-dynamic-plus-one-static burst-last scalar read-data shape;
2. runtime beat-count/`RLAST` validation over that raw-`ARLEN` metadata; and
3. multi-beat output banks over the runtime-validation boundary.

The third item depends on the first two. The multiple all-dynamic,
one-dynamic plus two-static, and one-dynamic plus three-static precedents all
settled request-time raw-`ARLEN` capture before runtime counters or multi-beat
payload banks. The two-dynamic-plus-one-static mixed read family should follow
that order unless the readiness audit finds a smaller prerequisite.

The selected `.352` audit is intentionally narrower than behavior. It should
decide whether the next owner can directly admit the bounded report-only
two-dynamic-plus-one-static raw-`ARLEN` shape, needs a public
contract-selection leaf first, needs helper/report cleanup first, or should
defer behind another prerequisite.

## Audit Scope For .352

`.352` must read or reverify:

- `.351` post two-dynamic-plus-one-static mixed dynamic/static read-data
  selector;
- `.350` two-dynamic-plus-one-static mixed dynamic/static scalar read-data
  behavior and public sample;
- `.349` contract selection and `.348` readiness audit;
- `.347` two-dynamic-plus-one-static mixed dynamic/static read burst-last
  response-demux behavior;
- `.344` two-dynamic-plus-one-static mixed dynamic/static read single-beat
  response-demux behavior;
- `.310`, `.312`, and `.314` two-static mixed dynamic/static burst-length,
  runtime-validation, and multi-beat precedents;
- `.333`, `.335`, and `.337` three-static mixed dynamic/static burst-length,
  runtime-validation, and multi-beat precedents;
- `.263`, `.264`, and `.268` multiple all-dynamic burst-length,
  runtime-validation, and multi-beat precedents;
- current burst-length coverage gates for generated read-data families;
- request-time raw-`ARLEN` storage/rule/report helpers;
- runtime beat-count/`RLAST` validation helpers, only to preserve that as a
  later owner unless selected separately;
- multi-beat output-bank helpers, only to preserve that as a later owner;
- support-accounting and focused validation costs, including host-memory
  caveats; and
- README, ROADMAP_V2, mdBook, Memory, and Knowledge Map state.

The audit should answer:

- whether report-only raw-`ARLEN` capture over generated
  two-dynamic-plus-one-static mixed dynamic/static last-beat read-data can be
  implemented directly;
- whether the public source shape should extend
  `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data.ppif`
  with existing `burst-length` syntax, or needs a separate contract-selection
  owner first;
- whether all covered read transactions `r0`, `r1`, and `r2` must carry
  per-transaction burst-length metadata before any behavior widens;
- how one family-level `ARLEN` signal maps to request-time raw-`ARLEN`
  capture for both dynamic transactions and the concrete static transaction;
- whether the `.350` last-beat completion-validity string remains the scalar
  data/status capture guard while burst length captures on request;
- report vocabulary for generated two-dynamic-plus-one-static mixed
  burst-length inputs, storage, rules, validation mode, residue movement, and
  diagnostics;
- fail-closed diagnostics for single-beat burst-length, runtime validation,
  partial transaction coverage, extra transaction coverage, one-dynamic
  mixed shapes outside their existing owners, broader mixed cardinalities,
  same-cycle widening, release-and-recapture, queues, scoreboards, direct
  backend behavior, backend-language variants, and VHDL;
- sample/support-accounting names for any later implementation owner;
- validation gates, including focused dynamic/mixed suite coverage and direct
  schedule/check/semantic/HDL probes or guarded lightweight fallbacks; and
- rollback and explicit residue.

## Non-Goals

`.351` does not implement burst-length capture, runtime beat-count
validation, multi-beat output banks, broader mixed cardinalities,
same-cycle widening, release-and-recapture, dynamic same-ID queues,
scoreboards, direct backend behavior, backend-language variants, or VHDL.

`.352` is also an audit owner unless it explicitly selects a later
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
HDL probes are required because `.351` changes no behavior.

## Rollback

Rollback is the `.351` selector commit. Reverting it restores `.351` as the
active post two-dynamic-plus-one-static mixed dynamic/static read-data selector
and removes the `.352` readiness-audit owner.
