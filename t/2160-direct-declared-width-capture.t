use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::Adapter::FSMGenFull::Parser;
use FSM::Adapter::FSMGenFull::SignalManager;
use FSM::Adapter::FSMGenFull::ExpressionBuilder;

my $class = 'FSM::Adapter::FSMGenFull::Parser';
ok($class->can('capture_declared_width_contract'), 'opt-in declared width capture exists')
    or do {done_testing(); exit};
my $json = JSON::PP->new->canonical;
sub literal { return {kind => 'literal', token => $_[0]} }
sub reference { return {kind => 'reference', observation_index => $_[0], value_expression => literal($_[1])} }
sub observation {
    my ($lookup, $kind, $token, $value, $root, $suffix) = @_;
    return {lookup => $lookup, kind => $kind, token => $token,
        value_payload => {kind => 'scalar', payload => $value},
        $kind eq 'parameter' ? (parameter => $root, suffix => $suffix) : ()};
}
sub expected {
    my ($width, $binding, $observations, $owner) = @_;
    return {width => $width, signed => 0, state_model => undef,
        width_capture => {width => $width, binding => $binding, observations => $observations,
            scope => {kind => 'direct_module', owner => $owner}}};
}
sub make_parser {
    my $manager = FSM::Adapter::FSMGenFull::SignalManager->new;
    return ($class->new(signal_manager => $manager,
        expression_builder => FSM::Adapter::FSMGenFull::ExpressionBuilder->new(signal_manager => $manager)), $manager);
}
sub capture {
    my ($parser, $token, $owner) = @_;
    return $parser->capture_declared_width_contract(signal_name => 'probe', width_token => $token,
        scope => {kind => 'direct_module', owner => $owner});
}

subtest 'actual source selects type, static and explicit parameter namespaces without changing stored products' => sub {
    my $raw = Lispish::multi('t/corpus/direct_size_parameter_selection.fsm');
    my $raw_before = $json->encode($raw);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $module = $adapter->parse_fsm($raw);
    my $p = $adapter->{parser}; my $owner = 'direct_size_parameter_selection';
    my $before = $json->encode([$module->parameters, $module->parameter_default_sources,
        $module->parameter_default_bindings, $adapter->{signal_manager}->get_signal('SELECTED')->declared_width_source,
        $adapter->{signal_manager}->get_signal('SELECTED')->declared_width_binding]);
    for my $token ('8', 'W') {
        is($json->encode(capture($p, $token, $owner)),
            $json->encode($p->resolve_declared_width_contract(signal_name => 'probe', width_token => $token)),
            'literal or named type keeps the exact fixed/type contract without invented capture');
    }
    is($json->encode(capture($p, ['+', ['W', '0']], $owner)),
        $json->encode(expected(8, {kind => 'operator', operator => '+', operands => [reference(0, 8), literal('0')]},
            [observation('symbol', 'static_symbol', 'W', 8)], $owner)),
        'general arithmetic captures the actual constant8 beside type4 and parameter16');
    for my $name ('W', 'ALIAS') {
        is($json->encode(capture($p, ['param', [$name]], $owner)),
            $json->encode(expected(16, reference(0, '16'),
                [observation('parameter', 'parameter', $name, '16', $name, '')], $owner)),
            'explicit parameter and alias retain immediate declared identity');
    }
    is($json->encode(capture($p, ['+', [['param', ['W']], ['param', ['W']]]], $owner)),
        $json->encode(expected(32, {kind => 'operator', operator => '+', operands => [reference(0, '16'), reference(1, '16')]},
            [map {observation('parameter', 'parameter', 'W', '16', 'W', '')} 1 .. 2], $owner)),
        'repeated references retain actual ordered observations');
    is($json->encode([$module->parameters, $module->parameter_default_sources,
        $module->parameter_default_bindings, $adapter->{signal_manager}->get_signal('SELECTED')->declared_width_source,
        $adapter->{signal_manager}->get_signal('SELECTED')->declared_width_binding]),
        $before, 'complete old getters and any already-published binding retain original kinds');
    is($json->encode($raw), $raw_before, 'actual frontend caller is unchanged');
};

subtest 'constant fast path never replays ordinary lookup under competing legacy tables' => sub {
    my ($p, $m) = make_parser();
    $m->store_constant('W', '0x10');
    $m->store_aggregate_symbol('W', {kind => 'scalar', payload => '32'});
    $m->store_param('W', {value_payload => {kind => 'scalar', payload => '64'}});
    is($json->encode(capture($p, 'W', 'lexical')),
        $json->encode(expected(16, reference(0, '16'),
            [observation('symbol', 'static_symbol', 'W', '16')], 'lexical')),
        'fast path retains its exact actual constant integer rather than aggregate32 or parameter64');
    is(capture($p, ['+', ['W', '0']], 'lexical')->{width}, 32,
        'ordinary expression correctly keeps its different aggregate-first lookup');
    $m->store_constant('W', FSM::CoreAST::Literal->new('1000', width => 2, radix => 'binary'));
    is($json->encode(capture($p, 'W', 'lexical')),
        $json->encode(expected(8, reference(0, '8'),
            [observation('symbol', 'static_symbol', 'W', '8')], 'lexical')),
        'intrinsic constant width uses the parsed selection without target formatting');
};

