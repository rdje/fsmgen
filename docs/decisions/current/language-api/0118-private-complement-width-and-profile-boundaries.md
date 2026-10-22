---
id: private-complement-width-and-profile-boundaries
title: Private complement width and profile boundaries
answers:
  - "why is a one-bit private complement classified as a vector?"
  - "does the archived scalar complement failure have its matching source?"
  - "why can direct VHDL emit a foreign tilde from private complement?"
  - "why does top-level AST rendering warn about an undefined caller?"
date: 2026-10-22
status: current
tags: [expression, width, complement, vhdl, diagnostics, provenance]
evidence: docs/audits/private-complement-reproduction-20261022.json.gz; docs/audits/private-complement-repair-20261022.json.gz; docs/audits/ast-caller-diagnostics-20261022.json.gz; docs/audits/direct-vhdl-process-boundaries-20261022.json.gz; docs/tasks/ISF-REDUCTION-DELIVERY.md; perl/FSM/Synthesis/EnableGraph/ASTSupport.pm; perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm
---
# 0118 — Private complement width and profile boundaries

- Type: private expression and backend contract
- Status: selected; bounded complement, caller diagnostic and process-refusal repairs qualified
- Owner: `ISF-REDUCTION-DELIVERY.7.1`

## Authenticated pre-repair behavior

The private enable-graph expression-width reader preserves the operand width
of `~`, but its single-bit classifier recognizes logical negation and reductions
only. A declared scalar complement therefore has known scalar width and false
scalar classification in Core, runtime and substituted AST models. Logical
negation of that value emits a redundant reduction wrapper. Declared wide
complement and unsupported unary operators retain conservative classification.

The direct VHDL converter currently returns output containing foreign `~`
for plain and logically negated private complement expressions. Correctly
recognizing scalar complement can expose this existing residue path through
narrower logical rendering. Source `(~ X)` remains refused; optional vector
inversion and executable VHDL qualification are separate from these repairs.

Top-level calls to `ast_to_systemverilog` also warn about undefined caller
subroutine/line metadata. Diagnostic string construction reads an unavailable
outer call frame even when informational debug output is disabled.

## Selected repair boundaries

Recognize complement's scalar result only through its explicit known
width-preserving semantics. Unknown widths and unsupported unary operators
cannot borrow scalar status. Preserve existing logical/reduction behavior.
After supported reduction translation, direct VHDL must refuse untranslated
complement tokens rather than return foreign syntax. Keep supported scalar and
vector reduction folds unchanged. Supply defined caller metadata without
changing rendered values or debug routing. Implementation and independent
preservation are owned by `.7.1.2` and `.7.1.3`.

## Complement repair

Leaf `.7.1.2` recognizes `~` only through its explicit width-preserving
semantics and the existing expression-width reader. Declared width one is
scalar; wide and unresolved complements stay conservative. Unsupported unary
operators cannot borrow scalar status. Logical and reduction results keep
their existing scalar behavior. Direct VHDL rejects residual `~` after supported
reduction conversion; assignments, comparisons and generated conditions share
that check. Source inversion remains refused and no HDL execution is inferred.
The unchanged authenticated probe and expanded real-owner regression qualify
these boundaries. Caller metadata is qualified below. An initial condition fixture
used unsupported `always @*` rather than generated `always_comb`; that harness
error and the converter's independently owned silent-drop defect remain
explicit under `.4`, without extending this repair's supported profile.

## Caller diagnostic repair

Leaf `.7.1.3` retains existing outer-subroutine metadata when available. For a
file-scope invocation, the renderer uses `(top level)` and the immediate call
line, with a defined zero fallback if no line exists. Message construction no
longer warns before debug gating. Actual Core, runtime and substituted renders
preserve expression bytes, low-level silence, stdout/file routing and nested
metadata. The unchanged valid regression fails before this repair and passes
after it. Its initial wrong Core constructor invocation is retained separately
as a harness error, not product evidence. Public syntax, report schemas and HDL
support boundaries do not change.

## Process-refusal repair

Leaf `.7.1.4` retains the actual ordinary conditional `always @*` source and
returned VHDL: no error, no process and no assignment. A lexical guard now
accounts for `always`, `always_comb`, `always_ff`, `always_latch`, `initial` and
`final`. Only generated multiline comb/ff begin headers reach existing body
conversion; the other keywords and noncanonical headers explicitly refuse
without returning an artifact. Comments are excluded from discovery and block
depth, and quoted metadata or longer identifiers cannot invent a keyword.
Actual sync/async reset and combinational controls preserve their processes
and assignments. Public unary admission is verified independently; the initial
legacy strict-reset spelling failure remains a separate harness epoch. This
finite profile repair makes no arbitrary-translation or VHDL execution claim.

## Evidence provenance

The original scalar-complement failure has its matching archived test source:
the call and label span lines 137–138, matching the retained RED location.
An initial single-line excerpt filter missed that pair. That interpretation
was corrected by direct complete-source inspection; no historical source gap
exists. No original failed outcome is replaced by a later result.

Fresh declared-width/renderer/converter products and compiled method source
identities bind the current reproduction to Git. Its first fixture treated an
unused width directive as an existing runtime signal. That epoch is preserved;
the settled fixture actually reads/copies the wide signal. The settled RED
isolates scalar-classification and VHDL-token failures, with wide, logical and
unsupported controls passing. Actual native source inversion still refuses.
No compiler, simulator, source inversion feature or historical replay runs.
