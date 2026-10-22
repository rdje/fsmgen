# ISF-REDUCTION-DELIVERY: SPECFORGE scalar and grouped reductions

## Metadata

- Tree ID: `ISF-REDUCTION-DELIVERY`
- Status: `active`
- Roadmap lane: `R14 / ISF; R13 public semantic reports`
- Created: `2026-10-21`
- Last updated: `2026-10-22`
- Owner: repo-local workflow

## Goal

Implement and qualify the required R1–R3 of SPECFORGE FSMGEN-REQUESTS.12.
SEMANTIC-INTROSPECTION-MCP-FRONTIER `.92` retains request coordination and
publication ownership. Decision `0117` selects the contract. This bounded
implementation tree avoids growing the near-rollover coordination task file.

## Non-Goals

- This tree does not close durations, named timers or record-output delivery.
- Optional inversion has separate ownership and cannot delay required delivery.
- No sibling repository, submodule pin or caller integration is changed here.

## Acceptance Criteria

- Every required request clause has source, IAL0, HDL and public-report evidence.
- Preserve accepted binary expressions and existing logical negation.
- Keep authored dependencies distinct from resolved defaults; prove actual HDL
  width and group behavior under parameter overrides and short final groups.
- Each completed source slice has corpus and native/API/MCP coverage, focused
  checks, independent semantics, synchronized book and feedback, and its own commit.
- Full CI and exact-SHA hosted results qualify publication under SEM `.69`.
- Task integrity and all required doctrines pass without relaxed safety limits.

## Task Tree

- ID: `ISF-REDUCTION-DELIVERY`
  Status: `active`
  Goal: `Deliver required unary and parameter-correct grouped reductions.`
  Children: `ISF-REDUCTION-DELIVERY.1, ISF-REDUCTION-DELIVERY.2, ISF-REDUCTION-DELIVERY.3, ISF-REDUCTION-DELIVERY.4, ISF-REDUCTION-DELIVERY.5, ISF-REDUCTION-DELIVERY.6, ISF-REDUCTION-DELIVERY.7, ISF-REDUCTION-DELIVERY.8`

- ID: `ISF-REDUCTION-DELIVERY.1`
  Status: `active`
  Goal: `Implement and qualify unary XOR, AND and OR reductions end to end.`
  Acceptance: `Before source edits, inspect the shared recursive expression parser, declared signal/type resolution, AST and every relevant width consumer, ISF scalar validation, IAL0 replay, HDL emitter profiles and normalized reports. Add arity-dependent unary semantics without changing multi-operand behavior. Reject undeclared, aggregate, non-vector or malformed operands contextually. Prove result width in direct and nested expressions, scalar/slice/index truth tables, retained caller parity inputs and unchanged binary/unrolled controls. Qualify supported HDL profiles with actual compilation/runtime through published tools; retain first failures under the HIAL failure-only prerequisite. Add a runnable supported corpus case, named detached report inventory and complete native/API/real MCP/capability parity. Update ISF reference/book/feedback and focused checks; split any unsafe expansion before implementation. Commit before generic-width work.`
  Verification: `Width groundwork and declared source integration are implemented; sampling/formal compatibility repairs qualify their bounded source slices. Broader source/profile/corpus signoff and external HDL runtime remain open; historical initial refusal remains retained by SEM .91.`
  Commit: `children below`
  Children: `ISF-REDUCTION-DELIVERY.1.1, ISF-REDUCTION-DELIVERY.1.2, ISF-REDUCTION-DELIVERY.1.3, ISF-REDUCTION-DELIVERY.1.4`

- ID: `ISF-REDUCTION-DELIVERY.1.1`
  Status: `done`
  Goal: `Prepare exact unary reduction widths and distinct intermediate identities without new source admission.`
  Acceptance: `Inspect shared expression width propagation, Core/runtime/substituted AST naming, direct intermediate widths and enable-graph width classification. Qualify unary ^/&/| as one-bit results independent of operand width, nested concatenation/comparison use and distinct readable intermediate identities; assignment-context width propagation must not resize a reduction operand. Preserve binary vector, logical negation, inversion and ordinary operand-propagation behavior. Add a meaningful RED-to-GREEN regression across the real independent consumers with adversarial vector-width and collision controls. Shared source parsing must still refuse unary reductions in this preparatory commit. Run focused expression/AST/backend-generation checks without external HDL execution, update decision/book/feedback and preserve actual test evidence. Runtime, source/corpus/public inventories remain explicitly pending under successors; commit before admission changes.`
  Verification: `Actual original RED and corrected native-predecessor RED fail four top-level subtests; the corrected current regression passes. The initial post-repair failure identifies an oracle error: runtime literals have their own stored definition, so the test now compares only all distinct reduction definitions and uses legal signal names. All current exact/Core/runtime/substituted/intermediate/enable widths and nested concatenations/comparisons are scalar where required; destination propagation cannot resize operands. Binary vectors, logical negation, inversion and ordinary propagation retain controls. Guarded focused All tests successful Files=7 Tests=21; fresh native --strict --check --json accepts the exact caller baseline and retains both unary arity refusals. Complete normalized logs, original test, corrected native capsule recipe/identities, current source hashes and typed outcomes are retained in docs/audits/unary-reduction-width-foundation-20261021.json. Re-derivation is current production-consumer regression and native supplied checks; falsification is the same corrected assertions against exact predecessor modules plus vector/identity/propagation controls; durability is tracked source/test/audit and this commit. No new source admission, public inventory, external HDL execution or R1/R2/R3 delivery claim. Book/task checks separately pass All tests successful Files=3 Tests=356, mdBook build and complete source/index contracts pass; native decision/Knowledge Map/task/claim checks pass. The final expanded comparison regression also fails against native predecessor modules and passes the complete current focused suite. Staged/normal gates precede commit.`
  Commit: `ISF-REDUCTION-DELIVERY.1.1: preserve scalar reduction widths and identities`

  Acceptance Checklist (enforced):
  - [x] **ROOT CAUSE (WHY + WHERE)** — Perl diagnostics from T2074 RED locate operand-width leakage in ExpressionBuilder/ExpressionNamer/direct intermediate inference, absent enable-graph reduction width, generated-name collisions and destination propagation. Fresh --strict --check --json still shows the independent arity refusal.
  - [x] **ADDRESSED (verified)** — Corrected assertions fail against exact native predecessor modules and pass against the repair; actual nested widths, complete distinct definition identities and operand-preservation controls qualify. Source grammar and public admission are unchanged. Complete logs and source identities remain in the dated width-foundation audit.
  - [x] **NO REGRESSION** — Guarded expression/naming/AST/intermediate/VHDL-text checks report All tests successful, Files=7, Tests=21; fresh supplied native baseline passes and unary forms retain their refusal. Book/task All tests successful Files=3 Tests=356, mdBook build, complete source/index, native decision/task and knowledge-map: OK pass. scripts/check_doctrines.sh plus normal hooks gate the commit. No external HDL runtime is inferred.

