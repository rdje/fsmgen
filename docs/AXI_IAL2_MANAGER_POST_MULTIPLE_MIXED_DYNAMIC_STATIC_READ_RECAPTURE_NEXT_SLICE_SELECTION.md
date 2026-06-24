# AXI IAL2 Manager Post Multiple Mixed Dynamic/Static Read Recapture Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.412`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.412` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.413`, a readiness audit for
one-dynamic-plus-two-static mixed dynamic/static read burst-last `RID &&
RLAST` same-cycle release-and-recapture.

No parser, generator, PPIF sample, support-accounting catalog, validation
behavior, generated artifact, test expectation, schedule/check/semantic JSON,
HDL, or runtime behavior changes in this selector.

## Inputs Read

The selector read the newly shipped `.411` one-dynamic-plus-two-static mixed
read single-beat recapture behavior, the `.410` contract, the `.409`
readiness audit, the `.408` post mixed-write selector, the `.407`, `.403`,
`.400`, and `.389` mixed write recapture records, the `.392` and `.396`
mixed read recapture records, the `.299` one-dynamic-plus-two-static mixed
read single-beat response-demux behavior, the `.303`
one-dynamic-plus-two-static mixed read burst-last response-demux behavior,
the `.307`, `.310`, `.312`, and `.314` read-data, raw-`ARLEN`, runtime, and
multi-beat preservation records, and the adjacent one-dynamic-plus-three-static
and two-dynamic-plus-one-static mixed read response-demux records.

The selector also inspected the current read response-demux normalizer,
dynamic/static state builders, release/release-recapture rule helpers,
assertion/report projection helpers, focused `t/1438` expectation surfaces,
support-accounting entries, README, ROADMAP_V2, mdBook, Memory, task tree,
and Knowledge Map.

## Live Baseline

A guarded schedule probe on the existing public burst-last sample passed
under the default RAM guard:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif
```

The guard started with host memory at 85.2% against the default 88% cutoff
and produced a 44340-byte schedule report.

The live report still has:

```text
mode: bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract
response_scope: burst_last
transaction_completion_source:
  generated_multi_mixed_dynamic_static_read_demux_last_beat
generated_assertions:
  axi0_r0_dynamic_request_not_busy
  axi0_r1_static_request_not_busy
  axi0_r2_static_request_not_busy
static_capture: absent
dynamic_capture.transactions[0].release_recapture_rule: absent
```

This is the current public boundary: the demux is generated and
support-accounted, but same-cycle release-and-recapture is not yet selected
for the two-static burst-last sibling.

## Decision

The next exact owner is a readiness audit, not direct implementation.

The selected boundary is the smallest adjacent read-side recapture gap after
`.411`:

- `.411` already proves one-dynamic-plus-two-static single-beat read
  recapture with list-shaped `static_capture[]` and composed static guards.
- `.396` already proves the one-dynamic-plus-one-static burst-last recapture
  policy, final-beat completion source, and raw non-final `RID` preservation.
- `.303` already provides the one-dynamic-plus-two-static burst-last
  response-demux public sample, mode, support-accounting entry, final
  completion pulses, raw beat assertions, and three transaction lifecycle
  states.
- `.307`, `.310`, `.312`, and `.314` already layer scalar read-data,
  raw-`ARLEN`, runtime validation, and multi-beat output banks over the same
  two-static burst-last completion source and must be protected from drift.

The readiness audit is still required because the next behavior combines the
new `.411` list-shaped recapture report shape with the `.396` final-beat
release source:

```text
generated_multi_mixed_dynamic_static_read_demux_last_beat_completion
```

It must also prove that raw non-final `RID` beats continue to assert
ownership without releasing or recapturing, and that scalar read-data,
raw-`ARLEN`, runtime, and multi-beat consumers remain unchanged.

## Alternatives Deferred

Direct implementation is deferred until `.413` records the exact report,
assertion, guard, preservation, and validation contract.

One-dynamic-plus-three-static read recapture remains deferred because the
two-static burst-last sibling is the nearest already-supported follow-up to
`.411` and has a shipped one-static burst-last recapture template.

Two-dynamic-plus-one-static read recapture remains deferred because it adds
the active dynamic-ID uniqueness and no-active-same-ID guard axis in addition
to the mixed static guard composition.

A standalone validation retry after the `.411` focused `t/1438` RAM cutoff is
not selected. The `.411` selected schedule, strict check, semantic JSON,
SystemVerilog, verify-hdl, and direct adapter probes passed; future focused
test retries should be tied to an exact owner and RAM state.

Static-busy-only recapture outside selected public samples, helper/report
cleanup, request arbitration beyond onehot0, dynamic same-ID queues,
scoreboards, queued/blocking policy, profile aliases, direct backend
behavior, backend-language variants, VHDL, and full AXI manager behavior
remain later exact owners.

## Selected Next Leaf

`.413` should audit whether one-dynamic-plus-two-static mixed read
burst-last `RID && RLAST` recapture can be implemented directly or requires a
smaller prerequisite.

The audit must record:

- the current live report baseline for
  `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif`;
- the expected dynamic recapture fields under
  `dynamic_capture.transactions[0]`;
- the expected list-shaped `static_capture[]` entries for `r1` and `r2`;
- the expected final-beat release-recapture source;
- release-only exclusion of same-transaction same-cycle requests;
- dynamic recapture guards across both static requests and both static-ID
  exclusions;
- static recapture guards across dynamic request and sibling static request;
- request assertion renames from request-not-busy to idle-or-releasing;
- raw non-final `RID` preservation;
- scalar read-data, raw-`ARLEN`, runtime, and multi-beat preservation;
- RAM-guarded validation gates and fallback probes; and
- rollback and documentation boundaries.

## Validation

This selector is documentation-only. Validation should cover Knowledge Map
generation/check, mdBook build, memory architecture check, diff whitespace
check, and doctrine checks. No behavior-bearing test expectation is changed
by `.412`.

## Rollback

Rollback is the `.412` selector commit. Reverting it removes the selector
record, fact card, task-tree advancement to `.413`, README/ROADMAP/mdBook
status, Memory pointer update, and Knowledge Map entry, restoring `.412` as
the active next selector.
