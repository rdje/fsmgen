package FSM::HDL::FlattenedDT::Backend::SystemVerilog::ScaffoldEmitter;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::ScaffoldEmitter - Render direct generated-module HDL scaffold sections

=head1 DESCRIPTION

Owns the bounded SystemVerilog scaffold family for the older direct generated
module backend. This package renders the stable top-of-module sections that
surround the richer enable-graph logic: file header, module declaration, state
encoding localparams, and the state register block.

Captured default trees use the shared canonical renderer, retaining
parameter roots, operators, literal/static selections and dependency order with
unchanged alphabetical ties. Consumed scalar trees require source/binding
membership, lexical ownership and observed reference agreement; missing
invalidated snapshots refuse. Legacy
programmatic literals retain their existing rendering. Immutable aggregate
subtrees fold through the canonical value evaluator. Mutable aggregate/path
relationships refuse before a header is returned; generic signal ranges and
external override qualification remain successors.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Backend::VerilogFamily::TypeDeclarationSupport;
use FSM::Backend::VerilogFamily::ParameterBindingEmitter;
use FSM::Support::HDLInstanceIdentifierPolicy;
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
    $ctx->{verilog_family_typedef_state} //= FSM::Backend::VerilogFamily::TypeDeclarationSupport->typedef_state(
        module_name => $fsm_module->name,
    );
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
    my $sources = $fsm_module->can('parameter_default_sources')
        ? ($fsm_module->parameter_default_sources // {}) : {};
    die "Module parameter default alias sources require a declaration map\n"
        unless ref($sources) eq 'HASH';
    my $bindings = $fsm_module->can('parameter_default_bindings')
        ? ($fsm_module->parameter_default_bindings // {}) : {};
    die "Module parameter defaults require a canonical binding map\n"
        unless ref($bindings) eq 'HASH';
    my (%values, %aliases, %dependencies);
    for my $parameter_name (sort keys %$parameters) {
        my $parameter_info = $parameters->{$parameter_name};
        my $value_text = ref($parameter_info) eq 'HASH'
            ? $parameter_info->{value_text}
            : $parameter_info;
        next unless defined($value_text) && length($value_text);
        $values{$parameter_name} = $value_text;
        my $target = _direct_scalar_default_alias(
            $parameter_name, $parameter_info, $sources->{$parameter_name}, $parameters);
        $aliases{$parameter_name} = $target if defined $target;
    }
    for my $name (sort keys %aliases) {
        die "Module parameter default alias '$name' requires an emitted declared target\n"
            unless exists $values{$aliases{$name}};
        $values{$name} = $aliases{$name};
        $dependencies{$name} = {$aliases{$name} => 1};
    }

    if (keys(%$sources) || keys(%$bindings)) {
        my $environment = _captured_parameter_environment($parameters, $sources, $bindings);
        for my $name (sort keys %values) {
            my $references = $sources->{$name}{references};
            my $lowered = FSM::Backend::VerilogFamily::ParameterBindingEmitter->lower_default(
                binding => $bindings->{$name}, environment => $environment);
            my $actual = $lowered->{parameter_references};
            die "Module parameter default '$name' changes reference observations\n"
                unless @$actual == @$references
                    && !grep {$actual->[$_] ne $references->[$_]{parameter}} 0 .. $#$references;
            die "Module parameter default '$name' requires emitted declared dependencies\n"
                if grep {!exists $values{$_}} @$actual;
            $values{$name} = $lowered->{text};
            $dependencies{$name} = {map {$_ => 1} @$actual};
        }
    }

    # Keep existing alphabetical ties while moving an emitted alias dependency
    # before its consumer. Actual captured references add dependency edges.
    my @names = sort keys %values;
    my (%emitted, @order);
    while (@order < @names) {
        my $next;
        for my $name (@names) {
            next if $emitted{$name};
            next if grep {!$emitted{$_}} keys %{$dependencies{$name} // {}};
            $next = $name; last;
        }
        die "Module parameter default dependency cycle\n" unless defined $next;
        push @order, $next; $emitted{$next} = 1;
    }
    return map {"  parameter $_ = $values{$_}"} @order;
}

sub _captured_parameter_environment ($parameters, $sources, $bindings) {
    die "Module parameter defaults require complete source and binding membership\n"
        unless keys(%$parameters) == keys(%$sources) && keys(%$parameters) == keys(%$bindings)
            && !grep {!exists($sources->{$_}) || !exists($bindings->{$_})} keys %$parameters;
    my $owner;
    for my $name (sort keys %$parameters) {
        my ($info, $source, $binding) = ($parameters->{$name}, $sources->{$name}, $bindings->{$name});
        die "Module parameter default '$name' requires normalized declaration evidence\n"
            unless ref($info) eq 'HASH' && defined($info->{value_kind}) && !ref($info->{value_kind})
                && $info->{value_kind} =~ /\A(?:scalar|list|map)\z/
                && ref($info->{value_payload}) eq 'HASH'
                && defined($info->{value_text}) && !ref($info->{value_text}) && length($info->{value_text});
        die "Module parameter default '$name' requires an actual source declaration\n"
            unless ref($source) eq 'HASH' && ($source->{parameter} // '') eq $name
                && defined($source->{source_module}) && !ref($source->{source_module})
                && length($source->{source_module}) && ref($source->{references}) eq 'ARRAY';
        $owner //= $source->{source_module};
        die "Module parameter default '$name' has a foreign source scope\n"
            unless $source->{source_module} eq $owner;
        die "Module parameter default '$name' requires a canonical binding record\n"
            unless ref($binding) eq 'HASH' && defined($binding->{kind}) && !ref($binding->{kind})
                && $binding->{kind} =~ /\A(?:literal|parameter|static_symbol|payload|operator|list|map)\z/;
        die "Module parameter default '$name' requires a target identifier\n"
            unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name);
        die "Module parameter default '$name' is reserved in SystemVerilog\n"
            if grep {$_ eq 'SystemVerilog'} @{FSM::Support::HDLInstanceIdentifierPolicy->reserved_target_languages($name)};
        for my $reference (@{$source->{references}}) {
            die "Module parameter default '$name' has malformed reference observations\n"
                unless ref($reference) eq 'HASH'
                    && !grep {!defined($reference->{$_}) || ref($reference->{$_})} qw(parameter token suffix);
            die "Module parameter default '$name' has inconsistent reference observations\n"
                unless exists($parameters->{$reference->{parameter}})
                    && $reference->{token} eq $reference->{parameter}.$reference->{suffix};
        }
    }
    return {scope => {kind => 'direct_module', owner => $owner}, parameters => $parameters,
        declaration_order => [sort keys %$parameters]};
}

sub _direct_scalar_default_alias ($name, $info, $source, $parameters) {
    return undef unless defined $source;
    return undef unless ref($info) eq 'HASH' && ($info->{value_kind} // '') eq 'scalar';
    die "Module parameter default alias '$name' has an inconsistent source declaration\n"
        unless ref($source) eq 'HASH' && ($source->{parameter} // '') eq $name;
    my $references = $source->{references};
    die "Module parameter default alias '$name' has malformed reference observations\n"
        unless ref($references) eq 'ARRAY';
    for my $reference (@$references) {
        die "Module parameter default alias '$name' has malformed reference observations\n"
            unless ref($reference) eq 'HASH'
                && !grep {!defined($reference->{$_}) || ref($reference->{$_})} qw(parameter token suffix);
        die "Module parameter default alias '$name' has inconsistent reference observations\n"
            unless $reference->{token} eq $reference->{parameter}.$reference->{suffix};
        die "Module parameter default alias '$name' observes an undeclared target\n"
            unless exists $parameters->{$reference->{parameter}};
    }
    my $expression = $source->{expression};
    $expression = $expression->[0] while ref($expression) eq 'ARRAY' && @$expression == 1;
    # This remains a bounded source-observation consistency check. Canonical
    # scalar operators are rendered separately by the captured-tree consumer.
    return undef unless defined($expression) && !ref($expression)
        && $expression =~ /\A[A-Za-z_]\w*\z/ && @$references;
    die "Module parameter default alias '$name' has inconsistent expression observations\n"
        unless @$references == 1 && $references->[0]{suffix} eq ''
            && $expression eq $references->[0]{token};
    my $target = $parameters->{$references->[0]{parameter}};
    die "Module parameter default alias '$name' requires a scalar declared target\n"
        unless ref($target) eq 'HASH' && ($target->{value_kind} // '') eq 'scalar';
    return $references->[0]{parameter};
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
