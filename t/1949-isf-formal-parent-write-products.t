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
(actor parent_write_products (clock clk) (reset rst_n)
 (interface (input fire) (input din (width 4)) (output done))
 (storage (var cell (width 4) (reset 3)))
 (transaction worker (ports (input data (width 4))) (set cell data) (complete done))
 (transaction main (ports (input payload (width 4))) (on fire) (set payload din)
  (spawn worker as job (bind (input data payload))) (await_all done) (complete done)))
ISF
sub parse {FSM::Adapter::ISF->new->parse_source($_[0], 'parent_write_products.isf')}
sub inventory {FSM::Scheduler::ISF::FormalReservationInventory->collect($_[0])->{reserved_names}}
sub products {
    my ($p) = @_;
    return {map {$_ => $p->{$_}} qw(transaction_products parent_activation_products
        parent_wiring_products parent_point_products resource_signal_products generated_child_products
        parent_completion_products reusable_child_products)};
}
sub project {
    my ($p) = @_;
    my $a = dclone($p->{actor});
    my $products = products($p);$products->{writes} = $p->{parent_storage_write_products};
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
sub observe_plan {
    my ($actor) = @_;
    my $original = \&FSM::Scheduler::ISF::ChildStorageOwnership::plan_child_storage_write_handoffs;
    my @plans;
    no warnings 'redefine';
    local *FSM::Scheduler::ISF::ChildStorageOwnership::plan_child_storage_write_handoffs = sub {
        my $plan = $original->(@_);push @plans, dclone($plan);return $plan;
    };
    my $ir = $l->build_module($actor);
    is(scalar @plans, 1, 'actual parent connection invokes the shared planner once');
    return ($ir, $plans[0]);
}
sub strict_parent {
    my ($ir, $label) = @_;
    my $path = "$work/$label.fsm";
    open my $fh, '>', $path or die $!;
    print {$fh} $s->{fsm_emitter}->emit($ir);close $fh or die $!;
    my $r = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $path], '');
    is($r->{exit_code}, 0, "$label strict parent carrier") or diag($r->{stdout}, $r->{stderr});
}
sub compare_actual {
    my ($a, $p, $label) = @_;
    my ($ir, $actual) = observe_plan($a);
    my $w = $p->{parent_storage_write_products};
    is_deeply($w, $actual, "$label complete allocation inputs and real handoff products agree");
    my %ports = map {$_->{name} => $_} @{$ir->{ports}};
    for my $port (@{$w->{ports}}) {
        is_deeply($port, $ports{$port->{name}}, "$label actual allocated parent port");
        is($ir->{signal_widths}{$port->{name}}, $port->{width}, 'actual parent width comes from child storage contract');
    }
    my @dts = grep {($_->{kind}//'') eq 'actor_storage_write_handoff'} @{$ir->{dt_blocks}};
    is_deeply($w->{dt_blocks}, \@dts, "$label actual owner-side write DTs retained");
    for my $instance (@{$ir->{spawn_instances}}) {
        my $record = $w->{instances}{$instance->{instance}} || next;
        is_deeply($record->{links}, $instance->{actor_storage_writes}, 'real top handoff links retained');
        for my $write (@{$record->{writes}}) {
            is_deeply($write->{identity}, ['actor_storage_write', $a->{actor_name}, $instance->{instance}, $write->{storage}], 'typed actor instance and storage ownership explicit');
            my ($dt) = grep {$_->{name} eq $write->{enable_port}} @dts;
            is($dt->{assignments}[0]{lhs}, $write->{storage}, 'write target remains actor-owned storage');
            is($dt->{assignments}[0]{rhs}, $write->{data_port}, 'same-cycle handoff uses actual data port');
        }
    }
    return $ir;
}

subtest 'real parent write declarations preserve storage types and source snapshots' => sub {
    for my $kind (qw(scalar typed record list two_targets)) {
        my $text = $base;
        if ($kind =~ /^(typed|record|list)$/) {
            my $type = $kind eq 'typed' ? '(bits 4)' : $kind eq 'record'
                ? '(record (high (bits 2)) (low (bits 2)))' : '(list (bits 2) (bits 2))';
            $text =~ s/\(storage/(types (type value_t $type)) (storage/;
            $text =~ s/\(var cell \(width 4\)/(var cell (type value_t)/;
        }
        if ($kind eq 'two_targets') {
            $text =~ s/\(storage/(storage (var extra (width 4))/;
            $text =~ s/\(set cell data\)/(set cell data) (set extra data)/;
        }
        my $a = parse($text);my $before = dclone($a);
        my $p = $l->prepare_formal_source($a);
        my $w = $p->{parent_storage_write_products};
        my $prior = inventory(products($p));
        for my $port (@{$w->{ports}}) {ok(!$prior->{$port->{name}}, 'actual parent write port was absent from earlier products')}
        compare_actual($a, $p, $kind);
        my ($physical) = project($p);
        my $q = $l->prepare_formal_source($physical);
        strict_parent(compare_actual($physical, $q, "physical_$kind"), $kind);
        is_deeply($q->{parent_storage_write_products}{instances}, $w->{instances}, 'ordinary formal projection retains actual handoff identities');
        ok(keys %{$w->{signal_type_refs}}, 'actual storage alias reaches parent data handoff') if $kind =~ /^(typed|record|list)$/;
        my $children = dclone($p->{generated_child_products});
        my $activations = dclone($p->{parent_activation_products});
        $w->{instances}{job}{writes}[0]{identity}[1] = 'changed';
        $w->{ports}[0]{name} = 'changed';
        is_deeply($p->{generated_child_products}, $children, 'plan edits cannot mutate child declarations');
        is_deeply($p->{parent_activation_products}, $activations, 'plan edits cannot mutate registration');
        is_deeply($p->{actor}, $before, 'prepared source unchanged');
        is_deeply($a, $before, 'authored source unchanged');
    }
};
subtest 'portable collisions and raw formal aliases remain distinct' => sub {
    for my $name ('isf_write_job_cell_data', 'ISF_WRITE_JOB_CELL_ENABLE') {
        for my $kind (qw(formal fixed)) {
            my $text = $base;
            $text =~ s/\bpayload\b/$name/g if $kind eq 'formal';
            $text =~ s/\(input fire\)/(input fire) (input $name)/ if $kind eq 'fixed';
            my $a = parse($text);my $p = $l->prepare_formal_source($a);
            compare_actual($a, $p, "${kind}_$name");
            ok(!scalar(grep {lc($_->{name}) eq lc($name)} @{$p->{parent_storage_write_products}{ports}}), 'portable allocator avoids raw collision');
            my ($physical, $plan, $reserved) = project($p);
            my $q = $l->prepare_formal_source($physical);
            my $ir = compare_actual($physical, $q, 'projected');
            for my $port (@{$q->{parent_storage_write_products}{ports}}) {
                ok(scalar(grep {lc($_) eq lc($port->{name})} keys %$reserved), 'actual post-projection handoff covered by portable source/product inventory');
            }
            strict_parent($ir, "${kind}_$name");
        }
    }
    (my $text = $base) =~ s/\bpayload\b/cell/g;
    my $a = parse($text);my $p = $l->prepare_formal_source($a);
    is(scalar @{$p->{parent_storage_write_products}{ports}}, 2, 'raw formal/storage overlap retains potential write ports');
    eval {$l->build_module($a)};
    like($@, qr/storage role for 'cell' conflicts across transactions/, 'raw parent alias still fails executable ownership');
    my ($physical) = project($p);
    strict_parent(compare_actual($physical, $l->prepare_formal_source($physical), 'raw_projected'), 'raw_projected');
};
subtest 'potential plans do not admit competing writers or invent unused handoffs' => sub {
    for my $kind (qw(parent generated)) {
        my $text = $base;
        $text =~ s/\(on fire\)/(on fire) (set cell 0)/ if $kind eq 'parent';
        $text =~ s/\(await_all done\)/(spawn worker as other (bind (input data payload))) (await_all done)/ if $kind eq 'generated';
        my $a = parse($text);my $p = $l->prepare_formal_source($a);
        ok(@{$p->{parent_storage_write_products}{ports}}, 'potential declarations retained before writer admission');
        eval {$l->build_module($a)};
        like($@, $kind eq 'parent' ? qr/parent writer and generated child writer/ : qr/competing generated child writers/,
            "$kind competing writer remains refused before actual allocation");
    }
    (my $text = $base) =~ s/\(set cell data\)/(wait 1)/;
    my $w = $l->prepare_formal_source(parse($text))->{parent_storage_write_products};
    is_deeply($w->{ports}, [], 'readonly child creates no write port');
    is_deeply($w->{instances}, {}, 'readonly child creates no write ownership');
    is_deeply($w->{dt_blocks}, [], 'readonly child creates no write DT');
};
done_testing;
