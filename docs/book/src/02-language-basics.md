# Language Basics

This chapter covers the core authoring surface you use before composition.

## Mental Model

FSMGen sources are Lisp-like trees.

You are usually writing:

- declarations such as `+system`, `+size`, `+constants`, `+enums`, `+types`
- states or decision-tree blocks
- assignments
- guards and tests

## Core Terms

- `?fsm:name`: state-machine root
- `?dt:name`: standalone decision-tree root
- `+system`: clock/reset declaration section
- `+size`: width/type declaration section
- `+constants`, `+enums`, `+types`: symbol and type sections
- `:=`: init/reset directive
- `<...`: guard suffix

## Widths

Use `+size` to declare the intended packed width or named type of signals:

```lisp
(+size
  (valid 1)
  (data 8)
  (frame frame_t)
)
```

The width slot is a constant-expression slot. It can use integer literals,
constants, enum members, params/generics, aggregate scalar leaves, and bounded
Lisp-ish arithmetic/bitwise expressions:

```lisp
(+constants
  (BYTE_W 8)
  (LANES (4 8))
)
(+enums
  (mode_w
    (NARROW 4)
    (WIDE 8)
  )
)
(+params
  (EXTRA_W 1)
)
(+size
  (data (+ BYTE_W EXTRA_W))
  (mode mode_w.WIDE)
  (lane LANES[1])
  (mask (and 7 3))
)
```

The expression must resolve to one positive integer before generation. Unknown
or aggregate-valued leaves are rejected instead of becoming accidental signals.

`.fsm` integer literals are intentionally a little friendlier than target HDL.
Alongside SystemVerilog-style forms such as `8'hA5`, you can write
intent-level sized values as `<width>'<integer-value>`: `5'23`, `8'-10`,
`8'-0xA`, `8'-0b1010`, or `20'x1`. Those are normalized before HDL emission,
so generated SV sees legal literals such as `5'd23`, `8'd246`, `8'hF6`,
`8'b11110110`, and `20'h1` instead of raw `.fsm` shorthand.

Value lanes are stricter than width lanes. In direct RHS expressions,
`+constants`, `+params`, and `.rtlif` parameter/generic scalar defaults,
FSMGen now rejects obviously bitstring-like bare `0/1` tokens such as
`00001110` or `10000000` instead of guessing whether they were meant as
decimal or binary. Write `0b00001110` for intrinsic-width binary,
`8'b00001110` for exact-width binary, or `0d1110` if decimal was intended.
Positive-width slots keep the existing decimal compatibility, so
`(+size (DATA 10))` still means decimal ten.

## Init/Reset Defaults

Use canonical `:=` pairs for explicit reset/default metadata:

```lisp
(:= (valid 0))
(:= (mode_reset (+ RESET_BASE mode.IDLE)))
(:=
  (ready 1)
  (data_reset 8'h00)
)
```

The value slot is also an expression slot. It may be a literal, a named
constant/enum/param, an aggregate scalar leaf, or a nested Lisp-ish expression.
The older compact form `(:= signal=value)` remains default-mode compatibility
residue; strict mode points users to the pair form.

## Assignment Operators

Current quick reference:

- `A = expr`: combinational assignment
- `A <- expr`: synchronous/flopped assignment where `A` names the flop output/Q value
- `A <= expr`: synchronous/flopped variant where `A` names the D-input/next-value side
- `A <-= expr`: synchronous with auxiliary `next_*` surface
- `A <=+ expr`: synchronous with auxiliary `*_r` surface
- `A <N 0` or `A <N 1`: delayed pulse form

The LHS may also use a bounded deconstruct target when one packed RHS should
feed several static lvalues:

```lisp
((concat HIGH LOW) = DATA)
((cat REG_HI REG_LO) <- NEXT_DATA)
```

The split is intentional source syntax, not emitted HDL pasted into the
renderer. `HIGH` receives the high RHS slice, `LOW` receives the low slice, and
the same high-to-low rule applies to later operands.

### Canonical Pair Form

FSMGen also supports the regular Lisp-ish assignment spelling. This is the
preferred authoring form for new `.fsm` files because the operator is the form
head and the payload is one explicit `(lhs rhs)` pair.

The shape is:

```lisp
(assign-op (lhs rhs))
(assign-op (lhs rhs) <cond)
```

where `assign-op` is one of the same assignment families:

```lisp
(=   (OUT VALUE))
(<-  (Q D))
(<=  (D_IN NEXT_VALUE))
(<-= (Q D))
(<=+ (D_IN NEXT_VALUE))
(<1  (PULSE 1))
```

The optional third form is assignment-level condition metadata:

```lisp
(=  (OUT VALUE) <valid)
(<- (Q D) <enable)
(=  (OUT (+ A B)) <(& valid ready))
```

That condition is not part of the RHS expression. It means “perform this
assignment when the guard is true,” exactly like today’s assignment suffix
guards.

The distinction between `<-` and `<=` matters. Use `<-` when the signal name is
the registered Q/output value, which is the common style for names such as
`addr_q` or `count_q`. Use `<=` only when the authored LHS is intentionally the
D-input/next-value carrier. Because of that D-input binding, `A <= (+ A 1)` is
not a safe counter spelling: it reads the same D-input carrier it is building
and FSMGen rejects it before HDL generation. Write `A <- (+ A 1)` for normal
registered feedback. If you really need same-cycle D visibility and a separate
registered Q mirror, use `<=+` and read the generated `A_r` mirror.

