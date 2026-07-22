# IAL2 AXI manager initiator — bounded W driver readiness audit

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.8` (behavior-neutral readiness
audit).

Status: ready for a separate contract-selection leaf. This audit changes no
parser, generator, public source, support-accounting entry, capability
manifest, test, generated artifact, runtime behavior, or HDL behavior.

## 1. Outcome

The next safe AXI initiator increment is a separate, bounded **single-beat W
write-data channel driver**. It accepts one upstream command containing 32-bit
write data and four byte strobes, drives `WVALID`, `WDATA`, `WSTRB`, and
single-beat `WLAST = 1` against `WREADY`, then emits a one-cycle `done` pulse.

The primitive is ready for contract selection because every required behavior
has a source anchor, the corrected AW driver supplies a proven existing-ISF
schedule shape, the existing W monitor supplies the matching stability
obligations, and all parser/generator/test/documentation owners are known.

Implementation is deliberately **not** selected by this leaf. The exact public
spelling and report schema belong to
`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.9`.

## 2. Source evidence and inspection method

The tracked source is
`docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf`
(SHA-256 `20aa5f946df5fa97053689d705959b1ef6a90a88f845fa3b686a53311f680ac1`).
For this audit, `pdfinfo` confirmed the 320-page unencrypted artifact,
`pdftotext -layout` was used for bounded extraction, and physical PDF pages
29-31 and 53-54 were rendered outside the repository and visually checked.

| Source anchor | Page | Constraint carried into this audit |
| --- | ---: | --- |
| `A2.3 Valid-Ready transport` | 29 | A transfer occurs only when `VALID` and `READY` are both high. A transmitter cannot wait for `READY` before asserting `VALID`; once asserted, `VALID` and its information remain stable until the transfer. |
| `A2.3.1 Valid-Ready signals`, Table A2.2 | 30 | `WVALID` marks valid W-channel information and `WREADY` marks that the receiver can accept a W transfer. |
| `A2.3.2.1 Write transaction dependencies` | 31 | The manager must not wait for `WREADY` before `WVALID`, for every write-data transfer. B-channel completion depends on accepted address and final write data, so B completion is not a property of this isolated W primitive. |
| `A3.2.1 Write data channel (W)` | 53 | `WDATA` has `DATA_WIDTH`; `WLAST` is one bit and marks the final write-data transfer. `DATA_WIDTH = 32` is a valid bounded profile. |
| `A3.2.1.1 Write strobes` | 54 | `WSTRB` width is `DATA_WIDTH / 8`; each bit selects one WDATA byte lane. With `DATA_WIDTH = 32`, the width is four. An all-zero strobe is legal and represents a transfer that writes no data. |

These are source facts, not permission to claim a complete AXI write
transaction. In particular, the write-dependency diagram makes the isolation
boundary explicit: AW acceptance, final W acceptance, and B response are
transaction-level concerns above the W channel primitive.

## 3. Existing repository evidence

### Existing W monitor

`ppif/axi_aw_w_valid_ready_bundle.ppif` already contains an independent W
monitor object with:

- channel `W`, role `manager-to-subordinate`;
- `wvalid`/`wready`;
- `wdata` width 32 and `wstrb` width 4.

`FSM::IAL2::ProtocolIntent::ValidReadyChannel` generates the matching
monitor-side obligations: if the previous cycle had `WVALID && !WREADY`, then
`WVALID` remains asserted and each payload field remains stable. The proposed
driver must **guarantee** what that monitor checks.

The monitor fixture omits `WLAST`; that is acceptable for its narrow transport
example, but not for a primitive claiming a complete bounded W beat. The driver
therefore adds a driven one-bit `WLAST`, fixed high while its single beat is
valid. It does not add a command-side last input because this leaf has no
multi-beat mode.

### Corrected AW schedule

`FSM::IAL2::ProtocolIntent::AxiAwDriver::_emit_isf` now uses the correction
shipped by `.7`:

- one inline launch handoff;
- a `launch_aw` rule that registers activity, busy, valid, and payload;
- an `accept_aw` rule guarded by `AWVALID && AWREADY` that clears activity,
  busy, and valid on the acceptance edge;
- explicit `accept_aw over launch_aw` priority; and
- a transaction loop over latched `active_q` before `(complete aw_done)`.

`t/1499-ial2-axi-aw-driver.t` proves this shape in generated HDL with
continuously-high READY and with a four-cycle payload stall followed by a
one-cycle READY pulse. Across two commands it observes exactly two handshakes
and two done pulses, stable stalled payload, and final valid/busy low. The
schedule has six states, no compile issues, and exactly three priority
resolutions (`active_q`, busy, and valid).

The W driver may reuse that schedule mechanically with W-specific bindings. It
must not reuse the superseded late-deassert schedule that allowed two transfers
from one command.

### Architectural boundaries

- Decision `0014` requires IAL2 -> generated `.isf` -> generated `.fsm`; direct
  IAL2-to-IAL0 lowering is forbidden.
- Decision `0017` defines the existing AW/W Valid-Ready bundle as an aggregate
  of independent monitor artifacts. It does not compose AW and W drivers or
  establish transaction behavior.
- Decision `0020` keeps AW/W drivers valid as bus-side primitives beneath a
  future protocol-neutral transaction interface. That future interface is not
  activated by this slice.

## 4. Safe first behavior boundary

The contract-selection leaf should preserve these distinct signal sets.

**Inputs (environment/upstream -> driver):**

| Role | Recommended binding | Width | Rule |
| --- | --- | ---: | --- |
| command trigger | `w_cmd_valid` | 1 | one-shot command, accepted only when the primitive is idle |
| command data | `cmd_wdata` | 32 | sampled on the command trigger |
| command strobe | `cmd_wstrb` | 4 | sampled on the command trigger; every value including `4'b0000` is legal |
| W-channel acceptance | `wready` | 1 | subordinate-owned; never gates initial `WVALID` assertion |

