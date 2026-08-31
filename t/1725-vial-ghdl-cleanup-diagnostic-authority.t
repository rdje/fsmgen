#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use Test::More;

use lib "$FindBin::Bin/../perl";

use FSM::VIAL::Backend::GHDLLifecycle;

my $session = {
    cleanup_on_error => 1,
    lifecycle_identity => 'lifecycle/' . ('a' x 64),
    stage_rel => '.artifacts/vial/runtime/cleanup-authority-probe',
    handle => undef,
};
my $phase_failure = bless {
    code => 'VIAL_GHDL_LIFECYCLE_TIMEOUT',
    message => 'GHDL ran timed out',
    path => '/ran',
}, 'FSM::VIAL::Backend::GHDLLifecycle::Failure';

subtest 'cleanup failure becomes the authoritative diagnostic' => sub {
    my $result;
    {
        no warnings 'redefine';
        local *FSM::VIAL::Backend::GHDLLifecycle::_owner_matches = sub { 1 };
        local *FSM::VIAL::Backend::GHDLLifecycle::_remove_owned_root = sub {
            die bless {
                code => 'VIAL_GHDL_LIFECYCLE_CLEANUP_ERROR',
                message => 'forced cleanup failure',
                path => '/cleanup',
            }, 'FSM::VIAL::Backend::GHDLLifecycle::Failure';
        };
        $result = FSM::VIAL::Backend::GHDLLifecycle::_exception(
            $phase_failure, $session,
        );
    }

    ok(!$result->{ok}, 'combined phase and cleanup failure rejects');
    is(
        $result->{diagnostics}[0]{code},
        'VIAL_GHDL_LIFECYCLE_CLEANUP_ERROR',
        'cleanup failure has diagnostic precedence',
    );
    is($result->{diagnostics}[0]{message}, 'forced cleanup failure',
        'cleanup failure retains its stable message');
    is($result->{diagnostics}[0]{path}, '/cleanup',
        'cleanup failure retains its exact phase path');
    ok(!$result->{cleanup}{removed}, 'failed cleanup is not reported removed');
    is_deeply(
        $result->{cleanup}{residue},
        [$session->{stage_rel}],
        'failed cleanup reports the exact owned staging identity as residue',
    );
};

subtest 'successful cleanup preserves the original phase diagnostic' => sub {
    my $result;
    {
        no warnings 'redefine';
        local *FSM::VIAL::Backend::GHDLLifecycle::_owner_matches = sub { 1 };
        local *FSM::VIAL::Backend::GHDLLifecycle::_remove_owned_root = sub { 1 };
        $result = FSM::VIAL::Backend::GHDLLifecycle::_exception(
            $phase_failure, $session,
        );
    }

    is($result->{diagnostics}[0]{code}, 'VIAL_GHDL_LIFECYCLE_TIMEOUT',
        'successful cleanup retains the original phase diagnostic');
    is($result->{diagnostics}[0]{path}, '/ran',
        'successful cleanup retains the original phase path');
    ok($result->{cleanup}{removed}, 'successful cleanup is reported removed');
    is_deeply($result->{cleanup}{residue}, [],
        'successful cleanup reports zero residue');
};

subtest 'unexpected cleanup exception is sanitized and phase-owned' => sub {
    my $result;
    {
        no warnings 'redefine';
        local *FSM::VIAL::Backend::GHDLLifecycle::_owner_matches = sub { 1 };
        local *FSM::VIAL::Backend::GHDLLifecycle::_remove_owned_root = sub {
            die "forced host cleanup failure\n";
        };
        $result = FSM::VIAL::Backend::GHDLLifecycle::_exception(
            $phase_failure, $session,
        );
    }

    is(
        $result->{diagnostics}[0]{code},
        'VIAL_GHDL_LIFECYCLE_CLEANUP_ERROR',
        'unexpected cleanup exception maps to the cleanup diagnostic family',
    );
    is($result->{diagnostics}[0]{message}, 'forced host cleanup failure',
        'unexpected cleanup exception is sanitized');
    is($result->{diagnostics}[0]{path}, '/cleanup',
        'unexpected cleanup exception remains cleanup-owned');
    ok(!$result->{cleanup}{removed},
        'unexpected cleanup exception is not reported removed');
    is_deeply($result->{cleanup}{residue}, [$session->{stage_rel}],
        'unexpected cleanup exception retains the exact residue identity');
};

done_testing();
