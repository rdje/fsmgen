# IAL2 AHB Requester Exact-Three BUSY-Insertion Readiness Audit

Task-tree owner:
`IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.1`

Date: 2026-07-29

## Outcome

The smallest additional literal `(busy-beats 3)` is runtime-ready on the
shipped exact-two requester substrate. No IAL1, IAL0, SystemVerilog, semantic,
MCP, or other lower-layer repair is required before public contract selection.

The audit selects proposed
`IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.2`, a separate
no-behavior public-contract leaf. It does not select direct implementation or
ship any public exact-three source.

## Disposable Candidate

All candidate material lived beneath repository-local ignored
`.artifacts/workspaces/` directories. The primary candidate copied the shipped
requester generator and changed only:

- normalization from exact literal two to the bounded candidate set `{2,3}`;
- candidate-only static-rule/residue wording;
- source/intent/actor identity from exact two to exact three; and
- `(busy-beats 2)` to `(busy-beats 3)`.

The generator's counter declaration, insertion transaction, BUSY hold,
non-final/final rules, priorities, address/data/response ownership, and
generated IAL1-to-IAL0 path were unchanged. The candidate produced:

```text
amba_requester_busy_insert_three.isf
amba_requester_busy_insert_three.fsm
module amba_requester_busy_insert_three
busy_insertion.before_beat = 2
busy_insertion.beats = 3
ahb_busy_remaining_q width = 2
```

Strict check, schedule JSON, normalized semantic JSON, generated review
artifacts, and HDL generation all succeeded. The unmatched candidate support
result remained truthful because the disposable source was not added to the
public support catalog.

## Exact Runtime Result

One assertion-enabled Verilator binary ran three scenarios:

| Scenario | Qualified BUSY events | Stalled BUSY clocks | Transfer presentations | Data beats | Final BUSY counter |
| --- | ---: | ---: | ---: | ---: | ---: |
| continuously qualified | 3 | 0 | 5 | 4 | 0 |
| ready low for 32 clocks | 3 | 32 | 5 | 4 | 0 |
| grant low for 32 clocks | 3 | 32 | 5 | 4 | 0 |

Each scenario proved one BUSY transition episode and the internal remaining
counter sequence `3 -> 2 -> 1 -> 0`. A qualified BUSY event observed exactly
the expected pre-retirement value; ready-low and grant-low clocks held the
internal counter at three and consumed nothing.

Across all scenarios:

- the pending address, write control, size, burst, protection, write data,
  beat index, and burst-beats-remaining values stayed stable throughout BUSY;
- BUSY completed no data beat or response;
- the same pending transfer resumed exactly once as `SEQ`;
- the requester presented `NONSEQ`, `SEQ`, one held BUSY episode, resumed
  `SEQ`, and final `SEQ`;
- exactly four byte `INCR4` data beats completed; and
- both public burst remaining and internal `ahb_busy_remaining_q` were zero at
  completion.

The first guarded run passed four top-level subtests with 59 nested assertions
in 33 seconds, covering lowering/report, strict/schedule/semantic/MCP,
generated runtime, malformed values, and exact-one/exact-two/base preservation.
Review found that its final-zero check named only the public burst counter, so
a strengthened second guarded run directly observed
`dut.ahb_busy_remaining_q`, proved `3 -> 2 -> 1 -> 0` plus stall stability,
and passed 8/8 tests in 10 seconds. The stronger result is authoritative.

## Semantic And MCP Boundary

Normalized semantic JSON succeeded with module
`amba_requester_busy_insert_three` and generated FSM source root. A real call
through the existing `fsmgen_semantic_introspect` adapter returned the same
bounded semantic model and module while preserving:

```text
read_only = true
shell_access = false
source_id = ppif/ahb_requester_busy_insert_three.ppif
```

No raw private lowering payload or feature-specific MCP method is necessary.
Numeric BUSY cardinality remains schedule/report data; the normalized semantic
model continues to expose the common generated module contract.

## Preservation And Required Public Work

The candidate overlay still parsed literal two as numeric two and initialized
the same width-two counter to two. Exact-one retained report token `single` and
no counter/continue rule. The base requester retained no BUSY machinery.
Candidate values `0`, `1`, `4`, and a symbolic count failed closed.

The runtime result removes a substrate prerequisite, but public exact-three
behavior still requires a contract. Leaf `.2` must freeze:

- whether public normalization accepts exactly `{2,3}` and its diagnostic;
- additive generic source/intent/object/actor/support/coverage identities;
- numeric report wording and truthful residue for exact-one, exact-two, and
  exact-three sources;
- width-two initialization/retirement and all preservation invariants;
- a focused assertion-enabled runtime test, strict/schedule/semantic/MCP/
  artifact/verifier gates, and support-accounting checkpoint;
- generic-first then matching `.ahb` alias sequencing; and
- rollback before any parser, generator, source, support, test, or runtime
  behavior change.

## Non-Selections

The audit does not select counts above three, a wider/general counter,
runtime/policy/random throttling, multiple insertion points, a distinct local
bus-BUSY status, exact-three paired compositions, broader bursts/signals/
managers/fabrics, interconnect correctness repairs, AXI/APB/VHDL behavior, or
decision 0020.

## Resource And Cleanup Evidence

The initial guard attempt stopped before work at 99.5% by its unchanged macOS
metric while an unrelated `pgen` Rust compiler held about 10 GiB RSS. That
process exited without intervention. The complete primary run then started at
61.6%, and the strengthened internal-counter run started at 64.0%; neither
crossed the 4-GiB descendant-RSS limit.

The primary disposable workspace contained 5 files / 136,849 bytes. The
strengthened workspace contained 5 files / 128,911 bytes. Runtime tempdirs
cleaned themselves, both exact workspaces were deleted, and a residue check
found neither path. No tracked source, generator, support, test, artifact, or
runtime behavior changed.

## Rollback

Remove this audit record/fact and proposed `.2`, restore `.1` to active audit,
and revert roadmap/mdBook/task/Memory/Knowledge Map pointers. There is no
shipped behavior to revert.
