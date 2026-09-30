# Knowledge Map: `isf-aggregate`

> **AUTO-GENERATED — DO NOT EDIT.** Return to the [Knowledge Map](../../KNOWLEDGE_MAP.md).
> **3** facts · **19** uniquely owned question entries.

## Questions → facts

- q="are list ports and variant records part of required record-port delivery?" · facts=[isf-aggregate-port-contract-selection](../../docs/decisions/0113-isf-record-interface-ports-reuse-packed-type-and-writer-contracts.md)
- q="can ISF interface ports carry packed records?" · facts=[isf-aggregate-port-request-baseline](../../docs/knowledge/isf-aggregate-port-request-baseline.md)
- q="can a scalar pin share an enum namespace name during record context validation?" · facts=[isf-aggregate-record-context-and-first-touch-validation](../../docs/decisions/0114-record-value-validation-detaches-facts-before-reading.md)
- q="do record input reads require independent controller repairs?" · facts=[isf-aggregate-port-contract-selection](../../docs/decisions/0113-isf-record-interface-ports-reuse-packed-type-and-writer-contracts.md)
- q="does internal generated aggregate handoff support authored record ports?" · facts=[isf-aggregate-port-request-baseline](../../docs/knowledge/isf-aggregate-port-request-baseline.md)
- q="how are actual parsed record-value declaration scopes prepared?" · facts=[isf-aggregate-port-contract-selection](../../docs/decisions/0113-isf-record-interface-ports-reuse-packed-type-and-writer-contracts.md)
- q="how are record value gates and contextual diagnostic oracles qualified?" · facts=[isf-aggregate-port-contract-selection](../../docs/decisions/0113-isf-record-interface-ports-reuse-packed-type-and-writer-contracts.md)
- q="how are selected record input AST contexts prepared without admission?" · facts=[isf-aggregate-record-context-and-first-touch-validation](../../docs/decisions/0114-record-value-validation-detaches-facts-before-reading.md)
- q="how is declared interface metadata qualified against supported ISF source queries?" · facts=[isf-aggregate-port-contract-selection](../../docs/decisions/0113-isf-record-interface-ports-reuse-packed-type-and-writer-contracts.md)
- q="how is first-touch record declaration mutation reproduced and repaired?" · facts=[isf-aggregate-record-context-and-first-touch-validation](../../docs/decisions/0114-record-value-validation-detaches-facts-before-reading.md)
- q="how is foreign-domain scalar slice and input-index refusal repaired and qualified?" · facts=[isf-aggregate-port-contract-selection](../../docs/decisions/0113-isf-record-interface-ports-reuse-packed-type-and-writer-contracts.md)
- q="what contract is selected for ISF record interface ports?" · facts=[isf-aggregate-port-contract-selection](../../docs/decisions/0113-isf-record-interface-ports-reuse-packed-type-and-writer-contracts.md)
- q="what is the packed record port field order?" · facts=[isf-aggregate-port-contract-selection](../../docs/decisions/0113-isf-record-interface-ports-reuse-packed-type-and-writer-contracts.md)
- q="where are declared ISF interface ports exposed in reports?" · facts=[isf-aggregate-port-contract-selection](../../docs/decisions/0113-isf-record-interface-ports-reuse-packed-type-and-writer-contracts.md)
- q="where is the SPECFORGE aggregate interface request preserved?" · facts=[isf-aggregate-port-request-baseline](../../docs/knowledge/isf-aggregate-port-request-baseline.md)
- q="which existing domain-path defect must be repaired before record input admission?" · facts=[isf-aggregate-port-contract-selection](../../docs/decisions/0113-isf-record-interface-ports-reuse-packed-type-and-writer-contracts.md)
- q="which type and lexical gates must precede record input admission?" · facts=[isf-aggregate-port-contract-selection](../../docs/decisions/0113-isf-record-interface-ports-reuse-packed-type-and-writer-contracts.md)
- q="why can numeric validation change caller JSON scalar kinds without an assignment?" · facts=[isf-aggregate-record-context-and-first-touch-validation](../../docs/decisions/0114-record-value-validation-detaches-facts-before-reading.md)
- q="why must metadata validation predicates use scalar context?" · facts=[isf-aggregate-port-contract-selection](../../docs/decisions/0113-isf-record-interface-ports-reuse-packed-type-and-writer-contracts.md)

## Facts

### isf-aggregate-port-contract-selection

_Selected record ports reuse packed types and qualified writers_

- **date:** 2026-09-30 · **status:** current
- **source and verification:** [`docs/decisions/0113-isf-record-interface-ports-reuse-packed-type-and-writer-contracts.md`](../../docs/decisions/0113-isf-record-interface-ports-reuse-packed-type-and-writer-contracts.md)

### isf-aggregate-port-request-baseline

_Authored record ports remain a separate boundary from typed storage_

- **date:** 2026-09-30 · **status:** current
- **source and verification:** [`docs/knowledge/isf-aggregate-port-request-baseline.md`](../../docs/knowledge/isf-aggregate-port-request-baseline.md)

### isf-aggregate-record-context-and-first-touch-validation

_Record context gates detach facts before numeric validation_

- **date:** 2026-09-30 · **status:** current
- **source and verification:** [`docs/decisions/0114-record-value-validation-detaches-facts-before-reading.md`](../../docs/decisions/0114-record-value-validation-detaches-facts-before-reading.md)
