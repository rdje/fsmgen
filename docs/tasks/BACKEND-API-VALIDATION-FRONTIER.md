# BACKEND-API-VALIDATION-FRONTIER: Backend, Validation, And Public API Frontier

## Metadata

- Tree ID: `BACKEND-API-VALIDATION-FRONTIER`
- Status: `active`
- Roadmap lane: `Backends And Validation` / `Embedding And Public APIs`
- Created: `2026-06-05`
- Last updated: `2026-06-05`
- Owner: repo-local workflow

## Goal

Own the backend, external-validation, embedding, and public-export backlog
items named in the 2026-06-05 remaining-work inventory.

## Non-Goals

- Do not implement backend or API behavior without an active exact child leaf.
- Do not claim VHDL, GHDL, ABC, structured generation, or embedding API
  behavior as shipped without matching code, tests, and mdBook coverage.
- Do not leak unstable internal objects as public API surfaces.

## Acceptance Criteria

- Each backend/API backlog item has a leaf-level owner.
- When selected, the tree activates one executable leaf at a time.
- Public docs/mdBook and API contracts are synchronized for every shipped
  behavior.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `BACKEND-API-VALIDATION-FRONTIER`
  Status: `active`
  Goal: `Track backend, validation, embedding, and public API backlog directions.`
  Children: `BACKEND-API-VALIDATION-FRONTIER.1`,
    `BACKEND-API-VALIDATION-FRONTIER.2`,
    `BACKEND-API-VALIDATION-FRONTIER.2.1`,
    `BACKEND-API-VALIDATION-FRONTIER.3`,
    `BACKEND-API-VALIDATION-FRONTIER.4`,
    `BACKEND-API-VALIDATION-FRONTIER.4.1`,
    `BACKEND-API-VALIDATION-FRONTIER.4.2`,
    `BACKEND-API-VALIDATION-FRONTIER.4.3`,
    `BACKEND-API-VALIDATION-FRONTIER.4.4`,
    `BACKEND-API-VALIDATION-FRONTIER.4.4.1`,
    `BACKEND-API-VALIDATION-FRONTIER.4.5`,
    `BACKEND-API-VALIDATION-FRONTIER.4.5.1`,
    `BACKEND-API-VALIDATION-FRONTIER.4.6`,
    `BACKEND-API-VALIDATION-FRONTIER.4.6.1`,
    `BACKEND-API-VALIDATION-FRONTIER.4.7`,
    `BACKEND-API-VALIDATION-FRONTIER.5`,
    `BACKEND-API-VALIDATION-FRONTIER.5.1`,
    `BACKEND-API-VALIDATION-FRONTIER.6`,
    `BACKEND-API-VALIDATION-FRONTIER.6.1`,
    `BACKEND-API-VALIDATION-FRONTIER.7`,
    `BACKEND-API-VALIDATION-FRONTIER.7.1`,
    `BACKEND-API-VALIDATION-FRONTIER.8`

- ID: `BACKEND-API-VALIDATION-FRONTIER.1`
  Status: `done`
  Goal: `Select the next executable backend/API leaf from evidence.`
  Acceptance: `Activated the backend/API frontier after the broad ISF/R14 frontier exhausted and selected BACKEND-API-VALIDATION-FRONTIER.2.1, the first scoped direct-root VHDL backend scaffold leaf.`
  Verification: `Selection audit/read: docs/TASK_TREE.md, docs/book/src/14-feature-backlog.md Backends And Validation section, docs/VHDL_SCOPE.md, docs/tasks/COMPOSITION-TYPE-BACKLOG-EXHAUSTION.md VHDL prerequisite result, README.md backend/API pointers, perl/FSM/HDL/FlattenedDT.pm generate_vhdl not-implemented boundary, perl/FSM/HDL/FlattenedDT/Backend/Verilog.pm conversion pattern, t/386-hdl-generator-facade-target-language-boundary-audit.t, and t/114-composition-target-support-diagnostics.t. Evidence shows VHDL is the first listed backend/API backlog item, unblocks GHDL/composition VHDL work, and has a narrow direct-root SV-first conversion plan while composition VHDL remains fail-closed.`
  Commit: `BACKEND-API-VALIDATION-FRONTIER.1: select VHDL direct scaffold`

- ID: `BACKEND-API-VALIDATION-FRONTIER.2`
  Status: `done`
  Goal: `Implement or explicitly scope the full VHDL backend frontier.`
  Children: `BACKEND-API-VALIDATION-FRONTIER.2.1`
  Acceptance: `One exact VHDL backend surface is selected, implemented or blocked, documented, and regression-covered.`
  Verification: `BACKEND-API-VALIDATION-FRONTIER.2.1 shipped the first exact direct-root VHDL scaffold surface with focused pipeline/CLI regression coverage, docs/mdBook sync, and composition/aggregate/GHDL/full-parity deferrals preserved.`
  Commit: `BACKEND-API-VALIDATION-FRONTIER.2.1: ship VHDL direct scaffold`

- ID: `BACKEND-API-VALIDATION-FRONTIER.2.1`
  Status: `done`
  Goal: `Implement the first direct-root VHDL backend scaffold through an SV-first converter module.`
  Acceptance: `perl/FSM/HDL/FlattenedDT.pm routes direct single-FSM VHDL generation through FSM::HDL::FlattenedDT::Backend::VHDL instead of the blanket not-implemented die for accepted direct roots. The accepted fixtures cover clock/reset, scalar/vector ports, state progression, basic enable assignments, sync reset, async active-low reset, and flat/nested concat RHS lowering, emitting deterministic VHDL text through the existing pipeline and CLI target path. Composition/top VHDL remains fail-closed with the existing composition diagnostic, aggregate-output direct roots fail closed at the scaffold boundary, and GHDL validation, packages, multi-clock domains, aggregate VHDL, and full feature parity remain deferred. Focused tests, docs/mdBook, capability/API surfaces, and required gates pass.`
  Verification: `perl -Iperl -c perl/FSM/HDL/FlattenedDT.pm; perl -Iperl -c perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm; prove -Iperl t/1420-vhdl-direct-backend-scaffold.t t/386-hdl-generator-facade-target-language-boundary-audit.t t/114-composition-target-support-diagnostics.t t/404-hdl-generator-facade-target-language-shape-boundary-audit.t; scripts/check_memory_architecture.sh; bash knowledge-map/scripts/check_knowledge_map.sh; prove -Iperl t/1414-docs-relative-paths-audit.t; prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t; mdbook build docs/book; git diff --check. command -v ghdl returned unavailable, so GHDL remains deferred.`
  Commit: `BACKEND-API-VALIDATION-FRONTIER.2.1: ship VHDL direct scaffold`

- ID: `BACKEND-API-VALIDATION-FRONTIER.3`
  Status: `done`
  Goal: `Audit GHDL validation viability for the direct VHDL scaffold and keep external-validation contracts honest.`
  Acceptance: `Local GHDL availability was checked and command -v ghdl returned unavailable. The existing --verify-hdl SystemVerilog-only boundary remains explicit in CLI tests, manifest contract guidance, docs, mdBook, task tree, and memory. No GHDL API or backend-validation manifest lane is advertised without a runnable tool-backed subset. The external validation contract now records the active direct VHDL generation scaffold, retains the legacy VHDL-backend deferral flag for compatibility, and adds the current vhdl_validation_deferred_until_ghdl_validation_lane flag.`
  Verification: `perl -Iperl -c perl/FSM/Support/HDLExternalValidationContract.pm; prove -Iperl t/313-hdl-external-validation-contract.t t/1057-hdl-external-validation-contract-full-surface-json-roundtrip-audit.t t/1058-hdl-external-validation-contract-full-surface-defensive-copy-audit.t t/297-capability-manifest.t t/308-systemverilog-external-validation.t; scripts/check_memory_architecture.sh; bash knowledge-map/scripts/check_knowledge_map.sh; prove -Iperl t/1414-docs-relative-paths-audit.t; prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t; mdbook build docs/book; git diff --check; command -v ghdl returned unavailable.`
  Commit: `BACKEND-API-VALIDATION-FRONTIER.3: keep GHDL validation deferred`

