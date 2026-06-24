# AXI IAL2 Manager Multiple Mixed Dynamic/Static Read RLAST Recapture Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.413`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.413` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.414`, public contract selection for
one-dynamic-plus-two-static mixed dynamic/static read burst-last `RID &&
RLAST` same-cycle release-and-recapture.

No parser, generator, PPIF sample, support-accounting catalog, validation
behavior, generated artifact, test expectation, schedule/check/semantic JSON,
HDL, or runtime behavior changes in this audit.

## Baseline

The support-accounted public sample already exists and is unchanged:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif
```

It uses the generated multiple mixed read burst-last response-demux contract:

```text
mode: bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract
response_scope: burst_last
transaction_completion_source:
  generated_multi_mixed_dynamic_static_read_demux_last_beat
transaction_completion_semantics:
  matched_dynamic_or_static_concrete_id_and_last_signal
```

A guarded baseline schedule probe passed:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif
```

The guard started at 86.3% host memory against the default 88% cutoff and
produced a 44340-byte report.

The live report still has request-not-busy assertions and no recapture report
surface:

```text
generated_assertions:
  axi0_r0_dynamic_request_not_busy
  axi0_r1_static_request_not_busy
  axi0_r2_static_request_not_busy
static_capture: absent
dynamic_capture.transactions[0].release_recapture_rule: absent
```

This confirms `.413` is an audit/contract-selection step, not a behavior
closeout.

## Readiness Findings

No lower parser or PPIF syntax prerequisite is needed. The `.303` public
sample already owns `response-scope burst-last`, a one-bit `last-signal`, one
dynamic read transaction, two pairwise-distinct concrete static read
transactions, and generated transaction completions.

No support-accounting prerequisite is needed. The sample is already in the
support catalog and focused dynamic transaction-ID coverage.

No new IAL1 or HDL lowering primitive is needed. Existing generated state,
rules, pulse outputs, assertions, and SystemVerilog lowering already carry
dynamic selected-ID state, static busy state, release rules, release-recapture
rules, generated assertions, and final-beat completion pulses.

No report-schema prerequisite is needed. `.411` already widened the
one-dynamic-plus-two-static single-beat read report to use
`dynamic_capture.transactions[0]` recapture fields plus list-shaped
`static_capture[]`. The same shape can describe the burst-last sibling with a
different completion source.

The current implementation gap is narrow and explicit: the read burst-last
normalizer marks one-dynamic-plus-one-static mixed read recapture, but leaves
the multi-mixed branch unmarked. The read recapture marker itself already
accepts exactly one dynamic read transaction and one or two static read
transactions, and defaults `release_recapture_source` from
`transaction_completion_source . '_completion'`. For this sample, that gives:

```text
generated_multi_mixed_dynamic_static_read_demux_last_beat_completion
```

The rule and assertion helpers are already policy-driven:

- dynamic release-recapture rules add static request blocks and static-ID
  exclusion blocks for mixed dynamic/static dynamic recapture;
- static release-recapture rules add dynamic request and sibling static
  request blocks;
- release-only rules exclude same-transaction same-cycle requests when a
  release-recapture policy is present; and
- request assertions switch from request-not-busy to idle-or-releasing when
  the matching dynamic or static state carries recapture policy metadata.

## Contract Selection Requirements

`.414` should select the exact public contract before behavior changes.

The selected behavior should keep public source syntax, support identity,
mode, scope, last-signal metadata, completion semantics, transaction lists,
static ID reservations, generated response-demux match rules, generated
completion outputs, raw `RID` active-match assertions, pairwise raw `RID`
unique-match assertions, and completion-active assertions unchanged.

The dynamic report should add recapture fields to
`response_demux.read.dynamic_capture.transactions[0]`:

```text
release_recapture_rule: axi0_r0_dynamic_id_release_recapture
same_cycle_release_recapture_policy: mixed_dynamic_static_dynamic_read
release_recapture_source:
  generated_multi_mixed_dynamic_static_read_demux_last_beat_completion
release_recapture_transaction: r0
```

