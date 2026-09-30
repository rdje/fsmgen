---
id: isf-aggregate-record-context-and-first-touch-validation
title: Record context gates detach facts before numeric validation
answers:
  - "how are selected record input AST contexts prepared without admission?"
  - "why can numeric validation change caller JSON scalar kinds without an assignment?"
  - "how is first-touch record declaration mutation reproduced and repaired?"
  - "can a scalar pin share an enum namespace name during record context validation?"
date: 2026-09-30
status: current
tags: [isf, record, ports, types, layout, writers, specforge]
evidence: perl/FSM/Support/ISFRecordPortContexts.pm; perl/FSM/Support/ISFRecordPortScopes.pm; perl/FSM/Support/ISFRecordPortValues.pm; t/1988-isf-record-port-context-gates.t; t/1987-isf-record-port-declaration-scopes.t; t/1986-isf-record-port-value-gates.t; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
---

# 0114 — Record value validation detaches facts before reading

- Date: 2026-09-30
- Status: qualified preparation; source admission remains pending
- Owner: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.2.2`
- Parent contract: [0113](0113-isf-record-interface-ports-reuse-packed-type-and-writer-contracts.md)

## Context

Record inputs need contextual scalar reads and strict same-type copies before
their first authored source admission. Existing qualified value gates accept
resolved declaration facts, and detached scope preparation consumes parsed
actor/formal/local declarations and untyped drive parameters. This preparation
is still unwired; current scalar/storage authoring remains unchanged.

T1988's complete actor comparison exposed a mutation missed by the earlier
T1987 baseline: validation changed string widths into JSON numbers on fresh
copies of parsed facts. The earlier mutation baseline followed a previous
projection. Direct fresh parser controls stayed equal; the fresh copied
controls were RED. T1986 independently reproduced the same change in each
scope, reference and copy gate using explicitly string-valued widths.

## Decision

Detach caller-owned declaration/type/reference maps before numeric validation
or comparison. Perl numeric reads can change a scalar's flags and subsequent
JSON representation without an assignment to that scalar. A clone made after
validation cannot protect the original. `Storable::dclone` detaches before
reads and retains cycles for the existing closed type validator to reject;
core type/path/layout contracts remain unchanged.

Reproduce the mechanism independently:

```bash
perl -MJSON::PP -e 'my $j=JSON::PP->new->canonical; my $x={width=>"7"}; print $j->encode($x),"\n"; my $n=0+$x->{width}; print $j->encode($x),"\n";'
```

The outputs are `{"width":"7"}` then `{"width":7}`. This is a caller-data
mutation mechanism, not a new numeric value or public field contract.

`ISFRecordPortContexts` now prepares selected transaction set/update RHS,
when/while/until conditions, switch selectors/branches, nested bodies, rule
guards/assignments, named/inline drive bodies and named-drive actuals. Whole
record ports refuse scalar contexts, including negated and compact comparison
spellings. Port-involved whole assignments consume qualified recursive type
identity and role gates; input targets, bad paths, operator-position paths and
unsupported subaggregate uses refuse. Existing storage-only packed transfers
retain their original owner. Explicit leaf sampling, domain ownership and
first source admission remain separate prerequisites.

The gate validates references, not the complete source grammar. Unknown tokens,
operator/arity/static-value rules and enum/package member validation retain
their existing validators. State-active arguments denote states, and local/
parameter declaration names are not read operands. No successful preparatory
gate establishes that an otherwise invalid source is accepted.

A scalar pin may share an enum/package root name. Actual namespace roots remain
delegated unless the nearest aggregate or an explicitly shadowed outer
aggregate identifies a declaration path. The draft incorrectly rejected the
admitted enum token `mode.BUSY` when the actor had scalar input `mode`.
T1988 retains the repaired source control and the counterexample in which a
scalar formal must not borrow a same-named outer record's member via an enum.
Actual aggregate/enum/rule classifier integration remains under `.3.2.3`.

## Qualification and limits

T1987's fresh copied actor/transaction/drive controls first reproduce the scalar
kind change; T1986's independently authored typed JSON does so for each value
gate. All preserve complete caller products after the repair. T1988 retains
independent selected AST cases and exact first-line negatives, same-type alias
copies, equal-width signed/state mismatches, input writes, formal shadows,
unknown-path controls, unsupported sampling/count/trigger contexts and enum
delegation. Complete currently admitted parser and scheduled products, including
emitted file bytes, remain unchanged. No oracle normalizes the caller product
before comparison.

```bash
scripts/run_with_ram_guard.sh -- prove -Iperl \
  t/1988-isf-record-port-context-gates.t \
  t/1987-isf-record-port-declaration-scopes.t \
  t/1986-isf-record-port-value-gates.t \
  t/1983-isf-interface-port-metadata.t \
  t/1259-isf-aggregate-storage-type-aliases.t t/1391-isf-local-variables.t
```

The competing borrowed-type, whole-record scalar, equal-width identity and
post-read detachment interpretations fail independent witnesses and negative
controls. Producers and permanent source/AST controls are tracked; ignored
logs are supplementary. This establishes unwired preparation and the repaired
caller-data contract, not new source/public transport admission, sample timing,
generated/domain carriers, external HDL execution or complete consumer delivery.
