# VHDL Backend Scope

This document defines the scoped R14 VHDL backend plan for FSMGen.

## Status
- The CLI currently accepts `--language vhdl` and routes to `FSM::Pipeline::HDLGenerator`.
- `FSM::HDL::FlattenedDT::generate_vhdl()` now routes direct single-FSM roots
  through `FSM::HDL::FlattenedDT::Backend::VHDL`, an SV-first scaffold
  converter.
- The direct scaffold now includes delayed-pulse clock-branch nested-if
  lowering for the generated `<N` pulse-delay shape.
- The direct scaffold now includes the first arithmetic/XOR RHS expression family:
  scalar addition and subtraction RHS forms and chains lower to one-bit
  truncated `xor` semantics, scalar multiplication RHS forms and chains lower
  to one-bit `and` semantics, same-width vector addition/subtraction chains
  lower through `numeric_std` unsigned casts, and same-width vector
  multiplication/division/modulo chains lower through explicit target-width
  `numeric_std` resize. Same-width scalar/vector XOR chains lower to VHDL
  `xor`.
- The direct scaffold now includes generic-bearing direct-root module headers:
  generated SystemVerilog `parameter` blocks lower to VHDL generics, with
  arithmetic integer-expression defaults as `integer`, one-bit sized-literal
  defaults as `std_logic`, and multi-bit sized-literal defaults as
  `std_logic_vector` generics.
- The direct scaffold now includes generated mux arithmetic with one vector
  signal and one numeric literal operand for `+` and `-`, as emitted by the
  compound update/shorthand fixtures.
- The direct scaffold now includes signed vector numeric-literal
  addition/subtraction/multiplication/division/modulo RHS assignments through
  target-width `to_signed` literal conversion, with
  multiplication/division/modulo resized to the target width.
- The direct scaffold now includes signed scalar direct-root port/internal
  declaration lowering and signed scalar addition/subtraction/multiplication
  RHS/chain lowering for one-bit signed scalar target/operand shapes. Signed
  scalar division/modulo and mixed signed/unsigned scalar arithmetic remain
  fail-closed.
- The direct scaffold now includes the bounded generated unsigned AMBA wrap
  arithmetic family emitted by `fsm/amba_requester.fsm`, including
  `beats_total_q * addr_step_q`, `addr_q - addr_q % (beats_total_q * addr_step_q)`,
  and the matching wrap-high expression.
- The direct scaffold now includes generated internal signal declaration
  lowering for scalar `bit NAME;` and signed vector
  `reg signed [MSB:LSB] NAME;` shapes, as emitted by the declarative bits
  symbolic-width fixture.
- The direct scaffold now includes generated non-signed four-state `logic`
  internal signal declarations for scalar/vector direct-root shapes, including
  package-backed symbolic-width declarative `+types` fixtures.
- The direct scaffold now includes generated vector `logic signed` internal
  signal declarations, lowered to VHDL `signed` signals.
- The direct scaffold now includes generated signed vector direct-root port
  declarations, lowered to VHDL `signed` ports.
- The direct scaffold now includes same-width signed vector
  addition/subtraction/multiplication/division/modulo RHS lowering for
  assignments where the target and all operands are signed vectors of the same
  width.
