# IAL2-MDBOOK-COHERENCE-AXI-COVERAGE: Present IAL2 as a coherent whole and backfill AXI mdBook coverage

## Metadata

- Tree ID: `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE`
- Status: `proposed`
- Roadmap lane: `roadmap/documentation alignment / IAL2 mdBook`
- Created: `2026-07-12`
- Last updated: `2026-07-12`
- Owner: repo-local workflow

## Origin

Filed from a director question ("what is the end goal — one IAL2 dialect for
AXI/AHB/APB or one dialect? what is the whole purpose?") plus a measured
documentation-vs-shipped gap surfaced during the `.785`-`.787` AHB requester
BUSY-insertion slices. The director reported getting lost across the fine-grained
IAL2 slices. Two read-only analyses confirmed the gap is real:

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
  Status: `proposed`
  Goal: `Present IAL2 as a coherent whole in the mdBook and backfill AXI coverage to its shipped surface.`
  Children: `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.1`

- ID: `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.1`
  Status: `pending`
  Goal: `Audit the IAL2 mdBook coherence + AXI coverage gap and select the exact backfill plan.`
  Acceptance: `Read docs/book/src/16-ial2-protocol-platform-intent.md, 16a/16b/16c, 13k, 14-feature-backlog.md, the shipped ppif/axi_*.ppif families, AxiManagerCapacityStatus.pm, RegressionCorpus, and decisions 0014/0015/0016/0018. Assess whether the 16-ial2 overview clearly conveys the one-language/per-protocol-profile/optional-alias/layered-lowering model and purpose; enumerate the AXI feature families and select which get a documented source shape + runnable example vs a representative sample; decide whether AXI coverage lives in 16a, a new sub-chapter, and/or 13k; and produce a bounded per-leaf backfill plan (overview synthesis first, then AXI family chapters/examples) with preservation of the thorough AHB chapter. No behavior change; documentation planning only.`
  Verification: `pending`
  Commit: `pending`

## Notes

- Not PNT-eligible until the director activates it (proposed backlog direction per
  `docs/TASK_TREE.md`).
- Related: the AXI thread is a coherent-but-deliberately-partial spine — 140/142
  sources compose one `axi0_capacity_status` module (a synthesizable
  capacity/status + response-demux + read-data-capture core that self-labels a
  "capacity-status-shell"), not yet a bus-driving initiator (it does not drive
  AW/AR/W handshakes, addresses, or WDATA/WLAST). Whether to keep deepening the AXI
  response/bookkeeping side vs. broadening toward bus initiation is a strategic
  scope question for the director, tracked separately from this documentation tree.
