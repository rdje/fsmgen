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
  Children: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.1`, `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.2`, `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.3`, `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.4`, `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.5`, `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.6`

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
  Status: `done`
  Goal: `Implement one-slot accepted address/control phase recapture and preserve the generated AHB requester/fabric/subordinate phase contract.`
  Acceptance: `Starting only after .2 commits cleanly, update AhbSubordinate generated IAL1/state/report behavior so every HSEL && HREADY && active HTRANS phase is retained exactly once: direct-admit current when idle, otherwise capture exactly one next HADDR/HTRANS/optional HBURST/HWRITE/HSIZE/wait_cycles bank, never capture HWDATA, reassert HREADYOUT low after the acceptance edge, relaunch after the current generated FSM tail without a second bus acceptance, and complete every accepted phase exactly once. Preserve current-response ownership, wait states, storage side effects, IDLE/BUSY/selection handling, sequence/HBURST/BUSY-park policies, and two-cycle ERROR semantics including IDLE cancellation versus active continuation. If paired generated-HDL preservation proves the bounded generated requester keeps an already-accepted address presentation active through the data phase, repair only that generated requester timing prerequisite so it retires the accepted presentation to an IDLE boundary while waiting for edge-captured data completion; preserve its public syntax/ports/report/status/burst policy and do not change direct requester seeds. If that correct IDLE retirement proves the generated interconnect response mux loses the accepted data-phase owner because it decodes only the current HTRANS/HADDR, add the smallest generated-interconnect owner latch: capture the selected subordinate at each ready active address acceptance, mux HREADY/HRESP/HRDATA from that retained owner through the data phase, retire on completion, and atomically replace it when completion accepts the next active address phase. Preserve address decode/select behavior, unmapped two-cycle ERROR behavior, public syntax/ports/report/source/support/artifact identities, and direct interconnect seeds. Add the selected additive phase_pipeline report and update current docs/book/facts. Extend t1519 to prove two acceptances/admissions/completions and storage 0x00002211 plus held-phase/error cases; run affected requester/subordinate/aggregate/paired preservation, support/accounting, mdBook, Knowledge Map, memory/path/diff/doctrine gates under the 4-GiB descendant cap. Do not change public syntax/ports/source or support IDs/artifact names, direct fsm/ahb_lite_subordinate.fsm or direct requester/interconnect seeds, broader burst policy, AXI/APB/VHDL, general queues/outstanding transfers, or decision 0020.`
  Verification: `Implemented the shared generated-role depth-one phase pipeline without changing public syntax, ports, source/support identities, artifact names, selected burst policy, or direct seeds. AhbSubordinate now captures every selected ready active phase once in ahb_phase_pending_q plus HADDR/HTRANS/optional HBURST/HWRITE/HSIZE/wait_cycles fields, never HWDATA; holds ready low while occupied; retires final ERROR safely; and reports phase_pipeline mode one_accepted_next_address_control/capacity 1/live_data_phase_held_while_stalled/stall_before_another_acceptance. Preservation exposed and this leaf repaired the coupled generated prerequisites: AhbRequester separates address/data/response ownership, retires accepted HTRANS to IDLE, and edge-captures HRESP/HRDATA; AhbInterconnect retains a reset-clean one-hot subordinate data owner through completion with same-edge mapped replacement and additive composition.response_mux.data_phase_owner reporting. t1519 passes three exact generated-HDL scenarios: NONSEQ0->SEQ1 has 2 accepts/captures/completions and storage 0x00002211; final ERROR+active has exactly two ERROR cycles and completes the continuation to storage 0xaa; final ERROR+IDLE has exactly two ERROR cycles, no continuation, and no storage effect. Generated-HDL t1513 preserves 5 presentations/4 beats/1 BUSY/storage 0x44332211; t1515 preserves 2 commands/10 presentations/8 beats/2 BUSY/status 0x44332211/control 0x88776655. Requester SINGLE/INCR4/WRAP4/8/16/BUSY, subordinate word/byte/SEQ/HBURST/BUSY, one-/two-window mapped/unmapped, and alias tests pass; final consolidated t1473/t1475/t1478/t1480/t1498/t1514/t1516/t1518 passes 8 files/30 tests in 860 seconds. t248+t297 pass 6815 assertions with unchanged accounting. t1518 now locks the shipped current phase truth. Perl syntax, strict checks, --verify-hdl, mdBook build, Knowledge Map generation/check at 973 facts/4928 question keys, memory architecture, docs paths, diff, and doctrine gates pass. Direct memory-pressure probes stayed safe (56-70% free during the last broad verifier); all guarded descendants stayed below 4 GiB. The affected t1480 test-only legal fabric-name sync is recorded above; unrelated known t1474 diagnostic drift remains with PUBLIC-SYNC-TEST-DRIFT-REPAIR. Disposable book/temp outputs were removed. Current behavior record/fact ial2-ahb-pipelined-active-transfer-repair, README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map are synchronized. Decision 0020 remains inactive; .4 owns the separate direct-seed audit.`
  Commit: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.3: repair generated AHB phase pipeline`

