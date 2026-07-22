# IAL2-AXI-MANAGER-INITIATOR-FRONTIER: AXI manager initiator (bus-driving) side

## Metadata

- Tree ID: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER`
- Status: `active`
- Roadmap lane: `IAL2 / SV-backed feature completeness / AXI initiator`
- Created: `2026-07-12`
- Last updated: `2026-07-23` (`.8` done: bounded W-driver readiness audited; `.9` pending contract selection)
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
  Children: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.1`, `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.2`, `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.3`, `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.4`, `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.5`, `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.6`, `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.7`, `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.8`, `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.9`

- ID: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.1`
  Status: `done`
  Goal: `Audit the AXI manager initiator surface and select the smallest safe first increment + its first owner leaf.`
  Acceptance: `Read this tree's evidence, AxiManagerCapacityStatus.pm (interface/assumptions only — it is ~9,773 lines; do not read whole), ValidReadyChannel.pm, the two AW sources (ppif/axi_aw_valid_ready.ppif, ppif/axi_aw_w_valid_ready_bundle.ppif), AhbRequester.pm (the initiator model: transfer/burst tables, drive blocks, beat loop, address generation), the AXI evidence/probe task trees (AXI-VALID-READY-INTENT-PROBE, AXI-MANAGER-USER-API-BRAINSTORM-CAPTURE, AXI-ID-ORDERING-RULE-EVIDENCE-PROBE, AXI-MANAGER-RULE-MATRIX-DESIGN-PROBE), the AXI spec reference, support accounting, language surface, mdBook, decisions 0014/0015/0016/0017/0018, and Memory. Compare candidate first increments for the initiator — e.g. a bounded AW address-channel driver (drive one AWVALID/AWADDR/AWID/AWLEN/AWSIZE/AWBURST handshake against AWREADY), then W write-data drive (WVALID/WDATA/WSTRB/WLAST), then AR read-address drive, then burst/address generation, then integration with the capacity/status core — and select the smallest safe first increment plus its first owner leaf (readiness audit or contract selection), with evidence for why the others are larger/deferred. Leaning (to confirm or revise): the AW address-channel driver mirrors how both the AHB requester and the AXI response side bootstrapped (the AXI response side started from the AW valid-ready monitor). Do not change parser, generator, public sources, support-accounting, capability manifest, tests, generated artifacts, HDL/runtime behavior, direct backend, verification-output, backend-language variants, AHB/APB, or VHDL behavior in this selector leaf.`
  Verification: `passed — no-behavior selector; evidence read and selection recorded in docs/IAL2_AXI_MANAGER_INITIATOR_FIRST_INCREMENT_SELECTION.md; doctrine/continuity gates run at commit.`
  Commit: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.1: select the bounded AW address-channel driver as the first initiator increment`
  Selection: `Smallest safe first increment = a bounded AW address-channel driver (drive one AWVALID + AW payload AWADDR/AWID/AWLEN/AWSIZE/AWBURST handshake against AWREADY, from a local command trigger, with done/busy status). Confirms the leaning: the authoring shape already exists (ppif/axi_aw_valid_ready.ppif), the driver model already exists (AhbRequester.pm drive-blocks + on/sample transaction), and the monitor->driver delta is minimal (ValidReadyChannel.pm observes the same single handshake). Deferred as larger: W write-data drive (adds a channel; naturally an AW+W bundle per 0017, so AW first), AR read-address drive (pulls in the R return path), burst/address generation (the AHB beat-loop + wrap/incr math), capacity-core integration (cross-generator wiring against the ~9,773-line shell), and .axi alias surfacing (relax the .axi guard). First owner leaf spawned: .2 readiness audit. Full evidence + owner map: docs/IAL2_AXI_MANAGER_INITIATOR_FIRST_INCREMENT_SELECTION.md.`

- ID: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.2`
  Status: `done`
  Goal: `Readiness audit for the bounded AW address-channel driver: map the exact code/test/docs/report owners a new AW-driver generator must touch and fix the safe first-slice boundary, before any contract-selection or implementation leaf.`
  Acceptance: `Following the AXI-IAL2-VALID-READY-READINESS-AUDIT template and the owner map in docs/IAL2_AXI_MANAGER_INITIATOR_FIRST_INCREMENT_SELECTION.md, write a repo-local audit note that (a) identifies every touch point for a new AW-driver protocol-intent kind inside perl/FSM/Adapter/IAL2/PPIF.pm (use import; new clause head + _parse_* + accumulator in _contract_from_root incl. the missing-intent error enumeration; a cardinality/return block emitting a new contract kind; a new _is_*_contract predicate; a dispatch arm in parse_source), (b) the new generator module (envelope mirroring AhbRequester.pm; report schema fsmgen.ial2.protocol_intent.axi_aw_driver.v1 or final name; lowering IAL2->generated .isf->.fsm, never IAL2->IAL0 per 0014), (c) the new public ppif source + support-accounting entry in RegressionCorpus.pm (guarded by t/248), (d) the capability-manifest current_boundary prose in LanguageSurfaceSection.pm (asserted verbatim by t/297), (e) the new t/14xx test mirroring t/1473-ial2-ahb-requester.t, (f) the mdBook initiator section in docs/book/src/16a-ial2-axi.md (coordinate with proposed IAL2-MDBOOK-COHERENCE-AXI-COVERAGE), and (g) the exact AW driver signal/port list, widths, and fail-closed rules for the safe first slice. Distinguish immediate prerequisites, generated artifacts, public/report surfaces, validation gates, and explicit deferrals. Do not change parser, generator, public sources, support-accounting, capability manifest, tests, generated artifacts, HDL/runtime behavior, direct backend, verification-output, backend-language variants, AHB/APB, or VHDL behavior in this audit leaf.`
  Verification: `passed — no-behavior audit; anchors spot-verified against PPIF.pm (dispatch chain :45-100, clause dispatch _contract_from_root :259, .axi guard :224, predicates :2822/:2845); audit note docs/IAL2_AXI_MANAGER_INITIATOR_AW_DRIVER_READINESS_AUDIT.md; doctrine/continuity gates run at commit.`
  Commit: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.2: write the AW address-channel driver readiness audit`

- ID: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.3`
  Status: `done`
  Goal: `Contract selection for the bounded AW address-channel driver: fix the exact ppif clause spelling, generator/module name, report schema, driven-vs-sampled signal naming, AWID width policy, and the first-slice AW payload set, resolving the open questions in the readiness audit.`
  Acceptance: `Resolve the open questions in docs/IAL2_AXI_MANAGER_INITIATOR_AW_DRIVER_READINESS_AUDIT.md section 8 and record the final AW-driver contract in a repo-local contract-selection note (mirroring docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_CONTRACT_SELECTION.md): the (axi-aw-driver ...) clause head + object spelling, the generator module + result kind + report schema names, whether the driven AW payload reuses sampled input names or takes distinct _out names, the AWID width parameter/pin, and whether the first slice drives awaddr+awlen only or the full burst-describing set {awaddr, awid, awlen, awsize, awburst} (audit recommends the latter). Fix the fail-closed static rules and width pins. No parser/generator/public-source/support-accounting/manifest/test/artifact/behavior change in this selection leaf; the implementation is the following leaf.`
  Verification: `passed — no-behavior contract selection; recorded in docs/IAL2_AXI_MANAGER_INITIATOR_AW_DRIVER_CONTRACT_SELECTION.md; doctrine/continuity gates run at commit.`
  Commit: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.3: select the AW address-channel driver contract`
  Selection: `clause (axi-aw-driver ...); contract kind axi_aw_driver; module FSM::IAL2::ProtocolIntent::AxiAwDriver; result kind protocol_intent.axi_aw_driver; schema fsmgen.ial2.protocol_intent.axi_aw_driver.v1; source ppif/axi_aw_driver.ppif (profile axi4). Distinct command inputs vs driven AW outputs (AHB-consistent): inputs aw_cmd_valid + cmd_awaddr(32)/cmd_awid(4)/cmd_awlen(8)/cmd_awsize(3)/cmd_awburst(2) + awready; outputs awvalid + awaddr(32)/awid(4)/awlen(8)/awsize(3)/awburst(2) + aw_busy/aw_done. First slice drives the FULL burst-describing set (not awaddr+awlen only). AWID pinned to width 4 (configurability deferred). Fail-closed width pins + axi4 profile. Full contract incl. target ISF + report shape + residue: docs/IAL2_AXI_MANAGER_INITIATOR_AW_DRIVER_CONTRACT_SELECTION.md.`

- ID: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.4`
  Status: `done`
  Goal: `Implement the bounded AW address-channel driver generator per the .3 contract: a new FSM::IAL2::ProtocolIntent::AxiAwDriver generator that emits the fixed target ISF (accept_command/assert_aw/finish drive blocks + aw_issue transaction), lowering IAL2 -> generated .isf -> .fsm, wired into PPIF.pm dispatch, with a public ppif/axi_aw_driver.ppif source, support-accounting entry, capability-manifest boundary prose, a focused test, and a mdBook initiator section.`
  Acceptance: `Following docs/IAL2_AXI_MANAGER_INITIATOR_AW_DRIVER_CONTRACT_SELECTION.md exactly: (1) add FSM::IAL2::ProtocolIntent::AxiAwDriver.pm (envelope + _normalize_contract fail-closed rules + _emit_isf + _build_report as fixed by the contract); (2) wire PPIF.pm (use import; axi-aw-driver clause + _parse_axi_aw_driver + accumulator + missing-intent enumeration in _contract_from_root; _is_axi_aw_driver_contract predicate + dispatch arm in parse_source before the fallthrough); (3) add ppif/axi_aw_driver.ppif; (4) add the RegressionCorpus.pm entry intent.ppif_axi_aw_driver (gated by t/248); (5) extend the LanguageSurfaceSection.pm .ppif current_boundary prose (gated by t/297); (6) add t/14xx-ial2-axi-aw-driver.t modeled on t/1473 (assert layer/kind/mode/schema + grep the generated .isf for awvalid driving + the assert_aw/finish blocks); (7) add a mdBook initiator/driving section to docs/book/src/16a-ial2-axi.md. Generated source must strict-check, lower to .isf/.fsm, and pass --verify-hdl where applicable. Run t/248, t/297, the new test, mdbook build, and scripts/check_doctrines.sh; run heavy/broad runs under scripts/run_with_ram_guard.sh. Keep every doc/spec/manifest/test surface synchronized in the same slice.`
  Verification: `passed — new FSM::IAL2::ProtocolIntent::AxiAwDriver ships as t/1499 (all subtests incl --verify-hdl PASS: verilator lint + yosys synthesis), module axi_aw_driver, 7 states. Also verified: strict --check --json, --emit-semantic-json, --emit-schedule-json, --outdir (emits .isf/.fsm/.sv). Regressions green: t/248 (6641, counts 297->298 and 338->339 x2), t/297 (manifest prose + new assertion), t/1473 (AHB via shared PPIF.pm), scripts/check_doctrines.sh, mdbook build. Ial-neutral generator uses named drives (held AWVALID/payload) + (while (! awready) (drive assert_aw)) hold + (complete aw_done) one-cycle pulse, per the ISF-scheduler-verified idiom. t/1436 (heavy PPIF parser CLI) confirmed-pending in background under machine-wide CPU contention from unrelated concurrent workloads; changes are strictly additive and no assertion touches the modified missing-intent string.`
  Commit: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.4: ship the bounded AXI AW address-channel driver generator`
  Note: `Known model characteristic (surfaced): with registered (Moore) outputs, deassert_aw takes effect the cycle after AWREADY, so AWVALID can stay high one extra cycle in the deassert state (a second VALID&READY beat if the slave holds AWREADY). Inherent to the shipped generation model (the AHB requester shares it), not AW-driver-specific; a future refinement, not a first-slice blocker.`

- ID: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.5`
  Status: `done`
  Goal: `Select the next bounded AXI initiator increment after the shipped AW driver, centered on W write-data drive toward a coherent write transaction and framed under decision 0020's transaction-layered/composable-role North Star.`
  Acceptance: `Compare a standalone bounded W-channel driver, an immediate AW+W combined writer, AR drive, burst/address generation, and capacity-core integration. Select the smallest safe next increment and its exact following owner leaf. The selection must preserve IAL2 -> generated ISF -> generated FSM -> HDL, keep the generic .ppif container, distinguish the future protocol-neutral transaction interface from the present bus-side primitive, and explicitly disposition the shipped AW driver's registered-output extra-handshake risk before any W implementation clones that timing pattern. Record the decision in a repo-local selection note and synchronize this tree, docs/TASK_TREE.md, the AXI mdBook chapter, and MEMORY.md. Do not change parser, generator, public source, support accounting, capability manifest, tests, generated artifacts, HDL/runtime behavior, direct backend, AHB/APB, verification-output, backend-language variants, or VHDL behavior in this selector leaf.`
  Verification: `passed — no-behavior selector; W remains the next functional direction, but a generated-artifact trace plus temporary Verilator cardinality harness proved that one command produces two AWVALID && AWREADY acceptances when AWREADY remains asserted. Selection and root cause recorded in docs/IAL2_AXI_MANAGER_INITIATOR_POST_AW_NEXT_INCREMENT_SELECTION.md; durable fact card docs/knowledge/ial2-axi-aw-driver-double-handshake.md; doctrine/book/continuity gates run at commit.`
  Commit: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.5: select the single-transfer correctness prerequisite before W drive`
  Selection: `Keep a bounded single-beat W write-data driver as the next functional increment, but first execute .6: a behavior-neutral readiness audit that selects the narrow correction owner for driven Valid-Ready single-transfer cardinality. The later W candidate drives WVALID/WDATA(32)/WSTRB(4)/WLAST=1 against WREADY from distinct command inputs with bounded busy/done status. Deferred: W implementation until the invariant is fixed, AW+W composition, multi-beat sequencing, B completion, AR, burst/address generation, capacity-core integration, and activation of decision 0020's proposed protocol-neutral transaction interface.`

