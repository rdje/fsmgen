# Composition Scope

This document defines the concrete `R6` scope for composition-oriented work in the active `bin/fsmgen` architecture.

## Status
- The active toolchain now ships the first `C1` composition lane:
  - one `?top:name`,
  - one child instance, currently `?fsmc`, `?dtc`, or `?rtl`,
  - generated children realized either from the same file or from a searchable external `.fsm` source,
  - external RTL children realized from the shipped `.rtlif` interface contract,
  - either one explicit `?ports` block or an omitted/empty `?ports` shape that triggers bounded single-child top-interface inference,
  - deterministic passthrough top wiring,
  - generated child HDL plus generated top HDL through `bin/fsmgen`.
- The active toolchain now also ships the first `C2` composition lane:
  - two or more generated children (`?fsmc` / `?dtc`),
- explicit `?toplink` wiring using top-port names, source-side top-port bit/slice expressions such as `data_bus[3]` or `data_bus[7:4]`, source-side child-output bit/slice expressions such as `producer.payload[3]` or `producer.payload[7:4]`, bounded source-side concat expressions such as `/header_bus,status_bus[0],=1,payload_bus[3:0]/child.port/` or `/header_bus,{status_bus[0],=0b1_0},{payload_bus[3:2],payload_bus[1:0]}/child.port/`, bounded source-side repeat groups such as `/{3{status_bus[0]}}/child.port/` or `/{2{producer.serial_lo}}/top_out/`, `instance.port` child endpoints, and the first bounded source-actual forms (`=open`, scalar `=0` / `=1`, unsized binary/decimal/signed-decimal/octal/hex direct forms such as `=0b10`, `=0d10`, `=-1`, `=0d-1`, `=0o7`, `=0xA`, `=170`, or `=A5`, underscore-separated spellings such as `=0b1010_0101`, `=1_70`, `=0o2_45`, and `=8'hA_5`, and exact-width `=N'b...` / `=N'sb...` / `=N'd...` / `=N'sd...` / `=N'o...` / `=N'so...` / `=N'h...` / `=N'sh...`), with `=open` still targeting realized child input ports only while direct scalar `=0` / `=1` and unsized binary/decimal/octal/hex direct actuals widen to the realized child-input or declared top-output target width, unsized signed decimal direct actuals widen when the numeric value fits the signed range of that direct target width, and exact-width literal actuals may now target realized child input ports or declared top outputs,
  - one resolved child output source may now also fan out to multiple top outputs through one deterministic shared carrier plus explicit top-output assignments,
  - one declared top input may now also drive one or more top outputs directly through explicit top-output assignments while sibling child-input consumers reuse that same top input without synthetic helper nets,
  - either one explicit `?ports` block or an omitted/empty `?ports` shape when the explicit `?toplink` endpoints can still supply one consistent top-boundary contract,
  - deterministic instance ordering,
  - deterministic internal-net creation for child-to-child wiring,
  - bounded undeclared top-interface inference for same-name child inputs and unique child outputs that remain top-facing,
  - bounded convention-first reuse of plain explicit top ports when same-name child-side evidence is still exact and safe,
  - bounded undeclared same-name internal-carrier inference for unique producer-to-consumer child families that remain otherwise unwired,
  - duplicate-driver rejection before emission.
- The active toolchain now also ships the first `C3` composition lane:
  - at least one external `?rtl` child,
  - plus any number of generated children (`?fsmc` / `?dtc`) beside those external RTL children,
- explicit `?toplink` wiring using top-port names, source-side top-port bit/slice expressions such as `data_bus[3]` or `data_bus[7:4]`, source-side child-output bit/slice expressions such as `producer.payload[3]` or `producer.payload[7:4]`, bounded source-side concat expressions such as `/header_bus,status_bus[0],=1,payload_bus[3:0]/child.port/` or `/header_bus,{status_bus[0],=0b1_0},{payload_bus[3:2],payload_bus[1:0]}/child.port/`, bounded source-side repeat groups such as `/{3{status_bus[0]}}/child.port/` or `/{2{producer.serial_lo}}/top_out/`, `instance.port` child endpoints, and the first bounded source-actual forms (`=open`, scalar `=0` / `=1`, unsized binary/decimal/signed-decimal/octal/hex direct forms such as `=0b10`, `=0d10`, `=-1`, `=0d-1`, `=0o7`, `=0xA`, `=170`, or `=A5`, underscore-separated spellings such as `=0b1010_0101`, `=1_70`, `=0o2_45`, and `=8'hA_5`, and exact-width `=N'b...` / `=N'sb...` / `=N'd...` / `=N'sd...` / `=N'o...` / `=N'so...` / `=N'h...` / `=N'sh...`), with `=open` still targeting realized child input ports only while direct scalar `=0` / `=1` and unsized binary/decimal/octal/hex direct actuals widen to the realized child-input or declared top-output target width, unsized signed decimal direct actuals widen when the numeric value fits the signed range of that direct target width, and exact-width literal actuals may now target realized child input ports or declared top outputs,
  - one resolved child output source may now also fan out to multiple top outputs through one deterministic shared carrier plus explicit top-output assignments,
  - one declared top input may now also drive one or more top outputs directly through explicit top-output assignments while sibling child-input consumers reuse that same top input without synthetic helper nets,
  - either one explicit `?ports` block or an omitted/empty `?ports` shape when the explicit `?toplink` endpoints can still supply one consistent top-boundary contract,
  - external RTL interface metadata loaded from embedded or sidecar `.rtlif` artifacts,
  - bounded undeclared top-interface inference for same-name child inputs and unique child outputs that remain top-facing,
  - bounded convention-first reuse of plain explicit top ports when same-name child-side evidence is still exact and safe,
  - bounded undeclared same-name internal-carrier inference for unique producer-to-consumer child families that remain otherwise unwired,
  - deterministic internal-net creation and mixed-child instantiation without regenerating external RTL internals.
