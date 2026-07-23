# IAL2 AXI manager initiator — bounded B response acceptor readiness audit

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.12` (behavior-neutral readiness
audit).

Date: 2026-07-23

Status: ready for a separate public-contract selection. This audit changes no
parser, generator, public source, support-accounting entry, capability
manifest, test, generated artifact, runtime behavior, or HDL behavior.

## 1. Outcome

The bounded AXI manager B write-response-channel acceptor selected by `.11` is
ready for contract selection.

The safe first slice is an **explicitly armed, one-response receiver**:

1. accept one upstream arm command while idle;
2. assert manager-owned `BREADY` without waiting for subordinate-owned
   `BVALID`;
3. hold `BREADY` and busy high until one `BVALID && BREADY` transfer;
4. capture 4-bit `BID` and 2-bit `BRESP` on that transfer;
5. clear ready/busy on the same acceptance edge;
6. keep the captured response stable; and
7. emit exactly one later one-cycle `done` pulse for that arm.

The exact clause spelling, signal names, generator/result/schema identities,
and residue IDs belong to the next leaf,
`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.13`.

Continuously-ready acceptance is rejected for the bounded first slice. Without
an arm/ownership token, it can consume an unexpected response, and supporting
back-to-back responses safely would require buffering or a downstream
ready/valid interface. Those are outstanding-transaction concerns, not one
channel-primitive prerequisites.

## 2. Source Evidence And Inspection Method

The tracked source is
`docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf`
(Arm IHI 0022 Issue L). The prior AW/W audits established the tracked artifact
and visually checked physical pages 29-31 and 53-54. This audit re-used those
verified transport/dependency facts, text-extracted pages 61-62 and 278, and
rendered and visually checked the newly relied-upon B signal-list page 278.

| Source anchor | Physical page | Constraint carried into this audit |
| --- | ---: | --- |
| `A2.3 Valid-Ready transport` | 29 | A transfer occurs only when `VALID` and `READY` are both high. Once asserted, the transmitting side holds VALID and its information stable until transfer. |
| `A2.3.1 Valid-Ready signals`, Table A2.2 | 30 | `BVALID` marks valid B-channel information and `BREADY` marks that the manager can accept it. Both are scalar. |
| `A2.3.2.1 Write transaction dependencies` | 31 | The subordinate must wait for accepted AW, accepted W, and the final W beat before `BVALID`, and must not wait for `BREADY`; the manager may assert `BREADY` before or after `BVALID`. |
| `A3.3 Transaction response` | 61 | Transactions include response transfers from subordinate to manager. |
| `A3.3.1 Write response`, Tables A3.26-A3.28 | 61-62 | Write responses use the B channel. `BRESP_WIDTH` permits 0, 2, or 3 in Issue L and defaults to 2; advanced features can introduce a second response/`BCOMP`. |
| `B1.1.3 Write response channel`, Table B1.3 | 278 | `BVALID`, `BID`, and `BRESP` are subordinate-sourced; `BREADY` is manager-sourced. `BID` width is `ID_W_WIDTH`, `BRESP` width is `BRESP_WIDTH`; Issue L lists additional optional/advanced B signals. |

The dependency rule makes eager post-arm READY both legal and useful: the
manager need not create a combinational or temporal dependency on `BVALID`.
The subordinate remains responsible for not presenting a response before the
address and final data transfers have completed. This isolated acceptor does
not attempt to prove those upstream channel dependencies.

## 3. Repository Evidence

### Monitor substrate

`FSM::IAL2::ProtocolIntent::ValidReadyChannel` already accepts AXI channel `B`
and role `subordinate-to-manager`. It emits a monitor, not a receiver: both
VALID and READY are inputs, and it checks that the transmitter holds VALID and
payload stable while stalled.

That substrate establishes the B-channel profile/role vocabulary and transfer
condition, but it cannot be reused as the acceptor generator because the new
primitive must drive `BREADY`, own one response, register `BID`/`BRESP`, and
publish busy/done status.

The acceptor trusts the AXI subordinate's stall-stability obligation and
captures only on the handshake. Adding generated subordinate-protocol
assertions to this bus-driving primitive is not required for the first slice;
the generic monitor remains the appropriate independent checker.

### Shipped AW/W primitives

`AxiAwDriver` and `AxiWDriver` supply the common generator envelope:

```text
IAL2 PPIF contract
  -> generated actor .isf
  -> FSM::Adapter::ISF
  -> FSM::Scheduler::ISF
  -> generated .fsm
  -> HDL entry
