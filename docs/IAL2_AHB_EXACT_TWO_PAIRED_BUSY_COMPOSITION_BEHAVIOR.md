# IAL2 AHB Exact-Two Paired BUSY Composition Behavior

Task-tree owner:
`IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.3`

Date: 2026-07-24

## Outcome

FSMGen ships one additive generic AHB aggregate that pairs the existing
exact-two BUSY-inserting requester with the existing HBURST-aware byte-lane
subordinate whose burst context parks across BUSY:

```text
ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
```

This is source-data composition through the existing generators, not a new
parser or generator. Its review path is:

```text
IAL2 source
  -> amba_requester_busy_insert_two.isf
   + ahb_lite_subordinate_byte_lane_hburst_seq.isf
   + ahb_interconnect.isf
  -> amba_requester_busy_insert_two.fsm
   + ahb_lite_subordinate_byte_lane_hburst_seq.fsm
   + ahb_interconnect.fsm
   + ahb_tb.fsm
  -> SystemVerilog module ahb_tb
```

The bounded shape remains one requester, one subordinate, one zero-base
four-byte window, one 32-bit register, byte-only `INCR4`, and one BUSY episode
before beat index two. The episode contains exactly two grant-and-ready-
qualified BUSY events.

## Source, Report, And Support Contract

The requester declares `(busy-before-beat 2)` and `(busy-beats 2)`. The
subordinate declares `(seq-policy hburst-in-word-progressive)` and
`(parked-transfer busy)`.

The existing aggregate schedule schema remains
`fsmgen.ial2.protocol_intent.ahb_interconnect.v1` with three children and
semantic root `top`. The requester child reports:

```text
children[0].busy_insertion.generated_behavior   = true
children[0].busy_insertion.htrans_busy_encoding = 2'b01
children[0].busy_insertion.before_beat          = 2
children[0].busy_insertion.beats                = 2
```

The subordinate child and propagated composition policy both report
`parks_on=[busy]`. The top intentionally adds no duplicate `busy_flow` block.
The base-requester aggregate remains structurally unchanged.

```text
support id:
  intent.ppif_ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park
coverage:
  ial2_ppif_ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park_pipeline_cli
source kind:   ppif
HDL module:    ahb_tb
child count:   3
semantic root: top
```

This source moves the corpus to 317 protocol fixtures and 358
supported-smoke/strict fixtures. The public AHB IAL2 inventory is 41 paths:
twenty-one generic `.ppif` sources and twenty `.ahb` aliases.

## Semantic Introspection And MCP

The source participates in the same bounded semantic contract as every other
support-accounted source:

```bash
./bin/fsmgen --quiet --strict --check --json \
  ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json \
  ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
```

The read-only MCP tool `fsmgen_semantic_introspect` exposes that normalized
semantic result, including aggregate module/root and support identity. Its
adapter provenance remains `read_only=true` and `shell_access=false`. No
feature-specific MCP method and no raw private parser/lowering payload were
added. New support-accounted semantics are expected to preserve this
check/schedule/normalized-semantic/read-only-MCP parity as the language grows.

## Generated-HDL Proof

Focused `t/1523-ial2-ahb-exact-two-paired-busy-composition.t` checks the source,
report, generated artifacts, strict support accounting, schedule JSON,
normalized semantic JSON, the real read-only MCP adapter, review artifacts,
`--verify-hdl`, and generated-HDL behavior.

The runtime drives one byte `INCR4` write and proves:

- one contiguous BUSY transition episode;
- exactly two `HGRANT && HREADY && HTRANS == BUSY` events;
- requester address/control/data/beat fields remain stable throughout BUSY;
- `ahb_busy_remaining_q` progresses from two to one to zero;
- subordinate continuation, accepted phase, and storage remain stable;
- interconnect one-hot data ownership remains stable;
- neither BUSY event completes a data beat;
- the same pending `SEQ` resumes exactly once;
- four byte data beats complete with clean status; and
- final storage is `32'h44332211`.

The aggregate retains the established `--no-assert` boundary because the
unchanged interconnect still has a separately tracked default/decode selector
overlap. Standalone exact-two requester `t/1521` remains assertion-enabled.

## Use It

```bash
./bin/fsmgen --quiet --strict --outdir generated/ial2-ahb-exact-two-paired \
  ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --strict --verify-hdl \
  ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
```

## Explicit Deferrals

Follow-on `.4` selects the matching exact-two paired `.ahb` alias contract for
proposed `.5`, but the alias does not ship yet. The two-subordinate exact-two
pairing, counts beyond two, multiple insertion points, runtime-selected
count/point, policy/random throttling, distinct local bus-BUSY status,
halfword/word or wider/indefinite burst expansion, broader optional AHB
signals, deeper queues, multiple outstanding transfers, broader managers or
fabrics, direct backends, verification-output generation, backend variants,
AXI/APB changes, VHDL, the separate selector repair, and decision 0020 remain
deferred/inactive.

## Rollback

Rollback removes the additive source, support entry, focused test/harness, and
current-surface documentation together; restores 316/357/40 accounting; and
leaves the existing exact-two requester, exact-one paired families, generators,
semantic/MCP API, and all lower layers unchanged.
