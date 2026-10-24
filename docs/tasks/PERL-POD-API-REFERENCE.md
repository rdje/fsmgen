# PERL-POD-API-REFERENCE: Generate and integrate the Perl API reference

## Metadata

- Tree ID: `PERL-POD-API-REFERENCE`
- Status: `active`
- Roadmap lane: `R13 / documentation and embedding`
- Created: `2026-10-23`
- Last updated: `2026-10-24`
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
  Children: `PERL-POD-API-REFERENCE.1, PERL-POD-API-REFERENCE.2, PERL-POD-API-REFERENCE.3, PERL-POD-API-REFERENCE.4, PERL-POD-API-REFERENCE.5, PERL-POD-API-REFERENCE.6, PERL-POD-API-REFERENCE.7`

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
  Status: `done`
  Children: `PERL-POD-API-REFERENCE.6.1.1.1, PERL-POD-API-REFERENCE.6.1.1.2`
  Goal: `Reproduce and repair any persistent stdio response-buffering defect before documenting client workflows.`
  Acceptance: `The adapter's run_stdio prints responses to a pipe without an explicit flush; verify with a real persistent subprocess that keeps stdin open and waits for its first response. Retain the exact request/raw response/process outcome before EOF and after orderly EOF, source/runtime identities and a competing EOF-only control. If buffering is confirmed, repair only transport response delivery without changing report bytes, IDs or notification behavior. Add an actual open-pipe regression, qualify custom handles and relevant existing transport/schema/source-failure tests, synchronize POD/book and commit before continuing the census.`
  Verification: `The live buffering defect is reproduced, isolated with a forced-flush control and repaired at fe68b8458. Both real open-pipe regressions pass with conserved response bytes and unchanged handle state. The independent pre-existing catalog snapshot issue is repaired in .6.1.1.2; all 23 relevant Perl files/64 top-level tests now pass. Complete operational documentation census remains .6.1.2.`
  Commit: `PERL-POD-API-REFERENCE.6.1.1.2: distinguish optional catalog fields in MCP schema snapshots`

- ID: `PERL-POD-API-REFERENCE.6.1.1.1`
  Status: `done`
  Goal: `Commit the verified persistent response-flush repair and actual open-pipe regression.`
  Acceptance: `Complete .6.1.1's transport repair with real launcher/custom-handle RED/GREEN, independent forced-flush control, exact response-byte conservation, orderly EOF and unchanged selected/buffering state. Retain the broader cohort's exact original outcome. If its snapshot failure reproduces with the byte-exact predecessor adapter and complete projection equality, own that separate fixture issue in immediate successor .6.1.1.2 instead of disguising it as a passing broad gate. Commit the verified scoped transport repair before that fixture successor.`
  Verification: `Both live regressions fail before repair and pass afterward. Actual launcher/default-adapter probes lack a reply before EOF while forced autoflush succeeds; after repair all three stream and complete reply bytes conserve. The broader cohort passes 22 files but t/1445's first sample-entry key differs from its saved fixture. The byte-exact predecessor reproduces the snapshot failure and its complete projected products equal the repaired adapter. This independent pre-existing fixture failure is owned by immediate successor .6.1.1.2; no broad green claim.`
  Commit: `fe68b8458`

- ID: `PERL-POD-API-REFERENCE.6.1.1.2`
  Status: `done`
  Goal: `Resolve the MCP schema snapshot's sample-dependent catalog projection failure.`
  Acceptance: `Reproduce the exact t/1445 failure using the original adapter and compare complete projected products before/after the flush-only repair. Trace the differing support-summary sample fields to actual catalog selection, history and its public optional-field contract. Repair the smallest correct observation/fixture contract, preserving strict protocol/schema coverage and meaningful real catalog checks; never blindly regenerate a fixture or weaken assertions to obtain green. Add a real catalog-variant/ordering control where warranted, qualify the fixed snapshot plus relevant cohort, synchronize public field guidance and commit before the exhaustive census.`
  Verification: `The original schema test froze the first sampled record although diagnostic_code was already optional in its own introduction revision. The current first catalog entry is an expected-failure fixture with that optional code. Original/current adapter projections match completely and fail the old observer equally. The repaired observer separates common/optional schema keys; both real catalog variants in either order preserve complete values, text/structured equality, full membership and source immutability. Missing-common and unknown-field controls remain distinguishable. Only the explicit optional-key declaration is added to the golden projection; every other fixture member and production code outside POD conserve. The full MCP cohort now passes Files=23 Tests=64. Complete compact-sample field guidance and its corrected native POD anchor pass book/source/index/delivery checks.`
  Commit: `PERL-POD-API-REFERENCE.6.1.1.2: distinguish optional catalog fields in MCP schema snapshots`

- ID: `PERL-POD-API-REFERENCE.6.1.2`
  Status: `active`
  Children: `PERL-POD-API-REFERENCE.6.1.2.1, PERL-POD-API-REFERENCE.6.1.2.2, PERL-POD-API-REFERENCE.6.1.2.3, PERL-POD-API-REFERENCE.6.1.2.4`
  Goal: `Complete the exhaustive public-surface and documentation-gap census after transport admission.`
  Acceptance: `Perform the full .6.1 census and refine every successor from actual published methods/tools/resources/templates/schema/query applicability. Retain complete source/runtime/schema identities, current documentation locations, unexplained gaps and explicit owned limitations; no schema/name-only stub counts as reference completion. Commit the audit before operational-reference edits.`
  Verification: `Persistent transport and the independently failing catalog-snapshot observer are qualified; exhaustive public-surface/schema/documentation-gap census remains pending.`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.1`
  Status: `done`
  Goal: `Capture complete live MCP discovery, method coverage and schema conformance observations.`
  Acceptance: `Use the real persistent server after the transport repair. Retain initialized capabilities, complete tools/resources/templates and all static payloads, public manifest sections, source-query applicability, schema/property populations and exact raw exchanges. Join independently published contract names and dispatcher method membership to live discovery/calls, with source and observer identities and orderly shutdown. Measure missing source-identity alternatives, diagnostic limit_examples visibility and capability payload types across every public section before classifying gaps. Include genuine missing/extra member/type controls; own each confirmed discrepancy and commit this bounded capture before repairing schemas.`
  Verification: `The real server at ed92d0a12 yields 7 dispatcher methods, 9 tools, 6 static resources, 13 listed templates and 74 complete exchanges. Independent raw-frame/contract/field/Git-source joins qualify 406 selected files (all 399 tracked FSM modules plus seven declared inputs), 21 input-property and 63 output-property paths. Eight genuine missing/extra/borrowed/Boolean/wire/source controls reject; JSON numeric enum equivalence and Boolean distinction are checked. Exact compressed bytes, source/observer identities, full results and a repeatable saved reader retain. Six exact conformance/error repair cohorts are owned in .6.1.2.2; no schema-conformance success, full result-documentation coverage, compiler epoch, temporal run or platform matrix is inferred. Book records current client compatibility defects; source/syntax/native/doctrine gates qualify the audit commit.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.1: qualify live MCP interface and conformance gaps`

- ID: `PERL-POD-API-REFERENCE.6.1.2.2`
  Status: `done`
  Children: `PERL-POD-API-REFERENCE.6.1.2.2.1, PERL-POD-API-REFERENCE.6.1.2.2.2, PERL-POD-API-REFERENCE.6.1.2.2.3, PERL-POD-API-REFERENCE.6.1.2.2.4, PERL-POD-API-REFERENCE.6.1.2.2.5, PERL-POD-API-REFERENCE.6.1.2.2.6`
  Goal: `Repair only confirmed advertised-schema/runtime contract discrepancies.`
  Acceptance: `Refine one exact child leaf per independent .6.1.2.1 discrepancy before implementation. Preserve existing valid behavior and published compatibility while making discovery accurately describe accepted requests/results. Prove real before/after requests and metadata, valid/refused cases and full typed outputs with adverse controls. Synchronize precise POD/manual guidance and relevant schema snapshots; commit each repair before its successor.`
  Verification: `All six confirmed interface repair cohorts close with actual schema/value/admission/error controls and original evidence retained. Required source alternatives, diagnostic limits, capability payload kinds, argument/copy/numeric behavior, bounded error preservation and examples documentation typing are qualified. This closes the selected discrepancies, not exhaustive protocol/model/reference signoff; remaining reference-address findings stay P2-owned by .6.2.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.2.6: declare examples documentation as an object`

- ID: `PERL-POD-API-REFERENCE.6.1.2.2.1`
  Status: `done`
  Goal: `Advertise the existing required source identity alternatives accurately.`
  Acceptance: `The captured check/semantic/schedule input schemas admit an empty object, while real calls reject it for absent source_id/source_path. Express the existing identity alternative in discovery without changing valid request precedence/applicability. Prove real empty/valid/refused cases and descriptor conformance, preserve scalar/source kinds and compatibility, synchronize exact guidance and commit.`
  Verification: `Live RED finds 15 schema/request mismatches. Discovery-only anyOf plus minLength repair makes both actual persistent regressions pass, including VIAL version applicability. Complete before/after captures conserve 12 valid results and 51 refusals; four coherent missing-call/report/schema/wire interventions fail at their intended checks. All other tool metadata and query runtime conserve. Broader MCP cohort passes All tests successful Files=23, Tests=64; POD/book guidance, local field anchor, native source/delivery and staged doctrines qualify this commit. Error-location repair remains explicitly pending .6.1.2.2.5.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.2.1: advertise required MCP source selectors`

- ID: `PERL-POD-API-REFERENCE.6.1.2.2.2`
  Status: `done`
  Goal: `Publish the diagnostic sample-limit argument already used by public workflows.`
  Acceptance: `Advertise limit_examples in explain_diagnostic's closed input schema, preserving existing documented/native behavior and defaults. Qualify declared field/type, real capped results and refusals, snapshot compatibility and precise per-tool zero/default semantics. Do not silently impose uniform limit behavior across unrelated tools. Commit before generic argument enforcement.`
  Verification: `The original schema rejects six actual valid limit-bearing requests and the new API fixture test fails on the missing field. The repaired descriptor and exact snapshot property/type addition pass, preserving all seven live diagnostic results and eight controlled results with full typed payload equality; five coherent adverse controls reject. Omitted/zero/negative defaults and the distinct support-summary zero policy retain; missing/unknown code refusals retain. Broader MCP cohort passes All tests successful Files=23, Tests=65. Native POD/book/source/delivery and staged doctrines qualify this commit; the newly confirmed large-integer limit defect remains owned by .2.4 and is disclosed in the manual/POD.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.2.2: advertise diagnostic sample limits`

- ID: `PERL-POD-API-REFERENCE.6.1.2.2.3`
  Status: `done`
  Goal: `Make capability-query output schemas admit every supported public section value.`
  Acceptance: `The real manifest_schema_version section returns integer payload 1 against an object-only payload declaration. Preserve the complete wire values and existing section variants; correct only the advertised output typing with deliberate public-section semantics. Check every captured/current section, distinguish Boolean/numeric types and reject a genuinely wrong type in the conformance observer. Synchronize schema/reference guidance and commit.`
  Verification: `The original live test rejects the actual manifest-version integer and an equivalent numeric spelling against the old object-only schema. The corrected object/integer union admits every current section while rejecting Boolean/string/array/null alternatives. Complete before/after results conserve across 18 selectors and 12 manifest sections; 402 selected source files bind the capture. Five coherent missing/extra/type/borrowed-value/schema controls reject at their intended checks. Query runtime outside the schema/POD region is byte-identical. Both live metadata tests pass, prior diagnostic saved-reader controls remain green after a shared framing-helper extraction, and the broader MCP/VIAL capability cohort passes All tests successful Files=24, Tests=71. Native POD/book/source/delivery and staged doctrines qualify this commit.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.2.3: admit integer capability payloads`

- ID: `PERL-POD-API-REFERENCE.6.1.2.2.4`
  Status: `done`
  Children: `PERL-POD-API-REFERENCE.6.1.2.2.4.1, PERL-POD-API-REFERENCE.6.1.2.2.4.2, PERL-POD-API-REFERENCE.6.1.2.2.4.3, PERL-POD-API-REFERENCE.6.1.2.2.4.4`
  Goal: `Enforce advertised metadata-tool argument types and closed fields consistently.`
  Acceptance: `Five metadata tools accept an unpublished argument despite closed schemas; discovery/examples/support also accept wrong array-typed fields, while capability/diagnostic wrong types expose ARRAY reference addresses in errors. Reuse established project JSON-kind/argument facilities where suitable, or select a bounded validator for exactly the published schema vocabulary without introducing an unrelated evaluator/dependency. Preserve all valid supported values, JSON scalar kinds and intended per-tool limits; reject invalid types/fields cleanly with actual API/newline controls. Split validation cohorts if needed, document and commit.`
  Verification: `Completed .4.1's full admission/copy audit, .4.2's metadata/envelope repair, .4.3's per-operation numeric policies and .4.4's source/VIAL kind repair. The final selected argument population has no unsupported admission, wrong invalid-input class or caller-copy change; complete schema-admitted results and URI routes conserve. Original failures, source capsules, independent readers and actual adverse controls retain, with current POD/book/KMap. This closes argument enforcement only; error-location, example-schema and complete operational/model reference successors remain.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.2.4.4: enforce source and VIAL argument kinds`

- ID: `PERL-POD-API-REFERENCE.6.1.2.2.4.1`
  Status: `done`
  Goal: `Qualify argument-kind and entrypoint normalization boundaries before validation changes.`
  Acceptance: `Query established JSON-kind facilities before designing new ones. Read the dispatcher, public argument schemas, affected payload helpers, canonical contracts/manual and relevant tests. Capture exact actual API/newline valid and invalid argument forms, closed fields, required fields and scalar kinds; distinguish omitted/null/falsy containers, numeric strings, integral/fractional numbers and Booleans. Include every published tool's typed fields where applicable, without running a historical source epoch. Refine subsequent fixes from actual discrepancies and public compatibility, bind source/observer identities, preserve original outcomes and commit this audit before implementation.`
  Verification: `The qualified matrix binds 9 tools/22 input fields and 615 labeled requests through both actual API and persistent stdio at d623c35dd. It records 106 unsupported-input admissions, 235 invalid-input error-class observations, no ordinary caller serialization change and 22 later-clone kind changes on invalid inputs. These are case observations, not distinct bugs. Exact source/observer capsules, raw exchanges, caller snapshots, 13 primitive samples, direct-versus-detached operator controls and eight adverse controls qualify. Original incomplete/Unicode drafts and the observer Boolean/zero false-acceptance control retain. Runtime before END is byte-identical; precise fixes are owned by .4.2-.4.4, with current limits disclosed in POD/book. Native documentation and staged doctrines qualify the audit commit.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.2.4.1: qualify argument kinds and caller preservation`

- ID: `PERL-POD-API-REFERENCE.6.1.2.2.4.2`
  Status: `done`
  Goal: `Enforce metadata argument object, required/closed-field and JSON-kind contracts.`
  Acceptance: `Use .4.1's exact public-boundary findings and established kind facilities. Preserve valid values and per-tool selection/default behavior; reject unsupported root argument shapes, unknown fields and wrong kinds without stringifying references or mutating input values. Handle dispatcher normalization explicitly so invalid falsy values cannot bypass admission. Qualify actual API/newline refusals, full valid-result conservation, scalar/Boolean controls and schema drift; synchronize POD/book and commit. Leave numeric normalization to its distinct leaf.`
  Verification: `T2102 genuinely fails three original subtests and passes after the public-boundary repair; all five metadata tools enforce their exact advertised primitive/required/closed-field contracts. A complete actual API/pipe matrix rejects all 369 targeted malformed cases, conserves all 81 previously successful complete responses and preserves metadata caller values/copy kinds. Original unsupported/misclassified/copy observations become 6/6/12, all separately owned source cases; these overlapping case categories are not distinct-defect counts. Both saved reader populations and eight controls pass, with four additional actual repair counterfeits rejected. Files=25 Tests=75 and all three live metadata tests pass. Aliases/defaults and integral number admission remain valid; numeric selection repair remains .4.3. Exact source overlay/capture/runtime conservation, logs, POD/book and required gates retain.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.2.4.2: enforce metadata argument contracts`

- ID: `PERL-POD-API-REFERENCE.6.1.2.2.4.3`
  Status: `done`
  Goal: `Repair valid large-integer sample limits while retaining each operation's policy.`
  Acceptance: `Fix the public 1e30 => default discrepancy after typed admission. Preserve diagnostic/default-zero behavior, support/discovery zero-empty policies, negative/default behavior, bounded samples and the examples operation's distinct positive-limit policy. Qualify ordinary and large integral spellings, scalar kinds, actual complete outputs and clearly counterfactual populations when real catalog counts cannot distinguish bounds. Reject genuine fractional/wrong-kind inputs at the owning admission boundary, retain before/after data and adverse controls, update current caveats/claim records/POD/book, and commit.`
  Verification: `T2103 retains 88 explicit per-operation API and newline cases over a clearly counterfactual 121-entry catalog. The original adapter fails exactly the large-number assertions in four operation subtests; the two-line numeric-predicate repair passes all five subtests. The independent reader verifies every complete ordered typed result, conserves ordinary/default/zero/negative and wrong-kind behavior, and rejects six coherent fallback/cap/type/order/wire/source counterfeits. A source-joined real persistent capture verifies all 32 limit calls against the full public catalog and rejects four additional identity/type/wire/native-boundary controls. All four live metadata tests and Files=26 Tests=80 pass. Descriptors/POD/book describe each distinct sampling policy, remove the obsolete caveat and retain explicit host/coverage limits. Full evidence and original failures remain in the dated audit directory.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.2.4.3: repair large integer catalog limits`

- ID: `PERL-POD-API-REFERENCE.6.1.2.2.4.4`
  Status: `done`
  Goal: `Close remaining source-selector kind discrepancies found by the admission audit.`
  Acceptance: `Refine from .4.1's actual results before editing. Check source identity, VIAL version/style and source-query argument kinds against published schemas; preserve all valid request behavior, applicability, source_path precedence and format authority. Distinguish textual URI version decoding from typed tool arguments so a fix cannot break versioned resources. Apply only confirmed repairs with actual native/API/newline controls and full result conservation, synchronize exact guidance and commit; close with a no-change qualification if the audit finds no discrepancy.`
  Verification: `The fresh pre-repair matrix retains 6 unsupported version admissions, 6 wrong invalid-input classes and 12 source caller-copy changes; the repaired full API/pipe matrix has none across the same 615 cases. All 75 schema-admitted results and complete values for ten resources/six paired tool calls conserve, including textual versions and unversioned v1 defaults. Both original reader populations/eight controls pass and five additional restored-admission/copy/borrowed-result/resource/source controls reject. T2104 genuinely fails three original subtests and passes all four after the scoped guard fix; it covers unused selectors, direct calls, fresh copies, integral spellings and URI routes. Files=27 Tests=84 plus all three actual persistent source tests pass. Current POD/book/KMap and source/capture custody retain exact limits; no full protocol, feature, runtime or platform qualification is inferred.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.2.4.4: enforce source and VIAL argument kinds`

- ID: `PERL-POD-API-REFERENCE.6.1.2.2.5`
  Status: `done`
  Children: `PERL-POD-API-REFERENCE.6.1.2.2.5.1, PERL-POD-API-REFERENCE.6.1.2.2.5.2, PERL-POD-API-REFERENCE.6.1.2.2.5.3, PERL-POD-API-REFERENCE.6.1.2.2.5.4`
  Goal: `Remove automatic Perl/input-record locations from public persistent-server errors.`
  Acceptance: `Real invalid-parameter errors include the adapter .pm line and STDIN record suffix. Trace _strip_perl_error_location's missing input-record case; preserve the meaningful public reason, authored source diagnostics and path-sanitization behavior while removing private automatic locations. Qualify persistent/default/custom handles and moved roots with spaces, exact original messages, safe hostile suffix/quote/operator controls and public code/message-only envelopes; commit a scoped fix.`
  Verification: `Qualified .5.1 native/source audit and committed .5.2-.5.4 repairs cover literal loaded-code suffixes, line/chunk/spaced paths, authored source locations, case-insensitive operator contexts and nonempty zero reasons. Complete original/repaired packets, genuine regressions, source custody and adverse controls retain. The grammar is bounded and does not promise arbitrary exception provenance; remaining protocol/reference-address and model coverage stays with .6.2 and the exhaustive frontier.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.2.5.4: preserve nonempty zero-valued error reasons`

- ID: `PERL-POD-API-REFERENCE.6.1.2.2.5.1`
  Status: `done`
  Goal: `Qualify automatic error suffix grammar and authored-message preservation before repair.`
  Acceptance: `Read canonical sanitizer/exception contracts, official Perl die behavior and actual error handling. Capture complete API/one-shot/persistent/custom-handle messages, exact native throw strings and locations, input-record line/chunk contexts and moved-root paths with spaces where applicable. Separate automatic loaded-code locations from meaningful authored source/quote/operator text; retain genuine original leak/truncation observations, source/runtime/producer identities and adverse controls. Choose a bounded repair contract, refine .5.2 if needed, synchronize current guidance and commit this audit before implementation. No whole source epoch or runtime execution.`
  Verification: `Original persistent messages leak adapter/STDIN locations. A fresh actual callback exception ending with newline, Authored diagnostic at design.isf line 17., returns only Authored diagnostic: the regex also deletes meaningful authored source-location text when no automatic suffix exists. The current .5.1 audit and immediate .5.2 repair own this P2 loss as well as leakage; no structured-report or global wire corruption is inferred. Root cause is shape-only location stripping after chomp. Official Perl die documentation confirms newline suppression and optional input-record context. The independent reader qualifies complete raw/native/public/caller contexts with six adverse controls. See the current acceptance section for exact population and limits.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.2.5.1: qualify error contexts and preservation contract`

