# ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT: Enforce Rule/Transaction Output Priority

## Metadata

- Tree ID: `ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT`
- Status: `done`
- Roadmap lane: `ISF / scheduler and output-selector correctness`
- Created: `2026-07-24`
- Last updated: `2026-07-30`
- Owner: repo-local workflow

## Goal

Audit and repair actor-level priority between a concurrent rule and a
transaction-invoked named drive when both can select different values for the
same registered output.

## Origin And Evidence

`IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.1` tested a disposable
BUSY-hold candidate declaring a concurrent rule higher priority than the AHB
request transaction. Generated storage conflicts honored priority, but the
transaction invoked a named drive for `HTRANS=SEQ` while the rule selected
`HTRANS=BUSY`; the unified mux enabled both selectors and the generated
assertion failed with `selector multi-value conflict: HTRANS`. The AHB repair
did not need this route and deliberately avoided it.

The post-generalized-count selector reconciles that evidence with the current
lowerer. Direct transaction assignments already participate in
`_apply_rule_transaction_priority_resolution`, and focused t1220 proves a
higher-priority rule suppresses a direct transaction assignment. Named-drive
bodies instead carry owner kind `drive`, remain outside that pass, and are
classified as `isf_unproven_rule_drive_overlap`. The selected gap is therefore
the propagation of transaction-level priority through a named-drive
invocation, not all rule/transaction output assignments.

Canonical evidence is
`docs/IAL2_AHB_REQUESTER_MULTI_BUSY_INSERTION_READINESS_AUDIT.md` and fact
`isf-rule-transaction-output-priority-gap`. Selection evidence is
`docs/IAL2_POST_GENERALIZED_BUSY_COUNT_NEXT_OWNER_SELECTION.md` and fact
`ial2-post-generalized-busy-count-next-owner-selection`.

## Non-Goals

- Do not activate while the AHB requester BUSY tree is active.
- Do not change AHB behavior as part of this general ISF owner.
- Do not weaken or remove selector assertions.
- Do not regress or redesign the working direct rule/transaction assignment
  priority path without independent evidence and ownership.

## Task Tree

- ID: `ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT`
  Status: `done`
  Goal: `Make declared transaction-level priority mechanically exclusive when a lower-priority transaction invokes a conflicting named-drive output selector.`
  Children: `ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.1, ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.2, ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.3`

- ID: `ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.1`
  Status: `done`
  Goal: `Audit the exact transaction-invoked named-drive selector seam without changing behavior.`
  Acceptance: `Starting only after explicit activation from a clean tree, reduce the AHB disposable finding to a protocol-neutral ISF actor with one concurrent rule, one transaction that invokes a named drive, a declared actor-level priority, and different values for one registered output. Include a direct transaction-assignment control proving the existing priority path still works. Reproduce the named-drive selector assertion failure and trace schedule metadata, lowering IR, provenance, drive activation, output-family unification, selector enables, reports, normalized semantics, and diagnostics. Compare masking the lower named-drive enable with failing closed; select exactly one contract or smallest prerequisite for a later leaf. Preserve same-value fan-in, direct rule/transaction assignment suppression, rule/rule and transaction/transaction conflicts, storage/resource priorities, reports, backends, and diagnostics. Make no parser, scheduler, selector, generator, public source, support, test-fixture behavior, semantic/MCP API, HDL/runtime, backend, protocol, HIAL/VIAL, VHDL, scale, or transaction behavior change in the audit.`
  Verification: `Activated only after clean parent selector commit f67705356 through clean activation commit b52e2efc6. Added tracked protocol-neutral named-drive and direct-assignment source/testbench pairs plus focused t1542. The direct control reports force_out over main, records priority_suppressed_by plus inverse rule guard, and passes assertion-enabled runtime with out=1. The named-drive fixture passes strict check with zero diagnostics, reports no priority resolution plus one warning isf_unproven_rule_drive_overlap/not_doable, retains transaction ownership only on drive_call_start, changes the output body to owner kind drive with aggregate drive_start, exposes both values in normalized semantics, and fails assertion-enabled runtime exactly on selector multi-value conflict: out. A two-caller probe proves distinct transaction call-site provenance is collapsed at the shared drive body, so whole-drive masking could suppress an unrelated caller. A same-volume disposable caller-aware candidate adds unique-caller metadata and target-local suppressor reuse; assertion-enabled one-output runtime passes out=1 and multi-output runtime passes out=1 side=1, proving non-conflicting outputs survive. All disposable candidate code, sources, generated FSM/SV, and Verilator objects were removed. Selected proposed no-behavior contract .2 to freeze bidirectional target-local masking for exactly one local transaction caller and fail closed for multiple/generated-child/ambiguous callers, while distinguishing a genuinely unused zero-caller drive from a zero-local generated source; direct assignments, same-value assertions, other conflict families, reports/semantics/backends, and selector assertions remain. Focused t1542 passes 3 top-level subtests/33 internal assertions. t1209+t1211+t1212+t1219+t1220+t1222+t1242+t1255+t1542 pass 9 files/28 top-level tests; t1518+t1256+t1414 pass 3 files/22 tests. Knowledge Map generation/check passes at 1,053 facts/5,409 question keys. The mdBook builds under authorized host100/process4096 to exactly 72 files/16,431,907 bytes and the exact render is removed. MEMORY.md is 50 lines, README.md is 2,337 lines, and .artifacts/tmp/tests is empty. Diff hygiene and all six doctrine gates pass, including project-data locality. Final canonical Stats-compatible capacity is 15,157,592,064/25,769,803,776 bytes = 14.117/24.000 GiB = 58.82%, with separate macOS kernel pressure level 1 and memory_pressure 70% free; guard occupancy is excluded from capacity truth. No product behavior changes and no background job remains.`
  Commit: `ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.1: audit named-drive priority readiness`

