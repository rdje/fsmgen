package FSM::Support::CompositionReportContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use Scalar::Util qw(blessed);

our @EXPORT_OK = qw(
    build_composition_report_contract
    composition_report_contract_source
    composition_report_json_fragment_path
    composition_report_public_top_level_keys
    composition_report_raw_report_json_safe
    composition_report_raw_result_key
    sanitize_composition_report
);

sub build_composition_report_contract {
    return {
        schema_version => 1,
        status => 'bounded_public_json_fragment',
        contract_source => composition_report_contract_source(),
        report_builder => 'FSM::Composition::ProvenanceReportBuilder',
        raw_result_key => composition_report_raw_result_key(),
        json_fragment_path => composition_report_json_fragment_path(),
        tested_by => [
            't/307-composition-report-contract.t',
        ],
        public_top_level_keys => composition_report_public_top_level_keys(),
        raw_report_json_safe => composition_report_raw_report_json_safe(),
        sanitized_report_json_safe => JSON::PP::true,
        sanitizes_private_perl_objects => JSON::PP::true,
        stable_nested_content => JSON::PP::false,
        guidance => [
            'Treat raw composition_report as an in-process compatibility report, not as a JSON document.',
            'Use the normalized semantic JSON composition provenance_report fragment for serializable downstream interchange.',
            'Do not expose composition_plan objects as public JSON; promote explicit scalar/list/hash report facts instead.',
        ],
    };
}

sub composition_report_contract_source {
    return 'FSM::Support::CompositionReportContract';
}

sub composition_report_raw_result_key {
    return 'composition_report';
}

sub composition_report_json_fragment_path {
    return 'semantic_exports.normalized_semantic_json.semantic.composition.provenance_report';
}

sub composition_report_raw_report_json_safe {
    return JSON::PP::false;
}

sub composition_report_public_top_level_keys {
    return [
        qw(
            lane
            top_port_count
            resolved_link_count
            override_count
            block_count
            ports
            resolved_links
            override_events
            block_events
            port_origin_counts
            port_category_counts
            port_origin_examples
            resolved_link_origin_counts
            resolved_link_category_counts
            resolved_link_origin_examples
            override_kind_counts
            block_kind_counts
            override_kind_examples
            block_kind_examples
            ordered_port_origins
            ordered_resolved_link_origins
            ordered_override_kinds
            ordered_block_kinds
        )
    ];
}

sub sanitize_composition_report {
    my ($report) = @_;
    return undef unless ref($report) eq 'HASH';

    my %public_keys = map { $_ => 1 } @{composition_report_public_top_level_keys()};
    my %sanitized;
    for my $key (sort keys %$report) {
        next unless $public_keys{$key};
        my ($ok, $value) = _json_ready_value($report->{$key});
        next unless $ok;
        $sanitized{$key} = $value;
    }

    return \%sanitized;
}

sub _json_ready_value {
    my ($value) = @_;

    return (1, undef) unless defined $value;
    return (1, $value) if JSON::PP::is_bool($value);
    return (1, $value) unless ref($value);

    if (ref($value) eq 'HASH') {
        my %public;
        for my $key (sort keys %$value) {
            my ($ok, $child) = _json_ready_value($value->{$key});
            next unless $ok;
            $public{$key} = $child;
        }
        return (1, \%public);
    }

    if (ref($value) eq 'ARRAY') {
        my @public;
        for my $item (@$value) {
            my ($ok, $child) = _json_ready_value($item);
            push @public, $child if $ok;
        }
        return (1, \@public);
    }

    return (0, undef) if blessed($value);
    return (0, undef);
}

1;
