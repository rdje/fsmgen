# IAL2 AHB Two-Subordinate Exact-Four Paired BUSY Composition Behavior

Task-tree owner:
`IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.3`

Date: 2026-07-30

## Shipped Outcome

FSMGEN now ships the generic two-subordinate exact-four paired AHB source:

```text
ppif/ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif
```

It composes the existing width-three exact-four requester, status and control
byte-lane/HBURST-SEQ/BUSY-parking subordinates, and two-window interconnect
through the existing generators. No parser, generator algorithm, report or
semantic/MCP API, simulator integration, backend, or existing source changed.

Public accounting is now 331 protocol fixtures, 372 supported-smoke fixtures,
372 strict-supported fixtures, and 55 AHB IAL2 paths split 28 generic `.ppif`
sources / 27 `.ahb` aliases.

Clean behavior commit `a62ddb705` activates no-behavior parent selector
`.827`. The selector, not this behavior record, owns the next exact roadmap
choice; the shipped 331/372/55 boundary remains unchanged during activation.

Completed selector `.827` now selects pending data-only alias implementation
`.828`. The future byte-identical `.ahb` path projects 332/373/56 split 28/28;
t1540 will own alias parity while t1539 remains the sole assertion-enabled
runtime. No alias ships in selection.

Clean selector commit `bc29c2e49` activates only `.828`; activation preserves
the shipped generic source and 331/372/55 boundary without adding the alias.

## Exact Source Delta

The 6,645-byte source is the frozen identity/requester/cardinality-only
transform of
`ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif`.
Exactly six fields change:

1. protocol-platform-intent identity changes exact-three to exact-four;
2. source-object identity changes exact-three to exact-four;
3. bounded anchor section changes exact-three to exact-four;
4. requester declaration selects `amba_requester_busy_insert_four`;
5. `(busy-beats 3)` becomes `(busy-beats 4)`; and
6. aggregate requester-child identity selects
   `amba_requester_busy_insert_four`.

Both subordinate clauses, ports, encodings, byte-lane storage semantics,
status/control wait controls, `[0,4)` and `[4,8)` windows, overlap rejection,
unmapped ERROR policy, and wiring remain byte-structurally identical.

## Generated Architecture

The current PPIF adapter plus `AhbRequester`, `AhbSubordinate`, and
`AhbInterconnect` generators emit exactly:

```text
IAL1:
  amba_requester_busy_insert_four.isf
  ahb_status_subordinate_byte_lane_hburst_seq.isf
  ahb_control_subordinate_byte_lane_hburst_seq.isf
  ahb_interconnect.isf

IAL0:
  amba_requester_busy_insert_four.fsm
  ahb_status_subordinate_byte_lane_hburst_seq.fsm
  ahb_control_subordinate_byte_lane_hburst_seq.fsm
  ahb_interconnect.fsm
  ahb_tb.fsm

HDL entry/module:
  ahb_tb.fsm / ahb_tb
```

Strict checking reports `ahb_tb`, root `top`, four children, 29 top-level
signals, zero top-local states, zero diagnostics, and the exact support entry.
The schedule keeps schema
`fsmgen.ial2.protocol_intent.ahb_interconnect.v1`, both decode windows,
one-hot accepted-subordinate data-phase ownership, requester
`before_beat=2`/`beats=4`, and both child/propagated `parks_on=[busy]` clauses.
There is no duplicate top-level `busy_flow` summary.

The requester retains width-three `ahb_busy_remaining_q`. Each command loads
four, retires qualified BUSY events through `4 -> 3 -> 2 -> 1 -> 0`, and
resumes its pending `SEQ` once. BUSY completes no data beat. The selected
subordinate retains its burst/phase/storage state, the unselected subordinate
does not change, and fabric data-phase ownership remains stable throughout the
BUSY episode.

## Semantic And MCP Surfaces

Normalized semantic JSON reports schema version 1, module `ahb_tb`, source
root `top`, four children, and support identity:

```text
intent.ppif_ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park
```

Real repo-relative `fsmgen_semantic_introspect` returns the same facts with:

```text
query_kind  = semantic
read_only   = true
shell_access = false
```

Public `--verify-hdl` passes. No feature-specific MCP method, mutation surface,
private raw dump, transport change, or shell-enabled adapter was added.

## Assertion-Enabled Runtime

Focused t1539 and its 14,900-byte repository-local testbench drive one
zero-wait byte `INCR4` write through each window. Verilator 5.046 compiles the
generated HDL with `--timing`, `-j 1`, and all generated selector assertions
enabled. Runtime passes:

```text
PASS commands=2 transfers=10 beats=8 busy=2 qualified_busy=8 resumed_seq=2 status=44332211 control=88776655
```

For each command, the observed transfer sequence is:

```text
NONSEQ(0) -> SEQ(1) -> BUSY(2 held for four qualified events)
          -> SEQ(2 resumed once) -> SEQ(3)
```

t1539 passes 4 top-level subtests in 718 seconds. Its source proof locks the six
approved deltas, exact report/artifact/semantic/MCP/verifier surfaces, and the
runtime above. Its disposable neighboring path also syntax-checks and lowers
successfully while remaining explicitly unmatched with zero false diagnostics.

## Support And Preservation

`FSM::Support::RegressionCorpus` now contains:

```text
id:
  intent.ppif_ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park
coverage:
  ial2_ppif_ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park_pipeline_cli
source kind / class / strict:
  ppif / supported_smoke / true
module / semantic root / children:
  ahb_tb / top / 4
```

t248+t297 pass 2 files / 7,019 tests at 331 protocol and 372 supported+strict
entries. The AHB inventory is 55 paths split 28 `.ppif` / 27 `.ahb`.

Adjacent preservation passes 4 files / 15 top-level tests in 2,113 seconds:

- t1533/t1534 preserve the two-window exact-three generic/profile pair and
  shared assertion-enabled 10/8/2/6/2 runtime; and
- t1537/t1538 preserve the one-window exact-four generic/profile pair and
  shared assertion-enabled 5/4/1/4/1/`44332211` runtime.

Existing source and alias bytes remain unchanged.

## Locality, Cleanup, And Resources

t1539 derives every temporary workspace from `.artifacts/tmp/tests`; the test
leaves that directory empty. All heavy validation uses the authorized
`--host-max-pct 100 --process-max-rss-mb 4096` profile. The only remaining
repository-local temporary file is the pre-existing 491-byte
`.artifacts/tmp/xcrun_db` tool cache.

Capacity uses the canonical Stats-compatible Mach-page formula
`active + inactive + speculative + wired + compressor-occupied - purgeable -
file-backed`. Kernel pressure is reported separately; guard occupancy and
inverted `memory_pressure -Q` free percentage are not capacity truth.

## Deferrals And Rollback

The matching `.ahb` alias, BUSY counts above four, broader insertion policy,
distinct bus-BUSY status, wider/indefinite bursts, optional signals, generic
priority, other protocols/backends, HIAL/VIAL, verification generation, VHDL,
portability, large-design scale implementation, and decision `0020` remain
separate task-tree-owned work.

Rollback removes exactly the new `.ppif` source, its RegressionCorpus entry,
t1539, its testbench, this record/fact, and synchronized public/accounting
updates. Accounting returns to 330/371/54 split 27 `.ppif`/27 `.ahb`.
Existing requester, subordinate, interconnect, paired, semantic/MCP, simulator,
backend, HIAL/VIAL, and VHDL behavior remains unchanged.
