# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Read Recapture Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.425`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.425` audits readiness for
two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture on the existing public sample:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

The audit selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.426`, public contract
selection for that exact single-beat read recapture behavior.

This slice changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, or runtime behavior.

## Evidence Read

The audit read or used:

- `.424` post-three-static RLAST recapture next-slice selection.
- `.423` one-dynamic-plus-three-static mixed read burst-last `RID && RLAST`
  recapture behavior.
- `.419` one-dynamic-plus-three-static mixed read single-beat `RID`
  recapture behavior.
- `.415` and `.411` one-dynamic-plus-two-static mixed read burst-last and
  single-beat recapture behavior.
- `.407` two-dynamic-plus-one-static mixed write `BID` recapture behavior.
- `.344` two-dynamic-plus-one-static mixed read single-beat response-demux
  behavior.
- `.347` two-dynamic-plus-one-static mixed read burst-last response-demux
  behavior.
- `.350`, `.353`, `.355`, `.357`, and `.361`
  two-dynamic-plus-one-static read-data, raw-`ARLEN`, runtime-validation, and
  multi-beat consumer records.
- Current read response-demux normalization, mixed dynamic/static state
  builders, release-only and release-recapture rule lowerers, assertion
  projection, focused `t/1438` report helpers, support accounting, README,
  ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map.

## Baseline Probes

A RAM-guarded schedule JSON probe for the selected sample was attempted with
the default host cutoff:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

The sandboxed first attempt could not inspect the process tree, so the same
guarded probe was rerun with process-inspection approval. The guard stopped
before useful output because host memory was already 95.3%, above the default
88% cutoff. No cutoff was raised.

A direct adapter/report fallback probe for the selected sample confirmed the
current no-recapture baseline:

```json
{
  "mode": "bounded_multi_mixed_dynamic_static_read_rid_demux_contract",
  "response_scope": "single_beat",
  "transaction_completion_source": "generated_multi_mixed_dynamic_static_read_demux",
  "transaction_completion_semantics": "matched_dynamic_or_static_concrete_id_single_beat",
  "dynamic_transactions": ["r0", "r1"],
  "static_transactions": ["r2"],
  "static_id_reservations": [
    {
      "transaction": "r2",
      "concrete_id": 3,
      "concrete_id_literal": "4'd3",
      "dynamic_capture_policy": "dynamic_id_must_not_equal_static_concrete_id"
    }
  ],
  "dynamic_capture_transactions": [
    {"transaction": "r0", "has_release_recapture": false},
    {"transaction": "r1", "has_release_recapture": false}
  ],
  "static_capture_present": false,
  "release_recapture_rules_in_isf": [],
  "generated_assertions": [
    "axi0_r0_dynamic_request_not_busy",
    "axi0_r1_dynamic_request_not_busy",
    "axi0_r2_static_request_not_busy",
    "axi0_read_mixed_dynamic_static_request_onehot0",
    "axi0_r0_dynamic_request_no_active_same_id",
    "axi0_r1_dynamic_request_no_active_same_id",
    "axi0_r0_r1_read_dynamic_active_id_unique",
    "axi0_r0_r2_read_dynamic_request_not_static_id",
    "axi0_r0_r2_read_dynamic_active_not_static_id",
    "axi0_r1_r2_read_dynamic_request_not_static_id",
    "axi0_r1_r2_read_dynamic_active_not_static_id",
    "axi0_read_mixed_dynamic_static_response_active_match",
    "axi0_r0_r1_read_mixed_dynamic_static_response_unique_match",
    "axi0_r0_r2_read_mixed_dynamic_static_response_unique_match",
    "axi0_r1_r2_read_mixed_dynamic_static_response_unique_match",
    "axi0_r0_dynamic_completion_active",
    "axi0_r1_dynamic_completion_active",
    "axi0_r2_static_completion_active"
  ]
}
```

Direct comparison probes also confirmed:

- the two-dynamic-plus-one-static burst-last read sibling remains no-recapture
  with request-not-busy assertions and absent `static_capture`;
- the shipped two-dynamic-plus-one-static write sibling reports list-shaped
  dynamic recapture for `w0` and `w1`, list-shaped static recapture for `w2`,
  and `mixed_dynamic_static_multi_active_dynamic_write`; and
- the one-dynamic-plus-two-static read single-beat sibling still reports
  list-shaped static capture for `r1` and `r2` and
  `mixed_dynamic_static_dynamic_read` for `r0`.

## Readiness Findings

The public source shape is already bounded and support-accounted. It has the
selected mode, transaction completion source, static ID reservation, generated
rules, generated completions, and assertion substrate needed for a direct
public recapture contract.

The read mixed dynamic/static state builder already attaches the guard
operands needed by a two-dynamic-plus-one-static recapture rule:

- sibling dynamic request block expressions;
- active sibling same-ID block expressions;
- static request block expressions;
- static ID block expressions for `4'd3`; and
- dynamic request block expressions for the static recapture rule.

