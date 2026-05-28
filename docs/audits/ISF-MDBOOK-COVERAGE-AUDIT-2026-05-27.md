# mdBook Coverage Audit — 2026-05-27

This is a one-shot audit of the FSMGen mdBook (`docs/book/src/`)
against the shipped codebase surface. It exists because the user
flagged that documentation is as important as code: the book is the
only window through which a non-technical reader can understand what
FSMGen does and how it does it.

This document is the deliverable for the
[`ISF-MDBOOK-COVERAGE-AUDIT`](../tasks/ISF-MDBOOK-COVERAGE-AUDIT.md)
task tree. It identifies gaps and proposes a prioritized queue of
downstream coverage slices. It is not the implementation of those
slices.

## Methodology

The audit combines four passes:

1. **Validator rejection-path inventory**: count and classify
   `confess` calls in the ISF parser and lowerer, focusing on phrase
   families that signal user-facing diagnostics (`remains deferred`,
   `requires`, `supported only`, `must be`, `Error:`, `duplicate`,
   `unknown`, `unsupported`, `invalid`, `expected`).
2. **Accept-path keyword inventory**: count shipped ISF clause
   keywords (`(transaction ...)`, `(spawn ...)`, `(do ...)`,
   `(repeat ...)`, etc.) and their mention frequency in book
   chapters.
3. **Book chapter coverage map**: walk each ISF book chapter
   (`13-intent-scheduling.md` through `13k-isf-feature-support-matrix.md`)
   plus the cookbook, count examples, list headings, and assess
   coverage density.
4. **Backlog status spot-check**: tally `Status:` markers in
   `14-feature-backlog.md`, sample a handful of "shipped" claims
   against current validator behavior, and look for stale "backlog"
   claims that have since shipped.

