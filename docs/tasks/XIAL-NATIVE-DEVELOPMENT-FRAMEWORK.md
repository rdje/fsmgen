# XIAL-NATIVE-DEVELOPMENT-FRAMEWORK: Complete HIAL/VIAL Development Ecosystem

## Metadata

- Tree ID: `XIAL-NATIVE-DEVELOPMENT-FRAMEWORK`
- Status: `proposed`
- Roadmap lane: `HIAL/VIAL / complete native design-and-verification ecosystem`
- Created: `2026-08-01`
- Last updated: `2026-08-01`
- Owner: repo-local workflow

## Goal

Create a complete native framework in which functional hardware design and
verification can be performed at the xIAL level from first authoring through
intent signoff, without requiring HDL generation or an HDL simulator in the
normal work loop. In this tree, **xIAL** is only a collective notation meaning
HIAL or VIAL (`x = H` or `x = V`); it is not a third language, a new IAL tier,
or a new source suffix.

The framework should make this the primary development loop:

`author/compose HIAL + VIAL -> elaborate/check -> execute in IASIM -> inspect/debug -> measure/close -> regress -> xIAL signoff`

IASIM is the small, independently qualified native execution kernel inside the
framework. The surrounding ecosystem owns projects/workspaces, incremental
semantic builds, reusable HIAL IP and VIAL VIP/packages, authoring services,
simulation sessions, typed semantic traces, interactive debugging and replay,
verification services, coverage closure, regression and triage, visualization,
automation/extension APIs, and durable signoff evidence. HDL/SystemVerilog,
VHDL, PGEN, NEXSIM, and commercial simulators are not prerequisites for the
native inner loop or authorities over xIAL meaning. Production HDL export is
nevertheless a first-class required framework lane for every profile that
promises publishable HDL: it must be standards-conformant, portable,
professionally packaged, and signoff-qualified against IASIM and exact external
tool/profile evidence before users are asked to consume it.

## Non-Goals

- Do not activate or implement the framework in this capture. This tree records
  the expanded product direction and begins with architecture selection.
- Do not make `xIAL` a new source language or rename HIAL, VIAL, IAL0, IAL1, or
  IAL2. It is shorthand for surfaces shared across HIAL and VIAL.
- Do not turn IASIM into a monolith. Its semantic kernel, reference engine, and
  native signoff remain independently owned by
  `IASIM-EXECUTABLE-REFERENCE-SEMANTICS`; framework services consume a stable,
  versioned kernel/session API.
- Do not require generated HDL, a UVM/VHDL library, an HDL parser, or an HDL
  simulator for authoring, execution, debugging, coverage, regression, or xIAL
  functional/intent signoff.
- Do not interpret that native-loop independence as permission to weaken or
  defer supported HDL export. If FSMGen advertises an xIAL-to-HDL profile, its
  standards compliance, lowering correctness, source quality, portability,
  packaging, and executable evidence are mandatory product signoff obligations.
- Do not claim that xIAL functional/intent signoff is synthesis, equivalence,
  CDC/RDC, STA, DFT, power, analog, place-and-route, manufacturing, or silicon
  signoff. Those remain explicit downstream proof layers unless a future
  native contract models and qualifies them.
- Do not require a network service or global package registry. Offline,
  repository-local, same-volume workflows are the baseline; remote/distributed
  services are later explicit profiles.
- Do not freeze the ecosystem into one UI. A shared typed service/API model may
  support CLI, TUI, IDE, web, and automation clients without giving any client
  separate semantic authority.

## Acceptance Criteria

- A versioned framework architecture defines the complete xIAL design and
  verification lifecycle, service boundaries, artifact graph, trust model,
  compatibility rules, and exact relationship to the IASIM kernel.
- Workspaces compose HIAL designs, VIAL environments, configurations,
  scenarios/tests, packages, reusable HIAL IP, reusable VIAL VIP, native
  extensions, run profiles, and signoff policies through repository-relative,
  reproducible manifests and lockable dependency identities.
