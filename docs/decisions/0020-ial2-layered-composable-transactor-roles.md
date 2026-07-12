# 0020 — IAL2 protocol roles as layered, composable transactors (future North Star)

- Date: 2026-07-12
- Type: architecture
- Status: accepted (directional — future horizon; not yet scheduled, does not pivot current work)
- Origin: director thinking-aloud about future routes (2026-07-12), explicitly "not a pivot"; captured so it does not live only in the conversation. "That's where I want to go."
- Owner: proposed `IAL2-TRANSACTION-LAYERED-ROLE-COMPOSITION-HORIZON` (not PNT-eligible until director-activated)

## Context

Today's IAL2 protocol-intent generators each speak only to a **bus**: the AHB
requester drives HTRANS/HADDR/HWDATA; the APB requester/completer drive the APB
handshake; the AXI valid-ready monitor observes a channel; the AXI capacity/status
core tracks responses; the new AXI AW address-channel driver
(`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.4`) drives one AW handshake. None of them
receives an order from a **higher layer in the stack** — they are wire-facing
only.

There is already an embryo of the target pattern: the AHB requester's
`(local-command …)` block (valid/write/address/write-data/length/burst) is, in
effect, a transaction **order in**, and its `(local-status …)` block
(busy/beat-done/done/…) is the transaction **status/response out**. It is neither
standardized, named as a transaction interface, nor present on AXI/APB.

## Decision

Adopt — as the future architectural North Star for the IAL2 protocol layer — a
**layered, protocol-agnostic transactor** model:

1. **Transaction interface (upward face).** Every IAL2 role/entity exposes a
   protocol-neutral transaction port: `write(addr, data, len)` /
   `read(addr, len)` → data/response. A write may lower to a single transfer or
   a burst on the wire; the caller does not know or care whether the wire is
   AXI, AHB, or APB. This is a generalization of the AHB requester's existing
   `local-command`/`local-status` pattern.

2. **Primitive role blocks (bus adapters).** One block per (protocol, role) —
   AXI manager, AXI subordinate, AHB requester, AHB subordinate, APB requester,
   APB completer, … Each block has the transaction interface on one side and the
   protocol-specific bus channels on the other, and translates between them.

3. **Composition into higher-order entities.** Primitive roles compose into
   higher-order IAL2 modules/blocks/entities. A composite entity presents the
   same transaction interface **upward** to the next layer in the stack, and its
   sibling sub-blocks interact with each other through that same interface. Two
   roles in one entity, wired through the interface, is how a **bridge/converter**
   is built (e.g., an AXI-subordinate role whose received transactions drive an
   APB-requester role). The interface is therefore doubly-useful: high-level ↔
   block, and block ↔ block.

The physical layer here is IAL2; the transaction interface is the layer boundary
higher-level logic talks to.

## Consequences

- The **mandatory lowering chain is unchanged** (`IAL2 → generated IAL1/.isf →
  generated IAL0/.fsm → HDL`, decisions `0014`/`0018`); this is an architecture
  for what the generated modules **expose**, not a new lowering path.
- **No pivot and no change to current work.** The active
  `IAL2-AXI-MANAGER-INITIATOR-FRONTIER` thread continues; its AW address-channel
  driver and the other shipped role generators remain valid **bus-side building
  blocks** under this North Star. The transaction interface is added *above*
  them later, not instead of them.
- Future artifacts this direction implies (each a later exact owner): the shared
  **transaction-interface contract** (protocol-neutral write/read, single or
  burst, request/response handshake); **role-block wrapping** of the bus adapters
  behind that interface (starting by generalizing the AHB requester's
  `local-command`/`local-status`); and **composition/interconnect of roles** into
  higher-order entities that present the interface up the stack.
- This is a **future horizon**: captured as the proposed owner
  `IAL2-TRANSACTION-LAYERED-ROLE-COMPOSITION-HORIZON`, not PNT-eligible until the
  director activates it. Recorded now so the direction survives the session;
  framing may be refined or superseded as the design matures.
