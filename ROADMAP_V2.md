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
- deepen the shipped `R6` composition model and adjacent reusable module/type contracts without widening them carelessly.

Deliverable themes:
- formalize the `.rtlif` mini-contract,
- decide whether a stronger interface-source contract should later replace or sit above `.rtlif`,
- record and later deliberately reduce the current architectural hotspot set instead of letting those seams stay as unnamed background debt:
  - split composition policy, interface inference, and top-emission planning back out of `FSM::Pipeline::HDLGenerator`,
  - start extracting explicit forward compiler IR layers out of the currently mixed pipeline instead of leaving proto-HIR/proto-lowered semantics implicit:
    - first one bounded `Intent HIR` slice for direct generated roots and realized generated children,
    - then one bounded `Lowered RTL IR` slice once that first forward semantic surface is stable,
    - then one bounded `Structural RTL IR` / connectivity slice once the lowered summary stops being asked to stand in for the full emitted wiring shape,
    - while keeping those forward IR shapes aligned with the future shared-middle/import architecture rather than growing a separate forward-only semantic stack,
  - shrink `FSM::Synthesis::EnableGraph` toward a clearer synthesis ownership boundary instead of one ever-growing semantic gravity well,
  - move planning/normalization residue out of `FSM::HDL::FlattenedDT::Backend::SystemVerilog` so the backend boundary becomes more honestly rendering-oriented,
  - make the bridge between `FSM::CoreAST::*` and `FSM::AST::*` more explicit so future work is not forced to rediscover that seam inside `EnableGraph`,
  - decide whether `FSM::ExpressionNamer` is real remaining surface or compatibility residue that should eventually be retired,
  - remove stale CLI/help compatibility wording from `bin/fsmgen`,
  - and revisit the global-state shape in `FSM::Debug` before `R13` embedding/API work makes that harder to change,
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
- define one bounded portable synthesizable-type lane instead of bolting backend-specific struct/record behavior onto the current scalar-oriented language:
  - add one frontend type core that maps honestly to both SystemVerilog and future VHDL:
    - bits / bit-vectors,
    - enums,
    - records / packed-struct-like aggregates,
    - fixed-size arrays,
    - arrays of records,
    - and named aliases / subtypes,
  - defer backend-specific or semantically sharp-edged features such as unions and user-visible promises of free aggregate-to-vector casting until the portable core is stable,
  - prefer convention over configuration by making type inference the default path for most signals and ports:
    - infer scalar versus aggregate shape from LHS and RHS usage,
    - infer record fields and array shapes from member/index access and compatible assignments,
    - and keep explicit type declarations available mainly as overrides, disambiguation anchors, and interface-stability controls,
  - keep the initial operational contract narrower than the eventual syntax surface:
    - member/field reads and writes,
    - fixed-index and bounded array-element access,
    - exact-type whole-aggregate assignment only after the member-access lane is stable,
    - and explicit conversion helpers later where backend differences require them,
- and harden mixed `?fsmc` / `?rtl` flows before adding broader composition syntax.
- record one future composition-syntax cleanup decision instead of leaving it as untracked taste:
  - decide whether `?toplink` should remain the canonical spelling,
  - or whether a clearer preferred alias such as `?wiring` should be added above it while keeping `?toplink` as compatibility spelling until a deliberate syntax cleanup pass says otherwise.
- record one future bounded syntax-power direction instead of drifting either into verbosity or into a general macro language:
  - highest-leverage candidates currently look like:
    - interface bundles / protocol groups,
    - enum-first `case` / `match` style control capture,
    - small local aliasing/default blocks for repeated guards and output intent,
    - bounded replication for repeated instances/lanes,
    - first-class intent helpers for common RTL patterns such as edge/pulse/sticky/handshake/conflict checks,
    - terse invariant/assertion forms,
    - and stronger explain/report surfaces for inferred behavior,
  - if a future generic/meta-programming lane is opened, it should stay list-oriented, semantic, elaboration-bounded, and 100% RTL/synthesis-focused,
  - such a lane should lower into the same typed AST / diagnostics path as ordinary syntax instead of acting like a parallel text/template preprocessor,
  - and it should explicitly avoid broad source-to-source macros, general-purpose metaprogramming, or anything that reopens the old legacy placeholder/template ambiguity.