- ID: `BACKEND-API-VALIDATION-FRONTIER.4`
  Status: `done`
  Goal: `Drive warning-clean external validation across historical samples.`
  Children: `BACKEND-API-VALIDATION-FRONTIER.4.1`,
    `BACKEND-API-VALIDATION-FRONTIER.4.2`,
    `BACKEND-API-VALIDATION-FRONTIER.4.3`,
    `BACKEND-API-VALIDATION-FRONTIER.4.4`,
    `BACKEND-API-VALIDATION-FRONTIER.4.4.1`,
    `BACKEND-API-VALIDATION-FRONTIER.4.5`,
    `BACKEND-API-VALIDATION-FRONTIER.4.5.1`,
    `BACKEND-API-VALIDATION-FRONTIER.4.6`,
    `BACKEND-API-VALIDATION-FRONTIER.4.6.1`,
    `BACKEND-API-VALIDATION-FRONTIER.4.7`
  Acceptance: `One exact historical sample family or tool gate is selected, cleaned or deferred, documented, and covered.`
  Verification: `BACKEND-API-VALIDATION-FRONTIER.4.1 added fsm/trial_0.fsm, BACKEND-API-VALIDATION-FRONTIER.4.2 added fsm/mipicsi2_configreg.fsm plus fsm/mipicsi2_fifo_4x8.fsm, BACKEND-API-VALIDATION-FRONTIER.4.3 added all remaining current MIPI samples under fsm/ to the external SystemVerilog validation smoke, BACKEND-API-VALIDATION-FRONTIER.4.4.1 added fsm/apb_tb.fsm after fixing generated-child shared-datapath export-port sink binding, BACKEND-API-VALIDATION-FRONTIER.4.5.1 made fsm/trial_2.fsm an explicit expected-failure corpus boundary, BACKEND-API-VALIDATION-FRONTIER.4.6.1 made fsm/generic_fifo.fsm an explicit expected-failure corpus boundary, and BACKEND-API-VALIDATION-FRONTIER.4.7 made fsm/lte_digital_rf.fsm an explicit expected-failure corpus boundary. The current historical external-validation frontier is exhausted: warning-clean supported samples are in the smoke, and remaining broad legacy samples are corpus-backed expected failures.`
  Commit: `this slice`

- ID: `BACKEND-API-VALIDATION-FRONTIER.4.1`
  Status: `done`
  Goal: `Add the already warning-clean historical trial_0 sample to the external SystemVerilog validation smoke.`
  Acceptance: `t/308-systemverilog-external-validation.t validates fsm/trial_0.fsm through the existing Verilator lint plus ABC-free Yosys synthesis lane when tools are installed. docs/REGRESSION_CORPUS.md and the mdBook generated-HDL debugging chapter list trial_0 in the focused external-validation smoke. Broader historical samples such as composition apb_tb and legacy-composition trial_2 remain deferred behind their own exact owner leaves because probe runs showed PINMISSING composition wiring warnings and legacy mapping rejection respectively.`
  Verification: `./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_trial_0_verify.sv fsm/trial_0.fsm; prove -Iperl t/308-systemverilog-external-validation.t; scripts/check_memory_architecture.sh; bash knowledge-map/scripts/check_knowledge_map.sh; prove -Iperl t/1414-docs-relative-paths-audit.t; prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t; mdbook build docs/book; git diff --check. Selection probes: ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_apb_tb_verify.sv fsm/apb_tb.fsm failed on Verilator PINMISSING composition child pins; ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_trial_2_verify.sv fsm/trial_2.fsm failed on legacy composition ?ports mapping. Temporary /tmp probe outputs were removed.`
  Commit: `this slice`

- ID: `BACKEND-API-VALIDATION-FRONTIER.4.2`
  Status: `done`
  Goal: `Add the warning-clean MIPI config/fifo direct samples to the external SystemVerilog validation smoke.`
  Acceptance: `t/308-systemverilog-external-validation.t validates fsm/mipicsi2_configreg.fsm and fsm/mipicsi2_fifo_4x8.fsm through the existing Verilator lint plus ABC-free Yosys synthesis lane when tools are installed. docs/REGRESSION_CORPUS.md and the mdBook generated-HDL debugging chapter list those samples in the focused smoke. Broader historical samples such as generic_fifo and lte_digital_rf remain deferred behind exact future owner leaves because probe runs showed unsupported ?define source kind and legacy multi-RTL composition syntax respectively.`
  Verification: `./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_mipicsi2_configreg_verify.sv fsm/mipicsi2_configreg.fsm; ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_mipicsi2_fifo_4x8_verify.sv fsm/mipicsi2_fifo_4x8.fsm; prove -Iperl t/308-systemverilog-external-validation.t; scripts/check_memory_architecture.sh; bash knowledge-map/scripts/check_knowledge_map.sh; prove -Iperl t/1414-docs-relative-paths-audit.t; prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t; mdbook build docs/book; git diff --check. Selection probes: ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_generic_fifo_verify.sv fsm/generic_fifo.fsm failed on unsupported ?define source kind; ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_lte_digital_rf_verify.sv fsm/lte_digital_rf.fsm failed on legacy multi-RTL composition syntax. Temporary /tmp probe outputs were removed.`
  Commit: `this slice`

- ID: `BACKEND-API-VALIDATION-FRONTIER.4.3`
  Status: `done`
  Goal: `Add the remaining warning-clean MIPI direct samples to the external SystemVerilog validation smoke.`
  Acceptance: `t/308-systemverilog-external-validation.t validates fsm/mipicsi2_laned_clog.fsm, fsm/mipicsi2_laned_sctrl.fsm, fsm/mipicsi2_rxccore_hs.fsm, fsm/mipicsi2_rxdcore_hs.fsm, fsm/mipicsi2_txccore_hs.fsm, fsm/mipicsi2_txccore_ulp.fsm, fsm/mipicsi2_txdcore_hs.fsm, fsm/mipicsi2_txdcore_lp.fsm, and fsm/mipicsi2_xgamaster.fsm through the existing Verilator lint plus ABC-free Yosys synthesis lane when tools are installed. docs/REGRESSION_CORPUS.md and the mdBook generated-HDL debugging chapter state that all MIPI samples currently in fsm/ are covered by the focused smoke.`
  Verification: `./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_mipicsi2_laned_clog_verify.sv fsm/mipicsi2_laned_clog.fsm; ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_mipicsi2_laned_sctrl_verify.sv fsm/mipicsi2_laned_sctrl.fsm; ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_mipicsi2_rxccore_hs_verify.sv fsm/mipicsi2_rxccore_hs.fsm; ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_mipicsi2_rxdcore_hs_verify.sv fsm/mipicsi2_rxdcore_hs.fsm; ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_mipicsi2_txccore_hs_verify.sv fsm/mipicsi2_txccore_hs.fsm; ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_mipicsi2_txccore_ulp_verify.sv fsm/mipicsi2_txccore_ulp.fsm; ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_mipicsi2_txdcore_hs_verify.sv fsm/mipicsi2_txdcore_hs.fsm; ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_mipicsi2_txdcore_lp_verify.sv fsm/mipicsi2_txdcore_lp.fsm; ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_mipicsi2_xgamaster_verify.sv fsm/mipicsi2_xgamaster.fsm; prove -Iperl t/308-systemverilog-external-validation.t; scripts/check_memory_architecture.sh; bash knowledge-map/scripts/check_knowledge_map.sh; prove -Iperl t/1414-docs-relative-paths-audit.t; prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t; mdbook build docs/book; git diff --check. Temporary /tmp probe outputs were removed.`
  Commit: `this slice`

- ID: `BACKEND-API-VALIDATION-FRONTIER.4.4`
  Status: `done`
  Goal: `Select the next exact blocked historical validation sample after full MIPI smoke coverage.`
  Acceptance: `Selected fsm/apb_tb.fsm as the next exact blocked historical validation target because it is a supported C4 composition fixture that already parses and generates HDL, but external validation fails on unbound generated-child shared-datapath export-enable output pins. The exact implementation owner is BACKEND-API-VALIDATION-FRONTIER.4.4.1. The other blocked candidates remain deferred behind later leaves: generic_fifo (?define source kind), lte_digital_rf (legacy multi-RTL composition syntax), and trial_2 (legacy composition ?ports mapping).`
  Verification: `Selection evidence: ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_apb_tb_verify.sv fsm/apb_tb.fsm failed in Verilator lint with 23 PINMISSING warnings, all generated-child shared_dp_export_*_en output ports on requester/completer instances. Read fsm/apb_tb.fsm, perl/FSM/Composition/GeneratedChildRealizer.pm, perl/FSM/Composition/InterfacePortBuilder.pm, perl/FSM/Composition/SharedDatapathSupport.pm, perl/FSM/Composition/LinkedPlanBuilder.pm, and perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm; the evidence points at generated child HDL export ports being patched after structural metadata is built, while top instantiations consume the unchanged realized child interface.`
  Commit: `this slice`

