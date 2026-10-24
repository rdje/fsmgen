# FSMGEN-CONVERSATIONAL-INTERFACE: A conversational interface to FSMGen, backed by structured API calls

## Metadata

- Tree ID: `FSMGEN-CONVERSATIONAL-INTERFACE`
- Status: `active`
- Roadmap lane: `R13 / private client integration and user interface`
- Created: `2026-10-24`
- Last updated: `2026-10-24`
- Owner: repo-local workflow
- Capture owner: `PERL-POD-API-REFERENCE.8.3`
- Scheduling owner: `PERL-POD-API-REFERENCE.8.4`

## Goal

Provide a private conversational and graphical interface for operating the
director's own FSMGen instance from an OpenAI host. ChatGPT/Codex handles the
conversation and tool selection; FSMGen performs its defined operations and
returns authoritative results through structured APIs, normally exposed by MCP.
The plugin UI and conversational tools consume the same source identities,
capabilities, reports and operation contracts.

The director accepted task tracking and dependency-based scheduling after the
DBIQNP discussion. Private read-only client/conversation/UI delivery is scheduled
behind the current MCP operating reference and required SPECFORGE handoff. This
planning step starts no installation, connection or feature implementation.
Current work selection remains in `MEMORY.md` and `docs/TASK_TREE.md`; the entry
gate and each successor release are specified below.

## Non-Goals