First shipped `R11` slice now in tree:
- `?dt:name` is now an active standalone-module root in the live toolchain.
- `?mod:name` and `?module:name` are now also active standalone-DT root aliases in the live toolchain.
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
  - the conventional explicit `(+system ...)` section plus directive sections `(+size ...)`, `(+constants ...)`, `(+enums ...)`, `(+define ...)`, and `(+params ...)`,
  - compact top-level `(:= signal=value)` directives,
  - explicit conventional `+system` yielding `clk` / `rstn` in standalone-DT roots and composition-facing `?dtc` children,
  - implicit `clk` / `rst_n` only when the `?dt:name` source contains sequential assignments and no explicit `+system` is present,
  - default output exposure for driven non-intermediate targets,
  - repeatable `--path DIR` search roots for bare `.fsm` input lookup,
  - the same explicit search roots feeding current `.rtlif` metadata lookup ahead of `FSMLIB`,
  - external `?fsmc` composition child sources resolved from sibling or searched `.fsm` files without leaving the active typed pipeline,
  - named `?fsmc:name` and `?dtc:name` children omitting the explicit source token when the child source should default to `name`,
  - `?dtc` composition child realization from embedded or external standalone-DT sources, including honest non-system interfaces for purely combinational DT children,
  - module-info-level reusable standalone-DT metadata for direct roots, realized `?dtc` children, and top-level composition aggregation of those realized child exports,
  - plus one bounded standalone-DT onehot0-style assertion-metadata/export layer for grouped multi-drive targets through DT-specific driver-enable families,
  - plus the first actual SystemVerilog standalone-DT assertion-emission slice through non-synthesis grouped-target guard assertions in direct `?dt` roots and realized `?dtc` children while keeping Verilog emission clean,
  - module-info-level shared-datapath candidate metadata for same-name output families across multiple realized `?fsmc` children,
  - and the first bounded per-child drive-intent metadata for those candidate families through generated-child `output_drive_families` plus candidate-contributor `drive_intent`,
  - plus one bounded aggregate-enable metadata layer for those candidates through deterministic whole-target and per-value aggregate enable names,
  - plus the first planned conflict-bit metadata layer for those candidates through `P_Q_multi_src_conflict`-style and `P_multi_value_conflict`-style names,
  - plus one bounded onehot0-style assertion-metadata layer for those candidates through deterministic per-child source-enable aliases and whole-target/per-value assertion inputs,
  - plus the first actual shared-datapath helper HDL slice for those candidates through hidden child source-enable export bindings and generated aggregate/conflict wires in the composition top,
  - plus the first actual SystemVerilog shared-datapath assertion-emission slice through non-synthesis same-value and whole-target conflict guards in the generated top while keeping Verilog emission clean,
  - plus one bounded lifted-ownership planning layer for those candidates through storage-class, peer-read endpoint, default-visibility, planned re-export, and loopback-policy metadata,
  - plus one bounded combinational peer-read policy layer for those candidates through explicit public-preserving top-output-only versus internal-only top-local policy and surfaced block-reason metadata,
  - plus the first actual bounded combinational peer-read public-preserving runtime through one emitted shared top-facing combinational carrier, peer-input rebinding, and preserved top-output re-export assignments,
  - plus the sibling bounded combinational peer-read internal-only runtime through one emitted shared top-local combinational carrier, peer-input rebinding, and no invented public top re-export assignments,
  - plus the sibling bounded combinational public-only fanout runtime through that same emitted shared top-facing combinational carrier and preserved public top-output fanout without requiring peer-read child inputs,
  - plus the first actual lifted shared-target behavior for the bounded registered peer-read public-preserving case through one emitted shared top-level register, peer-input rebinding, and preserved top-output re-export assignments, now including mixed public/internal carrier families,
  - plus the sibling bounded registered peer-read internal-only runtime case through that same emitted shared top-level register and peer-input rebinding without invented public re-export assignments,
  - plus the sibling bounded registered public-only fanout runtime through that same emitted shared top-level register and preserved public top-output fanout without requiring peer-read child inputs,
  - bounded single-child `C1` top-interface inference when `?ports` is omitted or empty, with the inferred top interface matching the lone realized child interface exactly,
  - bounded explicit-link `C2` / `C3` omitted/empty-`?ports` inference when explicit `?toplink` endpoints themselves still make the top boundary unambiguous, including renamed top-boundary signals with one consistent direction plus exact width/type agreement,
  - bounded explicit-link `C2` / `C3` undeclared top-input inference when same-name child inputs remain top-facing and agree exactly on direction, width, and type metadata,
  - bounded explicit-link `C2` / `C3` undeclared top-output inference when exactly one same-name child output remains top-facing and is not already consumed by explicit child-to-child wiring,
  - bounded explicit-link `C2` / `C3` plain-explicit-top-port same-name convention when child-side evidence is still exact and safe:
    - plain explicit top inputs may fan out by same name when compatible child inputs agree exactly on direction, width, and type metadata,
    - plain explicit top outputs may adopt one unique same-name top-facing child output when that child-side evidence stays exact,
    - mixed-direction plain-input families fail explicitly,
    - multi-output plain-output families fail explicitly,
    - and explicit top-boundary links still override that convention locally,
  - first bounded composition-plan transparency metadata:
    - top ports carry `origin_kind` so declared versus inferred top-boundary decisions remain visible,
    - links carry `origin_kind` so explicit toplinks, `=name`, same-name convention links, internal-carrier links, and auto system-port links can be distinguished,
    - and the typed composition plan exposes `resolved_links` as the full resolved link set used by planning,
  - first bounded user-facing composition provenance reporting on top of that metadata:
    - composition generation results now carry `composition_report`,
    - the report summarizes top-port and resolved-link provenance by `origin_kind`,
    - the report now also surfaces the first shipped local override events,
    - the report now also surfaces the first shipped blocked convention events,
    - plain explicit top-port same-name convention failures now also say when that convention is blocked instead of only implying it,
    - undeclared top-input/top-output and undeclared internal-carrier inference failures now also say when those convention-first inference paths are blocked,
    - explicit-toplink-driven undeclared top-port inference failures now also say when that inference path is blocked by direction, width, or type disagreement,
    - explicit `?toplink` validation failures now also say when endpoint resolution, direction, duplicate-drive, or width evidence blocks the declared link,
    - explicit-link top-wiring and realized-child-wiring failures now also say when declared top ports or realized child ports remain unwired in explicit-link lanes,
    - explicit-link lane-entry and topology failures now also say when explicit-link lanes are entered without `?toplink`, when top inputs try to drive top outputs directly, or when one source tries to drive multiple top outputs,
    - top-level composition lane/shape gates now also say when lane entry is blocked by missing child instances and when shape is blocked by invalid `?ports` multiplicity or omitted/empty `?ports` outside the bounded inference cases,
    - explicit top-output re-export mismatches for inferred same-name internal carriers now also say when that bounded re-export path is blocked by width or type disagreement,
    - declared `=name` connect-by-name failures now also say when the declared match is blocked by direction, width, ambiguity, or missing-endpoint evidence,
    - and `bin/fsmgen` now prints the same provenance summary for non-quiet composition runs,
  - bounded explicit-link `C2` / `C3` undeclared same-name internal-carrier inference when no explicit link already touches that name family, exactly one same-name child output remains available, and one or more same-name child inputs remain available,
  - bounded local override on top of that convention: an explicit same-name top output may adopt and re-export one of those inferred carriers when direction, width, and type metadata still match exactly,
  - single-generated-child declared connect-by-name through `=name` for both `?fsmc` and `?dtc` children,
  - and declared connect-by-name now covering one or more generated children, one or more external `?rtl` children, or any mixture of those generated and external RTL children when the top-level exact-match rule is still unambiguous,
  - and declared connect-by-name is now direction-asymmetric at the top boundary, with top outputs staying exact-one-match while top inputs may fan out to all matching child inputs of the same name and width,
  - and standalone-DT child interface direction now preferring semantic signal roles over the older name-based output heuristic in composition-facing interface realization.
