---
id: vial-foundation-tooling-claim-evidence
title: VIAL foundation and tooling claims have distinct executable evidence
answers:
  - "how are the first eight Chapter 16d claims verified?"
  - "how is exact VIAL source identity verified?"
  - "how is directional known-value injection verified?"
  - "how is HIAL VIAL bridge source identity verified?"
  - "how is the 27-key HIAL VIAL bridge manifest verified?"
  - "how are checked AHB ExecutionIR counts verified?"
  - "how is the portable Verilator profile verified?"
  - "why are VIAL .10 leaf numbers not capability claims?"
  - "is the proposed IASIM Perl 5 route shipped?"
date: 2026-08-21
status: current
tags: [claim-verification, vial, hial, semantic-ir, execution-ir, bridge, tooling, verilator, iasim, evidence]
evidence: >-
  doctrine/claim_verification/inventory.jsonl;
  doctrine/claim_verification/dispositions.jsonl;
  vial/ahb_subordinate_base_output_arbitration.vial;
  perl/FSM/VIAL/Parser.pm;
  perl/FSM/VIAL/SemanticBuilder.pm;
  perl/FSM/VIAL/ExecutionBuilder.pm;
  perl/FSM/Support/VIALExecutionContract.pm;
  perl/FSM/HIAL/VIALBridge/Builder.pm;
  perl/FSM/HIAL/VIALBridge/Manifest.pm;
  perl/FSM/HIAL/VIALBridge/Report.pm;
  perl/FSM/VIAL/Backend/Runner.pm;
  perl/FSM/VIAL/Backend/SVPortableVerilator.pm;
  t/1550-vial-semantic-ir.t;
  t/1551-hial-vial-bridge-manifest.t;
  t/1552-vial-execution-ir.t;
  t/1555-vial-public-source-tooling.t;
  t/1556-vial-public-planning-artifacts.t;
  t/1557-vial-portable-sv-backend-emission.t;
  t/1558-vial-verilator-run-integration.t;
  t/1601-vial-architecture-scale-semantic-catalog.t;
  t/1638-claim-verification-dispositions.t;
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md
reverify: >-
  scripts/check_claim_verification_dispositions.pl --report &&
  scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 --
  prove -Iperl t/1550-vial-semantic-ir.t
  t/1551-hial-vial-bridge-manifest.t t/1552-vial-execution-ir.t
  t/1555-vial-public-source-tooling.t
  t/1556-vial-public-planning-artifacts.t
  t/1557-vial-portable-sv-backend-emission.t
  t/1558-vial-verilator-run-integration.t &&
  prove -Iperl t/1601-vial-architecture-scale-semantic-catalog.t &&
  prove -Iperl t/1638-claim-verification-dispositions.t
  t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

`CLAIM-VERIFICATION-ADOPTION.5.6.1` reviews the exact eight inventory
candidates on `docs/book/src/16d-hial-vial-verification-architecture.md`
lines 1 through 931. Six candidates state current behavior and use derived
gates. Two are structural roadmap references and use reviewed-incidental
dispositions.

The six current claims retain separate evidence chains:

- the tracked VIAL source, parser, semantic builder, and semantic-scale oracle
  reproduce the canonical 4,986-byte, 123-line, SHA-256 source identity and
  reject an altered anchor;
- the execution contract and execution oracle admit
  `known_value_injection_v1` only for same-width/signed two-state drives into
  four-state carriers and reject the reverse four-state-to-two-state sample;
- the bridge builder verifies basename, SHA-256, bytes, lines, path, and null
  virtual-path identity rather than trusting caller labels;
- the bridge manifest/report oracle requires the closed 27-key projection and
  retains null transaction `type_id` for the scalar-only first profile;
- the execution builder and its focused oracles reproduce 21 static
  operations, four total fibers, and three maximum simultaneously live
  fibers for the checked AHB source; and
- portable-SystemVerilog emission and runner oracles preserve the selected
  Verilator 5.046 tool profile and repository-local object path while keeping
  emission-only data distinct from qualified execution evidence.

The RAM-guarded seven-file foundation/tooling collection passes at `Files=7,
Tests=50`; the independent semantic-scale source-identity oracle passes at
`Files=1, Tests=4`. The support/disposition collection passes at `Files=3,
Tests=7107`. The current registry therefore closes the first 8 of 288
verification-architecture candidates as six gates plus two reviewed outcomes.

The two reviewed records do not create capability claims. The `.10.1` through
`.10.4` leaf numbers are immutable task chronology describing how public
source, plan, emission, and run tooling landed. The IASIM Perl 5 statement is
a proposed definition-oriented reference route owned by the inactive
`IASIM-EXECUTABLE-REFERENCE-SEMANTICS` tree; it is not shipped or active.

Key durable commits are `be9c741630660b817353f219eb71e11c4aafacaa`
(semantic source), `2a1b3cefc08e2b89fec7043e40bd24b1bbd06319`
(directional binding), `51434a2ae489a2e918b9d53fd1c38aa0159eef5a`
(bridge contract), `44dbecd1abbabf0b777f187b669c9917927f6e2c`
(execution elaboration), `dfe87f536ab4c86824e85260e9c1b46aebbe7ec3`
(public tooling chronology), `201590d84772f72e699c26f90f350ff7627bc9ba`
(portable backend), and `1bcd979d00ca195a82b748d5e68924e553939474`
(IASIM proposal).
