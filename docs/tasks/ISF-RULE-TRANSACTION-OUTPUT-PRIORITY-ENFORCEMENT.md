# ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT: Enforce Rule/Transaction Output Priority

## Metadata

- Tree ID: `ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT`
- Status: `proposed`
- Roadmap lane: `ISF / scheduler and output-selector correctness`
- Created: `2026-07-24`
- Last updated: `2026-07-24`
- Owner: repo-local workflow

## Goal

Audit and repair actor-level priority between a concurrent rule and transaction
drive when both can write different values to the same registered output.

## Origin And Evidence

`IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.1` tested a disposable
BUSY-hold candidate declaring a concurrent rule higher priority than the AHB
request transaction. Generated storage conflicts honored priority, but the
`HTRANS` unified mux enabled both BUSY and SEQ selectors and the generated
assertion failed with `selector multi-value conflict: HTRANS`. The AHB repair
does not need this route and deliberately avoids it.

Canonical evidence is
`docs/IAL2_AHB_REQUESTER_MULTI_BUSY_INSERTION_READINESS_AUDIT.md` and fact
`isf-rule-transaction-output-priority-gap`.

## Non-Goals

- Do not activate while the AHB requester BUSY tree is active.
- Do not change AHB behavior as part of this general ISF owner.
- Do not weaken or remove selector assertions.

## Task Tree

- ID: `ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT`
  Status: `proposed`
  Goal: `Make declared rule/transaction output priority mechanically exclusive in generated selectors.`
  Children: `ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.1`

- ID: `ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.1`
  Status: `pending`
  Goal: `Reproduce, contract, and repair different-value rule-versus-transaction output priority without weakening conflict diagnostics.`
  Acceptance: `Starting only after explicit activation from a clean tree, reduce the AHB disposable finding to a protocol-neutral ISF actor with one concurrent rule, one transaction drive, a declared priority, and different values for one registered output. Prove current schedule metadata and generated mux/selector assertion behavior; decide whether priority must mask the lower-priority drive enable or fail closed; implement the selected semantics with structural and assertion-enabled runtime coverage; preserve same-value merging, rule/rule and transaction/transaction conflicts, storage priorities, reports, backends, and diagnostics.`
  Verification: `pending`
  Commit: `pending`

## Activation Gate

Proposed and inactive. It requires an explicit clean-tree selection after the
current AHB requester BUSY activity dries out.

Parent selector `IAL2-FEATURE-COMPLETENESS-FRONTIER.829` keeps this tree
proposed while selecting the smaller adjacent generalized literal BUSY-count
readiness audit. The current qualified multi-BUSY requester path does not use
the conflicting concurrent-rule selector mechanism, so this repair is not a
prerequisite to the selected audit.

## Rollback

Before activation, rollback removes this proposed tracking tree and its fact.
After activation, rollback follows the selected leaf contract and retains a
failing assertion-enabled reproducer until the issue is either repaired or
explicitly failed closed.
