# AXI IAL2 Manager Three-Static Mixed Dynamic/Static Read Recapture Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.419`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.419` ships
one-dynamic-plus-three-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture for the AXI manager capacity/status IAL2
object.

The support-accounted public sample is unchanged:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif
```

No new PPIF syntax is required. The behavior is bounded to exactly one
dynamic read transaction, exactly three pairwise-distinct concrete static
read transactions, and `response-scope single-beat`.

## Public Shape

The shipped behavior uses the existing explicit multiple mixed
dynamic/static read single-beat response-demux source shape:

```lisp
(transactions
  (read r0
    (tag rd0)
    (request axi0_r0_request)
    (completion axi0_r0_complete)
    (id dynamic))
  (read r1
    (tag rd1)
    (request axi0_r1_request)
    (completion axi0_r1_complete)
    (id (value 3)))
  (read r2
    (tag rd2)
    (request axi0_r2_request)
    (completion axi0_r2_complete)
    (id (value 5)))
  (read r3
    (tag rd3)
    (request axi0_r3_request)
    (completion axi0_r3_complete)
    (id (value 7))))

(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))
```

The read ID family still supplies `axi0_arid` and `axi0_rid` at width 4.

## Generated Behavior

FSMGen now emits a dynamic release-recapture rule for `r0`:

```text
axi0_r0_dynamic_id_release_recapture
```

The rule fires when an admitted `r0` read request arrives in the same cycle as
the generated `r0` completion while `axi0_r0_dynamic_busy_q` is active. It
also requires no admitted `r1`, `r2`, or `r3` static request and requires
`axi0_arid` to be different from all reserved static IDs: `4'd3`, `4'd5`,
and `4'd7`. It captures the new `axi0_arid` and keeps
`axi0_r0_dynamic_busy_q` asserted.

FSMGen also emits static release-recapture rules for `r1`, `r2`, and `r3`:

```text
axi0_r1_static_busy_release_recapture
axi0_r2_static_busy_release_recapture
axi0_r3_static_busy_release_recapture
```

Each static rule fires when the matching admitted static read request arrives
in the same cycle as the matching generated completion while that static busy
slot is active. It blocks the admitted dynamic request and both admitted
sibling static requests, then keeps the matching static busy bit asserted.

The release-only rules now exclude their own same-transaction requests:

```text
axi0_r0_dynamic_id_release: axi0_r0_complete && axi0_r0_dynamic_busy_q && !axi0_r0_request
axi0_r1_static_busy_release: axi0_r1_complete && axi0_r1_static_busy_q && !axi0_r1_request
axi0_r2_static_busy_release: axi0_r2_complete && axi0_r2_static_busy_q && !axi0_r2_request
axi0_r3_static_busy_release: axi0_r3_complete && axi0_r3_static_busy_q && !axi0_r3_request
```

The response-demux match rules remain single-beat matches and still use
pre-update state:

```text
axi0_read_complete && axi0_r0_dynamic_busy_q && axi0_rid == axi0_r0_dynamic_id_q
axi0_read_complete && axi0_r1_static_busy_q  && axi0_rid == 4'd3
axi0_read_complete && axi0_r2_static_busy_q  && axi0_rid == 4'd5
axi0_read_complete && axi0_r3_static_busy_q  && axi0_rid == 4'd7
```

## Report Contract

The response-demux mode and scope remain:

```text
bounded_multi_mixed_dynamic_static_read_rid_demux_contract
response_scope: single_beat
transaction_completion_source: generated_multi_mixed_dynamic_static_read_demux
transaction_completion_semantics: matched_dynamic_or_static_concrete_id_single_beat
```

The dynamic capture report keeps the existing transaction-list shape and now
adds recapture fields to `dynamic_capture.transactions[0]`:

```yaml
dynamic_capture:
  transactions:
    - transaction: r0
      selected_id_signal: axi0_r0_dynamic_id_q
      busy_signal: axi0_r0_dynamic_busy_q
      capture_rule: axi0_r0_dynamic_id_capture
      release_rule: axi0_r0_dynamic_id_release
      release_recapture_rule: axi0_r0_dynamic_id_release_recapture
      same_cycle_release_recapture_policy: mixed_dynamic_static_dynamic_read
      release_recapture_source: generated_multi_mixed_dynamic_static_read_demux_completion
      release_recapture_transaction: r0
```

The read report now includes list-shaped static busy lifecycle entries for
`r1`, `r2`, and `r3`. Each entry uses
`same_cycle_release_recapture_policy: mixed_dynamic_static_static_read` and
`release_recapture_source:
generated_multi_mixed_dynamic_static_read_demux_completion`.

