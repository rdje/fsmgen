---
id: readme-nearly-static-landing-page-policy
title: README policy is locally authoritative with derived line and byte budgets
answers:
  - "what is the README maintenance policy?"
  - "when should README.md change?"
  - "how is README growth prevented?"
  - "where is the project-neutral reusable README policy?"
  - "what are the README line and byte caps?"
  - "may a harness bootstrap file authorize the README policy?"
  - "is the README policy template an upstream?"
  - "does the README guard run when README.md did not change?"
date: 2026-07-31
status: current
tags: [readme, documentation, doctrine, continuity, onboarding]
evidence: README.md; README_POLICY.md; docs/decisions/0024-readme-is-a-nearly-static-landing-page.md; docs/decisions/0038-readme-policy-is-harness-neutral-and-locally-authoritative.md; scripts/check_readme_entrypoint.sh; scripts/check_doctrines.sh; docs/tasks/README-POLICY-ANVIL-ADOPTION-FEEDBACK.md
reverify: wc -l -c README.md && scripts/check_readme_entrypoint.sh && rg -n 'README_LINE_CAP|README_BYTE_CAP' scripts/check_readme_entrypoint.sh
---

`README.md` is a concise, nearly static GitHub landing page. It changes only
when the project objective, first-use path, top-level architecture, or
canonical navigation changes. Dynamic behavior, status, rationale, facts,
inventories, and history stay in their canonical maintained layers.

FSMGen enforces a maximum of 275 lines and 12,288 bytes, derived from its
reviewed 246-line / 9,952-byte survivor, plus the existing per-leaf chronology
guard through `scripts/check_readme_entrypoint.sh`. The doctrine driver runs
that tree invariant on every commit and CI build, independent of changed paths.

`README_POLICY.md` is the authoritative project-owned copy. Its reusable body
is project- and harness-neutral; local authority is FSMGen maintainers plus the
dated adopting decisions, never a harness bootstrap. The originating template
is not an upstream and is not synchronized automatically. Apparent duplicate
README content is proved against its canonical home before deletion or
relocation, and richer canonical content is retained through one link.