The reusable report and lowerer substrate is mostly present:

- one-dynamic mixed read recapture already projects dynamic recapture fields,
  list-shaped static recapture fields in multi-mixed modes, release-only
  same-transaction exclusions, and idle-or-releasing assertions;
- two-dynamic mixed write recapture already projects the multi-active dynamic
  mixed/static report shape and list-shaped static capture for the
  two-dynamic-plus-one-static cardinality; and
- the dynamic release-recapture lowerer already has a combined guard branch
  for the write policy that uses sibling dynamic request blocks, active
  same-ID blocks, static request blocks, and static ID blocks.

The exact implementation gap is policy selection and recognition for the read
family, not public syntax or missing state data:

- `_response_demux_mark_mixed_dynamic_static_read_recapture` currently marks
  only exactly one dynamic read transaction plus one, two, or three static
  read transactions.
- Dynamic recapture recognition has
  `mixed_dynamic_static_multi_active_dynamic_write`, but no read sibling.
- The multi-dynamic mixed read focused report helpers currently expect no
  release-recapture fields, no `static_capture`, and request-not-busy
  assertions.

## Decision

Direct public contract selection is ready. `.426` should select the exact
two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID`
recapture contract, rather than inserting a behavior-free helper prerequisite.

The contract selection should pin a new read-side policy spelling for dynamic
entries:

```text
mixed_dynamic_static_multi_active_dynamic_read
```

and should preserve the existing static policy spelling:

```text
mixed_dynamic_static_static_read
```

Implementation remains deferred to the implementation owner selected after
`.426`.

## Selected .426 Scope

`.426` should select the public contract for same-cycle release-and-recapture
on:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

The contract should preserve:

- public PPIF syntax and support-accounting identity;
- `bounded_multi_mixed_dynamic_static_read_rid_demux_contract`;
- `response_scope: single_beat`;
- `generated_multi_mixed_dynamic_static_read_demux`;
- `matched_dynamic_or_static_concrete_id_single_beat`;
- dynamic transactions `r0` and `r1`;
- static transaction `r2` at `4'd3`;
- generated response-demux rules and generated completion pulses;
- onehot0 mixed read request policy;
- request no-active-same-ID assertions for `r0` and `r1`;
- active dynamic selected-ID uniqueness;
- dynamic request/static-ID and active/static-ID exclusions for both dynamic
  transactions against `r2`;
- response active-match and pairwise unique-match assertions; and
- dynamic/static completion-active assertions.

The contract should require:

- dynamic release-recapture report fields under
  `dynamic_capture.transactions[0]` and `[1]`;
- `release_recapture_source` set to
  `generated_multi_mixed_dynamic_static_read_demux_completion`;
- `release_recapture_transaction: r0` and `r1` on the corresponding dynamic
  entries;
- list-shaped `static_capture[]` with one `r2` entry because the mode is
  multi-mixed;
- `r2` static release-recapture source
  `generated_multi_mixed_dynamic_static_read_demux_completion`;
- dynamic recapture guards that block sibling dynamic requests, active
  sibling same-ID conflicts, static requests, and static ID `4'd3`;
- static recapture guards that block both dynamic requests;
- release-only rules for `r0`, `r1`, and `r2` that exclude only their own
  same-transaction request; and
- generated assertions renamed to:
  `axi0_r0_dynamic_request_idle_or_releasing`,
  `axi0_r1_dynamic_request_idle_or_releasing`, and
  `axi0_r2_static_request_idle_or_releasing`.

`.426` should preserve one-/two-/three-static mixed read recapture behavior,
two-dynamic-plus-one-static write recapture behavior, two-dynamic-plus-one-
static read burst-last no-recapture behavior, read-data/raw-`ARLEN`/
runtime-validation/multi-beat consumers, direct backend behavior, VHDL, and
full-manager behavior.

## Deferred Boundaries

Direct implementation of the selected two-dynamic-plus-one-static read
recapture contract, burst-last read recapture for the same cardinality,
layered recapture-specific consumer changes, static-busy-only recapture
outside selected public mixed samples, request arbitration beyond onehot0,
dynamic same-ID queues, scoreboards, queued/blocking policy, profile aliases,
direct backend behavior, backend-language variants, VHDL, and full AXI manager
behavior remain later exact owners.

## Validation

`.425` is docs-only. Closeout validation is:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
mdbook build docs/book
scripts/check_doctrines.sh
```

No behavior-bearing command is required beyond the baseline direct probes
recorded above.

## Rollback

Rollback is the `.425` readiness-audit commit. Reverting it restores `.425`
as the active audit leaf and removes `.426` as the selected contract-selection
owner.
