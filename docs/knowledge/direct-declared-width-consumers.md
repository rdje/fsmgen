---
id: direct-declared-width-consumers
title: Direct declared ranges retain source trees but numeric declaration plans need captured lookup identities
answers:
  - "where do direct symbolic declared-width consumers need integration?"
  - "do direct symbolic internal storage ranges retain assignment-target captures?"
  - "where do actual direct backend declaration snapshots come from?"
  - "does a direct parameter-dependent width defaulting to one retain a vector range?"
  - "is the Core module signals map exhaustive for declared assignment targets?"
  - "why must explicit auxiliary width declarations be preserved before copying parent bindings?"
  - "why must late sizing preserve distinct next/q copy origins?"
  - "why did guard XOR become NOT?"
  - "how are explicit Core intermediate width allocation contracts held?"
  - "which consumers own concatenation selection and shift intermediate widths?"
  - "why can a shift helper borrow the shift amount width?"
  - "why does a static slice guard test the whole signal?"
  - "why do bit and concatenation guards reference undeclared condition?"
  - "how are factorizer allocation births retained?"
  - "how are ordered concatenation candidate births retained?"
  - "how are current concatenation sources observed without getters?"
  - "where are original concatenation generation sources frozen?"
  - "how are factorizer width inference events captured?"
  - "what owns graph proof rows?"
  - "why does I2C generation refuse inline shifts with literals?"
  - "why do AHB comparison guards falsely require literal data width intent?"
  - "why does ISF wait shift fail complete current selected targets?"
date: 2026-11-01
status: current
tags: [widths, parameters, lowering, declarations]
evidence: >-
  perl/FSM/ConcatenationWidthBirthSupport.pm; t/2276-concatenation-candidate-births.t; docs/audits/concat-candidate-birth-20261030/evidence.json.gz;
  perl/FSM/CoreAST.pm; perl/FSM/Adapter/FSMGenFull.pm; perl/FSM/Adapter/FSMGenFull/Parser.pm; perl/FSM/DeclaredWidthBindingSupport.pm; perl/FSM/DeclaredWidthRangeSupport.pm; perl/FSM/DirectDeclaredWidthSupport.pm; t/2266-direct-target-namespace.t; perl/FSM/IntermediateWidthAllocationSupport.pm; perl/FSM/HDL/ASTFactorization.pm; docs/audits/graph-close-20261029.json.gz;
  perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm; perl/FSM/Backend/VerilogFamily/DeclarationCapture.pm; perl/FSM/Backend/VerilogFamily/WidthExpressionEmitter.pm; perl/FSM/Backend/VHDL/WidthExpressionEmitter.pm; perl/FSM/Synthesis/EnableGraph/ModulePlanningSupport.pm; perl/FSM/Synthesis/EnableGraph/CaptureSupport.pm; perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm; perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm;
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/221[23489]*.t t/2277-concatenation-source-observations.t t/2204-factorizer-width-births.t t/22[23]*.t t/2198*.t t/2111-ial0-parameter-width-selection.t
---

Current owners are above. Exact original cards/proofs (baseline/digests) remain in `docs/audits/width-card-evidence-20261028.json.gz`; recover:

`python3 -B -c 'import gzip,json,hashlib; r=json.load(gzip.open("docs/audits/width-card-evidence-20261028.json.gz")); c=r["original_cards"]["docs/knowledge/direct-declared-width-consumers.md"]; b=c["source"].encode(); assert hashlib.sha256(b).hexdigest()==c["sha256"]; print(b.decode(),end="")'`.

Parser's Signal declared_width_source detaches expression/resolved_width/original signal; named types keep their contract.
Module parameter getters clone; source text/equal widths lack parameter/static lookup provenance.
The resettable receipt uses WIDTH1, explicit data_port parameter selection and an
independent literal-width input. Only the selector has an authored tree. Both
were formerly scalar HDL; captured Verilog-family ports now preserve symbolic
vector rank at width1. Assigned-output Signals may live in the canonical adapter
registry/assignment AST rather than the module signals map.

ModulePlanningSupport owns port/internal plans. ScaffoldEmitter consumes captured
port ranges; InternalDeclarationEmitter consumes source-owned storage, including
assignment targets absent from module membership. Register helpers use parent
ranges (T2187). VHDL follows direct-vhdl-parameter-profiles. CompositionWidthEmitter
already has captured lookups, symbolic ranges and width1 vector rank. Source
provenance/shared kernels/direct integration belong to .3.3; computed shapes/full
qualification remain .3.4/.6.

