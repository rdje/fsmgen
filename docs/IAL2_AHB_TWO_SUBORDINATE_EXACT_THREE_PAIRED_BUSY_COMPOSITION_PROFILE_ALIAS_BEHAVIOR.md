# IAL2 AHB Two-Subordinate Exact-Three Paired BUSY Composition `.ahb` Profile Alias Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.821`

Date: 2026-07-29

## Outcome

FSMGen ships two-window exact-three paired BUSY composition through both public
IAL2 source containers:

```text
ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif
ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ahb
```

The files are byte-identical. The `.ahb` suffix is a vocabulary/profile alias
of the same IAL2 model, not another parser, generator, semantic model, MCP
method, runtime, or direct HDL route.

## Preserved Lowering And Composition

Both sources lower through the same four-child architecture and review
artifacts:

```text
IAL1:
  amba_requester_busy_insert_three.isf
  ahb_status_subordinate_byte_lane_hburst_seq.isf
  ahb_control_subordinate_byte_lane_hburst_seq.isf
  ahb_interconnect.isf

IAL0:
  amba_requester_busy_insert_three.fsm
  ahb_status_subordinate_byte_lane_hburst_seq.fsm
  ahb_control_subordinate_byte_lane_hburst_seq.fsm
  ahb_interconnect.fsm
  ahb_tb.fsm

HDL module: ahb_tb
```

The schedule and normalized semantic report preserve:

- schema `fsmgen.ial2.protocol_intent.ahb_interconnect.v1`;
- semantic root `top`, four children, and 29 top signals;
- requester `busy_insertion.before_beat=2`, numeric `beats=3`, and width-two
  `3 -> 2 -> 1 -> 0` retirement;
- status `[0,4)` and control `[4,8)` windows;
- `parks_on=[busy]` for both subordinate children and both propagated policies;
- retained `one_hot_accepted_subordinate` response ownership; and
- no duplicate top-level `busy_flow` summary.

Existing suffix handling removes only `ahb_profile_alias_deferred`,
`ahb_aggregate_profile_alias_deferred`,
`ahb_subordinate_profile_alias_deferred`, and alias-exposure wording from the
`.ahb` report. The generic `.ppif` keeps that source-surface residue. No
adapter, generator, report, or semantic algorithm changed.

## Support And Semantic Introspection

```text
support id:
  intent.ahb_profile_alias_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park
coverage:
  ial2_ahb_profile_alias_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park_pipeline_cli
source kind:     ial2_profile_alias
classification: supported_smoke
strict:          supported
semantic root:   top
child count:     4
HDL module:      ahb_tb
```

This alias established 326 protocol fixtures, 367 supported-smoke plus strict
fixtures, and 50 AHB IAL2 paths. The generic exact-four requester established
327/368/51 and its matching alias established 328/369/52. The later exact-four
paired generic/profile pair moves current accounting to 330/371/54 split 27
`.ppif` sources / 27 `.ahb` aliases.

Strict check, schedule JSON, normalized semantic JSON, and real read-only
`fsmgen_semantic_introspect` expose the same support identity, module, semantic
root, and four-child composition. MCP provenance remains `read_only=true` and
`shell_access=false`; no feature-specific MCP method or private lowering
payload is introduced.

## Run It

```bash
./bin/fsmgen --quiet --strict --check --json \
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ahb
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json \
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ahb
./bin/fsmgen --quiet --strict --verify-hdl \
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ahb
```

Focused
`t/1534-ial2-ahb-two-subordinate-exact-three-paired-busy-composition-profile-alias.t`
proves byte identity, parse/report/residue parity, strict check, schedule JSON,
normalized semantic JSON, real read-only MCP, exact repository-local review
artifacts, HDL verification, targeted diagnostics, and preservation of the
generic source plus adjacent two-window exact-two, one-window exact-three, and
base aggregate aliases. It passes 4 top-level / 97 nested assertions in 870
seconds under the canonical host-100/process-4096 verification profile.

t1534 deliberately compiles no second simulation. Shared assertion-enabled
t1533 remains authoritative for exact two commands / ten presentations / eight
accepted beats / two BUSY episodes / six qualified BUSY events / two resumed
`SEQ` events / status `44332211` / control `88776655` behavior.

Verilator supplies event-capable compiled simulation for this supported
`--timing` subset. It is not a full-language SystemVerilog/UVM event-driven
authority; that remains a separate proposed HIAL/VIAL simulator profile.

## Explicit Deferrals

The exact-four requester and one-window paired generic/profile families now
ship. The two-window exact-four topology, counts above four, multiple insertion
points, runtime/policy/random insertion, distinct bus-BUSY status, broader bursts and
optional signals, queues/outstanding transfers, broader managers/fabrics,
generic priority changes, direct backends, verification generation, backend
variants, other protocols, VHDL, HIAL/VIAL activation, and decision `0020`
remain separate.

## Rollback

Remove the additive `.ahb` source, support/language/capability/test entries,
and alias behavior/fact documentation; restore 325/366/49 split 25/24. The
generic source, existing generators, semantic/MCP API, lower layers, and shared
t1533 runtime remain unchanged.
