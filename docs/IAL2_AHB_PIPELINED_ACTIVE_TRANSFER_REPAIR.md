# IAL2 AHB Pipelined Active-Transfer Repair

Task-tree owner: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.3`

Date: 2026-07-23

## Outcome

The generated public AHB endpoint/composition family now preserves every
selected ready `NONSEQ` or `SEQ` address phase through the bounded pipeline
that the bus exposes. A generated subordinate has one accepted address/control
bank, a generated requester separates address acceptance from data completion,
and a generated interconnect retains the accepted subordinate as data-phase
response owner. Together those three pieces allow consecutive active address
phases without an artificial `IDLE`, `BUSY`, or unselected boundary.

The repair changes no public IAL2 source syntax, port, source/support identity,
artifact name, selected transfer/burst policy, or direct lower-layer `.fsm`
seed. It is a depth-one protocol pipeline, not a general transaction queue,
multi-manager fabric, or activation of decision `0020`.

## Generated Subordinate Phase Bank

`FSM::IAL2::ProtocolIntent::AhbSubordinate` now emits one reset-clean pending
bank:

```text
ahb_phase_pending_q
next_addr_q
next_write_q
next_size_q
next_trans_q
next_burst_q       # only when HBURST is exposed
next_wait_n
```

`ahb_phase_capture` accepts a phase only when the bank is empty and
`HSEL && HREADY && HTRANS in {NONSEQ, SEQ}`. It captures `HADDR`, `HTRANS`,
optional `HBURST`, `HWRITE`, `HSIZE`, and fixture-local `wait_cycles`, then
drives `HREADYOUT=0`, `HRESP=OKAY`, and neutral `HRDATA` for the accepted
phase's data cycle. `ahb_phase_hold` retains that not-ready/OKAY/neutral state
while the bank is pending. The transaction consumes the bank once and clears
its pending flag before applying the existing wait, storage, sequence, burst,
and response policy.

`HWDATA` is deliberately not banked. It belongs to the data phase after the
captured address edge and remains live and stable while `HREADY` is low. The
subordinate consumes it only on the captured write's successful completion.

The former `ahb_access_active_q` boundary latch is gone. A final two-cycle
ERROR may therefore retire to the default OKAY state through
`ahb_error_retire`; if that final ready edge also carries a selected active
phase, `ahb_phase_capture` has priority and retains it. Final ERROR plus `IDLE`
captures nothing.

The schedule report exposes this additive contract at `phase_pipeline`:

```text
selected = true
mode = one_accepted_next_address_control
accepted_next_capacity = 1
write_data.policy = live_data_phase_held_while_stalled
overflow = stall_before_another_acceptance
```

## Generated Requester Phase Ownership

Preservation exposed that the generated requester previously held an accepted
active address presentation until the later data response. That is not a valid
source for an overlapped AHB pipeline: the accepted address phase must retire
while its data phase remains outstanding.

`FSM::IAL2::ProtocolIntent::AhbRequester` now emits separate reset-clean
address, data, and captured-response state:

```text
ahb_address_pending_q
ahb_data_pending_q
ahb_response_pending_q
ahb_response_q
ahb_read_data_q
```

On `HGRANT && HREADY`, `ahb_address_accept` moves ownership from address to
data and immediately drives `HTRANS=IDLE`. On the later ready edge,
`ahb_response_capture` records `HRESP` and `HRDATA`. The transaction consumes
that captured response once before advancing address, beat counters, status,
or retry/error state. SINGLE, INCR4, WRAP4/8/16, and one-BUSY insertion retain
their existing command/status results while no longer presenting an already
accepted address as active throughout the data wait.

## Generated Interconnect Data-Phase Owner

Once the requester correctly retires `HTRANS`, the generated interconnect
cannot select the response using the current address phase alone. It now emits
one reset-clean one-hot `ahb_data_owner_N_q` bit per subordinate window.

A ready mapped active address acceptance records the corresponding owner.
`HREADY`, `HRESP`, and `HRDATA` are muxed from that retained owner until its
data phase completes, independent of the requester's current `HTRANS` and
`HADDR`. A completion edge clears the owner; if the same edge accepts another
mapped active address, that acceptance atomically replaces it. Current-phase
decode, child select/local-address generation, and the existing two-cycle
unmapped ERROR path remain otherwise unchanged.

The aggregate report adds:

```text
composition.response_mux.data_phase_owner.selected = true
composition.response_mux.data_phase_owner.mode = one_hot_accepted_subordinate
composition.response_mux.data_phase_owner.response_mux = retained_owner_ready_response_read_data
composition.response_mux.data_phase_owner.same_edge_replacement = completion_with_accepted_active_address_replaces_owner
```

## Runtime Proof

Generated-HDL t/1519 exercises the repaired subordinate directly:

- boundary-free `NONSEQ` address 0 then `SEQ` address 1 produces exactly two
  acceptances, two captures, two completions, and storage `0x00002211`;
- final ERROR followed by an active supported `NONSEQ` has exactly two ERROR
  cycles, captures and completes the continuation, and leaves storage `0xaa`;
- final ERROR followed by `IDLE` has exactly two ERROR cycles, captures no
  continuation, and causes no storage effect.

The preserved one-requester/one-subordinate paired generated-HDL proof t/1513
still records five active presentations, four completed beats, one BUSY phase,
and storage `0x44332211`. The two-subordinate t/1515 proof still records two
commands, ten active presentations, eight completed beats, two BUSY phases,
and subordinate storage/status values `0x44332211` and `0x88776655`.
Requester-only tests retain the bounded SINGLE, INCR4, WRAP4/8/16, and BUSY
results; one- and two-window interconnect tests retain mapped and unmapped
behavior; `.ahb` aliases continue through the same generators.

## Boundaries And Deferrals

The shipped capacity is exactly one accepted pending address/control phase per
subordinate and one retained data owner in the selected static-window fabric.
Driving ready low before another acceptance is the overflow policy. This work
does not implement multiple outstanding transfers, deeper request/response
queues, multiple managers, arbitrary fabrics, broader optional AHB signals,
policy-driven or multiple BUSY insertion, a distinct local bus-BUSY status,
larger/indefinite bursts, or a transaction-level API.

The generated requester's local command/status surface remains the useful seed
for the proposed protocol-neutral transaction-layer direction in decision
`0020`, but that direction remains proposed and inactive. The direct
`fsm/amba_requester.fsm`, `fsm/amba_requester2.fsm`, and
`fsm/ahb_lite_subordinate.fsm` seeds are unchanged; task-tree leaf `.4` owns
their separate phase-contract audit.

The interconnect still owns its selected two-cycle unmapped ERROR behavior.
This repair does not promise a general pipeline from an owned mapped data phase
directly into a next unmapped address phase.

## Rollback

Rollback must restore the subordinate phase bank, requester address/data
ownership, and interconnect retained data owner as one coupled generated
contract, together with t/1519, paired preservation expectations, report
fields, current documentation, and Knowledge Map facts. Rolling back only one
of the three generated roles would recreate either a dropped address phase, a
repeated accepted presentation, or a response/data mux timing error.
