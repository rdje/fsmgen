{{#include ../../LIVE_DOCUMENT_SIZE_CONTAINMENT_ADOPTION_GUIDE.md}}

## FSMGen reference checks

Maintained ISF reference parts may evolve after their initial partitioning.
`prove -Iperl t/1569-focused-document-containment.t` checks their current
structure and links. It separately reconstructs the original activation from
declared Git sources in a repository-local fixture, verifies exact transformed
content, and proves that a later edit fails that historical equality check.
The fixture leaves current reference files untouched.