**Outputs (driver -> W channel/environment):**

| Role | Recommended binding | Width | Rule |
| --- | --- | ---: | --- |
| transfer valid | `wvalid` | 1 | asserted independently of `wready`, held until acceptance |
| driven data | `wdata` | 32 | sampled command data, stable throughout a stall |
| driven byte strobes | `wstrb` | 4 | sampled command strobes, stable throughout a stall |
| final-beat marker | `wlast` | 1 | driven high for the single valid beat and held through a stall |
| activity status | `w_busy` | 1 | high from launch until W acceptance |
| completion status | `w_done` | 1 | one-cycle pulse once the one accepted transfer completes |

The input names and output names must remain distinct, following the shipped AW
driver's `cmd_aw*` versus `aw*` split. `wlast` has no upstream twin in this
bounded profile. Values driven after `WVALID` falls have no transfer meaning;
the guarantee is `WLAST = 1` whenever this primitive presents its valid beat.

### Exact behavioral invariant

For each accepted command:

1. sample `cmd_wdata` and `cmd_wstrb` exactly once;
2. assert `WVALID` without waiting for `WREADY`;
3. while `WVALID && !WREADY`, keep `WVALID`, `WDATA`, `WSTRB`, and `WLAST`
   unchanged, with `WLAST = 1`;
4. count exactly one rising-edge `WVALID && WREADY` acceptance;
5. clear valid/busy on that acceptance edge; and
6. emit exactly one one-cycle `w_done` pulse.

No later edge may count as a second W acceptance for the same command, even if
`WREADY` remains high.

## 5. Target generated-ISF shape

The `.9` contract selection should pin the W-specific form of the proven `.7`
rule-pair idiom:

