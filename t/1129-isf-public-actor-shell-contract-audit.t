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
    build_isf_public_interface_contract
    isf_public_interface_actor_shell_required_keys
);

subtest 'contract advertises the scheduler-consumable actor shell' => sub {
    my $contract = build_isf_public_interface_contract();

    is_deeply(
        $contract->{actor_shell_required_keys},
        isf_public_interface_actor_shell_required_keys(),
        'contract publishes the required actor shell keys',
    );
    ok(
        key_list_contains($contract->{public_top_level_presence_keys}, 'actor_shell_required_keys'),
        'actor shell key family is part of the public contract surface',
    );
    ok(
        !$contract->{raw_actor_full_hash_stable},
        'contract still does not freeze the full raw actor hash',
    );
};

subtest 'public parser facades return actors with the advertised shell' => sub {
    my $path = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');
    my $source = read_text($path);

    my $adapter = FSM::Adapter::ISF->new();
    my @actors = (
        ['parse_file',   $adapter->parse_file($path)],
        ['parse_source', $adapter->parse_source($source, 'inline-apb-requester.isf')],
    );

    for my $case (@actors) {
        my ($label, $actor) = @$case;
        assert_actor_shell($actor, $label);
        assert_scheduler_accepts_actor($actor, $label);
    }
};

done_testing();

sub assert_actor_shell {
    my ($actor, $label) = @_;

    ok(ref($actor) eq 'HASH', "$label returns an actor hash reference");
    for my $key (@{isf_public_interface_actor_shell_required_keys()}) {
        ok(exists $actor->{$key}, "$label actor exposes required shell key $key");
    }

    is($actor->{actor_name}, 'apb_requester', "$label actor exposes scalar actor_name");
    ok(ref($actor->{transactions}) eq 'ARRAY', "$label actor exposes transactions array");
    ok(ref($actor->{interface}) eq 'HASH', "$label actor exposes interface hash");
}

sub assert_scheduler_accepts_actor {
    my ($actor, $label) = @_;
    my $scheduler = FSM::Scheduler::ISF->new();

    my $lowered = $scheduler->lower($actor);
    ok(exists $lowered->{files}{'apb_requester.fsm'}, "$label actor lowers through public scheduler");

    my $report = JSON::PP->new->decode($scheduler->report($actor));
    is($report->{scheduled_fsm}, 'apb_requester.fsm', "$label actor reports through public scheduler");
}

sub read_text {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";
    return $text;
}

sub key_list_contains {
    my ($keys, $needle) = @_;
    return scalar grep { $_ eq $needle } @{$keys || []};
}
