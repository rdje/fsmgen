# IAL2 AHB Exact-Four Paired BUSY Composition Behavior

Task-tree owner:
`IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.3`

Date: 2026-07-30

## Outcome

FSMGen ships one additive generic AHB aggregate:

```text
ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif
```

It pairs the existing exact-four BUSY-inserting requester with the existing
HBURST-aware byte-lane subordinate whose burst context parks across BUSY. The
bounded topology remains one requester, one subordinate, one zero-base
four-byte window, one 32-bit register, byte-only `INCR4`, and one BUSY episode
before beat index two. The episode contains exactly four grant-and-ready-
qualified BUSY events.

This is a data-only composition through existing generators:

```text
IAL2 source
  -> amba_requester_busy_insert_four.isf
   + ahb_lite_subordinate_byte_lane_hburst_seq.isf
   + ahb_interconnect.isf
  -> amba_requester_busy_insert_four.fsm
   + ahb_lite_subordinate_byte_lane_hburst_seq.fsm
   + ahb_interconnect.fsm
   + ahb_tb.fsm
  -> SystemVerilog module ahb_tb
```

No parser, generator algorithm, report schema, semantic/MCP API, simulator
integration, or existing source bytes changed.

## Source, Report, And Support Contract

The requester declares `(busy-before-beat 2)` and `(busy-beats 4)`. The
subordinate declares `(seq-policy hburst-in-word-progressive)` and
`(parked-transfer busy)`.

The existing aggregate schedule schema remains
`fsmgen.ial2.protocol_intent.ahb_interconnect.v1` with three children and
semantic root `top`. The requester child reports numeric `before_beat=2` and
`beats=4`; its width-three `ahb_busy_remaining_q` retires
`4 -> 3 -> 2 -> 1 -> 0`. The subordinate child and propagated composition
policy both report `parks_on=[busy]`. The top intentionally adds no duplicate
`busy_flow` block. One-hot accepted-subordinate response ownership and
completion-edge owner replacement remain unchanged.

```text
support id:
  intent.ppif_ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park
coverage:
  ial2_ppif_ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park_pipeline_cli
source kind:   ppif
class/strict:  supported_smoke / true
HDL module:    ahb_tb
child count:   3
semantic root: top
```

This source moves current accounting to 329 protocol fixtures, 370
supported-smoke and strict-supported fixtures, and 53 AHB IAL2 paths split
between 27 generic `.ppif` sources and 26 `.ahb` aliases.

## Semantic Introspection And Runtime Proof

Focused `t/1537-ial2-ahb-exact-four-paired-busy-composition.t` proves source
identity, strict support, schedule JSON, exact three IAL1 and four IAL0 review
artifacts, normalized semantic JSON, real repo-relative read-only MCP, public
`--verify-hdl`, and assertion-enabled generated HDL. MCP provenance remains
`read_only=true` and `shell_access=false`.

Verilator 5.046 compiles with `--timing`, `-j 1`, and all generated selector
assertions enabled. Runtime proves:

- five transfer presentations and four completed byte data beats;
- one contiguous BUSY episode with exactly four qualified BUSY events;
- internal requester retirement `4 -> 3 -> 2 -> 1 -> 0`;
- stable requester address/control/data/beat ownership during BUSY;
- stable subordinate continuation, phase, and storage during BUSY;
- stable one-hot fabric data ownership and no BUSY data completion;
- exactly one resumed pending `SEQ`, clean final status, and
  `storage=32'h44332211`.

The test creates all lowering and Verilator workspaces beneath the
repository-derived `.artifacts/tmp/tests` directory and removes each exact
temporary tree on completion.

## Use It

```bash
scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- \
  ./bin/fsmgen --quiet --strict --check --json \
  ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif

scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- \
  ./bin/fsmgen --quiet --strict --verify-hdl \
  ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif
```

## Explicit Deferrals

The matching `.ahb` alias, two-subordinate exact-four topology, counts above
four, multiple insertion points, runtime-selected or random policy, distinct
local bus-BUSY status, broader bursts/signals/managers/fabrics, other
protocols/backends, VHDL, VIAL verification generation, HIAL/VIAL activation,
large-design scale implementation, and decision-0020 behavior remain separate
task-tree-owned work.

Clean behavior commit `c42347a5e` activates parent selector
`IAL2-FEATURE-COMPLETENESS-FRONTIER.824` without changing this shipped
boundary. The selector must choose one next owner before any alias,
two-subordinate, broader-AHB, HIAL/VIAL, verification, portability, priority,
or scale behavior changes.

Completed selector `.824` chooses active `.825`, activated only after clean
selector commit `5b601fffc`, for the byte-identical matching `.ahb` alias with
projected 330/371/54 accounting split 27/27. Future
t1538 owns alias parity without a second simulation; t1537 remains this
generic/profile pair's shared assertion-enabled runtime. See
`docs/IAL2_POST_EXACT_FOUR_PAIRED_COMPOSITION_NEXT_OWNER_SELECTION.md`.

## Rollback

Rollback removes only the generic source, its support entry, t1537 and its
testbench, this behavior record/fact, and corresponding current-accounting
references. Accounting returns to 328 protocol fixtures, 369 supported-smoke
and strict-supported fixtures, and 52 AHB paths split 26 `.ppif` / 26 `.ahb`.
Existing generators, exact-four requester behavior, exact-three paired
behavior, semantic/MCP APIs, and simulator profiles remain unchanged.