- ID: `PERL-POD-API-REFERENCE.6.1.2.2.5.2`
  Status: `done`
  Goal: `Remove only confirmed private native exception suffixes without damaging public reasons.`
  Acceptance: `Select only a final Perl-shaped frame naming a loaded module or the entry script, comparing literal filenames and choosing the rightmost valid suffix. Handle bare, line-record and chunk-record forms and one terminal LF independently of caller record separator. Repair the confirmed automatic-location cases while preserving authored source diagnostics, quotes/operators, redaction/truncation policy, error code/message-only envelopes, caller kinds and valid results. Prove actual before/after default/custom/persistent/moved-root behavior and meaningful hostile suffix/false-location controls. Add focused CI regression, synchronize POD/book/KMap, qualify related source/diagnostic/transport tests and commit before capitalized operator-context repair.`
  Verification: `Original extended T1461 fails three of four subtests and both actual pipe tests fail before repair; all pass afterward. Complete before/final-after comparison checks 120 responses per capture, preserves native/caller/framing/source joins and clears every selected location/source-preservation discrepancy, leaving exactly the separately owned eight capitalized-context observations. Six reader controls on each packet and four repair controls reject. Broader MCP/quoted-division cohort passes Files=28 Tests=91; native POD/book/source/delivery and Knowledge Map checks pass. The additional zero-reason observation is owned by .5.4 before example typing.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.2.5.2: preserve public reasons when removing native error locations`

- ID: `PERL-POD-API-REFERENCE.6.1.2.2.5.3`
  Status: `done`
  Goal: `Preserve capitalized division-operator context while continuing to redact actual paths.`
  Acceptance: `The actual .5.1 callback with capitalized Operator redacts its quoted slash while lowercase operator preserves it. Own this P2 authored-message corruption now, reproduce the context predicate with genuine RED controls, and make the bounded case-insensitive context repair after .5.2. Preserve singular/list context, ordinary roots and longer paths; qualify actual message/report paths, original/new controls and the same error packet before committing. No broad string/path exemption.`
  Verification: `Actual original live regression has two capitalized-context subcase failures at the ordinary and spaced roots; all positive stock/refusal/preservation controls retain. Case-insensitive singular/list context predicates repair all eight complete captured messages and conserve the other 112 responses. Both original/repaired source/frame/native/caller readers and six controls pass; four restored-loss/unredacted-path/authored-loss/changed-ping interventions reject. Focused native/API/newline report parity passes Files=2 Tests=8, and both actual pipe tests pass. POD/book/source/delivery/Knowledge Map checks pass; zero-reason fallback remains .5.4.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.2.5.3: preserve capitalized division-operator context`

- ID: `PERL-POD-API-REFERENCE.6.1.2.2.5.4`
  Status: `done`
  Goal: `Preserve nonempty zero-valued authored exception reasons.`
  Acceptance: `Own the actual callback die of 0 plus newline returning the generic adapter message instead of the nonempty reason. This P2 embedded-exception loss comes from the post-format truthiness fallback. Immediately after .5.3, reproduce it with focused RED/GREEN API and pipe controls, select fallback by emptiness rather than truthiness, preserve truly empty fallback and code/message-only shape, synchronize POD/book and commit. No structured-report or native-CLI-wide corruption is inferred.`
  Verification: `Fresh T1461 on 488e59745 fails the zero-message case in all three API record contexts; empty and filtered-empty controls remain positive. Actual custom pipes fail exactly two zero subcases at ordinary/spaced roots. The repaired focused protocol/framing/error cohort passes Files=3 Tests=9 and both actual pipe tests pass. Complete capture comparison repairs both zero-string responses and conserves all 130 others; four restored-loss/numeric-zero/overwritten-empty/borrowed-source controls reject, alongside original reader controls on both packets and a qualified 120-response no-extra-cases compatibility route. POD/book/source/delivery and Knowledge Map checks pass; the error-preservation container closes.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.2.5.4: preserve nonempty zero-valued error reasons`

- ID: `PERL-POD-API-REFERENCE.6.1.2.2.6`
  Status: `done`
  Goal: `Correct the example tool's documentation result type without altering returned metadata.`
  Acceptance: `The actual examples result carries the public documentation section object, but outputSchema declares an array. Correct the declaration to its authoritative current contract; never reshape correct public values to satisfy a wrong schema. Compare complete actual documentation/catalog records with the capability manifest, text/structured results and schema metadata, include wrong-type controls, synchronize precise guidance and commit. Promote the new type fact within the unchanged Knowledge Map allowance, preserving all original questions/metadata and fact meanings through explicit scoped-ID abbreviation.`
  Verification: `Fresh real-server RED fails the declared array type. Repaired live cohort passes all five tests; four focused Perl files/18 subtests and native documentation paths pass. Complete before/after source/frame/value joins conserve all eleven non-discovery exchanges, including five example queries, default resource/alias and documentation selector. Only the documentation descriptor changes to its existing open-object contract. Five restored-schema/changed-object/borrowed-catalog/text/source controls reject. New FAQ preserves all original routes and existing metadata/fact meanings within unchanged Knowledge Map authority; native POD/book/source/delivery qualify.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.2.6: declare examples documentation as an object`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3`
  Status: `active`
  Children: `PERL-POD-API-REFERENCE.6.1.2.3.1, PERL-POD-API-REFERENCE.6.1.2.3.2, PERL-POD-API-REFERENCE.6.1.2.3.3, PERL-POD-API-REFERENCE.6.1.2.3.4, PERL-POD-API-REFERENCE.6.1.2.3.5`
  Goal: `Join every public result contract and documentation obligation into a complete gap matrix.`
  Acceptance: `Follow the manifest's full contract-surface graph, current report/schema producers, typed VIAL inspection contract and relevant book/POD. Inventory every public field family, nested record, meaning/unit/order/optionality/version/identity/failure boundary and its canonical documentation, stability and representative evidence. Names or object schemas alone do not count as semantic explanation. Separate compact/full variants and source temporal/schedule/runtime availability; retain explicit omissions and exact owners. No private compiler implementation is promoted to public API.`
  Verification: `Pending result-model/documentation census after interface repairs. Reproduced documentation debt: the book semantic_introspection JSON excerpt omits the currently shipped VIAL inspection tool/template, while live discovery and the following VIAL section include them. The gap matrix must own its refresh or explicitly partial presentation before reference completion; existing discovery remains authoritative.`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.1`
  Status: `done`
  Goal: `Freeze the complete public result-root and owning-contract graph after interface repairs.`
  Acceptance: `Recover canonical model facts and R13/read-only boundaries. Capture or source-bind actual full manifest, versioned VIAL/inspection capabilities, published tools/resources/templates and wrapped/direct roots. Join every selected root and advertised contract surface/owner/schema identity to its exact producer and public scope, recording duplicates/aliases and explicit private/execution exclusions. Preserve complete raw data, selected source/runtime custody and meaningful missing/extra/wrong-owner/borrowed-root controls. Classify this as root topology, not complete field semantics or documentation. Refine later model cohorts from the observed graph, synchronize the book's interpretation/discovery guidance and commit before descending.`
  Verification: `Qualified MCP/native capture retains 30 exchanges and 433 selected inputs. Independent root/owner/schema projection verifies 45 observed roots, 22 declared tool/template roots, every owner/reference/schema-slot occurrence and no unresolved declared owner, with nine omission/binding/type/completion/execution controls. Tool owners derive through all family domains, preserving hardware/VIAL alternatives. Native manifest/versioned capabilities/inspection bindings match complete MCP values. POD/book explain discovery, envelopes and separate API metadata; adapter runtime bytes preserve. Deeper model semantics remain explicit pending successors.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.3.1: qualify public result roots and contract ownership`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2`
  Status: `active`
  Children: `PERL-POD-API-REFERENCE.6.1.2.3.2.6, PERL-POD-API-REFERENCE.6.1.2.3.2.1, PERL-POD-API-REFERENCE.6.1.2.3.2.2, PERL-POD-API-REFERENCE.6.1.2.3.2.3, PERL-POD-API-REFERENCE.6.1.2.3.2.4, PERL-POD-API-REFERENCE.6.1.2.3.2.5`
  Goal: `Inventory nested manifest/capability/support/diagnostic/documentation model families and public ownership.`
  Acceptance: `Refine from .3.1. Follow all public metadata owner/key-family/schema maps and catalog compact/full variants. Inventory field families and dynamic-map/array element models with meaning/version/optionality/order/identity/extension boundaries and canonical prose/evidence. Separate metadata advertising another API from operations the MCP server actually offers. Record every semantic-doc gap and exact successor; retain full source/graph custody and commit bounded cohorts without declaring names or schema keys sufficient.`
  Verification: `Root topology is qualified at 1757aa395. Selection .6 is complete; the common-shell field census .1 is first, followed by the remaining exact metadata cohorts.`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.6`
  Status: `done`
  Goal: `Select bounded metadata field-census cohorts from the qualified root graph.`
  Acceptance: `Use the qualified public root/owner graph and canonical contracts to separate common shell/provenance, discovery/catalog/diagnostic/documentation, export/embedding, language/backend/verification and final metadata closure obligations. Preserve delegated specialized VIAL coverage and every model/doc debt; select the first exact active field census without altering shipped behavior.`
  Verification: `Five exact child cohorts now own all metadata categories, with .3.2.1 first. Canonical manifest/producer contracts and builders, current guide/POD and qualified root data were reviewed. Tool/build/version/revision provenance is distinct from schema/protocol authority; best-effort git_commit may be unknown and is not a release/replay identity. No runtime change or source query. This planning checkpoint declares no field-interpretation completion.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.3.2.6: select bounded metadata field-census cohorts`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1`
  Status: `active`
  Children: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.4, PERL-POD-API-REFERENCE.6.1.2.3.2.1.1, PERL-POD-API-REFERENCE.6.1.2.3.2.1.2, PERL-POD-API-REFERENCE.6.1.2.3.2.1.3`
  Goal: `Inventory manifest shell, producer and common contract-record field semantics and documentation gaps.`
  Acceptance: `Use the qualified root capture and canonical producer/manifest contracts. Inventory every root-shell, producer and common identity/entrypoint/key-family/guidance field, including dynamic map/list element rules, version distinctions, ordering, requiredness, extension policy and best-effort provenance. Map semantic evidence and exact POD/book coverage; mark genuinely undefined meaning rather than inventing it or counting names/test-status prose as sufficient. Keep captured build identity distinct from operational protocol/version authority. Independently join fields/patterns to source-bound actual shapes and test missing/extra/wrong-meaning/documentation controls. Commit the bounded census and synchronized interpretation guidance before other metadata families.`
  Verification: `Root/producer .1 and section-shell records are qualified. Shared records .2 remain active with enriched normalized families next; embedding, specialized VIAL and complete common-shell join .3 follow. Every deeper obligation retains.`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.4`
  Status: `done`
  Goal: `Select exact root/producer and shared-record common-metadata census cohorts.`
  Acceptance: `Inspect the qualified native manifest and canonical root/producer sources, distinguish root maps/identity from heterogeneous common contract records, preserve every shared-pattern and deeper delegation obligation, and name exact field-census successors before implementation. Retain source-hashed selection and any demonstrated documentation omission under a repair owner; commit selection first.`
  Verification: `Source-bound selection retains all explicit contract_source/schema_version/status candidate paths, owners, statuses and entrypoint labels. Entrypoint records vary by owner and some are absent; this is not a uniform closed universal record. Root/producer, shared patterns and final joined closure now have exact successors. The reproduced missing semantic_introspection book owner-list entry is P2-owned by immediate .1. No new metadata/source runtime, schema or user behavior change.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.4: scope common metadata census cohorts`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.1`
  Status: `done`
  Goal: `Qualify the complete manifest-root and producer field semantics/documentation census.`
  Acceptance: `Join every root field, manifest_contract field, producer field and ProducerContract field, nested maps/list elements, identity flags and entrypoint shapes to complete qualified actual values and canonical sources. Explain required presence, ordering, deliberate extension and build/schema/protocol distinctions; state undefined meaning rather than inventing it. Record exact POD/book coverage and owned gaps; fix the demonstrated semantic_introspection owner-list omission. Verify omission/extra/wrong-meaning/stale-doc/source controls, synchronize interpretation guidance and commit before shared-record work.`
  Verification: `Qualified dated census independently joins 51 root/producer/contract fields and 49 nested containers to complete native values, canonical sources and exact book/POD snapshots. Original book omission is actual RED; repaired owner list and all 13 field/type/meaning/gap/map/source/document/freshness/instrument controls pass. Selected runtime source is byte-conserved. Six focused Perl files/18 top-level tests and native POD/book/source/index checks pass. The producer contract_authority stronger-definition gap stays explicit P2 under .6.4; shared records and deeper sections remain successors.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.1: qualify manifest and producer field meanings`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2`
  Status: `active`
  Children: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.1, PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.2, PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3, PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.4, PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.5, PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.6, PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.7`
  Goal: `Qualify shared metadata-record identity, entrypoint, key-family and guidance semantics.`
  Acceptance: `Use the retained complete candidate path list and root graph, plus canonical owner contracts. Inventory common field occurrences and dynamic map/list-element rules while preserving owner-specific status, version, absent-field, order and extension distinctions; supplement or delegate nonconforming/specialized records explicitly. Map exact semantic evidence and POD/book gaps without promoting advertised APIs into MCP operations. Exercise missing/extra/wrong-owner/meaning/documentation controls and commit the bounded census.`
  Verification: `Root/producer, exact shared-record selection .2.1 and section-shell census .2.2 are qualified. Enriched common records .2.3 are next, followed by embedding variants, specialized VIAL and joined closure; every candidate and deeper obligation remains owned.`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.1`
  Status: `done`
  Goal: `Partition the retained shared-record candidates into exact semantic review cohorts.`
  Acceptance: `Preserve every selected path, owner, status and entrypoint variant. Separate section shells, enriched query/report contracts, embedding contracts and specialized VIAL records; retain the already-qualified root/producer exclusions and exact deeper repair owners. Verify a disjoint complete join to the original candidate list and source-bound capture, record startup policy-source identity checks and commit before semantic census implementation.`
  Verification: `Saved common-record-cohorts.json reproduces from the original capture/selection. Independent complete native traversal equals every unique candidate path; each original owner, status and entrypoint label/value is preserved, including prior root/producer exclusions. Today's local policy hashes and read-only sibling claim template still match the complete committed adoption review. No source/runtime epoch, manual behavior or publication changes.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.1: select shared contract-record review cohorts`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.2`
  Status: `done`
  Goal: `Qualify the section-shell common fields and their owner-specific discovery maps.`
  Acceptance: `Review BackendValidationContract, DiagnosticsContract, DocumentationContract, EmbeddingContract, LanguageSurfaceContract and SemanticExportsContract against the saved complete native manifest. Inventory common identity, entrypoints, presence/key families, guidance and nested ownership/presence map rules, explicitly delegate remaining domain fields. Bind semantic statements to exact source and book/POD evidence. Exercise missing/extra/owner/type/meaning/documentation controls, synchronize a usable field guide and commit before enriched records.`
  Verification: `Qualified saved census independently joins all 87 fields and 95 nested containers across the selected six section shells, with 19 exact semantic source snapshots. Actual draft embedding-subject RED retains; corrected generator known-key union, snapshot output and registry/result/contract distinctions pass all 14 coherent adverse controls. Existing contract cohort passes Files=20, Tests=32. Native POD/book HTML/source/index/copied-byte checks and Python 3.9 syntax pass. Knowledge signpost adds one question without card byte/line growth; deeper payloads remain explicitly owned.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.2: qualify section-shell fields and nested map subjects`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3`
  Status: `active`
  Children: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.1, PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2, PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.3, PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.4, PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.5`
  Goal: `Qualify common fields in enriched diagnostic, query, support, verification and validation records.`
  Acceptance: `Follow the exact selected paths, including repeated section projections, and dedicated owner contracts. Preserve optional-tool status, report versus manifest entrypoints, registry key-family labels, MCP adapter routes, common-field absence and extension boundaries. Record complete common-field semantics and exact deeper delegations, source-bound values and POD/book gaps; exercise coherent adverse controls and commit.`
  Verification: `Exact selected enriched paths require separate identity/routes, report/registry families, query/support/verification families and final joined closure. Identity/routes .3.1 is qualified, including the discovered root presence-map repair; report/registry families .3.2 now have qualified diagnostics; normalized families are next and all deeper obligations preserve. Section-shell prerequisite is committed at 3c4f11367.`
  Commit: `pending`


- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.1`
  Status: `done`
  Goal: `Qualify identity, status, entrypoint and guidance fields across every selected enriched record.`
  Acceptance: `Join all ten selected native paths and repeated projections to dedicated owners. Census schema_version, status, contract_source, report_source, entrypoints, mcp_adapter_entrypoints and guidance, including explicit absence. Preserve report versus manifest routes, optional external-tool status, list/string shapes, ordered retained values and deliberate extension boundaries. Bind exact source and book/POD meanings with omission, type, wrong-owner/route/status, projection and freshness controls; no runtime/source epoch replay. Delegate every other field by exact path to .3.2 or .3.3, commit before family semantics. The first broader T370 gate independently exposes the existing outer semantic_introspection key-list omission of source_query_kinds. Reproduce and retain original native/source/test evidence, derive the root family from its dedicated public owner, prove exact before/after projection-only repair, keep book/POD honest, and qualify the existing independent discovery gate before closure.`
  Verification: `Final saved/current census joins ten selected records, 61 present identity-field slots, nine explicit absences, 352 exactly delegated other fields and eleven semantic source snapshots; all sixteen coherent identity controls reject. Original missing-guide RED and pre-existing T370 discovery RED retain. Root presence families now derive from the dedicated public owner; exact constructor comparison proves only the three source_query_kinds projections change, with four independent adverse controls and unchanged test oracle. Repaired focused cohort passes Files=17, Tests=30; native POD/book, rendered table, source membership/copied-byte freshness and Python 3.9 syntax pass. Original and intermediate packets/streams retain. Final staged doctrine/normal hooks gate commit; family and deeper meaning remain pending.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.1: document enriched identity and repair discovery drift`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2`
  Status: `active`
  Children: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.1, PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2, PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.3, PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.4, PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.5`
  Goal: `Qualify enriched check, normalized-report, registry and external-validation key-family subjects.`
  Acceptance: `Follow /diagnostics/check_json, /diagnostics/stable_code_registry, /semantic_exports/normalized_semantic_json and /backend_validation/systemverilog_external from .3.1. Explain common presence/key/value-family maps, exact subject and conditional-success/failure/optional/extension meanings with canonical owner evidence. Preserve all remaining field/deeper payload delegation to .3.2.2-.4 and .6.3-.6.4, test coherent wrong-subject/value-versus-key/omission controls, synchronize book/POD and commit.`
  Verification: `Source-bound review distinguishes check/registry key and value subjects, extensive normalized semantic/IR families, and optional external-validation success/failure families. Exact children retain all four native paths and every prior delegated field. Check/registry .1 is qualified; normalized .2 is next, followed by external .3 and complete join .4. All four native paths and remaining deeper ownership persist.`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.1`
  Status: `done`
  Goal: `Qualify check-report and stable-code registry family subjects.`
  Acceptance: `Use the two diagnostics paths from the final identity census. Join all shell-owned presence, optional/matched, nested-owner, grouped-key and bounded-value families to their canonical contracts and saved native observation. Explain success versus failure placement, conditional fields, diagnostic entries versus registry siblings, key lists versus allowed values, array/object ordering and extension limits. Delegate unrelated metadata and deeper diagnostic/report fields exactly to .3.2.2, .3.3 and .6.3-.6.4; retain every original field. Add precise book/POD guidance, independent source/value/meaning/doc joins and coherent adverse controls; commit before normalized families. The actual broader T383 gate exposes P2 pre-existing array-only validation at line 92 for the legitimate source_optional_fields object in both report owners. Own the blocker here: retain original test/source/log, admit this exact owner/map/family variant against ReportSourceContract, preserve array validation everywhere else, and prove actual before/after plus native wrong-owner/map/type/value/sibling controls.`
  Verification: `The source-bound saved census qualifies 34 family/owner fields across both diagnostics records and exactly retains all remaining field delegation. Original missing-guide RED and T383 broader-gate failure retain. Fourteen family-reader interventions reject; the T383 repair admits only the exact published optional-source object and rejects the formerly admitted array. Native original/repaired helper fixtures and six independent custody/status/case/source controls qualify the repair. All tests successful Files=10, Tests=1155; native POD/book, selected HTML tables, complete source/copied-byte checks, Python 3.9 grammar and Knowledge Map pass. Two inherited array-only book statements are corrected. Final staged/normal doctrines gate commit; normalized and validation families remain open.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.1: qualify diagnostic families and repair object-map audit`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2`
  Status: `active`
  Children: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.1, PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.2, PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.3, PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.4, PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.5, PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.6, PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.7, PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.8, PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.9`
  Goal: `Qualify normalized semantic report and nested-family subjects.`
  Acceptance: `Follow /semantic_exports/normalized_semantic_json and all fields delegated by the identity census. Distinguish report envelope, success semantic payload, shared diagnostic/source/producer objects, optional composition/IR records and key versus value/meaning families. Refine additional bounded cohorts before implementation if required by actual subjects. Bind every selected family to its exact object/element/conditional/extension rule and canonical owner, preserve deeper .3.2.3, .3.3 and .6.3-.6.4 obligations, exercise source/value/meaning/omission/doc controls, synchronize book/POD and commit.`
  Verification: `Envelope .1 and payload/IR baseline .2 are qualified, including the direct-helper Boolean repair and its exact current-source bridge. Symbol .3 is next. Composition, shared-datapath, lowered-control, structural and grouped-map closure remain open with all original deeper ownership retained.`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.1`
  Status: `done`
  Goal: `Qualify normalized report-envelope and shared nested-object families.`
  Acceptance: `Cover public_top_level_presence_keys, success_only_top_level_keys, command/generated_output/producer/source presence and optional families, producer_extra_presence_keys, support_accounting_presence_keys and every failure/matched diagnostic/support family. Cover their shared scalar contract-source identities, including diagnostic_summary and generation_result_snapshot. Preserve the distinction from check reports: normalized failure support is also report-level, while semantic and generation_result_snapshot are success-only. Follow exact canonical owners and saved values; preserve optional map versus arrays, matched/null/extension rules and metadata-field versus payload subjects. Qualify book/POD and coherent source/value/subject/condition controls; retain .3.2.3/.3.3/.6.3-.6.4 deeper semantics and commit.`
  Verification: `Qualified saved census joins 24 selected envelope/owner fields and preserves all 150 remaining field delegations. Independent literal public-factory source joins distinguish success/failure root sets, producer extension, base command/source and report/diagnostic support paths; twelve coherent field/condition/value/owner/source/helper/doc controls reject. Genuine pre-guide RED and the case-sensitive natural-language observer refusal retain; the corrected observer leaves exact field/value/source matching unchanged. All tests successful Files=10, Tests=18; native book/POD, selected rendered tables, full source/index/copied-byte checks and Python 3.9 syntax pass. Existing Knowledge Map signposts still route to the updated canonical guide. Final staged/normal doctrines gate commit; payload/IR baseline .2 is next.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.1: qualify normalized report envelope families`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.2`
  Status: `done`
  Children: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.2.1, PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.2.2, PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.2.3`
  Goal: `Qualify normalized semantic payload and IR-tier baseline families.`
  Acceptance: `Cover public_layers, success_semantic_presence_keys and optional children, module required/optional metrics, explicit-system, signal-analysis container/entry, system and symbol base families, success_forward_ir_presence_keys and each IR tier base/optional-composition family. Cover their scalar dedicated contract-source identities. Bind each list to its exact payload/container/element/conditional subject and preserve artifact versus live compiler objects. Join existing Knowledge Map authorities, saved native values and canonical owners; exercise omission/wrong-tier/mandatory-versus-optional/doc controls and synchronize book/POD before commit. Deeper payload and source execution remain .3.2.3/.3.3/.6.3-.6.4. Before closing, qualify the suspicious _json_ready_value reference filter against JSON booleans through a bounded synthetic public report-builder call and established JSON-kind contracts; no compiler/source epoch. Do not count a defect without establishing the supported boundary; retain exact inputs/output/source and assign an exact repair successor if confirmed.`
  Verification: `All three children qualify the payload/IR baseline subject census, direct-helper Boolean correction and exact current-source closure. Every baseline field and remaining deeper delegation conserves, dedicated contract families are unchanged, and current book/POD reflect preserved value kinds. Native DSL/CLI/MCP reachability remains unqualified under .3.3; no source epoch or capability/schema change is claimed.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.2.3: close repaired normalized baseline source qualification`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.2.1`
  Status: `done`
  Goal: `Qualify payload/IR baseline subjects and own the discovered Boolean-filter blocker.`
  Acceptance: `Complete the selected saved-native/source-owner census and usable book/POD guide, preserve every remaining field and original fact/question, and qualify meaningful omission/subject/optionality/owner/source controls plus native rendering and metadata regressions. Retain the first owner-label producer refusal. Before broad semantic closure, investigate the suspicious JSON Boolean filter through the public builder and existing JSON-kind contracts; log the exact confirmed impact and immediate repair successor without claiming native source reachability.`
  Verification: `The saved census joins 27 selected fields and 123 remaining delegations. Required/optional/nullable factory-source allocation, fifteen dedicated list oracles, exact owner labels and fourteen adverse controls qualify. All tests successful Files=22, Tests=30; native book/POD, selected HTML, current source/index/copied bytes, Python 3.9 and Knowledge Map qualify. The new nullable question preserves all original questions/facts with exact reversal and no card growth. P2 direct-builder Boolean loss is retained with actual input/output/source; .2 owns the immediate correction. Final staged/normal doctrines gate this census commit.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.2.1: qualify baseline families and own Boolean filtering defect`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.2.2`
  Status: `done`
  Goal: `Preserve JSON Boolean values in the public normalized report builder.`
  Acceptance: `Use the exact retained synthetic direct-builder failure and CompositionReportContract existing JSON::PP::is_bool handling. Add a meaningful focused CI regression through public build_normalized_semantic_success_report for true/false core fields, nested hashes/arrays and scalar-kind/value conservation; ensure private/unsupported references remain filtered, caller input and copy behavior remain valid. Retain genuine RED/GREEN, complete controlled before/after inputs/results/sources/runtime and adverse controls. Make only the confirmed JSON Boolean primitive-preservation repair, update precise book/POD/current limitation and run focused/broader direct-helper and metadata gates. No new DSL, corpus classification, metadata capability or source epoch; native CLI/MCP source reachability stays explicitly unqualified under .3.3.`
  Verification: `T2105 genuinely fails all three subtests on original code and passes with the established one-line JSON::PP::is_bool branch. Complete controlled original/repaired public-builder captures retain Perl v5.34.1/JSON::PP 4.06, exact inputs/caller observations and full reports; the independent reader proves Boolean/hash/array kind/value preservation, complete unaffected reports, private-reference exclusion and the exact source delta. Six coherent kind/array/report/case/caller/source controls reject. Broader direct-helper/metadata cohort passes All tests successful Files=7, Tests=12. Book/POD describe repaired behavior; the fact card now replays current contract/helper tests without losing facts/questions. Final native book/source/index, Knowledge Map, staged/normal doctrines qualify commit. Native DSL/CLI/MCP source reachability remains explicitly unqualified; .3 owns current baseline-source closure.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.2.2: preserve JSON booleans in normalized semantic reports`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.2.3`
  Status: `done`
  Goal: `Close baseline qualification against the repaired current source.`
  Acceptance: `After .2, join original native metadata and the qualified field census to the exact Boolean-only runtime delta, unchanged dedicated families, current source/docs/producer identity and all remaining deeper delegations. Refresh current baseline packet, Knowledge Map replay route and selected native rendering, preserve original source/probe/producer refusals and complete conservation evidence, then close the parent and resume symbol families .3.`
  Verification: `Current-source closure independently joins the complete original native baseline, exact pre/post Boolean repair, unchanged dedicated sources, current docs/producer/runtime and every field/deeper delegation. Ten coherent closure controls reject; original reader still refuses current verification of old bytes. All tests successful Files=7, Tests=26; saved baseline and qualified repair replay pass. Selected native rendering, current POD/source/index/copied bytes, Knowledge Map and final staged/normal doctrines gate commit. Initial reader-ID and focused-launch filename refusals retain with corrections; no original epoch repeats.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.2.3: close repaired normalized baseline source qualification`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.3`
  Status: `pending`
  Goal: `Qualify normalized symbol families and intent-HIR mirrors.`
  Acceptance: `Cover symbol_contract_* nested constant/enum/type/package-import key, extension, value-kind and meaning families plus success_forward_ir_intent_hir_symbol_contract_* counterparts, excluding the base presence and owner identities assigned to .2. Preserve scalar meanings versus their grouped single-element arrays, dynamic names, recursive type/aggregate extensions and exact root-versus-HIR subjects. Source-bind complete saved values, precise owner/documentation and deeper .3.2.3/.3.3/.6.4 delegation; reject borrowed/wrong-tier/value-versus-key/omission controls and commit.`
  Verification: `pending predecessor qualification`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.4`
  Status: `pending`
  Goal: `Qualify normalized child composition and intent-HIR family subjects.`
  Acceptance: `Cover composition_* non-shared-datapath child/generated-child/parameter-override/standalone-DT families and success_forward_ir_intent_hir_composition_* mirrors. Exclude composition_contract_source and the tier optional-composition baselines owned by .2; shared-datapath families belong to .5. Bind fields to exact children, overrides, raw/value-metadata extensions, DT enable and multi-drive records with root/HIR context and optionality. Refine further before implementation if necessary. Preserve dedicated/deeper ownership, use exact saved sources/docs and adverse controls, synchronize guidance and commit.`
  Verification: `pending predecessor qualification`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.5`
  Status: `pending`
  Goal: `Qualify normalized shared-datapath family subjects and lowered mirrors.`
  Acceptance: `Cover composition_shared_datapath_* and success_forward_ir_lowered_rtl_ir_composition_shared_datapath_* families. Preserve candidate/contributor/declared-type/drive-intent/enable-family/aggregate/assertion/bound-expression subjects and root-versus-lowered context. Use canonical nested owners and original complete values, not names alone; refine further where needed. Join exact optional/extension rules and deeper .3.2.3/.3.3/.6.4 delegation, exercise missing/wrong-record/owner/value/doc controls, synchronize book/POD and commit.`
  Verification: `pending predecessor qualification`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.6`
  Status: `pending`
  Goal: `Qualify normalized lowered-RTL drive and control family subjects.`
  Acceptance: `Cover remaining success_forward_ir_lowered_rtl_ir_* output-drive, RHS-enable, selector-conflict assertion/target and standalone-DT multi-drive entry families after excluding the .2 base/optional-composition and .5 shared-datapath groups. Bind exact entries, extension/optional rules and source-prediction versus execution boundaries with canonical source/saved values and existing fact cards. Preserve deeper semantics, reject wrong-field/tier/meaning/doc controls, synchronize book/POD and commit.`
  Verification: `pending predecessor qualification`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.7`
  Status: `pending`
  Goal: `Qualify normalized structural-RTL entry and extension family subjects.`
  Acceptance: `Cover success_forward_ir_structural_rtl_ir_* assignment/LHS/RHS/provenance, auxiliary-assignment kind/meaning, instance/interface/parameter override/port binding, port/source/target, net and declared/resolved-link entry/extension families; exclude its base presence list owned by .2. Refine independent structural record cohorts before implementation where warranted. Keep direct versus composition/generation and rendered-text versus typed AST limits precise, preserve exact deeper owners and saved evidence, exercise coherent subject/type/omission/source/doc controls, synchronize book/POD and commit.`
  Verification: `pending predecessor qualification`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.8`
  Status: `pending`
  Goal: `Close normalized grouped-map subjects and complete field delegation.`
  Acceptance: `Join .1-.7 to every original normalized field from enriched-identity-final.json.gz. Qualify nested_contract_source_map, nested_presence_key_map, presence_key_family_map, semantic_presence_key_family_map, semantic_nested_presence_key_map and both forward_ir_nested maps with exact per-member subjects and their documented scalar/array/object projection rules. Preserve every remaining non-family metadata field under exact .3.2.3/.3.3/.6.4 owners and all identity fields under prior .3.1. Prove no omission/duplicate/lost projection or wrong subject, preserve complete source/doc custody and commit closure before optional-validation .3.2.3.`
  Verification: `pending predecessor qualification`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.9`
  Status: `done`
  Goal: `Select bounded normalized family cohorts before qualification.`
  Acceptance: `Read the existing normalized identity delegation, saved native record, public report/payload owners and relevant optional/structural fact cards. Split heterogeneous subjects into concrete children, retain every parent obligation and exact next action, verify task/Git continuity and existing declaration rules, and commit selection before .1. No source query, backend epoch or public behavior change.`
  Verification: `Saved native record and source-owned maps confirm the separate subjects; the original field census stays authoritative and .8 must prove complete allocation. The optional-child and structural assignment fact cards were consulted before source review. This selection closes no semantic/documentation gap. Task integrity and staged/normal doctrine gates qualify the continuity-only split.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.9: scope normalized semantic family cohorts`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.3`
  Status: `pending`
  Goal: `Qualify optional external-validation success and failure family subjects.`
  Acceptance: `Follow /backend_validation/systemverilog_external. Explain required/optional tool and stage-name values, success top-level/step key families, failure categories and text-prefix maps with their exact subjects and optional in-process ABC distinction. Do not infer installation, execution, frozen complete error text or MCP execution. Preserve unrelated metadata and deeper .3.2.4/.6.4 owners; bind source/saved values/docs, exercise wrong-key/value/availability/prefix controls and commit.`
  Verification: `pending preceding selection/qualification`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.4`
  Status: `pending`
  Goal: `Close the joined report/registry/validation family qualification.`
  Acceptance: `Join .1-.3 to all four original native paths and exact final identity-census field delegations. Prove every field has a qualified common-family subject or an exact deeper repair owner, preserving report/manifest distinction, conditional/optional/value rules and source/document custody. Reject missing/duplicate/wrong-subject/owner/stale joins and commit before enriched query/support/verification .3.3.`
  Verification: `pending preceding selection/qualification`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.5`
  Status: `done`
  Goal: `Select independently reviewable report/registry/validation cohorts.`
  Acceptance: `Read the saved identity delegation and dedicated public owners before implementation. Preserve all four paths, separate heterogeneous families into bounded exact children with complete acceptance and deeper ownership, verify task/policy/Git continuity and commit selection before .1. If normal task growth reaches its declared warning-debt allowance, apply the existing measured-actual-plus-ratchet procedure without raising any ceiling and retain the first refusal.`
  Verification: `Qualified final identity census and dedicated CheckDiagnosticsContract, DiagnosticCodeRegistryContract, NormalizedSemanticReportContract and HDLExternalValidationContract separate the selected subjects. Current README, memory/lifecycle/claim/doctrine/toolbox and R13 direction were recovered; cleanup is current and Git was clean. Task integrity and staged/normal doctrines qualify selection. No runtime or manual behavior change.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.5: scope report registry and validation family cohorts`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.3`
  Status: `pending`
  Goal: `Qualify enriched query, support and verification key-family subjects and repeated projections.`
  Acceptance: `Follow semantic_introspection, support_accounting and verification_outputs plus their section_contract projections from .3.1. Preserve absent common fields, manifest versus contract subjects, query name/value families, catalog required/optional fields, artifact and inert-validation boundaries. Bind grouped families to dedicated contracts and canonical documents; retain exact deeper .3.2.2-.4, .6.3-.6.6 owners, reject coherent wrong-subject/availability/omission controls and commit.`
  Verification: `pending preceding enriched report/registry family qualification`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.4`
  Status: `pending`
  Goal: `Close the joined enriched common-record census and every deeper field delegation.`
  Acceptance: `Independently join .3.1-.3 identity and family records to all selected native paths, owners, repeated projections, absent common fields, source-bound values and exact documentation routes. Prove each field has qualified common meaning or an exact deeper owner, reject missing/duplicate/wrong-owner/meaning/stale-document joins and commit before embedding .2.4.`
  Verification: `pending all enriched cohorts`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.5`
  Status: `done`
  Goal: `Separate enriched identity/routes from heterogeneous family semantics before implementation.`
  Acceptance: `Preserve all original selected paths and parent obligations; give each child a bounded concrete scope, independent checks and exact successor. Recheck selected source/canonical contracts, current policy identities, Git/task integrity, and commit this decomposition before implementing .3.1.`
  Verification: `Selected saved cohort has ten exact paths under seven dedicated owners. Source review confirms optional_when_tools_installed versus bounded_public, report versus manifest entrypoints, registry labels, repeated projections and absent guidance. These require separately reviewable identity and heterogeneous family cohorts. All selected startup policy hashes and read-only sibling template match the retained review; cleanup is current. Final integrity/doctrine gates qualify this documentation-only split, with no manual behavior change.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.5: separate enriched identity and family qualification`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.4`
  Status: `pending`
  Goal: `Qualify common fields in embedding facade, result, snapshot, extension and debug contracts.`
  Acceptance: `Follow the selected embedding paths and dedicated owners, preserving singular entrypoint, absent report_source/entrypoints, manifest strings, in-process arrays and extension-specific labels. Distinguish raw presence shells, JSON fragments and serializable snapshots; explain family_map versus presence-key maps without flattening their meanings. Bind exact common fields, semantic sources, POD/book coverage and deeper owners; exercise adverse controls and commit.`
  Verification: `pending enriched-record qualification`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.5`
  Status: `pending`
  Goal: `Qualify specialized VIAL shared fields and retain exact deeper typed-model delegation.`
  Acceptance: `Join every selected specialized VIAL path and repeated projection to its owner, status, schema/version and actual entrypoint/implementation_entrypoints/guidance shapes. Preserve private/public and execution/emission/inspection distinctions without running a backend or inspecting submodules. Map precise common-field meaning and documentation gaps, retain .3.4 typed-model and .3.2.4 capability delegation, exercise wrong-owner/availability/omission controls and commit.`
  Verification: `pending embedding-record qualification`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.6`
  Status: `pending`
  Goal: `Close the joined shared-record common-field census without losing a candidate or gap.`
  Acceptance: `Join all selected candidates and prior root/producer exclusions to qualified common fields or exact specialized delegation. Prove unique complete membership, preserve absent/nonconforming records, owner-specific meaning and every deeper documentation obligation. Reject dropped/duplicate/wrong-owner/meaning/stale-document cohorts and commit before the parent common-shell closure.`
  Verification: `pending all shared-record cohorts`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.7`
  Status: `done`
  Goal: `Synchronize inherited precursor descriptions with the completed section-shell child.`
  Acceptance: `The final committed handoff review finds the parent verification still selecting .2.2 and the next leaf still referring to pending section-shell qualification. Correct those descriptions against the done child and current Memory/index, preserve exact next-action ownership, verify integrity and doctrine gates, and commit the continuity repair. No implementation or manual behavior changes.`
  Verification: `Exact parent/successor descriptions now agree with the done section-shell child and the unchanged Memory/index .2.3 frontier. Task integrity and final staged/normal doctrine gates validate this continuity-only repair. Runtime, saved evidence, book and publication boundaries are unchanged.`
  Commit: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.7: synchronize section-shell completion pointers`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.1.3`
  Status: `pending`
  Goal: `Close the full common-shell census and retain every documentation obligation.`
  Acceptance: `Join root/producer and shared-record populations/patterns to complete actual shape, canonical evidence, aliases and exact documentation repair owners. Prove no dropped or duplicate field family, preserve genuinely undefined/partial semantics and deeper metadata/VIAL/report delegation, run coherent gap/source/wrong-meaning controls and commit closure before .3.2.2.`
  Verification: `pending both semantic cohorts`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.2`
  Status: `pending`
  Goal: `Inventory introspection discovery, diagnostic, support/catalog and documentation metadata field families.`
  Acceptance: `Refine exact leaves before work. Cover discovery tool/family/domain/resource/source-kind/owner maps, diagnostic registry and report-advertisement metadata, support aggregates and compact/full/catalog/discovery variants, and grouped documentation paths/contracts. Preserve all dynamic identifiers, optional diagnostic fields, ordering, counts/units, enum/default/version/extension semantics and query/limit scope. Join dedicated owners and actual data to complete semantic descriptions and exact documentation gaps; schedule every omission and commit bounded cohorts.`
  Verification: `pending common shell`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.3`
  Status: `pending`
  Goal: `Inventory semantic-export and embedding contract advertisements without promoting raw/private payloads.`
  Acceptance: `Refine nested cohorts from actual graph owners. Map normalized report, serializable snapshot/plan, facade/result, composition, debug-runtime and extension metadata families, separating descriptive contracts from results obtainable through MCP and separately owned in-process APIs. Explain all public field-family, copy/stability/safety/identity/optional/version/extension records and source/IR branch relationships, mark private/live hash exclusions and incomplete documentation, then commit bounded cohorts.`
  Verification: `pending root/common shell and dedicated owner reads`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.4`
  Status: `pending`
  Goal: `Inventory language/backend/verification capability metadata with exact delegated VIAL coverage.`
  Acceptance: `Refine bounded families from the graph. Cover public language/file/feature/status metadata, external validation descriptors, verification target/artifact/signal/observation/source/validation metadata and contract-family maps. Explain availability versus advertised separate execution APIs, dynamic IDs, units, versions, extension/stability boundaries and source evidence. Delegate specialized VIAL tooling/inspection/execution-schema descriptions explicitly to .3.4 while retaining every owning metadata path and gap obligation; no schema-name-only completion. Commit each bounded census.`
  Verification: `pending metadata cohorts`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.2.5`
  Status: `pending`
  Goal: `Close the full metadata field-family inventory and preserve every documentation obligation.`
  Acceptance: `Join .3.2.1-.4 fields/patterns, root aliases and delegated VIAL rows to actual producer/contract data and exact .6.2-.6.6 documentation owners. Prove no omitted/duplicate/dropped field family, keep partial/absent semantics explicit and include coherent wrong-owner/meaning/stale-doc controls. Record the bounded public versus merely observed extension distinction; commit the complete metadata census before source-report and final gap-matrix closure.`
  Verification: `pending full metadata field census`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.3`
  Status: `pending`
  Goal: `Inventory normalized hardware check/semantic/schedule result models and applicability.`
  Acceptance: `Refine exact cohorts from the root graph and public report contracts. Map complete normalized source/provenance/diagnostic/generated-output/support, semantic IR and schedule families to owners, public producer schemas, units, temporal meaning, optional/null/absent cases, format applicability and existing actual evidence. Keep raw parser/scheduler/generator objects excluded. Use existing qualified source records first; any genuinely required new public query requires its normal admission and owning leaf. Schedule all exact field/doc gaps and commit each bounded cohort.`
  Verification: `pending root topology; saved source epochs remain sealed`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.4`
  Status: `pending`
  Goal: `Inventory typed VIAL source/check/inspection and capability models with precise temporal/execution boundaries.`
  Acceptance: `Refine exact version/record cohorts from .3.1. Follow the public v1/v2 tooling and typed source-inspection contracts, including nested semantic groups, expressions/intents, identity/import limits, failures and source locations. Distinguish source temporal declarations and schedule predictions from actual lifecycle/backend execution evidence and unavailable MCP execution controls. Map each model/field family to meaning, ordering, units, optionality, version and canonical documentation, without inspecting submodule internals or running sealed epochs. Retain exact evidence and schedule missing semantics before committing.`
  Verification: `pending root topology; no new simulation/backend execution`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3.5`
  Status: `pending`
  Goal: `Join every public model/field/documentation obligation into the exhaustive operating-reference gap matrix.`
  Acceptance: `Join all .3.1-.4 populations and aliases to exact POD/book locations, representative actual evidence and .6.2-.6.6 successor owners. Mark absent/partial/complete semantics explicitly; field-name/schema-only stubs remain gaps. Carry original VIAL excerpt omission, the main MCP error-code paragraph's missing -32602 and remaining reference-address/protocol debt into their exact scheduled fixes. No model, dynamic family, version, failure or source/schedule/runtime boundary may disappear between inventories. Verify omissions/duplicates/stale/wrong-owner controls and commit before .6.1.2.4 final cohort selection.`
  Verification: `pending full model inventories; original excerpt/code-list debt stays P2-owned by .6.2/.6.3`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.4`
  Status: `pending`
  Goal: `Select exact exhaustive reference cohorts and close the initial audit.`
  Acceptance: `Join .1-.3's complete populations to documentation-gap owners and refine .6.2-.6.7 into bounded exact leaves, preserving every method/tool/resource/template/field/model/error/workflow obligation. Require no unexplained omission, retain original source/metadata/schema failures and evidence limits, commit the audit and select the first operational-reference leaf.`
  Verification: `pending live/schema/model/documentation inventory`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.2`
  Status: `pending`
  Goal: `Document connection, lifecycle, protocol and host safety contracts completely.`
  Acceptance: `After .6.1, split exact cohorts as needed. Cover launcher/configuration and roots, one-shot versus persistent stdio, UTF-8 framing, handshake/version/capabilities, discovery, requests/notifications/IDs, server shutdown, pagination/progress/cancellation/concurrency and all unavailable negotiated features. Describe actual behavior and error envelopes with executable success/refusal examples. Compare pinned official MCP requirements where relevant, own real discrepancies, preserve existing implementation scope and qualify native rendering before each commit. P2 original census reference-address error findings are explicitly scheduled here: qualify current resource/protocol inputs and own confirmed repair leaves before lifecycle/reference signoff.`
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
  Verification: `Pending result-model/schema inventory. Explicit P2 from .6.1.2.3.2.1.1: ProducerContract declares producer.contract_authority Boolean, currently true, without a stronger definition. Resolve exact supported meaning from an explicit canonical contract decision or preserve that undefined boundary in the final reference; never infer trust, release or compatibility. Qualified census and book/POD retain the gap.`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.5`
  Status: `pending`
  Goal: `Provide complete agent/human workflows including temporal questions and current execution limits.`
  Acceptance: `Build discover/select/check/inspect/schedule/diagnose/recheck workflows using real current tools/resources and explicit goal/decision/output examples. Explain source temporal declarations, typed lifecycle conditions/action bodies, schedule timing and any actual temporal execution access separately. Explicitly state which authoring/editing/generation/simulation/debug/iteration steps need external host capabilities or remain unavailable, and link their owned roadmap tasks. Execute every documented workflow and adverse branch; claim no CPU/DSP/MCU/ASIC/SoC end-to-end capacity without corresponding qualification.`
  Verification: `pending exact capability and data-contract census`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.6`
  Status: `active`
  Children: `PERL-POD-API-REFERENCE.6.6.1, PERL-POD-API-REFERENCE.6.6.2`
  Goal: `Guard complete MCP documentation coverage and runnable examples against drift.`
  Acceptance: `Join the exhaustive published methods/tools/resources/templates/schema/applicability population to explicit reference records and executable examples. Derive field membership from authoritative producers/schemas and verify descriptions and canonical links, not copied counts. Add genuine missing-surface/field/stale-schema/wrong-result controls without tests that only mirror implementation. Integrate focused checks through existing workflows, preserve all original failures and commit bounded guards.`
  Verification: `pending completed documented cohorts`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.6.1`
  Status: `pending`
  Goal: `P2: repair claim-scanner paragraph-continuation versus list-marker ambiguity.`
  Acceptance: `Reproduce the actual classify_prose false-incidental result for the API guide's continued default literal 10. and compare its native mdBook paragraph rendering. Trace the line-only list-marker stripping and relevant history before fixing it. Preserve real ordered-list navigation exclusions while treating continued contractual numeric prose conservatively; add actual paragraph/list/fence/adversarial controls, reclassify every affected current candidate with full owned evidence and update canonical policy/tool/book guidance if its contract changes. Commit before the remaining MCP coverage guards. Until then, author numeric policy prose unambiguously and explicitly disposition every policy table row; do not infer complete semantic classification from the scanner's green structural join.`
  Verification: `Discovered during .6.1.2.2.4.3 claim publication. The current classifier strips a physical-line 10. prefix without Markdown paragraph context. Source/renderer/native-function evidence is retained in integer-limits-claim-context.json. The numeric-limit policy rows retain independent producer/oracle/watcher coverage; this is a classification gap, not evidence that those limit claims are false. The current paragraph is rewritten unambiguously. Priority P2, scheduled first in .6.6 before final reference signoff; not a pivot from the numeric slice.`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.6.2`
  Status: `pending`
  Goal: `Complete the exhaustive MCP reference membership, field and runnable-example drift guards.`
  Acceptance: `Refine exact guard cohorts from the completed .6.1 inventory and .6.2-.6.5 reference/workflows. Fulfill every remaining .6.6 coverage obligation with independent published-surface/schema/result joins and actual missing/stale/wrong-result controls. Preserve the scanner repair and its classification limitations; no name/schema-only stub counts as documented semantics. Split safely before implementation and commit each guard cohort.`
  Verification: `pending completed reference cohorts and .6.6.1`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.7`
  Status: `pending`
  Goal: `Qualify the complete MCP operating reference and restore required feature delivery.`
  Acceptance: `Require an exact source/runtime/schema/documentation join with no unexplained surface/field omissions, all real-server workflow/result/refusal controls, native POD/book/link delivery and relevant regression/doctrine checks. Review the human and AI navigation and operational completeness against .6.1's entire inventory. Preserve explicit capability and hosted/platform limits, commit cleanly, clear the message and restore ISF-REDUCTION-DELIVERY.2.3.2.4.2.`
  Verification: `pending complete MCP reference`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.7`
  Status: `done`
  Goal: `Complete startup maintenance while preserving the selected MCP documentation frontier.`
  Children: `PERL-POD-API-REFERENCE.7.1, PERL-POD-API-REFERENCE.7.2`

- ID: `PERL-POD-API-REFERENCE.7.1`
  Status: `done`
  Goal: `Perform the due safe daily artifact census and refresh its latest-only record.`
  Acceptance: `Authenticate and reuse the published census through a new exclusive dated wrapper bound to native HEAD and prior cleanup bytes. Require elapsed-time admission, same-volume regular log/bin census, independent rg membership, root/Rust locations and saved adverse controls. Retain every candidate without exact disposal authority; update latest-only record and book replay route, pass focused and staged doctrine gates, and commit before policy review or metadata work.`
  Verification: `Actual elapsed-time admission at native a13376d4b passes; authenticated published collector records same-volume regular log/bin lstat metadata, root/Rust locations and independent rg membership. Saved replay and missing-member/unsafe-path/Boolean-size/invented-removal controls pass. All candidates retain; no disposal authority or physical reclamation is claimed. Initial sandbox RAM-guard refusal and approved supervised outcome retain. Latest-only record and book replay route update; focused and required gates recorded below.`
  Commit: `PERL-POD-API-REFERENCE.7.1: refresh safe daily artifact census`

- ID: `PERL-POD-API-REFERENCE.7.2`
  Status: `done`
  Goal: `Review the director-selected README, claim and containment policy sources for adoption changes.`
  Acceptance: `Read the named local policy/guide and read-only sibling claim template. Compare neutral normative contracts to the locally adopted authorities and retained prior review; preserve meaningful differences and source identities, adopt only necessary local changes under exact ownership, or record why none is required. Never write outside this Git repository. Commit review before resuming the selected common metadata census.`
  Verification: `Complete selected sibling claim bytes equal the retained 2026-09-23 reviewed template; existing decision0104 adaptation remains applicable. Canonical local README policy and complete containment bridge match adopted authority/lifecycle/derived-state/pressure/retrieval contracts. Dated source identities, dispositions and evidence legs retain in docs/audits/startup-policy-review-20261024.json. No policy, runtime, mdBook behavior, ceiling or external repository write required.`
  Commit: `PERL-POD-API-REFERENCE.7.2: verify startup policy-source adoption`

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


## Acceptance Checklist — .6.1.1.2

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'sample_entry_keys' -1 -- t/1445-semantic-introspection-mcp-schema-snapshots.t` identifies a1cc9414a, which snapshots one arbitrary first entry. That same revision's adapter already conditionally includes diagnostic_code; its optional projection originates in c0204a138. The current first entry language.isf_storage_identifier.rejection carries that code (its corpus insertion is 089224807). This identifies the current sample and original observer weakness, not the first historical failing run. The original c63f76753 adapter and repaired adapter produce identical complete projections and the same original snapshot failure.
- [x] **ADDRESSED (verified)** — Normalize only the declared diagnostic_code optional key in the schema projection and add its explicit optional-key declaration to the golden fixture. All other golden members remain identical. Real diagnostic/non-diagnostic catalog entries are reordered both ways without dropping members; actual complete sample values and text/structured equality qualify, with unchanged original manifest. Missing common fields and new unknown fields still fail the same observer. POD/book explain every compact field, optionality, catalog order and larger full-resource boundary. Production runtime code outside POD matches fe68b8458 exactly.
- [x] **NO REGRESSION** — All tests successful. Files=23, Tests=64 across the complete MCP protocol/schema/source-failure/large-UTF-8 cohort. The fixed snapshot's focused run also passes. Native book/source/index/full generated-delivery and the new field-link/actual-anchor checks pass; all full outputs are retained.

