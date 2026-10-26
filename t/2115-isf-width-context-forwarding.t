use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $json = JSON::PP->new->canonical;
my %products;
for my $pair (
    ['generated', 't/data/isf-width-context-forwarding.isf'],
    ['library', 't/data/isf-reusable-width-ir/library.isf'],
    ['atl', 't/data/isf-reusable-width-ir/atl.isf'],
) {
    my ($case, $path) = @$pair;
    my $actor = FSM::Adapter::ISF->new->parse_file($path);
    my $before = $json->encode($actor);
    my $scheduler = FSM::Scheduler::ISF->new;
    my $ir = $scheduler->{ir}->build_module($actor);
    $products{$case} = {actor => $json->decode($before), ir => $ir,
        files => $scheduler->lower($actor)->{files}, report => $scheduler->report($actor)};
    is($json->encode($actor), $before, "$case complete source caller remains unchanged");
}
my $capture = $json->encode(\%products);
my $ir = $products{generated}{ir};
my $plan = $ir->{_width_forwarding};
my $scope = {kind => 'actor', owner => 'width_forwarding'};
my $source = {kind => 'capture', scope => $scope, token => 'BASE'};
my $peer = {kind => 'capture', scope => $scope, token => 'SAME'};

subtest 'each actual activation forwards the declared actor identity to its context slot' => sub {
    ok(ref($plan) eq 'HASH', 'actual composition owns a private context-forwarding plan');
    return unless ref($plan) eq 'HASH';
    is_deeply($plan->{producer}, {module => 'width_forwarding', instance => 'width_forwarding', module_parameters => $scope},
        'producer uses the actual parent instance and its constructor parameter scope');
    is_deeply([map {$_->{instance}} @{$plan->{instances}}],
        [map {$_->{instance}} @{$ir->{spawn_instances}}], 'membership/order follows actual activation records, including do and rule triggers');
    is_deeply([sort map {$_->{instance}} @{$plan->{instances}}],
        [sort qw(first second defaults parent_worker_do_0 parent_worker_repeat_do_0 parent_worker_cond_do_0 kick_worker_trigger_0)],
        'static-zero activation is absent and every real instance is present');
    for my $instance (@{$plan->{instances}}) {
        is($instance->{module}, 'worker', 'target is the actual child module');
        is_deeply($instance->{module_parameters}, {kind => 'transaction', actor => 'width_forwarding', owner => 'worker'},
            'target module parameters belong to the transaction');
        is_deeply($instance->{bindings}, [{target_parameter => 'isf_width_capture_1', source_parameter => 'BASE',
            source_kind => 'module_parameter', source_identity => $source},
            {target_parameter => 'isf_width_capture_2', source_parameter => 'SAME',
                source_kind => 'module_parameter', source_identity => $peer}],
            'equal default-only captures remain distinct despite selected authored overrides');
        is($json->encode($instance->{selection}), $json->encode($ir->{_width_scopes}{generated_instances}{$instance->{instance}}),
            'complete actual selection/override source environment is retained separately');
    }
    unlike($products{generated}{report}, qr/"_width_forwarding"\s*:/, 'forwarding remains outside public reports');
};

subtest 'actual reusable and ATL instances preserve their own real parameter environments' => sub {
    for my $case (qw(library atl)) {
        my $module = $products{$case}{ir};
        my $forwarding = $module->{_width_forwarding};
        unless (ref($forwarding) eq 'HASH') {fail("$case actual forwarding inventory is required"); next}
        is(scalar @{$forwarding->{instances}}, 2, "$case actual instances are inventoried");
        for my $instance (@{$forwarding->{instances}}) {
            my $child = $module->{children}{$instance->{module}};
            ok($child, 'target identifies an existing actual child');
            is_deeply($instance->{module_parameters}, {kind => 'actor', owner => 'child'}, 'source export owns real child parameters');
            is_deeply($instance->{bindings}, [], 'real reusable parameters do not acquire spurious actor context imports');
            is($json->encode($instance->{selection}), $json->encode($child->{_width_scopes}{instance}),
                'selected default/override source environment remains exact');
        }
    }
};

