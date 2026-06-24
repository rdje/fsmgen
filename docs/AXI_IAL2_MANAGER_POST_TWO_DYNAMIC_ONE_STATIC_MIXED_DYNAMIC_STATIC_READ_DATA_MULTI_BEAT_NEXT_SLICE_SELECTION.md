# AXI IAL2 Manager Post Two-Dynamic/One-Static Mixed Dynamic/Static Read-Data Multi-Beat Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.358`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.358` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.359`, readiness audit for scalar
single-beat read-data over the `.344` generated two-dynamic-plus-one-static
mixed dynamic/static read single-beat `RID` response-demux.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The selector read or reverified:

- `.357` generated two-dynamic-plus-one-static mixed dynamic/static
  multi-beat read-data behavior.
- `.356` multi-beat readiness audit.
- `.355`, `.353`, and `.350` scalar last-beat raw-`ARLEN`/runtime/read-data
  behavior over the `.347` burst-last demux.
- `.347` two-dynamic-plus-one-static mixed read burst-last `RID && RLAST`
  demux behavior.
- `.344` two-dynamic-plus-one-static mixed read single-beat `RID` demux
  behavior.
- `.307` one-dynamic/two-static mixed scalar read-data behavior.
- `.330` one-dynamic/three-static mixed scalar read-data behavior.
- All-dynamic scalar and multi-beat read-data precedents.
- Current read-data coverage admission, report/residue behavior,
  support-accounting costs, focused-validation costs and RAM-guard caveats,
  README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map.

## Selection

The next exact owner should audit scalar single-beat read-data over the
already shipped `.344` response-demux boundary.

The candidate public sample stem for the later behavior, if the audit selects
direct implementation, is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data.ppif
```

The candidate support identity is:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data
```

The candidate coverage key is:

```text
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data_pipeline_cli
```

The candidate focused behavior label is:

```text
mixed_dynamic_static_read_data_multi_dynamic
```

`.359` must decide whether this can be implemented directly, needs public
contract selection first, needs helper/report cleanup, or should defer behind
a narrower prerequisite.

## Why This Owner

The two-dynamic-plus-one-static branch now has generated write `BID`
response-demux, read single-beat `RID` response-demux, read burst-last
`RID && RLAST` response-demux, scalar last-beat read-data, report-only
raw-`ARLEN`, runtime beat-count/`RLAST` validation, and multi-beat output
banks. The closest omitted sibling is scalar single-beat read-data over the
already shipped `.344` single-beat demux.

This is smaller and more evidence-backed than moving immediately to broader
mixed cardinalities, same-cycle request widening, release-and-recapture,
dynamic same-ID queues, scoreboards, backend variants, VHDL, aliases,
queued/blocking policy, or full-manager behavior.

The current read-data coverage gate is intentionally narrow. It admits the
two-dynamic-plus-one-static transaction set for scalar last-beat, report-only
raw-`ARLEN`, runtime-validation scalar last-beat, and runtime-validation
multi-beat output-bank paths, but it does not yet admit the same transaction
set for scalar single-beat capture over `.344`. That makes a readiness audit
the correct next owner.

## Audit Questions For .359

`.359` should answer:

- whether the public shape should be exactly two dynamic read transactions
  plus one concrete static read transaction under `response-scope single-beat`;
- whether the shape needs a contract selector before behavior implementation;
- whether existing scalar single-beat read-data report vocabulary is
  sufficient, including completion validity
  `generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse`;
- whether coverage admission can be widened locally for
  `generated_multi_mixed_dynamic_static_read_demux`, `capture-scope
  single-beat`, no `burst_length`, two dynamic reads, and one static read;
- which focused t/1438, support-accounting, and direct CLI probes are needed;
  and
- what residue remains for broader mixed cardinalities, same-cycle widening,
  release-and-recapture, dynamic same-ID queues, scoreboards, backend variants,
  VHDL, aliases, queued/blocking policy, and full-manager behavior.

## Validation Strategy

Because `.358` is selector-only, validation is documentation and continuity
focused:

- Knowledge Map generation/check;
- `mdbook build docs/book`;
- memory architecture check;
- `git diff --check`; and
- doctrine checks.

No behavior, parser, generator, PPIF, support-accounting catalog, focused
test, schedule/check/semantic JSON, or HDL output changes in this selector.

## Rollback

Rollback is documentation-only: remove this selector note and fact card,
restore `.358` to pending, and restore README, ROADMAP_V2, mdBook, task tree,
Memory, and Knowledge Map to the post-`.357` state.
