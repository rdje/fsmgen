# IAL2 AHB Pipelined Active-Transfer Contract Selection

Task-tree owner: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.2`

Date: 2026-07-23

Implementation status: `.3` now implements this contract as the coupled
generated-role repair documented in
`docs/IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_REPAIR.md`. The selection below remains
the durable rationale and boundary.

## Outcome

The selected repair for the generated public AHB subordinate family is a
depth-one accepted-address/control phase bank. When the current data phase
completes and the bus simultaneously accepts a selected `NONSEQ` or `SEQ`
address phase, the subordinate must capture that next phase at the acceptance
edge, drive the following data phase not-ready, and relaunch the captured
transfer after the current generated transaction has drained its internal FSM
tail.

This is required protocol bookkeeping, not a general outstanding-transfer
queue. At most one accepted next phase can exist: after its acceptance the
subordinate drives `HREADYOUT` low, so a compliant bus cannot accept another
address phase until the banked transfer completes.

The implementation owner is
`IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.3`. It may change the shared
`FSM::IAL2::ProtocolIntent::AhbSubordinate` generator, generated review
artifacts, report data, tests, current behavior documentation, and the mdBook.
It must not change public source syntax, ports, source/support identities,
artifact names, burst policy, decision 0020, or the separate direct lower-layer
seed `fsm/ahb_lite_subordinate.fsm`.

No parser, generator, public source, report, support-accounting, generated
artifact, HDL/runtime, AXI, APB, VHDL, or transaction-layer behavior changes in
this contract-selection slice.

## Evidence And Timing Reconciliation

The `.1` generated-HDL audit presents `NONSEQ` address 0 followed immediately
by `SEQ` address 1. It observes:

```text
first bus acceptance   = cycle 0
second bus acceptance  = cycle 37
internal done pulse    = cycle 48
bus acceptances        = 2
internal admissions    = 1
internal completions   = 1
```

The current generated IAL1 drives a successful or final-ERROR
`HREADYOUT = 1` response before its transaction reaches the generated FSM done
tail. The `ahb_access_done_q` pulse is therefore eleven observed cycles after
the second address phase has already been accepted. Clearing ownership or
sampling new address/control on that delayed pulse cannot recover the accepted
phase.

The relevant event is instead the rising clock edge on which all of these are
true:

```text
HSEL == 1
HREADY == 1
HTRANS == NONSEQ || HTRANS == SEQ
```

When no transfer is internally owned, that event is a direct admission into
the current phase bank. When a current transfer is still draining and the next
bank is empty, the same event is an atomic recapture into the next phase bank.
The current response remains the response sampled at that edge; the newly
accepted transfer owns the following data phase.

## Selected State Contract

The generated subordinate will have two logical address/control banks:

| Bank | Meaning | Lifetime |
| --- | --- | --- |
| current | Address/control of the transaction being evaluated or draining | Direct admission or queued relaunch through its one completion |
| next | Exactly one bus-accepted address/control phase waiting behind current | Acceptance at a current completion edge through atomic relaunch |

The implementation may choose mechanically appropriate internal identifiers,
but the selected model is equivalent to:

```text
current: addr_q, trans_q, optional burst_q, write_q, size_q, wait_n
next:    next_addr_q, next_trans_q, optional next_burst_q,
         next_write_q, next_size_q, next_wait_n, ahb_next_pending_q
