# CLAIM-VERIFICATION-ADOPTION: Adopt Three-Leg Claim Verification

## Metadata

- Tree ID: `CLAIM-VERIFICATION-ADOPTION`
- Status: `active`
- Roadmap lane: `infra/evidence governance`
- Created: `2026-08-20`
- Last updated: `2026-08-20`
- Owner: repo-local workflow

## Goal

Adopt a project-owned claim-verification standard so every actionable
quantitative claim names dimensionally distinct re-derivation, falsification,
and durability evidence, and so missing evidence is visible instead of being
hidden behind repeated checks of the same kind.

## Non-Goals

- Do not claim that a structural tag or doctrine gate can prove human intent,
  semantic truth, or the independence of an oracle by itself.
- Do not convert dates, versions, task IDs, schema identifiers, HDL literals,
  example values, or transient command output into permanent claim records
  merely because they contain digits.
- Do not change FSMGen language, lowering, HDL, verification, or support
  behavior while adopting this evidence policy.
- Do not treat the originating PGEN copy as an automatically synchronized
  upstream after FSMGen adopts its own authoritative copy.

## Acceptance Criteria

- FSMGen owns an authoritative repository-root `CLAIM_VERIFICATION.md` with a
  fenced local adoption note and explicit discovery from the tool-neutral
  bootstrap and stable documentation routes.
- Actionable quantitative claims use a bounded record that names the claim,
  re-derivation, a separating falsification oracle or an explicit missing leg,
  and durable producer/watcher evidence or an explicit missing leg.
- A registered doctrine check validates the mechanically decidable record
  shape and its declared tracked paths, runs through the commit hook and CI
  doctrine driver, and has positive plus deliberately failing controls.
- Existing high-traffic current surfaces and repository-derived constants are
  inventoried; each actionable claim is migrated, derived/gated, or assigned a
  task-owned debt disposition without pretending the inventory proves truth.
- Focused validation and `scripts/check_doctrines.sh` pass for every slice;
  full CI remains reserved for the next push or a separately selected major
  boundary.
- The task index and bounded resume pointer remain synchronized, and each
  completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `CLAIM-VERIFICATION-ADOPTION`
  Status: `active`
  Goal: `Adopt and enforce dimensionally independent claim evidence.`
  Children: `CLAIM-VERIFICATION-ADOPTION.1, CLAIM-VERIFICATION-ADOPTION.2, CLAIM-VERIFICATION-ADOPTION.3, CLAIM-VERIFICATION-ADOPTION.4, CLAIM-VERIFICATION-ADOPTION.5, CLAIM-VERIFICATION-ADOPTION.6`

- ID: `CLAIM-VERIFICATION-ADOPTION.1`
  Status: `done`
  Goal: `Select FSMGen's local authority, scope, three-leg record, enforcement boundary, and migration sequence.`
  Acceptance: `Decision 0074 records the project-owned contract, the distinction between actionable claims and incidental numerals, the honest limit of structural enforcement, and the separately owned implementation leaves.`
  Verification: `PASS — scripts/check_task_tree_integrity.pl; scripts/check_docs_relative_paths.sh; git diff --check`
  Commit: `CLAIM-VERIFICATION-ADOPTION.1: select three-leg claim evidence`

- ID: `CLAIM-VERIFICATION-ADOPTION.2`
  Status: `done`
  Goal: `Install the project-owned standard and wire stable discovery surfaces.`
  Acceptance: `The root standard has a fenced FSMGen adoption note; AGENTS, README, doctrine architecture, commit guidance, and the book reference map point to the canonical copy without duplicating its body; containment owns every new live path.`
  Verification: `PASS — neutral-body SHA-256 identity; bootstrap syntax/invariants; README routing; live-document/reference authority; docs-relative-path tests; mdBook build; doctrine gate`
  Commit: `CLAIM-VERIFICATION-ADOPTION.2: install the authoritative claim standard`

- ID: `CLAIM-VERIFICATION-ADOPTION.3`
  Status: `done`
  Goal: `Implement the bounded claim-record checker and register it as a doctrine.`
  Acceptance: `A data-only bounded registry and deterministic checker validate claim IDs, source paths, exact record markers, all three named legs or explicit gaps, tracked producers/watchers, and path locality; positive fixtures pass and mutations that remove or alias a leg demonstrably fail RED.`
  Verification: `PASS — bounded registry/checker; 8 positive, gap, and RED subtests; bootstrap/Knowledge Map/live-document gates; mdBook; doctrine gate`
  Commit: `CLAIM-VERIFICATION-ADOPTION.3: gate bounded three-leg claim records`

- ID: `CLAIM-VERIFICATION-ADOPTION.4`
  Status: `done`
  Goal: `Inventory existing actionable quantitative claims and derived constants on mandatory/current surfaces.`
  Acceptance: `The producer-derived sweep covers 73 current Markdown sources and 615 numeric doctrine constants; it partitions 10,666 numeric lines into 1,417 actionable candidates and four explicit incidental classes, reports producer/watcher state, and assigns every open candidate to CLAIM-VERIFICATION-ADOPTION.5 without representing the inventory as truth proof.`
  Verification: `PASS — independent git-grep census parity; canonical tracked inventory identity; Files=1, Tests=5 for drift, conservative-classifier, untracked-producer, and structural-partition RED controls; bootstrap/live-document gates`
  Commit: `CLAIM-VERIFICATION-ADOPTION.4: inventory current claims and constants`