Parser capture_declared_width_contract is opt-in, with lexical direct_module
scope, unchanged constant fast path and canonical selected-observation walk.
Actual Signal associations stage locally; primary declared_width_binding publishes
only after complete validation, and facade failures clear it. Header scope
survives physical renaming. Old numeric/public/source products preserve; literal
and type branches acquire no parameter relation.

Historical <-=/<=-/<=+ auxiliary overwrite and opposing W/X counterexamples retain
in the auxiliary-width-origin audit and exact prior card:
`git show 8b2868190:docs/knowledge/direct-declared-width-consumers.md`.
Current immutable events/actual-object ownership preserve earlier copy identity;
.3.3.1.2.2.3.3.4 repaired retention without numeric changes. Clean/width1/type/renamed controls preserve.

Opt-in Core declared_width_requirements keeps ordered separate declaration and
generated snapshots, lexical scope and observed numeric maximum. Origin, expression,
type and capture stay distinct; no combined symbolic expression or source admission.
Copies/getters detach, failed replacement clears, and registry width/source/type
writes or source-transaction clearing invalidate all records. Getter state anchors
withhold private divergence; ordinary objects gain no field. Parser stages actual
declarations/copy events by Signal identity, preserving every contribution to the
legacy numeric max. Deduplication requires whole-snapshot identity; unrecorded
contributions remain opaque. Registry versions/install state revoke stale pending
requirements and primary bindings even after matching-state replacement. Only full
success publishes; invalidation clears every new map. Both sizing orders/copy
chains retain origins. Ordinary unscoped late sizing stays legacy; computed shapes
remain separately owned.

Core binary_operand_max, scoped births, graph rows, source attachments and
complete target/currentness contracts route to `docs/book/src/11a-perl-api-reference.md`
and its linked canonical POD. Exact former paragraph and source hash survive in
`docs/audits/mdbook-i2c-check-20261031/qualification.json.gz` under `routed_prior_card`.

I2C's original literal selector required inline shifts unsupported by its source
capture. Fixed inline shifts now retain full amount fences but exclude amount
widths from data floors; parser-owned marking/sizing preserves original births.
Actual sampled-storage LHS identity joins sources absent from module membership.
Fixture alias `reg` also collided with a target keyword; it is `sampled_reg_addr`.
Proof/boundaries: the same API/POD; replay: `scripts/run_with_ram_guard.sh -- python3 -B docs/audits/mdbook-i2c-check-20261031/qualify.py`.

Primary/auxiliary bindings derive from that same current requirement map; no
pending-primary bypass exists. One requirement must match actual legacy source,
width and absent type through Core coherence. Chains preserve original declarations;
static/type/parameter namespaces and width1 captures stay distinct. Independent or
opaque requirements, including equal-default repeated primary declarations, withhold
a single binding. Retries use current lexical declarations; inherited larger floors
remain opaque. Final event versions preserve copies and reject stale replacement.

Late sizing retains next(data_r) and q(next_data) at next_data_r; the old fresh,
blanket and preserve-all failures remain in the scoped-late-width audit. Immediate copy_origin
attestation (.3.3.1.2.2.3.3.3.2.1) records actual edges separately from original
identity. Capture requires source-object equality with the registry key, never just
name/width. Chains replace immediate origin, retaining original declaration/capture;
absent/null older fields, declarations and unexplained floors invent no edge.
Distinct edges retain separate snapshots. Identical complete original captures may
share a binding while retaining every attested edge (T2185); independent/opaque/
unattested combined shapes withhold. Prepared ranges do not admit mixed assignments.
Scoped .2.2 retains authored/other-origin records, replacing only opaque generated
records attested to the same actual immediate source under original lexical scope.
Unknown older records stay conservative. Saved policies are diagnostic prototypes
at their recorded epoch.

Private parse_size_section_in_scope(size_ast, scope) shares copied-scope validation
and final requirement/binding publication. Malformed/incompatible scopes refuse
before mutation. Accepted calls snapshot compatible actual records, clear metadata,
seed revocable events and publish after full success; nested same-scope calls reuse
outer staging. Only opaque generated records attested to the same actual immediate
source replace; authored/other-origin records remain, and unexplained larger floors
stay opaque. Scalar/list/void/no-op contracts preserve; ordinary calls create no
capture context. Failed accepted sizing/publication clears derived records while
preserving numeric/source prefix. Legacy type-order asymmetry is owned by .24 before
.6: early auxiliaries omit Core type metadata; late sizing copies it. Scoped sizing
preserves actual late getters and records the same type origin.