- Composition VHDL is shipped only for the bounded C3 external-RTL
  literal/concat structural top in
  `t/corpus/composition_intent_integer_literals.fsm` and the bounded C1
  standalone-DT child passthrough top in
  `t/corpus/standalone_dtc_explicit_system_autowire.fsm`, plus the bounded C2
  generated-FSM scalar-autowire top in
  `t/corpus/implicit_composition_system_autowire.fsm`, plus the bounded APB/C4
  generated-FSM top in `fsm/apb_tb.fsm`. It also supports external-RTL scalar
  integer, scalar integer expression, metadata-backed one-bit sized bitstring,
  multi-bit sized bitstring, and resolved packed aggregate generic maps,
  including resolved qualified package constants, bounded C1 standalone-DT
  scalar integer, scalar expression, one-bit sized bitstring, multi-bit sized
  bitstring, packed-list, and packed-map generic maps, plus bounded C2
  generated-FSM scalar integer and scalar expression, one-bit sized bitstring,
  multi-bit sized bitstring, and resolved packed aggregate generic maps, plus
  bounded APB/C4 generated-FSM scalar integer, scalar expression, one-bit sized
  bitstring, multi-bit sized bitstring, resolved packed aggregate, and resolved
  package-backed generic maps in the shipped APB/C4 shape.
  Broader
  generated-FSM/C4 composition VHDL beyond the exact shipped fixtures,
  internal-net-heavy tops beyond APB, generic-map families outside these
  shipped sets: external-RTL scalar integer, scalar integer expression,
  metadata-backed one-bit sized bitstring, multi-bit sized bitstring
  literal/resolved-package-constant actuals, and resolved packed aggregate
  actuals; standalone-DT scalar integer, scalar expression, one-bit sized
  bitstring, multi-bit sized bitstring, packed-list, and packed-map actuals;
  generated-FSM scalar integer, scalar expression, one-bit sized bitstring,
  multi-bit sized bitstring, and resolved packed aggregate actuals; and APB/C4
  generated-FSM scalar integer, scalar expression, one-bit sized bitstring,
  multi-bit sized bitstring, resolved packed aggregate, and resolved
  package-backed actuals,
  VHDL package
  declaration/emission, full aggregate VHDL record/array lowering, broad
  expression parity, scalar division/modulo and broader scalar arithmetic,
  signed arithmetic operators beyond the shipped same-width vector arithmetic
  family, GHDL validation, packages, multi-clock domains, and full feature
  parity remain deferred.
- Mixed signed/unsigned vector numeric arithmetic is locked as an explicit
  fail-closed direct VHDL boundary by focused pipeline and facade coverage.
- Signed scalar addition/subtraction/multiplication arithmetic is locked as an
  explicit fail-closed direct VHDL boundary by focused pipeline and facade
  coverage.
- Scalar division/modulo RHS forms such as `A / B` and `A % B` are locked as
  explicit fail-closed direct VHDL boundaries by focused pipeline and facade
  coverage.
- Bounded direct aggregate-output roots now lower as packed
  `std_logic_vector` ports for the two maintained fixtures; full VHDL
  record/array aggregate lowering remains deferred.
- Composition/top VHDL is locked to the shipped structural-top leaves: the
  current pipeline and CLI accept `target_language => 'vhdl'` / `--language
  vhdl` only for the C3 external-RTL literal/concat fixture, the explicit
  C1 standalone-DT passthrough fixture, and the C2 generated-FSM scalar
  autowire fixture, plus the APB/C4 generated-FSM fixture. The external-RTL
  composition subset also accepts scalar integer, scalar integer expression,
  metadata-backed one-bit sized bitstring, multi-bit sized bitstring, and
  resolved packed aggregate generic maps, the C1 standalone-DT subset also
  accepts scalar integer, scalar expression, one-bit sized bitstring, multi-bit
  sized bitstring, packed-list, and packed-map generic maps, while
  the C2 generated-FSM subset also accepts scalar integer, scalar expression,
  one-bit sized bitstring, multi-bit sized bitstring, and resolved packed
  aggregate generic maps, and the APB/C4 generated-FSM subset also accepts
  scalar integer, scalar expression, one-bit sized bitstring, multi-bit sized
  bitstring, resolved packed aggregate, and resolved package-backed generic maps.
  Other `?top` shapes
  still parse into typed composition IR and then fail closed with the scoped
  composition target-support diagnostic.

## Goal
Implement a real, scoped VHDL backend that generates synthesizable VHDL from
`.fsm` sources through the existing pipeline, following the same
SystemVerilog-first-then-convert pattern already used for Verilog.

## Scope boundary — what the first lane covers
The VHDL lane is intentionally narrow:

1. **Direct-root scaffold plus four bounded composition structural tops**
   - Direct roots cover `?fsm:name` and `?dt:name`
   - Composition roots cover only the C3 external-RTL literal/concat shape in
     `t/corpus/composition_intent_integer_literals.fsm` and the C1
     standalone-DT explicit-port passthrough shape in
     `t/corpus/standalone_dtc_explicit_system_autowire.fsm`, plus the C2
     generated-FSM scalar-autowire shape in
     `t/corpus/implicit_composition_system_autowire.fsm`, plus the APB/C4
     generated-FSM shape in `fsm/apb_tb.fsm`
   - Broader generated-FSM/C4 composition VHDL, internal nets beyond exact
     owned fixtures, VHDL package declaration/emission, and generic-map
     families remain deferred outside these shipped sets: external-RTL scalar
     integer, scalar integer expression, metadata-backed one-bit sized
     bitstring, multi-bit sized bitstring literal/resolved-package-constant
     actuals, and resolved packed aggregate actuals; standalone-DT scalar
     integer, scalar expression, one-bit sized bitstring, multi-bit sized
     bitstring, packed-list, and packed-map actuals; generated-FSM scalar
     integer, scalar expression, one-bit sized bitstring, multi-bit sized
     bitstring, and resolved packed aggregate actuals; and APB/C4
     generated-FSM scalar integer, scalar expression, one-bit sized bitstring,
     multi-bit sized bitstring, resolved packed aggregate, and resolved
     package-backed actuals

2. **Direct-root structural conversion from SystemVerilog**
   - Generate SystemVerilog through the existing direct backend
   - Convert to VHDL through `FSM::HDL::FlattenedDT::Backend::VHDL`
   - Follow the same `convert_systemverilog_to_*` pattern as Verilog

3. **Composition structural emission from typed structural RTL IR**
   - Emit only the shipped external-RTL literal/concat, standalone-DT
     passthrough, C2 generated-FSM scalar-autowire, and APB/C4 generated-FSM
     structural tops through `FSM::Backend::VHDL::StructuralRTLIREmitter`
   - Render VHDL concurrent auxiliary assignments, generated standalone-DT
     child VHDL segments for the bounded C1 leaf, generated-FSM child VHDL
     segments for the bounded C2 and APB/C4 leaves, scalar/vector structural
     signals, VHDL port-map actuals, scalar integer / scalar integer
     expression / metadata-backed one-bit sized bitstring / multi-bit sized
     bitstring / resolved packed aggregate generic maps for external RTL
     instances, including resolved qualified package constants, scalar integer /
     scalar integer expression / one-bit sized bitstring / multi-bit sized
     bitstring / packed-list / packed-map generic maps for
     bounded standalone-DT instances, and scalar
     integer / scalar integer expression / multi-bit sized bitstring /
     one-bit sized bitstring / resolved packed aggregate
     generic maps for the bounded C2 generated-FSM family, plus scalar
     integer / scalar expression / one-bit sized bitstring / multi-bit sized
     bitstring / resolved packed aggregate / resolved package-backed generic
     maps for the bounded APB/C4 generated-FSM family
   - Reject generated-FSM child instances outside exact shipped or active
     leaves, generic-map families outside these shipped sets: external-RTL
     scalar integer, scalar integer expression, metadata-backed one-bit sized
     bitstring, multi-bit sized bitstring literal/resolved-package-constant,
     and resolved packed aggregate actuals; standalone-DT scalar
     integer/scalar expression/one-bit sized bitstring/multi-bit sized
     bitstring/packed-list/packed-map actuals; generated-FSM scalar integer,
     scalar expression, one-bit sized bitstring, multi-bit sized bitstring, and
     resolved packed aggregate actuals; and APB/C4 generated-FSM scalar
     integer/scalar expression/one-bit sized bitstring/multi-bit sized
     bitstring/resolved packed aggregate/resolved package-backed actuals, VHDL package
     declaration/emission, declared aggregate structural types, structural nets outside exact
     scalar/vector leaves, and non-VHDL auxiliary
     assignments

