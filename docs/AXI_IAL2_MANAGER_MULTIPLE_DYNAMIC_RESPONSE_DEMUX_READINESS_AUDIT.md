# AXI IAL2 Manager Multiple Dynamic Response-Demux Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.245`

Date: 2026-06-22

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.246`, public contract selection
for bounded multiple dynamic write response-demux behavior.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or used:

- `.244` post dynamic multi-beat selector:
  `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_MULTI_BEAT_NEXT_SLICE_SELECTION.md`
- `.243` dynamic multi-beat behavior:
  `docs/AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_BEHAVIOR.md`
- `.242` dynamic multi-beat readiness audit.
- `.240` dynamic runtime-validation behavior and `.238` report-only dynamic
  raw-`ARLEN` behavior.
- `.236` bounded dynamic focused-suite cleanup.
- `.234` scalar dynamic read-data behavior.
- `.231` dynamic read burst-last response-demux behavior.
- `.227` dynamic read single-beat response-demux behavior.
- `.223` dynamic write response-demux behavior.
- `.219` dynamic transaction-ID metadata behavior.
- Response-demux normalizers, dynamic state helpers, generated storage/rule
  helpers, match helpers, assertion helpers, report/residue wording, and
  focused dynamic tests.
- README, `ROADMAP_V2.md`, mdBook, task tree, Memory, and Knowledge Map.

## Live Probe

A temporary `/tmp` mutation of
`ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif` added a
second write transaction:

```text
(write w1
  (tag wr1)
  (request axi0_w1_request)
  (completion axi0_w1_complete)
  (id dynamic))
```

Strict check fails closed at the expected current boundary:

```text
AXI manager capacity/status IAL2 contract response_demux.write dynamic ID
matching supports exactly one dynamic write transaction in this slice
```

No repository file was changed by the probe.

## Code Findings

The current normalizers reject the target family before generated artifacts:

- `_response_demux_dynamic_write_transaction` requires exactly one dynamic
  write transaction and no additional write transactions.
- `_response_demux_dynamic_read_transaction` has the same one-dynamic and
  no-additional-read shape.
- Both dynamic helpers reject same-family auto-ID lifecycle and same-ID
  ordering policy while selected.

After a dynamic state is normalized, much of the lower substrate already
iterates state lists:

- `_response_demux_dynamic_storage_lines` emits selected-ID and busy storage
  for every dynamic state in the entry.
- `_response_demux_dynamic_capture_rule_lines` and
  `_response_demux_dynamic_release_rule_lines` emit capture/release rules for
  each dynamic state.
- `_response_demux_rule_lines` iterates
  `_response_demux_transaction_states`, so response completion rules are
  already state-list shaped.
- `_response_demux_transaction_states_for_family` merges dynamic, auto-ID,
  and queue-head states after normalization.

The unsafe gap is public semantics, not syntax. `_response_demux_match_expr`
matches a dynamic response with only `busy && response_id == selected_id`.
If two dynamic transactions are active with the same captured ID, one raw
response can match both. Current dynamic assertions prove request-not-busy,
some active dynamic response match, and completion while busy, but they do
not prove pairwise uniqueness across multiple dynamic states. Capture guards
also check only the local transaction's busy bit, not sibling active IDs or
same-cycle sibling requests.

## Selected .246 Boundary

`.246` should select the public contract before implementation. The contract
selection should define, at minimum:

- the first family: bounded multiple dynamic write response-demux, because
  write response matching has no `RLAST`, read-data, burst-length, or
  per-beat output-bank coupling;
- whether the first behavior shape requires all write transactions in the
  family to be dynamic, or whether mixed dynamic/static write transactions
  remain deferred;
- how to prevent ambiguous same-ID dynamic responses, likely through a
  generated dynamic same-ID conflict assertion/reject boundary rather than a
  queue/scoreboard in the first behavior slice;
- how simultaneous accepted dynamic write requests are handled when their
  request IDs compare equal;
- generated report vocabulary for multiple per-transaction selected-ID/busy
  state, capture/release rules, completion signals, active-match and
  unique-match assertions, and residue movement;
- the public PPIF sample and support-accounting identity expected for the
  later implementation slice;
- focused `t/1438` coverage expectations; and
- explicit deferrals for multiple dynamic read demux, mixed dynamic/static
  demux, dynamic same-ID queues, scoreboards, direct backend behavior,
  backend-language variants, and VHDL.

## Non-Goals

`.246` should not implement behavior. It should not change parser,
generator, PPIF samples, support accounting, validation behavior, generated
artifacts, tests, schedule/check/semantic JSON, or HDL behavior except to
record the selected later owner. Multiple dynamic read demux, mixed
dynamic/static demux, dynamic same-ID queues, scoreboards, direct backend,
backend-language variants, and VHDL remain outside `.246`.

## Validation

Audit validation covered code review, the temporary multiple-dynamic-write
fail-closed probe, live docs, mdBook, Memory, Knowledge Map, and doctrine
gates. No behavior changed.

## Rollback

Rollback is the `.245` audit commit. Reverting it restores `.245` as the
active readiness audit and removes the `.246` contract-selection owner.