- ID: `CLAIM-VERIFICATION-ADOPTION.5`
  Status: `active`
  Goal: `Migrate or gate the inventoried claims in bounded, surface-owned slices.`
  Acceptance: `Each claim is re-derived, falsified by a separating oracle where available, and made durable, or it names its missing leg and a task-owned repair; repository-derived constants are derived or input-identity gated rather than hand-carried.`
  Verification: `The current inventory partitions 1,415 candidates exactly into 70 root-document, 268 general-book, 557 protocol/profile/integration, 232 IAL2-AHB, and 288 HIAL/VIAL-verification candidates. Child .5.1 first gates review dispositions; .5.2-.5.6 then consume those five disjoint groups; .5.7 proves zero open migration owners and rechecks the governed doctrine constants.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5: partition claim migration frontier`
  Children: `CLAIM-VERIFICATION-ADOPTION.5.1, CLAIM-VERIFICATION-ADOPTION.5.2, CLAIM-VERIFICATION-ADOPTION.5.3, CLAIM-VERIFICATION-ADOPTION.5.4, CLAIM-VERIFICATION-ADOPTION.5.5, CLAIM-VERIFICATION-ADOPTION.5.6, CLAIM-VERIFICATION-ADOPTION.5.7`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.1`
  Status: `done`
  Goal: `Define and gate the bounded candidate-review disposition contract.`
  Acceptance: `The canonical bounded disposition and five-group registries join stable current candidate IDs to claim-record, derived-gate, reviewed-incidental, or explicitly owned-gap outcomes; outcome-specific evidence, tracked path locality, live gap owners, and group completion are gated while the deliberately empty first registry leaves all 1,417 candidates visibly open.`
  Verification: `PASS — disposition report reproduces 72 + 268 + 557 + 232 + 288 open candidates; Files=1, Tests=9 prove all four outcomes plus stale, duplicate, unknown, missing, aliased, incomplete, fabricated-source, and closed-gap-owner RED controls; 628-constant inventory, bootstrap, Knowledge Map, live-document, mdBook, and doctrine gates`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.1: gate candidate review dispositions`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.2`
  Status: `done`
  Goal: `Review and migrate the 70 current root-document claim candidates.`
  Acceptance: `Every root-document candidate receives an exact gated disposition; current policy constants and historical/rationale measurements are distinguished, published claims gain three-leg evidence or owned gaps, and incidental structure is reclassified only with a reviewable reason.`
  Verification: `PASS — children .5.2.1-.5.2.4 close the exact 32 + 8 + 18 + 12 root partition; the canonical join reports 70/70 disposed as 44 derived gates plus 26 reviewed non-operational references, zero open root candidates, and root_documents required-complete.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.2: partition root claim review`
  Children: `CLAIM-VERIFICATION-ADOPTION.5.2.1, CLAIM-VERIFICATION-ADOPTION.5.2.2, CLAIM-VERIFICATION-ADOPTION.5.2.3, CLAIM-VERIFICATION-ADOPTION.5.2.4`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.2.1`
  Status: `done`
  Goal: `Disposition the 32 current non-rationale root policy, index, route, and structural candidates.`
  Acceptance: `Every candidate outside DEVELOPMENT_NOTES.md is mapped to a real current policy/input gate, an exact archive or structural projection gate, a reviewed incidental identity/navigation reason, or a live owned repair without conflating declared policy with measured truth.`
  Verification: `PASS — stale README ceiling wording repaired; current inventory 1,416 candidates / 660 governed constants; exact root join 32 disposed / 39 open with 15 derived gates and 17 reviewed non-claims; archive, ledger, task, Knowledge Map, RAM, inventory, and disposition RED suites Files=8/Tests=88; bootstrap, docs paths, Memory, Knowledge Map, README/live-document/reference authority, mdBook test/build, and diff checks pass`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.2.1: disposition non-rationale root claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.2.2`
  Status: `done`
  Goal: `Repair unsupported UVM resource precision and disposition the 8 remaining foundational rationale candidates before the bridge-scale entries.`
  Acceptance: `The rationale-ledger, book-partition, roadmap-archive, UVM-resource, and provider-profile measurements each name their exact producer, separating oracle, and durable watcher or an explicit live repair task; immutable historical context is not mistaken for current support.`
  Verification: `PASS — unsupported exact UVM peak removed while the checked low-optimization resource control remains; regenerated inventory 1,415 candidates / 668 governed constants; exact root join 40 disposed / 30 open with 18 derived gates and 22 reviewed non-claims; all 8 remaining foundational candidates close as 3 live gates plus 5 immutable historical measurements; OSVVM source-order reconstruction added; focused Files=6/Tests=30 plus inventory, disposition, docs, live-document, mdBook, and doctrine gates`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.2.2: disposition foundational rationale claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.2.3`
  Status: `done`
  Goal: `Disposition the 18 bridge and execution-scale rationale candidates.`
  Acceptance: `The bridge-byte/source-map, scenario-map, total/live-fiber, and execution-type measurements join exact current producers and separating limit/mutation oracles or live repairs without borrowing one scale axis as proof of another.`
  Verification: `PASS — all 18 bridge/execution candidates close as 14 derived gates plus 4 reviewed historical/structural references; exact root join 58 disposed / 12 open with 32 gates and 26 reviewed outcomes; the bridge oracle now differentially reconstructs its real semantic baseline and increments; RAM-guarded exact bridge plus semantic/topology/fiber/type regressions pass at Files=5/Tests=34; regenerated inventory reports 1,415 candidates / 686 governed constants; synchronized inventory, disposition, book, Knowledge Map, live-document, staged-acceptance, and doctrine gates pass`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.2.3: disposition bridge execution claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.2.4`
  Status: `done`
  Goal: `Disposition the 12 current checking-scale rationale candidates and close the root group.`
  Acceptance: `The owned-shape, model, scoreboard, coverage, fault, and random-scale measurements join exact current producers and independent reconstruction/mutation oracles or live repairs; all 70 current root candidates are dispositioned and root_documents becomes required-complete.`
  Verification: `PASS — all 12 checking-scale candidates close as derived gates over the owned-shape, model, scoreboard, coverage, fault, and random-replay families; the model oracle additionally verifies authored definition/instance/declaration factorization; the RAM-guarded exact collection reports Files=6/Tests=30; inventory regenerates 1,415 candidates / 698 governed constants; root_documents is required-complete at 70/70.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.2.4: disposition checking scale claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.3`
  Status: `done`
  Goal: `Review and migrate the 268 general language, control, tooling, and reference-book candidates.`
  Acceptance: `Every shipped-behavior candidate outside the named protocol, IAL2-AHB, and HIAL/VIAL-verification clusters receives an exact gated disposition without weakening examples or turning syntax literals and navigation identifiers into claims.`
  Verification: `PASS — the five disjoint children close 35 + 43 + 68 + 71 + 51 = 268 candidates as 204 derived gates plus 64 reviewed outcomes; general_book is required-complete with zero open identities.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.3: partition general book claim review`
  Children: `CLAIM-VERIFICATION-ADOPTION.5.3.1, CLAIM-VERIFICATION-ADOPTION.5.3.2, CLAIM-VERIFICATION-ADOPTION.5.3.3, CLAIM-VERIFICATION-ADOPTION.5.3.4, CLAIM-VERIFICATION-ADOPTION.5.3.5`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.3.1`
  Status: `done`
  Goal: `Disposition the 35 core language, composition, diagnostics, extensions, and tooling candidates in Chapters 02-12.`
  Acceptance: `Every candidate on the ten selected chapter paths joins its exact current grammar/runtime/tooling producer and a separating oracle, a reviewed syntax/navigation/example reason, or an explicit repair without overstating shipped behavior.`
  Verification: `PASS — all 35 candidates close as 26 derived gates plus 9 reviewed syntax/example/identifier outcomes; the LTE corpus oracle independently counts 36 active child references; the RAM-guarded exact collection reports Files=22/Tests=7,487; inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.3.1: disposition core language claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.3.2`
  Status: `done`
  Goal: `Disposition the 43 intent-scheduling, actor-interface, and transaction candidates in Chapters 13, 13a, and 13b.`
  Acceptance: `Scheduling, actor, interface, and transaction measurements retain distinct current producers and falsification controls, while syntax literals and example data are reviewed only with exact reasons.`
  Verification: `PASS — all 43 candidates close as 42 derived gates plus one reviewed example numeral; published repeat timing and actor payload-width prose now match the lowerer; schedule JSON carries exact transaction ownership through injected latency states; the RAM-guarded exact collection reports Files=36/Tests=602; inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.3.2: disposition intent timing claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.3.3`
  Status: `done`
  Goal: `Disposition the 68 control-flow, data, composition, rules, lowering, and type candidates in Chapters 13d-13j.`
  Acceptance: `Every selected semantic or lowering claim is tied to the exact parser/lowerer/runtime projection and a separating oracle, or receives an exact reviewed-incidental or owned-repair outcome.`
  Verification: `PASS — all 68 candidates close as 60 derived gates plus eight reviewed instructional/example numerals; the lowering reference now matches check-first repeat timing and target-derived drive payload widths; the RAM-guarded exact collection reports Files=54/Tests=603 with 82 complete book fixtures lowering cleanly; inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.3.3: disposition control data claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.3.4`
  Status: `done`
  Goal: `Disposition the 71 feature-matrix and non-protocol backlog candidates in Chapters 13k and 14-14k.`
  Acceptance: `Current support claims join executable support-accounting producers and negative controls; backlog identifiers, priorities, and structural references remain explicitly distinct from shipped capability evidence.`
  Verification: `PASS — all 71 candidates close as 62 derived gates plus nine reviewed identifiers/example numerals; the stale book-audit count is repaired to 82 complete fixtures; RAM-guarded evidence reports Files=30/Tests=590 plus the filtered AXI Files=1/Tests=6; inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.3.4: disposition support backlog claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.3.5`
  Status: `done`
  Goal: `Disposition the 51 implementation-blueprint, platform-intent, and reference-map candidates in Chapters 15, 16, and 90.`
  Acceptance: `Blueprint and platform claims join exact current producers and separating oracles while historical, navigation, policy, and migration references receive narrowly reviewable outcomes.`
  Verification: `PASS — all 51 candidates close as 14 derived gates plus 37 reviewed policy, historical, structural, and navigation outcomes; activation-only occupancy is explicitly past-tense; the RAM-guarded exact collection reports Files=14/Tests=121; inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass; general_book is required-complete at 268/268.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.3.5: disposition blueprint reference claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4`
  Status: `active`
  Goal: `Review and migrate the 557 protocol-profile and integration-book candidates.`
  Acceptance: `Every candidate in 14f, 14g, 14h, 14i, 14j, 14l, 16a, 16aa, and 16b is dispositioned against executable protocol/profile/integration producers and separating oracles, or carries an exact owned gap; repeated measurements share evidence only when they are demonstrably the same claim.`
  Verification: `PASS — the committed protocol group partitions exactly into 16 evidence-coherent children whose disjoint path/range counts sum to 557; .5.4.1 alone is active.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.4: partition protocol claim review`
  Children: `CLAIM-VERIFICATION-ADOPTION.5.4.1, CLAIM-VERIFICATION-ADOPTION.5.4.2, CLAIM-VERIFICATION-ADOPTION.5.4.3, CLAIM-VERIFICATION-ADOPTION.5.4.4, CLAIM-VERIFICATION-ADOPTION.5.4.5, CLAIM-VERIFICATION-ADOPTION.5.4.6, CLAIM-VERIFICATION-ADOPTION.5.4.7, CLAIM-VERIFICATION-ADOPTION.5.4.8, CLAIM-VERIFICATION-ADOPTION.5.4.9, CLAIM-VERIFICATION-ADOPTION.5.4.10, CLAIM-VERIFICATION-ADOPTION.5.4.11, CLAIM-VERIFICATION-ADOPTION.5.4.12, CLAIM-VERIFICATION-ADOPTION.5.4.13, CLAIM-VERIFICATION-ADOPTION.5.4.14, CLAIM-VERIFICATION-ADOPTION.5.4.15, CLAIM-VERIFICATION-ADOPTION.5.4.16`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.1`
  Status: `active`
  Goal: `Disposition the 65 AXI-manager-core and dynamic-identity backlog candidates in Chapters 14f and 14g.`
  Acceptance: `Current generated AXI manager capacity, identity, demux, ordering, and output-bank statements join distinct executable evidence; selectors, historical checkpoints, and deferred-boundary numerals remain distinguishable from shipped behavior.`
  Verification: `exact 31 + 34 path census, focused manager/dynamic-identity producers and mutations, inventory/disposition/mdBook/doctrine gates`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.2`
  Status: `pending`
  Goal: `Disposition the 11 foundational profile/APB candidates in Chapter 14h lines 1-850 and Chapter 16b.`
  Acceptance: `Profile-alias chronology, APB endpoint/completer/interconnect foundations, and the shipped APB example chapter retain current evidence without promoting task identifiers or mode-map navigation into capability proof.`
  Verification: `exact 7 + 4 range/path census, focused profile/APB foundation gates, inventory/disposition/mdBook/doctrine gates`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.3`
  Status: `pending`
  Goal: `Disposition the 35 APB width, sideband, status, and timing candidates in Chapter 14h lines 851-1199.`
  Acceptance: `Data/strobe widths, protection/status fields, queue depth, and selected timing families join the exact APB generators and separating boundary cases.`
  Verification: `exact range census, APB width/sideband/status/timing gates and mutations, inventory/disposition/mdBook/doctrine gates`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.4`
  Status: `pending`
  Goal: `Disposition the 46 APB multi-register, protection, and composition candidates in Chapter 14h lines 1200-1699.`
  Acceptance: `Selected 16/32-bit multi-register, protected, queued, fixed-composition, and multi-peripheral measurements retain separate source-shape and runtime evidence.`
  Verification: `exact range census, multi-register/protection/composition gates and mutations, inventory/disposition/mdBook/doctrine gates`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.5`
  Status: `pending`
  Goal: `Disposition the 37 generalized APB register-set candidates in Chapter 14h lines 1700-1999.`
  Acceptance: `Generalized two-peripheral register-set widths, strides, windows, counts, and protection policies join exact generated artifacts and adjacent-boundary controls.`
  Verification: `exact range census, generalized-register-set gates and excess controls, inventory/disposition/mdBook/doctrine gates`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.6`
  Status: `pending`
  Goal: `Disposition the 28 expanded APB register-bound candidates in Chapter 14h lines 2000-end.`
  Acceptance: `Five- and six-register 16/32-bit protected and unprotected families keep explicit count/stride/width producers and fail-closed neighboring bounds.`
  Verification: `exact range census, expanded-register-bound gates and adjacent excess controls, inventory/disposition/mdBook/doctrine gates`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.7`
  Status: `pending`
  Goal: `Disposition the 40 foundational AHB endpoint, interconnect, HBURST, and BUSY candidates in Chapter 14i lines 1-1070.`
  Acceptance: `Endpoint and aggregate topologies, byte-lane/SEQ/BUSY policies, profile aliases, support counts, and runtime behavior retain distinct producer/oracle chains.`
  Verification: `exact range census, foundational AHB endpoint/interconnect/HBURST/BUSY gates, inventory/disposition/mdBook/doctrine gates`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.8`
  Status: `pending`
  Goal: `Disposition the 49 AHB semantic-repair and exact-two/three requester-BUSY candidates in Chapter 14i lines 1071-1406.`
  Acceptance: `Wrap progression, data-phase ownership, error timing, conditional BUSY insertion, exact count runtime, aliases, and integration surfaces join independent semantics and generated-HDL evidence.`
  Verification: `exact range census, AHB semantic/runtime/alias gates and mutations, inventory/disposition/mdBook/doctrine gates`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.9`
  Status: `pending`
  Goal: `Disposition the 27 AHB arbitration and exact-three paired-composition candidates in Chapter 14i lines 1407-1661.`
  Acceptance: `Default-decode arbitration repair and one-/two-subordinate exact-three paired compositions retain exact topology, artifact, support, and assertion-enabled runtime evidence.`
  Verification: `exact range census, arbitration and exact-three paired gates, inventory/disposition/mdBook/doctrine gates`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.10`
  Status: `pending`
  Goal: `Disposition the 35 exact-four requester and paired-composition candidates in Chapter 14i lines 1662-1779.`
  Acceptance: `Minimum counter widths, literal bounds, exact-four requester runtime, paired aggregate behavior, aliases, and support checkpoints join distinct generated evidence.`
  Verification: `exact range census, exact-four requester/paired gates and boundary mutations, inventory/disposition/mdBook/doctrine gates`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.11`
  Status: `pending`
  Goal: `Disposition the 32 two-subordinate exact-four and generalized BUSY-range candidates in Chapter 14i lines 1780-1895.`
  Acceptance: `Two-window exact-four runtime, aliases, generated artifact counts, support identity, and generalized literal 2..16 behavior retain separate runtime and fail-closed evidence.`
  Verification: `exact range census, two-subordinate/generalized-BUSY gates and adjacent invalid controls, inventory/disposition/mdBook/doctrine gates`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.12`
  Status: `pending`
  Goal: `Disposition the 17 AHB integration and public-synchronization candidates in Chapter 14i lines 1896-end.`
  Acceptance: `Post-AHB integration selections, ISF/book synchronization measurements, diagram migrations, task-ledger repairs, and Chapter 16c handoffs remain correctly classified as current gates or immutable history.`
  Verification: `exact range census, integration/reference/task reconstruction gates, inventory/disposition/mdBook/doctrine gates`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.13`
  Status: `pending`
  Goal: `Disposition the 6 extended-AXI backlog candidates in Chapter 14j.`
  Acceptance: `Mixed dynamic/static demux claims join exact generated behavior while selectors and bounded contract numerals remain narrowly classified.`
  Verification: `exact path census, extended-AXI demux gates and mutations, inventory/disposition/mdBook/doctrine gates`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.14`
  Status: `pending`
  Goal: `Disposition the 40 backend, validation, and public-API backlog candidates in Chapter 14l.`
  Acceptance: `VHDL/backend support, external validation, generation structure, semantic export, and embedding/API statements join their exact producers and negative controls without promoting roadmap residue.`
  Verification: `exact path census, backend/validation/API gates and mutations, inventory/disposition/mdBook/doctrine gates`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.15`
  Status: `pending`
  Goal: `Disposition the 46 shipped AXI IAL2 example candidates in Chapter 16a.`
  Acceptance: `Guided, initiator, more-control, raw, write/read, single/four-beat, and validation statements join executable example and lowering evidence; headings and syntax values remain non-claims where appropriate.`
  Verification: `exact path census, AXI example lowering/runtime/validation gates, inventory/disposition/mdBook/doctrine gates`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.16`
  Status: `pending`
  Goal: `Disposition the 43 AXI manager capacity/status candidates in Chapter 16aa.`
  Acceptance: `ID families, transaction events, auto/dynamic IDs, ordering, output capture/banks, raw ARLEN, and bounded progression claims retain exact generated/report/runtime evidence.`
  Verification: `exact path census, capacity/status producer and mutation gates, inventory/disposition/mdBook/doctrine gates`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.5`
  Status: `pending`
  Goal: `Review and migrate the 232 IAL2-AHB execution-scale book candidates.`
  Acceptance: `Every 16c candidate is tied to its exact scale/gate producer and a separating excess or mutation oracle, reclassified as reviewed incidental, or assigned an explicit repair; historical observations are not promoted into current support claims.`
  Verification: `16c group identity/count, scale producer reruns and adjacent-excess RED controls, zero open group candidates, mdBook/doctrine gates`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.6`
  Status: `pending`
  Goal: `Review and migrate the 288 HIAL/VIAL verification-architecture book candidates.`
  Acceptance: `Every 16d candidate is tied to exact architecture-scale, backend, runtime, result, or capability evidence with a separating oracle, reclassified with a reviewable incidental reason, or assigned an explicit repair without overstating provider or support coverage.`
  Verification: `16d group identity/count, exact architecture/runtime producer and RED controls, zero open group candidates, mdBook/doctrine gates`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.7`
  Status: `pending`
  Goal: `Reconcile all migrated claims and governed constants into a zero-open-owner inventory.`
  Acceptance: `The regenerated inventory has no candidate still owned by CLAIM-VERIFICATION-ADOPTION.5, every claim/disposition identity is current and three-leg honest, all 615 originally inventoried numeric doctrine constants are still derived/watched or input-identity gated, and no migration artifact is off-volume or untracked.`
  Verification: `complete disposition/inventory join, zero-open-owner assertion, constant census parity and watcher/input RED controls, mdBook/doctrine gates`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-ADOPTION.6`
  Status: `pending`
  Goal: `Close adoption with a complete current-surface audit and recoverable handoff.`
  Acceptance: `The authoritative policy, discovery, registry, checker, migrated claims, explicit debt, task evidence, book, and resume pointer agree; no adoption artifact is off-volume, untracked, or reachable only from conversation.`
  Verification: `focused adoption suite, full doctrine gate, clean tracked/untracked census, and task integrity`
  Commit: `pending`