4. **Supported constructs in the first lane:**
   - Module declaration with port list
   - `std_logic` / `std_logic_vector` port and signal types
   - Synchronous processes with clock and synchronous or async reset
   - Combinational `process(all)` blocks mapped from SV `always_comb`
   - State encoding as VHDL constant declarations
   - Basic signal assignments
   - Basic Boolean enable expressions and concatenation RHS forms covered by
     the direct scaffold fixtures
   - Delayed-pulse clock branches that use the generated one-level nested
     `if (<pulse_delay_pipe>) begin ... end` shape
   - Scalar addition and subtraction RHS assignments and chains, lowered as
     one-bit truncated scalar `xor`
   - Scalar multiplication RHS assignments and multiplication chains, lowered
     as one-bit scalar `and`
   - Generated direct mux assignments with vector signal plus/minus numeric
     literal operands, such as `SRC + 2` and `byte_count + 4`
   - Signed vector numeric-literal
     addition/subtraction/multiplication/division/modulo RHS assignments, such
     as `A + 1`, `A - 1`, `A * 2`, `A / 2`, and `A mod 2`, through
     target-width `to_signed`
   - Signed scalar direct-root ports and internal declarations for
     non-arithmetic one-bit signed type-alias shapes, lowered as `std_logic`
   - Generated scalar `bit` internal signal declarations as `std_logic`
   - Generated signed vector internal signal declarations as VHDL `signed`
   - Generated non-signed four-state `logic` internal signal declarations as
     `std_logic` / `std_logic_vector`
   - Generated vector `logic signed` internal signal declarations as VHDL
     `signed`
   - Generated signed vector direct-root ports as VHDL `signed`
   - Same-width signed vector addition/subtraction/multiplication/division/
     modulo RHS assignments for signed targets and operands
   - Same-width addition, subtraction, multiplication, division, modulo, and
     XOR RHS chains in the generated direct combinational mux shape
   - Generic-bearing direct-root module headers emitted by the generated
     SystemVerilog `#(...)` parameter-block shape
   - Generated sized-literal generic defaults such as `1'b1` and `1'b0`
     mapped to typed VHDL scalar/vector generics

5. **Intentionally deferred:**
   - Broader generated-child/C4 composition-top VHDL beyond the exact shipped
     fixtures
   - Internal-net-heavy composition-top VHDL beyond the APB/C4 fixture
   - Composition VHDL generic-map lowering
   - VHDL packages (SV packages → VHDL packages)
   - Intermediate signal factorization (needs VHDL signal declaration semantics)
   - Multi-clock domains
   - VHDL-specific testbenches
   - VHDL external validation (GHDL)
   - Verilator/Yosys VHDL path

## Implementation plan

### Phase 1: Conversion scaffolding (R14.1)
- Created `perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm` with the conversion
  entrypoint
- Wired into `FSM::HDL::FlattenedDT::generate_vhdl()`
- First deliverable: generate deterministic direct-root VHDL text for the
  accepted scaffold fixtures
- Reuses the existing SystemVerilog generation path as input

### Phase 2: Semantic conversion (R14.2)
- Shipped for the current scaffold subset:
  SystemVerilog `always_ff` → VHDL synchronous/async-reset process,
  SystemVerilog `always_comb` → VHDL `process(all)`, port/signal type
  mapping, module/entity conversion, reset polarity handling, and generated
  delayed-pulse nested clock-branch lowering, plus same-width addition,
  subtraction, multiplication, division, modulo, and XOR RHS expression chains,
  scalar addition/subtraction/multiplication RHS/chain lowering, and
  generated direct-root vector signal plus/minus numeric literal mux
  expressions from compound update/shorthand fixtures, generated direct-root
  scalar `bit` and signed vector internal signal declarations from declarative
  `+types` symbolic-width fixtures, generated non-signed four-state `logic`
  internal signal declarations from package-backed declarative `+types`
  fixtures, generated vector `logic signed` internal signal declarations,
  generated signed vector direct-root port declarations, same-width signed
  vector addition/subtraction/multiplication/division/modulo RHS assignments,
  signed vector numeric-literal addition/subtraction/multiplication/division/modulo
  RHS assignments, signed scalar direct-root declarations,
  signed scalar addition/subtraction/multiplication RHS/chain lowering,
  bounded AMBA wrap arithmetic,
  plus direct-root parameter blocks as VHDL
  generics, including integer expression defaults and typed scalar/vector
  sized-literal defaults.
