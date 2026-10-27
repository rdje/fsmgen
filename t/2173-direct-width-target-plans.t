use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::CoreAST;
use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::VHDL;
use FSM::DirectDeclaredWidthSupport;

my $class = 'FSM::DirectDeclaredWidthSupport';
ok($class->can('prepare_declarations'), 'direct target declaration preparation exists')
    or do {done_testing(); exit};
my $json = JSON::PP->new->canonical;
sub copy { $json->decode($json->encode($_[0])) }
sub fixture {
    my ($language, $value, $module_name, $signal_name, $width_token, $extra) = @_;
    $value //= 1; $module_name //= 'target_widths'; $signal_name //= 'DATA_PORT';
    $width_token //= '(param COPY)'; $extra //= '';
    my $text = "(?fsm:$module_name (+params (W $value) (COPY W) (SAME $value))"
        ." $extra (+size ($signal_name $width_token) (SOURCE $value)) (idle (<-= ($signal_name SOURCE))))";
    my $a = FSM::Adapter::FSMGenFull->new(debug => 0); my $m = $a->parse_fsm(scalar Lispish::multi(\$text));
    my $dt = FSM::HDL::FlattenedDT->new(debug => 0); my $sv = $dt->generate_systemverilog($m);
    my $mapped = $language eq 'vhdl'
        ? FSM::HDL::FlattenedDT::Backend::VHDL::_plan_generated_vhdl_identifiers($sv)
        : {text => $sv, identifier_map => {}};
    my $parsed = FSM::HDL::FlattenedDT::Backend::VHDL::_parse_module($mapped->{text});
    my @parameters = FSM::HDL::FlattenedDT::Backend::VHDL::_parse_generics($parsed->{parameters});
    my @ports = FSM::HDL::FlattenedDT::Backend::VHDL::_parse_ports($parsed->{ports});
    my @signals = FSM::HDL::FlattenedDT::Backend::VHDL::_parse_signal_declarations($parsed->{body}, {map {$_->{name} => 1} @ports});
    my @constants = FSM::HDL::FlattenedDT::Backend::VHDL::_parse_constants($parsed->{body});
    my %declarations = map {$_->{name} => {name => $_->{name},
        width => $_->{scalar} ? 1 : $_->{msb} - $_->{lsb} + 1,
        signed => $_->{signed} // 0, declared_type_name => undef, declared_type_spec => undef}} (@ports, @signals);
    # Keep the backend planner's declared-type evidence while independently
    # checking its actual rendered numeric width through the converter parser.
    my $planner = $dt->{enable_graph_module_planning_support};
    my $port_plan = $planner->build_module_declaration_plan($m);
    my $storage = $planner->build_internal_signal_declaration_plan($m, $port_plan->{declared_port_signals});
    my %metadata = map {$_->{name} => $_} (@{$port_plan->{base_ports}}, @{$port_plan->{inputs}}, @{$port_plan->{outputs}});
    for my $group ('signal', 'aux') {
        for my $name (keys %{$storage->{"${group}_decls"}}) {
            $metadata{$name} = {width => $storage->{"${group}_decls"}{$name},
                declared_type_name => $storage->{"${group}_declared_type_name"}{$name},
                declared_type_spec => $storage->{"${group}_declared_type_spec"}{$name}};
        }
    }
    for my $name (keys %metadata) {
        my $target = $mapped->{identifier_map}{$name} // $name;
        my $record = $declarations{$target} or die "missing actual rendered declaration $target";
        die "actual rendered width differs for $target" unless $record->{width} == $metadata{$name}{width};
        $record->{$_} = $metadata{$name}{$_} for qw(declared_type_name declared_type_spec);
    }
    my $ns = {module_name => $parsed->{name}, identifier_map => $mapped->{identifier_map},
        parameter_names => [map {$_->{name}} @parameters], ports => [map {$_->{name}} @ports],
        signals => [map {$_->{name}} @signals], constants => [map {$_->{name}} @constants], types => []};
    return {fsm_module => $m, assignment_analysis => $dt->{assignment_analysis},
        target_language => $language, target_namespace => $ns, target_declarations => \%declarations};
}
sub run_plan { return $class->prepare_declarations(%{$_[0]}) }
sub snapshot {
    my ($in) = @_;
    my $m = $in->{fsm_module};
    return $json->encode([$in->{target_namespace}, $in->{target_declarations}, $m->parameters,
        $m->parameter_default_sources, $m->parameter_default_bindings,
        $class->prepare_module(fsm_module => $m, assignment_analysis => $in->{assignment_analysis}, target_language => $in->{target_language})]);
}

subtest 'actual backend namespace yields complete independently expected direct ranges' => sub {
    for my $language ('systemverilog', 'verilog', 'vhdl') {
        for my $value (1, 8) {
            my $in = fixture($language, $value); my $before = snapshot($in); my $plan = run_plan($in);
            my $scope = {kind => 'direct_module', owner => 'target_widths'};
            my $width = {profile => 'symbolic', target_language => $language, source_scope => $scope,
                source_signal => 'DATA_PORT', width => $value, is_vector => 1, parameter_references => ['COPY'],
                width_contract => {scope => copy($scope), expression => ['param', 'COPY'], references => [{kind => 'parameter', token => 'COPY'}]},
                range_text => $language eq 'vhdl' ? '((COPY - 1) downto 0)' : '[(COPY - 1):0] '};
            is($json->encode($plan), $json->encode({profile => 'symbolic', target_language => $language,
                source_scope => $scope, module_name => 'target_widths', parameter_references => ['COPY'],
                signal_targets => {DATA_PORT => 'DATA_PORT', SOURCE => 'SOURCE', next_DATA_PORT => 'next_DATA_PORT'},
                fixed_signals => ['SOURCE'], ranges => {
                    DATA_PORT => {source_name => 'DATA_PORT', declaration_kind => 'signal', width_plan => $width},
                    next_DATA_PORT => {source_name => 'next_DATA_PORT', declaration_kind => 'port', width_plan => copy($width)}}}),
                'whole independently expected source/target plan');
            is(snapshot($in), $before, 'complete source/default/namespace/declaration caller JSON kinds preserve');
        }
    }
};

subtest 'same-default fixed literal static and named-type declarations keep their old target path' => sub {
    for my $language ('systemverilog', 'vhdl') {
        for my $case (['8', ''], ['(+ 8 0)', ''], ['word_t', '(+types (type word_t (bits 8)))']) {
            my $in = fixture($language, 8, 'fixed_widths', 'DATA_PORT', @$case);
            my $before = snapshot($in); my $plan = run_plan($in);
            is($plan->{profile}, 'fixed', 'independent fixed/type selection remains fixed');
            is_deeply($plan->{ranges}, {}, 'no parameter range inferred from equal default');
            is_deeply($plan->{fixed_signals}, [qw(DATA_PORT SOURCE next_DATA_PORT)], 'complete fixed target membership');
            is_deeply($plan->{parameter_references}, [], 'fixed target selection borrows no mutable roots');
            is(snapshot($in), $before, 'actual type/static target records conserve');
        }
    }
};

subtest 'actual normalized names remain separate from lexical ownership and mutable root names' => sub {
    my $in = fixture('vhdl', 1, '_physical_source', '_DATA_PORT');
    my $plan = run_plan($in);
    is($plan->{source_scope}{owner}, '_physical_source', 'original lexical header survives target normalization');
    is($plan->{module_name}, 'physical_source', 'actual normalized module identity is used');
    is($plan->{signal_targets}{_DATA_PORT}, 'DATA_PORT', 'actual declaration mapping is joined');
    is($plan->{ranges}{DATA_PORT}{width_plan}{range_text}, '((COPY - 1) downto 0)', 'selected root identity remains unchanged');
    my $before = snapshot($in); $plan->{ranges}{DATA_PORT}{width_plan}{width_contract}{scope}{owner} = 'WRONG';
    is(snapshot($in), $before, 'returned plan owns detached source/target data');
    $in = fixture('vhdl');
    $in->{target_namespace}{identifier_map}{COPY} = 'RENAMED_COPY';
    @{$in->{target_namespace}{parameter_names}} = map {$_ eq 'COPY' ? 'RENAMED_COPY' : $_} @{$in->{target_namespace}{parameter_names}};
    ok(!eval {run_plan($in); 1}, 'mutable root renaming refuses instead of rewriting text');
    like($@, qr/parameter.*renaming/, 'bounded root mapping refusal is explicit');
};

subtest 'complete actual membership namespace and observed declaration contracts are required' => sub {
    my @changes = (
        sub {$_[0]{target_namespace}{module_name} = 'WRONG'},
        sub {pop @{$_[0]{target_namespace}{parameter_names}}},
        sub {push @{$_[0]{target_namespace}{ports}}, 'COPY'; $_[0]{target_declarations}{COPY} = {name => 'COPY', width => 1, signed => 0}},
        sub {push @{$_[0]{target_namespace}{constants}}, 'DATA_PORT'},
        sub {$_[0]{target_declarations}{DATA_PORT}{width} = 8},
        sub {$_[0]{target_declarations}{DATA_PORT}{signed} = 1},
        sub {$_[0]{target_declarations}{DATA_PORT}{declared_type_name} = 'word_t'},
        sub {delete $_[0]{target_declarations}{DATA_PORT}},
        sub {$_[0]{target_declarations}{EXTRA} = {name => 'EXTRA', width => 1, signed => 0}},
        sub {$_[0]{target_namespace}{identifier_map}{DATA_PORT} = 'MISSING'},
        sub {$_[0]{target_namespace}{signals} = [grep {$_ ne 'DATA_PORT'} @{$_[0]{target_namespace}{signals}}]; delete $_[0]{target_declarations}{DATA_PORT}},
    );
    for my $change (@changes) {
        my $in = fixture('systemverilog'); $change->($in); my $before = snapshot($in);
        ok(!eval {run_plan($in); 1}, 'hostile actual target snapshot refuses');
        like($@, qr/width|target|declaration|namespace|parameter/i, 'target-boundary diagnostic is visible');
        is(snapshot($in), $before, 'refusal preserves every caller surface');
    }
    for my $language ('systemverilog', 'vhdl') {
        my $in = fixture($language); push @{$in->{target_namespace}{types}}, $language eq 'vhdl' ? 'OUT' : 'wire';
        ok(!eval {run_plan($in); 1}, 'reserved declaration names refuse through shared policy');
        like($@, qr/reserved|identifier/, 'reserved target refusal is named');
    }
    my $in = fixture('vhdl'); push @{$in->{target_namespace}{constants}}, 'copy';
    ok(!eval {run_plan($in); 1}, 'VHDL case-folded namespace conflict refuses');
    like($@, qr/collid/, 'case collision is explicit');
    $in = fixture('systemverilog'); push @{$in->{target_namespace}{constants}}, 'copy';
    ok(eval {run_plan($in); 1}, 'Verilog-family distinct case remains valid');
};

subtest 'held target plan retains no namespace declaration or module owners' => sub {
    my ($weak_ns, $weak_decl, $weak_module, $held);
    {
        my $in = fixture('vhdl');
        # The numeric backend has its own established owner cycle (.25).
        # A physical Core copy never installed into that backend isolates
        # retention by this prepared result, preserving actual Signal inputs.
        my $original = $in->{fsm_module};
        $in->{fsm_module} = FSM::CoreAST::FSMModule->new(name => $original->name,
            signals => $original->signals, parameters => $original->parameters,
            _parameter_default_sources => $original->parameter_default_sources,
            _parameter_default_bindings => $original->parameter_default_bindings);
        $weak_ns = $in->{target_namespace}; weaken($weak_ns);
        $weak_decl = $in->{target_declarations}; weaken($weak_decl);
        $weak_module = $in->{fsm_module}; weaken($weak_module);
        $held = run_plan($in);
    }
    ok(!defined($weak_ns) && !defined($weak_decl) && !defined($weak_module), 'actual held result retains no caller graphs');
    is($held->{ranges}{DATA_PORT}{width_plan}{range_text}, '((COPY - 1) downto 0)', 'held target plan remains usable');
};
done_testing();
