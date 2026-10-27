---
id: direct-declared-width-consumers
title: Direct declared ranges retain source trees but numeric declaration plans need captured lookup identities
answers:
  - "where do direct symbolic declared-width consumers need integration?"
  - "where do actual direct backend declaration snapshots come from?"
  - "does a direct parameter-dependent width defaulting to one retain a vector range?"
  - "is the Core module signals map exhaustive for declared assignment targets?"
  - "why must explicit auxiliary width declarations be preserved before copying parent bindings?"
  - "why must late sizing preserve distinct next/q copy origins?"
date: 2026-10-27
status: current
tags: [widths, parameters, lowering, declarations]
evidence: >-
  t/2175-direct-symbolic-port-ranges.t; t/data/ial0-direct-symbolic-ports.fsm; docs/audits/direct-symbolic-ports-20261027.json.gz;
  perl/FSM/Backend/VerilogFamily/DeclarationCapture.pm; t/2174-direct-declaration-capture.t; docs/audits/direct-declaration-capture-20261027.json.gz;
  t/2173-direct-width-target-plans.t; docs/audits/direct-width-target-plans-20261027.json.gz;
  perl/FSM/DirectDeclaredWidthSupport.pm; t/2172-direct-width-module-source-plans.t; docs/audits/direct-width-module-source-plans-20261027.json.gz;
  perl/FSM/DeclaredWidthRangeSupport.pm; t/2171-declared-width-range-adapter.t; docs/audits/direct-width-range-adapter-20261027.json.gz;
  docs/audits/direct-width-binding-proof-20261027.json.gz; perl/FSM/DeclaredWidthBindingSupport.pm; docs/audits/shared-vhdl-width-kernel-20261027.json.gz;
  perl/FSM/Backend/VHDL/WidthExpressionEmitter.pm; docs/audits/shared-verilog-width-kernel-20261027.json.gz; perl/FSM/Backend/VerilogFamily/WidthExpressionEmitter.pm;
  docs/audits/scoped-late-width-sizing-20261027.json.gz; docs/audits/immediate-width-copy-origins-20261027.json.gz; docs/audits/scoped-late-width-contract-20261027.json.gz;
  docs/audits/scoped-late-width-contract-20261027.py; docs/audits/auxiliary-width-bindings-20261027.json.gz; docs/audits/source-width-requirements-20261027.json.gz;
  docs/audits/auxiliary-width-origin-contract-20261027.json.gz; docs/audits/auxiliary-width-origin-contract-20261027.py; docs/audits/direct-declared-range-split-20261027.json.gz;
  perl/FSM/Adapter/FSMGenFull/Parser.pm; perl/FSM/Synthesis/EnableGraph/ModulePlanningSupport.pm; perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm;
  perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm; t/2111-ial0-parameter-width-selection.t
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2111-ial0-parameter-width-selection.t
---

Parser retains expression, resolved_width and original signal in the detached
Signal declared_width_source getter. Named types keep their existing type
contract. Complete actual parameter/static lookup provenance is not retained
there; the current numeric plans cannot reconstruct it from equal widths.

The receipt's actual resettable source has WIDTH1, an explicit data_port
parameter selector and an independent literal-width input. The selector tree
survives on its Signal while the independent literal has no authored width
record; the retained predecessor emitted both as scalar HDL. Current direct
Verilog-family ports preserve captured symbolic vector rank, including width1. Module signals alone is not
an exhaustive source for assigned outputs: the actual Signal is also reached
through the canonical adapter registry and assignment AST.

ModulePlanningSupport owns direct port/internal plans. ScaffoldEmitter now
consumes captured symbolic port ranges; InternalDeclarationEmitter still renders
numeric storage ranges. Direct VHDL symbolic port conversion remains pending
and refuses rather than returning an artifact. CompositionWidthEmitter already has
captured lookup contracts, explicit symbolic ranges and one-bit vector rank.
ISF-REDUCTION-DELIVERY.3.3 owns source provenance, shared target kernels and
direct consumer integration; computed shapes and full qualification stay .3.4/.6.

The direct Parser offers opt-in capture_declared_width_contract with explicit
lexical direct_module scope, preserving the actual constant fast branch and
canonical selected observation walk. Successful source parsing now stages real
Signal associations and publishes primary declared_width_binding records only
after complete module validation; facade failures clear them too. Original
header scope survives physical renaming. Old source/numeric/public products
conserve; literal/type branches acquire no parameter relationship. Eligible
auxiliary propagation and explicit scoped late sizing are implemented with
focused checks before target range kernels .3.3.2.
Reverify:
`prove -Iperl t/2162-direct-source-width-binding-publication.t t/2161-core-declared-width-binding-lifecycle.t t/2160-direct-declared-width-capture.t t/2111-ial0-parameter-width-selection.t`.