- ID: `ISF-REDUCTION-DELIVERY.1.2`
  Status: `active`
  Goal: `Admit unary reductions through declared scalar validation, IAL0 and detached public reports.`
  Acceptance: `After .1, qualify source/arity/type/path/scope validation, direct/nested reduction assignment widths, source/carrier parity and default retained caller parity. Add the detached reductions inventory through native check/semantic/schedule, API and actual newline MCP, with capability and source/version/query applicability, supported corpus admission and independent report/semantic controls. Preserve binary and logical behavior. Generate HDL for supported profiles without borrowing runtime proof. Commit any growing preparatory slice with its exact missing qualification boundary; do not close the required unary feature before .4.`
  Verification: `Width foundation and declared source/report integration are done. Broader source qualification remains in .1.2.3; this does not close unary runtime or required R1-R3 delivery.`
  Commit: `children below`
  Children: `ISF-REDUCTION-DELIVERY.1.2.1, ISF-REDUCTION-DELIVERY.1.2.2, ISF-REDUCTION-DELIVERY.1.2.3`

- ID: `ISF-REDUCTION-DELIVERY.1.2.1`
  Status: `done`
  Goal: `Prepare detached declared-vector reduction records before source admission.`
  Acceptance: `Use actual parsed actors, existing record declaration/path/sample scope helpers and the selected unary contract to prepare one private expression reduction inventory/snapshot producer from explicitly selected expression payloads; source-context selection/integration stays in .2. Validate declared packed scalar signals, legal slices/indices/fields and supported local/sample scopes; reject aggregate roots, unresolved/unknown/constant/parameter/string/expression operands contextually. Keep operand widths and authored tokens distinct; omit lost authored parameter dependencies instead of guessing. Define deterministic owner/context order and strict detached JSON-safe snapshots; preserve caller bytes/kinds and reject malformed fields. Bind owner/operand/layout against independent actual-source expectations; snapshots alone do not attest provenance. Qualify real parsed packet and scope/layout controls, aliases, wrong types/paths/widths and meaningful snapshot mutations. Do not integrate the producer, advertise support or change grammar/report products yet. Record remaining integration/runtime boundaries, focused checks, book/decision/feedback and commit.`
  Verification: `Actual parsed caller rules, nested aliases, scalar record paths, literal local/sample and named-drive scopes produce independently expected owner/token/width records while preserving complete caller JSON kinds. Unknown/constant/parameter/string/expression/aggregate/path operands refuse; untyped drive formals cannot borrow actor widths. Snapshot shape/member/kind/operator/owner/result/Boolean controls and mutation isolation qualify. First actual T2075 exposes a P1 draft false green: failed list-context regex drops its predicate and an unguarded one-argument helper accepts owner_kind external. Independent Perl reproduction proves one argument before and two after scalarization. Both identity predicates now force scalar context and the helper enforces exact arity, following decision 0113; decision 0114 owns detach-before-read. Genuine invalid owner strings and dropped-predicate controls reject. All initial source/test/log and corrected evidence retain in docs/audits/reduction-record-preparation-20261022.json. Guarded focused All tests successful Files=4 Tests=29. Re-derivation uses actual parsed packets and declaration/path/sample producers; falsification is independent literal records plus hostile scope/schema mutations and the first false green; durability is tracked helper/tests/audit/decision and Git. Source-context selection, provenance binding, integration/public inventories/admission and HDL behavior remain explicitly missing under successors. Book/task All tests successful Files=3 Tests=356, mdBook build and complete source/index contracts pass; native decision/task/Knowledge Map and complete claim checks pass. First staged doctrine exits 1 because the slice next_action pointer grows to warning pressure while active_resume remains declared normal. Complete failed log/index/pointer retain in reduction-record-preparation-gate-refusal-20261022.json.gz. Shortening only that redundant pointer preserves all detailed task contracts and leaves every budget unchanged; staged/normal checks repeat before commit.`
  Commit: `ISF-REDUCTION-DELIVERY.1.2.1: prepare detached declared-vector reduction records`

  Acceptance Checklist (enforced):
  - [x] **ROOT CAUSE (WHY + WHERE)** — Perl diagnostic at t/2075-isf-reduction-record-preparation.t line 30 retains the draft invalid-owner false green. The independent probe shows list-context regex failure drops the predicate; the initial _require lacks an arity guard. Existing --strict --check --json refusal remains separate from this private producer preparation.
  - [x] **ADDRESSED (verified)** — Real parsed caller and independently expected declaration/path/local/sample/drive records pass. Scalar identity predicates and exact helper arity reject invalid owner strings and dropped predicates. Genuine malformed kind/operator/result/member/Boolean fields and nonvector/path/scope controls refuse; caller/result mutation isolation holds. Initial draft and complete focused evidence retain in the dated audit; no integration or source-admission claim.
  - [x] **NO REGRESSION** — Guarded producer, width and existing value/declaration checks report All tests successful, Files=4, Tests=29. Book/task All tests successful Files=3 Tests=356, mdBook build and complete source/index contracts pass. Native decision/task/Knowledge Map and complete claims pass; scripts/check_doctrines.sh plus normal hooks gate this private preparation commit. Public/native/corpus/HDL qualification remains owned by successors.

