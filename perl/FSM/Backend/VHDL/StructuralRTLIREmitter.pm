package FSM::Backend::VHDL::StructuralRTLIREmitter;

=head1 NAME

FSM::Backend::VHDL::StructuralRTLIREmitter - VHDL emitter for bounded structural RTL IR tops

=head1 DESCRIPTION

Emits the bounded VHDL composition-top shapes from StructuralRTLIR. The
current leaves intentionally support only external-RTL structural instances or
one standalone-DT child passthrough instance plus bounded generated-FSM child
tops, direct scalar/vector top ports, VHDL-form auxiliary assignments,
scalar/vector signal declarations, and port-map actuals whose connection
expressions already render through the backend-neutral StructuralRTLIR
expression helper.

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

    my $target_language = lc($structural->{target_language} // 'vhdl');
    confess _unsupported('structural VHDL emitter only supports target_language vhdl')
        unless $target_language eq 'vhdl';

    my $top_name = $structural->{module_name}
        // confess _unsupported('structural VHDL emitter requires module_name');
    my @ports = @{$structural->{ports} || []};
    my @nets = @{$structural->{nets} || []};
    my @instances = @{$structural->{instances} || []};
    my @auxiliary_assignments = @{$structural->{auxiliary_assignments} || []};

    my @port_lines = _render_port_lines(\@ports);
    my @net_lines = _render_signal_lines(\@nets);
    my @instance_blocks = map { _render_instance_block($_) } @instances;

    my @body_lines = (
        'library ieee;',
        'use ieee.std_logic_1164.all;',
        'use ieee.numeric_std.all;',
        '',
        "entity $top_name is",
    );

    if (@port_lines) {
        push @body_lines,
            '  port (',
            @port_lines,
            '  );';
    }

    push @body_lines,
        "end entity $top_name;",
        '',
        "architecture rtl of $top_name is";

    push @body_lines, @net_lines if @net_lines;
    push @body_lines, 'begin';

    push @body_lines, map { _normalize_vhdl_auxiliary_assignment($_) } @auxiliary_assignments;
    push @body_lines, '' if @auxiliary_assignments && @instance_blocks;
    push @body_lines, @instance_blocks if @instance_blocks;
    push @body_lines,
        "end architecture rtl;";

    return join("\n", @body_lines);
}

sub _render_port_lines ($ports) {
    my @lines;
    for my $index (0 .. $#$ports) {
        my $port = $ports->[$index];
        my $suffix = $index == $#$ports ? '' : ';';
        push @lines, sprintf(
            '    %s : %s %s%s',
            _identifier($port->{name}, 'port name'),
            _vhdl_direction($port->{direction}),
            _vhdl_type($port),
            $suffix,
        );
    }
    return @lines;
}

sub _render_signal_lines ($nets) {
    return map {
        sprintf(
            '  signal %s : %s;',
            _identifier($_->{name}, 'signal name'),
            _vhdl_type($_),
        )
    } @$nets;
}

sub _render_instance_block ($instance) {
    my $instance_kind = $instance->{kind} // '';
    confess _unsupported("child kind '$instance_kind' is outside the bounded structural-top leaves")
        unless $instance_kind eq 'rtl' || $instance_kind eq 'dtc' || $instance_kind eq 'fsmc';
    confess _unsupported('composition VHDL generic maps are outside the first structural-top leaf')
        if @{$instance->{parameter_overrides} || []};

    my $instance_name = _identifier($instance->{instance_name}, 'instance name');
    my $module_name = _identifier($instance->{module_name}, 'instance module name');
    my @bindings = @{$instance->{port_bindings} || []};
    my @binding_lines;

    for my $index (0 .. $#bindings) {
        my $binding = $bindings[$index];
        my $suffix = $index == $#bindings ? '' : ',';
        push @binding_lines, sprintf(
            '      %s => %s%s',
            _identifier($binding->{port_name}, 'instance port name'),
            binding_expr_text($binding, 'vhdl'),
            $suffix,
        );
    }

    return join("\n",
        "  $instance_name : entity work.$module_name",
        '    port map (',
        @binding_lines,
        '    );',
    );
}

sub _normalize_vhdl_auxiliary_assignment ($line) {
    confess _unsupported('structural VHDL auxiliary assignments must be VHDL concurrent assignments')
        if $line =~ /^\s*assign\b/;

    my $trimmed = $line;
    $trimmed =~ s/\A\s+//;
    $trimmed =~ s/\s+\z//;
    confess _unsupported('empty structural VHDL auxiliary assignment')
        unless length $trimmed;
    return '  ' . $trimmed;
}

sub _vhdl_direction ($direction) {
    return 'in' if ($direction // '') eq 'input';
    return 'out' if ($direction // '') eq 'output';
    confess _unsupported("unsupported structural VHDL port direction '$direction'");
}

sub _vhdl_type ($entry) {
    confess _unsupported('declared aggregate structural VHDL types are outside the first structural-top leaf')
        if defined($entry->{declared_type_name}) || defined($entry->{declared_type_spec});

    my $width = $entry->{width} || 1;
    confess _unsupported("unsupported structural VHDL width '$width'")
        unless defined($width) && $width =~ /^\d+$/ && $width >= 1;

    return 'std_logic' if $width == 1;
    return ($entry->{signed} ? 'signed' : 'std_logic_vector') . '(' . ($width - 1) . ' downto 0)';
}

sub _identifier ($value, $label) {
    confess _unsupported("missing structural VHDL $label")
        unless defined($value) && $value =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
    return $value;
}

sub _unsupported ($message) {
    return "Structural VHDL composition-top scaffold unsupported: $message.";
}

1;

__END__

=head1 METHODS

=head2 emit_module

Renders one bounded VHDL structural top from StructuralRTLIR. Anything outside
the shipped external-RTL literal/concat, standalone-DT passthrough, and exact
generated-FSM composition-top leaves fails closed.

=cut
