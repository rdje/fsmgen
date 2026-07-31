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
evidence: docs/VIAL_PUBLIC_TOOLING_V1_CONTRACT.md; docs/VIAL_PORTABLE_SYSTEMVERILOG_BACKEND_V1_CONTRACT.md; docs/decisions/0039-vial-public-tooling-is-intent-oriented-and-artifact-atomic.md; docs/decisions/0043-vial-portable-systemverilog-is-a-deterministic-known-value-profile.md; docs/VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md; docs/VIAL_EXECUTION_IR_V1_CONTRACT.md; docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; docs/book/src/16d-hial-vial-verification-architecture.md; ROADMAP_V2.md
reverify: rg -n 'fsmgen vial|normal_v1|terse_v1|fsmgen.vial_tool_request.v1|fsmgen.vial_tool_result.v1|full-plan-sha256|fsmgen.verification_output_manifest.v2|decision `0043`|proposed `.10`' docs/VIAL_PUBLIC_TOOLING_V1_CONTRACT.md docs/VIAL_PORTABLE_SYSTEMVERILOG_BACKEND_V1_CONTRACT.md docs/decisions/0039-vial-public-tooling-is-intent-oriented-and-artifact-atomic.md docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md docs/book/src/16d-hial-vial-verification-architecture.md ROADMAP_V2.md
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
`fsmgen.vial_tool_result.v1` records over the selected source catalog and
artifact sink. Filesystem `plan` output defaults below
`.artifacts/vial/<fixture>/<full-plan-digest>/`, stays repository-local and
same-volume, and atomically publishes canonical normal source, generated HIAL
review artifacts, sanitized bridge/plan projections, and a tool manifest.

Existing `.isf` verification-output-manifest v1 skeleton output remains
unchanged. Future VIAL `run` uses explicit
`fsmgen.verification_output_manifest.v2`; consumers select by schema, not
filename. Decision `0043` now selects the first plain-SystemVerilog/Verilator
backend contract, but selection still ships no parser widening, command, API,
file, backend, or runtime. Clean commit `ab3e73b72` activates `.10` as the first
implementation owner; clean activation commit `5fd766600` decomposes it, with
`.10.1` active for capabilities/check/normal-terse formatting before the
planning, backend, and runtime children.
