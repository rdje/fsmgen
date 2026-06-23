# AXI IAL2 Manager Multiple Mixed Dynamic/Static Read Response-Demux Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.297`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.298`, public contract selection
for bounded multiple mixed dynamic/static read single-beat `RID`
response-demux.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or used:

- `.296` post multiple mixed dynamic/static write demux selector:
  `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION.md`
- `.295` multiple mixed dynamic/static write `BID` response-demux behavior.
- `.294` multiple mixed dynamic/static write contract selection.
- `.293` multiple mixed dynamic/static readiness audit.
- `.280` mixed dynamic/static read burst-last `RID && RLAST`
  response-demux behavior.
- `.276` mixed dynamic/static read single-beat `RID` response-demux behavior.
- `.284` mixed dynamic/static scalar read-data behavior.
- `.291` mixed dynamic/static multi-beat output-bank behavior.
- Multiple all-dynamic read response-demux precedents from `.251` and `.255`.
- Current read plan builder, read normalization, read-data coverage
  predicates, generated completion signal maps, static concrete-ID
  reservation/report surfaces, onehot0 request policy, assertion helpers,
  support accounting, focused validation costs, README, `ROADMAP_V2.md`,
  mdBook, task tree, Memory, and Knowledge Map.

## Current Boundary

The one-dynamic plus one-concrete-static mixed dynamic/static read path is
shipped for:

- single-beat `RID` response-demux;
- burst-last `RID && RLAST` response-demux;
- scalar single-beat and scalar last-beat read-data;
- report-only raw-`ARLEN` capture;
- runtime beat-count/`RLAST` validation; and
- multi-beat output banks.

The read response-demux plan builder remains hard-bounded to exactly one
dynamic read transaction and exactly one concrete static read transaction.
The current fail-closed diagnostic is:

```text
AXI manager capacity/status IAL2 contract response_demux.read mixed dynamic/static ID matching supports exactly one dynamic read transaction and one concrete static read transaction in this slice
```

`.293` previously confirmed that diagnostic with a RAM-guarded temporary
one-dynamic plus two-static read candidate. During this `.297` audit, a new
temporary single-beat read candidate was attempted under the default RAM
guard, but the guard stopped immediately because host memory was already
above the 88% cutoff; no diagnostic was emitted, and the temporary candidate
was removed. The code inspection and the `.293` rerunnable evidence are the
canonical readiness evidence for this audit.

## Readiness Findings

The lower substrate is close enough for a public contract-selection slice,
but not for direct behavior implementation.

The `.295` write implementation provides a local pattern for one dynamic
transaction plus two concrete static transactions: list-shaped static state,
pairwise static concrete-ID uniqueness, dynamic capture exclusion against
every selected static concrete ID, onehot0 selected request policy, ordered
generated completion signals, list-shaped `mixed_transactions` and
`static_id_reservations`, and preserved one-plus-one report shape.

The mixed dynamic/static assertion helper is already list-shaped across
dynamic and static state records. It emits request-not-busy, onehot0 request,
dynamic request/active-not-static-ID, active response match, pairwise
unique-match, and completion-active assertions over whatever state list the
plan builder supplies.

The remaining work is contract-sensitive rather than mechanically ready. Read
response-demux has two user-visible scopes:

- single-beat `RID`, where each raw accepted read response can complete the
  selected transaction; and
- burst-last `RID && RLAST`, where raw `RID` beat assertions remain separate
  from final-beat completion and release.

Combining both scopes into the first widened read contract would make the
report vocabulary, generated completion source naming, and validation matrix
larger than necessary. The first read-side widening should therefore mirror
the existing ladder and start with single-beat `RID`.

## Selected .298 Boundary

`.298` should select only the public contract for bounded multiple mixed
dynamic/static read single-beat `RID` response-demux. It should decide and
record:

- the first bounded read transaction cardinality, with a bias toward exactly
  one dynamic read transaction plus exactly two pairwise-distinct concrete
  static read transactions;
- the public PPIF sample stem:
  `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif`;
- whether existing `response-demux.read` syntax is reused unchanged with
  `response-scope single-beat`;
- report mode and completion-source vocabulary, including candidate
  `bounded_multi_mixed_dynamic_static_read_rid_demux_contract` and
  `generated_multi_mixed_dynamic_static_read_demux`;
- list-shaped mixed transaction and static-ID reservation report fields while
  preserving the existing `.276` one-dynamic plus one-static read report
  contract;
- dynamic capture exclusion against all selected static concrete IDs;
- static concrete-ID uniqueness diagnostics;
- onehot0 same-cycle request policy across all selected mixed read
  transactions;
- raw `RID` active-match and pairwise unique-match assertion names;
- generated completion signal ordering and transaction state report ordering;
- focused diagnostics for unsupported read burst-last widening, read-data,
  burst-length/runtime validation, multi-beat output banks, broader mixed
  cardinalities, same-cycle widening, release-and-recapture, dynamic same-ID
  queues, scoreboards, direct backend behavior, backend-language variants,
  and VHDL;
- validation gates, rollback, docs, mdBook, and Knowledge Map impact; and
- explicit residue.

`.298` should not implement parser, generator, sample, support-accounting,
test, JSON, generated artifact, or HDL behavior. It should only select the
future public contract so a later implementation owner can change behavior
with one unambiguous read-side ownership model.

## Explicit Residue

The following remain future owners:

- direct implementation of multiple mixed dynamic/static read single-beat
  `RID` response-demux;
- multiple mixed dynamic/static read burst-last `RID && RLAST`
  response-demux;
- scalar read-data, burst-length/runtime validation, and multi-beat output
  banks over multiple mixed read demux;
- two-dynamic plus one-static mixed dynamic/static write cardinality;
- broader mixed write and read cardinalities;
- same-cycle request widening beyond onehot0;
- same-cycle release-and-recapture;
- dynamic same-ID queues and scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

## Validation

Audit validation covers live docs, mdBook, Memory, Knowledge Map, diff
hygiene, and doctrine gates. No behavior changed.

The temporary `.297` RAM-guarded probe did not produce a diagnostic because
host memory was already above the default guard cutoff. The audit therefore
uses the existing `.293` fail-closed diagnostic evidence plus direct code
inspection of the current singular read plan builder.

## Rollback

Rollback is the `.297` audit commit. Reverting it restores `.297` as the
active multiple mixed dynamic/static read readiness-audit owner and removes
the `.298` contract-selection handoff.
