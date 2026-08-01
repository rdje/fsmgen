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

## What Still Lives Outside The Book

Some docs are intentionally still focused references:

- [../../COMPOSITION_SCOPE.md](../../COMPOSITION_SCOPE.md)
- [../../EXTENSION_MODEL.md](../../EXTENSION_MODEL.md)
- [../../REGRESSION_CORPUS.md](../../REGRESSION_CORPUS.md)
- [../../FEATURE_BACKLOG.md](../../FEATURE_BACKLOG.md)
- [../../INTENT_CAPTURE_AXI_CASE_STUDY.md](../../INTENT_CAPTURE_AXI_CASE_STUDY.md)
- [../../ISF_DOWNSTREAM_INTEGRATION_SPEC.md](../../ISF_DOWNSTREAM_INTEGRATION_SPEC.md)
- [../../ISF_SPEC.md](../../ISF_SPEC.md)
- [../../ISF_PUBLIC_INTERFACE_CONTRACT.md](../../ISF_PUBLIC_INTERFACE_CONTRACT.md)
- [../../BACKEND_LANGUAGE_MDBOOK_BLUEPRINT_SELECTION.md](../../BACKEND_LANGUAGE_MDBOOK_BLUEPRINT_SELECTION.md)
- [../../BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION.md](../../BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION.md)
- [../../BACKEND_LANGUAGE_PORTABLE_HOST_ABSTRACTION_SELECTION.md](../../BACKEND_LANGUAGE_PORTABLE_HOST_ABSTRACTION_SELECTION.md)
- [../../BACKEND_LANGUAGE_PORTABLE_PARITY_HARNESS_SELECTION.md](../../BACKEND_LANGUAGE_PORTABLE_PARITY_HARNESS_SELECTION.md)
- [../../BACKEND_LANGUAGE_TYPED_EXTENSION_PORTABILITY_AUDIT.md](../../BACKEND_LANGUAGE_TYPED_EXTENSION_PORTABILITY_AUDIT.md)
- [../../BIN_FSMGEN_IMPORT_TREE.md](../../BIN_FSMGEN_IMPORT_TREE.md)
- [../../TASK_TREE.md](../../TASK_TREE.md)
- [../../tasks/ISF-PUBLIC-CONTRACT-SYNC.md](../../tasks/ISF-PUBLIC-CONTRACT-SYNC.md)
- [../../COMPOSITION_LEGACY_MAPPING.md](../../COMPOSITION_LEGACY_MAPPING.md)
- [../../../MEMORY.md](../../../MEMORY.md)
- [../../../ROADMAP_V2.md](../../../ROADMAP_V2.md)
- [../../../README_POLICY.md](../../../README_POLICY.md)
- [../../../LIVE_DOCUMENT_SIZE_CONTAINMENT.md](../../../LIVE_DOCUMENT_SIZE_CONTAINMENT.md)
- [../../LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.md](../../LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.md)
- [../../audits/LIVE_ACHIEVEMENT_STATUS_VALUE_AUDIT.md](../../audits/LIVE_ACHIEVEMENT_STATUS_VALUE_AUDIT.md)
- [../../audits/ROADMAP_STATUS_VALUE_AUDIT.md](../../audits/ROADMAP_STATUS_VALUE_AUDIT.md)
- [../../../TASK_ACCEPTANCE.md](../../../TASK_ACCEPTANCE.md)
- [../../../COMMIT.md](../../../COMMIT.md)

These should stay precise and sometimes narrower than the book.