- ID: `ISF-REDUCTION-DELIVERY.1.2.2`
  Status: `done`
  Goal: `Integrate unary source admission and detached reports through canonical IAL0.`
  Acceptance: `After .1, integrate declared source validation and inventory with shared unary parsing, exact nested assignment width handling, preserved operand bounds and existing ISF scalar/count/binding contexts that already admit bitwise expressions. Thread detached inventories through schedule/check/semantic, public capability contracts and API/MCP; no failed/unrelated report inventions. Add supported corpus and explicit profile/semantic boundary controls. Keep alias/binary/logical semantics and exact caller baseline, verify original/generated carriers and unsupported operands. Split growing work before edits; runtime stays owned by .1.3/.1.4.`
  Verification: `Supplied fixed slices strict-check with independently expected operand widths and one-bit results. Actual fixture native/API/newline check, semantic and schedule products match completely; generated IAL0 strictly replays without invented ISF source ownership. Static parameter masking settles the observed schedule/check namespace collision; explicit private sample declarations settle the same-token capture/read failure. Canonical/Core/runtime/substituted/enable serializers preserve operand grouping; the actual CaptureSupport trace identifies the previously missed executed renderer. The reduction scalar-predicate repair preserves negated source polarity and bounded VHDL folds. Native compound-symbol/alias operands refuse in ordinary and strict checks. First discovery fallback, incomplete test contexts, literal spelling and probe-exit mistakes are retained as oracle repairs, not product qualification. Current guarded qualification: All tests successful Files=10 Tests=136; broader pre-predicate epoch Files=11 Tests=200 is separately dated and not relabeled as current execution. Actual extracted book example agrees with independent records and the book builds. Complete normalized epochs and final source identities retain in docs/audits/unary-reduction-source-integration-20261022.json.gz. Re-derivation uses authored declarations and actual source/carriers; falsification uses independent literal records, hostile scopes/paths, first failures and polarity/grouping controls; durability is tracked fixtures/tests/audit/decision and Git. Raw absolute-root stream bytes are not reconstructed. Broader source/profile/corpus qualification, external HDL execution, generic groups and publication remain open under successors; P2 complement classification is .7.1. The first doc gate exposes a pending container .7; active container status owns its scheduled child without claiming inversion implementation. Corrected book/task checks pass All tests successful Files=3 Tests=356; First staged doctrines refuse the inherited isf_reference aggregate authority; the complete failed index/patch/log is retained in docs/audits/unary-reduction-source-gate-refusal-20261022.json.gz. Refresh only the measured current aggregate identity/baseline/delta, without per-part or enforcement allowance growth; corrected staged doctrines and normal hooks precede commit.`
  Commit: `ISF-REDUCTION-DELIVERY.1.2.2: admit unary reductions and detached source reports`
  Children: `ISF-REDUCTION-DELIVERY.1.2.2.1`

  Acceptance Checklist (enforced):
  - [x] **ROOT CAUSE (WHY + WHERE)** — Actual --strict --check --json products bind the original unary arity boundary, the schedule/check static-name collision and the undeclared sample carrier. The real trace at perl/FSM/Synthesis/EnableGraph/ASTSupport.pm line 1057 identifies the executed bare-unary serializer; the real-owner census and negated-source failure bind the missing scalar predicate to that pipeline. Complete first sources, streams and oracle repairs remain in the dated integration audit.
  - [x] **ADDRESSED (verified)** — Declared unary source now reaches canonical IAL0 and detached schedule/check/semantic records. Independent literal rows agree across complete native/API/newline products; caller kinds and actual carrier replay hold. Static values cannot borrow same-named wire declarations; scalar sample aliases retain known private declarations. Operand grouping and one-bit classification preserve actual positive/negated generation and reject hostile source/wrapper paths. No failed/unrelated source inventories, full R1/runtime claim or optional inversion admission; P2 complement ownership remains .7.1.
  - [x] **NO REGRESSION** — Current guarded source/public/backend checks report All tests successful, Files=10, Tests=136; corrected book/task checks report All tests successful, Files=3, Tests=356. The separately retained pre-predicate broader epoch passes Files=11 Tests=200. Actual extracted book source and native strict SystemVerilog generation pass; VHDL evidence is generation only. scripts/check_doctrines.sh and normal hooks gate this exact source integration commit; broader corpus/profile and HDL execution remain successors.

