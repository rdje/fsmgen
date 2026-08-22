# Balanced Portable Composition

The balanced portable workload is qualification infrastructure for proving that
the six orthogonal VIAL architecture-scale families compose correctly. It is
not a public fixture-building API, supported-capacity promise, performance
result, or runtime result. Decision `0077` gives it a dedicated caller-sealed
revision-2 bridge instead of weakening either the public AHB bridge or the
private-nonportable revision-1 scale route.

## Closed construction boundary

`FSM::VIAL::ArchitectureScaleBalancedPortable` owns the only canonical
composer. `construct` accepts the frozen checked-AHB HIAL and VIAL texts,
verifies their complete byte identities, and generates one ordinary
repository-relative `.isf`/`.vial` pair. A caller cannot supply SemanticIR, a
bridge manifest, ExecutionIR, a plan, gate reports, or requested counts.

`build` evaluates a fresh substantive gate from each completed family before
the balanced route becomes reachable:

- semantic catalog: the 32-record-field gate;
- bridge fanout: the 256-endpoint, one-unit/one-domain gate;
- execution graph: the 2,048-binding gate;
- checking state: the 1,024-occurrence generated/replayed gate;
- backend emission: the portable-SystemVerilog artifact-graph gate; and
- runtime stream: the 10,000-record provider-free input gate.

Each full report must match its closed family, axis, level, schema, successful
status, empty diagnostics, and family-specific semantic oracle. The composer
stores the report digest and selected projection; it never accepts cached or
injected evidence. After those prerequisites pass, the private route parses and
lowers HIAL, parses VIAL, uses the revision-2 bridge, binds ExecutionIR, and
constructs the target-neutral plan.

## Exact interaction proof

`evaluate` rebuilds each canonical stage twice and compares complete stage
bytes. It then creates a strict replay manifest for every keyed choice, rebuilds
the route a third time, normalizes only the generated/replayed origin marker,
and requires plan equality.

The report derives this complete vector from the produced bridge, ExecutionIR,
and plan rather than copying the catalog request:

| Resource | Derived value |
| --- | ---: |
| selected units / domains | 1 / 1 |
| endpoints / events / probes | 128 / 128 / 32 |
| transactions / fields | 16 / 1,744 (109 each) |
| scenarios / operations | 32 / 1,024 |
| total / simultaneously live fibers | 128 / 32 |
| bindings / execution types | 2,048 / 512 |
| models / scalar cells | 32 / 512 |
| scoreboards / total declared capacity | 32 / 4,096 |
| coverpoints / authored bins | 256 / 4,096 |
| faults / keyed random occurrences | 32 / 1,024 |

The binding equation is `1 unit + 1 domain + 126 data endpoints + 32 probes +
16 aliases + 1,744 fields + 128 events = 2,048`. Every field is backed by a
real endpoint; there are no event-input, adapter-state, comment, path, or opaque
padding bindings.

Count equality alone is insufficient. The evaluator also verifies:

- `drive → sample → react → check` logical-time order and the exact stable
  tie-break fields;
- per-scenario fiber counts `32, 4, 4, 4, then 3 × 28` and operation counts
  `60, 32, 32, 32, then 31 × 28`;
- 32 sixteen-cell models with exercised increment assignments;
- 32 capacity-128 scoreboards with expect/start/check structure;
- 256 coverpoints with sixteen authored bins each and 32 one-cycle faults; and
- 1,024 unique `sha256_counter_rejection_v1` occurrences, 32 per scenario,
  with normalized generated/replayed plan equality.

## Qualified portable-SystemVerilog boundary

`FSM::VIAL::ArchitectureScaleBalancedPortableEmission` is the sole owner of
balanced structural emission. `evaluate` accepts only the canonical
construction. It freshly reruns the six-family composition, derives backend
inputs through `PlanBuilder`, and asks the portable-SystemVerilog backend to
admit the complete revision-2 bridge, ExecutionIR, and input projection. A
capability string by itself is never sufficient.

