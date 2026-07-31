---
id: vial-public-tooling-v1-contract
title: VIAL public tooling uses intent commands, equivalent source views, and atomic local artifacts
answers:
  - "what public VIAL command is selected?"
  - "how will I check or format a VIAL file?"
  - "how will I bind VIAL to a HIAL DUT?"
  - "what is the difference between terse and normal VIAL?"
  - "does terse VIAL change semantics?"
  - "what does fsmgen vial plan write?"
  - "where do VIAL artifacts live?"
  - "what is the VIAL public in-memory API?"
  - "does the VIAL API expose SemanticIR or ExecutionIR?"
  - "what happens to verification-output-manifest version 1?"
  - "is the public VIAL CLI implemented yet?"
  - "what is the next HIAL VIAL task?"
date: 2026-07-31
status: current
tags: [vial, public-tooling, cli, api, terse, normal-form, artifacts, manifests, data-locality, compatibility]
evidence: docs/VIAL_PUBLIC_TOOLING_V1_CONTRACT.md; perl/FSM/VIAL/SourceProjection.pm; perl/FSM/VIAL/Tool.pm; perl/FSM/VIAL/ToolCLI.pm; perl/FSM/VIAL/PlanBuilder.pm; perl/FSM/VIAL/ArtifactTransaction.pm; perl/FSM/VIAL/Backend/SVPortableVerilator.pm; perl/FSM/VIAL/Backend/Runner.pm; perl/FSM/VIAL/Backend/TraceValidator.pm; perl/FSM/VIAL/Backend/ResultProducer.pm; perl/FSM/VIAL/Parity/AHBBaseOutput.pm; perl/FSM/Support/VIALToolingContract.pm; t/1555-vial-public-source-tooling.t; t/1556-vial-public-planning-artifacts.t; t/1557-vial-portable-sv-backend-emission.t; t/1558-vial-verilator-run-integration.t; t/1559-vial-ahb-runtime-parity.t; docs/VIAL_PORTABLE_SYSTEMVERILOG_BACKEND_V1_CONTRACT.md; docs/decisions/0039-vial-public-tooling-is-intent-oriented-and-artifact-atomic.md; docs/decisions/0043-vial-portable-systemverilog-is-a-deterministic-known-value-profile.md; docs/VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md; docs/VIAL_EXECUTION_IR_V1_CONTRACT.md; docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; docs/book/src/16d-hial-vial-verification-architecture.md; ROADMAP_V2.md
reverify: ./bin/fsmgen vial capabilities --json && ./bin/fsmgen vial check vial/ahb_subordinate_base_output_arbitration.vial && prove -Iperl t/1555-vial-public-source-tooling.t t/1556-vial-public-planning-artifacts.t t/1557-vial-portable-sv-backend-emission.t t/1558-vial-verilator-run-integration.t t/1559-vial-ahb-runtime-parity.t
---

Decision `0039` selects `fsmgen vial capabilities|check|format|plan|run` as the
public tool family. `plan` takes separate `.vial` and `--dut` HIAL sources; the
DUT follows direct IAL0, direct IAL1, or IAL2 only through generated/reparsed
IAL1 and generated IAL0 review routes. Private SemanticIR, bridge objects, and
ExecutionIR never cross the public boundary.

`normal_v1` is the fully explicit current source shape. `terse_v1` removes only
the selected version/declaration-section/scenario wrappers. It cannot infer a
type, value, clock, timeout, seed, binding, event, or target behavior. Both
forms must format/reparse to the same provenance-excluding semantic meaning
digest; source hashes and spans remain distinct.

The portable API uses closed `fsmgen.vial_tool_request.v1` and
`fsmgen.vial_tool_result.v1` records. Completed `.10.1` ships capabilities,
check, and normal/terse format over caller-owned source text and source
catalogs. Completed `.10.2` adds defensive public planning and an ordered
virtual artifact sink without callbacks, filehandles, private objects, or host
paths. The filesystem CLI accepts only repository-root-relative, non-symlink,
same-volume inputs and atomically publishes that same graph.

Shipped filesystem `plan` output defaults below
`.artifacts/vial/<fixture>/<full-plan-digest>/`, stays repository-local and
same-volume, and atomically publishes canonical normal source, generated HIAL
review artifacts, sanitized bridge/plan projections, and a tool manifest.
Direct IAL0 can bind a transaction-free endpoint fixture; transaction-bearing
fixtures require matching reviewed IAL1/IAL2 transaction truth. Identical
trees return `unchanged`; non-identical or unsafe trees are never overwritten.

Existing `.isf` verification-output-manifest v1 skeleton output remains
unchanged. Shipped VIAL `run` uses explicit
`fsmgen.verification_output_manifest.v2`; consumers select by schema, not
filename. Decision `0043` now selects the first plain-SystemVerilog/Verilator
backend contract. Clean commit `ab3e73b72` activates `.10` as the first
implementation owner; clean activation commit `5fd766600` decomposes it.
Completed `.10.1` ships the source-only command/API and five exact public
capabilities. Completed `.10.2` ships `plan`, the artifact-layout/tool-manifest
capabilities, and distinct public-plan support accounting. Completed `.10.3`
ships deterministic portable-SystemVerilog emission and pure trace validation
through a private compiler API. Completed `.10.4` adds public `run`, exact
Verilator 5.046 qualification/execution, backend/result/output artifacts,
validated runtime capture, deterministic reruns, and atomic cleanup. `.11`
now ships bounded AHB handwritten-oracle parity as discovery evidence without
adding a public action or ordinary-run artifact. General parity is unclaimed.
