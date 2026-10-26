use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;
use FSM::Support::ISFWidthBindings qw(build_width_binding_plan);

my $json = JSON::PP->new->canonical;
my $fixture = 't/data/isf-width-default-bindings/bindings.isf';
my $actor = FSM::Adapter::ISF->new->parse_file($fixture);
$actor->{actor_name} = 'renamed_default_expressions';
my $actor_before = $json->encode($actor);
my $scheduler = FSM::Scheduler::ISF->new;
my $context = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $actor);
my $physical_before = $json->encode($context->{actor});
my $ir = $scheduler->{ir}->build_module($context->{actor});
my $products = {actor => $actor, physical => $context->{actor}, ir => $ir,
    files => $scheduler->lower($actor)->{files}, report => $scheduler->report($actor)};
my $capture = $json->encode($products);
my $actor_scope = {kind => 'actor', owner => 'default_bindings'};
my $worker_scope = {kind => 'transaction', actor => 'default_bindings', owner => 'worker'};

sub ref_node {my ($kind, $scope, $token) = @_; return {kind => $kind, scope => $scope, token => $token}}
sub literal {return {kind => 'literal', token => $_[0]}}
sub list {return {kind => 'list', items => [@_]}}
my $constant = ref_node('constant', $actor_scope, 'FIXED');
my $package = ref_node('package_constant', {kind => 'package', owner => 'shared'}, 'shared.WIDTH');
my $enum = ref_node('enum_member', $actor_scope, 'mode.EIGHT');
my $package_enum = ref_node('enum_member', $actor_scope, 'shared.mode.EIGHT');
my $actor_base = ref_node('parameter', $actor_scope, 'BASE');
my $worker_base = ref_node('parameter', $worker_scope, 'BASE');
my $actor_capture = ref_node('capture', $actor_scope, 'ACTOR_ALIAS');
my $expected_actor = {BASE => literal('8'), ACTOR_ALIAS => $actor_base,
    C => $constant, P => $package, E => $enum, PE => $package_enum,
    LANES => list($actor_base, $constant, $package, $enum, list(literal('8'), $actor_base))};
my $expected_worker = {BASE => literal('4'), LOCAL_ALIAS => $worker_base, A => $actor_capture,
    C => $constant, P => $package, E => $enum, PE => $package_enum,
    SHADOW => literal('4'), SHADOW_ALIAS => ref_node('parameter', $worker_scope, 'SHADOW'),
    LANES => list($worker_base, $actor_capture, $constant, $package, $enum,
        list(literal('8'), ref_node('parameter', $worker_scope, 'SHADOW')))};

sub defaults {
    my ($module) = @_;
    my $map = $module->{_width_bindings}{parameter_defaults};
    return undef unless ref($map) eq 'HASH';
    return {map {$_ => $map->{$_}{expression}} keys %$map};
}

subtest 'actual module defaults preserve selected namespaces and nested aggregate shape' => sub {
    is($json->encode(defaults($ir)), $json->encode($expected_actor), 'actor defaults retain real references and static/list token identities');
    my $child = $ir->{children}{worker};
    is($json->encode(defaults($child)), $json->encode($expected_worker), 'child defaults distinguish local parameters from captured actor values');
    for my $module ($ir, $child) {
        my $map = $module->{_width_bindings}{parameter_defaults};
        next unless ref($map) eq 'HASH';
        is_deeply([sort keys %$map], [sort map {$_->{name}} @{$module->{params}}], 'default membership follows actual module parameters only');
        for my $param (@{$module->{params}}) {
            is($json->encode($map->{$param->{name}}{declaration}), $json->encode($param), 'canonical declaration record and primitive kinds are retained');
        }
    }
    is_deeply($ir->{_width_bindings}{captures}, [], 'own actor references introduce no captures');
    is($json->encode($child->{_width_bindings}{captures}), $json->encode([$actor_capture]),
        'actor alias used only in defaults still has one deduplicated capture');
    is($json->encode($actor), $actor_before, 'complete source caller remains unchanged');
    is($json->encode($context->{actor}), $physical_before, 'complete physical caller remains unchanged');
    unlike($products->{report}, qr/"parameter_defaults"\s*:/, 'private default expressions stay out of the schedule report');
};

subtest 'default graphs, declarations and captures own independent nested containers' => sub {
    my $child = $ir->{children}{worker}{_width_bindings};
    if (!exists $child->{parameter_defaults}) {fail('actual module-default graphs are required'); return}
    my $saved = $json->encode($scheduler->{ir}->build_module($context->{actor}));
    $child->{parameter_defaults}{LANES}{expression}{items}[1]{scope}{owner} = 'WRONG';
    is($child->{parameter_defaults}{A}{expression}{scope}{owner}, 'default_bindings', 'separate defaults do not share capture nodes');
    is($child->{captures}[0]{scope}{owner}, 'default_bindings', 'capture list does not alias nested default expressions');
    $child->{parameter_defaults}{A}{declaration}{value} = 'WRONG';
    my ($a) = grep {$_->{name} eq 'A'} @{$ir->{children}{worker}{params}};
    is($a->{value}, '8', 'canonical executable parameter is detached from the default snapshot');
    $ir->{_width_bindings}{parameter_defaults}{LANES}{declaration}{value}[0] = 'WRONG';
    is($ir->{_width_scopes}{actor}{params}[-1]{value}[0], 'BASE', 'canonical environment remains detached');
    is($json->encode($context->{actor}), $physical_before, 'default mutations cannot alter prepared source');
    is($json->encode($scheduler->{ir}->build_module($context->{actor})), $saved, 'fresh complete result remains exact');
};

subtest 'inconsistent canonical observations are not reconstructed from equal values' => sub {
    my $original = $json->decode($capture)->{ir};
    if (!exists $original->{_width_bindings}{parameter_defaults}) {fail('actual module-default integration is required'); return}
    for my $case (
        [sub {delete $_[0]{_width_scopes}{actor}{parameter_default_bindings}{BASE}}, qr/lacks canonical parameter default 'BASE'/],
        [sub {$_[0]{_width_scopes}{actor}{parameter_default_bindings}{LANES} = {kind => 'list', items => []}}, qr/non-empty canonical default list/],
    ) {
        my $bad = $json->decode($json->encode($original)); $case->[0]->($bad);
        my $ok = eval {build_width_binding_plan($bad); 1};
        ok(!$ok, 'missing/malformed canonical binding is refused'); like($@, $case->[1], 'refusal identifies the absent source contract');
    }
};

if (my $path = $ENV{FSMGEN_WIDTH_DEFAULT_EXPRESSION_CAPTURE}) {
    open my $out, '>', $path or die $!; print {$out} $capture, "\n" or die $!; close $out or die $!;
}
done_testing();
