# ISF Nested-Bitwise Assertion Precedence Behavior

## Outcome

`ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.2` now preserves the exact CoreAST
subexpression boundary whenever concurrent-check rendering substitutes a
compiler-generated intermediate signal. Nested mixed-precedence boolean and
bitwise expressions therefore retain their authored meaning in generated
SystemVerilog assert, assume, and cover properties.

The shipped AXI fixed-four read behavioral admission set is unchanged. Legal
address `0x00000004` is still admitted, and its generated boundary assertion
now agrees instead of falsely failing.

## Source And Generated Meaning

An ISF check may use ordinary nested expressions directly or as temporal-
property leaves:

```lisp
(assert (& high (| bit3 bit2)) "nested bitwise semantics")
(assert (=> enable (& high (| bit3 bit2))) "same-cycle obligation")
(assert (=> enable (next (& high (| bit3 bit2)))) "next-cycle obligation")
```

FSMGEN may factor the nested OR into an internal signal during parsing and
lowering. Concurrent-check output still reconstructs the authored expression
with the OR grouped as one AND operand:

```systemverilog
assert property (@(posedge clk) disable iff (!rst_n)
  (((high & (bit3 | bit2)))))
  else $error("nested bitwise semantics");
```

Redundant outer parentheses record factored expression boundaries; the
decisive semantic guarantee is that the inner `bit3 | bit2` remains one child
of `high & ...`. The malformed `high & bit3 | bit2` form is no longer emitted
for this AST.

The same grouping survives overlapping implication and formal-only delayed
wrappers. Property operators and formal-only classification do not change:

```systemverilog
(enable) |-> (((high & (bit3 | bit2))))
(enable) |-> (##1 (((high & (bit3 | bit2)))))
```

## Implementation Boundary

`GeneratedModuleInfoBuilder::_render_check_condition_sv` already follows an
inlineable `FSM::CoreAST::SignalRef` to the signal's driving AST. The repair
keeps the recursively rendered replacement inside one pair of parentheses
before returning it to the parent renderer. This is the textual equivalent of
substituting one AST node at the original signal-reference position.

The change is deliberately independent of operator pairs. It protects nested
AND/OR/XOR, arithmetic, comparison, shift, unary, concatenation, conditional,
and property-leaf contexts without duplicating the CoreAST precedence table.
Direct `FSM::CoreAST::BinaryOp` rendering was already correct and is unchanged.
Cycle fallback and unrenderable-condition handling are also unchanged.

## AXI Fixed-Four Read Proof

The public fixed-four read coordinator still factors its behavioral guard:

```systemverilog
assign intermediate_complex_expr_10 =
    cmd_read_addr[3] | cmd_read_addr[2];
assign intermediate_and_intermediate_complex_expr_10_11 =
    cmd_read_addr[11] & cmd_read_addr[10] & cmd_read_addr[9]
    & cmd_read_addr[8] & cmd_read_addr[7] & cmd_read_addr[6]
    & cmd_read_addr[5] & cmd_read_addr[4]
    & intermediate_complex_expr_10;
```

Its concurrent boundary assertion now contains the equivalent grouped child:

```systemverilog
cmd_read_addr[11] & cmd_read_addr[10] & cmd_read_addr[9]
& cmd_read_addr[8] & cmd_read_addr[7] & cmd_read_addr[6]
& cmd_read_addr[5] & cmd_read_addr[4]
& (cmd_read_addr[3] | cmd_read_addr[2])
```

Address `0x00000004` has bit 2 high but no high 4-KiB-boundary bits. The
behavioral guard admits it, the corrected assertion accepts it, AR carries
address `0x00000004` with fixed `LEN=3`, `SIZE=2`, and `INCR`, and four clean R
beats retire exactly one transaction.

## Why The Runtime Proof Uses Two Harnesses

The existing t1507 behavioral harness intentionally sends a misaligned command
and a 4-KiB-crossing command to prove that rule admission rejects both. The
generated boundary assertion intentionally treats those commands as contract
violations. Running that negative harness with assertions enabled would
therefore fail by design, independent of the precedence repair.

t1507 now keeps the combined negative/positive behavioral harness under
`--no-assert` and adds legal `0x00000004` to it, reaching exact
`5/17/5/17/4` AR/R/request/beat/transaction counts while retaining two illegal
rejections, busy-command, non-OKAY, error-drain, and reset-abort coverage. A
separate tracked all-assertion harness sends only the legal bit-2-high command
and proves exact `1/4/1/4/1` completion with correct RID/RLAST status. This
keeps illegal behavioral coverage and assertion correctness independently
executable without weakening either contract.

## Validation

- t1410 freezes the authored carrier plus factored all-CoreAST AND/OR shape.
- t1411 proves grouped inline substitution and emitted concurrent assertion.
- t1412 proves overlapping and delayed property wrappers retain grouping and
  unchanged formal-only classification.
- t1544 proves direct rendering, corrected AXI `condition_sv`, correct
  behavioral factoring, and corrected final property text.
- t1507 proves unchanged public/report/schedule/semantic/verifier surfaces,
  the expanded negative/positive `5/17/5/17/4` behavior matrix, and separate
  assertion-enabled legal-`0x00000004` `1/4/1/4/1` runtime.
- t1413, t1416-t1418, and t404 preserve trigger anchors, sampled values,
  property windows, and HDL-facade behavior.

Production/test syntax passes for the builder plus t1410-t1412/t1507/t1544.
The final focused aggregate passes 5 files/27 top-level tests. Trigger,
sampled-value, property-window, and facade preservation passes 5 files/34
tests. Book matrix/status/path truth passes 5 files/329 tests. Knowledge Map
generation/check passes at 1,061 facts/5,461 question keys. The mdBook renders
exactly 72 files/16,519,726 bytes and its repository-local output is removed.
`.artifacts/tmp/tests` is empty; `MEMORY.md` is 49 lines; `README.md` is 2,347
lines; diff hygiene and all six doctrine gates pass.

Final canonical Stats-compatible capacity is
18,161,516,544/25,769,803,776 bytes = 16.914/24.000 GiB = 70.48%, with separate
macOS kernel pressure level 1 and `memory_pressure` 75% free. The RAM guard's
occupancy estimate is not used as capacity truth. No background job remains.

## Preserved Boundaries

This repair does not change public source syntax, property combinators,
assert/assume/cover kinds, messages, reset/clock sampling, formal-only delayed
properties, behavioral HDL expression rendering, AXI admission, ports,
topology, support accounting, report/semantic/MCP schemas, Verilog behavior,
VHDL support, HIAL/VIAL architecture, simulator qualification, scale claims,
or decision `0020`.

The assertion-enabled proof qualifies this supported generated subset through
event-capable compiled Verilator. It does not claim full-SystemVerilog-LRM or
UVM support.

## Rollback

Rollback removes the substitution-boundary grouping and the new focused/
assertion-enabled expectations together, restoring the historical malformed
property. It must not keep the legal assertion claim while restoring
`high & bit3 | bit2`, remove the illegal-command behavior coverage, or rewrite
the AXI source to hide the general compiler defect.