- The active toolchain now also ships the first `C4` composition lane:
  - top ports can be declared as `=name` inside `?ports` to request explicit same-name connect-by-name,
  - declared connect-by-name now covers one or more generated children, one or more external `?rtl` children, or any mixture of those generated and external RTL children,
  - declared connect-by-name can also coexist with explicit `?toplink` child-to-child wiring in those same bounded lanes,
  - declared top outputs still require exactly one matching child output,
  - declared top inputs may now fan out to all matching child inputs with the same name and width,
  - the planner still stays deterministic: exact-one-match for top outputs, fanout across fully compatible child inputs for top inputs,
  - ambiguous or missing matches fail explicitly instead of falling back to hidden inference.
- The active toolchain now also ships the first `C6` boundary:
  - out-of-scope legacy composition constructs fail explicitly and point to the scoped composition docs instead of falling through to generic parser behavior.
- `?top:name` inputs are now classified explicitly at the active pipeline boundary, parsed into typed composition IR, and then routed either into the shipped `C1`/`C2`/`C3`/`C4` runtime lanes or a deliberate scope-boundary diagnostic.
- This document remains the normative scope and acceptance boundary for the broader `R6` composition plan.

## Current active boundary
- `bin/fsmgen` currently compiles a single FSM or standalone-DT source into HDL.
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) parses a source file with `Lispish::multi(...)`, classifies the top-level source kind, and routes `?top:name` inputs through a typed composition parser plus the shipped `C1`/`C2`/`C3`/`C4` realization lanes or an explicit scope-boundary diagnostic.
- [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) currently accepts active single-module roots shaped like `?fsm:name`, `?dt:name`, `?mod:name`, `?module:name`, or `+fsm`.

