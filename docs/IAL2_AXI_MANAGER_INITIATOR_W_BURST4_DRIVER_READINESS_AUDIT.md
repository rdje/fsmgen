# IAL2 AXI manager initiator — fixed-four W burst driver readiness audit

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.40` (behavior-neutral audit).

Date: 2026-07-23

Status: ready for exact public-contract selection. This leaf changes no parser,
generator, public source, support entry, manifest, test, generated artifact,
runtime behavior, or HDL behavior.

## Outcome

The smallest honest multi-beat write-data primitive is an additive, bounded
**fixed-four-beat, full-width AXI4 manager W driver**. It captures four
explicitly named 32-bit data/four-bit strobe tuples atomically, presents them
in index order, keeps `WVALID` asserted between consecutive beats, and drives
`WLAST` as `0/0/0/1`. Arbitrary `WREADY` stalls preserve the current tuple and
`WLAST` until acceptance.

The primitive exposes one aggregate busy interval, one event for every
accepted beat with a two-bit accepted-beat index, and one final done event.
Exactly four rising-edge `WVALID && WREADY` transfers retire one command. An
all-zero strobe remains legal on any beat.

This must be a new `AxiWBurst4Driver`, not a generalization of the shipped
`AxiWDriver`. The one-beat object, source, schema, test, and write compositions
continue to rely on `WLAST=1` for their sole transfer. Mutating that generator
would silently widen or invalidate shipped behavior; an additive object makes
the new length and event contract reviewable and independently reversible.

A temporary IAL1 actor passes strict checking, zero-state schedule inspection,
Verilator lint, Yosys synthesis checking, and assertion-disabled executable
proof. It is ready for the behavior-neutral contract selector
`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.41`; `.42` is reserved for the atomic
implementation.

## Source evidence and inspection method

The tracked source is
`docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf`
(SHA-256 `20aa5f946df5fa97053689d705959b1ef6a90a88f845fa3b686a53311f680ac1`).
`pdfinfo` confirmed the 320-page unencrypted artifact. Bounded
`pdftotext -layout` extraction was checked against rendered pages, including
the length/no-early-termination requirements on page 44 and the W-channel
direction table on page 277.

| Order | Section | Page | Constraint fixed here |
| ---: | --- | ---: | --- |
| 1 | A2.3 | 29 | A transfer occurs only with both VALID and READY high; the transmitter cannot wait for READY before VALID and must retain VALID plus its information until acceptance. |
| 2 | A2.3.1 | 30 | `WVALID` identifies valid W information and `WREADY` identifies receiver acceptance capability. |
| 3 | A2.3.2.1 | 31 | The manager must not wait for `WREADY` before asserting `WVALID` on any write-data transfer. B completion is outside this isolated W primitive. |
| 4 | A3.1.2 | 44 | Length defines the transfer count; a manager must issue that many W transfers; `Length = AWLEN + 1`; early termination is forbidden, including when remaining strobes are all low. |
| 5 | A3.2.1 | 53 | `WDATA` has `DATA_WIDTH`; `WLAST` is scalar and the manager asserts it with the final write transfer. |
| 6 | A3.2.1.1 | 54 | `WSTRB` has `DATA_WIDTH / 8` bits; every value, including all zero, is legal within the transaction container. |
| 7 | B1.1.2, Table B1.2 | 277 | WVALID, WDATA, WSTRB, and WLAST are manager-sourced; WREADY is subordinate-sourced. |

The eventual fixed-four AW composition must pair this transfer count with
`AWLEN=3`. This channel-only driver does not own an address, AWLEN, AWSIZE,
AWBURST, alignment, or the 4-KiB predicate, so it must not claim address or
full-transaction legality. It provides the exact four-transfer W prerequisite.

## Existing repository evidence

The shipped `ppif/axi_w_driver.ppif` and
`FSM::IAL2::ProtocolIntent::AxiWDriver` capture one data32/strobe4 tuple, drive
one stable W transfer, hard-wire `WLAST=1`, and complete exactly once. Its
generated rule-pair correction prevents a held-high WREADY from accepting the
same command twice. `t/1500-ial2-axi-w-driver.t` proves continuous and pulsed
READY, stall stability, all-zero strobes, exactly two transfers/two done
pulses, and final idle.

`AxiWriteRequestComposition` and `AxiWriteTransactionComposition` reuse that
unchanged single-beat child with fixed `AWLEN=0`. They cannot reuse it four
times under `AWLEN=3`, because every child invocation would assert WLAST.

`AxiReadBurst4TransactionComposition` proves useful two-bit index, raw beat
event, final event, busy-command, reset-abort, and exact-four cardinality
patterns. Its repeated R child cannot be copied mechanically: RLAST is sampled
from the subordinate, whereas the W driver must actively select the next
payload and generate WLAST without a ready-low re-arm bubble.

Decisions 0014, 0015, and 0018 require the additive public PPIF object to lower
through generated IAL1 `.isf` and generated IAL0 `.fsm` before HDL. Decision
0020's protocol-neutral transaction interface remains director-gated and is
not activated by this bus-side primitive.

## Upstream payload-shape decision

| Candidate | Benefit | Cost/risk | Disposition |
| --- | --- | --- | --- |
| Four explicit data32/strobe4 tuples | Field-oriented PPIF is immediately reviewable; beat ownership and width diagnostics are exact; all payload is present at admission. | Eight payload bindings and six private trailing-beat storage registers. | **Selected.** |
| Packed data128/strobe16 banks | Fewer public bindings. | Hides beat ordering and lane grouping inside slicing rules, weakens field-specific diagnostics, and introduces packed-bank conventions absent from the current primitive family. | Deferred. |
| Streaming producer valid/ready | Scales naturally to dynamic lengths. | Adds a second handshake, producer backpressure, buffering/underflow policy, and an additional ownership interval before bus-side W progression is proven. | Deferred. |

The explicit contract is atomic: when an idle `w_cmd_valid` is sampled, beat
zero is captured directly into the registered WDATA/WSTRB outputs and beats
one through three are captured into private registers. Later mutation of any
command input cannot affect the active burst.

No private beat-zero payload copy is needed. The public driven registers are
the retained beat-zero storage, avoiding two dead registers while preserving
atomic capture of all four tuples.

## Exact public boundary recommended to `.41`

```text
(axi-w-burst4-driver axi_w_burst4_driver
  (role manager-to-subordinate)
  (clock clk)
  (reset (rst_n active_low async))
  (command
    (start w_cmd_valid)
    (data0 cmd_wdata0 width 32)
    (data1 cmd_wdata1 width 32)
    (data2 cmd_wdata2 width 32)
    (data3 cmd_wdata3 width 32)
    (strobe0 cmd_wstrb0 width 4)
    (strobe1 cmd_wstrb1 width 4)
    (strobe2 cmd_wstrb2 width 4)
    (strobe3 cmd_wstrb3 width 4)
    (ready wready))
  (channel
    (valid wvalid)
    (data wdata width 32)
    (strobe wstrb width 4)
    (last wlast)
    (busy w_busy)
    (beat-done w_beat_done)
    (done w_done)
    (beat-index w_beat_index width 2)))
