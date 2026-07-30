# Introduction

FSMGen compiles Lisp-like `.fsm` sources into synthesizable HDL.

Today, the primary backend is SystemVerilog, with Verilog compatibility through
the existing path. FSMGen also ships bounded VHDL generation for documented
direct single-FSM and exact composition subsets. VHDL is not yet a full-parity
backend and is not locally qualified by GHDL or another external VHDL compiler;
unsupported shapes fail closed. The exact shipped subset and remaining work are
tracked under [Backends And Validation](14-feature-backlog.md#backends-and-validation).

This book is the progressive front door for FSMGen:

- start simple,
- learn the mental model before the full reference,
- then move into composition, packages, types, debugging, and embedding.

It should also be treated as an evolving product manual, not a static snapshot.

When FSMGen's user-facing surface changes, this book is expected to change with
it.

This book is the public-facing documentation surface.

That means:

- it should explain what FSMGen does,
- how to use it,
- why the user-facing model works the way it does,
- and what the current shipped boundaries really are.
- every user-visible `.fsm` feature, composition form, package/type/import
  surface, CLI/debug behavior, diagnostic boundary, generated-HDL expectation,
  and support limitation should have a chapter home here.
- examples are part of the contract: users should be able to learn FSMGen by
  adapting realistic patterns from the book, not by reading implementation
  notes or reverse-engineering tests.

Internal continuity files still exist in the repo, but they have a different
job: they help maintainers preserve implementation continuity across crashes,
handoffs, and long-running feature work. They are not a substitute for putting
user-facing behavior into the book. Both surfaces matter: the book helps users
learn and trust FSMGen, while the continuity docs preserve the engineering
thread that lets the project keep moving safely.

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

- `docs/USER_GUIDE.md`: broad migration reference during guide-to-book
  transfer
- `docs/COMPOSITION_SCOPE.md`: precise composition support boundary
- `docs/EXTENSION_MODEL.md`: typed extension boundary
- `ROADMAP_STATUS.md`: live roadmap and current implementation lane for the
  maintainer side

The goal is not to duplicate every narrow maintainer artifact here immediately.

The goal is to give users one friendly, transparent path through the product
while the remaining user-facing deep reference material is folded into the book
incrementally.

That means this book should keep evolving alongside the project:

- new shipped features should appear here,
- examples should stay current and realistic,
- every user-facing surface should be documented with enough examples to make
  the feature approachable,
- and stale or missing user-facing guidance should be treated as a real quality
  gap.

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
support boundary,” it means the shipped, regression-backed boundary. The
consolidated list of user-visible items that are future work, deferred, or not
fully shipped is maintained in [Feature Backlog](14-feature-backlog.md).
