use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Composition::Parser;
use FSM::Composition::PackageImportResolver;
use FSM::Composition::Plan;
use FSM::IR::IntentHIRBuilder;
use FSM::IR::StructuralRTLIRBuilder;
use FSM::SourcePathResolver;

my $json = JSON::PP->new->canonical;
sub copy { return $json->decode($json->encode($_[0])) }
my $path = 't/data/composition-top-instance-bindings.fsm';
my $raw = Lispish::multi($path);
my $before = $json->encode($raw);
my $spec = FSM::Composition::Parser->new->parse_source($raw);
my $top = $spec->top;
my %capture;
my $has_top = $top->can('parameter_environment');
my $has_plan = FSM::Composition::Plan->can('parameter_environment');
ok($has_top, 'actual top supplies one canonical detached environment');
ok($has_plan, 'plan owns a detached environment getter');
if (!$has_top || !$has_plan) { done_testing(); exit }

sub capture_refusal {
    my ($label, $callback, $pattern) = @_;
    my $ok = eval {$callback->(); 1};
    my $error = $@;
    ok(!$ok, "$label refuses");
    like($error, $pattern, "$label identifies the pending boundary");
    $capture{refusals}{$label} = {accepted => $ok ? 1 : 0, error => $error};
}

capture_refusal('unresolved top', sub {$top->parameter_environment}, qr/requires resolved.*environment/s);
capture_refusal('unresolved plan', sub {FSM::Composition::Plan->new(raw_spec => $spec)}, qr/requires resolved.*environment/s);
FSM::Composition::PackageImportResolver->resolve_imports(composition_spec => $spec,
    fsm_file => $path, source_path_resolver => FSM::SourcePathResolver->new);
my $graph_before = $top->parameter_default_graph;
my $bindings_before = $top->parameter_default_bindings;
my $statics_before = {constants => $top->top_symbols->constants,
    enums => $top->top_symbols->enums, packages => [sort keys %{$top->top_symbols->imported_packages}]};
my $environment = $top->parameter_environment;
is_deeply([sort keys %$environment], [sort qw(scope declaration_order parameters default_sources default_bindings)],
    'environment has exactly the distinct source/value/binding families');
is_deeply($environment->{scope}, {kind => 'composition_top', owner => 'top_instance_bindings'}, 'real lexical owner remains explicit');
is_deeply($environment->{declaration_order}, [qw(W SAME ALIAS LANES FRAME)], 'authored order is preserved independently of lazy default resolution');
is_deeply($environment->{parameters}, $graph_before->{parameters}, 'complete normalized caches retain their original types');
is_deeply($environment->{default_sources}, $graph_before->{default_sources}, 'complete authored sources remain separate from caches');
is_deeply($environment->{default_bindings}, $bindings_before, 'complete scoped default trees remain separate from caches');
is($environment->{parameters}{W}{value_text}, '16', 'W has its canonical original default');
is($environment->{parameters}{SAME}{value_text}, '16', 'equal numeric default remains a distinct declaration');
is($environment->{default_bindings}{ALIAS}{parameter}, 'W', 'alias default retains its immediate root');
is($environment->{default_bindings}{W}{kind}, 'static_symbol', 'static default keeps its own binding kind');
is($environment->{default_bindings}{W}{token}, 'C', 'static default keeps its actual source lookup');
is_deeply($top->parameter_default_graph, $graph_before, 'environment read preserves the complete existing graph');
is_deeply($top->parameter_default_bindings, $bindings_before, 'environment read preserves existing binding products');
is_deeply({constants => $top->top_symbols->constants, enums => $top->top_symbols->enums,
    packages => [sort keys %{$top->top_symbols->imported_packages}]}, $statics_before, 'parameters do not enter the static symbol namespaces');
