# IAL2 AXI manager initiator — AR address-channel driver readiness audit

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.24` (behavior-neutral audit).

Date: 2026-07-23

Status: readiness boundary fixed. No parser, generator, public source, support
entry, manifest, test, generated artifact, runtime behavior, or HDL behavior
changes in this leaf.

## Decision

The bounded AXI4 manager read-address primitive is ready for exact public
contract selection in `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.25`.

The safe first slice is a standalone AR channel driver with the complete core
read-request tuple:

| Direction | Binding | Width | Meaning |
| --- | --- | ---: | --- |
| input | command start | 1 | admit one request while idle |
| input | command address | 32 | sampled AR address |
| input | command ID | 4 | sampled ARID |
| input | command length | 8 | sampled raw ARLEN |
| input | command size | 3 | sampled ARSIZE |
| input | command burst | 2 | sampled ARBURST |
| input | ARREADY | 1 | subordinate-owned acceptance |
| output | ARVALID | 1 | manager-owned request validity |
| output | AR address | 32 | held sampled address |
| output | ARID | 4 | held sampled ID |
| output | ARLEN | 8 | held sampled raw length |
| output | ARSIZE | 3 | held sampled size |
| output | ARBURST | 2 | held sampled burst type |
| output | busy | 1 | this zero-depth primitive owns an admitted request |
| output | done | 1 | one AR request was accepted; not read completion |

The audit selects the full tuple instead of a fixed single-beat subset. ARLEN,
ARSIZE, and ARBURST are part of the request channel and the driver can transmit
them without owning R-channel storage. This does **not** make the primitive a
complete AXI manager: after issuing a request, a composed manager must accept
the corresponding R beats. RREADY, RID/RDATA/RRESP/RLAST, beat accounting,
ARID/RID correlation, and full read completion remain separate owners.

The implementation must copy the corrected AW rule-pair architecture, renamed
for AR. It must not copy the obsolete late-deassert schedule that once allowed
two transfers under continuously asserted READY.

## Tracked source evidence

The source of record is the tracked, SHA-256-inventoried reference
`docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf`.
The public source selected in `.25` should carry these nine anchors:

| Section | PDF page | Audit consequence |
| --- | ---: | --- |
| `A2.3 Valid-Ready transport` | 29 | Transfer occurs only with VALID and READY together; transmitter-owned VALID is reset-low and held until acceptance. |
| `A2.3.1 Valid-Ready signals` | 30 | ARVALID is manager-owned and ARREADY subordinate-owned. |
| `A2.3.2.2 Read transaction dependencies` | 32 | The manager must not wait for ARREADY before asserting ARVALID; RVALID depends on an accepted AR request and is independent of RREADY. |
| `A2.6 Channel relationships` | 41 | Read data and response follow a read request; after issue, a complete manager must accept the returned data. |
| `A3.1 Transaction request` | 42 | The request carries the first address and transaction attributes; 4KB crossing is not legal. |
| `A3.1.1 Size` | 43 | ARSIZE is three bits; for a full-width 32-bit transfer its value is 2. |
| `A3.1.2 Length` | 44 | ARLEN is eight bits and encodes transfers minus one; early burst termination is not supported. |
| `A3.1.4 Burst` | 46 | ARBURST is two bits; INCR is encoded as `01`. |
| `B1.2.1 Read request channel` | 279 | Core AR channel directions and widths include ARID, ARADDR, ARLEN[7:0], ARSIZE[2:0], and ARBURST[1:0]. |

These anchors distinguish source facts from the bounded modeling choices. A
32-bit address and four-bit ID are selected project pins, not universal AXI
widths. Dynamic payload transmission also does not validate every legal
address/length/size/burst combination. Cross-4KB checks, reserved encodings,
wrap alignment/length constraints, and data-width coupling stay explicit
residue until a transaction composition owns them.

Extended AR attributes are out of the first slice. The residue must name at
least `ARREGION`, `ARLOCK`, `ARCACHE`, `ARPROT`, `ARQOS`, `ARUSER`, and the
newer optional security, coherency, tracing, credit, and MMU-related AR
sidebands represented by the tracked specification. The implementation must
not silently tie or imply support for them.

## Recommended public vocabulary for `.25`

The contract-selection leaf must freeze the exact spelling, but the audited
baseline is deliberately symmetric with the shipped AW primitive:

```text
(protocol-platform-intent axi_ar_driver
  (profile axi4)
  (source
    (object axi-ar-driver)
    ...nine anchors...)
  (axi-ar-driver axi_ar_driver
    (role manager-to-subordinate)
    (clock clk)
    (reset (rst_n active_low async))
    (command
      (start ar_cmd_valid)
      (address cmd_araddr width 32)
      (id cmd_arid width 4)
      (length cmd_arlen width 8)
      (size cmd_arsize width 3)
      (burst cmd_arburst width 2)
      (ready arready))
    (channel
      (valid arvalid)
      (address araddr width 32)
      (id arid width 4)
      (length arlen width 8)
      (size arsize width 3)
      (burst arburst width 2)
      (busy ar_busy)
      (done ar_done))))
