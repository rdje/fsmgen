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
my $ordinal = 0;
sub parse {FSM::Adapter::ISF->new->parse_source($_[0], $_[1] // 'domain_outer.isf')}
sub inventory {
    my ($p) = @_;
    return FSM::Scheduler::ISF::FormalReservationInventory->collect(
        {map {$_ => $p->{$_}} grep {$_ eq 'actor' || /products$/ || $_ eq 'domain_partition'} keys %$p})->{reserved_names};
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
sub declarations {
    my ($ir) = @_;
    return {map {$_ => 1} grep {defined $_} (
        keys %{$ir->{signal_widths} || {}}, keys %{$ir->{counters} || {}},
        (map {$_->{name}} @{$ir->{ports} || []}, @{$ir->{states} || []}, @{$ir->{dt_blocks} || []}),
        $ir->{clock}, (($ir->{reset} || {})->{name} // ()),
    )};
}
sub observe {
    my ($a) = @_;
    my ($actual, $before, $partition, $calls);
    my $realize = \&FSM::Scheduler::ISF::_multi_domain_realizations;
    my $top = \&FSM::Scheduler::ISF::_emit_multi_domain_top;
    no warnings 'redefine';
    local *FSM::Scheduler::ISF::_multi_domain_realizations = sub {
        ++$calls;
        $partition = dclone($_[2]);
        $actual = $realize->(@_);
        $before = dclone($actual);
        return $actual;
    };
    local *FSM::Scheduler::ISF::_emit_multi_domain_top = sub {
        my $realizations = $_[3];
        my $ir_before = dclone([map {$_->{ir}} @$realizations]);
        my $result = $top->(@_);
        is_deeply([map {$_->{ir}} @$realizations], $ir_before, 'actual top emission preserves complete domain and child IR');
        return $result;
    };
    my $files = $s->lower($a)->{files};
    is($calls, 1, 'public lowering uses actual outer realization once');
    is_deeply([map {$_->{ir}} @$actual], [map {$_->{ir}} @$before], 'file materialization and top emission preserve all local IR');
    return ($files, $before, $partition);
}
sub identities {
    my ($realizations) = @_;
    return [map {{domain => $_->{domain}, names => $_->{names}, composed => $_->{composed}}} @$realizations];
}
sub sorted_pairs {return [sort {join(' ', @$a) cmp join(' ', @$b)} @{$_[0]}]}
sub qualify {
    my ($a, $label) = @_;
    my $before = dclone($a);
    my $p = $l->prepare_formal_source($a);
    my ($files, $realizations, $partition) = observe($a);
    my (@fsm, @rtl, @interfaces, @wiring, @expected_files);
    push @wiring, 'domain_wiring';
    push @expected_files, "$a->{actor_name}_top.fsm";
    for my $r (@$realizations) {
        my ($ir, $names, $domain) = @{$r}{qw(ir names domain)};
        my $local = $p->{domain_source_products}{$domain->{name}}{preparation};
        my $reserved = inventory($local);
        is_deeply([sort grep {!$reserved->{$_}} keys %{declarations($ir)}], [], "$label actual domain namespace covered before outer emission");
        push @expected_files, $domain->{scheduled_fsm};
        push @expected_files, map {"$_.fsm"} values %{$names->{modules}};
        push @fsm, [$domain->{instance}, $ir->{actor_name}];
        push @wiring, $names->{wiring_name} if $r->{composed};
        for my $spawn (@{$ir->{spawn_instances}}) {
            push @fsm, [$names->{instances}{$spawn->{instance}}, $names->{modules}{$spawn->{child}}];
        }
        for my $use (@{$ir->{library_uses}}) {
            push @fsm, [$names->{instances}{$use->{instance}}, $names->{modules}{$use->{module}}];
        }
        for my $top (@{$ir->{atl_top_instances}}) {
            for my $child (ref($top->{children}) eq 'ARRAY' ? @{$top->{children}} : ($top)) {
                push @fsm, [$names->{instances}{$child->{instance}}, $names->{modules}{$child->{child_module}}];
            }
        }
    }
    for my $crossing (@{$partition->{crossings}}) {
        for my $prefix ($crossing->{kind} eq 'event' ? ('') : ('start_', 'done_')) {
            push @rtl, [$crossing->{"${prefix}instance"}, $crossing->{"${prefix}module"}];
            push @interfaces, $crossing->{"${prefix}module"};
        }
    }
    my $top = $files->{"$a->{actor_name}_top.fsm"};
    my @actual_fsm; push @actual_fsm, [$1, $2] while $top =~ /\(\?fsmc:(\w+)\s+(\w+)/g;
    my @actual_rtl; push @actual_rtl, [$1, $2] while $top =~ /\(\?rtl:(\w+)\s+(\w+)/g;
    my @actual_interfaces = $top =~ /\(\?rtlif:(\w+)/g;
    my @actual_wiring = $top =~ /\(\?wiring:(\w+)/g;
    is_deeply(sorted_pairs(\@actual_fsm), sorted_pairs(\@fsm), "$label exact outer FSM instance/module namespace");
    is_deeply(sorted_pairs(\@actual_rtl), sorted_pairs(\@rtl), "$label exact CDC instance/module namespace");
    is_deeply([sort @actual_interfaces], [sort @interfaces], "$label exact separate CDC interface declarations");
    is_deeply([sort @actual_wiring], [sort @wiring], "$label exact composition wiring labels");
    is_deeply([sort keys %$files], [sort @expected_files], "$label exact module/file artifact namespace");
    my %folded;
    ok(!$folded{lc $_}++, "$label case-independent artifact identity $_") for keys %$files;
    my %instances;
    ok(!$instances{lc $_->[0]}++, "$label portable outer child identity $_->[0]") for @actual_fsm, @actual_rtl;
    is_deeply($a, $before, "$label outer realization leaves source unchanged");
    my $dir = "$work/" . ++$ordinal; mkdir $dir or die $!;
    for my $file (sort keys %$files) {
        open my $fh, '>', "$dir/$file" or die $!; print {$fh} $files->{$file}; close $fh or die $!;
    }
    my $check = FSM::Test::SourceQueryRunner::_capture([$^X,'bin/fsmgen','--strict','--check','--json',"$dir/$a->{actor_name}_top.fsm"], '');
    is($check->{exit_code}, 0, "$label exported outer composition is strict-admissible") or diag($check->{stdout}, $check->{stderr});
    return {realizations => identities($realizations), files => [sort keys %$files],
        ports => [$top =~ /\(\?ports:public_io\s+([^()]*)\)/s], rtl_interfaces => [sort @actual_interfaces]};
}
sub compare_projection {
    my ($a, $label) = @_;
    my $original = qualify($a, $label);
    my $physical = project($l->prepare_formal_source($a));
    is_deeply(qualify($physical, "${label}_projected"), $original,
        "$label formal projection preserves every outer identity and public port declaration");
    return $original;
}
my $generated = <<'ISF';
(actor outer_products
 (clock-domains (domain core (clock clk) (reset rst_n) :default)
                (domain aux (clock aux_clk) (reset aux_rst_n)))
 (interface (input start) (input core__job) (output done) (output seen (width 4))
            (output again (width 4)) (input aux_start (domain aux)) (output aux_done (domain aux)))
 (storage (var value_reg (width 4) (reset 3)))
 (transaction worker (ports (output data (width 4))) (set data value_reg) (complete done))
 (transaction parent (ports (input payload (width 4))) (on start) (wait payload)
  (spawn worker as job (bind (output data seen))) (spawn worker as other (bind (output data again)))
  (await_all done) (complete done))
 (transaction aux_parent (domain aux) (on aux_start) (wait 1) (complete aux_done)))
ISF
subtest 'outer child names are independent of domain-local formal declarations' => sub {
    my $r = compare_projection(parse($generated), 'generated');
    my ($core) = grep {$_->{domain}{name} eq 'core'} @{$r->{realizations}};
    isnt($core->{names}{instances}{job}, 'core__job', 'actual flat child allocation avoids authored public pin');
    my $text = $generated;
    $text =~ s/\(clock-domains/(clock-domains (domain core__child_worker (clock empty_clk))/;
    $r = compare_projection(parse($text), 'module_collision');
    ($core) = grep {$_->{domain}{name} eq 'core'} @{$r->{realizations}};
    isnt($core->{names}{modules}{worker}, 'outer_products__domain_core__child_worker', 'actual child module allocation reserves other domain artifacts');
    $text = $generated; $text =~ s/\bcore\b/BUS/g;
    compare_projection(parse($text), 'keyword_domain');
    $text = $generated; $text =~ s/\baux\b/CORE/g;
    compare_projection(parse($text), 'case_domains');
};
subtest 'event and activation CDC declarations keep their own interface scope' => sub {
    for my $file (qw(clock_domain_event_crossing clock_domain_dual_event_crossing clock_domain_no_reset_event_crossing)) {
        my $a = FSM::Adapter::ISF->new->parse_file("isf/$file.isf");
        compare_projection($a, $file);
    }
    my $text = <<'ISF';
(actor outer_activation
 (clock-domains (domain core (clock clk) (reset rst_n) :default)
                (domain aux (clock aux_clk) (reset aux_rst_n)))
 (interface (input start) (output done) (output observed (domain aux)))
 (crossings (activation worker (from core) (to aux)))
 (transaction parent (ports (input payload (width 4))) (on start) (wait payload) (do worker) (complete done))
 (transaction worker (domain aux) (wait 2) (complete observed)))
ISF
    compare_projection(parse($text), 'activation');
};
subtest 'library module allocation stays separate from parent formal projection' => sub {
    open my $fh, '<', 'isf/fifo_library_use.isf' or die $!; my $text = do {local $/; <$fh>}; close $fh or die $!;
    $text =~ s/\(clock clk\)\s*\(reset \(rst_n async active_low\)\)/(clock-domains (domain core (clock clk) (reset (rst_n async active_low)) :default) (domain aux (clock aux_clk)))/;
    $text =~ s/\)\s*\z/ (transaction parent (ports (input payload (width 4))) (wait payload)))/;
    compare_projection(parse($text, 'isf/fifo_library_use.isf'), 'library');
};
subtest 'unsupported multi-domain ATL event composition remains refused' => sub {
    open my $fh, '<', 'isf/atl_resolved_child_pipeline.isf' or die $!;
    my $text = do {local $/; <$fh>}; close $fh or die $!;
    $text =~ s/\(clock clk\)\s*\(reset \(rst_n async active_low\)\)/(clock-domains (domain core (clock clk) (reset (rst_n async active_low)) :default) (domain aux (clock aux_clk) (reset (aux_rst_n async active_low))))/;
    $text =~ s/\(transaction run/\(transaction run (ports (input payload (width 4)))/;
    my $a = eval {parse($text, 'isf/atl_resolved_child_pipeline.isf')};
    ok(!defined $a, 'ATL event composition is refused before domain preparation');
    like($@, qr/ATL actor event waits require a single-clock actor in the current subset/,
        'canonical parser keeps the supported clock-domain boundary explicit');
};
done_testing;
