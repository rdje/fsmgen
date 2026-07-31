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
evidence: docs/HIAL_VIAL_BRIDGE_MANIFEST_V1_CONTRACT.md; docs/decisions/0035-hial-vial-bridge-is-produced-from-reviewable-hial-routes.md; docs/decisions/0037-vial-semantic-types-bind-to-hial-carriers-through-directional-proof-relations.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md; docs/book/src/16d-hial-vial-verification-architecture.md
reverify: prove -Iperl t/1551-hial-vial-bridge-manifest.t && rg -n 'core_single_unit_v1|direct_ial2_to_verification|verification-bridge|transaction/ahb_write|probe/reg_data_q|semantic_path|shipped_private_in_process|authoritative hardware carriers|decision `0037`|\.7\.3' perl/FSM/HIAL/VIALBridge/Builder.pm perl/FSM/Support/HIALVIALBridgeContract.pm docs/HIAL_VIAL_BRIDGE_MANIFEST_V1_CONTRACT.md docs/decisions/0035-hial-vial-bridge-is-produced-from-reviewable-hial-routes.md docs/decisions/0037-vial-semantic-types-bind-to-hial-carriers-through-directional-proof-relations.md docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md docs/book/src/16d-hial-vial-verification-architecture.md ROADMAP_V2.md
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

Completed `.5` ships private `FSM::HIAL::VIALBridge::Builder`, `Manifest`, and
`Report` owners, with focused t1551 coverage and capability/support discovery
through `FSM::Support::HIALVIALBridgeContract`. The first scalar-only AHB
profile represents transaction fields individually and leaves aggregate
transaction `type_id` null. Bridge expressions use a closed canonical record
owned by this manifest contract rather than pretending that the current IAL1
schedule report already exposes a reusable expression AST.

The producer writes no bridge file and does not bind VIAL, create an execution
plan, generate verification code, compile/simulate, or claim backend parity.
Public CLI/API/artifact discovery remains owned by `.8`. Clean implementation
commit `51434a2ae` permits the separate continuity-only activation of `.6` for
execution-contract selection; that selection remains unperformed until the
activation commits cleanly and no product behavior changes during activation.
Completed `.6` now selects decision `0036` and the exact target-neutral
execution contract without changing this bridge. Clean selection commit
`eaf3f95dc` permits active `.7` to own private binding/ExecutionIR
work after separate continuity activation. Decision `0037` and `.7.2` now
clarify that bridge field types remain authoritative hardware carriers while
the later ExecutionIR binder proves a closed directional relation from the
independently owned VIAL semantic type. This bridge schema and producer remain
unchanged. Clean selection commit `2a1b3cefc` permitted `.7.3` to implement
that private binder after separate continuity activation; completed `.7.3`
consumes the bridge defensively without changing its schema or producer.
