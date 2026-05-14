# Intent Scheduling Format (`.isf`)

The Intent Scheduling Format abstracts cycle counting away from the author.
You describe **what** happens — the compiler infers **when** and produces
explicit cycle-accurate `.fsm`.

```text
IAL1 .isf → LoweringIR → Emitter::FSM → IAL0 .fsm → SystemVerilog / Verilog
                    → Emitter::JSON → Schedule Report
```

## Intent Abstraction Layers

FSMGen treats explicit `.fsm` as **Intent Abstraction Layer 0** (`IAL0`).
Layer 0 is still an abstraction above HDL, but it is the cycle-authored review
artifact: DTs, assignment operators, state and non-state regions, mux-selector
semantics, and exact runtime behavior are visible there.

Current `.isf` constructs form **Intent Abstraction Layer 1** (`IAL1`). Layer 1
describes scheduling intent: transactions, rules, drives, samples, waits,
repeats, child calls, spawned child activation, and constraints. The Layer 1
contract is that lowering produces reviewable Layer 0 `.fsm` unless a targeted
diagnostic rejects the construct first.

Higher layers are intentionally reserved, not assumed. A future `IAL2` would
need its own semantic level, such as reusable protocol-level intent objects
(`APB read transaction`, `AXI burst`, and similar) or platform/resource mapping
decisions above individual transactions. It should not be introduced for
aliases, macros, syntax sugar, or wrappers that have no distinct runtime model.
Any future layer must lower through the same chain: clear source semantics,
clear lower-layer mapping, and clear runtime behavior.

## Design Principles

- **No register vocabulary**. You work with variables, ports, and expressions.
  The scheduler decides storage class (wire, flop, counter).
- **No magic merging**. One `(drive ...)` = one cycle. Timing is predictable.
- **Handshake-free activation**. `(on port)` fires when the port is true AND
  the actor can accept. The ready side (`can_accept`) is implicit.
- **Variables are first-class**. `(sample ...)`, `(update ...)` — just like
  programming language variables. The scheduler handles persistence.
- **Every construct has semantics**. A construct is not considered shipped just
  because the parser accepts it. It needs a documented lowering path into
  scheduled `.fsm`, a runtime meaning in terms of cycles, activation, storage,
  and conflicts, targeted diagnostics for unsupported forms, and regression
  coverage for the accepted behavior.
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
plus their public value shapes without freezing the full raw actor hash. The
current parser handoff also advertises a bounded `interface` subshape:
`inputs` and `outputs` arrays whose port entries expose unique non-empty scalar
`name` and positive integer `width`, with omitted source widths normalized to
`1`. Duplicate port names across either direction are rejected before
actor-shell return. It also
advertises a bounded transaction-entry shell: `transactions` entries expose
unique non-empty scalar `name` and a `clauses` array while the clause payload
contents remain private scheduler input. Duplicate transaction names are
rejected before actor-shell return. It also advertises `actor_name` as the
non-empty scalar identifier preserved from the ISF actor root. Current actor timing
handoff metadata is bounded too: `clock` is scalar when configured, `reset` is
null when omitted or a scalar-field hash, and `watchdog` is null when omitted
or a positive integer. Rule entries are bounded as unique non-empty scalar
`name`, optional `when`, and `actions` array shells while rule payload contents
remain private scheduler input. Duplicate rule names are rejected before
actor-shell return. Drive definitions are bounded as a drive-name-keyed hash whose
entries carry `params` and `body` arrays while drive body payload contents
remain private scheduler input. Duplicate drive names are rejected before
actor-shell return instead of overwriting an earlier drive body. Parameterized
drive declarations also reject duplicate parameter names before actor-shell
return. The
facade-shape metadata for those
receiver, argument, path, and actor-shell boundaries is audited as exact across
direct and manifest views, including bounded scalar diagnostics for public
facade boundary failures. The manifest also advertises the public facade
return containers: parser facades return scheduler-consumable actor hashes,
`lower(...)` returns the bounded lower-result hash, and `report(...)` returns
schedule-report JSON. Assigned scheduler counters in the
`*_wd`, `*_cc`, and `*_cnt` naming families are reported as `counter` storage
with the width inferred by the lowering IR. The advertised contract object is
JSON-round-trip audited so downstream tooling can consume the manifest metadata
as portable discovery data, and defensive-copy audited so caller mutation does
not pollute later contract builds. It is live, not a frozen API schema; exact
audits describe the currently advertised surface. Its identity and stability
metadata plus its
top-level discovery list are audited as exact across direct and manifest views,
and its advertised
entrypoint, CLI option, method-name, and constructor-option lists are audited as
exact and duplicate-free. Its lower-result and schedule-report discovery
metadata are audited as exact, as is the downstream guidance list that explains
the current bounded-public stance. Its `tested_by` provenance list is also
audited as exact repo-local metadata. CLI success-shape metadata is audited for
the schedule JSON, `--outdir`, plain HDL-generation, and accepted strict
HDL-generation paths. Both
capability-manifest CLI spellings are audited to emit the same ISF contract
payload. The current APB schedule report is also checked against the advertised
public key families, and successful reports advertise and keep an empty
`compile_issues` array when no nonfatal issues exist. Nonfatal conflict issues
now project into `compile_issues` as bounded objects with stable code/severity,
target/domain, `proof_status`, reason text, and capped source summaries.
Accepted fan-in groups now project as bounded `compatible_fanin_groups`
entries. Raw assignment provenance and activation proof internals remain
private. The lower-result `files` map is checked for both
single-file and multi-file lowering, including scheduled `.fsm` basename keys
and matching scheduled-text roots. The in-memory `parse_source(...)` facade is
also checked against `parse_file(...)` on a real fixture. APB DT block order
is locked across generated `.fsm` text and schedule-report `dt_blocks` so
hash-backed drive definitions do not create review-artifact churn; the manifest
also advertises the DT ordering policy, and that scheduled-artifact ordering
metadata is audited as exact. Rule-trigger fan-in schedule reports are also
covered so generated `rule_trigger_fanin` DTs and one-bit trigger-source
storage stay visible to downstream consumers. DT selector logic remains
combinational; assignment families decide the selected target behavior:
`=` drives combinational mux outputs, `<-` and `<=` drive sequential/flopped
targets, and `<1` requests a one-cycle delayed pulse whether they appear in
state or non-state DT blocks. The manifest advertises those operator families
through `dt_assignment_operator_family_map`.
Rule guards lower through non-state DT DTE headers in scheduled `.fsm` review
artifacts, so the guard activates the whole rule DT once instead of being
repeated on every action.
Schedule-report `dt_blocks`
`assignments` values are assignment counts, not payload lists, and the manifest
advertises that shape through `schedule_report_dt_assignments_shape`.
Schedule-report DT `kind` values are currently `drive`, `latency_counter`,
`rule`, and `rule_trigger_fanin`, and the manifest advertises that family
through `schedule_report_dt_kind_values`.
Inferred-storage `kind` values are `counter` or `register`, and optional
positive integer `width` values currently belong to inferred counters.
Transaction summaries expose emitted scheduled-state names in `states`, and
`count` equals that array length; transaction summaries are sorted lexically by
name while each `states` array keeps scheduled `.fsm` state emission order.
Reset summaries advertise `async`/`sync`
kind values and `active_high`/`active_low` polarity values; omitted resets are
reported as JSON null. Interface count
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