- The shipped first slice does not yet widen into:
  - regular FSM-state blocks inside `?dt:name`,
  - broader implicit parent-interface inference for undeclared top ports beyond the bounded single-child `C1` passthrough slice and bounded `C2` / `C3` undeclared top-input/top-output/internal-carrier slices,
  - broader reusable-module interface/export rules beyond the now-shipped module-info-level standalone-DT enable-family, grouped multi-drive-family, and composition-facing child-export surfacing slices,
  - or unnamed-root questions.
- The first explicit forward-compiler IR extraction slice is now also shipped:
  - direct generated roots now build one explicit `FSM::IR::IntentHIR` summary before `module_info` is derived,
  - that serialized `intent_hir` summary now flows back in direct generation results,
  - realized generated children (`?fsmc` / `?dtc`) now also preserve that same serialized forward intent summary through their `module_info`,
  - and the shipped slice is intentionally narrow: root identity, system contract, regular-state versus standalone-DT families, stable signal-analysis summaries, and standalone-DT enable families are now explicit.
- The first explicit forward `Lowered RTL IR` extraction slice is now also shipped:
  - new `FSM::IR::LoweredRTLIR` now captures one explicit lowered forward summary for generated output-drive families and standalone-DT grouped multi-drive targets,
  - direct generated roots now expose that serialized `lowered_rtl_ir` summary in generation results,
  - realized generated children (`?fsmc` / `?dtc`) now also preserve that same serialized lowered summary through their `module_info`,
  - and selected downstream composition/export consumers now prefer the extracted `lowered_rtl_ir` surface when present instead of re-reading only ad hoc legacy fields.
