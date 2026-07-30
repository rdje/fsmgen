---
id: ial2-post-frozen-workflow-sync-next-owner-selection
title: The live bin/fsmgen import-tree refresh follows workflow doctrine repair
answers:
  - "what follows the frozen legacy task-tree workflow sync?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.835 select?"
  - "why is the bin/fsmgen import-tree refresh selected next?"
  - "how stale is the maintained bin/fsmgen import-tree note?"
  - "does selecting the import-tree refresh activate HIAL or VIAL?"
  - "why did the startup import count move from 227 to 228 files?"
date: 2026-07-30
status: current
tags: [ial2, selector, bootstrap, architecture, import-tree, documentation]
evidence: docs/IAL2_POST_FROZEN_WORKFLOW_SYNC_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/tasks/BIN-FSMGEN-IMPORT-TREE-JUL29-REFRESH.md; docs/BIN_FSMGEN_IMPORT_TREE.md; docs/knowledge/bin-fsmgen-import-tree-current-baseline.md; perl/FSM/ProjectDataLocality.pm
reverify: perl -Iperl -MModule::ScanDeps=scan_deps -E 'my $d=scan_deps(files=>["bin/fsmgen"], recurse=>1); my @pm=grep { /(?:^|\/)FSM\/.*\.pm\z/ } keys %$d; say "total=".(scalar(@pm)+1); say "pm=".scalar(@pm); say "ial2=".scalar(grep { /(?:^|\/)FSM\/IAL2\// } @pm);'
---

Parent selector `.835` selects proposed no-behavior
`BIN-FSMGEN-IMPORT-TREE-JUL29-REFRESH.1` after the frozen-legacy workflow repair
ships.

The activation-time live closure is `228` project files / `227` packages with
`19` IAL2 packages, while the maintained note and its current fact still claim
`213` / `212` and the note says `IAL2: 5`. The proposed child's earlier
`227` / `226` measurement is one package lower because clean same-volume
implementation commit `017153eac` subsequently added reachable singleton
`perl/FSM/ProjectDataLocality.pm`; this is explained expected drift.

The selected leaf may update only the import-tree architecture note, its fact,
and synchronized continuity/user documentation. Runtime and every broader
candidate remain unchanged. HIAL/VIAL, end-to-end scale, public-test drift,
mdBook rustdoc fences, other protocols/backends, and simulator work remain
independently proposed; RAM-guard refinement, t1436, and decision `0020` keep
their explicit gates.
