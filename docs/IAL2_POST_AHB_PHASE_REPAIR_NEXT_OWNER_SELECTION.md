# IAL2 Post-AHB Phase-Repair Next Owner Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.808`

Date: 2026-07-23

## Outcome

Select `IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT` as the next
exact feature-completeness owner after the generated and direct AHB
completion-edge phase repairs close cleanly.

The selected first leaf is a no-behavior audit. It must determine the exact
ready/acceptance and generated-state contract for more than one bounded
requester `HTRANS=BUSY` presentation at one literal insertion point before any
public syntax or implementation is selected. The proposed tree does not
activate until `.808` commits with a clean repository.

Decision `0020` and the protocol-neutral transaction-layer horizon remain
proposed/inactive. The director required ongoing tasks to dry out before any
possible activation; that condition is not itself an activation instruction.

## Evidence Read

The selector reconciled:

- `.807` and the completed
  `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.1-.8` generated/direct phase
  lineage through clean commit `75d107083`;
- current AHB residue in the mdBook and generated requester reports;
- `ppif/ahb_requester_busy_insert.ppif`, its `.ahb` alias, and the one- and
  two-subordinate paired BUSY sources;
- `AhbRequester` transfer normalization, generated IAL1 insertion state,
  report/residue, and PPIF transfer-clause parsing;
- t/1498 single-BUSY generated-HDL proof, t/1512 alias parity, t/1513 and
  t/1515 paired BUSY-park generated-HDL proofs, and t/1519 phase preservation;
- support/language/capability surfaces, README, ROADMAP_V2, mdBook, Memory,
  Knowledge Map, task trees, proposed audits, and decision `0020`.

## Current Boundary

The current public requester syntax declares:

```text
(busy 2'b01)
(busy-before-beat 2)
```

The generated requester has one `busy_inserted_q` bit and no BUSY-count state.
Its report is exact:

```text
busy_insertion.generated_behavior = true
busy_insertion.before_beat        = 2
busy_insertion.beats              = single
```

Its canonical residue says multi-presentation or policy-driven BUSY
throttling, runtime-driven insertion points, and requester BUSY beyond one
held presentation remain future work. t/1498 proves
`transfers=5 beats=4 busy=1`; t/1513 proves the same one-BUSY/four-beat path
against a parking subordinate; t/1515 proves one insertion per command across
both subordinate windows.

The completion-edge repair does not widen this policy. It guarantees correct
accepted address/control and data-owner bookkeeping around back-to-back active
phases, which makes it a preservation authority for the selected audit.

## Why Multiple Bounded BUSY Presentations Are Next

A literal count of consecutive BUSY presentations at the existing single
insertion point is the smallest coherent remaining AHB increment:

- it extends an already shipped requester option, transfer encoding, drive
  block, source family, aliases, paired compositions, and BUSY-parking receiver;
- it can preserve every bus and local-status port, burst address progression,
  data-beat count, source identity of existing fixtures, and current report
  schema outside an additive count field;
- it asks one precise unanswered question: whether multiple BUSY transfer
  presentations count on ready acceptance while a not-ready cycle merely
  holds the current presentation; and
- it is naturally audit-first because the current one-bit flag cannot express
  a count and generated lowering must be checked before a counter contract is
  frozen.

The audit must not assume a syntax such as `busy-count`, a numeric range, or a
counter implementation. It must derive them from current grammar conventions,
AHB ready semantics, width bounds, and warning-clean generated-HDL behavior.

## Exact Selected Audit Boundary

The selected `.1` audit must:

- distinguish accepted BUSY presentations from raw cycles held while
  `HREADY=0`;
- preserve the pending SEQ address/control/write-data tuple through every BUSY
  presentation without consuming a data beat, sampling a response, advancing
  address/data, or changing beat index/remaining count;
- resume that same pending SEQ exactly once and retain the exact final
  acceptance, completion, error/status, and storage counts;
- feasibility-probe the smallest bounded counter/state shape through generated
  IAL1, IAL0, SystemVerilog, Verilator lint/runtime, and paired BUSY parking;
- decide generic requester source, `.ahb` alias, one-/two-subordinate paired
  sequencing, support/report/residue, diagnostics, docs, and rollback only far
  enough to select a separate contract owner; and
- preserve all current requester, subordinate, interconnect, phase-pipeline,
  base/alias, and single-BUSY behavior.

## Larger Alternatives Deferred

- Runtime-selected or externally throttled BUSY policy needs new command or
  policy inputs and a wider public contract.
- A separate local bus-BUSY status output changes requester and composition
  ports but does not first broaden functional BUSY behavior.
- Halfword/word, wider fixed, or indefinite burst continuation depends on
  multi-word/register-bank progression beyond the current byte-only window.
- Optional/property-gated AHB signals start a new signal/binding family.
- Larger fabrics, scoreboards, full-manager work, verification output,
  backends, AXI/APB, and VHDL are wider or orthogonal.
- Decision `0020` is director-owned and is not ordinary-PNT eligible.

## Validation

This selector is documentation/task routing only. Evidence commands are:

```bash
perl -Iperl -MFSM::Adapter::IAL2::PPIF -MJSON::PP -e 'my $r=FSM::Adapter::IAL2::PPIF->new()->parse_file("ppif/ahb_requester_busy_insert.ppif"); print JSON::PP->new->canonical->encode($r->{report}{busy_insertion}), "\n";'
rg -n 'busy_before_beat|busy_inserted_q|busy_insertion|multi-beat or policy-driven' perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm t/1498-ial2-ahb-requester-busy-insert.t
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_doctrines.sh
```

Potentially heavyweight proofs remain behind the repository RAM guard. The
future audit must use direct `memory_pressure -Q` for live host memory because
the guard's macOS host-percentage estimator is a known separate infrastructure
issue; descendant RSS remains capped at 4 GiB.

## Rollback

Rollback is documentation-only: remove this selector/fact and the proposed
audit tree, restore `.808` to active candidate comparison, and restore the
task-index/Memory/book/roadmap routing. No shipped behavior changes.
