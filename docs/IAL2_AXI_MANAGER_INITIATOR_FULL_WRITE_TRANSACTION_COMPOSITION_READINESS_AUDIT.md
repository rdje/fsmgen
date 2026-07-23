# IAL2 AXI manager initiator — full-write transaction composition readiness audit

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.20` (behavior-neutral audit).

Date: 2026-07-23

Status: ready for exact public-contract selection. This leaf changes no parser,
generator, public source, support entry, manifest, test, generated artifact,
runtime behavior, or HDL behavior.

## Outcome

The selected bounded AXI4 manager single-beat full-write composition is
implementable by reusing all four shipped write-side generated actors:

- unchanged `axi_aw_driver`;
- unchanged `axi_w_driver`;
- unchanged `axi_write_request_coordinator` behavior, generated with private
  request-handoff bindings;
- unchanged `axi_b_response_acceptor`; and
- one new rule-only response-aware transaction coordinator.

The selected structural architecture is a **flat five-child C4 top**. The
shipped `axi_write_request_composition` structural top cannot itself be a
`?fsmc` child: the active composition contract accepts FSM-rooted children,
while that artifact is rooted at `?top`. The full generator must invoke
`AxiWriteRequestComposition`, retain/extract its three generated IAL1 and leaf
IAL0 children, omit its unselected nested top from the full result, add B plus
the transaction coordinator, and build one new selected structural top.

The safe response policy is:

1. admit one aligned idle command and atomically retain its payload/AWID in the
   transaction coordinator;
2. issue one registered private start to the unchanged request coordinator;
3. preserve the request coordinator's completion as a distinct public
   request-done pulse;
4. arm B **only after** both AW and W have been accepted;
5. accept/capture one B response through the unchanged B actor;
6. compare captured four-bit BID with the retained admitted AWID;
7. expose raw captured BID/BRESP plus a stable ID-match status; and
8. emit one full-transaction done pulse and drop aggregate busy even on an ID
   mismatch, while also asserting the mismatch for verification.

Raw BRESP is not interpreted as success by this slice. AXI error responses are
valid responses, so completion means the response was accepted and captured;
the caller must inspect BRESP.

The proposal is ready for
`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.21`, the exact public-contract selector.

## Evidence read and live prerequisites

The audit reconciled:

- `AxiWriteRequestComposition.pm` generation, normalization, request-
  coordinator ISF, C4 top, report/artifact structure, and `t/1502` public,
  fail-closed, CLI, Verilator/Yosys, and generated-top proof;
- `AxiBResponseAcceptor.pm` generation, six-state schedule, eager post-arm
  BREADY/capture semantics, report, and `t/1501` unarmed/already-high/delayed-
  BVALID proof;
- the AW/W/B public sources and the tracked AXI transport, write dependency,
  AW, W, and B-response source anchors;
- the capacity/status raw accepted-response versus per-transaction completion
  distinction recorded by the response-demux readiness/contract facts;
- `PPIF.pm` imports, dispatch, object accumulators, cardinality/mixing guards,
  block parsers, predicates, missing-intent enumeration, and `.axi` rejection;
- `RegressionCorpus.pm`, `LanguageSurfaceSection.pm`, t/248, t/297, the AXI
  mdBook, task tree, Memory, and Knowledge Map; and
- `COMPOSITION_SCOPE.md`, `COMPOSITION_LEGACY_MAPPING.md`, and
  `GeneratedChildRealizer.pm` for the active direct-child/root-kind contract.

Live schedule probes confirm the shipped request composition still exposes
three lowering-clean schedules: two six-state channel transactions plus one
zero-state/six-rule request coordinator. The B actor remains one six-state
transaction with three accept-over-arm priority resolutions. The new
transaction-coordinator probe strict-checks with zero states, no compile
issues, seven rule blocks, and four realized pulse-clear priorities.

## Structural topology decision

### Nested request top rejected

A scratch wrapper attempted:

```text
(?top:axi_write_request_nested_probe
  ...
  (?fsmc:request axi_write_request_composition))
