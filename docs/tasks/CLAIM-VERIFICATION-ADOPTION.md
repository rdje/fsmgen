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
  Status: `done`
  Goal: `Review and migrate the 557 protocol-profile and integration-book candidates.`
  Acceptance: `Every candidate in 14f, 14g, 14h, 14i, 14j, 14l, 16a, 16aa, and 16b is dispositioned against executable protocol/profile/integration producers and separating oracles, or carries an exact owned gap; repeated measurements share evidence only when they are demonstrably the same claim.`
  Verification: `PASS — all 16 evidence-coherent children close the exact 557-candidate protocol group as 247 derived gates plus 310 reviewed outcomes; protocol is required-complete at 557/557 with zero open candidates.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.4: partition protocol claim review`
  Children: `CLAIM-VERIFICATION-ADOPTION.5.4.1, CLAIM-VERIFICATION-ADOPTION.5.4.2, CLAIM-VERIFICATION-ADOPTION.5.4.3, CLAIM-VERIFICATION-ADOPTION.5.4.4, CLAIM-VERIFICATION-ADOPTION.5.4.5, CLAIM-VERIFICATION-ADOPTION.5.4.6, CLAIM-VERIFICATION-ADOPTION.5.4.7, CLAIM-VERIFICATION-ADOPTION.5.4.8, CLAIM-VERIFICATION-ADOPTION.5.4.9, CLAIM-VERIFICATION-ADOPTION.5.4.10, CLAIM-VERIFICATION-ADOPTION.5.4.11, CLAIM-VERIFICATION-ADOPTION.5.4.12, CLAIM-VERIFICATION-ADOPTION.5.4.13, CLAIM-VERIFICATION-ADOPTION.5.4.14, CLAIM-VERIFICATION-ADOPTION.5.4.15, CLAIM-VERIFICATION-ADOPTION.5.4.16`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.1`
  Status: `done`
  Goal: `Disposition the 65 AXI-manager-core and dynamic-identity backlog candidates in Chapters 14f and 14g.`
  Acceptance: `Current generated AXI manager capacity, identity, demux, ordering, and output-bank statements join distinct executable evidence; selectors, historical checkpoints, and deferred-boundary numerals remain distinguishable from shipped behavior.`
  Verification: `PASS — all 65 candidates close as 28 derived gates plus 37 reviewed selector, readiness, helper-probe, and resource-history outcomes; the RAM-guarded exact manager/dynamic-ID collection reports Files=2/Tests=121; inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.4.1: disposition AXI manager claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.2`
  Status: `done`
  Goal: `Disposition the 11 foundational profile/APB candidates in Chapter 14h lines 1-850 and Chapter 16b.`
  Acceptance: `Profile-alias chronology, APB endpoint/completer/interconnect foundations, and the shipped APB example chapter retain current evidence without promoting task identifiers or mode-map navigation into capability proof.`
  Verification: `PASS — all 11 candidates close as six derived gates plus five reviewed contract-selection outcomes; the RAM-guarded exact APB completer/composition collection reports Files=2/Tests=133; inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.4.2: disposition foundational APB claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.3`
  Status: `done`
  Goal: `Disposition the 35 APB width, sideband, status, and timing candidates in Chapter 14h lines 851-1199.`
  Acceptance: `Data/strobe widths, protection/status fields, queue depth, and selected timing families join the exact APB generators and separating boundary cases.`
  Verification: `PASS — all 35 candidates close as 13 derived gates plus 22 reviewed readiness, selector, contract, and historical-guard outcomes; the RAM-guarded exact APB alias/completer/composition collection reports Files=3/Tests=147; inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.4.3: disposition APB width timing claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.4`
  Status: `done`
  Goal: `Disposition the 46 APB multi-register, protection, and composition candidates in Chapter 14h lines 1200-1699.`
  Acceptance: `Selected 16/32-bit multi-register, protected, queued, fixed-composition, and multi-peripheral measurements retain separate source-shape and runtime evidence.`
  Verification: `PASS — all 46 candidates close as 17 derived gates plus 29 reviewed readiness, selector, contract, and chronology outcomes; nine APB source families retain separate runtime and negative-boundary evidence; the RAM-guarded exact APB alias/completer/composition collection reports Files=3/Tests=147; inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.4.4: disposition APB composition claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.5`
  Status: `done`
  Goal: `Disposition the 37 generalized APB register-set candidates in Chapter 14h lines 1700-1999.`
  Acceptance: `Generalized two-peripheral register-set widths, strides, windows, counts, and protection policies join exact generated artifacts and adjacent-boundary controls.`
  Verification: `PASS — all 37 candidates close as 14 derived gates plus 23 reviewed heading, readiness, selector, contract, and historical-guard outcomes; six generalized APB source families retain separate width/stride/window/count/policy and adjacent-boundary evidence; the RAM-guarded exact APB alias/composition collection reports Files=2/Tests=115; inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.4.5: disposition generalized APB claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.6`
  Status: `done`
  Goal: `Disposition the 28 expanded APB register-bound candidates in Chapter 14h lines 2000-end.`
  Acceptance: `Five- and six-register 16/32-bit protected and unprotected families keep explicit count/stride/width producers and fail-closed neighboring bounds.`
  Verification: `PASS — all 28 candidates close as nine derived gates plus 19 reviewed heading, readiness, selector, contract, and historical-guard outcomes; five expanded APB source families retain separate count/stride/width/policy/artifact and excess-six/seven evidence while protected six-register shapes remain closed; the RAM-guarded exact APB alias/composition collection reports Files=2/Tests=115; inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.4.6: disposition expanded APB bounds`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.7`
  Status: `done`
  Goal: `Disposition the 40 foundational AHB endpoint, interconnect, HBURST, and BUSY candidates in Chapter 14i lines 1-1070.`
  Acceptance: `Endpoint and aggregate topologies, byte-lane/SEQ/BUSY policies, profile aliases, support counts, and runtime behavior retain distinct producer/oracle chains.`
  Verification: `PASS — all 40 candidates close as seven derived gates plus 33 reviewed contract, time-local support, and test/decision-identifier outcomes; five current evidence families retain separate one-window decode, aggregate byte-lane alias topology, one-word HBURST, and generic/alias BUSY-park producer/oracle chains; the RAM-guarded exact AHB collection reports Files=13/Tests=57 and support/manifest accounting reports Files=2/Tests=7098; inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.4.7: disposition foundational AHB claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.8`
  Status: `done`
  Goal: `Disposition the 49 AHB semantic-repair and exact-two/three requester-BUSY candidates in Chapter 14i lines 1071-1406.`
  Acceptance: `Wrap progression, data-phase ownership, error timing, conditional BUSY insertion, exact count runtime, aliases, and integration surfaces join independent semantics and generated-HDL evidence.`
  Verification: `PASS — all 49 candidates close as eight derived gates plus 41 reviewed audit, contract, identifier, historical-support, and superseded-bound outcomes; six current families retain separate WRAP, direct/paired exact-one, exact-two, exact-three, and exact-three-alias evidence while the phase-pipeline/direct-seed repairs remain in the exact no-regression collection; the RAM-guarded exact AHB collection reports Files=17/Tests=67 and support/manifest accounting reports Files=2/Tests=7098; inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.4.8: disposition AHB semantic BUSY claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.9`
  Status: `done`
  Goal: `Disposition the 27 AHB arbitration and exact-three paired-composition candidates in Chapter 14i lines 1407-1661.`
  Acceptance: `Default-decode arbitration repair and one-/two-subordinate exact-three paired compositions retain exact topology, artifact, support, and assertion-enabled runtime evidence.`
  Verification: `PASS — all 27 candidates close as two derived gates plus 25 reviewed audit, contract, identifier, projected-support, and shipment-checkpoint outcomes; one-window exact-three artifact/strict/semantic/MCP behavior and two-window assertion-enabled runtime retain separate executable evidence while the arbitration repairs remain in the exact no-regression collection; the RAM-guarded exact AHB collection reports Files=15/Tests=54 and support/manifest accounting reports Files=2/Tests=7098; inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.4.9: disposition AHB arbitration claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.10`
  Status: `done`
  Goal: `Disposition the 35 exact-four requester and paired-composition candidates in Chapter 14i lines 1662-1779.`
  Acceptance: `Minimum counter widths, literal bounds, exact-four requester runtime, paired aggregate behavior, aliases, and support checkpoints join distinct generated evidence.`
  Verification: `PASS — all 35 candidates close as five derived gates plus 30 reviewed probe, readiness, contract, projection, checkpoint, and removed-workspace outcomes; exact-four requester width/runtime, one-window paired artifact/runtime, and paired profile-alias parity retain distinct executable evidence while the historical 2..4 bound remains separate from current generalized 2..16; the RAM-guarded exact AHB collection reports Files=4/Tests=17 and support/manifest accounting reports Files=2/Tests=7098; inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.4.10: disposition AHB exact-four claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.11`
  Status: `done`
  Goal: `Disposition the 32 two-subordinate exact-four and generalized BUSY-range candidates in Chapter 14i lines 1780-1895.`
  Acceptance: `Two-window exact-four runtime, aliases, generated artifact counts, support identity, and generalized literal 2..16 behavior retain separate runtime and fail-closed evidence.`
  Verification: `PASS — all 32 candidates close as nine derived gates plus 23 reviewed readiness, contract, projection, superseded-activation, shipment, and selector-checkpoint outcomes; two-window exact-four topology/runtime, its profile alias, live 332/373/56 split-28/28 support accounting, and generalized 2..16 range/runtime/no-fixture behavior retain separate executable evidence; the RAM-guarded exact AHB collection reports Files=3/Tests=12 and support/manifest accounting reports Files=2/Tests=7098; inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.4.11: disposition generalized AHB BUSY claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.12`
  Status: `done`
  Goal: `Disposition the 17 AHB integration and public-synchronization candidates in Chapter 14i lines 1896-end.`
  Acceptance: `Post-AHB integration selections, ISF/book synchronization measurements, diagram migrations, task-ledger repairs, and Chapter 16c handoffs remain correctly classified as current gates or immutable history.`
  Verification: `PASS — all 17 candidates close as one derived gate plus 16 reviewed selector/task identifiers, synchronization-time measurements, diagram locations, and task-ledger checkpoints; the live Chapter 16c exact-one-through-four catalog versus generic 5..16 boundary retains lowerer, runtime, fail-closed, and support-accounting evidence while 332-index, 295-file/2,037-test, 36-chapter, and 842/840-to-844/844 values remain exact Git chronology; the RAM-guarded current AHB collection reports Files=2/Tests=9 and support/manifest accounting reports Files=2/Tests=7098; inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.4.12: disposition AHB integration claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.13`
  Status: `done`
  Goal: `Disposition the 6 extended-AXI backlog candidates in Chapter 14j.`
  Acceptance: `Mixed dynamic/static demux claims join exact generated behavior while selectors and bounded contract numerals remain narrowly classified.`
  Verification: `PASS — all six candidates close as four derived gates plus two reviewed selector-contract inputs; three exact behavior families retain separate one-capture-per-transaction, three-transaction 48-lane, and four-transaction 64-lane evidence; the RAM-guarded generator/public-sample collection reports Files=2/Tests=121 and support/manifest accounting reports Files=2/Tests=7098; inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.4.13: disposition extended AXI claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.14`
  Status: `done`
  Goal: `Disposition the 40 backend, validation, and public-API backlog candidates in Chapter 14l.`
  Acceptance: `VHDL/backend support, external validation, generation structure, semantic export, and embedding/API statements join their exact producers and negative controls without promoting roadmap residue.`
  Verification: `PASS — all 40 candidates close as 39 derived gates plus one reviewed selector-contract input; bounded VHDL generic maps, direct VHDL typed ports/literals/arithmetic, optional ABC mapping, and MCP non-object rejection retain four separate producer/oracle chains; the RAM-guarded exact collection reports Files=4/Tests=167; inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.4.14: disposition backend API claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.15`
  Status: `done`
  Goal: `Disposition the 46 shipped AXI IAL2 example candidates in Chapter 16a.`
  Acceptance: `Guided, initiator, more-control, raw, write/read, single/four-beat, and validation statements join executable example and lowering evidence; headings and syntax values remain non-claims where appropriate.`
  Verification: `PASS — all 46 candidates close as 42 derived gates plus four reviewed shipment-accounting fragments; six AXI channel primitives, five bounded compositions, the current initiator catalog, and the live 140-source manager cross-reference retain 13 separate producer/oracle chains; the RAM-guarded exact collection reports Files=12/Tests=49; inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.4.15: disposition AXI example claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.4.16`
  Status: `done`
  Goal: `Disposition the 43 AXI manager capacity/status candidates in Chapter 16aa.`
  Acceptance: `ID families, transaction events, auto/dynamic IDs, ordering, output capture/banks, raw ARLEN, and bounded progression claims retain exact generated/report/runtime evidence.`
  Verification: `PASS — all 43 candidates close as derived gates across eight separate source-census, foundation, queue, mixed-ID, population, scope, output-bank, and composite-bank evidence families; current reports reproduce every published cardinality, the unchanged-product exact AXI watcher baseline remains Files=2/Tests=121, support accounting reports Files=2/Tests=7098, and inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.4.16: disposition AXI manager reference claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.5`
  Status: `done`
  Goal: `Review and migrate the 232 IAL2-AHB execution-scale book candidates.`
  Acceptance: `Every 16c candidate is tied to its exact scale/gate producer and a separating excess or mutation oracle, reclassified as reviewed incidental, or assigned an explicit repair; historical observations are not promoted into current support claims.`
  Verification: `PASS — all six evidence-coherent children close the exact 232-candidate Chapter 16c group as 55 derived gates plus 177 reviewed outcomes; ial2_ahb is required-complete at 232/232 with zero open candidates.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.5: partition IAL2 AHB claim review`
  Children: `CLAIM-VERIFICATION-ADOPTION.5.5.1, CLAIM-VERIFICATION-ADOPTION.5.5.2, CLAIM-VERIFICATION-ADOPTION.5.5.3, CLAIM-VERIFICATION-ADOPTION.5.5.4, CLAIM-VERIFICATION-ADOPTION.5.5.5, CLAIM-VERIFICATION-ADOPTION.5.5.6`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.5.1`
  Status: `done`
  Goal: `Disposition the 6 Chapter 16c guided-mode, byte-lane, and HBURST candidates on lines 1-1176.`
  Acceptance: `Mode-map and guided endpoint/interconnect claims retain exact lane, in-word progression, and bounded HBURST evidence without promoting syntax examples into independent capabilities.`
  Verification: `PASS — all six candidates close as derived gates across four separate composite mode-map, byte-lane, in-word SEQ, and HBURST progression evidence families; current reports reproduce every endpoint field, the RAM-guarded exact oracle collection reports Files=9/Tests=35, and inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.5.1: disposition guided AHB claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.5.2`
  Status: `done`
  Goal: `Disposition the 37 Chapter 16c requester-shape and exact-one-through-four BUSY candidates on lines 1177-1656.`
  Acceptance: `Requester widths, source clauses, qualified BUSY retirement, exact count bounds, aliases, reports, artifacts, and runtime statements retain count-specific evidence or exact chronology.`
  Verification: `PASS — all 37 candidates close as 17 derived gates plus 20 reviewed historical/structural outcomes across eight requester, count-specific, paired, generalized-bound, artifact, and live-support evidence families; the RAM-guarded exact oracle collection reports Files=15/Tests=65, support/disposition gates report Files=3/Tests=7107, and inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.5.2: disposition requester AHB claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.5.3`
  Status: `done`
  Goal: `Disposition the 34 Chapter 16c paired-BUSY and subordinate candidates on lines 1657-2037.`
  Acceptance: `One-/two-window paired ownership, subordinate storage/phase behavior, aliases, diagnostics, and exact-one-through-four runtimes join their distinct aggregate evidence.`
  Verification: `PASS — all 34 candidates close as seven derived gates plus 27 reviewed historical/structural outcomes across two-window topology/runtime, fixed-wrap, phase-pipeline, and subordinate storage/width evidence; the RAM-guarded exact collection reports Files=8/Tests=33, the unchanged-product paired baseline remains Files=15/Tests=65, support/disposition gates report Files=3/Tests=7107, and inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.5.3: disposition paired subordinate AHB claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.5.4`
  Status: `done`
  Goal: `Disposition the 71 Chapter 16c direct-seed and exact-count progression candidates on lines 2038-2400.`
  Acceptance: `Direct subordinate/requester seeds, arbitration/phase repairs, exact-count generic/alias progression, artifacts, semantics, MCP, runtime, and shipment checkpoints remain distinguishable.`
  Verification: `PASS — all 71 candidates close as six derived gates plus 65 reviewed historical/structural outcomes across direct-repair chronology, two-window exact-three topology/runtime, exact-four requester surfaces, and one-window exact-four paired runtime; the RAM-guarded exact collection reports Files=9/Tests=34, support/disposition gates report Files=3/Tests=7107, and inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.5.4: disposition direct exact-count AHB claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.5.5`
  Status: `done`
  Goal: `Disposition the 62 Chapter 16c exact-four, two-window, generalized-range, and repair candidates on lines 2401-2640.`
  Acceptance: `Exact-four paired/two-window behavior, generalized 2..16 bounds, adjacent-invalid controls, qualified-event repair, and time-local accounting retain separate current and historical outcomes.`
  Verification: `PASS — all 62 candidates close as 15 derived gates plus 47 reviewed historical/structural outcomes across one-window alias parity, two-window exact-four topology/runtime and alias, live accounting, generalized 2..16 behavior, qualified-event repair, paired propagation, and exact-two preservation; the RAM-guarded exact collection reports Files=11/Tests=47, support/disposition gates report Files=3/Tests=7107, and inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.5.5: disposition generalized AHB claims`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.5.6`
  Status: `done`
  Goal: `Disposition the 22 Chapter 16c residue, current-boundary, and boundary-free phase candidates on lines 2641-3227.`
  Acceptance: `Current support/residue, bounded-count, runtime, aggregate, and direct-phase statements join live gates while shipment snapshots and selector chronology remain explicitly historical.`
  Verification: `PASS — all 22 candidates close as four derived gates plus 18 reviewed historical/structural outcomes across the generalized residue boundary, exact-three runtime, generated phase pipeline, direct Q-named capacity-one repair, aggregate/paired preservation, old support checkpoints, and test locators; the RAM-guarded exact collection reports Files=9/Tests=36, support/disposition gates report Files=3/Tests=7107, the IAL2 AHB group is required-complete at 232/232, and inventory/disposition, Knowledge Map, mdBook, containment, staged-acceptance, and doctrine gates pass.`
  Commit: `CLAIM-VERIFICATION-ADOPTION.5.5.6: close IAL2 AHB claim review`

