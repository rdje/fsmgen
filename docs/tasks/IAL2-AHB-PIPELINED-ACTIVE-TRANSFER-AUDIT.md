# IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT: Audit Boundary-Free Active Transfers

## Metadata

- Tree ID: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT`
- Status: `proposed`
- Roadmap lane: `IAL2 / AHB endpoint phase correctness`
- Created: `2026-07-23`
- Last updated: `2026-07-23`
- Owner: repo-local workflow

## Goal

Determine and select the exact generated requester/subordinate phase contract
for consecutive accepted `NONSEQ`/`SEQ` transfers with no intervening
unselected, `IDLE`, or `BUSY` boundary.

## Origin And Evidence

The generated-HDL proof in
`IAL2-FEATURE-COMPLETENESS-FRONTIER.794` required one-transfer phase ownership
to prevent early requester response handling and repeated subordinate
admission of a held transfer. The shipped requester produces a boundary that
releases `ahb_access_active_q`, and the paired proof passes. The current
release rule does not claim true pipelined/back-to-back active transfers that
replace one accepted active address phase directly with another.

## Non-Goals

- Do not activate while the current AHB feature-completeness slice is dirty.
- Do not claim full AHB pipelining from the bounded requester proof.
- Do not change burst policy, queues, outstanding depth, or the transaction
  layer described by decision 0020 in this audit.

## Acceptance Criteria (when activated)

- Build a source-backed generated-HDL probe for consecutive active address
  phases without an IDLE/BUSY/unselected boundary.
- Record address-phase versus data-phase ownership, HREADY/HREADYOUT timing,
  each accepted transfer, response ownership, and storage effects.
- Decide whether the current bounded contract should fail closed, insert a
  boundary, or gain explicit pipelined phase tracking before selecting code.
- Synchronize behavior docs, mdBook, Knowledge Map, tests, task/Memory, and
  relevant gates before any implementation commit.

## Task Tree

- ID: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT`
  Status: `proposed`
  Goal: `Runtime-prove and select the boundary-free active-transfer phase contract.`
  Children: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.1`

- ID: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.1`
  Status: `pending`
  Goal: `Audit consecutive active address/data-phase ownership before any behavior change.`
  Acceptance: `Use a deterministic generated-HDL probe to establish whether consecutive NONSEQ/SEQ address phases are accepted and completed exactly once; trace the IAL1/FSM phase state; select a bounded implementation or fail-closed contract from evidence. Make no behavior change in this audit.`
  Verification: `pending`
  Commit: `pending`

## Blockers

- Activation/order follows the task-tree pivot doctrine after ongoing active
  work dries out.
