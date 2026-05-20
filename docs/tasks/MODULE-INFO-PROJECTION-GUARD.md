# MODULE-INFO-PROJECTION-GUARD: Module Info Projection Guard

## Metadata

- Tree ID: `MODULE-INFO-PROJECTION-GUARD`
- Status: `done`
- Roadmap lane: `architecture backlog`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Keep `module_info` honest as a compatibility/result projection by auditing the
remaining mirrors, public contract keys, and mutation boundaries that could
make it look like a second canonical compiler IR.

## Non-Goals

- Do not remove `module_info`; existing embedders rely on it.
- Do not freeze every nested `module_info` field as stable public API.
- Do not duplicate normalized semantic JSON contracts inside `module_info`.
- Do not change caller-visible result shape without explicit compatibility
  planning.

## Acceptance Criteria

- `module_info` forward-IR mirrors, composition mirrors, and bounded contract
  keys are audited against the named canonical IR/projection owners.
- Any missing mutation/aliasing guard or misleading public-contract wording is
  split into executable leaves before code changes begin.
- Public docs/book text stays clear that `module_info` is a compatibility
  projection, not compiler truth.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `MODULE-INFO-PROJECTION-GUARD`
  Status: `done`
  Goal: `Guard module_info as a bounded compatibility projection.`
  Children: `MODULE-INFO-PROJECTION-GUARD.1`,
  `MODULE-INFO-PROJECTION-GUARD.2`, `MODULE-INFO-PROJECTION-GUARD.3`

- ID: `MODULE-INFO-PROJECTION-GUARD.1`
  Status: `done`
  Goal: `Audit module_info mirrors and contract key families.`
  Acceptance: `Direct, composition, generated-child, and semantic forward-IR
  mirrors are mapped to their canonical owner or report projection.`
  Verification: `static module_info owner/contract/test inventory`; `git diff --check`; `mdbook build docs/book`
  Commit: `MODULE-INFO-PROJECTION-GUARD.1: audit module_info mirrors`

- ID: `MODULE-INFO-PROJECTION-GUARD.2`
  Status: `done`
  Goal: `Select missing guard or wording fixes.`
  Acceptance: `No implementation guard is selected because `.1` found the
  current mirror ownership, contract wording, book wording, and alias guards
  already aligned.`
  Verification: `static module_info wording search`; `git diff --check`; `mdbook build docs/book`
  Commit: `MODULE-INFO-PROJECTION-GUARD.2: close module_info guard selection`

- ID: `MODULE-INFO-PROJECTION-GUARD.3`
  Status: `deferred`
  Goal: `Implement selected module_info projection guards.`
  Acceptance: `No implementation runs from this tree because `.2` selected no
  missing guard or wording fix.`
  Verification: `not run; deferred by selection decision`
  Commit: `deferred`

## Current Frontier

This tree is closed. No `module_info` implementation guard is PNT-eligible
from this tree. Future `module_info` guard work must be explicitly reopened
through a new or reactivated task-tree leaf.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `MODULE-INFO-PROJECTION-GUARD.1` | `done` | Mirror and contract inventory completed before selecting any guard. |
| 2 | `MODULE-INFO-PROJECTION-GUARD.2` | `done` | Selected no missing guard or wording fix after the inventory and wording search. |
| 3 | `MODULE-INFO-PROJECTION-GUARD.3` | `deferred` | No implementation runs until future work explicitly reopens a guard leaf. |

## Decisions

- `2026-05-20`: Selected as an actionable follow-up from
  `FSMGEN-IR-AUDIT.4` because `module_info` is useful and compatibility-bound
  but overlaps forward IR and normalized report projections enough to require
  periodic guard coverage.
- `2026-05-20`: Completed `.1` by auditing direct, composition, generated
  child, public contract, and normalized semantic report `module_info` mirrors.
  The audited surface is already owner-split and heavily guarded; `.2` will
  decide whether any concrete extra guard or wording fix is still justified.
- `2026-05-20`: Completed `.2` by selecting no missing implementation guard
  or wording fix. The audited docs and book already state that `module_info` is
  a bounded compatibility/result projection, not whole-hash compiler truth.
  `.3` is deferred.

## Open Questions

