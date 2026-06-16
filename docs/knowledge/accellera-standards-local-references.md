---
id: accellera-standards-local-references
title: Accellera standards PDFs are tracked as local reference artifacts
answers:
  - "where are the tracked Accellera standards PDFs?"
  - "where is the local SystemRDL reference?"
  - "where is the local PSS reference?"
  - "where are the local UVM reference PDFs?"
  - "are Accellera standards imported as shipped behavior?"
date: 2026-06-16
status: current
tags: [accellera, systemrdl, pss, uvm, pdf, standards, reference-artifacts]
evidence: docs/tasks/ACCELLERA-STANDARDS-LOCAL-REFERENCE-IMPORT.md; README.md; docs/book/src/14-feature-backlog.md; docs/book/src/90-reference-map.md
reverify: find docs/vendor/accellera -type f | sort
---

The provided Accellera standards PDFs are tracked locally as raw reference
artifacts under `docs/vendor/accellera/`:

- `docs/vendor/accellera/systemrdl/SystemRDL_2.0_Jan2018.pdf`
- `docs/vendor/accellera/pss/Portable_Test_Stimulus_Standard_v3.0.pdf`
- `docs/vendor/accellera/uvm/UVM_Class_Reference_Manual_1.2.pdf`
- `docs/vendor/accellera/uvm/uvm_users_guide_1.2.pdf`

These files are evidence/reference inputs for future task-tree-owned probes.
They do not ship SystemRDL, PSS, UVM, PDF extraction, parser, lowering,
scheduler, or HDL behavior by themselves.
