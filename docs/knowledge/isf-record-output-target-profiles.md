---
id: isf-record-output-target-profiles
title: Actual authored record output target profiles preserve atomic failure products
answers:
  - "which actual record output HDL target profiles are qualified?"
  - "do record output profile failures preserve existing and absent destinations?"
  - "which diagnostic wins for mixed record input and output target profiles?"
  - "can the HDL facade result be captured as raw complete JSON?"
date: 2026-10-01
status: current
tags: [isf, record, output, profile, facade, verilog, vhdl, specforge]
evidence: >-
  docs/audits/record-output-target-profiles-20261001/manifest.json;
  t/2035-isf-record-output-target-profiles.t;
  t/2028-isf-record-input-verilog-profile.t;
  t/2027-isf-record-input-backend-profiles.t;
  t/2032-isf-record-output-hdl-profiles.t;
  perl/FSM/Support/ISFHDLProfile.pm; perl/FSM/Pipeline/HDLGenerator.pm;
  docs/book/src/13j-type-enum-aggregate.md
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/2035-isf-record-output-target-profiles.t
  t/2032-isf-record-output-hdl-profiles.t
---

Actual local/imported/aliased/mixed/unused record output sources refuse verilog/v
and vhdl before HDL publication. Primary messages name actor, role, authored type
and canonical target and recommend SystemVerilog. The v alias uses verilog spelling.
Mixed Verilog retains the existing first record-input diagnostic. Mixed VHDL uses
the output guard before older shape-specific input backend refusals.

Native generation failures have exit 1 without signal or stdout HDL; existing
destination bytes remain exact and absent outputs stay uncreated. The public HDL
facade returns no partial product with the same primary reason. Complete native
check/semantic failures retain JSON false, nullable diagnostic code and no successful
declaration/semantic snapshot. Target-neutral schedules stay successful for every
unsupported target with literal nested six-bit signed/four-state output metadata.

SystemVerilog/sv native generation produces complete equal HDL apart from date
banners. Facade generation retains complete HDL text and public source metadata,
with actual endpoint, signed three-bit data and authored source/entry identity.
The facade is a typed Perl API: raw whole-result JSON correctly rejects its
CoreAST module. Captured evidence therefore includes complete hdl_code/source_info
and the complete result-key inventory, with typed AST serialization/equality
explicitly outside this slice. No allow_blessed/null erasure substitutes for it.

Actual source/generation/machine/schedule and atomic-destination products re-derive
these facts. Literal layouts/messages/types, immutable source bytes and hostile
success/signal/secondary cause/destination/partial metadata/signedness/priority
controls provide falsification. Full source/HDL/product/TAP snapshots, exact
unchanged producer objects and earlier archive members, authenticated restoration
of the accidentally reused scratch logs, sealed verifier and task/book/feedback/Git
provide durability. Existing input profiles, scalar/inferred packed controls,
facade aliases and generic profile contracts remain qualified. No HDL tool runs.
Exact complete predecessor comparisons and maintained corpus closure remain
.3.4.4.3-.4, then generated output/execution and field writers. Full SPECFORGE
aggregate delivery and the duration/timer implementations remain unfinished.
