# IAL2 AHB Two-Subordinate Exact-Two Paired BUSY Composition `.ahb` Profile Alias Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.811`

Date: 2026-07-24

## Outcome

FSMGen ships the topology-first two-subordinate exact-two paired BUSY
composition through both public IAL2 source containers:

```text
ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb
```

The files are byte-identical. The `.ahb` suffix is a profile-alias view of the
same IAL2 model, not a separate parser, generator, semantic model, MCP method,
or direct HDL route.

## Preserved Lowering And Composition

Both sources use the existing four-child architecture and lower through the
same review artifacts:

```text
IAL1:
  amba_requester_busy_insert_two.isf
  ahb_status_subordinate_byte_lane_hburst_seq.isf
  ahb_control_subordinate_byte_lane_hburst_seq.isf
  ahb_interconnect.isf

IAL0:
  amba_requester_busy_insert_two.fsm
  ahb_status_subordinate_byte_lane_hburst_seq.fsm
  ahb_control_subordinate_byte_lane_hburst_seq.fsm
  ahb_interconnect.fsm
  ahb_tb.fsm

HDL module: ahb_tb
```

The schedule and normalized semantic report preserve:

- schema `fsmgen.ial2.protocol_intent.ahb_interconnect.v1`;
- semantic root `top`, four children, and 29 top signals;
- requester `busy_insertion.before_beat=2` and numeric `beats=2`;
- status window `[0,4)` and control window `[4,8)`;
- `parks_on=[busy]` for both subordinate children and both propagated policies;
- retained `one_hot_accepted_subordinate` response ownership; and
- no duplicate top-level `busy_flow` summary.

Existing suffix-keyed cleanup removes only
`ahb_profile_alias_deferred`, `ahb_aggregate_profile_alias_deferred`,
`ahb_subordinate_profile_alias_deferred`, and alias-exposure wording from the
`.ahb` report. The generic `.ppif` report retains that source-surface residue.
No adapter or generator algorithm changed.

## Support And Deep Semantic Introspection

```text
support id:
  intent.ahb_profile_alias_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park
coverage:
  ial2_ahb_profile_alias_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park_pipeline_cli
source kind:     ial2_profile_alias
classification: supported_smoke
strict:          supported
semantic root:   top
child count:     4
HDL module:      ahb_tb
```

This additive alias moves current accounting to 320 protocol fixtures, 361
supported-smoke plus strict fixtures, and 44 AHB IAL2 paths, evenly split
between twenty-two `.ppif` sources and twenty-two `.ahb` aliases.

Strict check, schedule JSON, normalized semantic JSON, and the real read-only
`fsmgen_semantic_introspect` MCP tool expose the same support identity, module,
semantic root, and four-child composition. MCP provenance remains
`read_only=true` and `shell_access=false`.

This is an ongoing language-wide contract: every new support-accounted
semantic feature must extend the normalized semantic surface and preserve MCP
parity. FSMGen does not add one-off feature MCP methods or expose private
parser/lowering payloads.

## Run It

```bash
./bin/fsmgen --quiet --strict --check --json \
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json \
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb
./bin/fsmgen --quiet --strict --verify-hdl \
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb
```

Focused
`t/1526-ial2-ahb-two-subordinate-exact-two-paired-busy-composition-profile-alias.t`
proves byte identity, parse/report/artifact parity, strict check, schedule JSON,
normalized semantic JSON, the real read-only MCP adapter, exact outdir review
artifacts, HDL verification, malformed-alias diagnostics, and preservation of
the generic, one-subordinate exact-two, two-subordinate exact-one, and base
aggregate identities. It passed four subtests in 726 seconds under the 4-GiB
descendant-RSS guard.

The alias test deliberately compiles no second simulation. Shared generated-HDL
runtime `t/1525` already proves two commands, four qualified BUSY events, two
resumed pending `SEQ` events, eight data beats, and final status/control storage
`32'h44332211`/`32'h88776655`.

## Explicit Deferrals

BUSY counts beyond two, multiple insertion points, runtime-selected policy,
distinct local bus-BUSY status, broader bursts and optional signals, deeper
queues, multiple outstanding transfers, broader managers/fabrics, selector
repair, direct backends, verification-output generation, backend variants,
other protocol changes, VHDL, and decision 0020's transaction-layer horizon
remain deferred/inactive.

## Rollback

Rollback removes only the additive `.ahb` source, support/language/capability/
test entries, and alias behavior/fact documentation; restores 319/360/43; and
leaves the generic source, existing generators, normalized semantic/MCP API,
lower layers, and shared t1525 runtime unchanged.