```

The real compiler resolved `axi_write_request_composition.fsm`, detected root
`?top:axi_write_request_composition`, and rejected it because `?fsmc` requires
an embedded or external child rooted at `?fsm` (or legacy `+fsm`). This agrees
with `COMPOSITION_LEGACY_MAPPING.md`: the active bounded lane does not support
nested `?top` blocks.

The full-write design must not depend on unsupported recursive composition or
flatten a nested top after the fact.

### Flat five-child C4 selected

The selected immediate children are:

| Instance role | Generated object | Reuse policy |
| --- | --- | --- |
| AW driver | `axi_aw_driver` | unchanged result from request composition |
| W driver | `axi_w_driver` | unchanged result from request composition |
| request coordinator | `axi_write_request_coordinator` | unchanged rules/schedule; private handoff bindings |
| B acceptor | `axi_b_response_acceptor` | unchanged standalone actor |
| transaction coordinator | recommended `axi_write_transaction_coordinator` | new rule-only actor |

A scratch flat top with those five generated children strict-checks with:

```text
composition_child_count = 5
signal_count             = 29
resolved_link_count      = 61
lane                     = C4
```

It emits 2,866 lines of SystemVerilog containing all five child modules and
the selected structural top. No top-level recursion or direct IAL2-to-IAL0
path is involved.

### Private handoff namespace is mandatory

A direct flat probe using the standalone request composition's public
`write_cmd_valid`/`write_busy` names exposed two deterministic C4 conflicts:

- public `write_busy` matched both the request coordinator and transaction
  coordinator outputs; and
- public `write_cmd_valid` attempted to drive the request coordinator both by
  connect-by-name and from the transaction coordinator.

The selected remedy is not awkward public renaming. The full generator must
invoke `AxiWriteRequestComposition` with private internal command/status
bindings such as:

```text
request_cmd_valid_i  request_awaddr_i  request_awid_i
request_wdata_i      request_wstrb_i
request_busy_i       request_done_i
```

The transaction coordinator is the only child connected to the public command
and aggregate status. Explicit links connect its private request handoff to the
request coordinator. A second scratch probe with this namespace strict-checks
as the same five-child C4 shape while keeping familiar public command names.
Every internal binding remains subject to exact duplicate-name rejection.

## Safe transaction boundary

### Public command and bus behavior

The full-write object retains the shipped request payload and fixed policy:

| Field | Width/policy |
| --- | --- |
| byte address | 32 bits, four-byte aligned |
| AWID | 4 bits, captured until B retirement |
| WDATA | 32 bits, one beat |
| WSTRB | 4 bits, arbitrary including zero |
| AWLEN | fixed `8'd0` |
| AWSIZE | fixed `3'd2` |
| AWBURST | fixed `2'b01` (INCR) |
| WLAST | fixed high for the one beat |

One public command is level-sampled only while the aggregate is idle. A
one-cycle command while aggregate busy is ignored and not queued. A held
command may be admitted after idle returns. The outer coordinator repeats the
existing four-byte admission guard/assertion, captures all request payload
fields atomically, and holds its private handoff outputs across the registered
request-start pulse. The unchanged request coordinator then captures that
stable private handoff before starting AW and W.

This two-stage capture is intentional. Direct public payload wiring would be
unsafe because the outer registered start reaches the request coordinator
after a one-shot caller may change its inputs.

### Busy and completion meanings

Three meanings remain distinct:

- request-child busy is private and covers AW/W issue only;
- aggregate busy starts at public admission and stays high through B response
  retirement; and
- request done and transaction done are separate one-cycle public pulses.

