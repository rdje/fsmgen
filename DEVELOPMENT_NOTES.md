# DEVELOPMENT_NOTES
This document captures engineering rationale, design constraints, and working decisions behind recent FSMGen behavior.
## 2026-03-16: malformed `:=` directive shapes now have explicit end-to-end coverage
- The active top-level `:=` family was already covered for:
  - supported compact directives like `(:= signal=value)`,
  - malformed compact directives like `(:= BROKEN)` at parser level,
  - and malformed RHS values like `(:= tester_reset=<start)` across parser, pipeline, and CLI.
- The remaining gap was malformed payload shape, where non-scalar forms like `(:= (tester_reset=1 extra))` were rejected by the parser but not called out as their own regression-backed boundary.
- [t/81-language-contract-init-directive-shape-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/81-language-contract-init-directive-shape-boundary.t) now locks:
  - malformed non-scalar `:=` payloads through parser, pipeline, and CLI,
  - and malformed compact directives like `(:= BROKEN)` through pipeline and CLI too.
## 2026-03-16: reset naming now distinguishes current `?fsm` compatibility residue from future/default convention
- The wording around reset naming needed one more distinction:
  - current shipped explicit `(?fsm:name ... (+system ...))` compatibility residue still accepts `rstn`,
  - but that does not define the forward/default async-reset convention.
- Saved direction:
  - implicit no-`+system` generation stays on `rst_n`,
  - planned `?top:name` defaults should also stay on `rst_n`,
  - planned sequential `?dt:name` defaults should also stay on `rst_n`,
  - and the explicit `rstn` spelling should be treated as current shipped compatibility residue rather than as the preferred async-reset name going forward.
## 2026-03-16: non-conventional `+system` reset names are now locked explicitly too
- The conventional `+system` family was already covered for:
  - bad clock names,
  - malformed entry structure,
  - unsupported directives,
  - incomplete sections,
  - and duplicate declarations.
- The remaining small gap was the reset-name side specifically:
  - `(sreset reset)`,
  - and `(asreset reset_async_n)`.
- The regression set now closes that gap too:
  - direct parser coverage now names unsupported `+system` reset names explicitly,
  - and the same malformed reset-name cases are now locked through pipeline and CLI no-output behavior,
  - so the conventional `+system` family is no longer “clock names covered, reset names only documented”.
- Wording note:
  - using `reset_n` as the rejected synchronous-reset example was misleading because `_n` implies active-low naming,
  - so the synchronous rejected example now uses `(sreset reset)` instead,
  - while the accepted `(sreset rstn)` form remains current shipped `?fsm` compatibility residue rather than a polarity-aware naming recommendation or future default.
## 2026-03-16: malformed `+system` entry structures are now locked explicitly too
- The conventional `+system` family was already covered for:
  - bad clock names,
  - unsupported directives,
  - incomplete sections,
  - and duplicate declarations.
- The remaining gray zone was malformed entry structure itself:
  - scalar payloads like `BROKEN` inside `(+system ...)`,
  - and wrong-arity entries like `(clock clk extra)`.
- The regression set now closes that gap too:
  - direct parser coverage now names malformed `+system` entry structure explicitly,
  - and the same malformed structures are now locked through pipeline and CLI no-output behavior,
  - so `+system` validation is no longer “name/directive covered, entry-structure implicit”.
## 2026-03-16: malformed symbol-definition token cases are now locked explicitly too
- The malformed symbol-definition family was already covered for empty sections and malformed entry/member shapes.
- The remaining gray zone was the token-validity side:
  - bad identifiers in `+constants`, `+define`, and `+params`,
  - and non-scalar member values in `+enums`.
- The regression set now closes that gap too:
  - direct parser coverage now names those token-validity failures explicitly,
  - and the same cases are now locked through pipeline and CLI no-output behavior,
  - so symbol-definition validation is no longer “shape-covered, token-validity implicit”.
## 2026-03-16: malformed ordinary RHS expressions are now locked across entry points too
- The malformed side of the ordinary RHS expression family was already explicit at direct parser level:
  - unsupported operators such as `(bogus B C)`,
  - malformed active-operator arity such as `(== B)`,
  - and guard-only tokens such as `<start` in ordinary expression position.
- The remaining gap was that this family did not yet have focused pipeline and CLI no-output coverage of its own.
- The regression set now closes that gap:
  - those malformed ordinary RHS expression forms are now covered through pipeline and CLI entry points too,
  - so the active expression boundary is no longer “parser-explicit, but entrypoint-implicit” on that malformed side.
## 2026-03-16: malformed symbol-definition sections are now locked across entry points too
- The malformed side of the symbol-definition family was already explicit at direct parser level:
  - `+constants`,
  - `+define`,
  - `+params`,
  - and `+enums`.
- The remaining gap was that only the `+enums` malformed side was locked through pipeline and CLI no-output behavior directly.
- The regression set now closes that gap too:
  - malformed `+constants`, `+define`, and `+params` payloads are now covered through pipeline and CLI entry points,
  - so the malformed symbol-definition family is no longer “fully end-to-end for enums, parser-only for the rest”.
## 2026-03-16: reusable-source lookup now has a first shipped `R11` slice
- The reusable-source lookup direction is no longer just roadmap wording either.
- Shipped behavior:
  - the CLI now accepts repeatable `--path DIR` search roots,
  - bare `.fsm` input lookup searches those explicit roots before `FSMLIB`,
  - and the same explicit roots now also feed `.rtlif` metadata lookup for the current external-RTL composition lane.
- The implementation uses one small shared resolver instead of duplicating root ordering again:
  - [perl/FSM/SourcePathResolver.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/SourcePathResolver.pm) now normalizes explicit roots plus `FSMLIB`,
  - [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) uses it for bare input resolution,
  - and [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) uses it for sidecar metadata lookup.
- This is still a bounded slice:
  - it improves top-level bare input lookup and current `.rtlif` lookup,
  - but it does not yet define the broader reusable-root/reference contract for future multi-source `.fsm` composition.
## 2026-03-16: first `R11` standalone `?dt:name` slice is now shipped
- The reusable standalone-DT lane is no longer just future wording. One first slice is now live in the active toolchain.
- Shipped behavior:
  - `?dt:name` is now a classified/parsing/generation root beside `?fsm:name`, `+fsm`, and `?top:name`,
  - top-level `?dt:name` content currently supports `(+size ...)`, `(+constants ...)`, `(+enums ...)`, `(+define ...)`, `(+params ...)`, compact `(:= signal=value)` directives, and general DT blocks such as `(-foo ...)`,
  - explicit `+system` remains rejected inside `?dt:name`,
  - purely combinational `?dt:name` modules expose no implicit `clk` / `rst_n`,
  - any sequential assignment inside `?dt:name` causes implicit `clk` / `rst_n`,
  - driven non-intermediate targets are exposed as module outputs by default,
  - and standalone `?dt:name` generation stays out of the encoded `current_state` / `next_state` plan.
- This is enough to treat `R11` as active implementation work rather than a pure notes lane, but the broader reuse/composition-facing interface and lookup questions remain open.
## 2026-03-16: inline compound modifiers are now explicit on both the supported and malformed sides
- The active parser had one more truth gap in the assignment family:
  - bare inline modifiers such as `(ACC <- SRC (+=))` and `(COMB = SRC (-=))` were already accepted as delta-`1` forms,
  - but malformed payloads such as `(ACC <- SRC (+= 2 3))` were being truncated silently,
  - and duplicate inline modifiers such as `(ACC <- SRC (+= 2) (-= 1))` were falling through an unrelated bare-suffix boundary.
- The active contract is now explicit instead:
  - bare inline `(+=)` / `(-=)` forms are supported delta-`1` variants,
  - malformed multi-token inline modifier payloads now fail through a dedicated inline-modifier boundary,
  - duplicate inline modifiers now fail through a targeted duplicate-modifier boundary,
  - and the malformed side is now locked through parser, pipeline, and CLI entry points too.
## 2026-03-16: future `R11` reusable-DT and shared-drive notes were refined again
- The newer `R11` brainstorming is now more precise about where structure ends and arbitration begins.
- Reusable standalone-DT direction now carries these extra rules:
  - `?dt:name` should be allowed to contain any number of internal general DT blocks such as `(-foo ...)`,
  - `?fsm:name` should always implicitly declare `clk` / `rst_n`,
  - `?dt:name` should implicitly declare `clk` / `rst_n` only when at least one sequential assignment exists inside that standalone DT module,
  - output-driving behavior inside `?dt:name` should stay aligned with current DT behavior inside `?fsm:name` rather than inventing a different assignment family.
- Conflict/arbitration direction now carries this split:
  - multiple internal `(-foo ...)` blocks in one `?dt:name` may assign the same target without being rejected structurally,
  - same-target/same-value aggregation is a different problem from same-target/different-value conflict,
  - and generated enable families should make those arbitration conditions explicit through conflict/assertion bits instead of relying on a blanket structural conflict ban.
- Multi-FSM shared-output direction now also carries the tighter conflict rule:
  - there is no need to auto-resolve or auto-prioritize those conflicts by default,
  - per-`(P, Q)` families should support onehot0-style checks over source enables such as `A_P_Q_en`, `B_P_Q_en`, and `C_P_Q_en`,
  - whole-target `P` families should support assertion bits that detect multiple value families becoming active in the same cycle,
  - naming/reporting should likely stay split between per-value-source overlap signals such as `P_Q_multi_src_conflict` and whole-target overlap signals such as `P_multi_value_conflict`,
  - and same-target/same-value aggregation remains a separate explicit aggregation case rather than being conflated with a different-value conflict by default.
## 2026-03-16: future `R11` reusable standalone-DT/module-library lane
- Captured one more concrete future `R11` direction instead of leaving it as casual brainstorming only.
- Working semantic model:
  - add `?dt:name` as the smallest standalone module description,
  - allow `?dt:name` to contain any number of internal general DT blocks such as `(-foo ...)`,
  - a standalone DT module is not restricted to pure combinational behavior,
  - it may mix combinational outputs such as `(P = RHS)` and sequential outputs such as `(Q <- QRHS)` in the same `?dt:name` source,
  - so the semantic split from `?fsm:name` is the control model, not “combinational-only” versus “sequential-capable”,
  - `?fsm:name` should implicitly declare `clk` / `rst_n`,
  - `?dt:name` should implicitly declare `clk` / `rst_n` only when at least one sequential assignment exists in that standalone DT source,
  - and output-driving behavior inside `?dt:name` should stay aligned with existing DT handling inside `?fsm:name`.
- Root-family naming discussion captured for later contract work:
  - `?top:name` still has useful meaning as an explicit composition root,
  - `?mod:name` and `?module:name` are plausible future aliases or broader root-family spellings,
  - but they should be treated as a family-level root-syntax decision rather than as an ad hoc replacement for `?top:name`.
- Reusable-source library discussion captured for later contract work:
  - reuse the existing `FSMLIB` model instead of inventing a second environment-variable scheme,
  - add repeatable per-invocation `--path DIR` roots rather than comma-packed path strings,
  - and keep lookup/precedence/diagnostics deterministic across explicit paths, `--path`, `FSMLIB`, and local files.
- Open questions intentionally preserved:
  - whether unnamed reusable DT roots such as `?dt:` should exist at all,
  - how standalone DT interfaces are declared/exposed,
  - how block-level and module-level enable families should be surfaced so multi-`(-foo ...)` arbitration stays explicit without structural over-rejection,
  - and how reusable DT/module roots are referenced without drifting back into legacy implicit behavior.
## 2026-03-16: implicit system defaults now use one module-level source of truth
- The user called out the right design rule here: common information should be defined once and referenced, not recopied into multiple emitters/planners.
- The active implementation now treats the effective system contract as module-level data:
  - if explicit conventional `+system` is present, its declared `clock` / `reset` pair remains the source of truth,
  - if `+system` is absent, the module-level implicit default is now `clk` plus asynchronous active-low `rst_n`.
- Generation paths now reference that one effective-system accessor instead of each carrying their own fallback names:
  - module declaration planning,
  - state-register generation,
  - unified flop/pulse generation,
  - and composition child-interface realization/auto-wiring.
- This keeps the intentional naming split explicit:
  - explicit conventional `+system` still uses `rstn` because that is the current supported conventional declaration,
  - implicit no-`+system` generation now uses `rst_n` because that is the requested default convention.
## 2026-03-16: duplicate `+system` declarations are now part of the explicit contract
- The active parser already rejected duplicate `+system` declarations, but that part of the conventional-system contract was not yet documented or regression-locked clearly.
- The duplicate side of the boundary is now explicit:
  - duplicate `(clock clk)` entries are rejected,
  - duplicate reset declarations are rejected,
  - and mixed `(sreset rstn)` plus `(asreset rstn)` is also treated as a duplicate reset declaration rather than as a second supported reset form.
- This keeps the `+system` contract honest as “exactly one clock declaration and exactly one reset declaration”, not just “only these names/directives are accepted”.
## 2026-03-16: future `R11` shared-datapath composition sub-lane
- Captured a concrete future `R11` composition direction instead of leaving it as informal brainstorming only.
- Intended scope:
  - one generated top may instantiate several FSM children from one `.fsm` source or from several `.fsm` sources,
  - some outputs stay directly owned by FSM A / B / C,
  - only outputs assigned in at least two child FSMs are candidates to be lifted out of the child FSMs and moved into one shared datapath block instantiated by the generated top,
  - outputs assigned in only one child FSM are not shared and should remain owned by that child FSM.
- Shared-datapath direction:
  - the shared datapath block should own the mux/register logic for lifted targets,
  - child FSMs should emit deterministic per-source drive-intent enables such as `A_P_Q_en`, `B_P_Q_en`, and `C_P_Q_en`,
  - and the top/shared block should aggregate them through shared enables such as `P_Q_en`.
- Ownership/readback rules saved for later contract work:
  - outputs produced by child FSMs or by the shared datapath block are top-level outputs by default,
  - if a registered output is read on the RHS by another FSM child, that signal should become top-internal by default,
  - if the user still wants that now-internal registered signal exposed at the top level too, that export should be requested explicitly,
  - lifted registered/shared outputs may loop back into FSM inputs,
  - but combinational outputs, whether shared or not, must not be read by peer FSMs instantiated in the same generated top,
  - so combinational outputs should remain top-level outputs only.
- Future conflict rule:
  - same-target/same-value aggregation should remain distinct from same-target/different-value conflicts,
  - there is no need to auto-resolve or auto-prioritize those conflicts by default,
  - per-`(P, Q)` source-enable families should support onehot0-style conflict/assertion bits,
  - whole-target `P` value families should support assertion bits that detect multiple active values in the same cycle,
  - and the generated enable families should make the arbitration boundary explicit instead of relying only on structural rejection.
## 2026-03-15: malformed `+system` boundaries are now locked through pipeline and CLI too
- The conventional `+system` family already had parser-level coverage in the active contract for its malformed side:
  - non-conventional clock names like `core_clk`,
  - unsupported entries like `areset`,
  - and incomplete `+system` sections.
- This slice does not change parser behavior. It makes the contract more honest across entry points:
  - those malformed forms are now locked through pipeline and CLI no-output behavior too,
  - so the malformed side of the conventional `+system` family is no longer parser-only in the regression set.
## 2026-03-15: legacy generic/template placeholder boundaries are now locked through pipeline and CLI too
- The legacy generic/template placeholder family already had parser-level coverage in the active contract:
  - placeholder selectors such as `?[READ]`,
  - repeat macros such as `?repeat:[MAX_COUNT]`,
  - and placeholder tokens such as `[DATAIN]`.
- This slice does not change parser behavior. It makes the contract more honest across entry points:
  - those out-of-support forms are now locked through pipeline and CLI no-output behavior too,
  - so the legacy generic/template placeholder family is no longer parser-only in the regression set.
## 2026-03-15: unsupported top-level `+...` directive boundaries are now locked through pipeline and CLI too
- The unsupported top-level `+...` directive family already had parser-level coverage in the active contract:
  - unknown `+` directives like `+bogus`,
  - and future-style alternatives like `+clock` that are intentionally not active yet.
- This slice does not change parser behavior. It makes the contract more honest across entry points:
  - those malformed forms are now locked through pipeline and CLI no-output behavior too,
  - so the unsupported top-level `+...` directive family is no longer parser-only in the regression set.
## 2026-03-15: malformed test-selector boundaries are now locked through pipeline and CLI too
- The malformed test-selector family already had parser-level coverage in the active contract:
  - bare symbolic selectors like `BUSY`,
  - and bare numeric selectors like `0`.
- This slice does not change parser behavior. It makes the contract more honest across entry points:
  - those malformed forms are now locked through pipeline and CLI no-output behavior too,
  - so the malformed test-selector family is no longer parser-only in the regression set.
## 2026-03-15: malformed test-branch boundaries are now locked through pipeline and CLI too
- The malformed test-branch family already had parser-level coverage in the active contract:
  - empty test branches like `(?MODE (=0))`,
  - and body-less `?sig` branches that still omit a nested action.
- This slice does not change parser behavior. It makes the contract more honest across entry points:
  - those malformed forms are now locked through pipeline and CLI no-output behavior too,
  - so the malformed test-branch family is no longer parser-only in the regression set.
## 2026-03-15: bare condition-suffix boundaries are now locked through pipeline and CLI too
- The bare condition-suffix family already had parser-level coverage in the active contract:
  - bare assignment tails like `(A <= B start)`,
  - and bare transition tails like `(-> busy full)`.
- This slice does not change parser behavior. It makes the contract more honest across entry points:
  - those malformed forms are now locked through pipeline and CLI no-output behavior too,
  - so the malformed bare-suffix family is no longer parser-only in the regression set.
## 2026-03-15: malformed action-family boundaries are now locked through pipeline and CLI too
- The malformed-action family already had parser-level coverage in the active contract:
  - single-token malformed DT actions like `(BROKEN)`,
  - and empty guarded blocks like `(<req)`.
- This slice does not change parser behavior. It makes the contract more honest across entry points:
  - those malformed forms are now locked through pipeline and CLI no-output behavior too,
  - so the malformed-action family is no longer parser-only in the regression set.
## 2026-03-15: malformed legacy `+fsm` root bodies are now regression-backed explicitly
- The previous root-body slice tightened both `?fsm:name` and `+fsm` in the parser, but only the structured `?fsm:name` side was locked directly in a focused regression.
- The active contract is now explicit on the legacy side too:
  - empty `+fsm` roots like `(+fsm plus_empty)` are rejected,
  - scalar `+fsm` body items like `(+fsm plus_scalar BROKEN)` are rejected,
  - and the already-shipped body validator is now locked through parser, pipeline, and CLI entry points for the legacy root family as well.
## 2026-03-15: malformed structured `?fsm` root bodies now fail through an explicit boundary
- After tightening bare source roots, one more source-level gap remained inside the structured `?fsm:name` family:
  - `(?fsm:empty_root)` could still decode to an `undef` body,
  - and `(?fsm:scalar_root BROKEN)` could still carry a scalar top-level body item that was skipped instead of rejected explicitly.
- The active contract is now explicit on that malformed side too:
  - structured `?fsm:name` roots must contain a non-empty list of top-level directive/state/DT items,
  - empty structured roots now fail through a dedicated body diagnostic,
  - and scalar top-level body items now fail through a dedicated body-item diagnostic.
## 2026-03-15: bare top-level FSM content now fails through an explicit source-root boundary
- One generic parser message was still left at the very top of the FSM-only entry point:
  - files that started directly with `(+system ...)` or `(idle ...)` were outside the active source-root contract,
  - but they were still failing through the old generic “expected `?fsm:name` or `+fsm`” message instead of a real construct boundary.
- The active contract is now explicit on that malformed side too:
  - supported FSM source roots remain `?fsm:module_name` and the legacy `+fsm` family,
  - supported composition roots remain `?top:top_name` through the composition pipeline,
  - bare top-level FSM content without a wrapping supported source root now fails through a dedicated source-root diagnostic.
## 2026-03-15: malformed update-shorthand tails now fail through a dedicated boundary
- After tightening update-shorthand targets, one more misleading edge remained:
  - stray extra positional payloads like `3` in `(+= counter 4 3)` were being interpreted only after expansion,
  - which meant the user saw a suffix-guard diagnostic instead of an update-shorthand-specific one.
- The active contract is now explicit on that malformed side too:
  - update shorthand still supports an optional explicit guard suffix after the optional delta,
  - valid guarded forms like `(+= counter 4 <start)` remain supported,
  - malformed extra positional tails like `(+= counter 4 3)` and `(+= counter 4 3 2)` now fail through a dedicated update-shorthand-tail boundary.
## 2026-03-15: malformed update-shorthand targets now fail through an explicit boundary
- After promoting the alternate update-shorthand spellings, one remaining parser gap became obvious:
  - recognized update-shorthand forms with malformed non-scalar targets were returning `undef`,
  - which meant those malformed actions could disappear silently from a DT body instead of failing clearly.
- The active contract is now explicit on that malformed side too:
  - update shorthand must target a scalar signal name,
  - malformed forms such as `(++ (counter))` and `(+= (byte_count) 4)` now fail through a dedicated update-shorthand boundary,
  - and the same boundary is locked through parser, pipeline, and CLI entry points.
## 2026-03-15: alternate update-shorthand spellings are now part of the active contract
- The parser already supported more update-shorthand surface than the user guide claimed:
  - `(+= sig)` / `(-= sig)` as delta-`1` forms,
  - `(+= sig N)` / `(-= sig N)` as separated delta-carrying forms.
- This `R8` slice does not widen the parser. It makes the contract truthful:
  - the live docs now include those alternate spellings,
  - focused regression coverage now locks their assignment intent, arithmetic lowering, and HDL generation,
  - and the parser comment in [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now names the same supported family the docs do.
## 2026-03-15: unsupported assignment operators now fail through an explicit boundary
- The active assignment family was already stable on the happy path, but unsupported operators like `?=` and `=>` were still leaking a raw internal parser `confess`.
- The active contract is now explicit on that malformed side too:
  - decision-tree assignments support `=`, `<-`, `<-=`, `<=`, `<=+`, and delayed-pulse forms like `<1`,
  - unsupported operators such as `?=` and `=>` now fail through a dedicated assignment-operator boundary,
  - and that same boundary is now locked through parser, pipeline, and CLI entry points.
## 2026-03-15: malformed guard shorthand and inline comparison tokens now fail through explicit boundaries
- The active shorthand/inline comparison surface was already supported, but malformed forms like `<mode=` and `cnt[2:1]!=` were still leaking generic unsupported-expression-token diagnostics.
- The active contract is now explicit on that malformed side too:
  - malformed guard shorthand payloads such as `mode=` and `==3` fail through the guard-condition boundary,
  - malformed inline comparison tokens such as `cnt[2:1]!=` and `=3` fail through the inline-comparison boundary.

## 2026-03-15: malformed delayed-pulse RHS values now fail through an explicit boundary
- The active delayed-pulse `<N` form was already supported and covered on its happy path, but malformed RHS values still used raw internal parser messages.
- The active contract is now explicit on that malformed side too:
  - `(P <1 B)`
  - `(P <1 2'0)`
  now fail as malformed delayed-pulse RHS values with the same user-facing contract style used elsewhere in `R8`.
## 2026-03-15: plain `?SIG` test-node names are now part of the explicit contract
- The next `R8` slice closes a small but real test-node boundary gap:
  - selector tokens and computed selectors were already explicit,
  - but the plain `?SIG` form was still accepting the signal name more loosely than the rest of the active language.
- Implementation:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now requires plain test nodes to use `?signal_name` with an HDL-identifier-compatible signal name.
  - The computed-selector path `?(expr)` remains unchanged and supported.
- Focused regression coverage now exists in [t/54-language-contract-test-signal-name-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/54-language-contract-test-signal-name-boundary.t) for:
  - a valid plain `?SIG` success case,
  - malformed signal names like `?bad-name` and `?0`,
  - and pipeline/CLI confirmation that malformed plain test-node signal names do not emit HDL.
- Boundary decision:
  - plain `?SIG` now follows the same explicit identifier contract as source roots, state names, and transition targets,
  - while `?(expr)` stays the separate supported computed-selector form.
## 2026-03-15: transition targets are now part of the explicit contract
- The next `R8` slice closes a real control-flow boundary gap:
  - state/DT block names are now validated explicitly,
  - but transition targets were still mostly taken on trust and could drift into invalid `STATE_*` references or undeclared-state targets later in HDL generation.
- Implementation:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now validates transition target spelling immediately while parsing `->`.
  - Transition targets must be HDL-identifier-compatible regular-state names.
  - After the FSM is fully parsed, the parser now validates that each recorded transition target resolves to a declared regular FSM-state DT block inside the same FSM source.
- Focused regression coverage now exists in [t/53-language-contract-transition-target-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/53-language-contract-transition-target-boundary.t) for:
  - declared forward transition targets,
  - malformed target names like `bad-name`,
  - non-state targets like `-comb`,
  - unknown targets like `missing_state`,
  - and pipeline/CLI confirmation that bad targets do not emit HDL.
- Boundary decision:
  - transition targets are now a first-class source-level contract boundary,
  - not only an eventual HDL-side naming assumption,
  - and they must point at declared regular FSM-state DT blocks rather than standalone DTs or undeclared names.
## 2026-03-15: state and DT block names are now part of the explicit contract
- The next `R8` slice closes a real naming-boundary gap:
  - source-root names were already validated explicitly,
  - but state/DT block names were still mostly being accepted on trust and only failing later if HDL generation tripped over them.
- Implementation:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now validates state/DT block names up front.
  - Regular FSM-state DT names must be HDL-identifier-compatible.
  - General/combinational DT names must use exactly one leading `-` plus an HDL-identifier-compatible base name.
  - Reset-state names remain limited to the already supported special spellings.
- Focused regression coverage now exists in [t/52-language-contract-state-name-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/52-language-contract-state-name-boundary.t) for:
  - a success path with valid regular and standalone DT names,
  - malformed regular state names like `bad-name`,
  - malformed standalone DT names like `-bad-name` and `--bad`,
  - and pipeline/CLI confirmation that malformed names do not emit HDL.
- Boundary decision:
  - state/DT naming is now an explicit source-level contract, not only an eventual HDL-side constraint,
  - and malformed names fail early where the user can understand the construct boundary directly.
## 2026-03-15: symbol-definition sections now have an explicit malformed boundary
- The next `R8` slice closes another real parser-visible gray zone:
  - `+constants`, `+define`, `+params`, and `+enums` already had a documented happy path,
  - but malformed shapes were still relying on Perl list unpacking and incidental `undef` fallout instead of a real language-contract boundary.
- Implementation:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now validates the shape of each symbol-definition family explicitly before storing symbols.
  - `+constants` and `+params` now require non-empty lists of `(NAME scalar_value)` entries.
  - `+define` now requires exactly one `(NAME scalar_value)` pair.
  - `+enums` now requires a non-empty list of `(enum_name (MEMBER value) ...)` definitions, with at least one member per enum.
- Focused regression coverage now exists in [t/51-language-contract-symbol-definition-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/51-language-contract-symbol-definition-boundary.t) for:
  - empty sections,
  - malformed payloads,
  - malformed entry/member shapes,
  - and pipeline/CLI confirmation that malformed symbol-definition sections do not emit HDL.
- Boundary decision:
  - the symbol-definition family remains actively supported,
  - but only within the explicitly documented section/entry shapes,
  - and malformed symbol-definition sections are now out of contract instead of being tolerated accidentally.
## 2026-03-15: `+size` is now explicit instead of partially silent
- The next `R8` slice closes a small but real directive-boundary gap:
  - the shipped corpus still contains a legacy empty `(+size)` block,
  - and the parser was treating that as a silent no-op while also silently ignoring malformed non-list payloads.
- Implementation:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now parses `+size` through an explicit contract helper.
  - The helper keeps legacy empty `(+size)` supported as a no-op, but requires non-empty forms to be a list of `(signal positive_integer_width)` entries.
- Focused regression coverage now exists in [t/50-language-contract-size-section-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/50-language-contract-size-section-boundary.t) for:
  - successful parsing/generation with empty `(+size)`,
  - targeted rejection of malformed payloads like `(+size BROKEN)`,
  - targeted rejection of malformed entries like `(A)`,
  - and targeted rejection of non-positive widths like `(A 0)`.
- Boundary decision:
  - legacy empty `(+size)` remains part of active support as a no-op,
  - but malformed `+size` payloads are no longer silently tolerated.
## 2026-03-15: state/DT blocks now need a real body
- The next `R8` slice closes a small but real parser-visible gray zone:
  - empty blocks like `(idle)` or `(-misc)` were not part of the intended language,
  - but the parser could still build an empty pseudo-state by falling through with no decision trees.
- Implementation:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now rejects state/DT blocks that do not contain at least one nested decision-tree body or action form.
- Focused regression coverage now exists in [t/49-language-contract-state-body-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/49-language-contract-state-body-boundary.t) for:
  - empty FSM-state DT blocks,
  - empty general/combinational DT blocks,
  - and pipeline/CLI confirmation that those malformed blocks do not emit HDL.
- Boundary decision:
  - FSM-state DT blocks like `(aState ...)` and general/combinational DT blocks like `(-mycombDT ...)` must carry a real body,
  - empty block payloads are explicitly outside the active contract.
## 2026-03-15: general/combinational DT blocks are now explicit standalone DTs
- The next `R8` slice closes a terminology-versus-runtime gap around hyphen-prefixed DT blocks:
  - user-facing wording already distinguishes `(aState ...)` as an FSM-state DT from `(-mycombDT ...)` as a general/combinational DT block,
  - runtime behavior was already mostly correct,
  - but the AST contract still relied too much on the leading `-` naming convention instead of preserving that role explicitly.
- Implementation:
  - [perl/FSM/CoreAST.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/CoreAST.pm) now exposes `is_standalone_dt` and treats standalone DTs as an explicit state-role family beside regular states and reset-state DTs.
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now classifies hyphen-prefixed non-reset DT blocks as `state_type => standalone_dt`.
- Focused regression coverage now exists in [t/48-language-contract-standalone-dt-classification.t](/Users/richarddje/Documents/github/fsmgen/t/48-language-contract-standalone-dt-classification.t) for:
  - explicit `standalone_dt` AST classification,
  - exclusion of those blocks from the encoded-state plan,
  - and DT-style enable emission instead of `current_state == ...` comparisons.
- Boundary decision:
  - `(aState ...)` remains an FSM-state DT,
  - reset-state DTs remain their own dedicated families,
  - and hyphen-prefixed non-reset DT blocks are now explicitly standalone/general DTs instead of accidental pseudo-states.
## 2026-03-15: tagged source names now have an explicit whole-name boundary
- The next `R8` slice closes a real source-name mismatch between classification and decoding:
  - the source classifier already treated headers like `?fsm:bad-name` and `?top:bad-name` as tagged source kinds,
  - but the active parsers were decoding those names with `\w+`-style prefix matching,
  - which meant malformed names could silently truncate to a valid prefix like `bad`.
- Implementation:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now validates `?fsm:module_name` roots as a whole and rejects malformed names explicitly.
  - [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm) now validates `?top:top_name` roots as a whole and also validates embedded composition child sources like `?fsm:source_name` as a whole.
- Focused regression coverage now exists in [t/47-language-contract-source-name-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/47-language-contract-source-name-boundary.t) for:
  - malformed top-level `?fsm:bad-name` roots,
  - malformed top-level `?top:bad-name` roots,
  - and malformed embedded composition child sources like `?fsm:bad-name`.
- Boundary decision:
  - tagged source names must now be HDL-identifier-compatible (`[A-Za-z_]\\w*`) and are accepted or rejected as a whole,
  - malformed tagged names no longer truncate silently to their valid prefix.
## 2026-03-15: legacy `+fsm` roots are now a real contract instead of an under-validated compatibility path
- The next `R8` slice closes a real support gap around the documented flattened legacy FSM root:
  - `+fsm` was already claimed as a supported source kind,
  - but the codebase actually carried two shipped legacy layouts:
    - the flattened sibling form with `(+fsm module_name)` followed by sibling forms,
    - and the nested legacy root form `(+fsm module_name ...)`,
  - while malformed `+fsm` roots without a scalar module name still drifted through header decoding instead of getting a targeted contract failure.
- Implementation:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now validates the legacy `+fsm` source family explicitly before decoding the module name.
  - well-formed `+fsm` roots in either shipped legacy layout still parse through the active FSM path,
  - malformed `+fsm` roots now fail with a targeted `Malformed '+fsm' root` diagnostic instead of relying on incidental AST fallout.
- Focused regression coverage now exists in [t/46-language-contract-flat-plus-fsm-root.t](/Users/richarddje/Documents/github/fsmgen/t/46-language-contract-flat-plus-fsm-root.t) for:
  - source classification of `+fsm` as an active FSM source kind,
  - direct adapter parsing and pipeline/CLI generation for both shipped legacy `+fsm` layouts,
  - and explicit parser/pipeline/CLI rejection of malformed `+fsm` roots missing a scalar module name.
- Boundary decision:
  - the legacy `+fsm` root family remains part of active support,
  - in the two shipped legacy layouts already present in the tree,
  - and malformed `+fsm` roots are now explicitly out of contract instead of relying on incidental AST fallout.
## 2026-03-15: terminology clarification for FSM-state DTs versus general DTs
- User wording matters here, and the docs should reflect the language model more precisely:
  - both `(aState ...)` and `(-foobar ...)` are decision trees,
  - `(aState ...)` is an FSM-state DT attached to state `aState`,
  - `(-foobar ...)` is a general/combinational DT block.
- This is a terminology clarification, not a behavioral change:
  - FSM-state DTs and general/combinational DTs still share the same underlying decision-tree machinery,
  - but FSM-state DTs participate in state encoding and transition planning while general DTs do not.
- The user guide should prefer:
  - “FSM-state DT” for `(aState ...)`,
  - and “general/combinational DT block” for `(-foobar ...)`.
## 2026-03-15: reset-state spellings are now a real contract instead of an accidental name trick
- The next `R8` slice closes a real mismatch between the docs, the corpus, and the parser/runtime boundary:
  - the shipped corpus still uses legacy reset-state spellings like `-syncreset`,
  - the docs claimed special reset states were supported,
  - but the normalized reset-state metadata was not being preserved through `FSM::CoreAST::State`,
  - and normalized reset-state names like `syncreset` were still being treated as ordinary encoded states because downstream code only checked for a leading `-`.
- Implementation:
  - [perl/FSM/CoreAST.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/CoreAST.pm) now preserves `state_type` on `FSM::CoreAST::State` and exposes `state_type`, `is_reset_state`, and `is_regular_state` accessors.
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now treats `-syncrst` and `-syncreset` as the same sync-reset family, and `-asyncrst` and `-asyncreset` as the same async-reset family.
  - [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm), [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm), and [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) now classify reset-state blocks as DT-like blocks rather than regular encoded states.
- Focused regression coverage now exists in [t/45-language-contract-reset-state-spellings.t](/Users/richarddje/Documents/github/fsmgen/t/45-language-contract-reset-state-spellings.t) for:
  - canonical and legacy reset-state spellings normalizing to the same internal identities,
  - reset-state blocks staying out of the regular state-encoding plan,
  - and emitted HDL using DT-style enables instead of `current_state == SYNCRESET` / `ASYNCRESET` comparisons.
- Boundary decision:
  - reset-state blocks are now honestly supported as a dedicated contract family,
  - legacy long spellings remain supported as aliases,
  - and reset-state blocks are not part of the ordinary encoded-state set.
## 2026-03-15: the broader operator-arity contract is now active
- The next `R8` slice promotes the previously saved operator-arity agreement into the active parser instead of leaving it as design-only continuity.
- Implementation:
  - [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm) now supports:
    - n-ary relational chains such as `(< low mid high)` and `(== a b c d)`,
    - relational word aliases such as `eq`, `ne`, `lt`, `le`, `gt`, and `ge`,
    - unary alias `not`,
    - and explicit malformed-arity rejection against that broader contract.
  - Chained relational semantics now follow the saved adjacent-pair rule directly in the active parser:
    - `(< a b c)` => `((a < b) && (b < c))`
    - `(eq a b c d)` => `((a == b) && (b == c) && (c == d))`
- The slice also fixed one real end-to-end contract gap exposed by the new operator coverage:
  - [perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm) now follows the driving AST of parser-created intermediate expression signals during signal-role analysis,
  - so source inputs referenced only through those intermediate signals stay live in generated module interfaces.
- Focused regression coverage now exists in:
  - [t/44-language-contract-relational-operators.t](/Users/richarddje/Documents/github/fsmgen/t/44-language-contract-relational-operators.t),
  - and [t/40-language-contract-expression-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/40-language-contract-expression-boundary.t), whose malformed comparison-arity case is now `(== a)` instead of pretending chained comparison forms are unsupported.
- Boundary decision:
  - the broader operator family is no longer only a design note,
  - it is now part of the active supported language contract,
  - while malformed arity outside that contract is rejected explicitly.
## 2026-03-15: unsupported top-level bare forms now fail explicitly
- The next `R8` slice closes one more parser-visible gray zone at the top level of `(?fsm:name ...)`:
  - some malformed bare forms were still being skipped silently instead of being classified clearly as unsupported.
- This was especially misleading for future-looking syntax ideas such as:
  - `(lhs := value)`
  - which we have discussed as a possible future canonical form, but which is not part of the active contract yet.
- Implementation:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now rejects unsupported top-level bare forms explicitly instead of skipping them.
- Focused regression coverage now exists in [t/43-language-contract-top-level-form-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/43-language-contract-top-level-form-boundary.t) for:
  - explicit rejection of future-looking bare init syntax like `(tester_reset := 1)`,
  - explicit rejection of malformed bare scalar forms like `(BROKEN 1)`,
  - and pipeline/CLI confirmation that these forms no longer disappear silently.
- Boundary decision:
  - active top-level forms inside `(?fsm:name ...)` are directive sections, `:=` init/reset directives, and state/DT blocks,
  - future bare forms such as `(lhs := value)` remain design ideas only until deliberately promoted into the active contract.
## 2026-03-15: test-node selectors now require explicit operator prefixes
- The next `R8` slice closes a small but real selector-boundary gray zone in test nodes:
  - active branch selectors are meant to be explicit selector tokens like `=0`, `=OTHER`, `!=8'0`, or `>8'3`,
  - not accidental bare selector payloads like `BUSY` or `0`.
- Implementation:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now validates test-branch selectors explicitly during parse and rejects bare selector payloads with a targeted diagnostic.
  - [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) now enforces the same operator-prefixed selector rule in runtime lowering so direct AST callers cannot bypass the active contract accidentally.
- Focused regression coverage now exists in [t/42-language-contract-test-selector-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/42-language-contract-test-selector-boundary.t) for:
  - explicit rejection of bare symbolic selectors like `BUSY`,
  - explicit rejection of bare numeric selectors like `0`,
  - and continued support for explicit symbolic equality selectors like `=OTHER`.
- Boundary decision:
  - active test-node selectors must use an explicit operator prefix,
  - bare selector payloads are out of active support,
  - and this is compatible with the already shipped relational selector family.
## 2026-03-15: unsupported tagged top-level sources now fail explicitly
- The next `R8` slice closes one more parser-visible gray zone at the source-root boundary:
  - legacy tagged wrappers such as `?define:...` are no longer allowed to drift through the parser just because they contain a nested `?fsm:...` somewhere inside them.
- This slice is intentionally about top-level ownership, not inner content:
  - the active toolchain now evaluates the root source kind first,
  - and unsupported tagged source kinds fail at that boundary instead of being treated as accidental containers for live FSM parsing.
- Implementation:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now rejects unsupported tagged top-level source roots with a targeted diagnostic before the nested-`?fsm` fallback can fire.
  - [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) now rejects the same boundary explicitly in the active pipeline and CLI path.
- Focused regression coverage now exists in [t/41-language-contract-top-level-source-kind-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/41-language-contract-top-level-source-kind-boundary.t) for:
  - direct classifier truth (`kind => unknown`, `header => ?define:...`),
  - direct adapter rejection,
  - pipeline rejection,
  - and CLI rejection without leaked HDL output.
- Boundary decision:
  - active top-level source kinds are `?fsm:name`, `+fsm`, and `?top:name`,
  - other tagged source roots such as `?define:` are explicitly out of active support,
  - and a nested live FSM inside an unsupported tagged wrapper does not make that wrapper supported.
## 2026-03-15: unsupported expression forms now fail explicitly
- The next `R8` slice now closes one more parser-visible gray zone around expressions:
  - [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm) now rejects:
    - unknown operator forms such as `(bogus B C)`,
    - malformed active-operator arity such as `(== B C D)`,
    - empty expression lists,
    - unsupported payload types,
    - and guard-only tokens used in ordinary RHS expression position such as `<start`.
- This slice also preserves one real active compatibility path explicitly instead of accidentally:
  - inline scalar comparison tokens such as `cnt[2:1]!=2'2` are now parsed as real comparison ASTs in ordinary expression position.
- Focused regression coverage now exists in [t/40-language-contract-expression-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/40-language-contract-expression-boundary.t) for:
  - supported inline scalar comparison tokens,
  - unsupported RHS operators,
  - malformed RHS operator arity,
  - and invalid RHS scalar tokens.
- Boundary decision:
  - this slice does not widen the active operator family,
  - it makes the current operator boundary explicit and rejects unsupported expression forms truthfully instead of letting them drift through `undef` fallthrough or arbitrary fake-signal registration.
## 2026-03-15: shorthand guard comparisons are now part of the active contract
- The saved guard-language agreement from 2026-03-14 is now partially promoted into the active `R8` contract instead of remaining a future-only note.
- [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm) now lowers the shorthand guard family explicitly:
  - `(<foo ...)` -> `foo != 0`
  - `(<!foo ...)` -> `foo == 0`
  - `(<foo=value ...)` / `(<foo==value ...)` -> equality
  - `(<foo!=value ...)`, `(<foo<value ...)`, `(<foo<=value ...)`, `(<foo>value ...)`, `(<foo>=value ...)` -> the corresponding comparison operators
- This applies to both guarded blocks and suffix guards, because suffix guards already lower through the same condition parser boundary.
- Focused regression coverage now exists in:
  - [t/39-language-contract-guard-shorthand.t](/Users/richarddje/Documents/github/fsmgen/t/39-language-contract-guard-shorthand.t) for the shorthand family directly,
  - and [t/29-language-contract-core-forms.t](/Users/richarddje/Documents/github/fsmgen/t/29-language-contract-core-forms.t), which now expects explicit comparison ASTs for the simple `<foo` / `<!foo` forms.
- Boundary decision:
  - the shorthand guard family is no longer just a saved future direction,
  - it is now an active supported language feature,
  - while more ambitious future normalization around canonical spelling remains a design concern rather than a support-boundary blocker.
## 2026-03-15: legacy generic/template placeholders are now rejected explicitly
- The old corpus still contains template-expansion syntax that belongs to the legacy generic system, not to the active `.fsm` contract:
  - placeholder selectors such as `?[READ]`,
  - repeat macros such as `?repeat:[MAX_COUNT]`,
  - and placeholder tokens such as `[DATAIN]` or `[?size: ...]`.
- User clarification preserved from the design discussion:
  - forms like `?[READ]` act like generics to be populated later,
  - so they should not be treated as live active-language constructs until a real generic/template lane exists.
- This `R8` slice now makes that boundary explicit:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now rejects placeholder test selectors and repeat macros with targeted diagnostics instead of letting them drift into ordinary `?sig` parsing.
  - [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm) now rejects placeholder scalar tokens explicitly instead of registering them as ordinary signal names.
- Focused regression coverage now exists in [t/38-language-contract-generic-placeholder-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/38-language-contract-generic-placeholder-boundary.t) for:
  - `?[READ]`,
  - `?repeat:[MAX_COUNT]`,
  - and `[DATAIN]`.
- Boundary decision:
  - the active tool now treats these forms as explicit out-of-support legacy generic/template syntax,
  - not as partially supported FSM constructs.
- Future placeholder-syntax note saved from the design discussion:
  - `[VAR]` should remain legacy-only and should not be revived as the canonical future placeholder form.
  - `<VAR>` is a bad fit because `<...` is already core guarded-block / suffix-guard syntax in the active language.
  - `$VAR` could exist later as lightweight sugar, but it is not self-delimiting enough to be the canonical form.
  - `$(VAR)` is the preferred future canonical placeholder form because it is explicit, bounded, and scales better to later structured forms such as `$(size MAX_COUNT)` or `$(expr MAX_COUNT-1)`.
  - If a real generic/template lane is opened later, the clean direction would be:
    - canonical form: `$(VAR)`
    - optional sugar: `$VAR`
    - with both remaining outside the current active `R8` contract until that lane exists.
## 2026-03-15: computed test selectors are now part of the active contract
- The shipped parser already supported the computed-selector test-node form:
  - `?(expr)` where `expr` is a selector expression such as `(| A B)`.
- This `R8` slice closes the runtime gap that kept that form from being honestly supported:
  - [perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm) now analyzes the computed selector signal's driving AST, so the source signals used inside `expr` remain live inputs instead of disappearing from the generated interface.
  - [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) now treats parser-created intermediate selector signals as real intermediate signals during later dependency/filtering analysis instead of dropping them through AST-factorization heuristics.
- Focused regression coverage now exists in [t/37-language-contract-computed-test-selector.t](/Users/richarddje/Documents/github/fsmgen/t/37-language-contract-computed-test-selector.t) for:
  - the computed-selector form itself,
  - the synthesized intermediate selector signal,
  - the source-signal interface exposure,
  - and the emitted HDL wire/assign boundary.
- Boundary decision:
  - active test-node support now includes both `?SIG` and `?(expr)`,
  - and `?(expr)` may synthesize an internal intermediate signal that the branch comparisons reuse explicitly in generated HDL.
## 2026-03-15: relational `?sig` selectors are now part of the active contract
- The shipped corpus and active lowering path already relied on a broader `?sig` selector family than the docs admitted:
  - selectors like `!=8'0`, `>8'3`, and `<=8'3` are real active language forms, not just `=0` / `=1`.
- This `R8` slice now makes that truthful:
  - [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) now lowers relational test-node selectors with the matching comparison operator instead of collapsing everything to equality,
  - and [t/36-language-contract-test-branch-selectors.t](/Users/richarddje/Documents/github/fsmgen/t/36-language-contract-test-branch-selectors.t) now locks that behavior through captured condition ASTs and emitted HDL.
- Boundary decision:
  - active `?sig` selectors now include exact-value and relational operators,
  - and the docs now state that broader selector family explicitly instead of underspecifying the live language.
## 2026-03-15: malformed empty test-node branches now fail explicitly
- The next `R8` slice now tightens the `?sig` / case-style dispatch boundary:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now emits a targeted malformed-test-branch diagnostic instead of leaking malformed empty branches through a generic internal `undef` action failure.
- Focused regression coverage now exists in [t/35-language-contract-test-branch-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/35-language-contract-test-branch-boundary.t) for:
  - empty branches such as `(?MODE (=0))`,
  - and mixed test nodes where one branch is valid but another branch is empty.
- Boundary decision:
  - active test-node support still treats `?sig` as the case/switch-style multi-way exact-value form,
  - and each branch must now be understood as `selector + at least one nested action`.
## 2026-03-15: `:=` is now an explicit top-level init/reset directive, and future canonical forms are saved
- The active tree already uses compact top-level directives such as `(:= tester_reset=1)` in shipped corpus files like [fsm/mipicsi2_configreg.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/mipicsi2_configreg.fsm).
- This `R8` slice makes that boundary explicit instead of leaving it accidental:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now treats `:=` as a real top-level init/reset directive,
  - records explicit reset/default metadata on the target signal,
  - and no longer lets malformed DT actions or empty guarded blocks disappear silently.
- Focused regression coverage now exists in [t/34-language-contract-malformed-actions.t](/Users/richarddje/Documents/github/fsmgen/t/34-language-contract-malformed-actions.t) for:
  - supported top-level compact `:=` directives,
  - malformed single-token DT action forms such as `(BROKEN)`,
  - malformed `:=` directives such as `(:= BROKEN)`,
  - and empty guarded blocks such as `(<req)`.
- Future language-design note saved from the current discussion:
  - `(:= (lhs value))` would be a cleaner canonical structural form than the current compact `(:= lhs=value)` compatibility syntax,
  - `(lhs := value)` could also be accepted as user-facing sugar over that same canonical form,
  - but both are future normalization ideas only and are not part of the active contract yet.
- Boundary decision:
  - active support now includes legacy-compatible top-level `:=` init/reset directives,
  - while malformed DT action tokens still fail explicitly instead of being silently dropped.
## 2026-03-15: bare condition suffixes now fail explicitly
- The next `R8` slice now closes one more parser-visible legacy ambiguity around guarded-action syntax:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now rejects bare suffix tails like `start` or `full` in assignment/transition suffix positions,
  - so suffix guards must use the explicit active forms `<sig`, `<!sig`, or explicit condition-expression payloads.
- Focused regression coverage now exists in [t/33-language-contract-condition-suffix-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/33-language-contract-condition-suffix-boundary.t) for:
  - bare assignment suffix rejection,
  - and bare transition suffix rejection.
- Boundary decision:
  - this slice does not shrink the supported guarded-block family,
  - it only removes an implicit legacy acceptance path that was never part of the explicit language agreement.
## 2026-03-15: syntax-namespace rationale is now preserved for later language work
- Historical syntax rationale from the current language discussion is now saved explicitly:
  - the `(?foo:...)` family was chosen because it visually resembles Perl 5 regex grouping syntax,
  - and because it uses a shape users are unlikely to type accidentally in ordinary names or payloads.
- The `+...` family had a separate role:
  - it provided a directive-section namespace for forms like `+system`, `+size`, and the symbol-definition sections,
  - specifically to distinguish those constructs from ordinary state names.
- Boundary decision:
  - the project is not committing to a syntax-family redesign right now,
  - but if this area is revisited later, it should be treated as a family-level namespace decision rather than a `+system`-only rename.
- Saved future-direction note:
  - alternatives such as `(+clock clk)` / `(+asreset rstn)` or a broader directive-namespace redesign remain future language ideas only,
  - not part of the current supported contract.
## 2026-03-15: unsupported top-level `+...` directives now fail explicitly
- The next `R8` slice now closes one more parser-visible legacy ambiguity:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) no longer lets unknown top-level `+...` directive sections drift into fake state parsing,
  - and now emits a targeted error that lists the currently supported top-level directive family inside `?fsm:name`.
