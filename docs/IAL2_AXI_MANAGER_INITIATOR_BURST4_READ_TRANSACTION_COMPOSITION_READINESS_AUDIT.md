# IAL2 AXI manager initiator — fixed-four read transaction composition readiness audit

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.36` (behavior-neutral audit).

Date: 2026-07-23

Status: ready for exact public-contract selection. This leaf changes no parser,
generator, public source, support entry, manifest, test, generated artifact,
runtime behavior, or HDL behavior.

## Outcome

The first honest multi-beat physical read boundary is a fixed **four-beat,
full-width INCR** AXI4 manager transaction, not an authored bounded length.
It is implementable as one flat three-child C4 composition:

- the shipped `axi_ar_driver`, reused unchanged;
- the shipped one-arm/one-beat `axi_r_beat_acceptor`, reused unchanged and
  explicitly re-armed four times; and
- one new zero-state, rule-only
  `axi_read_burst4_transaction_coordinator`.

One legal address32/ID4 command emits fixed `ARLEN=8'd3`, `ARSIZE=3'd2`, and
`ARBURST=2'b01` (INCR). Admission requires four-byte alignment and a complete
16-byte span within one 4-KiB region. One AR transfer owns exactly four later R
transfers with the retained ARID.

The public result boundary is deliberately raw and beat-oriented:

- `read_request_done` means the AR request accepted;
- `read_beat_done` means one raw RID4/RDATA32/RRESP2/RLAST1 tuple is captured;
- `response_beat_index[1:0]` identifies that tuple as beat 0 through 3;
- `read_transaction_done` means the fourth expected beat was captured and the
  bounded ownership interval retired;
- `response_id_match` is sticky across all four RID comparisons; and
- `response_last_match` is sticky across the expected RLAST sequence: low on
  indices 0-2 and high on index 3.

Beat count is authoritative. Early RLAST, RID mismatch, and non-OKAY RRESP do
not terminate the burst: the manager continues accepting all four transfers.
Missing final RLAST retires at the fourth accepted beat with last-match low.
Every RRESP remains raw and is meaningful with `read_beat_done`; this physical
composition does not add sticky RRESP aggregation or a success boolean.

Scratch IAL1/C4 generation, strict checks, semantic inspection, Verilator,
Yosys, and an assertion-disabled executable harness all pass. The exact
candidate is ready for
`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.37`, the behavior-neutral public-contract
selector. `.38` is reserved for the atomic implementation.

## Evidence and source interpretation

The audit inspected the shipped full-read source, generator, coordinator/top,
generated AR/R children, `t/1506`, the capacity/status burst and output-bank
seams, PPIF/support/manifest/book owners, decisions 0014/0015/0018/0020, and
the local Issue L reference:

`docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf`.

Relevant pages were rendered and visually checked, not inferred from search
snippets:

| Order | Section | Page | Constraint fixed here |
| ---: | --- | ---: | --- |
| 1 | A2.3 | 29 | channel dependency baseline |
| 2 | A2.3.1 | 30 | handshake dependency rules |
| 3 | A2.3.2.2 | 32 | AR acceptance precedes returned R data; subordinate cannot wait for RREADY |
| 4 | A2.6 | 41 | after a read request, the manager must accept all returned read data |
| 5 | A3.1 | 42 | burst attributes and prohibition on crossing 4 KiB |
| 6 | A3.1.1 | 43 | ARLEN encodes transfers minus one; ARSIZE `010` is four bytes |
| 7 | A3.1.2 | 44 | no early burst termination; all transfers complete even when data is discarded |
| 8 | A3.1.4 | 46 | ARBURST `01` is INCR and aligned word addresses increment by four |
| 9 | A3.2.2 | 55 | RLAST marks the final read transfer |
| 10 | A3.3.2 | 62 | one RRESP accompanies each transfer; all length-selected transfers complete regardless of response |
| 11 | A5.1.1 | 90 | ARID and RID share the read ID width |
| 12 | B1.2.1 | 279 | read-address signal directions |
| 13 | B1.2.2 | 281 | RVALID/RID/RDATA/RRESP/RLAST are subordinate outputs; RREADY is manager output |

The new public source must preserve these thirteen anchors in this exact order
and use source object `axi-read-burst4-transaction-composition`.

