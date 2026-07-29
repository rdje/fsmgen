# IAL2 AHB Two-Subordinate Exact-Two Paired BUSY Composition Behavior

Task-tree owner:
`IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.8`

Date: 2026-07-24

## Outcome

FSMGen ships the topology-first AHB IAL2 source through both public containers:

```text
ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb
```

It pairs the existing exact-two BUSY-inserting requester with the existing
two-window status/control interconnect and two HBURST-aware byte-lane
subordinates whose burst contexts park across BUSY. This is a new declarative
IAL2 composition over existing requester, subordinate, interconnect, and top
generators; it is not a new parser, generator, report schema, semantic model,
or MCP API. The files are byte-identical; `.ahb` is the matching profile alias
over the same model.

The topology-first spelling keeps `two_subordinate` (fabric topology) separate
from `requester_busy_insert_two` (requester BUSY cardinality).

## Lowering And Report Contract

The normal `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` path produces four IAL1
artifacts:

```text
amba_requester_busy_insert_two.isf
ahb_status_subordinate_byte_lane_hburst_seq.isf
ahb_control_subordinate_byte_lane_hburst_seq.isf
ahb_interconnect.isf
```

and five IAL0 artifacts:

```text
amba_requester_busy_insert_two.fsm
ahb_status_subordinate_byte_lane_hburst_seq.fsm
ahb_control_subordinate_byte_lane_hburst_seq.fsm
ahb_interconnect.fsm
ahb_tb.fsm
```

The schedule keeps schema
`fsmgen.ial2.protocol_intent.ahb_interconnect.v1`, module `ahb_tb`, semantic
root `top`, four children, 29 top signals, status window `[0,4)`, control
window `[4,8)`, and retained `one_hot_accepted_subordinate` data-phase response
ownership. The requester reports numeric `busy_before_beat=2` and
`busy_insertion.beats=2`. Both subordinate children and both propagated
subordinate policies report `parks_on=[busy]`. The top adds no duplicate
`busy_flow` summary.

```text
support id:
  intent.ppif_ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park
coverage:
  ial2_ppif_ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park_pipeline_cli
source kind:   ppif
HDL module:    ahb_tb
child count:   4
semantic root: top
```

The generic source established the 319/360/43 checkpoint. Its matching alias
established the 320 protocol-fixture / 361 supported-smoke-plus-strict / 44 AHB
IAL2-path checkpoint: twenty-two generic `.ppif` sources and twenty-two `.ahb`
aliases. The later exact-three requester alias established 322/363/46; the
generic exact-three paired source established 323/364/47, and its matching
alias established 324/365/48. The generic two-subordinate exact-three paired
source now moves current accounting to 325/366/49 split 25 `.ppif` / 24 `.ahb`.

## Deep Semantic Introspection And MCP

The public source participates in every existing introspection surface:

```bash
./bin/fsmgen --quiet --strict --check --json \
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json \
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
```

The real MCP tool `fsmgen_semantic_introspect` exposes the same normalized
semantic report and support identity from a workspace-relative source path.
Its provenance remains `read_only=true` and `shell_access=false`. FSMGen's
deep semantic introspection is an ongoing language-wide capability: new
support-accounted semantics must preserve check, schedule, normalized
semantic JSON, and MCP parity through this stable adapter. Feature-specific
MCP methods and raw private parser/lowering payloads are not introduced. The
same rule is locked for the matching alias in
`IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md`.

## Generated-HDL Proof

Focused `t/1525-ial2-ahb-two-subordinate-exact-two-paired-busy-composition.t`
locks the source delta, report, strict support, schedule, normalized semantic
JSON, real MCP call, exact review artifacts, outdir generation,
`--verify-hdl`, and generated-HDL runtime.

The runtime issues one byte `INCR4` write through each window and proves:

- two commands, ten transfers, and eight completed data beats;
- exactly two qualified BUSY events per command and four total;
- one resumed pending `SEQ` per command and two total;
- requester remaining-count progression from two through one to zero;
- stable selected and unselected subordinate continuation, phase, and storage;
- stable retained response-owner bits and no BUSY data-beat completion;
- clean completion with status storage `32'h44332211`; and
- clean completion with control storage `32'h88776655`.

The aggregate retains the established `--no-assert` boundary because the
unchanged interconnect default/decode selector overlap has a separate proposed
owner. Standalone exact-two requester `t/1521` remains assertion-enabled.

Focused
`t/1526-ial2-ahb-two-subordinate-exact-two-paired-busy-composition-profile-alias.t`
proves byte identity, strict/schedule/artifact/HDL parity, normalized semantic
JSON, and real read-only MCP parity without compiling a second simulation.
t1525 remains the shared runtime proof.

## Use It

```bash
./bin/fsmgen --quiet --strict \
  --outdir generated/ial2-ahb-two-subordinate-exact-two \
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --strict --verify-hdl \
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
```

## Explicit Deferrals

The generic exact-three requester, matching `.ahb` alias, and generic
one-subordinate exact-three paired composition now ship separately. Its
matching alias and the generic two-subordinate exact-three form also ship;
only the two-subordinate exact-three matching alias, counts above three,
multiple insertion points, runtime-selected policy, distinct local bus-BUSY status,
broader bursts and optional signals, deeper queues, multiple outstanding
transfers, broader managers/fabrics, direct backends,
verification-output generation, backend variants, other protocol changes,
VHDL, and decision 0020's transaction-layer horizon remain deferred/inactive.

The original two-window aggregate shipped with `--no-assert` while separate
interconnect and generated-subordinate selector gaps remained. Both repairs
now ship, and `t/1525` runs with requester, fabric, both endpoints, and all
internal selector assertions enabled. See
`IAL2_AHB_SUBORDINATE_DEFAULT_PHASE_OUTPUT_ARBITRATION_BEHAVIOR.md`.

## Rollback

The original `.8` rollback removes the generic source, one support entry,
t1525 and its harness. The later `.811` rollback is documented in the alias
behavior record and removes only the alias/support/t1526 surface. Neither
rollback changes existing generators, the normalized semantic/MCP API, or
lower layers.
