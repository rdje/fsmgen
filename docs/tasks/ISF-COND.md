# ISF-COND: `(cond …)` If / Else-If / Else Priority Chain

## Metadata

- Tree ID: `ISF-COND`
- Status: `done` (closed `2026-06-01`)
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
  Status: `done`
  Goal: `(cond …) if/else-if/else priority chain — parser desugar to a negated-guard when-chain.`
  Children: `.1` (select + target validation), `.2` (desugar + tests + docs)

- ID: `ISF-COND.1`
  Status: `done`
  Goal: `Select; validate the negated-guard when-chain target (priority) by simulation.`
  Acceptance: `Task tree committed before code; hand-written chain simulates correct priority.`
  Verification: `verilator --binary: (when c1 …)(when (& (! c1) c2) …)(when (& (! c1)(! c2)) …) -> first true branch wins; mdbook build; git diff --check`
  Commit: `this slice`

- ID: `ISF-COND.2`
  Status: `done`
  Goal: `(cond …) parser desugar to the negated-guard when-chain + tests + docs.`
  Acceptance: `_expand_cond_loops runs before for/let/proc expansion; (cond (c1 b1)…(else bn)) desugars to (when c1 b1)(when (& (! c1) c2) b2)…(when (& (! c1)(! c2)…) elseBody) via _desugar_cond + _cond_and_guard (left-nested &); the first true branch runs and the else runs when none do (simulation-confirmed priority). Expression conditions and a no-else chain lower; a nested (cond …) in a branch expands; else-not-last, an empty branch body (trailing-undef filtered), and a non-list branch fail closed with clear diagnostics. 13d gains a (cond …) section; 13k row lists it; ISF_SPEC registers t/1396.`
  Verification: `(cond (c1 …)(c2 …)(else …)) lowers to ?c1 / ?(& (! c1) c2) / ?(& (! c1)(! c2)); verilator --binary: c1=1->r1, c1=1&c2=1->r1, c1=0&c2=1->r2, c1=0&c2=0->r3 (priority correct). Expr conds, no-else, nested cond lower; else-not-last/empty-body/non-list fail closed. prove -Iperl t/1396 (4 subtests) + doc gates PASS; full suite PASS; perl -c; mdbook build; git diff --check.`
  Commit: `this slice`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Select; target (negated-guard when-chain) validated by simulation (priority correct). |
| 2 | `.2` | `done` | `(cond …)` desugar + tests + docs. Simulation-confirmed priority. **Tree complete.** |

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
| `2026-06-01` | `.2` | `(cond (c1 …)(c2 …)(else …))` lowers to `?c1` / `?(& (! c1) c2)` / `?(& (! c1)(! c2))`; `verilator --binary` → c1=1→r1, c1=1&c2=1→r1, c1=0&c2=1→r2, c1=0&c2=0→r3 (priority); expr-conds / no-else / nested cond lower; else-not-last / empty-body / non-list fail closed. `prove -Iperl t/1396` (4 subtests) + doc gates PASS; full suite PASS; `perl -c`; `mdbook build`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ISF-COND.1: select (cond …) if/else-if/else priority chain` | `1c7f8b9c` |
| `.2` | `ISF-COND.2: (cond …) desugar to a negated-guard when-chain` | this slice |

## Changelog

- `2026-06-01`: Created — `(cond …)` if/else-if/else priority chain, a pure ISF parser
  desugar to a `when`-chain with accumulated negated guards. Target (priority correctness)
  validated by simulation. `.2` lands the desugar + tests + docs.
- `2026-06-01`: `.2` shipped — **tree complete**. `_expand_cond_loops` runs in
  `_build_actor` before the for/let/proc passes; `_desugar_cond` turns each branch into a
  `(when GUARD body…)`, accumulating `(! ci)` guards (left-nested `&` via `_cond_and_guard`)
  so the first true branch wins and the `else` runs only when none did. Verified by
  simulation (verilator `--binary`): `(cond (c1 …)(c2 …)(else …))` gives `c1`-priority
  (`c1=1&c2=1 → r1`), `c2` when `c1` is false, and the `else` when both are false. Expression
  conditions, a no-`else` chain, and a nested `(cond …)` all lower; `else`-not-last, an empty
  branch body (the trailing-undef quirk is filtered), and a non-list branch fail closed with
  clear diagnostics. `t/1396`; `13d` gains a `(cond …)` section; the `13k` control-flow row
  lists it; `docs/ISF_SPEC.md` registers `t/1396`. The conditions are evaluated across the
  multi-cycle `when`-chain, so they must be stable while it runs (sample volatile inputs
  first), matching `when`/`switch`.
