# Direct VHDL Reduction-Expression Behavior

## Shipped Contract

`DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING.2` makes generated unary OR, AND,
and XOR reductions truthful in the direct VHDL backend without changing the
public `.fsm` expression grammar.

| Generated SystemVerilog operand | Direct VHDL lowering |
| --- | --- |
| declared scalar `(|S)`, `(&S)`, `(^S)` | scalar identity `(S)` |
| complemented scalar `(~|S)`, `(~&S)`, `(~^S)` | `(not S)` |
| in-range static vector bit select | scalar identity/complement over `V(N)` |
| declared vector | required backend-owned OR/AND/XOR fold helper |
| complemented declared vector | `not` of the helper's `std_logic` result |
| signed declared vector | fold helper over explicit `std_logic_vector(V)` cast |
| range, invalid select, unresolved, compound, malformed, residual | targeted pre-emission rejection |

The recognizer runs before generic binary and arithmetic rewrites. Declaration
context now reaches continuous assignments, comparisons, combinational and
sequential conditions, and reset conversion, so width handling cannot vary by
expression location.

## Vector Fold Helpers

Each module emits only the helpers required by its reduction operators. The
helpers fold an unconstrained `std_logic_vector` with ordinary `std_logic`
operators and the correct identity:

```vhdl
function fsmgen_direct_vhdl_reduce_or(value : std_logic_vector)
  return std_logic is
  variable result : std_logic := '0';
begin
  for index in value'range loop
    result := result or value(index);
  end loop;
  return result;
end function fsmgen_direct_vhdl_reduce_or;
```

AND begins at `'1'`; XOR begins at `'0'`. This explicit fold preserves
`std_logic` unknown-value behavior and avoids relying on unqualified native
VHDL vector-reduction syntax. A generated declaration that collides with a
required helper name fails closed instead of emitting an ambiguous design.

## Preservation Reconciliation

The audit initially selected blanket vector rejection because no `ghdl`,
`nvc`, or `vcom` executable is available. The first implementation
preservation run proved that approach would shrink shipped direct-VHDL scope:

- `fsm/amba_requester.fsm` uses complemented OR reduction of two-bit `HRESP`;
- generated APB completer VHDL uses complemented OR of `wait_ctr` and positive
  OR of `addr_q`; and
- t1420 and t386 require those direct and generated-child paths to keep
  producing VHDL.

Backend-owned folds resolve that conflict without adding a native-operator or
external-compiler claim. Range slices and unresolved/compound forms remain
fail-closed exactly because no equally bounded operand contract was selected.

## Public And Backend Boundaries

Explicit one-operand `(| X)`, `(& X)`, and `(^ X)` forms remain rejected by
the public parser's existing n-ary arity rule. This backend repair consumes
only generated SystemVerilog shapes. Binary/n-ary source operators, arithmetic,
concatenation, comparisons, literals, other HDL targets, named-drive priority,
reports, normalized semantic JSON, MCP, support accounting, AHB behavior,
HIAL/VIAL, scale, simulator profiles, and decision `0020` do not widen.

Decision `0023` still applies: textual generation and internal regression
prove the scoped lowering, but no executable VHDL analyzer/runtime
qualification is claimed until an authoritative compiler profile exists.

## Verification

- t1543 passes 6 top-level subtests/79 nested assertions covering scalar and
  complemented OR/AND/XOR, vector folds and helper bodies, signed-vector casts,
  static bit selects, range/invalid/unresolved/compound rejection, helper
  collisions, condition context, public pipeline truthiness, and unchanged
  public source arity.
- t1542 passes 7 top-level subtests/95 nested assertions and proves the real
  named-drive positive and complemented scalar shapes contain no reduction
  token while existing assertion-enabled SystemVerilog and native-Verilog
  priority behavior remains intact.
- The updated real t1420+t386 paths pass 2 files/160 top-level tests, locking
  the AMBA `HRESP` and APB `wait_ctr`/`addr_q` helper-backed outputs. The final
  t1542+t1543+t404 aggregate passes 3 files/17 top-level tests.
- Book/status/path truth gates pass 4 files/45 tests. Knowledge Map generation
  and checking passes at 1,059 facts/5,448 question keys; all six doctrine
  gates pass. The mdBook renders exactly 72 files/16,495,196 bytes before the
  exact repository-local output is removed. `.artifacts/tmp/tests` is empty,
  `MEMORY.md` is 50 lines, `README.md` is 2,343 lines, and diff hygiene passes.
- Final canonical Stats-compatible capacity is
  17,056,055,296/25,769,803,776 bytes = 15.885/24.000 GiB = 66.19%, with
  separate kernel pressure level 1 and `memory_pressure` 75% free. The RAM
  guard's occupancy is excluded from capacity truth. No background job remains.

## Rollback

Rollback restores clean activation commit `2da0d42c0` and the historical token
leak. It must retain the audit and preservation-reconciliation evidence; it
must not misclassify pre-repair generation success as valid VHDL. A partial
rollback may not keep helper calls without declarations or restore blanket
vector rejection while claiming the prior AMBA/APB scope.
