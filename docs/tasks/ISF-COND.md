# ISF-COND: `(cond …)` If / Else-If / Else Priority Chain

## Metadata

- Tree ID: `ISF-COND`
- Status: `active`
- Roadmap lane: `R14` (ISF — high-level language richness)
- Created: `2026-06-01`
- Last updated: `2026-06-01`
- Owner: repo-local workflow

## Goal

`(cond (c1 body1…) (c2 body2…) … (else bodyN…))` — the **if / else-if / else** priority
chain a high-level language has. The first branch whose condition holds runs (and only it);
the optional `else` runs when no condition held. Cleaner than hand-nesting `when` (which has
no `else`).

```lisp
(cond
  ((== mode 0) (update out a))
  ((== mode 1) (update out b))
  (else        (update out c)))
```

## Ground truth (target validated by simulation, 2026-06-01)

`(cond …)` is a pure ISF (IAL1) parser desugar into a `when`-chain with **accumulated
negated guards**, so branch `i` runs only when `ci` holds and no earlier condition did:

```lisp
(when c1 body1…)
(when (& (! c1) c2) body2…)
(when (& (! c1) (! c2)) bodyN…)   ;; the else branch
```

A hand-written chain of this shape simulated with correct priority: `c1` wins over `c2`
when both hold; the `else` runs only when all conditions are false. `when` accepts the
expression guards, and `&`/`!` are shipped operators.

## Design

- Parser pass `_expand_cond_loops` runs in `_build_actor` **before** `_expand_for_loops` /
  `_expand_let_bindings` / `_expand_procedure_calls`, so the generated `when` bodies (and any
  `for`/`let`/`call` inside them) are expanded by those later passes.
- `_desugar_cond` walks the branches, accumulating `(! ci)` guards; each branch becomes a
  `(when GUARD body…)` whose guard is the left-nested `&` of all prior negations and (for a
  non-else branch) the branch condition. `else` (last only) gets the all-negated guard.
- The pass recurses into body-bearing forms (`when`/`switch`/`while`/`until`/`repeat`/`for`
  bodies and `cond` branches) so a nested `(cond …)` anywhere is expanded. Because the
  desugar emits `(when …)` clauses (valid wherever `cond` appeared), no hoisting is needed.

## Slice plan

- `.1` select (this doc) + target validated by simulation.
- `.2` `(cond …)` desugar: the parser pass + `when`-chain; priority verified by simulation;
  `else`-not-last / empty-branch / empty-body fail closed; `t/`; docs (13d section, 13k row).

## Non-Goals

- A single-cycle combinational `cond` (the `when`-chain is multi-cycle; conditions are
  assumed stable across evaluation — sample volatile inputs first, as for `when`/`switch`).
- A value-returning `(cond …)` expression (this is a statement-level control chain).

## Acceptance Criteria

- A top-level or nested `(cond …)` lowers to a priority `when`-chain — the first true branch
  runs, the `else` runs when none do — proven by simulation; `else` must be last and every
  branch needs a condition (or `else`) and a non-empty body, else fail closed; 13d documents
  it with a runnable example; audits pass. Each leaf committed via `COMMIT.md`.

## Task Tree

- ID: `ISF-COND`
  Status: `active`
  Goal: `(cond …) if/else-if/else priority chain — parser desugar to a negated-guard when-chain.`
  Children: `.1` (select + target validation), `.2` (desugar + tests + docs)

- ID: `ISF-COND.1`
  Status: `done`
  Goal: `Select; validate the negated-guard when-chain target (priority) by simulation.`
  Acceptance: `Task tree committed before code; hand-written chain simulates correct priority.`
  Verification: `verilator --binary: (when c1 …)(when (& (! c1) c2) …)(when (& (! c1)(! c2)) …) -> first true branch wins; mdbook build; git diff --check`
  Commit: `this slice`

- ID: `ISF-COND.2`
  Status: `todo`
  Goal: `(cond …) parser desugar to the negated-guard when-chain + tests + docs.`
  Acceptance: `(cond (c1 b1)…(else bn)) lowers to the priority when-chain; first true branch runs, else when none; nested cond expands; else-not-last / missing condition / empty body fail closed; simulation confirms priority. 13d section + 13k row; ISF_SPEC registers t/.`
  Verification: `Spike + t/; full isf regression; perl -c; mdbook build; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Select; target (negated-guard when-chain) validated by simulation (priority correct). |
| 2 | `.2` | `todo` | `(cond …)` desugar + tests + docs. |

## Decisions

- `2026-06-01`: implement as a pure ISF parser desugar to a `when`-chain with accumulated
  negated guards (priority if/else-if/else). Runs before for/let/proc expansion so the
  generated `when` bodies are further expanded. No new lowerer machinery.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-01` | `.1` | verilator `--binary`: negated-guard `when`-chain → first-true-branch priority (c1>c2; else when none); `mdbook build`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ISF-COND.1: select (cond …) if/else-if/else priority chain` | this slice |

## Changelog

- `2026-06-01`: Created — `(cond …)` if/else-if/else priority chain, a pure ISF parser
  desugar to a `when`-chain with accumulated negated guards. Target (priority correctness)
  validated by simulation. `.2` lands the desugar + tests + docs.
