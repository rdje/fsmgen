---
id: isf-named-drive-scalar-selector-identity
title: Scalar named-drive selectors follow private parameter roots
answers:
  - "why did a scalar drive parameter slice read a masked actor record?"
  - "why did a domain drive selector create an unconnected core.packet port?"
  - "does a drive parameter selector borrow its outer record width?"
date: 2026-10-01
status: current
tags: [isf, drive, scalar, record-ports, domains, lowering]
evidence: perl/FSM/Scheduler/ISF/LoweringIR.pm; t/2022-isf-drive-parameter-selectors.t; t/2021-isf-record-input-generated-refusals.t; t/1194-isf-drive-body-boundary.t; docs/book/src/13j-type-enum-aggregate.md; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/2022-isf-drive-parameter-selectors.t t/2021-isf-record-input-generated-refusals.t t/1194-isf-drive-body-boundary.t
---

At aebe0037554eb9995c1d4fa67f4ec53f98364520, a named drive's scalar
parameter packet masks the actor record during context/domain validation.
Lowering replaces a bare packet RHS with publish_packet but leaves
packet[3:0] unchanged. An ordinary carrier then interprets that selector
against the actor record and refuses malformed typed aggregate access.
A domain carrier instead invents a core.packet input and strict composition
check refuses its unconnected port. Neither refusal admits a crossing or
establishes executed incorrect HDL behavior.

The root is _substitute_named_drive_body_expr's exact bare-name lookup.
c6480c4d6378f884e4937a8ae9b9050a8e2ac8a4 introduces bare parameter
substitution; 505c2f72f6389c97165ccd68f9f140037139768d adds recursive
expression substitution while retaining that lookup. The helper's line history
is unchanged through the exact predecessor. Those observations describe this
handoff history, not every historical selector admission path.

The repair retains a single static scalar bit/slice suffix on a declared
parameter root, including within nested normalized expression arrays. Private
invocation prefixes remain supplied by the existing drive source owner.
Unrelated roots, members, namespaces, dynamic/chained selectors and caller
values remain untouched. Type/range/width validity stays with its existing
owners. A selector alone does not infer a parameter width from an outer record;
the authored witness uses a supported bare output to establish five bits.

Re-derivation uses actual authored ordinary/domain carriers and strict public
source products. Falsification uses complete literal selector/expression maps,
caller values, the corrected pre-repair RED and the exact committed predecessor
helper, independently of transport parity. Permanent producers/tests, the book,
this card, owning task and Git preserve durability. Full contextual refusal and
accepted controls qualify this selector prerequisite; generated binding-name
qualification remains the separately owned .2 prerequisite before parent closure; no HDL runtime or
external consumer signoff is inferred. Owner: SEM .60.4.3.2.4.2.2.1.
