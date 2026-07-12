# IAL2-AXI-MANAGER-INITIATOR-FRONTIER: AXI manager initiator (bus-driving) side

## Metadata

- Tree ID: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER`
- Status: `active`
- Roadmap lane: `IAL2 / SV-backed feature completeness / AXI initiator`
- Created: `2026-07-12`
- Last updated: `2026-07-12`
- Owner: repo-local workflow

## Origin — director-directed pivot

The director agreed the AXI **response/bookkeeping** side has gone as far as is
useful for now and directed a pivot to the AXI **initiator** (bus-driving) side.

Context that motivated the pivot (from the `.785`-`.787` session analysis): the
AXI thread ships 142 `ppif/axi_*.ppif` sources, 140 of which are the
`axi_manager_capacity_status_*` family lowering to one module
`axi0_capacity_status` via `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
(~9,773 lines). That generator is a coherent-but-partial spine — a synthesizable
capacity/status + response-demux + read-data-capture core that self-labels a
`"capacity-status-shell"`. It does **not drive** the AXI transaction channels:
a grep of the 9,773-line generator finds **0** mentions of
`AWVALID`/`AWADDR`/`AWLEN`/`ARVALID`/`WDATA`/`WLAST`/`WSTRB`. So FSMGen can today
observe a handshake and track/route responses, but cannot **issue** an AXI
transaction.

## Current initiator-relevant surface (evidence)

- `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm` (~9,773 lines):
  response/bookkeeping core; drives no AW/AR/W channel signals.
- `perl/FSM/IAL2/ProtocolIntent/ValidReadyChannel.pm` (503 lines): generates a
  valid-ready **monitor** (module `<name>_valid_ready_monitor`), roles
  `manager-to-subordinate`/`subordinate-to-manager` (AXI) or
  `producer-to-consumer`/`consumer-to-producer` (generic valid-ready); it
  observes one valid/ready handshake with a payload — it does not drive a full
  transaction. Sources: `ppif/axi_aw_valid_ready.ppif` (15 lines),
  `ppif/axi_aw_w_valid_ready_bundle.ppif` (31 lines).
- **Architectural model:** `perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm`
  (759 lines) is the direct analog of an initiator — it **drives** the bus
  (`HTRANS`/`HADDR`/`HBURST`/`HWDATA`), with beat progression, wrap/incr address
  generation, and response handling. An AXI manager initiator is the same shape
  over AW/AR (address) + W (write-data) + response channels. The initiator thread
  should borrow the AHB requester's drive-block + beat-loop structure.

## The initiator gap (what "initiator side" means)

An AXI manager initiator **issues transactions**: drives the AW address channel
(`AWVALID`/`AWADDR`/`AWID`/`AWLEN`/`AWSIZE`/`AWBURST`/… with the `AWREADY`
handshake), the W write-data channel (`WVALID`/`WDATA`/`WSTRB`/`WLAST`), and the
AR read-address channel (`ARVALID`/`ARADDR`/…), including address/burst
generation. Today's AXI surface only monitors handshakes and tracks responses.

## Goal

Grow a coherent AXI manager **initiator** profile that drives AXI transactions
(AW/AR address issue, W write-data drive, burst/address generation, handshake
driving), lowering through the shared `IAL2 → IAL1/.isf → IAL0/.fsm → HDL`
pipeline (decisions `0014`/`0015`/`0016`/`0018`), modeled on the AHB requester.
It complements — does not replace — the shipped capacity/status response core.

## Non-Goals

- No change to the shipped `axi_manager_capacity_status_*` response core, the
  valid-ready monitors, AHB/APB, or any other shipped behavior.
- No new IAL2 language layer — this is an AXI **profile/vocabulary** over the one
  generic `.ppif` container (`0015`), optionally surfaced later via `.axi` alias.
- No direct IAL2 → IAL0 lowering (`0014`); no VHDL/backend-variant work.

## Acceptance Criteria

- Each increment is a bounded, safe, task-owned slice with focused tests and
  synced mdBook (the AXI chapter is currently thin — coordinate with proposed
  `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE`).
- Generated sources strict-check, lower to `.isf`/`.fsm`/HDL, and pass
  `--verify-hdl` where applicable.
- Each completed leaf committed per `COMMIT.md`.

## Task Tree

- ID: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER`
  Status: `active`
  Goal: `Grow a coherent AXI manager initiator profile that drives AXI transactions, modeled on the AHB requester, through the shared IAL2->IAL1->IAL0->HDL pipeline.`
  Children: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.1`

- ID: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.1`
  Status: `pending`
  Goal: `Audit the AXI manager initiator surface and select the smallest safe first increment + its first owner leaf.`
  Acceptance: `Read this tree's evidence, AxiManagerCapacityStatus.pm (interface/assumptions only — it is ~9,773 lines; do not read whole), ValidReadyChannel.pm, the two AW sources (ppif/axi_aw_valid_ready.ppif, ppif/axi_aw_w_valid_ready_bundle.ppif), AhbRequester.pm (the initiator model: transfer/burst tables, drive blocks, beat loop, address generation), the AXI evidence/probe task trees (AXI-VALID-READY-INTENT-PROBE, AXI-MANAGER-USER-API-BRAINSTORM-CAPTURE, AXI-ID-ORDERING-RULE-EVIDENCE-PROBE, AXI-MANAGER-RULE-MATRIX-DESIGN-PROBE), the AXI spec reference, support accounting, language surface, mdBook, decisions 0014/0015/0016/0017/0018, and Memory. Compare candidate first increments for the initiator — e.g. a bounded AW address-channel driver (drive one AWVALID/AWADDR/AWID/AWLEN/AWSIZE/AWBURST handshake against AWREADY), then W write-data drive (WVALID/WDATA/WSTRB/WLAST), then AR read-address drive, then burst/address generation, then integration with the capacity/status core — and select the smallest safe first increment plus its first owner leaf (readiness audit or contract selection), with evidence for why the others are larger/deferred. Leaning (to confirm or revise): the AW address-channel driver mirrors how both the AHB requester and the AXI response side bootstrapped (the AXI response side started from the AW valid-ready monitor). Do not change parser, generator, public sources, support-accounting, capability manifest, tests, generated artifacts, HDL/runtime behavior, direct backend, verification-output, backend-language variants, AHB/APB, or VHDL behavior in this selector leaf.`
  Verification: `pending`
  Commit: `pending`

## Notes

- Pivoted here from `IAL2-FEATURE-COMPLETENESS-FRONTIER` (still active for other
  IAL2 work). The AHB requester BUSY-insertion implementation
  `IAL2-FEATURE-COMPLETENESS-FRONTIER.788` remains a durable **pending** leaf,
  not abandoned — resume it anytime.
