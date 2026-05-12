# Intent Scheduling Format (`.isf`)

The Intent Scheduling Format abstracts cycle counting away from the author.
You describe **what** happens — the compiler infers **when** and produces
explicit cycle-accurate `.fsm`.

```text
.isf → LoweringIR → Emitter::FSM → .fsm → SystemVerilog / Verilog
                    → Emitter::JSON → Schedule Report
```

## Design Principles

- **No register vocabulary**. You work with variables, ports, and expressions.
  The scheduler decides storage class (wire, flop, counter).
- **No magic merging**. One `(drive ...)` = one cycle. Timing is predictable.
- **Handshake-free activation**. `(on port)` fires when the port is true AND
  the actor can accept. The ready side (`can_accept`) is implicit.
- **Variables are first-class**. `(sample ...)`, `(update ...)` — just like
  programming language variables. The scheduler handles persistence.
- **Compile-time issues are explicit**. Parser and lowering failures are raised,
  and the schedule report carries a `compile_issues` field. Broader conflict,
  deadlock, and resource diagnostics are still being expanded.

## Quick Example

```lisp
(actor apb_requester
  (clock clk)
  (reset (rst_n async active_low))
  (watchdog 65536)

  (interface
    (input  start)
    (output done)
    (input  req_addr  (width 32))
    (output PADDR   (width 32))
    (input  PREADY))

  (drive (psel val)   (PSEL val))
  (drive (penable val) (PENABLE val))

  (transaction apb_transfer
    (on start
      (sample req_addr as addr))
    (drive setup_phase)
    (drive penable 1)
    (await PREADY)
    (complete done)
    (latency (min 2) (max 16))))
```

## Pipeline

```
ISF Source (.isf)
    │
    ▼
FSM::Adapter::ISF     ← Lispish parser
    │
    ▼
FSM::Scheduler::ISF::LoweringIR   ← typed IR
    │
    ├──► Emitter::FSM   → .fsm text → fsmgen → SystemVerilog
    └──► Emitter::JSON  → schedule report
```

The schedule report is generated from the same IR as the `.fsm` text. The
current APB report shape is regression-covered. The bounded downstream-facing
ISF API contract is advertised through `--capability-manifest` at
`embedding.isf_public_interface` and described in
[docs/ISF_PUBLIC_INTERFACE_CONTRACT.md](../../ISF_PUBLIC_INTERFACE_CONTRACT.md).
That contract is live documentation: it evolves in the same slice as public ISF
parser, scheduler, CLI, lower-result, or schedule-report changes. The public
adapter and scheduler constructors reject malformed option lists and unsupported
option names, require exact class invocants, and currently accept only `debug`.
The parser facade validates method receivers before private internals are used,
then validates
`parse_file(...)` and `parse_source(...)` argument counts and defined-scalar
shape before private parsing begins; `parse_file(...)` also requires a readable
`.isf` file path. The scheduler facade validates method receivers and the
public actor shell before calling private LoweringIR, and the manifest
advertises the required `actor_name`, `transactions`, and `interface` shell keys
without freezing the full raw actor hash. The facade-shape metadata for those
receiver, argument, path, and actor-shell boundaries is audited as exact across
direct and manifest views. Assigned scheduler counters in the
`*_wd`, `*_cc`, and `*_cnt` naming families are reported as `counter` storage
with the width inferred by the lowering IR. The advertised contract object is
JSON-round-trip audited so downstream tooling can consume the manifest metadata
as portable discovery data, and defensive-copy audited so caller mutation does
not pollute later contract builds. Its identity and stability metadata plus its
top-level discovery list are audited as exact across direct and manifest views,
and its advertised
entrypoint, CLI option, method-name, and constructor-option lists are audited as
exact and duplicate-free. Its lower-result and schedule-report discovery
metadata are audited as exact, as is the downstream guidance list that explains
the current bounded-public stance. Its `tested_by` provenance list is also
audited as exact repo-local metadata. CLI success-shape metadata is audited for
the schedule JSON, `--outdir`, and plain HDL-generation paths. Both
capability-manifest CLI spellings are audited to emit the same ISF contract
payload. The current APB schedule report is also checked against the advertised
public key families, and successful reports advertise and keep an empty
`compile_issues` array. The lower-result `files` map is checked for both
single-file and multi-file lowering. The in-memory `parse_source(...)` facade
is also checked against `parse_file(...)` on a real fixture. APB DT block order
is locked across generated `.fsm` text and schedule-report `dt_blocks` so
hash-backed drive definitions do not create review-artifact churn; the manifest
also advertises the DT ordering policy, and that scheduled-artifact ordering
metadata is audited as exact. DT timing remains assignment-family driven:
`=` is combinational, while `<-` and `<=` are sequential whether they appear in
state or non-state DT blocks; the manifest advertises those operator families
through `dt_assignment_operator_family_map`. Schedule-report `dt_blocks`
`assignments` values are assignment counts, not payload lists, and the manifest
advertises that shape through `schedule_report_dt_assignments_shape`.
Inferred-storage `kind` values are `counter` or `register`, and optional
positive integer `width` values currently belong to inferred counters.
Transaction summaries expose emitted scheduled-state names in `states`, and
`count` equals that array length. Reset summaries advertise `async`/`sync`
kind values and `active_high`/`active_low` polarity values. Interface count
summaries count input and output ports by direction, and `state_count` counts
scheduled `.fsm` state blocks in the parent report scope. Report `source` and
`scheduled_fsm` are actor-derived basenames, `clock` is the actor clock signal,
and `watchdog` is scalar when configured or null when omitted. The ISF
live-document path list is
audited across direct and manifest views so recovery pointers stay repo-local
and present. The public `--emit-schedule-json` path is audited to emit the same
report as the in-process scheduler with clean stderr. The public `--outdir`
path is audited to write multi-file scheduled `.fsm` artifacts matching the
in-process lower-result file map. Multi-file schedule reports are currently
parent-scoped, and that scope is advertised in the manifest. The plain
`file.isf` CLI path is audited to reach generated HDL with clean stderr,
including when the advertised `--strict` flag is present. Transaction summaries
include the generated state families used by the current scheduler, including
control-flow and data-operation states.

## Current Limitations

- `(do ...)` and `(spawn ...)` bind named start/done signals in scheduled
  `.fsm`; composition-top instantiation and spawn parameter binding remain
  deferred.
- `(resources ...)` and `(priority ...)` are parsed but not enforced as
  arbitration policy.
- `(shift_right ...)` field-width parameter is not yet configurable.
- `(extract ...)` field slice ranges are placeholder names, not exact slices.
- `(contract ...)` temporal assertions are not implemented.