- ID: `ISF-REDUCTION-DELIVERY.1.2.2.1`
  Status: `done`
  Goal: `Preserve one-bit reduction classification in the executed negation renderer.`
  Acceptance: `Before parent integration signoff, retain the generated fixture showing odd_parity_next as a redundant (~|(^data)); independently compare exact expression width with _operand_is_single_bit through real renderer owners for Core/runtime/substituted XOR/AND/OR. Capture the original mismatch before repair. Apply the existing shared reduction-operator classification to this missing scalar predicate, preserving other unary and logical/binary controls. Scalar complement classification has separate P2 ownership under .7.1; do not expand optional inversion or its backend surface here. Qualify actual negated source generation and bounded VHDL folds plus focused/current preservation checks. Close with the parent source integration commit; no runtime or R1-complete promotion.`
  Verification: `The corrected unchanged real-owner probe exits 1 before and 0 after the narrow repair: every Core/runtime/substituted reduction changes from exact width 1 with false scalar predicate to consistent one-bit classification. Its first exit-expression precedence bug is retained separately. Native generated odd parity changes from redundant compound NOR to logical negation of XOR; the unchanged current reduction assertions and real positive/negated VHDL source checks pass. Current parent focused qualification passes Files=10 Tests=136. Non-reduction unary behavior remains unchanged. The RED capsule preserves the independent one-bit complement failure under scheduled .7.1; no complete R1, runtime or optional inversion promotion.`
  Commit: `ISF-REDUCTION-DELIVERY.1.2.2: admit unary reductions and detached source reports`

- ID: `ISF-REDUCTION-DELIVERY.1.2.3`
  Status: `active`
  Goal: `Qualify complete unary source/public/corpus coverage before the fixed HDL witness.`
  Acceptance: `After .2, independently compare complete native/API/actual newline MCP check/semantic/schedule products, semantic widths, source/version/query applicability, corpus discovery and precise invalid source/profile controls. Re-derive retained baseline and scalar/slice/bit/field/local/sample cases including nested results and original IAL0 carriers. Cover legal owner labels, canonical compound/bounds controls, static/package namespaces, ordinary sample ownership and same-LHS capture identity before signoff. Update exact capability/reference/book/feedback contracts, pass focused gates and commit. This closes source/public qualification only; actual HDL behavior and R1 delivery require .1.3/.1.4.`
  Verification: `Next frontier after integrated source admission; complete source/profile/corpus signoff and runtime remain open.`
  Commit: `pending`
  Children: `ISF-REDUCTION-DELIVERY.1.2.3.1, ISF-REDUCTION-DELIVERY.1.2.3.2, ISF-REDUCTION-DELIVERY.1.2.3.3`

- ID: `ISF-REDUCTION-DELIVERY.1.2.3.1`
  Status: `active`
  Goal: `Qualify declared scalar field, local and sample operand scopes through real source and carriers.`
  Acceptance: `Read the canonical record/sample contracts and preserve existing record-port whole-aggregate sample/root refusals and storage-only sampling delegation. Independently qualify scalar record/storage fields, bounded paths, signed/state-preserving leaf samples and sample chains, local scopes, shadowing/static namespaces and legal owner labels. Use actual ISF and canonical source checks, generated IAL0 and detached inventories; no hand-built scope alone certifies admission. Retain first failures before repair and split any growing defect before edits. Prove profile/type boundaries touched by any repair; update book/reference/capabilities only for actual behavior. Focused checks and a source-scoped commit close this leaf before capture/corpus successors; no HDL execution or full R1 claim.`
  Verification: `Starting from clean 21843f970. The published record-input contract admits scalar-leaf samples, preserves signed/state traits and refuses whole-record sampling; do not invent broader sampling as part of reductions.`
  Commit: `pending`
  Children: `ISF-REDUCTION-DELIVERY.1.2.3.1.1, ISF-REDUCTION-DELIVERY.1.2.3.1.2`

