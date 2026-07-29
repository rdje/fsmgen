# IAL2 Post-Exact-Four Requester Alias Next-Owner Selection

## Selection

`IAL2-FEATURE-COMPLETENESS-FRONTIER.823` selects proposed readiness leaf:

`IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`

The audit must prove the shipped exact-four requester inside the existing
one-subordinate BUSY-parking aggregate with assertions enabled before any new
public paired source, support identity, test, or behavior is selected.

## Reconciled Boundary

Clean behavior commit `ba2d1c01f` completes the exact-one through exact-four
requester generic/profile family. Current accounting is 328 protocol fixtures,
369 supported-smoke plus strict fixtures, and 52 AHB IAL2 paths split 26
`.ppif` / 26 `.ahb`. Exact-four uses width-three
`ahb_busy_remaining_q`, literal load four, qualified `> 1` decrement and
`== 1` clear/`SEQ` handoff, and assertion-enabled t1535 runtime. t1536 proves
the matching alias without a second simulation.

The one-/two-subordinate exact-one/two/three paired families already establish
BUSY-parking endpoint and one-hot interconnect ownership. The first missing
adjacent cell is the one-subordinate exact-four pairing.

## Same-Volume Feasibility Probe

A repository-derived candidate copied the shipped one-subordinate exact-three
paired source and changed only intent/object/anchor/requester identities plus
`(busy-beats 3)` to `(busy-beats 4)`. Its future generic identity is:

```text
path: ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif
top:  ahb_tb
children:
  amba_requester_busy_insert_four
  ahb_lite_subordinate_byte_lane_hburst_seq
  ahb_interconnect
```

Strict check succeeds with zero diagnostics and intentionally unmatched
support. Schedule and normalized semantic JSON report schema
`fsmgen.ial2.protocol_intent.ahb_interconnect.v1`, root `top`, three children,
28 top signals, one-hot accepted-subordinate response ownership, requester
`before_beat=2` / `beats=4`, and child plus propagated `parks_on=[busy]`.
Lowering emits exactly three IAL1 and four IAL0 review artifacts. The requester
IAL1 contains width-three storage, literal load four, and the existing
qualified decrement/clear rules. Public `--verify-hdl` passes.

The exact 9-file / 1,247,052-byte disposable workspace was removed without
residue. No assertion-enabled aggregate runtime was inferred; that is the
selected audit's central responsibility.

## Why This Owner Is Next

The one-window exact-four composition is the smallest adjacent roadmap gap. It
reuses shipped syntax, requester, subordinate, interconnect, schedule,
semantic, and verifier machinery while adding no new policy or topology. It
outranks:

- two-window exact-four composition, which should follow the smaller topology;
- counts above four, which reopen the bounded count/range contract;
- runtime/random policy, multiple insertion points, local bus-BUSY status,
  wider bursts, and optional signals, which introduce new semantics;
- generic selector-priority repair, which remains separately proposed after
  current AHB work dries out;
- HIAL/VIAL, whose typed bridge, portable/native verification semantics,
  SV/UVM and VHDL lowerings, simulator profiles, migration, and scale gates
  remain a broader architecture program; and
- end-to-end really-big-design scalability and decision `0020`, which remain
  separate foundational directions.

Verilator remains the event-capable compiled portable-fast subset profile,
particularly with `--timing`; it is not treated as a full-SystemVerilog-LRM or
UVM authority. A separately qualified full-language/UVM simulator profile and
independent VHDL/mixed-language profiles remain required.

## Selected Readiness Contract

The proposed audit must:

1. recreate only the repository-derived same-volume one-window exact-four
   candidate and prove strict/check/schedule/artifact/semantic/read-only-MCP
   parity;
2. compile generated `ahb_tb` with every selector assertion enabled;
3. prove five transfer presentations, four accepted data beats, one BUSY
   episode, four ready-qualified BUSY events, internal `4 -> 3 -> 2 -> 1 -> 0`,
   one resumed `SEQ`, stable requester/subordinate/fabric ownership, and final
   storage `0x44332211`;
4. preserve standalone exact-four t1535/t1536 and paired exact-three t1531;
5. if ready, select a separate generic public-contract leaf projecting 329
   protocol / 370 supported+strict / 53 AHB paths split 27 `.ppif` / 26 `.ahb`;
6. keep the matching alias and two-subordinate exact-four cadence separate; and
7. stop at the smallest prerequisite if runtime, semantic/MCP, or assertion
   evidence disproves direct composition readiness.

The selector itself changes no public source, support, test, artifact, API,
HDL/runtime, simulator integration, backend, protocol, HIAL/VIAL, VHDL,
verification-generation, or transaction behavior.

## Validation And Rollback

Focused current-surface/backlog/path tests, Knowledge Map generation/check,
mdBook build with exact cleanup, all doctrine gates, exact Stats-compatible RAM
capacity, and separate kernel pressure close the selector. Heavy work uses the
authorized host-100/process-4096 profile and repository-derived same-volume
paths.

Closeout passes 3 focused files / 22 top-level tests including 66 nested AHB
assertions. The Knowledge Map contains 1,038 facts / 5,303 keys. mdBook builds
72 files / 16,281,044 bytes and the exact render is removed. Canonical RAM is
60.2% (14.455/24.000 GiB; 15,520,415,744 bytes) with separate normal kernel
pressure level 1; guard occupancy and inverted `memory_pressure` free
percentage are not capacity truth.

Rollback removes this record/fact and the proposed exact-four paired audit
tree, returning `.823` to active selection without changing shipped 328/369/52
behavior.
