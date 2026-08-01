# Knowledge Map: `isf-assert`

> **AUTO-GENERATED — DO NOT EDIT.** Return to the [Knowledge Map](../../KNOWLEDGE_MAP.md).
> **2** facts · **13** uniquely owned question entries.

## Questions → facts

- q="are mixed legacy and CoreAST nodes responsible for the AXI assertion bug?" · facts=[isf-assert-nested-bitwise-precedence-bug](../../docs/knowledge/isf-assert-nested-bitwise-precedence-bug.md)
- q="does AXI fixed-four read address 0x00000004 pass generated assertions?" · facts=[isf-assert-nested-bitwise-precedence-behavior](../../docs/knowledge/isf-assert-nested-bitwise-precedence-behavior.md)
- q="does FSMGEN currently preserve nested bitwise precedence in assertions?" · facts=[isf-assert-nested-bitwise-precedence-behavior](../../docs/knowledge/isf-assert-nested-bitwise-precedence-behavior.md)
- q="does assertion condition inlining preserve nested bitwise precedence?" · facts=[isf-assert-nested-bitwise-precedence-bug](../../docs/knowledge/isf-assert-nested-bitwise-precedence-bug.md)
- q="does t1502 freeze the grouped AXI write-request assertion?" · facts=[isf-assert-nested-bitwise-precedence-behavior](../../docs/knowledge/isf-assert-nested-bitwise-precedence-behavior.md)
- q="how are inline intermediate expressions grouped in generated properties?" · facts=[isf-assert-nested-bitwise-precedence-behavior](../../docs/knowledge/isf-assert-nested-bitwise-precedence-behavior.md)
- q="is the AXI read burst4 4-KiB admission guard behavior wrong?" · facts=[isf-assert-nested-bitwise-precedence-bug](../../docs/knowledge/isf-assert-nested-bitwise-precedence-bug.md)
- q="what is the selected repair for inline assertion expression precedence?" · facts=[isf-assert-nested-bitwise-precedence-bug](../../docs/knowledge/isf-assert-nested-bitwise-precedence-bug.md)
- q="what owns the nested bitwise assertion precedence repair?" · facts=[isf-assert-nested-bitwise-precedence-bug](../../docs/knowledge/isf-assert-nested-bitwise-precedence-bug.md)
- q="what shipped the nested-bitwise assertion precedence repair?" · facts=[isf-assert-nested-bitwise-precedence-behavior](../../docs/knowledge/isf-assert-nested-bitwise-precedence-behavior.md)
- q="why does t1507 use separate behavior and all-assertion harnesses?" · facts=[isf-assert-nested-bitwise-precedence-behavior](../../docs/knowledge/isf-assert-nested-bitwise-precedence-behavior.md)
- q="why does the AXI fixed-four read assertion reject address 0x00000004?" · facts=[isf-assert-nested-bitwise-precedence-bug](../../docs/knowledge/isf-assert-nested-bitwise-precedence-bug.md)
- q="why does the write burst4 request audit use a De Morgan address predicate?" · facts=[isf-assert-nested-bitwise-precedence-bug](../../docs/knowledge/isf-assert-nested-bitwise-precedence-bug.md)

## Facts

### isf-assert-nested-bitwise-precedence-behavior

_Concurrent checks preserve grouped inline-intermediate expressions_

- **date:** 2026-07-30 · **status:** current
- **source and verification:** [`docs/knowledge/isf-assert-nested-bitwise-precedence-behavior.md`](../../docs/knowledge/isf-assert-nested-bitwise-precedence-behavior.md)

### isf-assert-nested-bitwise-precedence-bug

_Concurrent assertion inlining can lose nested bitwise parentheses_

- **date:** 2026-07-30 · **status:** historical
- **source and verification:** [`docs/knowledge/isf-assert-nested-bitwise-precedence-bug.md`](../../docs/knowledge/isf-assert-nested-bitwise-precedence-bug.md)