- ID: `BACKEND-API-VALIDATION-FRONTIER.4.4.1`
  Status: `done`
  Goal: `Make fsm/apb_tb.fsm warning-clean in external SystemVerilog validation by preserving generated-child shared-datapath export ports in realized composition interfaces.`
  Acceptance: `Generated-child shared-datapath export-enable ports are now deterministically bound in composition tops. Real shared-datapath exports keep their source-enable helper bindings; unconsumed exports bind to top-local one-bit sink wires named shared_dp_unused_<instance>_<export>, avoiding unconnected named child pins without changing the user-visible top interface. fsm/apb_tb.fsm passes the existing Verilator lint plus ABC-free Yosys synthesis external validation lane and is registered in t/308-systemverilog-external-validation.t as a supported composition protocol smoke. Existing shared-datapath lifted-runtime behavior remains intact. docs/REGRESSION_CORPUS.md, docs/book/src/09-generated-hdl-debugging-and-inspection.md, docs/book/src/14-feature-backlog.md, and docs/knowledge/composition-shared-datapath-export-sinks.md are synchronized.`
  Verification: `perl -Iperl -c perl/FSM/Composition/SharedDatapathSupport.pm; prove -Iperl t/247-protocol-fixture-regression-smoke.t; ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_apb_tb_verify.sv fsm/apb_tb.fsm; prove -Iperl t/146-composition-shared-datapath-lifted-register-runtime.t t/147-composition-shared-datapath-internal-lifted-register-runtime.t; prove -Iperl t/308-systemverilog-external-validation.t; prove -Iperl t/248-regression-corpus-accounting.t t/296-regression-corpus-supported-behavior.t t/302-normalized-semantic-json.t t/305-hdl-generator-result-contract.t t/306-extension-contract.t t/307-composition-report-contract.t t/311-normalized-semantic-report-contract.t t/312-check-diagnostics-contract.t t/314-support-accounting-contract.t t/353-composition-system-contract-runtime-audit.t t/354-normalized-semantic-child-runtime-contract-audit.t t/355-hdl-generator-leaf-runtime-contract-audit.t t/631-normalized-semantic-composition-plan-snapshot.t t/632-serializable-generation-result-snapshot.t t/633-normalized-semantic-generation-result-snapshot.t t/643-serializable-composition-plan-snapshot-defensive-copy-boundary-audit.t t/644-normalized-semantic-composition-plan-snapshot-alias-boundary-audit.t t/651-serializable-composition-plan-snapshot-json-roundtrip-audit.t t/652-normalized-semantic-snapshots-json-roundtrip-audit.t t/663-public-report-embedded-snapshot-source-ownership-audit.t t/664-public-report-embedded-snapshot-key-alignment-audit.t; scripts/check_memory_architecture.sh; bash knowledge-map/scripts/check_knowledge_map.sh; prove -Iperl t/1414-docs-relative-paths-audit.t; prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t; mdbook build docs/book; git diff --check`
  Commit: `this slice`

- ID: `BACKEND-API-VALIDATION-FRONTIER.4.5`
  Status: `done`
  Goal: `Select the next exact blocked historical validation sample after APB composition smoke coverage.`
  Acceptance: `Selected fsm/trial_2.fsm as the next exact blocked historical validation target because it is the smallest remaining blocked source and the first failure is a bounded composition-parser boundary: legacy ?ports mapping directives such as /data_o/{tasu_timestamp, tasu_pl_data}/ are currently rejected inside ?ports blocks. The exact implementation or deferral owner is BACKEND-API-VALIDATION-FRONTIER.4.5.1. Remaining broader candidates stay deferred behind later leaves: fsm/generic_fifo.fsm (?define / ?& template macro surface) and fsm/lte_digital_rf.fsm (10k-line legacy multi-RTL composition with +arch directives and multi-module ?rtl payloads).`
  Verification: `Selection probes: ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_trial_2_verify.sv fsm/trial_2.fsm failed on legacy ?ports mapping directive /data_o/{tasu_timestamp, tasu_pl_data}/; ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_generic_fifo_verify.sv fsm/generic_fifo.fsm failed on unsupported top-level ?define:generic_fifo; ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_lte_digital_rf_verify.sv fsm/lte_digital_rf.fsm failed on legacy multi-RTL ?rtl child source count. Read fsm/trial_2.fsm, fsm/generic_fifo.fsm, fsm/lte_digital_rf.fsm, and the relevant Parser.pm rejection points.`
  Commit: `this slice`

- ID: `BACKEND-API-VALIDATION-FRONTIER.4.5.1`
  Status: `done`
  Goal: `Resolve the fsm/trial_2.fsm legacy ?ports mapping validation boundary by implementing a bounded compatibility slice or recording an exact fail-closed deferral.`
  Acceptance: `Explicitly deferred fsm/trial_2.fsm at the existing fail-closed legacy ?ports mapping boundary instead of reviving the broader historical composition dialect. Added the whole file as the expected-failure corpus entry contract.trial_2_ports_mapping_directive with stable FSMGEN_COMPOSITION_PORT_DECLARATION_MODE accounting, pipeline/CLI/check-JSON/semantic-JSON coverage, a knowledge-map fact card, and mdBook/corpus documentation. No parser behavior changed.`
  Verification: `./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_trial_2_verify.sv fsm/trial_2.fsm failed as expected on /data_o/{tasu_timestamp, tasu_pl_data}/ inside ?ports; perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm; prove -Iperl t/248-regression-corpus-accounting.t t/249-regression-corpus-classified-behavior.t t/300-check-json-regression-corpus.t t/304-normalized-semantic-json-regression-corpus.t t/127-composition-ports-mapping-diagnostics.t; scripts/check_memory_architecture.sh; bash knowledge-map/scripts/check_knowledge_map.sh; prove -Iperl t/1414-docs-relative-paths-audit.t; prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t; mdbook build docs/book; git diff --check.`
  Commit: `this slice`

- ID: `BACKEND-API-VALIDATION-FRONTIER.4.6`
  Status: `done`
  Goal: `Select the next exact blocked historical validation sample after the trial_2 deferral.`
  Acceptance: `Selected fsm/generic_fifo.fsm as the next exact blocked historical validation target because it is 156 lines and fails immediately at the language-contract boundary for unsupported top-level ?define:generic_fifo, while fsm/lte_digital_rf.fsm is 10,601 lines and remains deferred behind a broader legacy multi-module ?rtl composition boundary. The exact implementation-or-deferral owner is BACKEND-API-VALIDATION-FRONTIER.4.6.1.`
  Verification: `Selection probes: ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_generic_fifo_verify.sv fsm/generic_fifo.fsm failed on unsupported top-level source ?define:generic_fifo; ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_lte_digital_rf_verify.sv fsm/lte_digital_rf.fsm failed on ?rtl child lte_dif_iosocket with 36 RTL module references; wc -l fsm/generic_fifo.fsm fsm/lte_digital_rf.fsm returned 156 and 10601 lines respectively; read the leading source shapes and confirmed no /tmp probe output files were emitted.`
  Commit: `this slice`

- ID: `BACKEND-API-VALIDATION-FRONTIER.4.6.1`
  Status: `done`
  Goal: `Resolve the fsm/generic_fifo.fsm legacy template validation boundary by implementing a bounded compatibility slice or recording an exact fail-closed deferral.`
  Acceptance: `Explicitly deferred fsm/generic_fifo.fsm at the existing fail-closed legacy template boundary instead of reviving the broader historical ?define / ?& macro dialect. Added the whole file as the expected-failure corpus entry contract.generic_fifo_define_template_source with stable FSMGEN_LANGUAGE_UNSUPPORTED_TOP_LEVEL_SOURCE accounting, pipeline/CLI/check-JSON/semantic-JSON coverage, a knowledge-map fact card, and mdBook/corpus documentation. Also repaired the human regression-corpus table to include the prior contract.trial_2_ports_mapping_directive entry. No parser behavior changed.`
  Verification: `./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_generic_fifo_verify.sv fsm/generic_fifo.fsm failed as expected on unsupported top-level source ?define:generic_fifo; perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm; prove -Iperl t/248-regression-corpus-accounting.t t/249-regression-corpus-classified-behavior.t t/300-check-json-regression-corpus.t t/304-normalized-semantic-json-regression-corpus.t t/41-language-contract-top-level-source-kind-boundary.t; scripts/check_memory_architecture.sh; bash knowledge-map/scripts/check_knowledge_map.sh; prove -Iperl t/1414-docs-relative-paths-audit.t; prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t; mdbook build docs/book; git diff --check.`
  Commit: `this slice`

