# AXI IAL2 Manager Post Multiple Dynamic Read Recapture Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.382`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.382` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.383`, a readiness audit for multiple
all-dynamic read burst-last `RID && RLAST` same-cycle release-and-recapture.

The selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, or runtime behavior.

## Rationale

Multiple all-dynamic read burst-last recapture is the closest remaining
read-side sibling after `.381` shipped single-beat `RID` recapture. It shares
the same multi-active selected-ID/busy lifecycle, admitted `ARID` capture,
onehot0 same-cycle dynamic read request policy, active-ID uniqueness, request
no-active-same-ID assertions, raw response active/unique-match assertions, and
completion-active release structure.

It is not safe to jump directly to implementation because the burst-last path
has extra public surfaces that the single-beat slice intentionally avoided:

- final completion is matched `RID && RLAST`;
- non-final read beats must remain legal raw matched `RID` beats;
- raw response active/unique-match assertions intentionally stay unqualified by
  `RLAST`;
- scalar last-beat read-data consumes generated last-beat completion pulses;
- report-only raw-`ARLEN` and runtime beat-count/`RLAST` validation use raw
  matched beats and final `RLAST` assertions; and
- multi-beat output banks capture every matched beat while the final
  `RID && RLAST` completion remains the release boundary.

The `.381` implementation already proved why the boundary needs a separate
audit: an early attempt accidentally widened burst-last metadata before the
final implementation constrained recapture to the single-beat sample. The next
slice should therefore audit burst-last readiness first, then select a public
contract or narrower prerequisite from evidence.

## Selected .383 Scope

`.383` should audit multiple all-dynamic read burst-last `RID && RLAST`
same-cycle release-and-recapture readiness for the existing support-accounted
sample:

```text
ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif
```

The audit should decide whether the next exact owner can be public contract
selection, direct implementation, helper/report cleanup, a validation retry
slice, support-detail alignment, or a narrower prerequisite. It must record:

- whether the public source syntax, support identity, and
  `bounded_multi_dynamic_read_rid_rlast_demux_contract` mode stay unchanged;
- whether release-recapture fields should use
  `multi_active_unique_dynamic_read` plus
  `generated_dynamic_demux_last_beat_completion`;
- how release-only and release-recapture guards preserve own request, own
  final completion, own busy state, no sibling admitted request, and no active
  sibling with the new `ARID`;
- which request assertions would change from request-not-busy to
  idle-or-releasing;
- how raw non-final read beats, raw response active/unique-match assertions,
  and final completion-active assertions remain distinct;
- scalar last-beat read-data, raw-`ARLEN`, runtime beat-count/`RLAST`, and
  multi-beat output-bank preservation expectations;
- validation gates and host-memory caveats;
- rollback boundary;
- README, ROADMAP_V2, mdBook, task-tree, Memory, and Knowledge Map updates;
  and
- explicit deferred boundaries.

## Deferred Boundaries

This selector does not choose behavior for mixed dynamic/static recapture,
static busy recapture, request arbitration beyond onehot0, dynamic same-ID
queues, scoreboards, queued/blocking policy, profile aliases, direct backend
behavior, backend-language variants, VHDL, or full AXI manager behavior.

## Validation

Closeout for `.382` is documentation and continuity only:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No focused generator, parser, support-accounting, schedule/check/semantic, or
HDL probes are required because this selector changes no behavior.

## Rollback

Rollback is the `.382` selector commit. Reverting it restores `.382` as the
active frontier and removes `.383` as the selected burst-last readiness audit.
