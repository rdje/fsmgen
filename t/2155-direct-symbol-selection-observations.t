use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::Adapter::FSMGenFull::SignalManager;

my $class = 'FSM::Adapter::FSMGenFull::SignalManager';
ok($class->can('resolve_parameter_value_symbol_observation'), 'actual symbol-selection observation is available')
    or do { done_testing(); exit };
my $json = JSON::PP->new->canonical;
sub scalar_payload { return {kind => 'scalar', payload => $_[0]} }
sub parameter { return {value_payload => scalar_payload($_[0])} }
sub observe { return $_[0]->resolve_parameter_value_symbol_observation($_[1]) }
sub static_observation {
    my ($token, $value) = @_;
    return {kind => 'static_symbol', token => $token, value_payload => scalar_payload($value)};
}
sub parameter_observation {
    my ($token, $root, $suffix, $value) = @_;
    return {kind => 'parameter', token => $token, parameter => $root, suffix => $suffix,
        value_payload => scalar_payload($value)};
}
my %capture;

subtest 'actual source keeps ordinary static lookup distinct from declared parameters' => sub {
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $module = $adapter->parse_fsm(Lispish::multi('t/corpus/direct_size_parameter_selection.fsm'));
    my $manager = $adapter->{signal_manager};
    my $before = $json->encode([$module->parameters, $module->parameter_default_sources,
        $module->parameter_default_bindings]);
    is($json->encode(observe($manager, 'W')), $json->encode(static_observation('W', 8)),
        'ordinary W selects the real constant rather than same-name parameter/type');
    is_deeply($manager->resolve_declared_parameter_payload('W'), scalar_payload('16'),
        'explicit declared-only lookup keeps the parameter namespace');
    is($json->encode(observe($manager, 'ALIAS')),
        $json->encode(parameter_observation('ALIAS', 'ALIAS', '', '16')),
        'a parameter alias keeps its immediate declaration identity');
    is($json->encode([$module->parameters, $module->parameter_default_sources,
        $module->parameter_default_bindings]), $before, 'source getters and JSON kinds stay unchanged');
    $capture{source} = {W => observe($manager, 'W'), ALIAS => observe($manager, 'ALIAS')};
};

subtest 'one branch selector preserves complete static-before-parameter precedence' => sub {
    my $manager = $class->new;
    # Controlled legacy tables exercise competing resolver branches that source
    # declaration validation need not admit simultaneously.
    $manager->{aggregate_payloads}{'mode.RUN'} = scalar_payload(11);
    $manager->store_constant('mode.RUN', FSM::CoreAST::Literal->new(12));
    $manager->store_define('mode.RUN', FSM::CoreAST::Literal->new(13));
    $manager->{enums}{mode} = {RUN => 14};
    $manager->{params}{'mode.RUN'} = parameter('15');
    $manager->{params}{mode} = {value_payload => {kind => 'map', member_order => ['RUN'],
        members => {RUN => scalar_payload('16')}}};
    for my $step (
        [aggregate_payloads => 11], [constants => 12], [defines => 13], [enums => 14],
    ) {
        my ($bucket, $value) = @$step;
        my $selection = observe($manager, 'mode.RUN');
        is($json->encode($selection), $json->encode(static_observation('mode.RUN', $value)),
            "$bucket wins at its original precedence with exact JSON kinds");
        is($json->encode($manager->resolve_parameter_value_symbol_payload('mode.RUN')),
            $json->encode($selection->{value_payload}), 'existing payload API reads the same selected branch');
        push @{$capture{precedence}}, $selection;
        delete $manager->{$bucket}{$bucket eq 'enums' ? 'mode' : 'mode.RUN'};
    }
    is_deeply(observe($manager, 'mode.RUN'), parameter_observation('mode.RUN', 'mode.RUN', '', '15'),
        'an exact legacy parameter key precedes parameter path selection');
    delete $manager->{params}{'mode.RUN'};
    is_deeply(observe($manager, 'mode.RUN'), parameter_observation('mode.RUN', 'mode', '.RUN', '16'),
        'a selected path preserves the original token, immediate root and suffix');
    $manager->{constants}{SHADOW} = undef;
    $manager->{params}{SHADOW} = parameter('8');
    is_deeply(observe($manager, 'SHADOW'), {kind => 'static_symbol', token => 'SHADOW', value_payload => undef},
        'a selected unusable legacy constant cannot borrow a parameter value');
    is($manager->resolve_parameter_value_symbol_payload('SHADOW'), undef, 'existing undefined-shadow behavior remains unchanged');
};

subtest 'aggregate observations and legacy payload results are detached' => sub {
    my $manager = $class->new;
    my $payload = {kind => 'list', items => [scalar_payload('2'), scalar_payload('3')]};
    $manager->store_param('GROUP', {value_payload => $payload});
    my $before = $json->encode($manager->{params});
    my $whole = observe($manager, 'GROUP');
    is_deeply($whole, {kind => 'parameter', token => 'GROUP', parameter => 'GROUP', suffix => '',
        value_payload => $payload}, 'whole aggregate selection retains its actual root');
    is_deeply(observe($manager, 'GROUP[1]'), parameter_observation('GROUP[1]', 'GROUP', '[1]', '3'),
        'index selection records immediate aggregate ancestry');
    is_deeply(observe($manager, 'GROUP[9]'), {kind => 'parameter', token => 'GROUP[9]',
        parameter => 'GROUP', suffix => '[9]', value_payload => undef},
        'an absent leaf retains the selected root with an undefined payload');
    is($manager->resolve_parameter_value_symbol_payload('GROUP[9]'), undef,
        'the existing payload API still refuses the absent leaf');
    $whole->{value_payload}{items}[1]{payload} = 'WRONG';
    my $leaf = observe($manager, 'GROUP[1]'); $leaf->{value_payload}{payload} = 'WRONG';
    my $legacy = $manager->resolve_parameter_value_symbol_payload('GROUP'); $legacy->{items}[0]{payload} = 'WRONG';
    is($json->encode($manager->{params}), $before, 'nested observed and legacy result mutation cannot change stored parameters');
    is_deeply(observe($manager, 'GROUP[1]'), parameter_observation('GROUP[1]', 'GROUP', '[1]', '3'),
        'later calls do not reuse caller-mutated records');
    $capture{aggregate} = observe($manager, 'GROUP');
};

subtest 'missing inputs and result ownership preserve the existing boundary' => sub {
    my $manager = $class->new;
    for my $name (undef, [], {}, 'UNKNOWN', 'UNKNOWN[1]') {
        is(observe($manager, $name), undef, 'no eligible selection returns undef');
        is($manager->resolve_parameter_value_symbol_payload($name), undef, 'old payload API keeps its missing-input behavior');
    }
    my ($weak, $saved);
    {
        my $local = $class->new;
        $local->store_param('WIDTH', parameter('16'));
        $weak = $local; weaken($weak);
        $saved = observe($local, 'WIDTH');
    }
    ok(!defined($weak), 'a held plain observation does not retain its otherwise unreferenced manager');
    is_deeply($saved, parameter_observation('WIDTH', 'WIDTH', '', '16'), 'detached result remains usable after manager release');
};

if (my $path = $ENV{FSMGEN_SYMBOL_SELECTION_CAPTURE}) {
    open my $out, '>', $path or die $!;
    print {$out} $json->encode(\%capture), "\n" or die $!;
    close $out or die $!;
}
done_testing();
