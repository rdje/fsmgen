use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken);
use Lispish;
use FSM::CoreAST;
use FSM::Adapter::FSMGenFull;
use FSM::ParameterDefaultEnvironmentSupport;

my $class = 'FSM::DeclaredWidthRangeSupport';
ok(eval {require FSM::DeclaredWidthRangeSupport; 1}, 'direct declared-width target adapter exists')
    or do {done_testing(); exit};
my $json = JSON::PP->new->canonical;
sub copy { $json->decode($json->encode($_[0])) }
sub parsed {
    my ($value, $expression) = @_;
    my $text = "(?fsm:ranges (+constants (SCALE 6) (STATIC 8)) (+params (W $value) (COPY W) (SAME $value))"
        ." (+size (DATA $expression)) (idle (= (DATA 0))))";
    my $a = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $m = $a->parse_fsm(scalar Lispish::multi(\$text));
    my $env = FSM::ParameterDefaultEnvironmentSupport->build_direct_environment(
        parameters => $m->parameters, sources => $m->parameter_default_sources, bindings => $m->parameter_default_bindings);
    return ($a->{signal_manager}->get_signal('DATA'), $env, $a);
}

subtest 'whole prepared plans retain actual selected names and default-one vector rank' => sub {
    for my $value (1, 8) {
        for my $language (qw(systemverilog sv verilog v vhdl)) {
            my ($signal, $env) = parsed($value, '(param COPY)');
            my $before = $json->encode([$env, $signal->declared_width_binding]);
            my $plan = $class->prepare_signal(signal => $signal, environment => $env, target_language => $language);
            my $canonical = $language eq 'sv' ? 'systemverilog' : $language eq 'v' ? 'verilog' : $language;
            my $scope = {kind => 'direct_module', owner => 'ranges'};
            is($json->encode($plan), $json->encode({profile => 'symbolic', target_language => $canonical,
                source_scope => $scope, source_signal => 'DATA', width => $value, is_vector => 1,
                parameter_references => ['COPY'], width_contract => {scope => $scope,
                    expression => ['param', 'COPY'], references => [{kind => 'parameter', token => 'COPY'}]},
                range_text => $language eq 'vhdl' ? '((COPY - 1) downto 0)' : '[(COPY - 1):0] '}),
                'complete independently expected target plan');
            is($json->encode([$env, $signal->declared_width_binding]), $before, 'complete source/environment caller kinds remain unchanged');
            $plan->{source_scope}{owner} = 'WRONG';
            is($signal->declared_width_binding->{scope}{owner}, 'ranges', 'returned plan cannot rewrite captured source');
        }
    }
};

subtest 'structured arithmetic and zero defaults retain real roots, static selections and order' => sub {
    for my $language ('systemverilog', 'vhdl') {
        my ($signal, $env) = parsed(0, '(+ (param W) 1)');
        my $plan = $class->prepare_signal(signal => $signal, environment => $env, target_language => $language);
        is_deeply($plan->{width_contract}, {scope => {kind => 'direct_module', owner => 'ranges'},
            expression => ['+', ['param', 'W'], '1'], references => [{kind => 'parameter', token => 'W'}]},
            'zero selected default is not mistaken for missing identity');
        is($plan->{range_text}, $language eq 'vhdl' ? '(((W + 1) - 1) downto 0)' : '[((W + 1) - 1):0] ', 'canonical arithmetic target text');
        ($signal, $env) = parsed(1, '(/ (* (param W) SCALE) 2)');
        $plan = $class->prepare_signal(signal => $signal, environment => $env, target_language => $language);
        is_deeply($plan->{width_contract}{expression}, ['/', ['*', ['param', 'W'], '6'], '2'], 'pinned static value inlines from captured structure');
        is($plan->{range_text}, $language eq 'vhdl' ? '((((W * 6) / 2) - 1) downto 0)' : '[(((W * 6) / 2) - 1):0] ', 'explicit fold order preserved');
        ($signal, $env) = parsed(1, '(+ (param W) (param W))');
        $plan = $class->prepare_signal(signal => $signal, environment => $env, target_language => $language);
        is_deeply($plan->{parameter_references}, ['W', 'W'], 'repeated selected roots remain ordered');
    }
};

subtest 'fully static captures keep fixed scalar/vector plans instead of invented symbolic rank' => sub {
    for my $case (['(+ 0 1)', 1, 0], ['(+ STATIC 0)', 8, 1]) {
        my ($expression, $width, $vector) = @$case;
        for my $language ('systemverilog', 'vhdl') {
            my ($signal, $env) = parsed(1, $expression);
            is($json->encode($class->prepare_signal(signal => $signal, environment => $env, target_language => $language)),
                $json->encode({profile => 'fixed', target_language => $language,
                    source_scope => {kind => 'direct_module', owner => 'ranges'}, source_signal => 'DATA',
                    width => $width, is_vector => $vector, parameter_references => [], width_contract => undef, range_text => undef}),
                'complete fixed plan preserves independent static rank');
        }
    }
};