### .6.1.1.2 bounded fixture repair and reference evidence

- snapshot-regression.log.gz retains the complete now-green cohort. The prior
  23-file refusal, exact old/current full projections and original fixture are
  retained by .6.1.1.1. probe_snapshot.py is that dated producer at fe68b8458;
  replay its original test/fixture boundary rather than applying the old
  failing assertion to the repaired current fixture.
- snapshot-fixture-conservation.json independently compares complete parsed
  old/current golden files. Only the declared optional-key path is added; no
  unrelated protocol/schema projection is refreshed. Unknown-key and missing-
  common-key interventions prove the observer is not merely ignoring changes.
- The actual support query retains current sampled records. Re-derivation is
  the real source-backed variant calls and full cohort; falsification is the
  original same-projection failure, reversed optional variants and hostile
  missing/extra fields; durability is tracked test/fixture, exact captures,
  code/golden conservation, public field guidance and Git history.
- The first native anchor assertion catches an incorrectly guessed hyphenated
  heading. Pod::Simple publishes CATALOG_SAMPLE_RESULTS with underscores;
  the corrected exact native link and anchor are checked. The initial refusal
  and both builds remain retained; no broken new reference is committed.
- The clean successor is .6.1.2's exhaustive operational-reference census.
  The compact sample dictionary is one qualified result cohort, not completion
  of all endpoint, report-schema, temporal or agent-workflow documentation.
  Historical publication/full-CI, broader manual links and platform limits keep
  their existing owners. No required external server/fixture process remains.


- Final precommit review corrects an overbroad uncommitted draft: examples
  catalog_entries retain full public records, while support-summary and
  diagnostic samples are compact. The examples query's embedded support
  summary has zero samples. Complete actual example-record and text/structured
  assertions now guard this distinction in both real catalog orders. The
  superseded staged draft is retained with source hashes; no incorrect draft
  is published. The final 23-file/64-test cohort is rerun green, and current
  production code conservation is requalified. Final native source checks
  require complete restaging after the pointer update; the first expected
  source-plane refusal is retained and the unchanged guard reruns before commit.


### .6.1.2 initial schema-census checks to resolve

- Source review identifies two potential published-schema gaps for actual
  measurement: source-bound tool schemas have no required identity alternative
  despite runtime requiring source_id or source_path; explain_diagnostic's
  schema advertises code alone while the existing book/test and payload
  producer accept limit_examples. Capture actual advertised schemas and real
  refusals/results before classifying or repairing either. The census owns
  full argument/default/limit/error conformance; no new tool is authorized by
  this observation, and existing schema/API compatibility must be preserved.


- Also measure capability_query's payload declaration against every public
  manifest section: the adapter returns the selected section value while the
  advertised payload property is currently object-only. Array/scalar sections
  must be observed before classifying any output-schema mismatch. Limit/default
  differences between discovery, examples and diagnostic samples are census
  obligations, not automatically permission to change established semantics.


### .6.1.2.1 live measurement frontier

- inventory_mcp.py captures the real persistent handshake/discovery, every
  static resource, every public manifest section, all tool metadata and focused
  argument/limit/refusal cases. It joins runtime names to the independent
  manifest declarations, fingerprints all tracked FSM modules and selected
  launchers/schema/docs against HEAD, and verifies unchanged inputs and orderly
  EOF. Raw UTF-8 exchanges and complete decoded values are retained locally.
- Observed schema/validation/error discrepancies are owned by exact .6.1.2.2
  children above. The saved-reader, adverse controls and bounded capture commit
  must finish before source repair. No hardware compilation or temporal run
  occurred; this is metadata/interface evidence, not end-to-end design capacity.
- MCP's pinned tools specification requires structured results to conform to
  advertised output schemas and describes input validation:
  https://modelcontextprotocol.io/specification/2025-06-18/server/tools.
  Complete human/AI reference semantics remain in the planned result/document
  matrix; names and schema objects alone do not close that requirement.


## Acceptance Checklist — .6.1.2.1

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'outputSchema' -1 -- perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm` identifies 837eb3c92's envelope schemas. Actual ordinary capability-version/example results violate the declared payload/documentation types. The live publisher also omits source identity alternatives and the existing diagnostic limit argument, accepts some invalid metadata arguments and retains private references/locations in errors. Complete raw exchanges, published declarations and source-boundary custody make each discrepancy reviewable; exact .6.1.2.2 leaves own repairs before field-reference completion.
- [x] **ADDRESSED (verified)** — The bounded metadata audit now covers all published methods/tool/resource/template names and named schema properties, joins them to independent manifest/dispatcher/Git definitions, and rechecks the durable compressed capture. Missing/extra/borrowed field or member, lost reply, Boolean identity and stale-source interventions reject. The prepublication reader numeric-enum control first fails, then accepts equivalent numeric spellings while rejecting Boolean aliases under the pinned JSON Schema rule. The book discloses actual compatibility defects; none is misrepresented as repaired or conformant.
- [x] **NO REGRESSION** — All selected runtime modules, launcher/client/schema inputs at capture match ed92d0a12; its MCP cohort is recorded as All tests successful Files=23, Tests=64. This metadata-only audit runs no source/compiler epoch. Actual saved-reader/controls pass, both new Python producers parse as Python 3.9 grammar, and the unchanged launcher reports:

  bin/fsmgen-mcp syntax OK

### .6.1.2.1 evidence legs and next action

- Re-derivation is the real persistent collector, complete raw UTF-8 exchanges
  and publisher/manifest/dispatcher joins. Falsification is the independent
  saved reader's eight actual missing/extra/borrowed/type/wire/source mutations
  plus numeric/Boolean schema controls. Durability is the compressed exact
  capture, custody hashes, selected Git source boundary, complete outputs,
  tracked collector/reader and audit README. No count substitutes for field
  semantics or complete backing-model documentation.
- The bounded reader supports exactly its declared schema keyword subset,
  checks all emitted branches for unhandled keywords and preserves findings.
  The numeric control's original source/result is retained. Instance equality
  follows the pinned JSON Schema mathematical-number rule with Boolean types
  distinct; no general-validator or arbitrary toolchain-footprint claim is made.
- Current limits/defaults are captured per operation and are not silently
  normalized into a single policy. Invalid-argument observations are evidence
  of defects, not newly promised argument forms. Finding categories may
  overlap within one exchange; they are not counts of distinct product bugs.
- The API guide now records the six measured client compatibility gaps. The
  field/result/workflow matrix remains .6.1.2.3/.4 and .6.2-.7; schema names or
  opaque object schemas alone do not satisfy the director's thoroughness goal.
- After the required source/native/staged/normal commit gates, clear the
  message, verify clean state and activate .6.1.2.2.1's identity-schema repair.
  No server, child or required verification process remains from the capture.


- The first staged doctrine pass rejects the repair container's pending status
  after it gains children. Set only that container active, as required by the
  existing task-tree vocabulary; its implementation leaves remain pending.
  Retain the original refusal and rerun the unchanged integrity/native/staged
  gates. This tracking correction changes no interface or source behavior.


- The next doctrine pass identifies the new nested audit README as uncovered.
  Register exactly this dated evidence landing as a bounded snapshot with its
  own review-envelope-derived budget. No broad audit wildcard, existing ceiling
  or Knowledge Map allowance increases. Task warning growth uses the unchanged
  measured-ratchet policy. Retain the full refusal, refresh the
  derived inventory after final staging and rerun the same gates.

## Acceptance Checklist — .6.1.2.2.1

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S '_source_tool_properties' -1 -- perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm` identifies 129cfae08: source descriptors declare no required alternative and accept empty selector strings, while the runtime already rejects them. The qualified live census and new original regression demonstrate the mismatch; all original valid and refusal products are retained.
- [x] **ADDRESSED (verified)** — Source discovery uses anyOf, allowing either or both selectors, and minLength for every supplied selector. The two real persistent regressions pass. Complete saved results preserve all 12 valid reports and 51 refusal reasons/codes; coherent controls detect a missing call, changed full report, lost requirement and lost wire reply at the intended checks. Other discovery metadata and runtime code conserve. POD/manual explain precedence, nonempty unused selectors, workspace/applicability and VIAL boundaries.
- [x] **NO REGRESSION** — All tests successful. Files=23, Tests=64 across existing MCP protocol/schema/source-failure/UTF-8 tests. New actual selector/version regressions pass; saved-reader controls, syntax and native POD/book/source/delivery gates qualify. The changed module reports:

  perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm syntax OK

### .6.1.2.2.1 evidence and continuity

- Re-derivation: real persistent pre/post discovery and source requests, complete
  raw UTF-8 exchanges and actual reports in source-identity-before/after.json.gz.
  Falsification: the separate saved reader joins raw frames/decoded records,
  exact descriptor changes and full valid results; four coherent interventions
  target distinct checks. Runtime code outside the named descriptor/POD regions
  is byte-identical. Durability: tracked captures, selected source/observer SHA,
  replay reader, comparison, original fixtures and complete compressed logs in
  docs/audits/mcp-api-reference-20261023/. No whole-platform/runtime claim.
- Initial helper invocation failed before capture because local_path lacked its
  root argument; corrected before the qualified capture. Original short pipe
  deadlines expired during native compilation; complete replies and clean exits
  retain. Source requests now use a bounded 120-second deadline. The transport
  ping tests retain their shorter deadline; no latency guarantee is inferred.
- Knowledge Map records the selector fact without increasing aggregate card
  bytes, dropping questions or growing any allowance. Existing facts remain.
  The current guide removes only the repaired compatibility row; the remaining
  measured defects retain exact repair owners. The book's older manifest excerpt
  omission is owned by .6.1.2.3's scheduled exhaustive documentation matrix.
- After normal commit gates, clear the message and verify a clean tree. Next:
  .6.1.2.2.2, advertise the existing diagnostic sample-limit argument without
  silently changing its current default/zero semantics. No source epoch is open.
- Captures name the predecessor HEAD and fingerprint the actual observed
  files, including uncommitted repair/observer sources. The saved reader can
  recover those exact bytes from the eventual slice commit after current code
  changes; it never substitutes predecessor bytes for the repaired producer.
  The first native delivery check omitted the required --verify-build path;
  the full refusal retains and the correct docs/book/book invocation passes.
- The first staged gate catches the audit guide warning threshold; the second
  rejects the attempted debt declaration without a positive frozen baseline.
  Contain the small guide immediately by removing duplicated repair detail,
  keeping all substantive detail in this task and the complete captures. Both
  refusals and the original guide retain; no limit or allowance increases, no
  debt remains, and the unchanged doctrine gate reruns.

## Acceptance Checklist — .6.1.2.2.2

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'limit_examples' -1 -- perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm` identifies c0204a138's existing diagnostic sample behavior. Discovery omitted the argument from its closed schema; the new original API test fails and six real limit-bearing requests violate that schema. Controlled public calls also isolate the separately owned very-large-integer fallback in _bounded_limit's decimal-string predicate.
- [x] **ADDRESSED (verified)** — The integer argument is advertised and the golden fixture changes only its property name/type. The actual persistent query test passes. Full saved live/controlled comparisons preserve seven real queries and eight controlled requests, including order, complete fields, Boolean kinds, text/structured equality, defaults and caps. Five coherent missing-field/wrong-type/changed-live/changed-controlled/lost-wire controls reject at their intended checks. No runtime query code changes. POD/book disclose accurate sample limits and the pending large-integer defect rather than promising a uniform zero policy.
- [x] **NO REGRESSION** — All tests successful. Files=23, Tests=65 across the existing MCP protocol/schema/source-failure/UTF-8 cohort, now including independent controlled bounds and refusal assertions. The actual metadata test and saved reader pass; native POD/book/source/delivery and staged doctrines qualify. Syntax diagnostics:

  perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm syntax OK

### .6.1.2.2.2 evidence and continuity

- Re-derivation: original/repaired real persistent metadata calls and actual
  dispatcher calls with a clearly counterfactual larger catalog. Falsification:
  the saved reader joins raw frames, decoded objects, selected native/observer
  source hashes, exact discovery change, complete typed payloads and unchanged
  runtime; coherent adverse controls target five distinct checks. Durability:
  complete live and controlled captures, tracked producers/reader, comparison,
  original refusals and final logs under docs/audits/mcp-api-reference-20261023/.
  The real catalog cannot establish the cap alone; no hardware/source epoch,
  whole-feature/platform or latency claim follows from these metadata queries.
- The first saved-reader attempt requires a HEAD key absent from the Perl
  fixture packet. The corrected reader first joins the fixture adapter hash to
  its paired live capture, then uses that boundary only to locate exact source
  history. Original refusal retains; no product result is rewritten or dropped.
- Large JSON integer 1e30 selecting the default is confirmed through the public
  dispatcher and traced to exponent stringification failing a decimal regex.
  Own and schedule its fix under .6.1.2.2.4 before publication. The current POD,
  tool description and manual disclose it and give the usable 1-through-100
  range. This slice preserves zero/negative behavior, compact sample meaning,
  missing/unknown code refusals and the full underlying registry/catalog.
- Knowledge Map retains all questions/facts within a smaller byte footprint.
  The compressed reverify glob is checked to retain exactly its original five
  test paths; no sealed source epoch is rerun or allowance increased. The audit
  guide updates one status row without growth. Detailed records stay here.
- Complete normal commit gates, clear the message and verify a clean tree.
  Next is .6.1.2.2.3: admit every supported capability-section payload type
  without changing actual values. The overall exhaustive reference stays active.
- The first doctrine pass identifies the new API guide's numeric-limit prose
  as undisposed claims. Add its exact path as one required-complete POD-owned
  review group within the existing registry bound; register both candidates
  with distinct producer, adverse-oracle and durable-watcher legs. T1445 now
  checks every supported integer from 1 through 100; its fresh focused run
  passes alongside the unchanged broader cohort. The original gate refusal
  retains, and no registry capacity or document ceiling increases.

## Acceptance Checklist — .6.1.2.2.3

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'payload => _open_object_schema()' -1 -- perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm` identifies 837eb3c92's object-only envelope. Actual manifest_schema_version returns an integer; the original real-server regression fails that result and the equivalent numeric 1.0 control against the advertised schema. Other current wrapped public sections are objects.
- [x] **ADDRESSED (verified)** — The capability payload schema is the exact object/integer union; no result is reshaped. Both live metadata tests pass. The saved reader independently joins all 18 selectors to the 12-section public manifest plus named aliases, raw exchanges, complete typed values, exact descriptor change and 402 selected source identities. Five coherent omission/extra/Boolean/borrowed-value/missing-schema controls reject at their intended checks. Runtime outside the schema/POD is byte-identical. POD/book explain wrapped and direct-object variants without freezing private or deeper records.
- [x] **NO REGRESSION** — All tests successful. Files=24, Tests=71 across MCP protocol/schema/source failures/UTF-8 and independent VIAL capability parity. Both live metadata tests and the complete prior diagnostic reader/controls pass; the shared framing helper preserves that reader's behavior. Native POD/book/source/delivery and staged doctrines qualify. Syntax:

  perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm syntax OK

