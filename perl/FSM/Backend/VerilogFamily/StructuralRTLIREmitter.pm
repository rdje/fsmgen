package FSM::Backend::VerilogFamily::StructuralRTLIREmitter;

=head1 NAME

FSM::Backend::VerilogFamily::StructuralRTLIREmitter - Verilog-family structural RTL IR emitter

=head1 DESCRIPTION

Emits Verilog-family HDL text by walking the extracted forward
C<StructuralRTLIR> layer. This package is the beginning of the planned split
where backend text generation consumes structural connectivity rather than
re-deriving structure inside the pipeline coordinator.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::IR::StructuralRTLIR::ConnectionExpr qw(binding_expr_text);

sub emit_module ($class, $structural_rtl_ir) {
    my $structural = blessed($structural_rtl_ir) && $structural_rtl_ir->can('as_hashref')
        ? $structural_rtl_ir->as_hashref
        : ref($structural_rtl_ir) eq 'HASH'
            ? $structural_rtl_ir
            : {};

    my $target_language = $structural->{target_language} // 'systemverilog';
    confess "StructuralRTLIR verilog-family emitter only supports systemverilog/verilog target_language values"
        unless $target_language =~ /^(?:systemverilog|sv|verilog|v)$/;

    my $top_name = $structural->{module_name}
        // confess "StructuralRTLIR verilog-family emitter requires module_name";
    my @ports = @{$structural->{ports} || []};
    my @nets = @{$structural->{nets} || []};
    my @instances = @{$structural->{instances} || []};
    my @auxiliary_assignments = @{$structural->{auxiliary_assignments} || []};

    my @port_lines = map {
        my $width = ($_->{width} || 1) > 1 ? sprintf("[%d:0] ", $_->{width} - 1) : '';
        my $signed = ($_->{signed} // 0) ? 'signed ' : '';
        my $state_model = _state_model_keyword($_->{state_model});
        my $type_prefix = defined($state_model) ? "${state_model} ${signed}" : $signed;
        sprintf("    %s %s%s%s", $_->{direction}, $type_prefix, $width, $_->{name});
    } @ports;

    my @net_lines = map {
        my $width = ($_->{width} || 1) > 1 ? sprintf("[%d:0] ", $_->{width} - 1) : '';
        my $signed = ($_->{signed} // 0) ? 'signed ' : '';
        my $declaration_keyword = $_->{declaration_keyword} // 'wire';
        my $state_model = _state_model_keyword($_->{state_model});
        my $type_prefix = $declaration_keyword eq 'wire'
            ? (defined($state_model) ? "${state_model} ${signed}" : $signed)
            : $signed;
        sprintf("    %s %s%s%s;", $declaration_keyword, $type_prefix, $width, $_->{name})
    } @nets;

    my @instance_blocks = map {
        my $instance = $_;
        my @connection_lines = map {
            sprintf("        .%s(%s)", $_->{port_name}, binding_expr_text($_, $target_language))
        } @{$instance->{port_bindings} || []};

        join("\n",
            "    ".$instance->{module_name}." ".$instance->{instance_name}." (",
            join(",\n", @connection_lines),
            "    );",
        );
    } @instances;

    my @body_lines = (
        "module $top_name (",
        join(",\n", @port_lines),
        ");",
    );

    push @body_lines, "", @net_lines if @net_lines;
    push @body_lines, "", @auxiliary_assignments if @auxiliary_assignments;
    push @body_lines, "", join("\n\n", @instance_blocks), "" if @instance_blocks;
    push @body_lines, "endmodule";

    return join("\n", @body_lines);
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

=head2 emit_module

Renders one structural RTL IR module into SystemVerilog or Verilog-family text
using the explicit structural ports, nets, instances, bindings, and auxiliary
assignments already present in the IR.

=cut
