# AXI IAL2 Manager Mixed Dynamic/Static Read RLAST Response-Demux Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.278`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.279`, public contract selection for
bounded mixed dynamic/static read burst-last `RID && RLAST` response-demux.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or used:

- `.277` post mixed dynamic/static read demux selector:
  `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION.md`
- `.276` mixed dynamic/static read single-beat `RID` response-demux behavior:
  `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md`
- `.275` mixed dynamic/static read single-beat contract selection.
- `.274` mixed dynamic/static read response-demux readiness audit.
- `.272` mixed dynamic/static write `BID` response-demux behavior.
- `.255` multiple dynamic read burst-last `RID && RLAST` behavior.
- `.254` multiple dynamic read burst-last contract selection.
- `.253` multiple dynamic read burst-last readiness audit.
- `.231` single-active dynamic read burst-last behavior.
- Current response-demux normalization, mixed dynamic/static state, static
  concrete guard/match helpers, last-signal helpers, read-data coverage, and
  support-detail prose in
  `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`.
- Focused validation caveats, support-accounting catalog, README,
  `ROADMAP_V2.md`, mdBook, task tree, Memory, and Knowledge Map.

## Current Boundary

The `.276` mixed dynamic/static read path now accepts exactly one dynamic read
transaction plus one concrete static read transaction when
`response-demux.read.response-scope` is `single-beat`.

The current fail-closed diagnostic for the burst-last probe is:

```text
response_demux.read mixed dynamic/static ID matching supports response_scope single-beat only in this slice
```

The probe used the `.276` public sample, changed `response-scope` to
`burst-last`, and added a one-bit `last-signal`. No behavior changed.

## Code Findings

The lower substrate is close, but the next slice should be contract selection
before implementation.

Ready pieces:

- `_response_demux_mixed_dynamic_static_read_transaction` already creates a
  mixed state-list plan with one dynamic selected-ID/busy state and one static
  concrete busy state.
- Dynamic capture already reserves the static concrete ID away from the
  dynamic `ARID` value.
- Mixed read request onehot0, dynamic request/static-ID exclusion, active
  dynamic/static-ID exclusion, raw response active-match, raw response
  unique-match, and completion-active assertions are already generated for the
  single-beat mixed state set.
- `_normalize_response_demux_read` already validates `response-scope
  burst-last`, requires one-bit `last-signal`, and reports last-beat metadata
  for all-dynamic read burst-last contracts.
- `_response_demux_guard_expr` already adds the read `last_signal` to dynamic
  response-demux completion guards when the normalized read demux entry carries
  `last_signal`.
- `_response_demux_match_expr` intentionally stays raw `RID`-only for
  assertions and matched-read-beat consumers, which matches the all-dynamic
  burst-last precedent: non-final beats should be legal and should still have
  an active unique owner.

Open contract details:

- the static concrete branch of `_response_demux_guard_expr` is currently
  single-beat shaped and does not add `last_signal`, so a future mixed
  burst-last implementation must explicitly select and implement final-beat
  static completion behavior instead of relying on the current helper as-is;
- `_normalize_response_demux_read` currently rejects mixed dynamic/static
  state before the burst-last normalization branch, so the public contract
  needs to define the new mixed burst-last mode and report fields first;
- report vocabulary must distinguish raw beat ownership assertions from
  final-beat generated completion for both dynamic and static transactions;
  and
- read-data, raw `ARLEN`, runtime beat-count validation, and multi-beat output
  banks must remain fail-closed over the mixed burst-last demux until later
  owners select their completion or matched-beat coverage.

## Why Contract Selection First

Mixed dynamic/static read burst-last is not merely the `.276` single-beat
contract with a `last-signal` field added. The public contract must pin down:

- whether the first burst-last shape remains exactly one dynamic read and one
  concrete static read transaction;
- `last-signal` ownership and one-bit validation;
- raw beat ownership assertions using `RID` only;
- final-beat completion rules using `RID && RLAST`;
- static concrete final-beat completion behavior;
- report mode and transaction-completion source names;
- diagnostics for missing/extra last-signal fields and unsupported read-data,
  burst-length/runtime, and multi-beat consumers; and
- public sample/support-accounting naming and validation scope.

Selecting those details in `.279` keeps the later implementation bounded and
prevents mixing response-demux widening with read-data, burst-length/runtime,
or multi-beat output-bank behavior in one slice.

No separate IAL1, IAL0, or SystemVerilog prerequisite is required before
contract selection. The existing lowering path can already carry the needed
read ID signals, one-bit `RLAST` input, dynamic/static state, Boolean guards,
assertions, generated completion pulses, and SystemVerilog emission once the
IAL2 generator admits the mixed burst-last plan.

## Selected .279 Boundary

`.279` should select the exact public contract for bounded mixed dynamic/static
read burst-last `RID && RLAST` response-demux. It should define:

- source syntax and public sample shape;
- required positive-width read ID family with request ID source and response ID
  signal;
- exactly one dynamic read transaction and one concrete static read
  transaction in the selected read family;
- `response-demux.read response-scope burst-last` and one-bit `last-signal`;
- dynamic `ARID` capture guard with static concrete-ID reservation;
- static concrete busy-state capture and release lifetime;
- raw `RID` beat matching versus final `RID && RLAST` completion for dynamic
  and static states;
- request onehot0, dynamic request/static-ID exclusion, active dynamic/static
  exclusion, active-match, unique-match, and completion-active assertion roles;
- report vocabulary, mode names, generated completion source, residue, and
  support-detail movement;
- fail-closed diagnostics for read-data, burst-length/runtime validation,
  multi-beat output banks, multiple mixed transactions, same-cycle widening,
  release-and-recapture, queues, and scoreboards;
- focused validation and support-accounting expectations;
- rollback; and
- explicit non-goals.

## Non-Goals

This audit does not implement mixed dynamic/static read burst-last behavior.
It does not change parser, generator, PPIF samples, support-accounting catalog,
validation behavior, generated artifacts, tests, schedule/check/semantic JSON,
or HDL behavior.

These remain later exact owners unless `.279` explicitly selects otherwise:

- generated behavior for mixed dynamic/static read burst-last `RID && RLAST`;
- read-data over mixed dynamic/static read demux;
- burst-length/runtime validation over mixed dynamic/static read demux;
- multi-beat output banks over mixed dynamic/static read demux;
- multiple mixed dynamic/static transactions;
- same-cycle request widening beyond onehot0;
- same-cycle release-and-recapture;
- dynamic same-ID ordering;
- dynamic same-ID queues and scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

## Validation

Audit validation is documentation and continuity only:

```bash
perl -Iperl -MFSM::Adapter::IAL2::PPIF -e '...mixed burst-last negative probe...'
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No focused generator, parser, support-accounting, schedule/check/semantic, or
HDL probes are required because this audit changes no behavior.

## Rollback

Rollback is the `.278` audit commit. Reverting it restores `.278` as the active
readiness audit and removes the `.279` public contract-selection owner.
