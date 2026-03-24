package FSM::Composition::InterfacePortBuilder;

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
            reset_keyword => 'asreset',
            implicit => 1,
        },
    );
    my %system_port_type = (
        ($system_contract->{clock} => 'clock'),
        ($system_contract->{reset} => 'reset'),
    );

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

sub _port_type ($port) {
    return undef unless defined $port;
    return $port->{type} if ref($port) eq 'HASH';
    return $port->type if ref($port) && $port->can('type');
    return undef;
}

1;

__END__

=head1 NAME

FSM::Composition::InterfacePortBuilder - Composition-side interface port helpers

=head1 DESCRIPTION

This module owns the extracted composition interface-port projection rules used
while realizing generated children and normalizing interface metadata during
composition planning. It currently covers realized-child interface port
construction from generated-module metadata plus the shared interface-type and
system-port ordering helpers that composition planning still needs.

=cut