## Current shipped runtime subset
The currently shipped composition behavior is intentionally bounded:
- exactly one top-level `?top:name`,
- zero or one `?ports` block,
- one or more child instances, currently `?fsmc`, `?dtc`, and `?rtl`,
- every generated child must reference exactly one active child source, either embedded in the same file or resolved from an external `.fsm` file,
- `C1` single-child passthrough works without `?toplink` for one `?fsmc`, `?dtc`, or `?rtl` child,
- `C1` may infer the whole top interface directly from that lone child when `?ports` is omitted or empty,
- `C2` multi-generated-child composition uses explicit `?toplink`,
- `C2` and `C3` may now also omit `?ports` or use an empty `(?ports)` block when the top-boundary endpoints referenced in `?toplink` still imply one consistent top-boundary contract,
- `C2` and `C3` may now also infer undeclared top inputs when one or more child inputs share the same name, width, and type metadata and those inputs are not already targeted by explicit child-to-child links,
- `C2` and `C3` may now also infer undeclared top outputs when exactly one same-name child output remains top-facing and is not already consumed by explicit child-to-child links,
- `C2` and `C3` may now also let plain explicit top inputs fan out by same name when compatible child inputs still agree exactly on direction, width, and type metadata,
- `C2` and `C3` may now also let plain explicit top outputs bind one unique same-name top-facing child output when that child-side evidence is still exact,
- `C2` and `C3` may now also infer undeclared same-name internal carriers when no explicit link already touches that name family, exactly one same-name child output remains available, and one or more same-name child inputs remain available,
- those inferred same-name internal carriers stay internal by default, but an explicit same-name top output may adopt and re-export that carrier when its direction, width, and type metadata match the child-side family exactly,
- `C3` explicit-link composition currently supports any explicit-link top with at least one external `?rtl` child, including pure multi-`?rtl`, one-generated-plus-`?rtl`, and multi-generated-plus-`?rtl` mixtures,
- `C4` declared connect-by-name currently supports top ports marked as `=name` inside `?ports` for one or more generated children, one or more external `?rtl` children, or any mixture of those generated and external RTL children,
- each `=name` top output must resolve to exactly one same-named child output with the same width,
- each `=name` top input may resolve to one or more same-named child inputs with the same width,
- mixed-direction or width-mismatched same-name candidates still fail explicitly,
- each `?rtl` child currently loads its interface from an embedded `(?rtlif:module_name ...)` companion root in the same composition source when present, otherwise from a sidecar `<module>.rtlif` metadata file searched first beside the composition source, then through explicit search roots such as repeated `--path DIR`, and then through the existing `FSMLIB` roots,
- the shipped `.rtlif` mini-contract is one flat `(?rtlif:module_name ...)` root with declaration-ordered port tokens such as `clk`, `data_in<8`, `txd>`, `core_clk:clock`, and `rst_async_n:reset`,
- explicit `.rtlif` type annotations are currently limited to `data`, `clock`, and `reset`,
- typed `.rtlif` `clock` / `reset` tokens let custom-named RTL system ports auto-wire through composition without reviving broader hidden inference,
- the current `C3` slice uses the RTL module name as the instance name,
- top ports must match the realized child interface exactly by name, width, and direction in `C1`,
- when `C1` infers ports, that inferred top interface is exactly the realized child interface by name, width, and direction,
- when `C2` / `C3` omit `?ports`, undeclared top endpoints may be inferred directly from explicit `?toplink` evidence, including renamed top-boundary names and source-side top-port bit/slice expressions, but each such endpoint must still keep one direction plus one compatible width/type contract,
- when `C2` / `C3` infer undeclared top inputs, only input-only same-name groups with exact width/type agreement are eligible,
- when `C2` / `C3` infer undeclared top outputs, only exactly one same-name child output may remain top-facing,
- when `C2` / `C3` let plain explicit top inputs/outputs adopt same-name convention, that inference stays bounded to exact same-name direction/width/type agreement and still gives way locally when explicit top-boundary links already speak for that port,
- when `C2` / `C3` infer undeclared same-name internal carriers, only exactly one same-name child output plus one or more same-name child inputs may remain available and no explicit link may already touch that name family,
- child inputs already consumed by explicit child-to-child links are not inferred back out as top inputs,
- child outputs already consumed by explicit child-to-child links are not inferred back out as top outputs,
- inferred same-name internal carriers stay internal by default instead of being re-exported as top ports automatically,
- an explicit same-name top output may re-export one of those inferred carriers without forcing manual child-to-child restatement,
- explicit `?toplink` endpoints must match by role and exact width in `C2`, `C3`, and `C4`,
- explicit-link tops may now also fan out one realized child output source to multiple top outputs through one deterministic shared carrier net plus explicit top-output assignments,
- explicit-link tops may now also route one declared top input directly to one or more top outputs through explicit top-output assignments while sibling child-input consumers reuse that same top input without synthetic helper nets,
- explicit `?toplink` top-port and child-output expressions may currently appear only on the source side and may target realized child input ports or declared top outputs,
- when omitted/empty `?ports` leaves the base top input undeclared, those source-side top-port expressions may now also infer that missing top input from the highest referenced bit as long as the linked child-input evidence still agrees on one compatible direction/type/width contract, including `name[index]` / `name[msb:lsb]` operands that appear inside the bounded concat source form,
- source-side top-port expression forms are currently limited to `name[index]`, `name[msb:lsb]`, bounded comma-separated concat source forms, and bounded repeat groups such as `{3{status_bus[0]}}` or `{2{producer.serial_lo}}`,
- those bounded concat and repeat forms may now nest brace-group sub-concats such as `header_bus,{status_bus[0],=0b1_0},{payload_bus[3:2],payload_bus[1:0]}` and may use declared whole top-port references, top-port bit/slice expressions, child-output operands such as `producer.payload`, `producer.payload[7:4]`, or `producer.payload[0]`, one-bit scalar actuals `=0` / `=1`, intrinsic-width unsized binary/decimal/octal/hex actuals such as `=0b10`, `=170`, `=0d170`, `=0o7`, `=0xA5`, or `=A5`, exact-width binary/decimal/signed-decimal/octal/hex literal actuals in unsigned or signed form, and nested repeat groups,
- source-side child-output projected expression forms are currently limited to `instance.port[index]` and `instance.port[msb:lsb]`, and those projected child-output sources now share the same typed child-input/top-output binding path through one deterministic base carrier for the underlying child output,
- repeat groups now lower through typed structural `repeat` connection expressions rather than raw renderer text, and child-output repeat groups reuse that same deterministic base carrier family instead of inventing repeat-only helper nets,
- those intrinsic-width unsized binary/octal/hex concat actuals keep the width implied by their digits, and unsized decimal forms such as `=170` or `=0d170` now also keep the minimum width required by their numeric value rather than widening from the child-input target,
- when omitted/empty `?ports` infers undeclared top inputs from one such concat source, those child-output operands contribute fixed child-side width and usage context but do not themselves become inferred top-boundary ports,
- when one such concat source leaves exactly one undeclared whole-port operand unsized, omitted/empty `?ports` may now infer that operand's exact width from the remaining realized child-input target width after the other concat operands are already exact,
- when one such repeat or concat source leaves exactly one undeclared repeated whole-port operand unsized, omitted/empty `?ports` may now also infer that operand's exact per-copy width when the remaining realized child-input target width divides evenly across the repeat count,
- but several still-unsized undeclared whole-port concat operands continue to fail explicitly instead of guessing several widths from one child-input target,
- and uneven repeat-width splits now also fail explicitly instead of guessing one per-copy width silently,
- explicit `?toplink` actual sources may currently appear only on the source side,
- `=open` is the one width-agnostic explicit actual source in that first slice and still targets only realized child input ports,
- direct scalar actuals `=0` and `=1` plus unsized binary/decimal/octal/hex direct actuals such as `=0b10100101`, `=0d170`, `=0o245`, `=0xA5`, `=170`, and `=A5` may now target realized child input ports or declared top outputs by widening to the direct binding target width as numeric values, unsized signed decimal direct actuals such as `=-1` and `=0d-1` may now also target those same direct bindings when the numeric value fits the signed range of the target width, while exact-width binary/decimal/signed-decimal/octal/hex literal forms in unsigned or signed form such as `=8'b10100101`, `=8'sb10100101`, `=8'd165`, `=8'sd-1`, `=8'o245`, `=8'so245`, `=8'hA5`, or `=8'shA5` must still match the target width exactly,
- underscore-separated digit spellings such as `=0b1010_0101`, `=1_70`, `=0o2_45`, `=A_5`, `=8'd1_65`, and `=8'hA_5` are accepted on those same direct literal families,
- underscore-separated digit spellings are also accepted on the intrinsic-width unsized binary/decimal/octal/hex concat family, for example `=0b1_0`, `=0d1_70`, `=1_70`, `=0xA_5`, or `=A_5`,
- the source frontend now preserves brace-grouped slash-token text before composition parsing, so those nested concat groups survive from `.fsm` source through raw AST, composition parsing, and final emitted HDL instead of being flattened away at read time,
- explicit and declared connect-by-name mismatches now fail before emission and identify the conflicting endpoints and widths,
- the typed composition plan now also exposes first-pass provenance metadata for downstream tooling and diagnostics:
  - `FSM::Composition::Port->origin_kind` distinguishes declared and inferred top-port paths,
  - `FSM::Composition::Link->origin_kind` distinguishes explicit toplinks, declared `=name`, same-name convention links, internal-carrier links, and auto system-port links,
  - and `FSM::Composition::Plan->resolved_links` now surfaces the full resolved link set used by planning instead of only the original declared `links` input,
