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
- Composition VHDL, aggregate VHDL, broad expression parity, scalar
  division/modulo and broader scalar arithmetic, GHDL validation, packages,
  multi-clock domains, and full feature parity remain deferred.
- Scalar division/modulo RHS forms such as `A / B` and `A % B` are locked as
  explicit fail-closed direct VHDL boundaries by focused pipeline and facade
  coverage.
- Aggregate-output roots are locked as explicit fail-closed direct VHDL
  boundaries by focused pipeline and facade coverage.

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
  direct-root parameter blocks as VHDL generics, including integer expression
  defaults and typed scalar/vector sized-literal defaults.
- Remaining semantic conversion work still belongs to exact future VHDL leaves.

### Phase 3: Regression and hardening (R14.3)
- Focused direct VHDL generation tests cover pipeline and CLI routing,
  sync/async reset processes, delayed-pulse clock branches, concat lowering,
  scalar addition/subtraction/multiplication chains, same-width
  addition/subtraction/multiplication/division/modulo/XOR chain lowering,
  generic-bearing direct-root module headers, one-bit `std_logic` and
  multi-bit `std_logic_vector` sized-literal generic defaults,
  mismatched-width arithmetic-expression fail-closed diagnostics, and
  aggregate-output fail-closed diagnostics.
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
