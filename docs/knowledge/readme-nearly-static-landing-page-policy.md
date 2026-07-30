---
id: readme-nearly-static-landing-page-policy
title: README is a nearly static landing page with line and byte budgets
answers:
  - "what is the README maintenance policy?"
  - "when should README.md change?"
  - "how is README growth prevented?"
  - "where is the project-neutral reusable README policy?"
  - "what are the README line and byte caps?"
date: 2026-07-30
status: current
tags: [readme, documentation, doctrine, continuity, onboarding]
evidence: README.md; README_POLICY.md; docs/decisions/0024-readme-is-a-nearly-static-landing-page.md; scripts/check_readme_entrypoint.sh; docs/tasks/README-STATIC-LANDING-PAGE.md
reverify: wc -l -c README.md && scripts/check_readme_entrypoint.sh && rg -n 'README_LINE_CAP|README_BYTE_CAP' scripts/check_readme_entrypoint.sh
---

`README.md` is a concise, nearly static GitHub landing page. It changes only
when the project objective, first-use path, top-level architecture, or
canonical navigation changes. Dynamic behavior, status, rationale, facts,
inventories, and history stay in their canonical maintained layers.

FSMGen enforces a maximum of 300 lines and 16,384 bytes, plus the existing
per-leaf chronology guard, through `scripts/check_readme_entrypoint.sh`.
`README_POLICY.md` is the small project-neutral standard intended for reuse
in other repositories.
