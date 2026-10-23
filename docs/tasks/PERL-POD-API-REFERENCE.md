# PERL-POD-API-REFERENCE: Generate and integrate the Perl API reference

## Metadata

- Tree ID: `PERL-POD-API-REFERENCE`
- Status: `active`
- Roadmap lane: `R13 / documentation and embedding`
- Created: `2026-10-23`
- Last updated: `2026-10-23`
- Owner: repo-local workflow

## Goal

Implement the director's explicit request for a POD-generated FSMGen API
reference linked from the mdBook. Generate the reference from repository-owned
Perl modules, document the supported entry points, distinguish implementation
documentation from supported interfaces, and keep generated pages reproducible
and synchronized with their inputs.

The prior constructor preparation is committed at `5de680064`; reusable width
work resumes at `ISF-REDUCTION-DELIVERY.2.3.2.4.2` after this requested task.
The director further requires a thorough human/AI-agent operating reference for
every shipped MCP surface; .6 owns that explicit extension after the clean
initial delivery c63f76753. This 2026-10-23 priority exception does not waive existing publication,
HIAL, claim, locality, or source-feature signoff gates.

## Non-Goals

- No new DSL, HDL, simulation, MCP mutation, or execution capability.
- No expansion of API stability beyond the existing published contracts.
- No dependency/submodule implementation scan or documentation generation.
- Generated reference coverage must not silently turn missing internal POD
  into a claim of complete API documentation; classify and own any such debt.

## Acceptance Criteria

- Normal mdBook build/serve generates and includes the API reference.
- A book landing page and generated index give working relative navigation
  between the manual, supported entry points, and available module POD.
- Use `Pod::Simple::HTMLBatch` through its public interfaces; all generated
  files, caches, fixtures, and workspaces stay on the repository volume.
- Reject malformed POD, broken generated local links, stale/incomplete output,
  and unsafe source/output paths with meaningful adverse controls.
- Repeated generation under the same inputs/tool versions is byte-identical;
  timestamps and private absolute checkout paths do not leak into output.
- Supported facade POD describes current signatures, return/error boundaries,
  side effects, stability, and independently checked runnable examples.
- Document the actual provided-POD and supported-entry coverage without
  inferring full method semantics from headings or file counts.
- Update the book, relevant discovery/build instructions, task state, and
  generated projections; pass focused checks and required doctrine gates.
- The MCP operating reference covers every published method, tool, resource,
  template, request/result schema, field meaning, refusal/error, limit and
  lifecycle/transport boundary. Humans and external agents can discover, select
  and use the supported operations from this reference with tested examples.
- Temporal inspection, source semantics, schedule prediction and actual
  simulation/execution are described precisely, including availability limits;
  documentation must never imply an unimplemented authoring or execution tool.
- An explicit source/runtime/schema/documentation coverage join detects omitted
  MCP surfaces and protects the reference as capabilities evolve.
- Commit each slice before its successor. Hosted publication retains the
  standing full-CI and exact-SHA requirements.

## Task Tree

- ID: `PERL-POD-API-REFERENCE`
  Status: `active`
  Goal: `Deliver a reproducible POD API reference through the native mdBook workflow.`
  Children: `PERL-POD-API-REFERENCE.1, PERL-POD-API-REFERENCE.2, PERL-POD-API-REFERENCE.3, PERL-POD-API-REFERENCE.4, PERL-POD-API-REFERENCE.5, PERL-POD-API-REFERENCE.6`

- ID: `PERL-POD-API-REFERENCE.1`
  Status: `done`
  Goal: `Inventory actual POD and supported entry points; select the bounded generation contract.`
  Acceptance: `Query canonical API/book contracts, classify repository-owned Perl source files independently of POD presence, validate actual POD through the installed public parser/checker APIs, and retain complete source/input/tool identities and diagnostics. Select public entry points from existing contracts rather than every callable subroutine. Own every discovered malformed-POD/link/documentation gap and refine successor scopes before generator edits. Record the HTMLBatch/mdBook build, locality, reproducibility, asset/freshness and coverage boundaries. Commit the audit/contract before implementation.`
  Verification: `Saved docs/audits/pod-api-20261023 inventory and independent Git-boundary reader join all 399 module paths and source hashes; 107 contain POD, 292 lack POD, and 3 contain missing-encoding errors (the remaining 104 are clean). Malformed-POD and no-content adverse controls pass. No runtime modules were loaded.`
  Commit: `PERL-POD-API-REFERENCE.1: qualify source POD inventory and generation contract`

- ID: `PERL-POD-API-REFERENCE.2`
  Status: `done`
  Goal: `Implement deterministic safe HTMLBatch generation and reference validation.`
  Acceptance: `Use repository-owned source snapshots and public POD interfaces to render the provided module POD, index and navigation. Bind output to complete relevant inputs/tool versions, keep paths relative and caches local, detect stale/missing/extra output, and protect unowned/symlinked/foreign paths. Prove ordinary generation, repeat identity, actual cross-page/fragment links and targeted malformed/stale/path controls. Split an unsafe expansion before implementation, synchronize build guidance, and commit before public-POD completion.`
  Verification: `Real HTMLBatch generator passes 12 Python fixture tests: local cross-page/fragment and no-POD links, nonexecution, fresh-render byte identity, no-write cache hit, stale sources, malformed diagnostics, incomplete/modified/extra output, symlink/nested-Git paths, unsafe manifests/URLs and lock contention. Production generation correctly refuses the .1-owned encoding errors without publishing. Perl syntax passes.`
  Commit: `PERL-POD-API-REFERENCE.2: generate and validate deterministic POD reference`

