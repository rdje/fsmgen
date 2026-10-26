use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Composition::Parser;
use FSM::Composition::PackageImportResolver;
use FSM::Composition::Top;
use FSM::Composition::TopSymbols;
use FSM::ParameterDeclarationSupport;
use FSM::SourcePathResolver;

my $json = JSON::PP->new->canonical;
my %capture;
my $path = 't/data/composition-top-default-bindings.fsm';
my $scope = {kind => 'composition_top', owner => 'top_default_bindings'};
sub copy {return $json->decode($json->encode($_[0]))}
sub literal {return {kind => 'literal', token => $_[0]}}
sub reference {my ($name, $suffix) = @_;$suffix //= '';return {parameter => $name, token => $name.$suffix, suffix => $suffix}}
sub bound_parameter {return {kind => 'parameter', scope => copy($scope), %{reference(@_)}}}
sub resolve_spec {
    FSM::Composition::PackageImportResolver->resolve_imports(composition_spec => $_[0],
        fsm_file => $path, source_path_resolver => FSM::SourcePathResolver->new);
}

subtest 'shared graph captures canonical trees without changing values, source or registration' => sub {
    my $entries = [{name => 'ALIAS', value_ast => ['W']}, {name => 'W', value_ast => ['16']}];
    my (%graphs, %registered);
    for my $mode (0, 1) {
        $graphs{$mode} = FSM::ParameterDeclarationSupport->resolve_declarations(entries => copy($entries),
            source_module => 'shared_binding_source', capture_expression => $mode,
            on_resolved => sub {push @{$registered{$mode}}, [@_]});
    }
    my $captured = delete $graphs{1}{expressions};
    is_deeply($captured, {ALIAS => {kind => 'symbol', token => 'W'}, W => literal('16')}, 'graph retains canonical source trees in a separate opt-in map');
    is($json->encode($graphs{1}), $json->encode($graphs{0}), 'whole old normalized/source graph remains exact');
    is($json->encode($registered{1}), $json->encode($registered{0}), 'source-order registration receives the same detached old records');
    $capture{shared} = {graph => $graphs{0}, expressions => $captured, registered => $registered{1}};
};

subtest 'actual defaults bind observed identities rather than equal values' => sub {
    my $raw = Lispish::multi($path);my $raw_before = $json->encode($raw);
    my $spec = FSM::Composition::Parser->new->parse_source($raw);my $top = $spec->top;
    resolve_spec($spec);
    $capture{graph} = $top->parameter_default_graph;
    $capture{raw} = copy($raw);$capture{static} = $top->top_symbols->as_hashref;
    ok($top->can('parameter_default_bindings'), 'typed top exposes detached default bindings') or return;
    my $bindings = $top->parameter_default_bindings;
    is_deeply($bindings->{FORWARD}, bound_parameter('ALIAS'), 'forward alias remains a real reference to its immediate declaration');
    is_deeply($bindings->{ALIAS}, bound_parameter('BASE'), 'first equal default retains BASE identity');
    is_deeply($bindings->{OTHER}, bound_parameter('SAME'), 'second equal default retains distinct SAME identity');
    is($json->encode($bindings->{LITERAL}), $json->encode(literal('16')), 'equal literal retains its original token kind without invented binding');
    is_deeply($bindings->{LANE}, bound_parameter('LANES', '[1]'), 'aggregate item suffix retains its real root');
    is_deeply($bindings->{TAG}, bound_parameter('CFG', '.tag'), 'aggregate member suffix retains its real root');
    is_deeply($bindings->{CFG}, {kind => 'map', member_order => [qw(tag data)], members => {
        tag => literal("4'hA"), data => bound_parameter('LANES')}}, 'actual map structure binds member values without treating field names as symbols');
    is_deeply($bindings->{LANES}, {kind => 'list', items => [literal("8'hA5"), literal("8'h3C")]}, 'actual aggregate literals retain ordered structure');
    is_deeply($bindings->{SUM}, {kind => 'operator', operator => '+', source_operator => '+', operands => [bound_parameter('BASE'),
        {kind => 'static_symbol', scope => copy($scope), token => 'STATIC', value_payload => $top->top_symbols->resolve_payload('STATIC')}]}, 'operator keeps real parameter and immutable static cache distinct');
    for my $case (['STATIC_COPY', 'shared.FIXED'], ['MODE', 'mode.BIG']) {
        is_deeply($bindings->{$case->[0]}, {kind => 'static_symbol', scope => copy($scope), token => $case->[1],
            value_payload => $top->top_symbols->resolve_payload($case->[1])}, 'package and enum static references retain lookup identity and selected cache');
    }
    is($json->encode($raw), $raw_before, 'whole source caller remains unchanged');
    $capture{bindings} = copy($bindings);
    $bindings->{ALIAS}{scope}{owner} = 'WRONG';$bindings->{SUM}{operands}[1]{value_payload}{payload} = 'WRONG';
    is($json->encode($top->parameter_default_bindings), $json->encode($capture{bindings}), 'getter cannot rewrite owned source identity or static cache');
    my $old = $json->encode($top->parameter_default_bindings);
    $top->top_symbols->store_constant('STATIC', {kind => 'scalar', payload => '32'});
    is($json->encode($top->parameter_default_bindings), $old, 'already selected static cache is an immutable snapshot');
    $top->resolve_parameter_defaults;
    is($top->parameter_default_bindings->{SUM}{operands}[1]{value_payload}{payload}, '32', 'explicit retry selects the updated static cache');
    $top->top_symbols->store_constant('STATIC', {kind => 'scalar', payload => 'UNKNOWN'});
    my $ok = eval {$top->resolve_parameter_defaults;1};my $error = $@;
    ok(!$ok, 'bad retry refuses');like($error, qr/UNKNOWN/, 'retry preserves canonical reason');
    is($top->parameter_default_graph, undef, 'bad retry clears stale/partial normalized graph');
    is($top->parameter_default_bindings, undef, 'bad retry clears stale/partial binding graph');
    $capture{retry_refusal} = $error;
    is(FSM::Composition::Top->new(name => 'empty')->parameter_default_bindings, undef, 'plain top gains no invented binding graph');
};

subtest 'binding requires actual observations and declarations, never a matching value guess' => sub {
    my $loaded = eval {require FSM::Composition::ParameterBindingSupport;1};
    ok($loaded, 'canonical composition binding owner exists') or return;
    my %args = (scope => $scope, parameters => {BASE => {value_text => '16'}},
        static_symbols => FSM::Composition::TopSymbols->new);
    for my $case (
        ['discarded reference', literal('16'), [reference('BASE')], qr/reference observations/],
        ['unobserved symbol', {kind => 'symbol', token => 'BASE'}, [], qr/static cache|unbound canonical symbol/],
        ['missing declaration', {kind => 'symbol', token => 'OTHER'}, [reference('OTHER')], qr/declared parameter/],
        ['unknown tree', {kind => 'raw_hdl', token => 'BASE'}, [], qr/unsupported.*kind/],
    ) {
        my ($name, $expression, $references, $reason) = @$case;
        my $ok = eval {FSM::Composition::ParameterBindingSupport->bind_expression(%args,
            expression => $expression, references => $references);1};my $error = $@;
        ok(!$ok, "$name refuses");like($error, $reason, "$name names the actual missing contract");
        $capture{refusals}{$name} = {ok => $ok ? 1 : 0, error => $error};
    }
};

subtest 'programmatic scalar static caches keep canonical admission and detached bindings' => sub {
    for my $value ('8', '0x10') {
        my $top = FSM::Composition::Top->new(name => 'scalar_cache',
            parameter_declarations => [{name => 'W', value_ast => ['C']}],
            top_symbols => FSM::Composition::TopSymbols->new(constants => {C => $value}));
        my $ok = eval {$top->resolve_parameter_defaults;1};
        ok($ok, 'scalar cache normalizes through the shared value helper') or do {diag($@);next};
        ok($top->can('parameter_default_bindings'), 'scalar cache also has the required binding view') or next;
        my $graph = $top->parameter_default_graph;my $bound = $top->parameter_default_bindings;
        is_deeply($bound->{W}{value_payload}, $graph->{parameters}{W}{value_payload}, 'selected scalar cache and canonical default retain identical semantics');
        is($bound->{W}{kind}, 'static_symbol', 'matching numeric value never becomes a configurable parameter');
        $bound->{W}{value_payload}{payload} = 'WRONG';
        is_deeply($top->parameter_default_bindings->{W}{value_payload}, $graph->{parameters}{W}{value_payload}, 'scalar cache binding getter is detached');
        $capture{scalar_caches}{$value} = {graph => $graph, bindings => $top->parameter_default_bindings};
    }
};

if (my $out_path = $ENV{FSMGEN_TOP_DEFAULT_BINDING_CAPTURE}) {
    open my $out, '>', $out_path or die $!;print {$out} $json->encode(\%capture), "\n" or die $!;close $out or die $!;
}
done_testing();
