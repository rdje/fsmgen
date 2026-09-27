# Knowledge Map: `isf-generated`

> **AUTO-GENERATED — DO NOT EDIT.** Return to the [Knowledge Map](../../KNOWLEDGE_MAP.md).
> **6** facts · **20** uniquely owned question entries.

## Questions → facts

- q="can a child read a parent record or list after spawn?" · facts=[isf-generated-child-aggregate-reads](../../docs/knowledge/isf-generated-child-aggregate-reads.md)
- q="can a generated child write an entire actor-owned record or list?" · facts=[isf-generated-child-whole-aggregate-writes](../../docs/knowledge/isf-generated-child-whole-aggregate-writes.md)
- q="can an ISF clock domain be named bus or another HDL keyword?" · facts=[isf-generated-domain-identities](../../docs/knowledge/isf-generated-domain-identities.md)
- q="can case-only ISF domain names overwrite exported files?" · facts=[isf-generated-domain-identities](../../docs/knowledge/isf-generated-domain-identities.md)
- q="can generated child transactions read actor storage in independent clock domains?" · facts=[isf-generated-child-aggregate-reads](../../docs/knowledge/isf-generated-child-aggregate-reads.md)
- q="can two children write different members of an actor storage record?" · facts=[isf-generated-child-whole-aggregate-writes](../../docs/knowledge/isf-generated-child-whole-aggregate-writes.md)
- q="do aggregate child writes preserve imported aliases and owner resets?" · facts=[isf-generated-child-whole-aggregate-writes](../../docs/knowledge/isf-generated-child-whole-aggregate-writes.md)
- q="does a child storage write wait until completion or add a register cycle?" · facts=[isf-generated-child-scalar-writes](../../docs/knowledge/isf-generated-child-scalar-writes.md)
- q="does storage_port arbitrate generated child transaction writes?" · facts=[isf-generated-child-writer-contract-frontier](../../docs/knowledge/isf-generated-child-writer-contract-frontier.md)
- q="how are child named completion outputs combined with parent completion?" · facts=[isf-generated-child-named-completion](../../docs/knowledge/isf-generated-child-named-completion.md)
- q="how are domain and CDC child naming collisions resolved?" · facts=[isf-generated-domain-identities](../../docs/knowledge/isf-generated-domain-identities.md)
- q="how do agents join logical domains to generated children through semantic API and MCP?" · facts=[isf-generated-domain-identities](../../docs/knowledge/isf-generated-domain-identities.md)
- q="how do generated child storage reads preserve aggregate types?" · facts=[isf-generated-child-aggregate-reads](../../docs/knowledge/isf-generated-child-aggregate-reads.md)
- q="how does a generated child write the parent actor storage register?" · facts=[isf-generated-child-scalar-writes](../../docs/knowledge/isf-generated-child-scalar-writes.md)
- q="is set-field a partial child storage write?" · facts=[isf-generated-child-writer-contract-frontier](../../docs/knowledge/isf-generated-child-writer-contract-frontier.md)
- q="what is the next generated child storage writer contract?" · facts=[isf-generated-child-writer-contract-frontier](../../docs/knowledge/isf-generated-child-writer-contract-frontier.md)
- q="where do generated child storage resets and registers live?" · facts=[isf-generated-child-aggregate-reads](../../docs/knowledge/isf-generated-child-aggregate-reads.md)
- q="why are competing child or parent storage writers rejected?" · facts=[isf-generated-child-scalar-writes](../../docs/knowledge/isf-generated-child-scalar-writes.md)
- q="why did a generated child completing a named output fail to release its parent?" · facts=[isf-generated-child-named-completion](../../docs/knowledge/isf-generated-child-named-completion.md)
- q="why must delayed pulses be excluded from inferred shared datapaths?" · facts=[isf-generated-child-named-completion](../../docs/knowledge/isf-generated-child-named-completion.md)

## Facts

### isf-generated-child-aggregate-reads

_Generated children read live aggregate storage through typed internal ports_

- **date:** 2026-09-27 · **status:** current
- **source and verification:** [`docs/knowledge/isf-generated-child-aggregate-reads.md`](../../docs/knowledge/isf-generated-child-aggregate-reads.md)

### isf-generated-child-named-completion

_Generated child named completion preserves authored pulses and activation handshakes_

- **date:** 2026-09-27 · **status:** current
- **source and verification:** [`docs/knowledge/isf-generated-child-named-completion.md`](../../docs/knowledge/isf-generated-child-named-completion.md)

### isf-generated-child-scalar-writes

_Sole scalar child writers transfer data and enable on the original edge_

- **date:** 2026-09-27 · **status:** current
- **source and verification:** [`docs/knowledge/isf-generated-child-scalar-writes.md`](../../docs/knowledge/isf-generated-child-scalar-writes.md)

### isf-generated-child-whole-aggregate-writes

_Sole generated children write whole record and list storage on the original edge_

- **date:** 2026-09-27 · **status:** current
- **source and verification:** [`docs/knowledge/isf-generated-child-whole-aggregate-writes.md`](../../docs/knowledge/isf-generated-child-whole-aggregate-writes.md)

### isf-generated-child-writer-contract-frontier

_Broader child writers separate aggregate transfer, partial merge, bank ownership and contention_

- **date:** 2026-09-27 · **status:** current
- **source and verification:** [`docs/knowledge/isf-generated-child-writer-contract-frontier.md`](../../docs/knowledge/isf-generated-child-writer-contract-frontier.md)

### isf-generated-domain-identities

_ISF logical domains retain identity through portable generated names and case-safe artifacts_

- **date:** 2026-09-26 · **status:** current
- **source and verification:** [`docs/knowledge/isf-generated-domain-identities.md`](../../docs/knowledge/isf-generated-domain-identities.md)
