# DEVELOPMENT_NOTES

This bounded current view contains only newly appended engineering rationale.
Historical ranges and exact retrieval are indexed in
[DEVELOPMENT_NOTES_INDEX.md](DEVELOPMENT_NOTES_INDEX.md).

Add an entry only for non-obvious implementation rationale, constraints, or
local tradeoffs that have no better decision, fact, task, user-document,
source-comment, or commit home. Never add a placeholder entry for a slice.

## 2026-08-01: The rationale ledger keeps an immutable source anchor while accepting later entries

The migration fixes the 2,843 pre-cutover entries at clean activation commit
`d3c22e003` and represents that exact body as one descriptor-backed historical
range. The bounded root contains only entries appended after that source
anchor. Reconstruction therefore proves that the immutable source body is the
exact prefix of the ordered ledger, rather than requiring every later append
to rewrite or relocate the source object.

This distinction closes the first-append hole in the generic `.3` topology.
The version-backed source and historical range remain recoverable under the
repository's named full-history retention contract, while an executed local
adapter verifies their dimensions, digests, entry endpoints, ordinal closure,
current suffix, and complete reconstruction. Future rotation may seal or
archive later whole-entry ranges without changing the original source anchor.
## 2026-08-01: Chapter 14 partitions by topic while keeping the mandatory read shallow

The partition uses thirteen direct Chapter 14 pages rather than nested or
equal-sized shards. `SUMMARY.md` started at 39 lines, so twelve additional
direct members leave it at 51 of its 64-line ceiling and below the 80% warning
boundary while preserving navigation depth one. Topic boundaries also keep
the largest new page below 2,800 lines and 200 KiB without raising a limit.

The ranges follow language/data, composition, actor orchestration, IAL2,
HIAL/VIAL, AXI, APB, AHB, ISF, backend, validation, and API concerns. Two
chronologically separated HIAL/VIAL and APB ranges are reunited in their
semantic homes; within each range, original order and bytes remain unchanged.
The landing page retains the established backend deep-link as a compatibility
route. This keeps future edits discoverable by subject instead of reviving a
single chronological monolith.

## 2026-08-01: The roadmap archives the whole activation object, not only its chronology suffix

The bounded roadmap rewrites strategic material as well as removing the
9,354-line `Current intent` chronology, so its durable proof names the complete
10,451-line activation object. This avoids pretending that paraphrased
workstream and horizon prose is byte-preserved. One exact Git descriptor covers
every original line, while a six-range disposition states which ideas remain
live and which roles now route to task trees, the mdBook, decisions, and Git.

The live view keeps product objective, principles, `R8`–`R14` direction,
dependencies, concise milestone outcomes, current-state routing, and
`H1`–`H6` horizon intent in 317 lines. Derived 640-line / 64-KiB / 512-byte-line
bounds leave deliberate growth room without restoring the former transition
ceiling. An executed verifier binds the descriptor to exact history and rejects
missing strategic sections, missing canonical routes, pressure regression, or
a revived `Current intent` chronology sink.

## 2026-08-01: Focused-document containment separates browse topology from source membership

The root `docs/*.md` collection remains a fixed membership surface, while its
complete classification index lives at `docs/index/FOCUSED_DOCUMENTS.md` under
a separate generated-projection surface. That avoids making the index count
itself or requiring a thousand-path registry record. One deterministic
generator expands the two registered source collections, assigns every member
exactly once by audience/lifecycle/owner/role, and rejects unknown filenames.

The ISF language, downstream, and public contracts form a distinct
`maintained_reference` over bounded landing pages and eleven semantic parts.
Partition selection considered every pressure axis: the public contract was
below the line target but above the byte warning, while the root collection's
aggregate and file-count warning states remained independent. Exact activation
comparison permits only six declared link rewrites, each replacing a removed
test path with its surviving owning task record; all other source text changes
only by the deterministic one-directory link adjustment.

## 2026-08-01: Native UVM result collection is generated structure, not result evidence

Revision 4 deliberately keeps the checking/result package separate from the
normalized runtime-result artifact. Coverage, models, the scoreboard, fault
application, property checks, and diagnostics can therefore be reviewed as
ordinary generated UVM while the backend manifest still reports
`runtime=not_run` and `result=not_produced`. Sealing the generated collector
creates only an in-memory structural snapshot; it cannot satisfy the portable
result contract or parity gate.

The same boundary applies to observation. Public-port checks may be wired in
the review gallery, but verification-probe-backed expectations remain
source-mapped until a qualified adapter supplies the probe value. The private
RAL preview is not silently promoted into runtime observation authority.

## 2026-08-01: Native UVM matrix closure is selected-scope accounting, not qualification

Revision 5 treats the backend manifest's emitted-foundation list as a set that
must equal the mapping matrix exactly. Each foundation then records three
entry authorities—normal source, terse source, and typed IR—separately from
generated roles and four independent maturity states. This prevents a private
typed preview, compiler-owned topology, public source route, or structural
check from being mistaken for one another.

Review is reproducible but still judgment-bearing. The gallery generator owns
the canonical nine source and two JSON evidence snapshots; `--check` performs
an exact non-mutating comparison and rejects missing, extra, or drifted files.
That automation does not set visual review to passed. Human or delegated
findings remain durable only when they identify the artifact, generated
symbol, source-map ID, observation, severity, reproduction, expected intent,
and disposition in the owning task-tree.

## 2026-08-01: Experimental UVM workflow success is not fixture success

The reusable probe completes successfully when it has measured and classified
every selected stage, even if an inner stage is unsupported or fails. This is
why the canonical envelope reports `probe_completed=true` and
`partial_tool_limited` while generated-fixture parsing is unsupported,
compile/elaboration reaches a tool internal fault, and runtime is not run. A
nonzero tool stage remains durable evidence rather than turning the whole
probe into an opaque host error.