- composition generation results now also expose a user-facing provenance summary:
  - `FSM::Pipeline::HDLGenerator->generate_hdl_from_file(...)` returns `composition_report` for composition sources,
  - that report summarizes top-port and resolved-link provenance by `origin_kind`,
  - it also summarizes the first shipped local override events, such as explicit top links overriding same-name convention and explicit top outputs re-exporting inferred internal carriers, and now keeps one concise example subject per override kind,
  - and it now summarizes the first shipped “blocked” convention cases too, such as explicit child links blocking undeclared top-interface inference and inferred internal carriers staying internal by default, and now keeps one concise example subject per block kind,
  - and the first bounded failure-path wording slice is now shipped too, so plain explicit top-port same-name convention failures now say when that convention is blocked rather than only implying it,
  - and that failure-path blocked-wording lane now also covers undeclared top-input/top-output and undeclared internal-carrier inference failures,
  - and it now also covers explicit top-output re-export mismatches when a declared top output does not match the inferred same-name internal-carrier family exactly,
  - and it now also covers explicit-toplink-driven undeclared top-port inference failures when direction, width, or type evidence disagrees,
  - and it now also covers explicit `?toplink` validation failures when endpoint resolution, direction, duplicate-drive, or width evidence blocks the declared link,
  - and it now also covers explicit-link top-wiring and realized-child-wiring failures when declared top ports or realized child ports remain unwired in explicit-link lanes,
  - and it now also covers explicit-link lane-entry and remaining topology failures when explicit-link lanes are entered without `?toplink` or when a still-unsupported explicit-link topology is requested,
  - and it now also covers top-level composition lane/shape gates when no child instances exist, when `?ports` multiplicity is invalid, or when omitted/empty `?ports` appears outside the bounded inference cases,
  - and it now also covers declared `=name` connect-by-name failures when direction, width, ambiguity, or missing-endpoint evidence blocks the declared match,
  - and it now also covers `C1` passthrough exposure failures when explicit top exposure omits a realized child port or disagrees with the realized child interface on name, width, or direction,
  - and it now also covers duplicate top-port and duplicate child-instance declarations when those composition-shape conflicts would otherwise make planning ambiguous,
  - and it now also covers reserved system-port `=name` declarations and unsupported explicit endpoint syntax when those endpoint-shape errors would otherwise leave the binding contract ambiguous,
  - and it now also covers malformed `?ports` and `?toplink` parser items when top-port or top-link token flatness/shape/sizing/declaration-mode would otherwise fail through older raw wording,
  - and it now also covers unsupported composition backend targets when a valid composition source asks for a backend that the current composition lanes do not emit,
  - and it now also covers generated child-source resolution/realization failures when external `?fsmc` / `?dtc` child sources are missing or resolve to the wrong active root kind,
  - and it now also covers blocked `C2` lane selection when an explicit-link generated-child composition still provides only one generated child,
  - and it now also covers blocked external RTL metadata resolution when a mixed or RTL-only composition references a `?rtl` child without any reachable `.rtlif` metadata,
  - and it now also covers blocked external RTL metadata structure when a reachable `.rtlif` file does not contain the required `?rtlif:<module>` root,
  - and it now also covers blocked external RTL metadata port typing when a reachable `.rtlif` token resolves to an unsupported explicit type,
  - and it now also covers blocked external RTL metadata token shape when a reachable `.rtlif` token is syntactically invalid for the active flat port-token contract,
  - and it now also covers blocked external RTL metadata port sizing when a reachable `.rtlif` token declares a non-positive explicit width,
  - and it now also covers blocked external RTL metadata port declaration uniqueness when a reachable `.rtlif` file repeats the same port name,
  - and it now also covers blocked external RTL metadata port presence when a reachable `.rtlif` file declares no ports under the required root,
  - and it now also covers blocked external RTL metadata flatness when a reachable `.rtlif` file contains nested structure under the required root,
  - and it now also covers blocked embedded RTL metadata root uniqueness when the same composition source contains multiple embedded `?rtlif:<module>` roots for one external RTL child,
  - and it now also covers malformed child-entry structure when empty child entries, non-string child headers, or dotted-pair child payloads would otherwise fail through older raw wording or warnings,
  - and it now also covers unsupported child kinds when a composition child header falls outside the active `?fsmc` / `?dtc` / `?rtl` / `?ports` / `?toplink` family,
  - and it now also covers malformed generated-child source payloads when `?fsmc` / `?dtc` payloads use nested option structures or the wrong number of flat source names,
  - and `bin/fsmgen` now prints the same provenance summary during non-quiet composition runs,
- and non-quiet failed composition runs now also print a first bounded composition-failure summary when a blocked composition boundary can be extracted from the raised diagnostic, including a `Lane:` line when the blocked diagnostic already names the active `C1` / `C2` / `C3` / `C4` lane, a `Construct:` line when the blocked diagnostic already points clearly at one active syntax construct such as `?ports`, `?toplink`, `?rtl`, `?fsmc`, `?dtc`, or `=port`, a `Child source file:` line when a blocked `?fsmc` / `?dtc` realization failure already names the resolved external `.fsm` file, an `Expected child source file:` line when a blocked `?fsmc` / `?dtc` resolution failure names the missing external source target, an `Expected RTL metadata file:` line when a blocked `?rtl` resolution failure names the missing sidecar target, an `RTL metadata file:` line when a blocked `.rtlif` structure, token, sizing, typing, flatness, or declaration failure already names the resolved metadata file, a `Search roots:` line when blocked lookup diagnostics already expose the active search roots, a concise context line for the offending child/top-port/top-expression/child-expression/explicit-endpoint/actual-source/actual-endpoint/token/repeated-RTL-port/RTL-root when that context can be separated honestly from the longer failure text, plus a concise blocked-reason line,
- realized child interface currently means:
  - effective system inputs from the active FSM generator contract:
    - explicit conventional `+system` currently yields `clk` / `rstn`,
    - absent `+system` currently yields implicit `clk` / `rst_n`,
    - standalone-DT children may now expose explicit `clk` / `rstn` through the same conventional `+system` contract,
    - and purely combinational standalone-DT children still do not acquire fake system ports just because they are instantiated in composition when that explicit contract is absent,
  - plus explicit user-facing child ports as exposed by the active generation pipeline for `?fsmc` and `?dtc`,
  - plus explicit ports declared in the loaded `<module>.rtlif` metadata for `?rtl`,
- explicit-link endpoint syntax is currently:
  - top-port name, for example `result_data`,
  - or source-side top-port bit/slice expression over a declared top input, for example `payload_bus[15:8]` or `status_bus[0]`, when that explicit link targets a realized child input port or a declared top output,
  - or child endpoint `instance.port`, for example `producer.output_data`,
- or source actual `=open`, scalar `=0` / `=1`, unsized binary/decimal/signed-decimal/octal/hex direct actual such as `=0b10100101`, `=0d170`, `=-1`, `=0d-1`, `=0o245`, `=0xA5`, `=170`, or `=A5`, or exact-width binary/decimal/signed-decimal/octal/hex literal `=N'b...` / `=N'sb...` / `=N'd...` / `=N'sd...` / `=N'o...` / `=N'so...` / `=N'h...` / `=N'sh...`, for example `=8'b10100101`, `=8'sb10100101`, `=8'd165`, `=8'sd-1`, `=8'o245`, `=8'so245`, `=8'hA5`, or `=8'shA5`, where `=open` currently targets only a realized child input port, direct scalar `=0` / `=1` plus unsized binary/decimal/octal/hex direct actuals widen to the realized child-input or declared top-output target width as numeric values, unsized signed decimal direct actuals widen when the numeric value fits the signed range of that direct target width, and exact-width literal actuals may target a realized child input port or a declared top output,
- underscore-separated digit spellings are accepted on those same literal forms too, for example `=1_70`, `=0o2_45`, `=8'd1_65`, or `=8'hA_5`,
- composition output is currently limited to SystemVerilog / Verilog targets.

