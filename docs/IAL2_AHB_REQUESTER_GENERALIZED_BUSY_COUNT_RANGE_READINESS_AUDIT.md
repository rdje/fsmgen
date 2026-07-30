# IAL2 AHB Requester Generalized BUSY Count-Range Readiness Audit

Task-tree owner:
`IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.1`

Date: 2026-07-30

## Outcome

The audit selects one reusable, finite compile-time literal range:

```text
absence              => exactly 1 qualified BUSY event
(busy-beats N)       => exactly N qualified BUSY events, for N in 2..16
```

Proposed no-behavior contract `.2` must freeze that range before a separate
implementation changes the current shipped `2..4` admission boundary.

This is not an exact-five source selection. Existing tracked exact-one through
exact-four sources remain the examples and regression corpus; future custom
`.ppif` sources may use any canonical literal in `2..16` after implementation
without adding a catalog source, alias, paired composition, or support entry
for every count.

## Protocol And Product Boundary

The repo-local Arm AHB specification establishes three relevant rules:

- BUSY inserts idle cycles between transfers while preserving the next burst
  transfer's address/control;
- fixed-length bursts must end with `SEQ`, not `BUSY`; and
- a fixed-length waited BUSY may change to `SEQ` while `HREADY` is low, after
  which `SEQ` must hold until ready.

The specification sets no numeric limit on consecutive BUSY cycles. Therefore
16 is explicitly an FSMGen bounded-profile decision, not an AHB limit.

The selected maximum 16 is the strongest coherent current boundary because the
requester already declares `burst.max_beats=16`, `busy-before-beat` is bounded
to the 15 possible between-beat indices, and local length/beat-index/
beats-remaining use the existing five-bit bounded-requester class. Loading 16
into `ahb_busy_remaining_q` requires exactly five bits. Values above 16 remain
future range expansion even though the width helper could encode more.

## Lowering Readiness

Only three tracked code/report boundaries block the future range:

1. `_normalize_transfer` explicitly admits only `[234]` and diagnoses `2..4`;
2. `enforced_static_rules` says literal `2..4`; and
3. residue special-cases two/three and treats every later admitted value as
   exact four.

The lowering algorithm itself is already count-generic. `_counter_width`
implements the integer equivalent of `ceil(log2(N + 1))`, and generated
qualified retirement uses only:

```text
remaining > 1  => decrement
remaining == 1 => clear, restore address-pending ownership, resume SEQ
```

There is no exact-four branch. The selected width boundary is:

| Literal count | Counter width |
| ---: | ---: |
| 2, 3 | 2 |
| 4, 5, 6, 7 | 3 |
| 8 through 15 | 4 |
| 16 | 5 |

Contract `.2` must preserve canonical decimal spelling. Zero, one, 17 and
above, leading-zero forms, signs, symbols, expressions, references, malformed
values, missing prerequisites, and duplicate clauses remain fail closed.

## Disposable Structural And Semantic Probe

A repository-derived same-volume audit root copied the current CLI and
`AhbRequester` module, widened only the local admission/static-rule/residue
text, and created untracked count-5, count-8, and count-16 source transforms.
It did not modify any tracked source or load the patched module into the live
CLI.

Forty-six assertions passed:

- counts 5, 8, and 16 normalize and report numerically;
- generated IAL1 initializes the literal and derives widths 3, 4, and 5;
- the future static rule says `2..16`;
- unified residue states the source's exact numeric qualified count and keeps
  values above 16 plus dynamic/policy/random/symbolic and multiple-point work
  deferred;
- semantic MCP launched through the disposable repo root reports each exact
  module with `query_kind=semantic`, `read_only=true`, `shell_access=false`,
  and intentionally unmatched support; and
- 0, 1, 17, 32, and a symbolic count fail with the selected future diagnostic.

Public strict generation and `--verify-hdl` pass for all three candidates.
Each emits one IAL1 and one IAL0 review artifact plus the selected requester
HDL module.

## Assertion-Enabled Runtime Matrix

