#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use File::Temp qw(tempdir);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalClauseResolver;
use FSM::Scheduler::ISF::FormalIdentityPlan;
use FSM::Scheduler::ISF::PreparedFormalReservations;
use FSM::Scheduler::ISF::FormalReservationCoverage;
use FSM::Test::DiagnosticCause qw(diagnostic_cause_matches);

my $scheduler = FSM::Scheduler::ISF->new;
my $work = tempdir(CLEANUP => 1);
my $ordinal = 0;
sub allocation {
    my ($p) = @_;
    return FSM::Scheduler::ISF::FormalIdentityPlan->build($p->{actor},
        generated_children => $p->{generated_children},
        reserved_names => FSM::Scheduler::ISF::PreparedFormalReservations->collect($p)->{reserved_names});
}
sub verify {FSM::Scheduler::ISF::FormalReservationCoverage->verify(@_)}
sub qualify {
    my ($source, $label, $path) = @_;
    my $actor = ref($source) eq 'HASH' ? dclone($source)
        : FSM::Adapter::ISF->new->parse_source($source, $path // 'coverage.isf');
    my $p = $scheduler->{ir}->prepare_formal_source($actor);
    my $plan = allocation($p);
    my $physical = dclone($p->{actor});
    for my $tx (@{$physical->{transactions}}) {
        next if $p->{pruned_transactions}{$tx->{name}};
        $tx = FSM::Scheduler::ISF::FormalClauseResolver->transaction($tx,
            plan => $plan, %{$p->{transactions}{$tx->{name}}})->{transaction};
    }
    for my $rule (@{$physical->{rules}}) {
        $rule = FSM::Scheduler::ISF::FormalClauseResolver->rule($rule,
            plan => $plan, %{$p->{actor_context}})->{rule};
    }
    my %modules;
    my $build = \&FSM::Scheduler::ISF::LoweringIR::build_module;
    my $files;
    {
        no warnings 'redefine';
        local *FSM::Scheduler::ISF::LoweringIR::build_module = sub {
            my $ir = $build->(@_);
            $modules{$ir->{actor_name}} = dclone($ir);
            return $ir;
        };
        $files = $scheduler->lower($physical)->{files};
    }
    my $before = dclone([$p, $plan, \%modules]);
    my $result = verify($p, $plan, \%modules);
    ok(@{$result->{verified_scopes}}, "$label verifies actual lowered scopes");
    is_deeply([$p, $plan, \%modules], $before, "$label verification is read-only");
    my $dir = "$work/" . ++$ordinal; mkdir $dir or die $!;
    for my $name (sort keys %$files) {
        open my $out, '>', "$dir/$name" or die $!; print {$out} $files->{$name}; close $out or die $!;
    }
    my $top = exists $files->{"$actor->{actor_name}_top.fsm"}
        ? "$actor->{actor_name}_top.fsm" : "$actor->{actor_name}.fsm";
    my $check = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', '--strict', '--check', '--json', "$dir/$top"], '');
    is($check->{exit_code}, 0, "$label final exported carrier strict-checks") or diag($check->{stdout}, $check->{stderr});
    return ($p, $plan, \%modules);
}

my $source = <<'ISF';
(actor coverage (clock clk) (reset rst_n)
 (interface (input start) (input data (width 4)) (output result (width 4)) (output done) (output notice))
 (storage (var value_reg (width 8)))
 (drive (isf_port_main payload) (result payload))
 (transaction main (ports (input payload (width 4)) (input value_reg (width 4)))
  (on start) (set payload data) (set value_reg payload) (drive isf_port_main payload)
  (wait value_reg) (spawn worker as job) (await_all done) (complete done))
 (transaction worker (wait 1) (complete notice)))
ISF
my ($prepared, $plan, $modules);
subtest 'actual parent and generated child declarations pass independently' => sub {
    ($prepared, $plan, $modules) = qualify($source, 'generated child and storage shadow');
    (my $upper = $source) =~ s/isf_port_main/ISF_PORT_MAIN/g;
    qualify($upper, 'case-folded helper collision');
    my $reversed = FSM::Adapter::ISF->new->parse_source($source, 'coverage.isf');
    @{$reversed->{transactions}} = reverse @{$reversed->{transactions}};
    my $other = $scheduler->{ir}->prepare_formal_source($reversed);
    is_deeply(allocation($other), $plan, 'source declaration permutation preserves allocation');
    qualify($reversed, 'permuted actual declarations');
};

sub reject {
    my ($p, $allocation, $actual, $expected, $label) = @_;
    my $before = dclone([$p, $allocation, $actual]);
    my $ok = eval {verify($p, $allocation, $actual); 1};
    my $error = $@;
    ok(!$ok, "$label refused");
    ok(diagnostic_cause_matches($error, $expected), "$label diagnosed") or diag($error);
    is_deeply([$p, $allocation, $actual], $before, "$label refusal preserves inputs");
}
subtest 'missing declarations, module sets and private ownership fail closed' => sub {
    my $private = $plan->{formals}{main}{payload}{physical_name};
    for my $case (
        [sub {$_[0]{coverage}{counters}{late_unreserved_helper} = 1},
            "Formal reservation coverage: module 'coverage' has unreserved declarations: late_unreserved_helper",
            'late register'],
        [sub {push @{$_[0]{coverage}{states}[0]{assignments}},
                {lhs => 'implicit_late_helper', rhs => '0', op => '<='}},
            "Formal reservation coverage: module 'coverage' has unreserved declarations: implicit_late_helper",
            'implicit assignment declaration'],
        [sub {delete $_[0]{coverage}},
            'Formal reservation coverage has incomplete parent/domain modules (missing: coverage; unexpected: )',
            'missing parent'],
        [sub {$_[0]{extra} = dclone($_[0]{coverage})},
            'Formal reservation coverage has incomplete parent/domain modules (missing: ; unexpected: extra)',
            'unexpected module'],
        [sub {delete $_[0]{coverage}{children}{worker}},
            "Formal reservation coverage has incomplete children of 'coverage' (missing: worker; unexpected: )",
            'missing child'],
        [sub {$_[0]{coverage}{children}{worker}{children}{nested} = {}},
            'Formal reservation coverage has an unplanned nested child scope',
            'unexpected nested child'],
        [sub {$_[0]{coverage}{children}{worker}{actor_name} = 'other'},
            "Formal reservation coverage has a missing or mismatched module 'worker'",
            'wrong child identity'],
        [sub {$_[0]{coverage}{children}{worker}{counters}{$private} = 4},
            "Formal reservation coverage: module 'worker' has unreserved declarations: $private",
            'parent private name leaked into child'],
        [sub {$_[0]{coverage}{counters}{$private} = 9},
            "Formal reservation coverage: private formal '$private' has wrong width or ownership in 'coverage'",
            'wrong formal width'],
        [sub {$_[0]{coverage}{storage_roles}{$private} = 'drive_payload'},
            "Formal reservation coverage: private formal '$private' has wrong width or ownership in 'coverage'",
            'wrong formal role'],
        [sub {push @{$_[0]{coverage}{dt_blocks}}, {name => $private, assignments => []}},
            "Formal reservation coverage: private formal '$private' has wrong width or ownership in 'coverage'",
            'formal aliases a late block'],
    ) {
        my $actual = dclone($modules); $case->[0]->($actual);
        reject($prepared, $plan, $actual, $case->[1], $case->[2]);
    }
    my $bad_plan = dclone($plan); $bad_plan->{formals}{main}{payload}{physical_name} = 'isf_port_main_payload';
    reject($prepared, $bad_plan, $modules,
        'Formal reservation coverage requires the canonical complete allocation plan', 'stale or incomplete allocation');
};

sub substitute_token {
    my ($value, $name) = @_;
    if (ref($value) eq 'HASH') {
        return {map {my $key = $_; $key =~ s/\b\Q$name\E\b/missing_reservation_placeholder/g;
            $key => substitute_token($value->{$_}, $name)} keys %$value};
    }
    return [map {substitute_token($_, $name)} @$value] if ref($value) eq 'ARRAY';
    my $copy = $value;
    $copy =~ s/\b\Q$name\E\b/missing_reservation_placeholder/g if defined($copy);
    return $copy;
}
subtest 'removing a real producer name is detected against independently lowered output' => sub {
    my ($helper) = grep {$modules->{coverage}{storage_roles}{$_} eq 'dynamic_wait_counter'}
        keys %{$modules->{coverage}{storage_roles}};
    ok(defined $helper, 'actual dynamic-wait producer selected');
    my $incomplete = substitute_token($prepared, $helper);
    my $inventory = FSM::Scheduler::ISF::PreparedFormalReservations->collect($incomplete);
    ok(!$inventory->{reserved_names}{$helper}, 'mutation really removed every reservation for the actual helper');
    my $same_plan = allocation($incomplete);
    is_deeply($same_plan, $plan, 'omission does not change the planned private names');
    reject($incomplete, $same_plan, $modules,
        "Formal reservation coverage: module 'coverage' has unreserved declarations: $helper", 'omitted real producer declaration');
};

subtest 'reusable children and rule payload source identities retain their own coverage' => sub {
    for my $fixture (qw(fifo_library_use storage_fields atl_resolved_child_pipeline
        atl_two_child_vector_data_pipeline atl_two_child_trigger_batch_pipeline)) {
        my $actor = FSM::Adapter::ISF->new->parse_file("isf/$fixture.isf");
        qualify($actor, $fixture);
    }
    qualify(<<'ISF', 'rule payload source identity');
(actor rule_coverage (clock clk) (reset rst_n)
 (interface (input fire) (input din (width 4)) (output observed (width 4)) (output done))
 (transaction main (ports (input payload (width 4)))
  (on main_start) (set observed payload) (complete done))
 (rule isf_port fire (trigger main (bind (input payload din)))))
ISF
};

subtest 'a real helper-looking formal is separated before final admission' => sub {
    my $source = <<'ISF';
(actor monitor_coverage (clock clk) (reset rst_n)
 (interface (input fire) (input ack) (output observed (width 4)))
 (transaction main (ports (input payload (width 4)))
  (on fire) (set payload 3) (assert (monitor (within ack 3))) (set observed payload)))
ISF
    my $actor = FSM::Adapter::ISF->new->parse_source($source, 'monitor_coverage.isf');
    my $p = $scheduler->{ir}->prepare_formal_source($actor);
    my ($monitor) = grep {$_->{kind} eq 'temporal_contract_monitor'} @{$p->{transaction_products}{main}{dt_blocks}};
    my ($failure) = grep {$_->{source_kind} eq 'contract_fail'} @{$monitor->{assignments}};
    ok($failure, 'actual monitor failure producer observed');
    $source =~ s/\bpayload\b/$failure->{lhs}/g;
    my ($prepared) = qualify($source, 'monitor helper formal');
    ok(@{$prepared->{deferred_formal_collisions}{main}}, 'source-only collision deferral remains distinct from executable verification');
};

done_testing();