- None for this closed tree. Reopen only if future code changes add a new
  `module_info` mirror or stale wording claims whole-hash stability.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `MODULE-INFO-PROJECTION-GUARD.1` | `rg -n 'module_info|GeneratedModuleInfoBuilder|ResultMetadataBuilder|HDLGeneratorModuleInfoContract|forward_ir|intent_hir|lowered_rtl_ir|structural_rtl_ir' perl docs t`; `rg -n 'module_info.*alias|alias.*module_info|mutation.*module_info|module_info.*mutation|contaminate.*module_info|module_info.*contaminate|separate mutable|fresh module_info' t docs/book/src docs/COMPOSITION_SCOPE.md docs/IR_POLICY.md`; `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-20` | `MODULE-INFO-PROJECTION-GUARD.2` | `rg -n 'module_info.*canonical|canonical.*module_info|module_info.*stable|stable.*module_info|module_info.*truth|truth.*module_info|module_info.*public API|public API.*module_info|module_info.*full_hash_stable|full_hash_stable.*module_info|module_info.*JSON safe|JSON safe.*module_info|whole module_info|module_info hash' README.md docs docs/book/src perl/FSM/Support t`; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `MODULE-INFO-PROJECTION-GUARD.1` | `MODULE-INFO-PROJECTION-GUARD.1: audit module_info mirrors` | Maps mirror families to canonical owners and existing guard coverage. |
| `MODULE-INFO-PROJECTION-GUARD.2` | `MODULE-INFO-PROJECTION-GUARD.2: close module_info guard selection` | Selects no missing guard or wording fix and closes the tree. |

## Changelog

- `2026-05-20`: Created proposed follow-up task tree from
  `FSMGEN-IR-AUDIT.4`.
- `2026-05-20`: Activated `.1`, inventoried module-info mirror owners and
  guard coverage, and advanced `.2` for selection.
- `2026-05-20`: Completed `.2`, selected no missing guard or wording fix,
  deferred `.3`, and closed the tree.

## Module Info Mirror Inventory

`module_info` remains a compatibility/result projection. It is not compiler
truth and should not become a second canonical IR. The current implementation
already splits most ownership across direct-result, composition-result,
contract, and normalized-report owners.

