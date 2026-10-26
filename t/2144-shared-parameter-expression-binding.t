use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken);
use FSM::ParameterDeclarationSupport;
use FSM::Composition::ParameterBindingSupport;
use FSM::Composition::TopSymbols;

my $loaded = eval {require FSM::ParameterBindingSupport; 1};
ok($loaded, 'shared canonical expression binding owner exists') or do {
    diag($@); done_testing(); exit;
};

my $json = JSON::PP->new->canonical;
my %capture;
my $scope = {kind => 'direct_module', owner => 'original_source'};
sub copy {return $json->decode($json->encode($_[0]))}
sub literal {return {kind => 'literal', token => $_[0]}}
sub reference {
    my ($name, $suffix) = @_; $suffix //= '';
    return {parameter => $name, token => $name.$suffix, suffix => $suffix};
}
sub parameter {return {kind => 'parameter', scope => copy($scope), %{reference(@_)}}}

my $entries = [
    {name => 'ALIAS', value_ast => ['BASE']},
    {name => 'BASE', value_ast => ['16']},
    {name => 'SAME', value_ast => ['16']},
    {name => 'OTHER', value_ast => ['SAME']},
    {name => 'SUM', value_ast => ['add', 'ALIAS', ['*', 'STATIC', 'BASE']]},
    {name => 'LANES', value_ast => ["8'hA5", "8'h3C"]},
    {name => 'LANE', value_ast => ['LANES[1]']},
    {name => 'CFG', value_ast => [['tag', "4'hA"], [['data', 'LANES']]]},
    {name => 'TAG', value_ast => ['CFG.tag']},
    {name => 'OPAQUE', value_ast => {kind => 'scalar', payload => '8'}},
];
my $static = {kind => 'scalar', payload => '16'};
my $graph = FSM::ParameterDeclarationSupport->resolve_declarations(
    entries => $entries, source_module => $scope->{owner}, capture_expression => 1,
    resolve_static_symbol_payload => sub {return copy($static) if $_[0] eq 'STATIC'; return undef},
);
my $before = $json->encode([$entries, $graph, $scope, $static]);
my @lookups;
my %args = (scope => $scope, parameters => $graph->{parameters},
    resolve_static_symbol_payload => sub {push @lookups, $_[0]; return $static if $_[0] eq 'STATIC'; return undef});
my %bound;
for my $name (@{$graph->{order}}) {
    $bound{$name} = FSM::ParameterBindingSupport->bind_expression(%args,
        expression => $graph->{expressions}{$name}, references => $graph->{default_sources}{$name}{references});
}

subtest 'canonical graph binds selected identities and complete source structure' => sub {
    is_deeply($bound{ALIAS}, parameter('BASE'), 'forward alias retains its immediate declared root');
    is_deeply($bound{OTHER}, parameter('SAME'), 'equal defaults do not erase distinct selected roots');
    is_deeply($bound{BASE}, literal('16'), 'equal literal gains no guessed reference');
    is_deeply($bound{SUM}, {kind => 'operator', operator => '+', source_operator => 'add', operands => [
        parameter('ALIAS'), {kind => 'operator', operator => '*', source_operator => '*', operands => [
            {kind => 'static_symbol', scope => copy($scope), token => 'STATIC', value_payload => copy($static)},
            parameter('BASE')]}]}, 'nested operators preserve aliases, mutable identity and immutable static selection');
    is_deeply($bound{LANES}, {kind => 'list', items => [literal("8'hA5"), literal("8'h3C")]}, 'list order and literal sizing survive');
    is_deeply($bound{CFG}, {kind => 'map', member_order => [qw(tag data)], members => {
        tag => literal("4'hA"), data => parameter('LANES')}}, 'map fields are structure and values retain actual references');
    is_deeply($bound{LANE}, parameter('LANES', '[1]'), 'item selection retains its declared aggregate root');
    is_deeply($bound{TAG}, parameter('CFG', '.tag'), 'member selection retains its declared aggregate root');
    is_deeply($bound{OPAQUE}, {kind => 'payload', value => {kind => 'scalar', payload => '8'}}, 'semantic payload stays explicit');
    is_deeply(\@lookups, ['STATIC'], 'only the actual unbound symbol consults static lookup');
    is($json->encode([$entries, $graph, $scope, $static]), $before, 'complete caller values and JSON kinds stay unchanged');
    $capture{graph} = copy($graph); $capture{bindings} = copy(\%bound);
    $bound{SUM}{operands}[1]{operands}[0]{value_payload}{payload} = 'WRONG';
    $bound{ALIAS}{scope}{owner} = 'WRONG';
    is($json->encode([$entries, $graph, $scope, $static]), $before, 'returned nested static and scope records are detached');
};