The static report should add list-shaped entries for `r1` and `r2`:

```text
static_capture[].release_recapture_rule:
  axi0_r1_static_busy_release_recapture
  axi0_r2_static_busy_release_recapture
static_capture[].same_cycle_release_recapture_policy:
  mixed_dynamic_static_static_read
static_capture[].release_recapture_source:
  generated_multi_mixed_dynamic_static_read_demux_last_beat_completion
```

The generated assertion list should replace:

```text
axi0_r0_dynamic_request_not_busy
axi0_r1_static_request_not_busy
axi0_r2_static_request_not_busy
```

with:

```text
axi0_r0_dynamic_request_idle_or_releasing
axi0_r1_static_request_idle_or_releasing
axi0_r2_static_request_idle_or_releasing
```

The dynamic release-recapture rule should require the admitted `r0` request,
the generated final-beat `r0` completion, active `r0` dynamic busy state, no
admitted `r1` or `r2` static request, and `axi0_arid` not equal to `4'd3` or
`4'd5`.

Each static release-recapture rule should require its admitted static request,
its generated final-beat completion, active static busy state, no admitted
dynamic request, and no admitted sibling static request.

Release-only rules should exclude their own same-transaction request:

```text
axi0_r0_dynamic_id_release: ... && !axi0_r0_request
axi0_r1_static_busy_release: ... && !axi0_r1_request
axi0_r2_static_busy_release: ... && !axi0_r2_request
```

## Preservation Requirements

Raw non-final `RID` beats must remain ownership evidence only. They should
continue to feed raw active-match, pairwise unique-match, read-data lane
capture, and beat-count paths where those consumers apply, but they must not
release or recapture any transaction until the generated `RID && RLAST`
completion pulse fires.

The following sibling contracts must remain unchanged:

- `.396` one-dynamic-plus-one-static mixed read burst-last recapture keeps
  singular `static_capture` and
  `generated_mixed_dynamic_static_read_demux_last_beat_completion`;
- `.303` one-dynamic-plus-two-static mixed read burst-last response-demux
  keeps mode, final completion source, raw beat assertions, and generated
  completion rules;
- `.307` scalar last-beat read-data over this demux keeps
  `generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`;
- `.310` report-only raw-`ARLEN` capture keeps request-captured ARLEN and no
  runtime assertions;
- `.312` runtime beat-count/`RLAST` validation keeps raw matched-beat
  counters and runtime assertions;
- `.314` multi-beat output banks keep raw matched-beat lane capture and
  final completion/release boundaries;
- `.326` three-static read burst-last response-demux remains no-recapture;
  and
- `.347` two-dynamic-plus-one-static read burst-last response-demux remains
  no-recapture.

## Validation Plan For Later Behavior

The `.414` contract selection should require the later implementation owner
to run syntax checks for the generator and focused tests, then guarded
selected probes where RAM permits:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --output /tmp/fsmgen_multi_static_read_rlast_recapture.sv ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_multi_static_read_rlast_recapture_verify.sv ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif
```

Focused `t/1438` should use the selected burst-last filter and
`FSMGEN_DYNAMIC_SKIP_CLI_JSON=1` when needed to avoid the known high-memory
CLI JSON path. Direct adapter probes should verify the selected report and
the `.396`, `.303`, `.307`, `.310`, `.312`, `.314`, `.326`, and `.347`
preservation boundaries if full focused validation trips the RAM guard.

## Deferred Boundaries

Direct implementation, one-dynamic-plus-three-static read recapture,
two-dynamic-plus-one-static read recapture, static-busy-only recapture
outside selected public samples, request arbitration beyond onehot0, dynamic
same-ID queues, scoreboards, queued/blocking policy, profile aliases, direct
backend behavior, backend-language variants, VHDL, and full AXI manager
behavior remain later exact owners.

## Rollback

Rollback is the `.413` audit commit. Reverting it removes the readiness audit,
fact card, task-tree advancement to `.414`, README/ROADMAP/mdBook status,
Memory pointer update, and Knowledge Map entry, restoring `.413` as the active
audit leaf.
