# ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT: Enforce Rule/Transaction Output Priority

## Metadata

- Tree ID: `ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT`
- Status: `active`
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
  Status: `active`
  Goal: `Make declared transaction-level priority mechanically exclusive when a lower-priority transaction invokes a conflicting named-drive output selector.`
  Children: `ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.1, ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.2, ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.3`

- ID: `ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.1`
  Status: `done`
  Goal: `Audit the exact transaction-invoked named-drive selector seam without changing behavior.`
  Acceptance: `Starting only after explicit activation from a clean tree, reduce the AHB disposable finding to a protocol-neutral ISF actor with one concurrent rule, one transaction that invokes a named drive, a declared actor-level priority, and different values for one registered output. Include a direct transaction-assignment control proving the existing priority path still works. Reproduce the named-drive selector assertion failure and trace schedule metadata, lowering IR, provenance, drive activation, output-family unification, selector enables, reports, normalized semantics, and diagnostics. Compare masking the lower named-drive enable with failing closed; select exactly one contract or smallest prerequisite for a later leaf. Preserve same-value fan-in, direct rule/transaction assignment suppression, rule/rule and transaction/transaction conflicts, storage/resource priorities, reports, backends, and diagnostics. Make no parser, scheduler, selector, generator, public source, support, test-fixture behavior, semantic/MCP API, HDL/runtime, backend, protocol, HIAL/VIAL, VHDL, scale, or transaction behavior change in the audit.`
  Verification: `Activated only after clean parent selector commit f67705356 through clean activation commit b52e2efc6. Added tracked protocol-neutral named-drive and direct-assignment source/testbench pairs plus focused t1542. The direct control reports force_out over main, records priority_suppressed_by plus inverse rule guard, and passes assertion-enabled runtime with out=1. The named-drive fixture passes strict check with zero diagnostics, reports no priority resolution plus one warning isf_unproven_rule_drive_overlap/not_doable, retains transaction ownership only on drive_call_start, changes the output body to owner kind drive with aggregate drive_start, exposes both values in normalized semantics, and fails assertion-enabled runtime exactly on selector multi-value conflict: out. A two-caller probe proves distinct transaction call-site provenance is collapsed at the shared drive body, so whole-drive masking could suppress an unrelated caller. A same-volume disposable caller-aware candidate adds unique-caller metadata and target-local suppressor reuse; assertion-enabled one-output runtime passes out=1 and multi-output runtime passes out=1 side=1, proving non-conflicting outputs survive. All disposable candidate code, sources, generated FSM/SV, and Verilator objects were removed. Selected proposed no-behavior contract .2 to freeze bidirectional target-local masking for exactly one local transaction caller and fail closed for zero/multiple/generated-child/ambiguous callers, while preserving direct assignments, same-value assertions, other conflict families, reports/semantics/backends, and selector assertions. Focused t1542 passes 3 top-level subtests/33 internal assertions. t1209+t1211+t1212+t1219+t1220+t1222+t1242+t1255+t1542 pass 9 files/28 top-level tests; t1518+t1256+t1414 pass 3 files/22 tests. Knowledge Map generation/check passes at 1,053 facts/5,409 question keys. The mdBook builds under authorized host100/process4096 to exactly 72 files/16,431,907 bytes and the exact render is removed. MEMORY.md is 50 lines, README.md is 2,337 lines, and .artifacts/tmp/tests is empty. Diff hygiene and all six doctrine gates pass, including project-data locality. Final canonical Stats-compatible capacity is 15,157,592,064/25,769,803,776 bytes = 14.117/24.000 GiB = 58.82%, with separate macOS kernel pressure level 1 and memory_pressure 70% free; guard occupancy is excluded from capacity truth. No product behavior changes and no background job remains.`
  Commit: `ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.1: audit named-drive priority readiness`

- ID: `ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.2`
  Status: `active`
  Goal: `Freeze unique-caller target-local named-drive priority plus ambiguous-caller fail-closed behavior before implementation.`
  Acceptance: `Activate only after .1 commits cleanly and selects this leaf. Freeze the first repair to local named drives with exactly one invoking transaction; preserve drive provenance while carrying explicit caller metadata into priority analysis. Apply declared rule/transaction priority in both directions and only to conflicting drive-body targets, never the whole drive request, so unrelated drive outputs and transaction execution survive. Fail closed before HDL for zero/multiple/generated-child/otherwise ambiguous caller ownership and freeze a stable diagnostic naming the rule, drive, candidate callers, target, values, and ambiguity. Keep no-priority different-value unique-caller overlap, cycles, and mixed timing fail closed; preserve current same-value fan-in/assertions. Freeze exact schedule resolution, compile-issue, provenance, normalized-semantic, SystemVerilog/Verilog/VHDL qualification, diagnostics, t1542-derived structural/assertion runtime matrix, broader preservation, docs, resource profile, same-volume cleanup, rollback, and separate .3 implementation owner. Make no product behavior change.`
  Verification: `Activated only after clean audit commit e715a34c7. Activation changes continuity pointers only; the working direct-assignment path, unresolved named-drive selector behavior, tracked t1542 characterization, generated assertions, parser, scheduler, selector, generator, public sources, support, tests, reports, semantic/MCP APIs, HDL/runtime, simulator profiles, backends, protocols, HIAL/VIAL, VHDL, scale, decision 0020, and transaction behavior remain unchanged. Focused t1542 passes 3 top-level subtests/33 internal assertions; an initial combined invocation used nonexistent shorthand documentation-test names after t1542 passed, then rg resolves the exact tracked filenames and the authoritative t1518+t1256+t1414 invocation passes 3 files/22 top-level tests. Knowledge Map generation/check remains synchronized at 1,053 facts/5,409 question keys. The mdBook builds to exactly 72 files/16,433,453 bytes; both the initial same-volume repository-root render and the final canonical docs/book/book render are removed without residue. MEMORY.md is 50 lines, README.md is 2,337 lines, and .artifacts/tmp/tests is empty. Diff hygiene and all six doctrine gates pass, including project-data locality. Final canonical Stats-compatible capacity is 15,424,667,648/25,769,803,776 bytes = 14.365/24.000 GiB = 59.86%, with separate macOS kernel pressure level 1 and memory_pressure 72% free; guard occupancy is excluded from capacity truth. No behavior changes and no background job remains.`
  Commit: `ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.2: activate named-drive priority contract`

- ID: `ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.3`
  Status: `proposed`
  Goal: `Implement the contract selected by .2 without weakening selector assertions.`
  Acceptance: `Activate only after .2 commits cleanly and selects this leaf. Implement only the frozen rule versus transaction-invoked named-drive priority or fail-closed contract; add structural, report, semantic, diagnostic, and assertion-enabled runtime coverage; preserve the direct assignment path and all boundaries frozen by .2; update durable docs and mdBook; run focused and broader gates under the authorized same-volume resource profile; commit with a clean handoff.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

Contract `.2` is active after clean audit commit `e715a34c7`. It must freeze
the exact caller metadata, bidirectional per-target priority, ambiguous-caller
diagnostic, preservation, reporting, backend qualification, and implementation
gates proved by `.1`, without changing current lowering behavior.

## Rollback

Rollback of `.2` activation restores `.2` to proposed and clean audit commit
`e715a34c7` as the resume boundary. The tracked direct control, named-drive
assertion failure, and shared-caller evidence remain authoritative until the
issue is repaired or explicitly failed closed.