### .6.1.2.2.3 evidence and continuity

- Re-derivation is the persistent real server over every current public manifest
  section and documented alias. Falsification joins manifest/resource values,
  exact source/metadata membership, raw/decoded identity and full typed results;
  genuine missing/extra sections, Boolean substitution, an integer borrowed for
  an object section and a missing schema branch fail at distinct predicates.
  Durability is complete original/repaired captures, original failure fixture,
  selected source hashes, tracked collector/readers, comparison and full logs
  in docs/audits/mcp-api-reference-20261023/. The selected source footprint is
  explicit; no full toolchain/platform or feature/runtime claim is made.
- Object/integer typing describes current wrapped values. The direct all,
  contracts and examples results remain distinct object variants. Numeric 1.0
  is an integer for schema purposes; Boolean true remains a different kind.
  Full value joins detect a wrong integer in an object section even when the
  generic envelope schema would admit that kind. No interface version changes.
- The test collector and saved framing checks are shared with the diagnostic
  cohort; its historical packets and all five original adverse controls recheck
  green using their exact recorded source versions. The diagnostic packet's
  Git-only recovery also passed after its commit with current-source reads
  disabled. Older source/compiler epochs remain sealed and were not replayed.
- Knowledge Map preserves all facts/questions within the original byte budget.
  Its equivalent MCP test glob retains exact original path membership. Clarify
  the old ambiguous 'Resources are static' sentence as static/cursorless resource
  listings; source-bound reads remain dynamic queries. The audit-guide status
  row shrinks; detailed evidence remains in the task/captures, with no allowance
  or ceiling increase.
- Complete normal commit gates, clear the message and verify a clean tree.
  Next: refine and execute .6.1.2.2.4's metadata argument validation and owned
  numeric-limit repair in safe committed leaves before the remaining error and
  example-schema repairs. Complete operating-reference/model work stays active.

### .6.1.2.2.4.1 caller-kind finding

The actual API matrix also changes caller numeric source identities and metadata
filters into strings on a later Storable copy, even when ordinary serialization
can still look numeric. The observed examples are invalid string-field inputs;
no valid-input or global wire corruption claim is made. Direct `length` reads in
_source_query_payload and `lc` reads in metadata helpers touch caller scalars.
Decision 0114 and the public-copy-stability fact describe this mechanism; exact
operator/detached-copy controls qualify the cause before classification closes.
P2 fix ownership is immediate .4.2 for metadata and .4.4 for source selectors,
with fresh decoded input plus complete before/after and post-clone preservation
controls. The complete intermediate matrix/source capsules retain; final
observer qualification first corrects omitted/null labels and UTF-8 literals.

## Acceptance Checklist — .6.1.2.2.4.1

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S '$params->{arguments} || {}' -1 -- perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm` identifies 129cfae08's falsy normalization before tool admission. Actual API/pipe calls also show missing metadata field/type checks and VIAL numeric-string versions accepted against integer schemas. Direct length/lc reads of caller numeric string-field inputs reproduce later-copy kind changes; detached operator controls preserve them. The scoped canonical-JSON precedent is GHDLLifecycle's private integer validators; decision 0114 requires detachment before observation.
- [x] **ADDRESSED (verified)** — The audit independently joins the complete current tool/field case population, literal kinds, exact raw frames, source/observer identities, API/pipe results and fresh caller snapshots. Eight genuine missing/mislabeled/borrowed/lost/prechanged/Boolean controls reject at intended checks. Primitive and direct/detached controls isolate kind classification and caller-copy mechanisms. Corrected omitted/null and UTF-8 cases plus the original observer false-acceptance source retain; no observation is silently rewritten. .4.2-.4.4 own exact bounded fixes, and POD/book disclose the measured current limits.
- [x] **NO REGRESSION** — Production code before END remains byte-identical to d623c35dd, whose relevant MCP/VIAL cohort reports All tests successful Files=24, Tests=71. The actual matrix completes both routes with orderly EOF, no stderr, positive baseline queries and complete valid-result parity. The saved reader and eight controls pass; native POD/book/source/delivery and staged doctrines qualify this audit. New probe syntax:

  docs/audits/mcp-api-reference-20261023/probe_argument_api.pl syntax OK

### .6.1.2.2.4.1 qualification and next action

- Re-derivation: exact actual JSON-RPC API/stdio requests, full responses, raw
  UTF-8 frames, fresh before/after serialization and Storable-copy snapshots.
  Predicate units are labeled cases per entrypoint and named tool properties;
  categories overlap and are not counts of distinct defects. Falsification:
  independent schema/case/literal/source/wire joins, eight adverse interventions,
  numeric-versus-string/Boolean samples and direct-versus-detached operator
  controls. Durability: complete three capture/source capsules, original/final
  reader controls, producers/reader and full outputs in the dated audit directory.
- Scope: all current tool argument fields and tools/call params/name/object
  normalization. It is not a complete protocol-envelope, source-feature,
  filesystem-input, external-toolchain, performance or platform qualification.
  Native source files bind to the exact Git boundary; observer sources are
  retained verbatim with hashes. Historical source/compiler epochs are sealed;
  these are new bounded admission queries, not a replay of their qualification.
- Existing GHDL private canonical-JSON integer checks distinguish strings and
  Booleans but deliberately require bounded ordinary integer spellings. Reuse
  the canonical-kind technique locally without a backend dependency; MCP's
  integer semantics also admit integral exponent spellings. The finite prototype
  confirms detached scalar inspection across the selected primitive population;
  it is not a general JSON Schema validator or arbitrary-number-range claim.
- Original case-generator omissions mislabeled null as omitted and lacked the
  final case population; the next draft's hardcoded Unicode literal lacked its
  source UTF-8 declaration. Both full drafts retain and the independent reader
  rejects them. Corrected raw fixtures and explicit omitted/null/type joins pass.
- One original observer copy-control comparison used Python equality and really
  accepted false in place of numeric zero. Its full source, capture hash, exact
  mutation and original accepted result retain. Type-aware JSON equality now
  rejects it; actual native findings are unchanged. No product emitted that
  counterfeit control, and no false native-result or broad wire claim is made.
- The ordinary caller JSON remains equal in this matrix; the later-copy changes
  affect invalid numeric inputs to string fields. Fresh direct length/lc controls
  produce the same kind change; detached controls do not. .4.2 fixes metadata
  admission/caller preservation, .4.3 fixes numeric limits, and .4.4 fixes source
  kind admission/caller preservation while retaining textual URI decoding.
- Knowledge Map routes this audit without losing facts/questions or increasing
  its allowance. The shortened reverify glob has exact original path membership.
  No wider rationale or private-implementation API is introduced.
- After native/staged/normal commit gates, clear the message, verify clean state
  and activate .6.1.2.2.4.2. All required capture/reader jobs have been consumed.


## Acceptance Checklist — .6.1.2.2.4.2

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S '$params->{arguments} || {}' -1 -- perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm` identifies 129cfae08's falsy normalization. The committed .4.1 matrix proves missing metadata schema admission and direct lc caller-kind effects. Fresh T2102 runs on e01874c41 fail the wrong-kind/envelope/schema-drift subtests; its integral/default/alias subtest remains a positive control. Exact original output retains.
- [x] **ADDRESSED (verified)** — Public call_tool validation uses the actual metadata input descriptors and fails closed on unsupported schema vocabulary. The dispatcher separately distinguishes absent arguments from explicit null; detached primitive inspection distinguishes numeric/string/Boolean kinds without caller reads. Actual API/pipe comparison retains every request/result, validates all targeted refusals and full successful-result conservation, and preserves metadata caller copies. Four genuine restored-admission/changed-result/lost-copy/tampered-source controls reject, alongside all eight original reader controls on both captures. T2102 checks every reviewed metadata field, integral spellings, direct defaults, resource/capability aliases and five real schema-drift interventions; the persistent stdio test checks actual invalid calls and continued server health. POD/book document the exact changed boundary and remaining source/numeric limits.
- [x] **NO REGRESSION** — All tests successful. Files=25, Tests=75 across the existing MCP cohort plus T2102. All three live metadata tests pass, including complete current capability/diagnostic values. Captured runtime before END equals the final adapter despite later POD edits. Python readers parse as 3.9; native POD/book/source/delivery and staged doctrines qualify. No sealed source epoch, full toolchain/platform, latency or arbitrary-number-range claim follows.

### .6.1.2.2.4.2 evidence and continuity

- Re-derivation is the identical complete request population through the real
  initialized persistent server and decoded JSON-RPC API, with fresh before/
  after serialization and later Storable copies. Falsification uses independent
  schema/case/source/raw-frame joins, full original-success conservation,
  original and repair-specific adverse controls, plus T2102's literal-kind,
  default/alias and deliberately changed-descriptor controls. Durability is the
  complete original capture, repaired metadata-admission-after.json.gz, tracked
  producers/readers/tests and final comparison/logs in the dated audit directory.
- The repaired capture names e01874c41 as its base and retains the sole changed
  native adapter verbatim as a hashed overlay. It does not mislabel worktree
  bytes as that commit. Every other native module matches the original source
  population. Observer sources remain complete hashed capsules. Later POD-only
  edits retain separate final-source/runtime conservation evidence.
- The bounded local validator covers only the current metadata vocabulary and
  rejects unimplemented advertised constraints. It is not a general JSON Schema
  engine. Native integer classification uses the decoded finite numeric value;
  quoted numbers, Booleans and fractional values remain distinct. Integral
  decimal/exponent admission does not repair each tool's limit normalization.
- The prior T1445 missing-code expectation changes to invalid-params because
  code is a required field. Unknown string codes retain the semantic lookup
  refusal. Valid values/default policies, the unsupported string-tool lookup,
  capability/examples aliases and resource helper invocations conserve.
- The initial metadata reader run passes; its final readability change replaces
  an implicit list-length index with explicit enumeration and is reverified.
  No failed product observation is rewritten or dropped. Original .4.1 defects
  and observer mistakes retain their immutable evidence and scoped conclusions.
- Knowledge Map routes this repair without losing questions/facts or growing
  its authority. No new cross-cutting rationale or private supported API is
  introduced. Complete normal gates and commit before .4.3's numeric limits;
  .4.4 still owns source identities and VIAL version kinds/caller preservation.


## Acceptance Checklist — .6.1.2.2.4.3

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'return $default unless defined($value) && $value =~' -1 -- perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm` identifies c0204a138's decimal-spelling predicate in _bounded_limit. The committed public dispatcher witness selects 10 for 1e30 but 100 for 101. Fresh T2103 on b41de342d reproduces the large-number fallback in all four limit-bearing tools; the ordinary/default/zero/negative and complete API/newline controls remain green. The examples helper has the same decimal-only predicate and its separate positive-limit policy.
- [x] **ADDRESSED (verified)** — Replace only the two numeric-spelling tests with the already qualified detached JSON-integer predicate and each existing sign policy. The complete controlled reader verifies exact requests, source capsules, raw newline replies, every result field/order/kind and the eight specifically changed large-number cases. Six actual competing fallback/shared-cap/Boolean/order/wire/source interventions reject. Complete real-catalog projections and the controlled/live native boundary are independently joined; four additional real identity/Boolean/wire/borrowed-source controls reject. Descriptors and POD/book now state all four policies and remove the obsolete caveat. Claim records are updated to the repaired contract with current producer/oracle/watcher evidence.
- [x] **NO REGRESSION** — All tests successful. Files=26, Tests=80 across the existing MCP cohort plus argument and numeric-limit regressions. All four actual persistent metadata tests pass. Full controlled ordinary results and wrong-kind codes conserve; caller and manifest JSON/later-copy checks remain green. Native POD/book/source/delivery and staged doctrines qualify. Syntax and Python 3.9 parsing pass; the scope is these metadata limits, not hardware execution, performance, arbitrary precision or a platform matrix.

### .6.1.2.2.4.3 evidence and continuity

- Re-derivation is the explicit literal/policy table through actual public API
  and newline dispatch, plus real initialized persistent queries over the full
  current public manifest/catalog. Falsification uses an independently written
  complete projection reader, the genuine original RED/repaired GREEN, unique
  ordered fixture records with optional fields and Boolean kinds, six controlled
  and four live adverse interventions. Durability is tracked T2103, the shared
  metadata collector/CI tests, original and final full source/result capsules,
  complete stdout/raw exchanges, comparison and logs in the dated audit directory.
- The controlled population is deliberately invented and is never support
  evidence. It distinguishes bounds that the real per-diagnostic catalog cannot
  establish. Its complete input is retained, with three selected source capsules
  and runtime identities. The live capture fingerprints all tracked FSM modules
  plus its named launcher/framing/collector inputs; the same exact adapter hash
  joins both routes. The original controlled adapter matches b41de342d; repair
  bytes are retained explicitly rather than misattributed to that source commit.
- Omitted/zero/negative diagnostic limits select 10. Support defaults to 10 and
  discovery to 25; zero is empty and negative selects their respective defaults.
  Positive samples cap at 100. Examples default to 25 for omitted/zero/negative
  and keep uncapped positive limits, bounded only by matches. Integral decimal
  and exponent spellings are admitted; non-integer kinds remain invalid params.
  These observations cover the selected finite native values, not arbitrary-
  precision JSON arithmetic. Sampling never changes full catalog aggregates.
- The first repaired controlled packet predates descriptor/POD edits; it remains
  intact. A final packet repeats the full qualification against the published
  adapter. The final collector is shared with its CI test and requalified after
  that refactor. The saved reader additionally rejects a coherent borrowed old
  native boundary even when its fabricated current results look valid.
- Knowledge Map keeps every fact/question and its unchanged allowance. The
  first wording draft exceeds that allowance and is refused before writing;
  the final wording preserves the new exact meaning within the original bound.
  No rationale-ledger entry or supported private helper API is introduced.
- Complete normal gates and commit, then clear the message and verify clean
  state before .4.4's source identity/VIAL version admission and caller repair.
  Error locations, example result typing and full operating-model documentation
  retain their owned successors. Historical source epochs and publication gates
  remain sealed/open as recorded; no full CI/push signoff is inferred.

- During numeric claim publication, the line-only classifier is found to remove
  a continued paragraph's default 10. as though it were an ordered-list marker.
  Native prior book rendering and exact function execution isolate the mismatch;
  .6.6.1 owns the P2 correction before final signoff. Current policy rows have
  explicit evidence and the paragraph is rewritten unambiguously. The original
  stale-disposition refusal also retains: old caveat/claim IDs are retired into
  Git history and replaced by current policy dispositions, not left stale.

- The claim-inventory Knowledge Map card also records the precise paragraph
  ambiguity. Its existing scope/original-cohort/ownership/input/provenance facts
  and every question remain; redundant prose is compressed within its original
  byte footprint. The original paragraph HTML is retained and its exact native
  classifier/contrast replay is executable with verify_claim_context.py. No
  collection allowance or ceiling grows; the scanner's P2 fix remains pending.

- The first staged doctrine run rejects the newly split .6.6 container's pending
  status (including dependent containment/README checks). Correct it to active
  under the task-tree status contract; its pending leaves and selected .4.4
  frontier are unchanged. Retain the original refusal and rerun normal gates.


## Acceptance Checklist — .6.1.2.2.4.4

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S '!length($arguments->{$key})' -1 -- perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm` identifies 308677c9f's direct caller-scalar length guard. Fresh original requests reproduce the 6/6/12 version/error/copy observations. T2104 also demonstrates invalid numeric unused selectors reaching its injected runner, while its original URI/resource subtest stays positive. The shared _vial_language_version parser accepts textual URI versions and was also called directly on tool values, admitting quoted versions without a JSON-kind gate.
- [x] **ADDRESSED (verified)** — Source identity checks inspect a detached local value and require nonempty JSON string kind before length/resolution. A separate bound-argument version helper requires numeric integer kind before the existing enum parser; textual URI parsing stays intact. All repaired matrix findings clear, caller JSON and later copies preserve, all 75 schema-admitted results conserve, and complete before/after resource/tool values/raw bytes match. Five actual restored-version/restored-copy/borrowed-result/wrong-resource/borrowed-source controls reject, with the original eight controls on both matrices. T2104 covers direct and JSON-RPC callers, unused selectors, literal kinds, numeric spellings/defaults and resource parity; actual source tests enforce schema/refusal behavior over persistent stdio. POD/book remove resolved caveats and clarify URI kinds and static listings.
- [x] **NO REGRESSION** — All tests successful. Files=27, Tests=84 across the MCP cohort and all three new admission/limit regressions. All three actual persistent source tests pass. Source/path precedence, strict workspace/applicability rules and every captured resource/tool result preserve. Python 3.9 syntax, native POD/book/source/delivery and staged doctrines qualify. The selected argument/control population does not establish complete protocol, source-feature, filesystem-input, runtime, arbitrary-precision or platform coverage.

### .6.1.2.2.4.4 evidence and continuity

- Re-derivation: identical complete requests through the actual public decoded
  API and persistent UTF-8 pipe, with fresh caller serialization/later-copy
  snapshots. Separate initialized resource/tool captures cover both VIAL
  versions and unversioned defaults. Falsification: independent schema/case/
  source/raw-frame/full-result joins, original and repaired scalar controls,
  original T2104 RED/repaired GREEN and five coherent repair-specific adverse
  interventions. Durability: complete original/repaired matrices and resources,
  exact native/observer source capsules, tracked tests/readers, comparisons and
  original/final logs in the dated audit directory.
- The fresh baseline is 792f272a2. The repaired matrix retains its sole native
  adapter overlay explicitly. Resource captures fingerprint all tracked FSM
  modules and named launcher/framing/collector sources; the exact adapter hash
  joins each resource capture to its paired matrix. No repaired worktree bytes
  are mislabeled as predecessor bytes. Incoming numeric adapter/collector
  sources also recover exactly from Git with current-source reads disabled.
- The field matrix is not a combinatorial proof. Additional native-API tests
  exercise invalid numeric identities even when an alternate valid path wins;
  that original admission is observed with an explicitly injected hardware
  runner. Correctly quoted numeric-looking strings in an unused selector stay
  strings and preserve path precedence. No new hardware-feature or backend
  qualification follows from those admission controls.
- The version helper separates bound JSON data from URI text parsing. Numeric
  integral spellings retain enum selection; quoted versions are invalid params.
  Omitted versions, source style, normalized provenance/public reports, path
  authority and underlying public VIAL API behavior preserve. No private helper
  becomes a supported API and no transport/runtime feature is introduced.
- The Knowledge Map retains every original fact/question within its unchanged
  allowance. Equivalent compact globs preserve every original reverify path;
  the added T2102-T2104 paths are explicit, and no sealed source epoch is run.
  The book compatibility matrix now says static resource listings rather than
  ambiguously implying static source-bound payloads.
- The metadata capture helper accepts an explicit extra-source footprint for
  the source-resource collector; original default callers remain valid. Its
  actual captures retain all required producer identities. Historical captures
  stay byte-identical and exact source history remains the recovery authority.
- Complete normal gates/commit, clear the message and verify a clean tree.
  Next is .6.1.2.2.5's automatic Perl/input-record error-location repair, then
  example documentation typing and the full result-model/reference gap matrix.
  The P2 claim paragraph-context scanner repair remains scheduled at .6.6.1;
  publication, historical attribution and required feature frontiers retain.


