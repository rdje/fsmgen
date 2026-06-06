---
id: direct-vhdl-scaffold
title: Direct single-FSM VHDL generation has a scoped scaffold
answers:
  - "is VHDL still not implemented?"
  - "does --language vhdl work for direct FSM roots?"
  - "does --language vhdl work for composition tops?"
  - "does target_language vhdl work for composition roots?"
  - "what VHDL subset is shipped?"
  - "which composition VHDL subset is shipped?"
  - "does composition VHDL support standalone-DT children?"
  - "does composition VHDL support standalone-DT generic maps?"
  - "does composition VHDL support standalone-DT scalar generic maps?"
  - "does composition VHDL support standalone-DT scalar expression generic maps?"
  - "does composition VHDL support standalone-DT one-bit generic maps?"
  - "does composition VHDL support one-bit standalone-DT generic maps?"
  - "does composition VHDL support standalone-DT multi-bit generic maps?"
  - "does composition VHDL support multi-bit standalone-DT generic maps?"
  - "does composition VHDL support standalone-DT bitstring generic maps?"
  - "does composition VHDL support standalone-DT list generic maps?"
  - "does composition VHDL support standalone-DT packed-list generic maps?"
  - "does composition VHDL support standalone-DT map generic maps?"
  - "does composition VHDL support standalone-DT packed-map generic maps?"
  - "does composition VHDL support generated-FSM children?"
  - "does composition VHDL support C2 generated-FSM children?"
  - "does composition VHDL support APB/C4 generated-FSM children?"
  - "does composition VHDL support APB composition tops?"
  - "does composition VHDL support APB/C4 composition tops?"
  - "does composition VHDL support APB/C4 scalar generic maps?"
  - "does composition VHDL support APB/C4 scalar expression generic maps?"
  - "does composition VHDL support APB/C4 one-bit generic maps?"
  - "does composition VHDL support APB/C4 multi-bit generic maps?"
  - "does composition VHDL support APB/C4 bitstring generic maps?"
  - "does composition VHDL support APB/C4 aggregate generic maps?"
  - "does composition VHDL support APB/C4 packed aggregate generic maps?"
  - "does composition VHDL support APB/C4 non-packed aggregate generic maps?"
  - "does composition VHDL support non-packed aggregate generic maps?"
  - "does composition VHDL support APB/C4 package-backed generic maps?"
  - "does composition VHDL resolve APB/C4 package constants in generic maps?"
  - "does --language vhdl work for standalone-DT composition tops?"
  - "does --language vhdl work for C2 generated-FSM composition tops?"
  - "does --language vhdl work for APB/C4 composition tops?"
  - "does target_language vhdl work for standalone-DT composition roots?"
  - "does target_language vhdl work for C2 generated-FSM composition roots?"
  - "does target_language vhdl work for APB/C4 composition roots?"
  - "does composition VHDL support generic maps?"
  - "does composition VHDL support external RTL generic maps?"
  - "does composition VHDL support generated-FSM generic maps?"
  - "does composition VHDL support generated-child generic maps?"
  - "does composition VHDL support generated-FSM one-bit generic maps?"
  - "does composition VHDL support one-bit generated-FSM generic maps?"
  - "does composition VHDL support bitstring generic maps?"
  - "does composition VHDL support sized bitstring generic actuals?"
  - "does composition VHDL support scalar expression generic maps?"
  - "does composition VHDL support expression generic actuals?"
  - "does composition VHDL support aggregate generic maps?"
  - "does composition VHDL support aggregate generic actuals?"
  - "does composition VHDL support list generic actuals?"
  - "does composition VHDL support record generic actuals?"
  - "does composition VHDL support external-RTL non-packed aggregate generic maps?"
  - "does composition VHDL support external non-packed aggregate generic maps?"
  - "does composition VHDL support package-backed generic maps?"
  - "does composition VHDL support package-backed generic actuals?"
  - "does composition VHDL emit package constants in generic maps?"
  - "does composition VHDL support external RTL one-bit generic maps?"
  - "does composition VHDL support one-bit external RTL generic maps?"
  - "does direct VHDL support aggregate outputs?"
  - "is composition VHDL supported?"
  - "is GHDL validation active?"
  - "does direct VHDL support delayed pulses?"
  - "does direct VHDL support arithmetic expressions?"
  - "does direct VHDL support multi-operand addition?"
  - "does direct VHDL support subtraction chains?"
  - "does direct VHDL support multiplication chains?"
  - "does direct VHDL support division/modulo chains?"
  - "does direct VHDL support XOR chains?"
  - "does direct VHDL support scalar addition?"
  - "does direct VHDL support scalar addition chains?"
  - "does direct VHDL support scalar subtraction?"
  - "does direct VHDL support scalar subtraction chains?"
  - "does direct VHDL support scalar division?"
  - "does direct VHDL support scalar modulo?"
  - "does direct VHDL support scalar division/modulo?"
  - "does direct VHDL support scalar multiplication?"
  - "does direct VHDL support scalar multiplication chains?"
  - "does direct VHDL support numeric literal arithmetic?"
  - "does direct VHDL support signed numeric literal arithmetic?"
  - "does direct VHDL support signed vector numeric literal arithmetic?"
  - "does direct VHDL support compound update arithmetic?"
  - "does direct VHDL support signed declarations?"
  - "does direct VHDL support signed logic declarations?"
  - "does direct VHDL support logic signed declarations?"
  - "does direct VHDL support signed ports?"
  - "does direct VHDL support signed vector ports?"
  - "does direct VHDL support signed addition?"
  - "does direct VHDL support signed vector addition?"
  - "does direct VHDL support signed subtraction?"
  - "does direct VHDL support signed vector subtraction?"
  - "does direct VHDL support signed multiplication?"
  - "does direct VHDL support signed vector multiplication?"
  - "does direct VHDL support signed division?"
  - "does direct VHDL support signed modulo?"
  - "does direct VHDL support signed division/modulo?"
  - "does direct VHDL support signed vector division/modulo?"
  - "does direct VHDL support signed scalar arithmetic?"
  - "does direct VHDL support AMBA requester?"
  - "does direct VHDL support AMBA wrap arithmetic?"
  - "does direct VHDL support scalar bit declarations?"
  - "does direct VHDL support logic declarations?"
  - "does direct VHDL support four-state declarations?"
  - "does direct VHDL support generics?"
  - "does direct VHDL support parameterized direct roots?"
  - "does direct VHDL support sized literal generic defaults?"
  - "does direct VHDL support vector sized literal generic defaults?"
