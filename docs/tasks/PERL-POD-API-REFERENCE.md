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
This explicit 2026-10-23 priority exception does not waive existing publication,
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
- Commit each slice before its successor. Hosted publication retains the
  standing full-CI and exact-SHA requirements.

## Task Tree

- ID: `PERL-POD-API-REFERENCE`
  Status: `active`
  Goal: `Deliver a reproducible POD API reference through the native mdBook workflow.`
  Children: `PERL-POD-API-REFERENCE.1, PERL-POD-API-REFERENCE.2, PERL-POD-API-REFERENCE.3, PERL-POD-API-REFERENCE.4, PERL-POD-API-REFERENCE.5`

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
  Status: `pending`
  Goal: `Integrate reference generation, styling and navigation into normal mdBook build/serve.`
  Acceptance: `Add the native build integration and a book landing/sidebar route, with matching readable responsive styling and relative manual/module backlinks. Support documented invocations from repository root and book directory; watch source changes without an infinite rebuild loop. Keep generated output ignored/local and synchronize README/build/tool guidance only where their contracts change. Verify native built delivery, complete source/index contracts, fresh output after an input change and browser/rendered readability, then commit.`
  Verification: `pending generated reference and facade POD`
  Commit: `pending`

- ID: `PERL-POD-API-REFERENCE.5`
  Status: `pending`
  Goal: `Qualify complete reference delivery and restore the saved feature frontier.`
  Acceptance: `Independently join the declared source/POD/facade population to generated pages and working local links, run documented examples and ordinary native book builds, and verify repeatability, freshness, locality and relevant broader regression. Retain precise coverage boundaries and all original failures. Complete required doctrine/commit checks, leave the tree clean and message empty, and resume the preserved reusable-width frontier. No unqualified hosted publication or API/runtime expansion.`
  Verification: `pending implementation and integration`
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
