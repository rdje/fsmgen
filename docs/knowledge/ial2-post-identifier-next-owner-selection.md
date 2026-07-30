---
id: ial2-post-identifier-next-owner-selection
title: The identifier-era bin/fsmgen import-tree refresh is selected next
answers:
  - "what follows the portable HDL instance-identifier implementation?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.839 select?"
  - "why did the bin/fsmgen import closure move from 228 to 229 files?"
  - "which package made the canonical import-tree note stale on July 30?"
  - "what AHB mdBook contradiction remains after selector .839?"
date: 2026-07-30
status: current
tags: [ial2, selector, bootstrap, architecture, import-tree, identifiers, documentation]
evidence: docs/IAL2_POST_IDENTIFIER_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/BIN_FSMGEN_IMPORT_TREE.md; docs/knowledge/bin-fsmgen-import-tree-current-baseline.md; perl/FSM/Support/HDLInstanceIdentifierPolicy.pm; docs/book/src/16c-ial2-ahb.md
reverify: perl -Iperl -MModule::ScanDeps=scan_deps -E 'my $d=scan_deps(files=>["bin/fsmgen"], recurse=>1); my @pm=grep { /(?:^|\/)FSM\/.*\.pm\z/ } keys %$d; say "total=".(scalar(@pm)+1); say "pm=".scalar(@pm); say "ial2=".scalar(grep { /(?:^|\/)FSM\/IAL2\// } @pm); say "policy=".scalar(grep { /(?:^|\/)FSM\/Support\/HDLInstanceIdentifierPolicy\.pm\z/ } @pm);'
---

Parent selector `.839` selects proposed no-behavior
`BIN-FSMGEN-IMPORT-TREE-JUL30-IDENTIFIER-REFRESH.1` after the portable
identifier implementation and grouped AXI assertion expectation repair ship.

The live closure is `229` project files / `228` packages / `19` IAL2 owners,
while the canonical note/fact remain at `228` / `227` / `19`. The exact added
owner is `perl/FSM/Support/HDLInstanceIdentifierPolicy.pm`, introduced by clean
implementation commit `299db4cae`; Support therefore moves from `70` to `71`.

The selected leaf is documentation-only and remains inactive until a separate
clean activation. Chapter 16c's later claim that counts beyond four remain
outside the shipped surface contradicts its current canonical literal `2..16`
sections; `.839` preserves that as the next independent documentation
candidate rather than mixing it into the import-map refresh.
