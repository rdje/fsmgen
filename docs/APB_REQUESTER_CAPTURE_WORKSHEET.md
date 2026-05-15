# APB Requester — Intent Capture Worksheet

This is the first concrete R14 protocol intent-capture worksheet, following the
method established in [docs/INTENT_CAPTURE_AXI_CASE_STUDY.md](INTENT_CAPTURE_AXI_CASE_STUDY.md).

The emitted `.fsm` artifact is [fsm/apb_requester.fsm](../fsm/apb_requester.fsm),
which serves as the seed corpus asset for this capture.

## Stage 0: Source normalization

### Source document
- AMBA APB Protocol Specification (ARM IHI 0024)
- The APB protocol is significantly simpler than AXI: no pipelining, no
  outstanding transactions, no burst support, no narrow transfers.
- For this first worksheet, the protocol is simple enough that the existing
  FSMGen APB requester `.fsm` already captures the essential behavior.

### Source scope
- Included: APB master/requester interface, single-transfer read/write,
  PSLVERR handling, idle/wait states.
- Deferred: APB3/APB4 extended features, multi-peripheral arbitration,
  protection signals (PPROT), strobes (PSTRB).

## Stage 1: Protocol dossier

### Protocol identity
- Name: AMBA APB (Advanced Peripheral Bus)
- Version: APB2 / APB3 baseline
- Type: Simple non-pipelined peripheral bus
- Key characteristic: one transfer at a time, no bursts, no pipelining

### Core signal set (requester perspective)
| Signal    | Direction | Width | Role |
|-----------|-----------|-------|------|
| PCLK      | Input     | 1     | Clock |
| PRESETn   | Input     | 1     | Async reset, active low |
| PADDR     | Output    | 32    | Address |
| PWRITE    | Output    | 1     | Write (1) / Read (0) |
| PWDATA    | Output    | 32    | Write data |
| PSEL      | Output    | 1     | Peripheral select |
| PENABLE   | Output    | 1     | Enable (second cycle of transfer) |
| PREADY    | Input     | 1     | Peripheral ready |
| PRDATA    | Input     | 32    | Read data |
| PSLVERR   | Input     | 1     | Transfer error |

### Transfer protocol
1. **Setup phase (PSEL=1, PENABLE=0):** address, write/data, and direction
   are presented. No peripheral response expected.
2. **Access phase (PSEL=1, PENABLE=1):** peripheral must respond with
   PREADY=1 to complete the transfer. PSLVERR indicates error.
3. After PREADY=1, the transfer completes and the requester may start a new
   one or return to idle.

## Stage 2: Actor catalog

### Identified actors
1. **APB Requester** — initiator that drives transfers to one or more
   peripherals. Core actor for this capture.
2. **APB Completer** — peripheral that responds to transfers. Deferred to
   a separate capture worksheet.
3. **APB Interconnect** — address decoding and PSEL generation. Deferred;
   the requester directly drives PSEL in simple single-peripheral setups.

### Actor boundary rationale
- Requester and completer are separated because they have opposite
  signal directions and independent state machines.
- The requester is the natural first actor since it initiates transfers.

## Stage 3: Actor sheet — APB Requester

### Interface
#### APB bus signals (connected to peripheral)
- Outputs: PADDR[31:0], PWRITE, PWDATA[31:0], PSEL, PENABLE
- Inputs: PREADY, PRDATA[31:0], PSLVERR

#### Local side signals (connected to user logic)
- Inputs: `start`, `req_write`, `req_addr[31:0]`, `req_wdata[31:0]`
- Outputs: `done`, `last_read_data[31:0]`, `last_error`

### Phase model
1. **IDLE** — waiting for `start` request. PSEL=0, PENABLE=0, done=0.
2. **SETUP** — first cycle after `start`. PSEL=1, PENABLE=0. Address and
   write data are driven.
3. **ACCESS** — second cycle. PSEL=1, PENABLE=1. Waiting for PREADY.
4. **DONE** — transfer completed. Capture PRDATA or PSLVERR. Assert `done`.
   Return to IDLE (or stay in DONE until start deasserts, then IDLE).

### Persistent state
- `addr_q` — latched address for the current transfer
- `write_q` — latched write/read direction
- `wdata_q` — latched write data
- `last_error` — latched PSLVERR from last transfer
- `last_read_data` — latched PRDATA from last read transfer

### Phase transitions
```
IDLE  --[start]---------> SETUP
SETUP --[always]--------> ACCESS
ACCESS--[PREADY]--------> DONE
DONE  --[!start]--------> IDLE
```

## Stage 4: Contracts, invariants, assertions

