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
use FSM::Scheduler::ISF::LoweringIR;
use FSM::Scheduler::ISF::FormalIdentityPlan;
use FSM::Scheduler::ISF::FormalClauseResolver;
use FSM::Scheduler::ISF::FormalReservationInventory;

my $lowerer = FSM::Scheduler::ISF::LoweringIR->new;
my $work = tempdir(CLEANUP => 1);
my $source = <<'ISF';
(actor preallocation (clock clk) (reset rst_n)
  (interface (input fire) (input ack) (input din (width 4)) (output observed (width 4)))
  (transaction main (ports (input payload (width 4)))
    (on fire) (set payload 3) (assert (monitor (within ack 3))) (set observed payload)))
ISF
sub parse {FSM::Adapter::ISF->new->parse_source($_[0], 'preallocation.isf')}
sub preparation_rejected {
    my ($actor, $pattern, $label) = @_;
    my $ok = eval {$lowerer->prepare_formal_source($actor); 1};
    ok(!$ok, "$label refused during preparation");
    like($@, $pattern, "$label diagnostic retained");
}
my $baseline = $lowerer->prepare_formal_source(parse($source));
my $products = $baseline->{transaction_products}{main};
my ($monitor) = grep {$_->{kind} eq 'temporal_contract_monitor'} @{$products->{dt_blocks}};
my ($arm) = map {$_->{lhs}} map {@{$_->{assignments}}}
    grep {$_->{kind} eq 'contract'} @{$products->{states}};
my %helpers = (arm => $arm);
for my $pair ([pending => 'contract_pending_set'], [age => 'contract_age_reset'], [fail => 'contract_fail']) {
    my ($assignment) = grep {$_->{source_kind} eq $pair->[1]} @{$monitor->{assignments}};
    $helpers{$pair->[0]} = $assignment->{lhs};
}
is_deeply($baseline->{deferred_formal_collisions}, {}, 'ordinary prepared source has no deferred collisions');

