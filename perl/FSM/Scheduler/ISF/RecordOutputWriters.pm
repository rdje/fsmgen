package FSM::Scheduler::ISF::RecordOutputWriters;

use strict;
use warnings;
use Carp qw(confess);
use Storable qw(dclone);
use FSM::Support::ISFInterfacePortMetadata qw(capture_interface_port_metadata);
use FSM::Support::ISFRecordPortScopes qw(record_actor_scope);
use FSM::Composition::InterfacePortBuilder;
use FSM::Scheduler::ISF::PhysicalWriteDeclarations;
use FSM::Scheduler::ISF::PhysicalWriteTargets;
use FSM::Scheduler::ISF::SourceWriterOwners;
use FSM::Scheduler::ISF::WriterActivation;

# Inventory and its conservative admission consumer are private preparation.
# Neither an entry guard nor a source name alone proves exclusion.
sub inventory {
    my ($class, %args) = @_;
    _require(keys(%args) == 2 && ref($args{actor}) eq 'HASH' && ref($args{ir}) eq 'HASH',
        'requires resolved actor and realized module maps');
    my ($actor, $ir) = map { dclone($_) } @args{qw(actor ir)};
    _require(_identifier($actor->{actor_name}) && _identifier($ir->{actor_name})
        && $actor->{actor_name} eq $ir->{actor_name}, 'requires matching source/module identities');
    my $metadata = capture_interface_port_metadata($actor->{interface},
        ($actor->{clock_domains} || {})->{default});
    _require(ref($metadata) eq 'ARRAY', 'requires known declared interface facts');
    my @outputs = grep { $_->{direction} eq 'output'
        && ($_->{type_kind} // '') eq 'record' } @$metadata;
    return {module => $ir->{actor_name}, output_declarations => [], writers => []}
        unless @outputs;
    _require((($ir->{domain_partition} || {})->{kind} // '') ne 'multi_domain',
        'requires an actual realized clock-domain module');
    _require(ref($ir->{children} // {}) eq 'HASH' && !keys %{$ir->{children} // {}},
        'generated record-output mappings require separate qualification');

    my $scope = record_actor_scope(actor => $actor);
    my %ports;
    for my $port (@{_records($ir, 'ports')}) {
        _require(_identifier($port->{name}) && !exists($ports{$port->{name}}),
            'requires unique realized port identities');
        $ports{$port->{name}} = $port;
    }
    my %outputs = map { $_->{name} => $_ } @outputs;
    for my $output (@outputs) {
        my $name = $output->{name};
        my $port = $ports{$name};
        _require(ref($port) eq 'HASH' && ($port->{direction} // '') eq 'output',
            "record output '$name' lacks its realized output port");
        _require(defined($port->{width}) && !ref($port->{width})
            && $port->{width} =~ /\A[1-9][0-9]*\z/ && $port->{width} == $output->{width},
            "record output '$name' disagrees with its realized width");
        my $spec = $scope->{$name}{type_spec};
        if (exists $port->{type_spec}) {
            capture_interface_port_metadata({inputs => [], outputs => [{
                name => $name, width => $port->{width}, type => $output->{type},
                type_spec => $port->{type_spec},
            }]});
            _require(!FSM::Composition::InterfacePortBuilder->declared_type_conflicts(
                $spec, $port->{type_spec}), "record output '$name' disagrees with its realized type");
        }
        # Emitted ports carry aliases/widths, not recursive member layouts.
        # Match the resolved declaration before enriching this private copy.
        $port->{type_spec} = dclone($spec);
    }
    my $collection = FSM::Scheduler::ISF::PhysicalWriteDeclarations->collect($ir);
    for my $output (@outputs) {
        my $name = $output->{name};
        _require($collection->{declarations}{$name}{width_token} eq $output->{type},
            "record output '$name' disagrees with its emitted type token");
    }
    my $targets = FSM::Scheduler::ISF::PhysicalWriteDeclarations->target_contracts($ir);
    my @writers;
    for my $pair ([state => 'states'], [dt => 'dt_blocks']) {
        my ($kind, $key) = @$pair;
        for my $container (@{_records($ir, $key)}) {
            my $assignments = _records($container, 'assignments');
            for my $index (0 .. $#$assignments) {
                my $assignment = $assignments->[$index];
                my ($root) = $assignment->{lhs} =~ /\A([A-Za-z_]\w*)/;
                next unless $outputs{$root};
                push @writers, {
                    output => $root, target => dclone($targets->{$assignment->{lhs}}),
                    owner => FSM::Scheduler::ISF::SourceWriterOwners->resolve(
                        $ir, $actor, $kind, $container),
                    activation => FSM::Scheduler::ISF::WriterActivation->resolve(
                        $kind, $container, $index),
                    assignment => dclone($assignment),
                };
            }
        }
    }
    return {module => $ir->{actor_name}, output_declarations => \@outputs, writers => \@writers};
}

sub assert_admitted {
    my ($class, %args) = @_;
    # Always collect from actual source/module arguments. A supplied filtered
    # inventory cannot hide a writer before this pairwise check.
    my $inventory = $class->inventory(%args);
    my $writers = $inventory->{writers};
    for my $left_index (0 .. $#$writers) {
        for my $right_index ($left_index + 1 .. $#$writers) {
            my ($left, $right) = @{$writers}[$left_index, $right_index];
            next unless FSM::Scheduler::ISF::PhysicalWriteTargets->overlaps(
                $left->{target}, $right->{target});
            next if _ordered_state_pair($left, $right);
            confess "ISF module '$inventory->{module}' record output '$left->{output}' "
                . "cannot admit overlapping writers '" . _owner_label($left->{owner})
                . "' and '" . _owner_label($right->{owner})
                . "' to '$left->{assignment}{lhs}' and '$right->{assignment}{lhs}'; "
                . "use one ordered state controller or disjoint physical targets. "
                . "Qualified compatibility or exclusion is required.\n";
        }
    }
    return $inventory;
}

sub _ordered_state_pair {
    my ($left, $right) = @_;
    my ($a, $b) = ($left->{owner}, $right->{owner});
    return 0 unless $a->{container_kind} eq 'state' && $b->{container_kind} eq 'state'
        && $a->{source_kind} eq 'transaction' && $b->{source_kind} eq 'transaction'
        && $a->{container_name} ne $b->{container_name}
        && $left->{activation}{operator} eq '<-' && $right->{activation}{operator} eq '<-';
    # Different point-active states of this one source controller are exclusive.
    # Its entry condition and transaction-owned DTs confer no such guarantee.
    for my $key (qw(module domain source_kind source_name)) {
        return 0 unless ($a->{$key} // '') eq ($b->{$key} // '');
    }
    return 1;
}

sub _owner_label {
    my ($owner) = @_;
    return "$owner->{source_kind}/$owner->{source_name}/$owner->{container_kind}:$owner->{container_name}";
}

sub _records {
    my ($record, $key) = @_;
    _require(ref($record->{$key}) eq 'ARRAY'
        && !(grep { ref($_) ne 'HASH' } @{$record->{$key}}), "requires complete '$key' records");
    return $record->{$key};
}
sub _identifier {defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A[A-Za-z_]\w*\z/}
sub _require {
    confess "Invalid record-output writer inventory: validation requires predicate and message\n" unless @_ == 2;
    confess "Invalid record-output writer inventory: $_[1]\n" unless $_[0];
}

1;