Request done is emitted when the outer coordinator observes the shipped
request coordinator's `request_done_i`, meaning both AW and W transferred. It
coincides with B arming in the new coordinator. Transaction done is emitted
only when the B child later produces `b_done_i`, meaning BID/BRESP were
captured. It does not by itself mean BRESP is OKAY.

The shipped standalone request composition and its `write_done` meaning do not
change.

## Response ownership and error policy

### B arming after request issue

Arming B at public admission is rejected for this bounded composition. A
conforming subordinate cannot issue B until AW and the final W beat are
accepted, but early arming would let a non-conforming early BVALID be consumed
and associated with an unfinished request.

The selected coordinator waits for request completion, then pulses the B
acceptor arm once. If BVALID is already high after the final request handshake,
AXI requires it to remain asserted until BREADY; the shipped B actor's
already-high proof covers this case. Delaying BREADY therefore preserves a
legal response while enforcing local request-before-response causality. A
non-conforming transient BVALID pulse before arming is ignored rather than
accepted without ownership.

### BID correlation

The outer coordinator captures the public four-bit AWID at admission and
drives the same captured value into the request path. After B capture, it
compares the stable captured BID against that retained AWID.

On match, stable ID-match status becomes one. On mismatch, it becomes zero and
a generated assertion reports the protocol/ownership error. Functional logic
still retires the already-consumed response and pulses transaction done; it
must not wedge forever waiting for a response that can no longer arrive.
Assertion-disabled generated-HDL testing must prove this fail-closed terminal
behavior, and assertion-enabled testing must prove the mismatch is visible.

### BRESP exposure

The unchanged B child exposes stable captured four-bit BID and two-bit BRESP.
The full top re-exports both. No BRESP encoding is asserted or converted to a
boolean success in this first composition because OKAY, EXOKAY, SLVERR, and
DECERR are transaction results rather than transport-protocol violations.
Higher-level response-status mapping remains future work.

## New transaction-coordinator target

### Recommended interface

The rule-only coordinator requires:

- public command inputs: start, address32, AWID4, WDATA32, WSTRB4;
- private request inputs: `request_busy_i`, `request_done_i`;
- private B inputs: `b_busy_i`, `b_done_i`, captured BID4;
- private outputs: request start/payload handoff and one B-arm pulse; and
- public outputs: aggregate busy, request done, transaction done, and stable
  response-ID-match status.

Internal `active_q`, `response_armed_q`, and retained `expected_awid_q[3:0]`
own the full transaction. Captured BRESP bypasses the coordinator and is
re-exported directly from the B child.

### Proven rule schedule

The strict-clean scratch target uses seven rule blocks:

| Rule | Assignments | Purpose |
| --- | ---: | --- |
| `admit` | 8 | capture command/AWID, start private request, raise busy |
| `clear_request_start` | 1 | clear registered request pulse |
| `arm_response` | 3 | mark B armed, pulse B arm and public request done |
| `clear_b_arm` | 1 | clear B-arm pulse |
| `clear_request_done` | 1 | clear request-done pulse |
| `finish_response` | 5 | retire, lower busy, pulse transaction done, record ID match |
| `clear_transaction_done` | 1 | clear full-completion pulse |

The scheduler reports zero states, no procedural transactions, no compile
issues, and four realized priorities: admit over request-start clear;
arm-response over B-arm clear and request-done clear; finish-response over
transaction-done clear. Defensive declarations may additionally order
mutually exclusive state-transition writers, but they add no realized
resolution in the selected guards.

Two assertion-only transactions add no states:

- an otherwise-idle public command implies four-byte alignment; and
- active armed B completion implies captured BID equals retained AWID.

`.21` must freeze the exact ISF names, rule spellings, priorities, assignment
counts, assertion names/messages, and reset values.

## Artifact, report, CLI, and semantic boundary

The implementation result must expose:

- five generated IAL1 items and schedule reports: AW, W, request coordinator,
  B acceptor, transaction coordinator;