- One incremental semantic build graph parses, validates, elaborates, binds,
  caches, invalidates, and explains xIAL meaning without forcing HDL emission.
- Authoring services provide canonical formatting, diagnostics, navigation,
  completion/introspection contracts, source maps, semantic queries, refactors
  where safe, and exact normal/terse equivalence through shared compiler truth.
- IASIM sessions support batch and interactive execution, start/run/step/pause,
  breakpoints/watchpoints, seed/replay, checkpoints, bounded rewind where
  selected, controlled fault injection, and deterministic result publication.
- A typed semantic trace store captures xIAL domains, state, transitions,
  values, events, transactions, scenarios, model/scoreboard decisions,
  assertions, coverage, faults, diagnostics, and source/provenance links. It is
  queryable without decoding HDL waves or simulator-specific databases.
- Debugging can answer not only *what changed* but *why*: causal predecessors,
  active intent/rule, source span, old/new value, trigger, competing updates,
  property/model/scoreboard rationale, and reproducible route back to the run.
- Verification services cover stimulus/scenarios, monitors, assertions and
  temporal checks, transactions/events, reference models, scoreboards,
  constrained decisions, coverage, fault injection, reproducible randomness,
  waivers, and normalized results entirely in native xIAL terms.
- Regression orchestration owns tests/configurations/seeds, selection and
  sharding, bounded parallelism, deterministic caching, retry policy,
  checkpoints, result collection, comparison/baselines, failure clustering,
  triage, issue-bundle export, retention, and exact reproduction commands.
- Native signoff owns requirements/plan linkage, semantic and verification
  coverage closure, exclusions/waivers with provenance and expiry, regression
  stability, residual risk, exact engine/framework/profile identities, and a
  reproducible signed-off result manifest. Claims remain scoped to xIAL intent.
- Visualization and clients consume the same typed APIs for hierarchy,
  topology, timelines, state machines, transactions, causality, coverage,
  failures, and signoff dashboards without becoming semantic authorities.
- Extension APIs are typed, capability-gated, deterministic where required,
  sandboxable, source-mapped, versioned, and unable to bypass validation,
  locality, resource, provenance, or signoff controls.
- Production HDL export has exact supported language/revision/profile matrices,
  deterministic readable source and packaging, complete source maps,
  standards-conformance vectors, lint and warning policy, parser/compile/
  elaboration/runtime qualification, IASIM differential parity, synthesis and
  equivalence evidence where applicable, multi-tool portability evidence,
  diagnostics, compatibility/versioning, and publishable conformance manifests.
  Discrepancies remain classified by intent, tier lowering, backend generation,
  parser/elaboration, runtime, synthesis, or unsupported capability.
- The framework is bounded, observable, secure by default, repository-local,
  same-volume, crash-recoverable, scalable, thoroughly tested, and documented
  through runnable xIAL-only mdBook examples.
- Each completed active leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `XIAL-NATIVE-DEVELOPMENT-FRAMEWORK`
  Status: `proposed`
  Goal: `Deliver a complete HDL-independent HIAL/VIAL design, verification, debug, regression, and native-signoff ecosystem around the IASIM kernel.`
  Children: `XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.1, XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.2, XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.3, XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.4, XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.5, XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.6, XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.7, XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.8, XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.9, XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.10, XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.11, XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.12, XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.13, XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.14, XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.15`

- ID: `XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.1`
  Status: `proposed`
  Goal: `Select the complete xIAL-native product architecture, workflows, boundaries, service model, and phased delivery plan.`
  Acceptance: `Audit current HIAL/VIAL source, semantic IR, bridge, execution IR, tooling, traces/results, introspection, issue bundles, examples, and docs; define representative design, verification, debug, regression, reuse, and signoff user journeys; inventory missing services; define IASIM kernel versus framework ownership, semantic-authority boundaries, artifact and compatibility/version tuples, batch/interactive/client APIs, locality/security/resource rules, native versus downstream signoff claims, staged MVP-to-complete sequencing, risks, alternatives, and exact non-goals. Selection only; no implementation.`
  Verification: `pending`
  Commit: `pending`

