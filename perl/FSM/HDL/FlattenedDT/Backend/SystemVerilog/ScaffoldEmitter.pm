package FSM::HDL::FlattenedDT::Backend::SystemVerilog::ScaffoldEmitter;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::ScaffoldEmitter - Render direct generated-module HDL scaffold sections

=head1 DESCRIPTION

Owns the bounded SystemVerilog scaffold family for the older direct generated
module backend. This package renders the stable top-of-module sections that
surround the richer enable-graph logic: file header, module declaration, state
encoding localparams, and the state register block.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Backend::VerilogFamily::TypeDeclarationSupport;
use FSM::Debug;

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[ScaffoldEmitter.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

sub generate_header ($self, $fsm_module) {
    my $hdl = "";
    $hdl .= "//=============================================================================\n";
    $hdl .= "// Flattened Decision Tree FSM: " . $fsm_module->name . "\n";
    $hdl .= "// Generated using Enable-based Methodology with WEN/EN Signals\n";
    $hdl .= "// Date: " . localtime() . "\n";
    $hdl .= "// \n";
    $hdl .= "// This implementation uses:\n";
    $hdl .= "// - Flattened decision tree approach\n";
    $hdl .= "// - Enable-based logic with assign statements\n";
    $hdl .= "// - Write Enable (WEN) and Enable (EN) signals for each LHS\n";
    $hdl .= "// - Flat Boolean expressions from DT traversal\n";
    $hdl .= "//=============================================================================\n\n";
    return $hdl;
}

sub generate_module_declaration ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    my $module_plan = $ctx->{enable_graph_module_planning_support}->build_module_declaration_plan($fsm_module);
    $ctx->{verilog_family_typedef_state} //= FSM::Backend::VerilogFamily::TypeDeclarationSupport->typedef_state;
    my ($typedef_lines, $aggregate_typedef_lookup) =
        FSM::Backend::VerilogFamily::TypeDeclarationSupport->collect_declared_aggregate_typedefs(
            [ @{$module_plan->{base_ports} || []}, @{$module_plan->{inputs} || []}, @{$module_plan->{outputs} || []} ],
            $ctx->{verilog_family_typedef_state},
        );
    my @base_ports = map { _render_module_port_plan($_, $aggregate_typedef_lookup) } @{$module_plan->{base_ports} || []};
    my @inputs = map { _render_module_port_plan($_, $aggregate_typedef_lookup) } @{$module_plan->{inputs} || []};
    my @outputs = map { _render_module_port_plan($_, $aggregate_typedef_lookup) } @{$module_plan->{outputs} || []};

    my @all_ports = (@base_ports, @inputs, @outputs);
    my @parameter_lines = _render_module_parameter_lines($fsm_module);
    my $hdl = "";
    if (@$typedef_lines) {
        $hdl .= join("\n", @$typedef_lines) . "\n\n";
    }
    $hdl .= "module " . $fsm_module->name;
    if (@parameter_lines) {
        $hdl .= " #(\n";
        for my $i (0 .. $#parameter_lines) {
            $hdl .= $parameter_lines[$i];
            $hdl .= "," if $i < $#parameter_lines;
            $hdl .= "\n";
        }
        $hdl .= ")";
    }
    $hdl .= " (\n";
    for my $i (0 .. $#all_ports) {
        $hdl .= $all_ports[$i];
        if ($i < $#all_ports) {
            $hdl .= ",\n";
        } else {
            $hdl .= "\n";
        }
    }
    $hdl .= ");\n\n";

    $ctx->{declared_port_signals} = { %{$module_plan->{declared_port_signals} || {}} };
    $ctx->{port_directions} = { %{$module_plan->{port_directions} || {}} };

    return $hdl;
}

sub _render_module_parameter_lines ($fsm_module) {
    return unless $fsm_module && $fsm_module->can('parameters');

    my $parameters = $fsm_module->parameters || {};
    my @lines;
    for my $parameter_name (sort keys %$parameters) {
        my $parameter_info = $parameters->{$parameter_name};
        my $value_text = ref($parameter_info) eq 'HASH'
            ? $parameter_info->{value_text}
            : $parameter_info;
        next unless defined($value_text) && length($value_text);
        push @lines, "  parameter $parameter_name = $value_text";
    }
    return @lines;
}

