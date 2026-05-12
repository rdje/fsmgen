#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP ();

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::ISFPublicInterfaceContract qw(
    isf_public_interface_scheduler_method_names
);

subtest 'ISF scheduler facade advertises and accepts the public method set' => sub {
    is_deeply(
        isf_public_interface_scheduler_method_names(),
        [qw(new lower report)],
        'contract advertises the public scheduler method names',
    );

    my $actor = parse_apb_actor();
    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    ok(exists $lowered->{files}{'apb_requester.fsm'}, 'lower accepts adapter actor');

    my $report = JSON::PP->new->decode($scheduler->report($actor));
    is($report->{source}, 'apb_requester.isf', 'report accepts adapter actor');
};

subtest 'ISF scheduler facade rejects malformed public method arguments' => sub {
    my $scheduler = FSM::Scheduler::ISF->new();

    for my $method (qw(lower report)) {
        assert_rejects(
            sub { $scheduler->$method() },
            qr/\QFSM::Scheduler::ISF->$method expects exactly one scheduler-consumable actor hash reference\E/,
            "$method rejects missing actor",
        );
        assert_rejects(
            sub { $scheduler->$method({}, {}) },
            qr/\QFSM::Scheduler::ISF->$method expects exactly one scheduler-consumable actor hash reference\E/,
            "$method rejects extra actor",
        );
        assert_rejects(
            sub { $scheduler->$method('not-an-actor') },
            qr/\QFSM::Scheduler::ISF->$method argument 1 must be a scheduler-consumable actor hash reference\E/,
            "$method rejects non-hash actor",
        );
        assert_rejects(
            sub { $scheduler->$method({ transactions => [], interface => {} }) },
            qr/\QFSM::Scheduler::ISF->$method actor must include scalar actor_name\E/,
            "$method rejects actor without actor_name",
        );
        assert_rejects(
            sub { $scheduler->$method({ actor_name => 'x', transactions => {}, interface => {} }) },
            qr/\QFSM::Scheduler::ISF->$method actor must include transactions array\E/,
            "$method rejects actor without transactions array",
        );
        assert_rejects(
            sub { $scheduler->$method({ actor_name => 'x', transactions => [], interface => [] }) },
            qr/\QFSM::Scheduler::ISF->$method actor must include interface hash\E/,
            "$method rejects actor without interface hash",
        );
    }
};

done_testing();

sub parse_apb_actor {
    my $path = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');
    return FSM::Adapter::ISF->new()->parse_file($path);
}

sub assert_rejects {
    my ($code, $pattern, $label) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok, $label);
    like($@, $pattern, "$label diagnostic");
}