The isolated minimal UVM control is intentionally separate. Its passing
compile, elaboration, and zero-error runtime prove the exact Verilator/library
pair can execute UVM, which makes a later full-fixture diagnostic meaningful;
they do not qualify generated source. Strict fixture parsing runs before the
`--bbox-unsup` attempt so a generator syntax error cannot be hidden by a tool
workaround. `UVM_NO_DPI` and unsupported-feature blackboxing are explicit
deviations and cannot become canonical source conditionals.

Host compilation is also evidence-bounded. One build job and one Verilator
thread did not keep the initial optimized build inside the selected guarded
host envelope. `-O0` is therefore part of the exact feasibility argv: runtime
performance is irrelevant to the control, and the lower-memory build passes
the repository guard. Transcript identity removes
variable wall/resource measurements and hashes the control runtime's semantic
marker/error/fatal/finish proof, so an independent rerun is byte-stable.

## 2026-08-09: VHDL qualification identities include the GHDL code-generation backend

GHDL's version alone is not a sufficient runtime identity for this fixture.
The exact 6.0.0 macOS ARM64 LLVM AOT build analyzes and elaborates the selected
source set, but its VHDL-2008 external-name adapter dereferences null at
runtime. The matching exact LLVM-JIT build executes the same adapter and passes
the full bounded qualification. Support evidence therefore freezes the release
commit, backend, archive and binary hashes, complete version output, source
set, and commands; it cannot generalize a JIT result to AOT.

The executable gate also exposed a scheduler boundary that structural review
could not prove. On AHB's returning-ready sample, a previously stalled transfer
may be accepted and completed together. Portable VHDL must use that same
sample for both facts, as the qualified portable-SystemVerilog scheduler does,
and must hold an error transaction until the complete two-cycle response has
settled. Encoding those rules explicitly prevents repeated transfers and
double-counted outcomes without making HDL process or delta ordering semantic
authority.

## 2026-08-09: Exact OSVVM identity is a recursive graph, not a release label

The `2026.05` superproject tag alone cannot identify the provider used by a
generated advanced adapter. Qualification must freeze the superproject and all
thirteen gitlinks by commit, tree, origin, and tracked-entry count, then prove
every worktree clean before provider-dependent emission. The verifier remains
offline during emission so an existing exact repository-local graph is the
only accepted input; fetching and execution evidence stay separate actions.

Legal metadata is also an observed property of each pinned repository, not an
inference from the aggregate project. Fourteen tracked Apache-2.0 licence files
and zero notice files are locked exactly. The Documentation gitlink has neither
a tracked licence nor a notice, so FSMGen records that absence without claiming
coverage. This upstream packaging gap does not alter or block the code-bearing
adapter, but it remains visible for any future redistribution decision.

## 2026-08-09: Provider reports supplement portable semantics; they do not replace them

The exact combined profile compiles OSVVM from a frozen resolution of its own
2026.05 project files: 44 core sources and 17 VHDL-2008-compatible Common
sources. This avoids a hidden mutable library installation and keeps every
work library, generated settings body, report, and log inside one digest-named
repository-volume stage. The settings body is generated only inside that stage
and all qualification outputs are removed after their evidence is validated.

One dedicated provider probe is enough to distinguish API presence from useful
execution evidence. It runs OSVVM randomization, coverage, scoreboard,
reporting, memory, and barrier services through the generated adapter; the
Common address-bus type is analysis-qualified because no provider transaction
is part of the selected fixture. Four deterministic OSVVM YAML reports remain
supplementary. FSMGen's unchanged closed trace, normalized result, and nineteen
portable parity paths retain semantic authority, preventing provider-specific
reporting or scheduling from redefining VIAL behavior.

## 2026-08-10: Nominal bridge limits require a reachable canonical profile

The manifest schema's defensive array caps are not proof that the fixed first
AHB annotation can reach them. Its exact validator correctly admits one
transaction, six events, one probe, and five residue records. A later scale
catalog selected wider candidates without selecting the missing canonical
route; repeating or mutating the AHB result would manufacture evidence.

Bridge-scale qualification therefore uses a separate closed direct-IAL1
profile. Generated `.isf` must survive the ordinary parser, scheduler report,
and `.fsm` lowering before the shipped bridge builder sees it. The AHB profile
does not widen, and a source-map or serialized-byte cap that dominates a
nominal structural count is reported as the result rather than bypassed.

The implemented generator scales representation with reachable semantic
records, not comments or forged reports. A baseline qualification manifest has
221 source-map records; each configuration contributes 28 and each retained
residue contributes five. Those measured increments permit an exact 8,192-
record gate and exact valid 49,152/65,536 shapes. The latter two cross the
already authoritative 16-MiB canonical-report cap, so their correct result is
the earlier serialized rejection; 65,537 still rejects at the source-map cap.

Canonical byte profiles combine real configurations, residues, observations,
and one referenced logical width to produce exactly 1,048,576, 4,194,304, and
16,777,216 JSON bytes. The next complete representable logical width crosses
the cap. This calibrated construction is deliberately path-identity-sensitive:
repository-relative authored paths participate in the report, so changing a
path requires recalibration and the exact-byte oracle will fail rather than
silently weakening evidence.

## 2026-08-10: Scenario-local ranks do not imply scenario-local source-map paths

VIAL static operation ranks restart at zero for each scenario by design; tie
breaking is scenario-scoped and operation IDs already include the scenario.
Execution-plan source maps are different: their `plan_path` addresses the one
flat `operation_graph.operations` array and must therefore use a global index.
The original builder conflated these two coordinate systems, so every scenario
after the first reused `/operation_graph/operations/0...` paths.

The scale scenario gate made the collision unambiguous: 32 real operations
produced only one distinct operation-map path. The builder now records each
scenario's global operation offset before emission and adds it only when
forming source-map paths. Static ranks, operation IDs, successor chains,
logical time, and backend meaning remain unchanged. Exact regressions require
one unique global source-map path per operation; because this changes canonical
plan identity, all byte-locked galleries and exact VHDL qualification reports
must be regenerated and requalified together.

