# IAL2 AHB Requester Exact-Three BUSY Event Behavior

Task-tree owner:
`IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.3`

Date: 2026-07-29

## Outcome

FSMGen now ships the additive generic requester source:

```text
ppif/ahb_requester_busy_insert_three.ppif
```

It inserts exactly three grant-and-ready-qualified `HTRANS=BUSY` events before
one selected pending `SEQ` transfer. It uses the existing `AhbRequester`
generator and mandatory IAL2 -> IAL1 -> IAL0 -> HDL pipeline; there is no new
generator or semantic/MCP API.

Its public identity is:

```text
intent:          ahb_requester_busy_insert_three
source object:   fsmgen-ahb-requester-busy-insert-three
anchor section:  bounded-requester-three-busy-insertion
actor/module:    amba_requester_busy_insert_three
IAL1:            amba_requester_busy_insert_three.isf
IAL0:            amba_requester_busy_insert_three.fsm
support id:      intent.ppif_ahb_requester_busy_insert_three
coverage:        ial2_ppif_ahb_requester_busy_insert_three_pipeline_cli
source kind:     ppif
semantic root:   fsm
```

The matching byte-identical `.ahb` alias now also ships through completed `.5`:

```text
ppif/ahb_requester_busy_insert_three.ahb
```

Canonical alias behavior is documented in
`docs/IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_PROFILE_ALIAS_BEHAVIOR.md`.

## Public Count Boundary

The optional transfer clause now accepts exact literal integers `2..4`:

```text
(busy-before-beat 2)
(busy-beats 3)
```

Absence remains canonical exact-one. Literal two retains its existing
exact-two behavior. Zero, one, values above four, symbolic/non-literal forms,
missing prerequisites, and duplicates fail closed. The range diagnostic is:

```text
AHB requester transfer.busy_beats must be a literal integer in 2..4 in this slice
```

`busy-beats 3` means exactly three rising events satisfying:

```text
HGRANT && HREADY && HTRANS == 2'b01
```

Ready-low and grant-low clocks consume no count. BUSY completes no data beat
or response. The pending address, control, write data, beat index, and
data-beat remaining state stay stable until the same transfer resumes as
`SEQ`.

## Unchanged Generated Lowering

The source reuses the shipped actor-owned width-two counter:

```text
(var ahb_busy_remaining_q (width 2) (reset 0))
```

The insertion transaction initializes it from literal three before BUSY
becomes visible. Existing qualified rules retire `3 -> 2 -> 1 -> 0`: the
`> 1` rule decrements, while the `== 1` rule clears the counter, sets existing
`ahb_address_pending_q`, and drives `SEQ`. The whole-BUSY continuation gate,
`busy_inserted_q`, final-over-nonfinal priority, both BUSY rules' priority over
`ahb_request`, and every address/data/response owner are unchanged.

## Reports, Residue, And Support

The exact-three source reports:

```text
transfer.busy_beats                  = 3
busy_insertion.generated_behavior   = true
busy_insertion.htrans_busy_encoding = 2'b01
busy_insertion.before_beat          = 2
busy_insertion.beats                = 3
```

Exact-one keeps `beats=single`; exact-two keeps numeric `beats=2`. Shared
residue now tells the complete truth: exact-one names all three additive
generic sources, exact-two acknowledges exact-three and exact-four, exact-three
acknowledges exact-four, and all defer only counts above four plus generalized
policy/runtime/random and multiple-point insertion. Existing `.ahb` suffix
cleanup remains unchanged.

The generic source established the 321/362/45 checkpoint and the matching alias
established 322/363/46. The generic exact-three paired source established
323/364/47; its matching alias established 324/365/48. The generic
two-subordinate exact-three paired source established 325/366/49; its matching
alias established 326/367/50. The generic exact-four requester established
327/368/51; its matching alias now moves current accounting to 328 protocol
fixtures, 369 supported-smoke plus strict fixtures, and 52 AHB IAL2 paths: 26
generic `.ppif` sources and 26 `.ahb` aliases.

## Generated-HDL Proof

Assertion-enabled `t/1528-ial2-ahb-requester-three-busy-insert.t` compiles one
generated requester and runs:

| Scenario | Held BUSY clocks | Qualified BUSY events | Internal counter | Data beats |
| --- | ---: | ---: | --- | ---: |
| continuously qualified | 0 | 3 | `3 -> 2 -> 1 -> 0` | 4 |
| `HREADY=0` after first visible BUSY | 32 | 3 after release | held at 3, then `3 -> 2 -> 1 -> 0` | 4 |
| `HGRANT=0` after first visible BUSY | 32 | 3 after release | held at 3, then `3 -> 2 -> 1 -> 0` | 4 |

Every scenario observes one BUSY episode, no stall-time consumption, stable
pending ownership, no BUSY data/response completion, exactly one resumed
`SEQ`, four accepted byte `INCR4` data beats, and zero final public and private
remaining counts. The focused suite passes five top-level subtests with 87
nested assertions.

The same slice strengthens t1521 so exact-two directly observes private
`2 -> 1 -> 0` retirement and stall stability rather than inferring it from the
public burst counter.

## Preservation Matrix

Every affected requester and paired-composition boundary passes under the
unchanged RAM guard:

| Test | Result | Wall time |
| --- | --- | ---: |
| t1498 + t1521 | exact-one plus strengthened assertion-enabled exact-two runtime; 10 top-level subtests | 62 s |
| t1528 | exact-three source/runtime/semantic/MCP contract; 5 top-level subtests, 87 nested assertions | 48 s |
| t1529 | exact-three alias report/artifact/semantic/MCP/verifier/diagnostic parity; 4 top-level subtests, 72 nested assertions; no second runtime | 53 s |
| t1512 | exact-one requester `.ahb` alias parity; 4 top-level subtests | 24 s |
| t1522 | exact-two requester `.ahb` alias parity; 4 top-level subtests | 47 s |
| t1523 | one-subordinate generic exact-two paired runtime/parity; 4 top-level subtests | 327 s |
| t1524 | matching one-subordinate exact-two alias parity; 4 top-level subtests | 368 s |
| t1525 | two-subordinate generic exact-two paired runtime/parity; 3 top-level subtests | 603 s |
| t1526 | matching two-subordinate exact-two alias parity; 4 top-level subtests | 722 s |

t248 plus t297 pass 6,911 assertions over the updated accounting/capability
boundary. Strengthened t1518
passes five top-level subtests and locks exact-one, exact-two, exact-three,
paired, alias, mdBook, and Knowledge Map fact truth against stale exact-two
ceilings or pre-323 accounting.

Two t1526 attempts were safely stopped by the guard when an unrelated `pgen`
compiler pushed host memory above the 88% cutoff. The complete 722-second rerun
started at 65.1% host memory and passed without changing either resource cap or
interfering with the external workload.

## Semantic And Tooling Parity

Strict check, schedule JSON, exact review artifacts, generated HDL,
`--verify-hdl`, normalized semantic JSON, and the real common
`fsmgen_semantic_introspect` tool all pass. The MCP result keeps:

```text
source_id    = ppif/ahb_requester_busy_insert_three.ppif
read_only    = true
shell_access = false
module       = amba_requester_busy_insert_three
root kind    = fsm
```

No feature-specific method or raw private lowering payload is exposed.

## Use It

Run heavy commands under the repository RAM guard:

```bash
scripts/run_with_ram_guard.sh -- ./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester_busy_insert_three.ppif
scripts/run_with_ram_guard.sh -- ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester_busy_insert_three.ppif
scripts/run_with_ram_guard.sh -- ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester_busy_insert_three.ppif
scripts/run_with_ram_guard.sh -- ./bin/fsmgen --quiet --strict --verify-hdl ppif/ahb_requester_busy_insert_three.ppif
scripts/run_with_ram_guard.sh -- ./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester_busy_insert_three.ahb
```

Generated outputs should use a repository-derived same-volume path.

## Explicit Deferrals

The matching exact-three `.ahb` alias and the generic exact-four requester now
ship. Counts above four, runtime/policy/random count selection, multiple
insertion points, distinct local bus-BUSY status, broader
bursts/signals/managers/fabrics, AXI/APB/VHDL, and decision 0020 remain separate
and inactive. The generic one-subordinate exact-three paired source now ships
through its completed implementation leaf; its matching alias and the
generic two-subordinate exact-three topology also ship. The matching
two-subordinate exact-three alias remains separate.

## Rollback

Remove the exact-three source/support/test/behavior/fact entries, restore the
normalizer to exact literal two, restore prior exact-one/two residue and
language text, restore 320/361/44 accounting, and rerun the complete
preservation boundary. The existing exact-one and exact-two lowerings remain
otherwise unchanged.
