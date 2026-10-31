# MDBOOK-IAL-LAYER-FRAMING: Present the complete IAL0/IAL1/IAL2 product

## Metadata

- Tree ID: `MDBOOK-IAL-LAYER-FRAMING`
- Status: `active`
- Roadmap lane: `R13 / documentation; R14 / layered source authoring`
- Created: `2026-10-31`
- Last updated: `2026-10-31`
- Owner: repo-local workflow

## Goal

Apply the director-requested book-wide framing review. Readers must discover
IAL2 protocol/platform intent, IAL1 scheduled behavior and IAL0 explicit cycle
control from the introduction and choose an appropriate learning path. Keep
current profile/backend limits distinct from the full-chip objective.

This explicit request temporarily selects documentation ahead of saved
`ISF-REDUCTION-DELIVERY.3.4.3.3.3.5.4.2`; preserve that implementation frontier.

## Non-Goals

- No language, lowering, compiler, source corpus or capability changes.
- No unsupported protocol, VHDL parity or full-chip completeness claims.
- Do not mechanically replace valid IAL0 syntax with higher-layer vocabulary.
- Do not rewrite retained historical builds or immutable evidence.

## Acceptance Criteria

- Review all current book chapter openings, generic product descriptions,
  source/CLI examples, navigation, and the existing IAL1/IAL2 detailed guides.
- Repair global framing and label layer-specific instruction accurately, with
  direct links and runnable existing examples for each authoring entry point.
- Preserve the ordered IAL2 -> IAL1 -> IAL0 -> HDL contract and bounded support.
- Diagnose the quoted sentence against accessible source/builds; identify the
  actual reader URL when available without attributing it to a guessed build.
- Validate affected examples, rendered introduction/navigation and copied source
  freshness; update exact book aggregate authority and normal commit doctrines.
- Commit complete documentation and restore the saved required-delivery pointer.

## Task Tree

- ID: `MDBOOK-IAL-LAYER-FRAMING`
  Status: `active`
  Goal: `Align the full book's product framing and learning paths with all IAL layers.`
  Children: `MDBOOK-IAL-LAYER-FRAMING.1, MDBOOK-IAL-LAYER-FRAMING.2, MDBOOK-IAL-LAYER-FRAMING.3`

- ID: `MDBOOK-IAL-LAYER-FRAMING.1`
  Status: `done`
  Goal: `Review and repair IAL layer framing throughout the mdBook.`
  Acceptance: `Census all book chapters and generic product/source descriptions; read affected contexts and canonical layer contracts before edits. Update introduction, navigation, metadata and scoped chapter guidance where necessary, keeping dedicated IAL0 instruction and existing bounded IAL1/IAL2 contracts accurate. Qualify changed examples through public commands, build/rendered-source/navigation checks, exact maintained-reference aggregate authority and mandatory commit integrity. Preserve findings and the precise saved required-delivery frontier.`
  Verification: `At clean129a4fb3b the complete book-source framing census and canonical decisions0014/0015/0018 distinguish IAL2 protocol/platform intent, IAL1 scheduling and IAL0 explicit cycle control. Rewrite the opening around all source layers, add a source/intent/start-page map and runnable cross-layer checks, branch reader paths by authoring goal, label IAL0 teaching and IAL1 navigation/chapters, broaden CLI/diagnostic/integration/cookbook/reference guidance and book metadata, and correct the blueprint route from IAL2 backlog to current protocol guides. The included downstream reporting reference names all authored layers. Specialized IAL2, VIAL, implementation and historical/backlog semantics retain their scope; every existing Lisp example remains byte-identical. Actual HTTP https://rdje.github.io/fsmgen opening matches exact remote54ac1c22 Git source after removing Markdown inline-code delimiters. The first source predicate omitted those delimiters; corrected source/rendered comparison retains both. This establishes stale publication, not a guessed local build. New public checks for PPIF Valid-Ready, ISF phase_test and direct AHB FSM pass; documented I2C/PPIF schedule previews also pass with complete JSON/source identities. The initially proposed I2C full check fails with literal-emission refusal; preserve the complete first result, replace only the introductory example with the qualified small actor and own diagnosis .3 before publication .2. No source support, compiler or public API/MCP/corpus capability changes. Full census, first/final editorial epochs, complete initial/qualified command results and network intake retain under docs/audits/mdbook-ial-layer-framing-20261031/. Re-derive current chapter/source/example and HTTP/Git data; falsify the .fsm-only description against actual IAL1/IAL2 public commands and retain the real failed example; durability tracked book/metadata/task/receipts, canonical contracts and Git. The canonical inventory producer reissues the changed blueprint navigation candidate; retain the stale-disposition refusal and rejoin its current identity with the same reviewed incidental-navigation meaning. First normal hook refuses task_evidence file/line allowances; retain complete source/index/refusal in first-hook-task-allowance-refusal.json.gz and declare actual plus the existing file/line ratchet bands, with all baselines/ceilings unchanged. Exact book aggregate authority, final local rendered introduction/navigation, mdBook/POD/copied-source checks, fresh staged acceptance and every mandatory normal final-index doctrine gate commitment. Full local CI and exact-SHA hosted/Pages publication remain open under .2 and SEM .69.3; required implementation .3.4.3.3.3.5.4.2 remains saved.`
  Commit: `MDBOOK-IAL-LAYER-FRAMING.1: present all hardware intent layers throughout the book`


  Acceptance Checklist (enforced):
  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S 'FSMGen compiles Lisp-like' locatesee7cb1660 broadening the local opening, while actual published HTTP still matches remote54ac1c22. git log -S 'the .fsm language' locatesb8a083726: book metadata and early global reader guidance retained the original IAL0-only framing. Canonical contracts and source/HTML observations retain exact scope and revision.
  - [x] **ADDRESSED (verified)** — The book now presents IAL2/IAL1/IAL0 source choice and ordered lowering immediately, gives each layer a reader path, scopes direct-language chapters and shared CLI/API guidance, and routes IAL2 to current protocol guides. Complete original Lisp examples preserve; all newly selected public check/schedule commands pass. The real I2C full-check refusal remains separately owned before publication rather than hidden by the replacement example.
  - [x] **NO REGRESSION** — knowledge-map: OK; complete source-census and unchanged Lisp-example comparison pass. Public cross-layer command products are complete valid JSON with successful selected checks. Final mdBook test/build, rendered layer/navigation and copied-source verification, exact aggregate authority and every normal final-index doctrine gate this documentation slice. Full CI and hosted publication remain pending.

