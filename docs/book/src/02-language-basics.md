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
- `+size`: width declaration section
- `+constants`, `+enums`, `+types`: symbol and type sections
- `:=`: init/reset directive
- `<...`: guard suffix

## Assignment Operators

Current quick reference:

- `A = expr`: combinational assignment
- `A <- expr`: synchronous/flopped assignment
- `A <= expr`: synchronous/flopped variant
- `A <-= expr`: synchronous with auxiliary `next_*` surface
- `A <=+ expr`: synchronous with auxiliary `*_r` surface
- `A <N 0` or `A <N 1`: delayed pulse form

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
- word aliases such as `add`, `sub`, `and`, `or`, `xor`

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
