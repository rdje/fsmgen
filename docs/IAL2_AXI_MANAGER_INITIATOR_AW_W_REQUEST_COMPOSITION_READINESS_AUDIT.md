# IAL2 AXI manager initiator — AW+W request composition readiness audit

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.16` (behavior-neutral audit).

Date: 2026-07-23

Status: ready for exact public-contract selection. This leaf changes no parser,
generator, public source, support entry, manifest, test, generated artifact,
runtime behavior, or HDL behavior.

## Outcome

The selected bounded AXI manager write-request composition is implementable
without changing either shipped channel driver. The safe first slice is:

- one idle-admitted command carrying a 32-bit byte address, four-bit AWID,
  32-bit WDATA, and four-bit WSTRB;
- atomic command-payload capture in a distinct generated coordinator;
- fixed child AW metadata `AWLEN = 8'd0`, `AWSIZE = 3'd2`, and
  `AWBURST = 2'b01` (one 32-bit INCR beat);
- four-byte alignment, enforced both by an admission guard over
  `AWADDR[1:0]` and a generated assertion on an idle admission attempt;
- unchanged `axi_aw_driver` and `axi_w_driver` children, each started exactly
  once from the coordinator and sharing one clock/reset;
- arbitrary four-bit WSTRB, including the already-shipped legal all-zero
  strobe;
- aggregate busy from admission until both child done events have been seen;
  and
- one aggregate done pulse after both AW and W handshakes, in either order.

The generated coordinator must be a rule-only IAL1 actor. A scratch strict,
schedule, HDL-lint, and executable probe proves that this shape can capture the
one-shot payload, reject a misaligned command before either child starts,
remember AW-first or W-first one-cycle completions, handle simultaneous
completion, and produce one done pulse. The proposal is therefore ready for
`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.17`, which must select the exact public
spelling and report identifiers before behavior changes.

The B response acceptor remains independent. Aggregate done means **both
request channels accepted**, not **the AXI write transaction completed**.

## Evidence and prerequisites

The audit read and reconciled:

- `ppif/axi_aw_driver.ppif`, `AxiAwDriver.pm`, its live report/schedule, and
  `t/1499-ial2-axi-aw-driver.t`;
- `ppif/axi_w_driver.ppif`, `AxiWDriver.pm`, its live report/schedule, and
  `t/1500-ial2-axi-w-driver.t`;
- the independent `ppif/axi_b_response_acceptor.ppif` boundary and `t/1501`;
- the tracked AXI transport, write-dependency, AW, W, length, size, and burst
  facts already recorded by the AW/W readiness and contract notes;
- decisions `0014` (mandatory IAL2-to-IAL1-to-IAL0 lowering), `0017`
  (monitor-only valid-ready bundle), and `0020` (director-gated transaction
  interface horizon);
- `ApbComposition.pm` and `AhbInterconnect.pm` generated-child aggregation,
  schedule-report, structural-top, and selected-entry patterns;
- the composition actual-literal contract in `docs/COMPOSITION_SCOPE.md` and
  `ActualLiteralSupport.pm`;
- `PPIF.pm`, `RegressionCorpus.pm`, `LanguageSurfaceSection.pm`, the AXI
  mdBook, task tree, Memory, and Knowledge Map.

Live AW, W, and B report probes still expose one generated `.isf`, one
generated `.fsm`, and one selected child HDL entry per standalone primitive.
The composition substrate supports exact-width literal actuals such as
`=8'd0`, `=3'd2`, and `=2'b01`, so the fixed AW metadata can be structural
wiring rather than new dynamic aggregate inputs.

## Safe command and channel boundary

### Aggregate command

The first slice accepts these dynamic inputs:

| Meaning | Recommended signal | Width | Policy |
| --- | --- | ---: | --- |
| one-shot command | `write_cmd_valid` | 1 | admitted only while idle |
| byte address | `cmd_awaddr` | 32 | must have bits `[1:0] == 0` |
| request ID | `cmd_awid` | 4 | forwarded to AW; no BID matching here |
| write data | `cmd_wdata` | 32 | one W beat |
| byte strobes | `cmd_wstrb` | 4 | arbitrary, including all zero |

There is no aggregate ready output in this first slice. A one-cycle command
while busy is ignored and not queued. A command held until the composition
becomes idle can be admitted then; the public contract must describe
`write_cmd_valid` as a level-sampled idle admission request rather than imply
edge storage or a queue.

The coordinator must capture all four payload fields on the same admitted
edge. Connecting aggregate payload inputs directly to the children is unsafe:
the coordinator's registered start pulses reach the children on a later edge,
after a one-shot caller may legally have changed its inputs. The captured
payload outputs remain stable until the next accepted command and feed the two
child command interfaces.