Verilator 5.046 compiled three generated requesters with `--timing`, `-j 1`,
and every generated selector assertion enabled. A generic disposable harness
ran seven scenarios:

| Count | Width | Continuous | 32-clock ready-low | 32-clock grant-low |
| ---: | ---: | :---: | :---: | :---: |
| 5 | 3 | pass | pass | pass |
| 8 | 4 | pass | — | — |
| 16 | 5 | pass | pass | pass |

Every run observed exactly:

- five transfer-type presentations around a four-beat `INCR4` request;
- four completed data beats;
- one BUSY episode;
- `N` grant-and-ready-qualified BUSY events;
- no count consumption during ready-low or grant-low stalls;
- stable pending address, control, write data, beat index, and remaining-data
  count throughout BUSY;
- one resumed `SEQ`; and
- zero final BUSY and burst counters.

No `--no-assert` or warning-specific suppression was needed; the standard
`-Wno-fatal` setting remained. The corrected harness also compiled without the
initial disposable width-comparison warning.

## Selected `.2` Contract Boundary

Contract `.2` must freeze, without behavior changes:

1. canonical literal `busy-beats` values `2..16`, with absence exact-one;
2. the exact future diagnostic and all fail-closed malformed boundaries;
3. unchanged integer-loop minimum-width lowering and qualified retirement;
4. unified numeric residue for every single/multiple count instead of
   count-specific source enumeration;
5. no report-schema or semantic/MCP API change;
6. unchanged exact-one-through-four source bytes, artifacts, identities, and
   runtime behavior;
7. unchanged 332/373/56 split 28 `.ppif`/28 `.ahb` support accounting;
8. future focused t1541 plus one generic assertion harness covering the
   2/4/5/7/8/15/16/17 parse-width-diagnostic boundary and the proven 5/8/16
   runtime matrix; and
9. a separate implementation leaf, preservation gates, mdBook examples,
   Knowledge Map, same-volume cleanup, resource evidence, and exact rollback.

Dynamic, policy-selected, random, symbolic, or runtime-selected counts,
multiple insertion points, distinct bus-BUSY status, new burst/signal/topology
semantics, generic rule/transaction priority, HIAL/VIAL, verification
generation, VHDL, portability, scale, other protocols/backends, and decision
`0020` remain separately owned.

Clean audit commit `18f63a971` activates only contract `.2`. The activation is
continuity-only: current literal `2..4`, all generated behavior and source
bytes, and 332/373/56 split 28 `.ppif`/28 `.ahb` remain unchanged while the
contract is frozen before implementation.

Completed contract `.2` selects proposed lowerer/test-only implementation
`.3`. It freezes canonical decimal `2..16` admission, the exact diagnostic,
unchanged minimum-width and qualified-retirement logic, unified numeric
residue, no count-specific public fixture, focused t1541 plus generic 5/8/16
assertion runtime, and unchanged 332/373/56 split 28/28. Contract review also
found two default `File::Temp` workspaces in touched t1535; `.3` owns their
move to `.artifacts/tmp/tests`. See
`docs/IAL2_AHB_REQUESTER_GENERALIZED_BUSY_COUNT_RANGE_CONTRACT_SELECTION.md`.

## Resource And Cleanup Evidence

The exact disposable audit workspace contained 92 files and 7,016,808 bytes,
including three generated HDL modules, three IAL1 artifacts, three IAL0
artifacts, and three local Verilator object trees. It was removed exactly.
`.artifacts/tmp/tests` is empty; only the pre-existing 491-byte
`.artifacts/tmp/xcrun_db` cache remains.

Heavy commands used the authorized host-100/process-4096 RAM guard. Capacity
truth is recorded separately with the canonical Stats-compatible Mach-page
formula and kernel pressure state; guard occupancy is not capacity truth.

## Rollback

Rollback of the activation reverts its continuity pointers only. It leaves
current literal `2..4`, exact-one-through-four sources, all generated behavior,
reports, tests, support accounting, and simulator profiles unchanged.
