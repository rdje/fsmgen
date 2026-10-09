# Reference Map

This chapter helps you navigate between the new book and the older focused
reference docs.

## What The Book Is For

Use the book when you want:

- progressive learning
- example-rich explanations
- topic-based navigation
- a friendlier path from beginner to advanced use

Start here:

- [Introduction](00-introduction.md)
- [Your First FSM](01-first-fsm.md)
- [Cookbook](12-cookbook.md)
- [Implementation Blueprint](15-implementation-blueprint.md)

## Canonical Source Views

The build carries bounded raw source views for the selected repository
references. Each view contains the complete canonical source text at the latest
book build. Markdown links within a source view remain text; use the native
book chapters for rendered narrative and navigation. Source views also keep
focused guidance, policy, operational state and retained engineering evidence
distinct from shipped behavior.

The selected references in this chapter and the feature-support matrix open
these source views. Their labels identify the canonical repository documents;
the served text reflects the latest book build. Native source refresh requires
the source and its endpoint to be admitted by the ignore policy; build success
alone does not establish that. Links inside a raw source view remain text.

## What Still Lives Outside The Book

Some docs are intentionally still focused references:

- [../../COMPOSITION_SCOPE.md](reference-source/docs/COMPOSITION_SCOPE.markdown.source.txt)
- [../../EXTENSION_MODEL.md](reference-source/docs/EXTENSION_MODEL.markdown.source.txt)
- [../../REGRESSION_CORPUS.md](reference-source/docs/REGRESSION_CORPUS.markdown.source.txt)
- [../../FEATURE_BACKLOG.md](reference-source/docs/FEATURE_BACKLOG.markdown.source.txt)
- [../../INTENT_CAPTURE_AXI_CASE_STUDY.md](reference-source/docs/INTENT_CAPTURE_AXI_CASE_STUDY.markdown.source.txt)
- [../../ISF_DOWNSTREAM_INTEGRATION_SPEC.md](reference-source/docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.markdown.source.txt)
- [../../ISF_SPEC.md](reference-source/docs/ISF_SPEC.markdown.source.txt)
- [../../ISF_PUBLIC_INTERFACE_CONTRACT.md](reference-source/docs/ISF_PUBLIC_INTERFACE_CONTRACT.markdown.source.txt)
- [../../BACKEND_LANGUAGE_MDBOOK_BLUEPRINT_SELECTION.md](reference-source/docs/BACKEND_LANGUAGE_MDBOOK_BLUEPRINT_SELECTION.markdown.source.txt)
- [../../BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION.md](reference-source/docs/BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION.markdown.source.txt)
- [../../BACKEND_LANGUAGE_PORTABLE_HOST_ABSTRACTION_SELECTION.md](reference-source/docs/BACKEND_LANGUAGE_PORTABLE_HOST_ABSTRACTION_SELECTION.markdown.source.txt)
- [../../BACKEND_LANGUAGE_PORTABLE_PARITY_HARNESS_SELECTION.md](reference-source/docs/BACKEND_LANGUAGE_PORTABLE_PARITY_HARNESS_SELECTION.markdown.source.txt)
- [../../BACKEND_LANGUAGE_TYPED_EXTENSION_PORTABILITY_AUDIT.md](reference-source/docs/BACKEND_LANGUAGE_TYPED_EXTENSION_PORTABILITY_AUDIT.markdown.source.txt)
- [../../BIN_FSMGEN_IMPORT_TREE.md](reference-source/docs/BIN_FSMGEN_IMPORT_TREE.markdown.source.txt)
- [../../TASK_TREE.md](reference-source/docs/TASK_TREE.markdown.source.txt)
- [../../tasks/ISF-PUBLIC-CONTRACT-SYNC.md](reference-source/docs/tasks/ISF-PUBLIC-CONTRACT-SYNC.markdown.source.txt)
- [../../COMPOSITION_LEGACY_MAPPING.md](reference-source/docs/COMPOSITION_LEGACY_MAPPING.markdown.source.txt)
- [../../../MEMORY.md](reference-source/MEMORY.markdown.source.txt)
- [../../../ROADMAP_V2.md](reference-source/ROADMAP_V2.markdown.source.txt)
- [../../../README_POLICY.md](reference-source/README_POLICY.markdown.source.txt)
- [../../../LIVE_DOCUMENT_SIZE_CONTAINMENT.md](reference-source/LIVE_DOCUMENT_SIZE_CONTAINMENT.markdown.source.txt)
- [../../../CLAIM_VERIFICATION.md](reference-source/CLAIM_VERIFICATION.markdown.source.txt)
- [Live-Document Containment Adoption](91-live-document-containment-adoption.md)
- [../../LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.md](reference-source/docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.markdown.source.txt)
- [../../audits/LIVE_ACHIEVEMENT_STATUS_VALUE_AUDIT.md](reference-source/docs/audits/LIVE_ACHIEVEMENT_STATUS_VALUE_AUDIT.markdown.source.txt)
- [../../audits/ROADMAP_STATUS_VALUE_AUDIT.md](reference-source/docs/audits/ROADMAP_STATUS_VALUE_AUDIT.markdown.source.txt)
- [../../../TASK_ACCEPTANCE.md](reference-source/TASK_ACCEPTANCE.markdown.source.txt)
- [../../../COMMIT.md](reference-source/COMMIT.markdown.source.txt)

These should stay precise and sometimes narrower than the book.