- Shipped the first bounded composition VHDL structural-top leaf under
  `BACKEND-API-VALIDATION-FRONTIER.68.1`, limited to the C3 external-RTL
  literal/concat fixture in `t/corpus/composition_intent_integer_literals.fsm`.
  It emits VHDL concurrent literal/concat assignments and an
  `entity work.uart_tx` port map.
- Shipped bounded external-RTL scalar integer generic-map lowering under
  `BACKEND-API-VALIDATION-FRONTIER.73.1`. VHDL structural tops now emit
  `generic map` blocks such as `WIDTH => 16` before an external RTL instance's
  port map.
- Shipped bounded external-RTL multi-bit sized bitstring generic-map actual
  lowering under `BACKEND-API-VALIDATION-FRONTIER.74.1`. VHDL structural tops
  now emit actuals such as `RESET_VALUE => "10100101"` for `8'hA5`;
  generated-child, standalone-DT, scalar expressions, one-bit actuals that need
  target-type discrimination, aggregate, and unresolved package/expression
  generic actuals remained deferred at that slice.
- Shipped bounded resolved package-backed external-RTL generic-map actual
  coverage under `BACKEND-API-VALIDATION-FRONTIER.75.1`. Qualified imported
  package constants such as `param_pkg.WIDTH_16` and `param_pkg.RESET_A5`
  resolve before VHDL structural emission and emit literal actuals such as
  `WIDTH => 16` and `RESET_VALUE => "10100101"`; this does not add VHDL
  package declaration/emission support.
- Shipped bounded external-RTL scalar integer expression generic-map actual
  lowering under `BACKEND-API-VALIDATION-FRONTIER.76.1`. VHDL structural tops
  now emit resolved expressions such as `EXPR_WIDTH => (16 + 1)` before the
  `port map`; broader expression parity remains separate.
- Shipped bounded resolved packed aggregate external-RTL generic-map actual
  lowering under `BACKEND-API-VALIDATION-FRONTIER.77.1`. VHDL structural tops
  now emit list/map aggregate actuals after they resolve to multi-bit packed
  values, such as `LANES => "1010010100111100"` and `FRAME => "101"`.
- Shipped bounded C2 generated-FSM scalar integer generic-map actual lowering
  under `BACKEND-API-VALIDATION-FRONTIER.78.1`. VHDL structural tops now emit
  generated child instance actuals such as `WIDTH => 16` before the generated
  child port map.
- Shipped bounded C2 generated-FSM scalar expression generic-map actual
  lowering under `BACKEND-API-VALIDATION-FRONTIER.79.1`. VHDL structural tops
  now emit generated child instance expression actuals such as
  `EXPR_WIDTH => (16 + 1)` before the generated child port map. At that
  slice, generated-FSM one-bit, bitstring, and aggregate actuals remained
  deferred.
- Shipped bounded C2 generated-FSM multi-bit sized bitstring generic-map actual
  lowering under `BACKEND-API-VALIDATION-FRONTIER.80.1`. VHDL structural tops
  now emit generated child instance bitstring actuals such as
  `RESET_VALUE => "10100101"` before the generated child port map. At that
  slice, generated-FSM one-bit and aggregate actuals remained deferred.
- Shipped bounded C2 generated-FSM resolved packed aggregate generic-map actual
  lowering under `BACKEND-API-VALIDATION-FRONTIER.81.1`. VHDL structural tops
  now emit generated child instance aggregate actuals such as
  `LANES => "1010010100111100"` and `FRAME => "101"` before the generated
  child port map. At that slice, generated-FSM one-bit actuals remained
  deferred.
- Shipped bounded C2 generated-FSM one-bit sized bitstring generic-map actual
  lowering under `BACKEND-API-VALIDATION-FRONTIER.82.1`. VHDL structural tops
  now emit generated child instance one-bit actuals such as
  `ENABLE_DEFAULT => '1'` before the generated child port map, while the child
  entity keeps a `std_logic` generic declaration.
