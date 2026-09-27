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
open my $fh, '<', 'isf/fifo_library_use.isf' or die $!;
my $base = do {local $/; <$fh>}; close $fh or die $!;
sub parse {FSM::Adapter::ISF->new->parse_source($_[0], 'isf/fifo_library_use.isf')}
sub append_body {my ($text, $body) = @_; $text =~ s/\)\s*\z/ $body)/; return $text}
sub inventory {
    my ($p) = @_;
    return FSM::Scheduler::ISF::FormalReservationInventory->collect(
        {map {$_ => $p->{$_}} grep {$_ eq 'actor' || /products$/} keys %$p})->{reserved_names};
}
sub declarations {
    my ($ir) = @_;
    return {map {$_ => 1} grep {defined $_} (
        (map {keys %{$ir->{$_} || {}}} qw(signal_widths counters signal_type_refs storage_roles reset_values output_defaults)),
        (map {$_->{name}} @{$ir->{ports} || []}, @{$ir->{explicit_interface_ports} || []},
            @{$ir->{constants} || []}, @{$ir->{params} || []}, @{$ir->{states} || []}, @{$ir->{dt_blocks} || []}),
        @{$ir->{explicit_internal_signals} || []}, $ir->{clock}, (($ir->{reset} || {})->{name} // ()),
    )};
}
sub observe {
    my ($a) = @_;
    my @calls;
    my $connect = \&FSM::Scheduler::ISF::LoweringIR::connect_library_output_readbacks;
    my $finalize = \&FSM::Scheduler::ISF::LoweringIR::_finalize_ir;
    no warnings 'redefine';
    local *FSM::Scheduler::ISF::LoweringIR::connect_library_output_readbacks = sub {
        my ($ir, $uses) = @_;
        my $record = {stage => 'readback', actor => $ir->{actor_name}, before => dclone($ir), uses => dclone($uses)};
        my $result = eval {$connect->(@_)};
        my $error = $@;
        $record->{after} = dclone($ir); $record->{result} = $result; $record->{error} = $error;
        push @calls, $record;
        die $error if length $error;
        return $result;
    };
    local *FSM::Scheduler::ISF::LoweringIR::_finalize_ir = sub {
        my ($ir) = @_;
        my $before = declarations($ir);
        my $result = $finalize->(@_);
        push @calls, {stage => 'finalize', actor => $ir->{actor_name}, before => $before, after => declarations($ir)};
        return $result;
    };
    my $ir = eval {$l->build_module($a)};
    my $error = $@;
    return ($ir, [grep {$_->{actor} eq $a->{actor_name}} @calls], $error);
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
sub qualify {
    my ($a, $label, $count) = @_;
    my $source = dclone($a);
    my $p = $l->prepare_formal_source($a);
    my $reserved = inventory($p);
    my ($ir, $calls, $error) = observe($a);
    is($error, '', "$label real lowering succeeds") or return;
    is_deeply([map {$_->{stage}} @$calls], $count ? ['finalize', 'readback', 'finalize'] : ['finalize', 'readback'],
        "$label observes actual readback and conditional re-finalization order");
    my ($readback) = grep {$_->{stage} eq 'readback'} @$calls;
    is($readback->{result}, $count, "$label actual owner count");
    my $expected = dclone($readback->{before});
    my %owners = map {$_->{parent_name} => 1} grep {$_->{role} eq 'output'} map {@{$_->{bindings}}} @{$readback->{uses}};
    for my $port (@{$expected->{explicit_interface_ports}}) {
        next unless $owners{$port->{name}};
        is($port->{direction}, 'output', "$label authored output admission");
        $port->{direction} = 'input';
        $expected->{storage_roles}{$port->{name}} = 'library_output_readback';
    }
    is_deeply($readback->{after}, $expected, "$label complete effect is only direction and role adaptation");
    is_deeply($readback->{before}{ports}, $ir->{ports}, "$label public names, directions, widths and types unchanged");
    for my $call (@$calls) {
        my $before = $call->{stage} eq 'readback' ? declarations($call->{before}) : $call->{before};
        my $after = $call->{stage} eq 'readback' ? declarations($call->{after}) : $call->{after};
        is_deeply($after, $before, "$label $call->{stage} preserves complete declaration name set");
        is_deeply([sort grep {!$reserved->{$_}} keys %$after], [], "$label $call->{stage} names covered by real prepared products");
    }
    is_deeply($a, $source, "$label execution and preparation leave source unchanged");
    my $path = "$work/$label.fsm";
    open my $out, '>', $path or die $!; print {$out} $s->{fsm_emitter}->emit($ir); close $out or die $!;
    my $check = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $path], '');
    is($check->{exit_code}, 0, "$label strict emitted readback carrier") or diag($check->{stdout}, $check->{stderr});
    return $ir;
}
subtest 'real library readback adaptation preserves reservation namespace' => sub {
    for my $kind (qw(plain observed typed formal mixed_completion)) {
        my $text = $base;
        if ($kind eq 'observed') {
            $text =~ s/\(interface/(interface (output seen (width 8))/;
            $text = append_body($text, '(rule observe 1 (seen data_out))');
        }
        if ($kind eq 'typed') {
            $text =~ s/\(interface/(types (type Byte (bits 8))) (interface/;
            $text =~ s/\(output data_out \(width 8\)\)/(output data_out (type Byte))/;
        }
        if ($kind eq 'formal') {
            $text = append_body($text, '(transaction main (ports (input delay (width 4))) (wait delay))');
        }
        if ($kind eq 'mixed_completion') {
            $text =~ s/\(interface/(interface (input fire) (output notice) (output done)/;
            $text = append_body($text, '(transaction worker (complete notice)) (transaction main (on fire) (spawn worker as job) (await_all done) (complete notice))');
        }
        my $a = parse($text);
        qualify($a, $kind, 3);
        qualify(project($l->prepare_formal_source($a)), "${kind}_projected", 3);
    }
    qualify(parse('(actor no_library (clock clk) (reset rst_n) (interface (input fire) (output seen)) (rule observe fire (seen fire)))'), 'no_library', 0);
};
subtest 'readback refusal cannot allocate a hidden declaration' => sub {
    for my $kind (qw(writer reset default completion duplicate)) {
        my $text = $base;
        my $reason = qr/Library-owned output 'full' also has a parent writer/;
        $text = append_body($text, '(rule competing 1 (full 1))') if $kind eq 'writer';
        if ($kind eq 'reset' || $kind eq 'default') {
            $text =~ s/\(output full\)/(output full ($kind 0))/;
            $reason = qr/Library-owned output 'full' cannot have a parent reset or default/;
        }
        if ($kind eq 'completion') {
            $text =~ s/\(interface/(interface (input start) (output done)/;
            $text = append_body($text, '(transaction worker (complete full)) (transaction parent (on start) (spawn worker as w0) (await_all done) (complete done))');
        }
        if ($kind eq 'duplicate') {
            $text = append_body($text, '(use fifo_lib.fifo as second_fifo (bind (clock clk) (reset rst_n) (input write_req write_req) (input data_in data_in) (input read_req read_req) (output full full) (output empty empty) (output data_out data_out)))');
            $reason = qr/Library output 'full' is driven by both 'u_fifo' and 'second_fifo'/;
        }
        my $a = parse($text);
        my $p = $l->prepare_formal_source($a);
        for my $actor ($a, project($p)) {
            my ($ir, $calls, $error) = observe($actor);
            ok(!defined $ir, "$kind executable parent refused");
            like($error, $reason, "$kind canonical admission remains authoritative");
            my @readback = grep {$_->{stage} eq 'readback'} @$calls;
            is(scalar @readback, 1, "$kind refusal observed at actual readback boundary");
            next unless @readback;
            is($readback[0]{error}, $error, "$kind original exception propagated");
            is_deeply(declarations($readback[0]{after}), declarations($readback[0]{before}), "$kind partial admission introduces no name");
            is($calls->[-1]{stage}, 'readback', "$kind rejected parent is never re-finalized");
        }
    }
};
done_testing;
