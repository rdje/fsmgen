# AXI IAL2 Manager Post Three-Static Mixed Dynamic/Static Write Demux Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.319`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.320`, readiness audit for
bounded one-dynamic plus three-concrete-static mixed dynamic/static read
response-demux after generated bounded one-dynamic plus three-concrete-static
write `BID` response-demux shipped.

The audit should start from the read single-beat `RID` boundary, then record
whether burst-last `RID && RLAST`, read-data, burst-length/runtime
validation, or multi-beat output banks should be separate later owners. This
selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The selector read or used:

- `.318` one-dynamic plus three-concrete-static write `BID`
  response-demux behavior:
  `docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md`
- `.317` broader mixed dynamic/static cardinality contract selection.
- `.316` broader mixed dynamic/static cardinality readiness audit.
- `.315` post multiple mixed multi-beat selector.
- Earlier mixed/multiple dynamic/static write/read/read-data behavior notes,
  especially the `.296` to `.299` sequence after the two-static write demux
  and the `.300` to `.314` read burst-last/read-data/burst/runtime/multi-beat
  ladder.
- Current `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus` mixed write
  and read builders, read normalization, read-data response-demux coverage,
  static residue text, and public report vocabulary.
- Focused dynamic transaction coverage in
  `t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`, support
  accounting in `FSM::Support::RegressionCorpus`, `README.md`,
  `ROADMAP_V2.md`, mdBook feature backlog, task tree, Memory, and Knowledge
  Map state.

## Rationale

`.318` widened only the write-side mixed dynamic/static `BID` demux
cardinality. The write builder now accepts exactly one dynamic write
transaction plus one, two, or three pairwise-distinct concrete static write
transactions and already emits list-shaped static reservations, dynamic
static-ID exclusions, generated response-demux rules, completion pulses, and
pairwise unique-match assertions for the four selected write transactions.

The corresponding read builder remains hard-bounded to one dynamic read
transaction plus one or two concrete static read transactions:

```text
Internal error: mixed dynamic/static read demux requires one dynamic and one or two static transactions
```

Read burst-last normalization also repeats the one-or-two-static boundary,
and read-data coverage for generated multiple mixed dynamic/static read demux
still requires exactly one dynamic read transaction and two concrete static
read transactions. That means jumping directly to three-static read-data or a
capped mixed set would cross several public contracts at once.

The established local pattern after `.295` two-static write behavior was to
select a read readiness audit first, then contract selection, then behavior.
The same pattern is still the narrowest signoff-level move for the
three-static write widening. It keeps public syntax/report vocabulary,
diagnostics, validation cost, and rollback scoped before any behavior owner
changes parser, generator, support accounting, focused tests, JSON, or HDL.

Two-dynamic-plus-static shapes and general capped mixed sets should stay
behind this read parity audit. Those alternatives require policy choices for
dynamic-versus-dynamic matching and request arbitration that the current
one-dynamic mixed contracts deliberately avoid.

## Selected .320 Boundary

`.320` should audit only one-dynamic plus three-concrete-static mixed
dynamic/static read response-demux readiness. It should:

- inspect the `.318` three-static write implementation and report contract;
- inspect the current two-static read single-beat, burst-last, scalar
  read-data, burst-length/runtime validation, and multi-beat output-bank
  behavior chain;
- inspect `_response_demux_mixed_dynamic_static_read_transaction`,
  `_normalize_response_demux_read`,
  `_read_data_response_demux_transaction_coverage`, residue helpers,
  assertion helpers, and focused `t/1438` report expectations;
- decide whether the next exact owner after the audit should be public
  contract selection for three-static read single-beat `RID` demux, direct
  single-beat behavior, a helper/report cleanup, or a narrower prerequisite;
- record candidate public sample stems, with a bias toward
  `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif`
  if single-beat `RID` is selected;
- record expected report vocabulary, including whether the existing
  `bounded_multi_mixed_dynamic_static_read_rid_demux_contract` mode can
  cover the three-static shape through list fields or whether a narrower
  report update is required;
- record diagnostics for unsupported burst-last, read-data,
  burst-length/runtime validation, multi-beat output banks,
  two-dynamic-plus-static, capped mixed sets, same-cycle widening,
  release-and-recapture, dynamic same-ID queues, scoreboards, direct backend,
  backend-language variants, and VHDL; and
- change no parser, generator, PPIF sample, support-accounting catalog,
  validation behavior, generated artifact, test, schedule/check/semantic
  JSON, or HDL behavior.

## Explicit Residue

These remain future exact owners unless `.320` deliberately selects one as
the next boundary:

- implementation of one-dynamic plus three-static read single-beat `RID`
  response-demux;
- one-dynamic plus three-static read burst-last `RID && RLAST`
  response-demux;
- scalar read-data, burst-length/runtime validation, and multi-beat output
  banks over the three-static read demux;
- two-dynamic plus one-static write or read response-demux;
- generalized capped mixed dynamic/static sets;
- same-cycle request widening beyond onehot0;
- same-cycle release-and-recapture;
- dynamic same-ID queues and scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

## Validation

Selector validation is documentation and continuity only:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No focused generator, parser, support-accounting, schedule/check/semantic, or
HDL probes are required because `.319` changes no behavior.

## Rollback

Rollback is the `.319` selector commit. Reverting it restores `.319` as the
active selector after `.318` and removes the `.320` readiness-audit owner.