## Acceptance Checklist — .6.1.2.2.5.1

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'sub _strip_perl_error_location' -1 -- perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm` identifies 651eebc3c's shape-only suffix regex. Actual native throw hooks show optional input-record line/chunk forms and spaces in loaded filenames. The handler's chomp depends on caller record separator and deletes the newline signal; the regex then also strips authored design.isf location text. Separate capitalized operator context is case-sensitive (2dc265476) and owned by immediate .5.3.
- [x] **ADDRESSED (verified)** — Audit only: original error packet and independent reader retain 120 complete responses from API/one-shot/persistent/custom-handle entrypoints at ordinary and spaced roots, all native exceptions and caller snapshots. All 434 selected source identities and 431 copied files join; six actual missing-case/native-origin/wire/caller/raw-data/source interventions reject. The reader reports 69 expected-message mismatches rather than calling them conformance. Production behavior is unchanged; .5.2 and .5.3 own fixes.
- [x] **NO REGRESSION** — knowledge-map: OK. Perl probe syntax is clean. Python 3.9 syntax and independent source/framing/native/caller/control checks pass. Native POD/book/source/delivery gates and staged doctrine workflow qualify the audit publication. No source-query compilation, simulation, sealed epoch, full CI or push is run by this audit.

### .6.1.2.2.5.1 selected contract and evidence

- Evidence lives in `docs/audits/mcp-api-reference-20261023/`: original
  `error-context-before.json.gz`, `verify_error_context.py`, its verification
  output, producer sources and original relocation refusals. Re-derivation is
  the actual adapter/launcher; falsification is the separate native-origin,
  literal-case, framing, caller-copy and source reader with coherent controls;
  durability is complete raw/native data, all observer sources, hashes and Git.
- Current host is Perl v5.34.1, JSON::PP 4.06 and Storable 3.23. Three native
  API input contexts have thirteen cases apiece at each root. Stock one-shot
  and persistent pipes use four refusal classes, with ping on the open pipe.
  Six callback custom-handle cases each retain an error and subsequent ping.
  Long ASCII and Unicode controls check the existing character cap, not bytes.
- Official [Perl die documentation](https://perldoc.perl.org/functions/die)
  explains final-newline suppression and optional input-record locations. The
  actual hook/origin observations establish the forms on this host; no Perl
  version/platform matrix or timing guarantee follows. Instrumented callback
  stderr is explicitly a probe channel; stock launcher stderr remains empty.
- .5.2 will recognize a final Perl-shaped suffix only for literal loaded-code
  filenames or the entry script, including spaced paths and line/chunk record
  annotations, and select its rightmost candidate. A single terminal LF will
  be normalized independently of caller record separator. Authored .isf/.fsm
  locations, fake record text and quoted operators must preserve.
- Unstructured exception strings cannot prove whether deliberately identical
  loaded-code location text was authored or appended. The selected contract
  recognizes that narrow syntax; it does not promise arbitrary-text provenance
  recovery, Perl #line remappings, every record separator/handle name or stack
  trace grammar. Structured source reports remain the accurate diagnostic API.
- The capitalized Operator slash is a separate P2 defect, immediately owned
  by .5.3. .5.2 must conserve that known redaction until its dedicated repair;
  ordinary filesystem-root redaction must remain intact throughout.
- Two relocated audit fixtures failed before adapter startup: first omitted
  top-level Perl dependencies, then required README/bin markers. Both exact
  producer/log/manifest/error records retain. The corrected same-volume fixture
  copies tracked Perl modules and required marker/launcher/source inputs and
  verifies every copied byte. These are observer repairs, not product defects.
- Complete normal commit workflow, clear the brief and verify clean state;
  continue .5.2, then .5.3, example typing and full reference gap completion.

- The first staged gate refused claim inventory drift after the final task-box
  text was staged later than the inventory refresh. The original refusal
  retains. Refresh only after all final source/docs/evidence staging, then
  stage the resulting inventory and rerun the normal gate. No checker bypass.


## Acceptance Checklist — .6.1.2.2.5.2

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'sub _strip_perl_error_location' -1 -- perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm` identifies 651eebc3c's shape-only regex. The committed native-hook audit and actual original extended T1461 expose both retained line/chunk/spaced-file locations and erased authored source suffixes. Handler chomp also depends on the embedding record separator. Original API and real stock/custom/moved-pipe RED output is retained, with exact test/adapter bytes.
- [x] **ADDRESSED (verified)** — The formatter normalizes one final LF itself, finds literal loaded-code/entry-script filenames and strips only the rightmost matching final bare/line/chunk suffix. The handler no longer chomps using caller record state. Authored source references, fake suffix fragments, operators, internal newlines, caller copies, error classes and code/message-only envelopes preserve in the qualified population. Independent complete original/final comparison reduces 69 expected-message mismatches to the eight deliberately retained capitalized-context cases. Each packet passes all six original reader controls; four restored-location/over-stripping/operator-loss/wrong-class controls reject. POD/book document the recognized grammar and its provenance limits.
- [x] **NO REGRESSION** — All tests successful. Files=28, Tests=91 for the established MCP cohort and native/API/newline quoted-division report parity. Both actual stock/custom/relocated pipe tests pass. Original focused T1461 RED fails three of four subtests, repaired GREEN passes all four. Python 3.9 syntax, adapter Perl syntax, Knowledge Map, native POD/book/source/index/copied-byte/link gates pass. No sealed source epoch, simulation, full CI or push is run; full publication and platform boundaries retain.

### .6.1.2.2.5.2 custody and remaining scope

- Re-derivation: actual decoded adapter calls and stock/custom launchers at
  original and same-volume spaced roots, with native throw hooks, complete
  wire frames and caller/later-copy snapshots. Falsification: independent
  complete population/source/origin/frame/envelope/message joins, genuine
  original regressions and coherent restored-defect controls. Durability:
  `error-location-*` captures, comparisons, original RED source capsule, logs,
  tests/readers and exact Git boundary in the dated MCP audit directory.
- The final packet binds the completed adapter/POD source; the earlier repaired
  packet retains its exact pre-final-POD producer rather than being overwritten.
  The comparator proves every selected unrelated native source unchanged and
  runtime bytes outside the helper/old handler chomp identical. The collector's
  sole observer refinement permits an explicit owning leaf in copied markers;
  its original default route and complete source capsules preserve.
- ASCII/Unicode controls preserve the character cap and full truncated values;
  ping and pre-existing bounded responses conserve. Native errors retain their
  public classes, and no raw error data or extra transport frame appears.
  This finite population does not establish arbitrary exception provenance,
  every Perl/platform/handle/record grammar or all source-feature behavior.
- .5.3 immediately owns capitalized operator-context redaction. Review also
  reproduces a nonempty zero-valued authored exception becoming the generic
  fallback; .5.4 immediately owns that P2 repair after .5.3. Its complete
  original response joins the exact early repaired adapter capsule, and
  git log -S '$error ||' locates c9fa73319's truthiness fallback. Neither issue
  is mislabeled as repaired here or as structured-report-wide corruption.
- Complete staged doctrines and normal commit hooks, empty the brief, verify
  clean state, then continue .5.3/.4 and example result typing. Historical
  attribution, full-CI/push gates and final whole-reference qualification retain.


## Acceptance Checklist — .6.1.2.2.5.3

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'my $operator_context' -1 -- perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm` identifies 2dc265476's case-sensitive prefix predicates. The committed .5.1/.5.2 native/public capture retains the capitalized Operator slash becoming an absolute-path redaction. A fresh real-pipe RED run on 031dbd425 fails exactly the two capitalized custom-handle subcases at ordinary/spaced roots, with other current controls positive. Exact original adapter/tests/log retain in error-operator-red.json.gz.
- [x] **ADDRESSED (verified)** — Only the singular/list context predicates gain case-insensitive matching. Ordinary roots and longer paths retain redaction. Complete original/repaired source/native/frame/caller/envelope/message joins repair all eight selected capitalized responses and conserve all 112 others. The independent comparator proves those two modifiers are the complete runtime diff. Both packets pass the six existing reader controls, and four restored-loss/unredacted-path/authored-location-loss/changed-ping controls reject. The actual pipe regression is GREEN at both roots. POD/book remove the resolved caveat and accurately describe the envelope fields and bounded context.
- [x] **NO REGRESSION** — All tests successful. Files=2, Tests=8 for focused error-data and full native/API/newline diagnostic/report parity, including successful division. Extended report and message controls cover title/upper/mixed context, singular/list phrases, contextual and ordinary roots, longer/quoted paths, URIs and relative text. Both actual pipe tests pass. Python 3.9 syntax, native POD/book/source/index/copied-byte/link and Knowledge Map gates qualify. The selected controls imply no full language, arbitrary-message provenance, platform or runtime qualification.

### .6.1.2.2.5.3 custody and continuity

- Re-derivation: actual public report/error and stock/custom UTF-8 transports,
  plus complete error contexts from original and spaced same-volume roots.
  Falsification: independent full-value/source/origin/framing joins, original
  actual RED/repaired GREEN and coherent restored-loss/path/source/ping controls.
  Durability: `error-operator-*` captures, comparisons, source capsule, logs,
  CI tests and tracked reader in the dated MCP audit directory.
- The incoming packet binds the exact 031dbd425 adapter via its earlier
  explicit source overlay; the new packet binds this repair at that HEAD.
  Every other selected source is byte-identical. The full source footprint is
  434 paths and the copied root has 431 verified files. No prior artifact is
  rewritten or relabeled. The original reader and location-only comparison
  still recheck their own historical packets with their own expected gaps.
- Case folding only changes recognition of operator diagnostic context. It
  does not exempt longer absolute paths or ordinary quoted filesystem roots.
  The remaining zero-reason fallback discrepancy stays visible in POD/book
  and owned by immediate .5.4. Reference-address/protocol/model coverage and
  final whole-reference signoff remain under the existing exhaustive frontier.
- Complete normal staged/commit gates, clear the brief and verify clean state,
  then continue .5.4 before example typing and the backing-model/reference gap
  graph. Historical source attribution, full CI/push and final visual gates retain.


## Acceptance Checklist — .6.1.2.2.5.4

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S '$error ||' -1 -- perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm` locates c9fa73319's truthiness fallback. Actual authored 0 plus LF becomes the nonempty false string after formatting, then selects the generic message. Fresh original T1461 on 488e59745 fails only that case in all three API record contexts; actual custom pipes fail its two ordinary/spaced-root subcases. Empty and filtered-empty controls stay positive. Exact original adapter/tests/logs and complete native/public contexts retain.
- [x] **ADDRESSED (verified)** — The handler chooses its generic fallback only when the formatted message is empty. Complete native/source/frame/value joins verify string 0 at both roots and preserve the empty/control-only fallback. Only those two responses change; all 130 others conserve. Both packets pass the six original reader interventions, and restored-loss/numeric-zero/overwritten-empty/borrowed-source controls reject. The comparator proves the fallback selection is the whole runtime diff; POD/book close the resolved caveat. Optional audit stdio-only controls preserve the historical API population and ordinary collector route.
- [x] **NO REGRESSION** — All tests successful. Files=3, Tests=9 for focused protocol, UTF-8 framing and error-data/message behavior, with original T1461 RED/repaired GREEN. Both actual stock/custom/ordinary/spaced-pipe tests pass. A separately run no-extra-cases capture preserves all 120 historical public responses and passes its six reader controls. Python 3.9 syntax, native POD/book/source/index/copied-byte/link and Knowledge Map checks pass. No arbitrary-message provenance, full feature/platform/runtime or publication qualification follows from these finite controls.

### .6.1.2.2.5.4 source custody and next frontier

- Re-derivation: real adapter API record contexts and stock/custom transports,
  including original/spaced roots and zero/empty/control-only authored throws.
  Falsification: independent complete source/native/frame/envelope/value joins,
  actual original RED/repaired GREEN and four coherent restored-defect controls.
  Durability: `error-zero-*` packets, original source capsule, comparisons,
  logs, CI tests and tracked reader under the dated MCP audit directory.
- Fresh before/after packets share exact source HEAD 488e59745. Only the
  adapter has a native after-overlay; all selected observer/other native source
  hashes match. The complete footprint is 434 selected inputs and 431 verified
  copied files. Original .5.2 zero discovery remains separately retrievable
  with its own earlier exact adapter; it is not relabeled as this baseline.
- New zero/empty controls are stdio-only audit fixtures and do not change the
  historical thirteen-case API population. Existing collector invocations
  still omit them; the explicit opt-in route has its own population checks.
  The compatibility capture binds the same final source hashes and complete
  public values, not merely a process exit or result count.
- Source reports and valid results retain their contracts; error envelopes
  remain code/message only. Nonempty zero is a string; truly empty messages
  keep the generic fallback after normalization and filtering. The bounded
  native-suffix/provenance limitations documented by .5.1/.5.2 still apply.
- .6.1.2.2.5 closes after normal gates/commit. The next leaf is .6.1.2.2.6's
  examples documentation object declaration, then the complete backing-model
  and operating-reference gap graph. P2 original reference-address findings
  are explicitly scheduled for current qualification/repair under .6.2.
  Historical attribution, full CI/push and final visual gates remain open.


## Acceptance Checklist — .6.1.2.2.6

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S "documentation => { type => 'array'" -1 -- perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm` identifies 837eb3c92's declaration. DocumentationSection/DocumentationContract and the actual manifest/resource/tool results publish an object. Fresh original real-server regression fails array versus object, and the independent reader retains that precise violation on all five valid example queries. Original malformed-input cases are not used as evidence for this result-kind defect.
- [x] **ADDRESSED (verified)** — The examples descriptor now declares the existing open documentation object. The comparator proves that single declaration is the complete runtime diff; all eleven non-tools/list exchanges and every other descriptor conserve exactly. Five complete example results join the full manifest documentation/catalog and independently projected support summary, including default/filtered/empty/large-limit cases; resource and capability aliases agree. Five coherent restored-array/changed-documentation/borrowed-catalog/text-mismatch/borrowed-source interventions reject. POD/book explain grouped path metadata, filter/limit scope and aliases without advertising document search or execution.
- [x] **NO REGRESSION** — All tests successful. Files=4, Tests=18 for support queries, complete schema snapshots, structured outputs and native documentation path existence. All five actual live metadata tests pass, including wrong documentation kinds and earlier capability/admission/limit controls. Python 3.9 syntax, native POD/book/source/index/copied-byte/link and Knowledge Map gates qualify. All original question routes survive with one new field lookup; two missing-route/wrong-destination controls reject. The selected cases do not establish complete nested model, protocol, platform or runtime coverage.

### .6.1.2.2.6 evidence, containment and next scope

- Re-derivation: initialized actual stdio queries for discovery, full manifest,
  examples resource, examples/documentation capability selectors, support
  summary and five default/filtered/empty/large-limit example queries.
  Falsification: independent schema/full-value/catalog/support/alias/text/source
  joins, genuine original RED/repaired GREEN and coherent adverse controls.
  Durability: `examples-type-*` complete packets, sources, comparisons, logs,
  regression and tracked reader under the dated MCP audit directory.
- Both captures share exact HEAD 1bf8c9a2e and all 431 selected inputs: every
  tracked Perl module plus named launcher/bootstrap/framing/collector sources.
  The after adapter is an explicit native overlay; observer source text and
  hashes preserve the exact uncommitted collector. Generic capture adds source
  custody without changing existing default requests. Current/historical input
  recovery never pretends predecessor bytes are the repaired producer.
- The first new reader refused its own dot-form error-path assumption. The
  existing schema evaluator reports slash-form paths. Exact reader source,
  observed errors and original refusal retain; the corrected reader qualifies
  both actual payloads and the intended original schema violation. No product
  failure is inferred from that observer correction.
- The new examples documentation lookup is in the existing canonical MCP card.
  One explicit task-file/prefix scopes the same dated selector/limit/capability/
  copy/error facts. Original metadata/questions and all bytes outside that
  rephrased block preserve; each old unit identity reconstructs from the named
  prefix. Retained old/new prose, exact source hashes and complete before/after
  question rows support review. The card shrinks overall; no allowance or
  ceiling changes. Every original route survives and the new route resolves.
- The documentation object preserves human_contract/downstream_alignment path
  arrays and its section contract, independently of catalog filtering. Exact
  paths remain deliberately widenable. Full nested field interpretation stays
  in .6.1.2.3/.6.4's explicit gap graph; this repair does not declare it complete.
- Complete normal staged/commit gates, empty the brief and verify clean state.
  The selected interface-discrepancy container closes; next is .6.1.2.3's full
  backing-model/documentation census, followed by bounded operating-reference
  cohorts. P2 original reference-address/protocol findings stay with .6.2;
  claim paragraph-context repair stays .6.6.1 before final signoff. Historical
  attribution, full CI/push and whole-reference visual gates retain.


## Acceptance Checklist — .6.1.2.3.1

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'contract_surface_map' -1 -- perl/FSM/Support/SemanticIntrospectionContract.pm` identifies 93e0c2840's VIAL inspection/discovery extension to the public ownership graph. Current native/MCP metadata spans manifest, versioned tooling, inspection, multiple tool domains and separate APIs; the initial descriptor/property census cannot establish full model semantics. Actual tool declarations identify query families/domains rather than sharing resource declaration fields. Complete native/wire records establish the topology before field interpretation.
- [x] **ADDRESSED (verified)** — Source/runtime-bound metadata-only MCP capture and independent public in-process manifest/VIAL/inspection/source-kind bindings agree. The separate reader verifies every root, declared tool/template, owner/source reference, schema slot and namespace occurrence by exact location/value, with full wire/raw/native/source custody. It qualifies 45 observed roots and 22 declared result roots across 30 exchanges and 433 inputs, with no unresolved declared owner. Nine meaningful missing/extra/borrowed/wrong-owner/type/availability/completion controls reject. POD/book describe ownership joins and envelope/API boundaries. No root name/schema slot is counted as completed semantic documentation.
- [x] **NO REGRESSION** — knowledge-map: OK. Native POD/book/source/index/copied-byte/link validation and Python 3.9 syntax pass. Current adapter runtime bytes are identical to 684ca68bb; only its POD changes. The final qualified capture binds that exact POD source and native producer inputs. All actual metadata queries complete with orderly EOF, native success and empty stderr. No source-bound query, planning, simulation, backend execution, sealed source epoch, full CI or push is performed by the audit.

### .6.1.2.3.1 scope, custody and successor ownership

- Re-derivation: actual initialized MCP discovery, every static resource,
  versioned VIAL capability resources and every manifest/alias selector.
  Falsification: separate public in-process metadata bindings, independent
  per-root/per-pointer/type/source joins and nine coherent adverse controls.
  Durability: `model-roots-qualified*`, `model-root-graph-qualified.json.gz`,
  exact raw/native bytes, complete observer/native source custody, projector
  sources, reader and logs in the dated MCP audit directory.
- The graph has 1175 owner/producer/namespace reference occurrences, 296 schema
  namespace occurrences and 525 schema-labelled slots. These are occurrences
  across repeated roots, not counts of distinct public APIs, schemas or field
  meanings. Every declared owner resolves in the selected source set; a bare
  namespace reference is not promoted to a callable API. Values equal in this
  capture are recorded separately from semantic alias/stability promises.
- MCP tool declarations join through query_family -> query_families domains
  -> query_domains contract surfaces -> contract_surface_map. Shared check
  and semantic tools span hardware and VIAL domains. Resource declarations
  separately advertise output owners; neither form replaces the dedicated
  nested contracts or source-kind/version applicability. Bounded presence-key
  families do not automatically close all objects or freeze deeper payloads.
- An initial new projector assumed resource owner/source-bound fields also
  existed on tool declarations. Its exact source/failure and actual published
  tool shape retain; the corrected graph derives those fields through the
  real family/domain relation. The earlier successful projector source also
  retains when locality/source-custody handling is strengthened. Initial
  metadata-only and later native/final-POD observations keep their own source
  epochs and are not relabeled as the final qualification.
- A deliberate Boolean-to-zero initialization counterfeit was rejected by
  the original raw-capture join. The attempted counterexample and exact
  original reader source retain; it was never emitted by FSMGen and is not
  classified as a product defect. The final reader makes typed comparison
  explicit and retains that control alongside omission, wrong-owner, schema,
  borrowed-value and false completion/execution interventions.
- Public metadata can name runtime, planning, HDL-generation and raw/private
  interface contracts without exposing such operations through MCP. The
  audit's actual operations remain metadata-only. Source/check/semantic/
  schedule/inspection payload fields and temporal meaning remain .3.3/.3.4;
  metadata fields and nested contracts are .3.2; the complete doc-gap join is
  .3.5 before .6.1.2.4 selects exact operating-reference cohorts.
- Main-book VIAL tool/template excerpt omissions and the missing -32602 in its
  protocol-code paragraph remain P2-owned in .3.5 -> .6.2/.6.3. Original
  reference-address findings stay .6.2; the claim paragraph-context scanner
  stays .6.6.1 before final signoff. Historical source/CI/push gates retain.
- Complete normal staged/commit gates, clear the brief and verify clean state;
  then refine .6.1.2.3.2 from the qualified graph before its first implementation.


### .6.1.2.3.2.6 selection checkpoint

- The root graph's complete actual metadata is the census input; root names,
  owner links, schema labels and existing test-status prose do not by
  themselves document field semantics. The five child cohorts retain dynamic
  map/list members, version/order/requiredness/extension meaning and exact
  prose gaps, including explicit delegation of specialized VIAL metadata.
- Common-shell preparation read the complete CapabilityManifestContract,
  ProducerContract, ProducerSection and capability facade, the qualified
  manifest/producer values, and relevant current book/POD. Producer version
  is tool/build metadata; git_commit is a best-effort short hash or unknown,
  and the producer contract explicitly disclaims release-management meaning.
  These existing contract facts remain inputs to .3.2.1, not a new field audit.
- No code or runtime source changes. Book guidance now distinguishes the
  identity/version layers while full model interpretation remains pending.
  Complete normal doctrine/commit workflow and resume .3.2.1 from the committed
  selection alone; no process or uncommitted implementation is required.


## Acceptance Checklist — .6.1.2.3.2.6

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'PERL-POD-API-REFERENCE.6.1.2.3.2' -1 -- docs/tasks/PERL-POD-API-REFERENCE.md` identifies 1757aa395's qualified topology and still-unsplit metadata census. Its roots span common identity, discovery/catalog/diagnostic, embedding/export and language/backend/verification contracts; one undivided field inventory would not be a bounded signoff slice. The reviewed producer/manifest contracts explicitly separate build provenance from schema authority and release-management promises.
- [x] **ADDRESSED (verified)** — Five exact child cohorts now own every metadata category and final closure, with specialized VIAL delegation explicit and .3.2.1 selected first. The bounded Memory/task index name that exact first action. Book guidance distinguishes schema/language/protocol/build identities; no runtime code or field-completion status changes. The initial staged refusal is retained: book authority metadata is an implementation-classified path and therefore requires these fresh acceptance boxes even for this planning activity.
- [x] **NO REGRESSION** — knowledge-map: OK. The staged task-tree integrity check passes for the new topology; native mdBook/source/copied-byte/link checks pass. This is selection and documentation only, with all runtime source unchanged. No source query, backend, simulation, full CI or push is introduced. The next field census is unstarted and can resume from committed records alone.

- Session health: the director's section 11 applies after this long run; focus
  is slipping. Finish and commit this checkpoint before requesting fresh context
  for the unstarted field census. No implementation or process must depend on
  conversation-only state. The first acceptance refusal preserves separately;
  complete final staging/inventory refresh and rerun all normal gates.

- The initial checkpoint ID used a zero component, which the task-tree grammar
  rejects. Both original gate refusals retain. Rename that planning checkpoint
  to the valid unused positive child .3.2.6, preserve the five census cohorts
  and .3.2.1 resume target, and run focused integrity before the full final
  gate. No field census or runtime work has begun.


## Acceptance Checklist — .7.1

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'Latest artifact cleanup' -- docs/ARTIFACT_CLEANUP.md` locates the canonical date record. The collector compares actual UTC to complete native prior bytes and admits only after the elapsed-time prerequisite. Published collector functions remain byte-exact; Git bytes are comparison data only.
- [x] **ADDRESSED (verified)** — Actual supervised census and saved replay pass, including independent whole-member rg equality and all published missing-member/path/type/removal controls. No candidate has exact disposal authority, so all retain. Latest-only date and book saved-reader route now reference the new dated observation; original RAM-guard sandbox refusal retains.
- [x] **NO REGRESSION** — knowledge-map: OK. Saved collector controls pass without repeating collection or deletion. Focused task integrity and book/source/index checks plus staged doctrine/normal hooks gate this maintenance-only slice. No runtime source, compiler epoch, API, backend execution or publication changes.