- No immediate implementation pivot while recording this schedule; prerequisites
  and the selected current frontier retain their authority.
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
  capabilities are considered. New core write/generation capabilities
  retain the MCP write-horizon owner; read-only server-transport decisions
  retain the existing semantic MCP owner.
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
  Status: `active`
  Goal: `Deliver a private conversational and graphical interface over authoritative structured FSMGen operations under the recorded dependency schedule.`
  Children: `FSMGEN-CONVERSATIONAL-INTERFACE.1, FSMGEN-CONVERSATIONAL-INTERFACE.2, FSMGEN-CONVERSATIONAL-INTERFACE.3, FSMGEN-CONVERSATIONAL-INTERFACE.4, FSMGEN-CONVERSATIONAL-INTERFACE.5, FSMGEN-CONVERSATIONAL-INTERFACE.6`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.1`
  Status: `active`
  Goal: `Select the private host, user workflows and exact API/UI boundaries before implementation.`
  Children: `FSMGEN-CONVERSATIONAL-INTERFACE.1.1, FSMGEN-CONVERSATIONAL-INTERFACE.1.2`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.1.1`
  Status: `active`
  Goal: `Qualify the intended ChatGPT/Codex surface, private connection route and UI support.`
  Acceptance: `Recheck current official documentation and the actual authorized account/client. Distinguish MCP tool use, embedded MCP Apps UI, private stdio/tunnel connectivity and required host permissions. Test the smallest permitted connection/render probe when its scheduling gate opens; retain actual success/refusal and exact host/runtime identities. Resolve any Codex embedded-UI gap explicitly instead of assuming parity. Record the first supported private target and refine implementation leaves.`
  Verification: `scheduled qualification children; no connection, entitlement or host compatibility is claimed`
  Commit: `pending`
  Children: `FSMGEN-CONVERSATIONAL-INTERFACE.1.1.1, FSMGEN-CONVERSATIONAL-INTERFACE.1.1.2, FSMGEN-CONVERSATIONAL-INTERFACE.1.1.3, FSMGEN-CONVERSATIONAL-INTERFACE.1.1.4`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.1.1.1`
  Status: `blocked`
  Goal: `Inventory the actual private host, account capabilities and supported integration contracts.`
  Acceptance: `Recheck official host/plugin/MCP/UI documentation and available authorized client/account evidence. Record exact host/version, tool and embedded-UI capabilities, permission/access gaps and portable private connection candidates. This is host qualification, not assumed ChatGPT/Codex UI parity or a new FSMGen transport.`
  Verification: `scheduled; prerequisite not complete`
  Commit: `pending`
  Blocked by: `entry schedule gate; release to pending after verified committed completion; continue the current eligible priority leaf meanwhile.`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.1.1.2`
  Status: `blocked`
  Goal: `Qualify a minimal private structured-tool round trip.`
  Acceptance: `Through the supported route and published adapter, probe initialization, capability discovery and one admitted read-only request/result/refusal using an owned current fixture. Retain actual host/instance/source identities and failures; request missing access only when concretely needed. Preserve workspace/locality boundaries and sealed historical epochs.`
  Verification: `scheduled; prerequisite not complete`
  Commit: `pending`
  Blocked by: `FSMGEN-CONVERSATIONAL-INTERFACE.1.1.1; release to pending after verified committed completion; continue the current eligible priority leaf meanwhile.`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.1.1.3`
  Status: `blocked`
  Goal: `Qualify actual embedded UI rendering and tool/context interaction.`
  Acceptance: `Use an owned minimal UI resource and the documented host mechanism to observe rendering, tool invocation, result/context delivery and a meaningful unavailable/refusal control. Test the actual target surface; unsupported Codex UI becomes an explicit compatibility constraint, not a claim of parity or a silent loss of the UI requirement.`
  Verification: `scheduled; prerequisite not complete`
  Commit: `pending`
  Blocked by: `FSMGEN-CONVERSATIONAL-INTERFACE.1.1.2; release to pending after verified committed completion; continue the current eligible priority leaf meanwhile.`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.1.1.4`
  Status: `blocked`
  Goal: `Select the first supported private host and connection/UI contract.`
  Acceptance: `Join host/tool/UI evidence, choose the supported first target and connection route, and record exact installation/configuration/API/UI constraints plus fallback behavior. Split any newly discovered core requirement to its canonical owner before implementation; do not introduce a second semantic API.`
  Verification: `scheduled; prerequisite not complete`
  Commit: `pending`
  Blocked by: `FSMGEN-CONVERSATIONAL-INTERFACE.1.1.3; release to pending after verified committed completion; continue the current eligible priority leaf meanwhile.`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.1.2`
  Status: `blocked`
  Goal: `Select useful initial workflows and preserve the canonical FSMGen authority boundary.`
  Acceptance: `Inventory the actual shipped adapter/API/schema/manual contracts and supported source/query applicability. Select concrete private inspection/check/report journeys and a minimal useful graphical journey. Bind workspace/source identity, report versions, capabilities, result kinds, errors and effects. Separate UI rendering/client packaging from core semantic, transport and effectful API decisions; route new core capabilities to existing owners. Do not presume that every desired operation is already exposed.`
  Verification: `pending host and workflow selection`
  Commit: `pending`
  Blocked by: `FSMGEN-CONVERSATIONAL-INTERFACE.1.1.4; release to pending only after the named prerequisite is verified and committed; continue the current eligible priority leaf meanwhile.`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.2`
  Status: `active`
  Goal: `Connect and package the selected private interface without changing compiler semantics.`
  Children: `FSMGEN-CONVERSATIONAL-INTERFACE.2.1, FSMGEN-CONVERSATIONAL-INTERFACE.2.2`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.2.1`
  Status: `active`
  Goal: `Implement the selected private MCP connection and plugin packaging.`
  Acceptance: `Use the qualified host route and the published FSMGen adapter contract. Keep configuration portable and project-owned storage local; preserve the existing read-only profile and explicit workspace authority. Qualify actual initialization, discovery, tools/resources/schemas and supported request/result round trips. If a new FSMGen server transport is necessary, complete its existing owner selection first rather than silently adding service behavior.`
  Verification: `pending qualified host/workflow prerequisites`
  Commit: `pending`
  Children: `FSMGEN-CONVERSATIONAL-INTERFACE.2.1.1, FSMGEN-CONVERSATIONAL-INTERFACE.2.1.2, FSMGEN-CONVERSATIONAL-INTERFACE.2.1.3`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.2.1.1`
  Status: `blocked`
  Goal: `Create portable private plugin packaging over the selected public adapter.`
  Acceptance: `Implement the host-required package, tool/instruction/resource declarations and project-relative configuration for the selected read-only workflows. Bind versions, source/workspace authority and repository-local storage. Keep secrets out of tracked files; qualify schema/discovery packaging without changing compiler semantics.`
  Verification: `scheduled; prerequisite not complete`
  Commit: `pending`
  Blocked by: `FSMGEN-CONVERSATIONAL-INTERFACE.1.2; release to pending after verified committed completion; continue the current eligible priority leaf meanwhile.`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.2.1.2`
  Status: `blocked`
  Goal: `Implement the qualified private connection and explicit instance configuration.`
  Acceptance: `Use the host route selected at .1.1.4 and the published stdio adapter. Qualify actual instance/workspace selection and authorized connection setup. Any required new read-only FSMGen server transport returns to SEMANTIC-INTROSPECTION-MCP-FRONTIER; beyond-read-only effects retain SEMANTIC-INTROSPECTION-MCP-WRITE-HORIZON.`
  Verification: `scheduled; prerequisite not complete`
  Commit: `pending`
  Blocked by: `FSMGEN-CONVERSATIONAL-INTERFACE.2.1.1; release to pending after verified committed completion; continue the current eligible priority leaf meanwhile.`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.2.1.3`
  Status: `blocked`
  Goal: `Verify installed tool/resource discovery and structured round trips.`
  Acceptance: `Join actual private-host discovery to the shipped adapter/manifest, exercise selected tools/resources and exact arguments/value kinds/results/refusals, and retain host/runtime/source identities. Missing or extra operations must be explained; packaging alone is not a working interface.`
  Verification: `scheduled; prerequisite not complete`
  Commit: `pending`
  Blocked by: `FSMGEN-CONVERSATIONAL-INTERFACE.2.1.2; release to pending after verified committed completion; continue the current eligible priority leaf meanwhile.`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.2.2`
  Status: `blocked`
  Goal: `Qualify private connection lifecycle, failures and recovery.`
  Acceptance: `Test the actual client/instance startup, persistent request delivery, orderly shutdown, unavailable instance, malformed requests, authentication/permission refusal where applicable and restart/reconnection. Preserve source/workspace boundaries and structured diagnostics. Bound resources and retained logs; define recovery from interrupted work without implying that a killed process can continue from an unsupported checkpoint.`
  Verification: `pending private connection`
  Commit: `pending`
  Blocked by: `FSMGEN-CONVERSATIONAL-INTERFACE.2.1.3; release to pending only after the named prerequisite is verified and committed; continue the current eligible priority leaf meanwhile.`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.3`
  Status: `active`
  Goal: `Make conversational operation accurate and useful against current FSMGen results.`
  Children: `FSMGEN-CONVERSATIONAL-INTERFACE.3.1, FSMGEN-CONVERSATIONAL-INTERFACE.3.2`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.3.1`
  Status: `blocked`
  Goal: `Provide workflow instructions and precise tool selection for the chosen inspection journeys.`
  Acceptance: `Teach the host to discover capabilities/source identity and choose the applicable published inspection/check/semantic/schedule operations. Exercise direct, indirect and follow-up prompts plus unsupported requests. Keep natural-language interpretation in the host and validity/results in FSMGen. Do not invent an authoring, execution or generation capability from a metadata heading.`
  Verification: `pending selected working connection and workflows`
  Commit: `pending`
  Blocked by: `FSMGEN-CONVERSATIONAL-INTERFACE.2.2; release to pending only after the named prerequisite is verified and committed; continue the current eligible priority leaf meanwhile.`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.3.2`
  Status: `blocked`
  Goal: `Qualify report fidelity, explanations and source-bound conversational context.`
  Acceptance: `Join actual plugin tool arguments/results to canonical native/API results using authorized current fixtures. Verify exact values/kinds, source/revision identity, applicability, diagnostics and refusal behavior with independent adverse controls. Distinguish metadata families from actual payloads and schedule prediction from execution. Keep stale, missing and unsupported information visible; retain original outcomes and avoid replaying sealed historical capture epochs.`
  Verification: `pending conversational tools`
  Commit: `pending`
  Blocked by: `FSMGEN-CONVERSATIONAL-INTERFACE.3.1; release to pending only after the named prerequisite is verified and committed; continue the current eligible priority leaf meanwhile.`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.4`
  Status: `active`
  Goal: `Provide the graphical FSMGen interface alongside conversation on the qualified host.`
  Children: `FSMGEN-CONVERSATIONAL-INTERFACE.4.1, FSMGEN-CONVERSATIONAL-INTERFACE.4.2, FSMGEN-CONVERSATIONAL-INTERFACE.4.3`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.4.1`
  Status: `blocked`
  Goal: `Design and review the minimum useful private graphical workflow using real API data.`
  Acceptance: `Review the selected human journey and actual available payloads before choosing screens or controls. Consider source/capability navigation, diagnostics, state/structure diagrams and lowering/schedule views where the public data supports them. Make operation availability and result provenance understandable. Keep compiler/tool implementation details out of ordinary UI flows unless needed for a meaningful user decision.`
  Verification: `pending host qualification and workflow design`
  Commit: `pending`
  Blocked by: `FSMGEN-CONVERSATIONAL-INTERFACE.3.2; release to pending only after the named prerequisite is verified and committed; continue the current eligible priority leaf meanwhile.`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.4.2`
  Status: `active`
  Goal: `Implement the selected graphical views and supported operation controls through shared structured APIs.`
  Acceptance: `Use the qualified host UI mechanism and canonical payloads. Render actual source-bound information and call the same defined operations used by conversation. Preserve value kinds, refusals, unsupported/empty states and complete evidence access; never create a second semantic engine in the renderer. Distinguish defined/static state from observed execution and expose effectful controls only after their canonical API qualification.`
  Verification: `pending reviewed graphical journey`
  Commit: `pending`
  Children: `FSMGEN-CONVERSATIONAL-INTERFACE.4.2.1, FSMGEN-CONVERSATIONAL-INTERFACE.4.2.2, FSMGEN-CONVERSATIONAL-INTERFACE.4.2.3`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.4.2.1`
  Status: `blocked`
  Goal: `Implement the host UI resource and shared structured-data bridge.`
  Acceptance: `Initialize the qualified embedded UI and bind tool/result/context events to the same source-bound operations used by conversation. Preserve versions, value kinds, loading/error/refusal states and unsupported capability handling without duplicating semantic logic.`
  Verification: `scheduled; prerequisite not complete`
  Commit: `pending`
  Blocked by: `FSMGEN-CONVERSATIONAL-INTERFACE.4.1; release to pending after verified committed completion; continue the current eligible priority leaf meanwhile.`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.4.2.2`
  Status: `blocked`
  Goal: `Render the selected source, capability and result inspection journey.`
  Acceptance: `Implement the reviewed minimum journey using actual API data, preserving provenance, empty/stale states and complete evidence access. Add state/structure/lowering views only where the selected payload supports them; split each additional view into a safe owned leaf before code changes.`
  Verification: `scheduled; prerequisite not complete`
  Commit: `pending`
  Blocked by: `FSMGEN-CONVERSATIONAL-INTERFACE.4.2.1; release to pending after verified committed completion; continue the current eligible priority leaf meanwhile.`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.4.2.3`
  Status: `blocked`
  Goal: `Bind graphical controls to the qualified read-only operations.`
  Acceptance: `Connect selections/actions to the same typed requests as conversation. Verify source/instance identity, exact results and refusals, stale selection behavior and unsupported operations. Effectful controls remain absent until their separately selected API contract is qualified.`
  Verification: `scheduled; prerequisite not complete`
  Commit: `pending`
  Blocked by: `FSMGEN-CONVERSATIONAL-INTERFACE.4.2.2; release to pending after verified committed completion; continue the current eligible priority leaf meanwhile.`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.4.3`
  Status: `active`
  Goal: `Qualify graphical/conversational synchronization, usability and host compatibility.`
  Acceptance: `Exercise real rendered views, selections and tool actions with source identity and stale-result controls. Test supported host UI capabilities, initialization/lifecycle, loading/error/refusal states, keyboard/accessibility, navigation and useful display sizes. Verify that model-visible context and displayed results stay consistent. Qualify the selected host's fallback behavior without advertising untested cross-host UI parity.`
  Verification: `pending implemented UI and actual host testing`
  Commit: `pending`
  Children: `FSMGEN-CONVERSATIONAL-INTERFACE.4.3.1, FSMGEN-CONVERSATIONAL-INTERFACE.4.3.2`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.4.3.1`
  Status: `blocked`
  Goal: `Qualify source-bound synchronization between UI and conversation.`
  Acceptance: `Exercise actual selections, follow-up prompts, tool actions, refresh and changed/missing/stale source results. Compare displayed and model-visible identities and exact values; coherent wrong-source or stale-result controls must refuse.`
  Verification: `scheduled; prerequisite not complete`
  Commit: `pending`
  Blocked by: `FSMGEN-CONVERSATIONAL-INTERFACE.4.2.3; release to pending after verified committed completion; continue the current eligible priority leaf meanwhile.`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.4.3.2`
  Status: `blocked`
  Goal: `Qualify usability, accessibility and compatibility in the selected host.`
  Acceptance: `Review actual rendering, keyboard/accessibility, navigation, useful display sizes, loading/error/refusal/restart states and the supported host fallback. Record exact host/version limits; advertise only observed UI compatibility.`
  Verification: `scheduled; prerequisite not complete`
  Commit: `pending`
  Blocked by: `FSMGEN-CONVERSATIONAL-INTERFACE.4.3.1; release to pending after verified committed completion; continue the current eligible priority leaf meanwhile.`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.5`
  Status: `active`
  Goal: `Integrate separately selected bounded source-write/generation capabilities if requested later.`
  Children: `FSMGEN-CONVERSATIONAL-INTERFACE.5.1, FSMGEN-CONVERSATIONAL-INTERFACE.5.2`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.5.1`
  Status: `proposed`
  Goal: `Route any new effectful API requirement to the existing MCP horizon owner.`
  Acceptance: `State the desired user operation precisely and compare it with shipped read-only check/report operations. Delegate new core source mutation, HDL/artifact generation or beyond-read-only service selection to SEMANTIC-INTROSPECTION-MCP-WRITE-HORIZON and related canonical owners. Require their selected typed inputs/effects, authorization, path/resource, provenance and failure contracts before plugin implementation. Do not duplicate their API design here or activate them through this proposal.`
  Verification: `pending later effectful-workflow selection; inspection/UI work does not itself authorize it`
  Commit: `pending`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.5.2`
  Status: `proposed`
  Goal: `Adopt qualified effectful tools into conversation and graphical controls.`
  Acceptance: `After canonical API delivery, integrate exact supported candidate/write/generation/artifact operations through the same checked FSMGen pipeline. Verify intended effects, failure isolation, artifact identity/retrieval and actual backend applicability through independent controls. Keep read-only workflows usable and preserve explicit unsupported execution boundaries. Split concrete implementation slices after the selected effect contract exists.`
  Verification: `pending .5.1 and separately qualified API capabilities`
  Commit: `pending`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.6`
  Status: `active`
  Goal: `Qualify and document the complete selected private experience.`
  Children: `FSMGEN-CONVERSATIONAL-INTERFACE.6.1, FSMGEN-CONVERSATIONAL-INTERFACE.6.2`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.6.1`
  Status: `active`
  Goal: `Run end-to-end qualification of the actual installed private plugin and UI.`
  Acceptance: `Join selected tools, schemas, instructions, UI resources and workflows with no unexplained omissions. Test real conversation and graphical actions, actual results/refusals, unsupported requests, connection/resource interruptions and recovery. Require independent semantic/result oracles and observed adverse controls; keep host, source, runtime and capability identities with the evidence. Qualify only the operations and hosts actually tested.`
  Verification: `pending selected private implementation; effectful scope may remain explicitly deferred`
  Commit: `pending`
  Children: `FSMGEN-CONVERSATIONAL-INTERFACE.6.1.1, FSMGEN-CONVERSATIONAL-INTERFACE.6.1.2`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.6.1.1`
  Status: `blocked`
  Goal: `Qualify complete installed private conversational and graphical workflows.`
  Acceptance: `Join selected tools/schemas/instructions/UI resources and real vertical workflows to independent canonical FSMGen results. Retain complete host/source/runtime identities and actual outcomes without unexplained omissions or unsupported cross-host claims.`
  Verification: `scheduled; prerequisite not complete`
  Commit: `pending`
  Blocked by: `FSMGEN-CONVERSATIONAL-INTERFACE.4.3.2; release to pending after verified committed completion; continue the current eligible priority leaf meanwhile.`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.6.1.2`
  Status: `blocked`
  Goal: `Qualify end-to-end refusal, interruption and recovery boundaries.`
  Acceptance: `Exercise unsupported/malformed/stale requests, instance unavailability, authorized permission refusals and resource/connection interruptions. Retain complete outcomes, cleanup and recovery evidence; a killed process restarts only through its supported recovery contract, never an invented checkpoint.`
  Verification: `scheduled; prerequisite not complete`
  Commit: `pending`
  Blocked by: `FSMGEN-CONVERSATIONAL-INTERFACE.6.1.1; release to pending after verified committed completion; continue the current eligible priority leaf meanwhile.`

- ID: `FSMGEN-CONVERSATIONAL-INTERFACE.6.2`
  Status: `blocked`
  Goal: `Deliver accurate private setup, use, limits and recovery documentation.`
  Acceptance: `Document the actual selected host and installation/connection path, graphical and conversational examples, available operations, source/workspace authority, effects and recovery. Synchronize the mdBook and relevant discovery/fact records with tested behavior. Complete focused checks and required commit workflow, leaving a clean recoverable handoff. Task capture or a schema inventory alone is not completed plugin delivery.`
  Verification: `pending qualified private workflows`
  Commit: `pending`
  Blocked by: `FSMGEN-CONVERSATIONAL-INTERFACE.6.1.2; release to pending only after the named prerequisite is verified and committed; continue the current eligible priority leaf meanwhile.`

## Current Frontier

Accepted read-only/client/UI work is scheduled, with its leaves blocked on named
prerequisites. No plugin implementation is currently in progress. The first
future leaf is `.1.1.1`; current execution resumes from `MEMORY.md`.

## Schedule And Release Rules

The **entry schedule gate** requires both:

- The director-selected complete MCP operating-reference delivery owned by
  `PERL-POD-API-REFERENCE` is verified and committed.
- Required SPECFORGE requests `.7`–`.10` and `.12` have their qualified delivery,
  publication and feedback handoff under decision `0121`. Consult
  `docs/SPECFORGE_FEEDBACK_RESPONSE.md` and the canonical owners:
  `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.1`, `.60.2`, `.60.3`, `.60.4`, `.92`
  and `.69`, including `ISF-REDUCTION-DELIVERY.6` for reductions. These request
  numbers are downstream packet IDs, not similarly numbered local task leaves.

After this gate is evidenced, release `.1.1.1` to pending and select it through
normal PNT without asking for another blanket activation. Each later accepted
leaf names its immediate predecessor in `Blocked by`; when that predecessor is
verified and committed, release the successor and continue in that order. A
finished predecessor never satisfies a missing host/account entitlement, actual
UI compatibility or API requirement by implication. Log an actual missing
access/decision when encountered and progress independent work where possible.

The sequence is host/tool/UI qualification, API/workflow mapping, private
packaging/connection/lifecycle, conversational workflows/fidelity, graphical
design/data/views/actions, synchronization/usability, end-to-end qualification
and setup/use/recovery documentation. Each stage has executable child owners in
the node list. No calendar date or duration is promised without evidence.

The `.5` tracking container is open, with its conditional leaves still proposed.
After `.3.2` and `.4.1`, a selected journey that actually needs new writes,
generation or artifact operations triggers `.5.1` to route that requirement to
the existing core owner. `.5.2` follows verified `.5.1` and qualified delivery of
the chosen typed effect contract. Read-only client/UI completion may explicitly
leave that optional scope deferred. Public distribution is outside this private
schedule and needs a separately selected owner if requested later.

## Decisions

- `2026-10-24`: The director requested a dedicated proposed tree during DBIQNP.
  Scope is private use with the director's own FSMGen instance. The explicit
  graphical UI workstream complements the conversational interface.
- `2026-10-24`: The host provides conversation; FSMGen supplies authoritative
  structured operations/results. Conversation and UI share those APIs.
- `2026-10-24`: Reuse the shipped read-only adapter first. Read-only server-transport changes retain
  [the semantic MCP owner](SEMANTIC-INTROSPECTION-MCP-FRONTIER.md); new core
  effects retain [the MCP write horizon](SEMANTIC-INTROSPECTION-MCP-WRITE-HORIZON.md).
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

The entry leaf is blocked by the explicit priority/handoff gate above, and every
successor is blocked by its named predecessor. These are scheduling dependencies,
not observed product failures. The unblock condition is verified committed
completion of the named prerequisite; current MCP reference and required delivery
work run instead. No planning/access blocker prevents this scheduling repair.
Host/account/UI compatibility and new API capability are future qualifications.

## Verification Log

Original capture/documentation checks belong to `PERL-POD-API-REFERENCE.8.3`.
Dependency scheduling and unchanged-current-frontier checks belong to
`PERL-POD-API-REFERENCE.8.4`, with the retained review at
`docs/audits/private-interface-schedule-20261024/`. This is ownership/scheduling
qualification; no plugin implementation, installation, connection, rendered UI
or end-to-end host result is claimed.

## Commit Log

Find the capture commit with
`git log --grep='PERL-POD-API-REFERENCE.8.3:'`.
Find the scheduling commit with
`git log --grep='PERL-POD-API-REFERENCE.8.4:'`.
Released feature leaves use their own permanent work-unit IDs in Git subjects.

## Scheduling Clarification — 2026-10-24

The director required all newly identified activities to be task-treed and
scheduled whenever possible, then agreed to dependency-based scheduling without
changing current implementation priority. DBIQNP preserves execution focus; it
does not excuse leaving accepted future activity unscheduled. This supersedes
the original proposed-only selection wording for the accepted private read-only
client/conversation/UI scope. Planning owner: `PERL-POD-API-REFERENCE.8.4`.
The `.5` optional effects branch and any public-distribution work remain subject
to their own concrete scope/authority selection. No plugin is delivered by this
scheduling change.
