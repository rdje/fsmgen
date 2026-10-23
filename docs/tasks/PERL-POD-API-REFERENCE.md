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
  Status: `active`
  Children: `PERL-POD-API-REFERENCE.6.1.2.2.1, PERL-POD-API-REFERENCE.6.1.2.2.2, PERL-POD-API-REFERENCE.6.1.2.2.3, PERL-POD-API-REFERENCE.6.1.2.2.4, PERL-POD-API-REFERENCE.6.1.2.2.5, PERL-POD-API-REFERENCE.6.1.2.2.6`
  Goal: `Repair only confirmed advertised-schema/runtime contract discrepancies.`
  Acceptance: `Refine one exact child leaf per independent .6.1.2.1 discrepancy before implementation. Preserve existing valid behavior and published compatibility while making discovery accurately describe accepted requests/results. Prove real before/after requests and metadata, valid/refused cases and full typed outputs with adverse controls. Synchronize precise POD/manual guidance and relevant schema snapshots; commit each repair before its successor.`
  Verification: `pending actual conformance evidence and exact repair children`
  Commit: `pending`

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
  Status: `pending`
  Goal: `Enforce advertised metadata-tool argument types and closed fields consistently.`
  Acceptance: `Five metadata tools accept an unpublished argument despite closed schemas; discovery/examples/support also accept wrong array-typed fields, while capability/diagnostic wrong types expose ARRAY reference addresses in errors. Reuse established project JSON-kind/argument facilities where suitable, or select a bounded validator for exactly the published schema vocabulary without introducing an unrelated evaluator/dependency. Preserve all valid supported values, JSON scalar kinds and intended per-tool limits; reject invalid types/fields cleanly with actual API/newline controls. Split validation cohorts if needed, document and commit.`
  Verification: `Actual extra-argument calls succeed on capability, discovery, examples, diagnostic and support tools. Wrong-array query/limit calls succeed on discovery/examples/support; wrong-array section/code errors contain ARRAY(0x...) strings. Exact wire captures retained; implementation/qualification pending. P2 numeric-limit defect is also owned here before complete reference/publication: JSON integer 1e30 reaches _bounded_limit as a Perl exponent string and falls back to 10, whereas 101 caps at 100. Reproduce through actual public calls with a controlled catalog large enough to distinguish the results, then normalize valid JSON integer limits consistently without conflating Boolean/string kinds or silently changing zero/default policies. The public dispatcher confirms 101 => 100 samples but 1e30 => 10 with a controlled 121-entry catalog; real per-code populations are too small to distinguish those limits. Reproduce with perl -Iperl docs/audits/mcp-api-reference-20261023/probe_diagnostic_limits.pl. Complete typed public results and source hashes retain in diagnostic-controlled-before/after.json.gz; the exact decimal-regex root cause is confirmed. Fix at this leaf before reference completion/publication, splitting bounded validation/numeric leaves first if needed.`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.2.5`
  Status: `pending`
  Goal: `Remove automatic Perl/input-record locations from public persistent-server errors.`
  Acceptance: `Real invalid-parameter errors include the adapter .pm line and STDIN record suffix. Trace _strip_perl_error_location's missing input-record case; preserve the meaningful public reason, authored source diagnostics and path-sanitization behavior while removing private automatic locations. Qualify persistent/default/custom handles and moved roots with spaces, exact original messages, safe hostile suffix/quote/operator controls and public code/message-only envelopes; commit a scoped fix.`
  Verification: `The live pipe returns messages such as Invalid params: source_path or source_id is required at perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm line 457, <STDIN> line 32. The current strip regex only recognizes a bare final line number. Full original error messages are captured; no fix or broad cleanup claim yet.`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.2.6`
  Status: `pending`
  Goal: `Correct the example tool's documentation result type without altering returned metadata.`
  Acceptance: `The actual examples result carries the public documentation section object, but outputSchema declares an array. Correct the declaration to its authoritative current contract; never reshape correct public values to satisfy a wrong schema. Compare complete actual documentation/catalog records with the capability manifest, text/structured results and schema metadata, include wrong-type controls, synchronize precise guidance and commit.`
  Verification: `Saved-reader inspection finds documentation object against array schema on ordinary valid find_examples calls, independently of malformed-argument cases. Full original records and raw wire frames are retained in the live census.`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.6.1.2.3`
  Status: `pending`
  Goal: `Join every public result contract and documentation obligation into a complete gap matrix.`
  Acceptance: `Follow the manifest's full contract-surface graph, current report/schema producers, typed VIAL inspection contract and relevant book/POD. Inventory every public field family, nested record, meaning/unit/order/optionality/version/identity/failure boundary and its canonical documentation, stability and representative evidence. Names or object schemas alone do not count as semantic explanation. Separate compact/full variants and source temporal/schedule/runtime availability; retain explicit omissions and exact owners. No private compiler implementation is promoted to public API.`
  Verification: `Pending result-model/documentation census after interface repairs. Reproduced documentation debt: the book semantic_introspection JSON excerpt omits the currently shipped VIAL inspection tool/template, while live discovery and the following VIAL section include them. The gap matrix must own its refresh or explicitly partial presentation before reference completion; existing discovery remains authoritative.`
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