The audit treats `.fsm` source examples (\`\`\`lisp blocks) as the
primary indicator of "concrete documentation". Prose without an
example is treated as partial coverage.

## Inventory: validator rejection paths

`perl/FSM/Scheduler/ISF/LoweringIR.pm` is the ISF lowerer. It hosts
**446 distinct `confess` call sites** with **395 unique diagnostic
templates** after variable substitution. The breakdown by phrase
family:

| Phrase family | Count |
| --- | --- |
| `remains deferred` (explicit backlog markers) | 25 |
| `requires <X>` | 82 |
| `supports only` / `supported only` / `is supported only` | 34 |
| `cannot` | 18 |
| `duplicate` | 17 |
| `unknown` | 24 |
| `unsupported` | 21 |
| `shape` (override/value shape mismatches) | 3 |

`perl/FSM/Adapter/ISF/Parser.pm` is the ISF parser. It hosts
**502 confess sites** with **476 unique templates**:

| Phrase family | Count |
| --- | --- |
| `Error:` (parser-style prefix) | 482 |
| `requires <X>` | 97 |
| `must be <X>` | 78 |
| `duplicate` | 47 |
| `unknown` | 29 |
| `unsupported` | 24 |
| `remains deferred` | 22 |
| `supports only` / `supported only` | 3 |
| `expected` | 3 |
| `invalid` | 1 |

In addition, `perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm`
adds 34 emitter-level confess sites and `perl/FSM/Scheduler/ISF.pm`
adds 19 driver-level confess sites.

Total ISF-stack rejection surface: **~1003 confess call sites**.

The 25 lowerer `remains deferred` templates (the most user-facing
backlog markers) include:

- `cross-domain repeat-body do remains deferred` (3 sites — top-level,
  when-body, switch-branch)
- `loop-contained repeat-body do/spawn remains deferred` (2 sites)
- `deeper-nested repeat-body do/spawn remains deferred` (2 sites)
- 4 activation-override sub-axis gates (`repeat-count`, `wait-count`,
  `latency-bound`, `watchdog-limit`) × 3 entry points
  (spawn/do, rule trigger) = additional sites
- 5 `package constant aggregate/member path remains deferred`
  templates (one per axis: activation, actor default, transaction
  default, data-op width, contract window, repeat count, wait count,
  latency, watchdog)
- 4 `two-child data route ... remains deferred` templates
- 4 `await_any after the (later) do/spawn remains deferred` templates

The 22 parser `remains deferred` templates are not enumerated here;
they cover unqualified package constants, aggregate package
constants, package member/item paths, ambiguous local-enum/
package-constant spellings, and similar.

## Inventory: shipped accept-path keywords

Keyword mention frequency in the 12 ISF book chapters
(`13-intent-scheduling.md` through `13k-isf-feature-support-matrix.md`):

| Keyword | Mentions | Coverage |
| --- | --- | --- |
| `actor` | 548 | high |
| `transaction` | 456 | high |
| `(drive ` | 131 | high |
| `(do ` | 118 | high |
| `(params ` | 107 | high |
| `(complete ` | 70 | medium |
| `(domain ` | 63 | medium |
| `(set ` | 53 | medium |
| `(sample ` | 52 | medium |
| `(spawn ` | 51 | medium |
| `(when ` | 49 | medium |
| `(repeat ` | 44 | medium |
| `(bind ` | 42 | medium |
| `(await ` | 32 | medium |
| `(rule ` | 28 | medium |
| `(wait ` | 26 | medium |
| `(switch ` | 26 | medium |
| `(trigger ` | 23 | medium |
| `(clock-domains` | 17 | low-medium |
| `(shift_left ` | 16 | low-medium |
| `(latency ` | 16 | low-medium |
| `(update ` | 13 | low-medium |
| `(while ` | 12 | low |
| `(until ` | 11 | low |
| `(imports` | 11 | low |
| `(stage ` | 10 | low |
| `(assemble ` | 10 | low |
| `(shift_right ` | 10 | low |
| `(constants` | 7 | low |
| `(extract ` | 7 | low |
| `(store ` | 6 | low |
| `(contract ` | 6 | low |
| `(load ` | 5 | low |
| `(types ` | 4 | very-low |
| `(ports ` | 3 | very-low |
| `(handshake` | 1 | deprecated (OK) |

## Inventory: per-chapter coverage

| Chapter | Lines | Headings | `lisp`/`fsm` examples |
| --- | --- | --- | --- |
| `13-intent-scheduling.md` | 1055 | 5 | 4 |
| `13a-actor-interface.md` | 413 | 11 | 12 |
| `13b-transactions.md` | 1919 | 14 | 38 |
| `13c-drive-blocks.md` | 143 | 5 | 12 |
| `13d-control-flow.md` | 346 | 5 | 12 |
| `13e-data-manipulation.md` | 249 | 7 | 11 |
| `13f-composition.md` | 1565 | 13 | 32 |
| `13g-rules.md` | 495 | 8 | 13 |
| `13h-lowering-reference.md` | 2241 | 24 | 98 |
| `13i-downstream-integration.md` | 1 | 0 | 0 (file is one `{{#include ../../ISF_DOWNSTREAM_INTEGRATION_SPEC.md}}` directive) |
| `13j-type-enum-aggregate.md` | 210 | 6 | 6 |
| `13k-isf-feature-support-matrix.md` | 1321 | 18 | 14 |

Observations:

- **`13-intent-scheduling.md`** is the ISF overview chapter (1055
  lines) but contains only 4 source examples. The overview reads as
  prose-heavy; readers landing on the ISF section see paragraphs
  before they see code.
- **`13d-control-flow.md`** has only 12 examples for a chapter that
  must explain `when`/`switch`/`repeat`/`while`/`until`/`do`/`spawn`
  control flow. Two of those 12 examples were just added by the
  prior `ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE` slice.
- **`13j-type-enum-aggregate.md`** has 6 examples for ISF types,
  enums, and aggregates — a wide surface with low example density.
- **`13c-drive-blocks.md`** is short (143 lines) — likely
  proportional to the feature surface, but every drive variant
  (handshake, ready/valid, raw) should appear.
- **`13e-data-manipulation.md`** has 11 examples for the
  `set`/`update`/`shift_left`/`shift_right`/`assemble`/`extract`/
  `store`/`load` surface. Light, but each axis has at least one
  example.
- **`13h-lowering-reference.md`** is the largest (2241 lines, 98
  examples). This chapter is dense and well-illustrated and serves
  as the reference for code reviewers.

## Cross-cutting gap list

### G1. Cookbook chapter (`12-cookbook.md`) has zero ISF recipes

The cookbook is the chapter a new user reaches via "show me
end-to-end examples." It has 8 recipes covering counter FSMs,
routing DTs, generated children, multi-child wiring, structural
defaults, package-backed values, typed aggregates, and a first debug
run.

`grep -c 'spawn' docs/book/src/12-cookbook.md = 0`,
`rule = 0`, `trigger = 0`, `transaction = 0`.

This means the cookbook covers the `.fsm` (IAL0) authoring layer
only. ISF (IAL1) — which is the primary authoring surface for new
work — has no end-to-end recipe in the cookbook. A new user
following the book in order reaches Chapter 12 with no compact
recipes for ISF actors, transactions, generated children, or rules.

**Recommended slice**: extend `12-cookbook.md` with 4-6 ISF recipes
of comparable size to the existing entries (e.g., "A Small ISF
Actor", "Spawn-Based Generated Child", "Rule-Triggered Transaction",
"Multi-Domain Crossing", "Repeat-Body Generated Do").

### G2. Low-density coverage for shipped ISF clause keywords

The keyword mention count above places the following at "low" or
"very-low" coverage despite being shipped surface:

- **`(types ...)`** (4 mentions): local type aliases inside
  actor/transaction bodies.
- **`(ports ...)`** (3 mentions): transaction-local port declarations
  used by `(bind ...)`. This is heavily exercised by the recent
  port-width activation-override slice but the book barely names it.
- **`(constants ...)`** (7 mentions): actor-local declared constants.
- **`(contract ...)`** (6 mentions): temporal contract windows
  (a major shipped feature).
- **`(store ...)`** / **`(load ...)`** (6/5 mentions): bank
  storage access — the headline accept path for storage banks.
- **`(stage ...)`** (10 mentions): pipeline stages.
- **`(extract ...)`** (7 mentions): data-extract operations.
- **`(assemble ...)`** (10 mentions): data-assemble operations.
- **`(shift_right ...)`** (10 mentions): one of four data-op widths.

Each of these warrants at least one focused example in the chapter
that introduces it.

**Recommended slices**: one per clause family, each adding 1-2
examples plus a brief "shape / accepted variants / failure modes"
sentence to the relevant chapter (mostly `13b`, `13e`, `13j`).

### G3. Validator `remains deferred` diagnostics without book example

The 25 lowerer `remains deferred` templates fall into three
categories:

- **Already-exampled by the recent slice**
  (`ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE`):
  cross-domain repeat-body do, four activation-override sub-axes,
  loop-contained, deeper-nested. **7 templates exampled in 13b/13d.**
- **Exampled prior to this audit** in `13h-lowering-reference.md`
  or `13b-transactions.md`: several `requires same-body (await_all
  done) drain` variants from the missing-drain matrix. (Verification
  by direct chapter inspection is recommended; the audit did not
  exhaustively cross-reference each variant.)
- **No book example confirmed**:
    * 5 `package constant aggregate/member path remains deferred`
      templates (activation override, actor default, transaction
      default, data-op width, contract window, repeat count, wait
      count, latency, watchdog limit — really one repeated form
      across 9 contexts). The book mentions "unqualified package
      constants, aggregate package constants, and package member/
      item paths remain fail-closed" but does not show a
      `(package.NAME.x)` shape that triggers the rejection.
    * 4 `two-child data route remains deferred` templates. Two-child
      data routes appear in `13g` and `13f` prose but not in a
      worked rejected-shape example.
    * 4 `await_any after the (later) do/spawn remains deferred`
      templates. Mentioned in the repeat-body section of `13b` but
      no rejected example.

**Recommended slice**: extend the diagnostic-example coverage to
these three sub-families. Each is a 3-5 line `.fsm` fragment.

### G4. Backlog status accuracy

`14-feature-backlog.md` has 43 `Status:` markers:

- 28 `shipped` (with variants like "shipped for X subset")
- 30 `backlog`
- 13 `deferred` / `partially shipped`

The recent diagnostic-precision slices updated the backlog text but
the audit did not spot-check every "shipped" claim against current
validator behavior. Two areas warrant a focused review:

- **Spawn Inside Repeat Bodies** (line 539+): a very large
  multi-paragraph section. The recent precision slices added
  diagnostic phrases but the "shipped subset" enumeration is dense
  and may have drifted as new sub-cases shipped.
- **Temporal Contract Lowering** (line 2812): claims a shipped
  bounded eventually subset; the contract-window activation-override
  gate shipped before this session.

**Recommended slice**: a focused truth-sync slice (similar in shape
to the recent `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-DIAGNOSTIC-TRUTH-SYNC`)
that walks each `Status:` marker against a small set of probe
fixtures and updates any drifted text.

### G5. Chapter 13 (ISF intro) reads prose-heavy

`13-intent-scheduling.md` (1055 lines, 4 examples) sets the tone for
the ISF section. A new reader meets the chapter with sparse code.
The chapter could carry 8-12 short examples interspersed with the
prose without expanding much in length.

**Recommended slice**: insert 6-8 short examples covering the
"happy path" walking from actor declaration through generated
composition. Each fragment 5-10 lines.

### G6. `13j-type-enum-aggregate.md` light on examples

6 examples for type aliases, enums, and aggregates is light for a
feature surface that includes: scalar type aliases, package-imported
type aliases, enum members, aggregate literals, aggregate parameter
defaults, aggregate spawn override values, generated-top aggregate
binding, and enum-member resolution in spawn/do/trigger overrides.

**Recommended slice**: add 4-6 focused examples covering each axis
above. Each fragment is small (an enum/type declaration plus its
use site).

### G7. `13d-control-flow.md` light for the control-flow surface

`13d` covers `when`, `switch`, `repeat`, `while`, `until`, `do`,
`spawn`. Only 12 examples (two of which I just added). The chapter
should illustrate:

- `when` with a single condition and with a nested condition.
- `switch` with `(case N body)` and `(default body)`.
- `repeat` with literal count, with parameter count, and with
  dynamic count.
- `while` and `until` with cond + body.
- `(do child)` plain, with `(params ...)`, with `(bind ...)`, with
  `(domain ...)`.
- `(spawn child as inst)` plain, with `(params ...)`, with `(bind
  ...)`, with `(domain ...)`.

Many of these accept-path variants currently have at most one
example in the chapter.

**Recommended slice**: extend `13d` with 6-10 short examples
covering the variants above. Pair each shipped accept variant with
its corresponding fail-closed sibling.

### G8. Headings density and cross-references

Several chapters have low heading density (e.g., `13-intent-scheduling.md`
has 5 headings for 1055 lines; `13c-drive-blocks.md` has 5 headings
for 143 lines). Headings serve as navigational anchors. A reader
trying to find "how does FSMGen handle the bind handoff for a
generated child?" should be able to find a heading naming that
exact topic.

**Recommended slice**: a docs-structure pass that introduces
sub-headings every ~150-200 lines of prose. Pure structural; no
content changes.

## Counts that did not change in this session

| Surface | Before audit | After audit |
| --- | --- | --- |
| ISF book chapter line totals | 21300 | 21300 (audit is read-only) |
| Validator `confess` sites (lowerer) | 446 | 446 |
| Book code examples (13*.md) | 252 (sum of column above) | 252 (audit is read-only) |
| Book code examples (recent +5 + 2 from prior slice) | included above | included above |

## Recommended slice queue (priority order)

The user's framing — "documentation as important as code" —
suggests the queue should privilege coverage **breadth** before
chapter polish. Recommended order:

1. **G1: Cookbook ISF recipes** — biggest perceived gap for new
   users. One slice, +200-300 book lines, no code changes.
2. **G3: Remaining `remains deferred` examples** — extends the
   coverage pattern just shipped to its full validator backlog.
   Three sub-slices (package-constant aggregate, two-child data
   route, repeat-body `await_any` after do/spawn).
3. **G7: `13d-control-flow.md` accept-path examples** — closes
   the biggest accept-path coverage gap. One slice, +100-150 book
   lines.
4. **G2: Low-density clause families** — split per family
   (`(contract ...)`, `(store/load ...)`, `(stage ...)`,
   `(types ...)`, `(ports ...)`, `(constants ...)`,
   `(extract ...)`, `(assemble ...)`). 6-8 small slices, each
   +30-80 book lines.
5. **G6: `13j-type-enum-aggregate.md` examples** — closes the
   type/enum/aggregate gap. One slice, +60-100 book lines.
6. **G5: `13-intent-scheduling.md` happy-path examples** —
   improves new-reader onboarding. One slice, +50-80 book lines.
7. **G4: Backlog status truth-sync** — one focused slice using
   the existing TRUTH-SYNC pattern.
8. **G8: Heading density and cross-references** — pure
   structural polish. One slice, no content changes.

Each numbered item maps to one new task tree following the
two-commit `.1 select` / `.2 ship` pattern, so the queue lands as
~10-12 commits over the next session.

## Caveats

- This audit is a one-shot snapshot. The `confess`-site counts and
  keyword frequencies are accurate as of `2026-05-27`. Any future
  slice that adds or removes diagnostics will drift the counts.
- Mention frequency is a heuristic, not proof of explanation
  quality. A keyword can appear many times in prose without being
  shown in a working example.
- "Audit-clean" tests (`t/1305`, `t/1307`, `t/1332`) verify a
  specific consistency invariant between docs surfaces but they do
  not enforce example density. None of the recommendations above
  would be caught by the existing audit tests.
- The audit deliberately stops at the ISF surface. The non-ISF
  chapters (`01`–`12`) are out of scope for this slice; a separate
  audit could extend coverage to those chapters if useful.

## Next action

Per the user's instruction (audit only), no slice is automatically
shipped from this report. The user reviews the recommended queue and
selects the next slice to start as a new task tree.

## Addendum — example correctness audit (2026-05-29)

After the cookbook ISF recipes (G1) shipped, the user added a
stricter requirement: every `.isf` example in the book must lower
cleanly to FSM, and every example must be thoroughly explained. A
follow-up audit extracted every `lisp` code block from
`12-cookbook.md`, `13*.md`, and `14-feature-backlog.md` and
attempted to parse each via `FSM::Adapter::ISF` and lower it via
`FSM::Scheduler::ISF`.

Results (275 lisp blocks scanned):

| Category | Count |
| --- | --- |
| Fragments (don't start with `(actor`) | 243 |
| Complete fixtures that lower cleanly | 17 |
| Complete-looking fixtures that fail parse | 14 |
| Complete-looking fixtures that parse but fail lower | 1 |

Failure categorization (likely cause):

| Cause | Count | Disposition |
| --- | --- | --- |
| Ellipsis `...)` masquerading as a complete actor | 8 | **Fix needed** — either expand or strip the `(actor ...)` framing |
| External library reference (`(imports (library ...))`) | 3 | **Fix needed** — embed the library, annotate as multi-file, or use a non-lisp block |
| External package import (`(imports (package ...))`) | 1 | **Fix needed** — embed the package or annotate |
| Multiple `(actor ...)` roots in one block | 1 | **Fix needed** — split into separate blocks |
| Intentional fail-closed illustration (drive arity) | 1 | **Keep** — it documents the validator constraint |
| Real broken example (`setup_phase` not defined) | 1 | **Fix needed** — supply the missing drive |

Specific issues (15 total):

1. `docs/book/src/13-intent-scheduling.md` block #1 — `apb_transfer`
   transaction's `drive 'setup_phase'` is not defined. Real bug.
2. `docs/book/src/13-intent-scheduling.md` block #4 — package
   import without embedded package source.
3. `docs/book/src/13a-actor-interface.md` block #1 — ellipsis
   shorthand at end of actor body.
4. `docs/book/src/13a-actor-interface.md` block #11 — ellipsis
   shorthand.
5. `docs/book/src/13c-drive-blocks.md` block #12 — ellipsis
   shorthand.
6. `docs/book/src/13f-composition.md` block #11 — library import
   (`common.fifo`).
7. `docs/book/src/13f-composition.md` block #23 — library import
   (`common.packet`).
8. `docs/book/src/13h-lowering-reference.md` block #1 — interface
   port placeholder uses scalar.
9. `docs/book/src/13h-lowering-reference.md` block #3 — ellipsis
   shorthand.
10. `docs/book/src/13j-type-enum-aggregate.md` block #1 — ellipsis
    shorthand.
11. `docs/book/src/13j-type-enum-aggregate.md` block #2 — ellipsis
    shorthand.
12. `docs/book/src/14-feature-backlog.md` block #2 — drive arity
    violation. Intentional illustration; keep.
13. `docs/book/src/14-feature-backlog.md` block #7 — library
    import.
14. `docs/book/src/14-feature-backlog.md` block #8 — multiple
    actors in one block.
15. `docs/book/src/14-feature-backlog.md` block #9 — ellipsis
    shorthand.

Recommended remediation slice (a new task tree
`ISF-BOOK-EXAMPLE-CORRECTNESS-FIX`):

- For each ellipsis case (8 blocks): either expand the example to a
  complete actor or convert the block to a non-`lisp` text block
  (e.g., \`\`\`text) so it does not advertise itself as a parseable
  fixture. The choice depends on whether the block aims to teach a
  syntactic shape (text) or a complete construct (expand).
- For each multi-file case (4 blocks total — library/package/multi-
  actor): either embed the supporting fixture inside the same block
  using a `;; ---` separator, or convert the block to `text` with a
  one-line lead-in naming the missing piece.
- For the one real bug at `13-intent-scheduling.md` block #1: add
  the missing `(drive setup_phase ...)` clause or rework the
  example so it parses standalone.
- For the intentional fail-closed illustration at
  `14-feature-backlog.md` block #2: leave as-is and add a one-line
  comment marker so future audits skip it.

This addendum is itself doc-only. The remediation slice will own
the actual fixes through `COMMIT.md`.
