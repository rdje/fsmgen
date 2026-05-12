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

my $isf_path = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');
my $isf_source = read_text($isf_path);

subtest 'contract advertises parser and scheduler method receiver shapes' => sub {
    my $contract = build_isf_public_interface_contract();

    is(
        $contract->{parser_method_receiver_shape},
        'object returned by FSM::Adapter::ISF->new(...)',
        'contract advertises parser method receiver shape',
    );
    is(
        $contract->{scheduler_method_receiver_shape},
        'object returned by FSM::Scheduler::ISF->new(...)',
        'contract advertises scheduler method receiver shape',
    );
    ok(
        key_list_contains($contract->{public_top_level_presence_keys}, 'parser_method_receiver_shape'),
        'parser receiver shape is part of the public contract surface',
    );
    ok(
        key_list_contains($contract->{public_top_level_presence_keys}, 'scheduler_method_receiver_shape'),
        'scheduler receiver shape is part of the public contract surface',
    );
};

subtest 'parser facade rejects malformed method receivers' => sub {
    my $adapter = FSM::Adapter::ISF->new();
    ok(ref($adapter->parse_file($isf_path)) eq 'HASH', 'valid parser object receiver still parses files');
    ok(ref($adapter->parse_source($isf_source, 'inline-apb-requester.isf')) eq 'HASH', 'valid parser object receiver still parses source text');

    for my $case (
        ['parse_file class receiver',      sub { FSM::Adapter::ISF->parse_file($isf_path) }],
        ['parse_file undef receiver',      sub { FSM::Adapter::ISF::parse_file(undef, $isf_path) }],
        ['parse_file unblessed receiver',  sub { FSM::Adapter::ISF::parse_file({}, $isf_path) }],
        ['parse_source class receiver',     sub { FSM::Adapter::ISF->parse_source($isf_source, 'inline.isf') }],
        ['parse_source undef receiver',     sub { FSM::Adapter::ISF::parse_source(undef, $isf_source, 'inline.isf') }],
        ['parse_source unblessed receiver', sub { FSM::Adapter::ISF::parse_source({}, $isf_source, 'inline.isf') }],
    ) {
        my ($label, $code) = @$case;
        my $method = $label =~ /\A(parse_\w+)/ ? $1 : die "missing method in $label";
        assert_rejects(
            $code,
            qr/\QFSM::Adapter::ISF->$method must be called on an FSM::Adapter::ISF object\E/,
            "$label is rejected at the public parser boundary",
        );
    }
};

subtest 'scheduler facade rejects malformed method receivers' => sub {
    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $scheduler = FSM::Scheduler::ISF->new();
    ok(exists $scheduler->lower($actor)->{files}{'apb_requester.fsm'}, 'valid scheduler object receiver still lowers actors');
    like($scheduler->report($actor), qr/"scheduled_fsm"\s*:\s*"apb_requester\.fsm"/, 'valid scheduler object receiver still reports actors');

    for my $case (
        ['lower class receiver',     sub { FSM::Scheduler::ISF->lower($actor) }],
        ['lower undef receiver',     sub { FSM::Scheduler::ISF::lower(undef, $actor) }],
        ['lower unblessed receiver', sub { FSM::Scheduler::ISF::lower({}, $actor) }],
        ['report class receiver',     sub { FSM::Scheduler::ISF->report($actor) }],
        ['report undef receiver',     sub { FSM::Scheduler::ISF::report(undef, $actor) }],
        ['report unblessed receiver', sub { FSM::Scheduler::ISF::report({}, $actor) }],
    ) {
        my ($label, $code) = @$case;
        my $method = $label =~ /\A(\w+)/ ? $1 : die "missing method in $label";
        assert_rejects(
            $code,
            qr/\QFSM::Scheduler::ISF->$method must be called on an FSM::Scheduler::ISF object\E/,
            "$label is rejected at the public scheduler boundary",
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