- ID: `PERL-POD-API-REFERENCE.3`
  Status: `done`
  Goal: `Complete supported entry-point POD and repair blocking existing POD defects.`
  Acceptance: `Follow the inventory's explicit facade set and existing API contracts. Write accurate POD for signatures, supported options, return shapes, errors, effects, stability and runnable examples; preserve all runtime code and established boundaries. Fix every existing POD defect that blocks correct generation. Explicitly classify and schedule internal documentation gaps without falsely advertising completeness. Verify actual API examples and parser/rendered coverage, update book discovery and commit.`
  Verification: `Production generation and freshness check succeed; 399 module pages join to 112 provided-POD and 287 explicit no-POD entries. All six selected facades have POD and their extracted synopses execute with independently checked results. Three encoding declarations repaired. All nine changed module files conserve lexical code outside POD versus bb969f7ac. Existing facade cohort passes Files=6, Tests=20; generator controls remain green. Saved source/snippet hashes and readers are under docs/audits/pod-api-20261023.`
  Commit: `PERL-POD-API-REFERENCE.3: document supported Perl bindings and repair POD encoding`

- ID: `PERL-POD-API-REFERENCE.4`
  Status: `done`
  Goal: `Integrate reference generation, styling and navigation into normal mdBook build/serve.`
  Acceptance: `Add the native build integration and a book landing/sidebar route, with matching readable responsive styling and relative manual/module backlinks. Support documented invocations from repository root and book directory; watch source changes without an infinite rebuild loop. Keep generated output ignored/local and synchronize README/build/tool guidance only where their contracts change. Verify native built delivery, complete source/index contracts, fresh output after an input change and browser/rendered readability, then commit.`
  Verification: `Native root/book-cwd builds, independent complete source/coverage/copied-byte/link join, actual loopback serve refresh and Chrome guide/module/index/anchor/backlink checks pass. Narrow observed pages have viewport/document width 390/390. Fresh relocated root with spaces independently regenerates identical reference bytes; native malformed/missing-output refusals preserve prior output and explicit repair restores exact bytes. Probe restores stylesheet, resets viewport, closes tab/server; stopped listener confirmed. All captured observations/readers and original failures retained in docs/audits/pod-api-20261023.`
  Commit: `PERL-POD-API-REFERENCE.4: integrate POD reference with native mdBook delivery`

- ID: `PERL-POD-API-REFERENCE.5`
  Status: `done`
  Goal: `Qualify complete reference delivery and restore the saved feature frontier.`
  Children: `PERL-POD-API-REFERENCE.5.1, PERL-POD-API-REFERENCE.5.2, PERL-POD-API-REFERENCE.5.3`
  Acceptance: `Independently join the declared source/POD/facade population to generated pages and working local links, run documented examples and ordinary native book builds, and verify repeatability, freshness, locality and relevant broader regression. Retain precise coverage boundaries and all original failures. Complete required doctrine/commit checks, leave the tree clean and message empty, and resume the preserved reusable-width frontier. No unqualified hosted publication or API/runtime expansion.`
  Verification: `Completed .5.1 discovery, .5.2 executable CI guard and .5.3 runtime-bound final native qualification. Full source/coverage/copied-byte/link joins, complete fixture controls, fresh relocated builds, native refusal retention/repair and no-write reuse pass. Existing publication/legacy-link/whole-manual visual limits remain explicitly owned; restore ISF-REDUCTION-DELIVERY.2.3.2.4.2 after the clean commit.`
  Commit: `PERL-POD-API-REFERENCE.5.3: qualify runtime-bound POD reference delivery`

- ID: `PERL-POD-API-REFERENCE.5.1`
  Status: `done`
  Goal: `Make POD reference discovery durable within the existing Knowledge Map bounds.`
  Acceptance: `Add an atomic dated POD reference signpost. Preserve every existing fact/question and exact historical retrieval while removing the redundant fact-directory installer README pointer and retaining its full authoring guidance at the bundle entrypoint. Copy-edit only redundant wording in the related historical mdBook card as needed; retain all source meanings, metadata and questions with explicit before/after evidence and adverse controls. Do not raise any Knowledge Map allowance/ceiling. Prove query/parity/current-source checks and commit.`
  Verification: `New atomic signpost/query resolves to the canonical API guide. Whole Git-archive/source membership and bytes preserve every other card; contained historical card retains identical metadata/questions and all reviewed body meanings. Every old query row survives, with exactly the new POD question added. Actual omission/owner/location/metadata controls reject. Collection remains within its unchanged authority; no allowance or ceiling changes. Knowledge Map parity/check passes; unchanged historical saved reader verifies exact book recovery while worker/operational admission stays false and owned by HIAL.`
  Commit: `62a314b7f`

- ID: `PERL-POD-API-REFERENCE.5.2`
  Status: `done`
  Goal: `Guard actual facade POD examples in the existing CI fixture workflow.`
  Acceptance: `Promote the checked synopsis runner to a canonical script with isolated same-volume workspaces, retain the dated audit command as a compatibility route, and add a meaningful CI-discovered actual-example check. Execute source snippets and validate concrete public results, not copied headings or only exit codes. Keep runtime execution separate from documentation rendering, preserve previous capture identities and verify genuine malformed/invalid example controls before committing.`
  Verification: `Canonical isolated checker and existing audit compatibility command execute all six actual synopses with concrete result checks; evidence bytes match the prior real capture. The existing CI glob discovers seven example controls; all 19 generator/example tests and three relevant Perl contract files pass. Exact old-observer reproduction accepts counterfeit Boolean version true; current checker refuses it while accepting numeric 1 and 1.0. Timeout/invalid-program/wrong-result/stderr controls retain exact failure evidence.`
  Commit: `15fc3dadf`

