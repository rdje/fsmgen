# IAL2 AHB Requester Exact-Four BUSY-Insertion Readiness Audit

Task-tree owner:
`IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.1`

Date: 2026-07-29

## Outcome

Literal `(busy-beats 4)` is lower-layer and runtime ready when the requester
remaining counter is three bits wide. The shipped qualified non-final/final
rules already implement `4 -> 3 -> 2 -> 1 -> 0`; no IAL1, IAL0,
SystemVerilog, scheduler, assertion, or simulator repair is required.

The public implementation must not hardcode width three for every multiple-
BUSY source, because that would change the generated exact-two and exact-three
IAL1/IAL0/SystemVerilog artifacts without need. The smallest preserving rule is
the minimum unsigned width able to represent `0..busy_beats`:

```text
counter_width = ceil(log2(busy_beats + 1))
2 -> width 2
3 -> width 2
4 -> width 3
```

The audit therefore selects proposed no-behavior contract leaf
`IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.2`. It does not
broaden the public range or ship an exact-four source.

## Public Fail-Closed Boundary

A repository-local exact-four candidate copied the 2,313-byte shipped
exact-three source and changed only intent, object, anchor, actor, and
`(busy-beats 3)` to `(busy-beats 4)`. Strict JSON check stopped before
generation with exactly one error:

```text
AHB requester transfer.busy_beats must be a literal integer in 2..3 in this slice
```

The result reported `success=false`, one error diagnostic, unmatched support,
and `generated_output.emitted=false`. This is the intentional public-contract
boundary, not a parser or lower-layer defect.

## Disposable Lower-Layer Candidate

The audit generated the shipped exact-three IAL1 and made exactly three
changes in a disposable copy:

```diff
-(actor amba_requester_busy_insert_three
+(actor amba_requester_busy_insert_four
-    (var ahb_busy_remaining_q (width 2) (reset 0)))
+    (var ahb_busy_remaining_q (width 3) (reset 0)))
-          (set ahb_busy_remaining_q 3)
+          (set ahb_busy_remaining_q 4)
```

The qualified `> 1` decrement, `== 1` final clear/address-pending/SEQ handoff,
whole-BUSY continuation, rule priorities, transaction ownership, and every
other IAL1 line remained unchanged. Strict IAL1-to-SystemVerilog lowering and
public `--verify-hdl` both passed. Generated SystemVerilog contained a 3-bit
`ahb_busy_remaining_q`, initialization to four, decrement by one, final clear,
and the existing selector assertions.

## Exact Runtime Result

Verilator 5.046 compiled one assertion-enabled `--timing` binary without
`--no-assert`. The adapted exact-three fixture changed only module identity and
the expected four-event counter sequence.

| Scenario | Qualified BUSY events | Stalled BUSY clocks | Transfer presentations | Data beats | Final BUSY counter |
| --- | ---: | ---: | ---: | ---: | ---: |
| continuously qualified | 4 | 0 | 5 | 4 | 0 |
| ready low for 32 clocks | 4 | 32 | 5 | 4 | 0 |
| grant low for 32 clocks | 4 | 32 | 5 | 4 | 0 |

Every run directly observed pre-retirement counter values `4`, `3`, `2`, and
`1`, then zero on resumed `SEQ`. Both stall modes held the counter at four and
consumed no event. Pending address/control/write-data and public beat counters
stayed stable, BUSY completed no data beat, the same pending transfer resumed
once, four byte `INCR4` beats completed, and all selector assertions stayed
quiet.

This proves that a bounded 3-bit declaration is sufficient at the lower
layers. Minimum-width derivation is required only as a public-generator
preservation prerequisite, not as a new IAL1 language feature.

## Selected Next Contract Boundary

Leaf `.2` must reconcile this proof with the exact-one/two/three generic and
alias family, then select or reject exactly one additive generic exact-four
source. If selected, it must freeze:

- public literal range `2..4` and a matching diagnostic, while absence remains
  canonical exact-one;
- `counter_width = ceil(log2(busy_beats + 1))`, with exact-two and exact-three
  generated counter widths remaining two and exact-four width three;
- exact intent/object/anchor/actor/module/artifact/support/coverage identities;
- numeric report and truthful exact-one/two/three/four residue;
- normalized semantic JSON and common read-only, shell-disabled MCP parity;
- one assertion-enabled continuous/ready-low/grant-low runtime fixture with
  direct `4 -> 3 -> 2 -> 1 -> 0` observation;
- malformed values, prior source bytes, generated artifact behavior, paired
  compositions, diagnostics, support accounting, docs, cleanup, and rollback;
  and
- generic-first sequencing, with any `.ahb` alias owned separately.

Counts above four, arbitrary/runtime/policy/random counts, multiple insertion
points, local bus-BUSY status, new burst/signal/topology behavior, generic
priority work, other protocols/backends, HIAL/VIAL activation, VHDL,
verification generation, and decision `0020` remain separate.

## Resource And Cleanup Evidence

All candidate and generated data lived beneath repository-local
`.artifacts/tmp/ial2-ahb-requester-exact-four-readiness-audit`. The final
workspace contained exactly 32 files / 2,510,723 bytes, including the exact
2,313-byte public candidate, 12,007-byte IAL1 variant, 238,282-byte generated
SystemVerilog, fixture, and Verilator build products. The exact workspace was
removed recursively, and both direct-path and wildcard residue checks are
empty.

Heavy commands used the authorized host-100/process-4096 profile. The guard's
94.8%-99.3% occupancy heuristic was not interpreted as RAM capacity. The
post-cleanup canonical Stats-compatible formula reported 74.8%
(17.952/24.000 GiB), while kernel pressure independently remained `1`
(normal).

No tracked parser, generator, source, support, test, artifact, semantic/MCP
API, HDL/runtime, backend, protocol, verification-generation, HIAL/VIAL, VHDL,
or transaction behavior changed.

## Rollback

Remove this audit record and fact, restore `.1` to active, remove proposed
`.2`, and revert the synchronized task/index/Memory/roadmap/mdBook/HIAL-VIAL
pointers. There is no shipped behavior to revert.