- ID: `ISF-REDUCTION-DELIVERY.1.2.3.1.1`
  Status: `done`
  Goal: `Repair the P1 regression that applies record-port sample restrictions to delegated storage samples when reductions occur.`
  Acceptance: `Preserve the valid actual whole-storage sample baseline and otherwise equivalent unrelated scalar-reduction case before edits. Bind the observed ordinary/strict/schedule failure to the reduction hook's default sample plan, using the existing port-only contract and packed-storage inference owner. Preserve reduction-required scalar sample declarations while leaving unrelated delegated sample declarations/types unchanged. Compare actual baseline/repaired carriers and strict replay, metadata, caller kinds and supported source/API products; retain record-port whole-sample/root refusals and existing storage-path/width negatives. Capture any subsequent carrier failure before repair. Add a permanent independent regression, synchronize scoped contracts/book/facts and run focused checks; commit this repair before remaining operand qualification. No runtime, aggregate-layout invention or optional inversion admission.`
  Verification: `First complete 24-observation scope probe under .artifacts/logs/reduction-scopes-first-20261022.jsonl: direct record fields and record-leaf chains pass; implicit widening and storage-field captures retain existing failures. Whole-storage baseline passes ordinary/strict/schedule with statuses 0/0/0; adding (^ bus) over unrelated declared eight-bit input gives 1/1/255. First diagnostic is Invalid ISF record value: transaction main sample requires a scalar value; packet is a whole record. ADR 0114 explicitly delegates storage-only aggregate samples under port_only. The reduction capture calls record_transaction_samples without that selection; preserve the complete first source/streams before touching it. The unchanged same-actor T2077 regression is RED at actual parsing, and the read-only executed hook trace prints port_only absent before the failure at ISFReductions.pm line 32. The first port-only repair restores parsing and strict replay but the unchanged T2077 fails carrier equality: the unrelated q gains internal and +size entries. That complete second RED and port-selection source are retained. The emitter now follows whole-storage sample ancestry in actual capture order and leaves those aliases with the legacy owner; scalar sample declarations remain. Unresolved/delegated facts mask the reduction scope instead of being re-read through record-port validation. The unchanged original RED test now passes All tests successful Files=1 Tests=2. Expanded chain/carrier/native/API/newline coverage and existing unary/record facts, contexts, carriers, ownership and replay pass All tests successful Files=9 Tests=44. Fresh widening and storage-field sample observations preserve all original ordinary/strict/schedule statuses. Book/task checks pass Files=3 Tests=356; the book builds and complete source/index contracts pass. Complete normalized source epochs, first streams, executed trace, intermediate carrier RED and settled repair logs retain in docs/audits/reduction-delegated-storage-sampling-20261022.json.gz. Re-derivation uses real paired ISF and actual carriers/reports; falsification is exact one-RHS baseline comparison, original parser RED, intermediate carrier RED and existing negative controls; durability is tracked source/test/audit/decision and Git. Original raw-root stream byte reconstruction and whole original worktree capture are explicitly missing. No external HDL execution or complete R1 claim. Staged doctrines and normal hooks gate commit.`
  Commit: `ISF-REDUCTION-DELIVERY.1.2.3.1.1: preserve delegated sample ownership`


  Acceptance Checklist (enforced):
  - [x] **ROOT CAUSE (WHY + WHERE)** — Actual --check --json baseline/reduction products and the executed hook trace bind the scalar-only sample refusal to ISFReductions.pm calling record_transaction_samples without port_only. The unchanged test then locates a second RED at t/2077-isf-reduction-delegated-samples.t line 61: Emitter/FSM.pm adds unrelated internal and +size declarations. Complete first sources and streams retain in the dated audit.
  - [x] **ADDRESSED (verified)** — The existing port-only plan preserves delegation and unresolved masks. Actual capture ancestry leaves whole-storage aliases/chains with their legacy inference owner while known scalar sample declarations remain. The unchanged original RED test passes; expanded exact-carrier and strict replay assertions, independent inventory and complete native/API/newline equality pass without broadening aggregate reduction or record-port sampling.
  - [x] **NO REGRESSION** — Guarded unary/record sample facts, contexts, carriers, ownership and replay report All tests successful, Files=9 Tests=44. Fresh existing widening/storage-field observations match original ordinary/strict/schedule statuses. Book/task checks report All tests successful, Files=3 Tests=356; mdBook build and complete source/index checks pass. scripts/check_doctrines.sh and normal hooks gate this repair; external HDL runtime and full required delivery remain successors.

- ID: `ISF-REDUCTION-DELIVERY.1.2.3.1.2`
  Status: `active`
  Goal: `Complete remaining declared operand-scope qualification after delegated sampling repair.`
  Acceptance: `After .1, independently qualify actual field/local/formal and scalar-sample scopes, signed/state-preserving leaf chains, static namespace and owner-label boundaries, native canonical path/compound refusals and caller isolation. Preserve the existing distinction between record-port sampling restrictions and delegated storage behavior. Split newly reproduced defects before edits and commit the complete scoped source/carrier coverage before capture identity and corpus/profile successors.`
  Verification: `Starting from clean 3fa3e868c. Canonical formal-scope cards and actual record sample carrier/semantic tests are reviewed. First actual-source probe covers direct scalar record/storage fields, signed leaf sample chains, local slices, nearest formal widths, untyped named-drive masks, and controlled owner-label baselines before any source repair. Initial native check streams are retained at .artifacts/logs/reduction-operand-scopes-first-20261022.jsonl: field/storage/leaf-chain/local positives pass; untyped drive and non-HDL owner labels refuse. The input-formal write fails at the existing record context gate before reduction capture. Controlled record/non-record and read-only comparisons are running before classifying it; no complete unary delivery is claimed.`
  Commit: `children below`
  Children: `ISF-REDUCTION-DELIVERY.1.2.3.1.2.1, ISF-REDUCTION-DELIVERY.1.2.3.1.2.2`

