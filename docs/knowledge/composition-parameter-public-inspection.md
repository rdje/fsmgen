---
id: composition-parameter-public-inspection
title: Prepared composition environments have optional detached public inspection
answers:
  - "where are composition parameter environment and binding schemas advertised?"
  - "does public parameter environment inspection enable symbolic source planning?"
  - "how do plan snapshots preserve resolved composition parameter environments?"
  - "where is child generic declaration type evidence retained?"
date: 2026-10-26
status: current
tags: [composition, parameters, schemas, semantic-reports]
evidence: perl/FSM/Support/CompositionParameterContract.pm; t/2127-composition-parameter-public-contract.t
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2127-composition-parameter-public-contract.t t/2137-composition-child-declaration-evidence.t
---

[Composition Basics](../book/src/05-composition-basics.md) owns optional
schemas, detached Plan snapshots and pending source/VHDL boundaries. Overrides
retain child default text/payload/type/source apart from actual caches (T2137).
Only actual Top/Plan/IR establish provenance; static products omit environments.
