# IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT: Exact-Three Paired AHB BUSY Composition Readiness

## Metadata

- Tree ID: `IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT`
- Status: `active`
- Roadmap lane: `IAL2 / AHB paired requester-subordinate BUSY composition`
- Created: `2026-07-29`
- Last updated: `2026-07-29`
- Owner: repo-local workflow

## Goal

Determine whether the shipped exact-three requester can compose directly with
the shipped byte-lane/HBURST-SEQ/BUSY-parking subordinate and one-window AHB
interconnect, with every generated selector assertion enabled, before any new
public source or behavior is selected.

## Non-Goals

- Do not add a public exact-three paired source, alias, support entry, test, or
  generated artifact during the readiness audit.
- Do not select the two-subordinate topology, `.ahb` aliases, BUSY counts above
  three, runtime/policy/multiple-point insertion, distinct local bus-BUSY
  status, wider or indefinite bursts, optional AHB signals, generic priority
  changes, another protocol/backend, or VHDL behavior in this tree.
- Do not activate HIAL/VIAL or decision 0020 from this tree.

## Acceptance Criteria

- The audit starts only after the parent selector commits cleanly and this
  tree's `.1` leaf is activated in a separate no-behavior commit.
- A repository-derived same-volume disposable candidate composes the existing
  `amba_requester_busy_insert_three`,
  `ahb_lite_subordinate_byte_lane_hburst_seq`, and `ahb_interconnect`
  children under top `ahb_tb` through the public lowering path.
- The candidate is checked strictly, scheduled, lowered to reviewable IAL1 and
  IAL0 artifacts, compiled with every generated selector assertion enabled,
  and run through the exact paired runtime boundary.
- Runtime evidence distinguishes five transfer presentations, four accepted
  data beats, one BUSY episode, three ready-qualified BUSY events, one resumed
  `SEQ`, and final storage `0x44332211`.
- The audit records exact future source/object/anchor/artifact/report/support,
  normalized semantic JSON, read-only MCP, diagnostics, preservation,
  resource, cleanup, rollback, and implementation-handoff boundaries before
  choosing a public contract or behavior change.
- Existing exact-three standalone requester and generic/alias exact-two paired
  one-/two-subordinate behavior remains unchanged and retains its focused
  regression owners.
