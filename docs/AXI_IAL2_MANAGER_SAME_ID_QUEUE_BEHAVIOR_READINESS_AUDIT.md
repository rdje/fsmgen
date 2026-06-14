# AXI IAL2 Manager Same-ID Queue Behavior Readiness Audit

Task-tree owner:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.104`.

Date: `2026-06-14`.

## Purpose

This audit checks whether FSMGen can move from selected-not-generated AXI
same-ID queue-head response-demux metadata to generated same-ID queue state and
queue-head demux behavior.

It follows:

- `.98`, admitted per-transaction request pulses for selected
  `issue-order-queue` families.
- `.101`, compact one-hot transaction slots for future same-ID queue state.
- `.102`, the public/report contract that reuses existing `response-demux`
  read/write family arms for concrete same-ID queue-head demux.
- `.103`, selected-not-generated parser/report metadata and static validation
  for that contract.

## Evidence Read

The audit read the current generator paths for same-ID ordering, admitted
request pulses, ID/response validation, response-demux rules, read-data
matching, assertion generation, IAL1 storage/rule/pulse/assertion lowering, and
the public same-ID/response-demux PPIF samples.

The `.103` sample probe:

```bash
env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_same_id_queue_head_response_demux.ppif
```

confirms the selected queue-head metadata:

- `bounded_read_rid_queue_head_demux_contract`
- `implementation_status: selected_not_generated`
- `transaction_completion_source: generated_queue_head_demux`
- `queue_state_representation: compact_onehot_transaction_slots`
- duplicate concrete ID `3` queue group for read transactions `r0` and `r1`
- `accepted_same_id_reuse: false`
- `generated_queue_behavior: false`

The generated IAL1 for that sample still treats `axi0_r0_complete` and
`axi0_r1_complete` as authored inputs. It emits admitted request pulse storage
and rules, but it does not emit queue state, response-demux rules, generated
completion outputs, or queue dequeue behavior.

The existing generated burst-last read response-demux sample:

```bash
env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif
```

confirms that the current lower layers can already carry response-event,
`RID`, `RLAST`, generated completion pulse outputs, guarded demux rules, and
response-demux assertions for the auto-ID lifecycle case.

## Readiness Finding

No new IAL1, IAL0, or SystemVerilog substrate prerequisite is evident for the
first bounded generated same-ID queue behavior. The existing path can express:

- scalar state variables with reset values
- one-cycle pulse actions
- guarded rules
- generated inputs and outputs
- Boolean and equality guards
- static-width constants
- generated assertions

However, direct broad implementation is still too large for a signoff slice.
Queue state and queue-head demux are behavior-coupled:

- queue state needs an exact dequeue event from queue-head demux
- queue-head demux needs queue-head transaction identity from queue state
- accepted same-ID reuse must not become true until both sides ship together
  for the covered group
- transaction completion ownership must move from authored completion inputs
  to generated completion pulse outputs only within a fully specified behavior
  boundary

Shipping queue storage without generated queue-head demux would create a queue
that cannot safely dequeue. Shipping queue-head demux without queue state would
not know which same-ID transaction is at the head. Shipping both for every
read/write/scope/depth form in one step would be too broad.

## Decision

The next owner is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.105`, first generated AXI same-ID queue
state and queue-head behavior slice selection.

That selector must pin down the exact first behavior boundary before code
changes, including:

- whether the first generated behavior is read-only, write-only, or both
- whether the first read scope is `burst-last`, `single-beat`, or both
- the supported queue depth and duplicate concrete-ID group shape
- the compact one-hot slot update table for enqueue, dequeue, and same-cycle
  enqueue/dequeue
- generated storage names and reset values
- generated response-event, response-ID, and last-signal inputs
- generated transaction completion output ownership
- the internal queue dequeue pulse/event
- completion fan-in changes for capacity accounting and auto-release
- generated assertion names and diagnostics
- exact report fields and residue movement
- validation gates and rollback boundary

Until that selector completes, `.103` remains the runtime truth:
selected-not-generated metadata is available, but generated queue state,
queue-head demux rules, accepted same-ID reuse, generated queue behavior,
direct backend lowering, and VHDL behavior are deferred.

## Generated Artifact Expectations

The later behavior owner should still preserve the normal reviewable lowering
chain:

```text
IAL2 -> generated .isf -> generated .fsm -> SystemVerilog
```

Generated queue state and demux behavior should appear first in generated IAL1
review artifacts, then in generated IAL0, then in HDL. Direct IAL2-to-HDL
behavior is out of scope.

## Validation

This audit is documentation-only. The required validation is:

- live schedule probes for the `.103` same-ID queue-head sample, the existing
  generated burst-last read response-demux sample, and the existing same-ID
  issue-order queue policy sample
- Knowledge Map regeneration and check
- mdBook build
- docs relative-path audit
- memory architecture check
- diff hygiene
- stale frontier scan
- validation-process monitor

## Rollback

Rollback is documentation-only: revert this note and the `.104` continuity
updates. No runtime code, tests, samples, support accounting, generated
artifacts, or HDL behavior changed in this slice.
