# IAL2 AHB Requester Exact-Four BUSY Event Behavior

Task-tree owner:
`IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT.3`

Date: 2026-07-29

## Outcome

FSMGen ships the additive generic requester source:

```text
ppif/ahb_requester_busy_insert_four.ppif
```

It inserts exactly four grant-and-ready-qualified `HTRANS=BUSY` events before
the selected pending `SEQ` transfer. It reuses the existing `AhbRequester`
generator and the mandatory IAL2 -> IAL1 -> IAL0 -> HDL route.

Its public identity is:

```text
intent:          ahb_requester_busy_insert_four
source object:   fsmgen-ahb-requester-busy-insert-four
anchor section:  bounded-requester-four-busy-insertion
actor/module:    amba_requester_busy_insert_four
IAL1:            amba_requester_busy_insert_four.isf
IAL0:            amba_requester_busy_insert_four.fsm
support id:      intent.ppif_ahb_requester_busy_insert_four
coverage:        ial2_ppif_ahb_requester_busy_insert_four_pipeline_cli
source kind:     ppif
semantic root:   fsm
```

## Public Count Boundary

The optional transfer count accepts literal integers `2..4`; absence remains
canonical exact-one. Zero, one, values above four, symbolic/non-literal forms,
missing prerequisites, and duplicates fail closed. The range diagnostic is:

```text
AHB requester transfer.busy_beats must be a literal integer in 2..4 in this slice
```

`busy-beats 4` means exactly four rising events satisfying:

```text
HGRANT && HREADY && HTRANS == 2'b01
```

Ready-low and grant-low clocks consume no count. BUSY completes no data beat
or response, and pending transfer state stays stable until the same transfer
resumes as `SEQ`.

## Preserving Minimum-Width Lowering

Multiple-BUSY storage uses the minimum unsigned width equivalent to:

```text
ceil(log2(busy_beats + 1))
```

The implementation uses an integer loop, not floating-point arithmetic:

| Count | Counter width |
| ---: | ---: |
| 2 | 2 |
| 3 | 2 |
| 4 | 3 |

Exact-two and exact-three therefore retain byte-stable width-two generated
storage. Exact-four uses width three and generates:

```text
(var ahb_busy_remaining_q (width 3) (reset 0))
```

The insertion transaction initializes the counter to four. Existing qualified
rules retire `4 -> 3 -> 2 -> 1 -> 0`: the `> 1` rule decrements, and the
`== 1` rule clears the counter, sets the existing address-pending state, and
hands the unchanged transfer to `SEQ`. Priorities, owners, continuation rules,
and the IAL1 language are unchanged.

## Reports, Residue, And Support

The source reports numeric `transfer.busy_beats=4` and
`busy_insertion.beats=4`, with `before_beat=2`, generated behavior enabled, and
BUSY encoding `2'b01`. Exact-one residue names exact-two, exact-three, and
exact-four support; exact-two names exact-three and exact-four; exact-three
names exact-four; exact-four says four events ship. Counts above four and
generalized runtime/policy/random or multiple-point insertion remain deferred.

The generic source established 327 protocol fixtures, 368 supported-smoke plus
strict fixtures, and 51 AHB IAL2 paths split 26 generic `.ppif` sources and 25
`.ahb` aliases. The matching exact-four `.ahb` alias ships through
`docs/IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_PROFILE_ALIAS_BEHAVIOR.md` and
established 328/369/52. The later one-window exact-four paired generic/profile
pair established the 330/371/54 checkpoint split 27 `.ppif` / 27 `.ahb`;
the still-later two-window generic/profile pair moves the current boundary to
332/373/56 split 28 `.ppif` / 28 `.ahb`.

## Verification

Assertion-enabled `t/1535-ial2-ahb-requester-four-busy-insert.t` covers exact
source identities, diagnostics, strict/check/schedule, review artifacts,
repository-local output, public HDL verification, normalized semantic JSON,
and real read-only shell-disabled MCP introspection. One Verilator 5.046
`--timing` binary, without `--no-assert`, passes continuously qualified,
32-clock ready-low, and 32-clock grant-low scenarios. Each run observes one
BUSY episode, four qualified events, exact `4 -> 3 -> 2 -> 1 -> 0` retirement,
stable pending ownership during stalls, one resumed `SEQ`, four byte `INCR4`
data beats, and zero final counter.

The test also proves exact-three and exact-two remain width two, exact-one
remains counter-free, the base requester remains BUSY-insertion-free, and the
existing public source bytes remain unchanged.

## Use It

```bash
scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- ./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester_busy_insert_four.ppif
scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester_busy_insert_four.ppif
scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester_busy_insert_four.ppif
scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- ./bin/fsmgen --quiet --strict --verify-hdl ppif/ahb_requester_busy_insert_four.ppif
```

Generated outputs must use a repository-derived same-volume path.

## Explicit Deferrals And Rollback

Parent selector `.823` selected the one-window exact-four paired readiness
audit. That audit and contract now culminate in the shipped generic/profile
pair with shared assertion-enabled 5/4/1/4/1/`44332211` runtime. Two-window
exact-four, counts above four, arbitrary/runtime/policy/random counts,
multiple insertion points, local
bus-BUSY status, new burst/signal/topology behavior, HIAL/VIAL activation,
VHDL, verification generation, and decision 0020 remain separate.

Rollback removes the exact-four generic and alias source/support/test/behavior/fact entries,
restores literal `2..3` normalization and diagnostics, removes the width
helper, restores the former residue text and 326/367/50 accounting, then reruns
the requester preservation boundary. Exact-one/two/three generated behavior
otherwise remains unchanged.

Parent selector `.829` now selects proposed generalized literal requester
BUSY-count readiness `.1`. The selected audit must choose and prove one finite
range above four rather than add an exact-five-only fixture. Until a separate
contract and implementation ship, the public `2..4` boundary and all behavior
in this record remain unchanged.
