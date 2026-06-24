# AXI IAL2 Manager Post Two-Dynamic/One-Static Mixed Dynamic/Static Write Recapture Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.408`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.408` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.409`, readiness audit for
one-dynamic-plus-two-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture.

No parser, generator, PPIF sample, support-accounting catalog, validation
behavior, generated artifact, test, schedule/check or semantic JSON, HDL, or
runtime behavior changes in this selector.

## Inputs Read

The selector is based on:

- `.407` two-dynamic-plus-one-static mixed write recapture behavior;
- `.406` two-dynamic mixed write recapture contract selection;
- `.405` two-dynamic mixed write recapture readiness audit;
- `.403` one-dynamic plus three-static mixed write recapture behavior;
- `.400` one-dynamic plus two-static mixed write recapture behavior;
- `.389` one-dynamic plus one-static mixed write recapture behavior;
- `.392` one-dynamic plus one-static mixed read single-beat recapture
  behavior;
- `.396` one-dynamic plus one-static mixed read burst-last recapture behavior;
- `.398` broader mixed dynamic/static recapture readiness audit;
- `.299` one-dynamic plus two-static mixed read single-beat response-demux
  behavior;
- `.303` one-dynamic plus two-static mixed read burst-last response-demux
  behavior;
- `.307`, `.310`, `.312`, and `.314` read-data, raw-`ARLEN`, runtime
  validation, and multi-beat preservation records over the one-dynamic plus
  two-static mixed read family;
- current response-demux read/write normalization, mixed dynamic/static state
  builders, dynamic/static release and release-recapture helpers, assertion
  and report helpers, focused t/1436/t1437/t1438 expectation surfaces,
  support accounting, README, ROADMAP_V2, mdBook, Memory, task tree, and
  Knowledge Map.

The current implementation surface confirms the write-side mixed recapture
marker now covers the one-dynamic/multi-static and two-dynamic/one-static
write shapes, while the read-side mixed recapture marker remains bounded to
exactly one dynamic read transaction plus one concrete static read
transaction.

## Guarded Baseline Probe

The selector attempted a guarded schedule probe for the likely first read-side
candidate:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif
```

The RAM guard stopped the probe before usable output because host memory was
already above the default cutoff:

```text
host memory reached 92.0% against the 88% cutoff
schedule output: 0 bytes
```

No cutoff was raised and no retry was selected.

## Decision

The next exact owner is a readiness audit:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.409
```

The candidate public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif
```

This is the smallest post-`.407` read-side broader-mixed recapture direction.
It is closer than validation retry, static-busy-only recapture outside public
samples, request arbitration beyond onehot0, dynamic same-ID queues,
scoreboards, backend variants, VHDL, or full-manager behavior because it
reuses the shipped mixed dynamic/static selected-ID and concrete static busy
lifecycle. It is smaller than read burst-last and two-dynamic-plus-one-static
read recapture because it avoids raw non-final `RID` beat preservation,
final-only `RLAST` release sources, and active dynamic-ID uniqueness.

It is not selected for direct contract selection yet. The read-side mixed
recapture marker and report projection are still singular one-dynamic plus
one-static, while the candidate has one dynamic read transaction plus two
static concrete read transactions and already has scalar read-data and deeper
read-data consumer siblings that must remain preserved.

## Questions For `.409`

`.409` should decide whether the one-dynamic-plus-two-static mixed read
single-beat recapture contract can be selected directly after audit or whether
a smaller helper, report-shape, or validation prerequisite must land first.

The audit should pin the future public contract questions:

- preserving public syntax and support-accounting identity for
  `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif`;
- preserving `bounded_multi_mixed_dynamic_static_read_rid_demux_contract`;
- preserving `generated_multi_mixed_dynamic_static_read_demux` and
  `matched_dynamic_or_static_concrete_id_single_beat`;
- reporting dynamic recapture on
  `response_demux.read.dynamic_capture.transactions[0]`;
- reporting static recapture under list-shaped
  `response_demux.read.static_capture[]` entries for `r1` and `r2`;
- using `generated_multi_mixed_dynamic_static_read_demux_completion` as the
  candidate release-recapture source;
- making dynamic release-recapture block both admitted static sibling
  requests and both static concrete IDs;
- making each static release-recapture block the admitted dynamic request and
  the admitted sibling static request;
- making release-only rules exclude only their own same-transaction
  same-cycle request;
- replacing selected request-not-busy assertions with idle-or-releasing
  assertions for `r0`, `r1`, and `r2`;
- preserving onehot0 mixed read request policy, static-ID exclusion,
  response active-match, pairwise unique-match, and completion-active
  assertions;
- preserving scalar single-beat read-data consumption over generated multiple
  mixed read completions; and
- recording focused validation, RAM-guard constraints, rollback, docs,
  Knowledge Map impact, and deferred burst-last, two-dynamic, backend, VHDL,
  and full-manager boundaries.

## Deferred Alternatives

Validation retry after the `.407` and `.408` RAM-guard stops is not a feature
owner. The cutoffs are recorded and future audit or implementation leaves can
run guarded probes again when host memory permits.

Read burst-last broader mixed recapture remains deferred because it must
preserve raw non-final `RID` beats, final `RID && RLAST` release/recapture
sources, scalar last-beat read-data, raw-`ARLEN`, runtime beat-count/`RLAST`,
and multi-beat output-bank consumers.

Two-dynamic-plus-one-static mixed read recapture remains deferred because it
adds active dynamic-ID uniqueness, request no-active-same-ID guards, and
list-shaped dynamic recapture entries on top of static concrete-ID
reservation.

Static-busy-only recapture outside selected public mixed samples, helper/report
cleanup outside the `.409` audit, request arbitration beyond onehot0, dynamic
same-ID queues, scoreboards, queued/blocking policy, profile aliases, direct
backend behavior, backend-language variants, VHDL, and full AXI manager
behavior remain later exact owners.

## Validation For This Selector

Selector closeout requires:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
mdbook build docs/book
scripts/check_doctrines.sh
```

No behavior-bearing command is required for `.408`.

## Rollback

Rollback is this docs-only selector commit. Reverting it removes only the
`.409` selection record, fact card, task-tree advancement, live-doc updates,
and resume pointer update; generated behavior remains at `.407`.
