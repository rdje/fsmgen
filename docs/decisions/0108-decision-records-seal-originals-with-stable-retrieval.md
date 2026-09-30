---
id: live-document-decision-identity-capacity
title: Decision identity rollover preserves finite compatibility paths and current canonical partitions
answers:
  - "why does sealing more decision bodies not solve decision file-count rollover?"
  - "how is the decision identity and consumer census reverified?"
  - "what contract is selected for decision identity and index cardinality rollover?"
  - "which decision consumers must change before canonical records move?"
date: 2026-09-30
status: current
tags: [continuity, decisions, doctrine, knowledge-map]
evidence: scripts/audit_decision_identity_capacity.py; docs/audits/decision-identity-capacity-20260930.json; scripts/decision_records.py; scripts/decision_catalog.py; scripts/decision_store.py; scripts/decision_store_git.py; scripts/check_live_document_ceiling_authority.pl; t/2006-decision-identity-modes.t; t/2005-decision-ceiling-stores.t; t/2004-decision-reader-snapshots.t; t/2003-decision-store-git-continuity.t; t/2002-decision-reader-stores.t; t/2001-decision-store-navigation.t; t/2000-decision-catalog-preparation.t; t/1999-decision-identity-capacity-audit.t; t/1923-decision-record-archive.t; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- python3 -B scripts/audit_decision_identity_capacity.py --revision 25c01f0127144922ade78951b91439e1d9221c08 > .artifacts/decision-identity-capacity-reverify.json
---

# 0108 — Decision records seal originals with stable retrieval

Date: 2026-09-27
Type: architecture / continuity
Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.2

## Context

The declared rationale collection reached rollover debt while a controller
architecture decision was pending. Increasing its ordinary allowance would
violate containment. The independently committed source census in
`docs/audits/decision-record-rollover-census-20260927.json` fixes record
identities and consumers before storage changes.

## Decision

Seal the complete `0001–0050` cohort in `history/0001-0050.json`. Original
UTF-8 record text is immutable and digest-checked against the prior census.
Storage does not change authority: existing supersession markers and active
policies remain exactly as written. Later semantic changes still require a
new decision and an explicit supersession reference.

Every original path remains a bounded forwarding page. The existing index
continues to discover those identities. `scripts/decision_records.py read ID`
returns original text; ordinary retrieval needs neither historical Git objects
nor network access. The generated `history/0001-0050.md` view relocates relative
links and provides stable per-record anchors. It contains no unique facts.
Its executed freshness verifier checks the entire view and all forwarding
pages against the originals, and checks affected Knowledge Map commands.

The archive is file-backed terminal storage with an exact descriptor. The
optional human view is a bounded generated projection, excluded from mandatory
bootstrap reads. Its fixed ceiling admits this sealed cohort and rendering
headers; the freshness gate prohibits appending content to either form. The
archive reader bounds every input and ID request and rejects unsafe paths,
symlinks, duplicate keys, missing/reordered records and altered original bytes.

Keep the live rationale collection's existing ceilings. Retire recovered line
and byte growth allowance; retain file-count warning pressure honestly because
stable aliases preserve cardinality. Another index/identity containment task
must precede file-count rollover. This migration grants no authority to raise
that ceiling, retire a policy, or activate the director-deferred reassessment
of other agent-era documents.

## Consequences

Direct text searches of sealed root pages now search pointers. Use the exact
reader for body searches; the affected Knowledge Map reverify commands do so.
Evidence and generated provenance retain their original decision paths.

Source identity, complete-record preservation, navigation/consumer closure,
live dimensions and residue are separate checks. Tests compare every public
reader result with the independent Git source and plant corrupt originals,
missing/duplicate/reordered members, stale views, broken aliases/index links,
missing destinations and obsolete body-search commands. Git retrieval is a
qualification oracle, not a production reader dependency.

## Identity/cardinality rollover selection — 2026-09-30

Owner `.51.3.1` audits the fixed admission revision
`25c01f0127144922ade78951b91439e1d9221c08`; the tracked census is historical,
not a copied current total. Its complete root population has 114 decision IDs
plus INDEX: 50 sealed forwarders and 64 canonical bodies. Adding one record
enters the unchanged 128-file target's rollover band. Another body seal leaves
those root identities present, so it cannot solve this dimension. Dropping
paths would break known provenance and cannot establish unseen external safety.

