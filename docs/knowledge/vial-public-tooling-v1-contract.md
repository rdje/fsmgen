---
id: vial-public-tooling-v1-contract
title: VIAL public tooling uses intent commands, equivalent source views, and atomic local artifacts
answers:
  - "what public VIAL command is selected?"
  - "how will I check or format a VIAL file?"
  - "how will I bind VIAL to a HIAL DUT?"
  - "what is the difference between terse and normal VIAL?"
  - "does terse VIAL change semantics?"
  - "why did different VIAL model instances or fault targets share a semantic digest?"
  - "what does fsmgen vial plan write?"
  - "where do VIAL artifacts live?"
  - "what is the VIAL public in-memory API?"
  - "does the VIAL API expose SemanticIR or ExecutionIR?"
  - "what happens to verification-output-manifest version 1?"
  - "is the public VIAL CLI implemented yet?"
  - "what is the next HIAL VIAL task?"
  - "where is the public VIAL source to result lifecycle documented?"
  - "how do I use the public VIAL CLI and API?"
  - "what does a VIAL plan or run publish?"
  - "how does failed VIAL artifact publication clean up?"
date: 2026-09-24
status: current
tags: [vial, public-tooling, cli, api, terse, normal-form, artifacts, manifests, data-locality, compatibility]
evidence: >-
  t/1874-vial-fault-target-applicability.t; t/1873-vial-fault-target-identity.t; t/1872-vial-model-reference-identity.t; t/1870-vial-filesystem-source-query.t; perl/FSM/Support/SemanticIntrospectionContract.pm;
  docs/VIAL_PUBLIC_TOOLING_V1_CONTRACT.md; perl/FSM/VIAL/SourceProjection.pm; perl/FSM/VIAL/Tool.pm; perl/FSM/VIAL/ToolCLI.pm; perl/FSM/VIAL/PlanBuilder.pm; perl/FSM/VIAL/ArtifactTransaction.pm; perl/FSM/VIAL/Backend/SVPortableVerilator.pm; perl/FSM/VIAL/Backend/Runner.pm; perl/FSM/VIAL/Backend/TraceValidator.pm; perl/FSM/VIAL/Backend/ResultProducer.pm; perl/FSM/VIAL/Parity/AHBBaseOutput.pm; perl/FSM/Support/VIALToolingContract.pm; t/1555-vial-public-source-tooling.t; t/1556-vial-public-planning-artifacts.t; t/1557-vial-portable-sv-backend-emission.t; t/1558-vial-verilator-run-integration.t; t/1559-vial-ahb-runtime-parity.t; docs/VIAL_PORTABLE_SYSTEMVERILOG_BACKEND_V1_CONTRACT.md; docs/decisions/0039-vial-public-tooling-is-intent-oriented-and-artifact-atomic.md;
  docs/decisions/0043-vial-portable-systemverilog-is-a-deterministic-known-value-profile.md; docs/VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md; docs/VIAL_EXECUTION_IR_V1_CONTRACT.md; docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; docs/book/src/16d-hial-vial-verification-architecture.md; docs/book/src/16dg-vial-public-lifecycle-reference.md; t/1797-hial-vial-public-lifecycle-reference.t; ROADMAP_V2.md
reverify: ./bin/fsmgen vial capabilities --json && ./bin/fsmgen vial check vial/ahb_subordinate_base_output_arbitration.vial && prove -Iperl t/1874-vial-fault-target-applicability.t t/1873-vial-fault-target-identity.t t/1872-vial-model-reference-identity.t t/1555-vial-public-source-tooling.t t/1556-vial-public-planning-artifacts.t t/1557-vial-portable-sv-backend-emission.t t/1558-vial-verilator-run-integration.t t/1559-vial-ahb-runtime-parity.t t/1797-hial-vial-public-lifecycle-reference.t
---

Decision `0039` owns `fsmgen vial capabilities|check|format|plan|run`.
`plan` takes `.vial` plus `--dut`: IAL0, IAL1 via generated IAL0, or IAL2 via
reparsed generated IAL1 and IAL0. SemanticIR/ExecutionIR/bridge objects stay private.

`terse_v1` removes only selected normal-form version/declaration/scenario
wrappers. Types, values, clocks, timeouts, seeds, bindings, events and behavior
remain explicit. Format/reparse preserves meaning, not source hashes/spans.

The closed `fsmgen.vial_tool_request.v1` / `fsmgen.vial_tool_result.v1` API
checks/formats text/catalogs and plans defensive ordered virtual artifacts;
callbacks, filehandles, private objects and host paths are forbidden. CLI uses
root-relative, non-symlink, same-volume inputs and atomic publication.

Filesystem `plan` atomically publishes canonical source, HIAL review artifacts,
sanitized bridge/plan and tool manifest below
`.artifacts/vial/<fixture>/<full-plan-digest>/` on the repository volume.
Direct IAL0 supports transaction-free endpoint fixtures; transactions require
matching reviewed IAL1/IAL2 truth. Identical trees return `unchanged`;
non-identical/unsafe trees are never overwritten.

ISF verification-output-manifest v1 skeletons stay unchanged. VIAL `run` uses
explicit `fsmgen.verification_output_manifest.v2`, portable SystemVerilog,
validated runtime/results, deterministic reruns and atomic cleanup. Bounded
AHB handwritten-oracle parity is separate evidence, not an ordinary artifact
or general parity claim.

`check_vial_source_file({workspace_root, source_id, language_version?,
source_style?})` returns the complete public check result without output or
publication; CLI check shares it. Regular, non-symlink, same-volume relative
inputs enforce source/combined byte and distinct import-file limits before
parsing, plus stream-growth refusal and parser edge/cycle checks.
`build_vial_source_file_check_contract()` publishes
`contract_surface_map.vial_source_file_check.file_query_contract` without
changing frozen v1 capabilities. T1870 qualifies both versions, imports,
exact/excess limits, closed invocation, native parity and no publication.

T1797 checks `docs/book/src/16dg-vial-public-lifecycle-reference.md` against
machine contracts and the independent runtime watcher.

Model reads retain `model_instance_id` plus state `semantic_id`, correcting
false v1/v2 digest equality. Refresh affected caches; T1872 guards identity,
formatting and migration.

Faults retain declaration `transaction_id`; when aliases share it, explicit
`transaction_binding_id` preserves selected scope. Unique bindings remain
inferable with unchanged legacy IDs. T1873 guards v1/v2 style/import/migration
and API/MCP parity; refresh affected caches. T1874 proves AHB rejects unmatched
aliases, duplicate bridge references cannot bypass binding, and plain IAL1
`declaration_order` is bridge metadata, not execution support. No runtime claim.
