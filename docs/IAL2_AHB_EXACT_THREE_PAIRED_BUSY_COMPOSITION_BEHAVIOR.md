# IAL2 AHB Exact-Three Paired BUSY Composition Behavior

Task-tree owner:
`IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.3`

Date: 2026-07-29

## Outcome

FSMGen ships one additive generic AHB aggregate and its byte-identical `.ahb`
profile alias. Both pair the existing exact-three BUSY-inserting requester
with the existing HBURST-aware byte-lane
subordinate whose burst context parks across BUSY:

```text
ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif
ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ahb
```

This is a data-only composition through the existing generators. It adds no
parser or generator algorithm. The review path is:

```text
IAL2 source
  -> amba_requester_busy_insert_three.isf
   + ahb_lite_subordinate_byte_lane_hburst_seq.isf
   + ahb_interconnect.isf
  -> amba_requester_busy_insert_three.fsm
   + ahb_lite_subordinate_byte_lane_hburst_seq.fsm
   + ahb_interconnect.fsm
   + ahb_tb.fsm
  -> SystemVerilog module ahb_tb
```

The bounded shape remains one requester, one subordinate, one zero-base
four-byte window, one 32-bit register, byte-only `INCR4`, and one BUSY episode
before beat index two. The episode contains exactly three grant-and-ready-
qualified BUSY events.

## Source, Report, And Support Contract

The requester declares `(busy-before-beat 2)` and `(busy-beats 3)`. The
subordinate declares `(seq-policy hburst-in-word-progressive)` and
`(parked-transfer busy)`.

The existing aggregate schedule schema remains
`fsmgen.ial2.protocol_intent.ahb_interconnect.v1` with three children and
semantic root `top`. The requester child reports:

```text
children[0].busy_insertion.generated_behavior   = true
children[0].busy_insertion.htrans_busy_encoding = 2'b01
children[0].busy_insertion.before_beat          = 2
children[0].busy_insertion.beats                = 3
```

The subordinate child and propagated composition policy both report
`parks_on=[busy]`. The top intentionally adds no duplicate `busy_flow` block.
One-hot accepted-subordinate response ownership and completion-edge owner
replacement remain unchanged.

```text
support id:
  intent.ppif_ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park
alias support id:
  intent.ahb_profile_alias_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park
coverage:
  ial2_ppif_ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park_pipeline_cli
alias coverage:
  ial2_ahb_profile_alias_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park_pipeline_cli
source kinds:  ppif / ial2_profile_alias
HDL module:    ahb_tb
child count:   3
semantic root: top
```

The alias moves current accounting to 324 protocol fixtures, 365
supported-smoke and strict-supported fixtures, and 48 AHB IAL2 paths split
evenly between 24 generic `.ppif` sources and 24 `.ahb` aliases.

## Semantic Introspection And MCP

The source participates in the common bounded semantic contract:

```bash
./bin/fsmgen --quiet --strict --check --json \
  ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json \
  ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif
```

The read-only MCP tool `fsmgen_semantic_introspect` exposes the same normalized
semantic result, aggregate module/root, and exact support identity. Adapter
provenance remains `read_only=true` and `shell_access=false`; no
feature-specific MCP method or private lowering payload was added.

## Generated-HDL Proof

Focused `t/1531-ial2-ahb-exact-three-paired-busy-composition.t` checks the
source identity, strict support accounting, schedule JSON, exact three IAL1
and four IAL0 review artifacts, normalized semantic JSON, real read-only MCP,
repository-local output, `--verify-hdl`, and assertion-enabled generated HDL.

The runtime drives one byte `INCR4` write and proves:

- one contiguous BUSY transition episode;
- exactly three `HGRANT && HREADY && HTRANS == BUSY` events;
- requester address, control, data, and beat fields remain stable throughout;
- `ahb_busy_remaining_q` progresses `3 -> 2 -> 1 -> 0`;
- subordinate continuation, accepted phase, and storage remain stable;
- interconnect one-hot data ownership remains stable;
- no BUSY event completes a data beat;
- the same pending `SEQ` resumes exactly once;
- four byte data beats complete with clean status; and
- final storage is `32'h44332211`.

Verilator compiles the generated requester, fabric, endpoint, and internal
selector assertions without `--no-assert`. Runtime totals are five transfer
presentations, four completed beats, one BUSY episode, three qualified BUSY
events, one resumed `SEQ`, and final storage `44332211`.

Focused
`t/1532-ial2-ahb-exact-three-paired-busy-composition-profile-alias.t`
proves that the `.ahb` source is byte-identical to the generic source and
retains parse/report, strict-check, schedule, exact-artifact, normalized
semantic, read-only shell-disabled MCP, repository-local output, and
`--verify-hdl` parity. It removes only the aggregate, requester, subordinate,
and alias-exposure residue selected by existing suffix handling. The alias
reuses t/1531 as its assertion-enabled runtime proof; no second testbench or
generator path was added.

## Use It

```bash
./bin/fsmgen --quiet --strict \
  --outdir generated/ial2-ahb-exact-three-paired \
  ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --strict --verify-hdl \
  ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --strict --verify-hdl \
  ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ahb
```

## Explicit Deferrals

Parent selector `.817` selected `.818`, which now ships the matching
byte-identical `.ahb` alias. Parent selector `.819` now assigns the
two-subordinate exact-three pairing to a separate readiness audit; it remains
unshipped until direct runtime evidence and a later contract pass. Counts
above three, generalized counter width,
multiple insertion points, runtime-selected or policy/random throttling,
distinct local bus-BUSY status, broader bursts/signals/managers/fabrics,
other protocols/backends, VHDL, VIAL verification generation, HIAL/VIAL
activation, and decision-0020 behavior remain separate.

See
[`IAL2_POST_EXACT_THREE_PAIRED_COMPOSITION_NEXT_OWNER_SELECTION`](IAL2_POST_EXACT_THREE_PAIRED_COMPOSITION_NEXT_OWNER_SELECTION.md).
See also
[`IAL2_POST_EXACT_THREE_PAIRED_ALIAS_NEXT_OWNER_SELECTION`](IAL2_POST_EXACT_THREE_PAIRED_ALIAS_NEXT_OWNER_SELECTION.md).

## Rollback

Rollback of `.818` removes only the `.ahb` mirror, its support entry, t/1532,
and alias-current documentation together; restores 323/364/47 accounting
split 24 `.ppif` / 23 `.ahb`; and leaves the generic exact-three paired
source, its t/1531 runtime proof, generators, semantic/MCP API, and all lower
layers unchanged.