```

Reset clears current ownership, the next-pending flag, the internal completion
pulse, and the existing burst-continuation state. No stale bank contents are
observable when their valid/ownership flag is clear.

### Direct admission

With no current owner and no accepted next phase, an accepted active phase is
sampled directly into the current bank, claims current ownership, and drives
`HREADYOUT` low for its data phase. The transfer then follows the existing
wait, access, response, storage, and completion policy.

### Completion-edge recapture

While current ownership remains set and the next bank is empty, an accepted
active phase is sampled atomically into the next bank. The post-edge output for
the new data phase is `HREADYOUT = 0`, `HRESP = OKAY`, and neutral `HRDATA`
until the queued transfer reaches its selected response path. This post-edge
not-ready drive must have sufficient generated priority that the current
transaction's just-completed ready drive cannot overwrite it.

The accepted next phase is counted once at this edge. A held phase is not
sampled again because `HREADY` is low while the next bank is pending.

### Relaunch

After the current generated transaction reaches its internal terminal point,
the next bank moves atomically into the current bank, its pending flag clears,
current ownership remains continuous, and the banked transfer starts without
requiring a second bus acceptance. Its data phase is already in progress and
stalled by `HREADYOUT = 0`.

The relaunch is not a new admission count. Each bus acceptance must produce
exactly one later internal completion, one response completion, and at most one
storage effect.

## Address/Control And Data Ownership

At each direct admission or completion-edge recapture, the subordinate samples
the address-phase values that exist in the selected source variant:

- `HADDR`;
- `HTRANS`;
- `HBURST` when the variant exposes it;
- `HWRITE`;
- `HSIZE`;
- the fixture-local `wait_cycles` control.

These values move together as one phase. A queued transfer must never combine
the address from one accepted edge with control from another.

`HWDATA` is deliberately not part of either address/control bank. On AHB it is
data-phase data. At the edge that accepts a next write address, `HWDATA` still
belongs to the completing current write. After that edge the manager presents
the next write's data and holds it while `HREADY` is low. The subordinate
therefore consumes live `HWDATA` only on that banked write's successful
completion edge. Existing read-data ownership is symmetric: `HRDATA` becomes
valid for a successful read only in its final ready/OKAY data-phase cycle.

## Sequence And Burst Continuity

The current transfer commits its existing sequence-history result before the
banked phase is evaluated:

- a successful non-final supported burst beat arms or advances history;
- a final beat clears history;
- an error clears history;
- a new `NONSEQ` establishes a new sequence independently;
- a queued `SEQ` is checked later against the committed prior history,
  including `HBURST`, `HWRITE`, `HSIZE`, expected address, and beat count for
  the variants that implement those fields.

This ordering preserves the existing bounded byte-lane, in-word `SEQ`, HBURST,
and BUSY-parking policies. The repair changes phase retention only; it does not
widen which sizes, addresses, burst modes, or continuation shapes are legal.

## IDLE, BUSY, Selection, And Error Policy

An unselected, `IDLE`, or `BUSY` phase is not an active address-phase
acceptance and is never placed in the next bank. Existing zero-wait response,
history-clear, and BUSY-park policies remain variant-specific and unchanged.

For the final cycle of a two-cycle ERROR response:

- `HREADY = 1` plus `HTRANS = IDLE` means the manager canceled the already
  presented next transfer; nothing is captured;
- a selected active `NONSEQ` or `SEQ` is a bus acceptance and must be captured;
- existing error history clearing happens before that captured phase is later
  evaluated, so a continued `SEQ` can independently receive its own ERROR but
  cannot disappear;
- a supported captured `NONSEQ` starts a new independent transfer normally.

This follows the source-backed AHB reason for the two-cycle ERROR response: the
manager has an opportunity to cancel the next transfer, but cancellation is
not mandatory.

## Ready, Response, And Capacity Invariants

The implementation must preserve all of these invariants:

1. A phase is accepted only on `HSEL && HREADY && active HTRANS`.
2. Every accepted active phase is retained exactly once.
3. `HREADYOUT` is low after a next phase is accepted and stays low until that
   phase reaches its selected completion response.
4. No third phase can be accepted while the next bank is full.
5. The completion edge reports only the current transfer's `HRESP`/`HRDATA`;
   the next transfer cannot contaminate that response.
6. Each acceptance produces exactly one later OKAY or final-ERROR completion.
7. Each successful write changes storage exactly once; failed writes never
   change storage.
8. Reset or a non-accepted boundary cannot manufacture an admission or
   completion.

The capacity is therefore one current transfer plus one accepted next phase,
but never two independently executing or arbitrated outstanding transfers.

## Report And Documentation Contract

The implementation adds an additive generated-report policy object equivalent
to:

```text
phase_pipeline:
  selected: true
  mode: one_accepted_next_address_control
  accepted_next_capacity: 1
  acceptance: HSEL && HREADY && active HTRANS
  captures: HADDR, HTRANS, optional HBURST, HWRITE, HSIZE, wait_cycles
  write_data: live data-phase HWDATA held while stalled
  overflow: stall before another acceptance
