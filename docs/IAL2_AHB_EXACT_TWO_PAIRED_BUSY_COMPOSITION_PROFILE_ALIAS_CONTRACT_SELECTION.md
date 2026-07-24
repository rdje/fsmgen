# IAL2 AHB Exact-Two Paired BUSY Composition `.ahb` Profile Alias Contract Selection

Task-tree owner:
`IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.4`

Date: 2026-07-24

## Outcome

Select direct data-only implementation of the matching AHB profile alias:

```text
ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb
```

The alias must be a byte-identical mirror of the shipped generic source:

```text
ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
```

It is a second public source surface over the existing IAL2 model and existing
requester, subordinate, interconnect, and top generators. It is not another
generator, another language, or a direct IAL2-to-HDL path. Proposed `.5` owns
implementation after this selector commits cleanly.

This selection changes no source fixture, parser, generator, support catalog,
capability manifest, report, semantic/MCP API, generated artifact, HDL/runtime
behavior, backend, protocol, or transaction-layer behavior.

## Current Evidence

The selector reconciled the shipped generic exact-two paired source/behavior/
t1523, exact-one paired `.ppif`/`.ahb` precedent and t1514, standalone
exact-two requester alias precedent and t1522, `PPIF.pm` suffix handling,
support/language/capability surfaces, current docs, Memory, Knowledge Map, and
decision 0020.

Both shipped alias precedents are byte-identical to their generic siblings.
A disposable copy of the new generic source parsed using the reserved future
`.ahb` suffix and strict-checked successfully:

```text
success:     true
module:      ahb_tb
child count: 3
support:     matched=false (expected until the tracked alias/catalog entry exists)
```

Schedule JSON retained:

```text
schema: fsmgen.ial2.protocol_intent.ahb_interconnect.v1
intent: ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park
object: fsmgen-ahb-interconnect-requester-busy-insert-two-byte-lane-hburst-seq-busy-park

requester child busy_insertion:
  generated_behavior: true
  htrans_busy_encoding: 2'b01
  before_beat: 2
  beats: 2

subordinate parks_on: [busy]
propagated parks_on:  [busy]
top busy_flow:        absent
```

The future suffix removed `ahb_profile_alias_deferred`,
`ahb_aggregate_profile_alias_deferred`,
`ahb_subordinate_profile_alias_deferred`, and alias-exposure wording while
retaining all non-alias support residue. Normalized semantic JSON succeeded
with module `ahb_tb`, source root `top`, three semantic children, and unmatched
support accounting as expected. Generic and future-alias generated `.isf` and
`.fsm` review directories were byte-identical. No adapter or generator repair
is required. The disposable directory was removed after evidence capture.

## Selected Public And Support Identity

`.5` must add exactly:

```text
alias path:
  ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb

support id:
  intent.ahb_profile_alias_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park

coverage:
  ial2_ahb_profile_alias_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park_pipeline_cli

source kind:     ial2_profile_alias
family:          protocol_fixture
classification: supported_smoke
strict:          true
HDL module:      ahb_tb
child count:     3
semantic root:   top
```

The artifact contract remains:

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
```

One additive supported/strict fixture moves accounting from 317/358 to
318/359. The AHB inventory moves from 41 paths (21 `.ppif`, 20 `.ahb`) to 42,
evenly split 21/21.

## Semantic And MCP Contract

Strict check, schedule JSON, and normalized semantic JSON must expose the alias
path, support ID, coverage, `ial2_profile_alias` source kind, module `ahb_tb`,
root `top`, and three-child composition. The real read-only
`fsmgen_semantic_introspect` MCP adapter must expose that same normalized
payload with `read_only=true` and `shell_access=false`.

This is required parity for every support-accounted semantic addition, not an
alias-specific exception. `.5` must not add a feature-specific MCP method or
expose raw private parser/lowering objects.

## Selected Regression Contract

Focused `t/1524-ial2-ahb-exact-two-paired-busy-composition-profile-alias.t`
must prove:

- tracked alias existence and byte identity with the generic source;
- parse/report/artifact equality except alias-only residue cleanup;
- strict check and support identity;
- schedule and normalized semantic JSON;
- a real read-only `fsmgen_semantic_introspect` call;
- output review artifacts, HDL module identity, and `--verify-hdl`;
- numeric requester-child `busy_insertion.beats=2`;
- subordinate and propagated `parks_on=[busy]`;
- absence of duplicate top `busy_flow`;
- malformed profile-alias diagnostics; and
- generic/exact-one/base preservation.

t1524 must not compile a second generated-HDL simulation. Byte identity makes
shipped t1523 the shared runtime proof: one BUSY episode, exactly two qualified
BUSY events, stable requester/subordinate/interconnect ownership, counter
two-to-one-to-zero, no BUSY data completion, one resumed `SEQ`, four clean byte
beats, and final storage `32'h44332211`.

## Preservation And Non-Goals

`.5` must not modify `PPIF.pm`, any AHB generator, public syntax, report
schema, semantic/MCP API, generated behavior, ports, or runtime. It must not
add a two-subordinate exact-two source, another runtime, counts beyond two,
multiple insertion points, policy/runtime/random throttling, distinct local
bus-BUSY status, broader bursts/signals/managers/queues/fabrics/backends,
selector repairs, AXI/APB/VHDL changes, or decision 0020.

## Validation And Rollback

Implementation requires t1524, t1523 shared runtime or a current passing
record, exact-one paired/requester-alias preservation, t248, t297, t1518,
syntax, mdBook, Knowledge Map, memory/path/diff/doctrine gates, and the 4-GiB
resource cap for heavyweight work.

Rollback removes only the additive alias fixture, support/language/test/doc
entries, and restores 317/358/41. The shipped generic source and all existing
generators, semantic/MCP contracts, and runtime behavior remain unchanged.
