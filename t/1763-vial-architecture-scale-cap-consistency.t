#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'perl';

use FSM::VIAL::ArchitectureScaleCapConsistency;
use FSM::VIAL::ArchitectureScaleCapPolicy qw(
    build_architecture_scale_cap_policy
);

my $class = 'FSM::VIAL::ArchitectureScaleCapConsistency';
my @dimensions = qw(
    boundary adjacent_excess diagnostics atomicity no_tool cleanup
    accepted_identity
);
my @runtime_profile_evidence = qw(
    t/1663-vial-architecture-scale-portable-runtime-materialization.t
    t/1672-vial-architecture-scale-portable-vhdl-runtime-materialization.t
    t/1676-vial-architecture-scale-osvvm-runtime-materialization.t
);
my %runtime_evidence = (
    boundary => [
        @runtime_profile_evidence, qw(
            t/1721-vial-runtime-trace-artifact-preflight.t
            t/1722-vial-runtime-result-artifact-preflight.t
            t/1723-vial-runtime-final-artifact-graph.t
            t/1729-vial-ghdl-result-record-admission.t
            t/1730-vial-ghdl-osvvm-provider-report-byte-preflight.t
            t/1748-vial-common-worker-artifact-file-admission.t
            t/1749-vial-common-worker-output-census-admission.t
            t/1751-vial-common-interrupted-stage-census-admission.t
            t/1753-vial-common-bounded-cleanup-admission.t
        )
    ],
    adjacent_excess => [
        @runtime_profile_evidence, qw(
            t/1720-vial-runtime-structural-artifact-preflight.t
            t/1721-vial-runtime-trace-artifact-preflight.t
            t/1722-vial-runtime-result-artifact-preflight.t
            t/1723-vial-runtime-final-artifact-graph.t
            t/1729-vial-ghdl-result-record-admission.t
            t/1730-vial-ghdl-osvvm-provider-report-byte-preflight.t
            t/1748-vial-common-worker-artifact-file-admission.t
            t/1749-vial-common-worker-output-census-admission.t
            t/1751-vial-common-interrupted-stage-census-admission.t
            t/1753-vial-common-bounded-cleanup-admission.t
        )
    ],
    diagnostics => [qw(
        t/1720-vial-runtime-structural-artifact-preflight.t
        t/1721-vial-runtime-trace-artifact-preflight.t
        t/1722-vial-runtime-result-artifact-preflight.t
        t/1723-vial-runtime-final-artifact-graph.t
        t/1724-vial-runtime-process-envelope.t
        t/1725-vial-ghdl-cleanup-diagnostic-authority.t
        t/1726-vial-ghdl-admission-cleanup-evidence.t
        t/1727-vial-ghdl-probe-timeout-diagnostic-authority.t
        t/1728-vial-ghdl-probe-abort-cleanup-authority.t
        t/1729-vial-ghdl-result-record-admission.t
        t/1730-vial-ghdl-osvvm-provider-report-byte-preflight.t
        t/1748-vial-common-worker-artifact-file-admission.t
        t/1749-vial-common-worker-output-census-admission.t
        t/1751-vial-common-interrupted-stage-census-admission.t
        t/1752-vial-common-worker-process-group-containment.t
        t/1753-vial-common-bounded-cleanup-admission.t
        t/1754-vial-common-detached-descendant-containment.t
        t/1755-vial-selected-tool-detached-descendant-containment.t
        t/1756-vial-selected-tool-host-observer-deadline.t
        t/1757-vial-selected-tool-monotonic-containment.t
        t/1758-vial-selected-tool-bounded-leader-reap.t
        t/1759-vial-selected-tool-interrupted-wait.t
        t/1760-vial-selected-tool-interrupted-observer-read.t
        t/1761-vial-selected-tool-observation-timeout-precedence.t
        t/1762-vial-selected-tool-interrupted-containment-pipe-read.t
    )],
    atomicity => [
        @runtime_profile_evidence, qw(
            t/1720-vial-runtime-structural-artifact-preflight.t
            t/1721-vial-runtime-trace-artifact-preflight.t
            t/1722-vial-runtime-result-artifact-preflight.t
            t/1723-vial-runtime-final-artifact-graph.t
            t/1724-vial-runtime-process-envelope.t
            t/1730-vial-ghdl-osvvm-provider-report-byte-preflight.t
            t/1744-vial-osvvm-persisted-command-authority.t
            t/1745-vial-osvvm-persisted-lifecycle-storage-admission.t
            t/1746-vial-osvvm-persisted-lifecycle-validation-admission.t
            t/1747-vial-osvvm-outer-persisted-json-file-admission.t
            t/1749-vial-common-worker-output-census-admission.t
            t/1751-vial-common-interrupted-stage-census-admission.t
            t/1752-vial-common-worker-process-group-containment.t
            t/1753-vial-common-bounded-cleanup-admission.t
            t/1754-vial-common-detached-descendant-containment.t
            t/1755-vial-selected-tool-detached-descendant-containment.t
            t/1756-vial-selected-tool-host-observer-deadline.t
            t/1757-vial-selected-tool-monotonic-containment.t
            t/1758-vial-selected-tool-bounded-leader-reap.t
            t/1759-vial-selected-tool-interrupted-wait.t
            t/1760-vial-selected-tool-interrupted-observer-read.t
            t/1761-vial-selected-tool-observation-timeout-precedence.t
            t/1762-vial-selected-tool-interrupted-containment-pipe-read.t
        )
    ],
    no_tool => [
        @runtime_profile_evidence,
        't/1720-vial-runtime-structural-artifact-preflight.t',
    ],
    cleanup => [
        @runtime_profile_evidence, qw(
            t/1724-vial-runtime-process-envelope.t
            t/1725-vial-ghdl-cleanup-diagnostic-authority.t
            t/1726-vial-ghdl-admission-cleanup-evidence.t
            t/1728-vial-ghdl-probe-abort-cleanup-authority.t
            t/1736-vial-ghdl-object-descriptor-admission.t
            t/1737-vial-ghdl-state-owner-file-admission.t
            t/1738-vial-ghdl-handle-state-scalar-types.t
            t/1739-vial-ghdl-request-scalar-types.t
            t/1747-vial-osvvm-outer-persisted-json-file-admission.t
            t/1748-vial-common-worker-artifact-file-admission.t
            t/1749-vial-common-worker-output-census-admission.t
            t/1751-vial-common-interrupted-stage-census-admission.t
            t/1752-vial-common-worker-process-group-containment.t
            t/1753-vial-common-bounded-cleanup-admission.t
            t/1754-vial-common-detached-descendant-containment.t
            t/1755-vial-selected-tool-detached-descendant-containment.t
            t/1756-vial-selected-tool-host-observer-deadline.t
            t/1757-vial-selected-tool-monotonic-containment.t
            t/1758-vial-selected-tool-bounded-leader-reap.t
            t/1759-vial-selected-tool-interrupted-wait.t
            t/1760-vial-selected-tool-interrupted-observer-read.t
            t/1761-vial-selected-tool-observation-timeout-precedence.t
            t/1762-vial-selected-tool-interrupted-containment-pipe-read.t
        )
    ],
    accepted_identity => [
        @runtime_profile_evidence, qw(
            t/1729-vial-ghdl-result-record-admission.t
            t/1731-vial-ghdl-capture-evidence-admission.t
            t/1732-vial-ghdl-state-evidence-admission.t
            t/1733-vial-ghdl-terminal-payload-resume-admission.t
            t/1734-vial-verilator-terminal-resume-admission.t
            t/1735-vial-ghdl-authority-object-admission.t
            t/1736-vial-ghdl-object-descriptor-admission.t
            t/1737-vial-ghdl-state-owner-file-admission.t
            t/1738-vial-ghdl-handle-state-scalar-types.t
            t/1739-vial-ghdl-request-scalar-types.t
            t/1740-vial-osvvm-persisted-request-scalar-types.t
            t/1741-vial-osvvm-persisted-provider-admission.t
            t/1742-vial-osvvm-persisted-ghdl-provider-admission.t
            t/1743-vial-osvvm-persisted-emission-identity.t
            t/1744-vial-osvvm-persisted-command-authority.t
            t/1745-vial-osvvm-persisted-lifecycle-storage-admission.t
            t/1746-vial-osvvm-persisted-lifecycle-validation-admission.t
            t/1747-vial-osvvm-outer-persisted-json-file-admission.t
            t/1748-vial-common-worker-artifact-file-admission.t
            t/1752-vial-common-worker-process-group-containment.t
            t/1753-vial-common-bounded-cleanup-admission.t
            t/1754-vial-common-detached-descendant-containment.t
        )
    ],
);
my %runtime_rationale = (
    boundary => 'exact runtime artifact, result, report, census, and cleanup ceilings admit at their selected boundary',
    adjacent_excess => 'the first structural, byte, count, report, census, and cleanup excess rejects',
    diagnostics => 'runtime limit, admission, timeout, containment, and cleanup failures retain stable authority',
    atomicity => 'known excess and supervised failure publish no partial graph and preserve authenticated staging',
    no_tool => 'all three profile preflights and structural excess reject before provider or selected-tool execution',
    cleanup => 'owned staging and supervised process domains are removed exactly or report bounded residue',
    accepted_identity => 'all three profiles and persisted runtime objects rebind to selected source, plan, tool, trace, result, and storage authority',
);
my @backend_profile_evidence = qw(
    t/1646-vial-architecture-scale-backend-emission-portable-sv.t
    t/1647-vial-architecture-scale-backend-emission-portable-vhdl.t
    t/1648-vial-architecture-scale-backend-emission-osvvm.t
    t/1649-vial-architecture-scale-backend-emission-native-uvm.t
    t/1650-vial-architecture-scale-backend-emission-family-qualification.t
);
my @backend_hardening_evidence = qw(
    t/1716-vial-backend-portable-sv-cap-order.t
    t/1717-vial-backend-portable-vhdl-cap-order.t
    t/1718-vial-backend-osvvm-provider-admission-order.t
    t/1719-vial-backend-native-uvm-cap-order.t
);
my %backend_evidence = (
    boundary => [@backend_profile_evidence],
    adjacent_excess => [
        @backend_profile_evidence, @backend_hardening_evidence,
    ],
    diagnostics => [
        @backend_profile_evidence, @backend_hardening_evidence,
    ],
    atomicity => [
        @backend_profile_evidence, @backend_hardening_evidence,
    ],
    no_tool => [
        @backend_profile_evidence, @backend_hardening_evidence,
    ],
    cleanup => [@backend_profile_evidence],
    accepted_identity => [
        @backend_profile_evidence,
        't/1718-vial-backend-osvvm-provider-admission-order.t',
    ],
);
my %backend_rationale = (
    boundary => 'each selected backend profile admits its exact owned artifact-graph boundary',
    adjacent_excess => 'the first unowned shape, generated-byte, map, inventory, or adapter excess rejects',
    diagnostics => 'profile-local negotiation, byte, map, inventory, and provider diagnostics retain stable paths',
    atomicity => 'known backend excess publishes no partial source, map, artifact graph, or provider evidence',
    no_tool => 'pure emitters start no runtime and known OSVVM foundation excess does not verify its provider',
    cleanup => 'accepted, rejected, and consumer-failure staging is same-volume and removed exactly',
    accepted_identity => 'selected artifact, source-map, provider, validation, and review identities are deterministic and profile-local',
);
my @checking_model_evidence = qw(
    t/1630-vial-architecture-scale-checking-models.t
    t/1711-vial-execution-model-cardinality-preflight.t
);
my %checking_model_evidence = (
    boundary => [$checking_model_evidence[0]],
    adjacent_excess => [@checking_model_evidence],
    diagnostics => [@checking_model_evidence],
    atomicity => [@checking_model_evidence],
    no_tool => [@checking_model_evidence],
    cleanup => [$checking_model_evidence[0]],
    accepted_identity => [@checking_model_evidence],
);
my %checking_model_rationale = (
    boundary => 'both selected checking-model axes admit their exact provider-free oracle limits',
    adjacent_excess => 'the first model instance or scalar state cell excess rejects',
    diagnostics => 'checking-model limit, oracle, and staging failures retain stable diagnostics',
    atomicity => 'compact model excess performs no model normalization and publishes no ExecutionIR or plan',
    no_tool => 'the complete checking-model ladder uses a provider-free oracle and starts no external tool',
    cleanup => 'accepted and consumer-failure staging is same-volume and residue-free',
    accepted_identity => 'accepted construction, evaluation, rerun, plan, and compact-preflight identities are deterministic',
);
my @checking_fault_evidence = qw(
    t/1633-vial-architecture-scale-checking-faults.t
    t/1714-vial-execution-fault-cardinality-preflight.t
);
my %checking_fault_evidence = (
    boundary => [$checking_fault_evidence[0]],
    adjacent_excess => [@checking_fault_evidence],
    diagnostics => [@checking_fault_evidence],
    atomicity => [@checking_fault_evidence],
    no_tool => [@checking_fault_evidence],
    cleanup => [$checking_fault_evidence[0]],
    accepted_identity => [@checking_fault_evidence],
);
my %checking_fault_rationale = (
    boundary => 'the selected fault axis admits its exact provider-free lifecycle limit',
    adjacent_excess => 'the first excess fault rejects before fault normalization',
    diagnostics => 'fault limit, lifecycle-oracle, and staging failures retain stable diagnostics',
    atomicity => 'compact fault excess performs no fault normalization and publishes no ExecutionIR or plan',
    no_tool => 'the complete fault ladder uses a provider-free lifecycle oracle and starts no external tool',
    cleanup => 'accepted and consumer-failure fault staging is same-volume and residue-free',
    accepted_identity => 'accepted fault construction, evaluation, rerun, plan, and compact-preflight identities are deterministic',
);
my @checking_randomness_evidence = qw(
    t/1634-vial-architecture-scale-checking-random-replay.t
    t/1715-vial-execution-random-occurrence-preflight.t
);
my %checking_randomness_evidence = (
    boundary => [$checking_randomness_evidence[0]],
    adjacent_excess => [@checking_randomness_evidence],
    diagnostics => [@checking_randomness_evidence],
    atomicity => [@checking_randomness_evidence],
    no_tool => [@checking_randomness_evidence],
    cleanup => [$checking_randomness_evidence[0]],
    accepted_identity => [@checking_randomness_evidence],
);
my %checking_randomness_rationale = (
    boundary => 'the selected route admits 8,440 occurrences, rejects 8,441 on plan bytes, and records 65,536-occurrence preflight dominance',
    adjacent_excess => 'the first route-plan or random-occurrence excess rejects before forbidden materialization',
    diagnostics => 'plan-byte, occurrence-limit, replay-oracle, and staging failures retain stable diagnostics',
    atomicity => 'known route or occurrence excess publishes no ExecutionIR, plan, replay, or checking result',
    no_tool => 'the complete random/replay proofs are provider-free and start no external tool',
    cleanup => 'accepted and consumer-failure random staging is same-volume and residue-free',
    accepted_identity => 'accepted workload, evaluation, rerun, replay, plan, and compact-preflight identities are deterministic',
);
my @checking_scoreboard_evidence = qw(
    t/1631-vial-architecture-scale-checking-scoreboards.t
    t/1690-vial-semantic-scoreboard-capacity-order.t
    t/1712-vial-execution-scoreboard-cardinality-preflight.t
);
my %checking_scoreboard_evidence = (
    boundary => [@checking_scoreboard_evidence[0, 1]],
    adjacent_excess => [@checking_scoreboard_evidence],
    diagnostics => [@checking_scoreboard_evidence],
    atomicity => [@checking_scoreboard_evidence],
    no_tool => [@checking_scoreboard_evidence],
    cleanup => [$checking_scoreboard_evidence[0]],
    accepted_identity => [@checking_scoreboard_evidence],
);
my %checking_scoreboard_rationale = (
    boundary => 'both selected scoreboard axes admit their exact provider-free limits, including semantic capacity admission',
    adjacent_excess => 'the first semantic scalar, scoreboard instance, or aggregate capacity excess rejects',
    diagnostics => 'semantic, execution, FIFO-oracle, and staging failures retain stable diagnostics',
    atomicity => 'known excess publishes no semantic report, normalized scoreboards, ExecutionIR, plan, or checking result',
    no_tool => 'the complete scoreboard ladder, semantic order, and compact preflight start no external tool',
    cleanup => 'accepted and consumer-failure scoreboard staging is same-volume and residue-free',
    accepted_identity => 'accepted construction, semantic, evaluation, rerun, plan, and compact-preflight identities are deterministic',
);
my @checking_coverage_evidence = qw(
    t/1632-vial-architecture-scale-checking-coverage.t
    t/1691-vial-semantic-cross-max-bins-order.t
    t/1713-vial-execution-coverage-cardinality-preflight.t
);
my %checking_coverage_evidence = (
    boundary => [@checking_coverage_evidence[0, 1]],
    adjacent_excess => [@checking_coverage_evidence],
    diagnostics => [@checking_coverage_evidence],
    atomicity => [@checking_coverage_evidence],
    no_tool => [@checking_coverage_evidence],
    cleanup => [$checking_coverage_evidence[0]],
    accepted_identity => [@checking_coverage_evidence],
);
my %checking_coverage_rationale = (
    boundary => 'static-domain and semantic scalar limits admit exactly while the coverpoint route freezes lower source-byte dominance',
    adjacent_excess => 'the first static-domain, semantic scalar, defensive coverpoint, or parser-route excess rejects',
    diagnostics => 'fixture-envelope, parser-source, semantic, execution, coverage-oracle, and staging failures retain stable diagnostics',
    atomicity => 'known excess publishes no unadmitted source, semantic report, normalized coverage, ExecutionIR, plan, or checking result',
    no_tool => 'the complete coverage ladder, parser boundary, semantic order, and compact preflight start no external tool',
    cleanup => 'accepted and consumer-failure coverage staging is same-volume and residue-free',
    accepted_identity => 'accepted construction, semantic, evaluation, rerun, plan, and compact-preflight identities are deterministic',
);
my @bridge_profile_evidence = qw(
    t/1602-vial-architecture-scale-bridge-fanout.t
);
my %bridge_profile_evidence = map {
    $_ => [@bridge_profile_evidence]
} @dimensions;
my %bridge_profile_rationale = (
    boundary => 'the selected single-unit and single-domain bridge profiles admit at their exact limits',
    adjacent_excess => 'the first second unit or domain rejects before normalized manifest construction',
    diagnostics => 'profile excess retains its stable bridge capability diagnostic and semantic path',
    atomicity => 'profile rejection publishes empty metrics and no manifest or report identity',
    no_tool => 'every bridge construction has no backend or external-tool selector and uses the reviewed in-process route',
    cleanup => 'accepted and consumer-failure bridge staging is same-volume and residue-free',
    accepted_identity => 'accepted construction, manifest, report, input, and review-route identities are deterministic',
);
my @bridge_serialized_evidence = qw(
    t/1602-vial-architecture-scale-bridge-fanout.t
    t/1704-hial-vial-bridge-serialized-manifest-terminal-authority.t
);
my %bridge_serialized_evidence = (
    boundary => [@bridge_serialized_evidence],
    adjacent_excess => [@bridge_serialized_evidence],
    diagnostics => [@bridge_serialized_evidence],
    atomicity => [@bridge_serialized_evidence],
    no_tool => [$bridge_serialized_evidence[0]],
    cleanup => [$bridge_serialized_evidence[0]],
    accepted_identity => [@bridge_serialized_evidence],
);
my %bridge_serialized_rationale = (
    boundary => 'the exact workload ladder and terminal observer both admit a 16777216-byte canonical manifest',
    adjacent_excess => 'the enclosing route and terminal observer both reject the first complete valid record above the byte cap',
    diagnostics => 'workload and terminal checks retain the authoritative bridge limit diagnostic and manifest-root locus',
    atomicity => 'terminal and enclosing rejections publish no manifest, report, metrics, or identities',
    no_tool => 'the exact serialized-manifest workload carries no backend or external-tool selector',
    cleanup => 'serialized-manifest workload success and consumer failure are same-volume and residue-free',
    accepted_identity => 'the exact workload identities and terminal canonical SHA are deterministic and byte-equal',
);
my @bridge_normalized_evidence = qw(
    t/1602-vial-architecture-scale-bridge-fanout.t
    t/1694-hial-vial-bridge-configuration-cap-order.t
    t/1695-hial-vial-bridge-endpoint-cap-order.t
    t/1696-hial-vial-bridge-observation-cap-order.t
    t/1697-hial-vial-bridge-probe-cap-order.t
    t/1698-hial-vial-bridge-type-cap-order.t
    t/1699-hial-vial-bridge-transaction-cap-order.t
    t/1700-hial-vial-bridge-event-cap-order.t
    t/1701-hial-vial-bridge-residue-cap-order.t
    t/1702-hial-vial-bridge-backend-binding-cap-order.t
    t/1703-hial-vial-bridge-source-map-cap-order.t
);
my %bridge_normalized_evidence = (
    boundary => [$bridge_normalized_evidence[0]],
    adjacent_excess => [@bridge_normalized_evidence],
    diagnostics => [@bridge_normalized_evidence],
    atomicity => [@bridge_normalized_evidence],
    no_tool => [$bridge_normalized_evidence[0]],
    cleanup => [$bridge_normalized_evidence[0]],
    accepted_identity => [@bridge_normalized_evidence],
);
my %bridge_normalized_rationale = (
    boundary => 'the exact workload ladder admits all ten normalized collection axes at their selected limits',
    adjacent_excess => 'the exact ladder plus ten order witnesses reject each first constructible excess, including the 16386 binding shape',
    diagnostics => 'every collection retains the authoritative bridge limit code, count message, and normalized path',
    atomicity => 'every collection excess publishes no manifest or report, and the exact route withholds metrics and identities',
    no_tool => 'the exact normalized-collection workload carries no backend or external-tool selector',
    cleanup => 'normalized-collection workload success and consumer failure are same-volume and residue-free',
    accepted_identity => 'the exact ladder and ten representative accepted controls retain deterministic byte-equal manifest/report identities',
);
my @execution_profile_evidence = qw(
    t/1603-vial-architecture-scale-execution-foundation.t
    t/1616-vial-architecture-scale-execution-scenario-qualification.t
    t/1617-vial-architecture-scale-execution-scenario-limit.t
    t/1618-vial-architecture-scale-execution-scenario-over-limit.t
    t/1705-vial-execution-selected-domain-cap-order.t
);
my %execution_profile_evidence = (
    boundary => [@execution_profile_evidence[2, 4]],
    adjacent_excess => [@execution_profile_evidence[0, 3, 4]],
    diagnostics => [@execution_profile_evidence[0, 3, 4]],
    atomicity => [@execution_profile_evidence[0, 3, 4]],
    no_tool => [@execution_profile_evidence[0, 1, 3, 4]],
    cleanup => [$execution_profile_evidence[1]],
    accepted_identity => [@execution_profile_evidence[1, 2, 4]],
);
my %execution_profile_rationale = (
    boundary => 'the exact 4096-scenario limit and fixed one-fixture, one-unit, one-domain profile admit',
    adjacent_excess => '4097 scenarios reject, fixed-scalar over-limit shapes stay caller-sealed, and defensive second unit/domain inputs reject',
    diagnostics => 'caller-sealed shape, scenario-limit, unit-reference, and domain-limit failures retain stable loci',
    atomicity => 'unowned shapes construct no workload while execution excess publishes no ExecutionIR, plan, or metrics',
    no_tool => 'workload specifications and ordinary execution arguments carry no backend, provider, or tool selector',
    cleanup => 'qualification staging success and consumer failure are same-volume and residue-free',
    accepted_identity => 'qualification, exact-limit, and ordinary fixed-profile plans retain deterministic identities',
);
my %verified_evidence = (
    backend_artifact_graph => \%backend_evidence,
    bridge_normalized_collections => \%bridge_normalized_evidence,
    bridge_profile_cardinality => \%bridge_profile_evidence,
    bridge_serialized_manifest => \%bridge_serialized_evidence,
    checking_coverage => \%checking_coverage_evidence,
    checking_faults => \%checking_fault_evidence,
    checking_models => \%checking_model_evidence,
    checking_randomness => \%checking_randomness_evidence,
    checking_scoreboards => \%checking_scoreboard_evidence,
    execution_profile_selection => \%execution_profile_evidence,
    runtime_stream_envelopes => \%runtime_evidence,
);
my %verified_rationale = (
    backend_artifact_graph => \%backend_rationale,
    bridge_normalized_collections => \%bridge_normalized_rationale,
    bridge_profile_cardinality => \%bridge_profile_rationale,
    bridge_serialized_manifest => \%bridge_serialized_rationale,
    checking_coverage => \%checking_coverage_rationale,
    checking_faults => \%checking_fault_rationale,
    checking_models => \%checking_model_rationale,
    checking_randomness => \%checking_randomness_rationale,
    checking_scoreboards => \%checking_scoreboard_rationale,
    execution_profile_selection => \%execution_profile_rationale,
    runtime_stream_envelopes => \%runtime_rationale,
);

