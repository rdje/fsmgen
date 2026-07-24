# IAL2 AHB Direct Subordinate Pipelined Active-Transfer Contract Selection

Task-tree owner: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.5`

Date: 2026-07-23

## Outcome

The selected repair for the direct lower-layer
`fsm/ahb_lite_subordinate.fsm` seed is atomic completion-edge capture and
state dispatch through its existing phase registers. On a successful or final-
ERROR ready edge, a selected accepted `NONSEQ` must replace the completed
phase's address/control and enter `ACCESS`; an accepted `SEQ` must retain the
fixture's unsupported policy by entering `UNSUPPORTED`. An unselected, `IDLE`,
or `BUSY` presentation returns to `IDLE` and captures nothing.

This direct-state shape does not need the generated family's pending bank or a
new queue. The current state completes at the same edge that accepts the next
address phase, so nonblocking updates of the existing `addr_q`, `write_q`,
`size_q`, and `wait_ctr` registers become the next data phase's state
immediately after the edge. State selection itself retains the only HTRANS
distinction used by this seed: NONSEQ routes to `ACCESS`, SEQ routes to
`UNSUPPORTED`.

The implementation owner is `.6`. `.5` changes no seed, support identity,
artifact, port, generated HDL, runtime behavior, generated IAL2 role, backend,
AXI/APB/VHDL behavior, or decision `0020`.

## Evidence Reconciled

t/1520 proves two loss paths in the current direct seed:

| Completion edge | Bus acceptances | Internal captures/completions | Result |
| --- | ---: | ---: | --- |
| successful word write plus active NONSEQ read | 2 | 1 / 1 | only first write remains, `0x11111111` |
| final ERROR plus active NONSEQ write | 2 | 1 / 1 | exactly two ERROR cycles, continuation absent, storage zero |

`ACCESS` and `ERROR_COMPLETE` drive ready high and return to `IDLE` without
inspecting HSEL/HADDR/HTRANS. The following `IDLE` cycle is too late to sample:
the accepted manager may already retire or replace the phase.

The generated-family `.2` contract and `.3` repair establish the common bus
ownership rule: every selected ready active address phase is retained exactly
once, HWDATA is data-phase state, and final ERROR plus active captures while
final ERROR plus IDLE cancels. The direct seed uses the same external rule but
a smaller internal realization because it has no generated transaction tail,
HBURST history, or paired interconnect owner.

## Selected Completion Dispatcher

At each successful `ACCESS` completion and in `ERROR_COMPLETE`, the next-state
decision is equivalent to:

```text
if HSEL && HREADY && HTRANS == NONSEQ:
    addr_q   <= HADDR
    write_q  <= HWRITE
    size_q   <= HSIZE
    wait_ctr <= wait_cycles
    next_state = ACCESS
else if HSEL && HREADY && HTRANS == SEQ:
    wait_ctr <= wait_cycles
    next_state = UNSUPPORTED
else:
    next_state = IDLE
```

The implementation may factor this authored decision tree to avoid duplicated
text, but it must preserve those exact observable branches. NONSEQ captures
the same fields as direct admission from `IDLE`. SEQ preserves the existing
minimal unsupported path, which needs only the wait count before its two-cycle
ERROR. No new externally visible signal or report is selected.

### Successful completion

The current read/write effect uses the old `addr_q`, `write_q`, `size_q`, and
current data-phase HWDATA combinationally before the rising edge. At that same
edge, the dispatcher may load the next NONSEQ control into the registers and
keep/enter `ACCESS`. The following cycle is the accepted phase's data phase.

If its sampled `wait_cycles` is zero, the existing direct policy may present
ready immediately for that data phase and complete it at the next edge. A
nonzero count preserves the existing not-ready counted wait. Thus the repair
does not add an artificial bubble or change direct admission latency.

### Final ERROR

The existing first ERROR cycle remains in `ACCESS` or `UNSUPPORTED` with
`HREADYOUT=0`, so no address acceptance occurs there. `ERROR_COMPLETE` remains
the final `HREADYOUT=1`, `HRESP=1` cycle. At its edge:

- selected active NONSEQ captures and enters `ACCESS`;
- selected active SEQ enters `UNSUPPORTED` for an independent later ERROR;
- IDLE, BUSY, or unselected input captures nothing and enters `IDLE`.

After the edge, `ACCESS` or `UNSUPPORTED` restores the response output to the
new phase's policy. The prior ERROR remains exactly two cycles.

## HWDATA Ownership

HWDATA is never copied during address/control capture. On a successful current
write completion edge it still belongs to that current write, even if the edge
accepts the next write address. The manager presents the next write's HWDATA
after the edge and holds it through any ready-low cycles. The existing
`ACCESS` write effect consumes that live value only on the next write's own
successful completion.

This ordering prevents the accepted next write from overwriting current data
or consuming the previous write's data.

## Exactly-Once And Capacity Boundary

While `ACCESS` or `UNSUPPORTED` drives ready low, a held active phase is not
accepted. The first ready completion edge captures it once and dispatches the
state once. With zero waits, each data phase may complete while the bus accepts
the next address phase, which is the normal one-address/one-data overlap; there
is still no outstanding queue beyond the phase currently represented by the
direct registers/state.

Each bus acceptance must therefore produce exactly one later direct-state
completion and at most one storage effect. `.6` must convert t/1520 to require:

```text
successful continuation:
  bus_accepts=2, internal_captures=2, internal_completions=2
  second read completes, storage remains 0x11111111

ERROR continuation:
  bus_accepts=2, internal_captures=2, internal_completions=2
  first response has exactly two ERROR cycles
  captured NONSEQ write later stores 0xaaaaaaaa
```

## Preservation And Implementation Boundary

`.6` may edit only the direct seed, t/1520/harness expectations, current direct-
seed docs/book/facts, task/Memory, and directly affected validation evidence.
It must preserve:

- `protocol.ahb_lite_subordinate`, `fsm/ahb_lite_subordinate.fsm`, module and
  port identity, four-state source shape unless a state change is strictly
  necessary, and strict/support accounting;
- selected word-only NONSEQ behavior, unsupported SEQ/size/address handling,
  wait-cycle counting, reset, idle defaults, read/write effects, and two-cycle
  ERROR;
- the generated public IAL2 `.3` phase bank, requester/interconnect
  prerequisites, reports, sources, aliases, and paired runtimes; and
- requester direct seeds, general queues/outstanding transfers, broader AHB,
  AXI/APB/VHDL, and proposed decision `0020` inactivity.

Focused validation must include direct strict/check/HDL generation, repaired
t/1520 success and ERROR cases, generated t/1519 preservation, direct support
accounting/capability checks, current-doc truth, mdBook, Knowledge Map, memory,
paths, diff, and doctrine gates under the 4-GiB descendant cap where heavy.

## Rollback

Rollback removes this selection record/fact and restores `.5` to pending; it
does not change the proven defect. A later `.6` rollback must restore the seed
and t/1520 together, return the current docs to audit-only truth, and must not
leave a ready edge that advertises acceptance without phase retention.
