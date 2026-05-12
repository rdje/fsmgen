# ISF Public Interface Contract

This is the live downstream-consumer contract for the `.isf` intent-scheduling
surface.

It is intentionally a live document: any implementation slice that changes
supported ISF syntax, CLI behavior, public in-process facade behavior, scheduled
`.fsm` result shape, or schedule-report shape must update this file in the same
commit.

Machine-readable discovery lives in
[perl/FSM/Support/ISFPublicInterfaceContract.pm](../perl/FSM/Support/ISFPublicInterfaceContract.pm)
and is advertised through:

```text
./bin/fsmgen --capability-manifest
  -> embedding.isf_public_interface
```

## Stabilized Surface

The current bounded public surface is deliberately narrow.

Supported CLI entrypoints:

```bash
./bin/fsmgen path/to/file.isf
./bin/fsmgen --emit-schedule-json path/to/file.isf
./bin/fsmgen --outdir path/to/outdir path/to/file.isf
```

Supported in-process facade entrypoints:

```perl
my $actor = FSM::Adapter::ISF->new(%args)->parse_file($path);
my $actor = FSM::Adapter::ISF->new(%args)->parse_source($text, $label);

my $lowered = FSM::Scheduler::ISF->new(%args)->lower($actor);
my $json    = FSM::Scheduler::ISF->new(%args)->report($actor);
```

The only public constructor option currently advertised for the ISF parser and
scheduler facades is `debug`.

## Lower Result

`FSM::Scheduler::ISF->lower($actor)` returns a hash with the advertised top-level
key:

```text
files
```

`files` is a hash reference mapping scheduled `.fsm` basenames to scheduled
`.fsm` source text. The generated `.fsm` text is a reviewable compiler artifact
and then flows through the existing `.fsm` pipeline.

The full lower-result hash is not yet a broad public API beyond the advertised
keys.

## Schedule Report

`FSM::Scheduler::ISF->report($actor)` and `--emit-schedule-json` produce a
machine-readable schedule report.

The bounded public top-level key family is:

```text
source
scheduled_fsm
clock
reset
watchdog
port_count
inputs
outputs
state_count
inferred_storage
transactions
dt_blocks
compile_issues
```

Current bounded nested summary families:

```text
reset: name, kind, polarity
inferred_storage entries: name, kind, optional width
transactions entries: name, states, count
dt_blocks entries: name, kind, assignments
```

The schedule report is not yet a frozen full schema. Downstream consumers should
use the advertised contract metadata instead of assuming every current field,
ordering detail, generated state name, or private lowering decision is permanent.

## Non-Public Internals

These are not stable public interfaces yet:

- The raw actor hash returned by the parser as a whole.
- `FSM::Scheduler::ISF::LoweringIR` internals.
- Emitter-private state objects.
- Any unadvertised keys in the lower-result hash or schedule report.

## Evolution Rule

This contract evolves with R14 implementation work.

When an ISF slice changes a downstream-visible behavior, update together:

- [docs/ISF_PUBLIC_INTERFACE_CONTRACT.md](ISF_PUBLIC_INTERFACE_CONTRACT.md)
- [docs/ISF_SPEC.md](ISF_SPEC.md)
- [docs/book/src/13-intent-scheduling.md](book/src/13-intent-scheduling.md)
- [perl/FSM/Support/ISFPublicInterfaceContract.pm](../perl/FSM/Support/ISFPublicInterfaceContract.pm)
- focused regression tests for the changed public surface

The goal is not to freeze ISF prematurely. The goal is to make every public
promise explicit, discoverable, and regression-backed as the ISF compiler grows.