The backend qualification entrypoint is caller-sealed and distinct from public
`emit`. The latter continues to reject this private profile. Before rendering,
the sealed path independently checks the exact protocol facts, one unit and
domain, 128 endpoints, 32 probes, 16 transactions and their 1,744 fields, 128
events, 2,048 bindings, relations, known values, all 1,024 operations, and the
canonical backend inputs. Fifteen exact negotiated requirements must all be
satisfied; approximation and native-only fallbacks are empty.

One successful evaluation freezes this structural artifact graph:

| Evidence | Exact value |
| --- | ---: |
| total artifacts / SystemVerilog sources | 8 / 3 |
| source bytes | 503,279 |
| source-map entries | 3,605 |
| mapped operation IDs | 1,024 |
| mapped binding IDs | 2,048 |

The three generated sources are the runtime package, the balanced DUT, and its
qualification testbench. The other five artifacts are the backend manifest,
source-map index, compile and run command descriptions, and tool-profile
evidence. Every artifact uses a repository-relative logical path and an
in-memory byte identity. Independent route and emission reruns must be byte
equal, every generated identifier must be legal and within the frozen limit,
and manifest/map/artifact references must close over exactly this graph.

Public bypass, unsealed calls, changed bridge facts, changed ExecutionIR
resources, changed backend-input bytes, report mutation, and construction
mutation all fail before a partial graph can escape. `with_staging` provides
the same repository-volume success/failure cleanup contract as composition.
This is deliberately stronger than label admission while remaining narrower
than product support.

## Repository-root example

Run this diagnostic from the repository root. It supplies no intermediate
evidence and therefore exercises the same closed composition boundary as the
qualification watcher:

```perl
use strict;
use warnings;
use FSM::VIAL::ArchitectureScaleBalancedPortable;
use FSM::VIAL::ArchitectureScaleBalancedPortableEmission;

sub read_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    return <$fh>;
}

my $class = 'FSM::VIAL::ArchitectureScaleBalancedPortable';
my $construction = $class->construct({
    reference_hial_text => read_raw('ppif/ahb_lite_subordinate.ppif'),
    reference_vial_text =>
        read_raw('vial/ahb_subordinate_base_output_arbitration.vial'),
});
my $report = $class->evaluate({construction => $construction});
die "balanced composition rejected\n" unless $report->{ok};
my $emission = 'FSM::VIAL::ArchitectureScaleBalancedPortableEmission'
    ->evaluate({construction => $construction});
die "balanced structural emission rejected\n" unless $emission->{ok};

printf "endpoints=%d transactions=%d fields/transaction=%d bindings=%d\n",
    $report->{metrics}{endpoints},
    $report->{metrics}{transactions},
    $report->{metrics}{fields_per_transaction}[0],
    $report->{metrics}{bindings};
printf "artifacts=%d sources=%d maps=%d\n",
    $emission->{artifact_oracle}{artifact_count},
    $emission->{artifact_oracle}{source_artifact_count},
    $emission->{artifact_oracle}{source_map_entries};
```

Run it as `perl -Iperl example.pl` if saved as `example.pl`. The output is:

```text
endpoints=128 transactions=16 fields/transaction=109 bindings=2048
artifacts=8 sources=3 maps=3605
```

`validate_report` does not merely check the report's shape or digest. It
defensively regenerates the complete evaluation and accepts only canonical byte
equality. Direct calls to the private canonical route, bridge seal, or execution
seal fail. `with_staging` delegates to the repository-local scale staging
contract, verifies same-volume placement, sanitizes consumer failures, and
removes the exact staging tree after success or failure.

Focused `t/1653-vial-balanced-portable-composition.t` owns composition
durability and falsification. Focused
`t/1654-vial-balanced-portable-emission.t` owns exact negotiation, structural
artifacts, map closure, mutation/public-bypass rejection, defensive report
regeneration, and cleanup. Impacted matrices independently retain the six
prerequisites and existing public/revision-1 behavior.

## Deliberate nonclaims

This profile ends at deterministic portable-SystemVerilog structural emission.
No external compiler or runtime executes, no trace is materialized, and no
result is produced. Public planning and emission, other backends, support,
performance, capacity, and reached-boundary claims remain unchanged. Unified
provider-free family qualification is active next under `.17.2.7.3`; it does
not widen this profile.
