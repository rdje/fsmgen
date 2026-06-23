# AXI IAL2 Manager Post Multiple Dynamic Read Response-Demux Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.252`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.253`, readiness audit for multiple
dynamic read burst-last/`RLAST` response-demux after generated bounded
multiple dynamic read single-beat response-demux shipped in `.251`.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The selector read or used:

- `.251` multiple dynamic read single-beat response-demux behavior:
  `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_BEHAVIOR.md`
- `.250` multiple dynamic read response-demux contract selection.
- `.249` multiple dynamic read response-demux readiness audit.
- `.247` multiple dynamic write response-demux behavior.
- `.243` dynamic multi-beat output-bank behavior.
- `.240` dynamic runtime beat-count/`RLAST` validation behavior.
- `.238` dynamic report-only raw-`ARLEN` burst-length behavior.
- `.236` bounded dynamic focused-suite cleanup.
- `.234` scalar dynamic read-data behavior.
- `.231` single-active dynamic read burst-last/`RLAST` behavior.
- `.227` single-active dynamic read single-beat behavior.
- Current response-demux/read-data/runtime/multi-beat residue reports,
  focused validation caveats, README, ROADMAP_V2, mdBook, Memory, and
  Knowledge Map.

## Why Burst-Last Readiness Is Next

The `.251` implementation removes only the all-dynamic read-family,
single-beat, response-demux-only shape from residue. The next read-side
dependency is multiple dynamic read burst-last/`RLAST`, because it defines the
shared response-demux lifetime that later read-data, burst-length/runtime
validation, and multi-beat output-bank widening would consume.

The single-active `.231` burst-last behavior already proves the narrow
single-transaction pieces:

- admitted `ARID` capture;
- selected-ID/busy lifetime across non-last beats;
- raw accepted read beat matching by `RID == captured_id`;
- generated completion only when the raw matched beat also has one-bit
  `RLAST`; and
- raw-beat active-match assertions that remain valid on non-last beats.

The multiple-read `.251` behavior proves a different set of pieces:

- per-transaction selected-ID/busy state;
- sibling request and active same-ID guards;
- request onehot0;
- active dynamic ID uniqueness;
- response active-match and unique-match assertions; and
- generated completion/release for single-beat `RID` matches.

The next audit must determine whether those two proven boundaries can be
combined directly or whether a narrower contract-selection prerequisite is
needed. It must also decide how active-match and unique-match assertions reason
about raw non-last beats, whether request onehot0 and active same-ID policies
remain sufficient, and how report vocabulary distinguishes raw beat matching
from final `RID && RLAST` completion.

## Selected .253 Boundary

`.253` should audit multiple dynamic read burst-last/`RLAST`
response-demux readiness. It should decide whether the next owner is:

- direct generated behavior for all-dynamic multiple-read burst-last/`RLAST`
  response-demux;
- public contract selection before implementation;
- lower helper cleanup around raw matched read beats, `last_signal`, or
  dynamic assertion roles;
- report/static/support cleanup; or
- a narrower prerequisite.

The audit should cover:

- read-family shape and whether all selected read transactions must remain
  dynamic;
- `response-demux.read response-scope burst-last` with one-bit `last-signal`;
- per-transaction selected-ID/busy state and lifetime across non-last beats;
- admitted `ARID` capture guards with sibling request and active same-ID
  policies;
- raw `RID` beat matching versus final `RID && RLAST` completion;
- response active-match and unique-match assertion antecedents on raw read
  beats;
- generated completion/release behavior;
- whether read-data remains fail-closed for multiple dynamic read burst-last
  in the first implementation;
- public PPIF sample and support-accounting expectations for any later
  implementation;
- focused `t/1438` and parser/generator expectation impact;
- direct SystemVerilog and `--verify-hdl` validation boundaries;
- rollback; and
- explicit residue.

## Non-Goals

`.253` should not implement behavior. It should not change parser, generator,
PPIF samples, support-accounting catalog, validation behavior, generated
artifacts, tests, schedule/check/semantic JSON, or HDL behavior unless it
explicitly selects a later implementation owner.

The selector intentionally leaves these as later exact owners until `.253`
finishes:

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

## Validation Gates

For this selector, documentation and continuity gates are sufficient:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No focused generator, parser, support-accounting, schedule/check/semantic, or
HDL probes are required because this slice changes no behavior.

## Rollback

Rollback is the `.252` selector commit. Reverting it restores `.252` as the
active post-implementation selector and removes the `.253` readiness-audit
selection record.