```

The audited semantic distinctions are fixed even if `.25` revises a label:

- command bindings are upstream inputs; channel bindings are driven bus/status
  outputs;
- `manager-to-subordinate` is the address-channel role;
- reset is explicitly active-low and asynchronous in the public fixture;
- the five payload fields are captured atomically with one idle command;
- `ar_done` is a one-cycle **request-issued** event following the accepted
  `ARVALID && ARREADY` transfer;
- `ar_done` is not an R-beat event, read-complete event, success indication, or
  liveness guarantee; and
- there is no queue. A command presented while busy is not admitted.

## Exact generated IAL1 schedule boundary

The corrected `AxiAwDriver` schedule is structurally reusable by an AR driver.
The new generator should emit one actor, provisionally `axi_ar_driver`, with
15 interface ports, five payload storage registers, and one active bit. Its
generated ISF shape is:

```text
(actor axi_ar_driver
  ... 7 inputs + 8 outputs ...
  (priority accept_ar over launch_ar)

  (rule launch_ar launch_ar_start
    (set active_q 1)
    (set ar_busy 1)
    (set arvalid 1)
    (set araddr addr_q)
    (set arid id_q)
    (set arlen len_q)
    (set arsize size_q)
    (set arburst burst_q))

  (rule accept_ar (& arvalid arready)
    (set active_q 0)
    (set ar_busy 0)
    (set arvalid 0))

  (transaction ar_issue
    (on ar_cmd_valid
      ...sample the five command fields...)
    (drive (launch_ar_start 1))
    (while active_q (wait 1))
    (complete ar_done)))