The decisive protocol consequence is that ARLEN, not an observed error or
early RLAST, establishes the accepted transfer count. An early RLAST is a
subordinate violation and makes the sticky last-match result false, but it
does not authorize the manager to stop accepting the remaining transfers.
If a nonconforming subordinate stops transmitting after early RLAST, this
bounded manager remains busy waiting for the missing transfers; assertion and
timeout/recovery policy are separate concerns and stay explicit residue.

## Fixed four versus authored bounded length

| Candidate | Required new surface | Risk/proof size | Disposition |
| --- | --- | --- | --- |
| Fixed four full-width INCR | No new command metadata; one two-bit index; exact 16-byte legality predicate; four re-arms | Bounded exhaustive beat-position proof and one exact terminal count | **Selected** |
| Authored bounded ARLEN | Public length input and accepted range; wider counter; dynamic 4-KiB span calculation; zero/maximum semantics; broader test matrix | Mixes repeated reception with dynamic request legality and result-consumption policy | Deferred |

Fixed four is the smallest slice that genuinely proves repeated response
ownership. Fixed two would exercise repetition but would not match the
existing four-beat burst patterns used elsewhere in the AXI/AHB surfaces;
fixed four remains exhaustive with only a two-bit counter and tests early,
middle, and final positions without generalizing the command API.

## Exact public boundary recommended to `.37`

The additive family is:

```text
(axi-read-burst4-transaction-composition axi_read_burst4_transaction_composition
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
    (beat-done read_beat_done)
    (transaction-done read_transaction_done)
    (response-beat-index response_beat_index width 2)
    (response-id-match response_id_match)
    (response-last-match response_last_match)))
```

The exact aggregate role is `manager`. All three children share `clk` and an
asynchronous active-low `rst_n`. Public binding names, generated private
signals, instance names, object names, and artifact names must be globally
distinct under the existing fail-closed duplicate-name check.

Recommended identities are:

| Surface | Exact identity |
| --- | --- |
| parser contract kind | `axi_read_burst4_transaction_composition` |
| result kind | `protocol_intent.axi_read_burst4_transaction_composition` |
| mode | `read-burst4-transaction-composition` |
| generator | `FSM::IAL2::ProtocolIntent::AxiReadBurst4TransactionComposition` |
| report schema | `fsmgen.ial2.protocol_intent.axi_read_burst4_transaction_composition.v1` |
| public source | `ppif/axi_read_burst4_transaction_composition.ppif` |
| intent/top/module | `axi_read_burst4_transaction_composition` |
| coordinator | `axi_read_burst4_transaction_coordinator` |
| support ID | `intent.ppif_axi_read_burst4_transaction_composition` |
| support coverage key | `ial2_ppif_axi_read_burst4_transaction_composition_pipeline_cli` |
| test owner | `t/1507-ial2-axi-read-burst4-transaction-composition.t` |
| HDL fixture | `t/data/axi_read_burst4_transaction_composition_tb.svt` |

This is a new additive object. The shipped
`(axi-read-transaction-composition ...)` source, generator, report schema,
support ID, t/1506 proof, and fixed-single-beat behavior remain byte-for-byte
unchanged.

## Fixed request legality

The generated top connects exact sized constants to the unchanged AR child:

```text
=8'd3  -> ar_driver.cmd_arlen
=3'd2  -> ar_driver.cmd_arsize
=2'b01 -> ar_driver.cmd_arburst
```

Four words occupy 16 bytes. A four-byte-aligned start address is legal exactly
when its low 12 bits are at most `12'hff0`. The tested IAL1 spelling avoids
mixed-width arithmetic and comparison ambiguity:

```text
(& (! cmd_read_addr[0])
   (! cmd_read_addr[1])
   (! (& cmd_read_addr[11] cmd_read_addr[10] cmd_read_addr[9]
         cmd_read_addr[8]  cmd_read_addr[7]  cmd_read_addr[6]
         cmd_read_addr[5]  cmd_read_addr[4]
         (| cmd_read_addr[3] cmd_read_addr[2]))))
```

With alignment already required, the rejected low-12-bit values are exactly
`ff4`, `ff8`, and `ffc`; `ff0` is legal. The expression strict-checks, lowers,
and passes Verilator/Yosys. It must guard admission and appear in an assertion
for an otherwise idle admissible command. Misaligned and boundary-crossing
commands are ignored without ARVALID, busy, or completion pulses.

## Unchanged-child reuse and causal timing

