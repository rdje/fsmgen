use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::Backend::VerilogFamily::CompositionBindingEmitter;

my $renderer = 'FSM::Backend::VerilogFamily::ParameterBindingEmitter';
my $loaded = eval {require FSM::Backend::VerilogFamily::ParameterBindingEmitter; 1};
ok($loaded, 'shared scalar target renderer exists') or do {diag($@); done_testing(); exit};

my $json = JSON::PP->new->canonical;
my %capture;
sub copy {return $json->decode($json->encode($_[0]))}
my $module = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(
    scalar Lispish::multi('t/data/ial0-parameter-default-sources.fsm'));
my $environment = {
    scope => {kind => 'direct_module', owner => $module->parameter_default_sources->{W}{source_module}},
    declaration_order => [sort keys %{$module->parameters}], parameters => $module->parameters,
};
my $bindings = $module->parameter_default_bindings;
my $before = $json->encode([$environment, $bindings]);
sub lower {
    my ($binding, $env, $language) = @_;
    return $renderer->lower_expression(binding => $binding,
        environment => $env // $environment, target_language => $language // 'systemverilog');
}

subtest 'actual direct Core scalar bindings preserve names, operators, static selections and JSON kinds' => sub {
    my %expected = (
        W => ['16', []], FORWARD => ['W', ['W']], CHAIN => ['FORWARD', ['FORWARD']],
        STATIC => [16, []], MODE => [8, []], SUM => ['(W + 1)', ['W']],
        REPEATED => ['(W + W)', ['W', 'W']],
    );
    for my $language (qw(systemverilog verilog)) {
        for my $name (sort keys %expected) {
            my $actual = lower($bindings->{$name}, undef, $language);
            my $wanted = {text => $expected{$name}[0], parameter_references => $expected{$name}[1]};
            is($json->encode($actual), $json->encode($wanted), "$language $name preserves actual captured source meaning");
            $capture{direct}{$language}{$name} = copy($actual);
        }
    }
    my $changed = copy($environment);
    for my $name (qw(W STATIC)) {
        $changed->{parameters}{$name}{value_text} = '999';
        $changed->{parameters}{$name}{value_payload}{payload} = '999';
    }
    is(lower($bindings->{FORWARD}, $changed)->{text}, 'W', 'validation cache edits cannot replace a mutable root');
    is(lower($bindings->{STATIC}, $changed)->{text}, '16', 'validation cache edits cannot replace the selected immutable static payload');
    my $result = lower($bindings->{REPEATED}); $result->{parameter_references}[0] = 'WRONG';
    is_deeply(lower($bindings->{REPEATED})->{parameter_references}, ['W', 'W'], 'returned dependency arrays are detached');
    is($json->encode([$environment, $bindings]), $before, 'complete Core environment/binding callers keep values and JSON kinds');
};

subtest 'direct scope does not widen the composition wrapper' => sub {
    my $ok = eval {FSM::Backend::VerilogFamily::CompositionBindingEmitter->lower_expression(
        binding => $bindings->{FORWARD}, environment => $environment); 1};
    ok(!$ok, 'composition wrapper still rejects a direct-module environment');
    like($@, qr/explicit composition-top scope/, 'wrapper retains its narrow scope diagnostic');
};

subtest 'foreign, malformed and unsupported scalar profiles refuse before rendering' => sub {
    my $foreign_kind = copy($bindings->{FORWARD}); $foreign_kind->{scope}{kind} = 'composition_top';
    my $foreign_env = copy($environment); $foreign_env->{scope}{owner} = 'physical_rename';
    my $unknown_env = copy($environment); $unknown_env->{scope}{kind} = 'instance';
    my $incomplete = copy($environment); pop @{$incomplete->{declaration_order}};
    my $raw_static = copy($bindings->{STATIC});
    $raw_static->{value_payload} = {kind => 'scalar_expr', payload => '(W + 1)'};
    for my $case (
        ['foreign binding kind', $foreign_kind, undef, undef, qr/scope/],
        ['physical name used as source owner', $bindings->{FORWARD}, $foreign_env, undef, qr/scope/],
        ['unknown scope', $bindings->{FORWARD}, $unknown_env, undef, qr/explicit.*scope/],
        ['incomplete declarations', $bindings->{FORWARD}, $incomplete, undef, qr/declaration order/],
        ['aggregate item path', $bindings->{LANE}, undef, undef, qr/aggregate selection/],
        ['whole aggregate root', $bindings->{COPY}, undef, undef, qr/scalar parameter/],
        ['aggregate structure', $bindings->{ITEMS}, undef, undef, qr/unsupported.*list/],
        ['raw static expression', $raw_static, undef, undef, qr/scalar literal/],
        ['unsupported target', $bindings->{FORWARD}, undef, 'vhdl', qr/Verilog-family/],
    ) {
        my ($name, $binding, $env, $language, $reason) = @$case;
        my $snapshot = $json->encode([$binding, $env]);
        my $ok = eval {lower($binding, $env, $language); 1}; my $error = $@;
        ok(!$ok, "$name refuses"); like($error, $reason, "$name explains its boundary");
        is($json->encode([$binding, $env]), $snapshot, "$name preserves complete caller JSON kinds");
        $capture{refusals}{$name} = $error;
    }
    my $cycle = {kind => 'operator', operator => '~', source_operator => '~'};
    $cycle->{operands} = [$cycle];
    my $ok = eval {lower($cycle); 1}; my $error = $@;
    ok(!$ok, 'recursive caller graph refuses'); like($error, qr/cyclic/, 'recursion names the cyclic graph');
    $cycle->{operands} = [];
};

if (my $path = $ENV{FSMGEN_SHARED_SCALAR_RENDERER_CAPTURE}) {
    open my $out, '>', $path or die $!;
    print {$out} $json->encode(\%capture), "\n" or die $!; close $out or die $!;
}
done_testing();
