use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $json = JSON::PP->new->canonical;
my $work = tempdir(CLEANUP => 1);
open my $package, '>:raw', "$work/shared.fsm" or die $!;
print {$package} '(?pkg:shared (+constants (LIMIT 2)))' or die $!;
close $package or die $!;

sub source {
    my ($depth, $watchdog) = @_;
    return <<"ISF";
(actor static_sources
  (clock clk) (reset rst_n) $watchdog
  (imports (package shared))
  (params (W 2) (ALIAS W) (OTHER 2))
  (constants (FIXED 2))
  (interface (input start) (input ready) (output data (width W)))
  (storage (bank mem (width W) (depth $depth)))
  (transaction main (on start) (await ready) (set data 0)))
ISF
}

sub parse {
    return FSM::Adapter::ISF->new->parse_source($_[0], "$work/peer.isf");
}

sub remove_owned_metadata {
    my ($actor) = @_;
    delete $actor->{_watchdog_declaration};
    delete $_->{_depth_declaration} for @{$actor->{storage}};
    return $actor;
}

subtest 'independent one-slot peers preserve exact source identities' => sub {
    my $literal = parse(source('2', '(watchdog 2)'));
    my $baseline = $json->encode($literal);
    my $scheduler = FSM::Scheduler::ISF->new;
    my $files = $scheduler->lower($literal)->{files};
    my $report = $scheduler->report($literal);
    for my $case (
        ['W', 'actor_parameter', 'static_sources'],
        ['ALIAS', 'actor_parameter', 'static_sources'],
        ['OTHER', 'actor_parameter', 'static_sources'],
        ['FIXED', 'actor_constant', 'static_sources'],
        ['shared.LIMIT', 'package_constant', 'shared'],
    ) {
        my ($token, $kind, $owner) = @$case;
        my $expected = {token => $token, kind => $kind, owner => $owner};
        for my $slot (qw(depth watchdog)) {
            my $actor = parse($slot eq 'depth'
                ? source($token, '(watchdog 2)') : source('2', "(watchdog $token)"));
            my $record = $slot eq 'depth' ? $actor->{storage}[0] : $actor;
            is_deeply($record->{"_${slot}_declaration"}, $expected,
                "$slot $token retains actual source namespace and lexical owner");
            is($json->encode($actor->{storage}[0]{depth}), '2', 'depth stays a JSON number');
            is($json->encode($actor->{watchdog}), '"2"', 'watchdog keeps its JSON string kind');
            my $before = $json->encode($actor);
            is_deeply($scheduler->lower($actor)->{files}, $files, 'complete carrier bytes unchanged');
            is($scheduler->report($actor), $report, 'complete schedule report unchanged');
            is($json->encode($actor), $before, 'lower/report preserve complete caller kinds');
            is($json->encode(remove_owned_metadata($actor)), $baseline,
                'complete actor differs only by owned metadata');
        }
    }
    ok(!exists $literal->{_watchdog_declaration}, 'literal watchdog gains no dependency');
    ok(!exists $literal->{storage}[0]{_depth_declaration}, 'literal depth gains no dependency');
    my $default = parse(source('2', ''));
    is($default->{watchdog}, 65535, 'implicit watchdog retains established default');
    ok(!exists $default->{_watchdog_declaration}, 'implicit default gains no dependency');
};

subtest 'returned records remain isolated across siblings and fresh parses' => sub {
    my $text = source('ALIAS', '(watchdog ALIAS)');
    $text =~ s/\(depth ALIAS\)\)\)/\(depth ALIAS\)\) (bank other (width W) (depth ALIAS)))/;
    my $actor = parse($text);
    my $before = $json->encode($actor);
    my $fresh = parse($text);
    if (ref($actor->{storage}[0]{_depth_declaration}) eq 'HASH') {
        $actor->{storage}[0]{_depth_declaration}{token} = 'OTHER';
        is($actor->{storage}[1]{_depth_declaration}{token}, 'ALIAS', 'bank sibling is detached');
        is($actor->{_watchdog_declaration}{token}, 'ALIAS', 'watchdog record is detached');
    }
    is($json->encode($fresh), $before, 'fresh parser result is independent');
};

subtest 'library clones preserve exported ownership without sharing records' => sub {
    my $actor = parse(<<'ISF');
(library children (exports (actor child))
  (actor child (clock clk) (params (W 2)) (watchdog W)
    (interface (input data) (output result))
    (storage (bank mem (width 1) (depth W)))
    (rule copy 1 (result data))))
(actor parent (clock clk) (imports (library children as lib))
  (interface (input data) (output first) (output second))
  (use lib.child as a (bind (clock clk) (input data data) (output result first)))
  (use lib.child as b (bind (clock clk) (input data data) (output result second))))
ISF
    my @children = map {$_->{actor}} @{$actor->{library_uses}};
    my $expected = {token => 'W', kind => 'actor_parameter', owner => 'child'};
    for my $child (@children) {
        is_deeply($child->{_watchdog_declaration}, $expected, 'watchdog retains exported source owner');
        is_deeply($child->{storage}[0]{_depth_declaration}, $expected, 'depth retains exported source owner');
    }
    if (ref($children[0]{_watchdog_declaration}) eq 'HASH') {
        $children[0]{_watchdog_declaration}{owner} = 'wrong';
        $children[0]{storage}[0]{_depth_declaration}{owner} = 'wrong';
        is_deeply($children[1]{_watchdog_declaration}, $expected, 'watchdog clone is detached');
        is_deeply($children[1]{storage}[0]{_depth_declaration}, $expected, 'bank clone is detached');
    }
};

done_testing;
