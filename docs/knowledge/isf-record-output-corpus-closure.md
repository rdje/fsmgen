---
id: isf-record-output-corpus-closure
title: Maintained record output corpus preserves complete discovery and cohort applicability
answers:
  - "which maintained example demonstrates packed record output copies?"
  - "does record output corpus promotion preserve existing source query memberships?"
  - "does the record output catalog claim generated mappings or simulation?"
  - "is bounded record output source and public qualification complete?"
date: 2026-10-02
status: current
tags: [isf, record, output, corpus, public, mcp, specforge]
evidence: >-
  docs/audits/record-output-corpus-20261002/manifest.json;
  isf/record_output.isf; perl/FSM/Support/RegressionCorpus.pm;
  t/2037-isf-record-output-corpus-closure.t;
  t/1985-isf-interface-port-public-qualification.t;
  t/1883-semantic-source-query-cohort.t;
  t/248-regression-corpus-accounting.t;
  docs/isf-spec/11-downstream-actor-transactions.md;
  docs/isf-spec/22-public-interface-reports-evolution.md
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/2037-isf-record-output-corpus-closure.t
  t/1985-isf-interface-port-public-qualification.t
  t/1883-semantic-source-query-cohort.t
  t/248-regression-corpus-accounting.t
---

`isf/record_output.isf` is the maintained direct actor representative. A local
recursive record contains a kind, signed four-state data and a nested fixed list
with an unqualified bit and a two-state vector. Its interleaved authored
directions project to inputs then outputs without losing order inside each role.
The explicit controller copies input `incoming` into owned `held`, copies `held`
into whole output `packet`, then reads `packet.payload.data` into scalar `seen`.
Independent literal declarations and recursive semantic types preserve complete
JSON primitive kinds, ordered packing and absent state-model properties.

`feature.isf_record_output` owns supported-smoke parse/typecheck/lowering/check,
semantic/schedule reports and SystemVerilog generation. Internal catalog phase
and nonclaim arrays survive complete source-query selection. The manifest keeps
its existing sanitized catalog-entry schema; these internal arrays are not new
published fields. Output simulation, generated output mappings, member writes,
Verilog/VHDL, X/Z execution, reset-free initialization and full consumer delivery
remain explicit nonclaims.

Complete baseline/current catalog records, every source cohort record across all
published query-kind families, source byte identities and full discovery
products are retained. Existing records and order remain exact after removing
only the owned addition. All-section native, in-process, API and actual newline
discovery agree; every manifest field remains exact except the new entry and
derived accounting buckets/lists. This accounts complete applicability. It does
not claim actual execution of every supported source query.

Actual maintained-source public transports, strict carrier replay and complete
SystemVerilog/sv text re-derive the bounded products without HDL tool execution.
Independent literal metadata, recursive types, explicit carrier copy edges,
complete before/after allocation and hostile membership/kind/layout/role/state
corruption provide falsification. Full source/products/receipts, exact producer
Git objects, immutable prior archives, sealed verifier, permanent tests,
canonical downstream/spec/book/feedback, this card/task and Git retain durability.
The initial archive verifier omitted its retained source dependency; its complete
failed receipt and source remain archived. Catalog census tests initially retain
their old literals; exact complete membership allocation earns the revised
supported/strict census without dropping checks.

Bounded output source/public/profile/corpus reconciliation is complete under
SEM `.60.4.3.3.4`. Generated output handoff and execution remain `.60.4.3.3.5`;
output fields remain `.60.4.3.4`. The full SPECFORGE request is still open.