```

Their corrected rule-pair idiom establishes how FSMGen avoids a second
Valid-Ready transfer when READY stays high. The B receiver reverses the data
direction and therefore must not clone the transmitter payload-sampling shape
mechanically, but it can use the same priority-resolved state ownership:
one rule arms activity/READY, and a higher-priority rule captures and clears on
the handshake edge.

### Capacity/status response seam

The shipped capacity/status family already models the logical side of a write
response. For example,
`ppif/axi_manager_capacity_status_response_demux.ppif` names:

```text
(write-complete axi0_write_complete)
(write (width 4) (request-id axi0_awid) (response-id axi0_bid))
...
(response-event axi0_write_complete)
```

`AxiManagerCapacityStatus` declares `axi0_bid` as a 4-bit input for explicit
write-response demux and uses the abstract response event to pulse the matched
logical transaction completion. It does not drive `BREADY`, sample `BRESP`, or
define the event as a physical B handshake.

The bounded acceptor can later feed that seam without changing the existing
core: its stable captured ID can feed the core's `BID` input and its one-cycle
done/event can feed `write_complete`. This later wiring is intentionally not
part of the first acceptor behavior slice.

### Architectural constraints

- Decision `0014` requires IAL2 -> generated `.isf` -> generated `.fsm`; the
  acceptor must not add direct IAL2-to-IAL0 lowering.
- Decision `0017` covers aggregate Valid-Ready monitor artifacts, not
  request/response composition or receiver ownership.
- Decision `0020` preserves this acceptor as a bus-side role primitive beneath
  a future protocol-neutral transaction layer; that future horizon is not
  activated here.

## 4. Selected First-Slice Behavior Boundary

### Explicit arming, not continuously ready

The receiver has one upstream arm trigger and exposes busy status. An arm is
admitted only while idle. While active, further arm pulses are outside the
accepted-command contract; there is no queue.

This policy is smaller and safer than always-ready:

- the primitive never accepts a response without an owned receive operation;
- one arm maps to exactly one handshake and one completion event;
- no response queue or downstream backpressure interface is required;
- a later AW/W/B coordinator can arm the receiver at write launch (or at the
  exact later point selected by that composition) and may legally let BREADY
  precede BVALID; and
- the captured payload can remain stable until the next accepted response,
  making a delayed logical completion pulse safe to consume.

### Fixed AXI4 widths

The first slice is profile `axi4`, matching the shipped AW/W sources.

- `BID` input: width 4, matching the shipped AW driver's fixed `AWID` width and
  the representative capacity/status response-demux family.
- captured response ID output: width 4.
- `BRESP` input: width 2, the bounded/default AXI4 response width already used
  throughout the repository's AXI response modeling.
- captured response status output: width 2.
- `BVALID`, `BREADY`, arm, busy, and done: scalar.

The acceptor captures the two-bit response opaquely; interpreting OKAY,
EXOKAY, SLVERR, or DECERR and converting them to a higher-level transaction
status is a later composition/policy concern.

`BRESP_WIDTH` 0/3, `BCOMP`, persistence, atomic/deferrable responses,
`BPENDING`/credits, `BIDUNQ`, `BUSER`, `BTAGMATCH`, `BTRACE`, `BLOOP`, and
`BBUSY` are outside the bounded AXI4 first slice.

### Recommended structural bindings

Exact spellings remain for `.13`, but the public contract must keep these
roles distinct.

**Inputs:**

| Role | Recommended spelling | Width | Rule |
| --- | --- | ---: | --- |
| arm command | `b_accept_cmd_valid` | 1 | one-shot, admitted only while idle |
| bus response valid | `bvalid` | 1 | subordinate-owned; may already be high when armed |
| bus response ID | `bid` | 4 | sampled only on `BVALID && BREADY` |
| bus response status | `bresp` | 2 | sampled only on `BVALID && BREADY` |

**Outputs:**

| Role | Recommended spelling | Width | Rule |
| --- | --- | ---: | --- |
| bus response ready | `bready` | 1 | asserted after arm without waiting for BVALID; held until handshake |
| captured response ID | `response_bid` | 4 | updated on handshake and stable until the next accepted response |
| captured response status | `response_bresp` | 2 | updated on handshake and stable until the next accepted response |
| activity | `b_busy` | 1 | high from arm launch until response acceptance |
| completion/event | `b_done` | 1 | one-cycle pulse once the armed receive transaction retires |

The source role should be `subordinate-to-manager`: VALID and response payload
travel from the subordinate to the manager even though the generated manager
primitive owns READY.

### Exact cardinality and timing invariant

For every accepted arm:

1. do not accept a B transfer while unarmed (`BREADY = 0`);
2. assert `BREADY` independently of `BVALID` and mark busy;
3. keep ready/busy asserted while waiting;
4. on exactly one rising edge with `BVALID && BREADY`, capture the presented
   ID/status and clear ready/busy;
5. never count another B transfer for that arm, even if `BVALID` remains high;
6. keep the captured ID/status stable until a later arm accepts a new
   response; and
7. emit exactly one one-cycle done pulse for the accepted response.

The physical response is accepted and captured on the handshake edge. The
current ISF transaction lowering emits `(complete ...)` after the wait loop
retires, so `done` is a later logical event, not a claim that the physical
handshake occurred on the pulse cycle. A later capacity-core composition is
safe because captured ID/status remain stable across that gap.

Back-to-back responses and same-cycle re-arm are not supported. A subordinate
presenting the next response must hold it until a later arm raises BREADY,
consistent with the AXI Valid-Ready rule.

## 5. Proven Generated-ISF Shape

The audit tested this behavior-neutral prototype outside the repository:

```text
(priority accept_b over arm_b)

