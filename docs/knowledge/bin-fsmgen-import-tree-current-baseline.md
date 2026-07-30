---
id: bin-fsmgen-import-tree-current-baseline
title: Current bin/fsmgen import-tree baseline is recorded in docs/BIN_FSMGEN_IMPORT_TREE.md
answers:
  - "what is the current bin/fsmgen import-tree baseline?"
  - "how many project-owned files does bin/fsmgen currently reach?"
  - "where is the live bin/fsmgen import-tree architecture note?"
  - "does bin/fsmgen reach semantic-introspection support?"
  - "does bin/fsmgen reach the AXI manager PPIF implementation?"
  - "does bin/fsmgen reach the APB PPIF implementation?"
date: 2026-07-30
status: current
tags: [bootstrap, architecture, import-tree, bin-fsmgen, semantic-introspection, ial2, ppif]
evidence: docs/BIN_FSMGEN_IMPORT_TREE.md; docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUL29-REFRESH.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; bin/fsmgen; perl/FSM/ProjectDataLocality.pm; perl/FSM/Adapter/IAL2/PPIF.pm; docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUN28-REFRESH.md; docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUN23-REFRESH.md; docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUN22-REFRESH.md; docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUN16-REFRESH.md
reverify: perl -Iperl -MModule::ScanDeps=scan_deps -E 'my $d=scan_deps(files=>["bin/fsmgen"], recurse=>1); my @pm=grep { /(?:^|\/)FSM\/.*\.pm\z/ } keys %$d; say "total=".(scalar(@pm)+1); say "pm=".scalar(@pm); say "ial2=".scalar(grep { /(?:^|\/)FSM\/IAL2\// } @pm);'
---

`docs/BIN_FSMGEN_IMPORT_TREE.md` is the canonical live maintainer-facing
architecture note for the `bin/fsmgen` runtime spine.

As of the 2026-07-30 refresh, the static project-owned closure reaches `228`
project files total: `227` `FSM::...` `.pm` packages plus `bin/fsmgen`, with
`19` packages under `FSM/IAL2`. The closure includes the `.isf` front door; the
`.ppif`/profile-alias IAL2 front door; the Valid-Ready, AXI manager plus bounded
AXI initiator, APB, and AHB protocol-intent owners; bounded direct/composition
VHDL owners; semantic-introspection and verification-output support; and the
repository-local project-data owner. The canonical maintainer note records the
complete reachable package inventory, measured family counts, selected line
counts, runtime spines, and current hotspots.
