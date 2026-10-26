use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;
use FSM::Support::ISFWidthForwarding qw(build_width_forwarding_plan);

my $json = JSON::PP->new->canonical;
my %products;
for my $pair (
    ['children', 't/data/isf-domain-width-forwarding.isf'],
    ['plain', 't/data/isf-formal-width-ir/domains.isf'],
) {
    my ($case, $path) = @$pair;
    my $actor = FSM::Adapter::ISF->new->parse_file($path);
    my $before = $json->encode($actor);
    my $scheduler = FSM::Scheduler::ISF->new;
    my $formal = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $actor);
    my $physical = $formal ? $formal->{actor} : $actor;
    my $physical_before = $json->encode($physical);
    my $ir = $scheduler->{ir}->build_module($physical);
    my $partition_before = $json->encode($ir->{domain_partition});
    my $domains = $scheduler->_multi_domain_realizations($physical, $ir->{domain_partition});
    $products{$case} = {actor => $actor, physical => $physical, ir => $ir, realizations => $domains,
        files => $scheduler->lower($actor)->{files}, report => $scheduler->report($actor)};
    is($json->encode($actor), $before, "$case whole source caller is unchanged");
    is($json->encode($physical), $physical_before, "$case whole prepared caller is unchanged");
    is($json->encode($ir->{domain_partition}), $partition_before, "$case original partition remains unchanged");
}
my $capture = $json->encode(\%products);

subtest 'actual final domain maps bind physical producer and child identities only' => sub {
    for my $real (@{$products{children}{realizations}}) {
        my $module = $real->{ir};
        my $plan = $module->{_width_forwarding};
        is($plan->{producer}{instance}, $real->{domain}{instance}, 'producer uses the actual outer domain instance');
        is($plan->{producer}{module}, $module->{actor_name}, 'parent definition module is already explicit');
        my $normal = build_width_forwarding_plan($module);
        my $expected = $json->decode($json->encode($normal));
        $expected->{producer}{instance} = $real->{domain}{instance};
        for my $target (@{$expected->{instances}}) {
            my $selection = $target->{selection};
            $target->{instance} = $real->{names}{instances}{$selection->{instance}};
            $target->{module} = $real->{names}{modules}{$selection->{child}};
            my $top = $products{children}{files}{'domain_width_forwarding_top.fsm'};
            like($top, qr/\(\?fsmc:\Q$target->{instance}\E\s+\Q$target->{module}\E(?:\s|\))/,
                'independent source emitter uses the same actual instance/module pair');
        }
        is($json->encode($plan), $json->encode($expected), 'whole mapped plan preserves lexical scopes, parameter slots and selected environments exactly');
        is_deeply($plan->{producer}{module_parameters}, {kind => 'actor', owner => 'domain_width_forwarding'},
            'domain module rename does not change the source configuration owner');
        for my $target (@{$plan->{instances}}) {
            is_deeply([map {$_->{source_identity}{token}} @{$target->{bindings}}], [qw(BASE SAME)], 'equal captures retain distinct source tokens');
            is_deeply([map {$_->{source_identity}{scope}{owner}} @{$target->{bindings}}],
                [('domain_width_forwarding') x 2], 'logical owners do not become physical domain names');
        }
    }
    my ($core) = grep {$_->{domain}{name} eq 'core'} @{$products{children}{realizations}};
    isnt($core->{names}{instances}{w0}, 'core__w0', 'existing port collision exercises final allocated identity');
    my ($first) = grep {$_->{selection}{instance} eq 'w0'} @{$core->{ir}{_width_forwarding}{instances}};
    is($first->{instance}, $core->{names}{instances}{w0}, 'context target consumes the collision result');
};

subtest 'plain domains acquire no invented composition producer and mapped results detach' => sub {
    for my $real (@{$products{plain}{realizations}}) {
        ok(!exists $real->{ir}{_width_forwarding}, 'domain without child instances has no forwarding plan');
    }
    my $real = $products{children}{realizations}[0];
    my $module = $real->{ir};
    my $normal = build_width_forwarding_plan($module);
    unless (FSM::Support::ISFWidthForwarding->can('remap_width_forwarding_plan')) {fail('actual domain remapper is required'); return}
    my $normal_before = $json->encode($normal);my $names_before = $json->encode($real->{names});
    my $mapped = FSM::Support::ISFWidthForwarding::remap_width_forwarding_plan($normal, $real->{names});
    $mapped->{instances}[0]{bindings}[0]{source_identity}{scope}{owner} = 'WRONG';
    $mapped->{instances}[0]{selection}{parameters}[0]{value} = 'WRONG';
    is($json->encode($normal), $normal_before, 'normal plan remains detached from remapped result');
    is($json->encode($real->{names}), $names_before, 'actual name maps remain detached');
    my $fresh = FSM::Support::ISFWidthForwarding::remap_width_forwarding_plan($normal, $real->{names});
    is($fresh->{instances}[0]{bindings}[0]{source_identity}{scope}{owner}, 'domain_width_forwarding', 'fresh mapped source identity is isolated');
};

subtest 'missing actual maps refuse and parent module names are not child aliases' => sub {
    unless (FSM::Support::ISFWidthForwarding->can('remap_width_forwarding_plan')) {fail('actual domain remapper is required'); return}
    my $real = $products{children}{realizations}[0];
    my $normal = build_width_forwarding_plan($real->{ir});
    for my $case (
        ['instances', $normal->{producer}{instance}],
        ['instances', $normal->{instances}[0]{instance}],
        ['modules', $normal->{instances}[0]{module}],
    ) {
        my $names = $json->decode($json->encode($real->{names}));delete $names->{$case->[0]}{$case->[1]};
        my $before = $json->encode($names);
        my $ok = eval {FSM::Support::ISFWidthForwarding::remap_width_forwarding_plan($normal, $names); 1};
        ok(!$ok, 'missing producer/target mapping refuses');like($@, qr/requires actual domain (?:instance|module) mapping/, 'refusal names actual mapping obligation');
        is($json->encode($names), $before, 'mapping refusal cannot invent names in the caller');
    }
    my $names = $json->decode($json->encode($real->{names}));
    $names->{modules}{$normal->{producer}{module}} = 'unrelated_child_alias';
    my $mapped = FSM::Support::ISFWidthForwarding::remap_width_forwarding_plan($normal, $names);
    is($mapped->{producer}{module}, $normal->{producer}{module}, 'parent definition module is outside the child-module map');
};

if (my $path = $ENV{FSMGEN_DOMAIN_FORWARDING_CAPTURE}) {
    open my $out, '>', $path or die $!;print {$out} $capture, "\n" or die $!;close $out or die $!;
}
done_testing();