(rule arm_b arm_b_start
  (set active_q 1)
  (set b_busy 1)
  (set bready 1))

(rule accept_b (& active_q bvalid bready)
  (set response_bid bid)
  (set response_bresp bresp)
  (set active_q 0)
  (set b_busy 0)
  (set bready 0))

(transaction b_receive
  (on b_accept_cmd_valid)
  (drive
    (arm_b_start 1))
  (while active_q
    (wait 1))
  (complete b_done))
```

The probe result was:

- strict check: PASS, zero diagnostics;
- generated schedule: six states, zero compile issues;
- priority resolution: exactly three accept-over-arm targets (`active_q`,
  busy, and `BREADY`);
- generated `.fsm` and SystemVerilog: emitted successfully;
- executable Verilator scenario 1: `BVALID` already high before arm and held
  high after acceptance, producing exactly one handshake/done and one capture;
- executable Verilator scenario 2: receiver armed while `BVALID` remains low
  for four cycles, with READY/busy held, then one valid response; and
- total: `PASS handshakes=2 done_pulses=2 bid=9 bresp=3`, final ready/busy low.

This establishes schedule feasibility; it is not a checked-in implementation.
`.13` must select the exact generated actor and report contract, and the later
behavior leaf must reproduce the proof from the public PPIF source in a
checked-in focused test.

## 6. Exact Implementation Owner Map

### Parser and dispatch

`perl/FSM/Adapter/IAL2/PPIF.pm` is the public syntax owner. The behavior leaf
after `.13` will need all of these additive changes together:

- import the selected B acceptor generator beside `AxiAwDriver` and
  `AxiWDriver`;
- add a generator dispatch arm in `parse_source` before the manager/status
  fallthrough;
- reject the new object explicitly for `.axi` until alias exposure is owned;
- add a B-acceptor accumulator and clause dispatch in `_contract_from_root`;
- extend the missing-intent diagnostic;
- enforce exactly one object, AXI-family profile, and no mixing with any other
  intent object;
- return the B acceptor contract with intent/profile/source metadata;
- add the selected object parser plus arm/channel binding-block parsers; and
- add an `_is_*_contract` predicate beside the AW/W predicates.

The implementation must update every mixing predicate symmetrically. Missing
one would allow an ambiguous aggregate or make an unrelated object fall
through to the wrong generator.

### Generator

Add one module under `perl/FSM/IAL2/ProtocolIntent/`, with a likely descriptive
name `AxiBResponseAcceptor.pm` subject to `.13`.

It must mirror the defensive AW/W envelope:

- validate constructor and generator invocation;
- normalize profile/role/reset/source/bindings fail-closed;
- enforce the fixed widths and all signal-name uniqueness;
- emit the proven receiver ISF rule pair and transaction;
- lower only through `FSM::Adapter::ISF` and `FSM::Scheduler::ISF`;
- return generated IAL1 text, generated IAL0 files, schedule report, and one
  selected HDL entry; and
- report source, layering, bindings, explicit-arm/single-response policy,
  captured-response policy, enforced static rules, and honest residue.

### Public source

Add one generic `.ppif` source, likely
`ppif/axi_b_response_acceptor.ppif` subject to `.13`, with profile `axi4`, one
B acceptor object, role `subordinate-to-manager`, clock/reset, distinct arm and
channel/status bindings, and the six source anchors in section 2.

The source must not add AW/W objects or expose a `.axi` alias.

### Support accounting and manifest

Add one `RegressionCorpus` protocol-fixture entry beside the AW/W entries:

- classification `supported_smoke`;
- source kind `ppif`;
- strict supported;
- selected coverage identity;
- selected expected module; and
- semantic source root `fsm`.

The current t/248 baselines are 299 protocol fixtures, 340 supported-smoke
entries, and 340 strict-supported entries. The implementation should move them
to 300/341/341 and add the new coverage identity to the known/expected maps.

Extend the `.ppif` `current_boundary` sentence in
`LanguageSurfaceSection.pm` and add the matching t/297 assertion. That sentence
already names both bounded AW and W drivers; the B acceptor must be presented
as a bounded response primitive, not a complete AXI manager.

### Focused test and book

Reserve `t/1501-ial2-axi-b-response-acceptor.t` for the behavior slice. It
should mirror t/1499 and t/1500 and cover:

- adapter result/layer/kind/mode/schema/source/report bindings;
- exact source anchors and residue;
- fail-closed profile, role, width, cardinality, duplicate-name, mixed-object,
  and `.axi` cases;
- strict check, semantic JSON, schedule JSON, outdir artifacts, and
  `--verify-hdl` (Verilator lint plus Yosys synthesis);
- six states, zero compile issues, and the three expected priority
  resolutions; and
- generated-HDL execution with unarmed BVALID, already-high/held-high BVALID,
  delayed BVALID after four ready/busy cycles, two distinct BID/BRESP values,
  exactly two handshakes/two done pulses, correct captures, stable captured
  payload, and final ready/busy low.

Update `docs/book/src/16a-ial2-axi.md` from “selected next boundary” to the
actual shipped source only in that behavior slice. The book must distinguish
the handshake-edge capture from the later done pulse and keep composition
deferred.

## 7. Fail-Closed Rules For Contract Selection

`.13` must fix exact diagnostics and report spellings for at least:

- profile exactly `axi4` in the generator;
- role exactly `subordinate-to-manager`;
- fixed 4-bit bus/captured ID and 2-bit bus/captured response widths;
- scalar arm/VALID/READY/busy/done;
- all external and internal binding names unique;
- exactly one B acceptor object per source;
- no mixing with monitors, manager/status, AW/W drivers, APB, or AHB objects;
- exactly one of each required clause/binding and rejection of unknown clauses;
- source anchors complete and scalar;
- `.axi` alias rejected explicitly; and
- no direct IAL2-to-IAL0 path.

The report should include an explicit bounded response policy rather than
forcing consumers to infer it from raw signal bindings:

```text
arming: explicit_one_response
ready_policy: assert_after_arm_without_waiting_for_valid
accept_condition: bvalid && bready
id_width: 4
response_width: 2
capture: on_accept_and_hold_until_next_accept
done: one_pulse_per_accepted_arm_after_transaction_retirement
back_to_back: unsupported
```

These are semantic fields; `.13` owns their final JSON keys and values.

## 8. Explicit Deferrals And Residue

The first behavior slice must report, not imply away:

- AW/W/B coordination and complete write transacting;
- integration with capacity/status, response demux, and ID allocation;
- multiple outstanding or queued receives, same-cycle re-arm, and back-to-back
  response throughput;
- response-status interpretation and protocol-neutral completion mapping;
- configurable ID width and `BRESP_WIDTH` 0/3;
- `BCOMP`, persistence, atomic/deferrable/MTE responses, credit transport,
  `BIDUNQ`, `BUSER`, and other B-channel sidebands;
- generated subordinate stall assertions inside the acceptor;
- multi-beat/burst address/data coupling;
- AR/R behavior;
- decision `0020` transaction-interface activation;
- `.axi` alias exposure;
- verification-output generation;
- direct backend lowering, backend-language variants, and VHDL; and
- AHB/APB changes.

## 9. Validation And Rollback

This audit is documentation-only. Closeout requires:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
prove -Iperl t/1414-docs-relative-paths-audit.t
git diff --check
scripts/check_doctrines.sh
```

The temporary ISF/Verilator proof lives under `/tmp` and is not a repository
artifact.

Rollback removes this audit/fact, restores `.12` active, removes `.13`, and
restores the prior task-index/book/Memory pointers. No parser, generator,
source, support entry, manifest, test, generated artifact, or HDL rollback is
required.

## 10. Selected Next Leaf

Proceed with `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.13`: select the exact public
contract for the explicitly armed, fixed-width, one-response B acceptor. `.13`
must pin clause/object names, command/channel vocabulary, generator/result/
schema/source/module/support/test identities, report/residue, diagnostics,
executable test scenarios, validation, rollback, and the following behavior
implementation leaf without changing behavior itself.
