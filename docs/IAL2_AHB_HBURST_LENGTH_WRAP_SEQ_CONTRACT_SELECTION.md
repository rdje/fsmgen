# IAL2 AHB HBURST Length/Wrap SEQ Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.763`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.763` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.764`, direct implementation of the first
bounded endpoint-only AHB HBURST-aware byte-lane `SEQ` source family.

The selected source is additive and generic `.ppif` only. Existing endpoint
word-only, byte-lane, byte-lane in-word `SEQ`, `.ahb` aliases, and aggregate
sources must remain unchanged:

```text
ppif/ahb_lite_subordinate.ppif
ppif/ahb_lite_subordinate.ahb
ppif/ahb_lite_subordinate_byte_lane.ppif
ppif/ahb_lite_subordinate_byte_lane.ahb
ppif/ahb_lite_subordinate_byte_lane_seq.ppif
ppif/ahb_lite_subordinate_byte_lane_seq.ahb
ppif/ahb_interconnect_byte_lane_seq.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif
ppif/ahb_interconnect_byte_lane_seq.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb
```

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability manifest, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI/APB behavior, broader AHB behavior, or VHDL
behavior.

## Selected Public Source

The selected public source path for `.764` is:

```text
ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif
```

The selected support identity is:

```text
entry_id: intent.ppif_ahb_lite_subordinate_byte_lane_hburst_seq
coverage: ial2_ppif_ahb_lite_subordinate_byte_lane_hburst_seq_pipeline_cli
source_kind: ppif
module_name: ahb_lite_subordinate_byte_lane_hburst_seq
```

The selected generated review artifacts are:

```text
ahb_lite_subordinate_byte_lane_hburst_seq.isf
ahb_lite_subordinate_byte_lane_hburst_seq.fsm
```

The selected HDL entry module is:

```text
ahb_lite_subordinate_byte_lane_hburst_seq
```

The selected source shape is:

```text
(protocol-platform-intent ahb_lite_subordinate_byte_lane_hburst_seq
  (profile ahb)
  (source
    (object fsmgen-ahb-lite-subordinate-byte-lane-hburst-seq)
    (anchor
      (document ARM-AMBA-AHB-IHI0033-C-2021-09)
      (section bounded-ahb-lite-subordinate-byte-lane-hburst-seq)
      (page first-public-contract)))
  (ahb-subordinate ahb_lite_subordinate_byte_lane_hburst_seq
    (role subordinate)
    (clock clk)
    (reset (rst_n active_low async))
    (control
      (wait-cycles wait_cycles width 4))
    (bus
      (select HSEL)
      (ready-in HREADY)
      (address HADDR width 32)
      (transfer HTRANS width 2)
      (write HWRITE)
      (size HSIZE width 3)
      (burst HBURST width 3)
      (write-data HWDATA width 32)
      (ready-out HREADYOUT)
      (response HRESP width 1)
      (read-data HRDATA width 32))
    (storage
      (register reg0
        (address 0 width 32)
        (data reg_data_q width 32 reset 0)))
    (transfer ahb_lite_byte_lane_hburst_seq_access
      (accept-when (select 1) (ready-in 1))
      (idle 2'b00)
      (busy 2'b01)
      (nonseq 2'b10)
      (seq 2'b11)
      (supported-transfer nonseq)
      (supported-size byte)
      (supported-size halfword)
      (supported-size word)
      (lane-order little-endian)
      (narrow-write preserve-inactive-lanes)
      (narrow-read zero-fill-inactive-lanes)
      (unaligned-access error)
      (crossing-access error)
      (seq-policy hburst-in-word-progressive)
      (ignored-transfer idle)
      (ignored-transfer busy)
      (wait-cycles wait_cycles)
      (read register)
      (write register)
      (unmapped-address error)
      (unsupported-size error)
      (unsupported-transfer error)
      (response (okay 1'b0) (error 1'b1))
      (error-completion two-cycle))))
```

## Source Syntax Decision

The selected syntax keeps the existing scalar `supported-transfer nonseq`
contract and adds exactly two public extensions:

- `(burst HBURST width 3)` in the AHB subordinate `bus` block; and
- `(seq-policy hburst-in-word-progressive)` in the selected transfer block.

The policy is a new `seq-policy` mode, not a nested sub-policy. That keeps the
grammar aligned with the shipped `(seq-policy in-word-progressive)` form while
making the HBURST-aware behavior explicit.

Malformed sources must fail closed with targeted diagnostics when:

