# IAL2 AXI manager initiator — AW address-channel driver readiness audit

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.2` (no-behavior readiness audit).
Status: audit recorded; no parser/generator/source/test/artifact/behavior change
in this leaf.

This audit maps the exact code, test, docs, and report owners a future bounded
**AW address-channel driver** generator must touch, and fixes the safe
first-slice interface boundary (signal/port list, widths, fail-closed rules),
before any contract-selection or implementation leaf. It follows the
`AXI-IAL2-VALID-READY-READINESS-AUDIT` template and builds on the first-increment
selection in
`docs/IAL2_AXI_MANAGER_INITIATOR_FIRST_INCREMENT_SELECTION.md`.

## 1. Scope recap

The `.1` selector chose a bounded AW address-channel driver — issue one AW
address transfer: drive `AWVALID` plus the AW payload against `AWREADY`, from a
local command trigger, with a `done`/`busy` status. It reuses the existing AW
valid-ready authoring shape (`ppif/axi_aw_valid_ready.ppif`) and the
`perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm` drive-block / on-sample model,
**driven instead of observed**. No new channels, ordering, or response
association in this slice.

## 2. Safe first-slice interface boundary (recommended)

The generated actor is a *driver* (initiator), so — unlike the monitor
(`ValidReadyChannel.pm`) — the environment supplies a command and the actor
drives the AW channel. Signal widths follow AXI4 (AMBA AXI `IHI0022_L_2025-08`,
§A3.2.1, p. A3-40 — the anchor already carried by `ppif/axi_aw_valid_ready.ppif`).

**Inputs (environment → driver):**

| Role | Signal (suggested) | Width | Notes |
|---|---|---|---|
| command trigger | `aw_cmd_valid` | 1 | one-shot: begin one AW transfer |
| handshake ack | `awready` | 1 | subordinate accepts the address |
| payload: address | `awaddr` | 32 | pinned 32 in the first slice (matches existing AW source) |
| payload: id | `awid` | param (default 4) | ID width is implementation-defined; pin/param in the first slice |
| payload: length | `awlen` | 8 | AXI4 burst length (beats = `AWLEN`+1) |
| payload: size | `awsize` | 3 | bytes/beat = 2^`AWSIZE` |
| payload: burst | `awburst` | 2 | FIXED/INCR/WRAP |

**Outputs (driver → environment / AW channel):**

| Role | Signal (suggested) | Width | Notes |
|---|---|---|---|
| handshake valid | `awvalid` | 1 | asserted while a transfer is in flight |
| driven address | `awaddr_out` (or shared name) | 32 | held stable while `awvalid && !awready` |
| driven id | `awid_out` | param | held stable while stalled |
| driven length | `awlen_out` | 8 | held stable while stalled |
| driven size | `awsize_out` | 3 | held stable while stalled |
| driven burst | `awburst_out` | 2 | held stable while stalled |
| status: busy | `aw_busy` | 1 | high from command accept to handshake complete |
| status: done | `aw_done` | 1 | one-cycle completion pulse |

The exact input-vs-output naming (whether the driven AW payload reuses the
sampled input names or takes distinct `_out` names) is the one open spelling
decision for the `.3` contract-selection leaf; the AHB requester precedent
samples inputs into `*_q` locals and drives the bus outputs from those locals
(`AhbRequester.pm:377-408` sample block, `:314-324` `request_bus` drive).

**Handshake obligation (the AXI valid-ready rule the driver must honor):** once
`AWVALID` is asserted it must remain asserted, and the AW payload must remain
stable, until `AWREADY` is seen — the exact stability property the monitor
*checks* (`ValidReadyChannel.pm:325-344`) is what the driver must *guarantee*.

## 3. Generated ISF shape (target)

Mirror the AHB requester's structure at a fraction of the size — no beat-loop, no
burst/size tables, no wrap/incr address math, no response channels:

- `(actor <name> (clock clk) (reset (rst_n async active_low)) (interface …))` —
  inputs + outputs from §2.
- `(storage (var aw_done_q (width 1) (reset 0)))` — internal completion latch,
  as in `AhbRequester.pm:305-306`.
- `(drive accept_command …)` — raise `aw_busy`, clear `aw_done`.
- `(drive assert_aw …)` — drive `awvalid 1` + the sampled AW payload.
- `(drive finish …)` — drop `awvalid`, pulse `aw_done`, clear `aw_busy`.
- `(transaction aw_issue (on aw_cmd_valid (sample awaddr as addr_q) …) …
  (drive assert_aw) (when awready (drive finish)) (complete aw_done_q))` —
  assert-then-await-ready, one transfer.

Lowering is IAL2 → generated `.isf` (parsed by `FSM::Adapter::ISF`) → `.fsm`
(via `FSM::Scheduler::ISF`) → HDL — never IAL2→IAL0 direct (decision `0014`),
exactly as `AhbRequester.pm:33-39`.

## 4. Fail-closed static rules (first slice)

Following the AHB requester's `_normalize_contract` discipline
(`AhbRequester.pm:89-155`):

- profile must be an AXI family profile (`axi`/`axi3`/`axi4`/`axi5`); pin to
  `axi4` for the first slice (as the capacity/status core pins `axi4`).
- channel/object must be AW; role manager-to-subordinate.
- required bindings: name, clock, reset, `aw_cmd_valid`, `awready`, `awvalid`,
  and the AW payload set (`awaddr`/`awid`/`awlen`/`awsize`/`awburst`) + status
  (`aw_busy`/`aw_done`).
- width pins: `awaddr` 32, `awlen` 8, `awsize` 3, `awburst` 2 in the first slice
  (reject other widths, like `AhbRequester.pm:617-628`); `awid` width a bounded
  parameter.
- reject duplicate interface/internal signal names
  (`AhbRequester.pm:704-711` pattern).
- identifiers must be ISF identifiers; reset polarity from `_n` suffix unless
  explicit (`AhbRequester.pm:639-661`).

## 5. Owner map (touch points for the implementation leaf)

All dispatch lives in `perl/FSM/Adapter/IAL2/PPIF.pm` (no separate registry).

1. **Import** — add `use FSM::IAL2::ProtocolIntent::AxiAwDriver;` at
   `PPIF.pm:19-20` (alongside `AxiManagerCapacityStatus`/`ValidReadyChannel`).
2. **Clause parser** — in `_contract_from_root` (`PPIF.pm:259`): add an
   `elsif ($head eq 'axi-aw-driver')` arm with a `_parse_axi_aw_driver` routine
   and an `@axi_aw_drivers` accumulator (the clause-head chain is at
   `PPIF.pm:~285-300`); extend the unsupported-clause reject (`PPIF.pm:~303`) is
   automatic, but **update the missing-intent-object error enumeration**
   (`PPIF.pm:~311`, currently lists valid-ready-channel / manager-capacity-status
   / apb-* / ahb-*); add a cardinality/return block emitting a contract with
   `kind => 'axi_aw_driver'`.
3. **Predicate** — add `_is_axi_aw_driver_contract($contract)` (mirror
   `_is_manager_capacity_status_contract` `PPIF.pm:2822` /
   `_is_ahb_requester_contract` `PPIF.pm:2845`).
4. **Dispatch arm** — in `parse_source` (`PPIF.pm:45-100`) add
   `return AxiAwDriver->new(...)->generate($contract) if _is_axi_aw_driver_contract($contract);`
   before the fallthrough at `PPIF.pm:99`.
5. **Generator module** — `perl/FSM/IAL2/ProtocolIntent/AxiAwDriver.pm`, same
   envelope as `AhbRequester.pm:47-63` (`layer`/`kind`
   `protocol_intent.axi_aw_driver`/`mode`/`generated_ial1`/`generated_ial0`/
   `generated_ial1_schedule_report`/`report`); report `schema`
   `fsmgen.ial2.protocol_intent.axi_aw_driver.v1` (final name is a `.3`
   decision), with `target_protocol`/`bindings`/`enforced_static_rules`/
   `unsupported_residue` blocks like `AhbRequester.pm:512-593`.
6. **Public source** — new `ppif/axi_aw_driver.ppif` fixture (`profile axi4`,
   an `(axi-aw-driver …)` object) with the §2 signal set.
7. **Support accounting** — one `perl/FSM/Support/RegressionCorpus.pm` entry
   (mirror the AHB requester entry `RegressionCorpus.pm:51-61` and the AW
   valid-ready entry `:2013-2023`): `id => 'intent.ppif_axi_aw_driver'`,
   `relpath`, `family => 'protocol_fixture'`, `classification`, `coverage`,
   `source_kind => 'ppif'`, `strict_supported => 1`, `expected_module_name`,
   `expected_semantic_source_root_kind => 'fsm'`. Guarded by
   `t/248-regression-corpus-accounting.t`.
8. **Capability manifest** — extend the `.ppif` `current_boundary` prose in
   `perl/FSM/Support/LanguageSurfaceSection.pm:69-92` to name the AW-driver
   shape. Asserted verbatim by `t/297-capability-manifest.t` — the boundary
   prose must be updated in lockstep or `t/297` fails.
9. **mdBook** — add an initiator/driving section to
   `docs/book/src/16a-ial2-axi.md` (currently monitor + capacity/status +
   response-demux only, 190 lines, zero AW-drive coverage); coordinate with
   proposed `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE`.

## 6. Validation gates

- New generator test: `t/14xx-ial2-axi-aw-driver.t` mirroring
  `t/1473-ial2-ahb-requester.t` — parse the new source via
  `FSM::Adapter::IAL2::PPIF->new->parse_file(...)`, assert
  `layer`/`kind`/`mode`/`report.schema`, and grep the generated `.isf` for the
  `assert_aw`/`finish` drive blocks and `awvalid` driving.
- `t/248-regression-corpus-accounting.t` — the new corpus entry id/coverage.
- `t/297-capability-manifest.t` — the extended `.ppif` boundary prose.
- `t/1436-ial2-ppif-parser-cli.t` — CLI-level parse of the new clause head.
- `mdbook build docs/book`, `scripts/check_doctrines.sh`, `git diff --check`.
- Run heavy `prove`/broad runs under `scripts/run_with_ram_guard.sh` (host RAM
  guard; note the macOS over-report caveat in MEMORY / the RAM-guard fact card).

## 7. Explicit deferrals / residue (unchanged from the selection)

- **W write-data drive** (`WVALID`/`WDATA`/`WSTRB`/`WLAST`) — a second channel;
  naturally an AW+W aggregate bundle (decision `0017`), so AW ships first.
- **AR read-address drive** — same handshake shape but pulls in the R return
  path to be useful.
- **Burst / address generation** — INCR/WRAP address stepping and per-beat
  sequencing (the AHB requester beat-loop `AhbRequester.pm:430-467`).
- **Capacity-core integration** — wiring a driver to the ~9,773-line
  `AxiManagerCapacityStatus.pm` shell; cross-generator work, last.
- **AXI4 AW attribute signals** — `AWLOCK`/`AWCACHE`/`AWPROT`/`AWQOS`/
  `AWREGION`/`AWUSER` are explicit residue in the first slice.
- **`.axi` profile-alias surfacing** — requires relaxing the `.axi` guard
  `_validate_profile_alias_contract` (`PPIF.pm:224`, AXI-family check
  `_is_axi_family_profile` `PPIF.pm:158`, which currently rejects non-valid-ready
  AXI contracts on `.axi`); optional, after the generic `.ppif` driver ships.

## 8. Open questions for the `.3` contract-selection leaf

- Final clause-head spelling (`axi-aw-driver` vs `axi-manager-aw` …) and the
  generator/module name.
- Whether the driven AW payload reuses the sampled input names or takes distinct
  `_out` names.
- The `AWID` width parameter default and whether the first slice pins it.
- Whether the first slice drives only `awaddr`+`awlen` (matching the existing AW
  monitor payload exactly, the strictly-smallest option) or the full
  burst-describing set `{awaddr, awid, awlen, awsize, awburst}` recommended here
  (a complete AW address transfer). Recommendation: the burst-describing set —
  driving only address+length would issue an under-specified transfer.
