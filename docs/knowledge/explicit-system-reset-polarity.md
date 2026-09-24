---
id: explicit-system-reset-polarity
title: Explicit FSM reset polarity preserves timing and level through semantics and HDL
answers:
  - "does sreset support active_low reset polarity?"
  - "does areset support active_high reset polarity?"
  - "how do agents discover and inspect explicit reset polarity over MCP?"
  - "what defaults and strict checks apply when reset polarity is omitted?"
  - "does the explicit FSM reset carrier fix ISF lowering automatically?"
date: 2026-09-24
status: current
tags: [fsm, reset, polarity, semantics, mcp, systemverilog, verilog, vhdl]
evidence: docs/decisions/0106-reset-polarity-is-an-explicit-system-carrier.md; docs/book/src/03-decision-trees-and-fsms.md; t/1891-explicit-system-reset-polarity.t; t/1892-explicit-reset-hdl-behavior.t; docs/audits/specforge-rule-admission-20260924/reset-polarity-carrier.json
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1891-explicit-system-reset-polarity.t t/1892-explicit-reset-hdl-behavior.t
---

Canonical `sreset` and `areset` accept an optional literal `active_high` or
`active_low`. The keyword selects synchronous/asynchronous timing; the
modifier selects polarity independently of naming. Without a modifier, the
existing synchronous-high/asynchronous-low defaults and strict naming checks
remain. Extended `asreset`, invalid literals, nested polarity forms and extra
operands fail closed. Invalid polarity has stable diagnostic code
`FSMGEN_LANGUAGE_SYSTEM_RESET_POLARITY`.

The explicit/effective public system contract keeps its existing field shape.
`reset_kind` and `reset_active_level` retain authored intent. Language-surface
capabilities publish `system_contracts.explicit_reset_polarity_forms`; native
reports, the public adapter API and actual newline MCP have complete success
and failure equality in T1891.

T1892 independently drives nonzero reset values, clocked updates and reset
pulses wholly between clock edges for every kind/polarity combination in
SystemVerilog, Verilog and VHDL. Hardware qualification requires real tools,
not a skipped provider: on Darwin set `FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1`
only for the qualified provider; set `FSMGEN_RESET_GHDL` to the project-local
GHDL executable when it is absent from PATH. The captured receipt records the
actual providers and non-skipped outcomes.

This carrier is owned by `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.2.1`.
ISF emission still needs its separately owned `.32.1.3.2.2` repair; accepting
the FSM modifier alone does not fix a domain/CDC reset contradiction.
