# IAL2 AHB Requester Exact-Three BUSY Event Contract Selection

Task-tree owner:
`IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.2`

Date: 2026-07-29

## Outcome

This slice selects the smallest additive public extension from the shipped
exact-two requester BUSY contract to exactly three qualified BUSY events at
the existing single literal insertion point. Public normalization will accept
only literal `(busy-beats 2)` and `(busy-beats 3)`; absence of the clause
continues to mean the canonical exact-one behavior.

The first exact-three source will be the generic fixture
`ppif/ahb_requester_busy_insert_three.ppif`. It will reuse the existing
`AhbRequester` generator and its already-shipped width-two event counter. This
selection changes no parser, generator, source, support, test, artifact,
semantic/MCP API, HDL/runtime, backend, protocol, or transaction-layer
behavior. Implementation is owned by leaf
`IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.3`.

Leaf `.3` now implements this contract. The shipped result is documented in
`docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_BEHAVIOR.md`; the selection
below remains the normative public boundary.

## Public Syntax And Event Meaning

The selected source is the exact-two source with distinct identities and one
literal change:

```text
(transfer
  (idle 2'b00)
  (busy 2'b01)
  (nonseq 2'b10)
  (seq 2'b11)
  (first-beat nonseq)
  (later-beats seq)
  (advance-on ready)
  (busy-before-beat 2)
  (busy-beats 3))
```

`busy-before-beat` remains the zero-based pending `SEQ` beat before which BUSY
is inserted. `busy-beats 3` means exactly three rising events satisfying:

```text
HGRANT && HREADY && HTRANS == 2'b01
```

Ready-low and grant-low clocks consume no count. Address, control, write data,
beat index, and data-beat remaining state stay stable for the whole BUSY
episode. BUSY completes neither a data beat nor a response. After the third
qualified event, the same pending transfer resumes exactly once as `SEQ`.

## Bounded Normalization Contract

`PPIF.pm` already parses the optional `busy-beats` scalar; no adapter grammar
change is required. `AhbRequester::_normalize_transfer` will accept an exact
literal integer in the inclusive range `2..3` and retain the existing
prerequisites. The selected diagnostic is:

```text
AHB requester transfer.busy_beats must be a literal integer in 2..3 in this slice
```

The fail-closed boundary is:

- absence is canonical exact-one;
- literal two retains its shipped exact-two meaning;
- literal three selects exactly three qualified BUSY events;
- zero, one, values above three, symbols, expressions, references, and other
  non-literals are rejected;
- `busy-beats` still requires both the BUSY encoding and
  `busy-before-beat`; and
- duplicate clauses retain the existing literal-block duplicate diagnostic.

This is a bounded policy extension, not a promise of a generalized counter.

## Additive Generic Public Source

Leaf `.3` freezes these exact identities:

```text
path:             ppif/ahb_requester_busy_insert_three.ppif
intent:           ahb_requester_busy_insert_three
source object:    fsmgen-ahb-requester-busy-insert-three
anchor document:  FSMGEN-AHB-REQUESTER-CAPTURE-WORKSHEET
anchor section:   bounded-requester-three-busy-insertion
anchor page:      stage-1
actor/module:     amba_requester_busy_insert_three
IAL1 artifact:    amba_requester_busy_insert_three.isf
IAL0 artifact:    amba_requester_busy_insert_three.fsm
support id:       intent.ppif_ahb_requester_busy_insert_three
coverage:         ial2_ppif_ahb_requester_busy_insert_three_pipeline_cli
family:           protocol_fixture
classification:   supported_smoke
strict support:   true
source kind:      ppif
semantic root:    fsm
```

The source is additive and generic-first. The matching byte-identical `.ahb`
alias is not part of `.3`; completed `.4` separately selects its contract, and
proposed `.5` owns implementation after `.4` commits cleanly.

## Existing Lowering Is The Contract

The exact-three source uses the existing actor-owned storage unchanged:

```text
(var ahb_busy_remaining_q (width 2) (reset 0))
```

At insertion, the transaction initializes the counter from the literal value
before BUSY becomes visible. The existing qualified non-final rule decrements
when the count is greater than one. The existing qualified final rule matches
one, clears the counter, sets `ahb_address_pending_q`, and drives `SEQ`. The
final-over-nonfinal checker priority, both rules' priority over `ahb_request`,
the whole-BUSY continuation gate, `busy_inserted_q`, and all address/data/
response owners remain unchanged.

