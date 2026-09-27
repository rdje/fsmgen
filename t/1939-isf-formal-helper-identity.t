#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use JSON::PP;
use File::Temp qw(tempdir);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::LoweringIR;
use FSM::Scheduler::ISF::FormalClauseResolver;
use FSM::Scheduler::ISF::FormalIdentityPlan;
use FSM::Scheduler::ISF::FormalReservationInventory;

my $lowerer = FSM::Scheduler::ISF::LoweringIR->new;
my $work = tempdir(CLEANUP => 1);
sub parse { FSM::Adapter::ISF->new->parse_source($_[0], 'helper_identity.isf') }
sub project {
    my ($actor, $extra) = @_;
    my $prepared = $lowerer->prepare_formal_source($actor);
    my $names = FSM::Scheduler::ISF::FormalReservationInventory->collect({
        transactions => $prepared->{transaction_products}, parent => $prepared->{parent_activation_products},
    })->{reserved_names};
    $names->{$_} = 1 for keys %{$extra || {}};
    my $plan = FSM::Scheduler::ISF::FormalIdentityPlan->build($actor,
        generated_children => $prepared->{generated_children}, reserved_names => $names);
    my $physical = dclone($actor);
    for my $tx (@{$physical->{transactions}}) {
        next if $prepared->{pruned_transactions}{$tx->{name}};
        $tx = FSM::Scheduler::ISF::FormalClauseResolver->transaction($tx,
            plan => $plan, %{$prepared->{transactions}{$tx->{name}}})->{transaction};
    }
    for my $rule (@{$physical->{rules}}) {
        $rule = FSM::Scheduler::ISF::FormalClauseResolver->rule($rule,
            plan => $plan, %{$prepared->{actor_context}})->{rule};
    }
    return ($physical, $plan, $prepared);
}
my $source = <<'ISF';
(actor helper_identity (clock clk) (reset rst_n)
  (interface (input fire) (input din (width 4)) (output observed (width 4)) (output done))
  (transaction main (ports (input payload (width 4)))
    (on main_start) (set observed payload) (complete done))
  (rule isf_port fire (trigger main (bind (input payload din)))))
ISF

subtest 'rule helper source identity survives distinct physical endpoints' => sub {
    for my $extra ({}, {isf_port_main_payload_formal => 1}) {
        my $actor = parse($source);
        my $before = dclone($actor);
        my ($physical, $plan, $prepared) = project($actor, $extra);
        my $name = $plan->{formals}{main}{payload}{physical_name};
        my $port = $physical->{transactions}[0]{ports}{inputs}[0];
        is_deeply($port->{_isf_formal_identity}, {
            source => ['transaction_port', 'helper_identity', 'main', 'payload'], physical_name => $name,
        }, 'typed source identity and physical name retained separately');
        is($port->{name}, $name, 'declaration uses physical name');
        my $ir = $lowerer->build_module($physical);
        my $binding = $ir->{transaction_port_bindings}[0];
        is($binding->{payload_source}, 'isf_port_main_payload', 'binding metadata uses stable source helper');
        is($binding->{port}, $name, 'binding endpoint remains physical');
        my ($rule) = grep {$_->{kind} eq 'rule'} @{$ir->{dt_blocks}};
        my ($payload) = grep {$_->{source_kind} eq 'rule_trigger_payload_source'} @{$rule->{assignments}};
        is($payload->{lhs}, 'isf_port_main_payload', 'rule producer targets reserved authored helper');
        my ($fanin) = grep {$_->{kind} eq 'rule_trigger_fanin'} @{$ir->{dt_blocks}};
        my ($copy) = grep {$_->{source_kind} eq 'rule_trigger_payload_fanin'} @{$fanin->{assignments}};
        is($copy->{lhs}, $name, 'payload fan-in writes physical formal');
        is($copy->{rhs}, 'isf_port_main_payload', 'payload fan-in reads stable source helper');
        isnt($copy->{lhs}, $copy->{rhs}, 'formal and helper cannot alias');
        my $scheduler = FSM::Scheduler::ISF->new;
        my $report = JSON::PP->new->decode($scheduler->report($physical));
        is($report->{transaction_port_bindings}[0]{payload_source}, $binding->{payload_source}, 'schedule retains stable helper provenance');
        unlike(JSON::PP->new->encode($report), qr/_isf_formal_identity/, 'private projection does not leak into public report schema');
        my $lowered = $scheduler->lower($physical);
        strict_carriers($lowered);
        is_deeply($actor, $before, 'source actor remains authored');
        is_deeply($prepared->{actor}, $before, 'prepared source remains authored');
        $port->{_isf_formal_identity}{source}[3] = 'changed';
        is($plan->{formals}{main}{payload}{identity}[3], 'payload', 'projection is detached from plan');
    }
};

