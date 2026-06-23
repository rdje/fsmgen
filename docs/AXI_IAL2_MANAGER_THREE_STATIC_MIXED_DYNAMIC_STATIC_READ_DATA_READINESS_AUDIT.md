# AXI IAL2 Manager Three-Static Mixed Dynamic/Static Read-Data Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.328`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.329`, public contract selection
for bounded scalar read-data over generated one-dynamic plus
three-concrete-static mixed dynamic/static read response-demux.

The selected contract-selection slice should cover both scalar single-beat
read-data over the `.322` generated `RID` response-demux and scalar last-beat
read-data over the `.326` generated `RID && RLAST` response-demux.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or used:

- `.327` selector for scalar read-data readiness after the three-static
  mixed read burst-last demux.
- `.326` one-dynamic plus three-static mixed dynamic/static read burst-last
  `RID && RLAST` response-demux behavior.
- `.322` one-dynamic plus three-static mixed dynamic/static read single-beat
  `RID` response-demux behavior.
- `.307` one-dynamic plus two-static scalar read-data behavior.
- `.305` one-dynamic plus two-static scalar read-data readiness audit.
- `.284` one-dynamic plus one-static scalar read-data behavior.
- `.259` multiple dynamic scalar read-data behavior.
- Current `_read_data_response_demux_transaction_coverage`,
  `_normalize_read_data_read`, `_read_data_capture_rule_lines`,
  read-data report helpers, response-demux residue helpers,
  support-accounting catalog, focused dynamic tests, README,
  `ROADMAP_V2.md`, mdBook, task tree, Memory, and Knowledge Map.

## Code Findings

The scalar read-data substrate is ready for a narrow contract, but the public
three-static contract should be selected before implementation:

- `_read_data_response_demux_transaction_coverage` already recognizes
  `generated_multi_mixed_dynamic_static_read_demux` for scalar single-beat
  capture and `generated_multi_mixed_dynamic_static_read_demux_last_beat` for
  scalar last-beat capture.
- That branch is still explicitly bounded to exactly one dynamic read
  transaction and exactly two concrete static read transactions.
- The same branch already carries the desired report vocabulary:
  `generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse`
  and
  `generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`.
- `_normalize_read_data_read` is transaction-list driven once a coverage
  branch returns the covered transaction list and completion map. It already
  rejects missing, duplicate, and uncovered `read-data.read.transaction`
  bindings for arbitrary covered scalar transaction counts.
- `_read_data_capture_rule_lines` emits one scalar capture rule per normalized
  transaction, guarded by that transaction's generated completion pulse. It
  does not re-match raw `RID` or `RID && RLAST`.
- `.322` and `.326` response-demux reports already expose the ordered data a
  three-static scalar read-data branch needs:
  `dynamic_transactions: [r0]`, `static_transactions: [r1, r2, r3]`,
  list-shaped mixed/static transaction fields, static ID reservations for
  `4'd3`, `4'd5`, and `4'd7`, and generated completion signals for
  `r0`, `r1`, `r2`, and `r3`.
- Support accounting and focused dynamic tests have entries for the
  three-static response-demux-only samples and the two-static read-data
  samples, but no public three-static read-data sample or support identity
  exists yet.

The remaining behavior-bearing implementation appears local to admitting the
three-static scalar read-data cardinality, adding public samples/support
entries, and extending focused assertions. The public source shape, support
identity, report expectations, diagnostics, validation cost, and residue must
be fixed first.

## Why Contract Selection First

The two-static path deliberately used a readiness audit, then a public
contract selector, then implementation. Reusing that order keeps the
three-static widening reviewable and prevents a behavior slice from also
choosing public names and report vocabulary.

`.329` should decide:

- exact public PPIF stems, likely
  `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_read_data.ppif`
  and
  `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data.ppif`;
- support identities and coverage names for those two stems;
- scalar output naming for `r0`, `r1`, `r2`, and `r3`;
- whether the existing multi-mixed scalar read-data report vocabulary remains
  cardinality-neutral for three static transactions;
- the transaction coverage order, expected to remain dynamic transactions
  followed by static transactions, `r0, r1, r2, r3`;
- fail-closed diagnostics for unsupported cardinalities, partial bindings,
  extra bindings, duplicate bindings, completion-count mismatches, and
  unsupported burst-length/runtime/multi-beat extensions;
- whether response-demux and read-data residue change only for scalar
  read-data while raw `ARLEN`, runtime validation, and multi-beat output banks
  remain future owners;
- guarded direct validation and lightweight report/adapter fallback strategy;
  and
- docs, mdBook, README, `ROADMAP_V2.md`, Memory, Knowledge Map, and rollback
  requirements.

## Selected .329 Boundary

`.329` should select the exact public contract for bounded scalar read-data
over generated one-dynamic plus three-concrete-static mixed dynamic/static
read response-demux. It should define:

- public source shape for `.322` three-static single-beat `RID`
  response-demux plus scalar `capture-scope single-beat` read-data;
- public source shape for `.326` three-static burst-last `RID && RLAST`
  response-demux plus scalar `capture-scope last-beat` read-data;
- required transaction cardinality: exactly one dynamic read plus exactly
  three pairwise-distinct concrete static reads;
- transaction-to-generated-completion mapping and ordered coverage;
- scalar data/status output binding rules for `r0`, `r1`, `r2`, and `r3`;
- completion-validity and report vocabulary;
- public sample names, support identities, and support-accounting entries;
- focused parser/generator/dynamic/support-accounting validation gates,
  including RAM-guarded direct probes and lightweight report/adapter fallback
  probes if host memory is already above the guard cutoff;
- docs, mdBook, README, `ROADMAP_V2.md`, Memory, and Knowledge Map updates;
- rollback; and
- explicit residue.

## Non-Goals

This audit does not implement read-data over the three-static mixed
dynamic/static read demux boundary. It does not change parser, generator,
PPIF samples, support-accounting catalog, validation behavior, generated
artifacts, tests, schedule/check or semantic JSON, or HDL behavior.

These remain later exact owners unless `.329` explicitly selects otherwise:

- generated scalar read-data over three-static mixed read demux;
- raw `ARLEN` burst-length capture over three-static mixed read burst-last
  demux;
- runtime beat-count/`RLAST` validation over three-static mixed read
  burst-last demux;
- multi-beat output banks over three-static mixed read demux;
- two-dynamic plus one-static mixed dynamic/static cardinality;
- broader capped mixed write and read cardinalities;
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
HDL probes are required because `.328` changes no behavior.

## Rollback

Rollback is the `.328` audit commit. Reverting it restores `.328` as the
active readiness-audit frontier and removes the `.329` public
contract-selection owner.