- Focused validation, mdBook, Knowledge Map, continuity, and doctrine gates
  pass; disposable output is counted and removed with no residue.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT`
  Status: `active`
  Goal: `Audit assertion-enabled exact-three requester/BUSY-parking-subordinate/fabric composition before public expansion.`
  Children: `IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1, IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2, IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.3`

- ID: `IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`
  Status: `done`
  Goal: `Audit one-subordinate generic exact-three paired AHB BUSY composition readiness and select the next exact owner.`
  Acceptance: `Activate only after clean parent selector commit IAL2-FEATURE-COMPLETENESS-FRONTIER.816. Reconcile the shipped generic/alias exact-three requester, generic/alias one-/two-subordinate exact-two paired compositions, completed interconnect/generated-subordinate/direct-seed arbitration repairs, public PPIF adapters and AHB generators, report residue, support/language/capability surfaces, normalized semantic JSON, read-only fsmgen_semantic_introspect MCP, focused tests t1520/t1523/t1525/t1528, roadmap, mdBook, Knowledge Map, HIAL/VIAL, and decision 0020. Use only a repository-derived same-volume disposable one-subordinate candidate corresponding to future path ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif, intent ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park, object ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park, anchor ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park_anchor, top ahb_tb, and children amba_requester_busy_insert_three, ahb_lite_subordinate_byte_lane_hburst_seq, and ahb_interconnect. Require strict/check success, exact three IAL1 and four IAL0 review artifacts, assertion-enabled generated HDL, requester report before_beat=2/beats=3, child and propagated parks_on=[busy], one-hot accepted-subordinate ownership, normalized semantic JSON/read-only MCP parity, and runtime 5 presentations/4 beats/1 BUSY episode/3 qualified BUSY events/1 resumed SEQ/storage 0x44332211. Decide whether direct data-only public contract selection can follow, a lower-layer repair is required, or the candidate must fail closed. If ready, freeze projected support accounting 323 protocol / 364 supported+strict / 47 AHB paths split 24 .ppif and 23 .ahb, the exact support id, future focused test owner, diagnostics, preservation, residue, rollback, and separate alias/two-subordinate cadence before behavior changes. Keep counts above three, policy/status/bursts/signals, generic priority, other protocols/backends, HIAL/VIAL activation, VHDL, verification generation, and decision 0020 out of scope. Use the director-authorized --host-max-pct 100 --process-max-rss-mb 4096 profile, report exact Stats-compatible capacity separately from kernel pressure, census the disposable workspace, and remove it without residue.`
  Verification: `Activated at clean commit 0d5093f36, then audited the shipped exact-three requester, exact-two paired one-/two-window lineage, assertion-clean lower layers, public PPIF/report/support/semantic/MCP surfaces, roadmap, book, facts, HIAL/VIAL, and decision 0020. A repository-derived same-volume candidate with future generic identity ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park strict-checks with success, top ahb_tb, 3 children, zero diagnostics, and correctly unmatched disposable support. Schedule preserves schema fsmgen.ial2.protocol_intent.ahb_interconnect.v1, source object/anchor, one-hot accepted-subordinate ownership, exact 3 IAL1/4 IAL0 artifacts, width-two requester counter with 3 -> 2 -> 1 -> 0 retirement, requester before_beat=2/beats=3, child and propagated parks_on=[busy], and no duplicate top busy_flow. Normalized semantic JSON and real fsmgen_semantic_introspect agree on ahb_tb/top/3 children/unmatched support; MCP reports read_only=true and shell_access=false. Verilator compiles without --no-assert and runtime passes transfers=5/beats=4/BUSY episodes=1/qualified BUSY=3/resumed SEQ=1/storage=0x44332211. Current direct t1520, exact-two paired t1523/t1525, and standalone exact-three t1528 owners all pass; the initial combined runner exited only after those first three passes because a nonexistent t1528 filename was supplied, then corrected t/1528-ial2-ahb-requester-three-busy-insert.t passed 1 file/5 tests in 51 seconds. Support/capability t248+t297 pass 2 files/6,911 tests at current 322/363/46, projecting 323/364/47 split 24 .ppif/23 .ahb for one new generic source. No parser/generator/lower-layer/semantic-MCP/assertion repair is required. Selected pending `.2` to freeze the generic public source contract before implementation; alias and two-subordinate cadence remain separate. The exact 54-file/53,575,735-byte audit workspace was removed without residue. Focused current-doc t1518/t1256/t1414 pass 3 files/22 tests; Knowledge Map is synchronized at 1,022 facts/5,201 keys; mdBook builds and its exact 72-file/16,126,252-byte output was removed without residue; all six doctrine gates pass. Post-long-gate Stats-compatible capacity was 86.8% (20.84/24.00 GiB) with kernel pressure 2 (warning), so no further heavy work started; guard occupancy was excluded as capacity truth. No public source/support/test/checked-in artifact/API/HDL/runtime/backend/protocol/verification-generation/HIAL/VIAL/VHDL/transaction behavior changed.`
  Commit: `IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1: audit exact-three paired AHB readiness`

- ID: `IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2`
  Status: `done`
  Goal: `Select the first generic exact-three paired AHB BUSY public contract before implementation.`
  Acceptance: `Activate only after clean .1 audit commit. Read the .1 audit record/fact, disposable strict/schedule/artifact/assertion-runtime/normalized-semantic/read-only-MCP evidence, standalone exact-three requester contract/behavior, generic/alias exact-two paired one-/two-window contracts/behavior, current RegressionCorpus/support/capability surfaces, public diagnostics, roadmap, mdBook, Knowledge Map, HIAL/VIAL, and decision 0020. Freeze exactly one future generic source ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif with intent ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park, source object fsmgen-ahb-interconnect-requester-busy-insert-three-byte-lane-hburst-seq-busy-park, bounded anchor, embedded requester amba_requester_busy_insert_three, subordinate ahb_lite_subordinate_byte_lane_hburst_seq, fabric ahb_interconnect, top ahb_tb, exact 3 IAL1/4 IAL0 artifacts, width-two 3 -> 2 -> 1 -> 0 behavior, requester before_beat=2/beats=3, child/propagated parks_on=[busy], one-hot accepted-subordinate ownership, and no top busy_flow. Select support id intent.ppif_ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park, coverage ial2_ppif_ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park_pipeline_cli, source_kind ppif, classification supported_smoke, strict_supported=1, module ahb_tb, semantic root top, child counts 3, and projected 323 protocol / 364 supported+strict / 47 AHB paths split 24 .ppif/23 .ahb only if reconfirmed. Freeze a future focused test with strict/check/schedule/artifact/verifier/diagnostic/normalized-semantic/real read-only MCP checks plus assertion-enabled runtime 5/4/1/3/1/0x44332211, preservation of t1520/t1523/t1525/t1528 and current aliases, docs/KM/resource/same-volume cleanup/rollback, and a separate implementation leaf. Do not add the source, support entry, test, artifact, parser/generator behavior, `.ahb` alias, two-subordinate topology, counts above three, policy/status/burst/signal behavior, generic priority, another protocol/backend, HIAL/VIAL activation, VHDL, verification generation, or decision-0020 behavior in this selector.`
  Verification: `Activated at clean commit 1087d9bb1, then froze one additive generic public source ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif with exact intent/object/anchor, existing three-child ahb_tb architecture, exact 3 IAL1/4 IAL0 artifacts, width-two 3 -> 2 -> 1 -> 0 requester behavior, before_beat=2/beats=3 reports, child/propagated parks_on=[busy], one-hot accepted-subordinate ownership, and no top busy_flow. Selected support id intent.ppif_ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park, coverage ial2_ppif_ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park_pipeline_cli, ppif/supported_smoke/strict/module ahb_tb/root top/3-child expectations, projected 323 protocol / 364 supported+strict / 47 AHB paths split 24 .ppif/23 .ahb, and focused t1531 plus t/data/ahb_exact_three_paired_busy_composition_tb.svt. t1531 must own source/report/artifact/strict/outdir/verify-HDL/normalized-semantic/real read-only MCP parity and assertion-enabled 5/4/1/3/1/0x44332211 runtime, while current diagnostics and preservation owners remain authoritative. Selected pending `.3` for data-only implementation; no parser/generator algorithm or semantic-MCP API change is expected. Matching alias, two-subordinate exact-three, broader BUSY/protocol/backend/HIAL-VIAL/VHDL/verification-generation/decision-0020 work remains separate. Focused current-doc t1518/t1256/t1414 pass 3 files/22 tests; Knowledge Map is synchronized at 1,023 facts/5,206 keys; mdBook builds and its exact 72-file/16,132,266-byte output was removed without residue; all six doctrine gates pass. Post-gate Stats-compatible capacity was 58.4% (14.02/24.00 GiB), kernel pressure was 1 (normal), and guard occupancy was excluded as capacity truth. Contract selection changes no public source/support/test/artifact/API/HDL/runtime behavior.`
  Commit: `IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2: select exact-three paired AHB contract`

- ID: `IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.3`
  Status: `pending`
  Goal: `Ship the selected generic one-subordinate exact-three paired AHB BUSY source through existing generators.`
  Acceptance: `Activate only after clean .2 contract commit. Implement exactly the .2 contract: add ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif as the exact data-only extension of the exact-two paired source, with selected intent/object/anchor, embedded amba_requester_busy_insert_three, busy-before-beat 2, busy-beats 3, existing ahb_lite_subordinate_byte_lane_hburst_seq, ahb_interconnect, ahb_tb, ports/storage/burst/response/window/wiring unchanged. Add RegressionCorpus entry intent.ppif_ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park with selected coverage, ppif/supported_smoke/strict/module ahb_tb/root top/3-child expectations; update t248/t297 and public support/language/capability/current-doc inventory surfaces to exact 323 protocol / 364 supported+strict / 47 AHB paths split 24 .ppif/23 .ahb. Add t/1531-ial2-ahb-exact-three-paired-busy-composition.t and t/data/ahb_exact_three_paired_busy_composition_tb.svt covering source identities, strict/check success and exact support, schedule schema/3 children/artifacts/one-hot ownership/requester before_beat=2/beats=3/width-two counter/child+propagated parks/no top busy_flow, normalized semantic JSON, real repo-relative fsmgen_semantic_introspect read_only=true/shell_access=false, repo-local outdir, --verify-hdl, and Verilator without --no-assert at exact transfers=5/beats=4/BUSY episodes=1/qualified BUSY=3/resumed SEQ=1/storage=0x44332211 plus stable requester/subordinate/fabric ownership and clean completion. Preserve t1520/t1523-t1526/t1528-t1530 and existing source/alias byte identity; use the smallest warranted focused/broader gates. Add behavior record/fact and sync README, ROADMAP_V2, REGRESSION_CORPUS/support docs, mdBook, task/index, Memory, and Knowledge Map. Use repo-derived same-volume temp/output, authorized host100/process4096, exact Stats-compatible capacity plus separate kernel pressure, exact cleanup census, rollback, and commit. Do not change parser/generator algorithms, existing source bytes, report schema/API, `.ahb` alias, two-subordinate topology, counts above three, policy/status/burst/signal behavior, generic priority, other protocols/backends, HIAL/VIAL, VHDL, verification generation, or decision 0020.`
  Verification: `pending`
  Commit: `pending`

## Decisions

- `2026-07-29`: Parent selector `.816` proposes the one-subordinate generic
  readiness audit as the smallest adjacent owner after all audited AHB
  interconnect, generated-endpoint, and direct-seed assertion boundaries became
  clean. This proposal does not activate the tree or change behavior.
- `2026-07-29`: Clean selector commit `bc3d9eaf1` satisfies the activation
  boundary; `.1` is now the only active leaf and still changes no behavior.
- `2026-07-29`: Audit `.1` proves direct data-only contract readiness through
  existing assertion-clean generators and selects `.2`; no public source ships
  in the audit.
- `2026-07-29`: Clean audit commit `c1f3232f9` satisfies the `.2` activation
  boundary; contract selection is active and still changes no behavior.
- `2026-07-29`: Contract `.2` freezes one generic source, support identity,
  t1531 assertion-enabled runtime, and `.3` data-only implementation; aliases
  and the two-subordinate topology remain separately owned.

## Open Questions

- Whether the disposable exact-three composition proves direct data-only
  implementation readiness or exposes a lower-layer ownership defect. The
  `.1` audit owns the answer and it does not block task-tree creation.

## Blockers

- None.
