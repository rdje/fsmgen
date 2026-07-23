# IAL2 AHB Requester WRAP Progression Runtime Audit

Task-tree owner: `IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT.1`

Date: 2026-07-23

## Outcome

The suspected AHB requester WRAP progression defect is runtime-confirmed in
generated SystemVerilog. A byte `WRAP4` command starting at address `3` must
present accepted addresses:

```text
3, 0, 1, 2
```

The shipped requester instead presents:

```text
3, 1, 2, 3
```

The first wrap-to-base address is skipped. This audit changes no generator,
public source, support accounting, report schema, generated artifact contract,
or runtime behavior. It selects
`IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT.2` as the exact repair owner.

## Generated-State Root Cause

The public `ppif/ahb_requester.ppif` source lowers through
`AhbRequester.pm` to generated IAL1 and then generated IAL0. After a successful
non-final beat, the generated IAL1 currently contains:

```text
when wrap_mode_q:
  when addr_q + addr_step_q == wrap_high_q:
    addr_q = wrap_base_q
  when !(addr_q + addr_step_q == wrap_high_q):
    addr_q = addr_q + addr_step_q
```

The scheduler emits those as distinct numbered decision/set states. At the
boundary for start address `3`, byte step `1`, base `0`, and high `4`:

1. the first decision sees `3 + 1 == 4`;
2. its set state writes `addr_q = 0`;
3. the following decision re-evaluates `!(0 + 1 == 4)` as true; and
4. its set state overwrites `addr_q = 1`.

The next bus presentation therefore skips address `0`. The checked-in direct
seed `fsm/amba_requester.fsm` contains the same sequential pattern in both of
its successful-response progression paths.

## Runtime Proof

Focused audit `t/1517-ial2-ahb-requester-wrap-progression-audit.t`:

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

The test passes as a defect-reproduction audit. The repair leaf must invert it
into a correctness regression; it must not preserve the bad sequence as a
supported contract.

## Affected Scope

The runtime probe is deliberately the smallest `WRAP4` reproduction. The same
generated progression block is shared by `WRAP4`, `WRAP8`, and `WRAP16`, so
the root cause structurally affects every fixed wrapping mode when an accepted
beat reaches the calculated high boundary. `SINGLE`, `INCR`, `INCR4`, `INCR8`,
and `INCR16` take the non-wrap path and are not affected by this specific
defect.

The one-/two-subordinate paired BUSY proofs use `INCR4`; their shipped results
remain valid. The subordinate-side byte-only WRAP policy computes its own
expected address and is not the source of this requester defect.

## Selected `.2` Repair

`.2` must replace mutation/retest with an intentionally sequential but safe
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

The repair must update t/1517 to require the corrected generated states and
address sequence, widen runtime coverage across the shared fixed-wrap path as
warranted, preserve t/1511 `SINGLE`/`INCR4`, t/1498 BUSY insertion,
t/1513/t1515 paired compositions, direct-seed SystemVerilog/VHDL lowering, and
all public/support/report contracts. It must run public requester
`--verify-hdl`, focused tests, docs/Knowledge Map/memory gates, and doctrine
checks under the documented resource monitor.

## Rollback

Audit rollback removes t/1517 and its testbench plus this record/fact and
restores the tree to proposed status. It does not alter the pre-existing bug.
Repair rollback restores both requester sources and the audit expectations
together; it must never leave the generated IAL2 requester and direct seed on
different wrap algorithms.