- ID: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.4`
  Status: `done`
  Goal: `Audit the separate direct lower-layer AHB subordinate seed for consecutive active-phase retention after the generated-family repair.`
  Acceptance: `Starting only after .3 commits cleanly, runtime-probe fsm/ahb_lite_subordinate.fsm with consecutive selected active phases at a ready completion edge, distinguish its direct-FSM behavior from the shared IAL2 generator, and either prove correct retention or select a separate exact repair leaf. Make no seed behavior change in the audit.`
  Verification: `Startup Knowledge Map consultation exposed and this leaf corrected the stale present-tense question on historical .807 selector fact ial2-post-current-surface-repair-next-owner-selection; current generated behavior now routes only to ial2-ahb-pipelined-active-transfer-repair, while the direct result routes to new fact ial2-ahb-direct-subordinate-pipelined-active-transfer-runtime-audit. Added no-behavior t1520 plus a direct-seed Verilator harness. Structural proof shows only IDLE samples active address/control; ACCESS and ERROR_COMPLETE contain no HSEL/HADDR/HTRANS capture path. Runtime success case presents a word write then distinct NONSEQ read: bus_accepts=2, internal_captures=1, internal_completions=1, response_error_cycles=0, sampled_write=1, storage=0x11111111. Runtime ERROR case presents unsupported SEQ then active NONSEQ on final ERROR: bus_accepts=2, internal_captures=1, internal_completions=1, response_error_cycles=2, storage=0. The guarded t1520 run passes 2/2 top-level tests in 4 seconds under the 4-GiB descendant cap. t1518 current-doc truth passes 4/4 top-level tests after locking the generated-versus-direct distinction. Direct strict HDL generation, Perl syntax, mdBook build, Knowledge Map generation/check at 974 facts/4934 question keys, memory architecture, docs paths, diff, and doctrine gates pass. Added the canonical runtime-audit record/fact and synchronized the current direct-seed behavior/fact, README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map. Removed disposable outputs. No direct seed, generated family, public source/support/report/artifact/port/HDL/runtime, backend, AXI/APB/VHDL, or decision-0020 behavior changed. Selected .5 no-behavior direct-seed contract selection and .6 later implementation.`
  Commit: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.4: prove direct seed drops active phase`

