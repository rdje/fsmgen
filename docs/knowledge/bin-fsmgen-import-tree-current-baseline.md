---
id: bin-fsmgen-import-tree-current-baseline
title: Current bin/fsmgen import-tree baseline is recorded in docs/BIN_FSMGEN_IMPORT_TREE.md
answers:
  - "what is the current bin/fsmgen import-tree baseline?"
  - "how many project-owned files does bin/fsmgen currently reach?"
  - "where is the live bin/fsmgen import-tree architecture note?"
  - "does bin/fsmgen reach semantic-introspection support?"
  - "does bin/fsmgen reach the AXI manager PPIF implementation?"
date: 2026-06-16
status: current
tags: [bootstrap, architecture, import-tree, bin-fsmgen, semantic-introspection, ial2, ppif]
evidence: docs/BIN_FSMGEN_IMPORT_TREE.md; docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUN16-REFRESH.md
reverify: perl -Iperl -MModule::ScanDeps=scan_deps -E 'my $d=scan_deps(files=>["bin/fsmgen"], recurse=>1); my @pm=grep { /(?:^|\/)FSM\// && /\.pm\z/ } keys %$d; say "total=".(scalar(@pm)+1); say "pm=".scalar(@pm);'
---

`docs/BIN_FSMGEN_IMPORT_TREE.md` is the canonical live maintainer-facing
architecture note for the `bin/fsmgen` runtime spine.

As of the 2026-06-16 refresh, the static project-owned closure reaches `206`
project files total: `205` `FSM::...` `.pm` packages plus `bin/fsmgen`.
The closure includes the `.isf` front door, the `.ppif`/IAL2 front door, the
AXI manager capacity/status PPIF implementation, bounded VHDL owners, and the
first-class semantic-introspection manifest support surface.