## 2026-08-10: Total fibers and live fibers need different parallel shapes

A single 127-child parallel would prove 128 allocated fibers, but it would also
make all 128 live and entangle two independently selected scale axes. The gate
recipe instead limits each sequential group to 31 children. Five groups with
31/31/31/31/3 children retain exactly 128 total fibers while the root plus the
widest group produces exactly 32 live fibers, matching the separate gate value.

Live-width scaling has the opposite constraint: every selected descendant must
be structurally concurrent, while one semantic parallel can contain at most 256
fibers. A two-level tree makes that representation extend to the selected high
levels without widening parser limits. At the gate level, two outer fibers—one
containing a 29-child nested parallel—produce exactly 32 total and live fibers.
The builder remains unchanged; exact tree, join, operation, parent, successor,
phase, map, and identity oracles keep both constructions honest.

## 2026-08-10: Execution-type scale must use every shape through a real binding

`ExecutionBuilder` deduplicates its type table by canonical semantic shape at
the point a representation relation or value actually uses the type. Merely
declaring 512 aliases, or creating 512 bridge types that VIAL never binds,
would therefore be a false scale witness. The gate uses 512 public direct-IAL1
inputs and matching VIAL endpoints at widths 1 through 512. This gives each
four-state unsigned logic shape one semantic identity, one carrier identity,
and one exact-width drive proof through the unchanged public binder.

Optional metadata readers must also preserve absence. The scale helper once
read `verification_bridge.probes` without first checking that
`verification_bridge` was a hash. Perl autovivified the absent annotation to
`{}` after the scheduler had reported `null`, and the canonical bridge rightly
rejected the actor/report mismatch. Guarding the optional hash before probe
collection keeps ordinary non-annotated IAL1 ordinary; it does not weaken the
bridge identity check or introduce a private admission.

## 2026-08-20: Knowledge-card partitions need family-explicit parity scopes

A bounded fact card can be partitioned without losing retrieval semantics only
when its complete source remains exactly recoverable and its answer keys are
proved equal across the replacements. The VIAL execution-scale card therefore
uses a commit-pinned version object plus deterministic route/gate and per-axis
materializations. Current prose stays small; the complete earlier narrative is
still byte-retrievable; and every old question resolves to exactly one new
card.

The existing history verifier had encoded its two original families by
negative matching: IAL2 paths were one family and every non-IAL2 generated path
was assumed to be VHDL. Adding VIAL exposed that assumption before it could
silently mix answer sets. Parity checks now receive explicit replacement path
sets for each family. Future partitioned families must add their own source
identity, classifier, replacement paths, and routing checks rather than enter a
catch-all group.

## 2026-08-20: Source-free envelope rejections need canonical failure reconstruction

An unconstructible source-map level validates the caller's checked-AHB text
before the generic workload constructor rejects the oversized generated VIAL,
but the rejection record intentionally retains neither input. Re-validating
that record therefore cannot reconstruct from retained source as accepted
checked-AHB levels do, and retaining the HIAL only for later validation would
weaken the no-source rejection contract.

The validator instead rebuilds the exact generic input-1 envelope failure from
a minimal empty HIAL input and a deterministic one-byte-over-envelope VIAL
input, merges the catalog-derived specification, and byte-compares that closed
record with the caller's. The real checked-AHB source remains constructor-time
authority; the durable rejection remains source-free; and later evaluation or
build calls still reject any mutated diagnostic, requested count, or record
shape without regenerating multi-megabyte source.

The generator's owned-shape projection also remains distinct from the workload
catalog. Closing the source-map ladder raises selected owned shapes from 37 to
40; the catalog still has 65 shapes because 25 deliberately non-selected
profiles remain fail-closed. Tests must derive and compare those sets, not
equate “all selected levels are implemented” with “every catalog shape is
owned.”

## 2026-08-20: A zero-owned scale foundation needs a sealed candidate seam

Checking-state infrastructure must prove its canonical source-to-plan route
before an axis renderer is trusted, but using a selected gate as the foundation
would falsely publish ownership and using `reference_v1` would turn a catalog
record into a generated scale shape. The module therefore publishes an empty
owned-shape set and rejects both cases through its public constructor. A
same-package-only candidate seam accepts only generated ordinary VIAL text and
the exact checked-AHB source; later owned renderers can call it, while external
callers cannot inject SemanticIR, bridge, ExecutionIR, trace, result, or support
metadata. Defensive validation regenerates the candidate from its retained
source bytes before any canonical producer runs.

The foundation report also reserves the final top-level evidence shape before
an oracle lands. Model, scoreboard, coverage, fault, and random/replay
compartments begin null under a versioned closed schema, and the foundation
outcome is explicitly `accepted_not_axis_evaluated`. This lets later leaves
populate an exact axis compartment without silently widening report v1 or
equating the checked-AHB reference observations with a selected scale count.

## 2026-08-20: Model-state source factorization must preserve the expanded oracle count

A high scalar-state level cannot be represented by one enormous definition
without needlessly spending the source envelope, while a compact declaration
alone would not prove that every instantiated cell is exercised. The model
scale renderer therefore factors 512, 32,768, and 65,536 cells across 32 model
instances with 16, 1,024, or 2,048 state declarations per shared definition.
The 65,537 adjacent excess adds one separate one-cell definition and instance,
so it reaches the exact execution-resource boundary without changing any
accepted recipe.

The provider-free oracle expands the canonical ExecutionIR instance/definition
pairs again rather than trusting renderer arithmetic. It validates every known
u8 zero-to-one assignment, derives each bound event, commits and reads every
expanded cell, and compares packed state with independently sized all-zero and
all-one vectors. Source compactness therefore changes representation cost, not
semantic proof strength.