Actual <-=/<=-/<=+ auxiliary copies overwrite an independently declared auxiliary
source record with data(param W), while legacy max-width refinement still retains
both numeric requirements. Equal-default param X and literal-eight declarations
then had identical selected Signal products in that retained predecessor epoch; opposing W/X defaults demonstrate
the lost constraint still matters numerically. Clean/one-bit/named-type and
renamed late-sizing controls retain their distinct boundaries. The P1 private
retention defect is now repaired under .3.3.1.2.2.3.3.4; numeric behavior remains
unchanged. The audit packet describes its predecessor epoch. Immutable event
snapshots and final active actual-object ownership prevent later live-source
lookup from supplying an earlier copy's identity. Audit reverify:
`python3 -B docs/audits/auxiliary-width-origin-contract-20261027.py --self-test`.

The opt-in Core declared_width_requirements holder now retains ordered separate
declaration/generated snapshots with lexical scope and observed maximum width.
Each keeps origin/expression/type/capture distinctions; it supplies no combined
symbolic expression or new source admission. Plain copies detach callers and
getters, failed replacement clears, and actual registry width/source/type writes
or source-transaction clearing invalidate every record. Getter state anchors
withhold privately diverged installations. Ordinary objects add no field.
The Parser now captures declarations and actual copy events into a local map
keyed by Signal identity. Immutable copied requirements retain every separate
contribution to the legacy numeric maximum; deduplication requires identical
whole snapshots. Unrecorded contributions are explicitly opaque. Registry
mutation versions plus installation state revoke stale pending requirements and
primary bindings even after matching-state replacement. Current records publish
only after complete success; all new maps clear on invalidation. Both sizing
orders and real copy chains retain independent origins. Ordinary unscoped late
sizing remains legacy. Scoped late sizing/range admission and computed shape
rendering remain separately owned successors.
Reverify: `prove -Iperl t/2164-direct-source-width-requirements.t t/2163-core-declared-width-requirements.t t/2161-core-declared-width-binding-lifecycle.t t/2162-direct-source-width-binding-publication.t`.

Eligible primary and auxiliary bindings now derive from the same current
requirement map; no separate pending-primary map can bypass combined constraints.
A single captured requirement must still agree with the actual legacy source,
width and absent type through Core coherence checks. Real copy chains retain the
original declaration; static/type/parameter namespaces and one-bit captures stay
distinct. Independent or opaque requirements withhold a single binding, including
repeated primary declarations with equal defaults. Fresh retries use current
lexical declarations; an inherited larger numeric floor remains explicitly
opaque. Final event versions preserve immutable copies and reject stale source
replacement. Reverify: `prove -Iperl t/2165-direct-auxiliary-width-bindings.t t/2164-direct-source-width-requirements.t t/2162-direct-source-width-binding-publication.t`.

Late-sizing diagnostic policies expose a collision boundary: next_data_r may
receive next(data_r) and q(next_data) requirements. Current retention keeps both.
Fresh contexts lose explicit auxiliary declarations; blanket generated-record
removal loses the other copy path even with equal defaults. Preserving all
records safely withholds clean late bindings behind earlier opaque inference.
The prerequisite .3.3.1.2.2.3.3.3.2.1 now records optional immediate copy_origin
attestation at actual copy events, separate from original declaration identity.
Capture requires actual source-object equality with the registry key; matching
names or widths cannot attest an edge. Chains overwrite the immediate origin
while preserving original declaration/capture identity. Older absent/null fields
remain unattested; declarations and unexplained numeric floors invent no edge.
Distinct immediate edges retain separate snapshots even for equivalent original
captures; combined-shape reduction stays .3.4. Reverify:
`prove -Iperl t/2166-immediate-width-copy-origins.t t/2164-direct-source-width-requirements.t t/2165-direct-auxiliary-width-bindings.t t/2163-core-declared-width-requirements.t`.
The scoped entrypoint .2.2 preserves all authored and other-origin records,
replacing only opaque generated records attested to that same actual immediate
source under original lexical scope; unknown older records stay conservative.
The saved policies describe diagnostic prototypes at their recorded epoch.
Reverify:
`python3 -B docs/audits/scoped-late-width-contract-20261027.py --self-test`.

Private Parser parse_size_section_in_scope(size_ast, scope) now shares canonical
copied scope validation and the actual final requirement/binding publisher.
Malformed/incompatible scopes refuse before mutation. Accepted calls snapshot
current compatible actual records, clear metadata, seed revocable events and
publish only after complete success. Nested same-scope calls reuse outer staging.
Only opaque generated requirements attested to the same actual immediate source
may be replaced; all authored and other-origin records remain, and larger
unexplained numeric floors stay opaque. Scalar/list/void and no-op contracts are
preserved; ordinary calls create no capture context. Failed accepted sizing or
publication clears all derived records, preserving the numeric/source prefix.
The legacy named-type ordering asymmetry is reproduced and owned by .24 before
.6: early assignment auxiliaries omit Core type metadata while late sizing copies
it. The new scoped path preserves the actual legacy late getters; requirements
retain the same type origin. Reverify:
`prove -Iperl t/2167-scoped-late-width-sizing.t t/2165-direct-auxiliary-width-bindings.t t/2162-direct-source-width-binding-publication.t t/2160-direct-declared-width-capture.t`.

