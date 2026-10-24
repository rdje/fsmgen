# FSMGEN-CONVERSATIONAL-INTERFACE: A conversational interface to FSMGen, backed by structured API calls

## Metadata

- Tree ID: `FSMGEN-CONVERSATIONAL-INTERFACE`
- Status: `proposed`
- Roadmap lane: `R13 / private client integration and user interface`
- Created: `2026-10-24`
- Last updated: `2026-10-24`
- Owner: repo-local workflow
- Capture owner: `PERL-POD-API-REFERENCE.8.3`

## Goal

Provide a private conversational and graphical interface for operating the
director's own FSMGen instance from an OpenAI host. ChatGPT/Codex handles the
conversation and tool selection; FSMGen performs its defined operations and
returns authoritative results through structured APIs, normally exposed by MCP.
The plugin UI and conversational tools consume the same source identities,
capabilities, reports and operation contracts.

This is a proposed task tree requested during DBIQNP discussion. Capturing it
does not activate implementation, installation, a connection, or a new server
capability. The active documentation and required feature-delivery priorities
remain governed by `MEMORY.md` and `docs/TASK_TREE.md`.

## Non-Goals

- No implementation or priority pivot during this capture.
- No model dependency in the compiler, parallel semantic implementation, or
  change to DSL meaning or the existing checked lowering pipeline.
- No inferred UI parity between ChatGPT and a particular Codex surface.
- No implied simulation, hardware execution or board-control capability from
  static semantic or scheduling reports.
- No implicit source mutation, arbitrary shell, commit/push authority, ambient
  network service or unrestricted filesystem access through plugin packaging.

## Acceptance Criteria

- An explicitly selected private host can discover and use the qualified
  FSMGen tools against an explicitly scoped local instance/workspace.
- The graphical UI is an explicit workstream: users can inspect real results
  and invoke supported operations alongside conversation on the selected host.
- Host qualification separates tool availability from embedded UI rendering;
  unsupported surfaces and fallback requirements are resolved before delivery.
- Conversation and UI preserve concrete source/revision identity, value kinds,
  result/refusal semantics and the current published API's applicability limits.
- Existing inspection/check/report operations are reused before new effectful
  capabilities are considered. New core write/generation or server-transport
  decisions retain the existing MCP horizon owner.
- Any later effectful integration has a separate selected contract and tests
  for exact inputs, authorized effects, artifacts, failures and resource limits.
- Real private-client workflows, adverse controls, navigation/accessibility and
  recovery pass; intended UI behavior is checked in the actual target host.
- Book, setup guidance, capability boundaries and reproducible qualification
  evidence are synchronized. Each activated slice follows `COMMIT.md`.
- Project-owned outputs/caches/workspaces stay repository-derived and on the
  repository volume; other repositories and submodules retain their boundaries.

