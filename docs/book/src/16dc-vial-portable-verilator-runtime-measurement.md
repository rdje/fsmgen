# Portable Verilator Runtime Measurement

Portable-SystemVerilog runtime measurement is the active next step after the
[structural backend-emission matrix](16db-vial-structural-backend-emission-matrix.md).
It is not complete yet. The current durable boundary constructs canonical
runtime-stream inputs and records expected compile, run, trace, and result
contracts, but it deliberately does not manufacture runtime activity or start
Verilator.

This “execution” means external execution of generated portable SystemVerilog
with the already qualified Verilator profile. It is not IASIM execution and it
does not change IASIM's separately owned reference-semantics role.

## Why contract selection comes first

The shipped public Runner is an atomic transaction: it validates the exact
tool, materializes inputs, compiles, runs, validates the trace, produces the
normalized result, assembles artifacts, and removes its private stage. That is
the right public behavior. Measurement, however, must report those operations
as distinct stages while preserving one compiled executable and one coherent
evidence chain across isolated measurement workers.

The runtime-stream family also selects semantic activity counts rather than a
larger source file. A production-grade implementation therefore needs a
canonical runtime schedule whose identity is carried by emission, trace, and
result evidence. Editing generated source text after emission, padding output,
truncating a trace, or introducing a second tool runner would make the measured
work differ from the qualified work and is forbidden.

The active selection leaf must close both contracts before implementation:

| Boundary | Required decision |
| --- | --- |
| runtime activity | how canonical semantic work reaches each selected candidate without falsifying the base execution plan |
| identity | how the schedule is bound into backend, trace, transcript, and result evidence |
| applicability | which reference, candidate, limit, and excess shapes may execute the tool and which reject earlier |
| stage state | what immutable repository-local evidence moves from prepare to compile, run, trace validation, and result production |
| reuse | how the public Runner and scale measurement invoke the same caller-sealed lifecycle |
| failure | how timeout, signal, capture limit, malformed state, collision, and cleanup remain atomic and diagnosable |

## Prerequisite scheduler repair

The first real reachability probe found a product defect before it found a
scale limit. A legal scenario can place a check-phase `expect` before a later
react-phase `scoreboard_expect`. ExecutionIR retains the authored successor
dependency and labels both eligible phases correctly, but the portable
SystemVerilog emitter currently calls root operations directly in authored
order. It can therefore emit check followed by react in the same logical
cycle, which the runtime trace validator correctly rejects.

The selected repair boundary is general and semantic:

- authored dependencies stay in order;
- operations already ordered within one phase keep their stable static ranks;
- a successor whose eligible phase is earlier than the completed predecessor
  advances to its first legal phase in the next logical cycle; and
- the backend must not sort operations, reject otherwise legal VIAL, rewrite
  source, invent trace timestamps, or recognize a scale-only fixture.

Task `.17.3.5.1.1` owns an executable RED/GREEN proof for that behavior before
runtime materialization selection resumes. Until it closes, the exact gate
record count, larger-level applicability, and staged lifecycle remain selected
work rather than shipped scale evidence.

## Intended ownership sequence

The task tree separates selection, runtime materialization, shared lifecycle,
per-profile measurement, and immutable matrix publication. Each unit must
commit cleanly before the next begins. The shared lifecycle remains private:
the existing public command and result contract must keep its successful bytes,
qualified commands, stable diagnostics, process-group termination, transcript
limits, and exact cleanup behavior.

Only the canonical portable profile may enter this lane. A validation run must
succeed before measured repetitions are retained. Gate and qualification
samples remain raw evidence under the common resource guard; limit or excess
shapes that are already authoritatively dominated must not invoke Verilator.
Every accepted measurement must independently close artifact/source-map,
command, tool, trace framing/order/count, semantic outcome, normalized result,
publication, and cleanup oracles.

No work in this lane implies full-SystemVerilog behavior, complete four-state
observation, UVM, VHDL or OSVVM execution, mixed-language behavior, general
cross-backend parity, a public performance budget, architecture capacity, a
reached boundary, or a new public API. Those claims require their own completed
evidence and owners.