## 2026-08-20: Scoreboard scale separates authored structure from varying FIFO state

The scoreboard-instance ladder reuses one capacity-one definition across every
instance, while the capacity ladder uses one definition and one instance. This
keeps ordinary VIAL source proportional to authored topology and lets the
one-million-capacity level remain a four-line semantic shape rather than a
million-operation scenario. The provider-free oracle still derives definition,
binding, policy, capacity, and complete transaction fields from canonical
ExecutionIR, so compact source does not bypass the public producers.

Only the varying unsigned 32-bit payload is stored in the qualification FIFO.
The other five transaction fields are reconstructed at comparison time, every
field is checked, and expected and actual queues drain in order. Thus the exact
state cost is four bytes per entry while the semantic proof remains over
complete transactions; mismatch, at-capacity enqueue, and byte corruption are
separate negative obligations rather than inferred from a matching digest.

## 2026-08-20: An all-hit vector needs a separate authored-order identity

The selected coverage sample intentionally hits every authored bin and static
cross tuple, so its packed vector is all ones. That vector proves exact domain
cardinality and hit completeness, but it cannot by itself prove ordering: every
permutation of an all-one vector has the same bytes and digest.

The coverage oracle therefore streams a second identity over length-delimited
bin IDs followed by authored cross-tuple ID combinations. One stream comes from
canonical ExecutionIR; the independent stream comes from the selected source
recipe. Their byte-equal digests prove order without retaining a million JSON
identities, while a first-two-entry swap proves the comparison rejects order
mutation. The million-entry bit state remains bounded at 125,000 bytes; the
order proof closes a different semantic obligation rather than inflating that
state representation.

## 2026-08-20: Fault scale needs streamed lifecycle identity, not retained event records

Fault qualification must prove four ordered state changes per declaration:
arm, apply, expire, and restore. Retaining every transition as a report record
would make the evidence shape scale with the selected limit and would duplicate
canonical declaration data already present in ExecutionIR.

The fault oracle therefore streams length-delimited transition tokens into one
SHA-256 identity while independently reconstructing the same stream from the
selected source recipe. It retains only the digest, exact transition count, and
first-arm/last-restore endpoint witnesses. A separate declaration-order digest
prevents the lifecycle digest from hiding reordered declarations, and explicit
reinjection, overlap, substitute, and order mutations prove each comparison
fails closed. The 4,096-fault limit thus proves 16,384 lifecycle transitions
without turning the evaluation report into another execution trace.

## 2026-08-20: Random scale counts references and separates proof from materialization

A random occurrence is the semantic reference from one scenario to one choice,
not the declaration of that choice. The scale renderer therefore reuses a
bounded 128-choice Boolean palette across as many real scenario references as
the selected count requires. Compact source is still ordinary VIAL, and the
oracle derives each keyed decision from canonical ExecutionIR before comparing
independent generation, strict replay, and their origin-free plan forms.

The higher selected counts cannot honestly be treated alike. The 32,768 route
materializes SemanticIR and the bridge before the plan-byte cap rejects it;
65,536 is already dominated by that proved route boundary and is deliberately
not materialized or counted; 65,537 must still traverse semantics because its
random-occurrence diagnostic wins before plan serialization. Frozen
target-neutral identity lengths and timeout metadata reproduce the exact
decision-0073 gate and adjacent plan-byte witnesses, but do not add operations,
caller-created plans, or opaque plan padding. This keeps the evidence exact
while distinguishing semantic occurrence proof from resource materialization.

## Claim migration closure uses source-cohort identity digests

The original doctrine-constant cohort must remain recoverable without freezing
values that are supposed to be re-derived as the repository evolves. A copied
list of every value would create a second hand-maintained authority, while a
single aggregate digest would not identify which source lost an entry.

The closure contract therefore records one bounded identity digest per
original source, together with its last original record boundary and constant
count. Identity is the source path, record line, and structured pointer; the
value is deliberately excluded. Current generation must reproduce every
original identity and then apply today's producer, falsification oracle, and
watcher policy. Schema versions are configured input identities under that
policy, not exempt incidental leaves. Candidate migration ownership is likewise
derived from the current disposition join, so closed work cannot retain a
stale owner and genuinely new work cannot appear ownerless.

## 2026-08-21: Provider preflight reuse is a scoped capability, not a cache

Exact OSVVM verification walks a recursive provider graph and is immutable for
one synchronous backend evaluation, but a process-global cache would make
filesystem drift, test isolation, and caller-supplied evidence difficult to
reason about. The advanced VHDL backend therefore verifies at evaluation entry
and registers one opaque scalar capability only for the duration of a callback.
The lexical registry holds the verified result, dependency root, canonical
identity digest, and the original token; callers receive none of that evidence.

Each accepted local emission receives a fresh defensive clone. The root must
match, the token identity must still be registered, and the protected evidence
digest must remain exact. Registry deletion happens before either a successful
callback result or a sanitized callback failure is returned. Consequently a
retained handle is stale, a separately blessed object cannot forge authority,
and mutation of one emitted result cannot contaminate the next. Standalone
emission deliberately retains independent verification, keeping this reuse an
explicit evaluation boundary rather than hidden ambient state.

## 2026-08-21: A frozen identity cohort needs a frozen source domain

The first constant-cohort closure stored a line boundary plus an identity
digest for each source, then reconstructed membership from the current JSONL.
That works only while historical lines never gain new nested numeric leaves.
The live-document debt schema permits exactly that evolution, so the line
boundary was a location bound rather than a stable membership authority.

The corrected contract retains the compact boundary/count/digest records but
derives their members from the exact claim-inventory adoption commit. Current
JSONL is scanned separately: every historical identity must still exist, while
new identities are allowed regardless of their record line. Values stay out of
the frozen identity because their current producer and oracle are authoritative.
This separates immutable cohort membership from the intentionally evolving
current census without creating a copied list of values or a rebaseline path.