Generated assertions for the selected sample are now:

```text
axi0_r0_dynamic_request_idle_or_releasing
axi0_r1_static_request_idle_or_releasing
axi0_r2_static_request_idle_or_releasing
axi0_r3_static_request_idle_or_releasing
axi0_read_mixed_dynamic_static_request_onehot0
axi0_r0_r1_read_dynamic_request_not_static_id
axi0_r0_r1_read_dynamic_active_not_static_id
axi0_r0_r2_read_dynamic_request_not_static_id
axi0_r0_r2_read_dynamic_active_not_static_id
axi0_r0_r3_read_dynamic_request_not_static_id
axi0_r0_r3_read_dynamic_active_not_static_id
axi0_read_mixed_dynamic_static_response_active_match
axi0_r0_r1_read_mixed_dynamic_static_response_unique_match
axi0_r0_r2_read_mixed_dynamic_static_response_unique_match
axi0_r0_r3_read_mixed_dynamic_static_response_unique_match
axi0_r1_r2_read_mixed_dynamic_static_response_unique_match
axi0_r1_r3_read_mixed_dynamic_static_response_unique_match
axi0_r2_r3_read_mixed_dynamic_static_response_unique_match
axi0_r0_dynamic_completion_active
axi0_r1_static_completion_active
axi0_r2_static_completion_active
axi0_r3_static_completion_active
```

## Preservation

The implementation preserves public syntax, support-accounting identity,
static ID reservations for `4'd3`, `4'd5`, and `4'd7`, generated
response-demux rules, generated completion signals, onehot0 mixed read
request policy, dynamic request/static-ID exclusion assertions, active
dynamic/static-ID exclusion assertions, response active-match, pairwise
response unique-match, and completion-active assertions.

The one-dynamic/one-static mixed read recapture report keeps singular
`static_capture` and `generated_mixed_dynamic_static_read_demux_completion`.

The one-dynamic-plus-two-static mixed read single-beat and burst-last
recapture reports keep their existing list-shaped recapture contracts.

The one-dynamic-plus-three-static mixed read burst-last sample remains outside
this owner: it still has no `static_capture` and no release-recapture fields.

The two-dynamic-plus-one-static mixed read samples remain outside this owner:
they still have no release-recapture fields.

Three-static scalar read-data, raw-`ARLEN`, runtime beat-count/`RLAST`
validation, and multi-beat output-bank consumers remain unchanged.

## Validation

Closeout validation covered syntax checks:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
```

Both syntax checks passed.

The guarded selected schedule probe was attempted under the default 88% host
RAM cutoff:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif
```

The RAM guard stopped the probe before completion because host memory was
already 89.9%, above the default 88% cutoff. No cutoff was raised.

Focused `t/1438` selected-case coverage was also attempted under the default
guard:

```bash
scripts/run_with_ram_guard.sh -- env FSMGEN_DYNAMIC_CASE_FILTER=mixed_dynamic_static_read_demux_multi_static3 FSMGEN_DYNAMIC_SKIP_CLI_JSON=1 prove -Iperl t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
```

The RAM guard stopped that probe before completion at 90.0% host memory. No
cutoff was raised.

Smaller direct Perl probes verified the selected normalizer/rule path:

```text
static_capture_count = 3
dynamic_static_request_blocks = 3
dynamic_static_id_blocks = 3
dynamic_release_recapture_rule_headers = 1
static_release_recapture_rule_headers = 3
assertions_checked = 1
```

Direct preservation probes also confirmed that the two-static single-beat
recapture path still has two static recapture entries, the three-static
burst-last path still has no static recapture entry, and the
two-dynamic-plus-one-static path still has no recapture entry.

Continuity gates also pass as part of closeout: Knowledge Map
generation/check, mdBook build, memory architecture check, docs relative path
check, diff whitespace check, and doctrine checks.

## Deferred Boundaries

One-dynamic-plus-three-static burst-last read recapture,
two-dynamic-plus-one-static read recapture, layered recapture-specific
consumer changes, static-busy-only recapture outside selected public mixed
samples, request arbitration beyond onehot0, dynamic same-ID queues,
scoreboards, queued/blocking policy, profile aliases, direct backend
behavior, backend-language variants, VHDL, and full AXI manager behavior
remain later exact owners.

## Rollback

Rollback is the `.419` implementation commit. Reverting it removes the
one-dynamic-plus-three-static mixed read single-beat release-recapture
widening, focused expectation update, behavior docs, and facts, restoring the
`.418` selected contract as the active frontier.