## Goal of `R6`
Add a composition layer to the active architecture so `fsmgen` can build a top module from multiple child blocks without reviving the legacy eval/plugin model.

The first composition lane is intentionally narrow:
- preserve the current single-FSM compile path unchanged,
- add one explicit composition source path,
- keep composition typed and deterministic,
- reuse the existing child-FSM compile pipeline where possible.

## In-scope model for the first composition lane
### 1. Source kind
The active tool currently supports three top-level source families:
- FSM source: existing `?fsm:name` / `+fsm` path.
- Standalone-DT source: `?dt:name`, `?mod:name`, or `?module:name` for reusable DT-root modules.
- Composition source: one top-level `?top:name` form routed to a dedicated composition parser.

### 2. Child block kinds
The language surface for the first composition lane recognizes exactly three child block kinds:
- `?fsmc`
  - Child instance compiled from an FSM source through the active FSM pipeline.
- `?dtc`
  - Child instance compiled from a standalone-DT source through the active generation pipeline.
- `?rtl`
  - Child instance bound to an external RTL module with an explicitly declared interface.

Current shipped runtime subset:
- `?fsmc` and `?dtc` are realized in the shipped `C1`, `C2`, and `C3` slices,
- named `?fsmc:name` and `?dtc:name` children may now omit the explicit source token and default it to `name`,
- realized `?dtc` children now preserve standalone-DT block-enable family metadata in their `module_info` result surface,
- realized `?dtc` children now also preserve grouped standalone-DT multi-drive target metadata in that same `module_info` surface,
- parent composition tops now also aggregate those realized `?dtc` child exports through `composition_standalone_dt_child_count`, `composition_standalone_dt_block_count`, `composition_standalone_dt_multi_drive_target_count`, and `composition_standalone_dt_children` in top-level `module_info`,
- and that same top-level `composition_standalone_dt_children` surface now also preserves each realized child's forward `intent_hir` and `lowered_rtl_ir` summaries,
- and that same reusable standalone-DT child export now also lives inside composition-top `intent_hir`, with top-level `module_info` mirroring it back out from that explicit semantic layer instead of keeping a separate ad hoc export path,
- and that same narrower reusable standalone-DT child export path now also derives from the broader semantic `composition_children` layer instead of rebuilding `?dtc` child identity separately from plan instances, with standalone-DT names and enable families coming from child `intent_hir` and grouped multi-drive targets coming from child `lowered_rtl_ir`,
- and parent composition tops now also surface one broader generated-child export through `composition_generated_child_count`, `composition_generated_fsm_child_count`, `composition_generated_dt_child_count`, and `composition_generated_children`,
- and that broader generated-child surface now preserves each realized `?fsmc` / `?dtc` child's forward `intent_hir` and `lowered_rtl_ir` summaries together with stable kind/root/count metadata,
- and that same broader generated-child export now also lives inside composition-top `intent_hir`, with top-level `module_info` mirroring it back out from that explicit semantic layer instead of keeping a separate ad hoc export path,
- and that same narrower generated-child export path now also derives from the broader semantic `composition_children` layer instead of rebuilding generated-child identity separately from plan instances,
- and composition tops themselves now also surface direct-result top-level `intent_hir` and `lowered_rtl_ir`, with `module_info` mirroring the same bounded top-port, child-count, lane, internal-net, instance, auxiliary-assignment, and shared-datapath-candidate summaries,
- and composition tops now also surface one first bounded `structural_rtl_ir` connectivity layer over explicit top ports, internal nets, realized instances, pin bindings, and auxiliary assignments, with top-module emission now walking that structural layer instead of re-reading the plan directly,
- and realized generated-child export surfaces now preserve each child module's bounded `structural_rtl_ir` boundary summary beside `intent_hir` and `lowered_rtl_ir`, so composition-level consumers can reuse one explicit structural layer instead of treating structure as top-only,
- and the unified semantic `composition_children` export now derives child identity and order from `structural_rtl_ir->{instances}` instead of rereading realized child identity directly from plan instances, with the narrower generated-child and reusable standalone-DT export builders reusing that same computed child surface in the top-generation path,
- and realized generated-child interface planning now consumes that child `structural_rtl_ir` boundary summary first, with low-level declaration types like `wire` / `logic` normalized back to plain semantic data ports on the way into composition typing,
- and composition-top `lowered_rtl_ir` now consumes `structural_rtl_ir` for internal-net names, realized-instance names, and auxiliary-assignment counts instead of rebuilding that bounded connectivity slice directly from plan internals,
- and composition-top `module_info` / `statistics` now also consume `structural_rtl_ir` for child, top-port, and internal-net counts instead of rereading those bounded accounting fields directly from plan internals,
- and that same top-level bookkeeping now also consumes the explicit IRs for the remaining mirrored fields: `module_info` now derives internal-net names/counts, instance names/counts, auxiliary-assignment count, and composition lane from `lowered_rtl_ir` / `intent_hir`, and `statistics` now derives composition lane and shared-datapath candidate count from `intent_hir` / `lowered_rtl_ir`,
- and that same `composition_report` surface now also consumes `structural_rtl_ir` for top-port metadata and resolved-link endpoint lookup instead of rereading those bounded boundary/interface details directly from plan internals,
- and that same override/block reporting surface now also consumes `structural_rtl_ir` for top-port and child-interface metadata instead of rereading those same interface families directly from plan internals,
- and that same composition-top `intent_hir` layer now also consumes `structural_rtl_ir` for top-port names, counts, and grouped input/output signal-analysis families, with compatible top-level `module_info` signal metadata mirroring that same structural top-port boundary,
- and that same composition-top `structural_rtl_ir` layer now also preserves explicit resolved links as first-class connectivity entries beside ports, nets, instances, and pin bindings, with provenance/reporting and compatible top-level resolved-link counts now aligned to that same structural layer,
- and that same composition-top `structural_rtl_ir` layer now also preserves declared explicit-toplink connectivity separately through `declared_links`, so the structural layer now carries both declared and resolved top/child wiring intent instead of only the post-resolution side,
- and structural instance pin bindings now also preserve typed `connection_expr` nodes, currently bounded to backend-neutral `signal_ref`, source-side top-port `bit_select` / `slice` forms, source-side child-output `bit_select` / `slice` forms, bounded concat and repeat forms over those source-side operands, and the first shipped explicit-toplink actual-source forms through `open` and bit-vector literals, so the emitter can walk explicit actual-connection nodes instead of only mirrored signal-name strings,
- and realized composition-plan instance bindings now also preserve those same typed nodes before structural serialization, so the structural layer now carries them through instead of synthesizing them only at the export boundary,
- and that earlier binding normalization now lives on the runtime `FSM::Composition::RealizedInstance` carrier itself, so `signal_name` / `connection_expr` alignment is now a direct child-binding contract instead of only an `HDLGenerator` convention,
- and the current bounded `signal_ref` / `bit_select` / `slice` / `concat` / `repeat` / `open` / bit-vector-literal construction, binding signal-name recovery, and backend-neutral text rendering for those structural actual-connection nodes now also live in dedicated `FSM::IR::StructuralRTLIR::ConnectionExpr` helpers instead of remaining split across pipeline glue,
- and explicit-toplink actual sources plus source-side top-port bit/slice, source-side child-output bit/slice, repeat-group, and concat expressions now also land directly on realized child-input bindings or declared top-output assignments through that typed structural layer, so `=open`, `=0`, `=1`, exact-width `=N'b...`, `=N'd...`, `=N'o...`, `=N'h...`, declared-top forms such as `payload_bus[15:8]`, child-output forms such as `producer.payload[7:4]`, repeat groups such as `{2{producer.payload[7:4]}}`, and bounded concat forms such as `header_bus,producer.payload[7:4],=1,payload_bus[3:0]` no longer need fake carrier nets or fake same-name top-input inference just to reach the emitter,
- and that same override/block reporting surface now also takes its resolved connectivity from `structural_rtl_ir->{resolved_links}`, so explicit-toplink override examples, inferred internal-carrier re-export overrides, and kept-internal carrier family detection no longer reread resolved links directly from plan internals,
- and that same block-reporting surface now also takes explicit child-link blocking intent from `structural_rtl_ir->{declared_links}` instead of rereading declared toplinks directly from plan internals,
- and that same composition provenance surface now also preserves per-resolved-link endpoint context plus one example subject per top-port and resolved-link provenance kind, with generated-child endpoint examples carrying bounded forward child context from `intent_hir` / `lowered_rtl_ir`,
- and that same composition override / block reporting surface now also preserves structured top-port / child-endpoint context instead of only flat signal names, with generated-child endpoint examples carrying bounded forward child context from `intent_hir` / `lowered_rtl_ir`,
- and composition tops now also preserve one broader `composition_child_count` / `composition_children` semantic export across all realized child kinds (`?fsmc`, `?dtc`, and `?rtl`) inside top-level `intent_hir`, with compatible top-level `module_info` mirroring that same unified child surface back out for embedding/reporting use,
- and that same unified `composition_children` surface now preserves each child's stable identity (`kind`, `instance_name`, `module_name`, `source_name`, `source_root_kind`) together with the child's forward `intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir` summaries when those layers exist,
- and composition provenance / override / block endpoint context lookup now also consumes that unified `composition_children` semantic surface instead of rereading realized child identity only from plan instances,
- those grouped standalone-DT multi-drive target families now also surface onehot0-style assertion metadata over their DT-specific driver-enable signals, and SystemVerilog direct `?dt` roots plus realized `?dtc` children now emit bounded non-synthesis guard assertions from that metadata while Verilog keeps those assertions disabled,
- parent composition tops with multiple `?fsmc` children now also surface first shared-datapath candidate families through `composition_shared_datapath_candidate_count` and `composition_shared_datapath_candidates` in top-level `module_info`,
- realized generated children now also preserve `output_drive_family_count` and `output_drive_families` in their `module_info` surface,
- realized `?fsmc` children now also preserve hidden shared-datapath source-export metadata for per-value enable families used only inside generated composition tops,
- and those shared-datapath candidate contributors now also preserve the exact selected `output_drive_family` from that child's `lowered_rtl_ir`, with the bounded `drive_intent` summary now derived from that extracted family instead of standing alone,
- and those same shared-datapath contributors now also preserve each realized child's forward `intent_hir` and `lowered_rtl_ir` summaries together with stable generated-child identity fields,
- and that same shared-datapath candidate-discovery path now also consumes `structural_rtl_ir` for top-output / child-interface connectivity plus the unified semantic `composition_children` export for child identity and lowered contributor context, instead of rereading those bounded families directly from plan instances,
- and those shared-datapath candidate families now also expose one deterministic whole-target aggregate enable plus per-value aggregate enable families derived from the child-local `P_Q` families,
- and generated composition tops now also synthesize the first real shared-datapath helper HDL from that metadata: hidden child source-enable export bindings, per-value aggregate enable wires, per-value conflict wires, whole-target aggregate enable wires, and whole-target multi-value conflict wires,
- and those shared-datapath candidate families now also expose deterministic per-child shared-datapath source-enable aliases plus onehot0-style assertion metadata for same-value source overlap and whole-target multi-value overlap,
- and SystemVerilog composition tops now also emit bounded non-synthesis shared-datapath guard assertions from that metadata, while Verilog targets keep assertion emission disabled,
- and those shared-datapath candidate families now also expose the first lifted-ownership planning metadata for registered peer-read families through storage-class, peer-read endpoint, default lifted visibility, planned top re-export, and loopback-policy fields,
- and those shared-datapath candidate families now also expose explicit peer-read policy metadata for bounded combinational peer-read cases, distinguishing public-preserving top-output-only families from internal-only top-local carrier families instead of treating them as loopback-eligible,
- and non-quiet `bin/fsmgen` shared-datapath summaries now also render peer-read binding text from the typed `bound_connection_expr` surface instead of printing only endpoint names,
- and that same non-quiet shared-datapath candidate summary line now also renders contributor binding text from the typed `bound_connection_expr` surface instead of collapsing contributors back to endpoint-only text,
- and the bounded combinational peer-read public-preserving case now also realizes a first top-facing shared-carrier runtime, with one shared combinational carrier emitted in the generated top, preserved public top outputs re-exported from that carrier, peer-read child inputs rebound to it, and contributor outputs rebound to private raw nets,
- and the sibling bounded combinational peer-read internal-only case now also realizes a first top-local shared-carrier runtime, with one shared combinational carrier emitted in the generated top, peer-read child inputs rebound to it, contributor outputs rebound to private raw nets, and no invented public top re-export assignments when no such outputs exist,
- and the sibling bounded combinational public-only fanout case now also realizes that shared-carrier runtime through one shared top-facing combinational carrier plus preserved public top-output fanout assignments even when no peer-read child inputs exist,
- and the bounded registered peer-read public-preserving case now also realizes the first actual lifted shared-target behavior, with one shared top-level register emitted in the generated top, peer-read child inputs rebound to that lifted register, preserved public top outputs re-exported from the lifted register instead of binding directly to one child output, and mixed public/internal carrier families now using that same lifted runtime,
- and the sibling bounded registered peer-read internal-only case now also realizes that same lifted shared-target runtime without inventing public top re-export assignments when no such outputs exist,
- and the sibling bounded registered public-only fanout case now also realizes that lifted shared-target runtime through one shared top-level register plus preserved public top-output fanout assignments even when no peer-read child inputs exist,
- `?rtl` is now realized in the shipped single-child `C1`, explicit-link `C3`, and declared-by-name `C4` slices,
- the current explicit-link `C3` slice expects either one embedded `(?rtlif:module_name ...)` companion root or one `<module>.rtlif` sidecar metadata file per external RTL module and does not parse/regenerate SV/VHDL module internals at composition time.

