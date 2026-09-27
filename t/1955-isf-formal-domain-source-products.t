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
use FSM::Scheduler::ISF::FormalLowering;
use FSM::Scheduler::ISF::FormalIdentityPlan;
use FSM::Scheduler::ISF::FormalClauseResolver;
use FSM::Scheduler::ISF::FormalReservationInventory;

my $s = FSM::Scheduler::ISF->new;
my $l = $s->{ir};
my $work = tempdir(CLEANUP => 1);
my $case_ordinal = 0;
my $activation = <<'ISF';
(actor domain_activation_products
 (clock-domains (domain core (clock clk) (reset rst_n) :default)
                (domain aux (clock aux_clk) (reset aux_rst_n)))
 (interface (input start) (output done) (output observed (domain aux)))
 (crossings (activation worker (from core) (to aux)))
 (transaction parent (on start) (do worker) (complete done))
 (transaction worker (domain aux) (wait 2) (complete observed)))
ISF
sub parse {FSM::Adapter::ISF->new->parse_source($_[0], $_[1] // 'domain_products.isf')}
sub inventory {
    my ($p) = @_;
    return FSM::Scheduler::ISF::FormalReservationInventory->collect(
        {map {$_ => $p->{$_}} grep {$_ eq 'actor' || /products$/ || $_ eq 'domain_partition'} keys %$p})->{reserved_names};
}
sub declarations {
    my ($ir) = @_;
    return {map {$_ => 1} grep {defined $_} (
        (map {keys %{$ir->{$_} || {}}} qw(signal_widths counters storage_roles signal_type_refs reset_values output_defaults)),
        (map {$_->{name}} @{$ir->{ports} || []}, @{$ir->{explicit_interface_ports} || []},
            @{$ir->{constants} || []}, @{$ir->{params} || []}, @{$ir->{states} || []}, @{$ir->{dt_blocks} || []}),
        @{$ir->{explicit_internal_signals} || []}, $ir->{clock}, (($ir->{reset} || {})->{name} // ()),
    )};
}
sub prepare {
    my ($a) = @_;
    no warnings 'redefine';
    local *FSM::Scheduler::ISF::LoweringIR::build_module = sub {die "preparation executed a parent merge\n"};
    return $l->prepare_formal_source($a);
}
sub project {
    my ($p) = @_;
    my $a = dclone($p->{actor});
    my $plan = FSM::Scheduler::ISF::FormalIdentityPlan->build($a,
        generated_children => $p->{generated_children}, reserved_names => inventory($p));
    for my $tx (@{$a->{transactions}}) {
        next if $p->{pruned_transactions}{$tx->{name}};
        $tx = FSM::Scheduler::ISF::FormalClauseResolver->transaction($tx,
            plan => $plan, %{$p->{transactions}{$tx->{name}}})->{transaction};
    }
    return $a;
}
sub actual {
    my ($a) = @_;
    my (%sources, %modules);
    my $source_cv = \&FSM::Scheduler::ISF::_domain_actor_for_scheduled_artifact;
    my $build_cv = \&FSM::Scheduler::ISF::LoweringIR::build_module;
    no warnings 'redefine';
    local *FSM::Scheduler::ISF::_domain_actor_for_scheduled_artifact = sub {
        my $source = $source_cv->(@_);
        $sources{$source->{_scheduled_domain_name}} = dclone($source);
        return $source;
    };
    local *FSM::Scheduler::ISF::LoweringIR::build_module = sub {
        my ($self, $source) = @_;
        my $ir = $build_cv->(@_);
        $modules{$source->{_scheduled_domain_name}} = dclone($ir) if defined $source->{_scheduled_domain_name};
        return $ir;
    };
    my $files = $s->lower($a)->{files};
    return ($files, \%sources, \%modules);
}
sub qualify {
    my ($a, $label) = @_;
    my $before = dclone($a);
    my $p = prepare($a);
    my $context = FSM::Scheduler::ISF::FormalLowering->prepare($l, $a);
    my $physical = $context ? $context->{actor} : $a;
    my $physical_prepared = $l->prepare_formal_source($physical);
    my ($files, $sources, $modules) = actual($a);
    my $products = $physical_prepared->{domain_source_products};
    is_deeply([sort keys %$products], [sort keys %$sources], "$label actual domain source set retained");
    for my $name (sort keys %$sources) {
        my $r = $products->{$name}; my $local = $r->{preparation};
        is_deeply($r->{identity}, ['actor_domain', $a->{actor_name}, $name], "$label logical domain identity retained");
        is_deeply($local->{actor}, $sources->{$name}, "$label complete actual domain source retained");
        is_deeply($local, prepare($sources->{$name}), "$label actual source reproduces complete local preparation");
        is_deeply($local->{domain_source_products}, {}, "$label independent module terminates domain preparation");
        ok(!defined $local->{domain_partition}, "$label source constructor clears outer partition");
        my $reserved = inventory($local);
        is_deeply([sort grep {!$reserved->{$_}} keys %{declarations($modules->{$name})}], [], "$label actual domain declarations covered locally");
        is($modules->{$name}{actor_name} . '.fsm', $r->{domain}{scheduled_fsm}, "$label physical module matches partition artifact");
        my $default = $p->{domain_partition}{default_domain};
        for my $field (qw(transactions rules storage library_uses)) {
            is_deeply($sources->{$name}{$field}, [grep {($_->{domain} // $default) eq $name} @{$physical->{$field} || []}],
                "$label $field contains only the projected declarations of its authored domain owners");
        }
    }
    is_deeply($a, $before, "$label source unchanged by preparation and execution");
    my $dir = "$work/" . ++$case_ordinal . "_$label"; mkdir $dir or die $!;
    for my $file (sort keys %$files) {
        open my $out, '>', "$dir/$file" or die $!; print {$out} $files->{$file}; close $out or die $!;
    }
    my $top = "$dir/$a->{actor_name}_top.fsm";
    my $r = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $top], '');
    is($r->{exit_code}, 0, "$label actual exported composition strict-checks") or diag($r->{stdout}, $r->{stderr});
    return $p;
}
subtest 'activation ready, request and callee entry products are retained from real domain sources' => sub {
    my $a = parse($activation); my $p = qualify($a, 'activation');
    my %expected = (core => [qw(parent_do_1_ready parent_do_1_req worker_start_ready)],
                   aux => [qw(worker_idle_ext worker_done_ready worker_done_req)]);
    for my $name (sort keys %expected) {
        my $local = $p->{domain_source_products}{$name}{preparation};
        my $r = inventory($local);
        ok($r->{$_}, "$name previously missing external activation declaration $_ is retained") for @{$expected{$name}};
        is_deeply($local->{actor}{external_activations}, [{child => 'worker', role => $name eq 'core' ? 'caller' : 'callee',
            start_signal => 'worker_start', done_signal => 'worker_done'}], 'injected contract has exact caller/callee ownership');
    }
    qualify(project($p), 'activation_projected');
    my $snapshot = dclone($p);
    $p->{domain_source_products}{core}{preparation}{parent_wiring_products}{states}[0]{name} = 'mutated';
    is_deeply($p->{actor}, $snapshot->{actor}, 'local product mutation cannot edit original actor');
    is_deeply($p->{parent_wiring_products}, $snapshot->{parent_wiring_products}, 'local product mutation cannot edit monolithic products');
    is_deeply($p->{domain_source_products}{aux}, $snapshot->{domain_source_products}{aux}, 'local product mutation cannot edit sibling domain');
};
subtest 'event endpoints and portable domain identities retain source contracts' => sub {
    for my $file (qw(clock_domain_event_crossing clock_domain_dual_event_crossing clock_domain_no_reset_event_crossing)) {
        my $a = FSM::Adapter::ISF->new->parse_file("isf/$file.isf");
        my $p = qualify($a, $file);
        qualify(project($p), "${file}_projected");
    }
    my $text = $activation;
    $text =~ s/\bcore\b/CORE/g; $text =~ s/\baux\b/core/g;
    qualify(parse($text), 'case_domains');
};
subtest 'domain-local generated storage and named completion plans remain complete' => sub {
    my $text = <<'ISF';
(actor domain_generated_products
 (clock-domains (domain core (clock clk) (reset rst_n) :default)
                (domain aux (clock aux_clk) (reset aux_rst_n)))
 (interface (input start) (output done) (output notice) (output seen (width 4))
            (input aux_start (domain aux)) (output aux_done (domain aux)))
 (storage (var value_reg (width 4) (reset 3)))
 (transaction worker (ports (output data (width 4))) (set data value_reg) (complete notice))
 (transaction parent (ports (input delay (width 4))) (on start) (wait delay)
  (spawn worker as job (bind (output data seen))) (await_all done) (complete notice))
 (transaction aux_parent (domain aux) (on aux_start) (wait 1) (complete aux_done)))
ISF
    my $a = parse($text); my $p = qualify($a, 'generated');
    ok(exists $p->{domain_source_products}{core}{preparation}{generated_child_products}{worker}, 'worker retained in owning domain');
    is_deeply($p->{domain_source_products}{aux}{preparation}{generated_child_products}, {}, 'worker absent from sibling domain');
    qualify(project($p), 'generated_projected');
};
subtest 'reusable library children and empty domains retain independent sources' => sub {
    open my $in, '<', 'isf/fifo_library_use.isf' or die $!; my $text = do {local $/; <$in>}; close $in or die $!;
    $text =~ s/\(clock clk\)\s*\(reset \(rst_n async active_low\)\)/(clock-domains (domain core (clock clk) (reset (rst_n async active_low)) :default) (domain aux (clock aux_clk)))/;
    my $p = qualify(parse($text, 'isf/fifo_library_use.isf'), 'library');
    ok(keys %{$p->{domain_source_products}{core}{preparation}{reusable_child_products}{children}}, 'library retained in owning domain');
    is_deeply($p->{domain_source_products}{aux}{preparation}{reusable_child_products}{children}, {}, 'empty sibling has no copied library');
};
subtest 'formal aliases reserve actual external helpers without raw parent execution' => sub {
    for my $formal (qw(worker_start_ready WORKER_START_READY parent_do_2_ready)) {
        my $text = $activation;
        $text =~ s/\(transaction parent \(on start\)/(transaction parent (ports (input $formal (width 4))) (on start) (wait $formal)/;
        my $p = prepare(parse($text));
        my $physical = project($p);
        my ($parent) = grep {$_->{name} eq 'parent'} @{$physical->{transactions}};
        isnt($parent->{ports}{inputs}[0]{name}, $formal, 'direct formal receives a distinct physical identity');
        qualify($physical, "alias_$formal");
    }
    my $single = prepare(parse('(actor single (clock clk) (interface (input fire) (output done)) (transaction main (on fire) (complete done)))'));
    is_deeply($single->{domain_source_products}, {}, 'ordinary actor gains no fabricated domain scope');
    my $bad = $activation; $bad =~ s/\(do worker\)//;
    eval {prepare(parse($bad))};
    like($@, qr/declared but no transaction/, 'unused crossing remains rejected before product collection');
};
done_testing;