- ID: `BACKEND-API-VALIDATION-FRONTIER.4.7`
  Status: `done`
  Goal: `Resolve the fsm/lte_digital_rf.fsm legacy multi-RTL composition validation boundary by implementing a bounded compatibility slice or recording an exact fail-closed deferral.`
  Acceptance: `Explicitly deferred fsm/lte_digital_rf.fsm at the existing fail-closed legacy multi-module ?rtl composition boundary instead of reviving the broader historical multi-RTL dialect. Added the whole file as the expected-failure corpus entry contract.lte_digital_rf_rtl_child_source_count with stable FSMGEN_COMPOSITION_RTL_CHILD_SOURCE_COUNT accounting, pipeline/CLI/check-JSON/semantic-JSON coverage, a knowledge-map fact card, and mdBook/corpus documentation. No parser behavior changed.`
  Verification: `./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_lte_digital_rf_verify.sv fsm/lte_digital_rf.fsm failed as expected on ?rtl child lte_dif_iosocket with 36 RTL module references; perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm; prove -Iperl t/248-regression-corpus-accounting.t t/249-regression-corpus-classified-behavior.t t/300-check-json-regression-corpus.t t/304-normalized-semantic-json-regression-corpus.t; scripts/check_memory_architecture.sh; bash knowledge-map/scripts/check_knowledge_map.sh; prove -Iperl t/1414-docs-relative-paths-audit.t; prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t; mdbook build docs/book; git diff --check.`
  Commit: `this slice`

- ID: `BACKEND-API-VALIDATION-FRONTIER.5`
  Status: `done`
  Goal: `Harden ABC mapping behavior.`
  Children: `BACKEND-API-VALIDATION-FRONTIER.5.1`
  Acceptance: `Selected optional ABC executable discovery as the exact ABC mapping hardening edge. The implementation owner is BACKEND-API-VALIDATION-FRONTIER.5.1: report optional ABC mapping tool availability in the external validation support surface and contract while keeping the shipped validation lane ABC-free, non-requiring, and still driven by Verilator plus Yosys synth -noabc.`
  Verification: `Selection audit/read: perl/FSM/Support/HDLExternalValidation.pm, perl/FSM/Support/HDLExternalValidationContract.pm, perl/FSM/Support/BackendValidationSection.pm, t/308-systemverilog-external-validation.t, t/313-hdl-external-validation-contract.t, t/297-capability-manifest.t, README.md, docs/REGRESSION_CORPUS.md, docs/SPECFORGE_FEEDBACK_RESPONSE.md, docs/book/src/09-generated-hdl-debugging-and-inspection.md, docs/book/src/14-feature-backlog.md, and local tool probes command -v yosys, command -v yosys-abc, command -v berkeley-abc, command -v abc. Evidence: Yosys is installed, yosys-abc is installed, berkeley-abc and abc are unavailable, and the current validation/manifest/book contract intentionally uses synth -noabc with yosys_abc_enabled false.`
  Commit: `this slice`

- ID: `BACKEND-API-VALIDATION-FRONTIER.5.1`
  Status: `done`
  Goal: `Report optional ABC executable discovery while preserving the ABC-free external validation gate.`
  Acceptance: `The external validation support surface now discovers an optional ABC mapping executable candidate without making it a required validation tool. missing_systemverilog_validation_tools() still only requires Verilator and Yosys. validate_systemverilog_file() still runs Verilator lint and Yosys synth -noabc/stat, with no standalone ABC pass. The external validation contract and capability manifest expose required_tools, optional_tools, abc_tool_candidates, abc_mapping_status, and abc_mapping_required. README, live docs, mdBook, and a knowledge-map fact card explain the boundary.`
  Verification: `perl -Iperl -c perl/FSM/Support/HDLExternalValidation.pm; perl -Iperl -c perl/FSM/Support/HDLExternalValidationContract.pm; prove -Iperl t/313-hdl-external-validation-contract.t t/297-capability-manifest.t; prove -Iperl t/308-systemverilog-external-validation.t; prove -Iperl t/460-hdl-external-validation-contract-defensive-copy-boundary-audit.t t/1057-hdl-external-validation-contract-full-surface-json-roundtrip-audit.t t/1058-hdl-external-validation-contract-full-surface-defensive-copy-audit.t t/323-backend-validation-contract.t; prove -Iperl t/365-backend-validation-section-runtime-contract-audit.t t/358-capability-manifest-runtime-contract-audit.t; bash knowledge-map/scripts/check_knowledge_map.sh; scripts/check_memory_architecture.sh; prove -Iperl t/1414-docs-relative-paths-audit.t; prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t; mdbook build docs/book; git diff --check.`
  Commit: `this slice`

- ID: `BACKEND-API-VALIDATION-FRONTIER.6`
  Status: `done`
  Goal: `Broaden structured non-flattened generation.`
  Children: `BACKEND-API-VALIDATION-FRONTIER.6.1`
  Acceptance: `Selected the flattened-default generation-mode boundary as the exact structured/non-flattened generation edge. The implementation owner is BACKEND-API-VALIDATION-FRONTIER.6.1: expose the current debug-first flattened generation mode in the HDLGenerator facade contract and capability manifest while keeping generation_mode non-public/rejected until a real non-flattened backend path is implemented and regression-backed.`
  Verification: `Selection audit/read: docs/book/src/01-first-fsm.md, docs/book/src/09-generated-hdl-debugging-and-inspection.md, docs/book/src/14-feature-backlog.md, perl/FSM/Backend/GeneratedModuleEmitter.pm, perl/FSM/Pipeline/HDLGenerator.pm, perl/FSM/Support/HDLGeneratorFacadeContract.pm, t/375-hdl-generator-facade-contract.t, t/414-hdl-generator-facade-constructor-option-name-boundary-audit.t, t/297-capability-manifest.t, and t/439-hdl-generator-facade-contract-defensive-copy-boundary-audit.t. Evidence: generated-module emission still drives FSM::HDL::FlattenedDT, the public facade constructor options do not include generation_mode, unsupported constructor options are rejected before setup, and the book already says flattened generation is the intentional shipped default.`
  Commit: `this slice`

- ID: `BACKEND-API-VALIDATION-FRONTIER.6.1`
  Status: `done`
  Goal: `Publish the flattened-default generation-mode boundary without adding a non-flattened backend path.`
  Acceptance: `The HDLGenerator facade contract and capability manifest expose the current generation mode as flattened_debug_first, advertise the accepted generation-mode family as flattened_debug_first only, record structured_nonflattened_generation_enabled as false, and record the deferred status. generation_mode remains absent from public constructor options and is still rejected by FSM::Pipeline::HDLGenerator->new(...) as an unsupported constructor option. README/live docs/mdBook explain the boundary, focused tests lock the contract/manifest/constructor behavior, and no emitted HDL shape changes.`
  Verification: `perl -Iperl -c perl/FSM/Support/HDLGeneratorFacadeContract.pm; prove -Iperl t/375-hdl-generator-facade-contract.t t/414-hdl-generator-facade-constructor-option-name-boundary-audit.t t/439-hdl-generator-facade-contract-defensive-copy-boundary-audit.t t/297-capability-manifest.t; prove -Iperl t/815-capability-manifest-hdl-facade-identity-json-roundtrip-audit.t t/817-capability-manifest-hdl-facade-constructor-options-json-roundtrip-audit.t t/818-capability-manifest-hdl-facade-constructor-shapes-json-roundtrip-audit.t t/819-capability-manifest-hdl-facade-generation-boundary-json-roundtrip-audit.t t/820-capability-manifest-hdl-facade-linked-contracts-json-roundtrip-audit.t t/821-capability-manifest-hdl-facade-identity-defensive-copy-audit.t t/822-capability-manifest-hdl-facade-public-keys-defensive-copy-audit.t t/823-capability-manifest-hdl-facade-constructor-options-defensive-copy-audit.t t/824-capability-manifest-hdl-facade-constructor-shapes-defensive-copy-audit.t t/825-capability-manifest-hdl-facade-generation-boundary-defensive-copy-audit.t t/826-capability-manifest-hdl-facade-linked-contracts-defensive-copy-audit.t t/1089-hdl-generator-facade-contract-full-surface-json-roundtrip-audit.t t/1090-hdl-generator-facade-contract-full-surface-defensive-copy-audit.t t/358-capability-manifest-runtime-contract-audit.t; prove -Iperl t/386-hdl-generator-facade-target-language-boundary-audit.t; bash knowledge-map/scripts/check_knowledge_map.sh; scripts/check_memory_architecture.sh; prove -Iperl t/1414-docs-relative-paths-audit.t; prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t; mdbook build docs/book; git diff --check.`
  Commit: `this slice`

