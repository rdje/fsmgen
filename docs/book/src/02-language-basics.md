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
- `A <=- expr`: synchronous with auxiliary `*_r` surface
- `A <=+ expr`: legacy spelling for `<=-`
- `A <N 0` or `A <N 1`: delayed pulse form

### Clock Ticks and Cycles

FSMGen uses the usual edge-triggered flop timing model when describing
sequential assignments. A clock tick is one active clock transition. That
transition can be low-to-high or high-to-low in hardware, but most FSMGen
examples and generated synchronous logic use the low-to-high transition.

A clock cycle is the interval between two consecutive ticks. If the preceding
tick is called `N` and the next tick is called `N+1`, then cycle `N` is the
time after tick `N` and before tick `N+1`.

At tick `N`, a flop samples its `D` input as it was stable immediately before
the edge, written here as `N-`. Immediately after that edge, `N+`, the flop's
`Q` output holds the sampled value. `Q` then remains stable for the whole
cycle, up to `(N+1)-`, unless asynchronous reset or another explicitly
asynchronous mechanism intervenes. At tick `N+1`, the same rule repeats: the
`D` value stable at `(N+1)-` becomes the `Q` value at `(N+1)+`.

This is the timing basis for the sequential assignment operators. A `<-`
assignment names the `Q`/output side of the flop: the assignment selects a
`D` value during the current cycle, and the authored LHS observes that value
as `Q` after the next active tick. A `<=` assignment names the `D`/next-value
side directly: the authored LHS denotes the value selected during the current
cycle, while the corresponding `Q` value is only available after the next tick
unless a dual-output form exposes it separately. Decision-tree ordering does
not create procedural before/after timing inside a cycle; the tree selects the
combinational values that will be sampled by flops at the next active tick.

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
(<=- (D_IN NEXT_VALUE))
(<=+ (D_IN NEXT_VALUE))   ;; legacy alias for <=-
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
registered Q mirror, use `<=-` and read the generated `A_r` mirror. The older
`<=+` spelling is still accepted as a compatibility alias for `<=-`, but new
sources should prefer the symmetric `<=-` / `<-=` pair.

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
`<=-` assignments must not read the same LHS name from the RHS or assignment
guard. The legacy `<=+` alias follows the same rule. That form creates
combinational feedback in the generated next-value logic. Q/output-named `<-`
feedback remains valid and is the preferred spelling for ordinary registers.

## Practical Authoring Guidelines

Use assignment operators according to the hardware timing you intend:

- Use `=` only for true combinational outputs or combinational helper values.
- Use `<-` for ordinary flopped state and register loopback, especially for
  Q/output-named signals such as `addr_q`.
- Use `<=` only when the authored LHS intentionally names the D-input or
  next-value side of a flop. The RHS and assignment guard must not read that
  same LHS name.
- Use `<1`, `<2`, and other delayed-pulse forms when the intent is an explicit
  one-cycle flopped pulse rather than a sticky register assignment.

Keep conditions explicit and reviewable. Small guards are easier to read in
the source and in the generated enable logic. When a condition grows, expect
FSMGen to introduce factored intermediate signals in the emitted RTL.

For bring-up, use strict/check/report modes before treating emitted HDL as the
only evidence:

```bash
./bin/fsmgen --strict --check --json path/to/file.fsm
./bin/fsmgen --trace-verbosity=debug --trace-log=trace.log --output /tmp/out.sv path/to/file.fsm
```

For the full CLI and trace workflow, see
[Generated HDL, Debugging, and Inspection](09-generated-hdl-debugging-and-inspection.md).

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

This section carries the everyday active contract for guards, selector tests,
condition suffixes, and update shorthand. These forms are not just examples;
they are the regression-backed authoring surface.

### Guarded Blocks

Guarded blocks execute their nested actions only when the guard condition is
true:

```lisp
(<start
  (A = 1)
)
```

The negated form executes when the guard condition is false:

```lisp
(<!full
  (-> busy)
)
```

Guarded blocks must contain at least one action. Nested guards are allowed, and
their conditions compose by logical `AND`.

