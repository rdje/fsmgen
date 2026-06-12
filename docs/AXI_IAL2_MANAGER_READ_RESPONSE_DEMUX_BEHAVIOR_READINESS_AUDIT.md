# AXI IAL2 Manager Read Response Demux Behavior Readiness Audit

Status: readiness audit complete; generated behavior remains unchanged in this
slice.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.40`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

This audit follows the parser/report metadata boundary shipped in
[docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md](AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md).

## Conclusion

Generated single-beat read `RID` response-demux behavior can be implemented
directly in the next slice. No new IAL1, IAL0, or SystemVerilog prerequisite is
required.

The selected next owner is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.41
```

That implementation leaf must generalize the existing generated write
response-demux helpers from write-only to per-family read/write behavior. It
also owns the read completion fan-in and auto-ID release shift created by the
explicit read `response-demux` opt-in: the logical read transaction completion
names become generated pulse outputs, while the top-level `read-complete`
event becomes the raw accepted response input.

The next slice is still bounded to the selected public contract:
single-beat/non-burst read responses. Read-data payload capture, read-data
interleaving/reassembly, `RLAST`, bursts, per-ID response queues,
queued/blocking policy, full AXI manager behavior, and VHDL remain residue.

## Evidence Read

- `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `perl/FSM/Adapter/IAL2/PPIF.pm`
- `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md`
- `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_READINESS_AUDIT.md`
- `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md`
- `docs/AXI_IAL2_MANAGER_AUTO_ID_REQUEST_ID_DRIVE_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md`
- `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`
- `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`
- `docs/book/src/13g-rules.md`
- `docs/book/src/14-feature-backlog.md`
- `ppif/axi_manager_capacity_status_read_response_demux.ppif`
- `ppif/axi_manager_capacity_status_response_demux.ppif`
- `t/1437-axi-ial2-manager-capacity-status-generator.t`
- `t/1436-ial2-ppif-parser-cli.t`

The baseline command:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux.ppif
```

confirms the `.39` state: `response_demux.read.generated_behavior` is false,
`axi0_rid` is reported as a future generated input, the read completion names
still appear as authored event inputs, and generated `.isf`, `.fsm`, and HDL
behavior are unchanged.

## Substrate That Already Fits

The existing read metadata contains the same facts the write behavior consumes:

- `response_demux.read.response_event` is the raw accepted read response
  event;
- `response_demux.read.response_id_signal` is the generated `RID` input;
- `response_demux.read.auto_transactions` identifies the logical read
  transactions to demux;
- `auto_id_lifecycle` already provides each read transaction's selected-ID
  register and busy state;
- `transaction_event_dispatch` and the capacity rules already consume each
  logical read transaction completion event;
- IAL1 `(pulse TARGET)` rule actions already lower to the required one-cycle
  pulse form through `.fsm` and SystemVerilog.

The write demux path proves the required shape:

```text
(rule axi0_w0_response_demux
  (& axi0_write_complete axi0_w0_auto_id_busy_q
     (== axi0_bid axi0_w0_auto_id_q))
  (pulse axi0_w0_complete))
```

The read behavior can use the same layered lowering shape:

```text
(rule axi0_r0_response_demux
  (& axi0_read_complete axi0_r0_auto_id_busy_q
     (== axi0_rid axi0_r0_auto_id_q))
  (pulse axi0_r0_complete))
```

That keeps generated behavior on the required
`IAL2 -> IAL1 -> IAL0 -> SystemVerilog` path.

## Required Implementation Adjustments

The next leaf must make the response-demux helpers family-aware instead of
write-only:

- generated completion signal detection must include generated read completion
  pulses so those names are not emitted as authored inputs;
- response-event input detection must add the raw read response event when
  read demux generates behavior;
- response-ID input emission must add `RID` with the declared read ID width;
- completion-output emission must include generated read completion pulse
  outputs;
- demux rule generation must iterate over read and write auto-ID transaction
  states;
- demux assertion generation must emit read active-match and unique-match
  assertions as read assertions, not write assertions;
- report artifacts must be per family so mixed write/read contracts list read
  and write generated rules, completion signals, and assertions under their
  own arms.

Capacity release and auto-ID release do not need a separate prerequisite. The
existing capacity and lifecycle rules already consume the transaction
completion names. Once generated read demux removes those names from authored
inputs and emits them as pulse outputs, the existing completion fan-in and
release paths consume the generated pulses.

## Selected `.41` Behavior Boundary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.41` should implement:

- one generated IAL1 input for the read response ID signal, for example
  `axi0_rid`;
- one generated IAL1 output per selected read auto-ID transaction completion
  name, for example `axi0_r0_complete`;
- one generated read demux rule per selected read auto-ID transaction using
  `(pulse COMPLETION)`;
- read active-match assertion:
  `read_response_event -> any_active_matching_read_transaction`;
- read unique-match assertions for pairs of active read auto-ID transactions;
- generated `.fsm` pulse carriers and SystemVerilog reachability through the
  existing lowering path;
- schedule/report JSON with `response_demux.read.generated_behavior: true`
  and per-family generated rules, completion signals, and assertions;
- residue alignment that removes `generated_read_rid_demux` from
  `response_demux.residue` after the generated read behavior ships.

The leaf must keep the explicit non-goals visible in docs and reports:
read-data interleaving/reassembly, bursts/`RLAST`, per-ID response queues,
queued/blocking policy, profile aliases, full-manager behavior, direct
IAL2-to-backend generation, and VHDL.

## Report Expectations

After `.41`, a read-only response-demux contract should report the read arm as
generated behavior:

```text
response_demux:
  mode: bounded_response_demux_contract
  generated_behavior: true
  read:
    mode: bounded_read_rid_demux_contract
    generated_behavior: true
    response_event: axi0_read_complete
    response_event_role: raw_accepted_read_response
    response_scope: single_beat
    response_id_signal: axi0_rid
    response_id_direction: generated_input
    transaction_completion_source: generated_demux
    generated_completion_signals:
      - axi0_r0_complete
      - axi0_r1_complete
    generated_rules:
      - axi0_r0_response_demux
      - axi0_r1_response_demux
    generated_assertions:
      - axi0_read_response_demux_active_match
      - axi0_r0_r1_read_response_demux_unique_match
  residue:
    - read_data_interleaving
    - bursts
```

For mixed write/read contracts, the write arm keeps its shipped behavior and
the read arm gains the generated read behavior. Report residue should still
avoid claiming read-data payload ordering, interleaving, or burst support.

`same_id_ordering.families[].response_demux_covered` may become true for the
generated read auto-ID family once read demux is generated for that family.
`auto_id_lifecycle.residue` and `id_response_rule_engine.residue` may remove
covered `response_demux` residue only when all relevant response-demux arms for
their reported generated families are covered.

## Validation Gates For `.41`

The behavior leaf should run focused parser/generator and public sample gates:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t
prove -Iperl t/1436-ial2-ppif-parser-cli.t
./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_read_response_demux.ppif
```

The broader public-contract gates should include support accounting, language
surface, check JSON, semantic JSON, mdBook, Knowledge Map, memory architecture,
and diff hygiene:

```bash
prove -Iperl t/297-capability-manifest.t t/317-language-surface-contract.t
prove -Iperl t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

## Rollback

This `.40` slice changes only documentation, task-tree, mdBook, roadmap,
Memory, and Knowledge Map state. Rolling it back returns the active frontier
to generated read `RID` response-demux behavior readiness and leaves shipped
parser/report metadata untouched.
