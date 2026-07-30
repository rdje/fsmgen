# IAL2 AHB Requester Generalized BUSY Count Range Contract Selection

Task-tree owner:
`IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.2`

Date: 2026-07-30

## Outcome

This no-behavior slice freezes one implementation of the audited canonical
literal requester `busy-beats` range `2..16`. Absence remains exact-one. The
implementation changes the existing lowerer and verification only; it adds no
public source or support entry for any individual count.

Proposed leaf
`IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.3` owns the
implementation. Until that leaf activates and ships, the public range remains
`2..4` at 332 protocol fixtures, 373 supported-smoke plus strict entries, and
56 AHB paths split 28 `.ppif` / 28 `.ahb`.

## Public Admission Contract

After `.3`, `AhbRequester::_normalize_transfer` accepts:

```text
transfer.busy_beats absent  => exactly one qualified BUSY event
transfer.busy_beats 2..16   => exactly N qualified BUSY events
```

Only canonical unsigned decimal tokens are admitted. The exact normalizer
shape is equivalent to `\A(?:[2-9]|1[0-6])\z`; it accepts `2` through `9` and
`10` through `16` and rejects:

- `0`, `1`, and `17` or larger;
- signed forms such as `+2` and `-2`;
- leading-zero forms such as `02`;
- base-prefixed forms such as `0x2`;
- fractional forms such as `2.0`;
- symbols, references, expressions, lists, and other non-literals; and
- duplicate `(busy-beats ...)` clauses through the existing scalar-duplicate
  gate.

The selected exact diagnostic is:

```text
AHB requester transfer.busy_beats must be a canonical decimal literal integer in 2..16 in this slice
```

That diagnostic applies to malformed scalar tokens. Nested reference and
expression forms fail earlier at the PPIF literal-block gate with its existing
`requires exactly one scalar value` diagnostic; duplicate clauses likewise
retain the existing scalar-duplicate diagnostic.

Existing prerequisites remain exact: `busy_beats` requires
`busy_before_beat`; the insertion point requires BUSY encoding `2'b01`; and
`busy_before_beat` remains a literal `1..15` position within the declared
`max_beats=16` requester class.

## Lowering And Runtime Meaning

The current `_counter_width` integer loop remains byte-for-byte unchanged. It
implements `ceil(log2(count + 1))` for the normalized non-negative count:

| `busy-beats` | generated width |
| ---: | ---: |
| 2 | 2 |
| 4 | 3 |
| 5 | 3 |
| 7 | 3 |
| 8 | 4 |
| 15 | 4 |
| 16 | 5 |

The existing generated control is also unchanged. Insertion loads literal N;
each `HGRANT && HREADY && HTRANS == 2'b01` event with remaining count above one
decrements it; the event at one clears it, restores address-pending ownership,
and resumes the held transfer once as `SEQ`. Ready-low and grant-low clocks do
not retire the count. BUSY completes no data beat or response, and the pending
address/control/write-data/beat state remains stable for the episode.

No new IAL1 construct, generated signal, report field, artifact shape,
semantic schema, MCP method, simulator integration, or backend is selected.

## Static Rule, Report, And Residue

The static-rule report changes only its bound and canonical-token wording:

```text
multiple BUSY insertion is bounded to canonical decimal literal busy-beats values 2..16 in this slice
```

`transfer.busy_beats` and `busy_insertion.beats` remain numeric for explicit
counts; absence keeps the existing `busy_insertion.beats=single` report token.

The count-specific residue branch is replaced by one numeric template. Its
detail must state the exact singular/plural qualified-event count, state that
compile-time literal values `2..16` are supported without one catalog source
per count, and defer counts above 16 plus symbolic, policy-selected,
runtime-selected, or random throttling and multiple insertion points. Existing
residue id `ahb_requester_busy_insert_support` remains unchanged.

## Frozen Existing Bytes And Accounting

Implementation changes no existing public source byte. Contract-time blob
identities are:

| path | git blob |
| --- | --- |
| `ppif/ahb_requester_busy_insert.ppif` | `db5ebaac37735cbb80a3ed7c5954eee9112e7cf8` |
| `ppif/ahb_requester_busy_insert_two.ppif` | `82d4649e24eb3da3010e1a06b529861e60491fa1` |
| `ppif/ahb_requester_busy_insert_three.ppif` | `ed40621f07dc89e5cd92563d4d1c4da228baaeab` |
| `ppif/ahb_requester_busy_insert_four.ppif` | `2f01702633a8698f7057e6f5b663f8bca6d29989` |

