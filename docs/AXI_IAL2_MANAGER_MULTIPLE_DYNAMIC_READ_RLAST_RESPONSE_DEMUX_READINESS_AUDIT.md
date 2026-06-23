# AXI IAL2 Manager Multiple Dynamic Read RLAST Response-Demux Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.253`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.254`, public contract selection for
bounded multiple dynamic read burst-last/`RLAST` response-demux behavior.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or used:

- `.252` post multiple dynamic read selector:
  `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md`
- `.251` multiple dynamic read single-beat response-demux behavior.
- `.250` multiple dynamic read response-demux contract selection.
- `.249` multiple dynamic read response-demux readiness audit.
- `.247` multiple dynamic write response-demux behavior.
- `.243` dynamic multi-beat read-data output-bank behavior.
- `.240` dynamic runtime beat-count/`RLAST` validation behavior.
- `.238` dynamic report-only raw-`ARLEN` burst-length behavior.
- `.236` bounded dynamic focused-suite cleanup.
- `.234` scalar dynamic read-data behavior.
- `.231` single-active dynamic read burst-last/`RLAST` behavior.
- `.227` single-active dynamic read single-beat behavior.
- Current response-demux/read-data/runtime/multi-beat normalizers, dynamic
  assertion helpers, report/residue wording, focused validation caveats,
  README, ROADMAP_V2, mdBook, Memory, and Knowledge Map.

## Code Findings

The current fail-closed boundary is narrow and explicit:

- `_response_demux_dynamic_read_transaction` now normalizes one or more
  all-dynamic read transactions into a state-list plan.
- `_normalize_response_demux_read` accepts that plan for `single-beat`, but
  rejects multiple dynamic read transactions before the `burst-last` branch
  with the diagnostic that multiple dynamic reads are supported only with
  `response_scope single-beat` in this slice.
- The single-active dynamic burst-last path still accepts the same plan shape
  when there is only one dynamic read state.
- Dynamic capture/release state, generated completion signals, and generated
  response-demux rule emission are already state-list driven after
  normalization admits the states.
- `_response_demux_guard_expr` adds the read `last_signal` to burst-last
  completion guards, so generated completions can remain final-beat only.
- `_response_demux_match_expr` intentionally remains raw `RID == captured_id`
  matching without `RLAST`, which is the right substrate for raw-beat
  active-match/unique-match assertions and later beat-count logic.
- `_response_demux_dynamic_assertion_specs_for_family` is family-generic and
  already emits request onehot0, request no-active-same-ID, active-ID
  uniqueness, response active-match, response unique-match, and
  completion-active assertions for multiple dynamic states.
- `read_data.read` dynamic coverage still requires exactly one dynamic read
  transaction and one generated dynamic completion signal, so read-data over
  multiple dynamic read demux remains a separate fail-closed boundary.

## Why Contract Selection First

Multiple dynamic read burst-last/`RLAST` is not just the `.251` single-beat
contract with `RLAST` added. The public contract must first select:

- whether the first burst-last widening remains all-dynamic and
  response-demux-only;
- whether same-cycle dynamic read requests remain onehot0;
- whether active dynamic IDs must remain pairwise unique;
- how raw read-beat active-match assertions are worded when non-last beats
  should be legal and should not complete the transaction;
- whether response unique-match assertions use raw `RID` matches on every raw
  response beat or final `RID && RLAST` completion matches;
- how generated completion and release rules are named and reported;
- whether read-data, burst-length/runtime validation, and multi-beat
  output-bank behavior remain fail-closed over multiple dynamic read
  burst-last demux in the first implementation; and
- public sample, support-accounting, focused-suite, and HDL validation
  expectations for the later implementation.

Selecting those semantics in `.254` keeps the later implementation bounded and
prevents mixing response-demux widening with read-data/runtime/output-bank
behavior in one slice.

## Selected .254 Boundary

`.254` should select the exact public contract for bounded multiple dynamic
read burst-last/`RLAST` response-demux. It should define:

- source syntax and public sample shape;
- required all-dynamic read-family ownership;
- `response-demux.read response-scope burst-last` and one-bit `last-signal`
  ownership;
- admitted `ARID` capture guards with sibling request and active same-ID
  checks;
- selected-ID/busy lifetime across non-last beats;
- raw `RID` beat matching versus final `RID && RLAST` completion;
- generated completion/release behavior;
- request onehot0, request no-active-same-ID, active-ID uniqueness,
  active-match, unique-match, and completion-active assertion roles;
- report vocabulary and residue;
- fail-closed diagnostics for read-data, burst-length/runtime validation, and
  multi-beat output banks over multiple dynamic read demux;
- focused validation and support-accounting expectations;
- rollback; and
- explicit non-goals.

## Non-Goals

This audit does not implement multiple dynamic read burst-last/`RLAST`
response-demux. It does not change parser, generator, PPIF samples,
support-accounting catalog, validation behavior, generated artifacts, tests,
schedule/check/semantic JSON, or HDL behavior.

These remain later exact owners unless `.254` explicitly selects otherwise:

- generated behavior for multiple dynamic read burst-last/`RLAST`;
- read-data over multiple dynamic read demux;
- burst-length/runtime validation over multiple dynamic read demux;
- multi-beat output banks over multiple dynamic read demux;
- mixed dynamic/static demux;
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
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No focused generator, parser, support-accounting, schedule/check/semantic, or
HDL probes are required because this audit changes no behavior.

## Rollback

Rollback is the `.253` audit commit. Reverting it restores `.253` as the
active readiness audit and removes the `.254` public contract-selection owner.
