#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::ResourceActivationFixture qw(resource_activation_source resource_activation_cases);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $scheduler = FSM::Scheduler::ISF->new;
my @users = qw(low middle high);

subtest 'actual request and transformation evidence survives lowering' => sub {
    for my $case (resource_activation_cases()) {
        my $actor = FSM::Adapter::ISF->new->parse_source(resource_activation_source($case), "$case.isf");
        my $actor_before = dclone($actor);
        my $ir = $scheduler->{ir}->build_module($actor);
        my $evidence = $ir->{resource_activation};
        ok(ref($evidence) eq 'HASH', "$case retains resource activation evidence") or next;
        my @conditions = $case =~ /^literals/ ? ('0', '1', '(& a b)') : ('a', 'b', '(& a c)');
        my %expected_requests;
        for my $i (0 .. $#users) {
            $expected_requests{$users[$i]} = {
                container_name => $users[$i], source_owner => {kind => 'rule', name => $users[$i]},
                guard => ($i == 2 ? {expr => $conditions[$i]} : {port => $conditions[$i]}),
                condition => $conditions[$i],
            };
        }
        is_deeply($evidence->{requests}, \%expected_requests, "$case keeps exact original guards and typed owners");
        my @expected_pairs = map {my $resource = $_; map {[$resource->{name}, $_]} @{$resource->{users} || []}}
            @{$actor->{resources}};
        is_deeply([map {[$_->{resource}, $_->{user}]} @{$evidence->{steps}}], \@expected_pairs,
            "$case keeps every grant in actual declaration/user order");
        my %current_guard = map {$_ => dclone($expected_requests{$_}{guard})} @users;
        my %dt = map {$_->{source_owner}{name} => $_}
            grep {($_->{kind} // '') eq 'rule'} @{$ir->{dt_blocks}};
        for my $step (@{$evidence->{steps}}) {
            my $user = $step->{user};
            is($step->{container_name}, $dt{$user}{name}, 'step identifies actual DT');
            is_deeply($step->{before_guard}, $current_guard{$user}, 'input chains from original request or previous resource');
            $current_guard{$user} = $step->{after_guard};
            if ($step->{arbiter} eq 'priority') {
                my @higher = $user eq 'low' ? ($step->{resource} eq 'extra' ? ('high') : qw(high middle))
                    : $user eq 'middle' ? ('high') : ();
                is_deeply($step->{suppressors}, [map {{user => $_, condition => $expected_requests{$_}{condition}}} @higher],
                    'priority inputs retain original requests even after another resource');
                is_deeply($step->{before_guard}, $step->{after_guard}, 'highest-priority identity transformation remains explicit') unless @higher;
            } else {
                my $rr = $step->{round_robin};
                my ($index) = grep {$users[$_] eq $user} 0 .. $#users;
                is_deeply($rr->{pointer_declaration}, {name => 'isf_rr_shared_turn', width => 2,
                    storage_role => 'resource_round_robin_pointer'}, 'actual selected declaration retained');
                is($rr->{user_index}, $index, 'actual winner index retained');
                is($rr->{next_pointer}, ($index + 1) % 3, 'actual successor retained');
                my $update = $dt{$user}{assignments}[$rr->{assignment_index}];
                is_deeply([@{$update}{qw(lhs rhs op source_kind)}],
                    [$rr->{pointer_declaration}{name}, $rr->{next_pointer}, '<-', 'resource_round_robin_pointer'],
                    'retained assignment index resolves to the actual pointer update');
                ok(length($rr->{permission}), 'actual required permission is retained');
            }
        }
        is_deeply($current_guard{$_}, $dt{$_}{dte_guard}, "$_ final header equals its last retained transformation") for @users;
        is_deeply($actor, $actor_before, 'evidence capture leaves authored input unchanged');

        my $carrier = $scheduler->{fsm_emitter}->emit($ir);
        my $report = $scheduler->{json_emitter}->report_hash($ir);
        my $without = dclone($ir);
        delete $without->{resource_activation};
        is($scheduler->{fsm_emitter}->emit($without), $carrier, 'complete carrier is independent of private evidence');
        is_deeply($scheduler->{json_emitter}->report_hash($without), $report, 'complete public schedule is independent of private evidence');
        $evidence->{requests}{high}{guard}{expr} = 'corrupted request';
        $evidence->{requests}{high}{source_owner}{name} = 'corrupted owner';
        for my $step (@{$evidence->{steps}}) {
            $step->{before_guard}{port} = 'corrupted input';
            $step->{after_guard}{port} = 'corrupted output';
            $step->{round_robin}{pointer_declaration}{name} = 'corrupted pointer' if $step->{round_robin};
        }
        my $mutated_without = dclone($ir);
        delete $mutated_without->{resource_activation};
        is_deeply($mutated_without, $without, 'nested retained evidence aliases no executable IR');
        is_deeply($actor, $actor_before, 'nested retained evidence aliases no authored declarations');
    }
};

subtest 'explicit expressions and internal snapshots are detached' => sub {
    my $actor = FSM::Adapter::ISF->new->parse_source(resource_activation_source('priority'), 'priority.isf');
    my $ir = $scheduler->{ir}->build_module($actor);
    my $e = $ir->{resource_activation};
    ok(ref($e) eq 'HASH', 'evidence exists') or return;
    is_deeply([map {$_->{after_guard}} @{$e->{steps}}],
        [{expr => '(& a (! (| (& a c) b)))'}, {expr => '(& b (! (& a c)))'}, {expr => '(& a c)'}],
        'independently specified priority guard expressions match actual outputs');
    $e->{steps}[2]{before_guard}{expr} = 'changed';
    is($e->{steps}[2]{after_guard}{expr}, '(& a c)', 'unchanged transformation still owns separate snapshots');
    is($e->{requests}{high}{guard}{expr}, '(& a c)', 'request is separate from identity-step snapshots');
    my $rr_actor = FSM::Adapter::ISF->new->parse_source(resource_activation_source('round_robin'), 'round_robin.isf');
    my $rr = $scheduler->{ir}->build_module($rr_actor)->{resource_activation};
    is($rr->{steps}[0]{round_robin}{permission},
        '(| (== isf_rr_shared_turn 0) (& (== isf_rr_shared_turn 1) (! b) (! (& a c))) (& (== isf_rr_shared_turn 2) (! (& a c))))',
        'independently specified low-user permission matches producer output');
    $rr->{steps}[0]{round_robin}{pointer_declaration}{name} = 'changed';
    is($rr->{steps}[1]{round_robin}{pointer_declaration}{name}, 'isf_rr_shared_turn', 'per-user pointer snapshots do not alias');
};

subtest 'unconditional requests and selected pointer identity are actual producer values' => sub {
    my $source = resource_activation_source('priority');
    $source =~ s/\(when b\)// or die 'missing fixture guard';
    my $actor = FSM::Adapter::ISF->new->parse_source($source, 'unconditional.isf');
    my $ir = $scheduler->{ir}->build_module($actor);
    is_deeply($ir->{resource_activation}{requests}{middle}{guard}, {port => '1'},
        'absent authored guard retains the actual unconditional producer guard');
    is($ir->{resource_activation}{requests}{middle}{condition}, '1', 'unconditional expression is explicit');

    # Qualify consumption of the selected declaration without assuming its spelling.
    # This test-only producer substitution is not a public naming-policy change.
    no warnings 'redefine';
    local *FSM::Scheduler::ISF::LoweringIR::_round_robin_pointer_declaration = sub {
        return {name => 'selected_turn_counter', width => 2, storage_role => 'resource_round_robin_pointer'};
    };
    my $rr_actor = FSM::Adapter::ISF->new->parse_source(resource_activation_source('round_robin'), 'selected.isf');
    my $rr_ir = $scheduler->{ir}->build_module($rr_actor);
    my $step = $rr_ir->{resource_activation}{steps}[0];
    is($step->{round_robin}{pointer_declaration}{name}, 'selected_turn_counter', 'evidence follows actual selected declaration');
    like($step->{round_robin}{permission}, qr/\(== selected_turn_counter 0\)/, 'permission uses selected declaration');
    is($rr_ir->{counters}{selected_turn_counter}, 2, 'executable counter uses the same declaration');
    my ($dt) = grep {($_->{kind} // '') eq 'rule' && $_->{source_owner}{name} eq 'low'} @{$rr_ir->{dt_blocks}};
    is($dt->{assignments}[$step->{round_robin}{assignment_index}]{lhs}, 'selected_turn_counter',
        'retained pointer update points to the selected counter');
};

done_testing();
