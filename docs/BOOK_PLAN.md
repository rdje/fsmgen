# FSMGen Documentation Book Plan

This document captures the planned split of the monolithic
[USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md)
into a book-like documentation set.

Status: planned, not yet executed.

## Why split the guide

The current
[USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md)
is already large enough that it is doing too many jobs at once:

- introduction
- tutorial
- language reference
- composition guide
- support boundary reference
- debugging guide
- troubleshooting

That makes it harder for new users to learn progressively and harder for
existing users to find the exact topic they need.

The target shape is a book-like docs set:

- one Markdown file per major topic/chapter
- ordered from beginner to advanced
- realistic examples throughout
- precise reference docs kept alongside tutorials
- one landing page that orients the user before they dive deeper

## Target docs topology

The preferred long-term structure is:

- `docs/USER_GUIDE.md`
  - Landing page
  - table of contents
  - quick orientation
  - “read this first” page
- `docs/book/00-introduction.md`
  - What FSMGen is
  - what problems it solves
  - mental model
- `docs/book/01-first-fsm.md`
  - first working `.fsm`
  - first HDL generation
  - first debug loop
- `docs/book/02-language-basics.md`
  - core syntax
  - signals
  - assignment operators
  - guards
  - tests
  - update shorthand
- `docs/book/03-decision-trees-and-fsms.md`
  - `?fsm`
  - `?dt`
  - state transitions
  - combinational DTs
  - reset/init
- `docs/book/04-symbols-types-and-imports.md`
  - `+constants`
  - `+enums`
  - `+types`
  - scalar type aliases
  - aggregate type aliases
  - `+import`
- `docs/book/05-composition-basics.md`
  - `?top`
  - child kinds
  - `?ports`
  - simple `?toplink`
  - same-name convention
- `docs/book/06-composition-advanced.md`
  - source-side expressions
  - actuals
  - concat/repeat
  - package-backed actuals
  - inferred top ports
  - inferred carriers
  - declared type compatibility
- `docs/book/07-packages-and-sharing.md`
  - `?pkg`
  - semantic imports
  - namespacing
  - shared scalar values
  - shared aggregate values
- `docs/book/08-type-inference-and-aggregate-data.md`
  - inference-first typing
  - aggregate autovivification direction
  - packed lowering model
  - current supported boundary
- `docs/book/09-generated-hdl-debugging-and-inspection.md`
  - CLI flow
  - generated HDL reading
  - debug workflow
  - IR surfaces
  - diagnostics
- `docs/book/10-errors-strict-mode-and-troubleshooting.md`
  - common failures
  - strict mode
  - how to interpret errors
  - regression guidance
- `docs/book/11-extensions-and-embedding.md`
  - typed extensions
  - embedding/API notes
  - advanced integration entry points
- `docs/book/12-cookbook.md`
  - realistic copyable patterns
  - small end-to-end examples
  - “how do I model X?” answers

## Docs that stay as focused references

These docs should remain separate even after the split:

- [COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md)
  - precise composition support boundary
- [EXTENSION_MODEL.md](/Users/richarddje/Documents/github/fsmgen/docs/EXTENSION_MODEL.md)
  - extension-specific reference
- [REGRESSION_CORPUS.md](/Users/richarddje/Documents/github/fsmgen/docs/REGRESSION_CORPUS.md)
  - regression/reference process
- [INTENT_CAPTURE_AXI_CASE_STUDY.md](/Users/richarddje/Documents/github/fsmgen/docs/INTENT_CAPTURE_AXI_CASE_STUDY.md)
  - focused case study

The book chapters should link to these focused references instead of duplicating
their narrow technical detail.

## Mapping from the current guide

The current
[USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md)
should be split roughly as follows:

- `1) What FSMGen is` -> `00-introduction.md`
- `2) Core concepts` -> `02-language-basics.md`
- `2.1) Currently supported .fsm constructs` -> spread across chapters 02-08,
  with concise summary tables on the landing page
- `3) Basic usage` -> `01-first-fsm.md` and `09-generated-hdl-debugging-and-inspection.md`
- `4) Useful options` -> `09-generated-hdl-debugging-and-inspection.md`
- `5) Input resolution and FSMLIB` -> `07-packages-and-sharing.md`
- `6) Debug workflow` -> `09-generated-hdl-debugging-and-inspection.md`
- `7) Typed extensions` -> `11-extensions-and-embedding.md`
- `8) External compatibility flow` -> `11-extensions-and-embedding.md`
- `9) Troubleshooting` -> `10-errors-strict-mode-and-troubleshooting.md`
- `10) Practical authoring guidelines` -> landing page plus chapter intros,
  with concrete guidance repeated where users actually need it

## Migration order

The split should happen incrementally so docs stay usable at every step.

### Phase 1: establish the landing page and chapter skeleton

- reduce `docs/USER_GUIDE.md` to:
  - short introduction
  - quickstart links
  - chapter table of contents
  - “where to go next”
- create the `docs/book/` chapter files
- start each chapter with:
  - intent
  - current support boundary
  - realistic first examples

### Phase 2: extract beginner flow first

- move “What FSMGen is”
- move first-run/basic-usage material
- move the earliest language basics

This gives new users an easier on-ramp immediately.

### Phase 3: split the language and type material

- extract core language syntax/reference
- extract symbols/types/imports
- extract DT/FSM authoring

This prevents the language contract from being buried inside one giant page.

### Phase 4: split composition cleanly

- extract composition basics
- extract advanced composition topics
- keep
  [COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md)
  as the precise support-boundary companion

### Phase 5: split tooling/debugging/troubleshooting

- move options/debug workflow/generated HDL reading
- move strict mode and troubleshooting
- move extensions/embedding

### Phase 6: add the cookbook layer

- add realistic, copyable examples
- answer recurring “how do I model X?” questions
- include both simple and moderately realistic end-to-end examples

## Chapter-level quality standard

Each chapter should follow the same standard:

- explain intent before syntax
- state the current supported boundary honestly
- use realistic examples, not only toy fragments
- give users a safe path from simple to advanced
- link to precise reference docs when needed
- avoid making users hunt through one giant page for one rule

## Non-goals

This plan does not mean:

- duplicate every detail from focused reference docs into the book
- turn every chapter into an unreadable wall of reference text
- freeze the exact chapter names forever

The structure may evolve, but the core direction should remain:
progressive, book-like, example-rich documentation instead of one oversized
guide page.
