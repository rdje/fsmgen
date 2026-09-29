---
id: explicit-system-reset-polarity
title: Explicit FSM reset polarity preserves timing and level through semantics and HDL
answers:
  - "does sreset support active_low reset polarity?"
  - "does areset support active_high reset polarity?"
  - "how do agents discover and inspect explicit reset polarity over MCP?"
  - "what defaults and strict checks apply when reset polarity is omitted?"
  - "does ISF lowering preserve synchronous active-low and asynchronous active-high reset?"
  - "why do generated domain resets agree with CDC metadata?"
  - "why did T1974 fail its reset check at time 311?"
  - "does omitted ISF reset mean the specification leaves reset unspecified?"
date: 2026-09-30
status: current
tags: [fsm, isf, reset, polarity, semantics, mcp, systemverilog, verilog, vhdl]
evidence: docs/decisions/0106-reset-polarity-is-an-explicit-system-carrier.md; docs/book/src/03-decision-trees-and-fsms.md; t/1891-explicit-system-reset-polarity.t; t/1892-explicit-reset-hdl-behavior.t; docs/audits/specforge-rule-admission-20260924/reset-polarity-carrier.json; docs/audits/specforge-rule-admission-20260924/isf-reset-polarity.json; t/1893-isf-reset-polarity-lowering.t; t/1894-isf-domain-reset-event-behavior.t
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1891-explicit-system-reset-polarity.t t/1892-explicit-reset-hdl-behavior.t t/1893-isf-reset-polarity-lowering.t t/1894-isf-domain-reset-event-behavior.t
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

T1892 independently drives direct FSM and ordinary ISF nonzero reset values, clocked updates and reset
pulses wholly between clock edges for every kind/polarity combination in
SystemVerilog, Verilog and VHDL. Hardware qualification requires real tools,
not a skipped provider: on Darwin set `FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1`
only for the qualified provider; set `FSMGEN_RESET_GHDL` to the project-local
GHDL executable when it is absent from PATH. The captured receipt records the
actual providers and non-skipped outcomes.

This carrier is owned by `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.2.1`.
The subsequent `.32.1.3.2.2` repair makes ISF emission use that carrier whenever
keyword defaults or strict FSM naming would lose the parsed policy. Existing
strict-supported spellings remain stable. Flat ISF `_n`/`_b` inference is
case-sensitive and differs from FSM's final-n strict convention; emission
preserves ISF intent rather than reinterpreting the identifier.

T1893 qualifies ordinary parsed/lowered policy and complete public queries;
T1890 covers original and explicit-policy domain fixtures through native/API/
newline MCP. T1894 drives real events around source-only, destination-only and
joint resets on the original topology for each timing/level combination.
The preserved baseline HDL fails both independent reset-value and event
oracles; repaired HDL passes the identical oracles. Capture boundaries,
producer hashes and unchanged control HDL are retained in the ISF audit.
No generated-top VHDL support, reset-tree glue or broader activation-runtime
qualification is implied.


T1974's flat `(reset rst_n)` selects synchronous active-low reset. Its original
mid-run bench asserted reset at a falling edge and checked one time unit later,
before any reset-active rising edge. The actual failure at time 311 is therefore
a test-oracle error, not evidence of a production reset defect. The correction
waits through a rising edge before checking and releasing reset. Parsed/carrier
expectations and an independent saved event-order model qualify the static fix.
The subsequent observed T1974 passes both HDL targets, repeated requests and
reset with unchanged production code; the complete result is retained in
`docs/audits/priority-runtime-qualified-20260928/`. Inspect the original failed
observation and public metadata/HDL witness with
`python3 -B docs/audits/priority-reset-oracle-20260928/verify.py`.

The SPECFORGE unstated-reset baseline confirms legacy omission and explicit
async-low `rst_n` have identical public reports apart from source paths.
`explicit_system_contract` is explicit in the lowered FSM, not proof of authored
ISF reset provenance. A standalone clock-only named domain emits no reset,
state initializer or initial block in either Verilog target; it supplies no
guaranteed initial state. It is not a deferred implementation reset choice.
Reverify saved identities, complete contracts and HDL structure with
`python3 -B docs/audits/specforge-unstated-reset-20260930/verify.py`; replay native,
API and actual newline queries plus HDL emission with its `capture.t` under
the RAM guard. No native runtime executes in that audit. Missing reset-source
provenance and the downstream answer remain owned by SEM `.60.3.2` onward.
