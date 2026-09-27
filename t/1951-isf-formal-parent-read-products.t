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
(actor parent_read_products (clock clk) (reset rst_n)
 (interface (input fire) (input din (width 4)) (output done) (output observed (width 4)))
 (storage (var value_reg (width 4) (reset 3)))
 (transaction worker (ports (output data (width 4))) (set data value_reg) (complete done))
 (transaction main (ports (input payload (width 4))) (on fire) (set payload din)
  (spawn worker as job (bind (output data observed))) (await_all done) (complete done)))
ISF
sub parse {FSM::Adapter::ISF->new->parse_source($_[0], 'parent_read_products.isf')}
sub inventory {FSM::Scheduler::ISF::FormalReservationInventory->collect($_[0])->{reserved_names}}
sub products {my ($p) = @_; return {map {$_ => $p->{$_}} grep {/products$/} keys %$p}}
sub project {
    my ($p) = @_;
    my $a = dclone($p->{actor});
    my $reserved = inventory(products($p));
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
    my $original = \&FSM::Scheduler::ISF::ChildStorageOwnership::plan_child_storage_read_handoffs;
    my @plans;
    no warnings 'redefine';
    local *FSM::Scheduler::ISF::ChildStorageOwnership::plan_child_storage_read_handoffs = sub {
        my $before = dclone([@_]);
        my $plan = $original->(@_);
        is_deeply([@_], $before, 'real planner leaves caller-owned inputs untouched');
        push @plans, dclone($plan); return $plan;
    };
    my $ir = $l->build_module($a);
    is(scalar @plans, 1, 'executable connection uses the real shared planner once');
    return ($ir, $plans[0]);
}
sub compare_actual {
    my ($a, $p) = @_;
    my ($ir, $actual) = observe_plan($a);
    my $r = $p->{parent_storage_read_products};
    is_deeply($r, $actual, 'complete allocation inputs and actual read products agree');
    my %ports = map {$_->{name} => $_} @{$ir->{ports}};
    for my $port (@{$r->{ports}}) {
        is_deeply($port, $ports{$port->{name}}, 'actual parent output retained');
        is($ir->{signal_type_refs}{$port->{name}}, $r->{signal_type_refs}{$port->{name}}, 'exact storage type alias retained');
    }
    my @dts = grep {($_->{kind}//'') eq 'actor_storage_read_handoff'} @{$ir->{dt_blocks}};
    is_deeply($r->{dt_blocks}, \@dts, 'actual combinational owner views retained');
    for my $spawn (@{$ir->{spawn_instances}}) {
        my $record = $r->{instances}{$spawn->{instance}} || next;
        is_deeply($record->{links}, $spawn->{actor_storage_reads}, 'actual consumer links retained');
        is($record->{child}, $spawn->{child}, 'consumer module ownership explicit');
        for my $link (@{$record->{links}}) {
            is($link->{parent_port}, $r->{storage}{$link->{child_port}}{parent_port}, 'consumers share the owned storage view');
        }
    }
    for my $name (keys %{$r->{storage}}) {
        is_deeply($r->{storage}{$name}{identity}, ['actor_storage_read', $a->{actor_name}, $name], 'typed storage identity explicit');
    }
    return $ir;
}
sub strict_parent {
    my ($ir, $label) = @_;
    my $path = "$work/$label.fsm";
    open my $fh, '>', $path or die $!;
    print {$fh} $s->{fsm_emitter}->emit($ir); close $fh or die $!;
    my $r = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen','--strict','--check','--json',$path], '');
    is($r->{exit_code}, 0, "$label strict parent") or diag($r->{stdout},$r->{stderr});
}
subtest 'actual shared scalar aggregate and bank products survive projection' => sub {
    for my $kind (qw(scalar typed record list bank multiple read_write)) {
        my $text = $base;
        if ($kind =~ /^(typed|record|list)$/) {
            my $type = $kind eq 'typed' ? '(bits 4)' : $kind eq 'record'
                ? '(record (high (bits 2)) (low (bits 2)))' : '(list (bits 2) (bits 2))';
            $text =~ s/\(storage/(types (type value_t $type)) (storage/;
            $text =~ s/\(var value_reg \(width 4\)/(var value_reg (type value_t)/;
        }
        if ($kind eq 'bank') {
            $text =~ s/\(var value_reg \(width 4\) \(reset 3\)\)/(bank slots (width 4) (depth 2))/;
            $text =~ s/\(set data value_reg\)/(load slots 1 as data)/;
        }
        if ($kind eq 'multiple') {
            $text =~ s/\(output done\)/(output done) (output extra (width 4))/;
            $text =~ s/\(await_all done\)/(spawn worker as other (bind (output data extra))) (await_all done)/;
        }
        $text =~ s/\(set data value_reg\)/(set value_reg 7) (set data value_reg)/ if $kind eq 'read_write';
        my $a = parse($text); my $before = dclone($a);
        my $p = $l->prepare_formal_source($a);
        my $r = $p->{parent_storage_read_products};
        is(scalar keys %{$r->{storage}}, 1, 'one selected live storage view');
        compare_actual($a, $p);
        if ($kind eq 'read_write') {
            ok(@{$p->{parent_storage_write_products}{ports}}, 'actual write handoffs precede reads');
            for my $port (@{$p->{parent_storage_write_products}{ports}}) {
                ok($r->{input_names}{$port->{name}}, 'read allocation reserves preceding write port');
            }
        }
        my ($physical, $reserved) = project($p);
        my $q = $l->prepare_formal_source($physical);
        strict_parent(compare_actual($physical, $q), $kind);
        for my $port (@{$q->{parent_storage_read_products}{ports}}) {
            ok(scalar(grep {lc($_) eq lc($port->{name})} keys %$reserved), 'source inventory covers physical allocation');
        }
        my $children = dclone($p->{generated_child_products});
        my $writes = dclone($p->{parent_storage_write_products});
        $r->{ports}[0]{name} = 'changed';
        $r->{instances}{job}{links}[0]{child_port} = 'changed';
        is_deeply($p->{generated_child_products}, $children, 'read plans detached from children');
        is_deeply($p->{parent_storage_write_products}, $writes, 'read plans detached from write plans');
        is_deeply($p->{actor}, $before, 'prepared source remains unchanged');
        is_deeply($a, $before, 'caller source remains unchanged');
    }
};
subtest 'portable formal fixed and authored block collisions retain ownership' => sub {
    for my $name (qw(isf_storage_read_value_reg ISF_STORAGE_READ_VALUE_REG)) {
        for my $kind (qw(formal fixed rule)) {
            my $text = $base;
            $text =~ s/\bpayload\b/$name/g if $kind eq 'formal';
            $text =~ s/\(input fire\)/(input fire) (input $name)/ if $kind eq 'fixed';
            if ($kind eq 'rule') {
                $text =~ s/\(output done\)/(output done) (output flag)/;
                $text =~ s/\(transaction worker/(rule $name fire (flag 1)) (transaction worker/;
            }
            my $a = parse($text); my $p = $l->prepare_formal_source($a);
            compare_actual($a, $p);
            isnt(lc($p->{parent_storage_read_products}{ports}[0]{name}), lc($name), 'portable namespace collision avoided');
            my ($physical, $reserved) = project($p);
            my $q = $l->prepare_formal_source($physical);
            strict_parent(compare_actual($physical, $q), "${kind}_$name");
            for my $port (@{$q->{parent_storage_read_products}{ports}}) {
                ok(scalar(grep {lc($_) eq lc($port->{name})} keys %$reserved), 'post-projection allocation covered');
            }
        }
    }
};
subtest 'raw role conflicts and absent reads keep executable boundaries' => sub {
    (my $text = $base) =~ s/\bpayload\b/value_reg/g;
    my $a = parse($text); my $p = $l->prepare_formal_source($a);
    is(scalar @{$p->{parent_storage_read_products}{ports}}, 1, 'potential read survives raw storage/formal overlap');
    eval {$l->build_module($a)};
    like($@, qr/storage role for 'value_reg' conflicts across transactions/, 'raw executable ownership still refuses');
    my ($physical) = project($p);
    strict_parent(compare_actual($physical, $l->prepare_formal_source($physical)), 'raw_projected');
    ($text = $base) =~ s/\(set data value_reg\)/(set data 2)/;
    $a = parse($text); $p = $l->prepare_formal_source($a);
    compare_actual($a, $p);
    for my $field (qw(ports dt_blocks)) {is_deeply($p->{parent_storage_read_products}{$field}, [], "unused read creates no $field")}
    for my $field (qw(storage instances)) {is_deeply($p->{parent_storage_read_products}{$field}, {}, "unused read creates no $field")}
};
done_testing;