- ID: `MDBOOK-IAL-LAYER-FRAMING.2`
  Status: `pending`
  Goal: `Qualify and publish the updated book and accumulated commits, then verify hosted deployment.`
  Acceptance: `The director supplies https://rdje.github.io/fsmgen and flags the actual1206-commit upstream backlog. After .1 commits clean and .3 is dispositioned, follow existing SEMANTIC-INTROSPECTION-MCP-FRONTIER.69.3 and COMMIT.md publication ownership: required guarded full local CI, task-owned repair of exposed failures, a normal push without history rewriting, equal local/upstream/ls-remote full SHAs and every expected exact-SHA hosted workflow/job success. Verify GitHub Pages deployment/source revision and rendered introduction/navigation against the same committed book source. Preserve complete first failures and consume all required jobs. This request explicitly selects publication now ahead of saved private feature implementation; no full-CI or hosted success is inferred from focused checks.`
  Verification: `Director confirms GitHub Pages reader URL and requests overdue publication. Current source/default build differ from the quoted published sentence; actual remote content and current remote revision need network verification. Full local/hosted qualification remain open under the existing publication owners. Finish the book edit first, commit clean, then activate this leaf.`
  Commit: `pending`


- ID: `MDBOOK-IAL-LAYER-FRAMING.3`
  Status: `pending`
  Goal: `Diagnose the observed I2C full-check refusal and resolve any publication-blocking regression.`
  Acceptance: `After the documentation slice commits clean, use the Knowledge Map, public source/corpus contract and retained native failure to classify ./bin/fsmgen --quiet --strict --check --json isf/i2c_master.isf returning Direct literal emission requires current completed source intent. Determine actual supported scope and root mechanism before changing code. If a supported source regressed, own the smallest source/proof repair with focused original/current/adverse controls and synchronized book/task evidence before full CI/publication. Preserve first failure, guards and original dependency black-box boundaries. If the shape is intentionally outside current support, document the precise canonical boundary and retain the appropriate existing implementation owner rather than inventing successful generation.`
  Verification: `The proposed cross-layer introduction command fails status1 on isf/i2c_master.isf with a complete public JSON diagnostic; the preceding IAL2 check passes. Complete original example epoch retains in docs/audits/mdbook-ial-layer-framing-20261031/examples.json.gz. README currently demonstrates schedule preview for this file, which is a different operation. Full generation applicability and original-versus-current cause remain to be established; no production regression or intended-refusal classification is claimed yet. Finish .1 before this diagnosis; .2 publication depends on its disposition.`
  Commit: `pending`

## Decisions

- `2026-10-31`: Follow the explicit director request without abandoning required
  implementation. Explain entry-point choice and adjacent lowering from the first
  page, then scope specialized chapters rather than inserting labels everywhere.
- `2026-10-31`: The quoted old sentence is present in retained historical builds;
  source review alone cannot identify the particular copy the director reads.

## Open Questions

- Reader URL is https://rdje.github.io/fsmgen; publication is now explicitly
  selected after the source repair and full CI.

## Blockers

- None for the documentation review and source repair.