### Fixed single-beat AW metadata

The aggregate source must not expose dynamic length, size, or burst fields.
The structural top supplies:

| AW child input | Fixed value | Meaning |
| --- | --- | --- |
| `cmd_awlen` | `8'd0` | exactly one beat (`AWLEN + 1`) |
| `cmd_awsize` | `3'd2` | four bytes per beat (`2^AWSIZE`) |
| `cmd_awburst` | `2'b01` | INCR burst encoding; one beat only |

This closes the mismatch identified by `.15`: the W child always emits one
beat with `WLAST = 1`, so arbitrary AWLEN cannot be coherent. FIXED and INCR
have no address progression difference for one beat, but fixing INCR gives one
unambiguous conventional encoding. WRAP, multi-beat INCR, narrow sizes, and
dynamic burst metadata remain outside the slice.

### Alignment and strobe policy

The aggregate retains a standard 32-bit byte address. It admits a command only
when `!cmd_awaddr[0] && !cmd_awaddr[1]` and emits an assertion with the same
condition for an idle admission attempt. This dual policy is deliberate:

- the guard prevents a misaligned request from launching either child even
  when assertion checking is disabled; and
- the assertion makes the caller error visible in verification instead of
  silently dropping it.

The rule uses indexed one-bit tests rather than `(% cmd_awaddr 4) == 0`. The
scratch modulo form strict-checked but the current equality-to-zero HDL
optimization produced a Verilator `WIDTHTRUNC` warning by applying logical
negation to a 32-bit intermediate. The indexed form strict-checks and
Verilator-lints cleanly. This is a probe-local selection, not a change to the
pre-existing general equality-lowering issue tracked elsewhere.

WSTRB is not forced to `4'b1111`. AXI byte strobes can intentionally disable
lanes, and the standalone W driver already proves that all-zero WSTRB is
preserved. With four-byte-aligned AWSIZE=2 transfers, WSTRB selects byte lanes
within that one aligned 32-bit beat; unaligned placement and narrow transfer
size semantics are deferred together.

## Coordinator contract

### Required interface

The generated coordinator owns:

- inputs: `write_cmd_valid`, `cmd_awaddr[31:0]`, `cmd_awid[3:0]`,
  `cmd_wdata[31:0]`, `cmd_wstrb[3:0]`, `aw_done`, and `w_done`;
- child-start outputs: `aw_cmd_valid` and `w_cmd_valid`;
- captured child payload outputs: `aw_cmd_awaddr[31:0]`,
  `aw_cmd_awid[3:0]`, `w_cmd_wdata[31:0]`, and `w_cmd_wstrb[3:0]`; and
- aggregate outputs: `write_busy` and `write_done`.

Internal one-bit storage `active_q`, `aw_seen_q`, and `w_seen_q` tracks the
join. The child starts and aggregate done are registered one-cycle pulses.

### Proven rule schedule

The selected target is equivalent to this core:

```text
(rule launch_join
  (& (! active_q) write_cmd_valid (! cmd_awaddr[0]) (! cmd_awaddr[1]))
  (set active_q 1)
  (set aw_seen_q 0)
  (set w_seen_q 0)
  (set aw_cmd_valid 1)
  (set aw_cmd_awaddr cmd_awaddr)
  (set aw_cmd_awid cmd_awid)
  (set w_cmd_valid 1)
  (set w_cmd_wdata cmd_wdata)
  (set w_cmd_wstrb cmd_wstrb)
  (set write_busy 1))

(rule clear_child_starts (| aw_cmd_valid w_cmd_valid)
  (set aw_cmd_valid 0)
  (set w_cmd_valid 0))

(rule latch_aw (& active_q aw_done) (set aw_seen_q 1))
(rule latch_w  (& active_q w_done)  (set w_seen_q 1))

(rule finish_join
  (& active_q (| aw_seen_q aw_done) (| w_seen_q w_done))
  (set active_q 0)
  (set aw_seen_q 0)
  (set w_seen_q 0)
  (set write_busy 0)
  (set write_done 1))

(rule clear_done write_done (set write_done 0))
```

Required priorities are `finish_join` over each latch, launch, and clear-done
conflict, plus `launch_join` over the two latches and child-start clear. The
scratch scheduled result has zero transaction states, six rule DT blocks, no
compile issues, five realized different-value priority resolutions, and two
compatible same-value fan-in groups for clearing the completion-history bits.

The actor also emits:

```text
(transaction aligned_command_check
  (assert
    (=> (& (! active_q) write_cmd_valid)
        (& (! cmd_awaddr[0]) (! cmd_awaddr[1])))
    "single-beat AXI write address must be four-byte aligned"))
```

