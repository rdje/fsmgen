package FSM::Composition::ISFEventCDCModuleEmitter;

=head1 NAME

FSM::Composition::ISFEventCDCModuleEmitter - HDL emitter for generated ISF event CDC children

=head1 DESCRIPTION

Emits the concrete Verilog-family implementation for the ISF-generated
acknowledged single-bit event CDC primitive. The emitter is deliberately
selected by explicit C<.rtlif> metadata so normal external C<?rtl> children
remain externally supplied and are not inferred from shape alone.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use feature qw(signatures);
no warnings 'experimental::signatures';

use constant MARKER_PARAM => 'FSMGEN_ISF_CDC_EVENT';

sub hdl_code_for_loaded_metadata ($class, %args) {
    my $module_name = $args{module_name}
        or confess "ISFEventCDCModuleEmitter requires a module_name";
    my $metadata_path = $args{metadata_path} // 'unknown';
    my $target_language = $args{target_language} // 'systemverilog';
    my $interface_ports = $args{interface_ports} || [];
    my $parameter_declarations = $args{parameter_declarations} || [];

    my %params = map { (($_->{name} // '') => $_) } @$parameter_declarations;
    my $marker_param = MARKER_PARAM;
    return undef unless exists $params{$marker_param};

    my %policy = (
        source_reset => {
            present     => _required_bool_param($module_name, $metadata_path, \%params, 'SOURCE_RESET_PRESENT'),
            async       => _required_bool_param($module_name, $metadata_path, \%params, 'SOURCE_RESET_ASYNC'),
            active_high => _required_bool_param($module_name, $metadata_path, \%params, 'SOURCE_RESET_ACTIVE_HIGH'),
            port        => 'source_reset',
        },
        dest_reset => {
            present     => _required_bool_param($module_name, $metadata_path, \%params, 'DEST_RESET_PRESENT'),
            async       => _required_bool_param($module_name, $metadata_path, \%params, 'DEST_RESET_ASYNC'),
            active_high => _required_bool_param($module_name, $metadata_path, \%params, 'DEST_RESET_ACTIVE_HIGH'),
            port        => 'dest_reset',
        },
    );

    _assert_supported_target($module_name, $metadata_path, $target_language);
    _assert_marker($module_name, $metadata_path, \%params);
    _assert_reset_policy_shape($module_name, $metadata_path, \%policy);
    _assert_interface($module_name, $metadata_path, $interface_ports, \%policy);
    return _emit_module($module_name, \%policy);
}

sub _assert_supported_target ($module_name, $metadata_path, $target_language) {
    return if ($target_language // '') =~ /^(?:systemverilog|sv|verilog|v)$/;

    confess
        "Generated ISF event CDC module '$module_name' from '$metadata_path' ".
        "cannot emit target language '$target_language'. ".
        "The current event CDC implementation supports only SystemVerilog/Verilog-family HDL.\n";
}

sub _assert_marker ($module_name, $metadata_path, $params) {
    my $marker_param = MARKER_PARAM;
    my $value = _param_bool_value($params->{$marker_param});
    confess
        "Generated ISF event CDC module '$module_name' from '$metadata_path' ".
        "declares marker parameter '".MARKER_PARAM."' with non-boolean default; expected 1.\n"
        unless defined $value;
    confess
        "Generated ISF event CDC module '$module_name' from '$metadata_path' ".
        "declares marker parameter '".MARKER_PARAM."' as 0; expected 1.\n"
        unless $value == 1;
}

sub _assert_interface ($module_name, $metadata_path, $interface_ports, $policy) {
    my %expected = (
        source_clk   => { direction => 'input',  width => 1, type => 'clock' },
        dest_clk     => { direction => 'input',  width => 1, type => 'clock' },
        request      => { direction => 'input',  width => 1, type => 'data'  },
        ready        => { direction => 'output', width => 1, type => 'data'  },
        pulse        => { direction => 'output', width => 1, type => 'data'  },
    );
    $expected{source_reset} = { direction => 'input', width => 1, type => 'reset' }
        if $policy->{source_reset}{present};
    $expected{dest_reset} = { direction => 'input', width => 1, type => 'reset' }
        if $policy->{dest_reset}{present};

    my %ports = map { (_port_name($_) => $_) } @$interface_ports;
    for my $name (sort keys %expected) {
        my $port = $ports{$name};
        confess
            "Generated ISF event CDC module '$module_name' from '$metadata_path' ".
            "is missing required port '$name'.\n"
            unless $port;

        my $expected = $expected{$name};
        my $direction = _port_direction($port) // '';
        my $width = _port_width($port) // 0;
        my $type = _port_type($port) // 'data';

        confess
            "Generated ISF event CDC module '$module_name' from '$metadata_path' ".
            "requires port '$name' to be $expected->{direction} width 1 $expected->{type}, ".
            "but metadata declares $direction width $width $type.\n"
            unless $direction eq $expected->{direction}
                && $width == $expected->{width}
                && $type eq $expected->{type};
    }

    for my $name (sort keys %ports) {
        confess
            "Generated ISF event CDC module '$module_name' from '$metadata_path' ".
            "declares unsupported extra port '$name'.\n"
            unless exists $expected{$name};
    }
}

sub _assert_reset_policy_shape ($module_name, $metadata_path, $policy) {
    for my $key (qw(source_reset dest_reset)) {
        my $reset = $policy->{$key};
        confess
            "Generated ISF event CDC module '$module_name' from '$metadata_path' ".
            "declares ${key} as absent but also asynchronous. ".
            "Absent reset metadata must set the corresponding *_ASYNC parameter to 0.\n"
            if !$reset->{present} && $reset->{async};
    }
}

sub _required_bool_param ($module_name, $metadata_path, $params, $name) {
    confess
        "Generated ISF event CDC module '$module_name' from '$metadata_path' ".
        "is missing required metadata parameter '$name'.\n"
        unless exists $params->{$name};

    my $value = _param_bool_value($params->{$name});
    confess
        "Generated ISF event CDC module '$module_name' from '$metadata_path' ".
        "metadata parameter '$name' must have default 0 or 1.\n"
        unless defined $value;

    return $value;
}

sub _param_bool_value ($param) {
    return undef unless ref($param) eq 'HASH';
    my $value = $param->{default_value_text};
    return undef unless defined($value) && !ref($value);
    return 0 if $value eq '0';
    return 1 if $value eq '1';
    return undef;
}

sub _emit_module ($module_name, $policy) {
    my @ports = (
        "    input wire source_clk",
    );
    push @ports, "    input wire source_reset"
        if $policy->{source_reset}{present};
    push @ports, "    input wire dest_clk";
    push @ports, "    input wire dest_reset"
        if $policy->{dest_reset}{present};
    push @ports,
        "    input wire request",
        "    output wire ready",
        "    output reg pulse";

    my @lines = (
        "module $module_name (",
        join(",\n", @ports),
        ");",
        "",
        "    reg source_toggle = 1'b0;",
        "    reg source_ack_sync_1 = 1'b0;",
        "    reg source_ack_sync_2 = 1'b0;",
        "    reg dest_req_sync_1 = 1'b0;",
        "    reg dest_req_sync_2 = 1'b0;",
        "    reg dest_seen_toggle = 1'b0;",
        "    reg dest_ack_toggle = 1'b0;",
    );

    if ($policy->{dest_reset}{present}) {
        push @lines,
            "    reg source_dest_reset_sync_1 = 1'b1;",
            "    reg source_dest_reset_sync_2 = 1'b1;";
    }
    if ($policy->{source_reset}{present}) {
        push @lines,
            "    reg dest_source_reset_sync_1 = 1'b1;",
            "    reg dest_source_reset_sync_2 = 1'b1;";
    }

    push @lines,
        "",
        "    assign ready = " . _ready_expr($policy) . ";",
        "",
        "    always @(" . _event_control('source_clk', $policy->{source_reset}) . ") begin";
    push @lines, _emit_source_reset_branch($policy);
    push @lines,
        "    end",
        "",
        "    always @(" . _event_control('dest_clk', $policy->{dest_reset}) . ") begin";
    push @lines, _emit_dest_reset_branch($policy);
    push @lines,
        "    end",
        "endmodule";

    return join("\n", @lines) . "\n";
}

sub _emit_source_reset_branch ($policy) {
    my @lines;
    if ($policy->{source_reset}{present}) {
        push @lines,
            "        if (" . _reset_condition($policy->{source_reset}) . ") begin",
            _indent(3, _source_reset_assignments($policy)),
            "        end else begin",
            _indent(3, _source_runtime_lines($policy)),
            "        end";
        return @lines;
    }

    return _indent(2, _source_runtime_lines($policy));
}

sub _emit_dest_reset_branch ($policy) {
    my @lines;
    if ($policy->{dest_reset}{present}) {
        push @lines,
            "        if (" . _reset_condition($policy->{dest_reset}) . ") begin",
            _indent(3, _dest_reset_assignments($policy)),
            "        end else begin",
            _indent(3, _dest_runtime_lines($policy)),
            "        end";
        return @lines;
    }

    return _indent(2, _dest_runtime_lines($policy));
}

sub _source_reset_assignments ($policy) {
    my @lines = (
        "source_toggle <= 1'b0;",
        "source_ack_sync_1 <= 1'b0;",
        "source_ack_sync_2 <= 1'b0;",
    );
    if ($policy->{dest_reset}{present}) {
        push @lines,
            "source_dest_reset_sync_1 <= 1'b1;",
            "source_dest_reset_sync_2 <= 1'b1;";
    }
    return @lines;
}

sub _dest_reset_assignments ($policy) {
    my @lines = (
        "dest_req_sync_1 <= 1'b0;",
        "dest_req_sync_2 <= 1'b0;",
        "dest_seen_toggle <= 1'b0;",
        "dest_ack_toggle <= 1'b0;",
        "pulse <= 1'b0;",
    );
    if ($policy->{source_reset}{present}) {
        push @lines,
            "dest_source_reset_sync_1 <= 1'b1;",
            "dest_source_reset_sync_2 <= 1'b1;";
    }
    return @lines;
}

sub _source_runtime_lines ($policy) {
    my @lines;
    if ($policy->{dest_reset}{present}) {
        push @lines,
            "source_dest_reset_sync_1 <= " . _reset_condition($policy->{dest_reset}) . ";",
            "source_dest_reset_sync_2 <= source_dest_reset_sync_1;",
            "if (source_dest_reset_sync_2) begin",
            "    source_toggle <= 1'b0;",
            "    source_ack_sync_1 <= 1'b0;",
            "    source_ack_sync_2 <= 1'b0;",
            "end else begin",
            "    source_ack_sync_1 <= dest_ack_toggle;",
            "    source_ack_sync_2 <= source_ack_sync_1;",
            "    if (request && ready) begin",
            "        source_toggle <= ~source_toggle;",
            "    end",
            "end";
        return @lines;
    }

    return (
        "source_ack_sync_1 <= dest_ack_toggle;",
        "source_ack_sync_2 <= source_ack_sync_1;",
        "if (request && ready) begin",
        "    source_toggle <= ~source_toggle;",
        "end",
    );
}

sub _dest_runtime_lines ($policy) {
    my @lines = (
        "dest_req_sync_1 <= source_toggle;",
        "dest_req_sync_2 <= dest_req_sync_1;",
        "pulse <= 1'b0;",
    );

    if ($policy->{source_reset}{present}) {
        push @lines,
            "dest_source_reset_sync_1 <= " . _reset_condition($policy->{source_reset}) . ";",
            "dest_source_reset_sync_2 <= dest_source_reset_sync_1;",
            "if (dest_source_reset_sync_2) begin",
            "    dest_seen_toggle <= dest_req_sync_2;",
            "    dest_ack_toggle <= dest_req_sync_2;",
            "end else if (dest_req_sync_2 != dest_seen_toggle) begin",
            "    dest_seen_toggle <= dest_req_sync_2;",
            "    dest_ack_toggle <= dest_req_sync_2;",
            "    pulse <= 1'b1;",
            "end";
        return @lines;
    }

    push @lines,
        "if (dest_req_sync_2 != dest_seen_toggle) begin",
        "    dest_seen_toggle <= dest_req_sync_2;",
        "    dest_ack_toggle <= dest_req_sync_2;",
        "    pulse <= 1'b1;",
        "end";
    return @lines;
}

sub _ready_expr ($policy) {
    my @terms = ("source_ack_sync_2 == source_toggle");
    push @terms, "!source_dest_reset_sync_2" if $policy->{dest_reset}{present};
    return join(" && ", map { "($_)" } @terms);
}

sub _event_control ($clock, $reset) {
    return "posedge $clock" unless $reset->{present} && $reset->{async};
    my $edge = $reset->{active_high} ? 'posedge' : 'negedge';
    return "posedge $clock or $edge $reset->{port}";
}

sub _reset_condition ($reset) {
    return $reset->{active_high} ? $reset->{port} : "!$reset->{port}";
}

sub _indent ($level, @lines) {
    my $prefix = '    ' x $level;
    return map { $prefix . $_ } @lines;
}

sub _port_name ($port) {
    return $port->name if blessed($port) && $port->can('name');
    return ref($port) eq 'HASH' ? $port->{name} : undef;
}

sub _port_direction ($port) {
    return $port->direction if blessed($port) && $port->can('direction');
    return ref($port) eq 'HASH' ? $port->{direction} : undef;
}

sub _port_width ($port) {
    return $port->width if blessed($port) && $port->can('width');
    return ref($port) eq 'HASH' ? $port->{width} : undef;
}

sub _port_type ($port) {
    return $port->type if blessed($port) && $port->can('type');
    return ref($port) eq 'HASH' ? $port->{type} : undef;
}

1;

__END__

=head1 METHODS

=head2 hdl_code_for_loaded_metadata

Returns generated Verilog-family HDL for an explicitly marked ISF event CDC
C<.rtlif> contract, or C<undef> when the metadata belongs to a normal external
RTL child.

=cut
