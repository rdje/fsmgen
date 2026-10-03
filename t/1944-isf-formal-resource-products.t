#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use File::Temp qw(tempdir);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Test::DiagnosticCause qw(diagnostic_cause_matches);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalIdentityPlan;
use FSM::Scheduler::ISF::FormalClauseResolver;
use FSM::Scheduler::ISF::FormalReservationInventory;

my $scheduler = FSM::Scheduler::ISF->new;
my $lowerer = $scheduler->{ir};
my $work = tempdir(CLEANUP => 1);
sub parse {FSM::Adapter::ISF->new->parse_source($_[0], 'resource_products.isf')}
sub source {
    my ($kind, $count) = @_;
    my $resource = $kind eq 'transaction_start' ? 'work' : 'shared_bus';
    my $members = $kind eq 'output_bundle' ? '(members valid)' : $kind eq 'storage_port' ? '(members value_reg)' : '';
    my $inputs = join ' ', map {"(input req$_)"} 0 .. $count-1;
    my $users = join ' ', map {"user$_"} 0 .. $count-1;
    my $rules = join ' ', map {
        my $action = $kind eq 'transaction_start' ? '(trigger work)'
            : '(' . ($kind eq 'storage_port' ? 'value_reg' : 'valid') . ' ' . ($_ % 2) . ')';
        "(rule user$_ req$_ $action)";
    } 0 .. $count-1;
    return <<"ISF";
(actor resource_products (clock clk) (reset rst_n)
 (interface (input fire) $inputs (output valid) (output observed (width 4)) (output work_done))
 (storage (var value_reg (width 1)))
 (transaction main (ports (input payload (width 4))) (on fire) (set observed payload))
 (transaction work (on work_start) (wait 1) (complete work_done))
 (resources (resource $resource (kind $kind) (arbiter round_robin) $members (users $users)))
 $rules)
ISF
}
sub prior_names {
    my ($p) = @_;
    return FSM::Scheduler::ISF::FormalReservationInventory->collect({map {$_ => $p->{$_}}
        qw(transaction_products parent_activation_products parent_wiring_products parent_point_products)})->{reserved_names};
}
sub project {
    my ($p) = @_;
    my $reserved = prior_names($p);
    my $more = FSM::Scheduler::ISF::FormalReservationInventory->collect({resources => $p->{resource_signal_products}})->{reserved_names};
    $reserved->{$_} = 1 for keys %$more;
    my $actor = dclone($p->{actor});
    my $plan = FSM::Scheduler::ISF::FormalIdentityPlan->build($actor,
        generated_children => $p->{generated_children}, reserved_names => $reserved);
    for my $tx (@{$actor->{transactions}}) {
        $tx = FSM::Scheduler::ISF::FormalClauseResolver->transaction($tx,
            plan => $plan, %{$p->{transactions}{$tx->{name}}})->{transaction};
    }
    return ($actor, $plan);
}
sub strict_carrier {
    my ($actor, $label) = @_;
    my $path = "$work/$label.fsm";
    open my $fh, '>', $path or die $!;
    print {$fh} $scheduler->{fsm_emitter}->emit($lowerer->build_module($actor));
    close $fh or die $!;
    my $r = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $path], '');
    is($r->{exit_code}, 0, "$label strict carrier") or diag($r->{stdout}, $r->{stderr});
}
sub rejected {
    my ($actor, $expected_cause, $label) = @_;
    my $ok = eval {$lowerer->build_module($actor); 1};
    my $error = $@;
    ok(!$ok, "$label still refused by executable arbitration");
    ok(diagnostic_cause_matches($error, $expected_cause), "$label retains canonical diagnostic")
        or diag($error);
}

