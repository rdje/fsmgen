use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;

my $json = JSON::PP->new->canonical;
my $fixture = 't/data/isf-width-binding-expressions/bindings.isf';
my $actor = FSM::Adapter::ISF->new->parse_file($fixture);
$actor->{actor_name} = 'renamed_width_bindings';
my $actor_before = $json->encode($actor);
my $scheduler = FSM::Scheduler::ISF->new;
my $context = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $actor);
my $physical_before = $json->encode($context->{actor});
my $ir = $scheduler->{ir}->build_module($context->{actor});
my $products = {actor => $actor, physical => $context->{actor}, ir => $ir,
    files => $scheduler->lower($actor)->{files}, report => $scheduler->report($actor)};
my $capture = $json->encode($products);
my $actor_scope = {kind => 'actor', owner => 'width_bindings'};
my $direct_scope = {kind => 'transaction', actor => 'width_bindings', owner => 'direct'};
my $worker_scope = {kind => 'transaction', actor => 'width_bindings', owner => 'worker'};

sub node {my ($kind, $scope, $token) = @_; return {kind => $kind, scope => $scope, token => $token}}
sub inline {my ($token, $value) = @_; return {kind => 'inline_parameter', scope => $direct_scope,
    token => $token, default => $value}}
my $actor_alias = node('parameter', $actor_scope, 'ALIAS');
my $capture_alias = node('capture', $actor_scope, 'ALIAS');
my $static = node('constant', $actor_scope, 'FIXED');
my $packaged = node('package_constant', {kind => 'package', owner => 'shared'}, 'shared.WIDTH');
my $expected_parent = {
    data => $actor_alias, saved => node('parameter', $actor_scope, 'BASE'),
    isf_port_direct_answer => inline('W', $actor_alias),
    isf_port_direct_payload => inline('CHAIN', inline('W', $actor_alias)),
    isf_port_direct_fixed => inline('C', $static),
    isf_port_direct_packaged => inline('P', $packaged),
    isf_port_direct_enumerated => inline('E', node('enum_member', $actor_scope, 'mode.EIGHT')),
    isf_port_direct_package_enumerated => inline('PE', node('enum_member', $actor_scope, 'shared.mode.EIGHT')),
    isf_port_direct_literal_param => inline('LIT', {kind => 'literal', token => '8'}),
};
my $expected_worker = {
    payload => node('parameter', $worker_scope, 'LOCAL_ALIAS'),
    response => node('parameter', $worker_scope, 'BASE'),
    inherited => $capture_alias, fixed => $static, packaged => $packaged,
};

sub expressions {
    my ($module) = @_;
    my $plan = $module->{_width_bindings};
    return undef unless ref($plan) eq 'HASH';
    return {map {$_ => $plan->{declarations}{$_}{expression}} keys %{$plan->{declarations}}};
}

subtest 'actual parent and child scopes bind symbolic widths without default guessing' => sub {
    is($json->encode(expressions($ir)), $json->encode($expected_parent),
        'parent keeps real parameters and full immutable local alias/static/literal identities');
    my $child = $ir->{children}{worker};
    is($json->encode(expressions($child)), $json->encode($expected_worker),
        'child keeps its real local parameters and captures only inherited actor values');
    for my $module ($ir, $child) {
        my $plan = $module->{_width_bindings};
        next unless ref($plan) eq 'HASH';
        is_deeply($plan->{module_parameters}, $module->{_width_scopes}{module_parameters},
            'parameter ownership is explicit, independent of physical module names');
        for my $name (sort keys %{$module->{_width_declarations}}) {
            is_deeply($plan->{declarations}{$name}{declaration}, $module->{_width_declarations}{$name},
                "$name keeps its complete actual physical/source declaration");
        }
    }
    is_deeply($ir->{_width_bindings} && $ir->{_width_bindings}{captures}, [], 'parent has no foreign parameter captures');
    is($json->encode($child->{_width_bindings} && $child->{_width_bindings}{captures}),
        $json->encode([$capture_alias]), 'child capture list retains the exact lexical actor alias');
    is($json->encode($actor), $actor_before, 'complete source caller and token kinds are unchanged');
    is($json->encode($context->{actor}), $physical_before, 'complete prepared caller remains unchanged');
    unlike($products->{report}, qr/"_width_bindings"\s*:/, 'private expressions stay out of schedule JSON');
};

