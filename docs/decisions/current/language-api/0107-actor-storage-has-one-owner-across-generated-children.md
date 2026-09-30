# 0107 — Actor storage has one owner across generated transaction children

- Date: 2026-09-26
- Status: accepted; implementation lanes remain open
- Type: ISF storage and generated-module contract
- Owner: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.1`

## Context

Actor `(storage ...)` declares persistent actor-owned state. Generating a
transaction as a separate module must not turn that state into a new external
input or a private register copy. The retained probes in
[the child-storage audit](../../../audits/generated-child-storage-ownership-20260926.json)
pass strict check but fail independent read/write observations. A child write
updates its own register while the parent retains its reset value; a child
read becomes an inferred top input. Ordinary/domain ownership is repaired by
`.39.2.1`, but applying `internal` to every copied child declaration would
preserve the duplicated-state defect.

## Decision

Keep the actual actor-storage register and its reset in the owning actor or
clock-domain module. Generated transaction children access that same state
through explicit handoffs, with no new public actor ports:

- Reads are live views of the owning register, with its exact width/type.
  A transaction needing a snapshot must author the existing snapshot binding
  or local sampling operation explicitly.
- Writes transfer data and an enable to the owner on the original assignment
  edge. Do not add a payload-register cycle or silently delay visibility until
  child completion. Later child reads observe the shared updated state.
- Child modules retain only storage interface information they actually use;
  they do not receive independent copies of unrelated actor state.
- Transaction-local state remains local. Separately instantiated actors each
  retain their own actor storage; these are different ownership boundaries.

Implement and qualify read routing first. Refuse unsupported direct child
writes while their handoffs are unqualified. Then implement full-width scalar
writes from a sole writer, followed by owned partial-update, bank and competing
writer lanes. Source ordering, per-signal ownership and the existing resource
arbitration roadmap must determine arbitration; never invent silent priority.
Unsupported combinations remain explicit diagnostics with scheduled ownership,
not successful generation of behaviorally different hardware.

## Consequences

The generic composition rule that infers top inputs from unconnected child
inputs remains valid for direct composition sources. ISF must produce the
necessary storage handoffs before composition rather than disable that rule.
Generated names must avoid authored and other generated names. Domain rules,
reset policy and explicit transaction bindings continue to apply. Native,
API and MCP interface reports must match actual hardware. Independent runtime
oracles must distinguish live reads, snapshots, write timing and reset/hold.
