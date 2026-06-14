# AXI IAL2 Manager Post Same-ID Queue Behavior Next Slice Selection

Task-tree owner:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.107`.

Date: `2026-06-15`.

## Purpose

This selector audits the next AXI same-ID issue-order queue expansion after
`.106` shipped the first generated behavior boundary for the public read
burst-last queue-head sample.

This slice is documentation and task-tree state only. It does not change
parser, generator, tests, samples, support accounting, generated artifacts, or
HDL behavior.

## Evidence Read

The audit read the `.106` implementation, `.105` selector, `.104` readiness
audit, current generator/report/test code, public PPIF samples, live schedule
reports, generated HDL text, README, roadmap, mdBook, task tree, Memory, and
Knowledge Map facts.

Current generated behavior is deliberately narrow. The generator only builds
same-ID queue behavior when the response-demux family is `read`, the read
scope is `burst_last`, there is exactly one duplicate concrete read-ID group,
the group has exactly two transactions, computed depth is `2`, and there is no
same-family auto-ID lifecycle or read-data consumption.

The write queue-head public/report contract is already selected by `.102` and
normalized by `.103` as:

```text
bounded_write_bid_queue_head_demux_contract
```

but it still reports selected-not-generated behavior. Existing generated
auto-ID write `BID` response-demux behavior is a different path: it matches
`BID` against per-transaction allocated IDs and busy state. Concrete same-ID
write queue-head behavior instead needs queue state and a concrete-ID
queue-head match.

## Live Report And Artifact Findings

The current public read queue-head sample:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_same_id_queue_head_response_demux.ppif
```

now reports generated response demux, generated same-ID ordering,
`accepted_same_id_reuse: true`, and `generated_queue_behavior: true` for the
covered read burst-last depth-2 group only.

The generated HDL for that sample exposes compact one-hot read queue slots,
finite queue transition enable nets, generated `axi0_r0_complete` /
`axi0_r1_complete` pulse outputs, `RID`/`RLAST`-gated queue-head demux, and the
queue integrity assertions selected by `.105`.

The existing write response-demux sample:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif
```

continues to prove the generated auto-ID write `BID` demux path, but it does
not exercise concrete same-ID queue-head state. The existing single-beat read
demux and multi-beat read-data samples also remain separate auto-ID paths.

## Selected Next Slice

The next owner is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.108
```

`.108` should implement generated AXI same-ID **write** queue-head behavior for
one bounded public sample shape:

- write family only;
- one duplicate concrete write-ID group;
- two write transactions in that group;
- computed queue depth exactly `2`;
- compact one-hot transaction-slot state;
- `response-demux.write.transaction-completion generated`;
- no same-family `auto-id-lifecycle`;
- no read queue-head behavior expansion in the same slice.

The expected generated queue-head write match for transaction `w0` is:

```text
axi0_write_complete
&& axi0_bid == 4'd3
&& axi0_write_id3_same_id_issue_order_slot0_w0_q
```

The `w1` match uses the `slot0_w1` head bit. The matching generated rule
pulses the selected transaction completion:

```lisp
(rule axi0_w0_response_demux
  (& axi0_write_complete (== axi0_bid 4'd3)
     axi0_write_id3_same_id_issue_order_slot0_w0_q)
  (pulse axi0_w0_complete))
```

The write queue update table should reuse the `.105` finite depth-2
enqueue/dequeue/same-cycle transition semantics with write admitted request
pulses and write queue-head response matches. It must not introduce arrays,
dynamic indexed left-hand sides, pointer arithmetic, hidden unbounded queues,
direct-backend-only behavior, or generalized per-ID queues.

## Why Write Before Other Expansions

Write queue-head behavior is the smallest useful expansion after `.106`:

- it exercises the existing selected write queue-head contract;
- it checks that the generated queue behavior can be family-local instead of
  read-only;
- it avoids `RLAST` and read-data coupling;
- it avoids deeper queues, multiple groups, mixed auto-ID arbitration, and
  generalized per-ID state;
- it preserves the already-shipped auto-ID write response-demux path as a
  separate behavior.

Read `single-beat` queue-head behavior is still useful, but selecting it first
would expand read-scope handling while staying inside the same read family.
The write slice provides better coverage of family factoring with less new
read-side payload/status risk.

## Report Expectations

For the covered write sample, `.108` may report:

```yaml
response_demux:
  write:
    mode: bounded_write_bid_queue_head_demux_contract
    generated_behavior: true
    implementation_status: generated
    transaction_completion_source: generated_queue_head_demux
    transaction_completion_semantics: matched_concrete_id_queue_head
    generated_queue_behavior: true
    generated_queue_behavior_boundary: generated_write_bid_queue_head_demux
```

The same-ID write policy may report:

```yaml
same_id_ordering:
  concrete_id_reuse_policy:
    write:
      enforcement: generated_issue_order_queue
      implementation_status: generated_write_bid_queue_head_demux
      accepted_same_id_reuse: true
      generated_queue_behavior: true
```

The generated write queue report should list concrete ID, depth, transaction
order, slot storage, admitted enqueue pulses, generated update rules, and
generated assertions. Response-demux residue may remove
`generated_same_id_queue_head_demux` only for the newly covered write sample
shape.

## Validation Gates For `.108`

The implementation slice must include:

- syntax checks for touched Perl modules and focused tests;
- focused generator coverage for write queue slot storage, write queue update
  rules, generated completion outputs, write queue-head demux rules,
  assertions, and report/residue movement;
- focused PPIF/CLI coverage for a new public write queue-head sample through
  schedule JSON, generated `.isf`, generated `.fsm`, default SystemVerilog,
  `--verify-hdl`, check JSON, and semantic JSON;
- regression checks proving the existing read burst-last queue-head sample,
  auto-ID write response demux, auto-ID read response demux, and multi-beat
  read-data samples keep their current behavior;
- fail-closed coverage proving read single-beat, deeper groups, multiple
  groups, same-family mixed auto-ID, read-data consumption of concrete
  queue-head demux, direct backend, and VHDL remain outside the slice;
- support-accounting, README, roadmap, mdBook, task tree, Memory, and
  Knowledge Map sync;
- process monitoring for long PPIF/HDL validation runs.

## Deferred Work

Still deferred after `.107` until separately owned:

- implementation of write queue-head behavior itself, now selected as `.108`;
- read `single-beat` concrete same-ID queue-head behavior;
- more than one duplicate concrete-ID group;
- queue groups deeper than two slots;
- same-family mixed auto-ID plus concrete queue-head demux;
- read-data consumption of concrete same-ID queue-head demux;
- different-ID interleaving beyond covered families;
- generalized per-ID issue-order queues;
- direct backend lowering;
- VHDL.

## Rollback

Rollback for this selector is documentation-only. The runtime rollback
baseline remains `.106`: generated read burst-last depth-2 queue-head behavior
for the public read sample, selected-not-generated write queue-head metadata,
and no write queue-head runtime behavior.
