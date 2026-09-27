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
my $lowerer = $s->{ir};
my $work = tempdir(CLEANUP => 1);
my $base = <<'ISF';
(actor completion_products (clock clk) (reset rst_n)
 (interface (input fire) (input cycles (width 4)) (output done) (output observed (width 4)))
 (transaction worker (wait 2) (complete done))
 (transaction main (ports (input payload (width 4))) (on fire) (set payload cycles)
  (spawn worker as first) (spawn worker as second)
  (await_any done) (await_all done) (wait payload) (set observed payload) (complete done)))
ISF
sub parse {FSM::Adapter::ISF->new->parse_source($_[0], 'completion_products.isf')}
sub inventory {FSM::Scheduler::ISF::FormalReservationInventory->collect($_[0])->{reserved_names}}
sub product_set {
    my ($p) = @_;
    return {map {$_ => $p->{$_}} qw(transaction_products parent_activation_products
        parent_wiring_products parent_point_products resource_signal_products generated_child_products)};
}
sub project {
    my ($p) = @_;
    my $products = product_set($p);
    $products->{completion} = $p->{parent_completion_products};
    my $a = dclone($p->{actor});
    my $reserved = inventory($products);
    my $plan = FSM::Scheduler::ISF::FormalIdentityPlan->build($a,
        generated_children => $p->{generated_children}, reserved_names => $reserved);
    for my $tx (@{$a->{transactions}}) {
        next if $p->{pruned_transactions}{$tx->{name}};
        $tx = FSM::Scheduler::ISF::FormalClauseResolver->transaction($tx,
            plan => $plan, %{$p->{transactions}{$tx->{name}}})->{transaction};
    }
    return ($a, $plan, $reserved);
}
sub strict_parent {
    my ($ir, $label) = @_;
    my $path = "$work/$label.fsm";
    open my $fh, '>', $path or die $!;
    print {$fh} $s->{fsm_emitter}->emit($ir);
    close $fh or die $!;
    my $r = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $path], '');
    is($r->{exit_code}, 0, "$label strict parent carrier") or diag($r->{stdout}, $r->{stderr});
}
sub compare_actual {
    my ($actor, $p, $label) = @_;
    my $ir = $lowerer->build_module($actor);
    my $c = $p->{parent_completion_products};
    is_deeply({map {$_ => $c->{$_}} qw(input_names instances)},
        $ir->{child_completion_products}, "$label actual allocation inputs and ownership agree");
    my @actual = sort grep {$ir->{storage_roles}{$_} =~ /^child_completion_(?:seen|view)$/}
        keys %{$ir->{storage_roles}};
    is_deeply([sort keys %{$c->{signal_widths}}], \@actual, "$label all actual helper declarations retained");
    for my $field (qw(counters signal_widths storage_roles reset_values)) {
        is_deeply($c->{$field}, {map {$_ => $ir->{$field}{$_}} grep {exists $ir->{$field}{$_}} @actual},
            "$label $field uses actual generated values only");
    }
    my @dts = grep {($_->{kind}//'') eq 'child_completion'} @{$ir->{dt_blocks}};
    # Finalization adds assignment provenance; the producer payload is otherwise exact.
    for my $dt (@dts) {
        my ($retained) = grep {$_->{name} eq $dt->{name}} @{$c->{dt_blocks}};
        for my $i (0 .. $#{$retained->{assignments}}) {
            my $a = $retained->{assignments}[$i];
            is_deeply($a, {map {$_ => $dt->{assignments}[$i]{$_}} keys %$a}, "$label real completion assignment retained");
        }
    }
    my @joins = grep {($_->{kind}//'') =~ /^sync_/} @{$c->{states}};
    for my $join (@joins) {
        my ($actual) = grep {$_->{name} eq $join->{name}} @{$ir->{states}};
        for my $field (qw(done_ports completion_ports transitions)) {
            is_deeply($join->{$field}, $actual->{$field}, "$label rewritten join $field agrees");
        }
        is_deeply($join->{done_ports}, [qw(first_done second_done)], 'raw done ownership is unchanged');
        is_deeply($join->{completion_ports}, [map {$c->{instances}{$_}{ready_signal}} qw(first second)], 'join uses typed instance views');
        for my $guard (map {$_->{guard}} @{$join->{assignments}}) {
            next unless ref($guard) eq 'HASH';
            my $tokens = inventory($guard);
            ok(!$tokens->{first_done} && !$tokens->{second_done}, 'dynamic counter-load guard no longer reads transient done pulses');
        }
    }
    for my $name (qw(first second)) {
        my $record = $c->{instances}{$name};
        is_deeply($record->{identity}, ['generated_child_instance', 'completion_products', $name], 'source instance identity explicit');
        is($record->{start_signal}, "${name}_start", 'actual rearm handoff retained');
        is($record->{done_signal}, "${name}_done", 'actual capture handoff retained');
    }
    return $ir;
}

subtest 'real completion products and rewritten dynamic joins' => sub {
    my $a = parse($base);
    my $before = dclone($a);
    my $p = $lowerer->prepare_formal_source($a);
    my $old = inventory(product_set($p));
    my $c = $p->{parent_completion_products};
    for my $name (keys %{$c->{signal_widths}}) {
        ok(!$old->{$name}, "$name absent from previous products");
        ok(inventory($c)->{$name}, "$name now retained");
    }
    compare_actual($a, $p, 'source');
    my ($physical) = project($p);
    my $q = $lowerer->prepare_formal_source($physical);
    my $ir = compare_actual($physical, $q, 'physical');
    is_deeply($q->{parent_completion_products}{instances}, $c->{instances}, 'ordinary formal projection keeps allocation and source ownership');
    strict_parent($ir, 'dynamic');
    my $prior = dclone($p->{parent_point_products});
    $c->{states}[0]{name} = 'changed';
    $c->{instances}{first}{identity}[1] = 'changed';
    $c->{counters}{changed} = 9;
    ok(!exists $c->{signal_widths}{changed}, 'returned width maps are independent snapshots');
    is_deeply($p->{parent_point_products}, $prior, 'completion edits cannot mutate earlier states');
    is_deeply($p->{actor}, $before, 'prepared source detached');
    is_deeply($a, $before, 'authored source detached');
};

subtest 'exact and portable helper-looking names retain typed ownership' => sub {
    for my $formal ('isf_completion_first_seen', 'ISF_COMPLETION_SECOND_READY') {
        (my $text = $base) =~ s/\bpayload\b/$formal/g;
        my $a = parse($text);
        my $p = $lowerer->prepare_formal_source($a);
        compare_actual($a, $p, $formal);
        my ($physical, $plan, $reserved) = project($p);
        my $q = $lowerer->prepare_formal_source($physical);
        my $ir = compare_actual($physical, $q, 'projected_' . $formal);
        my $private = $plan->{formals}{main}{$formal}{physical_name};
        is($ir->{counters}{$private}, 4, 'physical formal width remains separate');
        for my $name (keys %{$q->{parent_completion_products}{signal_widths}}) {
            isnt(lc($name), lc($private), 'actual helper does not alias formal');
            ok(scalar(grep {lc($_) eq lc($name)} keys %$reserved),
                'actual post-projection helper reserved under portable comparison');
        }
        for my $instance (qw(first second)) {
            is_deeply($q->{parent_completion_products}{instances}{$instance}{identity},
                $p->{parent_completion_products}{instances}{$instance}{identity}, 'ownership survives allocation changes');
        }
        strict_parent($ir, $formal);
    }
    for my $fixed ('isf_completion_first_seen', 'ISF_COMPLETION_SECOND_READY') {
        (my $text = $base) =~ s/\(input fire\)/(input fire) (input $fixed)/;
        my $a = parse($text);
        my $p = $lowerer->prepare_formal_source($a);
        compare_actual($a, $p, $fixed);
        ok($p->{parent_completion_products}{input_names}{$fixed}, 'fixed collision retained in exact allocator namespace');
        ok(!scalar(grep {lc($_) eq lc($fixed)} keys %{$p->{parent_completion_products}{signal_widths}}),
            'actual helper avoids portable fixed collision');
    }
};

subtest 'declaration namespace includes static storage point and arbitration products' => sub {
    my $text = $base;
    $text =~ s/\(transaction worker/(constants (LIMIT 3)) (params (COUNT 4))
        (storage (var isf_completion_first_seen (width 8)))
        (resources (resource lane (kind rule_slot) (arbiter round_robin) (users r0 r1)))
        (rule r0 fire (flag 1)) (rule r1 fire (flag 0))
        (transaction worker/;
    $text =~ s/\(output done\)/(output done) (output flag)/;
    $text =~ s/\(on fire\)/(on fire as launch) (point armed) (assert (=> (at armed) fire))/;
    my $actor = parse($text);
    my $p = $lowerer->prepare_formal_source($actor);
    compare_actual($actor, $p, 'namespace');
    my $names = $p->{parent_completion_products}{input_names};
    for my $name ('LIMIT', 'COUNT', 'clk', 'rst_n', 'isf_completion_first_seen',
        keys %{$p->{parent_point_products}{counters}},
        map {$_->{declaration}{name}} @{$p->{resource_signal_products}}) {
        ok($names->{$name}, "$name is an actual allocator input");
    }
    my $reversed = dclone($actor);
    @{$reversed->{transactions}} = reverse @{$reversed->{transactions}};
    @{$reversed->{rules}} = reverse @{$reversed->{rules}};
    is_deeply($lowerer->prepare_formal_source($reversed)->{parent_completion_products}{instances},
        $p->{parent_completion_products}{instances}, 'independent declaration order preserves helper ownership');
    my ($physical) = project($p);
    strict_parent(compare_actual($physical, $lowerer->prepare_formal_source($physical), 'namespace_physical'),
        'namespace_physical');
};

subtest 'raw conflicting widths and absent joins never fabricate declarations' => sub {
    (my $text = $base) =~ s/\(transaction worker/(storage (var payload (width 8))) (transaction worker/;
    my $a = parse($text);
    my $p = $lowerer->prepare_formal_source($a);
    is($p->{transaction_products}{main}{counters}{payload}, 4, 'raw formal keeps own width');
    ok($p->{parent_completion_products}{input_names}{payload}, 'conflicting raw declaration represented only by membership');
    ok(!exists $p->{parent_completion_products}{counters}{payload}, 'membership not returned as a fabricated storage width');
    eval {$lowerer->build_module($a)};
    like($@, qr/(?:width|Width).*payload|payload.*(?:width|Width)/s, 'real parent still refuses conflicting raw declarations');
    my ($physical) = project($p);
    my $ir = compare_actual($physical, $lowerer->prepare_formal_source($physical), 'conflict_projected');
    strict_parent($ir, 'conflict_projected');
    for my $kind (qw(no_join no_spawn pruned)) {
        my $text = $base;
        $text =~ s/\(await_any done\) \(await_all done\)//;
        $text =~ s/\(spawn worker as first\) \(spawn worker as second\)// if $kind eq 'no_spawn';
        $text =~ s/\(spawn worker as first\) \(spawn worker as second\)/(repeat 0 (spawn worker as first) (spawn worker as second) (await_all done))/ if $kind eq 'pruned';
        my $c = $lowerer->prepare_formal_source(parse($text))->{parent_completion_products};
        is_deeply($c->{instances}, {}, "$kind no fabricated owner");
        is_deeply($c->{counters}, {}, "$kind no fabricated storage");
        is_deeply($c->{dt_blocks}, [], "$kind no fabricated retention behavior");
    }
};
done_testing;