- That same first widening step is now also shipped through one top-level composition export surface: aggregated `composition_standalone_dt_children` entries now preserve each realized `?dtc` child's serialized `intent_hir` and `lowered_rtl_ir` summaries instead of stripping those explicit forward layers back off at the top boundary.
- That same reusable standalone-DT export surface now also lives inside composition-top `IntentHIR`, and the compatible top-level `module_info` summary now mirrors it back out from that explicit semantic layer instead of keeping it as a separate ad hoc side channel.
- The next widening step is now also shipped through one broader generated-child composition export surface:
  - top-level `composition_generated_children` now covers realized `?fsmc` and `?dtc` children together instead of only the reusable standalone-DT subset,
  - those exported generated-child entries preserve both serialized `intent_hir` and serialized `lowered_rtl_ir`,
  - and non-quiet `bin/fsmgen` runs now print one concise generated-child summary derived from that broader export instead of requiring plan-internal inspection.
- The next widening step is now also shipped through the shared-datapath candidate surface:
  - shared-datapath candidate contributors now preserve their realized child's serialized `intent_hir` and serialized `lowered_rtl_ir`,
  - those same contributor entries now also preserve the exact selected `output_drive_family` from that child's serialized `lowered_rtl_ir`,
  - and the existing bounded `drive_intent` summary is now derived from that extracted family instead of standing alone,
  - those contributor entries now also preserve stable generated-child identity through `kind` and `source_name`,
  - and non-quiet `bin/fsmgen` runs now print one concise contributor-context line from that forward child IR surface before the existing drive-intent summary.
- The next widening step is now also shipped through composition tops themselves:
  - direct `?top` generation results now expose serialized top-level `intent_hir` and serialized top-level `lowered_rtl_ir`,
  - those composition-top forward layers now carry stable top-port analysis plus composition child-count / lane metadata on the intent side,
  - that same composition-top `intent_hir` surface now also carries the broader generated-child export instead of leaving it only as a separate top-level compatibility summary,
  - those same composition-top forward layers now also carry stable internal-net / instance / auxiliary-assignment summaries plus the bounded shared-datapath candidate surface on the lowered side,
  - and `module_info` now mirrors those same serialized composition-top forward IR layers instead of leaving composition tops as the remaining forward-IR gap.