- ID: `ISF-REDUCTION-DELIVERY.1.2.3.1.2.1`
  Status: `done`
  Goal: `P1: preserve admitted unary reductions through formal operand rewriting.`
  Acceptance: `First actual read-only formal source with a record port, and the no-record mutable-formal reduction source, both refuse Formal operand expression has invalid arity for ^. Bind that failure to the executed FormalOperandResolver family/arity gate before edits. Reuse canonical operator normalization and shared unary reduction classification without changing binary/n-ary, logical, property or binding roles. Add an unchanged RED-to-GREEN regression for all canonical and normalized unary forms, nested use, actual distinct physical formal identities, exact authored metadata widths and caller isolation. Qualify real source/generated carriers/native/API/newline products and existing resolver/width/source controls without external HDL execution. Retain first sources/streams, synchronize decision/book/feedback, pass focused and staged gates, then commit before remaining scope qualification.`
  Verification: `Complete first census and four formal controls retain in .artifacts/logs/reduction-operand-scopes-first-20261022.jsonl and reduction-formal-controls-first-20261022.jsonl. Read-only record/formal and no-record reduction cases both fail the same formal arity boundary; no-record non-reduction baseline passes. FormalOperandResolver.pm lines 71-73 still requires n-ary operands >=2, while canonical ExpressionBuilder admits unary ^/&/|. The direct actual Scheduler lower trace reaches FormalOperandResolver.pm line 73 via FormalClauseResolver.pm line 112 and FormalLowering.pm line 39. T2078 fails the detached rewrite and both real production variants; corrected immediate nested-error capture preserves the same RED oracle before edits. Complete source and both RED logs are retained before repair. Shared reduction classification admits the canonical and normalized unary forms without changing other arities/roles. The first arity-only repair then exposes the independently expected authored-provenance RED owned by the child. Both repairs now pass guarded All tests successful Files=7 Tests=386 across operand/clause resolution, existing formal/domain source reports, unary widths/records/public products and T2078. Exact retained native controls: with_record_baseline=1, with_record_readonly_reduction=0, without_record_baseline=0, without_record_reduction=0; P2 .8 remains distinct. Whole actual IR/source/preparation snapshots and deliberate view mutation prove report isolation. Complete normalized source epochs, first traces/streams and final identities retain in docs/audits/reduction-formal-source-preservation-20261022.json.gz. Re-derivation uses actual source/carriers and independent literal records/widths; falsification is original/corrected arity RED, intermediate provenance RED, outer/formal/slice controls and deliberate view mutation; durability is tracked source/test/audit/decision/card and Git. Raw-root byte reconstruction and whole original worktree capture remain explicit gaps. No external HDL execution or full required delivery claim. First staged doctrines refuse focused_documents aggregate line-growth debt:203444 exceeds baseline199211 plus4228. Complete failed log, binary staged patch and full index retain in docs/audits/reduction-formal-source-gate-refusal-20261022.json.gz. Apply the existing policy measurement plus100-line ratchet only to the short warning-debt dimension, giving4333; no baseline, ceiling, health target or per-file allowance changes and no fact deletion. Corrected staged doctrines and normal hooks gate commit.`
  Commit: `ISF-REDUCTION-DELIVERY.1.2.3.1.2.1: preserve unary formal expressions and source reports`
  Children: `ISF-REDUCTION-DELIVERY.1.2.3.1.2.1.1`


  Acceptance Checklist (enforced):
  - [x] **ROOT CAUSE (WHY + WHERE)** — Actual --check --json controls and the executed Scheduler trace identify FormalOperandResolver.pm line 73: the family-only gate rejects admitted unary reductions. After arity repair, unchanged T2078 independently locates the second RED in actual schedule metadata: LoweringIR captures physical operands and FormalLowering report_ir omits their authored restoration. First sources/streams and complete errors retain in the dated audit.
  - [x] **ADDRESSED (verified)** — Shared normalization/classification preserves all canonical/alias unary forms, nested use and distinct formal widths. The detached report view re-derives authored reductions from its selected original preparation; executable IR remains physical. Actual source/carrier/native/API/newline checks agree with independent literal records and original widths. Whole IR/source/preparation snapshots remain equal after report construction and deliberate view mutation. The existing input-formal write defect .8 stays scheduled and documented.
  - [x] **NO REGRESSION** — Guarded operand/clause resolvers, existing formal/domain report controls, reduction widths/records/public products and actual formal regression report All tests successful, Files=7 Tests=386. Retained native controls confirm both reduction repairs and the distinct existing write refusal. Book/task checks report All tests successful, Files=3 Tests=356. mdBook build/source-index gates and scripts/check_doctrines.sh plus normal hooks gate this source repair; external HDL runtime and complete R1-R3 publication remain successors.

- ID: `ISF-REDUCTION-DELIVERY.1.2.3.1.2.1.1`
  Status: `done`
  Goal: `P1: restore authored reduction operands only in detached formal schedule reports.`
  Acceptance: `The unchanged T2078 after arity repair reaches both real carriers and strict replay but its independently expected source inventory is RED: schedule operands are isf_port_main_bus rather than bus, including slice suffixes. Preserve that first intermediate source/test/log epoch before edits. Bind the generated spelling to LoweringIR re-capturing physical expressions and FormalLowering report_ir omitting the new inventory from its existing source restoration. Re-derive the inventory from the selected original preparation actor in the detached report view; never mutate executable IR or reverse-map guessed names. Prove complete authored records, native/API/newline schedule equality, original caller/report isolation, unchanged physical carrier identities and existing formal/domain report controls. Commit with the parent integrated arity slice only after both defects qualify.`
  Verification: `First repaired epoch passes actual lowering and strict replay for ordinary and record-readonly actors. Both source inventory comparisons show the exact generated operand in the actual schedule; the literal expected authored bus remains unchanged. All rows retain the correct formal width. Existing canonical formal-scope record explicitly keeps source provenance and executable physical identities separate; complete first report RED is retained before repair. A fresh native report-isolation probe now verifies complete executable IR, original actor and preparation actor equality after report construction and deliberate report-record mutation; executable operand remains isf_port_main_bus while report operand is bus. Full snapshots are retained in .artifacts/logs/reduction-formal-report-isolation-20261022.json. Focused source/formal/domain regression passes All tests successful Files=7 Tests=386; actual native/API/newline schedule records now preserve the independently expected authored bus and slice spellings. The dated source-preservation audit retains all complete snapshots, traces, sources and both RED stages; no external HDL execution is claimed.`
  Commit: `ISF-REDUCTION-DELIVERY.1.2.3.1.2.1: preserve unary formal expressions and source reports`