The Knowledge Map checks each fact card against its configured line, encoded
byte and line-width bounds. Both generation and validation count the original
UTF-8 bytes; a non-ASCII character can occupy several bytes. Invalid UTF-8 is
rejected. Query-cache fingerprints include the complete generated shard bytes,
so a byte change invalidates a cached projection even when its questions stay
the same. The collection's containment allowance is a separate gate; passing
one card's bounds does not authorize collection growth. An authoring script's
local precondition does not establish an enforcement limit: use the checker,
configuration and actual accepted and refused boundary cases. See
[the Knowledge Map architecture](#knowledge-map-architecture)
and its public checker, `knowledge-map/scripts/check_knowledge_map.sh`.


A collection rollover keeps each reader question at a bounded current card and
provides authenticated retrieval of its complete dated predecessor. Current
rules use canonical doctrine and registries; historical measurements keep their
capture boundary. Preserving counts alone cannot prove that question ownership
or unique information survived a move.

For eligible transition debt, the declared allowance covers measured actual plus
one declared step, clamped at the enforcement ceiling, with a live owner. At
rollover debt, perform the declared rollover; widening its allowance is forbidden.
Card limits, aggregate limits and the transition allowance are independent.
A compliant line width or an unchanged question count does not establish whole
surface health or preserved question ownership.

The containment cards now separate current rules from complete dated sources.
Retrieve a predecessor by its existing card ID from the repository root:

```sh
python3 -B docs/audits/knowledge-card-rollover-selection-20261005/read_source.py live-document-size-containment
```

The same reader accepts `live-document-surface-growth-procedure`,
`knowledge-card-sizing-and-partition` and
`live-document-transition-allowance-headroom`. It checks the complete retained
file digest before returning the original bytes. The doctrine gate also checks
these file archives. Earlier measurements and superseded instructions keep their
capture boundary; current writing follows the canonical doctrine and registries.

Captured metadata must retain its declared field kind and the recorded producer
form. A Boolean does not become an integer field because a host language compares
them equal. A public schema may admit equivalent integral numeric forms, while an
exact capture reader must still preserve the original producer representation.
Check these boundaries separately; a private comparison defect does not make
correctly captured source values wrong. Rollover records now use a superseding
reader that pins original source, programme, proof and receipt bytes to their
publication revision before checking their recorded metadata kinds.

`CLAIM_VERIFICATION.md` defines what earns an actionable quantitative claim:
re-derive it from its source, attempt to falsify it with a separating oracle,
and keep a tracked producer plus a watcher that detects staleness. A missing
leg is published explicitly rather than hidden behind repeated checks of the
same kind. `scripts/check_claim_verification.pl` gates exact bounded records and
tracked local paths. Decision `0094` makes a finite manifest-addressed
registry set the repository default while retaining one global claim namespace;
explicit `--registry` remains for bounded single-file fixtures. The separately bounded current-surface inventory derives
its scope from the live-document registry and sends every open candidate to a
task owner. Its bounded disposition registry then joins each reviewed current
candidate to a published claim record, a three-leg derived gate, a reviewed
incidental reason, or an explicit owned gap; a completed source group cannot
retain an open candidate. Run the five-group report with
`scripts/check_claim_verification_dispositions.pl --report`. Decision `0074`
keeps semantic truth and oracle independence outside those structural gates'
claims.

The reviewed policy also requires evidence at the level being claimed. State
its unit, population, predicate and input revision. A suite or group result
cannot establish each member's property without evidence connecting the two.
For an absence, uniqueness or completeness claim, retain the scoped enumeration
and its command. Classify search hits before calling them defects.

For example, finding a validation word in several tests identifies candidates
to inspect; it does not prove that each test checks the same behavior. Conversely,
finding no match for that word does not prove the behavior is untested. The
assertions and the public behavior they exercise provide the relevant evidence.
A claim naming one test must identify that test and its actual checked property.

Consult earlier adjudications before reporting a conflicting result, and name
any difference in source revision, contract, scope or evidence. An earlier ruling
can be wrong, but another search result alone does not overturn it. Attribute
a change through a safe controlled comparison or isolated reconstruction when
possible; preserve first-failure evidence, unrelated user work and existing
admission gates. A spent or prohibited capture stays prohibited. Publish a
missing attribution leg and its repair owner if the comparison is unavailable.

Review a challenged claim's prose, quantity and named instance separately under
its recorded conditions. A fixed-input census should reproduce exactly; a
contract value or named identity requires an exact match. A runtime measurement
can vary even when a command produces it, so report its sampling method and
interval instead of implying precision from one run. Any judgment tolerance
must be justified before comparison. Honest rechecking and correction remain
part of verification; confidence alone is not evidence. Decision `0104` records
these adaptations, and incidental numerals keep their existing semantic
contracts without becoming claim records merely because they contain digits.

The regenerated inventory also consumes the canonical disposition identities:
closed candidates carry no residual migration owner, while a new candidate
remains visibly task-owned until it receives a disposition. A compact
original-cohort manifest names the exact adoption commit, then reconstructs
per-source identity sets from that versioned source and checks their counts and
digests. Current files must retain every original identity, but later numeric
fields remain current-only even when nested on a historical JSONL line. Current
derived constants retain re-derivation, falsification, and durability legs;
configured policy values and schema versions retain explicit input-identity,
falsification, and durability gates. Run the reconciliation report with
`scripts/check_claim_verification_inventory.pl --report`.

The first root-document review repaired stale README-policy wording that had
described ratcheted enforcement ceilings as still pinned to their adoption
baseline. Every current non-rationale root policy, index, navigation, and
structural candidate now resolves to either a live derived gate or a reviewed
policy, history, structure, or identifier disposition. The rationale-ledger
measurements are likewise closed by the evidence-coherent reviews below;
derive current counts with the report command above instead of copying them
into this inventoried surface.

The foundational rationale review separates live gates from immutable context.
Ledger reconstruction, the complete roadmap archive, and qualified provider
source ordering use executable producer, separating-oracle, and watcher chains.
Book-partition and earlier roadmap-occupancy statements remain explicitly
historical. Unsupported precision in an experimental host-resource observation
was removed while retaining the checked guarded-envelope outcome and
lower-memory compilation control.

The bridge and execution rationale review also keeps independently selected
scale axes independent in the evidence. Bridge source-map calibration is
reconstructed with differential real semantic builds, while exact boundary
cases retain their ordinary builder outcome. The earlier scenario-map collision
is historical context watched by the repaired global-map invariant. Total and
live fibers use distinct generated tree shapes and mutation oracles, and an
execution type counts only when a real public binding exercises its semantic
shape. Rejected wide-tree and unbound-alias examples remain reviewed structural
references rather than being promoted into evidence.

The checking-scale review closes the root-document group without treating one
large aggregate as proof of another. The foundation oracle derives the owned
and rejected shape sets from the catalog. Model evidence separately checks
authored definitions, instances, declarations, and exercised cells; scoreboard,
coverage, and fault evidence reconstruct storage, order, and lifecycle
identities with targeted mutations. Random-replay evidence distinguishes
semantic preflight, bridge materialization, execution-plan rejection, and the
adjacent semantic diagnostic. These exact boundary suites run through the
ordinary generators and builders under the repository RAM guard.

The first general-book review applies the same separation to core language and
tooling prose. Parser boundaries, inferred widths, literal normalization,
declarative state models, composition inference, expression factorization,
hosted-test partitioning, target-language emission, and repeat lowering remain
attached to their ordinary producers and focused behavior oracles. Syntax
operands, boolean option values, protocol-version tokens, test bands, and linked
test filenames remain reviewed non-claims. The LTE expected-failure count is
also reconstructed from the active source entries independently of its catalog
diagnostic.

The intent, actor, and transaction review ties entry, drive, sample, await,
completion, control, data, loop, and latency timing to their ordinary lowering
and reporting paths. Published repeat timing now accounts for initialization
and every check transition, while request and target-derived payload widths
remain distinct. Lowered states carry exact transaction ownership so injected
latency checks remain attributable in schedule reports.

The control, data, composition, rule, lowering, and type review keeps loop and
temporal edges, expression widths, storage packing, generated-child routes,
rule conflicts, structural costs, and type packing on distinct executable
evidence. Instructional ordinals and an example clamp threshold remain
examples rather than capability measurements. The lowering reference now
matches check-first repeat behavior and separates request width, per-formal
signal count, and target-derived payload width.

The support-matrix and non-protocol backlog review separates current generated
behavior from test filenames, recipe ordinals, task identifiers,
implementation-language names, and illustrative literals. SourceHIR fixture
identity, VHDL generic maps, ATL and FIFO lowering, IAL2 response boundaries,
and VIAL profile evidence remain independently executable. The complete book-
example total now follows the lowering audit instead of a stale hand copy.

`16dd-vial-portable-vhdl-runtime-measurement.md` is the user-facing selection
contract for sampled portable-VHDL runtime scale. It explains why the existing
v1 trace cannot scale by reset count, the versioned compact snapshot design,
exact authored candidate equation, one shared staged GHDL lifecycle, unchanged
earlier-cap authority, and the boundary from IASIM, OSVVM, support, and
capacity claims.

The implementation-blueprint, platform-intent, and reference review keeps the
single Rust parity smoke and the current bounded AHB map on executable
evidence. Chapter coordinates, declared policy caps, and immutable activation
measurements remain explicit non-current context. Archive, ledger, task
segment, evidence-map, ISF-partition, and roadmap recovery each retain their
own checker; activation occupancy is now consistently written in the past
tense rather than resembling current repository state.

`MEMORY.md` is the bounded resume pointer and `TASK_TREE.md` indexes the live
work frontier. `ROADMAP_V2.md` carries high-level direction.
Decision 0049 retires the former roadmap-status board after its independent
`.11` audit found no unique current authority; the exact March-June 2026
chronology and R0-R14 snapshot remain version-retrievable. Decision 0046
retains the conditional rationale ledger. Its bounded current view is
`DEVELOPMENT_NOTES.md`; `DEVELOPMENT_NOTES_INDEX.md` lists every ordered range
and its exact retrieval. Add a whole `## ` entry only for durable engineering
rationale with no better decision, fact, task, user-document, source-comment,
or commit home. The ledger verifier reconstructs all 2,843 pre-cutover entries
from the immutable source at `d3c22e003`, then proves the bounded current range
is a real ordered suffix. Decision 0047 retires the duplicate per-slice
changelog after exact current-value and consumer proof: high-level
direction stays in `ROADMAP_V2.md`, active work and evidence in task trees,
resume state in `MEMORY.md`, shipped behavior in the mdBook, and exact change
history in work-unit-bearing Git commits. The exact former changelog object is
version-retained; no replacement status blob or generated changelog is added.
Decision 0048 likewise retires the former achievement journal after the
independent `.11` audit found no executable/content consumer or current
recovery/status role. Its exact frozen 23-day digest remains version-
retrievable; task evidence, this book, bounded Memory, and Git answer its
former current questions.

`README_POLICY.md` is the project- and harness-neutral landing-page maintenance
standard. Adopting projects keep their authoritative tracked copy at repository
root beside `README.md`; the originating template is not an upstream. Local
owner/date, decision, and empirically derived cap metadata stays in a fenced
adoption note above the neutral body. The policy defines stable content, routes
proven duplicate detail to its canonical home, and requires independent line
and byte budgets unconditionally on every commit and CI tree. FSMGen's reviewed
local limits are 275 lines and 12,288 bytes. Decision 0040 closes the next
boundary: moving detail is not enough unless the destination is also
pressure-controlled. Top-level `README.md` is also the rendered GitHub project
landing page, not just a bootstrap file: its purpose, minimal first-use path,
architecture summary, and canonical navigation remain visible there. FSMGen's
data-only route registry maps changing detail and chronology into the common
surface graph without off-loading that landing function. The unconditional
guards check per-file/aggregate ceilings, freshness ownership, terminal
lifecycle, or exact frozen identity. Current legacy ceilings are stop-growth
debt boundaries, not reusable recommendations.

`LIVE_DOCUMENT_SIZE_CONTAINMENT.md` is the broader reusable lifecycle
doctrine. Its normative body is project-neutral, project-agnostic, and
harness-neutral; FSMGen authority, measurements, 80/90 pressure
milestones, repository-local storage rule, and migration paths remain in a
fenced local adoption note and the focused audit. The architecture separates
bounded current views from role-appropriate durable stores: user-facing
reference stays in navigable semantic book partitions, generated indexes
shard from smaller canonical sources, and exact engineering chronology can
leave the working tree only after digest-verified retrieval exists. Per-part
sharding never substitutes for file-count and aggregate containment. Decision
0041 selects this contract and the
`LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION` tree owns implementation. Clean
selection commit `139efbf90` completes `.1` continuity activation and leaves
`.2` as the common-enforcement owner. `.2` now ships a neutral checker plus
local JSONL data: one named object per line, path and route arrays, nested
target/ceiling/milestone/baseline objects, and strict rejection of malformed,
missing, or unknown fields. Every common registry now starts with declared
record-count, file-byte, and maximum-record-byte limits; field byte bounds and
array cardinalities make the control plane finite. This retains line-oriented
diffs and streaming without the positional ambiguity of the discarded
22-column TSV prototype. The resulting unconditional census covers every tracked Markdown path, including README
itself, broad root/focused/ancillary collections, and canonical knowledge
cards; no family topology or established limit changes in the enforcement
slice.

`LIVE_DOCUMENT_SIZE_CONTAINMENT_ADOPTION_GUIDE.md` is the non-normative,
forwardable bridge for projects that already adopted durable memory but still
experience bounded-pointer or routed-destination pressure. It keeps
`MEMORY.md` bounded, separates immediate pointer stabilization from the wider
lifecycle migration, and tells adopters to derive their own utility decisions,
measurements, thresholds, registries, checks, and retention contracts rather
than copying FSMGen's local data.

Decision 0042 and `.6` define optional sealed task-subtree segments and
compact completed terminals. At the `.7` migration, the live IAL2 file kept its
active root while one exact-source segment reconstructed all 844 terminal
children, and the cross-tree index kept only three active plus eleven proposed
rows while 540 unique terminal rows became digest-proved query history.

`TASK_ACCEPTANCE.md` is the project-neutral evidence-backed code-slice
standard. FSMGen's registered checker reads data-only staged-path and evidence
registries, requires fresh one-file ROOT CAUSE / ADDRESSED / NO REGRESSION
boxes for matching implementation changes, and leaves actual behavioral proof
to the cited focused and CI oracles.

`ISF_DOWNSTREAM_INTEGRATION_SPEC.md` is the canonical human handoff landing
for every downstream consumer. The book downstream integration chapter includes
its four contract parts, so edits to those parts and the published chapter
cannot drift apart.

`BACKEND_LANGUAGE_MDBOOK_BLUEPRINT_SELECTION.md` records the selected
implementation-blueprint structure for future backend-language variants. The
book-facing entry point is Chapter 15, which links to the portable API, host
abstraction, and parity-harness selectors instead of duplicating their full
maintainer detail.

`BIN_FSMGEN_IMPORT_TREE.md` is the live maintainer-facing architecture map for
the `bin/fsmgen` runtime spine. It is not a tutorial chapter, but it is the
right place to verify whether the saved CLI/import-tree picture still matches
the source at the start of an engineering session.

Keep detailed static measurements in that focused doc; the book should point to
the current maintainer map rather than duplicate volatile line-count tables.

`COMMIT.md` is the process safety reference: every completed task, slice, lane,
or task-scoped activity must close with that workflow before the next work
starts, so crash recovery and agent handoff can resume from task-scoped
commits instead of a dirty worktree.

The standing publish interval is 500 accumulated local commits beyond the
configured upstream. Git is the sole counter; every slice is still committed
immediately, an explicitly directed early push resets the interval without
changing its standing length, and every successful transport remains open
until exact hosted qualification is consumed. This separates local recovery
from less frequent remote publication without shadow state. [Decision
0102](reference-source/docs/decisions/0102-push-cadence-is-500-commits.markdown.source.txt) records the rationale
and supersedes the former 300-commit interval.

Tracked raw standards PDFs under `docs/vendor/` are local reference artifacts
for future task-tree-owned evidence or design probes. The current set includes
the Arm AMBA AXI specification plus Accellera SystemRDL 2.0, Portable Test and
Stimulus 3.0, and UVM 1.2 references. These PDFs do not by themselves ship
standard extraction, parser, lowering, scheduler, or HDL behavior.

`TASK_TREE.md` is the active-tree and PNT frontier reference. For ISF feature
work, it points to the reusable synchronization checklist in
`docs/tasks/ISF-PUBLIC-CONTRACT-SYNC.md` so public specs, book chapters,
contracts, manifests, tests, live docs, and commit hygiene stay aligned without
duplicating the checklist in every feature tree. Its live-doc routing follows
`COMMIT.md`: task nodes and Git own history, Memory holds the resume pointer,
engineering rationale is conditional, and README stays a stable landing page. Long-running task trees may
keep only metadata, the root, and the nonterminal ancestor/frontier graph in
their live file while decision 0042's bounded JSONL manifest addresses
content-digested completed subtree segments copied from an exact source
revision. A compact completed terminal is valid only when the integrity checker
retrieves, digest-checks, counts, and reconstructs its full terminal subtree
from an exact version object. PNT still selects entirely from the live file;
the optional forms add no migration requirement for ordinary trees. The first
migration reduces the live IAL2 file from 21,726 to 85 lines and the task index
from 1,078 to 558 lines. Completed task files remain directly browsable; only
duplicated cross-tree terminal narration becomes query-first. User-directed
leaf `.14` published a self-contained external review packet before the next
migration.

Closed acceptance history uses an exact committed source and a unique legal
heading. When a new boundary is needed, it is committed before the separate
rollover; existing node contracts and active limits stay live throughout.
The semantic task’s completed acceptance body is now retrieved through its
bounded manifest, including the exact previous source and prior history chain.

Ownership records belong inside the first `## Task Tree` section and their
parent child list. Matching IDs elsewhere in a file does not establish live
registration. Completed semantic reset-question, reset-grammar and historical
view records now retain their original contracts in that authoritative graph;
optional historical views keep decision 0019’s separate historical role.

The bounded [review front door](reference-source/docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_REVIEW.markdown.source.txt)
summarizes the current architecture and routes forensic readers to the
content-identified
[external review packet](reference-source/docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_EXTERNAL_REVIEW_PACKET.markdown.source.txt).
That detailed packet explains the doctrine, schemas, pressure model, route and
archive checks, task-history migration, measured results, limitations, and 31
review questions. It is now immutable retained evidence rather than an
append-only review page. New review rounds receive new task-tree-owned
artifacts and dispositions.

PGEN and ANVIL returned independent reviews. The tracked
[disposition](reference-source/docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_EXTERNAL_REVIEW_DISPOSITION.markdown.source.txt)
checks every finding against exact FSMGen evidence. It corrects two easy-to-
misread claims: `2,780 / 2,780` path coverage proves classification, not healthy
size or currency, and the IAL2 live root plus task segment are overlapping views
rather than a line partition. The complete former 21,726-line source remains an
exact Git object while the segment independently preserves all 844 task nodes.

Decision `0044` accepts explicit health targets plus inclusive transition
ceilings, removal of inert `hard_pct`, mechanically proved verifier execution,
lifecycle-scoped currency without a global date heuristic, typed author versus
reader routes, complete collection indexes, declared version-object retention,
maximum line/record bytes, and utility outcome `re-form`. Leaves `.15`-`.23`
keep each correction atomic. No review suggestion changes a threshold,
lifecycle, frozen file, or product behavior merely by being accepted.
Clean disposition commit `3b782fc10` activates `.18` alone to implement the
health-target versus enforcement-ceiling correction without widening a limit.
The completed implementation gives every measured surface separate six-axis
`health_targets` and inclusive `enforcement_ceilings`. Warning and rollover are
health signals; equality at the ceiling passes and any excess fails. Debt
baselines cannot increase across revisions but may ratchet downward after an
atomic content reduction, owned allowances fit below the ceiling, and a banded
downward ratchet rejects stale headroom after pressure falls.
`hard_pct` is gone. A ceiling increase cannot authorize itself: it requires an
exact new append-only authority row plus a new decision in the same Git change,
while lowering is free. Checker output shows actual/target/ceiling values and
separates migrated, pinned/deferred, and steady surface pressure. This first
schema migration raises no predecessor ceiling. The sixth axis measures the
largest raw content line in bytes, excluding LF and optional CR; it catches
dense generated/table rows that can hide beneath total-line and total-byte
limits.
Leaf `.19` now requires generated freshness and version-object retrieval to
declare `core:`, `adapter:`, or `external:` execution. Core programs execute
from the repository root. The registry-driven local runner executes every
adapter program and supplies an exact one-use proof to the neutral checker;
missing or unused proofs fail. External contracts are visible fail-closed
degradation, never a green presence check. The bootstrap gate proves hosted CI
reaches this path through the single unconditional doctrine driver.
The rereferenced PGEN and ANVIL files exactly match the hashes already recorded
by `.17`, so they add no new review scope. Leaf `.20` now separates boundedness,
currency, and semantic truth. Currency is opt-in: a current surface names one
local contract and an executed core/adapter verifier. The active task index
uses task-tree integrity as its source-alignment oracle. No universal newest-
date, distinct-date, or file-age rule exists; legitimate closure dates and
undeclared surfaces are not scanned, while archive/frozen lifecycles are
structurally exempt.
Clean `.20` commit `8cf8263a2` activates `.21` alone to type author-overflow
versus reader-navigation routes and prove collection-index and review-evidence
membership. This activation changes no checker, registry, or document content.
Leaf `.21` now implements that boundary. Fifteen README navigation rows remain
reader routes; four author-overflow destinations are derived from the guard's
emitted hints and matched exactly to governed surfaces. Literal book/decision
indexes prove member links, other collection front doors declare query or
generated contracts, and fenced packet/disposition maps resolve 17 plus 5
evidence paths. A staged-result adapter prevents the neutral worktree check
from validating different controlled content than the commit tree.
Leaf `.22` closes the migration/retention ambiguity. A bounded migration
manifest independently verifies the IAL2 former source at 21,726 lines and
4,662,385 bytes, all 844 sealed semantic nodes, and the 6,002-line / 2,438,733-
byte live root-plus-manifest-plus-segment working set. It declares those
products `overlapping_non_partition` and records zero unretained residue;
false partition arithmetic, identity/cardinality drift, and unproved residue
fail closed. Every task-tree or generic archive `version_object` names a
bounded retention contract with an owner, guarantee, and recovery action.
Missing history diagnostics identify that action, while evidence that must not
depend on history uses content-addressed repository files. At `.22` closure,
the review front door was 79 lines. Its independent caps remain
100 lines / 5 KiB, and its typed route leads to the
SHA-256-frozen 1,311-line detailed packet.

Decision `0045` and leaf `.23` now select `maintained_reference` for unique
product or specification prose whose legitimate aggregate scope follows the
product. This is an information lifecycle, not a replacement name for the
`partitioned_canonical` storage topology. Both use stable semantic files and a
complete index, but only the ordinary partitioned collection claims that a
fixed aggregate ceiling is meaningful.

The distinction matters whenever a new supported feature needs a new chapter
or more accurate examples. A timeless aggregate cap would have only two
outcomes: maintainers repeatedly raise it, making the cap decorative, or they
delete/displace unique explanation to satisfy a number unrelated to user
value. Maintained reference instead fixes the costs a reader and reviewer must
pay while making aggregate change explicit:

- one complete mandatory index has independent line and byte ceilings;
- every part is linked directly from that index, bounding navigation depth;
- every part retains fixed line and byte health targets and inclusive ceilings;
- aggregate files, lines, and bytes are measured against an exact prior
  baseline plus the signed change authorized by the current work unit; and
- unrecorded, inexact, reused, or pre-banked aggregate authority fails the
  doctrine gate.

The ordinary aggregate pressure keys are present as JSON `null`. That spelling
means “a fixed product-size cap is inapplicable,” not “this dimension is
ignored.” The separate aggregate-change contract still accounts for the exact
files, lines, and bytes on every revision that changes the collection.

The mdBook is FSMGen's first `maintained_reference`. Its `SUMMARY.md` mandatory
read is capped at 64 lines and 4 KiB, and every chapter remains one direct link
away. Activation commit `b88b37323` fixes the former 18,697-line Chapter 14
source. Leaf `.8` maps all of it exactly once into thirteen direct pages by
stable language/data, composition, actor, IAL2, verification, protocol, ISF,
backend, validation, and API topics. At that activation the mandatory read was
51 lines. The largest new page was
2,726 lines / 192,166 bytes. Examples remain executable,
and the former backend deep-link routes through the bounded landing page.

The ISF reference is the second `maintained_reference`. Leaf `.13` preserves the
exact 6,254-line language specification, 4,485-line downstream contract, and
3,759-line public-interface contract at activation revision `322d81fac3ce`,
then re-forms them as three bounded landing pages and eleven stable semantic
parts under `docs/isf-spec/`. The main `docs/ISF_SPEC.md` landing directly links
every member, so no reference topic is more than one step away. The largest
part is 2,453 lines / 171,378 bytes, and the exact transformed activation
content passes an executable equality check.

Clean `.10` commit `3b71cb0b1` activates `.13` alone against 1,005 focused
documents and 12 ancillary documents. The 6,254-line ISF specification and the
independent 7,536-byte import-tree line are separate containment questions;
activation records them without changing content, paths, indexes, or limits.
The implementation retains `docs/BIN_FSMGEN_IMPORT_TREE.md` as the live
runtime-spine architecture map while wrapping its pathological lines. At that
activation, a generated index classified all 1,005 focused and 12 ancillary
documents by audience, lifecycle, owner, and role; its checker rejects stale, missing,
duplicate, or unclassified membership.

The roadmap has a different role: it is a bounded current-direction snapshot,
not shipped-behavior reference or exact chronology. Clean commit `dc1c64afb`
fixes the exact 10,451-line activation source. Leaf `.9` retains product
objective, principles, `R8`–`R14` strategy, dependency policy, concise
milestone outcomes, and `H1`–`H6` intent in a 317-line activation view. The
complete
source remains digest-checked through descriptor
`roadmap-v2-pre-containment-2026-08-01`; active state routes to Memory and task
trees, shipped behavior to this book, and exact chronology to Git.

Clean `.9` commit `a20d38afc` activates `.10` alone against 1,097 canonical
knowledge-card files and the exact 15,637-line / 6,152,312-byte generated map.
The activation changes no fact boundary, projection topology, generator,
query/cache behavior, or pressure limit; those remain the active frontier.

Leaf `.15` closes the neighboring control-plane gap. Each common JSONL
registry has a schema-versioned metadata record declaring positive maximum
data records, whole-file bytes, and raw JSON bytes per record. The neutral
checker also applies portable fail-safe bounds of 10,000 records, 16 MiB per
registry, and 64 KiB per record; FSMGen's declarations are tighter. Identifiers
use closed domains, scalar strings have field-specific byte limits, and arrays
stop at 128 entries. Focused fixtures reject missing/incoherent metadata,
record/file overflow, oversized fields and arrays, over-wide Markdown lines,
and CRLF mismeasurement. No predecessor pressure ceiling is widened.

## Completed Guide Migration

The former user-guide and book-plan waypoints are superseded. Their unique
accurate content now lives in the book, decision `0006`, or the focused links
above; leaf `.24` records exact identities, residue and consumer proofs, planted
negative controls, and Git recovery. Use this map and `SUMMARY.md` as the
current entry points.

## Old Guide To Book Map

- `1) What FSMGen is` -> [Introduction](00-introduction.md)
- `2) Core concepts` -> [Language Basics](02-language-basics.md)
- `2.1) Currently supported .fsm constructs` -> split across Chapters 02-08
- `3) Basic usage` -> [Your First FSM](01-first-fsm.md) and
  [Generated HDL, Debugging, and Inspection](09-generated-hdl-debugging-and-inspection.md)
- `4) Useful options` ->
  [Generated HDL, Debugging, and Inspection](09-generated-hdl-debugging-and-inspection.md)
- `5) Input resolution and FSMLIB` -> [Packages and Sharing](07-packages-and-sharing.md)
- `6) Debug workflow` ->
  [Generated HDL, Debugging, and Inspection](09-generated-hdl-debugging-and-inspection.md)
- `7) Typed extensions` -> [Extensions and Embedding](11-extensions-and-embedding.md)
- `8) External compatibility flow` -> [Extensions and Embedding](11-extensions-and-embedding.md)
- `9) Troubleshooting` -> [Errors, Strict Mode, and Troubleshooting](10-errors-strict-mode-and-troubleshooting.md)
- `10) Practical authoring guidelines` -> spread through the chapter intros and
  [Cookbook](12-cookbook.md)

## Migration Status

The mdBook scaffold is real and buildable now.

The old guide's major section families now have book homes:

- `1) What FSMGen is` -> Chapter 00
- `2) Core concepts` and `2.1) Currently supported .fsm constructs` ->
  Chapters 02-08 and Chapter 10
- `3) Basic usage`, `4) Useful options`, `5) Input resolution and FSMLIB`, and
  `6) Debug workflow` -> Chapter 09
- `7) Typed extensions` and `8) External compatibility flow` -> Chapter 11
- `9) Troubleshooting` -> Chapter 10
- `10) Practical authoring guidelines` -> Chapter 02

The migration discipline remains active:

- the book is the progressive learning surface and primary normative target
- runtime diagnostics now use book-owned documentation hints for the current
  supported, strict-mode, and package boundaries
- Chapter 09 now owns the operational CLI/options, report-only JSON mode,
  source-resolution, and trace/debug workflow material from the old guide
- Chapter 02 now owns the practical authoring guidance for assignment
  operator choice, guard readability, and bring-up checks
- Chapter 11 now explicitly owns the typed-extension definition, non-goals,
  and CLI/config loading prerequisites
- focused docs may still carry narrow maintainer or machine-contract detail
- the old guide remains a migration checklist and compatibility reference, not
  a place to leave user-facing contract stranded or to introduce new normative
  wording without updating the owning book chapter
- sections 3-10 of the old guide have already been reduced to chapter pointers
  so operational and extension/troubleshooting prose does not drift in two
  places
- sections 1-2.1 of the old guide have also been reduced to chapter pointers
  so product, direct-language, declaration/import, aggregate, composition, and
  diagnostic contract prose does not drift in two places
- `.24` owns final consumer replacement and proof-based waypoint retirement;
  no new normative wording belongs in the old guide

## Reading Sealed Decision Records

Use `docs/decisions/INDEX.md` to find a decision. Sealed records keep their
existing paths as forwarding pages to the complete readable archive entry.
Storage does not change a record's authority or supersession status; follow
later decisions named by the record and index when a policy has changed.

For exact original text, run from the repository root:

```sh
scripts/decision_records.py read 0014
scripts/decision_records.py read 0014 0015 | rg 'IAL2|profile'
scripts/decision_records.py check
```

The reader uses the repository's immutable archive without requiring a Git
history fetch. The readable view has relocated relative links; the reader
returns the original bytes. The check rejects altered originals, stale views,
missing forwarding/index links and obsolete Knowledge Map body searches.
These checks run through the live-document doctrine's projection verifier.
The archive is read on demand, not loaded as part of every session bootstrap.

Selected Git verification captures modes, object IDs and complete raw paths before
reading source bytes. The default whole-inventory API retains its byte bound.
Selected Git decision authentication captures the complete decision namespace, transition
source census and caller control files. The installed store also captures trusted
legacy link targets and Knowledge Map command consumers.

The fixed published legacy census determines that extra scope. Bootstrap verifies
its digest; final capture must retain its exact mode and object ID. Committed
selection resolves once to a SHA. Index selection reads all final metadata in one
native query. Ancestor metadata rejects files, symlinks and gitlinks in source
directory positions. Source reads cannot use unrelated objects. Scope declarations,
aggregate inventory bytes and individual blobs retain bounded contracts.

Check the selected current store and its continuity with the committed predecessor:

```sh
scripts/decision_records.py --snapshot index check
scripts/decision_records.py --snapshot index --prior-snapshot HEAD \
  --bind-file doctrine/live_document_size/surfaces.jsonl check-continuity
```

The dated stock fixture refused authentication solely because unrelated evidence
exceeded the whole-inventory budget. The real scoped production constructor now
authenticates the same complete store. Relevant overflow, missing membership,
conflicting stages, bad modes and changed bootstrap/final census objects still
refuse. Run the saved stock and repaired-source checks from the repository root:

```sh
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/decision-index-scope-20261008/verify.py
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/decision-index-repair-20261008/verify.py
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/decision-index-integration-20261008/verify.py
```

The repair reader reconstructs every native object, selected source and unchanged
semantic product from complete inputs. T2003 also exercises real index races,
advancing HEAD, special path bytes and shared aggregate limits. Installed index,
committed-tree, catalog and control integration is qualified; original-coordinate,
HIAL, visual, full CI and push gates remain open.

Saved checks that deliberately freeze canonical sources require their committed
source epoch. Fixture recovery declares exact input files or dependency namespaces;
it does not copy the whole historical tree or create another Git repository.
The preparation check qualifies regular and executable sources, a published book
alias, same-volume recovery, a private alternative index and read-only original
object access. The unchanged dated public route, complete reference and qualification
now pass with only declared dependencies. Independently check the full source/result
evidence and retained controls:

```sh
python3 -B docs/audits/coordinate-public-final-preparation-20261008/verify.py
python3 -B docs/audits/coordinate-public-final-replay-20261008/verify.py
```

Source-coordinate composition first admits the complete own statement catalog,
ordered observer generation and invocation custody together with the qualified
finite-public recipes. Its unchanged readers and independent source/blob/span
checks conserve every declared role and unresolved private identity. This input
admission does not interpret original coordinates or execute original captures:

```sh
python3 -B docs/audits/coordinate-source-admission-20261008/verify.py
```

The source-site bank preserves each named owner, guard/call statement and
observer, test and parser association with its complete source span. First and
closing line labels remain distinct, including equivalent labels on one line.
Invocation roots and observer generation stay tied to their admitted sources.
Function and wrapper extents establish lexical ownership; they do not predict
runtime call-site coordinates. Dated public recipes remain examples, while
per-refusal statement/path composition and original-coordinate selection are
separate pending steps. Read the saved source-only qualification with:

```sh
python3 -B docs/audits/coordinate-source-sites-checks-20261008/verify_sites.py
```

The source-only path-input admission binds the qualified ordinary, Storable
and control refusals to their authored callback and named-subtest bodies, whole
helper/observer paths and guard-model inputs. Repeated loop statements retain
their distinct helper indexes. Original generation and invocation associations
conserve, including the separately owned alias run. This does not select
statement-level coordinate alternatives or qualify original coordinates:

```sh
python3 -B docs/audits/coordinate-refusal-path-inputs-20261009/verify.py
```

The executable statement recipes extend that lexical bank with complete own
observer, helper, callback, subtest, nested capture and parser call statements.
The parser's `confess` expression includes its trailing conditional guard in
the executable recipe. Independent original-source reconstruction checks byte
offsets, ownership, first/closing equivalents and filename alternatives.
These recipes preserve alternatives without selecting original runtime coordinates:

```sh
python3 -B docs/audits/coordinate-statement-recipe-checks-20261009/verify_recipes.py
```

The source-only refusal-phase binding joins each admitted ordinary, Storable
and control refusal to its ordered guard, observer, helper, body and entry
callers. Each own caller cites an exact executable statement, retaining both
first/closing labels, equivalent alternatives and legitimate filenames. The
nested metadata capture includes its observer wrapper and Value eval before
the outer Value guard; these remain separate throw phases. Framework-owned
caller intervals remain opaque. The lexical test loader is `do`; its qualified
model label is retained separately.

The independent reader reconstructs the complete allocation from fixed Git
inputs and checks genuine guard, caller, phase, source, role, alternative and
promotion controls. It selects source topology only, excluding argument/error
payloads and original caller-coordinate snapshots. Read the sealed result with:

```sh
python3 -B docs/audits/coordinate-refusal-phase-checks-20261009/verify_phases.py
```

Original-coordinate joining remains pending, with original private runtime
meanings and alias downstream still owned separately. The binding establishes
source hypotheses, without choosing which line or filename an original
runtime actually reported.

The complete source-hypothesis qualification joins the original own-source
catalogue, lexical bank, executable statements, ordered refusal phases and
dated finite-public examples. Complete fixed input membership and bytes retain
their Git modes and source authorities. Separate original-source and call-path
reconstruction checks every hypothesis, while actual source-only readers and
genuine scope, identity, caller, guard and receipt controls qualify the join.
The published reader requires the exact complete seal:

```sh
python3 -B docs/audits/coordinate-source-hypothesis-checks-20261009/verify_hypotheses.py
```

Archive permissions follow Git's transport mask independently of tracked
file modes. The canonical retrieval fact and its `umask` query now retain this
rule. Controlled explicit masks qualify regular and executable payloads,
including the original failed mode assumption, without configuration writes:

```sh
python3 -B docs/audits/archive-transport-fact-20261009/archive.py
```

The governed card compaction retains exact complete original sources and
ordered semantic correspondence, every existing question and executable probe,
and unchanged Knowledge Map capacity authority. The first URL-wrapping draft
and corrected publication both retain. Whole source-hypothesis composition is
qualified; joining original raw coordinates remains the next owned step.

The saved original-coordinate intake authenticates the complete own capture,
its transitive proof corpus and the sealed source hypotheses. Independent Git
archive and blob streams conserve membership, tracked modes and every byte.
A separate walker rebuilds all empty/error allocations, whole error bodies,
physical caller coordinates, contexts and opaque argument/address lexemes from
the original capture JSON. Complete actual source/class-frame readers also
regenerate; the original captures are retained without recapture.

```sh
python3 -B docs/audits/coordinate-original-intake-checks-20261009/verify_intake.py
```

Intake preserves every original coordinate without selecting its meaning.
The first complete match rejects the first/closing-only source alternatives:
some helper calls and guards report interior expression lines. A complete
census retains every observation and mismatch, the first failed matcher and
its separately marked unexecuted verifier draft. No original alternative has
been widened.

Finite public caller and compiler fixtures reproduce callback/pattern and
live-operand guard attribution. Moving the relevant expression changes its
reported line; moving a later constant message does not. Constant-only guard
probes remain as counterexamples. The first ambiguous fixture selector and
its corrected producer both retain. These are finite current public results;
original private formatter/toolchain meanings remain unmeasured.

```sh
python3 -B docs/audits/coordinate-original-matching-checks-20261009/verify_diagnosis.py
```

Source-only superseding candidates now retain every prior statement, label,
filename and source identity, adding exact predicate-expression endings and
helper-pattern starts. Their literal UTF8 spans are independently reconstructed
from the complete original own source. `predicate_expression_closing` names
the final byte of a guard predicate; `pattern_expression_first` names the first
byte of a helper's pattern argument. The original statement first/closing
labels remain available, including equivalent labels on the same line.

The independent reader replays finite public caller/compiler examples and
unchanged source-only prerequisites. These are conditional candidates, with
no universal line-formatting prediction and every original selection empty:

```sh
python3 -B docs/audits/coordinate-expression-alternative-checks-20261009/verify_alternatives.py
```

Mandatory non-growing canonical causal-fact admission is next, before complete
original matching resumes. Whole hostile qualification, alias capture and
downstream, external framework, private formatting/toolchain and address
meanings retain their separate owners.

Original coordinate selections, opaque framework callers, private runtime
formatting/toolchain/identity, address lifetimes and alias downstream retain
their separate owners.

<div id="knowledge-map-architecture"></div>

{{#include ../../../knowledge-map/KNOWLEDGE_MAP_ARCHITECTURE.md}}
