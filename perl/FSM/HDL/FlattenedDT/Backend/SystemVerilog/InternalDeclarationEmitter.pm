package FSM::HDL::FlattenedDT::Backend::SystemVerilog::InternalDeclarationEmitter;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::InternalDeclarationEmitter - Render direct generated-module internal declaration blocks

=head1 DESCRIPTION

Owns the bounded SystemVerilog internal declaration family for the older direct
generated module backend. This package renders internal storage declarations
and auxiliary helper registers from the enable-graph declaration plan after
module declaration rendering has established which names already belong to the
module boundary.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[InternalDeclarationEmitter.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

sub generate_internal_signal_declarations ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    my $declaration_plan = $ctx->{enable_graph_module_planning_support}->build_internal_signal_declaration_plan(
        $fsm_module,
        $ctx->{declared_port_signals},
    );
    my %signal_decls = %{$declaration_plan->{signal_decls} || {}};
    my %aux_decls = %{$declaration_plan->{aux_decls} || {}};
    my %signal_signed = %{$declaration_plan->{signal_signed} || {}};
    my %aux_signed = %{$declaration_plan->{aux_signed} || {}};
    my %signal_state_model = %{$declaration_plan->{signal_state_model} || {}};
    my %aux_state_model = %{$declaration_plan->{aux_state_model} || {}};

    return "" unless (%signal_decls || %aux_decls);

    my $hdl = "  // Internal signal declarations\n";
    $hdl .= _render_reg_declarations(\%signal_decls, \%signal_signed, \%signal_state_model);

    if (%aux_decls) {
        $hdl .= "  // Internal mux helper registers\n";
        $hdl .= _render_reg_declarations(\%aux_decls, \%aux_signed, \%aux_state_model);
    }
    $hdl .= "\n";

    return $hdl;
}

sub _render_reg_declarations ($decls, $signed_map = undef, $state_model_map = undef) {
    my $hdl = "";
    for my $signal_name (sort keys %{$decls || {}}) {
        my $width = $decls->{$signal_name} || 1;
        my $width_str = ($width > 1) ? "[" . ($width - 1) . ":0] " : "";
        my $signed_str = ($signed_map && ($signed_map->{$signal_name} // 0)) ? "signed " : "";
        my $state_model = $state_model_map ? $state_model_map->{$signal_name} : undef;
        my $type_keyword = _state_model_keyword($state_model);
        if (defined $type_keyword) {
            $hdl .= "  ${type_keyword} ${signed_str}${width_str}${signal_name};\n";
            next;
        }
        $hdl .= "  reg ${signed_str}${width_str}${signal_name};\n";
    }
    return $hdl;
}

sub _state_model_keyword ($state_model) {
    return undef unless defined $state_model && !ref($state_model);
    return 'bit' if $state_model eq 'two_state';
    return 'logic' if $state_model eq 'four_state';
    return undef;
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one internal-declaration emitter bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 generate_internal_signal_declarations

Renders the SystemVerilog internal declaration block from the enable-graph
declaration plan, including both direct internal storage declarations and the
auxiliary helper register family used by the direct generated-module backend.

=cut
