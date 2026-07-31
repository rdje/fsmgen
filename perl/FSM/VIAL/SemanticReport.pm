package FSM::VIAL::SemanticReport;

use strict;
use warnings;

sub build {
    my ($class, $semantic_ir) = @_;
    die "SemanticReport requires exact FSM::VIAL::SemanticIR\n"
        unless ref($semantic_ir) eq 'FSM::VIAL::SemanticIR';

    my $data = $semantic_ir->as_hashref;
    my @unresolved;
    my @packages = map { _package_summary($_, \@unresolved) } @{$data->{packages}};
    my $report = {
        schema_version => 1,
        language => 'vial',
        language_version => 1,
        profile => $data->{profile},
        root_source => {
            source_name => $data->{root_source}{source_name},
            content_sha256 => $data->{root_source}{content_sha256},
        },
        sources => [map {
            {
                source_name => $_->{source_name},
                content_sha256 => $_->{content_sha256},
            }
        } @{$data->{sources}}],
        packages => \@packages,
        required_capabilities => [@{$data->{required_capabilities}}],
        unresolved_bridge_refs => \@unresolved,
        diagnostics => [],
    };
    return _clone($report);
}

sub _package_summary {
    my ($package, $unresolved) = @_;
    return {
        semantic_id => $package->{semantic_id},
        name => $package->{name},
        source_name => $package->{source_name},
        imports => [map {
            {
                alias => $_->{alias},
                source_name => $_->{source_name},
                package_id => $_->{package_id},
            }
        } @{$package->{imports}}],
        types => [_named_summaries($package->{types})],
        transactions => [_named_summaries($package->{transactions})],
        models => [_named_summaries($package->{models})],
        scoreboards => [_named_summaries($package->{scoreboards})],
        fixtures => [map { _fixture_summary($_, $unresolved) } @{$package->{fixtures}}],
    };
}

sub _named_summaries {
    my ($items) = @_;
    return map {
        {
            semantic_id => $_->{semantic_id},
            name => $_->{name},
        }
    } @{$items};
}

sub _fixture_summary {
    my ($fixture, $unresolved) = @_;
    my $dut = $fixture->{dut};

    push @{$unresolved}, {
        fixture_id => $fixture->{semantic_id},
        kind => 'unit',
        alias => $dut->{name},
        bridge_ref => $dut->{unit_bridge_ref},
        expected_type => undef,
        access => undef,
    };
    push @{$unresolved}, map {
        {
            fixture_id => $fixture->{semantic_id},
            kind => 'domain',
            alias => $_->{name},
            bridge_ref => $_->{bridge_ref},
            expected_type => undef,
            access => undef,
        }
    } @{$dut->{domains}};
    push @{$unresolved}, map {
        {
            fixture_id => $fixture->{semantic_id},
            kind => 'endpoint',
            alias => $_->{name},
            bridge_ref => $_->{bridge_ref},
            expected_type => _clone($_->{type}),
            access => $_->{access},
        }
    } @{$dut->{endpoints}};
    push @{$unresolved}, map {
        {
            fixture_id => $fixture->{semantic_id},
            kind => 'transaction',
            alias => $_->{name},
            bridge_ref => $_->{bridge_ref},
            expected_type => $_->{transaction_id},
            access => undef,
        }
    } @{$dut->{transaction_bindings}};

    return {
        semantic_id => $fixture->{semantic_id},
        name => $fixture->{name},
        dut_name => $dut->{name},
        unit_bridge_ref => $dut->{unit_bridge_ref},
        domains => [map {
            {
                semantic_id => $_->{semantic_id},
                name => $_->{name},
            }
        } @{$dut->{domains}}],
        endpoints => [map {
            {
                semantic_id => $_->{semantic_id},
                name => $_->{name},
                type => _clone($_->{type}),
                access => $_->{access},
            }
        } @{$dut->{endpoints}}],
        transaction_bindings => [map {
            {
                semantic_id => $_->{semantic_id},
                name => $_->{name},
                transaction_id => $_->{transaction_id},
            }
        } @{$dut->{transaction_bindings}}],
        model_instances => [map {
            {
                semantic_id => $_->{semantic_id},
                name => $_->{name},
                model_id => $_->{model_id},
            }
        } @{$fixture->{instances}{model_instances}}],
        scoreboard_instances => [map {
            {
                semantic_id => $_->{semantic_id},
                name => $_->{name},
                scoreboard_id => $_->{scoreboard_id},
                transaction_id => $_->{transaction_id},
            }
        } @{$fixture->{instances}{scoreboard_instances}}],
        coverpoints => [map {
            {
                semantic_id => $_->{semantic_id},
                name => $_->{name},
                domain_id => $_->{domain_id},
                bin_count => scalar(@{$_->{bins}}),
            }
        } @{$fixture->{coverage}{coverpoints}}],
        crosses => [map {
            {
                semantic_id => $_->{semantic_id},
                name => $_->{name},
                point_count => scalar(@{$_->{point_ids}}),
                max_bins => $_->{max_bins},
            }
        } @{$fixture->{coverage}{crosses}}],
        faults => [map {
            {
                semantic_id => $_->{semantic_id},
                name => $_->{name},
                transaction_id => $_->{transaction_id},
                field_name => $_->{field_name},
                domain_id => $_->{domain_id},
                duration_cycles => $_->{duration_cycles},
            }
        } @{$fixture->{faults}}],
        choices => [map {
            {
                semantic_id => $_->{semantic_id},
                name => $_->{name},
                type => _clone($_->{type}),
                decision_id => $_->{decision_id},
                distribution => _clone($_->{distribution}),
            }
        } @{$fixture->{randomness}{choices}}],
        scenarios => [map {
            {
                semantic_id => $_->{semantic_id},
                name => $_->{name},
                domain_id => $_->{domain_id},
                timeout_cycles => $_->{timeout_cycles},
                action_count => $_->{action_count},
                fiber_count => $_->{fiber_count},
            }
        } @{$fixture->{scenarios}}],
    };
}

sub _clone {
    my ($value) = @_;
    return undef unless defined $value;
    return { map { $_ => _clone($value->{$_}) } sort keys %{$value} } if ref($value) eq 'HASH';
    return [map { _clone($_) } @{$value}] if ref($value) eq 'ARRAY';
    return $value;
}

1;
