# IAL2-ATL-LOWERING-INTEGRATION: Reviewable actor networks in IAL2 lowering

## Metadata

- Tree ID: `IAL2-ATL-LOWERING-INTEGRATION`
- Status: `active`
- Roadmap lane: `R14 / IAL2 to IAL1 actor networks`
- Created: `2026-10-02`
- Last updated: `2026-10-02`
- Owner: repo-local workflow

## Goal

Make multi-actor IAL2 compositions emit a reviewable IAL1/ISF ATL network,
then obtain their IAL0 composition through the canonical IAL1 lowering path.
Preserve protocol behavior, artifact/report contracts and source provenance.

## Non-Goals

- This registration ships no network generator or new source syntax.
- Do not replace continuous protocol wiring with one-cycle ATL drive routes.
- Do not activate decision 0020's transaction-interface horizon, VHDL work,
  arbitrary groups, CDC, route storage or payload protocols by implication.

## Acceptance Criteria

- All current multi-actor generators and their relevant history are audited;
  every network-level semantic choice has an IAL1 representation or owned gap.
- Child actors alone cannot qualify a complete network lowering claim.
- Generated instances, bindings, activation, events, ordering and any storage
  preserve exact widths, direction, lifetimes and clock/reset ownership.
- Existing bounded public sources and aliases preserve their observable
  behavior; intentional artifact/report changes have explicit compatibility.
- Independent old/new source, schedule, topology and generated-HDL behavior
  evidence qualifies each migrated family. Unsupported shapes fail closed.
- Book, roadmap, contracts, support/API/MCP accounting and current facts stay
  aligned; each selected slice commits through `COMMIT.md`.

## Task Tree

- ID: `IAL2-ATL-LOWERING-INTEGRATION`
  Status: `active`
  Goal: `Route complete multi-actor IAL2 intent through reviewable ATL in IAL1.`
  Children: `IAL2-ATL-LOWERING-INTEGRATION.1, IAL2-ATL-LOWERING-INTEGRATION.2, IAL2-ATL-LOWERING-INTEGRATION.3, IAL2-ATL-LOWERING-INTEGRATION.4, IAL2-ATL-LOWERING-INTEGRATION.5, IAL2-ATL-LOWERING-INTEGRATION.6, IAL2-ATL-LOWERING-INTEGRATION.7, IAL2-ATL-LOWERING-INTEGRATION.8`

- ID: `IAL2-ATL-LOWERING-INTEGRATION.1`
  Status: `pending`
  Goal: `Audit every IAL2 composition and select the smallest faithful ATL prerequisite.`
  Acceptance: `P2 architectural gap, scheduled after the current R13 source-intent preparation/adoption contract reaches its clean handoff. Reproduce fixed APB through public --outdir: apb_requester.isf/apb_completer.isf exist, apb_tb.fsm contains structural wiring, and apb_tb.isf is absent. Impact: reviewers cannot inspect that network intent at IAL1; no protocol malfunction is inferred. Inventory ApbComposition fixed/multi-peripheral branches, AhbInterconnect, and all AXI read/write request/transaction composition generators, public aliases, artifact/report/semantic/support contracts, actual consumers and complete relevant Git history. Compare each topology, persistent wire, trigger/event, join, ordering, storage and system contract against canonical ATL support. Select fixed APB only if its static continuous binding can be represented faithfully; otherwise select the exact smaller IAL1 prerequisite. Record independent whole current products and genuine missing-network controls. Split follow-up leaves before implementation.`
  Verification: `Initial fixed-APB evidence is bound by SEMANTIC-INTROSPECTION-MCP-FRONTIER.66 and docs/audits/ial2-atl-contract-20261002. Exhaustive census, history and migration selection remain pending.`
  Commit: `pending`

- ID: `IAL2-ATL-LOWERING-INTEGRATION.2`
  Status: `pending`
  Goal: `Select complete IAL1 network binding and IAL2 artifact compatibility contracts.`
  Acceptance: `After .1, distinguish physical/static interface binding from temporal drive-body movement. Freeze only the prerequisite source/IR shape required by the selected topology: explicit instances, endpoint direction/width, lifetime, clock/reset, external pins, activation/event ownership, diagnostics and report families. Reuse canonical elaboration where qualified; do not invent permanent movement under existing drive syntax. Specify deterministic network .isf names, child lookup, IAL0/top entry, source anchors, unchanged aliases, semantic/API/MCP projections and residue. Select independent compatibility/behavior oracles and safe rollback. No implementation claim.`
  Verification: `pending`
  Commit: `pending`