- ID: `ISF-REDUCTION-DELIVERY.1.2.3.1.2.2`
  Status: `active`
  Goal: `Complete remaining operand scopes after formal reduction rewriting repair.`
  Acceptance: `Qualify the parent field/storage/local/formal/scalar-sample, signed/state, static mask, legal owner and canonical path/compound contracts against actual sources and carriers. Preserve all initial failures, distinguish the separately owned existing mixed-record/private-formal write defect .8, and do not claim R1/runtime/group delivery from source qualification. Commit before capture identity and corpus/profile successors.`
  Verification: `Formal arity and authored report preservation are committed at the preceding checkpoint; next complete the remaining declared operand scope cohort.`
  Commit: `pending`

- ID: `ISF-REDUCTION-DELIVERY.1.2.3.2`
  Status: `pending`
  Goal: `Qualify reduction capture identity and nested type/width propagation in the executed pipeline.`
  Acceptance: `After scoped operands, bind actual generated/semantic RHS values and enables for all reduction operators, logical negation, nested scalar uses and ordinary source controls, including same-LHS assignments and legal names resembling generated RHS labels. Preserve original binary/unrolled behavior and independent expected widths/polarities; do not infer identity from pretty names or snapshots alone. Own any reproduced collision or type defect before repair, qualify source/native/API/carrier parity, synchronize durable boundaries and commit. Actual HDL runtime remains the separately committed fixed witness.`
  Verification: `pending scoped operand qualification`
  Commit: `pending`

- ID: `ISF-REDUCTION-DELIVERY.1.2.3.3`
  Status: `pending`
  Goal: `Close unary public discovery, corpus applicability and explicit backend-profile qualification.`
  Acceptance: `After .1/.2, qualify complete native/API/actual newline success/failure products, source/version/query identity, complete corpus discovery and declaration expectations, and supported or precisely refused generation profiles with applicable output preservation. Exercise retained caller baseline, source fixture and all repaired contexts. Preserve every first failure; metadata/generation does not establish runtime. Synchronize exact discovery/reference/book/feedback contracts, run focused and warranted preservation checks, then commit and close parent .1.2.3 only on complete source/public/corpus signoff. Next is the fixed HDL witness and observer admission under .1.3.`
  Verification: `pending scoped operands and capture qualification`
  Commit: `pending`

- ID: `ISF-REDUCTION-DELIVERY.1.3`
  Status: `pending`
  Goal: `Commit the exact unary HDL witness and qualify its failure-only observer admission.`
  Acceptance: `Coordinate the existing HIAL .19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.10.11.7 for this director-prioritized genuinely needed witness. Before supervised HDL execution, commit exact tests/source/bench, fixed targets/profile/count and complete independent truth-table oracle. Separately qualify any changed observer identity/coverage using immutable native/failure-only helpers, original arguments/limits/results/errno and independent cleanup. No spent original/reused admission or recurrence campaign, host-policy change or authentication request.`
  Verification: `pending authored source and fixed witness`
  Commit: `pending`

- ID: `ISF-REDUCTION-DELIVERY.1.4`
  Status: `pending`
  Goal: `Qualify actual unary HDL behavior, profile boundaries and complete required R1 delivery.`
  Acceptance: `After .2/.3, consume one fresh admitted observation for the genuine unary witness. Independently prove XOR/AND/OR, scalar/bit/slice/odd parity and nested widths against public HDL pins, plus an actually wrong reduction control and unchanged binary/unrolled controls. Qualify each supported profile or precise refusal with native/API/MCP/carrier/corpus/book parity. Preserve complete first failures and settle all owned jobs; captured native rejection stops further runtime until diagnosed. Commit exact scope evidence and close SEM .92.2 only on complete R1 delivery; required R2/R3 and publication remain open.`
  Verification: `pending exact witness and observer admission`
  Commit: `pending`

- ID: `ISF-REDUCTION-DELIVERY.2`
  Status: `pending`
  Goal: `Preserve authored scalar width dependencies and resolved defaults.`
  Acceptance: `Coordinate SEM .33.3.1 and .32.3; audit public IAL0 parameterized sizing and reuse its evaluator. Retain dependency metadata from actor/transaction/library declarations through parser, LoweringIR, IAL0 and sanitized reports. Never infer a dependency from matching numbers. Cover constants versus parameters, aliases, reset/default sizing and unrelated equal-width controls. Keep incomplete HDL override support explicitly bounded in book/capabilities; qualify detached report and carrier parity, then commit this foundation.`
  Verification: `pending after unary delivery`
  Commit: `pending`

- ID: `ISF-REDUCTION-DELIVERY.3`
  Status: `pending`
  Goal: `Emit consistent parameter-dependent widths through supported HDL profiles.`
  Acceptance: `After .2, coordinate SEM .33.3.2. Carry dependencies through canonical IAL0 to ports, storage, intermediate expressions, constants and resets; no HDL post-processing. Independently compile a real parameter override and compare its declarations and runtime against separately generated matching defaults. Unrelated equal-width declarations remain independent. Refuse profiles that cannot preserve these relationships. Synchronize corpus/public native/API/MCP/book/feedback contracts and commit.`
  Verification: `pending width carrier foundation`
  Commit: `pending`

- ID: `ISF-REDUCTION-DELIVERY.4`
  Status: `pending`
  Goal: `Qualify specialization, parameter legality and external relationship guards.`
  Acceptance: `After .2/.3, coordinate SEM .33.3.3/.33.3.4 and existing derived-width legality. Recompute independent library/activation/generated-top environments before bindings, refuse stale/default-width mismatches and invalid widths, and preserve instance identity. Qualify positive integer legality plus compiled external HDL checks for dependent group/output-width relationships. Reports describe the chosen environment and retain authored dependencies without suggesting a default is generic proof. Keep all generic-width obligations tracked through closure and commit the bounded implementation.`
  Verification: `pending generic emission`
  Commit: `pending`