Active shorthand meanings are:

- `(<foo ...)` means `foo != 0`
- `(<!foo ...)` means `foo == 0`
- `(<foo=value ...)` and `(<foo==value ...)` mean equality
- `(<foo!=value ...)`, `(<foo<value ...)`, `(<foo<=value ...)`,
  `(<foo>value ...)`, and `(<foo>=value ...)` mean the corresponding
  comparison
- `(<(& req start !full) ...)` uses the normal expression language and means
  the compound predicate is true

The compact comparison family is the existing `name<op>value` grammar. The
same guard grammar is reused by condition suffixes and by non-state DT DTE
headers such as `(-route <req ...)`, `(-mode_hit <mode=3 ...)`, and
`(-both_ready <(& req ready) ...)`.

### Condition Suffixes

A condition suffix is the single-action form of a guarded block. It must use an
explicit guard marker such as `<...` or `<!...`; bare suffixes like
`(A <= B start)` or `(-> busy full)` are outside the active contract.

Examples:

```lisp
(A <= B <start)                         ;; same as: (<start (A <= B))
(-> busy <!full)                        ;; same as: (<!full (-> busy))
(OUT = IN <mode==1)                     ;; same as: (<mode==1 (OUT = IN))
(-> special <count<=3)                  ;; same as: (<count<=3 (-> special))
(-> joined <(& a_done b_done c_done))   ;; compound transition suffix
(= (OUT (+ A B)) <(& valid ready))      ;; pair-form assignment suffix
```

The suffix is action metadata, not part of an assignment RHS expression and not
part of a transition target name.

### Test Nodes

Computed-selector test nodes use a selector expression:

```lisp
(?(| A B)
  (=0 (FLAG = 0))
  (=1 (FLAG = 1))
)
```

Plain-selector test nodes use a compact `?SIG` header:

```lisp
(?MODE
  (=0 (A = 1))
  (!=8'0 (B = 1))
  (default (C = 1)))
```

Selectors with exact-width values can infer the selector signal:

```lisp
(?bytept
  (=2'3  (read = 1))
  (!=2'3 (-> wait))
)
```

Supported branch selectors are explicit operator-prefixed tokens such as
`=0`, `=1`, `=OTHER`, `!=8'0`, `<8'4`, `<=8'3`, `>8'3`, and `>=8'1`, plus one
fallback selector spelled `default` or `_`. Bare branch selectors like `BUSY`
or `0` are outside the active contract. A branch must contain at least one
action, and a test node may contain at most one fallback branch.

The fallback selector means the logical negation of the OR of all explicit
sibling predicates. For example:

```lisp
(?MODE
  (=0 (A = 1))
  (=1 (B = 1))
  (default (C = 1)))
```

The `C` branch condition is `!(MODE == 0 || MODE == 1)`. If explicit
predicates overlap, the fallback excludes their union. If the explicit
predicates are exhaustive for the selector width, the fallback is valid but
unreachable.

### Update Shorthand

Update shorthand targets a scalar signal and expands to the matching increment
or decrement assignment intent:

```lisp
(++ counter)       ;; increment by 1
(-- retries)       ;; decrement by 1
(+= count)         ;; increment by 1
(-= retries)       ;; decrement by 1
(+=4 byte_count)   ;; increment by 4
(-=1 remaining)    ;; decrement by 1
(+= count 4)       ;; increment by 4
(-= remaining 3)   ;; decrement by 3
```

After the optional delta, update shorthand accepts only an explicit condition
suffix such as `<start`, `<!full`, or `<(& req ready)`.

Inline modifiers keep the surrounding assignment family:

```lisp
(ACC <- SRC (+=))
(ACC <- SRC (+= 2))
(COMB = SRC (-=))
(COMB = SRC (-= 1))
```

## Current Boundary

This chapter is about the everyday surface.

The active direct-language boundary above is migrated from the live guide into
the book. `docs/USER_GUIDE.md` remains a broad migration reference, but
normative `.fsm` syntax found there should have a chapter home here rather than
remaining only in the monolithic guide.
