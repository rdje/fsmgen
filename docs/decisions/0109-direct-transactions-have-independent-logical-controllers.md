# 0109 — Direct transactions have independent logical controllers

Date: 2026-09-27
Type: ISF execution architecture
Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.2.2
Status: selected; implementation and qualification remain open

## Context

The retained direct-controller audit strict-admits and compiles independent
transactions but executes only the first declaration. Reversing declarations
reverses reachability. Plain local calls separately free-run an unguarded callee
or strand a waiting caller. Authored public IAL0 references demonstrate separate
control registers over shared actor storage, including repeated calls and reset.
Those references are feasibility evidence, not implemented ISF lowering.

The binding audit also distinguishes three timing classes. Generated `do`
inputs are live handoffs and correctly reject snapshot spelling. Local rule
payloads are snapshots, but at decision time the pulse-gated mux lost the value before
a delayed read. A request-gated target completes once and reads zero; changing
only the emitted mux default to its retained source restores the expected read.
An ungated rule target is a separate authored free-running control, not evidence
that rule fan-in implicitly installs an entry guard.

Evidence: `docs/audits/direct-controller-contract-20260927.json` and
`docs/audits/direct-controller-binding-timing-20260927.json`.

## Decision

Represent each retained transaction as an explicitly owned logical controller.
Its states, initial entry, transitions, local storage and activation effects
belong to that transaction and clock domain. Actor state retains its single
owner under decision `0107`; a controller does not acquire a private copy of
actor storage. Independent eligible transactions can make concurrent progress.
Declaration order cannot choose which transaction exists at runtime.

Use private per-controller state registers and guarded decision-tree bodies
through the existing public IAL0 carrier. This is an implementation-neutral
state/transition contract, not a new public language or backend bypass. A
single-controller optimization is acceptable only with proven semantic parity.
Generated selectors, widths and names are private, collision-safe and reset
under the owning module's qualified reset contract. Do not invent a reset for
an unqualified no-reset configuration.

Keep source-owned logical state identities in schedules and provenance.
Explicit ownership must survive expansion, call wiring, domain partitioning,
priority analysis and emission; do not recover it by splitting name prefixes.
Translate logical state predicates through the controller mapping, including
rule/transaction priority conditions. Preserve point-active assignments,
assertions, monitors, waits, loop edges and terminal holds. Raw textual
replacement across expressions, state names, type/member names and messages
is not an acceptable identity migration.

### Activation and binding boundaries

- Ordinary authored `on` guards remain entry conditions. Returning to entry
  reevaluates the guard; this repair does not convert every level condition
  into an edge trigger. Uncalled transactions without an entry guard retain
  their authored free-running semantics.
- A blocking local call owns its callee request entry. Install that entry if
  absent, as required for a callable body; preserve body ordering and entry
  sampling. One held request accepts one invocation. Fresh delayed completion
  releases the caller, and request release permits the next invocation.
  Reset aborts partial work and clears the activation history consistently.
- Local rule fan-in continues to produce the documented request signal.
  Preserve authored target guards, including `(on transaction_start)` and
  explicit qualifications; do not infer a new entry solely from a rule target.
- Local call input snapshots belong to the admitted invocation. Resolve caller
  operands in caller scope, capture at the qualified activation boundary, and
  retain values through waits. Callee formal names resolve in callee scope.
  Copy output bindings only under that invocation's completion condition.
- Rule payload snapshots must retain the accepted payload through the body.
  Preserve visibility on the acceptance edge as well as later reads; adding
  a register that delays an entry sample is not an equivalent repair. Source
  selection must follow actual admitted requests and existing resource grants.
- Generated `do` and spawn live handoffs stay live. Generated trigger payload
  retention keeps its separately qualified timing. Do not turn specialization
  parameters into mutable payload signals or silently convert timing classes.
- No request queue, stack, recursive invocation, simultaneous-caller ownership
  or busy-request payload replacement is inferred. Qualify repeated/nested
  acyclic calls, request release, early samples and reset explicitly. Unproved
  competing activation ownership needs a precise boundary and an owned repair.

### Shared-write admission

The old single encoded state variable cannot prove mutual exclusion between
independent controllers. Before enabling them, derive physical writer targets
from scoped identities and preserve source owner/state provenance. Classify
storage, actor outputs, partial/bank updates, named drives, binding copies and
generated handoffs under their real ownership rather than only bare LHS text.

Disjoint owners/targets need no arbitration. Preserve already qualified
completion-pulse fan-in and rule/resource behavior. Potentially overlapping
data writers require a sound existing compatibility or exclusion proof;
otherwise fail with an actionable conflict before claiming executable support.
Do not silently pick declaration order, suppress a controller, serialize work,
or treat parsed transaction/transaction priority as implemented arbitration.
Existing rule/transaction priority remains assignment-local; it is not a
whole-transaction grant or a stalled-progress protocol.

### Rollout and signoff

Start with a shadow logical-controller/consumer model under the existing
region/effect doctrine (`0013`). Prove unchanged source and public reports
before switching execution. Resolve direct formal identities under `.49.2.2`,
then repair local payload retention and establish shared-write admission before
independent execution is promoted. Separate local-call entry/capture and broad
backend/report qualification leaves retain their own runtime obligations.

Use declaration permutations, overlapping short/long independent work,
repeated and nested calls, changed inputs after acceptance, early entry samples,
held requests, reset during work, state-active priority and named-point checks.
Compare exact native/API/MCP reports and public IAL0 replay. Significant control
migration requires the broader regression gate; admission, lint and authored
reference simulations alone cannot close production runtime qualification.

## Consequences

The current direct-controller warning remains until generated production HDL
passes the owned repair gates. Local rule payload retention is now integrated
and qualified under .32.1.3.3.1.3.2 (T1965/T1966), including entry samples,
busy/reset/held requests and granted multiple sources. Independent controllers
and local-call timing remain open. Generated live-call probes stay separate
positive controls; they do not prove snapshot support. The early ungated
trigger probe is retained with its corrected interpretation.

This selects execution and admission boundaries without claiming an implemented
controller, arbitration protocol, scoped-port repair or storage-access feature.
Those remain prerequisites to the requested semantic register-access metadata.