- Shipped bounded C3 external-RTL metadata-backed one-bit sized bitstring
  generic-map actual lowering under `BACKEND-API-VALIDATION-FRONTIER.83.1`.
  VHDL structural tops now emit external RTL instance one-bit actuals such as
  `ENABLE_DEFAULT => '1'` when the matching `.rtlif` parameter declaration has
  scalar one-bit default metadata such as `ENABLE_DEFAULT 1'b0`.
- Shipped bounded C1 standalone-DT scalar integer generic-map actual lowering
  under `BACKEND-API-VALIDATION-FRONTIER.84.1`. VHDL structural tops now emit
  standalone-DT child instance scalar actuals such as `WIDTH => 16` before the
  standalone-DT child port map, while the child entity keeps an integer generic
  declaration.
- Shipped bounded C1 standalone-DT scalar expression generic-map actual
  lowering under `BACKEND-API-VALIDATION-FRONTIER.85.1`. VHDL structural tops
  now emit standalone-DT child instance scalar expression actuals such as
  `EXPR_WIDTH => (8 + 1)` before the standalone-DT child port map, while the
  child entity keeps an integer generic declaration.
- Shipped bounded C1 standalone-DT one-bit sized-bitstring generic-map actual
  lowering under `BACKEND-API-VALIDATION-FRONTIER.86.1`. VHDL structural tops
  now emit standalone-DT child instance one-bit actuals such as
  `ENABLE_DEFAULT => '1'` before the standalone-DT child port map, while the
  child entity keeps a `std_logic` generic declaration.
- Shipped bounded C1 standalone-DT multi-bit sized-bitstring generic-map actual
  lowering under `BACKEND-API-VALIDATION-FRONTIER.87.1`. VHDL structural tops
  now emit standalone-DT child instance multi-bit actuals such as
  `RESET_VALUE => "10100101"` before the standalone-DT child port map, while
  the child entity keeps a `std_logic_vector` generic declaration.
- Shipped bounded C1 standalone-DT packed-list generic-map actual lowering
  under `BACKEND-API-VALIDATION-FRONTIER.88.1`. VHDL structural tops now emit
  standalone-DT child instance packed-list actuals such as
  `LANES => "1010010100111100"` before the standalone-DT child port map, while
  the child entity keeps a packed `std_logic_vector` generic declaration.
- Shipped bounded C1 standalone-DT packed-map generic-map actual lowering
  under `BACKEND-API-VALIDATION-FRONTIER.89.1`. VHDL structural tops now emit
  standalone-DT child instance packed-map actuals such as `FRAME => "101"`
  before the standalone-DT child port map, while the child entity keeps a
  packed `std_logic_vector` generic declaration.
- Shipped the bounded C1 standalone-DT child composition VHDL top under
  `BACKEND-API-VALIDATION-FRONTIER.69.1`, limited to
  `t/corpus/standalone_dtc_explicit_system_autowire.fsm`. It emits the
  `standalone_route_src` VHDL child segment and a top-level
  `entity work.standalone_route_src` port map for the explicit passthrough
  ports.
- Shipped the bounded C2 generated-FSM child composition VHDL top under
  `BACKEND-API-VALIDATION-FRONTIER.70.1`, limited to
  `t/corpus/implicit_composition_system_autowire.fsm`. It emits VHDL-safe
  generated-child shared-datapath export ports/assignments, scalar structural
  signals, and both generated child entity port maps.
