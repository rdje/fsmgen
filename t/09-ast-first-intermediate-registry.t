#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

my $fsm_file = File::Spec->catfile($FindBin::Bin, '..', 'fsm', 'trial_1.fsm');
my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'systemverilog',
    quiet => 1,
);

{
    local $SIG{__WARN__} = sub { };
    $pipeline->generate_hdl_from_file($fsm_file);
}

my $hdl = $pipeline->{hdl_generator};
my $registry = $hdl->{intermediate_signals} || {};

is(
    ref($registry),
    'HASH',
    'live generator exposes intermediate_signals as a hash registry',
);

my @plain_string_entries = grep { !ref($registry->{$_}) } sort keys %$registry;
is_deeply(
    \@plain_string_entries,
    [],
    'live generation leaves no plain-string intermediate registry entries behind',
);

my @legacy_registry_entries = grep {
    ref($registry->{$_}) eq 'HASH'
        && (($registry->{$_}{source} || '') eq 'legacy_string_registry')
} sort keys %$registry;
is_deeply(
    \@legacy_registry_entries,
    [],
    'live generation leaves no legacy_string_registry intermediate entries behind',
);

done_testing();
