# AXI IAL2 Manager Multiple Mixed Dynamic/Static Read RLAST Response-Demux Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.301`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.302`, public contract selection
for bounded multiple mixed dynamic/static read burst-last `RID && RLAST`
response-demux.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or used:

- `.300` post multiple mixed dynamic/static read demux selector:
  `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION.md`
- `.299` multiple mixed dynamic/static read single-beat `RID`
  response-demux behavior.
- `.298` multiple mixed dynamic/static read single-beat contract selection.
- `.297` multiple mixed dynamic/static read response-demux readiness audit.
- `.295` multiple mixed dynamic/static write `BID` response-demux behavior.
- `.291` mixed dynamic/static multi-beat output-bank behavior.
- `.280` one-dynamic plus one-static mixed read burst-last `RID && RLAST`
  response-demux behavior.
- `.276` one-dynamic plus one-static mixed read single-beat `RID`
  response-demux behavior.
- Current read plan builder, read normalization, last-signal handling,
  generated completion signal maps, static concrete-ID reservation/report
  surfaces, onehot0 request policy, mixed assertion helper, support
  accounting, focused validation costs, README, `ROADMAP_V2.md`, mdBook,
  task tree, Memory, and Knowledge Map.
- A RAM-guarded temporary probe at
  `/tmp/fsmgen_multi_static_mixed_read_burst_candidate.ppif`, removed after
  the audit, combining the `.299` one-dynamic plus two-static read shape with
  `.280` burst-last `last-signal` syntax.

## Current Boundary

The `.299` public sample now accepts exactly one dynamic read transaction plus
two concrete static read transactions for `response-scope single-beat`. It
generates dynamic selected-ID/busy state, per-static busy state, list-shaped
`mixed_transactions`/`static_id_reservations`, dynamic capture exclusions for
all selected static concrete IDs, onehot0 request policy, and pairwise
single-beat raw `RID` response unique-match assertions.

The one-dynamic plus one-concrete-static mixed read path is already shipped
for burst-last `RID && RLAST` in `.280`.

The temporary multi-static burst-last probe fails closed under the default
RAM guard with:

```text
AXI manager capacity/status IAL2 contract response_demux.read mixed dynamic/static burst-last ID matching supports exactly one dynamic read transaction and one concrete static read transaction in this slice
```

That diagnostic is the current public boundary: multi-static mixed read
burst-last behavior is not yet selected or generated.

## Readiness Findings

The lower substrate is close enough for public contract selection, but not for
direct behavior implementation in this audit.

Ready pieces:

- `.299` supplies the one-dynamic plus two-static read state shape and report
  list surfaces for single-beat `RID` demux.
- `.280` supplies the one-dynamic plus one-static burst-last final-completion
  pattern with raw `RID` beat assertions separated from `RID && RLAST`
  completion and release.
- The mixed dynamic/static assertion helper is list-shaped across dynamic and
  static state records, so pairwise response uniqueness and dynamic/static
  static-ID exclusions can be named over the widened state set once the plan
  admits it.
- Existing IAL1/IAL0/SystemVerilog lowering can carry the generated one-bit
  `RLAST` input, Boolean guards, generated pulse outputs, state release
  rules, and assertions.

Open contract details:

- report mode and completion-source names need to distinguish multi-static
  mixed burst-last from `.299` single-beat and `.280` one-static burst-last;
- static concrete final-beat completion must be explicitly covered for both
  static transactions;
- raw `RID` beat ownership assertions must remain independent of `RLAST`, so
  legal non-final beats do not complete or release state;
- generated completion signal ordering and state-list ordering should stay
  `[r0, r1, r2]`;
- diagnostics must preserve `.280` one-static behavior and `.299` single-beat
  behavior while rejecting unsupported read-data, burst-length/runtime,
  multi-beat, broader cardinality, same-cycle widening, queues, scoreboards,
  backend variants, and VHDL; and
- support-accounting/sample naming should be selected before implementation.

## Selected .302 Boundary

`.302` should select only the public contract for bounded multiple mixed
dynamic/static read burst-last `RID && RLAST` response-demux. It should decide
and record:

- exact cardinality: one dynamic read transaction plus two pairwise-distinct
  concrete static read transactions;
- public source syntax reusing `response-demux.read` with
  `response-scope burst-last`, one-bit `last-signal`, and generated
  transaction completion;
- candidate public PPIF sample stem:
  `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif`;
- candidate report mode
  `bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`;
- candidate completion source
  `generated_multi_mixed_dynamic_static_read_demux_last_beat`;
- list-shaped `mixed_transactions` and `static_id_reservations` fields while
  preserving `.276` and `.280` one-dynamic plus one-static report contracts;
- dynamic capture exclusion against all selected static concrete IDs;
- onehot0 same-cycle request policy across all selected mixed read
  transactions;
- raw `RID` active-match and pairwise unique-match assertion names;
- final `RID && RLAST` generated completion and release behavior;
- focused diagnostics, validation gates, rollback, docs, mdBook, and
  Knowledge Map impact; and
- explicit residue.

`.302` should not implement parser, generator, sample, support-accounting,
test, JSON, generated artifact, or HDL behavior. It should only select the
future public contract so a later implementation owner can change behavior
with one unambiguous read-side burst-last ownership model.

## Explicit Residue

The following remain future owners:

- direct implementation of multiple mixed dynamic/static read burst-last
  `RID && RLAST` response-demux;
- scalar read-data over multiple mixed read demux;
- burst-length/runtime validation and multi-beat output banks over multiple
  mixed read demux;
- two-dynamic plus one-static mixed dynamic/static cardinality;
- broader mixed write and read cardinalities;
- same-cycle request widening beyond onehot0;
- same-cycle release-and-recapture;
- dynamic same-ID queues and scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

## Validation

Audit validation is documentation and continuity only:

```bash
scripts/run_with_ram_guard.sh --host-max-pct 88 --process-max-rss-mb 4096 -- ./bin/fsmgen --strict --check-json /tmp/fsmgen_multi_static_mixed_read_burst_candidate.ppif
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

The temporary probe was removed after recording the fail-closed diagnostic.
No focused generator, parser, support-accounting, schedule/check/semantic, or
HDL positive probes are required because `.301` changes no behavior.

## Rollback

Rollback is the `.301` audit commit. Reverting it restores `.301` as the
active multiple mixed dynamic/static read burst-last readiness-audit owner and
removes the `.302` contract-selection handoff.