## Decisions

- `2026-08-20`: Decision `0074` selects re-derive, falsify, and durability as
  three distinct publication legs. Structural enforcement checks declared
  records and evidence plumbing; it never represents formatting as proof of a
  claim's semantic truth.
- `2026-08-20`: The external PGEN document is an adoption source, not a live
  dependency. FSMGen's repository-root copy becomes authoritative once leaf
  `.2` lands.
- `2026-08-20`: Adoption precedes the recorded HIAL backend-emission frontier
  because the director explicitly requested this missing policy and the
  repository was clean, making the pivot handoff-safe.
- `2026-08-20`: The inventory classifier has no incidental fallback. Numeric
  prose not proven to be structure, code/data, a watched generated projection,
  or an identifier remains actionable review debt owned by leaf `.5`.
- `2026-08-20`: The committed inventory places 1,345 of 1,417 candidates in
  the mdBook. Migration therefore uses one root-doc slice, one general-book
  slice, and three evidence-coherent book clusters rather than one oversized
  documentation rewrite; a separate first child installs disposition honesty.
- `2026-08-20`: A migration group remains `required_complete=false` until its
  owning slice has dispositioned every current candidate. The empty `.5.1`
  outcome registry therefore proves mechanism and reports debt; it does not
  misrepresent any of the 1,417 candidates as reviewed.