- The next widening step is now also shipped through the composition provenance/reporting surface:
  - `composition_report` now preserves per-resolved-link endpoint context instead of only raw endpoint strings,
  - those endpoint contexts now carry bounded forward child summaries when a resolved link touches a realized generated child endpoint,
  - and top-port / resolved-link provenance kinds now each preserve one stable example subject so non-quiet CLI summaries are no longer counts-only in that area.
- The next widening step is now also shipped through the composition override/block reporting surface:
  - override and block events now preserve structured top-port / child-endpoint context instead of only flat signal names,
  - those generated-child endpoint contexts now carry bounded forward child summaries from `intent_hir` and `lowered_rtl_ir`,
  - and non-quiet CLI override/block sections now print richer link/endpoint examples instead of count-plus-name examples only.

Expected result:
- composition remains explicit and serious instead of drifting back toward legacy implicit behavior.
- convention should stay the primary integration path, while explicit configuration should act as a precise local override instead of forcing whole-interface restatement.

Planned bounded sub-lane inside `R11`:
- shared datapath extraction for multi-FSM tops.
- intent:
  - keep FSM children as controllers,
  - keep singly-owned outputs in their owning child FSMs,
  - and let only multiply-assigned shared/register-bearing targets move into one common datapath block.
- first contract questions to settle:
  - beyond the now-shipped same-name candidate-discovery metadata, how multiply-assigned lifted targets are declared and detected,
  - which RHS/value sources must also be surfaced to the shared datapath block,
  - how per-child drive intents are named and reported,
  - how same-target/same-value aggregation differs from same-target/different-value conflicts,
  - how conflict/assertion bits are expressed and named for per-`(P, Q)` source-enable families and for whole-target `P` value-family conflicts,
  - the bounded combinational peer-read lane now ships in one public-preserving top-facing form,
  - the bounded registered peer-read lane now ships in public-preserving, mixed-boundary, and internal-only forms,
  - and the remaining question is which broader registered outputs should internalize automatically, when public re-export should stay explicit or defaulted beyond the now-shipped peer-read and public-fanout slices, which lifted registered outputs may legally loop back into child FSM inputs, and how far the combinational lane should widen beyond the now-shipped peer-read public-preserving, internal-only, and public-fanout slices.
- reusable standalone-DT/module-library roots.
- intent:
  - treat `?dt:name` as the smallest reusable standalone module form,
  - allow one `?dt:name` source to contain any number of internal general DT blocks such as `(-foo ...)`,
  - allow that standalone DT module form to mix combinational and sequential outputs freely,
  - keep `?fsm:name` on implicit `clk` / `rst_n` by default,
  - let `?dt:name` acquire implicit `clk` / `rst_n` only when a sequential assignment exists,
  - keep the output-driving semantics inside `?dt:name` aligned with existing DT handling instead of inventing a separate conflict model,
  - keep `?top:name` as the explicit composition root while treating `?dt:name`, `?mod:name`, and `?module:name` as the current standalone-DT root family,
  - and extend reusable-source lookup through existing `FSMLIB` semantics plus repeatable `--path DIR` CLI roots.
- first contract questions to settle:
  - what the exact source-root family becomes beyond the now-shipped `?fsm:name`, `?dt:name`, `?mod:name`, `?module:name`, and `?top:name`,
  - whether unnamed reusable DT roots such as `?dt:` should exist at all or remain deferred,
  - how standalone DT interfaces are declared/exposed,
  - how block-level and module-level enable families are surfaced so same-target arbitration stays explicit without structural over-rejection,
  - how lookup precedence works between explicit paths, `--path` roots, `FSMLIB`, and local files,
  - how duplicate-name shadowing is diagnosed,
  - and how reusable DT/module roots are referenced from other `.fsm` sources without drifting back into legacy implicit behavior.
- portable synthesizable scalar/aggregate types with inference-first declarations.
- intent:
  - add one portable synthesizable type system that works as a frontend contract first and a backend lowering problem second,
  - let most users omit explicit type declarations most of the time by inferring signal and port types from how names are used in assignments and expressions,
  - and keep explicit type declarations mainly as overrides where inference is ambiguous or where the user wants to freeze an interface contract.