- five generated leaf IAL0 FSMs plus one selected full-write structural top;
- no nested request-composition top in the returned full-write artifact set;
- one combined file map with exact collision checks;
- a selected `generated_composition_top` HDL entry listing all five child FSMs;
- semantic root = the full structural top, lane C4, child count five;
- report sections for composition topology, bindings, single-beat request
  policy, request coordination reuse, response coordination, ID policy,
  response capture, schedules/artifacts, static rules, and residue; and
- explicit `direct_ial2_to_ial0 = false` layering.

`--emit-schedule-json` must expose all five schedules. `--outdir` must retain
five `.isf` files, five child `.fsm` files, the selected top `.fsm`, and HDL.
`--emit-semantic-json` must report the five-child top, not the omitted request
top. Strict rejection must emit no partial generated output.

The generator may call `AxiWriteRequestComposition->generate` and filter its
result to the three IAL1/leaf-IAL0 children; it must not copy the AW, W, or
request-coordinator ISF text into a second source of truth. It separately calls
`AxiBResponseAcceptor->generate` and generates only the new coordinator itself.

## Public source recommendation and fail-closed rules

`.21` owns exact spelling. The recommended additive family is:

```text
(axi-write-transaction-composition ...)
```

backed by `FSM::IAL2::ProtocolIntent::AxiWriteTransactionComposition`, public
source `ppif/axi_write_transaction_composition.ppif`, structural top
`axi_write_transaction_composition`, coordinator
`axi_write_transaction_coordinator`, support id
`intent.ppif_axi_write_transaction_composition`, and focused test `t/1503`.
The exact endpoint role should represent an AXI manager with outbound AW/W and
inbound B rather than falsely label the whole object as one channel direction;
`.21` must freeze that role and its diagnostics.

The public object should contain one command block, AW/W/B channel blocks, and
one status/response boundary. It should re-export raw captured BID/BRESP and
separate request/full completion. It must not embed authored copies of the
four child objects or expose private `_i` wiring.

Parser/generator rejection must cover:

- profile other than exact `axi4` and wrong aggregate role;
- missing, duplicate, or extra full-write objects;
- mixing with AW/W/B standalone objects, request composition,
  capacity/status, Valid-Ready, APB, or AHB intent;
- unsupported clock/reset, binding widths, missing B response capture, or
  duplicate public/private/reserved names;
- command/status names that would create ambiguous C4 top matches;
- dynamic AW metadata, multi-beat fields, queue/outstanding policy, or
  additional AXI attributes/sidebands;
- absence of distinct request-done and transaction-done bindings;
- absent/malformed ID-match status or any attempt to omit four-bit BID/AWID
  correlation;
- BRESP interpretation claims beyond raw two-bit capture;
- nested child overrides or nested `?top` selection;
- unsupported `.axi` alias use; and
- extra clauses, roles, channels, or policy vocabulary.

## Implementation owner map

| Surface | Required owner |
| --- | --- |
| parser/dispatch | `perl/FSM/Adapter/IAL2/PPIF.pm` |
| aggregate generator | new recommended `perl/FSM/IAL2/ProtocolIntent/AxiWriteTransactionComposition.pm` |
| request children | existing `AxiWriteRequestComposition.pm` result, unchanged and filtered to three leaves |
| B child | existing `AxiBResponseAcceptor.pm`, unchanged |
| public sample | new recommended `ppif/axi_write_transaction_composition.ppif` |
| support accounting | `perl/FSM/Support/RegressionCorpus.pm`, guarded by t/248 |
| language manifest | `perl/FSM/Support/LanguageSurfaceSection.pm`, guarded by t/297 |
| focused contract/HDL proof | new recommended `t/1503-ial2-axi-write-transaction-composition.t` |
| user documentation | `docs/book/src/16a-ial2-axi.md` |
| continuity | task tree/index, Memory, Knowledge Map fact, git |

