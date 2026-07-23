# IAL2 AHB Paired BUSY Composition Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.794`

Date: 2026-07-23

## Outcome

FSMGen ships one bounded generic AHB aggregate that pairs the existing
single-BUSY requester with the existing HBURST-aware byte-lane subordinate
whose burst context parks across BUSY:

```text
ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif
```

It lowers through the existing review chain:

```text
IAL2 source
  -> amba_requester_busy_insert.isf
   + ahb_lite_subordinate_byte_lane_hburst_seq.isf
   + ahb_interconnect.isf
  -> amba_requester_busy_insert.fsm
   + ahb_lite_subordinate_byte_lane_hburst_seq.fsm
   + ahb_interconnect.fsm
   + ahb_tb.fsm
  -> SystemVerilog module ahb_tb
```

The first paired slice is one requester, one subordinate, one zero-base
four-byte window, one 32-bit register, byte-only `INCR4`, and one BUSY
presentation before beat index two. It does not add an `.ahb` alias or a
two-subordinate sibling.

## Source And Report Contract

The requester declares `(busy 2'b01)` and `(busy-before-beat 2)`. The
subordinate declares `(seq-policy hburst-in-word-progressive)`,
`(ignored-transfer idle)`, and `(parked-transfer busy)`.

Schedule/report JSON keeps the existing aggregate schema. Its requester child
conditionally receives the standalone endpoint's complete `busy_insertion`
block:

```text
children[0].busy_insertion.generated_behavior   = true
children[0].busy_insertion.htrans_busy_encoding = 2'b01
children[0].busy_insertion.before_beat          = 2
children[0].busy_insertion.beats                 = single
```

The subordinate child and
`composition.seq_policy_propagation.subordinates[0]` retain
`parks_on = [busy]`. Those two child-owned facts are the canonical paired
report: requester `busy_insertion` says what is presented, while subordinate
`parks_on` says how it is consumed. There is no duplicate top-level
`busy_flow` block. Aggregates whose requester has no `busy_insertion` field
remain structurally unchanged.

## Generated Phase Behavior

The generated-HDL proof exposed two prerequisite defects in the reused AHB
endpoint path, and `.794` corrects them within the AHB family:

- The requester presents the request bus before entering its beat loop, waits
  one clock after driving `NONSEQ`/`SEQ`, and repeats the same transfer while
  `HREADY` is low. It evaluates `HRESP` and advances address/data/counters only
  after the data phase completes.
- The subordinate owns one admitted active transfer with
  `ahb_access_active_q`. A priority `ahb_access_admit` rule claims a selected
  `NONSEQ`/`SEQ` transfer and immediately lowers `HREADYOUT`; the transaction
  samples that transfer once. `ahb_access_release` releases the ownership at
  an unselected, `IDLE`, or `BUSY` boundary, preventing a held transfer from
  being admitted twice.
- `ahb_seq_idle_clear` is a concurrent rule, not a competing auxiliary
  transaction. This lets the shared transaction scheduler start the real AHB
  access while still clearing continuation history on the selected boundary.
- Runtime `wait_cycles` is implemented as a width-safe counted repetition of
  one-cycle waits. A zero count bypasses the wait body; nonzero counts retain
  the sampled delay without the former dynamic-wait literal-width warning.

The selected requester emits an `IDLE` or BUSY boundary between completed
active transfers, so this ownership contract covers the shipped aggregate.
True pipelined/back-to-back active transfers without such a boundary are not
claimed; proposed tree `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT` owns that
separate runtime audit.

The generated interconnect uses HDL-safe instance name `fabric`, and a
zero-base window emits only `HADDR < limit` rather than the unsigned tautology
`HADDR >= 0`. Nonzero-base windows keep both bounds. These corrections make
the paired public source clean under `--verify-hdl`. Proposed tree
`PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT` owns the separate audit
of other composition generators that may still use reserved identifiers.

## Runtime Proof

`t/1513-ial2-ahb-paired-busy-composition.t` generates `ahb_tb`, builds it with
Verilator, and drives one byte `INCR4` write:

```text
cmd_addr       = 0
cmd_burst      = 3'b011
cmd_len        = 4
cmd_size       = 0
cmd_write      = 1
wait_cycles    = 0
cmd_wdata      = 32'h11111111
cmd_wdata_step = 32'h11111111
```

The harness observes:

```text
NONSEQ(0) -> SEQ(1) -> BUSY(2 held) -> SEQ(2 resumed) -> SEQ(3)
```

It proves one BUSY presentation, four data beats, held requester fields and
counters across BUSY, held subordinate continuation state and storage across
BUSY, clean resumed `SEQ`, OKAY completion, no error/retry/split, zero
remaining beats, and final little-endian register value `32'h44332211`.

## Support And Commands

```text
support id:
  intent.ppif_ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park
coverage:
  ial2_ppif_ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park_pipeline_cli
source kind:   ppif
HDL module:    ahb_tb
child count:   3
semantic root: top
```

This slice moves the corpus to 311 protocol fixtures and 352
supported-smoke/strict entries.

```bash
./bin/fsmgen --quiet --strict --check --json \
  ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --strict --verify-hdl \
  ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif
```

## Explicit Deferrals

The matching `.ahb` alias now ships as the byte-identical profile surface
documented in
`docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md`. A
two-subordinate paired sibling, policy/runtime or multi-BUSY insertion, a
distinct local bus-BUSY status, true pipelined active
transfer admission, halfword/word burst `SEQ`, wider or indefinite bursts,
multi-word/register-bank behavior, optional AHB signals, broader AHB manager
behavior, direct backend, verification-output generation, backend-language
variants, AXI/APB behavior changes, and VHDL remain deferred.
