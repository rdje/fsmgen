# Introduction

FSMGen compiles state-machine and intent specifications into synthesizable HDL.

The long-term goal is complete digital-chip source authoring: real CPU, DSP,
MCU, ASIC and SoC designs from either IAL1 or IAL2, with VIAL for initial
functional verification. The end product is a complete implementation-ready
source tree; synthesis and physical implementation remain downstream. This goal requires
future capabilities and qualification beyond today's documented subsets.
The [proposed horizon](../../../docs/tasks/FULL-CHIP-SOURCE-AUTHORING-HORIZON.md)
records the objective, including access to the full feature set through API/MCP
and ChatGPT/Claude plugins and UI. Current exposure remains bounded by the
published capabilities. Required delivery priority is unchanged.

Every IAL1 and IAL2 design feature must ultimately have an elegant, expressive
Lispish/S-expression authoring form. Common designs should be concise, composition
natural, and detailed control readable, with no useless verbosity. Source and
API/MCP operations must preserve the same hardware meaning. These are feature
acceptance requirements for the full-chip goal, not claims of current completeness.

The proposed reusable component library is scoped to authoring and reuse at
IAL1/IAL2. It excludes a separate IAL0 (`.fsm`) component-library surface. IAL0
remains the explicit cycle-accurate lowering and review layer, including generated
`.fsm` artifacts; existing direct IAL0 authoring and composition retain their
documented contracts.

HIAL's complete lowering goal is **IAL2 -> IAL1 -> IAL0 -> SystemVerilog/VHDL**.
Every adjacent step must preserve specified meaning and source provenance;
expansion into several lower-level constructs is valid. VIAL must provide the
same preservation discipline for verification behavior, such as checks, monitors
and stimulus, which need not be synthesizable. Current VIAL uses one `.vial`
language and private semantic/execution stages; that architecture is also the
selected full-chip direction. High-level scenarios and detailed verification
control compose in the same language, with complete checked lowering required
for every supported feature and target.

The [lowering-contract reference](13h-lowering-reference.md#lowering-contract-for-hardware-and-verification)
explains the layers, both domains, timing/types/configuration, source identity,
worked examples, API/MCP access and qualification. Start there for the full
explanation, then use the current target/profile boundaries below.

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

When a feature has several authoring styles or non-obvious failure modes, its
chapter should show the recommended form and representative rejected forms.
Examples should progress from the smallest useful case to realistic use.

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

- `docs/COMPOSITION_SCOPE.md`: precise composition support boundary
- `docs/EXTENSION_MODEL.md`: typed extension boundary
- `ROADMAP_V2.md`: high-level roadmap direction and sequencing
- `MEMORY.md` plus `docs/TASK_TREE.md`: bounded current state and the exact
  live implementation frontier for maintainers

Optional `Current Frontier` sections inside task files are historical snapshots.
Maintainers resume from the authoritative task nodes, live index and bounded
Memory pointer; a historical snapshot does not describe current delivery.

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
