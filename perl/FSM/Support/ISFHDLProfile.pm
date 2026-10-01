package FSM::Support::ISFHDLProfile;

use strict;
use warnings;
use Exporter 'import';
use FSM::Support::ISFInterfacePortMetadata qw(snapshot_interface_port_metadata);

our @EXPORT_OK = qw(assert_record_input_hdl_profile);

# Source parsing and schedule preview stay backend-neutral. The CLI and facade
# call this only when realizing HDL, using validated declared-port evidence.
# A Verilog compatibility emitter retaining packed typedefs is not a qualified
# Verilog-2005 implementation of those inputs.
sub assert_record_input_hdl_profile {
    my (%args) = @_;
    return unless ($args{target_language} // '') =~ /\A(?:verilog|v)\z/;

    my $ports = snapshot_interface_port_metadata($args{interface_ports});
    for my $port (@{$ports // []}) {
        next unless $port->{direction} eq 'input'
            && ($port->{type_kind} // '') eq 'record';
        die "ISF actor '$args{actor_name}' record input '$port->{name}' (type '$port->{type}') "
            . "cannot generate target 'verilog': packed record inputs require SystemVerilog; "
            . "use --language systemverilog. Verilog-2005 record lowering is not implemented.\n";
    }
    return;
}

1;
