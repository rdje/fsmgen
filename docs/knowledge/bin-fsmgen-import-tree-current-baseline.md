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
date: 2026-08-11
status: current
tags: [bootstrap, architecture, import-tree, bin-fsmgen, semantic-introspection, ial2, ppif, vial]
evidence: docs/BIN_FSMGEN_IMPORT_TREE.md; docs/tasks/STARTUP-INTEGRITY-REPAIR-AUG09.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; bin/fsmgen; perl/FSM/VIAL/ToolCLI.pm; perl/FSM/VIAL/Tool.pm; perl/FSM/VIAL/PlanBuilder.pm; perl/FSM/VIAL/ArtifactTransaction.pm; perl/FSM/VIAL/Backend/SVPortableVerilator.pm; perl/FSM/VIAL/Backend/Runner.pm; perl/FSM/VIAL/Backend/TraceValidator.pm; perl/FSM/VIAL/Backend/ResultProducer.pm; perl/FSM/Support/VIALNativeUVMEmissionContract.pm; perl/FSM/Support/VIALVHDLEmissionContract.pm
reverify: perl -Iperl -MModule::ScanDeps=scan_deps -E 'my $d=scan_deps(files=>["bin/fsmgen"], recurse=>1); my @pm=grep { /(?:^|\/)FSM\/.*\.pm\z/ } keys %$d; say "total=".(scalar(@pm)+1); say "pm=".scalar(@pm); say "support=".scalar(grep { /(?:^|\/)FSM\/Support\// } @pm); say "ial2=".scalar(grep { /(?:^|\/)FSM\/IAL2\// } @pm); say "vial=".scalar(grep { /(?:^|\/)FSM\/VIAL\// } @pm); say "hial=".scalar(grep { /(?:^|\/)FSM\/HIAL\// } @pm);'
---

`docs/BIN_FSMGEN_IMPORT_TREE.md` is the canonical live maintainer-facing
architecture note for the `bin/fsmgen` runtime spine.

As of the 2026-08-11 refresh, the closure is `254` project files: `253`
packages plus `bin/fsmgen`, including `19` IAL2, `17` VIAL, and `3` HIAL
packages. It covers the `.isf` and `.ppif` front doors, shipped protocol-intent
families, HDL backends, semantic/tool support, and repository-local data owner.
Public VIAL runtime owns qualified portable-SystemVerilog emission, exact
Verilator execution, closed-trace validation, and normalized results.
Native-UVM remains review-only. The portable-VHDL contract records exact GHDL
6.0.0/OSVVM 2026.05 private-fixture qualification without making its backend
public or reachable. The canonical note owns inventory, counts, spines, and
hotspots.

README, roadmap, bootstrap, mdBook, task evidence, and executable scans consume
this current runtime-spine map. `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.13`
retains it as live maintainer reference because raw dependency output does not
supply the same architecture view.
