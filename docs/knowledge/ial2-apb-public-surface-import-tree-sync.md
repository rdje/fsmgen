---
id: ial2-apb-public-surface-import-tree-sync
title: APB public-surface and import-tree sync after busy output
answers:
  - "is the APB public surface reflected in the mdBook?"
  - "is the bin/fsmgen import tree current after APB busy output?"
  - "which IAL2 APB owners are reachable from bin/fsmgen?"
  - "are .axi and .apb shipped language surfaces?"
date: 2026-06-27
status: current
tags: [ial2, apb, axi, import-tree, mdbook, language-surface]
evidence: docs/BIN_FSMGEN_IMPORT_TREE.md; docs/book/src/11-extensions-and-embedding.md; docs/book/src/13-intent-scheduling.md; docs/book/src/14-feature-backlog.md; docs/knowledge/bin-fsmgen-import-tree-current-baseline.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; MEMORY.md
reverify: >-
  perl -Iperl -MModule::ScanDeps=scan_deps -E 'my $d=scan_deps(files=>["bin/fsmgen"], recurse=>1); my @pm=grep { /(?:^|\/)FSM\// && /\.pm\z/ } keys %$d; die "bad total\n" unless scalar(@pm)+1 == 213; die "bad pm\n" unless scalar(@pm) == 212; my %seen=map { $_=>1 } @pm; for my $m (qw(FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm FSM/IAL2/ProtocolIntent/ApbCompleter.pm FSM/IAL2/ProtocolIntent/ApbComposition.pm)) { die "missing $m\n" unless $seen{$m}; } say "import tree APB owners ok";' && rg -n 'file suffixes: .*\\.fsm.*\\.isf.*\\.ppif|bounded profile aliases `.axi` and `.apb`|Historical or future spellings `.pif`, `.ppi`,|APB requester-transfer sources, APB completer|`IAL2` is the current protocol/platform intent layer' docs/book/src/11-extensions-and-embedding.md docs/book/src/13-intent-scheduling.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.574` synchronizes the public mdBook
language-surface prose and the `bin/fsmgen` import-tree baseline after `.572`
shipped APB requester `busy` output and `.573` selected the sync owner.

The refreshed import-tree baseline is `213` project files total: `212`
reachable `FSM::...` `.pm` packages plus `bin/fsmgen`. The reachable IAL2 APB
owners are `FSM::IAL2::ProtocolIntent::ApbRequesterTransfer`,
`FSM::IAL2::ProtocolIntent::ApbCompleter`, and
`FSM::IAL2::ProtocolIntent::ApbComposition`.

The mdBook language-surface chapter now describes `.ppif` as the generic IAL2
container and `.axi`/`.apb` as bounded shipped profile aliases. It also keeps
`.pif`, `.ppi`, `.chi`, `.ace`, `.ahb`, `.atb`, `.smbus`, and `.i2s`
explicitly outside the bounded public surface.
