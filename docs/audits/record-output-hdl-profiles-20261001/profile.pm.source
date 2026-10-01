package FSM::Support::ISFHDLProfile;

use strict;
use warnings;
use Exporter 'import';
use FSM::Support::ISFInterfacePortMetadata qw(snapshot_interface_port_metadata);

our @EXPORT_OK = qw(assert_record_input_hdl_profile assert_record_port_hdl_profile);

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

# Keep the legacy input-only helper's behavior and diagnostic priority. New
# source consumers additionally guard declared outputs before HDL publication.
# A resolved output prototype is profile evidence, not source or writer admission.
sub assert_record_port_hdl_profile {
    my (%args) = @_;
    assert_record_input_hdl_profile(%args);
    my $target = $args{target_language} // '';
    return unless $target =~ /\A(?:verilog|v|vhdl)\z/;
    $target = 'verilog' if $target eq 'v';

    my $ports = snapshot_interface_port_metadata($args{interface_ports});
    for my $port (@{$ports // []}) {
        next unless $port->{direction} eq 'output'
            && ($port->{type_kind} // '') eq 'record';
        my $detail = $target eq 'verilog'
            ? 'Verilog-2005 record lowering is not implemented.'
            : 'VHDL record-output lowering is not implemented.';
        die "ISF actor '$args{actor_name}' record output '$port->{name}' (type '$port->{type}') "
            . "cannot generate target '$target': packed record outputs require SystemVerilog; "
            . "use --language systemverilog. $detail\n";
    }
    return;
}

1;
