---
id: isf-generated-child-output-read-preparation
title: Detached child output reads use private typed aliases and emitted operand roles
answers:
  - "how are generated child actor output reads prepared?"
  - "can actor outputs named start or done preserve child handshakes?"
  - "is the generated output read plan connected to production?"
  - "what prerequisites precede generated output read integration?"
date: 2026-10-02
status: current
tags: [isf, generated, output, reads, scope, preparation]
evidence: >-
  perl/FSM/Scheduler/ISF/ChildOutputReads.pm;
  perl/FSM/Scheduler/ISF/LoweringIR.pm;
  t/2039-isf-child-output-read-preparation.t;
  docs/audits/record-output-owner-read-preparation-20261002/scope.txt;
  docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/2039-isf-child-output-read-preparation.t
---

At ingress commit `851358dd6dca12ba69a2d2491bc70d766dd4dde1`, actual
generated readers lack an owner-output input. Record outputs named `start`
or `done` also leave inherited record type references on canonical one-bit
child handshake ports. The retained source/IR probes reproduce both causes.
Git pickaxe roots that child type inheritance in
`6dce0d9a34acaa813fa1ef1bbc791121674e074f` (scalar type-alias delivery);
record authoring later exposes the same inherited handshake namespace.

SEM `.60.4.3.3.5.2.1.1` adds detached preparation, without a production call.
`ChildOutputReads::plan` receives the actual source actor/transaction and
child IR. `LoweringIR::child_output_read_scope` supplies the same canonical
static namespace as formal lowering, with actual source declaration products.
Inconsistent static/type products, inherited read types or handshake history
refuse. Source/IR copies preserve first-touch caller JSON kinds on all paths.
The independent archive check caught numeric kind loss from the initial
`Storable::dclone` implementation, missed by an expected product using the same
copier. Plain recursive value copying preserves original scalar flags; the
test oracle snapshots serialized originals and checks untouched counters
separately. Initial numeric-kind failures were a real preparation defect. The
failed uncommitted archive and its false-positive green receipts are retained
as drafts, and an isolated original-copy mutant must fail the corrected test.

The walk follows actual FSM emitter read slots and precedence. Write targets,
state identities, diagnostic strings, ignored entry activation and generated
start/history operands stay intact. Real scalar/member/slice/guard/branch/DT
reads use allocated private input names. Explicit source formals and parameters
mask outer outputs; imported/local enum and constant identities stay static.
Source locals cannot shadow actor interface names under the existing gate.
The allocator reserves retained IR and complete source input/storage/type names,
including unused declarations. Recursive types and sample aliases survive.

Unused inherited owner metadata also leaves the child handshake namespace.
Ordinary data-writer declarations remain for their separate handoff owner;
data writers colliding with handshake names refuse. No parent port, DT,
register, reset, payload capture or clock edge is introduced by this plan.
Actual prepared data carriers pass standalone strict checks. The intentionally
retained scalar `const_3bx01` control still fails with false operand `x01`;
it is an owned prerequisite, not a successful literal/runtime claim.

Full independent expected products, literal recursive type facts and emitter
precedence fixtures re-derive the plan. Hostile history/port/entry/path/type/
static-scope/type-definition/prepared-state corruptions refuse without caller
mutation. Sealed full sources/products/recipes/receipts and the permanent test
retain falsification and durability; transport parity alone is not signoff.

P2 `.2.1.3` owns first-`when` activation action loss, traced to
`_ir_when_activation` retaining only samples. P2 `.2.1.4` owns the false `x01`
pre-generation operand diagnosis. Both precede production read integration
`.2.1.2`. Owner writer handoffs and complete physical mapping/public admission
remain open. No output execution, arbitration, field writers or X/Z behavior
is established here; no HDL compiler/analyzer/simulator is invoked.