- ID: `CLAIM-VERIFICATION-ADOPTION.5.6`
  Status: `active`
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
- `2026-08-21`: The 232-candidate Chapter 16c group is partitioned by its
  shipped-reference structure and evidence ownership: guided modes, requester
  exact counts, paired/subordinate behavior, direct-seed/count progression,
  exact-four/generalized repair chronology, and current residue/boundary
  phases. The disjoint `6 + 37 + 34 + 71 + 62 + 22` ranges prevent one current
  runtime gate from laundering unrelated shipment-time accounting.
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
- `2026-08-21`: The first protocol review keeps AXI manager capability
  evidence separate from the selection and resource history that produced it.
  Current concrete and dynamic ID queues, depth-2/depth-3 storage, head
  ordering, RLAST qualification, runtime beat validation, and multi-beat
  output banks use distinct bounded PPIF producers and focused generator/
  dynamic-ID oracles. Temporary helper counts, former local gates, selector
  cardinalities, host-memory percentages, stopped probes, and report byte
  sizes remain reviewed historical or structural context. The exact 65
  identities close as 28 derived gates and 37 reviewed outcomes without
  changing product or book behavior.
- `2026-08-21`: The foundational APB review separates shipped endpoint and
  composition behavior from the public contracts that selected it. Base
  completer storage, source-ordered multi-register decode, 16-bit data,
  3-bit protection, 2-bit strobes, one-entry request queueing, overflow
  rejection, and generated review artifacts use the ordinary requester,
  completer, and composition producers plus focused endpoint/composition
  oracles. Status width, address/data/reset constraints, and byte-lane widths
  inside the preceding contract records remain reviewed structural inputs.
  The exact 11 identities close as six derived gates and five reviewed
  outcomes without changing product or book behavior.