- ID: `XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.2`
  Status: `proposed`
  Goal: `Implement reproducible xIAL projects, workspaces, dependency locks, configurations, and the incremental semantic build graph.`
  Acceptance: `Support repository-relative manifests for HIAL/VIAL sources, tops/environments, packages, configurations, scenarios, run/signoff profiles, resources, extensions, and optional backends; select offline/local package identities and lock semantics; implement dependency discovery, incremental parse/validate/elaborate/bind invalidation, deterministic caches, explanation, atomic state, cleanup, and crash recovery without HDL generation.`
  Verification: `pending`
  Commit: `pending`

- ID: `XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.3`
  Status: `proposed`
  Goal: `Ship shared native xIAL authoring, validation, navigation, and semantic-introspection services.`
  Acceptance: `Expose canonical formatting, check/diagnostics, source maps, symbol/type/hierarchy/intent navigation, completion/query contracts, safe refactors where selected, normal/terse equivalence, and machine-readable semantic projections through one compiler-owned service layer; CLI/IDE/other clients receive identical truth and bounded incremental updates.`
  Verification: `pending`
  Commit: `pending`

- ID: `XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.4`
  Status: `proposed`
  Goal: `Establish reusable versioned HIAL IP, VIAL VIP, protocol, scenario, model, coverage, and utility packages.`
  Acceptance: `Define typed package namespaces, versions, parameters/configuration, capability requirements, documentation/examples, dependency locks, source/provenance identities, compatibility checks, qualification levels, local catalogs, vendoring/export, and conformance suites; prove reusable HIAL components and VIAL verification components compose without leaking HDL/UVM/VHDL mechanisms into authorship.`
  Verification: `pending`
  Commit: `pending`

- ID: `XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.5`
  Status: `proposed`
  Goal: `Integrate IASIM through one stable native execution/session/control API for batch and interactive clients.`
  Acceptance: `Consume exact IASIM semantics/engine/profile identities; support create/elaborate/start/run/step/pause/stop, breakpoints/watchpoints, seeds/replay, checkpoints and bounded rewind where selected, resource/time/event limits, cancellation, diagnostics, state/query snapshots, deterministic normalized results, and concurrent-session isolation; keep client and orchestration policy outside the semantic kernel.`
  Verification: `pending`
  Commit: `pending`

- ID: `XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.6`
  Status: `proposed`
  Goal: `Implement the typed xIAL semantic trace, provenance, and query database.`
  Acceptance: `Record hierarchy/domains/state/values/transitions/events/transactions/scenarios/model and scoreboard decisions/assertions/coverage/faults/random choices/diagnostics with logical time, source maps, causality, engine/profile/source identity, indexes, bounded retention, streaming and post-run access, stable queries, atomic publication, and deterministic export; no HDL waveform database is required.`
  Verification: `pending`
  Commit: `pending`

- ID: `XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.7`
  Status: `proposed`
  Goal: `Ship source-level xIAL debugging, causal explanation, checkpoints, and deterministic time-travel workflows.`
  Acceptance: `Provide source/hierarchy/state/transaction breakpoints and watchpoints; step by intent action, logical phase, event, transaction, or domain tick; inspect current and historical values; explain why transitions, updates, checks, model decisions, and failures occurred; navigate causal predecessors and competing updates; reproduce from exact checkpoint/seed/profile; prove bounded rewind semantics and honest unavailable-history diagnostics.`
  Verification: `pending`
  Commit: `pending`

- ID: `XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.8`
  Status: `proposed`
  Goal: `Complete native VIAL verification services and their tight integration with HIAL/IASIM execution.`
  Acceptance: `Support typed stimulus/scenarios/fibers, transactions/events, monitors, assertions/temporal checks, reference models, scoreboards, constrained decisions, coverage, controlled faults, reproducible randomness, configuration/substitution, requirements links, diagnostics, normalized results, and reusable VIP entirely in xIAL terms; every service is source-mapped, capability-gated, inspectable, replayable, and represented in semantic traces.`
  Verification: `pending`
  Commit: `pending`

