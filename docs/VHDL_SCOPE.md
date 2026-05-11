# VHDL Backend Scope

This document defines the scoped R14 VHDL backend plan for FSMGen.

## Status
- The CLI currently accepts `--language vhdl` and routes to `FSM::Pipeline::HDLGenerator`.
- `FSM::HDL::FlattenedDT::generate_vhdl()` exists but intentionally dies with:
  "VHDL backend is not implemented yet."
- This document defines the first honest implementation lane.

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
   - Convert to VHDL through a new `FSM::Backend::VHDL` module
   - Follow the same `convert_systemverilog_to_*` pattern as Verilog

3. **Supported constructs in the first lane:**
   - Module declaration with port list
   - `std_logic` / `std_logic_vector` port and signal types
   - Synchronous processes with clock and async reset
   - Combinational `when`/`else` assignments (mapped from SV `always_comb`)
   - State encoding as VHDL enumerated type or constant declarations
   - Basic signal assignments

4. **Intentionally deferred:**
   - Composition-top VHDL
   - VHDL packages (SV packages → VHDL packages)
   - Intermediate signal factorization (needs VHDL signal declaration semantics)
   - Multi-clock domains
   - VHDL-specific testbenches
   - VHDL external validation (GHDL)
   - Verilator/Yosys VHDL path

## Implementation plan

### Phase 1: Conversion scaffolding (R14.1)
- Create `perl/FSM/Backend/VHDL.pm` with the conversion entrypoint
- Wire into `FSM::HDL::FlattenedDT::generate_vhdl()`
- First deliverable: generate structurally valid VHDL that synthesizes
- Reuse the existing SystemVerilog generation path as input

### Phase 2: Semantic conversion (R14.2)
- SystemVerilog `always_ff` → VHDL synchronous process
- SystemVerilog `always_comb` → VHDL combinational process
- Signal/port type mapping: `logic` → `std_logic`, `logic [N:0]` → `std_logic_vector(N downto 0)`
- Module declaration conversion
- Reset polarity handling

### Phase 3: Regression and hardening (R14.3)
- Add VHDL output to the regression corpus
- Ensure `--check --json` and `--emit-semantic-json` work for VHDL target
- Add focused VHDL generation tests
- Consider external VHDL validation via GHDL

## Non-goals for R14
- VHDL composition-top generation (deferred until composition VHDL lane)
- Full VHDL structural feature parity with SystemVerilog
- VHDL-2008 or VHDL-2019 specific features in the first lane
- Mixed-language (SV+VHDL) co-simulation

## Relationship to existing Verilog path
The existing Verilog conversion path (`FSM::Backend::VerilogFamily`) provides
the architectural pattern:
1. Generate SystemVerilog through the normal direct backend
2. Convert to target language through a dedicated converter module
3. The converter owns syntax/semantic mapping, not pipeline orchestration

The VHDL backend should follow this same pattern: thin converter module,
SV-first generation, no duplication of the AST/pipeline layer.
