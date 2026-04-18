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
- `A <- expr`: synchronous/flopped assignment
- `A <= expr`: synchronous/flopped variant
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
(<=  (Q D))
(<-= (Q D))
(<=+ (Q D))
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

The same pair form covers the active LHS/RHS surface, including nested
expressions, RHS concat, aggregate leaves, and LHS deconstruct:

```lisp
(=  (OUT (concat HI LO)))
(=  ((concat HI LO) DATA))
(<- ((cat REG_HI REG_LO) NEXT_DATA) <load)
(=  (FRAME.payload TAIL))
```

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

## Expressions

The current live expression surface includes:

- literals
- signal references
- indexed and sliced references
- unary `!`
- comparison operators such as `==`, `!=`, `<`, `<=`, `>`, `>=`
- arithmetic and bitwise operators such as `+`, `-`, `*`, `/`, `%`, `&`, `|`, `^`
- word aliases such as `not`, `eq`, `ne`, `lt`, `le`, `gt`, `ge`, `add`,
  `sub`, `mul`, `div`, `mod`, `and`, `or`, and `xor`
- RHS pack expressions with `(concat ...)` or the shorter `(cat ...)` alias

The arithmetic/bitwise expression families are n-ary. Operators such as `+`,
`*`, `&`, `|`, and `^` combine all operands; `-`, `/`, and `%` are
left-associative, so `(/ a b c)` means `((a / b) / c)` and `(% a b c)` means
`((a % b) % c)`.

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
