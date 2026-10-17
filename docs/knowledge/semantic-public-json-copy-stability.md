---
id: semantic-public-json-copy-stability
title: Public path inspection preserves JSON scalar kinds through later copies
answers:
  - "why did cloned normalized compiler reports turn JSON numbers into strings?"
  - "does serialized native API parity prove later copy stability?"
  - "how do fixed storage baselines preserve report JSON kinds during source relocation?"
date: 2026-10-01
status: current
tags: [semantic, mcp, json, paths, validation]
evidence: t/1981-isf-storage-word-access.t; t/1982-isf-domain-storage-report.t; perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm; t/lib/FSM/Test/SourceQueryRunner.pm; t/2018-semantic-public-json-scalar-kinds.t; t/2017-isf-record-input-frontend-closure.t; docs/audits/specforge-aggregate-intake-20260930/manifest.json; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2018-semantic-public-json-scalar-kinds.t t/2017-isf-record-input-frontend-closure.t t/1981-isf-storage-word-access.t t/1982-isf-domain-storage-report.t
---

At ee81704239ca86545804eee4af357ffb3a838404, native/API and normalized/sanitized
JSON retain numeric kinds. Text inspection changes private Perl scalar flags;
Storable cloning either processed projection turns selected decoded integers
(including schema/count fields) into strings. Raw decoded copies retain numbers;
serializing first does not repair flags. This is copy instability, not changed
untouched wire types.

The test normalizer inspects a separate scalar instead of interpolating the
returned value. Public sanitization retains an untouched
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

Helper introduced: 37f5ace88f474b751f5cfae2bb6e94a6cd875461; initial
adapter sanitization is 129cfae085f10f55b606152a3c09c2ec21a28b4e. Prior ordinary
serialized parity and literal declarations remain scoped evidence. T1884's
normalization fixture used compiled numeric literals; its parity comparisons
and T1981/T1982 value comparisons did not establish copy stability for freshly
decoded numeric scalars. This repair adds that separate qualification instead
of rewriting immutable receipts or claiming a global wire defect.

Fixed storage-oracle qualification also compares complete JSON
kinds in T1981/T1982 native/API/newline, declarations and immutable baseline
products. T1981's local source relocation previously stringified expected numeric
fields; it now inspects a separate scalar and returns the untouched value when
no authorized path substitution occurs. Fresh decoded literal output/copy/caller
controls and exact named producer/baseline/source bytes qualify that oracle.
Exact committed predecessor relocation remains RED. This updates current test
evidence without rewriting dated receipts or inferring a production wire defect.
Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4.2.3.1.

Re-derivation: producers, strict baselines and literal copy witnesses.
Falsification: corrected exact predecessors and negative path/version/copy
controls. Durability: tracked tests/sources, fixed intake, this fact, task and
Git. Native HDL/external execution has separate owners.

Index stop predicate 7d012832f repeats this on exit_code; exact failed-source
discriminator: `docs/audits/task-acceptance-index-prospective-20261018/verify_failure.py`.
Fix: local scalar copy; RED/GREEN: the neighboring `preflight.py`.
