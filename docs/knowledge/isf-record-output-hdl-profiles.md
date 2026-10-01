---
id: isf-record-output-hdl-profiles
title: Prepared record outputs require precise unsupported HDL profile refusals
answers:
  - "which HDL profiles are prepared for ISF record outputs?"
  - "does the generic record port profile guard preserve input diagnostics?"
  - "does record output backend preparation open source declarations?"
date: 2026-10-01
status: current
tags: [isf, record, output, backend, verilog, vhdl, specforge]
evidence: >-
  docs/audits/record-output-hdl-profiles-20261001/manifest.json;
  t/2032-isf-record-output-hdl-profiles.t;
  t/2028-isf-record-input-verilog-profile.t;
  t/2027-isf-record-input-backend-profiles.t;
  perl/FSM/Support/ISFHDLProfile.pm;
  bin/fsmgen; perl/FSM/Pipeline/HDLGenerator.pm
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/2032-isf-record-output-hdl-profiles.t
  t/2028-isf-record-input-verilog-profile.t
  t/2027-isf-record-input-backend-profiles.t
---

The generic assert_record_port_hdl_profile uses canonical detached declaration
metadata before HDL realization. Prepared record outputs refuse verilog/v and
vhdl with precise actor/output/authored-type/target reasons and SystemVerilog
guidance. The v alias normalizes to the existing verilog diagnostic spelling.
Mixed Verilog interfaces keep the existing first record-input reason. The
legacy assert_record_input_hdl_profile body and input-only contract stay exact.
SystemVerilog/sv are passed through for later source/writer admission; null,
empty and scalar metadata do not fabricate record evidence. Malformed known
layout/order/entries refuse through the canonical metadata validator.

CLI calls the generic guard after target-neutral schedule preview and before
lowering/publication, retaining its normal failure handler. The public facade
calls it after parse and before lowering. Actual record-input machine failures,
precise VHDL backend refusals, scalar/storage controls and destination handling
are preserved. No blanket VHDL record-input refusal is introduced; its existing
shape-specific backend boundaries remain. Previously supported inferred packed
output VHDL fixtures retain their text controls.

T2032 and the full probe use actual parsed storage declarations projected into
private output roles, including local/imported/alias/mixed/unused nested facts.
Independently literal layout and exact old/new reasons plus malformed metadata
and first-touch JSON falsify inferred profile admission. The exact baseline
module runs the same probe/test; full sources/actors/metadata/receipts, sealed
baseline objects and hostile verifier, task/book/feedback and Git provide
durability. Unstated scalar state models remain absent rather than being
invented as two-state facts. Source syntax is still closed during this unit;
actual output native/API/machine atomic checks follow declaration integration
under SEM .60.4.3.3.4.3-.4. Generated/field/runtime promotion remains separate.
