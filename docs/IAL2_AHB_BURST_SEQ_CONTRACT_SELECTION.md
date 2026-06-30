# IAL2 AHB Burst SEQ Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.751`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.751` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.752`, direct implementation of the first
bounded public AHB subordinate-side `SEQ` continuation contract.

The selected implementation is additive and generic `.ppif` only. Existing
word-only and byte-lane subordinate sources and `.ahb` aliases must remain
unchanged:

```text
ppif/ahb_lite_subordinate.ppif
ppif/ahb_lite_subordinate.ahb
ppif/ahb_lite_subordinate_byte_lane.ppif
ppif/ahb_lite_subordinate_byte_lane.ahb
```

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability manifest, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI behavior, APB behavior, broader AHB behavior, or
VHDL behavior.

## Selected Public Source

The selected public source path for `.752` is:

```text
ppif/ahb_lite_subordinate_byte_lane_seq.ppif
```

The selected support identity is:

```text
entry_id: intent.ppif_ahb_lite_subordinate_byte_lane_seq
coverage: ial2_ppif_ahb_lite_subordinate_byte_lane_seq_pipeline_cli
source_kind: ppif
module_name: ahb_lite_subordinate_byte_lane_seq
```

The selected source shape is:

```text
(protocol-platform-intent ahb_lite_subordinate_byte_lane_seq
  (profile ahb)
  (source
    (object fsmgen-ahb-lite-subordinate-byte-lane-seq)
    (anchor
      (document ARM-AMBA-AHB-IHI0033-C-2021-09)
      (section bounded-ahb-lite-subordinate-byte-lane-seq)
      (page first-public-contract)))
  (ahb-subordinate ahb_lite_subordinate_byte_lane_seq
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
      (write-data HWDATA width 32)
      (ready-out HREADYOUT)
      (response HRESP width 1)
      (read-data HRDATA width 32))
    (storage
      (register reg0
        (address 0 width 32)
        (data reg_data_q width 32 reset 0)))
    (transfer ahb_lite_byte_lane_seq_access
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
      (seq-policy in-word-progressive)
      (unaligned-access error)
      (crossing-access error)
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

The first `SEQ` slice does not make `(supported-transfer ...)` repeatable and
does not replace the existing scalar `supported-transfer nonseq` field. That
preserves current report compatibility for existing sources and keeps the
first source change explicit.

`(seq-policy in-word-progressive)` is the selected additive clause. It is
valid only when the transfer already selects the shipped byte/halfword/word
narrow-transfer policy and `supported-transfer nonseq`. Malformed sources must
fail closed when:

- `seq-policy` has any value other than `in-word-progressive`;
- `seq-policy` appears without the selected byte/halfword/word size policy;
- `seq-policy` appears with a non-`nonseq` `supported-transfer` value;
- `seq-policy` appears more than once; or
- a `.ahb` alias attempts to use this source before a later alias owner ships
  it.

## Selected SEQ Semantics

The selected behavior stays inside one 32-bit register word. `NONSEQ` keeps
the already shipped byte-lane behavior. `SEQ` can complete with OKAY only when
all of these conditions hold:

- the previous accepted active transfer completed successfully;
- the previous accepted active transfer was `NONSEQ`, or a previously accepted
  `SEQ` that was itself valid under this policy;
- the previous accepted transfer size was byte or halfword;
- the current `SEQ` uses the same `HWRITE` direction and `HSIZE`;
- the current address equals the stored expected next address;
- the expected next address remains inside the selected 32-bit storage word;
  and
- the normal byte-lane address/alignment rule for the current size holds.

The selected address progression is:

```text
byte:     expected_next = previous_addr + 1
halfword: expected_next = previous_addr + 2
```

The selected OKAY examples are:

```text
NONSEQ byte     at HADDR 0 -> SEQ byte     at HADDR 1
NONSEQ byte     at HADDR 1 -> SEQ byte     at HADDR 2
NONSEQ byte     at HADDR 2 -> SEQ byte     at HADDR 3
NONSEQ halfword at HADDR 0 -> SEQ halfword at HADDR 2
```

After the final in-word byte or halfword continuation, a further `SEQ` crosses
the selected word and returns ERROR. A new `NONSEQ` starts a new independent
access and resets the selected continuation history.

Successful `SEQ` reads and writes reuse the existing byte-lane read/write
policy:

- writes update active lanes and preserve inactive storage lanes;
- reads drive active stored lanes and zero-fill inactive `HRDATA` lanes;
- wait-cycle handling, OKAY completion, and no-write-on-ERROR behavior match
  the existing byte-lane source.

## Fail-Closed Shapes

The selected first contract returns the existing two-cycle ERROR response for:

- standalone `SEQ` without a valid prior accepted active transfer;
- `SEQ` after `IDLE` or `BUSY`;
- `SEQ` after an ERROR transfer;
- `SEQ` after a successful word transfer;
- byte or halfword `SEQ` whose expected next address crosses the selected
  32-bit storage word;
- `SEQ` with changed `HWRITE` direction;
- `SEQ` with changed `HSIZE`;
- `SEQ` with unexpected address progression;
- unsupported sizes;
- unmapped, unaligned, or crossing accesses; and
- any `HBURST` length, wrapping, or multi-word/register-bank behavior beyond
  this in-word progression policy.

`IDLE` and `BUSY` remain ignored with zero-wait OKAY defaults and clear the
selected continuation history. The first slice does not model BUSY-as-burst
parking.

## Generated Review Contract

The selected generated review artifacts are:

```text
ahb_lite_subordinate_byte_lane_seq.isf
ahb_lite_subordinate_byte_lane_seq.fsm
```

The implementation must make the generated IAL1/FSM review text prove:

- the new source no longer routes all `SEQ` transfers unconditionally to
  ERROR;
- `SEQ` OKAY completion is guarded by stored continuation state;
- expected-address, size, and write/read direction checks are present;
- byte and halfword in-word `SEQ` reads/writes use the existing narrow-transfer
  lane policy;
- standalone, crossing, changed-control, and word `SEQ` cases route to ERROR;
  and
- existing word-only and byte-lane sources still route `SEQ` to ERROR.

## Report Contract

The report schema remains:

```text
fsmgen.ial2.protocol_intent.ahb_subordinate.v1
```

Existing source reports must remain compatible. In particular, existing
word-only and byte-lane reports keep:

```text
transfer.supported_transfer = nonseq
```

For the new selected source, the report must add:

```text
transfer.seq_policy.selected = true
transfer.seq_policy.mode = in_word_progressive
transfer.seq_policy.requires_prior_transfer = prior_okay_nonseq_or_seq
transfer.seq_policy.supported_sizes = [byte, halfword]
transfer.seq_policy.address_progression = previous_address_plus_size_bytes
transfer.seq_policy.control_stability = [HWRITE, HSIZE]
transfer.seq_policy.clears_on = [reset, idle, busy, error, new_nonseq]
```

The new source keeps `narrow_transfer_policy` as selected by the byte-lane
source. It must also narrow, not remove, `ahb_burst_seq_support_deferred`.
The narrowed residue must state that HBURST-driven length/wrap validation,
BUSY continuation inside bursts, multi-word/register-bank bursts, aggregate
propagation, `.ahb` alias exposure, full-manager behavior, direct backend,
verification-output generation, backend-language variants, AXI/APB behavior,
broader AHB behavior, and VHDL remain future work.

Existing word-only, existing byte-lane, endpoint `.ahb` aliases, aggregate
`.ppif` sources, aggregate `.ahb` aliases, and aggregate child reports keep
their current `SEQ` residue until later exact owners select propagation.

## Selected `.752` Scope

`.752` owns direct implementation of exactly this contract:

- add `ppif/ahb_lite_subordinate_byte_lane_seq.ppif`;
- add parser support for `(seq-policy in-word-progressive)` only on the
  selected byte-lane subordinate transfer shape;
- add generator/report support for the selected bounded in-word `SEQ`
  continuation policy;
- add the support-accounting and language-surface entries for the new generic
  `.ppif` source;
- add focused coverage in a new test, expected to be
  `t/1486-ial2-ahb-subordinate-byte-lane-seq.t`;
- add preservation checks for existing word-only `.ppif/.ahb`, byte-lane
  `.ppif/.ahb`, requester, and aggregate behavior as needed;
- update behavior docs, mdBook AHB/backlog, README, ROADMAP_V2, Knowledge Map,
  task tree, and Memory; and
- run focused syntax/probe/tests plus doctrine closeout.

`.752` must not add a matching `.ahb` alias, aggregate embedding/propagation,
HBURST forwarding to subordinates, HBURST length/wrap validation,
multi-word/register-bank behavior, optional/property-gated AHB signals, legacy
two-bit subordinate `HRESP`, broader interconnect/decode, scoreboards,
full-manager behavior, direct backend behavior, verification-output
generation, backend-language variants, AXI/APB behavior, broader AHB behavior,
or VHDL behavior.

## Validation

Closeout for `.751` is documentation-only:

```bash
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
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