- `2026-08-20`: Root review is split by evidence family, not file count. The
  39 rationale-ledger candidates require three chronological semantic slices,
  while the other eight root files plus the rationale index form one bounded
  policy/structure slice.
- `2026-08-20`: Leaf `.5.2.1` found that `README_POLICY.md` still described
  its inclusive ceilings as pinned to the 246-line / 9,952-byte adoption
  survivor even though the governed values had correctly ratcheted to the
  smaller current README. The repaired policy distinguishes historical
  baseline, health target, and derived current ceiling; regeneration removes
  one stale candidate, so the current frontier is 1,416 total / 71 root / 32
  non-rationale root candidates. Earlier `.4` and `.5.1` verification rows
  retain their then-current 1,417-candidate results as historical evidence.
- `2026-08-20`: Leaf `.5.2.2` found that the experimental UVM rationale's
  exact 4-GiB optimized-build peak had no tracked measurement producer. The
  durable probe proves the selected guarded-envelope failure outcome and the
  lower-memory `-O0` control, but not that discarded point estimate. Removing
  the unsupported precision is the repair; the regenerated inventory has
  1,415 candidates / 70 root candidates, with eight foundational candidates
  retained and dispositioned. Historical book and roadmap measurements name
  immutable Git producers and their preserved audits rather than posing as
  current occupancy or support claims.
- `2026-08-20`: Bridge and execution measurements remain separate evidence
  families. Source-map calibration is reconstructed by differential semantic
  builds rather than inferred from fact-path prefixes; topology collision is
  retained as an immutable pre-repair observation; total and live fibers use
  distinct tree-shape oracles; execution types count only shapes exercised by
  real public bindings. Rejected hypothetical shapes are reviewed context,
  not evidence for the selected gates.
- `2026-08-20`: Checking-scale evidence remains factored by semantic family.
  The owned-shape oracle derives both sides of the catalog partition; model
  evidence separately counts authored definitions, instances, declarations,
  and exercised cells; scoreboard, coverage, and fault evidence reconstruct
  their own storage, order, and lifecycle identities. Random-replay evidence
  distinguishes semantic preflight, bridge materialization, plan rejection,
  and the adjacent semantic diagnostic. The exact guarded suite closes the
  root group without borrowing any one aggregate as proof of another.
- `2026-08-20`: The general-book group is split by semantic and evidence
  ownership rather than by equal candidate counts. Core language/tooling,
  intent/actor/transactions, control/data/composition/lowering,
  support-matrix/backlog, and blueprint/platform/reference form five disjoint
  path sets. This keeps examples beside their owning behavior while preventing
  the reference map from masking unrelated runtime claims.
- `2026-08-20`: Core-language claim evidence stays on the ordinary behavior
  path: parser rejection boundaries, generated widths, literal normalization,
  declarative state models, composition inference, factorization, hosted-test
  partitioning, target-language emission, and repeat lowering each retain their
  own producer and oracle. Syntax operands, boolean values, protocol versions,
  test bands, and linked test filenames remain reviewed non-claims. The LTE
  corpus count is reconstructed from active child entries independently of the
  expected diagnostic pattern.
- `2026-08-20`: Intent/actor/transaction review found two published contract
  errors and one report-ownership defect. Positive static repeat lowering is
  check-first, so its exact cost is `N × (body + 1) + 2`, not the former
  `N × body + 2`; drive-parameter payload width follows the driven target
  rather than always being one bit. Latency injection also created a
  `main_max_chk` state that the JSON report's name heuristic could not own.
  Lowering now stamps every state with its exact transaction owner, and the
  emitter fails closed if neither that field nor the legacy fallback can name
  an owner. Forty-two candidates use distinct scheduling/runtime evidence
  families; the literal value in `(set fire 1)` remains one reviewed example
  numeral rather than a capability claim.
- `2026-08-20`: Control/data/composition/lowering evidence remains partitioned
  by semantic producer: loop exits and indexing, temporal windows and anchors,
  control examples, expression widths and field sugar, shifts/banks/assembly,
  generated-child ingress/egress/actor routes, rule pulses and disjointness,
  lowering costs and implicit signals, and scalar/aggregate type packing each
  retain their own separating oracle. The seven numbered verification-example
  headings and the clamp threshold are instructional/example values, not
  measurements. Chapter 13h repeated both the stale repeat-cost formula and an
  ambiguous one-per-parameter signal note from the original cycle-reference
  expansion; it now states the check-first cost and separates one-bit request,
  per-formal signal count, and target-derived payload width without formatting
  those corrected claims out of the inventory.
- `2026-08-20`: The support-matrix and non-protocol backlog review separates
  current executable behavior from test filenames, cookbook ordinals, task
  identifiers, implementation-language version names, and illustrative data.
  ATL routes, FIFO widths, SourceHIR byte identities, VHDL generic maps, IAL2
  pulse/read/RLAST/ARLEN boundaries, and VIAL review/qualification/bridge/
  execution/parity counts each retain a distinct producer and negative
  control. The Chapter 14 claim that 80 complete book fixtures lowered cleanly
  was stale; the ordinary audit reports 82, so the published count is repaired
  rather than waived as reviewed context.
