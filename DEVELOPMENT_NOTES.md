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
thread did not prevent Clang's generated UVM class aggregate from crossing a
4-GiB peak under optimized compilation. `-O0` is therefore part of the exact
feasibility argv: runtime performance is irrelevant to the control, and the
lower-memory build passes the repository guard. Transcript identity removes
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
