# IAL2 Post-Two-Subordinate Exact-Four Paired Alias Next-Owner Selection

## Selection

`IAL2-FEATURE-COMPLETENESS-FRONTIER.829` selects proposed
`IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.1` as the next
bounded SystemVerilog-backed IAL2 owner.

The selected leaf is a no-behavior readiness audit. It must choose and prove a
reusable finite literal `busy-beats` range above four before any public
normalization, generated artifact, runtime, report, residue, or diagnostic
change. It explicitly avoids extending the completed exact-one-through-four
family with an unbounded exact-five/exact-six fixture cadence.

## Reconciled Boundary

Clean behavior commit `3519cde33` completes exact-one through exact-four across
generic/profile requester sources and one-/two-window paired generic/profile
sources. Current accounting is 332 protocol fixtures, 373 supported-smoke plus
strict fixtures, and 56 AHB paths split 28 `.ppif` / 28 `.ahb`.

The shipped literal-count contract is:

- absence means exact one;
- literals `2..4` are accepted;
- zero, one, five and above, references, expressions, and malformed forms fail
  closed;
- minimum counter width is `ceil(log2(busy_beats + 1))` by integer iteration;
- retirement occurs only on `HGRANT && HREADY && HTRANS == BUSY`;
- BUSY completes no data beat, pending state stays stable, and the same transfer
  resumes once as `SEQ`; and
- exact-four generic runtime authority t1535 proves continuous, 32-clock
  ready-low, and 32-clock grant-low scenarios with `4 -> 3 -> 2 -> 1 -> 0`.

The completed paired families reuse that requester and add no separate count
semantics. t1537 and t1539 prove one- and two-window exact-four integration;
t1538 and t1540 prove their byte-identical alias parity without extra
simulation.

## Direct Readiness Evidence

An in-memory transform of
`ppif/ahb_requester_busy_insert_four.ppif` to exact five fails before output
with exactly the current range diagnostic:

```text
AHB requester transfer.busy_beats must be a literal integer in 2..4 in this slice
```

Inspection of `AhbRequester` isolates the admission boundary and follow-on
contract work:

- normalization explicitly accepts only `[234]`;
- the report static-rule text explicitly says `2..4`;
- residue branches exact-two, exact-three, then treats every larger admitted
  value as exact-four;
- `_counter_width` is already value-generic and returns widths 3 for 5/7, 4 for
  8/15, and 5 for 16/31; and
- the generated BUSY rules use only `> 1` and `== 1`, so they contain no
  exact-four control-flow special case.

This proves that a lower-layer algorithm rewrite is not yet justified, but it
does not prove a safe public maximum or assertion runtime at each width
transition. Those are exactly the selected audit's responsibilities.

## Candidate Comparison

| Candidate | Selection result | Evidence |
| --- | --- | --- |
| Reusable bounded literal count range above four | **selected for readiness audit** | Smallest adjacent public gap; current lowerer is already width-generic, while range, residue, diagnostics, representative runtime, and verification cost remain unproved. |
| Exact-five public fixture and alias/composition replication | not selected | Would repeat four source/topology variants per count and create an open-ended fixture cadence without establishing a reusable contract. |
| Runtime/policy/random/symbolic counts or multiple insertion points | deferred | Adds new ownership and dynamic semantics rather than widening the existing compile-time literal contract. |
| Rule/transaction output-priority enforcement | remains proposed | Real protocol-neutral correctness gap, but current qualified multi-BUSY path avoids the conflicting selector mechanism; it is not prerequisite to literal count widening. |
| HIAL/VIAL and verification generation | remains proposed | Strategic peer-intent architecture with typed bridge, portable/native semantics, full-language UVM authority, VHDL, mixed-language, migration, and scale gates; broader than this adjacent audit. |
| VHDL/portability | remains deferred/separate | Direct VHDL work remains behind SystemVerilog-backed IAL feature completeness and independent qualification. |
| End-to-end large-design scalability | remains proposed | Foundational requirement, but its workload/budget contract is not prerequisite to this bounded semantic audit; the audit must still measure its own runtime/resources. |
| Other protocols/backends | deferred | No evidence makes them a prerequisite to closing the current AHB literal-count boundary. |
| Decision `0020` transaction roles | inactive by decision | Directional North Star is explicitly not PNT-eligible until director activation. |

## Selected Audit Contract

The audit must not preselect an arbitrary maximum. It will compare protocol and
source limits, existing five-bit local length/status widths, counter-width
transitions, generated literal representation, simulation cost, diagnostic
clarity, and stable regression coverage. Repository-derived disposable
candidates must cover the first value above four and each relevant width
boundary; assertion-enabled representative runs must prove exact qualified
retirement, ready/grant stalls, stable ownership, one resumed `SEQ`, unchanged
data-beat completion, and zero final count.

If a reusable range is ready, the audit must freeze one later public widening
without requiring a catalog fixture for every admitted count. It must specify
whether support accounting remains 332/373/56, exact report/residue and
diagnostic changes, focused tests for lower/upper/transition/out-of-range
values, semantic/MCP and HDL-verifier preservation, mdBook examples, rollback,
and the separate implementation owner. If evidence exposes a lower-layer bug
or impractical verification boundary, it must select the smallest prerequisite
or narrower range instead.

## Preserved Boundaries

Selection changes no parser, generator, public source, support entry, test,
checked-in artifact, report/schema, semantic/MCP API, HDL/runtime, simulator
integration, backend, protocol, HIAL/VIAL, verification-generation, VHDL,
portability, scale, decision-`0020`, or transaction behavior. Current
332/373/56 split 28/28 behavior remains authoritative.

Verilator remains the event-capable compiled portable-fast supported-subset
profile, separate from a qualified full-language/SystemVerilog-UVM authority.
VHDL and mixed-language profiles remain independently qualified.

## Validation, Resources, And Rollback

The selector closes with focused current-surface/backlog/path checks,
Knowledge Map generation/check, mdBook rendering and exact cleanup, diff and
all doctrine gates. Heavy commands use authorized `--host-max-pct 100
--process-max-rss-mb 4096`. Capacity truth uses the canonical Stats-compatible
Mach-page formula and reports kernel pressure separately; guard occupancy is
not capacity truth. Project-owned temporary data remains on repository-derived
same-volume paths.

Rollback removes this selector/fact and proposed audit tree only. All shipped
exact-one-through-four behavior and 332/373/56 accounting remain unchanged.