A transaction-based launch/join implementation is not selected. Current ISF
`(on ...)` accepts a scalar port plus optional samples, not a compound boolean
admission expression. A scratch compound-on probe failed closed with the exact
grammar diagnostic. The rule-only form expresses guarded admission directly,
avoids a false aggregate done on rejected input, and still lowers through the
normal IAL1 scheduler.

## Structural composition and wiring

The generator must invoke the existing `AxiAwDriver` and `AxiWDriver`
generators with their fixed contracts, lower the coordinator through the ISF
scheduler, and build one structural top with three `?fsmc` children.

Recommended instance roles are `aw_driver`, `w_driver`, and `coordinator`.
All three share `clk` and asynchronous active-low `rst_n`. The top exposes:

- aggregate command inputs and `write_busy`/`write_done`;
- AW bus outputs `awvalid`, `awaddr[31:0]`, `awid[3:0]`, `awlen[7:0]`,
  `awsize[2:0]`, `awburst[1:0]`, plus input `awready`; and
- W bus outputs `wvalid`, `wdata[31:0]`, `wstrb[3:0]`, `wlast`, plus input
  `wready`.

Child `aw_busy`, `w_busy`, `aw_done`, `w_done`, and both start/payload
interfaces are internal nets. The aggregate public surface exposes only
composition status. The coordinator's captured payload outputs feed the
corresponding child inputs. The AW child receives the three fixed exact-width
literals. BREADY/BVALID/BID/BRESP and every B acceptor status are absent.

The top `.fsm` must include or otherwise make available all three generated
child `.fsm` definitions, following the shipped APB/AHB composition pattern.
It is the sole selected HDL entry; a child entry must never be selected for the
aggregate source.

## Artifact, report, CLI, and semantic boundary

The eventual aggregate result should preserve this shape (exact public names
remain owned by `.17`):

- `layer: IAL2` and a dedicated composition result kind;
- `generated_ial1.format: isf` with three ordered items: AW child, W child,
  coordinator;
- `generated_ial0.format: fsm` with four items: three generated children and
  one `generated_composition_top`;
- one combined `generated_ial0.files` map;
- three `generated_ial1_schedule_reports`, each labeled by object and role;
- a report schema dedicated to the aggregate composition;
- a selected `generated_artifacts.hdl_entry` whose kind is
  `generated_composition_top`, with all three child artifacts listed; and
- bounded `composition`, `bindings`, `single_beat_policy`, `coordinator`,
  `generated_artifacts`, `static`, and `residue` report sections.

The report must say explicitly:

- aggregate completion = `aw_done && w_done` history join, not B completion;
- command policy = idle admission, no queue, payload captured atomically;
- address policy = 32-bit byte address, four-byte aligned;
- fixed metadata = LEN 0, SIZE 2, BURST INCR;
- data/strobe policy = one 32-bit final beat, arbitrary WSTRB including zero;
- ID policy = AWID width 4 only, no BID comparison; and
- child reuse = shipped AW and W drivers unchanged.

`--emit-schedule-json` must report all three schedules while preserving the
public `.ppif` source identity. `--emit-semantic-json` must select the
structural top as the semantic root and expose its three generated children.
`--outdir` must retain the three reviewable `.isf` files, the three child
`.fsm` files, the structural top `.fsm`, and the selected HDL output. Strict
check must not emit partial generated output on rejection.

## Public source recommendation and fail-closed rules

The public source should use one bounded aggregate composition object rather
than embed authored copies of `(axi-aw-driver ...)` and `(axi-w-driver ...)`.
The generator owns the exact internal child contracts. This prevents public
duplication of fixed child names/widths/metadata and makes it impossible to
override AWLEN away from zero through a nested child object.

`.17` must fix the exact clause, object, module, result kind, schema, source,
actor/top, support id, and test spelling. The recommended family is an
`axi-write-request-composition` object named
`axi_write_request_composition`, backed by a new
`FSM::IAL2::ProtocolIntent::AxiWriteRequestComposition` generator and a public
`ppif/axi_write_request_composition.ppif` sample.

The parser and generator must fail closed for:

- profile other than `axi4`;
- role other than `manager-to-subordinate`;
- missing, duplicate, or extra aggregate composition objects;
- mixing with standalone AW, W, B, capacity/status, valid-ready, APB, or AHB
  intent in the same source;
- clock/reset disagreement or any unsupported reset mode/polarity;
- any renamed or wrong-width command, AW, W, or status binding;
- dynamic AWLEN/AWSIZE/AWBURST clauses or nested child overrides;
- duplicate signal names that collapse distinct directions/roles;
- B response bindings or claims of transaction completion;
- unsupported `.axi` alias use; and
- extra clauses, children, channels, attributes, or policy vocabulary.

