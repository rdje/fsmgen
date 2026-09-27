---
id: isf-storage-keyword-identifiers
title: Actor storage variables reject target keywords before lowering
answers:
  - "why is actor storage named cell rejected?"
  - "which keyword rules apply to ISF actor storage variables?"
  - "can a storage bank use a keyword logical name?"
  - "does strict success prove a storage fixture compiles as HDL?"
date: 2026-09-27
status: current
tags: [isf, storage, identifiers, keywords, diagnostics, compilation]
evidence: perl/FSM/Adapter/ISF/Parser.pm; perl/FSM/Support/HDLInstanceIdentifierPolicy.pm; perl/FSM/Support/DiagnosticCodes.pm; perl/FSM/Support/RegressionCorpus.pm; t/1952-isf-storage-keyword-identifiers.t; docs/decisions/0110-actor-storage-variables-reject-hdl-keywords.md
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1952-isf-storage-keyword-identifiers.t
---

Actor var/variable names become emitted HDL signals, so parsing checks them
against the shared shipped-target keyword registry after checking their shape.
SystemVerilog lookup is case-sensitive and VHDL lookup is case-insensitive.
The error retains actor, name, reserving targets and rename guidance. Public
check/semantic failure reports classify it as
FSMGEN_LANGUAGE_ISF_STORAGE_IDENTIFIER and retain complete API/newline parity.
Schedule failures retain the existing message-only API contract.

Logical bank names do not become bare HDL signals. Keyword names such as cell
and process remain valid because the actual elements have numeric suffixes.
Field metadata does not declare independent registers. Other identifier
families remain outside this bounded source check; no global identifier audit
or backend-specific escaping is implied.

The original strict-success source and independent Verilator compile failure
are retained in .artifacts/formal-parent-read-products/. Strict checks are not
independent HDL compiler evidence. T1952 covers both variable aliases, target
case rules, early public rejection, legal spelling preservation, keyword bank
identities and independent Verilog/SystemVerilog legal-control compilation. VHDL emission
is checked; its independent analysis remains conditional on GHDL availability.
Earlier formal-product controls now use value_reg while preserving their raw
alias/collision mechanisms. Decision 0110 owns the compatibility boundary.
Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.1.3.

The tracked literal-producer census additionally migrated the book's packed
assembly variable to packed_value and T1920's record domain-control variable
to record_value. These are the same keyword class; type constructors and domain
access expectations retain their original meaning. The census excludes
arbitrary interpolated/generated source and does not prove global coverage.