- ID: `BACKEND-API-VALIDATION-FRONTIER.7`
  Status: `done`
  Goal: `Freeze the next programmatic embedding API surface.`
  Children: `BACKEND-API-VALIDATION-FRONTIER.7.1`
  Acceptance: `Selected the JSON-safe generation-result snapshot as the next exact programmatic embedding API surface. The implementation owner is BACKEND-API-VALIDATION-FRONTIER.7.1: advertise FSM::Support::SerializableGenerationResultSnapshot directly under embedding.serializable_generation_result_snapshot while preserving the existing embedding.serializable_plan_reports nested reference and avoiding raw HDLGenerator result-object export.`
  Verification: `Selection audit/read: perl/FSM/Support/SerializableGenerationResultSnapshot.pm, perl/FSM/Support/SerializablePlanReportContract.pm, perl/FSM/Support/EmbeddingContract.pm, perl/FSM/Support/EmbeddingSection.pm, t/632-serializable-generation-result-snapshot.t, t/650-serializable-generation-result-snapshot-json-roundtrip-audit.t, t/641-serializable-generation-result-snapshot-defensive-copy-boundary-audit.t, t/297-capability-manifest.t, README.md, docs/book/src/11-extensions-and-embedding.md, and docs/book/src/14-feature-backlog.md. Evidence: the generation_result_snapshot builder and contract are already bounded public and JSON-safe, normalized semantic reports already embed the snapshot, README/book describe it for embedders, but embedding.section_contract currently exposes it only through the serializable_plan_reports branch rather than as a direct embedding child.`
  Commit: `this slice`

- ID: `BACKEND-API-VALIDATION-FRONTIER.7.1`
  Status: `done`
  Goal: `Advertise the JSON-safe generation-result snapshot as a direct embedding child contract.`
  Acceptance: `embedding.serializable_generation_result_snapshot appears in the capability manifest as the build_serializable_generation_result_snapshot_contract() payload. EmbeddingContract public/nested key lists, nested contract source map, and nested presence map include serializable_generation_result_snapshot with the snapshot's bounded public keys. Existing embedding.serializable_plan_reports.generation_result_snapshot_contract remains in place for compatibility. README/live docs/mdBook explain the direct embedding child. Focused tests cover embedding contract, manifest, JSON round-trip, defensive-copy, and existing snapshot behavior.`
  Verification: `perl -Iperl -c perl/FSM/Support/EmbeddingContract.pm; perl -Iperl -c perl/FSM/Support/EmbeddingSection.pm; perl -Iperl -c perl/FSM/Support/CapabilityManifestContract.pm; prove -Iperl t/321-embedding-contract.t t/297-capability-manifest.t t/358-capability-manifest-runtime-contract-audit.t t/366-embedding-section-runtime-contract-audit.t t/437-embedding-section-defensive-copy-boundary-audit.t t/845-capability-manifest-embedding-section-identity-json-roundtrip-audit.t t/846-capability-manifest-embedding-section-top-level-keys-json-roundtrip-audit.t t/847-capability-manifest-embedding-section-nested-source-map-json-roundtrip-audit.t t/848-capability-manifest-embedding-section-nested-presence-map-json-roundtrip-audit.t t/849-capability-manifest-embedding-section-flags-guidance-json-roundtrip-audit.t t/850-capability-manifest-embedding-section-identity-defensive-copy-audit.t t/851-capability-manifest-embedding-section-top-level-keys-defensive-copy-audit.t t/852-capability-manifest-embedding-section-nested-source-map-defensive-copy-audit.t t/853-capability-manifest-embedding-section-nested-presence-map-defensive-copy-audit.t t/854-capability-manifest-embedding-section-flags-guidance-defensive-copy-audit.t t/1061-embedding-contract-full-surface-json-roundtrip-audit.t t/1062-embedding-contract-full-surface-defensive-copy-audit.t t/632-serializable-generation-result-snapshot.t t/650-serializable-generation-result-snapshot-json-roundtrip-audit.t t/641-serializable-generation-result-snapshot-defensive-copy-boundary-audit.t t/629-serializable-plan-report-contract.t t/655-capability-manifest-serializable-plan-report-json-roundtrip-audit.t; prove -Iperl t/316-capability-manifest-contract.t t/370-capability-manifest-section-discovery-audit.t t/381-contract-tested-by-provenance-audit.t t/382-contract-module-provenance-audit.t t/383-contract-family-map-integrity-audit.t t/1131-isf-public-top-level-discovery-audit.t; bash knowledge-map/scripts/check_knowledge_map.sh; scripts/check_memory_architecture.sh; prove -Iperl t/1414-docs-relative-paths-audit.t; prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t; mdbook build docs/book; git diff --check`
  Commit: `this slice`