- a subordinate `(burst ...)` bus binding is present with width other than 3;
- `(seq-policy hburst-in-word-progressive)` appears without a subordinate
  `(burst ... width 3)` bus binding;
- `(seq-policy hburst-in-word-progressive)` appears without the selected
  byte/halfword/word byte-lane size policy;
- `(seq-policy hburst-in-word-progressive)` appears with any
  `supported-transfer` value other than `nonseq`;
- `seq-policy` appears more than once;
- `seq-policy` has any value other than `in-word-progressive` or
  `hburst-in-word-progressive`; or
- a `.ahb` alias attempts to use the new source before a later alias owner
  ships it.

Current-code probes confirmed the selected surface is not implemented yet:
the exact candidate with `(burst HBURST width 3)` fails at the subordinate bus
parser, while replacing only the existing policy with
`hburst-in-word-progressive` reaches the generator and fails at the current
`seq-policy` validator.

## Selected HBURST Semantics

The first HBURST-aware `SEQ` contract stays inside one 32-bit register word.
It supports `SEQ` OKAY only for byte-sized `INCR4` and `WRAP4` bursts. The
selected encodings match the existing AHB requester contract:

```text
SINGLE = 3'b000
INCR   = 3'b001
WRAP4  = 3'b010
INCR4  = 3'b011
WRAP8  = 3'b100
INCR8  = 3'b101
WRAP16 = 3'b110
INCR16 = 3'b111
```

`SINGLE` remains valid for independent `NONSEQ` byte/halfword/word accesses,
but it never arms `SEQ` history. `INCR4` and `WRAP4` arm byte-only HBURST
history. `INCR4` requires a word-aligned first byte address so the four-beat
incrementing burst stays within `reg0`. `WRAP4` may start on any byte lane and
wraps within the four-byte word window.

The selected OKAY examples are:

```text
INCR4 byte  NONSEQ HADDR 0 -> SEQ HADDR 1 -> SEQ HADDR 2 -> SEQ HADDR 3
WRAP4 byte  NONSEQ HADDR 0 -> SEQ HADDR 1 -> SEQ HADDR 2 -> SEQ HADDR 3
WRAP4 byte  NONSEQ HADDR 1 -> SEQ HADDR 2 -> SEQ HADDR 3 -> SEQ HADDR 0
WRAP4 byte  NONSEQ HADDR 2 -> SEQ HADDR 3 -> SEQ HADDR 0 -> SEQ HADDR 1
WRAP4 byte  NONSEQ HADDR 3 -> SEQ HADDR 0 -> SEQ HADDR 1 -> SEQ HADDR 2
```

Each successful byte beat uses the existing byte-lane narrow-transfer policy:
writes update only active lanes and reads drive active stored lanes while
zero-filling inactive `HRDATA` lanes. After the fourth accepted beat, the
source clears HBURST history; an extra `SEQ` returns the selected two-cycle
ERROR response.

## Fail-Closed Runtime Shapes

The selected source returns the existing two-cycle ERROR response and clears
HBURST/SEQ history for:

- standalone `SEQ` without valid armed HBURST history;
- `SEQ` after `SINGLE`;
- `SEQ` after `IDLE`, `BUSY`, reset, or ERROR;
- `SEQ` after a successful halfword or word transfer;
- changed `HBURST`, `HWRITE`, or `HSIZE` inside an armed sequence;
- unexpected `HADDR` progression;
- `INCR4` byte bursts whose first address is not word aligned;
- `INCR`, `WRAP8`, `INCR8`, `WRAP16`, and `INCR16`;
- `INCR4` or `WRAP4` with halfword or word size;
- unsupported sizes;
- unmapped, unaligned, or crossing accesses; and
- any multi-word/register-bank progression.

`IDLE` and `BUSY` stay ignored as transfers and clear HBURST/SEQ history.
BUSY-in-burst parking remains deferred.

## Report Contract

The report schema remains:

```text
fsmgen.ial2.protocol_intent.ahb_subordinate.v1
```

The new source must report the new bus binding under the existing bus binding
tree:

```text
bindings.bus.burst.name = HBURST
bindings.bus.burst.width = 3
```

The new source must report:

