package FSM::Support::SerializableCompositionPlanSnapshot;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use FSM::Support::CompositionParameterContract qw(build_composition_parameter_contract);
use Scalar::Util qw(blessed);

our @EXPORT_OK = qw(
    build_serializable_composition_plan_snapshot
    build_serializable_composition_plan_snapshot_contract
    serializable_composition_plan_snapshot_collection_keys
    serializable_composition_plan_snapshot_contract_source
    serializable_composition_plan_snapshot_public_top_level_keys
    serializable_composition_plan_snapshot_summary_keys
);

sub serializable_composition_plan_snapshot_contract_source {
    return 'FSM::Support::SerializableCompositionPlanSnapshot';
}

sub build_serializable_composition_plan_snapshot_contract {
    return {
        schema_version => 1,
        composition_parameter_contract => build_composition_parameter_contract(),
        status => 'bounded_public',
        contract_source => serializable_composition_plan_snapshot_contract_source(),
        object_name => 'composition_plan_snapshot',
        report_source => serializable_composition_plan_snapshot_contract_source(),
        entrypoints => {
            in_process => [
                'FSM::Support::SerializableCompositionPlanSnapshot::build_serializable_composition_plan_snapshot(composition_plan => $result->{composition_plan})',
            ],
        },
        optional_top_level_keys => [qw(parameter_environment)],
        public_top_level_presence_keys => serializable_composition_plan_snapshot_public_top_level_keys(),
        summary_keys => serializable_composition_plan_snapshot_summary_keys(),
        collection_keys => serializable_composition_plan_snapshot_collection_keys(),
        source_object_class_when_present => 'FSM::Composition::Plan',
        json_safe_as_whole => JSON::PP::true,
        raw_plan_object_exported => JSON::PP::false,
        guidance => [
            'Use this snapshot for bounded composition-plan inspection instead of traversing the raw FSM::Composition::Plan object.',
            'The snapshot records stable scalar counts and shallow summaries for ports, links, nets, instances, and shared-datapath candidates.',
            'Deep typed objects inside the raw plan remain in-process implementation details and are not exported through this JSON-safe surface.',
        ],
    };
}

sub build_serializable_composition_plan_snapshot {
    my (%args) = @_;
    my $plan = $args{composition_plan} || $args{plan};
    my $present = defined($plan) ? JSON::PP::true : JSON::PP::false;

    my $ports = _plan_array($plan, 'ports');
    my $links = _plan_array($plan, 'links');
    my $resolved_links = _plan_array($plan, 'resolved_links');
    my $nets = _plan_array($plan, 'nets');
    my $instances = _plan_array($plan, 'instances');
    my $auxiliary_assignments = _plan_array($plan, 'auxiliary_assignments');
    my $shared_datapath_candidates = _plan_array($plan, 'shared_datapath_candidates');

    my $environment = _value($plan, 'parameter_environment');
    return {
        (defined($environment) ? (parameter_environment => JSON::PP->new->decode(
            JSON::PP->new->encode($environment))) : ()),
        composition_plan_snapshot_schema_version => 1,
        report_source => serializable_composition_plan_snapshot_contract_source(),
        contract_source => serializable_composition_plan_snapshot_contract_source(),
        present => $present,
        source_object_class => defined($plan) ? (blessed($plan) || ref($plan) || 'scalar') : undef,
        lane => _value($plan, 'lane'),
        top_name => _value($plan, 'top_name'),
        summary => {
            port_count => scalar(@$ports),
            link_count => scalar(@$links),
            resolved_link_count => scalar(@$resolved_links),
            net_count => scalar(@$nets),
            instance_count => scalar(@$instances),
            auxiliary_assignment_count => scalar(@$auxiliary_assignments),
            shared_datapath_candidate_count => scalar(@$shared_datapath_candidates),
        },
        top_ports => [map { _port_snapshot($_) } @$ports],
        links => [map { _link_snapshot($_) } @$links],
        resolved_links => [map { _resolved_link_snapshot($_) } @$resolved_links],
        nets => [map { _net_snapshot($_) } @$nets],
        instances => [map { _instance_snapshot($_) } @$instances],
        auxiliary_assignments => [map { _string_value($_) } @$auxiliary_assignments],
        shared_datapath_candidates => [map { _json_value($_) } @$shared_datapath_candidates],
    };
}

sub serializable_composition_plan_snapshot_public_top_level_keys {
    return [
        qw(
            composition_plan_snapshot_schema_version
            report_source
            contract_source
            present
            source_object_class
            lane
            top_name
            summary
            top_ports
            links
            resolved_links
            nets
            instances
            auxiliary_assignments
            shared_datapath_candidates
        ),
    ];
}

sub serializable_composition_plan_snapshot_summary_keys {
    return [
        qw(
            port_count
            link_count
            resolved_link_count
            net_count
            instance_count
            auxiliary_assignment_count
            shared_datapath_candidate_count
        ),
    ];
}

sub serializable_composition_plan_snapshot_collection_keys {
    return [
        qw(
            top_ports
            links
            resolved_links
            nets
            instances
            auxiliary_assignments
            shared_datapath_candidates
        ),
    ];
}