subtest 'only raw direct formal aliases can be deferred' => sub {
    for my $direction (qw(input output)) {
        for my $role (qw(arm pending age fail)) {
            my $helper = $helpers{$role};
            (my $text = $source) =~ s/\bpayload\b/$helper/g;
            $text =~ s/\(ports \(input /(ports ($direction /;
            my $actor = parse($text);
            my $before = dclone($actor);
            my $prepared = $lowerer->prepare_formal_source($actor);
            my $deferred = $prepared->{deferred_formal_collisions}{main};
            is(scalar @$deferred, 1, "$direction $role collision retained explicitly");
            is_deeply($deferred->[0]{source_identity}, ['transaction_port', 'preallocation', 'main', $helper], 'typed source identity retained');
            is($deferred->[0]{generated_signal}, $helper, 'actual generated signal retained');
            is($deferred->[0]{monitor_role}, $role, 'actual monitor role retained');
            is($deferred->[0]{generated_width}, $products->{counters}{$helper}, 'actual generated width retained');
            is($deferred->[0]{formal_declaration}{width}, 4, 'source formal width remains separate');
            my $raw_ok = eval {$lowerer->build_module($prepared->{actor}); 1};
            ok(!$raw_ok, 'preparation does not turn raw aliases into executable admission');
            like($@, qr/generated signal '\Q$helper\E' collides/, 'production collision check still applies');
            my $names = FSM::Scheduler::ISF::FormalReservationInventory->collect({
                transactions => $prepared->{transaction_products}, parent => $prepared->{parent_activation_products},
            })->{reserved_names};
            ok($names->{$helper}, 'deferred helper is still reserved from actual products');
            my $plan = FSM::Scheduler::ISF::FormalIdentityPlan->build($actor,
                generated_children => {}, reserved_names => $names);
            my $physical = dclone($actor);
            $physical->{transactions}[0] = FSM::Scheduler::ISF::FormalClauseResolver->transaction($actor->{transactions}[0],
                plan => $plan, %{$prepared->{transactions}{main}})->{transaction};
            my $name = $plan->{formals}{main}{$helper}{physical_name};
            my $ir = $lowerer->build_module($physical);
            is($ir->{counters}{$helper}, $products->{counters}{$helper}, 'production keeps monitor width');
            is($ir->{counters}{$name}, 4, 'production keeps distinct formal width');
            is_deeply($lowerer->prepare_formal_source($physical)->{deferred_formal_collisions}, {}, 'resolved physical source has no remaining deferral');
            my $files = FSM::Scheduler::ISF->new->lower($physical)->{files};
            my $path = "$work/${direction}_${role}.fsm";
            open my $fh, '>', $path or die $!;
            print {$fh} $files->{'preallocation.fsm'};
            close $fh or die $!;
            my $check = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $path], '');
            is($check->{exit_code}, 0, "$direction $role strict physical carrier") or diag($check->{stdout}, $check->{stderr});
            is_deeply($actor, $before, 'source actor stays unchanged');
            is_deeply($prepared->{actor}, $before, 'prepared actor carries no admission mode');
            $deferred->[0]{formal_declaration}{width} = 99;
            is($prepared->{actor}{transactions}[0]{ports}{"${direction}s"}[0]{width}, 4, 'deferred declarations are detached');
        }
    }
};

subtest 'fixed and already physical identities retain strict collision admission' => sub {
    my $helper = $helpers{age};
    (my $text = $source) =~ s/\bpayload\b/$helper/g;
    for my $case (
        ['storage', sub {$_[0] =~ s/\(transaction main/(storage (var $helper (width 8))) (transaction main/}],
        ['actor input', sub {$_[0] =~ s/\(input fire\)/(input fire) (input $helper (width 8))/}],
        ['actor constant', sub {$_[0] =~ s/\(transaction main/(constants ($helper 2)) (transaction main/}],
        ['clock', sub {$_[0] =~ s/\(clock clk\)/(clock $helper)/}],
        ['reset', sub {$_[0] =~ s/\(reset rst_n\)/(reset $helper)/}],
    ) {
        my $fixed = $text;
        $case->[1]->($fixed);
        preparation_rejected(parse($fixed), qr/generated signal '\Q$helper\E' collides/, $case->[0]);
    }
    my $projected = parse($text);
    $projected->{transactions}[0]{ports}{inputs}[0]{_isf_formal_identity} = {
        source => ['transaction_port', 'preallocation', 'main', 'payload'], physical_name => $helper,
    };
    preparation_rejected($projected, qr/generated signal '\Q$helper\E' collides/, 'already projected formal');
    (my $local = $text) =~ s/\(ports \(input \Q$helper\E \(width 4\)\)\)/(local $helper (width 4))/;
    preparation_rejected(parse($local), qr/generated signal '\Q$helper\E' collides/, 'explicit local');
    my $generated = $text;
    $generated =~ s/\)\s*\z//; # remove only the actor closing delimiter
    $generated .= " (transaction caller (on fire) (spawn main as job (bind (input $helper din))) (await_all done)))";
    preparation_rejected(parse($generated), qr/generated signal '\Q$helper\E' collides/, 'generated public formal');
};

subtest 'source checks still run before and after the deferred physical check' => sub {
    my $helper = $helpers{age};
    (my $text = $source) =~ s/\bpayload\b/$helper/g;
    for my $case (
        ['window', '(within ack 3)', '(within ack 0)', qr/N must be a positive integer/],
        ['observed signal', '(within ack 3)', '(within missing 3)', qr/not an actor interface signal/],
        ['local', '(set observed', '(local bad (width 4) (typo 1)) (set observed', qr/unsupported local option/],
    ) {
        my $bad = $text;
        $bad =~ s/\Q$case->[1]\E/$case->[2]/;
        preparation_rejected(parse($bad), $case->[3], $case->[0]);
    }
};
done_testing;