- ID: `BACKEND-API-VALIDATION-FRONTIER.8`
  Status: `active`
  Goal: `Broaden normalized semantic export.`
  Acceptance: `One exact normalized export field family is specified, implemented or deferred, documented, and regression-covered.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `BACKEND-API-VALIDATION-FRONTIER.1` | `done` | Backend/API tree activated after broad ISF/R14 exhaustion; selected first exact VHDL direct-root scaffold leaf. |
| 2 | `BACKEND-API-VALIDATION-FRONTIER.2.1` | `done` | Shipped direct single-FSM VHDL scaffold through an SV-first converter while preserving composition, aggregate, GHDL, and full-parity deferrals. |
| 3 | `BACKEND-API-VALIDATION-FRONTIER.3` | `done` | GHDL validation cannot run in the current environment because `ghdl` is unavailable; external-validation contracts/docs now say the lane remains SystemVerilog-only until a future GHDL validation leaf is runnable. |
| 4 | `BACKEND-API-VALIDATION-FRONTIER.4.1` | `done` | Added the already warning-clean historical `fsm/trial_0.fsm` sample to the external SystemVerilog validation smoke; deferred `apb_tb` and `trial_2` to exact future owners based on probe failures. |
| 5 | `BACKEND-API-VALIDATION-FRONTIER.4.2` | `done` | Added warning-clean `fsm/mipicsi2_configreg.fsm` and `fsm/mipicsi2_fifo_4x8.fsm` to the external SystemVerilog validation smoke; deferred `generic_fifo` and `lte_digital_rf` based on probe failures. |
| 6 | `BACKEND-API-VALIDATION-FRONTIER.4.3` | `done` | Added the remaining warning-clean current MIPI samples under `fsm/` to the external SystemVerilog validation smoke. |
| 7 | `BACKEND-API-VALIDATION-FRONTIER.4.4` | `done` | Selected `fsm/apb_tb.fsm` as the next exact blocked historical validation target and created `.4.4.1` as its owner leaf. |
| 8 | `BACKEND-API-VALIDATION-FRONTIER.4.4.1` | `done` | Fixed APB composition PINMISSING warnings by binding unused generated-child shared-datapath export ports to deterministic sink wires, then added `apb_tb` to the external validation smoke. |
| 9 | `BACKEND-API-VALIDATION-FRONTIER.4.5` | `done` | Selected `fsm/trial_2.fsm` as the next exact blocked historical validation target. |
| 10 | `BACKEND-API-VALIDATION-FRONTIER.4.5.1` | `done` | Explicitly deferred `fsm/trial_2.fsm` as a regression-backed expected failure at the legacy `?ports` mapping boundary. |
| 11 | `BACKEND-API-VALIDATION-FRONTIER.4.6` | `done` | Selected `fsm/generic_fifo.fsm` as the next exact blocked historical validation target. |
| 12 | `BACKEND-API-VALIDATION-FRONTIER.4.6.1` | `done` | Explicitly deferred `fsm/generic_fifo.fsm` as a regression-backed expected failure at the legacy `?define` template boundary. |
| 13 | `BACKEND-API-VALIDATION-FRONTIER.4.7` | `done` | Explicitly deferred `fsm/lte_digital_rf.fsm` as a regression-backed expected failure at the legacy multi-module `?rtl` composition boundary. |
| 14 | `BACKEND-API-VALIDATION-FRONTIER.5` | `done` | Selected optional ABC executable discovery as the exact ABC hardening edge while preserving the ABC-free validation gate. |
| 15 | `BACKEND-API-VALIDATION-FRONTIER.5.1` | `done` | Reported optional ABC mapping tool availability in contracts/support surfaces without enabling or requiring ABC. |
| 16 | `BACKEND-API-VALIDATION-FRONTIER.6` | `done` | Selected the flattened-default generation-mode contract boundary as the exact structured/non-flattened generation edge. |
| 17 | `BACKEND-API-VALIDATION-FRONTIER.6.1` | `done` | Published the flattened-default generation-mode boundary without adding a non-flattened backend path. |
| 18 | `BACKEND-API-VALIDATION-FRONTIER.7` | `done` | Selected the JSON-safe generation-result snapshot as the next exact programmatic embedding API surface. |
| 19 | `BACKEND-API-VALIDATION-FRONTIER.7.1` | `done` | Advertised the JSON-safe generation-result snapshot as a direct embedding child contract while keeping raw `HDLGenerator` objects non-public and preserving the nested `serializable_plan_reports` reference. |
| 20 | `BACKEND-API-VALIDATION-FRONTIER.8` | `active` | Broaden normalized semantic export by selecting the next exact export field family. |

## Decisions

- `2026-06-05`: Activated after `ISF-REMAINING-BROAD-FRONTIER` exhausted. Select
  VHDL as the first backend/API lane because it is first in the book backlog,
  unblocks GHDL and VHDL composition work, and `docs/VHDL_SCOPE.md` already
  defines a narrow direct-root SV-first conversion scaffold.

## Open Questions

- None.

## Blockers

- GHDL validation is blocked in the current environment by local tool
  availability; `command -v ghdl` returned unavailable during `.2.1` and `.3`.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- |
| `2026-06-05` | `BACKEND-API-VALIDATION-FRONTIER.1` | Selection audit/read: `docs/TASK_TREE.md`, `docs/book/src/14-feature-backlog.md`, `docs/VHDL_SCOPE.md`, `docs/tasks/COMPOSITION-TYPE-BACKLOG-EXHAUSTION.md`, `README.md`, `perl/FSM/HDL/FlattenedDT.pm`, `perl/FSM/HDL/FlattenedDT/Backend/Verilog.pm`, `t/386-hdl-generator-facade-target-language-boundary-audit.t`, and `t/114-composition-target-support-diagnostics.t`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git diff --check` | `PASS` |
| `2026-06-05` | `BACKEND-API-VALIDATION-FRONTIER.2.1` | `perl -Iperl -c perl/FSM/HDL/FlattenedDT.pm`; `perl -Iperl -c perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm`; `prove -Iperl t/1420-vhdl-direct-backend-scaffold.t t/386-hdl-generator-facade-target-language-boundary-audit.t t/114-composition-target-support-diagnostics.t t/404-hdl-generator-facade-target-language-shape-boundary-audit.t`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `git diff --check`; `command -v ghdl` | `PASS`; `ghdl` unavailable and remains deferred |
| `2026-06-05` | `BACKEND-API-VALIDATION-FRONTIER.3` | `perl -Iperl -c perl/FSM/Support/HDLExternalValidationContract.pm`; `prove -Iperl t/313-hdl-external-validation-contract.t t/1057-hdl-external-validation-contract-full-surface-json-roundtrip-audit.t t/1058-hdl-external-validation-contract-full-surface-defensive-copy-audit.t t/297-capability-manifest.t t/308-systemverilog-external-validation.t`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `git diff --check`; `command -v ghdl` | `PASS`; `ghdl` unavailable and GHDL validation remains deferred |
| `2026-06-05` | `BACKEND-API-VALIDATION-FRONTIER.4.1` | `./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_trial_0_verify.sv fsm/trial_0.fsm`; `prove -Iperl t/308-systemverilog-external-validation.t`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `git diff --check`; selection probes for `fsm/apb_tb.fsm` and `fsm/trial_2.fsm`; removed `/tmp/fsmgen_*_verify.sv` probe artifacts | `PASS`; `apb_tb` and `trial_2` deferred to exact future owners |
| `2026-06-05` | `BACKEND-API-VALIDATION-FRONTIER.4.2` | `./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_mipicsi2_configreg_verify.sv fsm/mipicsi2_configreg.fsm`; `./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_mipicsi2_fifo_4x8_verify.sv fsm/mipicsi2_fifo_4x8.fsm`; `prove -Iperl t/308-systemverilog-external-validation.t`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `git diff --check`; selection probes for `fsm/generic_fifo.fsm` and `fsm/lte_digital_rf.fsm`; removed `/tmp/fsmgen_*_verify.sv` probe artifacts | `PASS`; `generic_fifo` and `lte_digital_rf` deferred to exact future owners |
| `2026-06-05` | `BACKEND-API-VALIDATION-FRONTIER.4.3` | Probe `--verify-hdl` commands for remaining MIPI samples: `mipicsi2_laned_clog`, `mipicsi2_laned_sctrl`, `mipicsi2_rxccore_hs`, `mipicsi2_rxdcore_hs`, `mipicsi2_txccore_hs`, `mipicsi2_txccore_ulp`, `mipicsi2_txdcore_hs`, `mipicsi2_txdcore_lp`, `mipicsi2_xgamaster`; `prove -Iperl t/308-systemverilog-external-validation.t`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `git diff --check`; removed `/tmp/fsmgen_*_verify.sv` probe artifacts | `PASS` |
| `2026-06-05` | `BACKEND-API-VALIDATION-FRONTIER.4.4` | `./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_apb_tb_verify.sv fsm/apb_tb.fsm`; code/read selection audit of `fsm/apb_tb.fsm`, `perl/FSM/Composition/GeneratedChildRealizer.pm`, `perl/FSM/Composition/InterfacePortBuilder.pm`, `perl/FSM/Composition/SharedDatapathSupport.pm`, `perl/FSM/Composition/LinkedPlanBuilder.pm`, and `perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git diff --check` | `PASS`; expected probe failure selected `apb_tb` for `.4.4.1` |
| `2026-06-05` | `BACKEND-API-VALIDATION-FRONTIER.4.4.1` | `perl -Iperl -c perl/FSM/Composition/SharedDatapathSupport.pm`; `prove -Iperl t/247-protocol-fixture-regression-smoke.t`; `./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_apb_tb_verify.sv fsm/apb_tb.fsm`; `prove -Iperl t/146-composition-shared-datapath-lifted-register-runtime.t t/147-composition-shared-datapath-internal-lifted-register-runtime.t`; `prove -Iperl t/308-systemverilog-external-validation.t`; APB-adjacent 21-file contract/snapshot suite (`t/248`, `t/296`, `t/302`, `t/305`, `t/306`, `t/307`, `t/311`, `t/312`, `t/314`, `t/353`, `t/354`, `t/355`, `t/631`, `t/632`, `t/633`, `t/643`, `t/644`, `t/651`, `t/652`, `t/663`, `t/664`); `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `git diff --check` | `PASS` |
| `2026-06-05` | `BACKEND-API-VALIDATION-FRONTIER.4.5` | Selection probes for `fsm/trial_2.fsm`, `fsm/generic_fifo.fsm`, and `fsm/lte_digital_rf.fsm`; code/read audit of `perl/FSM/Composition/Parser.pm` rejection points; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git diff --check` | `PASS`; selected `trial_2` for `.4.5.1` |
| `2026-06-05` | `BACKEND-API-VALIDATION-FRONTIER.4.5.1` | `./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_trial_2_verify.sv fsm/trial_2.fsm` expected-failure probe; `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `prove -Iperl t/248-regression-corpus-accounting.t t/249-regression-corpus-classified-behavior.t t/300-check-json-regression-corpus.t t/304-normalized-semantic-json-regression-corpus.t t/127-composition-ports-mapping-diagnostics.t`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `git diff --check` | `PASS`; `trial_2` deferred as an expected-failure corpus boundary |
| `2026-06-05` | `BACKEND-API-VALIDATION-FRONTIER.4.6` | Selection probes for `fsm/generic_fifo.fsm` and `fsm/lte_digital_rf.fsm`; `wc -l fsm/generic_fifo.fsm fsm/lte_digital_rf.fsm`; read leading source shapes for both files; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git diff --check` | `PASS`; selected `generic_fifo` for `.4.6.1` |
| `2026-06-05` | `BACKEND-API-VALIDATION-FRONTIER.4.6.1` | `./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_generic_fifo_verify.sv fsm/generic_fifo.fsm` expected-failure probe; `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `prove -Iperl t/248-regression-corpus-accounting.t t/249-regression-corpus-classified-behavior.t t/300-check-json-regression-corpus.t t/304-normalized-semantic-json-regression-corpus.t t/41-language-contract-top-level-source-kind-boundary.t`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `git diff --check` | `PASS`; `generic_fifo` deferred as an expected-failure corpus boundary |
| `2026-06-05` | `BACKEND-API-VALIDATION-FRONTIER.4.7` | `./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_lte_digital_rf_verify.sv fsm/lte_digital_rf.fsm` expected-failure probe; `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `prove -Iperl t/248-regression-corpus-accounting.t t/249-regression-corpus-classified-behavior.t t/300-check-json-regression-corpus.t t/304-normalized-semantic-json-regression-corpus.t`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `git diff --check` | `PASS`; `lte_digital_rf` deferred as an expected-failure corpus boundary; `.4` exhausted |
| `2026-06-05` | `BACKEND-API-VALIDATION-FRONTIER.5` | Selection audit/read of the external validation support, contract, manifest, smoke test, README, regression-corpus docs, SPECFORGE response, and mdBook ABC backlog/debugging sections; local tool probes for `yosys`, `yosys-abc`, `berkeley-abc`, and `abc`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git diff --check` | `PASS`; selected optional ABC executable discovery for `.5.1` |
| `2026-06-05` | `BACKEND-API-VALIDATION-FRONTIER.5.1` | `perl -Iperl -c perl/FSM/Support/HDLExternalValidation.pm`; `perl -Iperl -c perl/FSM/Support/HDLExternalValidationContract.pm`; `prove -Iperl t/313-hdl-external-validation-contract.t t/297-capability-manifest.t`; `prove -Iperl t/308-systemverilog-external-validation.t`; `prove -Iperl t/460-hdl-external-validation-contract-defensive-copy-boundary-audit.t t/1057-hdl-external-validation-contract-full-surface-json-roundtrip-audit.t t/1058-hdl-external-validation-contract-full-surface-defensive-copy-audit.t t/323-backend-validation-contract.t`; `prove -Iperl t/365-backend-validation-section-runtime-contract-audit.t t/358-capability-manifest-runtime-contract-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `git diff --check` | `PASS`; optional ABC discovery is now reported without enabling or requiring ABC |
| `2026-06-05` | `BACKEND-API-VALIDATION-FRONTIER.6` | Selection audit/read of `docs/book/src/01-first-fsm.md`, `docs/book/src/09-generated-hdl-debugging-and-inspection.md`, `docs/book/src/14-feature-backlog.md`, `perl/FSM/Backend/GeneratedModuleEmitter.pm`, `perl/FSM/Pipeline/HDLGenerator.pm`, `perl/FSM/Support/HDLGeneratorFacadeContract.pm`, `t/375-hdl-generator-facade-contract.t`, `t/414-hdl-generator-facade-constructor-option-name-boundary-audit.t`, `t/297-capability-manifest.t`, and `t/439-hdl-generator-facade-contract-defensive-copy-boundary-audit.t`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git diff --check` | `PASS`; selected flattened-default generation-mode contract boundary for `.6.1` |
| `2026-06-05` | `BACKEND-API-VALIDATION-FRONTIER.6.1` | `perl -Iperl -c perl/FSM/Support/HDLGeneratorFacadeContract.pm`; `prove -Iperl t/375-hdl-generator-facade-contract.t t/414-hdl-generator-facade-constructor-option-name-boundary-audit.t t/439-hdl-generator-facade-contract-defensive-copy-boundary-audit.t t/297-capability-manifest.t`; facade manifest JSON/defensive-copy audit suite (`t/815`, `t/817`, `t/818`, `t/819`, `t/820`, `t/821`, `t/822`, `t/823`, `t/824`, `t/825`, `t/826`, `t/1089`, `t/1090`, `t/358`); `prove -Iperl t/386-hdl-generator-facade-target-language-boundary-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `git diff --check` | `PASS`; flattened generation mode is now contract/manifest-visible and `generation_mode` remains rejected |
| `2026-06-05` | `BACKEND-API-VALIDATION-FRONTIER.7` | Selection audit/read of `perl/FSM/Support/SerializableGenerationResultSnapshot.pm`, `perl/FSM/Support/SerializablePlanReportContract.pm`, `perl/FSM/Support/EmbeddingContract.pm`, `perl/FSM/Support/EmbeddingSection.pm`, `t/632-serializable-generation-result-snapshot.t`, `t/650-serializable-generation-result-snapshot-json-roundtrip-audit.t`, `t/641-serializable-generation-result-snapshot-defensive-copy-boundary-audit.t`, `t/297-capability-manifest.t`, `README.md`, `docs/book/src/11-extensions-and-embedding.md`, and `docs/book/src/14-feature-backlog.md`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git diff --check` | `PASS`; selected direct embedding child advertisement for `generation_result_snapshot` |
| `2026-06-05` | `BACKEND-API-VALIDATION-FRONTIER.7.1` | `perl -Iperl -c perl/FSM/Support/EmbeddingContract.pm`; `perl -Iperl -c perl/FSM/Support/EmbeddingSection.pm`; `perl -Iperl -c perl/FSM/Support/CapabilityManifestContract.pm`; focused embedding/manifest/snapshot suite (`t/321`, `t/297`, `t/358`, `t/366`, `t/437`, `t/845`-`t/854`, `t/1061`, `t/1062`, `t/632`, `t/650`, `t/641`, `t/629`, `t/655`); manifest-shell/provenance/family-map audit suite (`t/316`, `t/370`, `t/381`, `t/382`, `t/383`, `t/1131`); `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `git diff --check` | `PASS`; advertised `embedding.serializable_generation_result_snapshot` as a direct manifest child while preserving nested plan/report compatibility |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `BACKEND-API-VALIDATION-FRONTIER.1` | `BACKEND-API-VALIDATION-FRONTIER.1: select VHDL direct scaffold` | selected `.2.1` |
| `BACKEND-API-VALIDATION-FRONTIER.2.1` | `BACKEND-API-VALIDATION-FRONTIER.2.1: ship VHDL direct scaffold` | shipped direct VHDL scaffold |
| `BACKEND-API-VALIDATION-FRONTIER.3` | `BACKEND-API-VALIDATION-FRONTIER.3: keep GHDL validation deferred` | kept GHDL deferred |
| `BACKEND-API-VALIDATION-FRONTIER.4.1` | `BACKEND-API-VALIDATION-FRONTIER.4.1: add trial_0 validation smoke` | added trial_0 smoke |
| `BACKEND-API-VALIDATION-FRONTIER.4.2` | `BACKEND-API-VALIDATION-FRONTIER.4.2: add MIPI config fifo validation smoke` | added config/fifo MIPI smoke |
| `BACKEND-API-VALIDATION-FRONTIER.4.3` | `BACKEND-API-VALIDATION-FRONTIER.4.3: add remaining MIPI validation smoke` | this slice |
| `BACKEND-API-VALIDATION-FRONTIER.4.4` | `BACKEND-API-VALIDATION-FRONTIER.4.4: select apb_tb validation target` | selected `.4.4.1` |
| `BACKEND-API-VALIDATION-FRONTIER.4.4.1` | `BACKEND-API-VALIDATION-FRONTIER.4.4.1: add apb_tb validation smoke` | this slice |
| `BACKEND-API-VALIDATION-FRONTIER.4.5` | `BACKEND-API-VALIDATION-FRONTIER.4.5: select trial_2 validation target` | selected `.4.5.1` |
| `BACKEND-API-VALIDATION-FRONTIER.4.5.1` | `BACKEND-API-VALIDATION-FRONTIER.4.5.1: defer trial_2 ports mapping` | this slice |
| `BACKEND-API-VALIDATION-FRONTIER.4.6` | `BACKEND-API-VALIDATION-FRONTIER.4.6: select generic_fifo validation target` | this slice |
| `BACKEND-API-VALIDATION-FRONTIER.4.6.1` | `BACKEND-API-VALIDATION-FRONTIER.4.6.1: defer generic_fifo template root` | this slice |
| `BACKEND-API-VALIDATION-FRONTIER.4.7` | `BACKEND-API-VALIDATION-FRONTIER.4.7: defer lte_digital_rf rtl child count` | this slice |
| `BACKEND-API-VALIDATION-FRONTIER.5` | `BACKEND-API-VALIDATION-FRONTIER.5: select ABC discovery edge` | selected `.5.1` |
| `BACKEND-API-VALIDATION-FRONTIER.5.1` | `BACKEND-API-VALIDATION-FRONTIER.5.1: report optional ABC discovery` | this slice |
| `BACKEND-API-VALIDATION-FRONTIER.6` | `BACKEND-API-VALIDATION-FRONTIER.6: select flattened mode boundary` | selected `.6.1` |
| `BACKEND-API-VALIDATION-FRONTIER.6.1` | `BACKEND-API-VALIDATION-FRONTIER.6.1: publish flattened mode contract` | this slice |
| `BACKEND-API-VALIDATION-FRONTIER.7` | `BACKEND-API-VALIDATION-FRONTIER.7: select generation snapshot API` | selected `.7.1` |
| `BACKEND-API-VALIDATION-FRONTIER.7.1` | `BACKEND-API-VALIDATION-FRONTIER.7.1: advertise generation snapshot child` | this slice |