- `2026-08-20`: The blueprint/platform/reference review keeps the Rust parity
  smoke and current bounded AHB map on their ordinary executable producers,
  while archive, ledger, task-segment, evidence-map, ISF-partition, and roadmap
  recovery retain separate negative controls. Five reference-map sentences
  used present tense for immutable activation occupancy even though the live
  task index, review front door, book summary, focused-document collection,
  and roadmap had evolved. Their measurements remain exact but are now
  explicitly historical. Declared caps, old-guide section labels, and chapter
  coordinates remain reviewed inputs or navigation rather than current scale
  claims.
- `2026-08-20`: The 557-candidate protocol group is partitioned by committed
  path and semantic line range into 16 children: AXI manager/dynamic identity;
  five APB phases; six AHB phases; extended AXI; backends/APIs; and two shipped
  AXI chapters. Counts `65 + 11 + 35 + 46 + 37 + 28 + 40 + 49 + 27 + 35 +
  32 + 17 + 6 + 40 + 46 + 43` reproduce the whole group exactly. No child
  shares a current candidate identity, and `.5.4.1` alone is active.

## Open Questions

- None blocking. `.5.4.1` owns the first 65 AXI-manager-core and
  dynamic-identity candidates after the exact 16-child protocol partition.

## Blockers

- None.

