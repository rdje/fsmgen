---
id: isf-direct-controller-runtime-boundary
title: Direct transaction runtime depends on declaration order until controller repair
answers:
  - "why does only the first direct ISF transaction run?"
  - "why can a plain local do stall despite strict source admission?"
  - "can public IAL0 decision trees express independent transaction controllers?"
  - "what is the runtime evidence for the direct controller repair?"
date: 2026-09-27
status: current
tags: [isf, controllers, transactions, local-do, runtime, concurrency]
evidence: docs/audits/direct-controller-contract-20260927.json; perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Scheduler/ISF/Emitter/FSM.pm; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: Materialize the tracked audit sources and testbenches into a repository-local workspace; strict-check/generate with bin/fsmgen, then run qualified Verilator under scripts/run_with_ram_guard.sh. Baselines are expected failures; reference_dt cases are hand-authored feasibility controls.
---

_build_parent_ir concatenates direct transaction states. _link_states links each
transaction back to its own entry, while Emitter::FSM emits all loops inside
one encoded FSM root. The first declared component is the only initial one.
The tracked audit has no formal-port collisions: simultaneous short and long
transactions strict-check and compile, but only the first executes. Reversing
their declaration order reverses the reachable transaction.

Plain local do is independently reproduced. An untriggered callee first in the
source executes repeatedly without its caller; caller-first stalls awaiting
an unreachable callee. _wire_do_children does not create an independent state
register and only rewires an existing idle state. Changing formal-port names
cannot repair this control-flow defect.

The public IAL0 reference uses private controller registers and guarded DT
bodies while keeping shared actor registers in the same module. It passes
concurrent short/long progress, separate repeated triggers and reset. The
local-call reference additionally retains start history so a held caller
request cannot execute the callee again after its delayed completion. It
passes repeated call counts, idle hold and reset during a partial call.
These are authored feasibility references, not production ISF lowering.

Before adoption, the controller contract must cover local entry injection,
held-start behavior, caller payload capture/completion copy, nested calls,
scoped identities, source/report provenance and shared-write admission.
Existing rule/transaction priority is assignment-local; it does not define
transaction/transaction arbitration or denied progress. The repair may not
silently serialize independent work, duplicate actor registers or invent a
priority policy. .32.1.3.3.1.2.2 owns adoption after rationale rollover .51;
.32.1.3.3.1.3 owns split implementation and qualification.

Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.2.1.