- Focused regression coverage now exists in [t/32-language-contract-top-level-directive-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/32-language-contract-top-level-directive-boundary.t) for:
  - unknown directive sections such as `(+bogus ...)`,
  - and future-looking but currently unsupported section spellings such as `(+clock clk)`.
- Boundary decision:
  - this slice does not define a new directive syntax family,
  - it only makes the current supported boundary explicit and rejects unsupported `+...` top-level directives truthfully.
## 2026-03-15: the conventional `+system` section is now part of the active `R8` contract
- The next `R8` slice is now regression-backed and promoted into the live support boundary:
  - [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now treats the conventional shared-system declaration as fully supported:
    - `(+system (clock clk) (sreset rstn))`
    - `(+system (clock clk) (asreset rstn))`
- The parser no longer silently ignores `+system`:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now validates the active `+system` contract explicitly,
  - records default clock/reset domains,
  - and registers typed system signals for `clk` and `rstn`.
- Focused regression coverage now exists in [t/31-language-contract-system-section.t](/Users/richarddje/Documents/github/fsmgen/t/31-language-contract-system-section.t) for:
  - the accepted conventional `+system` declaration,
  - non-conventional clock-name rejection,
  - unsupported directive rejection,
  - and incomplete-section rejection.
- Boundary decision:
  - this slice makes the conventional shared-system declaration explicit and supported,
  - accepts the two current shipped explicit `+system` reset declarations already present in the active tree,
  - but it still does not widen the contract into arbitrary system metadata, custom clock/reset names, or richer reset-mode differentiation.
## 2026-03-15: symbol-definition sections are now part of the active `R8` contract
- The next `R8` slice is now regression-backed and promoted into the live support boundary:
  - [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now treats the symbol-definition families as fully supported:
    - `(+constants ...)`,
    - `(+enums ...)`,
    - `(+define ...)`,
    - `(+params ...)`.
- The parser bug uncovered while tightening this contract is now fixed in [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm):
  - packed one-element Lispish array wrappers are now unwrapped consistently before scalar parsing for constants, defines, params, and enum members,
  - which restores correct literal resolution for `+constants` and `+define` in particular.
- Focused regression coverage now exists in [t/30-language-contract-symbol-definitions.t](/Users/richarddje/Documents/github/fsmgen/t/30-language-contract-symbol-definitions.t) for:
  - symbol-summary counts,
  - RHS literal resolution for constants, defines, params, and enum members,
  - and guard equality resolution against symbol-defined values.
- Boundary decision:
  - this slice makes symbol resolution normative only for the currently proven contract:
    - assignment RHS expressions,
    - and guard equality conditions.
  - `(+system ...)` beyond the conventional `clk` / `rstn` path remains unresolved and stays outside the supported tier for now.
## 2026-03-14: first `R8` language-contract slice is now promoted and regression-backed
- The first real `R8` slice is now live in the user-facing contract:
  - [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now contains a draft normative language-contract section for:
    - guarded blocks,
    - condition suffixes,
    - update shorthand,
    - and the currently regression-backed operator-expression families.
- The support boundary was tightened accordingly:
  - nested guarded blocks,
  - suffix guards on assignments/transitions,
  - compound update shorthand,
  - inline compound modifiers,
  - and the current regression-backed broader operator surface
  are no longer left in the vague “implemented but not strong enough” bucket.
- Focused regression coverage now exists in [t/29-language-contract-core-forms.t](/Users/richarddje/Documents/github/fsmgen/t/29-language-contract-core-forms.t) for:
  - simple and nested guarded blocks,
  - logical guarded expressions,
  - suffix guards,
  - shorthand and inline compound updates,
  - and broader operator lowering (`+`, `-`, `*`, `/`, `%`, `^`, `add`, `xor`).
- Boundary decision:
  - the more systematic future sugar direction discussed earlier, especially canonical shorthand such as `<foo==3` over a fully explicit guard expression, remains a saved future design note rather than part of the active contract today.
- Small support fix landed with this slice:
  - [perl/FSM/ExpressionNamer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/ExpressionNamer.pm) now defensively handles undefined legacy expression strings,
  - and [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm) no longer emits avoidable warning noise when debug-rendering some driving ASTs.
## 2026-03-14: long-term horizon goals are now captured explicitly
- The detailed roadmap now records two explicit long-term horizon goals:
  - a Rust implementation of FSMGen,
  - and a public project website that is beautiful, dynamic, and strong enough to present the project professionally.
- Boundary decision:
  - these are intentionally not active workstreams yet,
  - they are gated behind the current “make FSMGen state-of-the-art, rock solid, and really stable first” rule,
  - which means the current `R8`..`R13` contract/product-hardening work remains the real priority.
- Rationale:
  - both goals are strategically good,
  - but both become much healthier projects once the language contract, diagnostics, support accounting, and embedding surface are mature enough that the project can either be reimplemented or publicly amplified without ambiguity.
## 2026-03-14: roadmap v2 is now opened with `R8` as the active lane
- The first roadmap (`R0`..`R7`) remains closed and historically complete.
- The project now has an explicit second roadmap generation:
  - [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) remains the canonical live board,
  - [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) is the detailed companion roadmap for the post-modernization workstream set.
- Rationale:
  - the project no longer needs another broad modernization/refactor roadmap,
  - it now needs a contract-hardening roadmap focused on language clarity, diagnostics, support accounting, and deliberate backend growth,
  - the already-saved design agreements for guarded blocks, condition suffixes, update shorthand, and operator semantics are strong enough to support a real `R8` opening instead of remaining as loose notes only.
- Structural outcome:
  - roadmap v2 opens with `R8` (`language-contract hardening`) as the active lane,
  - `R9` through `R14` are now defined as explicit follow-on workstreams rather than informal future ideas,
  - the README onboarding order now points directly to both the live board and the new detailed roadmap companion.
- Boundary decision:
  - `R8` is marked `in progress` because the groundwork already exists:
    - a live support boundary in the user guide,
    - and saved semantic agreements for the main gray-zone control/expression constructs,
  - but the workstream remains genuinely open because those agreements have not yet been promoted into a normative language contract with matching regression coverage.
## 2026-03-14: candidate post-roadmap workstreams after `R0`..`R7`
- With the current roadmap closed, the next sensible improvements should be framed as a new explicit roadmap rather than as residual work from `R0`..`R7`.
- Suggested priority order for that future roadmap:
  - `R8` language-contract hardening,
  - `R9` strict mode and support-tier enforcement,
  - `R10` source provenance and diagnostics,
  - `R11` composition contract strengthening,
  - `R12` regression corpus and support-claim hardening,
  - `R13` public embedding/API stabilization,
  - `R14` VHDL backend only if it is still truly wanted after the contract work above.
- Rationale for this ordering:
  - the highest-value next step is not feature count; it is a crisp, trustworthy language boundary,
  - the current gray zone between "parser accepts it" and "the project should claim it is supported" is the biggest remaining gap between a capable tool and a serious tool,
  - backend diversification such as VHDL should come after the language and diagnostics contracts are tightened, not before.
- The specific gray-zone cluster that should be resolved first in any future roadmap is:
  - `(+system ...)` beyond conventional `clk` / `rstn`,
  - `(+constants ...)`, `(+enums ...)`, `(+define ...)`, `(+params ...)`,
  - nested `<...` / `<!...` blocks,
  - condition suffixes,
  - `++`, `--`, `+=`, `-=`,
  - broader arithmetic/operator forms.
- Boundary decision:
  - these are stored as future-work recommendations only,
  - they do not reopen the closed current roadmap,
  - and they should become live only if/when the project chooses to open a new explicit workstream set.
## 2026-03-14: agreed future semantics for guarded blocks, suffix guards, and update shorthand
- These are saved design agreements for later language-contract hardening work.
- They are not yet being promoted to the live "fully supported" boundary in the user guide.

### `(3)` Guarded blocks are a first-class language construct
- Guarded blocks are a first-class surface construct, not incidental legacy sugar.
- Nesting is intentionally unlimited.
- Semantic model:
  - each nested guarded block adds one guard,
  - nested guards compose by logical `AND`,
  - enclosed actions run under the conjunction of all active guards.
- Signal sugar:
  - `(<foo ...)` means `(<foo!=0 ...)`
  - `(<!foo ...)` means `(<foo==0 ...)`
- Relational shorthand:
  - `(<foo==3 ...)` means `(<(== foo 3) ...)`
  - `(<foo!=0 ...)` means `(<(!= foo 0) ...)`
- General form:
  - `(<(op (op1 ...) (op2 ...) ... (opN ...)) ...actions...)`
  - `(<!(op (op1 ...) (op2 ...) ... (opN ...)) ...actions...)`
  - where the `opk` family is relational/logical and may be unary or N-ary.
- Examples:
```lisp
(<req
  (A <= B)
)

(<!full
  (ERR <= 1)
)

(<foo==3
  (OUT = IN)
)

(<(& req ready !full)
  (WR_EN <= 1)
  (-> busy)
)

(<req
  (<mode==3
    (<!full
      (GO <= 1)
    )
  )
)
```

### `(4)` Condition suffixes have exactly the same semantics as guarded blocks
- Condition suffixes are first-class surface syntax.
- Their semantics are exactly the same as `(3)`; only the position of the guard differs.
- Canonical lowering rule:
  - a suffix guard desugars to a guarded block containing exactly one action.
- Examples:
```lisp
(A <= B <req)
```
means:
```lisp
(<req
  (A <= B)
)
```

```lisp
(OUT = IN <mode==1)
```
means:
```lisp
(<mode==1
  (OUT = IN)
)
```

```lisp
(-> send <!full)
```
means:
```lisp
(<!full
  (-> send)
)
```
- Composition rule:
  - suffix guards combine naturally with outer guarded blocks by logical `AND`.
- Readability rule of thumb captured in discussion:
  - suffix form is best for one short guarded action,
  - block form is best when one condition guards several actions or when nesting should remain visually explicit.

### `(5)` update shorthand semantics
- The following are agreed as update shorthand over multi-bit register/flop targets:
  - `(++ counter)` means increment multi-bit register/flop `counter` by `1`
  - `(-- retry_count)` means decrement multi-bit register/flop `retry_count` by `1`
  - `(+=4 byte_count)` means increment multi-bit register/flop `byte_count` by `4`
  - `(-=1 remaining)` means decrement multi-bit register/flop `remaining` by `1`
- Equivalence note:
  - `(-=1 remaining)` is semantically the same update as `(-- remaining)`.
- These agreements should be carried forward when the language contract for shorthand updates is made normative.

### `(6)` RHS operator-form expression contract (working design direction)
- The agreed direction is that the RHS of a combinational or sequential assignment should accept one expression of the form:
  - `(op expr1 expr2 ... exprN)`
- The RHS expression grammar should be the same across assignment families; the assignment operator decides timing/storage semantics, not the RHS grammar.
- Operator aliases should lower to one canonical operator family.
- The exact interpretation must be stated clearly and illustrated with examples whenever this is made normative.

#### Current working interpretation by operator family
- Working direction:
  - treat infix-style operator families as unlimited-ary where their semantics can be explained deterministically,
  - use the operator's associativity or chain rule to define the lowering,
  - and always document that lowering with unambiguous examples.
- Natural unlimited-ary fold operators:
  - `(+ a b c ... z)` means `(a + b + c + ... + z)`
  - `(* a b c ... z)` means `(a * b * c * ... * z)`
  - logical/bitwise combine operators are also naturally unlimited-ary:
  - `(& a b c ... z)` means `(a & b & c & ... & z)`
  - `(| a b c ... z)` means `(a | b | c | ... | z)`
  - `(^ a b c ... z)` means `(((a ^ b) ^ c) ^ ... ^ z)`
- Left-associative unlimited-ary operators:
  - `(- a b c d)` means `(((a - b) - c) - d)`
  - `(/ a b c d)` means `(((a / b) / c) / d)`
  - `(% a b c d)` means `(((a % b) % c) % d)`
- Unary operator:
  - `(! a)` means logical inversion of `a`
- Chained unlimited-ary relational operators:
  - `(< a b c)` means `((a < b) && (b < c))`
  - `(<= a b c d)` means `((a <= b) && (b <= c) && (c <= d))`
  - `(> a b c)` means `((a > b) && (b > c))`
  - `(>= a b c)` means `((a >= b) && (b >= c))`
  - `(== a b c)` means `((a == b) && (b == c))`
  - `(!= a b c)` means `((a != b) && (b != c))`

#### Examples
```lisp
(-state0
  (sum  = (+ a b c d))
  (prod = (* a b c d))
  (mask = (& ready valid enable))
  (par  = (^ a b c))
  (diff = (- a b c d))
  (quo  = (/ a b c d))
)
```

```lisp
(-state0
  (inside_range = (< 0 x 8))
  (ordered_pair = (<= low value high))
)
```

```lisp
(-state0
  (sum  = (add a b))
  (flag = (xor a b c))
)
```

#### Boundary note
- This is saved as a working design direction for future language-contract hardening.
- The key principle agreed in discussion is:
  - if an operator form is allowed, its exact interpretation must be provided unambiguously and explained with examples.
## 2026-03-14: `R7` closed with a second deliberate typed hook
- Finished the bounded `R7` lane by adding one more real hook boundary instead of continuing to widen loading or parameter plumbing.
- Rationale:
  - the loading story was already explicit and strong enough,
  - the remaining honest gap in `R7` was the hook set itself: one post-generation hook alone still made the replacement mechanism feel too narrow and too end-loaded,
  - the right second hook is at the parsed-source frontier because it is early, stable, and still avoids broad mid-pipeline mutation.
- Structural outcome:
  - `FSM::Extension::Context` now carries hook-stage metadata plus parsed AST data where appropriate,
  - the shipped hook set is now:
    - `after_parse_source($context)`,
    - `after_generate_result($context)`,
  - `HDLGenerator` now dispatches the source-frontier hook after source classification and after composition IR parsing when the source is a `?top:name` input,
  - the extension tests now lock both hook stages across the existing loading paths.
- Boundary decision:
  - this closes `R7` because the active architecture now has:
    - a typed registry,
    - typed hook contexts,
    - an explicit loading stack,
    - and a small deliberate hook set at two real lifecycle boundaries,
  - richer parameters, more hooks, or future convenience features can happen later, but they are no longer blockers on replacing `.plg` / `PPlugin` as the architectural extension story.
- Roadmap consequence:
  - `R7` can now move from `mostly done` to `done`,
  - there is no active roadmap lane left in the current `R0`..`R7` plan,
  - future work should be introduced as a new explicit workstream rather than stretching the closed current roadmap.
## 2026-03-14: the user guide now states the live `.fsm` support boundary directly
- Followed up after roadmap closure with a documentation-only clarification of the language boundary.
- Rationale:
  - "supported" had become too easy to answer informally from memory, which is risky now that the active architecture is narrower and more deliberate than the legacy surface,
  - the guide needed a live boundary that distinguishes:
    - what is truly regression-backed,
    - what is implemented but still lighter on coverage,
    - and what is intentionally outside the active model,
  - the user also called out standalone DT blocks explicitly, and that point mattered: the guide should reflect the active runtime truth rather than defaulting to a state-centric explanation.
- Documentation outcome:
  - [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now contains a dedicated live support section for current `.fsm` constructs,
  - that section now names standalone hyphen-prefixed blocks such as `(-alpha_dt ...)`, `(-misc ...)`, and `(-mycombit ...)` as supported standalone DT constructs,
  - it also states the current runtime distinction clearly:
    - regular named states participate in state encoding and transition planning,
    - DT-only inputs use the same decision-tree machinery but do not synthesize a state-register plan.
- Boundary decision:
  - the guide intentionally does not label every parser-accepted legacy form as "fully supported",
  - the stronger bar remains:
    - active parser support,
    - active generation path,
    - plus real regression coverage.
- Roadmap consequence:
  - no roadmap status changed,
  - this is a truth-clarification slice around the now-closed roadmap, not a new roadmap capability.
## 2026-03-14: `R7` explicit loading stack now includes config files
- Continued `R7` by closing the remaining loading-surface gap after object injection and explicit module-name loading.
- Rationale:
  - once explicit module-name loading existed, the remaining practical gap was not discovery but repeatability,
  - a small explicit config-file layer lets users keep stable extension lists out of the shell command line without reopening directory scans or `.plg`-style hook discovery,
  - the right config contract is intentionally tiny: one explicit `module Module::Name` declaration per active line plus optional blank/comment lines.
- Structural outcome:
  - [perl/FSM/Extension/Loader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Loader.pm) now parses extension-config files and reports malformed lines with file/line diagnostics,
  - `HDLGenerator` now accepts `extension_config_files => [ ... ]`,
  - [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) now accepts repeated `--extension-config <file>` flags,
  - the new behavior is locked by [t/28-extension-config-loading.t](/Users/richarddje/Documents/github/fsmgen/t/28-extension-config-loading.t).
- Boundary decision:
  - the extension-loading story is now explicit at three levels:
    - direct objects,
    - explicit module names,
    - explicit config files of module names,
  - there is still no auto-discovery, environment scan, or `.plg` compatibility path,
  - this keeps `R7` aligned with typed explicit boundaries rather than drifting back toward implicit plugin architecture.
- Roadmap consequence:
  - this is enough to move `R7` from `in progress` to `mostly done`,
  - the next meaningful work is no longer loading-related; it is the next typed hook boundary and any later decision about richer extension parameters.
## 2026-03-14: `R7` explicit loading path is now programmatic plus CLI
- Continued `R7` by solving the next practical gap in the first typed extension seam: loading.
- Rationale:
  - the first shipped hook was useful but still incomplete as an architectural replacement while it required callers to construct extension objects manually,
  - the right next step was an explicit loading path, not auto-discovery; users need a way to ask for one specific extension module without reopening `.plg` scans or string-hook registries,
  - loading by explicit module name keeps the architecture typed and testable because the boundary is still: validate name, load module, instantiate object, dispatch explicit method.
- Structural outcome:
  - the codebase now has [perl/FSM/Extension/Loader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Loader.pm) as the narrow explicit module loader for `R7`,
  - `HDLGenerator` now accepts `extension_modules => [ ... ]`,
  - [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) now accepts repeated `--extension-module Module::Name` flags,
  - the tests now lock both the pipeline-side and CLI-side explicit loading path.
- Boundary decision:
  - this is still not `.plg` compatibility,
  - there is still no directory scan, auto-discovery, or config-file layer,
  - module loading stays explicit and constructor-based (`new()`), which keeps the active replacement seam small and reviewable.
- Roadmap consequence:
  - `R7` stays `in progress`,
  - the next decision is whether explicit loading should remain at programmatic-plus-CLI scope or gain a config-file layer,
  - and then which additional typed hook boundary is worth standardizing next.
## 2026-03-14: typed-extension documentation now teaches the concept directly
- Followed up on the first shipped `R7` seam with a documentation-only clarification pass.
- Rationale:
  - "typed extension" is accurate architecture language, but it is not automatically self-explanatory to users reading the new boundary for the first time,
  - the user guide is the right place to show what the current extension seam actually feels like in practice,
  - the architecture note should also say explicitly that "typed" here means structured object/method/context dispatch, not a static type system claim.
- Documentation outcome:
  - [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now has a dedicated typed-extension section with concrete examples for result annotation and telemetry collection,
  - [docs/EXTENSION_MODEL.md](/Users/richarddje/Documents/github/fsmgen/docs/EXTENSION_MODEL.md) now defines "typed" more plainly and gives a second realistic extension example.
- Roadmap consequence:
  - no roadmap status changed,
  - this is clarity work around the already-shipped first `R7` boundary, not a new `R7` capability slice.
## 2026-03-14: `R7` started with a typed post-generation extension seam
- Started `R7` by landing one real extension boundary in the active pipeline instead of trying to design the full replacement plugin architecture all at once.
- Rationale:
  - the old `.plg` / `PPlugin` path bundled together discovery, dispatch, and late mutation in a way that is too implicit for the refactored architecture,
  - the first honest replacement slice is therefore a typed, explicit, programmatic boundary that proves live extensibility without reopening file scanning, `AUTOLOAD`, or string-dispatch hooks,
  - a post-generation hook is the safest first seam because it does not need to mutate parse-time or mid-synthesis state while the broader extension contract is still being defined.
- Structural outcome:
  - the active pipeline now has a typed extension registry and typed hook context,
  - `HDLGenerator->new(...)` can now accept `extensions => [ ... ]`,
  - the pipeline dispatches `after_generate_result($context)` for both supported source kinds before handing the result back to the caller,
  - the first replacement contract is documented explicitly in `docs/EXTENSION_MODEL.md` and locked by `t/26-extension-mechanism.t`.
- Boundary decision:
  - `R7` does not start by recreating `.plg` compatibility,
  - there is no auto-discovery, CLI loading, or mid-pipeline hook set in this first slice,
  - the modern extension story is intentionally explicit and typed first; broader loading/config questions come only after this base seam is proven.
- Roadmap consequence:
  - this is enough to move `R7` from `not started` to `in progress`,
  - the next decision is whether to keep loading programmatic-only for now or add an explicit config/CLI path,
  - and then to choose the next typed hook boundary without reviving legacy string-named plugin phases.
## 2026-03-14: `R6` shipped `C6` and closed the scoped composition lane
- Continued `R6` by finishing the last bounded acceptance-matrix slice instead of leaving the remaining unsupported legacy shapes as “probably okay.”
- Rationale:
  - the composition lane was not honestly done while some legacy constructs still failed only incidentally or without a clear scope-boundary framing,
  - `C6` is about boundary quality, not feature width: the active tool should reject the obsolete plugin/eval-era constructs deliberately and say why.
- Structural outcome:
  - `FSM::Composition::Parser` now routes the remaining reachable legacy shapes through explicit scope-boundary messages that point back to the scoped composition docs,
  - legacy macro/plugin child forms are now called out directly rather than being lumped into the generic “unsupported child” message.
- Roadmap consequence:
  - with `C1` through `C6` all shipped, `R6` can now close truthfully as `done`,
  - the active roadmap lane moves to `R7`,
  - the `.rtlif` grammar/stronger-interface-contract note remains as a future refinement, not a blocker on the closed `R6` lane.
## 2026-03-14: `R6` shipped `C5` width-mismatch diagnostics
- Continued `R6` by turning the existing width-equality rule into a fully locked diagnostic boundary.
- Rationale:
  - explicit `?toplink` width mismatches were already rejected, but `C5` was not truly done until that behavior was covered by tests and the declared connect-by-name path produced an equally direct diagnostic,
  - the right finish for `C5` is not another representation change; it is a clear user-facing failure mode that names the two conflicting endpoints and their widths.
- Structural outcome:
  - explicit-link width mismatches are now regression-locked,
  - declared connect-by-name width mismatches now directly report the top port, the child endpoint, and both widths.
- Roadmap consequence:
  - this is enough to move `R6` from `in progress` to `mostly done`,
  - the remaining roadmap work is now bounded to `C6` plus the already-recorded `.rtlif` contract follow-up.
## 2026-03-14: user-guide clarification for realistic `=name` usage
- Followed up on the first shipped `C4` slice by making the user-facing contract less abstract.
- Rationale:
  - the minimal `=final_data>8` example was technically correct but still too small to teach when `=name` is actually the right tool,
  - realistic examples belong in the user guide because this is primarily an authoring/usage question, not a design-boundary question.
- Documentation outcome:
  - the guide now shows realistic `=name` usage for:
    - exposing child FSM outputs directly at the top level,
    - passing a top-level control input into one child,
    - and exposing an external RTL output with `.rtlif` metadata.
  - it also now states the practical rule of thumb:
    - use `=name` only for intentional same-name passthrough,
    - keep explicit `?toplink` for renaming, remapping, and broader wiring.
## 2026-03-14: `R6` first shipped `C4` declared connect-by-name slice
- Continued `R6` by adding the first narrow modern connect-by-name contract on top of the shipped explicit-link lanes.
- Rationale:
  - the right modern meaning of “connect-by-name” is not broad inference; it is an explicit declaration that authorizes a deterministic same-name match,
  - putting that declaration on typed top ports (`=name` in `?ports`) keeps the feature small, testable, and visibly opted-in,
  - reusing the existing typed link planner is safer than inventing a second hidden auto-wiring engine.
- Structural outcome:
  - typed composition ports now carry `binding_mode`,
  - the parser preserves `=name` declarations as explicit connect-by-name intent,
  - `HDLGenerator` synthesizes by-name links from those declarations and then runs them through the same endpoint-resolution/validation pipeline as explicit links.
- Contract decision:
  - the first shipped `C4` slice is top-port only,
  - a declared connect-by-name match is valid only when exactly one child endpoint has the same name, same direction, and same width,
  - ambiguity and no-match cases fail explicitly instead of widening hidden inference.
- Safety/compatibility:
  - existing `C1`/`C2`/`C3` behavior stays intact because `C4` reuses the same planned-binding and emission paths,
  - explicit `?toplink` remains the mechanism for all other non-system connections,
  - the `.rtlif` follow-up is now recorded on the roadmap so we do not lose the next design question: document exact grammar now and later decide whether a stronger interface-source contract should replace or sit above the sidecar form.
- Verification:
  - syntax checks for the touched composition types, planner, and new parser/test files pass,
  - focused composition regressions `t/14`, `t/20`, `t/21`, `t/22`, `t/23`, and `t/24` pass,
  - the full Perl regression suite passes again after landing the `C4` slice.
- Next likely slices:
  - move to `C5` by tightening width-mismatch diagnostics across explicit and declared-by-name endpoints,
  - then close the scoped `R6` plan with the remaining explicit out-of-scope legacy-failure work in `C6`.
## 2026-03-14: `R6` first shipped `C3` mixed FSM-plus-RTL slice
- Continued `R6` by widening the shipped composition runtime from FSM-only linking into the first mixed external-RTL lane.
- Rationale:
  - the user’s clarification was the right architectural boundary: `?rtl` is a composition-time interface-binding concern, not a request to regenerate or semantically parse the external RTL internals at this layer,
  - the narrow honest next step after `C2` was therefore to consume pre-parsed interface metadata in a typed way, not to revive the legacy `entity_loader(...)` / plugin DB path,
  - using a sidecar metadata artifact keeps the scope tight while still proving the architecture can plan and validate mixed `?fsmc` + `?rtl` tops end to end.
- Structural outcome:
  - the composition layer now has a dedicated [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm),
  - `HDLGenerator` now realizes `?rtl` children through typed `<module>.rtlif` metadata instead of rejecting them,
  - the explicit-link planner is now reused for a dedicated `C3` lane rather than for FSM-only `C2` alone,
  - mixed tops instantiate the external RTL child but never emit its internals.
- Contract decision:
  - the first modern external-RTL contract is a flat `?rtlif:<module>` sidecar file containing typed port tokens,
  - lookup is intentionally simple and deterministic: beside the composition source first, then through existing `FSMLIB` roots,
  - this is a better modern fit than copying the old environment-specific entity DB hooks because it preserves explicit interface validation without reintroducing `AUTOLOAD`, `.plg`, or hidden loader state.
- Safety/compatibility:
  - `C1` and `C2` behavior stay intact because the mixed lane reuses the same explicit-link planning rules around endpoint roles, exact width matching, and deterministic net naming,
  - the shipped `C3` lane is still intentionally bounded: exactly one `?fsmc`, exactly one `?rtl`, explicit `?toplink`, and default RTL instance naming from the module name.
- Verification:
  - syntax checks for the new loader, updated planner, and new tests pass,
  - focused composition regressions `t/20`, `t/21`, `t/22`, and `t/23` pass,
  - the full Perl regression suite passes again after landing the `C3` slice.
- Next likely slices:
  - move to `C4` by defining the first narrow connect-by-name rule beyond explicit-link-only composition,
  - then tighten `C5`/`C6` around width-mismatch diagnostics and explicit failure for out-of-scope legacy composition constructs.
## 2026-03-14: `R6` first shipped `C2` FSM-linking slice
- Continued `R6` by widening the active composition runtime from one-child passthrough to the first explicit multi-child FSM-linking lane.
- Rationale:
  - once `C1` was shipped, the next honest move was not to jump straight to `?rtl`, but to prove that the active architecture can plan and emit deterministic wiring across more than one realized child,
  - explicit `?toplink` resolution is the right next step because it exercises the typed composition objects and forces us to define endpoint roles, internal-net ownership, and duplicate-driver behavior,
  - keeping this slice FSM-only avoids mixing two unsettled concerns at once: multi-child wiring and external-RTL interface loading.
- Structural outcome:
  - the composition layer now has a typed `Net` plan object for internal child-to-child wiring,
  - `Plan` now carries typed internal nets and `RealizedInstance` now carries port bindings,
  - `HDLGenerator` now has a real `C2` planning path for multiple embedded `?fsmc` children with explicit `?toplink` wiring,
  - explicit link endpoints are now resolved as either top-port names or `instance.port` child endpoints,
  - the planner now validates endpoint roles, width equality, deterministic source-carrier selection, and duplicate targets before emission,
  - top emission is now driven from planned bindings instead of recomputing wiring ad hoc.
- Safety/compatibility:
  - the single-FSM path remains unchanged,
  - `C1` behavior remains intact because it now just uses the same generic top emitter with a simpler binding plan,
  - the shipped multi-child lane is still intentionally bounded: embedded `?fsmc` children only, shared `clk` / `rstn` auto-wiring only, and explicit `?toplink` for non-system ports.
- Verification:
  - syntax checks for the new net type, updated planner, and new composition tests pass,
  - focused regressions `t/13`, `t/14`, `t/20`, `t/21`, and `t/23` pass,
  - the full Perl regression suite passes again after landing the `C2` slice.
- Next likely slices:
  - move to `C3` by adding `?rtl` child realization with declared interface metadata,
  - then add the remaining `C4`/`C5`/`C6` coverage around declared connect-by-name, width-mismatch diagnostics, and explicit rejection of out-of-scope legacy constructs.
## 2026-03-14: `R6` first shipped `C1` composition generation slice
- Continued `R6` by landing the first real composition runtime path instead of staying at parser-only groundwork.
- Rationale:
  - after the typed parser/IR slice, the next honest move was to prove one narrow accepted scenario end to end rather than keep expanding non-executable composition scaffolding,
  - the active child FSM pipeline does not yet carry typed `+system` metadata through `module_info`, so the first composition lane has to align with the real shipped child contract instead of pretending that richer interface metadata already exists,
  - that real contract today is: implicit `clk` / `rstn` system inputs plus only the user-facing child ports the FSM pipeline explicitly exposes.
- Structural outcome:
  - the composition layer now has typed per-port/per-link/runtime-plan objects under `perl/FSM/Composition/`,
  - `HDLGenerator` now supports a real `C1` runtime lane for one embedded `?fsmc` child with one explicit `?ports` block,
  - realized child interface data is stored as typed composition ports on the `RealizedInstance`,
  - top planning validates exact name/width/direction agreement before emission,
  - top emission now generates the parent module plus same-name child wiring through the normal CLI path.
- Safety/compatibility:
  - the single-FSM path stays unchanged,
  - the shipped composition lane is deliberately narrow and explicit,
  - one fixture assumption was corrected during the slice: a child signal is not a composition-visible port unless the child FSM itself marks it as an output, which is the right active-tool contract to preserve.
- Verification:
  - syntax checks for the touched composition/pipeline files pass,
  - focused composition regressions `t/13`, `t/14`, and `t/20` pass,
  - the full Perl regression suite passes again after landing the `C1` slice.
- Next likely slices:
  - widen from `C1` to `C2` with multi-child planning and typed explicit `?toplink`/net resolution,
  - then add the corresponding duplicate-driver and width/endpoint diagnostics.
## 2026-03-14: `R6` first typed composition parser/IR slice plus legacy mapping note
- Continued `R6` by moving from “explicit composition source boundary” to “explicit composition parser boundary.”
- Rationale:
  - after adding source classification, the next useful move was not to jump straight to top emission but to create a typed parser seam that future realization/planning code can build on,
  - the legacy `fx/bin/fsmgen` pass confirmed that the language concepts are real and historically grounded,
  - the same legacy pass also confirmed that the old implementation mechanism is not reusable because too much of it depended on `AUTOLOAD`, `PPlugin`, and plugin/eval late mutation.
- Structural outcome:
  - `docs/COMPOSITION_LEGACY_MAPPING.md` now captures the historical composition call tree and explicitly separates language concepts from obsolete plugin machinery,
  - the active codebase now has a first typed composition parser/IR layer under `perl/FSM/Composition/`,
  - `HDLGenerator` now parses `?top:name` sources into typed composition objects before stopping at the still-unimplemented realization/emission boundary,
  - the active parser now accepts `?top`, `?fsmc`, `?rtl`, `?ports`, and `?toplink` as typed child-block concepts,
  - several legacy-only shapes are now rejected deliberately:
    - inline top-port shorthand,
    - multi-source `?fsmc`,
    - nested `?top`,
    - unknown child kinds.
- Safety/compatibility:
  - this still does not claim active composition generation support,
  - the supported single-FSM path is unchanged,
  - the behavior change is that composition-shaped inputs now go through a truthful typed parse boundary before the not-yet-implemented runtime boundary is reported.
- Verification:
  - syntax checks for the new composition packages and updated pipeline pass,
  - focused regressions `t/13-composition-source-classification.t` and `t/14-composition-parser.t` pass.
- Next likely slices:
  - replace raw `?ports` / `?toplink` payload storage with typed port/link planning objects,
  - then start `C1` realization: one `?top:name`, one `?fsmc` child, explicit top-port exposure, deterministic top planning, and initial top emission.
## 2026-03-14: `R6` explicit composition source boundary before FSM-only parsing
- Landed the first executable composition-aware behavior in the active toolchain by inserting an explicit source-kind classifier before the existing FSM-only parser boundary.
- Rationale:
  - the scope document said `?top:name` had to be detected above the FSM-only parser, but the active runtime still let composition-shaped inputs fall through to a misleading generic FSM-shape error,
  - the next honest `R6` step was therefore not full composition parsing yet, but a typed boundary that distinguishes “unsupported composition source” from “malformed FSM source,”
  - that boundary is also reusable for the real composition parser/IR work that follows, so a shared classifier is better than scattering ad hoc `?top:` checks.
- Structural outcome:
  - `perl/FSM/SourceClassifier.pm` now owns top-level raw-AST source-kind classification,
  - `HDLGenerator` now classifies source kind before adapter parsing and rejects `?top:name` with a composition-specific diagnostic,
  - `FSMGenFull::Parser` now also rejects `?top:name` explicitly for direct callers instead of reporting the generic `?fsm:name` / `+fsm` shape error,
  - `t/13-composition-source-classification.t` locks classifier behavior plus the pipeline/adapter/CLI failure boundary,
  - `t/01-regression.t` now uses the same classifier to keep the broad compile sweep aligned with the active supported boundary instead of accidentally treating composition fixtures as normal FSM inputs,
  - `t/09-ast-first-intermediate-registry.t` and `t/10-ast-first-enable-structure.t` now target a real FSM-root sample instead of the legacy composition sample `trial_1.fsm`.
- Safety/compatibility:
  - existing single-FSM inputs still use the same adapter/generation path,
  - the behavior change is limited to composition-shaped roots, which now fail earlier and more truthfully,
  - this does not claim composition support; it only makes the unsupported boundary explicit and testable.
- Verification:
  - syntax checks for the new classifier, pipeline, and parser pass,
  - focused regression `t/13-composition-source-classification.t` passes,
  - the broad compile regression `t/01-regression.t` passes again once it is limited to active FSM-root samples,
  - the AST-first architecture tests pass again once they are retargeted to an actual FSM-root fixture.
- Next likely slices:
  - implement the first typed parser/IR objects for `?top:name` contents (`?ports`, `?fsmc`, `?rtl`, `?toplink`),
  - start the first acceptance-scenario test from `docs/COMPOSITION_SCOPE.md`, most likely the single-child `C1` lane.
## 2026-03-14: `R6` scope defined against the active architecture
- Started `R6` by defining composition scope concretely against the modern active pipeline instead of continuing to refer to legacy composition capabilities abstractly.
- Rationale:
  - composition was the next active lane, but the current codebase still had no active composition parser, typed IR, or emitter,
  - the honest next move was therefore not implementation-by-guessing but a scoped contract grounded in the current `bin/fsmgen` architecture,
  - the legacy `top_exec` notes remain useful context, but they are too broad and too entangled with obsolete eval/plugin behavior to serve as the implementation contract directly.
- Structural outcome:
  - `docs/COMPOSITION_SCOPE.md` now defines the first active composition lane,
  - the scoped source model is `?top:name` plus `?fsmc`, `?rtl`, `?ports`, and `?toplink`,
  - the planned architecture boundary is a typed composition parser/classifier above the existing FSM-only parser,
  - the first acceptance matrix is now explicit (`C1`..`C6`) instead of implied.
- Safety/compatibility:
  - no runtime behavior changed in this slice,
  - the scope is intentionally narrow and excludes legacy macro/plugin behavior from the first implementation lane,
  - the current single-FSM compile path remains the reference baseline that composition must preserve unchanged.
- Verification:
  - `git diff --check` passes,
  - targeted `rg` over the scope/roadmap docs confirms the new composition scope and `R6` transition wiring.
- Next likely slices:
  - implement the first source-classification layer that distinguishes `?fsm:name` from `?top:name`,
  - then add the first focused composition acceptance tests from the new scope document.
## 2026-03-14: Live roadmap snapshots now include what each `Rj` does
- Tightened the roadmap display contract so live-status snapshots show not only each phase’s status but also a short explanation of what that phase actually covers.
- Rationale:
  - status alone is not enough when the roadmap phases are abstract labels like `R3` or `R6`,
  - the user needs to see, at a glance, what each phase means without reopening the whole board or mentally decoding old history,
  - the canonical board is therefore now responsible for carrying both progress state and a concise semantic label for each phase.
- Structural outcome:
  - every workstream in `ROADMAP_STATUS.md` now has a `Description` field,
  - commit-workflow close-outs must now show every `Rj` as `status + description`,
  - when a phase has meaningful open sub-steps, the close-out may add brief sub-bullets for the active lane, changed lane, or another phase whose next step matters.
- Safety/compatibility:
  - this is a workflow/communication hardening slice only; no runtime behavior changed,
  - the live-status snapshot stays compact, but it now carries enough semantics to be useful without cross-referencing multiple docs.
- Verification:
  - `git diff --check` passes,
  - targeted `rg` over the workflow/docs confirms the new description requirement is wired consistently.
## 2026-03-14: `R3` completion audit and active-lane pivot to `R6`
- Closed the `R3` runtime-convergence phase after removing the last implicit stored-expression parse from normal backend runtime-AST resolution.
- Rationale:
  - `R3` was no longer about removing every compatibility hook; its exit criteria allowed deliberate, well-justified explicit residue,
  - once stored-expression parsing was removed from the default runtime path, the remaining compatibility behavior became narrow and intentional instead of ambient,
  - that means the remaining miss-recovery parser and owner-side legacy-registry/global-expression parser are acceptable final boundaries, not evidence that the phase is still open.
- Structural outcome:
  - `ROADMAP_STATUS.md` now marks `R3` as `done`,
  - the active lane now pivots to `R6` (`Composition-oriented language / architecture work`),
  - the next roadmap task is no longer another runtime-convergence cleanup; it is definition of concrete composition scope and acceptance tests for the active architecture.
- Safety/compatibility:
  - runtime behavior is now more explicit: stored expressions no longer become runtime ASTs unless the miss-recovery path intentionally asks for that recovery,
  - the compatibility residue that remains is documented, explicit, and covered by focused regression.
- Verification:
  - focused regression `t/07-runtime-ast-miss-dependency-recovery.t` passes,
  - full regression `prove -I perl t` passes.
- Next likely slices:
  - define composition scope for active `bin/fsmgen`,
  - write acceptance tests and developer-facing scope notes before implementation.
## 2026-03-14: `R3` runtime convergence slice removing direct stored-expression runtime parsing
- Narrowed the remaining runtime compatibility behavior again by removing direct stored-expression parsing from `resolve_intermediate_signal_runtime_ast(...)`.
- Rationale:
  - after the render-time late-hydration removal, the normal runtime-AST resolution path still had one implicit string-reconstruction step left,
  - that step blurred the contract because a plain runtime-AST lookup could still synthesize AST state from an arbitrary stored expression,
  - the explicit miss-recovery path is the correct place for that behavior because it is intentional, source-tagged, and only used after a real runtime-AST miss.
- Structural outcome:
  - normal runtime-AST resolution now stops at substituted ASTs and native/owner-resolved defining ASTs,
  - stored-expression-only lookups now record `no_ast_source` and leave recovery to `extract_intermediate_signals_from_runtime_ast_miss(...)`,
  - the old `parsed_expression_ast` / `cleaned_expression_ast` runtime-AST source labels disappear with this change.
- Safety/compatibility:
  - this narrows implicit compatibility behavior without removing the explicit compatibility-recovery path,
  - focused regression now locks that direct runtime-AST resolution no longer parses stored expressions while explicit cleaned-expression recovery still succeeds.
- Verification:
  - syntax checks for the backend and the focused test pass,
  - focused regression `t/07-runtime-ast-miss-dependency-recovery.t` passes.
- Next likely slices:
  - if `R3` is considered complete after this boundary audit, pivot to `R6`,
  - otherwise the only remaining runtime-convergence question is whether the explicit miss-recovery parser should remain as the final justified boundary.
## 2026-03-14: Commit workflow always displays the live-status tracker
- Tightened the close-out contract for the commit workflow so the current live roadmap snapshot is always shown after a commit, not only on status transitions.
- Rationale:
  - the user wants to see, at every commit boundary, how the just-finished task relates to the current roadmap state,
  - showing the snapshot only on status changes leaves too much ambiguity about whether the board was checked and whether the task moved anything,
  - the close-out therefore needs to distinguish two cases explicitly: “the snapshot changed like this” versus “the snapshot is unchanged for this task.”
- Structural outcome:
  - `COMMIT.md`, `.agents/workflows/commit.md`, `ROADMAP_STATUS.md`, and `MEMORY.md` now all require the current live-status snapshot in every commit-workflow close-out,
  - the workflow now also requires explicit wording about whether the snapshot changed or stayed the same.
- Safety/compatibility:
  - this is a workflow/communication hardening slice only; no runtime code changed,
  - the roadmap board remains the canonical source of truth, but the commit workflow now guarantees that the current snapshot is surfaced every time work is closed out.
- Verification:
  - `git diff --check` passes,
  - targeted `rg` over the workflow/docs confirms the new “always display snapshot” rule is wired consistently.
## 2026-03-14: `R3` runtime convergence slice removing render-time late hydration
- Narrowed one remaining compatibility behavior in `Backend::SystemVerilog` by removing the render-time “late hydration” retry from `render_intermediate_signal_expression(...)`.
- Rationale:
  - rendering an intermediate expression should not quietly mutate runtime-AST state after an earlier `no_ast_source` miss,
  - that behavior blurred the remaining compatibility boundary because a plain render call could turn into implicit recovery and mutate `runtime_ast_source`,
  - the explicit runtime-AST-miss dependency-recovery path is the better place for that behavior because it is intentional, inspectable, and already records recovery provenance.
- Structural outcome:
  - plain expression rendering now stops at `enable_graph_expression` / stored-expression fallback when no runtime AST exists,
  - the cleaned compatibility-expression recovery path still exists, but only when dependency recovery explicitly asks for it,
  - the explicit recovery path also exposed that `resolve_intermediate_signal_width(...)` needed a defaulted registry argument to support the shorter live call form already used by the backend.
- Safety/compatibility:
  - this narrows hidden compatibility behavior rather than widening it,
  - the focused regression now locks both sides of the boundary: no silent render-time hydration, but explicit cleaned-expression dependency recovery still works and records its source,
  - `R3` therefore remains `mostly done`, with the remaining residue now reduced to the direct raw/cleaned parsing still present in backend runtime-AST resolution and dependency recovery.
- Verification:
  - syntax check for `Backend/SystemVerilog.pm` passes,
  - focused regression `t/07-runtime-ast-miss-dependency-recovery.t` passes.
- Next likely slices:
  - re-audit the remaining direct compatibility parsing in `resolve_intermediate_signal_runtime_ast(...)` and `recover_runtime_ast_from_dependency_expression(...)`,
  - either remove that residue, replace it with native AST/CoreAST data, or keep it explicitly as the final justified compatibility boundary.
## 2026-03-14: `R2` completion audit and active-lane pivot to `R3`
- Closed the live ownership-migration phase after auditing the remaining backend surface against the explicit `R2` deliverables.
- Rationale:
  - once the roadmap board gained explicit deliverables, `R2` could no longer stay `in progress` merely because the backend still had code in the same area,
  - the correct question became whether any remaining backend code still represented synthesis/analysis ownership residue,
  - the audit answer was no: the remaining backend pocket is runtime AST recovery/filtering and emitted-signal ordering/rendering, which is exactly the retained backend responsibility described by the `R2` deliverables.
- Structural outcome:
  - `ROADMAP_STATUS.md` now marks `R2` as `done`,
  - the current active lane now switches to `R3` (`AST/CoreAST-first runtime convergence`),
  - the next roadmap focus is the remaining compatibility/runtime-AST-miss fallback residue inside `Backend::SystemVerilog`, which belongs under `R3`, not `R2`.
- Safety/compatibility:
  - this is a roadmap-state update only; no runtime code changed in this slice,
  - the change is evidence-based: it follows an audit of what the backend still does, not optimism about progress.
- Verification:
  - `git diff --check` passes,
  - backend audit confirms no remaining direct `assignment_analysis` / `lhs_assignments` ownership residue in `Backend::SystemVerilog`,
  - targeted `rg` over the backend confirms the remaining surface is the runtime-AST recovery/filtering and emission-ordering pocket.
- Next likely slices:
  - follow `R3` and re-audit the remaining compatibility parse / runtime-AST-miss fallback paths,
  - remove them where they are no longer justified, or keep them explicitly as deliberate compatibility residue.
## 2026-03-14: EnableGraph live-usage evidence ownership
- Continued the live `R2` ownership convergence by moving intermediate-signal live-usage evidence derivation under `EnableGraph`.
- Rationale:
  - the backend was still walking `assignment_analysis`, captured condition ASTs, and factorized expressions to answer “is this intermediate signal still needed?”,
  - those helpers did not render HDL; they derived owner-side usage evidence consumed later by backend filtering,
  - the next truthful move was therefore to keep the evidence derivation with `EnableGraph`, while the backend retains the actual filtering decision logic for emitted consolidated signals.
- Structural outcome:
  - `EnableGraph::ast_contains_signal(...)` now owns owner-side AST signal-reference inspection,
  - `EnableGraph::is_signal_referenced_in_substitutions(...)`, `is_signal_actually_used_in_final_expressions(...)`, and `resolve_intermediate_signal_live_usage(...)` now own the live-usage evidence derivation,
  - `Backend::SystemVerilog` now consumes that cached owner-provided evidence during consolidated intermediate-signal filtering instead of exposing the helpers itself.
- Safety/compatibility:
  - no intended HDL behavior change; only the ownership boundary moved,
  - the architecture regression now locks the backend free of the former live-usage evidence helper pocket while asserting `EnableGraph` ownership of the live entrypoints,
  - focused and full regression stayed green, so the move preserved the active intermediate-signal retention contract.
- Verification:
  - syntax checks for `EnableGraph.pm` and `Backend/SystemVerilog.pm` pass,
  - focused architecture regression `t/10-ast-first-enable-structure.t` passes,
  - full regression remains green (`prove -I perl t` -> `Files=12`, `Tests=400`, `PASS`).
- Next likely slices:
  - re-audit the remaining backend filtering decision logic around consolidated intermediate-signal emission,
  - move only the pieces that are truly synthesis/analysis ownership, not backend-local factorization or rendering.
## 2026-03-14: Roadmap deliverables hardening
- Tightened the live roadmap board so each `Rx` phase now has explicit deliverables.
- Rationale:
  - a status label without explicit deliverables is still too interpretive for a project of this size,
  - the user explicitly asked what `done` means, which means the board needed to define completion in terms of concrete outputs rather than narrative intent,
  - the roadmap board is the correct place to encode that because it is the canonical current-state source.
- Structural outcome:
  - every workstream in `ROADMAP_STATUS.md` must now state `Deliverables`, `Status`, `Done`, `Left`, and `Exit criteria`,
  - the live status scale is now deliverable-based: `done` means all listed deliverables are complete and the exit criteria are met,
  - the workflow docs now treat deliverable changes as board-refresh events, just like status/remaining-work/active-lane changes.
- Safety/compatibility:
  - this is a documentation/process clarification slice only; no runtime behavior changed,
  - status answers can now be justified directly from explicit deliverables instead of reconstructed from narrative history.
- Verification:
  - `git diff --check` passes,
  - `rg -n "^Deliverables:|roadmap deliverables|All listed `Deliverables`" ROADMAP_STATUS.md MEMORY.md COMMIT.md .agents/workflows/commit.md CHANGES.md DEVELOPMENT_NOTES.md` confirms the board/workflow wiring.
- Next likely slices:
  - keep deliverables current when roadmap interpretation changes,
  - when a phase status changes, explain that change against the listed deliverables rather than only repeating the status label.
## 2026-03-14: Live status visibility hardening
- Tightened the roadmap-status process so status changes are not only recorded but also surfaced immediately in the task close-out.
- Rationale:
  - `ROADMAP_STATUS.md` is now the canonical current-state board, but current-state alone is not enough if status transitions are easy to miss in day-to-day work,
  - the user explicitly asked for status changes to be both displayed and logged, so status movement must now be treated as a first-class workflow event,
  - `CHANGES.md` is the most appropriate historical log for those transitions because it already tracks completed slices and their practical consequences.
- Structural outcome:
  - `ROADMAP_STATUS.md` now requires a close-out status snapshot whenever a workstream status or the active lane changes,
  - `CHANGES.md` is now the required historical log for those live-status transitions,
  - `MEMORY.md`, `COMMIT.md`, and `.agents/workflows/commit.md` now all encode the same behavior so future sessions apply it consistently.
- Safety/compatibility:
  - this is a workflow/documentation hardening slice only; no runtime code path changed,
  - status display is triggered by actual status movement, not every commit, so the close-out stays focused instead of becoming repetitive noise.
- Verification:
  - `git diff --check` passes,
  - `rg -n "live status|status snapshot|ROADMAP_STATUS\\.md|CHANGES\\.md" ROADMAP_STATUS.md MEMORY.md COMMIT.md .agents/workflows/commit.md CHANGES.md DEVELOPMENT_NOTES.md` confirms the workflow wiring.
- Next likely slices:
  - apply this automatically on the next real status transition in `ROADMAP_STATUS.md`,
  - keep the close-out snapshot compact and sourced directly from the live board.
## 2026-03-14: EnableGraph substitution synchronization ownership
- Continued the live `R2` ownership convergence by moving substitution-era AST rewrite/debug passes under `EnableGraph`.
- Rationale:
  - the first-pass and second-pass substitution synchronization code was still rewriting `assignment_analysis` and captured condition ASTs from the backend,
  - those passes do not render HDL and do not implement the factorization algorithm itself; they synchronize owner-side synthesis structures after factorization,
  - the next truthful move was therefore to keep those rewrites, plus the surrounding unary-negation debug scan, with `EnableGraph`, while the backend and fixpoint loop stay focused on factorization orchestration and rendering.
- Structural outcome:
  - `EnableGraph::count_unary_negations_in_original_expressions(...)` now owns the substitution-era unary-negation debug scan,
  - `EnableGraph::update_original_asts_with_substituted_versions(...)` now owns first-pass synchronization back into `assignment_analysis` and `lhs_assignments`,
  - `EnableGraph::update_original_asts_with_second_pass_substitutions(...)` now owns the second-pass synchronization used by the fixpoint loop,
  - `Backend::SystemVerilog` and `FSM::HDL::Factorization::Fixpoint` now both defer to `EnableGraph` for those rewrites instead of mutating owner-side synthesis data directly.
- Safety/compatibility:
  - no intended HDL behavior change; only the ownership boundary moved,
  - the architecture regression now locks the backend free of the former substitution-update/debug helper pocket while asserting `EnableGraph` ownership of the live entrypoints,
  - focused and full regression stayed green, so the move preserved the active substitution/factorization contract.
- Verification:
  - syntax checks for `EnableGraph.pm`, `Backend/SystemVerilog.pm`, and `Factorization/Fixpoint.pm` pass,
  - focused architecture regression `t/10-ast-first-enable-structure.t` passes,
  - full regression remains green (`prove -I perl t` -> `Files=12`, `Tests=392`, `PASS`).
- Next likely slices:
  - re-audit the remaining backend-side filtering and live-usage checks around consolidated intermediate-signal emission,
  - move only the pieces that are truly synthesis/analysis ownership, not backend-local factorization or rendering.
## 2026-03-14: EnableGraph factorization AST-feed ownership
- Continued the live `R2` ownership convergence by moving factorization AST feeding under `EnableGraph`.
- Rationale:
  - both the primary AST feed and the second-pass AST feed were still walking `assignment_analysis`, captured condition ASTs, and intermediate-signal ownership data from the backend,
  - those feeders do not render HDL and do not perform the factorization algorithm itself; they prepare owner-side synthesis data for factorization,
  - the next truthful move was therefore to keep those collection and eligibility decisions with `EnableGraph`, while the backend and fixpoint engine stay focused on factorization orchestration and rendering.
- Structural outcome:
  - `EnableGraph::feed_asts_to_factorizer(...)` now owns primary factorization AST collection,
  - `EnableGraph::feed_current_asts_to_second_pass(...)` now owns post-substitution AST collection for the fixpoint loop,
  - `EnableGraph` also now owns the second-pass intermediate-signal eligibility checks (`ast_contains_intermediate_signals(...)` / `ast_has_intermediate_signals_recursive(...)`),
  - `Backend::SystemVerilog` and `FSM::HDL::Factorization::Fixpoint` now both defer to `EnableGraph` for those feeds instead of walking owner-side synthesis data themselves.
- Safety/compatibility:
  - no intended HDL behavior change; only the ownership boundary moved,
  - the architecture regression now locks the backend free of the former factorization-feed helper pocket while asserting `EnableGraph` ownership of the live entrypoints,
  - focused and full regression stayed green, so the move preserved the active factorization contract.
- Verification:
  - syntax checks for `EnableGraph.pm`, `Backend/SystemVerilog.pm`, and `Factorization/Fixpoint.pm` pass,
  - focused architecture regression `t/10-ast-first-enable-structure.t` passes,
  - full regression remains green (`prove -I perl t` -> `Files=12`, `Tests=386`, `PASS`).
- Next likely slices:
  - re-audit whether the remaining substitution-update/debug passes over `assignment_analysis` and captured condition ASTs still belong in the backend,
  - move only the pieces that are truly synthesis/analysis ownership, not backend-local factorization or rendering.
## 2026-03-14: Roadmap tracking infrastructure hardening
- Added a canonical live roadmap board in `ROADMAP_STATUS.md`.
- Rationale:
  - narrative history in `CHANGES.md`, `DEVELOPMENT_NOTES.md`, and `MEMORY.md` is valuable for context, but it is not an efficient source for answering “what is done, what is left, and what is the current active lane?” with precision,
  - the project is now large enough that status must be queryable directly rather than reconstructed from long-form history,
  - the user explicitly requested four exact achievement levels, so the board now normalizes status onto `done`, `mostly done`, `in progress`, and `not started`.
- Structural outcome:
  - `ROADMAP_STATUS.md` now serves as the canonical live board,
  - it records stable workstream IDs, a status for each workstream, explicit `Done` / `Left` summaries, and the current active lane,
  - the commit/process docs now require refreshing that board before commit whenever a task changes roadmap status, remaining work, or the active lane.
- Safety/compatibility:
  - this is a process/documentation slice only; no code path changed,
  - future status answers should now come from `ROADMAP_STATUS.md` first, with `CHANGES.md` / `DEVELOPMENT_NOTES.md` / `MEMORY.md` acting as supporting evidence rather than the primary status source.
- Verification:
  - `git diff --check` passes,
  - `rg -n "ROADMAP_STATUS\.md" README.md MEMORY.md COMMIT.md .agents/workflows/commit.md CHANGES.md DEVELOPMENT_NOTES.md` confirms the board is wired into the documented workflow.
- Next likely slices:
  - keep `ROADMAP_STATUS.md` current before every commit when the board changes,
  - if the workstream set itself becomes stale, revise the board structure in the same commit that changes the roadmap interpretation.
## 2026-03-14: EnableGraph logical-op counting ownership
- Continued the live ownership convergence by moving binary logical-operation counting under `EnableGraph`.
- Rationale:
  - the counting pass that produces `binary_logical_op_counts` is consumed by `EnableGraph`’s logical factorization policy (`should_factor_logical_operation(...)` / `contains_frequently_used_operations(...)`),
  - the old backend-side counting pass walked `EnableGraph`-owned `assignment_analysis`, the DT/LHS enable ASTs, and captured condition ASTs, but did not perform backend-specific rendering,
  - the next truthful move was therefore to keep the counting pass and its helper pocket with the same owner that applies the resulting policy.
- Structural outcome:
  - `EnableGraph::count_binary_logical_operation_occurrences(...)` now owns live logical-op counting,
  - `EnableGraph` also now owns the supporting AST collection/traversal helper pocket used only by that pass,
  - `Orchestrator` now routes step 4 directly through `EnableGraph`,
  - `Backend::SystemVerilog` no longer carries those counting helpers and now defers to `EnableGraph` for the defensive recount path inside global factorization.
- Safety/compatibility:
  - no intended HDL behavior change; only the ownership boundary moved,
  - the architecture regression now locks the backend free of the former counting helper pocket while asserting `EnableGraph` ownership of the live entrypoint,
  - focused and full regression stayed green, so the move preserved the active factorization-counting contract.
- Verification:
  - syntax checks for `EnableGraph.pm`, `Orchestrator.pm`, and `Backend/SystemVerilog.pm` pass,
  - focused architecture regression `t/10-ast-first-enable-structure.t` passes,
  - full regression remains green (`prove -I perl t` -> `Files=12`, `Tests=379`, `PASS`).
- Next likely slices:
  - re-audit whether any remaining backend stage still analyzes `assignment_analysis` or other `EnableGraph`-owned enable structures without adding backend-specific value,
  - if that lane is exhausted, pivot to the next truthful runtime seam rather than continuing owner-churn on the same edge.
## 2026-03-14: EnableGraph WEN/EN prescan ownership
- Continued the live ownership convergence by moving WEN/EN intermediate-signal prescan under `EnableGraph`.
- Rationale:
  - the old backend-side `prescan_wen_en_for_intermediate_signals(...)` did not render HDL or perform backend-specific factorization work,
  - it walked `EnableGraph`-owned `assignment_analysis`, traversed the same DT/LHS enable AST structures already built by `EnableGraph`, and delegated the actual AST traversal to `EnableGraph::track_ast_intermediate_signals(...)`,
  - the next truthful move was therefore to keep that prescan with the same owner that already owns the enable structures and their intermediate-signal tracking semantics.
- Structural outcome:
  - `EnableGraph::prescan_wen_en_for_intermediate_signals(...)` now owns live WEN/EN prescan,
  - `Orchestrator` now routes step 5 directly through `EnableGraph`,
  - `Backend::SystemVerilog` no longer carries that prescan entrypoint.
- Safety/compatibility:
  - no intended HDL behavior change; only the ownership boundary moved,
  - the architecture regression now locks the new boundary explicitly by asserting backend absence and `EnableGraph` ownership,
  - focused and full regression remained green, so the move preserved the active intermediate-signal discovery contract.
- Verification:
  - syntax checks for `EnableGraph.pm`, `Orchestrator.pm`, and `Backend/SystemVerilog.pm` pass,
  - focused architecture regression `t/10-ast-first-enable-structure.t` passes,
  - full regression remains green (`prove -I perl t` -> `Files=12`, `Tests=374`, `PASS`).
- Next likely slices:
  - re-audit whether any other remaining backend stage is still analyzing `assignment_analysis` or other `EnableGraph`-owned enable structures without adding backend-specific value,
  - if that lane is empty, pivot to the next truthful runtime seam rather than forcing more ownership churn in the same area.
## 2026-03-14: EnableGraph state register planning ownership
- Continued the live synthesis ownership convergence by moving state-structure planning under `EnableGraph`.
- Rationale:
  - `Backend::SystemVerilog::generate_state_encoding(...)` and `generate_state_register(...)` were still recomputing regular-state membership, encoding order, state-bit width, and reset-state selection inline,
  - those same decisions were also implicitly duplicated in other live synthesis paths such as `build_internal_signal_declaration_plan(...)` and `get_fsm_reset_state(...)`,
  - the next truthful move was therefore to let `EnableGraph` build one shared state plan while the backend stays responsible only for rendering that plan.
- Structural outcome:
  - `EnableGraph::build_state_register_plan(...)` now owns the live state-structure plan,
  - `Backend::SystemVerilog` now renders state encodings and the dedicated state-register block from that plan,
  - `EnableGraph` now reuses the same plan for reset-state lookup and for deciding when `current_state` / `next_state` should be treated as already-declared dedicated state signals.
- Safety/compatibility:
  - no intended HDL behavior change; only the planning/rendering boundary moved,
  - the focused regressions now lock both sides of the contract: regular-state FSMs keep the current encoding/reset-state behavior, and standalone-DT-only FSMs keep state-register planning disabled,
  - the full regression suite stayed green, so the owner move preserved active behavior.
- Verification:
  - syntax checks for `EnableGraph.pm` and `Backend/SystemVerilog.pm` pass,
  - focused regressions `t/10-ast-first-enable-structure.t`, `t/11-flatteneddt-generation-reset.t`, and `t/12-enablegraph-capture-registry.t` pass,
  - full regression remains green (`prove -I perl t` -> `PASS`).
- Next likely slices:
  - re-audit whether any remaining backend stage still computes synthesis-domain structure instead of rendering owner-provided plans,
  - if the planning/rendering lane is nearly exhausted, pivot to the next truthful live runtime seam instead of forcing another structural extraction.
## 2026-03-14: EnableGraph module declaration planning ownership
- Continued the live synthesis ownership convergence by moving module/interface declaration planning under `EnableGraph`.
- Rationale:
  - `Backend::SystemVerilog::generate_module_declaration(...)` was still making synthesis-domain decisions about which signals become interface ports, whether each port is an input or output, whether it is emitted as `wire` or `reg`, and what width it carries,
  - those decisions depend on synthesis-owned signal classification, especially `EnableGraph::get_driven_signals(...)` plus the existing explicit-output conventions,
  - the next truthful move was therefore to let `EnableGraph` build a typed declaration plan while keeping the backend responsible only for rendering text.
- Structural outcome:
  - `EnableGraph::build_module_declaration_plan(...)` now owns live module-port planning and the derived `declared_port_signals` / `port_directions` registries,
  - `Backend::SystemVerilog::generate_module_declaration(...)` now consumes that plan and renders it,
  - backend-local interface classification logic is gone from the active path.
- Safety/compatibility:
  - no intended HDL behavior change; only the planning/rendering boundary moved,
  - the first focused run caught a real snapshot-sensitive formatting regression in the generic renderer, which was fixed by preserving the exact legacy `output reg  ...` spacing contract for output ports,
  - focused and full regression stayed green after that fix, so the owner move preserved active interface behavior.
- Verification:
  - syntax checks for `EnableGraph.pm` and `Backend/SystemVerilog.pm` pass,
  - focused regressions `t/05-assignment-hdl-snapshots.t`, `t/03-assignment-intent-metadata.t`, and `t/10-ast-first-enable-structure.t` pass,
  - full regression remains green (`prove -I perl t` -> `Files=12`, `Tests=364`).
- Next likely slices:
  - re-audit whether any remaining backend emission step is still making synthesis-domain planning decisions that now belong with `EnableGraph`,
  - if that lane is exhausted, pivot to the next truthful live runtime seam instead of forcing more interface-only ownership moves.
## 2026-03-14: EnableGraph internal declaration planning ownership
- Pivoted from pure wrapper convergence to the next live synthesis seam by moving internal declaration planning under `EnableGraph`.
- Rationale:
  - `Backend::SystemVerilog::generate_internal_signal_declarations(...)` was still deciding synthesis-domain questions from `assignment_analysis` such as which non-port LHS signals need internal regs and which helper regs are required for dual-output and pulse-delay families,
  - those decisions depend on `EnableGraph`-owned analysis helpers like `get_lhs_width_from_analysis(...)`, `get_signal_assignment_type(...)`, and `get_pulse_delay_cycles_for_lhs(...)`,
  - the next truthful move was therefore to let `EnableGraph` build the declaration plan while the backend remains responsible only for RTL rendering.
- Structural outcome:
  - `EnableGraph::build_internal_signal_declaration_plan(...)` now owns live declaration planning from `assignment_analysis`,
  - `Backend::SystemVerilog::generate_internal_signal_declarations(...)` now consumes that plan and renders it,
  - the backend no longer re-derives helper-reg needs or width-driven declaration choices from synthesis metadata on its own.
- Safety/compatibility:
  - no intended HDL behavior change; only the planning/rendering boundary moved,
  - the focused declaration regression now locks the live plan directly for representative dual-output and pulse-delay families,
  - the full regression suite stayed green, so the owner move preserved active declaration behavior.
- Verification:
  - syntax checks for `EnableGraph.pm` and `Backend/SystemVerilog.pm` pass,
  - focused regressions `t/03-assignment-intent-metadata.t` and `t/10-ast-first-enable-structure.t` pass,
  - full regression remains green (`prove -I perl t` -> `Files=12`, `Tests=346`).
- Next likely slices:
  - re-audit whether any other backend emission steps still make synthesis-domain planning decisions that already belong with `EnableGraph`,
  - if not, pivot to the next truthful live runtime seam rather than continue declaration-specific convergence.
## 2026-03-14: EnableGraph unified WEN/EN emission ownership
- Continued the enable-synthesis ownership convergence by removing the remaining stage-7 backend routing wrapper around unified WEN/EN emission.
- Rationale:
  - the actual unified WEN/EN synthesis logic already lived in `EnableGraph::generate_unified_wen_en_signals(...)`,
  - `Backend::SystemVerilog::generate_wen_en_signals(...)` had become a thin active-path wrapper that only delegated to that owner,
  - the next small truthful move was therefore to route step 7 directly through `EnableGraph` and delete the wrapper.
- Structural outcome:
  - `Orchestrator` now sends stage-7 unified WEN/EN emission directly to `EnableGraph`,
  - `Backend::SystemVerilog` no longer carries the wrapper entrypoint,
  - the live boundary now matches the actual synthesis ownership more closely.
- Safety/compatibility:
  - no intended HDL behavior change; only the call path was shortened,
  - the architecture regression now locks the new boundary by asserting backend absence and `EnableGraph` ownership of the live entrypoint,
  - the full regression suite stayed green, so this convergence slice preserved active behavior.
- Verification:
  - syntax checks for `Orchestrator.pm` and `Backend/SystemVerilog.pm` pass,
  - focused architecture regression `t/10-ast-first-enable-structure.t` passes,
  - full regression remains green (`prove -I perl t` -> `Files=12`, `Tests=337`).
- Next likely slices:
  - re-audit whether any other active generation stage is still only routing to `EnableGraph` ownership through another module,
  - if not, pivot to the next truthful live runtime seam rather than continuing wrapper-only convergence.
## 2026-03-14: EnableGraph top-level enable emission ownership
- Continued the live enable-synthesis convergence by moving top-level state/DT enable emission under `EnableGraph`.
- Rationale:
  - after the previous slice, `state_enables` / `dt_enables` were already AST-backed and initialized by `EnableGraph`,
  - the backend still emitted those same registries through `generate_enable_conditions(...)`, which left a small but real split between semantic ownership and emission ownership on the active path,
  - the next truthful move was to let the same synthesis owner emit the top-level enable assigns as well.
- Structural outcome:
  - `EnableGraph::generate_enable_conditions(...)` now owns emission of `state_enables` / `dt_enables`,
  - `Orchestrator` now routes step 3 directly through `EnableGraph`,
  - `Backend::SystemVerilog` no longer carries that top-level enable-emission entrypoint.
- Safety/compatibility:
  - no intended change to emitted HDL text for the top-level `*_en` assigns,
  - the architecture regression now locks the new boundary explicitly: backend no longer owns the helper and `EnableGraph` does,
  - the full regression stayed green, so this ownership move preserved active generation behavior.
- Verification:
  - syntax checks for `EnableGraph.pm`, `Orchestrator.pm`, and `Backend/SystemVerilog.pm` pass,
  - focused regressions `t/10-ast-first-enable-structure.t` and `t/12-enablegraph-capture-registry.t` pass,
  - full regression remains green (`prove -I perl t` -> `Files=12`, `Tests=335`).
- Next likely slices:
  - re-audit whether any remaining top-level enable/declaration emission is still split away from the owner of the underlying synthesis data,
  - if not, pivot to the next truthful live seam elsewhere in the generation flow instead of forcing more enable-emission churn.
## 2026-03-13: AST-backed top-level enable registries on the live path
- Pivoted from the nearly exhausted `Orchestrator` ownership seam to the next real AST/CoreAST-first live boundary: the top-level `state_enables` / `dt_enables` registries.
- Rationale:
  - downstream enable synthesis was already AST-backed inside `assignment_analysis->{rhs_groups}`, but the top-level enable registries that seed `*_en` emission were still plain strings,
  - those registries are live state consumed during HDL generation, so leaving them string-backed kept an avoidable typed/untyped split in the active path,
  - the next truthful step was therefore to make top-level enable-condition construction AST-backed too, without changing registry keys or emitted HDL behavior.
- Structural outcome:
  - `EnableGraph::build_state_enable_condition_ast(...)` now constructs the regular-state `current_state == STATE` condition as AST,
  - `EnableGraph::build_dt_enable_condition_ast(...)` now constructs the standalone-DT always-enabled condition as AST,
  - `initialize_state_and_dt_enable_conditions(...)` now stores those AST values directly in `state_enables` / `dt_enables`,
  - `Backend::SystemVerilog::generate_enable_conditions(...)` now renders those registry entries from AST rather than assuming raw strings.
- Safety/compatibility:
  - emitted HDL stays behavior-identical for state and standalone-DT enable assigns,
  - the reset/reuse regression now locks that reused generators keep standalone DT enable entries AST-backed instead of drifting back to string state,
  - the architecture regression now locks that live top-level enable registries are typed AST state, not legacy string state.
- Verification:
  - syntax checks for `EnableGraph.pm` and `Backend/SystemVerilog.pm` pass,
  - focused regressions `t/10-ast-first-enable-structure.t`, `t/11-flatteneddt-generation-reset.t`, and `t/12-enablegraph-capture-registry.t` pass,
  - full regression remains green (`prove -I perl t` -> `Files=12`, `Tests=333`).
- Next likely slices:
  - re-audit whether any other live top-level enable/declaration registries are still string-backed without a semantic reason,
  - if that registry lane is exhausted, pivot again to the next truthful live runtime seam rather than forcing another representation-only change.
## 2026-03-13: EnableGraph test-condition AST ownership for live test-node traversal
- Continued the live `Orchestrator` / `EnableGraph` ownership convergence by moving the last inline test-node condition AST construction under `EnableGraph`.
- Rationale:
  - after the previous capture-focused slices, `EnableGraph` already owned condition conversion, test-value conversion, capture registration, and capture entrypoints,
  - `Orchestrator` still retained one narrow semantic responsibility inside `flatten_decision_tree(...)`: manually building the `signal == value` AST for `FSM::CoreAST::TestNode` branches,
  - the next small truthful move was to let the same owner that already interprets test values and later consumes the capture condition own that equality-AST construction too.
- Structural outcome:
  - `EnableGraph::build_test_condition_ast(...)` now owns test-signal-name normalization, value conversion, and `equals_op(...)` assembly for test branches,
  - `Orchestrator` now handles only traversal, isolated condition-stack copying, and recursion for test nodes,
  - this leaves test-branch semantic AST construction on one side of the boundary instead of split across modules.
- Safety/compatibility:
  - no intended change to generated HDL or capture semantics,
  - the focused capture regression now inspects the pre-factorization phase explicitly, which is the right place to lock this contract because later factorization intentionally rewrites condition ASTs into intermediate signal refs,
  - full regression remains green, so the owner move stayed behavior-preserving on the active path.
- Verification:
  - syntax checks for `EnableGraph.pm` and `Orchestrator.pm` pass,
  - focused regressions `t/12-enablegraph-capture-registry.t` and `t/10-ast-first-enable-structure.t` pass,
  - full regression remains green (`prove -I perl t` -> `Files=12`, `Tests=327`).
- Next likely slices:
  - re-audit whether any similarly coherent condition-stack-preparation seam still remains between `Orchestrator` and `EnableGraph`,
  - if not, pivot to the next truthful live runtime seam elsewhere in the generation flow instead of stretching this boundary further.
## 2026-03-13: EnableGraph capture-entrypoint ownership for live assignment capture
- Continued the live phase-1 ownership convergence by moving the assignment/transition capture entrypoints themselves under `EnableGraph`.
- Rationale:
  - after the previous slices, `EnableGraph` already owned capture-registry mutation, capture-shape normalization, and assignment-metadata normalization,
  - `Orchestrator` still retained the two top-level capture methods, but those had become thin shells over `EnableGraph`-owned semantics and registry writes,
  - the next small truthful step was therefore to move those entrypoints too and let `flatten_decision_tree(...)` delegate directly to the owner.
- Structural outcome:
  - `EnableGraph::capture_assignment_from_ast(...)` now owns assignment capture-time condition assembly, debug logging, metadata extraction, and registration,
  - `EnableGraph::capture_transition_from_ast(...)` now owns transition capture-time condition assembly, debug logging, and registration,
  - `Orchestrator` no longer carries local `record_assignment_from_ast(...)` / `record_transition_from_ast(...)` methods.
- Safety/compatibility:
  - no intended behavioral change to capture contents or emitted HDL,
  - the focused architecture test now locks the absence of those former helper names on the live `Orchestrator` object,
  - the live capture regression still passes, so the moved entrypoints preserve the active capture contract.
- Verification:
  - syntax checks for `EnableGraph.pm` and `Orchestrator.pm` pass,
  - focused regressions `t/10-ast-first-enable-structure.t` and `t/12-enablegraph-capture-registry.t` pass,
  - full regression remains green (`prove -I perl t` -> `Files=12`, `Tests=324`).
- Next likely slices:
  - re-audit the remaining `Orchestrator` / `EnableGraph` boundary to confirm whether any coherent capture-related ownership move is still left,
  - if not, shift to the next truthful live seam elsewhere in the active generation flow.
## 2026-03-13: EnableGraph assignment-metadata normalization for live assignment capture
- Continued the live phase-1 ownership convergence by moving assignment operator/intent/provenance normalization under `EnableGraph`.
- Rationale:
  - after the previous slices, `EnableGraph` already owned capture-registry mutation and capture-shape normalization, but `Orchestrator` still resolved operator metadata and assignment intent locally,
  - that metadata is part of the same capture contract later consumed by `EnableGraph` when building phase-1 analysis and signal-assignment behavior,
  - the next small truthful step was therefore to centralize assignment-metadata normalization in the same owner.
- Structural outcome:
  - `EnableGraph::extract_assignment_capture_metadata(...)` now owns operator resolution, pulse-operator derivation, strict validation, and normalization of `assignment_intent`, `source_provenance`, and `output_exposure`,
  - `Orchestrator::record_assignment_from_ast(...)` now delegates that normalization before registration,
  - the live capture contract is now more coherently owned by one module: `EnableGraph` owns capture registration, capture-shape normalization, and assignment-metadata normalization.
- Safety/compatibility:
  - no intended behavioral change to emitted HDL or assignment-family semantics,
  - the assignment-intent regression now also inspects the live capture registry after generation, which locks the key metadata preservation contract on representative assignment families,
  - full regression remains green, so the owner move stayed behavior-preserving on the active path.
- Verification:
  - syntax checks for `EnableGraph.pm` and `Orchestrator.pm` pass,
  - focused regressions `t/03-assignment-intent-metadata.t` and `t/12-enablegraph-capture-registry.t` pass,
  - full regression remains green (`prove -I perl t` -> `Files=12`, `Tests=322`).
- Next likely slices:
  - continue on the same live phase-1 seam,
  - if another coherent move remains, it is likely in the last direct `Orchestrator` knowledge of assignment-node traversal/capture preparation rather than in metadata ownership.
## 2026-03-13: EnableGraph capture-shape normalization for live assignment capture
- Continued the live phase-1 ownership convergence by moving the remaining LHS/RHS capture-shape normalization under `EnableGraph`.
- Rationale:
  - after the previous slice, `EnableGraph` already owned capture-registry mutation, but `Orchestrator` still derived the LHS key and RHS text locally before handing data off,
  - those normalization steps are part of the same capture-shape contract consumed later by `EnableGraph`, so leaving them in `Orchestrator` kept that seam wider than necessary,
  - the next small truthful move was therefore to migrate those owner-local normalizers too, while leaving traversal and operator validation in `Orchestrator`.
- Structural outcome:
  - `EnableGraph::extract_signal_name_from_ast(...)` now covers the leading-identifier fallback needed for capture-key normalization,
  - `EnableGraph::extract_rhs_capture_value(...)` now owns recursive RHS capture rendering,
  - `Orchestrator` no longer keeps separate local helpers for LHS-name and RHS-text extraction.
- Safety/compatibility:
  - no intended behavioral change to captured assignment metadata or emitted HDL,
  - the focused live-state regressions still pass, which confirms ordinary assignment capture, transition capture, and per-run reuse behavior remain intact after the owner move,
  - full regression remains green, so this normalization move stayed behavior-preserving on the active path.
- Verification:
  - syntax checks for `EnableGraph.pm` and `Orchestrator.pm` pass,
  - focused regressions `t/12-enablegraph-capture-registry.t` and `t/11-flatteneddt-generation-reset.t` pass,
  - full regression remains green (`prove -I perl t` -> `Files=12`, `Tests=314`).
- Next likely slices:
  - continue on the same live phase-1 seam,
  - the next small move is likely to narrow `Orchestrator`’s remaining direct knowledge of assignment-node intent/operator extraction if that can be localized without increasing behavior risk.
## 2026-03-13: EnableGraph capture-registry ownership for live assignment capture
- Continued the post-cleanup live refactor lane by moving captured assignment/transition registry mutation under `EnableGraph`.
- Rationale:
  - `Orchestrator` still performed direct writes into `lhs_assignments`, `all_lhs`, and `lhs_ast_map`, but those registries are semantically phase-1 analysis input later consumed by `EnableGraph`,
  - after the previous per-run reset slice, the next truthful structural step was to make `EnableGraph` own capture registration as well as later analysis,
  - this keeps traversal and semantic extraction in `Orchestrator`, but removes another piece of shared mutable state ownership from that layer.
- Structural outcome:
  - `EnableGraph::register_assignment_capture(...)` now owns registration of ordinary assignment capture metadata,
  - `EnableGraph::register_transition_capture(...)` now owns registration of synthetic `next_state` transition capture metadata and synthetic AST seeding,
  - `Orchestrator::record_assignment_from_ast(...)` and `record_transition_from_ast(...)` now delegate those writes after finishing their local AST/operator extraction work.
- Safety/compatibility:
  - no intended semantic change to capture contents or generated HDL behavior,
  - the new focused regression locks the live contract that both ordinary assignments and `next_state` transitions remain AST-backed in the capture registries,
  - full regression remains green, so the ownership move stayed behavior-preserving on the active path.
- Verification:
  - syntax checks for `EnableGraph.pm` and `Orchestrator.pm` pass,
  - focused regression `t/12-enablegraph-capture-registry.t` passes,
  - full regression remains green (`prove -I perl t` -> `Files=12`, `Tests=314`).
- Next likely slices:
  - continue through the remaining live phase-1 ownership seam instead of returning to wrapper cleanup,
  - the next small move is likely to reduce `Orchestrator`’s direct dependency on capture-shape details such as local RHS extraction or LHS-name derivation if those can be truthfully owned elsewhere.
## 2026-03-13: FlattenedDT per-run generation reset and enable-registry ownership
- Pivoted off the exhausted facade-pruning lane and back onto a live ownership seam in the generation path.
- Rationale:
  - the live `FlattenedDT` generation flow had several mutable registries that were initialized in `new(...)` but not reset before subsequent `generate_systemverilog(...)` calls, which left same-object reuse vulnerable to stale state,
  - the `state_enables` / `dt_enables` registries were also still populated in `Orchestrator` even though they function as enable-synthesis data consumed later by `EnableGraph` and the backend,
  - the smallest truthful slice was therefore to add an orchestrator-owned per-run reset and move enable-registry seeding under `EnableGraph`.
- Structural outcome:
  - `Orchestrator::reset_generation_state()` now clears the run-local generation registries before each live generation pass,
  - `EnableGraph::initialize_state_and_dt_enable_conditions(...)` now owns seeding of the state/DT enable registries,
  - `flatten_all_decision_trees(...)` remains responsible for traversal and AST assignment capture, not for initializing shared enable metadata.
- Safety/compatibility:
  - the generated HDL path is unchanged for single-run usage,
  - same-object reuse is now covered explicitly by a live regression that generates two different FSMs through one `FlattenedDT` instance and asserts no cross-run leakage survives,
  - this slice is therefore both a structural ownership improvement and a real correctness hardening for the active runtime.
- Verification:
  - syntax checks for `Orchestrator.pm` and `EnableGraph.pm` pass,
  - focused reuse regression `t/11-flatteneddt-generation-reset.t` passes,
  - full regression remains green (`prove -I perl t` -> `Files=11`, `Tests=296`).
- Next likely slices:
  - keep the wrapper-pruning lane closed unless a future audit finds genuinely dead supported surface,
  - continue with the next live `Orchestrator` / `EnableGraph` / backend ownership seam, likely wherever assignment-capture data or enable-structure state is still spread across modules more than necessary.
## 2026-03-13: FlattenedDT residual analysis/declaration facade delegate removal
- Continued AST/CoreAST-first cleanup by deleting the last residual analysis/declaration helper pocket from the `FlattenedDT` facade.
- Rationale:
  - a fresh repo-wide call-graph audit showed `generate_internal_signal_declarations(...)`, `get_lhs_width_from_analysis(...)`, `is_register(...)`, `fallback_register_analysis_from_assignments(...)`, `generate_intermediate_signals(...)`, `get_pulse_delay_cycles_for_lhs(...)`, `get_pulse_active_level_for_lhs(...)`, and `get_signal_info(...)` had no remaining callers on the `FlattenedDT` facade,
  - the matching methods remain live on `EnableGraph` or `Backend::SystemVerilog`, and the active flow already reaches them directly there,
  - `get_signal_assignment_type(...)` was intentionally left in place because the assignment-intent regression still treats it as part of the tested `FlattenedDT` surface.
- Safety/compatibility:
  - no active generation flow changed; the same analysis and declaration methods continue to run in the same owner modules as before,
  - the focused architecture regression now locks the absence of those helper names on live `FlattenedDT` objects,
  - this slice therefore shrinks dead facade surface without changing declaration emission, register analysis, pulse metadata handling, or HDL output.
- Verification:
  - syntax check for `FlattenedDT.pm` passes,
  - focused regression `t/10-ast-first-enable-structure.t` passes,
  - full regression remains green (`prove -I perl t` -> `Files=10`, `Tests=283`).
- Next likely slices:
  - treat the wrapper-pruning lane as exhausted unless a later audit finds new dead supported surface,
  - pivot back to the next live AST/CoreAST-first ownership seam.
## 2026-03-13: FlattenedDT dead backend factorization/substitution facade delegate removal
- Continued AST/CoreAST-first cleanup by deleting the remaining backend factorization/substitution helper pocket from the `FlattenedDT` facade.
- Rationale:
  - a fresh repo-wide call-graph audit showed `prescan_wen_en_for_intermediate_signals(...)`, `feed_asts_to_factorizer(...)`, `count_unary_negations_in_original_expressions(...)`, `ast_contains_signal(...)`, `update_original_asts_with_substituted_versions(...)`, `run_second_pass_factorization(...)`, `feed_current_asts_to_second_pass(...)`, `ast_contains_intermediate_signals(...)`, `ast_has_intermediate_signals_recursive(...)`, `update_original_asts_with_second_pass_substitutions(...)`, `get_substituted_ast_for_signal(...)`, `is_signal_referenced_in_substitutions(...)`, and `topologically_sort_signals(...)` had no remaining callers on the `FlattenedDT` facade,
  - the matching methods remain live inside `Backend::SystemVerilog`, and the active flow already reaches them there directly from `Orchestrator`, `FSM::HDL::Factorization::Fixpoint`, or backend-local calls,
  - keeping the `FlattenedDT` delegates therefore advertised another fake ownership boundary and an uncalled compatibility surface rather than a real supported entrypoint.
- Safety/compatibility:
  - no active generation flow changed; the same backend factorization/substitution methods continue to run in the same places as before,
  - the focused architecture regression now locks the absence of those helper names on live `FlattenedDT` objects,
  - this slice therefore shrinks dead facade surface without changing factorization passes, substitution behavior, or HDL output.
- Verification:
  - syntax check for `FlattenedDT.pm` passes,
  - focused regression `t/10-ast-first-enable-structure.t` passes,
  - full regression remains green (`prove -I perl t` -> `Files=10`, `Tests=275`).
- Next likely slices:
  - rerun the remaining facade audit and confirm whether any coherent dead wrapper pocket still remains,
  - if not, stop the cleanup lane and pivot back to the next live AST/CoreAST-first ownership seam.
## 2026-03-13: FlattenedDT dead utility/rendering facade delegate removal
- Continued AST/CoreAST-first cleanup by deleting a dead `EnableGraph` utility/rendering helper pocket from the `FlattenedDT` facade.
- Rationale:
  - a fresh repo-wide call-graph audit showed `generate_ast_based_signal_name(...)`, `extract_signal_name_from_ast(...)`, `map_operator_to_name(...)`, `is_arithmetic_operation(...)`, `is_logical_operation(...)`, `should_factor_logical_operation(...)`, `contains_frequently_used_operations(...)`, `get_driven_signals(...)`, `track_ast_intermediate_signals(...)`, `is_intermediate_signal(...)`, `is_signal_ast_based_intermediate(...)`, `_ast_contains_factorizable_operators(...)`, `_signal_name_indicates_ast_operators(...)`, `ast_to_systemverilog(...)`, `_ast_to_systemverilog_internal(...)`, `_render_binary_op(...)`, `_render_unary_op(...)`, `_choose_operator_symbol(...)`, `_operand_is_single_bit(...)`, `_signal_is_single_bit(...)`, `_get_operator_precedence(...)`, `_needs_parentheses(...)`, `_map_binary_operator(...)`, `_map_unary_operator(...)`, `_operand_needs_parens_for_negation(...)`, and `get_intermediate_signal_expression(...)` had no remaining callers on the `FlattenedDT` facade,
  - the matching methods remain live inside `EnableGraph`, so keeping the delegates on `FlattenedDT` advertised another fake ownership boundary and an uncalled compatibility surface rather than a real entrypoint,
  - `get_signal_assignment_type(...)` was intentionally left in place because the assignment-intent regression still treats it as part of the tested `FlattenedDT` surface.
- Safety/compatibility:
  - no active generation flow changed; the same `EnableGraph` utility/rendering methods continue to run in the same places as before,
  - the focused architecture regression now locks the absence of those helper names on live `FlattenedDT` objects,
  - the assignment-intent regression guards the remaining supported `get_signal_assignment_type(...)` seam,
  - this slice therefore shrinks dead facade surface without changing AST rendering, intermediate-signal tracking, or HDL output.
- Verification:
  - syntax check for `FlattenedDT.pm` passes,
  - focused regressions `t/03-assignment-intent-metadata.t` and `t/10-ast-first-enable-structure.t` pass,
  - full regression remains green (`prove -I perl t` -> `Files=10`, `Tests=262`).
- Next likely slices:
  - rerun the remaining facade audit and confirm whether any coherent dead wrapper pocket still remains,
  - if not, stop the cleanup lane and pivot back to the next live AST/CoreAST-first ownership seam.
## 2026-03-13: FlattenedDT dead orchestrator/backend facade pocket removal
- Continued AST/CoreAST-first cleanup by deleting a dead orchestrator/backend helper pocket from the `FlattenedDT` facade.
- Rationale:
  - a fresh repo-wide call-graph audit showed `flatten_all_decision_trees(...)`, `extract_lhs_name_from_ast(...)`, `flatten_decision_tree(...)`, `generate_header(...)`, `generate_module_declaration(...)`, `generate_state_encoding(...)`, `generate_state_register(...)`, `generate_enable_conditions(...)`, `generate_consolidated_intermediate_signals(...)`, `generate_wen_en_signals(...)`, `record_assignment_from_ast(...)`, `record_transition_from_ast(...)`, and `extract_rhs_from_expression(...)` had no remaining callers on the `FlattenedDT` facade,
  - the matching methods remain live and are now reached directly from `Orchestrator` or `backend_sv`,
  - keeping the facade delegates therefore advertised another fake ownership boundary and an uncalled compatibility surface rather than a real entrypoint.
- Safety/compatibility:
  - no active generation flow changed; the same orchestrator/backend methods continue to run in the same places as before,
  - the focused architecture regression now locks the absence of those helper names on live `FlattenedDT` objects,
  - this slice therefore shrinks dead facade surface without changing flattening, emission, or HDL output.
- Verification:
  - syntax check for `FlattenedDT.pm` passes,
  - focused regression `t/10-ast-first-enable-structure.t` passes,
  - full regression remains green (`prove -I perl t` -> `Files=10`, `Tests=236`).
- Next likely slices:
  - rerun the facade audit; if the remaining wrappers are only thin utility veneers with no compelling dead pocket left, stop the cleanup lane,
  - pivot back to the next live AST/CoreAST-first ownership seam.
## 2026-03-13: FlattenedDT dead EnableGraph facade delegate removal
- Continued AST/CoreAST-first cleanup by deleting a dead `EnableGraph`-owned helper pocket from the `FlattenedDT` facade.
- Rationale:
  - a fresh repo-wide call-graph audit showed `normalize_rhs_logic_level(...)`, `get_reset_value(...)`, `get_fsm_reset_state(...)`, `get_explicit_reset_value(...)`, `set_fsm_module_reference(...)`, `get_default_value_from_ast(...)`, `get_reset_value_from_ast(...)`, `get_default_value(...)`, `convert_condition_to_ast(...)`, and `convert_test_value_to_ast(...)` had no remaining callers on the `FlattenedDT` facade,
  - the matching methods remain live inside `EnableGraph` and are now reached directly from `EnableGraph` itself or from `Orchestrator`,
  - keeping the facade delegates therefore advertised another fake ownership boundary and an uncalled compatibility surface rather than a real entrypoint.
- Safety/compatibility:
  - no active generation flow changed; the same `EnableGraph` methods continue to run in the same places as before,
  - the focused architecture regression now locks the absence of those helper names on live `FlattenedDT` objects,
  - this slice therefore shrinks dead facade surface without changing reset/default behavior, AST conversion behavior, or HDL output.
- Verification:
  - syntax check for `FlattenedDT.pm` passes,
  - focused regression `t/10-ast-first-enable-structure.t` passes,
  - full regression remains green (`prove -I perl t` -> `Files=10`, `Tests=223`).
- Next likely slices:
  - rerun the final facade audit to confirm whether any meaningful dead delegates still remain,
  - if not, stop the cleanup lane and pivot back to the next live AST/CoreAST-first ownership seam.
## 2026-03-13: FlattenedDT dead logical-op facade delegate removal
- Continued AST/CoreAST-first cleanup by deleting a dead logical-operation helper delegate pocket from the `FlattenedDT` facade.
- Rationale:
  - a fresh repo-wide call-graph audit showed `run_global_ast_factorization(...)`, `collect_all_wen_en_ast_expressions(...)`, `count_binary_logical_operation_occurrences(...)`, `_count_logical_ops_in_ast(...)`, and `_is_factorizable_sub_expression(...)` had no remaining callers on the `FlattenedDT` facade,
  - the matching methods remain live inside `Backend::SystemVerilog` and still serve the orchestrated logical-operation counting/factorization path,
  - keeping the facade delegates therefore advertised another fake ownership boundary and an uncalled compatibility surface rather than a real entrypoint.
- Safety/compatibility:
  - no active generation flow changed; the backend and orchestrator continue to use those helpers internally in the same way as before,
  - the focused architecture regression now locks the absence of those helper names on live `FlattenedDT` objects,
  - this slice therefore shrinks dead facade surface without changing logical-op counting, factorization, or HDL output.
- Verification:
  - syntax check for `FlattenedDT.pm` passes,
  - focused regression `t/10-ast-first-enable-structure.t` passes,
  - full regression remains green (`prove -I perl t` -> `Files=10`, `Tests=213`).
- Next likely slices:
  - re-run the final facade audit to confirm whether any meaningful dead delegates still remain,
  - if not, pivot back to the next live AST/CoreAST-first ownership seam instead of continuing cleanup-only work.
## 2026-03-13: FlattenedDT dead filtering facade delegate removal
- Continued AST/CoreAST-first cleanup by deleting a dead filtering-helper delegate pocket from the `FlattenedDT` facade.
- Rationale:
  - a fresh repo-wide call-graph audit showed `should_filter_consolidated_signal(...)`, `should_filter_ast_based(...)`, `is_simple_negation(...)`, `is_simple_comparison(...)`, and `is_signal_actually_used_in_final_expressions(...)` had no remaining callers on the `FlattenedDT` facade,
  - the matching methods are still live inside `Backend::SystemVerilog`, but only as backend-local helpers used by the consolidated filtering path itself,
  - keeping the facade delegates therefore advertised a fake ownership boundary and an uncalled compatibility surface rather than a real supported entrypoint.
- Safety/compatibility:
  - no active generation flow changed; the backend continues to use those helpers internally in the same way as before,
  - the focused architecture regression now locks the absence of those helper names on live `FlattenedDT` objects,
  - this slice therefore shrinks dead facade surface without changing backend filtering behavior or HDL output.
- Verification:
  - syntax check for `FlattenedDT.pm` passes,
  - focused regression `t/10-ast-first-enable-structure.t` passes,
  - full regression remains green (`prove -I perl t` -> `Files=10`, `Tests=208`).
- Next likely slices:
  - run one more final facade/backend audit for any last dead delegates,
  - if nothing else is truly dead, pivot back to the next live AST/CoreAST-first ownership seam.
## 2026-03-13: FlattenedDT/backend dead mux/simple helper pocket removal
- Continued AST/CoreAST-first cleanup by deleting a dead mux/simple helper pocket from both the `FlattenedDT` facade and the backend owner side.
- Rationale:
  - a fresh repo-wide call-graph audit showed `is_simple_ast_expression(...)`, `generate_comb_mux(...)`, and `generate_flop_mux(...)` had no remaining callers anywhere in the active tree,
  - the two mux emitters still depended on the already-retired `lhs_to_enable_value_pairs` state, which made them clearly stranded compatibility code rather than a latent alternate backend path,
  - removing the facade delegates and backend implementations together is more honest than preserving an uncalled helper API for mux emission or AST simplicity classification.
- Safety/compatibility:
  - no active generation flow changed; live mux emission already runs through the unified/backend-owned paths used by `generate_wen_en_signals(...)` and related assignment-analysis structures,
  - the focused architecture regression now locks the absence of those helper names on both live `FlattenedDT` and live backend `SystemVerilog` objects,
  - this slice therefore shrinks dead facade/backend surface without widening any ownership seam or altering HDL output.
- Verification:
  - syntax checks for `FlattenedDT.pm` and `Backend/SystemVerilog.pm` pass,
  - focused regression `t/10-ast-first-enable-structure.t` passes,
  - full regression remains green (`prove -I perl t` -> `Files=10`, `Tests=203`).
- Next likely slices:
  - run one more narrow audit on the remaining `FlattenedDT` facade / backend delegate edge for any final dead wrapper residue,
  - if that audit is empty, pivot back to the next live AST/CoreAST-first ownership seam instead of stretching the cleanup lane.
## 2026-03-13: FlattenedDT/EnableGraph dead AST helper pocket removal
- Continued AST/CoreAST-first cleanup by deleting a dead AST helper pocket from both the `FlattenedDT` facade and the `EnableGraph` owner side.
- Rationale:
  - a fresh repo-wide call-graph audit showed `get_or_create_ast_signal_name(...)`, `canonicalize_expression(...)`, `is_complex_ast(...)`, `should_factor_ast(...)`, `analyze_ast_complexity(...)`, and `_traverse_ast_for_complexity(...)` had no remaining callers anywhere in the active tree,
  - the pocket was self-contained: `is_complex_ast(...)` and `_traverse_ast_for_complexity(...)` were only still reachable through the other already-dead helper names in that same cluster,
  - removing the entire pocket is more honest than preserving an uncalled AST naming/analysis API that no longer describes a live ownership boundary.
- Safety/compatibility:
  - no active generation flow changed; the live path no longer depends on this older AST helper cluster for intermediate naming, factorization policy, or complexity measurement,
  - the focused architecture regression now locks the absence of those helper names on both live `FlattenedDT` and live `EnableGraph` objects,
  - this slice therefore shrinks dead facade/owner surface without widening any ownership seam or altering HDL output.
- Verification:
  - syntax checks for `EnableGraph.pm` and `FlattenedDT.pm` pass,
  - focused regression `t/10-ast-first-enable-structure.t` passes,
  - full regression remains green (`prove -I perl t` -> `Files=10`, `Tests=197`).
- Next likely slices:
  - continue the narrow audit on the remaining `FlattenedDT` facade / backend edge for any last dead backend-owned wrapper pocket,
  - if that audit is empty, pivot back to the next live AST/CoreAST-first ownership seam instead of stretching the cleanup lane.
## 2026-03-13: FlattenedDT/backend dead sub-expression analysis helper removal
- Continued AST/CoreAST-first cleanup by deleting a small sub-expression-analysis pocket that had become dead on both the `FlattenedDT` facade and the backend owner side.
- Rationale:
  - a follow-up repo-wide call-graph audit showed `analyze_ast_sub_expressions(...)` had no remaining callers anywhere in the active tree,
  - `find_all_ast_sub_expressions(...)` only existed to serve that already-dead analysis entrypoint, so together they no longer described a real live boundary or backend service,
  - removing the facade delegates and backend implementations together is more honest than preserving an uncalled analysis API that the active logical-operation counting path does not use.
- Safety/compatibility:
  - no active generation flow changed; live logical-operation counting still runs through `collect_all_wen_en_ast_expressions(...)`, `_count_logical_ops_in_ast(...)`, `_is_factorizable_sub_expression(...)`, and `is_simple_ast_expression(...)`,
  - the focused architecture regression now locks the absence of the dead helper names on both live `FlattenedDT` and live backend `SystemVerilog` objects,
  - this slice therefore shrinks dead facade/backend surface without widening any ownership seam or altering HDL output.
- Verification:
  - syntax checks for `FlattenedDT.pm` and `Backend/SystemVerilog.pm` pass,
  - focused regression `t/10-ast-first-enable-structure.t` passes,
  - full regression remains green (`prove -I perl t` -> `Files=10`, `Tests=185`).
- Next likely slices:
  - run one more narrow audit of the remaining `FlattenedDT` facade / backend delegate edge for any final provably dead residue,
  - if that audit is empty, pivot back to the next live AST/CoreAST-first ownership seam instead of forcing more cleanup-only helper deletions.
## 2026-03-13: EnableGraph dead owner-only helper removal
- Continued AST/CoreAST-first cleanup by deleting a small helper pocket that had become dead even on the `EnableGraph` owner side.
- Rationale:
  - after the previous facade/orphan cleanup slices, a follow-up call-graph audit showed `get_or_create_global_expression(...)`, `should_factor_condition(...)`, `needs_parentheses(...)`, and `signal_uses_register_assignment(...)` had no remaining callers anywhere in the active tree,
  - these helpers no longer described a real boundary: the live flow already uses other paths for AST naming, factorization policy, parenthesis handling, and assignment-type classification,
  - removing the owner-only pocket is more honest than keeping uncalled helper implementations around just because they once anchored a compatibility lane.
- Safety/compatibility:
  - no active generation flow changed; all live registry, factorization, and mux classification logic already runs through other `EnableGraph` routines,
  - the focused architecture regression now locks the absence of those helper names on live `EnableGraph` objects,
  - this slice therefore shrinks dead owner surface without widening or relocating any live ownership seam.
- Verification:
  - syntax check for `EnableGraph.pm` passes,
  - focused regression `t/10-ast-first-enable-structure.t` passes,
  - full regression remains green (`prove -I perl t` -> `Files=10`, `Tests=181`).
- Next likely slices:
  - re-audit the remaining `FlattenedDT` / `EnableGraph` compatibility edge one more time for any final dead residue,
  - if that audit is empty, return to the next live AST/CoreAST-first ownership seam rather than continuing cleanup-only work.
## 2026-03-13: FlattenedDT/EnableGraph dead orphan helper removal
- Continued AST/CoreAST-first cleanup by deleting a small helper pocket that had become dead on both the `FlattenedDT` facade and the `EnableGraph` owner side.
- Rationale:
  - after the unified-helper delegate removal, a follow-up call-graph audit showed `create_condition_expression_signal_name(...)`, `set_explicit_reset_values(...)`, `parentheses_are_redundant(...)`, and `generate_expression_from_signal_name(...)` had no remaining callers anywhere in the active code or tests,
  - these names no longer described a live boundary: some were stale compatibility entrypoints on `FlattenedDT`, and the matching `EnableGraph` implementations were equally uncalled,
  - removing the whole orphan pocket is more honest than preserving dead owner methods after their facade delegates are gone.
- Safety/compatibility:
  - no active generation flow changed; all live condition construction, reset lookup, parenthesis handling, and intermediate-expression recovery already use other paths,
  - the focused architecture regression now locks the absence of those helper names on both live `FlattenedDT` and live `EnableGraph` objects,
  - this slice therefore shrinks the compatibility edge without widening any live ownership seam.
- Verification:
  - syntax checks for `EnableGraph.pm` and `FlattenedDT.pm` pass,
  - focused regression `t/10-ast-first-enable-structure.t` passes,
  - full regression remains green (`prove -I perl t` -> `Files=10`, `Tests=177`).
- Next likely slices:
  - continue re-auditing the remaining `FlattenedDT` / `EnableGraph` helper edge for any last dead residue,
  - if no more truly dead helper names remain, pivot back to the next live AST/CoreAST-first ownership seam instead of forcing more cleanup-only slices.
## 2026-03-13: FlattenedDT dead unified helper delegate removal
- Continued AST/CoreAST-first cleanup by deleting the dormant unified-analysis / unified-emission delegate pocket from `perl/FSM/HDL/FlattenedDT.pm`.
- Rationale:
  - after the earlier orchestrator and backend convergence slices, a fresh call-graph audit showed the live phase-1/2/3 path now goes directly through `Orchestrator` and `EnableGraph`, leaving the matching facade wrappers with no remaining callers,
  - the dead pocket included old unified analysis, enable-structure, WEN-generation, and mux-emission wrappers that no longer reflected a real ownership boundary,
  - removing the cluster as one slice is more honest than preserving an alternate helper-entry surface that the active runtime does not use.
- Safety/compatibility:
  - no active generation flow changed; `Orchestrator` still calls `enable_graph->build_unified_assignment_analysis(...)` and `enable_graph->generate_signal_assignments(...)` directly, and the backend still calls `enable_graph->generate_unified_wen_en_signals(...)` directly,
  - this slice only removes dead facade wrappers around already-localized `EnableGraph` ownership,
  - the focused architecture regression now locks the absence of the removed unified helper names on live `FlattenedDT` objects.
- Verification:
  - syntax check for `FlattenedDT.pm` passes,
  - focused regression `t/10-ast-first-enable-structure.t` passes,
  - full regression remains green (`prove -I perl t` -> `Files=10`, `Tests=169`).
- Next likely slices:
  - continue re-auditing the remaining `FlattenedDT` facade delegates for final dead surface that only mirrors direct owner calls,
  - if the facade cleanup lane runs out, return to the next smallest live AST/CoreAST-first ownership seam instead of forcing more dead-surface pruning.
## 2026-03-13: FlattenedDT dead signal-AST facade helper removal
- Continued AST/CoreAST-first cleanup by deleting the dormant `get_signal_ast_node(...)` helper from `perl/FSM/HDL/FlattenedDT.pm` and removing the facade-only imports it left behind.
- Rationale:
  - a fresh facade audit after the substituted-AST cleanup showed `get_signal_ast_node(...)` had no remaining callers anywhere in the active code or tests,
  - the helper was also anchored to a stale `fsm_module` slot on `FlattenedDT`, which is not part of the live orchestrator + `EnableGraph` path and therefore no longer represented a real source-of-truth boundary,
  - once the helper was removed, `FSM::GlobalASTManager`, `FSM::AST::Node`, and `FSM::CoreAST` became provably unused in the facade too, confirming this was isolated dead residue rather than a hidden live dependency.
- Safety/compatibility:
  - no active generation, factorization, or backend-emission path changed; all live signal/AST lookup continues to flow through `Orchestrator`, `EnableGraph`, and backend-owned helpers,
  - the focused architecture regression now locks the absence of the dead `get_signal_ast_node(...)` entrypoint on live `FlattenedDT` objects,
  - this slice therefore shrinks facade surface without widening any ownership boundary or altering HDL output.
- Verification:
  - syntax check for `FlattenedDT.pm` passes,
  - focused regression `t/10-ast-first-enable-structure.t` passes,
  - full regression remains green (`prove -I perl t` -> `Files=10`, `Tests=157`).
- Next likely slices:
  - continue re-auditing the remaining `FlattenedDT` delegates for any final dead surface, especially helpers whose backing state is already gone from the live path,
  - if no more truly dead residue remains, return to the next smallest live AST/CoreAST-first ownership seam instead of continuing cleanup-only facade pruning.
## 2026-03-13: FlattenedDT dead LHS/RHS completeness tracking removal
- Continued AST/CoreAST-first cleanup by deleting the dormant LHS/RHS completeness-tracking family from `perl/FSM/HDL/FlattenedDT.pm` and removing the last writes into that lane from `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`.
- Rationale:
  - after the earlier `track_actual_lhs_rhs()` ownership move, a fresh repo-wide audit showed the whole expected/actual/raw-AST completeness family had no live consumers left,
  - the only active path touching it was `Orchestrator` assignment/transition capture, which still wrote `actual_lhs_rhs` entries solely for a validation/reporting path that was never invoked,
  - keeping that bookkeeping around no longer improved safety; it only preserved dead surface area in the `FlattenedDT` facade.
- Safety/compatibility:
  - no active generation, enable synthesis, or backend lowering logic changed; this slice only removes dead validation/debug bookkeeping,
  - the live AST/CoreAST path remains the same: assignments and transitions still flow through `Orchestrator` into `lhs_assignments` / `assignment_analysis`,
  - the focused regression now locks the absence of the legacy `expected_lhs_rhs`, `actual_lhs_rhs`, and `missing_lhs_rhs` hashes after live generation.
- Verification:
  - syntax checks for `FlattenedDT.pm` and `Orchestrator.pm` pass,
  - focused regression `t/10-ast-first-enable-structure.t` passes,
  - full regression remains green (`prove -I perl t` -> `Files=10`, `Tests=155`).
- Next likely slices:
  - re-audit the remaining unreferenced `FlattenedDT` helper pockets, especially declaration-scheduling and substituted-AST matching helpers, to find the next truly dead surface,
  - keep preferring deletions of provably dead compatibility state over widening live backend/orchestrator behavior.
## 2026-03-13: FlattenedDT dead standalone declaration helper removal
- Continued AST/CoreAST-first cleanup by deleting the dormant standalone declaration helper lane from `perl/FSM/HDL/FlattenedDT.pm` and `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Rationale:
  - a follow-up repo-wide audit after the dead LHS/RHS-tracking slice showed the old standalone declaration entrypoint had no remaining callers anywhere on the active path,
  - the live declaration flow already emits intermediate wires through consolidated intermediate generation and the backend-owned `generate_internal_signal_declarations(...)` path,
  - leaving the old `schedule_intermediate_signal_for_declaration(...)` / `generate_intermediate_signal_declarations(...)` lane in place only preserved an untested alternate declaration shape and an unused scratch-state contract.
- Safety/compatibility:
  - no active emission ordering or declaration semantics changed; the removed lane was already bypassed by the live runtime path,
  - the adjacent `get_combinational_lhs_signals(...)` helper was removed in the same slice because it was part of the same dead declaration island and had no callers,
  - the focused regression now locks the absence of the old `intermediate_signals_to_declare` scratch state after live generation.
- Verification:
  - syntax checks for `FlattenedDT.pm` and `Backend/SystemVerilog.pm` pass,
  - focused regression `t/10-ast-first-enable-structure.t` passes,
  - full regression remains green (`prove -I perl t` -> `Files=10`, `Tests=156`).
- Next likely slices:
  - re-audit the remaining substituted-AST matching helper pocket in `FlattenedDT` to confirm whether it is now fully dead,
  - keep preferring deletions of provably dead compatibility helpers before taking broader live-path ownership moves.
## 2026-03-13: FlattenedDT dead substituted-AST matching helper removal
- Continued AST/CoreAST-first cleanup by deleting the dormant substituted-AST matching helper pocket from `perl/FSM/HDL/FlattenedDT.pm`.
- Rationale:
  - after the declaration-helper cleanup, a repo-wide audit showed the remaining canonical-expression/substituted-AST matching helpers were also fully unreferenced on the active path,
  - the real substitution/factorization flow now lives in backend-owned helpers, so keeping parallel matching heuristics in the `FlattenedDT` facade no longer added safety or functionality,
  - once those helpers were removed, the old `Data::Dumper`, `blessed`, `min`, and `max` imports became dead too, which confirmed the lane was self-contained residue rather than a hidden live dependency.
- Safety/compatibility:
  - no active substitution, factorization, or backend-emission logic changed; the removed helpers had no callers,
  - the still-live substitution surface remains backend-owned (`update_original_asts_with_substituted_versions(...)`, `get_substituted_ast_for_signal(...)`, `is_signal_referenced_in_substitutions(...)`),
  - this slice therefore shrinks the `FlattenedDT` facade without widening or relocating any live ownership boundary.
- Verification:
  - syntax check for `FlattenedDT.pm` passes,
  - full regression remains green (`prove -I perl t` -> `Files=10`, `Tests=156`).
- Next likely slices:
  - re-audit the remaining substitution-era helper surface to distinguish any final dead residue from the still-live backend-owned helpers,
  - if no more dead pockets remain nearby, return to the next smallest live AST/CoreAST-first ownership seam instead of forcing more facade-only cleanup.
## 2026-03-11: EnableGraph/SystemVerilog defining-AST metadata for consolidated filtering
- Continued backend convergence by carrying native defining-AST metadata forward on the consolidated intermediate-signal filtering path.
- Rationale:
  - after the previous slice moved dependency extraction from rendered strings to AST traversal, the next live friction point was not dependency discovery itself but the fact that some runtime paths could still reparse expression text even when a defining AST was already recoverable,
  - storing `defining_ast` alongside prescan-tracked intermediate references and centralizing backend AST resolution removes that unnecessary reparsing from the primary path.
- Safety/compatibility:
  - no public backend entrypoint or output-stage API changed; the slice only changes how the consolidated backend recovers a signal's defining AST internally,
  - `reference_ast` is now kept distinct from `defining_ast`, which makes the metadata model clearer and avoids confusing a use-site reference with the defining expression,
  - expression parsing remains only as a narrow fallback when no defining AST can be recovered from live AST-backed sources.
- Verification:
  - syntax checks for `EnableGraph.pm` and `Backend/SystemVerilog.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue shrinking the remaining expression-only compatibility cases on the consolidated path, especially where width/expression metadata is still synthesized without a stored defining AST,
  - keep revisiting larger registry/naming seams only when a live runtime dependency actually points there.
## 2026-03-11: EnableGraph/SystemVerilog AST-first intermediate dependency extraction
- Continued backend convergence by replacing a live string-based intermediate-dependency discovery path with AST traversal on the consolidated intermediate-signal flow.
- Rationale:
  - after re-scanning the runtime path instead of assuming the next seam from proximity alone, `get_or_create_global_expression()` turned out to be less live than expected for the current design,
  - the real active string dependency was in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, where dependency-aware filtering and debug tracing still identified referenced intermediate signals by scanning rendered expression text,
  - adding `EnableGraph::extract_intermediate_signals_from_ast()` made it possible to walk substituted and defining ASTs directly and keep dependency discovery on the AST/CoreAST side of the boundary.
- Safety/compatibility:
  - no public backend entrypoint or output-stage API changed; the slice only changes how referenced intermediate signals are discovered internally,
  - pre-scan referenced signals now carry defining ASTs into the consolidated intermediate-signal path when available, reducing later reparsing pressure,
  - `extract_intermediate_signals_from_expression()` still retains a narrow compatibility fallback for legacy cases that only expose string expressions and cannot be parsed back to ASTs.
- Verification:
  - syntax checks for `EnableGraph.pm` and `Backend/SystemVerilog.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue shrinking the remaining compatibility fallback cases where consolidated filtering still reparses or string-scans expression-only entries,
  - re-evaluate `get_or_create_global_expression()` only when a live runtime path actually depends on its current string-first behavior.
## 2026-03-11: EnableGraph AST-backed intermediate-signal registry metadata
- Continued backend convergence by converting the live intermediate-signal registry/lookup path in `perl/FSM/Synthesis/EnableGraph.pm` from string-backed ownership toward AST-backed metadata.
- Rationale:
  - after the logical-operation factor-detection slice, the next active string dependency was not another dormant helper in `FlattenedDT`, but the registry path that still stored intermediate-signal meaning primarily as strings and reparsed those strings later,
  - the new registry helpers let `intermediate_signals` carry `ast`, `expression`, `name`, and `source` together, so counting and lookup can prefer native AST ownership instead of reconstructing semantics from text,
  - this keeps the AST/CoreAST-first roadmap honest by converting a live semantic path rather than merely relocating more compatibility helpers.
- Safety/compatibility:
  - no public backend entrypoint or output-stage API changed; the slice only changes how intermediate-signal meaning is stored and recovered internally,
  - compatibility parsing still exists as a narrow fallback when legacy entries expose only an expression string and no defining AST yet,
  - `get_intermediate_signal_expression()` no longer reconstructs logic from signal-name patterns on the live path, which reduces one fragile string heuristic without widening scope into final-emitter rendering.
- Verification:
  - syntax checks for `EnableGraph.pm` and `Backend/SystemVerilog.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`),
  - the duplicate redeclaration warning introduced during the in-progress edit was removed before final validation.
- Next likely slices:
  - continue shrinking compatibility fallbacks around `get_or_create_global_expression()` and related registry seeding so new intermediate signals originate from ASTs more consistently,
  - then re-scan the remaining `FlattenedDT.pm` condition/value helper lane only when a slice removes a live string dependency rather than just moving string logic elsewhere.
## 2026-03-11: EnableGraph AST-first logical-operation factor detection
- Continued backend convergence by replacing the live logical-operation reuse heuristic in `perl/FSM/Synthesis/EnableGraph.pm` with AST-first traversal.
- Rationale:
  - after the roadmap update, the next truthful slice was no longer another nearby helper move from `FlattenedDT`, but the still-live factorization-decision path that rendered ASTs to strings and searched those strings for repeated logical-operation signatures,
  - the new implementation checks the AST tree directly, resolves intermediate-signal definitions back to ASTs where available, and only parses stored expressions as a narrow compatibility fallback,
  - this makes a real algorithmic path more AST/CoreAST-native without widening into the larger remaining string-helper pockets yet.
- Safety/compatibility:
  - no public backend entrypoint or output-stage API changed; the slice only changes how logical-operation reuse is detected internally,
  - `binary_logical_op_counts` still uses the existing signature map, so the behavior remains compatible with the current counting pipeline while the traversal itself is now AST-first,
  - compatibility parsing remains in place only when a defining AST is not yet stored in the relevant registries.
- Verification:
  - syntax check for `EnableGraph.pm` passes,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue replacing live compatibility fallbacks around intermediate-signal expression lookup with stored AST ownership,
  - re-evaluate the older `FlattenedDT.pm` condition/value helper lane only when the slice removes or bypasses string-based algorithmic handling rather than simply relocating it.
## 2026-03-11: FlattenedDT backend convergence (EnableGraph redundant-parentheses helper ownership)
- Continued backend convergence by finishing the in-flight parenthesis/sanitation helper lane and moving `parentheses_are_redundant()` from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Rationale:
  - after the `clean_intermediate_expression()` move, the remaining nearby helper pocket still did not expose a stronger live boundary than the already-open string-compatibility lane,
  - `parentheses_are_redundant()` was the smallest remaining helper in that lane, so moving it was the cleanest way to finish the in-flight slice,
  - this helper is still legacy string-oriented logic, and the user has now made clear that future work should pivot away from string-based algorithms and toward AST/CoreAST-native behavior.
- Safety/compatibility:
  - no HDL emission, factorization, or public entrypoint behavior changed; the helper logic stays the same,
  - `FlattenedDT` remains the compatibility shell and now forwards `parentheses_are_redundant()` to `EnableGraph`,
  - this slice should be treated as closure of an existing lane, not as justification for continuing string-helper relocation by default.
- Verification:
  - syntax checks for `EnableGraph.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - update the convergence roadmap so AST/CoreAST-first work selection is explicit,
  - re-scan remaining `FlattenedDT.pm` helpers for the next truthful slice that replaces string-based algorithmic handling with AST/CoreAST-native behavior, especially around `extract_condition_string()` and adjacent condition-formatting paths.
## 2026-03-11: FlattenedDT backend convergence (EnableGraph expression sanitation helper ownership)
- Continued backend convergence by moving the legacy string-expression sanitation helper from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Rationale:
  - after the `needs_parentheses()` slice, a fresh re-scan showed that the remaining nearby formatting and substitution pockets still did not expose a clearly stronger live boundary,
  - `clean_intermediate_expression()` was the next smallest self-contained helper in the same local string-sanitization lane,
  - moving it keeps the work incremental and honest: this slice reduces facade ownership a bit further without pretending that the remaining residue is more active than it currently appears.
- Safety/compatibility:
  - no HDL emission, factorization, or public entrypoint behavior changed; the helper logic stays the same,
  - `FlattenedDT` remains the compatibility shell and now forwards `clean_intermediate_expression()` to `EnableGraph`,
  - the remaining local helper pockets should still be re-scanned before assuming the next ownership move.
- Verification:
  - syntax checks for `EnableGraph.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - re-scan the remaining residual helper pockets in `FlattenedDT.pm`,
  - consider `parentheses_are_redundant()` or the older condition-formatting helpers only if they still present a similarly coherent ownership seam.
## 2026-03-11: FlattenedDT backend convergence (EnableGraph string parenthesis helper ownership)
- Continued backend convergence by moving the legacy string-expression parenthesis helper from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Rationale:
  - after the AST factorization-analysis move, the remaining nearby helper pocket was no longer uniformly coherent,
  - `needs_parentheses()` stood out as the smallest still-live formatting helper because it is directly used in `generate_dt_specific_wens()` when building DT-specific enable expressions,
  - moving only this helper preserved the micro-slice discipline and avoided widening into the older string-formatting cluster before confirming that cluster still reflects a meaningful compatibility boundary.
- Safety/compatibility:
  - no HDL emission, factorization, or public entrypoint behavior changed; the helper logic stays the same,
  - `FlattenedDT` remains the compatibility shell and now forwards `needs_parentheses()` to `EnableGraph`,
  - this slice keeps the broader string-formatting helpers in place until a later re-scan shows a coherent reason to move them.
- Verification:
  - syntax checks for `EnableGraph.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - re-scan the remaining nearby string-formatting helpers in `FlattenedDT.pm`,
  - consider `clean_intermediate_expression()` or the `format_condition()` / `format_signal_expression()` pair only if they still present a small, truthful ownership seam instead of a dormant cleanup target.
## 2026-03-11: FlattenedDT backend convergence (EnableGraph AST factorization-analysis helper ownership)
- Continued backend convergence by moving the AST-native factorization-analysis pair from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Rationale:
  - after the condition-factorization helper trio moved, `EnableGraph::should_factor_condition()` still documented `should_factor_ast()` as the preferred AST path even though `should_factor_ast()` and `is_complex_ast()` remained in the facade,
  - that made the AST-native factorization lane the next smallest coherent ownership pocket in the same area,
  - moving the pair keeps both condition-string and AST-native factorization decisions under the same synthesis-helper owner without widening into broader dormant formatting cleanup.
- Safety/compatibility:
  - no HDL emission, factorization, or public entrypoint behavior changed; the helper logic stays the same,
  - `FlattenedDT` remains the compatibility shell and now forwards this AST factorization-analysis pair to `EnableGraph`,
  - the move also makes the existing `EnableGraph` comment about preferring `should_factor_ast()` true at the ownership boundary instead of only at the compatibility boundary.
- Verification:
  - syntax checks for `EnableGraph.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - re-scan the remaining nearby legacy expression-formatting helpers in `FlattenedDT.pm`, with `needs_parentheses()` now the most plausible next small seam,
  - only pull in adjacent formatting helpers such as `clean_intermediate_expression()` if they form an equally coherent ownership block.
## 2026-03-11: FlattenedDT backend convergence (EnableGraph legacy condition-factorization helper ownership)
- Continued backend convergence by moving the legacy condition-factorization helper trio from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Rationale:
  - after the global-expression registry helper move, the next smallest coherent pocket in the same local lane was the condition-factorization trio: `should_factor_condition()`, `analyze_ast_complexity()`, and `_traverse_ast_for_complexity()`,
  - these helpers are about deciding when enable-condition expressions should be factored, so they fit the `EnableGraph` synthesis-helper role better than the `FlattenedDT` compatibility shell,
  - taking this slice continues the local ownership reduction without broadening into larger dormant helper families.
- Safety/compatibility:
  - no HDL emission, factorization, or public entrypoint behavior changed; the helper logic stays the same,
  - `FlattenedDT` remains the compatibility shell and now forwards this helper trio to `EnableGraph`,
  - this slice keeps the same registry/context access pattern through `flattened_dt`, so behavior remains unchanged.
- Verification:
  - syntax checks for `EnableGraph.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - re-scan the remaining nearby legacy expression/factorization helpers in `FlattenedDT.pm`, especially `needs_parentheses()` and adjacent formatting helpers,
  - keep avoiding broad dormant cleanup unless it clearly reduces a real compatibility boundary.
## 2026-03-10: FlattenedDT backend convergence (EnableGraph global-expression registry helper ownership)
- Continued backend convergence by moving the adjacent global-expression registry helper pair from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Rationale:
  - after the AST signal-naming helper move, the next smallest coherent pocket was the neighboring global-expression registry pair: `get_or_create_global_expression()` and `canonicalize_expression()`,
  - these helpers mutate the same shared registries already used by `EnableGraph`, so leaving them in the facade would keep unnecessary ownership in `FlattenedDT`,
  - taking this slice continues the local ownership reduction in the same registry/naming area without widening into broader legacy factorization cleanup.
- Safety/compatibility:
  - no HDL emission, factorization, or public entrypoint behavior changed; the helper logic and registry mutations stay the same,
  - `FlattenedDT` remains the compatibility shell and now forwards this helper pair to `EnableGraph`,
  - this slice continues ownership reduction rather than reviving dormant helper families that are not yet worth broader restructuring.
- Verification:
  - syntax checks for `EnableGraph.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - re-scan the remaining nearby legacy expression/factorization helpers in `FlattenedDT.pm` for the next smallest coherent owner,
  - keep avoiding broad dormant cleanup unless it clearly reduces a real compatibility boundary.
## 2026-03-10: FlattenedDT backend convergence (EnableGraph AST signal-naming helper ownership)
- Continued backend convergence by moving the AST signal-naming helper cluster from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Rationale:
  - the earlier `EnableGraph.pm` line-1105 lead turned out to be comment-only rather than a live callsite, so the next truthful seam was not another runtime round-trip,
  - the smallest coherent ownership pocket nearby was the AST signal-naming cluster: `create_condition_expression_signal_name()`, `get_or_create_ast_signal_name()`, `generate_ast_based_signal_name()`, and `map_operator_to_name()`,
  - those helpers operate on the same global-expression / intermediate-signal registries already shared through `EnableGraph`, so moving them there reduces facade ownership without changing runtime semantics.
- Safety/compatibility:
  - no HDL emission, factorization, or public entrypoint behavior changed; the helper logic and registry mutations stay the same,
  - `FlattenedDT` remains the compatibility shell and now forwards this helper cluster to `EnableGraph`,
  - this slice is ownership reduction rather than active callsite convergence, which is appropriate now that the obvious live round-trips in the previous lane were exhausted.
- Verification:
  - syntax checks for `EnableGraph.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - re-scan the remaining non-delegate utility pockets in `FlattenedDT.pm` for the next small coherent owner, especially nearby AST-support / legacy factorization helpers,
  - avoid broad dormant cleanup unless it clearly reduces a real compatibility boundary.
## 2026-03-10: FlattenedDT backend convergence (Verilog backend SystemVerilog-entry callsite convergence)
- Continued backend convergence by localizing the live `generate_systemverilog()` call in `perl/FSM/HDL/FlattenedDT/Backend/Verilog.pm` away from the `FlattenedDT` facade and onto `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`.
- Rationale:
  - after the `Fixpoint` second-pass lane was exhausted, the next smallest live facade round-trip surfaced at the Verilog backend entrypoint,
  - `generate_systemverilog()` ownership already lives in `Orchestrator.pm`, so this is a narrow call-path correction with no semantic broadening,
  - taking this slice keeps the convergence stream focused on active runtime flow instead of dormant delegate cleanup.
- Safety/compatibility:
  - no SystemVerilog generation or Verilog conversion semantics changed; only the active call path changed,
  - `FlattenedDT` remains the compatibility shell and its `generate_systemverilog()` delegate stays available,
  - the next step should come from a fresh orchestrator/facade re-scan rather than assuming another adjacent live caller.
- Verification:
  - syntax checks for `Backend/Verilog.pm`, `Orchestrator.pm`, and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - re-scan the broader orchestrator/facade boundary for the next live round-trip now that the Verilog backend entry has been localized,
  - keep preferring live convergence over dormant delegate cleanup in `FlattenedDT.pm`.
## 2026-03-10: FlattenedDT backend convergence (Fixpoint second-pass update callsite convergence)
- Continued backend convergence by localizing the live `update_original_asts_with_second_pass_substitutions()` call in `perl/FSM/HDL/Factorization/Fixpoint.pm` away from the `FlattenedDT` facade and onto `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Rationale:
  - after the prior feed-call slice, the adjacent update call became the next smallest live round-trip in the same `Fixpoint` pass loop,
  - helper ownership for `update_original_asts_with_second_pass_substitutions()` already lives in the SystemVerilog backend, so this is another narrow call-path correction rather than a behavioral change,
  - taking it now exhausts the direct `Fixpoint` second-pass round-trip lane without broadening scope into dormant delegates.
- Safety/compatibility:
  - no fixpoint, factorization, or AST-update semantics changed; only the active call path changed,
  - `FlattenedDT` remains the compatibility shell and its `update_original_asts_with_second_pass_substitutions()` delegate stays available,
  - the next slice should come from a fresh re-scan rather than assuming more live work remains in this lane.
- Verification:
  - syntax checks for `Fixpoint.pm`, `SystemVerilog.pm`, and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - re-scan the broader factorization/backend facade boundaries for the next live round-trip now that the direct `Fixpoint` second-pass lane is exhausted,
  - keep preferring live convergence over dormant delegate cleanup in `FlattenedDT.pm`.
## 2026-03-10: FlattenedDT backend convergence (Fixpoint second-pass feed callsite convergence)
- Continued backend convergence by localizing the live `feed_current_asts_to_second_pass()` call in `perl/FSM/HDL/Factorization/Fixpoint.pm` away from the `FlattenedDT` facade and onto `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Rationale:
  - after the prescan tracking slice, the smallest remaining live second-pass round-trip was the AST-feeding call at the top of the fixpoint pass loop,
  - helper ownership for `feed_current_asts_to_second_pass()` already lives in the SystemVerilog backend, so this is a narrow call-path correction rather than a behavior change,
  - taking it before the adjacent update call keeps the micro-slice discipline intact and preserves the ability to validate each second-pass boundary independently.
- Safety/compatibility:
  - no fixpoint, factorization, or render semantics changed; only the active call path changed,
  - `FlattenedDT` remains the compatibility shell and its `feed_current_asts_to_second_pass()` delegate stays available,
  - the adjacent `update_original_asts_with_second_pass_substitutions()` round-trip is intentionally left for the next slice.
- Verification:
  - syntax checks for `Fixpoint.pm`, `SystemVerilog.pm`, and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - localize the matching `update_original_asts_with_second_pass_substitutions()` call in `Fixpoint.pm`,
  - then re-scan for any remaining live second-pass round-trips before considering dormant delegate cleanup.
## 2026-03-10: FlattenedDT backend convergence (SystemVerilog prescan intermediate-tracking callsite convergence)
- Continued backend convergence by localizing the two live `track_ast_intermediate_signals()` callsites in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` away from the `FlattenedDT` facade and onto `perl/FSM/Synthesis/EnableGraph.pm`.
- Rationale:
  - after the `Fixpoint` AST-rendering slice, the smallest remaining live facade round-trip was no longer AST rendering but intermediate-tracking during the WEN/EN pre-scan stage,
  - `prescan_wen_en_for_intermediate_signals()` had exactly two such calls, both already compatible with the established `EnableGraph` ownership of `track_ast_intermediate_signals()`,
  - taking this slice keeps the convergence stream focused on active backend flow rather than dormant compatibility cleanup.
- Safety/compatibility:
  - no pre-scan or intermediate-signal semantics changed; only the active call path changed,
  - `FlattenedDT` remains the compatibility shell and no delegates were removed,
  - the backend continues to rely on `flattened_dt` for orchestration state while calling `EnableGraph` directly for this helper.
- Verification:
  - syntax checks for `SystemVerilog.pm`, `EnableGraph.pm`, and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - inspect `perl/FSM/HDL/Factorization/Fixpoint.pm` for the remaining live second-pass helper round-trips through `FlattenedDT`, especially `feed_current_asts_to_second_pass(...)` and `update_original_asts_with_second_pass_substitutions(...)`,
  - keep preferring narrow callsite convergence over dormant delegate removal.
## 2026-03-10: FlattenedDT backend convergence (Factorization Fixpoint AST-to-SV callsite convergence)
- Continued backend convergence by localizing the remaining non-local `ast_to_systemverilog()` callsites in `perl/FSM/HDL/Factorization/Fixpoint.pm` away from the `FlattenedDT` facade and onto `perl/FSM/Synthesis/EnableGraph.pm`.
- Rationale:
  - after the binary-support helper lane closed, the next truthful seam was no longer helper ownership but a live render/factorization callsite still routing through `FlattenedDT`,
  - `Fixpoint.pm` had exactly two such users, both debug/signature oriented and both already compatible with the established `EnableGraph` entrypoint,
  - taking this slice reduces a real facade dependency without widening scope into the remaining internal `FlattenedDT` render helpers.
- Safety/compatibility:
  - no factorization or render semantics changed; only the active call path for AST-to-SystemVerilog conversion changed,
  - `FlattenedDT` remains the compatibility shell and no delegates were removed,
  - `Fixpoint` continues to depend on `flattened_dt` for orchestration-only methods while using `EnableGraph` directly for render entry.
- Verification:
  - syntax checks for `Fixpoint.pm`, `EnableGraph.pm`, and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - inspect remaining canonical-expression / AST-render round-trips inside `FlattenedDT.pm`, especially `find_substituted_ast()` and nearby expression-matching utilities,
  - keep preferring narrow callsite convergence over dormant delegate removal.
## 2026-03-09: FlattenedDT backend convergence (EnableGraph binary operator-selection helper ownership)
- Continued backend convergence by moving `_choose_operator_symbol()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Rationale:
  - after `_operand_is_single_bit()` moved, `_choose_operator_symbol()` became the last remaining helper in the binary-support cluster beneath `_render_binary_op()`,
  - its remaining dependencies (`_operand_is_single_bit()`, `_map_binary_operator()`, `extract_signal_name_from_ast()`, and FSM-module metadata through `flattened_dt`) are now all locally reachable from `EnableGraph`,
  - taking it now completes the helper-ownership localization of the binary render-support lane without changing the external `FlattenedDT` compatibility boundary.
- Safety/compatibility:
  - no binary render semantics changed; only helper ownership and compatibility delegation changed,
  - `FlattenedDT` now forwards `_choose_operator_symbol()` to `EnableGraph`,
  - `EnableGraph` imports `List::Util::min` so the copied debug-path signal listing remains behavior-preserving.
- Verification:
  - syntax checks for `EnableGraph.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - the binary-support helper lane is now exhausted, so re-scan the remaining render-cluster / facade-boundary seams for the next smallest truthful slice,
  - keep `FlattenedDT` as the compatibility facade while continuing behavior-preserving ownership reduction.
## 2026-03-09: FlattenedDT backend convergence (EnableGraph binary operand-width helper ownership)
- Continued backend convergence by moving `_operand_is_single_bit()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Rationale:
  - after `_signal_is_single_bit()` moved, `_operand_is_single_bit()` became the next truthful helper in the same operand-analysis lane,
  - its recursive logic now depends only on local `EnableGraph` helpers and AST inspection, so it fits the micro-slice rule cleanly,
  - taking it now leaves `_choose_operator_symbol()` as the final remaining helper in the binary operator-selection boundary.
- Safety/compatibility:
  - no binary render semantics changed; only helper ownership and compatibility delegation changed,
  - `FlattenedDT` now forwards `_operand_is_single_bit()` to `EnableGraph`,
  - `_choose_operator_symbol()` remains the next and likely final binary-support helper in this render cluster lane.
- Verification:
  - syntax checks for `EnableGraph.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - re-evaluate `_choose_operator_symbol()` as the next truthful binary-support seam now that operand-width analysis is local,
  - keep the compatibility facade in `FlattenedDT` intact while localizing that final operator-selection helper.
## 2026-03-09: FlattenedDT backend convergence (EnableGraph binary signal-width helper ownership)
- Continued backend convergence by moving `_signal_is_single_bit()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Rationale:
  - after `_map_binary_operator()` moved, `_signal_is_single_bit()` became the next smallest truthful helper feeding the remaining operand-analysis lane,
  - its behavior is locally self-contained apart from FSM-module metadata access and `is_intermediate_signal()`, both of which are already reachable from `EnableGraph`,
  - retargeting the FSM-module lookup through `$self->{flattened_dt}` keeps the move behavior-preserving while shrinking the support boundary under `_operand_is_single_bit()`.
- Safety/compatibility:
  - no binary render semantics changed; only helper ownership and compatibility delegation changed,
  - `FlattenedDT` now forwards `_signal_is_single_bit()` to `EnableGraph`,
  - `_operand_is_single_bit()` and `_choose_operator_symbol()` remain as the next helpers in the heavier operand-analysis/operator-selection lane.
- Verification:
  - syntax checks for `EnableGraph.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - move `_operand_is_single_bit()` as the next truthful binary-support seam now that `_signal_is_single_bit()` is local,
  - then re-evaluate `_choose_operator_symbol()` once operand-width analysis is fully localized.
## 2026-03-09: FlattenedDT backend convergence (EnableGraph binary operator-mapping helper ownership)
- Continued backend convergence by moving `_map_binary_operator()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Rationale:
  - after `_get_operator_precedence()` moved, `_map_binary_operator()` became the next smallest fully isolated binary-support seam,
  - its logic is another self-contained lookup table with no external dependencies, making it a truthful micro-slice,
  - taking it now reduces the support surface feeding `_choose_operator_symbol()` before entering the heavier bit-width analysis helpers.
- Safety/compatibility:
  - no binary render semantics changed; only helper ownership and compatibility delegation changed,
  - `FlattenedDT` now forwards `_map_binary_operator()` to `EnableGraph`,
  - `_signal_is_single_bit()`, `_operand_is_single_bit()`, and `_choose_operator_symbol()` remain as the next helpers in the heavier binary-support lane.
- Verification:
  - syntax checks for `EnableGraph.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - re-evaluate `_signal_is_single_bit()` as the next smallest binary-support seam because `_operand_is_single_bit()` depends on it,
  - then move `_operand_is_single_bit()` before revisiting `_choose_operator_symbol()`.
## 2026-03-09: FlattenedDT backend convergence (EnableGraph binary precedence helper ownership)
- Continued backend convergence by moving `_get_operator_precedence()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Rationale:
  - after `_needs_parentheses()` moved, `_get_operator_precedence()` was the smallest fully isolated binary-support seam,
  - its logic is a self-contained lookup table with no external dependencies, making it zero-risk,
  - taking it now further shrinks the compatibility boundary without disturbing the heavier operator-selection or bit-width analysis helpers.
- Safety/compatibility:
  - no binary render semantics changed; only helper ownership and compatibility delegation changed,
  - `FlattenedDT` now forwards `_get_operator_precedence()` to `EnableGraph`,
  - `_choose_operator_symbol()` and `_operand_is_single_bit()` remain as the next binary-support delegates on the heavier path.
- Verification:
  - syntax checks for `EnableGraph.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - re-evaluate `_choose_operator_symbol()` as the next binary-support seam (depends on `_operand_is_single_bit()` and `_map_binary_operator()`),
  - alternatively, move `_operand_is_single_bit()` first if it proves more isolated.
## 2026-03-09: FlattenedDT backend convergence (EnableGraph binary parenthesis-decision helper ownership)
- Continued backend convergence by moving `_needs_parentheses()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Rationale:
  - after `_render_binary_op()` moved, `_needs_parentheses()` was the smallest fully isolated binary-support seam,
  - its logic is self-contained and policy-only, making it a lower-risk slice than the remaining operator-selection or bit-width analysis helpers,
  - taking it now further shrinks the compatibility boundary without disturbing the heavier binary-analysis path.
- Safety/compatibility:
  - no binary render semantics changed; only helper ownership and compatibility delegation changed,
  - `FlattenedDT` now forwards `_needs_parentheses()` to `EnableGraph`,
  - `_get_operator_precedence()` remains the next isolated binary-support delegate, while `_choose_operator_symbol()` and `_operand_is_single_bit()` stay on the heavier path for now.
- Verification:
  - syntax checks for `EnableGraph.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - move `_get_operator_precedence()` as the next smallest binary-support seam,
  - then re-evaluate `_choose_operator_symbol()` together with the adjacent bit-width analysis helpers.
## 2026-03-09: FlattenedDT backend convergence (EnableGraph binary AST-to-SV render helper ownership)
- Continued backend convergence by moving `_render_binary_op()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Rationale:
  - with the unary-render lane complete, `_render_binary_op()` became the next truthful entry seam into the remaining binary-render cluster,
  - moving the entrypoint first keeps the ownership shift aligned with the active runtime path,
  - the helper has a broader dependency surface than the unary path, so this slice keeps the move behavior-preserving via narrow bridges rather than pulling the whole operator-selection cluster at once.
- Safety/compatibility:
  - no binary render semantics changed; only helper ownership and compatibility delegation changed,
  - `FlattenedDT` now forwards `_render_binary_op()` to `EnableGraph`,
  - `EnableGraph` temporarily forwards `_get_operator_precedence()`, `_choose_operator_symbol()`, `_needs_parentheses()`, and `_operand_is_single_bit()` back to `FlattenedDT`, preserving the existing binary render behavior while shrinking the facade boundary.
- Verification:
  - syntax checks for `EnableGraph.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue with the smallest isolated binary-support helpers, most likely `_get_operator_precedence()` and/or `_needs_parentheses()` before `_choose_operator_symbol()`,
  - keep deferring the larger operator-selection and bit-width analysis helpers until those smaller seams are exhausted.
## 2026-03-09: FlattenedDT backend convergence (EnableGraph unary negation parenthesization helper ownership)
- Continued backend convergence by moving `_operand_needs_parens_for_negation()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Rationale:
  - after `_map_unary_operator()` moved, this became the last isolated unary-support seam,
  - its logic is self-contained and only governs unary negation formatting policy,
  - taking it now cleanly completes the unary-render support lane before re-entering the larger binary-render cluster.
- Safety/compatibility:
  - no unary rendering semantics changed; only helper ownership and compatibility delegation changed,
  - `FlattenedDT` now forwards `_operand_needs_parens_for_negation()` to `EnableGraph`,
  - the binary-render path remains untouched in this slice.
- Verification:
  - syntax checks for `EnableGraph.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - unary-support delegates are now exhausted,
  - re-scan `_render_binary_op()` together with its adjacent precedence/operator helpers for the next truthful micro-slice in the render cluster.
## 2026-03-09: FlattenedDT backend convergence (EnableGraph unary operator mapping helper ownership)
- Continued backend convergence by moving `_map_unary_operator()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Rationale:
  - after `_render_unary_op()` moved, `_map_unary_operator()` became the smallest fully isolated unary-support seam,
  - it has no remaining runtime dependencies beyond its own tiny mapping table,
  - taking it before `_operand_needs_parens_for_negation()` keeps the convergence cadence maximally small and low-risk.
- Safety/compatibility:
  - no unary rendering semantics changed; only helper ownership and compatibility delegation changed,
  - `FlattenedDT` now forwards `_map_unary_operator()` to `EnableGraph`,
  - `_operand_needs_parens_for_negation()` remains delegated from `EnableGraph` back to `FlattenedDT` until its own slice.
- Verification:
  - syntax checks for `EnableGraph.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - move `_operand_needs_parens_for_negation()` as the last unary-support helper seam,
  - then re-scan the larger `_render_binary_op()` / operator-selection cluster for the next truthful micro-slice.
## 2026-03-09: FlattenedDT backend convergence (EnableGraph unary AST-to-SV render helper ownership)
- Continued backend convergence by moving `_render_unary_op()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Rationale:
  - after `_ast_to_systemverilog_internal()` moved, unary rendering became the smallest adjacent live helper seam,
  - `_render_unary_op()` has a compact dependency surface and only needed two narrow bridges (`_map_unary_operator()` and `_operand_needs_parens_for_negation()`),
  - this keeps the micro-slice discipline intact instead of jumping directly into the much larger `_render_binary_op()` / operator-selection cluster.
- Safety/compatibility:
  - no unary render semantics changed; only helper ownership and compatibility delegation changed,
  - `FlattenedDT` now forwards `_render_unary_op()` to `EnableGraph`,
  - `EnableGraph` temporarily forwards `_map_unary_operator()` and `_operand_needs_parens_for_negation()` back to `FlattenedDT`, preserving existing formatting behavior while shrinking the facade boundary.
- Verification:
  - syntax checks for `EnableGraph.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue with the now-isolated unary-support helpers, most likely `_map_unary_operator()` before `_operand_needs_parens_for_negation()`,
  - keep deferring the broader binary/operator-precedence render cluster until these smaller seams are exhausted.
## 2026-03-09: FlattenedDT backend convergence (EnableGraph AST-to-SV internal helper ownership)
- Continued backend convergence by moving `_ast_to_systemverilog_internal()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Rationale:
  - the prior slice localized the active `ast_to_systemverilog()` entrypoint without yet moving the recursive dispatcher itself,
  - `_ast_to_systemverilog_internal()` was the next smallest truthful ownership seam because it depends directly on already-local `EnableGraph` rendering entrypoints and only needs temporary bridges for the two adjacent render helpers,
  - moving `_render_binary_op()` or the broader operator/precedence family first would have been a larger slice.
- Safety/compatibility:
  - no render semantics changed; only helper ownership and compatibility delegation changed,
  - `FlattenedDT` now forwards `_ast_to_systemverilog_internal()` to `EnableGraph`,
  - `EnableGraph` temporarily forwards `_render_binary_op()` and `_render_unary_op()` back to `FlattenedDT`, preserving the existing recursive render behavior while shrinking the facade boundary one step at a time.
- Verification:
  - syntax checks for `EnableGraph.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue with the smallest adjacent render helper still round-tripping through `FlattenedDT`, most likely `_render_unary_op()` before the larger `_render_binary_op()` flow,
  - keep deferring the broader operator/precedence helper family until there is a smaller truthful entry seam for it.
## 2026-03-09: FlattenedDT backend convergence (EnableGraph AST-to-SV internal delegate callsite convergence)
- Continued backend convergence by localizing the `ast_to_systemverilog()` render-internal callsite in `perl/FSM/Synthesis/EnableGraph.pm` away from a direct `FlattenedDT` object method call.
- Rationale:
  - the previous `EnableGraph` self-owned round-trip lane was exhausted,
  - a full ownership move for `_ast_to_systemverilog_internal()` would immediately pull in a larger render-helper family (`_render_binary_op()`, `_render_unary_op()`, precedence helpers, operator-selection helpers), which is too large for the current micro-slice discipline,
  - introducing an `EnableGraph` compatibility delegate keeps the active entrypoint local without forcing that larger move yet.
- Safety/compatibility:
  - no render logic changed; only the active runtime call path changed,
  - `EnableGraph` now exposes `_ast_to_systemverilog_internal()` as a compatibility delegate to the existing `FlattenedDT` implementation,
  - no intended semantic change to AST rendering, operator choice, precedence handling, or emitted HDL behavior.
- Verification:
  - syntax checks for `EnableGraph.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - if this render-boundary lane continues, the next truthful seam is the `_ast_to_systemverilog_internal()` helper family itself together with its adjacent render helpers,
  - keep preferring behavior-preserving slices over broad render-cluster moves.
## 2026-03-09: FlattenedDT backend convergence (EnableGraph LHS-enable intermediate tracking callsite convergence)
- Continued backend convergence by localizing the `track_ast_intermediate_signals()` callsite in `perl/FSM/Synthesis/EnableGraph.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` self ownership.
- Rationale:
  - helper ownership for `track_ast_intermediate_signals()` already lives in `EnableGraph`,
  - after the phase-1 `build_unified_assignment_analysis()` helper-family cleanup, this was the last same-pattern direct self-owned round-trip still active inside `EnableGraph.pm`.
- Safety/compatibility:
  - no helper logic changed; only the active runtime call path changed,
  - the `FlattenedDT` compatibility delegate remains available for any non-local callers,
  - no intended semantic change to referenced-intermediate tracking, generated enable declarations, or emitted HDL behavior.
- Verification:
  - syntax checks for `EnableGraph.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - the same-pattern direct self-owned round-trips in `EnableGraph.pm` now appear exhausted,
  - if this lane continues immediately, the next remaining direct method dependency to inspect is `ast_to_systemverilog()` calling `FlattenedDT`'s `_ast_to_systemverilog_internal(...)`, which is a deeper render-boundary seam rather than another self-owned helper round-trip.
## 2026-03-09: FlattenedDT backend convergence (EnableGraph mux-config callsite convergence)
- Continued backend convergence by localizing the phase-1 `build_multiplexer_config()` callsite in `perl/FSM/Synthesis/EnableGraph.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` self ownership.
- Rationale:
  - helper ownership for `build_multiplexer_config()` already lives in `EnableGraph`,
  - after the adjacent RHS-grouping and enable-structure callsite cleanups, this became the next smallest live facade round-trip still inside `build_unified_assignment_analysis()`.
- Safety/compatibility:
  - no helper logic changed; only the active runtime call path changed,
  - the `FlattenedDT` compatibility delegate remains available for any non-local callers,
  - no intended semantic change to multiplexer classification, enable ordering, or emitted HDL behavior.
- Verification:
  - syntax checks for `EnableGraph.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue with the next smallest remaining direct self-owned round-trip in `EnableGraph`, currently the `track_ast_intermediate_signals()` callsite in `generate_lhs_enables_from_analysis()`,
  - keep preferring live helper-family self-localization over broad facade cleanup.
## 2026-03-09: FlattenedDT backend convergence (EnableGraph enable-structure callsite convergence)
- Continued backend convergence by localizing the phase-1 `generate_complete_enable_structure()` callsite in `perl/FSM/Synthesis/EnableGraph.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` self ownership.
- Rationale:
  - helper ownership for `generate_complete_enable_structure()` already lives in `EnableGraph`,
  - after the adjacent RHS-grouping callsite cleanup, this became the next smallest live facade round-trip inside `build_unified_assignment_analysis()`.
- Safety/compatibility:
  - no helper logic changed; only the active runtime call path changed,
  - the `FlattenedDT` compatibility delegate remains available for any non-local callers,
  - no intended semantic change to enable-structure assembly, unified analysis contents, or emitted HDL behavior.
- Verification:
  - syntax checks for `EnableGraph.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue with the adjacent phase-1 analysis round-trip, most likely `build_multiplexer_config()` in `build_unified_assignment_analysis()`,
  - keep preferring live helper-family self-localization over broad facade cleanup.
## 2026-03-09: FlattenedDT backend convergence (EnableGraph RHS-grouping callsite convergence)
- Continued backend convergence by localizing the phase-1 `group_assignments_by_rhs()` callsite in `perl/FSM/Synthesis/EnableGraph.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` self ownership.
- Rationale:
  - helper ownership for `group_assignments_by_rhs()` already lives in `EnableGraph`,
  - with the active `generate_systemverilog()` stage chain fully localized, the next smallest live facade round-trip moved to the phase-1 analysis helper family inside `build_unified_assignment_analysis()`.
- Safety/compatibility:
  - no helper logic changed; only the active runtime call path changed,
  - the `FlattenedDT` compatibility delegate remains available for any non-local callers,
  - no intended semantic change to RHS grouping, unified analysis contents, or emitted HDL behavior.
- Verification:
  - syntax checks for `EnableGraph.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue with the adjacent phase-1 analysis round-trip, most likely `generate_complete_enable_structure()` in `build_unified_assignment_analysis()`,
  - keep preferring live helper-family self-localization over broad facade cleanup.
## 2026-03-08: CI workflow unification for local pre-push execution
- Added a shared CI entrypoint, `bin/ci-regression`, and pointed `.github/workflows/regression.yml` at that script so local and GitHub execution use the same repo-owned command path.
- Rationale:
  - the existing workflow only inlined `prove -v t/01-regression.t`, which worked from the repo root but did not provide a dedicated local pre-push entrypoint,
  - moving workflow behavior into a repo script makes the CI logic runnable locally even when invoked from outside the repository root,
  - the shared script also makes it straightforward to grow CI coverage without duplicating shell logic in YAML.
- Scope correction:
  - the repository’s active CI path is Perl-only, so the earlier Rust-specific include-path guard was unnecessary and has been removed,
  - the shared CI entrypoint now stays focused on the actual project contract: repo-root-aware execution of the Perl regression suite.
- Verification:
  - validated the shared local entrypoint from outside the repo root with `bash -lc 'cd /tmp && /Users/richarddje/Documents/github/fsmgen/bin/ci-regression'`,
  - the full regression remained green (`prove -I perl t` -> `Files=6`, `Tests=125`),
  - audited tracked `.github`, `bin`, `perl`, `t`, `README.md`, and `docs` content and found no active references to untracked `fx/`, `plugin/`, `specs/`, or machine-specific `/Users/...` paths.
- Working guidance:
  - keep future CI checks in repo-owned scripts first and let workflow YAML delegate to them,
  - when checking whether GitHub CI depends on untracked content, audit the active tracked workflow/runtime/test path rather than broad legacy trees that are not in use.
## 2026-03-08: FlattenedDT backend convergence (Orchestrator signal-assignment callsite convergence)
- Continued backend convergence by localizing the stage-8 `generate_signal_assignments()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` ownership.
- Rationale:
  - helper ownership for `generate_signal_assignments()` already lives in `perl/FSM/Synthesis/EnableGraph.pm`,
  - after the stage-7 WEN/EN callsite cleanup, this was the final remaining active `generate_systemverilog()` stage call still round-tripping through the `FlattenedDT` facade.
- Safety/compatibility:
  - no helper logic changed; only the active runtime call path changed,
  - the `FlattenedDT` compatibility delegate remains available for any non-local callers,
  - no intended semantic change to final signal-assignment emission, stage ordering, or emitted HDL behavior.
- Verification:
  - syntax checks for `FlattenedDT/Orchestrator.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - re-scan the remaining live `FlattenedDT` facade round-trips now that the active `generate_systemverilog()` stage chain is fully localized,
  - prioritize the next smallest behavior-preserving runtime seam outside this now-clean stage pipeline before considering delegate retirement.
## 2026-03-08: FlattenedDT backend convergence (Orchestrator WEN/EN-signal callsite convergence)
- Continued backend convergence by localizing the stage-7 `generate_wen_en_signals()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Rationale:
  - helper ownership for `generate_wen_en_signals()` already lives in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - after the consolidated-intermediate-signals callsite cleanup, this became the next earliest active backend-emission round-trip in `generate_systemverilog()`.
- Safety/compatibility:
  - no helper logic changed; only the active runtime call path changed,
  - the `FlattenedDT` compatibility delegate remains available for any non-local callers,
  - no intended semantic change to WEN/EN signal emission, stage ordering, or emitted HDL behavior.
- Verification:
  - syntax checks for `FlattenedDT/Orchestrator.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue with the next active Orchestrator round-trip, most likely the stage-8 `generate_signal_assignments()` callsite in `generate_systemverilog()`,
  - that next seam should localize from the facade to direct `EnableGraph` ownership while keeping compatibility delegates intact.
## 2026-03-08: FlattenedDT backend convergence (Orchestrator consolidated-intermediate-signals callsite convergence)
- Continued backend convergence by localizing the stage-6 `generate_consolidated_intermediate_signals()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Rationale:
  - helper ownership for `generate_consolidated_intermediate_signals()` already lives in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - after the WEN/EN pre-scan callsite cleanup, this became the next earliest active backend-emission round-trip in `generate_systemverilog()`.
- Safety/compatibility:
  - no helper logic changed; only the active runtime call path changed,
  - the `FlattenedDT` compatibility delegate remains available for any non-local callers,
  - no intended semantic change to consolidated intermediate signal emission, stage ordering, or emitted HDL behavior.
- Verification:
  - syntax checks for `FlattenedDT/Orchestrator.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue with the next active Orchestrator/backend round-trip, most likely the stage-7 `generate_wen_en_signals()` callsite in `generate_systemverilog()`,
  - keep prioritizing live callsite convergence over dormant validation/support helpers.
## 2026-03-08: Repository tracking scope for legacy plugin/spec assets
- Added `plugin/` and `specs/` to version control as repository assets.
- Rationale:
  - preserve the legacy plugin inventory and spec/reference files inside the repo for continuity and future modernization work,
  - keep this scope strictly about repository tracking rather than changing plugin loading semantics or backend behavior.
- Verification:
  - post-commit short status leaves only `fx/` untracked.
- Working rule:
  - keep `fx/` outside version control for now unless explicitly requested.
## 2026-03-08: FlattenedDT backend convergence (Orchestrator WEN/EN prescan callsite convergence)
- Continued backend convergence by localizing the stage-5 `prescan_wen_en_for_intermediate_signals()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Rationale:
  - helper ownership for `prescan_wen_en_for_intermediate_signals()` already lives in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - after the logical-op-count callsite cleanup, this became the next earliest active backend-analysis round-trip in `generate_systemverilog()`.
- Safety/compatibility:
  - no helper logic changed; only the active runtime call path changed,
  - the `FlattenedDT` compatibility delegate remains available for any non-local callers,
  - no intended semantic change to pre-scan behavior, stage ordering, or emitted HDL behavior.
- Verification:
  - syntax checks for `FlattenedDT/Orchestrator.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue with the next active Orchestrator/backend round-trip, most likely the stage-6 `generate_consolidated_intermediate_signals()` callsite in `generate_systemverilog()`,
  - keep prioritizing live callsite convergence over dormant validation/support helpers.
## 2026-03-08: FlattenedDT backend convergence (Orchestrator logical-op-count callsite convergence)
- Continued backend convergence by localizing the stage-4 `count_binary_logical_operation_occurrences()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Rationale:
  - helper ownership for `count_binary_logical_operation_occurrences()` already lives in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - after the stage-3 callsite cleanup, this became the next earliest active non-emission round-trip in `generate_systemverilog()`.
- Safety/compatibility:
  - no helper logic changed; only the active runtime call path changed,
  - the `FlattenedDT` compatibility delegate remains available for any non-local callers,
  - no intended semantic change to logical-op counting, pre-scan ordering, or emitted HDL behavior.
- Verification:
  - syntax checks for `FlattenedDT/Orchestrator.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue with the next active Orchestrator/backend round-trip, most likely the stage-5 `prescan_wen_en_for_intermediate_signals()` callsite in `generate_systemverilog()`,
  - keep prioritizing live callsite convergence over dormant validation/support helpers.
## 2026-03-08: FlattenedDT backend convergence (Orchestrator generate-enable-conditions callsite convergence)
- Continued backend convergence by localizing the stage-3 `generate_enable_conditions()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Rationale:
  - helper ownership for `generate_enable_conditions()` already lives in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - with the stage-2 emission chain now fully localized, this became the next earliest active backend-emission round-trip in `generate_systemverilog()`.
- Safety/compatibility:
  - no helper logic changed; only the active runtime call path changed,
  - the `FlattenedDT` compatibility delegate remains available for any non-local callers,
  - no intended semantic change to enable-condition emission, pipeline ordering, or emitted HDL behavior.
- Verification:
  - syntax checks for `FlattenedDT/Orchestrator.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue with the next active Orchestrator/backend round-trip, most likely the stage-4 `count_binary_logical_operation_occurrences()` callsite in `generate_systemverilog()`,
  - keep prioritizing live callsite convergence over dormant validation/support helpers.
## 2026-03-08: FlattenedDT backend convergence (Orchestrator generate-internal-signal-declarations callsite convergence)
- Continued backend convergence by localizing the stage-2 `generate_internal_signal_declarations()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Rationale:
  - helper ownership for `generate_internal_signal_declarations()` already lives in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - after the previous `generate_state_register()` callsite cleanup, this was the last remaining stage-2 backend-emission round-trip inside `generate_systemverilog()`.
- Safety/compatibility:
  - no helper logic changed; only the active runtime call path changed,
  - the `FlattenedDT` compatibility delegate remains available for any non-local callers,
  - no intended semantic change to internal signal declaration emission, pipeline ordering, or emitted HDL behavior.
- Verification:
  - syntax checks for `FlattenedDT/Orchestrator.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue with the next active Orchestrator/backend round-trip, most likely the stage-3 `generate_enable_conditions()` callsite in `generate_systemverilog()`,
  - keep prioritizing live callsite convergence over dormant validation/support helpers.
## 2026-03-08: FlattenedDT backend convergence (Orchestrator generate-state-register callsite convergence)
- Continued backend convergence by localizing the stage-2 `generate_state_register()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Rationale:
  - helper ownership for `generate_state_register()` already lives in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - after the previous `generate_state_encoding()` callsite cleanup, this became the next earliest remaining backend-emission round-trip inside `generate_systemverilog()`.
- Safety/compatibility:
  - no helper logic changed; only the active runtime call path changed,
  - the `FlattenedDT` compatibility delegate remains available for any non-local callers,
  - no intended semantic change to state-register emission, pipeline ordering, or emitted HDL behavior.
- Verification:
  - syntax checks for `FlattenedDT/Orchestrator.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue through the remaining stage-2 backend-emission Orchestrator round-trips in `generate_systemverilog()`, most likely `generate_internal_signal_declarations()`,
  - keep prioritizing live callsite convergence over dormant validation/support helpers.
## 2026-03-08: FlattenedDT backend convergence (Orchestrator generate-state-encoding callsite convergence)
- Continued backend convergence by localizing the stage-2 `generate_state_encoding()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Rationale:
  - helper ownership for `generate_state_encoding()` already lives in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - after the previous `generate_module_declaration()` callsite cleanup, this became the next earliest remaining backend-emission round-trip inside `generate_systemverilog()`.
- Safety/compatibility:
  - no helper logic changed; only the active runtime call path changed,
  - the `FlattenedDT` compatibility delegate remains available for any non-local callers,
  - no intended semantic change to state encoding emission, pipeline ordering, or emitted HDL behavior.
- Verification:
  - syntax checks for `FlattenedDT/Orchestrator.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue through the remaining stage-2 backend-emission Orchestrator round-trips in `generate_systemverilog()`, most likely `generate_state_register()`,
  - keep prioritizing live callsite convergence over dormant validation/support helpers.
## 2026-03-08: FlattenedDT backend convergence (Orchestrator generate-module-declaration callsite convergence)
- Continued backend convergence by localizing the stage-2 `generate_module_declaration()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Rationale:
  - helper ownership for `generate_module_declaration()` already lives in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - after the previous `generate_header()` callsite cleanup, this became the next earliest remaining backend-emission round-trip inside `generate_systemverilog()`.
- Safety/compatibility:
  - no helper logic changed; only the active runtime call path changed,
  - the `FlattenedDT` compatibility delegate remains available for any non-local callers,
  - no intended semantic change to module declaration emission, pipeline ordering, or emitted HDL behavior.
- Verification:
  - syntax checks for `FlattenedDT/Orchestrator.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue through the remaining stage-2 backend-emission Orchestrator round-trips in `generate_systemverilog()`, most likely `generate_state_encoding()`,
  - keep prioritizing live callsite convergence over dormant validation/support helpers.
## 2026-03-08: FlattenedDT backend convergence (Orchestrator generate-header callsite convergence)
- Continued backend convergence by localizing the stage-2 `generate_header()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Rationale:
  - helper ownership for `generate_header()` already lives in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - after the recent stage-level callsite cleanups, this became the earliest remaining backend-emission round-trip inside `generate_systemverilog()`.
- Safety/compatibility:
  - no helper logic changed; only the active runtime call path changed,
  - the `FlattenedDT` compatibility delegate remains available for any non-local callers,
  - no intended semantic change to header emission, pipeline ordering, or emitted HDL behavior.
- Verification:
  - syntax checks for `FlattenedDT/Orchestrator.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue through the remaining stage-2 backend-emission Orchestrator round-trips in `generate_systemverilog()`, most likely `generate_module_declaration()`,
  - keep prioritizing live callsite convergence over dormant validation/support helpers.
## 2026-03-08: FlattenedDT backend convergence (Orchestrator unified-assignment-analysis callsite convergence)
- Continued backend convergence by localizing the unified phase-1 `build_unified_assignment_analysis()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` ownership.
- Rationale:
  - helper ownership for `build_unified_assignment_analysis()` already lives in `EnableGraph`,
  - after the prior stage-0 callsite cleanup, this became the next smallest active stage-level round-trip in the Orchestrator flow.
- Safety/compatibility:
  - no helper logic changed; only the active runtime call path changed,
  - the `FlattenedDT` compatibility delegate remains available for any non-local callers,
  - no intended semantic change to flattened assignment analysis, phase-1 enable preparation, or emitted HDL behavior.
- Verification:
  - syntax checks for `FlattenedDT/Orchestrator.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue through the remaining active stage-level Orchestrator round-trips in `generate_systemverilog()`, likely starting with the earliest backend-emission callsites,
  - keep prioritizing live callsite convergence over dormant validation/support helpers.
## 2026-03-08: FlattenedDT backend convergence (Orchestrator stage-0 FSM-module-reference callsite convergence)
- Continued backend convergence by localizing the stage-0 `set_fsm_module_reference()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` ownership.
- Rationale:
  - helper ownership for `set_fsm_module_reference()` already lives in `EnableGraph`,
  - after the previous condition-helper callsite cleanup, this stage-0 call became the smallest remaining active stage-level round-trip inside `generate_systemverilog()`.
- Safety/compatibility:
  - no helper logic changed; only the active runtime call path changed,
  - the `FlattenedDT` compatibility delegate remains available for any non-local callers,
  - no intended semantic change to FSM-module reference storage, reset/default analysis setup, or emitted HDL behavior.
- Verification:
  - syntax checks for `FlattenedDT/Orchestrator.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue with the next stage-level Orchestrator round-trip, most likely `build_unified_assignment_analysis()` in `flatten_all_decision_trees()`,
  - keep prioritizing live callsite convergence over dormant validation/support helpers.
## 2026-03-08: FlattenedDT backend convergence (Orchestrator condition-helper callsite convergence)
- Continued backend convergence by localizing the active Orchestrator condition-helper round-trips from `FlattenedDT` facade delegates to direct `EnableGraph` ownership in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`.
- Rationale:
  - helper ownership for `convert_condition_to_ast()`, `convert_test_value_to_ast()`, and `create_condition_expression()` already lives in `EnableGraph`,
  - after the recent Orchestrator ownership moves, these condition-construction callsites are all on the live traversal/capture path and no longer need to bounce through the `FlattenedDT` facade.
- Safety/compatibility:
  - no helper logic changed; only the active runtime call path changed,
  - `FlattenedDT` compatibility delegates remain in place for any non-local or dormant callers,
  - no intended semantic change to condition AST construction, branch/test traversal, assignment capture, transition capture, or emitted HDL behavior.
- Verification:
  - syntax checks for `FlattenedDT/Orchestrator.pm` and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue through the remaining active stage-level Orchestrator round-trips such as `build_unified_assignment_analysis()` or `set_fsm_module_reference()`,
  - keep deprioritizing dormant validation and legacy helper clusters relative to live callsite convergence.
## 2026-03-08: FlattenedDT backend convergence (actual LHS/RHS tracking orchestration ownership)
- Continued backend convergence by moving `track_actual_lhs_rhs()` ownership into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` and reducing `perl/FSM/HDL/FlattenedDT.pm` to a compatibility delegate for that helper.
- Rationale:
  - after the assignment-capture and state-transition moves, actual LHS/RHS tracking had become a tiny single-purpose seam with only orchestrator-owned callers,
  - the adjacent expected/raw-AST validation family is not on the active runtime path, so moving only `track_actual_lhs_rhs()` keeps the slice truthful and low risk.
- Safety/compatibility:
  - tracking logic is unchanged apart from ownership and local call routing,
  - the moved helper still writes to the same `actual_lhs_rhs` state stored on the shared `FlattenedDT` context,
  - no intended semantic change to validation counters, captured assignment/transition metadata, or emitted HDL behavior.
- Verification:
  - syntax checks for `FlattenedDT.pm` and `FlattenedDT/Orchestrator.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - re-scan the remaining live Orchestrator/backend call surface for the next smallest active ownership seam,
  - continue deferring the dormant `track_expected_lhs_rhs()` / raw-AST completeness helpers until they justify extraction as a cohesive validation/support block.
## 2026-03-08: Living architecture note (parser/input-format independence vs FSMGen core)
This section is the living design note for decoupling FSM source syntax parsing from the FSMGen semantic core.
### Current validated state
- `FSM::Pipeline::HDLGenerator` still hardwires source parsing to `Lispish::multi(...)`.
- The pipeline then hands that raw parser output into `FSM::Adapter::FSMGenFull`, which lowers it into `FSM::CoreAST::FSMModule`.
- Downstream analysis and HDL generation mostly operate on `FSM::CoreAST` objects rather than on raw Lispish arrays.
- Conclusion:
  - the core is already semantically centered on `FSM::CoreAST`,
  - the frontend boundary is still specifically Lispish / `.fsm` oriented.
### Canonical architectural boundary
- The contract between any frontend and the rest of FSMGen should be `FSM::CoreAST::FSMModule` plus related semantic node types.
- Only frontend/lowering code should know about parser-specific raw trees, token spellings, or source-format quirks.
- Synthesis and backend code should not branch on input format once a valid `FSM::CoreAST` module exists.
### Important nuance about the current adapter
- The current adapter layer is not merely a thin syntax bridge.
- `FSM::Adapter::FSMGenFull::Parser`, `ExpressionBuilder`, and `SignalAnalyzer` currently perform meaningful semantic lowering and validation, including:
  - assignment-family interpretation (`=`, `<-`, `<=`, `<-=`, `<=+`, `<N`),
  - condition lowering,
  - width propagation and mismatch handling,
  - combinational self-dependency checks,
  - signal registration and signal-role/interface classification.
- Therefore, future format support should reuse shared lowering and semantic policy instead of duplicating backend-visible meaning separately inside each new parser.
### Desired end state
- Source text / file format -> frontend parser -> lowering / normalization -> `FSM::CoreAST` -> analysis / synthesis / backend emission.
- The existing Lispish `.fsm` reader becomes one frontend among potentially several.
- Future formats are acceptable if they can express the same semantic model and lower cleanly into `FSM::CoreAST`.
### Explicit non-goals
- Do not make synthesis/backend layers understand multiple raw parser AST shapes.
- Do not let syntax-specific array structures leak past the frontend boundary.
- Do not replace one parser dependency with many parser dependencies deeper in the pipeline.
### Direction for future work
- Move the direct `Lispish` dependency behind a dedicated frontend boundary instead of keeping it in `FSM::Pipeline::HDLGenerator`.
- Keep `FSM::CoreAST` as the canonical semantic IR unless a clearer lowered IR becomes necessary later.
- If multiple frontends are introduced, split “syntax parse” from “semantic lowering” more explicitly so shared semantic rules live once.
- Treat `raw_ast` as a frontend/debug artifact, not as required core state.
### Working summary
- Parser independence is not fully implemented today.
- Semantic-core independence is partially implemented already.
- The right long-term target is frontend independence around a stable semantic `FSM::CoreAST` boundary, not raw-AST pluralism.
## 2026-03-08: FlattenedDT backend convergence (assignment-capture orchestration ownership)
- Continued backend convergence by moving `extract_lhs_name_from_ast()`, `record_assignment_from_ast()`, and `extract_rhs_from_expression()` ownership into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` and reducing `perl/FSM/HDL/FlattenedDT.pm` to compatibility delegates for that trio.
- Rationale:
  - after the recursive flattener and state-transition moves, the assignment path became the next smallest still-live cohesive seam because its only operational callers were the orchestrator-owned traversal body and its own RHS recursion,
  - moving the LHS-name helper together avoids leaving a tiny facade-owned helper that would otherwise serve only the orchestrator-owned assignment path.
- Safety/compatibility:
  - assignment-capture logic is unchanged apart from ownership and local call routing,
  - the moved helpers still use the existing shared `FlattenedDT` state for condition construction, LHS/RHS validation tracking, and AST-map storage,
  - no intended semantic change to assignment intent interpretation, recorded assignment structures, or emitted HDL behavior.
- Verification:
  - syntax checks for `FlattenedDT.pm` and `FlattenedDT/Orchestrator.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue on the nearby shared tracking helper seam now used only from the orchestrator-owned assignment/transition capture path, most likely `track_actual_lhs_rhs()`,
  - keep deferring dormant legacy helpers such as `extract_condition_string()` until they become part of an active ownership path again.
## 2026-03-08: FlattenedDT backend convergence (state-transition capture orchestration ownership)
- Continued backend convergence by moving `record_transition_from_ast()` ownership into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` and reducing `perl/FSM/HDL/FlattenedDT.pm` to a compatibility delegate for that entrypoint.
- Rationale:
  - after the recursive flattener move, this transition-capture helper became a clean single-caller seam because it is now invoked only from the orchestrator-owned traversal body,
  - moving this smaller transition path first keeps the slice lower risk than immediately pulling the larger assignment-capture helper and its RHS-extraction dependency.
- Safety/compatibility:
  - transition-capture logic is unchanged apart from ownership and local call routing,
  - the moved helper still uses the existing shared condition-construction, tracking, and AST-map helpers on `FlattenedDT`,
  - no intended semantic change to next-state capture, validation tracking, or emitted HDL behavior.
- Verification:
  - syntax checks for `FlattenedDT.pm` and `FlattenedDT/Orchestrator.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue on the adjacent assignment-capture path (`record_assignment_from_ast()` together with `extract_rhs_from_expression()` and any tightly coupled support),
  - keep deferring dormant legacy factorization helpers until they matter to the active path again.
## 2026-03-08: FlattenedDT backend convergence (recursive flattener orchestration ownership)
- Continued backend convergence by moving `flatten_decision_tree()` ownership into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` and reducing `perl/FSM/HDL/FlattenedDT.pm` to a compatibility delegate for the recursive flattener.
- Rationale:
  - after the prior `flatten_all_decision_trees()` slice, the recursive traversal body was the next smallest still-live adjacent seam because it is now called only from the orchestrator-owned entrypoint and from itself,
  - moving the recursive traversal first keeps the slice smaller and safer than immediately pulling the lower-level AST-capture/storage helpers that it invokes.
- Safety/compatibility:
  - traversal logic is unchanged apart from ownership and local recursion routing,
  - the recursive flattener still calls back into the existing `FlattenedDT` helpers for condition conversion, AST capture, and assignment/transition recording,
  - no intended semantic change to traversal order, assignment collection, unified analysis inputs, or emitted HDL behavior.
- Verification:
  - syntax checks for `FlattenedDT.pm` and `FlattenedDT/Orchestrator.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue on the adjacent AST-capture helper family used by the recursive flattener (`record_assignment_from_ast()`, `record_transition_from_ast()`, `extract_rhs_from_expression()`, and any tightly coupled support),
  - continue deferring dormant legacy factorization helpers until they matter to the active path again.
## 2026-03-08: FlattenedDT backend convergence (flatten-all-decision-trees orchestration ownership)
- Continued backend convergence by moving `flatten_all_decision_trees()` ownership into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` and reducing `perl/FSM/HDL/FlattenedDT.pm` to a compatibility delegate for that entrypoint.
- Rationale:
  - after the recent live-path slices, this entrypoint was the next smallest still-exercised orchestration seam because `generate_systemverilog()` is its only operational caller and the body already behaves like orchestration glue over `flatten_decision_tree()` plus unified-analysis setup,
  - moving the entrypoint first keeps the slice smaller and safer than immediately pulling the deeper recursive flattener helper family.
- Safety/compatibility:
  - the moved body is unchanged apart from ownership and delegation,
  - no intended semantic change to state/DT traversal, assignment collection, unified analysis setup, or emitted HDL behavior.
- Verification:
  - syntax checks for `FlattenedDT.pm`, `FlattenedDT/Orchestrator.pm`, and `Backend/SystemVerilog.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue scanning the adjacent live flattening helper family (`flatten_decision_tree()` and nearby AST-capture helpers) for the next smallest truthful move,
  - continue ignoring dormant legacy factorization helpers until they matter to the active path again.
## 2026-03-08: FlattenedDT backend convergence (AST condition-helper ownership)
- Continued backend convergence by moving `create_condition_expression()`, `convert_condition_to_ast()`, and `convert_test_value_to_ast()` ownership into `perl/FSM/Synthesis/EnableGraph.pm` and reducing `perl/FSM/HDL/FlattenedDT.pm` to compatibility delegates for that trio.
- Rationale:
  - after the prescan slice, the nearby legacy factorization and AST naming helpers were re-checked and remain mostly dormant, while this trio is still exercised directly when flattening conditional branches, test nodes, and assignment/transition condition stacks,
  - the moved trio already represents enable-oriented AST construction, so `EnableGraph` is a better ownership fit than leaving the logic in the façade module.
- Safety/compatibility:
  - helper logic and callsites are unchanged apart from ownership and delegation,
  - no intended semantic change to condition AST construction, flattened assignment capture, or emitted HDL behavior.
- Validation/implementation note:
  - syntax checks for `FlattenedDT.pm`, `Backend/SystemVerilog.pm`, and `EnableGraph.pm` all pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`),
  - explicit `use FSM::AST::Utils;` in `EnableGraph` is currently unsafe because it exposes an incompatible helper load path in this repository; the final change deliberately relies on the pre-existing working runtime path instead.
- Next likely slices:
  - continue scanning for the next smallest active helper or entrypoint still exercised by the live flattening/orchestration/backend path,
  - keep ignoring dormant legacy helper blocks until they become part of an active call chain again.
## 2026-03-07: FlattenedDT backend convergence (WEN/EN prescan entrypoint ownership)
- Continued backend convergence by moving `prescan_wen_en_for_intermediate_signals()` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and reducing `perl/FSM/HDL/FlattenedDT.pm` to a compatibility delegate for that entrypoint.
- Rationale:
  - the nearby AST-based signal-naming helpers are currently mostly idle compatibility code, while the prescan step is still exercised directly by `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` on the live SystemVerilog generation path,
  - the moved entrypoint already depends on backend/EnableGraph-owned behavior (`track_ast_intermediate_signals`) and therefore forms a small truthful ownership seam.
- Safety/compatibility:
  - the prescan logic and Orchestrator call order are unchanged apart from ownership and delegation,
  - no intended semantic change to intermediate-signal discovery, declaration rescue, or emitted HDL behavior.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue scanning `FlattenedDT` for the next smallest active helper still exercised by the live Orchestrator/backend path,
  - keep deferring mostly idle legacy naming helpers until an active call path needs them.
## 2026-03-07: FlattenedDT backend convergence (AST sub-expression analysis helper ownership)
- Continued backend convergence by moving `analyze_ast_sub_expressions()`, `find_all_ast_sub_expressions()`, and `is_simple_ast_expression()` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and reducing `perl/FSM/HDL/FlattenedDT.pm` to compatibility delegates for that trio.
- Rationale:
  - after the intermediate-signal generation entrypoint move, this trio was the next smallest cohesive AST-analysis seam in the neighboring factorization helper cluster,
  - moving the trio together avoids leaving recursive helper behavior split across facade and backend ownership.
- Safety/compatibility:
  - helper logic is unchanged apart from ownership and delegation,
  - no intended semantic change to AST sub-expression discovery, factorization simplicity classification, or emitted HDL behavior.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue through the remaining adjacent factorization/helper cluster in `FlattenedDT`,
  - keep the same smallest-cohesive-family extraction cadence.
## 2026-03-07: FlattenedDT backend convergence (intermediate-signal generation entrypoint ownership)
- Continued backend convergence by moving `generate_intermediate_signals()` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and reducing `perl/FSM/HDL/FlattenedDT.pm` to a compatibility delegate for that entrypoint.
- Rationale:
  - after localizing the logical-op-count family, `generate_intermediate_signals()` was the next small backend-facing entrypoint whose active dependency chain was already mostly backend-local,
  - this preserves the micro-slice cadence while shrinking `FlattenedDT` by one more explicit backend ownership boundary.
- Safety/compatibility:
  - the entrypoint body is unchanged apart from ownership and delegation,
  - no intended semantic change to factorization results, intermediate declaration text, or emitted HDL behavior.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - continue through the adjacent intermediate-signal / legacy factorization helper cluster in `FlattenedDT`,
  - keep choosing the smallest behavior-preserving backend-owned seam each time.
## 2026-03-07: FlattenedDT backend convergence (logical-op-count helper-pair ownership)
- Continued backend convergence by moving `_count_logical_ops_in_ast()` and `_is_factorizable_sub_expression()` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and reducing `perl/FSM/HDL/FlattenedDT.pm` to compatibility delegates for both helpers.
- Rationale:
  - after the collector move, these two methods formed the remaining coupled backend/facade dependency inside the logical-op-count family,
  - moving them together keeps the slice truthful and avoids leaving recursion in backend code dependent on a facade-owned policy helper.
- Safety/compatibility:
  - the recursion and factorization-policy logic are unchanged apart from ownership and callsite relocation,
  - `FlattenedDT` still exposes compatibility delegates for both helper names,
  - no intended semantic change to logical-op counting, factorization policy, or emitted HDL text.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - re-scan `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` for the next smallest backend/facade ownership seam now that the logical-op-count family is locally owned,
  - continue the same micro-slice convergence cadence.
## 2026-03-07: Roadmap decision update (legacy plugin retirement)
- The roadmap direction for extension points is now to retire legacy `.plg` / `PPlugin.pm` support rather than carry it forward as a compatibility feature.
- Intended replacement direction:
  - use a more standard, typed, and robust extension mechanism when roadmap item 5 is executed,
  - treat current plugin artifacts as legacy behavior to replace, not architecture to preserve.
## 2026-03-07: FlattenedDT backend convergence (logical-op-count collector ownership)
- Continued backend convergence by moving `collect_all_wen_en_ast_expressions()` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and reducing `perl/FSM/HDL/FlattenedDT.pm` to a compatibility delegate for that helper.
- Rationale:
  - after the logical-op-count entrypoint move, the collector was the next smallest self-contained ownership seam because it only traverses existing `FlattenedDT` state and does not depend on the remaining counting/policy helpers,
  - switching the backend-owned count flow to `$self->collect_all_wen_en_ast_expressions()` removes one more active backend/facade round-trip while keeping the slice to a single helper family boundary.
- Safety/compatibility:
  - the collector logic is unchanged apart from ownership and callsite relocation,
  - the remaining direct backend dependency in this family is `_count_logical_ops_in_ast()`, which still couples through `_is_factorizable_sub_expression()`,
  - no intended semantic change to logical-op counting, factorization policy, or emitted HDL text.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - move `_count_logical_ops_in_ast()` into backend ownership together with `_is_factorizable_sub_expression()`,
  - then re-scan for any remaining direct backend/facade round-trips in the logical-op-count family.
## 2026-03-07: FlattenedDT backend convergence (logical-op-count entrypoint ownership)
- Continued backend convergence by moving `count_binary_logical_operation_occurrences()` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and reducing `perl/FSM/HDL/FlattenedDT.pm` to a compatibility delegate for that entrypoint.
- Rationale:
  - after the previous wrapper slice, the entrypoint itself was the next smallest truthful ownership move and could be relocated without forcing the entire logical-op-count helper family across at once,
  - this preserves the established low-risk cadence while making the active backend factorization flow own its logical-op-count entrypoint directly.
- Safety/compatibility:
  - the moved backend entrypoint still relies on `FlattenedDT` for the currently unmoved helper methods `collect_all_wen_en_ast_expressions()` and `_count_logical_ops_in_ast()`,
  - no intended semantic change to logical-op counting, factorization policy, or emitted HDL text.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - move `collect_all_wen_en_ast_expressions()` into backend ownership,
  - then tackle `_count_logical_ops_in_ast()` together with the tightly coupled `_is_factorizable_sub_expression()` helper.
## 2026-03-07: FlattenedDT backend convergence (logical-op-count wrapper callsite)
- Continued backend convergence by localizing the direct `run_global_ast_factorization` fallback callsite for `count_binary_logical_operation_occurrences()` behind a backend-local helper in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Rationale:
  - this was the remaining direct `FlattenedDT` method call in the active backend factorization flow, and wrapping it behind a backend-local helper is the smallest truthful slice before moving the heavier logical-op-count implementation family itself,
  - keeping the slice to one helper addition plus one callsite change preserves the established low-risk convergence cadence while shrinking the visible backend/facade round-trip surface in operational code.
- Safety/compatibility:
  - single operational callsite change in `run_global_ast_factorization` plus a backend-local delegating helper,
  - no intended semantic change to logical-op counting, factorization decisions, or emitted HDL text.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - move the logical-op-count implementation family (`count_binary_logical_operation_occurrences`, `_count_logical_ops_in_ast`, `_is_factorizable_sub_expression`, and any tightly coupled collection logic) into backend ownership,
  - then re-scan for the next smallest backend/helper ownership seam.
## 2026-03-07: FlattenedDT backend convergence (bare intermediate-signal trace render callsite)
- Continued backend convergence by localizing one bare `FSM::HDL::IntermediateSignalRef` trace render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from a `FlattenedDT` method call (`$ctx->ast_to_clean_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- Rationale:
  - this trace render sits in `ast_contains_intermediate_signals`, directly beside the already localized signal-name and regular-AST trace handling and is a smaller seam than the remaining logical-op-count helper call,
  - keeping the slice to one debug render callsite preserves the established low-risk convergence cadence while shrinking the remaining direct backend method-call round-trips to one.
- Safety/compatibility:
  - single-callsite change only in bare intermediate-signal debug tracing inside `ast_contains_intermediate_signals`,
  - no intended semantic change to second-pass factorization decisions, AST classification, or emitted HDL text.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - the remaining direct backend `count_binary_logical_operation_occurrences()` round-trip in `run_global_ast_factorization`,
  - any next-smallest backend ownership seam after that callsite is exhausted.
## 2026-03-07: FlattenedDT backend convergence (factorizer substituted-AST trace render callsite)
- Continued backend convergence by localizing one factorizer substituted-AST trace render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- Rationale:
  - this trace render sits in `get_substituted_ast_for_signal`, where factorizer-owned substituted AST lookup is already backend-local and fits the same direct `EnableGraph` rendering ownership as the recently completed second-pass debug paths,
  - keeping the slice to one factorizer trace callsite preserves the established low-risk convergence cadence while removing the last exact backend `$ctx->ast_to_systemverilog(...)` round-trip in this file cluster.
- Safety/compatibility:
  - single-callsite change only in factorizer substituted-AST debug tracing inside `get_substituted_ast_for_signal`,
  - no intended semantic change to factorizer lookup, substituted AST selection, or emitted HDL text.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - re-scan for remaining backend ownership seams now that exact backend `$ctx->ast_to_systemverilog(...)` pass-throughs are exhausted,
  - choose the next smallest render/helper round-trip beyond this exact pattern.
## 2026-03-07: FlattenedDT backend convergence (assignment-condition second-pass substituted-AST debug render callsite)
- Continued backend convergence by localizing one assignment-condition second-pass substituted-AST debug render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- Rationale:
  - this substituted-AST debug render is the direct companion to the already localized assignment-condition original-AST trace and completes that second-pass assignment-condition debug pair under backend-owned `EnableGraph` rendering,
  - keeping the slice to one assignment-condition debug callsite preserves the established low-risk convergence cadence while shrinking another backend round-trip.
- Safety/compatibility:
  - single-callsite change only in assignment-condition second-pass debug reporting inside `update_original_asts_with_second_pass_substitutions`,
  - no intended semantic change to second-pass substitution updates, condition AST storage, or emitted HDL text.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - the later factorizer substituted-AST trace render callsite in `get_substituted_ast_for_signal`,
  - any remaining backend-local AST render seams that still round-trip through `FlattenedDT`.
## 2026-03-07: FlattenedDT backend convergence (assignment-condition second-pass original-AST debug render callsite)
- Continued backend convergence by localizing one assignment-condition second-pass original-AST debug render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- Rationale:
  - this original-AST debug render sits in the assignment-condition branch of backend-owned second-pass synchronization tracing and is the next smallest direct `EnableGraph` ownership seam after the LHS-level pair,
  - keeping the slice to one assignment-condition debug callsite preserves the established low-risk convergence cadence while shrinking another backend round-trip.
- Safety/compatibility:
  - single-callsite change only in assignment-condition second-pass debug reporting inside `update_original_asts_with_second_pass_substitutions`,
  - no intended semantic change to second-pass substitution updates, condition AST storage, or emitted HDL text.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - the adjacent assignment-condition second-pass substituted-AST debug render callsite,
  - the later factorizer substituted-AST trace render.
## 2026-03-07: FlattenedDT backend convergence (LHS-level second-pass substituted-AST debug render callsite)
- Continued backend convergence by localizing one LHS-level second-pass substituted-AST debug render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- Rationale:
  - this substituted-AST debug render is the direct companion to the already localized LHS-level original-AST trace and belongs to the same backend-owned second-pass synchronization tracing path,
  - keeping the slice to one LHS-level debug callsite preserves the established low-risk convergence cadence while shrinking another backend round-trip.
- Safety/compatibility:
  - single-callsite change only in LHS-level second-pass debug reporting inside `update_original_asts_with_second_pass_substitutions`,
  - no intended semantic change to second-pass substitution updates, AST storage, or emitted HDL text.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - the assignment-condition second-pass original/substituted debug render callsites,
  - the later factorizer substituted-AST trace render.
## 2026-03-07: FlattenedDT backend convergence (LHS-level second-pass original-AST debug render callsite)
- Continued backend convergence by localizing one LHS-level second-pass original-AST debug render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- Rationale:
  - this original-AST debug render sits in the next adjacent second-pass update lane after the DT-specific slice and belongs to the same backend-owned second-pass synchronization tracing path,
  - keeping the slice to one LHS-level debug callsite preserves the established low-risk convergence cadence while shrinking another backend round-trip.
- Safety/compatibility:
  - single-callsite change only in LHS-level second-pass debug reporting inside `update_original_asts_with_second_pass_substitutions`,
  - no intended semantic change to second-pass substitution updates, AST storage, or emitted HDL text.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - the adjacent LHS-level substituted-AST debug render callsite,
  - the assignment-condition second-pass debug render pair and later factorizer substituted-AST trace render.
## 2026-03-07: FlattenedDT backend convergence (DT-specific second-pass substituted-AST debug render callsite)
- Continued backend convergence by localizing one DT-specific second-pass substituted-AST debug render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- Rationale:
  - this substituted-AST debug render belongs to backend-owned second-pass synchronization tracing and aligns with the same direct `EnableGraph` rendering ownership as the already converged consolidated-render paths,
  - keeping the slice to one DT-specific debug callsite preserves the established low-risk convergence cadence while shrinking another backend round-trip.
- Safety/compatibility:
  - single-callsite change only in DT-specific second-pass debug reporting inside `update_original_asts_with_second_pass_substitutions`,
  - no intended semantic change to second-pass substitution updates, AST storage, or emitted HDL text.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - the adjacent LHS-level second-pass debug render pair,
  - the assignment-condition second-pass debug render pair and later factorizer substituted-AST trace render.
## 2026-03-07: FlattenedDT backend convergence (original-AST consolidated fallback render callsite)
- Continued backend convergence by localizing one original-AST consolidated fallback render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- Rationale:
  - this original-AST fallback render sits beside the already localized substituted-AST branch and belongs to the same backend-owned consolidated intermediate-signal emission path,
  - keeping the slice to one fallback branch preserves the established low-risk convergence cadence while shrinking another backend round-trip.
- Safety/compatibility:
  - single-callsite change only in the original-AST fallback branch of consolidated intermediate-signal assign generation,
  - no intended semantic change to fallback selection, assignment emission, or emitted HDL text.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - remaining second-pass update render callsites,
  - any later backend-local AST render seams that still round-trip through `FlattenedDT`.
## 2026-03-07: FlattenedDT backend convergence (substituted-AST consolidated render callsite)
- Continued backend convergence by localizing one substituted-AST consolidated render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- Rationale:
  - this substituted-AST render belongs to backend-owned consolidated intermediate-signal emission and fits the same direct `EnableGraph` rendering ownership as the surrounding dependency/filter/debug paths,
  - keeping the slice to one render branch preserves the established low-risk convergence cadence while shrinking another backend round-trip.
- Safety/compatibility:
  - single-callsite change only in the substituted-AST branch of consolidated intermediate-signal assign generation,
  - no intended semantic change to substituted-AST selection, assignment emission, or emitted HDL text.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - the adjacent original-AST fallback render callsite in consolidated assign generation,
  - remaining second-pass update render callsites.
## 2026-03-06: FlattenedDT backend convergence (final-filtered debug AST render callsite)
- Continued backend convergence by localizing one final-filtered debug AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- Rationale:
  - this final-filtered render belongs to backend-owned consolidated intermediate-signal tracing and fits the same direct `EnableGraph` rendering ownership as the adjacent dependency, filtering, and rescued-signal debug paths,
  - keeping the slice to one debug callsite preserves the established low-risk convergence cadence while removing another backend round-trip.
- Safety/compatibility:
  - single-callsite change only in final-filtered debug reporting inside consolidated intermediate-signal generation,
  - no intended semantic change to filtering results, rescue behavior, or emitted HDL text.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - the consolidated-intermediate substituted-AST render path (`$substituted_ast` / original-AST fallback),
  - remaining second-pass update render callsites.
## 2026-03-06: FlattenedDT backend convergence (rescued-signal debug AST render callsite)
- Continued backend convergence by localizing one rescued-signal debug AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- Rationale:
  - this rescued-signal render belongs to backend-owned consolidated intermediate-signal tracing and fits the same direct `EnableGraph` rendering ownership as the adjacent dependency and filtering paths,
  - keeping the slice to one debug callsite preserves the established low-risk convergence cadence while shrinking another backend round-trip.
- Safety/compatibility:
  - single-callsite change only in rescued-signal debug reporting inside consolidated intermediate-signal generation,
  - no intended semantic change to rescue behavior, filtering results, or emitted HDL text.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - the adjacent final-filtered debug render callsite,
  - remaining substituted-AST render/update callsites in consolidated-intermediate and second-pass update paths.
## 2026-03-06: FlattenedDT backend convergence (initial-filtering AST render callsite)
- Continued backend convergence by localizing one initial-filtering AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- Rationale:
  - this filtering-path render is part of backend-owned intermediate-signal analysis and belongs more naturally with direct `EnableGraph` rendering ownership,
  - keeping the slice to a single callsite preserves the established low-risk convergence cadence.
- Safety/compatibility:
  - single-callsite change only in the initial filtering path of consolidated intermediate-signal generation,
  - no intended semantic change to filtering behavior, dependency rescue, or emitted HDL text.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
- Next likely slices:
  - remaining backend `ast_to_systemverilog` pass-throughs in rescued/final-filtered debug and substituted-AST render/update paths.
## 2026-03-06: FlattenedDT backend convergence (dependency-map AST render callsite)
- Continued backend convergence by localizing one dependency-map AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- Rationale:
  - this callsite belongs to backend enable/dependency expression rendering and is more coherent when directly bound to `EnableGraph`,
  - micro-slice continues reducing transitional `FlattenedDT` helper indirection without broad refactor risk.
- Safety/compatibility:
  - single-callsite change only in dependency-map expression rendering path,
  - no intended semantic change to filtering, dependency propagation, or emitted HDL text.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-03-06: README as canonical onboarding entrypoint
- Decision:
  - treat `README.md` as the single onboarding entry point for humans and successor agents.
- Rationale:
  - onboarding speed and navigation quality improve when objective, doc map, and code-path map are centralized in one stable location.
  - avoids context fragmentation across multiple markdown files at session start.
- Implementation notes:
  - added objective-focused summary, fast ramp-up order, full markdown index, and key project file/path map.
  - added maintenance policy to keep README current only when onboarding-critical information changes.
- Compatibility/scope:
  - documentation-only change, no runtime behavior or test expectations modified.
## 2026-02-28: Backend extraction of final-expression usage-check helper
- Continued structure-first `FlattenedDT` decomposition by moving `is_signal_actually_used_in_final_expressions` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains compatibility delegation for this entrypoint (`backend_sv->is_signal_actually_used_in_final_expressions(...)`).
- Rationale:
  - final-expression usage checking is consumed directly in backend-owned filtering paths and is better co-located with that logic,
  - extraction continues reducing `FlattenedDT` monolith size while preserving facade compatibility.
- Safety/compatibility:
  - no intended semantic change in usage-check behavior,
  - backend AST/string filtering now calls backend-local usage-check helper while keeping recursive signal-reference checks anchored through existing `FlattenedDT` helper context.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-28: Backend extraction of string-fallback filtering helper
- Continued structure-first `FlattenedDT` decomposition by moving `should_filter_string_based` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains compatibility delegation for this entrypoint (`backend_sv->should_filter_string_based(...)`).
- Rationale:
  - string-fallback filtering is invoked from backend-owned consolidated filtering flow and is better co-located with that logic,
  - extraction continues reducing `FlattenedDT` monolith size while preserving facade compatibility.
- Safety/compatibility:
  - no intended semantic change in fallback filtering behavior,
  - backend consolidated filtering now calls backend-local fallback helper (`$self->should_filter_string_based(...)`) while preserving existing dependency checks through `FlattenedDT` context access.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-28: Backend extraction of simple-comparison helper
- Continued structure-first `FlattenedDT` decomposition by moving `is_simple_comparison` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains compatibility delegation for this entrypoint (`backend_sv->is_simple_comparison(...)`).
- Rationale:
  - simple-comparison classification is consumed directly in backend-owned AST filtering flow and is better co-located with that logic,
  - extraction continues reducing `FlattenedDT` monolith size while preserving facade compatibility.
- Safety/compatibility:
  - no intended semantic change in simple-comparison detection behavior,
  - backend AST filtering now invokes backend-local helper (`$self->is_simple_comparison(...)`) while preserving all existing downstream filtering decisions.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-28: Backend extraction of simple-negation helper
- Continued structure-first `FlattenedDT` decomposition by moving `is_simple_negation` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains compatibility delegation for this entrypoint (`backend_sv->is_simple_negation(...)`).
- Rationale:
  - simple-negation classification is consumed directly in backend-owned AST filtering flow and is better co-located with that logic,
  - extraction continues reducing `FlattenedDT` monolith size while preserving facade compatibility.
- Safety/compatibility:
  - no intended semantic change in simple-negation detection behavior,
  - backend AST filtering now invokes backend-local helper (`$self->is_simple_negation(...)`) while preserving all existing downstream filtering decisions.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-28: Backend extraction of AST-based filtering helper
- Continued structure-first `FlattenedDT` decomposition by moving `should_filter_ast_based` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains compatibility delegation for this entrypoint (`backend_sv->should_filter_ast_based(...)`).
- Rationale:
  - this helper is directly coupled to backend-owned consolidated-signal filtering flow and is better co-located in `Backend::SystemVerilog`,
  - extraction further reduces `FlattenedDT` monolith size while preserving compatibility at the facade layer.
- Safety/compatibility:
  - no intended semantic change in AST-first filtering decisions,
  - backend filtering flow now calls backend-local helper (`$self->should_filter_ast_based(...)`) while using existing `FlattenedDT` helper context for dependent checks.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-28: Backend extraction of consolidated-signal filtering entrypoint
- Continued structure-first `FlattenedDT` decomposition by moving `should_filter_consolidated_signal` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains compatibility delegation for this entrypoint (`backend_sv->should_filter_consolidated_signal(...)`).
- Rationale:
  - this filtering entrypoint is consumed directly in backend consolidated intermediate-signal generation and is better owned in `Backend::SystemVerilog`,
  - extraction reduces `FlattenedDT` monolith size while preserving compatibility at the facade surface.
- Safety/compatibility:
  - no intended semantic change in AST-first filtering behavior or fallback path,
  - backend filtering callsite now invokes backend-local helper (`$self->should_filter_consolidated_signal(...)`) while still using unchanged `FlattenedDT` analysis helpers through context access.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: Backend extraction of intermediate-reference helper
- Continued structure-first `FlattenedDT` decomposition by moving `extract_intermediate_signals_from_expression` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains compatibility delegation for this entrypoint (`backend_sv->extract_intermediate_signals_from_expression(...)`).
- Rationale:
  - this helper is consumed by backend-owned dependency analysis and substitution trace paths, so ownership is more coherent in `Backend::SystemVerilog`,
  - extraction reduces `FlattenedDT` monolith size while preserving existing call-surface compatibility.
- Safety/compatibility:
  - no intended semantic change in how referenced intermediate signals are identified across AST-factorizer/global/FSMGenFull/pre-scan registries,
  - backend callsites now invoke backend-local helper (`$self->extract_intermediate_signals_from_expression(...)`) while using unchanged analysis state.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: Clarified legacy `?fsmc` semantics for composition work
- `?fsmc` is treated as composition-layer interface extraction/wiring support for child FSM blocks in parent compositions.
- `?fsmc` intent is interface visibility/port exposure to the parent layer; WEN/EN generation is not the purpose of `?fsmc` itself.
- This clarification is now the working interpretation for ongoing composition-oriented roadmap work.
## 2026-02-27: Backend extraction of substituted-intermediate AST resolver
- Continued structure-first `FlattenedDT` decomposition by moving `get_substituted_ast_for_signal` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains compatibility delegation for this entrypoint (`backend_sv->get_substituted_ast_for_signal(...)`).
- Rationale:
  - this helper is consumed in backend consolidated-intermediate emission and belongs with adjacent backend-owned factorization/substitution helpers,
  - extraction reduces `FlattenedDT` monolith size and improves backend-local helper ownership coherence.
- Safety/compatibility:
  - no intended semantic change to substituted-AST lookup behavior from factorizer intermediate-signal results,
  - backend emission path now calls backend-local resolver (`$self->get_substituted_ast_for_signal(...)`) while using the same source data.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: Terminology and roadmap clarification
- Clarified project term: `fsmc` means FSM Compile / FSM Compiler.
- Sequencing intent:
  - first ensure `(?fsm:name ...)`, `(+fsm ...)`, and related FSM description forms are handled robustly,
  - then proceed to composition DSL capability work.
- Legacy `.plg` plugin surface is expected to be redesigned or retired in its current form.
- Prior macro-like attempts (`cclausearch`, `declarch`, `beginarch`, `endarch`, etc.) are treated as historical prototypes rather than target architecture.
## 2026-02-27: Backend extraction of recursive intermediate-signal detector
- Continued structure-first `FlattenedDT` decomposition by moving `ast_has_intermediate_signals_recursive` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains compatibility delegation for this entrypoint (`backend_sv->ast_has_intermediate_signals_recursive(...)`).
- Rationale:
  - this helper is the direct recursive partner of `ast_contains_intermediate_signals` and belongs in the same backend-owned second-pass filtering cluster,
  - extraction further reduces `FlattenedDT` monolith size and improves locality of second-pass factorization helper ownership.
- Safety/compatibility:
  - no intended semantic change in recursive intermediate-signal detection behavior,
  - backend implementation uses the same `FlattenedDT` state/helpers through context delegation while keeping recursion local to backend method ownership.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: Backend extraction of second-pass intermediate-expression filter
- Continued structure-first `FlattenedDT` decomposition by moving `ast_contains_intermediate_signals` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains compatibility delegation for this entrypoint (`backend_sv->ast_contains_intermediate_signals(...)`).
- Rationale:
  - this helper is tightly coupled to second-pass factorization expression collection and belongs with adjacent backend-owned second-pass helpers,
  - extraction further reduces `FlattenedDT` monolith size while preserving current shared factorization call paths.
- Safety/compatibility:
  - no intended semantic change to second-pass filter rules (bare-signal rejection, intermediate-signal detection, compound-expression gating),
  - backend implementation uses the same `FlattenedDT` state/helpers through context delegation.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: Backend extraction of second-pass AST substitution update helper
- Continued structure-first `FlattenedDT` decomposition by moving `update_original_asts_with_second_pass_substitutions` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains compatibility delegation for this entrypoint (`backend_sv->update_original_asts_with_second_pass_substitutions(...)`).
- Rationale:
  - this helper is part of the same backend-side factorization orchestration lane as the newly extracted second-pass feed helper and primary substitution update helper,
  - extraction further reduces `FlattenedDT` monolith size while preserving call-surface compatibility for `FSM::HDL::Factorization::Fixpoint`.
- Safety/compatibility:
  - no intended semantic change in second-pass AST synchronization behavior back into assignment analysis and assignment-condition structures,
  - helper still operates on the same `FlattenedDT` state and AST conversion helpers through backend context delegation.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: Backend extraction of second-pass AST feeding helper
- Continued structure-first `FlattenedDT` decomposition by moving `feed_current_asts_to_second_pass` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains compatibility delegation for this entrypoint (`backend_sv->feed_current_asts_to_second_pass(...)`).
- Rationale:
  - this helper is directly coupled to backend-side AST-factorization orchestration and now aligns with adjacent backend-owned factorization methods,
  - extraction reduces `FlattenedDT` monolith size while preserving call-surface compatibility used by `FSM::HDL::Factorization::Fixpoint`.
- Safety/compatibility:
  - no intended semantic change in candidate-expression collection for iterative post-substitution factorization,
  - helper behavior still uses the same `FlattenedDT` analysis state and AST filtering rules through backend context delegation.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: Shared factorization engine package (`FSM::HDL::Factorization::Fixpoint`)
- Added backend-neutral package `perl/FSM/HDL/Factorization/Fixpoint.pm` with package name `FSM::HDL::Factorization::Fixpoint`.
- Moved iterative post-substitution convergence logic out of `FlattenedDT::Backend::SystemVerilog` and into the shared package.
- `Backend::SystemVerilog` now keeps compatibility ownership at API surface level (`run_second_pass_factorization`) but delegates execution to the shared package.
- Rationale:
  - convergence/fixpoint factorization is synthesis-stage logic and should not be tied to one HDL emitter,
  - package naming now reflects algorithm purpose and is reusable by all present/future backends,
  - this preserves ongoing decomposition strategy (`FlattenedDT` facade + backend delegation + shared synthesis utilities).
- Convergence/termination policy preserved in shared module:
  - no factorable post-substitution expressions,
  - no new factorization candidates,
  - repeated expression signature (oscillation/replay guard),
  - no substitution progress in pass,
  - max pass cap reached.
- Verification:
  - syntax checks for `Fixpoint.pm`, `Backend/SystemVerilog.pm`, and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: Backend extraction of second-pass factorization orchestration
- Continued structure-first `FlattenedDT` decomposition by moving `run_second_pass_factorization` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains only compatibility delegation for this entrypoint (`backend_sv->run_second_pass_factorization(...)`).
- Rationale:
  - this method is orchestration logic for second-pass AST factorization and belongs with adjacent backend factorization helpers already moved,
  - co-locating this orchestration in backend ownership further reduces `FlattenedDT` monolith pressure.
- Safety/compatibility:
  - no intended semantic change in second-pass factorization behavior, substitution, or diagnostics,
  - migrated routine continues to use existing `FlattenedDT` helper/state interfaces through backend context delegation.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: Backend extraction of AST substitution-backpropagation helper
- Continued structure-first `FlattenedDT` decomposition by moving `update_original_asts_with_substituted_versions` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains only compatibility delegation for this entrypoint (`backend_sv->update_original_asts_with_substituted_versions(...)`).
- Rationale:
  - this helper is part of backend-side AST-factorization orchestration where substitution results are propagated back into analysis structures,
  - extracting it co-locates substitution orchestration helpers with the backend factorization flow and reduces `FlattenedDT` monolith size.
- Safety/compatibility:
  - no intended semantic change in AST substitution synchronization behavior,
  - migrated routine continues using the same `FlattenedDT` analysis data and AST conversion helpers through backend context delegation.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: Backend extraction of unary-negation counting helper
- Continued structure-first `FlattenedDT` decomposition by moving `count_unary_negations_in_original_expressions` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains only compatibility delegation for this entrypoint (`backend_sv->count_unary_negations_in_original_expressions()`).
- Rationale:
  - this helper is part of backend-side AST-factorization orchestration diagnostics and belongs with adjacent factorization backend methods,
  - extracting it further reduces `FlattenedDT` monolith size while preserving existing call flow.
- Safety/compatibility:
  - no intended semantic change in unary-negation diagnostics or debug output,
  - migrated routine continues operating on the same `FlattenedDT` analysis data through backend context access.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: Backend extraction of AST-factorizer input feeding
- Continued structure-first `FlattenedDT` decomposition by moving `feed_asts_to_factorizer` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains only compatibility delegation for this entrypoint (`backend_sv->feed_asts_to_factorizer(...)`).
- Rationale:
  - this routine is part of the same backend-side AST-factorization pipeline as `run_global_ast_factorization`,
  - extracting it keeps factorization orchestration and its input collection logic co-located in backend ownership.
- Safety/compatibility:
  - no intended semantic change in factorizer inputs (DT enables, LHS enables, assignment conditions, FSMGen intermediate ASTs),
  - migrated routine continues operating on existing `FlattenedDT` state through context delegation.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: Backend extraction of global AST-factorization orchestration
- Continued structure-first `FlattenedDT` decomposition by moving `run_global_ast_factorization` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains only compatibility delegation for this entrypoint (`backend_sv->run_global_ast_factorization()`).
- Rationale:
  - this routine is tightly coupled to intermediate-signal emission flow and is part of backend-side SystemVerilog generation orchestration,
  - extracting it further reduces `FlattenedDT` monolith size while preserving runtime call sites.
- Safety/compatibility:
  - behavior remains unchanged (factorizer setup, substitution flow, second-pass factorization, and trace output preserved),
  - migrated routine continues using existing `FlattenedDT` helper methods through context delegation,
  - added `List::Util::min` import in backend module to preserve existing debug/report loops.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: Backend extraction of consolidated intermediate signal emission
- Continued the structure-first `FlattenedDT` decomposition by moving `generate_consolidated_intermediate_signals` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains only compatibility delegation for this entrypoint (`backend_sv->generate_consolidated_intermediate_signals(...)`).
- Rationale:
  - this method is pure SystemVerilog emission/control-flow in the generation pipeline and belongs with backend ownership,
  - extracting it reduces monolithic pressure in `FlattenedDT` while preserving call-site compatibility.
- Safety/compatibility:
  - no intended semantic changes in intermediate-signal filtering/factorization behavior,
  - existing helper calls remain anchored through `FlattenedDT` context methods,
  - added `Scalar::Util::blessed` import in backend module to preserve runtime behavior of migrated signal-introspection logic.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: First-class tracing architecture and policy
- FSMGen tracing is now treated as a first-class runtime capability, not a best-effort debug print layer.
- Decision:
  - canonical verbosity model uses named levels (`none`, `low`, `medium`, `high`, `debug`) mapped to numeric levels `0..4`,
  - numeric `--debug` compatibility is preserved to avoid breaking existing workflows/scripts.
- Tracing substrate design in `perl/FSM/Debug.pm`:
  - centralized trace-level parsing/normalization,
  - structured trace events (`topic`, `enter`, `exit`, `decision`),
  - source metadata embedding (`file`, `function`, `line`) for each trace line,
  - indentation-aware formatting and optional emoji markers for readability in long runs.
- Routing policy:
  - when trace-log routing is enabled, trace output is written to `trace.log` (or configured path) instead of stdout,
  - trace sink lifecycle is explicitly managed (open/set, flush/close, clear) to avoid fd leaks and stale handles.
- CLI policy in `bin/fsmgen`:
  - explicit trace controls are provided (`--trace-verbosity`, `--trace-log[=FILE]`, `--trace-emojis`, `--notrace-emojis`),
  - legacy tee-based debug output plumbing was removed to avoid split behavior and to make trace routing deterministic.
- Instrumentation scope for this slice:
  - added structured enter/exit/decision/topic tracing in key adapter/pipeline facades:
    - `perl/FSM/Pipeline/HDLGenerator.pm`,
    - `perl/FSM/Adapter/FSMGenFull.pm`,
    - `perl/FSM/Adapter/FSMGenFull/Parser.pm`.
- Verification outcome:
  - syntax checks for touched files are clean,
  - added `t/06-tracing-system.t` and full suite remains green (`Files=6`, `Tests=125`).
- Boundaries:
  - this slice instruments current Perl pipeline surfaces only;
  - no Rust pipeline instrumentation was added because no active `rust/` tree exists in this repository.
## 2026-02-27: Canonical commit workflow document added
- Added `COMMIT.md` as a tracked, canonical workflow contract for future AI handoffs.
- The document defines:
  - when to execute commit workflow (after each completed task/activity, and on explicit commit-workflow requests),
  - exact file responsibilities (`COMMIT.md`, `MEMORY.md`, `CHANGES.md`, `DEVELOPMENT_NOTES.md`, `git_message_brief.txt`, changed source/test files),
  - exact operation order (task completion -> ordered doc updates -> validation -> stage/commit -> truncate brief message file -> status verification).
- Rationale:
  - reduce ambiguity across AI session boundaries,
  - enforce consistent commit hygiene and file-update ordering,
  - preserve a single authoritative process reference in-repo.
## 2026-02-24: FlattenedDT decomposition model formalized (Orchestrator + Backend, with EnableGraph as helper)
- The next architecture phase keeps `FSM::Synthesis::EnableGraph` as a synthesis helper module used by `FlattenedDT` (not a direct `FlattenedDT` submodule breakdown track).
- `FlattenedDT` decomposition is explicitly tracked as two direct module tracks:
  - `Orchestrator`: top-level generation pipeline sequencing ownership,
  - `Backend` modules: rendering/emitter ownership.
- Enable-synthesis helper extraction into `EnableGraph` continues in parallel with the direct `FlattenedDT` breakdown.
- First extraction slice for this phase is complete:
  - created `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`,
  - moved `generate_systemverilog` pipeline sequencing into the orchestrator,
  - kept `FlattenedDT` as compatibility facade delegating `generate_systemverilog(...)`.
- Next extraction slice for this phase is complete:
  - created `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - moved `generate_module_declaration` backend emission into the backend module,
  - kept `FlattenedDT` as compatibility facade delegating `generate_module_declaration(...)`.
- Current extraction slice for this phase:
  - moved `generate_state_encoding` backend emission into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - kept `FlattenedDT` as compatibility facade delegating `generate_state_encoding(...)`.
- Latest extraction slice for this phase:
  - moved `generate_state_register` backend emission into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - kept `FlattenedDT` as compatibility facade delegating `generate_state_register(...)`.
- Current extraction slice for this phase:
  - moved `generate_enable_conditions` backend emission into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - kept `FlattenedDT` as compatibility facade delegating `generate_enable_conditions(...)`.
- Latest extraction slice for this phase:
  - moved `generate_header` backend emission into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - kept `FlattenedDT` as compatibility facade delegating `generate_header(...)`.
- Current extraction slice for this phase:
  - moved `generate_internal_signal_declarations` backend emission into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - kept `FlattenedDT` as compatibility facade delegating `generate_internal_signal_declarations(...)`.
- Latest extraction slice for this phase:
  - created `perl/FSM/HDL/FlattenedDT/Backend/Verilog.pm`,
  - moved Verilog generation ownership (`generate_verilog`, `convert_systemverilog_to_verilog`) into the dedicated Verilog backend module,
  - kept `FlattenedDT` as compatibility facade delegating Verilog-generation entrypoints.
- Current extraction slice for this phase:
  - moved WEN/EN emission entrypoint ownership (`generate_wen_en_signals`) into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - kept `FlattenedDT` as compatibility facade delegating `generate_wen_en_signals(...)`,
  - maintained strict behavior-preserving structure-first decomposition (no intended HDL semantic deltas).
- Latest extraction slice for this phase:
  - moved intermediate-signal declaration emission ownership (`generate_intermediate_signal_declarations`) into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - kept `FlattenedDT` as compatibility facade delegating `generate_intermediate_signal_declarations(...)`,
  - maintained strict behavior-preserving structure-first decomposition (no intended HDL semantic deltas).
- Current extraction slice for this phase:
  - moved combinational-mux emission ownership (`generate_comb_mux`) into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - kept `FlattenedDT` as compatibility facade delegating `generate_comb_mux(...)`,
  - maintained strict behavior-preserving structure-first decomposition (no intended HDL semantic deltas).
- Latest extraction slice for this phase:
  - moved flop-mux emission ownership (`generate_flop_mux`) into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - kept `FlattenedDT` as compatibility facade delegating `generate_flop_mux(...)`,
  - maintained strict behavior-preserving structure-first decomposition (no intended HDL semantic deltas).
- Rationale:
  - reduce monolithic file size and cognitive load,
  - improve ownership clarity before deeper backend splits,
  - preserve behavior by changing structure first and semantics later only when explicitly intended.
- Near-term follow-through:
  - continue backend-focused extractions in small parity-validated slices,
  - retain compatibility delegates until call sites converge and regressions remain stable.

## 2026-02-22: Phase-1 intent model clarification (`<-` vs `<=`)
- Assignment intent is now explicitly captured at AST assignment nodes (`assignment_intent`, `source_provenance`, `output_exposure`).
- The `<=` semantic intent is explicitly encoded as:
  - `register_style = input_named`
  - `lhs_binding = flop_d_input`
  - `immediate_visibility = same_cycle_on_d_input`
  - `hold_policy = q_feedback_when_no_enable`
- The `<-` semantic intent is explicitly encoded as:
  - `register_style = output_named`
  - `lhs_binding = flop_q_output`
  - `hold_policy = q_feedback_when_no_enable`

This preserves the intended modeling distinction:
- `<-` names/registers the flop output (`Q`) as LHS.
- `<=` names the flop input side (`D`) as LHS while maintaining storage behavior by feedback when enables are inactive.

## Current parser/generator model
- Parse flow is modularized into `SignalManager`, `ExpressionBuilder`, `Parser`, and `SignalAnalyzer`.
- Fail-fast behavior uses `Carp::confess` with stack traces instead of silent parser failures.
- The regression baseline remains CLI-level (`prove -v t/01-regression.t`) to validate real generation paths.

## Assignment semantics and safety policy
### Semantics
- `=` is combinational.
- `<-` and `<=` are synchronous/flopped forms.

### Safety rule
- Combinational assignments must not create self-dependency:
  - direct (`A = A`)
  - indirect/transitive (`A = f(B)`, `B = g(A)`)
- Synchronous feedback is valid (`A <- A`) and intentionally preserved.

## Why graph-based combinational validation was chosen
Direct text checks are insufficient because harmful dependence can be indirect.  
Decision:
- Track combinational dependencies as graph edges (`lhs -> rhs signal`) during parse.
- Validate cycle reachability per combinational target before module return.
- Reject with explicit error if any path returns to the same target.

Benefits:
- One generalized guard handles all `A = f(...)` cases.
- Order-independent detection (works regardless of statement order in source).
- Clear extension point for future combinational rule checks.

## Parser improvements retained
- Compound update shorthand and inline forms are supported:
  - `(++ sig)`, `(-- sig)`, `(+=K sig)`, `(-=K sig)`
  - `(A <- B (+= 2))`, `(A = B (-= 1))`
- Packed nested condition encoding is handled:
  - `['<', [cond, ...]]`
  - `['<!', [cond, ...]]`
- Scalar negation tokens and packed operands are normalized in expression parsing.

## Backend status rationale
- Verilog path exists via SystemVerilog emission followed by deterministic textual lowering.
- VHDL path is intentionally explicit not-implemented rather than failing with missing method errors.
- This prevents ambiguous failures and keeps CLI behavior predictable.

## Documentation consolidation policy (current)
- Canonical top-level docs:
  - `README.md` (overview + quickstart)
  - `CHANGES.md` (persistent technical history)
  - `DEVELOPMENT_NOTES.md` (this file; rationale and context)
- Canonical user guide:
  - `docs/USER_GUIDE.md`
- Investigation-era and duplicate docs are removed once their conclusions are merged into canonical files.

## Ongoing engineering expectations
- Keep debug messages traceable with clear `[file][function()]` context.
- Prefer AST-based generation/transforms over regex-driven rewrites.
- Add focused regression tests for every parser/generator rule that can silently regress.

## Legacy `fx/perl/FSMGen.pm` reference analysis (full)
This section preserves the detailed legacy analysis so future work can port behavior intentionally, not accidentally.

### Scope analyzed
The legacy flow analysis covered:
- `fx/bin/fsmgen`
- `fx/perl/FSMGen.pm`
- `fx/perl/PPlugin.pm`, `PathSearch.pm`, `Lispish.pm`, `LinkedSpec.pm`, `LinkedRE.pm`, `RTLUtils.pm`, `Global.pm`, `HUtils.pm`
- `fx/conf/fsmgen.conf`, `fx/conf/fxstart.conf`, `fx/perl/env.conf`
- `fx/plugin/fsmgen.plg`
- `fx/specs/Lispish.spec`, `fx/specs/DT.spec`, `fx/specs/pplugin.spec`

### Legacy execution model
Primary invocation:
- `fx/bin/fsmgen` parsed CLI options, then called `FSMGen::start_from_file(...)`.

Entry functions in `FSMGen.pm`:
- `start_from_file`
- `top_from_tree`
- `top_from_string`

Initialization chain:
1. Merge user config with `Global->set('fsmgen')`.
2. Parse source into Lispish ATree (`fsm_file_load` / `Lispish::multi`).
3. Classify top-level forms (`?define:*`, `?fsm:*`, `?top:*`) in `fsm_initialize`.
4. Run either FSM compile flow (`fsm_analyze`/`fsm_top_gen`) or top composition flow (`top_exec`) depending on form.

### Legacy FSM compile pipeline (from `FSMGen.pm`)
Main path:
- `fsm_analyze` -> `fsm_analyze_jo` -> `fsm_walk` -> `fsm_drive_wen` -> `fsm_entity_gen` -> `fsm_architecture_gen` -> `create_data_path` -> `create_top` -> `drive_modules`.

#### `fsm_walk` responsibilities
Handled per-FSM top entries:
- state decision trees (`state_name`)
- standalone decision trees (`-name`)
- async reset (`:=`)
- sync reset (`:<`; hook present, effectively not fully realized)
- shared sections (`+system`, `+size`, etc.)

#### DT propagation and node types
`dtree_walk` / `dtree_node_iterate` handled:
- assignments
- transitions (`->`)
- test nodes (`?signal`, boolean and shortcut forms)
- repeat expansion (`?repeat:N`)
- logical expressions
- increment/decrement shorthand rewrites

### Assignment semantics in legacy flow
Legacy intent encoded by operator families:
- `A <- B` : register output named `A` (`Q`-named style)
- `A <= B` : register input/mux side named `A` (D-input named style)
- `A = B`  : combinational
- `A <-= B` (`rm`) and `A <=+ B` (`mr`) variants for dual visibility needs
- `A <N B` (`pN`) pulse-style form with exact-delay intent (`Q+N`) for a one-cycle pulse
- auto update shorthands rewritten to canonical assignment structures:
  - `++`, `--`, `+=K`, `-=K`

RHS elaborations supported:
- slices (`sig[i]`, `sig[i:j]`)
- literal handling with width inference/normalization
- local helper RHS signals for slice/incdec elaboration

### Authoritative clarification for `<N` / `pN`
- User-intended semantics: `<N` means an exact delayed pulse request where the one-cycle pulse is emitted at decision cycle `Q+N`.
- `N` is a delay/latency parameter, not a pulse-width parameter.
- Legacy comments/code paths mention pulse behavior but pulse-specific backend realization was not completed in the original implementation.

### WEN/OWEN architecture (core legacy strength)
Legacy flow constructed enables in layered steps:
1. DT-local WENs:
   - built from condition stack (`cstack`) at each traversal point.
2. DT-level per-(assignment_type,LHS,RHS) OR enables:
   - `dtowens` aggregation.
3. FSM-level per-(assignment_type,LHS,RHS) enable:
   - OR across all controlling DTs (`fsmowens` mapping).

Notable behavior:
- State-variable-targeted enables were treated differently from non-state outputs.
- State-selection constants and selection signals were generated as one-hot controls.
- Enable naming and grouping were deterministic and central to generated mux/control structure.

### Legacy entity/architecture generation
`fsm_entity_gen` and `fsm_architecture_gen` emitted:
- system/control/output ports
- EQ signals
- local WEN and OR-WEN signals
- state type/encoding support
- state register process
- slice/helper assignments

This produced a control block with explicit, traceable control enables.

### Legacy datapath generation
`create_data_path` built datapath logic from assignment groupings:
- Grouped all assignments by LHS/RHS and assignment type.
- Built selection constants (typically one-hot) and selection signals.
- Built per-LHS mux-style next/output equations.
- Generated register processes for non-combinational classes.
- Applied hold/feedback defaults when no enable path active.
- Handled tricky LHS/RHS overlap cases (avoid accidental top exposure by default).

### Legacy top generation and interface policy
`create_top` and related architecture wiring implemented:
- connect-by-name composition across generated modules
- automatic top interface synthesis
- signal vs port classification based on producer/consumer directions
- explicit output override via `>` suffix semantics
- filtering of internal feedback nets from top outputs unless explicitly requested

This behavior was practical and production-oriented for control/datapath partitioning.

### Legacy composition DSL capabilities (`top_exec`)
`top_exec` supported a composition/meta flow with forms like:
- `?fsmc` (compile FSM collections)
- `?rtl` (bind external RTL entities)
- `?ports`
- `?toplink`
- `?top`
- macro expansion via `?&...`

Plus plugin hook phases (via `.plg`):
- `cclausearch`, `declarch`, `beginarch`, `endarch`, etc.

### Legacy strengths worth preserving
1. Layered enable architecture (DT local -> DT grouped -> FSM grouped).
2. Clear semantic split of `<-` vs `<=`.
3. Robust practical interface policy (`auto` + explicit override).
4. Datapath/control decomposition based on grouped assignment intent.
5. Rich composition workflow for building larger tops.

### Legacy fragilities to avoid reintroducing
1. Dynamic/eval-heavy parser/plugin infrastructure (`LinkedSpec` + plugin eval model).
2. Large mutable global hash state and implicit contracts between passes.
3. Partially implemented branches mixed into production paths.
4. Width/type inference scattered across many late-stage transformations.

### Modernization mapping (why this analysis matters)
Current modernization direction is to port legacy strengths into:
- explicit AST intent metadata (now in phase 1)
- deterministic synthesis passes (future `EnableGraph`/composition layers)
- backend-independent lowering
- typed extension APIs instead of eval-based plugin semantics

This section is the reference baseline for deciding whether a behavior is:
- intentionally preserved,
- intentionally changed,
- or still pending implementation.

## 2026-02-22: Assignment-family reference (`c`, `r`, `m`, `rm`, `mr`, `pN`)
This section captures the authoritative operator mapping and the finalized implementation intent.

### Operator family mapping (legacy intent, now explicit in modern metadata)
- `A = B`  -> `c` (combinational)
- `A <- B` -> `r` (register-output named; LHS is Q-facing)
- `A <= B` -> `m` (mux/D-input named; LHS is D-facing visible net)
- `A <-= B` -> `rm` (`r` + expose `next_A`)
- `A <=+ B` -> `mr` (`m` + expose `A_r`)
- `A <N B` -> `pN` (delayed pulse family)

### `<=+` (`mr`) behavior
- Classified as `mr`, with regular `m` behavior for main LHS datapath semantics.
- Also exposes a Q-side mirror output `<lhs>_r`.
- In generated HDL this is realized by driving `<lhs>_r` from the corresponding flop-feedback node.

### Authoritative `pN` interpretation (must not regress)
`pN` is **not** a duration operator.  
It is an exact-delay pulse request:
- Decision cycle is `Q`.
- Pulse emission cycle is exactly `Q+N`.
- Pulse width is exactly one cycle.
- Polarity is defined by RHS level:
  - `<N 1`: positive pulse (rest `0`, pulse `1`, i.e. `0->1->0`)
  - `<N 0`: negative pulse (rest `1`, pulse `0`, i.e. `1->0->1`)

### Legacy note vs modern implementation
- Legacy comments in `fx/perl/FSMGen.pm` mention pulse semantics and may read like “N-cycle pulse length”.
- Legacy backend path was incomplete for dedicated pulse realization.
- Modernized backend now treats `pN` as exact `Q+N` one-cycle pulse semantics (delay, not duration), matching the clarified framework intent.

## 2026-02-22: Hardening pass after assignment-family implementation
### Edge-case semantics now regression-locked
- Added explicit tests for `pN` with `N=0` to lock immediate-cycle delayed pulse behavior:
  - `<0 1` -> positive one-cycle pulse with rest `0`.
  - `<0 0` -> negative one-cycle pulse with rest `1`.
- Added explicit conflict-rejection regression coverage:
  - mixed combinational + sequential operators on same LHS,
  - mixed pulse-delayed + non-pulse sequential operators on same LHS,
  - multiple pulse delays on same LHS.
- Added explicit parser rejection coverage for invalid `<N` RHS (must be literal `0` or `1`).

### Snapshot strategy for rm/mr/pN
- Introduced targeted HDL golden snapshots (not only regex-based checks) for:
  - module ports (`next_*` and `*_r` exposure/width),
  - rm (`<-=`) emitted block,
  - mr (`<=+`) emitted block,
  - pN delayed pulse blocks.
- Rationale:
  - protect behavioral semantics *and* emitted structural shape from accidental drift.

### Enable-synthesis extraction seam (slice start)
- Added `FSM::Synthesis::EnableGraph` as an orchestration seam for enable synthesis.
- `FlattenedDT` now delegates complete enable-structure generation through this layer.
- This is an intentional first extraction step:
  - behavior-preserving refactor first,
  - deeper decomposition can proceed in subsequent slices with reduced risk.
- Latest behavior-preserving increment:
  - RHS grouping (`group_assignments_by_rhs`) now also runs through `EnableGraph`,
  - `FlattenedDT` delegates that step instead of owning the grouping implementation directly.
- Newest behavior-preserving increment:
  - multiplexer configuration assembly (`build_multiplexer_config`) now also runs through `EnableGraph`,
  - `FlattenedDT` delegates that step, further separating synthesis orchestration from backend monolith code.
- Latest behavior-preserving increment:
  - unified assignment-analysis orchestration (`build_unified_assignment_analysis`) now runs through `EnableGraph`,
  - `FlattenedDT` delegates the full per-LHS phase-1 analysis loop to the synthesis layer while reusing existing delegated sub-steps.
- Newest behavior-preserving increment:
  - unified phase-2 enable emission orchestration (`generate_unified_wen_en_signals`) now runs through `EnableGraph`,
  - DT-specific and LHS-level enable emitters (`generate_dt_enables_from_analysis`, `generate_lhs_enables_from_analysis`) now run through `EnableGraph`,
  - `FlattenedDT` delegates these phase-2 WEN/EN generation entrypoints to the synthesis layer.
- Latest behavior-preserving increment:
  - unified phase-3 assignment emission orchestration (`generate_signal_assignments`) now runs through `EnableGraph`,
  - `FlattenedDT` delegates this phase-3 multiplexer-emission entrypoint while retaining existing per-assignment-type mux emitters in `FlattenedDT`.
- Newest behavior-preserving increment:
  - unified combinational mux emission (`generate_unified_comb_mux`) now runs through `EnableGraph`,
  - phase-3 orchestration in `EnableGraph` now invokes its local combinational mux emitter,
  - `FlattenedDT` delegates the combinational mux emitter entrypoint to the synthesis layer.
- Latest behavior-preserving increment:
  - unified flop mux emission (`generate_unified_flop_mux`) now runs through `EnableGraph`,
  - phase-3 orchestration in `EnableGraph` now invokes its local flop mux emitter,
  - `FlattenedDT` delegates the flop mux emitter entrypoint to the synthesis layer.
- Session continuity policy increment:
  - added `MEMORY.md` as a live, compact resumption artifact for crash/session-handoff recovery,
  - mandated update order after each completed task: `MEMORY.md` first, then other affected live docs, then commit workflow,
  - `MEMORY.md` now carries fast-start context (recent milestones, active architecture status, and immediate next-step orientation).
- Latest behavior-preserving increment:
  - unified pulse-delay emission (`generate_unified_pulse_delay_logic`) now runs through `EnableGraph`,
  - phase-3 orchestration in `EnableGraph` now invokes its local pulse-delay emitter,
  - `FlattenedDT` delegates the pulse-delay emitter entrypoint to the synthesis layer.
- Newest behavior-preserving increment:
  - pulse helper analysis methods (`get_pulse_delay_cycles_for_lhs`, `get_pulse_active_level_for_lhs`, `normalize_rhs_logic_level`) now run through `EnableGraph`,
  - `EnableGraph` pulse-delay emission now resolves delay/active-level metadata through local helper ownership,
  - `FlattenedDT` retains compatibility delegations for these helper methods.
- Latest behavior-preserving increment:
  - enable naming helpers (`clean_signal_name`, `generate_rhs_based_enable_name`) now run through `EnableGraph`,
  - `EnableGraph` enable-structure generation now resolves naming through local helper ownership,
  - `FlattenedDT` retains compatibility delegations for these naming helper methods.
- Newest behavior-preserving increment:
  - assignment-type helpers (`signal_uses_register_assignment`, `get_signal_assignment_type`) now run through `EnableGraph`,
  - `EnableGraph` phase-3 mux/pulse selection path now resolves assignment families through local helper ownership,
  - `FlattenedDT` retains compatibility delegations for these assignment-type helper methods.
- Latest behavior-preserving increment:
  - driven-signal classification (`get_driven_signals`) now runs through `EnableGraph`,
  - `EnableGraph` now owns auxiliary output exposure classification for sequential dual families (`next_<lhs>` for `rm`, `<lhs>_r` for `mr`) using local assignment-type helper ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint so module declaration logic remains behavior-identical while ownership shifts.
- Newest behavior-preserving increment:
  - reset-value resolution (`get_reset_value`) now runs through `EnableGraph`,
  - `FlattenedDT` retains a compatibility delegation entrypoint for reset-value queries,
  - reset-state and reset-metadata discovery remains in existing `FlattenedDT` helper methods for now, enabling staged extraction without semantic drift.
- Latest behavior-preserving increment:
  - default-value resolution (`get_default_value`) now runs through `EnableGraph`,
  - `FlattenedDT` retains a compatibility delegation entrypoint for default-value queries,
  - AST-based default-value lookup flow (`get_default_value_from_ast`) remains behavior-identical and now lands on `EnableGraph` ownership through delegation.
- Newest behavior-preserving increment:
  - signal-info discovery (`get_signal_info`) now runs through `EnableGraph`,
  - `FlattenedDT` retains a compatibility delegation entrypoint for signal-info queries,
  - `EnableGraph` reset-value resolution now calls local signal-info ownership while preserving staged delegation for reset-state/explicit-reset helpers.
- Latest behavior-preserving increment:
  - explicit-reset discovery (`get_explicit_reset_value`) now runs through `EnableGraph`,
  - `FlattenedDT` retains a compatibility delegation entrypoint for explicit-reset queries,
  - `EnableGraph` reset-value resolution now calls local explicit-reset ownership while preserving staged delegation for reset-state helper logic.
- Newest behavior-preserving increment:
  - reset-state discovery (`get_fsm_reset_state`) now runs through `EnableGraph`,
  - `FlattenedDT` retains a compatibility delegation entrypoint for reset-state queries,
  - `EnableGraph` reset-value resolution now calls local reset-state ownership for state-variable reset behavior.
- Latest behavior-preserving increment:
  - AST reset-value lookup (`get_reset_value_from_ast`) now runs through `EnableGraph`,
  - `EnableGraph` unified flop-mux emission now calls local AST reset-value ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for AST reset-value queries.
- Newest behavior-preserving increment:
  - AST default-value lookup (`get_default_value_from_ast`) now runs through `EnableGraph`,
  - `EnableGraph` multiplexer config assembly now calls local AST default-value ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for AST default-value queries.
- Latest behavior-preserving increment:
  - explicit-reset configuration setter (`set_explicit_reset_values`) now runs through `EnableGraph`,
  - `FlattenedDT` retains a compatibility delegation entrypoint for explicit-reset configuration updates,
  - `EnableGraph` now owns writes to explicit reset configuration consumed by reset-resolution helper paths.
- Newest behavior-preserving increment:
  - FSM module-reference setter (`set_fsm_module_reference`) now runs through `EnableGraph`,
  - `FlattenedDT` retains a compatibility delegation entrypoint for FSM module-reference storage,
  - `EnableGraph` now owns writes to the shared FSM module reference used by signal-info/reset helper paths.
- Latest behavior-preserving increment:
  - register-classification helpers (`is_register`, `fallback_register_analysis_from_assignments`) now run through `EnableGraph`,
  - `EnableGraph` multiplexer configuration assembly now resolves register-vs-combinational classification through local helper ownership,
  - `FlattenedDT` retains compatibility delegation entrypoints for these register-classification helper paths.
- Newest behavior-preserving increment:
  - AST signal-name extraction helper (`extract_signal_name_from_ast`) now runs through `EnableGraph`,
  - `EnableGraph` AST reset/default helper paths now resolve signal names through local helper ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for AST signal-name extraction.
- Latest behavior-preserving increment:
  - LHS-width analysis helper (`get_lhs_width_from_analysis`) now runs through `EnableGraph`,
  - `EnableGraph` pulse-delay emission now resolves target width through local helper ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for LHS-width analysis.
- Newest behavior-preserving increment:
  - intermediate-signal AST tracker (`track_ast_intermediate_signals`) now runs through `EnableGraph`,
  - `EnableGraph` DT/LHS enable emission paths now call local intermediate-signal tracking ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for intermediate-signal AST tracking.
- Latest behavior-preserving increment:
  - intermediate-signal classification helper (`is_intermediate_signal`) now runs through `EnableGraph`,
  - `EnableGraph` intermediate-signal AST tracking path now calls local classification ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for intermediate-signal classification.
- Newest behavior-preserving increment:
  - AST-based intermediate classification helper (`is_signal_ast_based_intermediate`) now runs through `EnableGraph`,
  - `EnableGraph` intermediate-signal classification path now calls local AST-based classification ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for AST-based intermediate classification.
- Latest behavior-preserving increment:
  - AST factorization operator helper (`_ast_contains_factorizable_operators`) now runs through `EnableGraph`,
  - `EnableGraph` AST-based intermediate classification path now calls local operator-analysis ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for AST factorization operator analysis.
- Newest behavior-preserving increment:
  - arithmetic-operation helper (`is_arithmetic_operation`) now runs through `EnableGraph`,
  - `EnableGraph` AST factorization operator-analysis path now calls local arithmetic-operation ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for arithmetic-operation helper paths.
- Latest behavior-preserving increment:
  - logical-operation helper (`is_logical_operation`) now runs through `EnableGraph`,
  - `EnableGraph` AST factorization operator-analysis path now calls local logical-operation ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for logical-operation helper paths.
- Newest behavior-preserving increment:
  - logical-factorization policy helper (`should_factor_logical_operation`) now runs through `EnableGraph`,
  - `EnableGraph` AST factorization operator-analysis path now calls local logical-factorization policy ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for logical-factorization policy helper paths.
- Latest behavior-preserving increment:
  - frequent-logical-usage helper (`contains_frequently_used_operations`) now runs through `EnableGraph`,
  - `EnableGraph` logical-factorization policy path now calls local frequent-logical-usage ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for frequent-logical-usage helper paths.
- Newest behavior-preserving increment:
  - intermediate-signal expression resolver (`get_intermediate_signal_expression`) now runs through `EnableGraph`,
  - `EnableGraph` frequent-logical-usage helper path now calls local intermediate-signal expression ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for intermediate-signal expression resolver paths.
- Latest behavior-preserving increment:
  - intermediate-signal expression synthesis helper (`generate_expression_from_signal_name`) now runs through `EnableGraph`,
  - `EnableGraph` intermediate-signal expression resolver path now calls local expression-synthesis ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for intermediate-signal expression synthesis helper paths.
- Newest behavior-preserving increment:
  - AST-based intermediate-name metadata helper (`_signal_name_indicates_ast_operators`) now runs through `EnableGraph`,
  - `EnableGraph` AST intermediate classification path now calls local intermediate-name metadata ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for AST-based intermediate-name metadata helper paths.
- Latest behavior-preserving increment:
  - AST-to-SystemVerilog rendering helper (`ast_to_systemverilog`) now runs through `EnableGraph`,
  - `EnableGraph` DT/LHS enable emission paths now call local AST rendering ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for AST-to-SystemVerilog rendering helper paths.
- Newest behavior-preserving increment:
  - AST signal-reference traversal helper (`ast_contains_signal`) now runs through `Backend::SystemVerilog`,
  - backend final-expression usage-check paths now call local AST signal-reference traversal ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for AST signal-reference traversal helper paths.
- Latest behavior-preserving increment:
  - substitution-reference usage helper (`is_signal_referenced_in_substitutions`) now runs through `Backend::SystemVerilog`,
  - backend AST/string filtering paths now call local substitution-reference usage ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for substitution-reference usage helper paths.
- Newest behavior-preserving increment:
  - intermediate-signal dependency ordering helper (`topologically_sort_signals`) now runs through `Backend::SystemVerilog`,
  - backend consolidated intermediate-signal emission now calls local dependency ordering ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for dependency ordering helper paths.
- Latest behavior-preserving increment:
  - backend factorization/filtering callsites were converged to backend-local ownership in `Backend::SystemVerilog`,
  - callsites now invoke local helper ownership for `is_signal_referenced_in_substitutions`, `run_global_ast_factorization`, `feed_asts_to_factorizer`, `count_unary_negations_in_original_expressions`, `update_original_asts_with_substituted_versions`, and `run_second_pass_factorization`,
  - this removes backend round-trips through `FlattenedDT` delegation while preserving output and test behavior.
- Newest behavior-preserving increment:
  - second-pass AST feed checks were converged to backend-local `ast_contains_intermediate_signals` ownership in `Backend::SystemVerilog`,
  - DT/LHS/assignment condition second-pass gating now calls local intermediate-signal detection ownership,
  - this removes remaining backend delegation round-trips for this helper path while preserving output/test behavior.
- Latest behavior-preserving increment:
  - backend unified WEN/EN generation callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - phase-2 WEN/EN emission now invokes `enable_graph->generate_unified_wen_en_signals(...)` directly,
  - this removes the backend delegation round-trip through `FlattenedDT` for this path while preserving output/test behavior.
- Newest behavior-preserving increment:
  - backend intermediate-signal expression lookup callsites were converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - consolidated and declaration emission paths now invoke `enable_graph->get_intermediate_signal_expression(...)` directly,
  - this removes remaining backend delegation round-trips through `FlattenedDT` for intermediate-signal expression resolution while preserving output/test behavior.
- Latest behavior-preserving increment:
  - backend driven-signal classification callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - module-declaration port-direction analysis now invokes `enable_graph->get_driven_signals(...)` directly,
  - this removes the backend delegation round-trip through `FlattenedDT` for driven-signal lookup while preserving output/test behavior.
- Newest behavior-preserving increment:
  - backend assignment-type classification callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - internal-signal declaration analysis now invokes `enable_graph->get_signal_assignment_type(...)` directly,
  - this removes the backend delegation round-trip through `FlattenedDT` for assignment-type lookup while preserving output/test behavior.
- Latest behavior-preserving increment:
  - backend LHS-width analysis callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - internal-signal declaration analysis now invokes `enable_graph->get_lhs_width_from_analysis(...)` directly,
  - this removes the backend delegation round-trip through `FlattenedDT` for LHS-width lookup while preserving output/test behavior.
- Newest behavior-preserving increment:
  - backend pulse-delay-cycle lookup callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - internal-signal declaration analysis now invokes `enable_graph->get_pulse_delay_cycles_for_lhs(...)` directly,
  - this removes the backend delegation round-trip through `FlattenedDT` for pulse-delay-cycle lookup while preserving output/test behavior.
- Latest behavior-preserving increment:
  - backend reset-value lookup callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - flop-mux reset emission now invokes `enable_graph->get_reset_value(...)` directly,
  - this removes the backend delegation round-trip through `FlattenedDT` for reset-value lookup while preserving output/test behavior.
- Newest behavior-preserving increment:
  - backend default-value lookup callsites were converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - comb/flop mux default assignment emission now invokes `enable_graph->get_default_value(...)` directly,
  - this removes backend delegation round-trips through `FlattenedDT` for default-value lookup while preserving output/test behavior.
- Latest behavior-preserving increment:
  - backend intermediate-signal classification callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - recursive intermediate-signal detection now invokes `enable_graph->is_intermediate_signal(...)` directly,
  - this removes the backend delegation round-trip through `FlattenedDT` for this classification path while preserving output/test behavior.
- Newest behavior-preserving increment:
  - backend arithmetic-operation classification callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - AST filtering now invokes `enable_graph->is_arithmetic_operation(...)` directly,
  - this removes the backend delegation round-trip through `FlattenedDT` for arithmetic classification while preserving output/test behavior.
- Latest behavior-preserving increment:
  - backend logical-operation classification callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - AST filtering now invokes `enable_graph->is_logical_operation(...)` directly,
  - this removes the backend delegation round-trip through `FlattenedDT` for logical classification while preserving output/test behavior.
- Newest behavior-preserving increment:
  - backend logical-factorization policy callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - AST filtering now invokes `enable_graph->should_factor_logical_operation(...)` directly,
  - this removes the backend delegation round-trip through `FlattenedDT` for logical-factorization policy while preserving output/test behavior.
- Latest behavior-preserving increment:
  - one backend AST signal-name extraction callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - backend AST signal-reference traversal (`ast_contains_signal`) now invokes `enable_graph->extract_signal_name_from_ast(...)` directly,
  - this removes one backend delegation round-trip through `FlattenedDT` for AST signal-name extraction while preserving output/test behavior.
- Newest behavior-preserving increment:
  - one second-pass bare-signal AST name-extraction callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - second-pass AST intermediate-signal gating (`ast_contains_intermediate_signals`) now invokes `enable_graph->extract_signal_name_from_ast(...)` directly,
  - this removes one backend delegation round-trip through `FlattenedDT` for AST signal-name extraction in the second-pass path while preserving output/test behavior.
- Latest behavior-preserving increment:
  - one recursive AST intermediate-signal name-extraction callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - recursive second-pass AST intermediate detection (`ast_has_intermediate_signals_recursive`) now invokes `enable_graph->extract_signal_name_from_ast(...)` directly,
  - this removes one backend delegation round-trip through `FlattenedDT` for AST signal-name extraction in the recursive detection path while preserving output/test behavior.
- Newest behavior-preserving increment:
  - one second-pass AST render callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - second-pass bare-signal debug rendering (`ast_contains_intermediate_signals`) now invokes `enable_graph->ast_to_systemverilog(...)` directly,
  - this removes one backend delegation round-trip through `FlattenedDT` for AST rendering in the second-pass filtering path while preserving output/test behavior.
- Latest behavior-preserving increment:
  - one second-pass DT-enable AST render callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - second-pass DT-enable debug rendering (`feed_current_asts_to_second_pass`) now invokes `enable_graph->ast_to_systemverilog(...)` directly,
  - this removes one backend delegation round-trip through `FlattenedDT` for AST rendering in the second-pass DT-enable path while preserving output/test behavior.
- Newest behavior-preserving increment:
  - one second-pass LHS-enable AST render callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - second-pass LHS-enable debug rendering (`feed_current_asts_to_second_pass`) now invokes `enable_graph->ast_to_systemverilog(...)` directly,
  - this removes one backend delegation round-trip through `FlattenedDT` for AST rendering in the second-pass LHS-enable path while preserving output/test behavior.
- Latest behavior-preserving increment:
  - one second-pass assignment-condition AST render callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - second-pass assignment-condition debug rendering (`feed_current_asts_to_second_pass`) now invokes `enable_graph->ast_to_systemverilog(...)` directly,
  - this removes one backend delegation round-trip through `FlattenedDT` for AST rendering in the second-pass assignment-condition path while preserving output/test behavior.
- Newest behavior-preserving increment:
  - one DT-specific substituted-AST render callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - DT-specific substitution debug rendering (`update_original_asts_with_substituted_versions`) now invokes `enable_graph->ast_to_systemverilog(...)` directly for `original_sv`,
  - this removes one backend delegation round-trip through `FlattenedDT` for AST rendering in the DT-specific substitution path while preserving output/test behavior.
- Latest behavior-preserving increment:
  - one DT-specific substituted-AST updated-render callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - DT-specific substitution debug rendering (`update_original_asts_with_substituted_versions`) now invokes `enable_graph->ast_to_systemverilog(...)` directly for `substituted_sv`,
  - this removes one backend delegation round-trip through `FlattenedDT` for AST rendering in the DT-specific substitution-update path while preserving output/test behavior.
- Newest behavior-preserving increment:
  - one LHS-level substituted-AST original-render callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - LHS-level substitution debug rendering (`update_original_asts_with_substituted_versions`) now invokes `enable_graph->ast_to_systemverilog(...)` directly for `original_sv`,
  - this removes one backend delegation round-trip through `FlattenedDT` for AST rendering in the LHS-level substitution path while preserving output/test behavior.
- Latest behavior-preserving increment:
  - one LHS-level substituted-AST updated-render callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - LHS-level substitution debug rendering (`update_original_asts_with_substituted_versions`) now invokes `enable_graph->ast_to_systemverilog(...)` directly for `substituted_sv`,
  - this removes one backend delegation round-trip through `FlattenedDT` for AST rendering in the LHS-level substitution-update path while preserving output/test behavior.
- Newest behavior-preserving increment:
  - one assignment-condition substituted-AST original-render callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - assignment-condition substitution debug rendering (`update_original_asts_with_substituted_versions`) now invokes `enable_graph->ast_to_systemverilog(...)` directly for `original_sv`,
  - this removes one backend delegation round-trip through `FlattenedDT` for AST rendering in the assignment-condition substitution path while preserving output/test behavior.
- Latest behavior-preserving increment:
  - one assignment-condition substituted-AST updated-render callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - assignment-condition substitution debug rendering (`update_original_asts_with_substituted_versions`) now invokes `enable_graph->ast_to_systemverilog(...)` directly for `substituted_sv`,
  - this removes one backend delegation round-trip through `FlattenedDT` for AST rendering in the assignment-condition substitution-update path while preserving output/test behavior.
- Newest behavior-preserving increment:
  - one second-pass DT-specific original-render callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - second-pass DT-specific substitution debug rendering (`update_original_asts_with_second_pass_substitutions`) now invokes `enable_graph->ast_to_systemverilog(...)` directly for `original_sv`,
  - this removes one backend delegation round-trip through `FlattenedDT` for AST rendering in the second-pass DT-specific substitution path while preserving output/test behavior.
- Latest AST/CoreAST-first convergence increment:
  - repo-wide reference auditing showed that the remaining `FlattenedDT` condition-formatting and DT-specific/LHS-level WEN helpers were fully unreferenced while the live path already flows through `FlattenedDT::Orchestrator::{record_assignment_from_ast,record_transition_from_ast}` and `EnableGraph::generate_complete_enable_structure(...)`,
  - the dormant string-era condition/WEN helper island in `perl/FSM/HDL/FlattenedDT.pm` was removed instead of being ported, including the old parallel assignment recorder, string condition formatter, raw condition-string extractor, and top-level `dt_specific_enables` / `lhs_to_enable_value_pairs` state builders,
  - `t/10-ast-first-enable-structure.t` now locks the invariant that live enable synthesis stores AST-backed DT/LHS enable metadata inside `assignment_analysis->{rhs_groups}` and does not resurrect the old top-level WEN state.
- Design note from this slice:
  - deleting the dormant parallel string implementation is preferable to “modernizing” it because the AST/CoreAST-first path already exists and is covered by live tests; keeping both implementations only increases the chance of divergence and accidental fallback,
  - the next promising seam is another repo-wide audit of residual `FlattenedDT` compatibility helpers to distinguish genuinely live backend/orchestrator delegates from dormant string-era surface area that can be retired outright.
- Latest AST/CoreAST-first convergence increment:
  - a live audit on the known-good development fixtures showed that `FlattenedDT` now completes generation with an empty `intermediate_signals` registry, so the remaining plain-string registry writers were dead compatibility code rather than active backend behavior,
  - the dead string-era global-factorization helper cluster in `perl/FSM/HDL/FlattenedDT.pm` was removed instead of being modernized, because the live path already runs through `Backend::SystemVerilog::run_global_ast_factorization(...)` and `FSM::HDL::ASTFactorization`,
  - `t/09-ast-first-intermediate-registry.t` now locks the invariant that live generation leaves no plain-string or `legacy_string_registry` intermediate entries behind.
- Design note from this slice:
  - this is preferable to converting those dormant helpers to AST metadata because it shrinks the string-era surface area outright and reduces the risk of accidental reintroduction of plain-string registry state,
  - the next promising cleanup seam is the other dead string-era `FlattenedDT.pm` condition / DT-specific WEN helpers that are superseded by the orchestrator + `EnableGraph` AST path.
- Latest AST/CoreAST-first convergence increment:
  - fixture-backed auditing on the known-good development corpus (`trial_0`, `trial_1`, `trial_2`, `mipicsi2_tester_ctrl`) showed that the final `scan_intermediate_signal_names_in_expression(...)` fallback was no longer hit in live generation,
  - `extract_intermediate_signals_from_runtime_ast_miss(...)` now stops after AST-backed recovery sources and records remaining hard misses as `runtime_ast_miss_unresolved`,
  - the backend no longer fabricates dependency edges by mining identifiers from opaque invalid compatibility strings.
- Design note from this slice:
  - this is a better AST/CoreAST-first outcome than leaving the regex fallback in place, because “no recoverable AST/typed dependency source exists” is semantically honest while identifier mining from malformed strings can create false dependency edges,
  - the next seam is upstream: characterize which remaining opaque legacy registry names still lack native defining metadata and either enrich that metadata or retire the compatibility producers entirely.
- Latest AST/CoreAST-first convergence increment:
  - runtime audit in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` confirmed that consolidated intermediate emission (`generate_consolidated_intermediate_signals(...)`) is the live declaration seam and the standalone declaration helper remains compatibility-only,
  - the live backend now resolves intermediate widths through a dedicated width-normalization helper that prefers typed/native metadata (`EnableGraph::get_signal_info(...)`) and defining ASTs before any expression-string compatibility fallback,
  - this keeps the active declaration/filtering path AST/native-metadata-first instead of trusting placeholder `width => 1` values inherited from prescan/factorization staging.
- Design note from this slice:
  - factorizer-substituted AST node classes (`FSM::HDL::IntermediateSignalRef`, `FSM::HDL::SubstitutedUnaryOp`, `FSM::HDL::SubstitutedBinaryOp`) are now handled in the live backend width-resolution path so downstream declarations can stay on AST-derived semantics even after substitution,
  - keeping the width fix inside the consolidated backend path avoids widening dormant compatibility helpers solely for cleanup, which matches the current micro-slice strategy: fix the live AST/CoreAST seam first, then retire or rewrite dormant string-era helpers when they either become live again or are removed entirely.
- Latest AST/CoreAST-first convergence increment:
  - the live consolidated backend now normalizes a runtime AST for each intermediate signal before the dependency, filtering, and assign-emission phases,
  - runtime-AST resolution prefers substituted factorizer ASTs, then defining ASTs, and only parses stored expressions when no AST-backed source exists,
  - this collapses several previously separate expression-string branches into one compatibility helper path and keeps the active runtime algorithm AST-first.
- Design note from this slice:
  - keeping runtime-AST normalization backend-local is the right micro-slice because it changes live execution semantics without forcing premature cleanup of dormant helpers,
  - the next remaining compatibility seam on this lane is no longer “general expression fallback everywhere” but the much narrower cases where runtime-AST resolution misses and the backend still has to fall back to `extract_intermediate_signals_from_expression(...)` or `should_filter_string_based(...)`.
- Latest AST/CoreAST-first convergence increment:
  - consolidated intermediate dependency extraction is now normalized into backend-local cached metadata before the dependency-aware filtering phase,
  - dependency resolution prefers runtime AST traversal and only falls back to expression-based extraction inside one compatibility helper,
  - this removes another inline expression-era branch from the active consolidated path and continues the shift toward typed per-signal metadata.
- Design note from this slice:
  - caching normalized dependency metadata is a good AST-first step because it makes the active path consume one analyzed representation instead of recomputing source selection at each use site,
  - the remaining compatibility seam on this lane is now even narrower: runtime-AST resolution misses that still require fallback dependency extraction or fallback filtering.
- Latest AST/CoreAST-first convergence increment:
  - consolidated rendered-expression metadata is now normalized and cached before the live dependency/filter/emit phases consume it,
  - prescan-backed entries no longer eagerly carry expression text when runtime AST resolution already succeeded,
  - this pushes another piece of live-path state from ad hoc string handling toward explicit cached metadata derived from AST-first normalization.
- Design note from this slice:
  - render-metadata normalization pairs naturally with runtime-AST and dependency normalization because it gives the live consolidated path one stable per-signal view for “what gets emitted” instead of recomputing that answer at each callsite,
  - the remaining compatibility-only seams are now the misses themselves, not the regular live-path consumers.
- Latest AST/CoreAST-first convergence increment:
  - consolidated runtime-AST miss state is now normalized and cached per signal,
  - later live-path helpers reuse that cached `resolved`/`missing` state instead of repeating the same AST recovery attempt,
  - this makes the remaining compatibility-only path explicit metadata rather than repeated implicit fallback behavior.
- Design note from this slice:
  - caching miss state is a useful AST-first refinement because it turns “AST recovery failed somewhere earlier” into stable typed runtime metadata that downstream phases can reason about,
  - the next seam is now the compatibility behavior attached to those explicit misses, not miss detection itself.
- Latest AST/CoreAST-first convergence increment:
  - late expression hydration can now trigger a runtime-AST recovery attempt for signals whose earlier miss reason was only `no_ast_source`,
  - this lets the live consolidated path upgrade some former compatibility-only misses back into AST-backed runtime behavior within the same pass,
  - dependency normalization now benefits directly because it renders first, then sees the recovered runtime AST before choosing fallback extraction.
- Design note from this slice:
  - this is a good AST-first micro-slice because it shrinks the true miss set rather than just reorganizing fallback behavior around a fixed miss population,
  - the remaining compatibility-only seam is now closer to the “hard misses” where expression parsing itself still fails or no semantic AST source exists at all.
- Latest AST/CoreAST-first convergence increment:
  - dependency extraction now treats an explicit runtime-AST miss as its own recovery phase instead of jumping immediately to the old compatibility helper,
  - when the original stored expression is already known to have failed parsing, the live path skips that redundant retry and probes alternate known expressions from `EnableGraph` first,
  - if one of those alternate expressions parses, the recovered AST is cached back onto the signal entry so later filtering/emission can reuse it in the same pass.
- Design note from this slice:
  - this is a stronger AST-first refinement than a pure helper rename because it shrinks the hard-miss population again: some former dependency-fallback cases become runtime-AST-backed signals before filtering runs,
  - the remaining compatibility-only residue on this lane is now more clearly isolated to the final identifier scan and the legacy-named filtering fallback (`should_filter_string_based(...)`).
- Latest AST/CoreAST-first convergence increment:
  - the live consolidated path now normalizes AST-derived live-usage metadata per intermediate signal before filtering,
  - both `should_filter_ast_based(...)` and the explicit runtime-AST-miss path now consume that cached usage metadata instead of each independently re-running the same usage checks,
  - `should_filter_consolidated_signal(...)` now routes explicit misses to `should_filter_runtime_ast_miss(...)`, leaving the old `should_filter_string_based(...)` name as compatibility-only surface area.
- Design note from this slice:
  - this is a good narrowing slice because it preserves current filtering behavior while making the live algorithm consume typed per-signal metadata rather than a legacy helper shape,
  - the next real compatibility residue on this lane is no longer the filter decision itself but the remaining wrapper name plus the final identifier-scan fallback in dependency extraction.
- Latest AST/CoreAST-first convergence increment:
  - the unused legacy-named wrapper entrypoints `should_filter_string_based(...)` and `extract_intermediate_signals_from_expression(...)` have now been removed from both `Backend::SystemVerilog` and the `FlattenedDT` facade,
  - the repo surface now matches the live runtime path more closely: explicit miss filtering goes through `should_filter_runtime_ast_miss(...)` and dependency fallback goes through `extract_intermediate_signals_from_runtime_ast_miss(...)`.
- Design note from this slice:
  - this is a small but worthwhile cleanup slice because it removes dead string-era API surface rather than leaving it available for accidental reintroduction,
  - the next compatibility residue on this lane is now the final identifier-scan fallback itself, not stale wrapper naming.
- Latest AST/CoreAST-first convergence increment:
  - the runtime-AST-miss dependency helper now performs a cleaned-expression AST recovery attempt before the final identifier scan,
  - cleaned-expression parse success is cached onto runtime-AST metadata so later filtering can benefit from the recovered AST in the same pass,
  - when this cleaned compatibility path is used, the backend preserves the previously rendered expression text instead of forcing an immediate output-text change.
- Design note from this slice:
  - this is a good compatibility-narrowing micro-slice because it reduces the remaining identifier-scan population without widening the live path or forcing broad emitter churn,
  - the next residue on this lane is now the identifier scan itself, not the lack of one more AST recovery attempt before it.
- Latest AST/CoreAST-first convergence increment:
  - cleaned-expression compatibility recovery now happens during normal runtime-AST resolution, not only inside the dependency helper,
  - this lets the live consolidated path recover more runtime ASTs before filtering/dependency logic has to choose any fallback behavior,
  - rendering now preserves the original stored expression text whenever the recovered runtime AST came from a cleaned compatibility expression.
- Design note from this slice:
  - this is a stronger AST-first step than a dependency-only retry because it shrinks the remaining miss population for all later live-path consumers, not just dependency extraction,
  - the next residue on this lane is therefore the identifier scan itself, not the absence of earlier cleaned-expression AST recovery.
- Latest AST/CoreAST-first convergence increment:
  - explicit runtime-AST misses in dependency extraction now get one more structured recovery source before the raw identifier scan: `EnableGraph` can build a dependency-recovery AST directly from AST-generated intermediate signal names,
  - that recovery is intentionally narrow and preserves direct intermediate operands as leaf refs, so a signal like `not_mid_and_aux` can recover a dependency on `mid_and_aux` without incorrectly flattening to transitive children.
- Design note from this slice:
  - this is a better fit than adding another string cleanup pass because it uses existing AST-naming metadata as the recovery contract and keeps the fallback logic in typed AST traversal once the name has been recognized,
  - the remaining identifier scan is now reserved for legacy/non-AST-named signals or other hard misses where no AST source, cleaned expression, alternate expression, or AST-name metadata can recover dependencies.
- Latest AST/CoreAST-first convergence increment:
  - the remaining hard-miss audit exposed a deeper semantic issue upstream of the backend fallback logic: some parser/frontend intermediates were storing their defining AST in `attributes->{driving_ast}` instead of the canonical `Signal->{driving_ast}` field,
  - `FSM::CoreAST::Signal` now canonicalizes that legacy write pattern onto the real driving-AST field, and the two active frontend callsites now use `set_driving_ast(...)` directly.
- Design note from this slice:
  - this is a stronger AST/CoreAST-first fix than another fallback tweak because it improves the semantic model itself: backend normalization can now recover more intermediates through the native defining-AST path before any compatibility logic is considered,
  - the next residue should therefore be re-audited after this upstream correction, since some cases that previously looked like “hard misses” may now resolve natively.
- Latest AST/CoreAST-first convergence increment:
  - the post-canonicalization re-audit showed that some remaining hard misses were not truly opaque; they were conservative legacy registry names that still followed the same systematic operator naming shape as AST-generated intermediates,
  - those names now flow through the existing signal-name AST recovery path instead of going directly to regex scanning.
- Design note from this slice:
  - this is preferable to reviving another string-expression helper because the fallback still resolves dependencies through AST construction and AST traversal once a systematic legacy name is recognized,
  - the remaining regex scan is now narrowed further to genuinely opaque legacy names rather than all `legacy_string_registry` entries.
## 2026-03-15: malformed `:=` RHS values now fail through the init/reset boundary
- The active top-level `:=` directive was already supported, but malformed RHS values still leaked raw expression-parser diagnostics instead of surfacing through the directive contract itself.
- The active contract is now explicit on that side too:
  - `(:= tester_reset=[DATAIN])`
  - `(:= tester_reset=<start)`
  now fail as unsupported `:=` reset/default RHS values.

## 2026-03-15: computed test selectors now have an explicit malformed boundary
- The active `?(expr)` success path was already supported and regression-backed, but malformed computed selectors still relied too much on incidental expression/parser fallout.
- The contract is now explicit:
  - `?(expr)` must start with a real selector expression,
  - and it must include at least one branch after that selector expression.
- Examples that are now rejected explicitly:
  - `(? (=0 ...))`
  - `(?(| A B))`
