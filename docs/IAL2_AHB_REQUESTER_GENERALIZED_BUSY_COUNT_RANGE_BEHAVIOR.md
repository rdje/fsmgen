# IAL2 AHB Requester Generalized BUSY Count Range Behavior

Task-tree owner:
`IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.3`

Date: 2026-07-30

## Shipped Outcome

The AHB requester now accepts canonical unsigned decimal `busy-beats` literals
`2..16`. Omitting `busy-beats` remains the exact-one form. This ships through
the existing IAL2 -> IAL1 -> IAL0 -> HDL lowerer without adding a public source
or support entry for every admitted count.

Existing exact-one through exact-four generic/profile requester sources and
their paired compositions remain byte-identical. Support accounting therefore
stays exactly 332 protocol fixtures, 373 supported-smoke plus strict entries,
and 56 AHB paths split 28 `.ppif` / 28 `.ahb`.

## Public Form

Use the optional count with the existing BUSY insertion point:

```text
(transfer
  (idle 2'b00)
  (busy 2'b01)
  (nonseq 2'b10)
  (seq 2'b11)
  (first-beat nonseq)
  (later-beats seq)
  (advance-on ready)
  (busy-before-beat 2)
  (busy-beats 16))
```

The complete source still supplies the standard requester command/status/bus,
burst, and response blocks. `busy-before-beat` remains a literal `1..15` and
requires BUSY encoding `2'b01`.

Accepted explicit tokens are exactly `2` through `9` and `10` through `16`.
The following fail closed:

- `0`, `1`, and `17` or larger;
- `02`, `+2`, `-2`, `0x2`, and `2.0`;
- symbols and other non-literal scalar tokens;
- nested references and expressions; and
- duplicate count clauses.

Malformed scalar tokens receive:

```text
AHB requester transfer.busy_beats must be a canonical decimal literal integer in 2..16 in this slice
```

Nested reference/expression forms fail earlier at the PPIF literal-block
scalar-shape gate. Duplicate clauses retain the scalar-duplicate diagnostic.

## Generated Meaning

The lowerer derives the actor-owned remaining-counter width with
`ceil(log2(busy_beats + 1))` integer-loop semantics:

| count | width |
| ---: | ---: |
| 2 | 2 |
| 4 | 3 |
| 5 | 3 |
| 7 | 3 |
| 8 | 4 |
| 15 | 4 |
| 16 | 5 |

Insertion loads literal N. Only an event satisfying
`HGRANT && HREADY && HTRANS == BUSY` retires the count. Counts above one
decrement; the event at one clears the counter, restores address-pending
ownership, and resumes the held pending transfer once as `SEQ`. Ready-low and
grant-low clocks consume no count. BUSY completes no data beat or response and
holds address, control, write data, beat index, and remaining data-beat state.

Reports keep their existing schema. Explicit counts remain numeric in
`transfer.busy_beats` and `busy_insertion.beats`; absence keeps the compatible
`busy_insertion.beats=single` token. Residue id
`ahb_requester_busy_insert_support` now states the exact numeric singular or
plural event count and the supported canonical `2..16` range without naming a
catalog fixture for every value.

## Verification

Focused `t/1541-ial2-ahb-requester-generalized-busy-count-range.t` proves:

- absence plus admitted `2/4/5/7/8/15/16` and malformed boundaries;
- widths `2/3/3/3/4/4/5`, literal loads, numeric reports, static rules, and
  residue;
- strict/check, schedule, review artifacts, normalized semantic JSON, real
  repo-relative read-only shell-disabled MCP, and public HDL verification for
  repository-local unmatched count-5/8/16 candidates; and
- assertion-enabled Verilator 5.046 `--timing -j1` runtime for 5/8/16
  continuously qualified plus 32-clock ready-low and grant-low cases at 5 and
  16.

All seven runs observe five non-IDLE presentations, four completed data beats,
one BUSY episode, exactly N qualified events, minimum width, stable pending
state, one resumed `SEQ`, and zero final counter. Generated assertions remain
enabled; no `--no-assert` or warning-specific suppression is used.

Run the focused public proof:

```bash
scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- prove t/1541-ial2-ahb-requester-generalized-busy-count-range.t
```

The exact-one-through-four generic requester preservation suite passes 4
files/20 top-level tests. One-/two-window exact-four paired preservation passes
2 files/8 top-level tests, including the full two-command runtime. Requester
and paired alias parity plus t248/t297 accounting/capability preservation also
pass at unchanged 332/373/56 split 28/28.

## Same-Volume Verification Locality

Implementation review expanded the contract-time t1535 finding to every
existing requester count test touched by the shared report change. Exact-one
through exact-four generic/profile requester tests now create explicit
workspaces through `FSM::ProjectDataLocality` under `.artifacts/tmp/tests` and
configure subprocess temp roots there. The four exact-four paired generic/
profile tests already used repository-local explicit workspaces and now also
configure their subprocess temp environment. t1541 uses the same mechanism.

No public source or simulator behavior depends on this test-local migration.
Every focused run leaves `.artifacts/tmp/tests` empty.

## Non-Selections And Rollback

Counts above 16, symbolic/policy/runtime/random count selection, multiple
insertion points, distinct bus-BUSY status, new burst/signal/topology semantics,
generic rule/transaction priority, HIAL/VIAL, verification generation, VHDL,
portability, scale, other protocols/backends, and decision `0020` remain
separately owned.

Rollback restores the three AhbRequester admission/static-rule/residue regions
to literal `2..4`, restores affected report/diagnostic expectations, removes
t1541 and its generic testbench, and retains every existing public source and
support entry. The same-volume test migrations are independently safe to keep.

Clean behavior commit `2f64611ca` activates parent selector `.830` as a
continuity-only transition. Shipped `2..16` behavior, t1541 proof, public
source bytes, support accounting, and every deferred boundary remain
unchanged during selection.

Completed selector `.830` chooses the separate protocol-neutral
transaction-invoked named-drive priority audit. It changes no AHB behavior:
canonical decimal `2..16`, t1541, and 332/373/56 split 28/28 remain current.
