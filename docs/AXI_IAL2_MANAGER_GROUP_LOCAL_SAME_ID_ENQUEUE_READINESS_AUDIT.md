# AXI IAL2 Manager Group-Local Same-ID Enqueue Readiness Audit

Status: readiness audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.209` on
2026-06-21.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.209`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.210`, counted admission/capacity
prerequisite audit before group-local simultaneous enqueue widening.

Directly replacing the current family-wide request mutual-exclusion assertion
with per-concrete-ID group mutual exclusion is not safe yet. The queue state
is already generated per concrete-ID group, but request admission and the
capacity/status pending counters still assume one accepted request per
direction per cycle.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation, generated artifact, test, or HDL behavior.

## Evidence Read

The audit read:

- `.208` selector:
  `docs/AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md`.
- `.207` mixed multi-beat behavior and `.206` readiness audit.
- Admitted enqueue and admitted request pulse notes:
  `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_ENQUEUE_BOUNDARY_AUDIT.md`
  and
  `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_REQUEST_PULSES_FIRST_SLICE.md`.
- Generated queue-head behavior notes for read/write multi-group, depth-3,
  multiple/mixed depth-3, and mixed auto-ID plus concrete queue-head families.
- Current generator code around
  `_build_same_id_admitted_request_boundary`,
  `_build_same_id_issue_order_queue_behavior`,
  `_same_id_issue_order_queue_transition_specs`,
  `_same_id_issue_order_queue_response_states_for_family`,
  `_direction_rules`, report/residue projection, and assertions.
- Focused generator and PPIF/CLI tests, public PPIF samples, support-accounting
  surfaces, README, `ROADMAP_V2.md`, mdBook, downstream integration spec,
  public interface contract, task tree, Memory, and Knowledge Map.

## Live Probe Findings

Compact schedule probes over representative shipped samples show the current
contract:

```text
ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif
  family=read boundary=generated_read_burst_last_queue_head_demux
  groups=3:r0/r1:d2,5:r2/r3:d2
  request_fanin=(| axi0_r0_request axi0_r1_request axi0_r2_request axi0_r3_request)
  selected_request_events=axi0_r0_request,axi0_r1_request,axi0_r2_request,axi0_r3_request
  admitted_assertions=axi0_read_issue_order_queue_request_onehot0
  queue_update_rules=24

ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif
  family=write boundary=generated_write_bid_queue_head_demux
  groups=3:w0/w1:d2,5:w2/w3:d2
  request_fanin=(| axi0_w0_request axi0_w1_request axi0_w2_request axi0_w3_request)
  selected_request_events=axi0_w0_request,axi0_w1_request,axi0_w2_request,axi0_w3_request
  admitted_assertions=axi0_write_issue_order_queue_request_onehot0
  queue_update_rules=24

ppif/axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_response_demux.ppif
  family=read boundary=generated_read_single_beat_queue_head_demux
  groups=3:r0/r1/r2:d3,5:r3/r4/r5:d3
  request_fanin=(| axi0_r0_request axi0_r1_request axi0_r2_request axi0_r3_request axi0_r4_request axi0_r5_request)
  selected_request_events=axi0_r0_request,axi0_r1_request,axi0_r2_request,axi0_r3_request,axi0_r4_request,axi0_r5_request
  admitted_assertions=axi0_read_issue_order_queue_request_onehot0
  queue_update_rules=108

ppif/axi_manager_capacity_status_write_mixed_depth3_depth2_same_id_queue_head_response_demux.ppif
  family=write boundary=generated_write_bid_queue_head_demux
  groups=3:w0/w1/w2:d3,5:w3/w4:d2
  request_fanin=(| axi0_w0_request axi0_w1_request axi0_w2_request axi0_w3_request axi0_w4_request)
  selected_request_events=axi0_w0_request,axi0_w1_request,axi0_w2_request,axi0_w3_request,axi0_w4_request
  admitted_assertions=axi0_write_issue_order_queue_request_onehot0
  queue_update_rules=66

ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_multi_beat_read_data.ppif
  family=read boundary=generated_read_burst_last_queue_head_demux
  groups=3:r1/r2:d2
  request_fanin=(| axi0_r0_request axi0_r1_request axi0_r2_request)
  selected_request_events=axi0_r1_request,axi0_r2_request
  admitted_assertions=axi0_read_issue_order_queue_request_onehot0
  queue_update_rules=12
```

Generated IAL1 for the read multi-group sample shows the same split. Each
admitted pulse guard reads only the scalar pending counter and the family
completion fan-in:

```lisp
(rule axi0_r0_admitted_request
  (& axi0_r0_request
     (| (< axi0_pending_reads_q 4)
        (| axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete)))
  (pulse axi0_r0_admitted_request_pulse_q))

(rule axi0_r2_admitted_request
  (& axi0_r2_request
     (| (< axi0_pending_reads_q 4)
        (| axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete)))
  (pulse axi0_r2_admitted_request_pulse_q))
```

Each queue group's transition rules exclude competing enqueues only inside
that concrete-ID group:

```lisp
(rule axi0_read_id3_same_id_issue_order_empty_enqueue_r0
  (... axi0_r0_admitted_request_pulse_q (! axi0_r1_admitted_request_pulse_q))
  (axi0_read_id3_same_id_issue_order_slot0_r0_q 1))

