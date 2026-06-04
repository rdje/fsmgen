---
id: full-test-suite-invocation
title: How to run the full Perl test suite (and why -j6 can get OOM-killed)
answers:
  - "how do I run the full test suite?"
  - "what is the command to run all the Perl tests?"
  - "why did prove exit with code 137?"
  - "the test suite got killed / SIGKILL during prove"
  - "how long does the full suite take?"
date: 2026-06-03
status: current
tags: [testing, workflow, operations]
evidence: t/ (~1400+ .t files); .github/workflows/regression.yml; bin/ci-regression
reverify: prove -j4 -Iperl t/
---

Run the whole suite from the repo root with:

    prove -j4 -Iperl t/

It is ~1400+ test files and takes roughly ~4 minutes wall-clock. **Gotcha:**
`prove -j6` can be **OOM-killed on this machine — the process exits 137**
(128 + SIGKILL), which looks like a failure but is memory pressure, not a real
test failure. Prefer **`-j4`** for the full run; reserve `-j6` for partial runs.
For the ISF lane specifically, `./bin/ci-regression isf --no-book` is the faster
focused gate. Do **not** edit files under `t/` or `perl/` while a background
suite is reading them.