Select a finite pre-transition compatibility cohort and separate current
canonical semantic partitions. Preserve every existing root path and its
original heading destinations; freeze the compatibility population and its
rendering inputs so future records never create new root aliases. Keep the
existing sealed originals and exact reader. Place the unsealed canonical bodies
in continuity, language/API and verification partitions, with bounded indexes
and one complete root discovery page. New decisions belong only to those
partitions. Preserve identities, authority/supersession status, all question
keys, relative destination meaning and recoverable original text. The atomic
migration must prove source identity, semantic/navigation closure, current
working-set pressure and residue separately; ceilings do not increase.

This is an actual storage/navigation change, not permission to reclassify the
old growing collection. Its compatibility projection must be closed by exact
membership/byte/heading proofs, and current parts remain under declared finite
bounds. `.51.3.2` must split prerequisites before moving files; `.51.3.3` proves
fresh-record capacity and complete continuity before frontend work resumes.

The scoped full-basename census includes literal fragments and provenance.
Interface review also finds generic path consumers: Knowledge Map already scans
recursively, and memory bootstrap requires the root index. The ceiling-authority
validator currently admits only flat decision paths, so nested canonical
addition needs a precise authority-path integration and negative controls.
T1809 reads decision 0100's body/status directly; decisions 0062/0091 have
self-referential body searches. Their readers must follow canonical bodies.
Existing exported policy/provenance path strings remain stable. The published
sealed-reader index/navigation checks need complete partition-aware closure.
Do not alter immutable audit, calibration or historical source records.

Re-derive the fixed census with the front-matter command. The producer invokes
the pinned public reader in a same-volume temporary fixture and compares every
sealed original with its independent Git source, so future working changes do
not substitute reader inputs. Falsification uses exact index identity and
per-ID destination checks: T1999 observes equal-count duplicates, substituted
IDs, wrong destinations, missing and escaping routes refuse. T1923 preserves
original-byte and corrupt/stale navigation controls. Tracked producer, input
revision, census, tests and existing history-retention contract supply durability.
The consumer search covers tracked nonbinary full basenames; the separate
code search covers literal docs/decisions candidates in scripts/knowledge-map/
perl/t. Neither claims every dynamic or external consumer is enumerated.
No migration, external integration signoff or native HDL result is established.

## Catalog preparation contract — 2026-09-30

Owner `.51.3.2.1` supplies `scripts/decision_catalog.py` as a preparation
boundary. It neither moves sources nor changes the published reader or
ceiling-authority gate. Integrating callers must authenticate the independent
transition census before calling it; caller-supplied matching hashes alone
cannot establish historical authority. Python reading and Perl authority
integration must use this same contract rather than duplicate path/topic rules.

Canonical current locations are
`docs/decisions/current/PART/NNNN-kebab-title.md`, where PART is exactly
`continuity`, `language-api` or `verification`. The filename's ID must equal
the body's primary heading ID. Retained current IDs keep their original
basename, independently selected semantic part and index type. A new ID
follows the transition cohort's maximum; it cannot borrow a sealed ID or a
gap inside the fixed cohort. Future records do not enlarge compatibility
membership. The collection still has finite declared pressure limits; these
guards grant no ceiling increase or permanent capacity claim.

The source census, original archive and current catalog have the same closed
envelope: `schema_version`, `source_revision`, `records`. Each ordered source
row contains `id`, `path`, `kind`, `part`, `type`, `metadata`, `headings`,
`content`. Kind is `sealed` or `current`; the former has null part and the
latter one of the three parts. Paths in the source census are the original
flat locations. Complete original rows contain `id`, `path`, `text`; they
must match the census's complete ordered population, revision, dimensions and
digests. Current rows contain `id`, `path`, `type`, `metadata`, `content`.
Their complete declared transition membership must be present, with fresh
records allowed only through the closed current grammar.

Content descriptors contain exact UTF-8 `bytes`, LF `lines`, `line_bytes` and
`sha256`. Metadata contains `knowledge_id`, `knowledge_status`, ordered
`questions` and ordered `authority_status` lines. Record extraction validates
these against actual content, handles inline or listed questions, and excludes
fenced examples from heading/status identity. Relative inline status links
normalize to repository destinations so relocation cannot masquerade as a
status change. Original heading lines remain recoverable rendering inputs;
the integrated compatibility renderer must preserve their destinations.

