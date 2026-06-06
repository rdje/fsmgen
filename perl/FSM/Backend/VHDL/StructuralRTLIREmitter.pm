package FSM::Backend::VHDL::StructuralRTLIREmitter;

=head1 NAME

FSM::Backend::VHDL::StructuralRTLIREmitter - VHDL emitter for bounded structural RTL IR tops

=head1 DESCRIPTION

Emits the bounded VHDL composition-top shapes from StructuralRTLIR. The
current leaves intentionally support only external-RTL structural instances or
one standalone-DT child passthrough instance plus bounded generated-FSM child
tops, direct scalar/vector top ports, VHDL-form auxiliary assignments,
scalar/vector signal declarations, scalar integer and multi-bit sized
bitstring generic-map actuals for external RTL instances, and port-map actuals
whose connection expressions already render through the backend-neutral
StructuralRTLIR expression helper.

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

    my @parameter_overrides = @{$instance->{parameter_overrides} || []};
    if (@parameter_overrides) {
        confess _unsupported('composition VHDL generic maps are currently limited to external RTL scalar integer or sized bitstring overrides')
            unless $instance_kind eq 'rtl';
    }

    my $instance_name = _identifier($instance->{instance_name}, 'instance name');
    my $module_name = _identifier($instance->{module_name}, 'instance module name');
    my @bindings = @{$instance->{port_bindings} || []};
    my @generic_lines;
    my @binding_lines;

    for my $index (0 .. $#parameter_overrides) {
        my $override = $parameter_overrides[$index];
        my $suffix = $index == $#parameter_overrides ? '' : ',';
        push @generic_lines, sprintf(
            '      %s => %s%s',
            _identifier($override->{name}, 'instance generic name'),
            _vhdl_generic_actual($override),
            $suffix,
        );
    }

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
        '    generic map (',
        @generic_lines,
        '    )',
        '    port map (',
        @binding_lines,
        '    );',
    ) if @generic_lines;

    return join("\n",
        "  $instance_name : entity work.$module_name",
        '    port map (',
        @binding_lines,
        '    );',
    );
}

sub _vhdl_generic_actual ($override) {
    my $kind = $override->{value_kind} // 'scalar';
    confess _unsupported('composition VHDL generic maps are currently limited to scalar integer or multi-bit sized bitstring actuals')
        unless $kind eq 'scalar';

    my $value = $override->{value_text};
    confess _unsupported('composition VHDL generic maps are currently limited to scalar integer or multi-bit sized bitstring actuals')
        unless defined $value;

    return $value if $value =~ /\A-?\d+\z/;

    my $literal_actual = _vhdl_sized_bitstring_generic_actual($value);
    return $literal_actual if defined $literal_actual;

    confess _unsupported('composition VHDL generic maps are currently limited to scalar integer or multi-bit sized bitstring actuals');
}

sub _vhdl_sized_bitstring_generic_actual ($value) {
    return undef
        unless $value =~ /\A([1-9][0-9]*)'([bBhH])([0-9A-Fa-f_xXzZ]+)\z/;

    my ($width, $base, $digits) = ($1 + 0, lc($2), $3);
    return undef if $width <= 1;

    confess _unsupported('composition VHDL generic maps are currently limited to scalar integer or multi-bit sized bitstring actuals')
        if $digits =~ /[xz]/i;
    $digits =~ s/_//g;

    my $bits = $base eq 'b'
        ? _vhdl_binary_digits($digits)
        : _vhdl_hex_digits_to_bits($digits);
    confess _unsupported('composition VHDL generic maps are currently limited to width-fitting multi-bit sized bitstring actuals')
        if length($bits) > $width;

    $bits = ('0' x ($width - length($bits))) . $bits;
    return qq{"$bits"};
}

sub _vhdl_binary_digits ($digits) {
    confess _unsupported('composition VHDL generic maps are currently limited to scalar integer or multi-bit sized bitstring actuals')
        unless $digits =~ /\A[01]+\z/;
    return $digits;
}

sub _vhdl_hex_digits_to_bits ($digits) {
    my %hex_to_bits = (
        0 => '0000',
        1 => '0001',
        2 => '0010',
        3 => '0011',
        4 => '0100',
        5 => '0101',
        6 => '0110',
        7 => '0111',
        8 => '1000',
        9 => '1001',
        a => '1010',
        b => '1011',
        c => '1100',
        d => '1101',
        e => '1110',
        f => '1111',
    );

    my $bits = join '', map {
        my $digit = lc($_);
        confess _unsupported('composition VHDL generic maps are currently limited to scalar integer or multi-bit sized bitstring actuals')
            unless exists $hex_to_bits{$digit};
        $hex_to_bits{$digit}
    } split //, $digits;

    $bits =~ s/\A0+(?=.)//;
    return $bits;
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
