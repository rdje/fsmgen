# Direct VHDL Reduction-Expression Readiness Audit

## Outcome

`DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING.1` selects proposed implementation
`.2` with a deliberately compiler-independent boundary:

- a parenthesized generated-SystemVerilog unary OR, AND, or XOR reduction over
  a declaration-proven scalar identifier or a static bit select lowers to the
  scalar operand itself;
- the complemented forms `~|`, `~&`, and `~^` over those same scalar shapes
  lower to VHDL `not` of the scalar operand; and
- every vector, range-slice, unresolved, compound, or malformed unary-reduction
  operand fails closed before VHDL emission with a targeted direct-scaffold
  diagnostic.

The public `.fsm` expression grammar does not widen. Vector reductions remain
unsupported until an authoritative VHDL analyzer/simulator can qualify a
separate vector contract. This audit changes no parser, backend, generated
output, diagnostic, or runtime behavior.

## Reproduced Public Pipeline Boundary

A repository-local direct-root fixture exercised positive and zero truthiness
for a one-bit `SCALAR` and four-bit `VECTOR` through both generated HDL paths.

| Source truthiness | Generated SystemVerilog | Current direct VHDL | Finding |
| --- | --- | --- | --- |
| scalar nonzero | `idle_en & SCALAR` | `idle_en and SCALAR` | already correct scalar identity |
| scalar zero | `idle_en & !SCALAR` | `idle_en and not SCALAR` | already correct scalar complement |
| vector nonzero | `idle_en & (|VECTOR)` | `idle_en and (|VECTOR)` | foreign unary-OR token leaks |
| vector zero | `idle_en & (~|VECTOR)` | `idle_en and (~|VECTOR)` | foreign complemented unary-OR tokens leak |

The tracked named-drive source confirms the original case is scalar. Generated
SystemVerilog declares `reg drive_zero_start;`, and current direct VHDL declares
`signal drive_zero_start : std_logic;` before emitting the unnecessary
`drive_zero_en and (|drive_zero_start)`. Reduction of one bit by OR, AND, or
XOR is the identity; complement of any of those one-bit reductions is ordinary
scalar complement. No vector-reduction language feature is needed to repair
that exact case.

## OR, AND, And XOR Converter Matrix

An in-memory probe called the direct backend's public
`convert_systemverilog_to_vhdl` boundary with generated-shaped scalar and
four-bit vector declarations. Current results are width-insensitive because
the general expression rewrites do not recognize unary reductions first:

| Operand | SystemVerilog expression | Current result |
| --- | --- | --- |
| scalar | `(|X)` | returns invalid VHDL `(|X)` |
| scalar | `(&X)` | returns invalid VHDL `( and X)` |
| scalar | `(^X)` | fails through the unrelated arithmetic-expression boundary |
| vector | `(|X)` | returns invalid VHDL `(|X)` |
| vector | `(&X)` | returns invalid VHDL `( and X)` |
| vector | `(^X)` | fails through the unrelated arithmetic-expression boundary |

The behavior is now durably characterized by
`t/1543-direct-vhdl-reduction-expression-readiness.t`. That test also proves
that explicit one-operand `(| X)`, `(& X)`, and `(^ X)` source forms already
fail at the public expression parser with “requires at least 2 operands.” The
active public operators `|`, `&`, and `^` remain n-ary binary-tree operators;
this backend task does not turn them into source-level reduction operators.

## Width And Context Trace

The defect is isolated to the direct SystemVerilog-to-VHDL adapter:

1. `FSM::Synthesis::EnableGraph::ASTSupport` emits `(|operand)` for a
   multi-bit or conservatively unknown-width nonzero truthiness comparison and
   `(~|operand)` for its zero form. Known one-bit truthiness emits the operand
   or `!operand` directly.
2. `FSM::HDL::FlattenedDT::Backend::VHDL::convert_systemverilog_to_vhdl`
   parses generated ports and signals into `%decls_by_name`, preserving the
   decisive scalar/vector declaration shape.
3. Continuous assignments already call `_sv_expr_to_vhdl` with that
   declaration map. The helper currently performs binary `|`/`&` string
   rewrites without first recognizing unary tokens; `^` is routed as
   arithmetic. This produces the matrix above.
4. `_sv_condition_to_vhdl` currently calls `_sv_expr_to_vhdl` without a
   declaration context. Implementation `.2` must thread the existing map into
   condition conversion as well, so an unsupported reduction cannot escape
   merely by occurring in a generated `if` condition.

A plain declared scalar identifier and a static bit select lower to VHDL
`std_logic`, so identity/complement is type-correct. A SystemVerilog range
select, including a one-bit `[N:N]` range, lowers as a VHDL vector slice rather
than `std_logic`; it therefore remains in the fail-closed vector class. Target
LHS width is not evidence for the reduction operand's type.

## Selected `.2` Contract

Implementation `.2` is limited to the generated expression adapter and its
focused tests.

### Accepted generated shapes

Recognize parenthesized generated-SystemVerilog forms with optional internal
whitespace:

