{{#include ../../LIVE_DOCUMENT_SIZE_CONTAINMENT_ADOPTION_GUIDE.md}}

## FSMGen reference checks

Maintained ISF reference parts may evolve after their initial partitioning.
`prove -Iperl t/1569-focused-document-containment.t` checks their current
structure and links. It separately reconstructs the original activation from
declared Git sources in a repository-local fixture, verifies exact transformed
content, and proves that a later edit fails that historical equality check.
The fixture leaves current reference files untouched.

Task-evidence transition allowances reserve a bounded band of ordinary task
growth using the existing `ratchet_step` fields. The
[revision-bound calibration](../../../docs/audits/task-evidence-growth-band-20261027/measure.py)
derives aggregate bands from recent task changes and checks their selection
against the current registry. This reduces repeated allowance-only commits
while preserving per-file limits, immutable baselines, health targets, ceilings
and rollover checks. At rollover, exact version-object terminals or authenticated
history manifests retain completed evidence outside the live working set;
splitting into segments alone does not reduce aggregate pressure.