The supplied documents, populations, paths, individual records, questions and
headings have explicit code bounds. Duplicate keys/IDs/questions/fact IDs,
reordered or missing originals, borrowed body/source identities, unknown
fields or parts, malformed dimensions/digests, unresolved files, escaping
paths and symlinks at any file component refuse. Preparation returns detached
products and never modifies caller values. A selected-snapshot bytes accessor
uses the same validation as the regular-file accessor; snapshot authentication
remains the caller's duty.

Initial rollout additionally calls `verify_transition_metadata` to compare
the complete ordered metadata with the independent source. Ordinary current
validation authenticates current status against current bytes and retains
original fact identity and every original question; it does not freeze future
owned supersession changes. Immutable originals still return their original
status. The atomic rollout must separately prove body/link meaning, complete
index closure and exact compatibility rendering; this helper is not those
proofs or a live authority admission.

Re-derivation uses the literal future-store fixtures through
`scripts/run_with_ram_guard.sh -- prove -Iperl t/2000-decision-catalog-preparation.t`.
Falsification plants same-size source corruption, borrowed metadata/IDs,
equal-count duplicates, wrong supported semantic routes, malformed dimensions,
missing files and symlinked parents; the controls observe rejection.
Durability is the tracked helper, independent literal fixtures, owning task
and this contract. Existing exact sealed reads and flat ceiling-authority
behavior are separately exercised before integration under `.51.3.2.2`.

## Authenticated store/navigation preparation — 2026-09-30

Owner `.51.3.2.2.1` adds `scripts/decision_store.py`. Its integrating caller
must supply independent fingerprints for the transition census and complete
original index. Fixed relative inputs are
`docs/audits/decision-store-transition-census.json`,
`history/transition-originals.json`, `history/transition-index.md` and
`current/catalog.json`; the latter three are below `docs/decisions/`.
They are future-store locations, not delivered live inputs at this stage.
The loader authenticates source/index bytes before calling shared catalog
preparation, and retains exact original index text alongside original records.
The index's titles, types and summaries are unique source values, not disposable
routing decoration.

Compatibility rendering uses only fixed source paths, semantic parts and
original heading lines, in their complete order. It adds no headings or
competing slug calculation. Each original heading remains a destination with
a complete-record link. Sealed records route to the existing archive view;
current records route to their selected canonical part. Exact render comparison
and complete root membership prohibit stale pages or future root aliases.

The root front door directly discovers every sealed/current identity and all
three part indexes. Part tables exactly enumerate their canonical members.
Every per-ID relative destination and type must agree; part display cells must
match the root. Equal-count duplicate/substituted/misrouted rows refuse, as do
malformed/fenced rows used as membership and missing parts or sealed anchors.
Shared fenced-example handling excludes code headings and fake closing runs;
unterminated fences refuse. Initial transition additionally preserves every
captured title/type/summary cell and complete ordered metadata. Later owned
summary/status changes are validated as current values without rewriting the
immutable original index or records.

Selected-snapshot access requires its complete root path inventory. It cannot
silently fall back to ambient worktree enumeration. Literal fixtures prove
accepted original/current products, complete fresh part navigation without
compatibility growth, and exact initial preservation. Planted source/index
fingerprint corruption, lost originals, stale headings/pages, duplicate or
escaping routes, wrong types, missing part/anchor products, extra root aliases
and symlinks refuse; a broken ambient index cannot replace selected bytes.
Run `t/2001-decision-store-navigation.t` with the RAM guard to re-derive these
results. The tracked helper, literal fixtures and owning task provide durability.
Published reading, production fingerprint installation and fresh authority
integration remain `.51.3.2.2.2-.3`; complete real body/link meaning and storage
rollout remain `.51.3.2.3`. No live path or authority is admitted here.

## Published supplied-store reader — 2026-09-30

Owner `.51.3.2.2.2` connects the authenticated store to the actual published
CLI. Supplied stores require explicit `--root`, `--source-sha256` and
`--index-sha256`, with both digests independently trusted by the caller.
Do not obtain authority merely by hashing the candidate store being checked.
These explicit supplied-store reads do not install production fingerprints or
authorize a canonical decision addition. Production fingerprints remain unset
until the atomic rollout. A catalog without installed authority cannot silently
fall back to the legacy reader.

