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
- define one bounded multi-FSM shared-datapath composition lane instead of reopening broad implicit composition:
  - one `fsmgen` run may build one top from one `.fsm` source or from several `.fsm` sources,
  - some child outputs remain directly owned by their source FSMs,
  - outputs assigned in at least two child FSMs are the shared-datapath candidates and may be lifted into one shared datapath block instantiated by the generated top,
  - outputs assigned in only one child FSM are not shared and should remain directly child-owned,
  - outputs produced by the child FSMs or by the shared datapath block are top-level outputs by default,
  - if a registered output is read on the RHS by another child FSM, that signal should become top-internal by default instead of auto-exported,
  - if such a now-internal registered signal must also appear as a top-level output, the user should request that export explicitly,
  - that shared block owns the mux/register logic for those lifted targets and receives deterministic per-child drive-intent enables such as `A_P_Q_en`, `B_P_Q_en`, and aggregate enables such as `P_Q_en`,
  - lifted registered/shared outputs may be looped back into child FSM inputs and may be either top-local or top-exposed,
  - combinational outputs, whether shared or not, must not become cross-FSM read sources and should only exist as top-level outputs,
  - same-target/same-value aggregation should remain distinct from same-target/different-value conflicts,
  - the default shared-drive contract should surface conflict/assertion bits rather than auto-resolve or auto-prioritize,
  - per `(P, Q)` families should support onehot0-style checks over source enables such as `A_P_Q_en`, `B_P_Q_en`, and `C_P_Q_en`,
  - and per-target `P` families should support assertion bits that detect more than one value-family enable being active in the same cycle,
- define one bounded reusable standalone-DT/module-library lane instead of reopening broad implicit hierarchy:
  - add `?dt:name` as the smallest standalone module description,
  - let `?dt:name` contain any number of internal general DT blocks such as `(-foo ...)`,
  - `?dt:name` may mix combinational outputs such as `(P = RHS)` and sequential outputs such as `(Q <- QRHS)` in the same standalone DT module,
  - the semantic split from `?fsm:name` is the control model, not “combinational only” versus “sequential allowed”,
  - `?fsm:name` should implicitly declare `clk` / `rst_n`,
  - `?dt:name` should implicitly declare `clk` / `rst_n` only when at least one sequential assignment exists in that standalone DT module,
  - `?top:name` and sequential `?dt:name` should keep `rst_n` as the default async-reset convention even if the current explicit `?fsm` `+system` compatibility residue still spells `rstn`,
  - output-driving semantics inside `?dt:name` should stay aligned with the current DT handling inside `?fsm:name`,
  - multiple internal `(-foo ...)` blocks in the same `?dt:name` may assign the same target without being rejected structurally,
  - but the generated enable families must still support mutual-exclusion assertions so arbitration stays explicit,
  - keep `?top:name` as the explicit composition-root concept unless a later family-level root-syntax decision adds aliases such as `?mod:name` or `?module:name`,
  - let reusable `.fsm` module roots be located through existing `FSMLIB`-style search roots plus explicit per-invocation CLI search roots,
  - and prefer repeatable `--path DIR` search-root options over comma-packed path lists so lookup stays deterministic and shell-friendly,
- and harden mixed `?fsmc` / `?rtl` flows before adding broader composition syntax.

First shipped `R11` slice now in tree:
- `?dt:name` is now an active standalone-module root in the live toolchain.
- The `.rtlif` mini-contract is now explicit enough to build on:
  - one flat `(?rtlif:module_name ...)` root,
  - embedded same-file `(?rtlif:module_name ...)` companion roots taking precedence over sidecar metadata when present,
  - declaration-ordered port tokens,
  - compact tokens such as `clk`, `data_in<8`, and `txd>`,
  - typed tokens such as `core_clk:clock`, `rst_async_n:reset`, and `data_in<8:data`,
  - explicit type annotations currently limited to `data`, `clock`, and `reset`,
  - typed `clock` / `reset` metadata now enabling honest auto-wiring of custom-named RTL system ports in the shipped mixed-composition lane,
  - mixed composition no longer requiring a separate sidecar file when the external RTL interface contract is embedded in the composition source itself,
  - single-child composition now also covering a lone `?rtl` child across passthrough, explicit-link, and declared by-name lanes,
  - and explicit-link composition now also covering any explicit-link top with at least one `?rtl` child, including multiple generated children beside those RTL children.