- ID: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.5`
  Status: `done`
  Goal: `Select the exact direct lower-layer AHB subordinate completion-edge phase-retention contract without behavior changes.`
  Acceptance: `Starting only after .4 commits cleanly, reconcile the direct seed's IDLE/ACCESS/UNSUPPORTED/ERROR_COMPLETE schedule and t1520 timing with the generated-family .2/.3 contract. Freeze the smallest direct-FSM state/capture/relaunch contract for successful and final-ERROR completion edges, address/control versus live HWDATA ownership, held-phase suppression, ready/response timing, one completion per acceptance, preservation, validation, docs/fact effects, implementation owner, and rollback. Make no seed/source/support/report/artifact/HDL/runtime behavior change. Do not change generated IAL2 roles, requesters/interconnects, broader burst policy, general queues/outstanding transfers, AXI/APB/VHDL, or decision 0020.`
  Verification: `Reconciled direct t1520 loss timing, the direct IDLE/ACCESS/UNSUPPORTED/ERROR_COMPLETE source schedule, generated-family .2 contract, and .3 repair. Selected atomic no-queue completion-edge dispatch through existing direct state/registers: successful or final-ERROR ready plus selected NONSEQ loads addr_q/write_q/size_q/wait_ctr and enters ACCESS; selected SEQ loads wait_ctr and enters UNSUPPORTED; IDLE/BUSY/unselected enters IDLE without capture. The current effect uses old phase registers and live current-data-phase HWDATA before the edge; HWDATA is never captured, and the following cycle uses the new registers/state without an artificial bubble or second acceptance. First ERROR remains ready-low; final ERROR active captures while IDLE cancels. Exactly-once targets for .6 are two accepts/captures/completions, retained 0x11111111 after the success read, exactly two initial ERROR cycles and later 0xaaaaaaaa from the captured write. Added canonical contract record/fact ial2-ahb-direct-subordinate-pipelined-active-transfer-contract-selection and synchronized the audit/seed records/facts, README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map. t1518 current-doc truth passes 4/4 top-level tests; mdBook build, Knowledge Map generation/check at 975 facts/4940 question keys, memory architecture, docs paths, diff, and doctrine gates pass. Disposable book output removed. No seed/generator/source/support/report/artifact/port/HDL/runtime/backend/AXI/APB/VHDL or decision-0020 behavior changed. .6 owns implementation.`
  Commit: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.5: select direct seed phase contract`

- ID: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.6`
  Status: `pending`
  Goal: `Implement the selected direct lower-layer AHB subordinate phase-retention repair.`
  Acceptance: `Starting only after .5 commits cleanly, implement exactly the selected direct-seed completion-edge phase-retention contract, convert t1520 from defect evidence to the exact repair regression, preserve support/source/artifact identities and all generated-family behavior, synchronize current docs/book/facts/task/Memory, and run focused/broad gates under the resource cap. Do not widen into broader AHB, general queues/outstanding transfers, AXI/APB/VHDL, or decision 0020.`
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

`.3` activated only after `.2` committed cleanly at `814a2cc40`. Its behavior
boundary is the shared generated AHB subordinate family and the selected
additive report/runtime proof; the direct lower-layer seed remains untouched
for `.4`.

`.3` now implements that shared generated contract together with the two
coupled preservation prerequisites: requester address/data/response ownership
separation and retained interconnect data-phase ownership. The current repair
record is `docs/IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_REPAIR.md`, with Knowledge
Map fact `ial2-ahb-pipelined-active-transfer-repair`. The direct lower-layer
seeds remain unchanged; `.4` may activate only after the `.3` closeout commit
leaves the repository clean.

`.4` activated only after `.3` committed cleanly at `3e1dcc930`. Startup
Knowledge Map consultation exposed a current-answer collision: historical
selector fact `ial2-post-current-surface-repair-next-owner-selection` still
answers a present-tense current-subordinate question with the pre-`.3`
`ahb_access_active_q` behavior, while current repair fact
`ial2-ahb-pipelined-active-transfer-repair` answers with the shipped generated
phase bank. `.4` owns the prerequisite fact-routing correction to make the old
question/body explicitly pre-repair before using the map to distinguish the
unchanged direct seed from the repaired generated family. This changes no
source, support, artifact, HDL, or runtime behavior.

