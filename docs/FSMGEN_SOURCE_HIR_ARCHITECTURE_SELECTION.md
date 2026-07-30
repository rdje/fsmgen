# FSMGen SourceHIR architecture selection

Date: 2026-07-30
Owner: `FSMGEN-HIR-ROADMAP-FRONTIER.2`
Status: selected and privately implemented for version-1 valid-ready and
version-2 concrete control

`docs/FSMGEN_SOURCE_HIR_V1_CONTRACT.md` now freezes the exact private v1
field, package API, provenance, diagnostic, renderer-result, source-map, test,
and golden-equivalence contract selected by `.3`.

The three selected packages now implement the private valid-ready path.
Focused t1547 proves canonical rendering through the existing parser and
unchanged downstream artifacts/reports; no public surface is added.

Post-prototype audit `.5` retained the healthy boundary privately and selected
a second private concrete-control-to-IAL1 proof before promotion is
reconsidered. Leaves `.6` and `.7` have now selected and implemented that
proof; `.8` has now completed the audit. `docs/FSMGEN_SOURCE_HIR_POST_PROTOTYPE_AUDIT.md`
and decision `0029` own the original refinement.

Clean private implementation commit `8876adb0b` activates `.8`
continuity-only; activation selects no public/private/retirement outcome.

Audit `.8` now retains the two-route boundary privately and closes this HIR
frontier. Decision `0031` rejects current-shape promotion, narrowing, and
retirement, selects no third architecture-only route, and leaves public
producer/projection selection to the separate proposed builder owner.

## Outcome

FSMGen will add a distinct, private, pre-IAL semantic-intent layer named
`FSM::IR::SourceHIR`. It will not extend the existing
`FSM::IR::IntentHIR`, because that object is already the post-parse forward
semantic summary for direct `.fsm` roots and composition plans.

The first bounded path is:

```text
repository-internal constrained Perl builder
    -> private FSM::IR::SourceHIR
    -> SourceHIR validation and canonical PPIF rendering
    -> canonical .ppif text
    -> existing FSM::Adapter::IAL2::PPIF parser/validator
    -> existing IAL2 ValidReadyChannel generator
    -> generated IAL1 .isf
    -> generated IAL0 .fsm
```

The structured HIR is the new semantic phase boundary. Canonical `.ppif` text
remains the reviewable compatibility handoff into the existing pipeline. The
prototype must use the parser and validator; it may not call the IAL2 generator
contract directly.

This selection changes no code, parser, source artifact, generated artifact,
CLI, API, report schema, support-accounting entry, HDL, or runtime behavior.

## Evidence behind the split

The current forward pipeline already has three named IR layers:

- `FSM::IR::IntentHIR` is built from a parsed `fsm_module` or a
  `composition_plan` and records `.fsm`-level semantic summaries;
- `FSM::IR::LoweredRTLIR` records normalized lowered behavior facts; and
- `FSM::IR::StructuralRTLIR` records explicit structural/connectivity facts
  consumed by backend-facing paths.

Their normalized semantic contracts expose bounded projections of those
post-parse objects. None is a pre-IAL authoring model. Adding protocol-intent
source concepts to `IntentHIR` would combine two phases, two producer families,
and two validation boundaries under one misleading name.

The existing public `.ppif` path already supplies the correct downstream
compatibility boundary. A text-only prototype, however, would leave each
future frontend to invent its own semantic object graph and diagnostic model.
The smallest architecture that avoids both failures is a private SourceHIR
followed by canonical text rendering into the shipped parser.

## Required IR record

### Name

- Object: `FSM::IR::SourceHIR`
- Construction/validation owner: `FSM::IR::SourceHIRBuilder`
- Canonical handoff renderer: `FSM::IR::SourceHIRPPIFRenderer`
- Planned files:
  - `perl/FSM/IR/SourceHIR.pm`
  - `perl/FSM/IR/SourceHIRBuilder.pm`
  - `perl/FSM/IR/SourceHIRPPIFRenderer.pm`

The later contract leaf may split validation into a private helper only if it
keeps this selected three-package owner family unchanged and records the
helper as private implementation detail.

### Phase