```

Recommended identities are:

| Surface | Exact identity |
| --- | --- |
| parser contract kind | `axi_w_burst4_driver` |
| result kind | `protocol_intent.axi_w_burst4_driver` |
| mode | `burst4-driver` |
| generator | `FSM::IAL2::ProtocolIntent::AxiWBurst4Driver` |
| report schema | `fsmgen.ial2.protocol_intent.axi_w_burst4_driver.v1` |
| public source | `ppif/axi_w_burst4_driver.ppif` |
| source object | `axi-w-burst4-driver` |
| actor/module | `axi_w_burst4_driver` |
| generated IAL1 | `axi_w_burst4_driver.isf` |
| generated IAL0 / HDL entry | `axi_w_burst4_driver.fsm` |
| support ID | `intent.ppif_axi_w_burst4_driver` |
| support coverage key | `ial2_ppif_axi_w_burst4_driver_pipeline_cli` |
| test owner | `t/1508-ial2-axi-w-burst4-driver.t` |
| HDL fixture | `t/data/axi_w_burst4_driver_tb.svt` |

All public bindings, private registers (`active_q`, `beat_index_q`,
`data1_q`-`data3_q`, `strb1_q`-`strb3_q`), and scheduler-reserved names such as
`can_accept` must be distinct valid ISF identifiers. The exact profile is
`axi4`, the role is `manager-to-subordinate`, and all state shares `clk` plus
asynchronous active-low `rst_n`.

The shipped `(axi-w-driver ...)` object, generator, source, schema, support ID,
t/1500 proof, and every existing composition remain byte-for-byte unchanged.

## Exact transfer and event lifecycle

For every admitted command:

1. capture all four tuples atomically and present tuple zero with
   `WVALID=1`, `WLAST=0` without consulting WREADY;
2. while `WVALID && !WREADY`, retain WVALID, WDATA, WSTRB, WLAST, and the
   current private index;
3. on accepted indices 0, 1, and 2, publish `w_beat_done=1` with the accepted
   `w_beat_index`, advance to the next captured tuple, and keep WVALID high;
4. make WLAST low for presented indices 0-2 and high for presented index 3;
5. on accepted index 3, publish beat done/index 3 and final `w_done` together,
   clear active/busy/WVALID, and retire exactly once; and
6. clear each event on the following non-event cycle.

With continuously high WREADY, transfers occur on four consecutive rising
edges. `w_beat_done` is therefore high on four consecutive event cycles while
`w_beat_index` changes `0,1,2,3`; consumers treat the level in each cycle as
the event, not as a low-to-high edge detector. With a stall, no event occurs
and all presented W information remains stable.

`w_done` coincides with the final beat event and is high for that one terminal
cycle. A one-cycle command presented while busy is ignored and is not queued.
A held-high command is outside this one-shot command contract. Adjacent
back-to-back admission guarantees are deferred.

Asynchronous reset at any index clears active, busy, WVALID, both events,
indices, driven payload, and private payload storage without fabricating an
accepted beat or completion. A later command restarts at index zero. As with
the existing primitive, system reset is assumed to quiesce the peer; this
driver does not drain a pre-reset transaction.

## Exact generated-IAL1 schedule

The proven actor has 18 ports, ten inputs, eight outputs, zero procedural
states, seven rules, one assertion-only transaction, and `compile_issues=[]`.
Declared private storage is the two-bit `beat_index_q`, three 32-bit trailing
data registers, and three four-bit trailing strobe registers. `active_q` is
inferred from rule writes; the assertion-only transaction introduces the
scheduler's one-bit `can_accept` counter.

| Rule | Assignments | Purpose |
| --- | ---: | --- |
| `admit` | 13 | capture all tuples, initialize index, raise busy/WVALID, and present beat zero with WLAST low |
| `accept_beat0` | 6 | publish index zero and advance outputs/index to beat one |
| `accept_beat1` | 6 | publish index one and advance outputs/index to beat two |
| `accept_beat2` | 6 | publish index two and advance outputs/index to final data with WLAST high |
| `accept_final` | 6 | publish index three/final done and clear active/busy/WVALID |
| `clear_beat_done` | 1 | clear the per-beat event on a non-event cycle |
| `clear_done` | 1 | clear final done on the next cycle |

The five authored priorities are all realized:

```text
accept_beat0 over clear_beat_done
accept_beat1 over clear_beat_done
accept_beat2 over clear_beat_done
accept_final over clear_beat_done
accept_final over clear_done
```

The first four priorities preserve one event per transfer during consecutive
ready-high beats. The fifth makes final done win over clearing a previous done
value. Rule guards are mutually exclusive by `beat_index_q`; compatible
same-value fan-in permits the four accept rules to set beat done and the first
three presentation rules to set WLAST low.

The assertion-only transaction requires:

```text
(wvalid && active_q) -> (wlast == (beat_index_q == 3))
```

The rule structure itself guarantees WVALID/payload stability during stalls
because no acceptance rule is enabled. The generated result contains one IAL1
actor, one IAL0 FSM, and that FSM as the selected HDL entry; no composition top
or direct IAL2-to-IAL0 path exists.

## Report and static contract

The schema-v1 report must contain:

- generated-ISF/generated-FSM layering and `direct_ial2_to_ial0=false`;
- the exact source object, intent, and seven ordered anchors;
- AXI4/W-burst4/manager-to-subordinate identity;
- clock/reset/command/channel bindings;
- `fixed_burst_policy` with data width 32, strobe width 4, four beats,
  two-bit index, terminal index three, WLAST `0/0/0/1`, atomic explicit-field
  capture, and all-zero-strobe legality;
- lifecycle, stall, busy-command, event, and reset policies;
- exact schedule/rule/storage/priority facts;
- one generated IAL1 and one generated IAL0 artifact with selected HDL entry;
- ordered enforced-static and unsupported-residue arrays.

The ordered enforced-static set has thirteen entries:

1. exact AXI4 profile, W-burst4 object, and manager-to-subordinate role;
2. shared clock and asynchronous active-low reset;
3. one idle command atomically captures four explicit data32/strobe4 tuples;
4. WVALID asserts independently of WREADY and remains high through all four
   presented beats;
5. WDATA/WSTRB/WLAST remain stable during every WREADY-low stall;
6. WLAST is low on indices 0-2 and high only on index 3;
7. exactly four WVALID/WREADY acceptances retire one command;
8. all-zero and partial WSTRB values are legal on every beat;
9. beat event/index identify every accepted tuple, including consecutive
   ready-high transfers;
10. final done coincides with accepted index three and retires busy/WVALID;
11. a busy-time one-shot command is ignored with no queue;
12. reset aborts without fabricated beat/final events and recovery starts at
    index zero; and
13. lowering uses one generated IAL1 actor then one generated IAL0 FSM, never
    direct IAL2-to-IAL0.

The ordered residue set has thirteen IDs:

1. `axi_w_burst4_driver_aw_coordination_deferred`;
2. `axi_w_burst4_driver_b_response_completion_deferred`;
3. `axi_w_burst4_driver_address_attribute_coupling_deferred`;
4. `axi_w_burst4_driver_dynamic_general_bursts_deferred`;
5. `axi_w_burst4_driver_narrow_unaligned_wrap_deferred`;
6. `axi_w_burst4_driver_streaming_packed_payload_deferred`;
7. `axi_w_burst4_driver_capacity_core_integration_deferred`;
8. `axi_w_burst4_driver_outstanding_queueing_deferred`;
9. `axi_w_burst4_driver_transaction_interface_deferred`;
10. `axi_w_burst4_driver_profile_alias_deferred`;
11. `axi_w_burst4_driver_verification_output_deferred`;
12. `axi_w_burst4_driver_backend_variants_deferred`; and
13. `axi_w_burst4_driver_other_protocols_unchanged`.

`.41` owns the exact report key placement, static strings, and residue detail
strings without changing behavior.

## Fail-closed diagnostics

PPIF ownership is additive: import/result dispatch, root accumulator/object
arm, exact cardinality/mixing checks, object/command/channel parsers,
predicate, missing-intent enumeration, and a family-specific `.axi` rejection.
Existing dispatch order and predicates remain unchanged.

Targeted negative coverage must reject before partial artifacts escape:

- wrong root, non-AXI family at the adapter, profile other than exact `axi4`
  at the generator, wrong role, or reset other than asynchronous active-low;
- missing, duplicate, or unknown driver/command/channel clauses;
- multiple burst4 objects or mixing with any existing intent object;
- missing or wrong-width data0-3, strobe0-3, driven data/strobe, or beat index;
- missing start/ready/valid/last/busy/beat-done/done/index binding;
- packed banks, streaming producer vocabulary, authored length, or a fifth
  tuple in this bounded object;
- duplicate public/private/reserved names or invalid ISF identifiers;
- attempts to override WLAST values, beat count, rules, storage, or artifacts;
  and
- `.axi` profile-alias use.

`.41` must freeze exact diagnostic wording and the malformed-case table.

## Public tooling and executable proof

One new PPIF fixture changes expected support totals from 306/347/347 to
**307 protocol fixtures, 348 supported fixtures, and 348 strict-supported
fixtures**. No `.axi` alias or generated fixture is added.

`t/1508` must contain exactly four top-level subtests:

1. adapter/report, exact anchors, schedule, storage, priorities, and artifacts;
2. malformed and expanded contracts fail closed;
3. strict check, support accounting, schedule JSON, semantic JSON, outdir,
   Verilator, and Yosys; and
4. assertion-disabled executable generated-HDL behavior.

The executable matrix must cover:

- command admission with WREADY low, already high, continuous, and pulsed;
- mutation of all upstream payload fields immediately after admission;
- exact tuple order with zero, partial, and full strobes;
- WDATA/WSTRB/WLAST stability across stalls at every index;
- WLAST exactly `0/0/0/1` and beat indices exactly `0/1/2/3`;
- four consecutive transfers without a WVALID bubble under held-high WREADY;
- one beat event for every handshake and one final done per completed burst;
- one ignored busy-time command with no payload corruption;
- reset at representative indices, no phantom event/completion, and clean
  post-reset recovery; and
- exact totals plus final WVALID/busy/events low.

The refined temporary harness passes:

```text
PASS handshakes=14 beat=14 done=3 busy_ignored=1 reset_abort=1
```

The fourteen transfers/events comprise three completed four-beat bursts plus
two accepted beats from a reset-aborted burst. Only three final completions are
legal. Strict JSON reports 18 ports, 30 signals, zero states, and no
diagnostics. The schedule reports the exact seven rules and five priorities;
Verilator and Yosys pass.

## Owner map and validation

| Surface | Required owner |
| --- | --- |
| parser/dispatch | `perl/FSM/Adapter/IAL2/PPIF.pm` |
| generator | new `perl/FSM/IAL2/ProtocolIntent/AxiWBurst4Driver.pm` |
| preserved one-beat generator | existing `AxiWDriver.pm`, unchanged |
| public source | new `ppif/axi_w_burst4_driver.ppif` |
| support accounting | `perl/FSM/Support/RegressionCorpus.pm`, t/248 |
| language manifest | `perl/FSM/Support/LanguageSurfaceSection.pm`, t/297 |
| public/HDL proof | new `t/1508-ial2-axi-w-burst4-driver.t` plus `.svt` fixture |
| user documentation | `docs/book/src/16a-ial2-axi.md` |
| continuity | task/index, Memory, behavior fact, Knowledge Map, git |

Focused implementation validation must include generator/adapter/test syntax;
t/1500, t/1502, t/1503, t/1507, t/1508, t/248, and t/297 under the repository
RAM policy; public strict/schedule/semantic/outdir/verify-HDL probes; exact
executable proof; mdBook build; Knowledge Map generation/check;
memory/docs-path/whitespace checks; and the doctrine gate. Temporary ISF, FSM,
SV, object, PDF-render, log, and JSON artifacts must be removed before commit.

## Explicit deferrals

This boundary does not add or imply:

- AW launch, address ownership, AWLEN/AWSIZE/AWBURST coupling, alignment,
  4-KiB legality, AW/W joining, or a request-completion event;
- B arming, BID/BRESP handling, or full-write completion;
- authored/dynamic beat counts, narrow/unaligned/FIXED/WRAP transfers, more
  than four beats, packed payload banks, or streaming payload supply;
- capacity/status submit/completion integration;
- adjacent back-to-back admission, multiple outstanding writes, buffering,
  queues, ID allocation/order/demux, or write-data interleaving;
- timeout, abort, retry, or resynchronization after a nonconforming peer;
- changes to any shipped write/read primitive or composition;
- `.axi` alias surfacing or verification-output generation;
- decision 0020's director-gated protocol-neutral transaction interface;
- direct backend lowering, backend-language variants, or VHDL behavior; or
- any AHB/APB behavior change.

## Next leaves and rollback

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.41` selects the exact public contract from
this audit: syntax, identities, anchors, names, lifecycle, schedule, report,
static/residue strings, diagnostics, owners, accounting, proof, and rollback.
It changes no behavior.

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.42` is the atomic implementation owner. It
must land parser, additive generator, source, support/manifest entries, exact
t/1508 proof, shipped mdBook documentation, behavior fact, continuity, and
cleanup in one signoff-level slice while preserving `AxiWDriver` and all
existing compositions.

Audit rollback removes this audit and its fact card, restores `.40` active,
removes `.41`/`.42`, and restores the task-index/book/Memory pointers. No code,
runtime, or HDL rollback is required because `.40` changes no behavior.