Re-derivation: actual dated collector bound to native HEAD/prior record and installed source. Falsification: separate rg membership plus coherent saved-record refusals. Durability: tracked dated wrapper/census/refusal, unchanged published collector, latest-only record, task/book/Git. Lstat fields are dated metadata, not content identity or future absence. Resume .7.2 policy-source review, then the unchanged .6.1.2.3.2.1 common-field census.

The first staged gate correctly refused an unnecessary maintained-reference authority change: the dated route replacement changes neither aggregate bytes nor lines. Complete refusal retains in the dated census directory; restore the unchanged prior aggregate authority, regenerate the affected inventory and rerun staged/normal gates. No content, ceiling or disposal scope changes.

The next complete gate also identifies task_evidence total line/byte transition allowance exhaustion. Following the root containment procedure, declare actual plus that surface's own ratchet step for only these dimensions, keep the baseline/ceilings/targets/owner unchanged, and retain the full refusal. This is an ordinary warning-debt allowance declaration, not rollover-debt growth or a ceiling increase.


## Acceptance Checklist — .7.2

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'Reviewed update' -- CLAIM_VERIFICATION.md` and decision0104 identify the retained local adoption. The actual director-selected read-only sibling bytes equal the separately retained reviewed template; re-importing it would undo deliberate reviewed adaptations. The selected README source and containment bridge are already canonical repository-owned policies/routes.
- [x] **ADDRESSED (verified)** — Complete policy-source review and exact source hashes/dispositions retain in docs/audits/startup-policy-review-20261024.json. No new normative difference requires adoption; no external writes or executions occur. Startup maintenance closes and the exact saved metadata census resumes. No user-visible behavior changes, so the existing mdBook policy guidance needs no ceremonial edit.
- [x] **NO REGRESSION** — Focused task integrity and exact source identity/equality checks pass; knowledge-map: OK is enforced by final staged/normal doctrine gates. Only current task-evidence line/byte warning-debt allowances are measured per the documented actual-plus-own-step procedure; baseline, target, ceilings, ownership and every retained fact remain unchanged. No original source epoch, compiler, simulation or publication gate repeats.

Re-derivation, falsification and durability are named in the dated record. Template identity is a dated observation, not a current-state shadow; later source changes require another explicit review. The next executable work is the unchanged .6.1.2.3.2.1 manifest/producer/common-shell field census.


## Acceptance Checklist — .6.1.2.3.2.1.4

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'build_producer_contract' -- perl/FSM/Support/ProducerContract.pm` locates the dedicated producer boundary. Qualified native contract records expose differing status and entrypoint shapes, including absent entrypoints; interpreting every common field as one universal closed record would conflate distinct owners. Root manifest and producer source/POD/book were reviewed before selecting exact cohorts.
- [x] **ADDRESSED (verified)** — Source-hashed common-shell-selection.json retains each explicit contract-record candidate and all three exact successor scopes. Root/producer .1 starts first; shared record .2 and complete join .3 preserve every parent obligation. The actual semantic_introspection entry omitted from the book's top-level owner list is reproduced and owned by immediate .1, with no schema-only completeness claim or new execution.
- [x] **NO REGRESSION** — Task integrity and claim-inventory/disposition checks pass; knowledge-map: OK remains part of final staged/normal doctrine gates. Selection changes task/evidence/resume state only; current manual and runtime behavior remain unchanged. Existing qualified captures are read as evidence, never rerun, and all publication/history/HIAL limits retain.

The selection packet names re-derivation, falsification and durability, and states its structural predicate and exclusions. Full field meaning, actual adverse controls and semantic documentation signoff are expressly successors, not properties inferred from this planning census.


## Acceptance Checklist — .6.1.2.3.2.1.1

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'top_level_contract_source_map' -- perl/FSM/Support/CapabilityManifestContract.pm` identifies the grouped shell authority. The actual original book list omits semantic_introspection; manifest-owner-list-red.json retains exact native expected/list/revision and reader refusal. Canonical ProducerContract/ProducerSection define build provenance and typed families, but no stronger contract_authority meaning. Existing headings and round-trip status prose did not supply a complete field guide.
- [x] **ADDRESSED (verified)** — Qualified census independently joins all 51 selected fields and 49 nested containers to complete source-bound native values, exact owners/presence families, types, element domains and dedicated book/POD interpretation. Actual owner-list RED becomes GREEN. Thirteen coherent omission/extra/borrowed-value/kind/meaning/numeric-Boolean/gap/map/source/document/freshness/instrument controls reject. The stronger Boolean-marker definition stays explicit, P2-owned under .6.4. Runtime lexical source conserves exactly, and Knowledge Map adds the canonical lookup without losing an old fact/question or growing any allowance.
- [x] **NO REGRESSION** — All tests successful. Files=6, Tests=18 for manifest/producer contracts, exact native/CLI/alias builders and producer round-trip/copy boundaries. Native POD/book build, copied-source/index and Python 3.9 syntax checks pass; knowledge-map: OK and all prior metadata/questions preserve with one new lookup. Final updated native book/source checks and staged/normal doctrine hooks gate commit. No source query, simulation, backend, sealed epoch, full CI or publication qualification follows.

### .6.1.2.3.2.1.1 evidence and continuation

- Re-derivation: build_manifest_fields.py enumerates complete selected actual root, manifest_contract, producer and ProducerContract objects from the already qualified metadata capture; dedicated sources and current guide/POD snapshots bind the interpretation. Counts name fields and nested containers in those selected contexts, not distinct APIs or all metadata.
- Falsification: verify_manifest_fields.py independently reconstructs object membership, owner/presence-family relations, exact complete values and nested types, authenticates original native/wire/source capture, and rejects the named coherent interventions. The actual pre-edit owner-list failure retains. Meaning facets and explicitly reviewed phrases expose specific competing claims; general natural-language correctness still requires review.
- Durability: manifest-fields-qualified.json.gz retains exact source/document/producing-instrument text and hashes plus Python identity; current mode refuses stale docs/instrument, while saved mode authenticates the dated boundary without rerunning producers. The earlier packet and exact initial builder/reader/pass retain separately before custody/freshness strengthening; no predecessor evidence is relabeled as final. Focused/native logs and final reader output are retained in the same dated audit.
- Capture epoch is 684ca68bb25bde673f6570065b3e5ab52e9e2edb, inherited from .3.1's qualified complete observation. Current contract/producer sources are exact; CapabilityManifest differs only in POD. Its captured Git hint is historical provenance, never a claimed current HEAD. No original source/native compiler epoch repeats.
- Knowledge Map retains before/after complete card bytes and an exact reverse-edit join. Only listed redundant wording changes; all original questions, metadata, dated observations, test/source identities and limits preserve. New question routes to the book guide. Two proposed byte-growing edits refused before writing; final card shrinks without allowance/ceiling growth.
- The census deliberately leaves deeper section and heterogeneous common-record meanings for .1.2 and the existing metadata/report/VIAL cohorts. Undefined marker semantics are a documented limitation with an exact .6.4 repair owner, not an invented guarantee. Complete MCP operational coverage, legacy reference/protocol gaps, historical source causality, full CI/push and whole-reference visual QA remain open.
- Session health: decision0116 authorizes an engineer-selected clean context refresh. The next cohort spans differing owners/status/entrypoint shapes and needs fresh focused review; finish this verified slice, consume all jobs, clear the brief and stop only after the clean commit. Resume .6.1.2.3.2.1.2 by refining shared-record cohorts from the retained selection, not by restarting old captures.


## Acceptance Checklist — .6.1.2.3.2.1.2.1

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'entrypoints' -1 -- perl/FSM/Support/EmbeddingContract.pm` identifies 51be98306's bounded embedding owner. The complete retained native records include differing statuses, singular entrypoint and implementation_entrypoints forms, label-specific strings/arrays and absent fields. The incoming shared-record leaf spans separate contract families and requires exact cohorts before a safe semantic signoff.
- [x] **ADDRESSED (verified)** — `select_common_records.py --check` independently expands native candidate membership and joins every original path/owner/status/entrypoint label to one cohort or the prior root/producer census. The retained JSON preserves actual field names and entrypoint values/absence. Exact live children now own section shells, enriched query/report records, embedding variants, specialized VIAL and joined closure; no candidate is silently flattened or dropped. Policy sources still match today's retained complete review.
- [x] **NO REGRESSION** — Focused task integrity and deterministic selector replay pass; knowledge-map: OK and staged/normal doctrine hooks gate the checkpoint. Runtime code, source epochs, manual behavior and existing publication/HIAL gates remain unchanged. No user-facing behavior changes require a ceremonial mdBook edit.

Re-derivation, independent native per-path falsification and tracked durability are named in common-record-cohorts.json. This is an exact structural selection with semantic work expressly pending. The selector reads the saved capture only. Startup recovered a clean Git tree, active R13 documentation ownership, relevant public contracts/tests/book and unchanged adopted policy sources; no unresolved task-selection decision is required. Resume the selected section-shell census after committing this checkpoint.

The first staged checkpoint gate rejects task_evidence total-line/byte allowance exhaustion. Exact relevant native diagnostic excerpts retain in common-record-selection-refusal.json (not a claimed complete stream). Apply the canonical warning-debt actual-plus-own-ratchet-step procedure to those totals only; preserve baseline, targets, ceilings, owner and all recorded evidence.


## Acceptance Checklist — .6.1.2.3.2.1.2.2

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'entrypoints' -1 -- perl/FSM/Support/EmbeddingContract.pm` identifies 51be98306's section contract. The independent dedicated-contract join rejects the actual draft's embedding subject: HDLGeneratorResultContract::hdl_generator_result_known_top_level_keys is the sorted union of common/direct/composition families, while SerializableGenerationResultSnapshot publishes output keys. A universal child-contract or all-required interpretation is wrong. Exact draft sources/values and first reader failure retain.
- [x] **ADDRESSED (verified)** — Complete selected shell census joins 87 fields, 95 containers and 19 semantic source snapshots to exact native values, dedicated owners, owner-specific subjects and book/POD interpretation. The corrected actual draft passes; all 14 omission/extra/owner/type/subject/delegation/map/Boolean/execution/source/document/instrument controls reject. Book guidance distinguishes success-result fields, registry siblings, normalized envelopes, generator known-key unions, snapshot outputs and contract records, with path/language families and deeper owners explicit.
- [x] **NO REGRESSION** — All tests successful. Files=20, Tests=32 in the existing section contract/round-trip/copy cohort, including the expanded shell glob. Python 3.9 AST syntax and Perl syntax pass. Native mdBook/POD, exact rendered guide tables/content, current source/index/copied-byte checks pass. knowledge-map: OK is required by final staged/normal doctrine hooks; the new question resolves and exact reverse edits recover the prior card without card byte/line growth. Runtime lexical bytes and dedicated sources conserve exactly. No original source epoch, simulation, backend, full CI or publication gate repeats.

### .6.1.2.3.2.1.2.2 evidence and limits

- Re-derivation: build_section_shell_fields.py enumerates the selected complete native shell records from the already qualified metadata observation. Counts describe fields/containers in those contexts, not distinct public APIs, all metadata, or completed MCP documentation.
- Falsification: verify_section_shell_fields.py independently reconstructs membership/types and follows each dedicated contract relationship, including an independently reconstructed sorted known-key union. Saved native/wire/source custody is authenticated without starting producers. Actual first draft fails on the embedding subject; the later case-sensitive phrase check also rejects capitalized Registry wording and is corrected without weakening typed joins. Both originals and their source identities retain. The final reader records every coherent control's exact rejection locus. General natural-language correctness remains review, not a claim proved by keyword checks.
- Durability: final compressed census retains full builder/runtime/source/document snapshots. Saved mode authenticates its dated boundary; --current rejects changed sources, docs or builder. The final reader output retains its complete source text/hash. Original/intermediate packets, sandbox RAM-guard refusal, approved supervised outcomes, native regression/build logs, rendered HTML text/table identity and exact fact-route reverse edits retain in the dated audit directory. Nothing depends solely on ignored scratch output.
- Parent-field required presence is separate from a nested map's subject. In particular, generator known-key union membership does not require every union member on every result, and a snapshot output is distinct from the contract advertising it. These are dedicated public contract facts, not new execution capabilities or submodule-derived assumptions. Remaining enriched/embedding/VIAL common records and deeper metadata/report meanings stay with their named successors.
- Native HTML checks cover the updated guide, not browser or whole-manual visual qualification. Full MCP reference closure, the existing undefined producer marker, protocol/reference gaps and historical source/HIAL/CI/publication gates remain open. Resume .6.1.2.3.2.1.2.3 from the retained exact cohort selection after the clean commit.

Session health: this source-heavy review has accumulated substantial context, including corrected draft/instrument assumptions. Decision0116 authorizes a clean refresh to protect signoff quality before the enriched-record cohort. Finish this verified slice, consume every job, clear the brief and verify clean Git; the next .6.1.2.3.2.1.2.3 action is fully recoverable from committed cohorts and the bounded pointer.

The first section-shell staged doctrine gate refuses a verbose audit-front-door addition at rollover pressure. Its complete stream retains in section-shell-doctrines-first-refusal.log.gz. Keep the original audit facts/commands and a compact shell-reader route at that bounded landing; the full new interpretation remains in the canonical book and exact census packet. The guide returns to normal pressure without changing its allowance or ceiling.


## Acceptance Checklist — .6.1.2.3.2.1.2.7

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'pending section-shell qualification' -1 -- docs/tasks/PERL-POD-API-REFERENCE.md` identifies a5b9d2153's precursor descriptions. The completed .2.2 child and Memory/index advanced at 3c4f11367, while two inherited descriptions retained their earlier prerequisite wording. This could confuse a fresh reader despite correct authoritative statuses and next-action pointer.
- [x] **ADDRESSED (verified)** — Parent verification explicitly names the qualified shell census and selects enriched .2.3; the unstarted successor names the committed prerequisite. Exact targeted checks reject the former descriptions and agree with the done child and unchanged Memory/index. This small owned handoff repair changes no implementation or manual behavior and requires no ceremonial book edit.
- [x] **NO REGRESSION** — Focused task integrity passes; knowledge-map: OK and complete staged/normal doctrine gates remain required before the clean commit. Prior native field controls, source conservation, contract tests and book/POD qualification are unchanged. No producer, source epoch, backend, full CI or publication repeats.


## Acceptance Checklist — .6.1.2.3.2.1.2.3.5

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'mcp_adapter_entrypoints' -1 -- perl/FSM/Support/SemanticIntrospectionContract.pm` locates 129cfae08's adapter discovery boundary. Dedicated source review and the retained common-record-cohorts.json expose different report/manifest routes and heterogeneous family subjects; the incoming leaf combines identity with substantially deeper check/normalized/query/catalog/artifact schemas. No universal record interpretation is valid.
- [x] **ADDRESSED (verified)** — The parent now has explicit identity/routes, report/registry families, query/support/verification families and joined closure leaves. The existing ten selected paths and every original acceptance obligation remain owned. Identity .3.1 starts first; no implementation or user-visible manual behavior changes.
- [x] **NO REGRESSION** — knowledge-map: OK in the first complete staged gate; task integrity passes, and staged/normal doctrine gates must qualify this planning change; prior source/native evidence remains sealed. Startup policy inputs and selected read-only external template are byte-identical to the retained review; no adoption change or cleanup is due. No source epoch, backend, full CI or publication is run.

The split's first complete staged gate refused task_evidence total-line/byte transition allowance exhaustion. Full output retains in docs/audits/mcp-api-reference-20261023/enriched-split-doctrines-first-refusal.log.gz. Apply only the documented warning-debt actual-plus-own-step declaration for those totals after recording this evidence; preserve baseline, ceilings, targets and owner. The required implementation acceptance now covers that declaration; the initial gate already reports knowledge-map: OK, and all final gates must be rerun.


## Acceptance Checklist — .6.1.2.3.2.1.2.3.1

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'source_query_kinds' -1 -- perl/FSM/Support/SemanticIntrospectionContract.pm perl/FSM/Support/SemanticIntrospectionSection.pm` locates 39e774943's published applicability addition. The independent existing T370 first fails at line 54: the section has source_query_kinds while CapabilityManifestContract's separately maintained list omits it. Original owners/test equal HEAD before repair, and CapabilityManifest runtime code is unchanged by the POD edit. The original saved native metadata independently carries the same omission. The first identity reader also demonstrates the actual missing operational guide. Both originals retain, with no source-epoch replay.
- [x] **ADDRESSED (verified)** — The final identity packet/reader preserves every selected owner, schema/status, complete string/list value, repeated projection and absent field. Book/POD explain report/data authorities, optional-tool availability, manifest/report/adapter routes and deliberate widening. Every other field has an exact successor. CapabilityManifestContract now derives the semantic-introspection family from its already-public dedicated owner, following the existing verification-output pattern. Actual T370 RED becomes GREEN; independent saved comparison proves only three presence-family arrays gain source_query_kinds. No DSL, source-query, backend or execution capability is added.
- [x] **NO REGRESSION** — All tests successful. Files=17, Tests=30 for independent full-section discovery and adjacent root/owner round-trip/copy contracts. Native mdBook/POD build, current POD assets, complete source/index/copied-byte checks, selected rendered HTML table/POD interpretation, Python 3.9 syntax, sixteen identity and four repair controls pass. Knowledge lookup preserves all original questions/facts with an exact reverse-edit join and no card line/byte growth. Final staged/normal scripts/check_doctrines.sh and hooks are required before commit; full CI/push and whole-manual visual qualification remain separately gated.

### .6.1.2.3.2.1.2.3.1 evidence and continuation

- Re-derivation: build_enriched_identity.py reads the qualified native metadata capture and the exact selected cohort. Its quantities count field slots at selected record occurrences, including repeated section projections; they are not distinct APIs or complete MCP documentation. Seven nominated identity/route/guidance fields are examined per record, with explicit absence. The discovery-repair constructor is a bounded metadata observation, not a source-bound query or an original source/compiler epoch.
- Falsification: verify_enriched_identity.py independently declares path/owner/route-role subjects, joins exact native values/types/presence/source/projection/delegation and current guide/POD bytes, and rejects omission, extra records, wrong owner/role/status/source/type, invented null/alias, ordering, lost delegation, execution and freshness changes. The original pre-guide reader fails. verify_enriched_discovery.py compares the actual repaired constructor to the retained original full contract plus exactly the missing applicability member in its three projections, joins actual section membership, proves exact source repair and unchanged oracle, and rejects omitted members, unrelated metadata changes, changed test source and Boolean status. Actual T370 before/after uses the same existing test; the original fourteen-file cohort fails only that test, and the repaired cohort adds three adjacent root tests and passes all seventeen. General natural-language truth remains a source/document review obligation.
- Durability: docs/audits/mcp-api-reference-20261023/enriched-identity-final.json.gz binds complete sources, documents, builder and Python identity. The dated pre-guide and intermediate qualified packets are retained separately. enriched-identity-discovery-before.json.gz and enriched-identity-discovery-after.json.gz retain complete old/new owners/test/constructor data. enriched-identity-checks.json.gz retains complete original and final streams with consumed execution-handle statuses; sandbox process-inspection refusal is not confused with an admitted run. The unchanged RAM guard supervises admitted reads/tests/builds. No original metadata collector or source/backend/simulation capture is restarted.
- Read identity evidence with `scripts/run_with_ram_guard.sh -- python3 -B docs/audits/mcp-api-reference-20261023/verify_enriched_identity.py docs/audits/mcp-api-reference-20261023/enriched-identity-final.json.gz`; append --current only to assert current source/doc/instrument identity. The repair reader is `scripts/run_with_ram_guard.sh -- python3 -B docs/audits/mcp-api-reference-20261023/verify_enriched_discovery.py`, with the same freshness option. Saved mode starts no producer. Final joins must consume the explicit root-projection delta; predecessor censuses remain dated rather than silently relabeled current.
- verify_enriched_rendered.py reads the actual native built guide and generated POD. It joins each displayed owner/report-source cell to the saved native identity and checks the important absence/route distinctions. This is scoped rendered-content evidence, not browser or whole-manual visual qualification. Current build output remains regenerable under .artifacts; exact reader/source/result retains in the checks packet.
- enriched-identity-knowledge.json.gz retains complete card before/after bytes and an exact reverse transformation. Every prior question, metadata value and distinct navigation/owner/semantic-API fact survives. The new enriched-entrypoint question resolves to the canonical guide without collection allowance/ceiling growth. Earlier byte-growing draft proposals were refused before writes.
- The newly encountered P2 root-discovery omission is owned and fixed in this leaf because it blocked its independent regression gate. Source applicability and catalog outcomes remain unchanged. Family subjects/registry values, query policies, catalog/artifact contents, embedding/VIAL and complete operating-reference closure remain with their named successors. Resume .3.2 after this slice's clean commit; historical HIAL/source causality, whole-reference visual review and qualified full-CI/publication remain open.

## Acceptance Checklist — .6.1.2.3.2.1.2.3.2.5 (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — The first scripts/check_doctrines.sh stream rejects task_evidence aggregate lines and bytes at the prior declared allowance. git log -S '2570253' -- doctrine/live_document_size/surfaces.jsonl locates that byte allowance at c751598dd. This is warning-debt declaration pressure, below unchanged enforcement ceilings; LIVE_DOCUMENT_SIZE_CONTAINMENT.md explicitly authorizes measured actual plus the surface's own ratchet step. The complete terminal-failure stream retains as family-selection-first-refusal.log.gz; its original execution handle was omitted by the caller, so no consumed exit status is claimed.
- [x] **ADDRESSED (verified)** — The exact child graph preserves all four native paths and prior deeper obligations. Recompute task_evidence aggregates after this checklist and declare actual plus its existing ratchet step. Do not change baseline, ceiling, milestones, owner, retention or Knowledge Map allowance. No source/runtime epoch or manual behavior change.
- [x] **NO REGRESSION** — scripts/check_task_tree_integrity.pl passed; knowledge-map: OK in the first complete stream. Final staged scripts/check_doctrines.sh and normal commit hooks must qualify the declaration and selection before commit. The sibling claim template matches the retained reviewed SHA-256; local README and containment policy sources are already the adopted authority.

