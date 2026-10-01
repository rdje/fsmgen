---
id: isf-record-input-backend-profiles
title: Record input HDL profiles qualify both Verilog families and precise VHDL refusals
answers:
  - "does VHDL support authored ISF packed record inputs?"
  - "which backend profiles are qualified for ISF record inputs?"
  - "does unsupported record input VHDL generation replace an existing output?"
date: 2026-10-01
status: current
tags: [isf, record, input, vhdl, backend, specforge]
evidence: >-
  t/2027-isf-record-input-backend-profiles.t;
  docs/VHDL_SCOPE.md; docs/book/src/13j-type-enum-aggregate.md;
  docs/isf-spec/02-interface-transactions.md;
  docs/audits/record-input-backend-profiles-20261001/manifest.json;
  docs/knowledge/isf-record-input-direct-runtime.md;
  docs/knowledge/isf-record-input-generated-runtime.md
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/2027-isf-record-input-backend-profiles.t
  t/1420-vhdl-direct-backend-scaffold.t
  t/386-hdl-generator-facade-target-language-boundary-audit.t
  t/114-composition-target-support-diagnostics.t
---

Direct and generated record-input behavior is qualified in both Verilog-family
targets by the separate runtime cards. Selected VHDL profiles refuse precisely:
mixed signed/two-state direct members, supplied typed record inputs and generated
composition shapes. No successful pipeline product or new HDL destination is
published; existing destinations remain byte-exact. Scalar-input and prior
inferred packed-output VHDL controls remain admitted. These bounded refusal/text
controls establish no VHDL analyzer/runtime or broad backend-parity claim.

Re-derivation uses actual native and public pipeline generation with literal
source identities and independently expected declarations/reasons. False-success,
signal and stack-only/missing diagnostic controls provide falsification. Sealed
receipts, exact baseline producer objects, this card, tasks/book/spec and Git
provide durability. Full input signoff and output/consumer delivery remain owned
by the semantic frontier.