subtest 'source and expression containers remain detached within and across modules' => sub {
    my $plan = $ir->{_width_bindings};
    my $child = $ir->{children}{worker}{_width_bindings};
    if (!defined($plan) || !defined($child)) {fail('actual module binding plans are required'); return}
    my $fresh_before = $json->encode($scheduler->{ir}->build_module($context->{actor}));
    $child->{declarations}{inherited}{expression}{scope}{owner} = 'WRONG';
    is($child->{captures}[0]{scope}{owner}, 'width_bindings', 'capture collection does not alias an expression');
    $child->{captures}[0]{token} = 'WRONG';
    is($plan->{declarations}{data}{expression}{token}, 'ALIAS', 'parent and child plans are detached');
    $plan->{declarations}{isf_port_direct_payload}{expression}{default}{default}{token} = 'WRONG';
    is($plan->{declarations}{isf_port_direct_answer}{expression}{default}{token}, 'ALIAS',
        'independent declaration expressions do not share nested alias nodes');
    $plan->{declarations}{data}{declaration}{source}{token} = 'WRONG';
    is($ir->{_width_declarations}{data}{source}{token}, 'ALIAS', 'plan source snapshot does not alias original metadata');
    is($ir->{_width_scopes}{transactions}{direct}{parameter_default_bindings}{W}{token}, 'ALIAS',
        'inlined defaults do not alias canonical observations');
    is($json->encode($context->{actor}), $physical_before, 'mutation cannot alter prepared input');
    is($json->encode($scheduler->{ir}->build_module($context->{actor})), $fresh_before, 'fresh complete result remains exact');
};

subtest 'literal declarations acquire no inferred dependencies' => sub {
    my $plain = FSM::Adapter::ISF->new->parse_file('t/data/isf-generated-width-ir/plain.isf');
    my $module = FSM::Scheduler::ISF->new->{ir}->build_module($plain);
    for my $item ($module, values %{$module->{children}}) {
        my $plan = $item->{_width_bindings};
        is_deeply($plan && $plan->{declarations}, {}, 'literal/type/default widths have no invented expression source');
        is_deeply($plan && $plan->{captures}, [], 'equal numeric defaults cannot invent captures');
    }
};

subtest 'inconsistent private bindings refuse instead of borrowing numeric defaults' => sub {
    my $original = $json->decode($capture)->{ir};
    if (!exists $original->{_width_bindings}) {fail('actual semantic binding integration is required'); return}
    require FSM::Support::ISFWidthBindings;
    for my $case (
        [sub {$_[0]{_width_declarations}{data}{source}{token} = 'MISSING'}, qr/lacks declared parameter/],
        [sub {$_[0]{_width_declarations}{data}{source}{owner} = 'WRONG'}, qr/actor scope/],
        [sub {$_[0]{_width_scopes}{transactions}{direct}{parameter_default_bindings}{W}
            = {kind => 'transaction_parameter', token => 'CHAIN'}}, qr/cyclic inline parameter/],
    ) {
        my $bad = $json->decode($json->encode($original)); $case->[0]->($bad);
        my $ok = eval {FSM::Support::ISFWidthBindings::build_width_binding_plan($bad); 1};
        ok(!$ok, 'invalid semantic association is refused'); like($@, $case->[1], 'refusal identifies the missing binding contract');
    }
};

if (my $path = $ENV{FSMGEN_WIDTH_BINDING_CAPTURE}) {
    open my $out, '>', $path or die $!; print {$out} $capture, "\n" or die $!; close $out or die $!;
}
done_testing();