| Mirror family | Producer / owner | Canonical owner or source | Public projection status | Existing guard coverage |
| --- | --- | --- | --- | --- |
| Direct generated-module identity and semantic summaries | `FSM::Pipeline::GeneratedModuleInfoBuilder::build_from_fsm_module`, called by `FSM::Pipeline::DirectGenerationOrchestrator`. | `FSM::CoreAST` for direct semantics, then `FSM::IR::IntentHIR` for module identity, state/signal summaries, system contract, parameters, and symbol contract. | Bounded in-process `HDLGeneratorResult.module_info` identity/summary keys; top-level `intent_hir` and normalized semantic JSON are preferred for structured downstream inspection. | `t/560-generated-module-info-top-level-intent-projection-defensive-copy-boundary-audit.t`, `t/589-direct-generation-module-info-forward-ir-alias-boundary-audit.t`, `t/574-direct-generation-semantic-ir-alias-boundary-audit.t`, `t/596-hdl-generator-stateful-module-info-alias-boundary-audit.t`, and `t/620-hdl-generator-stateful-standalone-dt-module-info-alias-boundary-audit.t`. |
| Direct lowered summaries | `FSM::Pipeline::GeneratedModuleInfoBuilder::enrich_with_generated_analysis`. | `FSM::IR::LoweredRTLIR` built from generated-module analysis/backend state. | `module_info` mirrors selected output-drive, selector-conflict, and standalone-DT grouped-target summaries; top-level `lowered_rtl_ir` and normalized semantic JSON remain the structured projection. | `t/561-generated-module-info-lowered-projection-defensive-copy-boundary-audit.t`, `t/590-direct-generation-module-info-lowered-ir-alias-boundary-audit.t`, and `t/574-direct-generation-semantic-ir-alias-boundary-audit.t`. |
| Direct structural mirror | `FSM::Pipeline::DirectGenerationOrchestrator` attaches `structural_rtl_ir` after `FSM::IR::StructuralRTLIRBuilder`. | `FSM::IR::StructuralRTLIR` is the structural/connectivity boundary. | `module_info.structural_rtl_ir` mirrors the bounded structural projection for compatibility; top-level `structural_rtl_ir` and normalized semantic JSON remain preferred. | `t/1333-direct-structural-rtl-ir-projection.t` and `t/574-direct-generation-semantic-ir-alias-boundary-audit.t`. |
| Composition module identity, child, and semantic summaries | `FSM::Composition::ResultMetadataBuilder::build_module_info`, called by `FSM::Composition::GenerationOrchestrator`. | `FSM::Composition::Plan`, `FSM::IR::StructuralRTLIR`, and `FSM::IR::IntentHIR`; child export summaries are built by `FSM::Composition::ChildExportBuilder`. | `module_info` mirrors bounded composition counters and child summaries for compatibility; semantic composition JSON and top-level `intent_hir` remain the structured projection. | `t/555-composition-result-metadata-forward-ir-alias-defensive-copy-boundary-audit.t`, `t/581-composition-generation-module-info-forward-ir-alias-boundary-audit.t`, `t/579-composition-generation-semantic-ir-alias-boundary-audit.t`, `t/160-composition-top-forward-ir-surface.t`, `t/165-composition-child-forward-ir-exports.t`, and `t/614-hdl-generator-stateful-composition-module-info-alias-boundary-audit.t`. |
| Composition lowered and structural summaries | `FSM::Composition::ResultMetadataBuilder::build_module_info`. | `FSM::IR::LoweredRTLIR` for internal-net, instance, auxiliary-assignment, output-drive, and shared-datapath summaries; `FSM::IR::StructuralRTLIR` for ports, nets, instances, and resolved links. | `module_info` carries compatibility counters/lists and embedded forward-IR mirrors; top-level forward IR and normalized semantic JSON remain preferred. | `t/582-composition-generation-module-info-lowered-ir-alias-boundary-audit.t`, `t/162-composition-top-structural-rtl-ir-surface.t`, and `t/579-composition-generation-semantic-ir-alias-boundary-audit.t`. |
| Composition provenance mirror | `FSM::Composition::ResultMetadataBuilder::build_module_info` and `build_statistics`. | `FSM::Composition::ProvenanceReportBuilder` plus `FSM::Support::CompositionReportContract` for serialized provenance. | `module_info.composition_provenance` and `statistics.composition_provenance` are compatibility mirrors; normalized semantic composition provenance is the serializable downstream path. | `t/553-composition-result-metadata-provenance-defensive-copy-boundary-audit.t` and `t/580-composition-generation-provenance-alias-boundary-audit.t`. |
| Realized child module_info | `FSM::Composition::GeneratedChildRealizer`, `FSM::Composition::RTLChildRealizer`, and `FSM::Composition::RealizedInstance`. | Generated children reuse their direct `module_info`; external RTL children use loaded interface metadata as a composition planning carrier. | Realized child `module_info` is a private/in-process planning carrier exposed through bounded parent summaries and composition reports. | `t/500-realized-instance-accessor-defensive-copy-boundary-audit.t`, `t/184-composition-generated-child-realizer.t`, `t/185-composition-rtl-child-realizer.t`, `t/158-composition-generated-child-forward-ir-exports.t`, and `t/164-realized-child-interface-ports-from-structural-rtl-ir.t`. |
| Public nested module_info contract | `FSM::Support::HDLGeneratorModuleInfoContract`, reused by `FSM::Support::HDLGeneratorResultContract` and the capability manifest. | Contract owners advertise only identity keys, scalar summary keys, optional composition scalar summaries, and stable subsurface names. | `full_hash_stable` is false; whole-hash JSON safety is false; embedders should target advertised subsurfaces or normalized semantic JSON. | `t/305-hdl-generator-result-contract.t`, `t/355-hdl-generator-leaf-runtime-contract-audit.t`, `t/729-hdl-generator-result-contract-module-info-keys-json-roundtrip-audit.t`, `t/738-hdl-generator-result-contract-module-info-keys-defensive-copy-audit.t`, `t/770-capability-manifest-hdl-result-module-info-keys-json-roundtrip-audit.t`, `t/1075-hdl-generator-module-info-contract-full-surface-json-roundtrip-audit.t`, and `t/1076-hdl-generator-module-info-contract-full-surface-defensive-copy-audit.t`. |
| Normalized semantic report fallback | `FSM::Support::NormalizedSemanticReport`. | Top-level `intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir` are preferred; `module_info` is fallback/compatibility input for module and composition summaries. | Normalized semantic JSON is the downstream machine interchange surface, not `module_info` as a raw tree. | `t/641-serializable-generation-result-snapshot-defensive-copy-boundary-audit.t`, `t/642-normalized-semantic-generation-snapshot-alias-boundary-audit.t`, and normalized semantic contract tests under the `NormalizedSemantic*Contract` families. |

## Audit Notes For `.2`

The audit did not find an obvious unowned `module_info` family. Existing code
and tests already cover the highest-risk aliasing boundaries:

- same-result top-level semantic IR versus `module_info` mirrors,
- `module_info` top-level summaries versus embedded `intent_hir` /
  `lowered_rtl_ir` mirrors,
- composition provenance versus `module_info` / `statistics` mirrors,
- realized-instance constructor/accessor copy boundaries,
- stateful `HDLGenerator` reuse across direct, standalone-DT, and composition
  module-info containers,
- public contract key lists, stable-subsurface maps, JSON round trips, and
  defensive rebuilds.

`.2` closed the tree with no code changes. The wording search found only
bounded-key and stable-subsurface claims, plus explicit statements that the
whole `module_info` hash is not stable/canonical compiler truth.
