# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Read Response-Demux Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.342`

Date: 2026-06-24

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.343`, public contract selection
for bounded two-dynamic-plus-one-static mixed dynamic/static read single-beat
`RID` response-demux.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or used:

- `.341` two-dynamic-plus-one-static mixed dynamic/static write `BID`
  response-demux behavior.
- `.340` public contract selection for that write boundary.
- `.339` readiness audit for that write boundary.
- `.337` generated one-dynamic plus three-concrete-static mixed read-data
  multi-beat output-bank behavior.
- `.318` one-dynamic plus three-concrete-static mixed write behavior.
- `.322`, `.326`, `.330`, `.333`, `.335`, and `.337` three-static mixed
  read/read-data ladder behavior.
- `.299`, `.303`, `.307`, `.310`, `.312`, and `.314` one-dynamic plus
  two-static mixed read/read-data ladder behavior.
- `.251` multiple all-dynamic read single-beat behavior and `.255` multiple
  all-dynamic read burst-last behavior.
- Current read response-demux admission, normalization, constructor, report,
  and assertion helpers.
- Current read-data coverage predicates, support accounting, focused-test
  costs and RAM-guard caveats, README, `ROADMAP_V2.md`, mdBook, task tree,
  Memory, and Knowledge Map.

## Current Boundary

The shipped mixed dynamic/static read response-demux path currently supports
exactly one dynamic read transaction plus one, two, or three concrete static
read transactions. It is generated for:

- single-beat `RID` response-demux;
- burst-last `RID && RLAST` response-demux;
- scalar single-beat and scalar last-beat read-data;
- report-only raw-`ARLEN` capture;
- runtime beat-count/`RLAST` validation; and
- multi-beat output banks.

The all-dynamic read path separately supports multiple dynamic read
transactions for single-beat `RID` and burst-last `RID && RLAST`
response-demux with onehot0 same-cycle requests and active dynamic selected-ID
uniqueness.

After `.341`, the shared mixed dynamic/static assertion helper can express
multi-dynamic selected-ID policy: request no-active-same-ID, pairwise active
dynamic selected-ID uniqueness, dynamic-vs-static request/active exclusions,
response active-match, response unique-match, and completion-active
assertions over combined dynamic/static state lists.

The mixed read plan builder itself is still singular on the dynamic side:
`_response_demux_dynamic_read_transaction` admits mixed read demux only when
there is exactly one dynamic read transaction plus one, two, or three concrete
static read transactions, and `_response_demux_mixed_dynamic_static_read_transaction`
constructs one `$dynamic_state` plus a list of static states. The fail-closed
diagnostic remains:

```text
AXI manager capacity/status IAL2 contract response_demux.read mixed dynamic/static ID matching supports exactly one dynamic read transaction plus one, two, or three pairwise-distinct concrete static read transactions in this slice
```

## Readiness Findings

Direct behavior implementation is premature for `.342`.

The lower substrate is close because `.341` already proved the combined
two-dynamic/one-static mixed selected-ID policy on the write side, and `.251`
already proved multi-dynamic read single-beat capture/match/release. The
read-side mixed constructor can likely be widened by the same local pattern
used for `.341`: build `@dynamic_states`, block sibling dynamic requests,
block request-time reuse of active sibling dynamic IDs, block the selected
static concrete ID, track all generated completions in transaction order, and
emit list-shaped dynamic capture report fields.

The public contract still needs a separate owner before code changes because
read response-demux has user-visible scope choices and downstream consumers:

- single-beat `RID` should be selected before burst-last `RID && RLAST`, to
  keep final-beat semantics and `last_signal` metadata out of the first
  two-dynamic-plus-static read contract;
- read-data over the new completion source should remain separate until the
  generated completion vocabulary and transaction order are fixed;
- report mode reuse versus new mode naming needs to be recorded explicitly;
- `same_id_conflict_policy: active_dynamic_ids_must_be_unique` needs to be
  selected for the mixed read `dynamic_capture` report; and
- diagnostics for unsupported burst-last, read-data, broader cardinalities,
  same-cycle widening, queues, scoreboards, direct backend, and VHDL need to
  be named before implementation.

## Selected .343 Boundary

`.343` should select only the public contract for bounded
two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID`
response-demux. It should decide and record:

- the exact public PPIF sample stem, with candidate
  `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif`;
- support-accounting identity and focused behavior label;
- reuse of existing explicit `response-demux.read` syntax with
  `response-scope single-beat` and generated transaction completion;
- transaction order `r0`/`r1` dynamic, `r2` concrete static;
- static concrete read ID `3`, reported as `4'd3` in the four-bit public
  sample family;
- report mode, with a bias toward reusing
  `bounded_multi_mixed_dynamic_static_read_rid_demux_contract` and carrying
  cardinality in list-shaped dynamic/static fields;
- transaction completion source, with a bias toward
  `generated_multi_mixed_dynamic_static_read_demux`;
- `dynamic_capture.ownership` and `same_id_conflict_policy` values for the
  two-dynamic mixed read shape;
- onehot0 same-cycle mixed read request policy;
- dynamic-vs-dynamic request no-active-same-ID and active selected-ID
  uniqueness assertions;
- dynamic-vs-static request/active static-ID exclusion assertions;
- raw `RID` response active-match and pairwise unique-match assertions;
- generated completion ordering and release semantics;
- explicit diagnostics, validation gates, rollback, and residue; and
- the next frontier.

`.343` should not implement parser, generator, PPIF sample,
support-accounting catalog, validation behavior, generated artifact, test,
schedule/check/semantic JSON, or HDL behavior.

## Explicit Residue

The following remain future owners:

- direct implementation of two-dynamic-plus-one-static mixed dynamic/static
  read single-beat `RID` response-demux;
- two-dynamic-plus-one-static mixed dynamic/static read burst-last
  `RID && RLAST` response-demux;
- scalar read-data, burst-length/runtime validation, and multi-beat output
  banks over two-dynamic-plus-one-static mixed read demux;
- broader capped mixed write and read cardinalities;
- same-cycle request widening beyond onehot0;
- same-cycle release-and-recapture;
- dynamic same-ID queues and scoreboards;
- direct backend behavior;
- backend-language variants;
- profile aliases, queued/blocking policy, and full-manager behavior; and
- VHDL.

## Validation

Audit validation covers live docs, mdBook, Memory, Knowledge Map, diff
hygiene, and doctrine gates. No behavior changed.

No temporary PPIF candidate was committed. The audit relies on the current
singular mixed read admission/constructor code, the existing multiple
all-dynamic read behavior, and the newly shipped two-dynamic/one-static mixed
write behavior as the bounded implementation evidence.

## Rollback

Rollback is the `.342` audit commit. Reverting it restores `.342` as the
active two-dynamic-plus-one-static mixed read readiness-audit owner and
removes the `.343` contract-selection handoff.
