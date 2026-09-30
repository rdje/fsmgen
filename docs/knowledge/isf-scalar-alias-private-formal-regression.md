---
id: isf-scalar-alias-private-formal-regression
title: Scalar alias regression uses scoped private transaction formal carriers
answers:
  - "why did the scalar type alias regression expect wrong transaction carrier names?"
  - "which project inputs does an isolated historical scalar alias test need?"
date: 2026-10-01
status: current
tags: [isf, types, formal-identity, testing]
evidence: t/1257-isf-scalar-type-aliases.t; perl/FSM/Scheduler/ISF/FormalIdentityPlan.pm; specs/pplugin.spec; scripts/project_data_locality_env.sh; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/1257-isf-scalar-type-aliases.t
---

T1257 formerly expected raw `done_flag` and `payload` names in the scalar alias
`+size` artifact. Formal identity planning instead publishes private
`isf_port_main_done_flag` and `isf_port_main_payload` carriers in that fixture.
The scoped plan originated in 32642d54c4763a78e916f65c1c019e64bb99d0d4.
The corrected literal oracle still requires the original actor port/storage
aliases and both formal type aliases; it changes only the carrier names.

An isolated exact d9a40e4913c9636b561c20ce542875e25377ca6c source capsule
reproduces that stale regex failure before the imported-alias repair. Its
package-backed HDL generation and refusal controls pass. This is a source and
emission qualification, not HDL simulation.

That T1257 capsule needs this project's committed `bin`, `perl`, `specs` and
`plugin` trees, its test, README and locality environment helper. Missing owned
spec inputs abort parsing. Source the capsule's `scripts/project_data_locality_env.sh`
before running it: inherited main-repository temporary paths correctly fail the
capsule CLI's output-root restriction. These setup failures are not baseline proof.
The capsule contains no foreign checkout, Git metadata or submodule implementation.

Actual current test/carrier inspection supplies re-derivation; the independently
exported clean predecessor and literal stale-name failure supply falsification;
tracked planner/test, exact Git revision, this fact and the owning task retain
durability. This finite recipe does not qualify arbitrary historical capsules.