subtest 'unsupported symbolic profiles refuse rather than freeze their selected defaults' => sub {
    my ($signal, $env, $a) = parsed(8, '(param W)');
    for my $change (
        sub {$_[0]{parameters}{W}{value_kind} = 'map'},
        sub {$_[0]{parameters}{W}{value_type_spec} = {kind => 'record', width => 8}},
        sub {$_[0]{parameters}{W}{value_payload}{payload} = '9'},
    ) {
        my $bad = copy($env); $change->($bad);
        ok(!eval {$class->prepare_signal(signal => $signal, environment => $bad, target_language => 'systemverilog'); 1}, 'invalid scalar/typed/stale profile refuses');
        like($@, qr/width|range/i, 'profile refusal names width/range boundary');
    }
    for my $name ('NESTED', 'HIDDEN') {
        my $payload = {kind => 'scalar_expr', payload => 'W+1'};
        if ($name eq 'NESTED') {
            $a->{signal_manager}->store_param($name, {value_payload => copy($payload)});
        } else {$a->{signal_manager}->store_aggregate_symbol($name, copy($payload))}
        my $expression = $name eq 'NESTED' ? ['param', [$name]] : $name;
        my $capture = $a->{parser}->capture_declared_width_contract(signal_name => 'DATA', width_token => $expression, scope => copy($env->{scope}));
        my $frame = {%{$capture->{width_capture}}, signal => 'DATA', expression => $expression};
        my $s = FSM::CoreAST::Signal->new(name => 'copy', width => $frame->{width},
            _declared_width_source => {signal => 'DATA', expression => $expression, resolved_width => $frame->{width}},
            _declared_width_binding => $frame);
        my $input = copy($env);
        if ($name eq 'NESTED') {$input->{parameters}{$name} = {value_kind => 'scalar', value_payload => copy($payload)}; push @{$input->{declaration_order}}, $name}
        my $before = $json->encode([$frame, $input]);
        ok(!eval {$class->prepare_signal(signal => $s, environment => $input, target_language => 'systemverilog'); 1}, 'nested symbol-bearing payload is explicitly unsupported');
        like($@, qr/(?:nested|hidden).*payload/i, 'hidden dependency refusal is named');
        is($json->encode([$frame, $input]), $before, 'unsupported payload keeps full caller data');
    }
    ($signal, $env) = parsed(1, '(^ (param W) 2)');
    ok(eval {$class->prepare_signal(signal => $signal, environment => $env, target_language => 'systemverilog'); 1}, 'existing Verilog bitwise width profile remains available');
    ok(!eval {$class->prepare_signal(signal => $signal, environment => $env, target_language => 'vhdl'); 1}, 'VHDL symbolic bitwise profile refuses');
    like($@, qr/unsupported.*operator/i, 'VHDL operator boundary is explicit');
    ($signal, $env) = parsed(1, '(+ (* 2147483647 2) (param W))');
    ok(!eval {$class->prepare_signal(signal => $signal, environment => $env, target_language => 'vhdl'); 1}, 'static subtree cannot bypass target per-intermediate bounds');
    like($@, qr/portable integer range/, 'portable intermediate overflow is retained');
    my $path_text = '(?fsm:paths (+params (GROUP (3 5))) (+size (DATA GROUP[1])) (idle (= (DATA 0))))';
    my $path_adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $path_module = $path_adapter->parse_fsm(scalar Lispish::multi(\$path_text));
    my $path_env = FSM::ParameterDefaultEnvironmentSupport->build_direct_environment(
        parameters => $path_module->parameters, sources => $path_module->parameter_default_sources,
        bindings => $path_module->parameter_default_bindings);
    for my $language ('systemverilog', 'vhdl') {
        ok(!eval {$class->prepare_signal(signal => $path_adapter->{signal_manager}->get_signal('DATA'),
            environment => $path_env, target_language => $language); 1}, 'actual mutable aggregate path refuses');
        like($@, qr/mutable parameter paths/, 'path refusal names the unsupported profile');
    }
    ($signal, $env) = parsed(1, '(param W)');
    for my $language ('c', undef, []) {
        ok(!eval {$class->prepare_signal(signal => $signal, environment => $env, target_language => $language); 1},
            'missing/foreign/reference target refuses');
        like($@, qr/supported target language/, 'target boundary is explicit');
    }
};

subtest 'held plans retain no bare Signal or declaration environment' => sub {
    my ($source, $environment) = parsed(1, '(param W)'); my $frame = $source->declared_width_binding;
    my ($weak_signal, $weak_env, $held);
    {
        my $s = FSM::CoreAST::Signal->new(name => 'physical_copy', width => 1,
            _declared_width_source => {signal => 'DATA', expression => $frame->{expression}, resolved_width => 1},
            _declared_width_binding => copy($frame));
        my $env = copy($environment); $weak_signal = $s; weaken($weak_signal); $weak_env = $env; weaken($weak_env);
        $held = $class->prepare_signal(signal => $s, environment => $env, target_language => 'vhdl');
    }
    ok(!defined($weak_signal) && !defined($weak_env), 'prepared plan owns only detached data');
    is($held->{range_text}, '((W - 1) downto 0)', 'held selected range remains usable');
};
done_testing();
