---
id: semantic-public-json-copy-stability
title: Public path inspection preserves JSON scalar kinds through later copies
answers:
  - "why did cloned normalized compiler reports turn JSON numbers into strings?"
  - "does serialized native API parity prove later copy stability?"
date: 2026-10-01
status: current
tags: [semantic, mcp, json, paths, validation]
evidence: perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm; t/lib/FSM/Test/SourceQueryRunner.pm; t/2018-semantic-public-json-scalar-kinds.t; t/2017-isf-record-input-frontend-closure.t; docs/audits/specforge-aggregate-intake-20260930/manifest.json; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2018-semantic-public-json-scalar-kinds.t t/2017-isf-record-input-frontend-closure.t
---

At ee81704239ca86545804eee4af357ffb3a838404, untouched native/API JSON and
normalized/sanitized serialization retain numeric kinds. Text inspection changes
private Perl scalar flags, however. Storable cloning either processed projection
then turns selected decoded integers into JSON strings, including schema/count
fields. Raw decoded copies retain numbers. Serializing before copying does not
remove the flag change. This is a copy-stability defect, not evidence that
untouched wire responses already changed numeric types.

The test normalizer previously interpolated the returned value into a string.
It now inspects a separate scalar. Public sanitization retains an untouched
scalar whenever path processing makes no textual substitution. Source-failure
and VIAL-inspection classifiers compare local schema-version copies; VIAL-check
classification already used that approach. No numeric-string coercion, fabricated
number, schema change or path-policy relaxation is used. Integer, fractional,
negative, numeric-looking string, boolean and null values retain their kinds;
repository substitutions and external redaction keep their published rules.

T2018 uses independently decoded literals, serialized equality, subsequent
Storable copies, original-input preservation and recognized check/semantic/VIAL
failure signatures. Exact committed ee817 adapter/helper files make the corrected
copy controls RED; the old VIAL-check version-copy control remains positive.
T2017 retains strict full historical report comparisons and original supplied
record sources, so transport parity cannot hide a changed baseline kind.

The helper's introduction is 37f5ace88f474b751f5cfae2bb6e94a6cd875461; initial
adapter sanitization is 129cfae085f10f55b606152a3c09c2ec21a28b4e. Prior ordinary
serialized parity and literal declarations remain scoped evidence. T1884's
normalization fixture used compiled numeric literals; its parity comparisons
and T1981/T1982 value comparisons did not establish copy stability for freshly
decoded numeric scalars. This repair adds that separate qualification instead
of rewriting immutable receipts or claiming a global wire defect.

Actual producers, strict baseline products and literal copy witnesses supply
re-derivation. Corrected exact predecessor files and negative path/version/copy
controls supply falsification. Tracked tests, current sources, fixed intake
receipt, this fact, task evidence and Git supply durability. Native HDL and
external consumer execution remain separate owners.
