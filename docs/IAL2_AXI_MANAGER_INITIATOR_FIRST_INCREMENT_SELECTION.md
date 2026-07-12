# IAL2 AXI manager initiator — first-increment selection

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.1` (no-behavior selector).
Status: selection recorded; no parser/generator/source/test/artifact change in this leaf.

This note records the smallest safe first increment for the AXI manager
**initiator** (bus-driving) profile and the first owner leaf that follows it. It
is the initiator-side analog of the AHB requester contract-selection note
(`docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_CONTRACT_SELECTION.md`).

## Decision

**First increment: a bounded AW address-channel driver.** A new IAL2
protocol-intent generator that *issues* one AW address transfer — drives
`AWVALID` plus the AW payload (`AWADDR`/`AWID`/`AWLEN`/`AWSIZE`/`AWBURST`) and
completes on the `AWREADY` handshake — from a local command trigger, exposing a
`done`/`busy` status. It complements, and does not touch, the shipped
capacity/status response core.

**First owner leaf: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.2`, a readiness
audit** — map the exact code/test/docs/report owners a new AW-driver generator
must touch and fix the safe first-slice boundary (signal/port list, widths,
fail-closed rules), before any contract-selection or implementation leaf. This
mirrors how both prior generators bootstrapped: `AhbRequester.pm` and the AXI
Valid-Ready generator each began from a readiness audit
(`docs/tasks/AXI-IAL2-VALID-READY-READINESS-AUDIT.md`).

## Why this is the smallest safe increment

The AW driver sits exactly one well-understood step past what already ships:

- **The authoring shape already exists.** `ppif/axi_aw_valid_ready.ppif`
  (`profile axi4`, `channel AW`, `valid awvalid`, `ready awready`, payload
  `awaddr`/`awlen`) is the same AW handshake — the response side bootstrapped
  from it as a **monitor**; the initiator drives the same handshake instead of
  observing it.
- **The driver model already exists.** `perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm`
  is the bus-driving analog: `(drive …)` blocks (`request_bus`/`transfer_nonseq`/
  `transfer_seq`), a `(transaction … (on cmd_valid (sample … as …_q)))`, and
  status drive lines. The AW driver reuses that drive-block + sample-on-trigger
  structure at a fraction of the size.
- **The monitor→driver delta is minimal.** `ValidReadyChannel.pm` is `(on valid)`
  + stability/hold asserts + a cover (it drives nothing). The AW driver keeps the
  same single-handshake scope but adds output-driving `(drive …)` blocks and a
  trigger→assert-VALID→await-READY→complete transaction. No new channels, no
  ordering, no response association.

The plug-in surface is small and fully localized (see "Owners" below), and every
touch point is already guarded by existing gates (`t/248`, `t/297`).

## Alternatives considered (why each is larger / deferred)

| Candidate | Why larger than the AW driver | Disposition |
|---|---|---|
| **W write-data drive** (`WVALID`/`WDATA`/`WSTRB`/`WLAST`) | Adds a second channel and beat/last sequencing; naturally expressed as an AW+W **bundle** (decision `0017`), so it presupposes the single-channel AW driver first. | Deferred — next after AW. |
| **AR read-address drive** (`ARVALID`/`ARADDR`/…) | Same handshake shape as AW but pulls in the read-data return path (R channel) to be useful; larger coherent slice. | Deferred. |
| **Burst / address generation** (INCR/WRAP, `AxLEN`/`AxSIZE` beat stepping) | The AHB requester's beat-loop + wrap/incr address math; a whole sequencing layer on top of a single handshake. | Deferred — a later increment on the AW/AR driver. |
| **Integration with the capacity/status core** | Couples a new driver to the ~9,773-line `AxiManagerCapacityStatus.pm` shell; cross-generator wiring is the largest and last step. | Deferred — after standalone drivers exist. |
| **`.axi` profile-alias surfacing** | Requires relaxing the `.axi` guard (`perl/FSM/Adapter/IAL2/PPIF.pm`) to admit a new contract kind; orthogonal vocabulary work (decision `0015`). | Deferred — optional, after the generic `.ppif` driver ships. |

## Owners the `.2` readiness audit will formally map

A new AW-driver generator is a new protocol-intent kind routed entirely inside
`perl/FSM/Adapter/IAL2/PPIF.pm` (there is no separate registry). The audit
confirms and details these touch points:

1. **Dispatch** — a `use` import; a new clause head + `_parse_*` + accumulator in
   `_contract_from_root` (and the missing-intent error enumeration); a
   cardinality/return block emitting a contract with a new `kind`; a new
   `_is_*_contract` predicate; a dispatch arm in `parse_source`.
2. **Generator module** — `perl/FSM/IAL2/ProtocolIntent/AxiAwDriver.pm` (name
   TBD), same envelope as `AhbRequester.pm`/`AxiManagerCapacityStatus.pm`
   (`layer`/`kind`/`mode`/`generated_ial1`/`generated_ial0`/
   `generated_ial1_schedule_report`/`report`), lowering IAL2 → generated `.isf`
   → `.fsm` (decision `0014`; never IAL2→IAL0 direct).
3. **Public source** — a new `ppif/axi_aw_driver.ppif` (or similarly named)
   fixture; report `schema` `fsmgen.ial2.protocol_intent.axi_aw_driver.v1` (TBD).
4. **Support accounting** — a `RegressionCorpus.pm` entry (id/relpath/coverage/
   `expected_module_name`), guarded by `t/248`.
5. **Capability manifest** — extend the `.ppif` `current_boundary` prose in
   `LanguageSurfaceSection.pm` (asserted verbatim by `t/297`).
6. **Test** — a new `t/14xx-*.t` mirroring `t/1473-ial2-ahb-requester.t` (parse,
   assert layer/kind/mode/schema, grep the generated `.isf` for the AW drive
   blocks).
7. **mdBook** — add an initiator/driving section to `docs/book/src/16a-ial2-axi.md`
   (currently monitor + capacity/status + response-demux only); coordinate with
   proposed `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE`.

## Constraints (decisions 0014–0018)

- `0014`: lower `IAL2 → IAL1/.isf → IAL0/.fsm → HDL`; never direct IAL2→IAL0.
- `0015`: the AXI initiator is a profile/vocabulary over the one generic `.ppif`
  container; `.axi` is an optional later alias with no direct-lowering privilege.
- `0016`: `.ppif` is the first public generic container; AXI is selected via a
  `(profile axi4)` clause, not by extension.
- `0017`: multi-channel intent (e.g. AW+W) is an aggregate bundle over
  per-channel generated artifacts — relevant when the W drive follows.
- `0018`: the contract/report are backend-language-neutral semantics; Perl module
  names are current entrypoints, not the definition.

## Non-goals of this increment

No change to the shipped `axi_manager_capacity_status_*` response core, the
valid-ready monitors, AHB/APB, or any other shipped behavior; no new IAL2
language layer; no direct IAL2→IAL0 lowering; no VHDL/backend-variant work.
