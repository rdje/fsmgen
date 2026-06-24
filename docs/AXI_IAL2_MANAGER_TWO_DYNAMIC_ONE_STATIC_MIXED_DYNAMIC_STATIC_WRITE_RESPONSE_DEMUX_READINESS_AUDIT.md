# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Write Response-Demux Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.339`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.339` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.340`, public contract selection for
two-dynamic-plus-one-static mixed dynamic/static write `BID` response-demux.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or reverified:

- `.338` post three-static mixed multi-beat selector.
- `.337` three-static mixed dynamic/static multi-beat behavior.
- `.318` one-dynamic plus three-static mixed write `BID` response-demux
  behavior.
- `.317` and `.316` broader mixed-cardinality selection/audit.
- `.247` bounded multiple all-dynamic write `BID` response-demux behavior.
- Current `_response_demux_dynamic_write_transaction` admission,
  `_response_demux_mixed_dynamic_static_write_transaction` constructor,
  all-dynamic assertion helper, mixed dynamic/static assertion helper,
  report/residue text, support accounting, focused validation costs and
  RAM-guard caveats.
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map.

## Readiness Finding

Direct implementation is not yet the right next step. The lower substrate has
the necessary building blocks, but the public two-dynamic-plus-one-static
contract is not selected.

The current admission gate in `_response_demux_dynamic_write_transaction`
rejects any mixed dynamic/static write shape unless it has exactly one
dynamic write transaction and one, two, or three concrete static write
transactions:

```text
mixed dynamic/static ID matching supports exactly one dynamic write
transaction plus one, two, or three pairwise-distinct concrete static write
transactions in this slice
```

The mixed constructor repeats that invariant internally:

```text
mixed dynamic/static write demux requires one dynamic and one, two, or three
static transactions
```

The all-dynamic multiple write path is already stronger than the mixed path
in one important dimension. It supports multiple active dynamic write
transactions with:

- onehot0 same-cycle dynamic write request policy;
- per-transaction selected dynamic ID and busy state;
- request no-active-same-ID guards;
- pairwise active dynamic ID uniqueness assertions;
- response active-match assertions; and
- pairwise dynamic response unique-match assertions.

The one-dynamic plus static mixed write path is already stronger in the
static dimension. It supports:

- concrete static ID reservations;
- dynamic request and active selected-ID exclusions against every static ID;
- mixed-family request onehot0 across dynamic and static transactions;
- mixed response active-match assertions;
- pairwise mixed response unique-match assertions across the combined
  dynamic/static state list; and
- dynamic/static completion-active assertions.

The mixed assertion helper already loops over arbitrary dynamic and static
state lists for dynamic-vs-static exclusion assertions and response
unique-match assertions. That is useful, but not sufficient by itself:

- mixed admission still has no two-dynamic-plus-static public boundary;
- mixed constructor state/report assembly still assumes one dynamic state;
- mixed dynamic capture report vocabulary currently describes one dynamic
  transaction in the multi-mixed branch;
- the mixed assertion helper does not add dynamic-vs-dynamic active selected
  ID uniqueness assertions, because that policy currently lives in the
  all-dynamic assertion helper; and
- diagnostics, sample naming, support identity, focused behavior label, and
  explicit read-side/read-data residue need selection before behavior changes.

## Selected .340 Boundary

`.340` should select the public source/report contract before implementation.

The likely source shape is:

- write family only;
- exactly two dynamic write transactions, probably `w0` and `w1`;
- exactly one concrete static write transaction, probably `w2`;
- pairwise uniqueness for active dynamic selected IDs;
- dynamic request and active selected-ID exclusion against the static
  concrete ID;
- mixed-family request onehot0 across all three transactions;
- generated write `BID` response-demux with generated transaction
  completions; and
- no read response-demux, read-data, burst-length/runtime validation,
  multi-beat output-bank, broader cardinality, same-cycle, queue/scoreboard,
  backend-variant, or VHDL behavior.

The candidate public sample stem is:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

The candidate support identity is:

```text
intent.ppif_axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic
```

The candidate focused behavior label is:

```text
mixed_dynamic_static_write_demux_multi_dynamic
```

`.340` should decide whether the report reuses
`bounded_multi_mixed_dynamic_static_write_bid_demux_contract` with expanded
list-shaped fields or introduces a more explicit two-dynamic-plus-static
contract note. The preferred direction is to reuse the existing multi-mixed
mode if the contract can make the new dynamic-vs-dynamic active uniqueness
fields explicit without ambiguity.

## Diagnostics For .340

The contract selector should require fail-closed diagnostics for:

- any mixed write shape outside the selected two dynamic plus one static
  public boundary;
- duplicate or out-of-range concrete static IDs;
- missing write ID-family metadata;
- mixed dynamic/static response-demux combined with write auto-ID lifecycle or
  write same-ID ordering metadata;
- missing generated transaction completion ownership;
- read-side or read-data attempts for the two-dynamic-plus-static shape; and
- broader capped mixed sets until they are separately selected.

## Validation Strategy For Later Behavior

If `.340` selects direct implementation, the implementation owner should run:

- syntax checks for touched Perl modules and focused tests;
- filtered focused t/1438 coverage for the selected behavior label;
- t/248 support accounting after adding a public sample;
- direct schedule/check/semantic/verify-HDL probes under the RAM guard where
  host and descendant memory permit;
- preservation filters for `.247`, `.272`, `.295`, `.318`, and adjacent
  read-side samples;
- mdBook build;
- Knowledge Map generation/check;
- memory architecture check;
- diff whitespace check; and
- doctrine checks.

## Explicit Residue

Implementation of the two-dynamic-plus-one-static write demux, read
single-beat response-demux, read burst-last response-demux, read-data,
burst-length/runtime validation, multi-beat output banks, broader capped mixed
sets, same-cycle request widening, release-and-recapture, dynamic same-ID
queues, scoreboards, direct backend behavior, backend-language variants,
profile aliases, queued/blocking policy, full-manager behavior, and VHDL
remain separate exact owners.

## Rollback

Rollback is documentation-only: remove this audit note and fact card, restore
`.339` to pending, and restore README, ROADMAP_V2, mdBook, task tree, Memory,
and Knowledge Map to the post-`.338` state.