- ID: `PERL-POD-API-REFERENCE.5.3`
  Status: `done`
  Goal: `Close complete POD reference qualification and restore the saved feature frontier.`
  Acceptance: `Bind the generating Python runtime identity into the cache fingerprint with a genuine missing/stale-runtime RED/GREEN control. Independently rejoin all source/POD/selected-facade populations to final generated/copied/native links, check examples, output freshness, no-write reuse, relevant regression and current book/source/index/doctrine contracts. Retain limits and original failures, commit the clean delivery, and restore ISF-REDUCTION-DELIVERY.2.3.2.4.2. No unqualified push or closure of separately owned legacy/manual/historical gates.`
  Verification: `The fixed runtime test first fails on the genuine missing Python field, then passes with real implementation/release identity. Missing/stale-runtime controls refuse without asset writes and ordinary regeneration restores exact bytes. All 20 generator/example tests pass. Production transition preserves every source/rendered-output hash; only the expected manifest changes. Final independent native delivery joins 399 sources, 112 POD/287 explicit no-POD pages, six selected guides and 404 copied members across 3975 local href/fragment checks. Current check/generate/native build conserve all reference bytes and mtimes. Fresh same-volume root with spaces repeats complete bytes, both cwd forms, genuine malformed/missing native refusals and explicit owned repair. Native source/index/build checks and required doctrines/hooks gate the commit. Exact packets and executable readers are retained; hosted/platform/whole-manual scopes stay unqualified.`
  Commit: `PERL-POD-API-REFERENCE.5.3: qualify runtime-bound POD reference delivery`

- ID: `PERL-POD-API-REFERENCE.6`
  Status: `active`
  Goal: `Deliver a complete operating reference for humans and AI agents using the shipped FSMGen MCP server.`
  Children: `PERL-POD-API-REFERENCE.6.1, PERL-POD-API-REFERENCE.6.2, PERL-POD-API-REFERENCE.6.3, PERL-POD-API-REFERENCE.6.4, PERL-POD-API-REFERENCE.6.5, PERL-POD-API-REFERENCE.6.6, PERL-POD-API-REFERENCE.6.7`
  Acceptance: `Follow the director's explicit 2026-10-23 thoroughness requirement. Join every published protocol/API surface to precise current behavior, data contracts, constraints, errors and tested human/agent workflows. Use POD for Perl/API reference and mdBook for accessible client guidance, with one clearly linked authority per fact. No empty inventory or schema-only stub counts as operational documentation. Split each broad cohort before implementation, preserve existing producer and protocol limitations, and commit each completed slice.`
  Verification: `Initial renderer, selected binding POD and native delivery are committed through c63f76753. Complete MCP operational coverage is not yet qualified; .6.1 establishes the exhaustive inventory and documentation-gap matrix.`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1`
  Status: `active`
  Children: `PERL-POD-API-REFERENCE.6.1.1, PERL-POD-API-REFERENCE.6.1.2`
  Goal: `Inventory every shipped MCP surface and select exact documentation cohorts.`
  Acceptance: `Query canonical MCP decisions/facts; read the public adapter, launcher, contract/schema producers and existing manual/tests. Independently join actual initialized capabilities, methods, tools/list, resources/list, templates/list, schema snapshots, source-query applicability and typed inspection contracts. Inventory request/result fields, constraints/defaults/limits/errors and links to their current documentation; explicitly mark gaps without treating a name or schema alone as sufficient explanation. Preserve source/runtime identities and original observations. Refine .6.2-.6.7 into safe exact leaves before edits, register defects and availability gaps under existing owners, and commit the audit plus durable frontier.`
  Verification: `The incoming request is explicit authority to continue POD/MCP documentation ahead of the saved ISF frontier. Existing Knowledge Map MCP routes were retrieved during the preceding clean-commit handoff; complete census and operational documentation-gap review remain pending.`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.1`
  Status: `active`
  Children: `PERL-POD-API-REFERENCE.6.1.1.1, PERL-POD-API-REFERENCE.6.1.1.2`
  Goal: `Reproduce and repair any persistent stdio response-buffering defect before documenting client workflows.`
  Acceptance: `The adapter's run_stdio prints responses to a pipe without an explicit flush; verify with a real persistent subprocess that keeps stdin open and waits for its first response. Retain the exact request/raw response/process outcome before EOF and after orderly EOF, source/runtime identities and a competing EOF-only control. If buffering is confirmed, repair only transport response delivery without changing report bytes, IDs or notification behavior. Add an actual open-pipe regression, qualify custom handles and relevant existing transport/schema/source-failure tests, synchronize POD/book and commit before continuing the census.`
  Verification: `Source review finds no explicit flush in launcher/run_stdio; persistent-pipe behavior is not yet measured. This is a suspected client-driving blocker, not a confirmed failure or timing guarantee.`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.1.1`
  Status: `done`
  Goal: `Commit the verified persistent response-flush repair and actual open-pipe regression.`
  Acceptance: `Complete .6.1.1's transport repair with real launcher/custom-handle RED/GREEN, independent forced-flush control, exact response-byte conservation, orderly EOF and unchanged selected/buffering state. Retain the broader cohort's exact original outcome. If its snapshot failure reproduces with the byte-exact predecessor adapter and complete projection equality, own that separate fixture issue in immediate successor .6.1.1.2 instead of disguising it as a passing broad gate. Commit the verified scoped transport repair before that fixture successor.`
  Verification: `Both live regressions fail before repair and pass afterward. Actual launcher/default-adapter probes lack a reply before EOF while forced autoflush succeeds; after repair all three stream and complete reply bytes conserve. The broader cohort passes 22 files but t/1445's first sample-entry key differs from its saved fixture. The byte-exact predecessor reproduces the snapshot failure and its complete projected products equal the repaired adapter. This independent pre-existing fixture failure is owned by immediate successor .6.1.1.2; no broad green claim.`
  Commit: `PERL-POD-API-REFERENCE.6.1.1.1: flush persistent MCP responses before reading again`