- `2026-08-21`: The APB width/protection/timing review separates current
  generated behavior from the no-behavior records that selected it. Data16
  lanes and alignment, narrowed remaining-width guards, 32-bit and data16
  register-local protection, one-slot queued timing, queued `PPROT/PSTRB`,
  adjacent setup, and two-peripheral propagation use ordinary requester,
  completer, composition, alias, and artifact oracles. Pre-data16 hard-coded
  limits, readiness sample scopes, width/status/queue contract numerals, and
  superseded 32-bit-only guards remain reviewed Git chronology. The exact 35
  identities close as 13 derived gates and 22 reviewed outcomes without
  changing product or book behavior.

## Open Questions

- None blocking. `.5.4.4` owns the next 46 APB multi-register, protection,
  and composition candidates on Chapter 14h lines 1200-1699.

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
- [x] **ROOT CAUSE (WHY + WHERE)** — cross-partition `git log -S` traces the queue-head read-data count to `81dc0834b`, the multiple depth-3 factorization to `f208c5c41`, and the 89.5-percent readiness checkpoint to `ded1dc51a`; `dc1c64afb` later moved all three into the focused Chapter 14 parts. The current inventory still treated 65 lines across 14f/14g uniformly as open debt even though they mix current generated behavior with immutable selector, helper-probe, and host-resource chronology.
- [x] **ADDRESSED (verified)** — all 65 identities now join exactly 28 distinct three-leg derived gates plus 37 reviewed historical or structural outcomes. Concrete-ID and dynamic-ID queue families retain separate depth, ordering, RLAST, runtime-validation, and output-bank evidence; every reviewed outcome names its exact durable audit/selection record. The canonical join reports `candidates=1415`, `disposed=403`, `gates=276`, `reviewed=127`, and `protocol=65/557` with 492 open.
- [x] **NO REGRESSION** — the RAM-guarded exact AXI manager/dynamic-ID collection reports `All tests successful` at `Files=2, Tests=121`; the disposition mutation suite separately reports `Files=1, Tests=9`. Inventory remains `1,415` candidates / `1,031` governed constants, and the join closes protocol `65/557` as `28` gates / `37` reviewed outcomes. Knowledge Map parity reports `1,127` facts / `5,916` questions / `6,083` occurrences / `130` shards; live containment covers `3,022/3,022` paths with unchanged `51,089`-line / `2,699,163`-byte book authority. All 53 chapters test; the inspected 88-file/18,604-KiB build is removed. Task, docs-relative-path, Memory, reference-authority, diff, and staged doctrine gates pass.
- [x] **ROOT CAUSE (WHY + WHERE)** — cross-partition `git log -S` traces the selected 2-bit requester status contract to `836e7c8fa`, the 32-bit/four-byte multi-register contract to `8c98e9bf7`, and the 3-bit/4-bit sideband contract to `240106916`; `dc1c64afb` later moved those records into focused Chapter 14h. The current inventory still left all 11 foundational 14h/16b identities open even though they mix six current generated behavior claims with five immutable contract inputs.
- [x] **ADDRESSED (verified)** — all 11 identities now join exactly six three-leg derived gates plus five reviewed structural outcomes. Base completer, multi-register, data16/sideband, and queued-timing behavior retain separate producer/fixture/oracle chains; reviewed outcomes name their exact durable contract-selection records. The canonical join reports `candidates=1415`, `disposed=414`, `gates=282`, `reviewed=132`, and `protocol=76/557` with 481 open.
- [x] **NO REGRESSION** — the RAM-guarded exact APB completer/composition collection reports `All tests successful` at `Files=2, Tests=133`; the disposition mutation suite separately reports `Files=1, Tests=9`. Inventory remains `1,415` candidates / `1,042` governed constants, and the join closes protocol `76/557` with the new slice at `6` gates / `5` reviewed outcomes. Knowledge Map parity reports `1,128` facts / `5,921` questions / `6,088` occurrences / `130` shards; live containment covers `3,023/3,023` paths with unchanged `51,089`-line / `2,699,163`-byte book authority. All 53 chapters test; the inspected 88-file/18,604-KiB build is removed. Task, docs-relative-path, Memory, reference-authority, diff, and staged doctrine gates pass.
- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` traces the pre-data16 hard-coded-width snapshot to `a6f54de4f`, the selected data16 matrix to `a5d804145`, the temporary 32-bit protection guard to `8a2a76243`, the depth-1 timing contract to `ba95c7a5f`, and the later 32-bit-only timing snapshot to `fbd82b617`. The current inventory left all 35 Chapter 14h identities open even though 13 describe current generated behavior and 22 are immutable readiness, selector, contract, or superseded-guard chronology.
- [x] **ADDRESSED (verified)** — all 35 identities now join exactly 13 three-leg derived gates plus 22 reviewed historical or structural outcomes. Data16/remaining-width, protection, queued timing, queued sideband, adjacent setup, and multi-peripheral propagation retain separate producer/fixture/oracle chains; every reviewed outcome names its exact durable selection or audit record. The canonical join reports `candidates=1415`, `disposed=449`, `gates=295`, `reviewed=154`, and `protocol=111/557` with 446 open.
- [x] **NO REGRESSION** — the RAM-guarded exact APB alias/completer/composition collection reports `All tests successful` at `Files=3, Tests=147`; the disposition mutation suite separately reports `Files=1, Tests=9`. Inventory remains `1,415` candidates / `1,077` governed constants, and the join closes protocol `111/557` with the new slice at `13` gates / `22` reviewed outcomes. Knowledge Map parity reports `1,129` facts / `5,926` questions / `6,093` occurrences / `130` shards; live containment covers the complete resulting tree with unchanged `51,089`-line / `2,699,163`-byte book authority. All 53 chapters test; the inspected 88-file/18,604-KiB build is removed. Task, docs-relative-path, Memory, reference-authority, diff, and staged doctrine gates pass.

- [x] **ROOT CAUSE (WHY + WHERE)** — exact `git log -S` pickaxes trace the fixed 32-bit multi-register contract to `d81ef3544`, the two-peripheral 32-bit no-policy multi-register contract to `ecedad38e`, and the selected status/control residue cleanup to `4dba45565`. The inventory still left all 46 Chapter 14h lines 1200-1699 identities open even though 17 state current generated behavior and 29 preserve readiness, selector, or contract chronology.
- [x] **ADDRESSED (verified)** — all 46 identities now join exactly 17 three-leg derived gates plus 29 reviewed structural or historical outcomes. Nine separate fixed/multi-peripheral, 16/32-bit, no-policy/protected, register-map, and report-residue families retain exact public fixtures and falsification paths; every reviewed outcome names its exact durable audit or selection record. The canonical join reports `candidates=1415`, `disposed=495`, `gates=312`, `reviewed=183`, and `protocol=157/557` with 400 open.
- [x] **NO REGRESSION** — the RAM-guarded exact APB alias/completer/composition collection reports `All tests successful` at `Files=3, Tests=147`; the disposition mutation suite separately reports `Files=1, Tests=9`. Inventory remains `1,415` candidates / `1,123` governed constants, and the new slice closes as `17` gates / `29` reviewed outcomes. Knowledge Map parity reports `1,130` facts / `5,931` questions / `6,098` occurrences / `130` shards; live containment covers the complete resulting tree with unchanged book authority. All 53 chapters test; the inspected 88-file/18,604-KiB build is removed. Task, docs-relative-path, Memory, reference-authority, diff, staged acceptance, and all 12 doctrine gates pass.

- [x] **ROOT CAUSE (WHY + WHERE)** — exact `git log -S` pickaxes trace the pre-generalization timing guard to `c1ac86b48`, the selected two-to-four-register source-shape contract to `e95f83b39`, and the maximum-count-five widening contract to `8d115617b`. The inventory still left all 37 Chapter 14h lines 1700-1999 identities open even though 14 state current generated behavior and 23 are section headings or immutable readiness, selector, contract, and superseded-guard chronology.
- [x] **ADDRESSED (verified)** — all 37 identities now join exactly 14 three-leg derived gates plus 23 reviewed navigation, structural, or historical outcomes. Six separate 16/32-bit, no-policy/protected, two-to-four-register, and two-to-five-register families retain exact public fixtures and too-few, mismatch, wrong-width/address/policy, and adjacent-excess-count falsification paths. The canonical join reports `candidates=1415`, `disposed=532`, `gates=326`, `reviewed=206`, and `protocol=194/557` with 363 open.
- [x] **NO REGRESSION** — the RAM-guarded exact APB alias/composition collection reports `All tests successful` at `Files=2, Tests=115`; the disposition mutation suite separately reports `Files=1, Tests=9`. Inventory remains `1,415` candidates / `1,160` governed constants, and the new slice closes as `14` gates / `23` reviewed outcomes. Knowledge Map parity reports `1,131` facts / `5,936` questions / `6,103` occurrences / `130` shards; live containment covers the complete resulting tree with unchanged book authority. All 53 chapters test; the inspected 88-file/18,604-KiB build is removed. Task, docs-relative-path, Memory, reference-authority, diff, staged acceptance, and all 12 doctrine gates pass.

- [x] **ROOT CAUSE (WHY + WHERE)** — exact `git log -S` pickaxes trace the selected data16 five-register addresses to `3657a7487`, the first six-register contract to `2c40f7672`, and the data16 six-register addresses to `96d6a812b`. The inventory still left all 28 Chapter 14h lines 2000-end identities open even though nine state current generated behavior and 19 are a section heading or immutable readiness, selector, contract, and prior-guard chronology.
- [x] **ADDRESSED (verified)** — all 28 identities now join exactly nine three-leg derived gates plus 19 reviewed navigation, structural, or historical outcomes. Five separate remaining data16/protected five-register and 16/32-bit no-policy six-register families retain exact public fixtures, `reg3/reg4/reg5` artifacts, and mismatch, wrong-width/stride/policy, excess-six, excess-seven, and protected-six falsification paths. The canonical join reports `candidates=1415`, `disposed=560`, `gates=335`, `reviewed=225`, and `protocol=222/557` with 335 open; all 157 Chapter 14h APB candidates are closed.
- [x] **NO REGRESSION** — the RAM-guarded exact APB alias/composition collection reports `All tests successful` at `Files=2, Tests=115`; the disposition mutation suite separately reports `Files=1, Tests=9`. Inventory remains `1,415` candidates / `1,188` governed constants, and the new slice closes as `9` gates / `19` reviewed outcomes. Knowledge Map parity reports `1,132` facts / `5,941` questions / `6,108` occurrences / `130` shards; live containment covers the complete resulting tree with unchanged book authority. All 53 chapters test; the inspected 88-file/18,604-KiB build is removed. Task, docs-relative-path, Memory, reference-authority, diff, staged acceptance, and all 12 doctrine gates pass.

- [x] **ROOT CAUSE (WHY + WHERE)** — exact `git log -S` pickaxes trace the base-zero size-four interconnect to `ab4838dd5`, the one-word HBURST endpoint to `3fb1cf7f4`, and generic/alias aggregate BUSY-park child counts to `43c48ecea` / `6cf029b33`. The inventory still left all 40 Chapter 14i lines 1-1070 identities open even though seven state current behavior and 33 are immutable contract inputs, time-local support milestones, or test/decision identifiers.
- [x] **ADDRESSED (verified)** — all 40 identities now join exactly seven three-leg derived gates plus 33 reviewed structural, historical, or navigation outcomes. Five separate one-window interconnect, aggregate byte-lane alias, HBURST endpoint, generic aggregate BUSY-park, and aggregate BUSY-park alias families retain exact source, child-count, report, artifact, policy, response, and profile-parity evidence. The canonical join reports `candidates=1415`, `disposed=600`, `gates=342`, `reviewed=258`, and `protocol=262/557` with 295 open; the exact foundational 14i range is closed.
- [x] **NO REGRESSION** — the RAM-guarded exact AHB endpoint/interconnect/HBURST/BUSY/requester/paired/alias collection reports `All tests successful` at `Files=13, Tests=57`; live support-accounting and capability-manifest oracles separately report `Files=2, Tests=7098`, and the disposition mutation suite reports `Files=1, Tests=9`. Inventory remains `1,415` candidates / `1,228` governed constants. Knowledge Map parity reports `1,133` facts / `5,946` questions / `6,113` occurrences / `130` shards; live containment covers the complete resulting tree with unchanged book authority. All 53 chapters test; the inspected 88-file/18,604-KiB build is removed. Task, docs-relative-path, Memory, reference-authority, diff, staged acceptance, and all 12 doctrine gates pass.

- [x] **ROOT CAUSE (WHY + WHERE)** — exact `git log -S` pickaxes trace the skipped WRAP base to `ec9fa2ee3`, the dropped boundary-free phase to `5cbed61cc`, the original exact-three `2..3` contract to `5623b975a`, and its profile alias shipment to `c224b2cba`. The inventory still left all 49 Chapter 14i lines 1071-1406 identities open even though eight state current behavior and 41 are audit observations, selected contracts, test/decision identifiers, time-local support checkpoints, or the superseded pre-generalization bound.
- [x] **ADDRESSED (verified)** — all 49 identities now join exactly eight three-leg derived gates plus 41 reviewed structural, historical, or navigation outcomes. Six separate fixed-WRAP, direct exact-one, paired exact-one, exact-two requester, exact-three requester, and exact-three alias families retain exact source, counter, qualification, ownership, data-beat, artifact, semantic/MCP, and profile-parity evidence. The canonical join reports `candidates=1415`, `disposed=649`, `gates=350`, `reviewed=299`, and `protocol=311/557` with 246 open; current generalized `2..16` behavior is not confused with the historical exact-three `2..3` shipment.
- [x] **NO REGRESSION** — the RAM-guarded exact AHB wrap/current-surface/generated-and-direct-phase/exact-one/two/three/paired/semantic/MCP/alias collection reports `All tests successful` at `Files=17, Tests=67`; live support-accounting and capability-manifest oracles separately report `Files=2, Tests=7098`, and the disposition mutation suite reports `Files=1, Tests=9`. Inventory remains `1,415` candidates / `1,277` governed constants. Knowledge Map parity reports `1,134` facts / `5,951` questions / `6,118` occurrences / `130` shards; live containment covers the complete resulting tree with unchanged book authority. All 53 chapters test; the inspected 88-file/18,604-KiB build is removed. Task, docs-relative-path, Memory, reference-authority, diff, staged acceptance, and all 12 doctrine gates pass.

- [x] **ROOT CAUSE (WHY + WHERE)** — exact `git log -S` pickaxes trace the interconnect arbitration repair to `6eeac974c`, the generated-endpoint repair to `1eec6253d`, the one-window exact-three shipment to `00d71114d`, and the two-window shipment to `1a73bc65e`. The inventory still left all 27 Chapter 14i lines 1407-1661 identities open even though two state current numeric behavior and 25 are pre-repair audit observations, contract inputs, decision identifiers, projected values, or shipment-time support checkpoints.
- [x] **ADDRESSED (verified)** — all 27 identities now join exactly two three-leg derived gates plus 25 reviewed structural, historical, or navigation outcomes. One-window exact-three artifact/strict/semantic/MCP behavior and two-window assertion-enabled runtime retain separate producer/fixture/oracle chains; interconnect, generated-endpoint, and direct-seed arbitration repairs remain in the exact no-regression collection. The canonical join reports `candidates=1415`, `disposed=676`, `gates=352`, `reviewed=324`, and `protocol=338/557` with 219 open.
- [x] **NO REGRESSION** — the RAM-guarded exact AHB arbitration/generated-and-direct-endpoint/one-/two-window paired/exact-two/exact-three/alias collection reports `All tests successful` at `Files=15, Tests=54`; live support-accounting and capability-manifest oracles separately report `Files=2, Tests=7098`, and the disposition mutation suite reports `Files=1, Tests=9`. Inventory remains `1,415` candidates / `1,304` governed constants. Knowledge Map parity reports `1,135` facts / `5,956` questions / `6,123` occurrences / `130` shards; live containment covers the complete resulting tree with unchanged book authority. All 53 chapters test; the inspected 88-file/18,604-KiB build is removed. Task, docs-relative-path, Memory, reference-authority, diff, staged acceptance, and all 12 doctrine gates pass.

- [x] **ROOT CAUSE (WHY + WHERE)** — cross-document `git log -S` pickaxes trace minimum-width exact-four requester shipment to `95bfb7e4b`, the original `2..4` contract to `58efc8aff`, one-window paired shipment to `c42347a5e`, and its four-subtest/88-assertion alias parity to `40b8ead71`. The inventory still left all 35 Chapter 14i lines 1662-1779 identities open even though five state current numeric behavior and 30 are disposable probes, readiness/contract inputs, projected totals, shipment checkpoints, or the removed two-window candidate workspace.
- [x] **ADDRESSED (verified)** — all 35 identities now join exactly five three-leg derived gates plus 30 reviewed structural or historical outcomes. Exact-four requester width/runtime, one-window paired artifact/runtime, and paired profile-alias parity retain separate producer/fixture/oracle chains; the original exact-four `2..4` bound is not confused with current generalized `2..16`, and two-window runtime beyond line 1779 remains separately owned. The canonical join reports `candidates=1415`, `disposed=711`, `gates=357`, `reviewed=354`, and `protocol=373/557` with 184 open.
- [x] **NO REGRESSION** — the RAM-guarded exact-four requester/paired generic/profile collection reports `All tests successful` at `Files=4, Tests=17`; live support-accounting and capability-manifest oracles separately report `Files=2, Tests=7098`, and the disposition mutation suite reports `Files=1, Tests=9`. Inventory remains `1,415` candidates / `1,339` governed constants. Knowledge Map parity reports `1,136` facts / `5,961` questions / `6,128` occurrences / `130` shards; live containment covers the complete resulting tree with unchanged book authority. All 53 chapters test; the inspected 88-file/18,604-KiB build is removed. Task, docs-relative-path, Memory, reference-authority, diff, staged acceptance, and all 12 doctrine gates pass.

- [x] **ROOT CAUSE (WHY + WHERE)** — cross-document `git log -S` pickaxes trace two-window exact-four shipment to `a62ddb705`, its four-subtest/97-assertion alias parity to `3519cde33`, and generalized `2..16` shipment to `2f64611ca`; the same history preserves the superseded `2..4` activation states. The inventory still left all 32 Chapter 14i lines 1780-1895 identities open even though nine state current numeric behavior and 23 are readiness/contract inputs, projected totals, superseded activation states, or shipment/selector checkpoints.
- [x] **ADDRESSED (verified)** — all 32 identities now join exactly nine three-leg derived gates plus 23 reviewed structural or historical outcomes. Two-window exact-four topology/runtime, its profile alias, live 332/373/56 split-28/28 support accounting, and generalized `2..16` range/runtime/no-fixture behavior retain separate producer/fixture/oracle chains; superseded `2..4` statements remain chronology. The canonical join reports `candidates=1415`, `disposed=743`, `gates=366`, `reviewed=377`, and `protocol=405/557` with 152 open.
- [x] **NO REGRESSION** — the RAM-guarded two-window exact-four generic/profile and generalized-BUSY-range collection reports `All tests successful` at `Files=3, Tests=12`; live support-accounting and capability-manifest oracles separately report `Files=2, Tests=7098`, and the disposition mutation suite reports `Files=1, Tests=9`. Inventory remains `1,415` candidates / `1,371` governed constants. Knowledge Map parity reports `1,137` facts / `5,966` questions / `6,133` occurrences / `130` shards; live containment covers the complete resulting tree with unchanged book authority. All 53 chapters test; the inspected 88-file/18,604-KiB build is removed. Task, docs-relative-path, Memory, reference-authority, diff, staged acceptance, and all 12 doctrine gates pass.

- [x] **ROOT CAUSE (WHY + WHERE)** — exact pre-partition `git log -S` pickaxes trace focused-index synchronization to `4ba108b3d`, the aggregate-diagnostic expectation to `ce891bbd7`, the four-fence mdBook repair to `59fcaa99e`, the Chapter 16c BUSY residue repair to `3fb84b23e`, and the task-ledger diagnosis/repair to `bd1ef6765`/`c21765214`. The inventory still left all 17 Chapter 14i lines 1896-end identities open even though only one states current Chapter 16c catalog/range truth and 16 are selector/task identifiers or immutable synchronization, diagram, and task-ledger checkpoints.
- [x] **ADDRESSED (verified)** — all 17 identities now join exactly one three-leg derived gate plus 16 reviewed structural, navigation, or historical outcomes. The live Chapter 16c exact-one-through-four fixture catalog versus generic canonical `5..16` behavior retains lowerer, generated-candidate, assertion-enabled runtime, invalid-neighbor, and support-accounting proof. The canonical join reports `candidates=1415`, `disposed=760`, `gates=367`, `reviewed=393`, and `protocol=422/557` with 135 open.
- [x] **NO REGRESSION** — the RAM-guarded current AHB profile-diagnostic/generalized-range collection reports `All tests successful` at `Files=2, Tests=9`; live support-accounting and capability-manifest oracles separately report `Files=2, Tests=7098`, and the disposition mutation suite reports `Files=1, Tests=9`. Inventory remains `1,415` candidates / `1,388` governed constants. Knowledge Map parity reports `1,138` facts / `5,971` questions / `6,138` occurrences / `130` shards; live containment covers the complete resulting tree with unchanged book authority. All 53 chapters test; the inspected 88-file/18,604-KiB build is removed. Task, docs-relative-path, Memory, reference-authority, diff, staged acceptance, and all 12 doctrine gates pass.

- [x] **ROOT CAUSE (WHY + WHERE)** — pre-partition `git log -S` pickaxes trace the three-transaction raw-ARLEN shipment to `e8f556b88`, its 48-lane multi-beat extension to `e36a79af6`, the four-transaction 64-lane extension to `56f251e3e`, and the `.347`/`.50` selector contracts to `89069607a`/`c52053d90`. The inventory still left all six Chapter 14j identities open even though four state current generated cardinalities and two merely record one-bit last-signal contract inputs.
- [x] **ADDRESSED (verified)** — all six identities now join exactly four three-leg derived gates plus two reviewed structural outcomes. One dynamic plus two static transactions derive one raw-ARLEN capture per transaction and 3 x 16 = 48 RDATA/RRESP lanes with three companion sets; adding a third static transaction derives 4 x 16 = 64 lanes of each kind. Distinct fixture/oracle chains check transaction membership, RID/RLAST guards, banks, masks, lengths, aggregates, reports, scheduled FSM, and HDL. The canonical join reports `candidates=1415`, `disposed=766`, `gates=371`, `reviewed=395`, and `protocol=428/557` with 129 open.
- [x] **NO REGRESSION** — the RAM-guarded exact generator/public-sample collection reports `All tests successful` at `Files=2, Tests=121`; live support-accounting and capability-manifest oracles separately report `Files=2, Tests=7098`, and the disposition mutation suite reports `Files=1, Tests=9`. Inventory remains `1,415` candidates / `1,394` governed constants. Knowledge Map parity reports `1,139` facts / `5,976` questions / `6,143` occurrences / `131` shards; live containment covers the complete resulting tree with unchanged book authority. All 53 chapters test; the inspected 88-file/18,604-KiB build is removed. Task, docs-relative-path, Memory, reference-authority, diff, staged acceptance, and all 12 doctrine gates pass.

- [x] **ROOT CAUSE (WHY + WHERE)** — pre-partition `git log -S` pickaxes trace the first external-RTL one-bit generic map to `792f13a59`, literal-pair modulo lowering to `412a2e512`, explicit ABC opt-in to `8b3d981ca`, MCP non-object rejection to `b020ecbfa`, and the one-bit `.50 -> .51` selector to `c52053d90`. The inventory still left all 40 Chapter 14l identities open even though 39 state current behavior and one is immutable selector chronology.
- [x] **ADDRESSED (verified)** — all 40 identities now join exactly 39 three-leg derived gates plus one reviewed structural outcome. Bounded generic maps, direct typed ports/literals/arithmetic, optional default-off ABC validation, and pre-dispatch MCP non-object rejection retain four separate producer/oracle chains. The canonical join reports `candidates=1415`, `disposed=806`, `gates=410`, `reviewed=396`, and `protocol=468/557` with 89 open.
- [x] **NO REGRESSION** — the RAM-guarded VHDL facade/direct, ABC-contract, and MCP-envelope collection reports `All tests successful` at `Files=4, Tests=167`; live support-accounting and capability-manifest oracles separately report `Files=2, Tests=7098`, and the disposition mutation suite reports `Files=1, Tests=9`. Inventory remains `1,415` candidates / `1,434` governed constants. Knowledge Map parity reports `1,140` facts / `5,981` questions / `6,148` occurrences / `132` shards; staged live containment covers `3,037/3,037` paths with unchanged `51,089`-line / `2,699,163`-byte book authority. All 53 chapters test; the inspected 88-file/18,604-KiB build is removed. Task, docs-relative-path, Memory, reference-authority, diff, staged acceptance, and all 12 doctrine gates pass.

- [x] **ROOT CAUSE (WHY + WHERE)** — pre-split `git log -S` pickaxes trace exact-one AW restoration to `aaef04d83`, fixed-four W shipment to `6806ab9d6`, full-write response retirement to `f8838824d`, fixed-four read composition to `0e31c1f93`, and the three time-local support checkpoints to `25068673c`, `0e31c1f93`, and `d5cadf49b`. The inventory still left all 46 Chapter 16a identities open even though 42 state current behavior and four contain shipment-time corpus totals or a test locator.
- [x] **ADDRESSED (verified)** — all 46 identities now join exactly 42 three-leg derived gates plus four reviewed historical outcomes. Six channel primitives, five bounded compositions, the complete current initiator catalog, and the live 140-source manager cross-reference retain 13 separate producer/oracle chains. The canonical join reports `candidates=1415`, `disposed=852`, `gates=452`, `reviewed=400`, and `protocol=514/557` with 43 open.
- [x] **NO REGRESSION** — the RAM-guarded exact guided/initiator channel and composition collection reports `All tests successful` at `Files=12, Tests=49`; live support-accounting and capability-manifest oracles separately report `Files=2, Tests=7098`, and the disposition mutation suite reports `Files=1, Tests=9`. Inventory remains `1,415` candidates / `1,480` governed constants. Knowledge Map parity reports `1,141` facts / `5,986` questions / `6,153` occurrences / `132` shards; staged live containment covers `3,038/3,038` paths with unchanged `51,089`-line / `2,699,163`-byte book authority. All 53 chapters test; the inspected 88-file/18,604-KiB build is removed. Task, docs-relative-path, Memory, reference-authority, diff, staged acceptance, and all 12 doctrine gates pass.
- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` pickaxes trace the Chapter 16aa foundation/source census to `7074d3234`, concrete multi-group and mixed queue cardinalities to `a97e02ca8`, and read-data/output-bank totals to `da50f9dfc`. The inventory still left all 43 chapter identities open even though each describes current tracked source, generated report, or bounded composition behavior; no candidate-specific card joined the chapter to those already-shipped producers and watchers.
- [x] **ADDRESSED (verified)** — all 43 identities now join derived gates across eight separate census, foundation, concrete multi-group, mixed runtime-ID queue, population-bound, read-data-scope, output-bank, and composite-bank evidence families. Fourteen current public report runs plus an independent clause scan reproduce `44/44/46/72/142/44`, both multi-group metric vectors, mixed `6/18/15/2/2`, scope `4/2`, `4/2`, and `70/42`, both composite `48/48/48/12` results, and the `140/139/138/17/78/130/79/48` overlapping source census. The canonical join reports `candidates=1415`, `disposed=895`, `gates=495`, `reviewed=400`, and protocol `557/557` with zero open and `required_complete=1`.
- [x] **NO REGRESSION** — the exact manager/dynamic-ID watcher baseline at unchanged-product commit `eb9e6a2d2` reports `All tests successful` at `Files=2, Tests=121`; `git diff --name-only eb9e6a2d2..HEAD` proves only claim documentation/registries changed afterward, while this slice freshly re-derived the public reports. Live support-accounting and capability-manifest oracles report `Files=2, Tests=7098`, and the disposition mutation suite reports `Files=1, Tests=9`. Inventory remains `1,415` candidates / `1,523` governed constants. Knowledge Map parity reports `1,142` facts / `5,993` questions / `6,160` occurrences / `132` shards; staged live containment covers `3,039/3,039` paths with unchanged `51,089`-line / `2,699,163`-byte book authority. All 53 chapters test; the inspected 88-file/18,604-KiB build is removed. Task, docs-relative-path, Memory, reference-authority, diff, staged acceptance, and all 12 doctrine gates pass.
- [x] **ROOT CAUSE (WHY + WHERE)** — clean commit `5b4ebac13` closes the 557-candidate protocol group, leaving the existing 232-candidate `.5.5` leaf as the next dependency-ordered frontier. The single Chapter 16c source mixes current guided behavior and runtime with exact-count evolution, direct-seed repairs, aliases, projections, and shipment-time support checkpoints; treating all 232 candidates as one slice would alias unrelated evidence and create an unsafe review unit.
- [x] **ADDRESSED (verified)** — committed-inventory line aggregation partitions Chapter 16c into six disjoint children: `.5.5.1=6` on lines 1-1176, `.5.5.2=37` on 1177-1656, `.5.5.3=34` on 1657-2037, `.5.5.4=71` on 2038-2400, `.5.5.5=62` on 2401-2640, and `.5.5.6=22` on 2641-3227. Their exact sum is 232, `.5.5.1` alone is active, and no claim, disposition, evidence producer, product behavior, capability, or support statement changes in this partition slice.
- [x] **NO REGRESSION** — task-tree integrity, Memory, the unchanged `1,415`-candidate / `1,523`-constant inventory, the disposition join with `ial2_ahb=0/232` intentionally open, docs-relative paths, Knowledge Map parity, live-document authority, diff hygiene, staged acceptance, and all 12 doctrine gates pass from clean predecessor `5b4ebac13`.
- [x] **ROOT CAUSE (WHY + WHERE)** — clean partition commit `f97c905db` exposed six still-open Chapter 16c candidates on lines 184, 273-274, 337, and 408-409. Exact `--emit-schedule-json` runs reproduced all four lane bit ranges, `in_word_progressive`, and `hburst_in_word_progressive` with four beats/four bytes, separating a missing evidence join from a product-generation defect: the inventory had no candidate-specific join to the already-shipped requester/subordinate/interconnect generators, direct seed, and independent phase, lane, burst, and count watchers.
- [x] **ADDRESSED (verified)** — all six identities now join derived gates across four evidence families: the composite raw/full-control mode boundary; four little-endian byte lanes; byte/halfword progression inside one 32-bit word; and byte-only four-beat `INCR4`/`WRAP4`. Direct reports reproduce lane bits `[7:0]`, `[15:8]`, `[23:16]`, `[31:24]`, `in_word_progressive`, and HBURST `beats_per_burst=4` / `window_bytes=4`; exact-one absence, 5/8/16 generalized runtimes, completion-edge ownership, crossing, lane-order, and start/wrap controls remain distinct. The canonical join reports `candidates=1415`, `disposed=901`, `gates=501`, `reviewed=400`, and `ial2_ahb=6/232` with 226 open.
- [x] **NO REGRESSION** — the RAM-guarded endpoint/generated-phase/direct-phase/generalized-count collection reports `All tests successful` at `Files=6, Tests=21`; exact-one requester, paired one-hot ownership, and current-book truthfulness separately report `Files=3, Tests=14`. Live support-accounting and capability-manifest oracles report `Files=2, Tests=7098`, and the disposition mutation suite reports `Files=1, Tests=9`. Inventory remains `1,415` candidates / `1,529` governed constants. Knowledge Map parity reports `1,143` facts / `5,998` questions / `6,165` occurrences / `132` shards; live containment covers the complete resulting tree with unchanged book authority. All 53 chapters test. A misaddressed disposable build was immediately copied into repository-local `book/build`, verified at 88 files / 18,604 KiB with matching normalized SHA-256 `8a5f40b1f81931257bdc20ebedaaeb0aaadf007046cc4f10fd0823a4ce7cf44d`, then both the exact off-repository source and inspected local copy were removed with residue censuses. Task, docs-relative-path, Memory, reference-authority, diff, staged acceptance, and all 12 doctrine gates pass.
- [x] **ROOT CAUSE (WHY + WHERE)** — clean commit `31961501b` leaves 37 Chapter 16c requester-shape and exact-one-through-four BUSY candidates open on lines 1177-1656. Direct `--emit-schedule-json` reports and the exact requester suites reproduce the published widths, qualified BUSY sequences, count traces, artifacts, and live support boundary, separating a missing evidence join from a product defect. Twenty neighboring numerals instead identify tests, proposed contracts, or immutable shipment checkpoints and must not become current measurements.
- [x] **ADDRESSED (verified)** — all 37 identities now join exactly 17 three-leg derived gates plus 20 reviewed historical/structural outcomes across eight distinct base requester, exact-one, paired exact-one, generalized-range, exact-two, exact-three, exact-four, paired-artifact/live-support evidence families. Direct reports reproduce 32/3/4/5/2-bit bindings, exact BUSY counts one through four, three IAL1 and four IAL0 paired artifacts, and the current 332/373/56 support boundary split 28/28. The canonical join reports `candidates=1415`, `disposed=938`, `gates=518`, `reviewed=420`, and `ial2_ahb=43/232` with 189 open.
- [x] **NO REGRESSION** — the RAM-guarded exact requester, one-/two-window paired, generic/alias, and generalized-bound collection reports `All tests successful` at `Files=15, Tests=65`; live support-accounting, capability-manifest, and disposition mutation oracles report `Files=3, Tests=7107`. Inventory remains `1,415` candidates / `1,566` governed constants. Knowledge Map parity reports `1,144` facts / `6,004` questions / `6,171` occurrences / `132` shards; the mdBook, containment, task, docs-relative-path, Memory, reference-authority, diff, staged acceptance, and all 12 doctrine gates pass.
- [x] **ROOT CAUSE (WHY + WHERE)** — clean commit `97004ca3e` leaves 34 Chapter 16c paired-BUSY/subordinate candidates open on lines 1657-2037. Current strict reports, exact `--emit-schedule-json` reports, and the paired, WRAP, phase, and subordinate suites reproduce the shipped topology, runtime, address progression, recapture, storage, and widths, separating a missing evidence join from product behavior defects. The same range interleaves readiness probes, selected future contracts, shipment totals, test/task locators, and pre-repair failures that must remain chronological rather than current.
- [x] **ADDRESSED (verified)** — all 34 identities now join exactly seven three-leg derived gates plus 27 reviewed historical/structural outcomes. Separate gates retain four children/29 signals/top semantic root/four IAL1/five IAL0 artifacts; two-window status/control BUSY runtime; fixed WRAP4/8/16 progression; exactly two phase acceptances/completions; one register at address zero; 32-bit address/data/register fields; and 2/3/4/1-bit control/response widths. The canonical join reports `candidates=1415`, `disposed=972`, `gates=525`, `reviewed=447`, and `ial2_ahb=77/232` with 155 open.
- [x] **NO REGRESSION** — the corrected RAM-guarded subordinate, parking/non-parking report, fixed-wrap, alias-truth, and phase-pipeline collection reports `All tests successful` at `Files=8, Tests=33`; the immediately preceding unchanged-product exact collection includes all four paired generic/alias runtimes at `Files=15, Tests=65`, and the intervening committed diff contains only claim documentation/registries. Live support-accounting, capability-manifest, and disposition mutation oracles report `Files=3, Tests=7107`. Inventory remains `1,415` candidates / `1,600` governed constants. Knowledge Map parity reports `1,145` facts / `6,010` questions / `6,177` occurrences / `132` shards; the mdBook, containment, task, docs-relative-path, Memory, reference-authority, diff, staged acceptance, and all 12 doctrine gates pass.
- [x] **ROOT CAUSE (WHY + WHERE)** — clean commit `60bfcfd06` leaves 71 Chapter 16c direct-seed/exact-count progression candidates open on lines 2038-2400. Exact `--emit-schedule-json` reports and the guarded t1520/t1531-t1538 collection reproduce current direct repair, exact-three, exact-four requester, and exact-four paired behavior, separating missing evidence joins from product defects. Sixty-five neighboring numerals instead identify tests/tasks, disposable readiness candidates, selected contracts, projections, shipment checkpoints, or pre-repair direct behavior and must remain chronology rather than current measurements.
- [x] **ADDRESSED (verified)** — all 71 identities now join exactly six three-leg derived gates plus 65 reviewed historical/structural outcomes. Four records use the two-window exact-three topology/runtime family, one uses exact-four requester semantic/MCP/verifier and stalled-runtime evidence, and one uses one-window exact-four paired runtime evidence. The canonical join reports `candidates=1415`, `disposed=1043`, `gates=531`, `reviewed=512`, and `ial2_ahb=148/232` with 84 open.
- [x] **NO REGRESSION** — the RAM-guarded direct, exact-three, two-window, requester exact-four, and paired exact-four generic/profile collection reports `All tests successful` at `Files=9, Tests=34`; live support-accounting, capability-manifest, and disposition mutation oracles report `Files=3, Tests=7107`. Inventory remains `1,415` candidates / `1,671` governed constants. Knowledge Map parity reports `1,146` facts / `6,016` questions / `6,183` occurrences / `132` shards; the mdBook, containment, task, docs-relative-path, Memory, reference-authority, diff, staged acceptance, and all 12 doctrine gates pass.
- [x] **ROOT CAUSE (WHY + WHERE)** — clean commit `229857a7d` leaves 62 Chapter 16c exact-four/two-window/generalized-range/repair candidates open on lines 2401-2640. Exact `--emit-schedule-json` evidence, `git blame`, and the guarded t1498/t1513-t1516/t1521/t1537-t1541 collection separate 15 current alias, topology, runtime, support, generalized-bound, adjacent-control, and qualified-event statements from 47 readiness/contract inputs, projections, superseded activations, shipment checkpoints, repeated time-local accounting statements, and pre-repair observations.
- [x] **ADDRESSED (verified)** — all 62 identities now join exactly 15 three-leg derived gates plus 47 reviewed historical/structural outcomes. Separate evidence families retain one-window exact-four alias parity; two-window exact-four generic runtime and alias parity; live 332/373/56 accounting split 28/28; canonical decimal `2..16`, invalid neighbors, minimum widths, no-fixture behavior, and seven 5/8/16 runtimes; repaired exact-one qualified-event behavior through requester and paired one-/two-window paths; and exact-two preservation. The canonical join reports `candidates=1415`, `disposed=1105`, `gates=546`, `reviewed=559`, and `ial2_ahb=210/232` with 22 open.
- [x] **NO REGRESSION** — the RAM-guarded exact-one repair, paired generic/profile, exact-two, exact-four one-/two-window generic/profile, and generalized-range collection reports `All tests successful` at `Files=11, Tests=47`; live support-accounting, capability-manifest, and disposition mutation oracles report `Files=3, Tests=7107`. Inventory remains `1,415` candidates / `1,733` governed constants. Knowledge Map parity reports `1,147` facts / `6,021` questions / `6,188` occurrences / `132` shards. All 53 mdBook chapters test; the inspected repository-local 88-file/18,604-KiB build is removed. Containment, task, docs-relative-path, Memory, reference-authority, diff, staged acceptance, and all 12 doctrine gates pass.
- [x] **ROOT CAUSE (WHY + WHERE)** — clean commit `54019bd0f` leaves the final 22 Chapter 16c residue/current-boundary/phase candidates open on lines 2641-3227. Exact `--emit-schedule-json` evidence, `git blame`, and the guarded aggregate, paired, truthfulness, phase, direct-seed, exact-three, and generalized-range suites separate four current boundary/runtime/repair statements from 18 exact-two/exact-three support milestones, readiness/contract values, superseded bounds, and test-path-only locators.
- [x] **ADDRESSED (verified)** — all 22 identities now join exactly four three-leg derived gates plus 18 reviewed historical/structural outcomes. Independent gates retain canonical decimal `2..16` with above-16 and malformed rejection; exact-three `3 -> 2 -> 1 -> 0` through continuous and 32-clock stalls; generated two-acceptance/two-completion boundary-free active phases with final-ERROR active-versus-IDLE separation; and direct capacity-one Q-named four-state completion-edge retention. All six children close Chapter 16c as 55 gates plus 177 reviewed outcomes. The canonical join reports `candidates=1415`, `disposed=1127`, `gates=550`, `reviewed=577`, and required-complete `ial2_ahb=232/232` with zero open.
- [x] **NO REGRESSION** — the RAM-guarded aggregate HBURST generic/profile, paired one-/two-window, current-book truthfulness, generated/direct phase, exact-three, and generalized-range collection reports `All tests successful` at `Files=9, Tests=36`; live support-accounting, capability-manifest, and disposition mutation oracles report `Files=3, Tests=7107`. Inventory remains `1,415` candidates / `1,755` governed constants. Knowledge Map parity reports `1,148` facts / `6,027` questions / `6,194` occurrences / `132` shards. All 53 mdBook chapters test; the inspected repository-local 88-file/18,604-KiB build is removed. Containment, task, docs-relative-path, Memory, reference-authority, diff, staged acceptance, and all 12 doctrine gates pass.

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
| `2026-08-21` | `.5.4.1` | exact AXI manager/dynamic-ID queue, ordering, RLAST, runtime-validation, and output-bank evidence; inventory/disposition; Knowledge Map; mdBook; containment; staged acceptance; doctrines | `PASS — all 65 candidates closed as 28 gates / 37 reviewed; protocol 65/557; Files=2/Tests=121 exact focused run; 1,031 governed constants; all registered doctrines` |
| `2026-08-21` | `.5.4.2` | APB completer storage; multi-register decode; data16/sidebands; queue timing; composition artifacts; inventory/disposition; Knowledge Map; mdBook; containment; staged acceptance; doctrines | `PASS — all 11 candidates closed as 6 gates / 5 reviewed; protocol 76/557; Files=2/Tests=133 exact focused run; 1,042 governed constants; all registered doctrines` |
| `2026-08-21` | `.5.4.3` | APB data16/remaining widths; 32-bit/data16 protection; queued timing and sidebands; adjacent setup; two-peripheral propagation; inventory/disposition; Knowledge Map; mdBook; containment; staged acceptance; doctrines | `PASS — all 35 candidates closed as 13 gates / 22 reviewed; protocol 111/557; Files=3/Tests=147 exact focused run; 1,077 governed constants; all registered doctrines` |
| `2026-08-21` | `.5.4.4` | APB fixed/multi-peripheral multi-register; 16/32-bit no-policy/protected source shapes; queued composition; register/window decode; report residue; inventory/disposition; Knowledge Map; mdBook; containment; staged acceptance; doctrines | `PASS — all 46 candidates closed as 17 gates / 29 reviewed; protocol 157/557; Files=3/Tests=147 exact focused run; 1,123 governed constants; all registered doctrines` |
| `2026-08-21` | `.5.4.5` | APB generalized 16/32-bit no-policy/protected register sets; two-to-four and two-to-five counts; stride/window/policy matrices; adjacent excess controls; inventory/disposition; Knowledge Map; mdBook; containment; staged acceptance; doctrines | `PASS — all 37 candidates closed as 14 gates / 23 reviewed; protocol 194/557; Files=2/Tests=115 exact focused run; 1,160 governed constants; all registered doctrines` |
| `2026-08-21` | `.5.4.6` | APB data16/protected five-register and 16/32-bit no-policy six-register bounds; reg3/reg4/reg5 artifacts; excess-six/seven and protected-six controls; inventory/disposition; Knowledge Map; mdBook; containment; staged acceptance; doctrines | `PASS — all 28 candidates closed as 9 gates / 19 reviewed; protocol 222/557; all 157 Chapter 14h APB candidates closed; Files=2/Tests=115 exact focused run; 1,188 governed constants; all registered doctrines` |
| `2026-08-21` | `.5.4.7` | AHB one-window decode; aggregate byte-lane aliases; one-word HBURST; endpoint/aggregate BUSY parking; requester and paired runtime; profile aliases; support/manifest accounting; inventory/disposition; Knowledge Map; mdBook; containment; staged acceptance; doctrines | `PASS — all 40 candidates closed as 7 gates / 33 reviewed; protocol 262/557; Files=13/Tests=57 exact focused run plus support Files=2/Tests=7098; 1,228 governed constants; all registered doctrines` |
| `2026-08-21` | `.5.4.8` | AHB WRAP; alias truth; generated/direct phase repairs; exact-one/two/three requester and paired runtime; semantic/MCP and profile-alias parity; support/manifest accounting; inventory/disposition; Knowledge Map; mdBook; containment; staged acceptance; doctrines | `PASS — all 49 candidates closed as 8 gates / 41 reviewed; protocol 311/557; Files=17/Tests=67 exact focused run plus support Files=2/Tests=7098; 1,277 governed constants; all registered doctrines` |
| `2026-08-21` | `.5.4.9` | AHB interconnect/generated-endpoint/direct-seed arbitration; one-/two-window exact-three topology, artifacts, runtime, semantic/MCP, and aliases; support/manifest accounting; inventory/disposition; Knowledge Map; mdBook; containment; staged acceptance; doctrines | `PASS — all 27 candidates closed as 2 gates / 25 reviewed; protocol 338/557; Files=15/Tests=54 exact focused run plus support Files=2/Tests=7098; 1,304 governed constants; all registered doctrines` |
| `2026-08-21` | `.5.4.10` | AHB exact-four requester width/runtime; one-window paired artifacts/runtime; requester and paired profile aliases; current generalized-bound controls; support/manifest accounting; inventory/disposition; Knowledge Map; mdBook; containment; staged acceptance; doctrines | `PASS — all 35 candidates closed as 5 gates / 30 reviewed; protocol 373/557; Files=4/Tests=17 exact focused run plus support Files=2/Tests=7098; 1,339 governed constants; all registered doctrines` |
| `2026-08-21` | `.5.4.11` | AHB two-window exact-four topology/runtime and alias; live support identity; generalized 2..16 admission, widths, runtime, diagnostics, no-fixture rule, and adjacent invalid controls; inventory/disposition; Knowledge Map; mdBook; containment; staged acceptance; doctrines | `PASS — all 32 candidates closed as 9 gates / 23 reviewed; protocol 405/557; Files=3/Tests=12 exact focused run plus support Files=2/Tests=7098; 1,371 governed constants; all registered doctrines` |
| `2026-08-21` | `.5.4.12` | AHB integration/selector history; public-sync focused-index and regression checkpoints; four-fence book migration; assertion expectation; Chapter 16c exact-one-through-four versus 5..16 boundary; task-ledger reconstruction; inventory/disposition; Knowledge Map; mdBook; containment; staged acceptance; doctrines | `PASS — all 17 candidates closed as 1 gate / 16 reviewed; protocol 422/557; Files=2/Tests=9 exact focused run plus support Files=2/Tests=7098; 1,388 governed constants; all registered doctrines` |
| `2026-08-21` | `.5.4.13` | mixed dynamic/static raw-ARLEN capture; three-/four-transaction multi-beat banks; RID/RLAST guards; masks, lengths, and aggregates; selector-contract history; inventory/disposition; Knowledge Map; mdBook; containment; staged acceptance; doctrines | `PASS — all 6 candidates closed as 4 gates / 2 reviewed; protocol 428/557; Files=2/Tests=121 exact focused run plus support Files=2/Tests=7098; 1,394 governed constants; all registered doctrines` |
| `2026-08-21` | `.5.4.14` | VHDL generic-map families; direct typed ports, literals, and arithmetic; optional ABC validation; MCP non-object envelopes; selector-contract history; inventory/disposition; Knowledge Map; mdBook; containment; staged acceptance; doctrines | `PASS — all 40 candidates closed as 39 gates / 1 reviewed; protocol 468/557; Files=4/Tests=167 exact focused run plus support Files=2/Tests=7098; 1,434 governed constants; all registered doctrines` |
| `2026-08-21` | `.5.4.15` | guided/initiator catalog; AXI AW/W/B/AR/R primitives; single/fixed-four write/read compositions; manager-family count; shipment accounting; inventory/disposition; Knowledge Map; mdBook; containment; staged acceptance; doctrines | `PASS — all 46 candidates closed as 42 gates / 4 reviewed; protocol 514/557; Files=12/Tests=49 exact focused run plus support Files=2/Tests=7098; 1,480 governed constants; all registered doctrines` |
| `2026-08-21` | `.5.4.16` | exact manager source/clause census; foundation strict signal totals; concrete multi-group and mixed runtime-ID queues; scalar/multi-beat read-data banks; depth-3 concrete/dynamic compositions; support/manifest accounting; inventory/disposition; Knowledge Map; mdBook; containment; staged acceptance; doctrines | `PASS — all 43 candidates closed as derived gates across eight evidence families; protocol 557/557 required-complete; current direct reports reproduce every published total; unchanged-product exact AXI baseline eb9e6a2d2 reports Files=2/Tests=121; support Files=2/Tests=7098; 1,523 governed constants; all registered doctrines` |
| `2026-08-21` | `.5.5` partition | committed-inventory Chapter 16c line aggregation; exact six-child sum; task integrity; docs paths; inventory/disposition/Knowledge Map/live-document/diff/staged-doctrine gates | `PASS — 6 + 37 + 34 + 71 + 62 + 22 = 232 across one disjoint chapter range; .5.5.1 selected alone; no claim, disposition, product, capability, or support behavior changes` |
| `2026-08-21` | `.5.5.1` | composite mode map; little-endian lane masks; in-word byte/halfword SEQ; byte-only INCR4/WRAP4 progression; exact-one/generalized BUSY bounds; generated/direct phase retention; inventory/disposition; Knowledge Map; mdBook; containment; staged acceptance; doctrines | `PASS — all six candidates closed as derived gates across four evidence families; IAL2 AHB 6/232; Files=9/Tests=35 exact focused run plus support Files=2/Tests=7098; 1,529 governed constants; all registered doctrines` |
| `2026-08-21` | `.5.5.2` | requester widths and bounded completion; exact-one-through-four qualified BUSY count/runtime; one-/two-window paired exact-one; exact-four paired artifacts; aliases; generalized invalid neighbors; current support accounting; inventory/disposition; Knowledge Map; mdBook; containment; staged acceptance; doctrines | `PASS — all 37 candidates closed as 17 gates / 20 reviewed; IAL2 AHB 43/232; Files=15/Tests=65 exact focused run plus support/disposition Files=3/Tests=7107; 1,566 governed constants; all registered doctrines` |
| `2026-08-21` | `.5.5.3` | two-window paired topology/runtime; parking/non-parking report separation; fixed-wrap progression; current alias truth; completion-edge phase recapture; subordinate storage/widths; inventory/disposition; Knowledge Map; mdBook; containment; staged acceptance; doctrines | `PASS — all 34 candidates closed as 7 gates / 27 reviewed; IAL2 AHB 77/232; Files=8/Tests=33 exact focused run, unchanged-product paired baseline Files=15/Tests=65, support/disposition Files=3/Tests=7107; 1,600 governed constants; all registered doctrines` |
| `2026-08-21` | `.5.5.4` | direct Q-named repair chronology; exact-three one-/two-window generic/profile surfaces; exact-four requester and one-window paired runtime; readiness/contract/shipment separation; inventory/disposition; Knowledge Map; mdBook; containment; staged acceptance; doctrines | `PASS — all 71 candidates closed as 6 gates / 65 reviewed; IAL2 AHB 148/232; Files=9/Tests=34 exact focused run plus support/disposition Files=3/Tests=7107; 1,671 governed constants; all registered doctrines` |
| `2026-08-21` | `.5.5.5` | exact-four one-/two-window generic/profile behavior; live support identity; generalized 2..16 admission, widths, runtime, malformed/adjacent invalid controls, and no-fixture rule; exact-one qualified-event repair; exact-two preservation; time-local accounting; inventory/disposition; Knowledge Map; mdBook; containment; staged acceptance; doctrines | `PASS — all 62 candidates closed as 15 gates / 47 reviewed; IAL2 AHB 210/232; Files=11/Tests=47 exact focused run plus support/disposition Files=3/Tests=7107; 1,733 governed constants; all registered doctrines` |
| `2026-08-21` | `.5.5.6` | generalized residue boundary; exact-three public runtime; aggregate HBURST generic/profile preservation; current-book truthfulness; generated boundary-free phase pipeline; direct Q-named capacity-one retention; support milestones and locator separation; inventory/disposition; Knowledge Map; mdBook; containment; staged acceptance; doctrines | `PASS — all 22 candidates closed as 4 gates / 18 reviewed; IAL2 AHB required-complete at 232/232 as 55 gates / 177 reviewed; Files=9/Tests=36 exact focused run plus support/disposition Files=3/Tests=7107; 1,755 governed constants; all registered doctrines` |

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
| `.5.4.1` | `CLAIM-VERIFICATION-ADOPTION.5.4.1: disposition AXI manager claims` | `Maps current concrete/dynamic AXI manager queue, ordering, validation, and output-bank statements to bounded executable evidence while preserving selector, readiness, helper-probe, and host-resource chronology as reviewed context.` |
| `.5.4.2` | `CLAIM-VERIFICATION-ADOPTION.5.4.2: disposition foundational APB claims` | `Maps current APB completer, multi-register, width/sideband, queued-timing, and composition statements to executable evidence while preserving status, register-shape, and byte-lane contract numerals as reviewed inputs.` |
| `.5.4.3` | `CLAIM-VERIFICATION-ADOPTION.5.4.3: disposition APB width timing claims` | `Maps current data16, protection, queued-sideband, adjacent-setup, and multi-peripheral timing statements to executable evidence while preserving readiness scopes, selected contracts, and superseded guards as reviewed chronology.` |
| `.5.4.4` | `CLAIM-VERIFICATION-ADOPTION.5.4.4: disposition APB composition claims` | `Maps current APB fixed/multi-peripheral multi-register, queued, protected, register/window, and report-residue statements to nine family-specific gates while preserving readiness, selector, and contract chronology as reviewed context.` |
| `.5.4.5` | `CLAIM-VERIFICATION-ADOPTION.5.4.5: disposition generalized APB claims` | `Maps current generalized APB width, stride, window, register-count, policy-matrix, artifact, and boundary statements to six family-specific gates while preserving section headings and readiness/selection chronology as reviewed context.` |
| `.5.4.6` | `CLAIM-VERIFICATION-ADOPTION.5.4.6: disposition expanded APB bounds` | `Maps the remaining data16/protected five-register and 16/32-bit no-policy six-register statements to five family-specific gates while preserving headings and readiness/selection chronology and retaining protected-six deferral.` |
| `.5.4.7` | `CLAIM-VERIFICATION-ADOPTION.5.4.7: disposition foundational AHB claims` | `Maps current interconnect, byte-lane alias, HBURST, and aggregate BUSY-park statements to five family-specific gates while preserving contract inputs, support milestones, and test/decision identifiers as reviewed chronology.` |
| `.5.4.8` | `CLAIM-VERIFICATION-ADOPTION.5.4.8: disposition AHB semantic BUSY claims` | `Maps current fixed-WRAP and exact-one/two/three requester/paired/alias statements to six family-specific gates while preserving audit failures, contract targets, support checkpoints, identifiers, and the superseded exact-three bound as reviewed chronology.` |
| `.5.4.9` | `CLAIM-VERIFICATION-ADOPTION.5.4.9: disposition AHB arbitration claims` | `Maps current one-window exact-three artifact/semantic and two-window assertion-enabled runtime statements to distinct gates while preserving arbitration audits, contract inputs, decision identifiers, projected totals, and shipment checkpoints as reviewed chronology.` |
| `.5.4.10` | `CLAIM-VERIFICATION-ADOPTION.5.4.10: disposition AHB exact-four claims` | `Maps current exact-four requester width/runtime, one-window paired artifact/runtime, and paired-alias parity statements to distinct gates while preserving disposable probes, the historical 2..4 contract, projections, checkpoints, and removed-workspace measurements as reviewed chronology.` |
| `.5.4.11` | `CLAIM-VERIFICATION-ADOPTION.5.4.11: disposition generalized AHB BUSY claims` | `Maps current two-window exact-four topology/runtime, alias parity, live support accounting, and generalized 2..16 range/runtime/no-fixture statements to distinct gates while preserving readiness, contract, projection, superseded 2..4 activation, shipment, and selector chronology.` |
| `.5.4.12` | `CLAIM-VERIFICATION-ADOPTION.5.4.12: disposition AHB integration claims` | `Maps the current Chapter 16c exact-one-through-four catalog versus generic 5..16 statement to existing executable evidence while preserving selectors, public-sync totals, diagram migrations, assertion expectations, and task-ledger censuses as exact chronology.` |
| `.5.4.13` | `CLAIM-VERIFICATION-ADOPTION.5.4.13: disposition extended AXI claims` | `Maps current mixed dynamic/static raw-ARLEN and three-/four-transaction multi-beat cardinalities to exact lowerer, fixture, report, FSM, and HDL evidence while preserving one-bit RLAST selector inputs as contract chronology.` |
| `.5.4.14` | `CLAIM-VERIFICATION-ADOPTION.5.4.14: disposition backend API claims` | `Maps current VHDL generic-map and typed-lowering, optional ABC validation, and MCP non-object behavior to four executable evidence families while preserving one-bit RLAST selector chronology as a reviewed structural reference.` |
| `.5.4.15` | `CLAIM-VERIFICATION-ADOPTION.5.4.15: disposition AXI example claims` | `Maps current AXI channel, single/fixed-four composition, catalog, and manager-family statements to 13 source-specific evidence families while preserving three shipment-time support snapshots as historical accounting.` |
| `.5.4.16` | `CLAIM-VERIFICATION-ADOPTION.5.4.16: disposition AXI manager reference claims` | `Maps all current Chapter 16aa census, foundation, concrete/mixed queue, read-data, and bounded-composition cardinalities to eight independently reproduced executable evidence families and closes protocol review at 557/557.` |
| `.5.5` | `CLAIM-VERIFICATION-ADOPTION.5.5: partition IAL2 AHB claim review` | `Activates six evidence-coherent Chapter 16c line-range children from the exact 232-candidate census without changing claims, dispositions, product behavior, capability, or support accounting.` |
| `.5.5.1` | `CLAIM-VERIFICATION-ADOPTION.5.5.1: disposition guided AHB claims` | `Maps the first six Chapter 16c mode-map, lane, in-word SEQ, and HBURST progression statements to four independently falsifiable current evidence families.` |
| `.5.5.2` | `CLAIM-VERIFICATION-ADOPTION.5.5.2: disposition requester AHB claims` | `Maps requester widths, bounded completion, exact-one-through-four qualified BUSY behavior, paired artifacts, and the live support boundary to count-specific gates while preserving test locators, proposed contracts, and shipment checkpoints as reviewed context.` |
| `.5.5.3` | `CLAIM-VERIFICATION-ADOPTION.5.5.3: disposition paired subordinate AHB claims` | `Maps current two-window paired topology/runtime, fixed-wrap progression, completion-edge recapture, and subordinate storage/width statements to distinct gates while preserving readiness, selection, shipment, locator, and pre-repair chronology.` |
| `.5.5.4` | `CLAIM-VERIFICATION-ADOPTION.5.5.4: disposition direct exact-count AHB claims` | `Maps current two-window exact-three topology/runtime, exact-four requester surfaces, and one-window exact-four paired runtime to distinct gates while preserving direct repair locators, readiness and contract inputs, disposable candidates, projections, and shipment checkpoints as chronology.` |
| `.5.5.5` | `CLAIM-VERIFICATION-ADOPTION.5.5.5: disposition generalized AHB claims` | `Maps current exact-four alias/two-window behavior, live support accounting, generalized 2..16 bounds/runtime, qualified-event repair, paired propagation, and exact-two preservation to distinct gates while preserving readiness, contract, projection, activation, unrelated-work checkpoint, and pre-repair chronology.` |
| `.5.5.6` | `CLAIM-VERIFICATION-ADOPTION.5.5.6: close IAL2 AHB claim review` | `Maps current generalized residue, exact-three runtime, generated boundary-free phases, and direct Q-named retention to distinct gates; preserves old support totals, contract/readiness values, superseded bounds, and test locators; closes Chapter 16c required-complete at 232/232.` |
