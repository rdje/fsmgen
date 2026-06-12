---
id: ial2-ppif-bundle-semantic-json-first-slice
title: IAL2 PPIF bundle semantic JSON first slice
answers:
  - "does PPIF bundle semantic JSON work now?"
  - "what semantic root kind does a PPIF bundle use?"
  - "where is PPIF bundle semantic JSON documented?"
  - "does bundle semantic JSON pick one generated fsm root?"
  - "what corpus entry covers PPIF bundle semantic JSON?"
date: 2026-06-12
status: current
tags: [ial2, ppif, bundle, normalized-semantic-json, public-api]
evidence: docs/IAL2_PPIF_BUNDLE_SEMANTIC_JSON_FIRST_SLICE.md; docs/IAL2_PPIF_BUNDLE_HDL_ENTRY_FIRST_SLICE.md; ppif/axi_aw_w_valid_ready_bundle.ppif; bin/fsmgen; perl/FSM/Support/NormalizedSemanticProtocolIntentBundleContract.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/303-normalized-semantic-json-supported-corpus.t; docs/tasks/IAL2-PPIF-BUNDLE-SEMANTIC-JSON-FIRST-SLICE.md; docs/tasks/IAL2-PPIF-BUNDLE-HDL-ENTRY-FIRST-SLICE.md
reverify: prove -Iperl t/1436-ial2-ppif-parser-cli.t t/303-normalized-semantic-json-supported-corpus.t
---

Multi-channel `.ppif` Valid-Ready bundles now support
`--emit-semantic-json`. The export is aggregate: it keeps
`source.resolved_path` on the public `.ppif` file, reports
`semantic.module.source_root_kind = ppif_bundle`, and exposes the optional
`semantic.protocol_intent_bundle` child.

The bundle semantic export does not pick one generated channel `.fsm` as the
root. It reports the bundle schema, channel list, generated `.isf`/`.fsm`
review artifact summaries, per-channel schedule-report presence, and the
selected aggregate wrapper/top HDL entry. The support-accounting corpus entry
is `intent.ppif_axi_aw_w_valid_ready_bundle`.