subtest 'shared declaration producer agrees with actual selected resource kinds' => sub {
    for my $kind (qw(rule_slot output_bundle transaction_start storage_port)) {
        my $actor = parse(source($kind, 3));
        my $before = dclone($actor);
        my $p = $lowerer->prepare_formal_source($actor);
        is(scalar @{$p->{resource_signal_products}}, 1, "$kind has actual potential pointer");
        my $record = $p->{resource_signal_products}[0];
        is($record->{kind}, $kind, 'source resource kind retained');
        my $decl = $record->{declaration};
        my $ir = $lowerer->build_module($actor);
        is($decl->{width}, 2, 'independent pointer capacity expectation for three users');
        is_deeply($decl, {name => $decl->{name}, width => $ir->{counters}{$decl->{name}}, storage_role => $ir->{storage_roles}{$decl->{name}}}, 'actual generated declaration matches preparation');
        my @actual = sort grep {$ir->{storage_roles}{$_} eq 'resource_round_robin_pointer'} keys %{$ir->{storage_roles}};
        is_deeply(\@actual, [$decl->{name}], 'no actual pointer declaration omitted');
        ok(!prior_names($p)->{$decl->{name}}, 'actual pointer absent from earlier products');
        my @updates = grep {($_->{source_kind}//'') eq 'resource_round_robin_pointer'} map {@{$_->{assignments}}} @{$ir->{dt_blocks}};
        is_deeply([sort {$a <=> $b} map {$_->{rhs}} @updates], [0,1,2], 'actual grants advance the real declared pointer');
        is_deeply([sort keys %{{map {$_->{lhs} => 1} @updates}}], [$decl->{name}], 'all grant updates use the same actual declaration');
        my $permuted = dclone($actor);
        @{$permuted->{rules}} = reverse @{$permuted->{rules}};
        @{$permuted->{transactions}} = reverse @{$permuted->{transactions}};
        is_deeply($lowerer->prepare_formal_source($permuted)->{resource_signal_products}, $p->{resource_signal_products}, 'declaration permutations preserve resource products');
        my ($physical) = project($p);
        is_deeply($lowerer->prepare_formal_source($physical)->{resource_signal_products}, $p->{resource_signal_products}, 'formal projection preserves real resource identity');
        strict_carrier($physical, $kind);
        $decl->{name} = 'changed';
        is_deeply($p->{actor}, $before, 'declaration mutation cannot alter prepared source');
        is_deeply($actor, $before, 'original source remains detached');
    }
    for my $case ([1,1], [2,1], [5,3]) {
        my $actor = parse(source('rule_slot', $case->[0]));
        my $d = $lowerer->prepare_formal_source($actor)->{resource_signal_products}[0]{declaration};
        is($d->{width}, $case->[1], 'independent pointer width boundary');
        is($lowerer->build_module($actor)->{counters}{$d->{name}}, $case->[1], 'actual producer has same boundary width');
    }
};

subtest 'raw formal pointer aliases remain distinct from generated declarations' => sub {
    my $base = parse(source('rule_slot', 3));
    my $helper = $lowerer->prepare_formal_source($base)->{resource_signal_products}[0]{declaration}{name};
    (my $text = source('rule_slot', 3)) =~ s/\bpayload\b/$helper/g;
    my $actor = parse($text);
    my $p = $lowerer->prepare_formal_source($actor);
    my $decl = $p->{resource_signal_products}[0]{declaration};
    is($decl->{width}, 2, 'actual pointer width independent of raw formal');
    is($p->{transaction_products}{main}{counters}{$helper}, 4, 'raw formal width remains in its own product');
    rejected($p->{actor}, "ISF resource arbitration 'isf_resource_round_robin_pointer_collision' "
                . "on resource 'shared_bus': "
                . "generated round_robin pointer '$helper' collides with an existing actor symbol", 'raw formal alias');
    my ($physical, $plan) = project($p);
    my $private = $plan->{formals}{main}{$helper}{physical_name};
    isnt(lc($private), lc($helper), 'formal gets a distinct portable identity');
    my $ir = $lowerer->build_module($physical);
    is($ir->{counters}{$private}, 4, 'physical formal retains declared width');
    is($ir->{counters}{$helper}, 2, 'physical pointer retains generated width');
    strict_carrier($physical, 'formal_shadow');
};

subtest 'declaration collection does not replace resource admission' => sub {
    my $actor = parse(source('rule_slot', 3));
    my $helper = $lowerer->prepare_formal_source($actor)->{resource_signal_products}[0]{declaration}{name};
    for my $kind (qw(fixed unknown_user overlap)) {
        my $bad = dclone($actor);
        my $expected_cause;
        if ($kind eq 'fixed') {
            push @{$bad->{storage}[0]{signals}}, {name => $helper, width => 2};
            $expected_cause = "ISF resource arbitration 'isf_resource_round_robin_pointer_collision' "
                . "on resource 'shared_bus': "
                . "generated round_robin pointer '$helper' collides with an existing actor symbol";
        } elsif ($kind eq 'unknown_user') {
            $bad->{resources}[0]{users}[0] = 'missing';
            $expected_cause = "ISF resource arbitration 'isf_resource_unknown_user' "
                . "on resource 'shared_bus': "
                . "user 'missing' is not a lowered rule";
        } else {
            my $extra = dclone($bad->{resources}[0]);$extra->{name} = 'other';
            push @{$bad->{resources}}, $extra;
            $expected_cause = "ISF resource arbitration 'isf_resource_round_robin_user_overlap' "
                . "on resource 'other': "
                . "rule user 'user0' is already bound to round_robin resource 'shared_bus'";
            my $reversed = dclone($bad);@{$reversed->{resources}} = reverse @{$reversed->{resources}};
            is_deeply($lowerer->prepare_formal_source($reversed)->{resource_signal_products},
                $lowerer->prepare_formal_source($bad)->{resource_signal_products}, 'potential declarations sorted independently of resource order');
        }
        ok(@{$lowerer->prepare_formal_source($bad)->{resource_signal_products}}, "$kind still has potential declarations");
        rejected($bad, $expected_cause, $kind);
    }
    my $bad_name = dclone($actor);$bad_name->{resources}[0]{name} = 'shared-bus';
    my $bad_name_ok = eval {$lowerer->prepare_formal_source($bad_name); 1};
    my $bad_name_error = $@;
    ok(!$bad_name_ok, 'shared declaration producer rejects malformed generated name');
    ok(diagnostic_cause_matches($bad_name_error, "ISF resource arbitration 'isf_resource_round_robin_name_shape' "
                . "on resource 'shared-bus': "
                . "round_robin resource names must be HDL identifiers because FSMGen generates pointer storage from the resource name"),
        'shared declaration producer retains complete malformed-name cause') or diag($bad_name_error);
    rejected($bad_name, "ISF resource arbitration 'isf_resource_round_robin_name_shape' "
                . "on resource 'shared-bus': "
                . "round_robin resource names must be HDL identifiers because FSMGen generates pointer storage from the resource name", 'malformed name');
    for my $kind (qw(priority empty_users unsupported_kind)) {
        my $other = dclone($actor);
        $other->{resources}[0]{arbiter} = 'priority' if $kind eq 'priority';
        $other->{resources}[0]{users} = [] if $kind eq 'empty_users';
        $other->{resources}[0]{kind} = 'backlog_kind' if $kind eq 'unsupported_kind';
        is_deeply($lowerer->prepare_formal_source($other)->{resource_signal_products}, [], "$kind invents no pointer product");
        rejected($other, "ISF resource arbitration 'isf_resource_unsupported_kind' "
                . "on resource 'shared_bus': "
                . "resource kind 'backlog_kind' is not enforced yet", 'unsupported kind') if $kind eq 'unsupported_kind';
    }
};
done_testing;
