# IAL2 AXI manager initiator — full-read transaction composition readiness audit

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.32` (behavior-neutral audit).

Date: 2026-07-23

Status: ready for exact public-contract selection. This leaf changes no parser,
generator, public source, support entry, manifest, test, generated artifact,
runtime behavior, or HDL behavior.

## Outcome

The selected bounded AXI4 manager fixed-single-beat full-read transaction is
implementable as one **flat three-child C4 composition**:

- the shipped `axi_ar_driver`, reused unchanged;
- the shipped `axi_r_beat_acceptor`, reused unchanged; and
- one new zero-state, rule-only `axi_read_transaction_coordinator`.

One aligned public address32/ID4 command is retained by the coordinator. It
starts the private AR child with fixed `ARLEN=8'd0`, `ARSIZE=3'd2`, and
`ARBURST=2'b01` (INCR). The coordinator arms the private R child only after the
AR child reports acceptance. It retains aggregate ownership until that R child
accepts and captures exactly one RID4/RDATA32/RRESP2/RLAST1 beat.

The result boundary is deliberately not a success boolean:

- request done means the fixed AR request was accepted;
- transaction done means the one owned R beat was accepted, captured, and the
  bounded transaction retired;
- raw RRESP is re-exported without interpreting OKAY or error;
- stable ID-match and last-match status record whether captured RID equals the
  admitted ARID and whether the fixed single beat carried RLAST; and
- RID mismatch or missing RLAST is assertion-visible but terminal after the
  already-consumed beat. It cannot wait for a replacement response.

Scratch generation, strict compilation, semantic inspection, external HDL
verification, and executable generated-HDL testing all pass. The proposal is
ready for `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.33`, the exact public-contract
selector; `.34` is reserved for the later atomic implementation.

## Evidence and prerequisites

The audit reconciled:

- `AxiArDriver.pm`, its exact six-state launch/accept schedule, generated
  artifacts/report, and `t/1504` continuous/stalled/pulsed-READY proof;
- `AxiRBeatAcceptor.pm`, its exact six-state arm/accept schedule, raw capture
  contract, and `t/1505` unarmed/already-high/held/delayed-VALID proof;
- `AxiWriteTransactionComposition.pm` and `t/1503` as the shipped reference for
  flat endpoint/coordinator composition, fixed metadata connections, retained
  ID correlation, separate completion pulses, raw response status, terminal
  mismatch, active reset, and generated-top execution;
- the AR and R public samples' Issue L source anchors and the read dependency,
  completion, RLAST, RRESP, ID-width, and signal-direction evidence recorded in
  the `.31` selector;
- capacity/status read submission, transaction envelopes, RID demux, read-data
  banks, ARLEN capture, beat-count/RLAST validation, and RRESP aggregation as a
  deeper abstract seam that is not silently coupled here;
- PPIF parser/dispatch/cardinality/mixing/profile-alias owners, regression
  support, the language manifest, the AXI mdBook, task continuity, and the
  Knowledge Map; and
- decisions 0014, 0015, 0018, and 0020.

No new source-reference interpretation was required. The selected public
source must use the de-duplicated ordered union of the shipped AR and R
dependencies:

| Order | Section | Page | Reason |
| ---: | --- | --- | --- |
| 1 | A2.3 | 29 | channel dependency baseline |
| 2 | A2.3.1 | 30 | handshake dependency rules |
| 3 | A2.3.2.2 | 32 | read response follows an accepted read request |
| 4 | A2.6 | 41 | manager accepts returned read data |
| 5 | A3.1 | 42 | burst transaction attributes |
| 6 | A3.1.1 | 43 | burst length |
| 7 | A3.1.2 | 44 | burst size |
| 8 | A3.1.4 | 46 | burst type |
| 9 | A3.2.2 | 55 | RLAST final transfer |
| 10 | A3.3.2 | 62 | read response signaling |
| 11 | A5.1.1 | 90 | ARID/RID width relationship |
| 12 | B1.2.1 | 279 | read-address signal directions |
| 13 | B1.2.2 | 281 | read-data signal directions |

`.33` must preserve these thirteen anchors in this order and use source object
`axi-read-transaction-composition`.

## Exact public boundary recommended to `.33`

The additive family is fixed as:

