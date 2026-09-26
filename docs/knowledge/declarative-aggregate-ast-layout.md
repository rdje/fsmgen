---
id: declarative-aggregate-ast-layout
title: Single-member aggregate type AST layout and dependency resolution
answers:
  - "why did a single-member ISF record fail as malformed types?"
  - "how do raw and normalized aggregate type bodies differ?"
  - "do single-item lists preserve nested types and forward aliases?"
date: 2026-09-27
status: current
tags: [isf, types, aggregates, parsing]
evidence: perl/FSM/Package/DeclarativeTypeSupport.pm; perl/FSM/Package/DeclarativeTypeResolver.pm; perl/FSM/Package/Parser.pm; perl/FSM/Adapter/ISF/Parser.pm; t/1905-single-member-aggregate-types.t
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1905-single-member-aggregate-types.t t/280-declarative-aggregate-types.t t/1259-isf-aggregate-storage-type-aliases.t
---

Raw Lispish type forms wrap their aggregate body; the ISF adapter produces
flat forms. A sole array may be the wrapper or the actual member/nested type.
`type_ast_layout` explicitly selects `lispish` (default) or `flat`; the shared
`aggregate_body_items` operation serves both canonicalization and dependency
collection. ISF local package resolution passes `flat` through both consumers;
imported packages, direct roots and composition keep their raw layout.

Single-member records, single-item structured lists and nested forward aliases
retain their exact type shape and packed width through scheduled replay. Type
cycles and malformed specs still fail; package errors from these resolution
paths carry source/type context without process-specific Carp frames. T1905
compares complete native/API/newline reports for positive and negative cases.
See [the type chapter](../book/src/13j-type-enum-aggregate.md) and owner
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.40`. This does not qualify shared child
aggregate HDL composition; that remains owned by `.39.2.2.2.2`.
