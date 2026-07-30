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
  Status: `active`
  Goal: `Audit the exact transaction-invoked named-drive selector seam without changing behavior.`
  Acceptance: `Starting only after explicit activation from a clean tree, reduce the AHB disposable finding to a protocol-neutral ISF actor with one concurrent rule, one transaction that invokes a named drive, a declared actor-level priority, and different values for one registered output. Include a direct transaction-assignment control proving the existing priority path still works. Reproduce the named-drive selector assertion failure and trace schedule metadata, lowering IR, provenance, drive activation, output-family unification, selector enables, reports, normalized semantics, and diagnostics. Compare masking the lower named-drive enable with failing closed; select exactly one contract or smallest prerequisite for a later leaf. Preserve same-value fan-in, direct rule/transaction assignment suppression, rule/rule and transaction/transaction conflicts, storage/resource priorities, reports, backends, and diagnostics. Make no parser, scheduler, selector, generator, public source, support, test-fixture behavior, semantic/MCP API, HDL/runtime, backend, protocol, HIAL/VIAL, VHDL, scale, or transaction behavior change in the audit.`
  Verification: `Activated only after clean parent selector commit f67705356. Activation changes continuity pointers only; direct rule/transaction assignment suppression, the transaction-invoked named-drive gap, generated selector assertions, parser, scheduler, selector, generator, public sources, support, tests, reports, semantic/MCP APIs, HDL/runtime, simulator profiles, backends, protocols, HIAL/VIAL, VHDL, scale, decision 0020, and transaction behavior remain unchanged. Focused t1220+t1518+t1256+t1414 pass 4 files/24 top-level tests. Knowledge Map check remains green at 1,052 facts/5,403 question keys. The mdBook builds under authorized host100/process4096 to exactly 72 files/16,427,244 bytes and the exact render is removed. MEMORY.md is 50 lines, README.md is 2,336 lines, and .artifacts/tmp/tests is empty. Diff hygiene and all six doctrine gates pass, including project-data locality. Final canonical Stats-compatible capacity is 15,007,744,000/25,769,803,776 bytes = 13.977/24.000 GiB = 58.24%, with separate macOS kernel pressure level 1 and memory_pressure 70% free; guard occupancy is excluded from capacity truth. No background job remains.`
  Commit: `ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.1: activate named-drive priority audit`

- ID: `ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.2`
  Status: `proposed`
  Goal: `Freeze the selected named-drive priority or fail-closed contract before implementation.`
  Acceptance: `Activate only after .1 commits cleanly and selects this leaf. Freeze exact source semantics, transaction-to-drive ownership/provenance, selector exclusivity or compile-time rejection behavior, report and normalized-semantic projection, diagnostic wording, same-value handling, preservation matrix, structural/assertion runtime coverage, backend qualification, documentation, resource profile, same-volume cleanup, rollback, and the separate implementation owner. Make no product behavior change.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.3`
  Status: `proposed`
  Goal: `Implement the contract selected by .2 without weakening selector assertions.`
  Acceptance: `Activate only after .2 commits cleanly and selects this leaf. Implement only the frozen rule versus transaction-invoked named-drive priority or fail-closed contract; add structural, report, semantic, diagnostic, and assertion-enabled runtime coverage; preserve the direct assignment path and all boundaries frozen by .2; update durable docs and mdBook; run focused and broader gates under the authorized same-volume resource profile; commit with a clean handoff.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

Audit `.1` is active after clean parent selector commit `f67705356`. It must
build the protocol-neutral working direct-assignment control and failing
transaction-invoked named-drive case, trace the exact lowering boundary, and
select one later contract or prerequisite without changing product behavior.

## Rollback

Rollback of activation restores this tree to proposed, `.1` to pending, and
the clean selector as the resume boundary. During the audit, rollback follows
the selected leaf contract and retains the failing assertion-enabled evidence
until the issue is either repaired or explicitly failed closed.