my $plan = FSM::Composition::Plan->new(lane => 'C3', top_name => $top->name, raw_spec => $spec);
my $snapshot = copy($environment);
is_deeply($plan->parameter_environment, $snapshot, 'actual raw spec supplies the complete constructor snapshot');
$capture{environment} = copy($environment);
$capture{graph} = copy($graph_before);
$capture{bindings} = copy($bindings_before);
$environment->{default_bindings}{ALIAS}{scope}{owner} = 'wrong';
$environment->{default_sources}{W} = {};
$environment->{parameters}{W}{value_text} = 'wrong';
is_deeply($top->parameter_environment, $snapshot, 'top getter detaches values, sources and nested binding scope');
my $plan_view = $plan->parameter_environment;
$plan_view->{declaration_order}[0] = 'WRONG';
$plan_view->{default_bindings}{ALIAS}{scope}{owner} = 'wrong';
is_deeply($plan->parameter_environment, $snapshot, 'plan getter detaches every nested family');

# Re-resolve the same actual caller object through its supported static cache API.
$top->top_symbols->store_constant('C', {kind => 'scalar', payload => '32'});
$top->resolve_parameter_defaults;
is($top->parameter_environment->{parameters}{W}{value_text}, '32', 'actual successful retry changes the live top environment');
is_deeply($plan->parameter_environment, $snapshot, 'constructor snapshot remains stable when caller retries');
my $new_plan = FSM::Composition::Plan->new(raw_spec => $spec);
is($new_plan->parameter_environment->{parameters}{W}{value_text}, '32', 'new constructor selects the current resolved caller environment');
$top->top_symbols->store_constant('C', {kind => 'scalar', payload => 'UNKNOWN'});
capture_refusal('failed actual retry', sub {$top->resolve_parameter_defaults}, qr/(UNKNOWN|unresolved|unknown)/i);
capture_refusal('failed top environment', sub {$top->parameter_environment}, qr/requires resolved.*environment/s);
capture_refusal('failed plan environment', sub {FSM::Composition::Plan->new(raw_spec => $spec)}, qr/requires resolved.*environment/s);
is_deeply($plan->parameter_environment, $snapshot, 'refused retry cannot corrupt the already owned plan snapshot');

for my $builder (qw(FSM::IR::IntentHIRBuilder FSM::IR::StructuralRTLIRBuilder)) {
    my $ir = $builder eq 'FSM::IR::IntentHIRBuilder'
        ? $builder->build_from_composition_plan(composition_plan => $plan)
        : $builder->build_from_composition_plan($plan);
    is_deeply($ir->parameter_environment, $snapshot, 'forward IR retains the original snapshot after caller retry failure');
    is_deeply($plan->parameter_environment, $snapshot, 'IR propagation preserves the complete caller environment');
}
my $static_text = '(?top:plain (?rtl:u (module child_rtl)))';
my $static_spec = FSM::Composition::Parser->new->parse_source(scalar Lispish::multi(\$static_text));
is($static_spec->top->parameter_environment, undef, 'no-parameter source has no environment');
my $static_plan = FSM::Composition::Plan->new(lane => 'C3', top_name => 'plain', raw_spec => $static_spec);
is($static_plan->parameter_environment, undef, 'static plan gains no environment');
ok(!exists($static_plan->{parameter_environment}), 'ordinary plan keeps the exact legacy key set');
my $legacy = FSM::Composition::Plan->new(lane => 'C1', top_name => 'legacy');
is_deeply({%$legacy}, {lane => 'C1', top_name => 'legacy', ports => [], links => [], resolved_links => [],
    nets => [], instances => [], auxiliary_assignments => [], shared_datapath_candidates => [], raw_spec => undef},
    'complete ordinary constructor product remains exact');
is($json->encode($raw), $before, 'complete parsed source stays unchanged');
if (my $out_path = $ENV{FSMGEN_PLAN_ENVIRONMENT_CAPTURE}) {
    open my $out, '>', $out_path or die $!;
    print {$out} $json->encode(\%capture), "\n" or die $!;
    close $out or die $!;
}
done_testing();