- ID: `ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.2`
  Status: `done`
  Goal: `Freeze unique-caller target-local named-drive priority plus ambiguous-caller fail-closed behavior before implementation.`
  Acceptance: `Activate only after .1 commits cleanly and selects this leaf. Freeze the first repair to local named drives with exactly one invoking transaction; preserve drive provenance while carrying explicit caller metadata into priority analysis. Apply declared rule/transaction priority in both directions and only to conflicting drive-body targets, never the whole drive request, so unrelated drive outputs and transaction execution survive. Fail closed before HDL for multiple/generated-child/otherwise ambiguous caller ownership, distinguish zero-local generated ownership from a genuinely unused drive, and freeze a stable diagnostic naming the rule, drive, candidate callers, target, values, and ambiguity. Keep no-priority different-value unique-caller overlap, cycles, and mixed timing fail closed; preserve current same-value fan-in/assertions. Freeze exact schedule resolution, compile-issue, provenance, normalized-semantic, SystemVerilog/Verilog/VHDL qualification, diagnostics, t1542-derived structural/assertion runtime matrix, broader preservation, docs, resource profile, same-volume cleanup, rollback, and separate .3 implementation owner. Make no product behavior change.`
  Verification: `Activated only after clean audit commit e715a34c7 through clean activation commit 9c2439f05. Selected implementation .3 in docs/ISF_RULE_TRANSACTION_NAMED_DRIVE_PRIORITY_CONTRACT_SELECTION.md: drive DTs retain private sorted local_transaction_callers/generated_call_sources metadata; exact one-local/zero-generated ownership participates in priority analysis as the logical transaction while provenance stays owner_kind=drive and adds invoking_transactions; both priority directions reuse assignment-local suppression; rule-over-transaction masks only the conflicting drive target, transaction-over-rule masks only the conflicting rule under drive-body activation; no-priority unique-caller conflicts, cycles, and mixed timing fail closed; same-value fan-in remains; prioritized shared/generated/mixed ownership fails before HDL through isf_ambiguous_rule_transaction_drive_priority/ambiguous_drive_caller; reports use logical actor names with no new public schema; normalized output-family identities stay stable; assertions remain. Current SystemVerilog characterization remains authoritative, and a same-volume native Verilog probe generates then compiles with Icarus 13.0. The VHDL command succeeds but emits invalid SystemVerilog reduction residue drive_zero_en and (|drive_zero_start); root cause is the absent unary-reduction branch in _sv_expr_to_vhdl, no ghdl/nvc/vcom is installed, and decision 0023 plus proposed DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING now own the separate defect. The exact three-file/19,070-byte probe is removed. Unchanged priority/conflict preservation passes 9 files/28 top-level tests; the corrected backend/docs gate passes 7 files/396 tests. Knowledge Map generation/check passes at 1,055 facts/5,420 question keys. The mdBook builds under authorized host100/process4096 to exactly 72 files/16,443,056 bytes and the exact render is removed. MEMORY.md is 50 lines, README.md is 2,339 lines, .artifacts/tmp/tests is empty, git_message_brief.txt is zero bytes, diff hygiene passes, and all six doctrine gates pass. Final canonical Stats-compatible capacity is 19,557,990,400/25,769,803,776 bytes = 18.215/24.000 GiB = 75.89%, with separate macOS kernel pressure level 1 and memory_pressure 73% free; guard occupancy is excluded from capacity truth. Contract selection changes no product behavior, and no background job remains.`
  Commit: `ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.2: freeze named-drive priority contract`

