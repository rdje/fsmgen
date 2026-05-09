# FSMGen Documentation Book Plan

This document captures the planned split of the monolithic
[USER_GUIDE.md](docs/USER_GUIDE.md)
into a book-like documentation set.

Status: in progress.

The mdBook scaffold now exists under
`docs/book/` with:

- `docs/book/book.toml`
- `docs/book/src/SUMMARY.md`
- the first shipped chapter set under `docs/book/src/`

The migration is still incomplete:

- [USER_GUIDE.md](docs/USER_GUIDE.md)
  remains the broad reference during the split,
- focused reference docs such as
  [COMPOSITION_SCOPE.md](docs/COMPOSITION_SCOPE.md)
  still carry the narrow normative boundary for their lanes,
- and the book should keep absorbing user-facing material until it becomes the
  default learning surface.

The book must be treated as an evolving public product artifact:

- it evolves alongside the shipped user-facing surface,
- new user-visible features should update the relevant chapter material as part
  of shipping,
- and stale examples or stale support wording in the book are product bugs, not
  optional cleanup.
- the book is the canonical user-facing surface for FSMGen: every visible
  `.fsm` authoring feature, composition construct, package/type/import form,
  CLI/debug behavior, diagnostic boundary, generated-HDL expectation, and
  support limitation needs a clear chapter home rather than living only in
  maintainer notes.
- downstream tool-facing contracts should also have a book home. The current
  SPECFORGE alignment response lives in
  [SPECFORGE_FEEDBACK_RESPONSE.md](docs/SPECFORGE_FEEDBACK_RESPONSE.md)
  and is linked from the embedding chapter until those surfaces mature into
  dedicated capability/check/normalized-export reference chapters.

The book and the continuity notes have different jobs:

- the mdBook under `docs/book/` is the public-facing product documentation that
  users and the outside world should read to understand what FSMGen does, how
  to use it, and the rationale behind the user-facing design,
- live continuity artifacts such as `DEVELOPMENT_NOTES.md`, `MEMORY.md`,
  `ROADMAP_STATUS.md`, `ROADMAP_V2.md`, and `CHANGES.md` exist to preserve
  implementation continuity, rationale breadcrumbs, and session recovery
  context across crashes or handoffs,
- both surfaces are essential: the book makes FSMGen approachable and
  transparent to users, while the live continuity docs keep implementation
  direction coherent across long-running work and interrupted sessions,
- and those continuity docs are not substitutes for chaptered public
  documentation in the book.

Practical rule:

- every user-facing feature should land in the book with a clear
  chapter/section, practical rationale, current support boundary, and realistic
  examples,
- when a feature has multiple authoring styles or non-obvious failure modes,
  the book should show both the recommended path and representative rejected
  forms so users understand the shape of the contract,
- examples should be plentiful enough that users can learn by adapting real
  patterns instead of reverse-engineering tests or generated HDL,
- while the continuity docs may still record engineering rationale and rollout
  sequencing for maintainers.

## Why split the guide

The current
[USER_GUIDE.md](docs/USER_GUIDE.md)
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
- `docs/book/book.toml`
  - mdBook configuration
- `docs/book/src/SUMMARY.md`
  - chapter order
  - navigation spine
- `docs/book/src/00-introduction.md`
  - What FSMGen is
  - what problems it solves
  - mental model
- `docs/book/src/01-first-fsm.md`
  - first working `.fsm`
  - first HDL generation
  - first debug loop
- `docs/book/src/02-language-basics.md`
  - core syntax
  - signals
  - assignment operators
  - guards
  - tests
  - update shorthand
- `docs/book/src/03-decision-trees-and-fsms.md`
  - `?fsm`
  - `?dt`
  - state transitions
  - combinational DTs
  - reset/init
- `docs/book/src/04-symbols-types-and-imports.md`
  - `+constants`
  - `+enums`
  - `+types`
  - scalar type aliases
  - aggregate type aliases
  - `+import`
- `docs/book/src/05-composition-basics.md`
  - `?top`
  - child kinds
  - `?ports`
  - simple `?toplink`
  - same-name convention
- `docs/book/src/06-composition-advanced.md`
  - source-side expressions
  - actuals
  - concat/repeat
  - package-backed actuals
  - inferred top ports
  - inferred carriers
  - declared type compatibility
- `docs/book/src/07-packages-and-sharing.md`
  - `?pkg`
  - semantic imports
  - namespacing
  - shared scalar values
  - shared aggregate values
- `docs/book/src/08-type-inference-and-aggregate-data.md`
  - inference-first typing
  - aggregate autovivification direction
  - packed lowering model
  - current supported boundary
- `docs/book/src/09-generated-hdl-debugging-and-inspection.md`
  - CLI flow
  - generated HDL reading
  - debug workflow
  - IR surfaces
  - diagnostics
- `docs/book/src/10-errors-strict-mode-and-troubleshooting.md`
  - common failures
  - strict mode
  - how to interpret errors
  - regression guidance
- `docs/book/src/11-extensions-and-embedding.md`
  - typed extensions
  - embedding/API notes
  - advanced integration entry points
- `docs/book/src/12-cookbook.md`
  - realistic copyable patterns
  - small end-to-end examples
  - “how do I model X?” answers
- `docs/book/src/90-reference-map.md`
  - migration map
  - focused-reference links
  - old-guide section mapping

## Docs that stay as focused references

These docs should remain separate even after the split:

- [COMPOSITION_SCOPE.md](docs/COMPOSITION_SCOPE.md)
  - precise composition support boundary
- [EXTENSION_MODEL.md](docs/EXTENSION_MODEL.md)
  - extension-specific reference
- [REGRESSION_CORPUS.md](docs/REGRESSION_CORPUS.md)
  - regression/reference process
- [INTENT_CAPTURE_AXI_CASE_STUDY.md](docs/INTENT_CAPTURE_AXI_CASE_STUDY.md)
  - focused case study

The book chapters should link to these focused references instead of duplicating
their narrow technical detail.

## Mapping from the current guide

The current
[USER_GUIDE.md](docs/USER_GUIDE.md)
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

Status: shipped.

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

Status: in progress.

- move “What FSMGen is”
- move first-run/basic-usage material
- move the earliest language basics

This gives new users an easier on-ramp immediately.

### Phase 3: split the language and type material

Status: in progress.

- extract core language syntax/reference
- extract symbols/types/imports
- extract DT/FSM authoring

This prevents the language contract from being buried inside one giant page.

### Phase 4: split composition cleanly

Status: in progress.

- extract composition basics
- extract advanced composition topics
- keep
  [COMPOSITION_SCOPE.md](docs/COMPOSITION_SCOPE.md)
  as the precise support-boundary companion

### Phase 5: split tooling/debugging/troubleshooting

Status: in progress.

- move options/debug workflow/generated HDL reading
- move strict mode and troubleshooting
- move extensions/embedding

### Phase 6: add the cookbook layer

Status: started.

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