## Changelog

- `2026-06-05`: Created proposed backend/API frontier owner tree.
- `2026-06-05`: Activated the tree and selected `.2.1`, the first direct-root
  VHDL backend scaffold through an SV-first converter, before backend code
  changes.
- `2026-06-05`: Shipped `.2.1`, the first direct single-FSM VHDL scaffold,
  and moved the next frontier to `.3` for GHDL validation selection/blocking.
- `2026-06-05`: Completed `.3`; `ghdl` is unavailable in the current
  environment, so no GHDL validation lane was advertised and the
  external-validation contract/docs now state the current SystemVerilog-only
  boundary.
- `2026-06-05`: Activated `.4.1` for `fsm/trial_0.fsm` external-validation
  smoke coverage after probes showed `trial_0` passes, while `apb_tb` and
  `trial_2` require separate future owner leaves.
- `2026-06-05`: Completed `.4.1`; the external validation smoke now includes
  `fsm/trial_0.fsm` and the warning-clean frontier continues at `.4.2`.
- `2026-06-05`: Activated `.4.2` for `fsm/mipicsi2_configreg.fsm` and
  `fsm/mipicsi2_fifo_4x8.fsm` after probes showed both pass; `generic_fifo`
  and `lte_digital_rf` require separate future owner leaves.