- proposed syntax:
```lisp
(+types
  (type bit1 bit)
  (type byte (bits 8))
  (type word (bits 32))
  (type state_t (enum IDLE RUN DONE))
  (type axi_t
    (record
      (valid bit)
      (data (bits 32))
      (keep (bits 4))))
  (type axi_vec_t
    (array 4 axi_t)))
```
```lisp
(+ports
  (in  payload_in byte)
  (out status     state_t)
  (out bus        axi_t))
```
```lisp
(bus.valid = 1)
(bus.data  = payload_in)
(lanes[0].keep = 15)
(pkt <- next_pkt)
```
- phased implementation boundaries:
  1. add a first-class type AST plus explicit type declarations and backend-lowerable named types, without yet promising broad inference or aggregate-wide operations,
  2. add conservative inference for scalar versus aggregate declarations from LHS/RHS/member/index usage, while allowing explicit declarations to override or pin intent,
  3. add member/field and fixed-size array access in DT expressions and assignments,
  4. add exact-type whole-aggregate assignment and typed port/interface exposure rules,
  5. add explicit conversion/helper boundaries for backend differences, especially future VHDL record/vector lowering.
- first contract questions to settle:
  - which syntax is the canonical explicit declaration surface: `(+types ...)` only, or a paired signal/port type-annotation family too,
  - how far inference is allowed to go before the tool must require an explicit type anchor,
  - whether inferred aggregate declarations are recorded back into generated interface/type sections or remain internal planner facts only,
  - how enums interact with the already-shipped `(+enums ...)` lane versus a future unified type section,
  - how record/array literals are deferred or introduced without overcommitting early,
  - and how SystemVerilog packed-type convenience is prevented from leaking into a VHDL-hostile frontend promise.

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

Initial execution guidance:
- start the first serious Rust implementation in this same repository rather than in a separate repository with the current Perl tree as a submodule,
- keep the Perl implementation as the reference/oracle while the Rust implementation grows beside it,
- share one roadmap, one documentation set, one regression corpus, and one differential-test harness across both implementations,
- and only consider splitting into a separate repository later if release cadence, contributor workflow, packaging, or ownership really diverge enough that a monorepo becomes friction rather than leverage.

Rationale:
- a same-repo start keeps the contract, fixtures, snapshots, and expected diagnostics physically close to both implementations,
- it avoids submodule drift and cross-repository version skew while the Rust implementation is still proving semantic parity,
- and it makes it much easier to treat the Perl codebase as a semantic reference instead of trying to maintain two partially decoupled moving targets.

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

### H3. HDL import / intent recovery
Long-term goal:
- add a bounded reverse-direction lane that can recover `.fsm`-style design intent from `SystemVerilog` or `VHDL` inputs.

Intent:
- treat `.fsm` as the canonical design-intent IR,
- and treat HDL-to-`.fsm` as import/recovery rather than as a claim of exact source inversion.

Constraint:
- do not promise full or lossless recovery for arbitrary handwritten HDL,
- even when the input stays within synthesizable RTL.

Primary scope boundary:
- target synthesizable RTL rather than arbitrary simulation/testbench HDL.

Preferred execution order:
- start with `fsmgen`-generated `SystemVerilog` as the first round-trip/import target,
- then support a bounded handwritten synthesizable HDL subset where ports, clocks/resets, FSMs, DT-like logic, datapath structure, and composition hierarchy are recognizable,
- and only later decide how much broader `SystemVerilog` or `VHDL` recovery is worth attempting.

Required behavior:
- recover recognizable structure honestly into `.fsm`,
- surface a report that distinguishes recognized intent, bounded heuristics, and unsupported residue,
- and never pretend certainty where the HDL structure is ambiguous.

Recovery stance:
- do not freeze `.fsm` prematurely if repeated HDL recovery cases reveal a missing first-class semantic construct,
- but keep any such growth semantic, readable, and elegant instead of turning the language into a generic macro or syntax mirror of HDL,
- and prefer explicit residue/annotation reporting over forcing weak evidence into fake high-level elegance.

