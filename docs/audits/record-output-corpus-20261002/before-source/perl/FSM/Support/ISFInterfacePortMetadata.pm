package FSM::Support::ISFInterfacePortMetadata;

use strict;
use warnings;
use Carp qw(confess);
use Exporter 'import';
use Scalar::Util qw(refaddr);
use Storable qw(dclone);
use FSM::Package::AggregatePathSupport;

our @EXPORT_OK = qw(
    capture_interface_port_metadata
    snapshot_interface_port_metadata
    interface_port_metadata_contract
);

sub interface_port_metadata_contract {
    return {
        entry_keys => [qw(name direction width)],
        optional_entry_keys => [qw(type type_kind domain fields)],
        direction_values => [qw(input output)],
        type_kind_values => [qw(bit bits record)],
        field_keys => [qw(path width lsb msb signed)],
        optional_field_keys => ['state_model'],
        field_signed_values => [0, 1],
        field_state_model_values => [qw(two_state four_state)],
        shape => 'declared inputs in source order followed by declared outputs in source order; empty for a known empty interface; null when declaration metadata is unknown',
        field_layout => 'record scalar leaves in authored traversal order; port-relative member/item paths; first leaf most significant; inclusive packed ranges',
        meaning => 'declared ISF interface metadata; no inferred signals, private handoffs, source admission or hardware behavior is established by this projection',
    };
}

# The parser will supply its validated declarations. This producer is also
# tested on resolved record types before record source admission is enabled.
# It projects explicit properties rather than exporting parser/type objects.
sub capture_interface_port_metadata {
    my ($interface, $default_domain) = @_;
    return undef unless defined $interface;
    _require(ref($interface) eq 'HASH', 'expected declared interface');
    $interface = dclone($interface);
    _require(!defined($default_domain) || _identifier($default_domain), 'invalid default domain');
    my @ports;
    for my $pair (['inputs', 'input'], ['outputs', 'output']) {
        my ($key, $direction) = @$pair;
        _require(ref($interface->{$key}) eq 'ARRAY', "expected $key array");
        for my $port (@{$interface->{$key}}) {
            _require(ref($port) eq 'HASH', 'expected declared port');
            _require(_name($port->{name}), 'invalid declared port name');
            _require(_positive_integer($port->{width}), 'invalid declared port width');
            my %entry = (name => $port->{name}, direction => $direction, width => $port->{width});
            my $domain = defined($port->{domain}) ? $port->{domain} : $default_domain;
            $entry{domain} = $domain if defined $domain;
            if (exists $port->{type}) {
                $entry{type} = $port->{type};
                my $spec = $port->{type_spec};
                _require(ref($spec) eq 'HASH', "port '$port->{name}' lacks resolved type");
                my @paths;
                _collect_scalar_paths($spec, '', \@paths, {});
                _require(_positive_integer($port->{width}) && $port->{width} == $spec->{width},
                    "port '$port->{name}' type width disagrees");
                $entry{type_kind} = $spec->{kind};
                if ($spec->{kind} eq 'record') {
                    $entry{fields} = [map { _field_metadata($spec, $_) } @paths];
                } else {
                    _require($spec->{kind} eq 'bit' || $spec->{kind} eq 'bits',
                        "port '$port->{name}' unsupported root type");
                }
            } else {
                _require(!exists($port->{type_spec}), "port '$port->{name}' has type facts without an alias");
            }
            push @ports, \%entry;
        }
    }
    return snapshot_interface_port_metadata(\@ports);
}

sub _collect_scalar_paths {
    my ($spec, $path, $paths, $active) = @_;
    _require(ref($spec) eq 'HASH', 'invalid resolved member type');
    my $address = refaddr($spec);
    _require(!$active->{$address}, 'cyclic resolved type');
    local $active->{$address} = 1;
    _require(_positive_integer($spec->{width}), 'invalid resolved type width');
    my $kind = $spec->{kind} // '';
    if ($kind eq 'bit' || $kind eq 'bits') {
        _require($kind ne 'bit' || $spec->{width} == 1, 'bit type width must be one');
        _require(!exists($spec->{signed}) || _binary($spec->{signed}), 'invalid resolved signed property');
        _require(!exists($spec->{state_model}) || _state_model($spec->{state_model}), 'invalid resolved state model');
        push @$paths, $path;
        return;
    }
    my $width = 0;
    if ($kind eq 'record') {
        my ($members, $order) = @{$spec}{qw(members member_order)};
        _require(ref($members) eq 'HASH' && ref($order) eq 'ARRAY' && scalar(@$order),
            'record requires ordered members');
        _require(keys(%$members) == @$order, 'record member inventory disagrees');
        my %seen;
        for my $name (@$order) {
            _require(_identifier($name) && !$seen{$name}++ && exists($members->{$name}),
                'invalid or duplicate record member');
            _collect_scalar_paths($members->{$name}, "$path.$name", $paths, $active);
            $width += $members->{$name}{width};
        }
    } elsif ($kind eq 'list') {
        _require(length($path), 'list-root interface metadata remains unsupported');
        my $items = $spec->{items};
        _require(ref($items) eq 'ARRAY' && scalar(@$items), 'list requires ordered items');
        for my $index (0 .. $#$items) {
            _collect_scalar_paths($items->[$index], "$path\[$index\]", $paths, $active);
            $width += $items->[$index]{width};
        }
    } else {
        _require(0, 'unsupported resolved type kind');
    }
    _require($width == $spec->{width}, 'resolved aggregate width disagrees with members');
}