- Shipped the bounded APB/C4 generated-FSM child composition VHDL top under
  `BACKEND-API-VALIDATION-FRONTIER.71.1`, limited to `fsm/apb_tb.fsm`. It emits
  VHDL-safe APB requester/completer child segments, vector APB structural
  signals, deterministic shared-datapath sink signals, and both generated child
  entity port maps. Broader generated-FSM/C4 composition VHDL, internal
  nets/generic-map families outside the exact shipped external-RTL scalar-integer,
  scalar-expression, metadata-backed one-bit sized-bitstring,
  multi-bit sized-bitstring literal/resolved-package-constant, resolved packed
  aggregate generic-map, standalone-DT scalar-integer/scalar-expression
  generic-map, and C2 generated-FSM scalar-integer/scalar-expression/one-bit sized-bitstring/multi-bit
  sized-bitstring/resolved-packed-aggregate generic-map fixtures, APB/C4
  scalar-integer/scalar-expression/one-bit sized-bitstring/multi-bit
  sized-bitstring/resolved-packed-aggregate/resolved-package-backed generic-map
  fixtures, VHDL package
  declaration/emission, full aggregate VHDL record/array lowering, broader
  expression parity, signed scalar division/modulo, and mixed signed/unsigned
  scalar arithmetic remain separate future edges. APB/C4 non-packed aggregate
  generic-map hardening is the active `BACKEND-API-VALIDATION-FRONTIER.96.1`
  owner and does not imply record/array VHDL generic declaration support.
- Remaining semantic conversion work still belongs to exact future VHDL leaves.

### Phase 3: Regression and hardening (R14.3)
- Focused direct VHDL generation tests cover pipeline and CLI routing,
  sync/async reset processes, delayed-pulse clock branches, concat lowering,
  scalar addition/subtraction/multiplication chains, same-width
  addition/subtraction/multiplication/division/modulo/XOR chain lowering,
  vector numeric-literal addition/subtraction mux lowering,
  scalar `bit` and signed vector internal declaration lowering,
  non-signed four-state `logic` scalar/vector internal declaration lowering,
  vector `logic signed` internal declaration lowering,
  signed vector direct-root port declaration lowering,
  signed scalar addition/subtraction/multiplication RHS/chain lowering,
  generic-bearing direct-root module headers, one-bit `std_logic` and
  multi-bit `std_logic_vector` sized-literal generic defaults,
  bounded generated AMBA wrap arithmetic for `fsm/amba_requester.fsm`,
  bounded direct aggregate-output packed-vector lowering,
  bounded C3 external-RTL literal/concat composition VHDL structural-top
  generation,
  bounded external-RTL scalar integer, scalar expression, metadata-backed
  one-bit sized bitstring, multi-bit sized bitstring, resolved package-backed,
  and packed aggregate VHDL generic-map generation,
  bounded C1 standalone-DT scalar integer, scalar expression, one-bit sized
  bitstring, multi-bit sized bitstring, packed-list, and packed-map VHDL generic-map
  generation,
  bounded C1 standalone-DT and C2 generated-FSM composition VHDL structural-top
  generation,
  bounded C2 generated-FSM scalar integer, scalar expression, one-bit sized
  bitstring, multi-bit sized bitstring, and resolved packed aggregate VHDL
  generic-map generation,
  bounded APB/C4 generated-FSM composition VHDL structural-top generation,
  bounded APB/C4 generated-FSM scalar integer, scalar expression, one-bit sized
  bitstring, multi-bit sized bitstring, resolved packed aggregate, and resolved
  package-backed VHDL
  generic-map generation,
  mixed signed/unsigned vector numeric arithmetic fail-closed diagnostics,
  signed scalar division/modulo and mixed signed/unsigned scalar arithmetic
  fail-closed diagnostics,
  mismatched-width arithmetic-expression fail-closed diagnostics, and
  broader composition/top VHDL fail-closed diagnostics.
- Add broader VHDL output to the regression corpus
- Ensure `--check --json` and `--emit-semantic-json` stay target-neutral
- Consider external VHDL validation via GHDL

## Non-goals for R14
- Broader VHDL composition-top generation beyond exact owned structural-top
  leaves
- Full VHDL structural feature parity with SystemVerilog
- VHDL-2019 specific features in the first lane
- Mixed-language (SV+VHDL) co-simulation

## Relationship to existing Verilog path
The existing Verilog conversion path (`FSM::Backend::VerilogFamily`) provides
the architectural pattern:
1. Generate SystemVerilog through the normal direct backend
2. Convert to target language through a dedicated converter module
3. The converter owns syntax/semantic mapping, not pipeline orchestration

The VHDL backend should follow this same pattern: thin converter module,
SV-first generation, no duplication of the AST/pipeline layer.