subtest 'generated public formals keep source helper and handoff names' => sub {
    my $actor = parse(<<'ISF');
(actor generated_helper (clock clk) (reset rst_n)
  (interface (input fire) (input din (width 4)) (output done))
  (transaction main (on fire) (complete done))
  (transaction worker (params (N 2)) (ports (input data (width 4))) (wait 1) (complete done))
  (rule launch fire (trigger worker (params (N 3)) (bind (input data din)))))
ISF
    my ($physical) = project($actor);
    my $before = $lowerer->build_module($actor);
    my $after = $lowerer->build_module($physical);
    is_deeply($after->{transaction_port_bindings}, $before->{transaction_port_bindings}, 'generated binding metadata remains exact');
    is_deeply($after->{spawn_instances}, $before->{spawn_instances}, 'generated public handoff metadata remains exact');
    is_deeply($after->{dt_blocks}, $before->{dt_blocks}, 'generated trigger helper assignments remain exact');
    is_deeply($after->{children}{worker}{ports}, $before->{children}{worker}{ports}, 'generated child public declarations remain exact');
    strict_carriers(FSM::Scheduler::ISF->new->lower($physical));
};

subtest 'malformed and stale projection records fail before physical lowering' => sub {
    my ($physical, $plan, $prepared) = project(parse($source));
    for my $mutate (
        sub {$_[0]{_isf_formal_identity} = undef},
        sub {$_[0]{_isf_formal_identity}{extra} = 1},
        sub {$_[0]{_isf_formal_identity}{physical_name} = 'stale'},
        sub {$_[0]{_isf_formal_identity}{source} = []},
        sub {$_[0]{_isf_formal_identity}{source}[0] = 'wrong_kind'},
        sub {$_[0]{_isf_formal_identity}{source}[2] = 'other_owner'},
        sub {$_[0]{_isf_formal_identity}{source}[3] = ['nested']},
    ) {
        my $bad = dclone($physical);
        $mutate->($bad->{transactions}[0]{ports}{inputs}[0]);
        my $ok = eval {$lowerer->build_module($bad); 1};
        ok(!$ok, 'invalid projection rejected');
        like($@, qr/malformed or stale formal identity projection/, 'targeted projection diagnostic');
    }
    my $duplicate = dclone($physical);
    my $other = dclone($duplicate->{transactions}[0]{ports}{inputs}[0]);
    $other->{name} = 'other_physical';
    $other->{_isf_formal_identity}{physical_name} = 'other_physical';
    push @{$duplicate->{transactions}[0]{ports}{inputs}}, $other;
    my $duplicate_ok = eval {$lowerer->build_module($duplicate); 1};
    ok(!$duplicate_ok, 'distinct physical declarations cannot claim one source formal');
    like($@, qr/duplicate formal source identity/, 'duplicate identity diagnostic');
    my $tx = dclone($prepared->{actor}{transactions}[0]);
    $tx->{ports}{inputs}[0]{_isf_formal_identity} = $physical->{transactions}[0]{ports}{inputs}[0]{_isf_formal_identity};
    my $ok = eval {FSM::Scheduler::ISF::FormalClauseResolver->transaction($tx,
        plan => $plan, %{$prepared->{transactions}{main}}); 1};
    ok(!$ok, 'preexisting projection cannot be silently rewritten');
    like($@, qr/already physically projected/, 'repeat projection diagnostic');
};
done_testing;

sub strict_carriers {
    my ($lowered) = @_;
    for my $name (sort keys %{$lowered->{files}}) {
        next unless $name =~ /\.fsm$/;
        open my $fh, '>', "$work/$name" or die $!;
        print {$fh} $lowered->{files}{$name};
        close $fh or die $!;
    }
    for my $name (sort keys %{$lowered->{files}}) {
        next unless $name =~ /\.fsm$/;
        my $result = FSM::Test::SourceQueryRunner::_capture(
            [$^X, 'bin/fsmgen', '--strict', '--check', '--json', "$work/$name"], '');
        is($result->{exit_code}, 0, "$name strict carrier replay") or diag($result->{stdout}, $result->{stderr});
    }
}