## 2026-08-21: Wrapper source maps translate identity instead of replacing detail

An additive backend wrapper owns new generated artifact paths without owning a
new, coarser account of the reused source semantics. Replacing each reused file
with one whole-file map discards the portable emitter's operation, scenario,
fiber, model, endpoint, scheduler, checking, and probe correlations even when
the file bytes themselves remain exact.

The OSVVM wrapper now treats the portable source map as evidence that must be
validated before it can be translated. Its closed schema, six artifact refs and
digests, path-derived map identities, line/column bounds, unique entries, and
complete source coverage must agree with the byte-identical portable sources.
Each accepted entry keeps its semantic payload and order while its generated
path and path-derived identity move into the wrapper namespace. The seven
adapter-native entries stay first. This makes source reuse compositional:
wrapping changes artifact identity, not the granularity of source truth.

## 2026-08-21: A fixed review renderer needs closed shape negotiation

The native-UVM emitter intentionally implements one selected review gallery,
not general ExecutionIR breadth. A negotiation that checked only the presence
of one start, transaction, decision, and probe could accept additional public
expectations even though the fixed renderer did not emit them. The artifact
bytes and detailed mappings therefore looked successful while authored intent
had disappeared.

The backend now admits the whole selected operation shape as one capability:
the 21-operation sequence, its 12/9 scenario partition, four/three fiber
bounds, matching resource total, and the ten ordered expectation roles. One
predicate and one unsatisfied reason keep all unsupported shapes on the same
pre-render failure path. This is intentionally a semantic support boundary,
not a byte-capacity boundary; broadening the renderer later must broaden the
predicate and its evidence together.

## 2026-08-21: Backend scale facts need one closed structural authority

The backend-emission workload catalog and capability discovery describe the
same private emitter graphs but previously repeated their facts independently.
That allowed three different kinds of ambiguity: a source count could be
mistaken for a total artifact count, a wrapper's total bytes could be mistaken
for its portable foundation's enforced cap, and a large enforced cap could be
published without the much smaller selected shape that makes it unreachable.

`BackendEmissionAuthority` now owns one exact profile-local projection and
returns only defensive copies after closed-field validation. Workload
construction and support discovery consume that projection rather than
parallel literals. The schema deliberately distinguishes caps from selected
reference counts and separates OSVVM's portable sources, wrapper adapter, and
provider identity. A future authority change must therefore update one source
and its executable re-derivation; an unknown, missing, obsolete, or
contradictory field stops before generator work can consume it.

## 2026-08-22: Balanced portability is a qualified route, not a widened scale bypass

The balanced workload needs a bridge shape that neither the fixed AHB contract
nor the private-nonportable revision-1 scale contract can express. Relaxing
either validator would erase an already-qualified boundary, while adding the
private capability to a backend allow-list would confuse availability with
semantic qualification.

Decision `0077` therefore adds a distinct revision-2 direct-IAL1 profile behind
three independent controls: exact bridge construction, exact execution
admission, and backend-specific portable-SystemVerilog negotiation. The profile
must carry 16 transaction aliases with 109 real endpoint-backed fields each;
the resulting 1,744 fields combine with the other selected resources to derive
2,048 bindings with no padding. Existing public builders and support discovery
remain unaware of the private route. This design keeps scale infrastructure
useful for interaction proof without promoting it into a product protocol or
general portability promise.

The canonical composer keeps that separation operational. It accepts only the
frozen checked-AHB references, regenerates its balanced HIAL/VIAL sources, and
runs one fresh substantive gate from each completed architecture-scale family
before the private revision-2 route is reachable. It never accepts caller-
supplied gates, intermediate IR, manifests, plans, requested metrics, or
reports. Evaluation then reconstructs the complete source-to-plan projection
twice and a strict keyed replay once, so determinism, report content identity,
and replay equality are independent outcomes rather than trust in a cached
route. Portable emission remains another caller-sealed negotiation boundary;
composition success alone cannot promote the profile into emitter or product
support.

## 2026-08-22: Balanced emission qualification is full-shape admission

The portable-SystemVerilog backend does not treat the revision-2 capability as
an allow-list token. Its private qualification entrypoint independently checks
the bridge manifest, ExecutionIR resources and relations, known values,
operations, and canonical backend inputs before rendering. The public emitter
continues to reject the profile, which makes accidental product exposure a
separate, evidenced decision rather than a side effect of scale work.

The structural oracle owns the complete artifact graph and verifies operation
and binding source-map coverage, identifiers, identities, byte-equal reruns,
atomic failure, and repository-volume cleanup. It deliberately ends before an
external compiler or runtime. During implementation, explicit
`sort(_unique(...))` calls replaced ambiguous Perl `sort SUBNAME LIST` parsing;
canonical evidence ordering must be syntactically unambiguous at every sealed
boundary.

## 2026-08-22: Unified qualification retains child authority instead of flattening it

Runtime-stream reports and balanced structural-emission reports intentionally
use different stage vocabularies and evidence shapes. Converting both to one
small generic report would discard profile-specific command, limit, artifact,
and oracle authority precisely where the measurement handoff needs it most.

The unified qualifier therefore embeds each complete closed child report and
adds only content identities plus a normalized navigation matrix. Canonical
validation regenerates the entire ordered family from checked source bytes, so
the embedded evidence is neither caller-injected nor trusted by digest alone.
The matrix records cross-family completion without pretending that a balanced
structural emission is equivalent to a runtime member's future compiler or
simulator work. This costs more validation time, but it keeps the handoff
auditable, extensible by explicit schema revision, and honest about every
deferred stage.

## 2026-08-22: Measurement workers own outputs while the controller owns evidence

