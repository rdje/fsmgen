---
id: isf-record-output-source-admission
title: Whole record outputs require exact types and mandatory realized-module writers
answers:
  - "are authored ISF record output declarations and whole copies admitted?"
  - "where does mandatory record output physical writer admission run?"
  - "can equal values or priority admit overlapping record output writers?"
  - "does record output source admission establish execution support?"
date: 2026-10-01
status: current
tags: [isf, record, output, source, writers, domains, specforge]
evidence: >-
  docs/audits/record-output-source-admission-20261001/manifest.json;
  t/2033-isf-record-output-source-admission.t;
  perl/FSM/Adapter/ISF/Parser.pm; perl/FSM/Scheduler/ISF.pm;
  perl/FSM/Scheduler/ISF/RecordOutputWriters.pm;
  docs/isf-spec/02-interface-transactions.md;
  docs/book/src/13j-type-enum-aggregate.md
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/2033-isf-record-output-source-admission.t
  t/2030-isf-record-output-writer-admission.t
  t/2029-isf-record-output-writer-inventory.t
---

Parser admits resolved record-kind aliases on actor outputs through the same
mandatory role/context/sample/domain gates as inputs. Local/imported aliases,
mixed and unused declarations retain authored identity and complete ordered
packed metadata. Whole permitted input/output/storage copies require identical
resolved recursive record types, not just widths. Scalar output reads and
explicit captures retain exact leaf type. Input writes, output member writes,
whole inferred record captures, root-list/formal aggregates and typed output
reset/default forms retain their explicit boundaries.

Scheduler lower and report apply conservative physical admission after binding
and formal verification, before publishing scheduled files or schedule JSON.
Every actual domain realization uses its matching selected source. A combined
multi-domain actor view is not treated as a physical module. Only resolved
record outputs select this gate; scalar/input behavior keeps its earlier path.
The private LoweringIR builder can retain unadmitted IR for inventory/refusal
probes; it does not establish public publication admission. Sole writers,
disjoint physical targets and ordinary writes in different states of the same
explicit controller admit. Overlapping independent owners, equal values,
entry guards and priority do not establish compatibility or exclusion.
Generated output mappings stay closed pending separate handoff qualification.

At baseline 0d4bb180, authored record outputs refused; the same source-derived
resolved output prototypes nevertheless let both scheduler APIs publish
competing physical writers. The mandatory gate now refuses those latent P2
publication paths and current actual authored overlaps with precise module,
output and owner reasons. The complete caller JSON remains unchanged on both
success and refusal. No arbitration or implicit reset/value is introduced.

T2033 qualifies actual local/imported/alias/mixed/unused/reverse sources,
independently literal nested signed/four-state layout, exact scalar captures,
source native strict checks, strict direct/domain carriers and scoped refusals.
The same independent probe runs exact baseline Parser/Scheduler objects and
current code, preserving complete source/actor/IR/inventory/products. Literal
counts/types and hostile false publication, owner/output omissions and field
admission falsify broader claims. Full snapshots/receipts, exact Git objects,
immutable prior evidence, this card/tasks/book/feedback and Git provide durability.
Living old blanket-refusal tests now exercise still-closed fields or whole
captures; their original sealed snapshots remain unchanged. Complete public
reconciliation .3.4.4 precedes generated/backend execution .3.5 and field writes
.60.4.3.4. Full aggregate-interface/SPECFORGE feature requests are not complete.
