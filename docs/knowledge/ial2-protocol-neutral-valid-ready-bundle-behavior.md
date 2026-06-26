---
id: ial2-protocol-neutral-valid-ready-bundle-behavior
title: FSMGen ships a protocol-neutral dual-channel Valid-Ready PPIF bundle
answers:
  - "does FSMGen have a protocol-neutral Valid-Ready PPIF bundle?"
  - "what is ppif/valid_ready_dual_channel_bundle.ppif?"
  - "how do I run the neutral Valid-Ready PPIF bundle?"
  - "what support-accounting id covers the neutral Valid-Ready bundle?"
  - "does the neutral Valid-Ready bundle report AXI manager residue?"
date: 2026-06-26
status: current
tags: [ial2, ppif, protocol-platform, valid-ready, bundle, profile, sample, support-accounting]
evidence: docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_BUNDLE_BEHAVIOR.md; ppif/valid_ready_dual_channel_bundle.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ValidReadyChannel.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/REGRESSION_CORPUS.md; t/1468-ial2-ppif-neutral-valid-ready-bundle.t; t/1435-axi-ial2-valid-ready-generator.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: prove -Iperl t/1468-ial2-ppif-neutral-valid-ready-bundle.t t/1435-axi-ial2-valid-ready-generator.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t && ./bin/fsmgen --emit-schedule-json ppif/valid_ready_dual_channel_bundle.ppif && ./bin/fsmgen --strict --check --json ppif/valid_ready_dual_channel_bundle.ppif && ./bin/fsmgen --strict --emit-semantic-json ppif/valid_ready_dual_channel_bundle.ppif
---

FSMGen ships `ppif/valid_ready_dual_channel_bundle.ppif` as the first
support-accounted protocol-neutral/non-AXI Valid-Ready `.ppif` bundle.

The sample uses `(profile valid-ready)`, channels `data_downstream` and
`status_upstream`, roles `producer-to-consumer` and `consumer-to-producer`,
and support-accounting id `intent.ppif_valid_ready_dual_channel_bundle`.

It reports generic aggregate residue
`valid_ready_profile_bundle_behavior_outside_monitor` and does not report the
AXI-profile `axi_manager_concurrency` residue. The existing AXI AW/W bundle
keeps its AXI residue.