The AR child is reused with only the three fixed metadata values changed at
the structural top. Its exactly-once VALID/READY behavior and payload
retention do not change.

The R child remains one arm, one accepted beat, one raw capture, and one later
`r_beat_done` pulse. Repetition belongs exclusively to the coordinator:

1. idle legal admission retains address and ARID, raises aggregate busy, and
   pulses the private AR start;
2. the AR child owns ARVALID through `ARVALID && ARREADY`;
3. its later `ar_done_i` makes the coordinator pulse request done and the
   first R arm;
4. the R child raises RREADY independently of RVALID and captures one beat;
5. its later `r_done_i` makes the coordinator publish beat done/index, update
   sticky status, and either retire index 3 or clear ownership for re-arm;
6. on a non-final index, the next coordinator cycle issues another R arm once
   the unchanged child is idle; and
7. the fourth `r_done_i` lowers aggregate busy and pulses beat done and
   transaction done together.

There is a deliberate ready-low bubble between child arms. This cannot lose or
double-accept a conforming transfer: once RVALID is asserted without RREADY,
the subordinate retains RVALID and its payload until the next handshake. The
temporary harness held RVALID continuously and changed payload only after each
accepted edge; all four tuples were accepted once, in order. Replacing the R
child with a new burst receiver is unnecessary and would widen two contracts
instead of one.

`read_beat_done` and `response_beat_index` are registered together after the
R child has captured and held the raw tuple. Consumers sample the tuple and
index during the beat-done pulse. The raw outputs then remain stable until the
next accepted beat or reset. Consumers that need a four-entry transaction
result must store the event stream; output banks remain capacity-shell work.

## Exact coordinator schedule

The coordinator has 20 ports and no procedural states.

Inputs (9): public command start/address32/ID4; private AR busy/done; private R
busy/done; captured RID4 and RLAST. Outputs (11): private AR start/address32/
ID4 and R arm; public busy, request done, beat done, transaction done,
response beat index2, ID match, and last match.

Private state is `active_q`, `response_armed_q`, retained
`expected_arid_q[3:0]`, and declared `beat_index_q[1:0]`. Public match outputs
are initialized to one at admission and updated as sticky conjunctions.

| Rule | Assignments | Purpose |
| --- | ---: | --- |
| `admit` | 10 | retain request/ID, initialize index/status, pulse AR start, raise busy |
| `clear_ar_start` | 1 | clear registered AR-start pulse |
| `arm_first_response` | 3 | mark armed, pulse first R arm and request done after AR completion |
| `arm_next_response` | 2 | mark armed and pulse R arm after a non-final beat |
| `clear_r_arm` | 1 | clear registered R-arm pulse |
| `clear_request_done` | 1 | clear request-done pulse |
| `advance_beat` | 6 | publish non-final beat event/index, update sticky status, increment, release arm ownership |
| `finish_burst` | 8 | publish final event/index/status, retire, lower busy, pulse transaction done |
| `clear_beat_done` | 1 | clear beat-done pulse |
| `clear_transaction_done` | 1 | clear transaction-done pulse |

The ten authored priorities are:

```text
finish_burst over advance_beat
finish_burst over arm_next_response
finish_burst over clear_beat_done
finish_burst over clear_transaction_done
advance_beat over arm_next_response
advance_beat over clear_beat_done
arm_first_response over clear_r_arm
arm_first_response over clear_request_done
arm_next_response over clear_r_arm
admit over clear_ar_start
```

The scheduler reports eight realized resolutions:

| Winner | Loser | Target |
| --- | --- | --- |
| `admit` | `clear_ar_start` | `ar_cmd_valid_i` |
| `arm_first_response` | `clear_r_arm` | `r_arm_i` |
| `arm_next_response` | `clear_r_arm` | `r_arm_i` |
| `advance_beat` | `clear_beat_done` | `read_beat_done` |
| `finish_burst` | `clear_beat_done` | `read_beat_done` |
| `arm_first_response` | `clear_request_done` | `read_request_done` |
| `finish_burst` | `clear_transaction_done` | `read_transaction_done` |
| `finish_burst` | `advance_beat` | `response_last_match` |

Three assertion-only transactions add no states:

1. idle candidate admission is aligned and stays within one 4-KiB region;
2. every accepted beat's RID equals the retained ARID; and
3. RLAST is low on indices 0-2 and high on index 3.