```text
transfer.seq_policy.selected = true
transfer.seq_policy.mode = hburst_in_word_progressive
transfer.seq_policy.base_policy = in_word_progressive
transfer.seq_policy.length_source = HBURST
transfer.seq_policy.requires_prior_transfer = prior_okay_hburst_nonseq_or_seq
transfer.seq_policy.supported_sizes = [byte]
transfer.seq_policy.supported_hburst_modes = [WRAP4, INCR4]
transfer.seq_policy.fail_closed_hburst_modes = [INCR, WRAP8, INCR8, WRAP16, INCR16]
transfer.seq_policy.single_policy = nonseq_only_no_seq_history
transfer.seq_policy.beats_per_burst = 4
transfer.seq_policy.window_bytes = 4
transfer.seq_policy.address_progression = hburst_incr4_or_wrap4_within_word
transfer.seq_policy.control_stability = [HBURST, HWRITE, HSIZE]
transfer.seq_policy.clears_on = [reset, idle, busy, error, new_nonseq, final_beat]
```

The new source keeps `narrow_transfer_policy` as selected by the byte-lane
source. Existing word-only, byte-lane, byte-lane in-word `SEQ`, endpoint
`.ahb` aliases, aggregate `.ppif` sources, aggregate `.ahb` aliases, and
aggregate child reports must keep their current report shapes.

The new source must narrow, not remove, `ahb_burst_seq_support_deferred`.
The remaining residue must name unsupported indefinite `INCR`, wider fixed
bursts, halfword/word burst `SEQ`, BUSY-in-burst parking, multi-word/register
bank progression, aggregate propagation, `.ahb` alias exposure, full-manager
behavior, direct backend, verification-output generation, backend-language
variants, AXI/APB behavior, broader AHB behavior, and VHDL.

For the new source only, `ahb_subordinate_optional_signal_residue` must no
longer list `HBURST` as fully deferred. Existing sources keep their current
optional-signal residue until exact owners change them.

## Generated Review Contract

`.764` must make the generated IAL1/FSM review text prove:

- `HBURST` is sampled into generated state with the active transfer;
- byte-only `INCR4` and `WRAP4` history is armed from accepted `NONSEQ`;
- a beat counter or equivalent state enforces exactly four beats;
- `WRAP4` wraps inside the four-byte register word;
- `INCR4` accepts only word-aligned first byte bursts;
- `HBURST`, `HWRITE`, and `HSIZE` remain stable inside a sequence;
- unsupported HBURST modes, halfword/word bursts, unexpected address, and
  extra `SEQ` after the final beat route to ERROR; and
- existing byte-lane in-word `SEQ` and non-SEQ sources remain preserved.

The selected generated IAL1 state names should be local to the new source and
may extend the existing `seq_*` pattern with HBURST-specific state such as
`seq_hburst_q`, `seq_beat_index_q`, or `seq_wrap_base_q`, as long as the
report and tests prove the selected semantics.

## Selected `.764` Scope

`.764` owns direct implementation of exactly this contract:

- add `ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif`;
- add subordinate bus parser support for `(burst HBURST width 3)`;
- add generator/report support for `(seq-policy hburst-in-word-progressive)`;
- add the support-accounting and language-surface entries for the new generic
  `.ppif` source;
- add focused coverage in `t/1490-ial2-ahb-subordinate-byte-lane-hburst-seq.t`;
- add preservation checks for existing word-only, byte-lane, byte-lane `SEQ`,
  `.ahb` alias, requester, and aggregate behavior as needed;
- update behavior docs, mdBook AHB/backlog, README, ROADMAP_V2, Knowledge Map,
  task tree, and Memory; and
- run focused syntax/probe/tests plus doctrine closeout.

`.764` must not add a matching `.ahb` alias, aggregate HBURST forwarding,
aggregate propagation, BUSY-in-burst parking, halfword/word/multi-word burst
`SEQ`, optional/property-gated AHB signals, legacy two-bit subordinate `HRESP`,
broader interconnect/decode, scoreboards, full-manager behavior, direct
backend behavior, verification-output generation, backend-language variants,
AXI/APB behavior, broader AHB behavior, or VHDL behavior.

## Validation

Closeout for `.763` is documentation-only plus current-state probes:

```bash
perl -Iperl -MFSM::Adapter::IAL2::PPIF -e '...candidate source with (burst HBURST width 3) and (seq-policy hburst-in-word-progressive) fail-closed probe...'
perl -Iperl -MFSM::Adapter::IAL2::PPIF -e '...candidate hburst-in-word-progressive policy without burst binding fail-closed probe...'
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

Broad or potentially heavyweight Perl, `prove`, or `fsmgen` commands remain
behind `scripts/run_with_ram_guard.sh` or equivalent monitoring.

## Rollback

Rollback is documentation-only: remove this contract-selection note, its
Knowledge Map fact card, task-tree advancement, README/ROADMAP_V2/mdBook sync,
Memory pointer update, and regenerated Knowledge Map entries. No runtime
behavior is affected.
