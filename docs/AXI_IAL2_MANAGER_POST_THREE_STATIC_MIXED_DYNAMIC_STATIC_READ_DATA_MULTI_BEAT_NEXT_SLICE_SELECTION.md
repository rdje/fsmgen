# AXI IAL2 Manager Post Three-Static Mixed Dynamic/Static Multi-Beat Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.338`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.338` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.339`, readiness audit for
two-dynamic-plus-one-static mixed dynamic/static write `BID` response-demux.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The selector read or reverified:

- `.337` three-static mixed dynamic/static multi-beat behavior.
- `.336` three-static mixed dynamic/static multi-beat readiness audit.
- `.335` three-static mixed dynamic/static runtime-validation behavior.
- `.333`, `.330`, `.326`, and `.322` three-static read ladder behavior.
- `.318` one-dynamic plus three-static mixed write `BID` response-demux
  behavior.
- `.317` and `.316` broader mixed cardinality selection/audit.
- `.247` bounded multiple all-dynamic write `BID` response-demux behavior.
- Current mixed dynamic/static residue, support-accounting costs, focused
  validation costs and RAM-guard caveats, README, ROADMAP_V2, mdBook, task
  tree, Memory, and Knowledge Map.

## Selection

The next exact owner should audit two dynamic write transactions plus one
concrete static write transaction under generated mixed dynamic/static write
`BID` response-demux.

The candidate public sample stem for the later behavior, if the audit selects
direct implementation, is:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

The candidate support identity is:

```text
intent.ppif_axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic
```

The candidate focused behavior label is:

```text
mixed_dynamic_static_write_demux_multi_dynamic
```

`.339` must decide whether this can be implemented directly, needs public
contract selection first, needs helper/report cleanup, or should defer behind
a narrower prerequisite.

## Why This Owner

The one-dynamic mixed ladder is now complete through one dynamic plus one,
two, and three concrete static transactions for read-data multi-beat output
banks. The remaining mixed-cardinality axis is multiple dynamic transactions
combined with one or more concrete static transactions.

Starting with write `BID` response-demux keeps the next widening at the
smallest behavior-bearing boundary:

- write response-demux has no `RLAST`, `read_data`, burst-length, or
  multi-beat output-bank metadata;
- the all-dynamic multiple write path already proves pairwise dynamic active
  selected-ID assertions and generated `BID` matching;
- the one-dynamic plus static mixed write path already proves static concrete
  ID reservations, dynamic static-ID exclusions, mixed active-match
  assertions, and mixed response unique-match assertions; and
- a two-dynamic-plus-one-static write audit can decide how to combine those
  policies before read-side and read-data owners depend on the answer.

General capped mixed sets, same-cycle widening, release-and-recapture,
dynamic same-ID queues, scoreboards, direct backend behavior,
backend-language variants, and VHDL remain too broad for the immediate next
owner.

## Audit Questions For .339

`.339` should answer:

- whether the public shape is exactly two dynamic write transactions plus one
  concrete static write transaction, or whether a public contract selector is
  needed before choosing that shape;
- whether same-cycle request policy remains `onehot0` for the mixed family;
- how dynamic-vs-dynamic selected-ID uniqueness and dynamic-vs-static
  concrete-ID exclusion assertions compose in a single report;
- whether response active-match and response unique-match assertions can be
  generated from one combined dynamic/static transaction list;
- whether existing report vocabulary can remain list-shaped under the current
  bounded multi mixed write `BID` demux mode, or whether a new contract note is
  required;
- which focused t/1438, support-accounting, and direct CLI probes are needed;
  and
- what exact residue remains for read single-beat response-demux, read
  burst-last response-demux, read-data, burst-length/runtime validation,
  multi-beat output banks, broader cardinalities, same-cycle widening,
  queues/scoreboards, backend variants, and VHDL.

## Validation Strategy

Because `.338` is a selector-only slice, validation is documentation and
continuity focused:

- Knowledge Map generation/check;
- `mdbook build docs/book`;
- memory architecture check;
- `git --no-pager diff --check`; and
- doctrine checks.

No behavior, parser, generator, PPIF, support-accounting catalog, focused
test, schedule/check/semantic JSON, or HDL output changes in this selector.

## Rollback

Rollback is documentation-only: remove this selector note and fact card,
restore `.338` to pending, and restore README, ROADMAP_V2, mdBook, task tree,
Memory, and Knowledge Map to the post-`.337` state.
