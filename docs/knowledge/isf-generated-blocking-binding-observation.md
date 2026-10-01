---
id: isf-generated-blocking-binding-observation
title: Generated blocking result bindings are valid during child completion
answers:
  - "when is a generated blocking output binding valid?"
  - "why did corrected generated record-input runtime fail the blocking copy check?"
  - "which generated record-input runtime cases have actually passed?"
date: 2026-10-01
status: current
tags: [isf, composition, record-ports, runtime, verification]
evidence: docs/audits/record-input-generated-observation-corrected-20261001/manifest.json; docs/audits/record-input-generated-observation-corrected-20261001/diagnosis.json; docs/book/src/13f-composition.md; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- python3 docs/audits/record-input-generated-observation-corrected-20261001/verify.py
---

Spent generated_input_fixed_oct01 uses committed typed-carrier repair. The
named-domain source compiles and passes complete selected public-pin behavior
in both Verilog families. Ordinary blocking SystemVerilog compiles, then fails
its first late whole-copy predicate. Remaining blocking and unsigned runtime
cases do not execute; the full target is not PASS.

Actual public schedule reports the copier result binding as done_guarded.
Actual emitted carrier uses a combinational assignment guarded by child done;
HDL defaults copy_seen to zero outside that completion pulse. Parent phase 2,
reader work and parent done follow child completion. The old bench incorrectly
requires nonzero copied data in copy_seen at that later parent done and idle.
The published composition contract agrees with the emitted behavior. This is
a P2 test timing error, owned for immediate correction by SEM
.60.4.3.2.5.4.3.3.2. Correct observation must check the bound result in its
completion window and independently check held packed storage later. A binding
does not provide implicit retained storage.

The late-zero explanation derives from actual source/carrier/HDL; individual
failed component pin values were not captured. Other blocking fields remain
unqualified. Complete partial receipts preserve source/producer identities,
original bounds/results/arguments and cleanup. Native events/gaps are empty;
historical EPERM is unattributed. Successful-child PID absence is not measured.

Original receipts and actual unchanged public products re-derive this finding.
Hostile saved mutations and the independently literal completion-value versus
late-zero counterexample provide falsification. The sealed archive, published
contract, source Git blobs, scheduled repair, task/book/response and Git provide
durability. Saved reverify executes no HDL. Never replay either spent generated
capture; complete corrected runtime requires fresh committed authority.