date: 2026-06-06
status: current
tags: [vhdl, backend, direct-generation, composition, validation]
evidence: perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm; perl/FSM/Backend/VHDL/StructuralRTLIREmitter.pm; perl/FSM/Composition/GenerationOrchestrator.pm; perl/FSM/Composition/PlanBuilder.pm; perl/FSM/Support/HDLExternalValidationContract.pm; t/1420-vhdl-direct-backend-scaffold.t; t/386-hdl-generator-facade-target-language-boundary-audit.t; t/114-composition-target-support-diagnostics.t; docs/VHDL_SCOPE.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/1420-vhdl-direct-backend-scaffold.t t/386-hdl-generator-facade-target-language-boundary-audit.t t/114-composition-target-support-diagnostics.t t/313-hdl-external-validation-contract.t t/308-systemverilog-external-validation.t
---

Direct single-FSM roots can now use `target_language => 'vhdl'` or
`--language vhdl` for the shipped scaffold subset: scalar/vector ports, state
constants, enable assignments, sync/async reset processes, `process(all)`
combinational muxes, generic-bearing direct-root module headers, basic concat
RHS forms, and delayed-pulse clock-branch nested-if lowering. Generated
SystemVerilog `parameter` blocks for direct roots lower to VHDL generics before
the port block while the body keeps already-resolved concrete signal widths:
arithmetic integer-expression defaults become `integer` generics. Sized-literal
defaults become `std_logic` generics for one-bit defaults and
`std_logic_vector` generics for multi-bit defaults; the focused coverage uses
`params_aggregate_comparison` for the scalar case and
`params_aggregate_unary_complement` for the vector case. Generated scalar
`bit` internal declarations lower to `std_logic`, generated signed vector
internal declarations such as `reg signed [3:0] NIB` lower to VHDL `signed`
signals, generated non-signed four-state `logic` internal declarations lower
to `std_logic` / `std_logic_vector` for package-backed declarative `+types`
fixtures, and generated vector `logic signed [MSB:LSB] NAME;` internal
declarations lower to VHDL `signed` signals. Generated signed vector
direct-root input/output port declarations lower to VHDL `signed` ports. The
scaffold also lowers the first arithmetic RHS shape:
scalar addition and subtraction RHS forms and chains lower to one-bit truncated
`xor` semantics, and scalar multiplication plus scalar multiplication chains
lower to one-bit `and` semantics. Generated direct mux expressions with one vector
signal and one numeric literal operand for `+` or `-`, such as `SRC + 2` and
`byte_count + 4` from compound update/shorthand fixtures, lower through
target-width `to_unsigned` casts. Same-width vector `NAME + NAME` assignments
and same-width multi-operand
addition chains become
`std_logic_vector(unsigned(A) + unsigned(B) + ...)` expressions; same-width
vector subtraction chains become
`std_logic_vector(unsigned(A) - unsigned(B) - ...)` expressions.
Same-width vector multiplication chains become
`std_logic_vector(resize(unsigned(A) * unsigned(B) * ..., WIDTH))`
expressions. Same-width vector division/modulo chains become
`std_logic_vector(resize(unsigned(A) / unsigned(B) / ..., WIDTH))` and
`std_logic_vector(resize(unsigned(A) mod unsigned(B) mod ..., WIDTH))`
expressions. Scalar division/modulo RHS forms such as `A / B` and `A % B`
remain explicit fail-closed direct VHDL boundaries. Same-width scalar/vector XOR
chains become `A xor B xor ...`
expressions. Same-width signed vector addition RHS assignments lower as signed
VHDL arithmetic, such as `SUM <= A + B;`, when the target and all operands are
same-width signed vectors. Same-width signed vector subtraction RHS assignments
also lower as signed VHDL arithmetic, such as `DIFF <= A - B;`, under the same
target/operand constraints. Same-width signed vector multiplication RHS
assignments lower as target-width resized signed VHDL arithmetic, such as
`PROD <= resize(A * B, 8);`, under the same target/operand constraints.
Same-width signed vector division/modulo RHS assignments lower as target-width
resized signed VHDL arithmetic, such as `QUOT <= resize(A / B, 8);` and
`REM <= resize(A mod B, 8);`, under the same target/operand constraints. Signed
vector numeric-literal addition/subtraction lowers through target-width
`to_signed`, such as `SUM <= A + to_signed(1, 8);` and
`DIFF <= A - to_signed(1, 8);`. Signed vector numeric-literal
multiplication/division/modulo lowers through target-width `to_signed` and
target-width resize, such as `PROD <= resize(A * to_signed(2, 8), 8);`,
`QUOT <= resize(A / to_signed(2, 8), 8);`, and
`REM <= resize(A mod to_signed(2, 8), 8);`.
Signed scalar direct-root port/internal declarations for one-bit signed
type-alias shapes lower to `std_logic`, including declarations such as
`IN : in std_logic;` and `signal OUT : std_logic;`. Signed scalar
addition/subtraction RHS assignments and chains lower to one-bit `xor`
semantics, such as `SUM <= A xor B;`; signed scalar multiplication lowers to
one-bit `and` semantics, such as `PROD <= A and B;`. Signed scalar
division/modulo and mixed signed/unsigned scalar arithmetic remain outside the
current direct VHDL scaffold.
Mixed signed/unsigned vector numeric arithmetic is locked as an explicit
fail-closed direct VHDL boundary instead of lowering signed operands through
unsigned casts.
The direct VHDL scaffold now lowers the bounded generated AMBA wrap arithmetic
family in `fsm/amba_requester.fsm`: `wrap_span_q_next` uses the mixed-width
unsigned product `beats_total_q * addr_step_q`, `wrap_base_q_next` lowers
`addr_q - addr_q % (beats_total_q * addr_step_q)`, and `wrap_high_q_next`
adds the same wrap-span product to the computed base. This is a pattern-owned
AMBA wrap family, not broad expression-parser parity.
Bounded direct aggregate-output fixtures now lower as VHDL packed vectors:
`NESTED` is `std_logic_vector(6 downto 0)`, `OUT` is
`std_logic_vector(2 downto 0)`, and `OUT_FRAME` / `OUT_LANES` are 5-bit
`std_logic_vector` ports. Full VHDL record/array aggregate lowering remains a
later exact owner.
The maintained supported direct-root VHDL sweep now runs clean. The first
bounded composition VHDL structural top is also shipped for the C3 external-RTL
literal/concat fixture in `t/corpus/composition_intent_integer_literals.fsm`.
That composition subset emits a VHDL entity/architecture with concurrent
literal and concat assignments plus an external `entity work.uart_tx` port map,
without SystemVerilog `module`, `assign`, `endmodule`, or `always_*` syntax.
The bounded C1 standalone-DT child composition VHDL top is also shipped for
`t/corpus/standalone_dtc_explicit_system_autowire.fsm`. That subset emits the
`standalone_route_src` child VHDL entity plus a top-level
`entity work.standalone_route_src` port map for the explicit passthrough ports,
without SystemVerilog structural syntax. The same bounded C1 standalone-DT
family also lowers scalar integer, scalar integer expression, one-bit
sized-bitstring, multi-bit sized-bitstring, packed-list, and packed-map
parameter overrides to `generic map` actuals before the standalone-DT child
port map, such as `WIDTH => 16`, `EXPR_WIDTH => (8 + 1)`,
`ENABLE_DEFAULT => '1'`, `RESET_VALUE => "10100101"`,
`LANES => "1010010100111100"`, and `FRAME => "101"`, while the child entity
keeps the matching VHDL integer, `std_logic`, or `std_logic_vector` generic
declaration.
External-RTL C3 composition VHDL also
lowers scalar integer, metadata-backed one-bit sized bitstring, and multi-bit
sized bitstring parameter overrides to `generic map` actuals before the port
map, such as `WIDTH => 16`, `ENABLE_DEFAULT => '1'`, and
`RESET_VALUE => "10100101"` for `8'hA5`, and resolved scalar integer
expressions such as `EXPR_WIDTH => (16 + 1)`. Resolved packed list/map
aggregate actuals also emit as VHDL bit strings, such as
`LANES => "1010010100111100"` and `FRAME => "101"`. Qualified imported package
constants in that same external-RTL subset are resolved before VHDL emission
and also emit literal actuals, for example `param_pkg.WIDTH_16` and
`param_pkg.RESET_A5` emit `WIDTH => 16` and
`RESET_VALUE => "10100101"` without leaking `param_pkg` into the VHDL; this is
not VHDL package declaration/emission support. External-RTL one-bit actuals
are supported only when the matching `.rtlif` parameter declaration provides
scalar one-bit default metadata such as `ENABLE_DEFAULT 1'b0`. External-RTL
non-packed aggregate generic maps are locked fail-closed before VHDL emission:
aggregate/list/record actuals that do not lower to one packed literal fail
with the packed-literal diagnostic instead of emitting VHDL record/array
generics. Standalone-DT non-packed aggregate generic-map hardening is active
under `BACKEND-API-VALIDATION-FRONTIER.98.1`; until that leaf ships,
standalone-DT generic maps beyond
integer/scalar expression/one-bit sized-bitstring/multi-bit sized-bitstring/
packed-list/packed-map actuals remain deferred. Unresolved
package/expression actuals and APB/C4 generic maps beyond scalar integer,
scalar expression, one-bit sized-bitstring, and multi-bit sized-bitstring
actuals plus resolved packed aggregate and resolved package-backed actuals
remain deferred for those
families. The
bounded C2 generated-FSM child
composition VHDL top is also shipped for
`t/corpus/implicit_composition_system_autowire.fsm`. That subset emits VHDL-safe
generated-child shared-datapath export ports/assignments, scalar structural
signals, and VHDL entity port maps for `implicit_autowire_producer` and
`implicit_autowire_consumer`, without SystemVerilog structural syntax. The
same bounded C2 generated-FSM family also emits scalar integer generic maps
before the generated child port map, such as `WIDTH => 16`, while the child
entity keeps the matching VHDL generic declaration. Scalar expression generic
maps also emit before the generated child port map, such as
`EXPR_WIDTH => (16 + 1)`, against the child VHDL integer generic declaration.
One-bit sized bitstring generic maps also emit before the generated child port
map, such as `ENABLE_DEFAULT => '1'` for `ENABLE_DEFAULT 1'b1`, against the
child VHDL `std_logic` generic declaration.
Multi-bit sized bitstring generic maps also emit before the generated child
port map, such as `RESET_VALUE => "10100101"` for `RESET_VALUE 8'hA5`, against
the child VHDL `std_logic_vector` generic declaration. Resolved packed
aggregate generic maps also emit before the generated child port map, such as
`LANES => "1010010100111100"` and `FRAME => "101"`, against the child VHDL
`std_logic_vector` generic declarations.
The bounded APB/C4 generated-FSM child composition VHDL top is also shipped for
`fsm/apb_tb.fsm`. That subset emits VHDL-safe APB requester/completer child
segments, vector APB structural signals, deterministic shared-datapath sink
signals, and VHDL entity port maps for `apb_requester` and `apb_completer`,
without SystemVerilog structural syntax. The same bounded APB/C4 generated-FSM
family also lowers scalar integer parameter overrides to VHDL generic maps
before the requester/completer child port maps, such as
`TIMEOUT_CYCLES => 8` and `TIMEOUT_CYCLES => 6`, scalar expression
overrides such as `TIMEOUT_CYCLES => (4 + 1)` and
`TIMEOUT_CYCLES => (3 + 3)`, and one-bit sized-bitstring overrides such as
`ENABLE_DEFAULT => '1'`, plus multi-bit sized-bitstring overrides such as
`RESET_VALUE => "10100101"` and `RESET_VALUE => "00111100"`, while the child
entities keep matching `integer`, `std_logic`, or `std_logic_vector` generic
declarations. Resolved APB/C4 packed aggregate generic maps also emit before
the child port maps, such as `LANES => "0011110010100101"` and
`FRAME => "101"`, against matching `std_logic_vector` generic declarations.
Qualified package constants in the same APB/C4 subset are resolved before VHDL
emission, so `param_pkg.TIMEOUT_8` and `param_pkg.RESET_A5` emit
`TIMEOUT_CYCLES => 8` and `RESET_VALUE => "10100101"` without leaking package
tokens. APB/C4 non-packed aggregate generic maps are locked fail-closed before
VHDL emission: aggregate actuals that do not lower to one packed literal fail
with the packed-literal diagnostic instead of emitting VHDL record/array
generics. APB/C4 VHDL package declaration/emission remains deferred.
Other composition/top VHDL shapes remain locked fail-closed by focused pipeline
and CLI coverage: `?top` sources are parsed into typed composition IR, then unsupported
`target_language => 'vhdl'` and `--language vhdl` shapes are rejected with the
scoped composition target-support diagnostic. Broader generated-FSM/C4
composition VHDL beyond the exact shipped fixtures, internal nets/generic maps,
packages, multi-clock domains, broad expression parity, GHDL validation, and
full SystemVerilog parity remain deferred or fail-closed.
