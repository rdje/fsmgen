---
id: isf-record-input-direct-witness-preparation
title: Direct packed-input witness separates preparation from native execution
answers:
  - "where is direct packed record-input runtime qualification owned?"
  - "does the prepared direct record-input bench establish native behavior?"
  - "how does the packed-input witness separate live sample and whole-copy values?"
date: 2026-10-01
status: current
tags: [isf, record-ports, verification, runtime]
evidence: t/2024-isf-record-input-runtime.t; t/data/isf_record_input_runtime.isf; t/data/isf_record_input_runtime_tb.sv; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/2024-isf-record-input-runtime.t
---

SEM .60.4.3.2.5.1 prepares the fixed direct source and public-pin bench T2024.
Its single transaction reads the prior held record before replacing it, samples
a scalar member explicitly at accepted entry, then copies the live whole input
and later reads scalar fields live. Public phase outputs allow independently
authored pin changes around these distinct edges. Literal nested layouts and
signed/state properties are checked against actual parsed/native semantic,
scheduled carrier and both emitted Verilog-family products. Equal-width authored
property/member-order variants fail the unchanged independent declaration witness.

The bench owns literal packed words and expected scalar values, repeated requests,
idle holds, asynchronous reset/abort and the held record's authored reset value.
It does not derive expected values from compiler layout or schedule producers.
A deliberately unsigned same-width source is prepared for subsequent behavioral
falsification. The static slice does not compile or execute HDL; T2024's runtime
subtest is explicitly skipped without FSMGEN_RECORD_INPUT_RUNTIME=1.

Native execution requires new fixed observer qualification under .2.5.2 followed
by genuine observation under .2.5.3. HIAL .3.2.10.11.5 requires exact target/input
identities, unchanged supervision and explicit diagnostic gaps/cleanup; the old
T1974 admission is not reusable for this different target. Four-state declarations
are structurally preserved, while binary-valued Verilator behavior cannot prove
X/Z semantics. Generated/domain execution and backend/input completion remain
.2.5.4-.5. No historical EPERM repair or complete aggregate delivery follows.

Actual source/semantic/carrier/emitted products re-derive the prepared structure;
independent literals and actual authored counterexamples provide structural
falsification. Tracked source/bench/test, this fact, task nodes and Git provide
durability. Runtime re-derivation and behavioral falsification are separately qualified
under .5.3; see docs/knowledge/isf-record-input-direct-runtime.md. The reverify command checks preparation
only unless a genuine runtime has its separately qualified admission.