```

The expected schedule contract, derived from the live corrected AW report, is:

- six states:
  `ar_issue_idle_0`, `ar_issue_drive_1`, `ar_issue_while_entry_2`,
  `ar_issue_wait_3`, `ar_issue_while_check_4`, and `ar_issue_done_5`;
- `launch_ar` has eight assignments and `accept_ar` has three;
- exactly three realized priority resolutions, with `accept_ar` winning over
  `launch_ar` for `active_q`, `ar_busy`, and `arvalid`;
- no compile issues;
- storage widths `addr_q[31:0]`, `id_q[3:0]`, `len_q[7:0]`,
  `size_q[2:0]`, `burst_q[1:0]`, and scalar active/done state; and
- a one-state inline launch handoff followed by a wait on the latched active
  bit, never a control decision that resamples ARREADY after the handshake.

This rule pair provides the required behaviors:

1. an idle command captures all five fields together;
2. ARVALID is launched regardless of ARREADY;
3. ARVALID and the full payload remain stable during any stall;
4. the acceptance rule clears VALID/busy/active on the handshake edge;
5. continuously-high ARREADY produces exactly one transfer per command;
6. a one-cycle delayed ARREADY pulse cannot be lost; and
7. done pulses once after acceptance, then the actor returns idle.

Reset must clear active state, ARVALID, busy, and done both from idle and while
stalled. The generated-HDL test must prove that an active request is canceled
by reset and does not later complete without a newly admitted command.

## Generated artifacts and report boundary

The expected additive generator identity, for `.25` to freeze, is:

- module: `FSM::IAL2::ProtocolIntent::AxiArDriver`;
- result kind: `protocol_intent.axi_ar_driver`;
- mode: `driver`;
- schema: `fsmgen.ial2.protocol_intent.axi_ar_driver.v1`;
- generated IAL1: `axi_ar_driver.isf` plus its schedule report;
- generated IAL0: exactly `axi_ar_driver.fsm`;
- selected HDL entry: the generated driver FSM; and
- layering: IAL2 -> generated IAL1/.isf -> generated IAL0/.fsm -> HDL, with
  `direct_ial2_to_ial0` false.

The report should mirror the AW driver envelope: source object/anchors, target
profile/object/role, driver identity, clock/reset/command/channel bindings,
generated artifact identities, enforced static rules, and unsupported residue.
Its enforced rules must state axi4-only scope, manager-to-subordinate role,
the 32/4/8/3/2 width pins, the full five-field AR payload, request-issued done
semantics, and the prohibition on direct IAL2-to-IAL0 lowering.

Suggested residue IDs for contract selection are:

- `axi_ar_driver_id_width_fixed`;
- `axi_ar_driver_attributes_deferred`;
- `axi_ar_driver_request_legality_deferred`;
- `axi_ar_driver_r_channel_deferred`;
- `axi_ar_driver_request_only_completion`;
- `axi_ar_driver_capacity_core_integration_deferred`;
- `axi_ar_driver_outstanding_deferred`;
- `axi_ar_driver_profile_alias_deferred`; and
- `axi_ar_driver_verification_output_deferred`.

## Fail-closed parser and generator boundary

Implementation must be additive and fail closed at both layers.

`FSM::Adapter::IAL2::PPIF` must reject:

- a non-AXI-family profile before generator dispatch, and every profile other
  than exact `axi4` during generator normalization;
- zero or multiple AR-driver objects, or mixing one with another intent object;
- absent/duplicate/unsupported object clauses or command/channel subclauses;
- a non-scalar/invalid object or signal identifier;
- a role other than `manager-to-subordinate`;
- missing clock/reset/command/channel bindings;
- command/channel widths other than 32/4/8/3/2;
- duplicate public or internal signal names;
- malformed source-anchor structures; and
- the AR driver on `.axi`, whose deliberately narrow alias guard remains
  unchanged.

The parser owner map mirrors AW exactly:

- import and parse-result dispatch before the generic fallthrough;
- `axi-ar-driver` accumulation in `_contract_from_root`;
- the missing-intent diagnostic enumeration;
- cardinality, no-mixing, and profile checks;
- object parser plus exact command/channel block parsers; and
- `_is_axi_ar_driver_contract` predicate.

Diagnostics must identify `axi-ar-driver`, the offending clause/binding/width,
and the bounded expectation. No malformed input may reach scheduler lowering.

## Public, support, manifest, test, and book owners

The implementation surface is fully mapped:

1. Add `perl/FSM/IAL2/ProtocolIntent/AxiArDriver.pm`, based on the corrected
   `AxiAwDriver.pm` architecture, not the obsolete pre-correction schedule.
2. Add the PPIF import, object parser, block parsers, accumulator, predicate,
   profile/cardinality/mixing checks, missing-intent text, dispatch, and `.axi`
   rejection coverage in `perl/FSM/Adapter/IAL2/PPIF.pm`.
3. Add the nine-anchor runnable source `ppif/axi_ar_driver.ppif`.
4. Add support entry `intent.ppif_axi_ar_driver` with coverage
   `ial2_ppif_axi_ar_driver_pipeline_cli` in
   `perl/FSM/Support/RegressionCorpus.pm`; update `t/248` coverage accounting.
   Expected counts move from 302/343/343 to 303 protocol fixtures,
   344 supported fixtures, and 344 strict-supported fixtures.
5. Extend the `.ppif` current-boundary prose in
   `perl/FSM/Support/LanguageSurfaceSection.pm` and its exact `t/297` assertion.
6. Add exact four-subtest owner `t/1504-ial2-axi-ar-driver.t`.
7. Add the shipped AR primitive, commands, semantics, artifacts, and limits to
   `docs/book/src/16a-ial2-axi.md` in the implementation slice.
8. Add a behavior fact card and synchronize the task tree, task index,
   Knowledge Map, and bounded `MEMORY.md` pointer in the same slice.

The public source remains generic `.ppif`. No `.axi` alias is added.

## Exact proof matrix for `t/1504`

The focused test must contain exactly four top-level subtests, matching the
current initiator primitive convention:

1. **Adapter/report/artifacts/schedule.** Assert layer, kind, mode, schema,
   profile/object/role, all bindings/widths, 15 ports, one `.isf`, one `.fsm`,
   the six named states, no compile issues, and the exact three priorities.
2. **Fail-closed malformed sources.** Exercise profile, role, reset, missing,
   duplicate, unsupported, width, duplicate-signal, cardinality, mixed-object,
   and `.axi` rejection boundaries with targeted diagnostics.
3. **CLI and external validation.** Prove strict check JSON and matched support,
   semantic JSON with an FSM source root, schedule JSON, outdir `.isf`/`.fsm`
   plus selected HDL, Verilator lint, and Yosys synthesis through
   `--verify-hdl`.
4. **Generated-HDL behavior.** Simulate at least: continuously-high ARREADY;
   four or more stalled cycles while command inputs mutate; a one-cycle READY
   pulse; command presented while busy; reset while idle; reset while stalled;
   payloads including nonzero ARLEN and differing size/burst values; exact
   transfer/done cardinality; one-cycle done; and final VALID/busy/done low.

The simulation must count `ARVALID && ARREADY` only on rising clock edges and
must check every payload field at acceptance. It must prove held outputs remain
the admitted values even if upstream command inputs change during the stall.

## CLI and validation gates

The implementation slice must run:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/axi_ar_driver.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/axi_ar_driver.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_ar_driver.ppif
./bin/fsmgen --quiet --outdir /tmp/fsmgen-axi-ar-out ppif/axi_ar_driver.ppif
./bin/fsmgen --verify-hdl ppif/axi_ar_driver.ppif
```