- ID: `XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.9`
  Status: `proposed`
  Goal: `Implement deterministic local-first xIAL regression orchestration, collection, comparison, and triage.`
  Acceptance: `Define tests/configurations/seeds/matrices, selection, filtering, sharding, bounded parallelism, deterministic caching, cancellation/retry, checkpoint reuse, resource budgets, normalized collection, baselines/comparison, failure fingerprinting/clustering, flaky-run policy, triage annotations, issue bundles, retention, exact reproduction, and optional capability-gated distributed execution without requiring HDL tools.`
  Verification: `pending`
  Commit: `pending`

- ID: `XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.10`
  Status: `proposed`
  Goal: `Implement native coverage closure, waiver governance, requirements evidence, and xIAL signoff manifests.`
  Acceptance: `Aggregate semantic/rule/state/transition/transaction/scenario/assertion/model/scoreboard/functional coverage as selected; link requirements/plans/tests/results; expose holes and unreachable/excluded bins; govern waivers with reason/owner/provenance/expiry; require stable regressions and residual-risk review; emit exact reproducible framework/engine/profile/source/seed/capability/evidence identities; clearly scope the claim to native xIAL functional/intent signoff.`
  Verification: `pending`
  Commit: `pending`

- ID: `XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.11`
  Status: `proposed`
  Goal: `Ship responsive client-neutral visualization for structure, behavior, causality, coverage, regressions, and signoff.`
  Acceptance: `Provide typed views or view models for hierarchy/topology, FSMs, timelines, values, events/transactions, scenarios, causal chains, models/scoreboards, assertion failures, coverage holes, regression clusters, and signoff status; support large-data filtering/aggregation and stable deep links to sources/runs; CLI/TUI/IDE/web clients share service truth and no renderer gains semantic authority.`
  Verification: `pending`
  Commit: `pending`

- ID: `XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.12`
  Status: `proposed`
  Goal: `Define safe typed automation, plugin, extension, and external-tool integration surfaces.`
  Acceptance: `Expose versioned APIs for workspace/build/query/session/trace/debug/regression/signoff operations; define capability and permission boundaries, deterministic/pure versus effectful calls, sandboxing, repository roots, resource limits, provenance, cancellation, schema evolution, fixtures, and compatibility tests; integrate native extensions without raw target-language leakage or bypass of validation/signoff controls.`
  Verification: `pending`
  Commit: `pending`

- ID: `XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.13`
  Status: `proposed`
  Goal: `Deliver production-grade standards-conformant xIAL-to-HDL export and signoff qualification for every supported publishable profile.`
  Acceptance: `Select exact SystemVerilog/VHDL and methodology standard revisions and support matrices; generate deterministic efficient readable professionally structured source/packages with complete source maps and compatibility identities; prove applicable LRM conformance, clean lint/warning policy, parser/compile/elaboration/runtime behavior, IASIM normalized differential parity, HIAL synthesis and semantic/equivalence evidence, VIAL methodology behavior, and portability across exact qualified independent tools; publish artifacts, documentation, conformance manifests, limits, waivers, and reproduction commands suitable for downstream user consumption and testing. Keep HDL qualification mandatory for advertised export profiles while never making it the authority over native xIAL meaning or a prerequisite for the native inner loop.`
  Verification: `pending`
  Commit: `pending`

- ID: `XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.14`
  Status: `proposed`
  Goal: `Qualify framework scale, responsiveness, reliability, isolation, storage lifecycle, and recoverability.`
  Acceptance: `Measure representative small/large projects and regressions across semantic build, execution, traces, queries, debug, coverage, triage, visualization data, and signoff; set wall/CPU/RSS/storage/latency budgets, graceful ceilings, cancellation, corruption detection, atomicity, cache/trace retention, crash recovery, concurrent-session isolation, deterministic reruns, locality census, and stable regression gates.`
  Verification: `pending`
  Commit: `pending`

