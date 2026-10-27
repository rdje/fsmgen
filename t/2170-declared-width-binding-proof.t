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

my $class = 'FSM::DeclaredWidthBindingSupport';
ok(eval {require FSM::DeclaredWidthBindingSupport; 1}, 'declared width proof helper exists')
    or do {done_testing(); exit};
my $json = JSON::PP->new->canonical;
sub copy { $json->decode($json->encode($_[0])) }
sub parsed {
    my ($text) = @_;
    my $a = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $m = $a->parse_fsm(scalar Lispish::multi(\$text));
    my $env = FSM::ParameterDefaultEnvironmentSupport->build_direct_environment(
        parameters => $m->parameters, sources => $m->parameter_default_sources,
        bindings => $m->parameter_default_bindings);
    return ($a, $m, $env);
}
sub refs {
    my ($lookup, $root, $suffix) = @_;
    return {lookup => $lookup, parameter => $root, suffix => $suffix // '', token => $root.($suffix // '')};
}
sub copied_signal {
    my ($frame) = @_;
    return FSM::CoreAST::Signal->new(name => 'physical_copy', width => $frame->{width},
        _declared_width_source => {signal => $frame->{signal}, expression => $frame->{expression}, resolved_width => $frame->{width}},
        _declared_width_binding => $frame);
}

subtest 'actual source static/parameter/alias observations prove without namespace borrowing' => sub {
    my $text = '(?fsm:proof_source (+types (type W (bits 4))) (+constants (W 8))'
        .' (+params (W 16) (ALIAS W) (SAME 16))'
        .' (+size (STATIC (+ W 0)) (SELECTED (param W)) (ALIASED (param ALIAS)) (BARE W) (FIXED 16))'
        .' (idle (= (STATIC 0)) (= (SELECTED 0)) (= (ALIASED 0))))';
    my ($a, $m, $env) = parsed($text); my $before = $json->encode([$env, $m->parameters]);
    for my $case (['STATIC', []], ['SELECTED', [refs('parameter', 'W')]], ['ALIASED', [refs('parameter', 'ALIAS')]]) {
        my ($name, $expected_refs) = @$case; my $s = $a->{signal_manager}->get_signal($name);
        my $frame = $s->declared_width_binding;
        my $proof = $class->prove_signal(signal => $s, environment => $env);
        is($json->encode($proof), $json->encode({capture => $frame, parameter_references => $expected_refs,
            has_parameter_references => @$expected_refs ? 1 : 0}), 'whole independently expected proof retains actual capture and immediate references');
        $proof->{capture}{scope}{owner} = 'WRONG';
        is($s->declared_width_binding->{scope}{owner}, 'proof_source', 'returned proof cannot rewrite source ownership');
    }
    for my $name ('BARE', 'FIXED') {
        ok(!eval {$class->prove_signal(signal => $a->{signal_manager}->get_signal($name), environment => $env); 1}, 'fixed/type signal cannot invent a coherent capture');
    }
    $m->{name} = 'physical_rename';
    is($class->prove_signal(signal => $a->{signal_manager}->get_signal('SELECTED'), environment => $env)->{capture}{scope}{owner},
        'proof_source', 'physical module rename supplies no lexical ownership');
    is($json->encode([$env, $m->parameters]), $before, 'complete declaration environment and caller JSON kinds remain unchanged');
};

subtest 'actual one-bit, path and repeated identities remain ordered and detached' => sub {
    my ($a, $m, $env) = parsed('(?fsm:paths (+params (ONE 1) (GROUP (3 5)))'
        .' (+size (FLAG (param ONE)) (PATH GROUP[1]) (SUM (+ (param ONE) (param ONE))))'
        .' (idle (= (FLAG 0)) (= (PATH 0)) (= (SUM 0))))');
    for my $case (['FLAG', 1, [refs('parameter', 'ONE')]], ['PATH', 5, [refs('symbol', 'GROUP', '[1]')]],
        ['SUM', 2, [refs('parameter', 'ONE'), refs('parameter', 'ONE')]]) {
        my ($name, $width, $expected) = @$case;
        my $s = $a->{signal_manager}->get_signal($name); my $before = $json->encode([$s->declared_width_source, $s->declared_width_binding, $env]);
        my $proof = $class->prove_signal(signal => $s, environment => $env);
        is($proof->{capture}{width}, $width, 'actual selected width retained');
        is_deeply($proof->{parameter_references}, $expected, 'complete ordered path/repeated identity proof');
        is($json->encode([$s->declared_width_source, $s->declared_width_binding, $env]), $before, 'proof leaves source and environment unchanged');
    }
    my $nested = {value_kind => 'scalar', value_text => 'ONE+GROUP[1]',
        value_payload => {kind => 'scalar_expr', payload => 'ONE+GROUP[1]'}};
    $a->{signal_manager}->store_param('NESTED', copy($nested));
    my $expression = ['param', ['NESTED']];
    my $contract = $a->{parser}->capture_declared_width_contract(signal_name => 'nested', width_token => $expression, scope => copy($env->{scope}));
    my $frame = {%{$contract->{width_capture}}, signal => 'nested', expression => $expression};
    my $prepared = copy($env); $prepared->{parameters}{NESTED} = $nested; push @{$prepared->{declaration_order}}, 'NESTED';
    my $proof = $class->prove_signal(signal => copied_signal($frame), environment => $prepared);
    is($json->encode($proof->{capture}), $json->encode($frame), 'actual canonical nested payload capture remains complete');
    is_deeply($proof->{parameter_references}, [refs('parameter', 'NESTED'), refs('symbol', 'ONE'), refs('symbol', 'GROUP', '[1]')],
        'nested actual lookups cannot hide behind the selected outer payload');
    $a->{signal_manager}->store_aggregate_symbol('DYNAMIC', {kind => 'scalar_expr', payload => 'ONE+GROUP[1]'});
    $contract = $a->{parser}->capture_declared_width_contract(signal_name => 'hidden', width_token => 'DYNAMIC', scope => copy($env->{scope}));
    $frame = {%{$contract->{width_capture}}, signal => 'hidden', expression => 'DYNAMIC'};
    $proof = $class->prove_signal(signal => copied_signal($frame), environment => $prepared);
    is($proof->{capture}{observations}[0]{kind}, 'static_symbol', 'outer frozen static selection remains distinct');
    is_deeply($proof->{parameter_references}, [refs('symbol', 'ONE'), refs('symbol', 'GROUP', '[1]')],
        'nested mutable identities cannot disappear behind an outer static label');
    is($proof->{has_parameter_references}, 1, 'hidden mutable payload is explicit for the later target-profile gate');
};

subtest 'constant fast capture proves pinned selection without any live namespace callback' => sub {
    my ($a, $m) = parsed('(?fsm:constant_proof (+constants (FAST 16)) (+size (DATA FAST)) (idle (= (DATA 0))))');
    my $s = $a->{signal_manager}->get_signal('DATA'); my $frame = $s->declared_width_binding;
    my $env = {scope => copy($frame->{scope}), parameters => {}, declaration_order => []};
    $a->{signal_manager}->store_aggregate_symbol('FAST', {kind => 'scalar', payload => '32'});
    my $proof;
    {
        no warnings 'redefine';
        local *FSM::Adapter::FSMGenFull::SignalManager::resolve_parameter_value_symbol_observation = sub {die "live namespace lookup\n"};
        local *FSM::Adapter::FSMGenFull::SignalManager::resolve_declared_parameter_payload = sub {die "live parameter lookup\n"};
        $proof = $class->prove_signal(signal => $s, environment => $env);
    }
    is($json->encode($proof), $json->encode({capture => $frame, parameter_references => [], has_parameter_references => 0}),
        'constant-only original capture remains exact with an explicit empty declaration environment');
    is($proof->{capture}{width}, 16, 'later same-name aggregate32 cannot replace captured constant16');
};

subtest 'same-default tampering cannot rewrite source structure, lookup choice or declared payloads' => sub {
    my ($a, $m, $env) = parsed('(?fsm:hostile (+params (W 8) (SAME 8)) (+size (DATA (param W))) (idle (= (DATA 0))))');
    my $original = $a->{signal_manager}->get_signal('DATA')->declared_width_binding;
    for my $change (
        sub {$_[0]{expression} = ['+', ['param', ['W']], '0']},
        sub {$_[0]{binding}{value_expression}{token} = '7'},
        sub {$_[0]{binding}{observation_index} = 99},
        sub {$_[0]{observations}[0]{token} = $_[0]{observations}[0]{parameter} = 'SAME'},
        sub {$_[0]{observations}[0]{lookup} = 'symbol'},
        sub {$_[0]{observations}[0]{value_payload}{payload} = '7'},
        sub {push @{$_[0]{observations}}, copy($_[0]{observations}[0])},
        sub {$_[0]{observations} = []},
        sub {$_[0]{width} = 16},
        sub {$_[0]{scope}{owner} = 'other_source'},
    ) {
        my $bad = copy($original); $change->($bad); my $s = copied_signal($bad);
        my $before = $json->encode([$s->width, $s->declared_width_source, $s->declared_width_binding, $env]);
        ok(!eval {$class->prove_signal(signal => $s, environment => $env); 1}, 'altered same-width or inconsistent capture refuses');
        like($@, qr/width/i, 'refusal identifies the width proof boundary');
        is($json->encode([$s->width, $s->declared_width_source, $s->declared_width_binding, $env]), $before, 'refusal preserves complete caller records');
    }
    for my $change (
        sub {$_[0]{parameters}{W}{value_payload}{payload} = '9'},
        sub {$_[0]{scope}{owner} = 'physical_rename'},
        sub {$_[0]{scope}{kind} = 'composition_top'},
        sub {$_[0]{declaration_order} = ['W']},
        sub {$_[0]{parameters}{W}{value_payload}{callback} = sub {1}},
    ) {
        my $bad = copy($env); $change->($bad);
        ok(!eval {$class->prove_signal(signal => copied_signal($original), environment => $bad); 1}, 'stale/malformed declaration environment refuses');
        like($@, qr/width/i, 'environment refusal names width boundary');
    }
};

subtest 'held proof data retains neither bare Signal nor environment owners' => sub {
    my ($a, $m, $env) = parsed('(?fsm:owners (+params (W 8)) (+size (DATA (param W))) (idle (= (DATA 0))))');
    my $frame = $a->{signal_manager}->get_signal('DATA')->declared_width_binding;
    for my $fail (0, 1) {
        my ($weak_signal, $weak_env, $held);
        {
            my $s = copied_signal(copy($frame)); my $input = copy($env);
            $input->{parameters}{W}{value_payload}{payload} = '9' if $fail;
            $weak_signal = $s; weaken($weak_signal); $weak_env = $input; weaken($weak_env);
            $held = eval {$class->prove_signal(signal => $s, environment => $input)};
        }
        ok(!defined($weak_signal) && !defined($weak_env), 'success/refusal holds no caller owner');
        is($held->{capture}{scope}{owner}, 'owners', 'held complete proof stays plain and detached') unless $fail;
    }
};
done_testing();