sub _field_metadata {
    my ($spec, $path) = @_;
    my $resolved = FSM::Package::AggregatePathSupport->resolve_packed_range(
        root_type_spec => $spec, path_text => $path,
    );
    _require($resolved->{ok}, 'declared record field has no packed range');
    my $leaf = $resolved->{type_spec};
    (my $relative_path = $path) =~ s/^\.//;
    my %field = (
        path => $relative_path, width => 0 + $resolved->{width},
        lsb => 0 + $resolved->{low}, msb => 0 + $resolved->{high},
        signed => ($leaf->{signed} // 0) ? 1 : 0,
    );
    $field{state_model} = $leaf->{state_model} if exists $leaf->{state_model};
    return \%field;
}

# Unknown provenance stays unknown. Known metadata is checked and rebuilt so
# each consumer receives a closed detached value, including nested fields.
sub snapshot_interface_port_metadata {
    my ($value) = @_;
    return undef unless defined $value;
    _require(ref($value) eq 'ARRAY', 'expected port metadata array');
    $value = dclone($value);
    my (@ports, %seen);
    my $outputs_started = 0;
    for my $port (@$value) {
        _require(ref($port) eq 'HASH', 'expected port metadata entry');
        _closed_keys($port, [qw(name direction width)], [qw(type type_kind domain fields)]);
        _require(_name($port->{name}) && !$seen{$port->{name}}++, 'invalid or duplicate port name');
        _require(defined($port->{direction}) && !ref($port->{direction})
            && scalar($port->{direction} =~ /\A(?:input|output)\z/), 'invalid direction');
        _require($port->{direction} ne 'input' || !$outputs_started, 'inputs must precede outputs');
        $outputs_started = 1 if $port->{direction} eq 'output';
        _require(_positive_integer($port->{width}), 'invalid port width');
        my %copy = (name => $port->{name}, direction => $port->{direction}, width => 0 + $port->{width});
        if (exists $port->{domain}) {
            _require(_identifier($port->{domain}), 'invalid domain');
            $copy{domain} = $port->{domain};
        }
        if (exists $port->{type}) {
            _require(defined($port->{type}) && !ref($port->{type})
                && scalar($port->{type} =~ /\A[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)?\z/), 'invalid type alias');
            _require(defined($port->{type_kind}) && !ref($port->{type_kind})
                && scalar($port->{type_kind} =~ /\A(?:bit|bits|record)\z/), 'invalid resolved type kind');
            _require($port->{type_kind} ne 'bit' || $port->{width} == 1, 'bit port width must be one');
            @copy{qw(type type_kind)} = @{$port}{qw(type type_kind)};
        } else {
            _require(!exists($port->{type_kind}) && !exists($port->{fields}), 'type facts require an alias');
        }
        if (($port->{type_kind} // '') eq 'record') {
            $copy{fields} = _snapshot_fields($port->{fields}, $port->{width});
        } else {
            _require(!exists($port->{fields}), 'scalar port cannot have record fields');
        }
        push @ports, \%copy;
    }
    return \@ports;
}

sub _snapshot_fields {
    my ($fields, $width) = @_;
    _require(ref($fields) eq 'ARRAY' && scalar(@$fields), 'record requires scalar field metadata');
    my (@copy, %seen);
    my $next_high = $width - 1;
    for my $field (@$fields) {
        _require(ref($field) eq 'HASH', 'expected scalar field entry');
        _closed_keys($field, [qw(path width lsb msb signed)], ['state_model']);
        my $path = $field->{path};
        _require(defined($path) && !ref($path)
            && $path =~ /\A[A-Za-z_]\w*(?:(?:\.[A-Za-z_]\w*)|(?:\[[0-9]+\]))*\z/
            && !$seen{$path}++, 'invalid or duplicate field path');
        _require(_positive_integer($field->{width}) && _nonnegative_integer($field->{lsb})
            && _nonnegative_integer($field->{msb}) && $field->{msb} == $next_high
            && $field->{msb} - $field->{lsb} + 1 == $field->{width}, 'field ranges do not form ordered packed layout');
        _require(_binary($field->{signed}), 'invalid scalar field signed property');
        my %entry = (path => $path, map { $_ => 0 + $field->{$_} } qw(width lsb msb signed));
        if (exists $field->{state_model}) {
            _require(_state_model($field->{state_model}), 'invalid scalar field state model');
            $entry{state_model} = $field->{state_model};
        }
        push @copy, \%entry;
        $next_high = $field->{lsb} - 1;
    }
    _require($next_high == -1, 'record field layout does not cover the port');
    return \@copy;
}

sub _closed_keys {
    my ($value, $required, $optional) = @_;
    my %allowed = map { $_ => 1 } (@$required, @$optional);
    _require(!grep(!exists($value->{$_}), @$required), 'missing metadata key');
    _require(!grep(!$allowed{$_}, keys %$value), 'unknown metadata key');
}

# Predicate results must be single values in argument-list context: a failed
# regex otherwise returns an empty list and shifts the diagnostic into slot 0.
sub _name { (defined($_[0]) && !ref($_[0]) && length($_[0])) ? 1 : 0 }
sub _identifier { (defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A[A-Za-z_]\w*\z/) ? 1 : 0 }
sub _positive_integer { (defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A[1-9][0-9]*\z/) ? 1 : 0 }
sub _nonnegative_integer { (defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A(?:0|[1-9][0-9]*)\z/) ? 1 : 0 }
sub _binary { (defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A[01]\z/) ? 1 : 0 }
sub _state_model { (defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A(?:two_state|four_state)\z/) ? 1 : 0 }
sub _require {
    confess "Invalid ISF interface port metadata: validation requires a predicate and message\n"
        unless @_ == 2;
    confess "Invalid ISF interface port metadata: $_[1]\n" unless $_[0];
}

1;