subtest 'composition wrapper retains its scope and static-object contract' => sub {
    my $symbols = FSM::Composition::TopSymbols->new(constants => {STATIC => copy($static)});
    my $top_scope = {kind => 'composition_top', owner => 'top_source'};
    my $actual = FSM::Composition::ParameterBindingSupport->bind_expression(
        scope => $top_scope, parameters => $graph->{parameters}, static_symbols => $symbols,
        expression => $graph->{expressions}{ALIAS}, references => $graph->{default_sources}{ALIAS}{references});
    is_deeply($actual, {kind => 'parameter', scope => $top_scope, %{reference('BASE')}}, 'wrapper uses the same canonical parameter representation');
    for my $case (
        [{scope => $scope, static_symbols => $symbols}, qr/explicit composition-top scope/],
        [{scope => $top_scope, static_symbols => sub {return '16'}}, qr/static symbol cache/],
    ) {
        my $ok = eval {FSM::Composition::ParameterBindingSupport->bind_expression(
            %{$case->[0]}, parameters => $graph->{parameters}, expression => literal('16')); 1};
        ok(!$ok, 'composition boundary still refuses the foreign contract');
        like($@, $case->[1], 'wrapper retains its original refusal reason');
    }
};

subtest 'one binding freezes repeated static lookup while preserving repeated references' => sub {
    my $calls = 0;
    my $bound = FSM::ParameterBindingSupport->bind_expression(
        scope => $scope, parameters => $graph->{parameters},
        references => [reference('BASE'), reference('BASE')],
        resolve_static_symbol_payload => sub {return ++$calls == 1 ? '16' : '32'},
        expression => {kind => 'operator', operator => '+', source_operator => '+', operands => [
            {kind => 'symbol', token => 'STATIC'}, {kind => 'symbol', token => 'BASE'},
            {kind => 'symbol', token => 'STATIC'}, {kind => 'symbol', token => 'BASE'}]},
    );
    is($calls, 1, 'one call selects the repeated static token once');
    is_deeply($bound->{operands}[0], $bound->{operands}[2], 'both static occurrences retain the same selection');
    is_deeply($bound->{operands}[1], parameter('BASE'), 'first parameter occurrence remains explicit');
    is_deeply($bound->{operands}[3], parameter('BASE'), 'repeated parameter occurrence is not discarded');
    $bound->{operands}[0]{value_payload}{payload} = 'WRONG';
    is($bound->{operands}[2]{value_payload}{payload}, '16', 'repeated static result records are detached');
};

subtest 'malformed identity, source structure and observations refuse' => sub {
    my @cases = (
        ['unknown scope', {scope => {kind => 'instance', owner => 'x'}}, qr/explicit.*scope/],
        ['missing owner', {scope => {kind => 'direct_module'}}, qr/explicit.*scope/],
        ['missing static resolver', {resolve_static_symbol_payload => undef}, qr/static.*resolver/],
        ['discarded reference', {references => [reference('BASE')]}, qr/reference observations/],
        ['undeclared root', {expression => {kind => 'symbol', token => 'ABSENT'}, references => [reference('ABSENT')]}, qr/declared parameter/],
        ['inconsistent token', {references => [{parameter => 'BASE', token => 'SAME', suffix => ''}]}, qr/inconsistent reference/],
        ['unobserved symbol', {expression => {kind => 'symbol', token => 'BASE'}}, qr/static cache|unbound canonical symbol/],
        ['reordered observations', {expression => $graph->{expressions}{SUM}, references => [reverse @{$graph->{default_sources}{SUM}{references}}]}, qr/ordered reference observations/],
        ['unknown tree', {expression => {kind => 'raw_hdl', token => 'BASE'}}, qr/unsupported.*kind/],
        ['wrong operator alias', {expression => {kind => 'operator', operator => '+', source_operator => 'mul', operands => [literal('1'), literal('2')]}}, qr/canonical operator/],
        ['unordered map', {expression => {kind => 'map', member_order => ['a'], members => {a => literal('1'), b => literal('2')}}}, qr/unordered map/],
    );
    for my $case (@cases) {
        my ($name, $overrides, $reason) = @$case;
        my $snapshot = $json->encode([$overrides, $graph]);
        my $ok = eval {FSM::ParameterBindingSupport->bind_expression(%args,
            expression => literal('16'), references => [], %$overrides); 1};
        my $error = $@;
        ok(!$ok, "$name refuses"); like($error, $reason, "$name identifies its missing contract");
        is($json->encode([$overrides, $graph]), $snapshot, "$name preserves caller records");
        $capture{refusals}{$name} = $error;
    }
};

subtest 'transient static resolver and selected cache have no returned ownership edge' => sub {
    for my $bad (0, 1) {
        my ($weak, $result, $error);
        {
            my $cache = {payload => $bad ? 'UNKNOWN' : '16'};
            $weak = $cache; weaken($weak);
            $result = eval {FSM::ParameterBindingSupport->bind_expression(
                scope => $scope, parameters => {}, references => [],
                expression => {kind => 'symbol', token => 'STATIC'},
                resolve_static_symbol_payload => sub {return {kind => 'scalar', payload => $cache->{payload}}});};
            $error = $@;
        }
        ok(!defined($weak), 'resolver capture releases after '.($bad ? 'refusal' : 'success'));
        if ($bad) {like($error, qr/UNKNOWN/, 'invalid cache retains the canonical normalizer reason')}
        else {is_deeply($result->{value_payload}, $static, 'successful output owns only its selected semantic payload')}
    }
};

if (my $path = $ENV{FSMGEN_SHARED_BINDING_CAPTURE}) {
    open my $out, '>', $path or die $!;
    print {$out} $json->encode(\%capture), "\n" or die $!;
    close $out or die $!;
}
done_testing();