## Task Tree

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE`
  Status: `proposed`
  Goal: `Deliver a private conversational and graphical interface over authoritative structured FSMGen operations when explicitly selected.`
  Children: `FSMGEN-CONVERSATIONAL-INTERFACE.1, FSMGEN-CONVERSATIONAL-INTERFACE.2, FSMGEN-CONVERSATIONAL-INTERFACE.3, FSMGEN-CONVERSATIONAL-INTERFACE.4, FSMGEN-CONVERSATIONAL-INTERFACE.5, FSMGEN-CONVERSATIONAL-INTERFACE.6`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.1`
  Status: `proposed`
  Goal: `Select the private host, user workflows and exact API/UI boundaries before implementation.`
  Children: `FSMGEN-CONVERSATIONAL-INTERFACE.1.1, FSMGEN-CONVERSATIONAL-INTERFACE.1.2`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.1.1`
  Status: `proposed`
  Goal: `Qualify the intended ChatGPT/Codex surface, private connection route and UI support.`
  Acceptance: `Recheck current official documentation and the actual authorized account/client. Distinguish MCP tool use, embedded MCP Apps UI, private stdio/tunnel connectivity and required host permissions. Test the smallest permitted connection/render probe after activation; retain actual success/refusal and exact host/runtime identities. Resolve any Codex embedded-UI gap explicitly instead of assuming parity. Record the first supported private target and refine implementation leaves.`
  Verification: `pending activation; no connection, entitlement or FSMGen host compatibility has been tested by this proposal`
  Commit: `pending`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.1.2`
  Status: `proposed`
  Goal: `Select useful initial workflows and preserve the canonical FSMGen authority boundary.`
  Acceptance: `Inventory the actual shipped adapter/API/schema/manual contracts and supported source/query applicability. Select concrete private inspection/check/report journeys and a minimal useful graphical journey. Bind workspace/source identity, report versions, capabilities, result kinds, errors and effects. Separate UI rendering/client packaging from core semantic, transport and effectful API decisions; route new core capabilities to existing owners. Do not presume that every desired operation is already exposed.`
  Verification: `pending host and workflow selection`
  Commit: `pending`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.2`
  Status: `proposed`
  Goal: `Connect and package the selected private interface without changing compiler semantics.`
  Children: `FSMGEN-CONVERSATIONAL-INTERFACE.2.1, FSMGEN-CONVERSATIONAL-INTERFACE.2.2`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.2.1`
  Status: `proposed`
  Goal: `Implement the selected private MCP connection and plugin packaging.`
  Acceptance: `Use the qualified host route and the published FSMGen adapter contract. Keep configuration portable and project-owned storage local; preserve the existing read-only profile and explicit workspace authority. Qualify actual initialization, discovery, tools/resources/schemas and supported request/result round trips. If a new FSMGen server transport is necessary, obtain its existing owner selection first rather than silently adding service behavior.`
  Verification: `pending .1 design and activation`
  Commit: `pending`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.2.2`
  Status: `proposed`
  Goal: `Qualify private connection lifecycle, failures and recovery.`
  Acceptance: `Test the actual client/instance startup, persistent request delivery, orderly shutdown, unavailable instance, malformed requests, authentication/permission refusal where applicable and restart/reconnection. Preserve source/workspace boundaries and structured diagnostics. Bound resources and retained logs; define recovery from interrupted work without implying that a killed process can continue from an unsupported checkpoint.`
  Verification: `pending private connection`
  Commit: `pending`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.3`
  Status: `proposed`
  Goal: `Make conversational operation accurate and useful against current FSMGen results.`
  Children: `FSMGEN-CONVERSATIONAL-INTERFACE.3.1, FSMGEN-CONVERSATIONAL-INTERFACE.3.2`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.3.1`
  Status: `proposed`
  Goal: `Provide workflow instructions and precise tool selection for the chosen inspection journeys.`
  Acceptance: `Teach the host to discover capabilities/source identity and choose the applicable published inspection/check/semantic/schedule operations. Exercise direct, indirect and follow-up prompts plus unsupported requests. Keep natural-language interpretation in the host and validity/results in FSMGen. Do not invent an authoring, execution or generation capability from a metadata heading.`
  Verification: `pending selected working connection and workflows`
  Commit: `pending`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.3.2`
  Status: `proposed`
  Goal: `Qualify report fidelity, explanations and source-bound conversational context.`
  Acceptance: `Join actual plugin tool arguments/results to canonical native/API results using authorized current fixtures. Verify exact values/kinds, source/revision identity, applicability, diagnostics and refusal behavior with independent adverse controls. Distinguish metadata families from actual payloads and schedule prediction from execution. Keep stale, missing and unsupported information visible; retain original outcomes and avoid replaying sealed historical capture epochs.`
  Verification: `pending conversational tools`
  Commit: `pending`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.4`
  Status: `proposed`
  Goal: `Provide the graphical FSMGen interface alongside conversation on the qualified host.`
  Children: `FSMGEN-CONVERSATIONAL-INTERFACE.4.1, FSMGEN-CONVERSATIONAL-INTERFACE.4.2, FSMGEN-CONVERSATIONAL-INTERFACE.4.3`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.4.1`
  Status: `proposed`
  Goal: `Design and review the minimum useful private graphical workflow using real API data.`
  Acceptance: `Review the selected human journey and actual available payloads before choosing screens or controls. Consider source/capability navigation, diagnostics, state/structure diagrams and lowering/schedule views where the public data supports them. Make operation availability and result provenance understandable. Keep compiler/tool implementation details out of ordinary UI flows unless needed for a meaningful user decision.`
  Verification: `pending host qualification and workflow design`
  Commit: `pending`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.4.2`
  Status: `proposed`
  Goal: `Implement the selected graphical views and supported operation controls through shared structured APIs.`
  Acceptance: `Use the qualified host UI mechanism and canonical payloads. Render actual source-bound information and call the same defined operations used by conversation. Preserve value kinds, refusals, unsupported/empty states and complete evidence access; never create a second semantic engine in the renderer. Distinguish defined/static state from observed execution and expose effectful controls only after their canonical API qualification.`
  Verification: `pending reviewed graphical journey`
  Commit: `pending`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.4.3`
  Status: `proposed`
  Goal: `Qualify graphical/conversational synchronization, usability and host compatibility.`
  Acceptance: `Exercise real rendered views, selections and tool actions with source identity and stale-result controls. Test supported host UI capabilities, initialization/lifecycle, loading/error/refusal states, keyboard/accessibility, navigation and useful display sizes. Verify that model-visible context and displayed results stay consistent. Qualify the selected host's fallback behavior without advertising untested cross-host UI parity.`
  Verification: `pending implemented UI and actual host testing`
  Commit: `pending`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.5`
  Status: `proposed`
  Goal: `Integrate separately selected bounded source-write/generation capabilities if requested later.`
  Children: `FSMGEN-CONVERSATIONAL-INTERFACE.5.1, FSMGEN-CONVERSATIONAL-INTERFACE.5.2`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.5.1`
  Status: `proposed`
  Goal: `Route any new effectful API requirement to the existing MCP horizon owner.`
  Acceptance: `State the desired user operation precisely and compare it with shipped read-only check/report operations. Delegate new core source mutation, HDL/artifact generation or server-transport selection to SEMANTIC-INTROSPECTION-MCP-WRITE-HORIZON and related canonical owners. Require their selected typed inputs/effects, authorization, path/resource, provenance and failure contracts before plugin implementation. Do not duplicate their API design here or activate them through this proposal.`
  Verification: `pending later effectful-workflow selection; inspection/UI work does not itself authorize it`
  Commit: `pending`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.5.2`
  Status: `proposed`
  Goal: `Adopt qualified effectful tools into conversation and graphical controls.`
  Acceptance: `After canonical API delivery, integrate exact supported candidate/write/generation/artifact operations through the same checked FSMGen pipeline. Verify intended effects, failure isolation, artifact identity/retrieval and actual backend applicability through independent controls. Keep read-only workflows usable and preserve explicit unsupported execution boundaries. Split concrete implementation slices after the selected effect contract exists.`
  Verification: `pending .5.1 and separately qualified API capabilities`
  Commit: `pending`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.6`
  Status: `proposed`
  Goal: `Qualify and document the complete selected private experience.`
  Children: `FSMGEN-CONVERSATIONAL-INTERFACE.6.1, FSMGEN-CONVERSATIONAL-INTERFACE.6.2`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.6.1`
  Status: `proposed`
  Goal: `Run end-to-end qualification of the actual installed private plugin and UI.`
  Acceptance: `Join selected tools, schemas, instructions, UI resources and workflows with no unexplained omissions. Test real conversation and graphical actions, actual results/refusals, unsupported requests, connection/resource interruptions and recovery. Require independent semantic/result oracles and observed adverse controls; keep host, source, runtime and capability identities with the evidence. Qualify only the operations and hosts actually tested.`
  Verification: `pending selected private implementation; effectful scope may remain explicitly deferred`
  Commit: `pending`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.6.2`
  Status: `proposed`
  Goal: `Deliver accurate private setup, use, limits and recovery documentation.`
  Acceptance: `Document the actual selected host and installation/connection path, graphical and conversational examples, available operations, source/workspace authority, effects and recovery. Synchronize the mdBook and relevant discovery/fact records with tested behavior. Complete focused checks and required commit workflow, leaving a clean recoverable handoff. Task capture or a schema inventory alone is not completed plugin delivery.`
  Verification: `pending qualified private workflows`
  Commit: `pending`