## Acceptance Checklist — .6.1.2.3.2.1.2.3.2.1 (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — Saved qualified native metadata and CheckDiagnosticsContract/DiagnosticCodeRegistryContract distinguish report subjects, registry siblings/entries, allowed values and the object-valued source_optional_fields. The genuine pre-guide reader fails on absent semantic guidance. The actual broader gate fails at t/383-contract-family-map-integrity-audit.t line 92 because its generic audit assumes every family is an array. git log -S 'source_optional_fields => report_source_optional_fields()' locates d5c1806c2; the original array audit dates to e8ff1dc4c. Complete original source/failure/first-invalid-filename and incomplete control-attempt evidence retain. P2 ownership in this leaf includes the matching inherited array-only book prose; no public metadata corruption is inferred.
- [x] **ADDRESSED (verified)** — The guide/POD bind every selected family to its subject and condition, preserve key/value and absent/null/optional/extension distinctions, and exactly delegate every remaining field. The independent source/native/document reader and meaningful adverse controls qualify the saved census. T383 now checks the optional object against its dedicated owner and sibling only at the two published owners/map/field; the original array checks remain byte-identical. Actual original/repaired metadata fixtures prove both valid-object rejection and invalid-array admission reverse; wrong owner/map/family/content/sibling and malformed ordinary arrays reject. Book's older universal-array claims are repaired in the same source-bound packet. Runtime sources before __END__ conserve.
- [x] **NO REGRESSION** — All tests successful. Files=10, Tests=1155 in the named registry/discovery/grouped-map/round-trip/copy cohort. Native mdBook/POD, actual selected HTML table/POD content, current POD/source/index/copied-byte checks, Python 3.9 syntax and knowledge-map: OK qualify this scope. Final staged scripts/check_doctrines.sh and normal hooks remain required. No original metadata collector, source/compiler/backend epoch, full CI, publication or whole-manual browser qualification is claimed.

### Diagnostic-family evidence and continuation

- Re-derivation: build_diagnostic_families.py projects complete original native values for selected family/owner fields at the two diagnostics paths. The identity predecessor joins every prior delegated field to qualified common meaning or exact .3.2.2/.3.3/.6.4 owners. Field-slot quantities count metadata fields at those records, not APIs, features or complete diagnostic payload semantics. The optional-declaration object retains its deeper models.
- Falsification: verify_diagnostic_families.py independently enumerates subjects/conditions and joins native values/types/order, owner domains, sibling/entry/value distinctions, grouped mirrors, complete source/doc snapshots and deeper ownership. It rejects omissions, duplicates, wrong subjects/conditions/values/types/owners, lost delegation and staleness. The genuine pre-guide packet is RED. General natural-language truth remains a source/document review obligation, not a phrase-search proof.
- Durability: diagnostic-families-qualified.json.gz binds the exact original capture and identity packet, complete semantic source/doc/builder bytes and Python identity. Pre-guide and intermediate packets remain dated; only the qualified packet asserts the final guide. The saved/current reader never invokes the collector. Read with scripts/run_with_ram_guard.sh -- python3 -B docs/audits/mcp-api-reference-20261023/verify_diagnostic_families.py docs/audits/mcp-api-reference-20261023/diagnostic-families-qualified.json.gz; --current additionally asserts current source/doc/instrument identity.
- P2 audit repair: diagnostic-map-repair-before.json.gz retains original T383 and contract bytes plus the complete genuine failing cohort. qualify_diagnostic_map_repair.py runs the unchanged actual old/new helpers against retained local metadata fixtures. The saved-reader verify_diagnostic_map_repair.py --current proves complete case/input/probe/status/TAP/source joins and exact test reversal outside the narrow object branch. Labeled fixtures include overlapping generic-object/wrong-family observations; they are not distinct bugs. The first control runner had wrongly expected the original invalid array to fail; its incomplete attempt/source/output retain rather than being relabeled success. No source/compiler epoch is involved.
- diagnostic-family-checks.json.gz retains complete command streams, consumed execution statuses, independent readers and selected rendered HTML tables. Native rendering is scoped content evidence; whole-manual browser review remains pending. The Knowledge Map update preserves every original question/metadata and distinct fact, with complete before/after bytes, exact reversal and no card line/byte growth. Task collection declarations use existing actual-plus-ratchet rules; no baseline, ceiling or Knowledge Map allowance grows.
- The check/registry leaf closes the encountered audit/prose blocker. Resume normalized .3.2.2 after this clean commit, refining bounded subjects before implementation where needed; optional validation .3.2.3 and the joined family closure .3.2.4 remain open. Historical HIAL/source causality, required delivery and qualified full-CI/publication obligations retain.

## Acceptance Checklist — .6.1.2.3.2.1.2.3.2.2.9 (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — The saved normalized record's nested subjects and canonical NormalizedSemanticReportContract distinguish shared envelope, optional payload and heterogeneous IR entry families. git log -S 'source_optional_fields => report_source_optional_fields()' identifies the shared-object promotion at d5c1806c2; 55361cfa9 qualifies its exact audit handling. This child selection preserves that known contract instead of restarting a source epoch or treating every family as a uniform list.
- [x] **ADDRESSED (verified)** — Exact children now own envelope, baseline/tier, symbol, composition, shared-datapath, lowered-control, structural-entry and grouped closure obligations. The original field list remains preserved in the qualified identity packet; final join must allocate every field or retain an exact deeper owner. The current next action is .1. Existing warning-debt declarations are recomputed as actual plus their own ratchet without baseline/ceiling or Knowledge Map growth.
- [x] **NO REGRESSION** — The previous committed slice passed All tests successful Files=10, Tests=1155 and all normal hooks. This selection changes task continuity/declarations only: current task-tree integrity and full staged/normal scripts/check_doctrines.sh qualify the new graph. The book and runtime remain unchanged; no new feature, field meaning or execution claim is made.

## Acceptance Checklist — .6.1.2.3.2.1.2.3.2.2.1 (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — The exact saved native metadata and NormalizedSemanticReportContract separate the common envelope from nested payloads. Review of public NormalizedSemanticReport factories confirms both outcomes carry top-level support_accounting, while semantic/generation_result_snapshot are success-only. The pre-guide reader genuinely fails for absent explanation. git log -S 'source_optional_fields => report_source_optional_fields()' identifies the shared optional-source contract at d5c1806c2; existing .3.2.1 already qualifies its object-map handling. A later prose-only observer refusal came from case-sensitive success-only matching against Success-only, not a wrong public result; original observer source/packet and selected error retain.
- [x] **ADDRESSED (verified)** — The book/POD guide binds every selected field to its subject, outcome/matched condition and dedicated owner. Independent saved-native/type/order/owner and literal factory-root joins distinguish report-level versus diagnostic support, producer-advertised layers versus available semantics, shared optional source maps and success-only snapshot/payload presence. Exact remaining-field delegation preserves all payload/IR/grouped-map/deeper owners. Twelve coherent adverse controls reject; the prose matcher is case-insensitive while metadata/source matches stay exact. Runtime source bytes conserve before __END__; no source-query or backend epoch runs.
- [x] **NO REGRESSION** — All tests successful. Files=10, Tests=18 in the focused normalized-report/producer/command/generated-output round-trip/copy and discovery/grouped-map cohort. Native mdBook/POD, exact selected HTML tables, current POD/native copied-source/index checks and Python 3.9 grammar pass. Existing Knowledge Map routes remain valid and unchanged; the complete staged/normal scripts/check_doctrines.sh path remains required. Whole-manual browser review, original source/backend epochs, full CI and publication are not claimed.

### Normalized-envelope evidence and continuation

- Re-derivation: build_normalized_envelope.py reads the original qualified native manifest and final enriched identity delegation. The selected quantity counts metadata fields at one contract record, not APIs, complete source reports or supported features. Complete shared sources, current book/POD, builder, imported producer helper and Python identity are retained in normalized-envelope-qualified.json.gz. The helper joins its prior qualified source snapshot rather than being an untracked producer input.
- Falsification: verify_normalized_envelope.py independently enumerates exact subjects/conditions/owners and checks all selected values/types/order against the original native capture. A separate bounded extractor reads literal top-level public factory return hashes and joins success/failure roots, producer, command, base source and the failure support bridge. It is scoped to reviewed static factory syntax, not a general Perl parser or executed source-report oracle. Source identities fail on drift. Omission, wrong subject/outcome/match/owner, borrowed check-result keys, object-to-array coercion, lost delegation, source/helper mutation and missing/stale documents all reject. Natural-language truth remains a source/document review obligation.
- Durability: normalized-envelope-before-guide.json.gz preserves genuine missing-guide RED. normalized-envelope-case-refusal.json.gz retains the original observer, exact input and selected terminal error; full initial stderr was returned by the execution tool, so no retained complete stream is claimed. The subsequent corrected source/reader output and native regression/build/rendering streams retain in normalized-envelope-checks.json.gz with consumed execution statuses. No original collector or source/compiler/backend epoch is restarted.
- Replay from committed data: scripts/run_with_ram_guard.sh -- python3 -B docs/audits/mcp-api-reference-20261023/verify_normalized_envelope.py docs/audits/mcp-api-reference-20261023/normalized-envelope-qualified.json.gz. Add --current only to assert current source/doc/producer identity. verify_normalized_envelope_rendered.py reads actual native guide/POD tables and joins every field/owner row; this is selected rendered-content evidence, not browser or whole-manual visual signoff.
- The existing semantic-introspection fact card points to this same canonical guide, and normalized optional-child/public-source-identity cards preserve deeper routes. No Knowledge Map fact/question/allowance changes are needed. The report-envelope slice closes no payload/IR field meanings: resume .3.2.2.2, then the exact selected symbol/composition/shared-datapath/lowered/structural/grouped successors. Historical source/HIAL causality and qualified publication obligations remain open.

## Acceptance Checklist — .6.1.2.3.2.1.2.3.2.2.2.1 (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — The saved native metadata and dedicated contract-source functions distinguish baseline keys, optional children, bucket entries, IR tiers and owner labels. The genuine pre-guide reader fails on missing explanation; the first producer's invented explicit_system_contract_contract_source is retained and corrected to emitted labels. git log -S 'protocol_intent_bundle' locates the existing optional-bundle promotion at 9abfc939f. The later bounded public builder probe preserves its JSON Boolean inputs but removes three named system/signal properties; NormalizedSemanticReport::_json_ready_value lacks the explicit JSON::PP::is_bool branch already present in CompositionReportContract (cdfef64e6). This is a scoped direct-helper defect, not a measured native source failure.
- [x] **ADDRESSED (verified)** — The baseline census independently joins all 27 selected field/owner slots and 123 remaining delegations to native values and dedicated literal source lists. Fourteen omission/subject/tier/optionality/owner/source/helper/doc controls reject, including the original invented owner-field shape. The book/POD explain required-versus-null and optional-child states, exact owner labels and deeper model boundaries; they disclose the confirmed direct-helper Boolean limitation honestly. This census does not repair that runtime defect: immediate child .2 owns genuine RED/GREEN and the Boolean-only correction; .3 owns the final current-source baseline join. Original probe/program/input/output/source and producer refusal retain.
- [x] **NO REGRESSION** — All tests successful. Files=22, Tests=30 in dedicated payload/module/system/signal/symbol/IR metadata round-trip/copy and shared discovery/map audits. Native book/POD and exact rendered field/owner tables, current POD/source/index/copied bytes, Python 3.9 and knowledge-map: OK qualify the census; final staged/normal scripts/check_doctrines.sh gate its commit. The new nullable-key question routes to the canonical card; every original question/evidence/fact retains with an exact reverse edit and no card line/byte growth. Native source epochs, Boolean fix/source reachability, full CI/publication and whole-manual browser QA are not claimed.

### Baseline census, confirmed blocker and continuation

- Re-derivation: build_normalized_baseline.py projects selected baseline/owner slots from the original native observation and normalized-envelope predecessor. Slots count metadata fields at one record, not distinct APIs or complete model meanings. Every remaining predecessor field keeps the selected grouped closure plus exact deeper .3.2.3/.3.3/.6.4 owners. The exact source/doc/producer/helper/runtime snapshots bind the dated census; no original collector or compiler/source/backend epoch restarts.
- Falsification: verify_normalized_baseline.py has an independent subject/rule and public owner/function oracle, parses only reviewed literal qw-list contract syntax, and compares exact per-family values with native metadata. It separately joins the source factory's required/optional child allocation and nullable explicit-system propagation. It rejects omitted/invented fields, swapped tiers/buckets, wrong key/value/optional/non-null/owner interpretations, lost delegation, source/helper changes and missing/stale guide bytes. This is not a general Perl parser or whole-report/source-variant oracle; deeper actual data and availability stay owned. Natural-language truth remains source/document review.
- Durability: normalized-baseline-before-guide.json.gz retains the genuine absent-guide input and normalized-baseline-owner-refusal.json.gz retains the earlier incomplete producer/observer code and selected terminal error. The current-document census is normalized-baseline-census-qualified.json.gz; normalized-baseline-qualified.json.gz remains an earlier dated guide snapshot. Checks retain complete successful reader/test/build/rendering streams and consumed statuses. Saved mode verifies retained data; --current additionally asserts current source/doc/producer identity, so .3 must refresh after the Boolean repair rather than relabeling old bytes current.
- New P2 blocker: normalized-boolean-first-probe.json.gz retains the complete admitted synthetic public builder program, JSON input/output, guard stream and exact NormalizedSemanticReport/CompositionReportContract sources. JSON false declare_ports, true implicit and false signed disappear. JSON::PP::Boolean is a reference kind; the normalized helper accepts only plain scalars/HASH/ARRAY while the established composition helper explicitly accepts JSON booleans. The initial minimal probe did not emit runtime versions; the controlled repair cohort owns that fingerprint. No native DSL/CLI/MCP reachability or affected-source census is inferred; existing .3.3 owns source qualification.
- Read the current-document census with scripts/run_with_ram_guard.sh -- python3 -B docs/audits/mcp-api-reference-20261023/verify_normalized_baseline.py docs/audits/mcp-api-reference-20261023/normalized-baseline-census-qualified.json.gz. The optional-child card adds the nullable explicit-system question, preserves all original questions/evidence and direct/symbol-poor applicability facts, and deliberately updates its review date/reverify/owner evidence. Complete before/after bytes and invertible edits retain; no Knowledge Map allowance or ceiling grows.
- Commit .1's completed census before .2's direct-helper Boolean repair. After its focused native regression and complete controls, .3 must join the exact source delta and refreshed current docs/packet before the parent closes and symbols .3 resume. Existing historical source/HIAL causality, full-CI/publication and whole-manual browser obligations stay open.

## Acceptance Checklist — .6.1.2.3.2.1.2.3.2.2.2.2 (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — The retained public build_normalized_semantic_success_report probe loses JSON Boolean system/signal fields and array entries. T2105 genuinely fails all three original subtests at t/2105-normalized-semantic-json-booleans.t line 49 and neighboring assertions. NormalizedSemanticReport::_json_ready_value rejects reference kinds except HASH/ARRAY; JSON::PP::Boolean therefore falls through as unsupported. CompositionReportContract already uses JSON::PP::is_bool for the same public JSON-value boundary. The JSON-safe primitive distinction is independent of private AST objects; no native DSL/CLI/MCP source impact is inferred.
- [x] **ADDRESSED (verified)** — Add exactly the established one-line Boolean-recognition branch before generic reference filtering. Actual same-input/source/runtime captures now preserve false/true values, nested hashes, ordered arrays and caller data; unchanged plain-value reports and complete non-semantic report fields conserve. Private objects and scalar references remain filtered. verify_normalized_booleans.py proves full raw/decoded/source/probe/test joins, the exact one-line delta, controlled runtime and six known-bad kind/position/report/case/caller/source rejections. The old source-bound baseline census remains dated; .3 owns its refreshed current-source join rather than silently relabeling old bytes.
- [x] **NO REGRESSION** — All tests successful. Files=7, Tests=12 for new public-helper Boolean/nullable/optional/copy/filter controls plus current payload/report/composition contract and defensive-copy checks. Current metadata and in-process helper behavior qualify; no public source-language feature, corpus classification, capability/schema revision or source epoch is added. Book/POD remove the now-repaired limitation; the fact card's current reverify command is exactly this passed contract/helper subset. Final native book/POD/copied-source/index checks, Knowledge Map and staged/normal scripts/check_doctrines.sh are required before commit. Full CI/publication, broader browser review and native source reachability remain owned.

### Boolean preservation evidence and continuation

- Re-derivation: probe_normalized_booleans.pl invokes only the advertised public report builder with synthetic metadata. Before/after captures retain complete inputs, caller snapshots, output reports, private-reference recipes, canonical Perl/JSON runtime versions and identical probe/test/composition source bytes. These are controlled direct-helper cases, not compiled DSL examples, source-feature support or performance measurements. Initial and final genuine RED streams retain; no original source/compiler/backend epoch runs.
- Falsification: verify_normalized_booleans.py joins complete raw/decoded values and exact source delta, compares repaired semantic data against independent JSON inputs, conserves complete unaffected reports and every non-semantic report field, and checks caller/private-reference preservation. Coherent numeric-false, lost-array-position, unrelated-report, missing-case, caller-mutation and extra-source interventions all reject. False/true JSON kinds remain distinct from numeric zero/one and string values.
- Durability: normalized-boolean-repair-before.json.gz and normalized-boolean-repair-after.json.gz retain full sources, test/probe, actual output/guard streams, runtime and consumed execution statuses; normalized-boolean-initial-red.json.gz preserves the first test version/failure. The new CI regression is t/2105-normalized-semantic-json-booleans.t. Replay retained data with scripts/run_with_ram_guard.sh -- python3 -B docs/audits/mcp-api-reference-20261023/verify_normalized_booleans.py; --current asserts repaired sources/test/probe identity. The final checks packet binds the reader and native documentation evidence.
- Public sync/applicability: this fixes a confirmed in-process JSON primitive-preservation defect, with no new DSL/corpus/CLI/MCP selector or metadata key. Native DSL/CLI/MCP reachability was not established by the synthetic probe and remains explicitly under .6.1.2.3.3. Current field-family contracts remain unchanged. Book/POD describe preserved Boolean values and continued private-reference filtering, while the Knowledge Map keeps every fact/question/evidence and uses current contract/helper tests for reverify; its exact reverse update and lower card bytes retain.
- Resume .3 to join the old baseline census with the exact qualified Boolean source delta and refresh its dated source/doc packet before closing the parent and resuming symbols. Native source/HIAL causality, full-CI/publication and whole-manual browser obligations stay open. Final native source-copy checks follow all MEMORY.md/docs/TASK_TREE.md updates because both are selected book-source assets.


## Acceptance Checklist — .6.1.2.3.2.1.2.3.2.2.2.3 (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — The original baseline reader correctly returns ValueError: current source stale after the qualified Boolean repair; git log -S 'JSON::PP::is_bool' locates the exact runtime change at bd995774f. Its original-runtime conservation rule must remain intact. The closure authenticates the native-to-before and baseline-to-before source joins, verifies the retained full controlled repair and admits exactly its repaired report source before using the unchanged literal-family oracle on a separate original-source comparison view.
- [x] **ADDRESSED (verified)** — Refreshed baseline packet joins all 27 selected metadata fields, 123 remaining field/deeper delegations, unchanged dedicated-family sources and current source/docs/producer/runtime. Ten coherent field/delegation/family/report/old-source/input/instrument/guide/staleness controls reject. Book/POD clarify preserved value kinds without changing advertised families. The Knowledge Map replay command changes with exact reversal and every original metadata/question/evidence/body byte retained; no card or allowance grows. Original census, probe, producer and repair failures remain untouched; new reader-ID and nonexistent-test launcher refusals retain with their precise corrections.
- [x] **NO REGRESSION** — All tests successful. Files=7, Tests=26 in public-helper primitive/nullable/copy/filter and report/payload/composition contracts. Saved original baseline and qualified Boolean repair readers pass. Native book/POD rendering, complete current source/index/copied-byte checks, Python 3.9 grammar, knowledge-map: OK and staged/normal scripts/check_doctrines.sh qualify commit. No original source/compiler/backend epoch, full CI/publication or whole-manual browser signoff is claimed.

### Current baseline closure evidence and continuation

- Re-derivation: build_normalized_baseline_closure.py refreshes the existing baseline producer from retained native metadata and current source/document bytes. normalized-baseline-current-qualified.json.gz binds the original census and complete pre/post repair inputs by exact digest, current baseline snapshots, producer/reader/helper sources and runtime. Metadata-field counts concern selected slots at this contract only; remaining field delegation is a separate complete set, not nested-model completion.
- Falsification: verify_normalized_baseline_closure.py authenticates the original census with its unchanged reader and the complete repair with its independent reader. Exact native/original/baseline/repaired joins admit only the one Boolean-recognition line. Dedicated families remain byte-identical; the original literal-family, required/optional/nullable and owner oracle still runs. Coherent controls reject changed fields/delegations, unrelated family/report edits, old report substitution, wrong input identity, missing/changed instruments and missing/stale guide bytes. Natural-language accuracy remains reviewed source/document interpretation; native source reachability remains under .3.3.
- Durability: normalized-baseline-closure-checks.json.gz retains complete commands, stdout/stderr and consumed exit codes, including the sandbox guard refusal, old-current refusal, reader-ID typo and focused-launch filename error. normalized-baseline-closure-first-draft.json.gz and normalized-baseline-closure-explicit-path.json.gz preserve those exact instrument/source boundaries; neither is relabeled current. The final default-reader command is scripts/run_with_ram_guard.sh -- python3 -B docs/audits/mcp-api-reference-20261023/verify_normalized_baseline_closure.py; add --current to assert present source/docs/producer/runtime identity.
- The native selected table/POD reader still compares every baseline/owner row to the conserved original census. No whole-manual browser review follows from that content join. normalized-baseline-closure-card.json.gz proves a single invertible reverify edit, preserving all fact/question/evidence text without Knowledge Map growth. Current task-evidence warning-debt totals use actual plus their own ratchet only; targets, baseline, ceilings and owners remain unchanged.
- Close baseline parent .2 and resume symbol family .3 after this commit. All deeper nested/source, historical HIAL causality, full-CI/publication and broader browser obligations remain open. No new engineering decision requires a DEVELOPMENT_NOTES entry. Cleanup remains within the recorded daily interval; selected policy sources exactly match the already committed startup review.
