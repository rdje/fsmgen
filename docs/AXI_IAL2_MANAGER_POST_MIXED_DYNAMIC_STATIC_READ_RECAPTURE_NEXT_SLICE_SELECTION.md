# AXI IAL2 Manager Post Mixed Dynamic Static Read Recapture Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.393`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.393` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.394`, readiness audit for mixed
dynamic/static read burst-last `RID && RLAST` same-cycle
release-and-recapture.

The selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, or runtime behavior.

## Evidence Read

The selector read or used:

- `.392` mixed dynamic/static read single-beat `RID` recapture behavior.
- `.391` mixed read recapture contract selection.
- `.390` post mixed write recapture selector.
- `.389` mixed dynamic/static write `BID` recapture behavior.
- `.387` mixed dynamic/static recapture readiness audit.
- Mixed read burst-last response-demux behavior over `RID && RLAST`.
- Mixed read-data, raw-`ARLEN`, runtime-validation, and multi-beat
  preservation records over generated mixed read response-demux.
- Multiple mixed dynamic/static read/write behavior and cardinality records.
- Static concrete busy lifecycle and recapture implications from mixed write
  and mixed read single-beat recapture.
- Current focused t/1436/t1437/t1438 expectation surfaces, support accounting,
  README, ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map.

The selected next audit also inherits the `.392` preservation probe result:
the mixed read burst-last public sample still reports
`bounded_mixed_dynamic_static_read_rid_rlast_demux_contract`,
`response_scope: burst_last`, `last_signal: axi0_rlast`, completion source
`generated_mixed_dynamic_static_read_demux_last_beat`, request-not-busy
assertions, no read-side release-recapture policy, and no `static_capture`
block.

## Rationale

After `.392`, mixed dynamic/static read single-beat recapture has shipped and
the nearest sibling is mixed dynamic/static read burst-last recapture. That
shape should not jump directly to behavior implementation because it adds a
final-beat boundary on top of the single-beat dynamic/static lifecycle.

The next owner should audit whether the burst-last shape can proceed to a
public contract selection without a narrower prerequisite. The audit must
account for:

- final-completion-only release and recapture on `RID && RLAST`;
- raw non-final `RID` beats that must not release busy ownership;
- raw active-match and unique-match assertions that cover burst traffic;
- scalar last-beat read-data consumers over generated mixed read demux;
- raw `ARLEN` capture, runtime beat-count/`RLAST` validation, and multi-beat
  output-bank consumers;
- dynamic selected-ID ownership plus static concrete busy ownership; and
- report vocabulary for dynamic and static recapture under a last-beat
  completion source.

Multiple mixed dynamic/static recapture, static-busy-only recapture outside
the selected mixed samples, helper/report cleanup, and validation retries are
not the next exact owner. They remain useful, but the burst-last sibling is
the smallest roadmap-aligned behavioral gap exposed by `.392`.

## Selected .394 Scope

`.394` should audit mixed dynamic/static read burst-last `RID && RLAST`
same-cycle release-and-recapture readiness for:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif
```

The audit should confirm whether direct contract selection is safe or whether
a narrower prerequisite is needed. It should record public source and support
identity preservation; existing mode `bounded_mixed_dynamic_static_read_rid_rlast_demux_contract`;
`response_scope: burst_last`; `last_signal: axi0_rlast`; completion source
`generated_mixed_dynamic_static_read_demux_last_beat`; final-only dynamic and
static release/release-recapture semantics; expected dynamic and static report
fields; assertion rename candidates; validation gates; rollback; docs and
Knowledge Map impact; and residue.

The audit should explicitly preserve the already shipped mixed read burst-last
demux, scalar last-beat read-data, raw-`ARLEN`, runtime-validation, and
multi-beat output-bank consumer contracts unless a later implementation leaf
selects and validates behavior changes.

## Validation

`.393` is docs-only. Closeout validation is:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
mdbook build docs/book
scripts/check_doctrines.sh
```

## Deferred Boundaries

Multiple mixed dynamic/static transaction recapture, static-busy-only
recapture outside the selected mixed read/write samples, request arbitration
beyond onehot0, dynamic same-ID queues, scoreboards, queued/blocking policy,
profile aliases, direct backend behavior, backend-language variants, VHDL, and
full AXI manager behavior remain later exact owners.

## Rollback

Rollback is the `.393` selector commit. Reverting it removes only selector
docs, the fact card, task-tree frontier movement, Memory, README/ROADMAP, and
mdBook synchronization, restoring `.393` as the pending post-mixed-read
selector.