The same pair form covers the active LHS/RHS surface, including nested
expressions, RHS concat, aggregate leaves, explicit output exposure, and LHS
deconstruct:

```lisp
(=  (OUT (concat HI LO)))
(<= (output_data> 8'1))
(=  ((concat HI LO) DATA))
(<- ((cat REG_HI REG_LO) NEXT_DATA) <load)
(=  (FRAME.payload TAIL))
```

The `>` marker is part of the authored LHS. It means "expose this driven target
as an output port" for direct roots and generated composition children. For
example, `(<= (output_data> 8'1))` is the canonical pair-form equivalent of the
default-mode compatibility spelling `(output_data> <= 8'1)`. It is not the same
as `(<= (output_data 8'1))`, which drives the internal D-input-named target
without requesting public output exposure.

Existing infix forms such as `(OUT = VALUE)` and `(Q <- D)` remain compatibility
spellings. Both surfaces normalize into the same assignment AST/IR before HDL
generation, so backends see normalized assignment intent rather than
renderer-specific syntax. Strict mode accepts the canonical pair form and
rejects the infix compatibility spelling so sources can opt into the cleaner
forward contract.

## Combinational Safety Rule

Combinational `=` is not allowed to create direct or indirect RHS feedback to
the same LHS.

If you want retained state, use one of the sequential families instead.

There is a second, related sequential safety rule: D-input-named `<=` and
`<=+` assignments must not read the same LHS name from the RHS or assignment
guard. That form creates combinational feedback in the generated next-value
logic. Q/output-named `<-` feedback remains valid and is the preferred spelling
for ordinary registers.

## Expressions

The current live expression surface includes:

- literals
- signal references
- indexed and sliced references
- unary `!`
- negated n-ary bitwise/logical-style forms `!&`, `!|`, and `!^`
- comparison operators such as `==`, `!=`, `<`, `<=`, `>`, `>=`
- arithmetic and bitwise operators such as `+`, `-`, `*`, `/`, `%`, `&`, `|`, `^`
- word aliases such as `not`, `eq`, `ne`, `lt`, `le`, `gt`, `ge`, `add`,
  `sub`, `mul`, `div`, `mod`, `and`, `nand`, `or`, `nor`, `xor`, and `xnor`
- RHS pack expressions with `(concat ...)` or the shorter `(cat ...)` alias

The arithmetic/bitwise expression families are n-ary. Operators such as `+`,
`*`, `&`, `|`, and `^` combine all operands; `-`, `/`, and `%` are
left-associative, so `(/ a b c)` means `((a / b) / c)` and `(% a b c)` means
`((a % b) % c)`.

The negated n-ary forms lower as ordinary AST composition, not as a special
late renderer trick. `(!& A B C)` becomes `!(A & B & C)`, `(!| A B)` becomes
`!(A | B)`, and `(xnor A B C)` is the word alias for `(!^ A B C)`.

Constant-expression slots such as `+size`, `+params`, init/default metadata,
and parameter/generic overrides fold before HDL generation. In those domains,
division or modulo by zero is rejected before emission. Runtime RHS
expressions with dynamic divisors are still emitted as AST/HDL expressions; the
tool does not yet prove that every dynamic divisor is nonzero.

Width inference tries to use exact evidence that is already present in the
source. A slice such as `fifout[31:24]` proves that `fifout` is at least 32
bits, a guard such as `<txtimer>20'x1` proves a 20-bit comparison, and a test
selector such as `=2'3` proves a 2-bit selector. If the source does not contain
enough evidence, FSMGen keeps the width conservative and asks for an explicit
declaration instead of guessing.

Truthiness is intent-level: a signal used as a predicate means “non-zero.”
When flattened SystemVerilog needs a one-bit predicate from a multibit signal,
FSMGen emits a reduction such as `(|COUNT)` for true/non-zero or `(~|bytept)`
for false/zero. That is why the generated HDL may not literally show the bare
multibit signal in every enable expression; the reduction preserves the intent
and keeps Verilator/Yosys width checks clean.

Parser-created intermediate helpers that support these expression trees remain
internal implementation detail. They are now kept declared/assigned whenever a
final RHS expression still references them, and they do not become inferred
composition ports.

Examples:

```lisp
(QUO = (/ A B))
(REM = (% A B))
(QUO_ALIAS = (div A B))
(REM_ALIAS = (mod A B))
(QUO_CHAIN = (/ A B C))  ; emits left-to-right as A / B / C
(REM_CHAIN = (% A B C))  ; emits left-to-right as A % B % C
```

## Guards, Tests, and Updates

Common authoring shapes:

```lisp
(<start
  (A = 1)
)

(?(| A B)
  (=0 (FLAG = 0))
  (=1 (FLAG = 1))
)

(++ counter)
(+= count 4)
(-= retries)
```

Selectors with exact-width values can infer the selector signal:

```lisp
(?bytept
  (=2'3  (read = 1))
  (!=2'3 (-> wait))
)
```

## Current Boundary

This chapter is about the everyday surface.

For the exact live support line, the broad reference still lives in
`docs/USER_GUIDE.md`, especially the “Currently supported .fsm constructs”
section. The goal is to migrate that material fully into this book over time.
