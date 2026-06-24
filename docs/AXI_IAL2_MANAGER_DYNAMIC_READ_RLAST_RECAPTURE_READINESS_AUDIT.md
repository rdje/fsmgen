# AXI IAL2 Manager Dynamic Read RLAST Recapture Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.370`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.370` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.371`, public contract selection for
single-active dynamic read burst-last `RID && RLAST` same-cycle
release-and-recapture.

The audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Current Boundary

The currently shipped burst-last dynamic read response-demux sample is:

```text
ppif/axi_manager_capacity_status_dynamic_read_response_demux_burst_last.ppif
```

It uses existing `response-demux.read` syntax with:

- exactly one `(id dynamic)` read transaction;
- `response-scope burst-last`;
- one-bit `last-signal axi0_rlast`;
- raw read response event `axi0_read_complete`; and
- generated transaction completion `axi0_r0_complete`.

The current report mode is:

```text
bounded_dynamic_read_rid_rlast_demux_contract
```

The current assertion list still contains:

```text
axi0_r0_dynamic_request_not_busy
axi0_read_dynamic_response_active_match
axi0_r0_dynamic_completion_active
```

The implementation deliberately leaves burst-last entries unmarked by the
single-beat recapture helper. Only `response-scope single-beat` with one
dynamic read and no static reads currently receives
`same_cycle_release_recapture_policy: single_active_dynamic_read`.

## Audit Findings

The burst-last recapture shape has a clear behavior target but needs a public
contract selection before code changes.

The response-demux rule already separates raw accepted response beats from the
generated final completion pulse:

```text
axi0_read_complete && axi0_r0_dynamic_busy_q &&
  (axi0_rid == axi0_r0_dynamic_id_q) && axi0_rlast
```

Matched non-last beats keep the dynamic read active and must not release or
recapture. A later behavior owner should only consider release-and-recapture on
the generated final completion pulse. The raw active-match assertion should
remain raw-beat based so matched non-last beats continue to be legal.

The last-beat consumers make the contract broader than the single-beat `.368`
shape:

- scalar last-beat dynamic read-data captures `RDATA/RRESP` under the generated
  final completion pulse;
- report-only raw-`ARLEN` captures request metadata but still uses the generated
  final completion for payload capture;
- runtime beat-count/`RLAST` validation increments counters on raw matched
  beats and checks the final `RLAST` boundary; and
- multi-beat output banks capture per-beat payloads from raw matched dynamic
  read beats while the final completion still ends the transaction.

Those consumers can plausibly preserve their existing payload and validation
contracts if the response match uses the pre-update selected ID and recapture
updates only the next-cycle selected ID/busy state. The contract selector must
make that ordering explicit before an implementation leaf changes generator
behavior.

## Selected Next Owner

`.371` should select the public burst-last recapture contract. It should decide:

- whether the public source syntax remains exactly the existing burst-last
  response-demux syntax;
- whether the existing mode string remains
  `bounded_dynamic_read_rid_rlast_demux_contract`;
- whether `same_cycle_release_recapture_policy` reuses
  `single_active_dynamic_read` or uses a burst-last-specific value;
- the exact `release_recapture_rule`, `release_recapture_source`, and
  `release_recapture_transaction` report fields;
- whether `axi0_r0_dynamic_request_not_busy` is replaced by
  `axi0_r0_dynamic_request_idle_or_releasing` for burst-last;
- how to phrase raw-beat active-match and final completion-active assertion
  preservation;
- which existing last-beat read-data samples are preservation consumers in the
  first behavior owner; and
- which burst-length/runtime/multi-beat recapture implications remain later
  owners.

## Non-Goals

`.371` should not implement burst-last recapture unless it explicitly creates a
later implementation leaf. It should not change parser, generator, PPIF
samples, support accounting, tests, schedule/check/semantic JSON, HDL output,
or report behavior.

Multiple dynamic request widening, mixed dynamic/static recapture, static busy
recapture, dynamic same-ID queues, scoreboards, queued/blocking policy, profile
aliases, direct backend behavior, backend-language variants, VHDL, and full AXI
manager behavior remain later exact owners.

## Validation

Closeout for this audit used the documentation/doctrine gate set:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

Focused guarded `fsmgen` probes are useful for `.371` if host memory permits,
but this audit does not require runtime behavior probes because it changes no
generator behavior.
