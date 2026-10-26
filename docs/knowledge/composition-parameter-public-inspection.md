---
id: composition-parameter-public-inspection
title: Prepared composition environments have optional detached public inspection
answers:
  - "where are composition parameter environment and binding schemas advertised?"
  - "does public parameter environment inspection enable symbolic source planning?"
  - "how do plan snapshots preserve resolved composition parameter environments?"
date: 2026-10-26
status: current
tags: [composition, parameters, schemas, semantic-reports]
evidence: perl/FSM/Support/CompositionParameterContract.pm; t/2127-composition-parameter-public-contract.t
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2127-composition-parameter-public-contract.t
---

The [composition reference](../book/src/05-composition-basics.md) explains the
optional environment paths in prepared normalized reports and plan snapshots.
The shared discovery owner describes exact scoped binding, value, source and
recursive key families without changing source-query or HDL admission.
Use actual Top/Plan/IR producers for provenance; a supplied hash is no proof
of source ownership. Static products omit the environment field.
