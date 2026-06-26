---
id: backend-language-portable-parity-harness-selection
title: Portable parity harness compares normalized public contracts against the Perl oracle
answers:
  - "what did BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.5 select?"
  - "how will future FSMGen implementation-language variants prove parity?"
  - "what normalization rules apply to backend-language parity?"
  - "how should broad t/301 and t/303 parity gates be handled?"
  - "what comes after the parity harness selection?"
date: 2026-06-26
status: current
tags: [architecture, portability, parity, regression-corpus, diagnostics]
evidence: docs/BACKEND_LANGUAGE_PORTABLE_PARITY_HARNESS_SELECTION.md; docs/BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION.md; docs/BACKEND_LANGUAGE_PORTABLE_HOST_ABSTRACTION_SELECTION.md; docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/Support/RegressionCorpus.pm; t/296-regression-corpus-supported-behavior.t; t/249-regression-corpus-classified-behavior.t; t/301-check-json-supported-corpus.t; t/303-normalized-semantic-json-supported-corpus.t; t/1466-ppif-check-json-oversized-summary.t
reverify: rg -n 'BACKEND_LANGUAGE_PORTABLE_PARITY_HARNESS_SELECTION|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.5|Perl-reference parity harness|source_id|support_accounting|resource_sensitive|t/301-check-json-supported-corpus|t/303-normalized-semantic-json-supported-corpus|run_with_ram_guard|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.6' docs/BACKEND_LANGUAGE_PORTABLE_PARITY_HARNESS_SELECTION.md docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/backend-language-portable-parity-harness-selection.md
---

`BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.5` selected a differential
parity harness model with the current Perl 5 implementation as the
reference/oracle. Future implementation-language variants must run the same
logical `.2.3` request family over the same `.2.4` source graph, normalize
host-specific details, and compare the normalized public result against the
Perl oracle before claiming feature support.

The selected corpus partitions are `supported_smoke`, `strict_supported`,
`expected_failure`, `legacy_out_of_scope`, and `resource_sensitive`. Public
parity covers capability manifests, check JSON, semantic JSON, lowering and
schedule artifacts, generated HDL behavior, shipped verification outputs,
diagnostics, support accounting, and semantic-introspection/MCP surfaces for
variants that claim them.

Normalization removes host-specific paths, temp directories, output roots, JSON
key ordering, line endings, and resource measurements while preserving public
source identity, support accounting, diagnostics, artifact identities, and HDL
semantics. Broad `t/301`/`t/303` style gates remain logical parity targets, but
resource-sensitive runs must use `scripts/run_with_ram_guard.sh` or exact
bounded replacement tests. The next active backend-portability selector is
`.2.6`, the mdBook language-X implementation blueprint structure.
