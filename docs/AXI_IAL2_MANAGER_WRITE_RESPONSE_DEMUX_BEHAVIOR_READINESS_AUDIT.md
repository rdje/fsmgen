# AXI IAL2 Manager Write Response-Demux Behavior Readiness Audit

`IAL2-FEATURE-COMPLETENESS-FRONTIER.28` audits whether the generated write
`BID` response-demux behavior can be implemented immediately after the
parser/report metadata slice.

## Conclusion

Generated write `BID` demux should not be implemented directly in the next
slice. The current IAL1/IAL0/SystemVerilog substrate has almost everything the
bounded demux needs, but generated transaction completion signals must be
one-cycle completion pulses, not sticky flopped rule assignments.

The next owner is a small IAL1 prerequisite:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.29
```

That leaf should add a minimal rule-owned one-cycle pulse action for IAL1,
intended first for generated IAL2 response-demux completion outputs. Once that
exists, a later generated write response-demux behavior leaf can stay on the
required `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` path without direct IAL2 to
IAL0 or backend shortcuts.

## Evidence Read

- `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `perl/FSM/Adapter/IAL2/PPIF.pm`
- `perl/FSM/Scheduler/ISF/LoweringIR.pm`
- `perl/FSM/Scheduler/ISF/Emitter/FSM.pm`
- `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md`
- `docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_READINESS_AUDIT.md`
- `docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_SELECTION.md`
- `docs/book/src/13g-rules.md`
- `docs/ISF_SPEC.md`
- `ppif/axi_manager_capacity_status_response_demux.ppif`
- `t/1437-axi-ial2-manager-capacity-status-generator.t`
- `t/1436-ial2-ppif-parser-cli.t`

The baseline command:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif
```

confirms the current report still has `response_demux.generated_behavior:
false`, reports `axi0_bid` as a future generated input, and leaves generated
`.isf`, `.fsm`, and HDL behavior unchanged.

## Substrate That Already Fits

The shipped metadata contract is the right public boundary:

```text
(response-demux
  (write
    (response-event axi0_write_complete)
    (transaction-completion generated)))
```

The current generator already records the needed information:

- write response ID signal and width through `id_families.write`;
- response ID direction as `generated_input`;
- the write response event through `response_demux.write.response_event`;
- the auto-ID write transactions through
  `response_demux.write.auto_transactions`;
- each auto transaction's selected-ID and busy state through
  `auto_id_lifecycle.families[].transaction_state[]`;
- per-transaction request/completion event fan-in through
  `transaction_event_dispatch`.

The current lowerer can also carry the needed expressions and checks after an
IAL1 pulse action exists:

- compare `BID` against a selected-ID register;
- guard demux rules with `response_event && busy && (BID == selected_id)`;
- add `BID` as a generated IAL1 input with the declared write ID width;
- emit `.fsm` and SystemVerilog assertions through the existing `+assert`
  path.

No IAL0 or SystemVerilog backend prerequisite is required for these pieces.

## Missing IAL1 Piece

IAL1 rule actions currently support guarded flopped assignments:

```text
(set port expr)
(port expr)
```

Those lower as `<-` assignments. That is correct for generated request ID
outputs and busy state, but it is not correct for generated completion events.

The existing IAL1 completion contract is pulse-shaped:

```text
(complete done)
```

which lowers to:

```text
(<1 (done> 1))
```

The book and spec explicitly define completion as a one-cycle delayed pulse,
and the `.fsm` backend rejects mixed pulse-delayed and non-pulse sequential
operators on one LHS. Therefore response-demux completion names must not be
implemented as ordinary sticky rule assignments.

Using a generated helper transaction as a workaround would add an extra
scheduling boundary and blur the selected response-demux contract. Emitting
raw `.fsm` or HDL from IAL2 would violate the layered lowering decision.

## Selected Next Leaf

`IAL2-FEATURE-COMPLETENESS-FRONTIER.29` should implement a minimal IAL1 rule
pulse action.

The selected public IAL1 shape for that leaf is:

```text
(rule NAME GUARD
  (pulse TARGET))
```

First-slice constraints:

- `TARGET` must be a scalar actor output or scalar actor-local generated
  signal accepted by the existing IAL1 signal model.
- The action lowers to the same `.fsm` delayed-pulse operator family as
  transaction completion:

  ```text
  (<1 (TARGET> 1))
  ```

  for actor outputs, or the equivalent non-output target token for actor-local
  generated pulse signals.
- Rule-pulse actions must participate in existing rule conflict analysis as
  pulse-domain assignments, not as ordinary sticky data writes.
- The mdBook, ISF spec, focused parser/lowerer tests, and relevant support
  docs must describe the action as a pulse action, not as a data assignment.

## Later Response-Demux Behavior Boundary

After `.29`, the generated write response-demux behavior slice can be bounded
as follows:

- add the write response ID signal, such as `axi0_bid`, as a generated IAL1
  input with the declared write ID width;
- remove generated write completion names from the authored event-input set
  under explicit `response-demux`;
- emit one generated demux rule per auto-ID write transaction:

  ```text
  (rule axi0_w0_response_demux
    (& axi0_write_complete axi0_w0_auto_id_busy_q
       (== axi0_bid axi0_w0_auto_id_q))
    (pulse axi0_w0_complete))
  ```

- keep capacity release and auto-ID release driven by the generated completion
  pulse names already present in the transaction metadata;
- add unmatched/inactive response assertions:
  `response_event -> any_active_matching_transaction`;
- set `response_demux.generated_behavior` to true and remove
  `generated_write_bid_demux` from that report residue.

Read `RID` demux, same-ID ordering queues, read-data interleaving/reassembly,
bursts, queued policy, aliases, full-manager behavior, and VHDL remain future
exact-owner work.

## Validation Gates For `.29`

Focused gates for the IAL1 pulse prerequisite should include:

```bash
prove -Iperl t/1181-isf-rule-action-boundary.t
prove -Iperl t/1168-isf-rule-guard-factoring.t t/1171-isf-rule-trigger-fanin.t
```

The implementation leaf should add its own focused rule-pulse test and run
the usual docs/continuity gates:

```bash
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

## Rollback

This audit is documentation, task-tree, mdBook, roadmap, and Knowledge Map
state only. Rolling it back only removes the selected prerequisite and returns
the frontier to generated response-demux behavior readiness.