A stage callback must be isolated enough that a timeout can terminate its
whole descendant tree, but measurement cannot trust a callback's self-reported
resource use or output inventory. The foundation therefore forks one worker
per stage and gives it one disjoint `outputs/<stage>/` subtree. The parent
samples the controller and live worker tree, validates the stage's reported
files against that subtree, then validates every file in the aggregate owned
root. This permits later leaves to compose multiple stages without mistaking a
prior stage's artifact for unreported output or allowing a callback to certify
its own census.

The RAM-guard wrapper remains the enforcement authority. Its child environment
contains only an active marker and the effective host/descendant thresholds so
the report can bind the envelope actually in force; setting those values does
not reproduce the monitor. Raw 250-ms samples are retained because descendant
CPU and RSS can undercount short-lived processes, and that limitation stays
explicit instead of becoming a synthetic zero. Validation executes correctness
without retaining performance, while measured ordinals require matching
workload, Git, dirty-state, and host evidence from the preceding validation.
These boundaries let backend-specific leaves add qualified commands later
without weakening cleanup, identity, guard, or artifact authority.

## 2026-08-22: Canonical family evidence needs a path-safe measurement projection

The semantic and bridge family evaluators already own complete canonical JSON,
including diagnostic fields named `path` whose slash-leading values are
semantic pointers. Embedding those hashes unchanged in the generic measurement
record would make them indistinguishable from forbidden machine-local absolute
paths. Weakening the measurement foundation's recursive path rejection would
allow an unrelated worker to leak host paths under the same generic key.

The family adapter therefore retains the original canonical evaluation bytes as
a stage-owned, content-addressed artifact and embeds a separate deterministic
evidence projection. The projection recursively renames only keys exactly equal
to `path` as `semantic_path`, rejects a hash that already contains both names,
and changes no value or other key. Independent report validation regenerates
the family evaluation, the projection, and the original artifact census. This
keeps family authority byte-exact while preserving the generic measurement
schema's stronger host-path boundary.

## 2026-08-22: Long scale matrices publish complete profiles before completion claims

A multi-hour matrix cannot make its only durable transition at the final
profile. A process or machine interruption would otherwise discard already
validated raw records, encourage an unsafe rerun over partial output, or tempt
an operator to describe incomplete evidence as a completed matrix.

The semantic/bridge runner therefore gives each canonical profile set its own
immutable atomic publication. A retry independently reloads the whole report,
re-proves the family adapter, and accepts it only at the same clean Git and
common host/tool/guard identity. Existing different bytes collide, and
ambiguous crash staging remains visible instead of being guessed safe to
delete. Family manifests are withheld until every owned profile validates;
the complete manifest is withheld until both family manifests share the same
identity. This makes interruption recovery cheap without weakening raw-sample,
earliest-cap, or no-partial-completion truth.

## 2026-08-22: Boundary measurement repairs canonical work, not safety contracts

An exact-limit workload that exceeds its measurement timeout is not permission
to enlarge the timeout or replace meaningful source with padding. The first
semantic combined-byte boundary exposed two independent problems: generic
adapter validation re-executed a rejected stage and masked the controller's
timeout diagnostic, while valid wide four-state declarations took a quadratic-
feeling path through per-character lexer bookkeeping and repeated arbitrary-
precision binary-to-hex conversion.

Failed family stages are now validated as failed evidence: command and input
identity remain exact, outputs/oracles/artifacts must remain absent, later
family stages must be explicitly `prior_stage_failed`, and the original
foundation diagnostic remains authoritative. Successfully completed stages
still undergo full canonical rederivation. The parser validates UTF-8 first,
then uses byte-oriented chunk cursors only for proven-ASCII input; non-ASCII
  input retains Unicode-scalar columns and source-byte offsets. Four-state value,
known, and Z masks use linear transliteration plus binary pack/unpack instead
of three `Math::BigInt` conversions. This preserves the ordinary referenced-
declaration fixture, semantic identities, source spans, and the fixed safety
ceiling while removing implementation overhead at its owners.

## 2026-08-23: Source-free matrix reports need capture provenance, not borrowed measurements

Execution/checking scale includes canonical shapes that are intentionally
unconstructible before a workload identity exists. Their reports correctly
contain no common-controller validation record. A long resumable matrix still
has to prove that every immutable child belongs to one clean revision, host,
tool, and enforced guard; deriving that provenance from a nonexistent record
would be impossible, while copying a neighboring measurement identity would be
false evidence.

The execution/checking publisher therefore wraps every complete report in a
closed, content-addressed profile-publication envelope. Controller-backed
profiles establish the common capture identity from their own records. Later
source-free profiles inherit only that capture provenance in the envelope,
while the nested canonical report remains identity-free. Inventory order begins
with a constructible gate, every subsequent profile and both family seals must
match the common identity, and capture rechecks that the clean revision did not
change before sealing. This preserves resumability and revision truth without
widening the measurement schema or manufacturing work that never occurred.

## 2026-08-23: Interrupted measurement staging needs ownership before recovery

A guard or machine termination can stop the controller before its ordinary
cleanup block runs. Because a raw sample uses one deterministic staging path,
blindly deleting that path on retry could destroy a live concurrent run, while
rejecting every pre-existing directory would make profile-level resumability
stop at the first interrupted raw sample.

The foundation now acquires a nonblocking exclusive advisory lock keyed by the
exact repository-relative staging identity. The stable zero-byte lock lives on
the repository volume outside ephemeral staging, has a verified regular inode,
single link, owner, device, and close-on-exec descriptor, and remains held by
the controller and its forked worker until the run ends. A retry that obtains
the lock recursively admits only real directories and same-volume,
single-linked regular files before removing the orphan, pruning empty owned
parents, and creating a fresh stage. Symlinks, FIFOs, hard links, volume drift,
and live contention reject without reclamation. The real guard-interrupted
execution-bindings gate sample proved this route: recovery occurred at ordinal
three and the replacement report retained three samples, zero exclusions, and
zero residue. Persistent lock files are coordination identities, not partial
measurement evidence, and therefore remain outside `.artifacts/tmp`.

