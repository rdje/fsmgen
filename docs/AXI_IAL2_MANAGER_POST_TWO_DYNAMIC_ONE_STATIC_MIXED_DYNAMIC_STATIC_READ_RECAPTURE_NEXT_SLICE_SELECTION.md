# AXI IAL2 Manager Post Two-Dynamic/One-Static Mixed Read Recapture Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.428`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.428` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.429`, readiness audit for
two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID &&
RLAST` same-cycle release-and-recapture.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, or runtime behavior.

## Rationale

`.427` shipped the single-beat `RID` version of the same two-dynamic-plus-one-static
mixed read recapture shape. The next smallest same-family behavior is the
existing burst-last sample:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif
```

This boundary is close enough to reuse the `.427` dynamic/static guard and
report policy, but it must be audited before implementation because it adds:

- final-beat-only completion source
  `generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`;
- raw non-final `RID` active/unique-match preservation;
- `RLAST` final-beat response semantics;
- burst-last read-data, raw-`ARLEN`, runtime-validation, and multi-beat
  consumer preservation; and
- rollback/validation coverage distinct from the single-beat `.427` owner.

## Baseline

Direct adapter/report probes on the burst-last response-demux, burst-last
read-data, and burst-last raw-`ARLEN` samples confirmed the current state:

- mode `bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`;
- `response_scope: burst_last`;
- source `generated_multi_mixed_dynamic_static_read_demux_last_beat`;
- semantics `matched_dynamic_or_static_concrete_id_and_last_signal`;
- no `static_capture`;
- no generated release-recapture rules; and
- request-not-busy assertions for `r0`, `r1`, and `r2`.

## Selected Next Leaf

`.429` should audit whether the burst-last implementation can preserve public
syntax, support identities, mode/source/semantics, raw non-final `RID`
assertions, completion-active assertions, two-dynamic single-beat recapture,
existing one-/two-/three-static read recapture, two-dynamic write recapture,
and read-data/raw-`ARLEN`/runtime/multi-beat consumers while selecting exact
recapture report fields, guards, release-only rules, idle-or-releasing
assertions, validation gates, rollback, docs, and Knowledge Map impact.

Direct implementation remains deferred until `.429` owns that audit.