No `busy_insert_five`, `busy_insert_eight`, or `busy_insert_sixteen` catalog
fixture is selected. Existing generic/profile and one-/two-window paired
fixtures remain the support corpus. Therefore accounting stays exactly
332/373/56 split 28 `.ppif` / 28 `.ahb` before and after `.3`.

The current lowerer blob is
`08dcdbc107b89a0e6733d8764660d58d7bd4f359`. It is the only product-code file
selected for modification.

## Focused Verification Owner

Implementation `.3` must add exactly:

```text
t/1541-ial2-ahb-requester-generalized-busy-count-range.t
t/data/ahb_requester_generalized_busy_count_tb.svt
```

The test derives repository-local unmatched candidates from the shipped
exact-four source; they are verification inputs, not public fixtures or support
entries. It must prove:

1. absence, admitted `2/4/5/7/8/15/16`, and rejected
   `0/1/17/02/+2/-2/0x2/2.0/symbol/reference/expression/duplicate` forms;
2. widths `2/3/3/3/4/4/5`, literal loads, exact numeric reports, unchanged
   report/schema/artifact shapes, the exact static rule, and unified residue;
3. strict/check, schedule, repository-local IAL1/IAL0/SystemVerilog output,
   normalized semantic JSON, real repo-relative read-only shell-disabled MCP,
   and public `--verify-hdl` for representative counts 5, 8, and 16; and
4. assertion-enabled Verilator 5.046 `--timing -j1` runs for 5/8/16
   continuously qualified plus 32-clock ready-low and grant-low scenarios at
   counts 5 and 16.

Every runtime must observe five non-IDLE transfer presentations, four completed
data beats, one BUSY episode, exactly N qualified BUSY events, the minimum
counter width, stable pending state, one resumed `SEQ`, and zero final counter.
No `--no-assert` or warning-specific suppression is permitted; standard
`-Wno-fatal` remains.

Current focused test `t/1535-ial2-ahb-requester-four-busy-insert.t` has blob
`32787606525eb1e5fa6b235ebf1a5ef7cee86353`; its testbench has blob
`40d557deac23ea17f02f4774510fbeda268e4acf`. `.3` updates t1535 only to:

- expect the new static rule and numeric residue;
- replace the obsolete count-5 rejection with count-17 and canonical-token
  rejection where focused overlap is useful; and
- replace its two default `File::Temp` workspaces with a helper rooted at
  `.artifacts/tmp/tests`.

That last item closes a same-volume locality gap in the touched test. New t1541
and all subprocess/tool caches also use repository-derived roots; exact cleanup
and residue census are required.

## Preservation And Non-Selections

`.3` must preserve exact-one-through-four generated behavior and source hashes,
the base requester without BUSY machinery, t1498/t1512/t1521-t1540, t248/t297
accounting, support/language/capability truth, mdBook, Knowledge Map, and all
doctrine gates. Any necessary expectation update must follow the frozen report
text only; it must not weaken assertion or runtime coverage.

Dynamic, policy-selected, random, symbolic, or runtime-selected counts,
multiple insertion points, distinct bus-BUSY status, new burst/signal/topology
semantics, generic rule/transaction priority, HIAL/VIAL, verification
generation, VHDL, portability, scale, other protocols/backends, and decision
`0020` remain separately owned.

Clean contract commit `7e2b436cf` activates only implementation `.3`.
Activation changes continuity and no current parser, generator, source,
support, report, semantic/MCP, generated HDL/runtime, or simulator behavior;
literal `2..4` and 332/373/56 split 28/28 remain current until `.3` ships.

## Implementation Outcome

Implementation `.3` ships the frozen contract. In addition to the selected
t1535 repair, review of every test touched by the shared report/residue change
found the same implicit-temp risk in the exact-one through exact-four
requester generic/profile tests. All eight now use
`FSM::ProjectDataLocality` for explicit workspaces and subprocess temp roots.
The four paired exact-four generic/profile tests already had explicit
repository-local workspaces and now configure subprocess temp roots as well.
This verification-local expansion changes no public source, support identity,
HDL, simulator, report schema, or semantic/MCP contract.

The implementation result, runtime proof, current diagnostics, unchanged
accounting, and exact rollback are canonical in
`docs/IAL2_AHB_REQUESTER_GENERALIZED_BUSY_COUNT_RANGE_BEHAVIOR.md`.

## Rollback

Before `.3`, rollback removes this contract record/fact and proposed `.3`,
restores `.2` active, and changes no behavior. After `.3`, restore the three
AhbRequester regions to literal `2..4` admission/static-rule/count-specific
residue, restore t1535 expectations, remove t1541 and its testbench, retain all
existing public sources/support entries, and rerun every named preservation
gate. Accounting remains 332/373/56 split 28/28 throughout.
