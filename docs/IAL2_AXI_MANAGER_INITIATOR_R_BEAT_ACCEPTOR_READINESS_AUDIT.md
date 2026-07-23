# IAL2 AXI manager initiator - bounded R beat acceptor readiness audit

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.28` (behavior-neutral readiness
audit).

Date: 2026-07-23

Status: ready for a separate public-contract selection. This audit changes no
parser, generator, public source, support-accounting entry, capability
manifest, test, generated artifact, runtime behavior, or HDL behavior.

## 1. Outcome

The bounded AXI4 manager R read-data-channel acceptor selected by `.27` is
ready for contract selection.

The safe first slice is an **explicitly armed, one-beat receiver**:

1. accept one upstream arm command while idle;
2. assert manager-owned `RREADY` without waiting for subordinate-owned
   `RVALID`;
3. hold `RREADY` and busy high until one `RVALID && RREADY` transfer;
4. capture raw 4-bit `RID`, 32-bit `RDATA`, 2-bit `RRESP`, and scalar `RLAST`
   on that transfer;
5. clear ready/busy on the same acceptance edge;
6. keep all captured fields stable; and
7. emit exactly one later one-cycle **beat-done** pulse for that arm.

Beat-done means only that one physical R transfer was accepted. It never
implies `RLAST = 1`, successful `RRESP`, agreement between `RID` and an issued
`ARID`, satisfaction of `ARLEN + 1`, or completion of a read transaction.

The exact clause spelling, generator/result/schema identities, report keys,
and residue IDs belong to the next leaf,
`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.29`.

## 2. Source Evidence And Inspection Method

The tracked source is
`docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf`
(Arm IHI 0022 Issue L). This audit text-extracted the relevant sections, then
rendered and visually checked the physical pages below. The PDF tables and
dependency diagram were legible, aligned, and consistent with extraction.

| Source anchor | Physical page | Constraint carried into this audit |
| --- | ---: | --- |
| `A2.3 Valid-Ready transport` | 29 | A transfer occurs only when VALID and READY are both high. The transmitter retains VALID and information while stalled. |
| `A2.3.1 Valid-Ready signals`, Table A2.2 | 30 | `RVALID` marks valid R-channel information and `RREADY` marks that the manager can accept it; both are scalar. |
| `A2.3.2.2 Read transaction dependencies` | 32 | RVALID follows an accepted AR request. The subordinate must not wait for RREADY; the manager may assert RREADY before or after RVALID. |
| `A2.6 AXI transactions and transfers` | 41 | After issuing a read request, a manager must be able to accept all read data without depending on its other transactions. One-beat acceptance is therefore a primitive, not a full read-capacity claim. |
| `A3.2.2 Read data channel (R)`, Tables A3.24-A3.25 | 55 | RDATA width is `DATA_WIDTH`; RLAST is scalar and marks the final transfer. The bounded profile selects 32-bit data and captures RLAST without assuming it. |
| `A3.3.2 Read response`, Tables A3.29-A3.31 | 62-63 | Every read-data transfer carries RRESP; its value can vary by beat. `RRESP_WIDTH` permits 0, 2, or 3 and defaults to 2; this slice selects raw width 2. |
| `A5.1.1 Transaction ID signals`, Tables A5.1-A5.2 | 90 | RID and ARID share `ID_R_WIDTH`; the bounded profile selects width 4 but leaves matching to later composition. |
| `B1.2.2 Read data channel`, Table B1.5 | 281 | RVALID/RID/RDATA/RRESP/RLAST are subordinate-sourced; RREADY is manager-sourced. The table also exposes wider optional Issue L sidebands kept out of this slice. |

This evidence supports eager READY after an explicit arm. It does not support
an always-ready unowned receiver, nor does it permit a one-beat primitive to
claim that the complete manager obligation from A2.6 is discharged.

## 3. Repository Evidence

### Shipped B receiver architecture

`FSM::IAL2::ProtocolIntent::AxiBResponseAcceptor` is the closest proven actor.
It emits one idle arm, eager READY, acceptance-over-arm priority, handshake-edge
capture, stable registered outputs, six transaction states, and a later done
pulse. Its focused generated-HDL test proves unarmed, already-high/held-high,
and delayed VALID behavior.

The R actor can reuse that control schedule exactly. It cannot reuse B's
transaction-completion vocabulary: B has one response transfer per write,
whereas the R channel can carry several transfers and marks the final transfer
with RLAST. The new actor therefore needs R-specific **beat** naming and four
captured fields rather than B's two.

### Shipped AR request boundary

`AxiArDriver` emits a complete bounded AR request tuple but its machine-readable
`request_scope` says `done_event = ar_request_accepted` and
`includes_read_response = false`. Its `ar_done` pulse is not permission to
pretend an R response arrived. An R acceptor complements this missing physical
receiver side without coupling to a particular request policy.

### Capacity/status read seam

`AxiManagerCapacityStatus` already owns deep abstract read lifecycle behavior:
RID response demux, RLAST-aware completion, raw ARLEN capture, runtime
beat-count validation, single/last/multi-beat RDATA storage, and RRESP
aggregation. Its public shapes consume authored abstract request/completion and
read-data signals. They do not drive a small reusable physical RREADY actor or
establish which AR request owns a bus beat.

Later integration can feed the acceptor's captured RID/RDATA/RRESP/RLAST and
beat event into a selected adapter/core seam. That work must choose outstanding
state, rearm timing, ID routing, beat storage, and transaction completion, so it
is intentionally outside this primitive.

### Architectural constraints

- Decision `0014` requires IAL2 -> generated `.isf` -> generated `.fsm`; no
  direct IAL2-to-IAL0 lowering.
- Decision `0015` permits `.axi` only as an equivalent vocabulary alias; it
  does not justify adding the alias in the first generic `.ppif` behavior slice.
- Decision `0018` keeps public syntax, reports, diagnostics, and book language
  backend-neutral even though the current reference implementation is Perl.
- Decision `0020` preserves this receiver as a bus-side role primitive beneath
  a future transaction interface; that director-gated horizon is not activated.

## 4. Selected First-Slice Behavior Boundary

### Explicit arming, not continuous acceptance

One arm owns one R transfer. While unarmed, `RREADY = 0`; while active, further
arm pulses are not admitted and there is no queue. This keeps storage ownership
explicit and lets a later coordinator choose whether and when to rearm for the
next beat.

The subordinate may already hold RVALID high when the arm arrives, may assert
it after an arbitrary delay, or may keep it high after acceptance. All three
cases remain safe: READY rises only after arm, remains high until one transfer,
then clears on the acceptance edge so held RVALID cannot count twice.

### Fixed bounded AXI4 widths

- bus RID input and captured RID output: width 4, matching the shipped ARID;
- bus RDATA input and captured RDATA output: width 32;
- bus RRESP input and captured RRESP output: width 2;
- bus RLAST input and captured RLAST output: width 1; and
- arm, RVALID, RREADY, busy, and beat-done: scalar.

RRESP and RLAST are captured opaquely. The primitive neither interprets
response status nor rejects non-final beats. Configurable data/ID/response
widths and optional/advanced R signals remain later work.

### Recommended structural bindings

Exact spellings remain for `.29`, but the contract should retain this
backend-neutral role split.

**Inputs:**

| Role | Recommended spelling | Width | Rule |
| --- | --- | ---: | --- |
| arm command | `r_accept_cmd_valid` | 1 | one-shot, admitted only while idle |
| bus valid | `rvalid` | 1 | subordinate-owned; may already be high |
| bus response ID | `rid` | 4 | sampled only on the handshake |
| bus read data | `rdata` | 32 | sampled only on the handshake |
| bus response status | `rresp` | 2 | sampled only on the handshake |
| bus last marker | `rlast` | 1 | sampled only on the handshake; not required high |

**Outputs:**

| Role | Recommended spelling | Width | Rule |
| --- | --- | ---: | --- |
| bus ready | `rready` | 1 | asserted after arm independently of RVALID |
| captured response ID | `response_rid` | 4 | held until the next accepted beat |
| captured read data | `response_rdata` | 32 | held until the next accepted beat |
| captured response status | `response_rresp` | 2 | held until the next accepted beat |
| captured last marker | `response_rlast` | 1 | held until the next accepted beat |
| activity | `r_busy` | 1 | high from arm launch through acceptance |
| beat event | `r_beat_done` | 1 | one later one-cycle pulse per accepted arm |

The source role is `subordinate-to-manager`: RVALID and payload travel from the
subordinate to the manager even though the generated manager primitive owns
RREADY. Use the shared explicit asynchronous active-low reset model.

### Exact timing and cardinality

For every admitted arm:

1. do not accept while unarmed;
2. assert ready/busy without waiting for RVALID;
3. retain ready/busy while stalled;
4. capture exactly one RID/RDATA/RRESP/RLAST tuple on the first
   `RVALID && RREADY` edge;
5. clear ready/busy on that same edge;
6. retain the captured tuple until a later accepted beat; and
7. emit exactly one later beat-done pulse after ISF transaction retirement.

A command while busy is ignored by the idle transaction trigger. Reset while
idle or active clears READY, busy, active ownership, and pending done; it does
not fabricate a beat. Same-cycle rearm and back-to-back accepted beats are not
supported.

## 5. Proven Generated-IAL1 Shape

The audit tested this behavior-neutral prototype under `/tmp`:

```text
(priority accept_r over arm_r)