```text
(priority accept_w over launch_w)

(rule launch_w launch_w_start
  (set active_q 1)
  (set w_busy 1)
  (set wvalid 1)
  (set wdata data_q)
  (set wstrb strb_q)
  (set wlast 1))

(rule accept_w (& wvalid wready)
  (set active_q 0)
  (set w_busy 0)
  (set wvalid 0))

(transaction w_issue
  (on w_cmd_valid
    (sample cmd_wdata as data_q)
    (sample cmd_wstrb as strb_q))
  (drive
    (launch_w_start 1))
  (while active_q
    (wait 1))
  (complete w_done))
```

The complete actor also needs the standard clock/reset/interface declarations.
As with AW, `accept_w` must win the three shared writes (`active_q`, `w_busy`,
`wvalid`). `WDATA`, `WSTRB`, and `WLAST` are written only by launch, so they do
not create additional priority conflicts. The expected scheduler target is the
same six-state, zero-compile-issue shape as AW; `.9` must pin it before code
changes.

## 6. Fail-closed static boundary

The first W driver must reject any contract outside all of these conditions:

- profile exactly `axi4`;
- object exactly the selected W-driver object and role exactly
  `manager-to-subordinate`;
- exactly one W-driver object in a source, with no mixed intent-object kinds;
- all required clock/reset/command/channel/status bindings present exactly
  once;
- `cmd_wdata` and `wdata` widths exactly 32;
- `cmd_wstrb` and `wstrb` widths exactly 4, preserving the
  `DATA_WIDTH / 8` relation;
- `wlast` is a one-bit/scalar driven channel output, not a command input, and
  is fixed high for the presented beat;
- every interface name and internal alias (`data_q`, `strb_q`, `active_q`) is
  unique and is a valid ISF identifier; and
- lowering passes through generated IAL1 `.isf` before generated IAL0 `.fsm`.

The validator must **not** reject `cmd_wstrb = 0`; that would contradict the
source-defined legal all-strobes-low transfer. Runtime overlapping command
pulses while busy are outside this one-active primitive and must not be
mistaken for outstanding-transaction support.

## 7. Exact implementation owner map

The future behavior leaf selected by `.9` will have these owners.

1. **PPIF import and dispatch** — `perl/FSM/Adapter/IAL2/PPIF.pm`: add the W
   generator import beside `AxiAwDriver` (currently line 19), a W predicate and
   dispatch beside lines 98-101, and retain the final monitor fallback.
2. **Root clause/cardinality** — `_contract_from_root` (lines 262-332): add an
   `@axi_w_drivers` accumulator, the selected clause head, the missing-object
   diagnostic, one-object/AXI-family/mixed-object fail-closed checks, and the W
   contract return. W is independent here; do not interpret an authored AW
   driver plus W driver as composition.
3. **Binding parser** — mirror `_parse_axi_aw_driver` and its command/channel
   helpers (lines 889-962), narrowed to start/data/strobe/ready and
   valid/data/strobe/last/busy/done.
4. **Predicate** — add the W `kind` predicate beside
   `_is_axi_aw_driver_contract` (lines 2926-2929).
5. **Generator** — add the selected W module under
   `perl/FSM/IAL2/ProtocolIntent/`, mirroring `AxiAwDriver`'s constructor,
   normalization, generated-IAL1/IAL0 envelope, report, defensive copying, and
   identifier/reset helpers, but using the rule pair in section 5.
6. **Public source** — add the selected `ppif/axi_w_driver.ppif` fixture with
   accurate page 29-31/53-54 anchors and the bounded signal set in section 4.
7. **Support accounting** — add one entry next to
   `intent.ppif_axi_aw_driver` at `RegressionCorpus.pm:2035-2045`; the selected
   id/coverage/module names belong to `.9`. `t/248` owns corpus counts.
8. **Capability manifest** — extend the `.ppif` `current_boundary` at
   `LanguageSurfaceSection.pm:85-90`; `t/297` owns the exact manifest snapshot.
