package FSM::Composition::RealizedInstance;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

sub new ($class, %args) {
    return bless {
        kind => $args{kind},
        instance_name => $args{instance_name},
        module_name => $args{module_name},
        source_name => $args{source_name},
        interface_ports => $args{interface_ports} || [],
        port_bindings => $args{port_bindings} || [],
        module_info => $args{module_info},
        hdl_code => $args{hdl_code},
    }, $class;
}

sub kind ($self) { return $self->{kind} }
sub instance_name ($self) { return $self->{instance_name} }
sub module_name ($self) { return $self->{module_name} }
sub source_name ($self) { return $self->{source_name} }
sub interface_ports ($self) { return $self->{interface_ports} }
sub port_bindings ($self) { return $self->{port_bindings} }
sub module_info ($self) { return $self->{module_info} }
sub hdl_code ($self) { return $self->{hdl_code} }

1;