`read` preserves captured original bytes for transition identities and returns
current bytes for fresh uncaptured IDs. `read-original` selects captured source
bytes and refuses an uncaptured fresh ID. `read-current` selects current
canonical bodies and refuses sealed-only IDs or a legacy store. Whole requests
validate before output; both request cardinality and output bytes are bounded.
`resolve` returns a small exact canonical ID/path/content/source binding after
complete store verification. A compatibility, escaping or wrong-part path is
not a canonical binding. This lookup alone grants no new authority.

Current metadata may acquire a unique first fact identity where the original
had none. Existing source identities/questions still cannot be lost; exact
initial transition comparison still refuses that additive change at rollout.
Immutable original bytes keep their captured absence. Owned later status
changes similarly appear only in current products. Independent actual CLI
fixtures observe both products and their failures.

The no-catalog sealed reader retains its old check/read behavior and adds an
explicit original operation. Its schema requires an integer; the former Python
equality check incorrectly admitted JSON true and a floating version as one.
Actual reproduction observed true return original bytes; strict-kind controls
now refuse with no partial output. Delivered production stores must also match
every already-published sealed original and preserve archive-view/body-search
checks. Supplied fictional cohorts never replace that production provenance.
Lazy store loading preserves captured standalone legacy-reader capsules, and
the CLI disables bytecode writes.

Re-derive with guarded `t/2002-decision-reader-stores.t` and T1923. Literal
CLI products, unknown/unavailable/oversized requests, altered fingerprints,
missing catalog products, wrong canonical bindings and original substitution
are observed controls. Tracked CLI/helpers/tests and this owner provide
durability. Standalone current validation cannot infer births after its fixed
census: `.51.3.2.2.3` owns unconditional prior-to-current ID/path/fact/question
continuity before production admission, including deletion/reuse controls.
Real fingerprint installation, fresh authority and source rollout remain open.

## Selected Git access and identity continuity — 2026-09-30

Owner `.51.3.2.2.3.1` adds `scripts/decision_store_git.py`. A snapshot captures
the complete finite path/mode/object inventory once, from the staged index or
a resolved immutable revision. It reads by captured blob ID, so later index,
HEAD or working changes cannot substitute data. Selectors, path inventories,
Git output and individual blobs are bounded. Unsafe paths/selectors, conflicting
stages, missing/oversized blobs and symlink/gitlink/nondirectory ancestors
refuse. Inventory traversal never enters submodules; a gitlink is metadata,
never an admissible regular source. Selected root Markdown inventory accompanies
the exact bytes accessor rather than coming from ambient directories.
Git root resolution must match the requested repository; replacement refs,
lazy remote fetching and optional locks cannot alter captured reads.

Authenticated store products now retain the independent census/index digests
alongside their exact original values. Prior-to-current comparison requires
the source revision, both authority fingerprints, compatibility cohort,
originals and original index/routes to remain unchanged. Every prior current
ID must remain at its exact path and type. Existing fact IDs and all question
keys remain, including those first introduced after the transition snapshot.
New births follow the prior highest ID; earlier gaps cannot be reused.
Owned content/status/summary updates and additive first fact indexing remain
possible. This comparison consumes already-authenticated complete products;
it is not a substitute for each snapshot's byte/navigation verification.

Literal controls and repository-local Git fixtures prove exact staged/revision
loading, frozen object IDs after later commits and immunity to ambient edits.
The previously self-consistent deletion of a post-transition record now refuses
when compared with its prior product. Known-bad source/digest/original changes,
equal-count ID/path/type recycling, lost post-transition fact/question keys,
earlier-gap births, conflicts, links and byte bounds refuse. Re-derive with
guarded `t/2003-decision-store-git-continuity.t`. Tracked shared helpers/tests
and the task provide durability. `.51.3.2.2.3.2` must wire this comparison
unconditionally into actual selected-store/public/Perl gates; `.3` qualifies
all modes before real source rollout. No production pin or new authority is
installed by these prerequisites.

## Published selected products and change checks — 2026-09-30