`PPIF.pm` needs an import/dispatch predicate and arm, root accumulator/clause,
exact cardinality/mixing checks, object/block parsers, missing-intent entry, and
`.axi` rejection. Every existing standalone/request parser path remains
unchanged.

## Required executable proof

The implementation proof must execute the selected full structural top and
cover at least:

1. misaligned idle command launches no AW/W request, never arms B, and leaves
   aggregate idle with an assertion-visible caller error;
2. one-shot public payload changes after admission while both private capture
   stages preserve the admitted address/ID/data/strobe;
3. simultaneous-ready, AW-first, and W-first request issue under long stalls;
4. BREADY remains low until request completion/B arm;
5. BVALID already high at B arm is held and accepted once;
6. delayed BVALID sees BREADY remain asserted until one response acceptance;
7. matching BID and raw BRESP capture produce one request-done pulse, one B
   handshake, one transaction-done pulse, and stable match status one;
8. mismatched BID is accepted once, yields match status zero and terminal done
   with assertions disabled, and trips the generated assertion when enabled;
9. at least OKAY and one non-OKAY BRESP encoding are preserved without
   suppressing transaction completion;
10. a command during both AW/W issue and B wait is ignored, not queued;
11. reset during request issue and B wait returns every child and aggregate
    status/VALID/READY/pulse low without a phantom completion; and
12. final AWVALID/WVALID/BREADY/busy/request-done/transaction-done are low with
    exact AW/W/B/request/full-completion totals.

Focused validation must include t/1499-t/1502, new t/1503, t/248, t/297,
public strict/schedule/semantic/outdir/verify-HDL probes, mdBook, Knowledge Map,
memory/docs-path/whitespace, and doctrines under the repository RAM policy.

## Explicit deferrals

This boundary does not add or imply:

- capacity/status submission/completion wiring, ID allocation, response demux,
  same-ID ordering, or multiple outstanding writes;
- command queues, adjacent back-to-back admission, response buffering, or
  throughput beyond one active transaction;
- multi-beat W, dynamic WLAST/AWLEN/AWSIZE/AWBURST, burst address generation,
  narrow/unaligned placement, or extended AXI attributes/response sidebands;
- BRESP-to-protocol-neutral status mapping;
- AR/R behavior or decision `0020`'s transaction interface;
- `.axi` aliases, verification-output generation, direct backend lowering,
  backend-language variants, VHDL, AHB, or APB behavior.

The mandatory chain remains:

```text
IAL2 full-write object
  -> five generated IAL1 actors
  -> five generated leaf IAL0 FSMs
  -> one flat five-child structural IAL0 top
  -> HDL
```

## Next leaf, validation, and rollback

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.21` is the exact public-contract selector.
It must freeze public syntax/role/bindings, generator/result/report/source/
top/coordinator/support/test identities, private request namespace, five-child
wiring, seven-rule schedule, B-arm timing, request/full completion, AWID/BID
policy, raw BRESP behavior, report/static/residue, diagnostics, proof matrix,
validation, rollback, and the following implementation leaf.

The nested rejection, private-namespace strict check, five-child C4 check,
coordinator schedule, and 2,866-line/six-module HDL emission all pass. Two
optional `--verify-hdl` attempts were safely stopped by the default RAM guard
when its known macOS host metric reported 99.0% and 96.9%; `memory_pressure`
simultaneously reported 67% system memory free. The pre-existing guard-metric
issue and proposed owner are already tracked in Memory/fact
`ram-guard-macos-host-metric-over-reports`; this audit did not bypass the 88%
cutoff. Full Verilator/Yosys execution remains mandatory for implementation.

Documentation validation requires Knowledge Map generation/check, mdBook,
bounded Memory/docs-path/whitespace checks, and the full doctrine gate.
Rollback removes this audit/fact, restores `.20` active, removes `.21`, and
restores task-index/book/Memory pointers. No behavior rollback is required.