The same proof exposed an older test assumption that an injected publication
failure could remove the entire shared qualification namespace. Rollback now
proves absence of its exact target and removes only parents it created; a
pre-existing semantic/bridge evidence namespace must remain untouched.

## 2026-08-23: Exact profile isolation must preserve revision truth

Loading and fully regenerating a sequence of large execution/checking reports
in one Perl coordinator releases the logical values but not necessarily the
allocator's high-water heap. Restarting that coordinator does not solve resume:
validating the same immutable prefix recreates the same retained high-water
state before the next profile begins.

Capture, resume, and later family/complete revalidation therefore put each full
report lifecycle in a separate guard-visible child. The child performs the
existing adapter regeneration and atomic publication/reload checks, reduces the
report to one compact entry, and returns it through a close-on-exec pipe. The
parent admits only canonical JSON under a fixed byte ceiling and rechecks a
closed operation/profile/status/common-identity/artifact shape; exits, signals,
exceptions, malformed or noncanonical bytes, and oversized results fail closed.
This bounds allocator retention without weakening the outer guard or trusting
an immutable report without full validation.

The implementation commit also changes the clean Git revision. Nineteen reports
captured before the repair remain valid evidence for isolated revalidation, but
their revision cannot be relabelled or mixed into the repaired revision's
common-identity seal. They must be hash-verified and retained in a revision-
keyed repository-volume archive, after which the repaired clean revision earns
its own fresh complete-matrix capture. Preserving provenance takes precedence over a
superficially convenient resume claim.

## 2026-08-23: Bind-plan determinism must not multiply canonical admission

The execution/checking adapter has two distinct determinism boundaries:
canonical admission evaluates a producer twice, and the isolated stage worker
runs each payload twice. Calling the admission helper from each bind-plan
payload accidentally multiplied those boundaries. The valid million-attempt
profile therefore spent its fixed stage lifetime repeating already independent
work and timed out even though the canonical producer, replay, and preceding
stages were correct.

One closed helper now validates a single producer result. Admission invokes it
twice and compares the results; each bind-plan payload invokes it once, compares
against admission, and is still rerun by the worker. The random generator's hot
loop separately hoists only immutable digest-prefix and counter encoding and
uses full-space range algebra only where modulo and rejection are identities.
This preserves layered independence, algorithm bytes, fixed vectors, attempt
ordinals, plan/replay identities, and the normative timeout instead of trading
correctness checks for benchmark headroom.

## 2026-08-23: Exact plan preflight is a bounded two-pass projection

The serialized-plan cap cannot be moved earlier by estimating average random
record size or by hard-coding the known 8,440/8,441 boundary. Decision records,
scenario occurrence IDs, and random source maps are three separate canonical
arrays, while replay validation and random exhaustion must retain precedence
over plan size. The builder therefore streams one fully validated would-be
decision at a time through the canonical JSON encoder and accumulates exact
element and comma deltas over a shared-report base plan. Saturating arithmetic
bounds the count without stopping semantic validation.

Preflight deliberately retains neither the decision list nor the random
source-map suffix. An accepted plan consequently performs a second
deterministic generation/replay pass for ordinary materialization; terminal
canonical bytes must equal the projection and still meet the original limit.
This spends CPU to keep the known-excess path memory-bounded and makes the
terminal serializer a defense-in-depth oracle instead of a second schema
implementation. The base-plan seam is private to `ExecutionBuilder`, so the
optimization does not become a caller-supplied plan or public report API.

## 2026-08-24: Semantic repair takes precedence over a cosmetic scale boundary

The portable-SystemVerilog scale oracle was frozen before later scheduler and
direct-drive correctness repairs changed generated source. Re-deriving all
levels showed that the change is topology-sensitive, not one fixed byte delta,
and moved the exact 16-MiB boundary from 6,319/6,320 operations to
6,318/6,319. The first rejected shape is only 146 rendered bytes over the cap.

The renderer already conditions its added rollover on a genuine backward
logical-phase transition. Removing it would restore the trace-order defect,
while shortening comments or diagnostics solely to reclaim 146 bytes would
make a structural qualification boundary depend on cosmetic source text. The
long-term contract therefore keeps the cap and corrected semantics unchanged,
versions the portable artifact oracle and its schema to revision 2, and leaves
the shared role labels stable for unaffected profiles. Evidence compatibility
is expressed at the profile oracle that actually changed, not by renaming the
whole multi-backend workload catalog.

## 2026-08-24: Runtime qualification must fit its complete public artifact graph

A trace that fits its own capture is not a usable qualification workload when
the normalized result and companion artifacts make the final public
transaction exceed its independent byte cap. Exact portable-SystemVerilog
probes exposed both boundaries: 100,000 genuine records exceed runtime capture,
while a smaller 25,000-record run completes internally but cannot publish its
complete artifact graph. Selecting by trace records alone would therefore
encode a benchmark that the qualified public workflow cannot retain.

Portable runtime scale now uses authored reset-cycle sampling, for which every
extra cycle produces four real endpoint/probe samples plus one coverage record.
The exact 10,000-record gate remains, while qualification moves to 15,000: the
largest reproducible 5,000-record step whose complete graph stays at or below
three quarters of the public cap. The rule deliberately leaves schema-growth
headroom and remains an admission criterion, not a new limit or capacity claim.

Stage measurement also cannot duplicate the public Runner. One private,
caller-sealed Verilator lifecycle must own canonical emission through cleanup,
with forward-only content-addressed predecessor state. Public execution and
measurement may select different sealed storage contexts, but they retain the
same tool, flags, inputs, commands, validators, results, limits, and transition
semantics. This permits process-isolated stage costs without creating a second
compiler/simulator contract or trusting large payloads sent over worker IPC.

