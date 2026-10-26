use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Composition::Parser;
use FSM::Composition::Top;
use FSM::Composition::Spec;
use FSM::Composition::PackageImportResolver;
use FSM::Composition::PlanBuilder;
use FSM::SourcePathResolver;

my $json = JSON::PP->new->canonical;
my %capture;
my $source = <<'FSM';
(?top:parameter_environment
  (+import shared)
  (+constants (STATIC 8))
  (?rtl:child (params (N STATIC)))
)
(?pkg:shared
  (+constants (BASE 16) (LANES (8'hA5 8'h3C)))
  (+enums (mode (OFF 0) (ON 1)))
)
FSM

sub make_spec {
    my ($entries) = @_;
    my $input = $source;
    my $raw = Lispish::multi(\$input);
    my $parsed = FSM::Composition::Parser->new->parse_source($raw);
    my $original = $parsed->top;
    return FSM::Composition::Spec->new(
        top => FSM::Composition::Top->new(name => $original->name,
            instances => $original->instances, top_symbols => $original->top_symbols,
            package_imports => $original->package_imports, raw_ast => $original->raw_ast,
            parameter_declarations => $entries),
        embedded_package_sources => $parsed->embedded_package_sources,
        raw_ast => $raw,
    );
}

sub resolve_spec {
    my ($spec) = @_;
    return FSM::Composition::PackageImportResolver->resolve_imports(
        composition_spec => $spec, fsm_file => 't/data/top-parameter-environment.fsm',
        source_path_resolver => FSM::SourcePathResolver->new,
    );
}

subtest 'actual imports precede one detached top default graph without static promotion' => sub {
    my $entries = [
        {name => 'ALIAS', value_ast => ['WIDTH']},
        {name => 'WIDTH', value_ast => ['shared.BASE']},
        {name => 'STATIC_COPY', value_ast => ['STATIC']},
        {name => 'MODE', value_ast => ['shared.mode.ON']},
        {name => 'LANE', value_ast => ['shared.LANES[1]']},
    ];
    my $before = $json->encode($entries);
    my $spec = make_spec($entries);my $top = $spec->top;
    my $supported = $top->can('parameter_declarations') && $top->can('parameter_default_graph');
    ok($supported, 'typed top owns declaration and default graph interfaces') or return;
    is($top->parameter_default_graph, undef, 'unresolved declarations expose no invented default graph');
    $entries->[1]{value_ast}[0] = 'WRONG';
    my $packages = resolve_spec($spec);
    is_deeply([sort keys %$packages], ['shared'], 'real embedded package import completes');
    my $graph = $top->parameter_default_graph;
    is_deeply($graph->{order}, [qw(ALIAS WIDTH STATIC_COPY MODE LANE)], 'authored declaration order survives forward resolution');
    is_deeply({map {$_ => $graph->{parameters}{$_}{value_text}} @{$graph->{order}}},
        {ALIAS => '16', WIDTH => '16', STATIC_COPY => '8', MODE => '1', LANE => "8'h3C"}, 'canonical package, enum, aggregate path and local static defaults resolve');
    is_deeply($graph->{default_sources}{ALIAS}, {parameter => 'ALIAS', source_module => 'parameter_environment',
        expression => ['WIDTH'], references => [{parameter => 'WIDTH', token => 'WIDTH', suffix => ''}]}, 'real top parameter reference has explicit source owner');
    is_deeply($graph->{default_sources}{WIDTH}{references}, [], 'package static value gains no invented configurable reference');
    is($top->top_symbols->resolve_payload('WIDTH'), undef, 'top parameter is absent from static symbol lookup');
    is($top->instances->[0]->parameter_overrides->[0]{value_text}, '8', 'existing child override still uses its static symbol environment');
    is($json->encode($top->parameter_declarations), $before, 'constructor owns the authored declarations');
    my $decl = $top->parameter_declarations;$decl->[0]{value_ast}[0] = 'WRONG';
    $capture{resolved} = $json->decode($json->encode($graph));
    $graph->{parameters}{WIDTH}{value_payload}{payload} = 'WRONG';
    $graph->{default_sources}{ALIAS}{references}[0]{parameter} = 'WRONG';
    is($top->parameter_default_graph->{parameters}{WIDTH}{value_text}, '16', 'default getter cannot change the owned canonical value');
    is($top->parameter_default_graph->{default_sources}{ALIAS}{references}[0]{parameter}, 'WIDTH', 'source getter cannot rewrite owned reference identity');
    is($json->encode($top->parameter_declarations), $before, 'declaration getter is detached too');
    resolve_spec($spec);
    is_deeply($top->parameter_default_graph, $capture{resolved}, 'repeated import resolution recomputes the same canonical graph');
};

subtest 'default failures leave no partial graph and never promote child values' => sub {
    for my $case (
        ['cycle', [{name => 'A', value_ast => ['B']}, {name => 'B', value_ast => ['A']}], qr/dependency cycles.*parameter 'A'.*parameter 'B'/s],
        ['unknown', [{name => 'GOOD', value_ast => ['8']}, {name => 'BAD', value_ast => ['UNKNOWN']}], qr/UNKNOWN/],
        ['duplicate', [{name => 'A', value_ast => ['8']}, {name => 'A', value_ast => ['16']}], qr/at most once/],
    ) {
        my ($name, $entries, $expected) = @$case;my $spec = make_spec($entries);
        my $ok = eval {resolve_spec($spec);1};my $error = $@;
        ok(!$ok, "$name default refuses through actual import phase");like($error, $expected, "$name retains meaningful canonical reason");
        if ($spec->top->can('parameter_default_graph')) {is($spec->top->parameter_default_graph, undef, "$name publishes no partial default graph")}
        is($spec->top->instances->[0]->parameter_overrides->[0]{value_kind}, 'deferred_symbol', "$name stops before child override folding");
        $capture{refusals}{$name} = {ok => $ok ? 1 : 0, error => $error};
    }
};

subtest 'every current HDL plan refuses configurable top declarations before child realization' => sub {
    for my $language (qw(systemverilog verilog vhdl)) {
        my $spec = make_spec([{name => 'WIDTH', value_ast => ['16']}]);
        my $ok = eval {FSM::Composition::PlanBuilder->build_plan(pipeline => {}, composition_spec => $spec,
            fsm_file => 't/data/top-parameter-environment.fsm', target_language => $language);1};my $error = $@;
        ok(!$ok, "$language cannot silently drop top parameters");
        like($error, qr/top parameter lowering is blocked.*symbolic/s, "$language names the unfinished lowering boundary before child work");
        $capture{plan_refusals}{$language} = {ok => $ok ? 1 : 0, error => $error};
    }
};

if (my $path = $ENV{FSMGEN_TOP_PARAMETER_CAPTURE}) {
    open my $out, '>', $path or die $!;print {$out} $json->encode(\%capture), "\n" or die $!;close $out or die $!;
}
done_testing();
