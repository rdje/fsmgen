# FSMGen SourceHIR two-route promotion audit

Date: 2026-07-30
Owner: `FSMGEN-HIR-ROADMAP-FRONTIER.8`
Status: selected — retain as a private validated architecture boundary

## Outcome

Retain `FSM::IR::SourceHIR` as the private source-facing semantic boundary.
Do not promote its current Perl object/input shapes, do not add a third private
lowering route, do not narrow or rename the boundary, and do not retire it.

The two implementations now validate the architecture promised by decision
`0028`: one immutable/provenance model can represent protocol/platform intent
to canonical IAL2 and concrete control to canonical IAL1 without storing raw
target syntax, cloning either parser AST, or bypassing existing lowering.

That is architecture evidence, not public-product evidence. Every current
producer is a focused repository test. There is still no selected supported
host language, ergonomic package, public schema/serialization, compatibility
version, CLI, diagnostic promise, report/manifest projection, or support-
accounting contract. Publishing the internal Perl hashes now would freeze an
implementation detail before the separate builder owner selects those user-
facing constraints.

`IAL2-HOST-LANGUAGE-BUILDER-FRONTIER` remains the sole owner of any future
public producer and projection. It may reuse the private object directly,
select a public wrapper/projection over it, or reject its Perl shape while
preserving the semantic boundary. This audit does not activate that proposed
tree.

## Two-route evidence

| Route | Private semantic root | Canonical handoff | Exact oracle | Focused proof |
| --- | --- | --- | --- | --- |
| protocol/platform intent | schema 1 `protocol_platform_intent` / valid-ready | PPIF/IAL2, then existing IAL2 → IAL1 → IAL0 | 14 lines, 428 bytes, SHA-256 `6cbc68152c9e1658a341994bc2ccdd83bdb94b26aedd20d4180c996b5124f7ac` | t1547, 9 top-level tests |
| concrete FSM/control | schema 2 `concrete_control` / actor plus linear phases | ISF/IAL1, then existing IAL1 → IAL0 | 17-line/395-byte ISF SHA-256 `6eeab6c6f2e87c4a91f97fd8c0f2535334a163a7ccf263f30dfcefae51b0d2f2`; 45-line/484-byte IAL0 SHA-256 `8b82ddb329a6b625d0ec271d9611b35140414a2c84e775c1615e442cdfa65047` | t1548, 9 top-level tests |

Together t1547+t1548 pass with `Files=2, Tests=18`. Both routes prove:

- one builder-owned immutable `FSM::IR::SourceHIR` object family;
- closed discriminated schemas with deterministic validation and no raw
  expression or target-language fragment storage;
- defensive access and stable JSON-Pointer-style semantic paths;
- repository-relative/logical provenance with exact, ancestor, then root
  fallback;
- canonical generated text and a private generated-to-original source map;
- truthful structured remapping when downstream errors contain a position and
  root fallback when the current adapters do not provide one;
- re-entry through the shipped parser and lowering chain with equal downstream
  typed structures, artifacts, and reports; and
- no direct parser/scheduler/generator dependency in either renderer.

## Producer and public-surface census

Repository source references are confined to four private modules under
`perl/FSM/IR/SourceHIR*.pm` and focused t1547/t1548. The two tests construct
both roots; no non-test producer exists. `bin/fsmgen`, language-surface,
regression-corpus, embedding/result, capability, reporting, manifest, and
support-accounting owners do not advertise SourceHIR. The object deliberately
has no public `new` constructor.

This is enough to retain the internal seam and stop creating architecture-only
fixtures. It is not enough to promise that users should construct the current
Perl hashes, depend on package names, serialize either schema, or receive these
private diagnostics as a compatibility surface.

## Options considered

| Outcome | Evidence for it | Evidence against it | Result |
| --- | --- | --- | --- |
| Promote current packages/shapes | Two routes are deterministic and lowering-equivalent. | No real producer, language/package selection, versioning, compatibility, serialization, or public diagnostics contract exists. | Rejected as premature. |
| Retain privately, stop architecture-only expansion | Both distinct lowering targets share the selected invariants without syntax leakage; private status carries no compatibility burden. | Public usability remains unproved until a producer is selected. | Selected. |
| Narrow/rename to protocol intent | Version 1 alone originally looked protocol-specific. | Version 2 now proves concrete-control-to-IAL1 within the same immutable/provenance boundary. | Rejected. |
| Retire | Existing public PPIF/ISF paths remain sufficient for users. | Both private routes add checked frontend-neutral semantics and provenance with exact downstream preservation. | Rejected. |

## Closure and reactivation rule

`FSMGEN-HIR-ROADMAP-FRONTIER` closes after this audit: its architecture
selection, exact contracts, both private route proofs, and disposition decision
are complete. No third private fixture is selected.

Future public work must start in an explicitly activated owner, normally
`IAL2-HOST-LANGUAGE-BUILDER-FRONTIER`, and must select before implementation:

1. one supported producer/host language and ergonomic construction surface;
2. whether the public contract is the internal object, a wrapper, or a stable
   projection;
3. schema/versioning/compatibility and deprecation policy;
4. packaging, serialization, diagnostics, and source-location behavior;
5. the first real user workflow and exact public golden; and
6. CLI/report/manifest/capability/support-accounting exposure, if any.

Any later SourceHIR schema expansion requires a new task-tree leaf with a real
producer or product requirement. It may not add architecture-only shapes merely
to accumulate coverage.
