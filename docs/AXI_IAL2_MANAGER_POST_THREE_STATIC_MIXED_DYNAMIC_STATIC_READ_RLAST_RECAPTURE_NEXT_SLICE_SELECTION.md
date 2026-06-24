# AXI IAL2 Manager Post Three-Static Mixed Dynamic/Static Read RLAST Recapture Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.424`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.424` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.425`, readiness audit for
two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture.

The candidate public sample is unchanged:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, or runtime behavior.

## Evidence Read

The selector read or used:

- `.423` three-static mixed read burst-last `RID && RLAST` recapture
  behavior.
- `.422` three-static mixed read burst-last recapture contract selection.
- `.421` three-static mixed read burst-last recapture readiness audit.
- `.419` three-static mixed read single-beat `RID` recapture behavior.
- `.415` one-dynamic-plus-two-static mixed read burst-last recapture
  behavior.
- `.411` one-dynamic-plus-two-static mixed read single-beat recapture
  behavior.
- `.407` two-dynamic-plus-one-static mixed write `BID` recapture behavior.
- `.396` one-dynamic-plus-one-static mixed read burst-last recapture
  behavior.
- `.392` one-dynamic-plus-one-static mixed read single-beat recapture
  behavior.
- `.389` one-dynamic-plus-one-static mixed write recapture behavior.
- `.344` two-dynamic-plus-one-static mixed read single-beat response-demux
  behavior.
- `.347` two-dynamic-plus-one-static mixed read burst-last response-demux
  behavior.
- `.350`, `.353`, `.355`, `.357`, and `.361` two-dynamic-plus-one-static
  read-data/raw-`ARLEN`/runtime/multi-beat consumer behavior records.
- Current response-demux read/write normalization, mixed dynamic/static state
  builders, dynamic/static release-only and release-recapture rule helpers,
  assertion/report helpers, focused t/1438 expectation surfaces, support
  accounting, README, ROADMAP_V2, mdBook, Memory, task tree, and Knowledge
  Map.

## Baseline Probe

A direct adapter/report probe confirmed the current two-dynamic-plus-one-static
mixed read response-demux reports remain no-recapture for both single-beat and
burst-last shapes:

```json
[
  {
    "relpath": "ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif",
    "mode": "bounded_multi_mixed_dynamic_static_read_rid_demux_contract",
    "response_scope": "single_beat",
    "transaction_completion_source": "generated_multi_mixed_dynamic_static_read_demux",
    "dynamic_transactions": ["r0", "r1"],
    "static_transactions": ["r2"],
    "static_capture_present": false,
    "dynamic_release_recapture_rules": [],
    "request_not_busy_assertions": 3,
    "idle_or_releasing_assertions": 0
  },
  {
    "relpath": "ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif",
    "mode": "bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract",
    "response_scope": "burst_last",
    "transaction_completion_source": "generated_multi_mixed_dynamic_static_read_demux_last_beat",
    "dynamic_transactions": ["r0", "r1"],
    "static_transactions": ["r2"],
    "static_capture_present": false,
    "dynamic_release_recapture_rules": [],
    "request_not_busy_assertions": 3,
    "idle_or_releasing_assertions": 0
  }
]
```

## Rationale

After `.423`, the one-dynamic mixed read recapture ladder is covered across
one-static, two-static, and three-static cardinalities for both single-beat
and burst-last response-demux behavior. The write-side two-dynamic-plus-one
static recapture behavior is also shipped in `.407`.

The nearest remaining same-cycle recapture residue is therefore the
two-dynamic-plus-one-static mixed read family. It should not jump straight to
contract selection or implementation because it combines concerns from two
previously separate shipped families:

- multi-dynamic selected-ID recapture and active same-ID blocking from the
  dynamic/multi-dynamic recapture path;
- static concrete-ID reservation and static busy release-recapture from the
  mixed dynamic/static path;
- request no-active-same-ID assertions and active dynamic selected-ID
  uniqueness from `.344`/`.347`;
- onehot0 mixed request policy across `r0`, `r1`, and `r2`; and
- read-data/raw-`ARLEN`/runtime/multi-beat consumers that must remain
  preservation-only for the first recapture owner.

The single-beat `RID` shape is the smallest next readiness audit. It avoids
raw non-final `RID` beat preservation and final-only `RLAST` release source
questions while still exercising the two-dynamic-plus-one-static recapture
report, guard, and assertion surfaces.

## Selected .425 Scope

`.425` should audit readiness for two-dynamic-plus-one-static mixed
dynamic/static read single-beat `RID` same-cycle release-and-recapture on:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

The audit should decide whether direct public contract selection is ready or
whether a smaller helper/report prerequisite must land first. It should pin:

- public syntax and support-accounting identity preservation;
- `bounded_multi_mixed_dynamic_static_read_rid_demux_contract`;
- `generated_multi_mixed_dynamic_static_read_demux`;
- `matched_dynamic_or_static_concrete_id_single_beat`;
- dynamic transactions `r0` and `r1`;
- static transaction `r2` at concrete ID `4'd3`;
- report placement for two dynamic release-recapture entries under
  `dynamic_capture.transactions[]`;
- report placement for static busy recapture, likely list-shaped
  `static_capture[]` because the mode is multi-mixed;
- policy spelling for dynamic recapture over a mixed read with multiple active
  dynamic states;
- static policy spelling for `r2`;
- dynamic release-recapture guards that block sibling dynamic requests,
  active sibling same-ID conflicts, static requests, and static ID `4'd3`;
- static release-recapture guards that block both dynamic requests;
- release-only guards that exclude only their own same-transaction request;
- assertion renames from request-not-busy to idle-or-releasing for `r0`,
  `r1`, and `r2`;
- preservation of request no-active-same-ID assertions, active dynamic-ID
  uniqueness, static-ID exclusions, response active-match, pairwise
  unique-match, and completion-active assertions;
- preservation of one-/two-/three-static read recapture and two-dynamic
  write recapture behavior;
- preservation of read-data/raw-`ARLEN`/runtime/multi-beat consumers;
- focused validation gates, direct fallback probes, and RAM-guard constraints;
  and
- rollback, docs, Knowledge Map impact, direct-backend deferral, and VHDL
  deferral.

`.425` should not change behavior.

## Deferred Boundaries

Direct implementation of two-dynamic-plus-one-static read recapture,
two-dynamic-plus-one-static read burst-last recapture, layered
recapture-specific consumer changes, static-busy-only recapture outside
selected public mixed samples, request arbitration beyond onehot0, dynamic
same-ID queues, scoreboards, queued/blocking policy, profile aliases, direct
backend behavior, backend-language variants, VHDL, and full AXI manager
behavior remain later exact owners.

## Validation

`.424` is docs-only. Closeout validation is:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
mdbook build docs/book
scripts/check_doctrines.sh
```

No behavior-bearing command is required for this selector.

## Rollback

Rollback is the `.424` selector commit. Reverting it restores `.424` as the
active post-three-static RLAST recapture selector and removes `.425` as the
selected readiness-audit owner.