VerilogFamily::WidthExpressionEmitter now owns the existing prepared width walk,
using WidthExpressionSupport and shared ParameterBindingEmitter for explicit
direct_module/composition_top scopes. CompositionWidthEmitter is the narrower
top-scope/diagnostic wrapper. Ordered actual lookups, static arithmetic folds and
default-one vector rank preserve; foreign targets and unknown/mismatched scopes
refuse. Returned range text retains no caller graph. Actual existing composition
success/refusal/caller products conserve. Direct captured-plan preparation and
declaration activation remain .3.3.2.3/.3.
Reverify: `prove -Iperl t/2168-shared-verilog-width-kernel.t t/2135-composition-symbolic-port-ranges.t`.

VHDL::WidthExpressionEmitter now shares the existing portable prepared width
walk in direct_module/composition_top scope. Its composition wrapper preserves
top diagnostics and declaration/namespace prerequisites. The integer evaluator
retains natural bounds at every intermediate step, positive final width and mod
formatting; selected roots reuse VHDL::ParameterBindingEmitter identifier checks.
Actual composition success/refusal/caller products preserve, including recursive
caller topology captured as a deterministic reference graph. Direct raw
conversion and captured direct plans remain inactive. Reverify:
`prove -Iperl t/2169-shared-vhdl-width-kernel.t t/2139-composition-vhdl-port-ranges.t`.

DeclaredWidthBindingSupport proves coherent actual Signal captures against
frozen lookup observations and declared root/path payloads, reusing canonical
width evaluation without live namespace selection. DeclaredWidthRangeSupport
now adapts the proved structured graph to shared target contracts and range text.
Selected scalar roots retain their actual names, aliases, repeated order and
one-bit vector rank; pinned static trees inline without bypassing target-owned
intermediate checks. Fully static captures keep fixed numeric/rank plans.
Mutable paths, unsupported scalar/type/target profiles, symbol-bearing parameter
payloads and static payloads hiding mutable dependencies refuse. Caller defaults
remain unchanged and plans retain no Signal/environment owner. DirectDeclaredWidthSupport now joins actual module Signals and normalized
assignment-target SignalRefs, rejecting distinct objects claiming one physical
name. Copied module parameter maps pass canonical observation proof; coherent
bindings join the bounded adapter with original lexical scope. Fixed/type/static
controls preserve, while combined mutable requirements and stale/missing binding
records refuse. Module plans are detached and retain no Core/backend owners.
prepare_declarations now joins actual namespace/declaration snapshots, checking
mapped parameter/Signal membership, reserved names/collisions, numeric default
widths, signedness and declared types. VHDL folds case; selected mutable root
renaming refuses while physical module/Signal mappings remain independent of
source ownership. Detached target plans identify symbolic port/storage ranges
and independent fixed declarations. Actual numeric rendered widths independently
match backend planner metadata in the focused contract. The opt-in VerilogFamily::DeclarationCapture publisher now records actual
parameter order, ports, state/storage/enable/intermediate declarations and
allocated typedef names across the existing emitters. Completed assembly alone
exposes detached namespace/numeric-type snapshots; reset, failed/incomplete or
duplicate transactions withhold old/partial results. No HDL parsing or second
generation pass supplies them. Actual ordinary/captured artifacts conserve
against authenticated predecessor owners under the Date-only comparison.
Direct Verilog-family ports now consume the proved ranges, retaining actual
selected roots, arithmetic and default-one vector rank. Captured declarations
install the collector for one generation. Complete actual target qualification
and exact emitted-plan comparison reject late same-default ancestry changes;
combined/stale/namespace and symbolic system-width profiles refuse before success.
Fixed/type/legacy and static VHDL defaults conserve. Native strict check plus
SystemVerilog/Verilog outputs qualify the one-bit fixture; symbolic VHDL refuses
and preserves an existing destination. Storage/computed shapes, source-aware
VHDL ranges and full override/runtime qualification remain successors. Existing whole backend retention is separately owned under
.25 and the flattened-backend-owner-cycle card; isolated target plans retain no
caller target records or never-installed physical Core copy. Reverify:
`prove -Iperl t/2175-direct-symbolic-port-ranges.t t/2174-direct-declaration-capture.t t/2173-direct-width-target-plans.t`.
