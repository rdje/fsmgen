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

## Current Boundary

This chapter is about the everyday surface.

For the exact live support line, the broad reference still lives in
`docs/USER_GUIDE.md`, especially the “Currently supported .fsm constructs”
section. The goal is to migrate that material fully into this book over time.