### Safety invariants
- **S1:** PSEL must be 1 before PENABLE can be 1 (setup before access).
- **S2:** PENABLE must only be 1 when PSEL is 1 (no orphaned enables).
- **S3:** PADDR, PWRITE, PWDATA must be stable during SETUP and ACCESS
  phases.
- **S4:** `last_error` must only be asserted after a completed transfer
  where PSLVERR was sampled high.
- **S5:** `last_read_data` must only be updated on read transfers.

### Stability invariants
- **ST1:** During IDLE, all APB outputs are driven to inactive values
  (PSEL=0, PENABLE=0).
- **ST2:** `done` asserts for exactly one cycle per completed transfer.

### Causality invariants
- **C1:** PREADY is sampled only during ACCESS phase.
- **C2:** PRDATA is valid only when PREADY=1 during ACCESS phase and
  PWRITE=0 (read transfer).

## Stage 5: Abstraction and boundedness log

### Explicit abstractions
| Abstraction | Scope | Fidelity impact |
|-------------|-------|-----------------|
| `single_peripheral_first_pass` | Only one PSEL line, driven directly | Real systems need address decoding to generate PSEL |
| `no_wait_state_handling` | PREADY is sampled but no explicit timeout | Real peripherals may stall indefinitely |
| `no_protection_first_pass` | PPROT not modeled | Memory type/security attributes ignored |
| `no_strobes_first_pass` | PSTRB not modeled | Byte-level write enables not captured |
| `blocking_transfer_model` | One transfer at a time, no queuing | Real initiators may pipeline requests |

### Fidelity notes
- The first-pass model captures the core APB transfer protocol correctly.
- All four abstractions above are explicitly documented and can be lifted
  in later refinement passes.
- No legal APB behavior is silently dropped — the abstractions are
  narrowing of optional/advanced features, not violations.

## Stage 6: Decomposition

### Single-actor phase
- This first capture is a single leaf actor (APB requester).
- No composition or hierarchy is needed at this stage.
- The existing `fsm/apb_requester.fsm` is the emitted artifact.

### Future decomposition
- When the APB completer and interconnect actors are captured, they will
  compose through `?top` and `?wiring` as demonstrated by the existing
  `fsm/apb_tb.fsm` testbench harness.

## Stage 7: .fsm emission

### Emitted artifact
- [fsm/apb_requester.fsm](../fsm/apb_requester.fsm) — existing seed corpus
  asset. Verified through strict-mode pipeline and regression tests.

### Validation
- Strict-mode parse and SystemVerilog generation passes.
- Phase model maps directly to FSM states: IDLE → SETUP → ACCESS → DONE.
- Signal assignments match the interface contract.
- Persistent state matches the actor sheet.

## Stage 8: Verification assets

### Existing coverage
- `fsm/apb_tb.fsm` — composition testbench exercising requester+completer
  together.
- Regression corpus entry: `apb_requester` classified as `supported_smoke`.

### Future verification
- Scenario: read transfer with PSLVERR
- Scenario: back-to-back writes
- Scenario: PREADY stall in ACCESS phase
- Assertion-based: PSEL→PENABLE ordering, done pulse width

## Stage 9: Capture report

### Confidence assessment
| Category | Assessment |
|----------|-----------|
| Core transfer protocol | **Confident** — matches APB spec exactly |
| Phase model | **Confident** — IDLE/SETUP/ACCESS/DONE is the canonical APB sequence |
| Signal mapping | **Confident** — all APB signals mapped to .fsm ports |
| Error handling | **Confident** — PSLVERR captured and reported |
| Multi-peripheral | **Heuristic inference** — deferred, requires address decoding |
| Wait states | **Explicit abstraction** — PREADY sampled but no timeout |
| Protection | **Explicit abstraction** — PPROT not modeled |
| Strobes | **Explicit abstraction** — PSTRB not modeled |

### Unresolved
- None at this fidelity level. All current limitations are explicit
  abstractions, not ambiguities.

### Relationship to AXI case study
- Same working method: actor-first, phases before states, explicit
  abstraction logging.
- APB is intentionally chosen as the first R14 capture because it is
  dramatically simpler than AXI — validating the method on a protocol
  where the answer is already known and regression-backed.
- The AXI case study provided the 14-stage method; this APB worksheet
  applies stages 0–9 to a concrete, simpler target.

## Next capture targets (future R14 slices)
1. APB Completer — follow same worksheet, existing `fsm/apb_completer.fsm`
2. APB Testbench — composition harness, existing `fsm/apb_tb.fsm`
3. AMBA Requester — more complex, burst-capable, existing
   `fsm/amba_requester.fsm`
4. I2C Controller — new capture, no existing .fsm
5. UART — new capture, validates method on non-bus protocol