sub _render_module_port_plan ($port_plan, $aggregate_typedef_lookup = undef) {
    my $typedef_name = FSM::Backend::VerilogFamily::TypeDeclarationSupport
        ->aggregate_typedef_name_for($port_plan, $aggregate_typedef_lookup);
    return "  $port_plan->{direction} ${typedef_name} $port_plan->{name}"
        if defined $typedef_name;

    my $width = $port_plan->{width} || 1;
    my $width_str = ($width > 1) ? "[" . ($width - 1) . ":0] " : "";
    my $signed_str = ($port_plan->{signed} // 0) ? "signed " : "";
    my $type_keyword = _state_model_keyword($port_plan->{state_model});
    if (defined $type_keyword) {
        return "  $port_plan->{direction} ${type_keyword} ${signed_str}${width_str}$port_plan->{name}";
    }
    if ($port_plan->{direction} eq 'output' && $port_plan->{storage} eq 'reg') {
        return "  output reg " . ($signed_str || " ") . "${width_str}$port_plan->{name}";
    }

    return "  $port_plan->{direction}  $port_plan->{storage} ${signed_str}${width_str}$port_plan->{name}";
}

sub _state_model_keyword ($state_model) {
    return FSM::Backend::VerilogFamily::TypeDeclarationSupport->state_model_keyword($state_model);
}

sub generate_state_encoding ($self, $fsm_module) {
    my $state_plan = $self->{flattened_dt}->{enable_graph_module_planning_support}->build_state_register_plan($fsm_module);
    my $hdl = "  // State encoding\n";
    for my $encoding (@{$state_plan->{encodings} || []}) {
        $hdl .= "  localparam $encoding->{localparam_name} = $state_plan->{state_bits}'d$encoding->{encoded_value};\n";
    }
    $hdl .= "\n";

    return $hdl;
}

sub generate_state_register ($self, $fsm_module) {
    my $module_planning = $self->{flattened_dt}->{enable_graph_module_planning_support};
    my $state_plan = $module_planning->build_state_register_plan($fsm_module);
    my $event_control = $module_planning->sequential_event_control($fsm_module);
    my $reset_condition = $module_planning->reset_condition_expr($fsm_module);

    if (!$state_plan->{has_state_registers}) {
        fsm_debug("FSM has no regular states - only standalone decision trees. Skipping state register generation.", 3);
        return "  // No state registers needed - FSM contains only decision trees\n\n";
    }

    my $hdl = "  // State registers\n";
    $hdl .= "  reg [" . ($state_plan->{state_bits} - 1) . ":0] current_state, next_state;\n\n";

    $hdl .= "  // State sequential logic\n";
    $hdl .= "  always_ff @($event_control) begin\n";
    if (defined($reset_condition) && length($reset_condition)) {
        $hdl .= "    if ($reset_condition) begin\n";
        $hdl .= "      current_state <= $state_plan->{reset_state_name};\n";
        $hdl .= "    end else begin\n";
        $hdl .= "      current_state <= next_state;\n";
        $hdl .= "    end\n";
    } else {
        $hdl .= "      current_state <= next_state;\n";
    }
    $hdl .= "  end\n\n";

    return $hdl;
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one scaffold emitter bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 generate_header

Renders the generated-file banner block for one semantic FSM/DT module.

=head2 generate_module_declaration

Renders the ANSI-style SystemVerilog module declaration from the enable-graph
module plan and records the declared port inventory back onto the flattened
backend context for later declaration planning.

=head2 generate_state_encoding

Renders the localparam-based state encoding block from the enable-graph state
register plan.

=head2 generate_state_register

Renders the state register declaration and sequential state-update block when
the semantic module contains regular FSM states; otherwise returns the explicit
"no state registers needed" comment block used by the direct backend.

=cut
