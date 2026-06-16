# AXI IAL2 Manager Post Write Multi-Group Queue-Head Response-Demux Next Slice Selection

Status: selector for `IAL2-FEATURE-COMPLETENESS-FRONTIER.141` on
2026-06-16.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.141`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.142`, readiness audit for
generated read single-beat multi-group queue-head response-demux.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes in this selector slice.

## Evidence

The adjacent generated queue-head response-demux shapes are now:

- one duplicate concrete write-ID group, shipped by `.108`;
- one duplicate concrete read-ID group with `response-scope single-beat`,
  shipped by `.110`;
- multiple duplicate concrete read-ID groups with `response-scope burst-last`,
  shipped by `.124`;
- multiple duplicate concrete write-ID groups, shipped by `.140`.

The remaining direct response-demux-only multi-group sibling is read
`single-beat`: multiple duplicate concrete read-ID groups without `RLAST` and
without `read_data`.

A temporary `/tmp/fsmgen_read_single_multi_group_probe.ppif` source with
`r0`/`r1` sharing concrete `RID` `3` and `r2`/`r3` sharing concrete `RID` `5`
was accepted as selected queue-head metadata but remained generated-false:

```text
generated=0
read_generated=0
groups=2
status=selected_not_generated
response_residue=generated_same_id_queue_head_demux,read_data_interleaving,bursts
same_residue=concrete_id_same_id_ordering,per_id_issue_order_queues
```

That is the expected pre-audit state. The temporary probe was removed after
use.

## Why .142 Is An Audit

The shape is adjacent to shipped behavior, but a direct implementation should
not be selected without checking the exact lowerer/report boundaries:

- `.124` proves generated read burst-last multi-group response-demux, where
  queue-head completion is gated by `RLAST`;
- `.110` proves generated read single-beat queue-head response-demux, but only
  for one duplicate concrete read-ID group;
- `.140` proves generated multi-group queue-head behavior can be safe without
  widening the family-wide admitted-request onehot boundary, but it is in the
  write family;
- the current builder gate still intentionally permits multi-group read only
  for burst-last and multi-group write only for `BID` response demux.

`.142` must audit whether widening read single-beat to multiple groups is
only a local builder gate change, or whether response-state, assertion,
read-data coverage, support-accounting, or report wording needs a prerequisite
first.

## Candidate Implementation Boundary For .142

If the audit finds no prerequisite, the follow-on behavior slice should be
bounded to:

- read family only;
- `response-scope single-beat` only;
- generated queue-head response demux only;
- no `last-signal`;
- no `read_data` clause;
- two or more duplicate concrete read-ID groups in the same manager object;
- every covered group exactly two read transactions at computed depth `2`;
- selected `same-id-ordering.read concrete-id-reuse issue-order-queue`;
- no same-family `auto-id-lifecycle` demux;
- no queue depth greater than `2`;
- no write-family widening beyond `.140`;
- no read burst-last widening beyond already-shipped `.124`;
- no group-local simultaneous enqueue widening.

## Deferred Work

The following remain outside `.142`:

- implementation behavior changes;
- deeper queues;
- same-family mixed auto-ID plus concrete queue-head response demux;
- read-data over read single-beat multiple queue groups;
- packed outputs and alternate payload assembly;
- direct backend lowering;
- VHDL.

## Validation Gates For .142

The audit should read the `.140`, `.124`, `.110`, and `.108` behavior notes,
the current queue-head builder/report/residue code, focused tests, public
samples, support accounting, README, roadmap, mdBook, task tree, Memory, and
Knowledge Map. It should include live probes for the existing adjacent public
samples and a temporary read single-beat multi-group probe, then select either
a direct implementation owner or a prerequisite owner before any behavior
change.
