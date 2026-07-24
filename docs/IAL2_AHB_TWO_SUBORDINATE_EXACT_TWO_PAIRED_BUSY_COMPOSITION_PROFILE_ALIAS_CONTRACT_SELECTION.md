# IAL2 AHB Two-Subordinate Exact-Two Paired BUSY `.ahb` Profile Alias Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.810`

Date: 2026-07-24

## Outcome

Select proposed `.811` direct data-only implementation of the matching AHB
profile alias:

```text
ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb
```

The alias must be byte-identical to the generic source shipped at clean commit
`a5b7fa236`:

```text
ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
```

It is a second public filename/suffix surface over the same IAL2 model and the
same requester, two subordinates, interconnect, and top generators. It is not
another generator, parser path, semantic model, MCP API, or direct IAL2-to-HDL
route. This selector changes no source, support catalog, test, generated
artifact, HDL/runtime behavior, protocol behavior, or transaction layer.

## Why This Is The Smallest Next Owner

The repository already uses a generic-then-alias cadence for the standalone
exact-two requester, the one-subordinate exact-two paired composition, and the
two-subordinate exact-one paired composition. Decision 0015 requires profile
extensions to remain vocabulary aliases over the same IAL2 model and layered
lowering chain.

The matching alias is smaller than counts beyond two, runtime BUSY policy,
distinct local bus-BUSY status, broader burst progression, optional signals,
manager/fabric widening, or a selector repair: those alternatives require new
behavioral contracts, while this alias requires only byte-identical source
data, support accounting, semantic/MCP parity, diagnostics, and documentation.

## Readiness Evidence

A disposable byte-identical copy of the shipped generic source was evaluated
with the reserved `.ahb` suffix. Strict check passed without diagnostics:

```text
success:      true
module:       ahb_tb
child count:  4
signal count: 29
support:      matched=false
```

Unmatched support is expected before the tracked alias and catalog entry
exist. Schedule JSON retained:

```text
schema: fsmgen.ial2.protocol_intent.ahb_interconnect.v1
semantic root: top

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

requester before_beat: 2
requester beats:       2
child parks_on:        [busy], [busy]
propagated parks_on:   [busy], [busy]
response owner:        one_hot_accepted_subordinate
windows:               status [0,4), control [4,8)
top busy_flow:         absent
```

Existing suffix handling removed only
`ahb_aggregate_profile_alias_deferred`, requester-child
`ahb_profile_alias_deferred`, both subordinate-child
`ahb_subordinate_profile_alias_deferred` instances, and alias-exposure
wording. It retained requester BUSY support, burst, optional-signal,
interconnect, manager, backend, verification-output, and other substantive
residue.

Normalized semantic JSON passed with module `ahb_tb`, source root `top`, four
children, and unmatched support. A real `fsmgen_semantic_introspect` call from
a disposable `/tmp` workspace returned the same normalized report with
`query_kind=semantic`, `read_only=true`, and `shell_access=false`. No parser,
generator, report, semantic, MCP, or artifact repair is required. The
disposable source was removed and no probe process remains.

## Selected `.811` Public Contract

```text
alias path:
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb

support id:
  intent.ahb_profile_alias_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park

coverage:
  ial2_ahb_profile_alias_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park_pipeline_cli

family:         protocol_fixture
classification: supported_smoke
source kind:    ial2_profile_alias
strict:         true
HDL module:     ahb_tb
child count:    4
semantic root:  top
```

One support-accounted alias moves current accounting from 319 protocol / 360
supported-smoke+strict / 43 AHB paths to 320/361/44. The AHB source inventory
becomes evenly split between twenty-two generic `.ppif` and twenty-two `.ahb`
profile aliases.

## Semantic And MCP Contract

Strict check, schedule JSON, normalized semantic JSON, and the real read-only
`fsmgen_semantic_introspect` adapter must expose the alias path, selected
support ID/coverage, source kind `ial2_profile_alias`, module `ahb_tb`, root
`top`, and four-child composition. MCP provenance remains `read_only=true` and
`shell_access=false`.

This is the continuing contract for all support-accounted semantic additions,
not an alias-specific API. `.811` must not introduce a feature-specific MCP
method or expose raw private parser/lowering objects.

## Selected Regression Contract

Focused
`t/1526-ial2-ahb-two-subordinate-exact-two-paired-busy-composition-profile-alias.t`
must prove:

- tracked alias existence and byte identity with the generic source;
- schedule/report/artifact equality except alias-only residue cleanup;
- strict check, exact support identity, and source kind;
- normalized semantic JSON and a real read-only MCP call;
- exact outdir review artifacts, HDL module identity, and `--verify-hdl`;
- numeric requester `before_beat=2` and `beats=2`;
- both child and propagated `parks_on=[busy]` policies;
- status/control windows and retained response ownership;
- absence of duplicate top `busy_flow`;
- malformed alias/profile diagnostics; and
- generic, one-subordinate exact-two, and two-subordinate exact-one
  preservation.

t1526 must not compile a second generated-HDL simulation. Byte identity makes
shipped t1525 the shared two-window runtime proof: two commands, four qualified
BUSY events, two resumed `SEQ` events, eight data beats, and final
`44332211`/`88776655` status/control storage.

## Preservation, Validation, And Rollback

Implementation must preserve t1525, t1524, t1516, standalone assertion-enabled
t1521, and existing generic/alias sources. Focused validation includes t1526,
t248, t297, t1518, syntax, mdBook, Knowledge Map, memory/path/diff/doctrine
gates, and guarded preservation as warranted under the 4-GiB cap.

`.811` must not modify PPIF/AHB generators, public syntax, report schemas, the
semantic/MCP API, generated behavior, ports, or runtime. Counts beyond two,
multiple insertion points, policy/runtime throttling, distinct bus-BUSY
status, broader bursts/signals/managers/queues/fabrics/backends, selector
repairs, AXI/APB/VHDL, verification-output generation, decision 0020, and its
transaction-layer horizon remain separate/inactive.

Selector rollback removes this record/fact and restores `.810` active.
Implementation rollback removes only the byte-identical alias, one support
entry, t1526, and current-surface docs; restores 319/360/43; and leaves the
generic source, t1525 runtime, generators, semantic/MCP API, and all lower
layers unchanged.