The schedule has `compile_issues=[]`. `.37` must freeze the exact IAL1 rule,
priority, assertion, message, assignment, and reset spellings proven here.

## Count, RLAST, RID, RRESP, and retirement

For each accepted beat at index `i`:

```text
response_id_match = prior_response_id_match && (captured RID == admitted ARID)
response_last_match = prior_response_last_match && (captured RLAST == (i == 3))
```

The exact outcome table is:

| Observed condition | Sticky result | Receive action | Retirement |
| --- | --- | --- | --- |
| matching RID, non-final RLAST=0 | unchanged true | re-arm next beat | no |
| matching RID, final RLAST=1 | unchanged true | no re-arm | yes, fourth beat |
| RID mismatch at any index | ID match becomes false | continue/drain | fourth beat |
| early RLAST at index 0-2 | last match becomes false | continue/drain | fourth beat |
| missing RLAST at index 3 | last match becomes false | no re-arm | yes, fourth beat |
| any non-OKAY RRESP | raw code visible with beat event; match bits unchanged | continue/drain | fourth beat |

This gives one bounded terminal authority: accepted beat count. It avoids both
unsafe early retirement and an impossible fifth-beat replacement wait after a
missing final RLAST. Assertions flag RID/RLAST violations when enabled;
assertion-disabled hardware retains status and completes the count-defined
transaction.

No sticky RRESP bit is added. A scratch candidate proved such a bit lowers,
but it was rejected because it would be a lossy response aggregation owned by
the capacity/status layer. A consumer of this raw physical boundary must
sample each RRESP during `read_beat_done`.

## Busy, command, and reset policy

- Admission requires aggregate idle, both children idle, legal address, and
  command start high.
- `read_busy` spans admission through the fourth response retirement.
- A command sampled while busy is ignored; there is no queue or adjacent
  back-to-back guarantee.
- Request done pulses once after AR acceptance when first response ownership
  is armed.
- Beat done pulses once for each of four child completions.
- Transaction done pulses once with the fourth beat event, independent of raw
  RRESP and match status.
- Asynchronous active-low reset clears all three children, private ownership,
  counter, output pulses, match outputs, and captured raw values.
- Reset before AR acceptance, after AR acceptance, or between R beats aborts
  the aggregate without fabricating request/beat/transaction completion.
- A post-reset legal command starts from index zero with match outputs
  reinitialized true.

Reset does not drain a pre-reset bus transaction. System-level reset/quiescence
of the subordinate is assumed by the existing children and remains unchanged.

## Flat C4 topology and artifacts

The tested structural top has:

```text
module_name                     = axi_read_burst4_transaction_composition
signal_count                    = 29
composition_child_count         = 3
composition_generated_children  = 3 FSM children
composition_net_count           = 48
composition_resolved_link_count = 46
lane                            = C4
```

The two existing child `.fsm` files are reused unchanged. Private links are:

- AR busy/done to coordinator;
- coordinator AR start/address/ID to AR child;
- sized LEN3/SIZE2/INCR constants to AR child;
- coordinator R arm to R child;
- R busy/done to coordinator; and
- captured RID/RLAST fanout from the R child to public outputs and coordinator.

RDATA and RRESP remain public raw outputs only. The coordinator does not
consume them. The generated result exposes exactly three generated IAL1 items
and schedule reports, three leaf IAL0 FSMs, and one selected structural top:

```text
axi_ar_driver.isf / axi_ar_driver.fsm
axi_r_beat_acceptor.isf / axi_r_beat_acceptor.fsm
axi_read_burst4_transaction_coordinator.isf
axi_read_burst4_transaction_coordinator.fsm
axi_read_burst4_transaction_composition.fsm  # selected HDL entry
```

The mandatory lowering chain remains IAL2 -> generated IAL1 -> generated IAL0
-> HDL. There is no direct IAL2-to-IAL0 path and no nested composition top.

## Report contract

The schema-v1 report must contain:

- `layering` with generated ISF/FSM formats and `direct_ial2_to_ial0=false`;
- exact source object, intent, and thirteen anchors;
- target AXI4/read-burst4/manager identity;
- public clock/reset/command/AR/R/status bindings;
- `fixed_burst_policy` with address32, alignment4, span16,
  four-KiB-contained, ID4, data32, ARLEN3, ARSIZE2, ARBURST1/INCR,
  beat_count4, request/beat/transaction completion definitions;
