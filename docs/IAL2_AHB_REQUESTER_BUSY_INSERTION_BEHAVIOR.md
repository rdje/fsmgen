# IAL2 AHB Requester BUSY-Insertion Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.788`

Date: 2026-07-23

## Outcome

FSMGen ships an additive bounded AHB requester source whose public contract
requests one held `HTRANS = BUSY` presentation before a selected `SEQ` beat:

```text
ppif/ahb_requester_busy_insert.ppif
```

The source keeps the existing `ahb_requester` contract kind and public command,
status, and bus ports. It has its own intent, actor, generated artifacts, HDL
module, and support identity so `ppif/ahb_requester.ppif` and its `.ahb` alias
remain unchanged.

## Source Contract

The additive source declares the AHB BUSY encoding and literal insertion point
inside the existing `transfer` block:

```text
(transfer
  (idle 2'b00)
  (busy 2'b01)
  (nonseq 2'b10)
  (seq 2'b11)
  (first-beat nonseq)
  (later-beats seq)
  (advance-on ready)
  (busy-before-beat 2))
```

`busy-before-beat N` means: immediately before the `SEQ` transfer whose
zero-based `beat_index` is `N`, present the pending address/control/write-data
with `HTRANS = BUSY` once, do not advance address or counters, then resume that
same pending beat as `SEQ`. The bounded public source selects `N = 2`.

`N` must be a literal in `1..15`: beat zero is the initial `NONSEQ`, and the
requester supports at most sixteen beats. The parser fails closed for a missing
BUSY encoding, an encoding other than `2'b01`, a non-literal or out-of-range
index, or a duplicate insertion clause.

## Generated Behavior

The generator adds only when `busy-before-beat` is present:

- a `transfer_busy` drive that re-drives `HBUSREQ`, `HLOCK`, `HADDR`, `HWRITE`,
  `HSIZE`, `HBURST`, `HPROT`, and `HWDATA` from the armed request while driving
  `HTRANS = 2'b01`;
- one one-bit `busy_inserted_q` local, initialized for each command;
- an insertion guard at `beat_index_q == N` that drives BUSY, marks the
  one-shot, and continues to the next loop iteration before the normal transfer
  and `HREADY`/response path;
- the next iteration's unchanged `transfer_seq` and response advancement.

The requester presents the request bus before the beat loop, waits one clock
after driving an active data transfer, and retains that transfer while its
address/data ownership is pending. It samples `HRESP` and advances only after
the selected data phase completes. This phase behavior is common to the base
and BUSY-inserting requesters and was runtime-corrected when the first paired
aggregate exposed the former early-response path in `.794`.

The BUSY episode therefore cannot decrement `beats_remaining_q`, increment
`beat_index_q`, advance `addr_q`/`wdata_q`, or consume `HREADY`/`HRESP`. A burst
that never reaches `N` is a safe no-op. There is no new local-status bus-BUSY
output; users observe it directly on `HTRANS`, while `local-status.busy` keeps
its existing transaction-in-progress meaning.

## Reports And Support Accounting

Schedule/report JSON keeps schema
`fsmgen.ial2.protocol_intent.ahb_requester.v1` and adds:

```text
busy_insertion.generated_behavior   = true
busy_insertion.htrans_busy_encoding = 2'b01
busy_insertion.before_beat          = 2
busy_insertion.beats                 = single
```

The generic source also carries `ahb_requester_busy_insert_support`, recording the
shipped one-held-presentation subset and deferring multi-beat/policy-driven
throttling, runtime insertion points, and broader requester BUSY behavior.

```text
support id:      intent.ppif_ahb_requester_busy_insert
coverage:        ial2_ppif_ahb_requester_busy_insert_pipeline_cli
source kind:     ppif
IAL1 artifact:   amba_requester_busy_insert.isf
IAL0 artifact:   amba_requester_busy_insert.fsm
HDL module:      amba_requester_busy_insert
```

The support corpus moves from 308 to 309 protocol fixtures and from 349 to 350
supported-smoke/strict-supported entries at this slice's current baseline.
The matching `.ahb` alias shipped later in `.790` as
`intent.ahb_profile_alias_requester_busy_insert`, moving the current corpus to
310 protocol / 351 supported-smoke and strict entries; its canonical alias
record is `docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_PROFILE_ALIAS_BEHAVIOR.md`.

## Runtime Proof

Focused generated-HDL regression
`t/1498-ial2-ahb-requester-busy-insert.t` runs an `INCR4` command and observes
the non-IDLE transfer-type transition sequence:

```text
NONSEQ(index 0) -> SEQ(index 1) -> BUSY(index 2 held)
                 -> SEQ(index 2 resumed) -> SEQ(index 3)
```

The proof requires one contiguous BUSY transition episode, unchanged
address/control/write-data and unchanged beat index/remaining count from BUSY
to resumed SEQ, exactly four accepted data beats, and request completion with
zero remaining. It does not count every ready-qualified BUSY clock edge. It
also covers report shape, diagnostics, CLI check/schedule/outdir behavior,
support accounting, and preservation of the base requester.

## Current Cardinality Audit

`IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.1` found a current
runtime/report contradiction. With `HGRANT=1` and `HREADY=1` continuously, the
generated requester exposes one BUSY transition episode spanning **ten**
ready-qualified BUSY edges, while the report says
`busy_insertion.beats=single`. The one-bit flag records that the procedural
drive was scheduled, not that one bus event retired; generated microstates
keep the registered BUSY output active in between.

The repo-local Arm AHB specification permits a fixed-length BUSY-to-SEQ change
while `HREADY=0`, so that transition is not itself the defect. The defect is
the continuously-ready event cardinality. The audit proved assertion-enabled
single- and two-event candidate shapes. Contract slice `.2` now freezes
`single` as exactly one rising edge with
`HGRANT && HREADY && HTRANS == BUSY`: BUSY holds without retiring while either
qualifier is low, then hands the same pending transfer to `SEQ`. The selected
repair adds a conditional `ahb_busy_accept` rule and ready/BUSY loop gate,
reuses existing address-pending state, and adds no public syntax, report field,
or counter. `.3` owns implementation before any public multiple-BUSY
extension. Until `.3` ships, read `beats=single` as the intended contract, not
as a current clock-edge guarantee. The generic/alias paired requester families
inherit this same current limitation.

See
`docs/IAL2_AHB_REQUESTER_MULTI_BUSY_INSERTION_READINESS_AUDIT.md` for the exact
source-backed timing distinction and candidate matrix, and
`docs/IAL2_AHB_REQUESTER_SINGLE_BUSY_EVENT_CARDINALITY_REPAIR_CONTRACT_SELECTION.md`
for the selected repair and regression contract.

## Run It

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester_busy_insert.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester_busy_insert.ppif
./bin/fsmgen --quiet --outdir generated/ial2-ahb-requester-busy-insert ppif/ahb_requester_busy_insert.ppif
./bin/fsmgen --quiet --strict --verify-hdl ppif/ahb_requester_busy_insert.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester_busy_insert.ahb
```

## Explicit Deferrals

The matching `.ahb` alias and the first generic paired requester/subordinate
composition now ship. Paired `.ahb`/two-subordinate variants, multi-beat or
policy-driven BUSY throttling, runtime-selected insertion point, distinct
`local-status.bus_busy`, halfword/word burst `SEQ`, wider/indefinite bursts,
multi-word/register-bank progression, optional AHB signals, broader AHB manager
behavior, direct backend, verification output, backend-language variants,
AXI/APB changes, and VHDL remain deferred.