```

Exact serialized field spelling is owned by `.3`, but it must be one shared
subordinate-report contract, cloned naturally into aggregate child reports.
The existing `fsmgen.ial2.protocol_intent.ahb_subordinate.v1` schema identifier
remains unchanged because the field is additive. Output-default metadata,
source objects, bindings, transfer policies, artifact names, and support IDs
remain unchanged.

Current README, roadmap, mdBook, behavior records, and Knowledge Map facts must
stop describing boundary-free active-transfer retention as deferred for the
repaired generated subordinate family. Historical slice-local statements stay
historical. General outstanding queues, multiple managers, broader bursts,
and the protocol-neutral transaction layer remain explicit residue.

## Implementation And Verification Owner

`IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.3` owns the behavior repair. Its
minimum validation set is:

- update the shared `AhbSubordinate.pm` IAL1 emission and additive report;
- update `t/1519` so the exact no-boundary `NONSEQ(0) -> SEQ(1)` probe observes
  two acceptances, two admissions, two completions, and final storage
  `32'h00002211`;
- prove held-phase suppression and exact ready/response ownership;
- prove active continuation and `IDLE` cancellation across final ERROR;
- prove existing IDLE, BUSY-clear, BUSY-park, sequence, HBURST, wait-state,
  byte-lane, and paired aggregate behavior remains intact;
- update focused structural/report tests such as t/1475 and aggregate owners
  where their exact generated contract changes;
- keep source/support counts and public source/artifact identities stable;
- run RAM-monitored focused generated-HDL gates, mdBook, Knowledge Map,
  memory/path/diff, and doctrine gates.

The direct lower-layer `fsm/ahb_lite_subordinate.fsm` is intentionally not
implemented by the shared IAL2 generator and is not silently changed by `.3`.
`IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.4` owns a later, separate runtime
audit of its consecutive-active-phase behavior after `.3` commits cleanly.

## Resource And Rollback Boundary

Generated-HDL tests must use direct macOS memory-pressure observation and a
4-GiB descendant RSS ceiling. The known repository RAM-guard host percentage
is not treated as the live macOS memory value.

Rollback is the `.3` implementation commit as one unit: shared generator,
tests, report expectations, current docs/book, facts, task/Memory, and generated
contract wording. No compatibility mode that preserves silent loss of an
accepted transfer is selected.

## Rejected Alternatives

Releasing ownership only on `ahb_access_done_q` is rejected because the audit
observed that pulse eleven cycles after the next phase was already accepted.

Requiring an `IDLE`, `BUSY`, or unselected boundary is rejected because holding
ready low deadlocks a stable next phase, while driving ready high accepts it.

Capturing `HWDATA` with address/control is rejected because it belongs to the
current data phase at the next address phase's acceptance edge.

Adding an arbitrary-depth queue is rejected because one bank plus ready
backpressure is sufficient for the AHB acceptance model and is the smallest
reviewable repair.

Changing the direct `.fsm` seed in the same implementation is rejected because
it is a separate lower-layer architecture with its own support identity and
has not yet received the generated-family runtime proof.

## Validation For This Selector

This selector is documentation-only. It is validated by the committed `.1`
runtime proof, direct IAL1/IAL0/HDL timing inspection, the source-backed AHB
fact inventory and rendered two-cycle-ERROR reference pages, plus:

```bash
rg -n 'cycle 37|cycle 48|HWDATA|one_accepted_next_address_control|final cycle of a two-cycle ERROR' \
  docs/IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_CONTRACT_SELECTION.md
prove -Iperl t/1519-ial2-ahb-pipelined-active-transfer-audit.t
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```
