# AXI IAL2 Manager Transaction Envelope Selection

Status: next AXI manager feature-completeness subset selected; no parser,
generator, HDL, or CLI behavior changed by this note.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md](AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md)
- [docs/AXI_MANAGER_USER_API_BRAINSTORM.md](AXI_MANAGER_USER_API_BRAINSTORM.md)
- [docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md](AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md)
- [docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_FIRST_SLICE.md](AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md](AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md)

## Purpose

The shipped IAL2 AXI manager path now has:

- Valid-Ready channel objects and bundles,
- a public `manager-capacity-status` shell,
- explicit read/write outstanding capacity,
- static read/write ID-family metadata.

The next exact subset is a **logical read/write transaction envelope and
static-validation contract**. This is the missing bridge between static manager
metadata and later dynamic manager behavior. Without a transaction envelope,
there is no stable public place to attach a user tag, transaction direction,
request event, optional requested ID, address/data/control bindings, or
completion identity. ID allocation, ordering queues, and `BID`/`RID` response
matching should not be implemented before that envelope exists.

This selector does not implement the envelope. It selects the next readiness
audit owner.

## Source Anchors

The selected subset is anchored to:

| Anchor | Selected meaning |
| --- | --- |
| `A1.1` | AXI supports multiple outstanding transactions and out-of-order completion. |
| `A1.2` | AXI read/write transactions use the five channel families `AW`, `W`, `B`, `AR`, and `R`. |
| `A5.1` | IDs define ordered transaction streams and make later-before-earlier completion legal when the manager tracks the rules. |
| `A5.1.1` | Read and write ID families have separate widths and signal pairs, including zero-width absence. |
| `A5.5` | Write completion identity comes through `BID` corresponding to `AWID`; full response matching remains future work. |
| `A5.6` | Read completion/data identity comes through `RID` corresponding to `ARID`; full read-data matching and reassembly remain future work. |

`A5.2`, `A5.3`, `A5.6.1`, `A6.4.4`, and `B3` remain evidence for later
unique-in-flight, ordering, interleaving, atomic, and transaction-class rule
owners.

## Selected Subset

The next implementation family should introduce an AST/structural transaction
envelope model for logical manager requests. The model should be machine
readable and fielded, not a raw string carrier.

The selected semantic shape is equivalent to:

```text
(transactions
  (write w0
    (tag wr0)
    (request axi0_write_submit)
    (completion axi0_write_complete)
    (id auto))
  (read r0
    (tag rd0)
    (request axi0_read_submit)
    (completion axi0_read_complete)
    (id auto)))
```

The readiness audit may choose different exact source spelling, but it must
preserve these structural contract roles:

- stable transaction name,
- kind `read` or `write`,
- stable user-visible tag or completion identity,
- request/submit event binding,
- completion event binding,
- optional requested ID expression or `auto`,
- direction-specific validation against the declared ID family when a concrete
  ID is supplied,
- source anchors and report metadata,
- explicit residue for the dynamic behavior not owned by this first envelope.

## Static Validation Expectations

The later implementation should fail closed on at least:

- missing transaction name, kind, request event, completion event, or tag;
- duplicate transaction names or tags;
- transaction names, tags, request events, or completion events that collide
  with clock/reset/status/storage/ID-family signal names;
- write envelopes that reference read-only ID-family fields, or read envelopes
  that reference write-only ID-family fields;
- concrete requested IDs when the selected family has width `0`;
- concrete requested IDs that do not fit the declared family width;
- unsupported ordering, response-matching, burst, interleaving,
  transaction-class, alias, or VHDL clauses.

## Generated Artifact Boundary

The selected first transaction-envelope subset is expected to be static/report
metadata unless the readiness audit finds a concrete IAL1, IAL0, or
SystemVerilog prerequisite. If generated artifacts are widened, the mandatory
chain remains:

```text
IAL2 -> generated .isf -> generated .fsm -> SystemVerilog
```

The implementation must not add hidden direct IAL2-to-IAL0 lowering.

## Report Contract

The future report should add a structured transaction section without claiming
ID allocation or response matching:

```text
transactions:
  - name: w0
    kind: write
    tag: wr0
    request_event: axi0_write_submit
    completion_event: axi0_write_complete
    id_policy: auto
    source_anchors: [...]
  - name: r0
    kind: read
    tag: rd0
    request_event: axi0_read_submit
    completion_event: axi0_read_complete
    id_policy: auto
    source_anchors: [...]
```

If concrete requested IDs are selected by the later implementation, the report
should expose the normalized value, family, width, and fit-validation result.

## Explicit Residue

This selector does not implement:

- ID allocation algorithms,
- dynamic user-ID validation while issuing work,
- same-ID ordering queues,
- different-ID interleaving policy,
- `BID`/`RID` response matching,
- burst and last-beat assembly,
- write-data sequencing,
- queued or blocking policy behavior,
- transaction-class and unique-in-flight constraints,
- full Easy/Power/supervised Raw manager APIs,
- `.axi` or other profile aliases,
- VHDL backend or VHDL rerouting behavior.

## Selected Next Leaf

Proceed with `IAL2-FEATURE-COMPLETENESS-FRONTIER.11`: audit readiness for the
AXI manager logical transaction-envelope/static-validation slice. The audit
must decide whether the first implementation should extend the existing
`manager-capacity-status` object, introduce a broader manager object, or land
an IAL1/IAL0/SystemVerilog prerequisite first.