```text
( | SCALAR )   ( & SCALAR )   ( ^ SCALAR )
( ~| SCALAR )  ( ~& SCALAR )  ( ~^ SCALAR )
```

The operand must resolve through `%decls_by_name` as a scalar identifier or be
a static bit select of a declared signal. Convert bit-select brackets through
the existing lvalue syntax helper. Positive reductions become a parenthesized
operand; complemented reductions become parenthesized `not operand`.

### Fail-closed shapes

Before the general binary/arithmetic rewrites, reject:

- any reduction over a declared vector or any range slice;
- any reduction whose base declaration or width cannot be resolved;
- compound, concatenated, indexed-by-expression, or otherwise unselected
  operands; and
- any remaining parenthesized unary `|`, `&`, or `^` token that the bounded
  recognizer did not consume.

The diagnostic family remains the existing direct-scaffold exception prefix.
The selected detail must name the full authored generated expression, operand,
resolved shape when known, and the width-one-only boundary, for example:

```text
unary reduction expression '(|VECTOR)' is outside the direct VHDL scaffold:
operand 'VECTOR' is a 4-bit vector; only scalar identifiers and static bit
selects are supported
```

No stable public diagnostic code or report/semantic schema is added.

## Why Vector Translation Is Not Selected

`ghdl`, `nvc`, and `vcom` are all unavailable in the current environment. The
direct scaffold already uses some VHDL-2008-shaped constructs such as
`process(all)`, but that is not evidence that a newly emitted unary vector
operator is accepted with the intended `std_logic_vector`/`signed` overloads
by an authoritative configured toolchain. Decision `0023` specifically forbids
using generation success as qualification.

Failing vector reductions before emission is therefore the smallest truthful
repair. A future exact owner may select native VHDL vector-reduction syntax or
a backend-owned helper after analyzer/runtime evidence exists. `.2` must not
emit unqualified `or VECTOR`, `and VECTOR`, or `xor VECTOR` syntax.

## Preservation And Validation Contract

Implementation `.2` must preserve:

- public source arity rejection for one-operand `|`, `&`, and `^`;
- binary/n-ary OR, AND, and XOR lowering, including existing XOR-chain tests;
- ordinary scalar `!`, binary comparisons, concat, arithmetic, literals,
  bit/slice spelling, sequential/combinational process conversion, and every
  non-VHDL backend;
- named-drive priority semantics and public report/semantic/MCP schemas;
- AHB requester `2..16` behavior and 332/373/56 split 28/28 accounting; and
- HIAL/VIAL, scale, simulator-profile, composition/package/aggregate,
  verification-output, mixed-language, other-protocol/backend, and decision
  `0020` boundaries.

Focused implementation proof must update t1543 from defect characterization to
the selected scalar-identity/vector-fail-closed contract, update t1542 so the
tracked named-drive VHDL contains no reduction token, and run t1420 plus the
t386/t404 facade boundaries. External VHDL compile/runtime evidence is added
only if an authoritative compiler becomes available; otherwise the limitation
stays explicit. All workspaces and temporary output remain repository-local,
use the authorized host100/process4096 profile, receive exact census/cleanup,
and close through mdBook, Knowledge Map, doctrine, and COMMIT.md gates.

## Closeout Evidence

- t1543 passes 3 top-level subtests/38 nested assertions. It freezes the public
  scalar/vector truthiness seam, all six scalar/vector OR/AND/XOR converter
  results, and unchanged public one-operand source rejection.
- Direct-backend t1420 passes 64 subtests. The exact tracked t386/t404 facade
  files pass 2 files/100 tests. The first aggregate invocation used obsolete
  short facade filenames after t1543 and t1420 passed; rerunning the correct
  paths passed, with no product failure.
- Book/status/path truth gates pass 4 files/45 tests. Knowledge Map generation
  and checking passes at 1,058 facts/5,440 question keys.
- The mdBook renders exactly 72 files/16,485,893 bytes; its exact
  repository-local output is deleted with zero residue.
- Eight exact disposable audit files totaling 18,546 bytes are deleted after
  census. `.artifacts/tmp/tests` is empty. `MEMORY.md` is 50 lines,
  `README.md` is 2,342 lines, diff hygiene passes, and all six doctrine gates
  pass, including project-data locality.
- Final canonical Stats-compatible capacity is
  15,967,453,184/25,769,803,776 bytes = 14.871/24.000 GiB = 61.96%, with
  separate macOS kernel pressure level 1 and `memory_pressure` 73% free. Guard
  occupancy is excluded from capacity truth.

This audit changes no parser, backend, generated output, diagnostic, runtime,
public API, support accounting, HIAL/VIAL, scale, or decision-0020 behavior.
No background job remains.

## Rollback

Audit rollback removes this record/fact/t1543 characterization, restores `.1`
to active, and leaves the current leak unchanged. After `.2` activation,
rollback follows the selected scalar-identity/vector-rejection boundary and
must never restore silent foreign-token emission.
