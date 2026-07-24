# IAL2 AHB Direct Subordinate Register-Output Completion Repair

Task-tree owner: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.8`

Date: 2026-07-23

## Outcome

The direct lower-layer `fsm/ahb_lite_subordinate.fsm` now retains every
selected ready active phase accepted on successful or final-ERROR completion.
Persistent phase/storage loads use Q-named `<-`, so current completion reads
registered Q while same-edge next-phase capture writes a separate generated
`*_next` value.

The repair keeps the existing four states, eleven-signal strict-check result,
module/ports, source path, artifact, and support identity
`protocol.ahb_lite_subordinate`. It adds no pending bank, relaunch state,
report surface, HWDATA capture, extra ready-low cycle, or general queue.

This direct fixture remains separate from the generated public IAL2 AHB family
repaired by `.3`.

## Source Contract Implemented

All explicit persistent loads now use registered-output assignment:

```text
addr_q     <- HADDR
write_q    <- HWRITE
size_q     <- HSIZE
wait_ctr   <- wait_cycles
reg_data_q <- HWDATA
```

Successful address-zero word `ACCESS` completion and final
`ERROR_COMPLETE` use the same dispatcher:

```text
HSEL && HREADY && NONSEQ:
  capture HADDR/HWRITE/HSIZE/wait_cycles -> ACCESS

HSEL && HREADY && SEQ:
  capture wait_cycles -> UNSUPPORTED

IDLE/BUSY/unselected/HREADY=0:
  capture nothing -> IDLE
```

The Q/next split prevents the `.6` failure. A completing write predicate reads
registered `write_q`; the following phase's live HWRITE updates only
`write_q_next` before the edge. The current write therefore consumes its own
live data-phase HWDATA even when the same edge accepts a read.

## Ready, Response, And Data Ownership

There is no relaunch cycle. The accepted continuation enters `ACCESS` or
`UNSUPPORTED` immediately after the completion edge and uses the existing
`wait_cycles=N` policy. A held active address phase is not accepted while
ready is low; at the next ready edge it may replace the completing phase
exactly once.

HWDATA is never captured with address/control. The manager presents the next
write's HWDATA after its address acceptance and holds it across existing wait
cycles until that write's completion.

The first ERROR cycle remains `HRESP=1, HREADYOUT=0`; final
`ERROR_COMPLETE` remains `HRESP=1, HREADYOUT=1`. Active NONSEQ/SEQ on that
final edge is retained for independent evaluation. IDLE/BUSY/unselected input
cancels continuation. The prior ERROR remains exactly two cycles.

## Exact Generated-HDL Proof

t/1520 structurally proves that:

- all persistent source loads use `<-`, not `<=`;
- `write_q` lowers as `register_out` with separate `write_q_next`;
- current write completion reads Q `write_q`;
- completion capture writes next values through the selected dispatcher;
- no pending/relaunch storage or state is emitted; and
- Verilator reports no `UNOPTFLAT` warning.

Its four runtime scenarios prove:

```text
DIRECT_SUCCESS_ACTIVE_REPAIRED
  accepts=2 captures=2 completions=2 ready_low=4 errors=0
  sampled_write=0 storage=0x11111111

DIRECT_ERROR_ACTIVE_REPAIRED
  accepts=2 captures=2 completions=2 errors=2
  storage=0xaaaaaaaa

DIRECT_SUCCESS_SEQ_REPAIRED
  accepts=2 captures=2 completions=2 errors=2
  storage=0x55555555

DIRECT_ERROR_IDLE_CANCEL
  accepts=1 captures=1 completions=1 errors=2
  storage=0x00000000
```

Thus every accepted phase has exactly one capture and one completion, with at
most one storage effect. SEQ remains independently unsupported, and final
ERROR plus IDLE produces no phantom transfer.

## Preserved Boundaries

The repair does not change:

- word-only address-zero NONSEQ success, unsupported size/address/SEQ policy,
  wait counting, reset/default outputs, or two-cycle ERROR;
- direct requester/interconnect seeds;
- generated IAL2 AHB subordinate/requester/interconnect sources, reports,
  artifacts, support entries, aliases, or paired runtimes;
- public syntax, backend behavior, broader AHB, general queues/outstanding
  transfers, AXI/APB/VHDL; or
- proposed decision `0020`, which remains inactive.

## Validation

Focused repair validation:

```bash
prove -Iperl t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t
./bin/fsmgen --quiet --strict --check --json fsm/ahb_lite_subordinate.fsm
```

t/1520 passes 2/2 top-level tests in five seconds under the 4-GiB descendant
cap. t/1518 plus t/1520 pass 2 files/6 tests in five seconds. The direct strict
check reports four states, eleven signals, and matched
`protocol.ahb_lite_subordinate` support. Generated-family t/1519 preservation
passes 2/2 tests in 42 seconds, while t/248 plus t/297 pass 6,815 support and
capability assertions. mdBook build, Knowledge Map generation/check at 978
facts/4,953 question keys, memory/path/diff hygiene, and doctrine gates pass;
the disposable book output was removed.

## Rollback

Rollback restores `fsm/ahb_lite_subordinate.fsm`, t/1520, and its harness
together to commit `2738733ea`, restores the runtime-loss audit as current,
and removes this repair record/fact. It must not leave a ready completion edge
that claims acceptance without phase retention, or mix completion dispatch
with D-input-named persistent state.