```text
(axi-read-transaction-composition axi_read_transaction_composition
  (role manager)
  (clock clk)
  (reset (rst_n active_low async))
  (command
    (start read_cmd_valid)
    (address cmd_read_addr width 32)
    (id cmd_read_id width 4))
  (ar-channel
    (ready arready)
    (valid arvalid)
    (address araddr width 32)
    (id arid width 4)
    (length arlen width 8)
    (size arsize width 3)
    (burst arburst width 2))
  (r-channel
    (valid rvalid)
    (ready rready)
    (id rid width 4)
    (data rdata width 32)
    (response rresp width 2)
    (last rlast)
    (captured-id response_rid width 4)
    (captured-data response_rdata width 32)
    (captured-response response_rresp width 2)
    (captured-last response_rlast))
  (status
    (busy read_busy)
    (request-done read_request_done)
    (transaction-done read_transaction_done)
    (response-id-match response_id_match)
    (response-last-match response_last_match)))
```

The exact aggregate role is `manager`: the object drives AR and RREADY while
receiving ARREADY and the R payload, so neither single-channel directional role
describes the whole transaction. The reset is shared asynchronous active-low
`rst_n`; all three children use it unchanged.

Recommended identities are:

| Surface | Exact identity |
| --- | --- |
| parser kind | `protocol_intent.axi_read_transaction_composition` |
| mode | `read-transaction-composition` |
| generator | `FSM::IAL2::ProtocolIntent::AxiReadTransactionComposition` |
| report schema | `fsmgen.ial2.protocol_intent.axi_read_transaction_composition.v1` |
| public source | `ppif/axi_read_transaction_composition.ppif` |
| intent/top/module | `axi_read_transaction_composition` |
| coordinator | `axi_read_transaction_coordinator` |
| support id | `intent.ppif_axi_read_transaction_composition` |
| coverage key | `ial2_ppif_axi_read_transaction_composition_pipeline_cli` |
| focused owner | `t/1506-ial2-axi-read-transaction-composition.t` |

`.33` freezes the syntax and identities rather than revisiting the selected
architecture.

## Fixed request legality

The composition exposes address and ID only. It does not expose dynamic ARLEN,
ARSIZE, or ARBURST command inputs. Its private AR child receives exact sized
constants:

```text
(=8'd0 ar_driver.cmd_arlen)
(=3'd2 ar_driver.cmd_arsize)
(=2'b01 ar_driver.cmd_arburst)
```

This means one four-byte data transfer in an INCR burst. Admission requires
`cmd_read_addr[1:0] == 2'b00`; a misaligned idle command both fails to launch
and violates an emitted assertion. This matches the full-write composition's
safe fail-closed policy. There is no wrap boundary, beat progression, narrow
lane placement, or ARLEN/RLAST counter to define in this slice.

An idle command atomically captures address32 and ID4. A command offered while
the aggregate is busy is ignored and not queued; it cannot overwrite the
retained AR payload or expected response ID. A command held until the aggregate
returns idle remains level-sampled and may then be admitted. This is not an
edge-triggered or back-to-back queue contract.

## Child reuse and private namespace

The implementation must call the two shipped generators and reuse their
generated IAL1/leaf-IAL0 results. It must not copy their ISF text or alter their
standalone public behavior.

The coordinator owns the public command and aggregate status. Collision-free
private bindings are exact:

| Coordinator/child handoff | Width |
| --- | ---: |
| `ar_cmd_valid_i` -> `ar_driver.ar_cmd_valid` | 1 |
| `ar_cmd_addr_i` -> `ar_driver.cmd_araddr` | 32 |
| `ar_cmd_id_i` -> `ar_driver.cmd_arid` | 4 |
| `ar_driver.ar_busy` -> `ar_busy_i` | 1 |
| `ar_driver.ar_done` -> `ar_done_i` | 1 |
| `r_arm_i` -> `r_acceptor.r_accept_cmd_valid` | 1 |
| `r_acceptor.r_busy` -> `r_busy_i` | 1 |
| `r_acceptor.r_beat_done` -> `r_done_i` | 1 |
| `r_acceptor.response_rid` -> `captured_rid_i` | 4 |
| `r_acceptor.response_rlast` -> `captured_rlast_i` | 1 |

Public AR/R bus and captured-result names connect by name. Captured RID and
RLAST therefore fan out legally from the R child to both the top-level outputs
and the coordinator comparison inputs. Captured RDATA and RRESP bypass the
coordinator and are re-exported directly. The C4 resolver proves this fanout
has one source, not multiple drivers.

## Coordinator contract and schedule

### Exact interface and retained state

The coordinator has 18 interface ports:

- inputs: `read_cmd_valid`, `cmd_read_addr[31:0]`, `cmd_read_id[3:0]`,
  `ar_busy_i`, `ar_done_i`, `r_busy_i`, `r_done_i`,
  `captured_rid_i[3:0]`, and `captured_rlast_i`;