## Acceptance Checklist (enforced for implementation changes)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'dispositions.jsonl' --oneline 979d5d416 -- doctrine scripts t docs/book/src KNOWLEDGE_MAP.md` returned no match: the complete inventory had no bounded join from a current candidate identity to a reviewed outcome and no enforced way for a completed migration group to reject residual open candidates.
- [x] **ADDRESSED (verified)** — `scripts/check_claim_verification_dispositions.pl --report` reported `candidates=1417`, `disposed=0`, `open=1417`, and exact group totals `268/232/557/72/288`; `prove -Iperl -v t/1638-claim-verification-dispositions.t` exercised all four outcome shapes and nine positive/RED subtests for stale, duplicate, unknown, missing, aliased, incomplete, fabricated-source, and closed-gap-owner cases.
- [x] **NO REGRESSION** — the focused disposition suite reported `All tests successful` and `Files=1, Tests=9`; claim inventory re-derived `628` governed constants without changing the `1,417` candidate frontier, Knowledge Map reported `1127` facts with query parity, live-document containment covered `3022/3022` paths, and the RAM-guarded mdBook plus all 12 registered doctrines pass.
- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'remain pinned to the adoption baseline' --oneline -- README_POLICY.md doctrine/live_document_size/surfaces.jsonl` identifies `9bd081935`, while pickaxes for the later 245-line / 9,931-byte registry values identify `3084d8c7b`: the policy sentence predated the downward ratchet and was never joined to the current control input; the unreviewed root candidates likewise had no disposition join.
- [x] **ADDRESSED (verified)** — the policy and Knowledge Map now distinguish historical adoption baseline, reviewed health target, and registry-derived current ceiling; regenerated inventory reports `candidates=1416`; the canonical disposition report joins all `32` current non-rationale root candidates as `15` derived gates plus `17` reviewed non-claims and leaves only the `39` separately owned rationale candidates open.
- [x] **NO REGRESSION** — the deliberately failing archive, ledger, task-tree, Knowledge Map width, RAM-trip, inventory, and disposition controls report `All tests successful` at `Files=8, Tests=88`; bootstrap, docs-relative paths, Memory, Knowledge Map parity, README/live-document/reference authority, mdBook test/build, and `git diff --check` pass; the ignored 19-MiB generated book directory was removed after verification.
- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S '4-GiB peak under optimized compilation' --oneline -- DEVELOPMENT_NOTES.md` identifies `adc88817e`, while the tracked probe/report search finds the exact `-O0` resource control but no producer for that peak measurement. The other foundational pickaxes identify immutable Chapter 14, roadmap, and provider-profile commits; their current candidate records likewise had no disposition join.
- [x] **ADDRESSED (verified)** — the unsupported UVM point estimate is removed without weakening the checked guarded-envelope rationale; regenerated inventory reports `candidates=1415`; the root join reports `40/70` disposed and `30` open. All eight remaining foundational candidates close as three derived gates and five historical measurements whose reasons name exact Git producers, independent preserved audits or executable oracles, and durability watchers. The OSVVM oracle now reconstructs the core/Common counts from both ordered lists and executed analysis commands.
- [x] **NO REGRESSION** — the RAM-guarded ledger, roadmap, UVM, OSVVM, inventory, and disposition collection reports `All tests successful` at `Files=6, Tests=30`; the exact OSVVM tuple reruns byte-identically and cleans its same-volume staging; inventory derives `668` governed constants after the eight new disposition records. Knowledge Map passes at 1,127 facts / 5,897 questions / 6,064 occurrences / 130 shards; live containment covers 3,022/3,022 paths with exact book authority; all 53 chapters test and the rendered 88-file/18,584-KiB book is inspected and removed. Docs, Memory, diff, staged acceptance, and doctrine gates pass.
- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'CLAIM-VERIFICATION-ADOPTION.5.2.3' --oneline -- docs/tasks/CLAIM-VERIFICATION-ADOPTION.md docs/TASK_TREE.md MEMORY.md` identifies partition commit `3b2b1b95c`; clean commit `27921556d` closes `.5.2.2`, so the dependency-ordered bridge/execution review is the next inactive PNT frontier.
- [x] **ADDRESSED (verified)** — ownership surfaces alone activate `.5.2.3` for the exact 18 current candidates on `DEVELOPMENT_NOTES.md` lines 188..269. `.5.2.4` remains pending, and no disposition, claim, evidence producer, runtime behavior, capability, or support statement changes in this selection slice.
- [x] **NO REGRESSION** — task integrity, Memory, inventory/disposition joins, docs-relative paths, Knowledge Map, live-document authority, diff, staged acceptance, and all 12 doctrine gates pass from the clean closure predecessor.
- [x] **ROOT CAUSE (WHY + WHERE)** — the 18 bridge/execution candidates had no disposition joins, and the final-count checks in `t/1602-vial-architecture-scale-bridge-fanout.t` did not independently reconstruct the rationale's calibration premises. The failing tool output reported at t/1602-vial-architecture-scale-bridge-fanout.t line 193 and located a prefix-based probe that went RED at 26 versus 56 configuration maps and 251 versus 221 baseline maps because configuration semantics legitimately contribute maps outside `/configurations/`; copied path-family arithmetic was therefore not a separating proof.
- [x] **ADDRESSED (verified)** — the bridge oracle now builds baseline, one-configuration, one-residue, and selected-gate workloads through the ordinary direct-IAL1 route and differentially proves the calibration. Fourteen candidate identities join distinct bridge, fiber, semantic-limit, or bound-type producer/oracle/watcher chains; four rejected or pre-repair observations carry exact reviewed reasons. The canonical report is `candidates=1415`, `disposed=58`, `gates=32`, `reviewed=26`, `root open=12`.
- [x] **NO REGRESSION** — the RAM-guarded exact collection for `t/1550`, `t/1602`, `t/1604`, `t/1605`, and `t/1606` reports `All tests successful` at `Files=5, Tests=34`; inventory regenerates 1,415 candidates and 686 governed constants; disposition RED controls, docs, Memory, Knowledge Map, live containment, all 53 book chapters and rendered-book inspection/removal, staged acceptance, diff, and all 12 doctrine gates pass.
- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -1 --format='%H %s'` identifies clean implementation commit `7cc733514`; the canonical inventory retains exactly 12 undispositioned DEVELOPMENT_NOTES.md candidates on lines 306..411, so the final dependency-ordered root child is ready but inactive. Its acceptance text still carried the pre-repair 71-candidate root count even though `.5.2.2` removed one unsupported candidate and fixed the current root at 70.
- [x] **ADDRESSED (verified)** — task/index/Memory ownership surfaces activate `.5.2.4` for the exact checking-scale range and its acceptance count now agrees with the current canonical root total. `.5.2.3` remains done, and no disposition, claim, evidence producer, product behavior, capability, or support statement changes in this selection slice.
- [x] **NO REGRESSION** — task integrity, Memory, inventory/disposition joins, docs-relative paths, Knowledge Map, live-document authority, diff, staged acceptance exemption, and all 12 doctrine gates pass from clean predecessor `7cc733514`.
- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'Model-state source factorization must preserve the expanded oracle count' --oneline -- DEVELOPMENT_NOTES.md` identifies `48e97f656` and the scoreboard pickaxe identifies `416c79473`, while the canonical disposition join left all 12 checking-scale rationale candidates open. The existing model regression checked aggregate cells but did not independently count the authored definition, instance, and declaration factorization that makes those totals meaningful.
- [x] **ADDRESSED (verified)** — twelve candidate identities now join six distinct generated producer/oracle/watcher families. The model oracle counts shared definitions, instances, and declarations at gate, qualification, limit, and adjacent excess before exercising every cell; the exact guarded collection reports `All tests successful` at `Files=6, Tests=30`. The canonical report is `candidates=1415`, `disposed=70`, `gates=44`, `reviewed=26`, `root open=0`, with `root_documents required_complete=1`.
- [x] **NO REGRESSION** — inventory regenerates `1,415` candidates and `698` governed constants; inventory/disposition RED suites report `All tests successful` at `Files=2, Tests=14`; Knowledge Map reports `1,127` facts / `5,901` questions / `6,068` occurrences / `130` shards; live containment covers `3,022/3,022` paths with exact book authority. All 53 chapters test, the rendered 88-file/18,588-KiB book contains the synchronized checking evidence and is removed, while docs, Memory, diff, staged acceptance, and all 12 doctrine gates pass.
- [x] **ROOT CAUSE (WHY + WHERE)** — clean commit `3dcd9c2f1` closes `.5.2.4`, leaving the existing 268-candidate `.5.3` leaf as the next dependency-ordered frontier; one unsliced review would mix thirty chapter paths across unrelated grammar, runtime, support-accounting, backlog, and historical/reference evidence families.
- [x] **ADDRESSED (verified)** — the committed inventory is aggregated into five disjoint path-owned children: `.5.3.1=35/10 paths`, `.5.3.2=43/3`, `.5.3.3=68/6`, `.5.3.4=71/8`, and `.5.3.5=51/3`; their exact sum is `268` over all `30` general-book paths. `.5.3.1` alone is active, and no claim or disposition changes in this continuity slice.
- [x] **NO REGRESSION** — task integrity, Memory, inventory/disposition joins, docs-relative paths, Knowledge Map, live-document authority, diff, staged acceptance exemption, and all 12 doctrine gates pass from clean predecessor `3dcd9c2f1`.
- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S '36 flat RTL module references' --oneline -- docs/book/src/10-errors-strict-mode-and-troubleshooting.md` identifies `24ca8d74a`, while the committed inventory left all 35 candidates on the ten selected Chapters 02-12 paths without disposition joins. Most prose already described executable parser, lowering, emission, or CI-partition behavior, but the LTE expected-failure catalog repeated its `36` count without independently reconstructing that number from the offending source child.
- [x] **ADDRESSED (verified)** — all 35 identities now close as 26 three-leg derived gates and nine reviewed syntax/example/identifier outcomes. `t/248-regression-corpus-accounting.t` separately extracts `lte_dif_iosocket` and counts six declarations plus 30 active mappings before accepting the catalog diagnostic. The RAM-guarded exact evidence run reports `All tests successful` at `Files=22, Tests=7487`.
- [x] **NO REGRESSION** — the final RAM-guarded evidence rerun reports `All tests successful` at `Files=22, Tests=7487`. Inventory regenerates `1,415` candidates and `733` governed constants; the disposition join reports `105` closed overall, `35/268` in the general book, `70` gates, and `35` reviewed outcomes. Knowledge Map generation/check reports `1,127` facts / `5,902` questions / `6,069` occurrences / `130` shards; live containment covers `3,022/3,022` paths with exact `51,049`-line / `2,696,556`-byte book authority. All 53 chapters test, the rendered 88-file/18,592-KiB book contains the synchronized reference and is removed; the host-provided mdBook toolchain is the only read-only off-volume dependency. Docs, Memory, diff, staged acceptance, and all 12 doctrine gates pass.
- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'N × (body_cycles) + 2' --oneline -- docs/book/src/13b-transactions.md` identifies `423857034`, and the one-bit parameter-table pickaxe identifies `e2e5e7acf`: both prose claims predated an exact join to current lowering. The new focused oracle then exposed `Use of uninitialized value $tx_name ... Emitter/JSON.pm line 422`, because injected `main_max_chk` did not match the report's transaction-name heuristic.
- [x] **ADDRESSED (verified)** — all 43 selected identities close as 42 distinct three-leg derived gates plus one reviewed example numeral. The book now states the check-first positive-repeat cost `N × (body + 1) + 2` and target-derived drive payload widths; `t/1639-isf-published-timing-claims.t` proves the exact 26-cycle two-drive/eight-repeat graph, rejects 18, distinguishes one-bit requests from one- and eight-bit payloads, exercises the published timing families, and requires exact `main` ownership for the injected latency state. Lowering stamps transaction ownership on every state, and JSON emission uses that field first and otherwise fails closed.
- [x] **NO REGRESSION** — the RAM-guarded exact intent/actor/transaction collection reports `All tests successful` at `Files=36, Tests=602` over parser boundaries, state ordering, entry/drive/sample/await/complete behavior, repeat/control/data/loop timing, FIFO/APB composition, schedule reporting, and both claim registries. Inventory regenerates `1,415` candidates / `776` governed constants; the disposition join reports `148` closed overall and `78/268` in the general book. Knowledge Map reports `1,127` facts / `5,905` questions / `6,072` occurrences / `130` shards; live containment covers `3,022/3,022` paths with exact `51,059`-line / `2,697,391`-byte book authority. All 53 chapters test; the rendered 88-file/18,600-KiB book contains the corrected tables and reference, is inspected, and is removed. Docs, Memory, diff, staged acceptance, and all 12 registered doctrines pass; the host-provided mdBook toolchain remains the only read-only off-volume dependency.
- [x] **ROOT CAUSE (WHY + WHERE)** — both `git log -S 'body_cycles' --oneline -- docs/book/src/13h-lowering-reference.md` and the exact `{name}_{param}` implicit-signal pickaxe identify `423857034`: the cycle-reference expansion duplicated the stale repeat formula and left “1 per parameter” ambiguous between signal cardinality and payload width. All 68 current path-owned candidates also lacked disposition joins before this review.
- [x] **ADDRESSED (verified)** — all 68 current identities close as 60 distinct three-leg derived gates plus seven instructional heading ordinals and one clamp-example threshold. Chapter 13h now states the exact check-first positive-repeat structure and separately declares one-bit request width, one payload signal per formal, and target-derived payload width. The inventory stays at 68 selected candidates after the rewrite, proving the corrected claims were not hidden by line formatting.
- [x] **NO REGRESSION** — the RAM-guarded exact control/data/composition/lowering collection reports `All tests successful` at `Files=54, Tests=603`; it exercises loop edges/indexing, temporal bounds/anchors, control truthiness, width-clean data operations, storage/packing, exhaustive generated-child route reports/tops/HDL/RED cases, rule conflicts, lowering timing/signals, type packing, and both claim registries. The book audit reports 82 complete fixtures lowering cleanly and 270 non-actor fragments skipped. Inventory regenerates `1,415` candidates / `844` governed constants; disposition reports `216` closed overall and `146/268` in the general book. Knowledge Map reports `1,127` facts / `5,908` questions / `6,075` occurrences / `130` shards; live containment covers `3,022/3,022` paths with exact `51,071`-line / `2,698,124`-byte book authority. All 53 chapters test; the rendered 88-file/18,600-KiB book contains the corrected reference and is inspected and removed. Docs, Memory, diff, staged acceptance, and all 12 registered doctrines pass; the host-provided mdBook toolchain remains the only read-only off-volume dependency.
- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'Current state: 80' --oneline -- docs/book/src/14-feature-backlog.md` identifies `a25264fa3`: the hand-copied complete-example total was not updated when later runnable fixtures entered the ordinary audit. All 71 current candidates on the eight support-matrix/backlog paths also lacked disposition joins.
- [x] **ADDRESSED (verified)** — all 71 identities close as 62 distinct three-leg derived gates plus nine reviewed test/recipe/task/language/example identifiers. Chapter 14 now copies the executable audit's 82 complete fixtures; SourceHIR byte identities, VHDL generic-map shapes, ATL/FIFO behavior, IAL2 pulse/read/RLAST/ARLEN boundaries, and VIAL profile/bridge/execution/parity measurements retain separate producer/oracle/watcher chains.
- [x] **NO REGRESSION** — the RAM-guarded family collection reports `All tests successful` at `Files=30, Tests=590`, including the 82-complete/270-fragment book census, and the filtered dynamic-read/RLAST/raw-ARLEN collection reports `Files=1, Tests=6`. Inventory regenerates `1,415` candidates / `915` governed constants; disposition reports `287` closed overall and `217/268` in the general book. Knowledge Map reports `1,127` facts / `5,911` questions / `6,078` occurrences / `130` shards; live containment covers `3,022/3,022` paths with exact `51,078`-line / `2,698,576`-byte book authority. All 53 chapters test; the rendered 88-file/18,600-KiB book contains the repaired total and synchronized reference, is inspected, and is removed. Docs, Memory, diff, staged acceptance, and all 12 registered doctrines pass; the host-provided mdBook toolchain remains the only read-only off-volume dependency.
- [x] **ROOT CAUSE (WHY + WHERE)** — exact `git log -S` pickaxes for `cross-tree index keeps only three active`, `The 79-line review`, `The mandatory read is 51 lines`, `generated index classifies all 1,005`, and `317-line live view` identify commits `7f05b41de`, `2bfb32c02`, `dc1c64afb`, `ea1b76dd5`, and `a20d38afc`. Those immutable activation measurements remained accurate but used present tense after their live surfaces evolved, and all 51 current candidates on Chapters 15, 16, and 90 still lacked disposition joins.
- [x] **ADDRESSED (verified)** — all 51 identities close as 14 three-leg derived gates plus 37 reviewed policy, historical, structural, and navigation outcomes. The Rust smoke, current bounded AHB map, retired-history retrieval, rationale ledger, task segment/archive, evidence maps, ISF partition, and roadmap archive retain distinct evidence chains. Activation-only task-index, review-front, mdBook-summary, focused-collection, and roadmap occupancy is now explicitly past-tense without changing the exact 51-candidate census. The general-book registry is required-complete at `268/268` with zero open identities.
- [x] **NO REGRESSION** — the RAM-guarded exact blueprint/platform/reference collection reports `All tests successful` at `Files=14, Tests=121`; it exercises Rust/Perl parity, AHB source and generalized-count truth, task reconstruction, README/live-document pressure, maintained-reference authority, retired histories, rationale reconstruction, roadmap recovery, focused-document/ISF partitions, and both claim registries. Inventory regenerates `1,415` candidates / `966` governed constants; disposition reports `338` closed overall as `248` gates / `90` reviewed and closes `general_book=268/268 required_complete=1`. Knowledge Map reports `1,127` facts / `5,914` questions / `6,081` occurrences / `130` shards; live containment covers `3,022/3,022` paths with exact `51,089`-line / `2,699,163`-byte book authority. All 53 chapters test; the rendered 88-file/18,604-KiB book contains the clarified activation context and synchronized review note, is inspected, and is removed. Docs, Memory, diff, staged acceptance, and all 12 registered doctrines pass; the host-provided mdBook toolchain remains the only read-only off-volume dependency.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-08-20` | `.1` | `scripts/check_task_tree_integrity.pl`; `scripts/check_docs_relative_paths.sh`; `git diff --check` | `PASS — 4 active trees / 954 nodes; 1 docs-relative-path file / 2 tests; clean diff whitespace` |
| `2026-08-20` | `.2` | neutral-body digest; bootstrap; README/live-document/reference authority; docs paths; RAM-guarded mdBook; doctrine gate | `PASS — authoritative body identity reproduced; discovery and bounded routes closed; book built` |
| `2026-08-20` | `.3` | claim checker; `t/1636`; bootstrap; Knowledge Map; live-document/reference authority; RAM-guarded mdBook; doctrine gate | `PASS — one bounded conformance record; Files=1, Tests=8; deliberate missing/alias/path RED controls; all registered doctrines` |
| `2026-08-20` | `.4` | claim inventory/report; `t/1637`; bootstrap; claim checker; live-document/reference authority; RAM-guarded mdBook; doctrine gate | `PASS — independent parity across 10,666 numeric lines; 1,417 owned candidates and 615 governed constants; Files=1, Tests=5; bounded canonical inventory` |
| `2026-08-20` | `.5` partition | committed-inventory path/classification aggregation; exact five-group sum; task integrity; docs paths; doctrine gate | `PASS — 72 + 268 + 557 + 232 + 288 = 1,417 with disjoint path ownership; .5.1 selected alone` |
| `2026-08-20` | `.5.1` | disposition checker/report; `t/1638`; inventory/constant census; bootstrap; Knowledge Map; live-document/reference authority; RAM-guarded mdBook; doctrine gate | `PASS — five exact groups, four bounded outcomes, all 1,417 debt records visibly open; Files=1, Tests=9; 628 governed constants; all registered doctrines` |
| `2026-08-20` | `.5.2` partition | committed inventory path/line aggregation; exact four-group sum; task integrity; docs paths; doctrine gate | `PASS — 33 + 9 + 18 + 12 = 72 with disjoint path/range ownership; .5.2.1 selected alone` |
| `2026-08-20` | `.5.2.1` | stale-policy root cause; inventory/disposition joins; `t/1549`, `t/1554`, `t/1565`, `t/1566`, `t/1567`, `t/1595`, `t/1637`, `t/1638`; bootstrap; docs paths; Memory; Knowledge Map; README/live-document/reference authority; RAM-guarded mdBook; diff check | `PASS — current frontier 1,416; root 32 disposed / 39 open; 15 gates / 17 reviewed; 660 governed constants; Files=8/Tests=88; 53 book chapters tested and built` |
| `2026-08-20` | `.5.2.2` | UVM producer audit and live repair; ledger/book/roadmap/provider evidence review; OSVVM source-order reconstruction; `t/1565`, `t/1566`, `t/1592`, `t/1599`, `t/1637`, `t/1638`; inventory/disposition joins; docs/Memory/Knowledge Map/live-document/mdBook/diff/staged-doctrine gates | `PASS — current frontier 1,415; root 40 disposed / 30 open; 18 gates / 22 reviewed; all eight foundational candidates closed; 668 governed constants; Files=6/Tests=30; Knowledge Map 1,127/5,897/6,064/130; live paths 3,022/3,022; all 53 chapters; inspected/removed build 88 files/18,584 KiB; exact provider rerun and same-volume cleanup pass` |
| `2026-08-20` | `.5.2.3` activation | clean `27921556d` predecessor; exact 18-candidate line-range census; task/index/Memory continuity; task/inventory/disposition/docs/Knowledge Map/live-document/diff/staged-doctrine gates | `PASS — .5.2.3 alone active; .5.2.4 pending; no claim, disposition, evidence, product, capability, or support behavior changes` |
| `2026-08-20` | `.5.2.3` | bridge differential calibration; exact bridge boundary; semantic parallel limit; scenario topology; total/live fibers; bound execution types; inventory/disposition joins; docs/Memory/Knowledge Map/live-document/mdBook/diff/staged-doctrine gates | `PASS — all 18 candidates closed as 14 gates / 4 reviewed; root 58 disposed / 12 open; Files=5/Tests=34 exact focused run; 686 governed constants; all 53 chapters and all registered doctrines` |
| `2026-08-20` | `.5.2.4` activation | clean `7cc733514` predecessor; exact 12-candidate line-range census; task/index/Memory continuity; task/inventory/disposition/docs/Knowledge Map/live-document/diff/staged-doctrine gates | `PASS — .5.2.4 alone active; no claim, disposition, evidence, product, capability, or support behavior changes` |
| `2026-08-20` | `.5.2.4` | owned-shape partition; model source factorization and exact cells; scoreboard storage/order; coverage identity/order; fault lifecycle; random semantic/bridge/plan stages; inventory/disposition joins; docs/Memory/Knowledge Map/live-document/mdBook/diff/staged-doctrine gates | `PASS — all 12 candidates closed as derived gates; root 70/70 required-complete with 44 gates / 26 reviewed; Files=6/Tests=30 exact focused run; 698 governed constants; all 53 chapters and all registered doctrines` |
| `2026-08-20` | `.5.3` partition | committed-inventory path aggregation; exact five-child sum; task integrity; docs paths; inventory/disposition/Knowledge Map/live-document/diff/staged-doctrine gates | `PASS — 35 + 43 + 68 + 71 + 51 = 268 across 30 disjoint paths; .5.3.1 selected alone; no claim, disposition, product, capability, or support behavior changes` |
| `2026-08-20` | `.5.3.1` | parser/width/literal/type/composition/factorization/CI/VHDL/ISF/APB evidence; independent LTE source count; inventory/disposition/Knowledge Map/live-document/mdBook/diff/staged-doctrine gates | `PASS — all 35 candidates closed as 26 gates / 9 reviewed; general book 35/268; Files=22/Tests=7,487 exact focused run; all 53 chapters and all registered doctrines` |
| `2026-08-20` | `.5.3.2` | static wait; entry/drive/sample/await/complete; repeat/control/data/loop timing; FIFO/APB composition; exact schedule ownership; inventory/disposition/Knowledge Map/live-document/mdBook/diff/staged-doctrine gates | `PASS — all 43 candidates closed as 42 gates / 1 reviewed; general book 78/268; Files=36/Tests=602 exact focused run; all 53 chapters and all registered doctrines` |
| `2026-08-20` | `.5.3.3` | loop/temporal/control/data/storage/composition/rule/lowering/type evidence; exhaustive ATL routes; inventory/disposition/Knowledge Map/live-document/mdBook/diff/staged-doctrine gates | `PASS — all 68 candidates closed as 60 gates / 8 reviewed; general book 146/268; Files=54/Tests=603 exact focused run; 82 complete book fixtures and all registered doctrines` |
| `2026-08-20` | `.5.3.4` | support matrix; book audit; SourceHIR; VHDL generic maps; ATL/FIFO; IAL2 pulse/read/RLAST/ARLEN; VIAL profile/bridge/execution/parity; inventory/disposition/Knowledge Map/live-document/mdBook/diff/staged-doctrine gates | `PASS — all 71 candidates closed as 62 gates / 9 reviewed; general book 217/268; Files=30/Tests=590 plus filtered AXI Files=1/Tests=6; all registered doctrines` |
| `2026-08-20` | `.5.3.5` | Rust parity smoke; current AHB map; retired histories; ledger; task migration/archive; evidence maps; ISF/reference partitions; roadmap recovery; inventory/disposition/Knowledge Map/live-document/mdBook/diff/staged-doctrine gates | `PASS — all 51 candidates closed as 14 gates / 37 reviewed; general book 268/268 required-complete; Files=14/Tests=121 exact focused run; all registered doctrines` |
| `2026-08-20` | `.5.4` partition | committed-inventory path/range aggregation; exact 16-child sum; task integrity; docs paths; inventory/disposition/Knowledge Map/live-document/diff/staged-doctrine gates | `PASS — 65 + 11 + 35 + 46 + 37 + 28 + 40 + 49 + 27 + 35 + 32 + 17 + 6 + 40 + 46 + 43 = 557; .5.4.1 selected alone; no claim, disposition, product, capability, or support behavior changes` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `CLAIM-VERIFICATION-ADOPTION.1: select three-leg claim evidence` | `Decision and executable adoption sequence only; no policy or product behavior change.` |
| `.2` | `CLAIM-VERIFICATION-ADOPTION.2: install the authoritative claim standard` | `Project-owned standard plus bounded discovery and book reference; no product behavior change.` |
| `.3` | `CLAIM-VERIFICATION-ADOPTION.3: gate bounded three-leg claim records` | `Bounded registry, exact record checker, positive/RED fixtures, doctrine registration, and durable retrieval card.` |
| `.4` | `CLAIM-VERIFICATION-ADOPTION.4: inventory current claims and constants` | `Producer-derived current-surface census, conservative partitions, governed constants, exact migration ownership, and independent RED controls.` |
| `.5` | `CLAIM-VERIFICATION-ADOPTION.5: partition claim migration frontier` | `Activates seven bounded children from the committed five-group candidate census; changes no claim, checker, product, or support behavior.` |
| `.5.1` | `CLAIM-VERIFICATION-ADOPTION.5.1: gate candidate review dispositions` | `Bounded outcome/group registries, exact inventory join, live owner and path checks, completion enforcement, RED controls, and durable retrieval route.` |
| `.5.2` | `CLAIM-VERIFICATION-ADOPTION.5.2: partition root claim review` | `Activates four evidence-coherent children from the exact root candidate census; changes no claim, disposition, policy, product, or support behavior.` |
| `.5.2.1` | `CLAIM-VERIFICATION-ADOPTION.5.2.1: disposition non-rationale root claims` | `Repairs stale README ceiling semantics and maps every current non-rationale root candidate to a live derived gate or an exact reviewed non-claim outcome.` |
| `.5.2.2` | `CLAIM-VERIFICATION-ADOPTION.5.2.2: disposition foundational rationale claims` | `Removes unsupported UVM resource precision, strengthens the OSVVM source-count oracle, and maps the remaining foundational claims to live gates or immutable historical measurements.` |
| `.5.2.3` activation | `CLAIM-VERIFICATION-ADOPTION.5.2.3: activate bridge execution claim review` | `Activates the exact bridge/execution rationale range from the clean foundational closure without changing claims or evidence.` |
| `.5.2.3` | `CLAIM-VERIFICATION-ADOPTION.5.2.3: disposition bridge execution claims` | `Maps bridge and execution measurements to distinct current evidence chains, preserves historical/structural references honestly, and strengthens source-map calibration with differential real builds.` |
| `.5.2.4` activation | `CLAIM-VERIFICATION-ADOPTION.5.2.4: activate checking scale claim review` | `Activates the exact final checking-scale root range from the clean bridge/execution closure without changing claims or evidence.` |
| `.5.2.4` | `CLAIM-VERIFICATION-ADOPTION.5.2.4: disposition checking scale claims` | `Maps all checking-scale measurements to independent generated evidence chains, strengthens model source-factorization checks, and makes the complete root group mandatory.` |
| `.5.3` | `CLAIM-VERIFICATION-ADOPTION.5.3: partition general book claim review` | `Activates five semantic/evidence-coherent children from the exact 268-candidate general-book census; changes no claim, disposition, product, capability, or support behavior.` |
| `.5.3.1` | `CLAIM-VERIFICATION-ADOPTION.5.3.1: disposition core language claims` | `Maps core grammar, inference, composition, tooling, extension, and lowering statements to ordinary evidence chains; preserves syntax and navigation numerals as non-claims; independently reconstructs the LTE diagnostic count.` |
| `.5.3.2` | `CLAIM-VERIFICATION-ADOPTION.5.3.2: disposition intent timing claims` | `Maps intent, actor, and transaction statements to exact evidence families; repairs repeat timing and drive-payload prose; gives injected states explicit transaction ownership in schedule reports.` |
| `.5.3.3` | `CLAIM-VERIFICATION-ADOPTION.5.3.3: disposition control data claims` | `Maps control, temporal, data, generated-child composition, rule, lowering, and type statements to distinct executable evidence; repairs duplicated repeat and payload-width prose.` |
| `.5.3.4` | `CLAIM-VERIFICATION-ADOPTION.5.3.4: disposition support backlog claims` | `Maps shipped support-matrix and non-protocol backlog statements to distinct executable evidence, preserves identifiers/examples as reviewed context, and repairs the stale complete-book fixture count.` |
| `.5.3.5` | `CLAIM-VERIFICATION-ADOPTION.5.3.5: disposition blueprint reference claims` | `Maps current Rust, AHB, archive, ledger, task, evidence-map, ISF-partition, and roadmap claims to distinct gates; preserves policy/navigation/history context and clarifies activation-only occupancy.` |
| `.5.4` | `CLAIM-VERIFICATION-ADOPTION.5.4: partition protocol claim review` | `Activates 16 bounded path/range- and evidence-coherent children from the exact 557-candidate protocol census; changes no claim, disposition, product, capability, or support behavior.` |
