# IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT: Audit Boundary-Free Active Transfers

## Metadata

- Tree ID: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT`
- Status: `active`
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

- Do not activate while the current AHB feature-completeness slice is dirty
  (satisfied: `.807` committed cleanly at `a1a6eec9a`).
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
  Status: `active`
  Goal: `Runtime-prove and select the boundary-free active-transfer phase contract.`
  Children: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.1`, `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.2`, `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.3`, `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.4`

- ID: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.1`
  Status: `done`
  Goal: `Audit consecutive active address/data-phase ownership before any behavior change.`
  Acceptance: `Use a deterministic generated-HDL probe to establish whether consecutive NONSEQ/SEQ address phases are accepted and completed exactly once; trace the IAL1/FSM phase state; select a bounded implementation or fail-closed contract from evidence. Make no behavior change in this audit.`
  Verification: `Generated public-source t/1519 proves the IAL1 ownership-clear admission/sampling predicate and unselected/IDLE/BUSY-only release predicate, plus the corresponding IAL0 owner blocks. Its direct Verilator harness presents INCR4 byte NONSEQ address 0 followed by a distinct held SEQ address 1 with no boundary. HREADY/HREADYOUT stalls and then accepts both address phases with no HRESP error, while generated state records exactly one internal admission/completion, retains addr_q=0/trans_q=NONSEQ, and leaves storage at 0x00000011 instead of applying the second lane-one write to reach 0x00002211. The enhanced clean rerun passes 2/2 top-level subtests in 42 seconds; direct memory pressure reported 79% free and observed generator RSS was about 1.40 GiB, below the 4-GiB limit. Focused t1475+t1494+t1518 preservation passes 3 files/10 tests in 46 seconds. Boundary insertion remains sufficient only for the shipped paired requester shape. Endpoint-only fail-closed boundary waiting would either hold ready low and deadlock the stable next phase or raise ready and accept it; later ownership clear would miss that edge. Selected .2 no-behavior contract work for atomic completion-boundary recapture/tracking of exactly one next phase. Added audit record/fact ial2-ahb-pipelined-active-transfer-runtime-audit and synced README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map at 971 facts/4914 question keys. mdBook build, Knowledge Map, memory architecture, relative-doc paths, diff, and doctrine gates pass; disposable book output was removed. No generator/source/support/report/artifact/port/runtime behavior changed; decision 0020 remains inactive.`
  Commit: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.1: prove dropped active phase`

- ID: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.2`
  Status: `done`
  Goal: `Select the exact bounded completion-boundary phase-recapture contract before implementation.`
  Acceptance: `Starting only after .1 commits cleanly, reconcile t/1519 timing with the generated IAL1/IAL0 schedule and freeze the smallest one-next-phase contract: exact current-completion/new-address-acceptance event, atomic HADDR/HTRANS/HBURST/HWRITE/HSIZE/wait_cycles capture, current-versus-next HWDATA ownership, held-phase suppression, ready/response timing, SEQ continuity, error paths, one completion per bus acceptance, state/report/doc effects, implementation/test owners, preservation, resource boundary, and rollback. Make no behavior change. Do not expand into general queues/outstanding transfers, multiple managers, broader burst policy, AXI/APB, VHDL, or decision 0020.`
  Verification: `Reconciled the generated IAL1/IAL0/HDL schedule with t1519: the second ready/OKAY bus acceptance occurs at cycle 37 while ahb_access_done_q appears only at cycle 48, proving the delayed internal done pulse cannot recover that phase. Selected a one-slot accepted address/control bank captured on HSEL && HREADY && active HTRANS while current drains; it atomically stores HADDR/HTRANS/optional HBURST/HWRITE/HSIZE/wait_cycles, never HWDATA, then drives the following data phase not-ready and relaunches without a second bus acceptance. Existing sequence history commits before queued evaluation. Final ERROR+IDLE cancels; final ERROR+active captures for independent evaluation. Selected an additive phase_pipeline report, exact runtime/preservation/resource/rollback gates, .3 implementation, and .4 separate direct-seed audit. Source PDF pages 5-60/5-61 were rendered and visually checked under the PDF workflow. The RAM-guarded t1519 recheck passes 2/2 top-level tests in 42 seconds; live macOS pressure reported 81% free and peak observed generator RSS was about 1.39 GiB, below the 4-GiB cap. Knowledge Map generation/check passes at 972 facts/4921 question keys; mdBook, memory, docs-path, diff, and doctrine gates pass; disposable book output was removed. No behavior changed.`
  Commit: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.2: select one-slot phase recapture`

- ID: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.3`
  Status: `pending`
  Goal: `Implement one-slot accepted address/control phase recapture in the shared generated AHB subordinate family.`
  Acceptance: `Starting only after .2 commits cleanly, update AhbSubordinate generated IAL1/state/report behavior so every HSEL && HREADY && active HTRANS phase is retained exactly once: direct-admit current when idle, otherwise capture exactly one next HADDR/HTRANS/optional HBURST/HWRITE/HSIZE/wait_cycles bank, never capture HWDATA, reassert HREADYOUT low after the acceptance edge, relaunch after the current generated FSM tail without a second bus acceptance, and complete every accepted phase exactly once. Preserve current-response ownership, wait states, storage side effects, IDLE/BUSY/selection handling, sequence/HBURST/BUSY-park policies, and two-cycle ERROR semantics including IDLE cancellation versus active continuation. Add the selected additive phase_pipeline report and update current docs/book/facts. Extend t1519 to prove two acceptances/admissions/completions and storage 0x00002211 plus held-phase/error cases; run affected subordinate/aggregate/paired preservation, support/accounting, mdBook, Knowledge Map, memory/path/diff/doctrine gates under the 4-GiB descendant cap. Do not change public syntax/ports/source or support IDs/artifact names, direct fsm/ahb_lite_subordinate.fsm, broader burst policy, AXI/APB/VHDL, general queues/outstanding transfers, or decision 0020.`
  Verification: `pending`
  Commit: `pending`

- ID: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.4`
  Status: `pending`
  Goal: `Audit the separate direct lower-layer AHB subordinate seed for consecutive active-phase retention after the generated-family repair.`
  Acceptance: `Starting only after .3 commits cleanly, runtime-probe fsm/ahb_lite_subordinate.fsm with consecutive selected active phases at a ready completion edge, distinguish its direct-FSM behavior from the shared IAL2 generator, and either prove correct retention or select a separate exact repair leaf. Make no seed behavior change in the audit.`
  Verification: `pending`
  Commit: `pending`

## Audit Result And Selection

The current generated public subordinate silently drops the second of two
boundary-free ready/OKAY active address phases. The defect is runtime-confirmed
and documented in
`docs/IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_RUNTIME_AUDIT.md` plus fact
`ial2-ahb-pipelined-active-transfer-runtime-audit`.

`.2` selects a depth-one accepted address/control phase bank at the bus-visible
ready/completion edge, not the eleven-cycles-later internal done pulse. It
captures phase control but not data-phase `HWDATA`, preserves active
continuation after final ERROR unless the manager presents `IDLE`, and assigns
the shared-generator/report/runtime repair to `.3`. The distinct direct `.fsm`
seed remains unchanged for a separate `.4` audit. `.2` activated only after
`.1` committed cleanly at `5cbed61cc`; no behavior repair is mixed into the
contract-selection leaf.

## Blockers

- None. The predecessor `.807` selector committed cleanly at `a1a6eec9a`
  before this tree and leaf were activated.
