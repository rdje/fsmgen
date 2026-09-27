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
use FSM::Scheduler::ISF::FormalIdentityPlan;
use FSM::Scheduler::ISF::FormalClauseResolver;
use FSM::Scheduler::ISF::FormalReservationInventory;

my $s = FSM::Scheduler::ISF->new;
my $l = $s->{ir};
my $work = tempdir(CLEANUP => 1);
sub parse {FSM::Adapter::ISF->new->parse_source($_[0], 'arbitration_namespace.isf')}
sub inventory {FSM::Scheduler::ISF::FormalReservationInventory->collect($_[0])->{reserved_names}}
sub declarations {
    my ($ir) = @_;
    return {map {$_ => 1} grep {defined $_} (
        keys %{$ir->{signal_widths} || {}}, keys %{$ir->{counters} || {}},
        (map {$_->{name}} @{$ir->{ports} || []}, @{$ir->{constants} || []},
            @{$ir->{params} || []}, @{$ir->{states} || []}, @{$ir->{dt_blocks} || []}),
        $ir->{clock}, (($ir->{reset} || {})->{name} // ()),
    )};
}
sub observe {
    my ($actor) = @_;
    my @observed;
    # Observe production calls, not a fabricated parent assembled from raw
    # preparation products. Each wrapper delegates exactly once to its real CV.
    my @stages = qw(_apply_rule_user_resource_arbitration _apply_rule_priority_resolution
        _apply_rule_transaction_priority_resolution _finalize_ir);
    my %original;
    { no strict 'refs'; $original{$_} = \&{"FSM::Scheduler::ISF::LoweringIR::$_"} for @stages; }
    my $wrap = sub {
        my ($stage) = @_;
        return sub {
            my ($ir) = @_;
            my $before = declarations($ir);
            my $result = $original{$stage}->(@_);
            push @observed, {stage => $stage, actor => $ir->{actor_name}, before => $before,
                after => declarations($ir), result => $stage eq '_finalize_ir' ? undef : dclone($result)};
            return $result;
        };
    };
    no warnings 'redefine';
    local *FSM::Scheduler::ISF::LoweringIR::_apply_rule_user_resource_arbitration = $wrap->($stages[0]);
    local *FSM::Scheduler::ISF::LoweringIR::_apply_rule_priority_resolution = $wrap->($stages[1]);
    local *FSM::Scheduler::ISF::LoweringIR::_apply_rule_transaction_priority_resolution = $wrap->($stages[2]);
    local *FSM::Scheduler::ISF::LoweringIR::_finalize_ir = $wrap->($stages[3]);
    my $ir = $l->build_module($actor);
    return ($ir, \@observed);
}
sub prepared_inventory {
    my ($p) = @_;
    return inventory({map {$_ => $p->{$_}} qw(actor transaction_products parent_activation_products
        parent_wiring_products parent_point_products resource_signal_products generated_child_products
        parent_completion_products reusable_child_products)});
}
sub project {
    my ($p) = @_;
    my $a = dclone($p->{actor});
    my $plan = FSM::Scheduler::ISF::FormalIdentityPlan->build($a,
        generated_children => $p->{generated_children}, reserved_names => prepared_inventory($p));
    for my $tx (@{$a->{transactions}}) {
        next if $p->{pruned_transactions}{$tx->{name}};
        $tx = FSM::Scheduler::ISF::FormalClauseResolver->transaction($tx,
            plan => $plan, %{$p->{transactions}{$tx->{name}}})->{transaction};
    }
    return $a;
}
sub strict_parent {
    my ($ir, $label) = @_;
    my $path = "$work/$label.fsm";
    open my $fh, '>', $path or die $!;
    print {$fh} $s->{fsm_emitter}->emit($ir);close $fh or die $!;
    my $r = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $path], '');
    is($r->{exit_code}, 0, "$label strict carrier") or diag($r->{stdout}, $r->{stderr});
}
sub qualify {
    my ($actor, $label, $expect_grants, $expect_priority) = @_;
    my $p = $l->prepare_formal_source($actor);
    my $reserved = prepared_inventory($p);
    my ($ir, $stages) = observe($actor);
    my %expected = map {$_->{declaration}{name} => 1} @{$p->{resource_signal_products}};
    my @parent = grep {$_->{actor} eq $actor->{actor_name}} @$stages;
    is_deeply([map {$_->{stage}} @parent], [qw(_apply_rule_user_resource_arbitration
        _apply_rule_priority_resolution _apply_rule_transaction_priority_resolution _finalize_ir)],
        "$label observes actual stage order without skipping admission");
    for my $stage (@parent) {
        my @added = sort grep {!$stage->{before}{$_}} keys %{$stage->{after}};
        my @removed = sort grep {!$stage->{after}{$_}} keys %{$stage->{before}};
        is_deeply(\@added, $stage->{stage} eq '_apply_rule_user_resource_arbitration' ? [sort keys %expected] : [],
            "$label $stage->{stage} introduces only declared resource pointers");
        is_deeply(\@removed, [], "$label $stage->{stage} removes no existing declaration");
        my @missing = sort grep {!$reserved->{$_}} keys %{$stage->{after}};
        is_deeply(\@missing, [], "$label actual stage declarations covered by source/preparation inventory");
    }
    is(scalar @{$ir->{resource_arbitration}{grants}}, $expect_grants, "$label actual grants are nonvacuous when requested");
    is(scalar @{$ir->{priority_resolution}{resolutions}}, $expect_priority, "$label real assignment-priority resolutions exercised");
    for my $decl (@{$p->{resource_signal_products}}) {
        is($ir->{counters}{$decl->{declaration}{name}}, $decl->{declaration}{width}, 'actual introduced pointer width matches shared declaration producer');
    }
    my $physical = project($p);
    my ($physical_ir, $physical_stages) = observe($physical);
    my $physical_names = prepared_inventory($l->prepare_formal_source($physical));
    for my $stage (@$physical_stages) {
        next unless $stage->{actor} eq $physical->{actor_name};
        is_deeply([sort grep {!$physical_names->{$_}} keys %{$stage->{after}}], [], "$label physical stage has no uncovered declaration");
    }
    is_deeply($physical_ir->{priority_resolution}, $ir->{priority_resolution}, "$label source owner priority metadata survives formal projection");
    strict_parent($physical_ir, $label);
    return $ir;
}
sub resource_source {
    my ($kind, $arbiter) = @_;
    my $name = $kind eq 'transaction_start' ? 'work' : 'lane';
    my $members = $kind eq 'storage_port' ? '(members cell)' : $kind eq 'output_bundle' ? '(members flag)' : '';
    my $first = $kind eq 'transaction_start' ? '(trigger work)' : $kind eq 'storage_port' ? '(cell 1)' : '(flag 1)';
    my $second = $kind eq 'transaction_start' ? '(trigger work)' : $kind eq 'storage_port' ? '(cell 0)' : '(flag 0)';
    return <<"ISF";
(actor namespace_resource (clock clk) (reset rst_n)
 (interface (input fire) (input a) (input b) (output flag) (output done))
 (storage (var cell (width 1)))
 (transaction main (ports (input payload (width 4))) (on fire) (wait payload) (complete done))
 (transaction work (on work_start) (wait 1) (complete done))
 (priority high over low)
 (resources (resource $name (kind $kind) (arbiter $arbiter) $members (users high low)))
 (rule high a $first) (rule low b $second))
ISF
}
subtest 'resource declaration coverage is distinct from executable grant admission' => sub {
    for my $kind (qw(rule_slot output_bundle storage_port transaction_start)) {
        for my $arbiter (qw(priority round_robin)) {
            # Data conflicts retain a target-local priority record as well as
            # whole-rule resource grants. Compatible trigger pulses do not.
            qualify(parse(resource_source($kind, $arbiter)), "${kind}_$arbiter", 2,
                $kind eq 'transaction_start' ? 0 : 1);
        }
    }
};
subtest 'rule and transaction priorities reuse existing signal and state names' => sub {
    my $rule = <<'ISF';
(actor namespace_priority (clock clk) (reset rst_n)
 (interface (input a) (input b) (output out))
 (priority high over low)
 (rule high a (out 1)) (rule low b (out 0)))
ISF
    qualify(parse($rule), 'rule_priority', 0, 1);
    for my $file (qw(isf_rule_transaction_direct_priority_control
        isf_rule_transaction_named_drive_priority_probe isf_rule_transaction_named_drive_transaction_priority)) {
        my $a = FSM::Adapter::ISF->new->parse_file("t/data/$file.isf");
        qualify($a, $file, 0, 1);
    }
    my $direct = FSM::Adapter::ISF->new->parse_file('t/data/isf_rule_transaction_direct_priority_control.isf');
    $direct->{priorities} = [['main', 'over', 'force_out']];
    my $ir = qualify($direct, 'transaction_over_rule', 0, 1);
    my ($rule_dt) = grep {$_->{name} eq 'force_out'} @{$ir->{dt_blocks}};
    like($rule_dt->{assignments}[0]{guard}{expr}, qr/\(state_active main_update_1\)/,
        'reverse priority uses an existing state identity rather than allocating a new state-active register');
};
subtest 'potential declarations never bypass resource or conflict refusal' => sub {
    my $a = parse(resource_source('rule_slot', 'round_robin'));
    my $p = $l->prepare_formal_source($a);
    my $pointer = $p->{resource_signal_products}[0]{declaration}{name};
    for my $case (qw(collision unknown_user)) {
        my $bad = dclone($a);
        if ($case eq 'collision') {push @{$bad->{storage}[0]{signals}}, {name => $pointer, width => 1}}
        else {$bad->{resources}[0]{users}[0] = 'absent'}
        ok(@{$l->prepare_formal_source($bad)->{resource_signal_products}}, 'source collection retains only potential declaration');
        eval {observe($bad)};
        like($@, $case eq 'collision' ? qr/isf_resource_round_robin_pointer_collision/ : qr/isf_resource_unknown_user/,
            "$case still fails in actual resource stage");
    }
    my $conflict = parse('(actor conflict (interface (input a) (input b) (output out)) (rule high a (out 1)) (rule low b (out 0)))');
    eval {observe($conflict)};
    like($@, qr/isf_conflicting_rule_writes/, 'finalization still refuses incomparable data writers');
};
done_testing;
