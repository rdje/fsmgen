# IAL2 Post-Two-Subordinate Exact-Three Paired Alias Next-Owner Selection

## Selection

`IAL2-FEATURE-COMPLETENESS-FRONTIER.822` selects proposed readiness leaf:

`IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.1`

The audit must determine the smallest correct counter-width contract for
literal `(busy-beats 4)` before any parser range, generator, public source,
support, report, test, or runtime behavior changes.

## Reconciled Boundary

Clean behavior commit `db402fd9d` completes the bounded exact-one/two/three
requester and one-/two-window paired-composition generic/profile cadence.
Current accounting is 326 protocol fixtures, 367 supported-smoke plus strict
fixtures, and 50 AHB IAL2 paths split 25 `.ppif` / 25 `.ahb`. Exact-one uses
the one-event flag path. Exact-two and exact-three share the actor-owned
`ahb_busy_remaining_q`, qualified continuation/final-accept rules, stable
ready-low/grant-low behavior, and width-two storage.

The current normalizer accepts only literal `busy-beats` values `2..3`. The
generator declares:

```text
(var ahb_busy_remaining_q (width 2) (reset 0))
```

Reports state the `2..3` bound and current residue explicitly defers counts
above three. Literal four is therefore the first adjacent count that cannot be
represented by the shipped counter; it is not merely another data-only source.

## Same-Volume Exact-Four Probe

A repository-derived candidate copied the 2,313-byte exact-three requester and
changed only intent/object/anchor/actor identity plus `(busy-beats 3)` to
`(busy-beats 4)`. Strict check failed before generation with one diagnostic:

```text
AHB requester transfer.busy_beats must be a literal integer in 2..3 in this slice
```

No output was emitted and support remained unmatched. The exact one-file/
2,313-byte disposable tree was removed without residue. This is the intended
current fail-closed boundary, not a parser or runtime defect.

Static generator inspection identifies the next required question precisely:
whether a bounded three-bit counter with unchanged ready-qualified continuation
and final-accept rules is sufficient, or whether reusable minimum-width
derivation must be selected first. The readiness audit must prove this through
IAL2 -> IAL1 -> IAL0 -> SystemVerilog and assertion-enabled continuous,
ready-low, and grant-low runtime before choosing a public contract.

## Why This Owner Is Next

The roadmap still gives priority to SystemVerilog-backed IAL2 completeness.
Exact four is the smallest adjacent extension because it reuses the existing
public `busy-beats` clause, insertion point, transfer semantics, and qualified
rules while isolating the first real width boundary. It outranks:

- policy/runtime/random or multiple-point BUSY insertion, distinct bus-BUSY
  status, wider/indefinite bursts, and optional signals, all of which introduce
  new semantics rather than one bounded count;
- `ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT`, whose own activation
  boundary remains after current AHB work dries out;
- HIAL/VIAL, which remains a broader architecture audit covering layer
  topology, typed bridges, portable/native fixtures, multiple output languages,
  simulator capability profiles, migration, and scale; and
- end-to-end really-big-design scalability and decision `0020`, which remain
  separately proposed foundational directions.

HIAL/VIAL remains durable and inactive. Verilator continues to qualify the
portable-fast supported subset as event-capable compiled simulation with
`--timing`, not as a traditional full-SystemVerilog-LRM/UVM event-driven
authority. A separately qualified full-language/UVM profile plus independent
VHDL/mixed-language profiles remains required.

## Selected Readiness Contract

The proposed audit must:

1. reconcile exact-one/two/three sources, aliases, runtime, compositions,
   parser/report/residue, semantic/read-only-MCP, and support surfaces;
2. recreate only a repository-derived same-volume exact-four candidate and
   preserve exact identity/anchor/actor delta evidence;
3. determine whether width three is sufficient for the bounded literal or a
   reusable `ceil(log2(beats + 1))`-style derivation must be selected;
4. prove the chosen candidate through exact IAL1/IAL0 artifacts, generated HDL,
   internal `4 -> 3 -> 2 -> 1 -> 0`, four qualified BUSY events, stalls, resumed
   `SEQ`, and unchanged four-beat command completion with assertions enabled;
5. verify strict/check/schedule/normalized-semantic/real read-only MCP and
   existing exact-one/two/three preservation;
6. if ready, select a separate public-contract leaf with exact range,
   diagnostics, source/support/accounting, tests, documentation, cleanup,
   rollback, and remaining residue; and
7. stop at the smallest prerequisite if IAL1, IAL0, SystemVerilog, or selector
   behavior disproves the bounded-width hypothesis.

The audit makes no tracked behavior change. Policy/runtime/random and
multiple-point insertion, counts beyond the selected bound, bus-BUSY status,
broader bursts/signals/topologies, backends, VHDL, verification generation,
HIAL/VIAL activation, and decision `0020` remain separate.

## Validation And Resource Boundary

Focused current-surface/backlog/path tests, Knowledge Map generation/check,
mdBook build with exact cleanup, diff/path checks, and all doctrine gates close
the selector. Heavy commands use authorized `--host-max-pct 100
--process-max-rss-mb 4096`. Capacity truth uses the Stats-compatible Mach-page
formula, with kernel pressure reported separately. All disposable data remains
under repository-derived same-volume paths.

## Rollback

Rollback removes only the proposed exact-four readiness tree and this selector
record/fact, returning parent `.822` to active selection while leaving shipped
326/367/50 behavior unchanged.
