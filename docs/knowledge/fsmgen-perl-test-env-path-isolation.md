---
id: fsmgen-perl-test-env-path-isolation
title: Perl focused tests should isolate inherited sibling PERL5LIB
answers:
  - "why run FSMGen Perl tests with env -u PERL5LIB?"
  - "what should I do if t/1437 is SIGTERM before done_testing?"
  - "can sibling PERL5LIB affect FSMGen focused tests?"
  - "how should long AXI manager Perl tests be invoked?"
date: 2026-06-14
status: current
tags: [perl, tests, environment, validation, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t
reverify: rg -n 'env -u PERL5LIB|PERL5LIB|t/1437-axi-ial2-manager-capacity-status-generator|t/1436-ial2-ppif-parser-cli' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/knowledge/fsmgen-perl-test-env-path-isolation.md
---

In this environment, `PERL5LIB` may be inherited from a sibling workspace.
Even with `-Iperl`, long focused FSMGen Perl suites should be run with
`env -u PERL5LIB` so this repository's modules are authoritative.

During `IAL2-FEATURE-COMPLETENESS-FRONTIER.98`, `prove -Iperl -q
t/1437-axi-ial2-manager-capacity-status-generator.t` repeatedly received
SIGTERM before `done_testing` while inherited `PERL5LIB` pointed at a sibling
workspace. The same suite passed cleanly with:

```bash
env -u PERL5LIB prove -Iperl -q t/1437-axi-ial2-manager-capacity-status-generator.t
```

Use the same isolation for the long PPIF/CLI focused suite:

```bash
env -u PERL5LIB prove -Iperl -q t/1436-ial2-ppif-parser-cli.t
```