### 3. Interface model
Composition will use explicit typed interface data, not implicit global hashes.

The first lane must represent:
- top ports,
- child instances,
- child port directions,
- interconnect nets,
- top-to-child bindings,
- child-to-child bindings.

### 4. Wiring model
The first lane supports:
- explicit top-port exposure,
- explicit child-port wiring,
- declared top-port connect-by-name through `=name` declarations in `?ports`,
- deterministic connect-by-name only when the names are unambiguous and declared,
- explicit failure on:
  - unknown ports,
  - duplicate drivers,
  - ambiguous connect-by-name,
  - width mismatch where no legal adaptation exists.

### 5. Output model
The first lane produces:
- one generated top module in the selected HDL target,
- generated child modules for `?fsmc` and `?dtc` children,
- references to external RTL children without attempting to regenerate their internals.

### 6. CLI behavior
`bin/fsmgen` remains the single entrypoint.

The composition path must:
- detect a `?top:name` root before the FSM-only parser runs,
- route to a composition pipeline,
- keep current single-FSM CLI behavior unchanged for existing inputs.

## Explicit non-goals for the first composition lane
The following are out of scope for the first implementation slice:
- legacy eval/plugin phases (`.plg`, `cclausearch`, `declarch`, `beginarch`, `endarch`, etc.),
- macro systems and dynamic code injection,
- implicit architecture rewriting across child boundaries,
- automatic datapath/control repartitioning at composition level,
- mixed-language top generation,
- hierarchical timing semantics beyond explicit port/net wiring,
- broad “do what I mean” auto-wiring beyond the currently shipped bounded convention-first slices.

