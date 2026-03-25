package FSM::Composition::RTLChildRealizer;

=head1 NAME

FSM::Composition::RTLChildRealizer - Realizer for external RTL composition children

=head1 DESCRIPTION

Owns the bounded C<?rtl> child-realization family for composition. This
package takes already-loaded `.rtlif` interface metadata, projects it into the
active realized-child runtime carrier, and preserves the metadata provenance
needed by later planning and reporting layers.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Composition::RealizedInstance;

sub realize_rtl_child_instance ($class, %args) {
    my $rtl_interface_loader = $args{rtl_interface_loader}
        or confess "RTLChildRealizer requires an rtl_interface_loader";
    my $instance = $args{instance}
        or confess "RTLChildRealizer requires an instance";
    my $fsm_file = $args{fsm_file}
        or confess "RTLChildRealizer requires an fsm_file";
    my $composition_spec = $args{composition_spec};

    my $module_name = $instance->module_name;
    my $loaded = $rtl_interface_loader->load_interface(
        module_name => $module_name,
        source_file => $fsm_file,
        embedded_raw_ast => $composition_spec ? $composition_spec->raw_ast : undef,
    );

    return FSM::Composition::RealizedInstance->new(
        kind => 'rtl',
        instance_name => ($instance->name // $module_name),
        module_name => $module_name,
        source_name => undef,
        interface_ports => $loaded->{interface_ports},
        module_info => {
            module_name => $module_name,
            metadata_path => $loaded->{metadata_path},
            interface_kind => 'rtl_external',
        },
        hdl_code => undef,
    );
}

1;

__END__

=head1 METHODS

=head2 realize_rtl_child_instance

Loads one external RTL child interface through the active `.rtlif` loader and
returns the normalized L<FSM::Composition::RealizedInstance> used by later
composition planning/reporting code.

=cut
