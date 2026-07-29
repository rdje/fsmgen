# IAL2 AHB Requester Exact-Four BUSY Event Contract Selection

Task-tree owner:
`IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.2`

Date: 2026-07-29

## Outcome

This slice selects one additive generic exact-four requester source and a
minimum-width counter rule. Public normalization will accept only literal
`(busy-beats 2)`, `(busy-beats 3)`, and `(busy-beats 4)`; absence remains the
canonical exact-one behavior.

Implementation is owned by proposed leaf
`IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.3`. This contract
selection changes no parser, generator, source, support, test, artifact,
semantic/MCP API, HDL/runtime, backend, protocol, verification-generation,
HIAL/VIAL, VHDL, or transaction behavior.

## Public Syntax And Meaning

The new source is the shipped exact-three source with only distinct identities
and the adjacent literal count:

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
  (busy-beats 4))
```

`busy-beats 4` means exactly four events satisfying
`HGRANT && HREADY && HTRANS == 2'b01`. Ready-low and grant-low clocks consume
no count. The same pending address/control/write-data/beat state remains held,
BUSY completes no data beat or response, and the pending transfer resumes once
as `SEQ` after the fourth qualified event.

`AhbRequester::_normalize_transfer` will accept literal integers in inclusive
range `2..4`. The selected diagnostic is:

```text
AHB requester transfer.busy_beats must be a literal integer in 2..4 in this slice
```

Zero, one, five and larger values, symbols, expressions, references, and other
non-literals fail closed. Existing BUSY encoding, insertion-point, and duplicate
clause prerequisites remain unchanged.

## Exact Generic Identity

Leaf `.3` must add exactly:

```text
path:             ppif/ahb_requester_busy_insert_four.ppif
intent:           ahb_requester_busy_insert_four
source object:    fsmgen-ahb-requester-busy-insert-four
anchor document:  FSMGEN-AHB-REQUESTER-CAPTURE-WORKSHEET
anchor section:   bounded-requester-four-busy-insertion
anchor page:      stage-1
actor/module:     amba_requester_busy_insert_four
IAL1 artifact:    amba_requester_busy_insert_four.isf
IAL0 artifact:    amba_requester_busy_insert_four.fsm
support id:       intent.ppif_ahb_requester_busy_insert_four
coverage:         ial2_ppif_ahb_requester_busy_insert_four_pipeline_cli
family:           protocol_fixture
classification:   supported_smoke
strict support:   true
source kind:      ppif
semantic root:    fsm
```

The source is generic-first. No `.ahb` alias belongs to `.3`; an alias requires
a later separate selector and shared-runtime parity contract.

## Minimum-Width Lowering Contract

`AhbRequester` will derive the actor-owned remaining-counter width from the
normalized maximum value using the same integer-loop semantics as the existing
`AxiManagerCapacityStatus::_counter_width` helper:

```perl
sub _counter_width($max_value) {
    my $width = 1;
    my $limit = 2;
    while ($limit <= $max_value) {
        ++$width;
        $limit *= 2;
    }
    return $width;
}
```

This is `ceil(log2(max_value + 1))` for non-negative integer maxima. The
generated declaration is therefore:

```text
busy-beats 2 -> (var ahb_busy_remaining_q (width 2) (reset 0))
busy-beats 3 -> (var ahb_busy_remaining_q (width 2) (reset 0))
busy-beats 4 -> (var ahb_busy_remaining_q (width 3) (reset 0))
```

Exact-two and exact-three generated IAL1/IAL0/SystemVerilog behavior remains
unchanged. Exact-one still has no multiple-event counter. Literal four uses
the proven 3-bit declaration and existing initializer, `>1` decrement, `==1`
final clear/address-pending/SEQ handoff, whole-BUSY continuation, priorities,
and owners without any new IAL1 feature.

## Report, Residue, And Semantic Truth

The exact-four report exposes numeric `busy_insertion.beats=4`, insertion index
two, generated behavior true, and HTRANS BUSY encoding `2'b01`. Static-rule
text changes from range `2..3` to `2..4` for every multiple-BUSY report.

Shared residue must say:

- exact one: exact-two, exact-three, and exact-four behavior is supported;
- exact two: additive exact-three and exact-four behavior is supported;
- exact three: additive exact-four behavior is supported;
- exact four: exactly four is shipped; and
- every form defers counts above four, arbitrary/runtime/policy/random
  throttling, and multiple insertion points.

Alias-only residue cleanup, schedule/report schemas, semantic schema, and the
common read-only MCP API remain unchanged. Normalized semantic JSON and
`fsmgen_semantic_introspect` must report module
`amba_requester_busy_insert_four`, root `fsm`, matched support, repo-relative
source id, `read_only=true`, and `shell_access=false` without a feature-specific
method or private lowering payload.

## Support Accounting

The baseline is 326 protocol fixtures, 367 supported-smoke+strict entries, and
50 AHB source paths split 25 `.ppif` / 25 `.ahb`. One generic source projects:

```text
protocol fixtures:          327
supported-smoke + strict:   368
AHB IAL2 source paths:       51
AHB split:                   26 .ppif / 25 .ahb
```

RegressionCorpus, capability, language-surface, README current navigation,
roadmap, mdBook, task tree, Memory, and Knowledge Map must agree on that exact
checkpoint.

## Implementation And Validation Owner

Proposed `.3` must:

- make only the selected normalizer, counter-width, report/residue, source,
  support, focused-test, and synchronized public-document changes;
- add `t/1535-ial2-ahb-requester-four-busy-insert.t` and
  `t/data/ahb_requester_four_busy_insert_tb.svt`;
- use one assertion-enabled Verilator `--timing` binary without `--no-assert`
  for continuous, 32-clock ready-low, and 32-clock grant-low scenarios;
- directly observe `4 -> 3 -> 2 -> 1 -> 0`, one BUSY episode, four qualified
  events, five non-IDLE presentations, four accepted byte `INCR4` beats, stable
  pending state, no BUSY data/response completion, one resumed `SEQ`, and zero
  final counter;
- prove strict check, schedule/report, exact IAL1/IAL0 artifacts, repository-
  local outdir, public `--verify-hdl`, normalized semantic JSON, and real
  read-only shell-disabled MCP parity;
- reject 0/1/5/symbolic/missing-prerequisite/duplicate forms;
- prove exact-two width two and `2 -> 1 -> 0`, exact-three width two and
  `3 -> 2 -> 1 -> 0`, exact-one no counter, base no BUSY machinery, and all
  existing generic/alias/paired source bytes unchanged;
- update affected t1498/t1512/t1521-t1534/t1518/t248/t297 expectations with
  the smallest warranted focused and preservation runs; and
- use repository-derived same-volume outputs, the authorized host-100/
  process-4096 profile, canonical Stats-compatible RAM plus separate kernel
  pressure, exact cleanup census, doctrine gates, and a clean commit.

## Non-Selections

Counts above four, arbitrary/runtime-selected/policy/random counts, multiple
insertion points, local bus-BUSY status, new burst/signal/topology behavior,
the exact-four `.ahb` alias, exact-four paired compositions, generic priority,
other protocols/backends, HIAL/VIAL activation, VHDL, verification generation,
and decision `0020` remain separate.

## Rollback

Before `.3`, remove this record/fact/proposed leaf, restore `.2` to active, and
revert task/index/Memory/roadmap/mdBook/HIAL-VIAL pointers. No behavior needs
rollback. After `.3`, remove the exact-four source/support/test, restore literal
range/report/residue `2..3`, restore the width-two declaration contract for
the existing supported counts, restore 326/367/50 split 25/25, and rerun every
named preservation gate.