## Working interpretation of legacy terms
- `?fsmc`
  - Composition-layer child FSM declaration and interface exposure/wiring support.
  - It is not itself an enable-synthesis feature.
- `?rtl`
  - External RTL module binding with declared interface metadata loaded separately for composition-time validation and wiring.
- `?ports`
  - Explicit top-level interface declaration for the generated composition.
- `?toplink`
  - Explicit connectivity specification between top ports, interconnect nets, and child ports.

These names come from the historical composition flow, but the implementation must be typed and modernized rather than copied structurally from the legacy engine.

## Active architecture mapping
The first composition lane should be added above the current FSM-only parser boundary.

### Planned pipeline split
1. Source classification
   - inspect the Lispish root and choose FSM path or composition path.
2. Composition parsing
   - build a typed composition IR from `?top:*`, `?fsmc`, `?dtc`, `?rtl`, `?ports`, and `?toplink`.
3. Child realization
   - compile `?fsmc` children through the existing FSM pipeline whether the child source is embedded or loaded from an external `.fsm` file,
   - load/validate declared interfaces for `?rtl` children from embedded or sidecar `.rtlif` metadata.
4. Top planning
   - resolve ports, nets, instance wiring, and deterministic ordering.
5. Top emission
   - emit the generated top module in the selected HDL target.

### Planned typed IR concepts
The first lane should introduce typed composition objects instead of free-form hashes.
The initial parser/IR slice now covers the root/container side and also includes typed per-port/per-link objects used by the shipped `C1` planning path.

Planned typed objects:
- `CompositionSpec`
- `CompositionTop`
- `CompositionInstance`
- `CompositionPort`
- `CompositionNet`
- `CompositionLink`

Exact package names may change, but the architecture must stay typed at this boundary.

Historical note:
- [docs/COMPOSITION_LEGACY_MAPPING.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_LEGACY_MAPPING.md) captures how the obsolete `fx/bin/fsmgen` composition lane maps onto this modern scope without reviving its plugin/eval machinery.

## Acceptance matrix for the first composition lane
These are the executable scenarios that must exist before `R6` can be closed.

### C1. Single-child passthrough top
Status:
- Implemented in the current active toolchain for one child (`?fsmc`, `?dtc`, or `?rtl`) with either explicit same-name top exposure or bounded omitted/empty-`?ports` top-interface inference.

- Input:
  - one `?top:name` with one child (`?fsmc`, `?dtc`, or `?rtl`) and either explicit top-port exposure or an omitted/empty `?ports` shape.