sub dies {
    my ($code) = @_;
    local $@;
    eval { $code->(); 1 };
    return $@;
}

subtest 'sealed report enumerates every selected group and closeout dimension' => sub {
    my $policy = build_architecture_scale_cap_policy();
    my $report = $class->build;

    is(
        $report->{schema},
        'fsmgen.vial_architecture_scale_cap_consistency.v1',
        'consistency report has one versioned schema',
    );
    is($report->{decision}, $policy->{decision},
        'consistency report retains the policy decision');
    is_deeply($report->{required_dimensions}, \@dimensions,
        'closeout dimensions are closed and ordered');
    is_deeply(
        [sort keys %{$report->{groups}}],
        [sort keys %{$policy->{groups}}],
        'every selected policy group enters the consistency report',
    );

    my %expected_axes;
    for my $family (sort keys %{$policy->{axis_groups}}) {
        for my $axis (sort keys %{$policy->{axis_groups}{$family}}) {
            push @{$expected_axes{$policy->{axis_groups}{$family}{$axis}}},
                "$family/$axis";
        }
    }

    my @missing_evidence;
    for my $name (sort keys %{$report->{groups}}) {
        my $group = $report->{groups}{$name};
        is_deeply($group->{axes}, $expected_axes{$name},
            "$name retains its exact ordered axes");
        is($group->{declared_authority},
            $policy->{groups}{$name}{declared_authority},
            "$name retains its declared authority");
        is($group->{implementation_leaf},
            $policy->{groups}{$name}{implementation_leaf},
            "$name retains its implementation leaf");
        is_deeply($group->{candidate_evidence},
            $policy->{groups}{$name}{evidence},
            "$name retains candidate evidence without upgrading it");
        is_deeply([sort keys %{$group->{dimensions}}],
            [sort @dimensions],
            "$name cannot omit a closeout dimension");
        for my $dimension (@dimensions) {
            my $verified = exists($verified_evidence{$name});
            my $expected_status = $verified
                ? 'verified' : 'pending_independent_verification';
            my $expected_evidence = $verified
                ? $verified_evidence{$name}{$dimension} : [];
            is($group->{dimensions}{$dimension}{status}, $expected_status,
                "$name/$dimension has its sealed verification state");
            is_deeply(
                $group->{dimensions}{$dimension}{evidence},
                $expected_evidence,
                "$name/$dimension has its exact evidence join",
            );
            is(
                $group->{dimensions}{$dimension}{rationale},
                $verified
                    ? $verified_rationale{$name}{$dimension}
                    : 'policy citations are candidates, not dimension proof',
                "$name/$dimension has its exact evidence rationale",
            );
        }
        push @missing_evidence,
            grep { !-f $_ } @{$group->{candidate_evidence}};
    }
    is_deeply(\@missing_evidence, [],
        'every policy candidate-evidence path exists');

    my %joined = map { $_ => 1 }
        map { @{$runtime_evidence{$_}} } @dimensions;
    my @expected_join = (
        @runtime_profile_evidence,
        map {
            sprintf 't/%04d-%s', $_, runtime_leaf_suffix($_)
        } (1720 .. 1749, 1751 .. 1762),
    );
    is_deeply(
        [sort keys %joined], [sort @expected_join],
        'runtime join covers every selected profile and completed leaf once',
    );
    is_deeply(
        [grep { !-f $_ } sort keys %joined], [],
        'every sealed runtime evidence path exists',
    );

    my %backend_join = map { $_ => 1 }
        map { @{$backend_evidence{$_}} } @dimensions;
    is_deeply(
        [sort keys %backend_join],
        [sort @backend_profile_evidence, @backend_hardening_evidence],
        'backend join covers every profile proof and completed hardening leaf',
    );
    is_deeply(
        [grep { !-f $_ } sort keys %backend_join], [],
        'every sealed backend evidence path exists',
    );

    my %checking_model_join = map { $_ => 1 }
        map { @{$checking_model_evidence{$_}} } @dimensions;
    is_deeply(
        [sort keys %checking_model_join],
        [sort @checking_model_evidence],
        'checking-model join covers its foundation and preflight hardener',
    );
    is_deeply(
        [grep { !-f $_ } sort keys %checking_model_join], [],
        'every sealed checking-model evidence path exists',
    );

    my %checking_fault_join = map { $_ => 1 }
        map { @{$checking_fault_evidence{$_}} } @dimensions;
    is_deeply(
        [sort keys %checking_fault_join],
        [sort @checking_fault_evidence],
        'checking-fault join covers its foundation and preflight hardener',
    );
    is_deeply(
        [grep { !-f $_ } sort keys %checking_fault_join], [],
        'every sealed checking-fault evidence path exists',
    );

    my %checking_randomness_join = map { $_ => 1 }
        map { @{$checking_randomness_evidence{$_}} } @dimensions;
    is_deeply(
        [sort keys %checking_randomness_join],
        [sort @checking_randomness_evidence],
        'checking-randomness join covers its replay and preflight witnesses',
    );
    is_deeply(
        [grep { !-f $_ } sort keys %checking_randomness_join], [],
        'every sealed checking-randomness evidence path exists',
    );

    my %checking_scoreboard_join = map { $_ => 1 }
        map { @{$checking_scoreboard_evidence{$_}} } @dimensions;
    is_deeply(
        [sort keys %checking_scoreboard_join],
        [sort @checking_scoreboard_evidence],
        'checking-scoreboard join covers its FIFO, semantic, and preflight witnesses',
    );
    is_deeply(
        [grep { !-f $_ } sort keys %checking_scoreboard_join], [],
        'every sealed checking-scoreboard evidence path exists',
    );

    my %checking_coverage_join = map { $_ => 1 }
        map { @{$checking_coverage_evidence{$_}} } @dimensions;
    is_deeply(
        [sort keys %checking_coverage_join],
        [sort @checking_coverage_evidence],
        'checking-coverage join covers its oracle, semantic, and preflight witnesses',
    );
    is_deeply(
        [grep { !-f $_ } sort keys %checking_coverage_join], [],
        'every sealed checking-coverage evidence path exists',
    );

    my %bridge_profile_join = map { $_ => 1 }
        map { @{$bridge_profile_evidence{$_}} } @dimensions;
    is_deeply(
        [sort keys %bridge_profile_join],
        [sort @bridge_profile_evidence],
        'bridge-profile join covers its exact fanout witness once',
    );
    is_deeply(
        [grep { !-f $_ } sort keys %bridge_profile_join], [],
        'every sealed bridge-profile evidence path exists',
    );

    my %bridge_serialized_join = map { $_ => 1 }
        map { @{$bridge_serialized_evidence{$_}} } @dimensions;
    is_deeply(
        [sort keys %bridge_serialized_join],
        [sort @bridge_serialized_evidence],
        'serialized-manifest join covers the exact workload and terminal witnesses',
    );
    is_deeply(
        [grep { !-f $_ } sort keys %bridge_serialized_join], [],
        'every sealed serialized-manifest evidence path exists',
    );

    my %bridge_normalized_join = map { $_ => 1 }
        map { @{$bridge_normalized_evidence{$_}} } @dimensions;
    is_deeply(
        [sort keys %bridge_normalized_join],
        [sort @bridge_normalized_evidence],
        'normalized-collection join covers the exact ladder and ten order witnesses',
    );
    is_deeply(
        [grep { !-f $_ } sort keys %bridge_normalized_join], [],
        'every sealed normalized-collection evidence path exists',
    );

    my %execution_profile_join = map { $_ => 1 }
        map { @{$execution_profile_evidence{$_}} } @dimensions;
    is_deeply(
        [sort keys %execution_profile_join],
        [sort @execution_profile_evidence],
        'execution-profile join covers the fixed-scalar and scenario witnesses',
    );
    is_deeply(
        [grep { !-f $_ } sort keys %execution_profile_join], [],
        'every sealed execution-profile evidence path exists',
    );

    is($report->{calibration}{evidence_role},
        'historical_measurement_only',
        'calibration stays measurement evidence');
    is($report->{calibration}{cap_proof_status}, 'incomplete',
        'pending dimensions keep cap proof incomplete');
    is($report->{calibration}{disposition},
        'blocked_pending_current_cap_verification',
        'historical publication cannot be dispositioned prematurely');
    is($report->{calibration}{prohibited_relabel}, 'cap_implementation',
        'the historical publication nonclaim remains explicit');
};

