#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::FSMGenFull::SignalManager;

subtest 'signal usage inspection accessors return caller-owned snapshots' => sub {
    my $signal_manager = FSM::Adapter::FSMGenFull::SignalManager->new(debug => 0);
    my $live_usage = $signal_manager->initialize_signal_usage('ready');
    $live_usage->{referenced_in_conditions} = 1;
    push @{$live_usage->{contexts}}, 'condition.idle';

    my $single_usage = $signal_manager->get_signal_usage('ready');
    $single_usage->{referenced_in_conditions} = 99;
    push @{$single_usage->{contexts}}, 'mutated.single';

    is_deeply(
        $signal_manager->get_signal_usage('ready'),
        {
            referenced_in_conditions => 1,
            assigned_to => 0,
            has_output_marker => 0,
            is_intermediate => 0,
            contexts => ['condition.idle'],
        },
        'single signal usage lookup returns a fresh usage snapshot',
    );

    my $all_usage = $signal_manager->get_all_signal_usages;
    $all_usage->{ready}{assigned_to} = 99;
    push @{$all_usage->{ready}{contexts}}, 'mutated.all';
    $all_usage->{late} = {
        referenced_in_conditions => 1,
        assigned_to => 1,
        has_output_marker => 1,
        is_intermediate => 1,
        contexts => ['mutated'],
    };

    is_deeply(
        $signal_manager->get_all_signal_usages,
        {
            ready => {
                referenced_in_conditions => 1,
                assigned_to => 0,
                has_output_marker => 0,
                is_intermediate => 0,
                contexts => ['condition.idle'],
            },
        },
        'all signal usage lookup returns a fresh usage map snapshot',
    );
};

subtest 'initialize_signal_usage remains the explicit mutation path' => sub {
    my $signal_manager = FSM::Adapter::FSMGenFull::SignalManager->new(debug => 0);

    my $usage = $signal_manager->initialize_signal_usage('data');
    $usage->{assigned_to}++;
    push @{$usage->{contexts}}, 'assignment.idle';

    is_deeply(
        $signal_manager->get_signal_usage('data'),
        {
            referenced_in_conditions => 0,
            assigned_to => 1,
            has_output_marker => 0,
            is_intermediate => 0,
            contexts => ['assignment.idle'],
        },
        'explicit initializer mutation is preserved for analyzer updates',
    );
};

done_testing;
