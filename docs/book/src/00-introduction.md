# Introduction

FSMGen compiles Lisp-like `.fsm` sources into synthesizable HDL.

Today, the primary backend is SystemVerilog. Verilog compatibility exists, and
explicit VHDL support is still intentionally not implemented yet.

This book is the progressive front door for FSMGen:

- start simple,
- learn the mental model before the full reference,
- then move into composition, packages, types, debugging, and embedding.

It should also be treated as a live book, not a static manual snapshot.
When FSMGen's user-facing surface changes, this book is expected to change with
it.

## What FSMGen Is Good At

FSMGen is designed for:

- state-machine and decision-tree authoring at the intent level,
- explicit, regression-backed language contracts,
- generated HDL that stays understandable enough to debug,
- composition of generated children and external RTL,
- and increasingly strong typed and diagnostic surfaces.

## How To Read This Book

Recommended order:

1. Read [Your First FSM](01-first-fsm.md).
2. Read [Language Basics](02-language-basics.md).
3. Read [Decision Trees and FSMs](03-decision-trees-and-fsms.md).
4. Move into [Composition Basics](05-composition-basics.md) only when you need hierarchy or external RTL.
5. Use [Cookbook](12-cookbook.md) when you want practical patterns quickly.

## Current Documentation Shape

This book is now the progressive learning surface.

The repository still keeps a few focused technical references:

- `docs/USER_GUIDE.md`: broad live reference during the migration
- `docs/COMPOSITION_SCOPE.md`: precise composition support boundary
- `docs/EXTENSION_MODEL.md`: typed extension boundary
- `ROADMAP_STATUS.md`: live roadmap and current implementation lane

The goal is not to duplicate every narrow technical artifact here immediately.
The goal is to give users one friendly path through the product while the
remaining deep reference material is folded into the book incrementally.

That means this book should keep evolving alongside the project:

- new shipped features should appear here,
- examples should stay current and realistic,
- and stale user-facing guidance should be treated as a real quality gap.

## Building The Book

From repository root:

```bash
mdbook build docs/book
```

For local live preview:

```bash
cd docs/book
mdbook serve --open
```

## Current Product Boundaries

The active `.fsm` surface already covers:

- direct `?fsm` and `?dt` module roots,
- composition through `?top`,
- semantic packages through `?pkg`,
- constants, enums, and bounded `+types`,
- typed composition links and typed aggregate compatibility checks,
- and typed extensions for explicit embedding hooks.

Not every future direction is complete yet. When this book says “current
support boundary,” it means the shipped, regression-backed boundary.
