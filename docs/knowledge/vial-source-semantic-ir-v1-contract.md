---
id: vial-source-semantic-ir-v1-contract
title: VIAL v1 is a closed spanned S-expression language with private typed SemanticIR
answers:
  - "what is the VIAL version 1 syntax?"
  - "does VIAL reuse Lispish?"
  - "why does VIAL need a dedicated parser?"
  - "what is core_directed_single_clock_v1?"
  - "what types does VIAL v1 have?"
  - "how does VIAL represent four-state values?"
  - "what is the difference between same and value_eq in VIAL?"
  - "does VIAL create a second property language?"
  - "what property operators does VIAL v1 support?"
  - "what reusable declarations does VIAL v1 support?"
  - "how are VIAL imports resolved?"
  - "what is the VIALSemanticIR v1 owner?"
  - "is VIALSemanticIR public?"
  - "what is the first planned VIAL source?"
  - "what report does the first VIAL implementation expose?"
  - "what does HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.2 select?"
  - "what task implements VIAL source and SemanticIR?"
date: 2026-07-31
status: current
tags: [vial, source-language, parser, semantic-ir, types, four-state, property-language, diagnostics, provenance, ahb]
evidence: docs/VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md; docs/decisions/0033-vial-v1-uses-spanned-s-expressions-and-typed-semantic-records.md; docs/decisions/0008-verification-property-language-unification.md; docs/decisions/0032-vial-uses-one-source-two-private-irs-and-a-versioned-hial-bridge.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; docs/book/src/16d-hial-vial-verification-architecture.md
reverify: rg -n 'core_directed_single_clock_v1|VIALSemanticIR Required IR Record|dedicated VIAL lexer|known_mask|z_mask|same.*value_eq|canonical property|ahb_subordinate_base_output_arbitration\.vial|t/1550-vial-semantic-ir\.t|Proposed `\.3`' docs/VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md docs/decisions/0033-vial-v1-uses-spanned-s-expressions-and-typed-semantic-records.md docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md docs/TASK_TREE.md
---

Decision `0033` selects VIAL version 1 as closed public S-expression syntax
with a dedicated span-aware parser. It keeps FSMGen's readable notation but
does not reuse or expose raw `Lispish` arrays, which lack the exact source-span
and stable semantic-record contract required for diagnostics, mapping, and
later replay.

The first profile is `core_directed_single_clock_v1`: explicit packages and
in-memory imports, target-neutral types and values, transactions,
deterministic models, bounded scoreboards, unbound typed DUT references,
coverage, a bounded substitution fault, explicit random-decision identity,
directed scenarios, bounded repeats, and deterministic `parallel all|any`
fibers. It parse/typechecks only; binding, plans, output, and runtime are later.

Two-state types are `bool`, `u`, and `s`; four-state types are `logic` and
`slogic`. `#b` values normalize to value bits, known mask, and Z mask. No
implicit truncation, signedness conversion, wrap, or X/Z-to-two-state coercion
exists. `same` performs exact four-state equality; `value_eq` requires known
numeric/Boolean operands.

VIAL does not fork temporal semantics. Expectations and waits reuse decision
`0008`'s canonical `=>`, `next`, and `within` operators around typed VIAL
sample/event/model/choice references.

`FSM::VIAL::SemanticBuilder` alone constructs private immutable
`FSM::VIAL::SemanticIR`; all structured access and sanitized reports are
defensive clones. The planned first source is
`vial/ahb_subordinate_base_output_arbitration.vial`. Clean contract commit
`08f59167b` activates only `.3`, which owns the four implementation packages,
source, and focused `t/1550-vial-semantic-ir.t`; activation changes no product
behavior.