(rule arm_r arm_r_start
  (set active_q 1)
  (set r_busy 1)
  (set rready 1))

(rule accept_r (& active_q rvalid rready)
  (set response_rid rid)
  (set response_rdata rdata)
  (set response_rresp rresp)
  (set response_rlast rlast)
  (set active_q 0)
  (set r_busy 0)
  (set rready 0))

(transaction r_receive
  (on r_accept_cmd_valid)
  (drive
    (arm_r_start 1))
  (while active_q
    (wait 1))
  (complete r_beat_done))
```

The probe result was:

- strict check: PASS, zero diagnostics;
- generated schedule: 13 ports (six inputs/seven outputs), six states, zero
  compile issues;
- rule blocks: `arm_r` three assignments, `accept_r` seven assignments;
- exactly three `accept_r`-over-`arm_r` priority resolutions for `active_q`,
  `r_busy`, and `rready`;
- generated `.fsm` and SystemVerilog: PASS;
- external Verilator lint and Yosys synthesis: PASS; and
- executable Verilator proof: unarmed RVALID, already-high/held-high RVALID
  with input mutation after acceptance, delayed RVALID, command while busy,
  active reset abort, post-reset recovery, and a one-cycle RVALID all passed:
  `PASS handshakes=3 done_pulses=3 rid=5 rdata=badc0de rresp=0 rlast=1`.

This establishes schedule feasibility only. It is not a public PPIF
implementation. `.29` must select exact identities and `.30` (if selected by
that contract leaf) must reproduce the proof from the checked-in public source.

## 6. Exact Implementation Owner Map

### Parser and dispatch

`perl/FSM/Adapter/IAL2/PPIF.pm` owns the public syntax. The eventual behavior
slice must add the new object symmetrically to import/result dispatch, root
accumulation/clause parsing, missing-intent enumeration, exact cardinality,
every standalone mixing predicate, normalized return metadata, object and
binding-block parsers, the contract predicate, and an explicit `.axi`
first-alias rejection.

The B acceptor paths near `_parse_axi_b_response_acceptor` are the structural
template. The R object must remain standalone; silently mixing AR and R objects
would create an aggregate without a coordinator or selected HDL entry.

### Generator

Add one defensive reference-implementation module under
`perl/FSM/IAL2/ProtocolIntent/`, likely `AxiRBeatAcceptor.pm` subject to `.29`.
It must normalize the fixed profile/role/reset/bindings, reject duplicate
external/internal names, emit the proven rule pair through `FSM::Adapter::ISF`
and `FSM::Scheduler::ISF`, return one generated IAL1 plus generated IAL0 and a
selected HDL entry, and report the beat-only boundary and honest residue.

### Public source

Add one generic `.ppif` source, likely `ppif/axi_r_beat_acceptor.ppif` subject
to `.29`, with profile `axi4`, one receiver object, role
`subordinate-to-manager`, distinct arm/channel/captured/status bindings, and
the eight anchors in section 2. No AR object and no `.axi` source belongs in
the first behavior slice.

### Support accounting and manifest

Add one supported/strict `protocol_fixture` entry beside AR and B with a new
coverage key and expected generated module/root. Current counts are 303
protocol fixtures, 344 supported-smoke, and 344 strict-supported. The behavior
slice should move them to **304/345/345**.

Extend the `.ppif` `current_boundary` in
`perl/FSM/Support/LanguageSurfaceSection.pm` and add the matching
`t/297-capability-manifest.t` assertion. It must say one armed R beat, not a
complete read manager.

### Focused test and book

Reserve `t/1505-ial2-axi-r-beat-acceptor.t` for the implementation leaf. Follow
the four-top-level-subtest organization used by t/1501 and t/1504:

1. adapter/report/generated artifacts and exact anchors;
2. fail-closed profile/role/width/reset/cardinality/mixing/alias cases;
3. strict/check/semantic/schedule/outdir plus Verilator/Yosys validation; and
4. generated-HDL cardinality/capture/reset behavior reproducing the `/tmp`
   proof with exact three handshakes and three beat-done pulses.

Only the behavior slice changes the mdBook from selected/ready wording to a
shipped source and runnable commands.

## 7. Fail-Closed Contract Requirements

`.29` must fix exact public diagnostics and report spellings for at least:

- exact `axi4` profile and `subordinate-to-manager` role;
- fixed bus/captured RID4, RDATA32, RRESP2, and RLAST1;
- scalar arm/VALID/READY/busy/beat-done;
- all external and reserved internal binding names distinct;
- exactly one receiver object and every required clause/binding exactly once;
- rejection of unknown clauses and unsupported/malformed resets;
- no mixing with monitors, capacity/status, AW/AR/W/B primitives,
  compositions, APB, or AHB objects;
- complete source anchors;
- explicit `.axi` rejection; and
- no direct IAL2-to-IAL0 lowering.

## 8. Report And Residue Boundary

The report needs a machine-readable bounded-beat block. `.29` owns exact keys,
but it must express at least:

```text
arming              = explicit_one_beat
ready_policy         = assert_after_arm_without_waiting_for_valid
accept_condition     = rvalid && rready
id_width             = 4
data_width           = 32
response_width       = 2
last_width           = 1
capture              = on_accept_and_hold_until_next_accept
done_event           = r_beat_accepted
includes_read_completion = false
back_to_back_supported    = false
```

Static rules must distinguish handshake-edge capture from the later done
pulse and state that RLAST/RRESP remain raw. Unsupported residue must retain:

- AR/R composition and fixed-single-beat request coupling;
- repeated/multi-beat reception and rearm policy;
- ARLEN+1/RLAST validation and transaction completion;
- RRESP interpretation/aggregation and data-valid policy;
- RID/ARID match and request ownership;
- capacity/status integration, queues, outstanding reads, ordering, and demux;
- configurable widths and extended Issue L R sidebands/credit transport;
- generated subordinate stall assertions inside the acceptor;
- `.axi` profile-alias exposure;
- decision `0020` transaction-interface activation;
- verification-output generation; and
- direct/backend-language/VHDL, AHB, and APB behavior.

## 9. Validation And Rollback

This audit is documentation-only. Closeout requires Knowledge Map generation
and checking, mdBook build, bounded Memory/docs-path/whitespace checks, and the
full doctrine gate. The ISF/HDL/Verilator proof remains temporary and is not a
repository artifact.

Rollback removes this audit/fact, restores `.28` active, removes `.29`, and
restores task-index/book/Memory pointers. No parser, generator, public source,
support, manifest, test, artifact, runtime, or HDL rollback is required.

## 10. Selected Next Leaf

Proceed with `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.29`: select the exact public
contract for the explicitly armed fixed-width one-beat R acceptor. `.29` must
pin the object/clause and binding vocabulary, generator/result/schema/source/
module/support/test identities, exact eight-anchor source, six-state generated
IAL1, beat-scope report/static/residue, diagnostics, executable proof,
implementation owner, validation, rollback, and following behavior leaf
without changing behavior itself.