Expected technical pipeline:
- preprocess `SystemVerilog` / `VHDL` when needed,
- parse the HDL into an AST,
- run frontend semantic compilation work such as name/type/parameter/interface resolution,
- elaborate hierarchy, generate structure, and resolved bindings without requiring a full backend compile/synthesis flow,
- build a typed canonical RTL IR with provenance,
- recover design intent from that IR into `.fsm`,
- and emit a recovery report alongside the recovered source.

Planned IR layering:
- do not describe the reverse-path early layer as a “non-semantic HIR”; the non-semantic layer is the parsed HDL CST/AST, and honest recovery actually needs more semantic structure rather than less,
- the forward `.fsm` to HDL compiler should now be treated as likely converging toward `parsed .fsm AST -> semantic Intent HIR -> Lowered RTL IR -> Structural RTL IR / Connectivity IR -> backend emission`,
- the reverse HDL-import path should converge toward `parsed HDL CST/AST -> semantic HDL HIR -> elaborated RTL IR -> Flat IR -> recovered Intent IR -> .fsm output + recovery report`,
- the important refinement is that the current `Lowered RTL IR` should not be expected to double as the full connectivity graph forever: it can carry normalized lowering summaries and backend-relevant analysis without being the final structural object that the emitter walks,
- the planned `Structural RTL IR` / connectivity layer should eventually be an AST-like netlist structure that carries explicit ports, nets, instances, pin/binding edges, assignments, and backend-facing auxiliary structure so HDL emission becomes primarily a rendering walk instead of a place where connectivity is rediscovered ad hoc,
- `Flat IR` is likely optional in the forward path at first but valuable later for deeper optimization/analysis, while it is much more likely to be necessary in the reverse path because many hardware facts only become obvious after elaboration/flattening,
- and the reverse path therefore needs one extra semantic stage beyond the forward path: a recovered-intent layer that can preserve confidence, ambiguity, and residue instead of pretending that inference is the same thing as authored intent.

Shared-middle rule:
- do not build two completely separate semantic worlds for forward compilation and reverse recovery,
- keep the parse/surface trees separate (`.fsm` AST vs HDL CST/AST),
- keep the early HDL-specific semantic layer separate where the source languages genuinely differ,
- but aim to share the semantic middle:
  - one backend-independent `Intent HIR` that represents `.fsm`-level design intent,
  - one backend-independent `Lowered RTL IR` for normalized registers/drivers/shared-datapath structure and other lowered semantic facts,
  - one backend-independent `Structural RTL IR` / connectivity layer for explicit ports/nets/instances/pin bindings and full top/child wiring once that layer is extracted,
  - and possibly one shared `Flat IR` plus one general provenance model if they prove broad enough,
- while keeping recovery-specific residue/confidence reporting separate from authored-source semantics.

Refactoring implication:
- the current Perl runtime already has proto-HIR/proto-lowered-IR behavior spread across modules such as `HDLGenerator`, `FSMGenFull`, composition planning, and `FlattenedDT`,
- so the future goal is not to invent semantics from nothing but to make those semantic layers explicit, shareable, and backend-independent instead of continuing to rediscover them ad hoc inside generation code.

Advanced synthesizable targets worth considering later, not rejecting upfront:
- macro/preprocessor-heavy RTL after preprocessing with provenance retained,
- generate-heavy RTL after elaboration,
- richer composition hierarchies beyond the first bounded recovery slice,
- hand-optimized logic where some regions may recover as FSM/datapath intent and other regions remain opaque,
- and bounded pragma/attribute recovery where those annotations represent durable design intent rather than backend-specific implementation residue.

Prerequisite:
- the forward `.fsm` contract, diagnostics contract, and embedding/result surfaces should already be stable enough that HDL import targets a known IR instead of a moving language boundary.

## Current intent
The active immediate lane is `R11`.

The first honest `R11` slices are now:
1. keep widening convention-first composition only where the child-side evidence is still deterministic,
2. let explicit local overrides stay precise without forcing whole-interface restatement,
3. keep pushing shared-datapath and reusable-module feature slices before returning to contract-hardening-only work,
4. keep `R8` paused except when a feature slice necessarily touches a still-unlocked boundary.
