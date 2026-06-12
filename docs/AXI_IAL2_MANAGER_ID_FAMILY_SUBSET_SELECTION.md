# AXI IAL2 Manager ID-Family Subset Selection

Status: next AXI manager behavior subset selected; no parser, generator, HDL,
or CLI behavior changed by this note.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md](AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md)
- [docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md](AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md)
- [docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_FIRST_SLICE.md](AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_FIRST_SLICE.md)

## Purpose

The shipped AXI manager capacity/status slice owns explicit read/write pending
capacity and acceptance/status feedback, but it still leaves ID width, ID
presence, allocation, ordering, and response matching as residue.

This selector chooses the next bounded subset after capacity/status. The next
subset is **ID-family declaration and static validation** for the read and
write sides. It is a prerequisite for later ID allocation, same-ID ordering,
different-ID interleaving, and `BID`/`RID` response matching.

This selector does not implement behavior.

## Source Anchors

The selected subset is anchored to:

| Anchor | Selected meaning |
| --- | --- |
| `A5.1` | AXI IDs identify ordered transaction streams and enable later transactions to be issued before earlier transactions complete. |
| `A5.1.1` | Write IDs use the `AWID`/`BID` family, read IDs use the `ARID`/`RID` family, and ID widths can be zero through 32 bits. Width zero means the corresponding ID signal is absent. |
| `A5.5` | Write responses carry `BID` corresponding to the write request `AWID`; full response matching remains future work. |
| `A5.6` | Read data carries `RID` corresponding to the read request `ARID`; full read-data matching/reassembly remains future work. |

`A5.2`, `A5.3`, `A5.6.1`, `A6.4.4`, and `B3` remain evidence for later
unique-in-flight, ordering, interleaving, atomic, and transaction-class rule
owners.

## Selected Subset

The next implementation family should introduce a structured ID-family model
with separate read and write families:

- write family: width, request ID signal, response ID signal,
- read family: width, request ID signal, response ID signal,
- explicit presence semantics for zero-width ID configurations,
- source anchors and report metadata for each family,
- static diagnostics for malformed or contradictory ID declarations.

This subset owns **static structure**, not dynamic manager behavior. It must
not claim:

- ID allocation,
- user-specified ID validation on individual transactions,
- same-ID ordering queues,
- different-ID interleaving policy,
- `BID`/`RID` response matching,
- burst or last-beat tracking,
- write-data sequencing,
- unique-in-flight or transaction-class constraints,
- `blocking` or `queued` policy behavior,
- full Easy/Power/supervised Raw APIs,
- profile aliases such as `.axi`,
- VHDL backend or VHDL rerouting behavior.

## Public Source Expectation

The next readiness audit must decide whether the implementation extends the
existing capacity/status object or first introduces a broader manager object.
Either way, the selected semantic shape is equivalent to:

```text
(id-families
  (write (width 4) (request-id AWID) (response-id BID))
  (read  (width 4) (request-id ARID) (response-id RID)))
```

Static validation expectations:

- `width` must be an integer in `0..32`;
- if `width` is `0`, the corresponding request/response ID signals are absent
  and must not be supplied;
- if `width` is greater than `0`, both request and response ID signal names
  must be supplied and must be valid identifiers;
- read and write ID-family signal names must not collide with clock, reset,
  abstract submit/complete events, status outputs, generated storage names, or
  each other;
- unsupported ID allocation, ordering, response matching, burst, transaction
  class, or unique-in-flight clauses must fail closed instead of being
  silently accepted.

## Report Contract

The future report should add a structured ID-family section without implying
dynamic response matching:

```text
id_families:
  write:
    width: 4
    present: true
    request_id_signal: AWID
    response_id_signal: BID
  read:
    width: 4
    present: true
    request_id_signal: ARID
    response_id_signal: RID
```

The report must also include:

- source anchors for the ID-family rules,
- static rule classifications for width and signal-pair validation,
- explicit residue for allocation, ordering, interleaving, response matching,
  bursts, unique-in-flight, transaction classes, aliases, and VHDL,
- a schema/version decision if the current capacity/status report shape cannot
  be widened additively.

## Generated Artifact Boundary

The selected first ID-family subset is expected to be static/report metadata
unless the readiness audit finds a concrete reason to modify generated IAL1 or
IAL0 artifacts. If generated artifacts do change, the mandatory chain remains:

```text
IAL2 -> generated .isf -> generated .fsm -> SystemVerilog
```

The implementation must still preserve reviewable generated `.isf` before
generated `.fsm`, and it must not introduce hidden direct IAL2-to-IAL0
lowering.

## Validation Expectations

The next readiness audit must map exact code/test owners and decide the first
implementation boundary. A later implementation leaf should prove at least:

- accepted read/write ID widths at `0`, `1`, and a multi-bit value;
- rejection for non-integer, negative, and greater-than-32 widths;
- rejection for ID signal names supplied with zero width;
- rejection for missing request/response signal names when width is positive;
- rejection for duplicate or colliding signal names;
- report JSON carries `id_families` and explicit residue;
- public `.ppif` check JSON and normalized semantic JSON keep source identity
  if the implementation changes public syntax;
- existing capacity/status generated `.isf`, `.fsm`, HDL, and `--verify-hdl`
  behavior remain stable unless explicitly widened by the implementation owner.

## Selected Next Leaf

Proceed with a readiness audit before code changes. The next leaf is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.8`: audit whether the ID-family/static
validation subset should be implemented as an additive extension to the
capacity/status object, a new manager object, or a prerequisite IAL1/IAL0/SV
substrate slice.
