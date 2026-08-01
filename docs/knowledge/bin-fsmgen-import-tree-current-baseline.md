---
id: bin-fsmgen-import-tree-current-baseline
title: Current bin/fsmgen import-tree baseline is recorded in docs/BIN_FSMGEN_IMPORT_TREE.md
answers:
  - "what is the current bin/fsmgen import-tree baseline?"
  - "how many project-owned files does bin/fsmgen currently reach?"
  - "where is the live bin/fsmgen import-tree architecture note?"
  - "is BIN_FSMGEN_IMPORT_TREE.md still needed?"
  - "does bin/fsmgen reach semantic-introspection support?"
  - "does bin/fsmgen reach the AXI manager PPIF implementation?"
  - "does bin/fsmgen reach the APB PPIF implementation?"
  - "does bin/fsmgen reach the portable HDL instance-identifier policy?"
  - "does bin/fsmgen reach public VIAL source tooling?"
  - "does bin/fsmgen reach public VIAL planning artifacts?"
date: 2026-07-31
status: current
tags: [bootstrap, architecture, import-tree, bin-fsmgen, semantic-introspection, ial2, ppif]
evidence: docs/BIN_FSMGEN_IMPORT_TREE.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; bin/fsmgen; perl/FSM/VIAL/ToolCLI.pm; perl/FSM/VIAL/Tool.pm; perl/FSM/VIAL/SourceProjection.pm; perl/FSM/VIAL/PlanBuilder.pm; perl/FSM/VIAL/ArtifactTransaction.pm; perl/FSM/Support/VIALToolingContract.pm; docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUL30-IDENTIFIER-REFRESH.md; docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUL29-REFRESH.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; perl/FSM/ProjectDataLocality.pm; perl/FSM/Support/HDLInstanceIdentifierPolicy.pm; perl/FSM/Adapter/IAL2/PPIF.pm; docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUN28-REFRESH.md; docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUN23-REFRESH.md; docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUN22-REFRESH.md; docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUN16-REFRESH.md
reverify: perl -Iperl -MModule::ScanDeps=scan_deps -E 'my $d=scan_deps(files=>["bin/fsmgen"], recurse=>1); my @pm=grep { /(?:^|\/)FSM\/.*\.pm\z/ } keys %$d; say "total=".(scalar(@pm)+1); say "pm=".scalar(@pm); say "ial2=".scalar(grep { /(?:^|\/)FSM\/IAL2\// } @pm); say "vial=".scalar(grep { /(?:^|\/)FSM\/VIAL\// } @pm); say "hial=".scalar(grep { /(?:^|\/)FSM\/HIAL\// } @pm);'
---

`docs/BIN_FSMGEN_IMPORT_TREE.md` is the canonical live maintainer-facing
architecture note for the `bin/fsmgen` runtime spine.

As of the 2026-07-31 public-VIAL-planning refresh, the static
project-owned closure reaches `248` project files total: `247` `FSM::...` `.pm`
packages plus
`bin/fsmgen`, with
`19` packages under `FSM/IAL2`. The closure includes the `.isf` front door; the
`.ppif`/profile-alias IAL2 front door; the Valid-Ready, AXI manager plus bounded
AXI initiator, APB, and AHB protocol-intent owners; bounded direct/composition
VHDL owners; semantic-introspection and verification-output support; and the
repository-local project-data owner; and the shared portable HDL child-instance
identifier policy. It now also reaches the 13-package VIAL source/planning path
and three-package private HIAL bridge family for canonical review routing,
defensive public plan projection, and atomic repository-local artifacts,
without reaching a VIAL target backend or runtime. The canonical maintainer
note records the complete reachable package inventory, measured family counts
(`Support 74`, `VIAL 13`, `HIAL 3`), selected line counts, runtime spines, and
current hotspots.

It remains objectively useful rather than duplicate history: README, roadmap,
bootstrap, mdBook, task evidence, and executable `Module::ScanDeps` refreshes
consume it as the current runtime-spine map. Leaf
`LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.13` therefore retains it as live
maintainer reference and fixes its representation by wrapping overlong prose;
deleting it would remove a current architecture view not supplied by the
generated file inventory or raw dependency output alone.