The readiness audit directly proved internal `3 -> 2 -> 1 -> 0` retirement in
continuous, 32-clock ready-low, and 32-clock grant-low scenarios. No wider
counter or lower-layer repair is selected.

## Report And Residue Truth

The exact-three report will expose:

```text
busy_insertion.generated_behavior   = true
busy_insertion.htrans_busy_encoding = 2'b01
busy_insertion.before_beat          = 2
busy_insertion.beats                 = 3
```

The static-rule text will state that multiple insertion is bounded to literal
`busy-beats` values `2..3` in this slice. Residue must describe the whole
shipped surface truthfully:

- exact-one sources keep `beats=single` and name the additive exact-two and
  exact-three generic sources; only counts above three and broader policies
  remain deferred;
- exact-two generic and alias reports keep numeric `beats=2`, acknowledge
  exact-three generic support, and defer only counts above three plus broader
  policies; and
- exact-three reports use numeric `beats=3` and defer counts above three,
  generalized width, policy/runtime/random throttling, and multiple insertion
  points.

Existing profile-alias suffix cleanup remains unchanged. Consequently the
exact-two aliases and paired reports inherit only the truthful shared residue
update; no alias identity, generator, artifact, runtime, or composition
contract changes.

## Support And Semantic Boundary

The baseline is 320 protocol fixtures, 361 supported-smoke+strict entries,
and 44 AHB IAL2 source paths split 22 `.ppif` / 22 `.ahb`. Adding one generic
source moves the checkpoint to:

```text
protocol fixtures:          321
supported-smoke + strict:   362
AHB IAL2 source paths:       45
AHB split:                   23 .ppif / 22 .ahb
```

Normalized semantic JSON must retain module
`amba_requester_busy_insert_three`, semantic source root `fsm`, exact IAL1/
IAL0 artifacts, and matched support. The existing common
`fsmgen_semantic_introspect` adapter must return the same normalized model with
`read_only=true` and `shell_access=false`; there is no feature-specific API or
raw private lowering payload.

## Implementation And Validation Contract

Leaf `.3` must:

- add only the generic exact-three source and exact support entry;
- broaden normalization only from exact literal two to literal range `2..3`;
- retain the width-two counter, existing rules, priorities, owners, and
  generated artifact shape;
- add `t/1528-ial2-ahb-requester-three-busy-insert.t` and
  `t/data/ahb_requester_three_busy_insert_tb.svt`;
- use one assertion-enabled Verilator binary for continuous, 32-clock
  ready-low, and 32-clock grant-low scenarios;
- directly observe internal `ahb_busy_remaining_q` as `3 -> 2 -> 1 -> 0`,
  including stall stability, and prove one BUSY episode, three qualified BUSY
  events, one resumed `SEQ`, four accepted byte `INCR4` data beats, no BUSY
  data/response completion, stable pending ownership, and zero final count;
- strengthen existing t1521 exact-two runtime observation to directly prove
  its private counter `2 -> 1 -> 0`, without changing exact-two behavior;
- reject 0, 1, 4, symbolic, missing-prerequisite, and duplicate declarations;
- preserve exact-one, exact-two generic/alias, paired exact-two, and base
  behavior, including affected shared report residue;
- prove strict check, schedule/report, exact artifacts, normalized semantic
  JSON, real read-only MCP parity, outdir generation, HDL verification,
  diagnostics, support accounting, and the current language-surface boundary;
  and
- run every broad Perl/`prove`/`fsmgen` command under the unchanged repository
  RAM guard, remove generated book/test artifacts, and leave no disposable
  workspace.

The focused preservation boundary includes t1498, t1512, t1521-t1526, t1518,
t248, and t297 where their report, semantic, source-inventory, or accounting
contracts are affected.

## Non-Selections

Counts above three, generalized counter width, policy/runtime/random
throttling, multiple insertion points, a distinct local bus-BUSY status,
exact-three paired compositions, the matching exact-three `.ahb` alias,
broader bursts/signals/managers/fabrics, selector repairs, AXI/APB/VHDL, and
decision 0020 remain separate and inactive.

## Rollback

Before `.3`, rollback removes this contract record/fact and proposed leaf,
restores `.2` to active selection, and reverts roadmap/mdBook/task/Memory/
Knowledge Map pointers. There is no behavior to revert. After `.3`, rollback
must remove the exact-three generic source/support/test entries, restore the
literal-two diagnostic and exact-one/two residue, restore 320/361/44
accounting, and rerun the full preservation boundary.