The runtime alignment guard/assertion is not a substitute for static
diagnostics: all statically knowable contract errors remain parse/generation
failures.

## Implementation owner map

| Surface | Required owner |
| --- | --- |
| parser and dispatch | `perl/FSM/Adapter/IAL2/PPIF.pm` |
| composition generator | new `perl/FSM/IAL2/ProtocolIntent/AxiWriteRequestComposition.pm` (recommended name; `.17` finalizes) |
| child generation | existing `AxiAwDriver.pm` and `AxiWDriver.pm`, unchanged |
| public sample | new `ppif/axi_write_request_composition.ppif` (recommended path) |
| support accounting | `perl/FSM/Support/RegressionCorpus.pm`, guarded by `t/248-regression-corpus-accounting.t` |
| language manifest | `perl/FSM/Support/LanguageSurfaceSection.pm`, guarded by `t/297-capability-manifest.t` |
| focused contract and HDL proof | new `t/1502-ial2-axi-write-request-composition.t` (recommended owner) |
| user documentation | `docs/book/src/16a-ial2-axi.md` |
| durable continuity | this task tree, `docs/TASK_TREE.md`, `MEMORY.md`, Knowledge Map fact card, git |

`PPIF.pm` needs a dedicated import and dispatch predicate/arm, root accumulator,
clause parser, exact cardinality/mixing checks, missing-intent enumeration, and
`.axi` rejection. Existing standalone object parsing and dispatch must remain
unchanged.

## Required executable proof

The implementation test must cover the generated structural top, not only the
coordinator:

1. both READY signals already high: one AW handshake, one W handshake, one
   later aggregate done;
2. AW accepts first while W stalls for several cycles;
3. W accepts first while AW stalls for several cycles;
4. both children complete in the same coordinator-observation cycle;
5. long independent stalls preserve each VALID and its full payload;
6. one-shot command payload changes immediately after admission but captured
   child payload remains the admitted value;
7. all-zero WSTRB reaches the W bus unchanged;
8. a one-cycle command while busy is ignored and not queued;
9. a misaligned idle command launches neither child when assertions are
   disabled, while the generated assertion detects it when enabled; and
10. final child VALID, aggregate busy, and aggregate done are low, with no
    second transfer from held READY.

The scratch coordinator proof already passed the core join cases with three AW
starts, three W starts, and three done pulses across simultaneous, AW-first,
and W-first completion. It also passed atomic-payload capture, strict check,
zero-issue schedule emission, Verilator lint, assertion-enabled aligned
simulation, and assertion-disabled misaligned fail-closed simulation. The
implementation slice must repeat these properties through the real generated
top and both real child drivers.

Focused validation should include the new test, `t/1499`, `t/1500`, `t/248`,
`t/297`, public strict/semantic/schedule/outdir/verify-HDL probes, mdBook,
Knowledge Map, memory/docs-path/whitespace, and doctrine gates. Broad/heavy
runs remain subject to the repository RAM-guard policy and its documented
macOS false-high fallback.

## Explicit deferrals

This boundary does not add or imply:

- B arming/acceptance, BRESP handling, BID matching, or full write completion;
- capacity/status submission/completion wiring or outstanding-write tracking;
- command queueing, back-to-back admission, multiple outstanding requests, or
  arbitration;
- multi-beat W, dynamic WLAST, dynamic AWLEN/AWSIZE/AWBURST, narrow or
  unaligned lane placement, address progression, WRAP, or new AXI attributes;
- AR/R behavior;
- decision `0020`'s protocol-neutral transaction interface;
- `.axi` aliases, verification-output generation, direct-backend lowering,
  backend-language variants, VHDL, AHB, or APB behavior.

The mandatory lowering chain remains:

```text
IAL2 aggregate -> generated AW/W/coordinator IAL1/.isf
               -> generated AW/W/coordinator IAL0/.fsm
               -> generated structural IAL0/.fsm top -> HDL
```

## Next leaf, validation, and rollback

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.17` is the exact public-contract selector.
It must freeze all recommended names, the public source grammar, fixed literal
encodings, coordinator interface/rules/priorities/assertion, structural child
wiring, report/static/residue identifiers, diagnostics, artifact/CLI/semantic
shape, support/test owners, executable scenarios, and the following behavior
implementation leaf.

This audit is validated by the scratch executable proofs plus the Knowledge
Map generator/checker, mdBook build, bounded Memory/docs-path/whitespace checks,
and full doctrine gate. Rollback removes this audit and its fact card, restores
`.16` to active, removes `.17`, and restores the prior task-index/book/Memory
pointers. No behavior rollback is required.
