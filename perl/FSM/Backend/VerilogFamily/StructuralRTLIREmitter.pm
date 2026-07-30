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

use FSM::Backend::VerilogFamily::TypeDeclarationSupport;
use FSM::IR::StructuralRTLIR::ConnectionExpr qw(binding_expr_text);
use FSM::Support::HDLInstanceIdentifierPolicy;

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
    my ($typedef_lines, $aggregate_typedef_lookup) =
        FSM::Backend::VerilogFamily::TypeDeclarationSupport->collect_declared_aggregate_typedefs([@ports, @nets]);

    my @port_lines = map { _render_port_line($_, $aggregate_typedef_lookup) } @ports;

    my @net_lines = map { _render_net_line($_, $aggregate_typedef_lookup) } @nets;

    my @instance_blocks = map {
        my $instance = $_;
        FSM::Support::HDLInstanceIdentifierPolicy->assert_authored_instance_identifier(
            $instance->{instance_name},
            origin => "StructuralRTLIR verilog-family child instance",
        );
        my @connection_lines = map {
            sprintf("        .%s(%s)", $_->{port_name}, binding_expr_text($_, $target_language))
        } @{$instance->{port_bindings} || []};
        my @parameter_lines = map {
            sprintf("        .%s(%s)", $_->{name}, $_->{value_text})
        } @{$instance->{parameter_overrides} || []};

        @parameter_lines
            ? join("\n",
                "    ".$instance->{module_name}." #(",
                join(",\n", @parameter_lines),
                "    ) ".$instance->{instance_name}." (",
                join(",\n", @connection_lines),
                "    );",
            )
            : join("\n",
                "    ".$instance->{module_name}." ".$instance->{instance_name}." (",
                join(",\n", @connection_lines),
                "    );",
            );
    } @instances;

    my @body_lines;
    push @body_lines, @$typedef_lines, "" if @$typedef_lines;
    push @body_lines,
        "module $top_name (",
        join(",\n", @port_lines),
        ");";

    push @body_lines, "", @net_lines if @net_lines;
    push @body_lines, "", @auxiliary_assignments if @auxiliary_assignments;
    push @body_lines, "", join("\n\n", @instance_blocks), "" if @instance_blocks;
    push @body_lines, "endmodule";

    return join("\n", @body_lines);
}

sub _render_port_line ($port, $aggregate_typedef_lookup) {
    my $typedef_name = _aggregate_typedef_name_for($port, $aggregate_typedef_lookup);
    return sprintf("    %s %s %s", $port->{direction}, $typedef_name, $port->{name})
        if defined $typedef_name;

    my $width = ($port->{width} || 1) > 1 ? sprintf("[%d:0] ", $port->{width} - 1) : '';
    my $signed = ($port->{signed} // 0) ? 'signed ' : '';
    my $state_model = _state_model_keyword($port->{state_model});
    my $type_prefix = defined($state_model) ? "${state_model} ${signed}" : $signed;
    return sprintf("    %s %s%s%s", $port->{direction}, $type_prefix, $width, $port->{name});
}

sub _render_net_line ($net, $aggregate_typedef_lookup) {
    my $typedef_name = _aggregate_typedef_name_for($net, $aggregate_typedef_lookup);
    if (defined $typedef_name) {
        my $declaration_keyword = $net->{declaration_keyword} // 'wire';
        return $declaration_keyword eq 'wire'
            ? sprintf("    wire %s %s;", $typedef_name, $net->{name})
            : sprintf("    %s %s;", $typedef_name, $net->{name});
    }

    my $width = ($net->{width} || 1) > 1 ? sprintf("[%d:0] ", $net->{width} - 1) : '';
    my $signed = ($net->{signed} // 0) ? 'signed ' : '';
    my $declaration_keyword = $net->{declaration_keyword} // 'wire';
    my $state_model = _state_model_keyword($net->{state_model});
    my $type_prefix = $declaration_keyword eq 'wire'
        ? (defined($state_model) ? "${state_model} ${signed}" : $signed)
        : $signed;
    return sprintf("    %s %s%s%s;", $declaration_keyword, $type_prefix, $width, $net->{name});
}

sub _aggregate_typedef_name_for ($entry, $aggregate_typedef_lookup) {
    return FSM::Backend::VerilogFamily::TypeDeclarationSupport->aggregate_typedef_name_for($entry, $aggregate_typedef_lookup);
}

sub _state_model_keyword ($state_model) {
    return FSM::Backend::VerilogFamily::TypeDeclarationSupport->state_model_keyword($state_model);
}

1;

__END__

=head1 METHODS

=head2 emit_module

Renders one structural RTL IR module into SystemVerilog or Verilog-family text
using the explicit structural ports, nets, instances, bindings, and auxiliary
assignments already present in the IR.

=cut
