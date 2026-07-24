# IAL2 Post-Requester-Multiple-BUSY Next Owner Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.809`

Date: 2026-07-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.809` selects proposed
`IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT`, beginning with
one no-behavior runtime/lowering readiness leaf after `.809` commits cleanly.

The selected question is deliberately smaller than generalized BUSY policy:

> Can the shipped exact-two requester be composed with the shipped
> HBURST-aware byte-lane BUSY-parking subordinate so that two qualified BUSY
> events preserve all requester/subordinate/interconnect ownership and resume
> one pending `SEQ` exactly once?

This selector changes no parser, generator, public source, support catalog,
capability manifest, test, report, artifact, semantic/MCP API, HDL/runtime,
backend, AXI/APB/AHB/VHDL, or transaction-layer behavior.

## Evidence Read

The selector reconciled:

- `.808` and completed requester multiple-BUSY child `.1`-.7;
- exact-one paired `.ppif`/`.ahb` behavior and t/1513-t/1516;
- exact-two requester `.ppif`/`.ahb` behavior and t/1521-t/1522;
- `PPIF.pm`, `AhbRequester`, `AhbSubordinate`, and `AhbInterconnect` generated
  phase/address/data ownership;
- current report residue, support accounting, language/capability surfaces,
  normalized semantic JSON, and read-only MCP contract;
- README, ROADMAP_V2, mdBook AHB current boundary/backlog, task trees, Memory,
  Knowledge Map, relevant decisions, and proposed correctness audits; and
- decision 0020, which remains proposed/inactive by director instruction.

## Current Boundary

FSMGen now ships standalone exact-two requester behavior through byte-identical
`.ppif` and `.ahb` sources, with numeric `busy_insertion.beats=2`. It also ships
paired exact-one requester/BUSY-parking-subordinate compositions across one and
two subordinate windows, each with matching `.ahb` aliases.

No source currently composes the exact-two requester with a BUSY-parking
subordinate. Counts beyond two, policy/runtime/random insertion, distinct
local bus-BUSY status, broader bursts, optional signals, and deeper fabrics are
larger changes. The one-subordinate exact-two composition is therefore the
smallest reuse-only boundary left in this lineage.

## Static Feasibility Probe

A disposable in-memory candidate was derived from the one-subordinate exact-one
paired source. Only its identity/requester actor changed and `(busy-beats 2)`
was added. The existing adapter/generators produced:

```text
schema=fsmgen.ial2.protocol_intent.ahb_interconnect.v1
child_count=3
HDL module=ahb_tb
requester=amba_requester_busy_insert_two
requester busy_insertion.before_beat=2
requester busy_insertion.beats=2
subordinate parks_on=[busy]
propagated parks_on=[busy]
IAL1=amba_requester_busy_insert_two.isf
     + ahb_lite_subordinate_byte_lane_hburst_seq.isf
     + ahb_interconnect.isf
IAL0=amba_requester_busy_insert_two.fsm
     + ahb_lite_subordinate_byte_lane_hburst_seq.fsm
     + ahb_interconnect.fsm
     + ahb_tb.fsm
```

No parser/generator or semantic-API prerequisite is hidden. But static report
composition cannot prove that two consecutive qualified BUSY events keep the
subordinate continuation bank, interconnect data owner, requester pending
fields, and storage stable before exactly one resumed `SEQ`. That missing
runtime proof is why `.809` selects an audit rather than direct contract or
implementation work.

## Selected Audit Boundary

The audit must use a disposable one-requester/one-subordinate candidate and
prove:

- one BUSY transition episode containing exactly two qualified BUSY events;
- no count consumption through ready/grant stalls and no BUSY data completion;
- stable requester address/control/write-data/beat/counter ownership;
- stable subordinate continuation and storage through both BUSY events;
- retained one-hot interconnect data-phase ownership;
- the same pending transfer resumed once as `SEQ`;
- four accepted byte `INCR4` data beats, clean completion, and final
  `32'h44332211`; and
- no regression to exact-one paired or standalone exact-two behavior.

The existing paired runtime `--no-assert` boundary remains explicit because a
separate proposed interconnect task owns overlapping default/mapped output
selectors. Standalone t/1521 assertions remain authoritative for the
exact-two requester itself.

If public behavior is later selected, the audit must keep generic-first then
byte-identical `.ahb` alias sequencing, leave two-subordinate exact-two
composition separate, and require support-accounted strict check, schedule,
normalized semantic JSON, and real read-only `fsmgen_semantic_introspect` MCP
parity through existing contracts. No feature-specific introspection method or
raw private lowering payload is selected.

## Rejected Next Owners

- **Direct composition implementation:** rejected until generated-HDL runtime
  proves two-event parking/ownership and exact completion.
- **Two-subordinate exact-two composition:** larger than the one-window proof.
- **Counts beyond two or generalized count width:** requires a new public
  bound/resource/report contract.
- **Policy/runtime/random insertion or multiple points:** adds control policy,
  not reuse-only composition.
- **Distinct local bus-BUSY status:** changes public ports/meaning.
- **Halfword/word or wider/indefinite bursts, optional signals, queues,
  managers, or fabrics:** broader independent families.
- **Existing selector repairs:** remain separately owned and are not a
  prerequisite to the bounded `--no-assert` paired audit.
- **Decision 0020 transaction layer:** director-owned, proposed/inactive, and
  explicitly not selected by ordinary PNT.

## Validation And Resource Boundary

Selector closeout is documentation-only plus the in-memory static probe,
current t/1518 truth lock, mdBook build, Knowledge Map generation/check,
memory architecture, relative-document paths, diff, and doctrine gates.
Potentially heavyweight future Perl/Verilator work remains under the 4-GiB
descendant RSS cap and attached monitoring.

## Rollback

Remove this selector record/fact and proposed audit tree, restore `.809` to
active candidate selection, and revert README/ROADMAP_V2/mdBook/task/Memory/
Knowledge Map pointers. No shipped behavior is affected.