- ID: `ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.3`
  Status: `done`
  Goal: `Implement the contract selected by .2 without weakening selector assertions.`
  Acceptance: `Activate only after .2 commits cleanly and selects this leaf. In LoweringIR, collect sorted distinct local_transaction_callers per named drive and keep generated_call_sources separate; carry private invoking_transactions into drive assignment provenance without changing its drive owner/kind/source. Add priority-analysis records only for exactly one local caller and zero generated sources, using the logical transaction actor plus the drive-body activation condition. Reuse existing target-local suppression in both directions, so only conflicting assignments receive inverse winner guards and non-conflicting drive outputs/request/parameters/transaction/done survive. Emit logical actor priority_resolutions with no compile issue for resolved cases. Fail unique-caller different-value no-priority/cycle/mixed-timing cases through the existing conflict families; fail prioritized multiple/generated/mixed ambiguity with isf_ambiguous_rule_transaction_drive_priority, severity error, proof_status ambiguous_drive_caller, deterministic reason naming rule/drive/sorted callers/generated sources/ambiguity and source summaries retaining operators/values; preserve ambiguous no-priority warning and unused drives. Expand t1542 or an adjacent focused owner for rule-over-drive, drive-over-rule, multi-output, same-value, no-priority, cycle, mixed timing, multiple/generated ambiguity, structural FSM/SV/Verilog, Icarus compile/runtime, assertion-enabled Verilator, strict/check/schedule/semantic/provenance, and exact cleanup. Update t1207/t1209/t1212/t1219/t1220 and other affected conflict/report preservation only as contractually required. Keep normalized semantic output-family fields, report/public/MCP schemas, support accounting, direct assignments, rule/rule and transaction/transaction conflicts, resource priority, selector assertions, parser/source syntax, protocols/AHB, HIAL/VIAL, VHDL backend, scale, decision 0020, and transaction behavior outside the exact fix unchanged. Characterize VHDL honestly under decision 0023 without claiming validity or absorbing DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING. Synchronize durable docs/mdBook/Knowledge Map; use repository-local same-volume artifacts, authorized host100/process4096, exact Stats-compatible capacity plus separate kernel pressure, exact cleanup, focused/broader gates, and commit.`
  Verification: `Activated only after clean contract commit b44afcc51 through clean activation commit 6300fda6f. LoweringIR now inventories sorted distinct local_transaction_callers and generated_call_sources on drive DTs, retains raw drive owner/kind/source provenance plus private invoking_transactions, and maps only exact-one-local/zero-generated drive ownership into logical transaction priority analysis. Rule-over-transaction masks only the conflicting drive assignment; transaction-over-rule masks only the conflicting rule under full drive activation. Unique unordered different-value, cycle, and mixed-timing cases fail closed through existing families; same-value fan-in remains compatible; prioritized shared/generated/mixed ownership fails before HDL as isf_ambiguous_rule_transaction_drive_priority/ambiguous_drive_caller with deterministic detail; ambiguous/unused unprioritized overlap retains isf_unproven_rule_drive_overlap/not_doable. Logical priority_resolutions ship without public schema widening, normalized semantic identities remain stable, and selector assertions remain enabled. SystemVerilog/Verilator proves both directions and multi-output survival; native Verilog/Icarus compiles and runs; direct VHDL remains explicitly unqualified under decision 0023. Focused t1542 passes 7 top-level subtests/92 nested assertions. The final affected preservation set passes 13 files/145 tests; accounting/capability passes 2 files/7,031 tests; bounded book/status/path gates pass 4 files/305 tests. A full supported-corpus public JSON/semantic attempt was correctly stopped by the authorized 4,096-MiB descendant guard when the unrelated existing axi_manager_capacity_status_dynamic_write_same_id_issue_order_queue check reached 5,082.6 MiB RSS; the guard terminated the process tree before t303, the exact empty repository-local workspace was removed, targeted strict/check-failure/schedule/semantic surfaces remain covered by t1542, and no cap increase or unguarded retry was used. Knowledge Map generation/check reaches 1,056 facts/5,426 question keys. The mdBook builds under authorized host100/process4096 to exactly 72 files/16,468,460 bytes and the exact render is removed. README.md remains within its bounded line gate, .artifacts/tmp/tests is empty, git_message_brief.txt is zero bytes, diff hygiene passes, and all six doctrine gates pass. Final canonical Stats-compatible capacity is 15,157,477,376/25,769,803,776 bytes = 14.117/24.000 GiB = 58.82%, with separate macOS kernel pressure level 1 and memory_pressure 71% free; guard occupancy is excluded from capacity truth. No parser/source-syntax, public support identity/accounting, report/semantic/MCP schema, protocol/AHB, HIAL/VIAL, decision-0020, scale, transaction behavior outside the exact repair, or separately owned VHDL behavior changed, and no background job remains.`
  Commit: `ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.3: implement named-drive priority`

## Current Frontier

Implementation `.3` completes this tree: exact-one-local-caller named drives
now honor bidirectional target-local rule/transaction priority, ambiguous
prioritized ownership fails closed, public report/semantic schemas remain
bounded, and SystemVerilog/native-Verilog execution is qualified without
claiming direct-VHDL validity. The next action belongs to a new parent-roadmap
selector activated only from the clean post-`.3` commit boundary.

## Rollback

Rollback removes the `.3` caller/source metadata, logical priority mapping,
ambiguity diagnostic, shipped fixtures, behavior record, and book/spec sync,
restoring the pre-repair named-drive warning/assertion behavior while retaining
the committed `.2` contract and the independently owned VHDL reduction-
expression defect.
