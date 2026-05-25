package FSM::Composition::InterfacePortBuilder;

=head1 NAME

FSM::Composition::InterfacePortBuilder - Composition-side interface port helpers

=head1 DESCRIPTION

Builds realized child interface port objects from generated module metadata and
owns the shared interface-type and system-port ordering rules used while
planning compositions.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Composition::Port;
use FSM::IR::IntentHIR;

sub build_realized_child_interface_ports ($class, $module_info) {
    confess "InterfacePortBuilder requires a module_info hash"
        unless ref($module_info) eq 'HASH';

    my %ports;
    my $child_structural_rtl_ir = ref($module_info->{structural_rtl_ir}) eq 'HASH'
        ? $module_info->{structural_rtl_ir}
        : {};
    my $intent_hir = ref($module_info->{intent_hir}) eq 'HASH'
        ? $module_info->{intent_hir}
        : {};
    my $system_contract = FSM::IR::IntentHIR->system_contract_from_input(
        $intent_hir,
        $module_info->{system_contract} || {
            clock => 'clk',
            reset => 'rst_n',
            reset_keyword => 'areset',
            reset_kind => 'async',
            reset_active_level => 0,
            implicit => 1,
        },
    );
    my %system_port_type;
    $system_port_type{$system_contract->{clock}} = 'clock'
        if defined($system_contract->{clock}) && !ref($system_contract->{clock}) && length($system_contract->{clock});
    $system_port_type{$system_contract->{reset}} = 'reset'
        if defined($system_contract->{reset}) && !ref($system_contract->{reset}) && length($system_contract->{reset});

    if (ref($child_structural_rtl_ir->{ports}) eq 'ARRAY' && @{$child_structural_rtl_ir->{ports}}) {
        for my $entry (@{$child_structural_rtl_ir->{ports}}) {
            next unless defined($entry->{name}) && length($entry->{name});
            my $type = $entry->{type};
            $type = $system_port_type{$entry->{name}}
                if !defined($type) || $type eq '';
            $type = undef
                if defined($type) && ($type eq 'wire' || $type eq 'logic');

            $ports{$entry->{name}} = FSM::Composition::Port->new(
                name => $entry->{name},
                direction => ($entry->{direction} || 'input'),
                width => $entry->{width} || 1,
                signed => ($entry->{signed} // 0) ? 1 : 0,
                state_model => $entry->{state_model},
                declared_type_name => $entry->{declared_type_name},
                declared_type_spec => $entry->{declared_type_spec},
                type => $type,
                raw_token => undef,
                origin_kind => 'realized_child_interface_port',
            );
        }
    } else {
        for my $direction (qw(input output)) {
            my $list = $direction eq 'input'
                ? FSM::IR::IntentHIR->signal_analysis_entries_from_input($intent_hir, 'inputs')
                : FSM::IR::IntentHIR->signal_analysis_entries_from_input($intent_hir, 'outputs');
            $list = $direction eq 'input'
                ? ($module_info->{signal_analysis}{inputs} || [])
                : ($module_info->{signal_analysis}{outputs} || [])
                unless @$list;

            for my $entry (@$list) {
                $ports{$entry->{name}} = FSM::Composition::Port->new(
                    name => $entry->{name},
                    direction => $direction,
                    width => $entry->{width} || 1,
                    signed => 0,
                    state_model => $entry->{state_model},
                    declared_type_name => $entry->{declared_type_name},
                    declared_type_spec => $entry->{declared_type_spec},
                    type => $system_port_type{$entry->{name}},
                    raw_token => undef,
                    origin_kind => 'realized_child_interface_port',
                );
            }
        }
    }

    if ($system_contract->{declare_ports}) {
        for my $system_name (keys %system_port_type) {
            $ports{$system_name} //= FSM::Composition::Port->new(
                name => $system_name,
                direction => 'input',
                width => 1,
                signed => 0,
                type => $system_port_type{$system_name},
                raw_token => undef,
                origin_kind => 'realized_child_interface_port',
            );
        }
    }

    my @ordered_names = sort {
        $class->system_port_sort_key($ports{$a}) <=> $class->system_port_sort_key($ports{$b})
        ||
        $a cmp $b
    } keys %ports;

    return [map { $ports{$_} } @ordered_names];
}

sub system_port_sort_key ($class, $port) {
    my $type = _port_type($port);
    return 0 if ($type || '') eq 'clock';
    return 1 if ($type || '') eq 'reset';
    return 2;
}

sub normalized_interface_type ($class, $type) {
    return defined($type) && length($type) ? $type : 'data';
}

sub declared_type_name ($class, $port) {
    return undef unless defined $port;
    return $port->{declared_type_name}
        if ref($port) eq 'HASH' && exists $port->{declared_type_name};
    return $port->declared_type_name
        if ref($port) && ref($port) ne 'HASH' && $port->can('declared_type_name');
    return undef;
}

sub declared_type_spec ($class, $port) {
    return undef unless defined $port;
    return _clone_structured_value($port->{declared_type_spec})
        if ref($port) eq 'HASH' && exists $port->{declared_type_spec};
    return $port->declared_type_spec
        if ref($port) && ref($port) ne 'HASH' && $port->can('declared_type_spec');
    return undef;
}