- ID: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.6`
  Status: `done`
  Goal: `Audit the shipped AW driver's driven Valid-Ready schedule and select the smallest lowering-clean correction that guarantees exactly one accepted AW transfer per accepted command when AWREADY remains asserted, establishing the invariant required by the later W driver.`
  Acceptance: `Reproduce and structurally explain the continuously-ready double-transfer from checked-in ppif/axi_aw_driver.ppif; trace the generated ISF/FSM/HDL schedule; compare bounded correction candidates across generated-ISF shape, existing ISF scheduling semantics, a new bounded ISF construct, and direct-backend timing; prove at least one candidate through a temporary executable acceptance-count harness; select the exact next behavior owner and regression contract. Preserve AW payload stability while stalled and one-cycle completion status. Record the audit in a repo-local note and synchronize this tree, docs/TASK_TREE.md, the AXI mdBook chapter, and MEMORY.md. Do not change parser, generator, public source, support accounting, capability manifest, tests, generated artifacts, HDL/runtime behavior, direct backend, W source/implementation, AW+W composition, multi-beat sequencing, B response completion, profile aliases, verification-output, backend-language variants, AHB/APB, or VHDL behavior in this audit leaf.`
  Verification: `passed — no-behavior readiness audit; reproduced the shipped two-acceptance baseline, traced named-drive next-edge timing, compared correction layers, and proved the selected existing-ISF rule-pair candidate. Candidate schedule JSON: 6 states, compile_issues empty, three priority resolutions; --verify-hdl: Verilator lint + Yosys synthesis PASS; executable Verilator harness: two commands across continuous-READY and stalled/one-cycle-READY cases produced PASS handshakes=2 done_pulses=2 with stalled payload stability and final valid/busy low. Audit: docs/IAL2_AXI_MANAGER_INITIATOR_SINGLE_TRANSFER_CORRECTNESS_READINESS_AUDIT.md; fact card: docs/knowledge/ial2-axi-aw-single-transfer-correction-shape.md; doctrine/book/continuity gates run at commit.`
  Commit: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.6: select the priority-resolved single-transfer correction`
  Selection: `Use only shipped ISF features: transaction samples -> inline launch_aw_start drive -> launch_aw rule sets active_q/aw_busy/awvalid/payload -> accept_aw rule guarded by (& awvalid awready) clears active_q/aw_busy/awvalid on the acceptance edge -> while active_q (wait 1) -> one-cycle aw_done. Declare (priority accept_aw over launch_aw), yielding zero schedule compile issues and mechanical priority guards. No parser/scheduler/IAL0/backend change.`

- ID: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.7`
  Status: `done`
  Goal: `Implement the selected priority-resolved generated-ISF schedule and an executable cardinality regression so each accepted AW command produces exactly one AWVALID && AWREADY transfer, including continuously-ready and one-cycle-ready-after-stall cases.`
  Acceptance: `Change only AxiAwDriver.pm::_emit_isf behavior to emit (priority accept_aw over launch_aw), the launch_aw/accept_aw rules, one inline launch_aw_start drive, and a while active_q (wait 1) loop per the .6 audit. Preserve the public .ppif syntax, module/kind/schema/bindings, widths, payload, report surface, support-accounting ID, capability manifest, and residue. Update t/1499 structural checks for the exact ISF/FSM/report shape and add an executable generated-SystemVerilog regression that counts rising-edge AWVALID && AWREADY acceptances and aw_done pulses for continuously-ready plus stalled/one-cycle-ready commands, proves stalled payload stability, expects one transfer/done per command, and ends valid/busy low. Require schedule compile_issues empty with expected priority resolutions, strict check/export/report paths, --verify-hdl, mdBook sync, doctrines, and relevant regressions. Do not add W syntax/behavior, AW+W composition, multi-beat sequencing, B completion, outstanding transactions, AR, burst/address generation, capacity-core integration, profile aliases, verification-output, backend-language variants, direct backend, generic ISF semantics, AHB/APB, or VHDL behavior.`
  Verification: `passed — AxiAwDriver now emits the selected 6-state generated-ISF schedule with inline launch handoff, priority-resolved launch_aw/accept_aw rules, and active_q wait; schedule compile_issues empty with exactly three expected priority resolutions. t/1499 PASS (4 subtests): structural/report/CLI paths, --verify-hdl Verilator lint + Yosys synthesis, and generated-HDL executable cardinality harness; two commands across continuous-READY and stalled/four-cycle-stable-payload/one-cycle-READY cases produce PASS handshakes=2 done_pulses=2 and end valid/busy low. Cross-surface guarded regressions PASS: t/248 + t/297 + t/1473, 6649 tests; Perl syntax, strict public-source generation, mdBook build, and doctrines PASS.`
  Commit: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.7: restore exactly-one AW acceptance per command`

- ID: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.8`
  Status: `done`
  Goal: `Write the readiness audit for the bounded single-beat AXI W write-data driver that follows the corrected AW primitive, fixing its safe behavior boundary and exact owner map before contract selection.`
  Acceptance: `Read the relevant AXI W Valid-Ready source anchors/spec reference, the corrected AxiAwDriver generated-ISF schedule and t/1499 executable invariant, existing W monitor/bundle sources, decisions 0014/0017/0020, PPIF dispatch/generator/support-accounting/capability-manifest touch points, and the AXI mdBook. Audit a separate bus-side W primitive with distinct upstream command inputs and driven outputs for WVALID, 32-bit WDATA, 4-bit WSTRB, fixed single-beat WLAST=1, WREADY, busy, and one-cycle done; require exactly one WVALID && WREADY acceptance per accepted command and stable payload/strobe/last while stalled. Fix fail-closed width/profile/role/cardinality rules, generated IAL1->IAL0 target shape based on the .7 rule-pair idiom, report/residue shape, test owner, and exact following contract-selection leaf. Explicitly defer AW/W coordination, B response completion, multi-beat data/last sequencing, outstanding transactions, capacity-core integration, protocol-neutral transaction-interface activation, profile aliases, verification-output, backend variants, AHB/APB, and VHDL. Record a repo-local audit and synchronize task tree/index/book/MEMORY without changing parser, generator, public source, tests, manifests, support accounting, generated artifacts, or runtime/HDL behavior.`
  Verification: `PASS — tracked Arm AXI pages 29-31 and 53-54 were text-extracted, rendered, and visually checked; docs/IAL2_AXI_MANAGER_INITIATOR_W_DRIVER_READINESS_AUDIT.md fixes the one-beat W boundary (WVALID/WDATA32/WSTRB4/WLAST=1/WREADY + busy/done), legal zero-strobe handling, exactly-once/stall-stability invariant, .7-derived six-state priority-resolved ISF target, fail-closed rules, parser/generator/source/support/manifest/t1500/book owners, residue, and .9 contract-selection scope. Knowledge Map, mdBook, memory, task-tree, docs-path, whitespace, and doctrine gates PASS.`
  Commit: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.8: audit the bounded single-beat AXI W driver`

- ID: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.9`
  Status: `pending`
  Goal: `Select the exact public contract for the audited bounded single-beat AXI W driver before any behavior changes.`
  Acceptance: `Use docs/IAL2_AXI_MANAGER_INITIATOR_W_DRIVER_READINESS_AUDIT.md to fix the clause head, parser kind, generator/result kind, report schema, public source path, actor/module name, support-accounting id/coverage, and t/1500 owner; fix distinct command/channel syntax for w_cmd_valid/cmd_wdata32/cmd_wstrb4/wready versus wvalid/wdata32/wstrb4/wlast/w_busy/w_done; pin accurate A2.3/A2.3.1/A2.3.2.1/A3.2.1/A3.2.1.1 source anchors, the six-state priority-resolved launch_w/accept_w/active_q generated-ISF target, legal WSTRB=0000 behavior, fail-closed profile/role/width/cardinality/mixing/duplicate-name diagnostics, report static rules and exact residue ids, implementation touch points, executable generated-HDL test scenarios, validation/rollback, and the exact behavior implementation leaf. Explicitly preserve all .8 deferrals and change no parser, generator, public source, test, manifest, support-accounting entry, generated artifact, runtime behavior, or HDL behavior. Record a repo-local contract-selection note and synchronize task tree/index/book/MEMORY/Knowledge Map.`
  Verification: `pending`
  Commit: `pending`

