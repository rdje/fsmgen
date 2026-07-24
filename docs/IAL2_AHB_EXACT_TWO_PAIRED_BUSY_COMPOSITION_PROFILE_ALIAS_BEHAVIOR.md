# IAL2 AHB Exact-Two Paired BUSY Composition `.ahb` Profile Alias Behavior

Task-tree owner:
`IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.5`

Date: 2026-07-24

## Outcome

FSMGen ships the bounded one-subordinate exact-two paired BUSY composition
through both the generic IAL2 container and its matching AHB profile alias:

```text
ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb
```

The files are byte-identical. Both use the existing exact-two requester,
HBURST-aware byte-lane subordinate, interconnect, and composition-top
generators. The `.ahb` suffix is a second public source surface over the same
IAL2 model, not a separate parser, generator, language, or direct HDL route.

## Preserved Composition Contract

Both sources lower through the same review artifacts:

```text
IAL1:
  amba_requester_busy_insert_two.isf
  ahb_lite_subordinate_byte_lane_hburst_seq.isf
  ahb_interconnect.isf

IAL0:
  amba_requester_busy_insert_two.fsm
  ahb_lite_subordinate_byte_lane_hburst_seq.fsm
  ahb_interconnect.fsm
  ahb_tb.fsm

HDL module: ahb_tb
```

The report schema remains
`fsmgen.ial2.protocol_intent.ahb_interconnect.v1`. The three-child composition
keeps requester-child `busy_insertion.before_beat=2` and numeric
`busy_insertion.beats=2`, subordinate and propagated `parks_on=[busy]`, and no
duplicate top-level `busy_flow` block.

Existing suffix-keyed cleanup removes only
`ahb_profile_alias_deferred`, `ahb_aggregate_profile_alias_deferred`,
`ahb_subordinate_profile_alias_deferred`, and alias-exposure wording from the
`.ahb` report. The generic `.ppif` report keeps that residue. No adapter or
generator algorithm changed.

## Support And Semantic Introspection

```text
support id:
  intent.ahb_profile_alias_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park
coverage:
  ial2_ahb_profile_alias_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park_pipeline_cli
source kind:     ial2_profile_alias
classification: supported_smoke
strict:          supported
semantic root:   top
child count:     3
HDL module:      ahb_tb
```

The additive alias moves current accounting to 318 protocol fixtures and 359
supported-smoke/strict-supported fixtures. FSMGen now ships 42 bounded AHB
IAL2 paths, evenly split between twenty-one `.ppif` sources and twenty-one
`.ahb` aliases.

Strict check, schedule JSON, normalized semantic JSON, and the real read-only
`fsmgen_semantic_introspect` MCP tool expose the same alias support identity,
module, `top` semantic root, and three-child composition. MCP provenance stays
`read_only=true` and `shell_access=false`. This is the continuing rule for new
support-accounted semantic features: extend one normalized semantic surface
and preserve MCP parity, rather than adding feature-specific MCP methods or
exposing private parser/lowering payloads.

## Run It

```bash
./bin/fsmgen --quiet --strict --check --json \
  ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json \
  ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb
./bin/fsmgen --quiet --strict --outdir generated/ial2-ahb-exact-two-paired-alias \
  ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb
./bin/fsmgen --quiet --strict --verify-hdl \
  ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb
```

Focused t/1524 proves byte identity, parse/report/artifact parity, strict check,
schedule JSON, normalized semantic JSON, real read-only MCP introspection,
review artifacts, HDL module identity, `--verify-hdl`, malformed aliases, and
generic/exact-one/base preservation. It deliberately compiles no second
simulation. t/1523 remains the shared generated-HDL runtime proof: one BUSY
episode contains exactly two qualified BUSY events, the same pending `SEQ`
resumes once, four clean byte beats complete, and final storage is
`32'h44332211`.

## Explicit Deferrals

The two-subordinate exact-two pairing remains unshipped, although follow-on
readiness audit `.6` now proves it composes through the current four-child
architecture and selects separate public-contract work. BUSY counts beyond one/two, generalized
count width, multiple insertion points, runtime-selected counts/points,
policy/random throttling, distinct local bus-BUSY status, broader bursts and
optional signals, managers, queues/outstanding transfers, broader fabrics,
direct backends, verification-output generation, backend variants, AXI/APB
changes, VHDL, separate selector repairs, and decision 0020 remain
deferred/inactive.

## Rollback

Rollback removes only the additive `.ahb` source, support/language/capability/
test entries, and alias behavior/fact documentation; restores 317/358/41; and
leaves the generic exact-two paired source, existing generators, normalized
semantic/MCP API, and shared runtime behavior unchanged.
