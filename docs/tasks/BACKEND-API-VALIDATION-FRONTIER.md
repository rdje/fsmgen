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
    `BACKEND-API-VALIDATION-FRONTIER.5`,
    `BACKEND-API-VALIDATION-FRONTIER.6`,
    `BACKEND-API-VALIDATION-FRONTIER.7`,
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
  Status: `active`
  Goal: `Drive warning-clean external validation across historical samples.`
  Children: `BACKEND-API-VALIDATION-FRONTIER.4.1`,
    `BACKEND-API-VALIDATION-FRONTIER.4.2`
  Acceptance: `One exact historical sample family or tool gate is selected, cleaned or deferred, documented, and covered.`
  Verification: `BACKEND-API-VALIDATION-FRONTIER.4.1 added fsm/trial_0.fsm to the external SystemVerilog validation smoke; further warning-clean work remains active under .4.2.`
  Commit: `pending`

- ID: `BACKEND-API-VALIDATION-FRONTIER.4.1`
  Status: `done`
  Goal: `Add the already warning-clean historical trial_0 sample to the external SystemVerilog validation smoke.`
  Acceptance: `t/308-systemverilog-external-validation.t validates fsm/trial_0.fsm through the existing Verilator lint plus ABC-free Yosys synthesis lane when tools are installed. docs/REGRESSION_CORPUS.md and the mdBook generated-HDL debugging chapter list trial_0 in the focused external-validation smoke. Broader historical samples such as composition apb_tb and legacy-composition trial_2 remain deferred behind their own exact owner leaves because probe runs showed PINMISSING composition wiring warnings and legacy mapping rejection respectively.`
  Verification: `./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_trial_0_verify.sv fsm/trial_0.fsm; prove -Iperl t/308-systemverilog-external-validation.t; scripts/check_memory_architecture.sh; bash knowledge-map/scripts/check_knowledge_map.sh; prove -Iperl t/1414-docs-relative-paths-audit.t; prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t; mdbook build docs/book; git diff --check. Selection probes: ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_apb_tb_verify.sv fsm/apb_tb.fsm failed on Verilator PINMISSING composition child pins; ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_trial_2_verify.sv fsm/trial_2.fsm failed on legacy composition ?ports mapping. Temporary /tmp probe outputs were removed.`
  Commit: `this slice`

- ID: `BACKEND-API-VALIDATION-FRONTIER.4.2`
  Status: `pending`
  Goal: `Select the next exact warning-clean historical validation target after trial_0.`
  Acceptance: `Probe remaining candidate samples or tool gates, document the next exact owner leaf, and do not change validation code until the selected target has leaf-level ownership.`
  Verification: `pending`
  Commit: `pending`

- ID: `BACKEND-API-VALIDATION-FRONTIER.5`
  Status: `pending`
  Goal: `Harden ABC mapping behavior.`
  Acceptance: `One exact ABC mapping edge is selected, implemented or deferred, documented, and covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `BACKEND-API-VALIDATION-FRONTIER.6`
  Status: `pending`
  Goal: `Broaden structured non-flattened generation.`
  Acceptance: `One exact non-flattened generation surface is selected, implemented or deferred, documented, and covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `BACKEND-API-VALIDATION-FRONTIER.7`
  Status: `pending`
  Goal: `Freeze the next programmatic embedding API surface.`
  Acceptance: `One exact embedding API surface is specified, implemented or deferred, documented, and regression-covered without exporting unstable internals.`
  Verification: `pending`
  Commit: `pending`

- ID: `BACKEND-API-VALIDATION-FRONTIER.8`
  Status: `pending`
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
| 5 | `BACKEND-API-VALIDATION-FRONTIER.4.2` | `pending` | Select the next exact warning-clean historical validation target after `trial_0`. |

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

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `BACKEND-API-VALIDATION-FRONTIER.1` | `BACKEND-API-VALIDATION-FRONTIER.1: select VHDL direct scaffold` | selected `.2.1` |
| `BACKEND-API-VALIDATION-FRONTIER.2.1` | `BACKEND-API-VALIDATION-FRONTIER.2.1: ship VHDL direct scaffold` | shipped direct VHDL scaffold |
| `BACKEND-API-VALIDATION-FRONTIER.3` | `BACKEND-API-VALIDATION-FRONTIER.3: keep GHDL validation deferred` | this slice |
| `BACKEND-API-VALIDATION-FRONTIER.4.1` | `BACKEND-API-VALIDATION-FRONTIER.4.1: add trial_0 validation smoke` | this slice |

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
