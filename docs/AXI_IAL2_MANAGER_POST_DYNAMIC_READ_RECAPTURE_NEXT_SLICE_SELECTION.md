# AXI IAL2 Manager Post Dynamic Read Recapture Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.369`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.369` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.370`, readiness audit for single-active
dynamic read burst-last `RID && RLAST` same-cycle release-and-recapture after
single-beat read recapture shipped.

The selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Rationale

`.368` shipped the single-active dynamic read single-beat `RID` recapture
boundary under the existing
`ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif` sample.
The remaining closest same-family sibling is the single-active dynamic read
burst-last `RID && RLAST` response-demux sample:

```text
ppif/axi_manager_capacity_status_dynamic_read_response_demux_burst_last.ppif
```

That boundary is not a mechanical copy of the single-beat behavior. Burst-last
read response-demux keeps matched non-last beats active, pulses completion only
on the final `RID && RLAST` beat, and already feeds scalar last-beat read-data,
report-only raw-`ARLEN` capture, runtime beat-count/`RLAST` validation, and
multi-beat output-bank shapes. A direct behavior slice should not be selected
until those consumers and report/assertion consequences are audited together.

## Selected Next Owner

`.370` should audit whether the burst-last recapture behavior can keep the
existing public source syntax and mode strings while adding same-cycle
release-and-recapture semantics only to the final generated completion path.
The audit should cover at least:

- generated update ordering for capture-only, release-only, matched non-last,
  and final release-and-recapture cycles;
- whether read-side `same_cycle_release_recapture_policy` vocabulary should be
  shared with or distinct from the single-beat `single_active_dynamic_read`
  policy;
- report ownership for `release_recapture_rule`,
  `release_recapture_source`, and `release_recapture_transaction`;
- replacement or preservation of `axi0_r0_dynamic_request_not_busy` in the
  burst-last response-demux report;
- raw-beat active-match assertions that remain legal for matched non-last
  beats;
- scalar last-beat read-data preservation under the generated final completion
  pulse;
- report-only raw-`ARLEN`, runtime beat-count/`RLAST`, and multi-beat
  output-bank preservation or required follow-on owners;
- focused t/1437 and t/1438 expectation updates for any later behavior owner;
  and
- support-accounting and RAM-guard validation costs.

## Non-Goals

`.370` should not implement burst-last recapture. It should not change parser,
generator, PPIF samples, support accounting, tests, schedule/check/semantic
JSON, HDL output, or report behavior unless it explicitly creates a later
implementation owner.

Multiple dynamic request widening, mixed dynamic/static recapture, static busy
recapture, dynamic same-ID queues, scoreboards, queued/blocking policy, profile
aliases, direct backend behavior, backend-language variants, VHDL, and full AXI
manager behavior remain outside this next audit.

## Validation

Closeout for `.370` should be doc/doctrine-oriented unless the audit discovers a
required cleanup leaf:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

Focused guarded `fsmgen` probes for the existing burst-last and read-data
samples are useful if host memory permits, but `.370` should not force them
outside the RAM guard because it is a selector/audit slice.

## Deferred Boundaries

Direct burst-last recapture behavior, scalar last-beat read-data recapture
semantics, burst-length/runtime/multi-beat recapture, multiple dynamic request
widening, mixed dynamic/static recapture, static busy recapture, dynamic same-ID
queues, scoreboards, backend variants, VHDL, and full AXI manager behavior
remain later exact-owner tasks until `.370` chooses the next bounded owner.