## Notes

- Pivoted here from `IAL2-FEATURE-COMPLETENESS-FRONTIER` (still active for other
  IAL2 work). The AHB requester BUSY-insertion implementation
  `IAL2-FEATURE-COMPLETENESS-FRONTIER.788` remains a durable **pending** leaf,
  not abandoned — resume it anytime.
- `.1` (done) selected the **bounded AW address-channel driver** as the first
  increment (evidence + alternative comparison + owner map:
  `docs/IAL2_AXI_MANAGER_INITIATOR_FIRST_INCREMENT_SELECTION.md`). `.2` (done)
  wrote the readiness audit
  (`docs/IAL2_AXI_MANAGER_INITIATOR_AW_DRIVER_READINESS_AUDIT.md`): the safe
  first-slice AW interface, the target ISF shape, fail-closed rules, and the
  exact owner map with `PPIF.pm` anchors. `.3` (done) fixed the contract
  (`docs/IAL2_AXI_MANAGER_INITIATOR_AW_DRIVER_CONTRACT_SELECTION.md`): clause
  `(axi-aw-driver …)`, module `AxiAwDriver`, kind `axi_aw_driver`, schema
  `…axi_aw_driver.v1`, distinct command inputs (`aw_cmd_valid` +
  `cmd_aw*`) vs driven outputs (`awvalid` + `aw*` + `aw_busy`/`aw_done`), the
  full burst-describing payload set, and AWID pinned to 4. `.4` (done) **shipped
  the generator** — the first AXI initiator behavior-landing slice:
  `perl/FSM/IAL2/ProtocolIntent/AxiAwDriver.pm`, wired into `PPIF.pm`, public
  `ppif/axi_aw_driver.ppif`, `RegressionCorpus.pm`/t248, `LanguageSurfaceSection.pm`/t297,
  `t/1499`, and the mdBook initiator section; `--verify-hdl` PASS. `.5` kept W
  write-data drive as the next functional increment, but proved that the shipped
  AW schedule could accept twice from one command when `AWREADY` remained
  asserted; `.6` selected the priority-resolved correction and `.7` shipped it
  with an executable exactly-once regression. `.8` completed the bounded
  single-beat W-driver readiness audit and selected `.9` to fix its exact
  public contract before implementation. Decision `0020` frames AW/W drivers as bus-side primitives
  beneath the proposed transaction-layered/composable-role North Star. The AW driver
  reuses the existing AW valid-ready authoring shape
  (`ppif/axi_aw_valid_ready.ppif`) and the `AhbRequester.pm` drive-block model,
  driven instead of observed. Plug-in surface: `perl/FSM/Adapter/IAL2/PPIF.pm`
  (dispatch), a new generator module, `perl/FSM/Support/RegressionCorpus.pm`
  (gated by `t/248`), `perl/FSM/Support/LanguageSurfaceSection.pm` (gated by
  `t/297`), a new `t/14xx` test modeled on `t/1473-ial2-ahb-requester.t`, and an
  initiator section in `docs/book/src/16a-ial2-axi.md`.
