# IAL2-MDBOOK-COHERENCE-AXI-COVERAGE: Present IAL2 as a coherent whole and backfill AXI mdBook coverage

## Metadata

- Tree ID: `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE`
- Status: `active`
- Roadmap lane: `roadmap/documentation alignment / IAL2 mdBook`
- Created: `2026-07-12`
- Last updated: `2026-08-09`
- Owner: repo-local workflow

## Origin

Filed from a director question ("what is the end goal — one IAL2 dialect for
AXI/AHB/APB or one dialect? what is the whole purpose?") plus a measured
documentation-vs-shipped gap surfaced during the `.785`-`.787` AHB requester
BUSY-insertion slices. The director reported getting lost across the fine-grained
IAL2 slices. Two read-only analyses recorded this filing-time snapshot on
`2026-07-12` (the measurements are historical and are superseded by the current
audit below):

- **AXI mdBook coverage is THIN.** 142 shipped `ppif/axi_*.ppif` sources (140 are
  `axi_manager_capacity_status_*` lowering to one module `axi0_capacity_status`
  via `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`, ~9,773 lines),
  but `docs/book/src/16a-ial2-axi.md` is only ~190 lines and references ~6 of 142
  sources (~4%). Whole shipped feature classes are unmentioned in the chapter:
  mixed dynamic/static (57 `*mixed*` sources), write `BID` response-demux
  (12 sources), same-ID issue-order `queue_head` families (48 sources), dynamic
  transaction-ID capture (77 sources), read-data / burst-length-`ARLEN` /
  `RLAST` beat-count validation / multi-beat output banks, and multiple-transaction
  cardinalities. A grep of `16a` finds 0 mentions of `response-demux`/`BID`/`RID`,
  `read-data`, `RLAST`/`ARLEN`, multi-beat, `queue`/`same-id`, or `mixed`.
- **The feature matrix does not compensate.** `docs/book/src/13k-isf-feature-support-matrix.md`
  contains zero AXI content; it is the IAL1/ISF surface only.
- **APB is PARTIAL** (`16b`, ~201 lines, references ~14 of 57 families) and
  **AHB is THOROUGH** (`16c`, ~1,834 lines, references all 32 `.ppif`/`.ahb`
  sources with per-source report walkthroughs) — so the chapters are inversely
  proportional to what they document.

This violates the repo's own doctrines: the documentation-synchronization
invariant (`README.md`: mdBook synced in the same slice as any user-visible
change), the "thorough examples per feature" standard, and the objective that
"the mdBook must grow into the language-independent blueprint for building a
conforming variant in language X." It is the single largest doc-vs-shipped gap in
the IAL2 layer.

## Current Audit Result (`.1`, 2026-08-09)

The filing-time measurements had aged substantially. The current tracked state
is:

| Surface | Current evidence | Audit conclusion |
| --- | --- | --- |
| AXI public corpus | `153` `.ppif` sources: `140` manager-capacity/status plus `13` monitor/driver/acceptor/composition sources | The manager family remains the dominant documentation obligation. |
| Regression accounting | `153` AXI support IDs and `153` AXI `.ppif` relpaths in `perl/FSM/Support/RegressionCorpus.pm` | The complete checked-in AXI corpus is durably support-accounted. |
| AXI chapter | `1,224` lines and `16` unique literal AXI `.ppif` references | Coverage is no longer the filing-time `~4%`, but only `4/140` manager sources are named; the chapter mostly documents the non-capacity spine. |
| Other protocol chapters | overview `107` lines, APB `201`, AHB `3,380` | Preserve the thorough AHB chapter; APB remains separately scoped. |
| Reference implementation | `AxiManagerCapacityStatus.pm` is `9,773` lines | A dedicated manager-family subchapter is warranted; adding all detail to `16a` would obscure its authoring-mode and initiator narrative. |

The manager sources expose these overlapping, composable feature families:

| Feature family | Current source evidence | Documentation treatment |
| --- | --- | --- |
| Capacity and status shell | `140/140` contain `manager-capacity-status`; base source has limits, submit/completion events, policy, pending/full/can-accept/slots outputs | Full source shape and runnable baseline. |
| ID and transaction envelopes | `139` contain `id-families`; `138` contain `transactions`; authored IDs include static, `auto`, and `dynamic` | Full envelope shape plus representative identity modes. |
| Auto-ID lifecycle and event dispatch | `17` contain `auto-id-lifecycle`; the dispatch source separates per-transaction request/completion events | Full lifecycle fragment and runnable dispatch example. |
| Same-ID policy and queueing | `78` contain `same-id-ordering`; reject and issue-order-queue policies cover concrete and dynamic reuse; `48` filenames identify queue-head families | Full policy fragments; representative concrete/dynamic and multi-group/depth examples. |
| Response demultiplexing | `130` contain `response-demux`; write/BID and read/RID families include generated completion, single/multiple, static/dynamic/mixed populations | Separate representative write and read examples. |
| Mixed populations/cardinality | `57` filenames identify mixed dynamic/static sources; bounded depth-2/depth-3, multi-static, multi-dynamic, and multi-group shapes are shipped | Representative matrix, not one prose walkthrough per combinatorial fixture. |
| Read-data capture | `79` contain `read-data`; `15` single-beat, `48` last-beat, and `16` multi-beat capture scopes are shipped | Full clause shape for one single-beat and one multi-beat source, with the remaining scopes tabulated. |
| Burst length and runtime validation | `48` contain `burst-length`; `16` use report-only and `32` runtime-assertion validation; burst-last occurs in `80` sources | Paired report-only/runtime examples explaining raw `ARLEN`, AXI `axlen-plus-one`, beat counting, and `RLAST`. |
| Multi-beat output/status banks | `16` use per-beat status, worst-observed aggregation, and RID-based multi-beat interleaving | Full deep source fragment and explicit bounded residue. |

`docs/book/src/16-ial2-protocol-platform-intent.md` already contains the fixed
lowering chain, generic `.ppif` container, alias rule, and per-protocol
navigation. It therefore needs a focused synthesis rather than a rewrite: say
directly that IAL2 is one language layer whose profiles provide
protocol-specific vocabularies. `16a` also contains an obsolete internal
workflow narrative at lines `992..1040`: Git blame shows selector/audit/repair
commits appended activation and continuity transitions around a now-fixed
assertion defect. That history belongs in task records and Git, not in the
user-facing final contract.

Placement decision:

- retain `16a-ial2-axi.md` as the mode map plus monitor/initiator spine;
- add `16aa-ial2-axi-manager-capacity-status.md` for the 140-source manager
  family, linked immediately after `16a` in `SUMMARY.md`;
- keep `13k-isf-feature-support-matrix.md` IAL1/ISF-only and do not mix IAL2
  protocol coverage into it;
- keep `14-feature-backlog.md` a bounded backlog/boundary surface rather than a
  shipped-capability tutorial;
- preserve `16c` except for later exact truth corrections found by a selected
  leaf; a rewrite is expressly excluded.

Ten checked-in representatives passed `./bin/fsmgen --quiet --strict --check
--json` during this audit: the missing AW/W monitor bundle, base capacity shell,
transaction envelope, event dispatch, auto-ID lifecycle, dynamic same-ID reject,
mixed dynamic/static write issue-order queue, multi-group concrete queue-head
read data, mixed dynamic/static report-only burst read data, and depth-3 dynamic
runtime-asserted multi-beat read data. These sources form the executable example
set for the backfill leaves.

## The IAL2 architecture this must convey (from decisions 0014/0015/0016/0018)

- **One language layer, not per-protocol dialects** (`0015`: "IAL2 remains one
  architectural layer"). IAL2 is protocol/platform-generic and spans AXI, CHI,
  ACE, AHB, APB, ATB, and future protocols (`0014`).
- **One generic container: `.ppif`** (Protocol/Platform Intent Format, `0016`). A
  `.ppif` file selects a protocol vocabulary through a `(profile …)` clause.
- **Per-protocol vocabularies (profiles), not per-protocol languages** (`0015`):
  AXI uses `(manager-capacity-status …)`/`(valid-ready-channel …)`, AHB uses
  `(ahb-requester …)`/`(ahb-subordinate …)`/`(ahb-interconnect …)`, APB uses
  `(apb-completer …)`/`(apb-requester-transfer …)`/composition.
- **`.axi`/`.ahb`/`.apb` file suffixes are optional profile aliases, not layers**
  (`0015`: "not separate language layers, do not get special direct-lowering
  privileges, must not fragment the compiler architecture"). The shipped alias
  files are byte-identical mirrors of the generic `.ppif` sources.
- **One mandatory lowering chain** (`0014`): `IAL2 → IAL1/.isf → IAL0/.fsm → HDL`;
  direct IAL2 → IAL0 is forbidden. Every protocol shares the IAL1/IAL0/HDL pipeline.
- **Backend-language-neutral** (`0018`): the IAL layers + mdBook are portable
  contracts; Perl is the reference implementation.

## Goal

Make the IAL2 protocol/platform-intent layer legible from the mdBook alone: (1) an
overview chapter that presents the one-language / per-protocol-profile /
optional-alias / layered-lowering model and each protocol's role as a coherent
whole; and (2) an AXI chapter that documents the shipped AXI manager surface
(feature families, the `.ppif` source shape, runnable examples spanning
trivial→realistic, and an accurate supported-vs-residue statement) proportional to
what is actually shipped, matching the thoroughness AHB already has.

## Non-Goals

- No parser, generator, public source, support-accounting, capability-manifest,
  test, generated-artifact, HDL, or runtime behavior change. This tree is
  documentation-only.
- Not a rewrite of the AHB chapter (already thorough) and not a full APB backfill
  (a separate, smaller concern).
- Does not change the IAL2 architecture (decisions 0014/0015/0016/0018 stand); it
  documents it.

## Acceptance Criteria

- The IAL2 overview conveys the one-language/profile/alias/layered-lowering model
  and purpose clearly enough to answer "one dialect or three?" without reading code.
- The AXI chapter documents each shipped AXI manager feature family with at least
  one runnable, lowering-clean example and an accurate supported/residue summary;
  the "~4% of sources referenced" gap is closed to a representative, honest sample.
- `mdbook build docs/book` passes; doc path + doctrine gates pass.
- Live docs/roadmap/task-tree status updated; each leaf committed per `COMMIT.md`.

## Task Tree

- ID: `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE`
  Status: `active`
  Goal: `Present IAL2 as a coherent whole in the mdBook and backfill AXI coverage to its shipped surface.`
  Children: `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.1, IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.2, IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.3, IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.4, IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.5, IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.6`

- ID: `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.1`
  Status: `done`
  Goal: `Audit the IAL2 mdBook coherence + AXI coverage gap and select the exact backfill plan.`
  Acceptance: `Read docs/book/src/16-ial2-protocol-platform-intent.md, 16a/16b/16c, 13k, 14-feature-backlog.md, the shipped ppif/axi_*.ppif families, AxiManagerCapacityStatus.pm, RegressionCorpus, and decisions 0014/0015/0016/0018. Assess whether the 16-ial2 overview clearly conveys the one-language/per-protocol-profile/optional-alias/layered-lowering model and purpose; enumerate the AXI feature families and select which get a documented source shape + runnable example vs a representative sample; decide whether AXI coverage lives in 16a, a new sub-chapter, and/or 13k; and produce a bounded per-leaf backfill plan (overview synthesis first, then AXI family chapters/examples) with preservation of the thorough AHB chapter. No behavior change; documentation planning only.`
  Verification: `Remeasured 153 AXI PPIF sources as 140 manager plus 13 non-manager; proved exact 153/153 RegressionCorpus ID/relpath accounting; measured overview/16a/16b/16c at 107/1224/201/3380 lines and 16a at 16 unique literal AXI references; censused manager clauses and policies; traced stale workflow prose with git blame; read the generator and protocol corpus; selected ten representative sources and passed strict check JSON on all ten; selected a dedicated 16aa subchapter and ordered .2-.6 without changing behavior.`
  Commit: `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.1: audit AXI book coverage`

- ID: `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.2`
  Status: `pending`
  Goal: `Repair IAL2 architecture/current-truth prose and remove AXI workflow-history contamination.`
  Acceptance: `Make the IAL2 overview answer one language versus per-protocol dialects explicitly: one IAL2 language layer, generic PPIF container, protocol-specific profile vocabularies, optional aliases, mandatory IAL2->IAL1->IAL0->HDL lowering. In 16a, replace the obsolete selector/activation/continuity narrative with the final shipped assertion truth, account for the checked-in axi_aw_w_valid_ready_bundle.ppif monitor source, and keep the current initiator examples and honest bounded residue intact. Do not change code, tests, public sources, generated artifacts, or behavior.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `none`

- ID: `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.3`
  Status: `pending`
  Goal: `Add the AXI manager-capacity/status subchapter and document its foundational source model.`
  Acceptance: `Create docs/book/src/16aa-ial2-axi-manager-capacity-status.md and link it after 16a in SUMMARY.md. Explain the 140-source family as composable bounded fixtures, then document full runnable source shapes for capacity/status, id-families, transactions, event dispatch, auto-ID lifecycle, and static/auto/dynamic ID modes with report/artifact expectations and explicit residue. Preserve 16a as the mode/initiator entrypoint and do not add IAL2 content to 13k.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.2`

- ID: `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.4`
  Status: `pending`
  Goal: `Document AXI same-ID ordering, mixed populations, and response demultiplexing.`
  Acceptance: `Extend 16aa with concrete/dynamic same-ID reject and issue-order-queue policy shapes, queue-head semantics, bounded depth/cardinality, mixed dynamic/static populations, write BID/read RID response-demux, generated completion, and representative runnable write/read sources. Clearly distinguish fixture combinations from independent language features and state scoreboard/interleaving residue without implying full AXI manager behavior.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.3`

- ID: `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.5`
  Status: `pending`
  Goal: `Document AXI read-data, burst-length, RLAST validation, and multi-beat output banks.`
  Acceptance: `Extend 16aa with single-beat, last-beat, and multi-beat read-data shapes; completion-source response-demux; raw ARLEN axlen-plus-one capture; report-only versus runtime-assertion validation; beat-count/RLAST behavior; per-beat status, worst-observed aggregation, valid masks, RID interleaving, and bounded output banks. Include runnable representative sources for concrete queue-head, mixed report-only, and dynamic depth-3 runtime multi-beat paths plus accurate residue.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.4`

- ID: `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.6`
  Status: `pending`
  Goal: `Run the final IAL2/AXI coherence proof and close the documentation tree.`
  Acceptance: `Re-census the current AXI corpus and map every source to the documented monitor/initiator or manager feature families; rerun the ten representative strict checks and relevant schedule/semantic/outdir probes; build the mdBook; run public book/path/doctrine gates; confirm 13k remains ISF-only, APB remains honestly partial, AHB is preserved, no internal workflow narration remains in 16a/16aa, and all supported/residue claims agree with current reports. Close the task tree and bounded Memory only after a clean committed result.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.5`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.2` | `pending` | Establish the coherent architecture and final-truth narrative before adding the dedicated manager-family reference. |

## Decisions

- `2026-08-09`: The director delegated the choice among this audit and HIAL/VIAL
  `.16`, `.17`, and `.19`. Select this audit first because the mdBook is the
  director's primary project view and currently contains stale shipped-status
  claims; mixed-language `.16` remains tool-dependent, scale `.17` should
  measure a stable documented contract, and expressive expansion `.19` should
  not widen scope while the current public reference is internally inconsistent.
- `2026-08-09`: Keep the existing overview and `16a` entrypoint focused; place
  the 140-source manager family in new `16aa` rather than overloading `16a`,
  mixing IAL2 into the ISF-only `13k`, or using the backlog as a tutorial.
- `2026-08-09`: Document independent feature semantics in full, but document
  the combinatorial fixture matrix through representative sources. Ten selected
  sources span every current family and all passed strict check JSON.

## Findings Routed Outside This Tree

- `MDBOOK-CROSS-LAYER-CURRENT-STATUS-TRUTH-REPAIR` now tracks stale active-
  frontier and VHDL/GHDL status narration in Chapter 11. It must reconcile the
  text against current task/decision/tool evidence before editing; it is not
  folded into this IAL2-only tree.
- `NEXSIM-REQUIREMENTS-HEADING-NUMBERING-REPAIR` now tracks the deterministic
  one-section lag in subsections below top-level sections 36 through 42 of
  `docs/NEXSIM_API_MCP_AGENT_CONSUMER_REQUIREMENTS.md`.

## Notes

- Activated on `2026-08-09`; `.1` completed the current audit and `.2` is the
  sole PNT-eligible frontier.
- Related: the AXI thread is a coherent-but-deliberately-partial spine — 140/142
  sources compose one `axi0_capacity_status` module (a synthesizable
  capacity/status + response-demux + read-data-capture core that self-labels a
  "capacity-status-shell"), not yet a bus-driving initiator (it does not drive
  AW/AR/W handshakes, addresses, or WDATA/WLAST). Whether to keep deepening the AXI
  response/bookkeeping side vs. broadening toward bus initiation is a strategic
  scope question for the director, tracked separately from this documentation tree.
