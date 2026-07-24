# IAL2 AHB Requester Single-BUSY Event-Cardinality Repair Contract Selection

Task-tree owner:
`IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.2`

Date: 2026-07-24

## Outcome

This slice selects the exact repair for the shipped requester contract
`busy_insertion.beats=single`: exactly one requester BUSY event retires on a
rising edge where:

```text
HGRANT && HREADY && HTRANS == 2'b01
```

The selected implementation keeps the current public source syntax, report
schema and values, ports, artifacts, module names, support identities, and
residue. It changes only BUSY-inserting generated IAL1 timing in
`AhbRequester.pm`, plus focused/paired runtime assertions and current
documentation.

`IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.3` owns
implementation. Public multiple-BUSY syntax/count behavior remains deferred
until `.3` commits cleanly.

This contract-selection slice makes no parser, generator, source, test,
artifact, HDL, runtime, backend, AXI, APB, or VHDL behavior change.

Implementation outcome: `.3` now ships this contract exactly. See
`docs/IAL2_AHB_REQUESTER_SINGLE_BUSY_EVENT_CARDINALITY_REPAIR.md` for the
generated IAL1 delta and requester/generic/alias/paired runtime evidence.

## Selected Meaning Of `single`

The current report value is retained:

```text
busy_insertion.beats = single
```

Its exact runtime meaning is now frozen as one ready/grant-qualified BUSY edge,
not:

- one transition into a contiguous BUSY episode;
- one procedural `drive transfer_busy` statement;
- one generated FSM state; or
- an implementation-dependent number of clocks with `HTRANS=BUSY`.

Clocks with BUSY visible but either `HGRANT=0` or `HREADY=0` hold the pending
BUSY presentation and do not retire it. When both qualify, exactly one BUSY
event retires; the next clock presents the same pending transfer as SEQ.

The repo-local Arm AHB specification permits fixed-length BUSY-to-SEQ changes
while ready is low. The bounded FSMGen source deliberately selects the stronger
stable-BUSY-until-qualified policy because it gives the public `single` count a
deterministic protocol-event meaning and is the direct substrate for a later
literal count. This is a legal subset, not a claim that all AHB managers must
choose the same ready-low policy.

## Selected Generated IAL1 Shape

The repair is gated on `busy_before_beat`; the base requester emits none of the
new lines.

### Acceptance rule

Add priority over the requester transaction and a concurrent acceptance rule:

```text
(priority ahb_busy_accept over ahb_request)

(rule ahb_busy_accept
  (& HGRANT HREADY (== HTRANS 2'b01))
  (set ahb_address_pending_q 1)
  (set HTRANS 2'b11))
```

The rule reuses the existing address-pending owner. On the accepted BUSY edge,
the BUSY transfer itself creates no data/response owner. Instead, the rule arms
the pending SEQ address phase and changes the registered bus output for the
following clock. The existing `ahb_address_accept` rule then accepts that SEQ
exactly once, retires HTRANS to IDLE, and creates the normal data-pending owner.

### Procedural hold gate

Retain the existing `transfer_busy` drive and one-bit transaction-local
`busy_inserted_q` one-shot. Immediately after the insertion block, add:

```text
(continue-when (& (! HREADY) (== HTRANS 2'b01)))
```

The existing first loop gate already continues while grant is absent and no
address/data/response owner exists. Together the two gates prevent the
procedural transaction from reaching `transfer_seq` while the BUSY
presentation is unqualified. They write no output and therefore preserve the
registered `transfer_busy` fields.

No new BUSY-pending storage is needed for the current single-event repair:

- `busy_inserted_q` prevents procedural re-arming;
- registered `HTRANS=BUSY` is the visible pending-presentation state;
- the existing grant gate and new ready/BUSY gate hold it;
- `ahb_busy_accept` retires it into existing `ahb_address_pending_q` ownership.

A later multiple-BUSY contract may add a bounded remaining-event counter, as
proved feasible by `.1`; it must not be preimplemented in `.3`.

## Exact Timing

For continuously asserted grant and ready:

```text
clock k:     HTRANS=BUSY, HGRANT=1, HREADY=1  -> BUSY event 1 retires
clock k+1:   HTRANS=SEQ,  same address/control/data and beat counters
next accept: existing address/data/response pipeline proceeds once
```

For a ready or grant stall:

```text
BUSY visible + !HREADY or !HGRANT: hold BUSY and every pending field
first HGRANT && HREADY edge:         retire BUSY event 1
following clock:                     present the same pending SEQ
```

