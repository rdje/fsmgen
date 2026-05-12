#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::ISFPublicInterfaceContract qw(build_isf_public_interface_contract);

subtest 'contract advertises constructor receiver shape' => sub {
    my $contract = build_isf_public_interface_contract();

    is(
        $contract->{constructor_receiver_shape},
        'exact class invocant: FSM::Adapter::ISF or FSM::Scheduler::ISF',
        'contract advertises the exact constructor class invocants',
    );
    ok(
        key_list_contains($contract->{public_top_level_presence_keys}, 'constructor_receiver_shape'),
        'constructor receiver shape is part of the public contract surface',
    );
};

subtest 'adapter constructor rejects malformed receivers' => sub {
    my $adapter = FSM::Adapter::ISF->new();
    ok(ref($adapter) eq 'FSM::Adapter::ISF', 'valid adapter class receiver constructs an adapter');
    ok(ref(FSM::Adapter::ISF->new(debug => 1)) eq 'FSM::Adapter::ISF', 'valid adapter class receiver accepts debug option');

    for my $case (
        ['undefined receiver', sub { FSM::Adapter::ISF::new(undef) }],
        ['unblessed receiver', sub { FSM::Adapter::ISF::new({}) }],
        ['object receiver',    sub { $adapter->new() }],
        ['wrong class string', sub { FSM::Adapter::ISF::new('FSM::Scheduler::ISF') }],
    ) {
        my ($label, $code) = @$case;
        assert_rejects(
            $code,
            qr/\QFSM::Adapter::ISF->new must be called with the FSM::Adapter::ISF class invocant\E/,
            "adapter constructor rejects $label",
        );
    }
};

subtest 'scheduler constructor rejects malformed receivers' => sub {
    my $scheduler = FSM::Scheduler::ISF->new();
    ok(ref($scheduler) eq 'FSM::Scheduler::ISF', 'valid scheduler class receiver constructs a scheduler');
    ok(ref(FSM::Scheduler::ISF->new(debug => 1)) eq 'FSM::Scheduler::ISF', 'valid scheduler class receiver accepts debug option');

    for my $case (
        ['undefined receiver', sub { FSM::Scheduler::ISF::new(undef) }],
        ['unblessed receiver', sub { FSM::Scheduler::ISF::new({}) }],
        ['object receiver',    sub { $scheduler->new() }],
        ['wrong class string', sub { FSM::Scheduler::ISF::new('FSM::Adapter::ISF') }],
    ) {
        my ($label, $code) = @$case;
        assert_rejects(
            $code,
            qr/\QFSM::Scheduler::ISF->new must be called with the FSM::Scheduler::ISF class invocant\E/,
            "scheduler constructor rejects $label",
        );
    }
};

done_testing();

sub assert_rejects {
    my ($code, $pattern, $label) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok, $label);
    like($@, $pattern, "$label diagnostic");
}

sub key_list_contains {
    my ($keys, $needle) = @_;
    return scalar grep { $_ eq $needle } @{$keys || []};
}