VerilogFamily::WidthExpressionEmitter owns the existing prepared width walk through
WidthExpressionSupport/ParameterBindingEmitter, for explicit direct_module and
composition_top scopes. CompositionWidthEmitter is the narrower top/diagnostic
wrapper. Actual lookup order, static arithmetic folds and width1 vector rank
preserve; foreign targets and unknown/mismatched scopes refuse. Range text retains
no caller graph; composition success/refusal/caller products preserve.

VHDL::WidthExpressionEmitter shares the portable prepared walk in both scopes;
the composition wrapper preserves top diagnostics and declaration/namespace
prerequisites. Integer evaluation checks every intermediate natural bound and
positive final width, retaining mod formatting. Selected roots use the VHDL
ParameterBindingEmitter identifier checks. Composition success/refusal/caller
products preserve, including recursive topology captured as a deterministic
reference graph.

DeclaredWidthBindingSupport proves coherent actual Signal captures against frozen
lookup observations and declared root/path payloads, reusing canonical evaluation
without live namespace selection. DeclaredWidthRangeSupport adapts this graph to
shared target contracts/range text. Selected scalar roots keep actual names,
aliases/repeated order and width1 vector rank; pinned static trees inline subject
to target intermediate checks. Fully static captures retain numeric/rank plans.
Mutable paths, unsupported scalar/type/target profiles, symbol-bearing parameter
payloads and static payloads hiding mutable dependencies refuse. Defaults preserve;
plans retain no Signal/environment owner.

DirectDeclaredWidthSupport's joins/prepare_target_namespace (T2266) are
canonical in the API/book and linked POD. Source/lookup, physical mapping,
numeric/type/state and detachment validate there; namespace alone grants no
semantic/currentness authority.

Opt-in VerilogFamily::DeclarationCapture records actual parameter order, ports,
state/storage/enable/intermediate declarations and allocated typedef names at
existing emitters. Register helpers keep parent/kind (T2186); pulse/enable widths
stay independent. Only completed assembly exposes detached namespace/numeric-type
snapshots. Reset, failed/incomplete/duplicate transactions withhold old/partial
results; no HDL parsing or second pass supplies them. Ordinary/captured artifacts
match authenticated predecessor owners under Date-only comparison.

Verilog-family ports/storage use proved roots/arithmetic and width1 vector
rank, installing the collector each generation. Complete target/emitted-plan
proof refuses late same-default ancestry, stale/combined/namespace and symbolic
system widths. Fixed/type/signed/state/legacy products and static VHDL defaults
preserve. Strict check/SV/Verilog pass width1; the port audit retains its dated
VHDL refusal. Explicit internal storage shares the contract. General computed
shapes/full override/runtime remain successors. Backend retention: .25 and
flattened-backend-owner-cycle; isolated plans retain neither caller target
records nor never-installed physical Core copies.

Current namespace replay:

`prove -Iperl t/2266-direct-target-namespace.t t/2173-direct-width-target-plans.t`.

Guard XOR became NOT because condition capture read Core type `unary_op` and
forced NOT. It now validates the actual opcode, normalizes existing not/neg/pos
spellings and preserves recursive guards (T2189); optional source inversion stays
outside that repair. The original diagnosis is retained in the owning task and
`docs/audits/unary-guard-capture-operators-20261028.json.gz`.

Shift/concat/slice diagnosis and its historical receipts route to the canonical
API/book and `docs/tasks/ISF-REDUCTION-DELIVERY.md`. The exact prior card/hash stays
in `docs/audits/push-readiness-20261025/ahb-selector-proof-20261031.json.gz`.
AHB scalar comparison/not operands wrongly entered the literal data-maximum
selector. The typed selector now stops at those scalar operators, while installed
holders, actual data literals and every physical child keep their proof guards.
Replay T2297 with the retained old-selector adverse control; current contracts
remain in `docs/book/src/11a-perl-api-reference.md` and its linked POD.

Concat contracts: `docs/book/src/11a-perl-api-reference.md`; writer ownership: `docs/tasks/ISF-REDUCTION-DELIVERY.md`.

T1244 wait/shift declared bit, an SV keyword. Literal selection succeeds;
namespace proof refuses. Two source-name substitutions to serial_bit restore
native generation and installed Verilator lint; inverse keyword artifact fails.
Intake/repair: PUBLICATION-REGRESSION-REPAIRS.19. Full/runtime stay open.
