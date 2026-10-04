---
id: record-value-finite-copy-probe-reader
title: Finite record-value copy probes have independent typed graph qualification
answers:
  - "are the T1986 finite copy probes independently qualified?"
  - "what validates plain copy helper sharing and detachment?"
  - "how can the finite copy probes be replayed without changing sealed evidence?"
  - "are original T1986 candidate copy inputs captured?"
  - "what qualifies original T1986 candidate copy graphs?"
date: 2026-10-05
status: current
tags: [isf, record, copy, native, graph, qualification]
evidence: >-
  docs/audits/record-value-copy-probe-join-20261004/scope.txt;
  docs/audits/record-value-copy-probe-join-20261004/verify.py;
  docs/audits/record-value-copy-reader-20261004/scope.txt;
  docs/audits/record-value-copy-reader-20261004/verify.py;
  docs/audits/record-value-copy-reader-20261004/replay.py;
  docs/audits/record-value-copy-probes-20261004/manifest.json;
  docs/audits/record-value-original-candidate-20261004/scope.txt;
  docs/audits/record-value-original-candidate-20261004/check_capture.py;
  docs/audits/record-value-original-copy-reader-20261004/scope.txt;
  docs/audits/record-value-original-copy-reader-20261004/verify.py;
  docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: >-
  scripts/run_with_ram_guard.sh -- python3 -B
  docs/audits/record-value-original-copy-reader-20261004/verify.py &&
  python3 -B docs/audits/record-value-original-candidate-20261004/check_capture.py &&
  python3 -B docs/audits/record-value-copy-probe-join-20261004/verify.py &&
  scripts/run_with_ram_guard.sh -- python3 -B
  docs/audits/record-value-copy-reader-20261004/replay.py
---

The independent reader resolves complete serialized graph edges and checks a
typed bijection against separate authored object models. Reachable sets derive
reference populations and input/result sharing. Ordinary readonly, kinds,
sharing, cycles and detached copies qualify for the recorded plain profile.
Actual Storable, alias, split-sharing, cycle-alias, input-kind and result-kind
providers reach their own expected assertions; non-target records conserve.

Native boundary records preserve complete raw causes, class, HASH shape and
within-capture identity for the two observed empty blessed classes. This is
refusal evidence, not native-class copying or structured-clone cycle support.
Graph/cause/identity mutations and changed whole program authority reject.

Replay creates a fresh same-volume fixture with exact pinned sources. Whole
native records and both output streams remain retained; addresses keep their
actual per-capture lifetimes. Sealed producers never run in their own archive.
The finite join now authenticates exact completed owners and complete fresh
products. Original candidate captures now retain complete unchanged-input
Storable/alias trials and the full alias run's downstream mutation and abort.
Independent typed source models now qualify the unchanged-original copy
graphs and genuine provider trials, including readonly and detachment. Whole
API/consumer and full alias downstream semantics, their join and cold replay
remain open. The candidate-parent join, hot baseline/consumer repairs and
host-native refusal qualification remain separately owned successors.