- Must prove:
  - top generation succeeds,
  - generated child HDL is emitted through the active pipeline when the child is generated,
  - external RTL children are instantiated but not regenerated when the child is `?rtl`,
  - top ports are emitted deterministically,
  - child ports are wired exactly as declared,
  - and omitted/empty `?ports` in `C1` infers a top interface that matches the realized child interface exactly.

### C2. Two generated children with explicit child-to-child wiring
Status:
- Implemented in the current active toolchain for generated children with explicit `?toplink`, plus bounded omitted/empty-`?ports` inference, bounded explicit-toplink top-port inference, bounded undeclared top-interface inference for child-input groups and unique child outputs that are still top-facing, bounded convention-first reuse of plain explicit top ports, and bounded same-name internal-carrier inference for unique producer-to-consumer families that remain otherwise unwired or are explicitly re-exported through a matching top output.

- Input:
  - one `?top:name` with two generated children (`?fsmc` / `?dtc`) and explicit links between them.
- Must prove:
  - deterministic net creation,
  - deterministic instance ordering,
  - explicit link wiring is emitted correctly,
  - omitted/empty `?ports` can still work when explicit `?toplink` provides enough consistent evidence to infer the missing top ports, including renamed top-boundary names,
  - undeclared shared top inputs can be inferred when they are not already consumed by explicit child-to-child links,
  - undeclared unique top-facing child outputs can be inferred when they are not already consumed by explicit child-to-child links,
  - plain explicit top inputs can adopt same-name fanout convention when compatible child inputs still agree exactly on direction, width, and type metadata,
  - plain explicit top outputs can adopt unique same-name top-facing child outputs when the child-side evidence is still exact,
  - undeclared same-name internal carriers can be inferred when one unique child output and one or more child inputs share the same name and no explicit link already touches that family,
  - an explicit same-name top output may adopt and re-export that inferred carrier when width/type metadata still agree,
  - duplicate-driver errors are rejected.

### C3. Explicit-link external RTL composition
Status:
- Implemented in the current active toolchain for explicit-link tops with at least one external `?rtl` child and any number of generated children (`?fsmc` or `?dtc`) beside those RTL children, using the shipped `.rtlif` interface metadata and the same bounded omitted/empty-`?ports`, explicit-toplink top-port inference, undeclared top-interface, plain-explicit-port convention, and internal-carrier inference rules as `C2`.

- Input:
  - one or more `?rtl` children with explicit `?toplink` wiring,
  - optionally mixed with one or more generated children that participate in the same explicit-link plan.
- Must prove:
  - generated child is compiled,
  - RTL children are instantiated but not regenerated,
  - interface validation catches unknown ports, unsupported `.rtlif` type names, and direction mismatches,
  - deterministic carrier nets can feed more than one external RTL child from one resolved source,
  - multiple generated children can still participate in the same explicit-link plan as long as at least one `?rtl` child is present,
  - omitted/empty `?ports` can still work when explicit `?toplink` provides enough consistent evidence to infer the missing top ports, including renamed top-boundary names,
  - undeclared shared top inputs can still be inferred when they are not already consumed by explicit child-to-child links,
  - undeclared unique top-facing child outputs can still be inferred when they are not already consumed by explicit child-to-child links,
  - plain explicit top inputs can still adopt same-name fanout convention when compatible child inputs still agree exactly on direction, width, and type metadata,
  - plain explicit top outputs can still adopt one unique same-name top-facing child output when that child-side evidence is still exact,
  - undeclared same-name internal carriers can still be inferred when one unique child output and one or more child inputs share the same name and no explicit link already touches that family,
  - an explicit same-name top output may also adopt and re-export that inferred carrier when the top-boundary width/type contract still matches,
  - typed `.rtlif` `clock` / `reset` metadata can carry custom-named RTL system ports honestly.

### C4. Connect-by-name only when unambiguous
Status:
- Implemented in the current active toolchain for top ports declared as `=name` inside `?ports`, with direction-asymmetric same-name matching across the shipped single-child (`?fsmc`, `?dtc`, or `?rtl`), multi-generated-child, multi-`?rtl`, and mixed generated-child plus external RTL lanes.
- Implemented in the current active toolchain for top ports declared as `=name` inside `?ports`, with direction-asymmetric same-name matching:
  - top outputs still require exactly one compatible child output,
  - top inputs may fan out to one or more compatible child inputs.

- Input:
  - composition relying on declared connect-by-name.
- Must prove:
  - exact declared top outputs connect automatically when one unique child output matches,
  - exact declared top inputs can fan out automatically to one or more child inputs,
  - declared `=name` may coexist with explicit child-to-child `?toplink` wiring in the same bounded top,
  - ambiguous matches are rejected,
  - undeclared/unknown names are rejected.

### C5. Width mismatch diagnostics
Status:
- Implemented in the current active toolchain for both explicit `?toplink` links and declared `=name` connect-by-name ports.

- Input:
  - composition with incompatible linked widths.
- Must prove:
  - generation fails before emission,
  - the diagnostic identifies the two endpoints and the conflicting widths.

### C6. Legacy-composition features not in scope fail explicitly
Status:
- Implemented in the current active toolchain for legacy macro/plugin children and the currently out-of-scope legacy parser shapes that were still reachable from modern `?top:name` inputs.

- Input:
  - legacy macro/plugin-oriented composition constructs outside this scope.
- Must prove:
  - the active tool fails explicitly and points to unsupported composition scope,
  - it does not silently fall back to eval/plugin behavior.

## Test plan mapping
The first executable acceptance tests should be added as focused composition tests, separate from the FSM-only regression files.

Suggested initial names:
- `t/20-composition-single-fsm-top.t`
- `t/21-composition-two-fsm-linking.t`
- `t/22-composition-fsm-plus-rtl.t`
- `t/23-composition-errors.t`

## Exit boundary for `R6`
`R6` is not done when the scope is written down.

`R6` closes only when:
- the active composition source path exists in `bin/fsmgen`,
- the typed composition IR and top emitter exist,
- the acceptance matrix above is covered by executable tests,
- user/developer documentation reflects the shipped composition behavior.
