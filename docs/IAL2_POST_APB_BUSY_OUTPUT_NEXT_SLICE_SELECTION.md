# IAL2 Post APB Busy Output Next Slice Selection

Date: 2026-06-27

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.573`

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.573` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.574`, a no-behavior public-surface and
import-tree synchronization slice, before any further APB, AXI, direct backend,
verification-output, backend-language variant, or VHDL behavior work.

The immediate reason is that `.572` shipped additional public APB IAL2 surfaces
and reachable APB protocol-intent owners. The live `bin/fsmgen` import probe now
reaches `213` project-owned files total, including `212` `FSM::...` `.pm`
packages, while `docs/BIN_FSMGEN_IMPORT_TREE.md` and the corresponding
Knowledge Map fact still record the older `206`/`205` baseline. The mdBook
language-surface chapter also still describes `.axi` as outside the bounded
public surface and omits the shipped `.apb` alias and APB busy variants.

## Read Inputs

- `.572` APB busy output behavior:
  `docs/IAL2_APB_REQUESTER_BUSY_OUTPUT_BEHAVIOR.md`
- `.571` APB busy/status contract:
  `docs/IAL2_APB_REQUESTER_BUSY_STATUS_CONTRACT_SELECTION.md`
- Current APB behavior pages:
  `docs/IAL2_APB_PPIF_REQUESTER_TRANSFER_BEHAVIOR.md`,
  `docs/IAL2_APB_PPIF_COMPLETER_BEHAVIOR.md`,
  `docs/IAL2_APB_PPIF_COMPOSITION_BEHAVIOR.md`,
  `docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md`
- Post-APB selectors:
  `docs/IAL2_POST_APB_ALIAS_WIDENING_NEXT_SLICE_SELECTION.md`,
  `docs/IAL2_POST_APB_COMPOSITION_NEXT_SLICE_SELECTION.md`
- Roadmap/public surfaces:
  `README.md`, `ROADMAP_V2.md`, `docs/book/src/14-feature-backlog.md`,
  `docs/book/src/13-intent-scheduling.md`, and
  `docs/book/src/11-extensions-and-embedding.md`
- Runtime/support anchors:
  `perl/FSM/Support/RegressionCorpus.pm`,
  `perl/FSM/Support/LanguageSurfaceSection.pm`,
  `perl/FSM/Adapter/IAL2/PPIF.pm`,
  `perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm`,
  `perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm`, and
  `perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm`
- Continuity anchors:
  `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`,
  `docs/TASK_TREE.md`, `MEMORY.md`, and `KNOWLEDGE_MAP.md`
- Relevant decisions:
  `docs/decisions/0006-mdbook-sync-and-tests.md`,
  `docs/decisions/0007-memory-architecture.md`,
  `docs/decisions/0014-ial2-purpose-and-boundary.md`,
  `docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md`,
  `docs/decisions/0016-ppif-is-first-public-ial2-container.md`,
  `docs/decisions/0017-ial2-protocol-platform-aliases-lower-through-ppif.md`,
  and `docs/decisions/0018-ial-contracts-are-backend-language-neutral.md`
- Current import-tree probe:
  `perl -Iperl -MModule::ScanDeps=scan_deps -E 'my $d=scan_deps(files=>["bin/fsmgen"], recurse=>1); my @pm=grep { /(?:^|\/)FSM\// && /\.pm\z/ } keys %$d; say "total=".(scalar(@pm)+1); say "pm=".scalar(@pm); say join("\n", sort grep { /(?:Adapter\/IAL2|IAL2\/ProtocolIntent|Support\/LanguageSurfaceSection|Support\/RegressionCorpus)/ } @pm);'`

## Selected Next Slice

`.574` will synchronize public surfaces and the `bin/fsmgen` import-tree
baseline without changing runtime behavior.

The slice must:

- Refresh `docs/BIN_FSMGEN_IMPORT_TREE.md` and the associated Knowledge Map
  fact from `206` total / `205` `.pm` packages to the live `213` total / `212`
  `.pm` packages.
- Name the reachable IAL2 APB owners:
  `FSM::IAL2::ProtocolIntent::ApbRequesterTransfer`,
  `FSM::IAL2::ProtocolIntent::ApbCompleter`, and
  `FSM::IAL2::ProtocolIntent::ApbComposition`.
- Update mdBook public language-surface prose so `.ppif`, `.axi`, and `.apb`
  are described as shipped bounded surfaces, and so APB requester-transfer,
  completer, fixed composition, profile-alias, and busy-capable variants are
  visible from the user-facing book.
- Keep unsupported historical/generic spellings explicit:
  `.pif`, `.ppi`, `.chi`, `.ace`, `.ahb`, `.atb`, `.smbus`, and `.i2s` remain
  outside the bounded public surface.
- Sync `README.md`, `ROADMAP_V2.md`, `docs/TASK_TREE.md`, the active task tree,
  `MEMORY.md`, and Knowledge Map.
- Run the import probe, Knowledge Map generation/check, mdBook build,
  docs-relative-path audit, memory-architecture check, diff check, and doctrine
  driver.

## Non-Goals

`.574` must not change parser behavior, generator behavior, samples,
support-accounting catalog entries, validation behavior, generated artifacts,
tests, schedule/check/semantic JSON behavior, HDL/runtime behavior, direct
backend lowering, verification-output generation, backend-language variants,
AXI behavior, APB behavior, or VHDL behavior.

The following remain deferred behind future exact owners:

- APB report-only cleanup beyond public-surface wording.
- Named APB status fields.
- Multi-peripheral APB decode.
- Multi-register APB decode.
- APB sidebands or strobes.
- Alternate APB widths.
- APB back-to-back transfer policy.
- Direct backend lowering.
- Verification-output generation.
- Backend-language variants.
- AXI follow-on behavior.
- VHDL behavior.

## Validation Plan

`.574` should run at minimum:

```sh
perl -Iperl -MModule::ScanDeps=scan_deps -E 'my $d=scan_deps(files=>["bin/fsmgen"], recurse=>1); my @pm=grep { /(?:^|\/)FSM\// && /\.pm\z/ } keys %$d; say "total=".(scalar(@pm)+1); say "pm=".scalar(@pm); say join("\n", sort grep { /(?:Adapter\/IAL2|IAL2\/ProtocolIntent|Support\/LanguageSurfaceSection|Support\/RegressionCorpus)/ } @pm);'
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t
mdbook build docs/book
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback Boundary

Rollback is documentation-only: revert the `.573` selector commit and leave the
runtime `.572` APB busy output behavior unchanged. If `.574` finds a mismatch
between live probe output and documentation that is not documentation-only, stop
and create a new exact task-tree owner before changing behavior.