It must also run the focused AW-through-AR initiator test band, `t/248`,
`t/297`, mdBook build, Knowledge Map generation/check, bounded Memory/docs-path
checks, `git diff --check`, and `scripts/check_doctrines.sh`. Heavy/broad Perl
tests remain subject to the repository RAM guard.

## Preserved boundaries and explicit deferrals

This audit changes no behavior. The following stay outside the AR driver:

- RREADY drive, RID/RDATA/RRESP/RLAST capture, R-beat storage, error/status
  reduction, ARID/RID matching, and full read completion;
- enforcement that a complete manager accepts every response beat implied by
  ARLEN;
- legal address/length/size/burst cross-product checks, 4KB crossing, WRAP
  alignment/length rules, narrow/unaligned lane placement, and address stepping;
- configurable address/ID widths and all extended AR attributes;
- multiple outstanding or back-to-back requests, queues, ID allocation,
  ordering, demux, timeout, cancellation outside reset, or READY liveness;
- capacity/status integration and physical-to-abstract event/ID adapters;
- changes to shipped AW/W/B/request/full-write behavior;
- `.axi` alias expansion and decision `0020`'s director-gated protocol-neutral
  transaction interface;
- verification-output generation, direct backend lowering, backend-language
  variants, VHDL, AHB, and APB behavior.

## Rollback

Because `.24` is documentation-only, rollback removes this audit and fact card,
restores `.24` to active, removes `.25`, and restores the task-index/book/Memory
pointers. No parser, generator, public source, support, manifest, test,
generated artifact, runtime, or HDL rollback is required.