subtest 'source identity and nested results remain independent of physical names and other instances' => sub {
    unless (ref($plan) eq 'HASH') {fail('context plan is required'); return}
    my $actor = $json->decode($json->encode($products{generated}{actor})); $actor->{actor_name} = 'renamed_context_parent';
    my $fresh = FSM::Scheduler::ISF->new->{ir}->build_module($actor)->{_width_forwarding};
    is($fresh->{producer}{instance}, 'renamed_context_parent', 'actual producer instance follows the explicit module rename');
    is_deeply($fresh->{producer}{module_parameters}, $scope, 'lexical owner remains the source actor');
    is_deeply($fresh->{instances}[0]{bindings}, $plan->{instances}[0]{bindings}, 'complete symbolic binding ignores physical ancestry and default coincidence');
    my $sibling = $json->encode($plan->{instances}[1]);
    $plan->{instances}[0]{bindings}[0]{source_identity}{scope}{owner} = 'WRONG';
    $plan->{instances}[0]{selection}{parameters}[0]{value} = 'WRONG';
    is($json->encode($plan->{instances}[1]), $sibling, 'other actual instances own their nested records');
    is($ir->{children}{worker}{_width_symbols}{capture_parameters}[0]{source}{scope}{owner}, 'width_forwarding', 'child target source remains detached');
    is($ir->{_width_scopes}{generated_instances}{first}{parameters}[0]{value}, '8', 'original selected resolved module default remains detached');
    is($fresh->{instances}[0]{bindings}[0]{source_identity}{scope}{owner}, 'width_forwarding', 'fresh result remains detached');
};

subtest 'missing or conflicting semantic identities cannot borrow equal defaults' => sub {
    unless (ref($plan) eq 'HASH') {fail('context plan is required'); return}
    my $original = $json->decode($capture)->{generated}{ir};
    for my $case (
        [sub {$_[0]{params} = [grep {$_->{name} ne 'BASE'} @{$_[0]{params}}]}, qr/no declared producing parameter for actor capture 'BASE'/],
        [sub {$_[0]{children}{worker}{_width_symbols}{capture_parameters}[0]{source}{scope}{owner} = 'FOREIGN'}, qr/no declared producing parameter for actor capture 'BASE'/],
        [sub {$_[0]{children}{worker}{_width_symbols}{capture_parameters}[0]{name} = 'WIDTH'}, qr/conflicts with real child parameter 'WIDTH'/],
        [sub {$_[0]{children}{worker}{_width_symbols}{capture_parameters}[1]{name} = 'isf_width_capture_1'}, qr/duplicate child context target 'isf_width_capture_1'/],
        [sub {push @{$_[0]{_width_scopes}{generated_instances}{first}{parameter_overrides}}, {name => 'isf_width_capture_1', value => '8'}}, qr/conflicts with authored override 'isf_width_capture_1'/],
    ) {
        my $bad = $json->decode($json->encode($original)); $case->[0]->($bad);my $before = $json->encode($bad);
        my $ok = eval {FSM::Support::ISFWidthForwarding::build_width_forwarding_plan($bad); 1};
        ok(!$ok, 'invalid semantic producer/target relationship refuses');like($@, $case->[1], 'refusal identifies the actual missing/conflicting identity');
        is($json->encode($bad), $before, 'refusal does not mutate the complete caller');
    }
};

subtest 'an explicit imported parent context forwards its own slot without value lookup' => sub {
    unless (ref($plan) eq 'HASH') {fail('context plan is required'); return}
    my $module = $json->decode($capture)->{generated}{ir};
    $module->{_width_symbols}{module_parameters} = {kind => 'transaction', actor => 'width_forwarding', owner => 'wrapper'};
    $module->{params} = [];
    $module->{_width_symbols}{capture_parameters} = $json->decode($json->encode($module->{children}{worker}{_width_symbols}{capture_parameters}));
    $module->{_width_symbols}{capture_parameters}[0]{value} = '99';
    $module->{_width_symbols}{capture_parameters}[1]{value} = '4';
    my $before = $json->encode($module);
    my $forwarding = FSM::Support::ISFWidthForwarding::build_width_forwarding_plan($module);
    is_deeply($forwarding->{instances}[0]{bindings}, [
        {target_parameter => 'isf_width_capture_1', source_parameter => 'isf_width_capture_1', source_kind => 'context_parameter', source_identity => $source},
        {target_parameter => 'isf_width_capture_2', source_parameter => 'isf_width_capture_2', source_kind => 'context_parameter', source_identity => $peer}],
        'private typed parent contexts supply exact imported source identities');
    is($json->encode($module), $before, 'private imported-context join does not mutate the caller');
};

if (my $path = $ENV{FSMGEN_WIDTH_FORWARDING_CAPTURE}) {
    open my $out, '>', $path or die $!;print {$out} $capture, "\n" or die $!;close $out or die $!;
}
done_testing();
