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

The book search covers the manual and this guide. Use the API index, coverage
list or browser Find to navigate the standalone module pages.

## Current MCP schema compatibility

The live MCP audit has identified the compatibility defects below. A client
that validates responses strictly can reject legitimate current results.
These descriptor and validation gaps are pending repair; the complete operating
reference and its drift checks remain under qualification.

| Surface | Current discrepancy |
| --- | --- |
| Check, semantic and schedule tools | A source identity is required at runtime; the input schemas omit that alternative requirement |
| Diagnostic explanation | `limit_examples` is supported by existing workflows but missing from the closed input schema |
| Capability sections | The selected manifest version is an integer payload; the schema declares an object payload |
| Example lookup | `documentation` contains the public documentation object; the schema declares an array |
| Metadata-tool arguments | Some extra fields and wrong types are accepted despite the advertised schemas; that leniency is outside the supported argument contract |
| Error messages | Some failures retain automatic Perl locations or reference addresses; use error codes and structured diagnostics for program decisions |

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
prevent a stale, missing or modified tree from passing `--check`. The fingerprint
includes Perl/Pod::Simple versions and Python's implementation and release
versions. Missing or changed runtime identities require regeneration. Under the
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

## Check the documented examples

The existing CI Python fixture job discovers the POD example suite. It executes
the selected guides' actual SYNOPSIS programs and checks concrete public
results, source identities and their agreement with the book's entry-point list.
Run the same checker from the repository root:

```bash
scripts/run_with_ram_guard.sh -- python3 -B scripts/check_pod_api_examples.py
```

Keep each selected SYNOPSIS as one complete Perl program indented by four
spaces. New selected entry points need an explicit result check. Each invocation
uses a unique repository-local workspace. Failed programs and raw stdout/stderr
are retained at the printed relative evidence path; successful temporary
workspaces are removed. The checker offers a per-program `--timeout` option.
Reference rendering and normal book builds do not execute these programs.
