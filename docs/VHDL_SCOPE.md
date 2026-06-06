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
- The direct scaffold now includes same-width signed vector addition/subtraction RHS
  lowering for assignments where the target and all operands are signed
  vectors of the same width.
- Composition VHDL, aggregate VHDL, broad expression parity, scalar
  division/modulo and broader scalar arithmetic, signed arithmetic operators
  beyond same-width vector addition/subtraction, GHDL validation, packages,
  multi-clock domains, and full feature parity remain deferred.
- Scalar division/modulo RHS forms such as `A / B` and `A % B` are locked as
  explicit fail-closed direct VHDL boundaries by focused pipeline and facade
  coverage.
- Aggregate-output roots are locked as explicit fail-closed direct VHDL
  boundaries by focused pipeline and facade coverage.
- Composition/top VHDL is locked as an explicit fail-closed boundary. Current
  pipeline and CLI composition paths parse `?top` sources into typed
  composition IR, then reject `target_language => 'vhdl'` / `--language vhdl`
  with the scoped composition target-support diagnostic instead of emitting a
  VHDL top.

## Goal
Implement a real, scoped VHDL backend that generates synthesizable VHDL from
`.fsm` sources through the existing pipeline, following the same
SystemVerilog-first-then-convert pattern already used for Verilog.

## Scope boundary — what the first lane covers
The first VHDL lane is intentionally narrow:

1. **Single-FSM direct roots only** (`?fsm:name` and `?dt:name`)
   - No composition-top VHDL generation yet
   - No `?top` composition VHDL

2. **Structural conversion from SystemVerilog**
   - Generate SystemVerilog through the existing direct backend
   - Convert to VHDL through `FSM::HDL::FlattenedDT::Backend::VHDL`
   - Follow the same `convert_systemverilog_to_*` pattern as Verilog

3. **Supported constructs in the first lane:**
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
   - Generated scalar `bit` internal signal declarations as `std_logic`
   - Generated signed vector internal signal declarations as VHDL `signed`
   - Generated non-signed four-state `logic` internal signal declarations as
     `std_logic` / `std_logic_vector`
   - Generated vector `logic signed` internal signal declarations as VHDL
     `signed`
   - Generated signed vector direct-root ports as VHDL `signed`
   - Same-width signed vector addition/subtraction RHS assignments for signed
     targets and operands
   - Same-width addition, subtraction, multiplication, division, modulo, and
     XOR RHS chains in the generated direct combinational mux shape
   - Generic-bearing direct-root module headers emitted by the generated
     SystemVerilog `#(...)` parameter-block shape
   - Generated sized-literal generic defaults such as `1'b1` and `1'b0`
     mapped to typed VHDL scalar/vector generics

4. **Intentionally deferred:**
   - Composition-top VHDL
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
  vector addition/subtraction RHS assignments, plus direct-root parameter blocks as VHDL
  generics, including integer expression defaults and typed scalar/vector
  sized-literal defaults.
- Active follow-up: select the next exact backend/API/public-export edge under
  `BACKEND-API-VALIDATION-FRONTIER.59`; signed arithmetic operators beyond
  same-width vector addition/subtraction remain separate future edges.
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
  generic-bearing direct-root module headers, one-bit `std_logic` and
  multi-bit `std_logic_vector` sized-literal generic defaults,
  mismatched-width arithmetic-expression fail-closed diagnostics, and
  aggregate-output plus composition/top VHDL fail-closed diagnostics.
- Add broader VHDL output to the regression corpus
- Ensure `--check --json` and `--emit-semantic-json` stay target-neutral
- Consider external VHDL validation via GHDL

## Non-goals for R14
- VHDL composition-top generation (deferred until composition VHDL lane)
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