The consolidated backlog for deferred user-visible work is
[Feature Backlog](14-feature-backlog.md). The ISF-specific current
limitations are:

- `(do ...)` and `(spawn ...)` targets must resolve to declared same-actor
  transactions before scheduled `.fsm` emission. They bind named start/done
  signals in scheduled `.fsm`. Spawn parameter declaration, validation, child
  `+params` emission, per-instance override preservation, and generated-top
  application are shipped for the spawn-only `(params ...)` surface. Broader
  symbolic parameter values and richer generated-child surfaces remain
  backlog work.
- `(resources ...)` is structurally validated by the parser and now has one
  enforced resource kind: `rule_slot`, a one-cycle mutual-exclusion slot for
  rule users under the `priority` arbiter. Future kinds such as
  `output_bundle`, `interface_bundle`, `named_drive`, `transaction_start`,
  `child_instance`, and `storage_port` remain backlog until their lowering
  contracts are explicit. The accepted `round_robin` value remains parser
  metadata until round-robin lowering ships. `(priority ...)` is structurally
  validated and currently enforced for same-target rule/rule data conflicts
  and priority-arbitrated `rule_slot` resources; broader transaction and
  resource arbitration remains deferred.
- Deprecated `(handshake name (valid signal) (ready signal))` metadata is
  structurally validated and then ignored; direct `(on port ...)` activation
  plus generated `can_accept` is the current model.
- Actor-level `(phase ...)` and `(stage ...)` metadata is structurally
  validated and parser-carried only. Transaction `(phase ...)` lowers as a
  pass-through marker state; transaction `(stage ...)` fails closed during
  lowering until valid/ready pipeline-stage generation is implemented.
- Unsupported transaction clause heads now fail closed during lowering instead
  of being silently dropped. This includes the removed `(assign ...)` keyword
  and unsupported nested body forms in `when`, `switch`, and `repeat`.
- Rule actions are structurally validated as `(port value)`,
  `(trigger transaction)`, or `(priority over other_rule)`. Expression-valued
  rule assignments remain deferred. Rule trigger targets must resolve to a
  declared transaction in the same actor before parser handoff returns.
- `(shift_right ...)` accepts an explicit `(width N)` option when the shifted
  register width is not declared elsewhere; values with no known or explicit
  width still use the placeholder `WIDTH` expression.
- `(extract ...)` accepts an ordered `(widths N...)` option when field widths
  are not declared elsewhere; values with no known or explicit widths still
  use placeholder slice bounds.
- `(contract ...)` temporal assertions are not implemented; authored
  transaction contract clauses currently fail closed during lowering instead of
  being dropped from the scheduled `.fsm`.