- private outputs: `ar_cmd_valid_i`, `ar_cmd_addr_i[31:0]`,
  `ar_cmd_id_i[3:0]`, and `r_arm_i`; and
- public outputs: `read_busy`, `read_request_done`,
  `read_transaction_done`, `response_id_match`, and
  `response_last_match`.

Internal `active_q`, `expected_arid_q[3:0]`, and `response_armed_q` retain
transaction ownership. The registered AR handoff outputs retain address/ID
through the child start. Reset clears every ownership bit, private pulse,
aggregate pulse/status output, and retained value according to generated
zero-reset behavior.

### Exact seven-rule target

| Rule | Assignments | Purpose |
| --- | ---: | --- |
| `admit` | 6 | retain address/ID, pulse AR start, raise active/busy |
| `clear_ar_start` | 1 | clear registered AR-start pulse |
| `arm_response` | 3 | mark response armed, pulse R arm and request done |
| `clear_r_arm` | 1 | clear registered R-arm pulse |
| `clear_request_done` | 1 | clear request-done pulse |
| `finish_response` | 6 | retire, lower busy, pulse transaction done, record ID/last match |
| `clear_transaction_done` | 1 | clear transaction-done pulse |

The target has zero procedural states and no compile issues. Six authored
priorities are exact:

```text
finish_response over admit
finish_response over arm_response
finish_response over clear_transaction_done
arm_response over clear_r_arm
arm_response over clear_request_done
admit over clear_ar_start
```

Only four produce scheduler resolutions because the two remaining finish
conflicts are statically mutually exclusive under `active_q` and
`response_armed_q`:

| Winner | Loser | Target |
| --- | --- | --- |
| `admit` | `clear_ar_start` | `ar_cmd_valid_i` |
| `arm_response` | `clear_r_arm` | `r_arm_i` |
| `arm_response` | `clear_request_done` | `read_request_done` |
| `finish_response` | `clear_transaction_done` | `read_transaction_done` |

Three assertion-only transactions add no states:

1. an otherwise-admissible idle command is four-byte aligned;
2. owned R completion has captured RID equal to retained ARID; and
3. owned fixed-single-beat R completion has captured RLAST high.

`.33` must freeze the exact rule, priority, assertion, message, assignment,
and reset spellings shown by this audit.

## Causal timing and completion

All cross-child handoffs are registered. The exact causal sequence is:

1. aligned idle admission raises aggregate busy, retains address/ID, and
   produces one private AR-start pulse;
2. the unchanged AR child accepts that pulse and owns ARVALID/payload until
   `ARVALID && ARREADY`;
3. its later `ar_done_i` pulse causes the coordinator to pulse public request
   done and private R arm together;
4. the unchanged R child consumes that registered arm and raises RREADY
   independently of RVALID;
5. one `RVALID && RREADY` captures the raw beat and later produces `r_done_i`;
6. the coordinator records ID/last match, lowers busy, and pulses transaction
   done; the R child holds the raw captured tuple.

There is intentionally no combinational ARREADY-to-RREADY path and no R arm
before `ar_done_i`. If RVALID is already high after the AR handshake, AXI
requires the subordinate to retain its payload until the later RREADY. A
transient nonconforming RVALID pulse before ownership is ignored. Held-high
RVALID cannot create a second handshake because the one-beat child drops
RREADY after acceptance.

`read_request_done` and `read_transaction_done` are distinct one-cycle pulses.
`read_busy` spans public admission through response retirement. Raw captured
result and match statuses describe the most recently completed transaction
and remain stable until reset or later accepted data/completion replaces them.

## Terminal response policy

The composition consumes exactly one owned beat. On completion it compares:

```text
response_id_match   = (captured RID == retained admitted ARID)
response_last_match = captured RLAST
```

Both failures are protocol/ownership errors and trip generated assertions when
assertions are enabled. With assertions disabled they still set the relevant
status to zero, preserve the raw captured beat, pulse transaction done, and
return idle. Wedges and replacement-beat waits are rejected because the beat
was consumed and the fixed request can legally produce no second beat.

Every two-bit RRESP encoding is terminal raw status. Non-OKAY does not suppress
transaction done and does not alter ID/last match. This slice does not claim
that RDATA is semantically usable on an error response and does not map RRESP
to a protocol-neutral result.

## Proven structural and executable evidence

The exact scratch top strict-checks with no diagnostics:

```text
module_name                    = axi_read_transaction_composition
signal_count                   = 27
composition_child_count        = 3
composition_generated_children = 3 FSM children
composition_net_count          = 41
composition_resolved_link_count= 44
lane                           = C4
```

The generated SystemVerilog is 1,793 lines and contains the two unchanged
child modules, the new coordinator, and the structural top. `--verify-hdl`
passes Verilator lint and Yosys synthesis.