subtest 'actual scalar paths, one-bit defaults and nested expression lookups remain structured' => sub {
    my $text = '(?fsm:width_paths (+constants (FAST 0x10)) (+params (ONE 1) (GROUP (3 5)))'
        .' (+size (A FAST) (B (param ONE)) (C GROUP[1])) (idle (= (A 0)) (= (B 0)) (= (C 0))))';
    my $a = FSM::Adapter::FSMGenFull->new(debug => 0);
    $a->parse_fsm(scalar Lispish::multi(\$text)); my $p = $a->{parser};
    is($json->encode(capture($p, 'FAST', 'width_paths')),
        $json->encode(expected(16, reference(0, '16'), [observation('symbol', 'static_symbol', 'FAST', '16')], 'width_paths')),
        'real source constant fast path is captured');
    is($json->encode(capture($p, ['param', ['ONE']], 'width_paths')),
        $json->encode(expected(1, reference(0, '1'), [observation('parameter', 'parameter', 'ONE', '1', 'ONE', '')], 'width_paths')),
        'one-bit parameter retains its actual relationship');
    is($json->encode(capture($p, 'GROUP[1]', 'width_paths')),
        $json->encode(expected(5, reference(0, '5'), [observation('symbol', 'parameter', 'GROUP[1]', '5', 'GROUP', '[1]')], 'width_paths')),
        'actual path preserves immediate root and suffix');
    $a->{signal_manager}->store_param('NESTED', {value_payload => {kind => 'scalar_expr', payload => 'ONE+GROUP[1]'}});
    my $nested = capture($p, ['param', ['NESTED']], 'width_paths');
    is($nested->{width}, 6, 'selected nested payload uses canonical infix semantics');
    is_deeply([map {[$_->{lookup}, $_->{kind}, $_->{token}]} @{$nested->{width_capture}{observations}}],
        [['parameter', 'parameter', 'NESTED'], ['symbol', 'parameter', 'ONE'], ['symbol', 'parameter', 'GROUP[1]']],
        'nested expression retains complete actual lookup order');
};

subtest 'scope and source detach; refusals do not strand capture state or alter ordinary widths' => sub {
    my ($p, $m) = make_parser(); $m->store_param('ONE', {value_payload => {kind => 'scalar', payload => '1'}});
    my $scope = {kind => 'direct_module', owner => 'source_owner'};
    my $token = ['param', ['ONE']]; my $before = $json->encode([$scope, $token]);
    my $held = $p->capture_declared_width_contract(scope => $scope, width_token => $token);
    is($json->encode([$scope, $token]), $before, 'caller trees and scalar kinds are unchanged');
    $held->{width_capture}{scope}{owner} = 'WRONG';
    $held->{width_capture}{observations}[0]{value_payload}{payload} = '99';
    is(capture($p, $token, 'source_owner')->{width_capture}{observations}[0]{value_payload}{payload}, '1', 'result mutation cannot rewrite declarations');
    for my $bad_scope (undef, {}, {kind => 'composition_top', owner => 'top'}, {kind => 'direct_module', owner => ''},
            {kind => 'direct_module', owner => []}, {kind => 'direct_module', owner => 'valid', extra => 1}) {
        my $ok = eval {$p->capture_declared_width_contract(scope => $bad_scope, width_token => '1'); 1};
        ok(!$ok, 'absent or malformed scope is refused even for a fixed width');
        like($@, qr/explicit direct-module scope/, 'scope refusal identifies the boundary');
    }
    for my $bad (['param', ['MISSING']], ['/', ['1', '0']], '0') {
        my $ok = eval {capture($p, $bad, 'source_owner'); 1};
        ok(!$ok, 'canonical width refusal is preserved');
        is(capture($p, $token, 'source_owner')->{width}, 1, 'success retry has no stale partial capture');
        is($p->resolve_declared_width_contract(width_token => $token)->{width}, 1, 'ordinary mode still resolves after failed capture');
    }
    my $weak = $p; weaken($weak); my $weak_manager = $m; weaken($weak_manager);
    undef $p; undef $m;
    ok(!defined($weak), 'held plain capture does not retain the parser');
    ok(!defined($weak_manager), 'held plain capture does not retain the signal manager');
};
done_testing();