- unchanged AR and R child-reuse records;
- coordinator admission, re-arm, count, status, drain, busy, and reset policy;
- flat C4 composition with 29 ports, 3 children, 48 nets, and 46 links;
- three child reports and schedule reports;
- exact generated artifacts and selected top; and
- ordered enforced-static and unsupported-residue arrays.

The ordered enforced-static set has fifteen entries:

1. exact AXI4 profile, object, and manager role;
2. shared clock and asynchronous active-low reset;
3. one idle command atomically captures address32/ID4;
4. admission requires four-byte alignment and a 16-byte span within 4 KiB;
5. AR metadata is fixed to LEN3/SIZE2/INCR;
6. flat C4 reuses unchanged AR/R actors plus one coordinator;
7. R is first armed only after owned AR completion;
8. the unchanged R child is re-armed once for each expected beat;
9. one outstanding ownership interval excludes busy commands and queues;
10. request, beat, and transaction completion are distinct one-cycle events;
11. beat index 0-3 identifies the raw captured tuple during each beat event;
12. RID match and count/RLAST-sequence match are sticky across four beats;
13. RID/RLAST mismatch and non-OKAY RRESP drain to the fourth accepted beat;
14. RRESP remains raw per beat with no implicit success or aggregation; and
15. lowering uses three generated IAL1/leaf IAL0 actors plus one structural
    top, never direct IAL2-to-IAL0.

The ordered residue set has fourteen IDs:

1. `axi_read_burst4_transaction_composition_dynamic_burst_deferred`;
2. `axi_read_burst4_transaction_composition_narrow_unaligned_wrap_attributes_deferred`;
3. `axi_read_burst4_transaction_composition_multi_beat_write_deferred`;
4. `axi_read_burst4_transaction_composition_response_aggregation_output_banks_deferred`;
5. `axi_read_burst4_transaction_composition_capacity_core_integration_deferred`;
6. `axi_read_burst4_transaction_composition_outstanding_queueing_deferred`;
7. `axi_read_burst4_transaction_composition_id_allocation_ordering_demux_deferred`;
8. `axi_read_burst4_transaction_composition_malformed_subordinate_recovery_deferred`;
9. `axi_read_burst4_transaction_composition_extended_r_monitoring_deferred`;
10. `axi_read_burst4_transaction_composition_transaction_interface_deferred`;
11. `axi_read_burst4_transaction_composition_profile_alias_deferred`;
12. `axi_read_burst4_transaction_composition_verification_output_deferred`;
13. `axi_read_burst4_transaction_composition_backend_variants_deferred`; and
14. `axi_read_burst4_transaction_composition_other_protocols_unchanged`.

`.37` owns the exact detail strings and report placement.

## Fail-closed diagnostics

The family is additive. PPIF ownership requires the generator import and result
dispatch, root accumulator/object arm, exact cardinality/mixing checks,
object/block parsers, predicate, missing-intent enumeration, and a family-
specific `.axi` rejection. Existing dispatch order and all existing object
predicates remain unchanged.

Targeted negative coverage must reject before partial artifacts escape:

- wrong root, profile other than exact `axi4`, wrong role, or reset other than
  asynchronous active-low;
- missing, duplicate, or unknown composition/command/AR/R/status clauses;
- any authored length/size/burst/cardinality or second command/result bank;
- wrong width for every address, ID, length, size, burst, data, response,
  captured result, or beat index;
- missing beat done/index, request/transaction done, ID match, or last match;
- duplicate public/private/reserved names and generated artifact collisions;
- nested child overrides, nested tops, unsupported policy vocabulary, response
  success/aggregation claims, or omitted ID/RLAST checks;
- mixing with the fixed-single full read, standalone AR/R, any write
  composition, capacity/status, Valid-Ready, AHB, or APB object;
- multiple burst4 objects; and
- `.axi` profile-alias use.

`.37` must freeze exact diagnostics and the complete malformed-case table.

## Public tooling and executable proof

One new PPIF fixture changes expected support totals from 305/346/346 to
**306 protocol fixtures, 347 supported fixtures, and 347 strict-supported
fixtures**. No `.axi` alias or generated fixture is added.

`t/1507` must contain exactly four top-level subtests:

1. adapter/report, exact anchors, schedules, artifacts, and topology;
2. malformed and expanded contracts fail closed;
3. strict check, support accounting, schedule JSON, semantic JSON, outdir,
   Verilator, and Yosys; and