## Current Frontier

No implementation frontier is active. On later explicit activation, select
`.1.1` first and refine safe executable slices from its actual host findings.
Current PNT selection remains in `MEMORY.md` and the active task-tree index.

## Decisions

- `2026-10-24`: The director requested a dedicated proposed tree during DBIQNP.
  Scope is private use with the director's own FSMGen instance. The explicit
  graphical UI workstream complements the conversational interface.
- `2026-10-24`: The host provides conversation; FSMGen supplies authoritative
  structured operations/results. Conversation and UI share those APIs.
- `2026-10-24`: Reuse the shipped read-only adapter first. New core effects and
  server-transport decisions retain the separately proposed
  [MCP write horizon](SEMANTIC-INTROSPECTION-MCP-WRITE-HORIZON.md).
- `2026-10-24`: Official [plugin guidance](https://developers.openai.com/plugins/quickstart)
  and [private connection guidance](https://developers.openai.com/plugins/deploy/connect-chatgpt)
  were fetched during the discussion. The [UI guide](https://developers.openai.com/plugins/build/chatgpt-ui)
  documents embedded UI in ChatGPT and compatibility-based MCP Apps rendering.
  These dated external observations do not establish account access, a working
  FSMGen connection or embedded UI support in the target Codex surface; recheck
  them and test the actual host under `.1.1`.

## Open Questions

- `.1.1`: Which exact ChatGPT/Codex surface is the first private target, and
  which required graphical capabilities does it actually provide?
- `.1.1`: Which supported private local/tunnel route and account permissions
  apply? No connection or credentials have been configured by this proposal.
- `.1.2` and `.4.1`: Which inspection/diagnostic journey is the smallest useful
  graphical interface, and which additional views should follow?
- `.5.1`: Which candidate-write/generation/artifact operation, if any, should
  be selected after inspection? Its core API selection belongs to the existing
  horizon owner.

## Blockers

No planning blocker. Implementation is deliberately unselected under DBIQNP;
host/account/UI compatibility and any new API capability remain future
qualification work, not silently satisfied prerequisites.

## Verification Log

Capture and documentation checks are owned by
`PERL-POD-API-REFERENCE.8.3`. No plugin implementation, installation,
connection, rendered UI or end-to-end host result is claimed by this capture.

## Commit Log

Find the capture commit with
`git log --grep='PERL-POD-API-REFERENCE.8.3:'`.
Future activated leaves use their own permanent work-unit IDs in Git subjects.