9. **Focused test** — reserve `t/1500-ial2-axi-w-driver.t` (1498 is already
   reserved for the pending AHB requester BUSY-insertion slice; 1499 owns AW).
10. **User documentation** — extend `docs/book/src/16a-ial2-axi.md` from its
    current AW-only initiator mode to the shipped W source only in the behavior
    leaf. Until then, label this boundary as audited/not shipped.
11. **Continuity** — update the owning task tree/index, `MEMORY.md`, a dated
    Knowledge Map fact card, and generated `KNOWLEDGE_MAP.md` in every slice.

No other registry exists for this path; dispatch remains in `PPIF.pm`.

## 8. Report target and explicit residue

The future report should mirror `axi_aw_driver.v1`: `mode = driver`, layering,
source object/anchors, target protocol, driver identity, command/channel
bindings, generated artifacts, enforced static rules, and explicit unsupported
residue. `.9` must settle the exact schema and ids, but it must preserve at
least these distinct facts:

- AW/W channel coordination and transaction launch are deferred;
- B response observation/completion is deferred;
- multi-beat data sequencing and dynamic `WLAST` are deferred;
- multiple active/outstanding writes and overlapping commands are deferred;
- burst/address coupling and the AR/R path are outside this W primitive;
- integration with `AxiManagerCapacityStatus` is deferred;
- decision `0020`'s protocol-neutral transaction interface and role
  composition are not activated;
- `.axi` profile-alias exposure is deferred;
- verification-output generation is deferred;
- backend-language variants, including VHDL behavior, are deferred; and
- AHB/APB behavior is unchanged and outside this AXI-only leaf.

## 9. Validation contract for the future implementation

The reserved `t/1500` must cover:

- public-source parse/result/report/generated `.isf`/generated `.fsm` shape;
- exact static failures for profile, role, missing/duplicate/mixed objects,
  widths, missing bindings, and duplicate signal names;
- CLI strict check JSON, semantic JSON, schedule JSON, outdir artifacts, and
  `--verify-hdl`;
- the expected six-state/no-compile-issue/three-priority-resolution schedule;
- generated-HDL simulation with one continuously-high-`WREADY` command and one
  stalled command followed by a one-cycle `WREADY` pulse;
- exactly one W acceptance and one done pulse per command;
- stable `WDATA`, `WSTRB`, and `WLAST = 1` throughout the stall;
- final `WVALID = w_busy = 0`; and
- a legal all-zero `WSTRB` command.

Focused cross-surface gates are `t/1499` (AW invariant remains intact), `t/248`
(support accounting), and `t/297` (capability manifest), followed by strict
public-source generation, Verilator/Yosys validation, mdBook, Knowledge Map,
memory/docs-path/whitespace checks, and `scripts/check_doctrines.sh`. Heavy
Perl/prove runs remain subject to the repository RAM guard.

## 10. Exact next leaf

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.9` is a **behavior-neutral contract
selection**. It must fix:

- clause head, parser `kind`, generator/result kind, report schema, public
  source path, actor/module name, support id/coverage, and focused test path;
- exact command/channel source syntax and binding names;
- the four source anchors and source-object spelling;
- the six-state priority-resolved generated-ISF target;
- fail-closed diagnostics and cardinality/mixing policy;
- report static rules and exact residue ids;
- all implementation touch points and validation/rollback steps; and
- the exact following behavior implementation leaf.

It must not change the parser, generator, public source, tests, manifests,
support accounting, generated artifacts, runtime behavior, or HDL behavior.

## 11. Conclusion

The bounded W driver is ready to contract, not yet ready to implement without
that contract. The safe boundary is one independent 32-bit, four-strobe,
single-beat W transfer with `WLAST = 1`, exactly-one acceptance, stable stalled
signals, busy, and one-cycle done. The corrected AW rule-pair is the required
schedule substrate; AW/W composition and B completion remain higher-level
future work.
