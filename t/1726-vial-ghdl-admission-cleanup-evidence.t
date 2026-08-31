#!/usr/bin/env perl

use strict;
use warnings;

use File::Path qw(remove_tree);
use File::Spec;
use FindBin;
use Test::More;

use lib "$FindBin::Bin/../perl";

use FSM::VIAL::Backend::GHDLLifecycle;

my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my @root_stat = stat($repo_root);
my @stage;

END {
    remove_tree($_) for grep { -d $_ && !-l $_ } @stage;
}

subtest 'successful admission failure cleanup is reported exactly' => sub {
    my $session = probe_session('removed');
    my $result;
    {
        no warnings 'redefine';
        local *FSM::VIAL::Backend::GHDLLifecycle::_write_atomic = sub {
            die bless {
                code => 'VIAL_GHDL_LIFECYCLE_OBJECT_ERROR',
                message => 'forced admission write failure',
                path => '/state',
            }, 'FSM::VIAL::Backend::GHDLLifecycle::Failure';
        };
        my $ok = eval {
            FSM::VIAL::Backend::GHDLLifecycle::_begin($session);
            1;
        };
        ok(!$ok, 'forced admission write failure rejects');
        $result = FSM::VIAL::Backend::GHDLLifecycle::_exception(
            $@, $session,
        );
    }

    is($result->{diagnostics}[0]{code},
        'VIAL_GHDL_LIFECYCLE_OBJECT_ERROR',
        'successful cleanup preserves the triggering diagnostic');
    is($result->{diagnostics}[0]{path}, '/state',
        'successful cleanup preserves the triggering path');
    ok($result->{cleanup}{removed},
        'successful admission cleanup is reported removed');
    is_deeply($result->{cleanup}{residue}, [],
        'successful admission cleanup reports zero residue');
    ok(!-e $session->{stage_abs},
        'successful admission cleanup removes the exact created root');
};

subtest 'failed admission cleanup becomes authoritative with residue' => sub {
    my $session = probe_session('residue');
    my $result;
    {
        no warnings 'redefine';
        local *FSM::VIAL::Backend::GHDLLifecycle::_write_atomic = sub {
            die bless {
                code => 'VIAL_GHDL_LIFECYCLE_OBJECT_ERROR',
                message => 'forced admission write failure',
                path => '/state',
            }, 'FSM::VIAL::Backend::GHDLLifecycle::Failure';
        };
        local *FSM::VIAL::Backend::GHDLLifecycle::remove_tree = sub {
            my ($path, $options) = @_;
            ${$options->{error}} = [{
                $path => 'forced admission cleanup failure',
            }];
            return;
        };
        my $ok = eval {
            FSM::VIAL::Backend::GHDLLifecycle::_begin($session);
            1;
        };
        ok(!$ok, 'forced admission cleanup failure rejects');
        $result = FSM::VIAL::Backend::GHDLLifecycle::_exception(
            $@, $session,
        );
    }

    is(
        $result->{diagnostics}[0]{code},
        'VIAL_GHDL_LIFECYCLE_CLEANUP_ERROR',
        'failed admission cleanup has diagnostic precedence',
    );
    is($result->{diagnostics}[0]{path}, '/cleanup',
        'failed admission cleanup has the exact cleanup path');
    ok(!$result->{cleanup}{removed},
        'failed admission cleanup is not reported removed');
    is_deeply($result->{cleanup}{residue}, [$session->{stage_rel}],
        'failed admission cleanup reports the exact residual root');
    ok(-d $session->{stage_abs},
        'failed admission cleanup control retains the expected residue');
};

done_testing();

sub probe_session {
    my ($label) = @_;
    my $stage_rel =
        ".artifacts/test/vial-ghdl-admission-cleanup-$$-$label";
    my $stage_abs = File::Spec->catdir(
        $repo_root, split m{/}, $stage_rel,
    );
    push @stage, $stage_abs;
    return {
        authority => {},
        cleanup_on_error => 0,
        handle => undef,
        lifecycle_identity => 'lifecycle/' . ('b' x 64),
        objects => [],
        root_device => $root_stat[0],
        stage_abs => $stage_abs,
        stage_rel => $stage_rel,
    };
}