- ID: `PERL-POD-API-REFERENCE.6.1.1.2`
  Status: `pending`
  Goal: `Resolve the MCP schema snapshot's sample-dependent catalog projection failure.`
  Acceptance: `Reproduce the exact t/1445 failure using the original adapter and compare complete projected products before/after the flush-only repair. Trace the differing support-summary sample fields to actual catalog selection, history and its public optional-field contract. Repair the smallest correct observation/fixture contract, preserving strict protocol/schema coverage and meaningful real catalog checks; never blindly regenerate a fixture or weaken assertions to obtain green. Add a real catalog-variant/ordering control where warranted, qualify the fixed snapshot plus relevant cohort, synchronize public field guidance and commit before the exhaustive census.`
  Verification: `Current broader gate reports first support-summary sample keys diagnostic_code versus family. probe_snapshot.py really reruns the original assertion/projector with the byte-exact c63f76753 adapter and the current adapter: both fail and complete projections are identical. Fixture/catalog root cause and correct repair remain pending; no product schema change is inferred.`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2`
  Status: `pending`
  Goal: `Complete the exhaustive public-surface and documentation-gap census after transport admission.`
  Acceptance: `Perform the full .6.1 census and refine every successor from actual published methods/tools/resources/templates/schema/query applicability. Retain complete source/runtime/schema identities, current documentation locations, unexplained gaps and explicit owned limitations; no schema/name-only stub counts as reference completion. Commit the audit before operational-reference edits.`
  Verification: `pending persistent stdio qualification`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.2`
  Status: `pending`
  Goal: `Document connection, lifecycle, protocol and host safety contracts completely.`
  Acceptance: `After .6.1, split exact cohorts as needed. Cover launcher/configuration and roots, one-shot versus persistent stdio, UTF-8 framing, handshake/version/capabilities, discovery, requests/notifications/IDs, server shutdown, pagination/progress/cancellation/concurrency and all unavailable negotiated features. Describe actual behavior and error envelopes with executable success/refusal examples. Compare pinned official MCP requirements where relevant, own real discrepancies, preserve existing implementation scope and qualify native rendering before each commit.`
  Verification: `pending exhaustive inventory`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.3`
  Status: `pending`
  Goal: `Document every tool, static resource and resource template at field and operation level.`
  Acceptance: `After .6.1, create bounded leaves for the complete discovered operation population. Give purpose, selection/applicability, every argument/query parameter/default/enum/range/encoding rule, result envelope and field semantics, failures, side effects, stability and tool/resource equivalence or differences. Cross-link actual input/output schemas and underlying public data contracts; include successful and refusal examples through the real server. No discovered surface may be omitted or represented only by an auto-generated name/schema.`
  Verification: `pending exhaustive operation population`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.4`
  Status: `pending`
  Goal: `Document complete public result-model interpretation and source/query applicability.`
  Acceptance: `Split from .6.1's exact report/schema cohorts. Explain public identities, source locations/provenance, diagnostics, capability/support evidence, normalized hardware versus source/schedule/VIAL data and typed nested records. Describe versioning, units, ordering, optional/null/absent fields and extension boundaries where applicable. Link authoritative field dictionaries/schemas and worked reports; never expose private compiler objects as a supported API. Verify against complete actual outputs and independent semantic expectations, including refusal behavior.`
  Verification: `pending result-model and schema inventory`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.5`
  Status: `pending`
  Goal: `Provide complete agent/human workflows including temporal questions and current execution limits.`
  Acceptance: `Build discover/select/check/inspect/schedule/diagnose/recheck workflows using real current tools/resources and explicit goal/decision/output examples. Explain source temporal declarations, typed lifecycle conditions/action bodies, schedule timing and any actual temporal execution access separately. Explicitly state which authoring/editing/generation/simulation/debug/iteration steps need external host capabilities or remain unavailable, and link their owned roadmap tasks. Execute every documented workflow and adverse branch; claim no CPU/DSP/MCU/ASIC/SoC end-to-end capacity without corresponding qualification.`
  Verification: `pending exact capability and data-contract census`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.6`
  Status: `pending`
  Goal: `Guard complete MCP documentation coverage and runnable examples against drift.`
  Acceptance: `Join the exhaustive published methods/tools/resources/templates/schema/applicability population to explicit reference records and executable examples. Derive field membership from authoritative producers/schemas and verify descriptions and canonical links, not copied counts. Add genuine missing-surface/field/stale-schema/wrong-result controls without tests that only mirror implementation. Integrate focused checks through existing workflows, preserve all original failures and commit bounded guards.`
  Verification: `pending completed documented cohorts`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.7`
  Status: `pending`
  Goal: `Qualify the complete MCP operating reference and restore required feature delivery.`
  Acceptance: `Require an exact source/runtime/schema/documentation join with no unexplained surface/field omissions, all real-server workflow/result/refusal controls, native POD/book/link delivery and relevant regression/doctrine checks. Review the human and AI navigation and operational completeness against .6.1's entire inventory. Preserve explicit capability and hosted/platform limits, commit cleanly, clear the message and restore ISF-REDUCTION-DELIVERY.2.3.2.4.2.`
  Verification: `pending complete MCP reference`
  Commit: `pending`

## Decisions

- The director selected implementation after the POD discussion; this is an
  authorized priority change, not a DBIQNP-only suggestion.
- Prefer HTMLBatch for its module collection/index and public renderer hooks.
  `pod2html` remains a single-conversion alternative, not a second build path.
- POD documents the Perl bindings and implementation reference. Existing
  language-neutral semantic/MCP contracts and tutorials remain in the book.
- Disable dynamic footer data and validate relative output links. Source and
  output coverage are separate from semantic correctness and API stability.
