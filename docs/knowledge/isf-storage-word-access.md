---
id: isf-storage-word-access
title: Storage words carry independent checked access metadata without RTL policy
answers:
  - "can an ISF storage register state its own access?"
  - "does word access inherit into storage fields?"
  - "does access ro prevent an authored ISF write?"
  - "where is storage word access reported?"
  - "do multi-domain schedule reports expose storage details?"
  - "why is scalar access metadata independent of controller repair?"
date: 2026-10-01
status: current
tags: [isf, storage, register, access, metadata, specforge, mcp]
evidence: t/1982-isf-domain-storage-report.t; docs/audits/domain-storage-report-20260930/manifest.json; t/1981-isf-storage-word-access.t; docs/audits/storage-word-access-20260930/manifest.json; perl/FSM/Adapter/ISF/Parser.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Scheduler/ISF/Emitter/JSON.pm; perl/FSM/Support/ISFPublicInterfaceContract.pm; docs/decisions/0109-direct-transactions-have-independent-logical-controllers.md
reverify: scripts/run_with_ram_guard.sh prove -Iperl -It/lib t/1982-isf-domain-storage-report.t t/1981-isf-storage-word-access.t t/1453-isf-storage-field-metadata.t
---

Width-based scalar `var` and `variable` entries accept `(access TOKEN)` using
the same lowercase vocabulary as fields: `ro`, `rw`, `wo`, `w1c`, `w0c`, `rc`,
`rs`, `warl`, `wpri`, `reserved`. Word and field facts are independent; absent
metadata stays absent and differing values are permitted. Banks and typed
storage remain refused, as do malformed/duplicate options and unknown tokens.
Unknown-token diagnostics name the word and actual token.

Parser retains the validated scalar fact; LoweringIR's declared-storage clone
carries it to JSON `inferred_storage[].access`. It is not consumed by the FSM
emitter or hardware policy. The public contract advertises the optional key and
its meaning; native/API/newline schedule reports agree. Check and semantic
queries validate the source, while the metadata payload is schedule-owned.
`isf/storage_word_access.isf` is support-accounted as
`feature.isf_storage_word_access`.

T1981 preserves complete pre-change public reports and actual FSM/HDL controls,
allowing only authored word access and source relocation. It separately checks
tokens, field independence, refusal causes, domain-source selection and
capability discovery. The initial red run reproduces the missing parser option;
the candidate's first failure was an incorrect assumption that public domain
summaries already carried storage details. SEM `.38.3` repairs that projection:
`clock_domains[].inferred_storage[]` now uses the same normalized storage schema,
while original `storage` names and the generated top's empty detail array stay
unchanged. T1982 independently checks owned words/fields, typed storage,
scalarized banks, watchdogs, empty domains and detached nested metadata, with
complete native/API/newline and pre-change FSM/HDL compatibility controls.
Private pre-realization summaries use null for unavailable details; actual
realized empty domains have empty arrays. Named single domains reuse their
module storage details without changing existing domain counts. This adds no child-report flattening
or hardware behavior.

Current prior-product qualification under SEM .60.4.3.2.4.2.3.1 upgrades those
value comparisons to complete serialized JSON-kind equality. Source relocation
preserves decoded numeric/string/boolean/null kinds through later copies; only
actual path changes produce replacement strings. Independently decoded literals,
fixed report/carrier/HDL controls and exact named public producer plus immutable
source/baseline bytes qualify the current oracle. Historical receipts retain
their dated value/copy-stability limits. Complete generated-input catalog witness
closure remains separately owned; no runtime result is inferred.

Passive metadata does not depend on independent-controller execution. Decision
0109's former blanket sequence is narrowed under SEM `.38.1`; unchanged emitted
hardware is the evidence for that separation. Existing execution and historical
native-containment defects stay owned. No native simulation is needed to claim
byte-preserved hardware, and none was run by this slice.