(rule axi0_read_id5_same_id_issue_order_empty_enqueue_r2
  (... axi0_r2_admitted_request_pulse_q (! axi0_r3_admitted_request_pulse_q))
  (axi0_read_id5_same_id_issue_order_slot0_r2_q 1))
```

The direction counter still sees only one Boolean submit fan-in:

```lisp
(rule read_submit_only_occ0
  (& (| axi0_r0_request axi0_r1_request axi0_r2_request axi0_r3_request)
     (! (| axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete))
     (== axi0_pending_reads_q 0))
  ...)
```

## Code Findings

`_build_same_id_admitted_request_boundary` builds one selected request list per
read or write family and, when the list has more than one request event, emits
one family-wide `*_issue_order_queue_request_onehot0` assertion. The generated
admitted-pulse guards use current pending storage, the family `max-pending`
bound, and family completion fan-in.

`_direction_rules` and `_rule_lines` still model submit as a Boolean. A
`submit_only` rule increments the pending counter by one, and a
`submit_complete` rule preserves or increments by one depending on occupancy.
They cannot represent two or more distinct admitted requests in the same
direction in one cycle.

`_same_id_issue_order_queue_transition_specs` already scopes transition
enumeration to a single concrete-ID group. It chooses either no enqueue or one
transaction from that group and excludes the other admitted pulses in the same
group. Separate groups are emitted as separate rule sets, so distinct-group
enqueue transitions are structurally separable once admission/capacity is
made safe.

`_same_id_issue_order_queue_response_states_for_family` already iterates all
generated groups in the selected family. Response-demux and read-data coverage
helpers can consume those response states after queue-head generation without
needing a new response-state model for distinct groups.

Focused tests currently assert the same family-wide request onehot names for
generated queue-head samples. That test contract must change only in the later
implementation slice that owns a counted admission model and group-local
request assertions.

## Audit Answers

The family-wide request onehot cannot safely become group-local in the next
behavior slice as-is. If the assertion were simply replaced, two requests for
different concrete-ID groups could both produce admitted pulses while the
direction pending counter increments only once.

Direction-level capacity accounting therefore needs a prerequisite. A future
implementation must define how many same-direction requests are admitted in a
cycle, reject or defer over-capacity combinations when there are fewer free
slots than distinct-group requests, and update pending/status outputs
consistently with the admitted count and same-cycle completion.

Queue transition generation does not appear to be the first blocker for
distinct concrete-ID groups. Existing generated transition rules are already
per group and only exclude multiple enqueues inside that group. Same-group
multi-enqueue should remain unsupported through group-local onehot assertions;
distinct-group enqueue should wait for counted admission/capacity ownership.

## Selected `.210` Prerequisite Audit

`.210` must audit counted same-direction admission/capacity semantics before
group-local same-ID enqueue behavior:

- decide whether the capacity/status rule matrix should gain counted request
  rules for selected same-ID queue-head families or a narrower generated
  same-ID-only admission layer;
- define the report fields that distinguish Boolean request fan-in from
  counted admitted requests;
- decide how `pending_reads`, `pending_writes`, `*_slots_available`,
  `*_full`, and `*_can_accept` behave when two or more distinct concrete-ID
  groups request in the same cycle;
- preserve current one-request-per-cycle behavior for all existing public
  samples;
- keep same-group simultaneous request events fail-closed or asserted by
  group-local mutual exclusion;
- record diagnostics, expected tests, public-contract impact, and validation
  gates for the later implementation.

No group-local enqueue behavior should ship before `.210` selects the exact
capacity/accounting implementation owner.

## Preservation Matrix

The later prerequisite and implementation slices must preserve:

- current generated queue-head behavior for read single-beat, read burst-last,
  and write families;
- depth-2 multi-group, depth-3, multiple/mixed depth-3, and mixed auto-ID plus
  concrete queue-head generated behavior;
- read-data, burst-length, runtime-validation, and multi-beat output-bank
  behavior built on generated queue-head completions;
- current support identities, strict check JSON, semantic JSON, and HDL for
  all public samples until the exact owning implementation intentionally
  updates expectations;
- current parser syntax and public PPIF sample set.

## Non-Goals

- Do not implement counted admission/capacity behavior in `.209`.
- Do not replace the family-wide request onehot in `.209`.
- Do not add public PPIF syntax or samples in `.209`.
- Do not change queue storage, response-demux, read-data, support accounting,
  direct backend, verification-output generation, VHDL, or backend-language
  variant behavior in `.209`.

## Validation Gates

This audit used compact schedule and generated-IAL1 probes. Commit gates for
`.209` are documentation and continuity gates:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

`.210` should add focused live probes and temporary `/tmp` mutations that
exercise simultaneous distinct-group request combinations, over-capacity
combinations, and same-group conflicts without changing public behavior in
the audit slice.

## Rollback Boundary

Rollback for `.209` is limited to this audit record, task-tree frontier
movement, Memory, README, roadmap, mdBook, and Knowledge Map/fact-card
updates. No parser, generator, public sample, support-accounting catalog,
generated artifact, test, validation, or HDL behavior is part of this slice.