- Primary references: [HTMLBatch](https://perldoc.perl.org/Pod::Simple::HTMLBatch),
  [HTML renderer](https://perldoc.perl.org/Pod::Simple::HTML),
  [mdBook preprocessors](https://rust-lang.github.io/mdBook/format/configuration/preprocessors.html).

## Generation contract established by .1

- Scope is regular `.pm` files under `perl/FSM`, independently joined to Git.
  Do not search dependency trees or `@INC`; never execute modules to render POD.
- Render all provided POD after .3 repairs the three missing-encoding errors. The initial supported-binding guide set is
  `Pipeline::HDLGenerator`, `Adapter::ISF`, `Scheduler::ISF`,
  `Support::CapabilityManifest`, `Support::SemanticIntrospectionMCPAdapter`
  and `VIAL::Tool`, all prefixed `FSM::`. Their existing book contracts govern
  stability. Other rendered modules are implementation documentation.
- Missing internal POD is an explicit coverage boundary, not a broken parser:
  the source census schedules facade gaps in .3; the generated coverage report
  must enumerate every remaining module without POD. Internal methods are not
  a promised external API merely because documentation exists.
- The installed Checker and HTMLBatch are both 3.42. Use their documented
  content/errata methods, renderer subclass hook and batch settings. Require
  Pod::Simple 3.42 for this documentation tool; do not infer validation on the
  whole Perl 5.20 support matrix from one installed host.
- Generate into an ignored, dedicated book-source asset directory through a
  native preprocessor. Full input/output identities govern freshness; stable
  cache hits write nothing. Build staging stays under `.artifacts/`; reject
  symlinked/unowned output paths and validate local pages and fragments.
- Replace dynamic timestamp footers and use relative module/index/manual
  navigation plus a local stylesheet. Build validation must fail on bad POD,
  missing/extra output, stale inputs and broken local links.
- Saved count evidence: re-derivation is the filesystem census; falsification
  is the separate Git membership/source join plus malformed/plain controls;
  durability is the immutable capture revision and per-file SHA in
  `docs/audits/pod-api-20261023/inventory.json`. Reverify with
  `python3 docs/audits/pod-api-20261023/verify.py`; it reads the saved boundary,
  not changed current sources.

## Acceptance Checklist — .1

- [x] **ROOT CAUSE (WHY + WHERE)** — Native book configuration has no POD preprocessor and public facades lack POD; `git log -S '[output.html]' -1 -- docs/book/book.toml` locates the original HTML configuration. The saved source census identifies exact missing files without loading their implementation.
- [x] **ADDRESSED (verified)** — The read-only inventory and independent saved-boundary reader establish scope, source identities, diagnostics and malformed/no-content controls; the task now defines the generator and facade successors. No API stability is expanded.
- [x] **NO REGRESSION** — `perl -c docs/audits/pod-api-20261023/inventory.pl` emitted the actual diagnostic below; complete staged doctrine driver is required before this commit.

  docs/audits/pod-api-20261023/inventory.pl syntax OK

## Open Questions

- Actual provided-POD quality and facade coverage are measured by `.1`.
- Native mdBook integration and public renderer behavior are qualified through
  real builds in `.2`/`.4`, including the project's minimum-version boundary.

## Owned checker finding (.1, repaired in the audit and required in .2)

- Reproducer on Pod::Simple 3.42: check `=head1 NAME` followed by
  `Broken E<missing>`. The documented Checker output reports an unknown E
  escape, while its post-parse `any_errata_seen` returns false. The first
  saved-reader control failed with AssertionError before the correction.
  Both audit and generator must reject nonblank Checker diagnostics OR the
  errata flag. A retained regression will prevent reliance on the flag alone.
  Applying the corrected gate found missing `=encoding utf8` declarations in
  `ConsolidatedIntermediateClassificationSupport.pm`,
  `ConsolidatedIntermediateSelectionSupport.pm` and
  `IntermediateSignalRecoverySupport.pm` under the SystemVerilog backend; .3
  owns all three repairs before production generation. The initial flag-only
  census falsely reported no errors; its failure is preserved here and the
  corrected saved census/reader reports all three.
  This affects documentation validation; no FSMGen runtime changes are needed.

## Blockers

- None at activation. Existing unrelated publication gates remain in force.

## Acceptance Checklist — .2

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S '[output.html]' -1 -- docs/book/book.toml` identifies b8a083726, the native HTML configuration without POD generation. Real batch controls also exposed a globally scoped input separator that hid module pages and default external links that bypassed local fragment checks. Retained first/second/third logs show these failures; the input scope and public renderer hook now address them.
- [x] **ADDRESSED (verified)** — The final real-render fixture suite reports `Ran 12 tests` and `OK`; malformed production POD is rejected before replacement. Complete populations are joined before publication. The generator fingerprints all source/tool bytes and versions and owns only its dedicated output tree. Generated local links, including no-POD pages, pass page/fragment checks.
- [x] **NO REGRESSION** — Actual syntax diagnostics from the same checked source:

  scripts/pod_api_render.pl syntax OK
  scripts/lib/FSMGen/PodHTML.pm syntax OK

### .2 evidence and boundaries

- Run `python3 -B -m unittest discover -s t/python -p test_fixture_pod_api.py -v`.
  Saved first failures and production refusal are compressed under
  `docs/audits/pod-api-20261023/`; controls reproduce against the checked source.
- A fresh render and unchanged cache hit are separate tests. Identity is earned
  by complete file-byte comparison, broken by source/output mutations, and
  retained by the manifest and executable test. No cross-tool-version identity
  is claimed. The production POD population remains blocked until .3 repairs
  the diagnosed encoding declarations. Native delivery/serve qualification is
  still .4/.5, not implied by generator tests.
- Temporary source snapshots and locking live under `.artifacts/`; the only
  public output is the dedicated generated directory. Nonempty unowned trees,
  unknown extra members, symlinks, nested Git boundaries and foreign volumes
  fail before replacement. `--repair` permits replacement only of manifest-owned
  missing/modified files and still refuses extras.

## Acceptance Checklist — .3

- [x] **ROOT CAUSE (WHY + WHERE)** — The .2 production refusal names the SystemVerilog classification module's unencoded curly quote at POD line 34; .1 independently identifies the paired selection/recovery files. `git log -S '“which' -1 -- perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateClassificationSupport.pm` locates its introduction. Five selected entry-point modules had no POD; HDLGenerator's older POD omitted bounded options and raw-result limitations.
- [x] **ADDRESSED (verified)** — Add the three UTF-8 declarations and current binding documentation. Actual production render and `--check` pass. The complete coverage population and all six actual synopsis programs pass; `check_examples.py` checks concrete results rather than exit status alone. `compare_pod_code.py bb969f7ac` proves lexical code outside POD conserved across every changed Perl source. Initial synopsis-reader errors (crossing `=cut`, then assuming an actor_name report field) are retained and corrected to the actual scheduled_fsm schema.
- [x] **NO REGRESSION** — Guarded existing contract cohort: All tests successful. Files=6, Tests=20. The real HTMLBatch adverse suite also passes unchanged. Native book source/index and staged doctrine gates are required for this commit.

### .3 reproducible evidence

- `scripts/run_with_ram_guard.sh -- python3 -B docs/audits/pod-api-20261023/check_examples.py`
  extracts the six actual SYNOPSIS programs, retains local stdout/stderr and
  validates generation, parse, schedule, capability, MCP and VIAL results.
  `examples-evidence.json` binds the checked source/snippet hashes.
- `python3 -B docs/audits/pod-api-20261023/compare_pod_code.py bb969f7ac <slice-commit>`
  independently rechecks every changed Perl source against the original code;
  `pod-code-conservation.json` records the capture's file/code identities.
- Focused runtime cohort: t/375, t/1118, t/1143, t/1880, t/1441 and t/297
  (exact filenames/observations in retained facade-tests.log.gz). It exercises
  existing contracts after POD-only edits; it is not full CI or publication.
- Remaining no-POD implementation modules are enumerated in generated coverage.
  They are outside the selected binding-guide scope; this is explicit coverage,
  not a claim of exhaustive method documentation or a newly stable interface.
  Native automatic delivery and rendered/serve qualification remain .4/.5.

## Acceptance Checklist — .4

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S '[output.html]' -1 -- docs/book/book.toml` identifies the native configuration that lacked POD generation. The first actual preprocessor build fails on missing src metadata; retained native context shows mdBook 0.5.4 omits that default field. Use the default when absent and still reject an explicit unsupported source path. The first HTTP probe was denied by the filesystem sandbox before source mutation; the authorized unchanged loopback probe succeeds.
- [x] **ADDRESSED (verified)** — Native preprocessor, watch inputs/ignores, sidebar/landing/index links, README requirements and Toolbox guidance now deliver the reference. Fresh same-volume relocated build with a space-containing root matches complete generated/native file bytes, and both cwd forms work. Deliberately malformed POD and missing owned output fail the actual book build without replacing prior source/built output; explicit owned repair restores it. Scope prose is corrected to the exact perl/FSM .pm population.
- [x] **NO REGRESSION** — The 12 real-generator fixture controls pass. Existing native source/index checks and complete staged doctrine driver are required before this commit. Perl syntax remains unchanged from .3:

  scripts/pod_api_render.pl syntax OK

### .4 delivery, live preview and review evidence

- `verify_delivery.py REPO_RELATIVE_BOOK_OUTPUT` independently joins actual
  module files, selected guide population, coverage, source/tool hashes, complete
  copied membership/bytes and every generated local href/fragment. The native
  graph has 404 copied members and 3974 local-link checks at this capture.
  Coverage is 399 .pm sources: 112 with POD, 287 explicitly without. These are
  source/coverage observations, not method-completeness or stability claims.
- `check_relocated.py` proves actual fresh native generation, both invocation
  directories, full-byte identity, genuine native refusals and owned repair in
  a disposable same-volume root with spaces; the exact fixture is removed.
- `check_serve.py LOOPBACK_PORT` observes the original CSS, changes it, observes
  the served replacement, restores exact source bytes in finally, and observes
  the served original. Builds advance 1 -> 2 -> 3 and remain 3 over the bounded
  four-second idle observation. This is no latency/platform guarantee.
- Browser QA observes the guide/sidebar, HDL facade, API index, MCP page, method
  anchor and manual backlink. At a 390-pixel viewport, tested document width is
  also 390. Styles and long names remain readable; code blocks scroll locally.
  Viewport is restored and the temporary tab closed. One Playwright timeout on
  the old large embedding chapter is recovered through the documented native
  AX action. Broader manual visual QA is not thereby closed.
- `browser-rendered-pages.json.gz` and `browser-qa.json` retain the actually
  observed HTML/CSS/manifest identities and the visual-observation limits. A
  later narrow wording correction makes the namespace scope explicit; final
  native bytes and links are requalified separately.
- The older embedding chapter's test link produces HTTP 404. This distinct P2
  defect is owned/scheduled by MDBOOK-LEGACY-SOURCE-LINKS; it is not silently
  included in the passing generated-reference graph. No implementation pivot
  occurs before this task is committed and clean.
- All source/tool/test/temp work stays inside this project and on its volume.
  Normal stop closes the loopback listener; no preview job is left required.
  Hosted/full-CI publication and the broader Python/Perl/platform matrix remain
  outside these local signoffs.

- The first .4 staged gate rejects README growth and a source-inventory refresh
  generated before complete staging. Keep its full log, tighten only redundant
  README discovery prose while retaining all links/instructions, and regenerate
  the inventory after the complete new chapter is staged. No README ceiling or
  allowance is increased.

- The second .4 gate identifies SUMMARY's mandatory-read bound. Omit only its
  optional parser-ignored title, as permitted by the official mdBook summary
  format; retain every original entry in order and add the API child. The saved
  navigation join and native source/index/build checks qualify the result. No
  chapter or navigation member is removed and no bound increases.

## Acceptance Checklist — .5.1

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'Fact files live here' -1 -- docs/knowledge/README.md` identifies 601a18a06, the original installer pointer. The full pre-slice query set has no POD route, while the current Knowledge Map collection has fixed rollover-debt authority. Adding a card without containment would exceed that authority; the installer only creates its pointer when the entire first scan directory is absent.
- [x] **ADDRESSED (verified)** — Add the atomic reference signpost and preserve its default-directory/template/rename guidance at the bundle entrypoint. The related historical card is copy-edited without changing metadata, questions, source history, cause/repair, invocation contract, recovery operations or qualification limits. Whole before/after source and query joins, full retained old/new bodies and genuine adverse candidates pass. Byte/member authority is derived from the registry and required unchanged, not copied as a new limit.
- [x] **NO REGRESSION** — knowledge-map: OK. The canonical historical --verify-saved reader returns zero and retains actual_worker_execution=false and operational_execution_admitted=false; only its existing book recovery is qualified. The actual generated reference freshness check passes. Native book/source/index and staged doctrine gates are required for this commit.

### .5.1 preservation evidence

- `verify_knowledge_route.py` authenticates complete original source files through
  native Git archive plus an independent ls-tree membership join, preserves all
  unrelated card bytes, and checks unchanged historical metadata, every old
  question-owner row, exact history reconstruction and the complete reviewed
  small body. The before packet and compressed full question set are retained.
- Its actual missing-question, borrowed-owner, missing-card, lost-location and
  changed-metadata candidates fail the same preservation predicates. The paired
  full bodies make the manual semantic review visible; matching counts alone
  are not presented as meaning preservation.
- The source collection keeps its file membership count and adds only the small
  bounded byte delta under existing authority. No Knowledge Map limit changes.
  Re-derivation, falsification and durable base/source/body/question custody are
  distinct legs in `knowledge-route-evidence.json` and its tracked reader.
- The original historical reader's exact printed limits are retained in
  knowledge-original-reverify.log.gz. Its open worker/protocol/final-admission
  ownership remains unchanged; no new HIAL or hosted execution is inferred.
- The book now routes the POD query and explains the qualified checker's
  diagnostic-output boundary. No new API behavior or legacy-link repair is
  introduced by this discovery slice.

- The first .5.1 staged gate also finds the bundle README's ancillary-surface
  allowance exhausted. Tighten its redundant opening/model prose while retaining
  its purpose, reader roles, derived projection, automatic hook/CI behavior and
  signpost boundary. With the relocated authoring instruction, the complete
  README is smaller than its committed predecessor. No ancillary allowance
  or ceiling increases; the complete first failure remains retained.


## Acceptance Checklist — .5.2

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'manifest_schema_version' -1 -- docs/audits/pod-api-20261023/check_examples.py` identifies cfb13b284, the original audit-only observer. It used Python equality for numeric schema versions, accepted any nonempty VIAL object, reused a fixed workspace, and was absent from fixture discovery. The exact Git-recovered observer really accepts counterfeit true as version 1; the current checker rejects that payload at the intended result predicate. No product API emitted the counterfeit payload.
- [x] **ADDRESSED (verified)** — Canonical checker executes actual source synopses in unique same-volume workspaces, checks concrete typed results/source hashes, rejects stderr and bounds each process. Failure evidence survives; successful exact workspaces are removed. The existing CI fixture glob discovers the actual-example/guide-population join plus malformed/result/Boolean/numeric/stderr/timeout controls. The audit compatibility command returns byte-identical evidence for the real prior capture.
- [x] **NO REGRESSION** — The 19 real generator/example tests pass; the broader actual Perl facade cohort reports All tests successful. Files=3, Tests=13. Compressed raw outputs are retained, and native book/source/index/delivery plus staged doctrine checks are required before this commit.

### .5.2 evidence and successor ownership

- Re-derivation executes the actual source programs; falsification executes
  malformed Perl, a successful wrong-result process, Boolean/numeric payloads,
  unexpected stderr and a timed-out process. Durable source/program identities,
  complete old producer and controlled payload/output bytes are retained in
  previous-observer-probe.json and its executable producer. These are distinct
  legs; a zero exit code alone is never the result oracle.
- example-runner-conservation.json joins the complete successful evidence bytes
  to the .3 capture. It does not claim that arbitrary old observer predicates
  were sufficient. The stronger VIAL check joins the typed report and actual
  source content hash; the Boolean repair preserves integral numeric spellings.
- Qualification also finds that capture_inputs fingerprints Perl/Pod versions
  but omits the generating Python runtime. runtime-fingerprint-before.json
  retains the actual manifest versions and generator source identity. The
  reproducibility gap is owned and scheduled in immediate successor .5.3 with
  a missing/stale-runtime control; no cache-version claim is closed here.
- Example execution stays separate from rendering. Existing CI workflow
  discovery needs no new job or workflow policy; hosted execution itself has
  not occurred and existing publication gates remain unchanged.


## Acceptance Checklist — .5.3

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S "'versions': run_perl" -1 -- scripts/generate_pod_reference.py` identifies bb969f7ac: capture_inputs bound Perl/Pod versions but omitted the Python runtime that also serializes and generates reference files. The fixed real-generator test fails with KeyError: python before the repair; the actual production manifest also lacks that field. Both original observations are retained.
- [x] **ADDRESSED (verified)** — Fingerprint Python implementation name, implementation release and language release, without paths or timestamps. The unchanged runtime test now passes and actual missing/stale saved-runtime controls refuse without writing assets; regeneration restores the original rendered bytes. Production source/output hashes conserve. Independent complete native delivery, current check/generate/build no-write metadata, and fresh relocated native refusal/repair qualification pass; all raw records and source identities are retained.
- [x] **NO REGRESSION** — All 20 generator/example fixture tests pass, including all six actual facade synopses and prior adverse controls. Native book/source/index/complete delivery checks pass. The unchanged renderer remains:

  scripts/pod_api_render.pl syntax OK

### .5.3 final evidence and handoff

- runtime-red.log.gz and runtime-green.log.gz retain the exact fixed-test
  failure and complete successful suite. runtime-production-transition.json.gz
  retains complete before/after manifests, source/output hash conservation and
  actual generator output. The Python fingerprint repairs cache identity; it
  does not assert byte equivalence across arbitrary different tool releases.
- qualify_final.py is the repeatable current-reader producer. Its captured
  final-qualification.json.gz joins complete source/tool/output identities,
  native copied bytes and local links, and proves reference file bytes and
  mtimes survive --check, ordinary generation and native build. Count claims
  derive from actual source membership and independent HTML parsing; deliberate
  generator/native adverse fixtures are the separate falsification leg.
- final-relocated.json.gz and complete native command outputs preserve actual
  fresh generation, both cwd forms, malformed/missing-output failures retaining
  prior output, explicit repair, whole-byte identity and exact fixture cleanup.
  Original .4 observations stay immutable. Source styles and rendered module
  bytes remain unchanged from the browser-reviewed reference; later guide prose
  changes are separately native/link-qualified, not new whole-manual visual QA.
- Browser availability established by .4 also retires the stale browser-access
  blocker in MDBOOK-PARAGRAPH-SPACING.5.2. Its actual whole-manual review and
  resulting repair remain pending behind required delivery; no audit is passed
  merely by correcting its availability metadata.
- Existing unresolved legacy manual source hyperlinks remain owned/scheduled
  by MDBOOK-LEGACY-SOURCE-LINKS. Existing HIAL/historical causality, full CI,
  exact-SHA hosted/publication and broader supported-platform tests remain open
  under their original owners. No module execution occurs during rendering,
  and no API stability, language or MCP capability is expanded.
- After required staged/normal commit gates, clear the ephemeral message and
  verify clean state. Resume the committed source-only reusable constructor
  leaf ISF-REDUCTION-DELIVERY.2.3.2.4.2. No source/compiler epoch is replayed by
  this documentation qualification, and no preview/background job remains.


## Acceptance Checklist — .6.1.1.1

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'print {$out}' -1 -- perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm` identifies 129cfae08, the original unflushed run_stdio print. Real launcher and adapter pipes return no reply during the open-input observation and emit the complete response only after EOF; the same adapter with externally forced autoflush replies before EOF. Both fixed live tests fail on the original adapter. This isolates response buffering rather than malformed JSON or a crashed child.
- [x] **ADDRESSED (verified)** — Flush each completed response on the actual output handle, check write/flush failure, and retain selected handle/buffering mode. Actual launcher and custom-handle regressions now pass with multiple exchanges, Unicode/zero IDs, initialization, notification silence, refusal/recovery and orderly EOF. All independent probe replies conserve exact bytes while both former buffered paths now deliver before EOF. The existing CI fixture glob discovers these tests; POD/book describe persistent exchanges accurately.
- [x] **NO REGRESSION** — The six real POD programs and native book/source/index/complete reference delivery pass. The 23-file MCP cohort passes 22 files; T1445's snapshot assertion fails equally with the byte-exact predecessor, with complete old/new projected-product equality. That pre-existing fixture issue is owned by immediate .6.1.1.2 and the full original failure is retained; the broad cohort is explicitly not green. The changed module reports:

  perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm syntax OK

### .6.1.1.1 transport evidence and unresolved snapshot

- The original open-pipe observation, fixed RED/GREEN logs and exact failed
  fixture request/before-EOF/after-EOF/process/stderr bytes are retained under
  docs/audits/mcp-api-reference-20261023. The owned failed fixtures remain local;
  no necessary result or background process is stranded in them.
- probe_stdio.py produces the independent launcher/default/forced-flush
  observations and selected full source identities. Before/after compressed
  packets and response-conservation.json retain every complete reply. These
  are bounded observations, not a latency guarantee, full transitive footprint
  or supported-platform matrix. Re-derivation is the actual live transport;
  falsification is the forced-flush counterfactual and fixed regression;
  durability is complete captured bytes, source identities, producers and Git.
- stdio-regression.log.gz retains the complete 23-file run and original T1445
  refusal. probe_snapshot.py preserves that test's assertions/projector and
  changes only its fixture-root location for isolated execution. It preloads
  the exact predecessor module and compares complete projections with the new
  module. Both fail identically against the expected fixture. No fixture or
  public schema is edited in this transport slice, and no passing broad gate
  is inferred. The immediate successor owns diagnosis and verified repair.
- The pinned official MCP 2025-06-18 transport/lifecycle references describe
  subprocess newline UTF-8 exchanges and input-close shutdown:
  https://modelcontextprotocol.io/specification/2025-06-18/basic/transports
  and https://modelcontextprotocol.io/specification/2025-06-18/basic/lifecycle.
  The complete client reference remains .6-owned; this repair alone does not
  qualify every tool, schema, temporal question or end-to-end design workflow.
