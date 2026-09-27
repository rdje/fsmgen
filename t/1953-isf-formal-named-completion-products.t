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
my $base = <<'ISF';
(actor named_products (clock clk) (reset rst_n)
 (interface (input fire) (input din (width 4)) (output notice) (output done) (output seen (width 4)))
 (storage (var value_reg (width 4) (reset 3)))
 (transaction worker (ports (output data (width 4)))
  (set data value_reg) (set value_reg 7) (complete notice))
 (transaction main (ports (input payload (width 4))) (on fire) (set payload din)
  (spawn worker as job (bind (output data seen))) (await_all done) (complete notice)))
ISF
sub parse {FSM::Adapter::ISF->new->parse_source($_[0], 'named_products.isf')}
sub inventory {FSM::Scheduler::ISF::FormalReservationInventory->collect($_[0])->{reserved_names}}
sub project {
    my ($p) = @_;
    my $a = dclone($p->{actor});
    my $reserved = inventory({map {$_ => $p->{$_}} grep {/products$/} keys %$p});
    my $plan = FSM::Scheduler::ISF::FormalIdentityPlan->build($a,
        generated_children => $p->{generated_children}, reserved_names => $reserved);
    for my $tx (@{$a->{transactions}}) {
        next if $p->{pruned_transactions}{$tx->{name}};
        $tx = FSM::Scheduler::ISF::FormalClauseResolver->transaction($tx,
            plan => $plan, %{$p->{transactions}{$tx->{name}}})->{transaction};
    }
    return ($a, $reserved);
}
sub observe_plan {
    my ($a) = @_;
    my $original = \&FSM::Scheduler::ISF::ChildCompletionOutputs::plan_child_completion_outputs;
    my @plans;
    no warnings 'redefine';
    local *FSM::Scheduler::ISF::ChildCompletionOutputs::plan_child_completion_outputs = sub {
        my $before = dclone([@_]); my $plan = $original->(@_);
        is_deeply([@_], $before, 'actual planner does not mutate its caller inputs');
        push @plans, dclone($plan); return $plan;
    };
    my $ir = $l->build_module($a);
    is(scalar @plans, 1, 'actual connection calls shared planner once');
    return ($ir, $plans[0]);
}
sub compare_actual {
    my ($a, $p) = @_;
    my ($ir, $actual) = observe_plan($a);
    my $r = $p->{parent_named_completion_products};
    is_deeply($r, $actual, 'complete actual allocation inputs and named-completion products agree');
    my %ports = map {$_->{name} => $_} @{$ir->{ports}};
    for my $port (@{$r->{ports}}) {is_deeply($port, $ports{$port->{name}}, 'actual parent input retained')}
    for my $field (qw(counters signal_widths signal_type_refs storage_roles reset_values)) {
        for my $name (keys %{$r->{$field}}) {
            is_deeply($ir->{$field}{$name}, $r->{$field}{$name}, "actual $field contract retained");
        }
    }
    my @dts = grep {($_->{kind}//'') eq 'child_completion_output'} @{$ir->{dt_blocks}};
    is_deeply(\@dts, $r->{dt_blocks}, 'actual OR views retained without another pulse stage');
    for my $spawn (@{$ir->{spawn_instances}}) {
        my $record = $r->{instances}{$spawn->{instance}} || next;
        is_deeply($record->{links}, $spawn->{actor_completion_outputs}, 'actual per-instance completion wiring retained');
        is($record->{child}, $spawn->{child}, 'child module owner retained');
    }
    my %internal = map {$_ => 1} @{$ir->{explicit_internal_signals}};
    ok($internal{$_}, 'local pulse remains explicit internal state') for @{$r->{explicit_internal_signals}};
    for my $name (keys %{$r->{outputs}}) {
        my $record = $r->{outputs}{$name};
        is_deeply($record->{identity}, ['actor_completion_output', $a->{actor_name}, $name], 'typed public output identity retained');
        next unless $record->{local_pulse};
        my @local = grep {($_->{source_kind}//'') eq 'complete_pulse' && $_->{lhs} eq $record->{local_pulse}}
            map {@{$_->{assignments}||[]}} @{$ir->{states}}, @{$ir->{dt_blocks}};
        ok(@local, 'actual local completion assignments target the allocated pulse');
        is($_->{op}, '<1', 'local pulse keeps original delayed operator') for @local;
    }
    return $ir;
}
sub strict_parent {
    my ($ir, $label) = @_;
    my $path = "$work/$label.fsm";
    open my $fh, '>', $path or die $!; print {$fh} $s->{fsm_emitter}->emit($ir); close $fh or die $!;
    my $r = FSM::Test::SourceQueryRunner::_capture([$^X,'bin/fsmgen','--strict','--check','--json',$path], '');
    is($r->{exit_code}, 0, "$label strict parent") or diag($r->{stdout},$r->{stderr});
}
subtest 'actual named completion products preserve storage-stage order and projection' => sub {
    for my $kind (qw(shared child_only typed reset multiple local_shadow canonical)) {
        my $text = $base;
        $text =~ s/\(await_all done\) \(complete notice\)/(await_all done) (complete done)/ if $kind eq 'child_only';
        if ($kind eq 'typed') {
            $text =~ s/\(interface/(types (type Pulse bit)) (interface/;
            $text =~ s/\(output notice\)/(output notice (type Pulse))/;
        }
        $text =~ s/\(output notice\)/(output notice (width 1) (reset 1))/ if $kind eq 'reset';
        if ($kind eq 'multiple') {
            $text =~ s/\(set value_reg 7\)//;
            $text =~ s/\(output done\)/(output done) (output extra (width 4))/;
            $text =~ s/\(await_all done\)/(spawn worker as other (bind (output data extra))) (await_all done)/;
        }
        if ($kind eq 'local_shadow') {
            $text =~ s/\(output done\)/(output done) (output mirrored)/;
            $text =~ s/\(ports \(output data/(ports (output notice) (output data/;
            $text =~ s/\(bind \(output data seen\)\)/(bind (output data seen) (output notice mirrored))/;
        }
        $text =~ s/\(set value_reg 7\) \(complete notice\)/(set value_reg 7) (complete done)/ if $kind eq 'canonical';
        my $a = parse($text); my $before = dclone($a); my $p = $l->prepare_formal_source($a);
        my $r = $p->{parent_named_completion_products};
        compare_actual($a, $p);
        for my $field (qw(parent_storage_write_products parent_storage_read_products)) {
            for my $port (@{$p->{$field}{ports}}) {ok($r->{input_names}{$port->{name}}, 'named completion reserves preceding storage port')}
        }
        if ($kind eq 'canonical' || $kind eq 'local_shadow') {
            is_deeply($r->{ports}, [], 'no automatic named completion for canonical or explicitly local target');
            is_deeply($r->{outputs}, {}, 'no invented actor output ownership');
        } else {
            ok(@{$r->{ports}}, 'actual named child input retained');
            is(exists($r->{outputs}{notice}{local_pulse}) ? 1 : 0, $kind eq 'child_only' ? 0 : 1, 'local pulse exists only for actual parent completion');
        }
        my ($physical, $reserved) = project($p); my $q = $l->prepare_formal_source($physical);
        strict_parent(compare_actual($physical, $q), $kind);
        for my $name (keys %{$q->{parent_named_completion_products}{signal_widths}}, map {$_->{name}} @{$q->{parent_named_completion_products}{dt_blocks}}) {
            ok(scalar(grep {lc($_) eq lc($name)} keys %$reserved), 'source inventory covers physical named completion declaration');
        }
        my $children = dclone($p->{generated_child_products}); my $reads = dclone($p->{parent_storage_read_products});
        $r->{input_names}{mutated} = 1;
        $r->{outputs}{mutated} = {sources => ['changed']};
        is_deeply($p->{generated_child_products}, $children, 'child products detached');
        is_deeply($p->{parent_storage_read_products}, $reads, 'preceding read products detached');
        is_deeply($p->{actor}, $before, 'prepared source unchanged');
        is_deeply($a, $before, 'caller source unchanged');
    }
};
subtest 'portable helper collisions preserve complete real plans' => sub {
    for my $name (qw(isf_child_completion_job_notice ISF_LOCAL_COMPLETION_NOTICE isf_completion_output_notice)) {
        for my $kind (qw(formal fixed rule)) {
            my $text = $base;
            $text =~ s/\bpayload\b/$name/g if $kind eq 'formal';
            $text =~ s/\(input fire\)/(input fire) (input $name)/ if $kind eq 'fixed';
            if ($kind eq 'rule') {
                $text =~ s/\(output done\)/(output done) (output flag)/;
                $text =~ s/\(transaction worker/(rule $name fire (flag 1)) (transaction worker/;
            }
            my $a = parse($text); my $p = $l->prepare_formal_source($a); compare_actual($a,$p);
            my $r = $p->{parent_named_completion_products};
            ok(!scalar(grep {lc($_) eq lc($name)} (keys %{$r->{signal_widths}},map {$_->{name}} @{$r->{dt_blocks}})), 'generated helpers avoid portable authored collision');
            my ($physical,$reserved) = project($p); my $q = $l->prepare_formal_source($physical);
            strict_parent(compare_actual($physical,$q), "${kind}_$name");
            for my $decl (keys %{$q->{parent_named_completion_products}{signal_widths}},map {$_->{name}} @{$q->{parent_named_completion_products}{dt_blocks}}) {
                ok(scalar(grep {lc($_) eq lc($decl)} keys %$reserved), 'post-projection declarations covered');
            }
        }
    }
};
subtest 'potential completion plans preserve executable mixed-writer admission' => sub {
    (my $text = $base) =~ s/\(set payload din\)/(set payload din) (set notice 1)/;
    my $a = parse($text); my $p = $l->prepare_formal_source($a);
    ok(@{$p->{parent_named_completion_products}{ports}}, 'potential plan exists before parent writer admission');
    eval {$l->build_module($a)};
    like($@, qr/mixes generated child completion with a non-completion writer/, 'actual connection retains canonical refusal');
};
done_testing;
