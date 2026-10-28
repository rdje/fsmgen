use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::DeclaredWidthBindingSupport;
use FSM::DirectDeclaredWidthSupport;
use FSM::ParameterDefaultEnvironmentSupport;
use FSM::HDL::FlattenedDT;

my $json = JSON::PP->new->canonical;
sub copy { $json->decode($json->encode($_[0])) }
sub parse {
    my ($text) = @_;
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $module = $adapter->parse_fsm(scalar Lispish::multi(\$text));
    return ($adapter, $module);
}
sub origin_source {
    my ($width) = @_;
    return "(?fsm:origins (+params (W $width) (SAME $width)) (+size (data (param W)))"
        .' (idle (<-= (data 0)) (<=- (data 0)) (<-= (data_r 0)) (<=- (next_data 0))))';
}
sub get_signal { $_[0]{signal_manager}->get_signal($_[1]) }
sub snapshot {
    my ($signal) = @_;
    return $json->encode([$signal->width, $signal->declared_width_source,
        $signal->declared_width_requirements, $signal->declared_width_binding]);
}

subtest 'actual equivalent next/q captures publish one binding without merging edge records' => sub {
    for my $width (1, 8) {
        my ($adapter, $module) = parse(origin_source($width));
        my $signal = get_signal($adapter, 'next_data_r');
        my $requirements = $signal->declared_width_requirements;
        is_deeply([map {$_->{copy_origin}} @{$requirements->{requirements}}],
            ['data_r', 'next_data'], 'both actual immediate edges remain ordered');
        my $expected = {%{$requirements->{requirements}[0]{width_capture}},
            signal => 'data', expression => ['param', ['W']]};
        is($json->encode($signal->declared_width_binding), $json->encode($expected),
            'complete binding retains original declaration rather than immediate edge');
        my $before = snapshot($signal);
        my $environment = FSM::ParameterDefaultEnvironmentSupport->build_direct_environment(
            parameters => $module->parameters, sources => $module->parameter_default_sources,
            bindings => $module->parameter_default_bindings);
        my $proof = eval {FSM::DeclaredWidthBindingSupport->prove_signal(signal => $signal, environment => $environment)};
        ok($proof, 'combined binding passes actual canonical observation proof') or diag $@;
        for my $language (qw(systemverilog verilog vhdl)) {
            my $plan = eval {FSM::DirectDeclaredWidthSupport->prepare_module(
                fsm_module => $module, assignment_analysis => {next_data_r => {
                    lhs_ast => FSM::CoreAST::SignalRef->new($signal)}}, target_language => $language)};
            ok($plan, "actual Signal membership prepares $language relationship") or diag $@;
            next unless $plan;
            is($plan->{signals}{next_data_r}{width_plan}{range_text},
                $language eq 'vhdl' ? '((W - 1) downto 0)' : '[(W - 1):0] ',
                'whole range keeps original root and vector rank at one');
            $plan->{signals}{next_data_r}{width_plan}{source_signal} = 'WRONG';
        }
        is(snapshot($signal), $before, 'complete caller source, requirements and JSON kinds conserve');
        is($json->encode($signal->declared_width_requirements), $json->encode($requirements),
            'effective binding never erases separate attestations');
    }
};

subtest 'equal defaults, different originals, opaque requirements and unattested edges cannot combine' => sub {
    my ($adapter, $module) = parse(origin_source(8));
    my $original = get_signal($adapter, 'next_data_r');
    my $envelope = $original->declared_width_requirements;
    my $environment = FSM::ParameterDefaultEnvironmentSupport->build_direct_environment(
        parameters => $module->parameters, sources => $module->parameter_default_sources,
        bindings => $module->parameter_default_bindings);
    for my $change (
        sub {my $r = $_[0]{requirements}[1]; $r->{expression} = ['param', ['SAME']];
            $r->{width_capture}{observations}[0]{token} = 'SAME';
            $r->{width_capture}{observations}[0]{parameter} = 'SAME'},
        sub {$_[0]{requirements}[1]{signal} = 'other_original'},
        sub {$_[0]{requirements}[1]{width_capture} = undef; $_[0]{requirements}[1]{expression} = undef},
        sub {$_[0]{requirements}[1]{width_capture} = undef; $_[0]{requirements}[1]{expression} = '8'},
        sub {delete $_[0]{requirements}[1]{copy_origin}},
        sub {$_[0]{requirements}[1]{copy_origin} = undef},
        sub {$_[0]{requirements}[1]{width_capture} = undef;
            $_[0]{requirements}[1]{declared_type_name} = 'word';
            $_[0]{requirements}[1]{declared_type_spec} = {kind => 'bits', width => 8}},
    ) {
        my $record = copy($envelope); $change->($record);
        my $signal = FSM::CoreAST::Signal->new(name => 'physical_copy', width => 8,
            _declared_width_source => $original->declared_width_source,
            _declared_width_requirements => $record);
        is(FSM::DeclaredWidthBindingSupport->equivalent_requirement_binding(signal => $signal), undef,
            'nonidentical or unproved requirement set withholds a binding');
        # A caller-supplied coherent last binding must not bypass the complete set.
        $signal->set_declared_width_binding($original->declared_width_binding);
        my $before = snapshot($signal);
        ok(!eval {FSM::DeclaredWidthBindingSupport->prove_signal(signal => $signal, environment => $environment); 1},
            'canonical proof refuses an inconsistent complete requirement set');
        like($@, qr/requirement/, 'requirement conflict has a bounded diagnostic');
        is(snapshot($signal), $before, 'refusal does not mutate caller metadata');
    }
};

subtest 'stale payloads and source changes remain invalidated; ordinary single bindings preserve' => sub {
    my ($adapter, $module) = parse(origin_source(8));
    my $signal = get_signal($adapter, 'next_data_r');
    my $environment = FSM::ParameterDefaultEnvironmentSupport->build_direct_environment(
        parameters => $module->parameters, sources => $module->parameter_default_sources,
        bindings => $module->parameter_default_bindings);
    $environment->{parameters}{W}{value_payload}{payload} = '16';
    ok(!eval {FSM::DeclaredWidthBindingSupport->prove_signal(signal => $signal, environment => $environment); 1},
        'matching combined requirements do not bless stale selected parameters');
    like($@, qr/stale selected parameter/, 'actual default mismatch is named');
    $adapter->{signal_manager}->register_signal('next_data_r', width => 8,
        _declared_width_source => $signal->declared_width_source);
    is($signal->declared_width_binding, undef, 'same-value source replacement clears combined binding');
    is($signal->declared_width_requirements, undef, 'same-value source replacement clears edge requirements');
    my ($ordinary) = parse('(?fsm:single (+params (W 1)) (+size (data (param W))) (idle (<-= (data 0))))');
    my $single = get_signal($ordinary, 'next_data');
    is($json->encode(FSM::DeclaredWidthBindingSupport->equivalent_requirement_binding(signal => $single)),
        $json->encode($single->declared_width_binding), 'single captured copy preserves its existing binding');
};
subtest 'capture equivalence does not admit the collision source mixed assignment styles' => sub {
    my (undef, $module) = parse(origin_source(1));
    ok(!eval {FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($module); 1},
        'whole source retains the independent backend assignment-style refusal');
    like($@, qr/Mixed.*unsupported/, 'prepared ranges are not advertised as whole-source HDL qualification');
};
done_testing();