sub declared_type_signature ($class, $port_or_spec) {
    my $spec = (
        ref($port_or_spec) eq 'HASH' && exists $port_or_spec->{kind}
            ? $port_or_spec
            : $class->declared_type_spec($port_or_spec)
    );
    return undef unless ref($spec) eq 'HASH';
    return _type_spec_signature($spec);
}

sub declared_type_label ($class, $port_or_contract) {
    my $name = $class->declared_type_name($port_or_contract);
    return $name if defined($name) && length($name);

    my $spec = (
        ref($port_or_contract) eq 'HASH' && exists $port_or_contract->{kind}
            ? $port_or_contract
            : $class->declared_type_spec($port_or_contract)
    );
    return undef unless ref($spec) eq 'HASH';
    return _type_spec_label($spec);
}

sub declared_type_conflicts ($class, $left, $right) {
    my $left_signature = $class->declared_type_signature($left);
    my $right_signature = $class->declared_type_signature($right);
    return 0 unless defined $left_signature && defined $right_signature;
    return $left_signature ne $right_signature ? 1 : 0;
}

sub uniform_declared_type_contract ($class, $ports, @additional_ports) {
    my @ports = ref($ports) eq 'ARRAY' ? @$ports : ($ports, @additional_ports);
    return {
        declared_type_name => undef,
        declared_type_spec => undef,
    } unless @ports;

    my @signatures;
    my @names;
    my $template_spec;
    for my $port (@ports) {
        my $signature = $class->declared_type_signature($port);
        return {
            declared_type_name => undef,
            declared_type_spec => undef,
        } unless defined $signature;

        push @signatures, $signature;
        push @names, $class->declared_type_name($port);
        $template_spec //= $class->declared_type_spec($port);
    }

    my %signatures = map { $_ => 1 } @signatures;
    return {
        declared_type_name => undef,
        declared_type_spec => undef,
    } unless keys(%signatures) == 1;

    my $uniform_name = $names[0];
    for my $name (@names) {
        if (!defined($uniform_name) || !defined($name) || $uniform_name ne $name) {
            $uniform_name = undef;
            last;
        }
    }

    return {
        declared_type_name => $uniform_name,
        declared_type_spec => _clone_structured_value($template_spec),
    };
}

sub _port_type ($port) {
    return undef unless defined $port;
    return $port->{type} if ref($port) eq 'HASH';
    return $port->type if ref($port) && $port->can('type');
    return undef;
}

sub _type_spec_signature ($value) {
    return 'undef' unless defined $value;

    if (ref($value) eq 'HASH') {
        return '{'.join(',', map {
            $_.'=>'. _type_spec_signature($value->{$_})
        } sort keys %$value).'}';
    }

    if (ref($value) eq 'ARRAY') {
        return '['.join(',', map { _type_spec_signature($_) } @$value).']';
    }

    return "$value";
}

sub _type_spec_label ($spec) {
    return 'unknown' unless ref($spec) eq 'HASH';

    my $kind = $spec->{kind} || '';
    if ($kind eq 'bit') {
        my $label = 'bit';
        $label = "signed $label" if $spec->{signed};
        $label = ($spec->{state_model} || '').' '.$label if defined $spec->{state_model};
        $label =~ s/\A\s+|\s+\z//g;
        return $label;
    }

    if ($kind eq 'bits') {
        my $label = 'bits['.($spec->{width} // '?').']';
        $label = "signed $label" if $spec->{signed};
        $label = ($spec->{state_model} || '').' '.$label if defined $spec->{state_model};
        $label =~ s/\A\s+|\s+\z//g;
        return $label;
    }

    if ($kind eq 'list') {
        return 'list<'.join(', ', map { _type_spec_label($_) } @{ $spec->{items} || [] }).'>';
    }

    if ($kind eq 'record') {
        return 'record{'.join(', ', map {
            $_.':'. _type_spec_label(($spec->{members} || {})->{$_})
        } @{ $spec->{member_order} || [] }).'}';
    }

    if ($kind eq 'deferred_imported_alias') {
        return $spec->{imported_type_ref} // 'deferred_imported_alias';
    }

    return $kind;
}

sub _clone_structured_value ($value) {
    return undef unless defined $value;

    if (ref($value) eq 'HASH') {
        return {
            map { $_ => _clone_structured_value($value->{$_}) } sort keys %$value
        };
    }

    if (ref($value) eq 'ARRAY') {
        return [ map { _clone_structured_value($_) } @$value ];
    }

    return $value;
}

1;

__END__

=head1 METHODS

=head2 build_realized_child_interface_ports

Builds the realized child interface-port list from structural IR first, then
falls back to intent and signal-analysis metadata when structural boundary data
is absent.

=head2 system_port_sort_key

Returns the stable sort key that keeps shared system ports ordered ahead of data
ports.

=head2 normalized_interface_type

Normalizes a missing or empty interface type into the default semantic C<data>
type.

=head2 declared_type_name / declared_type_spec / declared_type_signature / declared_type_label

Expose the bounded declared-type metadata and canonical comparison helpers now
used by typed composition matching and inference.

=head2 declared_type_conflicts

Returns true only when both compared ports preserve declared type specs and
those canonical specs differ.

=head2 uniform_declared_type_contract

Returns one shared declared-type contract only when every supplied port carries
the same declared type spec; otherwise returns an empty contract.

=head2 _port_type

Extracts the type field from a hash-backed or object-backed port entry.

=cut
