# AXI IAL2 Manager Three-Static Mixed Dynamic/Static Read RLAST Response-Demux Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.324`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.325`, public contract selection
for bounded one-dynamic plus three-concrete-static mixed dynamic/static read
burst-last `RID && RLAST` response-demux.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or used:

- `.323` post three-static mixed dynamic/static read single-beat demux
  selector:
  `docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION.md`
- `.322` one-dynamic plus three-concrete-static mixed dynamic/static read
  single-beat `RID` response-demux behavior.
- `.321` three-static mixed dynamic/static read single-beat public contract
  selection.
- `.320` three-static mixed dynamic/static read response-demux readiness
  audit.
- `.303` one-dynamic plus two-concrete-static mixed dynamic/static read
  burst-last `RID && RLAST` response-demux behavior.
- `.302` two-static mixed dynamic/static read burst-last public contract
  selection.
- `.301` two-static mixed dynamic/static read burst-last readiness audit.
- `.299` one-dynamic plus two-concrete-static mixed dynamic/static read
  single-beat `RID` response-demux behavior.
- `.318` one-dynamic plus three-concrete-static mixed dynamic/static write
  `BID` response-demux behavior.
- Current `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus` read plan
  builder, read normalization, last-signal handling, generated completion
  maps, static concrete-ID reservation/report surfaces, onehot0 request
  policy, mixed assertion helper, and read-data coverage predicates.
- Focused dynamic transaction coverage in
  `t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`, support
  accounting, README, `ROADMAP_V2.md`, mdBook, task tree, Memory, and
  Knowledge Map state.

## Current Boundary

`.322` proves that the mixed dynamic/static read single-beat surface can
carry one dynamic read transaction plus three concrete static read
transactions. It reuses:

```text
bounded_multi_mixed_dynamic_static_read_rid_demux_contract
```

with list-shaped `dynamic_transactions`, `static_transactions`,
`mixed_transactions`, static ID reservations, dynamic static-ID exclusions,
generated rules, and generated completion signals.

`.303` proves the adjacent two-static burst-last surface. Its report mode is:

```text
bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract
```

and its completion source is:

```text
generated_multi_mixed_dynamic_static_read_demux_last_beat
```

That report is already list-shaped for:

```text
dynamic_transactions = [r0]
static_transactions = [r1, r2]
static_id_reservations = [4'd3, 4'd5]
dynamic_capture.static_id_exclusions = [4'd3, 4'd5]
generated_completion_signals = [axi0_r0_complete, axi0_r1_complete, axi0_r2_complete]
```

The public three-static burst-last boundary remains fail-closed. Current
burst-last read normalization still admits exactly one dynamic read
transaction plus one or two pairwise-distinct concrete static read
transactions in this slice. Read-data coverage over the generated multiple
mixed dynamic/static read demux is also still exact to one dynamic read
transaction plus two concrete static read transactions.

No checked-in public `.ppif` sample currently covers one dynamic read
transaction plus three concrete static read transactions under
`response-scope burst-last`.

## Readiness Findings

The next owner should be public contract selection, not direct behavior. The
underlying surfaces are close: the single-beat three-static report is
list-shaped, the two-static burst-last report is list-shaped, and the
existing last-signal vocabulary already has the right final-beat completion
source. The public contract still needs to lock the exact sample stem,
support-accounting identity, report vocabulary, diagnostics, validation
gates, rollback, and residue before the generator guard is widened.

No helper/report cleanup prerequisite is required before contract selection.
Any helper generalization needed for behavior should stay owned by the later
behavior leaf so it can be validated against the concrete sample.

Read-data, raw-ARLEN burst-length capture, runtime beat-count/`RLAST`
validation, and multi-beat output banks should remain behind generated
three-static burst-last completion semantics. Two-dynamic-plus-static,
general capped mixed cardinalities, same-cycle widening, release and
recapture, dynamic same-ID queues, scoreboards, direct backend behavior,
backend-language variants, and VHDL require broader ownership than this
read-lifetime boundary.

## Selected .325 Boundary

`.325` should select the public source/report contract for bounded
one-dynamic plus three-concrete-static mixed dynamic/static read burst-last
`RID && RLAST` response-demux. It should decide and record:

- reuse of existing `response-demux.read` syntax with
  `response-scope burst-last`, one one-bit `last-signal`, and
  `transaction-completion generated`;
- the exact first cardinality: one dynamic read transaction plus three
  pairwise-distinct concrete static read transactions;
- candidate public sample stem
  `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif`;
- support-accounting identity
  `intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last`;
- whether the existing report mode
  `bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract` remains
  the report mode, with cardinality exposed through existing list fields;
- expected completion source
  `generated_multi_mixed_dynamic_static_read_demux_last_beat`;
- ordered report fields for `dynamic_transactions`, `static_transactions`,
  `mixed_transactions`, `static_id_reservations`,
  `dynamic_capture.static_id_exclusions`, `generated_rules`,
  `generated_completion_signals`, `last_signal`, `last_signal_width`,
  `burst_length_source`, and `transaction_completion_semantics`;
- expected diagnostics for duplicate static concrete IDs, missing or
  non-one-bit `last-signal`, unsupported read-data over the three-static
  boundary, two-dynamic-plus-static, capped mixed sets, same-cycle widening,
  release and recapture, dynamic same-ID queues, scoreboards, direct backend,
  backend-language variants, and VHDL;
- focused validation gates and host-memory strategy; and
- rollback and docs/Knowledge Map impact.

`.325` should not implement parser, generator, sample, support-accounting,
test, schedule/check/semantic JSON, generated artifact, or HDL behavior. It
should only select the future public contract so the behavior owner can widen
burst-last admission with one unambiguous boundary.

## Explicit Residue

The following remain future owners:

- direct generated behavior for one-dynamic plus three-static read burst-last
  `RID && RLAST` response-demux;
- scalar read-data over the three-static read demux boundary;
- burst-length/runtime validation and multi-beat output banks over the
  three-static read demux boundary;
- two-dynamic plus one-static write or read response-demux;
- generalized capped mixed dynamic/static sets;
- same-cycle request widening beyond onehot0;
- same-cycle release and recapture;
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
HDL probes are required because `.324` changes no behavior.

## Rollback

Rollback is the `.324` audit commit. Reverting it restores `.324` as the
active readiness-audit owner and removes the `.325` contract-selection
handoff.