- The shipped first slice currently supports:
  - top-level general DT blocks such as `(-foo ...)`,
  - directive sections `(+size ...)`, `(+constants ...)`, `(+enums ...)`, `(+define ...)`, and `(+params ...)`,
  - compact top-level `(:= signal=value)` directives,
  - implicit `clk` / `rst_n` only when the `?dt:name` source contains sequential assignments,
  - default output exposure for driven non-intermediate targets,
  - repeatable `--path DIR` search roots for bare `.fsm` input lookup,
  - the same explicit search roots feeding current `.rtlif` metadata lookup ahead of `FSMLIB`,
  - external `?fsmc` composition child sources resolved from sibling or searched `.fsm` files without leaving the active typed pipeline,
  - `?dtc` composition child realization from embedded or external standalone-DT sources, including honest non-system interfaces for purely combinational DT children,
  - single-generated-child declared connect-by-name through `=name` for both `?fsmc` and `?dtc` children,
  - one or more external `?rtl` children plus mixed one-generated-child plus one-or-more-`?rtl` children under declared connect-by-name when the top-level exact-match rule is still unambiguous,
  - and standalone-DT child interface direction now preferring semantic signal roles over the older name-based output heuristic in composition-facing interface realization.
- The shipped first slice does not yet widen into:
  - explicit `+system` inside `?dt:name`,
  - regular FSM-state blocks inside `?dt:name`,
  - broader reusable-module interface/export rules,
  - or alias-root questions.

Expected result:
- composition remains explicit and serious instead of drifting back toward legacy implicit behavior.

Planned bounded sub-lane inside `R11`:
- shared datapath extraction for multi-FSM tops.
- intent:
  - keep FSM children as controllers,
  - keep singly-owned outputs in their owning child FSMs,
  - and let only multiply-assigned shared/register-bearing targets move into one common datapath block.
- first contract questions to settle:
  - how multiply-assigned lifted targets are declared and detected,
  - which RHS/value sources must also be surfaced to the shared datapath block,
  - how per-child drive intents are named and reported,
  - how same-target/same-value aggregation differs from same-target/different-value conflicts,
  - how conflict/assertion bits are expressed and named for per-`(P, Q)` source-enable families and for whole-target `P` value-family conflicts,
  - which registered outputs should internalize automatically when peer-read,
  - how users explicitly re-export those now-internal registered signals when wanted,
  - and which lifted registered outputs may legally loop back into child FSM inputs.
- reusable standalone-DT/module-library roots.
- intent:
  - treat `?dt:name` as the smallest reusable standalone module form,
  - allow one `?dt:name` source to contain any number of internal general DT blocks such as `(-foo ...)`,
  - allow that standalone DT module form to mix combinational and sequential outputs freely,
  - keep `?fsm:name` on implicit `clk` / `rst_n` by default,
  - let `?dt:name` acquire implicit `clk` / `rst_n` only when a sequential assignment exists,
  - keep the output-driving semantics inside `?dt:name` aligned with existing DT handling instead of inventing a separate conflict model,
  - keep `?top:name` as the explicit composition root while leaving `?mod:name` / `?module:name` as an open family-level naming question rather than an ad hoc replacement,
  - and extend reusable-source lookup through existing `FSMLIB` semantics plus repeatable `--path DIR` CLI roots.
- first contract questions to settle:
  - what the exact source-root family becomes: `?fsm:name`, `?dt:name`, `?top:name`, and whether `?mod:name` / `?module:name` are aliases or distinct roots,
  - whether unnamed reusable DT roots such as `?dt:` should exist at all or remain deferred,
  - how standalone DT interfaces are declared/exposed,
  - how block-level and module-level enable families are surfaced so same-target arbitration stays explicit without structural over-rejection,
  - how lookup precedence works between explicit paths, `--path` roots, `FSMLIB`, and local files,
  - how duplicate-name shadowing is diagnosed,
  - and how reusable DT/module roots are referenced from other `.fsm` sources without drifting back into legacy implicit behavior.

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