- `2026-06-05`: Completed `.4.2`; the external validation smoke now includes
  `fsm/mipicsi2_configreg.fsm` and `fsm/mipicsi2_fifo_4x8.fsm`, and the
  warning-clean frontier continues at `.4.3`.
- `2026-06-05`: Activated `.4.3` after probes showed all remaining MIPI
  direct samples under `fsm/` pass external SystemVerilog validation.
- `2026-06-05`: Completed `.4.3`; every current MIPI sample under `fsm/` is
  now in the external validation smoke, and blocked historical targets remain
  for `.4.4` selection.
- `2026-06-05`: Completed `.4.4`; selected `fsm/apb_tb.fsm` as the next
  exact blocked historical validation target and activated `.4.4.1` for the
  generated-child shared-datapath export-port binding fix.
- `2026-06-05`: Completed `.4.4.1`; generated-child shared-datapath export
  pins now bind to deterministic sink wires when unused, `fsm/apb_tb.fsm`
  passes external SystemVerilog validation, and `.4.5` is the next blocked
  historical validation target selection leaf.
- `2026-06-05`: Completed `.4.5`; selected `fsm/trial_2.fsm` for the next
  exact blocked historical validation target because its first failure is the
  bounded legacy `?ports` mapping boundary, while `generic_fifo` and
  `lte_digital_rf` remain broader legacy template/multi-RTL frontiers.
- `2026-06-05`: Completed `.4.5.1`; `fsm/trial_2.fsm` now has an explicit
  expected-failure corpus entry, stable diagnostic accounting, mdBook coverage,
  and a knowledge-map fact card at the legacy `?ports` mapping boundary. The
  warning-clean historical validation frontier continues at `.4.6` selection.
- `2026-06-05`: Completed `.4.6`; selected `fsm/generic_fifo.fsm` as the next
  exact blocked historical validation target because it is the smaller
  remaining candidate and fails first on the unsupported `?define` / `?&`
  template surface. `fsm/lte_digital_rf.fsm` remains deferred behind the
  broader legacy multi-module `?rtl` boundary.
- `2026-06-05`: Completed `.4.6.1`; `fsm/generic_fifo.fsm` now has an
  explicit expected-failure corpus entry, stable diagnostic accounting, mdBook
  coverage, and a knowledge-map fact card at the unsupported `?define` root
  boundary. The historical validation frontier continues at `.4.7` for
  `fsm/lte_digital_rf.fsm`.
- `2026-06-05`: Completed `.4.7`; `fsm/lte_digital_rf.fsm` now has an explicit
  expected-failure corpus entry, stable diagnostic accounting, mdBook coverage,
  and a knowledge-map fact card at the multi-module `?rtl` boundary. The
  historical external-validation frontier `.4` is exhausted and the active
  frontier moves to `.5` for ABC mapping behavior.
- `2026-06-05`: Completed `.5`; selected optional ABC executable discovery as
  the exact ABC mapping hardening edge because local probes show `yosys-abc`
  is installed while the current validation contract still intentionally uses
  `synth -noabc` and advertises `yosys_abc_enabled` as false. Activated
  `.5.1` to expose the required-tool versus optional-ABC distinction without
  enabling or requiring ABC.
- `2026-06-05`: Completed `.5.1`; external validation now reports optional
  ABC mapping executable discovery while keeping the required validation tools
  limited to Verilator and Yosys and keeping the validation command sequence
  ABC-free. The active frontier moves to `.6` for structured/non-flattened
  generation selection.
- `2026-06-05`: Completed `.6`; selected the flattened-default generation-mode
  contract boundary as the first structured/non-flattened generation edge
  because the current backend still drives `FSM::HDL::FlattenedDT`, the facade
  exposes no `generation_mode` constructor option, and the book already states
  that flattened generation is the intentional shipped default. Activated
  `.6.1` to publish that boundary without adding a non-flattened backend path.
- `2026-06-05`: Completed `.6.1`; `embedding.hdl_generator_facade` now
  advertises `flattened_debug_first` generation metadata while `generation_mode`
  remains non-public and rejected. The structured/non-flattened generation
  frontier is exhausted for this exact edge, and the active frontier moves to
  `.7` for programmatic embedding API surface selection.
- `2026-06-05`: Completed `.7`; selected the JSON-safe generation-result
  snapshot as the next exact programmatic embedding API surface because the
  snapshot builder/contract is already bounded public and JSON-safe, but the
  embedding manifest currently exposes it only indirectly through
  `serializable_plan_reports`. Activated `.7.1` to advertise it as a direct
  embedding child without exporting raw `HDLGenerator` internals.
- `2026-06-05`: Completed `.7.1`; the capability manifest now advertises
  `embedding.serializable_generation_result_snapshot` as the direct JSON-safe
  generation-result snapshot child, keeps the nested
  `embedding.serializable_plan_reports.generation_result_snapshot_contract`
  reference for compatibility, and moves the active frontier to `.8` for
  normalized semantic export selection.
