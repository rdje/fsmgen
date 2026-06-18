---
id: generated-hdl-artifact-placement
title: Implicit generated HDL is written under hidden git-ignored artifact directories
answers:
  - "where does fsmgen write generated HDL by default?"
  - "does fsmgen leave generated sv or vhd files in the repo root by default?"
  - "where are implicit SystemVerilog outputs written?"
  - "where are implicit VHDL outputs written?"
  - "does --output still preserve the exact generated HDL destination?"
date: 2026-06-18
status: current
tags: [cli, artifacts, generated-hdl, systemverilog, vhdl, gitignore]
evidence: bin/fsmgen; .gitignore; t/1463-cli-generated-hdl-artifact-placement.t; README.md; docs/book/src/01-first-fsm.md; docs/book/src/09-generated-hdl-debugging-and-inspection.md; docs/tasks/GENERATED-HDL-ARTIFACT-PLACEMENT.md; docs/TASK_TREE.md
reverify: rg -n 'default_hdl_artifact_dir|\\.artifacts/<language>|GENERATED-HDL-ARTIFACT-PLACEMENT|cli-generated-hdl-artifact-placement|implicit generated' bin/fsmgen .gitignore t/1463-cli-generated-hdl-artifact-placement.t README.md docs/book/src/01-first-fsm.md docs/book/src/09-generated-hdl-debugging-and-inspection.md docs/tasks/GENERATED-HDL-ARTIFACT-PLACEMENT.md docs/TASK_TREE.md
---

When `--output` / `-o` is omitted, FSMGen writes generated HDL under hidden,
git-ignored artifact directories instead of the current working directory root.

The default directories are:

- `.artifacts/sv/` for SystemVerilog (`systemverilog` / `sv`)
- `.artifacts/vhd/` for VHDL (`vhdl`)
- `.artifacts/v/` for Verilog (`verilog` / `v`)

Explicit `--output` paths bypass the default artifact directory and are honored
exactly as provided.
