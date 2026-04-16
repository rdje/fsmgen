# Errors, Strict Mode, and Troubleshooting

This chapter is about understanding failures quickly and safely.

## Common Failure Families

### Parser And Shape Errors

Typical causes:

- malformed root forms
- malformed child entries
- malformed `?ports` or `?toplink` tokens
- malformed `+system` or `:=` payloads
- `+size` expressions that reference unknown symbols or whole aggregate values
  where one scalar integer width is required
- `+size` arithmetic that cannot produce a valid positive integer width, such
  as division or modulo by zero
- `+size` operators outside the bounded supported set, such as `pow`
- `+size` operator forms with malformed arity, such as `(+ 8)`

These should now fail explicitly instead of falling through to vague behavior.

### Composition Planning Errors

Typical causes:

- unknown child source
- missing `.rtlif` metadata
- width mismatch
- direction mismatch
- duplicate drivers
- ambiguous connect-by-name
- blocked omitted-`?ports` inference
- incompatible declared type contracts

### Direct Generation Errors

Typical causes:

- illegal combinational self-dependency
- incompatible assignment widths
- undeclared internal operands
- unassigned internal operands

The pre-generation validation path exists specifically to catch these before
emission.

## Failure Summaries

Non-quiet `bin/fsmgen` runs now try to keep useful local context in summaries,
for example:

- lane
- construct
- child or top endpoint
- top expression
- child expression
- actual source or endpoint

That is especially important in composition, where the failing surface is often
one declared link or one inferred boundary family.

## Strict Mode

Strict mode exists to narrow the language toward the supported intentional
surface.

Examples of what strict mode is already used for:

- narrowing legacy root aliases
- rejecting some compatibility residue
- preventing accidental dependence on older looser spellings
- preferring canonical assignment pairs such as `(= (OUT IN))` over infix
  compatibility spellings such as `(OUT = IN)`

Use strict mode when you want the tool to tell you whether a source already
fits the cleaner forward contract.

The regression corpus deliberately keeps paired default-compatible and
strict-rejected assets for compatibility residue such as infix assignments, so
the supported boundary is machine-checked instead of living only in examples.
It also keeps positive strict-acceptance markers for canonical supported
surfaces. Canonical reset, canonical init/default, and canonical assignment
fixtures must pass through both the strict pipeline API and
`bin/fsmgen --strict`.

## Backend Expectations

Current backend truth:

- SystemVerilog: primary live backend
- Verilog: supported through the existing path
- VHDL: recognized by the CLI, but explicitly not implemented as a full backend

So a VHDL request currently failing is not a mystery bug. It is the honest
current boundary.

## Practical Debug Checklist

1. Re-run with trace enabled.
2. Confirm the active root kind.
3. Confirm imported packages and search roots.
4. Confirm port widths and directions.
5. Confirm named type compatibility when aliases are involved.
6. Inspect generated HDL or structural IR if planning succeeded.

## Regression Guidance

Before landing behavior changes, run the local regression suite:

```bash
./bin/ci-regression
```

For focused work, run the nearby targeted `prove` suites first, then the full
regression.

## Current Boundary

The project is trying to move toward:

- early failure
- local diagnostics
- regression-locked contracts

If a failure feels vague or misleading, that is still a product-quality gap,
not something users should simply accept.