sub _plan_array {
    my ($plan, $method) = @_;
    return [] unless defined $plan;
    my $value;
    if (blessed($plan) && $plan->can($method)) {
        $value = $plan->$method();
    } elsif (ref($plan) eq 'HASH') {
        $value = $plan->{$method};
    }
    return ref($value) eq 'ARRAY' ? $value : [];
}

sub _value {
    my ($object, $name) = @_;
    return undef unless defined $object;
    return $object->$name() if blessed($object) && $object->can($name);
    return $object->{$name} if ref($object) eq 'HASH';
    return undef;
}

sub _port_snapshot {
    my ($port) = @_;
    my $width_contract = _value($port, 'width_contract');
    my $width_token = _value($port, 'width_token');
    return {
        (defined($width_contract) ? (width_contract => _detached_json_value($width_contract)) : ()),
        name => _value($port, 'name'),
        direction => _value($port, 'direction'),
        width => _value($port, 'width'),
        width_token => ref($width_token) ? _detached_json_value($width_token) : $width_token,
        signed => _bool(_value($port, 'signed')),
        type => _value($port, 'type'),
        binding_mode => _value($port, 'binding_mode'),
        origin_kind => _value($port, 'origin_kind'),
    };
}

sub _detached_json_value {
    my ($value) = @_;
    return JSON::PP->new->decode(JSON::PP->new->encode($value));
}

sub _link_snapshot {
    my ($link) = @_;
    return {
        source => _string_value(_value($link, 'source')),
        target => _string_value(_value($link, 'target')),
        origin_kind => _value($link, 'origin_kind'),
    };
}

sub _resolved_link_snapshot {
    my ($link) = @_;
    return _link_snapshot($link)
        unless ref($link) eq 'HASH';

    my $raw_link = $link->{link};
    return {
        source => _string_value(_endpoint_value($link->{source}) || _value($raw_link, 'source')),
        target => _string_value(_endpoint_value($link->{target}) || _value($raw_link, 'target')),
        origin_kind => _value($raw_link, 'origin_kind'),
    };
}

sub _endpoint_value {
    my ($endpoint) = @_;
    return undef unless ref($endpoint) eq 'HASH';
    return $endpoint->{raw} if defined $endpoint->{raw};
    return $endpoint->{key} if defined $endpoint->{key};
    return undef;
}

sub _net_snapshot {
    my ($net) = @_;
    return {
        name => _value($net, 'name'),
        width => _value($net, 'width'),
        source => _string_value(_value($net, 'source')),
        targets => [map { _string_value($_) } @{_array_value(_value($net, 'targets'))}],
        declaration_keyword => _value($net, 'declaration_keyword'),
        signed => _bool(_value($net, 'signed')),
        state_model => _value($net, 'state_model'),
        declared_type_name => _value($net, 'declared_type_name'),
    };
}

sub _instance_snapshot {
    my ($instance) = @_;
    my $interface_ports = _array_value(_value($instance, 'interface_ports'));
    my $port_bindings = _array_value(_value($instance, 'port_bindings'));
    my $parameter_overrides = _array_value(_value($instance, 'parameter_overrides'));

    return {
        kind => _value($instance, 'kind'),
        instance_name => _value($instance, 'instance_name'),
        module_name => _value($instance, 'module_name'),
        source_name => _value($instance, 'source_name'),
        interface_port_count => scalar(@$interface_ports),
        interface_port_names => [map { _value($_, 'name') } @$interface_ports],
        port_binding_count => scalar(@$port_bindings),
        parameter_override_count => scalar(@$parameter_overrides),
    };
}

sub _array_value {
    my ($value) = @_;
    return $value if ref($value) eq 'ARRAY';
    return [];
}

sub _bool {
    my ($value) = @_;
    return $value ? JSON::PP::true : JSON::PP::false;
}

sub _string_value {
    my ($value) = @_;
    return undef unless defined $value;
    return $value unless ref($value);
    return _json_value($value);
}

sub _json_value {
    my ($value) = @_;
    return undef unless defined $value;
    return $value unless ref($value);

    if (ref($value) eq 'ARRAY') {
        return [map { _json_value($_) } @$value];
    }

    if (ref($value) eq 'HASH') {
        return {map { $_ => _json_value($value->{$_}) } sort keys %$value};
    }

    return blessed($value) || ref($value);
}

1;

=head1 NAME

FSM::Support::SerializableCompositionPlanSnapshot - Detached composition plan inspection

=head1 DESCRIPTION

C<build_serializable_composition_plan_snapshot(composition_plan =E<gt> $plan)>
returns the bounded JSON-safe plan summary. Actual resolved plans optionally
include C<parameter_environment>; ordinary plans omit it. This field is copied
through JSON serialization, preserving nested JSON kinds and refusing non-JSON
references instead of silently dropping environment data. Hash-backed callers
receive the same copy boundary but must establish their own input provenance.
Top ports optionally preserve C<width_contract>; structured C<width_token>
and width contracts are copied through JSON with the same kind-preserving,
fail-closed boundary. Static port shapes remain unchanged.

C<build_serializable_composition_plan_snapshot_contract()> describes mandatory
and optional keys separately and embeds the shared
L<FSM::Support::CompositionParameterContract>. Snapshot inspection does not
enable parameter-bearing source planning, port specialization or HDL emission.

=cut