An assertion-disabled generated-HDL harness proves:

- misaligned command non-launch;
- fixed AR metadata on every driven request;
- RREADY low before owned AR completion;
- RVALID already high before admission, then accepted exactly once after arm;
- four-cycle AR backpressure with stable retained payload while public command
  fields mutate and another busy command is ignored;
- delayed RVALID with RREADY/busy retained;
- matching RID/RLAST and raw non-OKAY RRESP capture;
- mismatched RID plus missing RLAST plus raw non-OKAY RRESP as one terminal
  response with both match statuses low;
- asynchronous active reset during a stalled AR and during an armed R wait;
- no phantom R/transaction completion across either reset; and
- a clean post-reset transaction and final idle state.

The exact final cardinality is:

```text
PASS ar=5 r=4 request=5 transaction=4
     mismatch_terminal=1 missing_last_terminal=1 reset_abort=2
```

The deliberate 5/4 asymmetry is the armed-R reset case: its AR request and
request-done occur, then reset cancels response ownership before an R
handshake or transaction-done. This is the required truthful reset behavior,
not a lost completion.

## Artifact, report, and public tooling boundary

The implementation result must expose exactly:

- three generated IAL1 items and schedule reports: AR child, R child, and read
  transaction coordinator;
- three generated leaf IAL0 FSMs plus one selected structural top;
- one collision-checked combined file map;
- one `generated_composition_top` HDL entry selecting
  `axi_read_transaction_composition.fsm`;
- semantic root `top`, lane C4, 27 signals, three FSM children, and no nested
  top; and
- `direct_ial2_to_ial0 = false`.

`--emit-schedule-json` exposes all three schedules. `--outdir` emits three
`.isf` files, the three child `.fsm` files, and the selected top `.fsm`.
`--emit-semantic-json`, strict check JSON, normal HDL output, and
`--verify-hdl` all select the structural top. Strict rejection emits no partial
generated output.

The report must contain exact sections for source object/anchors, target
protocol, command/AR/R/result/status bindings, fixed-single-beat policy, AR/R
child reuse, read coordinator policy, children, generated schedules,
artifacts/HDL entry, enforced static rules, and unsupported residue.

The ordered enforced-static set has twelve entries:

1. exact AXI4 profile, object, and aggregate manager role;
2. shared clock and asynchronous active-low reset for all three children;
3. one idle admission atomically captures aligned address32 and ID4;
4. AR metadata is fixed to LEN0/SIZE2/INCR for one four-byte beat;
5. flat C4 reuses unchanged AR/R actors plus one coordinator;
6. private handoffs isolate child links while raw captured outputs fan out;
7. R is armed only after owned AR acceptance;
8. aggregate busy spans admission through R retirement and request/transaction
   done are distinct one-cycle pulses;
9. captured RID and RLAST are checked against retained ARID and fixed-one-beat
   expectation; either mismatch terminally completes with status zero plus
   assertion;
10. RID4/RDATA32/RRESP2/RLAST1 remain raw captured results and RRESP is not
    interpreted as success;
11. all public bindings, generated internal signals, instances, and artifact
    names are distinct; and
12. lowering is IAL2 through three generated IAL1 and three leaf IAL0 actors
    into one structural IAL0 top, never direct IAL2-to-IAL0.

The ordered residue set has thirteen IDs:

1. `axi_read_transaction_composition_capacity_core_integration_deferred`;
2. `axi_read_transaction_composition_outstanding_queueing_deferred`;
3. `axi_read_transaction_composition_id_allocation_ordering_demux_deferred`;
4. `axi_read_transaction_composition_dynamic_multi_beat_deferred`;
5. `axi_read_transaction_composition_narrow_unaligned_attributes_deferred`;
6. `axi_read_transaction_composition_response_status_aggregation_deferred`;
7. `axi_read_transaction_composition_extended_r_monitoring_deferred`;
8. `axi_read_transaction_composition_write_channels_deferred`;
9. `axi_read_transaction_composition_transaction_interface_deferred`;
10. `axi_read_transaction_composition_profile_alias_deferred`;
11. `axi_read_transaction_composition_verification_output_deferred`;
12. `axi_read_transaction_composition_backend_variants_deferred`; and
13. `axi_read_transaction_composition_other_protocols_unchanged`.

`.33` must freeze their exact detail strings and report locations.

## Fail-closed parser and diagnostic boundary

