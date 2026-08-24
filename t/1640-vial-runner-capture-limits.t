#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::VerilatorLifecycle;

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');

sub capture {
    my (%args) = @_;
    return FSM::VIAL::Backend::VerilatorLifecycle->_test_capture_process(
        {
            repo_root => $repo_root,
            storage_context => {
                containment => 'lifecycle_process_group',
            },
        },
        [$^X, '-e', $args{program}],
        10,
        $args{limit},
    );
}

subtest 'the exact aggregate capture limit remains accepted' => sub {
    my $result = capture(
        limit => 65_536,
        program => 'print "a" x 32768; print STDERR "b" x 32768',
    );

    ok($result->{ok}, 'an exact-limit process succeeds');
    ok(FSM::VIAL::Backend::VerilatorLifecycle
            ->_test_process_succeeded($result),
        'shared lifecycle accepts the exact-limit process outcome');
    is($result->{exit_code}, 0, 'the exact-limit exit status is preserved');
    ok(!$result->{timed_out}, 'the exact-limit process does not time out');
    ok(!$result->{output_limited}, 'the exact limit is inclusive');
    is(length($result->{output}), 65_536,
        'stdout and stderr share one exact aggregate byte budget');
};

subtest 'one aggregate byte beyond the limit fails closed' => sub {
    my $result = capture(
        limit => 65_536,
        program => 'print "a" x 32768; print STDERR "b" x 32769',
    );

    ok(!$result->{ok}, 'one byte over cannot be accepted');
    ok(!FSM::VIAL::Backend::VerilatorLifecycle
            ->_test_process_succeeded($result),
        'shared lifecycle rejects the exhausted capture outcome');
    ok(!$result->{timed_out}, 'the rejection is not mislabeled as timeout');
    ok($result->{output_limited}, 'the rejection names output exhaustion');
    cmp_ok(length($result->{output}), '>', 65_536,
        'the captured witness crosses the configured limit');
};

subtest 'ordinary nonzero tool exit remains distinct from output exhaustion' => sub {
    my $result = capture(
        limit => 65_536,
        program => 'print "tool failed\n"; exit 23',
    );

    ok($result->{ok}, 'the capture infrastructure observes a normal child exit');
    ok(!FSM::VIAL::Backend::VerilatorLifecycle
            ->_test_process_succeeded($result),
        'shared lifecycle cannot accept a captured nonzero tool exit');
    is($result->{exit_code}, 23, 'the tool exit status is preserved exactly');
    ok(!$result->{timed_out}, 'the tool failure is not a timeout');
    ok(!$result->{output_limited}, 'the tool failure is not a capture limit');
    is($result->{output}, "tool failed\n", 'diagnostic output is retained');
};

done_testing();

package FSM::VIAL::Backend::VerilatorLifecycle;

sub _test_capture_process {
    my ($class, @args) = @_;
    die "unexpected capture-test invocant\n" unless $class eq __PACKAGE__;
    return _capture_process(@args);
}

sub _test_process_succeeded {
    my ($class, @args) = @_;
    die "unexpected process-test invocant\n" unless $class eq __PACKAGE__;
    return _process_succeeded(@args);
}
