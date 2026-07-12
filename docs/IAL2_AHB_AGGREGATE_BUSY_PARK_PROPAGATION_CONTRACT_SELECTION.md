# IAL2 AHB Aggregate BUSY-Park Propagation Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.781`

Date: 2026-07-12

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.781` selects the public contract for the
aggregate AHB BUSY-park propagation source(s) and selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.782`, the direct implementation that ships
both aggregate BUSY-park `.ppif` stems.

Both stems ship in `.782`, mirroring `.770`, which shipped both aggregate HBURST
`SEQ` stems (`ppif/ahb_interconnect_byte_lane_hburst_seq.ppif` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif`) in one slice.

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability-manifest behavior, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct-backend behavior, verification-output generation,
backend-language variant, AXI/APB behavior, broader AHB behavior, or VHDL
behavior.

## Evidence Read

The selector read the `.780` readiness audit, the aggregate HBURST `SEQ` sources
and their `.769`/`.770` contract/implementation lineage, the endpoint BUSY-park
source `ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif` and its
`.775`/`.776` contract/implementation lineage, `AhbInterconnect`,
`AhbSubordinate`, and PPIF adapter code owners,
`perl/FSM/Support/RegressionCorpus.pm` (support-accounting shape),
`perl/FSM/Support/LanguageSurfaceSection.pm`, the focused AHB tests
(`t/1491`–`t/1495`, `t/248`, `t/297`), README, ROADMAP_V2, the AHB mdBook
chapter, the feature backlog, the active task tree, Memory, Knowledge Map, and
relevant decisions.

## Selected Contract

`.782` adds two new additive aggregate BUSY-park source stems — byte-for-byte
copies of the shipped aggregate HBURST `SEQ` sources with the inlined child
subordinate transfer block's `(ignored-transfer busy)` replaced by
`(parked-transfer busy)` (keeping `(ignored-transfer idle)`), and every other
requester/interconnect/child field identical:

### One-subordinate stem

- source: `ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif`
  (copy of `ppif/ahb_interconnect_byte_lane_hburst_seq.ppif`);
- intent name: `ahb_interconnect_byte_lane_hburst_seq_busy_park`;
- source-object anchor: `fsmgen-ahb-interconnect-byte-lane-hburst-seq-busy-park`,
  section `bounded-ahb-interconnect-byte-lane-hburst-seq-busy-park-propagation`;
- support identity: `intent.ppif_ahb_interconnect_byte_lane_hburst_seq_busy_park`;
- coverage key:
  `ial2_ppif_ahb_interconnect_byte_lane_hburst_seq_busy_park_pipeline_cli`;
- `family: protocol_fixture`, `classification: supported_smoke`,
  `source_kind: ppif`, `strict_supported: 1`;
- `expected_module_name: ahb_tb`, `expected_semantic_source_root_kind: top`,
  `expected_check_composition_child_count: 3`,
  `expected_semantic_composition_child_count: 3`.

### Two-subordinate stem

- source: `ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif`
  (copy of `ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif`);
- intent name: `ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park`;
- source-object anchor:
  `fsmgen-ahb-interconnect-two-subordinate-byte-lane-hburst-seq-busy-park`,
  section
  `bounded-ahb-interconnect-two-subordinate-byte-lane-hburst-seq-busy-park-propagation`;
- support identity:
  `intent.ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park`;
- coverage key:
  `ial2_ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli`;
- `family: protocol_fixture`, `classification: supported_smoke`,
  `source_kind: ppif`, `strict_supported: 1`;
- `expected_module_name: ahb_tb`, `expected_semantic_source_root_kind: top`,
  `expected_check_composition_child_count: 4`,
  `expected_semantic_composition_child_count: 4`.

Both stems have `(parked-transfer busy)` on every inlined child subordinate, so a
child parks BUSY through the shipped endpoint machinery and the interconnect
composes it.

## Behavior Delta

Confirmed against the `.780` audit — the behavior slice is source data plus
residue narrowing, with no interconnect generator/parser/report code change:

- **No interconnect parser change.** The `(parked-transfer busy)` vocabulary, the
  `parked_transfer` field, and the relaxed `{idle}`-ignored + `{busy}`-parked
  validation live in the shared `AhbSubordinate` child path
  (`AhbSubordinate.pm:224`–`245`) and apply to the child subordinate role.
- **No propagation-report change.** `_seq_policy_propagation_report` clones each
  child `seq_policy` verbatim (`AhbInterconnect.pm:1177`, `:1207`), so each child
  entry and `composition.seq_policy_propagation` carry the child
  `parks_on = [busy]` and BUSY-free `clears_on` automatically.
- **Residue narrowing only.** `.782` narrows the aggregate
  `ahb_burst_seq_support_deferred` residue at `AhbInterconnect.pm:1401` (drop
  `BUSY-in-burst handling` from the HBURST variant). The base non-HBURST-`SEQ`
  variant at `:1403` is **not** touched, because these BUSY-park sources are
  HBURST sources and only the HBURST residue variant applies to them; the base
  variant keeps `BUSY-in-burst handling` deferred for the non-HBURST aggregate
  sources.
- **Fail-closed carries through.** The child `seq_ok_base` `SEQ`-beat validation
  remains the fail-closed path for a BUSY beat whose control signals drift from
  the armed burst, propagating through the composition unchanged.

## Preservation Matrix

`.782` preserves:

- the shipped aggregate HBURST `SEQ` sources
  `ppif/ahb_interconnect_byte_lane_hburst_seq.ppif` and
  `ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif` and their
  `t/1492`/`t/1493` assertions (the new stems are additive copies, not edits);
- the endpoint BUSY-park `.ppif`/`.ahb` sources and `t/1494`/`t/1495`;
- all shipped AHB requester/subordinate/interconnect/byte-lane/`SEQ`/HBURST/
  BUSY-park/aggregate/`.ahb` behavior;
- the base non-HBURST aggregate `SEQ` residue and every larger-burst,
  optional-signal, requester-side-BUSY, broader-AHB, direct-backend,
  verification-output, backend-variant, AXI/APB, and VHDL residue.

## Focused Test And Accounting

- Add a focused
  `t/1496-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park.t` modeled on the
  aggregate `t/1492`/`t/1493` and the endpoint BUSY-park `t/1494`: both stems
  strict-check; each child entry and `composition.seq_policy_propagation` report
  `parks_on = [busy]` and BUSY-free `clears_on`; the child arms/advances
  `WRAP4`/`INCR4` and holds across a BUSY beat; the narrowed aggregate HBURST
  residue drops `BUSY-in-burst handling`; malformed BUSY-park (parked-busy
  without the HBURST `SEQ` policy on a child) fail-closes; CLI
  check/semantic/schedule/outdir; and the shipped aggregate HBURST `SEQ` +
  endpoint BUSY-park sources still behave.
- `t/248` moves from 293 → 295 protocol / 334 → 336 total supported-smoke
  entries (two new `.ppif` sources).
- `t/297` capability-manifest regexes extend for the two new sources.

## Explicit Non-Selections

`.782` must not add the matching aggregate `.ahb` aliases (a later slice, as
`.771`/`.772` did for aggregate HBURST), requester-side BUSY insertion,
halfword/word burst `SEQ`, wider or indefinite bursts, multi-word/register-bank
progression, optional/property-gated AHB signals, legacy two-bit subordinate
`HRESP`, broader interconnect/decode, scoreboards, full-manager behavior, direct
backend behavior, verification-output generation, backend-language variants,
AXI/APB behavior, broader AHB behavior, or VHDL behavior. It must not touch the
base non-HBURST aggregate `SEQ` residue or edit the shipped aggregate HBURST
`SEQ` sources in place.

## Validation

Closeout for `.781` is documentation-only plus targeted current-state probes on
already-shipped sources:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane_hburst_seq.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

`.782` closeout additionally runs `prove t/1496 t/1492 t/1493 t/1494 t/248 t/297`
and the shipped-source strict/semantic/schedule probes, behind
`scripts/run_with_ram_guard.sh` or equivalent monitoring for the broad runs.

## Rollback

Rollback is documentation-only: remove this selector, its Knowledge Map fact
card, task-tree advancement, README/ROADMAP_V2/mdBook sync, Memory pointer
update, and regenerated Knowledge Map entries. No runtime behavior is affected.