- ID: `IAL2-ATL-LOWERING-INTEGRATION.3`
  Status: `pending`
  Goal: `Implement and qualify the selected IAL1 network prerequisite.`
  Acceptance: `After .2, split parser, elaborator, scheduler/emitter and report/admission work into separately committed safe children. Preserve current ATL temporal routes, generated-child composition and fail-closed groups/joins/CDC boundaries. Qualify full graph, names, directions, widths, lifetimes, system ownership and missing/ambiguous endpoint refusals with independent products and meaningful pre-fix controls. Publish runnable source, support accounting and book/API/MCP contracts together. Native behavior qualification must satisfy existing startup gates; emitted HDL alone is insufficient.`
  Verification: `pending`
  Commit: `pending`

- ID: `IAL2-ATL-LOWERING-INTEGRATION.4`
  Status: `pending`
  Goal: `Migrate selected APB compositions through emitted ATL network intent.`
  Acceptance: `After the prerequisite qualifies, begin with the exact fixed APB contract selected by .1/.2. Derive complete network .isf before canonical IAL0 top construction; keep endpoint actors and continuous handshake semantics intact. Independently compare old/new ports, topology, reset, APB setup/access/stall/error/read/write behavior, source anchors and all generated/reported artifacts. Then split multi-peripheral decode and every shipped register/width/sideband/back-to-back family and alias into explicit qualified children; no untested family promotion. Update reports, support and book per slice.`
  Verification: `pending`
  Commit: `pending`

- ID: `IAL2-ATL-LOWERING-INTEGRATION.5`
  Status: `pending`
  Goal: `Migrate selected AHB interconnect compositions through emitted ATL network intent.`
  Acceptance: `After .1 identifies the exact prerequisite and APB proves the shared boundary, split one-/two-subordinate and shipped lane/SEQ/HBURST/BUSY families into bounded leaves. Preserve address/data-phase ownership, registered routing/decode, response selection, widths, reset and public alias contracts. Emit complete IAL1 network intent, then canonical IAL0; independently qualify topology and actual protocol behavior under the existing native gates. Do not infer broader AHB or CDC support.`
  Verification: `pending`
  Commit: `pending`

- ID: `IAL2-ATL-LOWERING-INTEGRATION.6`
  Status: `pending`
  Goal: `Migrate selected AXI composition families through emitted ATL network intent.`
  Acceptance: `After .1/.2, create separate audit/selection/implementation/qualification children for AxiWriteRequestComposition, AxiWriteTransactionComposition, AxiReadTransactionComposition, AxiWriteBurst4RequestComposition and AxiReadBurst4TransactionComposition and any additional discovered generator. Preserve independent channel completion, coordinator storage, atomic capture, stalling, busy/reset recovery, request-versus-full-transaction completion and exact burst boundaries. Represent graph and orchestration at IAL1, preserve reports/aliases/support, and qualify actual generated-HDL behavior independently; no full-manager or decision 0020 horizon promotion.`
  Verification: `pending`
  Commit: `pending`

- ID: `IAL2-ATL-LOWERING-INTEGRATION.7`
  Status: `pending`
  Goal: `Close complete graph provenance and public inspection coverage.`
  Acceptance: `After selected migrations, independently join every IAL2 source object/anchor to emitted IAL1 network, selected children/bindings/orchestration and IAL0 artifacts. Qualify native/API/actual newline MCP check, semantic and schedule products, generated file membership, version/compatibility declarations and malformed/unsupported refusals. No embedded graph/hash serves as its own authority. Keep contracts backend-language neutral and remaining families explicitly owned.`
  Verification: `pending`
  Commit: `pending`

- ID: `IAL2-ATL-LOWERING-INTEGRATION.8`
  Status: `pending`
  Goal: `Earn complete migration signoff and synchronized documentation.`
  Acceptance: `After all selected families and public inspections qualify, reconcile the full .1 census against permanent independent tests, old/new products and exact native gates. Document ATL model, physical versus temporal bindings, scheduling, diagnostics, artifacts and runnable per-profile examples. Remove only superseded lowering residue; retain unsupported groups/CDC/runtime claims. Run broader regression and mandatory full CI before any authorized/cadence push, consume hosted results, commit and close only when all required work is verified.`
  Verification: `pending`
  Commit: `pending`

## Decisions

- `2026-10-02`: Director requires multi-actor IAL2 lowering to use ATL within
  IAL1/ISF. Decision 0115 records the target and observed fixed-APB gap.
- Current R13 source-intent ownership continues first. This P2 integration
  tree is scheduled next at that contract's clean handoff; legacy HUtils is
  not a prerequisite.

## Open Questions

- Exact static binding representation is owned by .1/.2; no new syntax is
  implied by registering this tree.

## Blockers

- No access blocker for .1. Native execution still obeys the separately
  owned historical startup/full-CI gates; these are not waived here.