- ID: `XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.15`
  Status: `proposed`
  Goal: `Complete xIAL-only examples, user/developer documentation, migration, support accounting, and ecosystem closeout.`
  Acceptance: `Publish runnable no-HDL design-through-signoff examples, workspace/package/IP/VIP authoring, interactive debug, coverage closure, regression/triage, automation, and optional backend-differential guides; document every command/API/artifact/profile/capability/limit/non-claim and framework-versus-IASIM responsibility; synchronize roadmap, task trees, decision records, Knowledge Map, mdBook, support accounting, diagnostics, release/compatibility policy, and all signoff gates.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

This framework is proposed and not PNT-eligible until the roadmap or director
explicitly activates it. Architecture selection `.1` must precede any product,
workspace, service, library, debugger, regression, UI, or signoff implementation.
The IASIM semantic kernel remains independently proposed under
`IASIM-EXECUTABLE-REFERENCE-SEMANTICS`.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.1` | `proposed` | Turn the director's complete xIAL ecosystem requirement into exact user journeys, service and trust boundaries, IASIM integration, proof claims, and a bounded delivery sequence before implementation. |

## Decisions

- `2026-08-01`: Define **xIAL** as collective notation for HIAL or VIAL, with
  `x = H` or `x = V`. It is not a new language, tier, or file format.
- `2026-08-01`: The objective is a complete framework/ecosystem, not merely an
  IASIM command: all ordinary functional design and verification work should be
  possible through native xIAL services without an HDL dependency.
- `2026-08-01`: Keep IASIM as the small independently qualified execution
  kernel. The framework owns rich workflows and clients through one versioned
  kernel/session API so convenience features cannot silently redefine meaning.
- `2026-08-01`: Treat reusable HIAL IP and VIAL VIP/packages as first-class
  ecosystem assets with exact versions, dependencies, capabilities,
  qualification, docs, and conformance evidence.
- `2026-08-01`: Native xIAL functional/intent signoff is a first-class exact
  claim. HDL export does not define that claim, but every advertised publishable
  HDL profile has a separate mandatory standards/conformance/quality/runtime
  signoff obligation. Physical-design proof layers remain separately scoped and
  must never be inferred from either claim.
- `2026-08-01`: Use one typed service truth for batch, CLI, IDE, TUI, web, and
  automation clients; presentation layers do not own semantics.

## Open Questions

- Which two or three end-to-end user journeys form the smallest coherent first
  framework profile: interactive HIAL state-machine debug, HIAL+VIAL AHB
  verification/coverage, or reusable IP/VIP workspace composition?
- Should framework/workspace APIs remain under `fsmgen`, gain an umbrella
  product command, or expose a daemon/service only as an optional client layer?
- Which current VIAL intent families must be authorable before the first native
  framework profile can claim a complete design-to-signoff loop?
- What package identity and offline dependency-lock model best fits repository-
  local HIAL IP and VIAL VIP before any optional registry exists?
- What minimum history/checkpoint model gives useful time-travel debugging
  without making trace storage unbounded?
- Which physical/implementation facts should eventually be reflected back into
  xIAL without allowing downstream HDL tools to become native semantic authority?
- Which exact HDL language revisions, tool diversity, warning policy,
  synthesis/equivalence gates, and portability thresholds define the first
  professional publishable export signoff profile?

## Blockers

- None for architecture selection. The framework is intentionally proposed
  until selected by roadmap/director priority. IASIM kernel implementation is
  a delivery dependency for native execution, but not a blocker to the `.1`
  architecture and user-journey audit.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-08-01` | `XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.1` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.1` | `pending` | Proposed architecture/product-boundary selection only; no framework implementation selected. |

## Changelog

- `2026-08-01`: Captured the director's requirement for a complete xIAL-native
  framework around IASIM so the ecosystem scope does not collapse into a
  standalone simulator command or remain only in session chat.
