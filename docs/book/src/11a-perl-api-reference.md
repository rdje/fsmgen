# Perl API Reference

The [generated API index](perl-api/index.html) renders the POD embedded in
FSMGen's Perl modules. Start with the selected entry points below. The
[coverage report](perl-api/coverage.html) lists every `.pm` source under `perl/FSM/`
and identifies missing POD explicitly; it also has a
[machine-readable form](perl-api/coverage.json).

| Entry point | Use it for |
| --- | --- |
| [HDLGenerator](perl-api/FSM/Pipeline/HDLGenerator.html) | Construct a generation pipeline and obtain HDL/results |
| [ISF parser](perl-api/FSM/Adapter/ISF.html) | Parse an IAL1 file or source text |
| [ISF scheduler](perl-api/FSM/Scheduler/ISF.html) | Obtain lowered IAL0 sources or a schedule JSON string |
| [Capability manifest](perl-api/FSM/Support/CapabilityManifest.html) | Discover current capabilities and binding contracts |
| [MCP adapter](perl-api/FSM/Support/SemanticIntrospectionMCPAdapter.html) | Host the bounded read-only local MCP service |
| [VIAL tooling](perl-api/FSM/VIAL/Tool.html) | Check/inspect VIAL source or use the versioned tooling lifecycle |

POD documents the Perl bindings. The language-neutral request/result schemas,
support boundaries and tutorials remain in
[Extensions and Embedding](11-extensions-and-embedding.md) and the
[VIAL Lifecycle Reference](16dg-vial-public-lifecycle-reference.md).
The selected guides describe signatures, options, return values, exceptions,
effects and stability, with runnable examples. This list is a starting set of
guides, not an exhaustive list of every supported interface.

Other rendered module pages are implementation documentation. POD presence
does not make an internal method public or stable, and a no-POD inventory page
does not describe that module's methods. In particular, the entire raw HDL
generation result is not JSON-safe. Use the documented normalized reports for
external consumers. The MCP adapter exposes its documented read-only query
subset; VIAL tooling's plan/run operations have a separate host boundary.

## Build and preview

Normal HTML builds and previews generate and validate the reference
automatically:

```bash
mdbook build docs/book
cd docs/book
mdbook serve
```

The documentation tool needs Python 3.9 or newer on macOS/Linux and
`Pod::Simple` 3.42 or newer, including `Pod::Simple::HTMLBatch` and
`Pod::Simple::Checker`. Perl's main implementation requirement remains in the
repository README. No FSMGen module is loaded merely to render its POD.

Run these standalone commands from the repository root when diagnosing a
documentation build:

```bash
python3 -B scripts/generate_pod_reference.py
python3 -B scripts/generate_pod_reference.py --check
```

The reference uses local styles and relative links, so it works in a moved
checkout, a custom book destination or a site hosted below a URL prefix.
Generated pages live in the ignored `docs/book/src/perl-api/` directory; the
HTML backend copies them into the book. Captured inputs and temporary staging
stay under `.artifacts/`. The preprocessor reuses an intact current tree
without writing it. Serve watches the module/tool/style inputs and ignores the
generated directory to avoid rebuilding in response to its own output.

## Validation and failures

Generation rejects malformed POD, missing expected module pages, broken local
links/fragments and unsafe paths. The gate considers both the checker
error flag and its diagnostic output. With the qualified Pod::Simple 3.42,
formatting diagnostics can clear the flag even when the output reports an error;
that output still fails generation. The generated coverage population is checked
against all module sources. Source/tool fingerprints and complete output hashes
prevent a stale, missing or modified tree from passing `--check`. Under the
same inputs and tool versions, fresh renders have identical file bytes;
generated footers contain no wall-clock timestamp.

If generation fails, the previous output tree is retained and the book build
fails. Fix the reported source POD or link before rebuilding. If known generated
files have been damaged, inspect them, then run:

```bash
python3 -B scripts/generate_pod_reference.py --repair
```

Repair replaces only a manifest-owned tree. Unknown extra files/directories,
symlinks and foreign repository/volume paths are refused. Resolve any unowned
content deliberately; the generator will not delete it. Simultaneous generator
invocations fail clearly rather than modifying the output concurrently.

The book search covers the manual and this guide. Use the API index, coverage
list or browser Find to navigate the standalone module pages.
