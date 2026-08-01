---
id: vhdl-package-emission
title: VHDL package declarations and package-backed composition are explicit capabilities
answers:
  - "does ?pkg generate HDL directly?"
  - "do package roots generate HDL directly?"
  - "can package roots generate VHDL packages?"
  - "does FSMGen emit VHDL packages?"
  - "does VHDL package declaration/emission ship?"
date: 2026-08-01
status: current
tags: [vhdl, backend, packages, composition]
evidence: >-
  docs/VHDL_SCOPE.md; docs/book/src/14l-backends-validation-and-apis.md;
  docs/book/src/10-errors-strict-mode-and-troubleshooting.md;
  docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: >-
  prove -Iperl t/1420-vhdl-direct-backend-scaffold.t
  t/386-hdl-generator-facade-target-language-boundary-audit.t
  t/114-composition-target-support-diagnostics.t t/313-hdl-external-validation-contract.t
---

Package-root and package-backed composition behavior is independent from the direct-FSM scaffold. Its current contract and examples live in `docs/VHDL_SCOPE.md` and the mdBook.

Exact pre-containment combined prose is retrievable with `git show aadbd14a5:docs/knowledge/direct-vhdl-scaffold.md`.
