---
id: hial-vial-bridge-manifest-v1-contract
title: HIALVIALBridgeManifest v1 is produced only from reviewable HIAL routes
answers:
  - "what is the HIALVIALBridgeManifest v1 schema?"
  - "how is the HIAL VIAL bridge generated?"
  - "can PPIF feed the VIAL bridge directly?"
  - "how do IAL2 protocol facts enter the VIAL bridge?"
  - "what is the IAL1 verification-bridge annotation?"
  - "which bridge IDs bind the AHB VIAL fixture?"
  - "does the HIAL VIAL bridge expose hierarchy?"
  - "does the HIAL VIAL bridge bind VIAL yet?"
  - "what does core_single_unit_v1 mean?"
date: 2026-07-31
status: current
tags: [hial, vial, bridge, manifest, ial0, ial1, ial2, review-route, provenance, ahb]
evidence: docs/HIAL_VIAL_BRIDGE_MANIFEST_V1_CONTRACT.md; docs/decisions/0035-hial-vial-bridge-is-produced-from-reviewable-hial-routes.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md; docs/book/src/16d-hial-vial-verification-architecture.md
reverify: rg -n 'core_single_unit_v1|direct_ial2_to_verification|verification-bridge|transaction/ahb_write|probe/reg_data_q|semantic_path|writes no file|Proposed `.5`' docs/HIAL_VIAL_BRIDGE_MANIFEST_V1_CONTRACT.md docs/decisions/0035-hial-vial-bridge-is-produced-from-reviewable-hial-routes.md docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md docs/book/src/16d-hial-vial-verification-architecture.md ROADMAP_V2.md
---

Decision `0035` selects `fsmgen.hial_vial_bridge_manifest.v1` with initial
`core_single_unit_v1`. It is a sanitized JSON-safe HIAL-to-VIAL binding-data
contract, not raw AST/IR, target HDL, an execution plan, or a runtime result.

The only routes are direct IAL0; direct IAL1 through generated IAL0; and IAL2
through generated IAL1 plus generated IAL0. PPIF never feeds the bridge
directly. Protocol/event/probe facts are rendered into a deterministic
generated-IAL1 `(verification-bridge ...)` annotation, then parsed, validated,
and reported by the ordinary IAL1 route before the bridge consumes them.

The first AHB route publishes exact IDs used by the checked VIAL source:
`unit/ahb_lite_subordinate`, `domain/ahb_bus`, its public endpoint IDs,
`transaction/ahb_write`, six lifecycle events, and `probe/reg_data_q`. Public
ports are portable. The probe remains `verification_probe` with an equivalent-
adapter requirement; no raw SystemVerilog/VHDL hierarchy path leaks into the
manifest.

Every semantic field has provenance. Exact spans are used only when an owning
parser supplies them; otherwise a stable semantic path and null span fields
state the honest precision. IAL2-derived facts cite authored PPIF and generated
IAL1 annotation provenance.

Proposed `.5` owns the private immutable producer/report and focused t1551.
It writes no bridge file and does not bind VIAL, create an execution plan,
generate verification code, compile/simulate, or claim backend parity. Public
CLI/API/artifact discovery remains owned by `.8`.
