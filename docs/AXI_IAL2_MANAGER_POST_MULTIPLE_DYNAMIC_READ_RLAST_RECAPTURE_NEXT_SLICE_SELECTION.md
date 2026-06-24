# AXI IAL2 Manager Post Multiple Dynamic Read RLAST Recapture Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.386`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.386` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.387`, a readiness audit for mixed
dynamic/static same-cycle release-and-recapture.

The selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, or runtime behavior.

## Rationale

All selected all-dynamic recapture siblings are now covered:

- single-active dynamic write `BID`;
- single-active dynamic read single-beat `RID`;
- single-active dynamic read burst-last `RID && RLAST`;
- multiple all-dynamic write `BID`;
- multiple all-dynamic read single-beat `RID`; and
- multiple all-dynamic read burst-last `RID && RLAST`.

The next useful boundary is mixed dynamic/static recapture. It is the closest
remaining same-cycle lifecycle shape because existing mixed dynamic/static
response-demux already owns:

- dynamic selected-ID and busy state;
- static concrete busy state;
- onehot0 mixed dynamic/static request policy;
- dynamic request/static concrete-ID exclusion;
- active dynamic/static concrete-ID exclusion;
- raw response active-match and unique-match assertions; and
- dynamic/static completion-active assertions.

It is not safe to jump directly to behavior. Static transactions do not
capture a selected ID; they own only a busy bit tied to a concrete ID. A
same-cycle static request plus static completion therefore needs explicit
static release-and-recapture semantics. Dynamic mixed recapture also differs
from all-dynamic recapture because the dynamic request must remain excluded
from every selected static concrete ID while sibling request onehot0 and raw
response unique-match assertions stay intact.

Read-side mixed burst-last and layered read-data/raw-`ARLEN`/runtime/multi-beat
consumers add another preservation stack. A readiness audit should decide the
right first mixed owner instead of letting write, read, static-busy, and
payload preservation semantics blur into one implementation slice.

## Selected .387 Scope

`.387` should audit mixed dynamic/static same-cycle release-and-recapture
readiness across the existing shipped mixed dynamic/static response-demux
family, with emphasis on the smallest support-accounted samples:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif
```

The audit should decide whether the next exact owner should be public contract
selection for mixed write, mixed read single-beat, mixed read burst-last,
static-busy-only recapture, a validation retry, support-detail/report cleanup,
or a narrower prerequisite.

The audit must record:

- public source syntax, support-accounting identity, and mode preservation
  expectations for candidate samples;
- dynamic release-recapture report vocabulary and source naming;
- static release-recapture report vocabulary, if selected;
- release-only exclusion semantics for same-transaction same-cycle requests;
- dynamic release-recapture guards with static concrete-ID reservation;
- static release-recapture guards for concrete-ID busy slots;
- whether request-not-busy assertions become idle-or-releasing for dynamic,
  static, or both transaction classes;
- preservation of onehot0 mixed request policy, dynamic request/static-ID
  exclusion, active dynamic/static-ID exclusion, raw response active/unique
  match, and completion-active assertions;
- read-side `RID && RLAST`, raw non-final beats, scalar read-data, raw
  `ARLEN`, runtime beat-count/`RLAST`, and multi-beat output-bank preservation
  implications;
- validation gates and host-memory caveats;
- rollback boundary; and
- README, ROADMAP_V2, mdBook, task-tree, Memory, and Knowledge Map updates.

## Deferred Boundaries

This selector does not implement behavior. It does not select request
arbitration beyond onehot0, multiple mixed dynamic/static transaction
widening, dynamic same-ID queues, scoreboards, queued/blocking policy, profile
aliases, direct backend behavior, backend-language variants, VHDL, or full AXI
manager behavior.

## Validation

Closeout for `.386` is documentation and continuity only:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No focused generator, parser, support-accounting, schedule/check/semantic, or
HDL probes are required because this selector changes no behavior.

## Rollback

Rollback is the `.386` selector commit. Reverting it restores `.386` as the
active frontier and removes `.387` as the selected mixed dynamic/static
recapture readiness audit.