subtest 'callers cannot inject authority or mutate the sealed report' => sub {
    like(dies(sub { $class->build({groups => {}}) }),
        qr/requires no arguments/,
        'callers cannot inject a policy or evidence map');
    like(dies(sub {
        FSM::VIAL::ArchitectureScaleCapConsistency::build('borrowed');
    }), qr/requires the exact class invocant/,
        'borrowed invocants fail closed');

    {
        package Local::CapConsistencySubclass;
        our @ISA = ('FSM::VIAL::ArchitectureScaleCapConsistency');
    }
    like(dies(sub { Local::CapConsistencySubclass->build }),
        qr/requires the exact class invocant/,
        'subclass invocants fail closed');

    my $first = $class->build;
    my ($first_group) = sort keys %{$first->{groups}};
    my $sealed_status =
        $first->{groups}{$first_group}{dimensions}{cleanup}{status};
    $first->{groups}{$first_group}{dimensions}{cleanup}{status} =
        $sealed_status eq 'verified'
            ? 'pending_independent_verification'
            : 'verified';
    push @{$first->{groups}{$first_group}{candidate_evidence}}, 'caller';
    $first->{calibration}{disposition} = 'reusable';
    my $second = $class->build;
    is($second->{groups}{$first_group}{dimensions}{cleanup}{status},
        $sealed_status,
        'returned dimension mutation cannot enter authority');
    ok(!(grep { $_ eq 'caller' }
        @{$second->{groups}{$first_group}{candidate_evidence}}),
        'returned evidence mutation cannot enter authority');
    is($second->{calibration}{disposition},
        'blocked_pending_current_cap_verification',
        'returned calibration mutation cannot bypass the barrier');

    my $assert = $class->can('_assert_report');
    ok(defined($assert), 'private sealed-report assertion is available');

    my $omitted_runtime = $class->build;
    pop @{$omitted_runtime->{groups}{runtime_stream_envelopes}
        {dimensions}{boundary}{evidence}};
    like(dies(sub { $assert->($omitted_runtime) }),
        qr/runtime_stream_envelopes\/boundary' contradicts the sealed evidence authority/,
        'callers cannot omit sealed runtime evidence');

    my $foreign_runtime = $class->build;
    push @{$foreign_runtime->{groups}{runtime_stream_envelopes}
        {dimensions}{cleanup}{evidence}}, 't/foreign-runtime-evidence.t';
    like(dies(sub { $assert->($foreign_runtime) }),
        qr/runtime_stream_envelopes\/cleanup' contradicts the sealed evidence authority/,
        'callers cannot add foreign runtime evidence');

    my $omitted_backend = $class->build;
    pop @{$omitted_backend->{groups}{backend_artifact_graph}
        {dimensions}{adjacent_excess}{evidence}};
    like(dies(sub { $assert->($omitted_backend) }),
        qr/backend_artifact_graph\/adjacent_excess' contradicts the sealed evidence authority/,
        'callers cannot omit sealed backend evidence');

    my $foreign_backend = $class->build;
    push @{$foreign_backend->{groups}{backend_artifact_graph}
        {dimensions}{accepted_identity}{evidence}},
        't/foreign-backend-evidence.t';
    like(dies(sub { $assert->($foreign_backend) }),
        qr/backend_artifact_graph\/accepted_identity' contradicts the sealed evidence authority/,
        'callers cannot add foreign backend evidence');

    my $omitted_checking_model = $class->build;
    pop @{$omitted_checking_model->{groups}{checking_models}
        {dimensions}{adjacent_excess}{evidence}};
    like(dies(sub { $assert->($omitted_checking_model) }),
        qr/checking_models\/adjacent_excess' contradicts the sealed evidence authority/,
        'callers cannot omit sealed checking-model evidence');

    my $foreign_checking_model = $class->build;
    push @{$foreign_checking_model->{groups}{checking_models}
        {dimensions}{accepted_identity}{evidence}},
        't/foreign-checking-model-evidence.t';
    like(dies(sub { $assert->($foreign_checking_model) }),
        qr/checking_models\/accepted_identity' contradicts the sealed evidence authority/,
        'callers cannot add foreign checking-model evidence');

    my $omitted_checking_fault = $class->build;
    pop @{$omitted_checking_fault->{groups}{checking_faults}
        {dimensions}{adjacent_excess}{evidence}};
    like(dies(sub { $assert->($omitted_checking_fault) }),
        qr/checking_faults\/adjacent_excess' contradicts the sealed evidence authority/,
        'callers cannot omit sealed checking-fault evidence');

    my $foreign_checking_fault = $class->build;
    push @{$foreign_checking_fault->{groups}{checking_faults}
        {dimensions}{accepted_identity}{evidence}},
        't/foreign-checking-fault-evidence.t';
    like(dies(sub { $assert->($foreign_checking_fault) }),
        qr/checking_faults\/accepted_identity' contradicts the sealed evidence authority/,
        'callers cannot add foreign checking-fault evidence');

    my $omitted_checking_randomness = $class->build;
    pop @{$omitted_checking_randomness->{groups}{checking_randomness}
        {dimensions}{adjacent_excess}{evidence}};
    like(dies(sub { $assert->($omitted_checking_randomness) }),
        qr/checking_randomness\/adjacent_excess' contradicts the sealed evidence authority/,
        'callers cannot omit sealed checking-randomness evidence');

    my $foreign_checking_randomness = $class->build;
    push @{$foreign_checking_randomness->{groups}{checking_randomness}
        {dimensions}{accepted_identity}{evidence}},
        't/foreign-checking-randomness-evidence.t';
    like(dies(sub { $assert->($foreign_checking_randomness) }),
        qr/checking_randomness\/accepted_identity' contradicts the sealed evidence authority/,
        'callers cannot add foreign checking-randomness evidence');

    my $omitted_checking_scoreboard = $class->build;
    pop @{$omitted_checking_scoreboard->{groups}{checking_scoreboards}
        {dimensions}{adjacent_excess}{evidence}};
    like(dies(sub { $assert->($omitted_checking_scoreboard) }),
        qr/checking_scoreboards\/adjacent_excess' contradicts the sealed evidence authority/,
        'callers cannot omit sealed checking-scoreboard evidence');

    my $foreign_checking_scoreboard = $class->build;
    push @{$foreign_checking_scoreboard->{groups}{checking_scoreboards}
        {dimensions}{accepted_identity}{evidence}},
        't/foreign-checking-scoreboard-evidence.t';
    like(dies(sub { $assert->($foreign_checking_scoreboard) }),
        qr/checking_scoreboards\/accepted_identity' contradicts the sealed evidence authority/,
        'callers cannot add foreign checking-scoreboard evidence');

    my $omitted_checking_coverage = $class->build;
    pop @{$omitted_checking_coverage->{groups}{checking_coverage}
        {dimensions}{adjacent_excess}{evidence}};
    like(dies(sub { $assert->($omitted_checking_coverage) }),
        qr/checking_coverage\/adjacent_excess' contradicts the sealed evidence authority/,
        'callers cannot omit sealed checking-coverage evidence');

    my $foreign_checking_coverage = $class->build;
    push @{$foreign_checking_coverage->{groups}{checking_coverage}
        {dimensions}{accepted_identity}{evidence}},
        't/foreign-checking-coverage-evidence.t';
    like(dies(sub { $assert->($foreign_checking_coverage) }),
        qr/checking_coverage\/accepted_identity' contradicts the sealed evidence authority/,
        'callers cannot add foreign checking-coverage evidence');

    my $omitted_bridge_profile = $class->build;
    pop @{$omitted_bridge_profile->{groups}{bridge_profile_cardinality}
        {dimensions}{adjacent_excess}{evidence}};
    like(dies(sub { $assert->($omitted_bridge_profile) }),
        qr/bridge_profile_cardinality\/adjacent_excess' verified evidence must be one non-empty array/,
        'callers cannot empty sealed bridge-profile evidence');

    my $foreign_bridge_profile = $class->build;
    push @{$foreign_bridge_profile->{groups}{bridge_profile_cardinality}
        {dimensions}{accepted_identity}{evidence}},
        't/foreign-bridge-profile-evidence.t';
    like(dies(sub { $assert->($foreign_bridge_profile) }),
        qr/bridge_profile_cardinality\/accepted_identity' contradicts the sealed evidence authority/,
        'callers cannot add foreign bridge-profile evidence');

    my $omitted_bridge_serialized = $class->build;
    pop @{$omitted_bridge_serialized->{groups}{bridge_serialized_manifest}
        {dimensions}{no_tool}{evidence}};
    like(dies(sub { $assert->($omitted_bridge_serialized) }),
        qr/bridge_serialized_manifest\/no_tool' verified evidence must be one non-empty array/,
        'callers cannot empty sealed serialized-manifest evidence');

    my $foreign_bridge_serialized = $class->build;
    push @{$foreign_bridge_serialized->{groups}{bridge_serialized_manifest}
        {dimensions}{accepted_identity}{evidence}},
        't/foreign-bridge-serialized-evidence.t';
    like(dies(sub { $assert->($foreign_bridge_serialized) }),
        qr/bridge_serialized_manifest\/accepted_identity' contradicts the sealed evidence authority/,
        'callers cannot add foreign serialized-manifest evidence');

    my $omitted_bridge_normalized = $class->build;
    pop @{$omitted_bridge_normalized->{groups}{bridge_normalized_collections}
        {dimensions}{no_tool}{evidence}};
    like(dies(sub { $assert->($omitted_bridge_normalized) }),
        qr/bridge_normalized_collections\/no_tool' verified evidence must be one non-empty array/,
        'callers cannot empty sealed normalized-collection evidence');

    my $foreign_bridge_normalized = $class->build;
    push @{$foreign_bridge_normalized->{groups}{bridge_normalized_collections}
        {dimensions}{accepted_identity}{evidence}},
        't/foreign-bridge-normalized-evidence.t';
    like(dies(sub { $assert->($foreign_bridge_normalized) }),
        qr/bridge_normalized_collections\/accepted_identity' contradicts the sealed evidence authority/,
        'callers cannot add foreign normalized-collection evidence');

    my $omitted_execution_profile = $class->build;
    pop @{$omitted_execution_profile->{groups}{execution_profile_selection}
        {dimensions}{cleanup}{evidence}};
    like(dies(sub { $assert->($omitted_execution_profile) }),
        qr/execution_profile_selection\/cleanup' verified evidence must be one non-empty array/,
        'callers cannot empty sealed execution-profile cleanup evidence');

    my $foreign_execution_profile = $class->build;
    push @{$foreign_execution_profile->{groups}{execution_profile_selection}
        {dimensions}{accepted_identity}{evidence}},
        't/foreign-execution-profile-evidence.t';
    like(dies(sub { $assert->($foreign_execution_profile) }),
        qr/execution_profile_selection\/accepted_identity' contradicts the sealed evidence authority/,
        'callers cannot add foreign execution-profile evidence');

    my $missing = $class->build;
    delete $missing->{groups}{$first_group}{dimensions}{cleanup};
    like(dies(sub { $assert->($missing) }),
        qr/dimensions is missing field 'cleanup'/,
        'missing dimensions fail closed');

    my $forged = $class->build;
    $forged->{groups}{$first_group}{dimensions}{cleanup} = {
        status => 'verified',
        evidence => ['t/1685-vial-architecture-scale-cap-policy.t'],
        rationale => 'caller supplied',
    };
    like(dies(sub { $assert->($forged) }),
        qr/cleanup' contradicts the sealed evidence authority/,
        'callers cannot promote a dimension through the private validator');

    my $extra = $class->build;
    $extra->{unexpected} = 1;
    like(dies(sub { $assert->($extra) }),
        qr/consistency report has unknown field 'unexpected'/,
        'unknown report fields fail closed');

    my $premature = $class->build;
    $premature->{calibration}{disposition} = 'reusable';
    like(dies(sub { $assert->($premature) }),
        qr/calibration disposition contradicts verification state/,
        'premature calibration disposition fails closed');
};

done_testing;

sub runtime_leaf_suffix {
    my ($number) = @_;
    my %suffix = map { /^t\/(\d+)-(.*)\.t\z/ ? ($1 => $2) : () }
        map { @{$runtime_evidence{$_}} } @dimensions;
    die "runtime evidence omits t/$number\n" unless exists $suffix{$number};
    return "$suffix{$number}.t";
}