`MEMORY.md` is the bounded resume pointer and `TASK_TREE.md` indexes the live
work frontier. `ROADMAP_V2.md` carries high-level direction.
`ROADMAP_STATUS.md` remains a frozen legacy record rather than a current view.
Its independent `.11` audit finds no unique current authority and recommends
retirement, while recording the directly browsable March-June 2026 chronology
and R0-R14 snapshot as its sole distinct retention case. The director's
retain/retire/re-form selection remains pending, so the audit changes no
lifecycle. Decision 0046 retains that separate lifecycle owner and the
conditional rationale-ledger owner. Decision 0047 retires the duplicate
per-slice changelog after exact current-value and consumer proof: high-level
direction stays in `ROADMAP_V2.md`, active work and evidence in task trees,
resume state in `MEMORY.md`, shipped behavior in the mdBook, and exact change
history in work-unit-bearing Git commits. The exact former changelog object is
version-retained; no replacement status blob or generated changelog is added.
Decision 0048 likewise retires the former achievement journal after the
independent `.11` audit found no executable/content consumer or current
recovery/status role. Its exact frozen 23-day digest remains version-
retrievable; task evidence, this book, bounded Memory, and Git answer its
former current questions. The roadmap-status value is assessed separately.

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
array cardinalities make the control plane finite. This retains line-oriented diffs and streaming without the
positional ambiguity of the discarded 22-column TSV prototype. The resulting
unconditional census covers every tracked Markdown path, including README
itself, broad root/focused/ancillary collections, and canonical knowledge
cards; no family topology or established limit changes in the enforcement
slice. Decision 0042 and `.6` define optional sealed task-subtree segments and
compact completed terminals. `.7` now applies the design: the live IAL2 file
keeps its active root while one exact-source segment reconstructs all 844
terminal children, and the cross-tree index keeps only three active plus eleven
proposed rows while 540 unique terminal rows remain digest-proved query history.

`TASK_ACCEPTANCE.md` is the project-neutral evidence-backed code-slice
standard. FSMGen's registered checker reads data-only staged-path and evidence
registries, requires fresh one-file ROOT CAUSE / ADDRESSED / NO REGRESSION
boxes for matching implementation changes, and leaves actual behavioral proof
to the cited focused and CI oracles.

`ISF_DOWNSTREAM_INTEGRATION_SPEC.md` is the canonical human handoff contract
for SPECFORGE-style downstream consumers. The book includes that file directly
in the ISF downstream integration chapter, so edits to the handoff document and
the book view cannot drift apart.

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

Tracked raw standards PDFs under `docs/vendor/` are local reference artifacts
for future task-tree-owned evidence or design probes. The current set includes
the Arm AMBA AXI specification plus Accellera SystemRDL 2.0, Portable Test and
Stimulus 3.0, and UVM 1.2 references. These PDFs do not by themselves ship
standard extraction, parser, lowering, scheduler, or HDL behavior.

`TASK_TREE.md` is the active-tree and PNT frontier reference. For ISF feature
work, it points to the reusable synchronization checklist in
`docs/tasks/ISF-PUBLIC-CONTRACT-SYNC.md` so public specs, book chapters,
contracts, manifests, tests, live docs, and commit hygiene stay aligned without
duplicating the checklist in every feature tree. Long-running task trees may
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

The bounded [review front door](../../LIVE_DOCUMENT_SIZE_CONTAINMENT_REVIEW.md)
summarizes the current architecture and routes forensic readers to the
content-identified
[external review packet](../../LIVE_DOCUMENT_SIZE_CONTAINMENT_EXTERNAL_REVIEW_PACKET.md).
That detailed packet explains the doctrine, schemas, pressure model, route and
archive checks, task-history migration, measured results, limitations, and 31
review questions. It is now immutable retained evidence rather than an
append-only review page. New review rounds receive new task-tree-owned
artifacts and dispositions.

PGEN and ANVIL returned independent reviews. The tracked
[disposition](../../LIVE_DOCUMENT_SIZE_CONTAINMENT_EXTERNAL_REVIEW_DISPOSITION.md)
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
depend on history uses content-addressed repository files. The 79-line review
front door has independent 100-line / 5-KiB caps and a typed route to the
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
read is capped at 64 lines and 4 KiB, every chapter is one direct link away,
and the existing Chapter 14 per-part debt remains owned by `.8`; lifecycle
selection does not bless that monolith. The book keeps all unique user-facing
prose and examples.

`docs/ISF_SPEC.md` demonstrates the opposite boundary. Its classification says
that the prose is a maintained-reference candidate, but it remains inside the
mixed `focused_documents` collection with the existing ceilings and debt.
Leaf `.13` must first create stable semantic parts and a bounded complete index.
Classification alone never waives current controls or turns a monolithic file
into a compliant maintained reference.

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