The new family is additive. Existing standalone AR/R, write compositions,
capacity/status, Valid-Ready, APB, AHB, and all unrelated parser paths remain
unchanged. PPIF ownership requires import/result dispatch, root accumulator and
object arm, exact cardinality/mixing checks, object/block parsers, predicate,
missing-intent enumeration, and read-composition-specific `.axi` rejection.

Targeted diagnostics must cover:

- wrong root, profile other than exact `axi4`, wrong aggregate role, and reset
  other than asynchronous active-low;
- missing, duplicate, or extra composition objects or required command/AR/R/
  status clauses;
- mixing with either standalone child, either write composition, other AXI
  intent, Valid-Ready, APB, or AHB objects;
- any dynamic AR metadata or command data/size/length/burst extension;
- every wrong public width, non-scalar ready/valid/last/status binding, absent
  captured R field, missing request/transaction done, or missing ID/last match;
- duplicate public/internal/reserved names and generated artifact collisions;
- nested child overrides, nested tops, extra clauses/channels/policy
  vocabulary, response-success claims, or omitted ID/RLAST checks; and
- unsupported `.axi` profile-alias use.

All malformed cases fail before partial generated artifacts escape. `.33`
owns exact diagnostic strings and the precise negative-test table.

## Owner map and expected accounting

| Surface | Required owner |
| --- | --- |
| parser/dispatch | `perl/FSM/Adapter/IAL2/PPIF.pm` |
| aggregate generator | new `perl/FSM/IAL2/ProtocolIntent/AxiReadTransactionComposition.pm` |
| AR child | existing `AxiArDriver.pm`, unchanged |
| R child | existing `AxiRBeatAcceptor.pm`, unchanged |
| public sample | new `ppif/axi_read_transaction_composition.ppif` |
| support accounting | `perl/FSM/Support/RegressionCorpus.pm`, t/248 |
| language manifest | `perl/FSM/Support/LanguageSurfaceSection.pm`, t/297 |
| public/HDL proof | new `t/1506-ial2-axi-read-transaction-composition.t` |
| user documentation | `docs/book/src/16a-ial2-axi.md` |
| continuity | task/index, Memory, behavior fact, Knowledge Map, git |

One new public PPIF fixture moves the exact expected totals from
304/345/345 to **305 protocol fixtures, 346 supported fixtures, and 346 strict-
supported fixtures**. No `.axi` alias or separate generated fixture is added.

The focused test must have exactly four top-level subtests mirroring t/1503:

1. adapter report, exact schedules/artifacts, and flat three-child contract;
2. malformed/expanded contracts fail closed;
3. CLI support, schedule, semantic, outdir, and Verilator/Yosys proof; and
4. executable generated-top lifecycle/cardinality proof.

Focused validation includes t/1499-t/1506, t/248, t/297, public strict/
schedule/semantic/outdir/verify-HDL probes, syntax, mdBook build, Knowledge Map,
memory/docs-path/whitespace, and all doctrines under repository RAM policy.

## Explicit deferrals

This boundary does not add or imply:

- dynamic ARLEN/ARSIZE/ARBURST, repeated/multi-beat R receipt, beat counters,
  dynamic RLAST validation, burst progression, or response aggregation;
- capacity/status submit/completion integration or selection of one of its
  existing read-data/demux families;
- multiple outstanding reads, adjacent back-to-back admission, buffering,
  queues, ID allocation/reuse/order, RID demux, or read-data interleaving;
- narrow/unaligned transfers, wrapping bursts, extended AR attributes, or
  extended R sidebands and subordinate stall monitoring;
- protocol-neutral RRESP/result mapping or a guarantee that error RDATA is
  usable;
- any write-side behavior;
- `.axi` aliases or direct verification-output generation;
- direct backend lowering, backend-language variants, or VHDL behavior;
- decision 0020's director-gated protocol-neutral transaction interface; or
- AHB/APB behavior.

The mandatory chain remains:

```text
IAL2 full-read object
  -> three generated IAL1 actors
  -> three generated leaf IAL0 FSMs
  -> one flat three-child structural IAL0 top
  -> HDL
```

## Next leaves and rollback

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.33` selects the exact public contract from
this audit: syntax, anchors, identities, report/static/residue, diagnostic
table, schedule, topology/wiring, proof matrix, accounting, owners, rollback,
and implementation leaf. It changes no behavior.

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.34` is the atomic implementation owner. It
must land parser, generator, public source, support/manifest entries, exact
t/1506 proof, mdBook shipped documentation, behavior fact, task continuity,
and generated-artifact cleanup in one signoff-level slice.

Audit rollback removes this audit and its fact, restores `.32` active, removes
the `.33`/`.34` leaves, and restores the task-index/book/Memory pointers. No
behavior rollback is required because `.32` changes no runtime surface.
