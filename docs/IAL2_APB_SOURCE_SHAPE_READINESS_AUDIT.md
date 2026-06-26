# IAL2 APB Source-Shape Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.548`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.548` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.549`, a public APB `.ppif` source-shape
contract selection before any APB `.ppif` sample or `.apb` suffix behavior.

The audit finds that APB has enough lower-layer evidence to justify a contract
selection owner, but not enough public IAL2 evidence to implement behavior in
this slice. The next owner should select an APB source shape under the generic
`.ppif` container, not accept `.apb`.

No parser behavior, generator behavior, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check/
semantic JSON behavior, HDL/runtime behavior, backend behavior,
verification-output generation, backend-language variant, external converter
dependency, scoreboard, AXI behavior, non-AXI behavior, common construct
promotion, profile-alias suffix syntax, generic-container alias syntax, direct
backend lowering, or VHDL behavior changed.

## Evidence Read

Decision `0015` keeps protocol-specific file extensions such as `.apb` as
future profile aliases over IAL2, not separate layers.

Decision `0016` selects `.ppif` as the first public generic IAL2 container and
leaves `.pif` and `.ppi` unaccepted unless a later exact owner selects them.

Decision `0017` selects aggregate Valid-Ready bundle reporting under `.ppif`;
it does not create an APB profile, an APB source shape, or an APB suffix.

The `.547` selector keeps `.pif` and `.ppi` explicitly unsupported historical
generic-container spellings and points this audit at APB as the next non-AXI
protocol-profile evidence target. The `.546` taxonomy classifies `.apb` as a
protocol-profile alias candidate, not a generic-container spelling.

The current CLI and adapter surfaces remain deliberately closed:

- `bin/fsmgen` knows `.apb` as a known unsupported IAL2 alias candidate and
  rejects it before PPIF parsing.
- `FSM::Adapter::IAL2::PPIF` parses only `.ppif` and the first shipped `.axi`
  profile-alias files.
- `LanguageSurfaceSection` ships `.fsm`, `.isf`, `.ppif`, and `.axi`, and
  keeps `.apb` in the unsupported first-slice alias inventory.
- `RegressionCorpus` support-accounts APB only as lower-layer `.isf`, `.fsm`,
  and composition fixtures, not as IAL2 `.ppif` or `.apb`.

## APB Evidence

APB has real lower-layer evidence in the repository:

- `isf/apb_requester.isf` is the realistic APB requester ISF fixture. It
  declares the local request side, APB bus side, setup/access/done phases,
  `PREADY` wait, `PRDATA` and `PSLVERR` sampling, and bounded latency.
- `fsm/apb_requester.fsm` is the active IAL0 requester model with one
  outstanding APB transfer, setup/access states, `PREADY` completion,
  `PSLVERR` capture, and read-data capture.
- `fsm/apb_completer.fsm` is the APB target/completer model with setup
  detection, optional wait cycles, a single implemented register location, and
  `PSLVERR` for other addresses.
- `fsm/apb_tb.fsm` composes the requester and completer through explicit APB
  bus wiring.
- The mdBook documents APB ISF examples, the APB transfer lowering reference,
  the APB feature-support matrix baseline, and the APB/C4 generated-FSM VHDL
  composition boundary.

That evidence is strong enough to select an APB `.ppif` source-shape contract.
It is not itself an IAL2 contract. The repository still lacks an authored APB
`.ppif` source, an APB profile-name rule, an APB IAL2 report schema or report
fields, support-accounting identity, sample name, APB-specific diagnostics,
and mdBook runnable APB `.ppif` commands.

## Readiness Finding

The next safe owner is APB `.ppif` source-shape public contract selection.
APB lower-layer fixtures are mature enough that a selector can make the public
IAL2 decisions before implementation. A lower-layer prerequisite is not needed
before the selector because the existing `.isf`, `.fsm`, composition, docs,
and support catalog already demonstrate the APB requester/completer shape that
the IAL2 source would target.

A report/support-accounting prerequisite should not be selected first either.
Those names depend on the public APB source-shape contract: the profile name,
source object, generated review artifacts, report schema or report fields, and
sample/support identity must be selected before support accounting can be
added without guessing.

Deferral would waste the evidence already present and would leave the non-AXI
IAL2 frontier stuck on unsupported suffix inventory instead of protocol
source-shape work.

The audit therefore selects contract selection, not implementation.

## Selected `.549` Scope

`.549` should select the public APB `.ppif` source-shape contract before any
behavior change.

The selector should decide:

- the APB profile spelling under `.ppif`, likely an explicit `(profile apb)`
  family rather than a suffix;
- the top-level APB intent object and source-anchor policy;
- the first APB object vocabulary, such as requester transfer intent, bus
  endpoint roles, setup/access phase names, wait-state behavior, response
  sampling, and bounded latency;
- how the APB source maps to generated `.isf` and generated `.fsm` review
  artifacts without widening `.isf` with IAL2 syntax;
- the report schema or additive report fields for source anchors, APB residue,
  generated artifacts, and APB-specific static rules;
- the eventual sample path and support-accounting identity, without adding
  the sample in the contract-selection slice;
- APB-specific diagnostics, including profile/source-shape mismatch wording;
- mdBook example shape and command set for a later implementation owner; and
- preservation tests needed for existing `.ppif`, `.axi`, protocol-neutral
  Valid-Ready, APB `.isf`, APB `.fsm`, and APB composition behavior.

`.549` must not accept `.apb`, `.pif`, `.ppi`, `.chi`, `.ace`, `.ahb`, `.atb`,
`.smbus`, `.i2s`, or any other suffix; must not add an APB `.ppif` sample;
must not change parser, generator, manifest, support-accounting, JSON, HDL,
runtime, backend, verification-output, or VHDL behavior; and must not extend
`.axi`.

## Deferred Alternatives

The following remain future exact-owner work:

- direct APB `.ppif` parser/generator implementation;
- a checked-in APB `.ppif` sample;
- `.apb` suffix/profile-alias behavior;
- APB support-accounting entries;
- APB report/schema behavior;
- APB-specific generated HDL behavior beyond the existing lower-layer
  fixtures;
- APB verification-output generation;
- direct IAL2-to-IAL0 lowering; and
- VHDL widening beyond the already shipped APB/C4 composition subset.

## Validation

Closeout for this audit is documentation-only:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback is documentation-only: remove this audit, its Knowledge Map fact,
task-tree advancement, README/ROADMAP_V2/mdBook sync, and Memory pointer. No
parser, generator, sample, support-accounting, generated HDL, runtime, or
backend artifact rollback is required.
