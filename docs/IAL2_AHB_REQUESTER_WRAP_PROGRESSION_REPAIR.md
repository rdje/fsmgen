# IAL2 AHB Requester WRAP Progression Repair

Task-tree owner: `IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT.2`

Date: 2026-07-23

## Outcome

The generated AHB requester and checked-in direct requester seed now advance
fixed wrapping bursts to the wrap base at the high boundary. The repair keeps
the public `.ppif`/`.ahb` syntax, ports, report schemas, support accounting,
artifact identities, and non-wrap progression unchanged.

Generated-HDL correctness coverage proves these accepted-address sequences:

| Command | Start | Accepted addresses |
|---|---:|---|
| byte `WRAP4` | `3` | `3, 0, 1, 2` |
| halfword `WRAP4` | `6` | `6, 0, 2, 4` |
| word `WRAP4` | `12` | `12, 0, 4, 8` |
| byte `WRAP8` | `7` | `7, 0, 1, 2, 3, 4, 5, 6` |
| byte `WRAP16` | `15` | `15, 0, 1, ..., 14` |

Each command presents one `NONSEQ` transfer followed by the required number
of `SEQ` transfers and completes without error, retry, or split status.

## Repair Shape

The `.1` audit proved that the old path wrote `wrap_base_q` and then
re-evaluated a negated predicate against the mutated address, overwriting the
base with base-plus-step. `.2` replaces that mutation/retest pair with a safe
sequential update:

```text
when wrap_mode_q:
  addr_q = addr_q + addr_step_q
  when addr_q == wrap_high_q:
    addr_q = wrap_base_q
```

The equality intentionally observes the just-incremented `addr_q`. A
non-boundary value retains the increment. At the high boundary, the second
assignment replaces that value with `wrap_base_q` before the next bus
transfer.

The same algorithm is present in:

- `perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm`, which emits the public AHB
  requester IAL1/IAL0 pipeline; and
- both successful-response progression paths in `fsm/amba_requester.fsm`,
  which keeps the direct seed aligned with generated requester behavior.

The non-wrap branch still increments `addr_q` once. No burst admission,
terminal-count, data progression, or BUSY-insertion rule changed.

## Runtime And Preservation Proof

`t/1517-ial2-ahb-requester-wrap-progression-audit.t` now requires the repaired
IAL1/IAL0/direct-seed structure and builds one generated SystemVerilog binary
that executes the five commands above. It fails on an omitted base address,
wrong step, wrong `HTRANS` sequence, extra/missing beat, or non-clean
completion.

Focused preservation also covers:

- `t/1473`, the public requester contract and artifact surfaces;
- `t/1498`, requester BUSY insertion;
- `t/1511`, `SINGLE` and `INCR4` completion;
- `t/310`, direct-seed SystemVerilog width/grouping and the new post-increment
  comparison shape;
- `t/1420`, direct-seed VHDL lowering;
- strict checking of `ppif/ahb_requester.ahb`; and
- public requester `--verify-hdl` through Verilator and Yosys.

The already-shipped one- and two-subordinate paired BUSY compositions remain
`INCR4` paths and therefore do not use fixed-wrap address progression. Their
generated-HDL runtime gates are retained as preservation checks for the shared
requester architecture. t/1513 and t/1515 pass together (two files, seven
top-level tests), covering both paired topologies after the repair.

## Scope Boundaries

This slice repairs the existing bounded requester fixed-wrap modes only. It
does not add larger or indefinite bursts, boundary-free pipelining, new BUSY
policy/status, optional AHB signals, subordinate/interconnect behavior,
AXI/APB behavior, or the proposed transaction-layer horizon in decision
`0020`.

## Rollback

Rollback must restore `AhbRequester.pm`, both direct-seed progression paths,
and t/1517 together. Restoring only one requester representation would create
generated/direct drift; restoring the old test expectation would incorrectly
turn a known defect into a supported contract.
