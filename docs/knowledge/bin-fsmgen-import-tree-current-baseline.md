---
id: bin-fsmgen-import-tree-current-baseline
title: Current bin/fsmgen import-tree baseline is recorded in docs/BIN_FSMGEN_IMPORT_TREE.md
answers:
  - "what is the current bin/fsmgen import-tree baseline?"
  - "how many project-owned files does bin/fsmgen currently reach?"
  - "where is the live bin/fsmgen import-tree architecture note?"
  - "is BIN_FSMGEN_IMPORT_TREE.md still needed?"
  - "does bin/fsmgen reach semantic-introspection support?"
  - "does bin/fsmgen reach the AXI manager PPIF implementation?"
  - "does bin/fsmgen reach the APB PPIF implementation?"
  - "does bin/fsmgen reach the portable HDL instance-identifier policy?"
  - "does bin/fsmgen reach public VIAL source tooling?"
  - "does bin/fsmgen reach public VIAL planning artifacts?"
  - "does bin/fsmgen reach public VIAL run and result tooling?"
  - "which VIAL backend packages are reachable from bin/fsmgen?"
  - "does bin/fsmgen reach the shared Verilator lifecycle?"
  - "does bin/fsmgen reach the shared backend-emission authority?"
date: 2026-09-30
status: current
tags: [bootstrap, architecture, import-tree, bin-fsmgen, semantic-introspection, ial2, ppif, vial]
evidence: docs/BIN_FSMGEN_IMPORT_TREE.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; bin/fsmgen; perl/FSM/VIAL/ToolCLI.pm; perl/FSM/VIAL/Tool.pm; perl/FSM/VIAL/PlanBuilder.pm; perl/FSM/VIAL/ArtifactTransaction.pm; perl/FSM/VIAL/Backend/SVPortableVerilator.pm; perl/FSM/VIAL/Backend/Runner.pm; perl/FSM/VIAL/Backend/VerilatorLifecycle.pm; perl/FSM/VIAL/Backend/ProcessSupervisor.pm; perl/FSM/VIAL/Backend/TraceValidator.pm; perl/FSM/VIAL/Backend/ResultProducer.pm; perl/FSM/VIAL/BackendEmissionAuthority.pm; perl/FSM/Support/VIALNativeUVMEmissionContract.pm; perl/FSM/Support/VIALVHDLEmissionContract.pm
reverify: perl -Iperl -MModule::ScanDeps=scan_deps -E 'my $d=scan_deps(files=>["bin/fsmgen"], recurse=>1); my @pm=grep { /(?:^|\/)FSM\/.*\.pm\z/ } keys %$d; say "total=".(scalar(@pm)+1); say "pm=".scalar(@pm); say "support=".scalar(grep { /(?:^|\/)FSM\/Support\// } @pm); say "ial2=".scalar(grep { /(?:^|\/)FSM\/IAL2\// } @pm); say "vial=".scalar(grep { /(?:^|\/)FSM\/VIAL\// } @pm); say "hial=".scalar(grep { /(?:^|\/)FSM\/HIAL\// } @pm);'
---

`docs/BIN_FSMGEN_IMPORT_TREE.md` is the canonical live maintainer-facing
architecture note for the `bin/fsmgen` runtime spine.

As of the 2026-09-06 capture, the closure is `266` project files: `265`
packages plus `bin/fsmgen`, including `19` IAL2, `24` VIAL, and `3` HIAL
packages. It covers the `.isf` and `.ppif` front doors, shipped protocol-intent
families, HDL backends, semantic/tool support, and repository-local data owner.
Public VIAL runtime owns qualified portable-SystemVerilog emission, thin Runner
adaptation over the shared exact Verilator lifecycle and sealed production
process supervisor, closed-trace validation, and normalized results. Reachable
support contracts share exact backend-
emission limits through `BackendEmissionAuthority`.
Native-UVM remains review-only. The portable-VHDL contract records exact GHDL
6.0.0/OSVVM 2026.05 private-fixture qualification without making its backend
public or reachable. The canonical note owns inventory, counts, spines, and
hotspots.

README, roadmap, bootstrap, mdBook, task evidence, and executable scans consume
this current runtime-spine map. `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.13`
retains it as live maintainer reference because raw dependency output does not
supply the same architecture view.

The scoped reset-provenance update on 2026-09-30 adds the shared
`FSM::Support::ISFResetProvenance` projection/discovery helper through ISF
schedule and shared check/semantic source contracts. It preserves the runtime
spine and the dated numerical capture above; see T1978 for native/API/newline
qualification rather than treating that old census as a refreshed closure count.
