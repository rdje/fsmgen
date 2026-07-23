# IAL2 AHB Requester WRAP Progression Runtime Audit

Task-tree owner: `IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT.1`

Date: 2026-07-23

## Outcome

This record preserves the `.1` runtime proof of the pre-repair AHB requester
WRAP progression defect. The defect was repaired by
`IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT.2`; current behavior and
verification are documented in
`docs/IAL2_AHB_REQUESTER_WRAP_PROGRESSION_REPAIR.md`.

Before `.2`, a byte `WRAP4` command starting at address `3` had to
present accepted addresses:

```text
3, 0, 1, 2
```

The pre-repair requester instead presented:

```text
3, 1, 2, 3
```

The first wrap-to-base address was skipped. The `.1` audit changed no generator,
public source, support accounting, report schema, generated artifact contract,
or runtime behavior. It selected
`IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT.2` as the exact repair owner.

## Generated-State Root Cause

The public `ppif/ahb_requester.ppif` source lowers through
`AhbRequester.pm` to generated IAL1 and then generated IAL0. After a successful
non-final beat, the pre-repair generated IAL1 contained:

```text
when wrap_mode_q:
  when addr_q + addr_step_q == wrap_high_q:
    addr_q = wrap_base_q
  when !(addr_q + addr_step_q == wrap_high_q):
    addr_q = addr_q + addr_step_q
```

The scheduler emitted those as distinct numbered decision/set states. At the
boundary for start address `3`, byte step `1`, base `0`, and high `4`:

1. the first decision sees `3 + 1 == 4`;
2. its set state writes `addr_q = 0`;
3. the following decision re-evaluates `!(0 + 1 == 4)` as true; and
4. its set state overwrites `addr_q = 1`.

The next bus presentation therefore skipped address `0`. The pre-repair
checked-in direct seed `fsm/amba_requester.fsm` contained the same sequential
pattern in both of its successful-response progression paths.

## Runtime Proof

At commit `ec9fa2ee3`, focused audit
`t/1517-ial2-ahb-requester-wrap-progression-audit.t`:

- parses the public requester and proves the exact generated IAL1 mutation
  shape;
- proves the generated IAL0 numbered decision/set state sequence;
- generates SystemVerilog through the public CLI;
- builds `t/data/ahb_requester_wrap_progression_audit_tb.svt` with Verilator;
- issues one byte `WRAP4` command at address `3` with `HREADY=1`, `HRESP=OKAY`;
- confirms `NONSEQ` followed by three `SEQ` transfers and clean four-beat
  completion; and
- records and checks the observed `3,1,2,3` address sequence against the
  required `3,0,1,2` sequence.

The current test is intentionally inverted and extended into a correctness
regression. It must never preserve the historical bad sequence as a supported
contract.

## Affected Scope

The runtime probe was deliberately the smallest `WRAP4` reproduction. The same
pre-repair progression block was shared by `WRAP4`, `WRAP8`, and `WRAP16`, so
the root cause structurally affected every fixed wrapping mode when an
accepted beat reached the calculated high boundary. `SINGLE`, `INCR`, `INCR4`,
`INCR8`, and `INCR16` took the non-wrap path and were not affected by this
specific defect.

The one-/two-subordinate paired BUSY proofs use `INCR4`; their shipped results
remain valid. The subordinate-side byte-only WRAP policy computes its own
expected address and is not the source of this requester defect.

## Implemented `.2` Repair

`.2` replaces mutation/retest with an intentionally sequential but safe
wrap update in both `AhbRequester.pm` and both corresponding paths in
`fsm/amba_requester.fsm`:

```text
when wrap_mode_q:
  addr_q = addr_q + addr_step_q
  when addr_q == wrap_high_q:
    addr_q = wrap_base_q
```

The equality intentionally observes the just-incremented register. A
non-boundary address retains its increment; a boundary address first reaches
`wrap_high_q`, then becomes `wrap_base_q` before the next transfer drive. No
new local, public port, source clause, report field, support entry, or artifact
name is required.

Current t/1517 requires corrected generated states and exact WRAP4/8/16
address sequences across representative byte/halfword/word steps. Focused
preservation retains t/1511 `SINGLE`/`INCR4`, t/1498 BUSY insertion, paired
compositions, direct-seed SystemVerilog/VHDL lowering, and all
public/support/report contracts. See the repair record for the full result.

## Rollback

Audit rollback removes t/1517 and its testbench plus this record/fact and
restores the tree to proposed status. It does not alter the pre-existing bug.
Repair rollback restores both requester sources and the audit expectations
together; it must never leave the generated IAL2 requester and direct seed on
different wrap algorithms.
