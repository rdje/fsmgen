---
id: isf-record-output-writer-ingress
title: Record output admission requires imported writer tokens and closed physical ownership
answers:
  - "what blocks record output whole-copy admission?"
  - "does the physical write collector accept imported type tokens?"
  - "can empty conflict issues prove record output writer safety?"
  - "where are detached record output writers inventoried?"
date: 2026-10-01
status: current
tags: [isf, record, output, writers, imports, ownership]
evidence: >-
  docs/audits/record-output-writer-inventory-20261001/manifest.json;
  perl/FSM/Scheduler/ISF/RecordOutputWriters.pm;
  t/2029-isf-record-output-writer-inventory.t;
  docs/audits/physical-write-import-types-20261001/manifest.json;
  docs/audits/record-output-ingress-20261001/manifest.json;
  docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md;
  perl/FSM/Scheduler/ISF/PhysicalWriteDeclarations.pm;
  perl/FSM/Scheduler/ISF/PhysicalWriteTargets.pm;
  perl/FSM/Scheduler/ISF/SourceWriterOwners.pm;
  docs/decisions/current/language-api/0113-isf-record-interface-ports-reuse-packed-type-and-writer-contracts.md
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/2029-isf-record-output-writer-inventory.t
  t/1968-isf-physical-write-declarations.t
  t/1967-isf-physical-write-targets.t
  t/1969-isf-implicit-write-targets.t
---

At selected input signoff, authored local/imported record outputs still refuse.
Existing resolved role/type/copy helpers include outputs, but source contexts are
called under an input-only gate. Output-only admission must wire mandatory
context/domain/profile checks and closed physical writer ownership first.

Actual imported input/storage carriers preserve `shared.frame` and strictly
replay. At ingress selection, PhysicalWriteDeclarations rejected that valid token because
its grammar allowed only bare identifiers; an equivalent local alias passed.
The defect originates in `1933c4f1`. SEM `.60.4.3.3.2` repairs the type-token
grammar to match the existing single package qualifier, retaining bare
signal/module identities and conservative unresolved-width contracts. Actual
direct/generated/domain record and imported scalar controls pass with emitted
token parity and strict replay. The collector remains preparatory; record
output source stays closed until its writer gate qualifies.

An actual scalar sibling control has different writes to one full packed root,
explicit distinct source owners and empty conflict issues. That existing broad
writer baseline remains separately owned. The record-output gate must inventory
realized module/root/range and source owners after handoffs; an empty report is
not a compatibility or exclusion proof. Whole/member overlaps cannot be resolved
by string equality. No arbitration is invented. Port alias/width facts alone do
not provide a resolved member layout; output-field range admission remains its
own subsequent lane.

Actual parser/IR/emitter/core replay and independent packed-target tests re-derive
the boundary. Alias-equivalent success and hostile false import repair, output
admission and omitted competing assignments falsify unsafe interpretations.
Sealed receipts, baseline Git objects, selected task children and this card provide
durability. Closed writer preparation, source admission and generated/public/native
qualification remain `.3.3`–`.3.5`; native execution requires fresh HIAL admission.

RecordOutputWriters::inventory now joins matching resolved actor declarations
and actual module ports on private clones before collecting packed targets,
explicit source owners and per-assignment activation. Emitted output ports
retain alias/width but lack recursive layouts; matching source facts enrich
only the detached copy. It retains every actual state/rule/drive output write,
including repeated and competing owners, without deciding compatibility.
Actual domain realization is supported; pre-partition views and generated
child mappings refuse. T2029 independently qualifies nested local/imported
layouts, whole/member ranges, same-value competing owners, scalar shadows,
omitted/mismatched facts and first-touch complete caller JSON. The source
prototype starts from admitted scalar output syntax and resolved storage types;
it does not constitute authored record-output support. Conservative admission
remains SEM `.60.4.3.3.3.2`, before source widening.
