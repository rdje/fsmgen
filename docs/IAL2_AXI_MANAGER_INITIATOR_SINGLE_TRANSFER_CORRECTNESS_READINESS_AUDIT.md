# IAL2 AXI manager initiator — single-transfer correctness readiness audit

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.6` (no-behavior readiness audit).
Status: audit complete; implementation is owned by `.7`.

This audit resolves the correctness prerequisite selected in `.5`. It traces
why the shipped AW driver can accept twice, evaluates correction layers, and
proves an existing-ISF shape that produces exactly one accepted transfer per
accepted command without bypassing the generated review-artifact chain.

## Outcome

**Select a priority-resolved two-rule handoff in generated ISF.** The command
transaction samples the payload and emits a one-state inline launch signal.
A `launch_aw` rule registers the payload, raises `AWVALID`/`aw_busy`, and sets
an internal `active_q`. An `accept_aw` rule guarded by
`(& awvalid awready)` clears `AWVALID`, `aw_busy`, and `active_q` on the same
rising edge that accepts the transfer. Explicit
`(priority accept_aw over launch_aw)` resolves all shared rule writes.

The transaction waits on latched `active_q`, not directly on `AWREADY`, so a
one-cycle `AWREADY` pulse cannot be lost while control advances through its
scheduled loop states. This shape uses the existing IAL2 -> generated `.isf`
-> generated `.fsm` -> HDL path. It needs no parser, ISF scheduler, IAL0, or
backend change.

The exact next behavior owner is
`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.7`.

## Root cause in the shipped shape

The shipped generated ISF has this sequence:

```lisp
(drive assert_aw)
(while (! awready)
  (drive assert_aw))
(drive deassert_aw)
(complete aw_done)
```

An ISF named drive call consumes one state and its `<-` assignments update
registered outputs on the following edge. The generated loop decision can
select `aw_issue_drive_5` when `AWREADY` is high, but
`deassert_aw_start` is not active until that new state executes. Registered
`AWVALID` therefore clears one edge later. With `AWREADY` held high, both the
edge entering the deassert state and the following edge see
`AWVALID && AWREADY`, yielding two accepted AW transfers from one command.

The generated-artifact trace is:

```text
aw_issue_drive_1          assert_aw_start = 1
aw_issue_while_entry_2    AWREADY decision
aw_issue_drive_5          deassert_aw_start = 1
aw_issue_done_6           completion state
```

`--verify-hdl` remains valuable: the shipped result passes Verilator lint and
Yosys synthesis. Those tools do not establish transfer cardinality.

## Candidate comparison

| Candidate | Evidence | Disposition |
| --- | --- | --- |
| Keep the post-loop named deassert drive | Registered deassert occurs one edge after the READY decision; the executable baseline probe counts two acceptances under continuously-high READY. | Rejected. |
| Assert once with the named drive; clear from an `accept_aw` rule; wait on `aw_busy` | Functional simulation passes, but schedule JSON reports two `isf_unproven_rule_drive_overlap` warnings because the compiler cannot prove the rule and named drive mutually exclusive. | Not selected; avoid knowingly shipping a warning when a clean existing-language shape is available. |
| Inline launch handoff + priority-resolved `launch_aw`/`accept_aw` rules + `active_q` loop | Schedule JSON has `compile_issues: []`; three rule-priority resolutions cover `active_q`, `aw_busy`, and `awvalid`; generated HDL has six states; lint, synthesis, continuous-READY simulation, stalled payload stability, and one-cycle READY simulation pass. | **Selected.** |
| Change generic `while` lowering to fuse the successor drive into its decision state | Alters timing semantics for all ISF loop users and requires broad scheduler regression work. | Rejected as disproportionate. |
| Add a new atomic Valid-Ready ISF construct | Could express the operation, but expands language/parser/scheduler surface when shipped rules, priority, inline drive, and wait already suffice. | Deferred; no demonstrated need. |
| Patch generated `.fsm` or the direct backend | Can clear on the acceptance edge but bypasses the mandatory generated-IAL1 ownership point and duplicates protocol behavior below IAL2. | Rejected by decision `0014`. |

## Selected generated-ISF shape

The behavior owner must emit this scheduling structure while preserving the
existing public command/channel interface and sampled payload names:

```lisp
(priority accept_aw over launch_aw)

