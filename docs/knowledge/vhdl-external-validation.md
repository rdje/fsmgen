---
id: vhdl-external-validation
title: GHDL is the external validation authority for generated VHDL
answers:
  - "is GHDL validation active?"
date: 2026-08-01
status: current
tags: [vhdl, ghdl, validation, backend]
evidence: >-
  docs/VHDL_SCOPE.md; docs/book/src/14l-backends-validation-and-apis.md;
  docs/book/src/10-errors-strict-mode-and-troubleshooting.md;
  docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: >-
  prove -Iperl t/1420-vhdl-direct-backend-scaffold.t
  t/386-hdl-generator-facade-target-language-boundary-audit.t
  t/114-composition-target-support-diagnostics.t t/313-hdl-external-validation-contract.t
---

Generated VHDL validation is routed through the repository's external HDL validation contract. GHDL availability and validation evidence are reported explicitly rather than inferred from generation success.

Exact pre-containment combined prose is retrievable with `git show aadbd14a5:docs/knowledge/direct-vhdl-scaffold.md`.
