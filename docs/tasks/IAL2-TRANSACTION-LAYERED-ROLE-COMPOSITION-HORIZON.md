# IAL2-TRANSACTION-LAYERED-ROLE-COMPOSITION-HORIZON: layered composable transactor roles

## Metadata

- Tree ID: `IAL2-TRANSACTION-LAYERED-ROLE-COMPOSITION-HORIZON`
- Status: `proposed` (not PNT-eligible until director-activated)
- Roadmap lane: `IAL2 / architecture horizon / transaction layer + role composition`
- Created: `2026-07-12`
- Last updated: `2026-07-12`
- Owner: repo-local workflow

## Origin — director thinking-aloud (explicitly no pivot)

The director described (2026-07-12), as a future route and explicitly **not** a
pivot or a change of course, the destination architecture for the IAL2 protocol
layer. Captured here so it survives the session; see decision
`docs/decisions/0020-ial2-layered-composable-transactor-roles.md`.

## Goal

Grow the IAL2 protocol layer into a **layered, protocol-agnostic transactor**
architecture:

1. A protocol-neutral **transaction interface** (`write(addr, data, len)` /
   `read(addr, len)` → data/response; a write is one transfer or a burst) that
   every IAL2 role/entity exposes upward, so higher-level logic never sees
   AXI vs AHB vs APB.
2. **Primitive role blocks** — one per (protocol, role): AXI manager/subordinate,
   AHB requester/subordinate, APB requester/completer — each a bus adapter with
   the transaction interface on one side and the protocol bus channels on the
   other.
3. **Composition** of primitive roles into higher-order IAL2 entities that
   present the same transaction interface up the stack and let sibling sub-blocks
   interact through it (enabling bridges/converters, e.g. AXI-subordinate →
   APB-requester).

The existing AHB requester `local-command`/`local-status` blocks are the embryo
of the transaction interface and the natural generalization seed.

## Non-Goals

- No change to the mandatory lowering chain (`IAL2 → .isf → .fsm → HDL`,
  decisions `0014`/`0018`); this governs what generated modules expose.
- No pivot away from, or change to, the active
  `IAL2-AXI-MANAGER-INITIATOR-FRONTIER` thread or any shipped generator.
- No new IAL2 language layer; the transaction interface is a vocabulary/contract
  over the existing model (decisions `0015`/`0016`).

## Acceptance Criteria (when activated)

- A selected, bounded transaction-interface contract (protocol-neutral write/read,
  single or burst, request/response handshake), with focused tests and synced
  mdBook.
- Role-block wrapping of at least one existing bus adapter behind that interface,
  starting from the AHB requester's `local-command`/`local-status`.
- A composition mechanism proven on one higher-order entity (e.g. a bridge),
  lowering cleanly and passing `--verify-hdl` where applicable.

## Task Tree

- ID: `IAL2-TRANSACTION-LAYERED-ROLE-COMPOSITION-HORIZON`
  Status: `proposed`
  Goal: `Grow the IAL2 protocol layer into a layered protocol-agnostic transactor architecture (transaction interface upward, primitive role blocks, composition into higher-order entities), per decision 0020.`
  Children: `(none yet — a first readiness/selection leaf is filed when the director activates this horizon)`

## Notes

- Directional/future only; not PNT-eligible. When activated, its likely first
  leaf is a readiness/selection audit for the transaction-interface contract,
  grounded in the AHB requester's `local-command`/`local-status` seed and the
  bounded AXI AW driver (`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.4`) as the first
  bus-side primitive.
- Related proposed owners: `FSMGEN-HIR-ROADMAP-FRONTIER` (source-facing HIR),
  `IAL2-HOST-LANGUAGE-BUILDER-FRONTIER` (IAL2/IAL1 builder). This horizon is the
  role/transaction-layer counterpart above the per-protocol bus adapters.