`SourceHIR` is a source-facing semantic-intent phase before IAL2 and IAL1. It
is not parsed syntax, scheduled behavior, lowered RTL, structural connectivity,
or a report projection.

### Owner

Only the `FSM::IR::SourceHIR*` package family may construct, validate, or
render the object. Existing IAL adapters consume only the rendered canonical
text. Future frontends may construct SourceHIR only through a separately
selected and documented builder boundary.

### Producers

The first and only producer is a repository-internal constrained Perl builder
that accepts explicit static data. It is a test/prototype construction path,
not a supported host-language API and not a compiler for arbitrary Perl.

The proposed `IAL2-HOST-LANGUAGE-BUILDER-FRONTIER` remains the owner for
selecting a public host language and ergonomic API after the private boundary
has been proved. No Python, Perl, Julia, C, embedded DSL, or standalone source
language becomes public through this selection.

### Consumers

The first direct consumers are SourceHIR validation and
`FSM::IR::SourceHIRPPIFRenderer`. The renderer returns canonical `.ppif` text
plus a private source map. The existing `FSM::Adapter::IAL2::PPIF` consumes
that text, then the existing `FSM::IAL2::ProtocolIntent::ValidReadyChannel`
path produces IAL1 and IAL0 artifacts.

`FSM::IR::IntentHIR`, `FSM::IR::LoweredRTLIR`, and
`FSM::IR::StructuralRTLIR` are downstream of the generated IAL0 path and are
not direct SourceHIR consumers.

### First semantic scope and invariants

Version 1 of the prototype is deliberately narrower than the eventual HIR:

- exactly one protocol-platform intent root;
- exactly one protocol-neutral valid-ready channel;
- a stable intent name, source object id, and ordered source anchors;
- profile, channel name, role, clock, reset signal/polarity/style, valid and
  ready endpoint names;
- a non-empty ordered payload list with stable names and positive integer
  widths;
- stable provenance for the root and semantic fields;
- identifiers accepted by the downstream PPIF/IAL1 boundary;
- no target-HDL syntax, backend-specific expression text, scheduler state,
  lowered behavior, or structural connectivity; and
- deterministic ordering and rendering independent of Perl hash order.

The exact version-1 field/key contract is frozen in
`docs/FSMGEN_SOURCE_HIR_V1_CONTRACT.md`. It stays within this
protocol/fixture boundary.

### Mutation policy

The constructed SourceHIR is immutable to callers. Construction deep-clones
input data, validation completes before handoff, accessors return scalars or
defensive clones, and no mutation method is exposed. The renderer must not
modify its input.

### Public/private status

The raw SourceHIR object, Perl input shape, and renderer source map are private
compiler interfaces. The first prototype is invoked only by focused tests or
an equivalently private repository harness. It adds no CLI mode, public module,
normalized semantic JSON key, `module_info` key, capability-manifest field, or
support-accounting entry.

The existing emitted `.ppif`, `.isf`, `.fsm`, schedule JSON, and normalized
semantic contracts retain their current owners and versions.

### Serialization and report contract

SourceHIR has no public serialization in the first prototype. Its deliberate
textual handoff is canonical `.ppif` version-1 syntax. For the golden input,
the renderer must reproduce `ppif/valid_ready_handshake.ppif` byte-for-byte,
including ordering, indentation, and final newline.

The private renderer result contains:

- the canonical text; and
- a line-oriented mapping from generated PPIF regions to SourceHIR semantic
  paths and their original source locations.

No source-map sidecar is persisted or advertised in this prototype.

### Source locations and diagnostics

Every SourceHIR root and semantic field must be addressable by a stable
semantic path. A producer attaches a repository-relative source name when the
input is file-backed, or a stable logical source name for in-memory input, plus
optional start/end line and column coordinates. Machine-absolute paths are
forbidden in persisted objects and diagnostics.

SourceHIR validation errors cite both the semantic path and the best original
source location. The renderer preserves a private generated-line-to-source
map so a downstream PPIF diagnostic can be translated back to the originating
  SourceHIR path/location. The exact private diagnostic hashes and fallback
  rules are frozen by the version-1 contract.

### Validation

The implementation slice must prove all of the following:

1. constructor and validator acceptance of the exact golden object;
2. focused rejection of missing fields, invalid identifiers, invalid role or
   reset semantics, empty payload, non-positive widths, duplicate endpoints,
   and malformed provenance;
3. defensive-copy and immutability behavior;
4. deterministic output across deliberately reordered input hashes;
5. byte-for-byte `.ppif` golden equivalence;
6. correct SourceHIR-path/source-location diagnostics;
7. successful reparse through the existing PPIF adapter;
8. unchanged schedule and generated IAL1/IAL0 semantics relative to the
   hand-written fixture; and
9. the relevant current forward-IR, normalized-contract, IAL2 fixture,
   mdBook, Knowledge Map, memory, and doctrine gates.

### Documentation impact

The architecture belongs in this record, decision `0028`, the HIR task tree,
roadmap, task index, Knowledge Map fact card, and mdBook feature backlog. The
implementation slice must add a runnable book example only if it creates a
user-visible invocation; the private prototype by itself must not imply a
supported frontend.

### Migration and retirement

This is an additive, opt-in private path. Existing `.fsm`, `.isf`, `.ppif`,
composition, CLI, embedding, reporting, and backend paths do not migrate.
The existing `IntentHIR` family is neither superseded nor renamed.

If the prototype fails to justify a second producer or an ergonomic public
builder, the private `SourceHIR*` packages and focused tests can be removed
without public compatibility work; canonical `.ppif` remains the supported
handoff. Public promotion requires a later task to select versioning,
projection, source packaging, and compatibility rules.

## First exact builder and golden fixture

The first builder is the private `FSM::IR::SourceHIRBuilder` construction path
implemented in Perl for repository proximity. It builds a single valid-ready
object; it is not the public Perl builder contemplated by the host-language
frontier.

The first golden fixture is `ppif/valid_ready_handshake.ppif`. Its selected
facts are:

- intent `valid_ready_handshake`;
- profile/protocol `valid-ready`;
- channel `data_link`;
- role `producer-to-consumer`;
- clock `clk`;
- asynchronous active-low reset `rst_n`;
- endpoints `valid` and `ready`;
- one payload named `data` with width 8; and
- source object `fsmgen-valid-ready-profile` with its existing document,
  section, and page anchor.

This fixture is preferred because it is protocol-neutral, shipped, already
validated by the public PPIF path, and already proves generated IAL1/IAL0
artifacts and runtime-monitor scheduling without adding APB-specific policy.

## Rejected alternatives

### Extend `FSM::IR::IntentHIR`

Rejected because its producers and invariants begin after `.fsm` parsing or
composition planning. Adding pre-IAL authored channel intent would collapse a
distinct compiler phase and make its bounded public projection ambiguous.

### Use only textual IAL output

Rejected as the semantic architecture because multiple future frontends would
still invent incompatible object models and diagnostics. Canonical text is
retained as the compatibility handoff after SourceHIR validation.

### Start with a public host-language API

Rejected for the first prototype because language/package ergonomics and
compatibility would obscure validation of the semantic boundary. Public host
language selection remains proposed under its existing owner.

### Bypass the PPIF parser

Rejected because direct generator calls would create a privileged path around
the shipped syntax and validation contract and weaken golden-equivalence
evidence.

## Follow-on leaves

- `.3` freezes the exact version-1 data, validation, provenance, diagnostic,
  renderer-result, and golden-test contract without behavior changes.
- `.4` implements the private packages and proves the golden pipeline.
- `.5` keeps SourceHIR private: retention is warranted, promotion is
  premature, and retirement is rejected.
- `.6` selects the exact private concrete-control-to-IAL1 boundary, `.7`
  implements it, and `.8` retains the validated two-route seam privately and
  closes this frontier.

Leaf `.6` now selects that boundary in
`docs/FSMGEN_SOURCE_HIR_CONCRETE_CONTROL_V2_CONTRACT.md`: semantic SourceHIR
version 2 renders `isf/phase_test.isf` exactly and uses the existing ISF
adapter and scheduler. Decision `0030` records why raw ISF and typed-parser-AST
storage remain rejected; t1548 now proves the implementation.