Direct generated-HDL t1520 now proves the unchanged seed has the analogous
completion-edge loss in both selected response paths. For a successful word
write followed by a distinct active NONSEQ read, the bus records two accepted
phases but the seed records one idle-state capture and one access completion;
the second read is never evaluated and storage remains the first write value
`0x11111111`. For unsupported SEQ followed by active NONSEQ on the final ERROR
edge, the bus again records two acceptances but one capture/completion, exactly
two ERROR cycles, and storage remains zero. `ACCESS` and `ERROR_COMPLETE`
inspect no HSEL/HADDR/HTRANS and unconditionally return to `IDLE`, so the ready
edge accepts a phase that cannot be sampled on the following cycle. `.4`
selects `.5` no-behavior direct-seed contract selection; `.6` is the later
implementation owner. The generated family remains repaired and unchanged.

The canonical `.4` result is
`docs/IAL2_AHB_DIRECT_SUBORDINATE_PIPELINED_ACTIVE_TRANSFER_RUNTIME_AUDIT.md`
plus fact
`ial2-ahb-direct-subordinate-pipelined-active-transfer-runtime-audit`.
`.5` may activate only after the `.4` closeout commit leaves the repository
clean.

`.5` activated only after `.4` committed cleanly at `d802aa615`. Its sole
scope is the direct lower-layer seed contract: no seed, generator, source,
support, report, artifact, HDL/runtime, backend, protocol, or decision-0020
behavior may change before the selected contract commits.

`.5` now freezes the atomic direct-state contract in
`docs/IAL2_AHB_DIRECT_SUBORDINATE_PIPELINED_ACTIVE_TRANSFER_CONTRACT_SELECTION.md`
and fact `ial2-ahb-direct-subordinate-pipelined-active-transfer-contract-selection`.
`.6` may activate only after the `.5` closeout commit leaves the repository
clean.

Implementation finding: direct t1519 proves the one-slot subordinate and
two-cycle ERROR retirement, while paired t1513/t1515 time out because the
bounded generated requester keeps its already-accepted active address
presentation asserted until data completion. Under the repaired subordinate,
that completion edge is correctly interpreted as another bus acceptance. `.3`
therefore also owns the smallest generated-requester timing prerequisite:
retire an accepted address presentation to `IDLE` during its data-phase wait.
This is required to preserve the shipped pair without reintroducing silent
same-value phase loss; direct requester seeds remain outside the slice.

The first corrected-requester paired rerun completes instead of deadlocking
but writes `00443322` rather than `44332211`. Root cause is the generated
interconnect response mux: it selects `HREADY/HRESP/HRDATA` from the current
active `HTRANS/HADDR`, so the requester's protocol-correct post-acceptance
`IDLE` immediately returns the mux to default ready/OKAY while the accepted
subordinate data phase is still stalled. The requester consequently advances
`HWDATA` one beat early. `.3` therefore also owns the smallest generated-fabric
prerequisite: retain the accepted subordinate as data-phase response owner
until completion, with same-edge replacement for a newly accepted active
phase. Direct interconnect seeds remain outside the slice.

Affected two-subordinate preservation also found four pre-existing stale
`t/1480` wiring assertions. Git blame dates them to `700ff29dde` on June 30,
while `2c9c674998` on July 23 changed the generated interconnect instance to
the legal identifier `fabric`; the generator/top wiring is correct and `.3`
did not cause that drift. Because `t/1480` is a direct preservation gate for
the generated interconnect changed here, `.3` owns the test-only `fabric`
expectation synchronization together with its own unmapped-owner-guard
expectation. The unrelated stale `t/1474` aggregate diagnostic remains owned
by proposed `PUBLIC-SYNC-TEST-DRIFT-REPAIR`.

## Blockers

- None. The predecessor `.807` selector committed cleanly at `a1a6eec9a`
  before this tree and leaf were activated.