Owner `.51.3.2.2.3.2.1` exposes the shared selected Git accessor through the
actual reader. All read/check/resolve products use the captured bytes and root
inventory; legacy archive/link/body-search checks consume the same snapshot.
The filesystem default and standalone legacy capsule remain available.
Supplied independent fixture digests require an explicit other root and cannot
override the reader's actual repository authority, with or without installed
production pins.

The atomic `check-continuity` operation authenticates both current and exact
Git predecessor stores before comparing complete prior identities. Optional
canonical paths return verified bindings and text plus prior-relative
freshness. A post-transition birth is no longer fresh after publication.
First catalog adoption matches the exact predecessor revision, complete root
population, original index, sealed archive originals and flat current originals;
transition metadata/navigation must also remain exact. Removal, malformed
requests or identity loss produces no partial result. Both absent catalogs
return an explicit non-catalog product, not a claim about sealed-reader checks.

Actual same-volume Git fixtures re-derive selected current products, adoption
and staged/worktree/committed birth bindings. Literal originals and planted
ambient/index/source/predecessor/deletion/removal/request/authority substitutions
falsify the contract. Tracked reader/test, this card and the task provide
durability; re-derive with guarded `t/2004-decision-reader-snapshots.t`.
Actual unconditional Perl gate enforcement remains child `.2`; production
pins and source migration remain `.51.3.2.3`.

## Actual ceiling-authority integration — 2026-09-30

Owner `.51.3.2.2.3.2.2` integrates the actual Perl gate with the authenticated
public change product. Controlled-path selection includes store/source/reader
changes, not only registry increases. Every change involving a catalog verifies
its complete prior-current identities. Ordinary births and owned updates do
not need a ceiling authority, but still cannot delete/recycle published keys.
Resolved immutable current commits determine their own exact parent snapshot.

Optional reader file bindings authenticate the gate's registry/authority bytes
against the same captured inventory. A real fixture dispatch changes the index
registry after the Perl read; the selected fingerprint mismatch refuses it.
Canonical authority uses verified current text, exact markers outside fences,
prior-relative ID freshness and file absence in the selected predecessor.
Neither relocation nor a previously published birth becomes fresh authority.
Existing flat historical authorities and no-catalog fixtures retain their
contracts. Fixture trust requires an explicit other root and independent pins;
actual-root overrides refuse. Reader output and diagnostics are streamed within
fixed bounds, and nonzero/signal failure cannot be interpreted as success.

P2 schema-kind repair: the predecessor Perl parser treated JSON true as version
one. Red actual-gate T2005 returned success for staged Boolean surface metadata.
Reference-valued versions now refuse in surface/authority metadata and authority
rows. Git traces the original bounded parser to
`2e10cc605f1dec9259b18d9b9d568c35882105a6`.

Actual independent fixture products and all selected modes re-derive successful
fresh authority and ordinary birth behavior. Planted identity deletion,
removal, ambient disagreement, source corruption, borrowed IDs, fenced-only
markers, mutable control substitutions and Boolean/authority overrides falsify
the boundary. Tracked code/tests, this card and the task provide durability;
re-derive with guarded `t/2005-decision-ceiling-stores.t` and the existing reader,
legacy authority and containment cohorts. Sibling `.51.3.2.2.3.3` still owns the
broader hostile mode matrix before real source rollover `.51.3.2.3`.

## Independently complete post-transition mode controls — 2026-09-30

Owner `.51.3.2.2.3.3.1` publishes a literal post-transition fact-bearing birth
in each independent fixture before changing it. Current byte descriptors,
metadata and complete root/part routes are updated consistently. Standalone
current authentication/navigation passes every planted deletion, equal-count
birth replacement, path/type recycle, fact deletion/replacement, question
loss/substitution and earlier-gap birth. The actual prior-aware Perl gate then
refuses each in working, staged and committed modes without a ceiling increase.

Owned body/status/summary changes and additive questions retain prior keys and
pass every mode. The standalone/current and prior-aware checks are separate
legs; a stale digest or malformed index cannot falsely earn the identity-floor
proof. Exact source/index/original/control baselines and same-volume fixtures
remain independent. Tracked `t/2006-decision-identity-modes.t`, this card and the
task provide durability. Remaining malformed product/authority/caller/IPC
qualification stays child `.2` before the atomic real source rollover.