- ID: `ISF-REDUCTION-DELIVERY.5`
  Status: `pending`
  Goal: `Implement reduce-groups with parameter-correct group order and short tails.`
  Acceptance: `After .2-.4, implement decision 0117 through shared expression/type/width, ISF validation, IAL0 AST, HDL and detached reports. Literal operators ^/&/| and positive decimal N only; use elaborated operand width, least-significant group first, exact result width and an unpadded short final group. Strict target mismatch names target width and group count. Independently qualify defaults, overrides, N greater than W, single-bit and short-tail vectors, slices, nested expressions and invalid group/operator/operand controls. Add supported corpus plus real native/API/MCP reports, actual HDL behavior and synchronized references/book/feedback; no default-width unroll or source-only delivery claim. Split a growing slice before implementation.`
  Verification: `pending generic prerequisites`
  Commit: `pending`

- ID: `ISF-REDUCTION-DELIVERY.6`
  Status: `pending`
  Goal: `Qualify and publish complete required SPECFORGE reduction delivery.`
  Acceptance: `Coordinate SEM .92.4 and .69 after required source slices. Compare exact retained unrolled baseline and accepted scalar parity, then grouped parity at widths 16/32 and a short-tail setting under real parameter overrides, with independent expected bits and width/legality negatives. Verify source/carrier/report/public discovery and supported profiles, required full CI and exact-SHA hosted workflows. Update canonical feedback with revision, selected syntax, limits and caller-owned pin/bundle/integration steps. No foreign write or historical-gate waiver; required R1-R3 close only on complete evidence.`
  Verification: `pending implementation and publication qualification`
  Commit: `pending`

- ID: `ISF-REDUCTION-DELIVERY.7`
  Status: `active`
  Goal: `Implement or explicitly defer optional width-preserving vector inversion.`
  Acceptance: `Coordinate SEM .92.5 after unary semantics. Selected (~ X) preserves operand width and complements each bit, including grouped results; logical ! remains single-bit. Implement only with independent truth tables, nested widths, native/API/MCP/carrier/profile/corpus/book qualification, or document a bounded deferral. Optional R4 must not block required R1-R3 publication. A source-feature deferral does not close the independently owned private classifier defect .7.1.`
  Verification: `Container active to own the scheduled P2 child; optional source inversion has not started. Required grouped XOR remains useful without inversion.`
  Commit: `pending`
  Children: `ISF-REDUCTION-DELIVERY.7.1`

- ID: `ISF-REDUCTION-DELIVERY.7.1`
  Status: `pending`
  Goal: `P2: repair private one-bit complement classification without promoting unsupported source/profile behavior.`
  Acceptance: `Scheduled immediately after required unary delivery .1.4, before generic-width work. Regardless of optional source-feature deferral, reproduce the retained scalar-classification RED capsule: Core UnaryOp(~, one-bit declared signal) has exact width 1 but _operand_is_single_bit returns 0. Repair its classification with explicit known unary semantics and qualify wide, logical and unsupported-operator/profile controls; do not let narrower negation rendering leak unsupported complement tokens into VHDL. Keep source inversion refused unless separately delivered under .7. Own independent native evidence, synchronized boundaries and a focused commit before closing this defect.`
  Verification: `The .1.2.2.1 native RED regression records the one-bit complement mismatch alongside the reduction defect. The complete test source/log is retained for the parent integration audit. Existing public inversion source is unimplemented; this private helper gap does not block required R1 source admission. The R1 fix deliberately leaves this separately scoped non-reduction behavior unchanged.`
  Commit: `pending`

- ID: `ISF-REDUCTION-DELIVERY.8`
  Status: `pending`
  Goal: `P2: repair the existing record-context refusal of private scalar input-formal assignments.`
  Acceptance: `Scheduled after grouped implementation .5 and before .6 publication and remaining SPECFORGE aggregate consumer signoff. Preserve the actual same-actor four controls: private bus width3 shadows actor bus width8; assigning 3d5 and reading bus[0] succeeds without an unused record input but fails cannot write declared input bus when that input is present. No reduction is needed. Canonical book 13b and production formal-scope card/test T1962 establish mutable private direct formals. Trace conditional record-context admission and its source-role/write resolver before repair; separate actor pins, direct private formals and generated public child ports through existing identity ownership. Preserve real actor-input immutability and generated direction/binding contracts, reject declaration inventions, and prove actual source/carrier/report/caller isolation plus independently qualified public behavior where needed. Retain first evidence, synchronize code/book/knowledge, commit the verified fix and close only after complete focused qualification.`
  Verification: `First controlled native --strict --check --json statuses: with_record_baseline=1, without_record_baseline=0, with_record_readonly_reduction=1 and without_record_reduction=1. The latter two have the independent new reduction arity failure owned by .1.2.3.1.2.1. Baseline mixed-record write refuses before capture_actor_reductions: Parser.pm conditionally calls validate_actor_record_contexts for actors with record ports; record_transaction_scope retains the private input formal role as input and the record value write path treats it as a public input. Full executed trace/history and repair remain open; initial inputs/streams retain in the current operand/formal audit work area and will be tracked with the active diagnosis slice.`
  Commit: `pending`

## Blockers

Publication retains the HIAL/startup, full-CI and query-incident obligations
under SEM `.69` and `.93`. No external access or product decision is pending.