(rule launch_aw launch_aw_start
  (set active_q 1)
  (set aw_busy 1)
  (set awvalid 1)
  (set awaddr addr_q)
  (set awid id_q)
  (set awlen len_q)
  (set awsize size_q)
  (set awburst burst_q))

(rule accept_aw (& awvalid awready)
  (set active_q 0)
  (set aw_busy 0)
  (set awvalid 0))

(transaction aw_issue
  (on aw_cmd_valid
    (sample cmd_awaddr as addr_q)
    (sample cmd_awid as id_q)
    (sample cmd_awlen as len_q)
    (sample cmd_awsize as size_q)
    (sample cmd_awburst as burst_q))
  (drive
    (launch_aw_start 1))
  (while active_q
    (wait 1))
  (complete aw_done))
```

The inline drive makes `launch_aw_start` a combinational, state-scoped
handoff. `launch_aw` consumes the samples captured on command acceptance and
registers the public outputs. Once `AWVALID` is high, `accept_aw` observes the
same `AWVALID && AWREADY` predicate used to count the bus acceptance and
schedules the three clears for that edge. The latched `active_q = 0` records
the acceptance for the transaction loop even if `AWREADY` drops immediately.

The rule priority is both documentary and mechanical. Schedule JSON reports
priority resolution with `accept_aw` winning over `launch_aw` for
`active_q`, `aw_busy`, and `awvalid`; it reports no compile issues. Generated
SystemVerilog retains the selector assertions for those shared targets.

## Executable proof

A temporary candidate source was lowered through the ordinary ISF pipeline:

```bash
./bin/fsmgen --quiet --emit-schedule-json \
  /tmp/fsmgen-axi-aw-rule-pair/axi_aw_driver_rule_pair_candidate.isf
./bin/fsmgen --verify-hdl \
  --output /tmp/fsmgen-axi-aw-rule-pair/axi_aw_driver_rule_pair_candidate.sv \
  /tmp/fsmgen-axi-aw-rule-pair/axi_aw_driver_rule_pair_candidate.isf
```

Observed results:

- schedule JSON: `state_count: 6`, `compile_issues: []`, and three expected
  `priority_resolutions`;
- Verilator lint: PASS;
- Yosys synthesis: PASS;
- generated selector assertions enabled during executable simulation: PASS.

A temporary rising-edge-counting Verilator harness then ran two commands:

1. `AWREADY` high before and throughout the command;
2. `AWREADY` low while `AWVALID` and all AW payload fields were checked stable
   for four cycles, followed by a one-cycle `AWREADY` pulse.

The final result was:

```text
PASS handshakes=2 done_pulses=2
```

Thus each of the two accepted commands produced exactly one bus acceptance
and one one-cycle completion pulse. Both cases returned `AWVALID` and
`aw_busy` low. The one-cycle READY case also proves that transaction control
does not depend on seeing READY again after the acceptance edge.

## `.7` implementation and regression contract

The next leaf is a bounded correction, not a new public feature:

1. Change only `_emit_isf` in
   `perl/FSM/IAL2/ProtocolIntent/AxiAwDriver.pm` to emit the selected priority,
   two rules, inline launch handoff, and `active_q` wait loop.
2. Keep the `.ppif` clause, module name, result kind, schema, bindings, signal
   widths, payload fields, support-accounting ID, capability surface, and
   unsupported residue unchanged.
3. Update `t/1499-ial2-axi-aw-driver.t` structural assertions to require the
   selected ISF shape, absence of the post-loop named deassert pattern, empty
   schedule compile issues, and the expected priority resolutions.
4. Add an executable generated-HDL cardinality subtest. It must count
   rising-edge `AWVALID && AWREADY` acceptances and `aw_done` pulses for both
   continuously-ready and stalled/one-cycle-ready commands, assert payload
   stability during the stall, assert exactly one acceptance and one done
   pulse per accepted command, and assert final `AWVALID = aw_busy = 0`.
5. Run the focused test, strict check/report/export paths, `--verify-hdl`, the
   mdBook build, and doctrine gates. Update the AXI chapter from a known
   boundary to the corrected guarantee in the same commit.

## Explicit boundary

This audit does not change behavior. `.7` does not add W-channel source
syntax, AW/W composition, multi-beat sequencing, B response completion,
outstanding transactions, AR drive, burst/address generation, capacity-core
integration, profile aliases, verification-output generation, backend
variants, AHB/APB behavior, or VHDL behavior. W remains the next functional
direction after the AW single-transfer correction lands.
