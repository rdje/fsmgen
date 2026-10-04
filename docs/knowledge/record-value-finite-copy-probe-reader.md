---
id: record-value-finite-copy-probe-reader
title: Finite record-value copy probes have independent typed graph qualification
answers:
  - "are the T1986 finite copy probes independently qualified?"
  - "what validates plain copy helper sharing and detachment?"
  - "how can the finite copy probes be replayed without changing sealed evidence?"
date: 2026-10-04
status: current
tags: [isf, record, copy, native, graph, qualification]
evidence: >-
  docs/audits/record-value-copy-reader-20261004/scope.txt;
  docs/audits/record-value-copy-reader-20261004/verify.py;
  docs/audits/record-value-copy-reader-20261004/replay.py;
  docs/audits/record-value-copy-probes-20261004/manifest.json;
  docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: >-
  python3 -B docs/audits/record-value-copy-reader-20261004/verify.py &&
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
The finite join, actual original inputs, hot baseline/consumer repairs and
host-native refusal qualification remain separately owned successors.
