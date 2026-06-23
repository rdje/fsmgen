# AXI IAL2 Manager Three-Static Mixed Dynamic/Static Read Response-Demux Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.320`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.321`, public contract selection
for bounded one-dynamic plus three-concrete-static mixed dynamic/static read
single-beat `RID` response-demux.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or used:

- `.319` post three-static mixed dynamic/static write demux selector:
  `docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION.md`
- `.318` one-dynamic plus three-concrete-static write `BID`
  response-demux behavior.
- `.317` broader mixed dynamic/static cardinality contract selection.
- `.316` broader mixed dynamic/static cardinality readiness audit.
- `.299` two-static mixed dynamic/static read single-beat `RID`
  response-demux behavior and `.303` two-static burst-last `RID && RLAST`
  behavior.
- `.307`, `.310`, `.312`, and `.314` two-static mixed read-data,
  burst-length, runtime-validation, and multi-beat output-bank behavior.
- Current `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus` read plan
  builder, read normalization, read-data coverage predicates, generated
  completion maps, static concrete-ID reservation/report surfaces, onehot0
  request policy, assertion helpers, and residue text.
- Focused dynamic transaction coverage in
  `t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`, support
  accounting, README, `ROADMAP_V2.md`, mdBook, task tree, Memory, and
  Knowledge Map state.

## Current Boundary

The shipped two-static read path already has the report shape needed for a
bounded three-static contract. The single-beat report mode is:

```text
bounded_multi_mixed_dynamic_static_read_rid_demux_contract
```

The report exposes list-shaped fields:

```text
dynamic_transactions = [r0]
static_transactions = [r1, r2]
mixed_transactions.dynamic = [r0]
mixed_transactions.static = [r1, r2]
static_id_reservations = [...]
dynamic_capture.static_id_exclusions = [...]
generated_rules = [axi0_r0_response_demux, axi0_r1_response_demux, axi0_r2_response_demux]
generated_completion_signals = [axi0_r0_complete, axi0_r1_complete, axi0_r2_complete]
```

The write-side `.318` implementation shows the same list-shaped report mode
can carry a four-transaction covered set without introducing a new report
mode. The read assertion expectations are also already pairwise/list-shaped
for two static reads.

The behavior is not ready for direct implementation until the public contract
is selected. The read plan builder still fails closed outside one dynamic and
one or two static reads:

```text
Internal error: mixed dynamic/static read demux requires one dynamic and one or two static transactions
```

Burst-last normalization repeats the same public boundary:

```text
AXI manager capacity/status IAL2 contract response_demux.read mixed dynamic/static burst-last ID matching supports exactly one dynamic read transaction plus one or two pairwise-distinct concrete static read transactions in this slice
```

Read-data coverage is also explicitly two-static:

```text
AXI manager capacity/status IAL2 contract read_data.read multiple mixed dynamic/static coverage requires exactly one dynamic read transaction and two concrete static read transactions in this slice
```

No checked-in public `.ppif` sample currently covers a three-static mixed
dynamic/static read response-demux shape.

## Readiness Findings

The next owner should not be direct behavior. The candidate public shape,
report vocabulary, diagnostics, support-accounting stem, validation gates,
and preservation obligations should be selected before changing the read
builder.

The first read-side widening should start with single-beat `RID`
response-demux. That mirrors the earlier two-static ladder and keeps the
behavior boundary smaller than a combined single-beat plus burst-last owner.
Burst-last adds `RLAST` completion semantics and raw active-match assertions
that should remain a later explicit owner. Read-data, raw `ARLEN`
burst-length, runtime beat-count/`RLAST`, and multi-beat output banks all
consume generated read response-demux and should follow only after the
three-static read-demux boundary ships.

Two-dynamic-plus-static and capped mixed sets are not ready as the next
public contract. They need dynamic-versus-dynamic ownership and arbitration
choices that are outside the one-dynamic mixed contract family.

## Selected .321 Boundary

`.321` should select the public source/report contract for bounded
one-dynamic plus three-concrete-static mixed dynamic/static read single-beat
`RID` response-demux. It should decide and record:

- reuse of existing `response-demux.read` syntax with
  `response-scope single-beat` and `transaction-completion generated`;
- the exact first cardinality: one dynamic read transaction plus three
  pairwise-distinct concrete static read transactions;
- candidate public sample stem
  `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif`;
- support-accounting identity
  `intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3`;
- whether the existing report mode
  `bounded_multi_mixed_dynamic_static_read_rid_demux_contract` remains the
  report mode, with cardinality exposed through existing list fields;
- ordered report fields for `dynamic_transactions`, `static_transactions`,
  `mixed_transactions`, `static_id_reservations`,
  `dynamic_capture.static_id_exclusions`, `generated_rules`, and
  `generated_completion_signals`;
- expected diagnostics for duplicate static concrete IDs, unsupported
  burst-last scope in this first contract, read-data over the three-static
  boundary, two-dynamic-plus-static, capped mixed sets, same-cycle widening,
  release-and-recapture, dynamic same-ID queues, scoreboards, direct backend,
  backend-language variants, and VHDL;
- focused validation gates and host-memory strategy; and
- rollback and docs/Knowledge Map impact.

`.321` should not implement parser, generator, sample, support-accounting,
test, schedule/check/semantic JSON, generated artifact, or HDL behavior. It
should only select the future public contract so the behavior owner can
change the code with one unambiguous boundary.

## Explicit Residue

The following remain future owners:

- direct generated behavior for one-dynamic plus three-static read
  single-beat `RID` response-demux;
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
HDL probes are required because `.320` changes no behavior.

## Rollback

Rollback is the `.320` audit commit. Reverting it restores `.320` as the
active readiness-audit owner and removes the `.321` contract-selection
handoff.
