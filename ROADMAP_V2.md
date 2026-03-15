# FSMGen Roadmap v2

This is the detailed companion to [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md).

Use this file for:
- the detailed post-`R0`..`R7` roadmap shape,
- sequencing and dependency rationale,
- and the concrete intent behind the active `R8+` workstreams.

Use [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) for:
- the canonical live status,
- current active lane,
- and done/left tracking.

## Why roadmap v2 exists
`R0` through `R7` closed the first major modernization roadmap:
- live roadmap tracking,
- `FlattenedDT` cleanup,
- synthesis ownership migration,
- AST/CoreAST-first convergence,
- assignment semantics modernization,
- generator reuse safety,
- scoped composition,
- and typed extension replacement.

The remaining work is no longer “finish the refactor.”
It is “turn the modernized tool into a stricter, more explicit, more trustworthy language/tool contract.”

That is what roadmap v2 is for.

## v2 principles
- Prefer explicit language contracts over implicit parser acceptance.
- Distinguish “implemented” from “supported”.
- Make diagnostics part of the product, not just a debugging aid.
- Grow surface area only when semantics are crisp and regression-backed.
- Keep composition and extension growth deliberate rather than legacy-compatible by default.

## Workstreams
### R8. Language-contract hardening
Goal:
- turn the current supported-language boundary into a normative contract.

Why first:
- this is the highest-value gap between a capable tool and a serious tool.

Deliverable themes:
- one normative `.fsm` language reference,
- one clear support-tier model,
- one explicit bucket for every parser-visible construct:
  - fully supported,
  - intentionally experimental/deferred,
  - or explicitly rejected.

Initial sub-slices:
1. Promote the already-agreed semantics for:
   - guarded blocks,
   - condition suffixes,
   - update shorthand,
   - and operator-arity rules
   from engineering notes into a normative reference.
2. Resolve the remaining gray-zone families:
   - `(+system ...)` beyond conventional `clk` / `rstn`,
   - `(+constants ...)`, `(+enums ...)`, `(+define ...)`, `(+params ...)`,
   - any remaining parser-accepted legacy constructs not yet classified clearly.
3. Add focused per-family regression coverage so support claims become provable.

Expected result:
- the active language boundary becomes crisp enough that strict mode can be built on top of it cleanly.

### R9. Strict mode and support-tier enforcement
Goal:
- let users choose “only the supported language” explicitly.

Deliverable themes:
- a strict mode in the CLI/pipeline,
- targeted errors for constructs outside the fully supported tier,
- and workflow guidance on when to use strict mode.

Expected result:
- production users can choose predictability over compatibility residue.

### R10. Source provenance and diagnostics
Goal:
- make parser/generator failures precise, actionable, and source-local.

Deliverable themes:
- file/line/construct provenance through parsing and generation,
- targeted errors instead of generic fallthrough failures,
- and clearer remediation guidance in diagnostics.

Expected result:
- large `.fsm` files become much easier to debug and review.

### R11. Composition contract strengthening
Goal:
- deepen the shipped `R6` composition model without widening it carelessly.

Deliverable themes:
- formalize the `.rtlif` mini-contract,
- decide whether a stronger interface-source contract should later replace or sit above `.rtlif`,
- and harden mixed `?fsmc` / `?rtl` flows before adding broader composition syntax.

Expected result:
- composition remains explicit and serious instead of drifting back toward legacy implicit behavior.

### R12. Regression corpus and support accounting
Goal:
- make support claims measurable and continuously checked.

Deliverable themes:
- curate a representative `.fsm` corpus,
- classify each case as supported / expected-failure / legacy-out-of-scope,
- and add golden outputs or semantic checks where appropriate.

Expected result:
- support claims stop being conversational and become auditable.

### R13. Public embedding/API stabilization
Goal:
- make FSMGen intentionally embeddable as a library/tooling component.

Deliverable themes:
- stabilize the `HDLGenerator` result contract,
- document the typed extension/context contract at an embedding level,
- and consider a more explicit serializable plan/report boundary where useful.

Expected result:
- the project becomes a stronger platform for downstream tooling, not just a CLI.

### R14. VHDL backend, if still wanted
Goal:
- implement a real VHDL backend only after the language contract is solid enough to support a second backend honestly.

Deliverable themes:
- define the VHDL backend scope,
- implement the single-FSM lane first,
- then decide whether composition-top VHDL generation is still desirable.

Expected result:
- VHDL becomes a deliberate second backend, not a speculative unfinished promise.

## Sequencing
Recommended order:
1. `R8`
2. `R9`
3. `R10`
4. `R11`
5. `R12`
6. `R13`
7. `R14`

Dependency logic:
- `R9` depends on `R8`, because strict mode needs a crisp language contract.
- `R10` benefits from `R8`, because better diagnostics depend on knowing the intended construct boundary.
- `R11` should follow `R8`, because composition should grow against a stable language core.
- `R12` should start as soon as `R8` classifications harden, because the corpus is how those claims stay honest.
- `R14` should come last, because a second backend multiplies ambiguity if the language contract is still gray.

## Long-term horizon (not active workstreams yet)
These are intentional long-term goals, but they are not near-term roadmap lanes.

Gating rule:
- first make FSMGen state-of-the-art,
- rock solid,
- and really stable
through the `R8`..`R13` contract-hardening and product-hardening work.

Only then should the project seriously widen its long-term ambition into these horizon goals.

### H1. Rust FSMGen
Long-term goal:
- create a Rust implementation of FSMGen.

Intent:
- carry the mature language/tool contract into a stronger long-term systems implementation,
- not to re-open the language-design phase in a second implementation prematurely.

Prerequisite:
- the language contract, diagnostics contract, support accounting, and embedding surface must already be stable enough that a Rust implementation is an execution project, not a moving-target rewrite.

### H2. Public project website
Long-term goal:
- create a very nice, beautiful, and dynamic public website for FSMGen so other people can discover and use the project.

Intent:
- publish the project professionally once the tool is strong enough to represent publicly with confidence,
- with a site that highlights:
  - the language,
  - the generated HDL model,
  - examples,
  - documentation,
  - and why the tool is worth adopting.

Prerequisite:
- the tool itself should first be strong enough that the website is amplifying a genuinely trustworthy product rather than compensating for an unstable one.

## Current intent
The active immediate lane is `R8`.

The first honest `R8` slices are:
1. extend the new draft normative language-reference slice beyond the now-locked guard/update/operator/symbol/system families,
2. audit any remaining non-directive parser-visible legacy constructs that still lack a clean support-tier bucket,
3. keep adding focused regressions that lock the adopted language contract family by family.