## 2026-08-24: Runtime qualification identities include tracked source provenance

Selection probes used repository-local temporary sources to choose semantic
activity before checked-in qualification paths existed. Once those sources are
tracked, their paths participate legitimately in SemanticIR, plan, emission,
trace, result, and public artifact identities. The final complete graphs are
therefore 32,098,531 and 47,505,049 bytes rather than the provisional
32,096,420 and 47,502,039 bytes. Qualification still retains 2,826,599 bytes
below the selected three-quarter admission ceiling, so implementation freezes
the final measured graphs instead of pretending path provenance is byte-free
or blindly adding an assumed constant.

The structural source projection is deliberately only an oracle: the tracked
gate and qualification files are always the actual parser inputs. The oracle
allows exactly the selected reset, timeout/window, and terminal-expectation
deltas from the checked reference, after which the ordinary source-to-emission
route is reconstructed twice and compared. The portable-only 15,000 override
is applied when selecting that exact profile's specification, preserving the
stable cross-profile role and the separate 100,000 VHDL/OSVVM candidates.

## 2026-08-24: Lifecycle cleanup authority follows identity proof, not call entry

The staged Verilator lifecycle cannot treat possession of a storage path as
permission to remove it. Admission publishes cleanup authority only after it
successfully creates a previously absent exact root. Resume publishes that
authority only after the closed handle matches the reconstructed lifecycle,
operation, storage context, state path, ordinal, and successor. This lets a
failure while validating an owned predecessor, object, or prepared input clean
the corrupted session, while a collision, foreign handle, or forged successor
cannot delete the existing owner. Final public assembly is constructed in
memory before cleanup, but is returned only after exact removal succeeds.

Content-addressed state is not enough if mutable work copies escape validation.
Every resume therefore checks the complete state-file census and predecessor
chain, exact state-specific object-kind inventory, object digest/bytes/mode,
prepared SystemVerilog copies against canonical emission, and the compiled
work executable against its sealed object. Public and measurement callers use
different sealed roots and honest actual command digests. Measurement rebases
only the operation-owned work prefix; a second root-normalized command identity
proves semantic equivalence without claiming the concrete records are equal.

Process supervision similarly separates authority and outcome. A close-on-exec
control pipe uses unbuffered child writes for handoff errors and is consumed
before ordinary output when both are ready. Deadline polling continues after
all capture descriptors close, aggregate overflow remains distinct from a
normal nonzero exit, and public timeout termination waits for the entire
process group rather than only its leader. The thin public Runner also retains
its original total-function boundary: an unexpected private lifecycle
exception or malformed private projection becomes one sanitized host-error
result rather than escaping, trusting partial cleanup authority, or leaking a
host path. Implementation-time macOS samples
localized repeated zero-output timeouts to pre-main `_dyld_start`; concurrent
policy/compiler activity remains only a correlation and is owned by proposed
`.17.3.5.3.1`, not by a retry, signing, security-bypass, or deadline workaround.
The final guarded exact lifecycle traversal and independent AHB runtime-parity
watcher pass. The broader public integration watcher passes six of seven top-
level subtests but reproduces the same wall only for the byte-identical second
direct-drive execution after the first passes; that result stays failed and
child-owned rather than becoming a retry or a weakened signoff criterion.

## 2026-08-24: A host stall is preserved by qualification, not hidden by recovery

The sampled `_dyld_start` stalls are real, but the initial compiler/policy
correlation is not a sufficient cause. The same canonical generated executable
reached first output with `syspolicyd` at 49.0% CPU during unrelated compiler
orchestration, and two zero-compiler observations also passed. Generated,
byte-identical different-path, and fresh minimal C++ binaries all carried the
same provenance value and valid linker-created ad-hoc signatures. The full
public repeated-direct-drive route later passed under the natural quiet
condition. Decision 0084 therefore preserves the existing lifecycle and fixed
wall and adds only an explicit-guard evidence watcher plus a bounded static
record.

The diagnostic treats controls as causal probes, never recovery paths. The
primary executes once and alone determines success; a timeout remains a failed
test even if a byte-identical copy or minimal binary later runs. Read-only
sampling begins only after two seconds of continued life, all evidence remains
under a same-device non-symlink repository root, and incomplete attempts cannot
strand sample data. This gives future macOS observations exact host, process,
binary, signature, xattr, timing, stack, and cleanup context without retry,
deadline widening, security/signing changes, or false backend support.

## 2026-08-24: Tool deadlines begin at the tool boundary, not route reconstruction

The portable-Verilator common worker must reconstruct the selected source,
route, ExecutionIR, emission, and predecessor authority before it can resume a
shared lifecycle transition. Treating the lifecycle's 30-second generated-
runtime limit as the whole run worker's wall made unrelated reconstruction
time consume the tool allowance. Under host load, the controller could kill
the worker before or during lifecycle handoff and report a controller timeout
that looked like a Verilator runtime failure.

The controller now owns explicit 900-second compile-worker and 300-second
run-worker containment envelopes. The shared lifecycle independently retains
the qualified 10-second version, 120-second compile, and 30-second runtime
limits plus the existing capture ceilings. Accepted evidence checks both
layers, so the larger outer envelope neither widens nor retries tool execution.
This composition makes cleanup and failure attribution deterministic while
preserving the public Runner's exact execution contract.

The same isolation boundary made a full public assembly unsuitable for the
controller pipe: serializing and decoding tens of MiB repeated work already
sealed in lifecycle objects. Measurement assembly therefore persists a compact
content-addressed descriptor and materializes the final graph once under the
controller-owned publish root. Fresh-process public resume still reconstructs
and verifies the complete assembly; ordinary Runner success still returns the
unchanged in-memory graph. The compact measurement projection carries exact
artifact identities, actual commands, normalized command digests, transcripts,
trace/result identities, and cleanup evidence without creating a second runner
or a second artifact contract.