4. assertion-disabled executable generated-top behavior.

The executable matrix must cover:

- misalignment and aligned 4-KiB crossing rejection, with `...ff0` accepted;
- fixed LEN3/SIZE2/INCR on continuous, stalled, and pulsed ARREADY;
- retained AR payload and ignored busy command;
- no R arm before owned AR completion;
- already-high, delayed, continuously-held, and pulsed RVALID;
- one ready-low re-arm bubble without lost or duplicate transfer;
- raw tuple and beat indices 0/1/2/3 with one beat pulse each;
- RID mismatch, early RLAST, two non-OKAY RRESP positions, and missing final
  RLAST in one burst that still drains exactly four beats;
- a clean burst reinitializing both sticky match statuses;
- reset during stalled AR, after AR acceptance, and between arbitrary beats;
- post-reset recovery, no phantom completion, exact request/beat/transaction
  counts, and final idle.

The temporary generated-HDL harness passed:

```text
PASS ar=4 r=13 request=4 beat=13 transaction=3
     illegal=2 busy_ignored=1 error_drain=4 reset_abort=1
```

The four AR handshakes comprise three completed transactions plus one reset-
aborted transaction. Thirteen R/beat events comprise three complete four-beat
bursts plus one pre-reset beat. Only three transaction completions are legal.
Verilator lint and Yosys synthesis pass on the 29-port three-child top.

## Owner map and validation

| Surface | Required owner |
| --- | --- |
| parser/dispatch | `perl/FSM/Adapter/IAL2/PPIF.pm` |
| aggregate generator | new `perl/FSM/IAL2/ProtocolIntent/AxiReadBurst4TransactionComposition.pm` |
| AR child | existing `AxiArDriver.pm`, unchanged |
| R child | existing `AxiRBeatAcceptor.pm`, unchanged |
| public source | new `ppif/axi_read_burst4_transaction_composition.ppif` |
| support accounting | `perl/FSM/Support/RegressionCorpus.pm`, t/248 |
| language manifest | `perl/FSM/Support/LanguageSurfaceSection.pm`, t/297 |
| public/HDL proof | new `t/1507-ial2-axi-read-burst4-transaction-composition.t` plus `.svt` fixture |
| user documentation | `docs/book/src/16a-ial2-axi.md` |
| continuity | task/index, Memory, behavior fact, Knowledge Map, git |

Focused implementation validation must include generator/adapter/test syntax;
t/1499-t/1507 plus t/248 and t/297 under the repository RAM policy; public
strict/schedule/semantic/outdir/verify-HDL probes; exact executable proof;
mdBook build; Knowledge Map generation/check; memory/docs-path/whitespace; and
the doctrine gate. Temporary source, FSM, SV, object, PDF-render, log, and JSON
artifacts must be removed before commit.

## Explicit deferrals

This boundary does not add or imply:

- authored/dynamic ARLEN, variable beat counts, variable ARSIZE, WRAP/FIXED,
  narrow or unaligned bursts, or extended AR attributes;
- multi-beat write-data supply, WLAST sequencing, or write composition;
- sticky/worst RRESP aggregation, result mapping, error-RDATA usability policy,
  or four-entry output banks;
- capacity/status submit/completion integration;
- adjacent back-to-back admission, multiple outstanding reads, buffering,
  queues, ID allocation/reuse/order, RID demux, or read interleaving;
- timeout, abort, retry, or resynchronization after a malformed subordinate
  stops before the ARLEN-selected count;
- `.axi` alias surfacing or direct verification-output generation;
- decision 0020's director-gated protocol-neutral transaction interface;
- direct backend lowering, backend-language variants, or VHDL behavior; or
- any AHB/APB behavior change.

## Next leaves and rollback

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.37` selects the exact public contract from
this audit: syntax, identities, anchors, legality predicate, schedule,
topology, lifecycle, report/static/residue strings, diagnostics, owners,
accounting, proof, and rollback. It changes no behavior.

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.38` is the atomic implementation owner. It
must land parser, generator, source, support/manifest entries, exact t/1507
proof, mdBook shipped documentation, behavior fact, continuity, and cleanup in
one signoff-level slice.

Audit rollback removes this audit and its fact card, restores `.36` active,
removes `.37`/`.38`, and restores the task-index/book/Memory pointers. No code,
runtime, or HDL rollback is required because `.36` changes no behavior.