BUSY never sets `ahb_data_pending_q` or `ahb_response_pending_q`, samples
`HRESP`/`HRDATA`, raises `beat_done`, decrements `beats_remaining_q`, increments
`beat_index_q`, or advances address/write data. The resumed SEQ owns exactly
those normal effects.

## Public And Report Preservation

Unchanged:

- `ppif/ahb_requester_busy_insert.ppif` and byte-identical `.ahb` alias;
- `(busy 2'b01)` and `(busy-before-beat 2)` syntax/diagnostics;
- requester kind/schema, local command/status ports, bus ports, actor/module,
  IAL1/IAL0 artifact names, support IDs, source kinds, coverage keys, and
  capability entries;
- `busy_insertion.generated_behavior`, encoding, before-beat, and
  `beats=single` report shape;
- `ahb_requester_busy_insert_support` text and broader policy/runtime/multiple
  BUSY deferrals;
- base requester generic/alias behavior and every non-BUSY requester source.

The repair makes the existing `single` report truthful; it does not add a new
report field or public feature.

## Selected Regression Contract

`.3` extends t/1498 and its tracked generated-HDL harness. Generated selector
assertions must remain enabled for these scenarios.

1. **Continuously qualified:** `HGRANT=HREADY=1`; count every rising edge with
   BUSY qualified and require exactly one. Preserve the transition episode,
   five transfer-type episodes, four data beats, unchanged BUSY fields/counters,
   same resumed SEQ, and zero remaining.
2. **Ready-low hold:** on the first publicly visible BUSY half-cycle, drive
   `HREADY=0` before the next rising edge, hold for 32 clocks, and require BUSY
   plus all pending fields/counters stable. Release ready, require exactly one
   qualified BUSY edge, then the same SEQ and four data beats.
3. **Grant-low hold:** use the same public BUSY observation to drive
   `HGRANT=0` for 32 clocks while ready remains high. Require stable BUSY with
   zero qualified edges during the stall, exactly one after grant returns, and
   normal completion.

The harness must not depend on generated state numbers. The first-visible BUSY
negedge occurs after the registered drive and before the next rising-edge
acceptance rule evaluates it, so it is a stable public stall injection point.

Structural t/1498 assertions lock the conditional priority, acceptance rule,
outer ready/BUSY gate, existing one-bit flag, and base-requester absence.
t/1512 retains byte-identical `.ahb` parity. The one- and two-subordinate
generic/alias paired harnesses (t/1513-t/1516) must count their ready-qualified
embedded BUSY edges and require one per command, while preserving parking,
four data beats per command, mappings, storage, and statuses. t/1518 retains
current mdBook truth and t/1519 preserves the broader phase pipeline.

Run focused requester/base/alias/paired tests, t/248/t/297 accounting and
capability gates, strict check/schedule/semantic/outdir paths, and public
`--verify-hdl`. Broad or potentially heavy commands remain under the 4-GiB
descendant RSS cap with direct macOS pressure observation.

## Disposable Contract Proof

The `.1` candidate already passed continuously-ready and 32-clock ready-low
scenarios with exactly one qualified BUSY edge and four data beats. `.2` added
an assertion-enabled public grant-stall proof using no generated state number:

```text
PASS transfers=5 beats=4 busy=1 qualified_busy=1 grant_stall=32
```

A corresponding public first-visible-BUSY ready-stall proof also passed with
one qualified BUSY event after 32 held clocks. The rejected early
`beat_done && beat_index==1` grant trigger correctly prevented BUSY from being
presented at all; it is not the selected regression stimulus.

The candidates were disposable and are not product artifacts.

## Explicit Deferrals

Multiple BUSY events, new count syntax/reporting/state, runtime-selected
insertion points, policy/random throttling, distinct local bus-BUSY status,
larger or broader burst behavior, optional AHB signals, multiple managers,
queues/outstanding transfers, direct seeds/backends, verification-output
generation, backend variants, AXI/APB changes, VHDL, the separate general ISF
output-priority owner, and decision 0020 remain outside `.3`.

## Rollback

Implementation rollback removes only the conditional priority/rule/hold gate
and new clock-edge/stall assertions, restoring the pre-repair generated IAL1
and tests together. It does not change public sources/reports/support. Rollback
must also restore the current limitation notes; it must never leave docs
claiming exact single-event runtime while the ten-edge behavior is present.
