<!-- README-POLICY-LOCAL-ADOPTION:BEGIN -->
## Local adoption note — FSMGen

- Authority: FSMGen maintainers, adopted 2026-07-30 under decision 0024 and
  refined 2026-07-31 under decision 0038.
- Authoritative copy: repository-root `README_POLICY.md`. Agent/harness
  bootstrap files may point here, but they are not the policy's authority.
- Independence: the originating template is not an upstream. There is no
  automatic synchronization; later changes require deliberate local review.
- Reviewed local budgets: 275 lines and 12,288 bytes, derived with modest
  headroom from the reviewed 246-line / 9,952-byte landing page.
<!-- README-POLICY-LOCAL-ADOPTION:END -->

---

# README Stability Policy

This project- and harness-neutral policy keeps a repository README useful as a
stable landing page instead of letting it grow into a changelog, roadmap, or
documentation catalog.

## Authority and provenance

After adoption, the project owns this policy. Cite its authority by project
owner and adoption or revision date, together with the project-owned
`<repository-root>/README_POLICY.md`. Never cite a vendor-, agent-, or
harness-specific bootstrap file as the authority. Bootstrap files may help
authors and tools discover the policy; they do not make the policy binding.

## Storage location

Store the adopting project's canonical copy as the git-tracked
`<repository-root>/README_POLICY.md`, alongside `README.md`. Keeping the policy
with the file it governs gives contributors, local hooks, and CI one
discoverable, versioned source of truth. A user-home, machine-global, or other
external copy may serve as a reusable template, but it must not replace the
project-owned repository copy. Once copied, the project-owned file is
authoritative and the origin is not an upstream. Do not automatically re-sync
from the origin; adopt later revisions only through deliberate local review.

Keep project-specific adoption metadata—owner, date, decisions, derived caps,
and local enforcement links—in a clearly fenced adoption note above the
neutral policy body. This keeps the reusable body free of project-specific and
harness-vendor-specific tokens without hiding local authority.

## Content contract

Keep only information a first-time visitor needs:

- purpose, audience, and top-level scope;
- prerequisites and one minimal verified quick start;
- stable architecture at a glance;
- links to canonical documentation, support, and contribution guidance;
- license and other essential repository-level notices.

Route changing detail elsewhere:

| Content | Canonical home |
| --- | --- |
| User-facing feature detail and examples | User guide or product manual |
| Current work, priorities, and roadmap status | Roadmap, issue tracker, or task system |
| Release history | Releases, changelog, or git history |
| Design rationale | Decision records or architecture docs |
| Exhaustive file/API/sample inventories | Generated indexes or dedicated references |
| Diagnostics and operational procedures | Troubleshooting or contributor docs |

Change the README only when its purpose, first-use path, top-level architecture,
or canonical navigation changes. Ordinary feature work should update the
canonical destination, not the README.

Before deleting or relocating apparent duplication, prove that it is genuinely
duplicated with a phrase, identity, or content probe against the intended
canonical home. If that home is already richer and maintained, delete the
README copy and retain one link. Relocate only information that is unique and
still belongs in maintained documentation.

## Mechanical growth guard

Enforce both a line cap and a byte cap. Derive both from the landing page that
survives a deliberate review and trim, leaving only modest explicit headroom.
Do not copy example values from this policy. Never raise a cap merely to land
new content; move the detail to its canonical home. A cap increase requires an
explicit reviewed decision that the landing-page contract itself expanded.

A minimal deterministic check is:

```sh
line_cap=__DERIVED_LINE_CAP__
byte_cap=__DERIVED_BYTE_CAP__
lines=$(wc -l < README.md | tr -d ' ')
bytes=$(wc -c < README.md | tr -d ' ')
test "$lines" -le "$line_cap"
test "$bytes" -le "$byte_cap"
```

Replace both placeholders with the adopting project's reviewed values before
enabling the check. Keep it non-mutating, return nonzero with a routing hint on
failure, and run it unconditionally on every commit and CI build. Landing-page
size is a property of the resulting tree, so the guard must not short-circuit
merely because `README.md` is absent from a staged or changed-path set; this
also catches over-budget merge and revert results.

Line and byte checks are independent. In one real adoption, the retained README
was 141 lines yet already 10,297 bytes; a numbered prose list measured roughly
118 bytes per line while a path list measured roughly 57. A line budget alone
therefore cannot constrain prose density, and a byte budget alone cannot
constrain vertical sprawl.

## Adoption checklist

1. Add and commit `<repository-root>/README_POLICY.md` beside `README.md`.
2. Fence local owner/date, authoritative-copy, independence, decision, and cap
   metadata above the neutral policy body.
3. Prove apparent status, history, inventory, and deep-reference duplication
   against its canonical home; delete-with-link when that home is richer, and
   relocate only genuinely unique maintained content.
4. Verify the retained quick start and links.
5. Record where each excluded content class belongs.
6. Derive reviewed line and byte caps from the trimmed survivor with modest
   explicit headroom; do not copy illustrative values.
7. Commit the deterministic check and wire it unconditionally into every local
   commit and CI build, independent of changed-path scope.
8. Require an explicit decision before either cap can increase.
